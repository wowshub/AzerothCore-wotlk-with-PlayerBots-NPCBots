-- Dark1A.lua (DARK1A V1, 2026-11-25, Claude) - candidate, NOT user-tested. New file.
-- Darkmaul Citadel quests 59975/59978/59979/59980/59981 (Exile's Reach, Horde):
--   * 59978: Herbert's gossip gives the "ogre transformation" credit (no disguise in this port), Gor'groth's gossip gives the greeting credit
--     (retail: /wave), the cooking area and the citadel entrance are area credits checked every 2 s.
--   * 59980 catapults (go 9326651) and 59981 runestones (go 9339865): the core gives the credit on use; the object is consumable, this script
--     despawns it and refuses a second click on the same object within 60 s (same pattern as the Harpy Totem, HARPY1C V4).
local Q_DISGUISE = 59978
local HERBERT, GORGROTH, CHEF = 167598, 153580, 154103
local FAKE_ENTRANCE = 9100210
local CATAPULT, RUNE = 9326651, 9339865
local LOCK_SECONDS, DESPAWN_MS = 60, 800
-- area credits: {creature entry for KilledMonsterCredit, x, y, radius}
local AREAS = {
    {CHEF, 604.0, -2064.0, 22.0},              -- ogre cooking area (retail polygon around 589,-2061)
    {FAKE_ENTRANCE, 695.0, -1897.0, 16.0},     -- citadel entrance
}

local function msg(p, s) p:SendBroadcastMessage(s) end

-- ---------------------------------------------------------------- Herbert / Gor'groth gossip credits
RegisterCreatureGossipEvent(HERBERT, 1, function(event, player, creature)
    local ok = pcall(function()
        if player:HasQuest(Q_DISGUISE) then
            player:KilledMonsterCredit(HERBERT)
            creature:SendUnitSay("Hold still... there! You look like an ogre now. Mostly. 别动……好了！你现在看起来像食人魔了。差不多吧。", 0)
        else
            creature:SendUnitSay("Ogres are not as clever as they look. 食人魔没有看起来那么聪明。", 0)
        end
        player:GossipComplete()
    end)
    if not ok then print("[Dark1A] Herbert gossip ERROR") end
    return false
end)

RegisterCreatureGossipEvent(GORGROTH, 1, function(event, player, creature)
    local ok = pcall(function()
        if player:HasQuest(Q_DISGUISE) then
            player:KilledMonsterCredit(GORGROTH)
            creature:SendUnitSay("Hrm. Ogre. Good. Go away. 嗯。食人魔。好。走开。", 0)
        end
        player:GossipComplete()
    end)
    if not ok then print("[Dark1A] Gor'groth gossip ERROR") end
    return false
end)

-- ---------------------------------------------------------------- area credits (59978)
CreateLuaEvent(function()
    local ok, err = pcall(function()
        for _, p in pairs(GetPlayersInWorld()) do
            if p:GetMapId() == 12175 and p:HasQuest(Q_DISGUISE) and p:IsAlive() then
                local x, y = p:GetX(), p:GetY()
                for _, a in ipairs(AREAS) do
                    local dx, dy = x - a[2], y - a[3]
                    if dx * dx + dy * dy <= a[4] * a[4] then p:KilledMonsterCredit(a[1]) end
                end
            end
        end
    end)
    if not ok then print("[Dark1A] area check ERROR: " .. tostring(err)) end
end, 2000, 0)

-- ---------------------------------------------------------------- click objects
local usedAt = {}
local function useOnce(entry, text)
    RegisterGameObjectEvent(entry, 14, function(event, go, player)       -- GAMEOBJECT_EVENT_ON_USE
        local ok, res = pcall(function()
            local gl = go:GetGUIDLow()
            local now = os.time()
            if usedAt[gl] and now - usedAt[gl] < LOCK_SECONDS then return true end
            usedAt[gl] = now
            if player then msg(player, text) end
            print("[Dark1A] object " .. entry .. " used at " .. math.floor(go:GetX()) .. "," .. math.floor(go:GetY()))
            go:RegisterEvent(function(_, _, _, g)
                local ok2, e2 = pcall(function() g:Despawn() end)
                if not ok2 then print("[Dark1A] despawn error: " .. tostring(e2)) end
            end, DESPAWN_MS, 1)
            return false
        end)
        if not ok then print("[Dark1A] object " .. entry .. " ERROR: " .. tostring(res)); return false end
        return res
    end)
end
useOnce(CATAPULT, "|cff00ff00BOOM! The catapult is wrecked. / 轰！投石机被炸毁了。|r")
useOnce(RUNE, "|cff00ff00The rune flickers out. / 符文熄灭了。|r")

print("[Dark1A] DARK1A V1 loaded: quests 59975/59978-59981, catapult " .. CATAPULT .. ", rune " .. RUNE)
