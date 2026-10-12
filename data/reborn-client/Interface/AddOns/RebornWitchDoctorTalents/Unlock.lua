-- WD141: server-quoted saved-build purchases; NPC uses the same transaction.
local M=RebornWD8
local U={serial=0};RebornWDUnlock=U
local function Tell(zh,en)
 M.message=RebornWDLanguage=="en" and en or zh
 if M.changed then M.changed() end
end
local errors={
 disabled={"服务器尚未开启此方案购买，请联系管理员开启配置。","This build purchase is disabled in server configuration."},
 slot={"请按顺序解锁；第4至10方案尚未开放。","Unlock builds in order; builds 4–10 are unavailable."},
 refresh={"方案状态已变化，请刷新后重试。","Build state changed; refresh and try again."},
 expired={"报价已过期或已使用，请重新点击获取价格。","Quote expired or already used; request a new price."},
 unavailable={"暂时无法购买，请刷新状态并检查服务端。","Purchase unavailable; refresh and check the server."},
 failed={"未完成购买，请查看聊天提示，刷新后重试。","Purchase not completed; check chat, refresh and retry."},
 verify={"交易结果需要核对，请刷新或重登；不要重复购买。","Verify the purchase by refreshing or relogging before retrying."}}
local function Ready()
 if U.pending or M.pending then return false end
 if not M.loaded or not M.layoutReady then Tell("请先刷新服务器状态。","Refresh the server state first.");return false end
 if M.HasDrafts() then Tell("请先保存或撤销草稿再购买方案。","Save or discard your draft before purchasing.");return false end
 local v=RebornEquipmentVault and RebornEquipmentVault.server
 if v and v.IsBusy and v.IsBusy() then Tell("请等待衣柜操作完成。","Wait for the wardrobe operation.");return false end
 if InCombatLockdown() or UnitIsDeadOrGhost("player") then Tell("请在存活且脱战时购买。","Purchase while alive and out of combat.");return false end
 return true
end
local function Send(kind,slot,args)
 U.serial=U.serial+1;U.pending={id=U.serial,kind=kind,slot=slot,revision=M.revision,time=GetTime()}
 SendChatMessage(".wd141"..kind.." "..U.serial.." "..args,"SAY")
 Tell("等待服务器确认…","Waiting for server confirmation…")
end
function U.Quote(slot)
 if not Ready() then return false end
 if slot<1 or slot>2 or slot~=M.unlocked then Tell(errors.slot[1],errors.slot[2]);return false end
 U.quote=nil
 Send("quote",slot,M.revision.." "..slot);return true
end
function U.Confirm(q)
 if not q or U.quote~=q or not Ready() then return false end
 U.quote=nil
 if GetTime()-q.time>55 or q.revision~=M.revision or q.slot~=M.unlocked then Tell(errors.expired[1],errors.expired[2]);return false end
 if M.level<q.level then Tell("等级不足，需要"..q.level.."级。","Requires level "..q.level..".");return false end
 if GetMoney()<q.gold*10000 then Tell("金币不足，需要"..q.gold.."金币。","Requires "..q.gold.." gold.");return false end
 Send("buy",q.slot,q.token.." "..q.revision.." "..q.slot);return true
end
function U.Receive(msg)
 if type(msg)~="string" then return end
 local p=U.pending;if not p then return end
 local seq,code=msg:match("^WD141|(%d+)|error|([a-z]+)$")
 if seq and tonumber(seq)==p.id then
  U.pending=nil;U.quote=nil;local text=errors[code]or errors.failed;Tell(text[1],text[2]);return
 end
 local seq,rev,slot,token,level,gold=msg:match("^WD141|(%d+)|quote|(%d+)|(%d+)|(%d+)|(%d+)|(%d+)$")
 if seq and p.kind=="quote" and tonumber(seq)==p.id then
  rev,slot,token,level,gold=tonumber(rev),tonumber(slot),tonumber(token),tonumber(level),tonumber(gold)
  if rev~=p.revision or rev~=M.revision or slot~=p.slot or slot~=M.unlocked or token<1 or token>4294967295 or level<1 or level>80 or gold>200000 then return end
  U.pending=nil
  if not Ready() then return end
  if M.level<level then Tell("解锁需要"..level.."级、"..gold.."金币；当前等级不足。","Unlock requires level "..level.." and "..gold.." gold; level too low.");return end
  if GetMoney()<gold*10000 then Tell("解锁价格："..gold.."金币，当前金币不足。","Unlock price: "..gold.." gold; insufficient funds.");return end
  local q={revision=rev,slot=slot,token=token,level=level,gold=gold,time=GetTime()};U.quote=q
  local en=RebornWDLanguage=="en";local d=StaticPopupDialogs.REBORN_WD141_UNLOCK
  d.text=en and("Permanently unlock build "..(slot+1).." for "..gold.." gold?\nRequires level "..level..". One-time purchase; switching is free.\nExisting builds will not be reset or activated.")or("花费"..gold.."金币永久解锁方案"..(slot+1).."？\n需要"..level.."级，一次购买，之后切换免费。\n不会重置或切换现有方案。")
  d.button1=en and"Purchase"or"确认购买";d.button2=en and"Cancel"or"取消"
  StaticPopup_Show("REBORN_WD141_UNLOCK",nil,nil,q);return
 end
 local seq,slot=msg:match("^WD141|(%d+)|ok|(%d+)$")
 if seq and p.kind=="buy" and tonumber(seq)==p.id and tonumber(slot)==p.slot then
  U.pending=nil;U.quote=nil;M.Query()
  DEFAULT_CHAT_FRAME:AddMessage(RebornWDLanguage=="en" and"Build unlocked. Refreshing the list; select the new build to choose its specialization."or"方案已解锁，正在刷新列表；请选择新方案再设置专精。")
 end
end
StaticPopupDialogs.REBORN_WD141_UNLOCK={text="",button1="确认购买",button2="取消",timeout=55,whileDead=false,hideOnEscape=true,
 OnAccept=function(_,data)U.Confirm(data)end,
 OnCancel=function(_,data)if U.quote==data then U.quote=nil end end}
-- A purchase reply must not overwrite a concurrently edited draft.
for _,name in ipairs({"CanEdit","SelectSlot","SetSpec","Bind","Activate","Save","QuoteReset","ConfirmReset","Query"}) do
 local original=M[name]
 if original then M[name]=function(...)if U.pending then return false end;return original(...)end end
end
local f=CreateFrame("Frame");U.listener=f;f:RegisterEvent("CHAT_MSG_SYSTEM")
f:SetScript("OnEvent",function(_,_,msg)U.Receive(msg)end)
f:SetScript("OnUpdate",function()
 if U.pending and GetTime()-U.pending.time>8 then
  local bought=U.pending.kind=="buy";U.pending=nil;U.quote=nil
  if bought then Tell("购买回包超时，请先刷新或重登核对是否解锁，勿直接重复购买。","Purchase reply timed out; refresh or relog to verify ownership before retrying.")
  else Tell("报价请求超时，请确认已安装WD141服务端后重试。","Quote request timed out; verify the WD141 server is installed.")end
 end
end)
if ChatFrame_AddMessageEventFilter then ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM",function(_,_,msg)return type(msg)=="string"and msg:match("^WD141|")~=nil end)end
