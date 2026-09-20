// WD19A: generated from manifest.json; explicit families, never numeric-ID ordering.
#ifndef REBORN_WITCH_DOCTOR_RANKS_H
#define REBORN_WITCH_DOCTOR_RANKS_H
#include "Define.h"
#include <cstddef>
namespace WD19A
{
struct Rank { uint32 spell; uint8 level; };
struct Family { Rank const* ranks; std::size_t count; bool starter; };
constexpr Rank WrathRanks[] = {{9003100,1},{9003120,6},{9003121,14},{9003122,22},{9003123,30},{9003124,38},{9003125,46},{9003126,54},{9003127,60}};
constexpr Rank BrewRanks[] = {{9003101,1},{9003130,8},{9003131,18},{9003132,26},{9003133,34},{9003134,42},{9003135,50},{9003136,58},{9003137,60},{9003138,76}};
constexpr Rank HexRanks[] = {{9003104,4},{9003106,12},{9003107,18},{9003108,26},{9003109,34},{9003110,42},{9003111,50},{9003112,58}};
// WD20A: base class skills; purchases are tracked independently of specialization.
constexpr Rank SpiritRanks[] = {{9003140,2},{9003141,28},{9003142,42},{9003143,56}};
constexpr Rank LethargyRanks[] = {{9003150,6}};
// WD21A: purchased base ward; attack spell is never taught.
constexpr Rank SerpentRanks[] = {{9003160,2}};
// WD22A: official Spell level 10; legacy generated list level 8 is not used.
constexpr Rank HealingWardRanks[] = {{9003170,10}};
// WD23A: Power Wuju native six-rank progression.
constexpr Rank PowerRanks[] = {{9003180,10},{9003181,20},{9003182,30},{9003183,40},{9003184,50},{9003185,60}};
// WD24A: Resourceful Wuju purchased at level 16.
constexpr Rank ResourcefulRanks[] = {{9003190,16}};
// WD25A: beast fear Jinx, purchased at level 22.
constexpr Rank HireekRanks[] = {{9003200,22}};
// WD26A: Mana Jinx, parent is the only learnable spell.
constexpr Rank ManaJinxRanks[] = {{9003210,26}};
// WD27A: Shrinking Jinx ranks; internal linked effects are not learnable.
constexpr Rank ShrinkingRanks[] = {{9003220,8},{9003221,18},{9003222,28},{9003223,38},{9003224,48},{9003225,58}};
// WD28A: native curse dispel, level 16 purchased support spell.
constexpr Rank HexbreakRanks[] = {{9003240,16}};
// WD29A: native poison/disease/curse immunity, level 28 purchased support spell.
constexpr Rank AllcureRanks[] = {{9003250,28}};
// WD30A: native resurrection, eight purchased ranks.
constexpr Rank ReclaimRanks[] = {{9003260,12},{9003261,20},{9003262,30},{9003263,40},{9003264,50},{9003265,60},{9003266,70},{9003267,80}};
// WD31A: purchased self-only Shadow Avatar.
constexpr Rank AvatarRanks[] = {{9003270,20}};
// WD32A: purchased raid-area Resourceful Wuju.
constexpr Rank GreaterResourcefulRanks[] = {{9003280,32}};
// WD33A: purchased raid-area Spirit and Power Wuju.
constexpr Rank GreaterSpiritRanks[] = {{9003290,56}};
constexpr Rank GreaterPowerRanks[] = {{9003300,60}};
constexpr Family Families[] = {
    {WrathRanks, sizeof(WrathRanks)/sizeof(Rank), true},
    {BrewRanks, sizeof(BrewRanks)/sizeof(Rank), true},
    {HexRanks, sizeof(HexRanks)/sizeof(Rank), false},
    {SpiritRanks, sizeof(SpiritRanks)/sizeof(Rank), false},
    {LethargyRanks, sizeof(LethargyRanks)/sizeof(Rank), false},
    {SerpentRanks, sizeof(SerpentRanks)/sizeof(Rank), false},
    {HealingWardRanks, sizeof(HealingWardRanks)/sizeof(Rank), false},
    {PowerRanks, sizeof(PowerRanks)/sizeof(Rank), false},
    {ResourcefulRanks, sizeof(ResourcefulRanks)/sizeof(Rank), false},
    {HireekRanks, sizeof(HireekRanks)/sizeof(Rank), false},
    {ManaJinxRanks, sizeof(ManaJinxRanks)/sizeof(Rank), false},
    {ShrinkingRanks, sizeof(ShrinkingRanks)/sizeof(Rank), false},
    {HexbreakRanks, sizeof(HexbreakRanks)/sizeof(Rank), false},
    {AllcureRanks, sizeof(AllcureRanks)/sizeof(Rank), false},
    {ReclaimRanks, sizeof(ReclaimRanks)/sizeof(Rank), false},
    {AvatarRanks, sizeof(AvatarRanks)/sizeof(Rank), false},
    {GreaterResourcefulRanks, sizeof(GreaterResourcefulRanks)/sizeof(Rank), false},
    {GreaterSpiritRanks, sizeof(GreaterSpiritRanks)/sizeof(Rank), false},
    {GreaterPowerRanks, sizeof(GreaterPowerRanks)/sizeof(Rank), false}
};
static inline Family const* FindFamily(uint32 spell)
{
    for (Family const& family : Families)
        for (std::size_t i=0; i<family.count; ++i)
            if (family.ranks[i].spell==spell) return &family;
    return nullptr;
}
static inline bool IsWrath(uint32 spell)
{
    Family const* family=FindFamily(spell);
    return family && family->ranks[0].spell==9003100;
}
static inline bool IsBrew(uint32 spell)
{
    Family const* family=FindFamily(spell);
    return family && family->ranks[0].spell==9003101;
}
}
#endif
