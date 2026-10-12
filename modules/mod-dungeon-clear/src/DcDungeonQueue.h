/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license, you may redistribute it
 * and/or modify it under version 3 of the License, or (at your option), any later version.
 */

#ifndef _DC_DUNGEON_QUEUE_H
#define _DC_DUNGEON_QUEUE_H

#include <string>

class Player;

// RebornWOW DCQ1A: continuous clear. The panel sends a list of dungeon tokens
// (rows of DcTestDungeonRegistry); the party is teleported into each one in
// turn, the clear is started on the party's DC tank, and when it reports
// "All bosses cleared!" the dungeon is reset (DcInstanceReset) and the next one
// starts.
//
//   - A wipe (any other run end) revives the whole party at that dungeon's
//     entrance and restarts the clear; the same dungeon failing twice is skipped.
//   - Before each dungeon: fewer than 5 free bag slots, or any equipped item
//     under 20% durability, on anyone in the party pauses the queue.
//   - A manual "dc off" pauses it; Resume continues the same dungeon.
//
// Everything runs on the world thread: commands arrive through the addon chat
// hook (CMSG_MESSAGECHAT is PROCESS_THREADUNSAFE) and the state machine is a
// WorldScript update. Run-end reports come from bot AI updates (map threads)
// and are only queued into a locked mailbox there.
namespace DcDungeonQueue
{
    // Addon "queue" subcommand. param: "list" | "start\t<tok,tok,...>" | "stop" |
    // "resume" | "state".
    void HandleAddon(Player* player, std::string const& param);

    // From DcActionShared::DisableDungeonClear (any thread): the run on `tank`
    // ended with `reason`.
    void OnRunDisabled(Player* tank, std::string const& reason);
}

#endif  // _DC_DUNGEON_QUEUE_H
