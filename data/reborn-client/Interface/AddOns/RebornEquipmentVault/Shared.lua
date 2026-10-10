-- EV3S: complete server snapshots; references and physical originals are separate.
local V=RebornEquipmentVault
local M={owned=0,revision=0,ready=false,names={},refs={},pool={},carry={},page=1,serial=0}
V.server=M
local function en(a,b)return V.lang=='en'and b or a end
function M.Name(i)return M.names[i]and M.names[i]~=''and M.names[i]or en('衣柜 ','Wardrobe ')..i end
function M.CanUse()return M.ready and not M.pending and V.selected<=M.owned end
function M.IsBusy()return M.pending~=nil or M.batch~=nil end
local function say(s)M.message=s;if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(s)end end
local errors={busy='衣柜请求过快，本轮已停止，稍后刷新再试',schema='请先安装EV3S迁移SQL及配套服务端',changed='装备或版本已变化，请刷新后重试',blocked='当前状态不能操作（战斗/死亡/交易/飞行等）',saving='装备正在保存，请稍后重试',relogin='需要重新登录校对装备',full='背包空位不足',equipfull='需要空背包格安放被替换装备',itemenchant='临时附魔尚未结束，暂不能收纳',itemrefund='装备仍可退款，暂不能收纳',itemtrade='装备仍可交易，暂不能收纳',itemduration='限时装备暂不能收纳',missing='找不到记录的原装备',cantwear='装备组合或穿戴资格不满足',wornelsewhere='原装备穿在另一个位置，请先放回背包',limit='记录数超过本版同步上限',buildchanged='天赋方案已变化，停止自动换装'}
local function send(command,action)
 if M.pending then return false end
 local now=GetTime();M.serial=M.serial+1
 M.pending={id=M.serial,time=now,action=action or'state',command=command:format(M.serial),pack=V.selected,due=math.max(now,(M.lastSend or -1)+.8)};M.ready=false
 -- All commands share the same gate, including reads and manual tab changes.
 if now>=M.pending.due then M.pending.dispatched=true;M.lastSend=now;SendChatMessage(M.pending.command,'SAY')end
 return true
end
function M.Query()return send('.evsstate %d '..V.selected..' '..M.page,'state')end
local function act(cmd,args)return send('.'..cmd..' %d '..M.revision..' '..args,cmd)end
function V.Select(i)
 if M.IsBusy()then return end
 V.selected=i;M.poolView=false;M.Query();V.Refresh()
end
function M.Page(delta)
 if M.IsBusy()then return end
 M.page=math.max(1,math.min(math.floor(M.owned/6)*6+1,M.page+delta*6));V.Refresh()
