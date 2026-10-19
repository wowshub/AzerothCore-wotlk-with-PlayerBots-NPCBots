/*
 * mod-dungeon-clear — DcSelfBot.cpp  (RebornWOW DCSB1A). See DcSelfBot.h.
 */

#include "Util/DcSelfBot.h"

#include "Player.h"
#include "SharedDefines.h"
#include "Playerbots.h"
#include "PlayerbotAI.h"
#include "PlayerbotMgr.h"
#include "AiFactory.h"
#include "Chat.h"                 // DCSB2A
#include "Group.h"
#include "Log.h"                  // PBSELF1A
#include "Map.h"
#include "ObjectAccessor.h"
#include "PlayerbotAIConfig.h"
#include "PlayerbotRepository.h"
#include "ScriptMgr.h"
#include "ServerFacade.h"
#include "StringFormat.h"
#include "WorldPacket.h"
#include "Ai/Dungeon/DungeonClear/Util/DcStatusPublisher.h"
#include <vector>

#include <mutex>
#include "Timer.h"
#include <algorithm>
#include <unordered_map>

namespace
{
    // The role last chosen per player, only for showing it on the panel.
    std::mutex g_roleLock;
    std::unordered_map<ObjectGuid::LowType, std::string> g_roles;

    std::string RoleOf(Player* player)
    {
        std::lock_guard<std::mutex> guard(g_roleLock);
        auto itr = g_roles.find(player->GetGUID().GetCounter());
        return itr != g_roles.end() ? itr->second : std::string();
    }

    void SetRole(Player* player, std::string const& role)
    {
        std::lock_guard<std::mutex> guard(g_roleLock);
        if (role.empty())
            g_roles.erase(player->GetGUID().GetCounter());
        else
            g_roles[player->GetGUID().GetCounter()] = role;
    }

    // A real player with a playerbot AI is a self-bot (bots never send addon commands).
    bool IsSelfBot(Player* player)
    {
        return GET_PLAYERBOT_AI(player) != nullptr;
    }

    // Run the playerbots `.playerbots bot self` toggle; its messages explain a refusal.
    std::string ToggleSelf(Player* player)
    {
        PlayerbotMgr* mgr = GET_PLAYERBOT_MGR(player);
        if (!mgr)
            return "playerbots is not available for this character.";
        char args[] = "self";  // HandlePlayerbotCommand strtok()s its argument in place
        std::string out;
        for (std::string const& line : mgr->HandlePlayerbotCommand(args, player))
            out += (out.empty() ? "" : " ") + line;
        return out;
    }

    // Combat-engine strategy change that turns the talent defaults into `role`.
    // Empty = keep the defaults (talents already fit, or nothing better exists).
    // `fallback` is set when the class cannot play the role.
    std::string RoleChange(Player* player, std::string const& role, bool& fallback)
    {
        fallback = false;
        uint8 const cls = player->getClass();
        bool const specTank = PlayerbotAI::IsTank(player, true);
        bool const specHeal = PlayerbotAI::IsHeal(player, true);
        std::string const untank = "-tank,-tank assist,-pull,-pull back,-tank face,-bthreat";

        if (role == "tank")
        {
            if (specTank)
                return "";
            switch (cls)
            {
                case CLASS_WARRIOR:      return "-arms,-fury,-dps assist,-behind,+tank,+tank assist,+pull,+pull back,+tank face";
                case CLASS_PALADIN:      return "-dps,-heal,-dps assist,-behind,+tank,+tank assist,+pull,+pull back,+tank face,+bthreat";
                case CLASS_DRUID:        return "-cat,-balance,-resto,-dps assist,-behind,+bear,+tank assist,+pull,+pull back,+tank face";
                case CLASS_DEATH_KNIGHT: return "-frost,-unholy,-frost aoe,-unholy aoe,-dps assist,-behind,+blood,+tank assist,+pull,+pull back,+tank face";
                default:                 fallback = true; return "";
            }
        }

        if (role == "heal")
        {
            if (specHeal)
                return "";
            switch (cls)
            {
                case CLASS_PRIEST:  return "-dps,-shadow debuff,-shadow aoe,+heal";
                case CLASS_SHAMAN:  return "-ele,-enh,-magma,+resto";
                case CLASS_PALADIN: return "-dps," + untank + ",+heal,+bcast";
                case CLASS_DRUID:   return "-cat,-bear,-balance," + untank + ",+resto";
                default:            fallback = true; return "";
            }
        }

        // dps
        if (!specTank && !specHeal)
            return "";
        switch (cls)
        {
            case CLASS_WARRIOR:      return untank + ",+arms,+dps assist";
            case CLASS_PALADIN:      return "-heal," + untank + ",+dps,+dps assist";
            case CLASS_DRUID:        return "-bear,-resto," + untank +
                                            (AiFactory::GetPlayerSpecTab(player) == 1 ? ",+cat" : ",+balance") + ",+dps assist";
            case CLASS_DEATH_KNIGHT: return "-blood," + untank + ",+frost,+dps assist";
            case CLASS_PRIEST:       return "-heal,-holy heal,+dps,+dps assist";
            case CLASS_SHAMAN:       return "-resto,+ele";
            default:                 return "";
        }
    }

