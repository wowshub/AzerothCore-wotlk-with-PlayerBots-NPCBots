/*
 * mod-dungeon-clear — DcPartyTier.h  (RebornWOW DCGM1F)
 *
 * The GM cheat tier of YOUR OWN party (design doc §9, "mode 1"): the party you
 * lead yourself from the dungeon-clear panel -- your account's characters, bots
 * found in the world or in the who-list (playerbots), and your NPCBots. Other
 * real players are never touched.
 *
 * Tiers are the `.dc test` ones (DCGM1B): story = invincible + unlimited power;
 * casual = the same, half damage; speed = also no cooldowns / instant casts and
 * 10x damage; normal = all off. Playerbots get the core cheat flags; NPCBots are
 * creatures the flags do not reach, so for them invincible is done in the damage
 * hook (IsNpcBotGod), power is refilled by Tick, and the damage multiplier is
 * keyed by the NPCBot's own guid (keying it by the owner would scale the owner's
 * damage too). NPCBots have no cooldown / cast-time switch: speed = 10x only.
 *
 * The tier belongs to the leader who set it. Tick keeps it true: a bot that
 * joins the party picks it up, a bot that leaves the party (or an NPCBot that is
 * dismissed) drops it, and everything is dropped when the leader logs out.
 * World thread, except IsNpcBotGod (damage hook, map threads; own mutex).
 */

#ifndef MOD_DUNGEON_CLEAR_DC_PARTY_TIER_H
#define MOD_DUNGEON_CLEAR_DC_PARTY_TIER_H

#include "ObjectGuid.h"
#include <string>
#include <vector>

class Player;

namespace DcPartyTier
{
    // Set the tier ("normal" | "story" | "casual" | "speed") of the party `leader`
    // leads (or of `leader` alone). Returns the names of the bots it now covers.
    std::vector<std::string> Apply(Player* leader, std::string const& tier);

    // The tier of the party `player` is in ("normal" when nobody set one).
    std::string TierFor(Player* player);

    // Damage hook: is this NPCBot covered by a tier (invincible)?
    bool IsNpcBotGod(ObjectGuid guid);

    // Once a second from the world tick.
    void Tick(uint32 diff);
}

#endif
