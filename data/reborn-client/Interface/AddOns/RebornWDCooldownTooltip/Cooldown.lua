-- WD100A: display only. Never changes cooldowns, casts, DBC, or talent drafts.
local _, class, classID = UnitClass('player')
if classID ~= 13 and class ~= 'WITCHDOCTOR' and class ~= 'WITCH_DOCTOR' then return end
-- Generated from the exact WD63/WD89 summon whitelist and this package's two Spell.dbc sides.
local baseCooldown = {[9003370]=180,[9003410]=12,[9003420]=45,[9003430]=60,[9003432]=60,[9003450]=60,[9003673]=60}
local english = GetLocale() ~= 'zhCN' and GetLocale() ~= 'zhTW'
local function Seconds(n)
    return (string.format('%.2f', n):gsub('0+$', ''):gsub('%.$', ''))
end
local function Duration(n)
    local minutes = math.floor(n / 60)
    local seconds = n - minutes * 60
    if minutes == 0 then return Seconds(seconds) .. (english and ' sec' or '秒') end
    local text = tostring(minutes) .. (english and ' min' or '分')
    if seconds > 0 then text = text .. (english and ' ' or '') .. Seconds(seconds) .. (english and ' sec' or '秒') end
    return text
end
local function IsHeader(text)
    if not text then return false end
    text = text:gsub('|c%x%x%x%x%x%x%x%x', ''):gsub('|r', '')
    if #text > 100 or not text:match('^%s*%d') then return false end
    return text:find('冷却时间', 1, true) or text:find('冷卻時間', 1, true) or text:lower():find('cooldown', 1, true)
end
local function Refresh(tip)
    local state = tip.wd100Cooldown
    if not state then return end
    -- HasSpell is learned/removed by the server on save/switch; a local unsaved draft is irrelevant.
    local active = IsSpellKnown(9003653) and true or false
    local effective = state.base * (active and .75 or 1)
    for _,font in ipairs(state.headers) do
        font:SetText(Duration(effective) .. (english and ' cooldown' or '冷却时间'))
    end
    if state.formula then
        local text
        if active then
            text = (english and 'Cooldown (Hastened): ' or '冷却时间（迅捷召唤）：') .. Duration(state.base) .. ' × 75% = ' .. Duration(effective)
        else
            text = (english and 'Base cooldown: ' or '基础冷却：') .. Duration(state.base) .. (english and ' (Hastened inactive)' or '（迅捷召唤未生效）')
        end
        state.formula:SetText(text)
    end
end
local function Describe(tip, id)
    id = tonumber(id)
    if not baseCooldown[id] or not tip.GetName or not tip:GetName() then return end
    if tip.wd100Cooldown then
        if tip.wd100Cooldown.id == id then Refresh(tip) end
        return
    end
    local state = {id=id, base=baseCooldown[id], headers={}}
    tip.wd100Cooldown = state
    local name = tip:GetName()
    -- Only the numeric cooldown heading; never duration prose or the current remaining-cooldown line.
    for i=2,math.min(5,tip:NumLines()) do
        for _,side in ipairs({'Left','Right'}) do
            local font = _G[name .. 'Text' .. side .. i]
            if font and IsHeader(font:GetText()) then state.headers[#state.headers+1] = font end
        end
    end
    tip:AddLine(' ', .3, 1, .6, true)
    state.formula = _G[name .. 'TextLeft' .. tip:NumLines()]
    Refresh(tip)
    tip:Show()
end
GameTooltip:HookScript('OnTooltipCleared',function(tip) tip.wd100Cooldown=nil;tip.wd100Elapsed=0 end)
GameTooltip:HookScript('OnTooltipSetSpell',function(tip) local _,id=tip:GetSpell();Describe(tip,id) end)
hooksecurefunc(GameTooltip,'SetHyperlink',function(tip,link)
    if type(link)=='string' then Describe(tip,link:match('spell:(%d+)')) end
end)
if GameTooltip.SetSpellByID then hooksecurefunc(GameTooltip,'SetSpellByID',Describe) end
if GameTooltip.SetSpellBookItem and GetSpellBookItemInfo then
    hooksecurefunc(GameTooltip,'SetSpellBookItem',function(tip,index,book)
        local kind,id=GetSpellBookItemInfo(index,book)
        if kind=='SPELL' then Describe(tip,id) end
    end)
end
hooksecurefunc(GameTooltip,'SetAction',function(tip,slot)
    local kind,id=GetActionInfo(slot)
    if kind=='spell' then Describe(tip,id) end
end)
GameTooltip:HookScript('OnUpdate',function(tip,elapsed)
    if not tip.wd100Cooldown then return end
    tip.wd100Elapsed=(tip.wd100Elapsed or 0)+elapsed
    if tip.wd100Elapsed<.25 then return end
    tip.wd100Elapsed=0;Refresh(tip)
end)
-- Returned only to the offline harness; the game ignores chunk return values.
return {Describe=Describe,Refresh=Refresh,Duration=Duration,baseCooldown=baseCooldown}
