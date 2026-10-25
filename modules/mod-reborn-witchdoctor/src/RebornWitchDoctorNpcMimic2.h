// WDN2C: one NPC-owned Mimic; baseline Arrow/Reclamation copies only.
#ifndef REBORN_WD_NPC_MIMIC_2_H
#define REBORN_WD_NPC_MIMIC_2_H
#include "RebornWitchDoctorNpcWard1.h"
namespace WDN2C
{
constexpr uint32 SpellId=9003673,Entry=900213,Presence=9004140;
constexpr char Key[]="RebornWD.NpcMimic2";
struct State:DataMap::Base {ObjectGuid guid;uint32 recruiter=0;};
inline bool Known(Creature*c)
{
 if(!WDN1::Actor(c))return false;auto* info=sSpellMgr->GetSpellInfo(SpellId);
 auto const& spells=c->GetBotAI()->GetSpellMap();auto it=spells.find(SpellId);
 return info&&c->GetLevel()>=info->SpellLevel&&it!=spells.end()&&it->second&&it->second->enabled&&it->second->spellId==SpellId;
}
inline void Clear(Creature*c)
{
 if(!c)return;auto*s=c->CustomData.GetDefault<State>(Key);auto old=s->guid;s->guid.Clear();s->recruiter=0;
 c->RemoveAurasDueToSpell(Presence,c->GetGUID());
 if(!old.IsEmpty()&&c->IsInWorld())if(Creature* ward=ObjectAccessor::GetCreature(*c,old))
  if(ward->GetEntry()==Entry&&ward->GetOwnerGUID()==c->GetGUID())ward->DespawnOrUnsummon();
}
inline Creature* Current(Creature*c)
{
 if(!c||!c->IsInWorld())return nullptr;auto*s=c->CustomData.GetDefault<State>(Key);if(s->guid.IsEmpty())return nullptr;
 Creature* ward=ObjectAccessor::GetCreature(*c,s->guid);
 if(Known(c)&&c->GetBotAI()->HasRole(NPC_BOT_ROLE_DPS)&&s->recruiter==c->GetBotAI()->GetBotOwnerGuid()&&
    ward&&ward->IsAlive()&&ward->GetEntry()==Entry&&ward->GetOwnerGUID()==c->GetGUID()&&
    c->IsInMap(ward)&&c->InSamePhase(ward)&&c->IsWithinDistInMap(ward,45.f))return ward;
 Clear(c);return nullptr;
}
inline bool Summon(Creature*c)
{
 if(!Known(c)||!c->GetBotAI()->HasRole(NPC_BOT_ROLE_DPS)||Current(c)||
    c->GetBotAI()->HasBotCommandState(BOT_COMMAND_FULLSTOP|BOT_COMMAND_INACTION))return false;
 auto* info=sSpellMgr->GetSpellInfo(SpellId);int32 duration=info->GetDuration();if(duration<=0)return false;
 Position pos=c->GetPosition();c->MovePositionToFirstCollision(pos,2.f,0.f);
 TempSummon* ward=c->SummonCreature(Entry,pos,TEMPSUMMON_TIMED_DESPAWN,uint32(duration));if(!ward)return false;
 ward->SetOwnerGUID(c->GetGUID());ward->SetCreatorGUID(c->GetGUID());ward->SetFaction(c->GetFaction());ward->SetLevel(c->GetLevel());
 ward->SetControlledByPlayer(true);ward->SetUnitFlag(UNIT_FLAG_PLAYER_CONTROLLED);
 ward->SetByteValue(UNIT_FIELD_BYTES_2,1,c->GetByteValue(UNIT_FIELD_BYTES_2,1));
 ward->SetMaxHealth(std::max(5u,uint32(c->GetLevel())*10));ward->SetHealth(ward->GetMaxHealth());
 auto*s=c->CustomData.GetDefault<State>(Key);s->guid=ward->GetGUID();s->recruiter=c->GetBotAI()->GetBotOwnerGuid();
 if(Aura* aura=c->AddAura(Presence,c)){aura->SetMaxDuration(duration);aura->SetDuration(duration);}
 return true;
}
inline bool Copyable(uint32 id){for(auto r:WD19A::WrathRanks)if(r.spell==id)return true;return (id>=9003970&&id<=9003978)||(id>=9003980&&id<=9003988);}
inline Creature* Source(Unit* caster,Unit* target,uint32 id)
{
 if(!Copyable(id))return nullptr;
 Creature*c=WDN1::Actor(caster);Creature* ward=nullptr;
 if(!c)
 {
  ward=caster?caster->ToCreature():nullptr;if(!ward||ward->GetEntry()!=Entry)return nullptr;
  c=ObjectAccessor::GetCreature(*ward,ward->GetOwnerGUID());
  if(!c||Current(c)!=ward||!target||!ward->IsInMap(target)||!ward->InSamePhase(target)||
     !ward->IsWithinDistInMap(target,40.f)||!ward->IsWithinLOSInMap(target))return nullptr;
 }
 return WDN1::Known(c,id)&&WDN1::Safe(c,target)&&c->GetBotAI()->HasRole(NPC_BOT_ROLE_DPS)&&
  !c->GetBotAI()->HasBotCommandState(BOT_COMMAND_FULLSTOP|BOT_COMMAND_INACTION)?c:nullptr;
}
inline void Mirror(Unit* caster,Unit* target,uint32 id)
{
 Creature*c=WDN1::Actor(caster);if(!c||Source(c,target,id)!=c)return;
 Creature* ward=Current(c);if(!ward||Source(ward,target,id)!=c)return;
 ward->SetFloatValue(UNIT_FIELD_MINRANGEDDAMAGE,c->GetFloatValue(UNIT_FIELD_MINRANGEDDAMAGE));
 ward->SetFloatValue(UNIT_FIELD_MAXRANGEDDAMAGE,c->GetFloatValue(UNIT_FIELD_MAXRANGEDDAMAGE));
 ward->SetFacingToObject(target);ward->CastSpell(target,id,true,nullptr,nullptr,c->GetGUID());
}
inline bool Alive(Creature*ward)
{
 if(!ward)return false;Creature*c=ObjectAccessor::GetCreature(*ward,ward->GetOwnerGUID());
 if(!c||Current(c)!=ward)return false;
 ward->SetFaction(c->GetFaction());ward->SetByteValue(UNIT_FIELD_BYTES_2,1,c->GetByteValue(UNIT_FIELD_BYTES_2,1));return true;
}
}
#endif
