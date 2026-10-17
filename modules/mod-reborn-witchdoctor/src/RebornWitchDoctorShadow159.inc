// WD159: source-grounded final-tier Spirit interactions. See research/upstream.
namespace WD159
{
constexpr uint32 Talent=9004170,Gift=9004171,Price=9004172,Ready=9004173,Volley=9004174,PriceReady=9004175,Haste=9004176;
constexpr char Key[]="RebornWD159.Spirit";
struct State:DataMap::Base{uint32 original=0;uint64 volleyGeneration=0,priceGeneration=0;uint32 volleyCompleted=0,lastBefore=0,lastAfter=0,lastVolleyAt=0,generatorCompleted=0,lastGenerator=0;};
State* Data(Player* p){return p->CustomData.GetDefault<State>(Key);}
bool Owns(Player* p,uint32 id){return IsDoctor(p)&&p->IsAlive()&&p->HasSpell(id)&&p->HasAura(id,p->GetGUID());}
bool Mimic(Player* p){return WD87B::PresenceRemaining(p)>0;}
bool Available(Player* p){return IsDoctor(p)&&p->IsAlive()&&p->HasSpell(Volley)&&((Owns(p,Talent)&&p->HasAura(Ready,p->GetGUID()))||(Owns(p,Gift)&&Mimic(p)));}
uint32 GlaiveRemaining(Player* p){uint32 remaining=0;for(uint32 id=9004030;id<=9004036;++id)if(p->HasSpell(id))remaining=std::max(remaining,p->GetSpellCooldownDelay(id));return remaining;}
void Reduce(Player* p,int32 milliseconds){for(uint32 id=9004030;id<=9004036;++id)if(p->HasSpell(id)&&p->GetSpellCooldownDelay(id))p->ModifySpellCooldown(id,-std::min<int32>(milliseconds,p->GetSpellCooldownDelay(id)));}
void Sync(Player* p)
{
    if(!IsDoctor(p)||!p->IsInWorld())return;State* s=Data(p);uint32 best=0;
    for(auto const& r:WD19A::Reclamation143Ranks)if(p->HasActiveSpell(r.spell))best=r.spell;
    bool enabled=Available(p);
    if(s->original&&(!enabled||s->original!=best)){p->SetTemporarySpellReplacement(s->original,0);s->original=0;}
    if(enabled&&best){p->SetTemporarySpellReplacement(best,Volley);s->original=best;}
    uint32 lifetime=Owns(p,Gift)?WD87B::PresenceRemaining(p):0;
    if(lifetime){Aura* a=p->GetAura(Haste,p->GetGUID());if(!a)a=p->AddAura(Haste,p);if(a){a->SetMaxDuration(int32(lifetime));a->SetDuration(int32(lifetime));}}
    else p->RemoveAurasDueToSpell(Haste,p->GetGUID());
}
void Proc(Player* p){if(Owns(p,Talent)&&roll_chance_i(30)){++Data(p)->volleyGeneration;p->CastSpell(p,Ready,true);}}
class ready:public AuraScript
{
    PrepareAuraScript(ready);
    void Changed(AuraEffect const*,AuraEffectHandleModes){if(Player* p=GetTarget()->ToPlayer())Sync(p);}
    void Register()override{AfterEffectApply+=AuraEffectApplyFn(ready::Changed,EFFECT_0,SPELL_AURA_DUMMY,AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);AfterEffectRemove+=AuraEffectRemoveFn(ready::Changed,EFFECT_0,SPELL_AURA_DUMMY,AURA_EFFECT_HANDLE_REAL);}
};
class generator:public SpellScript
{
    PrepareSpellScript(generator);
    void Done(){if(!GetSpell()->IsTriggered())if(Player* p=GetCaster()->ToPlayer())if(IsDoctor(p)){State* state=Data(p);++state->generatorCompleted;state->lastGenerator=GetSpellInfo()->Id;Proc(p);}}
    void Register()override{AfterCast+=SpellCastFn(generator::Done);}
};
class volley:public SpellScript
{
    PrepareSpellScript(volley);bool accepted=false;uint64 generation=0;uint32 spirits=0;
    SpellCastResult Check()
    {
        Player* p=WD68A::Caster(GetCaster());if(!IsDoctor(p)||!p->IsAlive()||!p->HasSpell(Volley))return SPELL_FAILED_CASTER_AURASTATE;
        if(GetSpell()->IsTriggered())return SPELL_CAST_OK;
        if(!accepted){if(!Available(p)){ChatHandler(p->GetSession()).SendNotification("灵魂齐射需要就绪效果，或拥有邦桑迪的赠礼并保持自己的拟态守卫存活。");return SPELL_FAILED_DONT_REPORT;}accepted=true;generation=Data(p)->volleyGeneration;}
        return SPELL_CAST_OK; // accepted casts complete even if readiness expires while casting
    }
    void Snapshot(){Player* p=WD68A::Caster(GetCaster());spirits=WD87A::Count(p);}
    void Damage(SpellEffIndex)
    {
        Player* p=WD68A::Caster(GetCaster());if(!IsDoctor(p)){SetEffectValue(0);return;}
        int32 value=GetEffectValue()+int32(.285f*std::max(0.f,p->GetTotalAttackPowerValue(RANGED_ATTACK)));
        SetEffectValue(value);
    }
    void Hit(){Player* p=WD68A::Caster(GetCaster());if(Owns(p,Gift)&&GetHitDamage()>0)SetHitDamage(int32(int64(GetHitDamage())*(100+2*WD87A::Count(p))/100));} // Upstream uses live Spirits at impact, after the successful-cast Spirit gain.
    void Done()
    {
        Player* p=GetCaster()->ToPlayer();if(GetSpell()->IsTriggered()||!IsDoctor(p)||!p->IsAlive())return;
        State* state=Data(p);++state->volleyCompleted;state->lastVolleyAt=getMSTime();state->lastBefore=GlaiveRemaining(p);
        p->CastSpell(p,9003574,true);Reduce(p,3000);state->lastAfter=GlaiveRemaining(p);
        if(Data(p)->volleyGeneration==generation)p->RemoveAurasDueToSpell(Ready,p->GetGUID());
        if(Unit* target=GetExplTargetUnit())WD68A::Mirror(p,target,Volley);
        Sync(p); // copies neither grant Spirits nor reduce cooldowns nor generate new readiness
    }
    void Register()override{OnCheckCast+=SpellCheckCastFn(volley::Check);BeforeCast+=SpellCastFn(volley::Snapshot);OnEffectLaunchTarget+=SpellEffectFn(volley::Damage,EFFECT_0,SPELL_EFFECT_SCHOOL_DAMAGE);OnHit+=SpellHitFn(volley::Hit);AfterCast+=SpellCastFn(volley::Done);}
};
class eclipse:public SpellScript
{
    PrepareSpellScript(eclipse);uint32 spirits=0;
    void Snapshot(){if(!GetSpell()->IsTriggered())spirits=WD87A::Count(GetCaster()->ToPlayer());}
    void Done(){Player* p=GetCaster()->ToPlayer();if(!GetSpell()->IsTriggered()&&spirits==5&&Owns(p,Price)){Reduce(p,INT32_MAX);++Data(p)->priceGeneration;p->CastSpell(p,PriceReady,true);}}
    void Register()override{BeforeCast+=SpellCastFn(eclipse::Snapshot);AfterCast+=SpellCastFn(eclipse::Done);}
};
class glaive:public SpellScript
{
    PrepareSpellScript(glaive);bool empowered=false,accepted=false;uint64 generation=0;
    SpellCastResult Check(){if(!accepted){accepted=true;Player* p=GetCaster()->ToPlayer();empowered=!GetSpell()->IsTriggered()&&Owns(p,Price)&&p->HasAura(PriceReady,p->GetGUID());if(empowered)generation=Data(p)->priceGeneration;GetSpell()->SetRebornWD159PriceSnapshot(empowered);}return SPELL_CAST_OK;}
    void Done(){Player* p=GetCaster()->ToPlayer();if(!empowered||!Owns(p,Price))return;if(Data(p)->priceGeneration==generation)p->RemoveAurasDueToSpell(PriceReady,p->GetGUID());uint32 remaining=p->GetSpellCooldownDelay(9004150);if(remaining)p->ModifySpellCooldown(9004150,-int32(std::min<uint32>(15000,remaining)));}
    void Register()override{OnCheckCast+=SpellCheckCastFn(glaive::Check);AfterCast+=SpellCastFn(glaive::Done);}
};
class modifiers:public GlobalScript
{
public:modifiers():GlobalScript("reborn_wd159_modifiers"){}
    bool OnIsAffectedBySpellModCheck(SpellInfo const*,SpellInfo const* check,SpellModifier const* mod)override
    {
        if(check&&mod&&mod->spellId==PriceReady)return !(mod->op==SPELLMOD_CRITICAL_CHANCE&&check->Id>=9004030&&check->Id<=9004036);
        if(check&&mod&&mod->spellId==9004012&&mod->op==SPELLMOD_DAMAGE&&check->Id==Volley)return false;
        return true;
    }
};
class lifecycle:public PlayerScript
{
public:lifecycle():PlayerScript("reborn_wd159_lifecycle"){}
    static void Clear(Player* p){p->RemoveAurasDueToSpell(Ready,p->GetGUID());p->RemoveAurasDueToSpell(PriceReady,p->GetGUID());p->RemoveAurasDueToSpell(Haste,p->GetGUID());if(auto* s=p->CustomData.Get<State>(Key))if(s->original){p->SetTemporarySpellReplacement(s->original,0);s->original=0;}}
    void OnPlayerUpdate(Player* p,uint32)override{if(!IsDoctor(p))return;if(!Owns(p,Talent))p->RemoveAurasDueToSpell(Ready,p->GetGUID());if(!Owns(p,Price))p->RemoveAurasDueToSpell(PriceReady,p->GetGUID());Sync(p);}
    void OnPlayerLogout(Player* p)override{if(IsDoctor(p))Clear(p);}
    void OnPlayerMapChanged(Player* p)override{if(IsDoctor(p))Clear(p);}
};
class diagnostics:public CommandScript
{
public:diagnostics():CommandScript("reborn_wd159_diagnostics"){}
    static bool Check(ChatHandler* h){Player* p=h->GetSession()->GetPlayer();if(!IsDoctor(p))return false;State* state=Data(p);h->PSendSysMessage("WD162G generator_completed={} last_generator_spell={} volley_completed={} last_before_ms={} last_after_ms={} last_reduced_ms={} last_volley_age_ms={}",state->generatorCompleted,state->lastGenerator,state->volleyCompleted,state->lastBefore,state->lastAfter,state->lastBefore>state->lastAfter?state->lastBefore-state->lastAfter:0,state->volleyCompleted?getMSTimeDiff(state->lastVolleyAt,getMSTime()):0);uint32 best=0;for(auto const& r:WD19A::Reclamation143Ranks)if(p->HasActiveSpell(r.spell))best=r.spell;Aura* ready=p->GetAura(Ready,p->GetGUID());Aura* price=p->GetAura(PriceReady,p->GetGUID());SpellInfo const* info=sSpellMgr->GetSpellInfo(Volley);h->PSendSysMessage("WD159 volley={} gift={} price={} spirits={} mimic_remaining_ms={} ready_ms={} original={} replacement={} volley_cast_ms={} gift_haste_pct={} gift_damage_pct={} price_ms={} stalker_remaining_ms={}",Owns(p,Talent)?1:0,Owns(p,Gift)?1:0,Owns(p,Price)?1:0,WD87A::Count(p),WD87B::PresenceRemaining(p),ready?ready->GetDuration():0,best,best?p->GetTemporarySpellReplacement(best):0,info?info->CalcCastTime(p):0,p->HasAura(Haste,p->GetGUID())?15:0,Owns(p,Gift)?2*WD87A::Count(p):0,price?price->GetDuration():0,p->GetSpellCooldownDelay(9004150));for(uint32 id=9004030;id<=9004036;++id)if(p->HasSpell(id))h->PSendSysMessage("WD159 glaive={} remaining_ms={}",id,p->GetSpellCooldownDelay(id));return true;}
    Acore::ChatCommands::ChatCommandTable GetCommands()const override{using namespace Acore::ChatCommands;static ChatCommandTable t={{"wd159check",Check,SEC_PLAYER,Console::No}};return t;}
};
void Register(){new lifecycle();new diagnostics();new modifiers();RegisterSpellScript(WD159::ready);RegisterSpellScript(WD159::generator);RegisterSpellScript(WD159::volley);RegisterSpellScript(WD159::eclipse);RegisterSpellScript(WD159::glaive);}
}
namespace WD159Bridge
{
void Apply(Player* p,bool volley,bool gift,bool price)
{
    if(!IsDoctor(p))return;bool flags[]={volley,gift,price};uint32 ids[]={WD159::Talent,WD159::Gift,WD159::Price};
    for(uint32 i=0;i<3;++i)if(flags[i]){if(!p->HasSpell(ids[i]))p->learnSpell(ids[i]);if(!p->HasAura(ids[i],p->GetGUID()))p->CastSpell(p,ids[i],true);}else{p->RemoveAurasDueToSpell(ids[i],p->GetGUID());if(p->HasSpell(ids[i]))p->removeSpell(ids[i],3,false);}
    if(volley||gift){if(!p->HasSpell(WD159::Volley))p->learnSpell(WD159::Volley,true);}else{WD159::lifecycle::Clear(p);if(p->HasSpell(WD159::Volley))p->removeSpell(WD159::Volley,3,false);}
    if(!volley)p->RemoveAurasDueToSpell(WD159::Ready,p->GetGUID());if(!price)p->RemoveAurasDueToSpell(WD159::PriceReady,p->GetGUID());WD159::Sync(p);
}
}
