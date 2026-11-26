-- Ally1B.lua (ALLY1B V1, 2026-11-25, Claude) - candidate, NOT user-tested. New file; the Horde scripts are not changed.
-- Exile's Reach island, Alliance side:
--   * phases: both factions stand on the same retail coordinates, so Alliance players are put into phase 2 on the island (map 12175).
--     SQL: Horde friendly NPCs stay in phase 1, Alliance NPCs are in phase 2, monsters and objects are in both (3).
--   * 54951 Emergency First Aid : the First Aid Kit (168410, use spell 746) on the three wounded
--   * 55174 Cooking Meat        : the Alliance campfire 9174075
--   * 59254 Enhanced Combat Tactics : spar with Captain Garrick (own entry 9164577, the quest counts creature 164577)
local ISLAND, ALLIANCE_PHASE = 12175, 2
local Q_AID, Q_COOK, Q_SPAR = 54951, 55174, 59254
local KIT, KIT_SPELL = 168410, 746
local RAW, COOKED = 174072, 174074
local CAMPFIRE = 9174075
local GARRICK, SPAR_CREDIT = 9164577, 164577
local FRIENDLY, HOSTILE, CONCEDE_PCT = 35, 14, 30
local STAND_SECONDS = 20
local INCOMPLETE = 3

local WOUNDED = {
    [156609] = "Thank you. I can breathe again. 谢谢你，我又能呼吸了。",
    [156612] = "That helps a lot. 这帮了大忙。",
    [156610] = "I will be all right now. 我现在没事了。",
}

local function msg(p, s) if p and p:IsInWorld() then p:SendBroadcastMessage(s) end end
local sparring = {}           -- [Garrick guid low] = player guid low

-- ---------------------------------------------------------------- phases
local function applyPhase(p)
    if not p or not p:IsInWorld() or p:GetTeam() ~= 0 or p:IsGM() then return end
    local now = p:GetPhaseMask()
    if p:GetMapId() == ISLAND then
        if now ~= ALLIANCE_PHASE then p:SetPhaseMask(ALLIANCE_PHASE, true) end
    elseif now == ALLIANCE_PHASE then
        p:SetPhaseMask(1, true)
    end
end

CreateLuaEvent(function()
    local ok, err = pcall(function()
        for _, p in pairs(GetPlayersInWorld()) do applyPhase(p) end
    end)
    if not ok then print("[Ally1B] phase ERROR: " .. tostring(err)) end
end, 1000, 0)

RegisterPlayerEvent(28, function(event, player)                                 -- ON_MAP_CHANGE
    local ok, err = pcall(applyPhase, player)
    if not ok then print("[Ally1B] map change ERROR: " .. tostring(err)) end
end)

-- ---------------------------------------------------------------- first aid
local healed = {}             -- [player guid low][entry] = true for the current quest attempt

RegisterPlayerEvent(63, function(event, player, quest)                          -- ON_QUEST_ACCEPT
    local ok, err = pcall(function()
        if not player or not quest then return end
        local id = quest:GetId()
        if id == Q_AID then
            healed[player:GetGUIDLow()] = {}
            if player:GetItemCount(KIT) < 3 then player:AddItem(KIT, 3 - player:GetItemCount(KIT)) end
        elseif id == Q_SPAR then
            local g = player:GetNearestCreature(40, GARRICK)
            if g and not sparring[g:GetGUIDLow()] then
                g:SendUnitSay("Show me what you've learned! 让我看看你学到了什么！", 0)
                sparring[g:GetGUIDLow()] = player:GetGUIDLow()
                g:SetFaction(HOSTILE)
                g:AttackStart(player)
            end
        end
    end)
    if not ok then print("[Ally1B] accept ERROR: " .. tostring(err)) end
end)

local function lieDownLater(creature)
    creature:RegisterEvent(function(_, _, _, c) if c then c:SetStandState(3) end end, STAND_SECONDS * 1000, 1)
end

