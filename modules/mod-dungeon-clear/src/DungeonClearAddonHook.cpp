/*
 * mod-dungeon-clear — DungeonClearAddonHook.cpp
 *
 * PlayerScript hook that intercepts addon messages (LANG_ADDON, prefix "DC")
 * sent by the DungeonClear companion addon.  Parses "CMD\t<sub>\t<param>"
 * payloads and dispatches to the same tank-bot actions that the `.dc` slash
 * command uses.
 *
 * The addon sends commands via SendAddonMessage("DC", ..., "PARTY") in a party
 * or "RAID" in a raid, arriving as CHAT_MSG_PARTY / CHAT_MSG_RAID / LANG_ADDON.
 * (A raid must use the RAID channel: a PARTY addon message only reaches the
 * sender's subgroup, so a tank bot in another subgroup would never see it.)
 * Our OnPlayerBeforeSendChatMessage
 * hook fires before the ChatHandler switch statement, parses the command,
 * dispatches it silently (DoSpecificAction with silent=true), then consumes
 * the message so no further chat processing occurs.
 */

#include <cstdlib>

#include "ScriptMgr.h"
#include "PlayerScript.h"
#include "Chat.h"
#include "Log.h"
#include "Player.h"
#include "ServerFacade.h"
#include "Playerbots.h"
#include "PlayerbotAI.h"

#include "DcModuleEnable.h"
#include "DungeonClearDispatch.h"
#include "StringFormat.h"
#include "Util/DcSpectator.h"
#include "Util/DcSelfBot.h"
#include "TestRun/DcTestRunManager.h"
#include "AiFactory.h"
#include "Item.h"
#include "DBCStores.h"
#include "SharedDefines.h"
#include "ObjectAccessor.h"
#include "WorldSession.h"
#include "Ai/Dungeon/DungeonClear/Settings/DcSettings.h"
#include "Ai/Dungeon/DungeonClear/Settings/DcSettingsRegistry.h"
#include "Ai/Dungeon/DungeonClear/Util/DungeonClearUtil.h"

namespace
{
    // Send a raw "DC\t..." payload back to the player via the addon channel.
    void SendAddonPayload(Player* player, std::string const& payload)
    {
        if (!player)
            return;

        WorldPacket data;
        ChatHandler::BuildChatPacket(data, CHAT_MSG_PARTY, LANG_ADDON, player->GetGUID(),
                                     ObjectGuid::Empty, payload, CHAT_TAG_NONE,
                                     player->GetName());

        ServerFacade::instance().SendPacket(player, &data);
    }

    // --- RebornWOW DCTEST2A: the test window's run list -------------------
    //
    // "testruns" answers with every live `.dc test` run, its party and each member's
    // level / item level / health; "testgear <name>" with one bot's equipped items.
    // GM only, like the `.dc test` commands the window also drives.

    // A field of a tab-separated payload: no tabs or newlines inside.
    std::string AddonField(std::string s)
    {
        for (char& c : s)
            if (c == '\t' || c == '\n' || c == '\r')
                c = ' ';
        return s;
    }

    // Keep a payload inside one chat packet, never splitting a UTF-8 sequence.
    std::string ClipPayload(std::string s, std::size_t max = 250)
    {
        if (s.size() <= max)
            return s;
        std::size_t cut = max;
        while (cut > 0 && (static_cast<unsigned char>(s[cut]) & 0xC0) == 0x80)
            --cut;
        s.resize(cut);
        return s;
    }

