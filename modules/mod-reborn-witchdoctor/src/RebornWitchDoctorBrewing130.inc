// WD130: local adaptation of CoA 04360619. Branch cap and ramp are documented policy.
#include "RebornWitchDoctorBeamPolicy182.h"
namespace WD130Local
{
void Reduce(Player* p,uint32 first,uint32 last,int32 ms)
{
    for(uint32 id=first;id<=last;++id) if(p->GetSpellCooldownDelay(id)) p->ModifySpellCooldown(id,-ms);
}
}
class spell_reborn_wd130_beam : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd130_beam);
    bool automatic=false;
    bool Load() override {automatic=WD168::IsAutomaticCast(GetCaster()->ToPlayer(),GetSpellInfo()->Id);return true;}
    void MarkAutomation();
    SpellCastResult Check()
    {
        Player* p=GetCaster()->ToPlayer();
        if(!IsDoctor(p) || !p->IsAlive() || !p->HasSpell(GetSpellInfo()->Id) || p->GetLevel()<GetSpellInfo()->SpellLevel)
            return SPELL_FAILED_CASTER_AURASTATE;
        return WD130A::Friendly(p,GetExplTargetUnit())?SPELL_CAST_OK:SPELL_FAILED_BAD_TARGETS;
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_wd130_beam::Check);
        AfterHit += SpellHitFn(spell_reborn_wd130_beam::MarkAutomation);
    }
};
class spell_reborn_wd130_heal : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd130_heal);
    void Hit()
    {
        Player* p=GetCaster()->ToPlayer();
        WD132A::Echo(p,GetHitUnit(),uint32(std::max(0,GetHitHeal())));
        // Effective gain, not the raw heal or overheal, reduces each live rank's cooldown.
        if(IsDoctor(p) && GetHitHeal()>0 && p->HasAura(9003930))
        { WD130Local::Reduce(p,9003870,9003876,1000); WD130Local::Reduce(p,9003890,9003896,1000); }
    }
    void Register() override { AfterHit += SpellHitFn(spell_reborn_wd130_heal::Hit); }
};
class aura_reborn_wd130_beam : public AuraScript
{
    PrepareAuraScript(aura_reborn_wd130_beam);
public:
    void SetAutomatic(bool value) {automatic=value;}
private:
    bool automatic=false;
    std::vector<ObjectGuid> branches;
    uint32 ticks=0;
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9003929,9003932,9003937,9003938,9003939}); }
    void Apply(AuraEffect const*,AuraEffectHandleModes)
    {
        if(Player* p=GetCaster()?GetCaster()->ToPlayer():nullptr)
        {
            branches.push_back(GetTarget()->GetGUID());
            p->CastSpell(p,9003929,true);
            if(Aura* a=p->GetAura(9003929,p->GetGUID())) { a->SetMaxDuration(GetDuration());a->SetDuration(GetDuration()); }
        }
    }
    void Heal(Player* p,ObjectGuid guid,int32 base)
    {
        if(!WD130A::Channel(p)) return;
        Unit* u=ObjectAccessor::GetUnit(*p,guid);
        if(!WD130A::Friendly(p,u)) return;
        if(automatic&&(!AutoRecipient(p,u)||u->GetHealthPct()>=90.f))return;
        int32 amount=std::max(0,base)+int32(float(std::max(0,p->SpellBaseHealingBonusDone(SPELL_SCHOOL_MASK_NATURE)))*0.1073f);
        // Hidden heal has zero SQL coefficients; native done/taken, crit and absorbs run once.
        p->CastCustomSpell(u,9003932,&amount,nullptr,nullptr,true);
    }
    bool AutoRecipient(Player* p,Unit* u)
    {
        if(!WD130A::Friendly(p,u)||!p->InSamePhase(u))return false;
        if(u==p)return true;
        if(u->GetTypeId()==TYPEID_PLAYER)return p->GetGroup()&&p->IsInRaidWith(u);
#ifdef MOD_NPCERBOTS
        if(u->IsNPCBot())return p->GetGroup()&&u->ToCreature()->GetBotGroup()==p->GetGroup();
#endif
        return false;
    }
    bool Emergency(Player* p)
    {
        if(p->GetHealthPct()<30.f)return true;
        if(auto* g=p->GetGroup())for(auto* r=g->GetFirstMember();r;r=r->next())
            if(auto* u=r->GetSource())if(AutoRecipient(p,u)&&u->GetHealthPct()<30.f)return true;
        return false;
    }
    bool OwnsChannel(Player* p)
    {
        Spell* spell=p?p->GetCurrentSpell(CURRENT_CHANNELED_SPELL):nullptr;
        return spell&&spell->GetSpellInfo()->Id==GetId()&&spell->m_targets.GetUnitTargetGUID()==GetTarget()->GetGUID();
    }
    void Stop(Player* p,char const* reason)
    {
        LOG_DEBUG("playerbots","WD182 {} spell={} stop={}",p->GetName(),GetId(),reason);
        p->InterruptSpell(CURRENT_CHANNELED_SPELL);
    }
    void Tick(AuraEffect const* effect)
    {
        PreventDefaultAction();
        Player* p=GetCaster()?GetCaster()->ToPlayer():nullptr;
        if(!IsDoctor(p) || !WD130A::Channel(p)) { Remove();return; }
        if(automatic)
        {
            // An obsolete Aura may not interrupt or drain a later/manual channel.
            if(!OwnsChannel(p)) {Remove();return;}
            auto plan=WD168::ReadPlan(p);
            if(!plan.available||plan.spec!=1) {Stop(p,"plan_changed");return;}
            if(Emergency(p)) {Stop(p,"emergency_retriage");return;}
        }
        branches.erase(std::remove_if(branches.begin(),branches.end(),[p,this](ObjectGuid g)
        {
            Unit* u=ObjectAccessor::GetUnit(*p,g);
            return !WD130A::Friendly(p,u)||(automatic&&(!AutoRecipient(p,u)||u->GetHealthPct()>=90.f));
        }),branches.end());
        if(branches.empty())
        {
            if(automatic)Stop(p,"no_injured_branch");else p->InterruptSpell(CURRENT_CHANNELED_SPELL);
            return;
        }
        static uint32 const mana[7]={101,139,186,231,316,429,470};
        ++ticks;
        uint32 cost=uint32(uint64(mana[GetId()-9003922])*branches.size()*(100+10*(ticks-1))/200);
        if(automatic&&!WD182::ContinueReserve(p->GetPower(POWER_MANA),p->GetMaxPower(POWER_MANA),cost))
        {Stop(p,"mana_reserve");return;}
        if(p->GetPower(POWER_MANA)<int32(cost)) { p->InterruptSpell(CURRENT_CHANNELED_SPELL);return; }
        p->ModifyPower(POWER_MANA,-int32(cost));
        // Only branches present at tick start sprout this round, so growth is bounded.
        auto previous=branches;
        for(ObjectGuid guid:previous)
        {
            if(!WD130A::Channel(p)) return;
            Heal(p,guid,effect->GetAmount());
            Unit* center=ObjectAccessor::GetUnit(*p,guid);
            if(!WD130A::Friendly(p,center) || (automatic&&!AutoRecipient(p,center)) || branches.size()>=8) continue;
            ObjectGuid added;
            for(Unit* ally:WD130A::Allies(p,center))
                if(std::find(branches.begin(),branches.end(),ally->GetGUID())==branches.end()&&
                   (!automatic||(AutoRecipient(p,ally)&&ally->GetHealthPct()<75.f)))
                { added=ally->GetGUID();break; }
            if(!added.IsEmpty()) { branches.push_back(added);Heal(p,added,effect->GetAmount()); }
        }
    }
    void Removed(AuraEffect const*,AuraEffectHandleModes)
    {
        if(Unit* p=GetCaster())
            if(!automatic||!WD130A::Channel(p)||OwnsChannel(p->ToPlayer()))p->RemoveAurasDueToSpell(9003929,p->GetGUID());
        branches.clear();
    }
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_reborn_wd130_beam::Apply,EFFECT_0,SPELL_AURA_PERIODIC_DUMMY,AURA_EFFECT_HANDLE_REAL);
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_reborn_wd130_beam::Tick,EFFECT_0,SPELL_AURA_PERIODIC_DUMMY);
        AfterEffectRemove += AuraEffectRemoveFn(aura_reborn_wd130_beam::Removed,EFFECT_0,SPELL_AURA_PERIODIC_DUMMY,AURA_EFFECT_HANDLE_REAL);
    }
};
// Channeled casts are deferred beyond the AI's prepare scope. Relay the Spell's
// snapshot to the actual applied Aura; querying the scope in Aura::Load is too late.
void spell_reborn_wd130_beam::MarkAutomation()
{
    if(Aura* aura=GetHitAura())
        if(auto* script=aura->GetScript<aura_reborn_wd130_beam>("aura_reborn_wd130_beam"))script->SetAutomatic(automatic);
}
class wd130_events : public AllSpellScript
{
public:
    wd130_events():AllSpellScript("wd130_events",{ALLSPELLHOOK_ON_CAST}) { }
    void OnSpellCast(Spell* spell,Unit* caster,SpellInfo const* info,bool) override
    {
        Player* p=caster?caster->ToPlayer():nullptr;
        if(!spell || spell->IsTriggered() || !info || !IsDoctor(p) || !p->IsAlive()) return;
        if(WD130A::Beam(info->Id)) WD132A::Restore(p);
        if(WD19A::IsBrew(info->Id) && p->HasAura(9003930)) WD130Local::Reduce(p,9003922,9003928,2000);
        if(WD130A::Bottle(info->Id) && p->HasAura(9003931)) p->CastSpell(p,9003574,true);
    }
};
