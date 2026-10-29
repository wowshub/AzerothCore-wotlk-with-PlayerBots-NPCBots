-- MBTG1A: explicit bot target; never forwards to the self learning API.
local G,S=RebornTalentGuide,RebornTalentCollections
local B={};G.BotRecommendations=B
local tokens={[1]='WARRIOR',[2]='PALADIN',[3]='HUNTER',[4]='ROGUE',[5]='PRIEST',[6]='DEATHKNIGHT',[7]='SHAMAN',[8]='MAGE',[9]='WARLOCK',[11]='DRUID',[13]='WITCHDOCTOR'}
local serial=math.floor(GetTime()*1000)%1000000000
local function say(text)B.message=text;if G.TalentCenter then G.TalentCenter.Message(text)end end
local function valid()
 local u=B.name and MultiBot and MultiBot.toUnit(B.name)
 return u and UnitExists(u)and UnitGUID(u)==B.guid and UnitGUID(u)~=UnitGUID('player')and u
end
local function counter(g)return type(g)=='string'and tonumber(g:match('^0x00000000(%x%x%x%x%x%x%x%x)$')or'',16)end
function B.Stop(why)
 B.job=nil;B.pending=nil;B.buffer=nil;B.quote=nil;B.payToken=nil
 if StaticPopup_Hide then StaticPopup_Hide('REBORN_BT_APPLY');StaticPopup_Hide('REBORN_BT_PAY')end
 if why then say(why)end
end
local function request(op,args)
 if B.pending then return false end
 if not valid()then B.Stop('机器人身份改变或离队，请重新选择 / Bot unavailable.');B.loaded=false;return false end
 serial=serial%2147483646+1;B.nonce=serial;B.pending=op;B.sent=GetTime();B.buffer=nil
 SendChatMessage('.'..op..' '..B.id..' '..serial..(args and' '..args or''),'SAY');return true
end
function B.Query()return request('btstate')end
function B.Open(name)
 if B.pending or B.job then say('请等待当前机器人操作结束 / Wait for the current request.');return false end
 local u=MultiBot and MultiBot.toUnit(name);local id=u and counter(UnitGUID(u));local _,token,class=u and UnitClass(u)
 if u then _,token,class=UnitClass(u)end
 if not u or not id or UnitGUID(u)==UnitGUID('player')or not tokens[class]then say('请选择队伍中支持的Playerbot / Select a supported grouped Playerbot.');return false end
 B.Stop();B.guid=UnitGUID(u);B.id=id;B.name=name;B.class=tokens[class];B.level=UnitLevel(u);B.loaded=false
 local T=G.TalentCenter;T.Open('recommend',B.class);B.mode=true
 if B.class=='WITCHDOCTOR'then
  local M=RebornWDBotTalents;if not M then say('请加载巫医机器人天赋插件');return false end
  if M.guid~=B.guid and not M.Begin(u,name)then B.mode=false;return false end
  if not M.pending then M.Query()end
 else B.Query()end
 T.Refresh();return true
