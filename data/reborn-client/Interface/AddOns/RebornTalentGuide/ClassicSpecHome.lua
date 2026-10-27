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
local names={WARRIOR='战士',PALADIN='圣骑士',HUNTER='猎人',ROGUE='潜行者',PRIEST='牧师',DEATHKNIGHT='死亡骑士',SHAMAN='萨满',MAGE='法师',WARLOCK='术士',DRUID='德鲁伊',MONK='武僧'}
local data={
 MONK={
 {name='踏风',role='近战输出',stats='连势 · 真气',style='青玉云山',icon='RebornMonk_WindwalkerSpec',description='猛虎身法、拳脚连势；专精方向不等于保存槽。',plan=1},
 {name='野性战斗',role='近战输出 / 坦克',stats='敏捷 · 生存',style='荒野兽群',icon='Ability_Monk_CatForm',description='猫形输出与熊形防护分别提供参考配点，在推荐列表切换用途。',plan=2},
 {name='恢复',role='治疗',stats='法术强度 · 回蓝',style='翡翠古树',icon='Ability_Monk_TreeofLife',description='回春、迅捷治愈与野性成长；留意持续治疗与紧急救援。',plan=4}},
 DRUID={
 {name='平衡',role='远程输出',stats='法术强度 · 命中',style='月光星林',icon='Spell_Nature_StarFall',description='月蚀、虫群与星辰；以枭兽形态协调自然和奥术。',plan=1},
 {name='野性战斗',role='近战输出 / 坦克',stats='敏捷 · 生存',style='荒野兽群',icon='Ability_Druid_CatForm',description='猫形输出与熊形防护分别提供参考配点，在推荐列表切换用途。',plan=2},
 {name='恢复',role='治疗',stats='法术强度 · 回蓝',style='翡翠古树',icon='Ability_Druid_TreeofLife',description='回春、迅捷治愈与野性成长；留意持续治疗与紧急救援。',plan=4}},
 WARLOCK={
 {name='痛苦',role='远程输出',stats='法术强度 · 命中',style='紫绿诅咒废墟',icon='Spell_Shadow_DeathCoil',description='腐蚀、痛苦无常与鬼影缠身；持续伤害配合虹吸。',plan=1},
 {name='恶魔学识',role='远程输出',stats='法术强度 · 宠物协作',style='邪能召唤大厅',icon='Spell_Shadow_Metamorphosis',description='恶魔卫士、契约与变形；留意宠物类型和技能条件。',plan=2},
 {name='毁灭',role='远程输出',stats='法术强度 · 暴击',style='赤金毁灭祭坛',icon='Spell_Fire_Fireball02',description='燃烧、混乱之箭与本服暗火汇聚；按实际说明安排爆发。',plan=3}},
 MAGE={
 {name='奥术',role='远程输出',stats='法术强度 · 法力管理',style='紫金星塔',icon='Spell_Holy_MagicalSentry',description='飞弹与奥术能量；大法师之触、奥术涌动按本服实际说明使用。',plan=1},
 {name='火焰',role='远程输出',stats='法术强度 · 暴击',style='赤金庭院',icon='Spell_Fire_FireBolt02',description='点燃、燃烧与活动炸弹；留意法术连击和持续伤害。',plan=2},
 {name='冰霜',role='远程输出',stats='法术强度 · 命中',style='冰蓝高塔',icon='Spell_Frost_FrostBolt02',description='寒冰护体、水元素与深度冻结；控场配合移动。',plan=3}},
 SHAMAN={
 {name='元素',role='远程输出',stats='法术强度 · 命中',style='雷火高地',icon='Spell_Nature_Lightning',description='闪电、熔岩与图腾协作；本服精研元素统御按实际提示使用。',plan=1},
 {name='增强',role='近战输出',stats='攻击强度 · 命中',style='狼魂荒原',icon='Spell_Shaman_FeralSpirit',description='风暴打击与狼魂；盾牌掌握、熔火劈斩为本服替换节点。',plan=2},
 {name='恢复',role='治疗',stats='法术强度 · 法力续航',style='青碧潮汐',icon='Spell_Shaman_Riptide',description='激流、大地之盾与治疗链；留意法力和治疗时机。',plan=3}},
 DEATHKNIGHT={
 {name='鲜血',role='生存 / 坦克参考',stats='耐力 · 护甲',style='血红黑铁',icon='Spell_Deathknight_BloodPresence',description='血魔之握、饮血者与符文刃舞；本服替换节点请查看实际说明。',plan=1},
 {name='冰霜',role='近战输出',stats='力量 · 命中',style='寒蓝冰晶',icon='Spell_Deathknight_FrostPresence',description='双持利刃、冰霜打击与凛风冲击；管理符文和符文能量。',plan=2},
 {name='邪恶',role='近战输出',stats='力量 · 命中',style='瘟绿墓城',icon='Spell_Deathknight_UnholyPresence',description='疾病、食尸鬼与石像鬼；天灾打击衔接符文循环。',plan=3}},
 PRIEST={
  {name='戒律',role='治疗',stats='智力 · 法术强度',style='护盾与苦修',icon='Spell_Holy_PowerWordShield',description='本服苦修在第七层；净化光芒与末层痛苦压制按实际说明使用。',plan=1},
  {name='神圣',role='治疗',stats='精神 · 法术强度',style='团队治疗',icon='Spell_Holy_GuardianSpirit',description='恢复、治疗之环与守护之魂；注意施法时机和法力。',plan=2},
  {name='暗影',role='远程输出',stats='法术强度 · 命中',style='持续伤害',icon='Spell_Shadow_Shadowform',description='暗影形态、吸血鬼之触与精神鞭笞；技能由玩家使用。',plan=3}},
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
local priestEN={
 {name='Discipline',role='Healer',stats='Intellect / Spell power',style='Shields and Penance',description='Penance is in tier 7. Inspect Purifying Light and the Pain Suppression capstone.'},
 {name='Holy',role='Healer',stats='Spirit / Spell power',style='Group healing',description='Renew, Circle of Healing and Guardian Spirit. Manage timing and mana.'},
 {name='Shadow',role='Ranged DPS',stats='Spell power / Hit',style='Sustained damage',description='Shadowform, Vampiric Touch and Mind Flay. Abilities are used manually.'}}
local deathKnightEN={
 {name='Blood',role='Survival / Tank reference',stats='Stamina / Armor',style='Blood and black iron',description='Gorefiends Grasp, Blood Drinker and Dancing Rune Weapon. Inspect server-specific replacements.'},
 {name='Frost',role='Melee DPS',stats='Strength / Hit',style='Frozen citadel',description='Dual wield, Frost Strike and Howling Blast. Manage runes and runic power.'},
 {name='Unholy',role='Melee DPS',stats='Strength / Hit',style='Plague necropolis',description='Diseases, ghouls and gargoyles. Weave Scourge Strike into your rune cycle.'}}
local shamanEN={
 {name='Elemental',role='Ranged DPS',stats='Spell power / Hit',style='Storm and flame',description='Lightning, lava and totems. Inspect this servers Elemental capstone tooltip.'},
 {name='Enhancement',role='Melee DPS',stats='Attack power / Hit',style='Spirit wolves',description='Stormstrike and spirits. Shield Mastery and Molten Cleave are server replacements.'},
 {name='Restoration',role='Healer',stats='Spell power / Mana sustain',style='Healing tides',description='Riptide, Earth Shield and Chain Heal. Manage mana and healing timing.'}}
local mageEN={
 {name='Arcane',role='Ranged DPS',stats='Spell power / Mana control',style='Violet observatory',description='Missiles and Arcane Power. Inspect this servers Touch of the Magi and Arcane Surge.'},
 {name='Fire',role='Ranged DPS',stats='Spell power / Critical strike',style='Ember courtyard',description='Ignite, Combustion and Living Bomb. Watch Hot Streak and damage over time.'},
 {name='Frost',role='Ranged DPS',stats='Spell power / Hit',style='Frozen tower',description='Ice Barrier, Water Elemental and Deep Freeze. Combine control with movement.'}}
local warlockEN={
 {name='Affliction',role='Ranged DPS',stats='Spell power / Hit',style='Cursed ruins',description='Corruption, Unstable Affliction and Haunt. Combine damage over time with drains.'},
 {name='Demonology',role='Ranged DPS',stats='Spell power / Pet synergy',style='Fel summoning hall',description='Felguard, Demonic Pact and Metamorphosis. Check pet type and ability requirements.'},
 {name='Destruction',role='Ranged DPS',stats='Spell power / Critical strike',style='Chaos altar',description='Conflagrate, Chaos Bolt and this servers Darkfire Convergence. Follow live tooltips.'}}
local druidEN={
 {name='Balance',role='Ranged DPS',stats='Spell power / Hit',style='Moonlit forest',description='Eclipse, Insect Swarm and Starfall. Balance Nature and Arcane in Moonkin Form.'},
 {name='Feral Combat',role='Melee DPS / Tank',stats='Agility / Survival',style='Wild pack',description='Separate cat damage and bear defense references are available in recommendations.'},
 {name='Restoration',role='Healer',stats='Spell power / Mana',style='Emerald grove',description='Rejuvenation, Swiftmend and Wild Growth. Combine ongoing healing with emergency care.'}}
local monkEN={
 {name='Windwalker',role='Melee DPS',stats='Combo / Chi',style='Jade mountains',description='Tiger footwork and flowing combinations. Talent trees are not saved-build slots.'},
 {name='Brewmaster',role='Tank',stats='Stagger / Survival',style='Amber monastery',description='Ox protection, Stagger and brews. Verify the active build before applying.'},
 {name='Mistweaver',role='Healer',stats='Mists / Recovery',style='Bamboo spring',description='Serpent mists and soothing healing. Keep the native three-build confirmation flow.'}}
local function specFor(token,index)
 local spec=data[token][index]
 if (token~='HUNTER'and token~='ROGUE'and token~='PRIEST'and token~='DEATHKNIGHT'and token~='SHAMAN'and token~='MAGE'and token~='WARLOCK'and token~='DRUID'and token~='MONK')or not G.CenterLocale or not G.CenterLocale.English()then return spec end
 local copy={};for k,v in pairs(spec)do copy[k]=v end;for k,v in pairs((token=='MONK'and monkEN or token=='DRUID'and druidEN or token=='WARLOCK'and warlockEN or token=='MAGE'and mageEN or token=='SHAMAN'and shamanEN or token=='DEATHKNIGHT'and deathKnightEN or token=='PRIEST'and priestEN or token=='ROGUE'and rogueEN or hunterEN)[index])do copy[k]=v end;return copy
end
local function tr(zh,en)if (B.token=='HUNTER'or B.token=='ROGUE'or B.token=='PRIEST'or B.token=='DEATHKNIGHT'or B.token=='SHAMAN'or B.token=='MAGE'or B.token=='WARLOCK'or B.token=='DRUID'or B.token=='MONK')and G.CenterLocale and G.CenterLocale.English()then return en end;return zh end
local featured={MONK={{9268,9234,9272},{9274,9235,9280},{9256,9258,9263}},DRUID={{793,1924,1926},{1162,1796,1927},{844,1791,1917}},WARLOCK={{1041,1670,2041},{1672,1885,1886},{966,968,1891}},MAGE={{87,1729,1847},{29,36,1852},{71,1741,1857}},SHAMAN={{573,1687,2053},{616,901,2058},{590,1698,2064}},DEATHKNIGHT={{1941,1936,1961},{1975,1979,1989},{1984,2216,2000}},HUNTER={{1387,1386,1803},{1345,1361,2135},{1325,1322,2145}},ROGUE={{280,1719,2071},{223,205,2076},{1722,1714,2081}},PRIEST={{322,1774,1897},{1637,1815,1911},{521,1779,1910}}}
local function native(token)return RebornTalentCollections.NativeData(token)end
local function scan(token)
 if not G.ClassEntry or G.ClassEntry.PlayerClass()~=token then return nil,'当前不是本人同职业'end
 if token=='HUNTER'or token=='ROGUE'or token=='PRIEST'or token=='DEATHKNIGHT'or token=='SHAMAN'or token=='MAGE'or token=='WARLOCK'or token=='DRUID'or token=='MONK'then return RebornTalentCollections.NativeEngine(token).Scan()end
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
   button:SetScript('OnLeave',function()GameTooltip:Hide()end);button:SetScript('OnClick',function()B.ShowTree(B.token,index)end);card.samples[j]=button
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
 B.home.title:SetText(tr('飞升 · '..names[token]..'天赋','Ascension / '..(token=='MONK'and'Monk'or token=='DRUID'and'Druid'or token=='WARLOCK'and'Warlock'or token=='MAGE'and'Mage'or token=='SHAMAN'and'Shaman'or token=='DEATHKNIGHT'and'Death Knight'or token=='PRIEST'and'Priest'or token=='ROGUE'and'Rogue'or'Hunter')..' Talents')..' · TG31A')
 B.library:SetText(tr('我的天赋收藏','My favorites'))
 B.home.note:SetText(tr('选择方向，浏览天赋；不会洗点、切换专精或自动加点。','Browse a tree. This does not reset, switch specialization or learn talents.'))
 for i,card in ipairs(B.cards)do
  local spec=specFor(token,i);card.name:SetText(spec.name);card.role:SetText(spec.role);card.description:SetText(spec.description)
  card.stats:SetText(tr('主要属性：','Stats: ')..spec.stats);card.style:SetText(tr('战斗方式：','Style: ')..spec.style)
  card.choose:SetText(tr('查看天赋','View talents'));card.sampleTitle:SetText(tr('代表天赋（展示）','Featured talents'))
  card.roleIcon:SetTexture('Interface\\Icons\\'..spec.icon)
  card.picture:SetTexture('Interface\\AddOns\\RebornTalentGuide\\Art\\'..stem..'SpecCardsTG10A_blp')
  card.picture:SetTexCoord((i-1)/3*.75,i/3*.75,0,.60546875)
  if token=='HUNTER'or token=='ROGUE'or token=='PRIEST'or token=='DEATHKNIGHT'or token=='SHAMAN'or token=='MAGE'or token=='WARLOCK'or token=='DRUID'or token=='MONK'then card.picture:SetTexture('Interface\\AddOns\\RebornTalentGuide\\Art\\'..({HUNTER='Hunter',ROGUE='Rogue',PRIEST='Priest',DEATHKNIGHT='DeathKnight',SHAMAN='Shaman',MAGE='Mage',WARLOCK='Warlock',DRUID='Druid',MONK='Monk'})[token]..'SpecCards'..(token=='MONK'and'TG31A'or token=='DRUID'and'TG30A'or token=='WARLOCK'and'TG29A'or token=='MAGE'and'TG28A'or token=='SHAMAN'and'TG27A'or token=='DEATHKNIGHT'and'TG26A'or'TG25A')..'_blp')end
  local tree=d.trees[i];local examples={tree[1],tree[math.ceil(#tree/2)],tree[#tree]};if featured[token]then local byId={};for _,n in ipairs(tree)do byId[n.id]=n end;for j,id in ipairs(featured[token][i])do examples[j]=byId[id]or examples[j]end end
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
  local spec=data[B.token][B.selected];if B.token=='HUNTER'or B.token=='ROGUE'or B.token=='PRIEST'or B.token=='DEATHKNIGHT'or B.token=='SHAMAN'or B.token=='MAGE'or B.token=='WARLOCK'or B.token=='DRUID'or B.token=='MONK'then B.tree:Hide();G.TalentCenter.Open('recommend',B.token,spec.plan);return end;G.Navigation.Return(names[B.token],spec.plan);G.Navigation.OpenLarge()
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
 B.tree.title:SetText(tr('飞升 · '..names[token],'Ascension / '..(token=='MONK'and'Monk'or token=='DRUID'and'Druid'or token=='WARLOCK'and'Warlock'or token=='MAGE'and'Mage'or token=='SHAMAN'and'Shaman'or token=='DEATHKNIGHT'and'Death Knight'or token=='PRIEST'and'Priest'or token=='ROGUE'and'Rogue'or'Hunter'))..' · '..spec.name..' · TG31A')
 B.back:SetText(tr('返回专精首页','Specializations'));B.treeLibrary:SetText(tr('我的天赋收藏','My favorites'));B.compare:SetText(tr('三系推荐对照','Compare builds'));B.edit:SetText(tr('打开收藏编辑方案','Open favorites'));B.actual:SetText(tr('打开原经典天赋面板','Native talent panel'));B.refresh:SetText(tr('刷新当前点数','Refresh points'))
 B.tree.note:SetText(tr('此页只读；经收藏确认应用。左右下角拖动缩放。','Read-only preview. Confirm in favorites to apply. Drag lower corners to resize.'))
 for i,b in ipairs(B.tabs)do b:SetText((i==index and'● 'or'')..specFor(token,i).name);b:Select(i==index)end
 B.background:SetTexture('Interface\\AddOns\\RebornTalentGuide\\Art\\'..(token=='WARRIOR'and'Warrior'or'Paladin')..'Spec'..index..'TG10A_blp')
 B.background:SetTexCoord(0,.787109375,0,.755859375);B.background:SetAlpha(1);B.background:Show()
 if token=='HUNTER'or token=='ROGUE'or token=='PRIEST'or token=='DEATHKNIGHT'or token=='SHAMAN'or token=='MAGE'or token=='WARLOCK'or token=='DRUID'or token=='MONK'then B.background:SetTexture('Interface\\AddOns\\RebornTalentGuide\\Art\\'..({HUNTER='Hunter',ROGUE='Rogue',PRIEST='Priest',DEATHKNIGHT='DeathKnight',SHAMAN='Shaman',MAGE='Mage',WARLOCK='Warlock',DRUID='Druid',MONK='Monk'})[token]..'Spec'..index..(token=='MONK'and'TG31A'or token=='DRUID'and'TG30A'or token=='WARLOCK'and'TG29A'or token=='MAGE'and'TG28A'or token=='SHAMAN'and'TG27A'or token=='DEATHKNIGHT'and'TG26A'or'TG25A')..'_blp');B.board:SetBackdropColor(.015,.02,.025,.50)else B.board:SetBackdropColor(.02,.03,.04,.15)end
 local sum=0;local tree=d.trees[index];local edges,items,ids={},{},{}
 for _,n in ipairs(tree)do ids[n.id]=true end
 for i,n in ipairs(tree)do
  local rank=ranks and ranks[index][i]or nil;if rank then sum=sum+rank end
  local _,_,icon=GetSpellInfo(n.spells[1])
  local item={id=n.id,x=245+(n.col-1)*110,y=28+(n.row-1)*62,size=34,icon=icon or n.icon,name=tr(n.name,n.nameEN or n.name),spell=n.spells[math.max(1,rank or 0)],maximum=n.max,target=rank or 0,actual=rank,shape=n.max>1 and'circle'or'square'}
  item.tooltip=function(tooltip)
   tooltip:AddLine(tr(n.name,n.nameEN or n.name)..' · TalentID '..n.id,1,.82,.3,true)
   tooltip:AddLine(tr('第'..n.row..'层 · 当前 ','Tier '..n.row..' / Learned: ')..(rank==nil and tr('未同步','Unavailable')or(rank..'/'..n.max)),1,1,1,true)
   if n.dep~=0 then tooltip:AddLine(tr('前置TalentID '..n.dep..'，至少 '..n.depRank..' 点','Requires TalentID '..n.dep..', '..n.depRank..' points'),.8,.85,.9,true)end
   if n.changed then tooltip:AddLine(tr('本服调整节点，请以实际技能说明为准。','Server-adjusted talent; inspect the current spell.'),1,.7,.3,true)end
   tooltip:AddLine('只读；编辑收藏不会修改角色。 / Read-only; editing a favorite does not change your character.',.7,.7,.7,true)
  end
  items[#items+1]=item;if n.dep~=0 and ids[n.dep]then edges[#edges+1]={n.dep,n.id}end
 end
 B.board.title:SetText(spec.name..tr(' · 当前已学 ',' / Learned: ')..(ranks and sum or tr('未同步','Unavailable')))
 C.ScrollTree(B.board,items,false);C.Paint(B.board,items,edges,{current=true,captionBelow=true})
 B.info:SetText(spec.name..' · '..spec.role..'\n\n'..spec.description..'\n\n主要属性：'..spec.stats..'\n战斗方式：'..spec.style..'\n\n当前本系：'..(ranks and(sum..' 点')or'未同步')..'\n\n层级和前置沿用本服经典Talent数据；本服替换节点在悬停中提示。\n\n'..(why or'点击方向仅作浏览，不会切换实际专精。')..'\n\n可打开收藏编辑，再经原流程核对和确认应用。')
 if (token=='HUNTER'or token=='ROGUE'or token=='PRIEST'or token=='DEATHKNIGHT'or token=='SHAMAN'or token=='MAGE'or token=='WARLOCK'or token=='DRUID'or token=='MONK')and G.CenterLocale.English()then B.info:SetText(spec.name..' / '..spec.role..'\n\n'..spec.description..'\n\nStats: '..spec.stats..'\nStyle: '..spec.style..'\n\nLearned: '..(ranks and sum or 'Unavailable')..'\n\nUses this server talent layout and prerequisites. Browsing does not switch specialization. Apply through the confirmation flow in favorites.')end
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

