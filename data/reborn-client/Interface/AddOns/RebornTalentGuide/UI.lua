local G=RebornTalentGuide
local D=RebornTalentGuideData
G.catalogClass='战士';G.category='PVE';G.classPage=1;G.planPage=1
local classes={'战士','圣骑士','猎人','潜行者','牧师','死亡骑士','萨满','法师','术士','德鲁伊','恶魔猎手','武僧','巫医'}
local treeNames={'武器','狂怒','防护'}
local function label(p,x,y,w,s,font)
 local f=p:CreateFontString(nil,'OVERLAY',font or'GameFontHighlightSmall');f:SetPoint('TOPLEFT',x,y);f:SetWidth(w);f:SetJustifyH('LEFT');f:SetText(s or'');return f
end
local function button(p,x,y,w,s,fn)
 return RebornTalentGuideTheme.Button(p,x,y,w,25,s,fn)
end
local function enabled(b,on)if on then b:Enable()else b:Disable()end end
local function detailText(p)
 local s=p.body..'\n\n雕文参考\n'..p.glyphs..'\n\n加点清单（本服适配）\n'
 for t,tree in ipairs(D.trees)do
  s=s..'\n'..treeNames[t]..'：\n'
  for i,x in ipairs(tree)do local n=p.ranks[t][i];if n>0 then s=s..'第'..x.row..'层 '..x.name..(x.changed and' *'or'')..' '..n..'/'..x.max..'\n'end end
 end
 return s..'\n来源与评价\n'..p.source..'\n适用建议，不作强度排名；无可核验使用人数，不展示人气数字。\n\n* 为本服与旧MultiBot静态表不同的节点。最终效果以本服说明和实测为准。'
end
-- MultiBot values may include edits not yet sent. Never call them confirmed server ranks.
function G.BotSnapshot()
 local f=MultiBot and MultiBot.talent
 if f and f.custom then return nil,'当前是MultiBot自定义草稿；点击原窗口 Talents 查看机器人实际加点'end
 if not f or f.class~='Warrior' then return nil,'当前机器人职业尚未适配推荐' end
 local ranks={}
 for t,tree in ipairs(D.trees)do
  local tab=f.frames and f.frames['Tab'..t];local byID={}
  for _,b in pairs(tab and tab.buttons or {})do
   local id=b.tips and b.tips[1] and tonumber(b.tips[1]:match('talent:(%d+)'))
   if id then byID[id]=b.value end
  end
  ranks[t]={}
  for i,x in ipairs(tree)do
   local n=byID[x.id]
   if type(n)~='number' or n<0 or n>x.max or n%1~=0 then return nil,'对照未完整匹配：'..x.name..'（TalentID '..x.id..'，读取 '..tostring(n)..'）；可应用整套方案后重新查询' end
   ranks[t][i]=n
  end
 end
 return ranks
end
function G.BotCheck()
 if G.catalogClass~='战士' or (G.category~='PVE' and G.category~='PVP') or not G.fromBot or not MultiBot or not MultiBot.talent or MultiBot.talent.name~=G.botName or MultiBot.talent.class~='Warrior' then return nil,'查看对象已改变，请重新打开机器人推荐' end
 local unit=MultiBot.toUnit and MultiBot.toUnit(G.botName)
 if not unit or not UnitExists(unit)then return nil,'机器人不在可核对的队伍中' end
 local _,class=UnitClass(unit)
 if class~='WARRIOR' or UnitLevel(unit)<80 then return nil,'当前方案仅支持80级战士机器人' end
 if UnitIsUnit(unit,'player') then return nil,'机器人入口不能应用到自己' end
 if InCombatLockdown() or UnitAffectingCombat(unit) or UnitIsDeadOrGhost(unit)then return nil,'请在自己和机器人脱战且机器人存活时应用' end
 -- Applying replaces the build; comparison completeness is not an eligibility requirement.
 if G.botSentUntil and GetTime()<G.botSentUntil then return nil,'指令已发送，请等待后重新查询机器人天赋核对' end
 return {name=G.botName,guid=UnitGUID(unit)}
