// WDN2E: independent NPC Shadow Effigy; native visible slow aura.
#ifndef REBORN_WD_NPC_EFFIGY_2_H
#define REBORN_WD_NPC_EFFIGY_2_H
#include "RebornWitchDoctorNpcIdol2.h"
#include "CellImpl.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
namespace WDN2E
{
constexpr uint32 SpellId=9003410,Entry=900197,Field=9003411;
constexpr uint32 Hex=9003420,HexEntry=900198,HexField=9003421;
constexpr uint32 Graven=9003422,GravenEntry=900199,GravenField=9003423;
constexpr uint32 Cursed=9003430,CursedEntry=900201,CursedField=9003431;
inline uint32 Lifetime(uint32 id){return id==Cursed?15000:60000;}
inline uint32 EntryFor(uint32 id){return id==Cursed?CursedEntry:id==Hex?HexEntry:id==Graven?GravenEntry:Entry;}
inline uint32 FieldFor(uint32 id){return id==Cursed?CursedField:id==Graven?GravenField:Field;}
constexpr char Key[]="RebornWD.NpcEffigy2";
struct State:DataMap::Base{ObjectGuid guid,pending;uint32 spell=SpellId,recruiter=0;std::vector<ObjectGuid> affected;};
inline bool Known(Creature*c,uint32 id=SpellId)
{
 if(!WDN1::Actor(c)||(id!=SpellId&&id!=Hex&&id!=Graven&&id!=Cursed))return false;auto*info=sSpellMgr->GetSpellInfo(id);
 auto const& spells=c->GetBotAI()->GetSpellMap();auto it=spells.find(id);
 return info&&c->GetLevel()>=info->SpellLevel&&it!=spells.end()&&it->second&&it->second->enabled&&it->second->spellId==id;
}
inline void RemoveFields(Creature*c)
{
 if(!c)return;auto*s=c->CustomData.GetDefault<State>(Key);
 if(c->IsInWorld())for(auto guid:s->affected)if(Unit*t=ObjectAccessor::GetUnit(*c,guid))t->RemoveAurasDueToSpell(FieldFor(s->spell),c->GetGUID());
 s->affected.clear();
}
inline void Clear(Creature*c)
{
 if(!c)return;RemoveFields(c);auto*s=c->CustomData.GetDefault<State>(Key);auto old=s->guid;s->guid.Clear();s->pending.Clear();s->recruiter=0;
 if(c->IsInWorld()&&!old.IsEmpty())if(auto*idol=ObjectAccessor::GetCreature(*c,old))
  if((idol->GetEntry()==Entry||idol->GetEntry()==HexEntry||idol->GetEntry()==GravenEntry||idol->GetEntry()==CursedEntry)&&idol->GetOwnerGUID()==c->GetGUID())idol->DespawnOrUnsummon();
}
inline Creature*Current(Creature*c)
{
 if(!c||!c->IsInWorld())return nullptr;auto*s=c->CustomData.GetDefault<State>(Key);if(s->guid.IsEmpty())return nullptr;
 auto*idol=ObjectAccessor::GetCreature(*c,s->guid);
 if(Known(c,s->spell)&&c->GetBotAI()->HasRole(NPC_BOT_ROLE_DPS)&&s->recruiter==c->GetBotAI()->GetBotOwnerGuid()&&idol&&idol->IsAlive()&&idol->GetEntry()==EntryFor(s->spell)&&
    idol->GetOwnerGUID()==c->GetGUID()&&c->IsInMap(idol)&&c->InSamePhase(idol)&&c->IsWithinDistInMap(idol,45.f))return idol;
 Clear(c);return nullptr;
}
inline bool Eligible(Creature*c,Creature*effigy,Unit*t)
{
 return WDN1::Safe(c,t)&&effigy&&effigy->IsInMap(t)&&effigy->InSamePhase(t)&&effigy->IsWithinDistInMap(t,effigy->GetEntry()==CursedEntry?15.f:30.f)&&effigy->IsWithinLOSInMap(t);
}
inline bool CanPlace(Creature*c,uint32 id)
{
 if(!Known(c,id)||!c->GetBotAI()->HasRole(NPC_BOT_ROLE_DPS)||c->GetBotAI()->HasBotCommandState(BOT_COMMAND_FULLSTOP|BOT_COMMAND_INACTION))return false;
 auto*active=Current(c);return !active||((id==Hex||id==Cursed)&&(active->GetEntry()==Entry||active->GetEntry()==GravenEntry));
}
inline bool ReactionTarget(Creature*c,Unit*t)
{
 return WDN1::Actor(c)&&!WDN1::Escaping(c)&&t&&t->IsAlive()&&t->IsInWorld()&&c->IsInMap(t)&&c->InSamePhase(t)&&c->IsValidAttackTarget(t)&&
  !t->HasBreakableByDamageCrowdControlAura()&&c->IsWithinLOSInMap(t);
}
inline void Queue(Creature*c,Unit*enemy)
{
 if(!Known(c,Hex)||!ReactionTarget(c,enemy)||c->GetBotAI()->HasBotCommandState(BOT_COMMAND_FULLSTOP|BOT_COMMAND_INACTION))return;
 auto*active=Current(c);if(!active||active->GetEntry()!=HexEntry)return;
 auto*s=c->CustomData.GetDefault<State>(Key);if(s->pending.IsEmpty())s->pending=enemy->GetGUID();
}
// Applied once by the shared duration hook, before native caps/diminishing.
inline bool GravenAffects(Creature*c,Unit*t,uint64 mechanics)
{
 if(!Known(c,Graven)||c->GetBotAI()->HasBotCommandState(BOT_COMMAND_FULLSTOP|BOT_COMMAND_INACTION))return false;
 // Read-only here: clearing fields would invalidate the caller's aura iteration.
 auto*s=c->CustomData.GetDefault<State>(Key);
 if(s->spell!=Graven||s->guid.IsEmpty()||s->recruiter!=c->GetBotAI()->GetBotOwnerGuid()||!c->GetBotAI()->HasRole(NPC_BOT_ROLE_DPS))return false;
 Creature*effigy=ObjectAccessor::GetCreature(*c,s->guid);
 if(!effigy||!effigy->IsAlive()||effigy->GetOwnerGUID()!=c->GetGUID()||effigy->GetEntry()!=GravenEntry||
    !c->IsInMap(effigy)||!c->InSamePhase(effigy)||!c->IsWithinDistInMap(effigy,45.f)||!Eligible(c,effigy,t))return false;
 return (mechanics&((1ULL<<MECHANIC_SNARE)|(1ULL<<MECHANIC_DISORIENTED)))||
  ((mechanics&(1ULL<<MECHANIC_ROOT))&&effigy->IsWithinDistInMap(t,15.f));
}
inline bool Summon(Creature*c,uint32 id=SpellId)
{
 if(!CanPlace(c,id))return false;
 Position pos=c->GetPosition();c->MovePositionToFirstCollision(pos,1.5f,4.2f);
 TempSummon*effigy=c->SummonCreature(EntryFor(id),pos,TEMPSUMMON_TIMED_DESPAWN,Lifetime(id)+1000);if(!effigy)return false;
 effigy->SetOwnerGUID(c->GetGUID());effigy->SetCreatorGUID(c->GetGUID());effigy->SetFaction(c->GetFaction());effigy->SetLevel(c->GetLevel());
 effigy->SetControlledByPlayer(true);effigy->SetUnitFlag(UNIT_FLAG_PLAYER_CONTROLLED);effigy->SetByteValue(UNIT_FIELD_BYTES_2,1,c->GetByteValue(UNIT_FIELD_BYTES_2,1));
 effigy->SetMaxHealth(std::max(5u,uint32(c->GetLevel())*10));effigy->SetHealth(effigy->GetMaxHealth());
 Clear(c);
 auto*s=c->CustomData.GetDefault<State>(Key);s->spell=id;s->guid=effigy->GetGUID();s->recruiter=c->GetBotAI()->GetBotOwnerGuid();return true;
}
inline void Update(Creature*effigy,ObjectGuid owner,uint32&timer,uint32&remaining,uint32 diff)
{
 auto*c=ObjectAccessor::GetCreature(*effigy,owner);if(!c||Current(c)!=effigy){effigy->DespawnOrUnsummon();return;}
 if(diff>=remaining){Clear(c);return;}remaining-=diff;
 if(WDN1::Escaping(c)||c->GetBotAI()->HasBotCommandState(BOT_COMMAND_FULLSTOP|BOT_COMMAND_INACTION)){RemoveFields(c);c->CustomData.GetDefault<State>(Key)->pending.Clear();return;}
 if(effigy->GetEntry()==HexEntry)
 {
  auto*s=c->CustomData.GetDefault<State>(Key);if(s->pending.IsEmpty())return;
  auto target=s->pending;s->pending.Clear();
  // Deferred to this update, never interrupt the hostile Spell::cast stack.
  if(Unit*t=ObjectAccessor::GetUnit(*c,target))if(ReactionTarget(c,t))c->CastSpell(t,HexField,true);
  Clear(c);return;
 }
 if(timer>diff){timer-=diff;return;}timer=1000;
 effigy->SetFaction(c->GetFaction());effigy->SetByteValue(UNIT_FIELD_BYTES_2,1,c->GetByteValue(UNIT_FIELD_BYTES_2,1));
 auto*s=c->CustomData.GetDefault<State>(Key);std::vector<ObjectGuid> next;
 for(Unit*t:WDN2D::Nearby(effigy))if(Eligible(c,effigy,t)&&std::find(next.begin(),next.end(),t->GetGUID())==next.end())next.push_back(t->GetGUID());
 for(auto guid:s->affected)if(std::find(next.begin(),next.end(),guid)==next.end())if(Unit*t=ObjectAccessor::GetUnit(*effigy,guid))t->RemoveAurasDueToSpell(FieldFor(s->spell),c->GetGUID());
 s->affected=next;
 for(auto guid:next)if(Unit*t=ObjectAccessor::GetUnit(*effigy,guid))if(Eligible(c,effigy,t))
 {
  if(Aura*a=t->GetAura(FieldFor(s->spell),c->GetGUID()))a->SetDuration(2200);
  else if(Aura*a=c->AddAura(FieldFor(s->spell),t))a->SetDuration(2200);
 }
}
}
#endif
