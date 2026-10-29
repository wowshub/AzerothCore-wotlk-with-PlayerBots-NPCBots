#pragma once
#include "DataMap.h"
#include "Player.h"
#include <array>
namespace WDAS4
{
inline constexpr uint32 Wards=1,Large=2,All=Wards|Large,Version=1;
inline constexpr char Key[]="Reborn.MBWD4B.AutomaticSummons";
inline constexpr std::array<uint32,15> Ordinary={9003160,9003170,9003450,9003400,9003953,9003370,9003440,9003432,9003382,9003380,9003390,9003410,9003420,9003422,9003430};
inline constexpr std::array<uint32,7> Major={9004080,9004182,9003580,9003800,9003673,9003810,9004181};
struct Snapshot{uint32 revision=0,mask=All;};
enum class Result{Ok,Stale,Invalid,Database};
struct Update{Snapshot value;Result result;};
constexpr uint32 Category(uint32 spell)
{
    for(auto id:Ordinary)if(id==spell)return Wards;
    for(auto id:Major)if(id==spell)return Large;
    return 0;
}
constexpr bool AllowsMask(uint32 mask,uint32 spell)
{auto category=Category(spell);return !category||(mask&category)==category;}
struct State:DataMap::Base{Snapshot value;bool persistent=false;};
inline Snapshot Read(Player* player)
{if(player)if(auto* s=player->CustomData.Get<State>(Key))return s->value;return {};}
inline bool Allows(Player* player,uint32 spell){return AllowsMask(Read(player).mask,spell);}
bool PersistenceAvailable();
bool LoadPersistent(Player*);
Update SetPersistent(Player*,uint32 expected,uint32 mask);
}
