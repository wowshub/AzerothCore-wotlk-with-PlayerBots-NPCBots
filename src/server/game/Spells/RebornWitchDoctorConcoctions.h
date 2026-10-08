#pragma once
#include "RebornConcoctionsState.h"
#include "Player.h"
#include "SpellAuras.h"
#include "SpellAuraEffects.h"
#include "SpellMgr.h"
#include "ObjectAccessor.h"
namespace RebornConcoctions
{
constexpr uint32 Talent=9003954, Buff=9003955, HealSpell=9003956;
inline bool Doctor(Unit* u)
{
    Player* p=u?u->ToPlayer():nullptr;
    return p && p->getClass()==13 && p->IsAlive() && p->IsInWorld() &&
        p->HasSpell(Talent) && p->HasAura(Talent,p->GetGUID());
}
inline Snapshot Launch(Unit* recipient)
{
    Snapshot result;
    if (!recipient || !recipient->IsAlive()) return result;
    Aura* chosen=nullptr;
    // Multiple doctors cannot turn one offensive cast into multiple leeches.
    // Deterministically consume only one provider (lowest GUID).
    for (auto const& pair:recipient->GetAppliedAuras())
    {
        Aura* aura=pair.second->GetBase();
        if(aura->GetId()!=Buff || !aura->GetCharges() || !Doctor(aura->GetCaster())) continue;
        if(!chosen || aura->GetCasterGUID()<chosen->GetCasterGUID()) chosen=aura;
    }
    if(chosen)
    {
        result.doctor=chosen->GetCasterGUID().GetRawValue();result.percent=5;
        chosen->DropCharge(); // Once at successful launch, before immediate hits.
    }
    return result;
}
inline void Heal(Unit* recipient,Snapshot state,uint32 resolved,uint32 healthBefore)
{
    uint32 amount=HealAmount(resolved,healthBefore,state.percent);
    if(!amount || !recipient || !recipient->IsAlive() || !recipient->IsInWorld()) return;
    Unit* doctor=ObjectAccessor::GetUnit(*recipient,ObjectGuid(state.doctor));
    if(!Doctor(doctor) || !doctor->InSamePhase(recipient) || !doctor->IsFriendlyTo(recipient)) return;
    SpellInfo const* info=sSpellMgr->GetSpellInfo(HealSpell);
    if(!info) return;
    // Resolved damage already includes bonuses/crit/absorb. Do not scale or crit twice.
    HealInfo heal(doctor,recipient,amount,info,info->GetSchoolMask());
    doctor->HealBySpell(heal,false);
}
}
