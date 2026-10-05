-- WD114: read-only, self-only server calculation. Never computes cost from a draft.
local tip=GameTooltip
local allowed,power={},{}
local function range(a,b) for id=a,b do allowed[id]=true end end
range(9003140,9003143);range(9003180,9003185)
for _,id in ipairs({9003190,9003280,9003290,9003300,9003150,9003200,9003210,9003762,9003240,9003101}) do allowed[id]=true end
range(9003220,9003225);range(9003130,9003138)
for id=9003180,9003185 do power[id]=true end;power[9003300]=true
local en=GetLocale()~="zhCN" and GetLocale()~="zhTW"
local frame=CreateFrame("Frame")
local cache,pending={},nil
local seq,epoch,nextSend,elapsed,failures=0,0,0,0,0
local function doctor()
 local _,token,id=UnitClass("player");return token=="WITCHDOCTOR" or tonumber(id)==13
end
local function invalidate()
 epoch=epoch+1;cache={};pending=nil
end
local function plain(s) return s:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","") end
local function failed()
 failures=failures+1
 if failures>=3 then nextSend=GetTime()+60;failures=0 end
end
local function refresh(self,forced)
 if not doctor() then return end
 local _,second,third=self:GetSpell()
 local id=tonumber(forced) or tonumber(third) or tonumber(second) or self.wd114Spell
 if not allowed[id] then return end
 self.wd114Spell=id
 local now=GetTime();local value=cache[id]
 if value and now-value.time>2 then value=nil end
 local state=RebornWD8
 if state and (state.pending or (value and state.loaded and (value.rev~=state.revision or value.active~=state.active))) then value=nil end
 if pending and now-pending.time>2 then pending=nil;failed() end
 if not pending and now>=nextSend and (not value or now-value.time>1) and not (state and state.pending) then
  seq=seq+1;pending={seq=seq,id=id,epoch=epoch,time=now};nextSend=now+1
  SendChatMessage(".wd114numbers "..seq.." "..id,"SAY")
 end
 self.wd114Lines=self.wd114Lines or {}
 for i=2,self:NumLines() do
  for _,side in ipairs({"Left","Right"}) do
   local key=self:GetName().."Text"..side..i
   local font=_G[key];local text=font and font:GetText()
   if text then
    local original=self.wd114Lines[key] or text
    local clean=plain(original)
    if clean:match("^%s*%d+%s*法力值%s*$") or clean:match("^%s*%d+%s*[Mm]ana%s*$") then
     self.wd114Lines[key]=original
     font:SetText(value and (tostring(value.cost)..(en and " Mana" or "法力值")) or (original..(en and " (syncing)" or "（同步中）")))
    end
   end
  end
 end
 if power[id] or id==9003240 then
  local text
  if value then
   if power[id] then text=en and ("Current melee / ranged attack power: +"..value.a.." / +"..value.b) or ("当前近战／远程攻击强度：+"..value.a.."／+"..value.b)
   else text=en and ("Curse removal attempts: "..value.a) or ("可尝试移除诅咒数量："..value.a) end
  else text=en and "Current effect: syncing" or "当前效果：同步中" end
  if not self.wd114EffectLine then
   self:AddLine(text,.3,1,.3,true);self.wd114EffectLine=self:NumLines();if self.Show then self:Show() end
  else
   local font=_G[self:GetName().."TextLeft"..self.wd114EffectLine];if font then font:SetText(text) end
  end
 end
end
local function receive(message)
 local n,id,status,rest=message:match("^WD114|(%d+)|(%d+)|([^|]+)|?(.*)$")
 n,id=tonumber(n),tonumber(id)
 if not n or not pending or n~=pending.seq or id~=pending.id or pending.epoch~=epoch then return end
 pending=nil
 if status~="ok" then failed();return end
 local cost,a,b,rev,active=rest:match("^(%d+)|([%-]?%d+)|([%-]?%d+)|(%d+)|(%d+)$")
 if not cost then return end
 local state=RebornWD8
 if state and state.loaded and (state.pending or tonumber(rev)~=state.revision or tonumber(active)~=state.active) then return end
 failures=0
 cache[id]={cost=tonumber(cost),a=tonumber(a),b=tonumber(b),rev=tonumber(rev),active=tonumber(active),time=GetTime()}
 if tip:IsShown() and tip.wd114Spell==id then refresh(tip,id) end
end
for _,event in ipairs({"CHAT_MSG_SYSTEM","PLAYER_ENTERING_WORLD","UNIT_AURA","UNIT_STATS","UNIT_INVENTORY_CHANGED","PLAYER_LEVEL_UP"}) do frame:RegisterEvent(event) end
frame:SetScript("OnEvent",function(_,event,arg)
 if event=="CHAT_MSG_SYSTEM" then
  if type(arg)=="string" and arg:match("^WD114|") then receive(arg)
  elseif type(arg)=="string" and arg:match("^WD16|") then invalidate() end
 elseif event:match("^UNIT_") then if arg=="player" then invalidate() end
 else invalidate() end
end)
ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM",function(_,_,text) return type(text)=="string" and text:match("^WD114|")~=nil end)
tip:HookScript("OnTooltipCleared",function(self) self.wd114Spell=nil;self.wd114Lines=nil;self.wd114EffectLine=nil end)
tip:HookScript("OnTooltipSetSpell",refresh)
tip:HookScript("OnUpdate",function(self,dt) elapsed=elapsed+dt;if elapsed>=.2 then elapsed=0;refresh(self) end end)
hooksecurefunc(tip,"SetHyperlink",function(self,link) if type(link)=="string" then refresh(self,link:match("spell:(%d+)")) end end)
if tip.SetSpellByID then hooksecurefunc(tip,"SetSpellByID",refresh) end
if tip.SetSpell and GetSpellLink then hooksecurefunc(tip,"SetSpell",function(self,index,book) local link=GetSpellLink(index,book);if type(link)=="string" then refresh(self,link:match("spell:(%d+)")) end end) end
if tip.SetSpellBookItem and GetSpellBookItemInfo then hooksecurefunc(tip,"SetSpellBookItem",function(self,index,book) local _,id=GetSpellBookItemInfo(index,book);refresh(self,id) end) end
if tip.SetAction and GetActionInfo then hooksecurefunc(tip,"SetAction",function(self,slot) local kind,id=GetActionInfo(slot);if kind=="spell" then refresh(self,id) end end) end
return {refresh=refresh,receive=receive,invalidate=invalidate,allowed=allowed}