    void SendTestRuns(Player* player)
    {
        std::vector<DcTestRunManager::AddonRunView> const runs =
            DcTestRunManager::Instance().AddonRunViews();
        // DCTEST4A: the cap in force, the conf value, and whether a GM override is set.
        SendAddonPayload(player, Acore::StringFormat("DC\tTR_START\t{}\t{}\t{}\t{}", runs.size(),
            DcTestRunManager::MaxConcurrent(), DcTestRunManager::ConfMaxConcurrent(),
            DcTestRunManager::MaxConcurrentOverridden() ? 1 : 0));
        for (DcTestRunManager::AddonRunView const& r : runs)
        {
            DcTestRunLive::RunSnapshot const& s = r.snap;
            Player* tank = ObjectAccessor::FindConnectedPlayer(r.tank);
            bool const watching = tank && tank->IsInWorld() && player->IsInWorld() &&
                                  tank->GetMap() == player->GetMap();
            SendAddonPayload(player, Acore::StringFormat(
                "DC\tTR\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}",
                AddonField(s.runId), AddonField(s.dungeon), s.heroic ? 1 : 0, AddonField(s.stage),
                s.elapsedS, s.bossesKilled, s.bossesTotal, watching ? 1 : 0, s.wiped ? 1 : 0,
                s.inCombat ? 1 : 0, s.level));
            // Free text on its own line: the run's state, its current target, and why it stalls.
            SendAddonPayload(player, ClipPayload("DC\tTRS\t" + AddonField(s.runId) + "\t" +
                                                 AddonField(s.state) + "\t" + AddonField(s.bossName) +
                                                 "\t" + AddonField(s.stall)));
            // DCTEST3A: replay data and tallies for the right-click menu.
            std::string comp;
            for (auto const& c : r.comp)
                comp += (comp.empty() ? "" : ",") + AddonField(c.first) + ":" + AddonField(c.second);
            SendAddonPayload(player, ClipPayload(Acore::StringFormat(
                "DC\tTRX\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}",
                AddonField(s.runId), r.seed, r.gearIlvl, r.gearQuality, r.roster ? 1 : 0,
                r.deaths, r.pulls, comp)));
            for (DcTestRunLive::BotPos const& b : s.bots)
            {
                Player* bot = ObjectAccessor::FindPlayerByName(b.name, false);
                uint32 const level = bot ? bot->GetLevel() : 0;
                uint32 const ilvl = bot ? uint32(bot->GetAverageItemLevel() + 0.5f) : 0;
                uint32 const spec = bot ? uint32(AiFactory::GetPlayerSpecTab(bot)) : 0;
                SendAddonPayload(player, Acore::StringFormat(
                    "DC\tTRM\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}",
                    AddonField(s.runId), AddonField(b.name), uint32(b.classId), AddonField(b.role),
                    level, ilvl, uint32(b.hp), int32(b.mp), b.alive ? 1 : 0, b.inCombat ? 1 : 0, spec));
            }
        }
        SendAddonPayload(player, "DC\tTR_END");
    }

    // DCTEST3A: one run's boss kills and deaths so far (the most recent 30 / 40).
    void SendTestInfo(Player* player, std::string const& runId)
    {
        std::vector<DcTestRunRecord::BossKill> kills;
        std::vector<DcTestRunRecord::DeathEntry> deaths;
        if (!DcTestRunManager::Instance().AddonRunDetail(runId, &kills, &deaths))
        {
            SendAddonPayload(player, "DC\tTI_ERR\t" + AddonField(runId));
            return;
        }
        SendAddonPayload(player, Acore::StringFormat("DC\tTI_START\t{}\t{}\t{}",
            AddonField(runId), kills.size(), deaths.size()));
        std::size_t const k0 = kills.size() > 30 ? kills.size() - 30 : 0;
        for (std::size_t i = k0; i < kills.size(); ++i)
            SendAddonPayload(player, ClipPayload(Acore::StringFormat("DC\tTIB\t{}\t{}",
                kills[i].t, AddonField(kills[i].name))));
        std::size_t const d0 = deaths.size() > 40 ? deaths.size() - 40 : 0;
        for (std::size_t i = d0; i < deaths.size(); ++i)
            SendAddonPayload(player, ClipPayload(Acore::StringFormat("DC\tTID\t{}\t{}\t{}\t{}",
                deaths[i].t, AddonField(deaths[i].name), deaths[i].onBoss ? 1 : 0,
                AddonField(deaths[i].opponent))));
        SendAddonPayload(player, "DC\tTI_END\t" + AddonField(runId));
    }

    // DCTEST4A: "testcap" [N|reset] -- show or set the concurrent-run cap from the panel.
    void HandleTestCap(Player* player, std::string const& param)
    {
        if (param == "reset")
        {
            DcTestRunManager::SetMaxConcurrentOverride(-1);
            LOG_INFO("module", "mod-dungeon-clear: {} reset the test-run cap to the conf value ({})",
                     player->GetName(), DcTestRunManager::ConfMaxConcurrent());
        }
        else if (!param.empty())
        {
            int32 const value = std::atoi(param.c_str());
            if (value >= 0 && value <= 100)
            {
                DcTestRunManager::SetMaxConcurrentOverride(value);
                LOG_INFO("module", "mod-dungeon-clear: {} set the test-run cap to {} (until restart)",
                         player->GetName(), value);
            }
        }
        SendAddonPayload(player, Acore::StringFormat("DC\tTRCAP\t{}\t{}\t{}",
            DcTestRunManager::MaxConcurrent(), DcTestRunManager::ConfMaxConcurrent(),
            DcTestRunManager::MaxConcurrentOverridden() ? 1 : 0));
    }

