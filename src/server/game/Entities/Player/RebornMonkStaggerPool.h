#ifndef REBORN_MONK_STAGGER_POOL_H
#define REBORN_MONK_STAGGER_POOL_H
#include <array>
#include <algorithm>
#include <cstdint>

// MONKBW2: damage already mitigated by armor/shields. No world or DB dependencies.
// Ten ordered installments, not a refreshed 10-second DoT that can postpone old debt.
class RebornMonkStaggerPool
{
public:
    static constexpr std::uint32_t Limit = 0x7fffffff;
    std::array<std::uint32_t, 10> slots{};
    std::uint32_t nextTickMs = 1000;

    std::uint32_t Total() const
    {
        std::uint64_t total = 0;
        for (auto value : slots) total += value;
        return static_cast<std::uint32_t>(total);
    }
    void Clear() { slots.fill(0); nextTickMs = 1000; }
    bool Valid() const
    {
        std::uint64_t total = 0;
        for (auto value : slots) total += value;
        return total <= Limit && nextTickMs >= 1 && nextTickMs <= 1000;
    }
    std::uint32_t Add(std::uint32_t damage)
    {
        auto accepted = std::min(damage, Limit - Total());
        for (std::size_t i = 0; i < slots.size(); ++i)
            slots[i] += accepted / 10 + (i < accepted % 10 ? 1 : 0);
        return accepted; // Any overflow stays immediate damage, never disappears.
    }
    std::uint32_t Tick()
    {
        auto due = slots.front();
        for (std::size_t i = 1; i < slots.size(); ++i) slots[i - 1] = slots[i];
        slots.back() = 0;
        return due;
    }
    struct Settlement { std::uint32_t scheduled, damage, cleared; };
    Settlement SettleTick(std::uint32_t masteryPercent, std::uint32_t guardPercent)
    {
        auto scheduled = Tick();
        auto first = std::uint64_t(scheduled) * std::min(masteryPercent, 100u) / 100;
        auto second = std::uint64_t(scheduled) * std::min(guardPercent, 100u) / 100;
        auto cleared = static_cast<std::uint32_t>(std::min<std::uint64_t>(scheduled, first + second));
        // Pop the FULL installment once. Only the paid part reaches health.
        // Never subtract the cleared portion from the remaining slots again.
        return {scheduled, scheduled - cleared, cleared};
    }
    std::uint32_t Purify(std::uint32_t percent)
    {
        auto total = Total();
        if (!total || !percent) return 0;
        auto amount = std::min(total, std::max<std::uint32_t>(1,
            static_cast<std::uint32_t>(std::uint64_t(total) * std::min(percent, 100u) / 100)));
        auto left = amount;
        auto remaining = total;
        for (auto& slot : slots)
        {
            auto original = slot;
            auto removed = remaining ? static_cast<std::uint32_t>(std::uint64_t(original) * left / remaining) : 0;
            slot -= removed;
            left -= removed;
            remaining -= original;
        }
        if (!Total()) nextTickMs = 1000;
        return amount;
    }
};
#endif
