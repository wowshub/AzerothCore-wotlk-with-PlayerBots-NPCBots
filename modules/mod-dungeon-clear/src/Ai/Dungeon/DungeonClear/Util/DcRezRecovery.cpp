/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license, you may redistribute it
 * and/or modify it under version 3 of the License, or (at your option), any later version.
 */

#include "DcRezRecovery.h"
#include "DcNpcPartySnapshot.h"

#include "Ai/Dungeon/DungeonClear/Data/DcNeverTargetRegistry.h"
#include "Ai/Dungeon/DungeonClear/Data/Events/DungeonEventTables.h"
#include "Ai/Dungeon/DungeonClear/DcPullContext.h"
#include "Ai/Dungeon/DungeonClear/DcValueKeys.h"
#include "Ai/Dungeon/DungeonClear/Settings/DcSettings.h"
#include "Ai/Dungeon/DungeonClear/Util/DcCombatFlag.h"
#include "Ai/Dungeon/DungeonClear/Util/DcLeaderSignal.h"
#include "Ai/Dungeon/DungeonClear/Util/DcRun.h"
#include "Ai/Dungeon/DungeonClear/Util/DcRunWing.h"
#include "Ai/Dungeon/DungeonClear/Util/DcStatusPublisher.h"
#include "Ai/Dungeon/DungeonClear/Util/DcTargeting.h"
#include "Ai/Dungeon/DungeonClear/DcApproachState.h"
#include "Ai/Dungeon/DungeonClear/Util/ChunkedPathfinder.h"
#include "TestRun/DcTestDungeonRegistry.h"
#include "Ai/Dungeon/DungeonClear/Util/DungeonClearTuning.h"
#include "Ai/Dungeon/DungeonClear/Action/DcActionShared.h"
#include "TestRun/DcTestRunManager.h"
#include "ObjectAccessor.h"
#include <map>
#include <mutex>

#include <algorithm>
#include <string>
#include <vector>

#include "CellImpl.h"
#include "Creature.h"
#include "Corpse.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "Group.h"
#include "InstanceScript.h"
#include "Log.h"
#include "Map.h"
#include "Player.h"
#include "PlayerbotAI.h"
#include "Playerbots.h"
#include "SpellMgr.h"
#include "botmgr.h"
#include "../../../../../../mod-reborn-witchdoctor/src/RebornWitchDoctorNpcActor1.h"
#include "Timer.h"

namespace
{
    using DcRezDecision::Member;

    // First rank of each class's out-of-combat resurrection (Resurrection, Redemption,
    // Ancestral Spirit, Revive). 0 = the class has none.
    uint32 RezSpellFirstRank(uint8 cls)
    {
        switch (cls)
        {
            case CLASS_PRIEST:  return 2006;
            case CLASS_PALADIN: return 7328;
            case CLASS_SHAMAN:  return 2008;
            case CLASS_DRUID:   return 50769;
            default:            return 0;
        }
    }

    // RebornWOW DCRZ1A: the class alone is not enough -- a bot levelled without visiting a
    // trainer (Halls of Stone, paladin "Dvd") was picked as the rezzer and refused forever with
    // "no spell id for name", freezing the run on "coming to resurrect". Require any rank of the
    // class rez (walking the whole chain, custom high ranks included).
    bool IsRezClass(Player* p)
    {
        if(p->getClass()==CLASS_WITCH_DOCTOR)
        {
            // Its independent class AI already handles Reclaim Soul; never elect it
            // for the stock priest/paladin/shaman/druid named-spell cast action.
            if(GET_PLAYERBOT_AI(p))return false;
            for(auto rank:WD19A::ReclaimRanks)if(p->HasSpell(rank.spell))return true;
            return false;
        }
        for (uint32 id = RezSpellFirstRank(p->getClass()); id; id = sSpellMgr->GetNextSpellInChain(id))
            if (p->HasSpell(id))
                return true;
        return false;
    }

    Unit* ExternalRezzer(Player* bot)
    {
        if(!bot||!bot->IsInWorld())return nullptr;
        std::vector<Player*> players{bot};
        if(Group* g=bot->GetGroup())for(GroupReference* ref=g->GetFirstMember();ref;ref=ref->next())
            if(Player* p=ref->GetSource())if(p!=bot)players.push_back(p);
        for(Player* p:players)
        {
            if(!p->IsInWorld()||!bot->IsInMap(p)||!bot->InSamePhase(p))continue;
            if(p->IsAlive()&&p->getClass()==CLASS_WITCH_DOCTOR&&GET_PLAYERBOT_AI(p))
                for(auto rank:WD19A::ReclaimRanks)if(p->HasSpell(rank.spell))return p;
        }
        for (Creature* candidate : DcNpcPartySnapshot::Collect(bot))
        {
            auto* c=WDN1::Actor(candidate);if(!c)continue;
            auto* ai=c->GetBotAI();auto const& spells=ai->GetSpellMap();auto it=spells.find(9003260);
            if(it==spells.end()||!it->second||!WDN1::Known(c,it->second->spellId)||
               ai->HasBotCommandState(BOT_COMMAND_FULLSTOP|BOT_COMMAND_INACTION|BOT_COMMAND_NO_CAST))continue;
            for(Player* dead:players)if(dead->isDead())
            {
                WorldObject* body=dead->HasFlag(PLAYER_FLAGS,PLAYER_FLAGS_GHOST)?static_cast<WorldObject*>(dead->GetCorpse()):dead;
                if(body&&body->IsInWorld()&&c->IsInMap(body)&&c->InSamePhase(body)&&c->GetDistance(body)<=60.f)return c;
            }
        }
        return nullptr;
    }

    // The member whose DcRunState owns this run — DEAD OR ALIVE. This used to be a
    // copy of the walk; it now shares one body with the terminal rungs, which need
    // exactly the same dead-tolerance for exactly the same reason. See
    // DcLeaderSignal::FindRunOwner and the header comment.
    Player* ResolveRunOwner(Player* bot) { return DcLeaderSignal::FindRunOwner(bot); }

