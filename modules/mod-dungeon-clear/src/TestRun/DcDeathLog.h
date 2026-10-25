/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license, you may redistribute it
 * and/or modify it under version 3 of the License, or (at your option), any later version.
 */

#ifndef _PLAYERBOT_DCDEATHLOG_H
#define _PLAYERBOT_DCDEATHLOG_H

#include <cstdint>
#include <string>
#include <utility>
#include <vector>

#include "ObjectGuid.h"

// RebornWOW DCBOSS1A: why did a test-party member die?
//
// The run record already said WHO died and what the party was fighting. It could
// not say what actually killed them -- which hit, which spell, how much of it,
// whether the healer was keeping up, how far down the boss was. "The whole party
// died to Bjarngrim" does not tell a boss that out-damages the healer from one that
// is simply never being hit.
//
// So this keeps, for every tracked party member, a short ring of the damage it took
// (source, spell, amount, the source's own health) and the healing it received,
// plus running totals per source/spell and per healer. The engine's UnitScript
// hooks feed it. Spell names come from the hit itself: ModifySpellDamageTaken /
// ModifyMeleeDamage / ModifyPeriodicDamageAurasTick run right before the
// DealDamage that fires OnDamage, so they are remembered for that one hit.
//
// Cost while no run is tracking anybody: one relaxed atomic load per hit.
namespace DcDeathLog
{
    struct LastHit
    {
        std::uint32_t ageMs = 0;     // before the last hit
        std::string src;
        std::string spell;
        std::uint32_t amount = 0;
    };

    struct Detail
    {
        bool any = false;            // false: nothing was logged for this member
        std::string killer;          // source of the last hit
        std::string killerSpell;     // "" for an unknown hit
        std::uint32_t killerSpellId = 0;
        std::uint32_t killerAmount = 0;
        std::uint32_t killerOverkill = 0;
        int killerHpPct = -1;        // the killer's own health %, -1 when not a creature
        bool killerBoss = false;
        std::uint32_t dmg5s = 0, dmg10s = 0, heal5s = 0, heal10s = 0;  // before the last hit
        std::string topSrc, topSpell;  // the biggest damage dealer of the last 5 s
        std::uint32_t topAmount = 0;
        std::vector<LastHit> lastHits; // newest first, up to 5
    };

    struct SourceTotal
    {
        std::string src;
        std::string spell;
        std::uint32_t spellId = 0;
        std::uint64_t total = 0;
        std::uint32_t hits = 0;
    };

    struct HealerTotal
    {
        std::string name;
        std::uint64_t total = 0;
    };

    // Start (or keep) logging a member for a run. Idempotent; a different runId
    // starts a fresh log for that member.
    void Track(ObjectGuid guid, std::string const& runId);
    // Stop and forget everyone logged for the run.
    void Untrack(std::string const& runId);
    // What killed this member. Does not clear anything.
    Detail TakeDeath(ObjectGuid guid);
    // Damage taken by source+spell and healing received by healer, summed over the
    // run's members, biggest first.
    void Totals(std::string const& runId, std::size_t maxSources, std::size_t maxHealers,
                std::vector<SourceTotal>* sources, std::vector<HealerTotal>* healers, std::uint64_t* taken);
    // RebornWOW DCSTAT3A: what the party DID, not only what it took.
    // Damage a tracked member (or its pet, or an NPCBot it owns) dealt to creatures, summed per
    // member, per target name and per boss fight, plus the damage each member took.
    struct MemberOut
    {
        std::string name;
        std::uint64_t dealt = 0;
        std::uint64_t taken = 0;     // only players are tracked as victims, so an NPCBot reads 0
    };
    struct TargetOut
    {
        std::string name;
        bool boss = false;
        std::uint64_t total = 0;
    };
    struct BossFight
    {
        std::string boss;
        std::uint32_t durMs = 0;     // first party hit -> last party hit on this boss
        std::uint64_t total = 0;
        std::vector<std::pair<std::string, std::uint64_t>> members;  // biggest first
    };
    struct Output
    {
        std::vector<MemberOut> members;
        std::vector<TargetOut> targets;
        std::vector<BossFight> bosses;
    };
    // The run's output so far (biggest first). Does not clear anything.
    void OutputOf(std::string const& runId, Output& out);
    // Registers the engine hooks (call once from AddSC).
    void Register();
}

#endif
