// WDN1C1: one owned base Serpent Ward; no Player build or Shaman totem slots.
#ifndef REBORN_WD_NPC_WARD_1_H
#define REBORN_WD_NPC_WARD_1_H
#include "RebornWitchDoctorNpcActor1.h"
#include "ObjectAccessor.h"
#include "SpellMgr.h"
#include "TemporarySummon.h"
namespace WDN1C
{
constexpr uint32 SpellId=9003160, Entry=900190, Attack=9003161;
constexpr char Key[]="RebornWD.NpcWard1";
struct State : DataMap::Base { ObjectGuid guid; uint32 recruiter=0; };
inline bool Known(Creature* c)
{
 if(!WDN1::Actor(c))return false;
 auto* info=sSpellMgr->GetSpellInfo(SpellId);
 auto const& spells=c->GetBotAI()->GetSpellMap();auto it=spells.find(SpellId);
 return info&&c->GetLevel()>=info->SpellLevel&&it!=spells.end()&&it->second&&
  it->second->enabled&&it->second->spellId==SpellId;
}
inline void Clear(Creature* c)
{
 if(!c)return;
 auto* state=c->CustomData.GetDefault<State>(Key);
 ObjectGuid old=state->guid;state->guid.Clear();state->recruiter=0;
 if(!old.IsEmpty()&&c->IsInWorld())
  if(Creature* ward=ObjectAccessor::GetCreature(*c,old))
   if(ward->GetEntry()==Entry&&ward->GetOwnerGUID()==c->GetGUID())ward->DespawnOrUnsummon();
}
inline Creature* Current(Creature* c)
{
 if(!c||!c->IsInWorld())return nullptr;
 auto* state=c->CustomData.GetDefault<State>(Key);
 if(state->guid.IsEmpty())return nullptr;
 Creature* ward=ObjectAccessor::GetCreature(*c,state->guid);
 if(Known(c)&&c->GetBotAI()->HasRole(NPC_BOT_ROLE_DPS)&&
    state->recruiter==c->GetBotAI()->GetBotOwnerGuid()&&ward&&ward->IsAlive()&&
    ward->GetEntry()==Entry&&ward->GetOwnerGUID()==c->GetGUID()&&
    c->IsInMap(ward)&&c->InSamePhase(ward)&&c->IsWithinDistInMap(ward,45.0f))return ward;
 Clear(c);return nullptr;
}
inline bool Summon(Creature* c)
{
 if(!Known(c)||!c->GetBotAI()->HasRole(NPC_BOT_ROLE_DPS))return false;
 Position pos=c->GetPosition();c->MovePositionToFirstCollision(pos,1.5f,0.0f);
 TempSummon* ward=c->SummonCreature(Entry,pos,TEMPSUMMON_TIMED_DESPAWN,60000);
 if(!ward)return false; // Failed replacement preserves the old ward.
 Clear(c);
 auto* state=c->CustomData.GetDefault<State>(Key);
 state->guid=ward->GetGUID();state->recruiter=c->GetBotAI()->GetBotOwnerGuid();
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
inline void Update(Creature* ward,ObjectGuid owner,float& timer,uint32 diff)
{
 Creature* c=ObjectAccessor::GetCreature(*ward,owner);
 if(!c||Current(c)!=ward){ward->DespawnOrUnsummon();return;}
 ward->SetFaction(c->GetFaction());
 ward->SetByteValue(UNIT_FIELD_BYTES_2,1,c->GetByteValue(UNIT_FIELD_BYTES_2,1));
 if(timer>float(diff)){timer-=float(diff);return;}
 timer=2000.0f; // No catch-up burst after a delayed map update.
 Unit* target=c->GetVictim();
 if(!Target(c,ward,target))return;
 ward->SetFacingToObject(target);
 ward->CastSpell(target,Attack,true,nullptr,nullptr,c->GetGUID());
}
}
#endif
