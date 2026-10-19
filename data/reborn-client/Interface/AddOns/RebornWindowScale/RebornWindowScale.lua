-- RebornWindowScale (窗口缩放), RebornWOW WSC1A-1E.
-- Adds a corner grip (drag to scale, double-click to reset), Ctrl + mouse wheel
-- scaling, dragging and remembered size/position to addon windows -- without
-- changing those addons. Known windows are listed below; any other window can
-- be added by pointing at it and typing /rwin add. Bilingual.

local DB
local MIN_SCALE, MAX_SCALE = 0.4, 2.0

-- Main windows and their sub-windows (popups that are separate frames).
local KNOWN = {
    "RebornEquipmentVaultFrame",          -- 共享搭配衣柜
    "RebornSpectatorRosterFrame",         -- 旁观中心
    "NPCBotsRTSFrame", "NPCBotsRTSHelpFrame",
    "GObjectEditorUIFrame",
    "DungeonClearFrame",                  -- 副本自动清理
    "RebornWDSpecHome", "RebornWDTreePreview",
    "SpellDraftBookFrame", "SpellDraftMysticOverviewFrame", "SpellDraftMysticConfirmFrame",
    "SpellDraftPrestigeShopFrame", "SpellDraftTalentRefundDialog",
}
-- Windows that already scale themselves (RebornTalentGuide has its own grip).
-- WSC1F: DungeonClearFrame is the centre of DungeonClear's five-column panel, which has
-- its own scale triangle at the panel's corner (DCUI3B5); two scalers would fight.
local SKIP = { RebornTalentGuideFrame = true, RebornDockFrame = true, DungeonClearFrame = true }

