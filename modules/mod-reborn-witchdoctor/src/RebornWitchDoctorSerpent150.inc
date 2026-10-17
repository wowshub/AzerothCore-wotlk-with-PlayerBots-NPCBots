// WD150: Call of Sseratus, Voodoo Fire (2 ranks), Spirit Striker.
namespace WD150
{
constexpr uint32 Call=9004080,FireOne=9004081,FireTwo=9004082,FireHit=9004083,Striker=9004084;
constexpr char Key[]="RebornWD150.MassWards";
struct State:DataMap::Base { std::vector<ObjectGuid> wards;uint32 attacks=0,procs=0; };
bool Owns(Player* p,uint32 id) { return IsDoctor(p)&&p->IsAlive()&&p->HasSpell(9003967)&&p->HasSpell(id); }
bool OwnedMass(Player* p,ObjectGuid guid)
{
    if(!Owns(p,Call))return false;auto* state=p->CustomData.GetDefault<State>(Key);
    return std::find(state->wards.begin(),state->wards.end(),guid)!=state->wards.end();
}
void Clear(Player* p)
{
    auto* state=p->CustomData.Get<State>(Key);if(!state||state->wards.empty())return;auto ids=state->wards;state->wards.clear();
    if(p->IsInWorld())for(auto guid:ids)if(Creature* c=ObjectAccessor::GetCreature(*p,guid))
        if(c->GetEntry()==900190&&c->GetOwnerGUID()==p->GetGUID())c->DespawnOrUnsummon();
}
class call : public AuraScript
{
    PrepareAuraScript(call);bool made=false;
    void Tick(AuraEffect const*)
    {
        if(made)return;made=true;Player* p=GetTarget()->ToPlayer();if(!Owns(p,Call)||GetCasterGUID()!=p->GetGUID())return;
        int32 duration=15000;p->ApplySpellMod(9003160,SPELLMOD_DURATION,duration);
        std::vector<ObjectGuid> fresh;
uint32 count=p->HasSpell(9004131)&&p->HasAura(9004131,p->GetGUID())?6:4;
        for(uint32 i=0;i<count;++i)
        {
            Position pos=p->GetPosition();p->MovePositionToFirstCollision(pos,2.5f,float(i)*6.2831853f/float(count));
            if(TempSummon* c=p->SummonCreature(900190,pos,TEMPSUMMON_TIMED_DESPAWN,std::max(1,duration)))fresh.push_back(c->GetGUID());
        }
        if(fresh.empty())return;
        Clear(p);p->CustomData.GetDefault<State>(Key)->wards=fresh;
        for(auto guid:fresh)if(ObjectAccessor::GetCreature(*p,guid))WD149::Gain(p);
    }
    void Register()override { OnEffectPeriodic+=AuraEffectPeriodicFn(call::Tick,EFFECT_0,SPELL_AURA_PERIODIC_DUMMY); }
};
void Shot(Creature* ward,ObjectGuid centerGuid)
{
    if(!ward||(ward->GetEntry()!=900190&&ward->GetEntry()!=900255))return;Player* p=ObjectAccessor::GetPlayer(*ward,ward->GetOwnerGUID());
    if(!IsDoctor(p)||!p->IsAlive()||(!Owns(p,FireOne)&&!Owns(p,FireTwo)))return;
    if(!OwnedMass(p,ward->GetGUID())&&!WD160::OwnedViper(p,ward->GetGUID())&&!WD153::OwnedWard(p,ward->GetGUID())&&p->CustomData.GetDefault<WD21A::State>(WD21A::Key)->guid!=ward->GetGUID())return;
    uint32 chance=Owns(p,FireTwo)?40:20;if(Owns(p,Striker))chance+=10;
    auto* state=p->CustomData.GetDefault<State>(Key);++state->attacks;
    if(!roll_chance_i(chance))return;
    Unit* center=ObjectAccessor::GetUnit(*ward,centerGuid);if(!center||!p->IsInMap(center)||!p->InSamePhase(center))return;
    std::list<Unit*> units;Acore::AnyUnitInObjectRangeCheck check(center,10.0f);Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(center,units,check);Cell::VisitObjects(center,search,10.0f);
    units.sort([center](Unit* a,Unit* b){return center->GetDistance(a)<center->GetDistance(b);});std::vector<ObjectGuid> targets;
    for(Unit* u:units)if(u->IsAlive()&&p->IsValidAttackTarget(u)&&p->InSamePhase(u)&&center->IsWithinDistInMap(u,10.0f)&&ward->IsWithinLOSInMap(u)) { targets.push_back(u->GetGUID());if(targets.size()==3)break; }
    if(targets.empty())return;++state->procs;
    for(auto guid:targets)if(Unit* u=ObjectAccessor::GetUnit(*ward,guid))if(u->IsAlive()&&p->IsValidAttackTarget(u))ward->CastSpell(u,FireHit,true,nullptr,nullptr,p->GetGUID());
}
class fire : public SpellScript
{
    PrepareSpellScript(fire);
    void Damage(SpellEffIndex)
    {
        Unit* original=GetOriginalCaster();Player* p=original?original->ToPlayer():nullptr;
        if(!IsDoctor(p)) { SetEffectValue(0);return; }
        float sp=float(std::max(p->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_FIRE),p->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_NATURE)));
        SetEffectValue(int32(73.0*WD120A::Scaling(p->GetLevel())+.125f*std::max(0.f,p->GetTotalAttackPowerValue(RANGED_ATTACK))+.12f*std::max(0.f,sp)));
    }
    void Register()override { OnEffectHitTarget+=SpellEffectFn(fire::Damage,EFFECT_0,SPELL_EFFECT_SCHOOL_DAMAGE); }
};
class lifecycle:public PlayerScript
{
public:
 lifecycle():PlayerScript("reborn_wd150_lifecycle"){}
 void OnPlayerLogout(Player* p)override { if(IsDoctor(p))Clear(p); }
 void OnPlayerMapChanged(Player* p)override { if(IsDoctor(p))Clear(p); }
 void OnPlayerUpdate(Player* p,uint32)override { if(IsDoctor(p)&&!Owns(p,Call))Clear(p); }
};
void Register() { RegisterSpellScript(WD150::call);RegisterSpellScript(WD150::fire);new lifecycle(); }
}
namespace WD150Bridge
{
void Apply(Player* p,bool call,uint32 fire,bool striker)
{
 if(!IsDoctor(p))return;
 bool flags[]={call,fire==1,fire>=2,striker};uint32 ids[]={WD150::Call,WD150::FireOne,WD150::FireTwo,WD150::Striker};
 for(uint32 i=0;i<4;++i)if(flags[i]) { if(!p->HasSpell(ids[i]))p->learnSpell(ids[i]);if(i&&!p->HasAura(ids[i],p->GetGUID()))p->CastSpell(p,ids[i],true); }
 else { p->RemoveAurasDueToSpell(ids[i],p->GetGUID());if(p->HasSpell(ids[i]))p->removeSpell(ids[i],3,false); }
 if(!call)WD150::Clear(p);
}
}
