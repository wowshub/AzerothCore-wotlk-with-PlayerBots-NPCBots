-- WD53A: project-authored DragonUI integration, MIT.
-- Explicit spell families from RebornWitchDoctorRanks.h; no native action slots.
local addon = select(2, ...)
local _, class, classID = UnitClass('player')
if class ~= 'WITCHDOCTOR' and class ~= 'WITCH_DOCTOR' and classID ~= 13 then return end

local groups = {
    {label = '守卫 / Ward', ids = {9003160, 9003170, 9003450, 9003400}},
    {label = '神像 / Idol', ids = {9003370, 9003440, 9003432, 9003382, 9003380, 9003390, 9003953}},
    {label = '雕像 / Effigy', ids = {9003410, 9003420, 9003422, 9003430}},
}
local bar, slots, allButtons = nil, {}, {}
local utility = {}
local dirty, elapsedSincePaint = true, 0
local function Config()
    return addon.db and addon.db.profile.additional and addon.db.profile.additional.totem
end
local function Store()
    if not addon.db or not addon.db.char then return end
    if type(addon.db.char.witchdoctorSummons) ~= 'table' then
        addon.db.char.witchdoctorSummons = {}
    end
    return addon.db.char.witchdoctorSummons
end
local function Enabled()
    local cfg = Config()
    return cfg and cfg.witchdoctor_enabled ~= false and addon:IsModuleEnabled('multicast')
end

-- Selection changes run in the secure click environment, including in combat.
-- Only frame references made out of combat are traversed; no server commands.
local TOGGLE = [[
    local flyout = self:GetFrameRef('flyout')
    local wasShown = flyout:IsShown()
    local owner = self:GetFrameRef('owner')
    for i = 1, 3 do owner:GetFrameRef('flyout' .. i):Hide() end
    if not wasShown then flyout:Show() end
]]
local SELECT = [[
    local main = self:GetFrameRef('main')
    main:SetAttribute('spell1', self:GetAttribute('choiceSpell'))
    main:SetAttribute('type1', 'spell')
    main:SetAttribute('selectedID', self:GetAttribute('choiceID'))
    self:GetFrameRef('flyout'):Hide()
]]
local MAIN = [[
    local owner = self:GetFrameRef('owner')
    local flyout = self:GetFrameRef('flyout')
    local wasShown = flyout:IsShown()
    for i = 1, 3 do owner:GetFrameRef('flyout' .. i):Hide() end
    if button == 'RightButton' and not wasShown and (self:GetAttribute('choiceCount') or 0) > 0 then flyout:Show() end
]]

-- Only transmit this character's selection to the server; a secure spell button casts.
local lastSelection
local function SendSelection(force)
    if not slots[3] then return end
    local message = 'S ' .. (slots[1]:GetAttribute('selectedID') or 0) .. ' ' ..
        (slots[2]:GetAttribute('selectedID') or 0) .. ' ' .. (slots[3]:GetAttribute('selectedID') or 0)
    if force or lastSelection ~= message then
        SendAddonMessage('RBWD53', message, 'WHISPER', UnitName('player'))
        lastSelection = message
    end
