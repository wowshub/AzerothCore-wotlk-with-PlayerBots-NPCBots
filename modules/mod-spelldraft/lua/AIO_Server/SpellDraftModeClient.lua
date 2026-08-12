local AIO = AIO or require("AIO")
if AIO.AddAddon() then return end

-- Use the same saved language selection as the visible SpellDraft language
-- button. Fall back to the client locale if the regular addon is unavailable.
local function ResolvePickerLanguage()
    if _G.SpellDraft and type(_G.SpellDraft.GetLanguage) == "function" then
        local ok, value = pcall(_G.SpellDraft.GetLanguage)
        if ok and (value == "zhCN" or value == "enUS") then return value end
    end
    local clientLocale = GetLocale and GetLocale() or "enUS"
    return (clientLocale == "zhCN" or clientLocale == "zhTW") and "zhCN" or "enUS"
end

local pickerLanguage = ResolvePickerLanguage()
local function BuildStrings()
    local zh = pickerLanguage == "zhCN"
    return zh and {
    title = "选择角色成长模式",
    subtitle = "此选择按角色永久保存。确认前请仔细阅读。",
    closeHint = "必须先选择成长模式，才能开始游戏。",
    classic = "经典职业模式",
    classicDesc = "保留原职业技能、训练师和原版天赋树。\n不会进入随机抽卡系统。",
    draft = "随机抽卡模式",
    draftDesc = "每次升级随机出现技能卡片。\n使用现有 SpellDraft 抽卡与天赋系统。",
    free = "自由选择模式",
    freeDesc = "升级获得点数，在整合面板自由学习技能与天赋。\n服务器权威点数系统正在下一阶段制作。",
    locked = "下一阶段开放",
    choose = "请先选择一种模式",
    confirm = "确认并永久锁定",
    selected = "已选择：",
    saving = "正在保存角色模式……",
    success = "保存成功，即将重新进入角色选择画面。",
    error = "保存失败：",
    draftFreshError = "该角色已经升级，不能再转为随机抽卡模式；请选择经典模式，或新建角色选择随机抽卡。",
    dkClassic = "经典英雄死亡骑士",
    dkClassicDesc = "保留55级、阿彻鲁斯任务线和原版死亡骑士成长。\n不会执行1级转换。",
    dkDraft = "1级随机抽卡死亡骑士",
    dkDraftDesc = "使用随机抽卡成长，并自动前往该种族的默认新手村。\n以后仍可使用750002自行更换练级地区；A.22.8开放转换。",
    dkDraftLocked = "A.22.8 开放",
    dkLegacyLocked = "旧死亡骑士受保护",
    dkRouteMissing = "本阵营没有可用出生地",
    dkConversionError = "1级死亡骑士转换尚未开放；请选择经典英雄死亡骑士模式。",
        language = "EN",
        languageTip = "切换为英文",
    } or {
    title = "Choose Character Progression",
    subtitle = "This choice is permanently saved per character. Read carefully before confirming.",
    closeHint = "You must choose a progression mode before playing.",
    classic = "Classic Class Mode",
    classicDesc = "Keep your original class, trainers, and native talent trees.\nThe random draft system is disabled.",
    draft = "Random Draft Mode",
    draftDesc = "Level up and choose from random spell cards.\nUses the existing SpellDraft spell and talent systems.",
    free = "Free Pick Mode",
    freeDesc = "Earn points and freely choose spells and talents.\nThe authoritative point system arrives in the next phase.",
    locked = "Available next phase",
    choose = "Choose one mode first",
    confirm = "Confirm and permanently lock",
    selected = "Selected: ",
    saving = "Saving character mode...",
    success = "Saved. Returning to character selection.",
    error = "Could not save: ",
        draftFreshError = "This character has already progressed. Choose Classic, or create a new character for Random Draft.",
        dkClassic = "Classic Hero Death Knight",
        dkClassicDesc = "Keep level 55, the Acherus quest line, and native Death Knight progression.\nNo level-one conversion is performed.",
        dkDraft = "Level-One Draft Death Knight",
        dkDraftDesc = "Use Random Draft progression and automatically enter this race's default starting zone.\nNPC 750002 remains optional; conversion arrives in A.22.8.",
        dkDraftLocked = "Available in A.22.8",
        dkLegacyLocked = "Legacy Death Knight protected",
        dkRouteMissing = "No faction starting route available",
        dkConversionError = "Level-one Death Knight conversion is not available yet. Choose Classic Hero Death Knight.",
        language = "中文",
        languageTip = "Switch to Chinese",
    }
