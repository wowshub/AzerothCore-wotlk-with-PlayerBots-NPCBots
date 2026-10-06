#pragma once
#include <array>
#include <cstdint>
namespace WD133
{
struct DeferredDamage
{
    std::array<std::uint64_t,5> debt{};
    unsigned cursor=0;
    void Store(std::uint32_t amount)
    {
        for(unsigned i=0;i<5;++i) debt[(cursor+i)%5]+=amount/5+(i<amount%5);
    }
    std::uint64_t Next()
    {
        auto amount=debt[cursor];debt[cursor]=0;cursor=(cursor+1)%5;return amount;
    }
    std::uint64_t Drain()
    {
        std::uint64_t total=0;for(auto d:debt) total+=d;debt={};return total;
    }
};
}
