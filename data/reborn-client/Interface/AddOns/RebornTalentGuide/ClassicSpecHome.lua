-- TG10A: classic class selection cards -> one canonical classic specialization tree.
-- Browsing is not selecting an exclusive spec, learning, resetting or changing a saved build.
local G=RebornTalentGuide;local C=RebornTalentTreeCanvas;local W=RebornTalentPanelWindows
local B={};G.ClassHome=B
-- Same reviewed CoA home atlas geometry as WD, copied under this addon's own path.
local shell='Interface\\AddOns\\RebornTalentGuide\\Art\\ClassicSpecShellTG10A_blp'
local shellUV={
 ['spec-background']={.000488,.787598,.000488,.418457},
 ['spec-thumbnailborder-off']={.000488,.157715,.838379,.937012},
 ['spec-dividerline']={.000488,.124512,.937988,.938965},
 ['spec-columndivider']={.982422,.98584,.000488,.418457}}
local names={WARRIOR='战士',PALADIN='圣骑士'}
local data={
 WARRIOR={
  {name='武器',role='近战输出',stats='力量',style='双手兵刃',icon='Ability_Warrior_OffensiveStance',description='掌握双手兵刃与战斗节奏，以经典武器系节点构筑你的战斗方式。',plan=3},
  {name='狂怒',role='近战输出',stats='力量',style='双持追击',icon='Ability_Warrior_InnerRage',description='围绕怒气与连续攻击展开战斗；双持资格与技能效果以本服已学为准。',plan=2},
  {name='防护',role='坦克',stats='耐力 · 力量',style='剑盾守护',icon='Ability_Warrior_DefensiveStance',description='以盾牌、生存和威胁控制守护队伍，沿经典防护系查看每层前置。',plan=1}},
 PALADIN={
  {name='神圣',role='治疗',stats='智力 · 法术强度',style='圣光救援',icon='Spell_Holy_HolyBolt',description='以圣光治疗与保护盟友，浏览本服神圣系的治疗和续航节点。',plan=1},
  {name='防护',role='坦克',stats='耐力 · 力量',style='盾牌守护',icon='Spell_Holy_DevotionAura',description='以圣盾、祝福和威胁控制承受攻击，查看本服防护系的实际替换。',plan=2},
  {name='惩戒',role='近战输出',stats='力量',style='圣印审判',icon='Spell_Holy_AuraOfLight',description='运用圣印与审判展开近战，按本服实际技能查看经典惩戒系。',plan=3}}}
local function native(token)return token=='WARRIOR'and RebornTalentGuideData or RebornTalentGuidePaladinData end
local function scan(token)
 if not G.ClassEntry or G.ClassEntry.PlayerClass()~=token then return nil,'当前不是本人同职业'end
 if token=='WARRIOR'then return G.Scan()end
 return RebornTalentGuidePaladin.Scan()
end
local function label(parent,text,y,font,width)
 local t=parent:CreateFontString(nil,'OVERLAY',font or'GameFontNormal');t:SetPoint('TOP',parent,'TOP',0,y);t:SetWidth(width or 320);t:SetJustifyH('CENTER');t:SetText(text or'');return t
end
local function atlas(parent,key,x,y,width,height,layer)
 local a=shellUV[key]
 local t=parent:CreateTexture(nil,layer or'ARTWORK');t:SetPoint('TOPLEFT',x,y);t:SetSize(width,height)
 if a then t:SetTexture(shell);t:SetTexCoord(a[1],a[2],a[3],a[4])else t:SetTexture(.06,.065,.07,1);if key~='spec-background'then t:SetAlpha(0)end end
 return t
