-- WD8: drafts are local; only a matching server response confirms a save/activation.
local M={unlocked=0,loaded=false,pending=false,revision=0,active=0,builds=0,level=0,specs={3,3,3},slot=0,draftSpec=0,draftRank=0,dirty=false,message="等待服务器确认"}
RebornWD8=M
M.keys={[0]="Voodoo",[1]="Brewing",[2]="Shadowhunting"}
M.ids={Voodoo=0,Brewing=1,Shadowhunting=2}
local function Changed() if M.changed then M.changed() end; if M.homeChanged then M.homeChanged() end end
local function Message(zh,en) RebornWDRegisterTranslation(zh,en);M.message=zh;Changed() end
function M.TotalPoints() return M.loaded and (M.totalPoints or math.max(0,math.min(80,M.level)-9)) or nil end
function M.SavedRank(slot) return math.floor(M.builds/2^slot)%2 end
function M.TreeRank(slot,spec)
 return spec==0 and M.specs[slot+1]==0 and (M.SavedRank(slot)+2*(math.floor(M.builds/2^(slot+3))%2)) or 0
end
function M.PointsUsed(mask) return mask%2+math.floor(mask/2)%2 end
function M.CanEdit() return M.loaded and M.slot<M.unlocked and M.specs[M.slot+1]==M.draftSpec end
function M.TotalSpent()
 local bound=M.specs[M.slot+1]
 return M.PointsUsed(bound==M.draftSpec and M.draftRank or M.TreeRank(M.slot,bound))
end
function M.NodeRank(id,mask)
 mask=mask or M.draftRank
 return id==6058 and mask%2 or (id==29928 and math.floor(mask/2)%2 or 0)
end
function M.SetNode(id,rank)
 local weight=id==6058 and 1 or (id==29928 and 2 or nil)
 if not weight then return end
 M.SetRank(M.draftRank+(rank-M.NodeRank(id))*weight)
end
function M.HasDrafts()
 for spec,rank in pairs(M.specDrafts or {}) do if rank~=M.TreeRank(M.slot,spec) then return true end end
 return M.dirty
end
function M.ResetDraft(slot,view)
 M.specDrafts={};M.slot=slot;M.draftSpec=view or (M.specs[slot+1]<3 and M.specs[slot+1] or 0)
 M.draftRank=M.TreeRank(slot,M.draftSpec);M.dirty=false;Changed()
end
function M.SetSpec(key)
 if M.pending and M.operation~="query" then return false end
 local spec=M.ids[key];if spec==nil then return false end
 if not M.loaded then M.requestedSpec=spec end
 -- Keep one draft per viewed specialization. Browsing is never a rank removal.
 M.specDrafts=M.specDrafts or {}
 M.specDrafts[M.draftSpec]=M.draftRank
 M.draftSpec=spec
 local remembered=M.specDrafts[spec]
 if remembered~=nil then M.draftRank=remembered
 elseif spec==0 then M.draftRank=M.TreeRank(M.slot,0)
 else M.draftRank=0 end
 M.dirty=M.loaded and M.draftRank~=M.TreeRank(M.slot,M.draftSpec)
 Changed();return true
end
function M.SetRank(rank)
 if not M.loaded then Message("未连接新版服务端：请检查WD8源码编译及配置，再刷新","Server not synchronized: check WD8 build/configuration, then refresh");return end
 if M.pending or M.draftSpec~=0 then return end
 if not M.CanEdit() then Message("此页只能浏览，请先选择未绑定方案的专精","Preview only: choose a specialization for an unbound build first");return end
 if type(rank)~="number" or rank<0 or rank>3 or rank~=math.floor(rank) then return end
 local saved=M.TreeRank(M.slot,M.draftSpec)
 if (saved%2==1 and rank%2==0) or (math.floor(saved/2)%2==1 and math.floor(rank/2)%2==0) then Message("已保存点数需要付费重置整个方案","Saved points require a paid full build reset");return end
 if M.PointsUsed(rank)>(M.TotalPoints() or 0) then Message("可用天赋点不足","Not enough talent points");return end
 if M.NodeRank(29928,rank)==1 and M.level<15 then Message("邪恶巫术需要15级","Bad Juju requires level 15");return end
 if rank>0 and M.level<10 then Message("10级开放此天赋","This talent unlocks at level 10");return end
 M.message="草稿已更改，请点击保存更改"
 M.draftRank=rank;M.specDrafts=M.specDrafts or {};M.specDrafts[M.draftSpec]=rank;M.dirty=rank~=M.TreeRank(M.slot,M.draftSpec);Changed()
