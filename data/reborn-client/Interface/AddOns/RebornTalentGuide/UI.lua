local G=RebornTalentGuide
local D=RebornTalentGuideData
G.catalogClass='战士';G.category='PVE';G.classPage=1;G.planPage=1
local classes={'战士','圣骑士','猎人','潜行者','牧师','死亡骑士','萨满','法师','术士','德鲁伊','恶魔猎手','武僧','巫医'}
local treeNames={'武器','狂怒','防护'}
local function label(p,x,y,w,s,font)
 local f=p:CreateFontString(nil,'OVERLAY',font or'GameFontHighlightSmall');f:SetPoint('TOPLEFT',x,y);f:SetWidth(w);f:SetJustifyH('LEFT');f:SetText(s or'');return f
end
local function button(p,x,y,w,s,fn)
 local b=CreateFrame('Button',nil,p,'UIPanelButtonTemplate');b:SetPoint('TOPLEFT',x,y);b:SetSize(w,25);b:SetText(s);b:SetScript('OnClick',fn);return b
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
 for pos,i in ipairs(visible)do if pos>(G.planPage-1)*6 and pos<=G.planPage*6 then local b=G.plans[i];b:ClearAllPoints();b:SetPoint('TOPLEFT',G.frame,'TOPLEFT',160,-218-((pos-1)%6)*54);b:Show()end end
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
   b.data=x;b:SetPoint('TOPLEFT',G.treePanels[t],'TOPLEFT',14+(x.col-1)*47,-42-(x.row-1)*50)
   local name,_,icon=GetSpellInfo(x.spells[1]);b.icon:SetTexture(icon or x.icon)
   local target=p.ranks[t][i];b.icon:SetDesaturated(target==0)
   b.rank:SetText(target..'/'..x.max);b.current:SetText('现 '..(ranks and tostring(ranks[t][i])or'—'))
   b.rank:SetTextColor(target>0 and 1 or .6,target>0 and .85 or .6,.35)
   b.star:SetText(x.changed and'*'or'');b:Show()
  else b:Hide()end
 end
 G.description:SetText(detailText(p));G.content:SetHeight(math.max(475,G.description:GetStringHeight()+16))
 local installed={};local _,class=UnitClass('player')
 if not G.fromBot and class=='WARRIOR'and GetGlyphSocketInfo then for i=1,6 do local _,_,id=GetGlyphSocketInfo(i,GetActiveTalentGroup(false,false));if id then installed[id]=true end end end
 for i,b in ipairs(G.glyphRows)do
  local x=p.glyphList[i];b.data=x;local _,_,icon=GetSpellInfo(x.spell);b.icon:SetTexture(icon or'Interface\\Icons\\INV_Glyph_MajorWarrior')
  b.name:SetText(x.kind..' · '..x.name..(installed[x.spell]and' |cff77ff77已装|r'or''));b.why:SetText(x.why)
 end
 if G.showGlyphs then G.scroll:Hide();G.glyphPanel:Show()else G.scroll:Show();G.glyphPanel:Hide()end
 G.url:SetText(p.url)
 local job,err;if G.fromBot then job,err=G.BotCheck()else job,err=G.Check(p)end;G.apply:SetText(G.fromBot and('应用到机器人 '..(G.botName or'?'))or'应用到自己的当前专精');enabled(G.apply,not G.job and job~=nil);enabled(G.stop,G.job~=nil)
 G.status:SetText(G.message or why or err or (G.fromBot and '应用会重置该机器人当前天赋；雕文仅参考。当前数值来自MultiBot面板。') or '可查看方案并补齐加点；应用前会再次核对自己的当前专精')
