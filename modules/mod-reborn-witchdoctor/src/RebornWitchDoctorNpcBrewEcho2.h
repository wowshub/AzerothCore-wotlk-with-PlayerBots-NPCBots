// WDN2Y: per-NPC Loa's Brew target history; never borrow a player's build state.
#pragma once
#include "RebornWitchDoctorNpcBrewing2.h"
#include "DataMap.h"
#include "ObjectAccessor.h"
namespace WDN2Y
{
constexpr uint32 Echo=9003102;
constexpr char Key[]="RebornWD.NpcBrewEcho2";
struct State:DataMap::Base
{
    ObjectGuid previous;
    uint32 owner=0,map=0,phase=0;
};
inline void Clear(Creature* c)
{
    if(!c)return;
    auto* s=c->CustomData.GetDefault<State>(Key);
    s->previous.Clear();s->owner=s->map=s->phase=0;
}
inline bool Enabled(Creature* c)
{
    if(!WDN2P::Active(c)||!c->GetBotAI()->HasRole(NPC_BOT_ROLE_HEAL))return false;
    auto const& spells=c->GetBotAI()->GetSpellMap();auto it=spells.find(9003101);
    return it!=spells.end()&&it->second&&WDN1::Known(c,it->second->spellId);
}
inline void Maintain(Creature* c)
{
    if(!c)return;
    auto* s=c->CustomData.GetDefault<State>(Key);
    if(!Enabled(c)){Clear(c);return;}
    uint32 owner=c->GetBotAI()->GetBotOwnerGuid();
    if(s->owner!=owner||s->map!=c->GetMapId()||s->phase!=c->GetPhaseMask())s->previous.Clear();
    s->owner=owner;s->map=c->GetMapId();s->phase=c->GetPhaseMask();
}
inline void AfterHeal(Creature* c,Unit* target,int32 effective)
{
    Maintain(c);
    if(!Enabled(c)||!WDN2P::Eligible(c,target))return;
    auto* s=c->CustomData.GetDefault<State>(Key);
    if(s->previous==target->GetGUID())return;
    ObjectGuid previous=s->previous;
    // A successful fully overhealed cast still becomes the next previous target.
    // Store before the triggered heal so nested calls cannot replay this pair.
    s->previous=target->GetGUID();
    int32 amount=std::max(0,effective)/2;
    if(!amount||previous.IsEmpty())return;
    Unit* ally=ObjectAccessor::GetUnit(*c,previous);
    if(!WDN2P::Eligible(c,ally))return;
    c->CastCustomSpell(ally,Echo,&amount,nullptr,nullptr,true);
}
}
