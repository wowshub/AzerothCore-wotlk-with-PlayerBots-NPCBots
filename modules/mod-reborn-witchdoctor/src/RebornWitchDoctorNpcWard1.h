// WDN1C1: one owned base Serpent Ward; no Player build or Shaman totem slots.
#ifndef REBORN_WD_NPC_WARD_1_H
#define REBORN_WD_NPC_WARD_1_H
#include "RebornWitchDoctorNpcActor1.h"
#include "RebornWitchDoctorNpcIdol2.h"
#include "ObjectAccessor.h"
#include "SpellMgr.h"
#include "TemporarySummon.h"
namespace WDN1C
{
constexpr uint32 SpellId=9003160, Entry=900190, Attack=9003161;
constexpr uint32 Healing=9003170,HealingEntry=900191,Heal=9003171;
inline uint32 EntryFor(uint32 id){return id==Healing?HealingEntry:Entry;}
constexpr char Key[]="RebornWD.NpcWard1";
struct State : DataMap::Base { ObjectGuid guid; uint32 recruiter=0,spell=SpellId; };
inline bool Known(Creature* c,uint32 id=SpellId)
{
 if(!WDN1::Actor(c)||(id!=SpellId&&id!=Healing))return false;
 auto* info=sSpellMgr->GetSpellInfo(id);
 auto const& spells=c->GetBotAI()->GetSpellMap();auto it=spells.find(id);
 return info&&c->GetLevel()>=info->SpellLevel&&it!=spells.end()&&it->second&&
  it->second->enabled&&it->second->spellId==id;
}
inline void Clear(Creature* c)
{
 if(!c)return;
 auto* state=c->CustomData.GetDefault<State>(Key);
 ObjectGuid old=state->guid;state->guid.Clear();state->recruiter=0;
 if(!old.IsEmpty()&&c->IsInWorld())
  if(Creature* ward=ObjectAccessor::GetCreature(*c,old))
   if((ward->GetEntry()==Entry||ward->GetEntry()==HealingEntry)&&ward->GetOwnerGUID()==c->GetGUID())ward->DespawnOrUnsummon();
}
inline Creature* Current(Creature* c)
{
 if(!c||!c->IsInWorld())return nullptr;
 auto* state=c->CustomData.GetDefault<State>(Key);
 if(state->guid.IsEmpty())return nullptr;
 Creature* ward=ObjectAccessor::GetCreature(*c,state->guid);
 if(Known(c,state->spell)&&(state->spell==Healing||c->GetBotAI()->HasRole(NPC_BOT_ROLE_DPS))&&
    state->recruiter==c->GetBotAI()->GetBotOwnerGuid()&&ward&&ward->IsAlive()&&
    ward->GetEntry()==EntryFor(state->spell)&&ward->GetOwnerGUID()==c->GetGUID()&&
    c->IsInMap(ward)&&c->InSamePhase(ward)&&c->IsWithinDistInMap(ward,45.0f))return ward;
 Clear(c);return nullptr;
}
inline bool Summon(Creature* c,uint32 id=SpellId)
{
 if(!Known(c,id)||(id!=Healing&&!c->GetBotAI()->HasRole(NPC_BOT_ROLE_DPS))||c->GetBotAI()->HasBotCommandState(BOT_COMMAND_FULLSTOP|BOT_COMMAND_INACTION))return false;
 Position pos=c->GetPosition();c->MovePositionToFirstCollision(pos,1.5f,0.0f);
 TempSummon* ward=c->SummonCreature(EntryFor(id),pos,TEMPSUMMON_TIMED_DESPAWN,60000);
 if(!ward)return false; // Failed replacement preserves the old ward.
 Clear(c);
 auto* state=c->CustomData.GetDefault<State>(Key);
 state->spell=id;state->guid=ward->GetGUID();state->recruiter=c->GetBotAI()->GetBotOwnerGuid();
 return true;
}
inline bool Target(Creature* c,Creature* ward,Unit* target)
{
 // A ward is not a pull opener: only attack the NPC's actual combat target.
 return c&&ward&&target&&c->GetVictim()==target&&c->IsInCombatWith(target)&&
  !c->GetBotAI()->HasBotCommandState(BOT_COMMAND_FULLSTOP|BOT_COMMAND_INACTION)&&
  WDN1::Safe(c,target)&&ward->IsInMap(target)&&ward->InSamePhase(target)&&
  ward->IsWithinDistInMap(target,30.0f)&&ward->IsWithinLOSInMap(target);
}
inline bool HealingNeeded(Creature*c)
{
 if(!Known(c,Healing)||c->GetBotAI()->HasBotCommandState(BOT_COMMAND_FULLSTOP|BOT_COMMAND_INACTION))return false;
 Creature*active=Current(c);if(active&&active->GetEntry()==HealingEntry)return false;
 std::vector<ObjectGuid> injured;
 for(Unit*t:WDN2D::Nearby(c))if(WDN2D::Eligible(c,c,t,false)&&t->IsInCombat()&&t->GetHealthPct()<65.f&&
    std::find(injured.begin(),injured.end(),t->GetGUID())==injured.end())
 {
  if(t->GetHealthPct()<40.f)return true;
  injured.push_back(t->GetGUID());
 }
 return !active&&injured.size()>=2;
}
inline void HealAllies(Creature*c,Creature*ward)
{
 if(c->GetBotAI()->HasBotCommandState(BOT_COMMAND_FULLSTOP|BOT_COMMAND_INACTION))return;
 auto units=WDN2D::Nearby(ward);
 units.remove_if([&](Unit*t){return !WDN2D::Eligible(c,ward,t,false)||t->GetHealthPct()>=100.f;});
 units.sort([](Unit*a,Unit*b){return a->GetHealthPct()!=b->GetHealthPct()?a->GetHealthPct()<b->GetHealthPct():a->GetGUID()<b->GetGUID();});
 std::vector<ObjectGuid> recipients;
 for(Unit*t:units)if(std::find(recipients.begin(),recipients.end(),t->GetGUID())==recipients.end())
 {recipients.push_back(t->GetGUID());if(recipients.size()==8)break;}
 ObjectGuid owner=c->GetGUID();
 for(auto guid:recipients)
 {
  c=ObjectAccessor::GetCreature(*ward,owner);
  if(!c||Current(c)!=ward||c->GetBotAI()->HasBotCommandState(BOT_COMMAND_FULLSTOP|BOT_COMMAND_INACTION))return;
  if(Unit*t=ObjectAccessor::GetUnit(*ward,guid))if(WDN2D::Eligible(c,ward,t,false)&&t->GetHealthPct()<100.f)
   ward->CastSpell(t,Heal,true,nullptr,nullptr,owner);
 }
}
inline void Update(Creature* ward,ObjectGuid owner,float& timer,uint32 diff)
{
 Creature* c=ObjectAccessor::GetCreature(*ward,owner);
 if(!c||Current(c)!=ward){ward->DespawnOrUnsummon();return;}
 ward->SetFaction(c->GetFaction());
 ward->SetByteValue(UNIT_FIELD_BYTES_2,1,c->GetByteValue(UNIT_FIELD_BYTES_2,1));
 if(timer>float(diff)){timer-=float(diff);return;}
 timer=ward->GetEntry()==HealingEntry?2500.f:2000.f; // No catch-up burst.
 if(ward->GetEntry()==HealingEntry){HealAllies(c,ward);return;}
 Unit* target=c->GetVictim();
 if(!Target(c,ward,target))return;
 ward->SetFacingToObject(target);
 ward->CastSpell(target,Attack,true,nullptr,nullptr,c->GetGUID());
}
}
#endif
