/*
 * mod-dungeon-clear — DcUnderFloorRescue.h  (RebornWOW DCHOL2A)
 *
 * Some instance maps carry phantom floors BELOW the dungeon in the server's
 * navigation data: map 602 (Halls of Lightning) has continuous flat sheets at
 * z ~ -1.9 and z ~ -13.9 under its whole footprint (see DcHallsOfLightning in
 * DungeonEventTables.h). A member that drops through a hole lands on that sheet,
 * the server treats it as ground, and the party is then followed, teleported
 * (stranded recovery) and path-found around UNDER the dungeon — on the client it
 * is empty air over the outside terrain.
 *
 * Once a second, for every live dungeon-clear run on a listed map: a member below
 * the map's lowest real floor is brought back. Bots, and a player whose character
 * the AI is playing ("auto-play"), go onto the tank when the tank stands on real
 * ground, else onto their own last good position. A player playing by hand is not
 * moved; they get a chat line saying how to get back. World thread.
 */

#ifndef MOD_DUNGEON_CLEAR_DC_UNDER_FLOOR_RESCUE_H
#define MOD_DUNGEON_CLEAR_DC_UNDER_FLOOR_RESCUE_H

#include "Define.h"

namespace DcUnderFloorRescue
{
    void Tick(uint32 diff);
}

#endif
