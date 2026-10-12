/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license, you may redistribute it
 * and/or modify it under version 3 of the License, or (at your option), any later version.
 */

#include "DcDungeonQueue.h"

#include <algorithm>
#include <mutex>
#include <sstream>
#include <unordered_map>
#include <utility>
#include <vector>

#include "Chat.h"
#include "Group.h"
#include "Item.h"
#include "Log.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "Playerbots.h"
#include "ScriptMgr.h"
#include "SharedDefines.h"
#include "Timer.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include "DcInstanceReset.h"
#include "DungeonClearDispatch.h"
#include "TestRun/DcTestDungeonRegistry.h"
#include "Ai/Dungeon/DungeonClear/Action/DcActionShared.h"
#include "Ai/Dungeon/DungeonClear/Util/DcRun.h"

namespace
{
    constexpr uint32 kTickMs = 500;
    constexpr uint32 kArriveTimeoutMs = 45 * 1000;
    constexpr uint32 kStartTimeoutMs = 30 * 1000;
    constexpr uint32 kStartRetryMs = 2000;
    constexpr uint32 kRunTimeoutMs = 90 * 60 * 1000;   // one dungeon, then pause
    constexpr uint32 kLostRunMs = 15 * 1000;            // run off with no report seen
    constexpr uint32 kResetTryMs = 60 * 1000;           // then move on without a reset
    constexpr uint32 kResetRetryMs = 5000;
    constexpr uint32 kResetCalmAfterMs = 20 * 1000;     // then drop leftover combat
    constexpr uint32 kMaxFails = 2;
    constexpr uint32 kMinFreeSlots = 5;
    constexpr uint32 kMinDurabilityPct = 20;

    enum class Stage : uint8
    {
        Prepare,   // supplies check, then teleport
        Arrive,    // waiting for everyone to be on the dungeon map
        Start,     // `dc on` until the tank's run is enabled
        Run,       // waiting for the run to end
        Reset,     // DcInstanceReset, then the next dungeon
        Paused,
    };

    char const* StageName(Stage s)
    {
        switch (s)
        {
            case Stage::Prepare: return "prepare";
            case Stage::Arrive: return "arrive";
            case Stage::Start: return "start";
            case Stage::Run: return "run";
            case Stage::Reset: return "reset";
            case Stage::Paused: return "paused";
        }
        return "?";
    }

    struct Queue
    {
        std::vector<std::string> tokens;
        std::size_t index = 0;
        uint32 fails = 0;
        Stage stage = Stage::Prepare;
        Stage resumeTo = Stage::Prepare;
        uint32 stageMs = 0;
        uint32 lastTryMs = 0;
        bool resetRequested = false;
        bool reviveOnArrive = false;
        ObjectGuid tank;
        std::string note;        // last status line shown to the player
    };

    // World thread only.
    std::unordered_map<ObjectGuid::LowType, Queue> g_queues;
    // Tokens sent ahead of "start" (addon messages are capped at 255 bytes).
    std::unordered_map<ObjectGuid::LowType, std::vector<std::string>> g_staged;
    uint32 g_accumMs = 0;

    // Run-end mailbox: written from bot AI updates (map threads).
    std::mutex g_mailMutex;
    std::vector<std::pair<ObjectGuid, std::string>> g_mail;

    void SendAddon(Player* player, std::string const& payload)
    {
        if (!player || !player->GetSession())
            return;
        WorldPacket data;
        ChatHandler::BuildChatPacket(data, CHAT_MSG_PARTY, LANG_ADDON, player->GetGUID(),
                                     ObjectGuid::Empty, payload, CHAT_TAG_NONE, player->GetName());
        player->GetSession()->SendPacket(&data);
    }

    void Say(Player* player, std::string const& text)
    {
        if (player && player->GetSession())
            ChatHandler(player->GetSession()).SendSysMessage(("|cff33ccff[连续清本]|r " + text).c_str());
    }

    DcTestDungeonRegistry::Row const* RowFor(Queue const& q)
    {
        if (q.index >= q.tokens.size())
            return nullptr;
        return DcTestDungeonRegistry::Find(q.tokens[q.index]);
    }

    std::string RowName(Queue const& q)
    {
        DcTestDungeonRegistry::Row const* row = RowFor(q);
        return row ? std::string(row->name) : (q.index < q.tokens.size() ? q.tokens[q.index] : std::string());
    }

