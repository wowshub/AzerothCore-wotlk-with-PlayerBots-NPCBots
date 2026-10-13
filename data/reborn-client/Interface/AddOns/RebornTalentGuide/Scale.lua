-- RebornWOW TGS1A/TGL1A: scale the talent guide window (RebornTalentGuideFrame).
-- A corner grip at the bottom-right scales the whole window (0.45x-1.2x,
-- top-left corner stays put); double-click it to go back to the original
-- fit-to-screen size; Ctrl + mouse wheel over the window does the same in
-- steps. The scale is saved (RebornTGScaleDB). UI.lua is not changed: this
-- file waits for the window to be created and decorates it.

local MIN_SCALE, MAX_SCALE = 0.45, 1.2

local function FitScale()
    -- Same formula UI.lua uses when it creates the window (TGL1A: 1220x680).
    local L = RebornTalentGuide and RebornTalentGuide.layout
    local w, h = (L and L.W) or 1220, (L and L.H) or 680
    return math.min(1, (UIParent:GetWidth() - 24) / w, (UIParent:GetHeight() - 24) / h)
end

local function Clamp(s)
    if s < MIN_SCALE then return MIN_SCALE elseif s > MAX_SCALE then return MAX_SCALE end
    return s
end

-- Change the scale while keeping the window's top-left corner on the same
-- screen spot (UI.lua anchors it CENTER; StartMoving may leave any anchor).
local function SetScaleKeepCorner(f, s)
    s = Clamp(s)
    local l, t = f:GetLeft(), f:GetTop()
    local eff = f:GetEffectiveScale()
    f:SetScale(s)
    RebornTGScaleDB = RebornTGScaleDB or {}
    RebornTGScaleDB.scale = s
    if not l or not t then return end
    local neff = f:GetEffectiveScale()
    f:ClearAllPoints()
    f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", l * eff / neff, t * eff / neff)
end

local function Decorate(f)
    if f.rebornScaleGrip then return end

    local grip = CreateFrame("Button", nil, f)
    f.rebornScaleGrip = grip
    grip:SetSize(18, 18)
    grip:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -6, 6)
    grip:SetFrameLevel(f:GetFrameLevel() + 40)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:AddLine("拖动缩放窗口 / Drag to resize", 1, 1, 1)
        GameTooltip:AddLine("双击恢复原大小；Ctrl+滚轮也可缩放\nDouble-click: original size. Ctrl+wheel also scales.", .8, .8, .8, true)
        GameTooltip:Show()
    end)
    grip:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Scale follows the cursor: the window's width on screen tracks the
    -- distance from its left edge to the cursor.
    grip:SetScript("OnMouseDown", function(self)
        local eff = f:GetEffectiveScale()
        self.drag = { left = f:GetLeft() * eff, width = f:GetWidth() }
        self:SetScript("OnUpdate", function(g)
            local cx = GetCursorPosition()
            local s = (cx - g.drag.left) / (g.drag.width * UIParent:GetEffectiveScale())
            if math.abs(Clamp(s) - f:GetScale()) > 0.005 then SetScaleKeepCorner(f, s) end
        end)
    end)
    grip:SetScript("OnMouseUp", function(self) self:SetScript("OnUpdate", nil); self.drag = nil end)
    grip:SetScript("OnDoubleClick", function()
        SetScaleKeepCorner(f, FitScale())
        RebornTGScaleDB.scale = nil   -- back to "follow the screen" like the original
    end)

    f:EnableMouseWheel(true)
    f:HookScript("OnMouseWheel", function(self, delta)
        if IsControlKeyDown() then SetScaleKeepCorner(self, self:GetScale() + (delta > 0 and 0.05 or -0.05)) end
    end)

    local saved = RebornTGScaleDB and tonumber(RebornTGScaleDB.scale)
    if saved then SetScaleKeepCorner(f, saved) end
end

-- The window is created lazily (G.Create on first open): wait for it.
local waiter = CreateFrame("Frame")
waiter:SetScript("OnUpdate", function(self)
    local f = _G.RebornTalentGuideFrame
    if f then
        Decorate(f)
        self:SetScript("OnUpdate", nil)
    end
end)
