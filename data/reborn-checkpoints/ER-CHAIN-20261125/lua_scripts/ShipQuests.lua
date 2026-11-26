-- ShipQuests.lua  (SHIP2B V1, 2026-11-22, Claude)
-- Exile's Reach Horde ship quest line, parts that SQL alone cannot do:
--   59926 Warming Up       : kill a combat dummy (plain quest kill, nothing here except Thrall's line)
--   59927 Stand Your Ground: spar with Grunt Throg -> he turns hostile, concedes at low health, player gets the credit
--   59928 Brace for Impact : turning it in to Thrall starts the shipwreck sequence (ShipCrash.lua, ShipCrash_Start)
-- Retail did the spar and the wreck with scripts + scenes (zone_exiles_reach.cpp); this is the 3.3.5 re-build.

local THRALL = 166573
local THROG = 166583
local COLE_CREDIT = 155607      -- quest objective credit creature of 59927
local Q_WARM, Q_SPAR, Q_BRACE = 59926, 59927, 59928

local FACTION_FRIENDLY = 35
local FACTION_HOSTILE = 14
local CONCEDE_PCT = 30          -- Throg gives up below this health percent

local sparring = {}             -- [throgGuidLow] = player guid low

local function reset_throg(c)
    c:SetFaction(FACTION_FRIENDLY)
    c:ClearThreatList()
    c:AttackStop()
    c:ClearInCombat()
    c:SetHealth(c:GetMaxHealth())
    sparring[c:GetGUIDLow()] = nil
end

-- accepting 59927 starts the spar
RegisterPlayerEvent(63, function(event, player, quest)    -- PLAYER_EVENT_ON_QUEST_ACCEPT
    if not player or not quest then return end
    local id = quest:GetId()
    if id == Q_SPAR then
        local throg = player:GetNearestCreature(40, THROG)
        if throg and not sparring[throg:GetGUIDLow()] then
            sparring[throg:GetGUIDLow()] = player:GetGUIDLow()
            throg:SendUnitSay("Always face your enemy! 永远要直面你的敌人！", 0)
            throg:SetFaction(FACTION_HOSTILE)
            throg:AttackStart(player)
        end
    elseif id == Q_WARM then
        local thrall = player:GetNearestCreature(40, THRALL)
        if thrall then
            thrall:SendUnitSay("We need to be ready for anything. Show me your skill in combat. 我们必须为任何情况做好准备。让我看看你的战斗技巧。", 0)
        end
    end
end)

-- Throg takes damage: concede at low health instead of dying
RegisterCreatureEvent(THROG, 9, function(event, creature, attacker, damage)   -- CREATURE_EVENT_ON_DAMAGE_TAKEN
    local owner = sparring[creature:GetGUIDLow()]
    if not owner then return end
    local after = creature:GetHealth() - (damage or 0)
    local pct = after * 100 / creature:GetMaxHealth()
    if pct <= CONCEDE_PCT then
        local p = attacker
        if p and p.GetObjectType and p:GetObjectType() ~= "Player" and p.GetOwner then
            p = p:GetOwner()
        end
        sparring[creature:GetGUIDLow()] = nil
        creature:SetFaction(FACTION_FRIENDLY)
        creature:ClearThreatList()
        creature:AttackStop()
        creature:ClearInCombat()
        creature:SendUnitSay("I concede! Your strength will see our mission through. 我认输！你的力量能帮我们完成使命。", 0)
        if p and p.KilledMonsterCredit then
            p:KilledMonsterCredit(COLE_CREDIT)
        end
        creature:RegisterEvent(function(_, _, _, c)
            if c then c:SetHealth(c:GetMaxHealth()) end
        end, 2000, 1)
        return true, 0      -- swallow this hit so Throg does not die
    end
end)

-- if the spar is abandoned (player dead, left, evaded) put Throg back
RegisterCreatureEvent(THROG, 2, function(event, creature)         -- CREATURE_EVENT_ON_LEAVE_COMBAT
    if sparring[creature:GetGUIDLow()] then
        reset_throg(creature)
    else
        creature:SetFaction(FACTION_FRIENDLY)
    end
end)
RegisterCreatureEvent(THROG, 5, function(event, creature)         -- CREATURE_EVENT_ON_SPAWN
    sparring[creature:GetGUIDLow()] = nil
    creature:SetFaction(FACTION_FRIENDLY)
end)

-- turning in 59928 at Thrall starts the shipwreck
RegisterCreatureEvent(THRALL, 34, function(event, player, creature, quest, opt)   -- CREATURE_EVENT_ON_QUEST_REWARD
    if quest and quest:GetId() == Q_BRACE then
        creature:SendUnitSay("Soldiers, brace yourselves! 战士们，准备迎接冲击！", 0)
        if ShipCrash_Start then
            ShipCrash_Start(player)
        else
            player:SendBroadcastMessage("ShipCrash.lua is not loaded. 没有加载 ShipCrash.lua。")
        end
    end
end)

print("[ShipQuests] SHIP2C V1 (bilingual) loaded: quests 59926-59928, Thrall " .. THRALL .. ", Throg " .. THROG)
