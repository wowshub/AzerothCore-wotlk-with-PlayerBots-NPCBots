-- Dark1A.lua (DARK1B V1 = Dark1A V2, 2026-11-25, Claude) - candidate, NOT user-tested. Replaces the DARK1A V1 file of the same name.
-- Darkmaul Citadel quests 59975/59978/59979/59980/59981 (Exile's Reach, Horde):
--   * V2 change: Herbert really disguises you (retail: Herbert casts spell 298241 on the player). Here: the player's model becomes an ogre
--     and the player's faction becomes the ogres' faction (14), so the ogres are friendly to you. The disguise lasts while quest 59978 is in the
--     log and ends when it is turned in or abandoned (checked every 2 s), so 59979 (kill ogres) works normally afterwards.
--   * 59978: Herbert's gossip gives the "ogre transformation" credit, Gor'groth's gossip gives the greeting credit
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

local OGRE_DISPLAY, OGRE_FACTION = 11567, 14
local disguised = {}      -- [player guid low] = original faction template

local function msg(p, s) p:SendBroadcastMessage(s) end

local function disguiseOn(p)
    local gl = p:GetGUIDLow()
    if not disguised[gl] then disguised[gl] = p:GetFaction() end
    p:SetDisplayId(OGRE_DISPLAY)
    p:SetFaction(OGRE_FACTION)
end

local function disguiseOff(p)
    local gl = p:GetGUIDLow()
    local orig = disguised[gl]
    disguised[gl] = nil
    p:DeMorph()
    if orig and orig ~= OGRE_FACTION then p:SetFaction(orig) end
    msg(p, "|cffffff00The ogre disguise wears off. / 食人魔伪装消失了。|r")
end

-- a fresh login never keeps a disguise (the core resets model and faction), so forget any stale entry
RegisterPlayerEvent(3, function(event, player)
    disguised[player:GetGUIDLow()] = nil
end)

-- ---------------------------------------------------------------- Herbert / Gor'groth gossip credits
RegisterCreatureGossipEvent(HERBERT, 1, function(event, player, creature)
    local ok = pcall(function()
        if player:HasQuest(Q_DISGUISE) then
            player:KilledMonsterCredit(HERBERT)
            if player:IsMounted() then player:Dismount() end
            disguiseOn(player)
            msg(player, "|cff00ff00You are disguised as an ogre. Ogres will not attack you. / 你伪装成了食人魔，食人魔不会攻击你。|r")
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
            local gl = p:GetGUIDLow()
            if disguised[gl] then
                if not p:HasQuest(Q_DISGUISE) then
                    disguiseOff(p)                                   -- turned in or abandoned
                elseif p:GetFaction() ~= OGRE_FACTION then
                    p:SetFaction(OGRE_FACTION)                       -- keep the disguise if something reset it
                end
            end
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

print("[Dark1A] DARK1B V1 loaded: quests 59975/59978-59981, catapult " .. CATAPULT .. ", rune " .. RUNE)
