/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license, you may redistribute it
 * and/or modify it under version 3 of the License, or (at your option), any later version.
 */

#include "gtest/gtest.h"

#include "DcRoleFitDecision.h"

using namespace DcRoleFit;

namespace
{
    Inputs Mk(std::uint32_t cls, char const* role, std::uint32_t a, std::uint32_t b, std::uint32_t c,
              bool shield = true, bool twoHand = false, std::uint32_t level = 80)
    {
        Inputs i;
        i.classId = cls;
        i.role = role;
        i.points[0] = a;
        i.points[1] = b;
        i.points[2] = c;
        i.offHandShield = shield;
        i.mainHandTwoHand = twoHand;
        i.level = level;
        return i;
    }

    std::vector<std::string> V(std::initializer_list<char const*> l)
    {
        return std::vector<std::string>(l.begin(), l.end());
    }
}

// the first lightning-hall wipe: an arms warrior tank, two-hander, no shield
TEST(RoleFit, WarriorTankOnArmsWithTwoHander)
{
    EXPECT_EQ(Decide(Mk(1, "tank", 40, 0, 31, false, true)), V({ "TANK_TREE", "TANK_2H" }));
}

TEST(RoleFit, WarriorTankProtectionWithShieldIsFine)
{
    EXPECT_TRUE(Decide(Mk(1, "tank", 3, 5, 61)).empty());
}

TEST(RoleFit, ProtectionWarriorWithoutShield)
{
    EXPECT_EQ(Decide(Mk(1, "tank", 3, 5, 61, false)), V({ "TANK_SHIELD" }));
}

TEST(RoleFit, PaladinTankOnRetribution)
{
    EXPECT_EQ(Decide(Mk(2, "tank", 0, 5, 66)), V({ "TANK_TREE" }));
    EXPECT_TRUE(Decide(Mk(2, "tank", 0, 53, 18)).empty());
}

TEST(RoleFit, DruidTankNeedsFeralAndNoShield)
{
    EXPECT_TRUE(Decide(Mk(11, "tank", 0, 60, 11, false)).empty());
    EXPECT_EQ(Decide(Mk(11, "tank", 60, 0, 11, false)), V({ "TANK_TREE" }));
}

TEST(RoleFit, DeathKnightTankAnyTreeNoShield)
{
    EXPECT_TRUE(Decide(Mk(6, "tank", 0, 51, 20, false)).empty());
}

// the "healer" on the elemental tree
TEST(RoleFit, ShamanHealerOnElemental)
{
    EXPECT_EQ(Decide(Mk(7, "heal", 50, 0, 21)), V({ "HEAL_TREE" }));
    EXPECT_TRUE(Decide(Mk(7, "heal", 0, 0, 61)).empty());
}

TEST(RoleFit, PriestHealerShadowOnly)
{
    EXPECT_EQ(Decide(Mk(5, "heal", 0, 0, 61)), V({ "HEAL_TREE" }));
    EXPECT_TRUE(Decide(Mk(5, "heal", 0, 61, 10)).empty());
    EXPECT_TRUE(Decide(Mk(5, "heal", 51, 20, 0)).empty());
}

TEST(RoleFit, PaladinAndDruidHealer)
{
    EXPECT_EQ(Decide(Mk(2, "heal", 0, 5, 66)), V({ "HEAL_TREE" }));
    EXPECT_TRUE(Decide(Mk(11, "heal", 0, 10, 61)).empty());
}

TEST(RoleFit, DpsAndCustomClassesAreNotJudged)
{
    EXPECT_TRUE(Decide(Mk(1, "dps", 0, 0, 71, false, true)).empty());
    EXPECT_TRUE(Decide(Mk(13, "tank", 71, 0, 0, false)).empty());
}

TEST(RoleFit, ATieIsNotAMismatch)
{
    EXPECT_TRUE(Decide(Mk(2, "heal", 31, 0, 31)).empty());
}

TEST(RoleFit, UnspentTalentPoints)
{
    EXPECT_EQ(Decide(Mk(1, "dps", 40, 0, 0)), V({ "TALENTS_UNSPENT" }));
    EXPECT_TRUE(Decide(Mk(1, "dps", 40, 0, 31)).empty());
    EXPECT_TRUE(Decide(Mk(1, "dps", 10, 0, 0, true, false, 60)).empty());
}

TEST(RoleFit, UndecidedTreeIsNotCalledWrong)
{
    // 12 points only: the tree is not decided, the unspent-points warning says what is wrong
    EXPECT_EQ(Decide(Mk(1, "tank", 0, 0, 12, true)), V({ "TALENTS_UNSPENT" }));
}