    // DCTEST4A: "testinspect <name>" -- one bot's character sheet: identity, stats,
    // equipped items with enchants and gems, every class talent with its rank,
    // glyphs and the playerbots strategies it runs with.
    void SendTestInspect(Player* player, std::string const& name)
    {
        Player* bot = name.empty() ? nullptr : ObjectAccessor::FindPlayerByName(name, false);
        if (!bot)
        {
            SendAddonPayload(player, "DC\tTIN_ERR\t" + AddonField(name));
            return;
        }
        uint8 const spec = bot->GetActiveSpec();
        auto rating = [bot](CombatRating cr) { return bot->GetUInt32Value(PLAYER_FIELD_COMBAT_RATING_1 + cr); };
        int32 spellPower = 0;
        for (uint8 school = SPELL_SCHOOL_HOLY; school < MAX_SPELL_SCHOOL; ++school)
            spellPower = std::max(spellPower, bot->GetInt32Value(PLAYER_FIELD_MOD_DAMAGE_DONE_POS + school));

        SendAddonPayload(player, Acore::StringFormat("DC\tTIN_START\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}",
            AddonField(bot->GetName()), uint32(bot->getClass()), uint32(bot->getRace()), uint32(bot->getGender()),
            uint32(bot->GetLevel()), uint32(bot->GetAverageItemLevel() + 0.5f), uint32(AiFactory::GetPlayerSpecTab(bot)),
            bot->GetMaxHealth(), bot->GetMaxPower(POWER_MANA), bot->GetFreeTalentPoints(), uint32(bot->IsAlive() ? 1 : 0)));
        // base stats, armor, attack power, spell power, healing
        SendAddonPayload(player, Acore::StringFormat("DC\tTIS\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}",
            uint32(bot->GetStat(STAT_STRENGTH)), uint32(bot->GetStat(STAT_AGILITY)), uint32(bot->GetStat(STAT_STAMINA)),
            uint32(bot->GetStat(STAT_INTELLECT)), uint32(bot->GetStat(STAT_SPIRIT)), bot->GetArmor(),
            uint32(bot->GetTotalAttackPowerValue(BASE_ATTACK)), uint32(bot->GetTotalAttackPowerValue(RANGED_ATTACK)),
            spellPower, bot->GetInt32Value(PLAYER_FIELD_MOD_HEALING_DONE_POS)));
        // ratings and percentages
        SendAddonPayload(player, Acore::StringFormat(
            "DC\tTIS2\t{}\t{}\t{:.2f}\t{:.2f}\t{:.2f}\t{}\t{}\t{}\t{}\t{}\t{:.2f}\t{:.2f}\t{:.2f}\t{}",
            rating(CR_HIT_MELEE), rating(CR_HIT_SPELL),
            bot->GetFloatValue(PLAYER_CRIT_PERCENTAGE), bot->GetFloatValue(PLAYER_RANGED_CRIT_PERCENTAGE),
            bot->GetFloatValue(PLAYER_SPELL_CRIT_PERCENTAGE1 + SPELL_SCHOOL_FIRE),
            rating(CR_HASTE_MELEE), rating(CR_HASTE_SPELL), bot->GetUInt32Value(PLAYER_EXPERTISE),
            rating(CR_ARMOR_PENETRATION), rating(CR_DEFENSE_SKILL),
            bot->GetFloatValue(PLAYER_DODGE_PERCENTAGE), bot->GetFloatValue(PLAYER_PARRY_PERCENTAGE),
            bot->GetFloatValue(PLAYER_BLOCK_PERCENTAGE), rating(CR_CRIT_TAKEN_MELEE)));

        // items: slot, entry, ilvl, quality, permanent enchant, three gem enchants,
        // random property, suffix factor, socket count
        for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
        {
            Item* item = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot);
            ItemTemplate const* proto = item ? item->GetTemplate() : nullptr;
            if (!proto)
                continue;
            uint32 sockets = 0;
            for (uint8 i = 0; i < MAX_ITEM_PROTO_SOCKETS; ++i)
                if (proto->Socket[i].Color)
                    ++sockets;
            SendAddonPayload(player, Acore::StringFormat("DC\tTII\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}",
                uint32(slot), item->GetEntry(), proto->ItemLevel, proto->Quality,
                item->GetEnchantmentId(PERM_ENCHANTMENT_SLOT),
                item->GetEnchantmentId(SOCK_ENCHANTMENT_SLOT),
                item->GetEnchantmentId(EnchantmentSlot(SOCK_ENCHANTMENT_SLOT + 1)),
                item->GetEnchantmentId(EnchantmentSlot(SOCK_ENCHANTMENT_SLOT + 2)),
                item->GetItemRandomPropertyId(), item->GetItemSuffixFactor(), sockets));
        }

