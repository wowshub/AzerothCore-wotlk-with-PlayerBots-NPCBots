-- UIR1A: preview only. No race/class selection, DBC mutation or creation eligibility.
local preview, launcher, active
local entries = {
    { key="Sethrak", title="联盟 · 蛇人", detail="Sethrak / 蛇人\n固定男性外观 · 预览 / 开发中\n本项目指定联盟归属，尚未开放创建。", scale=0.65, z=-0.75 },
    { key="Ogre", title="部落 · 双头食人魔", detail="Ogre / 双头食人魔\n仅双头外观 · 预览 / 开发中\n源文件在 Female 目录，不代表已提供女性款。", scale=0.75, z=-0.65 },
}
local prefix = "Reborn\\Preview\\UIR1A\\"
local function Call(model, method, ...)
    if model and type(model[method]) == "function" then
        return pcall(model[method], model, ...)
    end
    return false
end
local function Label(parent, text, size, x, y)
    local f = parent:CreateFontString(nil, "OVERLAY", "GlueFontNormal")
    f:SetPoint("TOP", parent, "TOP", x or 0, y or 0)
    f:SetWidth(size)
    f:SetText(text)
    return f
end
local function Button(parent, text, width, x, y, callback)
    local b = CreateFrame("Button", nil, parent, "GlueButtonSmallTemplate")
    b:SetSize(width, 25)
    b:SetPoint("TOP", parent, "TOP", x, y)
    b:SetText(text)
    b:SetScript("OnClick", callback)
    return b
end
local function ResetCamera()
    if not preview or not preview.entry then return end
    preview.facing = 0
    preview.zoom = preview.entry.scale
    Call(preview.model, "SetFacing", preview.facing)
    Call(preview.model, "SetModelScale", preview.zoom)
    Call(preview.model, "SetPosition", 0, 0, preview.entry.z)
end
local function Select(index)
    local e = entries[index]
    preview.entry = e
    preview.description:SetText(e.detail)
    for i,b in ipairs(preview.tabs) do b:SetChecked(i == index) end
    if preview.model then
        preview.model:Hide()
        Call(preview.model, "ClearModel")
    end
    -- Model is present in the current Glue XML. Runtime method checks remain mandatory.
    local ok = Call(preview.model, "SetModel", prefix..e.key.."\\"..e.key..".m2")
    if ok then
        Call(preview.model, "SetCamera", 0)
        Call(preview.model, "SetSequence", 0)
        ResetCamera()
        preview.model:Show()
        preview.status:SetText("拖动旋转 · 滚轮缩放 · 待实机核验纹理和待机")
    else
        preview.status:SetText("UIR1A：当前 Glue 模型接口不可用，请记录此提示。")
    end
end
local function Close()
    active = false
    if preview then preview:Hide() end
