// WD158: Umbral Glaive, Sen'jin's Apprentice and Spirit Shock. Community f6e3066; donor evidence in research.
namespace WD158
{
constexpr uint32 Talent=9004160,Apprentice=9004161,Shock=9004162,Ready=9004163,Umbral=9004164;
constexpr char Key[]="RebornWD158.Umbral";
struct State:DataMap::Base{uint64 generation=0;uint32 original=0;std::vector<ObjectGuid> targets;};
State* Data(Player* p){return p->CustomData.GetDefault<State>(Key);}
bool Owns(Player* p,uint32 id){return IsDoctor(p)&&p->IsAlive()&&p->HasSpell(id)&&(id==Shock||p->HasAura(id,p->GetGUID()));}
float Chance(Player* p){return p?std::min(100.f,10.f+std::max(0.f,p->GetRatingBonusValue(CR_CRIT_RANGED))):0.f;}
void Replacement(Player* p)
{
    if(!IsDoctor(p)||!p->IsInWorld())return;
    bool ready=Owns(p,Talent)&&p->HasAura(Ready,p->GetGUID());uint32 best=0;
    for(auto const& r:WD19A::HexRanks)if(p->HasActiveSpell(r.spell))best=r.spell;
    State* state=Data(p);
    if(state->original&&(!ready||state->original!=best)){p->SetTemporarySpellReplacement(state->original,0);state->original=0;}
    if(ready&&best&&p->HasActiveSpell(Umbral)){p->SetTemporarySpellReplacement(best,Umbral);state->original=best;}
}
void Clear(Player* p)
{
    auto* s=p->CustomData.Get<State>(Key);if(!s)return;auto ids=s->targets;s->targets.clear();
    if(p->IsInWorld())for(auto id:ids)if(Unit* u=ObjectAccessor::GetUnit(*p,id))u->RemoveAurasDueToSpell(Umbral,p->GetGUID());
}
class talent:public AuraScript
{
    PrepareAuraScript(talent);
    bool Check(ProcEventInfo& e)
    {
        Player* p=GetTarget()->ToPlayer();SpellInfo const* info=e.GetSpellInfo();
        return Owns(p,Talent)&&GetCasterGUID()==p->GetGUID()&&e.GetActor()==p&&e.GetDamageInfo()&&e.GetDamageInfo()->GetDamage()>0&&(!info||info->Id!=Umbral)&&
            (e.GetTypeMask()&(PROC_FLAG_DONE_RANGED_AUTO_ATTACK|PROC_FLAG_DONE_SPELL_RANGED_DMG_CLASS))&&roll_chance_f(Chance(p));
    }
    void Proc(ProcEventInfo&){PreventDefaultAction();Player* p=GetTarget()->ToPlayer();if(!Owns(p,Talent))return;++Data(p)->generation;p->CastSpell(p,Ready,true);}
    void Register()override{DoCheckProc+=AuraCheckProcFn(talent::Check);OnProc+=AuraProcFn(talent::Proc);}
};
class ready:public AuraScript
{
    PrepareAuraScript(ready);
    void Changed(AuraEffect const*,AuraEffectHandleModes){if(Player* p=GetTarget()->ToPlayer())Replacement(p);}
    void Register()override{AfterEffectApply+=AuraEffectApplyFn(ready::Changed,EFFECT_0,SPELL_AURA_DUMMY,AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);AfterEffectRemove+=AuraEffectRemoveFn(ready::Changed,EFFECT_0,SPELL_AURA_DUMMY,AURA_EFFECT_HANDLE_REAL);}
};
class umbral:public SpellScript
{
    PrepareSpellScript(umbral);
    bool accepted=false,done=false,automatic=false;uint64 generation=0;
    bool Load()override{automatic=WD168::IsAutomaticCast(WD68A::Caster(GetCaster()),GetSpellInfo()->Id);return true;}
    void ProtectHit(SpellEffIndex)
    {
        if(automatic&&!WD168::SafeAutomaticTarget(WD68A::Caster(GetCaster()),GetHitUnit()))
        {for(uint32 i=0;i<MAX_SPELL_EFFECTS;++i){PreventHitDefaultEffect(SpellEffIndex(i));PreventHitEffect(SpellEffIndex(i));}}
    }
    SpellCastResult Check()
    {
        Player* p=WD68A::Caster(GetCaster());if(!Owns(p,Talent)||!p->HasSpell(Umbral))return SPELL_FAILED_CASTER_AURASTATE;
        if(GetSpell()->IsTriggered())return SPELL_CAST_OK; // bounded copies/mimic; never consume/generate further copies
        if(!accepted){if(!p->HasAura(Ready,p->GetGUID())){ChatHandler(p->GetSession()).SendSysMessage("需要幽影战刃触发效果：先使用远程攻击命中敌人。");return SPELL_FAILED_DONT_REPORT;}accepted=true;generation=Data(p)->generation;}
        return SPELL_CAST_OK;
    }
    void Hit()
    {
        Player* p=WD68A::Caster(GetCaster());Unit* u=GetHitUnit();if(!Owns(p,Talent)||!u||!GetHitAura()||(automatic&&!WD168::SafeAutomaticTarget(p,u)))return;
        for(auto const& r:WD19A::HexRanks)if(Aura* a=u->GetAura(r.spell,p->GetGUID())){a->RefreshDuration();break;}
        auto* s=Data(p);s->targets.erase(std::remove_if(s->targets.begin(),s->targets.end(),[p](ObjectGuid id){Unit* t=ObjectAccessor::GetUnit(*p,id);return !t||!t->HasAura(Umbral,p->GetGUID());}),s->targets.end());
        if(std::find(s->targets.begin(),s->targets.end(),u->GetGUID())==s->targets.end())s->targets.push_back(u->GetGUID());
    }
    void Done()
    {
        Player* p=GetCaster()->ToPlayer();Unit* primary=GetExplTargetUnit();if(done||GetSpell()->IsTriggered()||!Owns(p,Talent)||!primary)return;
        if(automatic&&!WD168::SafeAutomaticTarget(p,primary))return;done=true;
        ObjectGuid primaryGuid=primary->GetGUID();
        std::list<Unit*> units;Acore::AnyUnitInObjectRangeCheck check(primary,10.f);Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(primary,units,check);Cell::VisitObjects(primary,search,10.f);
        units.remove_if([&](Unit* u){return u==primary||!u->IsAlive()||!p->IsInMap(u)||!p->InSamePhase(u)||!primary->IsWithinDistInMap(u,10.f)||!p->IsValidAttackTarget(u)||!p->IsWithinLOSInMap(u)||(automatic&&!WD168::SafeAutomaticTarget(p,u));});
        units.sort([primary](Unit* a,Unit* b){float da=primary->GetExactDistSq(a),db=primary->GetExactDistSq(b);return da==db?a->GetGUID()<b->GetGUID():da<db;});
        std::vector<ObjectGuid> ids;for(Unit* u:units){if(ids.size()==2)break;ids.push_back(u->GetGUID());}
        for(auto id:ids)
        {
            primary=ObjectAccessor::GetUnit(*p,primaryGuid);
            if(!p->IsAlive()||!primary||(automatic&&!WD168::SafeAutomaticTarget(p,primary)))break;
            Unit* u=ObjectAccessor::GetUnit(*p,id);
            if(u&&u->IsAlive()&&p->IsInMap(u)&&p->InSamePhase(u)&&p->IsValidAttackTarget(u)&&p->IsWithinLOSInMap(u)&&primary->IsWithinDistInMap(u,10.f)&&
               (!automatic||WD168::SafeAutomaticTarget(p,u)))
            {WD168::AutomaticCastScope scope(p,automatic?Umbral:0);p->CastSpell(u,Umbral,true);}
        }
        primary=ObjectAccessor::GetUnit(*p,primaryGuid);
        if(primary&&(!automatic||WD168::SafeAutomaticTarget(p,primary)))
        {WD168::AutomaticCastScope scope(p,automatic?Umbral:0);WD68A::Mirror(p,primary,Umbral);}
        if(Data(p)->generation==generation)p->RemoveAurasDueToSpell(Ready,p->GetGUID());
    }
    void Register()override{OnEffectHitTarget+=SpellEffectFn(umbral::ProtectHit,EFFECT_ALL,SPELL_EFFECT_ANY);OnCheckCast+=SpellCheckCastFn(umbral::Check);AfterHit+=SpellHitFn(umbral::Hit);AfterCast+=SpellCastFn(umbral::Done);}
};
class leech:public AuraScript
{
    PrepareAuraScript(leech);
    void Amount(AuraEffect const* effect,int32& amount,bool& recalc){recalc=false;Unit* target=GetUnitOwner();Player* p=WD68A::Caster(GetCaster());if(!Owns(p,Talent)||!target){amount=0;return;}uint32 base=uint32(std::max(0,effect->GetOldAmount()+int32(.10f*std::max(0.f,p->GetTotalAttackPowerValue(RANGED_ATTACK)))));amount=int32(p->SpellDamageBonusDone(target,GetSpellInfo(),base,DOT,EFFECT_0,effect->GetPctMods(),1));}
    void Register()override{DoEffectCalcAmount+=AuraEffectCalcAmountFn(leech::Amount,EFFECT_0,SPELL_AURA_PERIODIC_LEECH);}
};
class shock:public SpellScript
{
    PrepareSpellScript(shock);
    bool automatic=false,blocked=false;
    bool Load()override{automatic=WD168::IsAutomaticCast(GetCaster()->ToPlayer(),Shock);return true;}
    bool Safe(){Unit* u=GetHitUnit();return u&&!u->IsPlayer()&&WD168::SafeAutomaticTarget(GetCaster()->ToPlayer(),u);}
    SpellCastResult Check(){if(!Owns(GetCaster()->ToPlayer(),Shock))return SPELL_FAILED_CASTER_AURASTATE;
        if(automatic&&(!GetExplTargetUnit()||GetExplTargetUnit()->IsPlayer()||!WD168::SafeAutomaticTarget(GetCaster()->ToPlayer(),GetExplTargetUnit())))return SPELL_FAILED_BAD_TARGETS;
        return SPELL_CAST_OK;}
    void Interrupt(SpellEffIndex i){Unit* u=GetHitUnit();if(!u||u->IsPlayer()||(automatic&&!Safe()))PreventHitDefaultEffect(i);}
    void Before(SpellMissInfo){blocked=automatic&&!Safe();}
    void Silence(SpellEffIndex i){if(blocked){PreventHitAura();PreventHitDefaultEffect(i);}}
    void Register()override{OnCheckCast+=SpellCheckCastFn(shock::Check);OnEffectLaunchTarget+=SpellEffectFn(shock::Interrupt,EFFECT_1,SPELL_EFFECT_INTERRUPT_CAST);
        BeforeHit+=BeforeSpellHitFn(shock::Before);OnEffectHitTarget+=SpellEffectFn(shock::Silence,EFFECT_0,SPELL_EFFECT_APPLY_AURA);}
};
class lifecycle:public PlayerScript
{
public:lifecycle():PlayerScript("reborn_wd158_lifecycle"){}
    static void Exit(Player* p){p->RemoveAurasDueToSpell(Ready,p->GetGUID());Replacement(p);Clear(p);}
    void OnPlayerUpdate(Player* p,uint32)override{if(!IsDoctor(p))return;if(!Owns(p,Talent)){p->RemoveAurasDueToSpell(Ready,p->GetGUID());Clear(p);}Replacement(p);}
    void OnPlayerLogout(Player* p)override{if(IsDoctor(p))Exit(p);}
    void OnPlayerMapChanged(Player* p)override{if(IsDoctor(p))Exit(p);}
};
class diagnostics:public CommandScript
{
public:diagnostics():CommandScript("reborn_wd158_diagnostics"){}
    static bool Check(ChatHandler* h){Player* p=h->GetSession()->GetPlayer();if(!IsDoctor(p))return false;Aura* a=p->GetAura(Ready,p->GetGUID());uint32 original=0;for(auto const& r:WD19A::HexRanks)if(p->HasActiveSpell(r.spell))original=r.spell;
        h->PSendSysMessage("WD158 umbral={} apprentice={} shock={} proc_chance_percent={} ready_ms={} original_hex={} replacement={} intellect={} agility={} rap={} expected_apprentice_rap={} expected_apprentice_sp={} shock_remaining_ms={}",Owns(p,Talent)?1:0,Owns(p,Apprentice)?1:0,p->HasSpell(Shock)?1:0,Chance(p),a?a->GetDuration():0,original,original?p->GetTemporarySpellReplacement(original):0,p->GetStat(STAT_INTELLECT),p->GetStat(STAT_AGILITY),p->GetTotalAttackPowerValue(RANGED_ATTACK),Owns(p,Apprentice)?int32(p->GetStat(STAT_INTELLECT)+.25f*p->GetStat(STAT_AGILITY)):0,Owns(p,Apprentice)?int32(.25f*p->GetStat(STAT_AGILITY)):0,p->GetSpellCooldownDelay(Shock));
        if(Unit* u=p->GetSelectedUnit()){if(Aura* d=u->GetAura(Umbral,p->GetGUID()))h->PSendSysMessage("WD158 own_umbral remaining_ms={} tick_amount={} first_tick_delayed=1",d->GetDuration(),d->GetEffect(EFFECT_0)?d->GetEffect(EFFECT_0)->GetAmount():0);if(Aura* d=u->GetAura(Shock,p->GetGUID()))h->PSendSysMessage("WD158 own_shock silence_ms={}",d->GetDuration());}return true;}
    Acore::ChatCommands::ChatCommandTable GetCommands()const override{using namespace Acore::ChatCommands;static ChatCommandTable t={{"wd158check",Check,SEC_PLAYER,Console::No}};return t;}
};
void Register(){new lifecycle();new diagnostics();RegisterSpellScript(WD158::talent);RegisterSpellScript(WD158::ready);RegisterSpellScript(WD158::umbral);RegisterSpellScript(WD158::leech);RegisterSpellScript(WD158::shock);}
}
namespace WD158Bridge
{
void Apply(Player* p,bool umbral,bool apprentice,bool shock)
{
    if(!IsDoctor(p))return;bool flags[]={umbral,apprentice,shock};uint32 ids[]={WD158::Talent,WD158::Apprentice,WD158::Shock};
    for(uint32 i=0;i<3;++i)if(!flags[i]){p->RemoveAurasDueToSpell(ids[i],p->GetGUID());if(p->HasSpell(ids[i]))p->removeSpell(ids[i],3,false);}
    for(uint32 i=0;i<3;++i)if(flags[i]){if(!p->HasSpell(ids[i]))p->learnSpell(ids[i]);if(i<2&&!p->HasAura(ids[i],p->GetGUID()))p->CastSpell(p,ids[i],true);}
    if(umbral){if(!p->HasSpell(WD158::Umbral))p->learnSpell(WD158::Umbral,true);}
    else{p->RemoveAurasDueToSpell(WD158::Ready,p->GetGUID());WD158::Replacement(p);WD158::Clear(p);if(p->HasSpell(WD158::Umbral))p->removeSpell(WD158::Umbral,3,false);}
}
}
