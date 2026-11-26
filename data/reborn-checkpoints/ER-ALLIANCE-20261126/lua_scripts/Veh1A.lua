-- Veh1A.lua (VEH2A V1, 2026-11-25, Claude) - candidate, NOT user-tested.
-- Quest 59942 "The Re-Deather": the player rides the gunship (creature 9167020, VEH1A V1) and bombs Monstrous Cadavers (165150).
-- After the 6th cadaver the gunship lands: the player is taken off the vehicle (retail: the Choppy Booster flies off and the player
-- fights Torgok on foot). Torgok (162817) and Wrathion (167128) need no script, they are quest objective / quest ender in the SQL.
local Q_REDEATH = 59942
local CADAVER, GUNSHIP, TORGOK = 165150, 9167020, 162817
local NEED = 6
local RIDE_AURA = 46598          -- VEH3A: stock "Ride Vehicle" spell used by the boar spellclick, removing it leaves the boar
local LAND_DELAY = 2500          -- ms after the 6th kill

local kills = {}                 -- [playerGuidLow] = number of cadavers killed with quest 59942 active (resets on accept / relog / restart)
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
    print("[Veh1A] cadaver kill " .. kills[pl] .. "/" .. NEED .. " by " .. player:GetName())
    if kills[pl] == NEED then
        msg(player, "|cff00ff00The path is clear! The boar is stopping. / 路清出来了！野猪停下来了。|r")
        player:RegisterEvent(function(_, _, _, p)
            leaveVehicle(p)
            msg(p, "|cffffffffNow find Torgok on foot, then report to Wrathion. / 现在步行去找托戈克，然后向拉希奥复命。|r")
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

print("[Veh1A] VEH3A V1 loaded (boar mount): quest " .. Q_REDEATH .. ", land after " .. NEED .. " cadavers")
