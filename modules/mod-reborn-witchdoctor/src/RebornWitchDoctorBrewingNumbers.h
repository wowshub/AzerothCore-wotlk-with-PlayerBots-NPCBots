#pragma once
#include <algorithm>
#include "Player.h"
#include "SpellInfo.h"
namespace WD120A
{
constexpr uint32 Brewer=9003864, Shrooms=9003865, Pulse=9003866, Hot=9003867;
// WD122: shared runtime / tooltip cap; private aura avoids donor family-mask leakage.
inline uint32 PulseTargets(Unit* caster) { return caster->HasAura(9003880)?5u:8u; }
inline bool IsToss(uint32 id) { return id>=9003870 && id<=9003876; }
constexpr uint32 SplashHot=9003889;
inline bool IsSplash(uint32 id) { return id>=9003890 && id<=9003896; }
inline float SplashBonus(Player* p)
{
    return float(std::max(0,p->SpellBaseHealingBonusDone(SPELL_SCHOOL_MASK_NATURE)))*0.224494f
        +std::max(0.0f,p->GetStat(STAT_SPIRIT))*0.08f;
}
inline double Scaling(uint32 level)
{
    return 0.0267291844060354+0.0048541098014737*level+0.0001859597762293*level*level;
}
inline float Bonus(Player* p,bool pulse)
{
    return float(std::max(0,p->SpellBaseHealingBonusDone(SPELL_SCHOOL_MASK_NATURE)))*(pulse?0.20f:0.28f)
        +(pulse?0.0f:std::max(0.0f,p->GetStat(STAT_SPIRIT))*0.10f);
}
}

// WD125: private ingredient spell IDs; never use the donor IDs in live spellbook.
namespace WD125A
{
constexpr uint32 FishPrep=9003901,FishField=9003902,FishPotion=9003903,FishSplash=9003904;
constexpr uint32 BonesPrep=9003905,BonesField=9003906,BonesPotion=9003907,BonesSplash=9003908;
inline bool IsPrep(uint32 id) { return id==FishPrep || id==BonesPrep || id==WD120A::Shrooms; }
}
