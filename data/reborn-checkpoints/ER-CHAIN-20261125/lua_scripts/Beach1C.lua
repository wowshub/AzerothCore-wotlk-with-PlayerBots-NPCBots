-- Beach1C.lua (BEACH1C V3 / BOOST2B V1 / SIZER1A V1, 2026-11-24, Claude)
-- Exile's Reach Horde main spine. The parts retail did with vehicles / item-use are simplified here:
--   59940 Choppy Booster Mk. 5 : talk to the Booster to "scout" -> credit.
--   59941 Re-sizing the Situation: USE the Re-Sizer on 3 DIFFERENT Wandering Boars -> credit each (lightning, the boar swells for a few seconds).
--   59950 Stocking Up on Supplies: talk to Provisioner Jin'hake -> credit, the shop opens as usual.
local Q_BOOSTER, Q_RESIZE, Q_SUPPLY = 59940, 59941, 59950
local BOOSTER, BOAR, JINHAKE = 167027, 156722, 9167001
local RESIZER = 9178051
local BOAR_BASE, BOAR_BIG = 1.4, 3.4      -- must match the DisplayScale of creature 156722 in the SQL (1.4); big = what the Re-Sizer does for a few seconds

local function msg(p, s) p:SendBroadcastMessage(s) end

-- Choppy Booster: BOOST1A. Talking to the Booster with quest 59940 starts a passenger flight (gnome copter): take off, fly over the cadaver
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
            return false
        end
        creature:SendUnitSay("Hold on tight! Scouting run! 抓紧了！侦察飞行开始！", 0)
        player:GossipComplete()
        if player:IsMounted() then player:Dismount() end
        player:StartTaxi(FLY_PATH)
        watchFlight(player)
    else
        creature:SendUnitSay("Bzzt! Do not touch the goblin's gadget. 嗡！别碰地精的玩意儿。", 0)
        player:GossipComplete()
    end
    return false
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
        print("[Beach1C] boar " .. bg .. " original scale " .. tostring(boarBase[bg]))
    end
    tgt:SetScale(boarBase[bg] * (BOAR_BIG / BOAR_BASE))
    tgt:SendUnitSay("OINK!! 哼哼！！", 0)
    player:KilledMonsterCredit(BOAR)
    msg(player, "|cff00ff00The Re-Sizer zaps the boar and it swells! / 缩放器电了野猪一下，它变大了！|r")
    -- shrink back: the boar's own timer, plus the player's timer and a late retry as backups (any of them is enough; all are harmless if repeated)
    local function shrink(c, who)
        if not c then print("[Beach1C] shrink " .. who .. ": boar object is nil"); return end
        local ok, err = pcall(function() c:SetScale(boarBase[bg] or BOAR_BASE) end)
        pcall(function() c:RemoveAura(11196) end)
        print("[Beach1C] shrink " .. who .. " boar " .. bg .. " ok=" .. tostring(ok) .. (ok and "" or (" err=" .. tostring(err))))
    end
    tgt:RegisterEvent(function(_, _, _, c) shrink(c or tgt, "boar timer") end, BIG_SECONDS * 1000, 1)
    player:RegisterEvent(function(_, _, _, p) shrink(tgt, "player timer") end, (BIG_SECONDS + 2) * 1000, 1)
    player:RegisterEvent(function(_, _, _, p) shrink(tgt, "late retry") end, (BIG_SECONDS + 12) * 1000, 1)
    print("[Beach1C] Re-Sizer used on boar " .. bg .. " by " .. player:GetName())
end
RegisterPlayerEvent(5, function(...)
    local ok, err = pcall(onResizeCast, ...)
    if not ok then print("[Beach1C] ERROR in Re-Sizer cast handler: " .. tostring(err)) end
end)

-- talking to a boar only gives a hint now (credit comes from using the Re-Sizer)
RegisterCreatureGossipEvent(BOAR, 1, function(event, player, creature)
    if player:HasQuest(Q_RESIZE) then
        creature:SendUnitSay("Oink? Use the Re-Sizer on me! 哼哼？对我使用缩放器！", 0)
    else
        creature:SendUnitSay("Oink. 哼。", 0)
    end
    player:GossipComplete()
    return false
end)

-- Provisioner Jin'hake
RegisterCreatureGossipEvent(JINHAKE, 1, function(event, player, creature)
    if player:HasQuest(Q_SUPPLY) then
        player:KilledMonsterCredit(JINHAKE)
        creature:SendUnitSay("Take a look, friend. Everything is cheap today. 看看吧，朋友。今天什么都便宜。", 0)
    end
    player:SendListInventory(creature)
    return false
end)

print("[Beach1C] BEACH1C V3 / SIZER1B V2 loaded: quests " .. Q_BOOSTER .. " / " .. Q_RESIZE .. " / " .. Q_SUPPLY)
