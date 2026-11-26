-- RebornQuestMap v2 (QMAP1A V2, 2026-11-23, Claude)
-- Draws quest NPC icons on the world map and the minimap for Exile's Reach. The server tells us which NPCs to mark (addon prefix RQM):
--   "C" clear, "M|worldX|worldY|icon|name" add (icon A = available "!", C = ready "?", P = in progress grey "?"), "E" end.
-- Built defensively (pcall, optional APIs guarded) because this client rejects some APIs.
local ICONS = {
    A = "Interface\\GossipFrame\\AvailableQuestIcon",
    C = "Interface\\GossipFrame\\ActiveQuestIcon",
    P = "Interface\\GossipFrame\\IncompleteQuestIcon",
}
-- WorldMapArea of Exile's Reach (client Patch-X): world axis bounds
local LEFT, RIGHT, TOP, BOTTOM = -518.8, -3900.0, 1433.3, -820.8
local MAPNAME = "ExilesReach"

local marks = {}          -- { x, y, icon, name }
local mapPins, miniPins = {}, {}

local function err(msg)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffff4040[RebornQuestMap] " .. tostring(msg) .. "|r") end
end

local function norm(x, y)     -- world -> 0..1 on the island map
    return (LEFT - y) / (LEFT - RIGHT), (TOP - x) / (TOP - BOTTOM)
end

local function newPin(parent, size, icon)
    local f = CreateFrame("Frame", nil, parent)
    f:SetWidth(size); f:SetHeight(size)
    local t = f:CreateTexture(nil, "OVERLAY")
    t:SetAllPoints(f)
    t:SetTexture(icon)
    f.tex = t
    f:EnableMouse(true)
    f:SetScript("OnEnter", function(self)
        if self.mname then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.mname)
            GameTooltip:Show()
        end
    end)
    f:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return f
end

-- Is the world map currently showing the island?  v2: three independent checks, any one is enough
--  1) the map name contains "exile" (any case), 2) the player has a valid position on the shown map (only true when the shown map is the
--  zone the player stands in), 3) the world map's zone text.  v1 only used check 1 with an exact-case match and showed nothing.
local function mapIsIsland()
    local ok, name = pcall(function() return GetMapInfo and (GetMapInfo()) or nil end)
    if ok and type(name) == "string" and name:lower():find("exile", 1, true) then return true end
    local ok2, px, py = pcall(GetPlayerMapPosition, "player")
    if ok2 and px and py and (px ~= 0 or py ~= 0) then return true end
    return false
end

local function layoutMap()
    for _, p in ipairs(mapPins) do p:Hide() end
    if not WorldMapButton or not mapIsIsland() then return end
    local w, h = WorldMapButton:GetWidth(), WorldMapButton:GetHeight()
    for i, m in ipairs(marks) do
        local p = mapPins[i]
        if not p then p = newPin(WorldMapButton, 22, ICONS[m.icon]); mapPins[i] = p end
        p.tex:SetTexture(ICONS[m.icon] or ICONS.A)
        p.mname = m.name
        local nx, ny = norm(m.x, m.y)
        p:ClearAllPoints()
        p:SetPoint("CENTER", WorldMapButton, "TOPLEFT", nx * w, -ny * h)
        p:SetFrameLevel(WorldMapButton:GetFrameLevel() + 6)
        p:Show()
    end
end

-- ---- minimap
local RADIUS_OUT = { [0] = 233.33, [1] = 200, [2] = 166.67, [3] = 133.33, [4] = 100, [5] = 66.67 }   -- yards (outdoors), index = minimap zoom
local lastPlayerX, lastPlayerY
local function playerWorldXY()
    -- converts the player's map position back to world axes with the island bounds; needs the map set to the current zone
    if WorldMapFrame and WorldMapFrame:IsShown() then return lastPlayerX, lastPlayerY end
    if SetMapToCurrentZone then pcall(SetMapToCurrentZone) end
    local nx, ny = GetPlayerMapPosition("player")
    if not nx or (nx == 0 and ny == 0) then return nil end
    lastPlayerX, lastPlayerY = TOP - ny * (TOP - BOTTOM), LEFT - nx * (LEFT - RIGHT)
    return lastPlayerX, lastPlayerY
end

