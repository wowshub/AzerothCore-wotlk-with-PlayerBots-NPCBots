-- Ally1C.lua (ALLY1C V1, 2026-11-25, Claude) - candidate, NOT user-tested. New file; the Horde scripts are not changed.
-- Alliance copies of the tested Horde parts (Beach1C / Veh1A) with Alliance ids:
--   55193 Scout-o-Matic 5000 flight, 56034 Re-Sizer on the Wandering Boars, 55879 bombing run (vehicle 9167021, 8 cadavers).
do
local Q_BOOSTER, Q_RESIZE = 55193, 56034
local BOOSTER, BOAR = 156518, 156722
local RESIZER = 9178051
local BOAR_BASE, BOAR_BIG = 1.4, 3.4      -- must match the DisplayScale of creature 156722 in the SQL (1.4); big = what the Re-Sizer does for a few seconds

local function msg(p, s) p:SendBroadcastMessage(s) end

-- Choppy Booster: BOOST1A. Talking to the Booster with the quest starts a passenger flight (gnome copter): take off, fly over the cadaver
-- field, circle once, come back. The credit is given when the flight ends. (Taxi path built at load; display 28830 = stock GnomeCopter.)
local MOUNT = 9167010
local FLIGHT = {
    {12175, 107.87, -2414.18, 93.0},
    {12175, 135, -2392, 106},
    {12175, 165, -2365, 118},
    {12175, 181.2, -2346.8, 125.0},
    {12175, 213.0, -2360.0, 125.0},
    {12175, 244.8, -2346.8, 125.0},
    {12175, 258.0, -2315.0, 125.0},
    {12175, 244.8, -2283.2, 125.0},
    {12175, 213.0, -2270.0, 125.0},
    {12175, 181.2, -2283.2, 125.0},
    {12175, 168.0, -2315.0, 125.0},
    {12175, 181.2, -2346.8, 125.0},
    {12175, 160, -2370, 114},
    {12175, 130, -2395, 100},
    {12175, 101.5, -2417.5, 92.0}
}
local FLY_PATH = AddTaxiPath(FLIGHT, MOUNT, MOUNT)
local UNIT_STATE_IN_FLIGHT = 0x100
local flying = {}     -- [playerGuidLow] = true while a scouting flight is being watched

local SCOUT_X, SCOUT_Y, SCOUT_R = 213.0, -2315.0, 70.0    -- the flight must come within SCOUT_R yards (2D) of the cadaver field

local function watchFlight(player)
    local guid = player:GetGUIDLow()
    flying[guid] = true
    local seen, reached, ticks = false, false, 0
    player:RegisterEvent(function(eventId, delay, calls, p)
        ticks = ticks + 1
        local inFlight = p:HasUnitState(UNIT_STATE_IN_FLIGHT)
        if inFlight then
            seen = true
            local dx, dy = p:GetX() - SCOUT_X, p:GetY() - SCOUT_Y
            if dx * dx + dy * dy <= SCOUT_R * SCOUT_R then reached = true end
        end
        if seen and not inFlight then
            p:RemoveEventById(eventId)
            flying[guid] = nil
            if p:HasQuest(Q_BOOSTER) and p:GetQuestStatus(Q_BOOSTER) ~= 1 then
                if reached then
                    p:KilledMonsterCredit(BOOSTER)
                    msg(p, "|cff00ff00You scouted the island from the air. / 你从空中侦察了整座岛。|r")
                else
                    msg(p, "|cffff8800The scouting flight was cut short. Talk to the Booster again. / 侦察飞行被中断了，请再和助推器说话。|r")
                end
            end
        elseif (not seen and ticks >= 5) or ticks >= 150 then
            p:RemoveEventById(eventId)
            flying[guid] = nil
            if not seen then msg(p, "|cffff8800The Booster did not take off, talk to it again. / 助推器没有起飞，请再和它说话。|r") end
        end
    end, 1000, 0)
end

RegisterCreatureGossipEvent(BOOSTER, 1, function(event, player, creature)       -- GOSSIP_EVENT_ON_HELLO
    if player:HasQuest(Q_BOOSTER) then
        if flying[player:GetGUIDLow()] then
            player:GossipComplete()
            return
        end
        creature:SendUnitSay("Scout-o-Matic starting! 侦察机启动！", 0)
        player:GossipComplete()
        if player:IsMounted() then player:Dismount() end
        player:StartTaxi(FLY_PATH)
        watchFlight(player)
    else
        creature:SendUnitSay("Bzzt! Do not touch Lindie's invention. 嗡！别碰琳迪的发明。", 0)
        player:GossipComplete()
    end
end)

