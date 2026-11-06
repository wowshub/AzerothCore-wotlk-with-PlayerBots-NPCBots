-- 17 preview buttons: 9 Alliance (left) and 8 Horde (right). Ours keep REBORN* file strings, the new ones use the CoA 1.9.2 rows.

-- live nudge panel for races with a pos={x,y,z} (the camera cannot be set; x = up/down, z = near/far as measured in tests)
local nudge
local posStore = {}
-- each race keeps a far view and a near (close-up) view; the mouse wheel switches between them, the panel edits the current one
function NudgeGet(e)
    local s = posStore[e.k]
    if not s then
        local far = { e.pos and e.pos[1] or 0, e.pos and e.pos[2] or 0, e.pos and e.pos[3] or 0 }
        local near = e.near and { e.near[1], e.near[2], e.near[3] } or { far[1] + 24, far[2], far[3] }
        s = { far = far, near = near, mode = "far" }
        posStore[e.k] = s
    end
    return s[s.mode], s
end
function NudgeUpdate(e, p)
    if not nudge then
        nudge = CreateFrame("Frame", "RebornPreviewNudge", CharacterCreate)
        nudge:SetSize(250, 60) nudge:SetPoint("BOTTOMLEFT", CharacterCreate, "BOTTOMLEFT", 20, 120)
        nudge:SetFrameStrata("FULLSCREEN_DIALOG")
        nudge.text = nudge:CreateFontString(nil, "ARTWORK", "GlueFontNormalSmall")
        nudge.text:SetPoint("TOPLEFT", 0, 0)
        local defs = { {"远", -4, 0, 0}, {"近", 4, 0, 0}, {"左", 0, 1, 0}, {"右", 0, -1, 0}, {"上", 0, 0, 1}, {"下", 0, 0, -1}, {"重置", 0, 0, 0, true} }
        for i, d in ipairs(defs) do
            local b = CreateFrame("Button", nil, nudge)
            b:SetSize(34, 22) b:SetPoint("TOPLEFT", (i - 1) * 37, -22)
            local bg = b:CreateTexture(nil, "BACKGROUND") bg:SetAllPoints() bg:SetTexture(0.1, 0.1, 0.1, 0.9)
            local fs = b:CreateFontString(nil, "ARTWORK", "GlueFontNormalSmall") fs:SetPoint("CENTER") fs:SetText(d[1])
            b:SetScript("OnClick", function()
                local c = nudge.cur
                if not c then return end
                if d[5] then
                    local base = nudge.base or { 0, 0, 0 }
                    c[1], c[2], c[3] = base[1], base[2], base[3]
                else
                    c[1], c[2], c[3] = c[1] + d[2], c[2] + d[3], c[3] + d[4]
                end
                pcall(CharacterCreate.SetPosition, CharacterCreate, c[1], c[2], c[3])
                nudge.text:SetText((nudge.name or "") .. (nudge.mode == "near" and " 近景" or " 远景") .. "  pos " .. c[1] .. ", " .. c[2] .. ", " .. c[3])
            end)
        end
    end
    nudge.cur = NudgeGet(e)
    nudge.mode = posStore[e.k].mode
    nudge.base = e.pos or { 0, 0, 0 }
    nudge.name = e.n
    nudge.text:SetText(e.n .. (nudge.mode == "near" and " 近景" or " 远景") .. "  pos " .. nudge.cur[1] .. ", " .. nudge.cur[2] .. ", " .. nudge.cur[3])
    nudge:Show()
end

