// WD93A: Voice is an owned active aura; Price only changes its Spirit amount.
namespace WD93A
{
constexpr uint32 Voice=9003780, Explosion=9003781, Price=9003782;
class spell_wd93_voice : public SpellScript
{
    PrepareSpellScript(spell_wd93_voice);
    SpellCastResult Check()
    {
        Player* p=GetCaster()->ToPlayer();
        return IsDoctor(p) && p->IsAlive() && p->HasSpell(Voice) && p->GetLevel()>=57 ?
            SPELL_CAST_OK : SPELL_FAILED_CASTER_AURASTATE;
    }
    void Register() override { OnCheckCast += SpellCheckCastFn(spell_wd93_voice::Check); }
};
class aura_wd93_voice : public AuraScript
{
    PrepareAuraScript(aura_wd93_voice);
    bool executing=false;
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({Explosion,Price}); }
    void Amount(AuraEffect const*,int32& amount,bool& recalculate)
    {
        // CalcAmount runs during Aura::_InitEffects, before an AuraApplication exists.
        // GetTarget() is invalid in this hook; the unit owner already exists here.
        Unit* owner=GetUnitOwner();
        Player* p=owner ? owner->ToPlayer() : nullptr;
        amount=IsDoctor(p) && p->HasSpell(Price) && p->HasAura(Price,p->GetGUID()) ? 100 : 0;
        recalculate=false;
    }
    bool Check(ProcEventInfo& e)
    {
        Player* p=GetTarget()->ToPlayer();
        Unit* target=e.GetActionTarget();
        SpellInfo const* info=e.GetSpellInfo();
        return !executing && IsDoctor(p) && p->IsAlive() && p->HasSpell(Voice) &&
            GetCasterGUID()==p->GetGUID() && e.GetActor()==p && target && target!=p &&
            target->IsAlive() && p->IsValidAttackTarget(target) && info && info->Id!=Explosion &&
            (e.GetTypeMask() & PROC_FLAG_DONE_PERIODIC) && e.GetDamageInfo() && e.GetDamageInfo()->GetDamage();
    }
    void Proc(ProcEventInfo& e)
    {
        PreventDefaultAction();
        if (!Check(e)) return;
        executing=true;
        GetTarget()->CastSpell(e.GetActionTarget(),Explosion,true);
        executing=false;
    }
    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_wd93_voice::Amount,EFFECT_2,SPELL_AURA_MOD_PERCENT_STAT);
        DoCheckProc += AuraCheckProcFn(aura_wd93_voice::Check);
        OnProc += AuraProcFn(aura_wd93_voice::Proc);
    }
};
class spell_wd93_explosion : public SpellScript
{
    PrepareSpellScript(spell_wd93_explosion);
    void Scale(SpellEffIndex)
    {
        Player* p=GetCaster()->ToPlayer();
        if (!IsDoctor(p)) { SetEffectValue(0);return; }
        // Native automatic bonus is disabled by the exact spell_bonus_data row.
        SetEffectValue(GetEffectValue()+int32(.25f*std::max(0,p->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_SHADOW))));
    }
    void Register() override
    {
        OnEffectLaunchTarget += SpellEffectFn(spell_wd93_explosion::Scale,EFFECT_0,SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};
void Register()
{
    RegisterSpellScript(spell_wd93_voice);
    RegisterSpellScript(aura_wd93_voice);
    RegisterSpellScript(spell_wd93_explosion);
}
}
