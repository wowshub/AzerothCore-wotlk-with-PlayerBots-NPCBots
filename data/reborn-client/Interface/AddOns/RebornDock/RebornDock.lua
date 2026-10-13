-- RebornDock (插件收藏盒), RebornWOW DOCK1A.
-- A gold-framed box that holds the addon icons the player chooses. Click "+" to
-- enter collect mode: every eligible named icon on screen gets a green frame;
-- drag it into the box (or click it) to add it. Icons in the box get a red x in
-- collect mode: click it to send the icon back where it came from. Every icon is
-- scaled to one cell size; the corner grip scales the whole box; the mouse wheel
-- over the header changes the number of columns. Names, order, position, scale
-- and columns are saved (account-wide). Bilingual (中文 / EN).

local DB
local CELL, GAP, PAD, HEADER = 32, 5, 8, 22
local MIN_SCALE, MAX_SCALE = 0.5, 2.0
local RESTORE_SECONDS = 120   -- AIO icons (Heritage Horizons) arrive late

local STR = {
    zh = {
        title = "插件收藏盒", collect = "收纳模式", collectTip = "点一下进入/退出收纳模式：\n绿色框 = 可以收进来（拖进盒子或直接点）\n红色 × = 点一下放回原处",
        empty = "点 ＋ 进入收纳模式，\n把绿框里的图标拖进来", lang = "EN", langTip = "切换语言",
        gripTip = "拖动缩放收藏盒（双击恢复）", headerTip = "左键拖动移动收藏盒\n滚轮调整每行个数（当前 %d）",
        added = "已收进：%s", removed = "已放回：%s", notFound = "（图标 %s 暂未加载，加载后会自动收进来）",
        combat = "战斗中不能调整，请脱战后再试。", reset = "已把所有图标放回原处。",
        help = "/rdock 显示或隐藏收藏盒；/rdock reset 全部放回；/rdock cols 数字 设置每行个数",
    },
    en = {
        title = "Addon Dock", collect = "Collect mode", collectTip = "Click to enter/leave collect mode:\nGreen frame = can be added (drag into the box, or click)\nRed x = click to send it back",
        empty = "Click + for collect mode,\nthen drag icons in", lang = "中", langTip = "Switch language",
        gripTip = "Drag to scale the dock (double-click resets)", headerTip = "Left-drag to move the dock\nMouse wheel: icons per row (now %d)",
        added = "Added: %s", removed = "Sent back: %s", notFound = "(%s is not loaded yet; it is added when it appears)",
        combat = "Not in combat; try again after the fight.", reset = "All icons sent back.",
        help = "/rdock show or hide; /rdock reset send all back; /rdock cols N icons per row",
    },
}
local function IsZh() return DB and DB.lang == "zh" end
local function T(k) local t = IsZh() and STR.zh or STR.en; return t[k] or STR.en[k] or k end
local function Say(msg) DEFAULT_CHAT_FRAME:AddMessage("|cffd9a638[" .. T("title") .. "]|r " .. msg) end

-- Names never offered: action bars, unit frames, Blizzard panels and menus.
local BLOCK = { "^ActionButton", "^MultiBar", "^BonusAction", "^Shapeshift", "^PetAction", "^Possess",
    "^MainMenu", "^Character", "^Spellbook", "^Talent", "^Achievement", "^QuestLog", "^Social",
    "^PVP", "^LFD", "^LFR", "^Help", "^Bag", "^Keyring", "^Player", "^Target", "^Focus", "^Party",
    "^Compact", "^Chat", "^GeneralDocking", "^Friends", "^StaticPopup", "^DropDownList", "^Minimap",
    "^MiniMap", "^GameMenu", "^RebornDock", "^Watch", "^Quest", "^Interface", "^Video", "^Audio",
    "^Macro", "^KeyBinding", "^Gossip", "^Merchant", "^Mail", "^Trade", "^Loot", "^Group",
    "^Raid", "^Arena", "^Battlefield", "^Durability", "^Vehicle", "^TimeManager", "^GameTime" }

local owned, ownedOrder = {}, nil
local pinning = false
local dirty = true

------------------------------------------------------------------------------
-- The box
------------------------------------------------------------------------------
local box = CreateFrame("Frame", "RebornDockFrame", UIParent)
box:SetSize(160, 80)
box:SetFrameStrata("MEDIUM")
box:SetMovable(true)
box:SetClampedToScreen(true)
box:EnableMouse(true)
box:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
box:SetBackdropColor(0.08, 0.08, 0.1, 0.9)
box:SetBackdropBorderColor(0.85, 0.65, 0.22, 1)
box:Hide()

