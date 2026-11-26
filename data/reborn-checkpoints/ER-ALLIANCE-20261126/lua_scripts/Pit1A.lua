-- Pit1A.lua (PIT1D V1 = Pit1A V4, 2026-11-25, Claude) - candidate, NOT user-tested. Replaces the PIT1C V1 file of the same name.
-- PIT1D: quest 59949 can be abandoned and taken again after a crash/interruption without getting stuck: clean state on accept, and if Hrun is not
-- there (not respawned yet) Crenna's ride counts him as defeated for that player. Hrun respawns after 60 s instead of 300 s (world_pit1d.sql).
-- PIT1C: the elk ride hugs the ground (server ground height under the curve, 2-yard samples, lifted only 0.5) and keeps away from the outer wall
-- on the spiral (curve pulled 2 yards toward the pit centre). The speed cannot be changed: the core flies every taxi path at 32 yards/second.
-- Quest 59949 "Who Lurks in the Pit":
--   * Thick Cocoons (go 9350796): the core gives the quest credit; the cocoon is consumable, this script despawns it and refuses a second click
--     on the same cocoon within 60 s (same pattern as the Harpy Totem, HARPY1C V4).
--   * Hrun the Exiled (156900): fights with two stock abilities (Strike 11976, Thunderclap 8078, as in Medviten's exiles_reach.cpp); at low health he
--     yields (retail: he is defeated, not killed), the attacker gets the credit.
--   * Crenna Earth-Daughter (167254): once Hrun has yielded, talking to her takes the player out of the pit on her elk (taxi flight on the mount creature
--     9167011). V2 changes the route: instead of a straight line (it cut through the pit wall) the ride follows retail's own waypoint path 55640, the
--     spiral way back up the cave (20 nodes, LoreWalkerTDB waypoint_path_node), smoothed with a Catmull-Rom curve and sampled every ~5 yards.
local Q_PIT = 59949
local COCOON, HRUN, CRENNA = 9350796, 156900, 167254
local ELK = 9167011                        -- taxi mount creature with the elk-like display (world_pit1b.sql)
local LOCK_SECONDS, DESPAWN_MS = 60, 800
local YIELD_PCT = 20
local FACTION_FRIENDLY, FACTION_HOSTILE = 35, 14
local SPELL_STRIKE, SPELL_THUNDERCLAP = 11976, 8078

local function msg(p, s) p:SendBroadcastMessage(s) end

-- ---------------------------------------------------------------- cocoons
local usedAt = {}
RegisterGameObjectEvent(COCOON, 14, function(event, go, player)       -- GAMEOBJECT_EVENT_ON_USE
    local ok, res = pcall(function()
        local gl = go:GetGUIDLow()
        local now = os.time()
        if usedAt[gl] and now - usedAt[gl] < LOCK_SECONDS then return true end
        usedAt[gl] = now
        if player then msg(player, "|cff00ff00You cut the cocoon open and free a trapped soldier! / 你割开了茧，救出了一名被困的士兵！|r") end
        print("[Pit1A] cocoon freed at " .. math.floor(go:GetX()) .. "," .. math.floor(go:GetY()))
        go:RegisterEvent(function(_, _, _, g)
            local ok2, e2 = pcall(function() g:Despawn() end)
            if not ok2 then print("[Pit1A] cocoon despawn error: " .. tostring(e2)) end
        end, DESPAWN_MS, 1)
        return false
    end)
    if not ok then print("[Pit1A] cocoon ERROR: " .. tostring(res)); return false end
    return res
end)

-- ---------------------------------------------------------------- Hrun
local yielded = {}      -- [hrun guid low] = true after he yielded to somebody

local function resetHrun(c)
    c:RemoveEvents()
    yielded[c:GetGUIDLow()] = nil
    c:SetFaction(FACTION_HOSTILE)
end

RegisterCreatureEvent(HRUN, 5, function(event, creature) resetHrun(creature) end)          -- ON_SPAWN
RegisterCreatureEvent(HRUN, 2, function(event, creature)                                   -- ON_LEAVE_COMBAT
    creature:RemoveEvents()
    if not yielded[creature:GetGUIDLow()] then creature:SetHealth(creature:GetMaxHealth()) end
end)
RegisterCreatureEvent(HRUN, 1, function(event, creature, target)                           -- ON_ENTER_COMBAT
    creature:RemoveEvents()
    creature:RegisterEvent(function(_, _, _, c)
        local v = c:GetVictim()
        if v then c:CastSpell(v, SPELL_STRIKE, false) end
    end, 9000, 0)
    creature:RegisterEvent(function(_, _, _, c) c:CastSpell(c, SPELL_THUNDERCLAP, false) end, 17000, 0)
end)

RegisterCreatureEvent(HRUN, 9, function(event, creature, attacker, damage)                 -- ON_DAMAGE_TAKEN
    local gl = creature:GetGUIDLow()
    if yielded[gl] then return true, 0 end
    local after = creature:GetHealth() - (damage or 0)
    if after * 100 / creature:GetMaxHealth() > YIELD_PCT then return end
    yielded[gl] = true
    local p = attacker
    if p and p.GetObjectType and p:GetObjectType() ~= "Player" and p.GetOwner then p = p:GetOwner() end
    creature:RemoveEvents()
    creature:SetFaction(FACTION_FRIENDLY)
    creature:ClearThreatList()
    creature:AttackStop()
    creature:ClearInCombat()
    creature:SendUnitSay("Enough... I yield. Take the druid and go. 够了……我认输。带上德鲁伊走吧。", 0)
    if p and p.KilledMonsterCredit then p:KilledMonsterCredit(HRUN) end
    print("[Pit1A] Hrun yielded")
    creature:DespawnOrUnsummon(8000)
    return true, 0
end)

-- ---------------------------------------------------------------- Crenna's ride out of the pit (retail path 55640)
-- retail: Crenna's spawn (path 55639 node 0), then waypoint_path_node of path 55640, nodes 0..19 (x, y, z on the cave floor)
local RETAIL = {
    {73.1546, -2127.05, -29.6513},
    {95.7999, -2183.24, -25.628},
    {82.1485, -2215.47, -20.465},
    {124.998, -2244.52, -5.37676},
    {111.528, -2276.02, -3.46595},
    {84.4113, -2278.6, -3.50065},
    {34.9377, -2255.23, 2.40018},
    {20.2251, -2199.66, 14.6711},
    {66.7063, -2188.2, 23.6183},
    {107.033, -2227.31, 34.2311},
    {122.863, -2274.69, 41.9643},
    {108.053, -2288.47, 50.967},
    {81.1092, -2275.86, 61.0104},
    {70.3342, -2262.02, 66.3149},
    {70.0464, -2242.53, 67.9546},
    {63.9554, -2232.4, 72.1711},
    {66.7911, -2223.7, 74.6839},
    {74.1231, -2219.36, 78.8274},
    {83.2505, -2223.27, 83.3383},
    {86.385, -2239.05, 92.4443},
    {92.191, -2249.55, 94.7449},
    {90.5, -2251.5, 95.2}          -- a step further, next to Lana at the rim (89.8,-2251.8,95.1)
}
local LIFT = 0.5          -- ride this far above the ground (PIT1B: 1.5 above the retail nodes)
local STEP = 2.0          -- yards between sampled points (PIT1B: 5)
local INWARD = 2.0        -- yards the curve is pulled toward the pit centre on the spiral stretch, away from the outer wall
local CENTER_X, CENTER_Y = 75.0, -2235.0     -- the spiral's rough centre (retail nodes circle it)
local SNAP_TOL = 5.0      -- the server ground height replaces the curve's height only when it is within this many yards of it
local SMOOTH = 2          -- moving-average half window over the final heights, so the ride does not jitter on small bumps

local function dist3(a, b)
    local dx, dy, dz = a[1] - b[1], a[2] - b[2], a[3] - b[3]
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function catmull(p0, p1, p2, p3, t)
    local t2, t3 = t * t, t * t * t
    local r = {}
    for k = 1, 3 do
        r[k] = 0.5 * ((2 * p1[k]) + (-p0[k] + p2[k]) * t + (2 * p0[k] - 5 * p1[k] + 4 * p2[k] - p3[k]) * t2 + (-p0[k] + 3 * p1[k] - 3 * p2[k] + p3[k]) * t3)
    end
    return r
end

local function buildFlight()
    local out = {}
    local n = #RETAIL
    for i = 1, n - 1 do
        local p1, p2 = RETAIL[i], RETAIL[i + 1]
        local p0 = RETAIL[i - 1] or p1
        local p3 = RETAIL[i + 2] or p2
        local steps = math.max(1, math.ceil(dist3(p1, p2) / STEP))
        for s = 0, steps - 1 do
            local q = catmull(p0, p1, p2, p3, s / steps)
            out[#out + 1] = {q[1], q[2], q[3]}
        end
    end
    local last = RETAIL[n]
    out[#out + 1] = {last[1], last[2], last[3]}
    return out
end

-- pull the sampled curve toward the pit centre on the spiral stretch (z between -22 and 80), so bends keep away from the outer wall
local function pullInward(pts)
    for _, q in ipairs(pts) do
        if q[3] > -22 and q[3] < 80 then
            local dx, dy = CENTER_X - q[1], CENTER_Y - q[2]
            local d = math.sqrt(dx * dx + dy * dy)
            if d > INWARD + 1 then
                q[1] = q[1] + dx / d * INWARD
                q[2] = q[2] + dy / d * INWARD
            end
        end
    end
end

-- built once, on the first ride (needs the map for the ground height): ground-hugging points
local FLY_PATH = nil
local function getFlyPath(player)
    if FLY_PATH then return FLY_PATH end
    local pts = buildFlight()
    pullInward(pts)
    local map = player:GetMap()
    local snapped, zs = 0, {}
    for i, q in ipairs(pts) do
        local z = q[3]
        local ok, h = pcall(function() return map:GetHeight(q[1], q[2]) end)
        if ok and h and math.abs(h - z) <= SNAP_TOL then
            z = h
            snapped = snapped + 1
        end
        zs[i] = z
    end
    local out = {}
    for i, q in ipairs(pts) do
        local sum, cnt = 0, 0
        for k = math.max(1, i - SMOOTH), math.min(#pts, i + SMOOTH) do sum = sum + zs[k]; cnt = cnt + 1 end
        local z = sum / cnt
        if i == 1 or i == #pts then z = zs[i] end
        out[i] = {12175, q[1], q[2], z + LIFT}
    end
    FLY_PATH = AddTaxiPath(out, ELK, ELK)
    print("[Pit1A] Crenna ride path: " .. #out .. " points, " .. snapped .. " snapped to the ground, taxi path id " .. tostring(FLY_PATH))
    return FLY_PATH
end
local UNIT_STATE_IN_FLIGHT = 0x100
local flying = {}

local function watchFlight(player)
    local guid = player:GetGUIDLow()
    flying[guid] = true
    local seen, ticks = false, 0
    player:RegisterEvent(function(eventId, delay, calls, p)
        ticks = ticks + 1
        local inFlight = p:HasUnitState(UNIT_STATE_IN_FLIGHT)
        if inFlight then seen = true end
        if seen and not inFlight then
            p:RemoveEventById(eventId)
            flying[guid] = nil
            if p:HasQuest(Q_PIT) then
                p:KilledMonsterCredit(CRENNA)
                msg(p, "|cff00ff00You escaped the pit! Report back to Thrall. / 你逃出了深坑！回去向萨尔复命。|r")
            end
        elseif (not seen and ticks >= 5) or ticks >= 150 then
            p:RemoveEventById(eventId)
            flying[guid] = nil
            if not seen then msg(p, "|cffff8800The ride did not start, talk to Crenna again. / 骑乘没有开始，请再和克蕾娜说话。|r") end
        end
    end, 1000, 0)
end

RegisterCreatureGossipEvent(CRENNA, 1, function(event, player, creature)       -- GOSSIP_EVENT_ON_HELLO
    if not player:HasQuest(Q_PIT) then
        creature:SendUnitSay("The spirits are restless here. 这里的灵魂不得安宁。", 0)
        player:GossipComplete()
        return false
    end
    if flying[player:GetGUIDLow()] then player:GossipComplete(); return false end
    local hrun = creature:GetNearestCreature(80, HRUN)
    if hrun and hrun:IsAlive() and not yielded[hrun:GetGUIDLow()] then
        creature:SendUnitSay("Defeat Hrun first! 先打败赫鲁恩！", 0)
        player:GossipComplete()
        return false
    end
    if not hrun then
        -- PIT1D: Hrun is gone (he left after yielding to somebody else and has not respawned yet, or the quest was abandoned and taken again):
        -- count him as defeated for this player so the quest can never get stuck waiting for his respawn (extra credit calls are harmless)
        player:KilledMonsterCredit(HRUN)
        msg(player, "|cff00ff00Hrun is gone; the way out is open. / 赫鲁恩已经不在了，出路畅通。|r")
    end
    creature:SendUnitSay("Climb on! I'll carry you out the way we came. 上来！我原路带你出去。", 0)
    player:GossipComplete()
    if player:IsMounted() then player:Dismount() end
    player:StartTaxi(getFlyPath(player))
    watchFlight(player)
    return false
end)

-- PIT1D: taking the quest (again, after abandoning it because of a crash or any interruption) starts from a clean state:
-- no leftover "already on the ride" lock; the cocoons come back by themselves (60 s) and Hrun respawns after 60 s (SQL)
RegisterPlayerEvent(63, function(event, player, quest)       -- PLAYER_EVENT_ON_QUEST_ACCEPT
    if player and quest and quest:GetId() == Q_PIT then
        flying[player:GetGUIDLow()] = nil
    end
end)

print("[Pit1A] PIT1D V1 loaded: quest " .. Q_PIT .. ", cocoon " .. COCOON .. ", Hrun " .. HRUN .. ", Crenna " .. CRENNA .. ", elk " .. ELK)
