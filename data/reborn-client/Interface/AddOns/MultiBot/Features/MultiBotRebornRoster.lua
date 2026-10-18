-- RebornWOW MBR1A: a units list you can find your party in.
--
-- The stock list is every character on your account (any level, both factions) in
-- name order, because the server's "Bot roster:" line carries only name and class.
-- This file asks the dungeon-clear module (addon channel "DC", request "botinfo")
-- for each character's level / race / faction / online state and then:
--   * hides characters of the other faction (toggle: /mbr faction),
--   * sorts: favourites first, then closest to your level, then higher level,
--   * shows the level on each icon and a star on favourites,
--   * Shift+click an icon = add to / remove from your favourites ("常用组队"),
--   * favourites that are not on your account (random bots you team up with) get an
--     icon too, and clicking or the Invite button invites them with /invite.
-- Hooks in the stock files: Units.doLeft and Browse call MultiBot.RebornOrderUnits;
-- the invite timer calls MultiBot.RebornInvite; favourites allow Invite.

local ZH = GetLocale() == "zhCN" or GetLocale() == "zhTW"
local function L(en, zh) return ZH and zh or en end

local CLASS_BY_ID = { [1] = "Warrior", [2] = "Paladin", [3] = "Hunter", [4] = "Rogue", [5] = "Priest",
                      [6] = "DeathKnight", [7] = "Shaman", [8] = "Mage", [9] = "Warlock", [11] = "Druid" }
local STAR = "Interface\\TARGETINGFRAME\\UI-RaidTargetingIcon_1"

local info = {}               -- name -> { cls, level, race, team (0 alliance / 1 horde), online, mine }
MultiBot.rebornBotInfo = info
local wanted = {}             -- names seen in a list without info yet
local lastRequest = -100

local function Save()
    MultiBotSave = MultiBotSave or {}
    return MultiBotSave
end
local function SameFactionOnly() return Save().RebornSameFaction ~= false end
local function MyTeam() return UnitFactionGroup("player") == "Horde" and 1 or 0 end
local function Say(msg) DEFAULT_CHAT_FRAME:AddMessage("|cff3da6ff[MultiBot]|r " .. msg) end
local function IsMember(name) return MultiBot.isMember and MultiBot.isMember(name) or false end

local function Units()
    return MultiBot.frames and MultiBot.frames.MultiBar and MultiBot.frames.MultiBar.frames
        and MultiBot.frames.MultiBar.frames.Units
end

-- ------------------------------------------------------------------ request
local function SendCmd(param)
    local payload = "CMD\tbotinfo\t" .. param
    if GetNumRaidMembers() > 0 then
        SendAddonMessage("DC", payload, "RAID")
    elseif GetNumPartyMembers() > 0 then
        SendAddonMessage("DC", payload, "PARTY")
    else
        SendAddonMessage("DC", payload, "WHISPER", UnitName("player"))
    end
end

