local known={[9003852]=true,[9003853]=true,[9003854]=true}
local combat=false;local doctor=true;local hooks={};local changed=0
BOOKTYPE_SPELL='spell'
function UnitClass()return '',doctor and 'WITCHDOCTOR' or 'MAGE',doctor and 13 or 8 end
function GetNumSpellTabs()return 3 end
function GetSpellTabInfo(i)return ({'综合','巫毒 / Voodoo','酿造'})[i],nil,(i-1)*2,2 end
local slots={[1]=6603,[3]=9003143,[4]=9003853,[5]=9003621}
function GetSpellLink(slot)return slots[slot] and 'spell:'..slots[slot] end
function IsSpellKnown(id)return known[id] or false end
function GetSpellInfo(id)return 'spell'..id end
function InCombatLockdown()return combat end
function CreateFrame()return {RegisterEvent=function()end,SetScript=function(self,k,v)self[k]=v end}end
function hooksecurefunc(name,fn)hooks[name]=fn end
function SpellBookFrame_UpdateSpellRender()end
function SpellBookFrame_UpdatePages()changed=changed+1 end
function SpellButton_UpdateButton()end
SpellBookFrame={bookType='spell',selectedSkillLineNumSpells={},IsShown=function()return true end}
SlashCmdList={REBORNWDBOOK=function()end}
spellbookCustomRender={[1]={{spellID=6603}},[2]={{spellID=9003143}},[3]={{spellID=9003621}}}
local M=assert(loadfile(arg[1]))()
hooks.SpellBookFrame_UpdateSpellRender()
assert(#spellbookCustomRender[2]==4)
assert(spellbookCustomRender[2][3].spellID==9003853 and spellbookCustomRender[2][3].spellIndex==4)
assert(SpellBookFrame.selectedSkillLineNumSpells[2]==4 and #spellbookCustomRender[3]==1)
assert(not known[9003850] and not known[9003851])
M.repair();assert(#spellbookCustomRender[2]==4 and changed==1)
known[9003853]=false;M.repair();assert(#spellbookCustomRender[2]==3)
-- Existing original entries are kept, no duplicate or name-based merge.
spellbookCustomRender[2]={{spellID=9003852},{spellID=9003854}}
M.repair();assert(#spellbookCustomRender[2]==2)
known[9003853]=true;combat=true;M.repair();assert(#spellbookCustomRender[2]==2)
combat=false;M.repair();assert(#spellbookCustomRender[2]==3)
spellbookCustomRender[2]={};doctor=false;M.repair();assert(#spellbookCustomRender[2]==0)
doctor=true;SpellBookFrame.bookType='pet';M.repair();assert(#spellbookCustomRender[2]==0)
SpellBookFrame.bookType='spell'
-- No native tab/anchor: do not guess or insert into General.
function GetNumSpellTabs()return 1 end
M.repair();assert(#spellbookCustomRender[1]==1 and #spellbookCustomRender[2]==0)
print('PASS: known-only recovery; real native slot; missing-slot by-ID entry; counts; idempotence; removal; existing entries; combat; other class; pet; missing category; old Potent rank retained')
