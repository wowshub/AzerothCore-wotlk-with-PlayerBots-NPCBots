from wd136_init import *
CORE='src/server/game/'
put(SF+CORE+'Spells/RebornConcoctionsState.h',r'''#pragma once
#include <algorithm>
#include <cstdint>
namespace RebornConcoctions
{
// Stored on the actual Spell/Aura, never on a reusable spell ID or raw pointer map.
struct Snapshot { uint64_t doctor=0; uint32_t percent=0; };
inline uint32_t HealAmount(uint32_t resolved,uint32_t healthBefore,uint32_t percent)
{
    return uint32_t(uint64_t(std::min(resolved,healthBefore))*std::min(percent,100u)/100u);
}
}
''')
put(SF+CORE+'Spells/RebornWitchDoctorConcoctions.h',r'''#pragma once
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
''')
edit(SF+CORE+'Spells/Spell.h',lambda s:rep(rep(s,'#include "ConditionMgr.h"','#include "ConditionMgr.h"\n#include "RebornConcoctionsState.h"'),'    ~Spell();','    ~Spell();\n    RebornConcoctions::Snapshot rebornConcoctions;'))
edit(SF+CORE+'Spells/Auras/SpellAuras.h',lambda s:rep(rep(s,'#include "SpellAuraDefines.h"','#include "SpellAuraDefines.h"\n#include "RebornConcoctionsState.h"'),'class Aura\n{','class Aura\n{\npublic:\n    RebornConcoctions::Snapshot rebornConcoctions;'))
def spell(s):
 s=rep(s,'#include "Spell.h"','#include "Spell.h"\n#include "RebornWitchDoctorConcoctions.h"')
 s=rep(s,'    HandleLaunchPhase();','''    // WD136: successful offensive cast identity; cancelled/failed casts never arrive here.
    if (!IsTriggered() && !m_spellInfo->IsPositive() && !IsAutoRepeat() && !m_CastItem)
        rebornConcoctions=RebornConcoctions::Launch(m_caster);
    HandleLaunchPhase();''')
 s=rep(s,'SpellCastResult Spell::prepare(SpellCastTargets const* targets, AuraEffect const* triggeredByAura)\n{','''SpellCastResult Spell::prepare(SpellCastTargets const* targets, AuraEffect const* triggeredByAura)
{
    // A periodic trigger child inherits its own parent aura's snapshot; no extra charge.
    if(triggeredByAura && !m_spellInfo->IsPositive() &&
       triggeredByAura->GetSpellInfo()->Effects[triggeredByAura->GetEffIndex()].TriggerSpell==m_spellInfo->Id)
        rebornConcoctions=triggeredByAura->GetBase()->rebornConcoctions;''')
 s=rep(s,'                // Set aura stack amount to desired value','''                // Refresh replaces the old snapshot, including an empty (unbuffed) one.
                if(!m_spellInfo->IsPositive()) m_spellAura->rebornConcoctions=rebornConcoctions;
                // Set aura stack amount to desired value''')
 return s
edit(SF+CORE+'Spells/Spell.cpp',spell)
edit(SF+CORE+'Spells/SpellEffects.cpp',lambda s:rep(s,'            m_spellAura = aura;','            m_spellAura = aura;\n            if(!m_spellInfo->IsPositive()) aura->rebornConcoctions=rebornConcoctions;'))
rel=SF+CORE+'Entities/Unit/Unit.cpp';put(rel,(S/CORE/'Entities/Unit/Unit.cpp').read_bytes())
def unit(s):
 s=rep(s,'#include "Spell.h"','#include "Spell.h"\n#include "RebornWitchDoctorConcoctions.h"')
 needle='    Unit::DealDamage(this, victim, damageInfo->damage, &cleanDamage, SPELL_DIRECT_DAMAGE, SpellSchoolMask(damageInfo->schoolMask), spellProto, durabilityLoss, false, spell);'
 return rep(s,needle,'''    uint32 const healthBefore=victim->GetHealth();
    uint32 const resolved=Unit::DealDamage(this, victim, damageInfo->damage, &cleanDamage, SPELL_DIRECT_DAMAGE, SpellSchoolMask(damageInfo->schoolMask), spellProto, durabilityLoss, false, spell);
    if(spell && spell->GetCaster()==this && victim!=this)
        RebornConcoctions::Heal(this,spell->rebornConcoctions,resolved,healthBefore);''')
