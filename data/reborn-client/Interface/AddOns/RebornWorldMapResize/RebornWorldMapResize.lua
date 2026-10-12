-- RebornWorldMapResize (RebornWOW MAPRS1A)
-- Adds a corner grip to the WINDOWED world map (the small map toggled with the
-- button at its top right). Drag the grip to scale the whole window; the size is
-- remembered. Right-click the grip to reset. The full-screen map is never scaled.
--
-- Only WorldMapFrame:SetScale is used, so every overlay drawn as a child of the
-- map (coordinates, boss icons, fog of war) scales with it.

local MIN_SCALE, MAX_SCALE = 0.6, 2.5

local f = CreateFrame("Frame")
local grip

local function IsWindowed()
    if WORLDMAP_SETTINGS and WORLDMAP_WINDOWED_SIZE then
        return WORLDMAP_SETTINGS.size == WORLDMAP_WINDOWED_SIZE
    end
    return WorldMapFrameMiniBorderLeft and WorldMapFrameMiniBorderLeft:IsShown()
end

local function Clamp(v)
    if v < MIN_SCALE then return MIN_SCALE end
    if v > MAX_SCALE then return MAX_SCALE end
    return v
end

local function Apply()
    if not WorldMapFrame then return end
    if IsWindowed() then
        WorldMapFrame:SetScale(Clamp(RebornWorldMapResizeDB.scale or 1))
        if grip then grip:Show() end
    else
        WorldMapFrame:SetScale(1)
        if grip then grip:Hide() end
    end
end

local function CreateGrip()
    if grip or not WorldMapFrame or not WorldMapDetailFrame then return end

    grip = CreateFrame("Button", "RebornWorldMapResizeGrip", WorldMapFrame)
    -- MAPRS1B: larger, on a dark gold-edged plate, nudged inward off the blue
    -- corner jewel of the map border so it reads as a control.
    grip:SetSize(26, 26)
    grip:SetPoint("BOTTOMRIGHT", WorldMapDetailFrame, "BOTTOMRIGHT", -16, 16)
    grip:SetFrameStrata("TOOLTIP")
    grip:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    grip:SetBackdropColor(0, 0, 0, 0.75)
    grip:SetBackdropBorderColor(1, 0.82, 0, 1)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    for _, tex in ipairs({ grip:GetNormalTexture(), grip:GetPushedTexture() }) do
        tex:ClearAllPoints()
        tex:SetPoint("TOPLEFT", 3, -3)
        tex:SetPoint("BOTTOMRIGHT", -3, 3)
        tex:SetVertexColor(1, 0.82, 0)
    end
    grip:RegisterForClicks("RightButtonUp")

    grip:SetScript("OnMouseDown", function(self, button)
        if button ~= "LeftButton" then return end
        local x, y = GetCursorPosition()
        self.startX, self.startY = x, y
        self.startScale = WorldMapFrame:GetScale()
        -- Grip distance from the map's top-left in screen pixels at drag start;
        -- the new scale keeps the grip under the cursor.
        local left, top = WorldMapFrame:GetLeft(), WorldMapFrame:GetTop()
        local eff = WorldMapFrame:GetEffectiveScale()
        self.spanX = math.max(1, x - left * eff)
        self.spanY = math.max(1, top * eff - y)
        self.dragging = true
    end)
    grip:SetScript("OnMouseUp", function(self, button)
        if button ~= "LeftButton" or not self.dragging then return end
        self.dragging = false
        RebornWorldMapResizeDB.scale = WorldMapFrame:GetScale()
    end)
    grip:SetScript("OnUpdate", function(self)
        if not self.dragging then return end
        local x, y = GetCursorPosition()
        local fx = (self.spanX + (x - self.startX)) / self.spanX
        local fy = (self.spanY + (self.startY - y)) / self.spanY
        WorldMapFrame:SetScale(Clamp(self.startScale * math.max(fx, fy)))
    end)
    grip:SetScript("OnClick", function()
        RebornWorldMapResizeDB.scale = 1
        Apply()
    end)
    grip:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("拖动缩放地图 / Drag to resize", 1, 1, 1)
        GameTooltip:AddLine("右键恢复默认大小 / Right-click to reset", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    grip:SetScript("OnLeave", function() GameTooltip:Hide() end)

    WorldMapFrame:HookScript("OnShow", Apply)
    if WorldMap_ToggleSizeDown then hooksecurefunc("WorldMap_ToggleSizeDown", Apply) end
    if WorldMap_ToggleSizeUp then hooksecurefunc("WorldMap_ToggleSizeUp", Apply) end
end

f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function()
    RebornWorldMapResizeDB = RebornWorldMapResizeDB or {}
    if type(RebornWorldMapResizeDB.scale) ~= "number" then
        RebornWorldMapResizeDB.scale = 1
    end
    CreateGrip()
    Apply()
end)
