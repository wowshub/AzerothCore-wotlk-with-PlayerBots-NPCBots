-- RebornDock (插件收藏盒), RebornWOW DOCK1A-1J.
-- A gold-framed box that holds the addon icons the player chooses.
--
-- DOCK1C: every collected icon is shown in our own uniform slot (square, round
-- or tall), drawing a copy of the addon's icon; the addon's own button stays on
-- top of the slot, fully transparent, so clicks, right-clicks, dragging and its
-- tooltip all still belong to that addon. "/rdock add" adds whatever is under
-- the mouse (also icons collect mode does not frame, and unnamed ones, kept by
-- their position under the nearest named parent).
--
-- For addon authors (ours or others), to look right in the dock:
--   * give the launcher button a global name;
--   * optionally set  button.rebornDockIcon = "Interface\\Icons\\..."  (the
--     picture the dock should draw) -- otherwise the dock finds the icon itself.

local DB
local CELL, GAP, PAD, HEADER = 32, 2, 7, 22
local MIN_SCALE, MAX_SCALE = 0.5, 2.0
local RESTORE_SECONDS = 120   -- AIO icons (Heritage Horizons) arrive late
local SHAPES = { "square", "round", "tall" }

local STR = {
    zh = {
        title = "插件收藏盒", collect = "收纳模式",
        collectTip = "点一下进入/退出收纳模式：\n绿框 = 可以收进来（拖进盒子或直接点）\n红框 × = 点一下放回原处；按住拖到别的格子 = 调整顺序",
        empty = "点 ＋ 进入收纳模式，把绿框图标拖进来；\n或鼠标指着图标输入 /rdock add",
        lang = "EN", langTip = "切换语言",
        shape = "外观", shapeTip = "切换图标外观：方形 / 圆形 / 竖长方形",
        square = "方形", round = "圆形", tall = "竖长方形",
        gripTip = "拖动缩放收藏盒（双击恢复）", headerTip = "左键拖动移动收藏盒\n滚轮调整每行个数（当前 %d）",
        added = "已收进：%s", removed = "已放回：%s",
        combat = "战斗中不能调整，请脱战后再试。", reset = "已把所有图标放回原处。",
        nothing = "鼠标下面没有可以收的按钮（技能/宏这类安全动作按钮不能收）。",
        under = "鼠标下：%s（%s）", unnamed = "无名字，按位置记为 %s",
        help = "/rdock 显示或隐藏；/rdock add 收进鼠标下的图标；/rdock what 查看鼠标下的图标；/rdock list 列出已收；/rdock cols 数字；/rdock reset 全部放回",
    },
    en = {
        title = "Addon Dock", collect = "Collect mode",
        collectTip = "Click to enter/leave collect mode:\nGreen frame = can be added (drag into the box, or click)\nRed frame x = click to send it back; drag onto another slot to reorder",
        empty = "Click + for collect mode and drag icons in,\nor point at an icon and type /rdock add",
        lang = "中", langTip = "Switch language",
        shape = "Style", shapeTip = "Icon style: square / round / tall",
        square = "square", round = "round", tall = "tall",
        gripTip = "Drag to scale the dock (double-click resets)", headerTip = "Left-drag to move the dock\nMouse wheel: icons per row (now %d)",
        added = "Added: %s", removed = "Sent back: %s",
        combat = "Not in combat; try again after the fight.", reset = "All icons sent back.",
        nothing = "Nothing collectable under the mouse (secure action buttons such as spells/macros are excluded).",
        under = "Under the mouse: %s (%s)", unnamed = "no name, kept by position as %s",
        help = "/rdock show/hide; /rdock add the icon under the mouse; /rdock what; /rdock list; /rdock cols N; /rdock reset",
    },
}
local function IsZh() return DB and DB.lang == "zh" end
local function T(k) local t = IsZh() and STR.zh or STR.en; return t[k] or STR.en[k] or k end
local function Say(msg) DEFAULT_CHAT_FRAME:AddMessage("|cffd9a638[" .. T("title") .. "]|r " .. msg) end

