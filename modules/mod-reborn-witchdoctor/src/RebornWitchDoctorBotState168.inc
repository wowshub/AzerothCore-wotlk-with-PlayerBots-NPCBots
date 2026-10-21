// WD168A: inspect only. No lazy enrollment query, cast, save, learn or reset.
#include "CharmInfo.h"
namespace WD168
{
LearnedSpell ReadSpell(Player* p,uint32 base)
{
 LearnedSpell out;out.base=base;
 // Highest actually learned rank, not a hypothetical level-unlocked rank.
 if(auto* family=WD19A::FindFamily(base))
 {
  for(std::size_t i=family->count;i>0;--i)
   if(p->HasSpell(family->ranks[i-1].spell)){out.learned=family->ranks[i-1].spell;break;}
 }
 else if(p->HasSpell(base))out.learned=base;
 if(!out.learned)return out;
 out.replacement=p->GetTemporarySpellReplacement(out.learned);
 out.cooldownMs=p->GetSpellCooldownDelay(out.learned);
 if(auto* info=sSpellMgr->GetSpellInfo(out.learned))
 {out.infoKnown=true;out.gcdMs=p->GetGlobalCooldownMgr().GetGlobalCooldown(info);}
 return out;
}
Snapshot Capture(Player* p)
{
 Snapshot out;
 if(!IsDoctor(p)){out.plan.reason="not_witchdoctor";return out;}
 out.plan=ReadPlan(p);out.level=p->GetLevel();out.alive=p->IsAlive();
 out.inWorld=p->IsInWorld();out.combat=p->IsInCombat();
 out.mana=p->GetPower(POWER_MANA);out.maxMana=p->GetMaxPower(POWER_MANA);
 if(auto* wardState=p->CustomData.Get<WD21A::State>(WD21A::Key))
  if(auto* ward=ObjectAccessor::GetCreature(*p,wardState->guid))
   out.serpentPresent=ward->IsAlive()&&ward->IsInWorld()&&ward->GetEntry()==900190&&ward->GetOwnerGUID()==p->GetGUID()&&p->IsInMap(ward)&&p->InSamePhase(ward);
 out.souls=WD87A::Count(p); // Only aura 9003574 from this player's own GUID, capped at five.
 uint32 bases[]={9003100,9003101,9003104,9003160,9003260,9003970,9003980};
 for(std::size_t i=0;i<out.spells.size();++i)out.spells[i]=ReadSpell(p,bases[i]);
 return out;
}
}
