-- ShipRespawn.lua (SHIP2E V1, 2026-11-23, Claude)
-- On the Exile's Reach ships a dead player is brought back to life on the deck at once (no ghost run, no spirit healer), and a player
-- who falls below the deck (the ship map has no ground data) is put back on the deck before the fall can kill them.
-- Add the Alliance ship (map 12261) to POINTS when its deck point is known.
local TICK_MS = 1000
local FALL_Z = -5           -- anything below this on a ship map is "fell off the ship"

local POINTS = {
    -- [map] = { x, y, z, orientation }  : a safe spot on the deck, next to Thrall / the dummies
    [12369] = { x = -1070.0, y = -1058.0, z = 9.6, o = 1.5 },
}

local function msg(p, s) p:SendBroadcastMessage(s) end

CreateLuaEvent(function()
    for _, player in pairs(GetPlayersInWorld()) do
        if player:IsInWorld() then
            local pt = POINTS[player:GetMapId()]
            if pt then
                if not player:IsAlive() then
                    player:ResurrectPlayer(100, false)       -- full health, no resurrection sickness
                    player:Teleport(player:GetMapId(), pt.x, pt.y, pt.z, pt.o)
                    msg(player, "|cff00ff00You come back to life on the ship. 你在船上复活了。|r")
                elseif player:GetZ() < FALL_Z then
                    player:Teleport(player:GetMapId(), pt.x, pt.y, pt.z, pt.o)
                    msg(player, "|cffffff00You were pulled back onto the deck. 你被拉回了甲板。|r")
                end
            end
        end
    end
end, TICK_MS, 0)

print("[ShipRespawn] SHIP2E V1 loaded: revive on deck for map 12369")