local E = {
    { k="Sethrak",     f="REBORNSETHRAK",       ic="R:Sethrak",     n="蛇人" },
    { k="KulTiran",    f="REBORNKULTIRAN",      ic="R:KulTiran",    n="库尔提拉斯人" },
    { k="Drakkin", sc=1, scF=4, zmax=2, f="DRAKKINALLIANCE",     ic="R:Drakkin",     n="德拉金" },
    { k="Arakkoa", sc=5, zmax=3,     f="ARAKKOA",             ic="R:Arakkoa",    n="鸦人" },
    { k="Earthen", sc=2, zmax=3,     f="EARTHEN",             ic="R:Earthen",    n="土灵" },
    { k="Mechagnome", sc=4,  f="MECHAGNOME",          ic="R:Mechagnome",  n="机械侏儒" },
    { k="Jinyu",       f="JINYU",               ic="R:Jinyu",       n="津鱼人" },
    { k="Broken",      f="COABROKEN",            ic="R:Broken",      n="破碎者" },
    { k="Ogre", sc=15, zmax=3,        f="REBORNOGRE",          ic="R:Ogre",        n="双头食人魔", horde=true },
    { k="MagHar",      f="MAGHAR",              ic="R:MagHar",      n="玛格汉兽人", horde=true },
    { k="Furbolg", sc=14,     f="REFORGEDFURBOLG",     ic="R:Furbolg",    n="熊怪", horde=true },
    { k="UndeadGnome", sc=18, f="GNOMEUNDEAD",         ic="R:UndeadGnome", n="亡灵侏儒", horde=true },
    { k="Venthyr", sc=15, zmax=3,     f="VENTHYRHORDE",        ic="R:Venthyr",    n="温西尔", horde=true },
    { k="HighmtnHD", sc=14,   f="HIGHMOUNTAINHD",      ic="R:HighmtnHD", n="高山牛头人", horde=true },
    { k="DrakkariTroll", sc=15, zmax=3, f="DRAKKARITROLL",     ic="R:DrakkariTroll", n="达卡莱巨魔", horde=true },
    { k="Sylvari",     f="SYLVARIALLIANCE",     ic="R:Sylvari",     n="希尔瓦里", horde=true },
}
local bs, A, B = {}, nil, nil
local function Open(e, sex)
    if PAID_SERVICE_TYPE then return end
    local v = { GetAvailableRaces() }
    local s
    for p = 1, #v, 3 do
        if string.upper(v[p + 1] or "") == e.f then s = (p + 2) / 3 break end
    end
    if not s then
        message("未读取到该种族的数据（可玩种族列表里没有它）："..e.f)
        return
    end
    if CharacterCreate_RegisterSafeRaceId then CharacterCreate_RegisterSafeRaceId(s, false) end
    local scene = ((sex == 3 or sex == 1) and e.scF) or e.sc or (e.horde and 12 or 5)   -- borrowed creation scene: background + camera + close-up
    if CharacterCreate and CharacterCreate.backgroundRaceByListId then CharacterCreate.backgroundRaceByListId[s] = scene end
    A, B = e, s
    SetSelectedRace(s) SetSelectedSex(sex or 0) SetCharacterRace(s) SetCharacterCreateFacing(-15)
    -- RACEUI1C: this custom button bypasses CharacterRace_OnClick; refresh the real class UI here.
    if type(CharacterCreate_RefreshRaceClassState) == "function" then
        CharacterCreate_RefreshRaceClassState(s)
    end

    if CharacterCreate_UpdateModel then CharacterCreate_UpdateModel(CharacterCreate) end
    if e.drac and CharacterCreate_SetDracthyrBackground then pcall(CharacterCreate_SetDracthyrBackground, 1) CharacterCreate.r27WheelZoomLevel = 1 end
    -- experimental per-race model offset (the preview camera cannot be set); other races go back to 0,0,0
    if CharacterCreate and CharacterCreate.SetPosition then
        local p = NudgeGet(e)
        local ok, err = pcall(CharacterCreate.SetPosition, CharacterCreate, p[1], p[2], p[3])
        if not ok and e.pos and not PreviewPosWarned then PreviewPosWarned = true message("SetPosition: "..tostring(err)) end
    end
    local n = _G["CharCreateRaceButton"..scene]
    if n then n:SetChecked(0) end
    for _, b in ipairs(bs) do b:SetChecked(b.e == e) end
end
local function Hook()
    if RebornPreviewGenderHooked or type(SetCharacterGender) ~= "function" then return end
    RebornPreviewGenderHooked = true
    local o = SetCharacterGender
    SetCharacterGender = function(sex, ...)
        local was = A and B and GetSelectedRace() == B
        local r1, r2 = o(sex, ...)
        if was then pcall(Open, A, sex) end
        return r1, r2
    end
end