-- Wandering Boars: SIZER1A. The Re-Sizer (178051) now has a use-spell (RESIZE_SPELL, any-unit target) so using it shows the targeting cursor.
-- Casting it on a Wandering Boar: lightning visuals on the boar, the boar swells, credit once per boar per player, it shrinks back after a few seconds.
local RESIZE_SPELL = 746                   -- stock Linen Bandage spell: the same one the First Aid Kit uses (user-verified targeting); only the click/target spell, scaling is done below
local ZAP_SPELLS = { 45935, 28136 }        -- cosmetic lightning visuals cast on the boar (harmless dummy spells)
local BIG_SECONDS = 8
local tried = {}      -- [playerGuidLow][boarGuidLow] = true
local boarBase = {}   -- [boarGuidLow] = the boar's own original scale

RegisterPlayerEvent(63, function(event, player, quest)       -- ON_QUEST_ACCEPT
    if player and quest and quest:GetId() == Q_RESIZE then
        tried[player:GetGUIDLow()] = {}
        if player:GetItemCount(RESIZER) < 1 then player:AddItem(RESIZER, 1) end
    end
end)

local function onResizeCast(event, player, spell, skipCheck)     -- PLAYER_EVENT_ON_SPELL_CAST
    if not player or not spell then return end
    if spell:GetEntry() ~= RESIZE_SPELL then return end
    if not player:HasQuest(Q_RESIZE) then return end
    local pl = player:GetGUIDLow()
    tried[pl] = tried[pl] or {}
    local tgt = spell:GetTarget()
    local isBoar = false
    if tgt then
        local ok, e = pcall(function() return tgt:GetEntry() end)
        isBoar = ok and e == BOAR and tgt:GetTypeId() == 3
    end
    -- no boar targeted (or auto self cast): use the nearest boar this player has not tested yet
    if not isBoar then
        local best, bestD = nil, 9999
        for _, c in pairs(player:GetCreaturesInRange(15, BOAR)) do
            if not tried[pl][c:GetGUIDLow()] then
                local d = player:GetDistance(c)
                if d < bestD then best, bestD = c, d end
            end
        end
        if best then tgt = best; isBoar = true end
    end
    player:RegisterEvent(function(_, _, _, p) if p then p:RemoveAura(11196) end end, 800, 1)   -- in case the aura landed on the player
    if not isBoar then
        msg(player, "|cffff8800Use the Re-Sizer on a Wandering Boar. / 请对游荡野猪使用缩放器。|r")
        return
    end
    local bg = tgt:GetGUIDLow()
    if tried[pl][bg] then
        tgt:SendUnitSay("Oink? 哼哼？", 0)
        msg(player, "This boar has already been tested. / 这头野猪已经测试过了。")
        return
    end
    tried[pl][bg] = true
    for _, z in ipairs(ZAP_SPELLS) do pcall(function() tgt:CastSpell(tgt, z, true) end) end
    -- remember this boar's REAL scale before the first change (it is not necessarily BOAR_BASE), swell it by the same factor, restore exactly that value
    if not boarBase[bg] then
        local okS, cur = pcall(function() return tgt:GetScale() end)
        boarBase[bg] = (okS and type(cur) == "number" and cur > 0.05) and cur or BOAR_BASE
        print("[Ally1C] boar " .. bg .. " original scale " .. tostring(boarBase[bg]))
    end
    tgt:SetScale(boarBase[bg] * (BOAR_BIG / BOAR_BASE))
    tgt:SendUnitSay("OINK!! 哼哼！！", 0)
    player:KilledMonsterCredit(BOAR)
    msg(player, "|cff00ff00The Re-Sizer zaps the boar and it swells! / 缩放器电了野猪一下，它变大了！|r")
    -- shrink back: the boar's own timer, plus the player's timer and a late retry as backups (any of them is enough; all are harmless if repeated)
    local function shrink(c, who)
        if not c then print("[Ally1C] shrink " .. who .. ": boar object is nil"); return end
        local ok, err = pcall(function() c:SetScale(boarBase[bg] or BOAR_BASE) end)
        pcall(function() c:RemoveAura(11196) end)
        print("[Ally1C] shrink " .. who .. " boar " .. bg .. " ok=" .. tostring(ok) .. (ok and "" or (" err=" .. tostring(err))))
    end
    tgt:RegisterEvent(function(_, _, _, c) shrink(c or tgt, "boar timer") end, BIG_SECONDS * 1000, 1)
    player:RegisterEvent(function(_, _, _, p) shrink(tgt, "player timer") end, (BIG_SECONDS + 2) * 1000, 1)
    player:RegisterEvent(function(_, _, _, p) shrink(tgt, "late retry") end, (BIG_SECONDS + 12) * 1000, 1)
    print("[Ally1C] Re-Sizer used on boar " .. bg .. " by " .. player:GetName())
