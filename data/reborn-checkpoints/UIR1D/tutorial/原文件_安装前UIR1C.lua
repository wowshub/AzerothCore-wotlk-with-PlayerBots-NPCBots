-- UIR1A: preview only. No race/class selection, DBC mutation or creation eligibility.
local preview, launcher, active
local entries = {
    { key="Sethrak", title="联盟 · 蛇人", detail="Sethrak / 蛇人\n固定男性外观 · 预览 / 开发中\n本项目指定联盟归属，尚未开放创建。", scale=0.65, z=-0.75 },
    { key="Ogre", title="部落 · 双头食人魔", detail="Ogre / 双头食人魔\n仅双头外观 · 预览 / 开发中\n源文件在 Female 目录，不代表已提供女性款。", scale=0.75, z=-0.65 },
}
-- UIR1C: localized racial descriptions supplied by the user; display text only.
local racialDescriptions = {
    Sethrak = table.concat({
        "静电盘绕：对8码内的敌人造成自然伤害，并使其移动速度降低40%，持续6秒。冷却：2分钟。",
        "鳞甲：装备提供的护甲提高2%。",
        "蛇形反射：躲闪几率提高1%。",
        "风暴之血：自然伤害和治疗效果提高1%。",
        "抗毒体质：中毒效果持续时间缩短15%。",
    }, "\n\n"),
    Ogre = table.concat({
        "头槌：使附近一名敌人昏迷2秒。冷却：2分钟。",
        "蛮力：力量提高2%。",
        "厚皮：装备提供的护甲提高2%。",
        "重手：使用锤类和拳套武器时，精准提高3点。",
        "食人魔烹饪：烹饪技能提高5点。",
    }, "\n\n"),
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
    if RebornSethrakPreviewButton then RebornSethrakPreviewButton:SetChecked(false) end
    if RebornOgrePreviewButton then RebornOgrePreviewButton:SetChecked(false) end
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
    Label(preview, "新种族预览 · UIR1B · 暂不开放创建", 570, 0, -18)
    preview.tabs = {}
    for i,e in ipairs(entries) do
        local b = CreateFrame("CheckButton", nil, preview)
        b:SetSize(38, 38)
        b:SetPoint("TOP", preview, "TOP", i == 1 and -160 or 160, -64)
        b:SetNormalTexture("Reborn\\Preview\\UIR1B\\"..e.key.."\\icon-round.blp")
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
    -- UIR1B: XML-owned buttons reuse the exact native circular race template.
    local buttons = { RebornSethrakPreviewButton, RebornOgrePreviewButton }
    local neighbours = { CharCreateRaceButton23, CharCreateRaceButton25 }
    for i,b in ipairs(buttons) do
        local e=entries[i]
        local anchor=neighbours[i]
        local index=i
        b:ClearAllPoints()
        b:SetSize(62,62)
        b:SetScale(0.78)
        -- Existing top-row centers are +/-185, separated by 70 units.
        -- A relative center step follows the current anchor even after resizing.
        b:SetPoint("CENTER", anchor, "CENTER", i==1 and -70 or 70, 0)
        b:SetFrameStrata("HIGH")
        if CharCreateRaceButtonsFrame then b:SetFrameLevel(CharCreateRaceButtonsFrame:GetFrameLevel()+20) end
        b:SetNormalTexture("Reborn\\Preview\\UIR1B\\"..e.key.."\\icon-round.blp")
        b:SetPushedTexture("Reborn\\Preview\\UIR1B\\"..e.key.."\\icon-round.blp")
        b.borderfaction:SetTexture("Interface\\Glues\\CharacterCreate\\"..(i==1 and "AlliRoundRaceOk" or "HordeRoundRaceOk"))
        b.borderfaction:SetAlpha(1)
        b.borderfaction:Show()
        b.nameFrame.text:SetText(i==1 and "蛇人" or "双头食人魔")
        b.tooltip=e.title.."\n\n"..racialDescriptions[e.key]
        b:SetScript("OnClick", function()
            Open(index)
            for j,other in ipairs(buttons) do other:SetChecked(j==index) end
        end)
        if PAID_SERVICE_TYPE then b:Hide() else b:Show() end
    end
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
