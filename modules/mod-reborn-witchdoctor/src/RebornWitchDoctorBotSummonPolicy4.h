#pragma once
#include "Define.h"
#include <array>
namespace WDWS4
{
inline constexpr std::array<uint32,8> Bases={9003160,9003170,9003370,9003440,9004080,9003580,9003673,9003420};
constexpr uint32 Base(uint32 key){return key>=1&&key<=Bases.size()?Bases[key-1]:0;}
constexpr uint32 Resolve(uint32 key,uint32 learned,uint32 replacement,bool viperTalent)
{
    if(!Base(key)||!learned)return 0;
    if(!replacement)return learned;
    // Only the verified six-serpent -> Viper override is supported in this panel.
    return key==5&&learned==9004080&&replacement==9004182&&viperTalent?replacement:0;
}
}
