/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license, you may redistribute it
 * and/or modify it under version 3 of the License, or (at your option), any later version.
 */

#include "DcInstanceReset.h"

#include <unordered_map>
#include <vector>

#include "Chat.h"
#include "DBCStructure.h"
#include "Group.h"
#include "GroupMgr.h"
#include "Log.h"
#include "Map.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "Playerbots.h"
#include "ScriptMgr.h"
#include "SharedDefines.h"
#include "Timer.h"
#include "Ai/Dungeon/DungeonClear/Util/DcRun.h"

namespace
{
    // How long the teleports may take before the reset gives up and says who is
    // still inside. Far teleports normally complete within a couple of seconds.
    constexpr uint32 kWaitMs = 20000;
    constexpr uint32 kPollMs = 500;

    struct Pending
    {
        std::vector<ObjectGuid> members;  // everyone who must be outside, leader included
        uint32 deadlineMs = 0;
    };

    // World-thread only: written by Request (chat opcode, PROCESS_THREADUNSAFE)
    // and read by the WorldScript update below.
    std::unordered_map<ObjectGuid::LowType, Pending> g_pending;

    void Say(Player* player, std::string const& text)
    {
        if (player && player->GetSession())
            ChatHandler(player->GetSession()).SendSysMessage(("|cff33ccff[副本重置]|r " + text).c_str());
    }

    bool IsBot(Player* player)
    {
        PlayerbotAI* ai = GET_PLAYERBOT_AI(player);
        return ai && !ai->IsRealPlayer();
    }

    // A member still counts as inside while a teleport is in flight or while it
    // stands on any non-raid dungeon map.
    bool StillInside(Player* member)
    {
        if (member->IsBeingTeleported())
            return true;
        Map* map = member->FindMap();
        return map && map->IsDungeon() && !map->IsRaid();
    }

    void DoReset(Player* leader)
    {
        if (Group* group = leader->GetGroup())
            group->ResetInstances(INSTANCE_RESET_ALL, false, leader);
        else
            Player::ResetInstances(leader->GetGUID(), INSTANCE_RESET_ALL, false);
        Say(leader, "完成。看到“已被重置”的提示就可以重新进入；没有提示说明没有可重置的普通副本。"
                    " / Done. Re-enter after the \"has been reset\" notice; no notice means nothing was left to reset.");
        LOG_INFO("playerbots.dungeonclear", "DCRST1A: {} reset instances", leader->GetName());
    }
}

