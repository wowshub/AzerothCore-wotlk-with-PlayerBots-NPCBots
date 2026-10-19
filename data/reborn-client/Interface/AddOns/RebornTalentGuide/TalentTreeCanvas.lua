-- TG4C: read-only node projection, shared by WD recommendations and classic panel prototype.
RebornTalentTreeCanvas={}
local C=RebornTalentTreeCanvas
local ART='Interface\\AddOns\\RebornTalentGuide\\Art\\'
-- TG7B: normalized positions are UI preferences, never talent state.
local function prefs()
 RebornTGScaleDB=RebornTGScaleDB or{};local db=RebornTGScaleDB
 db.windows=db.windows or{};db.positions=db.positions or{};return db
end
local function finite(v)return type(v)=='number'and v==v and v>-1e6 and v<1e6 end
function C.SavePosition(f)
 if not f.rebornPlaced or not f.GetCenter or not f.GetEffectiveScale then return end
 local x,y=f:GetCenter();local scale=f:GetEffectiveScale();local parent=UIParent:GetEffectiveScale()
 if not finite(x)or not finite(y)or not finite(scale)or not finite(parent)or parent<=0 then return end
 local left=UIParent.GetLeft and UIParent:GetLeft()or 0;local bottom=UIParent.GetBottom and UIParent:GetBottom()or 0
 prefs().positions[f.rebornScaleKey]={x=math.max(0,math.min(1,(x*scale/parent-left)/UIParent:GetWidth())),y=math.max(0,math.min(1,(y*scale/parent-bottom)/UIParent:GetHeight()))}
end
function C.RestorePosition(f)
 local v=prefs().positions[f.rebornScaleKey];f.rebornPlaced=true
 if type(v)~='table'or not finite(v.x)or not finite(v.y)or not f.GetEffectiveScale then return end
 local scale=f:GetEffectiveScale();local parent=UIParent:GetEffectiveScale();if not finite(scale)or scale<=0 or not finite(parent)then return end
 f:ClearAllPoints();f:SetPoint('CENTER',UIParent,'BOTTOMLEFT',math.max(0,math.min(1,v.x))*UIParent:GetWidth()*parent/scale,math.max(0,math.min(1,v.y))*UIParent:GetHeight()*parent/scale)
end
function C.Legend(f,mode,y)
 if not f.legend then f.legend=C.Text(f,20,-(y or 94),1240,'','GameFontHighlightSmall');f.legend:SetTextColor(.88,.9,.94)end
 f.legend:SetText(mode=='collection'and'金色：收藏草稿；角色已保存点数见悬停与差异；左键加点 / 右键减点；保存收藏不会改变角色。'or mode=='current'and'显示当前已保存点数；— 表示尚未读取；节点只读；左右下角拖动缩放，双击恢复适屏。'or'金色：推荐配点；灰色：未推荐；数字：推荐 / 上限；当前已保存点数见悬停；节点只读。')