    // QSTATE\t<stage>\t<index 1-based>\t<total>\t<token>\t<fails>\t<note>
    void Publish(Player* leader, Queue const& q)
    {
        std::ostringstream os;
        os << "DC\tQSTATE\t" << StageName(q.stage) << '\t' << (q.index + 1) << '\t' << q.tokens.size()
           << '\t' << (q.index < q.tokens.size() ? q.tokens[q.index] : "") << '\t' << q.fails << '\t' << q.note;
        SendAddon(leader, os.str());
    }

    void Enter(Player* leader, Queue& q, Stage stage, std::string const& note, uint32 now)
    {
        q.stage = stage;
        q.stageMs = now;
        q.lastTryMs = 0;
        q.note = note;
        if (!note.empty())
            Say(leader, note);
        Publish(leader, q);
    }

    void Pause(Player* leader, Queue& q, Stage resumeTo, std::string const& why, uint32 now)
    {
        q.resumeTo = resumeTo;
        LOG_INFO("playerbots.dungeonclear", "DCQ1A: {} queue paused at {} ({}): {}",
                 leader->GetName(), q.index + 1, RowName(q), why);
        Enter(leader, q, Stage::Paused, "已暂停：" + why + "。处理后点「继续」。", now);
    }

    std::vector<Player*> Members(Player* leader)
    {
        std::vector<Player*> out;
        out.push_back(leader);
        if (Group* group = leader->GetGroup())
            for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
            {
                Player* member = ref->GetSource();
                if (member && member != leader && member->IsInWorld())
                    out.push_back(member);
            }
        return out;
    }

    // "" when everyone is fit for the next dungeon.
    std::string SupplyProblem(std::vector<Player*> const& members)
    {
        for (Player* m : members)
        {
            uint32 const free = m->GetFreeInventorySpace();
            if (free < kMinFreeSlots)
                return m->GetName() + " 背包只剩 " + std::to_string(free) + " 格";
            for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
            {
                Item* item = m->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
                if (!item)
                    continue;
                uint32 const maxDur = item->GetUInt32Value(ITEM_FIELD_MAXDURABILITY);
                if (!maxDur)
                    continue;
                uint32 const dur = item->GetUInt32Value(ITEM_FIELD_DURABILITY);
                if (dur * 100 < maxDur * kMinDurabilityPct)
                    return m->GetName() + " 的装备耐久低于 " + std::to_string(kMinDurabilityPct) + "%";
            }
        }
        return "";
    }

    // Revive (the queue is a hands-off mode the player opted into, so this
    // includes the player) and drop combat before a move.
    void ReviveAndCalm(Player* m)
    {
        m->GetThreatMgr().ClearAllThreat();
        m->CombatStop(true);
        m->AttackStop();
        if (!m->IsAlive() || m->HasPlayerFlag(PLAYER_FLAGS_GHOST))
        {
            m->RemoveAurasDueToSpell(27827);  // Spirit of Redemption
            m->ResurrectPlayer(1.0f, /*applySickness*/ false);
            m->SpawnCorpseBones();
        }
    }

    void TeleportParty(Player* leader, DcTestDungeonRegistry::Row const& row)
    {
        for (Player* m : Members(leader))
        {
            ReviveAndCalm(m);
            m->RemoveAurasWithInterruptFlags(AURA_INTERRUPT_FLAG_TELEPORTED | AURA_INTERRUPT_FLAG_CHANGE_MAP);
            m->TeleportTo(row.mapId, row.x, row.y, row.z, row.o);
        }
    }

    bool AllArrived(Player* leader, uint32 mapId)
    {
        for (Player* m : Members(leader))
            if (m->IsBeingTeleported() || !m->IsInWorld() || m->GetMapId() != mapId)
                return false;
        return true;
    }

    PlayerbotAI* TankAI(Queue const& q)
    {
        Player* tank = q.tank ? ObjectAccessor::FindPlayer(q.tank) : nullptr;
        return tank ? GET_PLAYERBOT_AI(tank) : nullptr;
    }

    // The next dungeon, or the end of the list.
    void Advance(Player* leader, Queue& q, uint32 now)
    {
        ++q.index;
        q.fails = 0;
        q.tank = ObjectGuid::Empty;
        if (q.index >= q.tokens.size())
        {
            Say(leader, "全部勾选的副本已完成。");
            LOG_INFO("playerbots.dungeonclear", "DCQ1A: {} queue finished ({} dungeons)",
                     leader->GetName(), q.tokens.size());
            q.note = "全部完成";
            q.stage = Stage::Paused;
            SendAddon(leader, "DC\tQSTATE\tdone\t" + std::to_string(q.tokens.size()) + "\t" +
                                  std::to_string(q.tokens.size()) + "\t\t0\t全部完成");
            g_queues.erase(leader->GetGUID().GetCounter());
            return;
        }
        Enter(leader, q, Stage::Prepare, "", now);
    }

