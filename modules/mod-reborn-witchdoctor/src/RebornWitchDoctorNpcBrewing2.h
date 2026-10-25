// WDN2P: bounded NPC ingredient / Potion Toss adapter; no player talent inheritance.
#pragma once
#include "RebornWitchDoctorNpcIdol2.h"
#include "RebornWitchDoctorBrewingNumbers.h"
namespace WDN2P
{
constexpr uint32 Thistle=9003915,ThistleField=9003916,ThistlePotion=9003917,ThistleSplash=9003918;
constexpr uint32 Fish=9003901,FishField=9003902,FishPotion=9003903,FishSplash=9003904;
constexpr uint32 Bones=9003905,BonesField=9003906,BonesPotion=9003907,BonesSplash=9003908;
constexpr uint32 Splash=9003890,SplashHot=9003889;
constexpr WD19A::Rank SplashRanks[]={{9003890,17},{9003891,22},{9003892,28},{9003893,36},{9003894,44},{9003895,50},{9003896,58}};
constexpr uint32 Prep=9003865,Pulse=9003866,Hot=9003867,Toss=9003870;
constexpr WD19A::Rank TossRanks[]={{9003870,14},{9003871,22},{9003872,30},{9003873,38},{9003874,46},{9003875,54},{9003876,60}};
inline uint32 Base(uint32 id){return id==Thistle?Thistle:id==Fish?Fish:id==Bones?Bones:id==Prep?Prep:WD120A::IsToss(id)?Toss:WD120A::IsSplash(id)?Splash:0;}
inline bool Known(Creature*c,uint32 id)
{
 if(!WDN1::Actor(c)||!Base(id))return false;
 auto*info=sSpellMgr->GetSpellInfo(id);auto const&spells=c->GetBotAI()->GetSpellMap();auto it=spells.find(Base(id));
 return info&&c->GetLevel()>=info->SpellLevel&&it!=spells.end()&&it->second&&it->second->enabled&&it->second->spellId==id;
}
inline bool Active(Creature*c)
{return WDN1::Actor(c)&&!c->GetBotAI()->HasBotCommandState(BOT_COMMAND_FULLSTOP|BOT_COMMAND_INACTION);}
inline uint32 Selected(Creature*c){return Known(c,Prep)?Prep:Known(c,Bones)?Bones:Known(c,Fish)?Fish:Known(c,Thistle)?Thistle:0;}
inline bool Ingredient(Creature*c,uint32 id){return Active(c)&&Selected(c)==id&&c->HasAura(id,c->GetGUID());}
inline bool Prepared(Creature*c){return Ingredient(c,Prep)||Ingredient(c,Bones)||Ingredient(c,Fish)||Ingredient(c,Thistle);}
inline void Clear(Creature*c){if(c)for(uint32 id:{Prep,Bones,BonesField,Fish,FishField,Thistle,ThistleField})c->RemoveAurasDueToSpell(id,c->GetGUID());}
inline int32 Shield(Creature*c,bool splash){return std::max(1,int32((splash?25.f:100.f)+std::max(0.f,c->GetStat(STAT_SPIRIT))*.35f+float(std::max(0,c->SpellBaseHealingBonusDone(SPELL_SCHOOL_MASK_NATURE)))*.80f));}
inline bool Eligible(Creature*c,Unit*t)
{return Active(c)&&WDN2D::Eligible(c,c,t,false);}
inline std::vector<Unit*> Targets(Creature*c)
{
 std::vector<Unit*> result;if(!Active(c))return result;
 for(Unit*t:WDN2D::Nearby(c))
  if(Eligible(c,t)&&t->GetHealthPct()<100.f&&std::none_of(result.begin(),result.end(),[t](Unit*u){return u->GetGUID()==t->GetGUID();}))result.push_back(t);
 std::sort(result.begin(),result.end(),[](Unit*a,Unit*b){return a->GetHealthPct()!=b->GetHealthPct()?a->GetHealthPct()<b->GetHealthPct():a->GetGUID()<b->GetGUID();});
 return result;
}
// Ground-target spells lose their explicit Unit in Spell::InitExplicitTargets.
// Keep selection anchored to the destination snapshot, not a moving ally pointer.
inline bool Destination(Creature*c,Position const*center)
{return Active(c)&&center&&c->GetExactDist(center)<=40.f;}
inline bool SplashEligible(Creature*c,Unit*t,Position const*center)
{return Destination(c,center)&&Eligible(c,t)&&t->GetExactDist(center)<=10.f;}
inline std::vector<Unit*> SplashTargets(Creature*c,Position const*center)
{
 auto result=Targets(c);
 result.erase(std::remove_if(result.begin(),result.end(),[c,center](Unit*t){return !SplashEligible(c,t,center);}),result.end());
 if(result.size()>8)result.resize(8);return result;
}
inline Unit* SplashAnchor(Creature*c)
{
 auto targets=Targets(c);Unit*best=nullptr;uint32 bestCount=1;
 for(Unit*anchor:targets)
 {
  uint32 count=0;
  for(Unit*t:targets)if(t->GetHealthPct()<70.f&&t->GetExactDist(anchor)<=10.f)++count;
  count=std::min(count,8u);
  if(count>bestCount){bestCount=count;best=anchor;}
 }
 return best;
}
inline void Maintain(Creature*c)
{
 if(!c)return;
 if(!Active(c)){Clear(c);return;}
 uint32 selected=Selected(c);
 if(selected!=Prep)c->RemoveAurasDueToSpell(Prep,c->GetGUID());
 if(selected!=Thistle){c->RemoveAurasDueToSpell(Thistle,c->GetGUID());c->RemoveAurasDueToSpell(ThistleField,c->GetGUID());}
 if(selected!=Fish){c->RemoveAurasDueToSpell(Fish,c->GetGUID());c->RemoveAurasDueToSpell(FishField,c->GetGUID());}
 if(selected!=Bones){c->RemoveAurasDueToSpell(Bones,c->GetGUID());c->RemoveAurasDueToSpell(BonesField,c->GetGUID());}
}
inline int32 Amount(Creature*c,int32 base,bool pulse,bool splash=false)
{
 if(pulse)base=int32(double(base)*WD120A::Scaling(c->GetLevel()));
 return int32(float(base)+float(std::max(0,c->SpellBaseHealingBonusDone(SPELL_SCHOOL_MASK_NATURE)))*(pulse?0.20f:splash?0.224494f:0.28f)
  +(pulse?0.f:std::max(0.f,c->GetStat(STAT_SPIRIT))*(splash?0.08f:0.10f)));
}
}
