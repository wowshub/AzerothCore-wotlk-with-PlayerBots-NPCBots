-- =========================================================================
-- RebornTreasure (野外寻宝指南) 客户端插件
-- 阶段: TREAS1B (审核整合: 加 Esc 关闭、保存变量空值保护)
-- 责任成员: Gemini (包前缀 geminifix_)
-- 特性:
--   1. 提供稳定全局名称按钮 RebornTreasureToggleButton，天然兼容 RebornDock 收藏盒
--   2. 自动监听服务端系统下发的 [寻宝线索] 消息并记录到探索日志
--   3. 提供简明优雅的只读线索查询面板 (/treasure 或 /rt)
--   4. 严格遵守安全边界：客户端只做展示，不作弊、不发包、不改底层 AIO
-- =========================================================================

local AddonName = "RebornTreasure"
local Frame = CreateFrame("Frame", "RebornTreasureMainFrame", UIParent)
Frame:SetSize(360, 420)
Frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
Frame:SetMovable(true)
Frame:EnableMouse(true)
Frame:RegisterForDrag("LeftButton")
Frame:SetScript("OnDragStart", Frame.StartMoving)
Frame:SetScript("OnDragStop", Frame.StopMovingOrSizing)
Frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 24,
    insets = { left = 6, right = 6, top = 6, bottom = 6 }
})
Frame:Hide()
tinsert(UISpecialFrames, "RebornTreasureMainFrame") -- Esc closes the panel

-- 标题栏
local Title = Frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
Title:SetPoint("TOP", Frame, "TOP", 0, -16)
Title:SetText("|cffffd700野外寻宝指南|r")

-- 关闭按钮
local CloseBtn = CreateFrame("Button", nil, Frame, "UIPanelCloseButton")
CloseBtn:SetPoint("TOPRIGHT", Frame, "TOPRIGHT", -8, -8)

-- 说明副标题
local SubTitle = Frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
SubTitle:SetPoint("TOPLEFT", Frame, "TOPLEFT", 18, -45)
SubTitle:SetText("|cffaaaaaa最近探险发现的宝藏线索记录：|r")

-- 线索文本滚动区域
local ScrollFrame = CreateFrame("ScrollFrame", "RebornTreasureScrollFrame", Frame, "UIPanelScrollFrameTemplate")
ScrollFrame:SetPoint("TOPLEFT", Frame, "TOPLEFT", 16, -65)
ScrollFrame:SetPoint("BOTTOMRIGHT", Frame, "BOTTOMRIGHT", -36, 45)

local Content = CreateFrame("Frame", nil, ScrollFrame)
Content:SetSize(305, 500)
ScrollFrame:SetScrollChild(Content)

local LogText = Content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
LogText:SetPoint("TOPLEFT", Content, "TOPLEFT", 4, -4)
LogText:SetWidth(295)
LogText:SetJustifyH("LEFT")
LogText:SetText("|cff888888暂无新记录。当你走近野外隐藏宝箱时，线索将自动浮现于此处；开箱也会记在这里。|r")

-- 底部清空记录按钮
local ClearBtn = CreateFrame("Button", nil, Frame, "UIPanelButtonTemplate")
ClearBtn:SetSize(100, 24)
ClearBtn:SetPoint("BOTTOMLEFT", Frame, "BOTTOMLEFT", 18, 14)
ClearBtn:SetText("清空日志")
ClearBtn:SetScript("OnClick", function()
    if RebornTreasureDB then
        RebornTreasureDB.logs = {}
    end
    LogText:SetText("|cff888888日志已清空。|r")
end)

-- 底部探险提示
local TipText = Frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
TipText:SetPoint("BOTTOMRIGHT", Frame, "BOTTOMRIGHT", -18, 18)
TipText:SetText("指令: /treasure 或 /rt")

-- =========================================================================
-- TREAS1E: 屏幕中间的醒目提示 (线索 / 开箱), 几秒后淡出
-- =========================================================================
local Alert = CreateFrame("Frame", "RebornTreasureAlertFrame", UIParent)
Alert:SetSize(640, 90)
Alert:SetPoint("TOP", UIParent, "TOP", 0, -170)
Alert:SetFrameStrata("FULLSCREEN_DIALOG")
Alert:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border",
    tile = true, tileSize = 32, edgeSize = 24,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
})
Alert:Hide()
local AlertTitle = Alert:CreateFontString(nil, "OVERLAY")
AlertTitle:SetFont(STANDARD_TEXT_FONT, 22, "OUTLINE")
AlertTitle:SetPoint("TOP", Alert, "TOP", 0, -14)
local AlertBody = Alert:CreateFontString(nil, "OVERLAY")
AlertBody:SetFont(STANDARD_TEXT_FONT, 15, "OUTLINE")
AlertBody:SetPoint("TOP", AlertTitle, "BOTTOM", 0, -6)
AlertBody:SetWidth(590)
AlertBody:SetJustifyH("CENTER")
local ALERT_HOLD, ALERT_FADE = 6, 1.5
local alertAge = 0
Alert:SetScript("OnUpdate", function(self, elapsed)
    alertAge = alertAge + elapsed
    if alertAge >= ALERT_HOLD + ALERT_FADE then
        self:Hide()
    elseif alertAge > ALERT_HOLD then
        self:SetAlpha(1 - (alertAge - ALERT_HOLD) / ALERT_FADE)
    end
end)

