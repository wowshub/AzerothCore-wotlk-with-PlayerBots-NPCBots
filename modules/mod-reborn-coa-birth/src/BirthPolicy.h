#ifndef REBORN_COA_BIRTH_POLICY_H
#define REBORN_COA_BIRTH_POLICY_H

#include <cstdint>

namespace RebornCoaBirth
{
struct Profile
{
    std::uint8_t Race;
    std::uint8_t TemplateRace;
    std::uint8_t Alliance;
    std::uint32_t AliasMask;
    std::uint32_t LanguageSkill;
    std::uint32_t LanguageSpell;
};

inline constexpr Profile Profiles[] =
{
    {39, 1, 0, 64,    98,  668}, // Kul Tiran: Common; never Gnomish.
    {49, 2, 1, 65536, 109, 669}  // Mag'har: Orcish; never Draenei.
};

inline constexpr Profile const* FindProfile(std::uint8_t race, std::uint8_t playerClass)
{
    if (playerClass != 1) // First playable batch is Warrior only.
        return nullptr;
    for (Profile const& profile : Profiles)
        if (profile.Race == race)
            return &profile;
    return nullptr;
}

// Only existing parent-Warrior starting entries from this bounded list may be
// repaired. No racial, profession, riding, dual wield or advanced armor grant.
inline constexpr bool IsBasicSkill(std::uint32_t skill)
{
    switch (skill)
    {
        case 26: case 256: case 257: // Warrior skill-book sections.
        case 95: case 162:           // Defense, unarmed.
        case 43: case 44: case 54: case 55: case 160:
        case 172: case 173: case 176: // Parent's existing starting weapons only.
        case 413: case 414: case 415: case 433: // Mail, leather, cloth, shield.
            return true;
        default:
            return false;
    }
}
}
#endif
