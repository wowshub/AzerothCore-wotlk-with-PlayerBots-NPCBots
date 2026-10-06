#pragma once
#include "Player.h"
#include "Spell.h"
#include "SpellInfo.h"
#include "CellImpl.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include <list>
namespace WD130A
{
inline bool Beam(uint32 id) { return id>=9003922 && id<=9003928; }
inline bool Bottle(uint32 id) { return id>=9003460 && id<=9003467; }
inline bool Side(uint32 id) { return Bottle(id) || (id>=9003870 && id<=9003876) || (id>=9003890 && id<=9003896); }
inline bool Channel(Unit* p)
{
    if(!p || !p->IsPlayer() || p->getClass()!=13 || p->getRace()!=1 || !p->IsAlive()) return false;
    Spell* s=p->GetCurrentSpell(CURRENT_CHANNELED_SPELL);
    return s && Beam(s->GetSpellInfo()->Id) && s->getState()==SPELL_STATE_CASTING;
}
inline bool SideCast(Unit* p,SpellInfo const* info) { return info && Side(info->Id) && Channel(p); }
inline bool Friendly(Unit* p,Unit* u)
{
    return p && u && u->IsAlive() && u->IsInWorld() && p->IsInMap(u) && p->IsFriendlyTo(u) &&
        p->IsWithinDistInMap(u,40.0f) && p->IsWithinLOSInMap(u);
}
inline std::list<Unit*> Allies(Unit* p,Unit* center)
{
    std::list<Unit*> units;
    if(!center) return units;
    Acore::AnyUnitInObjectRangeCheck check(center,15.0f);
    Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(center,units,check);
    Cell::VisitObjects(center,search,15.0f);
    units.remove_if([p,center](Unit* u){return !Friendly(p,u) || (u!=p && !p->IsInRaidWith(u)) || !center->IsWithinLOSInMap(u);});
    units.sort([center](Unit* a,Unit* b){float da=center->GetDistance(a),db=center->GetDistance(b);return da==db?a->GetGUID()<b->GetGUID():da<db;});
    return units;
}
}