end
function G.RequestBotRefresh()
 local m=MultiBot;local f=m and m.talent
 if not G.fromBot or not f or f.name~=G.botName then return end
 local unit=m.toUnit and m.toUnit(G.botName)
 if not unit or not UnitExists(unit) or not InspectUnit then G.Message('无法重新查询机器人，请靠近后打开其 Talents 页');return end
 if G.lastInspect and GetTime()-G.lastInspect<3 then return end
 G.lastInspect=GetTime();InspectUnit(unit)
 f.custom=false
 if m.auto and m.timer and m.timer.talent then
  m.timer.talent.elapsed=0;m.auto.talent=true
  G.snapshotAt=GetTime()+(m.timer.talent.interval or 2)+.5
  G.snapshotName=G.botName;G.snapshotGUID=UnitGUID(unit)
 end
 G.Message('已重新查询 '..G.botName..'；等待MultiBot刷新实际天赋，不读取自定义空白草稿。')
end
function G.SyncTick()
 local now=GetTime()
 if G.inspectAt and now>=G.inspectAt then G.inspectAt=nil;G.RequestBotRefresh()end
 if G.snapshotAt and now>=G.snapshotAt then
  G.snapshotAt=nil
  local unit=MultiBot and MultiBot.toUnit and MultiBot.toUnit(G.botName)
  if G.fromBot and G.botName==G.snapshotName and unit and UnitGUID(unit)==G.snapshotGUID and MultiBot.talent.name==G.botName then
   G.botRanks,G.botError=G.BotSnapshot();G.message=G.botError or '已更新机器人面板对照；请核对实际点数是否符合所选方案。';G.Refresh()
  end
 end