-- WSC1B: popups of these addons are picked up automatically -- any named panel
-- that is a direct child of UIParent and starts with one of these prefixes
-- (DungeonClear's test / queue / GPS / bot-detail windows, EV, SpellDraft, ...),
-- so new popups need no list update.
local PREFIXES = { "DungeonClear", "RebornEquipmentVault", "RebornEV", "RebornSpectator", "NPCBotsRTS",
                   "GObjectEditor", "RebornWD", "SpellDraft" }
-- Not windows: menus, option panels, buttons, overlays.
local NOT_A_WINDOW = { "Menu$", "OptionsPanel$", "Button$", "Tooltip", "Blocker$", "Flash$", "HUD$", "_CD$", "Hit$" }
local MIN_W, MIN_H = 160, 100

-- WSC1B: closing a main window must not close the sub-windows the player has
-- open. Dialogs that belong to an operation in the main window still close.
local KEEP_CLOSING = { "Confirm", "Dialog", "Blocker", "Refund" }
local function KeepsOpen(name)
    for _, w in ipairs(KEEP_CLOSING) do if name:find(w) then return false end end
    return true
end
local cascade = 0                    -- >0 while a managed window runs its OnHide
local reopen = {}                    -- frames to show again next frame
local reopener = CreateFrame("Frame")
reopener:Hide()
reopener:SetScript("OnUpdate", function(self)
    self:Hide()
    -- Protected windows may not be shown from addon code in combat: skip them then.
    for f in pairs(reopen) do if not f:IsShown() and not (InCombatLockdown() and f:IsProtected()) then f:Show() end end
    wipe(reopen)
end)

-- WSC1C: page views that fill a managed window and hide its corner grip.
-- view name -> window it belongs to.
local VIEWS = {
    SpellDraftMysticCatalogView = "SpellDraftBookFrame",        -- 神秘附魔 page of the SpellDraft book
    SpellDraftGlyphCollectionBookView = "SpellDraftBookFrame",  -- 雕纹收藏 page (server AIO UI)
}
-- WSC1E: grip inset for windows whose art sits inside a larger frame
-- (the SpellDraft parchment is drawn 18 px inside SpellDraftBookFrame).
local GRIP_INSET = { SpellDraftBookFrame = 21 }
local viewGrips = {}       -- owner name -> { [view frame] = grip }

-- One grip per window: the topmost shown page's grip, else the window's own.
local GetDecorated   -- set below, once `decorated` exists
local function UpdateGrips(owner)
    local d = GetDecorated and GetDecorated(owner)
    local list = viewGrips[owner]
    if not list then return end
    local top, topLevel
    for v in pairs(list) do
        if v:IsVisible() and (not topLevel or v:GetFrameLevel() > topLevel) then top, topLevel = v, v:GetFrameLevel() end
    end
    for v, g in pairs(list) do if v == top then g:Show() else g:Hide() end end
    if d and d.grip then if top then d.grip:Hide() else d.grip:Show() end end
end
local viewDone = {}
local AddViewGrip

local function LooksLikeWindow(f, name)
    local prefixed = false
    for _, p in ipairs(PREFIXES) do if name:sub(1, #p) == p then prefixed = true; break end end
    if not prefixed then return false end
    for _, pat in ipairs(NOT_A_WINDOW) do if name:find(pat) then return false end end
    if f:GetObjectType() ~= "Frame" then return false end
    local w, h = f:GetWidth() or 0, f:GetHeight() or 0
    return w >= MIN_W and h >= MIN_H
end

local STR = {
    zh = {
        title = "窗口缩放",
        grip = "拖动：缩放窗口\n双击：恢复原大小\nCtrl+滚轮：也可缩放\n拖动窗口空白处：移动（位置会记住）",
        added = "已加入：%s（右下角出现缩放小三角）", removed = "已移除：%s（下次重载后恢复原样）",
        nothing = "鼠标下面没有可以加入的窗口（需要有名字的窗口）。", reset = "已恢复 %s 的大小和位置。",
        list = "已管理的窗口：", help = "/rwin add 加入鼠标下的窗口；/rwin remove 移除；/rwin reset 恢复鼠标下窗口；/rwin list 列表",
    },
    en = {
        title = "Window Scale",
        grip = "Drag: scale the window\nDouble-click: original size\nCtrl+wheel: scale too\nDrag the window background: move (remembered)",
        added = "Added: %s (a scale grip appears in its corner)", removed = "Removed: %s (back to normal after /reload)",
        nothing = "No window under the mouse to add (it needs a name).", reset = "Reset size and position of %s.",
        list = "Managed windows:", help = "/rwin add the window under the mouse; /rwin remove; /rwin reset; /rwin list",
    },
}
local function T(k)
    local zh = DB and DB.lang == "zh"
    if DB and DB.lang == nil then zh = (GetLocale() == "zhCN" or GetLocale() == "zhTW") end
    return (zh and STR.zh or STR.en)[k] or k
end
local function Say(m) DEFAULT_CHAT_FRAME:AddMessage("|cffd9a638[" .. T("title") .. "]|r " .. m) end

local decorated = {}      -- name -> { frame, native = scale before ours }
GetDecorated = function(name) return decorated[name] end

local function Entry(name)
    DB.frames[name] = DB.frames[name] or {}
    return DB.frames[name]
end

-- Keep the top-left corner on the same screen spot while the scale changes.
local pendingApply = {}               -- windows to re-apply after combat
local function Locked(f) return InCombatLockdown() and f:IsProtected() end

local function SetScaleKeepCorner(f, s)
    if Locked(f) then return end
    if s < MIN_SCALE then s = MIN_SCALE elseif s > MAX_SCALE then s = MAX_SCALE end
    local l, t = f:GetLeft(), f:GetTop()
    local eff = f:GetEffectiveScale()
    f:SetScale(s)
    if l and t then
        local k = eff / f:GetEffectiveScale()
        f:ClearAllPoints()
        f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", l * k, t * k)
    end
end

local function SavePlace(name, f)
    local l, t = f:GetLeft(), f:GetTop()
    if not l or not t then return end
    local e = Entry(name)
    local k = f:GetEffectiveScale() / UIParent:GetEffectiveScale()
    e.x, e.y = l * k, t * k            -- top-left, in UIParent units
    e.scale = f:GetScale()
end

local function ApplySaved(name, f)
    local e = DB.frames[name]
    if not e then return end
    if Locked(f) then pendingApply[name] = f; return end
    if e.scale then f:SetScale(e.scale) end
    if e.x and e.y then
        local k = UIParent:GetEffectiveScale() / f:GetEffectiveScale()
        f:ClearAllPoints()
        f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", e.x * k, e.y * k)
    end
end

local function Decorate(name, f)
    if decorated[name] then return end
    local d = { frame = f, native = f:GetScale() }
    decorated[name] = d
    f:SetClampedToScreen(true)

    -- Corner grip.
    local grip = CreateFrame("Button", nil, f)
    d.grip = grip
    grip:SetSize(16, 16)
    local inset = GRIP_INSET[name] or 3
    grip:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -inset, inset)
    grip:SetFrameStrata(f:GetFrameStrata())
    grip:SetFrameLevel(f:GetFrameLevel() + 60)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT"); GameTooltip:AddLine(T("title"), 1, .82, .3)
        GameTooltip:AddLine(T("grip"), 1, 1, 1, true); GameTooltip:Show()
    end)
    grip:SetScript("OnLeave", function() GameTooltip:Hide() end)
    grip:SetScript("OnMouseDown", function(self)
        local eff = f:GetEffectiveScale()
        self.drag = { left = f:GetLeft() * eff, width = f:GetWidth() }
        self:SetScript("OnUpdate", function(g)
            local cx = GetCursorPosition()
            local s = (cx - g.drag.left) / (g.drag.width * UIParent:GetEffectiveScale())
            if math.abs(s - f:GetScale()) > 0.005 then SetScaleKeepCorner(f, s) end
        end)
    end)
    grip:SetScript("OnMouseUp", function(self) self:SetScript("OnUpdate", nil); self.drag = nil; SavePlace(name, f) end)
    grip:SetScript("OnDoubleClick", function()
        SetScaleKeepCorner(f, d.native or 1)
        local e = Entry(name); e.scale = nil
    end)

    -- Ctrl + mouse wheel over the window background.
    if not f:IsMouseWheelEnabled() then f:EnableMouseWheel(true) end
    f:HookScript("OnMouseWheel", function(self, delta)
        if IsControlKeyDown() then
            SetScaleKeepCorner(self, self:GetScale() + (delta > 0 and 0.05 or -0.05)); SavePlace(name, self)
        end
    end)

    -- Dragging: add it only when the window has none of its own.
    if not f:GetScript("OnDragStart") then
        f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function(self) self:StartMoving() end)
        f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); SavePlace(name, self) end)
    else
        f:SetMovable(true)
        f:HookScript("OnDragStop", function(self) SavePlace(name, self) end)
    end

    -- WSC1B: a sub-window hanging off another frame would vanish with it; move
    -- it to UIParent, keeping its place on screen.
    local parent = f:GetParent()
    if parent and parent ~= UIParent and KeepsOpen(name) and f:GetObjectType() == "Frame" and not f:IsProtected() then
        local l, t = f:GetLeft(), f:GetTop()
        local eff = f:GetEffectiveScale()
        f:SetParent(UIParent)
        if l and t then
            local k = eff / f:GetEffectiveScale()
            f:ClearAllPoints(); f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", l * k, t * k)
        end
    end
    -- Mark hides that happen inside this window's own OnHide (cascaded closes).
    local own = f:GetScript("OnHide")
    f:SetScript("OnHide", function(...)
        cascade = cascade + 1
        if own then pcall(own, ...) end
        cascade = cascade - 1
    end)
    f:HookScript("OnHide", function(self)
        if cascade > 0 and KeepsOpen(name) then reopen[self] = true; reopener:Show() end
    end)

    -- Re-apply after the addon shows (some reset their own scale each time they open).
    f:HookScript("OnShow", function(self)
        local e = DB.frames[name]
        if not (e and e.scale) then d.native = self:GetScale() end
        ApplySaved(name, self)
    end)
    ApplySaved(name, f)