local title = box:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
title:SetPoint("TOPLEFT", box, "TOPLEFT", PAD + 2, -7)
title:SetTextColor(1, 0.82, 0.3)

local hint = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
hint:SetPoint("TOPLEFT", box, "TOPLEFT", PAD + 2, -(HEADER + 6))
hint:SetJustifyH("LEFT")

local function SmallButton(text, w)
    local b = CreateFrame("Button", nil, box, "UIPanelButtonTemplate")
    b:SetSize(w, 16)
    b:SetText(text)
    local fs = b:GetFontString()
    if fs then fs:SetFont(STANDARD_TEXT_FONT, 10) end
    return b
end
local addBtn = SmallButton("+", 20)
addBtn:SetPoint("TOPRIGHT", box, "TOPRIGHT", -6, -5)
local langBtn = SmallButton("EN", 26)
langBtn:SetPoint("RIGHT", addBtn, "LEFT", -2, 0)

local function Tip(frame, textFn)
    frame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(textFn(), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end
Tip(addBtn, function() return T("collect") .. "\n" .. T("collectTip") end)
Tip(langBtn, function() return T("langTip") end)

-- Header strip: drag to move, wheel for columns.
local header = CreateFrame("Frame", nil, box)
header:SetPoint("TOPLEFT", box, "TOPLEFT", 4, -4)
header:SetPoint("RIGHT", langBtn, "LEFT", -2, 0)
header:SetHeight(HEADER - 4)
header:EnableMouse(true)
header:EnableMouseWheel(true)
header:RegisterForDrag("LeftButton")
Tip(header, function() return string.format(T("headerTip"), DB and DB.cols or 8) end)

-- Corner grip: scale the whole box, top-left corner stays put.
local grip = CreateFrame("Button", nil, box)
grip:SetSize(14, 14)
grip:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -3, 3)
grip:SetFrameLevel(box:GetFrameLevel() + 20)
grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
Tip(grip, function() return T("gripTip") end)

------------------------------------------------------------------------------
-- Position / scale (saved as UIParent-unit coordinates of the top-left corner)
------------------------------------------------------------------------------
local function SavePosition()
    local l, t = box:GetLeft(), box:GetTop()
    if not l or not t then return end
    local k = box:GetEffectiveScale() / UIParent:GetEffectiveScale()
    DB.x, DB.y = l * k, t * k
end

local function ApplyPosition()
    local k = UIParent:GetEffectiveScale() / box:GetEffectiveScale()
    box:ClearAllPoints()
    if DB.x and DB.y then
        box:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", DB.x * k, DB.y * k)
    else
        box:SetPoint("TOPLEFT", UIParent, "CENTER", 200 * k, 150 * k)
    end
end

local function SetBoxScale(s)
    if s < MIN_SCALE then s = MIN_SCALE elseif s > MAX_SCALE then s = MAX_SCALE end
    SavePosition()
    box:SetScale(s)
    DB.scale = s
    ApplyPosition()
end

header:SetScript("OnDragStart", function() box:StartMoving() end)
header:SetScript("OnDragStop", function() box:StopMovingOrSizing(); SavePosition(); ApplyPosition() end)

grip:SetScript("OnMouseDown", function(self)
    local eff = box:GetEffectiveScale()
    local left = box:GetLeft() * eff
    local width = box:GetWidth()
    self.drag = { left = left, width = width }
    self:SetScript("OnUpdate", function(g)
        local cx = GetCursorPosition()
        local s = (cx - g.drag.left) / (g.drag.width * UIParent:GetEffectiveScale())
        if math.abs(s - box:GetScale()) > 0.01 then SetBoxScale(s) end
    end)
end)
grip:SetScript("OnMouseUp", function(self) self:SetScript("OnUpdate", nil); self.drag = nil end)
grip:SetScript("OnDoubleClick", function() SetBoxScale(1) end)

------------------------------------------------------------------------------
-- Holding icons
------------------------------------------------------------------------------
local function MBFIgnore(name, add)
    local mbf = _G.MBF
    local list = mbf and mbf.db and mbf.db.profile and mbf.db.profile.MBF_Ignore
    if type(list) ~= "table" then return end
    for i = #list, 1, -1 do
        if list[i] == name then
            if add then return end
            if DB.mbfAdded and DB.mbfAdded[name] then table.remove(list, i); DB.mbfAdded[name] = nil end
            return
        end
    end
    if add then table.insert(list, name); DB.mbfAdded = DB.mbfAdded or {}; DB.mbfAdded[name] = true end