end
local function createHome()
 if B.home then return end
 local f=C.Window('RebornClassicSpecHome','飞升 · 职业天赋 · TG14A');B.home=f;W.Register('classicSpecHome',f)
 B.homeBackground=atlas(f,'spec-background',4,-30,1286,655,'BORDER')
 f.title:SetWidth(800)
 B.cards={}
 for i=1,3 do
  local index=i;local card=CreateFrame('Frame',nil,f);card:SetPoint('TOPLEFT',5+(i-1)*428,-36);card:SetSize(428,632)
  if i<3 then atlas(card,'spec-columndivider',425,-8,4,604,'BORDER')end
  card.picture=card:CreateTexture(nil,'ARTWORK');card.picture:SetPoint('TOPLEFT',69,-30);card.picture:SetSize(290,175)
  atlas(card,'spec-thumbnailborder-off',62,-24,304,187,'OVERLAY')
  card.name=label(card,'',-233,'GameFontNormalLarge')
  card.roleIcon=card:CreateTexture(nil,'ARTWORK');card.roleIcon:SetPoint('TOPLEFT',193,-270);card.roleIcon:SetSize(42,42)
  card.role=label(card,'',-315)
  atlas(card,'spec-dividerline',69,-345,290,2)
  card.description=label(card,'',-364,'GameFontNormal',294)
  card.stats=label(card,'',-442,'GameFontHighlight');card.style=label(card,'',-470);card.style:SetTextColor(.4,1,.35)
  atlas(card,'spec-dividerline',69,-495,290,2);label(card,'代表天赋（展示）',-506,'GameFontHighlightSmall')
  card.samples={}
  for j=1,3 do
   local button=CreateFrame('Button',nil,card);button:SetPoint('TOPLEFT',140+(j-1)*52,-530);button:SetSize(44,44)
   button.icon=button:CreateTexture(nil,'ARTWORK');button.icon:SetAllPoints()
   button.border=button:CreateTexture(nil,'OVERLAY');button.border:SetAllPoints();button.border:SetTexture('Interface\\Buttons\\UI-Quickslot2')
   button:SetScript('OnEnter',function(self)if not self.node then return end;GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:SetText(self.node.name,1,.82,0);GameTooltip:AddLine('代表节点；点击查看天赋后可核对本服替换与前置，不会自动学习。',1,1,1,true);GameTooltip:Show()end)
   button:SetScript('OnLeave',function()GameTooltip:Hide()end);card.samples[j]=button
  end
  card.points=label(card,'',-576,'GameFontHighlightSmall')
  card.choose=C.Button(card,76,-595,280,'查看天赋',function()B.ShowTree(B.token,index)end)
  B.cards[i]=card
 end
 B.library=C.Button(f,1030,-3,230,'我的天赋收藏',function()RebornTalentCollections.Open(B.token)end);B.library:SetHeight(20)
 f.note:SetText('选择方向，浏览对应的经典天赋树；不会洗点、切换专精或自动加点。')
