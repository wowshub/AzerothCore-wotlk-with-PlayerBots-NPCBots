#include <algorithm>
#include <cstdint>
using int32 = std::int32_t;
using uint32 = std::uint32_t;
int32 actual(int32 rec, uint32 RecoveryTime) {
    return std::min(rec, std::max(0, RecoveryTime - 5000));
}
int32 tooltip(int32 cooldown, uint32 RecoveryTime) {
    return std::min(cooldown, std::max(0, RecoveryTime - 5000));
}
