#pragma once
#include <cstdint>
// MBWD2B: used by the actual confirm path, and checked with compile-time cases.
namespace WDRemoteQuote
{
struct Identity
{
    std::uint64_t owner=0,bot=0;
    unsigned nonce=0,revision=0,slot=0,kind=0;
    bool active=false;
};
constexpr bool Matches(Identity const& q,std::uint64_t owner,std::uint64_t bot,unsigned nonce,
    unsigned revision,unsigned slot,unsigned kind,std::int64_t age)
{
    return q.active && age>=0 && age<60 && q.owner==owner && q.bot==bot && q.nonce==nonce &&
        q.revision==revision && q.slot==slot && q.kind==kind;
}
}
