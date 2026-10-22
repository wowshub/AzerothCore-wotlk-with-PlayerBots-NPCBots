// WD182A: AI-only reserve policy. Native spell costs and coefficients remain authoritative.
#ifndef REBORN_WD_BEAM_POLICY_182_H
#define REBORN_WD_BEAM_POLICY_182_H
#include "Define.h"
#include <cstdint>
namespace WD182
{
inline uint32 FirstTickCost(uint32 spell)
{
 constexpr uint32 mana[]={101,139,186,231,316,429,470};
 return spell>=9003922&&spell<=9003928?mana[spell-9003922]/2:0;
}
inline bool StartReserve(uint32 mana,uint32 maximum,uint32 upfront,uint32 firstTick)
{
 if(!maximum||!firstTick||mana<upfront)return false;
 return std::uint64_t(mana)*100>=std::uint64_t(maximum)*60&&
  std::uint64_t(mana-upfront)>=std::uint64_t(firstTick)+(std::uint64_t(maximum)*25+99)/100;
}
inline bool ContinueReserve(uint32 mana,uint32 maximum,uint32 nextCost)
{
 return maximum&&mana>=nextCost&&std::uint64_t(mana-nextCost)*100>=std::uint64_t(maximum)*20;
}
}
#endif
