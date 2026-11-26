-- Dark1A.lua (ALLY1F V1 = Dark1A V3, 2026-11-26, Claude) - candidate, NOT user-tested. Replaces the Dark1A.lua file.
-- Darkmaul Citadel outer ring for BOTH factions (Exile's Reach):
--   Horde 59978/59980/59981, Alliance 55981/55989/55990.
--   * ogre disguise (from DARK1B): talking to Herbert (Horde) or Meredy (Alliance) turns the player into an ogre of the ogres' faction until the
--     disguise quest is turned in or abandoned, or the player leaves the island.
--   * Gor'groth's gossip gives the greeting credit; the cooking area and the citadel entrance are area credits checked every 2 s.
--   * catapults and runestones of both factions: the core gives the credit on use; this script despawns the object and refuses a second click.
local DISGUISE_QUESTS = {59978, 55981}          -- Horde, Alliance
local HERBERT, GORGROTH, CHEF = 167598, 153580, 154103
local MEREDY = 156943
local FAKE_ENTRANCE = 9100210
local CATAPULT, RUNE = 9326651, 9339865
local CATAPULT_A, RUNE_A = 9326652, 9339866
local ISLAND = 12175
local LOCK_SECONDS, DESPAWN_MS = 60, 800
-- area credits: {creature entry for KilledMonsterCredit, x, y, radius}
local AREAS = {
    {CHEF, 604.0, -2064.0, 22.0},              -- ogre cooking area (retail polygon around 589,-2061)
    {FAKE_ENTRANCE, 695.0, -1897.0, 16.0},     -- citadel entrance
}

local OGRE_DISPLAY, OGRE_FACTION = 11567, 14
local disguised = {}      -- [player guid low] = original faction template

local function msg(p, s) p:SendBroadcastMessage(s) end

local function wantsDisguise(p)
    for _, id in ipairs(DISGUISE_QUESTS) do
        if p:HasQuest(id) then return true end
    end
    return false
end

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

-- ---------------------------------------------------------------- Herbert / Meredy / Gor'groth gossip
-- the handlers return nothing: "return false" lets the core open its default window on top
local function disguiser(npc, quest)
    RegisterCreatureGossipEvent(npc, 1, function(event, player, creature)
        local ok, err = pcall(function()
            player:GossipComplete()
            if player:HasQuest(quest) then
                player:KilledMonsterCredit(npc)
                if player:IsMounted() then player:Dismount() end
                disguiseOn(player)
                msg(player, "|cff00ff00You are disguised as an ogre. Ogres will not attack you. / 你伪装成了食人魔，食人魔不会攻击你。|r")
                creature:SendUnitSay("Hold still... there! You look like an ogre now. Mostly. 别动……好了！你现在看起来像食人魔了。差不多吧。", 0)
            else
                creature:SendUnitSay("Ogres are not as clever as they look. 食人魔没有看起来那么聪明。", 0)
            end
        end)
        if not ok then print("[Dark1A] disguise gossip ERROR: " .. tostring(err)) end
    end)
end
disguiser(HERBERT, 59978)
disguiser(MEREDY, 55981)

RegisterCreatureGossipEvent(GORGROTH, 1, function(event, player, creature)
    local ok, err = pcall(function()
        player:GossipComplete()
        if wantsDisguise(player) then
            player:KilledMonsterCredit(GORGROTH)
            creature:SendUnitSay("Hrm. Ogre. Good. Go away. 嗯。食人魔。好。走开。", 0)
        end
    end)
    if not ok then print("[Dark1A] Gor'groth gossip ERROR: " .. tostring(err)) end
end)

-- ---------------------------------------------------------------- area credits (59978)
CreateLuaEvent(function()
    local ok, err = pcall(function()
        for _, p in pairs(GetPlayersInWorld()) do
            local gl = p:GetGUIDLow()
            if disguised[gl] then
                if not wantsDisguise(p) or p:GetMapId() ~= ISLAND then
                    disguiseOff(p)                                   -- turned in, abandoned or left the island
                elseif p:GetFaction() ~= OGRE_FACTION then
                    p:SetFaction(OGRE_FACTION)                       -- keep the disguise if something reset it
                end
            end
            if p:GetMapId() == ISLAND and wantsDisguise(p) and p:IsAlive() then
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
useOnce(CATAPULT_A, "|cff00ff00BOOM! The catapult is wrecked. / 轰！投石机被炸毁了。|r")
useOnce(RUNE_A, "|cff00ff00The rune flickers out. / 符文熄灭了。|r")

print("[Dark1A] ALLY1F V1 loaded: both factions, disguise quests 59978/55981")
