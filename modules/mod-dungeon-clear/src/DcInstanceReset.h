/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license, you may redistribute it
 * and/or modify it under version 3 of the License, or (at your option), any later version.
 */

#ifndef _DC_INSTANCE_RESET_H
#define _DC_INSTANCE_RESET_H

#include <string>

class Player;

// RebornWOW DCRST1A: one-click "reset this dungeon" for the panel.
//
// The stock way (everyone walks out, leader right-clicks the portrait, "Reset
// all instances") does nothing at all for a group the dungeon finder converted
// into an LFG group: Group::ResetInstances returns before doing anything and
// sends no message. That is the usual state here, because a hand-made bot
// party that queued once stays an LFG group until it is disbanded.
//
// Request() runs on the world thread (it is reached from the chat opcode,
// which is PROCESS_THREADUNSAFE):
//   1. checks the leader, difficulty, combat, deaths and an active clear run;
//   2. an LFG group is disbanded and the same playerbots are re-added to a new
//      ordinary group led by the requester (other real players are refused,
//      since they cannot be re-invited for them);
//   3. every member inside the dungeon is teleported to its exit;
//   4. once nobody is left inside, the normal-difficulty instances are reset.
// Step 4 waits for the teleports and is driven by a WorldScript update.
namespace DcInstanceReset
{
    // False with *whyNot set when the request is refused up front.
    bool Request(Player* leader, std::string* whyNot);

    // RebornWOW DCQ1A: true while a requested reset is still waiting for the
    // party to leave the dungeon (the continuous-clear queue waits on it).
    bool IsPending(Player* leader);
}

#endif  // _DC_INSTANCE_RESET_H
