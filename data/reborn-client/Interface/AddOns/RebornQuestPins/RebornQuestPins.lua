-- RebornQuestPins 1.1 (DARK3F V1, 2026-11-25, Claude) - candidate, NOT user-tested.
-- 1.1: quest 59985 - Kalecgos on the island while the quest is not complete, Wrathion in Orgrimmar once it is.
-- The 3.3.5 client does not mark quest-giving objects on the maps, so this draws a yellow "!" for the listed ones:
-- on the world map of Exile's Reach and on the minimap (stays at the rim when the sign is out of range).
-- A pin disappears while its quest is in the log and after it has been turned in.
local PINS = {
    -- quest id, map file name, world X, world Y, title
    { quest = 56839, show = "new", map = "ExilesReach", x = 211.542, y = -2166.91, title = "Danger Sign 危险告示牌", text = "Killclaw the Terrible / 可怕的杀爪" },
    { quest = 59985, show = "active", map = "ExilesReach", x = 709.0, y = -1884.5, title = "Kalecgos 卡雷苟斯", text = "An End to Beginnings / 终结即开始" },
    { quest = 59985, show = "complete", map = "Ogrimmar", x = 1637.0, y = -4442.0, title = "Wrathion 瑞斯拉克", text = "An End to Beginnings / 终结即开始" },
}
-- WorldMapArea.dbc bounds: island (id 20414) and Orgrimmar (id 321)
local BOUNDS = {
    ExilesReach = { left = -518.75, right = -3900.0, top = 1433.33, bottom = -820.83 },
    Ogrimmar = { left = -3680.6, right = -5083.21, top = 2273.88, bottom = 1338.46 },
}
local MINI_DIAMETER = { [0] = 466.67, 400, 333.33, 266.67, 200, 133.33 }   -- outdoor minimap, yards per zoom level
local ICON_NEW = "Interface\\GossipFrame\\AvailableQuestIcon"
local ICON_ACTIVE = "Interface\\GossipFrame\\ActiveQuestIcon"

local done = {}                -- [questId] = true once turned in
local inLog = {}
local complete = {}
local worldPins, miniPins = {}, {}

local function fraction(p)
    local b = BOUNDS[p.map]
    return (b.left - p.y) / (b.left - b.right), (b.top - p.x) / (b.top - b.bottom)
end

local function wanted(p)
    if p.show == "active" then return inLog[p.quest] == true and not complete[p.quest] end
    if p.show == "complete" then return inLog[p.quest] == true and complete[p.quest] == true end
    return not done[p.quest] and not inLog[p.quest]
end

local function tooltip(self)
    local tip = (self.onWorldMap and WorldMapTooltip) or GameTooltip
    tip:SetOwner(self, "ANCHOR_RIGHT")
    tip:SetText(self.pin.title, 1, 0.82, 0)
    tip:AddLine(self.pin.text, 1, 1, 1)
    tip:Show()
end

local function hideTooltip(self)
    local tip = (self.onWorldMap and WorldMapTooltip) or GameTooltip
    tip:Hide()
end

local function newPin(parent, size, pin, onWorldMap)
    local f = CreateFrame("Button", nil, parent)
    f:SetWidth(size); f:SetHeight(size)
    local t = f:CreateTexture(nil, "OVERLAY")
    t:SetAllPoints(f); t:SetTexture(pin.show == "new" and ICON_NEW or ICON_ACTIVE)
    f.pin, f.onWorldMap = pin, onWorldMap
    f:SetScript("OnEnter", tooltip)
    f:SetScript("OnLeave", hideTooltip)
    f:Hide()
    return f
end

local function updateWorld()
    if not WorldMapFrame:IsShown() then return end
    local name = GetMapInfo()
    for i, p in ipairs(PINS) do
        local f = worldPins[i]
        if not f then
            f = newPin(WorldMapButton, 20, p, true)
            f:SetFrameLevel(WorldMapButton:GetFrameLevel() + 5)
            worldPins[i] = f
        end
        if name == p.map and wanted(p) then
            local fx, fy = fraction(p)
            f:ClearAllPoints()
            f:SetPoint("CENTER", WorldMapButton, "TOPLEFT", fx * WorldMapButton:GetWidth(), -fy * WorldMapButton:GetHeight())
            f:Show()
        else
            f:Hide()
        end
    end
end