    void HandleRunEnd(Player* leader, Queue& q, std::string const& reason, uint32 now)
    {
        if (reason == DcActionShared::kReasonAllCleared)
        {
            LOG_INFO("playerbots.dungeonclear", "DCQ1A: {} cleared {} ({}/{})",
                     leader->GetName(), RowName(q), q.index + 1, q.tokens.size());
            q.resetRequested = false;
            Enter(leader, q, Stage::Reset, RowName(q) + " 已清完，正在出本并重置。", now);
            return;
        }
        if (reason == "Dungeon clear disabled.")
        {
            Pause(leader, q, Stage::Start, "你手动停止了清本", now);
            return;
        }

        // Anything else is a failed attempt: a wipe, or a death nobody could rez.
        ++q.fails;
        LOG_INFO("playerbots.dungeonclear", "DCQ1A: {} attempt {} on {} failed: {}",
                 leader->GetName(), q.fails, RowName(q), reason);
        if (q.fails >= kMaxFails)
        {
            q.resetRequested = false;
            for (Player* m : Members(leader))
                ReviveAndCalm(m);
            Enter(leader, q, Stage::Reset,
                  RowName(q) + " 连续失败 " + std::to_string(q.fails) + " 次，跳过，进入下一个副本。", now);
            return;
        }
        DcTestDungeonRegistry::Row const* row = RowFor(q);
        if (!row)
        {
            Advance(leader, q, now);
            return;
        }
        TeleportParty(leader, *row);
        Enter(leader, q, Stage::Arrive, "团灭，全队在入口复活，重新开始 " + RowName(q) + "。", now);
    }

    void TickQueue(Player* leader, Queue& q, uint32 now,
                   std::vector<std::string> const& reports)
    {
        uint32 const inStage = getMSTimeDiff(q.stageMs, now);

        if (q.stage == Stage::Run)
        {
            if (!reports.empty())
            {
                HandleRunEnd(leader, q, reports.back(), now);
                return;
            }
            PlayerbotAI* tankAI = TankAI(q);
            bool const running = tankAI && DcRun::Of(tankAI).enabled;
            if (!running && inStage > kLostRunMs)
            {
                // Run went off without a report reaching us (tank logged out, ...).
                Pause(leader, q, Stage::Start, "清本意外停止", now);
                return;
            }
            if (inStage > kRunTimeoutMs)
                Pause(leader, q, Stage::Start, RowName(q) + " 超过 90 分钟未完成", now);
            return;
        }

        switch (q.stage)
        {
            case Stage::Prepare:
            {
                DcTestDungeonRegistry::Row const* row = RowFor(q);
                if (!row)
                {
                    Say(leader, "找不到副本 " + (q.index < q.tokens.size() ? q.tokens[q.index] : std::string()) + "，跳过。");
                    Advance(leader, q, now);
                    return;
                }
                if (!leader->GetGroup() || !DcLeaderSignal::FindLeaderTank(leader))
                {
                    Pause(leader, q, Stage::Prepare, "队伍里没有坦克机器人", now);
                    return;
                }
                std::string const problem = SupplyProblem(Members(leader));
                if (!problem.empty())
                {
                    Pause(leader, q, Stage::Prepare, problem, now);
                    return;
                }
                TeleportParty(leader, *row);
                LOG_INFO("playerbots.dungeonclear", "DCQ1A: {} entering {} ({}/{})",
                         leader->GetName(), row->name, q.index + 1, q.tokens.size());
                Enter(leader, q, Stage::Arrive,
                      "第 " + std::to_string(q.index + 1) + "/" + std::to_string(q.tokens.size()) +
                          " 个：" + row->name + "，正在传送。", now);
                return;
            }
            case Stage::Arrive:
            {
                DcTestDungeonRegistry::Row const* row = RowFor(q);
                if (!row)
                {
                    Advance(leader, q, now);
                    return;
                }
                if (AllArrived(leader, row->mapId))
                {
                    Enter(leader, q, Stage::Start, "", now);
                    return;
                }
                if (inStage > kArriveTimeoutMs)
                    Pause(leader, q, Stage::Prepare,
                          std::string("传送进 ") + row->name + " 失败（等级、钥匙或每小时副本次数限制）", now);
                return;
            }
            case Stage::Start:
            {
                Player* tank = DcLeaderSignal::FindLeaderTank(leader);
                PlayerbotAI* tankAI = tank ? GET_PLAYERBOT_AI(tank) : nullptr;
                if (tankAI && DcRun::Of(tankAI).enabled)
                {
                    q.tank = tank->GetGUID();
                    Enter(leader, q, Stage::Run, "开始清理 " + RowName(q) + "。", now);
                    return;
                }
                if (!q.lastTryMs || getMSTimeDiff(q.lastTryMs, now) >= kStartRetryMs)
                {
                    q.lastTryMs = now != 0 ? now : 1u;
                    DungeonClearDispatch::DispatchToTankBots(leader, "dc on");
                }
                if (inStage > kStartTimeoutMs)
                    Pause(leader, q, Stage::Start, "清本没有启动（查看聊天里的清本提示）", now);
                return;
            }
            case Stage::Reset:
            {
                // Heroic cannot be reset by hand; the next dungeon is another map anyway.
                if (leader->GetDifficulty(false) != DUNGEON_DIFFICULTY_NORMAL)
                {
                    Advance(leader, q, now);
                    return;
                }
                if (q.resetRequested)
                {
                    if (!DcInstanceReset::IsPending(leader))
                        Advance(leader, q, now);
                    return;
                }
                if (!q.lastTryMs || getMSTimeDiff(q.lastTryMs, now) >= kResetRetryMs)
                {
                    q.lastTryMs = now != 0 ? now : 1u;
                    // DCCB1A clears a stuck mob after 15 s; past 20 s drop what is left.
                    bool const calm = inStage > kResetCalmAfterMs;
                    for (Player* m : Members(leader))
                        if (!m->IsAlive() || (calm && m->IsInCombat()))
                            ReviveAndCalm(m);
                    std::string why;
                    if (DcInstanceReset::Request(leader, &why))
                    {
                        q.resetRequested = true;
                        return;
                    }
                    LOG_DEBUG("playerbots.dungeonclear", "DCQ1A: {} reset refused: {}", leader->GetName(), why);
                }
                if (inStage > kResetTryMs)
                {
                    Say(leader, "无法重置 " + RowName(q) + "，直接进入下一个副本。");
                    Advance(leader, q, now);
                }
                return;
            }
            default:
                return;
        }
    }