end
local function Build()
    if preview then return end
    preview = CreateFrame("Frame", "RebornRacePreviewUIR1A", CharacterCreate)
    preview:Hide()
    preview:SetSize(660, 570)
    preview:SetPoint("CENTER", CharacterCreate, "CENTER", 0, 0)
    preview:SetFrameStrata("DIALOG")
    preview:EnableMouse(true)
    preview:SetMovable(true)
    preview:SetClampedToScreen(true)
    preview:SetBackdrop({ bgFile="Interface\\Tooltips\\UI-Tooltip-Background", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=true, tileSize=16, edgeSize=16, insets={left=4,right=4,top=4,bottom=4} })
    preview:SetBackdropColor(0.025, 0.035, 0.055, 1)
    preview:RegisterForDrag("LeftButton")
    preview:SetScript("OnDragStart", function(self) self:StartMoving() end)
    preview:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    preview:SetScript("OnHide", function(self)
        active = false
        if self.model then self.model:Hide(); Call(self.model, "ClearModel") end
    end)
    Label(preview, "新种族预览 · UIR1A · 暂不开放创建", 570, 0, -18)
    preview.tabs = {}
    for i,e in ipairs(entries) do
        local b = CreateFrame("CheckButton", nil, preview)
        b:SetSize(38, 38)
        b:SetPoint("TOP", preview, "TOP", i == 1 and -160 or 160, -64)
        b:SetNormalTexture(prefix..e.key.."\\icon.blp")
        b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        b:SetCheckedTexture("Interface\\Buttons\\CheckButtonHilight", "ADD")
        local idx = i
        b:SetScript("OnClick", function() Select(idx) end)
        Label(b, e.title, 220, 0, 20)
        preview.tabs[i] = b
    end
    preview.description = Label(preview, "", 610, 0, -110)
    local ok, model = pcall(CreateFrame, "Model", "RebornRacePreviewModelUIR1A", preview)
    if ok and model then
        preview.model = model
        model:SetSize(580, 300)
        model:SetPoint("TOP", preview, "TOP", 0, -170)
        model:EnableMouse(true)
        model:EnableMouseWheel(true)
        model:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then self.dragX = GetCursorPosition() end
        end)
        model:SetScript("OnMouseUp", function(self) self.dragX = nil end)
        model:SetScript("OnHide", function(self) self.dragX = nil end)
        model:SetScript("OnUpdate", function(self)
            if self.dragX then
                local x = GetCursorPosition()
                preview.facing = (preview.facing or 0) + (x-self.dragX)*0.012
                self.dragX = x
                Call(self, "SetFacing", preview.facing)
            end
        end)
        model:SetScript("OnMouseWheel", function(self, delta)
            preview.zoom = math.max(0.2, math.min(1.8, (preview.zoom or 0.7)+delta*0.05))
            Call(self, "SetModelScale", preview.zoom)
        end)
    end
    preview.status = Label(preview, "", 620, 0, -480)
    Button(preview, "重置镜头", 100, -220, -520, ResetCamera)
    Button(preview, "缩小面板", 100, -110, -520, function() preview:SetScale(math.max(0.65, preview:GetScale()-0.05)) end)
    Button(preview, "放大面板", 100, 0, -520, function() preview:SetScale(math.min(1.1, preview:GetScale()+0.05)) end)
    Button(preview, "重置布局", 100, 110, -520, function()
        preview:SetScale(1); preview:ClearAllPoints(); preview:SetPoint("CENTER", CharacterCreate, "CENTER", 0, 0)
    end)
    Button(preview, "返回创建页", 110, 225, -520, Close)
end
local function Open(index)
    Build()
    active = true
    preview:Show()
    Select(index)
end
local originalOnShow = CharacterCreate_OnShow
function CharacterCreate_OnShow(...)
    if originalOnShow then originalOnShow(...) end
    if not launcher then
        launcher = CreateFrame("Frame", "RebornRacePreviewEntryUIR1A", CharacterCreate)
        launcher:SetSize(300, 65)
        launcher:SetPoint("TOP", CharacterCreate, "TOP", 0, -35)
        launcher:SetFrameStrata("HIGH")
        for i,e in ipairs(entries) do
            local b=CreateFrame("Button", nil, launcher)
            b:SetSize(38,38)
            b:SetPoint("TOP", launcher, "TOP", i==1 and -90 or 90, -22)
            b:SetNormalTexture(prefix..e.key.."\\icon.blp")
            b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
            local idx=i
            b:SetScript("OnClick", function() Open(idx) end)
            Label(b, e.title.." · 预览", 180, 0, 18)
        end
    end
    launcher:Show()
end
local originalOnHide = CharacterCreate_OnHide
function CharacterCreate_OnHide(...)
    Close()
    if originalOnHide then return originalOnHide(...) end
end
-- Catch native-button, Enter and deferred quote-confirmation calls while preview is open.
local originalCreate = CreateCharacter
function CreateCharacter(...)
    if active then
        if preview then preview.status:SetText("预览尚未开放创建。请返回创建页选择已开放种族。") end
        return
    end
    return originalCreate(...)
end
