#pragma once
#include <algorithm>
#include <cstdint>
namespace RebornConcoctions
{
// Stored on the actual Spell/Aura, never on a reusable spell ID or raw pointer map.
struct Snapshot { uint64_t doctor=0; uint32_t percent=0; };
inline uint32_t HealAmount(uint32_t resolved,uint32_t healthBefore,uint32_t percent)
{
    return uint32_t(uint64_t(std::min(resolved,healthBefore))*std::min(percent,100u)/100u);
}
}
