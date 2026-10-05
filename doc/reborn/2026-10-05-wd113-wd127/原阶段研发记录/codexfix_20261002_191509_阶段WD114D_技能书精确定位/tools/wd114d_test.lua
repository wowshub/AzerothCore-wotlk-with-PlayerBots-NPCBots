BOOKTYPE_SPELL='spell';SlashCmdList={REBORNWDBOOK=function()end}
spellbookCustomRender={[2]={},[5]={{spellID=9003621}}};SPELLBOOK_PAGENUMBERS={}
for i=1,41 do spellbookCustomRender[2][i]={spellID=1000+i} end
spellbookCustomRender[2][40]={spellID=9003852}
spellbookCustomRender[2][7]={spellID=9003853}
spellbookCustomRender[2][19]={spellID=9003854}
local combat=false;local known=true;local pet=false;local previous=0
function UnitClass()return '','WITCHDOCTOR',13 end
function InCombatLockdown()return combat end
function IsSpellKnown()return known end
function SpellBookFrame_UpdateSpellRender()end
SpellBookFrame={bookType='spell',IsShown=function()return true end}
SpellBookSearchBox={SetText=function(_,t)assert(t=='')end}
function SpellBookSkillLineTab_OnClick(_,tab)SpellBookFrame.selectedSkillLine=tab end
function SpellBookFrame_UpdateSpellState()end
function SpellButton_UpdateButton()
 local tab=SpellBookFrame.selectedSkillLine
 for i=1,12 do
  local row=spellbookCustomRender[tab][(SPELLBOOK_PAGENUMBERS[tab]-1)*12+i]
  _G['SpellButton'..i]={data=row and row.spellID,IsShown=function()return true end}
 end
end
local M=assert(loadfile(arg[1]))()
SlashCmdList.REBORNWDBOOK('9003852');assert(SPELLBOOK_PAGENUMBERS[2]==4 and SpellButton4.data==9003852)
SlashCmdList.REBORNWDBOOK('假死');assert(SPELLBOOK_PAGENUMBERS[2]==1 and SpellButton7.data==9003853)
SlashCmdList.REBORNWDBOOK('强效混合');assert(SPELLBOOK_PAGENUMBERS[2]==2 and SpellButton7.data==9003854)
combat=true;SlashCmdList.REBORNWDBOOK('假死');assert(SPELLBOOK_PAGENUMBERS[2]==2)
combat=false;known=false;SlashCmdList.REBORNWDBOOK('假死');assert(SPELLBOOK_PAGENUMBERS[2]==2)
known=true;SpellBookFrame.bookType='pet';SlashCmdList.REBORNWDBOOK('假死');assert(SPELLBOOK_PAGENUMBERS[2]==2)
assert(spellbookCustomRender[5][1].spellID==9003621)
print('PASS exact ID/page/slot navigation, Chinese aliases, same-name rank preserved, combat/unknown/pet guards')
