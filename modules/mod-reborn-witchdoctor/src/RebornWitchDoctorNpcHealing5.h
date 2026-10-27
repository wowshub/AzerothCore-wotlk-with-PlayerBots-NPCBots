// WDN5A: NPC-only triage policy; no spell amounts, costs or cooldown changes.
#pragma once
namespace WDN5A
{
inline bool NeedsHeal(float hp, bool tank) { return hp < (tank ? 85.f : 70.f); }
inline bool Urgent(float hp, bool tank) { return hp < 50.f || (tank && hp < 75.f); }
// Life-threatening allies first, then injured tanks, then ordinary injuries.
inline float Priority(float hp, bool tank)
{ return hp + (hp <= 25.f ? 0.f : tank ? 100.f : 200.f); }
}