local function layoutMini()
    for _, p in ipairs(miniPins) do p:Hide() end
    if #marks == 0 then return end
    local px, py = playerWorldXY()
    if not px then return end
    local zoom = Minimap:GetZoom() or 0
    local radius = RADIUS_OUT[zoom] or 233.33
    local mw = Minimap:GetWidth() / 2
    local rot = nil
    if GetCVar and GetCVar("rotateMinimap") == "1" and GetPlayerFacing then rot = GetPlayerFacing() end
    for i, m in ipairs(marks) do
        local p = miniPins[i]
        if not p then p = newPin(Minimap, 16, ICONS[m.icon]); miniPins[i] = p end
        p.tex:SetTexture(ICONS[m.icon] or ICONS.A)
        p.mname = m.name
        -- world Y grows to the west, world X grows to the north: minimap east = -dY, north = dX
        local dx, dy = -(m.y - py), (m.x - px)
        if rot then
            local c, s = math.cos(rot), math.sin(rot)
            dx, dy = dx * c - dy * s, dx * s + dy * c
        end
        local dist = math.sqrt(dx * dx + dy * dy)
        local scale = mw / radius
        local ox, oy = dx * scale, dy * scale
        if dist > radius * 0.92 then
            local k = (radius * 0.92) / dist
            ox, oy = ox * k, oy * k
        end
        p:ClearAllPoints()
        p:SetPoint("CENTER", Minimap, "CENTER", ox, oy)
        p:SetFrameLevel(Minimap:GetFrameLevel() + 6)
        p:Show()
    end
end

-- ---- server messages
local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_ADDON")
f:RegisterEvent("WORLD_MAP_UPDATE")
local pending
f:SetScript("OnEvent", function(self, event, prefix, msg)
    local ok, e = pcall(function()
        if event == "WORLD_MAP_UPDATE" then layoutMap(); return end
        if prefix ~= "RQM" or type(msg) ~= "string" then return end
        if msg == "C" then
            pending = {}
        elseif msg:sub(1, 2) == "M|" and pending then
            local x, y, ic, name = strsplit("|", msg:sub(3), 4)
            pending[#pending + 1] = { x = tonumber(x), y = tonumber(y), icon = ic, name = name }
        elseif msg == "E" and pending then
            marks, pending = pending, nil
            layoutMap(); layoutMini()
        end
    end)
    if not ok then err(e) end
end)

local acc = 0
f:SetScript("OnUpdate", function(self, dt)
    acc = acc + dt
    if acc < 0.15 then return end
    acc = 0
    local ok, e = pcall(layoutMini)
    if not ok then err(e); f:SetScript("OnUpdate", nil) end
end)
if WorldMapFrame and WorldMapFrame.HookScript then WorldMapFrame:HookScript("OnShow", function() pcall(layoutMap) end) end

-- keep the world map pins in step while the map is open (size changes in windowed mode, map switches)
local mapAcc = 0
local g = CreateFrame("Frame")
g:SetScript("OnUpdate", function(self, dt)
    mapAcc = mapAcc + dt
    if mapAcc < 0.5 then return end
    mapAcc = 0
    if WorldMapFrame and WorldMapFrame:IsShown() and #marks > 0 then pcall(layoutMap) end
end)

-- /rqm : print what the addon sees (for diagnosing)
SLASH_REBORNQUESTMAP1 = "/rqm"
SlashCmdList["REBORNQUESTMAP"] = function()
    local ok, name, h = pcall(function() return GetMapInfo() end)
    local px, py = GetPlayerMapPosition("player")
    DEFAULT_CHAT_FRAME:AddMessage(string.format("[RebornQuestMap] marks=%d  mapName=%s  playerPos=%.3f,%.3f  mapShowsIsland=%s  WorldMapButton=%s",
        #marks, tostring(name), px or -1, py or -1, tostring(mapIsIsland()), WorldMapButton and string.format("%dx%d", WorldMapButton:GetWidth(), WorldMapButton:GetHeight()) or "nil"))
    for i, m in ipairs(marks) do
        local nx, ny = norm(m.x, m.y)
        DEFAULT_CHAT_FRAME:AddMessage(string.format("  %d %s icon=%s world=(%.0f,%.0f) map=(%.3f,%.3f)", i, tostring(m.name), tostring(m.icon), m.x, m.y, nx, ny))
        if i >= 4 then break end
    end
end