    std::vector<std::string> SplitTokens(std::string const& csv)
    {
        std::vector<std::string> out;
        std::string cur;
        for (char c : csv)
        {
            if (c == ',')
            {
                if (!cur.empty())
                    out.push_back(cur);
                cur.clear();
            }
            else if (c != ' ' && c != '\t')
                cur += c;
        }
        if (!cur.empty())
            out.push_back(cur);
        return out;
    }

    bool Eligible(DcTestDungeonRegistry::Row const& row, uint32 expansion)
    {
        return !DcTestDungeonRegistry::IsScenario(row) &&
               DcTestDungeonRegistry::MaxPlayers(row) != 0 && DcTestDungeonRegistry::MaxPlayers(row) <= 5 &&
               DcTestDungeonRegistry::ExpansionOf(row) <= expansion;
    }
}

namespace DcDungeonQueue
{
    void OnRunDisabled(Player* tank, std::string const& reason)
    {
        if (!tank)
            return;
        std::lock_guard<std::mutex> lock(g_mailMutex);
        g_mail.emplace_back(tank->GetGUID(), reason);
    }

    void HandleAddon(Player* player, std::string const& param)
    {
        if (!player)
            return;
        std::string verb = param, arg;
        auto const tab = param.find('\t');
        if (tab != std::string::npos)
        {
            verb = param.substr(0, tab);
            arg = param.substr(tab + 1);
        }
        uint32 const now = getMSTime();
        ObjectGuid::LowType const key = player->GetGUID().GetCounter();

        if (verb == "list")
        {
            uint32 const expansion = player->GetSession() ? player->GetSession()->Expansion() : 2;
            uint32 sent = 0;
            for (DcTestDungeonRegistry::Row const& row : DcTestDungeonRegistry::All())
            {
                if (!Eligible(row, expansion))
                    continue;
                std::ostringstream os;
                os << "DC\tQROW\t" << row.token << '\t' << row.recommendedLevel << '\t' << row.heroicLevel
                   << '\t' << row.name;
                SendAddon(player, os.str());
                ++sent;
            }
            SendAddon(player, "DC\tQLISTEND\t" + std::to_string(sent));
            auto const it = g_queues.find(key);
            if (it != g_queues.end())
                Publish(player, it->second);
            return;
        }
        if (verb == "state")
        {
            auto const it = g_queues.find(key);
            if (it != g_queues.end())
                Publish(player, it->second);
            else
                SendAddon(player, "DC\tQSTATE\tidle\t0\t0\t\t0\t");
            return;
        }
        if (verb == "stop")
        {
            if (g_queues.erase(key))
            {
                Say(player, "已停止连续清本（当前副本里的清本不受影响，可以手动停止）。");
                LOG_INFO("playerbots.dungeonclear", "DCQ1A: {} queue stopped", player->GetName());
            }
            SendAddon(player, "DC\tQSTATE\tidle\t0\t0\t\t0\t已停止");
            return;
        }
        if (verb == "resume")
        {
            auto const it = g_queues.find(key);
            if (it == g_queues.end() || it->second.stage != Stage::Paused)
                return;
            Queue& q = it->second;
            Enter(player, q, q.resumeTo, "继续：" + RowName(q) + "。", now);
            return;
        }
        if (verb == "add")
        {
            std::vector<std::string>& staged = g_staged[key];
            for (std::string const& token : SplitTokens(arg))
                if (staged.size() < 200)
                    staged.push_back(token);
            return;
        }
        if (verb == "start")
        {
            std::vector<std::string> wanted;
            auto const st = g_staged.find(key);
            if (st != g_staged.end())
            {
                wanted = std::move(st->second);
                g_staged.erase(st);
            }
            for (std::string const& token : SplitTokens(arg))
                wanted.push_back(token);

            Group* group = player->GetGroup();
            if (group && !group->IsLeader(player->GetGUID()))
            {
                Say(player, "只有队长可以开始连续清本。");
                return;
            }
            uint32 const expansion = player->GetSession() ? player->GetSession()->Expansion() : 2;
            Queue q;
            for (std::string const& token : wanted)
            {
                DcTestDungeonRegistry::Row const* row = DcTestDungeonRegistry::Find(token);
                if (row && Eligible(*row, expansion) &&
                    std::find(q.tokens.begin(), q.tokens.end(), row->token) == q.tokens.end())
                    q.tokens.push_back(row->token);
            }
            if (q.tokens.empty())
            {
                Say(player, "没有勾选可用的副本。");
                return;
            }
            q.stageMs = now;
            auto& slot = g_queues[key];
            slot = std::move(q);
            LOG_INFO("playerbots.dungeonclear", "DCQ1A: {} queue started with {} dungeon(s)",
                     player->GetName(), slot.tokens.size());
            Say(player, "开始连续清本，共 " + std::to_string(slot.tokens.size()) + " 个副本。");
            Enter(player, slot, Stage::Prepare, "", now);
            return;
        }
    }
}

