// WDN1A: narrow Creature backend; never use the owner's Player build as authority.
#ifndef REBORN_WD_NPC_ACTOR_1_H
#define REBORN_WD_NPC_ACTOR_1_H
#include "Creature.h"
#include "SpellMgr.h"
#include "Player.h"
#include "bot_ai.h"
#include "botcommon.h"
#include "SpellAuraEffects.h"
#include "RebornWitchDoctorRanks.h"
namespace WDN1
{
constexpr uint32 Entry=900260,Spirit=9003574,AutoShot=9003989;
constexpr WD19A::Rank EclipseRanks[]={{9004000,15},{9004001,22},{9004002,30},{9004003,38},{9004004,46},{9004005,54},{9004006,60}};
constexpr WD19A::Rank GlaiveRanks[]={{9004030,15},{9004031,20},{9004032,28},{9004033,36},{9004034,44},{9004035,52},{9004036,60}};
inline Creature* Actor(Unit* u)
{
 auto* c=u?u->ToCreature():nullptr;
 return c&&c->IsNPCBot()&&c->GetEntry()==Entry&&c->GetBotClass()==BOT_CLASS_WITCH_DOCTOR&&
  c->GetBotAI()&&c->GetBotAI()->GetBotOwnerGuid()&&c->IsAlive()&&c->IsInWorld()?c:nullptr;
}
inline uint32 Base(uint32 id)
{
 for(auto r:WD19A::WrathRanks)if(r.spell==id)return 9003100;
 for(auto r:WD19A::BrewRanks)if(r.spell==id)return 9003101;
 for(auto r:WD19A::ReclaimRanks)if(r.spell==id)return 9003260;
 for(auto r:WD19A::SpiritRanks)if(r.spell==id)return 9003140;
 for(auto r:WD19A::PowerRanks)if(r.spell==id)return 9003180;
 for(auto r:WD19A::ResourcefulRanks)if(r.spell==id)return 9003190;
 for(auto r:WD19A::GreaterResourcefulRanks)if(r.spell==id)return 9003280;
 for(auto r:WD19A::GreaterSpiritRanks)if(r.spell==id)return 9003290;
 for(auto r:WD19A::GreaterPowerRanks)if(r.spell==id)return 9003300;
 if(id==9003240||id==9003250||id==9003442)return id;
 if(id==AutoShot)return AutoShot;
 if(id>=9004000&&id<=9004006)return 9004000;
 if(id>=9004030&&id<=9004036)return 9004030;
 if(id>=9003970&&id<=9003978)return 9003970;
 if(id>=9003980&&id<=9003988)return 9003980;
 return 0;
}
inline bool Known(Unit* u,uint32 id)
{
 auto* c=Actor(u);uint32 base=Base(id);if(!c||!base)return false;
 if(base==9003100||base==9003101||base==9003260||base==9003240||base==9003250||base==9003442||base==9003140||base==9003180||base==9003190||base==9003280||base==9003290||base==9003300){auto* info=sSpellMgr->GetSpellInfo(id);if(!info||c->GetLevel()<info->SpellLevel)return false;}
 else if(c->GetLevel()<10)return false;
 auto const& spells=c->GetBotAI()->GetSpellMap();auto it=spells.find(base);
 return it!=spells.end()&&it->second&&it->second->enabled&&it->second->spellId==id;
}
inline bool Engaged(Unit* u,Unit* t)
{
 auto* c=Actor(u);
 if(!c||!t||t==c||!t->IsAlive()||!t->IsInWorld()||!c->IsInMap(t)||!c->InSamePhase(t)||
    !c->IsValidAttackTarget(t)||t->HasBreakableByDamageCrowdControlAura()||
    t->HasAuraType(SPELL_AURA_REFLECT_SPELLS)||t->HasAuraType(SPELL_AURA_REFLECT_SPELLS_SCHOOL))return false;
 // Only the native, current, GUID-bound pull order can authorize a first shot.
 // Merely selecting an enemy never authorizes pulling it or neighbouring enemies.
 if(c->GetBotAI()->IsActionNext(NpcBotActionTypes::BOT_ACTION_PULL,0,t->GetGUID()))return true;
 if(c->IsInCombatWith(t))return true;
 Player* engagedOwner=c->GetBotAI()->GetBotOwner();
 if(engagedOwner&&engagedOwner->GetGUID().GetCounter()==c->GetBotAI()->GetBotOwnerGuid()&&
    engagedOwner->IsAlive()&&engagedOwner->IsInWorld()&&c->IsInMap(engagedOwner)&&
    c->InSamePhase(engagedOwner)&&engagedOwner->IsInCombatWith(t))return true;
 Unit* victim=t->GetVictim();if(!victim||!victim->IsAlive()||!victim->IsInCombatWith(t))return false;
 if(victim==c)return true;
 if(victim->GetTypeId()==TYPEID_PLAYER)
 {
  if(victim->GetGUID().GetCounter()==c->GetBotAI()->GetBotOwnerGuid())return true;
  Player* owner=c->GetBotAI()->GetBotOwner();
  // Playerbots are real Players. A tank in the owner's party/raid is an engaged teammate.
  return owner&&owner->GetGUID().GetCounter()==c->GetBotAI()->GetBotOwnerGuid()&&
   owner->IsInWorld()&&c->IsInMap(owner)&&c->InSamePhase(owner)&&owner->IsInRaidWith(victim);
 }
 auto* teammate=victim->ToCreature();
 return teammate&&teammate->IsNPCBot()&&c->GetBotGroup()&&teammate->GetBotGroup()==c->GetBotGroup();
}
// WDN3C: offensive summon callbacks also run while their owner is escaping.
// Read live self-owned auras; no cached target/state and no forced summon removal.
inline bool Escaping(Creature* c)
{
 return c&&(c->HasAura(9003853,c->GetGUID())||c->HasAura(9003859,c->GetGUID())||
  c->HasAura(9004110,c->GetGUID()));
}
inline bool Safe(Unit* u,Unit* t)
{auto* c=Actor(u);return c&&!Escaping(c)&&Engaged(c,t)&&c->IsWithinLOSInMap(t);}
inline uint32 Count(Unit* u)
{auto* a=u?u->GetAura(Spirit,u->GetGUID()):nullptr;return a?std::min<uint32>(5,a->GetStackAmount()):0;}
}
#endif
