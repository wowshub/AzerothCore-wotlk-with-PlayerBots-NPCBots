-- Harpy1C.lua (HARPY1C V4, 2026-11-25, Claude) - candidate, NOT user-tested.
-- Quest 59946 "Purge the Totems": clicking a Harpy Totem (go 9350803) burns it. The core gives the quest credit; this script then
-- summons a plain burning copy of the totem (9350805) with flames (9350804) for BURN_SECONDS and despawns the clicked totem itself
-- (the SQL makes it consumable, Data5 = 1, so Despawn really removes it; it respawns after its spawn time, 60 s), so its quest sparkle goes.
-- Guard: the same totem cannot give credit twice within LOCK_SECONDS (V3 let one totem be clicked again and again for 3/5, 4/5, 5/5).
local TOTEM, FLAMES, COPY = 9350803, 9350804, 9350805
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
        print("[Harpy1C] totem burning at " .. math.floor(x) .. "," .. math.floor(y) .. " copy=" .. tostring(copy ~= nil) .. " flames=" .. tostring(fire ~= nil))
        go:RegisterEvent(function(_, _, _, g)
            local ok2, e2 = pcall(function() g:Despawn() end)
            if not ok2 then print("[Harpy1C] despawn error: " .. tostring(e2)) end
        end, DESPAWN_MS, 1)
        return false
    end)
    if not ok then
        print("[Harpy1C] ERROR: " .. tostring(res))
        return false
    end
    return res      -- true = stop the normal use (repeat click), false = give the credit as usual
end)

print("[Harpy1C] HARPY1C V4 loaded (totem entry " .. TOTEM .. ")")
