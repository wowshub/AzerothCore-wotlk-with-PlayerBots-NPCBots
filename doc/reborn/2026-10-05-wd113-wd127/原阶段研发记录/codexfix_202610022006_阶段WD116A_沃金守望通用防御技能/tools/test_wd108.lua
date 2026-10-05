local objects={}
local function obj()
 local t={scripts={}}
 setmetatable(t,{__index=function(self,k)
  if k=='CreateFontString' or k=='CreateTexture' then return obj end
  if k=='SetScript' then return function(s,key,f)s.scripts[key]=f end end
  if k=='SetText' then return function(s,v)s.text=v end end
  if k=='SetPoint' then return function(s,...)s.point={...}end end
  if k=='GetFrameLevel' then return function()return 1 end end
  return function()end
 end});objects[#objects+1]=t;return t
end
CreateFrame=obj
RebornWDRegisterTranslation=function()end
RebornWDSetText=function(t,v)t:SetText(v)end
RebornWDLocalize=function(v)return v end
RebornWDSetDropdown=function()end
UIDropDownMenu_SetWidth=function()end
UIDropDownMenu_Initialize=function()end
local M={loaded=false,pending=false,active=1,slot=0,unlocked=2,specs={0,1,3},keys={[0]='Voodoo',[1]='Brewing',[2]='Shadowhunting'},draftSpec=0}
RebornWD8=M
local dirty=false;local resets=0;local replies=0
M.HasDrafts=function()return dirty end
M.ResetDraft=function(slot)resets=resets+1;M.slot=slot;M.draftSpec=M.specs[slot+1]end
M.AEOnReply=function()replies=replies+1 end
M.SelectSlot=function(slot)M.slot=slot end
M.Activate=function()end
assert(loadfile(arg[1]))()
M.AEOnReply();assert(resets==0)
M.loaded=true;M.AEOnReply();assert(resets==1 and M.slot==1 and M.draftSpec==1)
M.slot=0;dirty=true;M.AEOnReply();assert(M.slot==0 and resets==1 and dirty)
dirty=false;M.AEOnReply();assert(M.slot==0 and resets==1 and replies==4)
RebornWD8ToggleProfiles(obj())
local rows={};for _,v in ipairs(objects)do if type(v.title)=='table' and type(v.status)=='table' then rows[#rows+1]=v end end
assert(#rows==10)
assert(rows[2].point[3]==-34 and rows[1].point[3]==-72)
assert(rows[2].title.text=='方案：2' and rows[1].title.text=='方案：1')
rows[1].scripts.OnClick();assert(M.slot==0)
rows[2].scripts.OnClick();assert(M.slot==1)
M.active=0;RebornWD8RefreshProfiles();assert(rows[1].point[3]==-34 and rows[2].point[3]==-72)
M.active=2;M.unlocked=3;M.specs[3]=2;RebornWD8RefreshProfiles();assert(rows[3].point[3]==-34 and rows[1].point[3]==-72 and rows[2].point[3]==-110)
rows[3].scripts.OnClick();assert(M.slot==2)
print('PASS: failed/initial/repeated sync; manual browse and drafts retained; active 0/1/2 ordering; original numbers and all real slot click targets retained')