    bool IsClassicClass(uint8 cls)
    {
        switch (cls)
        {
            case CLASS_WARRIOR: case CLASS_PALADIN: case CLASS_HUNTER: case CLASS_ROGUE: case CLASS_PRIEST:
            case CLASS_DEATH_KNIGHT: case CLASS_SHAMAN: case CLASS_MAGE: case CLASS_WARLOCK: case CLASS_DRUID:
                return true;
            default:
                return false;
        }
    }

    // Returns a note for the player (empty when the role applied as asked).
    std::string ApplyRole(Player* player, std::string const& role)
    {
        PlayerbotAI* ai = GET_PLAYERBOT_AI(player);
        if (!ai)
            return "";

        // Start from the talent defaults (re-applies the dungeon's own strategy too).
        ai->SelectiveResetStrategies(BOT_STATE_COMBAT);

        std::string note;
        bool fallback = false;
        std::string const change = RoleChange(player, role, fallback);
        if (!change.empty())
            ai->ChangeStrategy(change, BOT_STATE_COMBAT);

        if (!IsClassicClass(player->getClass()))
        {
            // No class AI in playerbots yet (e.g. Witch Doctor): pick the party's target and
            // keep hitting it with the ranged weapon, else in melee.
            ai->ChangeStrategy("+dps assist,+dc selfbot basic", BOT_STATE_COMBAT);
            note = "no-class-ai";
        }
        else if (fallback)
        {
            note = "role-unsupported";
        }

        // Dodge ground effects and move with a dungeon-clear run like any party bot.
        // Back to the tank when this character is still fighting after the party stopped.
        ai->ChangeStrategy("+avoid aoe,+dungeon clear combat,+dc selfbot regroup", BOT_STATE_COMBAT);
        ai->ChangeStrategy("+dungeon clear", BOT_STATE_NON_COMBAT);
        // RebornWOW DCSB2B: the talent defaults also put tank strategies in the
        // NON-combat engine (a protection paladin: "tank assist", "pull", "bthreat").
        // Left there, a DPS / healer still reads as a tank (PlayerbotAI::IsTank checks
        // every engine), pulls between packs and buffs threat.
        if (role != "tank")
            ai->ChangeStrategy("-tank assist,-pull,-bthreat", BOT_STATE_NON_COMBAT);
        return note;
    }
}

// RebornWOW DCSB2A ---------------------------------------------------------------
// Auto-play for ordinary players, but only where design doc §10 allows it: inside a
// dungeon while their party runs dungeon clear (AiPlayerbot.SelfBotLevel stays 1 =
// GMs only everywhere else; 0 still disables it for everybody). Every 3 s:
//   - a real player in a party with a running clear, in the same dungeon, who has not
//     been asked for this run yet, gets "DC\tSBASK\t<suggested role>\t<tank>" and the
//     addon pops "auto (tank / heal / dps) or manual";
//   - a granted player who left the dungeon or the party is handed back (AI off).
namespace
{
    std::mutex g_grantLock;
    std::unordered_map<uint32, uint32> g_granted;    // player (low guid) -> 1 while granted
    // RebornWOW DCSB2C: one ask per run = tank + its instance; resent until answered.
    struct Asked
    {
        ObjectGuid tank;
        uint32 instance = 0;
        uint32 sentAt = 0;     // getMSTime() of the last send
        uint8 sends = 0;
        bool answered = false; // the player pressed an auto-play button (Manual included)
    };
    constexpr uint8 kAskSends = 3;
    constexpr uint32 kAskResendMs = 6000;
    std::unordered_map<uint32, Asked> g_asked;  // player (low guid) -> the current ask

