// WD145: a bounded Spirit/Reclamation extension; no new resource pool.
namespace WD145
{
constexpr uint32 Spirit=9003574,Loa=9004010,Devotee=9004011,Wisdom=9004012,Hit=9004020,Splash=9004021,Mana=9004022;
bool Eclipse(uint32 id) { return id>=9004000 && id<=9004006; }
bool Reclaim(uint32 id) { return id>=9003980 && id<=9003988; }
bool Owns(Player* p,uint32 id) { return IsDoctor(p) && p->IsAlive() && p->HasSpell(9003967) && p->HasSpell(id); }
uint32 Count(Player* p) { Aura* a=p?p->GetAura(Spirit,p->GetGUID()):nullptr;return a?std::min<uint32>(5,a->GetStackAmount()):0; }
class modifiers : public GlobalScript
{
public:
    modifiers():GlobalScript("reborn_wd145_modifiers"){}
    bool OnIsAffectedBySpellModCheck(SpellInfo const*,SpellInfo const* check,SpellModifier const* mod) override
    {
        if(mod && check && mod->spellId==Wisdom && mod->op==SPELLMOD_DAMAGE) return !Reclaim(check->Id);
        return true;
    }
};
class spirit_gain : public SpellScript
{
    PrepareSpellScript(spirit_gain);
    void HitSpirit()
    {
        Player* p=GetCaster()->ToPlayer();
        if(Owns(p,Devotee) && GetHitUnit()==p && p->HasAura(Devotee,p->GetGUID()) && GetHitAura())
            p->CastSpell(p,Mana,true);
    }
    void Register() override { AfterHit += SpellHitFn(spirit_gain::HitSpirit); }
};
class eclipse_aura : public AuraScript
{
    PrepareAuraScript(eclipse_aura);
    public:
    // Per-aura provenance: a manual reapplication clears any previous automatic flag.
    bool automatic=false;
private:
    uint32 remaining=0,damage=0,splash=0;
    bool npc=false;uint32 npcOwner=0,npcMap=0;
    void Apply(AuraEffect const* effect,AuraEffectHandleModes)
    {
        automatic=false;npc=false;
        if(auto* c=WDN1::Actor(GetCaster()))
        {
            npc=true;npcOwner=c->GetBotAI()->GetBotOwnerGuid();npcMap=c->GetMapId();
            remaining=WDN1::Known(c,GetId())&&WDN1::Safe(c,GetTarget())?WDN1::Count(c):0;
            if(!remaining){GetAura()->Remove();return;}
            float sp=float(std::max(0,c->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_SHADOW)));
            float rap=std::max(0.f,c->GetTotalAttackPowerValue(RANGED_ATTACK));
            damage=uint32(std::max(0,effect->GetAmount())+rap*.07f+sp*.15f);
            splash=uint32(130*WD120A::Scaling(c->GetLevel())+rap*.15f+sp*.15f);
            GetAura()->SetMaxDuration(remaining*250);GetAura()->SetDuration(remaining*250);return;
        }
        Player* p=GetCaster()?GetCaster()->ToPlayer():nullptr;
        remaining=Owns(p,GetId())?Count(p):0;
        if(!remaining) { GetAura()->Remove();return; }
        float sp=float(std::max(0,p->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_SHADOW)));
        float rap=std::max(0.0f,p->GetTotalAttackPowerValue(RANGED_ATTACK));
        damage=uint32(std::max(0,effect->GetAmount())+rap*.07f+sp*.15f);
        // Official parent tooltip: splash coefficients 15% RAP + 15% Shadow SP.
        splash=uint32(130*WD120A::Scaling(p->GetLevel())+rap*.15f+sp*.15f);
        uint32 pct=WD149::ReadyPct(p);
        damage=uint32(uint64(damage)*(100+pct)/100);splash=uint32(uint64(splash)*(100+pct)/100);
        if(pct)WD149::Consume(p);
        GetAura()->SetMaxDuration(remaining*250);GetAura()->SetDuration(remaining*250);
    }
    void NpcTick()
    {
        auto* c=WDN1::Actor(GetCaster());Unit* target=GetTarget();
        if(!c||!WDN1::Known(c,GetId())||c->GetBotAI()->GetBotOwnerGuid()!=npcOwner||c->GetMapId()!=npcMap||
           !remaining||!WDN1::Safe(c,target)||!c->IsWithinDistInMap(target,30.f)){GetAura()->Remove();return;}
        --remaining;
        std::list<Unit*> enemies;
        Acore::AnyUnitInObjectRangeCheck check(target,10.f);
        Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(target,enemies,check);
        Cell::VisitObjects(target,search,10.f);
        enemies.sort([target](Unit* a,Unit* b){return target->GetDistance(a)<target->GetDistance(b);});
        std::vector<ObjectGuid> selected;ObjectGuid primary=target->GetGUID();
        for(Unit* other:enemies)
            if(other!=target&&WDN1::Safe(c,other)&&target->IsWithinDistInMap(other,10.f)&&target->IsWithinLOSInMap(other))
            {selected.push_back(other->GetGUID());if(selected.size()==5)break;}
        c->CastCustomSpell(Hit,SPELLVALUE_BASE_POINT0,damage,target,true);
        for(ObjectGuid guid:selected)
        {
            c=WDN1::Actor(GetCaster());if(!c||!WDN1::Known(c,GetId())||c->GetBotAI()->GetBotOwnerGuid()!=npcOwner||c->GetMapId()!=npcMap)break;
            Unit* other=ObjectAccessor::GetUnit(*c,guid);Unit* center=ObjectAccessor::GetUnit(*c,primary);
            if(center&&center->IsInWorld()&&c->IsInMap(center)&&c->InSamePhase(center)&&
               WDN1::Safe(c,other)&&center->IsWithinDistInMap(other,10.f)&&center->IsWithinLOSInMap(other))
                c->CastCustomSpell(Splash,SPELLVALUE_BASE_POINT0,splash,other,true);
        }
        // Snapshot only: Eclipse does not consume or generate Spirits.
    }
    void Tick(AuraEffect const*)
    {
        if(npc){NpcTick();return;}
        Player* p=GetCaster()?GetCaster()->ToPlayer():nullptr;Unit* target=GetTarget();
        if(!Owns(p,GetId()) || !target->IsAlive() || !remaining || !p->IsValidAttackTarget(target) ||
           (automatic&&!WD168::SafeAutomaticTarget(p,target)) ||
           !p->IsWithinDistInMap(target,30.0f) || !p->IsWithinLOSInMap(target)) { GetAura()->Remove();return; }
        --remaining;
        std::list<Unit*> enemies;
        Acore::AnyUnitInObjectRangeCheck check(target,10.0f);
        Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(target,enemies,check);
        Cell::VisitObjects(target,search,10.0f);
        enemies.sort([target](Unit* a,Unit* b) { return target->GetDistance(a)<target->GetDistance(b); });
        std::vector<ObjectGuid> selected;
        for(Unit* other:enemies)
            if(other!=target && (!automatic||WD168::SafeAutomaticTarget(p,other)) && other->IsAlive() && p->InSamePhase(other) && target->IsWithinDistInMap(other,10.0f) && p->IsValidAttackTarget(other) && target->IsWithinLOSInMap(other) && p->IsWithinLOSInMap(other))
            {
                selected.push_back(other->GetGUID());
                if(selected.size()==5) break;
            }
        p->CastCustomSpell(Hit,SPELLVALUE_BASE_POINT0,damage,target,true);
        // Resolve each GUID again after triggered casts; never retain other-unit pointers across callbacks.
        for(ObjectGuid guid:selected)
            if(Unit* other=ObjectAccessor::GetUnit(*p,guid))
                if(Owns(p,GetId()) && (!automatic||(WD168::SafeAutomaticTarget(p,other) && target->IsWithinDistInMap(other,10.0f) && target->IsWithinLOSInMap(other))) && other->IsAlive() && p->InSamePhase(other) && p->IsValidAttackTarget(other) && p->IsWithinLOSInMap(other))
                    p->CastCustomSpell(Splash,SPELLVALUE_BASE_POINT0,splash,other,true);
        // Spirits are snapshotted and never consumed or created by Eclipse.
    }
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(eclipse_aura::Apply,EFFECT_0,SPELL_AURA_PERIODIC_DUMMY,AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        OnEffectPeriodic += AuraEffectPeriodicFn(eclipse_aura::Tick,EFFECT_0,SPELL_AURA_PERIODIC_DUMMY);
    }
};
class eclipse_cast : public SpellScript
{
    PrepareSpellScript(eclipse_cast);
    bool automatic=false;
    bool Load() override
    { automatic=!GetSpell()->IsTriggered()&&WD168::IsAutomaticCast(GetCaster()->ToPlayer(),GetSpellInfo()->Id);return true; }
    void MarkAura()
    {
        if(Aura* aura=GetHitAura())
            if(auto* script=aura->GetScript<eclipse_aura>("WD145::eclipse_aura"))
                script->automatic=automatic;
    }
    SpellCastResult Check()
    {
        Player* p=GetCaster()->ToPlayer();
        if(auto* c=WDN1::Actor(GetCaster()))
            return WDN1::Known(c,GetSpellInfo()->Id)&&WDN1::Safe(c,GetExplTargetUnit())&&WDN1::Count(c)>0?SPELL_CAST_OK:SPELL_FAILED_CASTER_AURASTATE;
        if(!Owns(p,GetSpellInfo()->Id)) return SPELL_FAILED_CASTER_AURASTATE;
        if(Count(p)==0)
        {
            if(p->GetSession()) ChatHandler(p->GetSession()).SendNotification(
                "灵魂蚀需要至少1层灵魂。请先用灵魂回收（Reclamation）等方式获取灵魂。");
            return SPELL_FAILED_DONT_REPORT;
        }
        return SPELL_CAST_OK;
    }
    void Register() override { OnCheckCast += SpellCheckCastFn(eclipse_cast::Check); AfterHit += SpellHitFn(eclipse_cast::MarkAura); }
};
void Register()
{
    new modifiers();RegisterSpellScript(WD145::spirit_gain);RegisterSpellScript(WD145::eclipse_cast);RegisterSpellScript(WD145::eclipse_aura);
}
}
namespace WD145Bridge
{
void Apply(Player* p,bool eclipse,bool loa,bool devotee,bool wisdom)
{
    if(!IsDoctor(p)) return;
    uint32 actions[MAX_ACTION_BUTTONS]={};
    for(uint8 b=0;b<MAX_ACTION_BUTTONS;++b) if(ActionButton const* a=p->GetActionButton(b)) if(a->GetType()==ACTION_BUTTON_SPELL) actions[b]=a->GetAction();
    uint32 const levels[]={15,22,30,38,46,54,60};uint32 best=0;
    for(uint32 i=0;i<7;++i) if(eclipse&&p->GetLevel()>=levels[i]) best=9004000+i;
    for(uint32 i=0;i<7;++i)
    {
        uint32 id=9004000+i;
        if(id==best) { if(!p->HasSpell(id))p->learnSpell(id); }
        else if(p->HasSpell(id))p->removeSpell(id,3,false);
    }
    bool changed=false;
    for(uint8 b=0;b<MAX_ACTION_BUTTONS;++b) if(WD145::Eclipse(actions[b])&&actions[b]!=best)
    {
        p->removeActionButton(b);if(best)p->addActionButton(b,best,ACTION_BUTTON_SPELL);changed=true;
    }
    if(changed)p->SendActionButtons(1);
    bool flags[]={loa,devotee,wisdom};
    for(uint32 i=0;i<3;++i)
    {
        uint32 id=9004010+i;
        if(flags[i]) { if(!p->HasSpell(id))p->learnSpell(id);if(!p->HasAura(id,p->GetGUID()))p->CastSpell(p,id,true); }
        else { p->RemoveAurasDueToSpell(id,p->GetGUID());if(p->HasSpell(id))p->removeSpell(id,3,false); }
    }
}
}