end
local function Tooltip(self)
    GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
    local id = self:GetAttribute('choiceID') or self:GetAttribute('selectedID')
    -- Empty slots describe their purpose, never preview an unlearned spell.
    if not id or not IsSpellKnown(id) then
        local labels = {
            [9003540] = '一键放置技能栏 / Ritual slot',
            [9003541] = '召唤物回收技能栏 / Recall slot',
            [9003673] = '独立守卫技能栏 / Independent Ward slot',
            [9003580] = '大巫毒技能栏 / Big Bad Voodoo slot',
            [9003800] = '魔像技能栏 / Golem slot',
        }
        local label = labels[self.utilityID] or self.category or '召唤技能栏 / Summon slot'
        GameTooltip:SetText(label, 1, .82, 0)
        GameTooltip:AddLine('此栏用于放置已学会的对应技能。', 1, 1, 1, true)
        GameTooltip:AddLine('This slot holds learned skills of this category.', .7, .75, .8, true)
        GameTooltip:Show()
        return
    end
    if id then GameTooltip:SetHyperlink('spell:' .. id)
    else GameTooltip:SetText(self.category or '巫医召唤栏', 1, .82, 0) end
    if self.dedicatedSummon then
        GameTooltip:AddLine(self.utilityID == 9003673 and '独立守卫 / Independent Ward' or (self.utilityID == 9003800 and '独立魔像 / Independent Golem' or '独立召唤 / Independent Summon'), .3, 1, .6)
        GameTooltip:AddLine('左键单独施放；不占守卫、神像或雕像槽，不包含在三类一键放置或回收中。', 1, 1, 1, true)
        GameTooltip:AddLine('Left-click to cast separately. Uses no Ward, Idol or Effigy slot; excluded from three-slot placement and recall.', .7, .75, .8, true)
        if not IsSpellKnown(self.utilityID) then
            GameTooltip:AddLine(self.utilityID == 9003673 and '尚未学习：在通用天赋中选择拟态守卫，保存并激活方案。' or (self.utilityID == 9003800 and '尚未学习战争魔像：在巫毒天赋中选择，保存并激活方案。' or '尚未学习大巫毒。学会后此槽自动显示技能。'), 1, .3, .3, true)
            GameTooltip:AddLine(self.utilityID == 9003673 and 'Not learned: select Mimic Ward in the Class tree, then save and activate the build.' or (self.utilityID == 9003800 and 'Not learned: select War Golem in the Voodoo tree, then save and activate the build.' or 'Big Bad Voodoo is not learned. This slot fills when learned.'), 1, .3, .3, true)
        end
    elseif self.utilityID then
        GameTooltip:AddLine(self.utilityID == 9003540 and '一次施放当前三个槽选中的召唤技能；仍需足够法力且技能冷却完毕。' or '回收自己的三类召唤物，返还成功召唤时实际法力费用的50%。', 1, 1, 1, true)
        if not IsSpellKnown(self.utilityID) then GameTooltip:AddLine('30级向巫医导师学习。', 1, .3, .3) end
    elseif self.isMain then
        GameTooltip:AddLine(self.category, .3, 1, .6)
        GameTooltip:AddLine('左键施放；右键或上方箭头展开选择。', 1, 1, 1, true)
        if not id then GameTooltip:AddLine('本类尚未学习召唤技能。', .7, .7, .7) end
    else
        GameTooltip:AddLine('点击选入主槽，再点击主槽施放。', 1, 1, 1, true)
    end
    GameTooltip:Show()
