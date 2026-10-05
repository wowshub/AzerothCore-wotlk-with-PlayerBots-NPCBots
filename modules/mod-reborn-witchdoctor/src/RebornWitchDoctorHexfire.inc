// WD99A: Hexfire Adept; included after WD98, with native transient replacement packets.
namespace WD99A
{
constexpr uint32 Adept=9003820, Ready=9003821, Wrath=9003822, WardNpc=9003823;
struct State : DataMap::Base { uint32 original=0; uint64 generation=0; };
State* Data(Player* p) { return p->CustomData.GetDefault<State>("RebornWD99.Hexfire"); }
bool Owned(Player* p) { return IsDoctor(p) && p->IsAlive() && p->GetLevel()>=50 && p->HasSpell(Adept) && p->HasAura(Adept,p->GetGUID()); }
float Power(Player* p)
{
    return float(std::max(0,std::max(p->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_FIRE),p->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_NATURE))));
}
void Restore(Player* p)
{
    State* state=Data(p);
    if(state->original) p->SetTemporarySpellReplacement(state->original,0);
    state->original=0;
}
class aura_wd99_ready : public AuraScript
{
    PrepareAuraScript(aura_wd99_ready);
    void Apply(AuraEffect const*,AuraEffectHandleModes)
    {
        Player* p=GetTarget()->ToPlayer();if(!Owned(p)) return;
        Restore(p);
        uint32 best=0;
        for(auto const& rank:WD19A::WrathRanks) if(p->HasActiveSpell(rank.spell)) best=rank.spell;
        if(!best) return;
        if(!p->HasSpell(Wrath)) p->learnSpell(Wrath,true);
        Data(p)->original=best;p->SetTemporarySpellReplacement(best,Wrath);
    }
    void Remove(AuraEffect const*,AuraEffectHandleModes) { if(Player* p=GetTarget()->ToPlayer()) Restore(p); }
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_wd99_ready::Apply,EFFECT_0,SPELL_AURA_DUMMY,AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_wd99_ready::Remove,EFFECT_0,SPELL_AURA_DUMMY,AURA_EFFECT_HANDLE_REAL);
    }
};
class spell_wd99_generate : public SpellScript
{
    PrepareSpellScript(spell_wd99_generate);
    void Done()
    {
        Player* p=GetCaster()->ToPlayer();
        if(!GetSpell()->IsTriggered() && Owned(p) && WD48A::Fire(GetSpellInfo()->Id))
        { ++Data(p)->generation;p->CastSpell(p,Ready,true); }
    }
    void Register() override { AfterCast += SpellCastFn(spell_wd99_generate::Done); }
};
class npc_wd99_serpent : public ScriptedAI
{
public:
    explicit npc_wd99_serpent(Creature* c):ScriptedAI(c) { }
    ObjectGuid target;
    uint32 timer=2000;
    void SetGUID(ObjectGuid const& id,int32) override { target=id; }
    void IsSummonedBy(WorldObject* object) override
    {
        Player* p=object?object->ToPlayer():nullptr;
        if(!Owned(p)) { me->DespawnOrUnsummon();return; }
        me->SetOwnerGUID(p->GetGUID());me->SetCreatorGUID(p->GetGUID());me->SetFaction(p->GetFaction());me->SetLevel(p->GetLevel());
        me->SetMaxHealth(std::max(5u,uint32(p->GetLevel())*10));me->SetHealth(me->GetMaxHealth());
        me->SetReactState(REACT_PASSIVE);me->SetCombatMovement(false);
    }
    void AttackStart(Unit*) override { }
    void MoveInLineOfSight(Unit*) override { }
    void JustDied(Unit*) override { me->DespawnOrUnsummon(); }
    void UpdateAI(uint32 diff) override
    {
        Player* p=ObjectAccessor::GetPlayer(*me,me->GetOwnerGUID());
        if(!Owned(p) || !p->IsInMap(me) || !p->InSamePhase(me)) { me->DespawnOrUnsummon();return; }
        if(timer>diff) { timer-=diff;return; } timer=2000;
        Unit* victim=ObjectAccessor::GetUnit(*me,target);
        if(!victim || !victim->IsAlive() || !p->IsValidAttackTarget(victim) || !me->InSamePhase(victim) ||
            !me->IsWithinDistInMap(victim,30.0f) || !me->IsWithinLOSInMap(victim) || victim->HasBreakableByDamageCrowdControlAura()) return;
        me->SetFacingToObject(victim);me->CastSpell(victim,WD21A::Attack,true,nullptr,nullptr,p->GetGUID());
    }
};
class spell_wd99_wrath : public SpellScript
{
    PrepareSpellScript(spell_wd99_wrath);
    bool accepted=false,done=false;
    uint64 generation=0;
    SpellCastResult Check()
    {
        Player* p=WD68A::Caster(GetCaster());
        if(!Owned(p)) return SPELL_FAILED_CASTER_AURASTATE;
        if(GetSpell()->IsTriggered()) return SPELL_CAST_OK; // bounded copies from this successful cast
        if(!accepted)
        {
            if(!p->HasAura(Ready,p->GetGUID())) return SPELL_FAILED_CASTER_AURASTATE;
            accepted=true;generation=Data(p)->generation;
        }
        return SPELL_CAST_OK;
    }
    void Scale(SpellEffIndex)
    {
        Player* p=WD68A::Caster(GetCaster());if(!Owned(p)) return;
        SetEffectValue(GetEffectValue()+int32(.75f*Power(p)*WD84A::PowerScale(p)));
    }
    void Done()
    {
        Player* p=GetCaster()->ToPlayer();Unit* primary=GetExplTargetUnit();
        if(done || GetSpell()->IsTriggered() || !Owned(p) || !primary) return;
        done=true;
        // Choose and freeze GUIDs before any triggered effects can change the world.
        std::list<Unit*> units;
        Acore::AnyUnitInObjectRangeCheck check(primary,10.0f);
        Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(primary,units,check);
        Cell::VisitObjects(primary,search,10.0f);
        units.remove_if([&](Unit* u) { return u==primary || !u->IsAlive() || !u->IsInWorld() || !p->IsInMap(u) || !p->InSamePhase(u) || !primary->IsWithinDistInMap(u,10.0f) || !p->IsValidAttackTarget(u) || !p->IsWithinLOSInMap(u); });
        units.sort([primary](Unit* a,Unit* b) { float da=primary->GetExactDistSq(a),db=primary->GetExactDistSq(b);return da==db?a->GetGUID()<b->GetGUID():da<db; });
        std::vector<ObjectGuid> targets;
        for(Unit* u:units) { if(targets.size()==2) break;targets.push_back(u->GetGUID()); }
        Position pos=primary->GetPosition();ObjectGuid main=primary->GetGUID();
        for(ObjectGuid id:targets)
            if(Unit* u=ObjectAccessor::GetUnit(*p,id))
                if(Owned(p) && u->IsAlive() && p->IsInMap(u) && p->InSamePhase(u) && p->IsValidAttackTarget(u) && p->IsWithinLOSInMap(u)) p->CastSpell(u,Wrath,true);
        if(Owned(p))
            if(TempSummon* ward=p->SummonCreature(WardNpc,pos,TEMPSUMMON_TIMED_DESPAWN,10000)) ward->AI()->SetGUID(main,0);
        if(Unit* u=ObjectAccessor::GetUnit(*p,main)) WD68A::Mirror(p,u,Wrath);
        // A newer Hexfire during this cast must not lose its new readiness.
        if(Data(p)->generation==generation) p->RemoveAurasDueToSpell(Ready,p->GetGUID());
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_wd99_wrath::Check);
        OnEffectLaunchTarget += SpellEffectFn(spell_wd99_wrath::Scale,EFFECT_0,SPELL_EFFECT_SCHOOL_DAMAGE);
        AfterCast += SpellCastFn(spell_wd99_wrath::Done);
    }
};
class Lifecycle : public PlayerScript
{
public:
    Lifecycle():PlayerScript("reborn_wd99_lifecycle") { }
    void OnPlayerLogin(Player* p) override { if(IsDoctor(p)) { p->RemoveAurasDueToSpell(Ready,p->GetGUID());Restore(p); } }
    void OnPlayerLogout(Player* p) override { if(IsDoctor(p)) { p->RemoveAurasDueToSpell(Ready,p->GetGUID());Restore(p); } }
};
void Register()
{
    RegisterSpellScript(aura_wd99_ready);RegisterSpellScript(spell_wd99_generate);
    RegisterSpellScript(spell_wd99_wrath);
    RegisterCreatureAI(npc_wd99_serpent);new Lifecycle();
}
}
