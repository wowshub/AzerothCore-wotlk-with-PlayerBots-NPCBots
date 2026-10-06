-- WD114B: read-only, self-only server calculation. Never computes cost from a draft.
local tip=GameTooltip
local allowed,power={},{}
local function range(a,b) for id=a,b do allowed[id]=true end end
range(9003140,9003143);range(9003180,9003185)
for _,id in ipairs({9003190,9003280,9003290,9003300,9003150,9003200,9003210,9003762,9003240,9003101}) do allowed[id]=true end
range(9003220,9003225);range(9003130,9003138)
for id=9003180,9003185 do power[id]=true end;power[9003300]=true
range(9003922,9003928);range(9003460,9003467);allowed[9003865]=true;range(9003870,9003876);range(9003890,9003896);allowed[9003861]=true;allowed[9003859]=true;allowed[9003855]=true;allowed[9003432]=true
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
-- WD119B: replace only this pair's base-value description, using server values.
local function walkerDescription(id,value)
 local lead=value and '当前效果 / Current effect: ' or '当前效果同步中 / Syncing current effect. '
 if id==9003855 then
  if not value then return lead..'持续时间、减伤与每秒治疗等待服务器确认。' end
  return string.format('持续%.1f秒，受到伤害降低%d%%，基础每秒恢复最大生命的%.2f%%。 / Lasts %.1f sec; damage taken -%d%%; base healing %.2f%% max health/sec.',value.a/1000,value.b,(value.c or 200)/100,value.a/1000,value.b,(value.c or 200)/100)
 end
 local limits='30码内视线可达的自己与队伍成员；与其他神像共用一个名额，守卫、神像和雕像名额彼此独立。 / Affects self and party in line of sight within 30 yd; shares the idol limit, separate from wards and effigies.'
 if not value then return lead..limits end
 return string.format('放置神像，持续%.1f秒，移动速度与抵抗定身/减速的几率提高%d%%。 / Summon an idol for %.1f sec; movement speed and root/snare resistance +%d%%. ',value.a/1000,value.b,value.a/1000,value.b)..limits
