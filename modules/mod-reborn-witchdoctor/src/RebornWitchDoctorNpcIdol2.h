// WDN2D: independent NPC Spirit Idol; native percent-mana pulse.
#ifndef REBORN_WD_NPC_IDOL_2_H
#define REBORN_WD_NPC_IDOL_2_H
#include "RebornWitchDoctorNpcActor1.h"
#include "CellImpl.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
namespace WDN2D
{
constexpr uint32 SpellId=9003370,Entry=900192,Mana=9003371;
constexpr uint32 Swift=9003432,SwiftEntry=900202,SwiftField=9003433;
constexpr uint32 Serene=9003390,SereneEntry=900195,SereneField=9003391;
inline uint32 EntryFor(uint32 id){return id==Swift?SwiftEntry:id==Serene?SereneEntry:Entry;}
inline uint32 FieldFor(uint32 id){return id==Serene?SereneField:SwiftField;}
inline uint32 Lifetime(uint32 id){return id==Swift?10000:id==Serene?60000:15000;}
constexpr char Key[]="RebornWD.NpcIdol2";
struct State:DataMap::Base{ObjectGuid guid;uint32 recruiter=0,spell=SpellId;std::vector<ObjectGuid> affected;};
inline bool Known(Creature*c,uint32 id=SpellId)
{
 if(!WDN1::Actor(c)||(id!=SpellId&&id!=Swift&&id!=Serene))return false;auto*info=sSpellMgr->GetSpellInfo(id);
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
 if(!c)return;RemoveFields(c);auto*s=c->CustomData.GetDefault<State>(Key);auto old=s->guid;s->guid.Clear();s->recruiter=0;
 if(c->IsInWorld()&&!old.IsEmpty())if(auto*idol=ObjectAccessor::GetCreature(*c,old))
  if((idol->GetEntry()==Entry||idol->GetEntry()==SwiftEntry||idol->GetEntry()==SereneEntry)&&idol->GetOwnerGUID()==c->GetGUID())idol->DespawnOrUnsummon();
}
inline Creature*Current(Creature*c)
{
 if(!c||!c->IsInWorld())return nullptr;auto*s=c->CustomData.GetDefault<State>(Key);if(s->guid.IsEmpty())return nullptr;
 auto*idol=ObjectAccessor::GetCreature(*c,s->guid);
 if(Known(c,s->spell)&&s->recruiter==c->GetBotAI()->GetBotOwnerGuid()&&idol&&idol->IsAlive()&&idol->GetEntry()==EntryFor(s->spell)&&
    idol->GetOwnerGUID()==c->GetGUID()&&c->IsInMap(idol)&&c->InSamePhase(idol)&&c->IsWithinDistInMap(idol,45.f))return idol;
 Clear(c);return nullptr;
}
inline bool Eligible(Creature*c,Creature*origin,Unit*t,bool manaOnly=true)
{
 if(!WDN1::Actor(c)||!origin||!t||!t->IsAlive()||!t->IsInWorld()||(manaOnly&&(t->getPowerType()!=POWER_MANA||!t->GetMaxPower(POWER_MANA)))||
    !c->IsInMap(t)||!origin->InSamePhase(t)||!c->IsFriendlyTo(t)||!origin->IsWithinDistInMap(t,30.f)||!origin->IsWithinLOSInMap(t))return false;
 return t==c||((t->GetTypeId()==TYPEID_PLAYER||t->IsNPCBot())&&c->GetBotAI()->IsInBotParty(t));
}
inline std::list<Unit*> Nearby(Creature*origin)
{
 std::list<Unit*> units;Acore::AnyUnitInObjectRangeCheck check(origin,30.f);
 Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(origin,units,check);Cell::VisitObjects(origin,search,30.f);return units;
}
inline bool Needed(Creature*c)
{
 if(!Known(c)||Current(c)||c->GetBotAI()->HasBotCommandState(BOT_COMMAND_FULLSTOP|BOT_COMMAND_INACTION))return false;
 for(Unit*t:Nearby(c))if(Eligible(c,c,t)&&uint64(t->GetPower(POWER_MANA))*100<uint64(t->GetMaxPower(POWER_MANA))*50)return true;
 return false;
}
inline bool SwiftNeeded(Creature*c)
{
 if(!Known(c,Swift)||Current(c)||c->GetBotAI()->HasBotCommandState(BOT_COMMAND_FULLSTOP|BOT_COMMAND_INACTION)||Needed(c))return false;
 std::vector<ObjectGuid> moving;
 for(Unit*t:Nearby(c))if(Eligible(c,c,t,false)&&t->IsInCombat()&&t->isMoving()&&!t->HasAuraType(SPELL_AURA_MOD_ROOT)&&!t->HasAura(SwiftField)&&
  std::find(moving.begin(),moving.end(),t->GetGUID())==moving.end())moving.push_back(t->GetGUID());
 return moving.size()>=2;
}
inline bool SereneNeeded(Creature*c)
{
 if(!Known(c,Serene)||Current(c)||c->GetBotAI()->HasBotCommandState(BOT_COMMAND_FULLSTOP|BOT_COMMAND_INACTION)||Needed(c))return false;
 std::vector<ObjectGuid> casters;
 for(Unit*t:Nearby(c))if(Eligible(c,c,t,false)&&t->IsInCombat()&&t->IsNonMeleeSpellCast(false)&&!t->HasAura(SereneField)&&
  std::find(casters.begin(),casters.end(),t->GetGUID())==casters.end())casters.push_back(t->GetGUID());
 return casters.size()>=2;
}
inline bool Summon(Creature*c,uint32 id=SpellId)
{
 if(!Known(c,id)||Current(c)||c->GetBotAI()->HasBotCommandState(BOT_COMMAND_FULLSTOP|BOT_COMMAND_INACTION))return false;
 Position pos=c->GetPosition();c->MovePositionToFirstCollision(pos,1.5f,2.1f);
 TempSummon*idol=c->SummonCreature(EntryFor(id),pos,TEMPSUMMON_TIMED_DESPAWN,Lifetime(id)+1000);if(!idol)return false;
 idol->SetOwnerGUID(c->GetGUID());idol->SetCreatorGUID(c->GetGUID());idol->SetFaction(c->GetFaction());idol->SetLevel(c->GetLevel());
 idol->SetControlledByPlayer(true);idol->SetUnitFlag(UNIT_FLAG_PLAYER_CONTROLLED);idol->SetByteValue(UNIT_FIELD_BYTES_2,1,c->GetByteValue(UNIT_FIELD_BYTES_2,1));
 idol->SetMaxHealth(std::max(5u,uint32(c->GetLevel())*10));idol->SetHealth(idol->GetMaxHealth());
 auto*s=c->CustomData.GetDefault<State>(Key);s->spell=id;s->guid=idol->GetGUID();s->recruiter=c->GetBotAI()->GetBotOwnerGuid();return true;
}
inline void Update(Creature*idol,ObjectGuid owner,uint32&timer,uint32&remaining,uint32 diff)
{
 auto*c=ObjectAccessor::GetCreature(*idol,owner);if(!c||Current(c)!=idol){idol->DespawnOrUnsummon();return;}
 idol->SetFaction(c->GetFaction());idol->SetByteValue(UNIT_FIELD_BYTES_2,1,c->GetByteValue(UNIT_FIELD_BYTES_2,1));
 if(idol->GetEntry()==SwiftEntry||idol->GetEntry()==SereneEntry)
 {
  if(diff>=remaining){Clear(c);return;}remaining-=diff;
  if(c->GetBotAI()->HasBotCommandState(BOT_COMMAND_FULLSTOP|BOT_COMMAND_INACTION)){RemoveFields(c);return;}
  if(timer>diff){timer-=diff;return;}timer=1000;
  auto*s=c->CustomData.GetDefault<State>(Key);std::vector<ObjectGuid> next;
  for(Unit*t:Nearby(idol))if(Eligible(c,idol,t,false)&&std::find(next.begin(),next.end(),t->GetGUID())==next.end())next.push_back(t->GetGUID());
  for(auto guid:s->affected)if(std::find(next.begin(),next.end(),guid)==next.end())if(Unit*t=ObjectAccessor::GetUnit(*idol,guid))t->RemoveAurasDueToSpell(FieldFor(s->spell),c->GetGUID());
  s->affected=next;
  for(auto guid:next)if(Unit*t=ObjectAccessor::GetUnit(*idol,guid))if(Eligible(c,idol,t,false))
  {
   if(Aura*a=t->GetAura(FieldFor(s->spell),c->GetGUID()))a->SetDuration(2200);
   else if(Aura*a=c->AddAura(FieldFor(s->spell),t))a->SetDuration(2200);
  }
  return;
 }
 uint32 step=std::min(diff,remaining);remaining-=step;
 if(timer>step)timer-=step;
 else
 {
  timer=3000; // No catch-up burst after a slow world update.
  if(!c->GetBotAI()->HasBotCommandState(BOT_COMMAND_FULLSTOP|BOT_COMMAND_INACTION))
   for(Unit*t:Nearby(idol))if(Eligible(c,idol,t))idol->CastSpell(t,Mana,true,nullptr,nullptr,c->GetGUID());
 }
 if(!remaining){Clear(c);}
}
}
#endif
