// WD148: Residual Energy. Upstream aura lifecycle expires Avatar into LesserAvatar.
namespace WD148
{
constexpr uint32 Talent=9004060, Lesser=9004061, Avatar=9003270;
bool Owns(Player* p) { return IsDoctor(p) && p->IsAlive() && p->HasSpell(9003967) && p->HasSpell(Talent) && p->HasAura(Talent,p->GetGUID()); }
class avatar_end : public AuraScript
{
    PrepareAuraScript(avatar_end);
    void Removed(AuraEffect const*,AuraEffectHandleModes)
    {
        Player* p=GetCaster()?GetCaster()->ToPlayer():nullptr;
        if(GetTargetApplication()->GetRemoveMode()!=AURA_REMOVE_BY_EXPIRE || !Owns(p) || GetTarget()!=p)return;
        p->CastSpell(p,Lesser,true);
    }
    void Register() override { AfterEffectRemove += AuraEffectRemoveFn(avatar_end::Removed,EFFECT_0,SPELL_AURA_ANY,AURA_EFFECT_HANDLE_REAL); }
};
class lesser : public AuraScript
{
    PrepareAuraScript(lesser);
    void Tick(AuraEffect const*)
    {
        Player* p=GetTarget()->ToPlayer();
        if(!Owns(p) || GetCasterGUID()!=p->GetGUID()) { Remove();return; }
        // Donor child 706803 has basepoints19 (+1 =20), not periodic slot basepoints14.
        for(uint32 id=9004030;id<=9004036;++id)if(p->HasSpell(id))
        {
            uint32 remaining=p->GetSpellCooldownDelay(id);
            if(remaining>=5)p->ModifySpellCooldown(id,-int32(remaining/5));
        }
    }
    void Register() override { OnEffectPeriodic += AuraEffectPeriodicFn(lesser::Tick,EFFECT_1,SPELL_AURA_PERIODIC_DUMMY); }
};
void Register() { RegisterSpellScript(WD148::avatar_end);RegisterSpellScript(WD148::lesser); }
}
namespace WD148Bridge
{
void Apply(Player* p,bool enabled)
{
    if(!IsDoctor(p))return;
    if(enabled) {
        if(!p->HasSpell(WD148::Talent))p->learnSpell(WD148::Talent);
        if(!p->HasAura(WD148::Talent,p->GetGUID()))p->CastSpell(p,WD148::Talent,true);
    } else {
        p->RemoveAurasDueToSpell(WD148::Talent,p->GetGUID());
        p->RemoveAurasDueToSpell(WD148::Lesser,p->GetGUID());
        if(p->HasSpell(WD148::Talent))p->removeSpell(WD148::Talent,3,false);
    }
}
}
