/*
 * mod-dungeon-clear — DcPlayerRuns.h  (RebornWOW DCRUN1A)
 *
 * The player's own dungeon-clear runs (design doc §13): one record per run of a
 * party a real player leads, for the panel's "Dungeon runs" column.
 *
 *   start   `dc on` on the party's DC tank (DcOnAction)        -- map thread
 *   bosses  every dungeon boss that dies in the run's instance  -- map thread
 *   deaths  every party player / NPCBot that dies there         -- map thread
 *   end     DcActionShared::DisableDungeonClear (all end paths) -- any thread
 *
 * `dc on` again in the same instance within 30 minutes of an unfinished end (a wipe,
 * a stop) continues the same record ("restarts"), so a wipe does not leave two rows.
 * `.dc test` runs and bot-only parties (no real player to own it) are not recorded.
 * DCRUN1B: every real player in the party at a `dc on` (start or restart) is a viewer
 * of the run and gets their own copy of the finished record (deleted per player).
 * Finished runs are appended to dc_playerruns.jsonl (a continued run is appended
 * again; the last line of an id wins) and the last 20 per owner are kept in memory.
 * Everything is behind one mutex; the addon requests are answered from it on the
 * world thread.
 */

#ifndef MOD_DUNGEON_CLEAR_DC_PLAYER_RUNS_H
#define MOD_DUNGEON_CLEAR_DC_PLAYER_RUNS_H

#include "Define.h"
#include <functional>
#include <string>

class Player;

namespace DcPlayerRuns
{
    using Send = std::function<void(std::string const&)>;

    void OnRunStarted(Player* tank, uint32 bossTotal);
    void OnRunEnded(Player* tank, std::string const& reason);
    void RegisterScripts();

    // Addon "myruns": MR_START, MR <fields>..., MR_END.
    void SendList(Player* player, Send const& send);
    // Addon "myrun <id>": MRX <id> <R|S|M|B|D> ..., MRX_END <id>.
    void SendDetail(Player* player, std::string const& id, Send const& send);
    // Addon "myrundel <id|all>": finished runs only.
    void Delete(Player* player, std::string const& id);
}

#endif
