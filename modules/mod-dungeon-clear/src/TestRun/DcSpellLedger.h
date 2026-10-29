/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license, you may redistribute it
 * and/or modify it under version 3 of the License, or (at your option), any later version.
 */

#ifndef _PLAYERBOT_DCSPELLLEDGER_H
#define _PLAYERBOT_DCSPELLLEDGER_H

#include <cstdint>
#include <string>
#include <vector>

#include "ObjectGuid.h"

// RebornWOW DCWD1A: what each party member's spells actually did, per spell -- the books for tuning
// a class's AI (the witch doctor first, but nothing here is class specific).
//
// Casts and effects are counted separately, because they are different questions:
//   started    AllSpellScript::OnSpellPrepare   the cast began
//   succeeded  AllSpellScript::OnSpellCast      the cast went off (this hook runs AFTER the spell executed;
//                                               Player's OnPlayerSpellCast runs BEFORE it, so it is not used)
//   cancelled  AllSpellScript::OnSpellCastCancel interrupted / cancelled / moved
//   triggered  succeeded casts that were triggered by another spell (procs, summoned attacks, copies)
//   damage / hits, healSelf / healOther / heals   from the engine's OnDamage / OnHeal
// A spell that fired once and hit five targets is ONE succeeded cast and five hits.
//
// OnDamage / OnHeal do not carry a spell. The spell behind an event is remembered by the hooks that run
// right before it for the same actor (ModifySpellDamageTaken / ModifyPeriodicDamageAurasTick /
// ModifyMeleeDamage / ModifyHealReceived) and used for that actor's next event only (250 ms). Whatever
// cannot be matched is booked under spellId kUnattributed, never dropped and never guessed, so
// per-spell numbers always add up to the totals.
//
// Pets, guardians, totems and other summons are credited to their owner (the party member) but kept as
// separate rows (sourceEntry = the summon's creature entry), so "the Serpent Ward's damage" and "the
// witch doctor's own damage" can be told apart. Damage is as the engine reports it (overkill is counted
// in `overkill`; effective damage = damage - overkill); healing is the effective heal (overheal is not
// reported by the engine hook and is not recorded).
//
// Cost while no run tracks anybody: one relaxed atomic load per event.
namespace DcSpellLedger
{
    constexpr std::uint32_t kMelee = 0;                    // auto attack / swing
    constexpr std::uint32_t kUnattributed = 0xFFFFFFFFu;   // an event with no spell remembered for it

    struct Row
    {
        std::string owner;               // the party member
        std::uint32_t sourceEntry = 0;   // 0 = the member itself, else the summon's creature entry
        std::string source;              // "" for the member, else the summon's name
        std::uint32_t spellId = 0;
        std::string spell;
        std::uint32_t started = 0, succeeded = 0, cancelled = 0, triggered = 0;
        std::uint32_t hits = 0, heals = 0;
        std::uint64_t damage = 0, overkill = 0, healSelf = 0, healOther = 0;
    };

    struct OwnerTotals
    {
        std::string owner;
        std::uint64_t damageAll = 0, overkillAll = 0, healAll = 0;   // every credited event, attributed or not
        std::uint64_t damageUnattributed = 0, healUnattributed = 0;
    };

    // Start (or keep) keeping books for a run's member. A different runId starts clean.
    void Track(ObjectGuid owner, std::string const& runId, std::string const& name);
    // Stop and forget everyone kept for the run.
    void Untrack(std::string const& runId);
    // The run's rows (largest effect first, at most `maxRows`) and per-member totals.
    void Snapshot(std::string const& runId, std::size_t maxRows, std::vector<Row>* rows, std::vector<OwnerTotals>* totals);
    // Registers the engine hooks (call once from AddSC).
    void Register();
}

#endif