-- "a|" = also your account's characters; the names after it are favourites and
-- list entries the server has not described yet. Chunks stay under the 255-byte cap.
function MultiBot.RebornRequestBotInfo(force)
    local now = GetTime()
    if not force and now - lastRequest < 20 then return end
    lastRequest = now
    local names, seen = {}, {}
    for name in pairs(Save().Favorites or {}) do
        if not seen[name] then seen[name] = true; names[#names + 1] = name end
    end
    for name in pairs(wanted) do
        if not seen[name] and #names < 40 then seen[name] = true; names[#names + 1] = name end
    end
    local chunk, first = "", true
    local function flush()
        SendCmd((first and "a|" or "|") .. chunk)
        first, chunk = false, ""
    end
    for _, n in ipairs(names) do
        if #chunk + #n + 1 > 200 then flush() end
        chunk = (chunk == "") and n or (chunk .. "," .. n)
    end
    flush()
end

-- ------------------------------------------------------------------ display
local function Refresh()
    local b = MultiBot.frames and MultiBot.frames.MultiBar and MultiBot.frames.MultiBar.buttons
        and MultiBot.frames.MultiBar.buttons.Units
    local u = Units()
    if b and u and u:IsShown() and b.doLeft then b.doLeft(b, b.roster) end
end

local function ToggleFavorite(name)
    MultiBot.ToggleFavorite(name)
    if MultiBot.IsFavorite(name) then
        Say(string.format(L("%s added to your favourites (right-click the roster button for the favourites list).",
                            "%s 已加入常用组队（右键名单按钮可直接打开常用列表）。"), name))
    else
        Say(string.format(L("%s removed from your favourites.", "%s 已移出常用组队。"), name))
    end
    MultiBot.RebornRequestBotInfo(true)
    Refresh()
end

-- Shift+click toggles the favourite; anything else runs whatever handler the stock
-- code put there last (the roster parser reassigns them on every refresh).
local function WrapClicks(b)
    if b.doLeft ~= b.rebornLeftWrapper then
        local inner = b.doLeft
        b.rebornLeftWrapper = function(btn)
            if IsShiftKeyDown() then return ToggleFavorite(btn.name) end
            if inner then return inner(btn) end
        end
        b.doLeft = b.rebornLeftWrapper
    end
end

local function Decorate(b, name)
    if not b.rebornLevel then
        b.rebornLevel = b:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
        b.rebornLevel:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", 1, 1)
        b.rebornStar = b:CreateTexture(nil, "OVERLAY")
        b.rebornStar:SetTexture(STAR)
        b.rebornStar:SetWidth(12)
        b.rebornStar:SetHeight(12)
        b.rebornStar:SetPoint("TOPLEFT", b, "TOPLEFT", -3, 3)
    end
    WrapClicks(b)
    local i = info[name]
    if i then
        local d = math.abs(i.level - UnitLevel("player"))
        local color = (not i.online and not i.mine) and "|cff808080" or (d == 0 and "|cff40ff40" or (d <= 3 and "|cffffd100" or "|cffbbbbbb"))
        b.rebornLevel:SetText(color .. i.level .. "|r")
    else
        b.rebornLevel:SetText("")
    end
    if MultiBot.IsFavorite(name) then b.rebornStar:Show() else b.rebornStar:Hide() end
    if i and b.class and MultiBot.toTip then
        local where = i.team == 1 and L("Horde", "部落") or L("Alliance", "联盟")
        local state = i.online and L("online", "在线") or L("offline", "离线")
        local own = i.mine and L("your character", "你的角色") or L("other account", "非本账号")
        b.tip = MultiBot.toTip(b.class, i.level, name) ..
            "\n|cffaaaaaa" .. where .. " / " .. state .. " / " .. own .. "|r" ..
            "\n|cffffd100" .. L("Shift+click: add to / remove from favourites", "Shift+点击：加入/移出常用组队") .. "|r"
    end
end

-- A favourite that is not on your account (a random bot) has no icon in the stock
-- list; make one once the server has told us its class.
local function Invite(name)
    local i = info[name]
    if i and not i.mine then
        if not i.online then
            Say(string.format(L("%s is offline.", "%s 不在线。"), name))
            return
        end
        InviteUnit(name)
        return
    end
    SendChatMessage(".playerbot bot add " .. name, "SAY")
end

local function EnsureFavoriteButton(name)
    local u = Units()
    if not u or u.buttons[name] then return end
    local i = info[name]
    local cls = i and CLASS_BY_ID[i.cls]
    if not cls then return end
    local tex = "Interface\\AddOns\\MultiBot\\Icons\\class_" .. string.lower(cls) .. ".blp"
    local b = u.addButton(name, 0, 0, tex, MultiBot.toTip(cls, i.level, name))
    if IsMember(name) then b.setEnable() else b.setDisable() end
    b.roster, b.class, b.name = "favorites", cls, name
    b.doLeft = function(p)
        if p.state then
            if p.parent.frames[p.name] then MultiBot.ShowHideSwitch(p.parent.frames[p.name]) end
        else
            Invite(p.name)
        end
    end
    b.doRight = function(p)
        if not p.state then return end
        if info[p.name] and not info[p.name].mine then UninviteUnit(p.name)
        else SendChatMessage(".playerbot bot remove " .. p.name, "SAY") end
        if p.parent.frames[p.name] then p.parent.frames[p.name]:Hide() end
        p.setDisable()
    end
end

-- Called by the stock Units.doLeft / Browse with the list they are about to show.
-- Returns the list to show: other faction dropped (unless already in your group),
-- favourites first, then by distance from your level, higher level first; names
-- without an icon are dropped (the stock code skips them anyway).
function MultiBot.RebornOrderUnits(list, roster)
    if not list then return list end
    local u = Units()
    local myLevel, myTeam, same = UnitLevel("player"), MyTeam(), SameFactionOnly()
    local out, pos = {}, {}
    for _, name in ipairs(list) do
        if name and not pos[name] then
            if roster == "favorites" then EnsureFavoriteButton(name) end
            local i = info[name]
            if not i then wanted[name] = true end
            local hide = same and i and i.team ~= myTeam and not IsMember(name)
            if not hide and u and u.buttons[name] then
                out[#out + 1] = name
                pos[name] = #out
            end
        end
    end
    table.sort(out, function(a, b)
        local fa, fb = MultiBot.IsFavorite(a), MultiBot.IsFavorite(b)
        if fa ~= fb then return fa end
        local ia, ib = info[a], info[b]
        if (ia ~= nil) ~= (ib ~= nil) then return ia ~= nil end
        if ia and ib then
            local da, db = math.abs(ia.level - myLevel), math.abs(ib.level - myLevel)
            if da ~= db then return da < db end
            if ia.level ~= ib.level then return ia.level > ib.level end
        end
        return pos[a] < pos[b]
    end)
    for _, name in ipairs(out) do Decorate(u.buttons[name], name) end
    if next(wanted) then MultiBot.RebornRequestBotInfo(false) end
    return out
end

-- Called by the invite timer. True = handled here (a random-bot favourite, or a
-- character of the other faction that is skipped); false = use .playerbot bot add.
function MultiBot.RebornInvite(name)
    local i = info[name]
    if not i then return false end
    if SameFactionOnly() and i.team ~= MyTeam() then
        Say(string.format(L("%s is of the other faction, skipped.", "%s 是另一个阵营，已跳过。"), name))
        return true
    end
    if i.mine then return false end
    Invite(name)
    return true
end

-- ------------------------------------------------------------------ events
local ev = CreateFrame("Frame")
local askAt = nil
ev:Hide()  -- OnUpdate only while a request is scheduled
ev:RegisterEvent("CHAT_MSG_ADDON")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:SetScript("OnEvent", function(self, event, prefix, msg)
    if event == "PLAYER_ENTERING_WORLD" then
        askAt = GetTime() + 6
        self:Show()
        return
    end
    if prefix ~= "DC" or type(msg) ~= "string" then return end
    if msg:sub(1, 3) == "BI\t" then
        local _, name, cls, level, race, team, online, mine = strsplit("\t", msg)
        if name and name ~= "" then
            info[name] = { cls = tonumber(cls) or 0, level = tonumber(level) or 0, race = tonumber(race) or 0,
                           team = tonumber(team) or 0, online = online == "1", mine = mine == "1" }
            wanted[name] = nil
        end
    elseif msg == "BI_END" then
        Refresh()
    end
end)
ev:SetScript("OnUpdate", function(self)
    if askAt and GetTime() >= askAt then
        askAt = nil
        self:Hide()
        MultiBot.RebornRequestBotInfo(true)
    end
end)

SLASH_MULTIBOTREBORN1 = "/mbr"
SlashCmdList["MULTIBOTREBORN"] = function(msg)
    msg = string.lower(msg or "")
    if msg == "faction" then
        Save().RebornSameFaction = not SameFactionOnly()
        Say(SameFactionOnly() and L("Units list: your faction only.", "单位列表：只显示同阵营。")
                              or L("Units list: both factions.", "单位列表：显示两个阵营。"))
        Refresh()
    elseif msg == "refresh" then
        MultiBot.RebornRequestBotInfo(true)
    else
        Say(L("/mbr faction - show only your faction (on/off); /mbr refresh - reload levels. Shift+click a unit icon to add it to your favourites; right-click the roster button for the favourites list.",
              "/mbr faction 只显示同阵营（开/关）；/mbr refresh 重新读取等级。Shift+点击单位图标加入常用组队；右键名单按钮直接打开常用组队列表。"))
    end
end