end

local L = BuildStrings()

local frame
local selectedMode
local cards = {}
local choiceCompleted = false
local pickerContext = {}

local MODE_INFO = {
    { key = "classic", icon = "Interface\\Icons\\INV_Misc_Book_09" },
    { key = "draft", icon = "Interface\\Icons\\INV_Misc_Dice_02" },
    { key = "free", icon = "Interface\\Icons\\Spell_Holy_MindVision" },
}

local function GetModeText(key)
    if pickerContext.isDeathKnight then
        if key == "classic" then return L.dkClassic, L.dkClassicDesc end
        if key == "draft" then return L.dkDraft, L.dkDraftDesc end
    end
    return L[key], L[key .. "Desc"]
end

local function GetCardBadge(card)
    if card.modeEnabled then return "" end
    if pickerContext.isDeathKnight and card.modeKey == "draft" then
        if pickerContext.dkStatus == "legacy_character" then return L.dkLegacyLocked end
        if pickerContext.dkStatus == "start_route_unavailable" then return L.dkRouteMissing end
        return L.dkDraftLocked
    end
    return L.locked
end

local function SetCardSelected(card, selected)
    if selected then
        card:SetBackdropBorderColor(1, 0.84, 0.18, 1)
        card:SetBackdropColor(0.30, 0.19, 0.055, 0.98)
    else
        card:SetBackdropBorderColor(0.76, 0.60, 0.28, 1)
        card:SetBackdropColor(0.13, 0.085, 0.045, 0.97)
    end
end

local function SelectCard(card)
    if not card.modeEnabled then return end
    selectedMode = card.modeKey
    for _, other in ipairs(cards) do SetCardSelected(other, other == card) end
    frame.status:SetTextColor(1, 0.82, 0.12)
    frame.status:SetText(L.selected .. card.modeTitle)
    frame.confirm:Enable()
    if frame.confirmHit then frame.confirmHit:Enable() end
end

local function SendLanguageToServer()
    AIO.Handle("SpellDraftModeServer", "SetLanguage", pickerLanguage)
end

local function RefreshPickerLanguage()
    L = BuildStrings()
    if not frame then return end
    frame.title:SetText(L.title)
    frame.subtitle:SetText(L.subtitle)
    frame.closeHint:SetText(L.closeHint)
    frame.languageButton:SetText(L.language)
    frame.languageButton.tooltipText = L.languageTip
    frame.confirm:SetText(L.confirm)

    for _, card in ipairs(cards) do
        local title, desc = GetModeText(card.modeKey)
        card.modeTitle = title
        card.titleText:SetText(title)
        card.desc:SetText(desc)
        card.badge:SetText(GetCardBadge(card))
    end

    if selectedMode then
        for _, card in ipairs(cards) do
            if card.modeKey == selectedMode then
                frame.status:SetText(L.selected .. card.modeTitle)
                break
            end
        end
    else
        frame.status:SetText(L.choose)
    end
end

local function TogglePickerLanguage()
    pickerLanguage = pickerLanguage == "zhCN" and "enUS" or "zhCN"
    _G.SpellDraftDB = _G.SpellDraftDB or {}
    _G.SpellDraftDB.language = pickerLanguage
    RefreshPickerLanguage()
    SendLanguageToServer()
end

