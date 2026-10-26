// WDN3A: NPC-only defensive decisions and bounded combat recovery.
#pragma once
#include "RebornWitchDoctorNpcIdol2.h"
#include "MotionMaster.h"
namespace WDN3A
{
constexpr uint32 Death=9003853,Slither=9003859,Mirage=9004110;
inline bool Defensive(uint32 id){return id==Death||id==Slither||id==Mirage;}
inline bool Known(Creature*c,uint32 id)
{
 if(!WDN1::Actor(c)||!Defensive(id))return false;
 auto*info=sSpellMgr->GetSpellInfo(id);auto const&spells=c->GetBotAI()->GetSpellMap();auto it=spells.find(id);
 return info&&c->GetLevel()>=info->SpellLevel&&it!=spells.end()&&it->second&&it->second->enabled&&it->second->spellId==id;
}
inline bool Allowed(Creature*c)
{
 return WDN1::Actor(c)&&!c->GetBotAI()->HasBotCommandState(BOT_COMMAND_FULLSTOP|BOT_COMMAND_INACTION)&&
  !c->GetBotAI()->HasRole(NPC_BOT_ROLE_TANK)&&!c->GetBotAI()->HasRole(NPC_BOT_ROLE_TANK_OFF)&&
  (c->GetBotAI()->HasRole(NPC_BOT_ROLE_DPS)||c->GetBotAI()->HasRole(NPC_BOT_ROLE_HEAL));
}
struct State
{
 uint32 spell=0,elapsed=0,owner=0,map=0,phase=0;
 float initialHealth=100.f;
 void Clear(Creature*c)
 {
  uint32 old=spell;spell=elapsed=owner=map=phase=0;
  if(old&&c)c->RemoveAurasDueToSpell(old,c->GetGUID());
 }
 void Begin(Creature*c,uint32 id)
 {
  if(!Defensive(id)||!Known(c,id))return;
  initialHealth=c->GetHealthPct();spell=id;elapsed=0;owner=c->GetBotAI()->GetBotOwnerGuid();map=c->GetMapId();phase=c->GetPhaseMask();
  c->AttackStop();c->InterruptSpell(CURRENT_AUTOREPEAT_SPELL);
  if(c->isMoving())c->BotStopMovement();
  if(id==Slither&&!c->GetBotAI()->HasBotCommandState(BOT_COMMAND_STAY))
  {
   Player*leader=c->GetBotAI()->GetBotOwner();
   if(leader&&leader->GetGUID().GetCounter()==owner&&WDN2D::Eligible(c,c,leader,false))
    c->GetMotionMaster()->MoveFollow(leader,3.f,3.1415926f);
  }
 }
 bool Hold(Creature*c,uint32 diff)
 {
  if(!c)return false;
  if(spell)
  {
   elapsed+=std::min(diff,60000u);
   bool invalid=!Allowed(c)||!Known(c,spell)||owner!=c->GetBotAI()->GetBotOwnerGuid()||map!=c->GetMapId()||phase!=c->GetPhaseMask();
   bool resume=spell!=Slither&&((elapsed>=500u&&c->GetHealthPct()+1.f<initialHealth)||c->isMoving()||elapsed>=(spell==Death?6000u:8000u)||(elapsed>=2000u&&c->GetHealthPct()>=65.f));
   if(invalid||resume||!c->HasAura(spell,c->GetGUID()))Clear(c);
  }
  // Respect manually applied defensive auras as well. Only this AI's own hold is cancelled above.
  if(!WDN1::Actor(c))return false;
  if(spell==Slither&&c->GetBotAI()->HasBotCommandState(BOT_COMMAND_STAY)&&c->isMoving())c->BotStopMovement();
  for(uint32 id:{Death,Slither,Mirage})if(c->HasAura(id,c->GetGUID()))
  {c->AttackStop();c->InterruptSpell(CURRENT_AUTOREPEAT_SPELL);return true;}
  return false;
 }
};
// Keep policy separate from engine casts: no free triggered active spell, no cached enemy.
template<class Can> uint32 Choose(Creature*c,Can can,bool recentHostileDamage=false)
{
 if(!Allowed(c)||!c->IsInCombat()||c->GetHealthPct()>40.f)return 0;
 bool attacked=recentHostileDamage;
 for(Unit*u:c->getAttackers())if(u&&u->IsAlive()&&u->IsInWorld()&&c->IsInMap(u)&&c->InSamePhase(u)&&u->GetVictim()==c){attacked=true;break;}
 if(!attacked)return 0;
 // A healer/owner observing from outside combat must not disable the victim's escape.
 if(c->GetHealthPct()<=25.f&&can(Death))return Death;
 if(can(Slither))return Slither;
 if(can(Mirage))return Mirage;
 if(can(Death))return Death;
 return 0;
}
}
