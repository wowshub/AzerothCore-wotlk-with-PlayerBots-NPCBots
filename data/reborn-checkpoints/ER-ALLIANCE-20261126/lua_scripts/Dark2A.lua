-- Dark2A.lua (ALLY1G V1, 2026-11-26, Claude) - candidate, NOT user-tested. Both factions: Horde 59984/59985, Alliance 55992/55991.
-- Dark2A.lua DARK3F V1 (2026-11-25, Claude) - candidate, NOT user-tested. Only the Kalecgos menu handlers changed.
-- Dark2A.lua (DARK3C V1 = Dark2A V4 again, 2026-11-25, Claude) - candidate, NOT user-tested. Replaces the DARK3B V1 file (no rooting any more).
-- DARK3C: the creatures of the dungeon interior move through the air (InhabitType in world_dark3c.sql) instead of being rooted, so they can chase without
--         dropping to the terrain far below. Same encounter script as DARK3A V1.
-- V4 (user request): the dungeon interior of this map is used for 59984.
--   * accepting 59984 teleports you to the entrance of the interior (855.40,-1384.25,176.63);
--   * Tunk (157300) and Gor'groth (156814) are static spawns (world_dark3a.sql), kill them in any order, working inward;
--   * when both are dead Kalecgos (156501, bound by the ritual) is spawned on the top platform (753.59,-1439.72,272.74);
--   * when Kalecgos dies, everyone within 120 yards is taken back to Mulgrin's platform (707.9,-1869.0,189.5), where the friendly Kalecgos (167663)
--     gives the "speak" credit for 59984 and, for 59985, a menu (take me to Orgrimmar now / not yet, with a confirm pop-up).
-- V3: Kalecgos opens a menu instead of teleporting on the first click. V2: no Dragon Isles, Wrathion (9167675) ends 59985 in Orgrimmar.
-- Boss/trash abilities are stock spells (Medviten's exiles_reach.cpp table: Tunk 72/8078, Gor'groth 695/8078); Kalecgos Frostbolt 9672 + Arcane Explosion 1449.
local TUNK, GORGROTH, KALEC_BOSS = 157300, 156814, 156501
local CASTER, CHANNELER = 9159802, 9159803
local MAP = 12175
local ENTRANCE = {MAP, 855.40, -1384.25, 176.63, 3.72}
local PLATFORM = {x = 753.59, y = -1439.72, z = 272.74, o = 0.40}      -- where Kalecgos appears
local MULGRIN = {MAP, 707.9, -1869.0, 189.5, 4.23}                       -- back to the Tauren warlord's platform
local ORG = {1, 1631.5, -4443.5, 15.8, 1.2}                               -- Orgrimmar, Grommash Hold, next to Wrathion 9167675
local STORMWIND = {0, -8833.38, 628.63, 94.01, 1.065}                    -- Stormwind, next to Captain Garrick 154169
local END_CREDIT = 244389                                                 -- retail objective id of 59985 (no creature template needed)
local SUMMON_TYPE, LIFETIME_MS = 1, 30 * 60 * 1000                        -- TEMPSUMMON_TIMED_OR_DEAD_DESPAWN
local RETURN_RANGE = 120

local tunkDead, gorgrothDead, kalecActive = false, false, false
local resetAt = 0

local function msg(p, s) p:SendBroadcastMessage(s) end
local function say(c, s) pcall(function() c:SendUnitSay(s, 0) end) end

-- ---------------------------------------------------------------- abilities
local function setupBoss(entry, spellA, everyA, spellB, everyB)
    RegisterCreatureEvent(entry, 1, function(event, creature, target)                -- ON_ENTER_COMBAT
        creature:RemoveEvents()
        creature:RegisterEvent(function(_, _, _, c)
            local v = c:GetVictim()
            if v then c:CastSpell(v, spellA, false) end
        end, everyA, 0)
        creature:RegisterEvent(function(_, _, _, c) c:CastSpell(c, spellB, false) end, everyB, 0)
    end)
    RegisterCreatureEvent(entry, 2, function(event, creature) creature:RemoveEvents() end)   -- ON_LEAVE_COMBAT
