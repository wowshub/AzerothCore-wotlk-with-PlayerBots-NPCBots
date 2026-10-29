-- =========================================================================
-- RebornTreasure GM 面板 (TREAS2B)
-- 三栏: 左 = 宝箱种类, 中 = 选中的宝箱 (外观/设置; 掉落表在 TREAS2C), 右 = 物品库 (TREAS2C)
-- 和服务端的对话: 发 ".treasure ui ..." (只有 GM 能执行), 收前缀 "TR" 的插件消息
-- 打开: /rtgm, 或寻宝指南面板标题旁的 GM 按钮
-- =========================================================================

local ADDON_PREFIX = "TR"
local PANEL_VERSION = "1.5.0"   -- shown in the title bar, so a stale copy of this file is easy to spot
-- the panel speaks Chinese unless the GM switched to English (the 中文/EN button in the title bar);
-- with no choice saved it follows the DungeonClear panel's language, else Chinese
local function IsZh()
    local db = RebornTreasureDB
    if db and db.lang then return db.lang == "zh" end
    if DungeonClearDB and DungeonClearDB.lang then return DungeonClearDB.lang == "zh" end
    return true
end

-- short labels; tooltips always show both languages
local function T(zh, en) return IsZh() and zh or en end

-- text that is set once and must follow the language switch
local binds = {}
local function Bind(obj, zh, en)
    binds[#binds + 1] = { obj = obj, zh = zh, en = en }
    obj:SetText(T(zh, en))
end
local function BindFn(obj, fn)
    binds[#binds + 1] = { obj = obj, fn = fn }
    obj:SetText(fn())
end

local RARITY = {
    [1] = { r = 0.12, g = 1.00, b = 0.00, hex = "1eff00", zh = "普通", en = "Common" },
    [2] = { r = 0.00, g = 0.44, b = 0.87, hex = "0070dd", zh = "稀有", en = "Rare" },
    [3] = { r = 0.64, g = 0.21, b = 0.93, hex = "a335ee", zh = "史诗", en = "Epic" },
}
local DEFAULT_ICON = {
    [1] = "Interface\\Icons\\INV_Box_01",
    [2] = "Interface\\Icons\\INV_Box_02",
    [3] = "Interface\\Icons\\INV_Box_04",
}

local state = {
    types = {},        -- entry -> type
    order = {},        -- entries, sorted
    models = {},       -- entry -> model path
    looks = {},        -- { {id, model, name}, ... }
    selected = nil,
    pendingSelect = nil,
    listOffset = 0,
    lookOffset = 0,
    online = false,
    drafts = {},       -- entry -> { field = text } typed but not saved yet
    spawns = {},       -- TREAS2C: every chest spawn of the world, as the server last listed them
    spawnCount = {},   -- entry -> how many spawns the type has
    clues = {},        -- spawn id -> clue text
    spawnScope = "type",
    spawnSel = nil,
    spawnOffset = 0,
    loot = { entry = 0, items = {}, offset = 0, ready = false },
    lootByType = {},   -- entry -> { { item, chance, min, max, group, q, icon, name, zh }, ... } (TREAS2D)
    lootAsked = {},    -- entry -> true once `loot <entry>` was sent
    lootNew = {},
    lootWork = {},     -- entry -> the working copy of the loot table (a draft until Save)
    questTitle = {},   -- quest id -> { en, zh } (TREAS3A)
    titleAsked = {},
    lootRow = 0,
    pool = { cat = "all", page = 0, text = "", items = {}, more = false },
    poolOffset = 0,
    iconsByCat = {},   -- category -> { { name = "INV_Box_01" }, ... } from the server
    iconCat = "chest",
    iconRow = 0,
}

local ui = {}

-- item quality: r, g, b, hex
local RARITY_Q = {
    [0] = { 0.62, 0.62, 0.62, "9d9d9d" }, [1] = { 1, 1, 1, "ffffff" }, [2] = { 0.12, 1, 0, "1eff00" },
    [3] = { 0, 0.44, 0.87, "0070dd" }, [4] = { 0.64, 0.21, 0.93, "a335ee" }, [5] = { 1, 0.5, 0, "ff8000" },
    [6] = { 0.9, 0.8, 0.5, "e6cc80" },
}

-- =========================================================================
-- helpers
-- =========================================================================
local function Cmd(text)
    SendChatMessage(".treasure ui " .. text, "SAY")
end

local function Split(msg)
    local out = {}
    for field in string.gmatch(msg .. "\t", "([^\t]*)\t") do
        out[#out + 1] = field
    end
    return out
end

local function CleanText(s)
    s = tostring(s or "")
    s = s:gsub("|", ""):gsub("[\r\n\t]", " ")
    return s
end

local function Money(copper)
    copper = tonumber(copper) or 0
    if GetCoinTextureString then
        local ok, text = pcall(GetCoinTextureString, copper, 12)
        if ok and text then return text end
    end
    return string.format("%.2f%s", copper / 10000, T("金", "g"))
end

local function GoldShort(copper)
    local g = (tonumber(copper) or 0) / 10000
    if g >= 1 then return string.format("%d", math.floor(g + 0.5)) end
    return string.format("%.2f", g)
end

-- icons saved by the TREAS2A SQL lost their backslashes ("InterfaceIconsINV_Box_01"); put them back
local function IconPath(icon, rarity)
    icon = icon or ""
    if icon ~= "" and not icon:find("\\", 1, true) then
        icon = "Interface\\Icons\\" .. (icon:match("^[Ii]nterface[Ii]cons(.+)$") or icon)
    end
    if icon == "" then icon = DEFAULT_ICON[rarity] or DEFAULT_ICON[1] end
    return icon
end

-- a PlayerModel frame takes the DBC path as it is (like GObjectEditorUI); .m2 is the fallback
function ui.ShowModel(model, path)
    if not path or path == "" then return false end
    local tries = { path, (path:gsub("%.[mM][dD][xXlL]$", ".m2")) }
    for _, p in ipairs(tries) do
        if pcall(model.SetModel, model, p) then
            pcall(model.SetCamDistanceScale, model, 1.0)
            pcall(model.SetPosition, model, 0, 0, 0)
            pcall(model.SetModelScale, model, model.zoom or 1)
            pcall(model.SetFacing, model, model.facing or 0.6)
            return true
        end
    end
    return false
end

local function Status(text, isError)
    if not ui.status then return end
    ui.status:SetText(text or "")
    if isError then
        ui.status:SetTextColor(1, 0.25, 0.25)
    else
        ui.status:SetTextColor(0.4, 1, 0.4)
    end
end

local function Tip(owner, zh, en, extra)
    owner:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(zh, 1, 0.82, 0)
        GameTooltip:AddLine(en, 0.7, 0.7, 0.7)
        if extra then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(extra, 0.9, 0.9, 0.9, true)
        end
        GameTooltip:Show()
    end)
    owner:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-- a square icon button with a coloured rim (the panel's "button with colour" style)
local function IconButton(parent, size, icon, r, g, b)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(size, size)
    local rim = btn:CreateTexture(nil, "BACKGROUND")
    rim:SetPoint("TOPLEFT", -2, 2)
    rim:SetPoint("BOTTOMRIGHT", 2, -2)
    rim:SetTexture(r, g, b, 0.9)
    btn.rim = rim
    local tex = btn:CreateTexture(nil, "ARTWORK")
    tex:SetAllPoints()
    tex:SetTexture(icon)
    tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    btn.icon = tex
    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    hl:SetBlendMode("ADD")
    btn:SetScript("OnMouseDown", function(self) self.icon:SetPoint("TOPLEFT", 1, -1); self.icon:SetPoint("BOTTOMRIGHT", 1, -1) end)
    btn:SetScript("OnMouseUp", function(self) self.icon:ClearAllPoints(); self.icon:SetAllPoints() end)
    return btn
end

local function Panel(parent)
    local f = CreateFrame("Frame", nil, parent)
    f:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    f:SetBackdropColor(0.08, 0.06, 0.03, 0.85)
    f:SetBackdropBorderColor(0.8, 0.62, 0.25, 1)
    return f
end

local function Header(parent, icon, zh, en)
    local tex = parent:CreateTexture(nil, "OVERLAY")
    tex:SetSize(20, 20)
    tex:SetPoint("TOPLEFT", 8, -7)
    tex:SetTexture(icon)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("LEFT", tex, "RIGHT", 6, 0)
    Bind(fs, zh, en)
    return fs
end

local function EditField(parent, width, numeric)
    local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    eb:SetSize(width, 20)
    eb:SetAutoFocus(false)
    eb:SetFontObject("ChatFontNormal")
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    if numeric then eb:SetMaxLetters(10) else eb:SetMaxLetters(60) end
    return eb
end

-- the 3.3.5 client has no Show-by-flag method on regions
local function ShowIf(obj, cond)
    if cond then obj:Show() else obj:Hide() end
end

-- A drop-down menu over the panel. The panel swallows the mouse clicks, so the client never sees "a click elsewhere"
-- and kept the menu until its own timer ran out (or until Cancel). An invisible full-screen button just under the menu
-- closes it on any click outside; clicking an entry still works because the menu lists are above the button.
function ui.OpenMenu(menu, frame)
    EasyMenu(menu, frame, "cursor", 0, 0, "MENU")
    if not ui.menuCatcher then
        local c = CreateFrame("Button", nil, UIParent)
        c:SetAllPoints(UIParent)
        c:SetFrameStrata("TOOLTIP")
        c:SetFrameLevel(0)
        c:EnableMouse(true)
        c:SetScript("OnMouseDown", function()
            CloseDropDownMenus()
            c:Hide()
        end)
        c:Hide()
        if DropDownList1 and DropDownList1.HookScript then
            DropDownList1:HookScript("OnHide", function() c:Hide() end)
        end
        ui.menuCatcher = c
    end
    for i = 1, 3 do   -- above the panel (which sits in FULLSCREEN_DIALOG), above the catcher
        local l = _G["DropDownList" .. i]
        if l then
            l:SetFrameStrata("TOOLTIP")
            l:Raise()
        end
    end
    ui.menuCatcher:Show()
end

local function Selected()
    return state.selected and state.types[state.selected]
end

-- =========================================================================
-- left column: chest types
-- =========================================================================
local ROW_H = 38

local function SortTypes()
    wipe(state.order)
    for entry in pairs(state.types) do state.order[#state.order + 1] = entry end
    table.sort(state.order)
end

local function RefreshList()
    if not ui.rows then return end
    local total = #state.order
    local visible = #ui.rows
    local maxOff = math.max(0, total - ui.visibleRows)
    if state.listOffset > maxOff then state.listOffset = maxOff end
    for i = 1, visible do
        local row = ui.rows[i]
        local entry = state.order[i + state.listOffset]
        local t = entry and state.types[entry]
        if t and i <= ui.visibleRows then
            local rar = RARITY[t.rarity] or RARITY[1]
            row.entry = entry
            local dr = state.drafts[entry]
            row.icon:SetTexture(IconPath((dr and dr.icon) or t.icon, t.rarity))
            row.rim:SetTexture(rar.r, rar.g, rar.b, 1)
            row.name:SetText("|cff" .. rar.hex .. t.name .. "|r" .. ((ui.EntryDirty and ui.EntryDirty(entry)) and ("  |cffff9933*" .. T("未保存", "unsaved") .. "|r") or ""))
            local gold = (t.goldMax > 0) and (GoldShort(t.goldMin) .. "-" .. GoldShort(t.goldMax) .. T("金", "g")) or T("无金币", "no gold")
            local nSpawn = state.spawnCount[entry] or 0
            row.info:SetText(entry .. "  ·  " .. gold .. (nSpawn > 0 and ("  ·  |cff88ccff" .. nSpawn .. T("处", " spots") .. "|r") or ""))
            ShowIf(row.dscale, t.dscale)
            ShowIf(row.off, not t.active)
            if entry == state.selected then row.sel:Show() else row.sel:Hide() end
            row:Show()
        else
            row.entry = nil
            row:Hide()
        end
    end
    ui.listCount:SetText(total .. " / 100")
end

local function SelectType(entry)
    state.selected = entry
    RefreshList()
    if ui.RefreshCard then ui.RefreshCard() end
    if ui.RefreshSpawnList then ui.RefreshSpawnList() end
    state.lootRow = 0
    if ui.RequestLootIfNeeded then ui.RequestLootIfNeeded() end
    if ui.RefreshLoot then ui.RefreshLoot() end
end

-- right-click menu of a chest type
function ui.TypeMenu(entry)
    local t = state.types[entry]
    if not t then return end
    SelectType(entry)
    ui.menuFrame = ui.menuFrame or CreateFrame("Frame", "RebornTreasureGMTypeMenu", UIParent, "UIDropDownMenuTemplate")
    local respawn = t.respawnMin
    local menu = {
        { text = t.name .. "  |cff888888" .. entry .. "|r", isTitle = true, notCheckable = true },
        { text = T("在我脚下刷一个", "Spawn one here"), notCheckable = true,
          func = function() SendChatMessage(".treasure add " .. entry .. " " .. respawn, "SAY") end },
        { text = T("刷一个并写线索…", "Spawn with a clue…"), notCheckable = true,
          func = function() ChatFrame_OpenChat(".treasure add " .. entry .. " " .. respawn .. " ") end },
        { text = T("列出所有点位", "List spawns"), notCheckable = true,
          func = function() SendChatMessage(".treasure list", "SAY") end },
        { text = T("启用", "Active"), checked = t.active,
          func = function() Cmd("typeset " .. entry .. " active " .. (t.active and 0 or 1)) end },
        { text = T("副本金币随人数缩放", "Dungeon gold scales"), checked = t.dscale,
          func = function() Cmd("typeset " .. entry .. " dscale " .. (t.dscale and 0 or 1)) end },
    }
    for r = 1, 3 do
        local info = RARITY[r]
        menu[#menu + 1] = { text = "|cff" .. info.hex .. T(info.zh, info.en) .. "|r", checked = t.rarity == r,
                            func = function() Cmd("typeset " .. entry .. " rarity " .. r) end }
    end
    menu[#menu + 1] = { text = T("改名", "Rename"), notCheckable = true,
                        func = function() ui.eName:SetFocus(); ui.eName:HighlightText() end }
    menu[#menu + 1] = { text = T("选择外观…", "Pick appearance…"), notCheckable = true,
                        func = function() if not ui.looksFrame:IsShown() then ui.ToggleLooks() end end }
    menu[#menu + 1] = { text = T("复制", "Copy"), notCheckable = true,
                        func = function() state.pendingSelect = true; Cmd("typecopy " .. entry) end }
    menu[#menu + 1] = { text = "|cffff4040" .. T("删除", "Delete") .. "|r", notCheckable = true,
                        func = function() ui.Popup("REBORN_TREASURE_DELETE", t.name, nil, entry) end }
    menu[#menu + 1] = { text = T("取消", "Cancel"), notCheckable = true }
    ui.OpenMenu(menu, ui.menuFrame)
end

local function BuildLeft(main)
    local col = Panel(main)
    ui.left = col
    Header(col, "Interface\\Icons\\INV_Box_02", "宝箱种类", "Chest types")

    ui.listCount = col:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ui.listCount:SetPoint("TOPRIGHT", -10, -12)

    -- toolbar: new / copy / delete / refresh
    local bar = CreateFrame("Frame", nil, col)
    bar:SetPoint("TOPLEFT", 8, -34)
    bar:SetPoint("TOPRIGHT", -8, -34)
    bar:SetHeight(30)

    local bNew = IconButton(bar, 26, "Interface\\Icons\\Spell_ChargePositive", 0.2, 0.75, 0.2)
    bNew:SetPoint("LEFT", 2, 0)
    bNew:SetScript("OnClick", function()
        state.pendingSelect = true
        Cmd("typenew " .. T("新宝箱", "New chest"))
    end)
    Tip(bNew, "新建宝箱", "New chest type", T("用下一个空闲编号（990200-990299）新建一种宝箱。", "Creates a chest type on the next free entry (990200-990299)."))

    local bCopy = IconButton(bar, 26, "Interface\\Icons\\INV_Scroll_03", 0.25, 0.5, 0.95)
    bCopy:SetPoint("LEFT", bNew, "RIGHT", 8, 0)
    bCopy:SetScript("OnClick", function()
        if not state.selected then Status(T("先选一种宝箱", "Pick a chest first"), true) return end
        state.pendingSelect = true
        Cmd("typecopy " .. state.selected)
    end)
    Tip(bCopy, "复制宝箱", "Copy chest type", T("外观、金币和掉落表都一起复制。", "Copies looks, gold and the loot table."))

    local bDel = IconButton(bar, 26, "Interface\\Icons\\Spell_ChargeNegative", 0.85, 0.2, 0.15)
    bDel:SetPoint("LEFT", bCopy, "RIGHT", 8, 0)
    bDel:SetScript("OnClick", function()
        local t = Selected()
        if not t then Status(T("先选一种宝箱", "Pick a chest first"), true) return end
        ui.Popup("REBORN_TREASURE_DELETE", t.name, nil, t.entry)
    end)
    Tip(bDel, "删除宝箱", "Delete chest type", T("三种基础宝箱不能删；还有点位在用的也不能删。", "The three base chests and types still used by a spawn cannot be deleted."))

    local bRef = IconButton(bar, 26, "Interface\\Icons\\Spell_Holy_BorrowedTime", 0.85, 0.65, 0.15)
    bRef:SetPoint("RIGHT", -2, 0)
    bRef:SetScript("OnClick", function() Cmd("types") end)
    Tip(bRef, "刷新", "Refresh")

    -- rows
    local list = CreateFrame("Frame", nil, col)
    list:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, -4)
    list:SetPoint("BOTTOMRIGHT", col, "BOTTOMRIGHT", -8, 8)
    list:EnableMouseWheel(true)
    list:SetScript("OnMouseWheel", function(_, delta)
        state.listOffset = math.max(0, state.listOffset - delta)
        RefreshList()
    end)
    ui.list = list
    ui.rows = {}
    ui.visibleRows = 0

    function ui.LayoutRows()
        local h = list:GetHeight() or 0
        local n = math.max(1, math.floor(h / (ROW_H + 2)))
        for i = #ui.rows + 1, n do
            local row = CreateFrame("Button", nil, list)
            row:SetHeight(ROW_H)
            row:SetPoint("TOPLEFT", 0, -(i - 1) * (ROW_H + 2))
            row:SetPoint("TOPRIGHT", 0, -(i - 1) * (ROW_H + 2))
            local bg = row:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetTexture(0, 0, 0, 0.35)
            row.sel = row:CreateTexture(nil, "BORDER")
            row.sel:SetAllPoints()
            row.sel:SetTexture(1, 0.82, 0, 0.18)
            row.sel:Hide()
            local hl = row:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints()
            hl:SetTexture(1, 1, 1, 0.08)
            row.rim = row:CreateTexture(nil, "ARTWORK")
            row.rim:SetSize(34, 34)
            row.rim:SetPoint("LEFT", 2, 0)
            row.icon = row:CreateTexture(nil, "OVERLAY")
            row.icon:SetSize(30, 30)
            row.icon:SetPoint("CENTER", row.rim, "CENTER")
            row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.name:SetPoint("TOPLEFT", row.rim, "TOPRIGHT", 8, -2)
            row.name:SetPoint("RIGHT", row, "RIGHT", -40, 0)
            row.name:SetJustifyH("LEFT")
            row.info = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.info:SetPoint("BOTTOMLEFT", row.rim, "BOTTOMRIGHT", 8, 2)
            row.dscale = row:CreateTexture(nil, "OVERLAY")
            row.dscale:SetSize(16, 16)
            row.dscale:SetPoint("RIGHT", -4, 0)
            row.dscale:SetTexture("Interface\\Icons\\INV_Misc_GroupNeedMore")
            row.off = row:CreateTexture(nil, "OVERLAY")
            row.off:SetSize(16, 16)
            row.off:SetPoint("RIGHT", row.dscale, "LEFT", -2, 0)
            row.off:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
            row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            row:SetScript("OnClick", function(self, button)
                if not self.entry then return end
                if button == "RightButton" then ui.TypeMenu(self.entry) else SelectType(self.entry) end
            end)
            row:SetScript("OnEnter", function(self)
                local t = self.entry and state.types[self.entry]
                if not t then return end
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine(t.name)
                GameTooltip:AddLine(T("编号", "Entry") .. " " .. t.entry .. "   " .. T("外观", "Display") .. " " .. t.display, 0.8, 0.8, 0.8)
                GameTooltip:AddLine(T("金币", "Gold") .. ": " .. Money(t.goldMin) .. " - " .. Money(t.goldMax), 1, 1, 1)
                GameTooltip:AddLine(T("刷新", "Respawn") .. ": " .. t.respawnMin .. "-" .. t.respawnMax .. T(" 秒", " s"), 0.8, 0.8, 0.8)
                if t.dscale then GameTooltip:AddLine("副本金币随人数缩放 / Dungeon gold scales with players", 1, 0.6, 0.2) end
                if not t.active then GameTooltip:AddLine("已停用 / Inactive", 1, 0.3, 0.3) end
                GameTooltip:AddLine("右键：刷出、启用、品质、复制、删除…", 0.5, 0.8, 1)
                GameTooltip:AddLine("Right-click: spawn, toggle, quality, copy, delete…", 0.5, 0.6, 0.7)
                GameTooltip:Show()
            end)
            row:SetScript("OnLeave", function() GameTooltip:Hide() end)
            ui.rows[i] = row
        end
        ui.visibleRows = n
        RefreshList()
    end
end

-- =========================================================================
-- middle column: the selected chest (looks + settings); loot table comes in TREAS2C
-- =========================================================================
local function SaveField(field, value)
    local t = Selected()
    if not t then return end
    Cmd("typeset " .. t.entry .. " " .. field .. " " .. value)
end

-- the text boxes hold a draft: what is typed stays (a click on the list, a rarity change or the
-- server's reply no longer overwrites it) until Save / Enter sends it or Undo / Esc drops it
local DRAFT_KEYS = { "name", "gmin", "gmax", "rmin", "rmax", "size", "display", "rarity", "active", "dscale", "icon" }
local function ServerText(t, key)
    if key == "name" then return t.name end
    if key == "gmin" then return GoldShort(t.goldMin) end
    if key == "gmax" then return GoldShort(t.goldMax) end
    if key == "rmin" then return tostring(t.respawnMin) end
    if key == "rmax" then return tostring(t.respawnMax) end
    if key == "size" then return tostring(t.size) end
    if key == "display" then return tostring(t.display) end
    if key == "rarity" then return tostring(t.rarity) end
    if key == "active" then return t.active and "1" or "0" end
    if key == "dscale" then return t.dscale and "1" or "0" end
    if key == "icon" then   -- the name only: the seed rows still carry a damaged path ("InterfaceIconsINV_Box_01")
        local n = tostring(t.icon or "")
        n = n:match("([^\\]+)$") or n
        return (n:gsub("^[Ii]nterface[Ii]cons", ""))
    end
end

local function AnyDraft(d)
    if not d then return false end
    for _, k in ipairs(DRAFT_KEYS) do if d[k] then return true end end
    return false
end

-- the value shown for a field: the draft when there is one, else the server's
function ui.Eff(t, key)
    local d = state.drafts[t.entry]
    local v = d and d[key]
    if v == nil then v = ServerText(t, key) end
    return v
end

-- a change that is not typed (appearance, quality, the ticks) goes into the draft too
function ui.SetDraft(key, value, extra)   -- extra: the model path of a look; for an icon, true = picked by hand
    local t = Selected()
    if not t then return end
    local d = state.drafts[t.entry] or {}
    local v = tostring(value)
    if v == ServerText(t, key) then
        d[key] = nil
        if key == "display" then d.displayModel = nil end
    else
        d[key] = v
        if key == "display" then d.displayModel = extra end
        if key == "icon" and extra then d.iconManual = true end   -- picked by hand: a later appearance no longer changes it
    end
    state.drafts[t.entry] = AnyDraft(d) and d or nil
    ui.RefreshCard()
    if ui.RefreshLooksNow then ui.RefreshLooksNow() end   -- the picker's "chosen" highlight follows the click / the undo
    if ui.RefreshIconsNow then ui.RefreshIconsNow() end
end

-- appearance words -> a classic icon that fits (the names are all in the client)
local ICON_KEYS = {
    { "crate", "INV_Crate_01" }, { "barrel", "INV_Crate_03" }, { "tablet", "INV_Misc_StoneTablet_01" },
    { "scroll", "INV_Scroll_03" }, { "map", "INV_Scroll_03" }, { "urn", "INV_Misc_Urn_01" }, { "vase", "INV_Misc_Urn_01" },
    { "sack", "INV_Misc_Bag_09" }, { "bag", "INV_Misc_Bag_09" }, { "gift", "INV_Misc_Gift_01" }, { "present", "INV_Misc_Gift_01" },
    { "coffer", "INV_Box_04" }, { "strongbox", "INV_Box_04" }, { "trunk", "INV_Box_02" }, { "cache", "INV_Box_02" },
    { "box", "INV_Box_01" }, { "chest", "INV_Box_02" }, { "spoils", "INV_Box_02" }, { "booty", "INV_Box_02" },
}
function ui.AutoIcon(look)
    local card = Selected()
    if not (card and look) then return end
    local d = state.drafts[card.entry]
    if d and d.iconManual then return end
    local hay = ((look.name or "") .. " " .. (look.model or "")):lower()
    for _, k in ipairs(ICON_KEYS) do
        if hay:find(k[1], 1, true) then
            ui.SetDraft("icon", k[2], false)
            return
        end
    end
end

-- a short form for the card: no "INV_" / "INV_Misc_" in front
local function ShortIcon(name)
    name = tostring(name or "")
    name = name:gsub("^[Ii][Nn][Vv]_[Mm]isc_", ""):gsub("^[Ii][Nn][Vv]_", "")
    if #name > 16 then name = name:sub(1, 15) .. ".." end
    return name
end

function ui.UpdateDirty()
    local t = Selected()
    local d = t and state.drafts[t.entry]
    local n = 0
    if t and ui.LootDiff then
        local _, lootN = ui.LootDiff(t.entry)
        n = n + lootN
    end
    for _, key in ipairs(DRAFT_KEYS) do
        if d and d[key] then n = n + 1 end
        local eb = ui.boxes and ui.boxes[key]
        if eb then
            if d and d[key] then eb:SetTextColor(1, 0.6, 0.2) else eb:SetTextColor(1, 1, 1) end
        end
    end
    if ui.bSave then
        if n > 0 then
            ui.bSave:Enable(); ui.bUndo:Enable()
            ui.dirtyText:SetText("|cffff9933" .. string.format(T("有 %d 项没保存", "%d unsaved"), n) .. "|r")
        else
            ui.bSave:Disable(); ui.bUndo:Disable()
            ui.dirtyText:SetText(t and ("|cff55dd55" .. T("已全部保存", "All saved") .. "|r") or "")
        end
    end
    RefreshList()
end

function ui.SaveDraft()
    local t = Selected()
    local d = t and state.drafts[t.entry]
    local lootCmds = t and ui.LootDiff and ui.LootDiff(t.entry) or {}
    if not t or ((not d or not AnyDraft(d)) and #lootCmds == 0) then return end
    d = d or {}
    local function val(key) return d[key] or ServerText(t, key) end
    local cmds = {}
    if d.name then
        local name = CleanText(d.name)
        if name == "" then Status(T("名字不能为空", "The name cannot be empty"), true); return end
        cmds[#cmds + 1] = "typeset " .. t.entry .. " name " .. name
        t.name = name
    end
    if d.gmin or d.gmax then
        local a = math.floor((tonumber(val("gmin")) or 0) * 10000 + 0.5)
        local b = math.floor((tonumber(val("gmax")) or 0) * 10000 + 0.5)
        cmds[#cmds + 1] = "typeset " .. t.entry .. " gold " .. a .. " " .. b
        t.goldMin, t.goldMax = a, b
    end
    if d.rmin or d.rmax then
        local a, b = tonumber(val("rmin")) or 300, tonumber(val("rmax")) or 600
        cmds[#cmds + 1] = "typeset " .. t.entry .. " respawn " .. a .. " " .. b
        t.respawnMin, t.respawnMax = a, b
    end
    if d.size then
        local s = tonumber(d.size) or 1
        cmds[#cmds + 1] = "typeset " .. t.entry .. " size " .. s
        t.size = s
    end
    if d.display then
        t.display = tonumber(d.display) or t.display
        cmds[#cmds + 1] = "typeset " .. t.entry .. " display " .. t.display
        if d.displayModel then state.models[t.entry] = d.displayModel end
    end
    if d.rarity then
        t.rarity = tonumber(d.rarity) or t.rarity
        cmds[#cmds + 1] = "typeset " .. t.entry .. " rarity " .. t.rarity
    end
    if d.active then
        t.active = d.active == "1"
        cmds[#cmds + 1] = "typeset " .. t.entry .. " active " .. d.active
    end
    if d.dscale then
        t.dscale = d.dscale == "1"
        cmds[#cmds + 1] = "typeset " .. t.entry .. " dscale " .. d.dscale
    end
    if d.icon and d.icon ~= "" then
        t.icon = d.icon
        cmds[#cmds + 1] = "typeset " .. t.entry .. " icon " .. d.icon
    end
    for _, c in ipairs(lootCmds) do cmds[#cmds + 1] = c end   -- the loot table's changes go last
    state.lootWork[t.entry] = nil
    -- one command at a time, a little apart: the server answers each one, and a burst of chat lines is throttled
    for i, c in ipairs(cmds) do
        if i == 1 then Cmd(c) else ui.After(0.3 * (i - 1), function() Cmd(c) end) end
    end
    state.drafts[t.entry] = nil   -- shown as saved now; the server's reply corrects it if it refused
    ui.RefreshCard()
end

function ui.UndoDraft(key)
    local t = Selected()
    local d = t and state.drafts[t.entry]
    if t and not key and state.lootWork[t.entry] then
        state.lootWork[t.entry] = nil   -- the loot table goes back to the server's
        ui.RefreshLoot()
        ui.RefreshPool()
    end
    if not d then ui.UpdateDirty() return end
    if key then
        d[key] = nil
        if key == "display" then d.displayModel = nil end
        if key == "icon" then d.iconManual = nil end
    else
        d = nil
    end
    state.drafts[t.entry] = AnyDraft(d) and d or nil
    ui.RefreshCard()
    if ui.RefreshLooksNow then ui.RefreshLooksNow() end   -- the picker's "chosen" highlight follows the click / the undo
    if ui.RefreshIconsNow then ui.RefreshIconsNow() end
end

local function BindDraft(eb, key)
    ui.boxes = ui.boxes or {}
    ui.boxes[key] = eb
    eb:SetScript("OnTextChanged", function(self)
        if ui.filling then return end
        local t = Selected()
        if not t then return end
        local d = state.drafts[t.entry] or {}
        local text = self:GetText() or ""
        if text == ServerText(t, key) then d[key] = nil else d[key] = text end
        state.drafts[t.entry] = AnyDraft(d) and d or nil
        ui.UpdateDirty()
    end)
    eb:SetScript("OnEnterPressed", function(self) self:ClearFocus(); ui.SaveDraft() end)
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus(); ui.UndoDraft(key) end)
    eb:SetScript("OnTabPressed", function(self)
        for i, k in ipairs(DRAFT_KEYS) do
            if k == key then
                local nxt = ui.boxes[DRAFT_KEYS[i % #DRAFT_KEYS + 1]]
                if nxt then nxt:SetFocus(); nxt:HighlightText() end
                return
            end
        end
    end)
end

-- =========================================================================
-- loot table grid (middle, bottom), loot editor, item pool (right) -- TREAS2D
-- =========================================================================
local LOOT_CELL, LOOT_GAP = 46, 6

local function ItemLabel(it)
    if IsZh() and it.zh and it.zh ~= "" then return it.zh end
    return it.name or tostring(it.item or it.id or "?")
end

local function ChanceText(c)
    c = tonumber(c) or 0
    if c == math.floor(c) then return string.format("%d%%", c) end
    return string.format("%.1f%%", c)
end

local function CountText(it)
    if (it.max or 1) > 1 then
        return "x" .. (it.min or 1) .. ((it.max or 1) > (it.min or 1) and ("-" .. it.max) or "")
    end
    if (it.min or 1) > 1 then return "x" .. it.min end
    return ""
end

-- A full item tooltip only for an item the client already has. Asking for an unknown item through a tooltip makes the
-- client fetch it, and the equipment-compare addon zzzMoPItemTooltips then crashes the client (0x00620727 in
-- ShoppingTooltip1; seen again on 2026-10-25 while hovering the item pool). Without the data a plain tooltip is shown.
function ui.ItemTip(owner, anchor, id, label, quality, lines)
    GameTooltip:SetOwner(owner, anchor)
    local cached = GetItemInfo(id)
    local shown = false
    if cached then shown = pcall(GameTooltip.SetHyperlink, GameTooltip, "item:" .. id) end
    if not shown then
        local q = RARITY_Q[quality or 1] or RARITY_Q[1]
        GameTooltip:AddLine("|cff" .. q[4] .. label .. "|r")
        GameTooltip:AddLine("ItemID: " .. id, 0.7, 0.7, 0.7)
        if not cached then
            GameTooltip:AddLine(T("客户端还没有这件物品的数据，所以不显示完整提示。", "The client has no data for this item yet, so the full tooltip is skipped."), 1, 0.5, 0.2, true)
        end
    end
    for _, l in ipairs(lines or {}) do
        if l then GameTooltip:AddLine(l[1], l[2] or 1, l[3] or 0.82, l[4] or 0, true) end
    end
    GameTooltip:Show()
end

function ui.RequestLoot(entry)
    entry = tonumber(entry)
    if not entry then return end
    state.lootAsked[entry] = true
    Cmd("loot " .. entry)
end

function ui.RequestLootIfNeeded()
    local t = Selected()
    if t and not state.lootByType[t.entry] and not state.lootAsked[t.entry] then ui.RequestLoot(t.entry) end
end

-- The loot table is edited as a draft, like the rest of the card: state.lootWork[entry] is a working copy of the
-- server's list; the grid shows it, the Save button sends the difference, Undo drops it.
local function LootList(entry)
    return state.lootWork[entry] or state.lootByType[entry]
end

local function CopyConds(list)
    if not list then return nil end
    local out = {}
    for i, c in ipairs(list) do out[i] = { type = c.type, neg = c.neg, v1 = c.v1, v2 = c.v2, v3 = c.v3 } end
    return out
end

local function CondKey(list)
    local parts = {}
    for _, c in ipairs(list or {}) do parts[#parts + 1] = string.format("%d:%d:%d:%d:%d", c.type, c.neg, c.v1, c.v2, c.v3) end
    table.sort(parts)
    return table.concat(parts, ",")
end

local function WorkList(entry)
    local w = state.lootWork[entry]
    if not w then
        w = {}
        for _, it in ipairs(state.lootByType[entry] or {}) do
            w[#w + 1] = { item = it.item, chance = it.chance, min = it.min, max = it.max, group = it.group,
                          q = it.q, icon = it.icon, name = it.name, zh = it.zh,
                          quest = it.quest, nconds = it.nconds, conds = CopyConds(it.conds), condsBase = CopyConds(it.condsBase) }
        end
        state.lootWork[entry] = w
    end
    return w
end

-- the commands that turn the server's table into the working copy
function ui.LootDiff(entry)
    local work = state.lootWork[entry]
    local cmds = {}
    if not work then return cmds, 0 end
    local sm, wm = {}, {}
    for _, it in ipairs(state.lootByType[entry] or {}) do sm[it.item] = it end
    for _, it in ipairs(work) do
        wm[it.item] = true
        local s = sm[it.item]
        if not s or s.chance ~= it.chance or s.min ~= it.min or s.max ~= it.max or s.group ~= it.group
           or (s.quest and true or false) ~= (it.quest and true or false) then
            cmds[#cmds + 1] = string.format("lootset %d %d %g %d %d %d %d", entry, it.item, it.chance, it.min, it.max, it.group, it.quest and 1 or 0)
        end
        local condsChanged
        if not s then condsChanged = it.conds ~= nil and #it.conds > 0
        else condsChanged = it.conds ~= nil and it.condsBase ~= nil and CondKey(it.conds) ~= CondKey(it.condsBase) end
        if condsChanged then   -- the conditions are written after the line itself exists
            cmds[#cmds + 1] = string.format("lootcondclr %d %d", entry, it.item)
            for _, c in ipairs(it.conds) do
                cmds[#cmds + 1] = string.format("lootcondadd %d %d %d %d %d %d %d", entry, it.item, c.type, c.neg, c.v1, c.v2, c.v3)
            end
        end
    end
    for _, it in ipairs(state.lootByType[entry] or {}) do
        if not wm[it.item] then cmds[#cmds + 1] = string.format("lootdel %d %d", entry, it.item) end
    end
    return cmds, #cmds
end

function ui.EntryDirty(entry)
    if state.drafts[entry] then return true end
    local _, n = ui.LootDiff(entry)
    return n > 0
end

-- a change was made to the working copy: drop it again when it equals the server's, and repaint
function ui.TouchLoot(entry)
    local _, n = ui.LootDiff(entry)
    if n == 0 then state.lootWork[entry] = nil end
    ui.UpdateDirty()
    ui.RefreshLoot()
    ui.RefreshPool()
end

local function LootReady(entry)
    if state.lootByType[entry] then return true end
    Status(T("掉落表还在读取，稍等一下再改", "The loot table is still loading, try again in a moment"), true)
    return false
end

local function MetaFor(id, meta)
    if meta then return { q = meta.q or 1, icon = meta.icon or "", name = meta.name or "", zh = meta.zh or "" } end
    local name, _, q, _, _, _, _, _, _, tex = GetItemInfo(id)
    return { q = q or 1, icon = tex or "Interface\\Icons\\INV_Misc_QuestionMark", name = name or ("item " .. id), zh = "" }
end

-- put an item into the working copy of the selected chest type's loot table (100%, one piece, no group)
function ui.AddLoot(id, meta)
    local t = Selected()
    id = tonumber(id)
    if not t then Status(T("先选一种宝箱", "Pick a chest type first"), true) return end
    if not id or not LootReady(t.entry) then return end
    for _, it in ipairs(LootList(t.entry) or {}) do
        if it.item == id then
            Status(T("这件已经在掉落表里了，点它可以改概率和数量", "Already in the loot table: click it to change chance and count"), true)
            return
        end
    end
    local m = MetaFor(id, meta)
    local w = WorkList(t.entry)
    w[#w + 1] = { item = id, chance = 100, min = 1, max = 1, group = 0, q = m.q, icon = m.icon, name = m.name, zh = m.zh,
                  quest = false, nconds = 0, conds = {}, condsBase = {} }
    state.lootRow = 1000   -- scroll to the new one
    ui.TouchLoot(t.entry)
    Status(T("已加入掉落表（还没保存，点“保存”才生效）", "Added to the loot table (not saved yet: click Save)"))
end

function ui.DeleteLoot(entry, item)
    if not LootReady(entry) then return end
    local w = WorkList(entry)
    for i, it in ipairs(w) do
        if it.item == item then table.remove(w, i) break end
    end
    ui.TouchLoot(entry)
end

local function SetLootLine(entry, item, chance, mn, mx, group, quest, conds)
    if not LootReady(entry) then return end
    for _, it in ipairs(WorkList(entry)) do
        if it.item == item then
            if chance then it.chance = chance end
            if mn then it.min = mn end
            if mx then it.max = mx end
            if group then it.group = group end
            if quest ~= nil then it.quest = quest end
            if conds then
                it.conds = CopyConds(conds)
                if it.condsBase == nil and (it.nconds or 0) == 0 then it.condsBase = {} end   -- nothing was there before
            end
        end
    end
    ui.TouchLoot(entry)
end

local function LootInList(id)
    local t = Selected()
    for _, it in ipairs((t and LootList(t.entry)) or {}) do
        if it.item == id then return true end
    end
    return false
end

-- cursor items: a click or a drag released over the grid (a cell is a child of the area, so it takes the drop too)
local function DropOnLoot()
    local kind, id = GetCursorInfo()
    if kind == "item" and id then
        ClearCursor()
        ui.AddLoot(id)
    end
end

-- ---------------------------------------------------------------- the grid
function ui.RefreshLoot()
    if not ui.lootCells then return end
    local t = Selected()
    local list = t and LootList(t.entry)
    local serverList = t and state.lootByType[t.entry] or {}
    local cols, vis = ui.lootCols or 1, ui.lootRowsVis or 1
    local n = list and #list or 0
    local maxRow = math.max(0, math.ceil(n / cols) - vis)
    state.lootRow = math.max(0, math.min(state.lootRow or 0, maxRow))
    for i, cell in ipairs(ui.lootCells) do
        local it = (i <= cols * vis) and list and list[state.lootRow * cols + i]
        if it then
            local q = RARITY_Q[it.q] or RARITY_Q[1]
            cell.it = it
            if it.q >= 8 then cell.rim:SetTexture(1, 0.12, 0.12, 1) else cell.rim:SetTexture(q[1], q[2], q[3], 1) end    -- a quality the client has no colour for: see the tooltip
            cell.tex:SetTexture(IconPath(it.icon, 1))
            cell.chance:SetText(ChanceText(it.chance))
            if it.chance >= 100 then cell.chance:SetTextColor(1, 1, 1) else cell.chance:SetTextColor(1, 0.82, 0.2) end
            cell.count:SetText(CountText(it))
            cell.group:SetText(it.group > 0 and ("G" .. it.group) or "")
            local nc = it.conds and #it.conds or it.nconds or 0
            cell.flag:SetText((it.quest and ("|cffff9933" .. T("任", "Q") .. "|r") or "") .. (nc > 0 and ("|cff55ccff" .. T("条", "C") .. "|r") or ""))
            local was
            for _, s in ipairs(serverList) do if s.item == it.item then was = s end end
            if not was or was.chance ~= it.chance or was.min ~= it.min or was.max ~= it.max or was.group ~= it.group then
                cell.mod:Show()
            else
                cell.mod:Hide()
            end
            cell:Show()
        else
            cell.it = nil
            cell:Hide()
        end
    end
    if ui.lootCount then
        local dirty = t and state.lootWork[t.entry]
        ui.lootCount:SetText(list and (string.format(T("%d 件", "%d items"), n) .. (dirty and ("  |cffff9933*" .. T("未保存", "unsaved") .. "|r") or "")) or "")
    end
    if ui.lootEmpty then
        if not t then ui.lootEmpty:SetText("")
        elseif not list then ui.lootEmpty:SetText(T("读取中…", "Loading…"))
        elseif n == 0 then
            ui.lootEmpty:SetText(T("这种宝箱现在只给金币。\n把右边“物品库”里的物品拖到这里，或点一下物品加入；也可以把背包里的物品拖进来。",
                "This chest gives gold only.\nDrag an item from the Item pool here, or click one; items from your bags work too."))
        else ui.lootEmpty:SetText("") end
    end
end

function ui.LayoutLoot()
    local area = ui.lootArea
    if not (area and ui.lootCells) then return end
    local w, h = area:GetWidth() or 0, area:GetHeight() or 0
    if w < 60 or h < 60 then return end
    local cols = math.max(1, math.floor((w - 16) / (LOOT_CELL + LOOT_GAP)))
    local vis = math.max(1, math.floor((h - 38) / (LOOT_CELL + LOOT_GAP)))
    ui.lootCols, ui.lootRowsVis = cols, vis
    for i = #ui.lootCells + 1, cols * vis do
        local cell = CreateFrame("Button", nil, area)
        cell:SetSize(LOOT_CELL, LOOT_CELL)
        cell:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        cell.rim = cell:CreateTexture(nil, "BACKGROUND")
        cell.rim:SetAllPoints()
        cell.tex = cell:CreateTexture(nil, "ARTWORK")
        cell.tex:SetPoint("TOPLEFT", 2, -2)
        cell.tex:SetPoint("BOTTOMRIGHT", -2, 2)
        cell.tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        local hl = cell:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetTexture(0.45, 0.70, 1.0, 0.35)
        local function Small(point, x, y)
            local fs = cell:CreateFontString(nil, "OVERLAY")
            fs:SetFont(STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
            fs:SetPoint(point, x, y)
            return fs
        end
        cell.chance = Small("BOTTOMLEFT", 3, 3)
        cell.count = Small("TOPRIGHT", -3, -3)
        cell.group = Small("TOPLEFT", 3, -3)
        cell.flag = Small("BOTTOMRIGHT", -3, 3)
        cell.group:SetTextColor(0.5, 0.8, 1)
        cell.mod = cell:CreateTexture(nil, "OVERLAY")   -- an orange dot: new or changed, not saved yet
        cell.mod:SetSize(9, 9)
        cell.mod:SetPoint("TOPRIGHT", -2, -2)
        cell.mod:SetTexture(1, 0.6, 0.15, 1)
        cell.mod:Hide()
        cell:SetScript("OnEnter", function(self)
            local it = self.it
            if not it then return end
            ui.ItemTip(self, "ANCHOR_RIGHT", it.item, ItemLabel(it), it.q, {
                { " ", 1, 1, 1 },
                { string.format(T("概率 %s   数量 %d-%d   组 %d", "Chance %s   Count %d-%d   Group %d"), ChanceText(it.chance), it.min, it.max, it.group), 1, 0.82, 0 },
                { T("点击：改概率、数量、组    右键：更多", "Click: edit chance, count, group    Right-click: more"), 0.7, 0.7, 0.7 },
                it.quest and { T("任务物品：只给正在做、还缺这件物品的任务的人", "Quest item: only for players on a quest that still needs it"), 1, 0.6, 0.2 } or false,
                ((it.conds and #it.conds or it.nconds or 0) > 0) and { string.format(T("条件 %d 个：点开能看", "%d condition(s): click to see"), it.conds and #it.conds or it.nconds), 0.4, 0.8, 1 } or false,
                (it.q >= 8) and { T("品质 " .. it.q .. "：客户端没有这个品质的颜色，开箱时拾取窗口会报 Lua 错误，不要放进宝箱。", "Quality " .. it.q .. ": the client has no colour for it, the loot window gives a Lua error; keep it out of chests."), 1, 0.3, 0.3 } or false,
            })
        end)
        cell:SetScript("OnLeave", function() GameTooltip:Hide() end)
        cell:SetScript("OnReceiveDrag", DropOnLoot)
        cell:SetScript("OnClick", function(self, button)
            if GetCursorInfo and GetCursorInfo() then DropOnLoot() return end   -- an item on the cursor: put it in, do not edit the cell
            local it = self.it
            if not it then return end
            if button == "RightButton" then ui.LootMenu(it) else ui.EditLoot(it) end
        end)
        ui.lootCells[i] = cell
    end
    for i, cell in ipairs(ui.lootCells) do
        cell:ClearAllPoints()
        cell:SetPoint("TOPLEFT", area, "TOPLEFT", 8 + ((i - 1) % cols) * (LOOT_CELL + LOOT_GAP), -30 - math.floor((i - 1) / cols) * (LOOT_CELL + LOOT_GAP))
    end
    ui.RefreshLoot()
end

function ui.LootMenu(it)
    local t = Selected()
    if not t then return end
    ui.lootMenuFrame = ui.lootMenuFrame or CreateFrame("Frame", "RebornTreasureGMLootMenu", UIParent, "UIDropDownMenuTemplate")
    local entry, id = t.entry, it.item
    local function Set(chance) SetLootLine(entry, id, chance) end
    local menu = {
        { text = ItemLabel(it), isTitle = true, notCheckable = true },
        { text = T("编辑…", "Edit…"), notCheckable = true, func = function() ui.EditLoot(it) end },
        { text = T("概率 100%（必掉）", "Chance 100% (always)"), notCheckable = true, func = function() Set(100) end },
        { text = T("概率 50%", "Chance 50%"), notCheckable = true, func = function() Set(50) end },
        { text = T("概率 10%", "Chance 10%"), notCheckable = true, func = function() Set(10) end },
        { text = T("概率 1%", "Chance 1%"), notCheckable = true, func = function() Set(1) end },
        { text = "|cffff4040" .. T("从掉落表删除", "Remove from the loot table") .. "|r", notCheckable = true, func = function() ui.DeleteLoot(entry, id) end },
        { text = T("取消", "Cancel"), notCheckable = true },
    }
    ui.OpenMenu(menu, ui.lootMenuFrame)
end

local function BuildLootGrid(area)
    area:EnableMouse(true)
    area:SetScript("OnReceiveDrag", DropOnLoot)
    area:SetScript("OnMouseUp", function() if GetCursorInfo and GetCursorInfo() then DropOnLoot() end end)
    area:EnableMouseWheel(true)
    area:SetScript("OnMouseWheel", function(_, d) state.lootRow = (state.lootRow or 0) - d; ui.RefreshLoot() end)
    ui.lootCells = {}
    local wiz = CreateFrame("Button", nil, area, "UIPanelButtonTemplate")   -- the quest-item wizard
    wiz:SetSize(112, 20)
    wiz:SetPoint("TOPLEFT", 104, -7)
    Bind(wiz, "按任务添加", "From a quest")
    wiz:SetScript("OnClick", function() ui.QuestWizard() end)
    Tip(wiz, "按任务添加物品", "Add the items of a quest", T("输入任务编号或名字，会把这个任务要收集的物品加进这种宝箱的掉落表，并设成“任务物品”。",
        "Type a quest id or name: the items it asks for go into this chest's loot table as quest items."))
    local qtest = CreateFrame("Button", nil, area, "UIPanelButtonTemplate")   -- TREAS3B: give / take away a quest to test with
    qtest:SetSize(112, 20)
    qtest:SetPoint("LEFT", wiz, "RIGHT", 6, 0)
    Bind(qtest, "任务测试", "Quest test")
    qtest:SetScript("OnClick", function() ui.QuestTestMenu() end)
    Tip(qtest, "任务测试（GM）", "Quest test (GM)", T("给选中的角色、输入名字的在线角色或你自己接任务，不管阵营、种族、前置任务；也可以把任务去掉，让他再接一次。用来测任务物品宝箱。",
        "Give a quest to the selected character, a named online character or yourself, ignoring faction, race and prerequisites; or take it away so it can be taken again. For testing quest-item chests."))
    ui.lootCount = area:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ui.lootCount:SetPoint("TOPRIGHT", -10, -10)
    ui.lootEmpty = area:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    ui.lootEmpty:SetPoint("TOPLEFT", 16, -40)
    ui.lootEmpty:SetPoint("BOTTOMRIGHT", -16, 10)
    ui.lootEmpty:SetJustifyH("CENTER")
    area:SetScript("OnSizeChanged", function() ui.LayoutLoot() end)
end

-- ---------------------------------------------------------------- the editor of one loot line
-- ---------------------------------------------------------------- conditions of a loot line (TREAS3A)
-- A loot line can be "a quest item" (only players who are on a quest that still needs it get it) and can carry up to
-- three conditions (all must be true). The conditions are rows of the server's `conditions` table; only the types below
-- are written by the panel.
local COND_TYPES = {
    [9]  = { zh = "正在做任务", en = "Is doing the quest", kind = "quest" },
    [28] = { zh = "任务做完还没交", en = "Quest done, not handed in", kind = "quest" },
    [8]  = { zh = "已经交过任务", en = "Has handed the quest in", kind = "quest" },
    [14] = { zh = "从没接过任务", en = "Never took the quest", kind = "quest" },
    [6]  = { zh = "阵营", en = "Faction", kind = "team" },
    [15] = { zh = "职业", en = "Class", kind = "class" },
    [16] = { zh = "种族", en = "Race", kind = "race" },
    [27] = { zh = "等级", en = "Level", kind = "level" },
    [1]  = { zh = "身上有光环", en = "Has the aura", kind = "aura" },
    [2]  = { zh = "背包里有物品", en = "Has the item", kind = "item" },
}
local COND_ORDER = { 9, 28, 8, 14, 6, 15, 16, 27, 1, 2 }
local COND_MAX = 3
local CLASS_NAMES = { { 1, "战士", "Warrior" }, { 2, "圣骑士", "Paladin" }, { 3, "猎人", "Hunter" }, { 4, "盗贼", "Rogue" },
    { 5, "牧师", "Priest" }, { 6, "死亡骑士", "Death Knight" }, { 7, "萨满", "Shaman" }, { 8, "法师", "Mage" },
    { 9, "术士", "Warlock" }, { 11, "德鲁伊", "Druid" }, { 13, "巫医", "Witch Doctor" }, { 14, "武僧", "Monk" } }
local RACE_NAMES = { { 1, "人类", "Human" }, { 2, "兽人", "Orc" }, { 3, "矮人", "Dwarf" }, { 4, "暗夜精灵", "Night Elf" },
    { 5, "亡灵", "Undead" }, { 6, "牛头人", "Tauren" }, { 7, "侏儒", "Gnome" }, { 8, "巨魔", "Troll" },
    { 10, "血精灵", "Blood Elf" }, { 11, "德莱尼", "Draenei" } }
local CMP_NAMES = { [0] = { "等于", "equal to" }, [1] = { "大于", "above" }, [2] = { "小于", "below" },
                    [3] = { "至少", "at least" }, [4] = { "至多", "at most" } }

local function MaskNames(list, mask)
    local out = {}
    for _, e in ipairs(list) do
        if bit.band(mask, bit.lshift(1, e[1] - 1)) ~= 0 then out[#out + 1] = T(e[2], e[3]) end
    end
    return #out > 0 and table.concat(out, "/") or tostring(mask)
end

local function QuestLabel(id)
    local q = state.questTitle[id]
    if not q then return "#" .. id end
    local title = (IsZh() and q.zh ~= "" and q.zh) or q.en
    return "[" .. title .. "] #" .. id
end

local function DescribeCond(c)
    local ty = COND_TYPES[c.type]
    if not ty then return "?" end
    local v = ""
    if ty.kind == "quest" then v = QuestLabel(c.v1)
    elseif ty.kind == "team" then v = c.v1 == 469 and T("联盟", "Alliance") or T("部落", "Horde")
    elseif ty.kind == "class" then v = MaskNames(CLASS_NAMES, c.v1)
    elseif ty.kind == "race" then v = MaskNames(RACE_NAMES, c.v1)
    elseif ty.kind == "level" then v = T(CMP_NAMES[c.v2] and CMP_NAMES[c.v2][1] or "?", CMP_NAMES[c.v2] and CMP_NAMES[c.v2][2] or "?") .. " " .. c.v1
    elseif ty.kind == "aura" then v = "#" .. c.v1
    elseif ty.kind == "item" then v = "#" .. c.v1 .. " x" .. c.v2 end
    return (c.neg == 1 and ("|cffff6060" .. T("不是：", "NOT: ") .. "|r") or "") .. T(ty.zh, ty.en) .. "  " .. v
end

local function NewCond(ty)
    local c = { type = ty, neg = 0, v1 = 0, v2 = 0, v3 = 0 }
    local kind = COND_TYPES[ty].kind
    if kind == "team" then c.v1 = 67
    elseif kind == "class" then c.v1 = 1
    elseif kind == "race" then c.v1 = 1
    elseif kind == "level" then c.v1 = 60; c.v2 = 3
    elseif kind == "item" then c.v2 = 1 end
    return c
end

-- the quest's name is asked for once per id (the answers fill state.questTitle)
local function AskQuestTitle(id)
    if id and id > 0 and not state.questTitle[id] and not state.titleAsked[id] then
        state.titleAsked[id] = true
        Cmd("quests " .. id)
    end
end

local function CondRowsRefresh()
    local f = ui.lootEditor
    if not (f and f.condRows) then return end
    f.filling = true
    for i, row in ipairs(f.condRows) do
        local c = f.conds[i]
        if c then
            local ty = COND_TYPES[c.type]
            row:Show()
            row.type:SetText(T(ty.zh, ty.en))
            row.v1:SetText(tostring(c.v1))
            row.v2:SetText(tostring(c.v2))
            if ty.kind == "item" then row.v2:Show() else row.v2:Hide() end
            if ty.kind == "quest" or ty.kind == "team" or ty.kind == "class" or ty.kind == "race" or ty.kind == "level" then row.pick:Show() else row.pick:Hide() end
            row.neg:SetChecked(c.neg == 1)
            row.desc:SetText(DescribeCond(c))
            if ty.kind == "quest" then AskQuestTitle(c.v1) end
        else
            row:Hide()
        end
    end
    f.filling = false
    if f.addHint then ShowIf(f.addHint, #f.conds == 0) end
    if f.loadingText then ShowIf(f.loadingText, f.loading and true or false) end
end
ui.RefreshCondRows = CondRowsRefresh

local function AddCond(ty)
    local f = ui.lootEditor
    if not f then return nil end
    if f.loading then Status(T("条件还在读取，稍等一下", "The conditions are still loading"), true) return nil end
    if #f.conds >= COND_MAX then Status(T("一件物品最多 3 个条件", "At most 3 conditions per item"), true) return nil end
    local c = NewCond(ty)
    f.conds[#f.conds + 1] = c
    CondRowsRefresh()
    return c
end

local function SetCondType(i, ty)
    local f = ui.lootEditor
    local old = f.conds[i]
    if not old then return end
    local c = NewCond(ty)
    c.neg = old.neg
    f.conds[i] = c
    CondRowsRefresh()
end

-- pick a quest by id or by name (the answer of `quests` opens a menu); `done(id)` gets the chosen id
local function PickQuest(done)
    ui.Popup("REBORN_TREASURE_INPUT", T("任务编号，或任务名字的一部分（中文英文都行）", "Quest id, or part of its name (Chinese or English)"), nil, {
        default = "", fn = function(text)
            text = CleanText(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
            if text == "" then return end
            local id = tonumber(text)
            if id then
                done(math.floor(id))
            else
                state.questPick = done
                Cmd("quests " .. text)
            end
        end })
end

local function PickMenu(list, current, set)
    local menu = {}
    for _, e in ipairs(list) do
        menu[#menu + 1] = { text = T(e[2], e[3]), notCheckable = true, func = function() set(e[1]) end }
    end
    menu[#menu + 1] = { text = T("取消", "Cancel"), notCheckable = true }
    ui.lootPickMenu = ui.lootPickMenu or CreateFrame("Frame", "RebornTreasureGMPickMenu", UIParent, "UIDropDownMenuTemplate")
    ui.OpenMenu(menu, ui.lootPickMenu)
end

local function RowPick(i)
    local f = ui.lootEditor
    local c = f.conds[i]
    if not c then return end
    local kind = COND_TYPES[c.type].kind
    if kind == "quest" then
        PickQuest(function(id) c.v1 = id; CondRowsRefresh(); AskQuestTitle(id) end)
    elseif kind == "team" then
        PickMenu({ { 469, "联盟", "Alliance" }, { 67, "部落", "Horde" } }, c.v1, function(v) c.v1 = v; CondRowsRefresh() end)
    elseif kind == "class" then
        PickMenu(CLASS_NAMES, c.v1, function(id) c.v1 = bit.lshift(1, id - 1); CondRowsRefresh() end)
    elseif kind == "race" then
        PickMenu(RACE_NAMES, c.v1, function(id) c.v1 = bit.lshift(1, id - 1); CondRowsRefresh() end)
    elseif kind == "level" then
        local list = {}
        for k = 0, 4 do list[#list + 1] = { k, CMP_NAMES[k][1], CMP_NAMES[k][2] } end
        PickMenu(list, c.v2, function(v) c.v2 = v; CondRowsRefresh() end)
    end
end

local function RowTypeMenu(i)
    local menu = {}
    for _, ty in ipairs(COND_ORDER) do
        menu[#menu + 1] = { text = T(COND_TYPES[ty].zh, COND_TYPES[ty].en), notCheckable = true, func = function() SetCondType(i, ty) end }
    end
    menu[#menu + 1] = { text = T("取消", "Cancel"), notCheckable = true }
    ui.lootPickMenu = ui.lootPickMenu or CreateFrame("Frame", "RebornTreasureGMPickMenu", UIParent, "UIDropDownMenuTemplate")
    ui.OpenMenu(menu, ui.lootPickMenu)
end

-- ---------------------------------------------------------------- the editor of one loot line
local function BuildLootEditor(main)
    local f = CreateFrame("Frame", "RebornTreasureLootEditor", main)
    f:SetSize(470, 480)
    f:SetPoint("CENTER", UIParent, "CENTER", -80, 20)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true, tileSize = 32, edgeSize = 24,
        insets = { left = 6, right = 6, top = 6, bottom = 6 },
    })
    f:EnableMouse(true)
    f:Hide()
    f.conds = {}
    local solid = f:CreateTexture(nil, "BACKGROUND")
    solid:SetPoint("TOPLEFT", 7, -7)
    solid:SetPoint("BOTTOMRIGHT", -7, 7)
    solid:SetTexture(0.02, 0.02, 0.03, 0.97)
    local drag = CreateFrame("Frame", nil, f)
    drag:SetPoint("TOPLEFT", 6, -4)
    drag:SetPoint("TOPRIGHT", -30, -4)
    drag:SetHeight(28)
    drag:EnableMouse(true)
    drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart", function() f:StartMoving() end)
    drag:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)
    Header(f, "Interface\\Icons\\INV_Misc_Bag_08", "掉落物品", "Loot line")
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)

    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetSize(40, 40)
    f.icon:SetPoint("TOPLEFT", 18, -42)
    f.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    f.name = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.name:SetPoint("LEFT", f.icon, "RIGHT", 10, 6)
    f.name:SetPoint("RIGHT", f, "RIGHT", -16, 0)
    f.name:SetJustifyH("LEFT")
    f.sub = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.sub:SetPoint("TOPLEFT", f.name, "BOTTOMLEFT", 0, -4)

    local function Field(labelZh, labelEn, y, tipZh, tipEn)
        local fs = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetPoint("TOPLEFT", 20, y)
        Bind(fs, labelZh, labelEn)
        local eb = EditField(f, 70, true)
        eb:SetPoint("TOPLEFT", 150, y + 4)
        eb:SetScript("OnEnterPressed", function(self) self:ClearFocus(); ui.ApplyLootEdit() end)
        local hold = CreateFrame("Frame", nil, f)
        hold:SetPoint("TOPLEFT", fs, "TOPLEFT", -2, 2)
        hold:SetPoint("BOTTOMRIGHT", eb, "BOTTOMRIGHT", 0, 0)
        Tip(hold, tipZh, tipEn)
        return eb
    end
    f.eChance = Field("概率 %（0–100）", "Chance % (0-100)", -100, "这一件掉落的概率。组为 0 时每件独立计算；100 = 必掉。", "Chance for this line. With group 0 every line rolls on its own; 100 = always.")
    f.eMin = Field("最少数量", "Min count", -128, "掉落时最少几个。", "Fewest pieces when it drops.")
    f.eMax = Field("最多数量", "Max count", -156, "掉落时最多几个（1–255）。", "Most pieces when it drops (1-255).")
    f.eGroup = Field("组（0 = 无）", "Group (0 = none)", -184, "同一组（编号相同、大于 0）里的物品一次只掉其中一件，概率是组内的相对权重。", "Lines sharing a group number above 0 drop only one of them; the chances are weights inside the group.")

    -- quest item
    f.cQuest = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    f.cQuest:SetSize(24, 24)
    f.cQuest:SetPoint("TOPLEFT", 14, -206)
    local qt = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    qt:SetPoint("LEFT", f.cQuest, "RIGHT", 2, 0)
    qt:SetWidth(400)
    qt:SetJustifyH("LEFT")
    Bind(qt, "任务物品：只给正在做、还缺这件物品的任务的人", "Quest item: only for players on a quest that still needs it")
    Tip(f.cQuest, "任务物品", "Quest item", T("勾上后，只有“正在做一个需要这件物品、而且还没收集够”的任务的玩家才能看到、拿到它。物品本身要是某个任务的收集物品。",
        "Only players with a quest that still needs this item see and get it. The item must be a quest's required item."))

    -- conditions
    local ch = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ch:SetPoint("TOPLEFT", 20, -240)
    Bind(ch, "条件（全部满足才会掉）", "Conditions (all must be met to drop)")
    f.addHint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    f.addHint:SetPoint("LEFT", ch, "RIGHT", 10, 0)
    Bind(f.addHint, "没有条件：所有人都能掉。点下面的按钮加。", "No condition: everyone can get it. Use the buttons below.")
    f.loadingText = f:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    f.loadingText:SetPoint("TOPLEFT", 20, -300)
    Bind(f.loadingText, "读取条件中…", "Loading the conditions…")

    local function Preset(k, zh, en, fn, tipZh, tipEn)
        local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        b:SetSize(104, 22)
        b:SetPoint("TOPLEFT", 20 + (k - 1) * 108, -262)
        Bind(b, zh, en)
        b:SetScript("OnClick", fn)
        Tip(b, zh, en, T(tipZh, tipEn))
        return b
    end
    Preset(1, "+任务进行中", "+On quest", function()
        local c = AddCond(9)
        if c then RowPick(#f.conds) end
    end, "加一个“正在做任务”条件，并马上让你选任务。", "Adds an 'is doing the quest' condition and asks for the quest.")
    Preset(2, "+仅部落", "+Horde", function() local c = AddCond(6); if c then c.v1 = 67; CondRowsRefresh() end end, "只有部落玩家掉。", "Horde players only.")
    Preset(3, "+仅联盟", "+Alliance", function() local c = AddCond(6); if c then c.v1 = 469; CondRowsRefresh() end end, "只有联盟玩家掉。", "Alliance players only.")
    Preset(4, "+其它条件", "+Other", function()
        local menu = {}
        for _, ty in ipairs(COND_ORDER) do
            menu[#menu + 1] = { text = T(COND_TYPES[ty].zh, COND_TYPES[ty].en), notCheckable = true, func = function() AddCond(ty) end }
        end
        menu[#menu + 1] = { text = T("取消", "Cancel"), notCheckable = true }
        ui.lootPickMenu = ui.lootPickMenu or CreateFrame("Frame", "RebornTreasureGMPickMenu", UIParent, "UIDropDownMenuTemplate")
        ui.OpenMenu(menu, ui.lootPickMenu)
    end, "从全部条件类型里选一个。", "Pick from every condition type.")

    f.condRows = {}
    for i = 1, COND_MAX do
        local row = CreateFrame("Frame", nil, f)
        row:SetSize(440, 44)
        row:SetPoint("TOPLEFT", 16, -292 - (i - 1) * 48)
        row.index = i
        row.type = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.type:SetSize(150, 22)
        row.type:SetPoint("TOPLEFT", 0, 0)
        row.type:SetScript("OnClick", function() RowTypeMenu(i) end)
        row.v1 = EditField(row, 70, true)
        row.v1:SetPoint("TOPLEFT", 160, -1)
        row.v2 = EditField(row, 44, true)
        row.v2:SetPoint("TOPLEFT", 238, -1)
        row.pick = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.pick:SetSize(40, 22)
        row.pick:SetPoint("TOPLEFT", 290, 0)
        Bind(row.pick, "选…", "Pick…")
        row.pick:SetScript("OnClick", function() RowPick(i) end)
        row.neg = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
        row.neg:SetSize(22, 22)
        row.neg:SetPoint("TOPLEFT", 340, 0)
        local nt = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        nt:SetPoint("LEFT", row.neg, "RIGHT", 0, 0)
        Bind(nt, "取反", "NOT")
        Tip(row.neg, "取反", "Negate", T("勾上表示“不满足这个条件才掉”，比如“没接过任务”。", "Drops when the condition is NOT met."))
        row.del = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.del:SetSize(26, 22)
        row.del:SetPoint("TOPLEFT", 410, 0)
        row.del:SetText("x")
        row.del:SetScript("OnClick", function()
            table.remove(f.conds, i)
            CondRowsRefresh()
        end)
        row.desc = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        row.desc:SetPoint("TOPLEFT", 4, -26)
        row.desc:SetWidth(430)
        row.desc:SetJustifyH("LEFT")
        row.v1:SetScript("OnTextChanged", function(self)
            if f.filling then return end
            local c = f.conds[i]
            if not c then return end
            c.v1 = math.floor(tonumber(self:GetText()) or 0)
            row.desc:SetText(DescribeCond(c))
            if COND_TYPES[c.type].kind == "quest" then
                f.titleToken = (f.titleToken or 0) + 1
                local tok = f.titleToken
                ui.After(0.7, function() if tok == f.titleToken then AskQuestTitle(c.v1); row.desc:SetText(DescribeCond(c)) end end)
            end
        end)
        row.v2:SetScript("OnTextChanged", function(self)
            if f.filling then return end
            local c = f.conds[i]
            if not c then return end
            c.v2 = math.floor(tonumber(self:GetText()) or 0)
            row.desc:SetText(DescribeCond(c))
        end)
        row.neg:SetScript("OnClick", function(self)
            local c = f.conds[i]
            if c then c.neg = self:GetChecked() and 1 or 0; row.desc:SetText(DescribeCond(c)) end
        end)
        row:Hide()
        f.condRows[i] = row
    end

    local apply = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    apply:SetSize(90, 24)
    apply:SetPoint("BOTTOMLEFT", 20, 16)
    Bind(apply, "应用", "Apply")
    apply:SetScript("OnClick", function() ui.ApplyLootEdit() end)
    local del = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    del:SetSize(90, 24)
    del:SetPoint("LEFT", apply, "RIGHT", 8, 0)
    Bind(del, "删除", "Remove")
    del:SetScript("OnClick", function()
        local e = f.editing
        if e then ui.DeleteLoot(e.entry, e.item.item) end
        f:Hide()
    end)
    local note = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    note:SetPoint("LEFT", del, "RIGHT", 12, 0)
    note:SetPoint("RIGHT", f, "RIGHT", -16, 0)
    note:SetJustifyH("LEFT")
    Bind(note, "应用后还要点卡片上的“保存”才生效。", "After Apply, click Save on the card.")
    ui.lootEditor = f
end

function ui.EditLoot(it)
    local t = Selected()
    local f = ui.lootEditor
    if not (t and f and it) then return end
    f.editing = { entry = t.entry, item = it }
    f.icon:SetTexture(IconPath(it.icon, 1))
    local q = RARITY_Q[it.q] or RARITY_Q[1]
    f.name:SetText("|cff" .. q[4] .. ItemLabel(it) .. "|r")
    f.sub:SetText(string.format("%s %d   %s", T("物品", "Item"), it.item, t.name))
    f.eChance:SetText(string.format("%g", it.chance))
    f.eMin:SetText(tostring(it.min))
    f.eMax:SetText(tostring(it.max))
    f.eGroup:SetText(tostring(it.group))
    f.cQuest:SetChecked(it.quest and true or false)
    if it.conds then
        f.conds, f.loading = CopyConds(it.conds), false
    elseif (it.nconds or 0) > 0 then
        f.conds, f.loading = {}, true
        Cmd(string.format("lootcond %d %d", t.entry, it.item))
    else
        f.conds, f.loading = {}, false
    end
    CondRowsRefresh()
    f:Show()
    f:Raise()
end

function ui.ApplyLootEdit()
    local f = ui.lootEditor
    local e = f and f.editing
    if not e then return end
    local chance = math.max(0, math.min(100, tonumber(f.eChance:GetText()) or 100))
    local mn = math.max(1, math.min(255, math.floor(tonumber(f.eMin:GetText()) or 1)))
    local mx = math.max(mn, math.min(255, math.floor(tonumber(f.eMax:GetText()) or mn)))
    local grp = math.max(0, math.min(255, math.floor(tonumber(f.eGroup:GetText()) or 0)))
    local conds
    if not f.loading then
        for _, c in ipairs(f.conds) do
            if c.v1 <= 0 then Status(T("有条件还没填完（编号或数值是 0）", "A condition is not filled in yet"), true) return end
        end
        conds = f.conds
    end
    SetLootLine(e.entry, e.item.item, chance, mn, mx, grp, f.cQuest:GetChecked() and true or false, conds)
    f:Hide()
end

-- the quest-item wizard: a quest id or name -> the items the quest asks for go into the loot table as quest items
function ui.ApplyQuestInfo(info)
    local t = Selected()
    if not t then return end
    if info.id and info.id > 0 then state.lastQuest = info.id end  -- TREAS3B
    if #info.items == 0 then
        Status(T("这个任务没有要收集的物品（只有“杀怪”或“对话”之类的目标）", "This quest asks for no items (kill or talk objectives only)"), true)
        return
    end
    local added = 0
    for _, it in ipairs(info.items) do
        ui.AddLoot(it.item, { q = it.q, icon = it.icon, name = it.name, zh = it.zh })
        for _, line in ipairs(LootList(t.entry) or {}) do
            if line.item == it.item then
                SetLootLine(t.entry, it.item, nil, nil, nil, nil, true)
                added = added + 1
            end
        end
    end
    local title = (IsZh() and info.zh ~= "" and info.zh) or info.title
    Status(string.format(T("任务《%s》：%d 件任务物品已加入掉落表（还没保存）", "Quest '%s': %d quest items added (not saved yet)"), title, added))
end

-- TREAS3B: `questadd` / `questdel <id> [name]`: the named character, else the selected player, else the GM
function ui.QuestTestMenu()
    -- who == nil: the selected character (yourself when nobody is selected); a name: that online character
    local function Do(verb, id, who)
        id = math.floor(tonumber(id) or 0)
        if id <= 0 then return end
        state.lastQuest = id
        if who then state.lastWho = who end
        Cmd(verb .. " " .. id .. (who and (" " .. who) or ""))
    end
    local function AskName(done)
        ui.Popup("REBORN_TREASURE_INPUT", T("角色名（要在线）", "Character name (must be online)"), nil, {
            default = state.lastWho or "", fn = function(text)
                text = CleanText(text or ""):gsub("%s+", "")
                if text == "" then return end
                done(text)
            end })
    end
    local me = UnitName and UnitName("player")
    local last, who = state.lastQuest, state.lastWho
    local menu = {
        { text = T("任务测试：不管阵营、种族、前置任务", "Quest test: ignores faction, race and prerequisites"), isTitle = true, notCheckable = true },
        { text = T("接任务（选中的角色，没选就是自己）…", "Give a quest (selected character, else you)…"), notCheckable = true,
          func = function() PickQuest(function(id) Do("questadd", id) end) end },
        { text = T("去掉任务（选中的角色，没选就是自己）…", "Take a quest away (selected character, else you)…"), notCheckable = true,
          func = function() PickQuest(function(id) Do("questdel", id) end) end },
        { text = T("给指定角色接任务（输角色名）…", "Give a quest to a named character…"), notCheckable = true,
          func = function() AskName(function(name) PickQuest(function(id) Do("questadd", id, name) end) end) end },
        { text = T("去掉指定角色的任务（输角色名）…", "Take a quest away from a named character…"), notCheckable = true,
          func = function() AskName(function(name) PickQuest(function(id) Do("questdel", id, name) end) end) end },
    }
    if me and me ~= "" then
        menu[#menu + 1] = { text = T("给我自己接任务…", "Give myself a quest…"), notCheckable = true,
            func = function() PickQuest(function(id) Do("questadd", id, me) end) end }
        menu[#menu + 1] = { text = T("去掉我自己的任务…", "Take a quest away from myself…"), notCheckable = true,
            func = function() PickQuest(function(id) Do("questdel", id, me) end) end }
    end
    if last then
        menu[#menu + 1] = { text = string.format(T("接上次的任务 %d（选中的角色）", "Give the last quest %d (selected)"), last), notCheckable = true,
            func = function() Do("questadd", last) end }
        menu[#menu + 1] = { text = string.format(T("去掉上次的任务 %d（选中的角色）", "Take the last quest %d away (selected)"), last), notCheckable = true,
            func = function() Do("questdel", last) end }
        if who then
            menu[#menu + 1] = { text = string.format(T("给 %s 接上次的任务 %d", "Give %s the last quest %d"), who, last), notCheckable = true,
                func = function() Do("questadd", last, who) end }
            menu[#menu + 1] = { text = string.format(T("去掉 %s 的上次任务 %d", "Take quest %d away from %s"), who, last), notCheckable = true,
                func = function() Do("questdel", last, who) end }
        end
    end
    menu[#menu + 1] = { text = T("取消", "Cancel"), notCheckable = true }
    ui.questTestMenu = ui.questTestMenu or CreateFrame("Frame", "RebornTreasureGMQuestTestMenu", UIParent, "UIDropDownMenuTemplate")
    ui.OpenMenu(menu, ui.questTestMenu)
end

function ui.QuestWizard()
    local t = Selected()
    if not t then Status(T("先选一种宝箱", "Pick a chest type first"), true) return end
    ui.Popup("REBORN_TREASURE_INPUT", T("任务编号，或任务名字的一部分。会把这个任务要收集的物品加进掉落表，并设成“任务物品”。", "Quest id, or part of its name. The items the quest asks for are added as quest items."), nil, {
        default = "", fn = function(text)
            text = CleanText(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
            if text == "" then return end
            local id = tonumber(text)
            if id then
                state.qiWizard = true
                Cmd("questinfo " .. math.floor(id))
            else
                state.questPick = function(qid) state.qiWizard = true; Cmd("questinfo " .. qid) end
                Cmd("quests " .. text)
            end
        end })
end


-- ---------------------------------------------------------------- the item pool
local POOL_CATS = {
    { "all", "全部", "All" }, { "use", "消耗", "Use" }, { "gear", "装备", "Gear" }, { "cloth", "服饰", "Cloth" },
    { "weapon", "武器", "Weapon" }, { "mount", "坐骑", "Mount" }, { "pet", "宠物", "Pet" }, { "recipe", "配方", "Recipe" },
    { "trade", "材料", "Trade" }, { "quest", "任务", "Quest" }, { "gem", "宝石", "Gem" }, { "misc", "杂项", "Misc" },
}
local POOL_ROW_H = 36

function ui.PoolRequest(page)
    local p = state.pool
    if page then p.page = math.max(0, page) end
    p.loading = true
    Cmd("items " .. p.cat .. " " .. p.page .. (p.text ~= "" and (" " .. CleanText(p.text)) or ""))
    ui.RefreshPool()
end

function ui.RefreshPool()
    if not ui.poolRows then return end
    local p = state.pool
    for key, b in pairs(ui.poolCatBtns or {}) do
        if key == p.cat then b:LockHighlight() else b:UnlockHighlight() end
    end
    local visible = ui.poolVisible or 0
    state.poolOffset = math.max(0, math.min(state.poolOffset or 0, #p.items - visible))
    for i, row in ipairs(ui.poolRows) do
        local it = (i <= visible) and p.items[i + state.poolOffset]
        if it then
            local q = RARITY_Q[it.q] or RARITY_Q[1]
            row.it = it
            row.rim:SetTexture(q[1], q[2], q[3], 1)
            row.tex:SetTexture(IconPath(it.icon, 1))
            row.name:SetText("|cff" .. q[4] .. ItemLabel(it) .. "|r")
            row.info:SetText("|cff888888" .. it.id .. "|r" .. (it.q >= 8 and ("  |cffff6060" .. T("品质", "quality") .. " " .. it.q .. "|r") or ""))
            if LootInList(it.id) then row.have:Show() else row.have:Hide() end
            row:Show()
        else
            row.it = nil
            row:Hide()
        end
    end
    if ui.poolPage then
        ui.poolPage:SetText(string.format(T("第 %d 页", "Page %d"), p.page + 1) .. (p.loading and ("  " .. T("读取中…", "Loading…")) or ""))
    end
    if ui.poolPrev then
        if p.page > 0 then ui.poolPrev:Enable() else ui.poolPrev:Disable() end
        if p.more then ui.poolNext:Enable() else ui.poolNext:Disable() end
    end
    if ui.poolEmpty then
        ui.poolEmpty:SetText((#p.items == 0 and not p.loading) and T("没有找到。可以输入物品编号，或中文/英文名字的一部分。", "Nothing found. Type an item id, or part of a Chinese / English name.") or "")
    end
end

local function PoolGhost()
    if ui.ghost then return ui.ghost end
    local g = CreateFrame("Frame", nil, UIParent)
    g:SetSize(40, 40)
    g:SetFrameStrata("TOOLTIP")
    g.tex = g:CreateTexture(nil, "ARTWORK")
    g.tex:SetAllPoints()
    g.tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    g:SetScript("OnUpdate", function(self)
        local x, y = GetCursorPosition()
        local s = UIParent:GetEffectiveScale()
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x / s + 18, y / s - 18)
    end)
    g:Hide()
    ui.ghost = g
    return g
end

function ui.LayoutPool()
    local list = ui.poolList
    if not (list and ui.poolRows) then return end
    local n = math.max(1, math.floor((list:GetHeight() or 0) / POOL_ROW_H))
    for i = #ui.poolRows + 1, n do
        local row = CreateFrame("Button", nil, list)
        row:SetHeight(POOL_ROW_H - 2)
        row:SetPoint("TOPLEFT", 0, -(i - 1) * POOL_ROW_H)
        row:SetPoint("RIGHT", list, "RIGHT", 0, 0)
        row:RegisterForClicks("LeftButtonUp")
        row:RegisterForDrag("LeftButton")
        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture(0.10, 0.10, 0.12, 0.9)
        local hl = row:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetTexture(0.45, 0.70, 1.0, 0.30)
        row.rim = row:CreateTexture(nil, "ARTWORK")
        row.rim:SetSize(30, 30)
        row.rim:SetPoint("LEFT", 4, 0)
        row.tex = row:CreateTexture(nil, "OVERLAY")
        row.tex:SetSize(26, 26)
        row.tex:SetPoint("CENTER", row.rim, "CENTER")
        row.tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.name:SetPoint("TOPLEFT", row.rim, "TOPRIGHT", 6, -1)
        row.name:SetPoint("RIGHT", row, "RIGHT", -22, 0)
        row.name:SetJustifyH("LEFT")
        row.info = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        row.info:SetPoint("BOTTOMLEFT", row.rim, "BOTTOMRIGHT", 6, 1)
        row.have = row:CreateTexture(nil, "OVERLAY")
        row.have:SetSize(16, 16)
        row.have:SetPoint("RIGHT", -4, 0)
        row.have:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        row:SetScript("OnEnter", function(self)
            if not self.it then return end
            ui.ItemTip(self, "ANCHOR_LEFT", self.it.id, ItemLabel(self.it), self.it.q, {
                { " ", 1, 1, 1 },
                { T("点击：加入这种宝箱的掉落表（100%，1 个，点“保存”才生效）", "Click: add to this chest's loot table (100%, 1 piece; then Save)"), 0.7, 0.7, 0.7 },
                { T("也可以拖到中间的掉落表里", "or drag it onto the loot table in the middle"), 0.7, 0.7, 0.7 },
            })
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        row:SetScript("OnClick", function(self)
            if not self.it then return end
            if state.dragStamp and GetTime() - state.dragStamp < 0.3 then return end   -- the mouse-up of a drag
            ui.AddLoot(self.it.id, self.it)
        end)
        row:SetScript("OnDragStart", function(self)
            if not self.it then return end
            GameTooltip:Hide()
            state.dragItem = self.it
            local g = PoolGhost()
            g.tex:SetTexture(IconPath(self.it.icon, 1))
            g:Show()
        end)
        row:SetScript("OnDragStop", function()
            local it = state.dragItem
            state.dragItem = nil
            state.dragStamp = GetTime()
            if ui.ghost then ui.ghost:Hide() end
            if it and ui.lootArea and MouseIsOver(ui.lootArea) then ui.AddLoot(it.id, it) end
        end)
        ui.poolRows[i] = row
    end
    ui.poolVisible = n
    ui.RefreshPool()
end

local function BuildPool(pool)
    state.pool = state.pool or { cat = "all", page = 0, text = "", items = {}, more = false }
    ui.poolCatBtns = {}
    local W = 52
    for k, c in ipairs(POOL_CATS) do
        local b = CreateFrame("Button", nil, pool, "UIPanelButtonTemplate")
        b:SetSize(W, 20)
        b:SetPoint("TOPLEFT", 2 + ((k - 1) % 4) * (W + 2), -2 - math.floor((k - 1) / 4) * 22)
        Bind(b, c[2], c[3])
        b:SetScript("OnClick", function()
            state.pool.cat = c[1]
            state.poolOffset = 0
            ui.PoolRequest(0)
        end)
        ui.poolCatBtns[c[1]] = b
    end
    local box = EditField(pool, 100, false)
    box:SetPoint("TOPLEFT", 8, -74)
    box:SetPoint("RIGHT", pool, "RIGHT", -62, 0)
    box:SetMaxLetters(40)
    box:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        state.pool.text = self:GetText() or ""
        if state.pool.text:match("^%s*%d+%s*$") then state.pool.cat = "all" end   -- an item id: look everywhere
        state.poolOffset = 0
        ui.PoolRequest(0)
    end)
    Tip(box, "搜索物品", "Search items", T("写物品编号（会在所有分类里找），或中文/英文名字的一部分，按 Enter。", "An item id (searched in every category), or part of a Chinese / English name, then Enter."))
    ui.poolBox = box
    local go = CreateFrame("Button", nil, pool, "UIPanelButtonTemplate")
    go:SetSize(54, 22)
    go:SetPoint("TOPRIGHT", -2, -73)
    Bind(go, "搜索", "Search")
    go:SetScript("OnClick", function() box:GetScript("OnEnterPressed")(box) end)

    local prev = CreateFrame("Button", nil, pool, "UIPanelButtonTemplate")
    prev:SetSize(30, 20)
    prev:SetPoint("TOPLEFT", 2, -100)
    prev:SetText("<")
    prev:SetScript("OnClick", function() state.poolOffset = 0; ui.PoolRequest(state.pool.page - 1) end)
    local nxt = CreateFrame("Button", nil, pool, "UIPanelButtonTemplate")
    nxt:SetSize(30, 20)
    nxt:SetPoint("LEFT", prev, "RIGHT", 2, 0)
    nxt:SetText(">")
    nxt:SetScript("OnClick", function() state.poolOffset = 0; ui.PoolRequest(state.pool.page + 1) end)
    ui.poolPrev, ui.poolNext = prev, nxt
    ui.poolPage = pool:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ui.poolPage:SetPoint("LEFT", nxt, "RIGHT", 8, 0)

    local list = CreateFrame("Frame", nil, pool)
    list:SetPoint("TOPLEFT", 2, -124)
    list:SetPoint("BOTTOMRIGHT", -2, 2)
    list:EnableMouseWheel(true)
    list:SetScript("OnMouseWheel", function(_, d) state.poolOffset = (state.poolOffset or 0) - d * 3; ui.RefreshPool() end)
    list:SetScript("OnSizeChanged", function() ui.LayoutPool() end)
    ui.poolList = list
    ui.poolRows = {}
    ui.poolEmpty = list:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    ui.poolEmpty:SetPoint("TOPLEFT", 10, -20)
    ui.poolEmpty:SetPoint("RIGHT", -10, 0)
    ui.poolEmpty:SetJustifyH("CENTER")
end

local function BuildMiddle(main)
    local col = Panel(main)
    ui.middle = col
    ui.cardTitle = Header(col, "Interface\\Icons\\INV_Misc_Bag_10", "宝箱", "Chest")

    -- model preview
    local stage = CreateFrame("Frame", nil, col)
    stage:SetPoint("TOPLEFT", 10, -34)
    stage:SetSize(150, 150)
    stage:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true, tileSize = 32, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    ui.stage = stage
    local model = CreateFrame("PlayerModel", nil, stage)
    model:SetPoint("TOPLEFT", 6, -6)
    model:SetPoint("BOTTOMRIGHT", -6, 6)
    model:SetFrameLevel(stage:GetFrameLevel() + 2)
    model.facing = 0.6
    model.zoom = 1
    model:EnableMouse(true)
    model:EnableMouseWheel(true)
    model:SetScript("OnUpdate", function(self, elapsed)
        if self.dragX then
            local x = GetCursorPosition()
            self.facing = self.facing + (x - self.dragX) * 0.02
            self.dragX = x
        elseif not self.paused then
            self.facing = self.facing + elapsed * 0.4
        end
        pcall(self.SetFacing, self, self.facing)
    end)
    model:SetScript("OnMouseDown", function(self) self.dragX = GetCursorPosition() end)
    model:SetScript("OnMouseUp", function(self) self.dragX = nil end)
    model:SetScript("OnMouseWheel", function(self, delta)
        self.zoom = math.max(0.3, math.min(3, self.zoom + delta * 0.1))
        pcall(self.SetModelScale, self, self.zoom)
    end)
    ui.model = model
    local noModel = stage:CreateTexture(nil, "ARTWORK")
    noModel:SetSize(56, 56)
    noModel:SetPoint("CENTER")
    noModel:Hide()
    ui.noModel = noModel
    Tip(model, "外观预览：拖动旋转，滚轮缩放", "Preview: drag to turn, wheel to zoom")

    -- appearance picker button under the preview
    local bLook = IconButton(col, 24, "Interface\\Icons\\INV_Misc_Spyglass_02", 0.85, 0.65, 0.15)
    bLook:SetPoint("TOPLEFT", stage, "BOTTOMLEFT", 2, -6)
    bLook:SetScript("OnClick", function() if ui.ToggleLooks then ui.ToggleLooks() end end)
    Tip(bLook, "选择外观", "Pick appearance", T("从库里所有宝箱用过的模型里选。客户端会缓存旧外观，换了看不到时清客户端 Cache 或新建一种。",
        "Models used by stock chests. The client caches looks; clear the Cache folder or make a new type if it does not change."))
    ui.lookText = col:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ui.lookText:SetPoint("LEFT", bLook, "RIGHT", 6, 0)

    -- the icon of this chest type (only the GM panel shows it): follows the appearance, can be picked by hand
    local bIcon = IconButton(col, 24, "Interface\\Icons\\INV_Box_01", 0.55, 0.55, 0.65)
    bIcon:SetPoint("TOPLEFT", bLook, "BOTTOMLEFT", 0, -8)
    bIcon:SetScript("OnClick", function() if ui.ToggleIcons then ui.ToggleIcons() end end)
    bIcon:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(T("选择图标", "Pick the icon"), 1, 0.82, 0)
        if ui.iconFull and ui.iconFull ~= "" then GameTooltip:AddLine(ui.iconFull, 1, 1, 1) end
        GameTooltip:AddLine(T("这个图标只在 GM 面板里当标签用，游戏里看不到。选外观时会自动换成相配的图标；自己选过之后，换外观就不再改它。",
            "Only the GM panel shows this icon. Picking an appearance changes it to a matching one; once you pick one by hand, a new appearance leaves it alone."), 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    bIcon:SetScript("OnLeave", function() GameTooltip:Hide() end)
    ui.bIcon = bIcon
    ui.iconText = col:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ui.iconText:SetPoint("LEFT", bIcon, "RIGHT", 6, 0)

    -- settings to the right of the preview
    local x0, y = 176, -38
    local function Label(icon, zh, en, yy)
        local tex = col:CreateTexture(nil, "OVERLAY")
        tex:SetSize(18, 18)
        tex:SetPoint("TOPLEFT", x0, yy)
        tex:SetTexture(icon)
        local holder = CreateFrame("Frame", nil, col)
        holder:SetAllPoints(tex)
        holder:EnableMouse(true)
        Tip(holder, zh, en)
        return tex
    end

    Label("Interface\\Icons\\INV_Misc_Note_02", "名字", "Name", y)
    local eName = EditField(col, 150, false)
    eName:SetPoint("TOPLEFT", x0 + 28, y + 1)
    BindDraft(eName, "name")
    ui.eName = eName

    y = y - 30
    Label("Interface\\Icons\\INV_Misc_Coin_01", "金币（金）：最少 - 最多", "Gold (g): min - max", y)
    local eGmin = EditField(col, 60, true)
    eGmin:SetPoint("TOPLEFT", x0 + 28, y + 1)
    local eGmax = EditField(col, 60, true)
    eGmax:SetPoint("LEFT", eGmin, "RIGHT", 14, 0)
    BindDraft(eGmin, "gmin")
    BindDraft(eGmax, "gmax")
    ui.eGmin, ui.eGmax = eGmin, eGmax
    ui.goldText = col:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ui.goldText:SetPoint("TOPLEFT", x0 + 28, y - 20)

    y = y - 44
    Label("Interface\\Icons\\Spell_Holy_BorrowedTime", "刷新（秒）：最少 - 最多", "Respawn (s): min - max", y)
    local eRmin = EditField(col, 60, true)
    eRmin:SetPoint("TOPLEFT", x0 + 28, y + 1)
    local eRmax = EditField(col, 60, true)
    eRmax:SetPoint("LEFT", eRmin, "RIGHT", 14, 0)
    BindDraft(eRmin, "rmin")
    BindDraft(eRmax, "rmax")
    ui.eRmin, ui.eRmax = eRmin, eRmax

    y = y - 30
    Label("Interface\\Icons\\INV_Misc_EngGizmos_20", "大小（0.3-4）", "Size (0.3-4)", y)
    local eSize = EditField(col, 60, true)
    eSize:SetPoint("TOPLEFT", x0 + 28, y + 1)
    BindDraft(eSize, "size")
    ui.eSize = eSize

    -- rarity: three coloured gems
    y = y - 30
    Label("Interface\\Icons\\INV_Misc_Gem_Variety_01", "品质", "Quality", y)
    ui.rarityBtns = {}
    for r = 1, 3 do
        local info = RARITY[r]
        local b = IconButton(col, 20, DEFAULT_ICON[r], info.r, info.g, info.b)
        b:SetPoint("TOPLEFT", x0 + 28 + (r - 1) * 30, y + 1)
        b:SetScript("OnClick", function() ui.SetDraft("rarity", r) end)
        Tip(b, info.zh, info.en)
        ui.rarityBtns[r] = b
    end

    -- toggles: active, dungeon gold scaling
    y = y - 32
    local cActive = CreateFrame("CheckButton", nil, col, "UICheckButtonTemplate")
    cActive:SetSize(24, 24)
    cActive:SetPoint("TOPLEFT", x0 - 3, y + 3)
    cActive:SetScript("OnClick", function(self) ui.SetDraft("active", self:GetChecked() and 1 or 0) end)
    local aText = col:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    aText:SetPoint("LEFT", cActive, "RIGHT", 2, 0)
    Bind(aText, "启用", "Active")
    Tip(cActive, "启用这种宝箱", "Chest type active", T("停用后不再刷出新的这种宝箱。", "An inactive type no longer spawns."))
    ui.cActive = cActive

    y = y - 26
    local cScale = CreateFrame("CheckButton", nil, col, "UICheckButtonTemplate")
    cScale:SetSize(24, 24)
    cScale:SetPoint("TOPLEFT", x0 - 3, y + 3)
    cScale:SetScript("OnClick", function(self) ui.SetDraft("dscale", self:GetChecked() and 1 or 0) end)
    local sIcon = col:CreateTexture(nil, "OVERLAY")
    sIcon:SetSize(18, 18)
    sIcon:SetPoint("LEFT", cScale, "RIGHT", 2, 0)
    sIcon:SetTexture("Interface\\Icons\\INV_Misc_GroupNeedMore")
    local sText = col:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sText:SetPoint("LEFT", sIcon, "RIGHT", 4, 0)
    Bind(sText, "副本金币随人数缩放", "Dungeon gold scales")
    Tip(cScale, "副本金币随人数缩放", "Dungeon gold scales with player count",
        "关 / Off：副本里金币整份给开箱的人（默认）。Full gold in dungeons (default).\n" ..
        "开 / On：跟副本缩放模块走，单人五人本只得 1/5。例：单人魔枢 6 金 → 1 金 20 银。\n" ..
        "Follows mod-dungeon-scale: solo in a 5-man gets 1/5.")
    ui.cScale = cScale

    -- Save / Undo for the text boxes (the gems and ticks above save at once)
    local bSave = CreateFrame("Button", nil, col, "UIPanelButtonTemplate")
    bSave:SetSize(96, 24)
    bSave:SetPoint("TOPLEFT", x0 - 3, y - 26)
    Bind(bSave, "保存", "Save")
    bSave:SetScript("OnClick", function() ui.SaveDraft() end)
    Tip(bSave, "保存所有改动", "Save every change",
        T("名字、金币、刷新、大小、外观、品质、两个勾选，改了都要点这里才生效。改过没保存的文字是橙色；格子里按 Enter 也保存；Tab 跳到下一格；Esc 撤销这一格。",
          "Name, gold, respawn, size, appearance, quality and the two ticks all wait for this button. Unsaved text is orange; Enter in a box also saves; Tab goes to the next box; Esc undoes that box."))
    local bUndo = CreateFrame("Button", nil, col, "UIPanelButtonTemplate")
    bUndo:SetSize(64, 24)
    bUndo:SetPoint("LEFT", bSave, "RIGHT", 4, 0)
    Bind(bUndo, "撤销", "Undo")
    bUndo:SetScript("OnClick", function() ui.UndoDraft(nil) end)
    Tip(bUndo, "撤销没保存的修改", "Undo the unsaved changes")
    local dirtyText = col:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    dirtyText:SetPoint("TOPLEFT", bSave, "BOTTOMLEFT", 2, -5)
    ui.bSave, ui.bUndo, ui.dirtyText = bSave, bUndo, dirtyText

    -- loot table area (TREAS2C)
    local lootArea = Panel(col)
    lootArea:SetPoint("TOPLEFT", col, "TOPLEFT", 8, -316)
    lootArea:SetPoint("BOTTOMRIGHT", col, "BOTTOMRIGHT", -8, 8)
    lootArea:SetBackdropColor(0, 0, 0, 0.4)
    Header(lootArea, "Interface\\Icons\\INV_Misc_Bag_08", "掉落表", "Loot table")
    ui.lootArea = lootArea
    BuildLootGrid(lootArea)

    local empty = col:CreateFontString(nil, "OVERLAY", "GameFontDisableLarge")
    empty:SetPoint("CENTER")
    Bind(empty, "← 选一种宝箱", "← Pick a chest type")
    ui.emptyCard = empty

    ui.cardWidgets = { stage, bLook, ui.lookText, bIcon, ui.iconText, eName, eGmin, eGmax, eRmin, eRmax, eSize, cActive, cScale, lootArea, ui.goldText, bSave, bUndo, dirtyText }
end

function ui.RefreshCard()
    local t = Selected()
    local show = t ~= nil
    if ui.cardWidgets then
        for _, w in ipairs(ui.cardWidgets) do if show then w:Show() else w:Hide() end end
    end
    if ui.rarityBtns then
        for _, b in ipairs(ui.rarityBtns) do if show then b:Show() else b:Hide() end end
    end
    ShowIf(ui.emptyCard, not show)
    if not show then
        Bind(ui.cardTitle, "宝箱", "Chest")
        return
    end
    local rar = RARITY[t.rarity] or RARITY[1]
    ui.cardTitle:SetText("|cff" .. rar.hex .. t.name .. "|r  |cff888888" .. t.entry .. "|r")
    local d = state.drafts[t.entry] or {}
    ui.filling = true
    for _, key in ipairs(DRAFT_KEYS) do
        local eb = ui.boxes[key]   -- appearance, quality and the ticks have no text box
        if eb then
            local want = d[key] or ServerText(t, key)
            if not eb:HasFocus() and eb:GetText() ~= want then eb:SetText(want) end
        end
    end
    ui.filling = false
    ui.UpdateDirty()
    ui.goldText:SetText(Money(t.goldMin) .. "  -  " .. Money(t.goldMax))
    ui.cActive:SetChecked(ui.Eff(t, "active") == "1")
    ui.cScale:SetChecked(ui.Eff(t, "dscale") == "1")
    local effRarity = tonumber(ui.Eff(t, "rarity")) or t.rarity
    for r, b in ipairs(ui.rarityBtns) do b:SetAlpha(r == effRarity and 1 or 0.35) end
    ui.lookText:SetText(T("外观", "Display") .. " " .. ui.Eff(t, "display"))
    local iconName = ui.Eff(t, "icon")
    ui.bIcon.icon:SetTexture(IconPath(iconName, effRarity))
    ui.iconText:SetText(T("图标", "Icon") .. " " .. (iconName ~= "" and ShortIcon(iconName) or T("默认", "default")))
    ui.iconFull = iconName

    local dd = state.drafts[t.entry]
    local ok = ui.ShowModel(ui.model, (dd and dd.display and dd.displayModel) or state.models[t.entry])
    if ok then
        ui.model:Show()
        ui.noModel:Hide()
    else
        ui.model:Hide()
        ui.noModel:SetTexture(IconPath(t.icon, t.rarity))
        ui.noModel:Show()
    end
end

-- =========================================================================
-- right column (TREAS2C): tab "Spawns" (where the chests of the chosen type / of the whole world stand)
-- and tab "Item pool" (TREAS2D)
-- =========================================================================
local SP_ROW_H = 42

-- cut a UTF-8 string to `max` characters
local function Cut(s, max)
    s = tostring(s or "")
    local n, i, len = 0, 1, #s
    while i <= len do
        local b = s:byte(i)
        local step = (b >= 240 and 4) or (b >= 224 and 3) or (b >= 192 and 2) or 1
        n = n + 1
        if n > max then return s:sub(1, i - 1) .. ".." end
        i = i + step
    end
    return s
end

local function Clock(sec)
    sec = math.max(0, math.floor(tonumber(sec) or 0))
    return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
end

-- a StaticPopup that opens over the panel (the panel sits in FULLSCREEN_DIALOG), and goes back after
function ui.Popup(which, a1, a2, data)
    local def = StaticPopupDialogs[which]
    if def then
        if which == "REBORN_TREASURE_INPUT" then
            def.button1, def.button2 = T("确定", "OK"), T("取消", "Cancel")
        else
            def.button1, def.button2 = T("是", "Yes"), T("否", "No")
        end
    end
    local dlg = StaticPopup_Show(which, a1, a2, data)
    if dlg then
        dlg:SetFrameStrata("TOOLTIP")
        dlg:Raise()
    end
    return dlg
end

-- run something later (the panel's OnUpdate drives it)
function ui.After(sec, fn)
    state.timers = state.timers or {}
    state.timers[#state.timers + 1] = { t = sec, fn = fn }
end

function ui.RunTimers(elapsed)
    local list = state.timers
    if list and #list > 0 then
        -- the ones that are due run in the order they were added (a long frame can make several due at once: a Save sends
        -- "clear the conditions" and then "add them", and that order matters)
        local due, keep = {}, {}
        for _, tm in ipairs(list) do
            tm.t = tm.t - elapsed
            if tm.t <= 0 then due[#due + 1] = tm else keep[#keep + 1] = tm end
        end
        for i = #list, 1, -1 do list[i] = nil end
        for _, tm in ipairs(keep) do list[#list + 1] = tm end
        for _, tm in ipairs(due) do
            local ok, err = pcall(tm.fn)
            if not ok then DEFAULT_CHAT_FRAME:AddMessage("|cffff3333[RebornTreasure GM] " .. tostring(err) .. "|r") end
        end
    end
    -- the spawn list: ask again every 15 s, redraw every second (the respawn countdown)
    if ui.spawnPane and ui.spawnPane:IsShown() then
        state.pollAcc = (state.pollAcc or 0) + elapsed
        state.redrawAcc = (state.redrawAcc or 0) + elapsed
        if state.pollAcc >= 15 then
            state.pollAcc = 0
            ui.RequestSpawns()
        end
        if state.redrawAcc >= 1 then
            state.redrawAcc = 0
            if ui.RefreshSpawnList then ui.RefreshSpawnList() end
        end
    end
end

function ui.RequestSpawns()
    Cmd("spawns")
    state.pollAcc = 0
end

local function SpawnById(id)
    for _, s in ipairs(state.spawns) do
        if s.id == id then return s end
    end
end

local function SpawnLeft(s)
    local passed = GetTime() - (state.spawnStamp or GetTime())
    return math.max(0, s.left - passed)
end

-- the spawns shown in the list: this chest type's, or every one in the world
local function ShownSpawns()
    local out = {}
    local sel = state.spawnScope == "type" and state.selected or nil
    for _, s in ipairs(state.spawns) do
        if not sel or s.entry == sel then out[#out + 1] = s end
    end
    return out
end

function ui.RefreshSpawnList()
    if not ui.spawnRows then return end
    local list = ShownSpawns()
    local visible = ui.spawnVisible or 0
    state.spawnOffset = math.max(0, math.min(state.spawnOffset or 0, #list - visible))
    for i, row in ipairs(ui.spawnRows) do
        local s = (i <= visible) and list[i + state.spawnOffset]
        if s then
            local t = state.types[s.entry]
            local rar = RARITY[t and t.rarity or 1] or RARITY[1]
            row.s = s
            row.icon:SetTexture(IconPath(t and t.icon or "", t and t.rarity or 1))
            row.rim:SetTexture(rar.r, rar.g, rar.b, 1)
            if state.spawnScope == "all" then
                row.name:SetText("|cff" .. rar.hex .. (t and t.name or tostring(s.entry)) .. "|r  |cffffd100" .. Cut(s.zoneName, 8) .. "|r")
            else
                row.name:SetText("|cffffd100" .. s.zoneName .. "|r" .. (s.comment ~= "" and ("  |cffaaaaaa" .. Cut(s.comment, 10) .. "|r") or ""))
            end
            row.info:SetText(string.format("#%d  %s  |cff888888%.0f, %.0f|r", s.id, Cut(s.mapName, 8), s.x, s.y) ..
                (s.wet and ("  |cff55aaff" .. T("水下", "water") .. "|r") or ""))
            if s.state == 1 then
                row.status:SetText("|cff55dd55" .. T("已刷出", "standing") .. "|r")
            else
                local left = SpawnLeft(s)
                if left > 0 then
                    row.status:SetText("|cffff9933" .. T("等待 ", "wait ") .. Clock(left) .. "|r")
                else
                    row.status:SetText("|cffaaaaaa" .. T("待刷出", "pending") .. "|r")
                end
            end
            row.dist:SetText(s.dist >= 0 and ("|cff888888" .. s.dist .. T("码", "yd") .. "|r") or "")
            if s.hasClue then row.clue:Show() else row.clue:Hide() end
            if s.id == state.spawnSel then row.sel:Show() else row.sel:Hide() end
            row:Show()
        else
            row.s = nil
            row:Hide()
        end
    end
    if ui.spawnCount then
        local scope = state.spawnScope == "type" and (Selected() and Selected().name or "") or T("全世界", "world")
        ui.spawnCount:SetText(string.format("%s  |cff888888%d|r", Cut(scope, 8), #list))
    end
    ui.spawnEmpty:SetText(#list == 0 and (state.spawnsLoaded and T("这里还没有点位。点上面的 + 在你脚下刷一个。", "No spawns here. Click + above to put one at your feet.") or T("读取中…", "Loading…")) or "")
    -- the selected spawn's details
    local s = SpawnById(state.spawnSel)
    if s then
        local t = state.types[s.entry]
        ui.spawnD1:SetText(string.format("|cffffd100#%d|r  %s", s.id, t and t.name or s.entry))
        ui.spawnD2:SetText(string.format("%s · %s", s.mapName, s.zoneName))
        ui.spawnD3:SetText(string.format(T("坐标 %.1f  %.1f  %.1f", "Pos %.1f  %.1f  %.1f"), s.x, s.y, s.z) ..
            (s.dist >= 0 and ("   |cff888888" .. s.dist .. T("码", "yd") .. "|r") or "") ..
            (s.wet and ("   |cff55aaff" .. T("在水下", "under water") .. "|r") or ""))
        ui.spawnD4:SetText(string.format(T("刷新 %d–%d 秒", "Respawn %d–%d s"), s.rmin, s.rmax) ..
            (s.comment ~= "" and ("   " .. Cut(s.comment, 14)) or ""))
        ui.spawnD5:SetText(s.hasClue and ("|cff88ccff" .. T("线索：", "Clue: ") .. "|r" .. Cut(state.clues[s.id] or "", 22)) or "|cff666666" .. T("没有线索", "No clue") .. "|r")
    else
        for _, fs in ipairs({ ui.spawnD1, ui.spawnD2, ui.spawnD3, ui.spawnD4, ui.spawnD5 }) do fs:SetText("") end
        ui.spawnD1:SetText("|cff666666" .. T("点一个点位看详情；右键有更多操作", "Click a spawn for details; right-click for more") .. "|r")
    end
    if ui.bSpAdd then
        if Selected() then ui.bSpAdd:Enable() else ui.bSpAdd:Disable() end
    end
    for key, b in pairs({ type = ui.bScopeType, all = ui.bScopeAll }) do
        if state.spawnScope == key then b:LockHighlight() else b:UnlockHighlight() end
    end
end

-- right-click menu of a spawn
function ui.SpawnMenu(s)
    state.spawnSel = s.id
    ui.RefreshSpawnList()
    ui.spawnMenuFrame = ui.spawnMenuFrame or CreateFrame("Frame", "RebornTreasureGMSpawnMenu", UIParent, "UIDropDownMenuTemplate")
    local t = state.types[s.entry]
    local id = s.id
    local typeList = {}
    for _, entry in ipairs(state.order) do
        local ty = state.types[entry]
        if ty and ty.active then
            local rar = RARITY[ty.rarity] or RARITY[1]
            typeList[#typeList + 1] = { text = "|cff" .. rar.hex .. ty.name .. "|r", checked = (entry == s.entry), func = function()
                Cmd("spawntype " .. id .. " " .. entry)
            end }
        end
    end
    local menu = {
        { text = string.format("#%d  %s", id, t and t.name or s.entry), isTitle = true, notCheckable = true },
        { text = T("传送到这里", "Teleport here"), notCheckable = true, func = function() Cmd("spawngo " .. id) end },
        { text = T("传送并显示宝箱", "Teleport and show the chest"), notCheckable = true, func = function()
            state.pendingShow = id
            Cmd("spawngo " .. id)
        end },
        { text = T("显示宝箱（被捡走了就重新刷出）", "Show the chest (put it back if taken)"), notCheckable = true, func = function()
            Cmd("spawnshow " .. id)
        end },
        { text = T("查看里面有什么", "See what is inside"), notCheckable = true, func = function() ui.ShowContents(s.entry) end },
        { text = T("编辑线索…", "Edit the clue…"), notCheckable = true, func = function()
            ui.Popup("REBORN_TREASURE_INPUT", T("写线索（玩家走近会看到；留空 = 删除线索）", "Clue text (players near it see it; empty = remove)"), nil,
                { default = state.clues[id] or "", fn = function(text) Cmd("spawnclue " .. id .. " " .. CleanText(text)) end })
        end },
        { text = T("编辑备注…", "Edit the note…"), notCheckable = true, func = function()
            ui.Popup("REBORN_TREASURE_INPUT", T("点位备注", "Spawn note"), nil,
                { default = s.comment, fn = function(text) Cmd("spawncomment " .. id .. " " .. CleanText(text)) end })
        end },
        { text = T("设置刷新时间…", "Set respawn time…"), notCheckable = true, func = function()
            ui.Popup("REBORN_TREASURE_INPUT", T("刷新秒数，写两个数：最少 最多（例：300 600）", "Respawn seconds: min max (e.g. 300 600)"), nil,
                { default = s.rmin .. " " .. s.rmax, fn = function(text)
                    local a, b = text:match("(%d+)%D+(%d+)")
                    if not a then a = text:match("(%d+)"); b = a end
                    if a then Cmd("spawnrespawn " .. id .. " " .. a .. " " .. (b or a)) else Status(T("要写数字", "Numbers please"), true) end
                end })
        end },
        { text = T("把点位移到我脚下", "Move the spawn to my feet"), notCheckable = true, func = function() Cmd("spawnhere " .. id) end },
        { text = T("贴地（修正这个点位的高度）", "Snap to the ground"), notCheckable = true, func = function() Cmd("spawnsnap " .. id) end },
        { text = T("贴地：修正全部点位", "Snap every spawn to the ground"), notCheckable = true, func = function() Cmd("spawnsnap 0") end },
        { text = T("改成别的宝箱种类", "Change the chest type"), notCheckable = true, hasArrow = true, menuList = typeList },
        { text = T("复制坐标到聊天框", "Copy the position to chat"), notCheckable = true, func = function()
            ChatFrame_OpenChat(string.format("%s %s (%.1f, %.1f, %.1f)", s.mapName, s.zoneName, s.x, s.y, s.z))
        end },
        { text = "|cffff4040" .. T("删除这个点位", "Delete this spawn") .. "|r", notCheckable = true, func = function()
            ui.Popup("REBORN_TREASURE_SPAWN_DELETE", string.format("#%d  %s", id, s.zoneName), nil, id)
        end },
        { text = T("取消", "Cancel"), notCheckable = true },
    }
    ui.OpenMenu(menu, ui.spawnMenuFrame)
end

local function SetRightTab(which)
    state.rightTab = which
    ShowIf(ui.spawnPane, which == "spawns")
    ShowIf(ui.poolPane, which == "pool")
    if ui.tabSpawns then
        if which == "spawns" then ui.tabSpawns:LockHighlight(); ui.tabPool:UnlockHighlight() else ui.tabPool:LockHighlight(); ui.tabSpawns:UnlockHighlight() end
    end
    if which == "spawns" then
        ui.RefreshSpawnList()
        if ui.main and ui.main:IsShown() then ui.RequestSpawns() end
    elseif which == "pool" and not state.pool.loaded and ui.main and ui.main:IsShown() then
        state.pool.loaded = true
        ui.PoolRequest(0)
    end
end

local function BuildRight(main)
    local col = Panel(main)
    ui.right = col

    local tabSpawns = CreateFrame("Button", nil, col, "UIPanelButtonTemplate")
    tabSpawns:SetSize(92, 22)
    tabSpawns:SetPoint("TOPLEFT", 8, -8)
    Bind(tabSpawns, "点位", "Spawns")
    tabSpawns:SetScript("OnClick", function() SetRightTab("spawns") end)
    Tip(tabSpawns, "点位", "Spawns", T("世界里放了哪些宝箱：位置、状态、传送、显示、删除。", "Where the chests stand: position, state, teleport, show, delete."))
    local tabPool = CreateFrame("Button", nil, col, "UIPanelButtonTemplate")
    tabPool:SetSize(92, 22)
    tabPool:SetPoint("LEFT", tabSpawns, "RIGHT", 4, 0)
    Bind(tabPool, "物品库", "Item pool")
    tabPool:SetScript("OnClick", function() SetRightTab("pool") end)
    ui.tabSpawns, ui.tabPool = tabSpawns, tabPool

    -- ---------------- tab: item pool (TREAS2D)
    local pool = CreateFrame("Frame", nil, col)
    pool:SetPoint("TOPLEFT", 4, -36)
    pool:SetPoint("BOTTOMRIGHT", -4, 4)
    BuildPool(pool)
    ui.poolPane = pool

    -- ---------------- tab: spawns
    local pane = CreateFrame("Frame", nil, col)
    pane:SetPoint("TOPLEFT", 4, -36)
    pane:SetPoint("BOTTOMRIGHT", -4, 4)
    ui.spawnPane = pane

    -- toolbar: scope, add, refresh
    local bType = CreateFrame("Button", nil, pane, "UIPanelButtonTemplate")
    bType:SetSize(78, 20)
    bType:SetPoint("TOPLEFT", 4, -2)
    Bind(bType, "本类型", "This type")
    bType:SetScript("OnClick", function() state.spawnScope = "type"; state.spawnOffset = 0; ui.RefreshSpawnList() end)
    Tip(bType, "只看选中的宝箱种类的点位", "Only the spawns of the selected chest type")
    local bAll = CreateFrame("Button", nil, pane, "UIPanelButtonTemplate")
    bAll:SetSize(78, 20)
    bAll:SetPoint("LEFT", bType, "RIGHT", 2, 0)
    Bind(bAll, "全世界", "World")
    bAll:SetScript("OnClick", function() state.spawnScope = "all"; state.spawnOffset = 0; ui.RefreshSpawnList() end)
    Tip(bAll, "世界里所有的宝箱点位", "Every chest spawn in the world")
    ui.bScopeType, ui.bScopeAll = bType, bAll

    local bRef = IconButton(pane, 20, "Interface\\Icons\\Spell_Holy_BorrowedTime", 0.85, 0.65, 0.15)
    bRef:SetPoint("TOPRIGHT", -6, -3)
    bRef:SetScript("OnClick", function() ui.RequestSpawns() end)
    Tip(bRef, "刷新点位列表", "Refresh the list")
    local bAdd = IconButton(pane, 20, "Interface\\Icons\\Spell_ChargePositive", 0.2, 0.7, 0.25)
    bAdd:SetPoint("RIGHT", bRef, "LEFT", -8, 0)
    bAdd:SetScript("OnClick", function()
        local t = Selected()
        if not t then return end
        SendChatMessage(".treasure add " .. t.entry .. " " .. t.respawnMin, "SAY")
        ui.After(1.5, ui.RequestSpawns)
    end)
    Tip(bAdd, "在我脚下刷一个选中的宝箱", "Put the selected chest at my feet",
        T("用左边选中的种类，在你站的地方放一个新点位。要写线索：右键点位 → 编辑线索。", "Uses the type picked on the left. Add a clue afterwards: right-click the spawn."))
    bAdd.icon:SetTexture("Interface\\Icons\\Spell_ChargePositive")
    ui.bSpAdd = bAdd
    -- the Enable/Disable calls of a plain button do not grey an icon: do it by hand
    function bAdd:Enable() self:SetAlpha(1); self:EnableMouse(true) end
    function bAdd:Disable() self:SetAlpha(0.35); self:EnableMouse(false) end

    ui.spawnCount = pane:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ui.spawnCount:SetPoint("TOPLEFT", bType, "BOTTOMLEFT", 2, -6)

    -- details of the picked spawn, at the bottom
    local detail = CreateFrame("Frame", nil, pane)
    detail:SetPoint("BOTTOMLEFT", 2, 2)
    detail:SetPoint("BOTTOMRIGHT", -2, 2)
    detail:SetHeight(92)
    detail:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    detail:SetBackdropColor(0, 0, 0, 0.5)
    detail:SetBackdropBorderColor(0.5, 0.4, 0.2, 1)
    local last
    for i = 1, 5 do
        local fs = detail:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetPoint("TOPLEFT", 8, -6 - (i - 1) * 16)
        fs:SetPoint("RIGHT", -6, 0)
        fs:SetJustifyH("LEFT")
        ui["spawnD" .. i] = fs
    end

    -- the list
    local list = CreateFrame("Frame", nil, pane)
    list:SetPoint("TOPLEFT", ui.spawnCount, "BOTTOMLEFT", -2, -4)
    list:SetPoint("BOTTOMRIGHT", detail, "TOPRIGHT", 0, 4)
    list:EnableMouseWheel(true)
    list:SetScript("OnMouseWheel", function(_, d) state.spawnOffset = (state.spawnOffset or 0) - d * 3; ui.RefreshSpawnList() end)
    ui.spawnList = list
    ui.spawnRows = {}
    ui.spawnEmpty = list:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    ui.spawnEmpty:SetPoint("CENTER")
    ui.spawnEmpty:SetWidth(200)

    function ui.LayoutSpawnRows()
        local n = math.max(1, math.floor((list:GetHeight() or 0) / SP_ROW_H))
        for i = #ui.spawnRows + 1, n do
            local row = CreateFrame("Button", nil, list)
            row:SetHeight(SP_ROW_H - 3)
            row:SetPoint("TOPLEFT", 0, -(i - 1) * SP_ROW_H)
            row:SetPoint("RIGHT", list, "RIGHT", 0, 0)
            row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            local bg = row:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetTexture(0, 0, 0, 0.35)
            row.sel = row:CreateTexture(nil, "BORDER")
            row.sel:SetAllPoints()
            row.sel:SetTexture(1, 0.82, 0, 0.22)
            local hl = row:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints()
            hl:SetTexture(1, 1, 1, 0.1)
            row.rim = row:CreateTexture(nil, "ARTWORK")
            row.rim:SetSize(30, 30)
            row.rim:SetPoint("LEFT", 5, 0)
            row.icon = row:CreateTexture(nil, "OVERLAY")
            row.icon:SetSize(26, 26)
            row.icon:SetPoint("CENTER", row.rim, "CENTER")
            row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            row.name:SetPoint("TOPLEFT", row.rim, "TOPRIGHT", 6, -1)
            row.name:SetPoint("RIGHT", row, "RIGHT", -64, 0)
            row.name:SetJustifyH("LEFT")
            row.info = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.info:SetPoint("BOTTOMLEFT", row.rim, "BOTTOMRIGHT", 6, 1)
            row.info:SetJustifyH("LEFT")
            row.status = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            row.status:SetPoint("TOPRIGHT", -6, -5)
            row.dist = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.dist:SetPoint("BOTTOMRIGHT", -6, 4)
            row.clue = row:CreateTexture(nil, "OVERLAY")
            row.clue:SetSize(12, 12)
            row.clue:SetPoint("RIGHT", row.dist, "LEFT", -4, 0)
            row.clue:SetTexture("Interface\\Icons\\INV_Misc_Note_01")
            row:SetScript("OnClick", function(self, button)
                if not self.s then return end
                if button == "RightButton" then
                    ui.SpawnMenu(self.s)
                else
                    state.spawnSel = self.s.id
                    ui.RefreshSpawnList()
                end
            end)
            row:SetScript("OnDoubleClick", function(self) if self.s then Cmd("spawngo " .. self.s.id) end end)
            row:SetScript("OnEnter", function(self)
                if not self.s then return end
                GameTooltip:SetOwner(self, "ANCHOR_LEFT")
                GameTooltip:AddLine(string.format("#%d  %s", self.s.id, self.s.zoneName), 1, 0.82, 0)
                GameTooltip:AddLine(string.format("%s  (%.1f, %.1f, %.1f)", self.s.mapName, self.s.x, self.s.y, self.s.z), 0.8, 0.8, 0.8)
                GameTooltip:AddLine(T("右键：传送 / 显示宝箱 / 查看内容 / 线索 / 删除…", "Right-click: teleport / show / contents / clue / delete…"), 0.7, 0.7, 0.7)
                GameTooltip:AddLine(T("双击：传送到这里", "Double-click: teleport here"), 0.7, 0.7, 0.7)
                GameTooltip:Show()
            end)
            row:SetScript("OnLeave", function() GameTooltip:Hide() end)
            ui.spawnRows[i] = row
        end
        ui.spawnVisible = n
        ui.RefreshSpawnList()
    end
    list:SetScript("OnSizeChanged", function() if ui.LayoutSpawnRows then ui.LayoutSpawnRows() end end)

    state.spawnScope = state.spawnScope or "type"
    SetRightTab("spawns")
end

-- =========================================================================
-- icon picker (TREASFIX2): a grid of real icons the server lists
-- =========================================================================
local ICON_COLS, ICON_ROWS, ICON_CELL = 8, 8, 40

local function RefreshIcons()
    if not ui.iconCells then return end
    local list = state.iconsByCat[state.iconCat] or {}
    for key, b in pairs(ui.iconTabs or {}) do
        if key == state.iconCat then b:LockHighlight() else b:UnlockHighlight() end
    end
    local maxRow = math.max(0, math.ceil(#list / ICON_COLS) - ICON_ROWS)
    state.iconRow = math.max(0, math.min(state.iconRow or 0, maxRow))
    local card = Selected()
    local cur = card and ui.Eff(card, "icon") or ""
    for i, cell in ipairs(ui.iconCells) do
        local ic = list[state.iconRow * ICON_COLS + i]
        if ic then
            cell.ic = ic
            cell.tex:SetTexture(IconPath(ic.name, 1))
            if ic.name == cur then cell.sel:Show() else cell.sel:Hide() end
            cell:Show()
        else
            cell.ic = nil
            cell:Hide()
        end
    end
    ui.iconsEmpty:SetText(#list == 0 and (state.iconsByCat[state.iconCat] and T("这一类没有图标", "No icons in this category") or T("读取中…", "Loading…")) or "")
    if ui.iconsCount then
        ui.iconsCount:SetText(#list > 0 and string.format("%d", #list) or "")
    end
end
ui.RefreshIconsNow = RefreshIcons

local function BuildIcons(main)
    local f = CreateFrame("Frame", "RebornTreasureIconPicker", main)
    f:SetSize(ICON_COLS * ICON_CELL + 28, ICON_ROWS * ICON_CELL + 112)
    f:SetPoint("CENTER", UIParent, "CENTER", 120, 0)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true, tileSize = 32, edgeSize = 24,
        insets = { left = 6, right = 6, top = 6, bottom = 6 },
    })
    f:EnableMouse(true)
    f:Hide()
    local solid = f:CreateTexture(nil, "BACKGROUND")
    solid:SetPoint("TOPLEFT", 7, -7)
    solid:SetPoint("BOTTOMRIGHT", -7, 7)
    solid:SetTexture(0.02, 0.02, 0.03, 0.97)
    local drag = CreateFrame("Frame", nil, f)
    drag:SetPoint("TOPLEFT", 6, -4)
    drag:SetPoint("TOPRIGHT", -30, -4)
    drag:SetHeight(28)
    drag:EnableMouse(true)
    drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart", function() f:StartMoving() end)
    drag:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)
    Header(f, "Interface\\Icons\\INV_Box_01", "选择图标", "Pick the icon")
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    ui.iconsCount = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ui.iconsCount:SetPoint("TOPRIGHT", -34, -13)

    -- categories: chests first
    local CATS = { { "chest", "箱子", "Chests" }, { "key", "钥匙", "Keys" }, { "coin", "金币", "Coins" },
                   { "gem", "宝石", "Gems" }, { "bag", "袋子", "Bags" }, { "scroll", "卷轴书", "Scrolls" } }
    ui.iconTabs = {}
    local prev
    for _, c in ipairs(CATS) do
        local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        b:SetSize(math.floor((ICON_COLS * ICON_CELL - 10) / #CATS), 22)
        if prev then b:SetPoint("LEFT", prev, "RIGHT", 2, 0) else b:SetPoint("TOPLEFT", 14, -36) end
        Bind(b, c[2], c[3])
        b:SetScript("OnClick", function()
            state.iconCat = c[1]
            state.iconRow = 0
            if not state.iconsByCat[c[1]] then Cmd("icons " .. c[1]) end
            RefreshIcons()
        end)
        ui.iconTabs[c[1]] = b
        prev = b
    end

    local grid = CreateFrame("Frame", nil, f)
    grid:SetPoint("TOPLEFT", 14, -64)
    grid:SetSize(ICON_COLS * ICON_CELL, ICON_ROWS * ICON_CELL)
    grid:EnableMouseWheel(true)
    grid:SetScript("OnMouseWheel", function(_, delta) state.iconRow = (state.iconRow or 0) - delta; RefreshIcons() end)
    ui.iconCells = {}
    for i = 1, ICON_COLS * ICON_ROWS do
        local cell = CreateFrame("Button", nil, grid)
        cell:SetSize(ICON_CELL - 2, ICON_CELL - 2)
        cell:SetPoint("TOPLEFT", ((i - 1) % ICON_COLS) * ICON_CELL, -math.floor((i - 1) / ICON_COLS) * ICON_CELL)
        cell:RegisterForClicks("LeftButtonUp")
        cell.sel = cell:CreateTexture(nil, "BACKGROUND")      -- the chosen icon: a gold frame around it
        cell.sel:SetPoint("TOPLEFT", -2, 2)
        cell.sel:SetPoint("BOTTOMRIGHT", 2, -2)
        cell.sel:SetTexture(1, 0.82, 0, 1)
        cell.tex = cell:CreateTexture(nil, "ARTWORK")
        cell.tex:SetAllPoints()
        cell.tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        local hl = cell:CreateTexture(nil, "HIGHLIGHT")        -- under the mouse: bright
        hl:SetAllPoints()
        hl:SetTexture(0.45, 0.70, 1.0, 0.45)
        cell:SetScript("OnEnter", function(self)
            if not self.ic then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(self.ic.name, 1, 0.82, 0)
            GameTooltip:Show()
        end)
        cell:SetScript("OnLeave", function() GameTooltip:Hide() end)
        cell:SetScript("OnClick", function(self)
            if self.ic then ui.SetDraft("icon", self.ic.name, true) end
        end)
        ui.iconCells[i] = cell
    end
    ui.iconsEmpty = f:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    ui.iconsEmpty:SetPoint("CENTER", grid, "CENTER")
    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOMLEFT", 14, 14)
    hint:SetPoint("BOTTOMRIGHT", -14, 14)
    hint:SetJustifyH("LEFT")
    Bind(hint, "点一个图标选用（要点“保存”才生效）；滚轮翻页；拖标题移动。", "Click an icon to use it (then Save); wheel to scroll; drag the title to move.")
    ui.iconsFrame = f
    function ui.ToggleIcons()
        if f:IsShown() then f:Hide() return end
        if not Selected() then Status(T("先选一种宝箱", "Pick a chest first"), true) return end
        f:Show()
        f:Raise()
        if not state.iconsByCat[state.iconCat] then Cmd("icons " .. state.iconCat) end
        RefreshIcons()
    end
end

-- =========================================================================
-- what is inside a chest type (opened from the spawn menu)
-- =========================================================================
local function BuildContents(main)
    local f = CreateFrame("Frame", "RebornTreasureContents", main)
    f:SetSize(380, 420)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true, tileSize = 32, edgeSize = 24,
        insets = { left = 6, right = 6, top = 6, bottom = 6 },
    })
    f:EnableMouse(true)
    f:Hide()
    local drag = CreateFrame("Frame", nil, f)
    drag:SetPoint("TOPLEFT", 6, -4)
    drag:SetPoint("TOPRIGHT", -30, -4)
    drag:SetHeight(28)
    drag:EnableMouse(true)
    drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart", function() f:StartMoving() end)
    drag:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)
    ui.contentsTitle = Header(f, "Interface\\Icons\\INV_Misc_Bag_08", "宝箱内容", "Chest contents")
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)

    ui.contentsGold = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    ui.contentsGold:SetPoint("TOPLEFT", 16, -38)
    ui.contentsHint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ui.contentsHint:SetPoint("BOTTOMLEFT", 16, 12)
    Bind(ui.contentsHint, "滚轮翻页。之后的版本在这里直接增删物品。", "Wheel to scroll. Adding and removing items comes next.")

    local list = CreateFrame("Frame", nil, f)
    list:SetPoint("TOPLEFT", 12, -60)
    list:SetPoint("BOTTOMRIGHT", -12, 32)
    list:EnableMouseWheel(true)
    ui.contentsRows = {}
    local ROW = 28
    local visible = 11
    for i = 1, visible do
        local row = CreateFrame("Button", nil, list)
        row:SetHeight(ROW - 2)
        row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW)
        row:SetPoint("RIGHT", list, "RIGHT", 0, 0)
        local bg = row:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture(0, 0, 0, 0.35)
        local hl = row:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetTexture(1, 1, 1, 0.1)
        row.rim = row:CreateTexture(nil, "ARTWORK")
        row.rim:SetSize(24, 24)
        row.rim:SetPoint("LEFT", 3, 0)
        row.icon = row:CreateTexture(nil, "OVERLAY")
        row.icon:SetSize(20, 20)
        row.icon:SetPoint("CENTER", row.rim, "CENTER")
        row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.name:SetPoint("LEFT", row.rim, "RIGHT", 6, 0)
        row.name:SetPoint("RIGHT", row, "RIGHT", -92, 0)
        row.name:SetJustifyH("LEFT")
        row.chance = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.chance:SetPoint("RIGHT", -6, 0)
        row:SetScript("OnEnter", function(self)
            if not self.item then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            ui.ItemTip(self, "ANCHOR_RIGHT", self.item, self.name:GetText() or "", self.q)
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        ui.contentsRows[i] = row
    end
    ui.contentsEmpty = f:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    ui.contentsEmpty:SetPoint("CENTER", list, "CENTER")
    function ui.RefreshContents()
        local items = state.loot.items
        state.loot.offset = math.max(0, math.min(state.loot.offset or 0, #items - visible))
        for i, row in ipairs(ui.contentsRows) do
            local it = items[i + state.loot.offset]
            if it then
                local rar = RARITY_Q[it.q] or RARITY_Q[1]
                row.item = it.item
                row.q = it.q
                row.icon:SetTexture(IconPath(it.icon, 1))
                row.rim:SetTexture(rar[1], rar[2], rar[3], 1)
                local nm = (IsZh() and it.zh ~= "" and it.zh) or it.name
                row.name:SetText("|cff" .. rar[4] .. nm .. "|r" .. ((it.max > 1) and ("  |cffaaaaaa x" .. it.min .. (it.max > it.min and ("-" .. it.max) or "") .. "|r") or ""))
                row.chance:SetText(string.format("%s%%", (it.chance == math.floor(it.chance)) and tostring(math.floor(it.chance)) or string.format("%.1f", it.chance)))
                row:Show()
            else
                row.item = nil
                row:Hide()
            end
        end
        ui.contentsEmpty:SetText(#items == 0 and (state.loot.ready and T("这种宝箱的掉落表是空的，只会给金币。", "The loot table is empty: gold only.") or T("读取中…", "Loading…")) or "")
    end
    list:SetScript("OnMouseWheel", function(_, d) state.loot.offset = (state.loot.offset or 0) - d * 3; ui.RefreshContents() end)
    ui.contentsFrame = f
end

function ui.ShowContents(entry)
    local t = state.types[entry]
    if not ui.contentsFrame then return end
    state.loot = { entry = entry, items = {}, offset = 0, ready = false }
    ui.contentsTitle:SetText(T("宝箱内容", "Contents") .. "  |cffffd100" .. (t and t.name or entry) .. "|r")
    ui.contentsGold:SetText(t and ((T("金币：", "Gold: ")) .. Money(t.goldMin) .. "  -  " .. Money(t.goldMax)) or "")
    ui.contentsFrame:Show()
    ui.contentsFrame:Raise()
    ui.RefreshContents()
    Cmd("loot " .. entry)
end

-- =========================================================================
-- appearance picker (movable, resizable; rows follow its height)
-- =========================================================================
local LOOK_ROW_H = 32   -- bigger rows are easier to hit

local function RefreshLooks()
    if not ui.lookRows then return end
    local total = #state.looks
    local visible = ui.lookVisible or 0
    state.lookOffset = math.max(0, math.min(state.lookOffset, total - visible))
    local t = Selected()
    for i, row in ipairs(ui.lookRows) do
        local look = (i <= visible) and state.looks[i + state.lookOffset]
        if look then
            row.look = look
            local file = (look.model:match("([^\\]+)$") or look.model):gsub("%.[^%.]+$", "")
            row.text:SetText(string.format("|cffffd100%d|r  %s  |cff888888%s|r", look.id, look.name, file))
            if t and tonumber(ui.Eff(t, "display")) == look.id then
                row.sel:Show(); row.mark:Show()
            else
                row.sel:Hide(); row.mark:Hide()
            end
            row:Show()
        else
            row.look = nil
            row:Hide()
        end
    end
    if total == 0 then ui.lookEmpty:Show() else ui.lookEmpty:Hide() end
    if ui.lookCount then
        ui.lookCount:SetText(total > 0 and string.format("%d-%d / %d", state.lookOffset + 1, math.min(total, state.lookOffset + visible), total) or "")
    end
end

ui.RefreshLooksNow = RefreshLooks

local function BuildLooks(main)
    local f = CreateFrame("Frame", "RebornTreasureLookPicker", main)
    f:SetSize(520, 420)
    f:SetPoint("TOPLEFT", main, "TOPRIGHT", -4, 0)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetToplevel(true)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:SetResizable(true)
    if f.SetMinResize then f:SetMinResize(420, 300) end
    if f.SetMaxResize then f:SetMaxResize(1000, 900) end
    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true, tileSize = 32, edgeSize = 24,
        insets = { left = 6, right = 6, top = 6, bottom = 6 },
    })
    f:EnableMouse(true)
    f:Hide()
    local solid = f:CreateTexture(nil, "BACKGROUND")
    solid:SetPoint("TOPLEFT", 7, -7)
    solid:SetPoint("BOTTOMRIGHT", -7, 7)
    solid:SetTexture(0.02, 0.02, 0.03, 0.97)

    -- title strip: drag to move
    local drag = CreateFrame("Frame", nil, f)
    drag:SetPoint("TOPLEFT", 6, -4)
    drag:SetPoint("TOPRIGHT", -30, -4)
    drag:SetHeight(28)
    drag:EnableMouse(true)
    drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart", function() f:StartMoving() end)
    drag:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)
    Header(f, "Interface\\Icons\\INV_Misc_Spyglass_02", "选择外观", "Pick appearance")
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)
    ui.lookCount = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ui.lookCount:SetPoint("TOPRIGHT", -34, -13)

    -- preview on the right
    local stage = CreateFrame("Frame", nil, f)
    stage:SetPoint("TOPRIGHT", -12, -36)
    stage:SetPoint("BOTTOMRIGHT", -12, 34)
    stage:SetWidth(170)
    stage:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    stage:SetBackdropColor(0, 0, 0, 0.6)
    stage:SetBackdropBorderColor(0.8, 0.62, 0.25, 1)
    local preview = CreateFrame("PlayerModel", nil, stage)
    preview:SetPoint("TOPLEFT", 4, -4)
    preview:SetPoint("BOTTOMRIGHT", -4, 4)
    preview:SetFrameLevel(stage:GetFrameLevel() + 2)
    preview.facing = 0.6
    preview.zoom = 1
    preview:SetScript("OnUpdate", function(self, e) self.facing = self.facing + e * 0.6; pcall(self.SetFacing, self, self.facing) end)
    preview:Hide()
    ui.lookPreview = preview

    -- list on the left
    local list = CreateFrame("Frame", nil, f)
    list:SetPoint("TOPLEFT", 12, -36)
    list:SetPoint("BOTTOMRIGHT", stage, "BOTTOMLEFT", -8, 0)
    list:EnableMouseWheel(true)
    list:SetScript("OnMouseWheel", function(_, d) state.lookOffset = state.lookOffset - d * 3; RefreshLooks() end)
    ui.lookRows = {}

    local function LayoutLookRows()
        local n = math.max(1, math.floor((list:GetHeight() or 0) / LOOK_ROW_H))
        for i = #ui.lookRows + 1, n do
            local row = CreateFrame("Button", nil, list)
            row:SetHeight(LOOK_ROW_H - 2)
            row:SetPoint("TOPLEFT", 0, -(i - 1) * LOOK_ROW_H)
            row:SetPoint("RIGHT", list, "RIGHT", 0, 0)
            row:RegisterForClicks("LeftButtonUp")
            local bg = row:CreateTexture(nil, "BACKGROUND")
            bg:SetAllPoints()
            bg:SetTexture(0.10, 0.10, 0.12, 0.9)
            -- the CHOSEN one (the card's appearance): a gold bar on the left and a gold tint
            row.sel = row:CreateTexture(nil, "BORDER")
            row.sel:SetAllPoints()
            row.sel:SetTexture(1, 0.82, 0, 0.30)
            row.mark = row:CreateTexture(nil, "ARTWORK")
            row.mark:SetWidth(5)
            row.mark:SetPoint("TOPLEFT", 0, 0)
            row.mark:SetPoint("BOTTOMLEFT", 0, 0)
            row.mark:SetTexture(1, 0.82, 0, 1)
            -- the one UNDER THE MOUSE: bright blue-white, clearly another colour
            local hl = row:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints()
            hl:SetTexture(0.45, 0.70, 1.0, 0.38)
            row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            row.text:SetPoint("LEFT", 10, 0)
            row.text:SetPoint("RIGHT", -4, 0)
            row.text:SetJustifyH("LEFT")
            row:SetScript("OnEnter", function(self)
                if self.look then
                    if ui.ShowModel(preview, self.look.model) then preview:Show() else preview:Hide() end
                end
            end)
            -- leaving a row: the preview goes back to the chosen appearance, like the highlight
            row:SetScript("OnLeave", function()
                local card = Selected()
                local dd = card and state.drafts[card.entry]
                local path = card and ((dd and dd.display and dd.displayModel) or state.models[card.entry])
                if path and ui.ShowModel(preview, path) then preview:Show() else preview:Hide() end
            end)
            row:SetScript("OnClick", function(self)
                if self.look then
                    ui.SetDraft("display", self.look.id, self.look.model)
                    ui.AutoIcon(self.look)
                end
            end)
            ui.lookRows[i] = row
        end
        ui.lookVisible = n
        RefreshLooks()
    end

    ui.lookEmpty = f:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    ui.lookEmpty:SetPoint("CENTER", list, "CENTER")
    Bind(ui.lookEmpty, "读取中…", "Loading…")
    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOMLEFT", 14, 13)
    hint:SetPoint("BOTTOMRIGHT", -34, 13)
    hint:SetJustifyH("LEFT")
    Bind(hint, "停在一行上预览，点击使用；滚轮翻页；拖标题移动，拖右下角缩放。", "Hover to preview, click to use; wheel to scroll; drag the title to move, the corner to resize.")

    local grip = CreateFrame("Button", nil, f)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -8, 8)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnMouseDown", function() f:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp", function() f:StopMovingOrSizing(); LayoutLookRows() end)
    f:SetScript("OnSizeChanged", function() LayoutLookRows() end)

    ui.looksFrame = f
    function ui.ToggleLooks()
        if f:IsShown() then f:Hide() return end
        if not Selected() then Status(T("先选一种宝箱", "Pick a chest first"), true) return end
        f:Show()
        f:Raise()
        LayoutLookRows()
        if #state.looks == 0 then Cmd("looks") end
        RefreshLooks()
    end
end

-- the language switch: every bound text again, then every list and card that builds its own text
function ui.ApplyLang()
    for _, b in ipairs(binds) do
        b.obj:SetText(b.fn and b.fn() or T(b.zh, b.en))
    end
    if ui.langLabel then ui.langLabel:SetText(IsZh() and "EN" or "中文") end
    if ui.tabSpawns then
        ui.tabSpawns:SetText(T("点位", "Spawns"))
        ui.tabPool:SetText(T("物品库", "Item pool"))
    end
    RefreshList()
    if ui.RefreshCard then ui.RefreshCard() end
    if ui.UpdateDirty then ui.UpdateDirty() end
    if ui.RefreshSpawnList then ui.RefreshSpawnList() end
    if ui.RefreshContents then ui.RefreshContents() end
    if ui.lookRows then RefreshLooks() end
    Status(T("语言已切换", "Language switched"))
end

-- =========================================================================
-- main frame
-- =========================================================================
local function Layout()
    local main = ui.main
    if not main or not ui.left then return end
    local w = main:GetWidth()
    local inner = w - 24
    local lw = math.floor(inner * 0.27)
    local rw = math.floor(inner * 0.26)
    ui.left:ClearAllPoints()
    ui.left:SetPoint("TOPLEFT", 12, -44)
    ui.left:SetPoint("BOTTOMLEFT", 12, 30)
    ui.left:SetWidth(lw)
    ui.right:ClearAllPoints()
    ui.right:SetPoint("TOPRIGHT", -12, -44)
    ui.right:SetPoint("BOTTOMRIGHT", -12, 30)
    ui.right:SetWidth(rw)
    ui.middle:ClearAllPoints()
    ui.middle:SetPoint("TOPLEFT", ui.left, "TOPRIGHT", 6, 0)
    ui.middle:SetPoint("BOTTOMRIGHT", ui.right, "BOTTOMLEFT", -6, 0)
    if ui.LayoutRows then ui.LayoutRows() end
    if ui.LayoutSpawnRows then ui.LayoutSpawnRows() end
    if ui.LayoutLoot then ui.LayoutLoot() end
    if ui.LayoutPool then ui.LayoutPool() end
end

local function SaveGeometry()
    local main = ui.main
    RebornTreasureDB = RebornTreasureDB or {}
    local point, _, relPoint, x, y = main:GetPoint(1)
    RebornTreasureDB.gm = { point = point, relPoint = relPoint, x = x, y = y, w = main:GetWidth(), h = main:GetHeight() }
end

local function BuildMain()
    local main = CreateFrame("Frame", "RebornTreasureGMFrame", UIParent)
    ui.main = main
    main:SetSize(980, 600)
    main:SetPoint("CENTER")
    main:SetFrameStrata("FULLSCREEN_DIALOG")
    main:SetToplevel(true)
    main:SetMovable(true)
    main:SetResizable(true)
    if main.SetMinResize then main:SetMinResize(900, 540) end
    if main.SetMaxResize then main:SetMaxResize(1600, 1000) end
    main:SetClampedToScreen(true)
    main:EnableMouse(true)
    main:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true, tileSize = 32, edgeSize = 28,
        insets = { left = 8, right = 8, top = 8, bottom = 8 },
    })
    main:Hide()
    tinsert(UISpecialFrames, "RebornTreasureGMFrame")

    -- title bar (drag to move)
    local bar = CreateFrame("Frame", nil, main)
    bar:SetPoint("TOPLEFT", 10, -8)
    bar:SetPoint("TOPRIGHT", -96, -8)
    bar:SetHeight(32)
    bar:EnableMouse(true)
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", function() main:StartMoving() end)
    bar:SetScript("OnDragStop", function() main:StopMovingOrSizing(); SaveGeometry() end)
    local crest = bar:CreateTexture(nil, "OVERLAY")
    crest:SetSize(28, 28)
    crest:SetPoint("LEFT", 2, 0)
    crest:SetTexture("Interface\\Icons\\INV_Misc_Bag_11")
    local title = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", crest, "RIGHT", 8, 0)
    local verText = bar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    verText:SetPoint("LEFT", title, "RIGHT", 10, -2)
    verText:SetText("v" .. PANEL_VERSION)
    BindFn(title, function() return "|cffffd100" .. T("宝箱管理", "Treasure GM") .. "|r  |cff888888" .. T("Treasure GM", "宝箱管理") .. "|r" end)

    local close = CreateFrame("Button", nil, main, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)

    local langBtn = CreateFrame("Button", nil, main)
    langBtn:SetSize(54, 22)
    langBtn:SetPoint("TOPRIGHT", -44, -10)
    langBtn:SetFrameLevel(main:GetFrameLevel() + 10)
    langBtn:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    langBtn:SetBackdropColor(0.25, 0.17, 0.04, 1)
    langBtn:SetBackdropBorderColor(0.85, 0.65, 0.15, 1)
    local langHl = langBtn:CreateTexture(nil, "HIGHLIGHT")
    langHl:SetPoint("TOPLEFT", 3, -3)
    langHl:SetPoint("BOTTOMRIGHT", -3, 3)
    langHl:SetTexture(1, 1, 1, 0.18)
    ui.langLabel = langBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ui.langLabel:SetPoint("CENTER", 0, 0)
    ui.langLabel:SetText(IsZh() and "EN" or "中文")
    langBtn:SetScript("OnClick", function()
        RebornTreasureDB = RebornTreasureDB or {}
        RebornTreasureDB.lang = IsZh() and "en" or "zh"
        local ok, err = pcall(ui.ApplyLang)
        if not ok then DEFAULT_CHAT_FRAME:AddMessage("|cffff3333[RebornTreasure GM] language: " .. tostring(err) .. "|r") end
    end)
    Tip(langBtn, "切换语言", "Switch language", "中文 / English")
    ui.langBtn = langBtn

    -- status line + resize grip
    ui.status = main:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ui.status:SetPoint("BOTTOMLEFT", 16, 12)
    ui.status:SetPoint("BOTTOMRIGHT", -40, 12)
    ui.status:SetJustifyH("LEFT")

    local grip = CreateFrame("Button", nil, main)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -8, 8)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnMouseDown", function() main:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp", function() main:StopMovingOrSizing(); SaveGeometry(); Layout() end)
    Tip(grip, "拖动缩放", "Drag to resize")

    main:SetScript("OnMouseDown", function() CloseDropDownMenus() end)
    main:SetScript("OnSizeChanged", function() Layout() end)
    main:SetScript("OnShow", function(self)
        self:Raise()
        Status(T("连接服务端…", "Contacting the server…"))
        state.online = false
        Cmd("ping")
        Cmd("types")
        ui.After(0.7, ui.RequestSpawns)
        self.waitPong = 3
    end)
    main:SetScript("OnUpdate", function(self, elapsed)
        if ui.RunTimers then ui.RunTimers(elapsed) end
        if self.waitPong then
            self.waitPong = self.waitPong - elapsed
            if self.waitPong <= 0 then
                self.waitPong = nil
                if not state.online then
                    Status(T("服务端没有回应：需要 GM 权限，且服务端装了 TREAS2B。", "No answer: needs a GM account and the TREAS2B server build."), true)
                end
            end
        end
    end)
    main:SetScript("OnHide", function()
        if ui.looksFrame then ui.looksFrame:Hide() end
        if ui.contentsFrame then ui.contentsFrame:Hide() end
        if ui.iconsFrame then ui.iconsFrame:Hide() end
        if ui.lootEditor then ui.lootEditor:Hide() end
        if ui.ghost then ui.ghost:Hide() end
    end)
end

local function RestoreGeometry()
    local g = RebornTreasureDB and RebornTreasureDB.gm
    if not g then return end
    ui.main:ClearAllPoints()
    ui.main:SetPoint(g.point or "CENTER", UIParent, g.relPoint or "CENTER", g.x or 0, g.y or 0)
    if g.w and g.h then ui.main:SetSize(math.max(900, g.w), math.max(540, g.h)) end
end

-- =========================================================================
-- server messages
-- =========================================================================
local function OnServer(msg)
    local f = Split(msg)
    local kind = f[1]
    if kind == "PONG" then
        state.online = true
        if f[2] == "1" then Status(T("已连接", "Connected")) else Status(T("服务端没导入宝箱的 SQL", "The treasure SQL is not imported"), true) end
    elseif kind == "TY_START" then
        wipe(state.types)
        wipe(state.models)
    elseif kind == "TY" then
        local entry = tonumber(f[2])
        if entry then
            state.types[entry] = {
                entry = entry, name = f[3] or "", icon = f[4] or "", display = tonumber(f[5]) or 0,
                size = tonumber(f[6]) or 1, goldMin = tonumber(f[7]) or 0, goldMax = tonumber(f[8]) or 0,
                rarity = tonumber(f[9]) or 1, respawnMin = tonumber(f[10]) or 300, respawnMax = tonumber(f[11]) or 600,
                active = f[12] == "1", dscale = f[13] == "1",
            }
            SortTypes()
            RefreshList()
            if entry == state.selected then ui.RefreshCard() end
        end
    elseif kind == "TYM" then
        local entry = tonumber(f[2])
        if entry then
            state.models[entry] = f[3]
            if entry == state.selected then ui.RefreshCard() end
        end
    elseif kind == "TY_END" then
        SortTypes()
        if type(state.pendingSelect) == "number" and state.types[state.pendingSelect] then
            state.selected = state.pendingSelect
            state.pendingSelect = nil
        elseif not (state.selected and state.types[state.selected]) then
            state.selected = state.order[1]
        end
        RefreshList()
        ui.RefreshCard()
        ui.RefreshSpawnList()
        ui.RequestLootIfNeeded()
        ui.RefreshLoot()
    elseif kind == "SP_START" then
        state.spawnsNew = {}
        state.cluesNew = {}
    elseif kind == "SP" then
        if state.spawnsNew then
            local s = {
                id = tonumber(f[2]) or 0, entry = tonumber(f[3]) or 0, mapId = tonumber(f[4]) or 0, mapName = f[5] or "?",
                zoneId = tonumber(f[6]) or 0, zoneName = f[7] or "?", x = tonumber(f[8]) or 0, y = tonumber(f[9]) or 0, z = tonumber(f[10]) or 0,
                state = tonumber(f[11]) or 0, left = tonumber(f[12]) or 0, rmin = tonumber(f[13]) or 0, rmax = tonumber(f[14]) or 0,
                dist = tonumber(f[15]) or -1, hasClue = f[16] == "1", wet = f[17] == "1", comment = f[18] or "",
            }
            state.spawnsNew[#state.spawnsNew + 1] = s
        end
    elseif kind == "SPC" then
        if state.cluesNew then state.cluesNew[tonumber(f[2]) or 0] = f[3] or "" end
    elseif kind == "SP_END" then
        if state.spawnsNew then
            state.spawns, state.clues = state.spawnsNew, state.cluesNew or {}
            state.spawnsNew, state.cluesNew = nil, nil
            state.spawnStamp = GetTime()
            state.spawnsLoaded = true
            wipe(state.spawnCount)
            for _, s in ipairs(state.spawns) do state.spawnCount[s.entry] = (state.spawnCount[s.entry] or 0) + 1 end
            if state.spawnSel and not SpawnById(state.spawnSel) then state.spawnSel = nil end
            RefreshList()
            ui.RefreshSpawnList()
        end
    elseif kind == "LT_START" then
        local entry = tonumber(f[2])
        state.lootNew[entry or 0] = {}
        if entry == state.loot.entry then state.loot.items = {}; state.loot.ready = false end
    elseif kind == "LT" then
        local entry = tonumber(f[2])
        local line = {
            item = tonumber(f[3]) or 0, chance = tonumber(f[4]) or 0, min = tonumber(f[5]) or 1, max = tonumber(f[6]) or 1,
            group = tonumber(f[7]) or 0, q = tonumber(f[8]) or 1, quest = f[9] == "1", nconds = tonumber(f[10]) or 0,
            icon = f[11] or "", name = f[12] or "", zh = f[13] or "",
        }
        local list = state.lootNew[entry or 0]
        if list then list[#list + 1] = line end
        if entry == state.loot.entry then state.loot.items[#state.loot.items + 1] = line end
    elseif kind == "LT_END" then
        local entry = tonumber(f[2])
        if entry and state.lootNew[entry] then
            state.lootByType[entry] = state.lootNew[entry]
            state.lootNew[entry] = nil
        end
        if entry == state.loot.entry then
            state.loot.ready = true
            if ui.RefreshContents then ui.RefreshContents() end
        end
        ui.RefreshLoot()
        ui.RefreshPool()
    elseif kind == "CD_START" then
        state.cdNew = { entry = tonumber(f[2]), item = tonumber(f[3]), list = {} }
    elseif kind == "CD" then
        if state.cdNew then
            state.cdNew.list[#state.cdNew.list + 1] = { type = tonumber(f[4]) or 0, neg = tonumber(f[5]) or 0,
                v1 = tonumber(f[6]) or 0, v2 = tonumber(f[7]) or 0, v3 = tonumber(f[8]) or 0 }
        end
    elseif kind == "CD_END" then
        local n = state.cdNew
        state.cdNew = nil
        if n then
            for _, list in ipairs({ state.lootByType[n.entry] or {}, state.lootWork[n.entry] or {} }) do
                for _, it in ipairs(list) do
                    if it.item == n.item then
                        it.conds, it.condsBase = CopyConds(n.list), CopyConds(n.list)
                    end
                end
            end
            local ed = ui.lootEditor
            if ed and ed.editing and ed.editing.entry == n.entry and ed.editing.item.item == n.item and ed.loading then
                ed.conds, ed.loading = CopyConds(n.list), false
                ui.RefreshCondRows()
            end
        end
    elseif kind == "QS_START" then
        state.qsNew = {}
    elseif kind == "QS" then
        if state.qsNew then
            local id = tonumber(f[2]) or 0
            state.qsNew[#state.qsNew + 1] = { id = id, level = tonumber(f[3]) or 0, title = f[4] or "", zh = f[5] or "" }
            state.questTitle[id] = { en = f[4] or "", zh = f[5] or "" }
        end
    elseif kind == "QS_END" then
        local list = state.qsNew or {}
        state.qsNew = nil
        local pick = state.questPick
        state.questPick = nil
        if pick then
            if #list == 0 then
                Status(T("没有找到这个任务", "No such quest found"), true)
            elseif #list == 1 then
                pick(list[1].id)
            else
                local menu = { { text = T("选一个任务", "Pick a quest"), isTitle = true, notCheckable = true } }
                for _, q in ipairs(list) do
                    menu[#menu + 1] = { text = string.format("#%d  [%d]  %s", q.id, q.level, (IsZh() and q.zh ~= "" and q.zh) or q.title),
                                        notCheckable = true, func = function() pick(q.id) end }
                end
                menu[#menu + 1] = { text = T("取消", "Cancel"), notCheckable = true }
                ui.questMenu = ui.questMenu or CreateFrame("Frame", "RebornTreasureGMQuestMenu", UIParent, "UIDropDownMenuTemplate")
                ui.OpenMenu(menu, ui.questMenu)
            end
        end
        if ui.RefreshCondRows then ui.RefreshCondRows() end
    elseif kind == "QI" then
        state.qiNew = { id = tonumber(f[2]) or 0, level = tonumber(f[3]) or 0, title = f[4] or "", zh = f[5] or "", items = {} }
        state.questTitle[state.qiNew.id] = { en = f[4] or "", zh = f[5] or "" }
    elseif kind == "QIT" then
        if state.qiNew then
            state.qiNew.items[#state.qiNew.items + 1] = { item = tonumber(f[2]) or 0, count = tonumber(f[3]) or 1, q = tonumber(f[4]) or 1,
                icon = f[5] or "", name = f[6] or "", zh = f[7] or "" }
        end
    elseif kind == "QI_END" then
        local info = state.qiNew
        state.qiNew = nil
        if info and state.qiWizard then
            state.qiWizard = nil
            ui.ApplyQuestInfo(info)
        end
    elseif kind == "IT_START" then
        state.poolNew = { cat = f[2], page = tonumber(f[3]) or 0, items = {} }
    elseif kind == "IT" then
        if state.poolNew then
            state.poolNew.items[#state.poolNew.items + 1] = {
                id = tonumber(f[2]) or 0, q = tonumber(f[3]) or 1, icon = f[7] or "", name = f[8] or "", zh = f[9] or "",
            }
        end
    elseif kind == "IT_END" then
        local n = state.poolNew
        state.poolNew = nil
        if n and n.cat == state.pool.cat and n.page == state.pool.page then
            state.pool.items = n.items
            state.pool.more = f[3] == "1"
            state.pool.loading = false
            state.poolOffset = 0
        end
        ui.RefreshPool()
    elseif kind == "IC_START" then
        state.iconNew, state.iconNewCat = {}, f[2] or "chest"
    elseif kind == "IC" then
        if state.iconNew then state.iconNew[#state.iconNew + 1] = { name = f[2] or "" } end
    elseif kind == "IC_END" then
        if state.iconNew then
            state.iconsByCat[state.iconNewCat or "chest"] = state.iconNew
            state.iconNew = nil
        end
        if ui.RefreshIconsNow then ui.RefreshIconsNow() end
    elseif kind == "LK_START" then
        wipe(state.looks)
    elseif kind == "LK" then
        state.looks[#state.looks + 1] = { id = tonumber(f[2]) or 0, model = f[3] or "", name = f[4] or "" }
    elseif kind == "LK_END" then
        RefreshLooks()
    elseif kind == "OK" then
        local what = f[2]
        if (what == "typenew" or what == "typecopy") and tonumber(f[3]) then
            state.pendingSelect = tonumber(f[3])
        end
        local names = { typenew = T("已新建", "Created"), typecopy = T("已复制", "Copied"), typedel = T("已删除", "Deleted"), typeset = T("已保存", "Saved"),
            spawngo = T("已传送", "Teleported"), spawnshow = T("宝箱已显示", "Chest shown"), spawndel = T("点位已删除", "Spawn deleted"),
            spawnhere = T("点位已移到脚下", "Spawn moved here"), spawnrespawn = T("刷新时间已保存", "Respawn saved"),
            spawncomment = T("备注已保存", "Note saved"), spawnclue = T("线索已保存", "Clue saved"), spawntype = T("种类已改", "Type changed"),
            lootset = T("掉落已保存", "Loot saved"), lootdel = T("已从掉落表删除", "Removed from the loot table"),
            lootcondadd = T("条件已保存", "Condition saved"), lootcondclr = T("条件已清除", "Conditions cleared"),
            questadd = T("已接任务", "Quest given"), questdel = T("已去掉任务", "Quest taken away") }
        Status((names[what] or what) .. (f[3] and ("  " .. f[3]) or ""))
        if what == "spawnsnap" then
            Status(string.format(T("贴地：移动 %s 个，在水下 %s 个，没处理 %s 个（地图没加载）", "Snapped: %s moved, %s under water, %s skipped (map not loaded)"),
                f[4] or "0", f[5] or "0", f[6] or "0"))
        end
        if what == "typeset" then RefreshLooks() end
        if what == "lootset" or what == "lootdel" or what == "lootcondadd" or what == "lootcondclr" then
            Status(T("掉落表已保存", "Loot table saved") .. "  " .. (f[4] or ""))
            local entry = tonumber(f[3])
            if entry and not state.lootReread then
                state.lootReread = true   -- one read after the whole burst of answers
                ui.After(0.8, function()
                    state.lootReread = nil
                    ui.RequestLoot(entry)
                end)
            end
        end
        if what:sub(1, 5) == "spawn" then
            -- teleport and show: wait for the new map to load, then ask for the chest
            if what == "spawngo" and state.pendingShow == tonumber(f[3]) then
                local id = state.pendingShow
                state.pendingShow = nil
                ui.After(3, function() Cmd("spawnshow " .. id) end)
            end
            ui.After(0.6, ui.RequestSpawns)
        end
    elseif kind == "ERR" then
        Status(f[2] or "?", true)
        UIErrorsFrame:AddMessage(f[2] or "?", 1, 0.2, 0.2)
        state.pendingSelect = nil
        state.pendingShow = nil
        if ui.RefreshCard then ui.RefreshCard() end
    end
end

-- =========================================================================
-- build (each stage guarded, a failure is shown in red instead of a silent broken panel)
-- =========================================================================
local built = false
local function Build()
    if built then return true end
    local stages = {
        { "main", BuildMain },
        { "left", function() BuildLeft(ui.main) end },
        { "middle", function() BuildMiddle(ui.main) end },
        { "right", function() BuildRight(ui.main) end },
        { "looks", function() BuildLooks(ui.main) end },
        { "contents", function() BuildContents(ui.main) end },
        { "icons", function() BuildIcons(ui.main) end },
        { "lootedit", function() BuildLootEditor(ui.main) end },
        { "layout", function() RestoreGeometry(); Layout(); ui.RefreshCard() end },
    }
    for _, s in ipairs(stages) do
        local ok, err = pcall(s[2])
        if not ok then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff3333[RebornTreasure GM] build failed at " .. s[1] .. ": " .. tostring(err) .. "|r")
            return false
        end
    end
    built = true
    return true
end

local function Toggle()
    if not Build() then return end
    if ui.main:IsShown() then ui.main:Hide() else ui.main:Show() end
end

-- the popups are raised over the panel by ui.Popup; they go back to normal when they close
local function PopupBack(self) self:SetFrameStrata("DIALOG") end

StaticPopupDialogs["REBORN_TREASURE_DELETE"] = {
    text = "删除宝箱种类“%s”？掉落表一起删除。\nDelete this chest type and its loot table?",
    button1 = YES,
    button2 = NO,
    OnAccept = function(_, entry) if entry then Cmd("typedel " .. entry) end end,
    OnHide = PopupBack,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

StaticPopupDialogs["REBORN_TREASURE_SPAWN_DELETE"] = {
    text = "删除这个宝箱点位 %s？世界里的宝箱一起消失。\nDelete this spawn? The chest in the world goes too.",
    button1 = YES,
    button2 = NO,
    OnAccept = function(_, id) if id then Cmd("spawndel " .. id) end end,
    OnHide = PopupBack,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

StaticPopupDialogs["REBORN_TREASURE_INPUT"] = {
    text = "%s",
    button1 = ACCEPT,
    button2 = CANCEL,
    hasEditBox = 1,
    maxLetters = 120,
    OnShow = function(self)
        local d = self.data
        self.editBox:SetText(d and d.default or "")
        self.editBox:HighlightText()
        self.editBox:SetFocus()
    end,
    OnAccept = function(self, d)
        if d and d.fn then d.fn(self.editBox:GetText() or "") end
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        local d = parent.data
        parent:Hide()
        if d and d.fn then d.fn(self:GetText() or "") end
    end,
    EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
    OnHide = PopupBack,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

local events = CreateFrame("Frame")
events:RegisterEvent("CHAT_MSG_ADDON")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(_, event, prefix, msg)
    if event == "CHAT_MSG_ADDON" then
        if prefix ~= ADDON_PREFIX or type(msg) ~= "string" or not built then return end
        local ok, err = pcall(OnServer, msg)
        if not ok then DEFAULT_CHAT_FRAME:AddMessage("|cffff3333[RebornTreasure GM] " .. tostring(err) .. "|r") end
    elseif event == "PLAYER_LOGIN" then
        -- a GM button next to the guide panel's title
        local guide = _G["RebornTreasureMainFrame"]
        if guide then
            local b = IconButton(guide, 22, "Interface\\Icons\\INV_Misc_Bag_11", 0.85, 0.65, 0.15)
            b:SetPoint("TOPLEFT", 14, -12)
            b:SetScript("OnClick", Toggle)
            Tip(b, "宝箱管理（GM）", "Treasure GM panel", "/rtgm")
        end
    end
end)

SLASH_REBORNTREASUREGM1 = "/rtgm"
SlashCmdList["REBORNTREASUREGM"] = Toggle
