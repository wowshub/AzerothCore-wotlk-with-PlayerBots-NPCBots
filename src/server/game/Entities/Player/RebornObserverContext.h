// OB8B: server-owned transient routing; never accepted from an addon packet.
#ifndef REBORN_OBSERVER_CONTEXT_H
#define REBORN_OBSERVER_CONTEXT_H
#include "Player.h"
#include "DataMap.h"
namespace RebornObserver
{
inline constexpr char Key[] = "RebornSpectator.InstanceRoute";
struct Context : DataMap::Base
{
    uint32 mapId = 0, instanceId = 0;
    ObjectGuid target;
    WorldLocation origin;
    bool returning = false;
};
inline Context* Get(Player const* player)
{ return player ? player->CustomData.Get<Context>(Key) : nullptr; }
inline bool Active(Player const* player) { return Get(player) != nullptr; }
inline bool Destination(Player const* player, uint32 mapId, uint32 instanceId)
{
    auto const* c = Get(player);
    return c && !c->returning && c->mapId == mapId && c->instanceId == instanceId;
}
}
#endif