-- Collect mode never offers these: action bars, unit frames, Blizzard panels,
-- buffs, bags, list rows. ("/rdock add" can still take a non-protected one.)
local BLOCK = { "^ActionButton", "^MultiBar", "^BonusAction", "^Shapeshift", "^PetAction", "^Possess",
    "^MainMenu", "^Character", "^Spellbook", "^Talent", "^Achievement", "^QuestLog", "^Social",
    "^PVP", "^LFD", "^LFR", "^Help", "^Bag", "^Keyring", "^Player", "^Target", "^Focus", "^Party",
    "^Compact", "^Chat", "^GeneralDocking", "^Friends", "^StaticPopup", "^DropDownList", "^Minimap",
    "^MiniMap", "^GameMenu", "^RebornDock", "^Watch", "^Quest", "^Interface", "^Video", "^Audio",
    "^Macro", "^KeyBinding", "^Gossip", "^Merchant", "^Mail", "^Trade", "^Loot", "^Group",
    "^Raid", "^Arena", "^Battlefield", "^Durability", "^Vehicle", "^TimeManager", "^GameTime",
    "^BuffButton", "^DebuffButton", "^TempEnchant", "^ConsolidatedBuff", "^Bagnon", "^ContainerFrame",
    "^Details", "^Skada", "^Recount", "^MBF", "^Totem", "^Rune", "^Stance", "^Aura" }
local DECOR = { "border", "ring", "background", "highlight", "hilight", "glow", "shadow", "mask", "tracking", "flash" }

local owned = {}          -- key -> record

-- DOCK1I: true for buttons driven by secure attributes (action/macro/spell
-- buttons): those are never collected, not even as a shortcut.
local function IsSecureAction(b)
    if not b.GetAttribute then return false end
    for _, a in ipairs({ "type", "*type1", "type1", "*type2", "macrotext", "spell", "action" }) do
        if b:GetAttribute(a) ~= nil then return true end
    end
    return false
end
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
local shapeBtn = SmallButton("□", 22)
shapeBtn:SetPoint("RIGHT", langBtn, "LEFT", -2, 0)

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
Tip(shapeBtn, function() return T("shapeTip") .. "\n" .. T(DB and DB.shape or "square") end)

local header = CreateFrame("Frame", nil, box)
header:SetPoint("TOPLEFT", box, "TOPLEFT", 4, -4)
header:SetPoint("RIGHT", shapeBtn, "LEFT", -2, 0)
header:SetHeight(HEADER - 4)
header:EnableMouse(true)
header:EnableMouseWheel(true)
header:RegisterForDrag("LeftButton")
Tip(header, function() return string.format(T("headerTip"), DB and DB.cols or 8) end)

local grip = CreateFrame("Button", nil, box)
grip:SetSize(14, 14)
grip:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -3, 3)
grip:SetFrameLevel(box:GetFrameLevel() + 30)
grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
Tip(grip, function() return T("gripTip") end)

------------------------------------------------------------------------------
-- Position / scale
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
    self.drag = { left = box:GetLeft() * eff, width = box:GetWidth() }
    self:SetScript("OnUpdate", function(g)
        local cx = GetCursorPosition()
        local s = (cx - g.drag.left) / (g.drag.width * UIParent:GetEffectiveScale())
        if math.abs(s - box:GetScale()) > 0.01 then SetBoxScale(s) end
    end)
end)
grip:SetScript("OnMouseUp", function(self) self:SetScript("OnUpdate", nil); self.drag = nil end)
grip:SetScript("OnDoubleClick", function() SetBoxScale(1) end)

------------------------------------------------------------------------------
-- Keys: a global name, or "@Ancestor/i/j" for an unnamed frame (child indices
-- below the nearest named ancestor).
------------------------------------------------------------------------------
local function KeyOf(f)
    local name = f:GetName()
    if name and name ~= "" then return name end
    local path, cur = {}, f
    while cur and not (cur:GetName() and cur:GetName() ~= "") do
        local parent = cur:GetParent()
        if not parent then return nil end
        local idx
        for i, c in ipairs({ parent:GetChildren() }) do if c == cur then idx = i break end end
        if not idx then return nil end
        table.insert(path, 1, idx)
        cur = parent
    end
    if not cur then return nil end
    return "@" .. cur:GetName() .. "/" .. table.concat(path, "/")
end