end
function G.Create()
 if G.frame then return end
 local f=CreateFrame('Frame','RebornTalentGuideFrame',UIParent);G.frame=f;f:SetSize(1410,760);f:SetPoint('CENTER');f:SetFrameStrata('DIALOG');f:SetClampedToScreen(true)
 f:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\DialogFrame\\UI-DialogBox-Border',tile=true,tileSize=32,edgeSize=24,insets={left=6,right=6,top=6,bottom=6}});f:SetBackdropColor(.035,.045,.065,1)
 f:SetMovable(true);f:EnableMouse(true);f:RegisterForDrag('LeftButton');f:SetScript('OnDragStart',function(self)self:StartMoving()end);f:SetScript('OnDragStop',function(self)self:StopMovingOrSizing()end)
 f:SetScale(math.min(1,(UIParent:GetWidth()-24)/1410,(UIParent:GetHeight()-24)/760))
 local art=f:CreateTexture(nil,'BACKGROUND');art:SetPoint('TOPLEFT',8,-8);art:SetPoint('BOTTOMRIGHT',-8,8);art:SetTexture('Interface\\AddOns\\RebornTalentGuide\\Art\\Backdrop');art:SetTexCoord(0,1,170/1024,853/1024);art:SetAlpha(.35)
 table.insert(UISpecialFrames,'RebornTalentGuideFrame')
 local close=CreateFrame('Button',nil,f,'UIPanelCloseButton');close:SetPoint('TOPRIGHT',-6,-5)
 label(f,20,-18,850,'天赋与雕文推荐 · 职业图鉴','GameFontNormalLarge')
 G.context=label(f,20,-45,900,'')
 local function nav(x,y,w,text,fn)
  -- No UIPanelButtonTemplate: its inherited segmented regions cover custom backgrounds.
  local b=CreateFrame('Button',nil,f);b:SetPoint('TOPLEFT',x,y);b:SetSize(w,25)
  b:SetNormalFontObject(GameFontNormal);b:SetHighlightFontObject(GameFontHighlight);b:SetDisabledFontObject(GameFontDisable)
  b:SetText(text);b:SetScript('OnClick',fn)
  local bg=b:CreateTexture(nil,'BACKGROUND');bg:SetAllPoints(b);bg:SetTexture(.42,.055,.065,1)
  b.navBackground=bg
  b:SetBackdrop({edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=10})
  b:SetBackdropBorderColor(.60,.43,.20,1)
  local hi=b:CreateTexture(nil,'HIGHLIGHT');hi:SetAllPoints(b);hi:SetTexture(1,.65,.20,.16);b:SetHighlightTexture(hi)
  function b:SetNavSelected(on)
   self.navBackground:SetTexture(on and .60 or .42,.055,.065,1)
   self:SetBackdropBorderColor(on and 1 or .60,on and .82 or .43,on and .25 or .20,1)
  end
  return b
 end
 G.classButtons={};label(f,20,-74,132,'职业选择','GameFontNormal')
 for i,name in ipairs(classes)do
  local b=nav(18,-108-((i-1)%10)*34,130,name,function()if G.job then G.Stop()end;G.catalogClass=name;G.planPage=1;G.message=nil;G.Refresh()end)
  b.className=name;G.classButtons[i]=b
 end
 nav(18,-461,35,'<',function()G.classPage=math.max(1,G.classPage-1);G.Refresh()end)
 nav(113,-461,35,'>',function()G.classPage=math.min(math.ceil(#classes/10),G.classPage+1);G.Refresh()end)
 G.classPageLabel=label(f,60,-467,50,'')
 label(f,164,-74,180,'推荐天赋选择','GameFontNormal');G.categoryButtons={}
 for i,name in ipairs({'PVE','PVP','其他','我的收藏','统计推荐'})do
  local category=name;local x=160+((i-1)%2)*90;local y=-105-math.floor((i-1)/2)*33
  local b=nav(x,y,86,name,function()if G.job then G.Stop()end;G.category=category;G.planPage=1;G.message=nil;G.Refresh()end);b.category=name;G.categoryButtons[i]=b
 end
 G.plans={};for i,p in ipairs(D.plans)do local n=i;local b=nav(160,-218,176,p.title,function()G.selected=n;G.category=D.plans[n].category;G.message=nil;G.scroll:SetVerticalScroll(0);G.Refresh()end);b:SetHeight(46);G.plans[i]=b end
 nav(160,-562,35,'<',function()G.planPage=math.max(1,G.planPage-1);G.Refresh()end)
 nav(301,-562,35,'>',function()G.planPage=G.planPage+1;G.Refresh()end)
 G.planPageLabel=label(f,222,-568,65,'')
 label(f,164,-603,175,'金字：推荐 / 上限\n灰字：当前点数\n星号：本服改动\n其他职业方案待适配。')
 G.heading=label(f,370,-76,1010,'','GameFontNormal')
 G.treePanels={};G.treeTitles={}
 for t=1,3 do
  local panel=CreateFrame('Frame',nil,f);panel:SetPoint('TOPLEFT',364+(t-1)*208,-107);panel:SetSize(204,603)
  panel:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=12});panel:SetBackdropColor(.025,.055,.075,.96);panel:SetBackdropBorderColor(.48,.40,.23,1)
  G.treePanels[t]=panel;G.treeTitles[t]=label(panel,12,-15,180,treeNames[t],'GameFontNormal')
 end
 G.empty=CreateFrame('Frame',nil,f);G.empty:SetPoint('TOPLEFT',370,-115);G.empty:SetSize(990,520)
 G.emptyText=label(G.empty,24,-100,960,'','GameFontNormalLarge')
 G.nodes={}
 for t,tree in ipairs(D.trees)do for i,x in ipairs(tree)do
  local b=CreateFrame('Button',nil,G.treePanels[t]);b:SetSize(34,34);b.tree=t;b.index=i
  b.icon=b:CreateTexture(nil,'ARTWORK');b.icon:SetAllPoints();b:SetHighlightTexture('Interface\\Buttons\\ButtonHilight-Square','ADD')
  local badge=b:CreateTexture(nil,'OVERLAY');badge:SetPoint('BOTTOMLEFT',-2,-2);badge:SetSize(38,15);badge:SetTexture(0,0,0,1)
  b.rank=label(b,-2,-21,38,'');b.rank:SetFont(STANDARD_TEXT_FONT,14,'OUTLINE');b.rank:SetJustifyH('CENTER')
  b.current=label(b,-5,-36,44,'');b.current:SetFont(STANDARD_TEXT_FONT,10,'OUTLINE');b.current:SetJustifyH('CENTER');b.current:SetTextColor(.75,.80,.85)
  b.star=label(b,25,5,16,'','GameFontNormal')
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
 local scroll=CreateFrame('ScrollFrame','RebornTalentGuideScroll',f,'UIPanelScrollFrameTemplate');G.scroll=scroll;scroll:SetPoint('TOPLEFT',1000,-148);scroll:SetSize(366,472)
 local content=CreateFrame('Frame',nil,scroll);G.content=content;content:SetSize(357,900);scroll:SetScrollChild(content)
 G.description=label(content,2,-4,348,'');G.description:SetFont(STANDARD_TEXT_FONT,13,'');G.description:SetSpacing(3)
 button(f,996,-108,182,'方案说明 / 加点清单',function()G.showGlyphs=false;G.Refresh()end)
 button(f,1184,-108,182,'雕文推荐 / 已装对照',function()G.showGlyphs=true;G.Refresh()end)
 local gp=CreateFrame('Frame',nil,f);G.glyphPanel=gp;gp:SetPoint('TOPLEFT',1000,-148);gp:SetSize(370,472);G.glyphRows={}
 for i=1,6 do
  local b=CreateFrame('Button',nil,gp);b:SetPoint('TOPLEFT',0,-(i-1)*76);b:SetSize(366,71)
  b.icon=b:CreateTexture(nil,'ARTWORK');b.icon:SetPoint('TOPLEFT',2,-5);b.icon:SetSize(30,30)
  b.name=label(b,40,-5,318,'','GameFontNormalSmall');b.why=label(b,40,-25,318,'');b.why:SetHeight(44)
  b:SetScript('OnEnter',function(self)GameTooltip:SetOwner(self,'ANCHOR_LEFT');if GetSpellInfo(self.data.spell)then pcall(GameTooltip.SetHyperlink,GameTooltip,'spell:'..self.data.spell)else GameTooltip:SetText(self.data.name)end;GameTooltip:AddLine('推荐清单：不会自动安装、购买或消耗雕文。',1,.8,.3,true);GameTooltip:Show()end)
  b:SetScript('OnLeave',function()GameTooltip:Hide()end);G.glyphRows[i]=b
 end
 label(f,1000,-632,360,'攻略链接（点击后 Ctrl+C 复制）')
 local url=CreateFrame('EditBox',nil,f,'InputBoxTemplate');G.url=url;url:SetPoint('TOPLEFT',1008,-655);url:SetSize(350,22);url:SetAutoFocus(false);url:SetFontObject('GameFontHighlightSmall');url:SetScript('OnEscapePressed',function(self)self:ClearFocus()end);url:SetScript('OnMouseUp',function(self)self:HighlightText()end)
 G.apply=button(f,18,-652,318,'应用到自己的当前专精',function()
  if G.catalogClass~='战士' or (G.category~='PVE' and G.category~='PVP')then return end
  if G.fromBot then G.ConfirmBot();return end
  local chosen=G.selected;local check,why=G.Check(D.plans[chosen]);if not check then G.Message(why);return end
  StaticPopupDialogs.REBORN_TG_APPLY={text='补齐自己的当前专精为「'..D.plans[chosen].title..'」？将花费 '..#check.rows..' 点。不会洗点或安装雕文；中途停止时已加点保留。',button1=ACCEPT,button2=CANCEL,timeout=0,whileDead=false,hideOnEscape=true,OnAccept=function()if G.catalogClass=='战士' and not G.fromBot then G.Start(chosen)end end}
  StaticPopup_Show('REBORN_TG_APPLY')
 end)
 G.stop=button(f,18,-683,318,'停止后续加点',function()G.Stop()end)
 button(f,18,-714,318,'刷新当前点数',function()G.message=nil;if G.fromBot then G.RequestBotRefresh()else G.Refresh()end end)
 G.status=label(f,1000,-693,368,'');G.status:SetHeight(40)
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
 if (bot and (not MultiBot or MultiBot.talent.class~='Warrior'))or(not bot and class~='WARRIOR')then
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
