-- Hara2.lua (HARA2 V2, 2026-11-26, Claude): click objectives of the Haranir starter quests 90958 and 90959.
local MAP = 12694
local Q_ROOTS, Q_DUTIES = 90958, 90959
local PLANT = 246277                                   -- Withered Plant (pull it)
local ALTON, DALNIR_DEN = 245104, 246705               -- the outsider, Dalnir at the Den
local FOUND, SAPTOR, SAFE, MET = 247257, 245114, 246360, 253478

local function msg(p, s) p:SendBroadcastMessage(s) end

local function need(player, quest, entry, count)
    return player:HasQuest(quest) and player:GetReqKillOrCastCurrentCount(quest, entry) < (count or 1)
end

local pulledAt = {}                                     -- [plant guid low] = os.time() of the click that counted

RegisterCreatureGossipEvent(PLANT, 1, function(event, player, creature)
    player:GossipComplete()
    local id, now = creature:GetGUIDLow(), os.time()
    if pulledAt[id] and now - pulledAt[id] < 10 then return end    -- already pulled, it is about to vanish
    if need(player, Q_ROOTS, PLANT, 6) then
        pulledAt[id] = now
        player:KilledMonsterCredit(PLANT)
        creature:DespawnOrUnsummon(800)                -- it grows back after its spawn time
    else
        msg(player, "A withered plant. / 一株枯萎的植物。")
    end
end)

RegisterCreatureGossipEvent(ALTON, 1, function(event, player, creature)
    player:GossipComplete()
    if need(player, Q_DUTIES, FOUND) then
        player:KilledMonsterCredit(FOUND)
        creature:SendUnitSay("Help! That saptor will not let me go! 救命！那只迅叶龙不放我走！", 0)
    elseif need(player, Q_DUTIES, SAPTOR) then
        creature:SendUnitSay("Deal with the saptor first! 先解决那只迅叶龙！", 0)
    elseif need(player, Q_DUTIES, SAFE) then
        player:KilledMonsterCredit(SAFE)
        creature:SendUnitSay("Thank you. I will head to Har'mara. 谢谢你，我这就去哈尔玛拉。", 0)
        msg(player, "Now meet Dalnir at the Den of Remembrance. / 现在去铭记之穴和戴尼尔会合。")
    else
        creature:SendUnitSay("These roots are beautiful. 这些根须真美。", 0)
    end
end)

RegisterCreatureGossipEvent(DALNIR_DEN, 1, function(event, player, creature)
    player:GossipComplete()
    if need(player, Q_DUTIES, MET) then
        player:KilledMonsterCredit(MET)
        creature:SendUnitSay("You came. Speak with Orweyna. 你来了，去和奥威娜说话吧。", 0)
    else
        creature:SendUnitSay("The ceremony awaits. 仪式在等着你。", 0)
    end
end)

print("[Hara2] HARA2 V2 loaded: Haranir starter quests 90957-90960 on map " .. MAP)
