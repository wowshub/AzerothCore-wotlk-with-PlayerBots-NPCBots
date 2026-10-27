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
local names={WARRIOR='战士',PALADIN='圣骑士',HUNTER='猎人',ROGUE='潜行者'}
local data={
 ROGUE={
  {name='刺杀',role='近战输出',stats='敏捷 · 双匕首',style='毒药与毁伤',icon='Ability_Rogue_Eviscerate',description='本服毁灭之刃会消耗生命；确认技能说明再使用。',plan=1},
  {name='战斗',role='近战输出',stats='敏捷 · 双持剑斧',style='劈斩与连击',icon='Ability_BackStab',description='劈斩需要剑或斧；杀戮盛筵要注意位置。',plan=2},
  {name='敏锐',role='近战输出',stats='敏捷 · 武器条件',style='潜行与机动',icon='Ability_Stealth',description='暗影步、暗影之舞与装死；机制参考方案。',plan=3}},
 HUNTER={
  {name='野兽控制',role='远程输出',stats='敏捷 · 宠物',style='兽群协同',icon='Ability_Hunter_BeastTaming',description='狂野怒火与宠物协同；宠物天赋独立处理。',plan=1},
  {name='射击',role='远程输出',stats='敏捷 · 远程武器',style='独狼射击',icon='Ability_Marksmanship',description='本服独狼需要无激活宠物；浏览替换节点再决定配点。',plan=2},
  {name='生存',role='远程输出',stats='敏捷 · 暴击',style='陷阱与爆炸',icon='Ability_Hunter_SwiftStrike',description='爆炸射击、黑箭与陷阱联动；注意站位。',plan=3}},
 WARRIOR={
  {name='武器',role='近战输出',stats='力量',style='双手兵刃',icon='Ability_Warrior_OffensiveStance',description='掌握双手兵刃与战斗节奏，以经典武器系节点构筑你的战斗方式。',plan=3},
  {name='狂怒',role='近战输出',stats='力量',style='双持追击',icon='Ability_Warrior_InnerRage',description='围绕怒气与连续攻击展开战斗；双持资格与技能效果以本服已学为准。',plan=2},
  {name='防护',role='坦克',stats='耐力 · 力量',style='剑盾守护',icon='Ability_Warrior_DefensiveStance',description='以盾牌、生存和威胁控制守护队伍，沿经典防护系查看每层前置。',plan=1}},
 PALADIN={
  {name='神圣',role='治疗',stats='智力 · 法术强度',style='圣光救援',icon='Spell_Holy_HolyBolt',description='以圣光治疗与保护盟友，浏览本服神圣系的治疗和续航节点。',plan=1},
  {name='防护',role='坦克',stats='耐力 · 力量',style='盾牌守护',icon='Spell_Holy_DevotionAura',description='以圣盾、祝福和威胁控制承受攻击，查看本服防护系的实际替换。',plan=2},
  {name='惩戒',role='近战输出',stats='力量',style='圣印审判',icon='Spell_Holy_AuraOfLight',description='运用圣印与审判展开近战，按本服实际技能查看经典惩戒系。',plan=3}}}
local hunterEN={
 {name='Beast Mastery',role='Ranged DPS',stats='Agility / Pet',style='Pet teamwork',description='Bestial Wrath and pet synergy. Pet talents are managed separately.'},
 {name='Marksmanship',role='Ranged DPS',stats='Agility / Ranged weapon',style='Lone Wolf',description='Lone Wolf requires no active pet on this server. Inspect the replacement talent.'},
 {name='Survival',role='Ranged DPS',stats='Agility / Critical strike',style='Traps and explosives',description='Explosive Shot, Black Arrow and traps. Plan your positioning.'}}
local rogueEN={
 {name='Assassination',role='Melee DPS',stats='Agility / Daggers',style='Poisons and Mutilate',description='Blades of Desolation costs health on this server. Read the spell before use.'},
 {name='Combat',role='Melee DPS',stats='Agility / Swords or axes',style='Dual wield attacks',description='Hack and Slash needs swords or axes. Plan safe Killing Spree positioning.'},
 {name='Subtlety',role='Melee DPS',stats='Agility / Weapon requirements',style='Stealth and mobility',description='Shadowstep, Shadow Dance and Cheat Death. A mechanics reference.'}}
