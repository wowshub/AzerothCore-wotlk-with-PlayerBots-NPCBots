// WD91A: standalone local adaptation of Dark Effigy; included after the existing families.
namespace WD91A
{
constexpr uint32 DarkEffigy=9003770;
bool Owns(Player* player)
{
    return IsDoctor(player) && player->IsAlive() && player->HasSpell(DarkEffigy) && player->HasAura(DarkEffigy);
}
class spell_wd91_cleave : public SpellScript
{
    PrepareSpellScript(spell_wd91_cleave);
    bool expanded=false;
    void After()
    {
        Player* player=GetCaster()->ToPlayer();
        Unit* primary=GetExplTargetUnit();
        if (expanded || GetSpell()->IsTriggered() || !Owns(player) || !primary ||
            (!WD48A::Juju(GetSpellInfo()->Id) && !WD48A::Fire(GetSpellInfo()->Id))) return;
        expanded=true; // Recursive triggered copies can never fan out again.
        AuraEffect* amount=player->GetAuraEffect(DarkEffigy,EFFECT_0,player->GetGUID());
        uint32 cap=amount?uint32(std::max(0,std::min(2,amount->GetAmount()))):0;
        std::list<Unit*> units;
        Acore::AnyUnitInObjectRangeCheck check(primary,10.0f);
        Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(primary,units,check);
        Cell::VisitObjects(primary,search,10.0f);
        units.remove_if([&](Unit* unit)
        {
            return unit==primary || !unit->IsAlive() || !unit->IsInWorld() ||
                !player->IsInMap(unit) || !player->InSamePhase(unit) ||
                !primary->IsWithinDistInMap(unit,10.0f) || !player->IsValidAttackTarget(unit) ||
                !player->IsWithinLOSInMap(unit);
        });
        // Stable nearest-first selection. Resolve GUIDs afresh after each triggered cast.
        units.sort([primary](Unit* a,Unit* b)
        {
            float da=primary->GetExactDistSq(a),db=primary->GetExactDistSq(b);
            return da==db ? a->GetGUID()<b->GetGUID() : da<db;
        });
        std::vector<ObjectGuid> targets;
        for (Unit* unit:units)
        {
            if(targets.size()>=cap) break;
            targets.push_back(unit->GetGUID());
        }
        for (ObjectGuid guid:targets)
        {
            if (!Owns(player)) break;
            Unit* target=ObjectAccessor::GetUnit(*player,guid);
            if (target && target->IsAlive() && player->IsInMap(target) && player->InSamePhase(target) &&
                player->IsValidAttackTarget(target) && player->IsWithinLOSInMap(target))
                player->CastSpell(target,GetSpellInfo()->Id,true);
        }
    }
    void Register() override { AfterCast += SpellCastFn(spell_wd91_cleave::After); }
};
class spell_wd91_shadowflare : public SpellScript
{
    PrepareSpellScript(spell_wd91_shadowflare);
    void Hit()
    {
        Player* player=GetCaster()->ToPlayer();
        Unit* target=GetHitUnit();
        WD19A::Family const* family=WD19A::FindFamily(GetSpellInfo()->Id);
        if (!Owns(player) || !family || family->ranks[0].spell!=9003560 || !target ||
            GetHitDamage()<=0 || !target->HasAura(WD68A::Threads,player->GetGUID())) return;
        AuraEffect* amount=player->GetAuraEffect(DarkEffigy,EFFECT_1,player->GetGUID());
        if (amount) SetHitDamage(int32(std::min<int64>(2147483647,
            int64(GetHitDamage())*(100+std::max(0,amount->GetAmount()))/100)));
    }
    void Register() override { OnHit += SpellHitFn(spell_wd91_shadowflare::Hit); }
};
void Register()
{
    RegisterSpellScript(spell_wd91_cleave);
    RegisterSpellScript(spell_wd91_shadowflare);
}
}
