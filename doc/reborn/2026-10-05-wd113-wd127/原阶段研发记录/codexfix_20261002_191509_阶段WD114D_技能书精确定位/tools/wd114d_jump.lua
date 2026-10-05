-- WD114D: exact-ID navigation in the existing spellbook, not a second spell panel.
local previousBookCommand=SlashCmdList.REBORNWDBOOK
local names={['假死']=9003853,['假死药剂']=9003853,['显性诅咒']=9003852,['强效混合']=9003854}
local managed={[9003850]=true,[9003851]=true,[9003852]=true,[9003853]=true,[9003854]=true}
local function locate(id)
 for tab,list in pairs(spellbookCustomRender or {}) do
  for index,entry in ipairs(list) do
   if entry.spellID==id then return tab,math.ceil(index/12),(index-1)%12+1 end
  end
 end
end
SlashCmdList.REBORNWDBOOK=function(arg)
 local text=(arg or ''):match('^%s*(.-)%s*$')
 local id=tonumber(text) or names[text]
 if not id then
  previousBookCommand(arg)
  for sid in pairs(managed) do
   local tab,page,slot=locate(sid)
   if tab then print(string.format('[WD114D] %d：分类%d，第%d页，第%d格',sid,tab,page,slot)) end
  end
  return
 end
 local _,token,classID=UnitClass('player')
 if token~='WITCHDOCTOR' and classID~=13 then return end
 if not managed[id] then print('[WD114D] 请使用9003850—9003854。');return end
 if InCombatLockdown() then print('[WD114D] 请脱战后定位技能。');return end
 if not SpellBookFrame or not SpellBookFrame:IsShown() or SpellBookFrame.bookType~='spell' then
  print('[WD114D] 请先打开法术书的法术页，再执行命令。');return
 end
 if not IsSpellKnown(id) then print('[WD114D] 当前方案未学会该技能。');return end
 if not SpellBookFrame_UpdateSpellRender or not SpellBookSkillLineTab_OnClick then print('[WD114D] 当前技能书接口不匹配。');return end
 SpellBookFrame_UpdateSpellRender()
 local tab,page,slot=locate(id)
 if not tab then print('[WD114D] 已学但当前列表没有该编号，请发/wdbook输出。');return end
 -- Clear the old name search so it cannot select another same-name rank.
 if SpellBookSearchBox and SpellBookSearchBox.SetText then SpellBookSearchBox:SetText('') end
 SpellBookFrame.searchSpellID=id
 SPELLBOOK_PAGENUMBERS[tab]=page
 SpellBookSkillLineTab_OnClick(nil,tab)
 SpellButton_UpdateButton()
 if SpellBookFrame_UpdateSpellState then SpellBookFrame_UpdateSpellState() end
 local button=_G['SpellButton'..slot]
 local rendered=button and button.data==id
 local shown=button and button:IsShown()
 print(string.format('[WD114D] %d：分类%d，第%d页，第%d格；按钮匹配=%s，可见=%s',id,tab,page,slot,tostring(rendered or false),tostring(shown or false)))
end
return {locate=locate}