local function ShowAlert(title, body)
    AlertTitle:SetText(title or "")
    AlertBody:SetText(body or "")
    Alert:SetHeight(AlertBody:GetStringHeight() + 62)
    alertAge = 0
    Alert:SetAlpha(1)
    Alert:Show()
    pcall(PlaySound, "RaidWarning")
end

-- 刷新日志显示
local function RefreshLogDisplay()
    if not RebornTreasureDB or not RebornTreasureDB.logs or #RebornTreasureDB.logs == 0 then
        LogText:SetText("|cff888888暂无新记录。当你走近野外隐藏宝箱时，线索将自动浮现于此处；开箱也会记在这里。|r")
        return
    end

    local text = ""
    for i = #RebornTreasureDB.logs, 1, -1 do
        local entry = RebornTreasureDB.logs[i]
        local tag = entry.kind == "open" and "|cff00ff00开箱|r " or "|cffffd700线索|r "
        text = text .. tag .. "|cffffd700[" .. (entry.time or "--:--") .. "] " .. (entry.zone or "野外") .. "|r\n"
        text = text .. "|cffffffff" .. (entry.clue or "") .. "|r\n\n"
    end
    LogText:SetText(text)
end

-- =========================================================================
-- 独立全局入口按钮 RebornTreasureToggleButton (供 RebornDock 收藏盒统一收纳)
-- =========================================================================
local ToggleButton = CreateFrame("Button", "RebornTreasureToggleButton", UIParent)
ToggleButton:SetSize(32, 32)
ToggleButton:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", -10, -10)
ToggleButton:SetMovable(true)
ToggleButton:EnableMouse(true)
ToggleButton:RegisterForDrag("LeftButton")
ToggleButton:SetScript("OnDragStart", ToggleButton.StartMoving)
ToggleButton:SetScript("OnDragStop", ToggleButton.StopMovingOrSizing)

-- 设置宝箱图标
local Icon = ToggleButton:CreateTexture(nil, "BACKGROUND")
Icon:SetAllPoints()
Icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_11")
ToggleButton.rebornDockIcon = "Interface\\Icons\\INV_Misc_Bag_11"

-- 高亮与按压效果
local Highlight = ToggleButton:CreateTexture(nil, "HIGHLIGHT")
Highlight:SetAllPoints()
Highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
Highlight:SetBlendMode("ADD")

ToggleButton:SetScript("OnClick", function()
    if Frame:IsShown() then
        Frame:Hide()
    else
        RefreshLogDisplay()
        Frame:Show()
    end
end)

ToggleButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("|cffffd700野外寻宝指南|r", 1, 1, 1)
    GameTooltip:AddLine("点击打开寻宝线索与探险日志面板", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("命令: /treasure 或 /rt", 0.6, 0.6, 0.6)
    GameTooltip:Show()
end)

ToggleButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- =========================================================================
-- 消息事件监听：捕获系统下发的寻宝线索
-- =========================================================================
local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("ADDON_LOADED")
EventFrame:RegisterEvent("CHAT_MSG_SYSTEM")

EventFrame:SetScript("OnEvent", function(self, event, arg1, ...)
    if event == "ADDON_LOADED" and arg1 == AddonName then
        RebornTreasureDB = RebornTreasureDB or {}
        RebornTreasureDB.logs = RebornTreasureDB.logs or {}
    elseif event == "CHAT_MSG_SYSTEM" and arg1 then
        RebornTreasureDB = RebornTreasureDB or {}
        RebornTreasureDB.logs = RebornTreasureDB.logs or {}
        -- 监听服务端发送的带有 [寻宝线索] 的文字
        -- TREAS1E: 线索和开箱两类消息都记日志, 并在屏幕中间提示
        local plain = arg1:gsub("|c%x%x%x%x%x%x%x%x", "")
        plain = plain:gsub("|r", "")
        local kind, title
        if string.find(plain, "[寻宝线索]", 1, true) then
            kind, title = "clue", "|cffffd700寻宝线索|r"
            plain = plain:gsub("^%s*%[寻宝线索%]%s*", "")
        elseif string.find(plain, "你成功开启了野外寻宝宝箱", 1, true)
            or string.find(plain, "你获得了寻宝金币奖励", 1, true)
            or string.find(plain, "[寻宝提示]", 1, true) then
            kind, title = "open", "|cff00ff00寻宝宝箱|r"
        end
        if kind then
            table.insert(RebornTreasureDB.logs, {
                time = date("%H:%M"),
                zone = GetZoneText() or "未知区域",
                clue = plain,
                kind = kind
            })
            -- 最多保留 30 条记录
            while #RebornTreasureDB.logs > 30 do
                table.remove(RebornTreasureDB.logs, 1)
            end
            if Frame:IsShown() then
                RefreshLogDisplay()
            end
            ShowAlert(title, plain)
        end
    end
end)

-- 斜杠命令支持
SLASH_REBORNTREASURE1 = "/treasure"
SLASH_REBORNTREASURE2 = "/rt"
SlashCmdList["REBORNTREASURE"] = function()
    if Frame:IsShown() then
        Frame:Hide()
    else
        RefreshLogDisplay()
        Frame:Show()
    end
end


-- /rttest: 预览屏幕提示
SLASH_REBORNTREASURETEST1 = "/rttest"
SlashCmdList["REBORNTREASURETEST"] = function()
    ShowAlert("|cffffd700寻宝线索|r", "你感到附近的空气中弥漫着微弱的宝物灵气，似乎有什么东西藏在附近...")
end
