local A={serial=0,owners={},rows={},ownerPage=0,rowPage=0,selected={}}
RebornCompanions=A
local F=CreateFrame('Frame','RebornCompanionsFrame',UIParent)
F:SetSize(760,540);F:SetPoint('CENTER');F:SetFrameStrata('DIALOG');F:EnableMouse(true);F:SetMovable(true);F:RegisterForDrag('LeftButton')
F:SetScript('OnDragStart',function(self)self:StartMoving()end);F:SetScript('OnDragStop',function(self)self:StopMovingOrSizing()end)
F:SetBackdrop({bgFile='Interface\\DialogFrame\\UI-DialogBox-Background',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',tile=true,tileSize=32,edgeSize=24,insets={left=5,right=5,top=5,bottom=5}})
F:SetBackdropColor(.06,.08,.10,1)
local solid=F:CreateTexture(nil,'BACKGROUND');solid:SetTexture(.025,.035,.045,1);solid:SetPoint('TOPLEFT',5,-5);solid:SetPoint('BOTTOMRIGHT',-5,5)
local art=F:CreateTexture(nil,'BORDER');art:SetTexture('Interface\\AddOns\\RebornCompanions\\Art\\Companions');art:SetTexCoord(0,1,170/1024,853/1024);art:SetPoint('TOPLEFT',5,-5);art:SetPoint('BOTTOMRIGHT',-5,5)
local shade=F:CreateTexture(nil,'ARTWORK');shade:SetTexture(0,0,0,.60);shade:SetPoint('TOPLEFT',16,-50);shade:SetPoint('BOTTOMRIGHT',-16,70)
F:Hide();tinsert(UISpecialFrames,'RebornCompanionsFrame')
local function label(parent,text,x,y,width)
 local t=parent:CreateFontString(nil,'OVERLAY','GameFontNormal');t:SetPoint('TOPLEFT',x,y);t:SetWidth(width or 700);t:SetJustifyH('LEFT');t:SetText(text);return t
end
local function button(parent,text,x,y,w,fn)
 local b=CreateFrame('Button',nil,parent,'UIPanelButtonTemplate');b:SetSize(w or 100,25);b:SetPoint('TOPLEFT',x,y);b:SetText(text);b:SetScript('OnClick',fn);return b
end
label(F,'MultiBot · 雇佣随从',20,-20)
button(F,'关闭',685,-16,55,function()F:Hide()end)
local title=label(F,'请选择左侧的机器人',230,-56,510)
local status=label(F,'收起保留雇佣关系，但随从不会参战。',20,-479,720);status:SetTextColor(1,1,1)
label(F,'同队成员（服务端核验控制权）',20,-56,205)
local info=label(F,'',230,-86,510)
local errors={OWNER='不是你控制的同队 Playerbot',MAP='机器人不在同一地图',OFFLINE='机器人已离线',COMBAT='队伍正在战斗',DEAD='你或机器人已死亡',TRAVEL='机器人正在传送或飞行',MISSING='该随从已不属于此机器人',BUSY='操作过快，请稍后刷新',ACTION='无效操作或服务端版本过旧',SELECT='请勾选具体随从',HIDDEN='随从已收起、死亡或传送中，请先召回并刷新'}
local classes={[1]='战士',[2]='圣骑士',[3]='猎人',[4]='潜行者',[5]='牧师',[6]='死亡骑士',[7]='萨满',[8]='法师',[9]='术士',[11]='德鲁伊'}
local ownerButtons,rowButtons,checks={},{},{}
local function unhex(s)return (s:gsub('%x%x',function(c)return string.char(tonumber(c,16))end))end
local function names()
 local result={};local raid=GetNumRaidMembers()>0;local n=raid and GetNumRaidMembers() or GetNumPartyMembers()
 for i=1,n do local u=(raid and 'raid' or 'party')..i;local name=UnitName(u);if name and name~=UnitName('player')then result[#result+1]=name end end
 table.sort(result);return result
end
function A.Draw()
 local busy=A.pending or A.batch
 for i,b in ipairs(ownerButtons)do local n=A.owners[A.ownerPage*10+i];b.name=n;b:SetText((n==A.owner and '> 'or'')..(n or''));if n then b:Show()else b:Hide()end;if busy then b:Disable()else b:Enable()end end
 local hidden=0;for _,r in ipairs(A.rows)do if r.hidden then hidden=hidden+1 end end
 title:SetText((A.owner or'请选择机器人')..' · 雇佣随从')
 info:SetText(A.valid and ('共 '..#A.rows..' 名 · 收起设置 '..hidden..' 名 · 第 '..(A.rowPage+1)..' 页')or'等待查询或尚未取得完整数据')
 for i,b in ipairs(rowButtons)do
  local r=A.rows[A.rowPage*8+i];b.row=r
  if r then
   b:Show();local state=r.hidden and(r.world and'收起中'or'已收起')or(r.world and(r.stay and'原地停留'or'在场／跟随')or'待召回／地图限制')
   b.text:SetText(r.name..'  ['..(classes[r.class]or('职业 '..r.class))..']\n'..state)
   b:SetText(r.hidden and'召回'or'收起');checks[i]:Show();checks[i]:SetChecked(A.selected[r.entry] or false);if busy or not A.valid then checks[i]:Disable()else checks[i]:Enable()end
   if busy or not A.valid then b:Disable()else b:Enable()end
  else b:Hide();b.text:SetText('');checks[i]:Hide()end
 end
 for _,b in ipairs(A.actions or{})do if busy or not A.valid or (b.requiresV2 and A.version~=2) then b:Disable()else b:Enable()end end
end
function A.Request(owner,action,entry)
 if A.pending or GetTime()<(A.nextSend or 0)then return false end
 A.serial=A.serial+1;A.pending={id=tostring(A.serial),owner=owner,rows={},action=action,untilTime=GetTime()+8}
 A.valid=false;A.nextSend=GetTime()+.8;A.Draw();status:SetText(owner..'：正在查询／处理…')
 SendChatMessage('.rcompanions '..A.serial..' '..owner..' '..action..' '..(entry or 0),'SAY')
 return true
end
function A.Open(owner)
 F:Show();A.owners=names();A.ownerPage=0
 if A.pending or A.batch then A.Draw();return end
 A.selected={};A.owner=owner or A.owner or A.owners[1];A.rows={};A.valid=false;A.rowPage=0;A.Draw()
 if A.owner then A.Request(A.owner,'list',0)end
end
for i=1,10 do ownerButtons[i]=button(F,'',20,-84-(i-1)*29,190,function(self)
 if A.pending or A.batch then return end
 A.owner=self.name;A.selected={};A.rows={};A.valid=false;A.rowPage=0;A.Request(A.owner,'list',0);A.Draw()
end)end
button(F,'上一页',20,-380,90,function()A.ownerPage=math.max(0,A.ownerPage-1);A.Draw()end)
button(F,'下一页',120,-380,90,function()if (A.ownerPage+1)*10<#A.owners then A.ownerPage=A.ownerPage+1 end;A.Draw()end)
for i=1,8 do
 local b=button(F,'',640,-116-(i-1)*33,90,function(self)if self.row then A.Request(A.owner,self.row.hidden and'show'or'hide',self.row.entry)end end)
 local ck=CreateFrame('CheckButton',nil,F,'UICheckButtonTemplate');ck:SetSize(24,24);ck:SetPoint('TOPLEFT',228,-116-(i-1)*33);ck:SetScript('OnClick',function(self)if b.row then A.selected[b.row.entry]=self:GetChecked() and true or nil end end);checks[i]=ck
 b.text=label(F,'',258,-116-(i-1)*33,400);b.text:SetFontObject('GameFontHighlightSmall');rowButtons[i]=b
end
A.actions={button(F,'全部收起',230,-389,105,function()A.Request(A.owner,'hide',0)end),button(F,'全部召回',345,-389,105,function()A.Request(A.owner,'show',0)end)}
button(F,'刷新',460,-389,75,function()if A.owner and not A.batch then A.Request(A.owner,'list',0)end end)
button(F,'〈',550,-389,45,function()A.rowPage=math.max(0,A.rowPage-1);A.Draw()end)
button(F,'〉',605,-389,45,function()if (A.rowPage+1)*8<#A.rows then A.rowPage=A.rowPage+1 end;A.Draw()end)
local function Selected(action)
 if A.pending or A.batch or not A.valid then return end
 local names,entries={},{}
 for _,r in ipairs(A.rows)do if A.selected[r.entry]then names[#names+1]=A.owner;entries[#entries+1]=r.entry end end
 if #entries==0 then status:SetText('请先勾选右侧随从；可跨页选择。');return end
 A.batch={names=names,entries=entries,action=action,index=1,ok=0,failed=0};A.Draw()
end
button(F,'全选',230,-427,65,function()if not A.pending and not A.batch then for _,r in ipairs(A.rows)do A.selected[r.entry]=true end;A.Draw()end end)
button(F,'清选',300,-427,65,function()if not A.pending and not A.batch then A.selected={};A.Draw()end end)
for i,v in ipairs({{'选中收起','hide'},{'选中召回','show'},{'原地停留','stay'},{'恢复跟随','follow'}})do
 local b=button(F,v[1],370+(i-1)*91,-427,88,function()Selected(v[2])end);b.requiresV2=i>=3;A.actions[#A.actions+1]=b
end
local function batch(action)
 if A.pending or A.batch then return end
 A.batch={names=names(),action=action,index=1,ok=0,failed=0};A.valid=false;A.Draw()
end
button(F,'队伍随从全收起',230,-507,160,function()batch('hide')end)
button(F,'队伍随从全召回',400,-507,160,function()batch('show')end)
button(F,'停止后续批量',570,-507,160,function()A.batch=nil;status:SetText('已停止后续请求；已发送的操作不会撤回。');A.Draw()end)
local function finish(ok,reason)
 local p=A.pending;if not p then return end
 if ok then if A.owner~=p.owner then A.selected={} end;A.version=p.version;A.owner=p.owner;A.rows=p.rows;table.sort(A.rows,function(a,b)return a.entry<b.entry end);A.rowPage=0;A.valid=true end
 A.pending=nil
 if A.batch then
  local b=A.batch;if ok then b.ok=b.ok+1 else b.failed=b.failed+1 end;b.index=b.index+1
  DEFAULT_CHAT_FRAME:AddMessage('|cffffcc00[雇佣随从]|r '..p.owner..'：'..(ok and'状态已返回' or reason))
 end
 status:SetText(ok and'状态已返回；收起／召回中请稍后刷新。隐藏不等于解雇。'or reason);A.Draw()
end
local events=CreateFrame('Frame');events:RegisterEvent('CHAT_MSG_ADDON');events:RegisterEvent('PARTY_MEMBERS_CHANGED');events:RegisterEvent('RAID_ROSTER_UPDATE');events:RegisterEvent('PLAYER_LOGIN')
events:SetScript('OnEvent',function(_,event,prefix,message,channel,sender)
 if event~='CHAT_MSG_ADDON'then A.owners=names();A.Draw();return end
 if prefix~='RBCOMP1'or channel~='WHISPER'or(sender~=UnitName('player') and sender~=UnitName('player')..'-'..GetRealmName())then return end
 local id,kind,data=message:match('^(%d+)|([BERD])|(.*)$');local p=A.pending;if not p or id~=p.id then return end
 if kind=='E'then finish(false,errors[data]or data)
 elseif kind=='B'then local count,version=data:match('^(%d+)|(%d+)$');p.expected=tonumber(count or data);p.version=tonumber(version)or 1;p.rows={}
 elseif kind=='R'and p.expected then
  local e,c,h,w,stay,n=data:match('^(%d+)|(%d+)|([01])|([01])|([01])|(%x*)$');if not e then e,c,h,w,n=data:match('^(%d+)|(%d+)|([01])|([01])|(%x*)$')end
  if e then for _,r in ipairs(p.rows)do if r.entry==tonumber(e)then return end end;p.rows[#p.rows+1]={entry=tonumber(e),class=tonumber(c),hidden=h=='1',world=w=='1',stay=stay=='1',name=unhex(n)}end
 elseif kind=='D'and p.expected and #p.rows==p.expected and tonumber(data)==p.expected then finish(true)end
end)
events:SetScript('OnUpdate',function()
 if A.pending and GetTime()>A.pending.untilTime then finish(false,'服务器未回包：请核对 CMake 模块加载清单及已部署的 worldserver；仅覆盖源码无效。')end
 if A.batch and not A.pending and GetTime()>=(A.nextSend or 0)then
  local b=A.batch;local n=b.names[b.index]
  if n then A.Request(n,b.action,b.entries and b.entries[b.index]or 0)else A.batch=nil;status:SetText('批量结束：已返回 '..b.ok..' 名主人，失败 '..b.failed..' 名；原因见聊天框。');A.Draw()end
 end
end)
SLASH_REBORNCOMPANIONS1='/rcompanions';SlashCmdList.REBORNCOMPANIONS=function(name)A.Open(name~=''and name or nil)end
-- RebornWOW MBUI1A: the launcher is a robot icon at the right end of MultiBot's
-- bar (same button type as MultiBot's own icons), and a small corner grip on it
-- scales the whole MultiBot bar. MultiBot's own files are not changed.
-- Without MultiBot, the old red button is still shown in the middle of the screen.
local ICON='Interface\\AddOns\\RebornCompanions\\Art\\RobotIcon'
local function Toggle() if F:IsShown() then F:Hide() else A.Open() end end
local function DB() RebornCompanionsDB=RebornCompanionsDB or {};return RebornCompanionsDB end

local fallback=button(UIParent,'雇佣随从',0,0,95,Toggle)
fallback:ClearAllPoints();fallback:SetPoint('CENTER',UIParent,'CENTER',0,220);fallback:Hide()

local function Clamp(v) if v<0.5 then return 0.5 elseif v>1.6 then return 1.6 end return v end

-- Re-anchor the bar so its BOTTOMRIGHT stays at the same spot on screen after a
-- scale change. MultiBot anchors it BOTTOMRIGHT to UIParent; SetPoint offsets are
-- in the bar's own (scaled) units.
local function SetBarScale(bar,scale)
 local eff=bar:GetEffectiveScale();local ui=UIParent:GetEffectiveScale()
 local right,bottom=bar:GetRight(),bar:GetBottom()
 bar:SetScale(scale)
 if not right or not bottom then return end
 local sx=right*eff-UIParent:GetRight()*ui;local sy=bottom*eff
 local neff=bar:GetEffectiveScale()
 bar:ClearAllPoints()
 if bar.setPoint then bar.setPoint(sx/neff,sy/neff) else bar:SetPoint('BOTTOMRIGHT',UIParent,'BOTTOMRIGHT',sx/neff,sy/neff) end
end

local function Install(m)
 local bar=m.frames.MultiBar;local right=bar.frames and bar.frames.Right
 if not right or not right.addButton then return false end

 -- One slot to the right of the last button MultiBot put on the right side.
 local x=0
 for name,b in pairs(right.buttons) do if name~='RebornCompanions' and type(b.x)=='number' and b.x>=x then x=b.x+34 end end
 local btn=right.addButton('RebornCompanions',x,0,ICON,'雇佣随从')
 btn.doLeft=function() Toggle() end
 btn.doRight=function() Toggle() end
 -- MBUI1B: no OnClick here; MultiBot's own PostClick already calls doLeft/doRight (an extra toggle closed the window again).
 btn:SetScript('OnEnter',function(self)
  GameTooltip:SetOwner(self,'ANCHOR_TOP');GameTooltip:AddLine('雇佣随从',1,1,1)
  GameTooltip:AddLine('点击打开随从名单。右下角小三角拖动可缩放 MultiBot 底栏，双击小三角恢复原大小。',.8,.8,.8,true);GameTooltip:Show()
 end)
 btn:SetScript('OnLeave',function() GameTooltip:Hide() end)

 -- Corner grip on the robot icon: drag to scale the whole bar.
 local grip=CreateFrame('Button',nil,btn);grip:SetSize(14,14);grip:SetPoint('BOTTOMRIGHT',btn,'BOTTOMRIGHT',6,-6)
 grip:SetFrameLevel(btn:GetFrameLevel()+5)
 grip:SetNormalTexture('Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up')
 grip:SetHighlightTexture('Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight')
 grip:SetPushedTexture('Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down')
 grip:RegisterForClicks('LeftButtonUp')
 grip:SetScript('OnEnter',function(self) GameTooltip:SetOwner(self,'ANCHOR_TOP');GameTooltip:AddLine('拖动缩放底栏（双击恢复）',1,1,1);GameTooltip:Show() end)
 grip:SetScript('OnLeave',function() GameTooltip:Hide() end)
 grip:SetScript('OnMouseDown',function(self)
  -- Scale follows the cursor: anchor = bar's right edge on screen, the grip
  -- sits `dist` bar-units to its right, so scale = (cursor - anchor) / dist.
  local eff=bar:GetEffectiveScale()
  local anchor=bar:GetRight()*eff
  local dist=(self:GetRight()*self:GetEffectiveScale()-anchor)/eff
  if dist<20 then return end
  self.drag={anchor=anchor,dist=dist}
  self:SetScript('OnUpdate',function(g)
   local cx=GetCursorPosition()
   local s=Clamp((cx-g.drag.anchor)/(g.drag.dist*UIParent:GetEffectiveScale()))
   if math.abs(s-bar:GetScale())>0.01 then SetBarScale(bar,s) end
  end)
 end)
 grip:SetScript('OnMouseUp',function(self)
  self:SetScript('OnUpdate',nil);self.drag=nil
  DB().barScale=bar:GetScale()
 end)
 grip:SetScript('OnDoubleClick',function() SetBarScale(bar,1);DB().barScale=1 end)

 -- MultiBot saves the bar position on logout via toPoint, which assumes the bar
 -- has UIParent's scale. Measure on screen instead, so the saved offset is in the
 -- bar's own units and lands in the same place once the scale is reapplied.
 if m.toPoint and not m.rebornScaledToPoint then
  local orig=m.toPoint
  m.toPoint=function(frame)
   if frame==bar and bar:GetScale()~=1 then
    local eff=bar:GetEffectiveScale()
    local offX=(bar:GetRight()*eff-UIParent:GetRight()*UIParent:GetEffectiveScale())/eff
    return math.floor(offX+0.5),math.floor(bar:GetBottom()+0.5)
   end
   return orig(frame)
  end
  m.rebornScaledToPoint=true
 end

 -- Saved scale: MultiBot already restored the offsets (in scaled units), so only
 -- the scale is set here, without re-anchoring.
 -- MBUI1C: gold frame around the bar row, styled like the NetherBot panel. It is a
 -- child of the bar (so it scales with it), sits below the icons and takes no
 -- clicks. It wraps only the row itself: the bar's own buttons plus the Left and
 -- Right groups; popups (Units list, Main/Masters menus) stay outside.
 local box=CreateFrame('Frame',nil,bar)
 box:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',tile=true,tileSize=16,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
 box:SetBackdropColor(0.08,0.08,0.1,0.85);box:SetBackdropBorderColor(0.85,0.65,0.22,1)
 box:EnableMouse(false);box:SetFrameStrata(bar:GetFrameStrata())
 -- MBUI1D: anchor and size it at once; an unanchored frame never got laid out.
 box:SetPoint('CENTER',bar,'CENTER',0,0);box:SetSize(40,40);box:Show()
 local function Bounds(group,acc)
  if not group or not group.buttons or not group:IsVisible() then return end
  for _,b in pairs(group.buttons) do
   if b:IsVisible() then
    local l,r,t,bo=b:GetLeft(),b:GetRight(),b:GetTop(),b:GetBottom()
    if l then
     if not acc.l or l<acc.l then acc.l=l end;if not acc.r or r>acc.r then acc.r=r end
     if not acc.t or t>acc.t then acc.t=t end;if not acc.b or bo<acc.b then acc.b=bo end
    end
   end
  end
 end
 local last='';local tick=0;local state='init'
 local function Layout()
  -- Keep it just under the lowest icon frame, whatever MultiBot's Raise() did.
  local low=bar:GetFrameLevel()
  for _,g in pairs({bar.frames.Left,right}) do if g and g:GetFrameLevel()<low then low=g:GetFrameLevel() end end
  if box:GetFrameLevel()~=math.max(0,low-1) then box:SetFrameLevel(math.max(0,low-1)) end
  if box:GetFrameStrata()~=bar:GetFrameStrata() then box:SetFrameStrata(bar:GetFrameStrata()) end
  local acc={};Bounds(bar,acc);Bounds(bar.frames.Left,acc);Bounds(right,acc)
  local bl,bb=bar:GetLeft(),bar:GetBottom()
  if not acc.l or not bl then state='no icons measured';return end
  local pad=7
  local x,y,w,h=acc.l-bl-pad,acc.b-bb-pad,acc.r-acc.l+pad*2,acc.t-acc.b+pad*2
  local key=string.format('%.1f %.1f %.1f %.1f',x,y,w,h)
  if key~=last then last=key;box:ClearAllPoints();box:SetPoint('BOTTOMLEFT',bar,'BOTTOMLEFT',x,y);box:SetSize(w,h) end
  state='ok '..key
 end
 -- Driven by a separate always-shown frame: the box's own OnUpdate depends on it being laid out.
 local ticker=CreateFrame('Frame',nil,UIParent)
 ticker:SetScript('OnUpdate',function(self,dt) tick=tick+dt;if tick<0.25 then return end;tick=0;Layout() end)
 Layout()
 SLASH_REBORNCOMPANIONSBAR1='/rcbar'
 SlashCmdList.REBORNCOMPANIONSBAR=function()
  Layout()
  DEFAULT_CHAT_FRAME:AddMessage(string.format('|cffffcc00[雇佣随从]|r 金边：%s；显示=%s 层级=%s/%s 底栏层级=%s 缩放=%.2f',
   state,tostring(box:IsVisible()),box:GetFrameStrata(),box:GetFrameLevel(),bar:GetFrameLevel(),bar:GetScale()))
 end
 local saved=tonumber(DB().barScale)
 if saved and saved~=1 then bar:SetScale(Clamp(saved)) end
 return true
end

local attach=CreateFrame('Frame');local elapsed,waited=0,0
attach:SetScript('OnUpdate',function(self,dt)
 elapsed=elapsed+dt;if elapsed<1 then return end;waited=waited+elapsed;elapsed=0
 local m=MultiBot
 if m and m.frames and m.frames.MultiBar and Install(m) then fallback:Hide();self:SetScript('OnUpdate',nil);return end
 if waited>=10 then fallback:Show() end
end)
