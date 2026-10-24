// WD146: Spirit Glaive, Soul Feeder and Vol'jin's Blessing.
namespace WD146
{
constexpr uint32 Spirit=9003574,Feeder=9004040,Blessing=9004041,Avatar=9003270;
bool Glaive(uint32 id) { return id>=9004030 && id<=9004036; }
bool Owns(Player* p,uint32 id) { return IsDoctor(p) && p->IsAlive() && p->HasSpell(9003967) && p->HasSpell(id); }
uint32 Count(Player* p) { Aura* a=p?p->GetAura(Spirit,p->GetGUID()):nullptr;return a?std::min<uint32>(5,a->GetStackAmount()):0; }
void Refresh(Player* p,uint32 count)
{
    if(!IsDoctor(p))return;
    if(AuraEffect* e=p->GetAuraEffect(Feeder,EFFECT_0,p->GetGUID())) e->ChangeAmount(Owns(p,Feeder)?int32(count*5):0);
}
class modifiers : public GlobalScript
{
public:
    modifiers():GlobalScript("reborn_wd146_modifiers"){}
    bool OnIsAffectedBySpellModCheck(SpellInfo const*,SpellInfo const* check,SpellModifier const* mod) override
    {
        if(mod && check && mod->spellId==Feeder)
            return !(mod->op==SPELLMOD_DAMAGE && ((check->Id>=9003970 && check->Id<=9003978) || check->Id==9004020 || check->Id==9004021));
        return true;
    }
};
class feeder : public AuraScript
{
    PrepareAuraScript(feeder);
    void Calculate(AuraEffect const*,int32& amount,bool& recalc)
    {
        // CalcAmount runs before AuraApplication exists; GetTarget() is invalid here.
        Unit* owner=GetUnitOwner();Player* p=owner?owner->ToPlayer():nullptr;
        amount=Owns(p,Feeder)?Count(p)*5:0;recalc=false;
    }
    void Register() override { DoEffectCalcAmount += AuraEffectCalcAmountFn(feeder::Calculate,EFFECT_0,SPELL_AURA_ADD_PCT_MODIFIER); }
};
class spirit_sync : public AuraScript
{
    PrepareAuraScript(spirit_sync);
    void Apply(AuraEffect const*,AuraEffectHandleModes)
    { if(GetCasterGUID()==GetTarget()->GetGUID()) Refresh(GetTarget()->ToPlayer(),std::min<uint32>(5,GetStackAmount())); }
    void Remove(AuraEffect const*,AuraEffectHandleModes)
    { if(GetCasterGUID()==GetTarget()->GetGUID()) Refresh(GetTarget()->ToPlayer(),0); }
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spirit_sync::Apply,EFFECT_0,SPELL_AURA_PERIODIC_ENERGIZE,AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(spirit_sync::Remove,EFFECT_0,SPELL_AURA_PERIODIC_ENERGIZE,AURA_EFFECT_HANDLE_REAL);
    }
};
class glaive : public SpellScript
{
    PrepareSpellScript(glaive);
    bool automatic=false;
    bool Load() override { automatic=!GetSpell()->IsTriggered()&&WD168::IsAutomaticCast(GetCaster()->ToPlayer(),GetSpellInfo()->Id);return true; }
    void Filter(std::list<WorldObject*>& targets)
    {
        if(WDN1::Actor(GetCaster()))
        {
            Unit* caster=GetCaster();uint32 spell=GetSpellInfo()->Id;
            targets.remove_if([caster,spell](WorldObject* o){return !WDN1::Known(caster,spell)||!o||!WDN1::Safe(caster,o->ToUnit());});return;
        }
        if(!automatic)return; // Preserve manual cone targeting, including its normal native rules.
        Player* p=GetCaster()->ToPlayer();
        targets.remove_if([p](WorldObject* o){return !o||!WD168::SafeAutomaticTarget(p,o->ToUnit());});
    }
    uint32 readyPct=0;
    void Snapshot() { readyPct=WD149::ReadyPct(GetCaster()->ToPlayer()); }
    void Consume() { if(readyPct)WD149::Consume(GetCaster()->ToPlayer()); }
    SpellCastResult Check()
    {
        if(auto* c=WDN1::Actor(GetCaster()))
            return WDN1::Known(c,GetSpellInfo()->Id)&&WDN1::Safe(c,c->GetVictim())?SPELL_CAST_OK:SPELL_FAILED_CASTER_AURASTATE;
        Player* p=GetCaster()->ToPlayer();return Owns(p,GetSpellInfo()->Id)?SPELL_CAST_OK:SPELL_FAILED_CASTER_AURASTATE;
    }
    void Damage(SpellEffIndex)
    {
        if(WDN1::Actor(GetCaster()))
        {
            Unit* c=GetCaster();
            if(!WDN1::Known(c,GetSpellInfo()->Id)||!WDN1::Safe(c,GetHitUnit())){SetEffectValue(0);return;}
            SetEffectValue(GetEffectValue()+int32(.5f*std::max(0.f,c->GetTotalAttackPowerValue(RANGED_ATTACK))+.5f*std::max(0,c->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_SHADOW))));return;
        }
        Player* p=GetCaster()->ToPlayer();if(!Owns(p,GetSpellInfo()->Id)) { SetEffectValue(0);return; }
        int32 base=GetEffectValue()+int32(.5f*std::max(0.0f,p->GetTotalAttackPowerValue(RANGED_ATTACK))+.5f*std::max(0,p->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_SHADOW)));
        SetEffectValue(int32(int64(base)*(100+readyPct)/100));
    }
    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(glaive::Filter,EFFECT_0,TARGET_UNIT_CONE_ENEMY_24);
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(glaive::Filter,EFFECT_2,TARGET_UNIT_CONE_ENEMY_24);
        OnCast += SpellCastFn(glaive::Snapshot);
        AfterCast += SpellCastFn(glaive::Consume);
        OnCheckCast += SpellCheckCastFn(glaive::Check);
        OnEffectHitTarget += SpellEffectFn(glaive::Damage,EFFECT_0,SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};
