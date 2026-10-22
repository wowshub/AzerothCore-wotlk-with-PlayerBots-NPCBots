// WD142: private spell IDs; no changes to global CoA spell families.
namespace WD142
{
constexpr uint32 Veil=9003962,Pulse=9003963,Communion=9003964,Devotion=9003965,Heal=9003966;
struct State : DataMap::Base { std::vector<ObjectGuid> targets; };
constexpr char Key[]="Reborn.WD142.Veil";
void Clear(Player* p)
{
    auto* state=p->CustomData.GetDefault<State>(Key);
    auto targets=std::move(state->targets);state->targets.clear();
    for(ObjectGuid guid:targets)
        if(Unit* target=ObjectAccessor::GetUnit(*p,guid)) target->RemoveAurasDueToSpell(Veil,p->GetGUID());
}
class aura_veil : public AuraScript
{
    PrepareAuraScript(aura_veil);
public:
    void SetAutomatic(bool value) {automatic=value;}
private:
    bool automatic=false;
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({Veil,Pulse,Communion}); }
    void Applied(AuraEffect const*,AuraEffectHandleModes)
    {
        Player* p=GetCaster()?GetCaster()->ToPlayer():nullptr;
        if(!IsDoctor(p) || !p->HasSpell(Veil)) { Remove();return; }
        auto& targets=p->CustomData.GetDefault<State>(Key)->targets;
        if(std::find(targets.begin(),targets.end(),GetTarget()->GetGUID())==targets.end()) targets.push_back(GetTarget()->GetGUID());
    }
    void Removed(AuraEffect const*,AuraEffectHandleModes)
    {
        Player* p=GetCaster()?GetCaster()->ToPlayer():nullptr;if(!p) return;
        auto& targets=p->CustomData.GetDefault<State>(Key)->targets;
        targets.erase(std::remove(targets.begin(),targets.end(),GetTarget()->GetGUID()),targets.end());
    }
    void Tick(AuraEffect const*)
    {
        PreventDefaultAction();
        Player* p=GetCaster()?GetCaster()->ToPlayer():nullptr;
        Unit* target=GetTarget();
        if(!IsDoctor(p) || !p->IsAlive() || !p->HasSpell(Veil) || !p->IsInMap(target)) { Remove();return; }
        if(automatic&&!WD168::SafeAutomaticTarget(p,target)) {Remove();return;}
        WD168::AutomaticCastScope scope(p,automatic?Pulse:0);
        if(target->IsAlive() && p->IsValidAttackTarget(target) && p->IsWithinDistInMap(target,40.0f) && p->IsWithinLOSInMap(target))
            p->CastSpell(target,Pulse,true);
    }
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_veil::Applied,EFFECT_0,SPELL_AURA_MOD_DAMAGE_FROM_CASTER,AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_veil::Removed,EFFECT_0,SPELL_AURA_MOD_DAMAGE_FROM_CASTER,AURA_EFFECT_HANDLE_REAL);
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_veil::Tick,EFFECT_1,SPELL_AURA_PERIODIC_DUMMY);
    }
};
// Preserve the existing SQL loader name with a paired Spell/Aura loader.
// Capture during prepare, relay after actual application/reapplication.
class spell_veil : public SpellScript
{
    PrepareSpellScript(spell_veil);
    bool automatic=false;
    bool Load() override {automatic=WD168::IsAutomaticCast(GetCaster()->ToPlayer(),Veil);return true;}
    void Guard(SpellEffIndex)
    {
        if(automatic&&!WD168::SafeAutomaticTarget(GetCaster()->ToPlayer(),GetHitUnit()))
        {PreventHitAura();PreventHitDefaultEffect(EFFECT_0);PreventHitDefaultEffect(EFFECT_1);}
    }
    void Mark()
    {
        if(Aura* a=GetHitAura())if(auto* script=a->GetScript<aura_veil>("WD142::aura_veil"))script->SetAutomatic(automatic);
    }
    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_veil::Guard,EFFECT_0,SPELL_EFFECT_APPLY_AURA);
        OnEffectHitTarget += SpellEffectFn(spell_veil::Guard,EFFECT_1,SPELL_EFFECT_APPLY_AURA);
        AfterHit += SpellHitFn(spell_veil::Mark);
    }
};
class spell_pulse : public SpellScript
{
    PrepareSpellScript(spell_pulse);
    bool automatic=false;
    bool Load() override {automatic=WD168::IsAutomaticCast(GetCaster()->ToPlayer(),Pulse);return true;}
    void Recheck()
    {if(automatic&&!WD168::SafeAutomaticTarget(GetCaster()->ToPlayer(),GetHitUnit()))SetHitDamage(0);}
    void Damage(SpellEffIndex index)
    {
        Player* p=GetCaster()->ToPlayer();
        if(automatic&&!WD168::SafeAutomaticTarget(p,GetHitUnit()))
        {PreventHitDefaultEffect(index);SetEffectValue(0);SetHitDamage(0);return;}
        if(!IsDoctor(p) || !p->HasSpell(Veil) || !GetHitUnit() || !GetHitUnit()->HasAura(Veil,p->GetGUID())) { SetEffectValue(0);return; }
        float amount=GetEffectValue()+0.10f*std::max(0,p->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_SHADOW))+
                     0.045f*std::max(0.0f,p->GetTotalAttackPowerValue(BASE_ATTACK));
        if(p->HasSpell(Communion) && p->HasAura(Communion,p->GetGUID())) amount*=2.0f;
        SetEffectValue(int32(std::max(0.0f,amount)));
    }
    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_pulse::Damage,EFFECT_0,SPELL_EFFECT_SCHOOL_DAMAGE);
        OnHit += SpellHitFn(spell_pulse::Recheck);
    }
};
class aura_devotion : public AuraScript
{
    PrepareAuraScript(aura_devotion);
    bool executing=false;
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({Heal}); }
    bool Check(ProcEventInfo& event)
    {
        Player* p=GetTarget()->ToPlayer();auto* damage=event.GetDamageInfo();auto* info=event.GetSpellInfo();
        if(executing || !IsDoctor(p) || !p->IsAlive() || !p->HasSpell(Devotion) || event.GetActor()!=p ||
           !event.GetActionTarget() || event.GetActionTarget()==p || !damage || !damage->GetDamage() ||
           (event.GetTypeMask()&(PROC_FLAG_DONE_PERIODIC|PROC_FLAG_TAKEN_PERIODIC))) return false;
        // Periodic puppet hits and copied/derived damage must not masquerade as direct casts.
        return !info || (info->Id!=Pulse && info->Id!=Heal && info->Id!=9003695 && info->Id!=9003672 && info->Id!=9003468);
    }
    void Proc(ProcEventInfo& event)
    {
        PreventDefaultAction();Player* p=GetTarget()->ToPlayer();if(!p || executing) return;
        auto* effect=GetEffect(EFFECT_0);auto* info=sSpellMgr->GetSpellInfo(Heal);if(!effect || !info) return;
        executing=true;
        uint32 amount=uint32(uint64(event.GetDamageInfo()->GetDamage())*std::max(0,effect->GetAmount())/100);
        // Amount already derives from final damage; no second spell-power/crit or proc dispatch.
        amount=p->SpellHealingBonusTaken(p,info,amount,HEAL);
        HealInfo heal(p,p,amount,info,info->GetSchoolMask());Unit::CalcHealAbsorb(heal);p->HealBySpell(heal,false);
        p->GetThreatMgr().ForwardThreatForAssistingMe(p,float(heal.GetEffectiveHeal())*.5f,info);
        executing=false;
    }
    void Register() override { DoCheckProc += AuraCheckProcFn(aura_devotion::Check);OnProc += AuraProcFn(aura_devotion::Proc); }
};
// Native aura 271 handles spells but this core skips it for white melee attacks.
class melee : public UnitScript
{
public:
    melee():UnitScript("reborn_wd142_melee",true,{UNITHOOK_MODIFY_MELEE_DAMAGE}){}
    void ModifyMeleeDamage(Unit* target,Unit* attacker,uint32& damage) override
    {
        Player* p=attacker?attacker->ToPlayer():nullptr;
        if(!IsDoctor(p) || !p->HasSpell(Veil) || !target) return;
        if(AuraEffect const* effect=target->GetAuraEffect(Veil,EFFECT_0,p->GetGUID()))
            damage=uint32(std::min<uint64>(UINT32_MAX,uint64(damage)*(100+std::max(0,effect->GetAmount()))/100));
    }
};
}
