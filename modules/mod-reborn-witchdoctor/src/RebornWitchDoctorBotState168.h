// WD168A: map-thread-only, by-value, read-only inputs for future bot decisions.
#ifndef REBORN_WD_BOT_STATE_168_H
#define REBORN_WD_BOT_STATE_168_H
#include "Define.h"
#include <array>
class Player;
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
struct Snapshot
{
 Plan plan;
 uint32 level=0,souls=0,mana=0,maxMana=0;
 bool alive=false,inWorld=false,combat=false,serpentPresent=false;
 std::array<LearnedSpell,7> spells{};
};
Plan ReadPlan(Player*);
Snapshot Capture(Player*);
// No pointers to mutable state escape; not a CanCast predicate or AI action.
}
#endif
