-- Ally1A.lua (ALLY1A V3, 2026-11-25, Claude) - V3 movie change is a candidate. New file; the Horde ship scripts are not changed.
-- V2: user report "the dummy dies but the quest does not count". If the core gives no credit for the dummy or the spar, the script completes
--     the quest itself, and says whether the player is in a raid group (the core gives no normal quest credit in a raid, Quests.IgnoreRaid=0).
-- Exile's Reach Alliance ship (map 12261), the parts SQL alone cannot do (same method as the accepted Horde ship):
--   58209 Stand Your Ground : spar with Private Cole -> he turns hostile, concedes at low health, the player gets the credit
--   58208 Brace for Impact  : turning it in to Jaina starts storm -> movie -> teleport to the beach -> knocked down -> up
--   death or falling off the deck puts the player back on the ship (the ship map has no ground data)
local JAINA, COLE, CREDIT = 156280, 160664, 155607
local Q_WARM, Q_SPAR, Q_BRACE = 56775, 58209, 58208
local FRIENDLY, HOSTILE, CONCEDE_PCT = 35, 14, 30

local CFG = {
    shipMap = 12261,
    shipZone = 50531,
    moviePath = "Interface" .. string.char(92) .. "Cinematics" .. string.char(92) .. "ExilesReachAllianceCrash",
    movieSeconds = 23,
    stormDelayToMovie = 7,
    beach = { map = 12175, x = -432.0, y = -2608.0, z = 1.5, o = 4.0 },
    knockedDownSeconds = 6,
    deck = { x = -1067.39, y = -1067.02, z = 13.45, o = 0.9 },
    fallBelow = 3.0,          -- the ship sits at z 7.84 and its deck is about 13: lower than this means "fell off"
}

local function msg(p, s) if p and p:IsInWorld() then p:SendBroadcastMessage(s) end end

-- ---------------------------------------------------------------- quest completion when the core gives no credit
local DUMMY = 160737
local INCOMPLETE = 3

local function groupKind(p)
    local ok, kind = pcall(function()
        local g = p:GetGroup()
        if not g then return "solo" end
        if g:IsRaidGroup() then return "raid" end
        return "party"
    end)
    return ok and kind or "unknown"
end

local function finish(p, quest, how)
    if not p or not p:IsInWorld() or p:GetMapId() ~= CFG.shipMap then return end
    if p:GetQuestStatus(quest) ~= INCOMPLETE then return end
    local kind = groupKind(p)
    p:CompleteQuest(quest)
    msg(p, "|cff00ff00Quest objective completed. 任务目标已完成。|r")
    if kind == "raid" then
        msg(p, "|cffffff00You are in a raid group: the server gives no normal quest credit in raids. 你在团队中：团队里服务器不给普通任务进度。|r")
    end
    print("[Ally1A] quest " .. quest .. " completed by the script (" .. how .. ", group=" .. kind .. ", player=" .. p:GetName() .. ")")
end

-- ---------------------------------------------------------------- the spar
local sparring = {}           -- [cole guid low] = player guid low

local function calm(c)
    sparring[c:GetGUIDLow()] = nil
    c:SetFaction(FRIENDLY)
    c:ClearThreatList()
    c:AttackStop()
    c:ClearInCombat()
end

RegisterPlayerEvent(63, function(event, player, quest)                    -- ON_QUEST_ACCEPT
    local ok, err = pcall(function()
        if not player or not quest or player:GetMapId() ~= CFG.shipMap then return end
        local id = quest:GetId()
        if id == Q_SPAR then
            local cole = player:GetNearestCreature(40, COLE)
            if cole and not sparring[cole:GetGUIDLow()] then
                sparring[cole:GetGUIDLow()] = player:GetGUIDLow()
                cole:SendUnitSay("Always face your enemy! 永远要直面你的敌人！", 0)
                cole:SetFaction(HOSTILE)
                cole:AttackStart(player)
            end
        elseif id == Q_WARM then
            local jaina = player:GetNearestCreature(40, JAINA)
            if jaina then
                jaina:SendUnitSay("We need to be ready for anything. Show me your skill in combat. 我们必须为任何情况做好准备。让我看看你的战斗技巧。", 0)
            end
        end
    end)
    if not ok then print("[Ally1A] accept ERROR: " .. tostring(err)) end
end)

RegisterCreatureEvent(COLE, 9, function(event, creature, attacker, damage)      -- ON_DAMAGE_TAKEN
    if not sparring[creature:GetGUIDLow()] then return end
    local after = creature:GetHealth() - (damage or 0)
    if after * 100 / creature:GetMaxHealth() > CONCEDE_PCT then return end
    local p = attacker
    if p and p.GetObjectType and p:GetObjectType() ~= "Player" and p.GetOwner then p = p:GetOwner() end
    calm(creature)
    creature:SendUnitSay("I yield! You'll do fine out there. 我认输！到了岛上你没问题的。", 0)
    if p and p.KilledMonsterCredit then
        p:KilledMonsterCredit(CREDIT)
        local ok, err = pcall(finish, p, Q_SPAR, "spar")
        if not ok then print("[Ally1A] spar finish ERROR: " .. tostring(err)) end
    end
    creature:RegisterEvent(function(_, _, _, c) if c then c:SetHealth(c:GetMaxHealth()) end end, 2000, 1)
    return true, 0                                                              -- swallow this hit so Cole does not die
end)

RegisterCreatureEvent(COLE, 2, function(event, creature)                        -- ON_LEAVE_COMBAT
    if sparring[creature:GetGUIDLow()] then
        calm(creature)
        creature:SetHealth(creature:GetMaxHealth())
    else
        creature:SetFaction(FRIENDLY)
    end
end)
RegisterCreatureEvent(COLE, 5, function(event, creature)                        -- ON_SPAWN
    sparring[creature:GetGUIDLow()] = nil
    creature:SetFaction(FRIENDLY)
end)