end
function G.BotCode(plan)
 local tabs={}
 for t,tree in ipairs(D.trees)do
  local rows={};for i,x in ipairs(tree)do rows[#rows+1]={row=x.row,col=x.col,n=plan.ranks[t][i]}end
  table.sort(rows,function(a,b)if a.row==b.row then return a.col<b.col else return a.row<b.row end end)
  local digits={};for _,x in ipairs(rows)do digits[#digits+1]=tostring(x.n)end;tabs[t]=table.concat(digits)
 end
 return table.concat(tabs,'-')
end
function G.ConfirmBot()
 local target,why=G.BotCheck();if not target then G.Message(why);return end
 local selected=G.selected;local code=G.BotCode(D.plans[selected])
 StaticPopupDialogs.REBORN_TG_BOT_APPLY={text='将「'..D.plans[selected].title..'」应用到战士机器人 '..target.name..'？服务器会重置该机器人的当前天赋并重新加点。不会修改你的角色；雕文需另行配置。',button1='确认应用到机器人',button2=CANCEL,timeout=0,whileDead=false,hideOnEscape=true,OnAccept=function()
  local now,err=G.BotCheck()
  if not now or now.name~=target.name or now.guid~=target.guid or G.selected~=selected then G.Message(err or'对象或方案已改变，请重新确认');return end
  G.botSentUntil=GetTime()+10;G.inspectAt=GetTime()+1.5
  SendChatMessage('talents apply '..code,'WHISPER',nil,target.name)
  G.Message('已向 '..target.name..' 发送应用指令；请重新打开该机器人的天赋核对。发送不代表应用成功。')
 end}
 StaticPopup_Show('REBORN_TG_BOT_APPLY')
end
function G.Refresh()
 if not G.frame then return end
 local ready=G.catalogClass=='战士' and (G.category=='PVE' or G.category=='PVP')
 for i,b in ipairs(G.classButtons)do if i>(G.classPage-1)*10 and i<=G.classPage*10 then b:Show()else b:Hide()end;b:SetText((b.className==G.catalogClass and'● 'or'')..b.className);b:SetNavSelected(b.className==G.catalogClass)end
 local visible={};for i,plan in ipairs(D.plans)do if ready and plan.category==G.category then visible[#visible+1]=i end end
 local selectedVisible=false;for _,i in ipairs(visible)do if i==G.selected then selectedVisible=true end end
 if ready and not selectedVisible then G.selected=visible[1]end
 G.classPageLabel:SetText(G.classPage..' / '..math.ceil(#classes/10))
 G.planPage=math.min(G.planPage,math.max(1,math.ceil(#visible/6)));G.planPageLabel:SetText(G.planPage..' / '..math.max(1,math.ceil(#visible/6)))
 for _,b in ipairs(G.plans)do b:Hide()end
 for pos,i in ipairs(visible)do if pos>(G.planPage-1)*6 and pos<=G.planPage*6 then local b=G.plans[i];b:ClearAllPoints();local L=G.layout;b:SetPoint('TOPLEFT',G.frame,'TOPLEFT',L.planX,L.planTop-((pos-1)%6)*L.planStep);b:Show()end end
 for _,b in ipairs(G.categoryButtons)do b:SetText((b.category==G.category and'● 'or'')..b.category)end
 for _,v in ipairs(G.treePanels)do if ready then v:Show()else v:Hide()end end
 if not ready then
  G.empty:Show();G.emptyText:SetText(G.catalogClass..' · '..G.category..'\n推荐方案待适配\n\n新职业将使用本服实际加点系统。\n不会显示战士方案或发送战士加点指令。')
  G.heading:SetText(G.catalogClass..' · 尚无可用方案');G.context:SetText('职业目录 · TG1F测试版')
  G.scroll:Hide();G.glyphPanel:Hide();G.url:SetText('');G.apply:Disable();G.stop:Disable();G.status:SetText('请选择战士测试三系全景和推荐应用。');return
 end
 G.empty:Hide()
 local p=D.plans[G.selected];local ranks,why
 if G.fromBot then ranks,why=G.botRanks,G.botError else ranks,why=G.Scan()end
 G.heading:SetText(p.title..'   '..p.split..' / 71点')
 G.context:SetText('本服战士参考 · 80级 · TG1F测试版 | '..(G.fromBot and('机器人 '..(G.botName or'?')..'：面板快照 / 推荐（可能含未提交编辑）')or'自己的当前专精对照'))
 for i,b in ipairs(G.plans)do b:SetText((i==G.selected and'> 'or'')..D.plans[i].title..'\n'..D.plans[i].split);enabled(b,not G.job)end
 for t,tree in ipairs(D.trees)do local sum=0;for _,n in ipairs(p.ranks[t])do sum=sum+n end;G.treeTitles[t]:SetText(treeNames[t]..' · 推荐 '..sum..' 点')end
 for _,b in ipairs(G.nodes)do
  local i,t=b.index,b.tree;local x=D.trees[t][i]
  if x then
   b.data=x;local L=G.layout;b:SetPoint('TOPLEFT',G.treePanels[t],'TOPLEFT',L.nodeX+(x.col-1)*L.colStep,L.nodeY-(x.row-1)*L.rowStep)
   local name,_,icon=GetSpellInfo(x.spells[1]);b.icon:SetTexture(icon or x.icon)
   local target=p.ranks[t][i];b.icon:SetDesaturated(target==0)
   b.rank:SetText(target..'/'..x.max);b.current:SetText('现 '..(ranks and tostring(ranks[t][i])or'—'))
   b.rank:SetTextColor(target>0 and 1 or .6,target>0 and .85 or .6,.35)
   b.star:SetText(x.changed and'*'or'');b:Show()
  else b:Hide()end
 end
 G.description:SetText(detailText(p));G.content:SetHeight(math.max(394,G.description:GetStringHeight()+16));if G.scroll.UpdateScrollChildRect then G.scroll:UpdateScrollChildRect()end
 local installed={};local _,class=UnitClass('player')
 if G.Evidence then installed=G.Evidence.Sockets('WARRIOR').installed elseif not G.fromBot and class=='WARRIOR'and GetGlyphSocketInfo then for i=1,6 do local _,_,id=GetGlyphSocketInfo(i,GetActiveTalentGroup(false,false));if id then installed[id]=true end end end
 for i,b in ipairs(G.glyphRows)do
  local x=p.glyphList[i];b.data=x;local _,_,icon=GetSpellInfo(x.spell);b.icon:SetTexture(icon or'Interface\\Icons\\INV_Glyph_MajorWarrior')
  b.name:SetText(x.kind..' · '..x.name..(installed[x.spell]and' |cff77ff77已装|r'or''));b.why:SetText(x.why)
 end
 if G.showGlyphs then G.scroll:Hide();G.glyphPanel:Show()else G.scroll:Show();G.glyphPanel:Hide()end
 if G.tabDesc then G.tabDesc:SetNavSelected(not G.showGlyphs);G.tabGlyph:SetNavSelected(G.showGlyphs and true or false)end
 G.url:SetText(p.url)
 local job,err;if G.fromBot then job,err=G.BotCheck()else job,err=G.Check(p)end;G.apply:SetText(G.fromBot and('应用到机器人 '..(G.botName or'?'))or'应用到自己的当前专精');enabled(G.apply,not G.job and job~=nil);enabled(G.stop,G.job~=nil)
 G.status:SetText(G.message or why or err or (G.fromBot and '应用会重置该机器人当前天赋；雕文仅参考。当前数值来自MultiBot面板。') or '可查看方案并补齐加点；应用前会再次核对自己的当前专精')
end
-- RebornWOW TGL1A/TGL1B/TGL1C: compact, aligned layout (1220x680, was 1410x760). Four
-- regions with one margin system: left navigation (classes | categories and
-- plans), three talent trees, right description/glyph panel. Logic unchanged.
local W,H=1220,680
local M=14                       -- outer margin
local NAV_X,NAV_W=M,270          -- left navigation
local CLS_W=110                  -- class column inside the navigation
local PLAN_X=NAV_X+CLS_W+10      -- category/plan column
local PLAN_W=NAV_W-CLS_W-10
local TREE_X,TREE_W,TREE_GAP=NAV_X+NAV_W+12,196,6
local SIDE_X=TREE_X+3*TREE_W+2*TREE_GAP+12
local SIDE_W=W-SIDE_X-M
local TOP=96                     -- top of the content row
G.layout={W=W,H=H,planX=PLAN_X,planTop=-206,planStep=44,nodeX=12,nodeY=-40,colStep=45,rowStep=46}
local function divider(p,x,y,w)
 local t=p:CreateTexture(nil,'ARTWORK');t:SetTexture(.85,.65,.22,.35);t:SetPoint('TOPLEFT',x,y);t:SetSize(w,1);return t
end
local function section(p,x,y,w,text)
 local l=label(p,x,y,w,text,'GameFontNormal');l:SetTextColor(1,.82,.3);divider(p,x,y-16,w);return l
end
function G.Create()
 if G.frame then return end
 local f=CreateFrame('Frame','RebornTalentGuideFrame',UIParent);G.frame=f;f:SetSize(W,H);f:SetPoint('CENTER');f:SetFrameStrata('DIALOG');f:SetClampedToScreen(true)
 f:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',tile=true,tileSize=32,edgeSize=24,insets={left=6,right=6,top=6,bottom=6}});f:SetBackdropColor(.03,.04,.06,.97)
 f:SetMovable(true);f:EnableMouse(true);f:RegisterForDrag('LeftButton');f:SetScript('OnDragStart',function(self)self:StartMoving()end);f:SetScript('OnDragStop',function(self)self:StopMovingOrSizing()end)
 f:SetScale(math.min(1,(UIParent:GetWidth()-24)/W,(UIParent:GetHeight()-24)/H))
 local art=f:CreateTexture(nil,'BORDER');art:SetPoint('TOPLEFT',8,-8);art:SetPoint('BOTTOMRIGHT',-8,8);art:SetTexture('Interface\\AddOns\\RebornTalentGuide\\Art\\GuideGrimoireTG6B_blp');art:SetTexCoord(0,1,0,1);RebornTalentGuideTheme.Surface(f,art,true)
 table.insert(UISpecialFrames,'RebornTalentGuideFrame')
 local close=CreateFrame('Button',nil,f,'UIPanelCloseButton');close:SetPoint('TOPRIGHT',-6,-5)
 -- Header
 local titleText=label(f,M+6,-16,700,'天赋与雕文推荐 · 职业图鉴','GameFontNormalLarge');titleText:SetTextColor(1,.82,.3);G.titleText=titleText
 G.context=label(f,M+6,-40,900,'');G.context:SetTextColor(.72,.74,.78)
 divider(f,M,-60,W-2*M)
 local function nav(x,y,w,text,fn)
  return RebornTalentGuideTheme.Button(f,x,y,w,24,text,fn)
 end
 -- Left navigation: classes
 G.classButtons={};section(f,NAV_X,-70,CLS_W,'职业')
 for i,name in ipairs(classes)do
  local b=nav(NAV_X,-94-((i-1)%10)*28,CLS_W,name,function()if G.job then G.Stop()end;G.catalogClass=name;G.planPage=1;G.message=nil;G.Refresh()end)
  b.className=name;G.classButtons[i]=b
 end
 nav(NAV_X,-382,28,'<',function()G.classPage=math.max(1,G.classPage-1);G.Refresh()end)
 nav(NAV_X+CLS_W-28,-382,28,'>',function()G.classPage=math.min(math.ceil(#classes/10),G.classPage+1);G.Refresh()end)
 G.classPageLabel=label(f,NAV_X+30,-388,CLS_W-60,'');G.classPageLabel:SetJustifyH('CENTER')
 -- Left navigation: categories and plans
 section(f,PLAN_X,-70,PLAN_W,'推荐分类');G.categoryButtons={}
 local catW=math.floor((PLAN_W-4)/2)
 for i,name in ipairs({'PVE','PVP','其他','我的收藏','统计推荐'})do
  local category=name;local x=PLAN_X+((i-1)%2)*(catW+4);local y=-94-math.floor((i-1)/2)*28
  local b=nav(x,y,catW,name,function()if G.job then G.Stop()end;G.category=category;G.planPage=1;G.message=nil;G.Refresh()end);b.category=name;G.categoryButtons[i]=b
 end
 section(f,PLAN_X,-182,PLAN_W,'方案')
 G.plans={};for i,p in ipairs(D.plans)do local n=i;local b=nav(PLAN_X,G.layout.planTop,PLAN_W,p.title,function()G.selected=n;G.category=D.plans[n].category;G.message=nil;G.scroll:SetVerticalScroll(0);G.Refresh()end);b:SetHeight(40);G.plans[i]=b end
 G.planPrev=nav(PLAN_X,-472,28,'<',function()G.planPage=math.max(1,G.planPage-1);G.Refresh()end)
 G.planNext=nav(PLAN_X+PLAN_W-28,-472,28,'>',function()G.planPage=G.planPage+1;G.Refresh()end)
 G.planPageLabel=label(f,PLAN_X+30,-478,PLAN_W-60,'');G.planPageLabel:SetJustifyH('CENTER')
 local legend=label(f,NAV_X,-508,NAV_W,'|cffffd24d金字|r 推荐 / 上限    |cffbfc7d0灰字|r 当前点数    |cffff8040*|r 本服改动\n不同职业采用各自点数与保存规则。');legend:SetTextColor(.7,.72,.76)
 -- Center: three trees
 G.heading=label(f,TREE_X,-70,3*TREE_W+2*TREE_GAP,'','GameFontNormal');G.heading:SetTextColor(1,.82,.3)
 G.treePanels={};G.treeTitles={}
 for t=1,3 do
  local panel=CreateFrame('Frame',nil,f);panel:SetPoint('TOPLEFT',TREE_X+(t-1)*(TREE_W+TREE_GAP),-TOP);panel:SetSize(TREE_W,H-TOP-M-10)
  panel:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=12,insets={left=3,right=3,top=3,bottom=3}});panel:SetBackdropColor(.02,.045,.065,.94);panel:SetBackdropBorderColor(.55,.44,.22,1)
  G.treePanels[t]=panel;G.treeTitles[t]=label(panel,10,-10,TREE_W-20,treeNames[t],'GameFontNormal');G.treeTitles[t]:SetJustifyH('CENTER')
  local d=panel:CreateTexture(nil,'ARTWORK');d:SetTexture(.85,.65,.22,.3);d:SetPoint('TOPLEFT',10,-28);d:SetSize(TREE_W-20,1)
 end
 G.empty=CreateFrame('Frame',nil,f);G.empty:SetPoint('TOPLEFT',TREE_X,-TOP);G.empty:SetSize(3*TREE_W+2*TREE_GAP,H-TOP-M-10)
 G.emptyText=label(G.empty,24,-100,3*TREE_W-40,'','GameFontNormalLarge')
 G.nodes={}
 for t,tree in ipairs(D.trees)do for i,x in ipairs(tree)do
  local b=CreateFrame('Button',nil,G.treePanels[t]);b:SetSize(32,32);b.tree=t;b.index=i
  b.icon=b:CreateTexture(nil,'ARTWORK');b.icon:SetAllPoints();b.icon:SetTexCoord(.07,.93,.07,.93);b:SetHighlightTexture('Interface\\Buttons\\ButtonHilight-Square','ADD')
  local edge=b:CreateTexture(nil,'BACKGROUND');edge:SetPoint('TOPLEFT',-1,1);edge:SetPoint('BOTTOMRIGHT',1,-1);edge:SetTexture(.55,.44,.22,.9)
  local badge=b:CreateTexture(nil,'OVERLAY');badge:SetPoint('BOTTOM',b,'BOTTOM',0,-1);badge:SetSize(30,13);badge:SetTexture(0,0,0,.8)
  b.rank=label(b,-4,-19,40,'');b.rank:SetFont(STANDARD_TEXT_FONT,12,'OUTLINE');b.rank:SetJustifyH('CENTER')
  b.current=label(b,-6,-33,44,'');b.current:SetFont(STANDARD_TEXT_FONT,9,'OUTLINE');b.current:SetJustifyH('CENTER');b.current:SetTextColor(.70,.75,.80)
  b.star=label(b,24,5,16,'','GameFontNormal')
  b:SetScript('OnEnter',function(self)
   local x=self.data;GameTooltip:SetOwner(self,'ANCHOR_RIGHT')
   local n=D.plans[G.selected].ranks[self.tree][self.index];local id=x.spells[math.max(1,n)]
   if GetSpellInfo(id)then pcall(GameTooltip.SetHyperlink,GameTooltip,'spell:'..id)else GameTooltip:SetText(x.name)end
   GameTooltip:AddLine('推荐 '..n..' / '..x.max..'；第'..x.row..'层，第'..x.col..'列',1,.85,.3)
   if x.dep~=0 then for _,r in ipairs(D.trees[self.tree])do if r.id==x.dep then GameTooltip:AddLine('前置：'..r.name..' '..x.depRank..'点',.8,.85,1,true)end end end
   if x.changed then GameTooltip:AddLine('本服改动节点；此处使用本服技能，不能直接套用原版循环。',1,.45,.3,true)end
   GameTooltip:Show()
  end);b:SetScript('OnLeave',function()GameTooltip:Hide()end);G.nodes[#G.nodes+1]=b
 end end
 -- Right: description / glyphs
 local tabW=math.floor((SIDE_W-4)/2)
 G.tabDesc=nav(SIDE_X,-TOP,tabW,'方案说明 / 加点清单',function()G.showGlyphs=false;G.Refresh()end);G.tabDesc:SetHeight(26)
 G.tabGlyph=nav(SIDE_X+tabW+4,-TOP,tabW,'雕文推荐 / 已装对照',function()G.showGlyphs=true;G.Refresh()end);G.tabGlyph:SetHeight(26)
 local side=CreateFrame('Frame',nil,f);side:SetPoint('TOPLEFT',SIDE_X,-(TOP+30));side:SetSize(SIDE_W,410)
 side:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=12,insets={left=3,right=3,top=3,bottom=3}});side:SetBackdropColor(.02,.045,.065,.94);side:SetBackdropBorderColor(.55,.44,.22,1)
 local scroll=CreateFrame('ScrollFrame','RebornTalentGuideScroll',side,'UIPanelScrollFrameTemplate');G.scroll=scroll;scroll:SetPoint('TOPLEFT',8,-8);scroll:SetSize(SIDE_W-34,394)
 local content=CreateFrame('Frame',nil,scroll);G.content=content;content:SetSize(SIDE_W-36,900);scroll:SetScrollChild(content)
 G.description=label(content,2,-2,SIDE_W-40,'');G.description:SetFont(STANDARD_TEXT_FONT,12,'');G.description:SetSpacing(3)
 local gp=CreateFrame('Frame',nil,side);G.glyphPanel=gp;gp:SetPoint('TOPLEFT',8,-8);gp:SetSize(SIDE_W-16,394);G.glyphRows={}
 for i=1,6 do
  local b=CreateFrame('Button',nil,gp);b:SetPoint('TOPLEFT',0,-(i-1)*66);b:SetSize(SIDE_W-16,62)
  b.icon=b:CreateTexture(nil,'ARTWORK');b.icon:SetPoint('TOPLEFT',2,-4);b.icon:SetSize(28,28);b.icon:SetTexCoord(.07,.93,.07,.93)
  b.name=label(b,38,-4,SIDE_W-60,'','GameFontNormalSmall');b.why=label(b,38,-22,SIDE_W-60,'');b.why:SetHeight(38)
  if i<6 then local d=b:CreateTexture(nil,'ARTWORK');d:SetTexture(.85,.65,.22,.18);d:SetPoint('BOTTOMLEFT',0,0);d:SetSize(SIDE_W-16,1)end
  b:SetScript('OnEnter',function(self)GameTooltip:SetOwner(self,'ANCHOR_LEFT');if GetSpellInfo(self.data.spell)then pcall(GameTooltip.SetHyperlink,GameTooltip,'spell:'..self.data.spell)else GameTooltip:SetText(self.data.name)end;GameTooltip:AddLine('推荐清单：不会自动安装、购买或消耗雕文。',1,.8,.3,true);GameTooltip:Show()end)
  b:SetScript('OnLeave',function()GameTooltip:Hide()end);G.glyphRows[i]=b
 end
 local urlLabel=label(f,SIDE_X,-(TOP+448),SIDE_W,'攻略链接（点击后 Ctrl+C 复制）');urlLabel:SetTextColor(.72,.74,.78)
 local url=CreateFrame('EditBox',nil,f,'InputBoxTemplate');G.url=url;url:SetPoint('TOPLEFT',SIDE_X+6,-(TOP+466));url:SetSize(SIDE_W-8,20);url:SetAutoFocus(false);url:SetFontObject('GameFontHighlightSmall');url:SetScript('OnEscapePressed',function(self)self:ClearFocus()end);url:SetScript('OnMouseUp',function(self)self:HighlightText()end)
 G.status=label(f,SIDE_X,-(TOP+496),SIDE_W,'');G.status:SetHeight(48);G.status:SetTextColor(.85,.85,.85)
 -- Bottom-left actions
 local by=-(H-M-10-3*28+4)
 G.apply=button(f,NAV_X,by,NAV_W,'应用到自己的当前专精',function()
  if G.catalogClass~='战士' or (G.category~='PVE' and G.category~='PVP')then return end
  if G.fromBot then G.ConfirmBot();return end
  local epoch=G.Lifecycle and G.Lifecycle.epoch or 0;local guid=UnitGUID('player');local chosen=G.selected;local check,why=G.Check(D.plans[chosen]);if not check then G.Message(why);return end
  StaticPopupDialogs.REBORN_TG_APPLY={text='补齐自己的当前专精为「'..D.plans[chosen].title..'」？将花费 '..#check.rows..' 点。不会洗点或安装雕文；中途停止时已加点保留。',button1=ACCEPT,button2=CANCEL,timeout=0,whileDead=false,hideOnEscape=true,OnAccept=function()
   if(G.Lifecycle and not G.Lifecycle.Current(epoch))or G.catalogClass~='战士'or G.fromBot or G.selected~=chosen or UnitGUID('player')~=guid then G.Message('角色或推荐状态已改变，请重新确认');return end
   local current,reason=G.Check(D.plans[chosen]);local same=current and current.group==check.group
   if same then for t,row in ipairs(check.ranks)do for i,rank in ipairs(row)do if current.ranks[t][i]~=rank then same=false end end end end
   if not same then G.Message(reason or'点数或专精已改变，请重新确认');return end
   G.Start(chosen)
  end}
  StaticPopup_Show('REBORN_TG_APPLY')
 end)
 G.stop=button(f,NAV_X,by-28,NAV_W,'停止后续加点',function()G.Stop()end)
 button(f,NAV_X,by-56,NAV_W,'刷新当前点数',function()G.message=nil;if G.fromBot then G.RequestBotRefresh()else G.Refresh()end end)
 f:SetScript('OnHide',function()if G.job then G.Stop('窗口已关闭，后续加点停止；已完成点数保留')end end)
 f:Hide()
end
function G.Open(fromBot)
 if G.job then G.Stop('切换参考对象，停止后续加点')end
 G.fromBot=fromBot;G.catalogClass='战士';G.category=D.plans[G.selected].category;G.message=nil;G.inspectAt=nil;G.snapshotAt=nil
 if fromBot then G.botRanks,G.botError=G.BotSnapshot();G.botName=MultiBot and MultiBot.talent and MultiBot.talent.name end
 G.Create();G.frame:Show();G.frame:Raise();G.Refresh()
end
local function entry(parent,bot)
 local _,class=UnitClass('player')
 if (bot and (not MultiBot or MultiBot.talent.class~='Warrior'))or(not bot and class~='WARRIOR'and not(G.WD and G.WD.IsDoctor()))then
  StaticPopupDialogs.REBORN_TG_UNSUPPORTED={text='当前职业尚未适配推荐。巫医等新职业需要单独接入其加点系统。要浏览战士参考方案吗？',button1='浏览战士参考',button2=CANCEL,timeout=0,whileDead=true,hideOnEscape=true,OnAccept=function()G.Open(bot)end}
  StaticPopup_Show('REBORN_TG_UNSUPPORTED');return
 end
 G.Open(bot)
end
local function attach(parent,bot)
 if not parent or parent.rebornTalentGuideButton then return end
 if bot then
  parent:SetMovable(true)
  local drag=CreateFrame('Frame',nil,parent);parent.rebornTalentGuideDrag=drag
  drag:SetPoint('BOTTOMLEFT',parent,'BOTTOMLEFT',100,982);drag:SetSize(435,23)
  drag:SetFrameLevel(parent:GetFrameLevel()+9);drag:EnableMouse(true);drag:RegisterForDrag('LeftButton','RightButton')
  drag:SetScript('OnDragStart',function()parent:StartMoving()end)
  drag:SetScript('OnDragStop',function()parent:StopMovingOrSizing()end)
  drag:SetScript('OnHide',function()parent:StopMovingOrSizing()end)
  drag:SetScript('OnEnter',function(self)GameTooltip:SetOwner(self,'ANCHOR_TOP');GameTooltip:SetText('按住标题左键或右键拖动机器人天赋窗口');GameTooltip:Show()end)
  drag:SetScript('OnLeave',function()GameTooltip:Hide()end)
 end
 local b=CreateFrame('Button',nil,parent,'UIPanelButtonTemplate');parent.rebornTalentGuideButton=b
 if bot then
  -- MultiBot's visible panel is the left half of its 1024px canvas.
  local copy=parent.buttons and MultiBot.info and MultiBot.info.talent and parent.buttons[MultiBot.info.talent.Copy]
  if copy then b:SetPoint('LEFT',copy,'RIGHT',10,0)else b:SetPoint('BOTTOMRIGHT',parent,'BOTTOMRIGHT',-720,966)end
 else b:SetPoint('TOPRIGHT',parent,'TOPRIGHT',-38,-35)end
 b:SetSize(140,24);b:SetText('天赋/雕文参考');b:EnableMouse(true);b:RegisterForClicks('LeftButtonUp')
 local function layer()b:SetFrameLevel(parent:GetFrameLevel()+10)end
 layer();b:HookScript('OnShow',layer)
 b:SetScript('OnClick',function()
  local ok,err=pcall(entry,parent,bot)
  if not ok then print('|cffff6060[天赋推荐] 打开失败：'..tostring(err)..'|r')end
 end)
end
function G.Attach()attach(PlayerTalentFrame,false);if MultiBot then attach(MultiBot.talent,true)end end
SLASH_REBORNTALENTGUIDE1='/rtalent';SLASH_REBORNTALENTGUIDE2='/天赋推荐';SlashCmdList.REBORNTALENTGUIDE=function()G.Open(false)end
local events=CreateFrame('Frame');events:RegisterEvent('ADDON_LOADED');events:RegisterEvent('PLAYER_LOGIN');events:RegisterEvent('PLAYER_TALENT_UPDATE');events:RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED');events:RegisterEvent('PLAYER_REGEN_DISABLED');events:RegisterEvent('GLYPH_UPDATED');events:RegisterEvent('GLYPH_ADDED');events:RegisterEvent('GLYPH_REMOVED')
events:SetScript('OnEvent',function(_,event)
 G.Attach()
 if G.job and(event=='ACTIVE_TALENT_GROUP_CHANGED'or event=='PLAYER_REGEN_DISABLED')then G.Stop('专精或战斗状态改变，停止后续加点')end
 if G.frame and G.frame:IsShown()then G.Refresh()end
end)
local elapsed=0;events:SetScript('OnUpdate',function(_,dt)elapsed=elapsed+dt;if elapsed<.2 then return end;elapsed=0;G.Tick();G.SyncTick()end)
G.Attach()
