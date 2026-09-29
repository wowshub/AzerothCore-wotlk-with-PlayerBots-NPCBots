// WD19A: generated from manifest.json; explicit families, never numeric-ID ordering.
#ifndef REBORN_WITCH_DOCTOR_RANKS_H
#define REBORN_WITCH_DOCTOR_RANKS_H
#include "Define.h"
#include <cstddef>
namespace WD19A
{
struct Rank { uint32 spell; uint8 level; };
struct Family { Rank const* ranks; std::size_t count; bool starter; };
// WD54A: innate class passive; native aura 98 adds +15 to Alchemy only.
constexpr Rank DarkMojoRanks[]={{9003640,30}};
constexpr Rank WizenedRanks[]={{9003641,30},{9003642,40}};
constexpr Rank LoaStrengthRanks[]={{9003643,30},{9003644,40}};
constexpr Rank JujuInjectionRanks[]={{9003650,30},{9003651,40}};
constexpr Rank SeekerRanks[]={{9003652,30}};
constexpr Rank HastenedRanks[]={{9003653,30}};
constexpr Rank MimicRanks[]={{9003673,10}};
constexpr Rank PuppeteerRanks[]={{9003670,10}};
constexpr Rank PuppetRanks[]={{9003680,11},{9003681,18},{9003682,24},{9003683,30},{9003684,36},{9003685,42},{9003686,48},{9003687,54},{9003688,60},{9003689,68}};
constexpr Rank SpiritHealerRanks[]={{9003630,20}};
constexpr Rank LoaPresenceRanks[]={{9003631,30}};
constexpr Rank SpiritualTraditionsRanks[]={{9003632,30}};
constexpr Rank AlchemicalEnhancementRanks[]={{9003633,30}};
constexpr Rank PotentMixesRanks[]={{9003620,30},{9003621,40}};
constexpr Rank MojoAddictionRanks[]={{9003622,30},{9003623,40}};
constexpr Rank BrewmasterRanks[]={{9003624,30},{9003625,40}};
constexpr Rank StyleRanks[]={{9003610,10}};
constexpr Rank ZalazaneRanks[]={{9003611,10}};
constexpr Rank DaVoodooRanks[]={{9003612,30}};
constexpr Rank HollowRanks[]={{9003600,30}};
constexpr Rank CauldronRanks[]={{9003590,60}};
constexpr Rank BigVoodooRanks[]={{9003580,40}};
constexpr Rank ShadowflareRanks[] = {{9003560,16},{9003561,22},{9003562,28},{9003563,34},{9003564,40},{9003565,46},{9003566,52},{9003567,58},{9003568,60},{9003569,76},{9003570,80},{9003571,84},{9003572,90}};
constexpr Rank AlchemistRanks[]={{9003550,1}};
constexpr Rank RiteRanks[]={{9003540,30}};
constexpr Rank RecallRanks[]={{9003541,30}};
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
// WD34A: separately purchased seven-rank food/drink creation families.
constexpr Rank CocktailRanks[] = {{9003310,4},{9003311,10},{9003312,16},{9003313,26},{9003314,36},{9003315,46},{9003316,56}};
constexpr Rank StewRanks[] = {{9003320,6},{9003321,10},{9003322,20},{9003323,30},{9003324,40},{9003325,50},{9003326,58}};
// WD35A: one purchased family, five healing consumable ranks.
constexpr Rank RejuvenatingMojoRanks[] = {{9003350,12},{9003351,22},{9003352,34},{9003353,46},{9003354,58}};
constexpr Rank SpiritIdolRanks[] = {{9003370,14}};
constexpr Rank DarkIdolRanks[] = {{9003380,56}};
constexpr Rank JungleIdolRanks[] = {{9003382,52}};
constexpr Rank SereneIdolRanks[] = {{9003390,60}};
constexpr Rank SentryWardRanks[] = {{9003400,30}};
constexpr Rank ShadowEffigyRanks[] = {{9003410,8}};
constexpr Rank HexingEffigyRanks[] = {{9003420,24}};
constexpr Rank GravenEffigyRanks[] = {{9003422,34}};
constexpr Rank CursedEffigyRanks[] = {{9003430,58}};
constexpr Rank SwiftIdolRanks[] = {{9003432,28}};
constexpr Rank CleansingIdolRanks[] = {{9003440,16}};
constexpr Rank MassAllcureRanks[] = {{9003442,58}};
constexpr Rank StasisWardRanks[] = {{9003450,14}};
constexpr Rank TouchMuehzalaRanks[] = {{9003452,30}};
constexpr Rank BottleRanks[] = {{9003460,16},{9003461,24},{9003462,32},{9003463,40},{9003464,48},{9003465,56},{9003466,60},{9003467,68}};
constexpr Rank TouchSpiritsRanks[] = {{9003470,16}};
constexpr Rank LoaBlessingRanks[] = {{9003480,30}};
constexpr Rank JungleSecretsRanks[] = {{9003481,30}};
constexpr Rank BadJujuRanks[] = {{9003103,15},{9003491,22},{9003492,28},{9003493,34},{9003494,40},{9003495,46},{9003496,52},{9003497,58},{9003498,60}};
constexpr Rank HexfireRanks[] = {{9003500,15},{9003501,22},{9003502,30},{9003503,38},{9003504,46},{9003505,54},{9003506,60},{9003507,68}};
constexpr Rank NightRanks[] = {{9003510,30}};
constexpr Rank JindoRanks[] = {{9003511,30}};
constexpr Rank MalignantRanks[] = {{9003520,30}};
constexpr Rank HexplosionRanks[] = {{9003521,30}};
constexpr Rank GrowingMaliceRanks[] = {{9003530,30}};
constexpr Rank BerserkingRanks[] = {{9003532,30}};
constexpr Family Families[] = {
    {MimicRanks,1,false},{PuppeteerRanks,1,false},{PuppetRanks,10,false},
    {JujuInjectionRanks,sizeof(JujuInjectionRanks)/sizeof(Rank),false},
    {SeekerRanks,sizeof(SeekerRanks)/sizeof(Rank),false},
    {HastenedRanks,sizeof(HastenedRanks)/sizeof(Rank),false},
    {DarkMojoRanks,sizeof(DarkMojoRanks)/sizeof(Rank),false},
    {WizenedRanks,sizeof(WizenedRanks)/sizeof(Rank),false},
    {LoaStrengthRanks,sizeof(LoaStrengthRanks)/sizeof(Rank),false},
    {SpiritHealerRanks,sizeof(SpiritHealerRanks)/sizeof(Rank),false},
    {LoaPresenceRanks,sizeof(LoaPresenceRanks)/sizeof(Rank),false},
    {SpiritualTraditionsRanks,sizeof(SpiritualTraditionsRanks)/sizeof(Rank),false},
    {AlchemicalEnhancementRanks,sizeof(AlchemicalEnhancementRanks)/sizeof(Rank),false},
    {PotentMixesRanks,sizeof(PotentMixesRanks)/sizeof(Rank),false},
    {MojoAddictionRanks,sizeof(MojoAddictionRanks)/sizeof(Rank),false},
    {BrewmasterRanks,sizeof(BrewmasterRanks)/sizeof(Rank),false},
    {StyleRanks,sizeof(StyleRanks)/sizeof(Rank),false},
    {ZalazaneRanks,sizeof(ZalazaneRanks)/sizeof(Rank),false},
    {DaVoodooRanks,sizeof(DaVoodooRanks)/sizeof(Rank),false},
    {HollowRanks,sizeof(HollowRanks)/sizeof(Rank),false},
    {CauldronRanks,sizeof(CauldronRanks)/sizeof(Rank),false},
    {BigVoodooRanks,sizeof(BigVoodooRanks)/sizeof(Rank),false},
    {ShadowflareRanks, sizeof(ShadowflareRanks)/sizeof(Rank), false},
    {AlchemistRanks, sizeof(AlchemistRanks)/sizeof(Rank), true},
    {RiteRanks, sizeof(RiteRanks)/sizeof(Rank), false},
    {RecallRanks, sizeof(RecallRanks)/sizeof(Rank), false},
    {GrowingMaliceRanks,sizeof(GrowingMaliceRanks)/sizeof(Rank),false},
    {BerserkingRanks,sizeof(BerserkingRanks)/sizeof(Rank),false},
    {MalignantRanks,sizeof(MalignantRanks)/sizeof(Rank),false},
    {HexplosionRanks,sizeof(HexplosionRanks)/sizeof(Rank),false},
    {NightRanks,sizeof(NightRanks)/sizeof(Rank),false},
    {JindoRanks,sizeof(JindoRanks)/sizeof(Rank),false},
    {BadJujuRanks, sizeof(BadJujuRanks)/sizeof(Rank), false},
    {HexfireRanks, sizeof(HexfireRanks)/sizeof(Rank), false},
    {LoaBlessingRanks, sizeof(LoaBlessingRanks)/sizeof(Rank), false},
    {JungleSecretsRanks, sizeof(JungleSecretsRanks)/sizeof(Rank), false},
    {BottleRanks, sizeof(BottleRanks)/sizeof(Rank), false},
    {TouchSpiritsRanks, sizeof(TouchSpiritsRanks)/sizeof(Rank), false},
    {StasisWardRanks, sizeof(StasisWardRanks)/sizeof(Rank), false},
    {TouchMuehzalaRanks, sizeof(TouchMuehzalaRanks)/sizeof(Rank), false},
    {CleansingIdolRanks, sizeof(CleansingIdolRanks)/sizeof(Rank), false},
    {MassAllcureRanks, sizeof(MassAllcureRanks)/sizeof(Rank), false},
    {CursedEffigyRanks, sizeof(CursedEffigyRanks)/sizeof(Rank), false},
    {SwiftIdolRanks, sizeof(SwiftIdolRanks)/sizeof(Rank), false},
    {HexingEffigyRanks, sizeof(HexingEffigyRanks)/sizeof(Rank), false},
    {GravenEffigyRanks, sizeof(GravenEffigyRanks)/sizeof(Rank), false},
    {ShadowEffigyRanks, sizeof(ShadowEffigyRanks)/sizeof(Rank), false},
    {SentryWardRanks, sizeof(SentryWardRanks)/sizeof(Rank), false},
    {SereneIdolRanks, sizeof(SereneIdolRanks)/sizeof(Rank), false},
    {DarkIdolRanks, sizeof(DarkIdolRanks)/sizeof(Rank), false},
    {JungleIdolRanks, sizeof(JungleIdolRanks)/sizeof(Rank), false},
    {SpiritIdolRanks, sizeof(SpiritIdolRanks)/sizeof(Rank), false},
    {RejuvenatingMojoRanks, sizeof(RejuvenatingMojoRanks)/sizeof(Rank), false},
    {CocktailRanks, sizeof(CocktailRanks)/sizeof(Rank), false},
    {StewRanks, sizeof(StewRanks)/sizeof(Rank), false},

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
    if (spell==9003490) spell=9003103; // Retired WD48A duplicate, including saved action bars.
    for (Family const& family : Families)
        for (std::size_t i=0; i<family.count; ++i)
            if (family.ranks[i].spell==spell) return &family;
    return nullptr;
}
static inline bool IsBadJuju(uint32 spell)
{
    return spell==9003103 || (spell>=9003490 && spell<=9003498);
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
