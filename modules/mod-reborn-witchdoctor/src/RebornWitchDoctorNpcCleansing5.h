// WDN5D: existing dispel/immunity mechanics; no player talent inheritance.
#pragma once
#include "RebornWitchDoctorNpcActor1.h"
namespace WDN5D
{
constexpr uint32 Hexbreak=9003240,Allcure=9003250,MassAllcure=9003442;
constexpr uint32 Curse=1u<<DISPEL_CURSE,Poison=1u<<DISPEL_POISON,Disease=1u<<DISPEL_DISEASE;
inline bool Eligible(Unit* caster,Unit* target)
{
 auto* c=WDN1::Actor(caster);
 return c&&target&&target->IsAlive()&&target->IsInWorld()&&c->IsInMap(target)&&
  c->InSamePhase(target)&&c->IsFriendlyTo(target)&&c->IsValidAssistTarget(target)&&
  (target==c||((target->GetTypeId()==TYPEID_PLAYER||target->IsNPCBot())&&c->GetBotAI()->IsInBotParty(target)))&&
  c->IsWithinDistInMap(target,30.f)&&c->IsWithinLOSInMap(target);
}
inline uint32 Afflictions(Unit* target)
{
 if(!target)return 0;
 uint32 mask=0;
 for(auto const& pair:target->GetAppliedAuras())
 {
  auto* app=pair.second;if(!app||app->IsPositive())continue;
  auto* aura=app->GetBase();if(!aura||aura->IsPassive())continue;
  auto* info=aura->GetSpellInfo();if(!info)continue;
  if((info->AttributesEx7&SPELL_ATTR7_DISPEL_REMOVES_CHARGES)?!aura->GetCharges():!aura->GetStackAmount())continue;
  if(info->Dispel==DISPEL_CURSE)mask|=Curse;
  if(info->Dispel==DISPEL_POISON)mask|=Poison;
  if(info->Dispel==DISPEL_DISEASE)mask|=Disease;
 }
 return mask;
}
inline uint32 Choose(uint32 affected,uint32 mask,bool groupReady,bool singleReady,bool curseReady)
{
 if(affected>=2&&groupReady)return MassAllcure;
 if((mask&(Poison|Disease))&&singleReady)return Allcure;
 if((mask&Curse)&&curseReady)return Hexbreak;
 if(mask&&singleReady)return Allcure;
 return 0;
}
}
