// WD137: refresh prepared ingredient fields after native modifiers change.
class aura_reborn_wd137_master : public AuraScript
{
    PrepareAuraScript(aura_reborn_wd137_master);
    void Refresh(AuraEffect const*,AuraEffectHandleModes)
    {
        Player* p=GetTarget()?GetTarget()->ToPlayer():nullptr;
        if(!IsDoctor(p) || !p->IsAlive() || !p->IsInWorld()) return;
        uint32 const prep[3]={9003901,9003905,9003915},field[3]={9003902,9003906,9003916};
        for(uint32 i=0;i<3;++i) if(p->HasAura(prep[i],p->GetGUID())) p->CastSpell(p,field[i],true);
    }
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_reborn_wd137_master::Refresh,EFFECT_2,SPELL_AURA_ADD_PCT_MODIFIER,AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_reborn_wd137_master::Refresh,EFFECT_2,SPELL_AURA_ADD_PCT_MODIFIER,AURA_EFFECT_HANDLE_REAL);
    }
};