edit(rel,unit)
def periodic(s):
 s=rep(s,'#include "SpellAuraEffects.h"','#include "SpellAuraEffects.h"\n#include "RebornWitchDoctorConcoctions.h"')
 a='    Unit::DealDamage(caster, target, damage, &cleanDamage, DOT, GetSpellInfo()->GetSchoolMask(), GetSpellInfo(), true);'
 s=rep(s,a,'''    auto const concoctions=GetBase()->rebornConcoctions;
    uint32 const healthBefore=target->GetHealth();
    uint32 const resolved=Unit::DealDamage(caster, target, damage, &cleanDamage, DOT, GetSpellInfo()->GetSchoolMask(), GetSpellInfo(), true);
    if(caster!=target) RebornConcoctions::Heal(caster,concoctions,resolved,healthBefore);''')
 a='    new_damage = Unit::DealDamage(caster, target, damage, &cleanDamage, DOT, GetSpellInfo()->GetSchoolMask(), GetSpellInfo(), false);'
 return rep(s,a,'''    auto const concoctions=GetBase()->rebornConcoctions;
    uint32 const healthBefore=target->GetHealth();
    new_damage = Unit::DealDamage(caster, target, damage, &cleanDamage, DOT, GetSpellInfo()->GetSchoolMask(), GetSpellInfo(), false);
    if(caster!=target) RebornConcoctions::Heal(caster,concoctions,uint32(std::max(0,new_damage)),healthBefore);''')
edit(SF+CORE+'Spells/Auras/SpellAuraEffects.cpp',periodic)
def brewing(s):
 s=rep(s,'bool _shrooms=false,_fish=false,_bones=false,_thistle=false;','bool _shrooms=false,_fish=false,_bones=false,_thistle=false,_concoctions=false;')
 s=rep(s,'        _shrooms=GetCaster()->HasAura(WD120A::Shrooms);','        _shrooms=GetCaster()->HasAura(WD120A::Shrooms);\n        _concoctions=GetCaster()->HasAura(9003954);')
 s=rep(s,'            p->CastSpell(target,splash?WD120A::SplashHot:WD120A::Hot,true);','''        {
            p->CastSpell(target,splash?WD120A::SplashHot:WD120A::Hot,true);
            if(_concoctions && p->HasSpell(9003954) && p->HasAura(9003954,p->GetGUID()))
                p->CastSpell(target,9003955,true);
        }''');return s
edit(SF+SRC+'RebornWitchDoctorBrewingFoundation.inc',brewing)
def main(s):
 a='        SpellInfo const* info=aura->GetSpellInfo();\n        // WD86A:'
 return rep(s,a,'''        SpellInfo const* info=aura->GetSpellInfo();
        // WD136: eight delivered ingredient effects only; preparation/other HoTs excluded.
        switch(info->Id)
        {
            case 9003867: case 9003889: case 9003903: case 9003904:
            case 9003907: case 9003908: case 9003917: case 9003918:
                if(Unit* source=aura->GetCaster())
                    if(Player* doctor=source->ToPlayer())
                        if(IsDoctor(doctor) && doctor->HasSpell(9003954) && doctor->HasAura(9003954,doctor->GetGUID()))
                            duration=int32(int64(duration)*120/100);
                break;
            default:break;
        }
        // WD86A:''')
edit(SF+SRC+'RebornWitchDoctor.cpp',main)
print('WD136 Spell/Aura-owned snapshots, resolved damage leech and ingredient duration written.')
