// WDN2B: baseline Call of Sseratus; independent from the ordinary ward slot.
#ifndef REBORN_WD_NPC_MASS_WARD_2_H
#define REBORN_WD_NPC_MASS_WARD_2_H
#include "RebornWitchDoctorNpcWard1.h"
namespace WDN2B
{
constexpr uint32 SpellId=9004080,Count=4,Lifetime=15000;
constexpr char Key[]="RebornWD.NpcMassWard2";
struct State:DataMap::Base { std::vector<ObjectGuid> wards;uint32 recruiter=0;bool creating=false; };
inline bool Known(Creature* c)
{
 if(!WDN1::Actor(c))return false;
 auto* info=sSpellMgr->GetSpellInfo(SpellId);
 auto const& spells=c->GetBotAI()->GetSpellMap();auto it=spells.find(SpellId);
 return info&&c->GetLevel()>=info->SpellLevel&&it!=spells.end()&&it->second&&it->second->enabled&&it->second->spellId==SpellId;
}
inline bool Creating(Creature* c)
{return c&&Known(c)&&c->CustomData.GetDefault<State>(Key)->creating;}
inline void Clear(Creature* c)
{
 if(!c)return;auto* s=c->CustomData.GetDefault<State>(Key);auto ids=s->wards;
 s->wards.clear();s->recruiter=0;s->creating=false;
 if(c->IsInWorld())for(auto guid:ids)if(Creature* ward=ObjectAccessor::GetCreature(*c,guid))
  if(ward->GetEntry()==WDN1C::Entry&&ward->GetOwnerGUID()==c->GetGUID())ward->DespawnOrUnsummon();
}
inline uint32 Active(Creature* c)
{
 if(!c||!c->IsInWorld())return 0;auto* s=c->CustomData.GetDefault<State>(Key);
 if(s->wards.empty())return 0;
 if(!Known(c)||!c->GetBotAI()->HasRole(NPC_BOT_ROLE_DPS)||s->recruiter!=c->GetBotAI()->GetBotOwnerGuid())
 {Clear(c);return 0;}
 std::vector<ObjectGuid> alive;
 for(auto guid:s->wards)
 {
  Creature* ward=ObjectAccessor::GetCreature(*c,guid);
  if(!ward||ward->GetEntry()!=WDN1C::Entry||ward->GetOwnerGUID()!=c->GetGUID())continue;
  if(ward->IsAlive()&&c->IsInMap(ward)&&c->InSamePhase(ward)&&c->IsWithinDistInMap(ward,45.f))alive.push_back(guid);
  else ward->DespawnOrUnsummon();
 }
 s->wards=alive;return uint32(alive.size());
}
inline bool Owned(Creature* c,Creature* ward)
{
 if(!Active(c)||!ward)return false;auto* s=c->CustomData.GetDefault<State>(Key);
 return std::find(s->wards.begin(),s->wards.end(),ward->GetGUID())!=s->wards.end();
}
inline bool Summon(Creature* c)
{
 if(!Known(c)||!c->GetBotAI()->HasRole(NPC_BOT_ROLE_DPS)||
    c->GetBotAI()->HasBotCommandState(BOT_COMMAND_FULLSTOP|BOT_COMMAND_INACTION)||Active(c))return false;
 Unit* target=c->GetVictim();
 if(!target||!c->IsInCombatWith(target)||!WDN1::Safe(c,target))return false;
 auto* s=c->CustomData.GetDefault<State>(Key);std::vector<ObjectGuid> fresh;s->creating=true;
 for(uint32 i=0;i<Count;++i)
 {
  Position pos=c->GetPosition();c->MovePositionToFirstCollision(pos,2.5f,float(i)*6.2831853f/float(Count));
  if(TempSummon* ward=c->SummonCreature(WDN1C::Entry,pos,TEMPSUMMON_TIMED_DESPAWN,Lifetime))fresh.push_back(ward->GetGUID());
 }
 s->creating=false;
 if(fresh.empty())return false;
 s->wards=fresh;s->recruiter=c->GetBotAI()->GetBotOwnerGuid();return true;
}
inline void Update(Creature* ward,ObjectGuid owner,float& timer,uint32 diff)
{
 Creature* c=ObjectAccessor::GetCreature(*ward,owner);
 if(!c||!Owned(c,ward)){ward->DespawnOrUnsummon();return;}
 ward->SetFaction(c->GetFaction());ward->SetByteValue(UNIT_FIELD_BYTES_2,1,c->GetByteValue(UNIT_FIELD_BYTES_2,1));
 if(timer>float(diff)){timer-=float(diff);return;}timer=2000.f;
 Unit* target=c->GetVictim();if(!WDN1C::Target(c,ward,target))return;
 ward->SetFacingToObject(target);ward->CastSpell(target,WDN1C::Attack,true,nullptr,nullptr,c->GetGUID());
}
}
#endif