end
local function WardrobeBusy()
 local v=RebornEquipmentVault and RebornEquipmentVault.server
 return v and v.IsBusy and v.IsBusy()
end
local function Request(command,operation)
 if operation~="query" and WardrobeBusy()then Message("衣柜正在处理装备，请完成后再切换或修改天赋","Wardrobe is busy; finish it before changing talents");return end
 if M.pending then return end
 M.pending=true;M.operation=operation;M.expected=M.revision;M.requestSlot=M.slot;M.requestSpec=M.draftSpec;M.sent=GetTime()
 M.message="等待服务器确认…";Changed();SendChatMessage(command,"SAY")
end
M.Request=Request
function M.Query() Request(".wd16state","query") end
function M.Save()
 if not M.CanEdit() or not M.dirty or M.pending then return end
 Request(".wd16save "..M.revision.." "..M.slot.." "..M.draftSpec.." "..M.draftRank,"save")
end
function M.SelectSlot(slot)
 if M.pending or not M.loaded or slot<0 or slot>=M.unlocked then return end
 if M.HasDrafts() then Message("请先保存更改或撤销草稿","Save changes or discard the draft first");return end
 M.ResetDraft(slot);if M.navigate then M.navigate(M.keys[M.draftSpec]) end
end
function M.Activate()
 if not M.loaded or M.pending or M.slot>=M.unlocked or M.slot==M.active then return end
 if InCombatLockdown() then Message("请脱战后切换方案","Leave combat before switching builds");return end
 if M.specs[M.slot+1]==3 then Message("请先为此方案选择专精","Choose this build's specialization first");return end
 if M.HasDrafts() then Message("请先保存更改再激活","Save changes before activating");return end
 Request(".wd16activate "..M.revision.." "..M.slot,"activate")
end
function M.Bind()
 if not M.loaded or M.pending or M.slot>=M.unlocked or M.specs[M.slot+1]~=3 then return end
 if M.level<10 then Message("10级开放专精选择","Choose a specialization at level 10");return end
 if InCombatLockdown() then return end
 Request(".wd16bind "..M.revision.." "..M.slot.." "..M.draftSpec,"bind")
end
-- Price comes from the server configuration, never a hard-coded client fee.
local function EnoughResetMoney(gold)
 if gold==nil or GetMoney()>=gold*10000 then return true end
 Message("金币不足：重置需要"..gold.."金币，当前仅有"..GetMoney().."铜币；未扣费，方案不变。",
  "Not enough money: reset costs "..gold.." gold; you have "..GetMoney().." copper. No charge; build unchanged.")
 return false
end
function M.QuoteReset()
 if not M.loaded or M.pending or M.slot>=M.unlocked or M.specs[M.slot+1]==3 then return end
 if not EnoughResetMoney(M.resetGold) then return end
 if InCombatLockdown() then Message("请脱战后重置方案","Leave combat before resetting a build");return end
 Request(".wd16quote "..M.revision.." "..M.slot,"quote")
end
function M.ConfirmReset(q)
 if not q or M.pending or not M.loaded or M.slot~=q.slot or M.revision~=q.rev then return end
 if not EnoughResetMoney(q.gold) then return end
 if InCombatLockdown() then Message("请脱战后重置方案","Leave combat before resetting a build");return end
 Request(".wd16reset "..q.rev.." "..q.slot.." "..q.gold,"reset")
end
local function Links()
 RebornWD8Equipment=RebornWD8Equipment or {}
 local key=(GetRealmName() or "")..":"..(UnitGUID("player") or UnitName("player"))
 RebornWD8Equipment[key]=RebornWD8Equipment[key] or {};return RebornWD8Equipment[key]
