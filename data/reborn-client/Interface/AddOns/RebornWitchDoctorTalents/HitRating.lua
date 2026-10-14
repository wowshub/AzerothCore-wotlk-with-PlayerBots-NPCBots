-- WD145B: server-owned percentage bonuses; preserve the native rating number.
local driver=CreateFrame("Frame")
local tracked={}
local cache,pending=nil,nil
local seq,nextSend,elapsed=0,0,0
local en=GetLocale()~="zhCN" and GetLocale()~="zhTW"
local function doctor() local _,token,id=UnitClass("player");return token=="WITCHDOCTOR" or id==13 end
local function clear()
 cache=nil;pending=nil
end
local function draw(frame,index)
 if not doctor() or (index~=CR_HIT_MELEE and index~=CR_HIT_RANGED and index~=CR_HIT_SPELL) then return end
 local rec=tracked[frame] or {};tracked[frame]=rec;rec.index=index
 local name=frame:GetName();local font=name and _G[name.."StatText"]
 if not font then return end
 local text=font:GetText() or "";local tip=frame.tooltip2 or ""
 if text~=rec.rendered then rec.original=text end
 if tip~=rec.renderedTip then rec.originalTip=tip end
 local value=cache and GetTime()-cache.time<3 and cache or nil
 if RebornWD8 and RebornWD8.pending then value=nil end
 local bonus=value and (index==CR_HIT_SPELL and value.spell or value.physical) or 0
 local suffix=bonus~=0 and string.format(" |cff20ff20(%+g%%)|r",bonus) or ""
 rec.rendered=(rec.original or text)..suffix
 local note
 if value then
  note=en and string.format("\n\nVillage Wisdom: %+g percentage points to hit (server aura).\nThe number above is hit rating; this talent does not add rating.\nAll server hit-chance auras: physical %+g, spell %+g percentage points. This is not the final hit chance against a target.",bonus,value.totalPhysical,value.totalSpell)
   or string.format("\n\n村落智慧：额外%+g个百分点命中（服务器光环）。\n上面的原数值是命中等级，本天赋不增加等级。\n服务器所有命中光环合计：物理%+g、法术%+g个百分点；不是对某个敌人的最终命中率。",bonus,value.totalPhysical,value.totalSpell)
 else note=en and "\n\nVillage Wisdom hit bonus: waiting for server confirmation." or "\n\n村落智慧命中加成：等待服务器确认。" end
 rec.renderedTip=(rec.originalTip or tip)..note
 font:SetText(rec.rendered);frame.tooltip2=rec.renderedTip
end
local function redraw() for f,r in pairs(tracked) do draw(f,r.index) end end
local function receive(msg)
 local n,p,s,tp,ts,learned=msg:match("^WD145H|(%d+)|([%-]?%d+)|([%-]?%d+)|([%-]?%d+)|([%-]?%d+)|([01])$")
 if not pending or tonumber(n)~=pending or not doctor() then return end
 pending=nil;cache={physical=tonumber(p),spell=tonumber(s),totalPhysical=tonumber(tp),totalSpell=tonumber(ts),time=GetTime()};redraw()
end
local function install()
 if not driver.installed and type(PaperDollFrame_SetRating)=="function" then
  hooksecurefunc("PaperDollFrame_SetRating",draw);driver.installed=true
 end
end
driver:SetScript("OnEvent",function(_,event,arg)
 if event=="CHAT_MSG_SYSTEM" then if type(arg)=="string" then receive(arg);if arg:match("^WD139") or arg:match("^WD16|") then clear();redraw() end end
 elseif event=="UNIT_AURA" then if arg=="player" then clear();redraw() end
 else install();clear();redraw() end
end)
for _,event in ipairs({"PLAYER_LOGIN","ADDON_LOADED","PLAYER_ENTERING_WORLD","UNIT_AURA","CHAT_MSG_SYSTEM"})do driver:RegisterEvent(event)end
driver:SetScript("OnUpdate",function(_,dt)
 elapsed=elapsed+dt;if elapsed<.25 then return end;elapsed=0
 if not doctor() then return end
 local visible=false;for f in pairs(tracked)do if f:IsShown() then visible=true;break end end
 if not visible then return end
 redraw()
 if GetTime()>=nextSend then seq=seq+1;pending=seq;nextSend=GetTime()+1.5;SendChatMessage(".wd145hit "..seq,"SAY") end
end)
ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM",function(_,_,msg)return type(msg)=="string" and msg:match("^WD145H|")~=nil end)
install()
return {draw=draw,receive=receive,clear=clear,driver=driver}