end
local function packs(guid)
 local a={};for p,rows in pairs(M.refs)do for _,r in pairs(rows)do if r.guid==guid then a[#a+1]=p;break end end end
 table.sort(a);return a
end
function M.Badge(guid)
 local a=packs(guid);if #a==0 then return ''end
 return #a<=3 and table.concat(a,'·')or en('多个','Many')
end

-- EV3T: cloth ribbon sits outside the icon; it never intercepts mouse input.
local ribbonPalette={{.20,.40,.65},{.20,.52,.36},{.46,.29,.64},{.65,.40,.15},{.14,.49,.52},{.55,.30,.42}}
local function Ribbon(parent,guid,side)
 local a=guid and packs(guid)or {};local f=parent.evSharedRibbon
 if #a==0 then if f then f:Hide()end;return end
 if not f then
  f=CreateFrame('Frame',nil,parent);parent.evSharedRibbon=f;f:EnableMouse(false);f:SetFrameLevel(parent:GetFrameLevel()+2)
  f.cloth=f:CreateTexture(nil,'BACKGROUND');f.cloth:SetAllPoints();f.cloth:SetTexture('Interface\\Buttons\\WHITE8X8')
  f.trim=f:CreateTexture(nil,'ARTWORK');f.trim:SetPoint('TOPLEFT');f.trim:SetPoint('TOPRIGHT');f.trim:SetHeight(2);f.trim:SetTexture('Interface\\Buttons\\WHITE8X8');f.trim:SetVertexColor(.85,.70,.40,1)
  f.tail={};for i=1,5 do for j=1,2 do local t=f:CreateTexture(nil,'BACKGROUND');t:SetTexture('Interface\\Buttons\\WHITE8X8');t:SetHeight(1);t:SetPoint(j==1 and'TOPLEFT'or'TOPRIGHT',f,j==1 and'BOTTOMLEFT'or'BOTTOMRIGHT',0,-i+1);f.tail[#f.tail+1]=t end end
  f.cells={};for i=1,5 do
   local c={};c.disk=f:CreateTexture(nil,'ARTWORK');c.disk:SetTexture('Interface\\AddOns\\RebornEquipmentVault\\Media\\RibbonMedallion')
   c.text=f:CreateFontString(nil,'OVERLAY','GameFontNormalSmall');c.text:SetJustifyH('CENTER');f.cells[i]=c
  end
 end
 local labels={};local current=false;for _,n in ipairs(a)do if n==V.selected then current=true end end
 if #a==1 then labels={tostring(a[1])}elseif current then labels={tostring(V.selected),'+'..(#a-1)}else labels={'x'..#a}end
 local count=#labels;local width=24;for i=1,count do width=math.max(width,#labels[i]*6+6)end
 local step=count<=2 and 17 or(count==3 and 13 or(count==4 and 10 or 8.5))
 local height=math.max(36,count*step+4);local color=#a>1 and{.57,.12,.18}or ribbonPalette[(a[1]-1)%#ribbonPalette+1]
 f.shared=#a>1;f.ids=a;f:SetWidth(width);f:SetHeight(height);f.cloth:SetVertexColor(color[1],color[2],color[3],1)
 for i,t in ipairs(f.tail)do t:SetWidth(width/2-math.ceil(i/2));t:SetVertexColor(color[1],color[2],color[3],1)end
 for i,c in ipairs(f.cells)do
  if i<=count then
   local n=(current and V.selected or a[1]);local ink=ribbonPalette[(n-1)%#ribbonPalette+1];local size=math.min(18,step+1)
   c.disk:ClearAllPoints();c.disk:SetPoint('TOP',f,'TOP',0,-3-(i-1)*step);c.disk:SetSize(size,size);c.disk:Show()
   c.text:ClearAllPoints();c.text:SetPoint('CENTER',c.disk,'CENTER',0,0);c.text:SetFont(STANDARD_TEXT_FONT or'Fonts\\FRIZQT__.TTF',count<=3 and 11 or 8,'OUTLINE');c.text:SetTextColor(math.min(1,ink[1]+.5),math.min(1,ink[2]+.5),math.min(1,ink[3]+.5));c.text:SetText(labels[i]);c.text:Show()
  else c.disk:Hide();c.text:Hide()end
 end
 f:ClearAllPoints()
 if side=='left'then f:SetPoint('TOPRIGHT',parent,'TOPLEFT',-2,-1)
 elseif side=='bottom'then f:SetPoint('TOPLEFT',parent,'BOTTOMLEFT',0,-2)
 else f:SetPoint('TOPLEFT',parent,'TOPRIGHT',2,-1)end
 f:Show()
end
-- All referenced originals plus unassigned stored originals, deduplicated by GUID.
function M.LibraryRows()
 local rows={};for g,link in pairs(M.pool)do rows[g]={guid=g,link=link}end
 for _,outfit in pairs(M.refs)do for _,r in pairs(outfit)do if not rows[r.guid]then rows[r.guid]={guid=r.guid,link=r.link}end end end
 local ids={};for g in pairs(rows)do local include=not M.poolCurrent;if M.poolCurrent then for _,r in pairs(M.refs[V.selected]or{})do if r.guid==g then include=true;break end end end;if include then ids[#ids+1]=g end end;table.sort(ids)
 return ids,rows
end

local characterSlots={'Head','Neck','Shoulder','Shirt','Chest','Waist','Legs','Feet','Wrist','Hands','Finger0','Finger1','Trinket0','Trinket1','Back','MainHand','SecondaryHand','Ranged','Tabard'}
function M.RefreshBadges(stale)
 for slot,name in ipairs(characterSlots)do
  local b=_G['Character'..name..'Slot']or _G['Character'..name..'Slot9']
  if b then
   if not b.evSharedMark then b.evSharedMark=b:CreateFontString(nil,'OVERLAY','GameFontNormalSmall');b.evSharedMark:SetPoint('TOPRIGHT',b,'TOPRIGHT',0,0)end
   local guid
   if not stale then for g,c in pairs(M.carry)do if c.state==2 and c.slot==slot then guid=g;break end end end
   b.evSharedMark:SetText('');Ribbon(b,guid,slot>=16 and slot<=18 and'bottom'or'left');b.evSharedGuid=guid
   if not b.evSharedHook then b.evSharedHook=true;b:HookScript('OnEnter',function(self)
    if self.evSharedGuid then local a=packs(self.evSharedGuid);local labels={};for _,p in ipairs(a)do labels[#labels+1]=('#'..p..' '..M.Name(p))end
     if #a>0 then GameTooltip:AddLine(en('搭配：','Outfits: ')..table.concat(labels,' / '),1,.8,.25,true);GameTooltip:Show()end
    end
   end)end
  end
 end
end
local function location(guid)
 if M.pool[guid]then return en('装备库','Stored')end
 if M.carry[guid]then return M.carry[guid].state==2 and en('身上','Equipped')or en('背包','Bags')end
 return en('找不到','Missing')
end
local function tooltip(b)
 GameTooltip:SetOwner(b,'ANCHOR_RIGHT')
 if b.item and not b.item:match('^item:0:')then GameTooltip:SetHyperlink(b.item)else GameTooltip:SetText(en('空位或原件已不存在','Empty or missing original'))end
 if b.guid then
  GameTooltip:AddLine(location(b.guid)..' · GUID '..b.guid,.7,.9,.9)
  local a=packs(b.guid);local names={};for _,p in ipairs(a)do names[#names+1]=('#'..p..' '..M.Name(p))end
  GameTooltip:AddLine(#a>0 and en('使用搭配：','Outfits: ')..table.concat(names,' / ')or en('未被搭配使用','Not used by an outfit'),1,.8,.25,true)
  if M.pool[b.guid]then GameTooltip:AddLine(en('右键取回背包（保留搭配记录）','Right-click to withdraw; references remain'),.7,.8,.7,true)end
 end;GameTooltip:Show()
end
local function confirm(text,fn)
 StaticPopupDialogs.REBORN_EVS_CONFIRM={text=text,button1=ACCEPT,button2=CANCEL,OnAccept=fn,timeout=0,whileDead=false,hideOnEscape=true,preferredIndex=3}
 StaticPopup_Show('REBORN_EVS_CONFIRM')
end
local function beginBatch(mode,auto)
 if not M.CanUse()or M.batch then return end
 local rows=M.refs[V.selected]or {};local list={}
 if mode=='equip'then
  -- Vacate empty targets and moved originals (ring/trinket swaps) before equipping.
  local worn={};for g,c in pairs(M.carry)do if c.state==2 then worn[c.slot]={guid=g,slot=c.slot}end end
  for s=19,1,-1 do local c=worn[s];if c then
   local target=rows[s];local moved=false;for ts,r in pairs(rows)do if r.guid==c.guid and ts~=s then moved=true end end
   if not target or moved then list[#list+1]={slot=s,guid=c.guid,clear=true}end
  end end
 end
 local order={16,17,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,18,19}
 for _,slot in ipairs(order)do local r=rows[slot];if r then
  local c=M.carry[r.guid]
  if mode=='equip'and(not c or c.state~=2 or c.slot~=slot)or mode=='store'and c and c.state==3 or mode=='take'and(M.pool[r.guid]or c and c.state==2)then list[#list+1]={slot=slot,guid=r.guid}end
 end end
 if #list==0 then say(mode=='take'and en('此搭配没有身上或库内装备需要放回背包','No worn or stored outfit items to return')or mode=='store'and en('背包中没有此搭配可存入公共库的装备','No outfit bag items to store')or en('此搭配已经穿好','Outfit already equipped'));return end
 M.batch={mode=mode,rows=list,pos=1,pack=V.selected,auto=auto};M.nextStep=GetTime()+.6
end
function M.OnTalentActivated(slot,revision)
 if M.IsBusy()then say(en('天赋已切换，衣柜忙，请稍后手动穿戴','Talents switched; wardrobe busy, equip manually'));return false end
 M.follow={slot=slot,revision=revision};M.Query();return true
end
local function step()
 local b=M.batch;if not b or M.pending or not M.ready then return end
 if V.selected~=b.pack or InCombatLockdown()then M.batch=nil;say(en('换装停止：选择或战斗状态变化','Stopped: selection or combat changed'));return end
 if b.auto then local w=RebornWD8;if not w or w.pending or w.active~=b.auto.slot or w.revision~=b.auto.revision then M.batch=nil;say(errors.buildchanged);return end end
 local r=b.rows[b.pos];if not r then M.batch=nil;say(en('操作完成','Operation complete'));V.Refresh();return end
 local c=M.carry[r.guid]
 if b.mode=='equip'then
  if r.clear then
   if not c or c.state~=2 then b.pos=b.pos+1;return end
   if b.auto then act('evslinked',r.slot..' '..r.guid..' 0 0 '..b.pack..' '..b.auto.slot..' '..b.auto.revision..' 1')else act('evsunequip',r.slot..' '..r.guid..' '..b.pack)end
   return
  end
  if c and c.state==2 and c.slot==r.slot then b.pos=b.pos+1;return end
  if not c and not M.pool[r.guid]then M.batch=nil;say(errors.missing..' GUID '..r.guid);return end
  local old,off=0,0;for g,it in pairs(M.carry)do if it.state==2 then if it.slot==r.slot then old=g end;if it.slot==17 then off=g end end end
  local args=r.slot..' '..r.guid..' '..old..' '..off..' '..b.pack
  if b.auto then args=args..' '..b.auto.slot..' '..b.auto.revision..' 0' end
  act(b.auto and'evslinked'or'evsequip',args)
 elseif b.mode=='store'then
  if M.pool[r.guid]then b.pos=b.pos+1;return end
  if not c or c.state~=3 then M.batch=nil;say(errors.changed);return end
  act('evsput',r.guid..' '..b.pack)
 else
  if c and c.state==3 then b.pos=b.pos+1;return end
  if c and c.state==2 then act('evsreturn',c.slot..' '..r.guid..' '..b.pack);return end
  if not M.pool[r.guid]then M.batch=nil;say(errors.missing..' GUID '..r.guid);return end
  act('evstake',r.guid..' '..b.pack)
 end
end
local function receive(msg)
 if type(msg)~='string'then return end
 local prefix=msg:match('^(EV[3S])|');if not prefix then return end
 local f={};for s in msg:gmatch('[^|]+')do f[#f+1]=s end
 local p=M.pending;if not p or tonumber(f[3])~=p.id then return end
 if f[2]=='ERR'then
  M.pending=nil;M.batch=nil;M.follow=nil;M.ready=false;M.nextQuery=(f[4]~='schema'and f[4]~='relogin')and GetTime()+1 or nil
  say(errors[f[4]]or en('服务器拒绝：','Server rejected: ')..tostring(f[4]));V.Refresh();return
 end
 if prefix~='EVS'then return end
 local function number(i,min,max)local n=tonumber(f[i]);if not n or n%1~=0 or n<min or n>max then error('Invalid EVS number')end;return n end
 if f[2]=='BEGIN'then
  p.data={revision=number(4,0,2147483640),pack=number(5,1,2147483640),owned=number(6,1,1000),price=number(7,-1,2147480000),capacity=number(12,1,2000),counts={number(8,0,19000),number(9,0,2000),number(10,0,1100),number(11,1,1000)},seen={0,0,0,0},refs={},pool={},carry={},names={}}
 elseif p.data then
  local d=p.data;local kind=f[2]
  if kind=='NAME'then local n=number(4,1,d.owned);assert(d.names[n]==nil);local x=f[5];assert(x and(x=='-'or(#x<=192 and#x%2==0 and not x:find('[^%x]'))));d.names[n]=x=='-'and''or x:gsub('%x%x',function(v)return string.char(tonumber(v,16))end);d.seen[4]=d.seen[4]+1
  elseif kind=='REF'then local a,s,g=number(4,1,d.owned),number(5,1,19),number(6,1,4294967295);local state=number(7,1,4);assert(f[8]and f[8]:match('^item:%d+:'));d.refs[a]=d.refs[a]or{};assert(not d.refs[a][s]);d.refs[a][s]={guid=g,state=state,link=f[8]};d.seen[1]=d.seen[1]+1
  elseif kind=='POOL'then local g=number(4,1,4294967295);assert(not d.pool[g]and f[5]and f[5]:match('^item:%d+:'));d.pool[g]=f[5];d.seen[2]=d.seen[2]+1
  elseif kind=='CARRY'then local g=number(4,1,4294967295);assert(not d.carry[g]);d.carry[g]={state=number(5,2,3),slot=number(6,0,19),link=f[7]};d.seen[3]=d.seen[3]+1
  elseif kind=='BUILD'then d.build={available=number(4,0,1)==1,revision=number(5,0,2000000000),active=number(6,0,2),pack=number(7,0,2147483640),packs={number(8,0,2147483640),number(9,0,2147483640),number(10,0,2147483640)}}
  elseif kind=='END'then
   for i=1,4 do assert(d.counts[i]==d.seen[i])end;assert(d.pack==V.selected and d.build)
   for g in pairs(d.pool)do assert(not d.carry[g])end
   local slots={};for g,r in pairs(d.carry)do assert(r.link and r.link:match('^item:%d+:'));if r.state==2 then assert(r.slot>0 and not slots[r.slot]);slots[r.slot]=g else assert(r.slot==0)end end
   for _,rows in pairs(d.refs)do local ids={};for _,r in pairs(rows)do assert(not ids[r.guid]);ids[r.guid]=true;local c=d.carry[r.guid];assert(r.state==(d.pool[r.guid]and 1 or c and c.state or 4))end end
   M.revision=d.revision;M.owned=d.owned;M.price=d.price;M.refs=d.refs;M.pool=d.pool;M.capacity=d.capacity;M.carry=d.carry;M.names=d.names;M.build=d.build;M.linkInfo=d.build;M.ready=true;M.pending=nil
   if M.batch and p.action~='state'then
    local b=M.batch;local r=b.rows[b.pos];local c=M.carry[r.guid]
    local ok=b.mode=='equip'and c and(r.clear and c.state==3 or not r.clear and c.state==2 and c.slot==r.slot)or b.mode=='store'and M.pool[r.guid]or b.mode=='take'and c and c.state==3
    if ok then b.pos=b.pos+1;M.nextStep=GetTime()+.65 else M.batch=nil;say(en('结果不符，停止后续操作','Unexpected result; batch stopped'))end
   end
   if M.follow then local f=M.follow;M.follow=nil
    if d.build.available and d.build.active==f.slot and d.build.revision==f.revision and d.build.pack>0 then
     V.selected=d.build.pack;M.poolView=false;beginBatch('equip',f)
    end
   end
   M.RefreshBadges(false);V.Refresh()
  end
 end
end
M.Receive=receive
function M.ProfileCanLink()
 local w=RebornWD8;return M.ready and not M.IsBusy()and w and w.loaded and not w.pending and w.slot==w.active and M.build and M.build.available and w.revision==M.build.revision and w.active==M.build.active
end
function M.ProfileChoose(pack,unlink)
 if not M.ProfileCanLink()or not pack or pack<1 or pack>M.owned then return false end
 V.selected=pack;M.poolView=false;return act('evslink',M.build.revision..' '..M.build.active..' '..pack..' '..(unlink and 0 or 1))
end
function M.OpenWardrobe()if not V.frame or not V.frame:IsShown()then V.Toggle()end;M.Query()end
function M.ProfileEquip()local w=RebornWD8;if w then return M.OnTalentActivated(w.active,w.revision)end end
local oldRefresh=V.Refresh
local function button(parent,label,x,y,fn)
 local b=CreateFrame('Button',nil,parent,'UIPanelButtonTemplate');b:SetPoint('TOPLEFT',x,y);b:SetSize(166,26);b:SetText(label);b:SetScript('OnClick',fn);return b
end
function M.Summary(pack)
 local total,worn,missing=0,0,0;for _,r in pairs(M.refs[pack]or{})do total=total+1;local c=M.carry[r.guid];if c and c.state==2 then worn=worn+1 elseif not c and not M.pool[r.guid]then missing=missing+1 end end
 return en('共','Total ')..total..en('件 · 身上',' · worn ')..worn..(missing>0 and(en(' · 缺',' · missing ')..missing)or'')
end
local function enabled(b,on)if on then b:Enable()else b:Disable()end end
local function bind()
 if M.bound or not V.frame then return end;M.bound=true
 V.capture:SetScript('OnClick',function()if M.CanUse()and not M.batch then local p=V.selected;confirm(en('用身上整套装备覆盖此搭配？不移动或删除装备。','Replace this outfit with currently equipped items? No items move or are deleted.'),function()if M.CanUse()and V.selected==p then act('evssave',p)end end)end end)
 V.clear:SetScript('OnClick',function()local selected=V.selected;confirm(en('将当前搭配整套放回背包？身上的卸下、库内的取出，共享装备也会卸下；搭配记录保留。空间不足时停止，保留已完成部分。','Return this outfit to bags? Unequip worn originals and withdraw stored originals, including shared gear. References remain. Stops if bags fill; completed steps remain.'),function()if V.selected==selected then beginBatch('take')end end)end)
 V.controls[5]:SetScript('OnClick',function()local p=V.selected;confirm(en('穿戴此搭配？空栏目会卸下原装备。换装逐件确认；空间不足或失败时停止，保留已完成部分。','Equip this outfit? Empty slots will be cleared. Stops on failure; completed moves remain.'),function()if V.selected==p then beginBatch('equip')end end)end)
 V.controls[3]:SetScript('OnClick',function()M.Query()end)
 V.controls[4]:SetScript('OnClick',function()if M.ready and M.price>=0 then local p,c=V.selected,M.price;confirm(en('解锁价格：','Unlock price: ')..(c/10000)..en('金币',' gold'),function()if M.ready and V.selected==p then act('evsbuy',p..' '..c)end end)end end)
 V.controls[6]:SetScript('OnClick',function()if M.CanUse()and M.build and M.build.available then local b=M.build;act('evslink',b.revision..' '..b.active..' '..V.selected..' '..(b.pack==V.selected and 0 or 1))end end)
 V.rename:SetScript('OnClick',function()
  StaticPopupDialogs.REBORN_EVS_NAME={text=en('搭配名称（最多16字）','Outfit name (up to 16 characters)'),button1=ACCEPT,button2=CANCEL,hasEditBox=true,maxLetters=48,timeout=0,hideOnEscape=true,OnAccept=function(self)local s=self.editBox:GetText();local hex=s:gsub('.',function(c)return ('%02x'):format(c:byte())end);if M.CanUse()then act('evsname',V.selected..' '..hex)end end};StaticPopup_Show('REBORN_EVS_NAME')
 end)
 V.pagePrev:SetScript('OnClick',function()M.Page(-1)end);V.pageNext:SetScript('OnClick',function()M.Page(1)end)
 M.store=button(V.frame,en('背包装备存入公共库','Store outfit bag items'),27,-577,function()beginBatch('store')end)
 M.forget=button(V.frame,en('清空搭配记录','Clear outfit'),723,-516,function()local p=V.selected;confirm(en('清空此搭配记录？所有实物保留，其他搭配不变。','Clear outfit references? All originals and other outfits remain.'),function()if M.CanUse()and V.selected==p then act('evsclear',p)end end)end)
 M.poolButton=button(V.frame,en('公共装备库','Shared storage'),723,-550,function()if M.IsBusy()then return end;M.poolView=not M.poolView;M.poolPage=1;V.Refresh()end)
 M.stop=button(V.frame,en('停止批量操作','Stop batch operation'),723,-584,function()M.batch=nil;M.follow=nil;if M.pending and not M.pending.dispatched and M.pending.action~='state'then M.pending=nil;M.ready=false;M.nextQuery=GetTime()+.8 end;say(en('已停止；当前已发送操作以服务器结果为准','Stopped; any pending operation will still be reconciled'))end)
 local function explain(b,title,body)
  b:HookScript('OnEnter',function(self)GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:SetText(title);GameTooltip:AddLine(body,1,.85,.6,true);GameTooltip:Show()end)
  b:HookScript('OnLeave',function()GameTooltip:Hide()end)
 end
 explain(M.stop,en('停止批量操作','Stop batch operation'),en('停止本轮尚未发送的换装、收纳或取回。已完成的保留，当前已发送的一件以服务器结果为准；不会撤销或清空搭配记录。','Stop unsent batch steps. Completed changes stay; the current request still finishes. Does not undo or clear outfits.'))
 explain(M.forget,en('清空搭配记录','Clear outfit'),en('只清除当前衣柜的装备搭配名单；实物留在原处，其他搭配保留。只想更新装备，直接保存身上搭配即可。','Clear only this outfit reference list. Originals stay in place and other outfits remain. To update gear, use Save current outfit.'))
 explain(V.clear,en('整套放回背包','Return outfit to bags'),en('身上卸下、库内取出，背包已有的不动。按当前搭配原件核对；共用装备也会卸下但保留各套记录。','Unequip worn and withdraw stored originals of this outfit. Keep all outfit references.'))
 explain(M.store,en('背包装备存入公共库','Store outfit bag items'),en('只收纳背包内属于当前搭配的原件，不卸下身上装备。','Store matching bag originals only; worn equipment stays equipped.'))
 local pf=CreateFrame('Frame',nil,V.frame);M.poolFrame=pf;pf:SetPoint('TOPLEFT',223,-96);pf:SetSize(466,493);pf:SetFrameLevel(V.frame:GetFrameLevel()+15);pf:EnableMouse(true)
 pf:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=16});pf:SetBackdropColor(.03,.035,.04,1)
 local solid=pf:CreateTexture(nil,'BACKGROUND');solid:SetAllPoints();solid:SetTexture(.025,.03,.035,1)
 M.poolTitle=pf:CreateFontString(nil,'OVERLAY','GameFontNormal');M.poolTitle:SetPoint('TOP',0,-16)
 M.poolFilter=button(pf,en('仅看当前搭配','Current outfit only'),35,-452,function()M.poolCurrent=not M.poolCurrent;M.poolPage=1;V.Refresh()end)
 M.poolSlots={}
 for i=1,20 do local b=CreateFrame('Button',nil,pf);b:SetSize(54,54);b:SetPoint('TOPLEFT',35+((i-1)%5)*82,-52-math.floor((i-1)/5)*84);b:SetNormalTexture('Interface\\Buttons\\UI-Quickslot2')
  b.icon=b:CreateTexture(nil,'ARTWORK');b.icon:SetAllPoints();b.mark=b:CreateFontString(nil,'OVERLAY','GameFontNormalSmall');b.mark:SetPoint('TOP',0,0)
  b.caption=b:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');b.caption:SetPoint('TOP',b,'BOTTOM',0,-2)
  b:RegisterForClicks('RightButtonUp');b:SetScript('OnEnter',tooltip);b:SetScript('OnLeave',function()GameTooltip:Hide()end)
  b:SetScript('OnClick',function(self)if self.guid and M.pool[self.guid]and M.CanUse()and not M.batch then act('evstake',self.guid..' '..V.selected)end end);M.poolSlots[i]=b
 end
 button(pf,'<',35,-415,function()M.poolPage=math.max(1,(M.poolPage or 1)-1);V.Refresh()end)
 button(pf,'>',250,-415,function()M.poolPage=(M.poolPage or 1)+1;V.Refresh()end)
 pf:EnableMouseWheel(true);pf:SetScript('OnMouseWheel',function(_,d)M.poolPage=math.max(1,(M.poolPage or 1)-(d>0 and 1 or -1));V.Refresh()end);pf:Hide()
 for _,b in ipairs(V.buttons)do
  b.mark=b:CreateFontString(nil,'OVERLAY','GameFontNormalSmall');b.mark:SetPoint('TOP',b,'TOP',0,1)
  b.where=b:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');b.where:SetPoint('BOTTOM',b,'BOTTOM',0,0)
  b:SetScript('OnReceiveDrag',nil);b:SetScript('OnClick',function(self,key)if key=='RightButton'and self.guid and M.pool[self.guid]and M.CanUse()and not M.batch then act('evstake',self.guid..' '..V.selected)end end)
  b:SetScript('OnEnter',tooltip)
 end
 V.frame:HookScript('OnShow',function()if not M.pending then M.Query()end end)
end
function V.Refresh()
 if not V.frame then return end;bind()
 V.items={};local display=M.refs[V.selected]or {};for s,r in pairs(display)do V.items[s]=r.link end
 if M.poolView then
  M.poolFilter:SetText(M.poolCurrent and en('显示全部装备','Show all equipment')or en('仅看当前搭配','Current outfit only'))
  local ids,library=M.LibraryRows();local stored=0;for _ in pairs(M.pool)do stored=stored+1 end
  local page=M.poolPage or 1;local pages=math.max(1,math.ceil(#ids/20));M.poolPage=math.max(1,math.min(page,pages))
  M.poolTitle:SetText((M.poolCurrent and(M.Name(V.selected)..' · ')or en('装备总览 ','Equipment overview '))..#ids..en('件 · 已收纳 ',' items · stored ')..stored..' / '..(M.capacity or 200)..' · '..M.poolPage..' / '..pages)
  for i,b in ipairs(M.poolSlots)do local g=ids[(M.poolPage-1)*20+i];b.guid=g;b.item=g and library[g].link;b.icon:SetTexture(b.item and select(10,GetItemInfo(b.item))or nil);b.mark:SetText('');Ribbon(b,g,'right');b.caption:SetText(g and(location(g)..(#packs(g)==0 and en(' · 未使用',' · Unused')or''))or'');enabled(b,g~=nil)end
  M.poolFrame:Show()
 else M.poolFrame:Hide()end
 oldRefresh()
 V.title:SetText(en('共享搭配衣柜 · EV3T3','Shared Outfit Wardrobe · EV3T3'))
 V.subtitle:SetText(M.poolView and en('公共装备总览 · 滚轮翻页','Shared storage · mouse wheel pages')..' '..(M.poolPage or 1)or M.Name(V.selected))
 V.hint:SetText(en('条带：当前编号 + 其他共用套数；x表示共用总套数。悬停看完整搭配；总览可筛选当前搭配。','Save records references. Store moves bag items only. Right-click stored originals to withdraw.'))
 V.footer:SetText(M.message or en('搭配共用原件，不复制装备','Outfits share originals; no duplicates'))
 V.capture:SetText(en('保存身上搭配','Save current outfit'));V.clear:SetText(en('整套放回背包','Withdraw outfit items'));V.controls[5]:SetText(en('一键穿戴搭配','Equip outfit'));V.rename:SetText(en('搭配改名','Rename outfit'));V.controls[4]:SetText(en('解锁新衣柜','Unlock wardrobe'))
 V.controls[6]:SetText(M.build and M.build.available and((M.build.pack==V.selected and en('取消关联方案 ','Unlink build ')or en('关联到方案 ','Link to build '))..(M.build.active+1))or en('此职业暂无方案关联','Build linking unavailable'))
 V.lockLabel:SetText(M.ready and en('此衣柜尚未解锁','Wardrobe locked')or en('正在同步…','Synchronizing…'));V.lockPrice:SetText(V.selected>M.owned and M.price and M.price>=0 and (M.price/10000)..en(' 金币',' gold')or'')
 local usable=M.CanUse()and not M.batch
 for _,b in ipairs({V.capture,V.clear,V.controls[5],V.rename,M.store,M.forget})do enabled(b,usable and not M.poolView)end
 enabled(V.controls[6],usable and M.build and M.build.available);enabled(V.controls[4],M.ready and not M.batch and V.selected==M.owned+1 and M.price and M.price>=0)
 V.pageLabel:SetText((math.floor((M.page-1)/6)+1)..' / '..(math.floor(M.owned/6)+1))
 for i,t in ipairs(V.tabs)do t.pack=M.page+i-1;t.label:SetText(M.Name(t.pack));t.sub:SetText(t.pack<=M.owned and M.Summary(t.pack)or t.pack==M.owned+1 and en('可解锁','Unlock available')or en('未开放','Unavailable'));enabled(t,not M.IsBusy()and t.pack<=M.owned+1);t:SetBackdropBorderColor(t.pack==V.selected and 1 or .3,t.pack==V.selected and .8 or .3,.2,1)end
 for _,b in ipairs(V.buttons)do local r=display[b.slot];b.guid=r and r.guid;b.item=r and r.link;b.mark:SetText('');Ribbon(b,r and r.guid,(b.slot==10 or b.slot==6 or b.slot==7 or b.slot==8 or b.slot==11 or b.slot==12 or b.slot==13 or b.slot==14)and'right'or(b.slot>=16 and b.slot<=18)and'right'or'left');b.where:ClearAllPoints();b.where:SetPoint('TOP',b,'BOTTOM',0,(b.slot>=16 and b.slot<=18)and -18 or -1);b.where:SetText(r and location(r.guid)or'');if M.poolView then b:Hide()else b:Show()end end
 if M.poolView then V.model:Hide()else V.model:Show()end
 V.model:EnableMouseWheel(true);V.model:SetScript('OnMouseWheel',function(_,delta)if M.poolView then M.poolPage=math.max(1,(M.poolPage or 1)-(delta>0 and 1 or -1));V.Refresh()end end)
end
local frame=CreateFrame('Frame');frame:RegisterEvent('CHAT_MSG_SYSTEM');frame:RegisterEvent('PLAYER_ENTERING_WORLD');frame:RegisterEvent('PLAYER_EQUIPMENT_CHANGED');frame:RegisterEvent('BAG_UPDATE');frame:RegisterEvent('GET_ITEM_INFO_RECEIVED')
frame:SetScript('OnEvent',function(_,event,msg)
 if event=='CHAT_MSG_SYSTEM'then local ok=pcall(receive,msg);if not ok then M.pending=nil;M.batch=nil;M.ready=false;say(en('同步记录不完整，请刷新','Incomplete snapshot; refresh'));M.nextQuery=GetTime()+1 end
 elseif event=='GET_ITEM_INFO_RECEIVED'then V.Refresh()
 else M.RefreshBadges(true);M.nextQuery=GetTime()+.8 end
end)
frame:SetScript('OnUpdate',function()
 local now=GetTime()
 if M.pending and not M.pending.dispatched and now>=M.pending.due then
  local p=M.pending
  if p.pack~=V.selected or(p.action~='state'and InCombatLockdown())then
   M.pending=nil;M.batch=nil;M.follow=nil;M.ready=false;M.nextQuery=now+.8;say(en('操作取消：搭配或战斗状态已变化','Cancelled: outfit or combat changed'))
  else p.dispatched=true;p.time=now;M.lastSend=now;SendChatMessage(p.command,'SAY')end
 end
 if M.pending and M.pending.dispatched and now-M.pending.time>15 then M.pending=nil;M.batch=nil;M.follow=nil;M.ready=false;say(en('操作超时，停止队列并重新查询（不重发写操作）','Timed out; querying without replaying writes'));M.nextQuery=now+1 end
 if M.nextQuery and now>=M.nextQuery and not M.pending and not M.batch then M.nextQuery=nil;M.Query()end
 if M.batch and now>=(M.nextStep or 0)then M.nextStep=now+.65;step()end
end)
if ChatFrame_AddMessageEventFilter then ChatFrame_AddMessageEventFilter('CHAT_MSG_SYSTEM',function(_,_,msg)return type(msg)=='string'and(msg:match('^EVS|')or msg:match('^EV3|'))~=nil end)end
M.Query()


