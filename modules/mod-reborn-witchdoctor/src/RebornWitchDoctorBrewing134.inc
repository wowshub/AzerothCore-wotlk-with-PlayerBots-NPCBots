// WD134: saved-build cauldron + caster-owned Unstable Concoction.
namespace WD134
{
constexpr uint32 Cauldron=9003947,Field=9003948,Pulse=9003949,Unstable=9003950,Mark=9003951,Burst=9003952,Entry=900231;
struct State : DataMap::Base { ObjectGuid guid; };
constexpr char Key[]="Reborn.WD134.Cauldron";
bool Ally(Player* p,Unit* center,Unit* u,float radius)
{
    if(!p || !p->IsAlive() || !p->IsInWorld() || !u || !u->IsAlive() || !u->IsInWorld() || !p->IsFriendlyTo(u) || !center->InSamePhase(u) ||
       !center->IsWithinDistInMap(u,radius) || !center->IsWithinLOSInMap(u)) return false;
    if(u==p || p->IsInRaidWith(u)) return true;
#ifdef MOD_NPCERBOTS
    if(u->IsNPCBot()) return p->GetGroup() && u->ToCreature()->GetBotGroup()==p->GetGroup();
#endif
    return false;
}
std::vector<ObjectGuid> Allies(Player* p,Unit* center,float radius,uint32 cap=0)
{
    std::list<Unit*> units;
    Acore::AnyUnitInObjectRangeCheck check(center,radius);
    Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(center,units,check);
    Cell::VisitObjects(center,search,radius);
    if(Ally(p,center,center,radius)) units.push_back(center);
    if(Ally(p,center,p,radius)) units.push_back(p);
    units.remove_if([=](Unit* u){return !Ally(p,center,u,radius);});
    units.sort([](Unit* a,Unit* b){if(a->GetHealthPct()!=b->GetHealthPct()) return a->GetHealthPct()<b->GetHealthPct();return a->GetGUID()<b->GetGUID();});
    units.unique([](Unit* a,Unit* b){return a->GetGUID()==b->GetGUID();});
    if(cap && units.size()>cap) units.resize(cap);
    std::vector<ObjectGuid> out;for(Unit* u:units) out.push_back(u->GetGUID());return out;
}
void Clear(Player* p)
{
    State* s=p->CustomData.GetDefault<State>(Key);
    if(Creature* c=ObjectAccessor::GetCreature(*p,s->guid))
        if(c->GetEntry()==Entry && c->GetOwnerGUID()==p->GetGUID()) c->DespawnOrUnsummon();
    s->guid.Clear();
}
}
class spell_reborn_wd134_cauldron : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd134_cauldron);
    bool Validate(SpellInfo const*) override{return ValidateSpellInfo({WD134::Cauldron,WD134::Field,WD134::Pulse});}
    SpellCastResult Check()
    {
        Player* p=GetCaster()->ToPlayer();
        if(!IsDoctor(p) || !p->IsAlive() || !p->HasSpell(WD134::Cauldron) || p->GetLevel()<57) return SPELL_FAILED_CASTER_AURASTATE;
        return sObjectMgr->GetCreatureTemplate(WD134::Entry)?SPELL_CAST_OK:SPELL_FAILED_ERROR;
    }
    void Summon(SpellEffIndex)
    {
        Player* p=GetCaster()->ToPlayer();if(!IsDoctor(p)) return;
        Position pos=p->GetPosition();p->MovePositionToFirstCollision(pos,1.5f,0.0f);
        if(TempSummon* c=p->SummonCreature(WD134::Entry,pos,TEMPSUMMON_MANUAL_DESPAWN,0))
        { WD134::Clear(p);p->CustomData.GetDefault<WD134::State>(WD134::Key)->guid=c->GetGUID(); }
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_wd134_cauldron::Check);
        OnEffectHitTarget += SpellEffectFn(spell_reborn_wd134_cauldron::Summon,EFFECT_0,SPELL_EFFECT_DUMMY);
    }
};
class npc_reborn_wd134_cauldron : public CreatureScript
{
public:
    npc_reborn_wd134_cauldron():CreatureScript("npc_reborn_wd134_cauldron"){}
    struct AI : ScriptedAI
    {
        explicit AI(Creature* c):ScriptedAI(c){}
        ObjectGuid owner;uint32 age=0,fieldTimer=0,healTimer=1500;
        void IsSummonedBy(WorldObject* summoner) override
        {
            Player* p=summoner?summoner->ToPlayer():nullptr;
            if(!IsDoctor(p)){me->DespawnOrUnsummon();return;}
            owner=p->GetGUID();me->SetOwnerGUID(owner);me->SetCreatorGUID(owner);me->SetFaction(p->GetFaction());me->SetLevel(p->GetLevel());
            me->SetReactState(REACT_PASSIVE);me->SetCombatMovement(false);me->setActive(true);
            me->SetUnitFlag(UNIT_FLAG_NON_ATTACKABLE);me->SetUnitFlag(UNIT_FLAG_NOT_SELECTABLE);
        }
        void AttackStart(Unit*) override{}
        void MoveInLineOfSight(Unit*) override{}
        void UpdateAI(uint32 diff) override
        {
            Player* p=ObjectAccessor::GetPlayer(*me,owner);
            if(!IsDoctor(p) || !p->IsAlive() || !p->HasSpell(WD134::Cauldron) || !p->IsInMap(me) || !p->InSamePhase(me) ||
               p->CustomData.GetDefault<WD134::State>(WD134::Key)->guid!=me->GetGUID()) {me->DespawnOrUnsummon();return;}
            age+=std::min(diff,15000u);
            bool pulse=healTimer<=diff;healTimer=pulse?1500-std::min(diff-healTimer,1499u):healTimer-diff;
            if(fieldTimer<=diff || pulse)
            {
                fieldTimer=250;
                auto recipients=WD134::Allies(p,me,15.0f);
                for(ObjectGuid guid:recipients) if(Unit* u=ObjectAccessor::GetUnit(*me,guid)) if(WD134::Ally(p,me,u,15.0f))
                {
                    // Short leases remove the field on range exit/despawn/logout without stale external pointers.
                    if(!u->HasAura(WD134::Field) || u->HasAura(WD134::Field,me->GetGUID())) me->CastSpell(u,WD134::Field,true);
                    if(Aura* a=u->GetAura(WD134::Field,me->GetGUID())) {a->SetMaxDuration(500);a->SetDuration(500);}
                    if(pulse) p->CastSpell(u,WD134::Pulse,true);
                }
            }
            else fieldTimer-=diff;
            if(age>=15000) me->DespawnOrUnsummon();
        }
    };
    CreatureAI* GetAI(Creature* c) const override{return new AI(c);}
};
class player_reborn_wd134_lifecycle : public PlayerScript
{
public:
    player_reborn_wd134_lifecycle():PlayerScript("player_reborn_wd134_lifecycle"){}
    void OnPlayerLogout(Player* p) override {if(IsDoctor(p)) WD134::Clear(p);}
    void OnPlayerMapChanged(Player* p) override {if(IsDoctor(p)) WD134::Clear(p);}
};
class spell_reborn_wd134_unstable : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd134_unstable);
    bool Validate(SpellInfo const*) override{return ValidateSpellInfo({WD134::Unstable,WD134::Mark,WD134::Burst});}
    void Hit()
    {
        Player* p=GetCaster()->ToPlayer();Unit* target=GetHitUnit();uint32 id=GetSpellInfo()->Id;
        if(!IsDoctor(p) || !p->IsAlive() || !p->HasSpell(WD134::Unstable) || !p->HasAura(WD134::Unstable,p->GetGUID()) ||
           !target || !target->IsAlive() || !p->IsFriendlyTo(target) || GetSpell()->IsTriggered()) return;
        if(WD120A::IsToss(id)) {p->CastSpell(target,WD134::Mark,true);return;}
        if(!WD19A::IsBrew(id) && !WD130A::Bottle(id)) return;
        Aura* mark=target->GetAura(WD134::Mark,p->GetGUID());if(!mark) return;
        mark->Remove(); // Consume once before any healing proc can reenter.
        auto recipients=WD134::Allies(p,target,20.0f,5);
        for(ObjectGuid guid:recipients) if(Unit* u=ObjectAccessor::GetUnit(*p,guid))
            if(WD134::Ally(p,target,u,20.0f)) p->CastSpell(u,WD134::Burst,true);
    }
    void Register() override { AfterHit += SpellHitFn(spell_reborn_wd134_unstable::Hit); }
};
class spell_reborn_wd134_heal : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd134_heal);
    void Amount(SpellEffIndex)
    {
        Player* p=GetCaster()->ToPlayer();if(!IsDoctor(p)) return;
        float coefficient=GetSpellInfo()->Id==WD134::Pulse?0.60f:0.40f;
        SetEffectValue(int32(float(GetEffectValue())+float(std::max(0,p->SpellBaseHealingBonusDone(SPELL_SCHOOL_MASK_NATURE)))*coefficient));
    }
    void Register() override { OnEffectLaunchTarget += SpellEffectFn(spell_reborn_wd134_heal::Amount,EFFECT_0,SPELL_EFFECT_HEAL); }
};