class resistance : public AuraScript
{
    PrepareAuraScript(resistance);
    void Calculate(AuraEffect const*,int32& amount,bool& recalc)
    {
        if(auto* c=WDN1::Actor(GetCaster())){amount=WDN1::Known(c,GetId())?-int32(c->GetLevel()+1):0;recalc=false;return;}
        Player* p=GetCaster()?GetCaster()->ToPlayer():nullptr;amount=Owns(p,GetId())?-int32(p->GetLevel()+1):0;recalc=false;
    }
    void Register() override { DoEffectCalcAmount += AuraEffectCalcAmountFn(resistance::Calculate,EFFECT_2,SPELL_AURA_MOD_RESISTANCE); }
};
class blessing : public AuraScript
{
    PrepareAuraScript(blessing);
    void Tick(AuraEffect const*)
    {
        Player* p=GetTarget()->ToPlayer();
        if(!Owns(p,Blessing) || !p->HasAura(Avatar,p->GetGUID()))return;
        for(uint32 id=9004030;id<=9004036;++id)if(p->HasSpell(id))
        {
            uint32 remaining=p->GetSpellCooldownDelay(id);
            if(remaining>=5) p->ModifySpellCooldown(id,-int32(remaining/5));
        }
    }
    void Register() override { OnEffectPeriodic += AuraEffectPeriodicFn(blessing::Tick,EFFECT_0,SPELL_AURA_PERIODIC_DUMMY); }
};
void Register()
{
    new modifiers();RegisterSpellScript(WD146::feeder);RegisterSpellScript(WD146::spirit_sync);
    RegisterSpellScript(WD146::glaive);RegisterSpellScript(WD146::resistance);RegisterSpellScript(WD146::blessing);
}
}
namespace WD146Bridge
{
void Apply(Player* p,bool glaive,bool feeder,bool blessing)
{
    if(!IsDoctor(p))return;
    uint32 actions[MAX_ACTION_BUTTONS]={};
    for(uint8 b=0;b<MAX_ACTION_BUTTONS;++b)if(ActionButton const* a=p->GetActionButton(b))if(a->GetType()==ACTION_BUTTON_SPELL)actions[b]=a->GetAction();
    uint32 const levels[]={15,20,28,36,44,52,60};uint32 best=0;
    for(uint32 i=0;i<7;++i)if(glaive&&p->GetLevel()>=levels[i])best=9004030+i;
    for(uint32 i=0;i<7;++i)
    {
        uint32 id=9004030+i;
        if(id==best) { if(!p->HasSpell(id))p->learnSpell(id); }
        else if(p->HasSpell(id))p->removeSpell(id,3,false);
    }
    bool changed=false;
    for(uint8 b=0;b<MAX_ACTION_BUTTONS;++b)if(WD146::Glaive(actions[b])&&actions[b]!=best)
    { p->removeActionButton(b);if(best)p->addActionButton(b,best,ACTION_BUTTON_SPELL);changed=true; }
    if(changed)p->SendActionButtons(1);
    bool flags[]={feeder,blessing};
    for(uint32 i=0;i<2;++i)
    {
        uint32 id=9004040+i;
        if(flags[i]) { if(!p->HasSpell(id))p->learnSpell(id);if(!p->HasAura(id,p->GetGUID()))p->CastSpell(p,id,true); }
        else { p->RemoveAurasDueToSpell(id,p->GetGUID());if(p->HasSpell(id))p->removeSpell(id,3,false); }
    }
    WD146::Refresh(p,WD146::Count(p));
}
}