end
setupBoss(TUNK, 72, 9000, 8078, 17000)                 -- Shield Bash, Thunderclap
setupBoss(GORGROTH, 695, 5000, 8078, 17000)            -- Shadow Bolt, Thunderclap
setupBoss(KALEC_BOSS, 9672, 5000, 1449, 15000)         -- Frostbolt, Arcane Explosion
for _, e in ipairs({CASTER, CHANNELER}) do
    RegisterCreatureEvent(e, 1, function(event, creature, target)
        creature:RemoveEvents()
        creature:RegisterEvent(function(_, _, _, c)
            local v = c:GetVictim()
            if v then c:CastSpell(v, 695, false) end
        end, 4500, 0)
    end)
    RegisterCreatureEvent(e, 2, function(event, creature) creature:RemoveEvents() end)
end

-- one row per faction: dungeon quest, finale quest, friendly Kalecgos, destination of the finale
local SIDES = {
    {dungeon = 59984, finale = 59985, friend = 167663, dest = ORG, city = "Orgrimmar", cityCn = "奥格瑞玛", leader = "Thrall", leaderCn = "萨尔"},
    {dungeon = 55992, finale = 55991, friend = 161350, dest = STORMWIND, city = "Stormwind", cityCn = "暴风城", leader = "Jaina", leaderCn = "吉安娜"},
}

-- ---------------------------------------------------------------- accept: go to the entrance
RegisterPlayerEvent(63, function(event, player, quest)                                   -- ON_QUEST_ACCEPT
    local ok, err = pcall(function()
        local id = quest:GetId()
        if id ~= SIDES[1].dungeon and id ~= SIDES[2].dungeon then return end
        msg(player, "|cff00ff00You are taken to the entrance of Darkmaul Citadel. Fight your way inward: Tunk, Gor'groth, then Kalecgos on the top platform. / 你被传送到暗槌要塞内部入口。一路向里：图克、戈尔格罗斯，最后是最高处平台上的卡雷苟斯。|r")
        player:Teleport(ENTRANCE[1], ENTRANCE[2], ENTRANCE[3], ENTRANCE[4], ENTRANCE[5])
    end)
    if not ok then print("[Dark2A] accept ERROR: " .. tostring(err)) end
end)

-- ---------------------------------------------------------------- boss flow
local function announce(creature, text)
    pcall(function()
        for _, p in pairs(creature:GetPlayersInRange(150)) do msg(p, text) end
    end)
end

local function maybeSpawnKalecgos(anchor)
    if os.time() > resetAt then tunkDead, gorgrothDead, kalecActive = false, false, false end
    if tunkDead and gorgrothDead and not kalecActive then
        kalecActive = true
        local k = anchor:SpawnCreature(KALEC_BOSS, PLATFORM.x, PLATFORM.y, PLATFORM.z, PLATFORM.o, SUMMON_TYPE, LIFETIME_MS)
        if k then say(k, "The... ritual... I am... not... myself. 仪式……我……不再是我自己了。") end
        announce(anchor, "|cffff8800Kalecgos, bound by the ritual, awaits on the top platform! / 被仪式控制的卡雷苟斯在最高处的平台上等着你！|r")
        print("[Dark2A] Kalecgos spawned on the platform")
    end
end