end

local function Layout()
    dirty = false
    local cols = DB.cols or 8
    local shown = {}
    for _, name in ipairs(DB.items) do
        local o = owned[name]
        if o and o.btn:IsShown() then shown[#shown + 1] = o end
    end
    local n = #shown
    local perRow = math.max(1, math.min(cols, math.max(n, 1)))
    local rows = math.max(1, math.ceil(n / cols))
    local w = PAD * 2 + perRow * CELL + (perRow - 1) * GAP
    local h = HEADER + PAD + rows * CELL + (rows - 1) * GAP + PAD
    if n == 0 then
        hint:SetText(T("empty")); hint:Show()
        w = math.max(w, hint:GetStringWidth() + PAD * 2 + 6)
        h = HEADER + hint:GetStringHeight() + PAD * 2 + 4
    else
        hint:Hide()
    end
    box:SetSize(math.max(w, title:GetStringWidth() + 70), h)
    pinning = true
    for i, o in ipairs(shown) do
        local col, row = (i - 1) % cols, math.floor((i - 1) / cols)
        local x = PAD + col * (CELL + GAP) + CELL / 2
        local y = -(HEADER + PAD + row * (CELL + GAP) + CELL / 2)
        local b, s = o.btn, o.scale
        if b:GetParent() ~= box then b:SetParent(box) end
        if b:GetScale() ~= s then b:SetScale(s) end
        b:SetFrameStrata(box:GetFrameStrata())
        b:SetFrameLevel(box:GetFrameLevel() + 3)
        o.px, o.py = x / s, y / s
        b:ClearAllPoints()
        b:SetPoint("CENTER", box, "TOPLEFT", o.px, o.py)
    end
    pinning = false
end

local function HookOnce(btn)
    if btn.rdockHooked then return end
    btn.rdockHooked = true
    -- The owning addon may move, reparent or rescale its icon at any time
    -- (LibDBIcon minimap updates, DragonUI/MBF restores, per-frame position code).
    -- Put it straight back into its cell so it never flickers out of the box.
    local function Pin(self)
        local o = owned[self:GetName() or ""]
        if not self.rdockOwned or pinning or not o then return end
        pinning = true
        if self:GetParent() ~= box then self:SetParent(box) end
        if self:GetScale() ~= o.scale then self:SetScale(o.scale) end
        if o.px then self:ClearAllPoints(); self:SetPoint("CENTER", box, "TOPLEFT", o.px, o.py) end
        pinning = false
    end
    hooksecurefunc(btn, "SetPoint", Pin)
    hooksecurefunc(btn, "SetParent", Pin)
    hooksecurefunc(btn, "SetScale", Pin)
    btn:HookScript("OnShow", function(self) if self.rdockOwned then dirty = true end end)
    btn:HookScript("OnHide", function(self) if self.rdockOwned then dirty = true end end)
end

local function Take(btn)
    local name = btn:GetName()
    if not name or owned[name] or btn:IsProtected() then return false end
    local o = { btn = btn, parent = btn:GetParent(), oscale = btn:GetScale(), strata = btn:GetFrameStrata(),
                level = btn:GetFrameLevel(), points = {} }
    for i = 1, btn:GetNumPoints() do o.points[i] = { btn:GetPoint(i) } end
    local size = math.max(btn:GetWidth() or 0, btn:GetHeight() or 0)
    o.scale = (size > 1) and (CELL / size) or 1
    owned[name] = o
    btn.rdockOwned = true
    btn.DragonUI_CollectorManaged = nil
    HookOnce(btn)
    MBFIgnore(name, true)
    dirty = true
    return true
end

local function Release(name)
    local o = owned[name]
    if not o then return end
    local b = o.btn
    owned[name] = nil
    b.rdockOwned = nil
    pinning = true
    b:SetParent(o.parent or UIParent)
    b:SetScale(o.oscale or 1)
    b:SetFrameStrata(o.strata or "MEDIUM")
    b:SetFrameLevel(o.level or 1)
    b:ClearAllPoints()
    if #o.points > 0 then
        for _, p in ipairs(o.points) do b:SetPoint(unpack(p)) end
    else
        b:SetPoint("CENTER", UIParent, "CENTER")
    end
    pinning = false
    MBFIgnore(name, false)
    dirty = true
end

local function AddName(name)
    for _, n in ipairs(DB.items) do if n == name then return end end
    table.insert(DB.items, name)
end

local function RemoveName(name)
    for i = #DB.items, 1, -1 do if DB.items[i] == name then table.remove(DB.items, i) end end
end

------------------------------------------------------------------------------
-- Collect mode
------------------------------------------------------------------------------
local collecting = false
local overlays = {}
local ghost = CreateFrame("Frame", nil, UIParent)
ghost:SetSize(CELL, CELL)
ghost:SetFrameStrata("TOOLTIP")
ghost.tex = ghost:CreateTexture(nil, "ARTWORK")
ghost.tex:SetAllPoints()
ghost:Hide()

local function IconTexture(btn)
    local t = btn.icon or btn.Icon
    if t and t.GetTexture and t:GetTexture() then return t:GetTexture() end
    local n = btn.GetNormalTexture and btn:GetNormalTexture()
    if n and n:GetTexture() then return n:GetTexture() end
    for _, r in ipairs({ btn:GetRegions() }) do
        if r.GetObjectType and r:GetObjectType() == "Texture" and r:GetTexture() and r:IsShown() then return r:GetTexture() end
    end
end

local function Eligible(f)
    if not f or owned[f:GetName() or ""] then return false end
    local name = f:GetName()
    if not name or name == "" then return false end
    local kind = f:GetObjectType()
    if kind ~= "Button" and kind ~= "CheckButton" then return false end
    if not f:IsVisible() or f:IsProtected() then return false end
    local w, h = f:GetWidth() * f:GetEffectiveScale(), f:GetHeight() * f:GetEffectiveScale()
    if w < 10 or h < 10 or w > 72 or h > 72 then return false end
    for _, pat in ipairs(BLOCK) do if name:find(pat) then return false end end
    return true
end

local function Candidates()
    local found, seen = {}, {}
    local function visit(frame, depth)
        if not frame or not frame.GetChildren or depth > 2 then return end
        for _, c in ipairs({ frame:GetChildren() }) do
            if c ~= box and not seen[c] then
                seen[c] = true
                if Eligible(c) then found[#found + 1] = c
                elseif depth < 2 then visit(c, depth + 1) end
            end
        end
    end
    visit(Minimap, 1)
    if MinimapBackdrop then visit(MinimapBackdrop, 1) end
    visit(UIParent, 1)
    -- The special cases called out by name, wherever they sit.
    for _, n in ipairs({ "CustomRacialRadialButton", "DungeonClearMinimapButton", "NetherBotMinimapButton" }) do
        local f = _G[n]
        if f and not seen[f] and Eligible(f) then found[#found + 1] = f end
    end
    return found
end

local function Overlay(i)
    local o = overlays[i]
    if o then return o end
    o = CreateFrame("Button", nil, UIParent)
    o:SetFrameStrata("TOOLTIP")
    o:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 2 })
    o.mark = o:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    o.mark:SetPoint("TOPRIGHT", o, "TOPRIGHT", 2, 4)
    o:RegisterForClicks("LeftButtonUp")
    o:RegisterForDrag("LeftButton")
    o:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(self.targetName or "?", 1, 1, 1)
        GameTooltip:AddLine(self.inBox and T("collectTip"):match("[^\n]+$") or T("collectTip"):match("\n([^\n]+)\n"), 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    o:SetScript("OnLeave", function() GameTooltip:Hide() end)
    overlays[i] = o
    return o
end

local RefreshOverlays -- forward

local function Add(btn)
    if InCombatLockdown() then Say(T("combat")); return end
    if Take(btn) then AddName(btn:GetName()); Say(string.format(T("added"), btn:GetName())) end
    Layout(); RefreshOverlays()
end

local function SendBack(name)
    if InCombatLockdown() then Say(T("combat")); return end
    Release(name); RemoveName(name); Say(string.format(T("removed"), name))
    Layout(); RefreshOverlays()
end

RefreshOverlays = function()
    for _, o in ipairs(overlays) do o:Hide(); o.target = nil end
    if not collecting then return end
    local i = 0
    for _, f in ipairs(Candidates()) do
        i = i + 1
        local o = Overlay(i)
        o.target, o.targetName, o.inBox = f, f:GetName(), false
        o:ClearAllPoints(); o:SetAllPoints(f)
        o:SetBackdropBorderColor(0.2, 1, 0.3, 1)
        o.mark:SetText("")
        o:SetScript("OnClick", function(self) Add(self.target) end)
        o:SetScript("OnDragStart", function(self)
            ghost.tex:SetTexture(IconTexture(self.target) or "Interface\\Icons\\INV_Misc_QuestionMark")
            ghost:Show()
            ghost:SetScript("OnUpdate", function(g)
                local x, y = GetCursorPosition(); local s = UIParent:GetEffectiveScale()
                g:ClearAllPoints(); g:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / s, y / s)
            end)
        end)
        o:SetScript("OnDragStop", function(self)
            ghost:SetScript("OnUpdate", nil); ghost:Hide()
            if MouseIsOver(box) then Add(self.target) end
        end)
        o:Show()
    end
    for _, name in ipairs(DB.items) do
        local ow = owned[name]
        if ow and ow.btn:IsVisible() then
            i = i + 1
            local o = Overlay(i)
            o.target, o.targetName, o.inBox = ow.btn, name, true
            o:ClearAllPoints(); o:SetAllPoints(ow.btn)
            o:SetBackdropBorderColor(1, 0.25, 0.2, 1)
            o.mark:SetText("|cffff4040×|r")
            o:SetScript("OnClick", function(self) SendBack(self.targetName) end)
            o:SetScript("OnDragStart", nil); o:SetScript("OnDragStop", nil)
            o:Show()
        end
    end
end

local function SetCollecting(on)
    collecting = on
    if on then addBtn:LockHighlight() else addBtn:UnlockHighlight() end
    addBtn:SetText(on and "√" or "+")
    RefreshOverlays()
end
addBtn:SetScript("OnClick", function() SetCollecting(not collecting) end)

------------------------------------------------------------------------------
-- Language, columns
------------------------------------------------------------------------------
local function ApplyLanguage()
    title:SetText(T("title"))
    langBtn:SetText(T("lang"))
    dirty = true
end
langBtn:SetScript("OnClick", function() DB.lang = IsZh() and "en" or "zh"; ApplyLanguage() end)

header:SetScript("OnMouseWheel", function(_, delta)
    DB.cols = math.max(1, math.min(16, (DB.cols or 8) + (delta > 0 and 1 or -1)))
    dirty = true
    if GameTooltip:IsOwned(header) then header:GetScript("OnEnter")(header) end
end)

------------------------------------------------------------------------------
-- Startup and upkeep
------------------------------------------------------------------------------
local elapsed, sinceLogin = 0, 0
local ticker = CreateFrame("Frame")
ticker:SetScript("OnUpdate", function(_, dt)
    if not DB then return end
    elapsed = elapsed + dt
    if elapsed < 0.3 then return end
    sinceLogin = sinceLogin + elapsed
    elapsed = 0
    if not InCombatLockdown() then
        if sinceLogin < RESTORE_SECONDS then
            for _, name in ipairs(DB.items) do
                if not owned[name] then
                    local f = _G[name]
                    if type(f) == "table" and f.GetObjectType and not f:IsProtected() then Take(f) end
                end
            end
        end
        if dirty then Layout(); if collecting then RefreshOverlays() end end
    end
end)

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:SetScript("OnEvent", function(_, event, arg1)
    if arg1 ~= "RebornDock" then return end
    RebornDockDB = RebornDockDB or {}
    DB = RebornDockDB
    DB.items = DB.items or {}
    DB.cols = DB.cols or 8
    if DB.lang == nil then
        local loc = GetLocale and GetLocale() or "enUS"
        DB.lang = (loc == "zhCN" or loc == "zhTW") and "zh" or "en"
    end
    box:SetScale(DB.scale or 1)
    ApplyPosition()
    ApplyLanguage()
    if DB.hidden then box:Hide() else box:Show() end
    dirty = true
end)

SLASH_REBORNDOCK1 = "/rdock"
SlashCmdList.REBORNDOCK = function(msg)
    msg = (msg or ""):lower()
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    if cmd == "reset" then
        if InCombatLockdown() then Say(T("combat")); return end
        for _, name in ipairs(DB.items) do Release(name) end
        wipe(DB.items); Layout(); RefreshOverlays(); Say(T("reset"))
    elseif cmd == "cols" and tonumber(arg) then
        DB.cols = math.max(1, math.min(16, math.floor(tonumber(arg)))); dirty = true
    elseif cmd == "help" then
        Say(T("help"))
    else
        if box:IsShown() then box:Hide(); DB.hidden = true else box:Show(); DB.hidden = false end
    end
end