end
-- Each large window owns its scale; opening it again must not discard the user's size.
function C.AttachScale(f,key)
 if f.rebornScaleGrips then return end
 local function fit()return math.min(1,math.max(.45,math.min((UIParent:GetWidth()-30)/f:GetWidth(),(UIParent:GetHeight()-30)/f:GetHeight())))end
 local function apply(value,keepRight)
  value=math.max(.45,math.min(1.3,value));local e=f:GetEffectiveScale();local x=keepRight and f:GetRight()or f:GetLeft();local y=f:GetTop()
  f:SetScale(value)
  if x and y then local n=f:GetEffectiveScale();f:ClearAllPoints();f:SetPoint(keepRight and'TOPRIGHT'or'TOPLEFT',UIParent,'BOTTOMLEFT',x*e/n,y*e/n)end
  prefs().windows[key]=value;C.SavePosition(f)
 end
 f.rebornScaleKey=key;f.rebornScaleGrips={};f.rebornSetScale=apply;f.rebornFitScale=fit
 for _,left in ipairs({false,true})do
  local g=CreateFrame('Button',nil,f);g:SetSize(20,20);g:SetPoint(left and'BOTTOMLEFT'or'BOTTOMRIGHT',f,left and'BOTTOMLEFT'or'BOTTOMRIGHT',left and 6 or-6,5);g:SetFrameLevel(f:GetFrameLevel()+8)
  g:SetNormalTexture('Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up');g:SetHighlightTexture('Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight');g:SetPushedTexture('Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down')
  if left and g.GetNormalTexture then for _,t in ipairs({g:GetNormalTexture(),g:GetHighlightTexture(),g:GetPushedTexture()})do if t then t:SetTexCoord(1,0,0,1)end end end
  g:SetScript('OnMouseDown',function(self,button)
   if button~='LeftButton'then return end
   local x=GetCursorPosition();self.drag={x=x,scale=f:GetScale(),parentScale=UIParent:GetEffectiveScale()}
   self:SetScript('OnUpdate',function(grip)
    if IsMouseButtonDown and not IsMouseButtonDown('LeftButton')then grip:SetScript('OnUpdate',nil);grip.drag=nil;return end
    local cx=GetCursorPosition();local delta=(cx-grip.drag.x)/(f:GetWidth()*grip.drag.parentScale);apply(grip.drag.scale+(left and-delta or delta),left)
   end)
  end)
  local function stop(self)self:SetScript('OnUpdate',nil);self.drag=nil end
  g:SetScript('OnMouseUp',stop);g:SetScript('OnHide',stop)
  g:SetScript('OnDoubleClick',function()apply(fit());prefs().windows[key]=nil;prefs().positions[key]=nil;f:ClearAllPoints();f:SetPoint('CENTER');f.rebornPlaced=true end)
  g:SetScript('OnEnter',function(self)GameTooltip:SetOwner(self,'ANCHOR_TOP');GameTooltip:SetText('拖动缩放 · 双击恢复适屏');GameTooltip:AddLine('Ctrl + 滚轮也可缩放；仅保存窗口大小。',1,1,1,true);GameTooltip:Show()end);g:SetScript('OnLeave',function()GameTooltip:Hide()end)
  f.rebornScaleGrips[#f.rebornScaleGrips+1]=g
 end
 f:HookScript('OnDragStop',function()C.SavePosition(f)end);f:HookScript('OnHide',function()C.SavePosition(f)end)
 f:EnableMouseWheel(true);f:HookScript('OnMouseWheel',function(_,delta)if IsControlKeyDown()then apply(f:GetScale()+(delta>0 and .05 or-.05))end end)
end
function C.Art(board,index)
 if not board.art then board.art=board:CreateTexture(nil,'BORDER');board.art:SetPoint('TOPLEFT',4,-4);board.art:SetPoint('BOTTOMRIGHT',-4,4)end
 board:SetBackdropColor(.02,.025,.035,0);board.art:SetTexture(ART..'PaladinTriptychTG6B_blp');board.art:SetTexCoord((index-1)/3,index/3,0,1);board.art:SetAlpha(.22);board.art:Show()
end
function C.Text(parent,x,y,w,value,font)
 local t=parent:CreateFontString(nil,'OVERLAY',font or'GameFontHighlightSmall');t:SetPoint('TOPLEFT',x,y);t:SetWidth(w);t:SetJustifyH('LEFT');t:SetText(value or'');return t
end
function C.Button(parent,x,y,w,value,fn)
 return RebornTalentGuideTheme.Button(parent,x,y,w,25,value,fn)
end
function C.Atlas(texture,key)
 local a=(RebornWDHomeArt and RebornWDHomeArt[key])or(RebornWDArt and RebornWDArt[key])
 if not a then return false end;texture:SetTexture(a[1]);texture:SetTexCoord(a[4],a[5],a[6],a[7]);return true
end
function C.Window(name,title)
 local f=CreateFrame('Frame',name,UIParent);f:SetSize(1294,690);f:SetPoint('CENTER');f:SetFrameStrata('DIALOG');f:SetFrameLevel(2);f:SetClampedToScreen(true);f:EnableMouse(true);f:SetMovable(true);f:RegisterForDrag('LeftButton')
 f:SetScript('OnDragStart',function(self)self:StartMoving()end);f:SetScript('OnDragStop',function(self)self:StopMovingOrSizing()end)
 f:SetBackdrop({edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=16,insets={left=4,right=4,top=4,bottom=4}});f:SetBackdropBorderColor(.6,.48,.25,1)
 -- TG14A: the opaque fallback must be below the CoA home/spec illustration.
 local classicSpec=name=='RebornClassicSpecHome'or name=='RebornClassicSpecTree'
 local bg=f:CreateTexture(nil,classicSpec and'BACKGROUND'or'BORDER');f.rebornBaseBackground=bg;bg:SetAllPoints(f);if name=='RebornTGWarriorLarge'or name=='RebornClassicTalentLargePanel'or name=='RebornClassicSpecHome'or name=='RebornClassicSpecTree'then bg:SetTexture(.025,.03,.038,1)else bg:SetTexture(ART..'GuideGrimoireTG6B_blp')end
 if name~='RebornClassicSpecHome'and name~='RebornClassicSpecTree'then RebornTalentGuideTheme.Surface(f,bg,name=='RebornTalentCollectionFrame')end
 local bar=f:CreateTexture(nil,'BORDER');bar:SetPoint('TOPLEFT',5,-5);bar:SetSize(1284,25);bar:SetTexture(.055,.06,.065,1)
 f.title=C.Text(f,18,-9,1150,title,'GameFontNormal');f.note=C.Text(f,34,-665,1220,'')
 local close=CreateFrame('Button',nil,f,'UIPanelCloseButton');close:SetPoint('TOPRIGHT',-2,0);close:SetScript('OnClick',function()f:Hide()end)
 C.AttachScale(f,name);f:Hide();return f
end
function C.Fit(frame)
 local saved=RebornTGScaleDB and RebornTGScaleDB.windows and RebornTGScaleDB.windows[frame.rebornScaleKey]
 if type(saved)=='number'and saved==saved then frame:SetScale(math.max(.45,math.min(1.3,saved)))else local w,h=UIParent:GetWidth(),UIParent:GetHeight();frame:SetScale(math.min(1,math.max(.45,math.min((w-30)/frame:GetWidth(),(h-30)/frame:GetHeight()))))end
 C.RestorePosition(frame)
end
function C.Board(parent,x,y,w,h,title)
 local f=CreateFrame('Frame',nil,parent);f:SetPoint('TOPLEFT',x,y);f:SetSize(w,h);f:EnableMouse(true)
 f:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=12,insets={left=3,right=3,top=3,bottom=3}});f:SetBackdropColor(.025,.04,.055,1);f:SetBackdropBorderColor(.35,.31,.22,1)
 f.title=C.Text(f,14,-10,w-28,title,'GameFontNormal');f.canvas=CreateFrame('Frame',nil,f);f.canvas:SetPoint('TOPLEFT',10,-35);f.canvas:SetSize(w-20,h-45);f.width=w-20;f.height=h-45;f.buttons={};f.lines={};return f
