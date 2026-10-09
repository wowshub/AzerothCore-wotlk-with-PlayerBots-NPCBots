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

#include <mutex>
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
        return note;
    }
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

    if (param == "off")
    {
        if (IsSelfBot(player))
        {
            std::string const why = ToggleSelf(player);
            if (IsSelfBot(player))
                reply("DC\tSELFBOT_MSG\tfail\t" + why);
        }
        SetRole(player, "");
        reply(StateLine(player));
        return;
    }

    if (param == "tank" || param == "heal" || param == "dps")
    {
        if (!IsSelfBot(player))
        {
            std::string const why = ToggleSelf(player);
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
