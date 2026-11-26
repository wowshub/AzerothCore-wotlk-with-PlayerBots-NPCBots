-- Beach1A.lua (BEACH1A V4 / FIRSTAID1C V1, 2026-11-23, Claude)
-- Quest 59930 "Emergency First Aid / 紧急急救".
-- The three survivors lie on the ground (creature_template_addon bytes1 = 3). The First Aid Kit (168410) now has a use-spell (746, friendly
-- target), so using it shows the targeting cursor; casting it on a survivor stands him up, gives the quest credit, and he lies down again later.
-- The kit is consumed by the core (spellcharges -1). Wrong target / already treated / no quest: the kit is given back.
local Q_AID = 59930
local KIT = 168410
local KIT_SPELL = 746
local STAND_SECONDS = 20
local STATE_STAND, STATE_LIE = 0, 3

local WOUNDED = {
    [166786] = "Thank you. I can breathe again. 谢谢你，我又能呼吸了。",
    [166791] = "That helps a lot. 这帮了大忙。",
    [166796] = "I will be all right now. 我现在没事了。",
}

local healed = {}     -- [playerGuidLow][entry] = true for the current quest attempt (memory only)

RegisterPlayerEvent(63, function(event, player, quest)     -- PLAYER_EVENT_ON_QUEST_ACCEPT
    if player and quest and quest:GetId() == Q_AID then
        healed[player:GetGUIDLow()] = {}
        if player:GetItemCount(KIT) < 3 then
            player:AddItem(KIT, 3 - player:GetItemCount(KIT))
        end
    end
end)

local function lieDownLater(creature)
    creature:RegisterEvent(function(_, _, _, c)
        if c then c:SetStandState(STATE_LIE) end
    end, STAND_SECONDS * 1000, 1)
end

local function onCast(event, player, spell, skipCheck)     -- PLAYER_EVENT_ON_SPELL_CAST
    if not player or not spell then return end
    local sid = spell:GetEntry()
    if sid ~= KIT_SPELL then return end
    local tgt = spell:GetTarget()
    local tentry = "nil"
    if tgt then
        local ok, e = pcall(function() return tgt:GetEntry() end)
        tentry = ok and tostring(e) or "err"
    end
    -- no friendly target selected (or auto self cast): the bandage lands on the player; use the nearest wounded survivor instead
    local selfCast = (not tgt) or (tentry ~= "nil" and tgt:GetGUIDLow() == player:GetGUIDLow() and tgt:GetTypeId() == 4)
    if selfCast then
        local mine0 = healed[player:GetGUIDLow()] or {}
        local best, bestD = nil, 9999
        for e in pairs(WOUNDED) do
            if not mine0[e] then                       -- skip survivors this player has already treated
                local c = player:GetNearestCreature(8, e)
                if c then
                    local d = player:GetDistance(c)
                    if d < bestD then best, bestD, tentry = c, d, tostring(e) end
                end
            end
        end
        if best then tgt = best end
    end
    -- the bandage puts "Recently Bandaged" (11196, 60 s) on its target = the player when self-cast; clear it so the kits can be used back to back
    player:RegisterEvent(function(_, _, _, p)
        if p then p:RemoveAura(11196) end
    end, 800, 1)
    print("[Beach1A] cast spell " .. sid .. " by " .. player:GetName() .. " target entry " .. tentry .. " hasQuest " .. tostring(player:HasQuest(Q_AID)))
    if not player:HasQuest(Q_AID) then return end
    local entry = tonumber(tentry)
    if not tgt or not entry or not WOUNDED[entry] then
        player:SendBroadcastMessage("|cffff8800Use the First Aid Kit on a wounded survivor. / 请对受伤的幸存者使用急救包。|r")
        player:AddItem(KIT, 1)
        return
    end
    local guid = player:GetGUIDLow()
    local mine = healed[guid]
    if not mine then mine = {}; healed[guid] = mine end
    if mine[entry] then
        tgt:SendUnitSay("I am already feeling better. 我已经好多了。", 0)
        player:AddItem(KIT, 1)
        return
    end
    mine[entry] = true
    player:KilledMonsterCredit(entry)
    tgt:SetStandState(STATE_STAND)
    tgt:SendUnitSay(WOUNDED[entry], 0)
    lieDownLater(tgt)
    print("[Beach1A] credit given for " .. entry)
end

RegisterPlayerEvent(5, function(...)
    local ok, err = pcall(onCast, ...)
    if not ok then print("[Beach1A] ERROR in cast handler: " .. tostring(err)) end
end)

-- talking to a survivor only gives a hint now
local function OnHello(event, player, creature)
    if not player or not creature then return false end
    if player:HasQuest(Q_AID) then
        creature:SendUnitSay("Use a First Aid Kit on me. 请对我使用急救包。", 0)
    else
        creature:SendUnitSay("I am hurt, but I will live. 我受伤了，但死不了。", 0)
    end
    player:GossipComplete()
    return false
end

for entry in pairs(WOUNDED) do
    RegisterCreatureGossipEvent(entry, 1, OnHello)   -- GOSSIP_EVENT_ON_HELLO
end

print("[Beach1A] BEACH1A V4 FIRSTAID1C loaded: First Aid Kit is cast on survivors (spell " .. KIT_SPELL .. ")")
