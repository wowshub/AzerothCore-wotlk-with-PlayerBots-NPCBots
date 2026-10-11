// WD138B: current Tiki (crit / magic absorb); no legacy next-Brew buff.
namespace WD138
{
constexpr uint32 Talent=9003958, Splash=9003959, Crit=9003960, Shield=9003961;
bool Owned(Player* p){return p && IsDoctor(p) && p->IsAlive() && p->HasSpell(Talent) && p->HasAura(Talent,p->GetGUID());}
uint32 Base(Player* p){return p->HasAura(9003942)?9003942u:p->HasAura(9003944)?9003944u:0u;}
// WD138D: Splash is a persistent learned action; no superseded-spell packets.
}
class spell_reborn_wd138_tiki : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd138_tiki);
    uint32 base=0;
    bool Validate(SpellInfo const*) override {return ValidateSpellInfo({WD138::Talent,WD138::Crit,WD138::Shield});}
    SpellCastResult Check()
    {
        Player* p=GetCaster()->ToPlayer();
        if(!p || !WD138::Owned(p) || p->GetLevel()<24 || !p->HasSpell(WD138::Splash))
            return SPELL_FAILED_CASTER_AURASTATE;
        // WD138D: explain the missing prerequisite, without changing other cast failures.
        if(!WD138::Base(p))
        {
            if(p->GetSession())
                ChatHandler(p->GetSession()).SendNotification(
                    "请先施放基底：水晶之水或基底：野兽之血，再施放提基泼洒。 / First cast Base: Crystal Water or Base: Beast Blood, then Tiki Splash.");
            return SPELL_FAILED_DONT_REPORT;
        }
        return SPELL_CAST_OK;
    }
    void Snapshot(){Player* p=GetCaster()->ToPlayer();base=p?WD138::Base(p):0;}
    void Done()
    {
        Player* p=GetCaster()->ToPlayer();
        if(WD138::Owned(p) && base && !GetSpell()->IsTriggered())
            p->CastSpell(p,base==9003942?WD138::Crit:WD138::Shield,true);
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_wd138_tiki::Check);
        BeforeCast += SpellCastFn(spell_reborn_wd138_tiki::Snapshot);
        AfterCast += SpellCastFn(spell_reborn_wd138_tiki::Done);
    }
};
class aura_reborn_wd138_amount : public AuraScript
{
    PrepareAuraScript(aura_reborn_wd138_amount);
    void Amount(AuraEffect const*,int32& amount,bool& recalc)
    {
        Player* p=GetCaster()?GetCaster()->ToPlayer():nullptr;recalc=false;
        if(!WD138::Owned(p)){amount=0;return;}
        float coefficient=GetId()==WD138::Shield?0.75f:0.25f;
        // Current Bottle coefficient modifier; no Bottle on-hit/proc cloning.
        if(GetId()==WD138::Splash && p->HasAura(9003911))coefficient*=1.15f;
        amount+=int32(float(std::max(0,p->SpellBaseHealingBonusDone(SPELL_SCHOOL_MASK_NATURE)))*coefficient);
    }
    void Tick(AuraEffect const*)
    {
        Player* p=GetCaster()?GetCaster()->ToPlayer():nullptr;
        if(!WD138::Owned(p))PreventDefaultAction();
    }
    void Register() override
    {
        if(m_scriptSpellId==WD138::Shield)
            DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_reborn_wd138_amount::Amount,EFFECT_0,SPELL_AURA_SCHOOL_ABSORB);
        else
        {
            DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_reborn_wd138_amount::Amount,EFFECT_0,SPELL_AURA_PERIODIC_HEAL);
            OnEffectPeriodic += AuraEffectPeriodicFn(aura_reborn_wd138_amount::Tick,EFFECT_0,SPELL_AURA_PERIODIC_HEAL);
        }
    }
};