    // Is a live hostile nobody is fighting standing beside this body? Then a rezzer
    // walking to it walks into an unpulled pack — see DcRezDecision's
    // UnsafeStandDown branch. Idle only: a mob still fighting the party is the
    // engagement gate's business, and counting it would stand the recovery down
    // (and spend the episode's one announcement) in the middle of a fight that is
    // about to leave the body safe.
    bool CorpseAmongIdleHostiles(Player* corpse)
    {
        if (!corpse || !corpse->IsInWorld())
            return false;
        std::list<Unit*> nearby;
        Acore::AnyUnfriendlyUnitInObjectRangeCheck check(corpse, corpse,
                                                         DC_REZ_CORPSE_HOSTILE_RADIUS);
        Acore::UnitListSearcher<Acore::AnyUnfriendlyUnitInObjectRangeCheck> searcher(
            corpse, nearby, check);
        Cell::VisitObjects(corpse, searcher, DC_REZ_CORPSE_HOSTILE_RADIUS);
        for (Unit* u : nearby)
        {
            Creature* c = u ? u->ToCreature() : nullptr;
            if (!c || !c->IsAlive() || c->IsInCombat() || c->IsTotem() || c->IsCivilian() ||
                c->IsCritter() || c->IsTrigger() || c->HasReactState(REACT_PASSIVE) ||
                c->HasUnitFlag(UNIT_FLAG_NON_ATTACKABLE | UNIT_FLAG_NOT_SELECTABLE))
                continue;
            if (!c->IsHostileTo(corpse))
                continue;
            if (DcNeverTargetRegistry::IsNeverTarget(corpse->GetMapId(), c->GetEntry()))
                continue;
            return true;
        }
        return false;
    }

    // Same-map group snapshot, KEEPING dead members (unlike the Smart Rest
    // snapshot — the corpses are the whole point here). `players` receives the
    // matching Player* per row so verdict indices resolve to live identities.
    void BuildSnapshot(Player* bot, Player* owner, std::vector<Member>& out,
                       std::vector<Player*>& players)
    {
        auto add = [&](Player* member)
        {
            Member m;
            m.isDead = member->isDead();
            m.canRezClass = IsRezClass(member);
            m.isHealerRole = PlayerbotAI::IsHeal(member);
            m.isTankRole = PlayerbotAI::IsTank(member);
            m.isBot = GET_PLAYERBOT_AI(member) != nullptr;
            m.corpseUnsafe = m.isDead && CorpseAmongIdleHostiles(member);
            out.push_back(m);
            players.push_back(member);
        };

        Group* group = bot->GetGroup();
        if (!group)
        {
            add(owner ? owner : bot);
            return;
        }
        for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
        {
            Player* member = ref->GetSource();
            if (!member || member->GetMapId() != bot->GetMapId())
                continue;
            add(member);
        }
    }

    // Instantaneous "is the party fighting" read for the clock freeze. The
    // latched variant (IsPartyEngagedLatched) is file-local to DcLeaderSignal;
    // a bare read is safe HERE because a false flicker merely clears and
    // re-stamps the clock — which RESETS the timeout budget, the forgiving
    // direction — it can never expire recovery early.
    //
    // ENGAGEMENT, not the combat flag: a resurrection cast is refused while
    // flagged ("rez party: cast 'resurrection' -> not possible yet"), so under a
    // phantom flag — a 45yd hostile area aura with nothing aggroed — the recovery
    // can never complete AND the flag froze this very clock, so the timeout that
    // is supposed to bound it never arrived. The run then held over the corpse
    // forever, inside the aura (Arcatraz heroic, tr-20260801-194932-20: hand-
    // rezzed by the player to unstick it). A real fight still freezes the clock.
    bool AnyMemberEngaged(std::vector<Player*> const& players)
    {
        for (Player* p : players)
            if (DcCombatFlag::IsEngaged(p))
                return true;
        if (!players.empty())
            for (Creature* c : DcNpcPartySnapshot::Collect(players.front()))
                if (DcNpcPartySnapshot::Engaged(c)) return true;
        return false;
    }

    // "Would the resurrect spell even be allowed here?" — a mirror of the exploit
    // guard in Spell::CheckCast (Spell.cpp, "Xinef: exploit protection"), which
    // refuses SPELL_EFFECT_RESURRECT outright — SPELL_FAILED_TARGET_CANNOT_BE_
    // RESURRECTED, in or out of combat — for any player casting inside a dungeon
    // whose InstanceScript reports an encounter in progress.
    //
    // Read from the CASTER's side because that is what the core reads: the guard
    // keys off m_caster's map and instance script, not the corpse's.
    bool RezBlockedByInstance(Player* p)
    {
        if (!p)
            return false;
        Map* map = p->GetMap();
        if (!map || !map->IsDungeon())
            return false;
        InstanceScript* const instance = DcTargeting::GetInstanceScript(p);
        return instance && instance->IsEncounterInProgress();
    }

    // Same read, from a bare group walk instead of a built snapshot — for
    // IsElectedRezzer, which answers a stand-down question and has no reason to
    // pay for the snapshot EvaluateImpl builds.
    bool AnySameMapMemberEngaged(Player* bot)
    {
        Group* group = bot->GetGroup();
        if (!group)
            return DcCombatFlag::IsEngaged(bot);
        for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
        {
            Player* member = ref->GetSource();
            if (!member || member->GetMapId() != bot->GetMapId())
                continue;
            if (DcCombatFlag::IsEngaged(member))
                return true;
        }
        return false;
    }

    // "Is there a corpse at all?" — EvaluateImpl's very first question, answered
    // from the group list instead of from the two vectors BuildSnapshot allocates
    // to ask it. IsElectedRezzer runs on every rez-class follower on every tick
    // (it gates the follower movers' stand-down), and outside a recovery the whole
    // snapshot was built only to conclude "nobody is dead".
    //
    // Ungrouped bots return true so they still fall through to EvaluateImpl, whose
    // no-group snapshot is over the resolved run OWNER, not over `bot`.
    bool AnySameMapMemberDead(Player* bot)
    {
        Group* group = bot->GetGroup();
        if (!group)
            return true;
        for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
        {
            Player* member = ref->GetSource();
            if (!member || member->GetMapId() != bot->GetMapId())
                continue;
            if (member->isDead())
                return true;
        }
        return false;
    }

    // ---- RebornWOW DCENC1A: a boss fight nobody is having ----------------------
    // The core refuses every out-of-combat resurrect while the instance reports an
    // encounter IN_PROGRESS and a party member still has an in-combat victim
    // (Spell::CheckCast, "Xinef: exploit protection"). A boss that keeps its combat
    // with nobody able to reach it -- the tank knocked into a wall (Bjarngrim's Knock
    // Away), a boss stranded off its platform -- therefore blocks every rez for good
    // and the run limps on short-handed. When the block has lasted kStuckRezBlockMs,
    // an in-combat dungeon boss whose health has not moved for kStuckBossHpMs and
    // which is not hitting anyone in melee range is made to evade: its script resets
    // the encounter, the block lifts, and the normal rez path raises the dead.
    constexpr uint32 kStuckRezBlockMs = 45000;
    constexpr uint32 kStuckBossHpMs = 20000;
    constexpr uint32 kStuckCooldownMs = 60000;

