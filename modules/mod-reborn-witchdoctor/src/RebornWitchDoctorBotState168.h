// WD168A: map-thread-only, by-value, read-only inputs for future bot decisions.
#ifndef REBORN_WD_BOT_STATE_168_H
#define REBORN_WD_BOT_STATE_168_H
#include "Define.h"
#include <array>
class Player;
class Unit;
namespace WD168
{
struct Plan
{
 bool available=false;
 char const* reason="not_loaded";
 uint32 revision=0,slot=0,spec=3,ae=0,te=0,aeBudget=0,teBudget=0;
};
struct LearnedSpell
{
 uint32 base=0,learned=0,replacement=0,cooldownMs=0,gcdMs=0;
 bool infoKnown=false;
};
struct SummonSlot
{
 uint32 selected=0,entry=0;
 bool present=false;
};
struct Snapshot
{
 Plan plan;
 uint32 level=0,souls=0,mana=0,maxMana=0;
 bool alive=false,inWorld=false,combat=false,serpentPresent=false;
 std::array<LearnedSpell,11> spells{};
 std::array<SummonSlot,3> summons{};
};
LearnedSpell ReadSpell(Player*,uint32);
Plan ReadPlan(Player*);
Snapshot Capture(Player*);
// Map-thread call scope only. Script::Load snapshots this flag during native prepare;
// it is never persisted on the player and cannot leak into a later manual cast.
class AutomaticCastScope
{
 Player* previous;uint32 previousSpell;
public:
 AutomaticCastScope(Player*,uint32);
 ~AutomaticCastScope();
 AutomaticCastScope(AutomaticCastScope const&)=delete;
 AutomaticCastScope& operator=(AutomaticCastScope const&)=delete;
};
bool IsAutomaticCast(Player*,uint32);
bool SafeAutomaticTarget(Player*,Unit*);
// No pointers to mutable state escape; not a CanCast predicate or AI action.
}
#endif
