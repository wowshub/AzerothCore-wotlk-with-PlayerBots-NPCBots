// WD132: effective Beam healing -> two lowest-health allies; no recursive Beam casts.
#include "ThreatManager.h"
namespace WD132A
{
constexpr uint32 Wave=9003937, Heal=9003938, Replenishment=9003939;
bool Enabled(Player* p) { return IsDoctor(p) && p->IsAlive() && p->HasSpell(Wave) && p->HasAura(Wave,p->GetGUID()); }
std::list<Unit*> Nearby(Player* p,Unit* center,float radius)
{
    std::list<Unit*> units;
    if(!center) return units;
    Acore::AnyUnitInObjectRangeCheck check(center,radius);
    Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(center,units,check);
    Cell::VisitObjects(center,search,radius);
    units.remove_if([p,center,radius](Unit* u){return !WD130A::Friendly(p,u) || (u!=p && !p->IsInRaidWith(u)) ||
        !center->IsWithinDistInMap(u,radius) || !center->IsWithinLOSInMap(u);});
    return units;
}
void Echo(Player* p,Unit* primary,uint32 effective)
{
    if(!Enabled(p) || !primary || effective<2) return;
    SpellInfo const* info=sSpellMgr->GetSpellInfo(Heal);if(!info) return;
    auto units=Nearby(p,primary,20.0f); // official Radius9=20; community uses 15.
    units.remove_if([primary](Unit* u){return u==primary || u->IsFullHealth();});
    units.sort([](Unit* a,Unit* b){return a->GetHealthPct()==b->GetHealthPct()?a->GetGUID()<b->GetGUID():a->GetHealthPct()<b->GetHealthPct();});
    std::vector<ObjectGuid> targets;
    for(Unit* u:units) { targets.push_back(u->GetGUID());if(targets.size()==2) break; }
    ObjectGuid center=primary->GetGUID();
    for(ObjectGuid guid:targets)
    {
        Unit* u=ObjectAccessor::GetUnit(*p,guid);Unit* origin=ObjectAccessor::GetUnit(*p,center);
        if(!Enabled(p) || !origin || !WD130A::Friendly(p,u) || (u!=p && !p->IsInRaidWith(u)) ||
           !origin->IsWithinDistInMap(u,20.0f) || !origin->IsWithinLOSInMap(u)) continue;
        // Source effective heal already includes caster bonuses and crit. Apply recipient modifiers once.
        uint32 amount=u->SpellHealingBonusTaken(p,info,effective/2,HEAL);
        HealInfo heal(p,u,amount,info,info->GetSchoolMask());
        Unit::CalcHealAbsorb(heal);p->HealBySpell(heal,false);
        // No extra proc dispatch: this copied heal cannot recursively grow branches or reduce potion CDs.
        u->GetThreatMgr().ForwardThreatForAssistingMe(p,float(heal.GetEffectiveHeal())*0.5f,info);
    }
}
void Restore(Player* p)
{
    if(!Enabled(p)) return;
    auto units=Nearby(p,p,40.0f);
    units.remove_if([](Unit* u){return u->getPowerType()!=POWER_MANA || !u->GetMaxPower(POWER_MANA);});
    units.sort([](Unit* a,Unit* b){
        uint64 left=uint64(a->GetPower(POWER_MANA))*b->GetMaxPower(POWER_MANA),right=uint64(b->GetPower(POWER_MANA))*a->GetMaxPower(POWER_MANA);
        return left==right?a->GetGUID()<b->GetGUID():left<right;
    });
    std::vector<ObjectGuid> targets;
    for(Unit* u:units) { targets.push_back(u->GetGUID());if(targets.size()==10) break; }
    for(ObjectGuid guid:targets)
        if(Unit* u=ObjectAccessor::GetUnit(*p,guid))
            if(WD130A::Friendly(p,u) && (u==p || p->IsInRaidWith(u)) && u->getPowerType()==POWER_MANA)
                p->CastSpell(u,Replenishment,true);
}
}