    std::mutex g_stuckMutex;  // bots of different maps update on different threads
    std::map<ObjectGuid, std::pair<uint32, uint32>> g_bossHp;  // boss -> (hp, unchanged since)
    std::map<uint32, uint32> g_stuckFiredAt;                    // instance id -> last evade

    // True when it made at least one boss evade; *names lists them.
    bool UnstickEncounter(Player* bot, uint32 now, std::string* names)
    {
        Map* map = bot->GetMap();
        if (!map || !map->IsDungeon())
            return false;
        uint32 const instanceId = map->GetInstanceId();
        std::vector<Creature*> stuck;
        {
            std::lock_guard<std::mutex> lock(g_stuckMutex);
            auto fired = g_stuckFiredAt.find(instanceId);
            if (fired != g_stuckFiredAt.end() && getMSTimeDiff(fired->second, now) < kStuckCooldownMs)
                return false;
            for (auto const& kv : map->GetCreatureBySpawnIdStore())
            {
                Creature* boss = kv.second;
                if (!boss || !boss->IsAlive() || !boss->IsInCombat() || !boss->IsDungeonBoss())
                    continue;
                uint32 const hp = boss->GetHealth();
                auto it = g_bossHp.find(boss->GetGUID());
                if (it == g_bossHp.end() || it->second.first != hp)
                {
                    g_bossHp[boss->GetGUID()] = { hp, now };
                    continue;  // still losing health (or first look): a real fight
                }
                if (getMSTimeDiff(it->second.second, now) < kStuckBossHpMs)
                    continue;
                Unit* victim = boss->GetVictim();
                if (victim && victim->IsAlive() && boss->IsWithinMeleeRange(victim))
                    continue;  // it is beating on somebody: that is a fight, not a hang
                stuck.push_back(boss);
            }
            if (stuck.empty())
                return false;
            g_stuckFiredAt[instanceId] = now;
            for (Creature* boss : stuck)
                g_bossHp.erase(boss->GetGUID());
        }
        for (Creature* boss : stuck)
        {
            if (boss->IsAIEnabled && boss->AI())
                boss->AI()->EnterEvadeMode();
            else
                boss->CombatStop(true);
            *names += (names->empty() ? "" : ", ") + boss->GetName();
        }
        return true;
    }

