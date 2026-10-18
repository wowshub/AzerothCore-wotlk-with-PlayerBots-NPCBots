-- RebornWOW MBR1A/1B: a units list you can find your party in.
--
-- The stock list is every character on your account (any level, both factions) in
-- name order, because the server's "Bot roster:" line carries only name and class.
-- This file asks the dungeon-clear module (addon channel "DC", request "botinfo")
-- for each character's level / race / faction / online state and then:
--   * hides characters of the other faction (toggle: /mbr faction),
--   * sorts: favourites first, then closest to your level, then higher level;
--     your own "self-bot" switch goes last,
--   * shows the level on each icon and a star on favourites,
--   * Shift+click an icon = add to / remove from your favourites ("常用组队"),
--   * favourites that are not on your account (random bots you team up with) get an
--     icon too, and clicking or the Invite button invites them with /invite,
--   * MBR1B: every bot in your party / raid gets an icon even when the stock code
--     dropped it (custom classes such as Demon Hunter have no class name in the
--     server's roster line; bots already grouped before a /reload never greet again),
--     and a star button above the list opens the favourites.
-- Hooks in the stock files: Units.doLeft and Browse call MultiBot.RebornOrderUnits;
-- the invite timer calls MultiBot.RebornInvite; favourites allow Invite.

local function ZH()
    if MultiBot.GetLanguage then return MultiBot.GetLanguage() == "zhCN" end
    return GetLocale() == "zhCN"
end
local function L(en, zh) return ZH() and zh or en end

local CLASS_BY_ID = { [1] = "Warrior", [2] = "Paladin", [3] = "Hunter", [4] = "Rogue", [5] = "Priest",
                      [6] = "DeathKnight", [7] = "Shaman", [8] = "Mage", [9] = "Warlock", [11] = "Druid" }
local STAR = "Interface\\TARGETINGFRAME\\UI-RaidTargetingIcon_1"

local info = {}               -- name -> { cls, level, race, team (0 alliance / 1 horde), online, mine }
MultiBot.rebornBotInfo = info
local wanted = {}             -- names seen in a list without info, not asked yet
local asked = {}              -- names already asked once (MBR1B: never re-ask on a timer)
local greeted = {}            -- group members we sent "co ?" to (MBR1B)
local lastRequest = -100

local function Save()
    MultiBotSave = MultiBotSave or {}
    return MultiBotSave
end
local function SameFactionOnly() return Save().RebornSameFaction ~= false end
local function MyTeam() return UnitFactionGroup("player") == "Horde" and 1 or 0 end
local function Say(msg) DEFAULT_CHAT_FRAME:AddMessage("|cff3da6ff[MultiBot]|r " .. msg) end
local function IsMember(name) return MultiBot.isMember and MultiBot.isMember(name) or false end
local function Me() return UnitName("player") end

local function Units()
    return MultiBot.frames and MultiBot.frames.MultiBar and MultiBot.frames.MultiBar.frames
        and MultiBot.frames.MultiBar.frames.Units
end

-- party1..4 / raid1..40 -> name -> unit id
local function GroupUnits()
    local out = {}
    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            local u = "raid" .. i
            local n = UnitName(u)
            if n and n ~= Me() then out[n] = u end
        end
    else
        for i = 1, GetNumPartyMembers() do
            local u = "party" .. i
            local n = UnitName(u)
            if n then out[n] = u end
        end
    end
    return out
end

-- ------------------------------------------------------------------ request
local function SendCmd(param)
    local payload = "CMD\tbotinfo\t" .. param
    if GetNumRaidMembers() > 0 then
        SendAddonMessage("DC", payload, "RAID")
    elseif GetNumPartyMembers() > 0 then
        SendAddonMessage("DC", payload, "PARTY")
    else
        SendAddonMessage("DC", payload, "WHISPER", Me())
    end
end

-- "a|" = also your account's characters; the names after it are favourites and list
-- entries the server has not described yet. Chunks stay under the 255-byte cap.
-- force: ask again for everything (login, group change, /mbr refresh); otherwise only
-- names never asked before -- a name the server cannot find is asked once, so the list
-- is not re-laid out every few seconds (that closed the tooltip under the mouse).
function MultiBot.RebornRequestBotInfo(force)
    local now = GetTime()
    if not force and now - lastRequest < 5 then return end
    local names, seen = {}, {}
    local function add(name)
        if name and not seen[name] and #names < 40 then
            seen[name] = true
            names[#names + 1] = name
            asked[name] = true
        end
    end
    if force then
        for name in pairs(Save().Favorites or {}) do add(name) end
        for name in pairs(GroupUnits()) do add(name) end
    end
    for name in pairs(wanted) do
        if force or not asked[name] then add(name) end
    end
    wipe(wanted)
    if not force and #names == 0 then return end
    lastRequest = now
    local chunk, first = "", true
    local function flush()
        SendCmd(((first and force) and "a|" or "|") .. chunk)
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
        Say(string.format(L("%s added to your favourites (star button above the list).",
                            "%s 已加入常用组队（列表上方的星标按钮打开常用列表）。"), name))
    else
        Say(string.format(L("%s removed from your favourites.", "%s 已移出常用组队。"), name))
    end
    if not info[name] then wanted[name] = true end
    MultiBot.RebornRequestBotInfo(false)
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

-- The class shown in a tooltip: the stock name, or for a custom class (Unknown to
-- MultiBot) the game's own localized name when the unit is in your group.
local function ClassLabel(b, name)
    if b.class and b.class ~= "Unknown" then return b.class end
    local unit = GroupUnits()[name]
    local loc = unit and UnitClass(unit)
    return loc or b.class or "?"
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
    if name == Me() then  -- the stock self-bot switch keeps its own icon and tooltip
        b.rebornLevel:SetText("")
        b.rebornStar:Hide()
        return
    end
    WrapClicks(b)
    local i = info[name]
    local unit = GroupUnits()[name]
    local level = (i and i.level) or (unit and UnitLevel(unit)) or nil
    if level then
        local d = math.abs(level - UnitLevel("player"))
        local offline = i and not i.online and not i.mine
        local color = offline and "|cff808080" or (d == 0 and "|cff40ff40" or (d <= 3 and "|cffffd100" or "|cffbbbbbb"))
        b.rebornLevel:SetText(color .. level .. "|r")
    else
        b.rebornLevel:SetText("")
    end
    if MultiBot.IsFavorite(name) then b.rebornStar:Show() else b.rebornStar:Hide() end
    if MultiBot.toTip and (i or unit) then
        local lines = ""
        if i then
            local where = i.team == 1 and L("Horde", "部落") or L("Alliance", "联盟")
            local state = i.online and L("online", "在线") or L("offline", "离线")
            local own = i.mine and L("your character", "你的角色") or L("other account", "非本账号")
            lines = "\n|cffaaaaaa" .. where .. " / " .. state .. " / " .. own .. "|r"
        end
        if unit then lines = lines .. "\n|cff40ff40" .. L("in your group", "在你的队伍里") .. "|r" end
        b.tip = MultiBot.toTip(ClassLabel(b, name), level, name) .. lines ..
            "\n|cffffd100" .. L("Shift+click: add to / remove from favourites", "Shift+点击：加入/移出常用组队") .. "|r"
    end
end

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

local function StockHandlers(b)
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

-- A favourite that is not on your account (a random bot) has no icon in the stock
-- list; make one once the server has told us its class.
local function EnsureFavoriteButton(name)
    local u = Units()
    if not u or u.buttons[name] then return end
    local i = info[name]
    if not i then return end
    local cls = CLASS_BY_ID[i.cls] or "Unknown"
    local tex = "Interface\\AddOns\\MultiBot\\Icons\\class_" .. string.lower(cls) .. ".blp"
    local b = u.addButton(name, 0, 0, tex, MultiBot.toTip(cls, i.level, name))
    if IsMember(name) then b.setEnable() else b.setDisable() end
    b.roster, b.class, b.name = "favorites", cls, name
    StockHandlers(b)
end

-- MBR1B: a group member the stock list never picked up gets an icon and the same
-- "co ?" handshake the stock code runs when a bot greets you, which builds its
-- strategy bar and adds it to the actives.
local function EnsureGroupButtons()
    local u = Units()
    if not u or not MultiBot.addActive then return {} end
    local names = {}
    for name, unit in pairs(GroupUnits()) do
        names[#names + 1] = name
        local b = u.buttons[name]
        if not b then
            local _, token = UnitClass(unit)
            b = MultiBot.addActive(token, UnitLevel(unit), name)
            b.setDisable()
            StockHandlers(b)
        end
        if not greeted[name] and not (MultiBot.isActive and MultiBot.isActive(name)) then
            greeted[name] = true
            b.waitFor = "CO"
            SendChatMessage("co ?", "WHISPER", nil, name)
        end
        if not info[name] and not asked[name] then wanted[name] = true end
    end
    return names
end

-- Called by the stock Units.doLeft / Browse with the list they are about to show.
-- Returns the list to show: other faction dropped (unless already in your group),
-- favourites first, then by distance from your level, higher level first, yourself
-- last; group members always included; names without an icon are dropped.
function MultiBot.RebornOrderUnits(list, roster)
    if not list then return list end
    local u = Units()
    if not u then return list end
    local myLevel, myTeam, same, me = UnitLevel("player"), MyTeam(), SameFactionOnly(), Me()
    local source = {}
    for _, name in ipairs(list) do source[#source + 1] = name end
    if roster == "players" or roster == "actives" then
        for _, name in ipairs(EnsureGroupButtons()) do source[#source + 1] = name end
    end
    local out, pos = {}, {}
    for _, name in ipairs(source) do
        if name and not pos[name] then
            if roster == "favorites" then EnsureFavoriteButton(name) end
            local i = info[name]
            if not i and not asked[name] then wanted[name] = true end
            local hide = same and i and i.team ~= myTeam and not IsMember(name)
            if not hide and u.buttons[name] then
                out[#out + 1] = name
                pos[name] = #out
            end
        end
    end
    local group = GroupUnits()
    local function lvl(n)
        local i = info[n]
        if i then return i.level end
        local unit = group[n]
        return unit and UnitLevel(unit) or nil
    end
    table.sort(out, function(a, b)
        if (a == me) ~= (b == me) then return b == me end
        local fa, fb = MultiBot.IsFavorite(a), MultiBot.IsFavorite(b)
        if fa ~= fb then return fa end
        local la, lb = lvl(a), lvl(b)
        if (la ~= nil) ~= (lb ~= nil) then return la ~= nil end
        if la and lb then
            local da, db = math.abs(la - myLevel), math.abs(lb - myLevel)
            if da ~= db then return da < db end
            if la ~= lb then return la > lb end
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

-- ------------------------------------------------------------------ star button
-- MBR1B: one click to the favourites. It sits on top of the list's control column
-- (Filter 0, Roster 30, PvP 60, Invite 90, Browse 120 -> this one at 150).
local function SelectRoster(control, id, texture)
    local unitsBtn = MultiBot.frames.MultiBar.buttons.Units
    if MultiBot.Select then MultiBot.Select(control, "Roster", texture) end
    if control.buttons and control.buttons.Invite then control.buttons.Invite.setEnable() end
    if control.frames and control.frames.Invite then control.frames.Invite:Hide() end
    unitsBtn.doLeft(unitsBtn, id)
end

local function BuildStarButton()
    local u = Units()
    local control = u and u.frames and u.frames.Control
    if not control or not control.addButton or control.buttons.RebornFavorites then return end
    local tip = L("Favourites\n|cffffffffLeft-click: show your favourite bots.\nRight-click: back to all characters.\nShift+click any unit icon to add or remove a favourite.|r",
                  "常用组队\n|cffffffff左键：只显示常用组队的机器人。\n右键：回到全部角色。\n在任意单位图标上 Shift+点击 可以加入或移出常用组队。|r")
    local b = control.addButton("RebornFavorites", 0, 150, STAR, tip)
    b.doLeft = function() SelectRoster(control, "favorites", STAR) end
    b.doRight = function()
        SelectRoster(control, "players", "Interface\\AddOns\\MultiBot\\Icons\\roster_players.blp")
    end
end

-- ------------------------------------------------------------------ events
local ev = CreateFrame("Frame")
local askAt = nil
local changed = false
ev:Hide()  -- OnUpdate only while a request is scheduled
ev:RegisterEvent("CHAT_MSG_ADDON")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("PARTY_MEMBERS_CHANGED")
ev:RegisterEvent("RAID_ROSTER_UPDATE")
ev:SetScript("OnEvent", function(self, event, prefix, msg)
    if event == "PLAYER_ENTERING_WORLD" then
        BuildStarButton()
        askAt = GetTime() + 6
        self:Show()
        return
    end
    if event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
        askAt = GetTime() + 3   -- let the new member load, then describe it and redraw
        self:Show()
        return
    end
    if prefix ~= "DC" or type(msg) ~= "string" then return end
    if msg:sub(1, 3) == "BI\t" then
        local _, name, cls, level, race, team, online, mine = strsplit("\t", msg)
        if name and name ~= "" then
            local new = { cls = tonumber(cls) or 0, level = tonumber(level) or 0, race = tonumber(race) or 0,
                          team = tonumber(team) or 0, online = online == "1", mine = mine == "1" }
            local old = info[name]
            if not old or old.level ~= new.level or old.team ~= new.team or old.online ~= new.online
               or old.mine ~= new.mine or old.cls ~= new.cls then
                changed = true
            end
            info[name] = new
            wanted[name] = nil
        end
    elseif msg == "BI_END" then
        -- MBR1B: redraw only when something changed (a redraw closes the tooltip)
        if changed then
            changed = false
            Refresh()
        end
    end
end)
ev:SetScript("OnUpdate", function(self)
    if askAt and GetTime() >= askAt then
        askAt = nil
        self:Hide()
        BuildStarButton()
        MultiBot.RebornRequestBotInfo(true)
        changed = true  -- group changes: redraw even if every level was known
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
        wipe(greeted)
        MultiBot.RebornRequestBotInfo(true)
        changed = true
    else
        Say(L("/mbr faction - show only your faction (on/off); /mbr refresh - reload levels and group bots. Shift+click a unit icon to add it to your favourites; the star button above the list shows them.",
              "/mbr faction 只显示同阵营（开/关）；/mbr refresh 重新读取等级和队伍里的机器人。Shift+点击单位图标加入常用组队；列表上方的星标按钮显示常用组队。"))
    end
end
