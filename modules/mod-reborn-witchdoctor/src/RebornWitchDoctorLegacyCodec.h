#pragma once
#include "RebornWitchDoctorNodeLayout.h"
#include <boost/multiprecision/cpp_int.hpp>
namespace WD139 {
inline bool LegacyCompatible(Build const& build) {
    if(!build.Valid())return false;
    for(unsigned i=0;i<Capacity;++i)if(build.ranks[i] && (i>=108 || i>=Count || Nodes[i].offset+Nodes[i].width>LegacyBits))return false;
    return true;
}
inline std::string LegacyDecimal(Build const& build) {
    if(!LegacyCompatible(build))return "";
    boost::multiprecision::uint128_t mask=0;
    for(unsigned i=0;i<Count && i<108;++i)mask|=boost::multiprecision::uint128_t(build.ranks[i])<<Nodes[i].offset;
    return mask.str();
}
inline bool ParseLegacy(std::string_view text,Build& out) {
    using Integer=boost::multiprecision::uint128_t;
    Integer mask=0,maximum=(Integer(1)<<LegacyBits)-1;
    if(text.empty()||text.size()>39)return false;
    for(char ch:text) {
        if(ch<'0'||ch>'9')return false;
        unsigned digit=ch-'0';if(mask>(maximum-digit)/10)return false;
        mask=mask*10+digit;
    }
    Build candidate;
    for(unsigned i=0;i<Count && i<108;++i)candidate.ranks[i]=static_cast<unsigned>((mask>>Nodes[i].offset)&((1u<<Nodes[i].width)-1));
    if(!candidate.Valid())return false;
    out=candidate;return true;
}
}
