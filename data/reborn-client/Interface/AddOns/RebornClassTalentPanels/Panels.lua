-- CT1B: adapters read the canonical character data. No alternate saved build or LearnTalent call.
RebornClassTalentPanels={adapters={}}
local A=RebornClassTalentPanels
local G=RebornTalentGuide
local C=RebornTalentTreeCanvas
local Windows=RebornTalentPanelWindows
local D=RebornTalentGuidePaladinData
local P=RebornTalentGuidePaladin
local names={'神圣','防护','惩戒'}
local function message(s)if G and G.Message then G.Message(s)end end
function A.Register(token,adapter)A.adapters[token]=adapter end
function A.Open(token)
 if InCombatLockdown()then message('请脱战后切换职业大面板');return false end
 local _,own=UnitClass('player');token=token or own
 local adapter=A.adapters[token]
 if not adapter then message('该职业大面板尚未接入，请继续使用原经典面板');return false end
 return adapter.Open()
end
local function classic()
 if InCombatLockdown()then message('请脱战后打开原经典面板');return end
 local _,token=UnitClass('player')
 if G.Navigation and ({WARRIOR='战士',PALADIN='圣骑士',WITCHDOCTOR='巫医'})[token]then return G.Navigation.Actual(({WARRIOR='战士',PALADIN='圣骑士',WITCHDOCTOR='巫医'})[token])end
 if token~='PALADIN'then message('当前样板属于圣骑士；你的原职业面板入口保持不变');return end
 Windows.Prepare('native')
 if type(ToggleTalentFrame)=='function'and(not PlayerTalentFrame or not PlayerTalentFrame:IsShown())then ToggleTalentFrame()end
 Windows.Install()
end
local function create()
 if A.frame then return end
 local f=C.Window('RebornClassicTalentLargePanel','职业天赋大面板 · 圣骑士试用版');A.frame=f;Windows.Register('classicLarge',f)
 A.library=C.Button(f,1030,-3,230,'我的天赋收藏',function()if RebornTalentCollections then RebornTalentCollections.Open('PALADIN')end end);A.library:SetHeight(20)
 A.current=C.Button(f,18,-41,140,'当前已学',function()A.compare=false;A.Refresh()end)
 A.planButtons={}
 A.categories={}
 for i,category in ipairs({'PVE','PVP'})do local value=category;A.categories[i]=C.Button(f,165+(i-1)*65,-41,60,category,function()
  G.Navigation.Stop();local spec=(D.plans[A.selected or 1]or D.plans[1]).spec or 1
  for index,plan in ipairs(D.plans)do if plan.category==value and plan.spec==spec then A.selected=index;break end end
  A.category=value;A.compare=true;A.Refresh()
 end)end
 for i=1,3 do
  local b=C.Button(f,300+(i-1)*250,-41,240,'',nil);A.planButtons[i]=b
  b:SetScript('OnClick',function()if b.index then G.Navigation.Stop();A.compare=true;A.selected=b.index;A.Refresh()end end)
 end
 A.returnButton=C.Button(f,1060,-41,100,'返回推荐',function()G.Navigation.Return('圣骑士',A.compare and A.selected or P.selected)end)
 A.actual=C.Button(f,1170,-41,105,'实际天赋面板',function()G.Navigation.Actual('圣骑士')end)
 A.summary=C.Text(f,20,-80,1240,'','GameFontNormal');A.boards={}
 for t=1,3 do A.boards[t]=C.Board(f,12+(t-1)*426,-108,418,530,names[t]);C.Art(A.boards[t],t)end
 A.apply=C.Button(f,32,-648,280,'应用推荐到自己的当前专精',function()
  if not A.compare then return end
  local index=A.selected or 1;G.Navigation.Return('圣骑士',index)
  G.apply:GetScript('OnClick')(G.apply)
 end)
 A.refresh=C.Button(f,1060,-648,210,'刷新当前点数',function()A.Refresh()end)
