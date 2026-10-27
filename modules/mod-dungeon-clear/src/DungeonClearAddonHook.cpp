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
#include "DcInstanceReset.h"
#include "DcDungeonQueue.h"
#include "TestRun/DcTestRunManager.h"
#include "TestRun/DcPrepSnapshot.h"  // RebornWOW DCPREP1A
#include "bot_ai.h"    // RebornWOW DCPREP2A
#include "botmgr.h"
#include "Group.h"
#include "DcPartyTier.h"   // RebornWOW DCGM1F
#include "DcPanelData.h"   // RebornWOW DCUI3B
#include "DcPlayerRuns.h"  // RebornWOW DCRUN1A
#include "Ai/Dungeon/DungeonClear/Util/DcRezRecovery.h"
#include "AiFactory.h"
#include "Item.h"
#include "DBCStores.h"
#include "SharedDefines.h"
#include "ObjectAccessor.h"
#include "CharacterCache.h"   // MBR1A
#include "DatabaseEnv.h"
#include <set>
#include <sstream>
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
                "DC\tTR\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}",
                AddonField(s.runId), AddonField(s.dungeon), s.heroic ? 1 : 0, AddonField(s.stage),
                s.elapsedS, s.bossesKilled, s.bossesTotal, watching ? 1 : 0, s.wiped ? 1 : 0,
                s.inCombat ? 1 : 0, s.level,
                r.gmName.empty() ? std::string("-") : AddonField(r.gmName)));  // DCTEST10A: who started it
            // Free text on its own line: the run's state, its current target, and why it stalls.
            SendAddonPayload(player, ClipPayload("DC\tTRS\t" + AddonField(s.runId) + "\t" +
                                                 AddonField(s.state) + "\t" + AddonField(s.bossName) +
                                                 "\t" + AddonField(s.stall)));
            // DCTEST3A: replay data and tallies for the right-click menu.
            std::string comp;
            for (auto const& c : r.comp)
                comp += (comp.empty() ? "" : ",") + AddonField(c.first) + ":" + AddonField(c.second);
            SendAddonPayload(player, ClipPayload(Acore::StringFormat(
                "DC\tTRX\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}",
                AddonField(s.runId), r.seed, r.gearIlvl, r.gearQuality, r.roster ? 1 : 0,
                r.deaths, r.pulls, comp,
                r.cheatTier.empty() ? std::string("-") : AddonField(r.cheatTier))));  // DCGM1B2
            for (DcTestRunLive::BotPos const& b : s.bots)
            {
                Player* bot = ObjectAccessor::FindPlayerByName(b.name, false);
                uint32 const level = bot ? bot->GetLevel() : 0;
                uint32 const ilvl = bot ? uint32(bot->GetAverageItemLevel() + 0.5f) : 0;
                uint32 const spec = bot ? uint32(AiFactory::GetPlayerSpecTab(bot)) : 0;
                // RebornWOW DCGM1A: trailing field = active GM cheats (g = god, p = power).
                std::string cheats;
                // RebornWOW DCTEST9A: trailing power type and power % so the panel draws the
                // class's own bar (rage / energy / runic power, not only mana)
                int32 powerType = -1, powerPct = -1;
                if (bot)
                {
                    Powers const pt = bot->getPowerType();
                    uint32 const maxP = bot->GetMaxPower(pt);
                    powerType = int32(pt);
                    powerPct = maxP ? int32(uint64(bot->GetPower(pt)) * 100 / maxP) : 0;
                }
                if (bot && bot->GetCommandStatus(CHEAT_GOD))
                    cheats += 'g';
                if (bot && bot->GetCommandStatus(CHEAT_POWER))
                    cheats += 'p';
                SendAddonPayload(player, Acore::StringFormat(
                    "DC\tTRM\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}",
                    AddonField(s.runId), AddonField(b.name), uint32(b.classId), AddonField(b.role),
                    level, ilvl, uint32(b.hp), int32(b.mp), b.alive ? 1 : 0, b.inCombat ? 1 : 0, spec,
                    cheats.empty() ? std::string("-") : cheats, powerType, powerPct));  // DCTEST9A
            }
        }
        // RebornWOW DCTEST6A: finished runs, newest first. TRF = outcome and
        // replay data, TRFC = party (name:role:class:level), TRFR = fail reason
        // and end time (unix seconds).
        for (DcTestRunRecord::Record const& f : DcTestRunManager::Instance().FinishedRuns())
        {
            SendAddonPayload(player, ClipPayload(Acore::StringFormat(
                "DC\tTRF\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}",
                AddonField(f.runId), AddonField(f.dungeon), f.heroic ? 1 : 0, AddonField(f.result),
                f.durationS, f.bossesKilled, f.bossesTotal, uint32(f.deaths.size()), f.testRegroups,
                uint32(f.cheats.size()), f.level, f.compSeed, f.gearIlvl, f.gearQuality,
                f.roster ? 1 : 0,
                f.cheatTier.empty() ? std::string("-") : AddonField(f.cheatTier),  // DCGM1B2
                f.gmName.empty() ? std::string("-") : AddonField(f.gmName))));     // DCTEST10A
            std::string comp;
            for (auto const& c : f.comp)
                comp += (comp.empty() ? "" : ",") + AddonField(c.name) + ":" + AddonField(c.role) +
                        ":" + AddonField(c.className) + ":" + std::to_string(c.level);
            SendAddonPayload(player, ClipPayload("DC\tTRFC\t" + AddonField(f.runId) + "\t" + comp));
            SendAddonPayload(player, ClipPayload("DC\tTRFR\t" + AddonField(f.runId) + "\t" +
                                                 std::to_string(f.endedAtMs / 1000) + "\t" +
                                                 AddonField(f.failReason)));
        }
        SendAddonPayload(player, "DC\tTR_END");
    }

    // --- RebornWOW MBR1A: level / race / faction / online for the MultiBot units list
    //
    // "botinfo" param = "a|Name,Name,...": "a" = the sender's own account characters,
    // then up to 40 named characters (favourites that are random bots, party members).
    // Only what /who would show. One line per character, then BI_END.
    void SendBotInfo(Player* player, std::string const& param)
    {
        if (!player->GetSession())
            return;
        uint32 const account = player->GetSession()->GetAccountId();
        auto line = [player](std::string const& name, uint32 cls, uint32 level, uint32 race,
                             bool online, bool mine)
        {
            SendAddonPayload(player, Acore::StringFormat("DC\tBI\t{}\t{}\t{}\t{}\t{}\t{}\t{}",
                AddonField(name), cls, level, race,
                Player::TeamIdForRace(static_cast<uint8>(race)) == TEAM_HORDE ? 1 : 0,
                online ? 1 : 0, mine ? 1 : 0));
        };
        std::size_t const bar = param.find('|');
        bool const withAccount = bar != std::string::npos && param.substr(0, bar) == "a";
        std::string const names = bar == std::string::npos ? param : param.substr(bar + 1);
        std::set<std::string> sent;
        if (withAccount)
        {
            if (QueryResult r = CharacterDatabase.Query(
                    "SELECT guid, name, class, level, race FROM characters WHERE account = {}", account))
            {
                do
                {
                    Field* f = r->Fetch();
                    ObjectGuid const guid = ObjectGuid::Create<HighGuid::Player>(f[0].Get<uint32>());
                    if (guid == player->GetGUID())
                        continue;
                    std::string const name = f[1].Get<std::string>();
                    Player* p = ObjectAccessor::FindConnectedPlayer(guid);
                    line(name, f[2].Get<uint8>(), p ? p->GetLevel() : f[3].Get<uint8>(), f[4].Get<uint8>(),
                         p != nullptr, true);
                    sent.insert(name);
                } while (r->NextRow());
            }
        }
        std::istringstream in(names);
        std::string n;
        uint32 count = 0;
        while (std::getline(in, n, ',') && count < 40)
        {
            if (n.empty() || sent.count(n))
                continue;
            ++count;
            CharacterCacheEntry const* c = sCharacterCache->GetCharacterCacheByName(n);
            if (!c)
                continue;
            Player* p = ObjectAccessor::FindConnectedPlayer(c->Guid);
            line(c->Name, c->Class, p ? p->GetLevel() : c->Level, c->Race, p != nullptr,
                 c->AccountId == account);
            sent.insert(c->Name);
        }
        SendAddonPayload(player, "DC\tBI_END");
    }

    // RebornWOW DCNPC2A: put an NPCBot into the sender's group, by name. An NPCBot is a creature:
    // the invite list cannot invite it by name. Its group join is a BotMgr call on its OWNER (the
    // same one the NPCBot gossip "join group" runs) and it lands in the owner's group. So a bot is
    // found among (1) the sender's own hired bots, then (2) the hired bots of another character of
    // the SAME ACCOUNT that is online (a character logged in as a playerbot) and standing in the
    // sender's group -- its group is then the sender's group. Nobody else's bots are touched.
    // param = "Name,Name,..." (up to 10).
    void HandleNpcJoin(Player* player, std::string const& param)
    {
        if (!player->GetSession())
            return;
        ChatHandler chat(player->GetSession());
        uint32 const account = player->GetSession()->GetAccountId();
        auto say = [&chat](std::string const& m) { chat.SendSysMessage(("|cff3da6ff[NPCBot]|r " + m).c_str()); };
        auto findIn = [](BotMgr* mgr, std::string const& name) -> Creature*
        {
            if (!mgr)
                return nullptr;
            for (auto const& kv : *mgr->GetBotMap())
                if (kv.second && kv.second->GetName() == name)
                    return kv.second;
            return nullptr;
        };
        std::istringstream in(param);
        std::string n;
        uint32 asked = 0;
        while (std::getline(in, n, ',') && asked < 10)
        {
            if (n.empty())
                continue;
            ++asked;
            BotMgr* ownerMgr = player->GetBotMgr();
            Creature* found = findIn(ownerMgr, n);
            Player* ownerChar = player;
            std::string elsewhere;
            if (!found)
            {
                for (auto const& kv : ObjectAccessor::GetPlayers())
                {
                    Player* p = kv.second;
                    if (!p || p == player || !p->IsInWorld() || !p->GetSession() ||
                        p->GetSession()->GetAccountId() != account)
                        continue;
                    Creature* bot = findIn(p->GetBotMgr(), n);
                    if (!bot)
                        continue;
                    if (player->GetGroup() && p->GetGroup() == player->GetGroup())
                    {
                        found = bot;
                        ownerMgr = p->GetBotMgr();
                        ownerChar = p;
                    }
                    else
                        elsewhere = p->GetName();
                    break;
                }
            }
            if (!found)
                say(elsewhere.empty()
                        ? Acore::StringFormat("{} is not one of your hired NPCBots (or your account's characters in this group).", n)
                        : Acore::StringFormat("{} belongs to {}; put {} in your group first.", n, elsewhere, elsewhere));
            else if (!found->IsInWorld())
                say(Acore::StringFormat("{} is not in the world.", n));
            else if (!ownerMgr->AddBotToGroup(found))
                say(Acore::StringFormat("{} could not join (the group is full).", n));
            else if (ownerChar != player)
                say(Acore::StringFormat("{} (hired by {}) joined your group.", n, ownerChar->GetName()));
        }
    }

    // DCTEST3A: one run's boss kills and deaths so far (the most recent 30 / 40).
    void SendTestInfo(Player* player, std::string const& runId)
    {
        std::vector<DcTestRunRecord::BossKill> kills;
        std::vector<DcTestRunRecord::DeathEntry> deaths;
        std::vector<DcTestRunManager::ChecklistRow> checklist;  // DCTEST7A
        std::vector<DcTestRunRecord::DamageSource> damage;      // RebornWOW DCBOSS1A
        std::vector<DcTestRunRecord::HealSource> healing;
        std::vector<DcTestRunRecord::HealerStat> healerStats;  // RebornWOW DCBOSS1B
        if (!DcTestRunManager::Instance().AddonRunDetail(runId, &kills, &deaths, &checklist, &damage, &healing, &healerStats))
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
        {
            // RebornWOW DCBOSS1A: fields 6..17 say what killed them ("-" = none)
            DcTestRunRecord::DeathEntry const& d = deaths[i];
            auto const dash = [](std::string const& v) { return v.empty() ? std::string("-") : AddonField(v); };
            SendAddonPayload(player, ClipPayload(Acore::StringFormat("DC\tTID\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}",
                d.t, AddonField(d.name), d.onBoss ? 1 : 0, AddonField(d.opponent),
                dash(d.killer), d.killerSpellId, dash(d.killerSpell), d.killerAmount, d.killerOverkill,
                d.killerHpPct, d.dmg5s, d.heal5s, dash(d.role), dash(d.topSrc),
                dash(d.topSpell) + "\t" + std::to_string(d.topAmount), dash(d.healers))));  // DCBOSS1B: field 18
        }
        // RebornWOW DCBOSS1A: damage taken by source and spell, healing by healer
        for (DcTestRunRecord::DamageSource const& t : damage)
            SendAddonPayload(player, ClipPayload(Acore::StringFormat("DC\tTIQ\t{}\t{}\t{}\t{}\t{}",  // DCBOSS1B2: TIS is the inspect window's
                AddonField(t.src), t.spellId, t.spell.empty() ? std::string("-") : AddonField(t.spell), t.total, t.hits)));
        for (DcTestRunRecord::HealSource const& t : healing)
            SendAddonPayload(player, ClipPayload(Acore::StringFormat("DC\tTIH\t{}\t{}", AddonField(t.name), t.total)));
        // RebornWOW DCBOSS1B: what each healer did with the fight
        for (DcTestRunRecord::HealerStat const& h : healerStats)
        {
            // RebornWOW DCBOSS1C: field 10 = what the engine said about casting a heal while idle
            std::string checks;
            for (auto const& kv : h.castChecks)
                checks += (checks.empty() ? "" : " | ") + kv.first + " x" + std::to_string(kv.second) + "s";
            SendAddonPayload(player, ClipPayload(Acore::StringFormat("DC\tTIX\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}",
                AddonField(h.name), h.combatS, h.movingS, h.castingS, h.lowAllyS, h.lowAllyMovingS, h.lowAllyIdleS, h.minManaPct,
                std::string("-"))));
            // RebornWOW DCBOSS1D: one short line per answer (a joined field was clipped at 250 bytes)
            for (auto const& kv : h.castChecks)
                SendAddonPayload(player, ClipPayload(Acore::StringFormat("DC\tTIY\t{}\t{}\t{}",
                    AddonField(h.name), kv.second, AddonField(kv.first))));
        }
        // RebornWOW DCTEST7A: the boss/objective checklist, in clear order.
        for (DcTestRunManager::ChecklistRow const& row : checklist)
            SendAddonPayload(player, ClipPayload(Acore::StringFormat("DC\tTIL\t{}\t{}\t{}",
                AddonField(row.name), row.objective ? 1 : 0, AddonField(row.status))));
        SendAddonPayload(player, "DC\tTI_END\t" + AddonField(runId));
    }

    // RebornWOW DCPREP1A: "prep [runId]" -- how ready the party is. Without a run id: the sender's
    // own group right now (the panel's pre-run view; anyone may ask). With one: the snapshots the
    // test harness stored when that run started (GM only, like every test-run view).
    //   PRP_START <runId|-> <refIlvl> <members>
    //   PRP_M <name> <class> <level> <role> <ilvl> <weakest> <empty slots> <durability %> <needs pet> <has pet> <talents>
    //   PRP_S <name> hp power powerType armor ap rap sp healSp crit rcrit scrit hit rhit shit haste expertise defense dodge parry block resilience
    //   PRP_B <name> <F|E|W> <aura spell id> <seconds left>      (worn flask / elixir / food)
    //   PRP_K <name> <H|M|F|E|W> <item id> <count>               (carried: health / mana potion, flask, elixir, food)
    //   PRP_END
    std::string F1(float v)
    {
        return Acore::StringFormat("{:.1f}", v);
    }

    void SendPrep(Player* player, std::string const& runId)
    {
        std::vector<std::pair<std::string, DcPrep::Snapshot>> rows;
        std::uint32_t ref = 0;
        std::string tag = "-";
        if (!runId.empty() && runId != "-")
        {
            if (!player->GetSession() || player->GetSession()->GetSecurity() < SEC_GAMEMASTER)
            {
                SendAddonPayload(player, "DC\tPRP_ERR\tgm");
                return;
            }
            if (!DcTestRunManager::Instance().AddonRunPrep(runId, &rows, &ref))
            {
                SendAddonPayload(player, "DC\tPRP_ERR\trun");
                return;
            }
            tag = AddonField(runId);
        }
        else if (Group* group = player->GetGroup())
        {
            for (GroupReference* r = group->GetFirstMember(); r; r = r->next())
                if (Player* m = r->GetSource(); m && m->IsInWorld())
                    rows.emplace_back(m->GetName(), DcPrep::Capture(m, ""));
        }
        else
            rows.emplace_back(player->GetName(), DcPrep::Capture(player, ""));
        // DCPREP2A: NPCBots are creatures, not group members, so the loop above never sees them.
        // Add the hired NPCBots of every real person in the party.
        if (runId.empty() || runId == "-")
        {
            std::vector<Player*> owners;
            if (Group* group = player->GetGroup())
            {
                for (GroupReference* r = group->GetFirstMember(); r; r = r->next())
                {
                    // a real person can carry a PlayerbotAI too (IsRealPlayer); only a true bot is skipped
                    PlayerbotAI* ownerAi = r->GetSource() ? GET_PLAYERBOT_AI(r->GetSource()) : nullptr;
                    if (Player* m = r->GetSource(); m && m->IsInWorld() && !(ownerAi && !ownerAi->IsRealPlayer()))
                        owners.push_back(m);
                }
            }
            else
                owners.push_back(player);
            for (Player* owner : owners)
            {
                BotMgr* mgr = owner->GetBotMgr();
                if (!mgr)
                    continue;
                for (auto const& kv : *mgr->GetBotMap())
                {
                    Creature* bot = kv.second;
                    if (!bot || !bot->IsInWorld())
                        continue;
                    bool dup = false;
                    for (auto const& have : rows)
                        dup = dup || have.first == bot->GetName();
                    if (!dup)
                        rows.emplace_back(bot->GetName(), DcPrep::CaptureBot(bot));
                }
            }
        }
        if (rows.size() > 10)
            rows.resize(10);

        SendAddonPayload(player, Acore::StringFormat("DC\tPRP_START\t{}\t{}\t{}", tag, ref, rows.size()));
        for (auto const& row : rows)
        {
            DcPrep::Snapshot const& s = row.second;
            std::string const n = AddonField(row.first);
            SendAddonPayload(player, ClipPayload(Acore::StringFormat("DC\tPRP_M\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}",
                n, s.classId, s.level, s.role, s.avgIlvl, s.minIlvl, s.emptySlots, s.durabilityPct,
                s.needsPet ? 1 : 0, s.hasPet ? 1 : 0, AddonField(s.talents))
                + (s.npcBot ? "\tn" : "")));
            DcPrep::Stats const& t = s.stats;
            std::string line = Acore::StringFormat("DC\tPRP_S\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}\t{}", n, t.hp, t.mana, t.powerType,
                                                   t.armor, t.ap, t.rap, t.sp, t.healSp);
            for (float v : { t.crit, t.rcrit, t.scrit, t.hit, t.rhit, t.shit, t.haste })
                line += "\t" + F1(v);
            line += Acore::StringFormat("\t{}\t{}", t.expertise, t.defense);
            for (float v : { t.dodge, t.parry, t.block })
                line += "\t" + F1(v);
            line += "\t" + std::to_string(t.resilience);
            SendAddonPayload(player, ClipPayload(line));
            for (DcPrep::Buff const& b : s.buffs)
                SendAddonPayload(player, ClipPayload(Acore::StringFormat("DC\tPRP_B\t{}\t{}\t{}\t{}", n, b.kind, b.spellId, b.secs)));
            for (DcPrep::Stock const& k : s.stock)
                SendAddonPayload(player, ClipPayload(Acore::StringFormat("DC\tPRP_K\t{}\t{}\t{}\t{}", n, k.kind, k.itemId, k.count)));
        }
        SendAddonPayload(player, "DC\tPRP_END\t" + tag);
    }

    // RebornWOW DCGM3A: "gmcmd <text>" -- a GM command typed from the panel by a player who cannot
    // speak (dead): chat is refused to the dead, the addon channel is not. Run through the
    // ordinary command parser of the player's own session, so every command still checks its own
    // security level; GM accounts only, and only what the panel itself sends.
    void HandleGmCommand(Player* player, std::string const& param)
    {
        WorldSession* session = player->GetSession();
        if (!session || session->GetSecurity() < SEC_GAMEMASTER)
        {
            SendAddonPayload(player, "DC\tTR_ERR\tgm");
            return;
        }
        static char const* const allowed[] = { ".dc ", ".gps", ".go xyz ", ".groupsummon " };
        bool ok = false;
        for (char const* prefix : allowed)
            if (param.rfind(prefix, 0) == 0)
            {
                ok = true;
                break;
            }
        if (!ok)
        {
            LOG_WARN("module", "mod-dungeon-clear: {} sent a gmcmd the panel does not send: '{}'", player->GetName(), param);
            return;
        }
        ChatHandler handler(session);
        if (!handler.ParseCommands(param))
            handler.SendSysMessage("Unknown command.");
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

        // One-click dungeon reset (RebornWOW DCRST1A): acts on the sending player
        // and its group directly, never dispatched to a tank bot. Progress and
        // results arrive as system messages; a refusal also goes to the panel.
        if (subCmd == "instreset")
        {
            std::string whyNot;
            if (!DcInstanceReset::Request(player, &whyNot))
            {
                ChatHandler(player->GetSession()).SendSysMessage(("|cff33ccff[副本重置]|r " + whyNot).c_str());
                SendAddonError(player, whyNot);
            }
            return;
        }

        // Continuous clear (RebornWOW DCQ1A): a queue of dungeons run one after
        // another for the sending player's party. Handled in-process.
        if (subCmd == "queue")
        {
            DcDungeonQueue::HandleAddon(player, param);
            return;
        }

        // RebornWOW DCGM1G: the GM party menu (kill / raise / tier) comes over the addon
        // channel, which still works while the player is dead -- the client refuses to
        // send chat (and so a typed .dc party) from a corpse. Same command, same rules:
        // ParseCommands applies the command table's GM-only security level.
        if (subCmd == "gmparty")
        {
            std::string const line = ".dc party " + param;
            ChatHandler(player->GetSession()).ParseCommands(line);
            return;
        }

        // RebornWOW DCGM1F: the cheat tier for the panel's tag -- the test run the
        // player is watching (same map as its tank), else the party it is in.
        if (subCmd == "tier")
        {
            std::string tier;
            std::string source = "test";
            if (!DcTestRunManager::Instance().ViewerRunTier(player, &tier))
            {
                tier = DcPartyTier::TierFor(player);
                source = "party";
            }
            // RebornWOW DCTEST10B: 4th field = the test run whose party the player is in
            std::string testRun;
            if (!DcTestRunManager::Instance().TestPartyOf(player, &testRun))
                testRun = "-";
            SendAddonPayload(player, "DC\tTIER\t" + tier + "\t" + source + "\t" + testRun);
            return;
        }

        // RebornWOW DCUI3B: the five-column panel -- every dungeon (with dungeon-clear
        // support) and the invite roster by category. Any player, read-only.
        if (subCmd == "dungeons" || subCmd == "roster" || subCmd == "fill" ||  // fill: RebornWOW DCUI3C3
            subCmd == "partyroles")                                               // RebornWOW DCUI3C5
        {
            auto send = [player](std::string const& payload) { SendAddonPayload(player, payload); };
            if (subCmd == "dungeons")
                DcPanelData::SendDungeons(player, send);
            else if (subCmd == "partyroles")
                DcPanelData::SendPartyRoles(player, send);
            else if (subCmd == "fill")
                DcPanelData::SendFill(player, param, send);
            else
                DcPanelData::SendRoster(player, param, send);
            return;
        }

        // RebornWOW DCRUN1A: the player's own run records (the panel's column 2).
        if (subCmd == "myruns" || subCmd == "myrun" || subCmd == "myrundel")
        {
            auto send = [player](std::string const& payload) { SendAddonPayload(player, payload); };
            if (subCmd == "myruns")
                DcPlayerRuns::SendList(player, send);
            else if (subCmd == "myrun")
                DcPlayerRuns::SendDetail(player, param, send);
            else
                DcPlayerRuns::Delete(player, param);
            return;
        }

        // RebornWOW MBR1A: facts for the MultiBot units list (any player, read-only).
        if (subCmd == "botinfo")
        {
            SendBotInfo(player, param);
            return;
        }

        // RebornWOW DCNPC2A: the panel puts the sender's own NPCBots into the sender's group.
        if (subCmd == "npcjoin")
        {
            HandleNpcJoin(player, param);
            return;
        }

        // RebornWOW DCRZ2B: the player's answer to a corpse-run announcement.
        if (subCmd == "rezchoice")
        {
            DcRezRecovery::HandleCorpseRunChoice(player, param);
            return;
        }

        // RebornWOW DCPREP1A: the readiness panel
        if (subCmd == "prep")
        {
            SendPrep(player, param);
            return;
        }

        // RebornWOW DCGM3A: a panel GM command from a player who is dead (chat is refused to the dead)
        if (subCmd == "gmcmd")
        {
            HandleGmCommand(player, param);
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