        // talents: every talent of the class, learned or not -- tab page, row, column,
        // rank, max rank, and the spell of the current rank (rank 1 when unlearned)
        uint32 points[3] = { 0, 0, 0 };
        for (uint32 i = 0; i < sTalentStore.GetNumRows(); ++i)
        {
            TalentEntry const* talent = sTalentStore.LookupEntry(i);
            if (!talent)
                continue;
            TalentTabEntry const* tab = sTalentTabStore.LookupEntry(talent->TalentTab);
            if (!tab || !(tab->ClassMask & bot->getClassMask()) || tab->tabpage > 2)
                continue;
            uint32 maxRank = 0;
            uint32 rank = 0;
            for (uint32 r = 0; r < MAX_TALENT_RANK; ++r)
            {
                if (!talent->RankID[r])
                    continue;
                maxRank = r + 1;
                if (bot->HasTalent(talent->RankID[r], spec))
                    rank = r + 1;
            }
            if (!maxRank)
                continue;
            points[tab->tabpage] += rank;
            SendAddonPayload(player, Acore::StringFormat("DC\tTIT\t{}\t{}\t{}\t{}\t{}\t{}",
                tab->tabpage, talent->Row, talent->Col, rank, maxRank,
                talent->RankID[rank ? rank - 1 : 0]));
        }
        SendAddonPayload(player, Acore::StringFormat("DC\tTIP\t{}\t{}\t{}", points[0], points[1], points[2]));

        // glyphs, as their spells (the client names them)
        std::string glyphs;
        for (uint8 slot = 0; slot < MAX_GLYPH_SLOT_INDEX; ++slot)
            if (uint32 glyph = bot->GetGlyph(slot))
                if (GlyphPropertiesEntry const* gp = sGlyphPropertiesStore.LookupEntry(glyph))
                    glyphs += (glyphs.empty() ? "" : ",") + std::to_string(gp->SpellId);
        SendAddonPayload(player, "DC\tTIG\t" + glyphs);

