// WD157: community f6e30667591521c9f4f199a294b7cc4b15573c71, official donor contracts in research.
namespace WD157
{
constexpr uint32 Stalker=9004150,Hunger=9004151,Hex=9004152,Hunt=9004153,Stacks=9004154,Debuff=9004155,Entry=9004156,Speed=9004157;
constexpr char Key[]="RebornWD157.Targets";
struct State:DataMap::Base{std::vector<ObjectGuid> targets;};
bool Owns(Player* p,uint32 id){return IsDoctor(p)&&p->IsAlive()&&p->HasSpell(id)&&(id==Stalker||p->HasAura(id,p->GetGUID()));}
uint32 HungerCount(Player* p){if(!Owns(p,Hunger))return 0;Aura* a=p->GetAura(Stacks,p->GetGUID());return a?std::min(10u,uint32(a->GetStackAmount())):0;}
constexpr int32 ArrowDamage(int32 base,uint32 stacks){return base>0?int32(std::min<int64>(INT32_MAX,int64(base)*(100+10*std::min(10u,stacks))/100)):base;}
constexpr uint32 HuntChance(uint32 spirits){return std::min(5u,spirits)*15;}
void Clear(Player* p){auto* s=p->CustomData.Get<State>(Key);if(!s)return;auto ids=s->targets;s->targets.clear();if(p->IsInWorld())for(auto id:ids)if(Unit* u=ObjectAccessor::GetUnit(*p,id))u->RemoveAurasDueToSpell(Debuff,p->GetGUID());}
void ArrowCast(Player* p,uint32 hungerBefore,uint32 spiritsBefore)
{
    if(!IsDoctor(p)||!p->IsAlive())return;
    if(hungerBefore)p->RemoveAurasDueToSpell(Stacks,p->GetGUID());
    if(Owns(p,Hunt)&&roll_chance_i(HuntChance(spiritsBefore))){p->CastSpell(p,WD87A::Spirit,true);WD87A::Sync(p);}
}
void ArrowHit(Player* p,Unit* u)
{
    if(!Owns(p,Hex)||!u||!u->IsAlive()||!p->IsValidAttackTarget(u))return;
    p->CastSpell(u,Debuff,true);
    auto* s=p->CustomData.GetDefault<State>(Key);
    s->targets.erase(std::remove_if(s->targets.begin(),s->targets.end(),[p](ObjectGuid id){Unit* t=ObjectAccessor::GetUnit(*p,id);return !t||!t->HasAura(Debuff,p->GetGUID());}),s->targets.end());
    if(u->HasAura(Debuff,p->GetGUID())&&std::find(s->targets.begin(),s->targets.end(),u->GetGUID())==s->targets.end())s->targets.push_back(u->GetGUID());
}
class stalker:public SpellScript
{
    PrepareSpellScript(stalker);
    bool Validate(SpellInfo const*)override{return ValidateSpellInfo({Stalker,Entry,Speed});}
    SpellCastResult Check(){return Owns(GetCaster()->ToPlayer(),Stalker)?SPELL_CAST_OK:SPELL_FAILED_CASTER_AURASTATE;}
    void Stop(){Player* p=GetCaster()->ToPlayer();if(!Owns(p,Stalker))return;p->AttackStop();p->InterruptSpell(CURRENT_AUTOREPEAT_SPELL);}
    void Register()override{OnCheckCast+=SpellCheckCastFn(stalker::Check);OnCast+=SpellCastFn(stalker::Stop);}
};
class stealth:public AuraScript
{
    PrepareAuraScript(stealth);
    void Remove(AuraEffect const*,AuraEffectHandleModes){if(Unit* u=GetTarget()){u->RemoveAurasDueToSpell(Speed,GetCasterGUID());u->RemoveAurasDueToSpell(Entry,GetCasterGUID());}}
    void Register()override{AfterEffectRemove+=AuraEffectRemoveFn(stealth::Remove,EFFECT_0,SPELL_AURA_MOD_STEALTH,AURA_EFFECT_HANDLE_REAL);}
};
class hunger:public AuraScript
{
    PrepareAuraScript(hunger);
    void Tick(AuraEffect const*)
    {
        Player* p=GetTarget()->ToPlayer();
        if(Owns(p,Hunger)&&GetCasterGUID()==p->GetGUID()&&(p->HasAura(Stalker,p->GetGUID())||p->HasAura(WD154::Mirage,p->GetGUID())))p->CastSpell(p,Stacks,true);
    }
    void Remove(AuraEffect const*,AuraEffectHandleModes){if(Unit* u=GetTarget())u->RemoveAurasDueToSpell(Stacks,GetCasterGUID());}
    void Register()override{OnEffectPeriodic+=AuraEffectPeriodicFn(hunger::Tick,EFFECT_0,SPELL_AURA_PERIODIC_DUMMY);AfterEffectRemove+=AuraEffectRemoveFn(hunger::Remove,EFFECT_0,SPELL_AURA_PERIODIC_DUMMY,AURA_EFFECT_HANDLE_REAL);}
};
class lifecycle:public PlayerScript
{
public:lifecycle():PlayerScript("reborn_wd157_lifecycle"){}
    static void Exit(Player* p){p->RemoveAurasDueToSpell(Stalker,p->GetGUID());p->RemoveAurasDueToSpell(Entry,p->GetGUID());p->RemoveAurasDueToSpell(Speed,p->GetGUID());p->RemoveAurasDueToSpell(Stacks,p->GetGUID());Clear(p);}
    void OnPlayerUpdate(Player* p,uint32)override{if(!IsDoctor(p))return;if(!Owns(p,Stalker)){p->RemoveAurasDueToSpell(Stalker,p->GetGUID());p->RemoveAurasDueToSpell(Speed,p->GetGUID());p->RemoveAurasDueToSpell(Entry,p->GetGUID());}if(!Owns(p,Hunger))p->RemoveAurasDueToSpell(Stacks,p->GetGUID());if(!Owns(p,Hex))Clear(p);}
    void OnPlayerLogout(Player* p)override{if(IsDoctor(p))Exit(p);}
    void OnPlayerMapChanged(Player* p)override{if(IsDoctor(p))Exit(p);}
};
class diagnostics:public CommandScript
{
public:diagnostics():CommandScript("reborn_wd157_diagnostics"){}
    static bool Check(ChatHandler* h)
    {
        Player* p=h->GetSession()->GetPlayer();if(!IsDoctor(p))return false;Aura* a=p->GetAura(Stalker,p->GetGUID());Aura* speed=p->GetAura(Speed,p->GetGUID());Aura* b=p->GetAura(Stacks,p->GetGUID());
        h->PSendSysMessage("WD157 stalker={} hunger={} hex={} hunting={} stalker_ms={} speed_ms={} cooldown_ms={} hunger_stacks={} hunger_ms={} arrow_bonus_percent={} spirits={} hunting_chance_percent={}",p->HasSpell(Stalker)?1:0,Owns(p,Hunger)?1:0,Owns(p,Hex)?1:0,Owns(p,Hunt)?1:0,a?a->GetDuration():0,speed?speed->GetDuration():0,p->GetSpellCooldownDelay(Stalker),HungerCount(p),b?b->GetDuration():0,10*HungerCount(p),WD87A::Count(p),Owns(p,Hunt)?HuntChance(WD87A::Count(p)):0);
        if(Unit* u=p->GetSelectedUnit())if(Aura* d=u->GetAura(Debuff,p->GetGUID()))h->PSendSysMessage("WD157 own_hex stacks={} remaining_ms={} healing_received_percent={}",d->GetStackAmount(),d->GetDuration(),d->GetEffect(EFFECT_0)?d->GetEffect(EFFECT_0)->GetAmount():0);
        return true;
    }
    Acore::ChatCommands::ChatCommandTable GetCommands()const override{using namespace Acore::ChatCommands;static ChatCommandTable t={{"wd157check",Check,SEC_PLAYER,Console::No}};return t;}
};
void Register(){new lifecycle();new diagnostics();RegisterSpellScript(WD157::stalker);RegisterSpellScript(WD157::stealth);RegisterSpellScript(WD157::hunger);}
}
namespace WD157Bridge
{
void Apply(Player* p,bool stalker,bool hunger,bool hex,bool hunting)
{
    if(!IsDoctor(p))return;bool flags[]={stalker,hunger,hex,hunting};uint32 ids[]={WD157::Stalker,WD157::Hunger,WD157::Hex,WD157::Hunt};
    for(uint32 i=0;i<4;++i)if(!flags[i]){p->RemoveAurasDueToSpell(ids[i],p->GetGUID());if(p->HasSpell(ids[i]))p->removeSpell(ids[i],3,false);}
    for(uint32 i=0;i<4;++i)if(flags[i]){if(!p->HasSpell(ids[i]))p->learnSpell(ids[i]);if(i&&!p->HasAura(ids[i],p->GetGUID()))p->CastSpell(p,ids[i],true);}
    if(!stalker){p->RemoveAurasDueToSpell(WD157::Speed,p->GetGUID());p->RemoveAurasDueToSpell(WD157::Entry,p->GetGUID());}
    if(!hunger)p->RemoveAurasDueToSpell(WD157::Stacks,p->GetGUID());if(!hex)WD157::Clear(p);
}
}