end

AddViewGrip = function(view, v, owner, f)
    local grip = CreateFrame("Button", nil, v)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", v, "BOTTOMRIGHT", -3, 3)
    viewGrips[owner] = viewGrips[owner] or {}
    viewGrips[owner][v] = grip
    v:HookScript("OnShow", function() UpdateGrips(owner) end)
    v:HookScript("OnHide", function() UpdateGrips(owner) end)
    grip:SetFrameStrata(v:GetFrameStrata())
    grip:SetFrameLevel(v:GetFrameLevel() + 60)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT"); GameTooltip:AddLine(T("title"), 1, .82, .3)
        GameTooltip:AddLine(T("grip"), 1, 1, 1, true); GameTooltip:Show()
    end)
    grip:SetScript("OnLeave", function() GameTooltip:Hide() end)
    grip:SetScript("OnMouseDown", function(self)
        -- Width of the view on screen tracks the cursor; scale the owner window.
        local eff = v:GetEffectiveScale()
        self.drag = { left = v:GetLeft() * eff, width = v:GetWidth() * v:GetScale() / 1 }
        self:SetScript("OnUpdate", function(g)
            local cx = GetCursorPosition()
            local inner = v:GetEffectiveScale() / f:GetEffectiveScale()   -- view scale relative to owner
            local s = (cx - g.drag.left) / (v:GetWidth() * inner * UIParent:GetEffectiveScale())
            if math.abs(s - f:GetScale()) > 0.005 then SetScaleKeepCorner(f, s) end
        end)
    end)
    grip:SetScript("OnMouseUp", function(self) self:SetScript("OnUpdate", nil); self.drag = nil; SavePlace(owner, f) end)
    grip:SetScript("OnDoubleClick", function()
        local d = decorated[owner]
        SetScaleKeepCorner(f, d and d.native or 1)
        local e = Entry(owner); e.scale = nil
    end)
    if not v:IsMouseWheelEnabled() then v:EnableMouseWheel(true) end
    v:HookScript("OnMouseWheel", function(_, delta)
        if IsControlKeyDown() then
            SetScaleKeepCorner(f, f:GetScale() + (delta > 0 and 0.05 or -0.05)); SavePlace(owner, f)
        end
    end)