        // playerbots strategies (combat, then non-combat)
        if (PlayerbotAI* ai = GET_PLAYERBOT_AI(bot))
        {
            auto joined = [](std::vector<std::string> const& v)
            {
                std::string out;
                for (std::string const& s : v)
                    out += (out.empty() ? "" : ", ") + AddonField(s);
                return out;
            };
            SendAddonPayload(player, ClipPayload("DC\tTIA\tco\t" + joined(ai->GetStrategies(BOT_STATE_COMBAT))));
            SendAddonPayload(player, ClipPayload("DC\tTIA\tnc\t" + joined(ai->GetStrategies(BOT_STATE_NON_COMBAT))));
        }
        SendAddonPayload(player, "DC\tTIN_END\t" + AddonField(bot->GetName()));
    }

    void SendTestGear(Player* player, std::string const& name)
    {
        Player* bot = name.empty() ? nullptr : ObjectAccessor::FindPlayerByName(name, false);
        if (!bot)
        {
            SendAddonPayload(player, "DC\tTRG_ERR\t" + AddonField(name));
            return;
        }
        SendAddonPayload(player, Acore::StringFormat("DC\tTRG_START\t{}\t{}\t{}\t{}\t{}",
            AddonField(bot->GetName()), uint32(bot->getClass()), uint32(bot->GetLevel()),
            uint32(bot->GetAverageItemLevel() + 0.5f), uint32(AiFactory::GetPlayerSpecTab(bot))));
        for (uint8 slot = EQUIPMENT_SLOT_START; slot < EQUIPMENT_SLOT_END; ++slot)
            if (Item* item = bot->GetItemByPos(INVENTORY_SLOT_BAG_0, slot))
                if (ItemTemplate const* proto = item->GetTemplate())
                    SendAddonPayload(player, Acore::StringFormat("DC\tTRG\t{}\t{}\t{}\t{}",
                        uint32(slot), item->GetEntry(), proto->ItemLevel, proto->Quality));
        SendAddonPayload(player, "DC\tTRG_END");
    }

    // Send an error back to the player via the addon message channel.
    void SendAddonError(Player* player, std::string const& msg)
    {
        SendAddonPayload(player, "DC\tERROR\t" + msg);
    }

    // Tell the addon whether the spectator free-camera is enabled server-side so
    // it can grey out / disable its Spectate button instead of letting the player
    // click into a refusal. DungeonClear.SpectateEnable is a server-only flag, so
    // this is the only way the addon learns it. Sent in answer to the addon's
    // status poll (its panel heartbeat) — tank-independent, and refreshed every
    // time the panel reopens or combat toggles.
    void SendSpectateState(Player* player)
    {
        bool const enabled = DcSettings::GetBool(player, "SpectateEnable");
        SendAddonPayload(player,
            Acore::StringFormat("DC\tSPECTATE\t{}", enabled ? 1 : 0));
    }

    // One "DC\tSETTINGS\t<key>\t<value>\t<min>\t<max>\t<type>\t<overridden>"
    // line describing one player-facing setting's effective value + schema, so
    // the addon can populate (and optionally render) its panel from the server.
    void SendSettingLine(Player* player, ObjectGuid owner, DcSettingDef const& d)
    {
        double const value = DcSettings::GetEffectiveRaw(owner, d);
        bool const overridden = DcSettings::HasOverride(owner, d.key);

        SendAddonPayload(player, Acore::StringFormat(
            "DC\tSETTINGS\t{}\t{}\t{}\t{}\t{}\t{}",
            d.key, value, d.minVal, d.maxVal,
            static_cast<int>(d.type), overridden ? 1 : 0));
    }

    // Push every player-facing setting (the full panel) to the player, framed by
    // a SYNCSTART/SYNCEND pair so the addon knows when it has the complete set.
    void SendSettingsSync(Player* player, ObjectGuid owner)
    {
        SendAddonPayload(player, "DC\tSYNCSTART");
        for (DcSettingDef const& d : kDcSettings)
            if (d.playerFacing)
                SendSettingLine(player, owner, d);
        SendAddonPayload(player, "DC\tSYNCEND");
    }

    // set / reset / sync share the same run-owner resolution. Returns false (and
    // reports an error) when the player has no leader tank to own the overrides.
    void HandleSettingsCommand(Player* player, std::string const& subCmd,
                               std::string const& param)
    {
        // The run owner is this party's leader tank, if one exists. sync works
        // without one (it just reports the server defaults so the addon panel
        // can render anywhere); set/reset need an owner to attach the override
        // to and report an error when there's no tank in the group.
        Player* leader = DcLeaderSignal::FindLeaderTank(player);
        ObjectGuid const owner = leader ? leader->GetGUID() : ObjectGuid::Empty;

        if (subCmd == "sync")
        {
            SendSettingsSync(player, owner);
            return;
        }

        if (owner.IsEmpty())
        {
            SendAddonError(player, "No tank bot found in your group.");
            return;
        }

        if (subCmd == "reset")
        {
            // param is the key to reset, or empty to reset the whole run.
            DcSettings::ResetOverride(owner, param);
            SendSettingsSync(player, owner);
            return;
        }

        // subCmd == "set": param is "<key>\t<value>".
        auto const sep = param.find('\t');
        if (sep == std::string::npos)
        {
            SendAddonError(player, "set requires <key> <value>.");
            return;
        }

        std::string const key = param.substr(0, sep);
        std::string const valStr = param.substr(sep + 1);

        char* end = nullptr;
        double const value = std::strtod(valStr.c_str(), &end);
        if (end == valStr.c_str())
        {
            SendAddonError(player, "Invalid value for " + key + ".");
            return;
        }

        std::string err;
        if (!DcSettings::SetOverride(owner, key, value, &err))
        {
            SendAddonError(player, err);
            return;
        }

        // Echo the stored (clamped) value back so the addon shows the truth.
        if (DcSettingDef const* d = FindDcSetting(key))
            SendSettingLine(player, owner, *d);
    }
}