    DcRezRecovery::Plan EvaluateImpl(Player* bot, bool mutate)
    {
        DcRezRecovery::Plan plan;
        if (!bot)
            return plan;

        Player* owner = ResolveRunOwner(bot);
        PlayerbotAI* ownerAI = owner ? GET_PLAYERBOT_AI(owner) : nullptr;
        if (!ownerAI)
            return plan;
        DcRunState& run = DcRun::Of(ownerAI);
        if (!run.enabled || run.paused)
            return plan;  // a pause holds recovery too; clocks stay as-is

        std::vector<Member> members;
        std::vector<Player*> players;
        BuildSnapshot(bot, owner, members, players);

        uint32 const now = getMSTime();

        bool anyDead = false;
        for (Member const& m : members)
            anyDead = anyDead || m.isDead;

        if (!anyDead)
        {
            if (mutate && (run.rezPendingSinceMs || run.rezAnnounceMs))
            {
                // A recovery episode just completed — everyone is back up. The
                // rezzed member's low HP/mana now holds the tank via the
                // default between-pulls readiness floors until they recover.
                if (run.rezAnnounceMs)
                    if (PlayerbotAI* botAI = GET_PLAYERBOT_AI(bot))
                        DcStatusPublisher::SendAddonMessage(
                            botAI, "CHAT\tParty restored \xe2\x80\x94 resuming.");
                run.rezPendingSinceMs = 0;
                run.rezAnnounceMs = 0;
            }
            return plan;  // None / NoDeaths
        }

        // First corpse by group order, for the disable messages.
        for (std::size_t i = 0; i < members.size(); ++i)
            if (members[i].isDead)
            {
                plan.deadName = players[i]->GetName();
                break;
            }

        if (!DcRezRecovery::Enabled(bot))
        {
            // Feature off: hand the party-died trigger its classic verdict.
            plan.verdict.outcome = DcRezDecision::Outcome::Disable;
            plan.verdict.reason = DcRezDecision::Reason::Disabled;
            return plan;
        }

        // THE PULLER DIED — retire the pull it was running.
        //
        // Nothing else can. The whole pull FSM is leader-driven and the leader is
        // the corpse: DungeonClearPullTrigger and the maneuver both stand down on a
        // dead bot, and MaintainScoutCamp (which owns the orphan release) is only
        // reached through the leader election, which excludes the dead. So the
        // phase, the camp and any latched scripted stage simply persist — in the
        // MgT heroic audit the teardown snapshots show phase 3/4 held for 606-708k
        // ms, and tr-20260805-191834-3 ended at phase=4 with camp=True and all five
        // members corpses.
        //
        // That residue is not inert. A latched stage pins the pull target, forces
        // the pull mode on and stands the advance rung down; the camp keeps the
        // followers' hold-at-camp reading a camp nobody is dragging to. Both come
        // back with the tank when it is rezzed, pointed at a fight that is over.
        //
        // Clearing it here rather than in the pull code because this is the one rung
        // that runs on EVERY bot, dead leader included, and already resolves the
        // owner. Idempotent and self-limiting: the guard goes false after the first
        // pass and cannot re-fire until a live pull is re-formed.
        if (mutate && owner->isDead())
        {
            DcPullContext& pull =
                ownerAI->GetAiObjectContext()->GetValue<DcPullContext&>(DcKey::PullContext)->Get();
            if (pull.phase != DcPullPhase::Idle || pull.HasCamp() || pull.scriptedStage >= 0)
            {
                LOG_INFO("playerbots.dungeonclear",
                         "[DC:{}] the puller died mid-pull (phase {}, stage {}, camp {}) "
                         "-> pull FSM reset; the party stops holding a camp nobody is "
                         "dragging to", owner->GetName(), static_cast<uint32>(pull.phase),
                         pull.scriptedStage, pull.HasCamp() ? "set" : "none");
                pull.Reset();
            }
        }

        // Is the instance refusing the spell right now, and since when? The clock
        // clears the instant the block lifts, so the wait the kernel measures is
        // always the CURRENT block — a boss that resets and re-engages does not
        // inherit the seconds its last attempt burned.
        bool const rezBlocked = RezBlockedByInstance(bot);
        if (mutate)
        {
            if (!rezBlocked)
                run.rezBlockedSinceMs = 0;
            else if (run.rezBlockedSinceMs == 0)
                run.rezBlockedSinceMs = now ? now : 1;
        }

        // The recovery clock: runs only while nobody is FIGHTING (a fight clears
        // it, so a mid-recovery add pull resets the budget instead of burning it).
        // A block clears it for the same reason and then some: time spent unable to
        // cast must not be charged to a recovery that has not been allowed to start,
        // or the timeout fires the moment the block lifts.
        // A live chess game holds every body at the board (the rezzer included),
        // so it stops the clock too: the tank that died at the board is raised
        // once the game is over, not timed out in the middle of it.
        // Every corpse among idle hostiles stands the recovery down (see the
        // kernel), and like a block it must not spend the budget meanwhile — or the
        // corpse that comes back into play once the party clears beside it would
        // time the run out on the spot.
        bool allCorpsesUnsafe = true;
        for (Member const& m : members)
            if (m.isDead && !m.corpseUnsafe)
                allCorpsesUnsafe = false;
        bool const partyEngaged = AnyMemberEngaged(players);
        // RebornWOW DCENC1A: the rez has been refused for a long time -- check for a
        // boss fight nobody is having and release it (see UnstickEncounter). Only the
        // run owner's tick does it (dead owners tick too); a per-instance cooldown
        // stops a second try while the first evade is still walking home.
        if (mutate && rezBlocked && run.rezBlockedSinceMs && bot == owner &&
            getMSTimeDiff(run.rezBlockedSinceMs, now) >= kStuckRezBlockMs)
        {
            std::string names;
            if (UnstickEncounter(bot, now, &names))
            {
                LOG_INFO("playerbots.dungeonclear",
                         "[DC:{}] DCENC1A stuck encounter: rez blocked {}s, {} out of reach with no "
                         "health lost -> evade (encounter resets, resurrects allowed again)",
                         owner->GetName(), getMSTimeDiff(run.rezBlockedSinceMs, now) / 1000, names);
                if (ownerAI)
                    DcStatusPublisher::SendAddonMessage(ownerAI, "CHAT\t" + names +
                        " \xe5\x8d\xa1\xe4\xbd\x8f\xe4\xba\x86\xef\xbc\x88\xe6\xb2\xa1\xe4\xba\xba\xe6\x89\x93"
                        "\xe5\xbe\x97\xe5\x88\xb0\xef\xbc\x89\xef\xbc\x8c\xe5\xb7\xb2\xe8\xae\xa9\xe5\xae\x83"
                        "\xe8\x84\xb1\xe6\x88\x98\xe9\x87\x8d\xe7\xbd\xae\xef\xbc\x8c\xe7\x8e\xb0\xe5\x9c\xa8"
                        "\xe5\x8f\xaf\xe4\xbb\xa5\xe5\xa4\x8d\xe6\xb4\xbb\xe4\xba\x86\xe3\x80\x82");
                run.rezBlockedSinceMs = 0;
            }
        }
        if (mutate)
        {
            if (partyEngaged || rezBlocked || allCorpsesUnsafe || DcKarazhan::ChessIsOn(bot))
                run.rezPendingSinceMs = 0;
            else if (run.rezPendingSinceMs == 0)
                run.rezPendingSinceMs = now ? now : 1;
        }

        // The NoRezzer floor's other input: is any LIVING survivor still carrying
        // the core combat flag? Deliberately the raw flag rather than engagement —
        // the shape it exists to catch is a boss that has stopped fighting and not
        // yet released the party (Kael'thas' 11s defeat sequence), where every
        // survivor is flagged and nothing is swinging.
        bool anySurvivorCombatFlagged = false;
        for (Player* p : players)
            if (p && p->IsAlive() && p->IsInCombat())
            {
                anySurvivorCombatFlagged = true;
                break;
            }

        DcRezDecision::Inputs in;
        in.enabled = true;
        in.nowMs = now;
        in.pendingSinceMs = run.rezPendingSinceMs;
        in.timeoutMs = DcSettings::GetUInt(bot, "PostCombatRezTimeoutSecs") * 1000;
        // Raid wipe semantics: fraction verdict + entrance regroup (the run
        // continues; DungeonClearDisableOnDeathAction routes Regroup to
        // RegroupAtEntrance instead of the disable funnel).
        if (bot->GetMap() && bot->GetMap()->IsRaid())
        {
            in.wipeFractionPct = DcSettings::GetUInt(bot, "RaidWipeFractionPct");
            in.regroupOnWipe = true;
        }
        // Five-man maps that regroup on a FULL wipe like a raid does. The Oculus: an
        // Eregos wipe is the most likely failure in the dungeon, it happens in the
        // air where no body can be reached, and dead bosses stay dead — ending the
        // run on the first one would make a battery measure nothing but that.
        else if (bot->GetMapId() == DcOculus::MAP_ID)
            in.regroupOnWipe = true;
        // Raid corpse piles get more clock: even in parallel, waves of raises
        // (each adding rezzers back) and the drinking between them take real
        // time. Scale by the corpses beyond the first, capped at twice the
        // configured budget (which itself resolves through the .Raid layer).
        if (bot->GetMap() && bot->GetMap()->IsRaid())
        {
            uint32 deadCount = 0;
            for (Member const& m : members)
                if (m.isDead)
                    ++deadCount;
            uint32 const scaled =
                in.timeoutMs + (deadCount > 1 ? (deadCount - 1) * DC_REZ_RAID_PER_CORPSE_MS
                                              : 0);
            in.timeoutMs = std::min(scaled, in.timeoutMs * 2);
        }
        in.partyEngaged = partyEngaged;
        in.anySurvivorCombatFlagged = anySurvivorCombatFlagged;
        in.noRezzerSinceMs = run.noRezzerSinceMs;
        in.noRezzerQuietSinceMs = run.noRezzerQuietSinceMs;
        in.noRezzerQuietGraceMs = DC_NO_REZZER_QUIET_GRACE_MS;
        in.noRezzerHoldMaxMs = DC_NO_REZZER_HOLD_MAX_MS;
        in.rezBlocked = rezBlocked;
        in.blockedSinceMs = run.rezBlockedSinceMs;
        in.blockedHoldMaxMs = DC_REZ_BLOCKED_HOLD_MAX_MS;

        Unit* external=ExternalRezzer(bot);in.externalRezzer=external!=nullptr;
        plan.verdict = DcRezDecision::Decide(in, members);
        if(plan.verdict.reason==DcRezDecision::Reason::WaitingOnExternal&&external)
            plan.rezzerName=external->GetName();

        // Advance the floor's clocks from the verdict we just got. They can only be
        // stamped after the fact — whether a rezzer is left is precisely what the
        // kernel decides — so both run a tick behind, which is immaterial against
        // graces measured in seconds. A verdict that is not the no-rezzer branch
        // clears them, so a rezzer coming back up (or a fresh episode) starts clean.
        if (mutate)
        {
            bool const noRezzer = plan.verdict.reason == DcRezDecision::Reason::NoRezzer ||
                                  plan.verdict.reason == DcRezDecision::Reason::NoRezzerInFight;
            if (!noRezzer)
            {
                run.noRezzerSinceMs = 0;
                run.noRezzerQuietSinceMs = 0;
            }
            else
            {
                if (run.noRezzerSinceMs == 0)
                    run.noRezzerSinceMs = now ? now : 1;
                if (partyEngaged || anySurvivorCombatFlagged)
                    run.noRezzerQuietSinceMs = 0;
                else if (run.noRezzerQuietSinceMs == 0)
                    run.noRezzerQuietSinceMs = now ? now : 1;
            }
        }

        if (plan.verdict.rezzerIdx >= 0 &&
            plan.verdict.rezzerIdx < static_cast<int>(players.size()))
        {
            plan.rezzer = players[plan.verdict.rezzerIdx]->GetGUID();
            plan.rezzerName = players[plan.verdict.rezzerIdx]->GetName();
        }
        if (plan.verdict.targetIdx >= 0 &&
            plan.verdict.targetIdx < static_cast<int>(players.size()))
        {
            plan.target = players[plan.verdict.targetIdx]->GetGUID();
            plan.targetName = players[plan.verdict.targetIdx]->GetName();
        }
        for (auto const& [ri, ti] : plan.verdict.pairs)
            if (ri >= 0 && ti >= 0 && ri < static_cast<int>(players.size()) &&
                ti < static_cast<int>(players.size()))
                plan.pairs.emplace_back(players[ri]->GetGUID(), players[ti]->GetGUID());

        // One announcement per recovery episode, from whichever member
        // evaluates first (the stamp on the shared run state dedupes the rest).
        //
        // BlockedWaiting is deliberately NOT announced: it is a 20s probe of whether
        // the instance is going to let go, and announcing it would spend the episode's
        // one line on a state the party is about to leave — either into a real
        // recovery (which then has nothing left to say) or into the stand-down, which
        // is the line actually worth reading. The stand-down is not a Hold, so it is
        // named explicitly here.
        bool const blockedStandDown =
            plan.verdict.reason == DcRezDecision::Reason::BlockedStandDown;
        bool const unsafeStandDown =
            plan.verdict.reason == DcRezDecision::Reason::UnsafeStandDown;
        bool const announceable =
            blockedStandDown || unsafeStandDown ||
            (plan.verdict.outcome == DcRezDecision::Outcome::Hold &&
                                 plan.verdict.reason != DcRezDecision::Reason::BlockedWaiting);
        if (mutate && announceable && run.rezAnnounceMs == 0)
        {
            run.rezAnnounceMs = now ? now : 1;
            std::string line;
            if (blockedStandDown)
                // The one case where the run neither holds nor ends: nothing can raise
                // them here, so the survivors keep clearing and the corpse comes back
                // up when the encounter releases (or at the end of the run).
                line = plan.targetName + " died and the encounter won't allow a "
                       "resurrection \xe2\x80\x94 carrying on without them.";
            else if (unsafeStandDown)
                line = plan.targetName + " died among enemies we haven't pulled \xe2\x80\x94 "
                       "carrying on without them rather than walk into the pack.";
            else if (plan.verdict.reason == DcRezDecision::Reason::WaitingOnExternal)
                line = plan.targetName + " died -- waiting for " + plan.rezzerName + " to resurrect them (" + std::to_string(in.timeoutMs/1000) + "s).";
            else if (plan.verdict.reason == DcRezDecision::Reason::WaitingOnHuman)
                line = plan.targetName + " died \xe2\x80\x94 waiting for you to resurrect them (" +
                       std::to_string(in.timeoutMs / 1000) + "s).";
            else if (plan.verdict.reason == DcRezDecision::Reason::NoRezzerInFight)
                // No rezzer elected — there is none left. The hold is only until the
                // fight ends, at which point the verdict becomes the classic disable.
                line = plan.targetName + " died and no one left can resurrect \xe2\x80\x94 "
                       "finishing this fight first.";
            else
                line = plan.targetName + " died \xe2\x80\x94 " + plan.rezzerName +
                       " is coming to resurrect them.";
            if (PlayerbotAI* botAI = GET_PLAYERBOT_AI(bot))
                DcStatusPublisher::SendAddonMessage(botAI, "CHAT\t" + line);
            LOG_INFO("playerbots.dungeonclear",
                     "[DC:{}] post-combat rez: {} \xe2\x80\x94 {}", owner->GetName(),
                     blockedStandDown ? "the instance refuses every resurrect, clearing "
                                        "short-handed"
                     : unsafeStandDown ? "every corpse lies among idle hostiles, clearing "
                                         "short-handed"
                                       : "holding the run", line);
        }

        return plan;
    }
}

