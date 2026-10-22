// WD200: automatic copies are synchronous, explicit single-target damage only.
#ifndef REBORN_WD_FOOL_200_H
#define REBORN_WD_FOOL_200_H
#include "SpellInfo.h"
namespace WD200
{
constexpr uint32 AutomaticKey=168200;
inline bool AutomaticEcho(SpellInfo const* info)
{
 if(!info||info->Speed!=0.f)return false;
 bool found=false;
 for(auto const& e:info->Effects)if(e.IsEffect())
 {
  if(e.TargetA.GetTarget()!=TARGET_UNIT_TARGET_ENEMY||e.TargetB.GetTarget()!=0||e.ChainTarget>1)return false;
  if(e.Effect!=SPELL_EFFECT_SCHOOL_DAMAGE&&e.Effect!=SPELL_EFFECT_WEAPON_PERCENT_DAMAGE&&e.Effect!=SPELL_EFFECT_WEAPON_DAMAGE&&e.Effect!=SPELL_EFFECT_NORMALIZED_WEAPON_DMG)return false;
  found=true;
 }
 return found;
}
}
#endif
