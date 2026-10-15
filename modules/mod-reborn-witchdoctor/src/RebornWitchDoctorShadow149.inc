// WD149: Godslayer + The True Spirit, authored mutually exclusive Shadow nodes.
namespace WD149
{
constexpr uint32 God=9004070,Explosion=9004071,True=9004072,Ready=9004073;
bool Owns(Player* p,uint32 id) { return IsDoctor(p) && p->IsAlive() && p->HasSpell(9003967) && p->HasSpell(id) && p->HasAura(id,p->GetGUID()); }
uint32 ReadyPct(Player* p) { Aura* a=Owns(p,True)?p->GetAura(Ready,p->GetGUID()):nullptr;return a?6u*std::min<uint32>(5,a->GetStackAmount()):0u; }
void Gain(Player* p) { if(Owns(p,True))p->CastSpell(p,Ready,true); }
void Consume(Player* p) { if(p)p->RemoveAurasDueToSpell(Ready,p->GetGUID()); }
class gain : public SpellScript
{
    PrepareSpellScript(gain);
    void Hit() { Player* p=GetCaster()->ToPlayer();if(p && GetHitUnit()==p && GetHitAura())Gain(p); }
    void Register() override { AfterHit += SpellHitFn(gain::Hit); }
};
class ending : public AuraScript
{
    PrepareAuraScript(ending);
    void Removed(AuraEffect const*,AuraEffectHandleModes)
    {
        if(GetTargetApplication()->GetRemoveMode()!=AURA_REMOVE_BY_EXPIRE)return;
        Player* p=GetCaster()?GetCaster()->ToPlayer():nullptr;Unit* center=GetTarget();
        if(!Owns(p,God)||!center||!center->IsAlive()||!p->IsInMap(center)||!p->IsValidAttackTarget(center))return;
        std::list<Unit*> nearby;Acore::AnyUnitInObjectRangeCheck check(center,10.0f);
        Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(center,nearby,check);Cell::VisitObjects(center,search,10.0f);
        std::unordered_set<ObjectGuid> targets;targets.insert(center->GetGUID());
        for(Unit* u:nearby)if(u->IsAlive()&&p->IsValidAttackTarget(u)&&p->InSamePhase(u)&&center->IsWithinDistInMap(u,10.0f)&&center->IsWithinLOSInMap(u))targets.insert(u->GetGUID());
        for(ObjectGuid guid:targets)if(Unit* u=ObjectAccessor::GetUnit(*p,guid))
            if(Owns(p,God)&&u->IsAlive()&&p->IsValidAttackTarget(u)&&p->InSamePhase(u))p->CastSpell(u,Explosion,true);
    }
    void Register() override { AfterEffectRemove += AuraEffectRemoveFn(ending::Removed,EFFECT_2,SPELL_AURA_MOD_RESISTANCE,AURA_EFFECT_HANDLE_REAL); }
};
class explosion : public SpellScript
{
    PrepareSpellScript(explosion);
    void Damage(SpellEffIndex)
    {
        Player* p=GetCaster()->ToPlayer();
        if(!Owns(p,God)) { SetEffectValue(0);return; }
        // Official 20260930 tooltip: 315 * level scaling + 40% SP + 25% RAP.
        SetEffectValue(int32(315.f*WD120A::Scaling(p->GetLevel())+.4f*std::max(0,p->SpellBaseDamageBonusDone(SPELL_SCHOOL_MASK_SHADOW))+.25f*std::max(0.f,p->GetTotalAttackPowerValue(RANGED_ATTACK))));
    }
    void Register() override { OnEffectHitTarget += SpellEffectFn(explosion::Damage,EFFECT_0,SPELL_EFFECT_SCHOOL_DAMAGE); }
};
void Register() { RegisterSpellScript(WD149::gain);RegisterSpellScript(WD149::ending);RegisterSpellScript(WD149::explosion); }
}
namespace WD149Bridge
{
void Apply(Player* p,bool god,bool spirit)
{
    if(!IsDoctor(p))return;
    bool flags[]={god,spirit};uint32 ids[]={WD149::God,WD149::True};
    for(uint32 i=0;i<2;++i)if(flags[i]) { if(!p->HasSpell(ids[i]))p->learnSpell(ids[i]);if(!p->HasAura(ids[i],p->GetGUID()))p->CastSpell(p,ids[i],true); }
    else { p->RemoveAurasDueToSpell(ids[i],p->GetGUID());if(p->HasSpell(ids[i]))p->removeSpell(ids[i],3,false); }
    if(!spirit)WD149::Consume(p);
}
}