end

local function Names()
    local list, seen = {}, {}
    for _, n in ipairs(KNOWN) do if not seen[n] then seen[n] = true; list[#list + 1] = n end end
    for n in pairs(DB.added) do if not seen[n] then seen[n] = true; list[#list + 1] = n end end
    return list
end

-- Windows are often created on first open: keep looking.
local waiter = CreateFrame("Frame")
local acc, scanTick = 0, 0
waiter:SetScript("OnUpdate", function(_, dt)
    if not DB then return end
    acc = acc + dt
    if acc < 1 then return end
    acc = 0
    for _, n in ipairs(Names()) do
        if not decorated[n] and not SKIP[n] and not DB.removed[n] then
            local f = _G[n]
            if type(f) == "table" and f.GetObjectType and f.SetScale and not InCombatLockdown() then Decorate(n, f) end
        end
    end
    for view, owner in pairs(VIEWS) do
        local v, d = _G[view], decorated[owner]
        if not viewDone[view] and type(v) == "table" and v.GetObjectType and d then
            viewDone[view] = true
            AddViewGrip(view, v, owner, d.frame)
            UpdateGrips(owner)
        end
    end
    for owner in pairs(viewGrips) do UpdateGrips(owner) end
    -- WSC1B: automatic pick-up of these addons' popups (every 2 s).
    scanTick = (scanTick or 0) + 1
    if scanTick % 2 == 0 then
        for _, c in ipairs({ UIParent:GetChildren() }) do
            local n = c.GetName and c:GetName()
            if n and not decorated[n] and not SKIP[n] and not DB.removed[n] and not InCombatLockdown()
               and LooksLikeWindow(c, n) then
                Decorate(n, c)
            end
        end
    end
end)

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")
ev:SetScript("OnEvent", function(_, event, arg1)
    if event == "PLAYER_REGEN_ENABLED" then
        for n, f in pairs(pendingApply) do ApplySaved(n, f) end
        wipe(pendingApply)
        return
    end
    if arg1 ~= "RebornWindowScale" then return end
    RebornWindowScaleDB = RebornWindowScaleDB or {}
    DB = RebornWindowScaleDB
    DB.frames = DB.frames or {}
    DB.added = DB.added or {}
    DB.removed = DB.removed or {}
    if DB.lang == nil then DB.lang = (GetLocale() == "zhCN" or GetLocale() == "zhTW") and "zh" or "en" end
end)

-- The named top-level window under the mouse (walk up to a child of UIParent).
local function WindowUnderMouse()
    local f = GetMouseFocus()
    local best
    while f and f ~= UIParent and f ~= WorldFrame do
        if f.GetName and f:GetName() and f:GetName() ~= "" and f.SetScale then best = f end
        local p = f:GetParent()
        if p == UIParent then break end
        f = p
    end
    return best
end

SLASH_REBORNWINDOWSCALE1 = "/rwin"
SlashCmdList.REBORNWINDOWSCALE = function(msg)
    local cmd = ((msg or ""):match("^(%S*)") or ""):lower()
    if cmd == "add" then
        local f = WindowUnderMouse()
        if not f or InCombatLockdown() then Say(T("nothing")); return end
        local n = f:GetName()
        DB.added[n] = true; DB.removed[n] = nil
        Decorate(n, f); Say(string.format(T("added"), n))
    elseif cmd == "remove" then
        local f = WindowUnderMouse(); local n = f and f:GetName()
        if not n then Say(T("nothing")); return end
        DB.added[n] = nil; DB.removed[n] = true; DB.frames[n] = nil
        local d = decorated[n]
        if d and d.grip then d.grip:Hide() end
        Say(string.format(T("removed"), n))
    elseif cmd == "reset" then
        local f = WindowUnderMouse(); local n = f and f:GetName()
        if not n then Say(T("nothing")); return end
        DB.frames[n] = nil
        local d = decorated[n]
        if d then f:SetScale(d.native or 1); f:ClearAllPoints(); f:SetPoint("CENTER") end
        Say(string.format(T("reset"), n))
    elseif cmd == "list" then
        Say(T("list"))
        for _, n in ipairs(Names()) do
            local e = DB.frames[n]
            Say(string.format("  %s%s  %s", n, decorated[n] and "" or " (-)",
                e and e.scale and string.format("x%.2f", e.scale) or ""))
        end
    else
        Say(T("help"))
    end
end
