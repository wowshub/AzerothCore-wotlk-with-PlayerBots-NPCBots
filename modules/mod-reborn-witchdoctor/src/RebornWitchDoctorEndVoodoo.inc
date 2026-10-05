// WD98A: private IDs and per-cast summon GUIDs; no global player pointers.
namespace WD98A
{
constexpr uint32 Golem=9003800, Malicious=9003801, Vigil=9003802;
constexpr uint32 Marionette=9003810, Stacks=9003811, Transform=9003812, Explosion=9003813, Clone=9003814;
constexpr uint32 GolemNpc=9003800, CloneNpc=9003801;
struct State : DataMap::Base { ObjectGuid golem; };
State* StateFor(Player* p) { return p->CustomData.GetDefault<State>("RebornWD98.Summons"); }
bool Owned(Player* p,uint32 id) { return IsDoctor(p) && p->IsAlive() && p->HasSpell(id) && p->HasAura(id,p->GetGUID()); }
class spell_wd98_active : public SpellScript
{
    PrepareSpellScript(spell_wd98_active);
    SpellCastResult Check()
    {
        Player* p=GetCaster()->ToPlayer();
        return IsDoctor(p) && p->IsAlive() && p->GetLevel()>=59 && p->HasSpell(GetSpellInfo()->Id) ? SPELL_CAST_OK : SPELL_FAILED_CASTER_AURASTATE;
    }
    void Register() override { OnCheckCast += SpellCheckCastFn(spell_wd98_active::Check); }
};
class npc_wd98_summon : public ScriptedAI
{
public:
    explicit npc_wd98_summon(Creature* c) : ScriptedAI(c) { }
    void IsSummonedBy(WorldObject* object) override
    {
        Player* p=object ? object->ToPlayer() : nullptr;
        if(!IsDoctor(p)) { me->DespawnOrUnsummon();return; }
        me->SetOwnerGUID(p->GetGUID());me->SetCreatorGUID(p->GetGUID());
        me->SetFaction(p->GetFaction());me->SetLevel(p->GetLevel());
        me->SetReactState(REACT_PASSIVE);me->SetCombatMovement(false);
        uint32 health=me->GetEntry()==GolemNpc ? std::max(100u,uint32(p->GetStat(STAT_INTELLECT)*8)) : std::max(5u,uint32(p->GetLevel())*10);
        me->SetMaxHealth(health);me->SetHealth(health);
        if(me->GetEntry()==CloneNpc)
        {
            // WD101: this is visual initialization of our own temporary summon,
            // not another cast from the player during Marionette's aura apply.
            // Keep the real caster on aura 247: the mirror-image packet uses it
            // to copy the player's face, hair and equipped item displays.
            me->SetNativeDisplayId(p->GetDisplayId());
            if (!p->AddAura(Clone,me))
                LOG_ERROR("scripts", "WD101: Soul Clone aura {} failed for summon {}", Clone, me->GetGUID().ToString());
            me->SetDisplayId(p->GetDisplayId(),p->GetObjectScale());
            me->SetFacingToObject(p);me->SetUInt32Value(UNIT_NPC_EMOTESTATE,EMOTE_STATE_SPELL_CHANNEL_OMNI);
        }
    }
    void JustDied(Unit*) override
    {
        if(me->GetEntry()!=GolemNpc) return;
        if(Player* p=ObjectAccessor::GetPlayer(*me,me->GetOwnerGUID()))
            if(StateFor(p)->golem==me->GetGUID()) p->RemoveAurasDueToSpell(Golem,p->GetGUID());
    }
    void UpdateAI(uint32) override
    {
        Player* p=ObjectAccessor::GetPlayer(*me,me->GetOwnerGUID());
        uint32 active=me->GetEntry()==GolemNpc ? Golem : Marionette;
        if(!Owned(p,active)) me->DespawnOrUnsummon();
    }
};
class aura_wd98_golem : public AuraScript
{
    PrepareAuraScript(aura_wd98_golem);
    ObjectGuid guid;
    void Amount(AuraEffect const*,int32& amount,bool& recalculate)
    {
        Unit* unit=GetUnitOwner();Player* p=unit ? unit->ToPlayer() : nullptr;
        amount=IsDoctor(p) ? std::max(1,int32(p->GetStat(STAT_INTELLECT)*8)) : 0;recalculate=false;
    }
    void Apply(AuraEffect const*,AuraEffectHandleModes)
    {
        Player* p=GetTarget()->ToPlayer();if(!Owned(p,Golem)) return;
        State* state=StateFor(p);
        if(Creature* old=ObjectAccessor::GetCreature(*p,state->golem)) old->DespawnOrUnsummon();
        state->golem.Clear();
        Position pos=p->GetNearPosition(2.0f,0.0f);
        if(TempSummon* summon=p->SummonCreature(GolemNpc,pos,TEMPSUMMON_TIMED_DESPAWN,10000))
        {
            guid=summon->GetGUID();state->golem=guid;
            if(Owned(p,Malicious)) p->CastSpell(p,Vigil,true);
        }
    }
    void Absorb(AuraEffect*,DamageInfo&,uint32& absorb)
    {
        Player* p=GetTarget()->ToPlayer();Creature* c=p ? ObjectAccessor::GetCreature(*p,guid) : nullptr;
        if(!Owned(p,Golem) || !c || !c->IsAlive() || c->GetOwnerGUID()!=p->GetGUID()) absorb=0;
    }
    void Remove(AuraEffect const*,AuraEffectHandleModes)
    {
        Player* p=GetTarget()->ToPlayer();if(!p) return;
        if(StateFor(p)->golem==guid) StateFor(p)->golem.Clear();
        if(Creature* c=ObjectAccessor::GetCreature(*p,guid)) c->DespawnOrUnsummon();
    }
    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_wd98_golem::Amount,EFFECT_1,SPELL_AURA_SCHOOL_ABSORB);
        AfterEffectApply += AuraEffectApplyFn(aura_wd98_golem::Apply,EFFECT_0,SPELL_AURA_DUMMY,AURA_EFFECT_HANDLE_REAL);
        OnEffectAbsorb += AuraEffectAbsorbFn(aura_wd98_golem::Absorb,EFFECT_1);
        AfterEffectRemove += AuraEffectRemoveFn(aura_wd98_golem::Remove,EFFECT_0,SPELL_AURA_DUMMY,AURA_EFFECT_HANDLE_REAL);
    }
};
class aura_wd98_malicious : public AuraScript
{
    PrepareAuraScript(aura_wd98_malicious);
    bool Check(ProcEventInfo& e)
    {
        Player* p=GetTarget()->ToPlayer();SpellInfo const* info=e.GetSpellInfo();
        if(!Owned(p,Malicious) || GetCasterGUID()!=p->GetGUID() || e.GetActor()!=p || !info || !e.GetDamageInfo() || !e.GetDamageInfo()->GetDamage()) return false;
        bool hex=info->Id==9003104 || (info->Id>=9003106 && info->Id<=9003112);
        return info->Id==WD68A::PuppetHit || (hex && (e.GetTypeMask()&PROC_FLAG_DONE_PERIODIC));
    }
    void Proc(ProcEventInfo& e)
    {
        PreventDefaultAction();if(!Check(e)) return;
        Player* p=GetTarget()->ToPlayer();uint32 delay=p->GetSpellCooldownDelay(Golem);
        if(delay) p->ModifySpellCooldown(Golem,-int32(std::min(delay,500u)));
    }
    void Register() override { DoCheckProc += AuraCheckProcFn(aura_wd98_malicious::Check);OnProc += AuraProcFn(aura_wd98_malicious::Proc); }
};
class aura_wd98_marionette : public AuraScript
{
    PrepareAuraScript(aura_wd98_marionette);
    std::vector<ObjectGuid> clones;
    bool completed=false;
    void Apply(AuraEffect const*,AuraEffectHandleModes)
    {
        Player* p=GetTarget()->ToPlayer();if(!Owned(p,Marionette)) return;
        p->RemoveAurasDueToSpell(Stacks,p->GetGUID());
        for(uint32 i=0;i<5;++i)
        {
            Position pos=p->GetNearPosition(2.5f,float(i)*6.2831853f/5.0f);
            if(TempSummon* c=p->SummonCreature(CloneNpc,pos,TEMPSUMMON_TIMED_DESPAWN,8500)) clones.push_back(c->GetGUID());
        }
    }
    void Tick(AuraEffect const*)
    {
        Player* p=GetTarget()->ToPlayer();if(completed || !Owned(p,Marionette)) return;
        for(ObjectGuid guid:clones)
            if(Creature* c=ObjectAccessor::GetCreature(*p,guid);c && c->IsAlive() && c->GetOwnerGUID()==p->GetGUID()) p->CastSpell(p,Stacks,true);
        Aura* stacks=p->GetAura(Stacks,p->GetGUID());if(!stacks || stacks->GetStackAmount()<20) return;
        completed=true;p->RemoveAurasDueToSpell(Stacks,p->GetGUID());p->CastSpell(p,Transform,true);
        for(ObjectGuid guid:clones)
            if(Creature* c=ObjectAccessor::GetCreature(*p,guid);c && c->IsAlive() && c->GetOwnerGUID()==p->GetGUID())
            {
                // Owner is the damage caster; each destination is the corresponding clone.
                p->CastSpell(c->GetPositionX(),c->GetPositionY(),c->GetPositionZ(),Explosion,true);
                c->DespawnOrUnsummon();
            }
    }
    void Remove(AuraEffect const*,AuraEffectHandleModes)
    {
        Player* p=GetTarget()->ToPlayer();if(!p) return;
        for(ObjectGuid guid:clones) if(Creature* c=ObjectAccessor::GetCreature(*p,guid)) c->DespawnOrUnsummon();
        p->RemoveAurasDueToSpell(Stacks,p->GetGUID());
    }
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_wd98_marionette::Apply,EFFECT_0,SPELL_AURA_MOD_ROOT,AURA_EFFECT_HANDLE_REAL);
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_wd98_marionette::Tick,EFFECT_1,SPELL_AURA_PERIODIC_DUMMY);
        AfterEffectRemove += AuraEffectRemoveFn(aura_wd98_marionette::Remove,EFFECT_0,SPELL_AURA_MOD_ROOT,AURA_EFFECT_HANDLE_REAL);
    }
};
class spell_wd98_explosion : public SpellScript
{
    PrepareSpellScript(spell_wd98_explosion);
    void Scale(SpellEffIndex)
    {
        Player* p=GetCaster()->ToPlayer();
        SetEffectValue(IsDoctor(p) ? GetEffectValue()+int32(.5f*std::max(0,p->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_SHADOW))) : 0);
    }
    void Register() override { OnEffectLaunchTarget += SpellEffectFn(spell_wd98_explosion::Scale,EFFECT_0,SPELL_EFFECT_SCHOOL_DAMAGE); }
};
class ExactMods : public GlobalScript
{
public:
    ExactMods() : GlobalScript("reborn_wd98_exact_mods") { }
    bool OnIsAffectedBySpellModCheck(SpellInfo const*,SpellInfo const* check,SpellModifier const* mod) override
    {
        if(!check || !mod || mod->spellId!=Transform) return true;
        bool family=check->Id==9003822 || check->Id==9003100 || (check->Id>=9003120 && check->Id<=9003127) || WD48A::Juju(check->Id);
        return !(family && (mod->op==SPELLMOD_DAMAGE || mod->op==SPELLMOD_CRITICAL_CHANCE));
    }
};
void Register()
{
    RegisterSpellScript(spell_wd98_active);RegisterSpellScript(aura_wd98_golem);
    RegisterSpellScript(aura_wd98_malicious);RegisterSpellScript(aura_wd98_marionette);RegisterSpellScript(spell_wd98_explosion);
    RegisterCreatureAI(npc_wd98_summon);new ExactMods();
}
}
