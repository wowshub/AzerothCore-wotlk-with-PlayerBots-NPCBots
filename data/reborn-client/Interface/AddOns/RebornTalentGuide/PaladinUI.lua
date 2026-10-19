-- TG3A: retain the existing guide chrome; Paladin owns only its content and native apply queue.
local G=RebornTalentGuide
local P=RebornTalentGuidePaladin
local D=RebornTalentGuidePaladinData
local treeNames={'神圣','防护','惩戒'}
local function text(parent,x,y,w,s,font)
 local f=parent:CreateFontString(nil,'OVERLAY',font or 'GameFontHighlightSmall');f:SetPoint('TOPLEFT',x,y);f:SetWidth(w);f:SetJustifyH('LEFT');f:SetText(s or '');return f
end
local function btn(parent,x,y,w,s,fn)
 return RebornTalentGuideTheme.Button(parent,x,y,w,30,s,fn)
end
local function enable(b,on)if on then b:Enable()else b:Disable()end end
local function rankName(n)local name=GetSpellInfo(n.spells[1]);return name or n.name end
local function signature(rows)
 local out={};for t,row in ipairs(rows)do out[#out+1]=table.concat(row,',')end;return table.concat(out,'/')
end
local function create()
 if P.panel then return end
 local f=CreateFrame('Frame',nil,G.frame);P.panel=f;f:SetPoint('TOPLEFT',G.frame,'TOPLEFT',296,-96);f:SetSize(600,546)
 f:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=12,insets={left=3,right=3,top=3,bottom=3}});f:SetBackdropColor(.02,.045,.065,.94);f:SetBackdropBorderColor(.55,.44,.22,1)
 P.summary=text(f,12,-12,570,'','GameFontNormal');P.summary:SetTextColor(1,.82,.3)
 local sc=CreateFrame('ScrollFrame','RebornTGPaladinListScroll',f,'UIPanelScrollFrameTemplate');P.scroll=sc;sc:SetPoint('TOPLEFT',10,-50);sc:SetSize(558,474)
 local child=CreateFrame('Frame',nil,sc);child:SetSize(552,474);sc:SetScrollChild(child);P.content=child;P.rows={}
 P.hint=text(G.frame,134,-96,150,'80级原生天赋\n逐点等待服务器\n不会自动洗点');P.hint:SetTextColor(.8,.8,.75)
 P.viewToggle=btn(G.frame,134,-154,72,'查看列表',function()P.viewMode=(P.viewMode or'tree')=='tree'and'list'or'tree';G.Refresh()end);P.viewToggle:SetHeight(25)
 P.plans={};for i,p in ipairs(D.plans)do local index=i;local b=btn(G.frame,134,-206-((i-1)%3)*46,150,p.title,function()if P.job then P.Stop()end;P.selected=index;G.message=nil;P.scroll:SetVerticalScroll(0);if G.scroll then G.scroll:SetVerticalScroll(0)end;G.Refresh()end);b:SetHeight(40);P.plans[i]=b end
 local old=G.apply:GetScript('OnClick')
 G.apply:SetScript('OnClick',function(self,...)
  if G.catalogClass~='圣骑士'then return old(self,...)end
  if P.job then return end
  local index=P.selected;local job,why=P.Check(D.plans[index]);if not job then G.Message(why);return end
  local epoch=G.Lifecycle and G.Lifecycle.epoch or 0;local guid,group,baseline=UnitGUID('player'),job.group,signature(job.ranks)
  StaticPopupDialogs.REBORN_TG_PALADIN={text='补齐当前圣骑士专精为「'..D.plans[index].title..'」？将投入 '..#job.rows..' 点。不会洗点；停止后已加点保留。',button1=ACCEPT,button2=CANCEL,timeout=0,whileDead=false,hideOnEscape=true,OnAccept=function()
   if(G.Lifecycle and not G.Lifecycle.Current(epoch))or G.catalogClass~='圣骑士'or G.fromBot or P.selected~=index or UnitGUID('player')~=guid then G.Message('查看对象已改变，请重新确认');return end
   local current,reason=P.Check(D.plans[index]);if not current or current.group~=group or signature(current.ranks)~=baseline then G.Message(reason or'点数或专精已改变，请重新确认');return end
   P.Start(index)
  end};StaticPopup_Show('REBORN_TG_PALADIN')
 end)
 local stop=G.stop:GetScript('OnClick')
 G.stop:SetScript('OnClick',function(self,...)if G.catalogClass=='圣骑士'then P.Stop()else return stop(self,...)end end)
 G.frame:HookScript('OnHide',function()if P.job and not P.job.owner then P.Stop('窗口已关闭，停止后续加点')end end)
