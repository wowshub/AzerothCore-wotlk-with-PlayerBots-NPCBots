// WD87A: spirit talents share the existing owned Spirit aura; no new resource pool.
namespace WD87A
{
constexpr uint32 LoaOne=9003750, LoaTwo=9003751, BewareOne=9003752, BewareTwo=9003753, Juju=9003754, Spirit=9003574;
uint32 LoaRank(Player* p,uint32 excluding=0)
{
    if (!IsDoctor(p)) return 0;
    if (excluding!=LoaTwo && p->HasSpell(LoaTwo) && p->HasAura(LoaTwo)) return 2;
    if (excluding!=LoaOne && p->HasSpell(LoaOne) && p->HasAura(LoaOne)) return 1;
    return 0;
}
uint32 Count(Player* p)
{
    Aura* aura=IsDoctor(p)?p->GetAura(Spirit,p->GetGUID()):nullptr;
    return aura?std::min<uint32>(5,aura->GetStackAmount()):0;
}
void Sync(Player* p,uint32 excluding=0,bool spiritGone=false)
{
    if (!IsDoctor(p)) return;
    uint32 count=spiritGone?0:Count(p);
    if (!spiritGone)
        if (AuraEffect* stat=p->GetAuraEffect(Spirit,EFFECT_2,p->GetGUID()))
            stat->ChangeAmount(int32(count*2*LoaRank(p,excluding)),false);
    if (excluding!=Juju)
        if (AuraEffect* chance=p->GetAuraEffect(Juju,EFFECT_0,p->GetGUID()))
            chance->ChangeAmount(int32(count*5),false);
}
bool Derived(SpellInfo const* info)
{
    if (!info) return false;
    // Local counterparts of upstream derived echoes, stored releases and Spirit restoration.
    switch (info->Id)
    {
        case 9003102: case 9003468: case 9003486: case 9003574: case 9003672: case 9003732:
            return true;
        default: return false;
    }
}
class aura_wd87_talent : public AuraScript
{
    PrepareAuraScript(aura_wd87_talent);
    bool executing=false;
    void Amount(AuraEffect const*,int32& amount,bool& recalculate)
    {
        if (GetId()==Juju)
        {
            amount=int32(Count(GetUnitOwner()->ToPlayer())*5);
            recalculate=true;
        }
    }
    void Apply(AuraEffect const*,AuraEffectHandleModes) { Sync(GetTarget()->ToPlayer()); }
    void Remove(AuraEffect const*,AuraEffectHandleModes) { Sync(GetTarget()->ToPlayer(),GetId()); }
    bool Check(ProcEventInfo& event)
    {
        Player* p=GetTarget()->ToPlayer();
        uint32 rank=LoaRank(p);
        if (executing || !rank || !p->IsAlive() || event.GetActor()!=p || !event.GetActionTarget() ||
            GetId()!=(rank==2?LoaTwo:LoaOne) || Derived(event.GetSpellInfo())) return false;
        bool damage=event.GetDamageInfo() && event.GetDamageInfo()->GetDamage()>0;
        bool healing=event.GetHealInfo() && event.GetHealInfo()->GetEffectiveHeal()>0;
        return (damage || healing) && roll_chance_i(rank==2?15:8);
    }
    void Proc(ProcEventInfo&)
    {
        PreventDefaultAction();
        if (executing) return;
        executing=true;
        GetTarget()->CastSpell(GetTarget(),Spirit,true);
        executing=false;
    }
    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_wd87_talent::Amount,EFFECT_0,SPELL_AURA_ANY);
        AfterEffectApply += AuraEffectApplyFn(aura_wd87_talent::Apply,EFFECT_0,SPELL_AURA_ANY,AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(aura_wd87_talent::Remove,EFFECT_0,SPELL_AURA_ANY,AURA_EFFECT_HANDLE_REAL);
        DoCheckProc += AuraCheckProcFn(aura_wd87_talent::Check);
        OnProc += AuraProcFn(aura_wd87_talent::Proc);
    }
};
class aura_wd87_spirit : public AuraScript
{
    PrepareAuraScript(aura_wd87_spirit);
    void Amount(AuraEffect const*,int32& amount,bool& recalculate)
    {
        // Core multiplies the result by StackAmount after this callback.
        amount=int32(2*LoaRank(GetUnitOwner()->ToPlayer()));
        recalculate=true;
    }
    void Apply(AuraEffect const*,AuraEffectHandleModes) { Sync(GetTarget()->ToPlayer()); }
    void Remove(AuraEffect const*,AuraEffectHandleModes) { Sync(GetTarget()->ToPlayer(),0,true); }
    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_wd87_spirit::Amount,EFFECT_2,SPELL_AURA_MOD_TOTAL_STAT_PERCENTAGE);
        AfterEffectApply += AuraEffectApplyFn(aura_wd87_spirit::Apply,EFFECT_2,SPELL_AURA_MOD_TOTAL_STAT_PERCENTAGE,AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(aura_wd87_spirit::Remove,EFFECT_2,SPELL_AURA_MOD_TOTAL_STAT_PERCENTAGE,AURA_EFFECT_HANDLE_REAL);
    }
};
class modifiers : public GlobalScript
{
public:
    modifiers():GlobalScript("reborn_wd87_spirit_modifiers") { }
    bool OnIsAffectedBySpellModCheck(SpellInfo const*,SpellInfo const* check,SpellModifier const* mod) override
    {
        if (!check || !mod) return true;
        // In this core false is a positive match; empty DBC masks exclude the fallback.
        if ((mod->spellId==BewareOne || mod->spellId==BewareTwo) && mod->op==SPELLMOD_DURATION)
            return check->Id!=9003673 && check->Id!=Spirit;
        if (mod->spellId==Juju && mod->op==SPELLMOD_CRITICAL_CHANCE)
        {
            WD19A::Family const* family=WD19A::FindFamily(check->Id);
            return !family || family->ranks[0].spell!=9003103;
        }
        return true;
    }
};
void Register()
{
    RegisterSpellScript(aura_wd87_talent);
    RegisterSpellScript(aura_wd87_spirit);
    new modifiers();
}
}