end
function A.Refresh()
 if not A.frame then return end
 local actual,why=P.Scan();local selected=D.plans[A.selected or 1]
 if A.compare and G.Navigation then G.Navigation.Select('圣骑士',A.selected or 1)end
 A.current:SetText(A.compare and'当前已学'or'● 当前已学');A.current:Select(not A.compare)
 C.Legend(A.frame,A.compare and'recommendation'or'current')
 local _,own=UnitClass('player');if own=='PALADIN'and not G.fromBot and not InCombatLockdown()then A.actual:Enable()else A.actual:Disable()end
 if A.compare then A.category=selected.category or'PVE'end
 A.category=A.category or'PVE';local visible={}
 for index,plan in ipairs(D.plans)do if(plan.category or'PVE')==A.category then visible[#visible+1]=index end end
 for i,b in ipairs(A.planButtons)do local index=visible[i];b.index=index
  if index then b:SetText((A.compare and index==(A.selected or 1)and'● 'or'对照：')..D.plans[index].title);b:Select(A.compare and index==(A.selected or 1));b:Show()else b:Hide()end
 end
 for i,b in ipairs(A.categories)do b:Select(A.category==({'PVE','PVP'})[i])end
 local spent={0,0,0};if actual then for t,row in ipairs(actual)do for _,n in ipairs(row)do spent[t]=spent[t]+n end end end
 A.summary:SetText(A.compare and('推荐对照：'..selected.title..' · '..table.concat(selected.split,'/')..'；当前已学 '..table.concat(spent,'/'))or(actual and('当前已学 '..table.concat(spent,'/')..'；剩余 '..tostring(GetUnspentTalentPoints(false,false,GetActiveTalentGroup(false,false)))..' 点')or'布局样板预览：当前角色不是圣骑士或原生天赋数据未就绪'))
 for t,tree in ipairs(D.trees)do
  local items,edges,ids={},{},{}
  for _,n in ipairs(tree)do ids[n.id]=true end
  for i,n in ipairs(tree)do
   local name,_,icon=GetSpellInfo(n.spells[1]);local maximum=n.max
   local target=A.compare and selected.ranks[t][i]or(actual and actual[t][i]or 0)
   local rank=actual and actual[t][i]or nil
   local item={id=n.id,x=57+(n.col-1)*86,y=30+(n.row-1)*43,size=38,icon=icon or n.icon,name=name or n.name,spell=n.spells[math.max(1,target)],maximum=maximum,target=target,actual=rank,shape=n.max>1 and'circle'or'square'}
   item.tooltip=function(tooltip,x)
    tooltip:AddLine((name or n.name)..' · TalentID '..n.id,1,.85,.3,true)
    tooltip:AddLine('当前已学 '..(rank==nil and'未同步'or rank)..'/'..maximum..(A.compare and('；推荐 '..target..'/'..maximum)or''),.7,.85,1,true)
    tooltip:AddLine('第'..n.row..'层，需要本系'..((n.row-1)*5)..'点；前置 '..(n.dep==0 and'无'or(n.dep..'（等级'..n.depRank..'）')),1,1,1,true)
    if n.dep~=0 and not ids[n.dep]then tooltip:AddLine('当前本服数据缺少此前置；推荐未选此节点。',1,.4,.3,true)end
    if n.changed then tooltip:AddLine('本服替换节点，请以实际技能说明为准。',1,.7,.3,true)end
    tooltip:AddLine('节点只读；底部应用按钮转入原推荐系统确认补齐。',.7,.7,.7,true)
   end
   items[#items+1]=item
   if n.dep~=0 and ids[n.dep]then edges[#edges+1]={n.dep,n.id}end
  end
  A.boards[t].title:SetText(names[t]..' · 当前 '..(actual and spent[t]or'—')..(A.compare and(' / 推荐 '..selected.split[t])or''));C.ScrollTree(A.boards[t],items,false);C.Paint(A.boards[t],items,edges,{current=not A.compare,captionBelow=true})
 end
 if A.compare then A.apply:Show()else A.apply:Hide()end
 local ready=actual and not G.fromBot and UnitLevel('player')>=80 and not InCombatLockdown()and not UnitIsDeadOrGhost('player')
 if A.compare and ready then A.apply:Enable()else A.apply:Disable()end
 A.frame.note:ClearAllPoints();A.frame.note:SetPoint('TOPLEFT',330,-654);A.frame.note:SetWidth(700)
 A.frame.note:SetText(why or'金色：推荐；白色：未推荐；青色角标：当前已学。应用转入原推荐确认补齐，不会洗点。')
end
A.Register('WARRIOR',{Open=function()if not G.Navigation then message('请先启用配套推荐导航');return false end;G.Navigation.Return('战士',G.selected);G.Navigation.OpenLarge();return true end})
A.Register('PALADIN',{Open=function()create();Windows.Install();Windows.Prepare('classicLarge');C.Fit(A.frame);A.frame:Show();A.Refresh();return true end})
A.Register('WITCHDOCTOR',{Open=function()Windows.Install();if RebornWDTreePreviewAPI and RebornWDTreePreviewAPI.Open then RebornWDTreePreviewAPI.Open();return true end;message('请启用巫医天赋插件');return false end})
SLASH_REBORNCLASSTALENTS1='/rclass';SLASH_REBORNCLASSTALENTS2='/rtree'
SlashCmdList.REBORNCLASSTALENTS=function(msg)
 msg=(msg or''):lower()
 if msg=='warrior'or msg=='战士'then A.Open('WARRIOR')elseif msg=='paladin'or msg=='圣骑士'then A.Open('PALADIN')elseif msg=='classic'or msg=='原面板'then classic()else A.Open()end
end
local event=CreateFrame('Frame');event:RegisterEvent('CHARACTER_POINTS_CHANGED');event:RegisterEvent('PLAYER_TALENT_UPDATE');event:RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED');event:RegisterEvent('PLAYER_REGEN_DISABLED');event:RegisterEvent('PLAYER_REGEN_ENABLED')
event:SetScript('OnEvent',function()if A.frame and A.frame:IsShown()then A.Refresh()end end)


-- TG24A: hunter uses the same three-column center and its canonical collection engine.
A.Register('HUNTER',{Open=function()return G.TalentCenter.Open('recommend','HUNTER',RebornTalentGuideHunter.selected or 1)end})

A.Register('ROGUE',{Open=function()return G.TalentCenter.Open('recommend','ROGUE',RebornTalentGuideRogue.selected or 1)end})