end
function B.RefreshHome()
 if not B.home or not B.token then return end
 B.homeBackground:SetAlpha(1);B.homeBackground:Show()
 local token=B.token;local d=native(token);local ranks=scan(token);local stem=token=='WARRIOR'and'Warrior'or'Paladin'
 B.home.title:SetText('飞升 · '..names[token]..'天赋 · TG14A')
 for i,card in ipairs(B.cards)do
  local spec=data[token][i];card.name:SetText(spec.name);card.role:SetText(spec.role);card.description:SetText(spec.description)
  card.stats:SetText('主要属性：'..spec.stats);card.style:SetText('战斗方式：'..spec.style)
  card.roleIcon:SetTexture('Interface\\Icons\\'..spec.icon)
  card.picture:SetTexture('Interface\\AddOns\\RebornTalentGuide\\Art\\'..stem..'SpecCardsTG10A_blp')
  card.picture:SetTexCoord((i-1)/3*.75,i/3*.75,0,.60546875)
  local tree=d.trees[i];local examples={tree[1],tree[math.ceil(#tree/2)],tree[#tree]}
  for j,button in ipairs(card.samples)do local n=examples[j];local _,_,icon=GetSpellInfo(n.spells[1]);button.node=n;button.icon:SetTexture(icon or n.icon)end
  local sum=0;if ranks then for _,n in ipairs(ranks[i])do sum=sum+n end end
  card.points:SetText(ranks and('当前已学 '..sum..' 点')or'当前点数尚未就绪')
 end
end
local function createTree()
 if B.tree then return end
 local f=C.Window('RebornClassicSpecTree','飞升 · 专精天赋 · TG14A');B.tree=f;W.Register('classicSpecTree',f)
 B.back=C.Button(f,20,-40,170,'返回专精首页',function()B.tree:Hide();B.ShowHome(B.token)end)
 B.tabs={}
 for i=1,3 do local index=i;B.tabs[i]=C.Button(f,205+(i-1)*165,-40,155,'',function()B.selected=index;B.board.offset=0;B.RefreshTree()end)end
 C.Button(f,1030,-3,230,'我的天赋收藏',function()RebornTalentCollections.Open(B.token)end):SetHeight(20)
 C.Button(f,1030,-40,240,'三系推荐对照',function()
  local spec=data[B.token][B.selected];G.Navigation.Return(names[B.token],spec.plan);G.Navigation.OpenLarge()
 end)
 B.background=f:CreateTexture(nil,'BORDER');B.background:SetPoint('TOPLEFT',7,-30);B.background:SetSize(1280,620)
 B.infoShade=f:CreateTexture(nil,'ARTWORK');B.infoShade:SetPoint('TOPLEFT',915,-82);B.infoShade:SetSize(350,548);B.infoShade:SetTexture(.02,.025,.035,.76)
 B.board=C.Board(f,14,-80,885,550,'');B.board:SetBackdropColor(.02,.03,.04,.15)
 B.info=C.Text(f,929,-97,324,'','GameFontHighlight');B.info:SetSpacing(5)
 C.Button(f,935,-542,320,'打开收藏编辑方案',function()RebornTalentCollections.Open(B.token)end)
 B.actual=C.Button(f,935,-580,320,'打开原经典天赋面板',function()G.Navigation.Actual(names[B.token])end)
 B.refresh=C.Button(f,1035,-648,225,'刷新当前点数',B.RefreshTree)
 f.note:SetWidth(940);f.note:SetText('沿用经典节点、层级和前置。此页只读；编辑与应用使用已有收藏和原确认流程。左右下角拖动缩放。')
end
function B.RefreshTree()
 if not B.tree or not B.token then return end
 local token=B.token;local index=B.selected or 1;local spec=data[token][index];local d=native(token);local ranks,why=scan(token)
 B.tree.title:SetText('飞升 · '..names[token]..' · '..spec.name..'天赋 · TG14A')
 for i,b in ipairs(B.tabs)do b:SetText((i==index and'● 'or'')..data[token][i].name);b:Select(i==index)end
 B.background:SetTexture('Interface\\AddOns\\RebornTalentGuide\\Art\\'..(token=='WARRIOR'and'Warrior'or'Paladin')..'Spec'..index..'TG10A_blp')
 B.background:SetTexCoord(0,.787109375,0,.755859375);B.background:SetAlpha(1);B.background:Show()
 local sum=0;local tree=d.trees[index];local edges,items,ids={},{},{}
 for _,n in ipairs(tree)do ids[n.id]=true end
 for i,n in ipairs(tree)do
  local rank=ranks and ranks[index][i]or nil;if rank then sum=sum+rank end
  local _,_,icon=GetSpellInfo(n.spells[1])
  local item={id=n.id,x=245+(n.col-1)*110,y=28+(n.row-1)*62,size=34,icon=icon or n.icon,name=n.name,spell=n.spells[math.max(1,rank or 0)],maximum=n.max,target=rank or 0,actual=rank,shape=n.max>1 and'circle'or'square'}
  item.tooltip=function(tooltip)
   tooltip:AddLine(n.name..' · TalentID '..n.id,1,.82,.3,true)
   tooltip:AddLine('第'..n.row..'层 · 当前 '..(rank==nil and'未同步'or(rank..'/'..n.max)),1,1,1,true)
   if n.dep~=0 then tooltip:AddLine('前置TalentID '..n.dep..'，至少 '..n.depRank..' 点',.8,.85,.9,true)end
   if n.changed then tooltip:AddLine('本服替换节点，请以实际技能说明为准。',1,.7,.3,true)end
   tooltip:AddLine('此处只读；编辑收藏不会直接修改角色。',.7,.7,.7,true)
  end
  items[#items+1]=item;if n.dep~=0 and ids[n.dep]then edges[#edges+1]={n.dep,n.id}end
 end
 B.board.title:SetText(spec.name..' · 当前已学 '..(ranks and sum or'未同步')..' 点')
 C.ScrollTree(B.board,items,false);C.Paint(B.board,items,edges,{current=true,captionBelow=true})
 B.info:SetText(spec.name..' · '..spec.role..'\n\n'..spec.description..'\n\n主要属性：'..spec.stats..'\n战斗方式：'..spec.style..'\n\n当前本系：'..(ranks and(sum..' 点')or'未同步')..'\n\n层级和前置沿用本服经典Talent数据；本服替换节点在悬停中提示。\n\n'..(why or'点击方向仅作浏览，不会切换实际专精。')..'\n\n可打开收藏编辑，再经原流程核对和确认应用。')
 if G.ClassEntry.PlayerClass()==token and not InCombatLockdown()then B.actual:Enable()else B.actual:Disable()end
end
function B.ShowTree(token,index)
 if InCombatLockdown()then G.Message('请脱战后浏览职业天赋树');return false end
 if not data[token]or not data[token][index]then return false end
 B.token=token;B.selected=index;createTree();if B.home then B.home:Hide()end
 B.board.offset=0;B.RefreshTree();C.Fit(B.tree);B.tree:Show();W.Focus(B.tree);return true
end
function B.ShowHome(token)
 if not data[token]then return false end
 B.token=token;createHome();B.RefreshHome();C.Fit(B.home);B.home:Show();W.Focus(B.home);return true
end
function B.Open(token,toggle)
 if InCombatLockdown()then G.Message('请脱战后打开飞升天赋');return false end
 if not data[token]then return false end
 if toggle and B.token==token then
  if B.tree and B.tree:IsShown()then B.tree:Hide();return true end
  if B.home and B.home:IsShown()then B.home:Hide();return true end
 end
 if B.tree then B.tree:Hide()end;return B.ShowHome(token)
end
local events=CreateFrame('Frame');B.events=events
for _,name in ipairs({'CHARACTER_POINTS_CHANGED','PLAYER_TALENT_UPDATE','ACTIVE_TALENT_GROUP_CHANGED','PLAYER_REGEN_ENABLED','PLAYER_REGEN_DISABLED'})do events:RegisterEvent(name)end
events:SetScript('OnEvent',function()if B.home and B.home:IsShown()then B.RefreshHome()end;if B.tree and B.tree:IsShown()then B.RefreshTree()end end)