local function specFor(token,index)
 local spec=data[token][index]
 if (token~='HUNTER'and token~='ROGUE')or not G.CenterLocale or not G.CenterLocale.English()then return spec end
 local copy={};for k,v in pairs(spec)do copy[k]=v end;for k,v in pairs((token=='ROGUE'and rogueEN or hunterEN)[index])do copy[k]=v end;return copy
end
local function tr(zh,en)if (B.token=='HUNTER'or B.token=='ROGUE')and G.CenterLocale and G.CenterLocale.English()then return en end;return zh end
local function native(token)return RebornTalentCollections.NativeData(token)end
local function scan(token)
 if not G.ClassEntry or G.ClassEntry.PlayerClass()~=token then return nil,'当前不是本人同职业'end
 if token=='HUNTER'or token=='ROGUE'then return RebornTalentCollections.NativeEngine(token).Scan()end
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
  atlas(card,'spec-dividerline',69,-495,290,2);card.sampleTitle=label(card,'代表天赋（展示）',-506,'GameFontHighlightSmall')
  card.samples={}
  for j=1,3 do
   local button=CreateFrame('Button',nil,card);button:SetPoint('TOPLEFT',140+(j-1)*52,-530);button:SetSize(44,44)
   button.icon=button:CreateTexture(nil,'ARTWORK');button.icon:SetAllPoints()
   button.border=button:CreateTexture(nil,'OVERLAY');button.border:SetAllPoints();button.border:SetTexture('Interface\\Buttons\\UI-Quickslot2')
   button:SetScript('OnEnter',function(self)if not self.node then return end;GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:SetText(tr(self.node.name,self.node.nameEN or self.node.name),1,.82,0);GameTooltip:AddLine('代表节点；点击查看前置，不会自动学习。 / Preview only; inspect prerequisites before learning.',1,1,1,true);GameTooltip:Show()end)
   button:SetScript('OnLeave',function()GameTooltip:Hide()end);card.samples[j]=button
  end
  card.points=label(card,'',-576,'GameFontHighlightSmall')
  card.choose=C.Button(card,76,-595,280,'查看天赋',function()B.ShowTree(B.token,index)end)
  B.cards[i]=card
 end
 B.homeLanguage=C.Button(f,850,-3,150,'中 / EN',function()local L=G.CenterLocale;L.Set(L.English()and'zhCN'or'enUS');B.RefreshHome()end);B.homeLanguage:SetHeight(20)
 B.library=C.Button(f,1030,-3,230,'我的天赋收藏',function()RebornTalentCollections.Open(B.token)end);B.library:SetHeight(20)
 f.note:SetText('选择方向，浏览对应的经典天赋树；不会洗点、切换专精或自动加点。')
