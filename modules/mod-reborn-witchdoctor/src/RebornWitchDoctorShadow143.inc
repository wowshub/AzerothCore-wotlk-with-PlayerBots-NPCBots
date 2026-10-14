// WD143: isolated Shadowhunting starter mechanics. Source contracts recorded in research.
namespace WD143
{
constexpr uint32 Identity=9003967, ArrowTalent=9003968, Heal=9003969, AutoShot=9003989;
bool Owns(Player* p) { return IsDoctor(p) && p->IsAlive() && p->HasSpell(Identity); }
class auto_shot : public SpellScript
{
    PrepareSpellScript(auto_shot);
    SpellCastResult Check()
    {
        Player* p=GetCaster()->ToPlayer();
        return Owns(p) && p->HasSpell(AutoShot) ? SPELL_CAST_OK : SPELL_FAILED_CASTER_AURASTATE;
    }
    void Register() override { OnCheckCast += SpellCheckCastFn(auto_shot::Check); }
};
class arrow : public SpellScript
{
    PrepareSpellScript(arrow);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({Identity,ArrowTalent,Heal}); }
    SpellCastResult Check()
    {
        Player* p=GetCaster()->ToPlayer();
        return Owns(p) && p->HasSpell(ArrowTalent) && p->HasSpell(GetSpellInfo()->Id) ? SPELL_CAST_OK : SPELL_FAILED_CASTER_AURASTATE;
    }
    void Damage(SpellEffIndex)
    {
        Player* p=GetCaster()->ToPlayer();
        if(!Owns(p)) { SetEffectValue(0);return; }
        float extra=0.20f*std::max(0.0f,p->GetTotalAttackPowerValue(RANGED_ATTACK))+
            0.25f*std::max(0,p->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_NATURE));
        SetEffectValue(GetEffectValue()+int32(extra));
    }
    void Hit()
    {
        Player* p=GetCaster()->ToPlayer();
        if(!Owns(p) || GetHitDamage()<=0) return;
        SpellInfo const* info=sSpellMgr->GetSpellInfo(Heal);
        uint32 amount=uint64(GetHitDamage())*40/100;
        amount=p->SpellHealingBonusTaken(p,info,amount,HEAL);
        HealInfo heal(p,p,amount,info,info->GetSchoolMask());Unit::CalcHealAbsorb(heal);p->HealBySpell(heal,false);
        p->GetThreatMgr().ForwardThreatForAssistingMe(p,float(heal.GetEffectiveHeal())*.5f,info);
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(arrow::Check);
        OnEffectHitTarget += SpellEffectFn(arrow::Damage,EFFECT_0,SPELL_EFFECT_SCHOOL_DAMAGE);
        AfterHit += SpellHitFn(arrow::Hit);
    }
};
class reclamation : public SpellScript
{
    PrepareSpellScript(reclamation);
    uint32 spiritsBefore=0;
    void Snapshot() { spiritsBefore=WD145::Count(GetCaster()->ToPlayer()); }
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({Identity,9003574}); }
    SpellCastResult Check()
    {
        Player* p=GetCaster()->ToPlayer();
        return Owns(p) && p->HasSpell(GetSpellInfo()->Id) ? SPELL_CAST_OK : SPELL_FAILED_CASTER_AURASTATE;
    }
    void Cast()
    {
        Player* p=GetCaster()->ToPlayer();
        if(!Owns(p) || GetSpell()->IsTriggered()) return;
        p->CastSpell(p,9003574,true);
        Unit* target=GetExplTargetUnit();
        if(WD145::Owns(p,WD145::Loa) && p->HasAura(WD145::Loa,p->GetGUID()) && target && target->IsAlive() &&
           p->IsValidAttackTarget(target) && p->IsWithinDistInMap(target,30.0f) && p->IsWithinLOSInMap(target) && roll_chance_i(spiritsBefore*5))
            p->CastSpell(target,GetSpellInfo()->Id,true); // one echo; triggered casts never recurse or gain spirits

    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(reclamation::Check);
        BeforeCast += SpellCastFn(reclamation::Snapshot);
        AfterCast += SpellCastFn(reclamation::Cast);
    }
};
}
namespace WD143Bridge
{
void Apply(Player* p,bool identity,bool arrow,bool reclaim)
{
    if(!IsDoctor(p)) return;
    bool wasArrow=p->HasSpell(WD143::ArrowTalent);
    if(!identity)
        if(Spell* shot=p->GetCurrentSpell(CURRENT_AUTOREPEAT_SPELL))
            if(shot->GetSpellInfo()->Id==WD143::AutoShot) p->InterruptSpell(CURRENT_AUTOREPEAT_SPELL);
    // Capture action identities before removeSpell can clear their buttons.
    uint32 actions[MAX_ACTION_BUTTONS]={};
    for(uint8 b=0;b<MAX_ACTION_BUTTONS;++b)
        if(ActionButton const* a=p->GetActionButton(b))
            if(a->GetType()==ACTION_BUTTON_SPELL) actions[b]=a->GetAction();
    auto set=[p](uint32 id,bool enabled) {
        if(enabled) { if(!p->HasSpell(id)) p->learnSpell(id); }
        else { p->RemoveAurasDueToSpell(id,p->GetGUID());if(p->HasSpell(id)) p->removeSpell(id,3,false); }
    };
    set(WD143::Identity,identity);set(WD143::ArrowTalent,identity&&arrow);
    set(WD143::AutoShot,identity);
    // Weapon training is permanent class knowledge; never erase outside ownership.
    if(identity)
        for(uint32 training:{264u,266u,5011u})
            if(!p->HasSpell(training)) p->learnSpell(training);
    uint32 bestArrow=0,bestReclaim=0;
    for(auto const& r:WD19A::Arrow143Ranks) if(identity&&arrow&&p->GetLevel()>=r.level) bestArrow=r.spell;
    for(auto const& r:WD19A::Reclamation143Ranks) if(identity&&reclaim&&p->GetLevel()>=r.level) bestReclaim=r.spell;
    for(auto const& r:WD19A::Arrow143Ranks) set(r.spell,r.spell==bestArrow);
    for(auto const& r:WD19A::Reclamation143Ranks) set(r.spell,r.spell==bestReclaim);
    if(bestArrow) for(auto const& r:WD19A::WrathRanks) set(r.spell,false);
    else if(wasArrow) SyncRanks(p); // Restore the purchase ledger only on leaving the replacement.
    bool changed=false;
    for(uint8 b=0;b<MAX_ACTION_BUTTONS;++b)
    {
        uint32 id=actions[b],next=id;
        if(WD19A::IsWrath(id) && id!=9003822) next=bestArrow?bestArrow:WD19A::ResolveAction(p,id);
        else if(id>=9003970&&id<=9003978) next=bestArrow?bestArrow:WD19A::ResolveAction(p,9003100);
        else if(id>=9003980&&id<=9003988) next=bestReclaim;
        else continue;
        ActionButton const* now=p->GetActionButton(b);
        if(now && now->GetType()==ACTION_BUTTON_SPELL && now->GetAction()==next) continue;
        p->removeActionButton(b);if(next) p->addActionButton(b,next,ACTION_BUTTON_SPELL);changed=true;
    }
    if(changed) p->SendActionButtons(1);
}
}
