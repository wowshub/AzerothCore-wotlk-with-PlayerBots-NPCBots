#pragma once
#include "DataMap.h"
#include "Player.h"
// MBWD3A: session-only automatic preferences. No SQL or talent ownership writes.
namespace WDMB3
{
inline constexpr uint32 Buff=1,Cure=2,All=Buff|Cure,Version=1;
inline constexpr char Key[]="Reborn.MBWD3A.AutomaticPreferences";
struct Snapshot { uint32 revision=0,mask=All; };
enum class Result { Ok,Stale,Invalid };
struct Update { Snapshot value;Result result; };
constexpr Update Apply(Snapshot current,uint32 expected,uint32 mask)
{
    if(mask>All || current.revision>=2000000000u) return {current,Result::Invalid};
    if(expected!=current.revision) return {current,Result::Stale};
    if(mask!=current.mask) { current.mask=mask;++current.revision; }
    return {current,Result::Ok};
}
constexpr bool EnabledMask(uint32 mask,uint32 category) { return (mask&category)==category; }
constexpr uint32 Category(uint32 spell)
{
    if((spell>=9003140&&spell<=9003143)||(spell>=9003180&&spell<=9003185)||
        spell==9003190||spell==9003280||spell==9003290||spell==9003300) return Buff;
    // Includes the parent of the automatic cleansing idol. Existing summons
    // and passive/triggered effects are not despawned or globally suppressed.
    if(spell==9003240||spell==9003250||spell==9003442||spell==9004124||spell==9003440) return Cure;
    return 0;
}
constexpr bool AllowsMask(uint32 mask,uint32 spell)
{ auto category=Category(spell);return !category || EnabledMask(mask,category); }
struct State : DataMap::Base { Snapshot value; };
inline Snapshot Read(Player* player)
{
    if(player) if(auto* s=player->CustomData.Get<State>(Key)) return s->value;
    return {};
}
inline bool Enabled(Player* player,uint32 category) { return EnabledMask(Read(player).mask,category); }
inline bool Allows(Player* player,uint32 spell) { return AllowsMask(Read(player).mask,spell); }
inline Update Set(Player* player,uint32 expected,uint32 mask)
{
    auto result=Apply(Read(player),expected,mask);
    if(player && result.result==Result::Ok) player->CustomData.GetDefault<State>(Key)->value=result.value;
    return result;
}
}