class DungeonClearAddonHookScript : public PlayerScript
{
public:
    DungeonClearAddonHookScript()
        : PlayerScript("DungeonClearAddonHookScript", {
            PLAYERHOOK_ON_BEFORE_SEND_CHAT_MESSAGE,
            PLAYERHOOK_CAN_PLAYER_USE_GROUP_CHAT,
            PLAYERHOOK_ON_LOGOUT
        }) {}

    // True for the addon's client->server control messages, which ride in as an
    // addon chat line of the form "DC\tCMD\t<sub>[\t<param>]". Shared by the
    // parse hook (OnPlayerBeforeSendChatMessage, which acts on them) and the
    // relay-block hook (OnPlayerCanUseChat, which stops the core forwarding
    // them to the rest of the group).
    //
    // WHISPER is the solo transport. The addon's normal channel is PARTY/RAID,
    // which simply does not exist for a player with no group — so a GM watching
    // a test run from outside the bot party could not press any button at all,
    // spectate included, even though the spectator camera itself has never had
    // a group requirement. A whisper to oneself is the standard addon-message
    // channel for that case. The server dispatch self-authorizes either way
    // (bot commands still need a tank bot in the sender's group and say so),
    // so accepting the extra channel grants no new authority.
    static bool IsDcAddonCommand(uint32 type, uint32 lang, std::string const& msg)
    {
        if (lang != LANG_ADDON)
            return false;
        if (type != CHAT_MSG_PARTY && type != CHAT_MSG_PARTY_LEADER &&
            type != CHAT_MSG_RAID && type != CHAT_MSG_RAID_LEADER &&
            type != CHAT_MSG_WHISPER)
            return false;
        // "DC\t" (3) + "CMD\t" (4) = 7-byte prefix.
        return msg.compare(0, 7, "DC\tCMD\t") == 0;
    }

    // Per-run overrides are keyed by the leader tank's GUID; drop them when that
    // player logs out so stale leader GUIDs don't accumulate. A no-op for any
    // player who never owned a run.
    void OnPlayerLogout(Player* player) override
    {
        if (!DcModule::IsEnabled())
            return;  // no run can exist, so no override store to clear
        if (player)
        {
            DcSettings::ClearRun(player->GetGUID());
            DcSelfBot::Forget(player);
        }
    }

    // Block the core from relaying our own control messages to the rest of the
    // group. We already act on them in OnPlayerBeforeSendChatMessage; returning
    // false here silently drops the packet. This REPLACES the old "consume"
    // trick of rewriting `type` to CHAT_MSG_ADDON (= 0xFFFFFFFF): that value has
    // no case in HandleMessagechatOpcode's `switch (type)`, so every command
    // fell through to the default and logged
    // "CHAT: unknown message type 4294967295, lang: 4294967295" — once per
    // command, and constantly from the addon's status-poll heartbeat.
    bool OnPlayerCanUseChat(Player* /*player*/, uint32 type, uint32 lang, std::string& msg, Group* /*group*/) override
    {
        return !IsDcAddonCommand(type, lang, msg);
    }

