-- 17 preview buttons: 9 Alliance (left) and 8 Horde (right). Ours keep REBORN* file strings, the new ones use the CoA 1.9.2 rows.

-- live nudge panel for races with a pos={x,y,z} (the camera cannot be set; x = up/down, z = near/far as measured in tests)
local nudge
local posStore = {}
-- each race keeps a far view and a near (close-up) view; the mouse wheel switches between them, the panel edits the current one
function NudgeGet(e)
    local fem = type(GetSelectedSex) == "function" and SEX_FEMALE and GetSelectedSex() == SEX_FEMALE   -- RACE14A: separate camera for female
    local key = e.k .. (fem and "F" or "M")
    local s = posStore[key]
    if not s then
        local fp = (fem and e.posF) or e.pos
        local far = { fp and fp[1] or 0, fp and fp[2] or 0, fp and fp[3] or 0 }
        local fn = (fem and e.nearF) or e.near
        local near = fn and { fn[1], fn[2], fn[3] } or { far[1] + 24, far[2], far[3] }
        s = { far = far, near = near, mode = "far" }
        posStore[key] = s
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
    -- RACE14A: CoA 1.9.9 AllRaces v12, 7 Alliance + 7 Horde (preview only). Icons: Reborn\Preview\RACE14\<k>\icon-round.blp
    { k="Titan", zmax=3, f="TITANALLIANCE", ic="S:Titan", n="泰坦" },
    { k="Mogu", zmax=3, f="MOGUALLIANCE", ic="S:Mogu", n="魔古族" },
    { k="Sureki", zmax=3, f="SUREKIALLIANCE", ic="S:Sureki", n="苏雷基" },
    { k="Centaur", sc=20, zmax=1, f="CENTAURALLIANCE", ic="S:Centaur", n="半人马" },
    { k="Fungarian", sc=2, zmax=3, f="FUNGARIANALLIANCE", ic="S:Fungarian", n="蘑菇人" },
    { k="LostOne", f="LOSTONEALLIANCE", ic="S:LostOne", n="失落者", horde=true },
    { k="Stormforged", zmax=3, f="STORMFORGEDALLIANCE", ic="S:Stormforged", n="风暴铸造者" },
    { k="Qiraji", zmax=3, f="QIRAJIHORDE", ic="S:Qiraji", n="其拉人", horde=true },
    { k="Nerubian", sc=21, f="NERUBIANHORDE", ic="S:Nerubian", n="蛛魔", horde=true },
    { k="Dreadlord", sc=21, zmax=3, f="DREADLORDHORDE", ic="S:Dreadlord", n="恐惧魔王", horde=true },
    { k="Wretched", f="WRETCHEDHORDE", ic="S:Wretched", n="邪裔", horde=true },
    { k="Moarg", sc=15, zmax=3, zmaxF=2, f="MOARGHORDE", ic="S:Moarg", n="莫阿格", horde=true },
    { k="Sporeling", sc=4, f="SPORELINGALLIANCE", ic="S:Sporeling", n="孢子人" },
    { k="Lich", sc=25, zanda=true, f="LICHHORDE", ic="S:Lich", n="巫妖", horde=true },
    -- NEUTRAL1: single-gender CoA races (V16: Fel Orc and Taunka removed) in the neutral row (4 left, 4 right, symmetric); emblem + label sit above the row
    { k="Gnoll", sc=14, f="GNOLLHORDE", ic="N:Gnoll", n="豺狼人", neutral=true, side="R", slot=0, only=0 },
    { k="Twins", sc=1, f="THINHUMAN", ic="N:ThinHuman", n="瘦人双胞胎", neutral=true, side="L", slot=3, only=0 },
    { k="Saberon", sc=8, f="SABERONHORDE", ic="N:Saberon", n="沙伯龙", neutral=true, side="L", slot=4, only=0 },
    { k="Drakonid", drac=true, f="DRAKONIDHORDE", ic="N:Drakonid", n="龙人", neutral=true, side="L", slot=1, only=0 },
    { k="Grummle", sc=4, f="GRUMMLE", ic="N:Grummle", n="格鲁姆", neutral=true, side="L", slot=2, only=0 },
    { k="Mantid", sc=15, f="MANTIDHORDE", ic="N:Mantid", n="螳螂人", neutral=true, side="R", slot=2, only=0 },
    { k="Ethereal", f="ETHEREALALLIANCE", ic="N:Ethereal", n="虚灵", neutral=true, side="L", slot=0, only=0 },
    { k="Hozen", sc=16, f="HOZENALLIANCE", ic="N:Hozen", n="赫猿", neutral=true, side="R", slot=3, only=0 },
    { k="Banshee", sc=24, night=true, f="BANSHEEHORDE", ic="N:Banshee", n="女妖", neutral=true, side="R", slot=4, only=1 },   -- V29: back, female-only with the correct sex value
    -- V30: new ids 114/115/116 (the old 69/70/66 were taken over by the runtime's Earthen/Haranir/Highmountain logic)
    { k="NeuSkeleton", sc=13, f="SKELETONNEUTRAL", ic="N:Skeleton", n="骷髅", neutral=true, side="R", slot=1, only=0 },
    { k="NeuTaunka", sc=3, f="TAUNKANEUTRAL", ic="N:Taunka", n="牦牛人", neutral=true, side="L", slot=5, only=0 },
    { k="NeuFelOrc", sc=12, f="FELORCNEUTRAL", ic="N:FelOrc", n="邪兽人", neutral=true, side="R", slot=5, only=0 },
    { k="SlimeGiant", sc=5, f="TUSKARRNEUTRAL", ic="N:Tuskarr", n="海象人", neutral=true, side="L", slot=6, only=0 },   -- V40: re-uses the idle XML button
    { k="Harpy", sc=25, zanda=true, f="HARPY", ic="N:Harpy", n="鹰人", neutral=true, side="R", slot=6, only=1 },
}
-- NEUTRAL1: single-gender races grey out the other gender button (and re-enable it for every other race)
local function SetGenderLock(only)
    for _, q in ipairs({ { "CharCreateMaleButton", 0 }, { "CharCreateFemaleButton", 1 } }) do
        local b = _G[q[1]]
        if b then
            pcall(function()
                local lock = (only ~= nil and q[2] ~= only)
                if lock then b:Disable() b:SetAlpha(0.35) else b:Enable() b:SetAlpha(1) end
                if only ~= nil then b:SetChecked(q[2] == only and 1 or 0) end   -- V28: the highlight follows the real gender
                local t = b.GetNormalTexture and b:GetNormalTexture()
                if t and t.SetDesaturated then t:SetDesaturated(lock and 1 or nil) end
            end)
        end
    end