namespace DcRezRecovery
{
    bool Enabled(Player* bot)
    {
        return DcSettings::GetBool(bot, "PostCombatRez");
    }

    Plan Evaluate(Player* bot)
    {
        return EvaluateImpl(bot, /*mutate*/ true);
    }

    bool IsPending(Player* leaderTank)
    {
        if (!leaderTank || !Enabled(leaderTank))
            return false;
        PlayerbotAI* ai = GET_PLAYERBOT_AI(leaderTank);
        if (!ai)
            return false;
        DcRunState const& run = DcRun::Of(ai);
        if (!run.enabled || run.paused)
            return false;

        // THE ONE CLOCK READ THIS PREDICATE MAKES, and it is here to stop a hold that
        // can never end. When the instance refuses every resurrect (see
        // RezBlockedByInstance) a corpse is not a recovery in progress, it is just a
        // corpse — and holding the run on it parks the party over a body while the
        // encounter that forbade the spell carries on around them. Match the kernel:
        // hold while the block might still lift, then stop gating on it entirely.
        //
        // An unstamped clock reads as "the block just started", so the ordering
        // caveat above still cuts the safe way: at worst this holds one tick longer
        // than the verdict does, never one tick less.
        if (RezBlockedByInstance(leaderTank) && run.rezBlockedSinceMs != 0 &&
            getMSTime() - run.rezBlockedSinceMs >= DC_REZ_BLOCKED_HOLD_MAX_MS)
            return false;

        if (leaderTank->isDead())
            return true;
        Group* group = leaderTank->GetGroup();
        if (!group)
            return false;
        // A corpse among idle hostiles is not a recovery in progress either — the
        // kernel stands down on it (UnsafeStandDown), so holding the run over it
        // would park the party with nobody walking. Same scan as the snapshot.
        for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
        {
            Player* member = ref->GetSource();
            if (!member || member->GetMapId() != leaderTank->GetMapId())
                continue;
            if (member->isDead() && !CorpseAmongIdleHostiles(member))
                return true;
        }
        return false;
    }