end
RegisterPlayerEvent(5, function(...)
    local ok, err = pcall(onResizeCast, ...)
    if not ok then print("[Ally1C] ERROR in Re-Sizer cast handler: " .. tostring(err)) end
end)
end

do
local Q_REDEATH = 55879
local CADAVER, GUNSHIP, TORGOK = 165150, 9167021, 162817
local NEED = 8
local RIDE_AURA = 46598          -- ALLY1C V3: stock "Ride Vehicle" spell used by the boar spellclick, removing it leaves the boar
local LAND_DELAY = 2500          -- ms after the 6th kill

local kills = {}                 -- [playerGuidLow] = number of cadavers killed with the quest active (resets on accept / relog / restart)
local counted = {}               -- [cadaverGuidLow] = true, so the two hooks below never count one corpse twice

local function msg(p, s) p:SendBroadcastMessage(s) end

local function leaveVehicle(p)
    if not p then return end
    local ok, veh = pcall(function() return p:IsOnVehicle() end)
    if not ok or not veh then return end
    pcall(function() p:RemoveAura(RIDE_AURA) end)
    local ok2, still = pcall(function() return p:IsOnVehicle() end)
    if ok2 and still then pcall(function() still:RemovePassenger(p) end) end    -- fallback
end

local function countKill(player, cadaver)
    if not player or not cadaver then return end
    local ok, gl = pcall(function() return cadaver:GetGUIDLow() end)
    if not ok then return end
    if counted[gl] then return end
    counted[gl] = true
    if not player:HasQuest(Q_REDEATH) then return end
    local pl = player:GetGUIDLow()
    kills[pl] = (kills[pl] or 0) + 1
    print("[Ally1C] cadaver kill " .. kills[pl] .. "/" .. NEED .. " by " .. player:GetName())
    if kills[pl] == NEED then
        msg(player, "|cff00ff00The path is clear! Time to dismount. / 路清出来了！该下坐骑了。|r")
        player:RegisterEvent(function(_, _, _, p)
            leaveVehicle(p)
            msg(p, "|cffffffffNow defeat Torgok on foot, then find Wrathion. / 现在步行击败托戈克，然后去找拉希奥。|r")
        end, LAND_DELAY, 1)
    end
end

-- hook 1: the player killed a creature (vehicle kills count for the controlling player in the core)
RegisterPlayerEvent(7, function(event, killer, killed)
    if not killer or not killed then return end
    local ok, e = pcall(function() return killed:GetEntry() end)
    if ok and e == CADAVER then pcall(countKill, killer, killed) end
end)

-- hook 2: the cadaver died; if the killer is the gunship, credit its driver
RegisterCreatureEvent(CADAVER, 4, function(event, creature, killer)
    if not killer then return end
    local ok, e = pcall(function() return killer:GetEntry() end)
    if not ok or e ~= GUNSHIP then return end
    local ok2, p = pcall(function()
        local kit = killer:GetVehicleKit()
        return kit and kit:GetPassenger(0) or nil
    end)
    if ok2 and p then pcall(countKill, p, creature) end
end)

RegisterPlayerEvent(63, function(event, player, quest)       -- ON_QUEST_ACCEPT
    if player and quest and quest:GetId() == Q_REDEATH then kills[player:GetGUIDLow()] = 0 end
end)

-- tidy the dedupe table now and then
CreateLuaEvent(function() counted = {} end, 600000, 0)
end

print("[Ally1C] ALLY1C V3 loaded: quests 55193 / 56034 / 55879 (boar mount)")