    void SendAddon(Player* player, std::string const& payload)
    {
        if (!player || !player->GetSession())
            return;
        WorldPacket data;
        ChatHandler::BuildChatPacket(data, CHAT_MSG_PARTY, LANG_ADDON, player->GetGUID(), ObjectGuid::Empty, payload,
                                     CHAT_TAG_NONE, player->GetName());
        ServerFacade::instance().SendPacket(player, &data);
    }

    // The party's running dungeon-clear tank in the player's own dungeon copy, if any.
    Player* ActiveTankOf(Player* player)
    {
        Group* g = player->GetGroup();
        if (!g || !player->GetMap() || !player->GetMap()->IsDungeon())
            return nullptr;
        for (ObjectGuid const& guid : DcStatusPublisher::ActiveTanks())
            if (Player* tank = ObjectAccessor::FindConnectedPlayer(guid))
                if (tank->GetGroup() == g && tank->GetMap() == player->GetMap())
                    return tank;
        return nullptr;
    }

    // Turn the AI on: the stock rule, or (SelfBotLevel 1, not a GM) the dungeon-clear one.
    std::string EnableSelf(Player* player)
    {
        if (sPlayerbotAIConfig.selfBotLevel != 1 || player->CanBeGameMaster())
            return ToggleSelf(player);
        if (!ActiveTankOf(player))
            return "Auto-play is only available inside a dungeon while your party runs dungeon clear.";
        PlayerbotsMgr::instance().AddPlayerbotData(player, true);
        PlayerbotAI* ai = GET_PLAYERBOT_AI(player);
        if (!ai)
            return "playerbots could not start the AI for this character.";
        ai->SetMaster(player);
        PlayerbotRepository::instance().Load(ai);
        std::lock_guard<std::mutex> lock(g_grantLock);
        g_granted[player->GetGUID().GetCounter()] = 1;
        return "";
    }

    void Ungrant(Player* player)
    {
        std::lock_guard<std::mutex> lock(g_grantLock);
        g_granted.erase(player->GetGUID().GetCounter());
    }

    char const* SuggestRole(Player* player)
    {
        if (PlayerbotAI::IsTank(player, true))
            return "tank";
        if (PlayerbotAI::IsHeal(player, true))
            return "heal";
        return "dps";
    }

    class DcSelfBotRunScript : public WorldScript
    {
    public:
        DcSelfBotRunScript() : WorldScript("DcSelfBotRunScript") {}

        void OnUpdate(uint32 diff) override
        {
            _accum += diff;
            if (_accum < 3000)
                return;
            _accum = 0;

            // 1. hand back players who left the dungeon or the party
            std::vector<uint32> granted;
            {
                std::lock_guard<std::mutex> lock(g_grantLock);
                for (auto const& kv : g_granted)
                    granted.push_back(kv.first);
            }
            for (uint32 low : granted)
            {
                Player* p = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(low));
                if (!p || !GET_PLAYERBOT_AI(p))
                {
                    std::lock_guard<std::mutex> lock(g_grantLock);
                    g_granted.erase(low);
                    continue;
                }
                if (!p->IsInWorld() || p->IsBeingTeleported())
                    continue;
                if (p->GetGroup() && p->GetMap() && p->GetMap()->IsDungeon())
                    continue;
                ToggleSelf(p);  // AI off
                SetRole(p, "");
                Ungrant(p);
                SendAddon(p, "DC\tSELFBOT_MSG\trevoked\t");
                SendAddon(p, DcSelfBot::StateLine(p));
            }