local function Resolve(key)
    if key:sub(1, 1) ~= "@" then
        local f = _G[key]
        if type(f) == "table" and f.GetObjectType then return f end
        return nil
    end
    local parts = {}
    for p in key:sub(2):gmatch("[^/]+") do parts[#parts + 1] = p end
    local cur = _G[parts[1]]
    for i = 2, #parts do
        if type(cur) ~= "table" or not cur.GetChildren then return nil end
        cur = select(tonumber(parts[i]) or 0, cur:GetChildren())
    end
    if type(cur) == "table" and cur.GetObjectType then return cur end
end

------------------------------------------------------------------------------
-- Icon picture of a button
------------------------------------------------------------------------------
local function IsDecor(path)
    if type(path) ~= "string" then return false end
    local p = path:lower()
    for _, w in ipairs(DECOR) do if p:find(w, 1, true) then return true end end
    return false
end

-- Returns texture path and its 8 texcoords (or nil).
local function IconOf(btn)
    if type(btn.rebornDockIcon) == "string" then return btn.rebornDockIcon end
    local function from(t)
        if t and t.GetTexture and t:GetTexture() then return t:GetTexture(), { t:GetTexCoord() } end
    end
    local p, c = from(btn.icon or btn.Icon)
    if p then return p, c end
    -- DOCK1D: the button's own picture comes next. Equipment Vault re-skins
    -- micro-menu launchers with a larger dark slot texture from DragonUI's atlas,
    -- which the "largest texture" rule below picked (the icon showed black).
    local nt = btn.GetNormalTexture and btn:GetNormalTexture()
    local np = nt and nt:GetTexture()
    if type(np) == "string" and np ~= "" and not IsDecor(np) then return np, { nt:GetTexCoord() } end
    local best, bestArea, bestIsIcon
    local function consider(r)
        if not (r.GetObjectType and r:GetObjectType() == "Texture") then return end
        local path = r:GetTexture()
        if not path or IsDecor(path) or r:GetDrawLayer() == "HIGHLIGHT" then return end
        local isIcon = type(path) == "string" and path:lower():find("\\icons\\", 1, true) ~= nil
        local area = (r:GetWidth() or 0) * (r:GetHeight() or 0)
        if (isIcon and not bestIsIcon) or ((isIcon == bestIsIcon or (not isIcon and not bestIsIcon)) and area > (bestArea or -1)) then
            best, bestArea, bestIsIcon = r, area, isIcon
        end
    end
    for _, r in ipairs({ btn:GetRegions() }) do consider(r) end
    if not bestIsIcon then
        for _, c in ipairs({ btn:GetChildren() }) do
            for _, r in ipairs({ c:GetRegions() }) do consider(r) end
        end
    end
    p, c = from(best)
    if p then return p, c end
    return from(btn.GetNormalTexture and btn:GetNormalTexture())
end

------------------------------------------------------------------------------
-- Slots: our uniform look
------------------------------------------------------------------------------
local slots = {}
local function SlotSize()
    if DB.shape == "tall" then return 26, 36 end
    return CELL, CELL
end

local function Slot(i)
    local s = slots[i]
    if s then return s end
    s = CreateFrame("Frame", nil, box)
    s:SetFrameLevel(box:GetFrameLevel() + 2)
    s.bg = s:CreateTexture(nil, "BACKGROUND")
    s.bg:SetTexture(0, 0, 0, 0.6)
    s.icon = s:CreateTexture(nil, "ARTWORK")
    s.ring = s:CreateTexture(nil, "OVERLAY")
    -- DOCK1F: dark round disc behind non-portrait pictures in the round style.
    s.disc = s:CreateTexture(nil, "BACKGROUND")
    s.disc:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    s.disc:SetVertexColor(0, 0, 0, 0.85)
    s.disc:Hide()
    s.edge = CreateFrame("Frame", nil, s)
    s.edge:SetAllPoints()
    s.edge:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    s.edge:SetBackdropBorderColor(0.85, 0.65, 0.22, 0.9)
    s.hl = s:CreateTexture(nil, "OVERLAY")
    s.hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    s.hl:SetBlendMode("ADD")
    s.hl:SetAllPoints()
    s.hl:Hide()
    -- DOCK1G: click target for shortcut entries (micro-menu buttons stay in their
    -- bar; clicking here clicks the original).
    s.click = CreateFrame("Button", nil, s)
    s.click:SetAllPoints()
    s.click:SetFrameLevel(box:GetFrameLevel() + 7)
    s.click:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    s.click:SetScript("OnClick", function(self, mouse)
        local o = s.owner
        if o and o.mirror and o.btn and o.btn:IsEnabled() ~= 0 then o.btn:Click(mouse) end
    end)
    s.click:SetScript("OnEnter", function(self)
        local o = s.owner
        s.hl:Show()
        if not o then return end
        local enter = o.btn:GetScript("OnEnter")
        if enter and pcall(enter, o.btn) and GameTooltip:IsShown() then
            GameTooltip:ClearAllPoints()
            GameTooltip:SetPoint("BOTTOM", self, "TOP", 0, 4)
            return
        end
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(o.btn.tooltipText or o.btn:GetName() or "?", 1, 1, 1)
        if o.btn.newbieText then GameTooltip:AddLine(o.btn.newbieText, 1, .82, 0, true) end
        GameTooltip:Show()
    end)
    s.click:SetScript("OnLeave", function()
        s.hl:Hide(); GameTooltip:Hide()
        local o = s.owner
        local leave = o and o.btn:GetScript("OnLeave")
        if leave then pcall(leave, o.btn) end
    end)
    s.click:Hide()
    slots[i] = s
    return s
end

local function PaintSlot(s, o)
    local w, h = SlotSize()
    s:SetSize(w, h)
    local path, coords = IconOf(o.btn)
    local shape = DB.shape or "square"
    local sig = tostring(path) .. shape .. (coords and table.concat(coords, ",") or "")
    if s.sig == sig then return end
    s.sig = sig
    s.icon:ClearAllPoints()
    s.ring:Hide()
    if shape == "round" then
        s.bg:Hide(); s.edge:Hide()
        s.icon:SetPoint("CENTER")
        -- DOCK1F: SetPortraitToTexture ignores texcoords (micro-menu atlases came
        -- out as stripes) and only takes stock icon files (addon pictures came out
        -- blank). Portrait only a plain Interface\Icons\ picture; anything else is
        -- drawn with its own coords, small enough to sit inside the ring, on a disc.
        local isIcon = type(path) == "string" and path:lower():find("\\icons\\", 1, true)
        local plain = not coords or #coords ~= 8 or (coords[1] == 0 and coords[2] == 0 and coords[7] == 1 and coords[8] == 1)
        s.disc:ClearAllPoints(); s.disc:SetPoint("CENTER"); s.disc:SetSize(w * 0.74, h * 0.74); s.disc:Show()
        if isIcon and plain then
            s.icon:SetSize(w * 0.66, h * 0.66)
            SetPortraitToTexture(s.icon, path)
            s.icon:SetTexCoord(0, 1, 0, 1)
        else
            s.icon:SetSize(w * 0.48, h * 0.48)
            s.icon:SetTexture(path or "Interface\\Icons\\INV_Misc_QuestionMark")
            if coords and #coords == 8 then s.icon:SetTexCoord(unpack(coords)) else s.icon:SetTexCoord(0, 1, 0, 1) end
        end
        -- Classic minimap ring: the visible circle fills ~60% of the texture and its
        -- centre sits ~31% in from the top-left corner (the stock 31px button with
        -- its 53px border); size and offset it so the circle lands on the slot.
        s.ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
        s.ring:SetSize(w * 1.7, h * 1.7)
        s.ring:ClearAllPoints()
        s.ring:SetPoint("TOPLEFT", s, "CENTER", -w * 1.7 * 0.31, h * 1.7 * 0.31)
        s.ring:Show()
    else
        s.bg:Show(); s.edge:Show(); s.disc:Hide()
        s.bg:SetAllPoints()
        s.icon:SetPoint("TOPLEFT", 2, -2)
        s.icon:SetPoint("BOTTOMRIGHT", -2, 2)
        s.icon:SetTexture(path or "Interface\\Icons\\INV_Misc_QuestionMark")
        local isIcon = type(path) == "string" and path:lower():find("\\icons\\", 1, true)
        if coords and #coords == 8 and not (coords[1] == 0 and coords[7] == 1 and coords[2] == 0 and coords[8] == 1) then
            s.icon:SetTexCoord(unpack(coords))
        elseif shape == "tall" then
            s.icon:SetTexCoord(0.2, 0.8, 0.08, 0.92)       -- crop the sides to a portrait
        elseif isIcon then
            s.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)     -- trim the stock icon edge
        else
            s.icon:SetTexCoord(0, 1, 0, 1)
        end
    end