end
function M.Link(name) if not M.pending then Links()[M.slot+1]=name;Changed() end end
function M.Linked(slot) return Links()[(slot or M.slot)+1] end
function M.Equip(slot)
 if WardrobeBusy()then return end
 local name=M.Linked(slot);if not name then return end
 if InCombatLockdown() then Message("战斗中不换装，请脱战后点击穿戴","Leave combat, then click Equip");return end
 if not GetEquipmentSetInfoByName or not GetEquipmentSetInfoByName(name) then Message("关联装备套装不存在，请重新关联","Linked equipment set is missing; link it again");return end
 local ok=pcall(function()
  if EquipmentManager_EquipSet then EquipmentManager_EquipSet(name) else UseEquipmentSet(name) end
 end)
 Message(ok and "已请求换装，请检查缺失物品及装备栏" or "换装失败，请用装备管理器检查",ok and "Equip requested; check missing items and equipment slots" or "Equip failed; check the equipment manager")
end
function M.SaveEquipment()
 if M.pending or InCombatLockdown() then return end
 local slot=M.slot;local name="WD8-"..(slot+1)
 local function Save()
  if InCombatLockdown() then return end
  if RefreshEquipmentSetIconInfo then RefreshEquipmentSetIconInfo() end
  if EquipmentManagerClearIgnoredSlotsForSave then EquipmentManagerClearIgnoredSlotsForSave() end
  -- Link only after the native list actually confirms creation, not merely after the API call.
  M.gearPending={slot=slot,name=name,time=GetTime()}
  SaveEquipmentSet(name,1)
  Message("已请求保存当前装备，等待装备列表确认","Equipment save requested; waiting for list confirmation")
 end
 if GetEquipmentSetInfoByName(name) then
  StaticPopupDialogs.REBORN_WD8_OVERWRITE={text=RebornWDLanguage=="en" and "Replace the existing WD8 equipment set with your current gear?" or "用当前身上装备覆盖已有WD8装备套装？",button1=YES,button2=NO,OnAccept=Save,timeout=0,whileDead=false,hideOnEscape=true}
  StaticPopup_Show("REBORN_WD8_OVERWRITE")
 elseif GetNumEquipmentSets()>=10 then Message("装备套装已满，请先在装备管理器清理","Equipment sets are full; manage them first")
 else Save() end