local function SubmitSelection()
    if not selectedMode or not frame or frame.submitting then return end
    frame.submitting = true
    frame.confirm:Disable()
    if frame.confirmHit then frame.confirmHit:Disable() end
    for _, card in ipairs(cards) do
        card:Disable()
        if card.hitButton then card.hitButton:Disable() end
    end
    frame.status:SetText(L.saving)
    AIO.Handle("SpellDraftModeServer", "SelectMode", selectedMode)
end

local function CursorIsInside(region, cursorX, cursorY)
    if not region or not region:IsShown() then return false end
    local left, right = region:GetLeft(), region:GetRight()
    local bottom, top = region:GetBottom(), region:GetTop()
    if not left or not right or not bottom or not top then return false end
    return cursorX >= left and cursorX <= right
        and cursorY >= bottom and cursorY <= top
end

local function CreatePicker()
    frame = CreateFrame("Frame", "SpellDraftModePickerFrame", UIParent)
    frame:SetAllPoints(UIParent)
    frame:SetFrameStrata("TOOLTIP")
    -- Keep every interactive part above collection/preload overlays used by
    -- this client. The mini card was clickable at level 1000 while the old
    -- 930/950 card and close-button levels were visually present but blocked.
    frame:SetFrameLevel(1100)
    frame:EnableMouse(true)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    -- Only dim the world slightly. The old 0.88 opacity combined with dark
    -- panel/card backdrops and made the whole picker look almost black.
    frame:SetBackdropColor(0.015, 0.008, 0.003, 0.42)
    frame:Hide()
    frame:EnableKeyboard(true)

    local panel = CreateFrame("Frame", nil, frame)
    panel:SetSize(1040, 590)
    panel:SetPoint("CENTER")
    panel:SetFrameLevel(1110)
    panel:EnableMouse(true)
    panel:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 11, top = 11, bottom = 11 },
    })
    panel:SetBackdropColor(0.24, 0.14, 0.055, 1)

    local title = panel:CreateFontString(nil, "OVERLAY")
    title:SetPoint("TOP", 0, -38)
    title:SetFont("Fonts\\ARKai_T.ttf", 30, "OUTLINE")
    title:SetTextColor(1, 0.82, 0.12)
    title:SetText(L.title)
    frame.title = title

    local subtitle = panel:CreateFontString(nil, "OVERLAY")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -12)
    subtitle:SetFont("Fonts\\ARHei.ttf", 15)
    subtitle:SetTextColor(1, 0.94, 0.76)
    subtitle:SetText(L.subtitle)
    frame.subtitle = subtitle

    local closeHint = panel:CreateFontString(nil, "OVERLAY")
    closeHint:SetPoint("TOP", subtitle, "BOTTOM", 0, -10)
    closeHint:SetFont("Fonts\\ARHei.ttf", 13)
    closeHint:SetTextColor(0.76, 0.90, 1)
    closeHint:SetText(L.closeHint)
    frame.closeHint = closeHint

    local languageButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    languageButton:SetSize(72, 26)
    languageButton:SetPoint("TOPRIGHT", -34, -30)
    languageButton:SetFrameLevel(1140)
    languageButton:SetText(L.language)
    languageButton.tooltipText = L.languageTip
    languageButton:SetScript("OnClick", TogglePickerLanguage)
    languageButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.tooltipText)
        GameTooltip:Show()
    end)
    languageButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    frame.languageButton = languageButton

    for index, info in ipairs(MODE_INFO) do
        local card = CreateFrame("Button", nil, panel)
        card:SetSize(300, 345)
        card:SetPoint("TOPLEFT", 45 + (index - 1) * 325, -125)
        card:SetFrameLevel(1130)
        card:EnableMouse(true)
        card:RegisterForClicks("LeftButtonUp")
        card:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 18,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        card.modeKey = info.key
        local modeTitle, modeDesc = GetModeText(info.key)
        card.modeTitle = modeTitle
        card:SetScript("OnClick", SelectCard)
        -- Raw mouse-down fallback for customized 3.3.5 button handlers.
        card:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then SelectCard(self) end
        end)

        local iconBorder = CreateFrame("Frame", nil, card)
        iconBorder:SetSize(100, 100)
        iconBorder:SetPoint("TOP", 0, -28)
        iconBorder:SetFrameLevel(1135)
        iconBorder:SetBackdrop({ edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 18 })

        local icon = iconBorder:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", 7, -7)
        icon:SetPoint("BOTTOMRIGHT", -7, 7)
        icon:SetTexture(info.icon)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        local cardTitle = card:CreateFontString(nil, "OVERLAY")
        cardTitle:SetPoint("TOP", iconBorder, "BOTTOM", 0, -18)
        cardTitle:SetFont("Fonts\\ARKai_T.ttf", 21, "OUTLINE")
        cardTitle:SetTextColor(1, 0.82, 0.12)
        cardTitle:SetText(modeTitle)
        card.titleText = cardTitle

        local desc = card:CreateFontString(nil, "OVERLAY")
        desc:SetPoint("TOPLEFT", 18, -185)
        desc:SetPoint("TOPRIGHT", -18, -185)
        desc:SetJustifyH("CENTER")
        desc:SetFont("Fonts\\ARHei.ttf", 15)
        desc:SetTextColor(1, 0.93, 0.73)
        desc:SetText(modeDesc)
        card.desc = desc

        local badge = card:CreateFontString(nil, "OVERLAY")
        badge:SetPoint("BOTTOM", 0, 28)
        badge:SetFont("Fonts\\ARHei.ttf", 14, "OUTLINE")
        badge:SetTextColor(1, 0.25, 0.2)
        badge:SetText("")
        card.badge = badge

        cards[index] = card
        SetCardSelected(card, false)

        -- This client has a central transparent addon layer that consumes
        -- clicks aimed at children of the detailed panel. Put the actual hit
        -- target directly on UIParent, just like the previously working mini
        -- card, while keeping the visual card inside the panel.
        local hitButton = CreateFrame("Button", "SpellDraftModeCardHit" .. index, UIParent)
        hitButton:SetAllPoints(card)
        hitButton:SetFrameStrata("TOOLTIP")
        hitButton:SetFrameLevel(5100 + index)
        hitButton:EnableMouse(true)
        hitButton:RegisterForClicks("LeftButtonUp")
        hitButton:SetScript("OnClick", function() SelectCard(card) end)
        hitButton:SetScript("OnMouseDown", function(_, button)
            if button == "LeftButton" then SelectCard(card) end
        end)
        hitButton:Hide()
        card.hitButton = hitButton
    end

    local status = panel:CreateFontString(nil, "OVERLAY")
    status:SetPoint("BOTTOM", 0, 72)
    status:SetFont("Fonts\\ARHei.ttf", 15, "OUTLINE")
    status:SetTextColor(1, 0.82, 0.12)
    status:SetText(L.choose)
    frame.status = status

    local confirm = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    confirm:SetSize(280, 36)
    confirm:SetPoint("BOTTOM", 0, 25)
    confirm:SetText(L.confirm)
    confirm:SetFrameLevel(1140)
    confirm:EnableMouse(true)
    confirm:RegisterForClicks("LeftButtonUp")
    confirm:Disable()
    confirm:SetScript("OnClick", SubmitSelection)
    frame.confirm = confirm

    local confirmHit = CreateFrame("Button", "SpellDraftModeConfirmHit", UIParent)
    confirmHit:SetAllPoints(confirm)
    confirmHit:SetFrameStrata("TOOLTIP")
    confirmHit:SetFrameLevel(5200)
    confirmHit:EnableMouse(true)
    confirmHit:RegisterForClicks("LeftButtonUp")
    confirmHit:SetScript("OnClick", SubmitSelection)
    confirmHit:SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" then SubmitSelection() end
    end)
    confirmHit:Disable()
    confirmHit:Hide()
    frame.confirmHit = confirmHit

    local languageHit = CreateFrame("Button", "SpellDraftModeLanguageHit", UIParent)
    languageHit:SetAllPoints(languageButton)
    languageHit:SetFrameStrata("TOOLTIP")
    languageHit:SetFrameLevel(5300)
    languageHit:EnableMouse(true)
    languageHit:RegisterForClicks("LeftButtonUp")
    languageHit:SetScript("OnClick", TogglePickerLanguage)
    languageHit:Hide()
    frame.languageHit = languageHit

    -- Mandatory selection: the frame is intentionally not in UISpecialFrames,
    -- so ESC cannot dismiss it. If another addon tries to hide it, restore it.
    frame:SetScript("OnShow", function()
        for _, card in ipairs(cards) do card.hitButton:Show() end
        confirmHit:Show()
        languageHit:Show()
    end)
    frame:SetScript("OnHide", function()
        for _, card in ipairs(cards) do card.hitButton:Hide() end
        confirmHit:Hide()
        languageHit:Hide()
        if not choiceCompleted then frame:Show() end
    end)

    -- Last-resort input path for this customized client: its central overlay
    -- consumes normal frame OnClick/OnMouseDown dispatch even for UIParent
    -- children. Poll the hardware button transition and cursor coordinates,
    -- then hit-test the visible card rectangles ourselves.
    frame.leftMouseWasDown = false
    frame:SetScript("OnUpdate", function(self)
        local leftDown = IsMouseButtonDown("LeftButton") and true or false
        if leftDown and not self.leftMouseWasDown
            and not choiceCompleted and not self.submitting then
            local cursorX, cursorY = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            if scale and scale > 0 then
                cursorX = cursorX / scale
                cursorY = cursorY / scale
            end

            for _, card in ipairs(cards) do
                if card.modeEnabled and CursorIsInside(card, cursorX, cursorY) then
                    SelectCard(card)
                    self.leftMouseWasDown = leftDown
                    return
                end
            end

            if selectedMode and CursorIsInside(self.confirm, cursorX, cursorY) then
                SubmitSelection()
                self.leftMouseWasDown = leftDown
                return
            end

            if CursorIsInside(self.languageButton, cursorX, cursorY) then
                TogglePickerLanguage()
            end
        end
        self.leftMouseWasDown = leftDown
    end)
