-- Ally1D.lua (ALLY1D V1, 2026-11-25, Claude) - candidate, NOT user-tested.
-- Alliance quest 55881 "Purge the Totems": same behaviour as the tested Horde Harpy1C.lua, for the Alliance totem 9350813.
local TOTEM, FLAMES, COPY = 9350813, 9350804, 9350805
local BURN_SECONDS = 58
local LOCK_SECONDS = 60
local DESPAWN_MS = 800

local usedAt = {}      -- [totem spawn guid low] = os.time() of the last accepted click

RegisterGameObjectEvent(TOTEM, 14, function(event, go, player)      -- GAMEOBJECT_EVENT_ON_USE
    local ok, res = pcall(function()
        local gl = go:GetGUIDLow()
        local now = os.time()
        if usedAt[gl] and now - usedAt[gl] < LOCK_SECONDS then
            return true      -- already burned: stop the normal use, so no second credit
        end
        usedAt[gl] = now
        local x, y, z, o = go:GetX(), go:GetY(), go:GetZ(), go:GetO()
        local copy = go:SummonGameObject(COPY, x, y, z, o, BURN_SECONDS)
        local fire = go:SummonGameObject(FLAMES, x, y, z + 0.1, o, BURN_SECONDS)
        if player then player:SendBroadcastMessage("|cffff8800The totem goes up in flames! / 图腾燃烧起来了！|r") end
        print("[Ally1D] totem burning at " .. math.floor(x) .. "," .. math.floor(y) .. " copy=" .. tostring(copy ~= nil) .. " flames=" .. tostring(fire ~= nil))
        go:RegisterEvent(function(_, _, _, g)
            local ok2, e2 = pcall(function() g:Despawn() end)
            if not ok2 then print("[Ally1D] despawn error: " .. tostring(e2)) end
        end, DESPAWN_MS, 1)
        return false
    end)
    if not ok then
        print("[Ally1D] ERROR: " .. tostring(res))
        return false
    end
    return res      -- true = stop the normal use (repeat click), false = give the credit as usual
end)

print("[Ally1D] ALLY1D V1 loaded (totem entry " .. TOTEM .. ")")
