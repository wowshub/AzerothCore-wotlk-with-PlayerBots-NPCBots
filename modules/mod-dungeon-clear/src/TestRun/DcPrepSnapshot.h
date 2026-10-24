/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license, you may redistribute it
 * and/or modify it under version 3 of the License, or (at your option), any later version.
 */

#ifndef _PLAYERBOT_DCPREPSNAPSHOT_H
#define _PLAYERBOT_DCPREPSNAPSHOT_H

#include <cstdint>
#include <string>
#include <vector>

class Player;

// RebornWOW DCPREP1A: how ready a character is to go in -- gear level, the stats that matter, the
// flask / elixir / food it is wearing, and the potions and food it carries. Read once for the run
// record (comp[].prep) and on request for the addon's readiness panel. Pure reads, no state.
namespace DcPrep
{
    struct Stats
    {
        std::uint32_t hp = 0;
        std::uint32_t mana = 0;       // max of the character's own power bar
        std::uint32_t powerType = 0;  // Powers: 0 mana, 1 rage, 3 energy, 6 runic power
        std::uint32_t armor = 0;
        std::uint32_t ap = 0;         // melee attack power
        std::uint32_t rap = 0;        // ranged attack power
        std::uint32_t sp = 0;         // spell damage bonus
        std::uint32_t healSp = 0;     // spell healing bonus
        std::uint32_t expertise = 0;
        std::uint32_t defense = 0;    // defence skill
        std::uint32_t resilience = 0; // resilience rating
        float crit = 0.f, rcrit = 0.f, scrit = 0.f;  // melee / ranged / spell crit chance, %
        float hit = 0.f, rhit = 0.f, shit = 0.f;      // melee / ranged / spell hit, %
        float haste = 0.f;                            // the best of the three, %
        float dodge = 0.f, parry = 0.f, block = 0.f;  // %
    };

    struct Buff
    {
        char kind = 'F';              // F flask, E elixir, W well-fed food
        std::uint32_t spellId = 0;    // the aura on the character (the addon takes its icon)
        std::uint32_t secs = 0;       // seconds left, 0 = unknown / no limit
    };

    struct Stock
    {
        char kind = 'H';              // H health potion, M mana potion, F flask, E elixir, W food
        std::uint32_t itemId = 0;     // the best stack of that kind (the addon takes its icon)
        std::uint32_t count = 0;      // everything of that kind in the bags
    };

    struct Snapshot
    {
        bool valid = false;
        std::uint32_t classId = 0;
        std::uint32_t level = 0;
        std::string role;                 // tank | heal | dps
        std::string talents;              // points in the three tabs, "5/31/35"
        std::uint32_t avgIlvl = 0;
        std::uint32_t minIlvl = 0;        // the weakest equipped piece
        std::uint32_t emptySlots = 0;     // empty slots among the ones every class fills
        std::uint32_t durabilityPct = 100;  // the lowest piece
        bool needsPet = false;            // hunter / warlock
        bool hasPet = false;
        Stats stats;
        std::vector<Buff> buffs;
        std::vector<Stock> stock;
    };

    // `role` may be empty: it is then read from the character's spec.
    Snapshot Capture(Player* p, std::string const& role);

    // One JSON object, no trailing newline.
    std::string ToJson(Snapshot const& s);
}

#endif