end
local function line(board,index,x1,y1,x2,y2,on)
 local t=board.lines[index];if not t then t=board.canvas:CreateTexture(nil,'BORDER');board.lines[index]=t end
 t:ClearAllPoints();t:SetPoint('TOPLEFT',board.canvas,'TOPLEFT',math.min(x1,x2),-math.min(y1,y2));t:SetSize(math.max(2,math.abs(x2-x1)),math.max(2,math.abs(y2-y1)));t:SetTexture(on and .7 or .23,on and .55 or .27,on and .2 or .29,.9);t:Show()
end
function C.Paint(board,items,edges,options)
 options=options or{};local by={};for _,n in ipairs(items)do by[n.id]=n end
 local count=0
 for _,edge in ipairs(edges or{})do
  local a,b=by[edge[1]],by[edge[2]]
  if a and b then
   local mid=(a.y+b.y)/2;local on=(a.target or 0)>0 and(b.target or 0)>0
   count=count+1;line(board,count,a.x,a.y,a.x,mid,on)
   count=count+1;line(board,count,a.x,mid,b.x,mid,on)
   count=count+1;line(board,count,b.x,mid,b.x,b.y,on)
  end
 end
 for i=count+1,#board.lines do board.lines[i]:Hide()end
 for i,n in ipairs(items)do
  local b=board.buttons[i]
  if not b then
   b=CreateFrame('Button',nil,board.canvas);b:EnableMouse(true)
   b.icon=b:CreateTexture(nil,'ARTWORK');b.icon:SetPoint('CENTER');b.border=b:CreateTexture(nil,'OVERLAY');b.border:SetPoint('CENTER')
   b.rankBox=CreateFrame('Frame',nil,b);b.rankBox:SetSize(32,15);b.rankBox:SetPoint('BOTTOM',b,'BOTTOM',0,-5);b.rankBox:SetFrameLevel(b:GetFrameLevel()+2)
   b.rankBg=b.rankBox:CreateTexture(nil,'BACKGROUND');b.rankBg:SetAllPoints();b.rankBg:SetTexture(.015,.02,.025,.98)
   b.rank=b.rankBox:CreateFontString(nil,'OVERLAY','GameFontNormalSmall');b.rank:SetAllPoints();b.rank:SetFont(STANDARD_TEXT_FONT or'Fonts\\FRIZQT__.TTF',12,'OUTLINE');b.rank:SetJustifyH('CENTER')
   b.actualBox=CreateFrame('Frame',nil,b);b.actualBox:SetSize(17,15);b.actualBox:SetPoint('TOPRIGHT',b,'TOPRIGHT',7,5);b.actualBox:SetFrameLevel(b:GetFrameLevel()+3)
   b.actualBg=b.actualBox:CreateTexture(nil,'BACKGROUND');b.actualBg:SetAllPoints();b.actualBg:SetTexture(.015,.08,.10,.98)
   b.actual=b.actualBox:CreateFontString(nil,'OVERLAY','GameFontHighlightSmall');b.actual:SetAllPoints();b.actual:SetFont(STANDARD_TEXT_FONT or'Fonts\\FRIZQT__.TTF',12,'OUTLINE');b.actual:SetJustifyH('CENTER')
   b:SetScript('OnEnter',function(self)
    local n=self.node;GameTooltip:SetOwner(self,'ANCHOR_RIGHT')
    if n.spell and GetSpellInfo(n.spell)then pcall(GameTooltip.SetHyperlink,GameTooltip,'spell:'..n.spell)else GameTooltip:SetText(n.name or tostring(n.id))end
    if n.tooltip then n.tooltip(GameTooltip,n)else
     GameTooltip:AddLine((n.name or'')..' · ID '..n.id,1,.85,.3,true)
     GameTooltip:AddLine('推荐 '..(n.target or 0)..'/'..n.maximum..'；当前 '..(n.actual==nil and'未同步'or n.actual),.7,.85,1,true)
    end
    GameTooltip:Show()
   end);b:SetScript('OnLeave',function()GameTooltip:Hide()end)
   b:SetScript('OnClick',function(self,button)if self.node.onClick then self.node.onClick(button)end end)
   board.buttons[i]=b
  end
  b.node=n;if options.edit then b:RegisterForClicks('LeftButtonUp','RightButtonUp')else b:RegisterForClicks('LeftButtonUp')end;local size=n.size or 38;b:ClearAllPoints();b:SetPoint('CENTER',board.canvas,'TOPLEFT',n.x,-n.y);b:SetSize(size,size);b.icon:SetSize(size-5,size-5);b.icon:SetTexture(n.icon)
  local target,actual=n.target or 0,n.actual;local active=options.current and(actual or 0)>0 or not options.current and target>0
  b.icon:SetDesaturated(not active);b.icon:SetVertexColor(active and 1 or .6,active and 1 or .6,active and 1 or .6,1)
  local state=active and'yellow'or'gray';local shape=n.shape or'square'
  if not C.Atlas(b.border,'talents-node-'..shape..'-'..state)then b.border:SetTexture('Interface\\Buttons\\UI-Quickslot2');b.border:SetTexCoord(0,1,0,1)end
  b.border:SetSize(size+9,size+9)
  b.rankBox:ClearAllPoints();if options.edit or options.captionBelow then b.rankBox:SetPoint('TOP',b,'BOTTOM',0,-6)else b.rankBox:SetPoint('BOTTOM',b,'BOTTOM',0,-5)end
  b.rank:SetText((options.current and(actual==nil and'—'or actual)or target)..'/'..n.maximum)
  b.rank:SetTextColor(1,active and .9 or 1,active and .25 or 1)
  b.actual:SetText(actual or'');b.actual:SetTextColor(.25,1,1);if not options.edit and not options.captionBelow and not options.current and actual and actual>0 then b.actualBox:Show()else b.actualBox:Hide()end
  b:Show()
 end
 for i=#items+1,#board.buttons do board.buttons[i]:Hide()end
 board.items,board.edges=items,edges
