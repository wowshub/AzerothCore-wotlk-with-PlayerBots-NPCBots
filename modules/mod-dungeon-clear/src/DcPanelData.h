/*
 * mod-dungeon-clear — DcPanelData.h  (RebornWOW DCUI3B)
 *
 * Read-only data for the five-column panel (design doc §15):
 *
 *   dungeons            every dungeon and raid map the server has an instance
 *                       template for: map id, raid flag, sizes ("5", "10/25", "40"),
 *                       level, expansion, localized name, and the `.dc test` rows
 *                       (token, entrance) that mark it SUPPORTED by dungeon-clear.
 *   roster <cat>\t<q>   candidates for the party column, by category:
 *                       account (your characters), bots (online playerbots of your
 *                       faction, closest level first), npcbots (your hired NPCBots),
 *                       players (online real players; DungeonClear.PartyPicker.
 *                       RealPlayers 0 off / 1 friends+guild / 2 all), search (name
 *                       fragment across all of those). At most 40 rows.
 *
 * Public facts only (what /who and the LFG panel show). Replies are complete addon
 * payloads handed to `send`. World thread (addon chat).
 */

#ifndef MOD_DUNGEON_CLEAR_DC_PANEL_DATA_H
#define MOD_DUNGEON_CLEAR_DC_PANEL_DATA_H

#include <functional>
#include <string>

class Player;

namespace DcPanelData
{
    using Send = std::function<void(std::string const&)>;

    void SendDungeons(Player* player, Send const& send);
    void SendRoster(Player* player, std::string const& param, Send const& send);
}

#endif
