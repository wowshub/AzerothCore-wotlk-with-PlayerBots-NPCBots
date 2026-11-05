/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license, you may redistribute it
 * and/or modify it under version 3 of the License, or (at your option), any later version.
 */

#ifndef _PLAYERBOT_DCROLEFITDECISION_H
#define _PLAYERBOT_DCROLEFITDECISION_H

#include <algorithm>
#include <cstdint>
#include <string>
#include <vector>

// RebornWOW DCP1C-B: does a character's build fit the role it is about to play? Pure decision
// kernel for the readiness panel's warnings; engine-free so it is unit-testable.
//
// Why: the first lightning-hall wipe (2026-10-11) was a tank on the weapon talents, holding a
// two-hander and no shield, and a "healer" on the elemental tree. Nothing said so before the pull.
//
// What it does NOT do: it never blocks anything and it never changes a build. It names the
// mismatch, once per code, and the panel shows it next to the character. Only the three stock
// classes whose role depends on a tree and a shield are judged; custom classes (Witch Doctor,
// Monk, ...) and NPCBots return nothing, because their trees are not known here.
//
// Tab order is the DBC `tabpage`: warrior Arms/Fury/Protection, paladin Holy/Protection/
// Retribution, priest Discipline/Holy/Shadow, shaman Elemental/Enhancement/Restoration,
// druid Balance/Feral/Restoration. A tie counts as fitting -- the warning is for a build that is
// clearly in the wrong place, not for a split one.
namespace DcRoleFit
{
    // class ids as in the DBC
    constexpr std::uint32_t kWarrior = 1, kPaladin = 2, kPriest = 5, kShaman = 7, kDruid = 11;

    struct Inputs
    {
        std::uint32_t classId = 0;
        std::uint32_t level = 0;
        std::string role;                  // tank | heal | dps
        std::uint32_t points[3] = { 0, 0, 0 };
        bool mainHandTwoHand = false;      // a two-handed weapon in the main hand
        bool offHandShield = false;        // a shield in the off hand
    };

    // codes: TANK_TREE, TANK_2H, TANK_SHIELD, HEAL_TREE, TALENTS_UNSPENT
    inline std::vector<std::string> Decide(Inputs const& in)
    {
        std::vector<std::string> out;
        std::uint32_t const total = in.points[0] + in.points[1] + in.points[2];

        // Unspent talent points: a level-80 build has 71. Only judged from 70 up and only when
        // clearly short, so a character that just levelled is not nagged.
        if (in.level >= 70 && total + 10 < in.level - 9)
            out.push_back("TALENTS_UNSPENT");

        auto isMax = [&](int tab)
        {
            std::uint32_t best = 0;
            for (int i = 0; i < 3; ++i)
                if (i != tab)
                    best = std::max(best, in.points[i]);
            return in.points[tab] >= best;
        };

        // below 20 points the tree is not decided yet; the unspent-points warning covers it
        bool const decided = total >= 20;

        if (in.role == "tank")
        {
            int tankTab = -1;
            bool needsShield = false;
            switch (in.classId)
            {
                case kWarrior: tankTab = 2; needsShield = true; break;
                case kPaladin: tankTab = 1; needsShield = true; break;
                case kDruid:   tankTab = 1; break;   // feral (bear)
                default: break;                       // death knight: any tree can tank
            }
            if (tankTab >= 0 && decided && !isMax(tankTab))
                out.push_back("TANK_TREE");
            if (needsShield && !in.offHandShield)
                out.push_back(in.mainHandTwoHand ? "TANK_2H" : "TANK_SHIELD");
        }
        else if (in.role == "heal" && decided)
        {
            int healTab = -1;
            switch (in.classId)
            {
                case kPaladin: healTab = 0; break;   // holy
                case kDruid:   healTab = 2; break;   // restoration
                case kShaman:  healTab = 2; break;   // restoration
                default: break;
            }
            if (healTab >= 0 && !isMax(healTab))
                out.push_back("HEAL_TREE");
            // a priest heals from discipline or holy; shadow is the one tree that does not
            if (in.classId == kPriest && in.points[2] > std::max(in.points[0], in.points[1]))
                out.push_back("HEAL_TREE");
        }
        return out;
    }
}

#endif  // _PLAYERBOT_DCROLEFITDECISION_H