    void OnPlayerBeforeSendChatMessage(Player* player, uint32& type, uint32& lang, std::string& msg) override
    {
        // Only our addon control messages ("DC\tCMD\t...", on party/raid addon
        // chat). The addon sends on RAID when the player is in a raid so the
        // command reaches a tank bot in any subgroup — on PARTY it would only
        // reach the sender's own subgroup. The matching relay-suppression lives
        // in OnPlayerCanUseChat above; here we only act on the command.
        if (!IsDcAddonCommand(type, lang, msg))
            return;

        // Master switch: answer the panel instead of silently dropping every
        // button it presses. The relay suppression in OnPlayerCanUseChat still
        // applies (the payload is ours either way, and must not reach party
        // chat as text). See DcModuleEnable.h.
        if (!DcModule::IsEnabled())
        {
            SendAddonError(player,
                           "mod-dungeon-clear is disabled on this server "
                           "(DungeonClear.Enable = 0).");
            return;
        }

        // Parse "DC\tCMD\t<subcommand>[\t<param>]" — strip the 7-byte prefix.
        std::string const cmdPayload = msg.substr(7);
        std::string subCmd;
        std::string param;

        auto const tabPos = cmdPayload.find('\t');
        if (tabPos == std::string::npos)
        {
            subCmd = cmdPayload;
        }
        else
        {
            subCmd = cmdPayload.substr(0, tabPos);
            param = cmdPayload.substr(tabPos + 1);
        }

        if (subCmd.empty())
            return;

        // Per-run settings overrides (set/reset/sync) are handled in-process
        // rather than dispatched as a tank-bot action.
        if (subCmd == "set" || subCmd == "reset" || subCmd == "sync")
        {
            HandleSettingsCommand(player, subCmd, param);
            return;
        }

        // Spectator camera: acts on the sending player directly (session
        // plumbing, not a tank-bot action) — never dispatched. Bare = the
        // free-flying camera; "follow" rides the run's tank instead.
        if (subCmd == "spectate")
        {
            std::string whyNot;
            bool ok = true;
            if (param == "follow")
                ok = DcSpectator::ToggleFollow(player, nullptr, &whyNot);
            else if (param == "next")
                ok = DcSpectator::CycleFollow(player, +1, &whyNot);
            else if (param == "prev")
                ok = DcSpectator::CycleFollow(player, -1, &whyNot);
            else
                ok = DcSpectator::Toggle(player, &whyNot);
            if (!ok)
                SendAddonError(player, whyNot);
            return;
        }

        // Test-run list for the addon's test window (RebornWOW DCTEST2A): read-only
        // views of the `.dc test` harness, answered in-process. GM only.
        if (subCmd == "testruns" || subCmd == "testgear" || subCmd == "testinfo" ||
            subCmd == "testinspect" || subCmd == "testcap")
        {
            if (!player->GetSession() || player->GetSession()->GetSecurity() < SEC_GAMEMASTER)
            {
                SendAddonPayload(player, "DC\tTR_ERR\tgm");
                return;
            }
            if (subCmd == "testruns")
                SendTestRuns(player);
            else if (subCmd == "testinfo")
                SendTestInfo(player, param);
            else if (subCmd == "testinspect")
                SendTestInspect(player, param);
            else if (subCmd == "testcap")
                HandleTestCap(player, param);
            else
                SendTestGear(player, param);
            return;
        }

        // Self-bot ("let the AI play me", RebornWOW DCSB1A): acts on the sending
        // player directly, like spectate -- never dispatched to a tank bot.
        if (subCmd == "selfbot")
        {
            DcSelfBot::Handle(player, param,
                [player](std::string const& payload) { SendAddonPayload(player, payload); });
            return;
        }

        // Piggyback the spectate-enabled flag on the addon's status poll: it's
        // the panel's heartbeat (sent on open and on combat transitions), so the
        // button stays in sync regardless of whether a tank bot is present.
        if (subCmd == "status")
        {
            SendSpectateState(player);
            SendAddonPayload(player, DcSelfBot::StateLine(player));
        }

        // Map subcommand strings to action names.
        std::string action;
        if (subCmd == "on")         action = "dc on";
        else if (subCmd == "off")   action = "dc off";
        else if (subCmd == "skip")  action = "dc skip";
        else if (subCmd == "pause") action = "dc pause";
        else if (subCmd == "pull")  action = "dc pull";
        else if (subCmd == "status") action = "dc status";
        else if (subCmd == "bosses") action = "dc bosses";
        else if (subCmd == "go")    action = "dc go";
        else if (subCmd == "wing")  action = "dc wing";
        else
        {
            LOG_DEBUG("module", "mod-dungeon-clear: unknown addon subcommand '{}' from {}",
                      subCmd, player->GetName());
            return;
        }

        // Dispatch to the tank bot(s) silently (no PlaySound emotes). Relay
        // suppression is handled by OnPlayerCanUseChat — see the note there.
        if (!DungeonClearDispatch::DispatchToTankBots(player, action, param))
            SendAddonError(player, "No tank bot found in your group.");
    }
};

void AddSC_dungeon_clear_addon_hook()
{
    new DungeonClearAddonHookScript();
}
