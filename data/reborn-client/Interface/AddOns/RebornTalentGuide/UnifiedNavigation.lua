-- TG7B: shared navigation projects existing plans; no new learning/save protocol.
local G=RebornTalentGuide
local C=RebornTalentTreeCanvas
local W=G.WD
local P=RebornTalentGuidePaladin
local S=RebornTalentCollections
local Windows=RebornTalentPanelWindows
local N={states={},pageSize=3};G.Navigation=N
local tokens={['术士']='WARLOCK',['死骑']='DEATHKNIGHT',['法师']='MAGE',['萨满']='SHAMAN',['死亡骑士']='DEATHKNIGHT',['牧师']='PRIEST',['潜行者']='ROGUE',['猎人']='HUNTER',['战士']='WARRIOR',['圣骑士']='PALADIN',['巫医']='WITCHDOCTOR'}
local names={['战士']={'武器','狂怒','防护'},['圣骑士']={'神圣','防护','惩戒'}}
local sourceNames={recommended='推荐方案',favorites='我的收藏',tested='实测推荐'}
function N.State()
 local key=G.catalogClass or'战士'
 if not N.states[key]then N.states[key]={source='recommended',scene='全部',role='全部',view='tree',page=1}end
 return N.states[key]
end
function N.AllPlans()
 local out={};local cls=G.catalogClass
 local plans=cls=='战士'and RebornTalentGuideData.plans or cls=='圣骑士'and RebornTalentGuidePaladinData.plans or cls=='巫医'and RebornTalentGuideWDData.plans or{}
 for i,p in ipairs(plans)do
  local scene=p.category or(cls=='巫医'and i==1 and'练级'or'PVE')
  local role=p.role or cls=='圣骑士'and({'治疗','坦克','输出'})[(i-1)%3+1]or cls=='巫医'and i==4 and'支援'or cls=='战士'and(p.title:find('防护')and'坦克'or'输出')or'输出'
  out[#out+1]={index=i,title=p.title,scene=scene,role=role,plan=p,healer=cls=='巫医'and i==4}
 end
 return out
end
function N.Plans()
 local state=N.State();local out={}
 for _,p in ipairs(N.AllPlans())do
  if(state.scene=='全部'or state.scene==p.scene)and(state.role=='全部'or state.role==p.role or(state.role=='治疗'and p.healer))then out[#out+1]=p end
 end
 return out
end
function N.Available(field,value)
 local state=N.State();local scene=field=='scene'and value or state.scene;local role=field=='role'and value or state.role
 for _,row in ipairs(N.AllPlans())do if(scene=='全部'or row.scene==scene)and(role=='全部'or row.role==role or(role=='治疗'and row.healer))then return true end end
 return false
end
function N.Stop()
 for _,H in ipairs({RebornTalentGuideHunter,RebornTalentGuideRogue,RebornTalentGuidePriest,RebornTalentGuideDeathKnight,RebornTalentGuideShaman,RebornTalentGuideMage,RebornTalentGuideWarlock})do if H and H.job and not H.job.owner then H.Stop('切换推荐，停止后续加点')end end
 if G.job then G.Stop('切换推荐，停止后续加点')end
 if P.job and not P.job.owner then P.Stop('切换推荐，停止后续加点')end
 if StaticPopup_Hide then for _,key in ipairs({'REBORN_TG_APPLY','REBORN_TG_PALADIN','REBORN_TG_WD_DRAFT','REBORN_TG_BOT_APPLY'})do StaticPopup_Hide(key)end end
end
function N.Sync()
 local state=N.State()
 if N.currentClass~=G.catalogClass then N.currentClass=G.catalogClass;state.scene='全部';state.role='全部';state.source='recommended';state.page=1 end
 if #N.Plans()==0 and #N.AllPlans()>0 then state.scene='全部';state.role='全部';state.page=1 end
 P.viewMode='tree' -- The shared list is separate; retain the proven native tree renderer.
 local state=N.State();local actual=G.catalogClass=='战士'and G.selected or G.catalogClass=='圣骑士'and P.selected or G.catalogClass=='巫医'and W.selected
 if actual and(state.lastSet==nil or actual~=state.lastSet)then state.selected=actual end
 local list=N.Plans();local found
 for _,row in ipairs(list)do if row.index==state.selected then found=row end end
 if not found then found=list[1];state.selected=found and found.index end
 if found then
  state.lastSet=found.index
  if G.catalogClass=='战士'then G.selected=found.index;G.category=found.scene
  elseif G.catalogClass=='圣骑士'then P.selected=found.index
  elseif G.catalogClass=='巫医'then W.selected=found.index end
 end
end
local function enabled(b,on)if on then b:Enable()else b:Disable()end end
local function button(parent,x,y,width,label,fn)
 return RebornTalentGuideTheme.Button(parent,x,y,width,24,label,fn)
end
local function move(f,x,y)f:ClearAllPoints();f:SetPoint('TOPLEFT',G.frame,'TOPLEFT',x,y)end
local function hide(f)if f then f:Hide()end end
local function hideList(t)for _,f in ipairs(t or{})do hide(f)end end
local function choose(field,value)
 local state=N.State();if(field=='scene'or field=='role')and not N.Available(field,value)then return end;if field~='view'then N.Stop();state.page=1;if N.list then N.list:SetVerticalScroll(0)end end;state[field]=value;G.message=nil;G.Refresh()
end
function N.Select(class,index)
 local data=class=='战士'and RebornTalentGuideData or class=='圣骑士'and RebornTalentGuidePaladinData or class=='巫医'and RebornTalentGuideWDData
 if not data or not data.plans[index]then return false end
 local catalog=G.catalogClass;G.catalogClass=class;local state=N.State()
 state.selected=index;state.lastSet=index
 local list=N.Plans();local found
 for i,row in ipairs(list)do if row.index==index then found=i end end
 if not found then state.scene='全部';state.role='全部';list=N.Plans();for i,row in ipairs(list)do if row.index==index then found=i end end end
 if found then state.page=math.ceil(found/N.pageSize)end
 if class=='战士'then G.selected=index elseif class=='圣骑士'then P.selected=index else W.selected=index end
 G.catalogClass=catalog;return true
end
function N.Return(class,index,view)
 if not tokens[class]then return false end
 -- A guide-owned learning job cannot silently continue behind another class/plan.
 -- Collection-owned jobs keep their independent window lifecycle.
 if G.job and(class~='战士'or(index and index~=G.job.plan))then G.Stop('切换推荐，停止后续加点；已加点保留')end
 if P.job and not P.job.owner and(class~='圣骑士'or(index and index~=P.job.plan))then P.Stop('切换推荐，停止后续加点；已加点保留')end
 if index and not N.Select(class,index)then return false end
 G.Create();G.catalogClass=class;G.classPage=class=='巫医'and 2 or 1;N.currentClass=class
 local state=N.State();state.source='recommended';if view then state.view=view end
 if class=='巫医'then RebornTGViewSettings=RebornTGViewSettings or{};RebornTGViewSettings.wd='list'end
 if G.DecorateWindow then G.DecorateWindow()end
 G.Refresh();G.frame:Show();Windows.Focus(G.frame);return true
end
function N.Actual(class)
 if InCombatLockdown()then G.Message('请脱战后打开实际天赋面板');return end
 local _,own=UnitClass('player');class=type(class)=='string'and class or G.catalogClass
 if own~=tokens[class]or G.fromBot then G.Message('这里打开本人同职业面板；机器人请使用原机器人天赋入口');return end
 if own=='WITCHDOCTOR'then Windows.OpenDoctor()elseif ToggleTalentFrame and(not PlayerTalentFrame or not PlayerTalentFrame:IsShown())then ToggleTalentFrame()end
end
function N.Favorites()
 local token=tokens[G.catalogClass]
 if token=='WARRIOR'or token=='PALADIN'or token=='WITCHDOCTOR'then S.Open(token)else G.Message((G.catalogClass or'该职业')..'收藏仍待适配；已有推荐和应用功能保持可用')end
end
function N.Collect()
 if G.catalogClass~='战士'and G.catalogClass~='圣骑士'and G.catalogClass~='巫医'then return end
 N.Stop();local token=tokens[G.catalogClass];S.Open(token,function()S.New('recommendation')end)
end
local function create()
 if N.panel then return end
 local f=G.frame
 local nav=CreateFrame('Frame',nil,f);nav:SetPoint('TOPLEFT',0,0);nav:SetSize(1220,680);nav:SetFrameLevel(f:GetFrameLevel()+3)
 local bg=nav:CreateTexture(nil,'BACKGROUND');bg:SetPoint('TOPLEFT',130,-65);bg:SetSize(160,517);bg:SetTexture(.025,.035,.045,.80)
 N.groups={};N.planButtons={}
 for _,group in ipairs({{title='方案来源',field='source',y=70,values={{'recommended','推荐方案'},{'favorites','我的收藏'},{'tested','实测推荐'}},cols=1},{title='使用场景',field='scene',y=184,values={{'全部','全部'},{'练级','练级'},{'PVE','PVE'},{'PVP','PVP'}},cols=2},{title='职责筛选',field='role',y=266,values={{'全部','全部'},{'输出','输出'},{'坦克','坦克'},{'治疗','治疗'},{'支援','支援'}},cols=2}})do
  local title=C.Text(nav,134,-group.y,150,group.title,'GameFontNormal');N.groups[#N.groups+1]={title=title}
  for i,v in ipairs(group.values)do
   local field,value=group.field,v[1];local width=group.cols==1 and 150 or 73
   local b=button(nav,134+((i-1)%group.cols)*77,-group.y-22-math.floor((i-1)/group.cols)*27,width,v[2],function()
    choose(field,value);if field=='source'and value=='favorites'and(tokens[G.catalogClass]=='WARRIOR'or tokens[G.catalogClass]=='PALADIN'or tokens[G.catalogClass]=='WITCHDOCTOR')then N.Favorites()end
   end);N.groups[#N.groups+1]={button=b,field=field,value=value}
  end
 end
 C.Text(nav,134,-374,150,'方案','GameFontNormal')
 for i=1,3 do local b=button(nav,134,-398-(i-1)*44,150,'',function(self)N.Stop();N.State().selected=self.index;G.message=nil;G.Refresh()end);b:SetHeight(40);N.planButtons[i]=b end
 N.prev=button(nav,134,-538,28,'<',function()N.State().page=math.max(1,N.State().page-1);G.Refresh()end)
 N.next=button(nav,256,-538,28,'>',function()N.State().page=N.State().page+1;G.Refresh()end)
 N.page=C.Text(nav,166,-544,88,'');N.page:SetJustifyH('CENTER')
 N.panel=CreateFrame('Frame',nil,f);N.panel:SetPoint('TOPLEFT',296,-102);N.panel:SetSize(600,480)
 N.panel:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=12,insets={left=3,right=3,top=3,bottom=3}});N.panel:SetBackdropColor(.02,.035,.05,.96)
 N.empty=C.Text(N.panel,28,-110,540,'','GameFontNormalLarge')
 N.boards={};for i=1,3 do N.boards[i]=C.Board(N.panel,0,0,196,480,'')end
 N.list=CreateFrame('ScrollFrame','RebornTGUnifiedList',N.panel,'UIPanelScrollFrameTemplate');N.list:SetPoint('TOPLEFT',10,-42);N.list:SetSize(564,420)
 N.content=CreateFrame('Frame',nil,N.list);N.content:SetSize(550,420);N.list:SetScrollChild(N.content);N.rows={}
 N.listTitle=C.Text(N.panel,14,-12,568,'','GameFontNormal')
 N.tree=button(f,296,-70,78,'天赋树',function()choose('view','tree')end)
 N.listButton=button(f,380,-70,78,'加点列表',function()choose('view','list')end)
 N.largeButton=button(f,464,-70,125,'独立大面板',N.OpenLarge)
 N.collect=button(f,595,-70,105,'收藏此方案',N.Collect)
 N.actual=button(f,706,-70,190,'实际天赋面板',N.Actual)
 N.library=button(N.panel,160,-250,280,'打开我的收藏',N.Favorites)
 N.legend=C.Text(f,300,-626,590,'金色：推荐；数字为推荐 / 上限；当前已保存点数见悬停。')
 N.levelLabel=C.Text(f,300,-600,110,'预览等级')
 N.levelButtons={}
 for i,level in ipairs({0,20,40,60,80})do local value=level;N.levelButtons[i]=button(f,414+(i-1)*94,-594,88,level==0 and'当前等级'or(level..'级'),function()N.Stop();W.previewCurrent=value==0;W.previewLevel=value==0 and UnitLevel('player')or value;G.Refresh()end)end
end
local function nativeItems(data,plan,current)
 local all={}
 for t,tree in ipairs(data.trees)do
  local rows={}
  for i,n in ipairs(tree)do
   local target=plan.ranks[t][i]or 0;local _,_,icon=GetSpellInfo(n.spells[1])
   rows[#rows+1]={id=n.id,x=23+(n.col-1)*43,y=16+(n.row-1)*37,size=25,icon=icon or n.icon,spell=n.spells[math.max(1,target)],name=n.name,target=target,actual=current and current[t][i]or nil,maximum=n.max,shape=n.max>1 and'circle'or'square'}
  end
  all[t]=rows
 end
 return all
end
local scrollTree=C.ScrollTree

function N.Paint(boards,large)
 local cls=G.catalogClass
 if cls~='巫医'and not large then
  N.panel:Hide();for i,board in ipairs(G.treePanels)do board:Show();if cls=='战士'then C.WarriorArt(board,i)end end;return true
 end
 if cls=='巫医'then
  local result,why=W.Build(W.selected,W.previewLevel or UnitLevel('player'));if not result then return nil,why end
  for i,tab in ipairs({'Class',({[0]='Voodoo',[1]='Brewing',[2]='Shadowhunting'})[result.plan.spec]})do
   local board=boards[i];local width=large and 630 or 296;local height=large and 510 or 480
   board:Show();board:ClearAllPoints();board:SetPoint('TOPLEFT',large and N.large or N.panel,'TOPLEFT',(i-1)*(width+8)+(large and 12 or 0),large and-108 or 0);board:SetSize(width,height);board.canvas:SetSize(width-20,height-45);board.width=width-20;board.height=height-45
   board.title:SetText(i==1 and'通用 AE'or(({'巫毒','酿造','暗影狩猎'})[result.plan.spec+1]..' TE'))
   if not board.art then board.art=board:CreateTexture(nil,'BACKGROUND');board.art:SetPoint('TOPLEFT',4,-4);board.art:SetPoint('BOTTOMRIGHT',-4,4)end
   if C.Atlas(board.art,'talents-background-witchdoctor-'..({'voodoo','brewing','shadowhunting'})[result.plan.spec+1])then board.art:SetAlpha(.22);board.art:Show();board:SetBackdropColor(.025,.04,.055,0)else board.art:Hide();board:SetBackdropColor(.025,.04,.055,.95)end
   G.TreeViews.PaintWD(board,tab,result,N.choices,function()N.Update()end,true);scrollTree(board,board.items,true);C.Paint(board,board.items,board.edges,{captionBelow=true})
  end;hide(boards[3]);return true
 end
 local data=cls=='圣骑士'and RebornTalentGuidePaladinData or RebornTalentGuideData
 local plan=data.plans[cls=='圣骑士'and P.selected or G.selected]
 local current;if cls=='圣骑士'then current=P.Scan()elseif G.fromBot then current=G.botRanks else current=G.Scan()end
 local items=nativeItems(data,plan,current)
 if large and N.largeCurrent then for t,rows in ipairs(items)do for i,item in ipairs(rows)do item.target=current and current[t][i]or 0 end end end
 for t,tree in ipairs(data.trees)do
  local board=boards[t];local width=large and 418 or 196;local height=large and 530 or 480
  board:Show();board:ClearAllPoints();board:SetPoint('TOPLEFT',large and N.large or N.panel,'TOPLEFT',(t-1)*(width+(large and 8 or 6))+(large and 12 or 0),large and-108 or 0);board:SetSize(width,height);board.width=width-20;board.height=height-45;board.canvas:SetSize(board.width,board.height);local spent,total=0,0;for i,item in ipairs(items[t])do spent=spent+(current and current[t][i]or 0);total=total+item.target end;board.title:SetText(names[cls][t]..' · 当前 '..(current and spent or'—')..(N.largeCurrent and''or(' / 推荐 '..total)));if cls=='圣骑士'then C.Art(board,t)else C.WarriorArt(board,t)end
  if large then for _,n in ipairs(items[t])do n.x=35+(n.x-23)*2.1;n.y=32+(n.y-16)/37*62;n.size=34 end;scrollTree(board,items[t],false)end
  local edges,ids={},{};for _,n in ipairs(tree)do ids[n.id]=true end
  for _,n in ipairs(tree)do if n.dep and n.dep~=0 and ids[n.dep]then edges[#edges+1]={n.dep,n.id}end end
  C.Paint(board,items[t],edges, {captionBelow=true,current=large and N.largeCurrent})
 end;return true
end
function N.PaintList()
 local cls=G.catalogClass;local items={}
 if cls=='巫医'then
  local result=W.Build(W.selected,W.previewLevel or UnitLevel('player'));if not result then return end
  local used={};for _,row in ipairs(result.order)do if not used[row.id]then used[row.id]=true;local n=RebornTalentGuideWDData.nodes[row.id];items[#items+1]={name=n.name,rank=RebornWD8.AERank(row.id,result.mask),max=n.max,group=n.tab=='Class'and'通用 AE'or'专精 TE',icon=n.icon}end end
 else
  local data=cls=='圣骑士'and RebornTalentGuidePaladinData or RebornTalentGuideData;local plan=data.plans[cls=='圣骑士'and P.selected or G.selected]
  for t,tree in ipairs(data.trees)do for i,n in ipairs(tree)do local rank=plan.ranks[t][i];if rank>0 then local _,_,icon=GetSpellInfo(n.spells[1]);items[#items+1]={name=n.name,rank=rank,max=n.max,group=names[cls][t]..' · 第'..n.row..'层',icon=icon or n.icon,spell=n.spells[rank]}end end end
 end
 for i,n in ipairs(items)do
  local b=N.rows[i];if not b then b=CreateFrame('Button',nil,N.content);b:SetPoint('TOPLEFT',0,-(i-1)*47);b:SetSize(545,44);b.icon=b:CreateTexture(nil,'ARTWORK');b.icon:SetPoint('TOPLEFT',4,-3);b.icon:SetSize(32,32);b.label=C.Text(b,45,-3,490,'');b:SetScript('OnEnter',function(self)GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:SetText(self.node.name);GameTooltip:AddLine(self.node.group..' · 推荐 '..self.node.rank..'/'..self.node.max,1,.9,.3,true);GameTooltip:Show()end);b:SetScript('OnLeave',function()GameTooltip:Hide()end);N.rows[i]=b end
  b.node=n;b.icon:SetTexture(n.icon);b.label:SetText(n.name..'  '..n.rank..'/'..n.max..'\n'..n.group);b:Show()
 end
 for i=#items+1,#N.rows do N.rows[i]:Hide()end;N.content:SetHeight(math.max(420,#items*47));if N.list.UpdateScrollChildRect then N.list:UpdateScrollChildRect()end
end
function N.OpenLarge()
 if not N.State().selected or N.State().source~='recommended'then return end
 if G.catalogClass=='巫医'then G.TreeViews.OpenWD();return end
 if G.catalogClass=='圣骑士'and RebornClassTalentPanels then RebornClassTalentPanels.compare=true;RebornClassTalentPanels.selected=P.selected;RebornClassTalentPanels.Open('PALADIN');return end
 if not N.large then
  N.large=C.Window('RebornTGWarriorLarge','职业天赋大面板 · 战士');Windows.Register('warriorRecommendation',N.large);N.largeBoards={}
  for i=1,3 do N.largeBoards[i]=C.Board(N.large,0,0,418,530,'')end
  N.largeCurrentButton=C.Button(N.large,18,-41,120,'当前已学',function()N.largeCurrent=true;N.RefreshLarge()end)
  N.largeCategories={}
  for i,category in ipairs({'PVE','PVP'})do local value=category;N.largeCategories[i]=C.Button(N.large,148+(i-1)*65,-41,60,category,function()
   N.Stop();N.largeCategory=value;N.largeCurrent=false
   for index,plan in ipairs(RebornTalentGuideData.plans)do if plan.category==value then G.selected=index;break end end
   N.RefreshLarge()
  end)end
  N.largePlans={};for i=1,3 do local pos=i;N.largePlans[i]=C.Button(N.large,286+(i-1)*220,-41,210,'',function(self)
   N.Stop();G.selected=self.index;N.largeCurrent=false;N.RefreshLarge()
  end)end
  N.largeReturn=C.Button(N.large,1060,-41,100,'返回推荐',function()N.Return('战士',G.selected)end)
  N.largeActual=C.Button(N.large,1170,-41,105,'实际天赋面板',function()N.Actual('战士')end)
  N.largeLibrary=C.Button(N.large,1030,-3,230,'我的天赋收藏',function()S.Open('WARRIOR')end);N.largeLibrary:SetHeight(20)
  N.largeSummary=C.Text(N.large,20,-80,1240,'','GameFontNormal')
  N.largeApply=C.Button(N.large,24,-648,290,'应用推荐到自己的当前专精',function()
   if N.largeCurrent then return end
   local selected=G.selected;N.Return('战士',selected)
   G.apply:GetScript('OnClick')(G.apply)
  end)
  C.Button(N.large,1060,-648,210,'刷新当前点数',N.RefreshLarge)
  N.large.note:ClearAllPoints();N.large.note:SetPoint('TOPLEFT',328,-652);N.large.note:SetWidth(710)
 end
 N.largeCurrent=false;N.largeCategory=RebornTalentGuideData.plans[G.selected].category
 N.RefreshLarge();C.Fit(N.large);N.large:Show();Windows.Focus(N.large)
end
function N.RefreshLarge()
 if not N.large then return end
 local D=RebornTalentGuideData;local plan=D.plans[G.selected]
 -- A separate recommendation window must not render the currently browsed other class.
 local catalog=G.catalogClass;G.catalogClass='战士';N.Paint(N.largeBoards,true);G.catalogClass=catalog
 local actual,why;if G.fromBot then actual,why=G.botRanks,G.botError else actual,why=G.Scan()end
 local spent={0,0,0};if actual then for t,row in ipairs(actual)do for _,rank in ipairs(row)do spent[t]=spent[t]+rank end end end
 if not N.largeCurrent then N.Select('战士',G.selected)end
 N.largeCurrentButton:SetText(N.largeCurrent and'● 当前已学'or'当前已学')
 C.Legend(N.large,N.largeCurrent and'current'or'recommendation')
 local _,own=UnitClass('player');enabled(N.largeActual,own=='WARRIOR'and not G.fromBot and not InCombatLockdown())
 N.large.title:SetText('职业天赋大面板 · 战士 · '..(N.largeCurrent and'当前已学'or plan.title))
 N.largeSummary:SetText((N.largeCurrent and'当前已学：'or('推荐对照：'..plan.title..' · '..plan.split..'；当前已学 '))..(actual and table.concat(spent,'/')or'未同步'))
 local visible={};for index,p in ipairs(D.plans)do if p.category==N.largeCategory then visible[#visible+1]=index end end
 for i,b in ipairs(N.largePlans)do local index=visible[i];b.index=index;if index then b:SetText((not N.largeCurrent and G.selected==index and'● 'or'对照：')..D.plans[index].title);b:Show()else b:Hide()end end
 for i,b in ipairs(N.largeCategories)do b:SetText((N.largeCategory==({'PVE','PVP'})[i]and'● 'or'')..({'PVE','PVP'})[i])end
 if not N.largeCurrent and not G.fromBot and actual and UnitLevel('player')>=80 and not InCombatLockdown()and not UnitIsDeadOrGhost('player')then N.largeApply:Enable()else N.largeApply:Disable()end
 N.large.note:SetText(why or(G.fromBot and'机器人快照只读；应用请返回原机器人入口。'or'金色：推荐；白色：未推荐；应用需原流程确认补齐。收藏可管理多个版本。'))
end
local largeEvents=CreateFrame('Frame');for _,event in ipairs({'CHARACTER_POINTS_CHANGED','PLAYER_TALENT_UPDATE','ACTIVE_TALENT_GROUP_CHANGED','PLAYER_REGEN_DISABLED','PLAYER_REGEN_ENABLED'})do largeEvents:RegisterEvent(event)end
largeEvents:SetScript('OnEvent',function()if N.large and N.large:IsShown()then N.RefreshLarge()end end)

function N.Update()
 if not G.frame or N.updating then return end;N.updating=true;create()
 local state=N.State();local list=N.Plans();N.visible=list
 N.Theme()
 hideList(G.categoryButtons);hideList(G.plans);hideList(G.treePanels);hide(G.empty);hide(G.heading);hide(G.planPrev);hide(G.planNext);hide(G.planPageLabel)
 hide(P.panel);hide(P.hint);hide(P.viewToggle);hideList(P.plans);hide(W.panel);hide(W.hint);hideList(W.plans);hide(G.TreeViews.switch);hide(G.TreeViews.classic);hide(S.entry)
 N.panel:Show();hideList(N.boards);hide(N.list);hide(N.listTitle);hide(N.empty);hide(N.library)
 -- Cover old per-class category text without intercepting the new navigation.
 for _,row in ipairs(N.groups)do if row.button then row.button:Select(state[row.field]==row.value);if row.field=='scene'or row.field=='role'then enabled(row.button,N.Available(row.field,row.value))end end end
 local pages=math.max(1,math.ceil(#list/N.pageSize));state.page=math.max(1,math.min(state.page,pages));N.page:SetText(state.page..' / '..pages)
 for i,b in ipairs(N.planButtons)do local row=list[(state.page-1)*3+i];if row and state.source=='recommended'then b.index=row.index;b:SetText((state.selected==row.index and'● 'or'')..row.title);b:Select(state.selected==row.index);b:Show()else b:Hide()end end
 enabled(N.prev,state.page>1 and state.source=='recommended');enabled(N.next,state.page<pages and state.source=='recommended')
 N.tree:Select(state.view=='tree');N.listButton:Select(state.view=='list')
 local ready=state.source=='recommended'and #list>0
 if ready then N.legend:Show()else N.legend:Hide()end
 local _,own=UnitClass('player');enabled(N.actual,own==tokens[G.catalogClass]and not G.fromBot and not InCombatLockdown())
 enabled(N.tree,ready);enabled(N.listButton,ready);enabled(N.largeButton,ready);enabled(N.collect,ready and(G.catalogClass=='战士'or G.catalogClass=='巫医'or G.catalogClass=='圣骑士'))
 if ready and G.catalogClass=='巫医'then N.levelLabel:SetText('预览 '..(W.previewLevel or UnitLevel('player'))..'级');N.levelLabel:Show();for i,b in ipairs(N.levelButtons)do b:Select(i==1 and W.previewCurrent~=false or i>1 and W.previewCurrent==false and W.previewLevel==({0,20,40,60,80})[i]);b:Show()end else N.levelLabel:Hide();hideList(N.levelButtons)end
 G.tabDesc:SetText('方案说明');G.tabGlyph:SetText('雕文建议');G.context:SetText('TG16A · '..sourceNames[state.source]..' · '..state.scene..' · '..state.role)
 if not ready then
  local message
  if state.source=='tested'then message='实测推荐 · 待接入\n\n清本统计与方案版本关联尚未接入。\n不会用普通推荐代替实测结果。'
  elseif state.source=='favorites'then message=(G.catalogClass=='战士'or G.catalogClass=='圣骑士'or G.catalogClass=='巫医')and'我的收藏\n\n在独立收藏窗口管理、编辑和对比方案。'or(G.catalogClass..' · 收藏待适配\n\n现有推荐方案仍可正常浏览。');if G.catalogClass=='战士'or G.catalogClass=='圣骑士'or G.catalogClass=='巫医'then N.library:Show()end
  else message='暂无符合筛选的方案\n\n试试“全部”场景或“全部”职责。\n尚未接入的用途不会套用其他职业方案。'end
  N.empty:SetText(message);N.empty:Show();G.heading:SetText(G.catalogClass..' · '..sourceNames[state.source]);G.description:SetText(message);G.scroll:Show();G.glyphPanel:Hide();G.url:SetText('');G.apply:Disable();G.stop:Disable()
 else
  if state.view=='tree'then local ok,why=N.Paint(N.boards,false);if not ok then N.empty:SetText(why or'配套数据尚未就绪');N.empty:Show()end
  else N.listTitle:SetText('加点列表 · '..G.catalogClass);N.listTitle:Show();N.PaintList();N.list:Show()end
  if G.catalogClass=='巫医'then G.apply:SetText('保留已学并补点（载入草稿）')elseif not G.fromBot then G.apply:SetText('应用到当前方案（补齐点数）')end
 end
 N.updating=false
end
local refresh=G.Refresh
function G.Refresh()
 if N.opening then return end
 if N.busy then return refresh()end
 N.busy=true;N.Sync();refresh();N.busy=false;N.Update()
end
for _,adapter in ipairs({P,W})do local old=adapter.Refresh;adapter.Refresh=function(...)local result=old(...);if not N.busy then N.Update()end;return result end end
local open=G.Open
function G.Open(...)
 RebornTGViewSettings=RebornTGViewSettings or{};RebornTGViewSettings.wd='list'
 for _,state in pairs(N.states)do state.source='recommended'end
 N.opening=true;local ok,result=pcall(open,...);N.opening=false
 if not ok then error(result)end;G.Refresh();if G.DecorateWindow then G.DecorateWindow()end;return result
end
local returnToRecommendation=Windows.ReturnToRecommendation
function Windows.ReturnToRecommendation()
 if N.states['巫医']then N.states['巫医'].source='recommended'end
 return returnToRecommendation()
end

-- Shared frame style; restrained profession artwork under the description/glyph text.
function N.Theme()
 for _,host in ipairs({G.scroll,G.glyphPanel})do
  if not host.rebornTheme then host.rebornTheme=host:CreateTexture(nil,'BACKGROUND');host.rebornTheme:SetAllPoints()end
  local tex=host.rebornTheme;local cls=G.catalogClass
  if cls=='巫医'then C.Atlas(tex,'talents-background-witchdoctor-'..({'voodoo','brewing','shadowhunting'})[(RebornTalentGuideWDData.plans[W.selected]or{spec=2}).spec+1])
  else tex:SetTexture('Interface\\AddOns\\RebornTalentGuide\\Art\\'..(cls=='圣骑士'and'PaladinTriptychTG6B_blp'or cls=='战士'and'WarriorTriptychTG6B_blp'or'GuideGrimoireTG6B_blp'));tex:SetTexCoord(0,(cls=='圣骑士'or cls=='战士')and 1/3 or 1,0,1)end
  tex:SetAlpha(.05);tex:Show()
 end
end