    bool CanRecover(Player* bot)
    {
        if (!bot || !Enabled(bot))
            return false;
        // Nothing can rez here, so "is a rez class alive" is not the question — the
        // run is allowed to resume and will clear short-handed. Refusing `dc on`
        // over an unraisable corpse would leave the party standing in a Violet Hold
        // that is still counting down.
        if (RezBlockedByInstance(bot))
            return true;
        if(ExternalRezzer(bot))return true;
        Group* group = bot->GetGroup();
        if (!group)
            return bot->IsAlive() && IsRezClass(bot);
        for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
        {
            Player* member = ref->GetSource();
            if (!member || member->GetMapId() != bot->GetMapId())
                continue;
            if (member->IsAlive() && IsRezClass(member))
                return true;
        }
        return false;
    }

    bool IsElectedRezzer(Player* bot)
    {
        // Cheapest read first — this runs on every follower rung, every tick,
        // and only a living rez class is ever elected. Non-rez classes (and
        // every bot mid-fight) never reach the group walk in EvaluateImpl.
        if (!bot || bot->isDead() || bot->IsInCombat() || !IsRezClass(bot))
            return false;
        Map* map = bot->GetMap();
        if (!map || !map->IsDungeon())
            return false;

        // DELIBERATELY NARROWER THAN THE TRIGGER: the trigger only asks whether THIS
        // bot is flagged, but this predicate hands the bot's movement to the rez rung
        // by taking it away from every other mover. Doing that while the party is
        // still swinging would let an unflagged healer walk out of a live fight to
        // start a corpse run. Recovery loses nothing by waiting — the glue clears the
        // pending clock for exactly as long as anyone is engaged, so the budget this
        // defers is not being spent.
        if (AnySameMapMemberEngaged(bot))
            return false;

        // NO CORPSE -> no recovery to be elected for. EvaluateImpl reaches the same
        // answer (its no-deaths plan is Outcome::None, which fails the Hold test
        // below) after allocating and filling the snapshot; ask it the cheap way.
        if (!AnySameMapMemberDead(bot))
            return false;

        // mutate=false: see the header. The trigger owns the clock; this is the
        // same verdict read without the side effects.
        Plan const plan = EvaluateImpl(bot, /*mutate*/ false);
        if (plan.verdict.outcome != DcRezDecision::Outcome::Hold ||
            plan.verdict.reason != DcRezDecision::Reason::Recovering ||
            PairedTargetFor(plan, bot).IsEmpty())
            return false;

        // ...AND NOTHING ALIVE IS STILL ON THE PARTY. The engagement test above is
        // `victim || attackers`, a snapshot of who is mid-swing this instant: it
        // goes false in the gap between a pack's swings, and this predicate then
        // hands the rezzer's movement to the corpse walk — out of the camp, across
        // the room, alone, into mobs that are still very much alive.
        //
        // Six of the 45 rez approaches in tp-20260808-162331-1 killed the rezzer
        // within 40s and four of those ended the run. tr-20260808-162337-8 is the
        // clean read: the tank died at 10:41 mid-pack, the healer was released the
        // same second, and was dead at 10:45 to a Sunblade Blood Knight — with the
        // healer the only rez class in the group, that was the run.
        //
        // Placed LAST on purpose. The scan costs a pathfind per combat reference,
        // and everything above already narrows this to the elected rezzer of a
        // pending recovery, which is rare. Radius-bounded so a hostile area aura
        // (45yd, nothing actually on us) cannot stall recovery forever.
        return !DcCombatFlag::AnyPartyHeldByLiveEnemy(bot, DC_FIGHT_HOLDER_RADIUS);
    }

    ObjectGuid PairedTargetFor(Plan const& plan, Player* bot)
    {
        if (!bot)
            return ObjectGuid::Empty;
        if (plan.verdict.outcome != DcRezDecision::Outcome::Hold ||
            plan.verdict.reason != DcRezDecision::Reason::Recovering)
            return ObjectGuid::Empty;
        if (plan.rezzer == bot->GetGUID())
            return plan.target;
        // Raid runs recover in PARALLEL: every paired rezzer works its own
        // corpse. Dungeons keep the single election — the second rez class
        // stays with the party (5 people, 1-2 corpses; a second walker is more
        // exposure for no time saved).
        if (bot->GetMap() && bot->GetMap()->IsRaid())
            for (auto const& pr : plan.pairs)
                if (pr.first == bot->GetGUID())
                    return pr.second;
        return ObjectGuid::Empty;
    }