end
function B.RefreshHome()
 if not B.home or not B.token then return end
 B.homeBackground:SetAlpha(1);B.homeBackground:Show()
 local token=B.token;local d=native(token);local ranks=scan(token);local stem=token=='WARRIOR'and'Warrior'or'Paladin'
 B.home.title:SetText(tr('飞升 · '..names[token]..'天赋','Ascension / '..(token=='ROGUE'and'Rogue'or'Hunter')..' Talents')..' · TG24B')
 B.library:SetText(tr('我的天赋收藏','My favorites'))
 B.home.note:SetText(tr('选择方向，浏览天赋；不会洗点、切换专精或自动加点。','Browse a tree. This does not reset, switch specialization or learn talents.'))
 for i,card in ipairs(B.cards)do
  local spec=specFor(token,i);card.name:SetText(spec.name);card.role:SetText(spec.role);card.description:SetText(spec.description)
  card.stats:SetText(tr('主要属性：','Stats: ')..spec.stats);card.style:SetText(tr('战斗方式：','Style: ')..spec.style)
  card.choose:SetText(tr('查看天赋','View talents'));card.sampleTitle:SetText(tr('代表天赋（展示）','Featured talents'))
  card.roleIcon:SetTexture('Interface\\Icons\\'..spec.icon)
  card.picture:SetTexture('Interface\\AddOns\\RebornTalentGuide\\Art\\'..stem..'SpecCardsTG10A_blp')
  card.picture:SetTexCoord((i-1)/3*.75,i/3*.75,0,.60546875)
  if token=='HUNTER'or token=='ROGUE'then card.picture:SetTexture('Interface\\Icons\\'..spec.icon);card.picture:SetTexCoord(.05,.95,.15,.85)end
  local tree=d.trees[i];local examples={tree[1],tree[math.ceil(#tree/2)],tree[#tree]}
  for j,button in ipairs(card.samples)do local n=examples[j];local _,_,icon=GetSpellInfo(n.spells[1]);button.node=n;button.icon:SetTexture(icon or n.icon)end
  local sum=0;if ranks then for _,n in ipairs(ranks[i])do sum=sum+n end end
  card.points:SetText(ranks and(tr('当前已学 ','Learned: ')..sum)or tr('当前点数尚未就绪','Points not available'))
 end
end
local function createTree()
 if B.tree then return end
 local f=C.Window('RebornClassicSpecTree','飞升 · 专精天赋 · TG14A');B.tree=f;W.Register('classicSpecTree',f)
 B.back=C.Button(f,20,-40,170,'返回专精首页',function()B.tree:Hide();B.ShowHome(B.token)end)
 B.tabs={}
 for i=1,3 do local index=i;B.tabs[i]=C.Button(f,205+(i-1)*165,-40,155,'',function()B.selected=index;B.board.offset=0;B.RefreshTree()end)end
 B.treeLanguage=C.Button(f,850,-3,150,'中 / EN',function()local L=G.CenterLocale;L.Set(L.English()and'zhCN'or'enUS');B.RefreshTree()end);B.treeLanguage:SetHeight(20)
 B.treeLibrary=C.Button(f,1030,-3,230,'我的天赋收藏',function()RebornTalentCollections.Open(B.token)end);B.treeLibrary:SetHeight(20)
 B.compare=C.Button(f,1030,-40,240,'三系推荐对照',function()
  local spec=data[B.token][B.selected];if B.token=='HUNTER'or B.token=='ROGUE'then B.tree:Hide();G.TalentCenter.Open('recommend',B.token,spec.plan);return end;G.Navigation.Return(names[B.token],spec.plan);G.Navigation.OpenLarge()
 end)
 B.background=f:CreateTexture(nil,'BORDER');B.background:SetPoint('TOPLEFT',7,-30);B.background:SetSize(1280,620)
 B.infoShade=f:CreateTexture(nil,'ARTWORK');B.infoShade:SetPoint('TOPLEFT',915,-82);B.infoShade:SetSize(350,548);B.infoShade:SetTexture(.02,.025,.035,.76)
 B.board=C.Board(f,14,-80,885,550,'');B.board:SetBackdropColor(.02,.03,.04,.15)
 B.info=C.Text(f,929,-97,324,'','GameFontHighlight');B.info:SetSpacing(5)
 B.edit=C.Button(f,935,-542,320,'打开收藏编辑方案',function()RebornTalentCollections.Open(B.token)end)
 B.actual=C.Button(f,935,-580,320,'打开原经典天赋面板',function()G.Navigation.Actual(names[B.token])end)
 B.refresh=C.Button(f,1035,-648,225,'刷新当前点数',B.RefreshTree)
 f.note:SetWidth(940);f.note:SetText('沿用经典节点、层级和前置。此页只读；编辑与应用使用已有收藏和原确认流程。左右下角拖动缩放。')
end
function B.RefreshTree()
 if not B.tree or not B.token then return end
 local token=B.token;local index=B.selected or 1;local spec=specFor(token,index);local d=native(token);local ranks,why=scan(token)
 B.tree.title:SetText(tr('飞升 · '..names[token],'Ascension / '..(token=='ROGUE'and'Rogue'or'Hunter'))..' · '..spec.name..' · TG24B')
 B.back:SetText(tr('返回专精首页','Specializations'));B.treeLibrary:SetText(tr('我的天赋收藏','My favorites'));B.compare:SetText(tr('三系推荐对照','Compare builds'));B.edit:SetText(tr('打开收藏编辑方案','Open favorites'));B.actual:SetText(tr('打开原经典天赋面板','Native talent panel'));B.refresh:SetText(tr('刷新当前点数','Refresh points'))
 B.tree.note:SetText(tr('此页只读；经收藏确认应用。左右下角拖动缩放。','Read-only preview. Confirm in favorites to apply. Drag lower corners to resize.'))
 for i,b in ipairs(B.tabs)do b:SetText((i==index and'● 'or'')..specFor(token,i).name);b:Select(i==index)end
 B.background:SetTexture('Interface\\AddOns\\RebornTalentGuide\\Art\\'..(token=='WARRIOR'and'Warrior'or'Paladin')..'Spec'..index..'TG10A_blp')
 B.background:SetTexCoord(0,.787109375,0,.755859375);B.background:SetAlpha(1);B.background:Show()
 if token=='HUNTER'or token=='ROGUE'then B.background:SetTexture(.025,.075,.045,.92);B.background:SetTexCoord(0,1,0,1)end
 local sum=0;local tree=d.trees[index];local edges,items,ids={},{},{}
 for _,n in ipairs(tree)do ids[n.id]=true end
 for i,n in ipairs(tree)do
  local rank=ranks and ranks[index][i]or nil;if rank then sum=sum+rank end
  local _,_,icon=GetSpellInfo(n.spells[1])
  local item={id=n.id,x=245+(n.col-1)*110,y=28+(n.row-1)*62,size=34,icon=icon or n.icon,name=tr(n.name,n.nameEN or n.name),spell=n.spells[math.max(1,rank or 0)],maximum=n.max,target=rank or 0,actual=rank,shape=n.max>1 and'circle'or'square'}
  item.tooltip=function(tooltip)
   tooltip:AddLine(tr(n.name,n.nameEN or n.name)..' · TalentID '..n.id,1,.82,.3,true)
   tooltip:AddLine('第'..n.row..'层 · 当前 '..(rank==nil and'未同步'or(rank..'/'..n.max)),1,1,1,true)
   if n.dep~=0 then tooltip:AddLine('前置TalentID '..n.dep..'，至少 '..n.depRank..' 点',.8,.85,.9,true)end
   if n.changed then tooltip:AddLine('本服替换节点，请以实际技能说明为准。',1,.7,.3,true)end
   tooltip:AddLine('只读；编辑收藏不会修改角色。 / Read-only; editing a favorite does not change your character.',.7,.7,.7,true)
  end
  items[#items+1]=item;if n.dep~=0 and ids[n.dep]then edges[#edges+1]={n.dep,n.id}end
 end
 B.board.title:SetText(spec.name..tr(' · 当前已学 ',' / Learned: ')..(ranks and sum or tr('未同步','Unavailable')))
 C.ScrollTree(B.board,items,false);C.Paint(B.board,items,edges,{current=true,captionBelow=true})
 B.info:SetText(spec.name..' · '..spec.role..'\n\n'..spec.description..'\n\n主要属性：'..spec.stats..'\n战斗方式：'..spec.style..'\n\n当前本系：'..(ranks and(sum..' 点')or'未同步')..'\n\n层级和前置沿用本服经典Talent数据；本服替换节点在悬停中提示。\n\n'..(why or'点击方向仅作浏览，不会切换实际专精。')..'\n\n可打开收藏编辑，再经原流程核对和确认应用。')
 if (token=='HUNTER'or token=='ROGUE')and G.CenterLocale.English()then B.info:SetText(spec.name..' / '..spec.role..'\n\n'..spec.description..'\n\nStats: '..spec.stats..'\nStyle: '..spec.style..'\n\nLearned: '..(ranks and sum or 'Unavailable')..'\n\nUses this server talent layout and prerequisites. Browsing does not switch specialization. Apply through the confirmation flow in favorites.')end
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
