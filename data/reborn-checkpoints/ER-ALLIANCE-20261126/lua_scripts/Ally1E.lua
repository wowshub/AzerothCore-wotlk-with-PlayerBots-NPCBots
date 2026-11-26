-- Ally1E.lua (ALLY1E V1, 2026-11-25, Claude) - candidate, NOT user-tested.
-- Alliance quests 55194 (Quartermaster Richter) and 55639 (pit): cocoons 9350797, Ralia Dreamchaser 156929 and her ride out of the pit.
-- The cocoon and ride code is the Horde Pit1A.lua (PIT1D V1). Hrun the Exiled is shared by both factions and stays scripted by Pit1A.lua,
-- which must be loaded too.
local Q_PIT = 55639
local COCOON, HRUN, CRENNA = 9350797, 156900, 156929      -- CRENNA = Ralia Dreamchaser on the Alliance side
local ELK = 9167012                        -- taxi mount creature of Ralia (world_ally1e.sql)
local LOCK_SECONDS, DESPAWN_MS = 60, 800
local FACTION_FRIENDLY, FACTION_HOSTILE = 35, 14

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
        print("[Ally1E] cocoon freed at " .. math.floor(go:GetX()) .. "," .. math.floor(go:GetY()))
        go:RegisterEvent(function(_, _, _, g)
            local ok2, e2 = pcall(function() g:Despawn() end)
            if not ok2 then print("[Ally1E] cocoon despawn error: " .. tostring(e2)) end
        end, DESPAWN_MS, 1)
        return false
    end)
    if not ok then print("[Ally1E] cocoon ERROR: " .. tostring(res)); return false end
    return res
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
    print("[Ally1E] Ralia ride path: " .. #out .. " points, " .. snapped .. " snapped to the ground, taxi path id " .. tostring(FLY_PATH))
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
                msg(p, "|cff00ff00You escaped the pit! Report back to Jaina. / 你逃出了深坑！回去向吉安娜复命。|r")
            end
        elseif (not seen and ticks >= 5) or ticks >= 150 then
            p:RemoveEventById(eventId)
            flying[guid] = nil
            if not seen then msg(p, "|cffff8800The ride did not start, talk to Ralia again. / 骑乘没有开始，请再和拉莉亚说话。|r") end
        end
    end, 1000, 0)
end

RegisterCreatureGossipEvent(CRENNA, 1, function(event, player, creature)       -- GOSSIP_EVENT_ON_HELLO
    if not player:HasQuest(Q_PIT) then
        creature:SendUnitSay("The spirits are restless here. 这里的灵魂不得安宁。", 0)
        player:GossipComplete()
        return
    end
    if flying[player:GetGUIDLow()] then player:GossipComplete(); return end
    local hrun = creature:GetNearestCreature(80, HRUN)
    if hrun and hrun:IsAlive() and hrun:GetFaction() ~= FACTION_FRIENDLY then      -- Pit1A.lua makes him friendly when he yields
        creature:SendUnitSay("Defeat Hrun first! 先打败赫鲁恩！", 0)
        player:GossipComplete()
        return
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
    return
end)

-- PIT1D: taking the quest (again, after abandoning it because of a crash or any interruption) starts from a clean state:
-- no leftover "already on the ride" lock; the cocoons come back by themselves (60 s) and Hrun respawns after 60 s (SQL)
RegisterPlayerEvent(63, function(event, player, quest)       -- PLAYER_EVENT_ON_QUEST_ACCEPT
    if player and quest and quest:GetId() == Q_PIT then
        flying[player:GetGUIDLow()] = nil
    end
end)

-- ---------------------------------------------------------------- Quartermaster Richter (55194)
local Q_SUPPLY, RICHTER = 55194, 156800
RegisterCreatureGossipEvent(RICHTER, 1, function(event, player, creature)
    if player:HasQuest(Q_SUPPLY) then
        player:KilledMonsterCredit(RICHTER)
        creature:SendUnitSay("Take a look. We saved what we could. 看看吧，能抢救的我们都抢救出来了。", 0)
    end
    player:SendListInventory(creature)
end)

print("[Ally1E] ALLY1E V1 loaded: quests 55194 / 55639, cocoon " .. COCOON .. ", Ralia " .. CRENNA .. ", mount " .. ELK)