    bool RegroupAtEntrance(Player* bot)
    {
        if (!bot)
            return false;
        Player* owner = ResolveRunOwner(bot);
        PlayerbotAI* ownerAI = owner ? GET_PLAYERBOT_AI(owner) : nullptr;
        if (!ownerAI)
            return false;
        Map* map = owner->FindMap();
        if (!map)
            return false;

        // The entrance teleport target comes from the dungeon catalogue (its
        // rows carry the world-DB areatrigger targets). No row -> the caller
        // falls back to the classic disable.
        //
        // On a split map the row is the RUN's wing's (row token == wing token):
        // a wiped UBRS party regroups at the UBRS entrance, a Scarlet Monastery
        // Library party at the Library's — not at whichever wing's row happens to
        // come first in the table. Any other map (or no wing resolved) takes the
        // first non-scenario row for the map, as before.
        std::string const wingToken = DcRunWing::ActiveWingToken(owner);
        DcTestDungeonRegistry::Row const* row = nullptr;
        for (DcTestDungeonRegistry::Row const& r : DcTestDungeonRegistry::All())
        {
            // A scenario's drop point is mid-instance, never the entrance.
            if (r.mapId != map->GetId() || DcTestDungeonRegistry::IsScenario(r))
                continue;
            if (!wingToken.empty() && wingToken == r.token)
            {
                row = &r;
                break;
            }
            if (!row)
                row = &r;
        }
        if (!row)
            return false;

        // THE OCULUS REGROUPS AT THE PORTAL LANDING, not the entrance. The entrance
        // floor is an island of its own: a party revived there would have to re-cross
        // the Nexus Portal, whose objective has already latched, and walk to Drakos's
        // ring for the givers anyway. The landing is where the portal's own spell puts
        // a player, beside the givers and the lift-off pad.
        float destX = row->x, destY = row->y, destZ = row->z, destO = row->o;
        if (map->GetId() == DcOculus::MAP_ID)
        {
            destX = DcOculus::PORTAL_LAND_X;
            destY = DcOculus::PORTAL_LAND_Y;
            destZ = DcOculus::PORTAL_LAND_Z;
        }

        LOG_INFO("playerbots.dungeonclear",
                 "[DC:{}] raid wipe -> reviving the raid at the {} entrance and "
                 "continuing the run", owner->GetName(), row->name);

        Group* group = owner->GetGroup();
        auto const regroupMember = [&](Player* member)
        {
            if (!member || !member->IsInWorld() || member->GetMapId() != map->GetId())
                return;
            PlayerbotAI* memberAI = GET_PLAYERBOT_AI(member);
            if (!memberAI)
                return;  // never revive/relocate a human — they release normally

            // End the lost fight from both sides before moving anyone: threat
            // and combat refs first, then the TARGET — CombatStop leaves
            // `current target` set, and a bot relocated with a stale target
            // walks the party straight back to the boss (the relocation-must-
            // drop-the-target lesson).
            member->GetThreatMgr().ClearAllThreat();
            member->CombatStop(true);
            member->AttackStop();
            member->SetTarget();
            memberAI->GetAiObjectContext()
                ->GetValue<Unit*>(DcKey::Stock::CurrentTarget)->Set(nullptr);

            if (!member->IsAlive() || member->HasPlayerFlag(PLAYER_FLAGS_GHOST))
            {
                // Same shape as the harness teardown revive: Spirit of
                // Redemption must come off first, no resurrection sickness, and
                // the corpse turns to bones so nothing resurrectable is left
                // behind at the boss.
                member->RemoveAurasDueToSpell(27827);
                member->ResurrectPlayer(1.0f, /*applySickness*/ false);
                member->SpawnCorpseBones();
            }
            member->TeleportTo(row->mapId, destX, destY, destZ, destO);
        };

        if (group)
        {
            for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
                regroupMember(ref->GetSource());
        }
        else
            regroupMember(owner);

        // Run-state hygiene on the owner: the fight is over and the raid is at
        // the entrance, so every cursor pointed at the boss room is stale. Same
        // cluster `dc on` clears, minus the run-level toggles — the run stays
        // ENABLED and re-enters the normal advance pipeline from the entrance.
        AiObjectContext* ctx = ownerAI->GetAiObjectContext();
        ctx->GetValue<DcPullContext&>(DcKey::PullContext)->Get().Reset();
        ctx->GetValue<DcApproachState&>(DcKey::ApproachState)->Get().Reset();
        ctx->GetValue<ChunkedPathfinder::Result&>(DcKey::LongPath)->Reset();
        ctx->GetValue<uint32>(DcKey::StickyBoss)->Set(0u);
        ctx->GetValue<std::string&>(DcKey::StallReason)->Get().clear();

        DcRunState& run = DcRun::Of(ownerAI);
        run.rezPendingSinceMs = 0;
        run.rezAnnounceMs = 0;
        run.noRezzerSinceMs = 0;
        run.noRezzerQuietSinceMs = 0;
        run.progress.stampMs = 0;  // stranded clock re-arms on the next evaluation

        if (PlayerbotAI* botAI = GET_PLAYERBOT_AI(bot))
            DcStatusPublisher::SendAddonMessage(
                botAI, map->IsRaid()
                           ? "CHAT\tThe raid wiped \xe2\x80\x94 regrouping at the entrance "
                             "and continuing."
                           : "CHAT\tNo one could be resurrected \xe2\x80\x94 regrouping at "
                             "the entrance and continuing.");
        return true;
    }

    std::string DescribeWait(Player* bot)
    {
        Plan const plan = EvaluateImpl(bot, /*mutate*/ false);
        if (plan.verdict.outcome != DcRezDecision::Outcome::Hold)
            return "";
        if (plan.verdict.reason == DcRezDecision::Reason::WaitingOnHuman)
            return "Waiting for you to resurrect " + plan.targetName + ".";
        if (plan.verdict.reason == DcRezDecision::Reason::BlockedWaiting)
            return "Can't resurrect " + plan.targetName +
                   " while the encounter is in progress.";
        return plan.rezzerName + " is coming to resurrect " + plan.targetName + ".";
    }

    // RebornWOW DCRZ2B -------------------------------------------------------
    namespace
    {
        struct CorpseRun
        {
            uint32 dueMs = 0;       // 0 = waiting on the player (no countdown)
            std::string why;
        };
        std::mutex g_corpseMutex;
        std::map<ObjectGuid, CorpseRun> g_corpseRuns;      // run owner -> pending corpse run
        std::map<ObjectGuid, uint32> g_botWipeSinceMs;     // run owner -> all bots dead since

        void Announce(Player* owner, std::string const& payload, std::string const& chat)
        {
            PlayerbotAI* ai = owner ? GET_PLAYERBOT_AI(owner) : nullptr;
            if (!ai)
                return;
            DcStatusPublisher::SendAddonMessage(ai, payload);
            if (!chat.empty())
                DcStatusPublisher::SendAddonMessage(ai, "CHAT\t" + chat);
        }

        // Bots on the owner's map: how many, how many dead (ghosts count dead).
        void CountBots(Player* owner, uint32& bots, uint32& dead)
        {
            bots = dead = 0;
            Group* group = owner->GetGroup();
            auto look = [&](Player* m)
            {
                if (!m || !m->IsInWorld() || m->GetMapId() != owner->GetMapId() || !GET_PLAYERBOT_AI(m))
                    return;
                ++bots;
                if (!m->IsAlive() || m->HasPlayerFlag(PLAYER_FLAGS_GHOST))
                    ++dead;
            };
            if (!group)
            {
                look(owner);
                return;
            }
            for (GroupReference* ref = group->GetFirstMember(); ref; ref = ref->next())
                look(ref->GetSource());
        }
    }

