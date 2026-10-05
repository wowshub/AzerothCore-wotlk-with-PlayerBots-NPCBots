
-- WD114C: recover known standalone spells omitted by the custom highest-rank list.
-- Display only: never learns/casts spells or derives ownership from talent drafts.
local ids={9003850,9003851,9003852,9003853,9003854}
local wanted={};for _,id in ipairs(ids) do wanted[id]=true end
local function isDoctor()
 local _,token,id=UnitClass("player");return token=="WITCHDOCTOR" or id==13
end
local function scan()
 local native,tab={},nil
 for i=1,GetNumSpellTabs() do
  local name,_,offset,count=GetSpellTabInfo(i)
  if name and (name:find("巫毒",1,true) or name:lower():find("voodoo",1,true)) then tab=i end
  for slot=(offset or 0)+1,(offset or 0)+(count or 0) do
   local link=GetSpellLink(slot,BOOKTYPE_SPELL or "spell")
   local id=link and tonumber(link:match("spell:(%d+)"))
   if id then
    native[id]={tab=i,slot=slot}
    if not tab and (id==9003143 or id==9003150 or id==9003640) then tab=i end
   end
  end
 end
 return native,tab
end
local busy=false
local function repair()
 if busy or not isDoctor() or (InCombatLockdown and InCombatLockdown()) then return end
 if not SpellBookFrame or SpellBookFrame.bookType~=(BOOKTYPE_SPELL or "spell") or type(spellbookCustomRender)~="table" then return end
 busy=true
 local native,tab=scan()
 local present,changed={},false
 for _,list in pairs(spellbookCustomRender) do
  for i=#list,1,-1 do
   local entry=list[i]
   if entry.wd114c and not IsSpellKnown(entry.spellID) then table.remove(list,i);changed=true
   else present[entry.spellID]=true end
  end
 end
 for _,id in ipairs(ids) do
  local target=(native[id] and native[id].tab) or tab
  if not present[id] and target and IsSpellKnown(id) and GetSpellInfo(id) then
   spellbookCustomRender[target]=spellbookCustomRender[target] or {}
   table.insert(spellbookCustomRender[target],{spellID=id,spellIndex=native[id] and native[id].slot,wd114c=true})
   changed=true;present[id]=true
  end
 end
 if changed then
  for i,list in pairs(spellbookCustomRender) do
   SpellBookFrame.selectedSkillLineNumSpells[i]=#list
  end
  if SpellBookFrame_UpdatePages then SpellBookFrame_UpdatePages() end
  if SpellBookFrame:IsShown() and SpellButton_UpdateButton then SpellButton_UpdateButton() end
 end
 busy=false
end
local installed=false
local function install()
 if not installed and type(SpellBookFrame_UpdateSpellRender)=="function" then
  hooksecurefunc("SpellBookFrame_UpdateSpellRender",repair);installed=true
 end
end
local events=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_LOGIN","ADDON_LOADED","SPELLS_CHANGED","PLAYER_REGEN_ENABLED"}) do events:RegisterEvent(event) end
events:SetScript("OnEvent",function(_,event)
 install()
 if event~="ADDON_LOADED" then repair() end
end)
install()
local oldDiag=SlashCmdList.REBORNWDBOOK
SlashCmdList.REBORNWDBOOK=function(...)
 oldDiag(...)
 if not isDoctor() then return end
 local native=scan();local present={}
 for _,list in pairs(spellbookCustomRender or {}) do for _,entry in ipairs(list) do present[entry.spellID]=true end end
 for _,id in ipairs(ids) do
  print(string.format("[WD114C] %d %s | 已学=%s 原生槽=%s 列表=%s",id,GetSpellInfo(id) or "缺少客户端Spell记录",tostring(IsSpellKnown(id)),tostring(native[id] and native[id].slot),tostring(present[id] or false)))
 end
end
return {repair=repair,scan=scan}