class DcDungeonQueueWorldScript : public WorldScript
{
public:
    DcDungeonQueueWorldScript() : WorldScript("DcDungeonQueueWorldScript") { }

    void OnUpdate(uint32 diff) override
    {
        g_accumMs += diff;
        if (g_accumMs < kTickMs)
            return;
        g_accumMs = 0;

        std::vector<std::pair<ObjectGuid, std::string>> mail;
        {
            std::lock_guard<std::mutex> lock(g_mailMutex);
            mail.swap(g_mail);
        }
        if (g_queues.empty())
            return;

        uint32 const now = getMSTime();
        for (auto it = g_queues.begin(); it != g_queues.end();)
        {
            Player* leader = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(it->first));
            if (!leader)
            {
                g_staged.erase(it->first);
                it = g_queues.erase(it);  // the player logged out: drop the queue
                continue;
            }
            // DCQ1B: a far teleport takes the player out of the world until the
            // client acks the new map. That is not a logout; wait it out. (DCQ1A
            // dropped the queue here when the reset moved the party out.)
            if (!leader->IsInWorld())
            {
                ++it;
                continue;
            }
            Queue& q = it->second;
            std::vector<std::string> reports;
            if (q.tank)
                for (auto const& m : mail)
                    if (m.first == q.tank)
                        reports.push_back(m.second);

            ++it;  // TickQueue may erase the current entry (Advance at the end of the list)
            TickQueue(leader, q, now, reports);
        }
    }
};

void AddSC_dungeon_clear_dungeon_queue()
{
    new DcDungeonQueueWorldScript();
}
