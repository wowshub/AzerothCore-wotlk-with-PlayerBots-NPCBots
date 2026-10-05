-- WD52A: follow MONKM1B's read-only native spellbook diagnostics.
SLASH_REBORNWDBOOK1 = "/wdbook"
SlashCmdList.REBORNWDBOOK = function()
    local _, class, id = UnitClass("player")
    if class ~= "WITCHDOCTOR" and id ~= 13 then
        print("[WD52A] 当前角色不是巫医。")
        return
    end
    print("[WD52A] 技能书分类不限制专精，也不会自动学习技能。")
    for i = 1, GetNumSpellTabs() do
        local name, _, offset, count = GetSpellTabInfo(i)
        print(string.format("%d: %s / %d spells / offset %d", i, name or "?", count or 0, offset or 0))
    end
end


-- WD119B: read-only diagnostics. Never refresh, navigate or mutate native spellbook state.
local ids={9003850,9003851,9003852,9003853,9003854,9003855,9003432,9003857,9003858}
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
local function locate(id)
 for tab,list in pairs(spellbookCustomRender or {}) do
  for index,entry in ipairs(list) do
   if entry.spellID==id then return tab,math.ceil(index/12),(index-1)%12+1 end
  end
 end
end

local names={['假死']=9003853,['假死药剂']=9003853,['显性诅咒']=9003852,['強效混合']=9003854,['强效混合']=9003854,['沃金守望']=9003855,['迅捷神像']=9003432}
local previous=SlashCmdList.REBORNWDBOOK
local lastBlocked
local monitor=CreateFrame('Frame')
monitor:RegisterEvent('ADDON_ACTION_BLOCKED')
monitor:RegisterEvent('ADDON_ACTION_FORBIDDEN')
monitor:SetScript('OnEvent',function(_,event,addon,operation)
 if isDoctor() then lastBlocked={event,tostring(addon),tostring(operation)} end
end)
SlashCmdList.REBORNWDBOOK=function(arg)
 if not isDoctor() then return end
 local text=(arg or ''):match('^%s*(.-)%s*$')
 local id=tonumber(text) or names[text]
 if not id then previous() end
 local native=scan()
 for _,sid in ipairs(id and {id} or ids) do
  local tab,page,slot=locate(sid)
  print(string.format('[WD119B] %d %s 已学=%s 原生槽=%s 分类=%s 页=%s 格=%s',sid,GetSpellInfo(sid) or '?',tostring(IsSpellKnown(sid)),tostring(native[sid] and native[sid].slot),tostring(tab),tostring(page),tostring(slot)))
 end
 print('[WD119B] 只读定位：请手动点击对应分类和页码；左右列交替计格。')
 if lastBlocked then print('[WD119B] 最近受保护操作：'..table.concat(lastBlocked,' / ')) end
end
return {locate=locate,scan=scan}
