-- TG4C: two views of the same recommendation; neither tree nodes nor view switches allocate points.
local G=RebornTalentGuide
local W=G.WD
local D=RebornTalentGuideWDData
local C=RebornTalentTreeCanvas
local Windows=RebornTalentPanelWindows
G.TreeViews={choices={}}
local T=G.TreeViews
local tabs={[0]='Voodoo',[1]='Brewing',[2]='Shadowhunting'}
local names={Class='通用',Voodoo='巫毒',Brewing='酿造',Shadowhunting='暗影狩猎'}
local function enable(b,on)if on then b:Enable()else b:Disable()end end
local function settings()RebornTGViewSettings=RebornTGViewSettings or{};return RebornTGViewSettings end
local function saved()
 local M=RebornWD8
 if M and M.loaded and M.layoutReady and M.aeMasks and M.aeMasks[M.active+1]then return M.aeMasks[M.active+1]end
end
local function paintWD(board,tab,result,choices,onChange,modelOnly)
 choices=choices or T.choices
 local M=RebornWD8;local actual=saved();local groups,keys={},{}
 for _,node in ipairs(RebornWDTreeData or{})do
  if node.Tab==tab and D.nodes[node.ID]then
   local key=node.PositionX..':'..node.PositionY
   if not groups[key]then groups[key]={};keys[#keys+1]=key end
   groups[key][#groups[key]+1]=node
  end
 end
 table.sort(keys,function(a,b)local na,nb=groups[a][1],groups[b][1];return na.PositionY==nb.PositionY and na.PositionX<nb.PositionX or na.PositionY<nb.PositionY end)
 local minX,maxX,minY,maxY=10000,-10000,10000,-10000
 local positions={}
 for _,key in ipairs(keys)do
  local n=groups[key][1];local x,y=24+n.PositionX*44,24+n.PositionY*44
  if n.PositionX==10 and tab~='Class'then x,y=465,46+n.PositionY*41 end
  positions[key]={x,y};minX=math.min(minX,x);maxX=math.max(maxX,x);minY=math.min(minY,y);maxY=math.max(maxY,y)
 end
 if #keys==0 then C.Paint(board,{},{});return end
 local scale=math.min(1.04,(board.width-66)/math.max(1,maxX-minX+40),(board.height-56)/math.max(1,maxY-minY+40))
 local left=(board.width-(maxX-minX)*scale)/2;local top=(board.height-(maxY-minY)*scale)/2
 local items,aliases={},{}
 for _,key in ipairs(keys)do
  local choiceKey=tab..':'..key;local group=groups[key];local chosen=choices[tab..':'..key]
  if not chosen or chosen>#group then
   chosen=1
   for i,n in ipairs(group)do if M.AERank(n.ID,result.mask)>0 then chosen=i;break end end
  end
  local node=group[chosen];local detail=D.nodes[node.ID];local target=M.AERank(node.ID,result.mask)
  for _,n in ipairs(group)do aliases[n.ID]=node.ID end
  local pos=positions[key]
  local item={id=node.ID,x=left+(pos[1]-minX)*scale,y=top+(pos[2]-minY)*scale,size=38*scale,icon=node.Icon or detail.icon,name=detail.name,target=target,actual=actual and M.AERank(node.ID,actual)or nil,maximum=detail.max,shape=#group>1 and'choice'or(node.NodeType and node.NodeType:find('Circle')and'circle'or'square')}
  item.tooltip=function(tooltip,n)
   tooltip:SetText(detail.name..' / '..detail.en)
   tooltip:AddLine('推荐 '..target..'/'..detail.max..'；激活方案已存 '..(n.actual==nil and'未同步'or n.actual),1,.85,.3,true)
   tooltip:AddLine('前置：'..detail.path,.7,.85,1,true)
   tooltip:AddLine(detail.effects[math.max(1,target)]or detail.effects[1],1,1,1,true)
   tooltip:AddLine(detail.limit,.95,.65,.4,true)
   if #group>1 then
    tooltip:AddLine('互斥选择：点击图标仅切换查看，不加点。',1,.8,.3,true)
    for _,other in ipairs(group)do local d=D.nodes[other.ID];tooltip:AddLine(d.name..'：推荐 '..M.AERank(other.ID,result.mask)..'/'..d.max,.8,.8,.8,true)end
   end
   tooltip:AddLine('连线表示树结构；实际前置与点数以本服校验为准。',.65,.7,.75,true)
  end
  if #group>1 then item.alternatives={};for _,member in ipairs(group)do item.alternatives[#item.alternatives+1]=member.ID end;item.onClick=function()choices[choiceKey]=chosen%#group+1;(onChange or T.RefreshWD)()end end
  items[#items+1]=item
 end
 local edges,seen={},{}
 for _,key in ipairs(keys)do for _,node in ipairs(groups[key])do
  for _,id in ipairs(node.ConnectedNodes or{})do
   local a,b=aliases[node.ID],aliases[id]
   if a and b and a~=b then
    local edge=math.min(a,b)..':'..math.max(a,b)
    if not seen[edge]then seen[edge]=true;edges[#edges+1]={a,b}end
   end
  end
 end end
 if modelOnly then board.items,board.edges=items,edges else C.Paint(board,items,edges)end
end
T.PaintWD=paintWD
local function createWD()
 if T.frame then return end
 local f=C.Window('RebornTGWDRecommendationTree','巫医推荐 · 天赋树预览');T.frame=f;Windows.Register('recommendationTree',f)
 T.planButtons={}
 for i,p in ipairs(D.plans)do local index=i;T.planButtons[i]=C.Button(f,18+(i-1)*218,-40,210,p.title,function()W.selected=index;G.message=nil;T.choices={};T.RefreshWD()end)end
 T.returnButton=C.Button(f,1060,-41,100,'返回推荐',function()G.Navigation.Return('巫医',W.selected)end)
 T.library=C.Button(f,1030,-3,230,'我的天赋收藏',function()RebornTalentCollections.Open('WITCHDOCTOR')end);T.library:SetHeight(20)
 T.actual=C.Button(f,1170,-41,105,'实际天赋面板',function()G.Navigation.Actual('巫医')end)
 T.summary=C.Text(f,20,-79,1240,'','GameFontNormal')
 T.artBackground=f:CreateTexture(nil,'BORDER');T.artBackground:SetPoint('TOPLEFT',4,-30);T.artBackground:SetSize(1286,628);T.artBackground:SetAlpha(.22)
 T.classBoard=C.Board(f,12,-108,630,510,'巫医 · 通用 AE')
 T.specBoard=C.Board(f,652,-108,630,510,'专精 TE')
 T.classBoard:SetBackdropColor(.025,.04,.055,.57);T.specBoard:SetBackdropColor(.025,.04,.055,.57)
 C.Button(f,340,-631,92,'当前等级',function()W.previewCurrent=true;W.previewLevel=UnitLevel('player');T.choices={};T.RefreshWD()end)
 for i,level in ipairs({20,40,60,80})do local value=level;C.Button(f,442+(i-1)*90,-631,80,value..'级',function()W.previewCurrent=false;W.previewLevel=value;T.choices={};T.RefreshWD()end)end
 T.apply=C.Button(f,26,-631,285,'应用到当前方案（载入草稿）',function()W.RequestDraft(true)end)
 T.refresh=C.Button(f,1010,-631,270,'刷新当前点数',function()T.RefreshWD()end)
end
function T.RefreshWD()
 if not T.frame then return end
 enable(T.actual,W.IsDoctor()and not G.fromBot and not InCombatLockdown())
 local result,reason=W.Build(W.selected,W.previewLevel or UnitLevel('player'))
 if not result then T.summary:SetText(reason or'巫医配套数据未就绪');C.Paint(T.classBoard,{},{});C.Paint(T.specBoard,{},{});T.apply:Disable();return end
 T.summary:SetText(string.format('%s · %d级 · 推荐 AE %d/%d，TE %d/%d；图标只读；当前已保存点数见悬停',D.plans[W.selected].title,result.level,result.ae,result.aeBudget,result.te,result.teBudget))
 T.specBoard.title:SetText('巫医 · '..names[tabs[result.plan.spec]]..' TE')
 C.Atlas(T.artBackground,'talents-background-witchdoctor-'..tabs[result.plan.spec]:lower())
 T.classBoard.title:SetText('巫医 · 通用 AE');C.Legend(T.frame,'recommendation')
 if G.Navigation then G.Navigation.Select('巫医',W.selected)end
 for i,board in ipairs({T.classBoard,T.specBoard})do paintWD(board,i==1 and'Class'or tabs[result.plan.spec],result,nil,nil,true);C.ScrollTree(board,board.items,true);C.Paint(board,board.items,board.edges,{captionBelow=true})end
 for i,b in ipairs(T.planButtons)do b:SetText((i==W.selected and'● 'or'')..D.plans[i].title)end
 local checked,why=W.CheckDraft(W.selected,W.previewLevel or UnitLevel('player'));enable(T.apply,checked~=nil)
 enable(T.actual,W.IsDoctor()and not G.fromBot and not InCombatLockdown())
 T.frame.note:SetText(G.message or why or'应用先载入草稿并打开原面板，核对后点保存更改；图标只读，不会自动洗点。')
end
function T.OpenWD()
 if not W.Ready()or not RebornWDTreeData then G.Message('缺少巫医配套树数据，请先启用插件并重登');return false end
 createWD();Windows.Install();Windows.Prepare('recommendationTree');C.Fit(T.frame);settings().wd='tree';T.frame:Show();T.RefreshWD();return true
end
local refresh=G.Refresh
function G.Refresh()
 refresh()
 if not G.frame then return end
 if not T.switch then
  T.switch=C.Button(G.frame,134,-154,150,'树状视图',T.OpenWD)
  T.classic=C.Button(G.frame,212,-154,72,'大面板',function()
   if RebornClassTalentPanels then RebornClassTalentPanels.Open('PALADIN')else G.Message('请启用RebornClassTalentPanels样板插件并重新登录')end
  end)
 end
 if G.catalogClass=='巫医'then T.switch:Show();T.classic:Hide()
 elseif G.catalogClass=='圣骑士'then T.switch:Hide();T.classic:Show()
 else T.switch:Hide();T.classic:Hide()end
end
local open=G.Open
function G.Open(...)
 open(...)
 if G.frame and G.frame:IsShown()and G.catalogClass=='巫医'and settings().wd=='tree'then T.OpenWD()end
end
local event=CreateFrame('Frame');local elapsed=0;local signature
 event:SetScript('OnUpdate',function(_,dt)
 elapsed=elapsed+dt;if elapsed<.5 then return end;elapsed=0
 if not T.frame or not T.frame:IsShown()then return end
 local M=RebornWD8;local value=table.concat({tostring(W.selected),tostring(W.previewLevel),tostring(M and M.revision),tostring(M and M.loaded),tostring(M and M.pending),tostring(M and M.aeDirty),tostring(InCombatLockdown())},':')
 if value~=signature then signature=value;T.RefreshWD()end
 end)
