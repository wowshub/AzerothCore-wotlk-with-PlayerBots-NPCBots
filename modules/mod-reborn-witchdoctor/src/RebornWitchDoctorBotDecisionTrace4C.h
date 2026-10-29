#pragma once
#include "DataMap.h"
#include "Player.h"
#include "RebornWitchDoctorBotState168.h"
#include "RebornWitchDoctorBotControls3.h"
#include "RebornWitchDoctorBotAutoSummon4B.h"
#include "SpellMgr.h"
#include "SpellInfo.h"
#include "CharmInfo.h"
#include <chrono>
#include <string>
#include <algorithm>
namespace WDWHY4
{
using Clock=std::chrono::steady_clock;
inline constexpr char Key[]="Reborn.MBWD4C.DecisionTrace";
constexpr uint32 WindowMillis(bool armed,int64 elapsed)
{return armed&&elapsed>=0&&elapsed<30000?uint32(30000-elapsed):0;}
inline uint32 Age(Clock::time_point time,Clock::time_point now)
{auto n=std::chrono::duration_cast<std::chrono::milliseconds>(now-time).count();return uint32(std::clamp<int64>(n,0,4294967295ll));}
struct Snapshot
{
    bool observed=false,planAvailable=false,damage=false,reposition=false,combat=false,moving=false,casting=false;
    uint32 samples=0,spec=3,slot=0,revision=0,hp=0,mana=0,maxMana=0,basicMask=3,summonMask=3,spell=0;
    uint32 attemptSpell=0,attemptResult=0,cost=0,cooldown=0,gcd=0;
    bool infoKnown=false;
    std::string phase="none",reason="none",planReason="not_observed",target;
    Clock::time_point sampled{},attempted{};
};
struct State:DataMap::Base{bool armed=false;Clock::time_point started{};Snapshot value;};
inline uint32 Remaining(State const* state,Clock::time_point now)
{return state?WindowMillis(state->armed,std::chrono::duration_cast<std::chrono::milliseconds>(now-state->started).count()):0;}
inline std::string Text(std::string_view value)
{
    std::string out=value.size()<=64?std::string(value):"(long name)";
    for(char& c:out)if(c=='|'||c=='\n'||c=='\r')c=' ';
    return out;
}
inline void Control(Player* p,uint32 mode)
{
    if(!p)return;
    if(mode==1){auto* s=p->CustomData.GetDefault<State>(Key);s->armed=true;s->started=Clock::now();s->value={};}
    else if(mode==2)if(auto* s=p->CustomData.Get<State>(Key))s->armed=false;
}
inline void Record(Player* p,std::string_view phase,uint32 spell,std::string_view reason,Unit* target,bool damage,bool reposition)
{
    if(!p)return;
    auto* s=p->CustomData.Get<State>(Key);if(!s||!s->armed)return;
    auto now=Clock::now();if(!Remaining(s,now)){s->armed=false;return;}
    if(s->value.observed&&Age(s->value.sampled,now)<250&&s->value.spell==spell&&s->value.reason==reason)return;
    auto& v=s->value;auto plan=WD168::ReadPlan(p);
    v.observed=true;v.sampled=now;++v.samples;v.phase=Text(phase);v.reason=Text(reason);v.spell=spell;
    v.planAvailable=plan.available;v.planReason=Text(plan.reason);v.spec=plan.spec;v.slot=plan.slot;v.revision=plan.revision;
    v.hp=uint32(std::clamp(p->GetHealthPct(),0.f,100.f));v.mana=p->GetPower(POWER_MANA);v.maxMana=p->GetMaxPower(POWER_MANA);
    v.combat=p->IsInCombat();v.moving=p->isMoving();v.casting=p->IsNonMeleeSpellCast(false,false,true);
    v.basicMask=WDMB3::Read(p).mask;v.summonMask=WDAS4::Read(p).mask;
    v.damage=damage;v.reposition=reposition;v.target=target?Text(target->GetName()):"";
    v.infoKnown=false;v.cost=0;v.cooldown=0;v.gcd=0;
    if(auto* info=spell?sSpellMgr->GetSpellInfo(spell):nullptr)
    {v.infoKnown=true;v.cost=uint32(std::max(0,info->CalcPowerCost(p,info->GetSchoolMask())));v.cooldown=p->GetSpellCooldownDelay(spell);v.gcd=p->GetGlobalCooldownMgr().GetGlobalCooldown(info);}
}
inline void Attempt(Player* p,uint32 spell,bool accepted)
{
    if(!p)return;
    auto* s=p->CustomData.Get<State>(Key);if(!s||!s->armed)return;
    auto now=Clock::now();if(!Remaining(s,now)){s->armed=false;return;}
    s->value.attemptSpell=spell;s->value.attemptResult=accepted?1:2;s->value.attempted=now;
}
}