end
function B.Pick()
 if not B.selector then
  local f=RebornTalentTreeCanvas.Window('RebornBotTalentTargets','选择机器人 / Select Playerbot');B.selector=f;f:SetSize(400,530);B.rows={}
  for i=1,12 do local b=RebornTalentTreeCanvas.Button(f,20,-45-(i-1)*35,360,'',function(self)if self.bot then B.Open(self.bot);f:Hide()end end);B.rows[i]=b end
 end
 local names,seen={},{};for _,prefix in ipairs({'party','raid'})do for i=1,(prefix=='party'and 4 or 40)do local u=prefix..i;if UnitExists(u)and UnitGUID(u)~=UnitGUID('player')then local n=UnitName(u);if n and not seen[n]then seen[n]=true;names[#names+1]=n end end end end
 table.sort(names);for i,b in ipairs(B.rows)do b.bot=names[i];b:SetText(names[i]or'');if names[i]then b:Show()else b:Hide()end end
 B.selector:Show();if #names==0 then say('队伍中没有可见队友 / No visible group members.')end
end
local function nativePlan(index)
 local data=S.NativeData(B.class);local engine=S.NativeEngine(B.class)
 if not data or not engine then return nil,'该职业尚无推荐'end
 local plan,why
 if engine.Build then plan,why=engine.Build(index,B.level)
 elseif B.level>=80 then plan=data.plans[index]else return nil,'本职业现有方案是80级参考，请80级后应用'end
 if not plan then return nil,why end
 local current,target={{},{},{}},S.Copy(plan)
 for t,tree in ipairs(data.trees)do for i,n in ipairs(tree)do current[t][i]=B.ranks[n.id]or 0;target.ranks[t][i]=math.max(current[t][i],plan.ranks[t][i]or 0)end end
 local queue,err=engine.Queue(target,current);if not queue then return nil,err end
 if #queue>B.free then return nil,'剩余天赋点不足 / Not enough talent points.'end
 if #queue==0 then return nil,'当前推荐已满足，没有需要补的点 / Already matches.'end
 return queue
end
local function wdDraft(index)
 local M,D=RebornWDBotTalents,RebornTalentGuideWDData;local p=D and D.plans[index]
 if not M or M.guid~=B.guid or not M.CanEdit()or M.HasDrafts()or not p or p.spec~=M.spec or M.specs[M.slot+1]~=p.spec then return nil,'先在机器人面板选择已解锁并绑定的相应专精，保存或撤销已有草稿'end
 local mask=M.aeMasks[M.slot+1];local start=mask;local candidates={}
 for _,list in ipairs({p.ae,p.order})do for _,v in ipairs(list)do candidates[#candidates+1]=type(v)=='table'and{id=v[1],rank=v[2]}or{id=v,rank=1}end end
 for pass=1,200 do
  local progress=false
  for _,n in ipairs(candidates)do local row=RebornWDNodeLayout.nodes[RebornWDNodeLayout.index[n.id]]
   if not row then return nil,'推荐节点版本不匹配'end
   local rank=M.AERank(n.id,mask)
   if rank<n.rank then local nextMask=M.MaskSet(mask,row.offset,row.width,rank+1);if M.AEValid(nextMask)then mask=nextMask;progress=true;break end end
  end
  if not progress then break end
  if pass==200 then return nil,'超过推荐安全步数'end
 end
 if M.MaskEqual(mask,start)then return nil,'没有可补点数；请检查预算与已保存点数'end
 return {mask=mask,before=start,revision=M.revision,slot=M.slot,spec=M.spec}
end
local function advance()
 local j=B.job;if not j then return end
 local T=G.TalentCenter
 if not B.mode or not valid()or B.guid~=j.guid or B.group~=j.group or T.class~=B.class or T.tab~='recommend'or(T.selected[B.class]or 1)~=j.index then B.Stop('目标、推荐或激活方案改变，停止后续加点');return end
 local row=j.queue[j.pos]
 if not row then B.Stop('机器人推荐加点已逐点确认 / Bot talent points confirmed.');G.TalentCenter.Refresh();return end
 local n=S.NativeData(B.class).trees[row.tab][row.index]
 request('btpoint',B.group..' '..B.stamp..' '..n.id..' '..row.rank)
end
function B.Apply()
 local T=G.TalentCenter;if not B.mode or T.class~=B.class or T.tab~='recommend'or B.pending or B.job then return end
 local index=T.selected[B.class]or 1;local value,why
 if B.class=='WITCHDOCTOR'then value,why=wdDraft(index)else if not B.loaded then say('请刷新机器人状态');return end;value,why=nativePlan(index)end
 if not value then say(why);return end
 local guid,stamp=B.guid,B.stamp
 StaticPopupDialogs.REBORN_BT_APPLY={text='将推荐应用到 '..B.name..'？ / Apply to this bot?\n保留已保存点数，不自动洗点或付费。巫医只载入机器人草稿，仍需保存。',button1=YES,button2=CANCEL,timeout=30,hideOnEscape=true,OnAccept=function()
  if not B.mode or B.guid~=guid or not valid()or B.pending or T.class~=B.class or(T.selected[B.class]or 1)~=index then say('对象或推荐已改变，请重试');return end
  if B.class=='WITCHDOCTOR'then local now,err=wdDraft(index);if not now or now.before~=value.before or now.revision~=value.revision or now.slot~=value.slot or now.mask~=value.mask then say(err or'机器人方案已改变');return end;local M=RebornWDBotTalents;M.draftAE=now.mask;M.Message('推荐已载入机器人草稿，请核对并保存');if M.ShowPanel then M.ShowPanel()end;say('已载入机器人草稿；尚未保存 / Bot draft loaded, not saved.')
  else if B.stamp~=stamp then say('机器人快照已改变，请重新确认');return end;B.job={guid=guid,group=B.group,index=index,queue=value,pos=1};advance()end
 end};StaticPopup_Show('REBORN_BT_APPLY')
end
function B.Unlock(currency,slot,name)
 if B.pending or B.job then return end
 if name and(name~=B.name or not B.mode)then if not B.Open(name)then return end;if B.pending then say('请等状态同步后再次选择币种');return end end
 if not valid()then say('请先选择机器人');return end
 local M=RebornWDBotTalents
 if B.class=='WITCHDOCTOR'and(not M or M.pending or M.HasDrafts())then say('请等待巫医状态同步，保存或撤销草稿');return end
 slot=slot or(B.class=='WITCHDOCTOR'and M and M.unlocked or 1)
 request('btuquote',slot..' '..currency)
end
local errors={permission='无管理权限、离队或超过50码',unsafe='需要双方存活、脱战并停止移动施法',storage='请先安装本批CHARACTERS SQL',wallet_unavailable='机器人所属账号钱包不存在或查询失败',insufficient='所选币种余额不足，未解锁',expired='报价过期、配置改变或身份改变，请重新询价',level='机器人等级不足',slot='方案已经变化，请刷新',disabled='此方案或币种未开放',stale='机器人方案快照改变，已停止',point='天赋等级、职业或剩余点数不符合条件',native_rejected='原生加点拒绝，已停止',transaction='数据库事务未完成，未确认解锁',unconfirmed='购买结果未确认，请刷新核对权益后再操作',already_unlocked='已有解锁权益，已核对恢复，请刷新'}
function B.Receive(message)
 if type(message)~='string'then return false end
 local guid,nonce,payload=message:match('^BTT1|(%d+)|(%d+)|(.+)$')
 if not guid or not B.pending or tonumber(guid)~=B.id or tonumber(nonce)~=B.nonce then return false end
 if not valid()then B.Stop('机器人身份改变，停止操作');return true end
 local fields={};for f in(payload..'|'):gmatch('(.-)|')do fields[#fields+1]=f end
 local kind=fields[1]
 if kind=='ERROR'then B.Stop(errors[fields[2]]or('服务器拒绝 / '..(fields[2]or'error')));return true end
 if kind=='BEGIN'then
  if B.pending~='btstate'and B.pending~='btpoint'and B.pending~='btswitch'then return true end
  local v={};for i=2,9 do local n=tonumber(fields[i]);if not n or n<0 or n%1~=0 then return true end;v[i]=n end
  if tokens[v[2]]~=B.class then B.Stop('职业快照不匹配');return true end
  B.buffer={classId=v[2],level=v[3],group=v[4],count=v[5],free=v[6],money=v[7],stamp=v[8],expected=v[9],ranks={},rows=0};return true
 elseif kind=='ROWS'and B.buffer then
  for id,rank in(fields[2]or''):gmatch('(%d+):(%d+),')do id,rank=tonumber(id),tonumber(rank);if B.buffer.ranks[id]then B.Stop('重复天赋快照');return true end;B.buffer.ranks[id]=rank;B.buffer.rows=B.buffer.rows+1 end;return true
 elseif kind=='END'and B.buffer then
  local v=B.buffer;if v.rows~=v.expected then return true end
  local op=B.pending;B.pending=nil;B.buffer=nil;for k,value in pairs(v)do B[k]=value end;B.loaded=true
  if op=='btpoint'and B.job then local row=B.job.queue[B.job.pos];local id=S.NativeData(B.class).trees[row.tab][row.index].id;if B.ranks[id]~=row.rank then B.Stop('服务器点数未确认，停止');return true end;B.job.pos=B.job.pos+1;advance()else say('机器人天赋已同步 / Bot talents synchronized.')end
 elseif kind=='QUOTE'and B.pending=='btuquote'then
  B.pending=nil;local q={};for i=2,7 do q[i]=tonumber(fields[i]);if not q[i]then say('报价格式不完整');return true end end
  local id,guid,token=B.id,B.guid,B.nonce;B.payToken=token;local currency=({'金币 / Gold','DP','VP'})[q[3]+1]
  if not currency then return true end
  StaticPopupDialogs.REBORN_BT_PAY={text='解锁 '..B.name..' · 方案 '..(q[2]+1)..'？\n支付来源：机器人所属账号 '..q[7]..'（金币为机器人自身余额）\n费用 '..q[4]..' '..currency..'；余额 '..q[5]..'；要求等级 '..q[6]..'。\n三选一，一次性支付。 / One currency, one-time payment.',button1='确认支付 / Confirm',button2=CANCEL,timeout=50,hideOnEscape=true,OnAccept=function()if not B.mode or B.payToken~=token or B.guid~=guid or B.id~=id or not valid()or B.pending or not G.TalentCenter.frame:IsShown()then say('对象改变或报价取消，请重新询价');return end;B.payToken=nil;request('btubuy',token)end,OnCancel=function()B.payToken=nil end};StaticPopup_Show('REBORN_BT_PAY')
 elseif kind=='BOUGHT'or kind=='RECOVERY_REQUIRED'then
  B.pending=nil;say(kind=='BOUGHT'and'服务器确认已解锁 / Unlock confirmed.'or'已保存购买权益，需刷新恢复；不要重复付款 / Receipt saved, refresh to recover.')
  if B.class=='WITCHDOCTOR'then local M=RebornWDBotTalents;if M and M.guid==B.guid and not M.pending then M.Query()end else B.Query()end
 end
 if G.TalentCenter.frame then G.TalentCenter.Refresh()end;return true
end
local clock=CreateFrame('Frame');clock:RegisterEvent('CHAT_MSG_SYSTEM');clock:RegisterEvent('PLAYER_LOGOUT')
clock:SetScript('OnEvent',function(_,event,msg)if event=='CHAT_MSG_SYSTEM'then B.Receive(msg)else B.Stop()end end)
clock:SetScript('OnUpdate',function()if B.pending and GetTime()-B.sent>8 then B.Stop('请求超时，已停止且不自动重发；请刷新核对 / Timed out; refresh to verify.')end end)
ChatFrame_AddMessageEventFilter('CHAT_MSG_SYSTEM',function(_,_,msg)return type(msg)=='string'and msg:match('^BTT1|')~=nil end)
-- Both entry points use the same explicit target selector. Self action is retained.
local T=G.TalentCenter;local oldRefresh,oldOpen=T.Refresh,T.Open
function T.Open(...)B.Stop();B.mode=false;return oldOpen(...)end
function T.Refresh(...)
 oldRefresh(...);if not T.frame then return end
 if not B.targetButton then
  local C=RebornTalentTreeCanvas
  B.targetButton=C.Button(T.frame,20,-682,365,'选择机器人 / Playerbot',B.Pick)
  B.selfButton=C.Button(T.frame,20,-721,175,'返回本人 / My talents',function()B.mode=false;B.Stop();T.Open('recommend',S.Class())end)
  B.refreshButton=C.Button(T.frame,205,-721,180,'刷新机器人 / Refresh',function()if B.class=='WITCHDOCTOR'then local M=RebornWDBotTalents;if M and M.guid==B.guid and not M.pending then M.Query()end else B.Query()end end)
  B.buildButtons={}
  for i=1,2 do local group=i-1;B.buildButtons[i]=C.Button(T.frame,416+(i-1)*190,-56,180,'方案 / Build '..i,function()if B.mode and B.loaded and not B.pending and not B.job then request('btswitch',group..' '..B.stamp)end end)end
  B.botPanel=C.Button(T.frame,1040,-56,250,'机器人天赋 / Bot panel',function()if B.class=='WITCHDOCTOR'and RebornWDBotTalents.ShowPanel then RebornWDBotTalents.ShowPanel()end end)
  B.applyButton=C.Button(T.frame,812,-740,270,'应用到机器人 / Apply to bot',B.Apply)
  B.payButtons={};for i,label in ipairs({'金币 / Gold','DP','VP'})do local cur=i-1;B.payButtons[i]=C.Button(T.frame,20+(i-1)*123,-760,118,label,function()B.Unlock(cur)end)end
  T.frame:HookScript('OnHide',function()B.Stop();B.mode=false end)
 end
 B.targetButton:SetText(B.mode and('目标 / Bot: '..(B.name or''))or'选择机器人 / Playerbot')
 if B.job and(T.class~=B.class or T.tab~='recommend'or(T.selected[B.class]or 1)~=B.job.index)then B.Stop('页面或推荐改变，已停止后续加点；已投入点数保留')end
 for i,b in ipairs(B.buildButtons)do
  if B.mode and B.class~='WITCHDOCTOR'then
   b:Show();b:SetText('方案 / Build '..i..(B.loaded and B.group==i-1 and' · 已激活'or''))
   if B.loaded and i<=(B.count or 1)and not B.pending and not B.job then b:Enable()else b:Disable()end
  else b:Hide()end
 end
 if B.mode then B.refreshButton:Show()else B.refreshButton:Hide()end
 if B.mode and B.class=='WITCHDOCTOR'then B.botPanel:Show()else B.botPanel:Hide()end
 for _,f in ipairs(B.payButtons)do if B.mode then f:Show()else f:Hide()end end
 if B.mode then
  T.apply:Hide();T.applySaved:Hide();T.saveCurrent:Hide();T.actual:Disable()
  if T.tab=='recommend'and T.class==B.class then B.applyButton:Show();if B.pending or B.job then B.applyButton:Disable()else B.applyButton:Enable()end else B.applyButton:Hide()end
  T.summary:SetText('机器人 / Bot: '..B.name..' · Lv '..B.level..'\n推荐仅用于该目标 / Explicit bot target\n解锁：金币 / DP / VP 三选一')
  T.status:SetText(B.message or'请选推荐；不会修改本人天赋 / Self talents remain separate.')
 else B.applyButton:Hide()end
end
local setup=CreateFrame('Frame');local installed=false
setup:SetScript('OnUpdate',function()
 if installed or not MultiBot or not MultiBot.talent then return end
 local f=MultiBot.talent;if not f.wowButton then return end;installed=true
 local b=f.wowButton('推荐 / Recommend',-650,966,170,20,12)
 b.doLeft=function()B.Open(f.name)end
 local M=RebornWDBotTalents
 if M then
  M.QuoteUnlock=function()if M.pending or M.HasDrafts()then M.Message('请先保存或撤销草稿');return end;B.PickCurrency(M.name)end
 end
 setup:SetScript('OnUpdate',nil)
end)
function B.PickCurrency(name)
 if B.pending then return end
 if B.name~=name or not B.mode then if not B.Open(name)then return end end
 if not B.currencyFrame then local C=RebornTalentTreeCanvas;local f=C.Window('RebornBotTalentCurrency','解锁支付 / Unlock payment');f:SetSize(450,180);B.currencyFrame=f
  for i,label in ipairs({'金币 / Gold','DP','VP'})do local cur=i-1;C.Button(f,20+(i-1)*140,-65,130,label,function()B.Unlock(cur);f:Hide()end)end
 end
 B.currencyFrame:Show()
end
