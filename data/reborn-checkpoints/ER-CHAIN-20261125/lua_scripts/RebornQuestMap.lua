-- RebornQuestMap.lua (QMAP1A V1, 2026-11-23, Claude)
-- Server side of the quest map icons: every few seconds, for each player on the island map, work out which quest NPCs show
-- "!" (quest available), "?" (ready to turn in) or a grey "?" (in progress) and send the list to the client addon RebornQuestMap
-- as addon messages (prefix RQM). Data (who starts / ends which quest, where the NPC stands) is read from the world DB at load,
-- so new quest batches need no change here (type .reloadqmap as GM, or restart).
local MAP = 12175
local Q_LO, Q_HI = 59926, 60100
local TICK_MS = 3000
local PREFIX = "RQM"

-- ---- marker table: one entry per NPC spawn
local markers = {}            -- list of { x, y, name, starts = {quest..}, ends = {quest..} }
local prevQuest = {}          -- [quest] = prerequisite quest id (0 = none)

local function load_markers()
    markers = {}
    prevQuest = {}
    local byGuid = {}
    local function pull(table_name, key)
        local sql = "SELECT t.quest, c.guid, c.position_x, c.position_y, IFNULL(ct.name, '') FROM " .. table_name ..
            " t JOIN creature c ON c.id1 = t.id JOIN creature_template ct ON ct.entry = t.id WHERE c.map = " .. MAP ..
            " AND t.quest BETWEEN " .. Q_LO .. " AND " .. Q_HI
        local q = WorldDBQuery(sql)
        if q then
            repeat
                local quest, guid, x, y, name = q:GetUInt32(0), q:GetUInt32(1), q:GetFloat(2), q:GetFloat(3), q:GetString(4)
                local m = byGuid[guid]
                if not m then
                    m = { x = x, y = y, name = name, starts = {}, ends = {} }
                    byGuid[guid] = m
                    markers[#markers + 1] = m
                end
                m[key][#m[key] + 1] = quest
            until not q:NextRow()
        end
    end
    pull("creature_queststarter", "starts")
    pull("creature_questender", "ends")
    local q = WorldDBQuery("SELECT ID, PrevQuestID FROM quest_template_addon WHERE ID BETWEEN " .. Q_LO .. " AND " .. Q_HI)
    if q then
        repeat
            prevQuest[q:GetUInt32(0)] = q:GetInt32(1)
        until not q:NextRow()
    end
    print("[RebornQuestMap] QMAP1A V1 loaded: " .. #markers .. " quest NPCs on map " .. MAP)
end
load_markers()

-- ---- per-player state
local function available(player, quest)
    if player:GetQuestRewardStatus(quest) or player:HasQuest(quest) then return false end
    local prev = prevQuest[quest] or 0
    if prev > 0 and not player:GetQuestRewardStatus(prev) then return false end
    return true
end

local function icon_for(player, m)
    for _, quest in ipairs(m.ends) do
        if player:HasQuest(quest) and player:GetQuestStatus(quest) == 1 then return "C" end   -- COMPLETE: ready to turn in
    end
    for _, quest in ipairs(m.starts) do
        if available(player, quest) then return "A" end
    end
    for _, quest in ipairs(m.ends) do
        if player:HasQuest(quest) then return "P" end                                         -- in progress
    end
    return nil
end

local last = {}               -- [guidLow] = last signature sent
local function send(player, msg) player:SendAddonMessage(PREFIX, msg, 7, player) end

local function refresh(player)
    local parts, sig = {}, {}
    for _, m in ipairs(markers) do
        local ic = icon_for(player, m)
        if ic then
            parts[#parts + 1] = string.format("M|%.1f|%.1f|%s|%s", m.x, m.y, ic, m.name)
            sig[#sig + 1] = string.format("%.0f,%.0f,%s", m.x, m.y, ic)
        end
    end
    local s = table.concat(sig, ";")
    local low = player:GetGUIDLow()
    if last[low] == s then return end
    last[low] = s
    send(player, "C")
    for _, p in ipairs(parts) do send(player, p) end
    send(player, "E")
end

local function clear(player)
    local low = player:GetGUIDLow()
    if last[low] ~= "" then
        last[low] = ""
        send(player, "C")
        send(player, "E")
    end
end

CreateLuaEvent(function()
    for _, player in pairs(GetPlayersInWorld()) do
        if player:IsInWorld() then
            if player:GetMapId() == MAP then refresh(player) else clear(player) end
        end
    end
end, TICK_MS, 0)

-- a fresh login / map change always resends
RegisterPlayerEvent(3, function(event, player) last[player:GetGUIDLow()] = nil end)       -- PLAYER_EVENT_ON_LOGIN
RegisterPlayerEvent(4, function(event, player) last[player:GetGUIDLow()] = nil end)       -- logout
RegisterPlayerEvent(28, function(event, player) last[player:GetGUIDLow()] = nil end)      -- map change

-- GM: .reloadqmap  (reload NPC data after a new quest batch without restarting)
RegisterPlayerEvent(42, function(event, player, command)
    local c = tostring(command or ""):lower():gsub("^%.", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if c == "reloadqmap" and player:GetGMRank() >= 1 then
        load_markers()
        last = {}
        player:SendBroadcastMessage("RebornQuestMap: reloaded " .. #markers .. " quest NPCs.")
        return false
    end
end)