RegisterPlayerEvent(5, function(event, player, spell)                           -- ON_SPELL_CAST
    local ok, err = pcall(function()
        if not player or not spell or spell:GetEntry() ~= KIT_SPELL or not player:HasQuest(Q_AID) then return end
        local guid = player:GetGUIDLow()
        local mine = healed[guid]
        if not mine then mine = {}; healed[guid] = mine end
        local tgt = spell:GetTarget()
        local entry = tgt and tgt:GetEntry() or nil
        -- no friendly target (the bandage lands on the player): use the nearest wounded one not treated yet
        if not tgt or tgt:GetGUIDLow() == guid and tgt:GetTypeId() == 4 then
            local best, bestD = nil, 9999
            for e in pairs(WOUNDED) do
                if not mine[e] then
                    local c = player:GetNearestCreature(8, e)
                    if c and player:GetDistance(c) < bestD then best, bestD, entry = c, player:GetDistance(c), e end
                end
            end
            tgt = best
        end
        player:RegisterEvent(function(_, _, _, p) if p then p:RemoveAura(11196) end end, 800, 1)   -- Recently Bandaged
        if not tgt or not entry or not WOUNDED[entry] then
            msg(player, "|cffff8800Use the First Aid Kit on a wounded survivor. / 请对受伤的幸存者使用急救包。|r")
            player:AddItem(KIT, 1)
            return
        end
        if mine[entry] then
            tgt:SendUnitSay("I am already feeling better. 我已经好多了。", 0)
            player:AddItem(KIT, 1)
            return
        end
        mine[entry] = true
        player:KilledMonsterCredit(entry)
        tgt:SetStandState(0)
        tgt:SendUnitSay(WOUNDED[entry], 0)
        lieDownLater(tgt)
    end)
    if not ok then print("[Ally1B] first aid ERROR: " .. tostring(err)) end
end)

for entry in pairs(WOUNDED) do
    RegisterCreatureGossipEvent(entry, 1, function(event, player, creature)     -- ON_HELLO
        local ok = pcall(function()
            if player:HasQuest(Q_AID) then
                creature:SendUnitSay("Use a First Aid Kit on me. 请对我使用急救包。", 0)
            else
                creature:SendUnitSay("I am hurt, but I will live. 我受伤了，但死不了。", 0)
            end
            player:GossipComplete()
        end)
        if not ok then player:GossipComplete() end
    end)
end

-- ---------------------------------------------------------------- campfire
RegisterGameObjectEvent(CAMPFIRE, 14, function(event, go, player)               -- ON_USE
    if not player then return true end
    local ok, err = pcall(function()
        if not player:HasQuest(Q_COOK) then
            msg(player, "A warm campfire. / 一堆温暖的篝火。")
        elseif player:GetItemCount(COOKED) > 0 then
            msg(player, "You already have cooked meat. / 你已经有烤熟的肉了。")
        elseif player:GetItemCount(RAW) >= 5 then
            player:AddItem(COOKED, 1)
            msg(player, "|cff00ff00You cook the meat over the fire. / 你在篝火上把肉烤熟了。|r")
        else
            msg(player, "You need 5 Raw Meat. / 你需要5份生肉。")
        end
    end)
    if not ok then print("[Ally1B] campfire ERROR: " .. tostring(err)) end
    return true
end)

-- ---------------------------------------------------------------- spar with Captain Garrick
local function calm(c)
    sparring[c:GetGUIDLow()] = nil
    c:SetFaction(FRIENDLY)
    c:ClearThreatList()
    c:AttackStop()
    c:ClearInCombat()
end

RegisterCreatureEvent(GARRICK, 9, function(event, creature, attacker, damage)   -- ON_DAMAGE_TAKEN
    if not sparring[creature:GetGUIDLow()] then return end
    local after = creature:GetHealth() - (damage or 0)
    if after * 100 / creature:GetMaxHealth() > CONCEDE_PCT then return end
    local p = attacker
    if p and p.GetObjectType and p:GetObjectType() ~= "Player" and p.GetOwner then p = p:GetOwner() end
    calm(creature)
    creature:SendUnitSay("Enough! You are ready. 够了！你已经准备好了。", 0)
    local ok, err = pcall(function()
        if p and p.KilledMonsterCredit then
            p:KilledMonsterCredit(SPAR_CREDIT)
            if p:GetQuestStatus(Q_SPAR) == INCOMPLETE then                      -- no normal credit (raid group)
                p:CompleteQuest(Q_SPAR)
                msg(p, "|cff00ff00Quest objective completed. 任务目标已完成。|r")
                print("[Ally1B] spar quest completed by the script for " .. p:GetName())
            end
        end
    end)
    if not ok then print("[Ally1B] spar ERROR: " .. tostring(err)) end
    creature:RegisterEvent(function(_, _, _, c) if c then c:SetHealth(c:GetMaxHealth()) end end, 2000, 1)
    return true, 0
end)

RegisterCreatureEvent(GARRICK, 2, function(event, creature)                     -- ON_LEAVE_COMBAT
    calm(creature)
    creature:SetHealth(creature:GetMaxHealth())
end)
RegisterCreatureEvent(GARRICK, 5, function(event, creature)                     -- ON_SPAWN
    sparring[creature:GetGUIDLow()] = nil
    creature:SetFaction(FRIENDLY)
end)

print("[Ally1B] ALLY1B V1 loaded: Alliance phase on map " .. ISLAND .. ", quests " .. Q_AID .. "/" .. Q_COOK .. "/" .. Q_SPAR)
