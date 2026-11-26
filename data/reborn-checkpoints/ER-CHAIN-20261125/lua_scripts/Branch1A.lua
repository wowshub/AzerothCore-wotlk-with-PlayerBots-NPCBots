-- Branch1A.lua (BRANCH1A V1, 2026-11-25, Claude) - candidate, NOT user-tested. New file.
-- Two optional Exile's Reach side quests (retail ids kept):
--   * 54933 Freeing the Light: four Ritual Pedestals (go 9326716..9326719, clones of the verified totem row 9350803). The core gives the quest
--     credit; this script despawns the used pedestal and refuses a second click on the same one within 60 s (pattern of HARPY1C V4).
--   * 56839 Killclaw the Terrible: Killclaw (153266) fights with stock abilities (retail: Claw, Severing Swipe bleed, Trampling Charge stun):
--     Rend 13443 every 9 s, Charge 22911 + a 3 s stun every 17 s. Hidden Treasure Chest (go 9326800) is the turn-in, it despawns after use.
local PED_FIRST, PED_LAST = 9326716, 9326719
local LOCK_SECONDS, DESPAWN_MS = 60, 800
local KILLCLAW = 153266
local SPELL_REND, SPELL_CHARGE, SPELL_STUN = 13443, 22911, 5211

local function msg(p, s) p:SendBroadcastMessage(s) end

-- ---------------------------------------------------------------- pedestals
local usedAt = {}
local function useOnce(entry, text)
    RegisterGameObjectEvent(entry, 14, function(event, go, player)       -- GAMEOBJECT_EVENT_ON_USE
        local ok, res = pcall(function()
            local gl = go:GetGUIDLow()
            local now = os.time()
            if usedAt[gl] and now - usedAt[gl] < LOCK_SECONDS then return true end
            usedAt[gl] = now
            if player then msg(player, text) end
            print("[Branch1A] object " .. entry .. " used at " .. math.floor(go:GetX()) .. "," .. math.floor(go:GetY()))
            go:RegisterEvent(function(_, _, _, g)
                local ok2, e2 = pcall(function() g:Despawn() end)
                if not ok2 then print("[Branch1A] despawn error: " .. tostring(e2)) end
            end, DESPAWN_MS, 1)
            return false
        end)
        if not ok then print("[Branch1A] object " .. entry .. " ERROR: " .. tostring(res)); return false end
        return res
    end)
end
for e = PED_FIRST, PED_LAST do
    useOnce(e, "|cff00ff00The shadow energy is dispersed by the light. / 暗影能量被光明驱散了。|r")
end

-- ---------------------------------------------------------------- Killclaw
local function stopEvents(c) c:RemoveEvents() end
RegisterCreatureEvent(KILLCLAW, 5, function(event, creature) stopEvents(creature) end)              -- ON_SPAWN
RegisterCreatureEvent(KILLCLAW, 2, function(event, creature) stopEvents(creature) end)              -- ON_LEAVE_COMBAT
RegisterCreatureEvent(KILLCLAW, 4, function(event, creature, killer) stopEvents(creature) end)      -- ON_DIED
RegisterCreatureEvent(KILLCLAW, 1, function(event, creature, target)                                 -- ON_ENTER_COMBAT
    creature:RemoveEvents()
    creature:RegisterEvent(function(_, _, _, c)                      -- Severing Swipe (bleed)
        local v = c:GetVictim()
        if v then c:CastSpell(v, SPELL_REND, false) end
    end, 9000, 0)
    creature:RegisterEvent(function(_, _, _, c)                      -- Trampling Charge (charge + short stun)
        local v = c:GetVictim()
        if v then
            c:CastSpell(v, SPELL_CHARGE, true)
            c:CastSpell(v, SPELL_STUN, true)
        end
    end, 17000, 0)
end)

-- ---------------------------------------------------------------- treasure chest
RegisterGameObjectEvent(9326800, 14, function(event, go, player)
    local ok = pcall(function()
        if player then msg(player, "|cff00ff00You find a cache of treasure, just like the ogres' sign said! / 你找到了一堆宝藏，正如食人魔的牌子所说！|r") end
    end)
    return false
end)

print("[Branch1A] BRANCH1A V1 loaded: quests 54933 (pedestals " .. PED_FIRST .. "-" .. PED_LAST .. "), 56839 (Killclaw " .. KILLCLAW .. ")")
