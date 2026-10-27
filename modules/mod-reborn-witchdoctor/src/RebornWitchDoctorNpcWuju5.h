// WDN5E: mutually exclusive, party-only Wuju maintenance.
#pragma once
#include "RebornWitchDoctorNpcActor1.h"
namespace WDN5E
{
constexpr uint32 Spirit=9003140,Power=9003180,Resourceful=9003190;
constexpr uint32 GreaterResourceful=9003280,GreaterSpirit=9003290,GreaterPower=9003300;
inline uint32 Kind(uint32 id)
{
 uint32 b=WDN1::Base(id);
 if(b==Spirit||b==GreaterSpirit)return Spirit;
 if(b==Power||b==GreaterPower)return Power;
 if(b==Resourceful||b==GreaterResourceful)return Resourceful;
 return 0;
}
inline bool Group(uint32 id){return id==GreaterResourceful||id==GreaterSpirit||id==GreaterPower;}
inline float Radius(uint32 id){return id==GreaterResourceful?100.f:id==GreaterPower?40.f:30.f;}
inline uint32 Learned(Creature* c,uint32 base)
{
 auto const& spells=c->GetBotAI()->GetSpellMap();auto it=spells.find(base);
 uint32 id=it!=spells.end()&&it->second?it->second->spellId:0;
 return WDN1::Known(c,id)?id:0;
}
inline uint32 Preferred(Creature* c,Unit* t)
{
 uint32 first=t->getPowerType()==POWER_MANA?Resourceful:Power;
 if(Learned(c,first)||Learned(c,first==Resourceful?GreaterResourceful:GreaterPower))return first;
 return Learned(c,Spirit)||Learned(c,GreaterSpirit)?Spirit:0;
}
inline bool Eligible(Unit* caster,Unit* t,float radius)
{
 auto* c=WDN1::Actor(caster);
 return c&&t&&t->IsAlive()&&t->IsInWorld()&&c->IsInMap(t)&&c->InSamePhase(t)&&
  c->IsFriendlyTo(t)&&c->IsValidAssistTarget(t)&&
  (t==c||((t->GetTypeId()==TYPEID_PLAYER||t->IsNPCBot())&&c->GetBotAI()->IsInBotParty(t)))&&
  c->IsWithinDistInMap(t,radius)&&c->IsWithinLOSInMap(t);
}
// 0: preserve existing blessing, 1: compatible but fresh, 2: missing/expiring.
inline uint32 Need(Creature* c,Unit* t,uint32 id)
{
 uint32 kind=Kind(id);if(!kind||Preferred(c,t)!=kind)return 0;
 bool found=false,fresh=false;
 for(auto const& pair:t->GetAppliedAuras())
 {
  auto* app=pair.second;auto* a=app?app->GetBase():nullptr;
  if(!a||!Kind(a->GetId()))continue;
  if(a->GetCasterGUID()!=c->GetGUID()||Kind(a->GetId())!=kind)return 0;
  found=true;
  if(a->GetDuration()<0||a->GetDuration()>60000)fresh=true;
 }
 return found&&fresh?1:2;
}
}