end
local f=CreateFrame("Frame");M.listener=f
f:RegisterEvent("CHAT_MSG_SYSTEM");f:RegisterEvent("EQUIPMENT_SETS_CHANGED")
f:SetScript("OnEvent",function(_,event,msg)
 if event=="EQUIPMENT_SETS_CHANGED" then
  local pending=M.gearPending
  if pending and GetEquipmentSetInfoByName(pending.name) then Links()[pending.slot+1]=pending.name;M.gearPending=nil;Message("装备列表已确认套装，请正常退出以保存","Equipment list confirmed; log out normally to save") end
  return
 end
 if type(msg)~="string" then return end
 local price=msg:match("^WD16P|(%d+)$")
 if price then price=tonumber(price);if price<=200000 then M.resetGold=price end;return end
 if msg=="WD16P|invalid" then M.resetGold=nil;return end
 local qr,qs,qg=msg:match("^WD16Q|(%d+)|(%d+)|(%d+)$")
 if qr then
  qr,qs,qg=tonumber(qr),tonumber(qs),tonumber(qg)
  if not M.pending or M.operation~="quote" or qr~=M.expected or qs~=M.requestSlot or qg>200000 then return end
  M.pending=false;M.operation=nil;M.message="请选择是否付费重置";Changed()
  M.resetGold=qg
  if not EnoughResetMoney(qg) then return end
  local quote={rev=qr,slot=qs,gold=qg}
  local text=RebornWDLanguage=="en" and ("Pay "..qg.." gold to reset build "..(qs+1).."? All its saved talents and specialization will be cleared. Other builds and equipment are kept.") or ("支付"..qg.."金币重置方案"..(qs+1).."？清空本方案全部已保存天赋与专精选择。其他方案及装备不受影响。")
  StaticPopupDialogs.REBORN_WD16_RESET={text=text,button1=YES,button2=NO,timeout=60,whileDead=false,hideOnEscape=true,OnAccept=function() M.ConfirmReset(quote) end}
  StaticPopup_Show("REBORN_WD16_RESET");return
 end

 local baseMessage,modern,a0,a1,a2,ae,te=msg:match("^(WD16|.+)|([01])|(%d+)|(%d+)|(%d+)|(%d+)|(%d+)$")
 if baseMessage then msg=baseMessage end
 local core,points,unlocked=msg:match("^(WD16|[a-z]+|%d+|%d+|%d+|%d+|%d+|%d+|%d+|[01])|(%d+)|([0-3])$")
 if not core then return end
 if core then msg=core end
 local status,revision,active,builds,s0,s1,s2,level,loaded=msg:match("^WD16|([a-z]+)|(%d+)|(%d+)|(%d+)|(%d+)|(%d+)|(%d+)|(%d+)|([01])$")
 if not status then return end
 revision,active,builds,s0,s1,s2,level=tonumber(revision),tonumber(active),tonumber(builds),tonumber(s0),tonumber(s1),tonumber(s2),tonumber(level)
 if revision<M.revision or revision>2000000000 or active>2 or builds>63 or s0>3 or s1>3 or s2>3 or level>255 then return end
 if points and tonumber(points)~=math.max(0,math.min(80,level)-9) then return end
 if modern then
  a0,a1,a2,ae,te=M.MaskParse(a0),M.MaskParse(a1),M.MaskParse(a2),tonumber(ae),tonumber(te)
  if not M.MaskFits(a0,114) or not M.MaskFits(a1,114) or not M.MaskFits(a2,114) or ae>255 or te>255 then return end
  M.modern=modern=="1";M.aeMasks={a0,a1,a2};M.aeBudget=ae;M.teBudget=te
 end
 M.unlocked=tonumber(unlocked)
 if loaded=="1" and active>=M.unlocked then return end
 M.totalPoints=points and tonumber(points) or nil
 local operation,requestSlot,expected=M.operation,M.requestSlot,M.expected
 M.pending=false;M.operation=nil;M.revision=revision;M.active=active;M.builds=builds;M.specs={s0,s1,s2};M.level=level
 local recoverable={money=true,busy=true,combat=true,dead=true,casting=true,transport=true,quoteexpired=true}
 M.loaded=loaded=="1" and (status=="ok" or recoverable[status]==true)
 local confirmed=M.loaded and status=="ok" and ((operation=="save" or operation=="activate" or operation=="bind" or operation=="reset" or operation=="join") and revision==expected+1)
 if confirmed and operation=="save" then
  M.specDrafts=M.specDrafts or {};M.specDrafts[M.requestSpec]=M.TreeRank(requestSlot,M.requestSpec)
  M.draftRank=M.specDrafts[M.draftSpec] or M.TreeRank(M.slot,M.draftSpec)
  M.dirty=M.draftRank~=M.TreeRank(M.slot,M.draftSpec)
 elseif confirmed then M.ResetDraft(requestSlot,M.draftSpec)
  if operation=="reset" and RebornWDTreePreviewAPI then RebornWDTreePreviewAPI.ShowHome() end
 elseif status=="ok" and M.loaded and not M.HasDrafts() then M.ResetDraft(M.slot,M.draftSpec) end
 if M.loaded and M.requestedSpec~=nil then
  local requested=M.requestedSpec;M.requestedSpec=nil;M.SetSpec(M.keys[requested])
 end
 if M.AEOnReply then M.AEOnReply(operation,confirmed) end
 if status~="ok" or not M.loaded then
  local errors={
   freshonly={"请用新建巫医测试本批分支","Use a newly created Witch Doctor for this branch"},
   bound={"方案专精已绑定，其他专精只能浏览；更改需要付费重置","Build is bound; other specs are preview-only. Pay to reset before changing"},
   unbound={"请先为此方案选择专精","Choose this build's specialization first"},
   resetrequired={"已保存点数需要付费重置整个方案","Saved points require a paid full build reset"},
   quoteexpired={"报价已失效，请重新点击付费重置","Quote expired; request a new paid reset"},
   money={"金币不足：重置需要"..(M.resetGold or "待查询").."金币；未扣费，方案不变。","Not enough gold: reset costs "..(M.resetGold or "unknown").." gold. No charge; build unchanged."},
   busy={"操作过快，请稍候再试；本次未执行。","Too many requests; try again shortly. No change made."},
   combat={"战斗中不能修改方案，请脱战后再试。","Cannot change builds in combat."},
   dead={"死亡状态不能修改方案，请复活后再试。","Resurrect before changing builds."},
   casting={"正在施法，请施法结束后再试。","Finish casting before changing builds."},
   transport={"飞行、载具或运输途中不能修改方案。","Leave flight, vehicle or transport before changing builds."},
   spell={"服务端缺少必需的技能数据，请检查本包安装。","Required server spell data is missing; check installation."},
   locked={"此方案尚未解锁，请向巫医导师购买","This build is locked; visit the Witch Doctor trainer"},
   disabled={"服务端未启用WD8","WD8 is disabled on the server"},
   invalid={"服务器拒绝保存：请检查等级、点数与WD16服务端/SQL版本；草稿已保留","Save rejected: check level, points and WD16 server/SQL; draft retained"},
   database={"存档读取或写入失败：请检查WD16角色库过程；草稿已保留","Database request failed: check WD16 procedure; draft retained"},
   stale={"方案版本已变化，请刷新后核对草稿再保存","Build revision changed; refresh and review the draft before saving"},
   blocked={"请求未执行，具体原因未返回；请刷新后重试，草稿已保留","Request not executed; reason unavailable. Refresh and retry; draft retained"}
  }
  local e=errors[status] or {"操作未确认，请保留草稿并刷新","Operation unconfirmed; keep draft and refresh"}
  Message(e[1],e[2])
 else Message("已与服务器同步","Synchronized with server") end
 if confirmed and operation=="activate" and active==requestSlot then
   local v=RebornEquipmentVault and RebornEquipmentVault.server
   if not(v and v.OnTalentActivated and v.OnTalentActivated(active,revision))then Message("天赋已切换，请安装并同步衣柜插件后手动穿戴","Talents switched; install and synchronize the wardrobe addon, then equip manually")end
  end
 Changed()
end)
f:SetScript("OnUpdate",function()
 if M.pending and GetTime()-M.sent>5 then M.pending=false;M.operation=nil;M.loaded=false;Message("未收到WD16应答：请更新本包服务端与SQL后刷新","No WD16 reply: install the matching server build and SQL, then refresh") end
 if M.gearPending and GetTime()-M.gearPending.time>5 then M.gearPending=nil;Message("装备保存未收到确认，请检查装备管理器","Equipment save unconfirmed; check equipment manager") end
end)
ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM",function(_,_,msg) return type(msg)=="string" and (msg:match("^WD16|[a-z]+|")~=nil or msg:match("^WD16Q|")~=nil or msg:match("^WD16P|")~=nil) end)


