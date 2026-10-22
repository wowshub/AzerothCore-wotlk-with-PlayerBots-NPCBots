// WD168A: inspect only. No lazy enrollment query, cast, save, learn or reset.
#include "CharmInfo.h"
namespace WD168
{
LearnedSpell ReadSpell(Player* p,uint32 base)
{
 LearnedSpell out;out.base=base;
 // Highest actually learned rank, not a hypothetical level-unlocked rank.
 if(base==9004000 || base==9004030)
 {for(uint32 i=0;i<7;++i)if(p->HasSpell(base+i))out.learned=base+i;}
 else if(auto* family=WD19A::FindFamily(base))
 {
  for(std::size_t i=family->count;i>0;--i)
   if(p->HasSpell(family->ranks[i-1].spell)){out.learned=family->ranks[i-1].spell;break;}
 }
 else if(p->HasSpell(base))out.learned=base;
 if(!out.learned)return out;
 // Core returns the original learned ID when no temporary override exists.
 uint32 resolved=p->GetTemporarySpellReplacement(out.learned);
 out.replacement=resolved!=out.learned?resolved:0;
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
 // Observe all three existing owner slots without creating state or changing selections.
 ObjectGuid ids[3]={};
 if(auto* st=p->CustomData.Get<WD21A::State>(WD21A::Key))ids[0]=st->guid;
 if(auto* st=p->CustomData.Get<WD36A::State>(WD36A::Key))ids[1]=st->guid;
 if(auto* st=p->CustomData.Get<WD41A::State>(WD41A::Key))ids[2]=st->guid;
 auto* selection=p->CustomData.Get<WD53A::State>(WD53A::Key);
 for(uint32 i=0;i<3;++i)
 {
  if(selection && WD53A::Slot(selection->selected[i])==int(i) && p->HasSpell(selection->selected[i]))
   out.summons[i].selected=selection->selected[i];
  if(auto* u=ObjectAccessor::GetCreature(*p,ids[i]))
   if(u->IsAlive()&&u->IsInWorld()&&(WD53A::Entry(i,u->GetEntry())||(i==1&&u->GetEntry()==900232))&&u->GetOwnerGUID()==p->GetGUID()&&p->IsInMap(u)&&p->InSamePhase(u))
   {out.summons[i].present=true;out.summons[i].entry=u->GetEntry();}
 }
 out.serpentPresent=out.summons[0].present; // Includes healing/mimic wards; never overwrite an occupied slot.
 if(auto* mass=p->CustomData.Get<WD150::State>(WD150::Key))
  for(auto guid:mass->wards)if(auto* u=ObjectAccessor::GetCreature(*p,guid))
   if(u->IsAlive()&&u->IsInWorld()&&u->GetEntry()==900190&&u->GetOwnerGUID()==p->GetGUID()&&p->IsInMap(u)&&p->InSamePhase(u))++out.massWards;
 // Independent Mimics do not occupy the ordinary Ward slot. Observe, never create state.
 if(auto* mimic=p->CustomData.Get<WD68A::State>(WD68A::Key))
  for(auto guid:{mimic->mimic,mimic->extra,mimic->mojo})
   if(auto* u=ObjectAccessor::GetCreature(*p,guid))
    if(u->IsAlive()&&u->IsInWorld()&&u->GetEntry()==WD68A::MimicEntry&&u->GetOwnerGUID()==p->GetGUID()&&p->IsInMap(u)&&p->InSamePhase(u))out.mimicPresent=true;
 out.souls=WD87A::Count(p); // Only aura 9003574 from this player's own GUID, capped at five.
 uint32 bases[]={9003100,9003101,9003104,9003160,9003260,9003970,9003980,9004000,9004030,9003541,9003270};
 for(std::size_t i=0;i<out.spells.size();++i)out.spells[i]=ReadSpell(p,bases[i]);
 return out;
}
}
