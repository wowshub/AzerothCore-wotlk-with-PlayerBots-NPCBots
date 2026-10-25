// WDN2O: independent NPC Big Bad Voodoo slot; never inherit player talents.
#ifndef REBORN_WD_NPC_VOODOO_2_H
#define REBORN_WD_NPC_VOODOO_2_H
#include "RebornWitchDoctorNpcIdol2.h"
namespace WDN2O
{
constexpr uint32 SpellId=9003580,Entry=900211,Lock=9003583,Immunity=9003581,Protection=9003582;
constexpr char Key[]="RebornWD.NpcVoodoo2";
struct State:DataMap::Base{ObjectGuid guid;uint32 recruiter=0;};
inline bool Known(Unit*u)
{
 auto*c=WDN1::Actor(u);if(!c)return false;auto*info=sSpellMgr->GetSpellInfo(SpellId);
 auto const& spells=c->GetBotAI()->GetSpellMap();auto i=spells.find(SpellId);
 return info&&c->GetLevel()>=info->SpellLevel&&i!=spells.end()&&i->second&&i->second->enabled&&i->second->spellId==SpellId;
}
inline void Clear(Creature*c)
{
 if(!c)return;auto*s=c->CustomData.GetDefault<State>(Key);auto old=s->guid;s->guid.Clear();s->recruiter=0;
 if(c->IsInWorld()&&!old.IsEmpty())if(auto*v=ObjectAccessor::GetCreature(*c,old))
  if(v->GetEntry()==Entry&&v->GetOwnerGUID()==c->GetGUID())
  {if(v->AI())v->AI()->DoAction(56);v->DespawnOrUnsummon();}
 c->RemoveAurasDueToSpell(Immunity,c->GetGUID());
}
inline Creature*Current(Creature*c)
{
 if(!c||!c->IsInWorld())return nullptr;auto*s=c->CustomData.GetDefault<State>(Key);if(s->guid.IsEmpty())return nullptr;
 auto*v=ObjectAccessor::GetCreature(*c,s->guid);
 if(Known(c)&&s->recruiter==c->GetBotAI()->GetBotOwnerGuid()&&v&&v->IsAlive()&&v->GetEntry()==Entry&&v->GetOwnerGUID()==c->GetGUID()&&
    c->IsInMap(v)&&c->InSamePhase(v)&&c->IsWithinDistInMap(v,45.f)&&!c->GetBotAI()->HasBotCommandState(BOT_COMMAND_FULLSTOP|BOT_COMMAND_INACTION))return v;
 Clear(c);return nullptr;
}
inline bool Available(Unit*t){return t&&!t->HasAura(Lock)&&!t->HasAura(Immunity)&&!t->HasAura(Protection);}
inline bool Needed(Creature*c)
{
 if(!Known(c)||!Available(c)||Current(c)||c->GetBotAI()->HasBotCommandState(BOT_COMMAND_FULLSTOP|BOT_COMMAND_INACTION))return false;
 std::vector<ObjectGuid> injured;
 for(Unit*t:WDN2D::Nearby(c))if(WDN2D::Eligible(c,c,t,false)&&c->IsWithinDistInMap(t,15.f)&&Available(t)&&t->IsInCombat()&&t->GetHealthPct()<60.f&&
   std::find(injured.begin(),injured.end(),t->GetGUID())==injured.end())
 {if(t->GetHealthPct()<30.f)return true;injured.push_back(t->GetGUID());}
 return injured.size()>=2;
}
}
#endif
