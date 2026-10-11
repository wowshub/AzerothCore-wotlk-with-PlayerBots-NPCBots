-- TG1F: explicit views and drafts; never treat a sent command as acknowledgement.
local G=RebornTalentGuide
local installed=false
local function install()
 local m=MultiBot;local f=m and m.talent
 if installed or not f or not f.frames or not f.frames.Tab8 then return end
 installed=true
 local mode='actual';local pending=false
 local names={actual='当前天赋',glyphs='当前雕文',custom='手动配点',customGlyphs='手动配雕文'}
 local function Title()
  local draft=mode=='custom'or mode=='customGlyphs'
  local state=pending and'｜已发送，请刷新核对'or(draft and'｜草稿，尚未应用'or'｜查询快照')
  f.setText('Title',(draft and'|cffff8050'or'|cffffcc00')..names[mode]..' · '..(f.name or'?')..state..'|r')
 end
 local function Mode(value)mode=value;pending=false;Title()end
 local function MarkTalent(button)
  if not button or button.rebornDraftLabels then return end
  button.rebornDraftLabels=true
  for _,key in ipairs({'doLeft','doRight'})do
   local original=button[key]
   if original then button[key]=function(self)
    local before=self.value;original(self)
    if self.value~=before then f.custom=true;Mode('custom')end
   end end
  end
 end
 if f.addTalent then
  local add=f.addTalent
  f.addTalent=function(... )local button=add(...);MarkTalent(button);return button end
 end
 for t=1,3 do
  local tab=f.frames['Tab'..t]
  if tab then for _,button in pairs(tab.buttons or{})do MarkTalent(button)end end
 end
 f.rebornGuideViewChanged=function(kind)Mode(kind=='custom'and'custom'or'actual')end
 local specs={{'Tab5','Talents','actual'},{'Tab6','Glyphs','glyphs'},{'Tab7','Custom Talents','custom'},{'Tab8','Custom Glyphs','customGlyphs'}}
 for _,spec in ipairs(specs)do
  local tab,key,kind=spec[1],spec[2],spec[3]
  local button=f.frames[tab].buttons and f.frames[tab].buttons[key]
  if button then
   if button.text then button.text:SetText(names[kind])end
   local old=button.doLeft
   button.doLeft=function(self)
    if f.rebornCancelTalentRead then f.rebornCancelTalentRead()end
    if old then old(self)end
    Mode(kind)
    if kind=='actual' then
     local unit=m.toUnit and m.toUnit(f.name)
     if unit and UnitExists(unit)then
      InspectUnit(unit);f.custom=false
      if m.auto then m.auto.talent=true end
      if m.timer then m.timer.elapsed=0 end
     end
    end
   end
   button:HookScript('OnEnter',function(self)
    GameTooltip:SetOwner(self,'ANCHOR_BOTTOM');GameTooltip:SetText(names[kind],1,.82,0)
    GameTooltip:AddLine((kind=='custom'or kind=='customGlyphs')and'手动设计草稿；点击应用才提交给机器人。关闭或重新打开编辑页可能丢失草稿，不会自动收藏。'or'重新查询机器人数据；查询快照不等于提交成功回执。',1,1,1,true);GameTooltip:Show()
   end)
   button:HookScript('OnLeave',function()GameTooltip:Hide()end)
  end
 end
 local apply=f.buttons and m.info and m.info.talent and f.buttons[m.info.talent.Apply]
 if apply and apply.text then apply.text:SetText('应用到机器人')end
 if gApply and gApply.text then gApply.text:SetText('应用雕文')end
 -- Observe the existing sender without replacing either command or payload.
 hooksecurefunc('SendChatMessage',function(message,channel,language,target)
  if channel=='WHISPER'and target==f.name and type(message)=='string'and
    (message:match('^talents apply ')or message:match('^glyph equip '))then
   pending=true;Title()
  end
 end)
 f:HookScript('OnShow',function()if not f.custom then Mode('actual')else Title()end end)
 Title()
end
local events=CreateFrame('Frame');events:RegisterEvent('ADDON_LOADED');events:RegisterEvent('PLAYER_LOGIN')
events:SetScript('OnEvent',install);install()
