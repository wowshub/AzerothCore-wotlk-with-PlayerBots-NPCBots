/*
 * mod-dungeon-clear — DcSelfBot.h  (RebornWOW DCSB1A)
 *
 * One-click "let the AI play my character" for the DungeonClear panel.
 * playerbots already supports self-bot mode (`.playerbots bot self`); this
 * wraps it for the addon so the player never types a command:
 *
 *   selfbot tank|heal|dps  turn self-bot on (or keep it on) and play that role
 *   selfbot off            hand the character back to the player
 *   selfbot state          report the current state
 *
 * Enabling and disabling go through the playerbots `self` command handler, so
 * the AiPlayerbot.SelfBotLevel permission rules apply unchanged. The role picks
 * the class's tank / heal / dps strategies (the same names AiFactory uses);
 * when talents already fit the role nothing is changed. Classes without that
 * role in playerbots (and custom classes such as the Witch Doctor) fall back
 * to following and assisting as dps. The dungeon-clear follower strategies are
 * added so a self-botted player moves with the run like any party bot.
 *
 * Replies are complete addon payloads ("DC\tSELFBOT\t...").
 */

#ifndef MOD_DUNGEON_CLEAR_DC_SELF_BOT_H
#define MOD_DUNGEON_CLEAR_DC_SELF_BOT_H

#include <functional>
#include <string>

class Player;

namespace DcSelfBot
{
    using Reply = std::function<void(std::string const&)>;

    void Handle(Player* player, std::string const& param, Reply const& reply);

    // "DC\tSELFBOT\t<1|0>\t<tank|heal|dps|>" for the panel's buttons.
    std::string StateLine(Player* player);

    // Forget the remembered role (logout).
    void Forget(Player* player);
}

#endif