end
function P.Hide()
 if not P.panel then return end
 P.panel:Hide();P.hint:Hide();P.viewToggle:Hide();for _,b in ipairs(P.plans)do b:Hide()end
 if P.treeNodes then for _,b in ipairs(P.treeNodes)do b:Hide()end end
 for _,f in ipairs(G.treePanels or{})do if f.art then f.art:Hide();f:SetBackdropColor(.02,.045,.065,.94)end end
end
local function detail(plan)
 return plan.body..'\n\n本服校验\n总点数 '..table.concat(plan.split,'/')..'，合计71。逐点满足层级与前置；已保存点数冲突需自行决定是否洗点，推荐不会代做。\n神圣惩戒1756当前引用缺失前置1409，三套方案均未选；不自动修补或绕过前置。\n带 * 节点为已识别本服替换；其余节点也以客户端实际说明为准。\n\n雕文\n本批不新增可信雕文清单，沿用原雕文系统自行核对；不会购买、安装或清空雕文。\n\n来源\n参考攻略的职责与机制方向；具体点数为本服适配候选，未实机验收，不宣称最优。'
end
-- Same three-column geometry and node treatment as the original Warrior recommendation view.
local function paintTrees(plan,actual)
 if not P.treeNodes then
  P.treeNodes={}
  for t,tree in ipairs(D.trees)do for i,n in ipairs(tree)do
   local b=CreateFrame('Button',nil,G.treePanels[t]);b:SetSize(32,32);b.tree=t;b.index=i;b.data=n
   b.icon=b:CreateTexture(nil,'ARTWORK');b.icon:SetAllPoints();b.icon:SetTexCoord(.07,.93,.07,.93);b:SetHighlightTexture('Interface\\Buttons\\ButtonHilight-Square','ADD')
   local edge=b:CreateTexture(nil,'BACKGROUND');edge:SetPoint('TOPLEFT',-1,1);edge:SetPoint('BOTTOMRIGHT',1,-1);edge:SetTexture(.55,.44,.22,.9)
   local badge=b:CreateTexture(nil,'OVERLAY');badge:SetPoint('BOTTOM',b,'BOTTOM',0,-1);badge:SetSize(30,13);badge:SetTexture(0,0,0,.8)
   b.rank=text(b,-4,-19,40,'');b.rank:SetFont(STANDARD_TEXT_FONT,12,'OUTLINE');b.rank:SetJustifyH('CENTER')
   b.current=text(b,-6,-33,44,'');b.current:SetFont(STANDARD_TEXT_FONT,9,'OUTLINE');b.current:SetJustifyH('CENTER');b.current:SetTextColor(.70,.75,.80)
   b.star=text(b,24,5,16,'','GameFontNormal')
   b:SetScript('OnEnter',function(self)
    local n=self.data;local target=D.plans[P.selected].ranks[self.tree][self.index]
    GameTooltip:SetOwner(self,'ANCHOR_RIGHT');local id=n.spells[math.max(1,target)]
    if GetSpellInfo(id)then pcall(GameTooltip.SetHyperlink,GameTooltip,'spell:'..id)else GameTooltip:SetText(n.name)end
    GameTooltip:AddLine('推荐 '..target..'/'..n.max..'；当前 '..(self.actual==nil and'未同步'or self.actual),1,.85,.3,true)
    GameTooltip:AddLine('TalentID '..n.id..'；第'..n.row..'层，第'..n.col..'列；前置 '..(n.dep==0 and'无'or(n.dep..'（等级'..n.depRank..'）')),.7,.85,1,true)
    if n.changed then GameTooltip:AddLine('本服替换节点，以实际技能说明为准。',1,.7,.3,true)end
    GameTooltip:AddLine('推荐树用于查看和对照；通过左下角按钮确认补齐当前专精。',.7,.7,.7,true);GameTooltip:Show()
   end);b:SetScript('OnLeave',function()GameTooltip:Hide()end);P.treeNodes[#P.treeNodes+1]=b
  end end
 end
 for _,old in ipairs(G.nodes)do old:Hide()end
 for t,frame in ipairs(G.treePanels)do frame:Show();if RebornTalentTreeCanvas then RebornTalentTreeCanvas.Art(frame,t)end;G.treeTitles[t]:SetText(treeNames[t]..' · 推荐 '..plan.split[t]..' 点')end
 for _,b in ipairs(P.treeNodes)do
  local n=b.data;local L=G.layout;b:ClearAllPoints();b:SetPoint('TOPLEFT',G.treePanels[b.tree],'TOPLEFT',L.nodeX+(n.col-1)*L.colStep,L.nodeY-(n.row-1)*L.rowStep)
  local _,_,icon=GetSpellInfo(n.spells[1]);b.icon:SetTexture(icon or n.icon)
  local target=plan.ranks[b.tree][b.index];b.actual=actual and actual[b.tree][b.index]or nil
  b.icon:SetDesaturated(target==0);b.rank:SetText(target..'/'..n.max);b.current:SetText('现 '..(b.actual==nil and'—'or b.actual));b.current:SetTextColor(.25,1,1);b.rank:SetTextColor(1,target>0 and .9 or 1,target>0 and .25 or 1);b.star:SetText(n.changed and'*'or'');b:Show()
 end
end
function P.Refresh()
 create();P.panel:Show();P.hint:Show();G.empty:Hide();G.glyphPanel:Hide()
 for _,f in ipairs(G.treePanels)do f:Hide()end;for _,b in ipairs(G.plans)do b:Hide()end
 for _,b in ipairs(G.categoryButtons)do b:Hide()end
 G.planPrev:Hide();G.planNext:Hide();G.planPageLabel:SetText('PVE / PVP · 3 类职责')
 local plan=D.plans[P.selected];G.heading:SetText('圣骑士 · '..plan.title);G.context:SetText('TG4C · 80级候选 · 仅自己原生天赋')
 G.url:SetText(plan.source);G.apply:SetText('补齐自己的当前专精');G.stop:SetText('停止后续加点');enable(G.stop,P.job~=nil)
 P.summary:SetText('本服分配 '..table.concat(plan.split,'/')..' · 71点；黄色为推荐，悬停查看技能')
 for i,b in ipairs(P.plans)do if D.plans[i].category==plan.category then b:Show()else b:Hide()end;b:SetText((i==P.selected and '● 'or'')..D.plans[i].title)end
 local actual=P.Scan();local nrow=0
 for t,tree in ipairs(D.trees)do for i,n in ipairs(tree)do
  local target=plan.ranks[t][i]
  if target>0 then
   nrow=nrow+1;local b=P.rows[nrow]
   if not b then
    b=CreateFrame('Button',nil,P.content);b:SetSize(546,44);b:SetPoint('TOPLEFT',2,-(nrow-1)*47)
    b.icon=b:CreateTexture(nil,'ARTWORK');b.icon:SetPoint('TOPLEFT',0,-4);b.icon:SetSize(32,32);b.icon:SetTexCoord(.07,.93,.07,.93)
    b.name=text(b,42,-3,350,'','GameFontNormalSmall');b.rank=text(b,398,-3,144,'');b.note=text(b,42,-23,498,'');b.note:SetTextColor(.65,.7,.75)
    b:SetScript('OnEnter',function(self)
     GameTooltip:SetOwner(self,'ANCHOR_RIGHT');local x=self.node;local id=x.spells[self.target]
     if id and GetSpellInfo(id)then pcall(GameTooltip.SetHyperlink,GameTooltip,'spell:'..id)else GameTooltip:SetText(rankName(x))end
     GameTooltip:AddLine('TalentID '..x.id..'；推荐 '..self.target..'/'..x.max,1,.85,.3,true)
     GameTooltip:AddLine('第'..x.row..'层：本系至少'..((x.row-1)*5)..'点；前置 '..(x.dep==0 and'无'or(x.dep..' 等级'..x.depRank)),.7,.85,1,true);GameTooltip:Show()
    end);b:SetScript('OnLeave',function()GameTooltip:Hide()end);P.rows[nrow]=b
   end
   b.node=n;b.target=target;local _,_,icon=GetSpellInfo(n.spells[1]);b.icon:SetTexture(icon or n.icon)
   b.name:SetText(rankName(n)..(n.changed and' *'or''));b.rank:SetText('荐 '..target..'/'..n.max..'  当前 '..(actual and actual[t][i]or'—'));b.note:SetText(treeNames[t]..' · 第'..n.row..'层 · TalentID '..n.id);b:Show()
  end
 end end
 for i=nrow+1,#P.rows do P.rows[i]:Hide()end;P.content:SetHeight(math.max(474,nrow*47));if P.scroll.UpdateScrollChildRect then P.scroll:UpdateScrollChildRect()end
 G.description:SetText(G.showGlyphs and'本批没有新增已验证的圣骑士雕文推荐。请通过原雕文系统核对本服实际效果；不会自动安装、消耗或替换。'or detail(plan));G.content:SetHeight(math.max(394,G.description:GetStringHeight()+16));G.scroll:Show();if G.scroll.UpdateScrollChildRect then G.scroll:UpdateScrollChildRect()end
 G.tabDesc:SetNavSelected(not G.showGlyphs);G.tabGlyph:SetNavSelected(G.showGlyphs and true or false)
 local job,why=P.Check(plan);enable(G.apply,job~=nil and not P.job)
 G.status:SetText(G.message or why or'将逐点调用原生接口；不会代洗点或安装雕文。')
 P.viewToggle:Show();P.viewToggle:SetText((P.viewMode or'tree')=='tree'and'查看列表'or'查看树')
 if(P.viewMode or'tree')=='tree'then P.panel:Hide();paintTrees(plan,actual)else P.panel:Show();if P.treeNodes then for _,b in ipairs(P.treeNodes)do b:Hide()end end end
end
local oldRefresh=G.Refresh
function G.Refresh()
 P.Hide();oldRefresh();if G.frame and G.catalogClass=='圣骑士'then P.Refresh()end
end
local oldOpen=G.Open
function G.Open(fromBot)
 if P.job then P.Stop('查看对象改变，停止加点')end
 oldOpen(fromBot);local _,class=UnitClass('player')
 if not fromBot and class=='PALADIN'then G.catalogClass='圣骑士';G.classPage=1;G.Refresh()end
end
local ev=CreateFrame('Frame');ev:RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED');ev:RegisterEvent('PLAYER_REGEN_DISABLED');ev:RegisterEvent('PLAYER_LOGOUT')
ev:SetScript('OnEvent',function()if P.job then P.Stop('专精或状态改变，停止后续加点')end end)
local elapsed=0;ev:SetScript('OnUpdate',function(_,dt)elapsed=elapsed+dt;if elapsed<.2 then return end;elapsed=0;P.Tick()end)