end
local bs, A, B = {}, nil, nil
-- V27b: the creation page sets the background in CharacterCreate_SetCurrentBackground and only knows the real Zandalari race;
-- every other Horde race falls back to the Orgrimmar scene. Route the Lich preview (zanda=true) to the Zandalari background.
if CharacterCreate_SetCurrentBackground and not RebornSCBWrapped then
    RebornSCBWrapped = true
    local origSCB = CharacterCreate_SetCurrentBackground
    function CharacterCreate_SetCurrentBackground(zoom)
        if A and B and GetSelectedRace() == B then
            local fn = (A.zanda and CharacterCreate_SetStageIZandalariBackground) or (A.night and CharacterCreate_SetStageHNightborneBackground)
            if fn then
                local ok, r = pcall(fn)
                if ok and r then CharacterCreate.r27WheelZoomLevel = 1 return end
            end
            -- V36: SetBackgroundModel only knows scenes 1-11 under "HUMAN" and 12-21 under "ORC"; a mismatch falls back to the default scene.
            -- The stock code picks by the race's DBC faction, so choose by the scene number for preview races instead.
            local sc = CharacterCreate_GetBackgroundRaceId and CharacterCreate_GetBackgroundRaceId(B)
            if not A.drac and type(sc) == "number" and sc >= 1 and sc <= 21 and sc ~= 20 and SetBackgroundModel then   -- 20 (Centaur): its opening and wheel scenes differ anyway; left as it was
                SetBackgroundModel(CharacterCreate, (sc >= 12) and "ORC" or "HUMAN", sc, zoom)
                CharacterCreate.r27WheelZoomLevel = (zoom == 1) and 1 or 4
                return
            end
        end
        return origSCB(zoom)
    end