end

function C.WarriorArt(board,index)
 if not board.art then board.art=board:CreateTexture(nil,'BORDER');board.art:SetPoint('TOPLEFT',4,-4);board.art:SetPoint('BOTTOMRIGHT',-4,4)end
 board:SetBackdropColor(.02,.025,.035,0);board.art:SetTexture(ART..'WarriorTriptychTG6B_blp');board.art:SetTexCoord((index-1)/3,index/3,0,1);board.art:SetAlpha(.22);board.art:Show()
end

function C.ScrollTree(board,items,spread)
 if not board.scroll then
  board.scroll=CreateFrame('ScrollFrame',nil,board);board.scroll:SetPoint('TOPLEFT',10,-35)
  board.canvas:SetParent(board.scroll);board.canvas:ClearAllPoints();board.canvas:SetPoint('TOPLEFT');board.scroll:SetScrollChild(board.canvas)
  board.scroll:EnableMouseWheel(true);board.scroll:SetScript('OnMouseWheel',function(_,delta)
   if IsControlKeyDown()then return end
   board.offset=math.max(0,math.min(board.scrollMax or 0,(board.offset or 0)-delta*58));board.scroll:SetVerticalScroll(board.offset)
  end)
 end
 local minX,maxX,minY=1e9,-1e9,1e9
 for _,n in ipairs(items)do minX=math.min(minX,n.x);maxX=math.max(maxX,n.x);minY=math.min(minY,n.y)end
 local ordered={};for _,n in ipairs(items)do ordered[#ordered+1]=n end
 table.sort(ordered,function(a,b)return a.y==b.y and a.x<b.x or a.y<b.y end)
 local placed={};local bottom=0
 for _,n in ipairs(ordered)do
  if spread then n.x=25+(n.x-minX)*(board.width-50)/math.max(1,maxX-minX);n.y=30+(n.y-minY)*1.8;n.size=32 end
  for _,prev in ipairs(placed)do if math.abs(prev.x-n.x)<45 then n.y=math.max(n.y,prev.y+62)end end
  placed[#placed+1]=n;bottom=math.max(bottom,n.y+42)
 end
 board.canvas:SetSize(board.width,math.max(board.height,bottom));board.scroll:SetSize(board.width,board.height)
 board.scrollMax=math.max(0,bottom-board.height);board.offset=math.min(board.offset or 0,board.scrollMax);board.scroll:SetVerticalScroll(board.offset)
 if board.scrollMax>0 then board.title:SetText(board.title:GetText()..' · 滚轮')end
end
