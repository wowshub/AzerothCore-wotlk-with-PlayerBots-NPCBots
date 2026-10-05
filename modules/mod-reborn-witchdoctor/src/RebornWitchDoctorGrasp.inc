// WD96A: own saved Grasp only; periodic Spirit uses the existing owned resource aura.
namespace WD96A
{
constexpr uint32 Grasp=9003790, Spirit=9003574;
class spell_wd96_grasp : public SpellScript
{
    PrepareSpellScript(spell_wd96_grasp);
    SpellCastResult Check()
    {
        Player* p=GetCaster()->ToPlayer();
        return IsDoctor(p) && p->IsAlive() && p->HasSpell(Grasp) && p->GetLevel()>=27 ?
            SPELL_CAST_OK : SPELL_FAILED_CASTER_AURASTATE;
    }
    void Register() override { OnCheckCast += SpellCheckCastFn(spell_wd96_grasp::Check); }
};
class aura_wd96_grasp : public AuraScript
{
    PrepareAuraScript(aura_wd96_grasp);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({Spirit}); }
    void Tick(AuraEffect const*)
    {
        Player* p=GetTarget()->ToPlayer(); // Periodic hook has a valid AuraApplication.
        if(IsDoctor(p) && p->IsAlive() && p->HasSpell(Grasp) && GetCasterGUID()==p->GetGUID())
            p->CastSpell(p,Spirit,true);
    }
    void Register() override { OnEffectPeriodic += AuraEffectPeriodicFn(aura_wd96_grasp::Tick,EFFECT_2,SPELL_AURA_PERIODIC_DUMMY); }
};
void Register()
{
    RegisterSpellScript(spell_wd96_grasp);
    RegisterSpellScript(aura_wd96_grasp);
}
}