end

local handlers = AIO.AddHandlers("SpellDraftModeClient", {})

-- WoW's autoRangedCombat CVar automatically switches a right-click attack
-- between melee and the learned ranged auto-attacks. SpellDraft characters
-- know Auto Shot/Shoot/Throw even when no ranged weapon is equipped, so the
-- automatic switch can choose a ranged attack and raise
-- ERR_NEED_RANGED_WEAPON instead of starting melee combat.
--
-- Keep the ranged spells usable from the action bar. In a classless mode,
-- enable automatic ranged combat only while slot 18 contains a real ranged
-- weapon; relics, idols, librams, totems and sigils use INVTYPE_RELIC and do
-- not count. Restore the player's previous preference in classic mode.
local function HasUsableRangedWeaponEquipped()
    if type(GetInventoryItemLink) ~= "function" or type(GetItemInfo) ~= "function" then
        return false
    end

    local itemLink = GetInventoryItemLink("player", 18)
    if not itemLink then return false end

    local equipLoc = select(9, GetItemInfo(itemLink))
    return equipLoc == "INVTYPE_RANGED"
        or equipLoc == "INVTYPE_RANGEDRIGHT"
        or equipLoc == "INVTYPE_THROWN"
end

local function ApplyCombatModeCVar(modeName)
    if type(GetCVar) ~= "function" or type(SetCVar) ~= "function" then return end

    _G.SpellDraftDB = _G.SpellDraftDB or {}
    local db = _G.SpellDraftDB
    local classlessMode = modeName == "draft" or modeName == "free"

    if classlessMode then
        if db.autoRangedCombatBeforeDraft == nil then
            db.autoRangedCombatBeforeDraft = tostring(GetCVar("autoRangedCombat") or "0")
        end
        SetCVar("autoRangedCombat", HasUsableRangedWeaponEquipped() and "1" or "0")
    elseif modeName == "classic" and db.autoRangedCombatBeforeDraft ~= nil then
        SetCVar("autoRangedCombat", db.autoRangedCombatBeforeDraft)
        db.autoRangedCombatBeforeDraft = nil
    end