end

------------------------------------------------------------------------------
-- Holding buttons
------------------------------------------------------------------------------
local function MBFIgnore(name, add)
    local mbf = _G.MBF
    local list = mbf and mbf.db and mbf.db.profile and mbf.db.profile.MBF_Ignore
    if type(list) ~= "table" or name:sub(1, 1) == "@" then return end
    for i = #list, 1, -1 do
        if list[i] == name then
            if add then return end
            if DB.mbfAdded and DB.mbfAdded[name] then table.remove(list, i); DB.mbfAdded[name] = nil end
            return
        end
    end
    if add then table.insert(list, name); DB.mbfAdded = DB.mbfAdded or {}; DB.mbfAdded[name] = true end
end

-- The button sits on its slot, scaled so its frame fits the slot, invisible.
local function Pin(o)
    local b, s = o.btn, o.slot
    if not s then return end
    pinning = true
    if b:GetParent() ~= box then b:SetParent(box) end
    local w, h = SlotSize()
    local bw, bh = b:GetWidth() or 0, b:GetHeight() or 0
    local sc = (bw > 1 and bh > 1) and math.min(w / bw, h / bh) or 1
    if math.abs(b:GetScale() - sc) > 0.001 then b:SetScale(sc) end
    -- DOCK1E: a tall launcher (micro buttons 28x58, SpellDraft 32x64) scaled to
    -- fit only covers a narrow strip of the slot; widen its click area to the
    -- whole slot (insets are in the button's own units).
    if bw > 1 and bh > 1 then
        local ix = math.max(0, (w / sc - bw) / 2)
        local iy = math.max(0, (h / sc - bh) / 2)
        if o.insetX ~= ix or o.insetY ~= iy then
            b:SetHitRectInsets(-ix, -ix, -iy, -iy)
            o.insetX, o.insetY = ix, iy
        end
    end
    b:SetFrameStrata(box:GetFrameStrata())
    b:SetFrameLevel(box:GetFrameLevel() + 6)
    b:ClearAllPoints()
    b:SetPoint("CENTER", s, "CENTER", 0, 0)
    if not b:IsShown() then b:Show() end
    if b:GetAlpha() ~= 0 then b:SetAlpha(0) end
    pinning = false
end

local function Layout()
    dirty = false
    local cols = DB.cols or 8
    local list = {}
    for _, key in ipairs(DB.items) do
        local o = owned[key]
        if o then list[#list + 1] = o end
    end
    local n = #list
    local w, h = SlotSize()
    local perRow = math.max(1, math.min(cols, math.max(n, 1)))
    local rows = math.max(1, math.ceil(n / cols))
    local bw = PAD * 2 + perRow * w + (perRow - 1) * GAP
    local bh = HEADER + PAD + rows * h + (rows - 1) * GAP + PAD
    if n == 0 then
        hint:SetText(T("empty")); hint:Show()
        bw = math.max(bw, hint:GetStringWidth() + PAD * 2 + 6)
        bh = HEADER + hint:GetStringHeight() + PAD * 2 + 4
    else
        hint:Hide()
    end
    box:SetSize(math.max(bw, title:GetStringWidth() + 96), bh)
    for i, o in ipairs(list) do
        local s = Slot(i)
        local col, row = (i - 1) % cols, math.floor((i - 1) / cols)
        s:ClearAllPoints()
        s:SetPoint("TOPLEFT", box, "TOPLEFT", PAD + col * (w + GAP), -(HEADER + PAD + row * (h + GAP)))
        s.owner = o
        o.slot = s
        PaintSlot(s, o)
        s:Show()
        if o.mirror then s.click:Show() else s.click:Hide(); Pin(o) end
    end
    for i = n + 1, #slots do slots[i]:Hide(); slots[i].owner = nil end
end

local function HookOnce(b)
    if b.rdockHooked then return end
    b.rdockHooked = true
    local function back(self) if self.rdockOwned and not pinning then dirty = true end end
    hooksecurefunc(b, "SetPoint", back)
    hooksecurefunc(b, "SetParent", back)
    hooksecurefunc(b, "SetScale", back)
    hooksecurefunc(b, "SetAlpha", function(self) if self.rdockOwned and not pinning then pinning = true; self:SetAlpha(0); pinning = false end end)
    b:HookScript("OnHide", back)
    b:HookScript("OnEnter", function(self) local o = owned[self.rdockKey or ""]; if o and o.slot then o.slot.hl:Show() end end)
    b:HookScript("OnLeave", function(self) local o = owned[self.rdockKey or ""]; if o and o.slot then o.slot.hl:Hide() end end)
end

-- DOCK1G: a micro-menu button sitting in a bar (CollectionsMicroButton under
-- MainMenuBarArtFrame / DragonUI's micro menu) is not moved: the bar keeps fixed
-- slots and would show a hole. The dock shows a shortcut that clicks it instead.
local function IsBarMicroButton(b)
    local name = b:GetName() or ""
    local parent = b:GetParent()
    return name:find("MicroButton$") ~= nil and parent ~= nil and parent ~= UIParent
end

local function Take(b, key)
    if not key or owned[key] or IsSecureAction(b) then return false end
    local o = { btn = b, key = key, parent = b:GetParent(), oscale = b:GetScale(), alpha = b:GetAlpha(), insets = { b:GetHitRectInsets() },
                strata = b:GetFrameStrata(), level = b:GetFrameLevel(), shown = b:IsShown(), points = {} }
    for i = 1, b:GetNumPoints() do o.points[i] = { b:GetPoint(i) } end
    if IsBarMicroButton(b) or b:IsProtected() then
        o.mirror = true
        -- DOCK1J: a floating shortcut original (not inside a menu bar) is hidden
        -- from the screen: transparent and click-through. Our shortcut still
        -- calls :Click() on it. A bar button keeps its place (no gap).
        o.hideOrig = not IsBarMicroButton(b)
        o.mouse = b:IsMouseEnabled()
        owned[key] = o
        dirty = true
        return true
    end
    owned[key] = o
    b.rdockOwned, b.rdockKey = true, key
    b.DragonUI_CollectorManaged = nil
    HookOnce(b)
    MBFIgnore(key, true)
    dirty = true
    return true
end

local function Release(key)
    local o = owned[key]
    if not o then return end
    local b = o.btn
    owned[key] = nil
    if o.slot then o.slot.hl:Hide(); o.slot.click:Hide() end
    if o.mirror then
        if o.hideOrig and not InCombatLockdown() then
            b:SetAlpha(o.alpha or 1)
            if o.mouse ~= nil then b:EnableMouse(o.mouse and true or false) end
        end
        dirty = true
        return
    end
    b.rdockOwned, b.rdockKey = nil, nil
    pinning = true
    b:SetParent(o.parent or UIParent)
    b:SetScale(o.oscale or 1)
    b:SetAlpha(o.alpha or 1)
    if o.insets and #o.insets == 4 then b:SetHitRectInsets(unpack(o.insets)) end
    b:SetFrameStrata(o.strata or "MEDIUM")
    b:SetFrameLevel(o.level or 1)
    b:ClearAllPoints()
    if #o.points > 0 then
        for _, p in ipairs(o.points) do b:SetPoint(unpack(p)) end
    else
        b:SetPoint("CENTER", UIParent, "CENTER")
    end
    if o.shown == false then b:Hide() end
    pinning = false
    MBFIgnore(key, false)
    dirty = true
end

local function AddKey(key)
    for _, k in ipairs(DB.items) do if k == key then return end end
    table.insert(DB.items, key)
end
local function RemoveKey(key)
    for i = #DB.items, 1, -1 do if DB.items[i] == key then table.remove(DB.items, i) end end
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

local function Blocked(name)
    for _, pat in ipairs(BLOCK) do if name:find(pat) then return true end end
    return false
end

local function Eligible(f)
    if not f or not f.GetObjectType or f == box or f.rdockOwned then return false end
    local name = f:GetName()
    if not name or name == "" then return false end
    local kind = f:GetObjectType()
    if kind ~= "Button" and kind ~= "CheckButton" then return false end
    if not f:IsVisible() or IsSecureAction(f) then return false end
    local w, h = f:GetWidth() * f:GetEffectiveScale(), f:GetHeight() * f:GetEffectiveScale()
    if w < 10 or h < 10 or w > 130 or h > 130 then return false end
    if name:find("%d$") or Blocked(name) then return false end
    return IconOf(f) ~= nil
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
    for _, n in ipairs({ "CustomRacialRadialButton", "DungeonClearMinimapButton", "NetherBotMinimapButton",
                         "SpellDraftMicroButton", "RebornEquipmentVaultMicroButton" }) do
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
        GameTooltip:AddLine(self.targetKey or "?", 1, 1, 1)
        local lines = { strsplit("\n", T("collectTip")) }
        GameTooltip:AddLine(self.inBox and lines[3] or lines[2], 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    o:SetScript("OnLeave", function() GameTooltip:Hide() end)
    overlays[i] = o
    return o
end

local RefreshOverlays -- forward

local function Add(b, key)
    if InCombatLockdown() then Say(T("combat")); return end
    key = key or KeyOf(b)
    if Take(b, key) then AddKey(key); Say(string.format(T("added"), key)) end
    Layout(); RefreshOverlays()
end

local function SendBack(key)
    if InCombatLockdown() then Say(T("combat")); return end
    Release(key); RemoveKey(key); Say(string.format(T("removed"), key))
    Layout(); RefreshOverlays()
end

-- DOCK1H: index (1-based, in DB.items order of the entries that are laid out)
-- of the slot under the cursor, or nil.
local function SlotUnderCursor()
    for i, s in ipairs(slots) do
        if s:IsShown() and s.owner and MouseIsOver(s) then return i end
    end
end

local function MoveKey(key, toSlot)
    -- Slots show only loaded entries; map the target slot to its key, then move
    -- `key` to that key's position in the saved list.
    local target = slots[toSlot] and slots[toSlot].owner and slots[toSlot].owner.key
    if not target or target == key then return false end
    local from, to
    for i, k in ipairs(DB.items) do
        if k == key then from = i end
        if k == target then to = i end
    end
    if not from or not to then return false end
    table.remove(DB.items, from)
    table.insert(DB.items, to, key)
    return true
end

RefreshOverlays = function()
    for _, o in ipairs(overlays) do o:Hide(); o.target = nil end
    if not collecting then return end
    local i = 0
    for _, f in ipairs(Candidates()) do
        i = i + 1
        local o = Overlay(i)
        o.target, o.targetKey, o.inBox = f, f:GetName(), false
        o:ClearAllPoints(); o:SetAllPoints(f)
        o:SetBackdropBorderColor(0.2, 1, 0.3, 1)
        o.mark:SetText("")
        o:SetScript("OnClick", function(self) Add(self.target) end)
        o:SetScript("OnDragStart", function(self)
            ghost.tex:SetTexture((IconOf(self.target)) or "Interface\\Icons\\INV_Misc_QuestionMark")
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
    for _, key in ipairs(DB.items) do
        local ow = owned[key]
        if ow and ow.slot and ow.slot:IsVisible() then
            i = i + 1
            local o = Overlay(i)
            o.target, o.targetKey, o.inBox = ow.btn, key, true
            o:ClearAllPoints(); o:SetAllPoints(ow.slot)
            o:SetBackdropBorderColor(1, 0.25, 0.2, 1)
            o.mark:SetText("|cffff4040×|r")
            o:SetScript("OnClick", function(self) SendBack(self.targetKey) end)
            -- DOCK1H: drag a boxed icon onto another slot to reorder.
            o:SetScript("OnDragStart", function(self)
                local ow2 = owned[self.targetKey]
                ghost.tex:SetTexture((ow2 and IconOf(ow2.btn)) or "Interface\\Icons\\INV_Misc_QuestionMark")
                ghost.tex:SetTexCoord(0, 1, 0, 1)
                ghost:Show()
                self:SetAlpha(0.4)
                ghost:SetScript("OnUpdate", function(g)
                    local x, y = GetCursorPosition(); local sc = UIParent:GetEffectiveScale()
                    g:ClearAllPoints(); g:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / sc, y / sc)
                end)
            end)
            o:SetScript("OnDragStop", function(self)
                ghost:SetScript("OnUpdate", nil); ghost:Hide(); self:SetAlpha(1)
                local to = SlotUnderCursor()
                if to and MoveKey(self.targetKey, to) then Layout(); RefreshOverlays() end
            end)
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
-- Language, shape, columns
------------------------------------------------------------------------------
local SHAPE_MARK = { square = "□", round = "○", tall = "▯" }
local function ApplyLanguage()
    title:SetText(T("title"))
    langBtn:SetText(T("lang"))
    shapeBtn:SetText(SHAPE_MARK[DB.shape] or "□")
    dirty = true
end
langBtn:SetScript("OnClick", function() DB.lang = IsZh() and "en" or "zh"; ApplyLanguage() end)
shapeBtn:SetScript("OnClick", function()
    local idx = 1
    for i, s in ipairs(SHAPES) do if s == DB.shape then idx = i end end
    DB.shape = SHAPES[idx % #SHAPES + 1]
    for _, s in ipairs(slots) do s.sig = nil end
    ApplyLanguage()
    Say(T("shape") .. "：" .. T(DB.shape))
end)

header:SetScript("OnMouseWheel", function(_, delta)
    DB.cols = math.max(1, math.min(16, (DB.cols or 8) + (delta > 0 and 1 or -1)))
    dirty = true
    if GameTooltip:IsOwned(header) then header:GetScript("OnEnter")(header) end
end)

------------------------------------------------------------------------------
-- Startup and upkeep
------------------------------------------------------------------------------
local elapsed, sinceLogin, repaint = 0, 0, 0
local ticker = CreateFrame("Frame")
ticker:SetScript("OnUpdate", function(_, dt)
    if not DB then return end
    elapsed = elapsed + dt
    if elapsed < 0.1 then return end
    sinceLogin = sinceLogin + elapsed
    repaint = repaint + elapsed
    elapsed = 0
    if InCombatLockdown() then return end
    if sinceLogin < RESTORE_SECONDS then
        for _, key in ipairs(DB.items) do
            if not owned[key] then
                local f = Resolve(key)
                if f and not IsSecureAction(f) then Take(f, key) end
            end
        end
    end
    -- Some addons replace SetPoint on the instance (Equipment Vault), so hooks
    -- alone are not enough: verify placement directly.
    if not dirty then
        for _, o in pairs(owned) do
            local b = o.btn
            local _, rel = b:GetPoint(1)
            if not o.mirror and (b:GetParent() ~= box or rel ~= o.slot or not b:IsShown() or b:GetNumPoints() ~= 1) then dirty = true; break end
        end
    end
    for _, o in pairs(owned) do
        if o.hideOrig then
            local b = o.btn
            if b:GetAlpha() > 0 then b:SetAlpha(0) end
            if b:IsMouseEnabled() then b:EnableMouse(false) end
        end
    end
    if dirty then Layout(); if collecting then RefreshOverlays() end end
    -- Icons can change (state colours, swapped pictures): repaint twice a second.
    if repaint >= 0.5 then
        repaint = 0
        for _, s in ipairs(slots) do if s.owner and s:IsShown() then PaintSlot(s, s.owner) end end
    end
end)

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:SetScript("OnEvent", function(_, _, arg1)
    if arg1 ~= "RebornDock" then return end
    RebornDockDB = RebornDockDB or {}
    DB = RebornDockDB
    DB.items = DB.items or {}
    DB.cols = DB.cols or 8
    DB.shape = DB.shape or "square"
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

------------------------------------------------------------------------------
-- Slash commands
------------------------------------------------------------------------------
-- The collectable button under the mouse: the focus or its nearest Button ancestor.
local function UnderMouse()
    local f = GetMouseFocus()
    for _ = 1, 4 do
        if not f or f == WorldFrame or f == UIParent then return nil end
        if f == box or f.owner or f.targetKey then return nil end   -- our own frames
        local kind = f.GetObjectType and f:GetObjectType()
        if (kind == "Button" or kind == "CheckButton") then return f end
        f = f.GetParent and f:GetParent()
    end
end

SLASH_REBORNDOCK1 = "/rdock"
SlashCmdList.REBORNDOCK = function(msg)
    msg = msg or ""
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    cmd = (cmd or ""):lower()
    if cmd == "reset" then
        if InCombatLockdown() then Say(T("combat")); return end
        for _, key in ipairs(DB.items) do Release(key) end
        wipe(DB.items); Layout(); RefreshOverlays(); Say(T("reset"))
    elseif cmd == "cols" and tonumber(arg) then
        DB.cols = math.max(1, math.min(16, math.floor(tonumber(arg)))); dirty = true
    elseif cmd == "add" or cmd == "what" then
        local f = UnderMouse()
        if not f or IsSecureAction(f) then Say(T("nothing")); return end
        local key = KeyOf(f)
        if not key then Say(T("nothing")); return end
        local desc = f:GetName() and f:GetObjectType() or string.format(T("unnamed"), key)
        Say(string.format(T("under"), key, desc))
        if cmd == "add" then Add(f, key) end
    elseif cmd == "list" then
        for i, key in ipairs(DB.items) do
            local o = owned[key]
            local state = o and string.format("icon=%s", tostring((IconOf(o.btn))))
                or (IsZh() and "未加载" or "not loaded")
            Say(i .. ". " .. key .. "  " .. state)
        end
    elseif cmd == "help" then
        Say(T("help"))
    else
        if box:IsShown() then box:Hide(); DB.hidden = true else box:Show(); DB.hidden = false end
    end
end