namespace DcInstanceReset
{
    bool Request(Player* leader, std::string* whyNot)
    {
        auto refuse = [whyNot](std::string const& text)
        {
            if (whyNot)
                *whyNot = text;
            return false;
        };

        if (!leader || !leader->IsInWorld())
            return refuse("角色未就绪 / Character not ready.");
        if (g_pending.count(leader->GetGUID().GetCounter()))
            return refuse("上一次重置还在进行中 / A reset is already in progress.");

        Group* group = leader->GetGroup();
        if (group && !group->IsLeader(leader->GetGUID()))
            return refuse("只有队长可以重置副本 / Only the group leader can reset instances.");
        if (group && (group->isBGGroup() || group->isBFGroup()))
            return refuse("战场队伍不能重置副本 / Not available in a battleground group.");
        if (leader->GetDifficulty(false) != DUNGEON_DIFFICULTY_NORMAL)
            return refuse("只能重置普通难度；英雄难度要等每日重置 / Only normal difficulty can be reset; heroic waits for the daily reset.");

        // The members to move, and the checks that would make the move unsafe.
        std::vector<Player*> members;
        members.push_back(leader);
        bool hasOtherHuman = false;
        if (group)
        {
            for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
            {
                Player* member = ref->GetSource();
                if (!member || member == leader || !member->IsInWorld())
                    continue;
                members.push_back(member);
                if (!IsBot(member))
                    hasOtherHuman = true;
            }
        }

        std::string busy;
        for (Player* member : members)
        {
            if (member->IsInCombat())
                busy += member->GetName() + "(战斗中/in combat) ";
            else if (member->isDead())
                busy += member->GetName() + "(死亡/dead) ";
            else if (PlayerbotAI* ai = GET_PLAYERBOT_AI(member))
                if (!ai->IsRealPlayer() && DcRun::Of(ai).enabled)
                    busy += member->GetName() + "(清本运行中/clear running) ";
        }
        if (!busy.empty())
            return refuse("请先处理：" + busy + "/ Resolve first.");

        // Where the people inside go: this dungeon's exit when the leader is
        // inside one, otherwise the leader's own spot.
        Map* leaderMap = leader->GetMap();
        uint32 destMap = leader->GetMapId();
        float destX = leader->GetPositionX(), destY = leader->GetPositionY(), destZ = leader->GetPositionZ();
        float destO = leader->GetOrientation();
        if (leaderMap && leaderMap->IsDungeon())
        {
            if (leaderMap->IsRaid())
                return refuse("团队副本不在此功能范围内 / Raids are not handled here.");
            AreaTriggerTeleport const* exit = sObjectMgr->GetGoBackTrigger(leader->GetMapId());
            if (!exit)
                return refuse("找不到这个副本的出口 / No exit known for this dungeon.");
            destMap = exit->target_mapId;
            destX = exit->target_X;
            destY = exit->target_Y;
            destZ = exit->target_Z;
            destO = exit->target_Orientation;
        }

        // An LFG group cannot reset at all (Group::ResetInstances returns at once).
        // Rebuild it as an ordinary group with the same playerbots.
        if (group && group->isLFGGroup())
        {
            if (hasOtherHuman)
                return refuse("队伍是随机副本队伍，里面有其他真人玩家，无法自动重组；请手动退组重组 "
                              "/ LFG group with other players: disband and regroup by hand.");
#ifdef MOD_NPCERBOTS
            if (group->GetFirstBotMember())
                return refuse("队伍里有 NpcBots 随从，无法自动重组；请手动退组重组 "
                              "/ NpcBots in the group: disband and regroup by hand.");
#endif
            std::vector<ObjectGuid> bots;
            for (Player* member : members)
                if (member != leader)
                    bots.push_back(member->GetGUID());

            group->Disband();
            group = nullptr;

            Group* fresh = new Group();
            if (!fresh->Create(leader))
            {
                delete fresh;
                Say(leader, "队伍已解散，但新队伍创建失败；请手动邀请机器人 / Disbanded, but could not create the new group.");
                return true;  // the old group is gone; nothing more to do safely
            }
            sGroupMgr->AddGroup(fresh);
            uint32 added = 0;
            for (ObjectGuid guid : bots)
                if (Player* bot = ObjectAccessor::FindConnectedPlayer(guid))
                    if (fresh->AddMember(bot))
                        ++added;
            group = fresh;
            Say(leader, "随机副本队伍已改为普通队伍，重新加入 " + std::to_string(added) + " 个机器人 "
                        "/ LFG group rebuilt as a normal group.");
            LOG_INFO("playerbots.dungeonclear", "DCRST1A: {} rebuilt LFG group as normal ({} bot(s))",
                     leader->GetName(), added);
        }

        // Move everyone who is inside a dungeon out.
        Pending pending;
        uint32 moved = 0;
        for (Player* member : members)
        {
            pending.members.push_back(member->GetGUID());
            Map* map = member->GetMap();
            if (!map || !map->IsDungeon() || map->IsRaid())
                continue;
            member->RemoveAurasWithInterruptFlags(AURA_INTERRUPT_FLAG_TELEPORTED | AURA_INTERRUPT_FLAG_CHANGE_MAP);
            if (member->TeleportTo(destMap, destX, destY, destZ, destO))
                ++moved;
        }

        if (!moved)
        {
            DoReset(leader);
            return true;
        }

        pending.deadlineMs = getMSTime() + kWaitMs;
        g_pending[leader->GetGUID().GetCounter()] = std::move(pending);
        Say(leader, "正在把 " + std::to_string(moved) + " 名队员传出副本，全部出来后自动重置 "
                    "/ Moving members out; the reset follows.");
        LOG_INFO("playerbots.dungeonclear", "DCRST1A: {} moving {} member(s) out before reset",
                 leader->GetName(), moved);
        return true;
    }
}

class DcInstanceResetWorldScript : public WorldScript
{
public:
    DcInstanceResetWorldScript() : WorldScript("DcInstanceResetWorldScript") { }

    void OnUpdate(uint32 diff) override
    {
        if (g_pending.empty())
            return;
        _accum += diff;
        if (_accum < kPollMs)
            return;
        _accum = 0;

        uint32 const now = getMSTime();
        for (auto it = g_pending.begin(); it != g_pending.end();)
        {
            Player* leader = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(it->first));
            if (!leader || !leader->IsInWorld())
            {
                it = g_pending.erase(it);
                continue;
            }

            std::string inside;
            for (ObjectGuid guid : it->second.members)
                if (Player* member = ObjectAccessor::FindConnectedPlayer(guid))
                    if (member->IsInWorld() ? StillInside(member) : member->IsBeingTeleported())
                        inside += member->GetName() + " ";

            if (inside.empty())
            {
                DoReset(leader);
                it = g_pending.erase(it);
                continue;
            }

            if (static_cast<int32>(now - it->second.deadlineMs) >= 0)
            {
                Say(leader, "以下队员还在副本里，重置取消：" + inside + "/ Still inside, reset cancelled.");
                LOG_INFO("playerbots.dungeonclear", "DCRST1A: {} reset cancelled, still inside: {}",
                         leader->GetName(), inside);
                it = g_pending.erase(it);
                continue;
            }
            ++it;
        }
    }

private:
    uint32 _accum = 0;
};

void AddSC_dungeon_clear_instance_reset()
{
    new DcInstanceResetWorldScript();
}