local function updateMini()
    if WorldMapFrame:IsShown() then return end          -- the position then refers to the viewed map
    local name = GetMapInfo()
    local px, py = GetPlayerMapPosition("player")
    for i, p in ipairs(PINS) do
        local f = miniPins[i]
        if not f then
            f = newPin(Minimap, 16, p, false)
            f:SetFrameStrata("MEDIUM"); f:SetFrameLevel(Minimap:GetFrameLevel() + 6)
            miniPins[i] = f
        end
        if name == p.map and wanted(p) and px and (px > 0 or py > 0) then
            local fx, fy = fraction(p)
            local b = BOUNDS[p.map]
            local east, north = (fx - px) * (b.left - b.right), (py - fy) * (b.top - b.bottom)
            if GetCVar("rotateMinimap") == "1" and GetPlayerFacing then
                local a = GetPlayerFacing() or 0
                local c, s = math.cos(a), math.sin(a)
                east, north = east * c + north * s, -east * s + north * c
            end
            local diameter = MINI_DIAMETER[Minimap:GetZoom()] or 466.67
            local scale = Minimap:GetWidth() / diameter
            local x, y = east * scale, north * scale
            local rim = Minimap:GetWidth() / 2 - 6
            local len = math.sqrt(x * x + y * y)
            if len > rim then x, y = x * rim / len, y * rim / len; f:SetAlpha(0.7) else f:SetAlpha(1) end
            f:ClearAllPoints()
            f:SetPoint("CENTER", Minimap, "CENTER", x, y)
            f:Show()
        else
            f:Hide()
        end
    end
end

local function readLog()
    inLog, complete = {}, {}
    for i = 1, GetNumQuestLogEntries() do
        local _, _, _, _, isHeader, _, isComplete, _, questID = GetQuestLogTitle(i)
        if not isHeader and questID then
            inLog[questID] = true
            if isComplete == 1 then complete[questID] = true end
        end
    end
end

local function readDone()
    if GetQuestsCompleted then
        local t = GetQuestsCompleted()
        for id in pairs(t or {}) do done[id] = true end
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("QUEST_LOG_UPDATE")
frame:RegisterEvent("WORLD_MAP_UPDATE")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
pcall(frame.RegisterEvent, frame, "QUEST_QUERY_COMPLETE")
frame:SetScript("OnEvent", function(self, event)
    local ok, err = pcall(function()
        if event == "PLAYER_ENTERING_WORLD" then
            if QueryQuestsCompleted then QueryQuestsCompleted() end
        elseif event == "QUEST_QUERY_COMPLETE" then
            readDone()
        elseif event == "ZONE_CHANGED_NEW_AREA" then
            if not WorldMapFrame:IsShown() then SetMapToCurrentZone() end
        end
        if event == "QUEST_LOG_UPDATE" or event == "PLAYER_ENTERING_WORLD" then readLog() end
        updateWorld()
    end)
    if not ok then DEFAULT_CHAT_FRAME:AddMessage("|cffff4444RebornQuestPins: " .. tostring(err) .. "|r") end
end)

-- a quest that left the log may have been turned in: ask the server again
if hooksecurefunc and GetQuestReward then
    hooksecurefunc("GetQuestReward", function() if QueryQuestsCompleted then QueryQuestsCompleted() end end)
end

-- after browsing another map, go back to the current zone so the minimap pin has a valid position
WorldMapFrame:HookScript("OnHide", function() SetMapToCurrentZone() end)

local acc, failed = 0, false
frame:SetScript("OnUpdate", function(self, elapsed)
    acc = acc + elapsed
    if acc < 0.2 or failed then return end
    acc = 0
    local ok, err = pcall(function() updateMini(); updateWorld() end)
    if not ok then failed = true; DEFAULT_CHAT_FRAME:AddMessage("|cffff4444RebornQuestPins: " .. tostring(err) .. "|r") end
end)

SLASH_REBORNQUESTPINS1 = "/rqp"
SlashCmdList["REBORNQUESTPINS"] = function()
    local px, py = GetPlayerMapPosition("player")
    DEFAULT_CHAT_FRAME:AddMessage(string.format("RebornQuestPins: map=%s pos=%.4f,%.4f", tostring(GetMapInfo()), px or 0, py or 0))
    for _, p in ipairs(PINS) do
        DEFAULT_CHAT_FRAME:AddMessage(string.format("  quest %d (%s, %s): inLog=%s complete=%s done=%s shown=%s", p.quest, p.show, p.map,
            tostring(inLog[p.quest] == true), tostring(complete[p.quest] == true), tostring(done[p.quest] == true), tostring(wanted(p) == true)))
    end
end