RegisterCreatureEvent(TUNK, 4, function(event, creature, killer)                         -- ON_DIED
    local ok, err = pcall(function()
        if os.time() > resetAt then tunkDead, gorgrothDead, kalecActive = false, false, false end
        tunkDead = true; resetAt = os.time() + LIFETIME_MS / 1000
        announce(creature, "|cff00ff00Tunk is down. / 图克倒下了。|r")
        maybeSpawnKalecgos(creature)
    end)
    if not ok then print("[Dark2A] Tunk died ERROR: " .. tostring(err)) end
end)
RegisterCreatureEvent(GORGROTH, 4, function(event, creature, killer)
    local ok, err = pcall(function()
        if os.time() > resetAt then tunkDead, gorgrothDead, kalecActive = false, false, false end
        gorgrothDead = true; resetAt = os.time() + LIFETIME_MS / 1000
        announce(creature, "|cff00ff00Gor'groth is down. / 戈尔格罗斯倒下了。|r")
        maybeSpawnKalecgos(creature)
    end)
    if not ok then print("[Dark2A] Gor'groth died ERROR: " .. tostring(err)) end
end)
RegisterCreatureEvent(KALEC_BOSS, 4, function(event, creature, killer)
    local ok, err = pcall(function()
        say(creature, "Thank you... the shadow is gone. Find me at the camp. 谢谢你……暗影散去了。到营地来找我。")
        tunkDead, gorgrothDead, kalecActive = false, false, false
        local list = creature:GetPlayersInRange(RETURN_RANGE)
        if killer and killer.GetObjectType and killer:GetObjectType() == "Player" then list[#list + 1] = killer end
        local done = {}
        for _, p in pairs(list) do
            local gl = p:GetGUIDLow()
            if not done[gl] then
                done[gl] = true
                msg(p, "|cff00ff00Kalecgos is free. You are taken back to the upper platform; speak with Kalecgos there. / 卡雷苟斯自由了。你被送回高处的平台，去和那里的卡雷苟斯说话。|r")
                p:Teleport(MULGRIN[1], MULGRIN[2], MULGRIN[3], MULGRIN[4], MULGRIN[5])
            end
        end
    end)
    if not ok then print("[Dark2A] Kalecgos died ERROR: " .. tostring(err)) end
end)

-- ---------------------------------------------------------------- friendly Kalecgos: credit for 59984, menu + teleport for 59985
local GOSSIP_ICON_CHAT, GOSSIP_ICON_TAXI = 0, 2
local OPT_GO, OPT_STAY = 1, 2
local MENU_TEXT = 1                                           -- stock npc_text id 1, the real text is in the options

-- the handlers return nothing. With "return false" the engine goes on with the core default and its greeting window
-- replaces our menu (no travel option).
local function friendlyKalecgos(side)
    RegisterCreatureGossipEvent(side.friend, 1, function(event, player, creature)           -- GOSSIP_EVENT_ON_HELLO
        local ok, err = pcall(function()
            if player:HasQuest(side.finale) then
                player:GossipClearMenu()
                player:GossipMenuAddItem(GOSSIP_ICON_TAXI, "Take me to " .. side.city .. " now. / 现在就带我去" .. side.cityCn .. "。", 0, OPT_GO, false,
                    "Travel to " .. side.city .. " now? / 现在就前往" .. side.cityCn .. "吗？", 0)
                player:GossipMenuAddItem(GOSSIP_ICON_CHAT, "Not yet. / 先不去。", 0, OPT_STAY)
                player:GossipSendMenu(MENU_TEXT, creature)
                return
            end
            if player:HasQuest(side.dungeon) then
                player:KilledMonsterCredit(side.friend)
                creature:SendUnitSay("Thank you. Report to " .. side.leader .. ". 谢谢你。去向" .. side.leaderCn .. "复命吧。", 0)
            else
                creature:SendUnitSay("Come back when " .. side.leader .. " sends you. 等" .. side.leaderCn .. "派你来的时候再来找我。", 0)
            end
            player:GossipComplete()
        end)
        if not ok then print("[Dark2A] Kalecgos gossip ERROR: " .. tostring(err)); pcall(function() player:GossipComplete() end) end
    end)

    RegisterCreatureGossipEvent(side.friend, 2, function(event, player, creature, sender, intid, code)   -- GOSSIP_EVENT_ON_SELECT
        local ok, err = pcall(function()
            player:GossipComplete()
            if intid == OPT_GO and player:HasQuest(side.finale) then
                player:KilledMonsterCredit(END_CREDIT)
                creature:SendUnitSay("Hold on to something. 抓紧了。", 0)
                local d = side.dest
                player:Teleport(d[1], d[2], d[3], d[4], d[5])
            end
        end)
        if not ok then print("[Dark2A] Kalecgos select ERROR: " .. tostring(err)) end
    end)
end
for _, side in ipairs(SIDES) do friendlyKalecgos(side) end

print("[Dark2A] ALLY1G V1 loaded: both factions, quests 59984/59985 and 55992/55991, bosses " .. TUNK .. "/" .. GORGROTH .. "/" .. KALEC_BOSS)
