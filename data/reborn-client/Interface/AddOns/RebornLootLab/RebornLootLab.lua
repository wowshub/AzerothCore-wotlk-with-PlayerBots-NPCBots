-- =========================================================================
-- RebornLootLab 掉落工坊 (阶段 LAB2: 浏览 + 编辑 / 撤销 / 还原官方)
-- 左 = 来源 (怪物 / 游戏物件 / 钓鱼 ... 的页签、筛选、列表), 中 = 掉落表 / 模拟掉落, 右 = 物品反查 ("谁掉落它")
-- 和服务端的对话: 发 ".lootlab ui ..." (只有 GM 能执行), 收前缀 "LL" 的插件消息
-- 打开: /lootlab 或 /lab
-- 这一版不改任何数据库内容.
-- =========================================================================

local ADDON_PREFIX = "LL"
local PANEL_VERSION = (GetAddOnMetadata and GetAddOnMetadata("RebornLootLab", "Version")) or "2.2.0"   -- the title shows the .toc version
local SIM_RUNS = 1000
local PAGE_ROWS = 16

local function IsZh()
    local db = RebornLootLabDB
    if db and db.lang then return db.lang == "zh" end
    if RebornTreasureDB and RebornTreasureDB.lang then return RebornTreasureDB.lang == "zh" end
    return true
end
local function T(zh, en) return IsZh() and zh or en end