-- mouse wheel on a preview race: move the model along the depth axis (camera dolly) instead of the scene's zoom swap
local function WheelHook()
    if PreviewWheelHooked or not CharacterCreate or not CharacterCreate.GetScript then return end
    PreviewWheelHooked = true
    local old = CharacterCreate:GetScript("OnMouseWheel")
    CharacterCreate:EnableMouseWheel(true)
    CharacterCreate:SetScript("OnMouseWheel", function(self, delta, ...)
        if A and B and GetSelectedRace() == B and CharacterCreate.SetPosition then
            local _, s = NudgeGet(A)
            s.mode = delta > 0 and "near" or "far"
            local c = s[s.mode]
            pcall(CharacterCreate.SetPosition, CharacterCreate, c[1], c[2], c[3])
            if nudge then
                nudge.cur = c nudge.mode = s.mode
                nudge.text:SetText(A.n .. (s.mode == "near" and " 近景" or " 远景") .. "  pos " .. c[1] .. ", " .. c[2] .. ", " .. c[3])
            end
        elseif old then
            return old(self, delta, ...)
        end
    end)
end

-- Drakkin borrows the Dracthyr creation background + its wheel-zoom models; some races cap the wheel at level `zmax`
-- (the last level drops tall or short models out of frame)
do
    local origBG, origZoom, origLevel = CharacterCreate_SetCurrentBackground, CharacterCreate_GetWheelZoomModel, CharacterCreate_SetWheelZoomLevel
    local function Active() return A and B and GetSelectedRace() == B and A end
    function CharacterCreate_SetCurrentBackground(zoom, ...)
        local a = Active()
        if a and a.drac and CharacterCreate_SetDracthyrBackground and CharacterCreate_SetDracthyrBackground(zoom) then
            CharacterCreate.r27WheelZoomLevel = (zoom == 1) and 1 or 4
            return
        end
        return origBG(zoom, ...)
    end
    function CharacterCreate_GetWheelZoomModel(level, ...)
        local a = Active()
        if a and a.drac and EXTRA_RACE_DRACTHYR_KEY and CHARACTER_CREATE_WHEEL_ZOOM_PREFIX_BY_BACKGROUND then
            local prefix = CHARACTER_CREATE_WHEEL_ZOOM_PREFIX_BY_BACKGROUND[EXTRA_RACE_DRACTHYR_KEY]
            if prefix then
                return prefix .. level .. (GetSelectedSex() == SEX_FEMALE and "f" or "m") .. ".m2", EXTRA_RACE_DRACTHYR_KEY
            end
        end
        return origZoom(level, ...)
    end
    function CharacterCreate_SetWheelZoomLevel(level, ...)
        local a = Active()
        if a and a.zmax and level and level > a.zmax then level = a.zmax end
        return origLevel(level, ...)
    end
end
local old = CharacterCreate_OnShow
function CharacterCreate_OnShow(...)
    if old then old(...) end
    Hook()
    local l, r = 0, 0
    for i, e in ipairs(E) do
        local b = _G["Reborn"..e.k.."PreviewButton"]
        if b then
            bs[i] = b
            b.e = e
            if CharCreateRaceButtonsFrame and b.SetParent then b:SetParent(CharCreateRaceButtonsFrame) end
            b:ClearAllPoints() b:SetSize(62, 62) b:SetScale(0.78)
            if e.horde then
                b:SetPoint("CENTER", CharCreateRaceButton25, "CENTER", 70 * (r % 5 + 1) - (r >= 5 and 55 or 0), -75 * math.floor(r / 5))
                r = r + 1
            else
                b:SetPoint("CENTER", CharCreateRaceButton23, "CENTER", -70 * (l % 5 + 1) + (l >= 5 and 55 or 0), -75 * math.floor(l / 5))
                l = l + 1
            end
            b:SetFrameStrata("HIGH")
            if CharCreateRaceButtonsFrame then b:SetFrameLevel(CharCreateRaceButtonsFrame:GetFrameLevel() + 20) end
            local kind, name = string.match(e.ic, "^(%a):(.+)$")
            local icon = kind == "R" and ("Reborn\\Preview\\UIR1B\\"..name.."\\icon-round.blp") or ("Interface\\Icons\\"..name)
            b:SetNormalTexture(icon) b:SetPushedTexture(icon)
            b.borderfaction:SetTexture("Interface\\Glues\\CharacterCreate\\"..(e.horde and "HordeRoundRaceOk" or "AlliRoundRaceOk"))
            b.borderfaction:SetAlpha(1) b.borderfaction:Show()
            b.nameFrame.text:SetText(e.n)
            b.tooltip = e.n
            b:SetScript("OnClick", function()
                local ok, err = pcall(Open, e)
                if not ok then b:SetChecked(false) message("预览失败："..tostring(err)) end
            end)
            if PAID_SERVICE_TYPE then b:Hide() else b:Show() end
        end
    end
end