end

-- Re-evaluate immediately when the ranged slot changes. PLAYER_ENTERING_WORLD
-- is also useful after reload/login, when the item cache becomes available.
local combatModeCVarFrame = CreateFrame("Frame")
combatModeCVarFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
combatModeCVarFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
combatModeCVarFrame:SetScript("OnEvent", function(_, event, slot)
    if event == "PLAYER_EQUIPMENT_CHANGED" and tonumber(slot) ~= 18 then return end
    ApplyCombatModeCVar(tostring(_G.SpellDraftCharacterMode or "pending"))
end)

function handlers.ApplyMode(player, modeName)
    modeName = tostring(modeName or "pending")
    _G.SpellDraftCharacterMode = modeName
    ApplyCombatModeCVar(modeName)
    if type(_G.SpellDraft_ApplyModeButtons) == "function" then
        _G.SpellDraft_ApplyModeButtons()
    end
    pickerLanguage = ResolvePickerLanguage()
    L = BuildStrings()
    SendLanguageToServer()
end

function handlers.ApplyLanguage(player, language)
    if language ~= "zhCN" and language ~= "enUS" then return end
    pickerLanguage = language
    _G.SpellDraftDB = _G.SpellDraftDB or {}
    _G.SpellDraftDB.language = language
    RefreshPickerLanguage()