-- WD90A: refresh authoritative budgets when the visible book observes a new level.
-- No local point arithmetic and no ResetDraft: the normal query reply preserves drafts.
local levelWatch=CreateFrame("Frame")
local elapsedLevel,observedLevel,stableAt,attempts,nextTry=0,nil,0,0,0
local function BookVisible()
 return (RebornWDTreePreview and RebornWDTreePreview:IsShown()) or
        (RebornWDSpecHome and RebornWDSpecHome:IsShown())
end
levelWatch:RegisterEvent("PLAYER_LEVEL_UP")
levelWatch:RegisterEvent("UNIT_LEVEL")
levelWatch:SetScript("OnEvent",function(_,event,unit)
 if event=="UNIT_LEVEL" and unit~="player" then return end
 -- PLAYER_LEVEL_UP may precede UnitLevel changing; sample the unit on the next update.
 elapsedLevel=.25
end)
levelWatch:SetScript("OnUpdate",function(_,elapsed)
 elapsedLevel=elapsedLevel+elapsed
 if elapsedLevel<.25 then return end
 elapsedLevel=0
 if not BookVisible() or M.level<=0 then return end
 local level=UnitLevel("player")
 if not level or level<=0 then return end
 local now=GetTime()
 if observedLevel~=level then observedLevel=level;stableAt=now;attempts=0;nextTry=0 end
 if M.level==level then attempts=0;return end
 -- A save, reset or activation already in flight must finish first.
 if M.pending or now-stableAt<.25 or now<nextTry or attempts>=3 then return end
 if M.sent and now-M.sent<.5 then return end
 M.Query()
 if M.pending and M.operation=="query" then attempts=attempts+1;nextTry=now+2 end
end)