            // 2. ask real players in a party with a running clear
            std::vector<ObjectGuid> const tanks = DcStatusPublisher::ActiveTanks();
            {
                // RebornWOW DCSB2C: a finished clear forgets its asks, so the next run
                // (even with the same bot tank) asks again
                std::lock_guard<std::mutex> lock(g_grantLock);
                for (auto it = g_asked.begin(); it != g_asked.end();)
                    it = std::find(tanks.begin(), tanks.end(), it->second.tank) == tanks.end() ? g_asked.erase(it) : std::next(it);
            }
            uint32 const nowMs = getMSTime();
            for (ObjectGuid const& tankGuid : tanks)
            {
                Player* tank = ObjectAccessor::FindConnectedPlayer(tankGuid);
                Group* g = tank ? tank->GetGroup() : nullptr;
                if (!g || !tank->GetMap() || !tank->GetMap()->IsDungeon())
                    continue;
                for (GroupReference* ref = g->GetFirstMember(); ref; ref = ref->next())
                {
                    Player* m = ref->GetSource();
                    if (!m || m == tank || GET_PLAYERBOT_AI(m) || m->GetMap() != tank->GetMap() || !m->IsInWorld() ||
                        m->IsBeingTeleported())
                        continue;  // bots, players already on auto-play, members elsewhere or loading
                    if (g->IsLeader(m->GetGUID()))
                        continue;  // the leader runs the clear from the panel
                    uint32 const low = m->GetGUID().GetCounter();
                    {
                        // RebornWOW DCSB2C: per run (tank + instance); resend a few times
                        // until answered -- a message during the loading screen is lost
                        std::lock_guard<std::mutex> lock(g_grantLock);
                        uint32 const inst = tank->GetInstanceId();
                        Asked& a = g_asked[low];
                        if (a.tank != tankGuid || a.instance != inst)
                            a = Asked{ tankGuid, inst, 0, 0, false };
                        if (a.answered || a.sends >= kAskSends ||
                            (a.sends > 0 && getMSTimeDiff(a.sentAt, nowMs) < kAskResendMs))
                            continue;
                        ++a.sends;
                        a.sentAt = nowMs;
                    }
                    SendAddon(m, Acore::StringFormat("DC\tSBASK\t{}\t{}", SuggestRole(m), tank->GetName()));
                }
            }
        }

    private:
        uint32 _accum = 0;
    };
}

// RebornWOW PBSELF1A: a player who logged out on auto-play was saved with the taxi
// cheat the bot AI set (the save runs before the logout hooks), so on the next login a
// non-GM without a bot AI loses it. A GM keeps a .taxicheat of their own.
namespace
{
    class DcSelfBotLoginScript : public PlayerScript
    {
    public:
        DcSelfBotLoginScript() : PlayerScript("DcSelfBotLoginScript", { PLAYERHOOK_ON_LOGIN }) {}

        void OnPlayerLogin(Player* player) override
        {
            if (!player || player->CanBeGameMaster() || GET_PLAYERBOT_AI(player) || !player->isTaxiCheater())
                return;
            player->SetTaxiCheater(false);
            LOG_INFO("module", "mod-dungeon-clear PBSELF1A: cleared a leftover auto-play taxi cheat on {}", player->GetName());
        }
    };
}

void DcSelfBot::RegisterScripts()
{
    new DcSelfBotRunScript();
    new DcSelfBotLoginScript();  // RebornWOW PBSELF1A
}

std::string DcSelfBot::StateLine(Player* player)
{
    if (!player)
        return "DC\tSELFBOT\t0\t";
    bool const on = IsSelfBot(player);
    return std::string("DC\tSELFBOT\t") + (on ? "1" : "0") + "\t" + (on ? RoleOf(player) : std::string());
}

void DcSelfBot::Forget(Player* player)
{
    if (player)
        SetRole(player, "");
}

void DcSelfBot::Handle(Player* player, std::string const& param, Reply const& reply)
{
    if (!player)
        return;

    if (param == "off" || param == "tank" || param == "heal" || param == "dps")
    {
        // RebornWOW DCSB2C: the player answered; stop resending the question
        std::lock_guard<std::mutex> lock(g_grantLock);
        auto it = g_asked.find(player->GetGUID().GetCounter());
        if (it != g_asked.end())
            it->second.answered = true;
    }

    if (param == "off")
    {
        if (IsSelfBot(player))
        {
            std::string const why = ToggleSelf(player);
            if (IsSelfBot(player))
                reply("DC\tSELFBOT_MSG\tfail\t" + why);
        }
        SetRole(player, "");
        Ungrant(player);  // RebornWOW DCSB2A
        reply(StateLine(player));
        return;
    }

    if (param == "tank" || param == "heal" || param == "dps")
    {
        if (!IsSelfBot(player))
        {
            std::string const why = EnableSelf(player);  // RebornWOW DCSB2A: the dungeon-clear rule
            if (!IsSelfBot(player))
            {
                reply("DC\tSELFBOT_MSG\tfail\t" + why);
                reply(StateLine(player));
                return;
            }
        }
        std::string const note = ApplyRole(player, param);
        SetRole(player, param);
        if (!note.empty())
            reply("DC\tSELFBOT_MSG\t" + note + "\t" + param);
        reply(StateLine(player));
        return;
    }

    // "state" or anything else: just report.
    reply(StateLine(player));
}