end

function handlers.ShowPicker(player, enabled)
    if not frame then CreatePicker() end
    enabled = enabled or {}
    pickerContext = {
        isDeathKnight = enabled.isDeathKnight == true,
        dkStatus = enabled.dkStatus,
        dkConversionReady = enabled.dkConversionReady == true,
    }
    RefreshPickerLanguage()
    choiceCompleted = false
    frame.submitting = false
    selectedMode = nil
    frame.status:SetTextColor(1, 0.82, 0.12)
    frame.status:SetText(L.choose)
    frame.confirm:Disable()
    frame.confirmHit:Disable()

    for _, card in ipairs(cards) do
        card.modeEnabled = enabled[card.modeKey] == true
        card:Enable()
        card.badge:SetText("")
        card.desc:SetTextColor(1, 0.93, 0.73)
        SetCardSelected(card, false)
        if not card.modeEnabled then
            card:Disable()
            card.hitButton:Disable()
            card.badge:SetText(GetCardBadge(card))
            card.desc:SetTextColor(0.68, 0.64, 0.56)
        else
            card.hitButton:Enable()
        end
    end
    frame:Show()
end

function handlers.SelectionResult(player, ok, result)
    if not frame then return end
    if ok then
        choiceCompleted = true
        frame.status:SetTextColor(0.2, 1, 0.2)
        frame.status:SetText(L.success)
        return
    end

    frame.status:SetTextColor(1, 0.25, 0.2)
    local errorText
    if result == "draft_requires_fresh_character" then
        errorText = L.draftFreshError
    elseif result == "dk_conversion_not_ready" then
        errorText = L.dkConversionError
    else
        errorText = tostring(result or "unknown")
    end
    frame.status:SetText(L.error .. errorText)
    frame.submitting = false
    for _, card in ipairs(cards) do
        if card.modeEnabled then
            card:Enable()
            card.hitButton:Enable()
        end
    end
    if selectedMode then
        frame.confirm:Enable()
        frame.confirmHit:Enable()
    end
end