end
local function Skin(button)
    button.icon = button:CreateTexture(nil, 'BORDER')
    button.icon:SetAllPoints(button)
    button.icon:SetTexCoord(.05, .95, .05, .95)
    button:SetNormalTexture(addon.config.assets.normal)
    local normal = button:GetNormalTexture()
    normal:ClearAllPoints()
    normal:SetPoint('TOPRIGHT', button, 2.2, 2.3)
    normal:SetPoint('BOTTOMLEFT', button, -2.2, -2.2)
    normal:SetDrawLayer('OVERLAY')
    button:SetPushedTexture(addon.config.assets.normal)
    if button:GetPushedTexture().set_atlas then
        button:GetPushedTexture():set_atlas('_ui-hud-actionbar-iconborder-pushed')
    end
    button:GetPushedTexture():SetAllPoints(normal)
    button:SetHighlightTexture(addon.config.assets.highlight)
    button:GetHighlightTexture():SetAllPoints(normal)
    button.cooldown = CreateFrame('Cooldown', nil, button, 'CooldownFrameTemplate')
    button.cooldown:SetAllPoints(button)
    button:SetScript('OnEnter', Tooltip)
    button:SetScript('OnLeave', function() GameTooltip:Hide() end)
    allButtons[#allButtons + 1] = button
end
local function Paint()
    if not bar then return end
    SendSelection()
    local store = Store()
    for _, button in ipairs(allButtons) do
        local id = button:GetAttribute('choiceID') or button:GetAttribute('selectedID')
        if button.isMain and id and store then store[button.groupIndex] = id end
        -- An unlearned independent Ward is an empty slot, never a castable preview.
        if id and not IsSpellKnown(id) then id = nil end
        if id then
            local name, _, texture = GetSpellInfo(id)
            button.icon:SetTexture(texture)
            -- Query the exact localized spell/rank used by the secure cast button.
            -- Private numeric IDs are metadata keys, not reliable usability keys
            -- on this client. Match DragonUI's existing extra action buttons.
            local spell = button:GetAttribute('choiceSpell') or button:GetAttribute('spell1')
            local start, duration, enable = 0, 0, 0
            local usable, noMana
            if name and spell and IsSpellKnown(id) then
                start, duration, enable = GetSpellCooldown(spell)
                usable, noMana = IsUsableSpell(spell)
            end
            CooldownFrame_SetTimer(button.cooldown, start or 0, duration or 0, enable or 0)
            if not usable and noMana then button.icon:SetVertexColor(.4, .4, 1)
            elseif not usable then button.icon:SetVertexColor(.4, .4, .4)
            else button.icon:SetVertexColor(1, 1, 1) end
        else
            -- WD69B: unlearned categories keep an empty bordered slot.
            button.icon:SetTexture(nil)
            button.icon:SetVertexColor(.35, .35, .35)
            CooldownFrame_SetTimer(button.cooldown, 0, 0, 0)
        end
    end
end
local function SpellName(id)
    local name, rank = GetSpellInfo(id)
    if not name then return end
    return rank and rank ~= '' and (name .. '(' .. rank .. ')') or name
end

local function Build()
    if bar or InCombatLockdown() or not addon.db or not DragonUI_TotemAnchor then return end
    bar = CreateFrame('Frame', 'DragonUI_WitchDoctorBar', UIParent, 'SecureHandlerStateTemplate')
    bar:SetFrameStrata('MEDIUM')
    bar:SetFrameLevel(30)
    bar:SetPoint('BOTTOMLEFT', DragonUI_TotemAnchor, 'BOTTOMLEFT', 0, 0)
    local hover = {bar}
    for index, group in ipairs(groups) do
        local slot = CreateFrame('CheckButton', 'DragonUI_WDSummonSlot' .. index, bar, 'SecureActionButtonTemplate')
        slot.isMain, slot.groupIndex, slot.category = true, index, group.label
        slot:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
        Skin(slot)
        local flyout = CreateFrame('Frame', 'DragonUI_WDSummonFlyout' .. index, bar, 'SecureHandlerBaseTemplate')
        flyout:SetFrameLevel(40)
        flyout:SetBackdrop({bgFile = 'Interface\\Tooltips\\UI-Tooltip-Background',
            edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border', tile = true, tileSize = 16, edgeSize = 12,
            insets = {left = 3, right = 3, top = 3, bottom = 3}})
        flyout:SetBackdropColor(.025, .045, .035, .96)
        flyout:Hide()
        bar:SetFrameRef('flyout' .. index, flyout)
        SecureHandlerSetFrameRef(slot, 'owner', bar)
        SecureHandlerSetFrameRef(slot, 'flyout', flyout)
        bar:WrapScript(slot, 'OnClick', MAIN)
        local arrow = CreateFrame('Button', 'DragonUI_WDSummonArrow' .. index, bar, 'SecureHandlerClickTemplate')
        arrow:RegisterForClicks('LeftButtonUp')
        arrow:SetNormalTexture('Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up')
        arrow:SetHighlightTexture('Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Highlight')
        arrow:SetFrameRef('owner', bar)
        arrow:SetFrameRef('flyout', flyout)
        arrow:SetAttribute('_onclick', TOGGLE)
        arrow:SetScript('OnEnter', function(self)
            GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
            GameTooltip:SetText(group.label .. '：展开 / 收起', 1, .82, 0)
            GameTooltip:Show()
        end)
        arrow:SetScript('OnLeave', function() GameTooltip:Hide() end)
        slot.choices, slot.flyout, slot.arrow = {}, flyout, arrow
        for j, id in ipairs(group.ids) do
            local choice = CreateFrame('CheckButton', 'DragonUI_WDSummonChoice' .. index .. '_' .. j, flyout, 'SecureHandlerClickTemplate')
            Skin(choice)
            choice:SetAttribute('choiceID', id)
            choice:SetFrameRef('main', slot)
            choice:SetFrameRef('flyout', flyout)
            choice:SetAttribute('_onclick', SELECT)
            choice:RegisterForClicks('LeftButtonUp')
            slot.choices[j] = choice
            hover[#hover + 1] = choice
        end
        slots[index] = slot
        hover[#hover + 1], hover[#hover + 2], hover[#hover + 3] = slot, arrow, flyout
    end
    for index, id in ipairs({9003540, 9003541, 9003673, 9003580, 9003800}) do
        local button = CreateFrame('CheckButton', 'DragonUI_WDUtility' .. index, bar, 'SecureActionButtonTemplate')
        button.utilityID = id
        button.dedicatedSummon = id == 9003673 or id == 9003580 or id == 9003800
        button:RegisterForClicks('LeftButtonUp')
        button:SetAttribute('choiceID', id)
        Skin(button)
        if id == 9003540 then button:SetScript('PreClick', SendSelection) end
        utility[index] = button
        hover[#hover + 1] = button
    end
    -- When a vehicle takes over, close menus securely as well as hiding the bar.
    bar:SetAttribute('_onstate-display', [[
        if newstate == 'hide' then
            for i = 1, 3 do self:GetFrameRef('flyout' .. i):Hide() end
            self:Hide()
        else self:Show() end
    ]])
    if addon.VisibilityFade then
        addon.VisibilityFade.Register('witchdoctorSummons', bar, {
            dbTable = Config, hoverFrames = hover, clickThrough = false,
        })
    end
end

local function Refresh()
    dirty = true
    if InCombatLockdown() then return end
    Build()
    if not bar then return end
    local cfg, store = Config() or {}, Store() or {}
    local size = math.max(16, math.min(64, tonumber(cfg.button_size) or 34))
    local gap = math.max(0, math.min(20, tonumber(cfg.button_spacing) or 4))
    -- WD102: ritual, three categories, three independent summons, recall.
    local columns = #groups + #utility
    bar:SetSize(columns * size + (columns - 1) * gap, size + 16)
    for index, group in ipairs(groups) do
        local slot = slots[index]
        slot:SetSize(size, size)
        slot:ClearAllPoints()
        slot:SetPoint('BOTTOMLEFT', bar, 'BOTTOMLEFT', index * (size + gap), 0)
        slot.arrow:SetSize(22, 16)
        slot.arrow:ClearAllPoints()
        slot.arrow:SetPoint('BOTTOM', slot, 'TOP', 0, 0)
        slot.flyout:Hide()
        slot.flyout:ClearAllPoints()
        slot.flyout:SetPoint('BOTTOM', slot.arrow, 'TOP', 0, 2)
        local count, chosen, first = 0, nil, nil
        for j, id in ipairs(group.ids) do
            local choice = slot.choices[j]
            local name = SpellName(id)
            if IsSpellKnown(id) and name then
                first = first or id
                if store[index] == id then chosen = id end
                choice:SetAttribute('choiceSpell', name)
                choice:SetSize(size, size)
                choice:ClearAllPoints()
                choice:SetPoint('BOTTOMLEFT', slot.flyout, 'BOTTOMLEFT', 6, 6 + count * (size + 4))
                choice:Show()
                count = count + 1
            else choice:Hide(); choice:SetAttribute('choiceSpell', nil) end
        end
        chosen = chosen or first
        slot:SetAttribute('choiceCount', count)
        slot:SetAttribute('spell1', chosen and SpellName(chosen) or nil)
        slot:SetAttribute('type1', chosen and 'spell' or nil)
        slot:SetAttribute('selectedID', chosen)
        slot.flyout:SetSize(size + 12, math.max(1, count) * (size + 4) + 8)
        if count > 0 then slot.arrow:Show() else slot.arrow:Hide() end
    end
    local utilityColumns = {0, 7, 4, 5, 6} -- ritual, recall, Mimic, Voodoo, Golem
    for index, button in ipairs(utility) do
        local id = button.utilityID
        button:SetSize(size, size)
        button:ClearAllPoints()
        button:SetPoint('BOTTOMLEFT', bar, 'BOTTOMLEFT', utilityColumns[index] * (size + gap), 0)
        button:SetAttribute('type1', IsSpellKnown(id) and 'spell' or nil)
        button:SetAttribute('spell1', SpellName(id))
    end
    SendSelection()
    -- WD53A: custom Witch Doctor reports [possessbar] while not possessing.
    -- Match DragonUI multicast/extrabar vehicle-only visibility; do not gate on possessbar.
    -- 'visibility' is a special native path which bypasses _onstate snippets.
    RegisterStateDriver(bar, 'display', Enabled() and '[vehicleui] hide; show' or 'hide')
    if addon.VisibilityFade then addon.VisibilityFade.Update('witchdoctorSummons') end
    dirty = false
    Paint()
end
addon.RefreshWitchDoctorBar = Refresh

local watcher = CreateFrame('Frame')
for _, event in ipairs({'PLAYER_ENTERING_WORLD', 'SPELLS_CHANGED', 'LEARNED_SPELL_IN_TAB',
    'PLAYER_TALENT_UPDATE', 'PLAYER_REGEN_ENABLED', 'SPELL_UPDATE_COOLDOWN', 'PLAYER_LOGOUT'}) do
    watcher:RegisterEvent(event)
end
watcher:SetScript('OnEvent', function(_, event)
    if event == 'PLAYER_LOGOUT' or event == 'SPELL_UPDATE_COOLDOWN' then Paint()
    else dirty = true end
end)
watcher:SetScript('OnUpdate', function(_, elapsed)
    elapsedSincePaint = elapsedSincePaint + elapsed
    if elapsedSincePaint < .15 then return end
    elapsedSincePaint = 0
    if dirty and not InCombatLockdown() then Refresh() end
    -- Read secure selection attributes; visual/database writes only during combat.
    Paint()
end)
-- Existing DragonUI size/spacing/profile controls refresh the new class bar too.
if addon.RefreshMulticast then hooksecurefunc(addon, 'RefreshMulticast', Refresh) end


-- Read-only status after an ordinary out-of-combat refresh; no chat-method macros needed.
SLASH_DRAGONUIWDSUMMONS1 = '/wdsummons'
SlashCmdList.DRAGONUIWDSUMMONS = function()
    Refresh()
    local cfg = Config() or {}
    print('WD53A', 'enabled=' .. tostring(Enabled()),
        'state=' .. tostring(bar and bar:GetAttribute('state-display')),
        'shown=' .. tostring(bar and bar:IsShown()),
        'alpha=' .. tostring(bar and bar:GetAlpha()),
        'vehicle=' .. tostring(SecureCmdOptionParse('[vehicleui] yes; no')),
        'possess=' .. tostring(SecureCmdOptionParse('[possessbar] yes; no')))
end
