// WD133: two Cauldron bases; native raid-area lifecycle; no global healing coefficient changes.
#include "RebornWitchDoctorDeferredDamage.h"
class spell_reborn_wd133_base : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd133_base);
    SpellCastResult Check()
    {
        Player* p=GetCaster()->ToPlayer();
        return IsDoctor(p) && p->IsAlive() && p->HasSpell(GetSpellInfo()->Id) && p->HasSpell(9003864)
            ?SPELL_CAST_OK:SPELL_FAILED_CASTER_AURASTATE;
    }
    void Register() override { OnCheckCast += SpellCheckCastFn(spell_reborn_wd133_base::Check); }
};
class aura_reborn_wd133_base : public AuraScript
{
    PrepareAuraScript(aura_reborn_wd133_base);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9003942,9003943,9003944,9003945}); }
    void Apply(AuraEffect const*,AuraEffectHandleModes)
    {
        Unit* p=GetCaster();Unit* u=GetTarget();if(!p || !u) return;
        if(p==u) p->RemoveAurasDueToSpell(GetId()==9003942?9003944:9003942,p->GetGUID());
        if(GetId()==9003942)
        {
            p->CastSpell(u,9003943,true);
            if(Aura* a=u->GetAura(9003943,p->GetGUID())) { a->SetMaxDuration(GetDuration());a->SetDuration(GetDuration()); }
        }
    }
    void Removed(AuraEffect const*,AuraEffectHandleModes)
    {
        if(GetId()==9003942) GetTarget()->RemoveAurasDueToSpell(9003943,GetCasterGUID());
        // Earned Crystal shields last their remaining 5 seconds after leaving the field.
    }
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_reborn_wd133_base::Apply,EFFECT_0,SPELL_AURA_DUMMY,AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_reborn_wd133_base::Removed,EFFECT_0,SPELL_AURA_DUMMY,AURA_EFFECT_HANDLE_REAL);
    }
};
class aura_reborn_wd133_beast : public AuraScript
{
    PrepareAuraScript(aura_reborn_wd133_beast);
    WD133::DeferredDamage payments;bool paying=false;
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9003946}); }
    void Amount(AuraEffect const*,int32& amount,bool& recalc) { amount=-1;recalc=false; }
    void Absorb(AuraEffect*,DamageInfo& damage,uint32& absorb)
    {
        absorb=0;
        if(paying || damage.GetDamageType()==DOT || !(damage.GetSchoolMask()&SPELL_SCHOOL_MASK_NORMAL)) return;
        // Multiple doctors must not multiply the deferred fraction. Lowest GUID wins while overlapping.
        for(AuraEffect const* a:GetTarget()->GetAuraEffectsByType(SPELL_AURA_SCHOOL_ABSORB))
            if(a->GetId()==9003943 && a->GetCasterGUID()<GetCasterGUID()) return;
        absorb=uint64(damage.GetDamage())*15/100;
    }
    void Stored(AuraEffect*,DamageInfo&,uint32& absorb)
    {
        payments.Store(absorb);
    }
    void Pay(uint64 amount)
    {
        Unit* u=GetTarget();if(!amount || !u->IsInWorld() || !u->IsAlive()) return;
        paying=true;
        uint32 hit=uint32(std::min<uint64>(amount,UINT32_MAX));
        SpellNonMeleeDamage log(u,u,sSpellMgr->GetSpellInfo(9003946),SPELL_SCHOOL_MASK_NORMAL);log.damage=hit;
        u->SendSpellNonMeleeDamageLog(&log);
        Unit::DealDamage(u,u,hit,nullptr,DOT,SPELL_SCHOOL_MASK_NORMAL,sSpellMgr->GetSpellInfo(9003946),false);
        paying=false;
    }
    void Tick(AuraEffect const*)
    {
        PreventDefaultAction();Pay(payments.Next());
    }
    void Removed(AuraEffect const*,AuraEffectHandleModes)
    {
        Pay(payments.Drain());
    }
    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_reborn_wd133_beast::Amount,EFFECT_0,SPELL_AURA_SCHOOL_ABSORB);
        OnEffectAbsorb += AuraEffectAbsorbFn(aura_reborn_wd133_beast::Absorb,EFFECT_0);
        AfterEffectAbsorb += AuraEffectAbsorbFn(aura_reborn_wd133_beast::Stored,EFFECT_0);
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_reborn_wd133_beast::Tick,EFFECT_1,SPELL_AURA_PERIODIC_DUMMY);
        AfterEffectRemove += AuraEffectRemoveFn(aura_reborn_wd133_beast::Removed,EFFECT_0,SPELL_AURA_SCHOOL_ABSORB,AURA_EFFECT_HANDLE_REAL);
    }
};
class wd133_crystal_heal : public UnitScript
{
public:
    wd133_crystal_heal():UnitScript("wd133_crystal_heal",true,{UNITHOOK_ON_HEAL}) { }
    void OnHeal(Unit*,Unit* u,uint32& gain) override
    {
        if(!u || !u->IsAlive() || !u->IsInWorld() || gain<5) return;
        ObjectGuid selected;
        for(AuraEffect const* a:u->GetAuraEffectsByType(SPELL_AURA_DUMMY))
            if(a->GetId()==9003944 && (selected.IsEmpty() || a->GetCasterGUID()<selected)) selected=a->GetCasterGUID();
        if(selected.IsEmpty()) return;
        Unit* p=ObjectAccessor::GetUnit(*u,selected);
        if(!IsDoctor(p?p->ToPlayer():nullptr) || !p->IsAlive() || !p->HasAura(9003944,p->GetGUID()) ||
           !p->IsWithinDistInMap(u,40.0f) || !p->IsFriendlyTo(u) || (p!=u && !p->IsInRaidWith(u))) return;
        uint64 value=gain/5;
        if(AuraEffect* a=u->GetAuraEffect(9003945,EFFECT_0,selected)) value+=uint32(std::max(0,a->GetAmount()));
        int32 amount=int32(std::min<uint64>(std::min<uint64>(value,u->GetMaxHealth()),INT32_MAX));
        p->CastCustomSpell(u,9003945,&amount,nullptr,nullptr,true);
    }
};
