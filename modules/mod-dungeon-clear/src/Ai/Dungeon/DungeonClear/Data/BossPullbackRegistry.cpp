/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license, you may redistribute it
 * and/or modify it under version 3 of the License, or (at your option), any later version.
 */

#include "BossPullbackRegistry.h"

#include <vector>

namespace
{
    // ---- the table ------------------------------------------------------
    //
    // CURRENTLY EMPTY. It has held exactly one row in its life — Ghaz'an
    // (18105, The Underbog 546) — and that row was retired in S1593. The
    // machinery is kept because the facility is general and the invariants are
    // tested; adding a boss is still a single entry here plus a matching
    // BossRosterPatch anchor.
    //
    // WHY GHAZ'AN'S ROW WENT AWAY, so nobody re-adds it from the old reasoning:
    //
    // The row existed because Ghaz'an was always found swimming in his lake, and
    // the party had to be walked ~147yd away to fight him on dry ground — with
    // force-aggro at 150yd and a teleport-if-stuck, because there was no
    // reachable spot inside his aggro bubble and no reliable way for him to
    // climb out. Every one of those was compensation for a single upstream
    // cause: `at_underbog_ghazan` (areatrigger 4302) is the ONLY caller of his
    // ACTION_MOVE_TO_PLATFORM, and a headless bot party never sent the
    // CMSG_AREATRIGGER that runs it. So he never left the water, and everything
    // downstream was built around meeting him there.
    //
    // DcTestAreaTriggers now sends that packet (and the Underbog "Send Ghaz'an
    // to his platform" event covers a route that misses the volume), so he
    // climbs waypoint path 1383921 onto his platform like he does for a real
    // party. Probed against the live mmaps rather than assumed:
    //
    //   * his platform end (256.28, -458.73) has walkable navmesh at z 81.45 —
    //     the SAME surface as (274.72, -462.60), the ledge boss-nav already
    //     drives the tank to for the drop-down objective;
    //   * his whole 12yd MoveRandom circle is on it (probed E/W/N/S/NE/SE, all
    //     z 81.45), so he cannot wander off the deck;
    //   * the deck connects to the old anchor by a continuous walkable ramp —
    //     (154.16,-452.03) z 73.58 -> (170,-460) 73.58 -> (190,-468) 75.98 ->
    //     (205,-472) 79.67 -> (215,-475) 81.08 -> the deck.
    //
    // The "his platform and the pipe are missing from the extracted navmesh"
    // finding this row was justified with was measured around his WATER HOME
    // (193.74, -423.40, 43.58) and never around the platform itself. The
    // platform is meshed. On dry, connected ground he is an ordinary boss, and
    // an ordinary pull is strictly better than a forced one.
    //
    // A row belongs here only when the ground a boss stands on genuinely kills
    // the party AND no upstream cause can be fixed instead. Check the second
    // half first — this row spent a long time treating a symptom.
    std::vector<BossPullback> const& Rows()
    {
        static std::vector<BossPullback> const rows = {
            // map  entry  anchor x  y  z  forceAggro  summonIfStuck
            //
            // RebornWOW DCHOL2B -- General Bjarngrim, Halls of Lightning. He laps an
            // OPEN ring of platforms (waypoint path 1269810: (1262,-26.6) <->
            // (1395.1,36.6), three floors, the ring's centre (1330,30) has no floor at
            // all) and his Knock Away sends the tank flying: live 2026-10-18 the tank
            // died wedged in the wall mid-pull, and the fight never released. The camp
            // is in the walled corridor 50yd north of his northernmost point, measured
            // in game by the user standing there (.gps 1445.72 40.80 58.77, map 602):
            // walls both sides, off his lap, and a knock-back from the south only
            // pushes the tank further into the corridor. Normal tag (no force-aggro).
            // DCHOL2C: the pull can fail for a reason outside the row (trash packs on the 170+ yd walk-in
            // take the tag); then fight him as an ordinary boss rather than stall the run.
            { 602, 28586, 1445.72f, 40.80f, 58.77f, 0.0f, false, true },
        };
        return rows;
    }
}

BossPullback const* BossPullbackRegistry::Find(uint32 mapId, uint32 bossEntry)
{
    for (BossPullback const& r : Rows())
        if (r.mapId == mapId && r.bossEntry == bossEntry)
            return &r;
    return nullptr;
}

bool BossPullbackRegistry::HasRows(uint32 mapId)
{
    for (BossPullback const& r : Rows())
        if (r.mapId == mapId)
            return true;
    return false;
}
