#pragma once
#include <cstdint>
#include "RebornNeutralOrigin.h"

// WOW64SEVEN1A: identity is separate from legacy mask aliases and old Darkfallen38.
inline constexpr bool IsSevenAllianceRace(std::uint8_t race) {
    return race == 43 || race == 52 || race == 80 || race == 108;
}
inline constexpr bool IsSevenHordeRace(std::uint8_t race) { return race == 57 || race == 66; }
inline constexpr bool IsSevenNewRace(std::uint8_t race) { return IsSevenAllianceRace(race) || IsSevenHordeRace(race); }
inline constexpr std::uint8_t RebornMoguAllianceRace = 123;
inline constexpr std::uint8_t RebornSurekiAllianceRace = 86;
inline constexpr std::uint8_t RebornStormforgedAllianceRace = 84;
// WOW64RACE12A: explicit identities; faction never comes from a filename suffix.
inline constexpr bool IsRace12Alliance(std::uint8_t race) { return race == 28 || race == 68 || race == 67 || race == 78 || race == 50 || race == 99 || race == 79 || race == RebornMoguAllianceRace || race == RebornSurekiAllianceRace || race == RebornStormforgedAllianceRace; }
inline constexpr bool IsRace12Horde(std::uint8_t race) { return race == 51 || race == 101 || race == 41 || race == 102 || race == 110 || race == 125; }
inline constexpr bool IsRace12(std::uint8_t race) { return IsRace12Alliance(race) || IsRace12Horde(race); }
inline constexpr std::uint8_t RebornMurlocHordeRace = 121;
inline constexpr bool IsMurlocStarterClass(std::uint8_t playerClass)
{
    return (playerClass >= 1 && playerClass <= 9) || playerClass == 11
        || (playerClass >= 13 && playerClass <= 15);
}
// RACECLASS1A: these are real race identities, independent from shared mask bits.
inline constexpr bool IsClassicExpansionRace(std::uint8_t race)
{
    return race == RebornMurlocHordeRace || race == 91 || RebornNeutralOrigin::IsRace(race) || IsRace12(race) || IsSevenNewRace(race) || race == 36 || race == 37 || race == 38 || race == 39 || race == 40 || race == 49 || race == 73 || race == 109;
}
inline constexpr bool IsClassicExpansionClass(std::uint8_t playerClass)
{
    return (playerClass >= 1 && playerClass <= 9) || playerClass == 11;
}
inline constexpr std::uint8_t GetClassicExpansionDonor(std::uint8_t race, std::uint8_t playerClass)
{
    if (race == RebornMoguAllianceRace)
    {
        if (!IsClassicExpansionClass(playerClass))
            return 0;
        // Preserve the established Human donor and use Alliance starter kits for the new classes.
        constexpr std::uint8_t donors[] = {0,1,1,3,1,1,1,11,1,1,0,4};
        return donors[playerClass];
    }
    if (race == RebornMurlocHordeRace)
    {
        constexpr std::uint8_t donors[] = {0,2,10,2,2,5,2,2,5,2,0,6,0,2,2,5};
        return IsMurlocStarterClass(playerClass) ? donors[playerClass] : 0;
    }
    if (!IsClassicExpansionRace(race) || !IsClassicExpansionClass(playerClass))
        return 0;
    if (RebornNeutralOrigin::IsRace(race)) return RebornNeutralOrigin::Donor(1,playerClass);
    constexpr std::uint8_t alliance[] = {0,1,1,3,1,1,1,11,1,1,0,4};
    constexpr std::uint8_t horde[] = {0,2,10,2,2,5,2,2,5,2,0,6};
    return (race == 91 || IsRace12Alliance(race) || IsSevenAllianceRace(race) || race == 36 || race == 39 || race == 40) ? alliance[playerClass] : horde[playerClass];
}
inline constexpr bool IsClassicExpansionSkill(std::uint32_t skill)
{
    switch (skill)
    {
        case 6: case 8: case 26: case 38: case 39: case 50: case 51: case 56:
        case 78: case 134: case 163: case 184: case 237: case 253: case 256:
        case 257: case 267: case 354: case 355: case 373: case 374: case 375:
        case 573: case 574: case 593: case 594: case 613: case 770: case 771: case 772:
        case 43: case 44: case 45: case 46: case 54: case 55: case 95: case 118:
        case 136: case 160: case 162: case 172: case 173: case 176: case 183:
        case 226: case 228: case 229: case 293: case 413: case 414: case 415:
        case 433: case 473:
            return true;
        default:
            return false;
    }
}
