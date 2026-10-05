#include <algorithm>
#include <cstdint>
using int32 = std::int32_t;
using uint32 = std::uint32_t;
constexpr int32 actual(int32 rec, uint32 RecoveryTime) {
    return std::min<int32>(rec, std::max<int32>(0, int32(RecoveryTime) - 5000));
}
constexpr int32 tooltip(int32 cooldown, uint32 RecoveryTime) {
    return std::min<int32>(cooldown, std::max<int32>(0, int32(RecoveryTime) - 5000));
}
static_assert(actual(15000, 15000u) == 10000);
static_assert(tooltip(15000, 15000u) == 10000);
static_assert(actual(10000, 15000u) == 10000);
static_assert(tooltip(10000, 15000u) == 10000);
static_assert(actual(8000, 15000u) == 8000);
static_assert(tooltip(8000, 15000u) == 8000);
static_assert(actual(15000, 4000u) == 0);
static_assert(tooltip(15000, 4000u) == 0);
static_assert(actual(0, 0u) == 0);
static_assert(tooltip(0, 0u) == 0);
