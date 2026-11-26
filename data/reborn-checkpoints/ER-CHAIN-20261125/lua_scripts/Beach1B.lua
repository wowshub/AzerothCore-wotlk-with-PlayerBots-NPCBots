-- Beach1B.lua (BEACH1B V1, 2026-11-23, Claude)
-- Exile's Reach Abandoned Camp:
--   59932 Cooking Meat / 烹饪肉: collect 5 Raw Meat from wildlife (SQL loot), then use the campfire (this script) to cook -> Cooked Meat.
--   59933 Enhanced Combat Tactics / 强化战斗战术: spar with Warlord Breka Grimaxe; she turns hostile, concedes at low health, player gets the credit.
local Q_COOK, Q_SPAR = 59932, 59933
local RAW, COOKED = 174072, 174074
local CAMPFIRE = 9174074
local GRIM = 164577
local FACTION_FRIENDLY, FACTION_HOSTILE = 35, 14
local CONCEDE_PCT = 30

-- ---- campfire (goober): cooking uses the meat the player already carries
RegisterGameObjectEvent(CAMPFIRE, 14, function(event, go, player)       -- GAMEOBJECT_EVENT_ON_USE
    if not player then return true end
    if player:HasQuest(Q_COOK) then
        if player:GetItemCount(COOKED) > 0 then
            player:SendBroadcastMessage("You already have cooked meat. / 你已经有烤熟的肉了。")
        elseif player:GetItemCount(RAW) >= 5 then
            player:AddItem(COOKED, 1)
            player:SendBroadcastMessage("|cff00ff00You cook the meat over the fire. / 你在篝火上把肉烤熟了。|r")
        else
            player:SendBroadcastMessage("You need 5 Raw Meat. / 你需要5份生肉。")
        end
    else
        player:SendBroadcastMessage("A warm campfire. / 一堆温暖的篝火。")
    end
    return true
end)

-- ---- sparring with Grimaxe
local sparring = {}      -- [guidLow] = player guid low

local function reset_grim(c)
    c:SetFaction(FACTION_FRIENDLY)
    c:ClearThreatList()
    c:AttackStop()
    c:ClearInCombat()
    c:SetHealth(c:GetMaxHealth())
    sparring[c:GetGUIDLow()] = nil
end

RegisterPlayerEvent(63, function(event, player, quest)         -- PLAYER_EVENT_ON_QUEST_ACCEPT
    if not player or not quest then return end
    if quest:GetId() == Q_SPAR then
        local grim = player:GetNearestCreature(40, GRIM)
        if grim and not sparring[grim:GetGUIDLow()] then
            sparring[grim:GetGUIDLow()] = player:GetGUIDLow()
            grim:SendUnitSay("Show me what you've learned! 让我看看你学到了什么！", 0)
            grim:SetFaction(FACTION_HOSTILE)
            grim:AttackStart(player)
        end
    end
end)

RegisterCreatureEvent(GRIM, 9, function(event, creature, attacker, damage)   -- ON_DAMAGE_TAKEN
    local owner = sparring[creature:GetGUIDLow()]
    if not owner then return end
    local after = creature:GetHealth() - (damage or 0)
    if after * 100 / creature:GetMaxHealth() <= CONCEDE_PCT then
        local p = attacker
        if p and p.GetObjectType and p:GetObjectType() ~= "Player" and p.GetOwner then
            p = p:GetOwner()
        end
        sparring[creature:GetGUIDLow()] = nil
        creature:SetFaction(FACTION_FRIENDLY)
        creature:ClearThreatList()
        creature:AttackStop()
        creature:ClearInCombat()
        creature:SendUnitSay("Enough! You are ready. 够了！你已经准备好了。", 0)
        if p and p.KilledMonsterCredit then
            p:KilledMonsterCredit(GRIM)
        end
        creature:RegisterEvent(function(_, _, _, c)
            if c then c:SetHealth(c:GetMaxHealth()) end
        end, 2000, 1)
        return true, 0
    end
end)

RegisterCreatureEvent(GRIM, 2, function(event, creature)       -- ON_LEAVE_COMBAT
    if sparring[creature:GetGUIDLow()] then reset_grim(creature) else creature:SetFaction(FACTION_FRIENDLY) end
end)
RegisterCreatureEvent(GRIM, 5, function(event, creature)       -- ON_SPAWN
    sparring[creature:GetGUIDLow()] = nil
    creature:SetFaction(FACTION_FRIENDLY)
end)

print("[Beach1B] BEACH1B V1 loaded: quests " .. Q_COOK .. " / " .. Q_SPAR .. ", campfire " .. CAMPFIRE .. ", Grimaxe " .. GRIM)
