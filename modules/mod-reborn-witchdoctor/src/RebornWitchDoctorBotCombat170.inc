// WD170A: per-thread native prepare scope; spell scripts retain their own bool after prepare.
namespace WD168
{
namespace { thread_local Player* automaticPlayer=nullptr;thread_local uint32 automaticSpell=0; }
AutomaticCastScope::AutomaticCastScope(Player* p,uint32 spell):previous(automaticPlayer),previousSpell(automaticSpell)
{automaticPlayer=p;automaticSpell=spell;}
AutomaticCastScope::~AutomaticCastScope(){automaticPlayer=previous;automaticSpell=previousSpell;}
bool IsAutomaticCast(Player* p,uint32 spell){return p&&p==automaticPlayer&&spell==automaticSpell;}
bool SafeAutomaticTarget(Player* p,Unit* u)
{
 if(!IsDoctor(p)||!p->IsAlive()||!p->IsInWorld()||!u||!u->IsAlive()||!u->IsInWorld()||!p->IsInMap(u)||!p->InSamePhase(u)||!p->IsValidAttackTarget(u)||!p->IsWithinLOSInMap(u)||u->HasBreakableByDamageCrowdControlAura())return false;
 if(u->GetTypeId()==TYPEID_PLAYER&&p->IsInRaidWith(u))return false;
 if(u->HasAuraType(SPELL_AURA_REFLECT_SPELLS)||u->HasAuraType(SPELL_AURA_REFLECT_SPELLS_SCHOOL))return false;
 if(p->IsInCombatWith(u))return true;
 if(auto* g=p->GetGroup())for(auto* r=g->GetFirstMember();r;r=r->next())
  if(auto* ally=r->GetSource())if(ally->IsAlive()&&ally->IsInWorld()&&p->IsInMap(ally)&&p->InSamePhase(ally)&&ally->IsInCombatWith(u))return true;
 return false;
}
}
