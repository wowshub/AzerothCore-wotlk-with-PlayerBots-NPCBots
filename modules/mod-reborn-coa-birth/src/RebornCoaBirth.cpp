// RACENEXT2A: explicit birth-language and missing basic-skill repair for 39/49.
// This module does not open creation, initialize reputation, or award items.
#include "ScriptMgr.h"
#include "Player.h"
#include "RaceMgr.h"
#include "ObjectMgr.h"
#include "DBCStores.h"
#include "SpellMgr.h"
#include "SpellInfo.h"
#include "Config.h"
#include "Log.h"
#include "BirthPolicy.h"
#include <algorithm>
#include <vector>

namespace
{
using namespace RebornCoaBirth;

char const* CheckPrerequisites(Profile const& profile)
{
    ChrRacesEntry const* race = sChrRacesStore.LookupEntry(profile.Race);
    if (!race || (race->Flags & CHRRACES_FLAGS_NOT_PLAYABLE) || race->alliance != profile.Alliance)
        return "missing/playability/faction ChrRaces contract";
    if (sRaceMgr->GetMaxRaces() <= profile.Race)
        return "runtime race capacity not ready";
    if (GetRaceMaskForRace(profile.Race) != profile.AliasMask)
        return "coordinated race-mask contract not ready";
    if (GetReputationRaceMaskForRace(profile.Race) != GetRaceMaskForRace(profile.TemplateRace))
        return "explicit reputation template not ready";
    if (!sObjectMgr->GetPlayerInfo(profile.Race, CLASS_WARRIOR) ||
        !sObjectMgr->GetPlayerInfo(profile.TemplateRace, CLASS_WARRIOR))
        return "missing Warrior birth information";
    if (!GetSkillRaceClassInfo(profile.LanguageSkill, profile.Race, CLASS_WARRIOR) ||
        !sSpellMgr->GetSpellInfo(profile.LanguageSpell))
        return "missing explicit language skill/spell data";
    auto bounds = sSpellMgr->GetSkillLineAbilityMapBounds(profile.LanguageSpell);
    for (auto i = bounds.first; i != bounds.second; ++i)
        if (i->second->SkillLine == profile.LanguageSkill)
            return nullptr;
    return "language spell is not linked to its language skill";
}

void Synchronize(Player* player)
{
    if (!player)
        return;
    Profile const* profile = FindProfile(player->getRace(true), player->getClass());
    if (!profile || !sConfigMgr->GetOption<bool>("RebornCoaBirth.Enable", false))
        return;

    if (char const* problem = CheckPrerequisites(*profile))
    {
        LOG_ERROR("module", "RACENEXT2A: race {} skipped: {}", uint32(profile->Race), problem);
        return;
    }
    if (!player->IsSpellFitByClassAndRace(profile->LanguageSpell))
    {
        LOG_ERROR("module", "RACENEXT2A: race {} explicit language eligibility missing", uint32(profile->Race));
        return;
    }

    PlayerInfo const* parent = sObjectMgr->GetPlayerInfo(profile->TemplateRace, CLASS_WARRIOR);
    std::vector<uint32> missing;
    for (PlayerCreateInfoSkill const& entry : parent->skills)
    {
        if (entry.Rank != 0 || !IsBasicSkill(entry.SkillId) || player->HasSkill(entry.SkillId) ||
            std::find(missing.begin(), missing.end(), entry.SkillId) != missing.end())
            continue;
        // Preflight all missing skills BEFORE the first grant. Skill reward
        // eligibility must be integrated in the core, not forced by this module.
        if (!GetSkillRaceClassInfo(entry.SkillId, profile->Race, CLASS_WARRIOR))
        {
            LOG_ERROR("module", "RACENEXT2A: race {} basic skill {} eligibility missing; no repair",
                uint32(profile->Race), uint32(entry.SkillId));
            return;
        }
        missing.push_back(entry.SkillId);
    }

    if (!player->HasSpell(profile->LanguageSpell))
        player->learnSpell(profile->LanguageSpell);
    if (!player->HasSpell(profile->LanguageSpell))
    {
        LOG_ERROR("module", "RACENEXT2A: race {} language learn failed; basic skills skipped", uint32(profile->Race));
        return;
    }
    if (!player->HasSkill(profile->LanguageSkill))
        player->SetSkill(profile->LanguageSkill, 0, 300, 300);
    // Existing values, progression and skills are never reset or maxed here.
    for (uint32 skill : missing)
        if (!player->HasSkill(skill))
            player->LearnDefaultSkill(skill, 0);
}

class RebornCoaBirthPlayerScript final : public PlayerScript
{
public:
    RebornCoaBirthPlayerScript() : PlayerScript("RebornCoaBirthPlayerScript",
        {PLAYERHOOK_ON_CREATE, PLAYERHOOK_ON_LOGIN}) { }

    void OnPlayerCreate(Player* player) override { Synchronize(player); }
    void OnPlayerLogin(Player* player) override { Synchronize(player); }
};
}

void AddRebornCoaBirthScripts()
{
    new RebornCoaBirthPlayerScript();
    LOG_INFO("module", "RACENEXT2A: birth repair registered for race39/49 Warrior; enabled={}",
        sConfigMgr->GetOption<bool>("RebornCoaBirth.Enable", false));
}