local binds = {}
local function Bind(obj, zh, en)
    binds[#binds + 1] = { obj = obj, zh = zh, en = en }
    obj:SetText(T(zh, en))
end

-- item quality: r, g, b, hex (this client has no ITEM_QUALITY_COLORS[7] / [8], so the panel has its own)
local QC = {
    [0] = { 0.62, 0.62, 0.62, "9d9d9d" }, [1] = { 1, 1, 1, "ffffff" }, [2] = { 0.12, 1, 0, "1eff00" },
    [3] = { 0, 0.44, 0.87, "0070dd" }, [4] = { 0.64, 0.21, 0.93, "a335ee" }, [5] = { 1, 0.5, 0, "ff8000" },
    [6] = { 0.9, 0.8, 0.5, "e6cc80" }, [7] = { 0.9, 0.8, 0.5, "e6cc80" },
}
local function QCol(q) return QC[tonumber(q) or 1] or QC[1] end

local state = {
    kinds = {}, kindOrder = {}, kind = "creature",
    maps = {}, rank = -1, map = -1, search = "", page = 0, more = false,
    sources = {}, sel = nil, view = "loot",
    loot = {}, lootReady = false, users = { total = 0, list = {} },
    sim = nil, simBusy = false,
    items = {}, itemPage = 0, itemMore = false, itemText = "", item = nil,
    who = nil, rightMode = "items",
    picks = {}, pickAnchor = nil, batch = nil,   -- LAB3C2: several items picked in the search list
    canEdit = false, editLocked = false, editEnabled = false, editMode = false, log = {},
}
local ui = {}
local built = false

local function Cmd(text) SendChatMessage(".lootlab ui " .. text, "SAY") end

local function Split(msg)
    local out = {}
    for field in string.gmatch(msg .. "\t", "([^\t]*)\t") do out[#out + 1] = field end
    return out
end

local function Pick(zh, name)
    zh = zh or ""
    if IsZh() and zh ~= "" then return zh end
    if name and name ~= "" then return name end
    return zh
end

local function Status(text, isError)
    if not ui.status then return end
    ui.status:SetText(text or "")
    if isError then ui.status:SetTextColor(1, 0.25, 0.25) else ui.status:SetTextColor(0.4, 1, 0.4) end
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

local function EditField(parent, width)
    local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    eb:SetSize(width, 20)
    eb:SetAutoFocus(false)
    eb:SetFontObject("ChatFontNormal")
    eb:SetMaxLetters(40)
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return eb
end

local function Button(parent, w, zh, en, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w, 22)
    Bind(b, zh, en)
    b:SetScript("OnClick", onClick)
    return b
end

-- a drop-down menu over the panel; the invisible full-screen button closes it on any click outside
function ui.OpenMenu(menu, frame)
    if not ui.menuFrame then   -- EasyMenu needs a named dropdown frame (an unnamed button gives UIDropDownMenu.lua:84)
        ui.menuFrame = CreateFrame("Frame", "RebornLootLabMenuFrame", UIParent, "UIDropDownMenuTemplate")
    end
    EasyMenu(menu, ui.menuFrame, "cursor", 0, 0, "MENU")
    if not ui.menuCatcher then
        local c = CreateFrame("Button", nil, UIParent)
        c:SetAllPoints(UIParent)
        c:SetFrameStrata("TOOLTIP")
        c:SetFrameLevel(0)
        c:EnableMouse(true)
        c:SetScript("OnMouseDown", function() CloseDropDownMenus(); c:Hide() end)
        c:Hide()
        if DropDownList1 and DropDownList1.HookScript then
            DropDownList1:HookScript("OnHide", function() c:Hide() end)
        end
        ui.menuCatcher = c
    end
    for i = 1, 3 do
        local l = _G["DropDownList" .. i]
        if l then l:SetFrameStrata("TOOLTIP"); l:Raise() end
    end
    ui.menuCatcher:Show()
end

-- uncached items crash this client's tooltip addon: only SetHyperlink what GetItemInfo knows
function ui.ItemTip(owner, id, label, quality, lines)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    local cached = id and id > 0 and GetItemInfo(id)
    local shown = false
    if cached then shown = pcall(GameTooltip.SetHyperlink, GameTooltip, "item:" .. id) end
    if not shown then
        GameTooltip:AddLine("|cff" .. QCol(quality)[4] .. (label or "") .. "|r")
        if id and id > 0 then GameTooltip:AddLine("ItemID: " .. id, 0.7, 0.7, 0.7) end
        if id and id > 0 and not cached then
            GameTooltip:AddLine(T("客户端还没有这件物品的数据，所以不显示完整提示。", "The client has no data for this item yet, so the full tooltip is skipped."), 1, 0.5, 0.2, true)
        end
    end
    for _, l in ipairs(lines or {}) do GameTooltip:AddLine(l, 1, 0.82, 0, true) end
    GameTooltip:Show()
end

-- ---- a scrolling list of rows (mouse wheel), each row = icon + left text + right text
local function MakeList(parent, w, nRows, rowH, fill, isSel)
    local L = { rows = {}, data = {}, offset = 0, n = nRows, max = 40 }
    for i = 1, L.max do
        local b = CreateFrame("Button", nil, parent)
        b:SetHeight(rowH)
        b:SetPoint("TOPLEFT", 0, -(i - 1) * rowH)
        b:SetPoint("TOPRIGHT", 0, -(i - 1) * rowH)
        local hl = b:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        hl:SetBlendMode("ADD")
        local sel = b:CreateTexture(nil, "BACKGROUND")
        sel:SetAllPoints()
        sel:SetTexture(1, 0.8, 0.2, 0.18)
        sel:Hide()
        b.sel = sel
        local icon = b:CreateTexture(nil, "ARTWORK")
        icon:SetSize(rowH - 2, rowH - 2)
        icon:SetPoint("LEFT", 1, 0)
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        b.icon = icon
        local right = b:CreateFontString(nil, "OVERLAY", rowH >= 30 and "GameFontHighlight" or "GameFontHighlightSmall")
        right:SetPoint("RIGHT", -4, 0)
        right:SetJustifyH("RIGHT")
        b.right = right
        local left = b:CreateFontString(nil, "OVERLAY", rowH >= 30 and "GameFontNormal" or "GameFontNormalSmall")
        left:SetPoint("LEFT", icon, "RIGHT", 4, 0)
        left:SetPoint("RIGHT", right, "LEFT", -4, 0)
        left:SetJustifyH("LEFT")
        b.left = left
        b:Hide()
        L.rows[i] = b
    end
    parent:EnableMouseWheel(true)
    parent:SetScript("OnMouseWheel", function(_, delta)
        local max = math.max(0, #L.data - L.n)
        L.offset = math.min(max, math.max(0, L.offset - delta * 3))
        L:Refresh()
    end)
    function L:SetN(n)
        n = math.max(1, math.min(self.max, n))
        self.n = n
        self.offset = math.min(self.offset, math.max(0, #self.data - n))
        self:Refresh()
    end
    function L:Set(data, keepOffset)
        self.data = data or {}
        if not keepOffset then self.offset = 0 end
        self:Refresh()
    end
    function L:Refresh()
        for i = 1, self.max do
            local row = self.rows[i]
            local d = (i <= self.n) and self.data[self.offset + i] or nil
            if d then
                row.data = d
                fill(row, d)
                if isSel and isSel(d) then row.sel:Show() else row.sel:Hide() end
                row:Show()
            else
                row.data = nil
                row:Hide()
            end
        end
    end
    return L
end

-- one icon per kind of source (creatures by rank), so a row's icon says what it is
local ICON_DIR = "Interface\\Icons\\"
local KIND_ICON = {
    gameobject = "INV_Box_01", skinning = "INV_Misc_Pelt_Wolf_01", pickpocketing = "INV_Misc_Coin_01", fishing = "INV_Misc_Fish_02",
    item = "INV_Misc_Bag_08", disenchant = "INV_Enchant_ShardBrilliantSmall", prospecting = "INV_Misc_Gem_Ruby_01",
    milling = "INV_Misc_Herb_01", reference = "INV_Misc_Note_01",
}
local FAMILY_ICON = {   -- creature family -> the hunter-pet icon of that animal
    [1] = "Wolf", [2] = "Cat", [3] = "Spider", [4] = "Bear", [5] = "Boar", [6] = "Crocolisk", [7] = "Vulture", [8] = "Crab",
    [9] = "Gorilla", [11] = "Raptor", [12] = "TallStrider", [20] = "Scorpid", [21] = "Turtle", [24] = "Bat", [25] = "Hyena",
    [26] = "Owl", [27] = "WindSerpent", [30] = "DragonHawk", [31] = "Ravager", [32] = "WarpStalker", [33] = "Sporebat",
    [34] = "NetherRay", [35] = "Serpent", [37] = "Moth", [38] = "Chimera", [39] = "Devilsaur", [41] = "Silithid", [42] = "Worm",
    [43] = "Rhino", [44] = "Wasp", [45] = "CoreHound", [46] = "SpiritBeast",
}
local TYPE_ICON = {   -- creature type, when it has no family
    [1] = "Ability_Hunter_BeastCall", [2] = "INV_Misc_Head_Dragon_01", [3] = "Spell_Shadow_SummonFelHunter",
    [4] = "Spell_Nature_ElementalShields", [5] = "Ability_Warrior_Rampage", [6] = "INV_Misc_Bone_HumanSkull_01",
    [7] = "INV_Misc_Head_Human_01", [8] = "INV_Misc_Rabbit", [9] = "INV_Misc_Gear_01", [11] = "Spell_Nature_StoneClawTotem",
    [13] = "Spell_Nature_Cyclone",
}
-- humanoids have no family, and one head for all of them is wrong: a few well-known names get their own icon
local NAME_ICON = {   -- { lower-case English part, Chinese part, icon }
    { "kobold", "狗头人", "INV_Misc_Head_Troll_01" }, { "murloc", "鱼人", "INV_Misc_Head_Murloc_01" },
    { "gnoll", "豺狼人", "Ability_Hunter_Pet_Hyena" }, { "troll", "巨魔", "INV_Misc_Head_Troll_01" },
    { "ogre", "食人魔", "INV_Misc_Head_Orc_01" }, { "orc", "兽人", "INV_Misc_Head_Orc_01" },
    { "defias", "迪菲亚", "INV_Misc_Bandana_03" }, { "dwarf", "矮人", "INV_Misc_Head_Dwarf_01" },
    { "gnome", "侏儒", "INV_Misc_Head_Gnome_01" }, { "goblin", "地精", "INV_Misc_Head_Gnome_01" },
    { "nerubian", "蛛魔", "INV_Misc_Head_Nerubian_01" }, { "naga", "纳迦", "Ability_Hunter_Pet_Serpent" },
    { "tauren", "牛头人", "INV_Misc_Head_Tauren_01" }, { "elf", "精灵", "INV_Misc_Head_Elf_01" },
    { "skeleton", "骷髅", "INV_Misc_Bone_HumanSkull_01" }, { "zombie", "僵尸", "INV_Misc_Bone_HumanSkull_01" },
    { "ghoul", "食尸鬼", "INV_Misc_Bone_HumanSkull_01" }, { "harpy", "鹰身人", "Ability_Hunter_Pet_Owl" },
}
local function NameIcon(name, zh)
    local lo = string.lower(name or "")
    for _, e in ipairs(NAME_ICON) do
        if string.find(lo, e[1], 1, true) or (zh and zh ~= "" and string.find(zh, e[2], 1, true)) then return e[3] end
    end
end

local function SourceIcon(kind, rank, ctype, family, name, zh)
    if kind == "creature" then
        local fam = FAMILY_ICON[tonumber(family) or 0]
        if fam then return ICON_DIR .. "Ability_Hunter_Pet_" .. fam end
        local byName = NameIcon(name, zh)
        if byName then return ICON_DIR .. byName end
        return ICON_DIR .. (TYPE_ICON[tonumber(ctype) or 0] or "INV_Misc_Head_Orc_01")
    end
    return ICON_DIR .. (KIND_ICON[kind] or "INV_Misc_Bag_08")
end

-- a rank is shown by the name's colour: boss red, rare blue, elite yellow
local function RankColor(rank)
    rank = tonumber(rank) or 0
    if rank == 3 then return "|cffff4040" end
    if rank == 2 then return "|cff66ccff" end
    if rank == 1 then return "|cffffd100" end
    if rank == 4 then return "|cff99ccff" end
    return ""
end

local function Fmt(chance)
    chance = tonumber(chance) or 0
    if chance >= 10 then return string.format("%.1f%%", chance) end
    return string.format("%.2f%%", chance)
end

local function Count(d)
    local a, b = tonumber(d.min) or 1, tonumber(d.max) or 1
    if a == b then return "x" .. a end
    return a .. "-" .. b
end

-- =========================================================================
-- state changes
-- =========================================================================
local RefreshAll

local TAB_EN = { creature = "Creatures", gameobject = "Objects", pickpocketing = "Pickpocket", item = "Containers",
    disenchant = "Disenchant", reference = "References" }

local function KindInfo(key) return state.kinds[key] end

local function AskSources()
    local k = KindInfo(state.kind)
    if not k then return end
    local rank = k.rank == 1 and state.rank or -1
    local map = k.map == 1 and state.map or -1
    Cmd(string.format("list %s %d %d %d %s", state.kind, rank, map, state.page, state.search))
    Status(T("正在读取来源列表…", "Reading the source list…"))
    state.asked = GetTime()
    state.askedKind = state.kind
    state.listState = T("正在读取来源列表…", "Reading the source list…")
end

-- no answer for a few seconds: say so instead of leaving the list looking empty or old
local watch = CreateFrame("Frame")
watch:SetScript("OnUpdate", function(_, elapsed)
    if state.asked and GetTime() - state.asked > 6 then
        state.asked = nil
        state.listState = "|cffff5555" .. string.format(T("服务端 6 秒内没有返回「%s」的来源列表。请看 worldserver 控制台有没有 SQL 报错，或是否已更新服务端模块。", "No source list for '%s' came back within 6 seconds. Check the worldserver console for a SQL error, or whether the server module is up to date."), tostring(state.askedKind)) .. "|r"
        Status(state.listState, true)
        if ui.main and ui.main:IsShown() and RefreshAll then RefreshAll() end
    end
end)

local function SelectSource(kind, loot, name, id, info)
    state.sel = { kind = kind, loot = loot, name = name, id = id, info = info }
    state.loot = {}
    state.lootReady = false
    state.users = { total = 0, list = {} }
    state.view = "loot"
    state.sim = nil
    Cmd(string.format("loot %s %d", kind, loot))
    Cmd(string.format("users %s %d", kind, loot))
    RefreshAll()
end

local function SetKind(key)
    state.kind = key
    state.page = 0
    state.rank = -1
    state.map = -1
    -- drop the old kind's list and selection at once, so a slow or failed answer never leaves the old list under the new tab
    state.sources = {}
    state.more = false
    state.sel = nil
    state.loot = {}
    state.lootReady = false
    state.users = { total = 0, list = {} }
    AskSources()
    RefreshAll()
end

local function Jump(kind, loot, name, isBack)
    if not isBack and state.sel then
        state.hist = state.hist or {}
        state.hist[#state.hist + 1] = { kind = state.sel.kind, loot = state.sel.loot, name = state.sel.name }
        if #state.hist > 20 then table.remove(state.hist, 1) end
    end
    if kind ~= state.kind then
        state.kind = kind
        state.page = 0
        state.rank = -1
        state.map = -1
        state.search = tostring(loot)
        if ui.search then ui.search:SetText(state.search) end
        AskSources()
    end
    SelectSource(kind, loot, name, loot, "")
end

local function KindName(key)
    local k = state.kinds[key]
    if not k then return key end
    return T(k.zh, k.en)
end

-- =========================================================================
-- server answers
-- =========================================================================
local newSources, newKinds, newLoot, newUsers, newItems, newWho, newSim

local function OnServer(msg)
    local f = Split(msg)
    local kind = f[1]
    if kind == "PONG" then
        state.online = true
        if f[2] ~= "1" then Status(T("掉落工坊在服务端配置中关闭", "LootLab is switched off in the server config"), true) end
        state.canEdit = f[3] == "1"
        if state.canEdit then Cmd("logsize") end   -- LAB3B
        state.editLocked = f[4] == "1"
        state.editEnabled = f[5] == "1"
        if state.editLocked then Status(T("正式服已锁定：只能看，不能改", "Production lock is on: view only"), true) end
        if built and RefreshAll then RefreshAll() end
    elseif kind == "ERR" then
        Status(f[2] or "?", true)
        state.batch = nil
    elseif kind == "LS" then   -- LAB3B: the size of the change log
        state.logStat = { rows = tonumber(f[2]) or 0, bytes = tonumber(f[3]) or 0, warn = tonumber(f[4]) or 20, crit = tonumber(f[5]) or 100,
                          keep = tonumber(f[6]) or 30, baseRows = tonumber(f[7]) or 0, baseBytes = tonumber(f[8]) or 0 }
        if ui.RefreshLogSize then ui.RefreshLogSize() end
    elseif kind == "ED" and state.batch and state.batch.i > 0 then   -- LAB3C2: an answer inside a batch add
        ui.BatchAnswer(f[2] == "1", f[3])
    elseif kind == "ED" then
        local ok = f[2] == "1"
        Status((ok and T("已完成：", "Done: ") or T("没有改：", "Not changed: ")) .. (f[3] or ""), not ok)
        if state.canEdit then Cmd("logsize") end
        DEFAULT_CHAT_FRAME:AddMessage((ok and "|cff55ff55" or "|cffffa020") .. "[LootLab]|r " .. (ok and T("已完成：", "Done: ") or T("没有改：", "Not changed: ")) .. (f[3] or ""))
        if ok and state.sel then
            local s = state.sel
            SelectSource(s.kind, s.loot, s.name, s.id, s.info)   -- read the table and its users again
        end
    elseif kind == "LG_START" then
        state.log = {}
    elseif kind == "LG" then
        state.log[#state.log + 1] = { id = tonumber(f[2]) or 0, ts = tonumber(f[3]) or 0, who = f[4] or "", kind = f[5] or "", loot = tonumber(f[6]) or 0, action = f[7] or "" }
    elseif kind == "LG_END" then
        if ui.FillLog then ui.FillLog() end
    elseif kind == "KD_START" then
        newKinds = { map = {}, order = {} }
    elseif kind == "KD" then
        if newKinds then
            newKinds.map[f[2]] = { key = f[2], zh = f[3], en = f[4], n = tonumber(f[5]) or 0, rank = tonumber(f[6]) or 0, map = tonumber(f[7]) or 0 }
            newKinds.order[#newKinds.order + 1] = f[2]
        end
    elseif kind == "KD_END" then
        if newKinds then state.kinds, state.kindOrder = newKinds.map, newKinds.order; newKinds = nil end
        if #state.sources == 0 and not state.sourcesAsked then state.sourcesAsked = true; AskSources() end
        RefreshAll()
    elseif kind == "MP_START" then
        state.maps = {}
    elseif kind == "MP" then
        state.maps[#state.maps + 1] = { id = tonumber(f[2]), ty = tonumber(f[3]) or 0, name = f[4] or "?" }
    elseif kind == "SRC_START" then
        newSources = { kind = f[2], page = tonumber(f[3]) or 0, list = {} }
    elseif kind == "SRC" then
        if newSources then
            newSources.list[#newSources.list + 1] = { id = tonumber(f[2]), loot = tonumber(f[3]), rank = tonumber(f[4]) or 0, ctype = tonumber(f[5]) or 0, family = tonumber(f[6]) or 0, path = f[7] or "", info = f[8] or "", name = f[9] or "", zh = f[10] or "", disp = tonumber(f[11]) or 0 }
        end
    elseif kind == "SRC_END" then
        if newSources and newSources.kind == state.kind then
            state.sources = newSources.list
            state.more = f[3] == "1"
            state.asked = nil
            state.listState = (#state.sources == 0) and T("这个分类下没有符合条件的来源。", "No sources match here.") or nil
            Status(string.format(T("%d 个来源", "%d sources"), #state.sources))
        end
        newSources = nil
        RefreshAll()
    elseif kind == "LT_START" then
        newLoot = { kind = f[2], loot = tonumber(f[3]), list = {} }
    elseif kind == "LT" then
        if newLoot then
            newLoot.list[#newLoot.list + 1] = {
                item = tonumber(f[3]) or 0, chance = tonumber(f[4]) or 0, min = tonumber(f[5]) or 1, max = tonumber(f[6]) or 1,
                group = tonumber(f[7]) or 0, quest = tonumber(f[8]) or 0, conds = tonumber(f[9]) or 0, ref = tonumber(f[10]) or 0,
                q = tonumber(f[11]) or 1, icon = f[12] or "", name = f[13] or "", zh = f[14] or "",
            }
        end
    elseif kind == "LT_END" then
        local sel = state.sel
        if newLoot and sel and sel.kind == newLoot.kind and sel.loot == newLoot.loot then
            state.loot = newLoot.list
            state.lootReady = true
        end
        newLoot = nil
        RefreshAll()
    elseif kind == "US_START" then
        newUsers = { kind = f[2], loot = tonumber(f[3]), list = {}, total = 0 }
    elseif kind == "US" then
        if newUsers then newUsers.list[#newUsers.list + 1] = { id = tonumber(f[2]), name = f[3] or "", zh = f[4] or "" } end
    elseif kind == "US_END" then
        local sel = state.sel
        if newUsers and sel and sel.kind == newUsers.kind and sel.loot == newUsers.loot then
            newUsers.total = tonumber(f[4]) or 0
            state.users = newUsers
        end
        newUsers = nil
        RefreshAll()
    elseif kind == "SM_START" then
        newSim = { kind = f[2], loot = tonumber(f[3]), runs = tonumber(f[4]) or 0, list = {} }
    elseif kind == "SM" then
        if newSim then
            newSim.list[#newSim.list + 1] = {
                item = tonumber(f[2]) or 0, times = tonumber(f[3]) or 0, qty = tonumber(f[4]) or 0, q = tonumber(f[5]) or 1,
                icon = f[6] or "", name = f[7] or "", zh = f[8] or "",
            }
        end
    elseif kind == "SM_END" then
        local sel = state.sel
        if newSim and sel and sel.kind == newSim.kind and sel.loot == newSim.loot then
            newSim.skipped = tonumber(f[5]) or 0
            state.sim = newSim
        end
        newSim = nil
        state.simBusy = false
        RefreshAll()
    elseif kind == "IT_START" then
        newItems = { page = tonumber(f[2]) or 0, list = {} }
    elseif kind == "IT" then
        if newItems then
            newItems.list[#newItems.list + 1] = { id = tonumber(f[2]) or 0, q = tonumber(f[3]) or 1, icon = f[4] or "", name = f[5] or "", zh = f[6] or "" }
        end
    elseif kind == "IT_END" then
        if newItems then
            state.items = newItems.list
            state.itemPage = newItems.page
            state.itemMore = f[3] == "1"
        end
        newItems = nil
        RefreshAll()
    elseif kind == "WH_START" then
        newWho = { item = tonumber(f[2]), list = {} }
    elseif kind == "WH" then
        if newWho then
            newWho.list[#newWho.list + 1] = {
                kind = f[2], loot = tonumber(f[3]), chance = tonumber(f[4]) or 0, quest = tonumber(f[5]) or 0, via = tonumber(f[6]) or 0,
                users = tonumber(f[7]) or 0, name = f[8] or "", zh = f[9] or "",
            }
        end
    elseif kind == "WH_END" then
        if newWho then state.who = newWho; state.rightMode = "who" end
        newWho = nil
        if state.who and #state.who.list == 0 then
            Status(T("没有任何掉落表包含这件物品", "No loot table contains this item"), true)
        end
        RefreshAll()
    end
end

-- =========================================================================
-- the window
-- =========================================================================
-- a reference line carries "<count>|<first items>" in its name: "引用池 1002（12 件）：岩石、红玉石、…"
local function RefParts(d)
    local cnt, items = string.match(Pick(d.zh, d.name) or "", "^(%d+)|(.*)$")
    return tonumber(cnt) or 0, items or ""
end

local KIND_HELP = {
    creature = { "怪物掉落：杀死怪物后尸体里的物品。左边是怪物编号和名字。", "Creature loot: what a killed creature drops. Left: creature id and name." },
    gameobject = { "游戏物件：宝箱、矿脉、草药等可以打开 / 采集的物件。", "Game objects: chests, mining veins, herbs and other things you open or gather." },
    skinning = { "剥皮：用剥皮技能从怪物尸体上取得的材料（皮革、鳞片等）。", "Skinning: materials taken from a corpse with the skinning skill (leather, scales...)." },
    pickpocketing = { "偷窃：盗贼偷窃怪物口袋得到的东西。", "Pickpocketing: what a rogue gets from a creature's pocket." },
    fishing = { "钓鱼：按地区区分，在那个地区钓到什么。", "Fishing: by area; what you catch there." },
    item = { "可打开的物品：背包里能打开的箱子、包裹、开锁箱。", "Containers: boxes, bags and lockboxes you open from your bags." },
    disenchant = { "分解：附魔师把绿色以上装备分解成什么。每张表对应一类装备。", "Disenchant: what an enchanter gets from green-or-better gear. One table per gear class." },
    prospecting = { "选矿：珠宝匠把矿石分解成宝石。", "Prospecting: a jewelcrafter breaking ore into gems." },
    milling = { "研磨：铭文师把草药研磨成颜料。", "Milling: a scribe grinding herbs into pigments." },
    reference = { "引用表：很多掉落表共用的“物品池”，本身不属于某个怪。编号后面是池里最常出的几件。", "Reference tables: shared item pools used by many loot tables. After the id: the commonest items inside." },
}
local function KindHelp(key)
    local h = KIND_HELP[key]
    return h and T(h[1], h[2]) or ""
end

local function LootRow(row, d)
    if d.ref ~= 0 then
        row.icon:SetTexture("Interface\\Icons\\INV_Misc_Note_01")
        local cnt, items = RefParts(d)
        row.left:SetText("|cff66ccff" .. T("引用池 ", "Pool ") .. d.ref .. "|r" ..
            (cnt > 0 and ("  |cffaaaaaa" .. string.format(T("（共 %d 件）", "(%d items) "), cnt) .. items .. "|r") or ""))
    else
        row.icon:SetTexture(d.icon ~= "" and d.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        local c = QCol(d.q)
        row.left:SetText("|cff" .. c[4] .. Pick(d.zh, d.name) .. "|r")
    end
    local flags = ""
    if d.quest ~= 0 then flags = flags .. "|cffff9933" .. T("任", "Q") .. "|r " end
    if d.conds > 0 then flags = flags .. "|cff66aaff" .. T("条", "C") .. "|r " end
    if d.group > 0 then flags = flags .. "|cffaaaaaa" .. T("组", "G") .. d.group .. "|r " end
    row.right:SetText(flags .. Fmt(d.chance) .. "  " .. Count(d))
end

local function ShowLootTip(self)
    local d = self.data
    if not d then return end
    local lines = {
        T("概率 ", "Chance ") .. Fmt(d.chance) .. "   " .. T("数量 ", "Count ") .. Count(d),
    }
    if d.group > 0 then lines[#lines + 1] = T("分组 ", "Group ") .. d.group .. T("（组内只掉其中一件）", " (only one of the group drops)") end
    if d.quest ~= 0 then lines[#lines + 1] = T("任务物品：只有接了对应任务的玩家看得到", "Quest item: only players on the quest see it") end
    if d.conds > 0 then lines[#lines + 1] = string.format(T("有 %d 条掉落条件", "%d drop condition(s)"), d.conds) end
    if d.ref ~= 0 then
        lines[#lines + 1] = T("这一行指向引用表：从那张表里再抽。", "This line points at a reference table: more rolls from there.")
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(T("引用池 ", "Pool ") .. d.ref, 0.4, 0.8, 1)
        local cnt, items = RefParts(d)
        if cnt > 0 then GameTooltip:AddLine(string.format(T("池里共 %d 件，例如：", "%d items inside, for example: "), cnt) .. items, 0.9, 0.9, 0.9, true) end
        for _, l in ipairs(lines) do GameTooltip:AddLine(l, 1, 0.82, 0, true) end
        GameTooltip:Show()
        return
    end
    if state.editMode and state.canEdit then lines[#lines + 1] = "|cffff9966" .. T("点击这一行来修改", "Click to edit this row") .. "|r" end
    ui.ItemTip(self, d.item, Pick(d.zh, d.name), d.q, lines)
end

local function SimRow(row, d)
    row.icon:SetTexture(d.icon ~= "" and d.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    row.left:SetText("|cff" .. QCol(d.q)[4] .. Pick(d.zh, d.name) .. "|r")
    local runs = state.sim and state.sim.runs or 1
    row.right:SetText(string.format("%d/%d (%.1f%%)  %s %d", d.times, runs, d.times * 100 / math.max(1, runs), T("共", "total"), d.qty))
end

local function BuildLeft(main)
    local left = Panel(main)
    left:SetPoint("TOPLEFT", 10, -64)
    left:SetPoint("BOTTOMLEFT", 10, 34)
    left:SetWidth(320)
    ui.left = left

    ui.rankBtn = Button(left, 120, "品级：全部", "Rank: all", function(self)
        local menu = { { text = T("品级", "Rank"), isTitle = true, notCheckable = true } }
        local names = { [0] = { "普通", "Normal" }, [1] = { "精英", "Elite" }, [2] = { "稀有精英", "Rare elite" }, [3] = { "首领", "Boss" } }
        menu[#menu + 1] = { text = T("全部", "All"), notCheckable = true, func = function() state.rank = -1; state.page = 0; AskSources(); RefreshAll() end }
        for r = 0, 3 do
            menu[#menu + 1] = { text = T(names[r][1], names[r][2]), notCheckable = true,
                func = function() state.rank = r; state.page = 0; AskSources(); RefreshAll() end }
        end
        ui.OpenMenu(menu, self)
    end)
    ui.rankBtn.noBind = true
    ui.rankBtn:SetPoint("TOPLEFT", 8, -8)

    ui.mapBtn = Button(left, 130, "地图：全部", "Map: all", function(self)
        if #state.maps == 0 then Cmd("maps") end
        local groups = { [0] = {}, [1] = {}, [2] = {} }
        for _, m in ipairs(state.maps) do
            local g = groups[m.ty] or groups[0]
            g[#g + 1] = { text = m.name .. " (" .. m.id .. ")", notCheckable = true,
                func = function() state.map = m.id; state.page = 0; AskSources(); RefreshAll() end }
        end
        local menu = {
            { text = T("地图", "Map"), isTitle = true, notCheckable = true },
            { text = T("全部", "All"), notCheckable = true, func = function() state.map = -1; state.page = 0; AskSources(); RefreshAll() end },
            { text = T("野外世界", "Open world"), notCheckable = true, hasArrow = true, menuList = groups[0] },
            { text = T("五人副本", "Dungeons"), notCheckable = true, hasArrow = true, menuList = groups[1] },
            { text = T("团队副本", "Raids"), notCheckable = true, hasArrow = true, menuList = groups[2] },
        }
        ui.OpenMenu(menu, self)
    end)
    ui.mapBtn.noBind = true
    ui.mapBtn:SetPoint("LEFT", ui.rankBtn, "RIGHT", 4, 0)

    local search = EditField(left, 168)
    search:SetPoint("TOPLEFT", 16, -38)
    search:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        state.search = self:GetText() or ""
        state.page = 0
        AskSources()
    end)
    ui.search = search
    local go = Button(left, 64, "搜索", "Search", function()
        ui.search:ClearFocus()
        state.search = ui.search:GetText() or ""
        state.page = 0
        AskSources()
    end)
    go:SetPoint("LEFT", search, "RIGHT", 4, 0)

    local hint = left:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOPLEFT", 12, -62)
    Bind(hint, "名称或编号", "Name or id")

    local host = CreateFrame("Frame", nil, left)
    host:SetPoint("TOPLEFT", 6, -78)
    host:SetPoint("BOTTOMRIGHT", -6, 34)
    -- loads a source's model into a PlayerModel. A creature goes by display id / creature id first (they carry the skin
    -- textures; a bare model file is all white), but only counts if the client really loaded something (GetModel);
    -- otherwise the model file itself is the fallback.
    function ui.LoadModel(m, d, facing)
        local function loaded()
            local ok, p = pcall(m.GetModel, m)
            return ok and p ~= nil and p ~= ""
        end
        local shown = false
        if state.kind == "creature" then
            if (d.disp or 0) > 0 and m.SetDisplayInfo and pcall(m.SetDisplayInfo, m, d.disp) and loaded() then shown = true end
            if not shown and d.id and m.SetCreature and pcall(m.SetCreature, m, d.id) and loaded() then shown = true end
        end
        if not shown then
            for _, cand in ipairs({ d.path, (d.path:gsub("%.[mM][dD][xXlL]$", ".m2")) }) do
                if not shown and pcall(m.SetModel, m, cand) then shown = true end
            end
        end
        pcall(m.SetCamera, m, 0)
        pcall(m.SetCamDistanceScale, m, 1.0)
        pcall(m.SetPosition, m, 0, 0, 0)
        pcall(m.SetFacing, m, facing or 0.5)
        return shown
    end

    ui.srcList = MakeList(host, 256, PAGE_ROWS, 34, function(row, d)
        -- no icon / model here: the id and the name are what you search by
        row.icon:Hide()
        row.icon:SetSize(1, 1)
        row.left:SetText("|cff9d9d9d" .. d.id .. "|r  " .. RankColor(d.rank) .. (Pick(d.zh, d.name) ~= "" and Pick(d.zh, d.name) or ((d.info or "") ~= "" and d.info or "-")))
        if row.model then row.model:Hide() end
        if false then   -- (the 3D head code stays but is switched off: textures could not be loaded reliably)
            local path = state.show3d and d.path or ""
            if path ~= "" then
                local key = path .. "#" .. tostring(d.disp or 0)
                if row.modelPath ~= key then
                    row.modelPath = ui.LoadModel(row.model, d, 0.6) and key or nil
                end
                if row.modelPath then
                    row.model:Show()
                    row.icon:Hide()
                else
                    row.model:Hide()
                    row.icon:Show()
                end
            else
                row.model:Hide()
                row.icon:Show()
            end
        end
    end, function(d) return state.sel and state.sel.kind == state.kind and state.sel.loot == d.loot and state.sel.id == d.id end)
    for _, row in ipairs(ui.srcList.rows) do
        local mdl = CreateFrame("PlayerModel", nil, row)
        mdl:SetSize(32, 32)
        mdl:SetPoint("LEFT", 1, 0)
        mdl:Hide()
        row.model = mdl
        row:SetScript("OnClick", function(self)
            local d = self.data
            if d then SelectSource(state.kind, d.loot, Pick(d.zh, d.name), d.id, d.info) end
        end)
        row:SetScript("OnEnter", function(self)
            local d = self.data
            if not d then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 250, 0)
            GameTooltip:AddLine(Pick(d.zh, d.name), 1, 0.82, 0)
            GameTooltip:AddLine((T("来源编号 ", "Source id ")) .. d.id .. "   " .. T("掉落表 ", "Loot table ") .. d.loot, 0.8, 0.8, 0.8)
            GameTooltip:Show()
            -- a big model beside the row (hover preview)
            if false then
                if not ui.big then
                    local big = CreateFrame("PlayerModel", nil, UIParent)
                    big:SetSize(240, 300)
                    big:SetFrameStrata("TOOLTIP")
                    big:SetClampedToScreen(true)
                    local bg = big:CreateTexture(nil, "BACKGROUND")
                    bg:SetAllPoints()
                    bg:SetTexture(0, 0, 0, 0.85)
                    ui.big = big
                end
                local big = ui.big
                big:ClearAllPoints()
                big:SetPoint("LEFT", self, "RIGHT", 4, 0)
                local ok = ui.LoadModel(big, d, 0.5)
                if ok then big:Show() else big:Hide() end
            end
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() if ui.big then ui.big:Hide() end end)
    end

    ui.prev = Button(left, 60, "上一页", "Prev", function()
        if state.page > 0 then state.page = state.page - 1; AskSources() end
    end)
    ui.prev:SetPoint("BOTTOMLEFT", 10, 8)
    ui.next = Button(left, 60, "下一页", "Next", function()
        if state.more then state.page = state.page + 1; AskSources() end
    end)
    ui.next:SetPoint("BOTTOMRIGHT", -10, 8)
    ui.pageText = left:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ui.pageText:SetPoint("BOTTOM", 0, 13)
end

local function BuildMiddle(main)
    local mid = Panel(main)
    mid:SetPoint("TOPLEFT", ui.left, "TOPRIGHT", 6, 0)
    mid:SetPoint("BOTTOMLEFT", ui.left, "BOTTOMRIGHT", 6, 0)
    mid:SetPoint("TOPRIGHT", ui.right, "TOPLEFT", -6, 0)
    mid:SetPoint("BOTTOMRIGHT", ui.right, "BOTTOMLEFT", -6, 0)
    ui.mid = mid

    ui.title = mid:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    ui.title:SetPoint("TOPLEFT", 12, -10)
    ui.title:SetPoint("RIGHT", -12, 0)
    ui.title:SetJustifyH("LEFT")

    ui.usersText = mid:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ui.usersText:SetPoint("TOPLEFT", 12, -34)
    ui.usersText:SetPoint("RIGHT", -12, 0)
    ui.usersText:SetJustifyH("LEFT")
    ui.usersText:SetHeight(30)
    ui.usersText:SetJustifyV("TOP")

    ui.simBtn = Button(mid, 110, "模拟掉落 ×1000", "Simulate ×1000", function()
        local s = state.sel
        if not s then return end
        state.view = "sim"
        state.sim = nil
        state.simBusy = true
        Cmd(string.format("sim %s %d %d", s.kind, s.loot, SIM_RUNS))
        RefreshAll()
    end)
    ui.simBtn:SetPoint("TOPLEFT", 10, -68)
    ui.lootBtn = Button(mid, 90, "掉落表", "Loot table", function() state.view = "loot"; RefreshAll() end)
    ui.lootBtn:SetPoint("LEFT", ui.simBtn, "RIGHT", 4, 0)
    ui.reload = Button(mid, 70, "刷新", "Reload", function()
        local s = state.sel
        if s then SelectSource(s.kind, s.loot, s.name, s.id, s.info) end
    end)
    ui.reload:SetPoint("LEFT", ui.lootBtn, "RIGHT", 4, 0)
    -- back: after following a reference line or a "who drops it" jump
    ui.navBack = Button(mid, 70, "← 返回", "← Back", function()
        local h = state.hist and table.remove(state.hist)
        if h then Jump(h.kind, h.loot, h.name, true) end
    end)
    ui.navBack:SetPoint("LEFT", ui.reload, "RIGHT", 4, 0)

    ui.legend = mid:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    ui.legend:SetPoint("TOPLEFT", 12, -96)
    ui.legend:SetPoint("RIGHT", -12, 0)
    ui.legend:SetJustifyH("LEFT")

    local host = CreateFrame("Frame", nil, mid)
    host:SetPoint("TOPLEFT", 6, -112)
    host:SetPoint("BOTTOMRIGHT", -6, 38)
    ui.lootList = MakeList(host, 456, 20, 18, LootRow)
    ui.simList = MakeList(host, 456, 20, 18, SimRow)
    for _, row in ipairs(ui.lootList.rows) do
        row:SetScript("OnEnter", ShowLootTip)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
        row:SetScript("OnClick", function(self)
            local d = self.data
            if d and d.ref ~= 0 and state.sel then Jump("reference", d.ref, T("引用池 ", "Pool ") .. d.ref)
            elseif d and d.ref == 0 and state.editMode and state.canEdit and state.sel then ui.OpenEdit(d) end
        end)
    end
    for _, row in ipairs(ui.simList.rows) do
        row:SetScript("OnEnter", function(self)
            local d = self.data
            if d then
                local runs = state.sim and state.sim.runs or 0
                ui.ItemTip(self, d.item, Pick(d.zh, d.name), d.q, {
                    string.format(T("模拟 %d 次，其中 %d 次出现", "%d runs, appeared in %d"), runs, d.times),
                    string.format(T("累计数量 %d", "Total quantity %d"), d.qty),
                })
            end
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    ui.empty = mid:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    ui.empty:SetPoint("CENTER", 0, -30)
    ui.empty:SetWidth(380)
    ui.BuildEditBar(mid)
end

local function BuildRight(main)
    local right = Panel(main)
    right:SetPoint("TOPRIGHT", main, "TOPRIGHT", -10, -64)
    right:SetPoint("BOTTOMRIGHT", main, "BOTTOMRIGHT", -10, 34)
    right:SetWidth(300)
    ui.right = right

    local title = right:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 10, -10)
    Bind(title, "物品反查：谁掉落它", "Item lookup: who drops it")

    local search = EditField(right, 150)
    search:SetPoint("TOPLEFT", 16, -34)
    local function DoSearch()
        search:ClearFocus()
        state.itemText = search:GetText() or ""
        state.rightMode = "items"
        Cmd("items 0 " .. state.itemText)
    end
    search:SetScript("OnEnterPressed", DoSearch)
    ui.itemSearch = search
    local go = Button(right, 56, "搜索", "Search", DoSearch)
    go:SetPoint("LEFT", search, "RIGHT", 4, 0)

    ui.whoBtn = Button(right, 130, "谁掉落它", "Who drops it", function()
        if state.item then
            Cmd("who " .. state.item.id)
            Status(T("正在查找…", "Looking…"))
        end
    end)
    ui.whoBtn:SetPoint("TOPLEFT", 10, -60)
    ui.backBtn = Button(right, 80, "返回", "Back", function() state.rightMode = "items"; RefreshAll() end)
    ui.backBtn:SetPoint("LEFT", ui.whoBtn, "RIGHT", 4, 0)

    ui.itemInfo = right:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ui.itemInfo:SetPoint("TOPLEFT", 12, -86)
    ui.itemInfo:SetPoint("RIGHT", -10, 0)
    ui.itemInfo:SetJustifyH("LEFT")

    local host = CreateFrame("Frame", nil, right)
    host:SetPoint("TOPLEFT", 4, -104)
    host:SetPoint("BOTTOMRIGHT", -4, 34)
    ui.itemList = MakeList(host, 232, 17, 18, function(row, d)
        row.icon:SetTexture(d.icon ~= "" and d.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        row.left:SetText("|cff" .. QCol(d.q)[4] .. Pick(d.zh, d.name) .. "|r")
        row.right:SetText("|cffaaaaaa" .. d.id .. "|r")
    end, function(d) return state.picks[d.id] end)
    ui.whoList = MakeList(host, 232, 17, 18, function(row, d)
        row.icon:SetTexture(SourceIcon(d.kind, 0))
        local nm = Pick(d.zh, d.name)
        if nm == "" then nm = KindName(d.kind) .. " " .. d.loot end
        row.left:SetText((d.via ~= 0 and "|cff66ccff*|r " or "") .. nm)
        row.right:SetText(d.via ~= 0 and "|cff66ccff" .. T("引用", "ref") .. "|r" or Fmt(d.chance))
    end)
    for _, row in ipairs(ui.itemList.rows) do
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row:SetScript("OnClick", function(self, button)
            local d = self.data
            if not d then return end
            if button == "RightButton" then ui.ItemMenu(d) return end
            ui.PickItem(d)
        end)
        row:SetScript("OnEnter", function(self)
            local d = self.data
            if d then ui.ItemTip(self, d.id, Pick(d.zh, d.name), d.q, { T("Ctrl+点击多选，Shift+点击连选，右键菜单可加入爆率", "Ctrl+click to pick more, Shift+click for a range, right-click to add to the loot table") }) end
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    for _, row in ipairs(ui.whoList.rows) do
        row:SetScript("OnClick", function(self)
            local d = self.data
            if d then Jump(d.kind, d.loot, Pick(d.zh, d.name)) end
        end)
        row:SetScript("OnEnter", function(self)
            local d = self.data
            if not d then return end
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:AddLine(KindName(d.kind) .. "  " .. T("掉落表 ", "table ") .. d.loot, 1, 0.82, 0)
            if d.via ~= 0 then
                GameTooltip:AddLine(T("通过引用表 ", "Through reference table ") .. d.via, 0.4, 0.8, 1)
            else
                GameTooltip:AddLine(T("概率 ", "Chance ") .. Fmt(d.chance), 1, 1, 1)
            end
            if d.quest ~= 0 then GameTooltip:AddLine(T("任务物品", "Quest item"), 1, 0.6, 0.2) end
            GameTooltip:AddLine(string.format(T("被 %d 个来源使用", "Used by %d source(s)"), d.users), 0.8, 0.8, 0.8)
            GameTooltip:AddLine(T("点击跳转到它的掉落表", "Click to open its loot table"), 0.6, 1, 0.6)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    ui.itemPrev = Button(right, 56, "上页", "Prev", function()
        if state.itemPage > 0 then Cmd("items " .. (state.itemPage - 1) .. " " .. state.itemText) end
    end)
    ui.itemPrev:SetPoint("BOTTOMLEFT", 10, 8)
    ui.itemNext = Button(right, 56, "下页", "Next", function()
        if state.itemMore then Cmd("items " .. (state.itemPage + 1) .. " " .. state.itemText) end
    end)
    ui.itemNext:SetPoint("BOTTOMRIGHT", -10, 8)
    -- LAB3C2: add everything picked to the loot table in the middle
    ui.itemAddBtn = Button(right, 118, "加入爆率", "Add to loot", function() ui.OpenBatchAdd() end)
    ui.itemAddBtn.noBind = true
    ui.itemAddBtn:SetPoint("BOTTOM", 0, 8)
    ui.itemAddBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(T("加入爆率", "Add to loot"))
        GameTooltip:AddLine(T("把搜索结果里选中的物品一次加进中间这张掉落表。Ctrl+点击多选，Shift+点击连选；也可以右键物品。需要打开编辑模式并选中一张掉落表。", "Adds the items picked in the search list to the loot table in the middle. Ctrl+click picks more, Shift+click picks a range; right-click an item works too. Needs edit mode and a selected loot table."), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    ui.itemAddBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

function RefreshAll()
    if not built then return end
    -- tabs
    for key, b in pairs(ui.tabs or {}) do
        local k = state.kinds[key]
        if k then
            b:SetText(T(k.zh, TAB_EN[key] or k.en) .. " " .. (k.n >= 1000 and string.format("%.1fk", k.n / 1000) or k.n))
            if key == state.kind then b:Disable() else b:Enable() end
            b:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
                GameTooltip:AddLine(T(k.zh, k.en), 1, 0.82, 0)
                GameTooltip:AddLine(KindHelp(key), 0.9, 0.9, 0.9, true)
                GameTooltip:Show()
            end)
            b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end
    end
    local k = state.kinds[state.kind]
    if k and k.rank == 1 then ui.rankBtn:Show() else ui.rankBtn:Hide() end
    if k and k.map == 1 then ui.mapBtn:Show() else ui.mapBtn:Hide() end
    if state.rank >= 0 then
        local names = { [0] = { "普通", "Normal" }, [1] = { "精英", "Elite" }, [2] = { "稀有精英", "Rare elite" }, [3] = { "首领", "Boss" } }
        ui.rankBtn:SetText(T("品级：", "Rank: ") .. T(names[state.rank][1], names[state.rank][2]))
    else
        ui.rankBtn:SetText(T("品级：全部", "Rank: all"))
    end
    if state.map >= 0 then
        local nm = tostring(state.map)
        for _, m in ipairs(state.maps) do if m.id == state.map then nm = m.name end end
        ui.mapBtn:SetText(T("地图：", "Map: ") .. nm)
    else
        ui.mapBtn:SetText(T("地图：全部", "Map: all"))
    end
    ui.srcList:Set(state.sources, true)
    ui.pageText:SetText(string.format(T("第 %d 页", "Page %d"), state.page + 1))
    if state.page > 0 then ui.prev:Enable() else ui.prev:Disable() end
    if state.more then ui.next:Enable() else ui.next:Disable() end

    -- middle
    local s = state.sel
    if not s then
        ui.title:SetText(T("请先在左边选一个来源", "Pick a source on the left"))
        ui.usersText:SetText("")
        ui.simBtn:Disable()
        ui.lootBtn:Disable()
        ui.reload:Disable()
        if ui.navBack then
            if state.hist and #state.hist > 0 then ui.navBack:Enable() else ui.navBack:Disable() end
        end
        ui.legend:SetText("")
        ui.lootList:Set({}, true)
        ui.simList:Set({}, true)
        ui.empty:SetText("|cffffd100" .. KindHelp(state.kind) .. "|r\n\n" .. T("这一版只能看、不能改。\n点左边一行，看它的掉落表；也可以点“模拟掉落”。", "This version is read-only.\nClick a row on the left to see its loot table, or simulate it.") ..
            ((#state.sources == 0 and state.listState) and ("\n\n" .. state.listState) or ""))
    else
        ui.simBtn:Enable()
        ui.lootBtn:Enable()
        ui.reload:Enable()
        if ui.navBack then
            if state.hist and #state.hist > 0 then ui.navBack:Enable() else ui.navBack:Disable() end
        end
        ui.title:SetText("|cffffd100" .. s.name .. "|r  |cffaaaaaa" .. KindName(s.kind) .. " #" .. s.loot .. "|r")
        local u = state.users
        local names = {}
        for i, e in ipairs(u.list) do
            if i > 4 then break end
            names[#names + 1] = Pick(e.zh, e.name)
        end
        local line = string.format(T("这张掉落表被 |cffffd100%d|r 个来源使用", "This loot table is used by |cffffd100%d|r source(s)"), u.total)
        if u.total > 1 then line = line .. T("（改它会同时影响它们）", " (editing it changes all of them)") end
        if #names > 0 then line = line .. "\n" .. table.concat(names, "、") .. (u.total > #names and " …" or "") end
        ui.usersText:SetText(line)
        if state.view == "sim" then
            ui.legend:SetText(state.simBusy and T("正在模拟…", "Simulating…") or
                string.format(T("模拟 %d 次，按出现次数排序；不含任务物品和条件（跳过 %d 行任务物品）", "%d runs sorted by appearances; quest items and conditions are not simulated (%d quest lines skipped)"),
                    state.sim and state.sim.runs or 0, state.sim and state.sim.skipped or 0))
            ui.simList:Set(state.sim and state.sim.list or {}, true)
            for _, r in ipairs(ui.lootList.rows) do r:Hide() end
            ui.empty:SetText((not state.simBusy and state.sim and #state.sim.list == 0) and T("什么也没掉出来", "Nothing dropped") or "")
        else
            ui.legend:SetText(T("任=任务物品  条=有条件  组=分组（组内只掉一件）  蓝色引用表可点击跳转", "Q=quest item  C=has conditions  G=group (one of the group drops)  click a blue reference line to open it"))
            ui.lootList:Set(state.loot, true)
            for _, r in ipairs(ui.simList.rows) do r:Hide() end
            if not state.lootReady then ui.empty:SetText(T("读取中…", "Loading…"))
            elseif #state.loot == 0 then ui.empty:SetText(T("这张掉落表是空的", "This loot table is empty"))
            else ui.empty:SetText("") end
        end
    end
    if not state.sim and state.view == "sim" then ui.simList:Set({}, true) end

    -- right
    local it = state.item
    if it then
        ui.itemInfo:SetText("|cff" .. QCol(it.q)[4] .. Pick(it.zh, it.name) .. "|r  #" .. it.id)
        ui.whoBtn:Enable()
    else
        ui.itemInfo:SetText(T("先搜索并点选一件物品", "Search and click an item"))
        ui.whoBtn:Disable()
    end
    if state.rightMode == "who" and state.who then
        ui.itemInfo:SetText(string.format(T("掉落 #%d 的来源：%d 个（* = 经引用表）", "Sources of #%d: %d (* = via a reference table)"), state.who.item, #state.who.list) ..
            (#state.who.list == 0 and ("\n|cffffaa66" .. T("没有任何掉落表（含经一层引用表）包含它。它可能来自商人、任务奖励、制作、成就，或由脚本发放。", "No loot table (even through one reference table) holds it. It may come from a vendor, a quest reward, crafting, an achievement or a script.") .. "|r") or ""))
        ui.backBtn:Show()
        ui.whoList:Set(state.who.list, true)
        for _, r in ipairs(ui.itemList.rows) do r:Hide() end
        ui.itemPrev:Hide()
        ui.itemNext:Hide()
        ui.itemAddBtn:Hide()
    else
        ui.backBtn:Hide()
        ui.itemList:Set(state.items, true)
        for _, r in ipairs(ui.whoList.rows) do r:Hide() end
        ui.itemPrev:Show()
        ui.itemNext:Show()
        ui.itemAddBtn:Show()
        if state.itemPage > 0 then ui.itemPrev:Enable() else ui.itemPrev:Disable() end
        if state.itemMore then ui.itemNext:Enable() else ui.itemNext:Disable() end
    end
    for _, b in ipairs(binds) do
        if b.obj and not b.obj.noBind and b.zh then b.obj:SetText(T(b.zh, b.en)) end
    end
    if ui.Label3D then ui.Label3D() end
    if ui.RefreshEdit then ui.RefreshEdit() end
    if ui.RefreshPicks then ui.RefreshPicks() end
end

-- =========================================================================
-- LAB2: editing. Only works when the server says this account may edit
-- (PONG: RebornLootLab.Edit.Enable = 1, Edit.Lock = 0, account level high enough).
-- =========================================================================
local function TitleText()
    local tag
    if state.editMode then tag = "|cffff4040" .. T("编辑中", "editing") .. "|r"
    elseif state.canEdit then tag = "|cff66ff66" .. T("可编辑", "editable") .. "|r"
    else tag = "|cffff9933" .. T("只读", "read-only") .. "|r" end
    return "|cff00ff00Reborn|r " .. T("掉落工坊", "LootLab") .. "  |cffaaaaaav" .. PANEL_VERSION .. "|r  " .. tag
end

local function EditCmd(op, args)
    local s = state.sel
    if not s then return end
    Cmd(string.format("edit %s %d %s%s", s.kind, s.loot, op, args and (" " .. args) or ""))
    Status(T("已发送，等服务端回答…", "Sent, waiting for the server…"))
end

-- one popup for both "edit this row" and "add an item"
function ui.BuildEditPop()
    if ui.pop then return ui.pop end
    local p = CreateFrame("Frame", "RebornLootLabEditPop", UIParent)
    p:SetSize(340, 300)
    p:SetPoint("CENTER")
    p:SetFrameStrata("FULLSCREEN_DIALOG")
    p:SetToplevel(true)
    p:EnableMouse(true)
    p:SetMovable(true)
    p:RegisterForDrag("LeftButton")
    p:SetScript("OnDragStart", p.StartMoving)
    p:SetScript("OnDragStop", p.StopMovingOrSizing)
    p:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    p.title = p:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    p.title:SetPoint("TOP", 0, -18)
    p.item = p:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    p.item:SetPoint("TOPLEFT", 24, -46)
    p.item:SetPoint("RIGHT", -24, 0)
    p.item:SetJustifyH("LEFT")

    local function Row(y, zh, en)
        local l = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        l:SetPoint("TOPLEFT", 24, y)
        Bind(l, zh, en)
        local e = EditField(p, 90)
        e:SetPoint("TOPLEFT", 160, y + 4)
        e:SetMaxLetters(10)
        return e
    end
    p.idBox = Row(-72, "物品编号", "Item id")
    p.chance = Row(-98, "掉率 %（0–100）", "Chance % (0-100)")
    p.min = Row(-124, "最少数量", "Min count")
    p.max = Row(-150, "最多数量", "Max count")
    p.group = Row(-176, "分组（0=独立）", "Group (0 = own roll)")
    p.quest = CreateFrame("CheckButton", nil, p, "UICheckButtonTemplate")
    p.quest:SetPoint("TOPLEFT", 20, -198)
    p.questText = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    p.questText:SetPoint("LEFT", p.quest, "RIGHT", 2, 0)
    Bind(p.questText, "任务物品（只有接了任务的人能拿到）", "Quest item (only players on the quest get it)")

    p.warn = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    p.warn:SetPoint("TOPLEFT", 24, -228)
    p.warn:SetPoint("RIGHT", -24, 0)
    p.warn:SetJustifyH("LEFT")

    p.save = Button(p, 90, "保存", "Save", function() ui.SaveEdit() end)
    p.save:SetPoint("BOTTOMLEFT", 24, 20)
    p.del = Button(p, 90, "删除这行", "Delete row", function() ui.DeleteEdit() end)
    p.del:SetPoint("LEFT", p.save, "RIGHT", 6, 0)
    p.cancel = Button(p, 90, "取消", "Cancel", function() p:Hide() end)
    p.cancel:SetPoint("LEFT", p.del, "RIGHT", 6, 0)
    if UISpecialFrames then table.insert(UISpecialFrames, "RebornLootLabEditPop") end
    p:Hide()
    ui.pop = p
    return p
end

local function FillPop(mode, d)
    local p = ui.BuildEditPop()
    p.mode = mode
    p.row = d
    local s = state.sel
    local n = state.users and state.users.total or 0
    p.warn:SetText("|cffffaa55" .. string.format(T("这张掉落表被 %d 个来源使用，改动会同时影响它们。改之前已自动保存官方原样，随时可以“还原官方”。",
        "This loot table is used by %d source(s); the change affects all of them. The official content is saved before the first change; you can always use \"Restore official\"."), n) .. "|r")
    if mode == "add" then
        p.title:SetText(T("添加物品", "Add an item"))
        p.item:SetText(s and s.name or "")
        p.idBox:SetText("")
        p.idBox:Enable()
        p.chance:SetText("10")
        p.min:SetText("1")
        p.max:SetText("1")
        p.group:SetText("0")
        p.quest:SetChecked(false)
        p.quest:Disable()
        p.del:Hide()
    else
        p.title:SetText(T("修改这一行", "Edit this row"))
        p.item:SetText("|cff" .. QCol(d.q)[4] .. Pick(d.zh, d.name) .. "|r")
        p.idBox:SetText(tostring(d.item))
        p.idBox:Disable()
        p.chance:SetText(string.format("%g", d.chance))
        p.min:SetText(tostring(d.min))
        p.max:SetText(tostring(d.max))
        p.group:SetText(tostring(d.group))
        p.quest:SetChecked(d.quest ~= 0)
        p.quest:Enable()
        p.del:Show()
    end
    p:Show()
    p:Raise()
end

-- ---- LAB3C2: pick several items in the search list and add them to the open loot table
-- the picked items in list order (the page the player sees)
local function PickedList()
    local out = {}
    for _, d in ipairs(state.items) do
        if state.picks[d.id] then out[#out + 1] = d end
    end
    return out
end
local function PickCount() return #PickedList() end

function ui.PickItem(d)
    if IsControlKeyDown() then   -- toggle this one
        if state.picks[d.id] then state.picks[d.id] = nil else state.picks[d.id] = true end
        state.pickAnchor = d.id
    elseif IsShiftKeyDown() and state.pickAnchor then   -- everything between the anchor and this one
        local a, b
        for i, x in ipairs(state.items) do
            if x.id == state.pickAnchor then a = i end
            if x.id == d.id then b = i end
        end
        if a and b then
            if a > b then a, b = b, a end
            for i = a, b do state.picks[state.items[i].id] = true end
        else
            state.picks[d.id] = true
        end
    else   -- a plain click: just this one (as before)
        state.picks = { [d.id] = true }
        state.pickAnchor = d.id
    end
    state.item = d
    RefreshAll()
end

function ui.RefreshPicks()
    local b = ui.itemAddBtn
    if not b then return end
    local n = PickCount()
    b:SetText(string.format(T("加入爆率 (%d)", "Add to loot (%d)"), n))
    if n > 0 and state.canEdit and state.editMode and state.sel then b:Enable() else b:Disable() end
end

function ui.ItemMenu(d)
    if not state.picks[d.id] then   -- right-click on something not picked: it becomes the pick
        state.picks = { [d.id] = true }
        state.pickAnchor = d.id
        state.item = d
        RefreshAll()
    end
    local n = PickCount()
    local canAdd = state.canEdit and state.editMode and state.sel
    local menu = {
        { text = Pick(d.zh, d.name), isTitle = true, notCheckable = true },
        { text = canAdd and string.format(T("把选中的 %d 件加入爆率…", "Add the %d picked item(s) to the loot table…"), n)
                       or T("加入爆率（先开编辑模式并选一张掉落表）", "Add to loot (turn on edit mode and pick a loot table first)"),
          disabled = not canAdd, notCheckable = true, func = function() ui.OpenBatchAdd() end },
        { text = T("谁掉落它", "Who drops it"), notCheckable = true, func = function() state.item = d; Cmd("who " .. d.id); Status(T("正在查找…", "Looking…")) end },
        { text = T("清除选择", "Clear the picks"), notCheckable = true, func = function() state.picks = {}; RefreshAll() end },
        { text = CANCEL or "Cancel", notCheckable = true },
    }
    ui.OpenMenu(menu, nil)
end

function ui.BuildBatchPop()
    if ui.bpop then return ui.bpop end
    local p = CreateFrame("Frame", "RebornLootLabBatchPop", UIParent)
    p:SetSize(360, 330)
    p:SetPoint("CENTER")
    p:SetFrameStrata("FULLSCREEN_DIALOG")
    p:SetToplevel(true)
    p:EnableMouse(true)
    p:SetMovable(true)
    p:RegisterForDrag("LeftButton")
    p:SetScript("OnDragStart", p.StartMoving)
    p:SetScript("OnDragStop", p.StopMovingOrSizing)
    p:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    p.title = p:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    p.title:SetPoint("TOP", 0, -18)
    p.target = p:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    p.target:SetPoint("TOPLEFT", 24, -46)
    p.target:SetPoint("RIGHT", -24, 0)
    p.target:SetJustifyH("LEFT")
    p.names = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    p.names:SetPoint("TOPLEFT", 24, -68)
    p.names:SetPoint("RIGHT", -24, 0)
    p.names:SetJustifyH("LEFT")
    p.names:SetHeight(84)
    p.names:SetJustifyV("TOP")

    local function Row(y, zh, en, val)
        local l = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        l:SetPoint("TOPLEFT", 24, y)
        Bind(l, zh, en)
        local e = EditField(p, 90)
        e:SetPoint("TOPLEFT", 190, y + 4)
        e:SetMaxLetters(10)
        e:SetText(val)
        return e
    end
    p.chance = Row(-162, "每件的掉率 %（0–100）", "Chance % each (0-100)", "10")
    p.min = Row(-188, "最少数量", "Min count", "1")
    p.max = Row(-214, "最多数量", "Max count", "1")
    p.group = Row(-240, "分组（0=各自独立）", "Group (0 = own roll)", "0")
    p.note = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    p.note:SetPoint("TOPLEFT", 24, -264)
    p.note:SetPoint("RIGHT", -24, 0)
    p.note:SetJustifyH("LEFT")
    p.note:SetText("|cffffaa55" .. T("这张表里已有的物品会跳过。加完之后可以在日志里看到，也可以用“撤销”逐步退回。", "Items the table already has are skipped. Every add is logged and \"Undo\" steps back one at a time.") .. "|r")

    p.ok = Button(p, 110, "全部加入", "Add them all", function() ui.RunBatch() end)
    p.ok:SetPoint("BOTTOMLEFT", 24, 20)
    p.cancel = Button(p, 90, "取消", "Cancel", function() p:Hide() end)
    p.cancel:SetPoint("LEFT", p.ok, "RIGHT", 6, 0)
    if UISpecialFrames then table.insert(UISpecialFrames, "RebornLootLabBatchPop") end
    p:Hide()
    ui.bpop = p
    return p
end

function ui.OpenBatchAdd()
    if not (state.canEdit and state.editMode and state.sel) then
        Status(T("先打开编辑模式并选一张掉落表", "Turn on edit mode and pick a loot table first"), true)
        return
    end
    local list = PickedList()
    if #list == 0 then Status(T("先在搜索结果里选物品", "Pick items in the search list first"), true) return end
    local p = ui.BuildBatchPop()
    p.items = list
    p.title:SetText(string.format(T("加入 %d 件物品", "Add %d item(s)"), #list))
    p.target:SetText(T("加到：", "Into: ") .. "|cffffd100" .. (state.sel.name or "") .. "|r  (" .. KindName(state.sel.kind) .. " " .. state.sel.loot .. ")")
    local lines = {}
    for i, d in ipairs(list) do
        if i > 6 then lines[#lines + 1] = string.format(T("……还有 %d 件", "… and %d more"), #list - 6) break end
        lines[#lines + 1] = "|cff" .. QCol(d.q)[4] .. Pick(d.zh, d.name) .. "|r  #" .. d.id
    end
    p.names:SetText(table.concat(lines, "\n"))
    p:Show()
    p:Raise()
end

-- one add at a time: the next goes out when the server has answered the last one (no chat flood)
local function BatchNext()
    local b = state.batch
    if not b then return end
    b.i = b.i + 1
    local d = b.list[b.i]
    if not d then
        local msg = string.format(T("批量加入完成：成功 %d 件", "Batch add finished: %d added"), b.ok)
        if b.skip > 0 then msg = msg .. string.format(T("，已有跳过 %d 件", ", %d already there"), b.skip) end
        if #b.fail > 0 then msg = msg .. string.format(T("，失败 %d 件（%s）", ", %d failed (%s)"), #b.fail, table.concat(b.fail, "; ")) end
        Status(msg, #b.fail > 0)
        DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[LootLab]|r " .. msg)
        state.batch = nil
        if b.ok > 0 and state.sel then
            local s = state.sel
            SelectSource(s.kind, s.loot, s.name, s.id, s.info)
        end
        return
    end
    Status(string.format(T("批量加入 %d/%d …", "Batch add %d/%d …"), b.i, #b.list))
    EditCmd("add", string.format("%d %.4f %d %d %d", d.id, b.v.chance, b.v.min, b.v.max, b.v.group))
end

-- called by the ED / ERR answers; returns true when the answer belonged to a batch
function ui.BatchAnswer(ok, text)
    local b = state.batch
    if not b or b.i == 0 then return false end
    if ok then b.ok = b.ok + 1 else b.fail[#b.fail + 1] = tostring(b.list[b.i].id) .. ": " .. (text or "?") end
    BatchNext()
    return true
end

function ui.RunBatch()
    local p = ui.bpop
    if not p or not p.items or not state.sel then return end
    local chance = tonumber(p.chance:GetText())
    local minC = tonumber(p.min:GetText())
    local maxC = tonumber(p.max:GetText())
    local group = tonumber(p.group:GetText())
    if not chance or chance < 0 or chance > 100 then Status(T("掉率要在 0 到 100 之间", "Chance must be between 0 and 100"), true) return end
    if not minC or not maxC or minC < 1 or maxC < minC or maxC > 255 then Status(T("数量：最少至少 1，最多不小于最少，不超过 255", "Count: min at least 1, max not below min, at most 255"), true) return end
    if not group or group < 0 or group > 255 then Status(T("分组要在 0 到 255 之间", "Group must be between 0 and 255"), true) return end
    local have = {}
    for _, r in ipairs(state.loot or {}) do if r.item then have[r.item] = true end end
    local list, skip = {}, 0
    for _, d in ipairs(p.items) do
        if have[d.id] then skip = skip + 1 else list[#list + 1] = d end
    end
    p:Hide()
    state.batch = { list = list, i = 0, ok = 0, skip = skip, fail = {}, v = { chance = chance, min = math.floor(minC), max = math.floor(maxC), group = math.floor(group) } }
    BatchNext()
end

function ui.OpenEdit(d) FillPop("set", d) end
function ui.OpenAdd() if state.sel then FillPop("add") end end

local function PopNumbers()
    local p = ui.pop
    local chance = tonumber(p.chance:GetText())
    local minC = tonumber(p.min:GetText())
    local maxC = tonumber(p.max:GetText())
    local group = tonumber(p.group:GetText())
    if not chance or chance < 0 or chance > 100 then return nil, T("掉率要在 0 到 100 之间", "Chance must be between 0 and 100") end
    if not minC or not maxC or minC < 1 or maxC < minC or maxC > 255 then return nil, T("数量：最少至少 1，最多不小于最少，不超过 255", "Count: min at least 1, max not below min, at most 255") end
    if not group or group < 0 or group > 255 then return nil, T("分组要在 0 到 255 之间", "Group must be between 0 and 255") end
    return { chance = chance, min = math.floor(minC), max = math.floor(maxC), group = math.floor(group) }
end

function ui.SaveEdit()
    local p = ui.pop
    if not p or not state.sel then return end
    local v, err = PopNumbers()
    if not v then Status(err, true); return end
    if p.mode == "add" then
        local item = tonumber(p.idBox:GetText())
        if not item or item < 1 then Status(T("请填物品编号", "Enter an item id"), true); return end
        EditCmd("add", string.format("%d %.4f %d %d %d", item, v.chance, v.min, v.max, v.group))
    else
        EditCmd("set", string.format("%d %.4f %d %d %d %d", p.row.item, v.chance, v.min, v.max, v.group, p.quest:GetChecked() and 1 or 0))
    end
    p:Hide()
end

function ui.DeleteEdit()
    local p = ui.pop
    if p and p.mode == "set" and p.row then
        EditCmd("del", tostring(p.row.item))
        p:Hide()
    end
end

function ui.ConfirmRestore()
    if not state.sel then return end
    StaticPopupDialogs["REBORN_LOOTLAB_RESTORE"] = {
        text = T("把这张掉落表还原成官方原样？现在的改动会被替换（还能用“撤销”找回）。", "Restore this loot table to the official content? Current changes are replaced (\"Undo\" can bring them back)."),
        button1 = ACCEPT or "OK", button2 = CANCEL or "Cancel",
        OnAccept = function() EditCmd("restore") end,
        timeout = 0, whileDead = 1, hideOnEscape = 1,
    }
    StaticPopup_Show("REBORN_LOOTLAB_RESTORE")
end

-- LAB3A: every table the workshop has changed goes back to the official content
function ui.ConfirmRestoreAll()
    StaticPopupDialogs["REBORN_LOOTLAB_RESTOREALL"] = {
        text = T("把工坊改过的【所有】掉落表都还原成官方原样？每张表现在的改动都会被替换（日志里留有记录）。", "Restore ALL the loot tables the workshop has changed to the official content? Their current changes are replaced (the log keeps a record)."),
        button1 = ACCEPT or "OK", button2 = CANCEL or "Cancel",
        OnAccept = function()
            Cmd("restoreall")
            Status(T("已发送，等服务端回答…", "Sent, waiting for the server…"))
        end,
        timeout = 0, whileDead = 1, hideOnEscape = 1,
    }
    StaticPopup_Show("REBORN_LOOTLAB_RESTOREALL")
end

-- LAB3B: how big the change log is, in a colour that says whether it is time to archive
local function Mb(bytes)
    if bytes < 1024 * 100 then return string.format("%.0f KB", bytes / 1024) end
    return string.format("%.1f MB", bytes / 1048576)
end

function ui.LogLevel()
    local st = state.logStat
    if not st then return 0 end
    local mb = st.bytes / 1048576
    if mb >= st.crit then return 2 end
    if mb >= st.warn then return 1 end
    return 0
end

function ui.RefreshLogSize()
    local st = state.logStat
    if not ui.main then return end
    if not ui.logStatBtn then
        local b = CreateFrame("Button", "RebornLootLabLogSize", ui.main)
        b:SetSize(420, 22)
        b:SetPoint("TOP", ui.main, "TOP", 40, -10)
        b:SetNormalFontObject("GameFontNormalLarge")
        b:SetHighlightFontObject("GameFontHighlightLarge")
        b:SetFrameLevel(ui.main:GetFrameLevel() + 5)
        b:SetScript("OnClick", function() Cmd("log"); Cmd("logsize"); ui.ShowLog() end)
        b:SetScript("OnEnter", function(self)
            local s = state.logStat
            if not s then return end
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:AddLine(T("改动日志的大小", "Size of the change log"))
            GameTooltip:AddLine(string.format(T("日志 %d 条，%s；官方原样备份 %d 张表，%s。", "Log: %d entries, %s; official copies: %d tables, %s."),
                s.rows, Mb(s.bytes), s.baseRows, Mb(s.baseBytes)), 1, 1, 1, true)
            GameTooltip:AddLine(string.format(T("橙色从 %d MB 起提示，红色从 %d MB 起强烈建议。", "Orange from %d MB, red from %d MB."), s.warn, s.crit), 1, 1, 1, true)
            GameTooltip:AddLine(T("点一下打开日志，里面有“归档并清理”：把旧日志写到服务器文件再从数据库删除，每张表最新一条保留，撤销和还原官方不受影响。", "Click to open the log; \"Archive and clean\" writes old entries to a file on the server and removes them from the database. The newest entry of each table stays, so undo and restore official still work."), 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        ui.logStatBtn = b
    end
    if not (st and state.canEdit) then ui.logStatBtn:Hide() return end
    local lvl = ui.LogLevel()
    local color = lvl == 2 and "|cffff3030" or (lvl == 1 and "|cffffa020" or "|cff55ff55")
    local text = string.format(T("日志 %s · %d 条", "Log %s · %d entries"), Mb(st.bytes), st.rows)
    if lvl == 2 then text = text .. T("  ！请尽快归档", "  ! archive it now")
    elseif lvl == 1 then text = text .. T("  ！建议归档", "  ! consider archiving") end
    ui.logStatBtn:SetText(color .. text .. "|r")
    ui.logStatBtn:Show()
    if lvl > 0 and not state.logWarned then   -- once per session, in the chat too
        state.logWarned = true
        DEFAULT_CHAT_FRAME:AddMessage(string.format("%s[LootLab]|r %s", color,
            string.format(T("改动日志已 %s（%d 条），建议在掉落工坊里“日志 → 归档并清理”。", "The change log is %s (%d entries); open Log -> Archive and clean in the workshop."), Mb(st.bytes), st.rows)))
    end
end

function ui.AskArchive()
    local st = state.logStat or {}
    StaticPopupDialogs["REBORN_LOOTLAB_ARCHIVE"] = {
        text = string.format(T("归档并清理改动日志：保留最近多少天？更早的日志会写进服务器上的文件（归档目录里的 .jsonl），再从数据库删除。每张表最新的一条总会保留，撤销和还原官方不受影响。\n\n现在：%s，%d 条。", "Archive and clean the change log: keep how many days? Older entries are written to a file on the server (a .jsonl in the archive folder), then removed from the database. The newest entry of each table always stays, so undo and restore official still work.\n\nNow: %s, %d entries."),
            Mb(st.bytes or 0), st.rows or 0),
        button1 = ACCEPT or "OK", button2 = CANCEL or "Cancel",
        hasEditBox = 1, maxLetters = 4,
        OnShow = function(self) self.editBox:SetText(tostring(st.keep or 30)); self.editBox:HighlightText() end,
        OnAccept = function(self)
            local d = tonumber(self.editBox:GetText())
            if not d or d < 0 then Status(T("请填天数（0 到 3650）", "Enter a number of days (0 to 3650)"), true) return end
            Cmd("logarchive " .. math.floor(d))
            Status(T("已发送，等服务端回答…", "Sent, waiting for the server…"))
            DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55[LootLab]|r " .. string.format(T("已请求归档 %d 天前的旧日志，等服务端回答…", "Archive of the log older than %d days requested, waiting for the server..."), math.floor(d)))
        end,
        EditBoxOnEnterPressed = function(self)
            local d = tonumber(self:GetText())
            if d and d >= 0 then Cmd("logarchive " .. math.floor(d)); Status(T("已发送，等服务端回答…", "Sent, waiting for the server…")) end
            self:GetParent():Hide()
        end,
        timeout = 0, whileDead = 1, hideOnEscape = 1,
    }
    StaticPopup_Show("REBORN_LOOTLAB_ARCHIVE")
end

-- the change log, newest first
function ui.ShowLog()
    if not ui.logPop then
        local p = CreateFrame("Frame", "RebornLootLabLogPop", UIParent)
        p:SetSize(620, 400)
        p:SetPoint("CENTER")
        p:SetFrameStrata("FULLSCREEN_DIALOG")
        p:SetToplevel(true)
        p:EnableMouse(true)
        p:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        })
        local t = p:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        t:SetPoint("TOP", 0, -18)
        Bind(t, "改动日志（最近 60 条）", "Change log (last 60)")
        p.text = p:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        p.text:SetPoint("TOPLEFT", 22, -46)
        p.text:SetPoint("BOTTOMRIGHT", -22, 50)
        p.text:SetJustifyH("LEFT")
        p.text:SetJustifyV("TOP")
        local close = Button(p, 90, "关闭", "Close", function() p:Hide() end)
        close:SetPoint("BOTTOM", 80, 18)
        local arch = Button(p, 150, "归档并清理…", "Archive and clean…", function() ui.AskArchive() end)   -- LAB3B
        arch:SetPoint("BOTTOM", -60, 18)
        p.arch = arch
        if UISpecialFrames then table.insert(UISpecialFrames, "RebornLootLabLogPop") end
        ui.logPop = p
    end
    ui.logPop.text:SetText(T("读取中…", "Loading…"))
    ui.logPop:Show()
    ui.logPop:Raise()
end

function ui.FillLog()
    if not ui.logPop then return end
    local lines = {}
    for _, e in ipairs(state.log or {}) do
        lines[#lines + 1] = string.format("|cff9d9d9d#%d %s|r %s  |cffffd100%s #%d|r  %s", e.id, date("%m-%d %H:%M", e.ts), e.who, e.kind, e.loot, e.action)
    end
    ui.logPop.text:SetText(#lines > 0 and table.concat(lines, "\n") or T("还没有任何改动。", "No changes yet."))
end

function ui.BuildEditBar(mid)
    local bar = CreateFrame("Frame", nil, mid)
    bar:SetHeight(26)
    bar:SetPoint("BOTTOMLEFT", 8, 6)
    bar:SetPoint("BOTTOMRIGHT", -8, 6)
    ui.editBar = bar
    ui.editToggle = Button(bar, 112, "编辑模式", "Edit mode", function()
        state.editMode = not state.editMode
        RefreshAll()
    end)
    ui.editToggle.noBind = true
    ui.editToggle:SetPoint("LEFT", 0, 0)
    ui.addBtn = Button(bar, 78, "添加物品", "Add item", function() ui.OpenAdd() end)
    ui.addBtn:SetPoint("LEFT", ui.editToggle, "RIGHT", 4, 0)
    ui.undoBtn = Button(bar, 58, "撤销", "Undo", function() EditCmd("undo") end)
    ui.undoBtn:SetPoint("LEFT", ui.addBtn, "RIGHT", 4, 0)
    ui.restoreBtn = Button(bar, 98, "还原官方", "Restore official", function() ui.ConfirmRestore() end)
    ui.restoreBtn:SetPoint("LEFT", ui.undoBtn, "RIGHT", 4, 0)
    ui.logBtn = Button(bar, 58, "日志", "Log", function() Cmd("log"); ui.ShowLog() end)
    ui.logBtn:SetPoint("LEFT", ui.restoreBtn, "RIGHT", 4, 0)
    ui.restoreAllBtn = Button(bar, 98, "还原全部", "Restore all", function() ui.ConfirmRestoreAll() end)  -- LAB3A
    ui.restoreAllBtn:SetPoint("LEFT", ui.logBtn, "RIGHT", 4, 0)
    ui.restoreAllBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine(T("还原全部", "Restore all"))
        GameTooltip:AddLine(T("把工坊改过的每一张掉落表都还原成官方原样，不用一张一张点。", "Puts every loot table the workshop changed back to the official content, no need to go table by table."), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    ui.restoreAllBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    bar:Hide()
end

function ui.RefreshEdit()
    if ui.titleText then ui.titleText:SetText(TitleText()) end
    if not ui.editBar then return end
    if state.canEdit then ui.editBar:Show() else ui.editBar:Hide(); state.editMode = false end
    if ui.editToggle then
        ui.editToggle:SetText(state.editMode and T("编辑模式：开", "Edit mode: on") or T("编辑模式：关", "Edit mode: off"))
    end
    local on = state.canEdit and state.editMode and state.sel ~= nil
    for _, b in ipairs({ ui.addBtn, ui.undoBtn, ui.restoreBtn }) do
        if b then if on then b:Enable() else b:Disable() end end
    end
    if ui.restoreAllBtn then   -- LAB3A: needs no selected table, only the edit mode
        if state.canEdit and state.editMode then ui.restoreAllBtn:Enable() else ui.restoreAllBtn:Disable() end
    end
end

local function BuildMain()
    local main = CreateFrame("Frame", "RebornLootLabFrame", UIParent)
    local sz = RebornLootLabDB and RebornLootLabDB.size
    main:SetSize(sz and math.max(1100, sz[1]) or 1100, sz and math.max(520, sz[2]) or 600)
    main:SetResizable(true)
    if main.SetMinResize then main:SetMinResize(1100, 520) end
    if main.SetMaxResize then main:SetMaxResize(1900, 1100) end
    main:SetPoint("CENTER")
    main:SetFrameStrata("FULLSCREEN_DIALOG")
    main:SetMovable(true)
    main:EnableMouse(true)
    main:SetClampedToScreen(true)
    main:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    ui.main = main
    tinsert(UISpecialFrames, "RebornLootLabFrame")

    local drag = CreateFrame("Frame", nil, main)
    drag:SetPoint("TOPLEFT", 0, 0)
    drag:SetPoint("TOPRIGHT", -40, 0)
    drag:SetHeight(32)
    drag:EnableMouse(true)
    drag:RegisterForDrag("LeftButton")
    drag:SetScript("OnDragStart", function() main:StartMoving() end)
    drag:SetScript("OnDragStop", function() main:StopMovingOrSizing() end)

    local title = main:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 18, -14)
    title:SetText(TitleText())
    ui.titleText = title

    local close = CreateFrame("Button", nil, main, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)

    -- the language button (self-drawn: a template button stays black here)
    local lang = CreateFrame("Button", nil, main)
    lang:SetSize(54, 20)
    lang:SetPoint("TOPRIGHT", -44, -12)
    local bg = lang:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(0.25, 0.18, 0.05, 0.9)
    local fs = lang:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("CENTER")
    lang.fs = fs
    lang:SetFrameLevel(main:GetFrameLevel() + 20)   -- above everything else in the title bar
    lang:RegisterForClicks("LeftButtonUp")
    lang:SetScript("OnClick", function()
        RebornLootLabDB = RebornLootLabDB or {}
        RebornLootLabDB.lang = IsZh() and "en" or "zh"
        local ok, err = pcall(function()
            title:SetText(TitleText())
            fs:SetText(IsZh() and "中文 / EN" or "EN / 中文")
            RefreshAll()
        end)
        if not ok then DEFAULT_CHAT_FRAME:AddMessage("|cffff3333[RebornLootLab] language switch: " .. tostring(err) .. "|r") end
    end)
    fs:SetText(IsZh() and "中文 / EN" or "EN / 中文")

    -- experimental 3D heads in the creature list (off by default)
    state.show3d = not (RebornLootLabDB and RebornLootLabDB.show3d == false)   -- on unless switched off
    local m3 = CreateFrame("Button", nil, main)
    m3:SetSize(96, 20)
    m3:Hide()   -- 3D heads are switched off
    m3:SetPoint("RIGHT", lang, "LEFT", -6, 0)
    local m3bg = m3:CreateTexture(nil, "BACKGROUND")
    m3bg:SetAllPoints()
    m3bg:SetTexture(0.25, 0.18, 0.05, 0.9)
    local fs3 = m3:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs3:SetPoint("CENTER")
    function ui.Label3D()
        fs3:SetText(state.show3d and T("3D头像：开", "3D heads: on") or T("3D头像：关", "3D heads: off"))
    end
    m3:SetScript("OnClick", function()
        state.show3d = not state.show3d
        RebornLootLabDB = RebornLootLabDB or {}
        RebornLootLabDB.show3d = state.show3d
        RefreshAll()
    end)
    m3:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine(T("3D 头像", "3D heads"), 1, 0.82, 0)
        GameTooltip:AddLine(T("在来源列表里显示怪物 / 物件的真实模型。关掉就只用图标（模型多时更省资源）。", "Show the real model of each creature / object in the source list. Switch it off to use plain icons (lighter when many are shown)."), 0.9, 0.9, 0.9, true)
        GameTooltip:Show()
    end)
    m3:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local grip = CreateFrame("Button", nil, main)
    grip:SetSize(18, 18)
    grip:SetPoint("BOTTOMRIGHT", -6, 6)
    grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    grip:SetScript("OnMouseDown", function() main:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp", function()
        main:StopMovingOrSizing()
        RebornLootLabDB = RebornLootLabDB or {}
        RebornLootLabDB.size = { main:GetWidth(), main:GetHeight() }
    end)
    main:SetScript("OnSizeChanged", function(_, w, h) if ui.Layout then ui.Layout(w, h) end end)

    -- the kind tabs
    ui.tabs = {}
    main:SetScript("OnShow", function() Cmd("ping") end)

    BuildLeft(main)
    BuildRight(main)
    BuildMiddle(main)

    ui.status = main:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ui.status:SetPoint("BOTTOMLEFT", 20, 14)
    ui.status:SetPoint("RIGHT", -20, 0)
    ui.status:SetJustifyH("LEFT")
    built = true
    ui.Layout()
end

-- the lists show as many rows as the window has room for; the tabs share the width
function ui.Layout(w, h)
    if not built then return end
    w = w or ui.main:GetWidth()
    h = h or ui.main:GetHeight()
    ui.srcList:SetN(math.floor((h - 210) / 34))
    ui.lootList:SetN(math.floor((h - 218) / 18))
    ui.simList:SetN(math.floor((h - 218) / 18))
    ui.itemList:SetN(math.floor((h - 236) / 18))
    ui.whoList:SetN(math.floor((h - 236) / 18))
    local count = math.max(1, #state.kindOrder)
    local tw = math.floor((w - 36) / count) - 2
    for i, key in ipairs(state.kindOrder) do
        local b = ui.tabs[key]
        if b then
            b:SetWidth(tw)
            b:ClearAllPoints()
            b:SetPoint("TOPLEFT", ui.main, "TOPLEFT", 18 + (i - 1) * (tw + 2), -38)
        end
    end
end

local function BuildTabs()
    if not ui.main then return end
    local x = 18
    for _, key in ipairs(state.kindOrder) do
        if not ui.tabs[key] then
            local b = Button(ui.main, 104, "", "", function() SetKind(key) end)
            b:SetPoint("TOPLEFT", ui.main, "TOPLEFT", x, -38)
            if b.SetNormalFontObject then
                b:SetNormalFontObject("GameFontNormalSmall")
                b:SetHighlightFontObject("GameFontHighlightSmall")
                b:SetDisabledFontObject("GameFontHighlightSmall")
            end
            b.noBind = true
            ui.tabs[key] = b
        end
        x = x + 106
    end
    if ui.Layout then ui.Layout() end
end

local oldRefresh = RefreshAll
function RefreshAll()
    BuildTabs()
    oldRefresh()
end

local function Toggle()
    if not ui.main then
        local ok, err = pcall(BuildMain)
        if not ok then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff3333[RebornLootLab] " .. tostring(err) .. "|r")
            return
        end
    end
    if ui.main:IsShown() then
        ui.main:Hide()
    else
        ui.main:Show()
        Cmd("kinds")
        if not state.mapsAsked then state.mapsAsked = true; Cmd("maps") end
        RefreshAll()
    end
end

-- a round button on the minimap: click = open / close, drag = move it around the minimap
local function MinimapButton()
    if ui.mini or not Minimap then return end
    RebornLootLabDB = RebornLootLabDB or {}
    local b = CreateFrame("Button", "RebornLootLabMinimapButton", Minimap)
    b:SetSize(31, 31)
    b:SetFrameStrata("MEDIUM")
    b:SetFrameLevel(8)
    b:RegisterForClicks("LeftButtonUp")
    b:RegisterForDrag("LeftButton")
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    hl:SetBlendMode("ADD")
    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("TOPLEFT", 6, -6)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Spyglass_03")
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    local border = b:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    local function Place(angle)
        local r = (Minimap:GetWidth() / 2) + 5
        b:ClearAllPoints()
        b:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * r, math.sin(angle) * r)
    end
    Place(math.rad(RebornLootLabDB.minimapAngle or 215))
    b:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local s = Minimap:GetEffectiveScale()
            local a = math.atan2(cy / s - my, cx / s - mx)
            RebornLootLabDB.minimapAngle = math.deg(a)
            Place(a)
        end)
    end)
    b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    b:SetScript("OnClick", function() Toggle() end)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(T("掉落工坊", "LootLab"), 1, 0.82, 0)
        GameTooltip:AddLine(T("点击打开 / 关闭，拖动可移动位置", "Click to open / close, drag to move"), 0.9, 0.9, 0.9)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    ui.mini = b
end

local events = CreateFrame("Frame")
events:RegisterEvent("CHAT_MSG_ADDON")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(_, event, prefix, msg)
    if event == "PLAYER_LOGIN" then
        local ok, err = pcall(MinimapButton)
        if not ok then DEFAULT_CHAT_FRAME:AddMessage("|cffff3333[RebornLootLab] " .. tostring(err) .. "|r") end
    elseif event == "CHAT_MSG_ADDON" then
        if prefix ~= ADDON_PREFIX or type(msg) ~= "string" or not built then return end
        local ok, err = pcall(OnServer, msg)
        if not ok then DEFAULT_CHAT_FRAME:AddMessage("|cffff3333[RebornLootLab] " .. tostring(err) .. "|r") end
    end
end)

SLASH_REBORNLOOTLAB1 = "/lootlab"
SLASH_REBORNLOOTLAB2 = "/lab"
SlashCmdList["REBORNLOOTLAB"] = Toggle