-- the dummy: the kill by the player or the player's pet
local function onKill(event, killer, killed)
    local ok, err = pcall(function()
        if killed and killed:GetEntry() == DUMMY then finish(killer, Q_WARM, "kill") end
    end)
    if not ok then print("[Ally1A] kill ERROR: " .. tostring(err)) end
end
RegisterPlayerEvent(7, onKill)                                                    -- ON_KILL_CREATURE

-- ---------------------------------------------------------------- the wreck
local state = {}              -- [player guid low] = { moviePlaying, done }

local function after(player, seconds, fn)
    player:RegisterEvent(function(_, _, _, obj)
        if obj and obj:IsInWorld() then fn(obj) end
    end, seconds * 1000, 1)
end

local function weather(player, kind, grade)
    local map = player:GetMap()
    if map then map:SetWeather(CFG.shipZone, kind, grade) end
end

local function toBeach(p)
    local st = state[p:GetGUIDLow()]
    if not st or st.done then return end
    st.done = true
    weather(p, 0, 0)
    p:Teleport(CFG.beach.map, CFG.beach.x, CFG.beach.y, CFG.beach.z, CFG.beach.o)
    after(p, 1, function(p2)
        p2:SetRooted(true)
        p2:SetStandState(3)
        msg(p2, "|cffffff00You wash up on a beach. Everything hurts... 你被冲到了海滩上，浑身剧痛……|r")
        after(p2, CFG.knockedDownSeconds, function(p3)
            p3:SetStandState(0)
            p3:SetRooted(false)
            state[p3:GetGUIDLow()] = nil
            msg(p3, "|cffffff00You get back on your feet. 你重新站了起来。|r")
        end)
    end)
end

local function startWreck(player)
    local low = player:GetGUIDLow()
    if state[low] then
        msg(player, "The ship wreck sequence is already running. 船失事过程正在进行。")
        return
    end
    state[low] = { moviePlaying = false, done = false }
    msg(player, "|cffff8040The sky darkens. The ship starts to shake! 天色暗了下来，船开始剧烈摇晃！|r")
    weather(player, 3, 0.9)
    after(player, 3, function(p) msg(p, "|cffff8040Captain Garrick: Brace yourselves! 加里克船长：抓紧了！|r") end)
    after(player, CFG.stormDelayToMovie, function(p)
        p:SendAddonMessage("RBSHIP", "MOVIE|" .. CFG.moviePath, 7, p)
        local st = state[p:GetGUIDLow()]
        if st then st.moviePlaying = true end
    end)
    after(player, CFG.stormDelayToMovie + CFG.movieSeconds, function(p) toBeach(p) end)
    after(player, 90, function(p) state[p:GetGUIDLow()] = nil end)
end

RegisterCreatureEvent(JAINA, 34, function(event, player, creature, quest, opt)     -- ON_QUEST_REWARD
    local ok, err = pcall(function()
        if quest and quest:GetId() == Q_BRACE then
            creature:SendUnitSay("Everyone, brace yourselves! 所有人，抓紧了！", 0)
            startWreck(player)
        end
    end)
    if not ok then print("[Ally1A] reward ERROR: " .. tostring(err)) end
end)

RegisterServerEvent(30, function(event, sender, msgType, prefix, text)             -- ADDON_EVENT_ON_MESSAGE
    if prefix == "RBSHIP" and text == "DONE" then
        local st = sender and state[sender:GetGUIDLow()]
        if st and st.moviePlaying and not st.done then toBeach(sender) end
        return false
    end
end)

RegisterPlayerEvent(42, function(event, player, command)                           -- ON_COMMAND
    if not player then return end
    local c = tostring(command or ""):lower():gsub("^%.", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if c == "allycrash" then
        if player:GetGMRank() < 1 then return end
        startWreck(player)
        return false
    end
end)

RegisterPlayerEvent(4, function(event, player)                                     -- ON_LOGOUT
    if player then state[player:GetGUIDLow()] = nil end
end)

-- ---------------------------------------------------------------- stay on the ship
CreateLuaEvent(function()
    local ok, err = pcall(function()
        for _, p in pairs(GetPlayersInWorld()) do
            if p:IsInWorld() and p:GetMapId() == CFG.shipMap then
                local d = CFG.deck
                if not p:IsAlive() then
                    p:ResurrectPlayer(100, false)
                    p:Teleport(CFG.shipMap, d.x, d.y, d.z, d.o)
                    msg(p, "|cff00ff00You come back to life on the ship. 你在船上复活了。|r")
                elseif p:GetZ() < CFG.fallBelow then
                    p:Teleport(CFG.shipMap, d.x, d.y, d.z, d.o)
                    msg(p, "|cffffff00You were pulled back onto the deck. 你被拉回了甲板。|r")
                elseif p:IsInCombat() and p:GetQuestStatus(Q_WARM) == INCOMPLETE then
                    -- fighting a damaged dummy counts as practice, also when the kill is not reported (bot, other killer)
                    for _, t in pairs({ p:GetVictim(), p:GetSelection() }) do
                        if t and t:GetEntry() == DUMMY and t:GetHealth() < t:GetMaxHealth() then
                            finish(p, Q_WARM, "combat")
                            break
                        end
                    end
                end
            end
        end
    end)
    if not ok then print("[Ally1A] deck check ERROR: " .. tostring(err)) end
end, 1000, 0)

print("[Ally1A] ALLY1A V3 loaded: quests " .. Q_WARM .. "/" .. Q_SPAR .. "/" .. Q_BRACE .. " on map " .. CFG.shipMap)