end
local function draw(self,forced)
 if not doctor() then return end
 local _,second,third=self:GetSpell()
 local id=tonumber(forced) or tonumber(third) or tonumber(second) or self.wd114Spell
 if not allowed[id] then return end
 if self.wd114Spell~=id then self.wd114Lines=nil;self.wd114EffectLine=nil end
 self.wd114Spell=id
 local changed=false
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
    -- Native tooltip setters can rebuild the same FontString without clearing it.
    local record=self.wd114Lines[key]
    local original=(record and text==record.rendered) and record.original or text
    local clean=plain(original)
    if (id==9003855 or id==9003432) and side=="Left" and (clean:find("基础（未计灵魂行者）",1,true) or clean:find("基础 (未计灵魂行者)",1,true) or clean:find("Base values; current values shown below.",1,true) or clean:find("Base values: current values shown below.",1,true)) then
     local rendered=walkerDescription(id,value)
     self.wd114Lines[key]={original=original,rendered=rendered}
     if text~=rendered then font:SetText(rendered);changed=true end
    elseif clean:match("^%s*%d[%d,%. ]*%s*法力值%s*$") or clean:match("^%s*%d[%d,%. ]*%s*[Mm]ana%s*$") then
     local rendered=value and (tostring(value.cost)..(en and " Mana" or "法力值")) or (original..(en and " (syncing)" or "（同步中）"))
     self.wd114Lines[key]={original=original,rendered=rendered}
     if text~=rendered then font:SetText(rendered);changed=true end
    elseif id==9003861 and (clean:match("秒施法时间$") or clean:match("秒施放时间$") or clean:match("秒施法$") or clean:match("秒施放$") or clean:match("sec cast$") or clean=="瞬发法术" or clean=="瞬发" or clean=="Instant") then
     local rendered=value and (value.a==0 and (en and "Instant" or "瞬发法术") or string.format(en and "%.2f sec cast" or "%.2f秒施法",value.a/1000)) or (original..(en and " (syncing)" or "（同步中）"))
     self.wd114Lines[key]={original=original,rendered=rendered};if text~=rendered then font:SetText(rendered);changed=true end
    elseif (id>=9003870 and id<=9003876 or id>=9003890 and id<=9003896) and (clean:find("15秒冷却",1,true) or clean:find("15 sec cooldown",1,true) or clean:find("15 sec Cooldown",1,true)) then
     -- WD127F: native cooldown headings are Right FontStrings; descriptions are Left.
     -- Always rebuild from original text, including when a saved build is changed.
     local seconds=value and value.e and value.e/1000
     local rendered=seconds and clean:gsub("15秒冷却",string.format("%g秒冷却",seconds)):gsub("15 sec cooldown",string.format("%g sec cooldown",seconds)):gsub("15 sec Cooldown",string.format("%g sec Cooldown",seconds)) or (original..(en and " (syncing)" or "（同步中）"))
     self.wd114Lines[key]={original=original,rendered=rendered};if text~=rendered then font:SetText(rendered);changed=true end
    elseif id==9003861 and (clean:match("秒冷却时间$") or clean:match("分钟冷却时间$") or clean:match("sec cooldown$") or clean:match("min cooldown$")) then
     local rendered=value and string.format(en and "%g sec cooldown" or "%g秒冷却时间",value.b/1000) or (original..(en and " (syncing)" or "（同步中）"))
     self.wd114Lines[key]={original=original,rendered=rendered};if text~=rendered then font:SetText(rendered);changed=true end
    else
     self.wd114Lines[key]=nil
    end
   end
  end
 end
 if id==9003865 or (id>=9003870 and id<=9003876) or (id>=9003890 and id<=9003896) or id==9003861 or power[id] or id==9003240 or id==9003855 or id==9003432 then
  local text
  if value then
   if id>=9003890 and id<=9003896 then
    text=string.format("当前直接治疗 / Direct heal: %d–%d；蘑菇 / Shrooms: %d / 3秒，持续%g秒 / sec；冷却%g秒 / cooldown %g sec",value.a,value.b,value.c or 0,(value.d or 12000)/1000,(value.e or 15000)/1000,(value.e or 15000)/1000)
   elseif id==9003865 or (id>=9003870 and id<=9003876) then
    local label=id==9003865 and string.format("当前每%g秒，最多%d人 / Pulse every %g sec, up to %d allies: ",(value.c or 6000)/1000,value.d or 8,(value.c or 6000)/1000,value.d or 8) or "直接治疗 / Direct heal: "
    text=label..value.a.."–"..value.b..(id==9003865 and "" or (value.e and string.format("；冷却%g秒 / cooldown %g sec",value.e/1000,value.e/1000) or "；冷却同步中 / cooldown syncing")).."（含自身加成；未计目标增减益及暴击 / self bonuses, before target modifiers and crit）"
   elseif id==9003861 then
    text=en and string.format("Current: %.2f sec cast; %g sec cooldown",value.a/1000,value.b/1000) or string.format("当前：施法%.2f秒；冷却%g秒",value.a/1000,value.b/1000)
   elseif id==9003855 then
    text=en and string.format("Current duration: %.1f sec; damage taken -%d%%; base healing %.2f%% max health/sec",value.a/1000,value.b,(value.c or 200)/100) or string.format("当前持续时间：%.1f秒；减伤%d%%；基础每秒恢复%.2f%%最大生命",value.a/1000,value.b,(value.c or 200)/100)
   elseif id==9003432 then
    text=en and string.format("Current duration: %.1f sec; speed and root/snare resistance +%d%%",value.a/1000,value.b) or string.format("当前持续时间：%.1f秒；移速、抵抗定身/减速提高%d%%",value.a/1000,value.b)
   elseif power[id] then text=en and ("Current melee / ranged attack power: +"..value.a.." / +"..value.b) or ("当前近战／远程攻击强度：+"..value.a.."／+"..value.b)
   else text=en and ("Curse removal attempts: "..value.a) or ("可尝试移除诅咒数量："..value.a) end
  else text=en and "Current effect: syncing" or "当前效果：同步中" end
  if not self.wd114EffectLine then
   self:AddLine(text,.3,1,.3,true);self.wd114EffectLine=self:NumLines();changed=true
  else
   local font=_G[self:GetName().."TextLeft"..self.wd114EffectLine];if font and font:GetText()~=text then font:SetText(text);changed=true end
  end
 end
 if changed and self.Show and self:IsShown() then self:Show() end
end
local function refresh(self,forced)
 -- Show() and other tooltip hooks may synchronously request another refresh.
 if self.wd114Drawing then return end
 self.wd114Drawing=true
 draw(self,forced)
 self.wd114Drawing=nil
end
local function receive(message)
 local n,id,status,rest=message:match("^WD114|(%d+)|(%d+)|([^|]+)|?(.*)$")
 n,id=tonumber(n),tonumber(id)
 if not n or not pending or n~=pending.seq or id~=pending.id or pending.epoch~=epoch then return end
 pending=nil
 if status~="ok" then failed();return end
 local cost,a,b,rev,active,c,d,e=rest:match("^(%d+)|([%-]?%d+)|([%-]?%d+)|(%d+)|(%d+)|(%d+)|(%d+)|(%d+)$")
 if not cost then cost,a,b,rev,active,c,d=rest:match("^(%d+)|([%-]?%d+)|([%-]?%d+)|(%d+)|(%d+)|(%d+)|(%d+)$") end
 if not cost then cost,a,b,rev,active,c=rest:match("^(%d+)|([%-]?%d+)|([%-]?%d+)|(%d+)|(%d+)|(%d+)$") end
 if not cost then cost,a,b,rev,active=rest:match("^(%d+)|([%-]?%d+)|([%-]?%d+)|(%d+)|(%d+)$") end
 if not cost then return end
 local state=RebornWD8
 if state and state.loaded and (state.pending or tonumber(rev)~=state.revision or tonumber(active)~=state.active) then return end
 failures=0
 cache[id]={e=tonumber(e),d=tonumber(d),c=tonumber(c),cost=tonumber(cost),a=tonumber(a),b=tonumber(b),rev=tonumber(rev),active=tonumber(active),time=GetTime()}
 if tip:IsShown() and tip.wd114Spell==id then refresh(tip) end
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