end
local function Open(e, sex)
    if PAID_SERVICE_TYPE then return end
    -- V28: the engine only accepts 2 (male) / 3 (female) / 1 (none); 0 was silently ignored, 1 meant "no gender"
    if e.only ~= nil then sex = (e.only == 1) and (SEX_FEMALE or 3) or (SEX_MALE or 2) end   -- NEUTRAL1: single-gender race
    pcall(SetGenderLock, e.only)
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
    SetSelectedRace(s) if sex then SetSelectedSex(sex) end SetCharacterRace(s) SetCharacterCreateFacing(-15)
    -- RACEUI1C: this custom button bypasses CharacterRace_OnClick; refresh the real class UI here.
    if type(CharacterCreate_RefreshRaceClassState) == "function" then
        CharacterCreate_RefreshRaceClassState(s)
    end

    if CharacterCreate_UpdateModel then CharacterCreate_UpdateModel(CharacterCreate) end
    -- V27: Lich borrows the Zandalari background from the first frame (not only after the wheel zoom)
    if e.zanda and CharacterCreate_SetStageIZandalariBackground then pcall(CharacterCreate_SetStageIZandalariBackground) end
    if e.night and CharacterCreate_SetStageHNightborneBackground then pcall(CharacterCreate_SetStageHNightborneBackground) end
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
    if type(CharacterRace_OnClick) == "function" and not RebornGenderLockHooked then
        RebornGenderLockHooked = true
        local oc = CharacterRace_OnClick
        CharacterRace_OnClick = function(...)
            pcall(SetGenderLock, nil)
            local r1, r2, r3 = oc(...)
            -- V56: a stock race button was clicked; the preview-race icons must not stay lit unless that click did not change the race
            pcall(function()
                if not (A and B and GetSelectedRace() == B) then
                    for _, pb in ipairs(bs) do pb:SetChecked(false) end
                end
            end)
            return r1, r2, r3
        end
    end
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
        local zm = a and ((type(GetSelectedSex) == "function" and SEX_FEMALE and GetSelectedSex() == SEX_FEMALE and a.zmaxF) or a.zmax); if zm and level and level > zm then level = zm end   -- RACE14A zmaxF
        return origLevel(level, ...)
    end
end
local old = CharacterCreate_OnShow
function CharacterCreate_OnShow(...)
    if old then old(...) end
    Hook()
    pcall(SetGenderLock, nil)
    local l, r = 0, 0
    local neutralIdx = 0
    for i, e in ipairs(E) do
        local b = _G["Reborn"..e.k.."PreviewButton"]
        if b then
            bs[i] = b
            b.e = e
            if CharCreateRaceButtonsFrame and b.SetParent then b:SetParent(CharCreateRaceButtonsFrame) end
            b:ClearAllPoints() b:SetSize(62, 62) b:SetScale(0.78)
            if e.neutral then
                local nx = (e.side == "L") and (-80 - 70 * (e.slot or 0)) or (80 + 70 * (e.slot or 0))   -- V17: fixed side/slot, removing a race never moves the others
                b:SetPoint("CENTER", CharacterCreate, "CENTER", nx, -165)
                neutralIdx = neutralIdx + 1
            elseif e.horde then
                b:SetPoint("CENTER", CharCreateRaceButton25, "CENTER", 70 * (r % 5 + 1) - (r >= 5 and 55 or 0), -75 * math.floor(r / 5))
                r = r + 1
            else
                b:SetPoint("CENTER", CharCreateRaceButton23, "CENTER", -70 * (l % 5 + 1) + (l >= 5 and 55 or 0), -75 * math.floor(l / 5))
                l = l + 1
            end
            b:SetFrameStrata("HIGH")
            if CharCreateRaceButtonsFrame then b:SetFrameLevel(CharCreateRaceButtonsFrame:GetFrameLevel() + 20) end
            local kind, name = string.match(e.ic, "^(%a):(.+)$")
            local icon = kind == "R" and ("Reborn\\Preview\\UIR1B\\"..name.."\\icon-round.blp") or kind == "S" and ("Reborn\\Preview\\RACE14\\"..name.."\\icon-round.blp") or kind == "N" and ("Reborn\\Preview\\NEUTRAL\\"..name.."\\icon-round.blp") or ("Interface\\Icons\\"..name)
            b:SetNormalTexture(icon) b:SetPushedTexture(icon)
            b.borderfaction:SetTexture("Interface\\Glues\\CharacterCreate\\"..((e.horde or (e.neutral and e.side == "R")) and "HordeRoundRaceOk" or "AlliRoundRaceOk"))
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
    -- NEUTRAL1: emblem + label between the two groups
    pcall(function()
        if not RebornNeutralBadge then
            local f = CreateFrame("Frame", "RebornNeutralBadge", CharacterCreate)
            f:SetSize(64, 64) f:SetFrameStrata("HIGH")
            f:SetScript("OnUpdate", function(self) local st = CharacterCreateFrame and CharacterCreateFrame.state; self:SetAlpha(st == "CUSTOMIZATION" and 0 or 1) end)   -- hidden on the detailed customization page
            f.tex = f:CreateTexture(nil, "ARTWORK") f.tex:SetAllPoints()
            f.tex:SetTexture("Reborn\\Preview\\NEUTRAL1\\emblem.blp")
            f.text = f:CreateFontString(nil, "OVERLAY", "GlueFontNormal")
            f.text:SetPoint("TOP", f, "BOTTOM", 0, -2) f.text:SetText("中立")
        end
        RebornNeutralBadge:ClearAllPoints()
        RebornNeutralBadge:SetPoint("CENTER", CharacterCreate, "CENTER", 0, -95)   -- above the neutral row, clear of the gender buttons
        if PAID_SERVICE_TYPE then RebornNeutralBadge:Hide() else RebornNeutralBadge:Show() end
    end)
end
