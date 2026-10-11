-- TG1D: gate MultiBot tree rendering on a complete inspect snapshot.
-- No writes to MultiBot source; wrappers are removed by disabling this addon.
local clock=CreateFrame('Frame')
local pending,installed
local function ready(m)
 local f=m.talent
 local class=m.data and m.data.talent and m.data.talent.talents[f.class]
 if not class then return false end
 local group=GetActiveTalentGroup(true) or 1
 local points=GetUnspentTalentPoints(true)
 if type(points)~='number' then return false end
 for t=1,3 do
  if not class[t] then return false end
  for i=1,#class[t] do
   local name,icon,row,col,rank,max=GetTalentInfo(t,i,true,nil,group)
   local link=GetTalentLink(t,i,true,nil,group)
   if not name or not icon or not row or not col or type(rank)~='number' or not max or not link or not link:match('talent:%d+:') then return false end
  end
 end
 return true
end
local function install()
 local m=MultiBot
 if installed or not m or not m.talent or not m.talent.setTalents or not m.talent.setTalentsCustom then return end
 installed=true
 local f=m.talent
 f.rebornCancelTalentRead=function()pending=nil end
 local actual,custom=f.setTalents,f.setTalentsCustom
 if f.HookScript then f:HookScript('OnHide',function()pending=nil end)end
 local function request(kind)
  local unit=m.toUnit and m.toUnit(f.name)
  local guid=unit and UnitGUID(unit)
  if not guid then return end
  if pending and pending.name==f.name and pending.guid==guid and pending.kind==kind then return end
  pending={name=f.name,guid=guid,kind=kind,attempt=0,next=GetTime()+.3}
 end
 f.setTalents=function()request('actual')end
 f.setTalentsCustom=function()request('custom')end
 clock:SetScript('OnUpdate',function()
  local p=pending
  if not p or GetTime()<p.next then return end
  local unit=m.toUnit and m.toUnit(f.name)
  if f.name~=p.name or not unit or UnitGUID(unit)~=p.guid then pending=nil;return end
  p.attempt=p.attempt+1
  if ready(m) then
   pending=nil
   if p.kind=='custom'then custom()else f.custom=false;actual()end
   if f.rebornGuideViewChanged then f.rebornGuideViewChanged(p.kind)end
   if RebornTalentGuide and RebornTalentGuide.fromBot and RebornTalentGuide.botName==p.name then
    local g=RebornTalentGuide;g.botRanks,g.botError=g.BotSnapshot();g.message=g.botError;g.Refresh()
   end
  elseif p.attempt>=12 then
   pending=nil
   print('|cffffcc00[天赋推荐] '..p.name..' 的三系数据尚未齐全；已停止重试，请靠近后重新打开天赋。|r')
  else p.next=GetTime()+.4 end
 end)
end
clock:RegisterEvent('ADDON_LOADED');clock:RegisterEvent('PLAYER_LOGIN')
clock:SetScript('OnEvent',install);install()