    bool RequestCorpseRun(Player* owner, std::string const& why)
    {
        if (!owner)
            return false;
        uint32 dueMs = 0;
        {
            std::lock_guard<std::mutex> lock(g_corpseMutex);
            if (g_corpseRuns.count(owner->GetGUID()))
                return true;  // already counting / waiting
            CorpseRun& cr = g_corpseRuns[owner->GetGUID()];
            cr.why = why;
            cr.dueMs = getMSTime() + kCorpseRunSeconds * 1000;
            dueMs = cr.dueMs;
        }
        (void)dueMs;
        LOG_INFO("playerbots.dungeonclear", "[DC:{}] DCRZ2B corpse run announced ({}), {}s", owner->GetName(),
                 why, kCorpseRunSeconds);
        Announce(owner, "RZ\tcount\t" + std::to_string(kCorpseRunSeconds) + "\t" + why,
                 "No one can resurrect \xe2\x80\x94 corpse run in " + std::to_string(kCorpseRunSeconds) +
                 "s: the dead bots revive at the entrance and the clear continues. Choose on the panel: "
                 "wait for me / run now / stop.");
        return true;
    }

    void HandleCorpseRunChoice(Player* human, std::string const& choice)
    {
        Player* owner = human ? DcLeaderSignal::FindRunOwner(human) : nullptr;
        if (!owner)
            return;
        bool stop = false;
        {
            std::lock_guard<std::mutex> lock(g_corpseMutex);
            auto it = g_corpseRuns.find(owner->GetGUID());
            if (it == g_corpseRuns.end())
                return;
            if (choice == "wait")
                it->second.dueMs = 0;
            else if (choice == "run")
                it->second.dueMs = getMSTime();
            else if (choice == "stop")
            {
                g_corpseRuns.erase(it);
                stop = true;
            }
            else
                return;
        }
        LOG_INFO("playerbots.dungeonclear", "[DC:{}] DCRZ2B corpse run: {} chose '{}'", owner->GetName(),
                 human->GetName(), choice);
        if (stop)
        {
            Announce(owner, "RZ\tend", "");
            if (PlayerbotAI* ai = GET_PLAYERBOT_AI(owner))
                DcActionShared::DisableDungeonClear(
                    ai, "Stopped after the deaths \xe2\x80\x94 dungeon clear disabled. Type 'dc on' when ready to resume.");
        }
        else if (choice == "wait")
            Announce(owner, "RZ\twait", "Waiting for you to resurrect the party.");
    }

    void TickCorpseRuns(uint32 diff)
    {
        static uint32 acc = 0;
        acc += diff;
        if (acc < 500)
            return;
        acc = 0;
        uint32 const now = getMSTime();

        // 1. A full bot wipe on a player-led run: no living bot is left to run the
        //    party-died bailout (corpses run no DC strategy), so watch for it here.
        for (ObjectGuid const& g : DcStatusPublisher::ActiveTanks())
        {
            Player* tank = ObjectAccessor::FindConnectedPlayer(g);
            PlayerbotAI* ai = tank ? GET_PLAYERBOT_AI(tank) : nullptr;
            if (!ai || !tank->IsInWorld() || !DcRun::Of(ai).enabled || !tank->GetMap() ||
                !tank->GetMap()->IsDungeon() || DcTestRunManager::Instance().IsTestTank(g))
            {
                std::lock_guard<std::mutex> lock(g_corpseMutex);
                g_botWipeSinceMs.erase(g);
                continue;
            }
            uint32 bots = 0, dead = 0;
            CountBots(tank, bots, dead);
            bool fire = false;
            {
                std::lock_guard<std::mutex> lock(g_corpseMutex);
                if (bots == 0 || dead < bots)
                    g_botWipeSinceMs.erase(g);
                else if (!g_botWipeSinceMs.count(g))
                    g_botWipeSinceMs[g] = now;
                else if (getMSTimeDiff(g_botWipeSinceMs[g], now) >= 5000 && !g_corpseRuns.count(g))
                    fire = true;
            }
            if (fire)
                RequestCorpseRun(tank, "wipe");
        }

        // 2. Countdowns and cleanup.
        std::vector<ObjectGuid> owners;
        {
            std::lock_guard<std::mutex> lock(g_corpseMutex);
            for (auto const& kv : g_corpseRuns)
                owners.push_back(kv.first);
        }
        for (ObjectGuid const& g : owners)
        {
            Player* owner = ObjectAccessor::FindConnectedPlayer(g);
            PlayerbotAI* ai = owner ? GET_PLAYERBOT_AI(owner) : nullptr;
            bool drop = !ai || !owner->IsInWorld() || !DcRun::Of(ai).enabled;
            uint32 bots = 0, dead = 0;
            if (!drop)
                CountBots(owner, bots, dead);
            if (!drop && dead == 0)
            {
                // Everyone is up again (the player raised them, or a soulstone):
                // nothing left to run for.
                Announce(owner, "RZ\tend", "");  // no dead bot left (raised, or only a human died)
                drop = true;
            }
            bool fire = false;
            {
                std::lock_guard<std::mutex> lock(g_corpseMutex);
                auto it = g_corpseRuns.find(g);
                if (it == g_corpseRuns.end())
                    continue;
                if (drop)
                {
                    g_corpseRuns.erase(it);
                    continue;
                }
                if (it->second.dueMs && getMSTimeDiff(it->second.dueMs, now) < 0x80000000u)
                {
                    fire = true;
                    g_corpseRuns.erase(it);
                }
            }
            if (fire)
            {
                LOG_INFO("playerbots.dungeonclear", "[DC:{}] DCRZ2B corpse run done: reviving {} dead bot(s) "
                         "at the entrance", owner->GetName(), dead);
                bool const ok = RegroupAtEntrance(owner);
                Announce(owner, "RZ\tend", ok ? "" : "No entrance known for this map \xe2\x80\x94 "
                                                      "resurrect the party yourself or stop the clear.");
                if (!ok)
                {
                    // No entrance row: fall back to waiting on the player.
                    std::lock_guard<std::mutex> lock(g_corpseMutex);
                    g_corpseRuns[g].dueMs = 0;
                }
                std::lock_guard<std::mutex> lock(g_corpseMutex);
                g_botWipeSinceMs.erase(g);
            }
        }
    }
}
