#pragma once
#include <algorithm>
#include <cstdint>
#include <vector>
namespace WD135
{
struct Health { uint32_t current, maximum; };
inline std::vector<uint32_t> Balance(std::vector<Health> const& input)
{
    uint64_t health=0, maximum=0;
    for(auto const& v:input) {health+=v.current;maximum+=v.maximum;}
    std::vector<uint32_t> result;
    if(!maximum) return result;
    uint64_t assigned=0;
    for(auto const& v:input)
    {
        // Floating ratio avoids overflowing totalHealth * individualMaxHealth.
        // The correction below conserves the exact integer total, including minimum 1 HP.
        uint32_t amount=std::min(v.maximum,std::max(1u,uint32_t((long double)health*v.maximum/maximum)));
        result.push_back(amount);assigned+=amount;
    }
    for(size_t i=0;i<result.size() && assigned!=health;++i)
    {
        if(assigned<health) {auto d=std::min<uint64_t>(health-assigned,input[i].maximum-result[i]);result[i]+=uint32_t(d);assigned+=d;}
        else {auto d=std::min<uint64_t>(assigned-health,result[i]-1u);result[i]-=uint32_t(d);assigned-=d;}
    }
    return result;
}
}
