-- TG23A: display-only localization. Saved builds, names and search keys are never translated.
local G=RebornTalentGuide
local L={bindings={}};G.CenterLocale=L
function L.English()return type(RebornTGViewSettings)=='table'and RebornTGViewSettings.centerLanguage=='enUS'end
local dictionary={
 ['鲜血']='Blood',['冰霜']='Frost',['邪恶']='Unholy',
 ['戒律']='Discipline',['暗影']='Shadow',
 ['刺杀']='Assassination',['战斗']='Combat',['敏锐']='Subtlety',['原生参考方案；应用通过原生接口逐点确认，不自动洗点。']='Reference builds. Each point requires native confirmation; no automatic reset.',
 ['编辑收藏']='Edit Favorite',['当前筛选暂无推荐方案。']='No builds match this filter.',['猎人参考方案；应用通过原生接口逐点确认，不自动洗点。']='Hunter reference builds. Each point requires native confirmation; no automatic reset.',
 ['天赋中心']='Talent Center',['推荐天赋']='Recommended Talents',['我的收藏']='My Favorites',
 ['选择职业']='Choose Class',['天赋加点']='Talent Builds',['我的天赋']='My Talents',
 ['战士']='Warrior',['圣骑士']='Paladin',['猎人']='Hunter',['潜行者']='Rogue',['牧师']='Priest',['死亡骑士']='Death Knight',['萨满']='Shaman',['法师']='Mage',['术士']='Warlock',['德鲁伊']='Druid',['恶魔猎手']='Demon Hunter',['武僧']='Monk',['巫医']='Witch Doctor',
 ['巫毒']='Voodoo',['酿造']='Brewing',['暗影狩猎']='Shadowhunting',['武器']='Arms',['狂怒']='Fury',['防护']='Protection',['神圣']='Holy',['惩戒']='Retribution',['野兽控制']='Beast Mastery',['射击']='Marksmanship',['生存']='Survival',
 ['全部']='All',['练级']='Leveling',['当前等级']='Current Level',['当前天赋加点']='Current Talents',
 ['20级']='Lv. 20',['40级']='Lv. 40',['60级']='Lv. 60',['80级']='Lv. 80',
 ['保存当前的天赋加点']='Save Current Talents',['搜索收藏名称（包含匹配）']='Search by name',
 ['＋ 扩展收藏位']='+ More Favorite Slots',['实际天赋面板']='Actual Talent Panel',['收藏此天赋']='Favorite This Build',
 ['按推荐天赋加点']='Apply Recommended Talents',['保留已学并加点']='Keep Learned & Add Points',
 ['重命名']='Rename',['删除']='Delete',['比较并应用此天赋']='Compare & Apply Build',['查看方案说明']='Build Details',
 ['已登记职业\n未接入推荐的职业显示说明，不套用其他职业天赋。']='Registered classes.\nClasses without templates show an empty state; no substitute builds.',
 ['当前每职业提供1个免费收藏位。扩展方式尚未开放，不会扣费。']='One free favorite per class. Extra slots are not available yet; no charge.',
 ['免费收藏位已用完；已有收藏仍可查看、重命名或删除。扩展尚未开放。']='Free slot used. Existing favorites can be viewed, renamed or deleted. Expansion is not available yet.',
 ['个人收藏 · 只读预览']='Personal favorite - read-only preview',
 ['与实际天赋面板已保存配点一致 · 不包含未保存草稿']='Matches saved talents in the actual panel; unsaved drafts are excluded.',
 ['当前天赋与收藏都只读预览；保存收藏不会改变角色，应用仍需原校验与确认。']='Talents and favorites are previews. Saving a favorite does not change your character. Applying requires validation and confirmation.',
 ['保存收藏不会改变角色；应用需比较并确认。']='Saving a favorite does not change your character. Compare and confirm before applying.',
 ['按推荐天赋加点：保留已学，只载入草稿；请在实际天赋面板核对保存。']='Apply Recommended Talents keeps learned points and loads a draft. Review and save in the actual talent panel.',
 ['此职业尚无可用的推荐或收藏数据。\n不会用其他职业天赋代替。']='No recommendations or favorites are available for this class.\nBuilds from other classes will not be substituted.',
 ['浏览其他职业 · 不显示为本人已加点']='Browsing another class; these are not your spent points.',
 ['通用 AE']='Class AE',['专精 TE']='Spec TE',['已加点']='Spent',['未加点数']='Unspent',
 ['角色']='Character Lv. ',['级 · 已保存方案']=' - Saved Build ',['级 · 当前天赋以已保存数据为准']=' - Showing saved talents',
 ['我的收藏 ']='My Favorites ',[' / 免费1个']=' / 1 free slot',
 ['推荐天赋 · ']='Recommended Talents - ',[' · 只载入草稿或通过原生加点确认']=' - Draft or native talent confirmation',
 ['；保留已学，只载入草稿。']='; keep learned points; load a draft only.',
 ['级：AE ']=': AE ',['推荐']='Recommended Lv. ',['级']='',
 [' · 暂无推荐天赋']=' - No recommended builds',
 ['保存当前的天赋加点\n请输入收藏名称（最多96字节）。']='Save Current Talents\nEnter a favorite name (up to 96 bytes).',
 ['保存收藏']='Save Favorite',['我的天赋']='My Talents',['当前天赋']='Current Talents',
 ['重命名收藏']='Rename Favorite',['保存名称']='Save Name',
 ['当前推荐已改变，请重新确认']='The selected recommendation changed. Confirm again.',
 ['推荐已改变，请重新确认']='The recommendation changed. Confirm again.',
 ['当前方案已改变，请重新确认']='The current build changed. Confirm again.',
 ['职业已改变，请重新保存']='The class changed. Save again.',
 ['收藏快照已改变，请重新保存']='The favorite snapshot changed. Save again.',
 ['收藏选择已改变，请重新确认']='The selected favorite changed. Confirm again.',
 ['已保存收藏；角色天赋未改变']='Favorite saved; character talents unchanged.',
 ['收藏已删除，角色天赋未改变']='Favorite deleted; character talents unchanged.',
 ['已载入草稿，请到实际天赋面板核对保存']='Draft loaded. Review and save in the actual talent panel.',
 ['载入失败']='Could not load the draft',['正在按原生接口逐点加点']='Adding talents through the native interface',['无法开始加点']='Cannot start adding talents',
 ['载入草稿']='Load Draft',['确认加点']='Confirm Talents',['取消']='Cancel',
 ['保留全部已学点数，增加 AE ']='Keep all learned points and add AE ',
 ['？\n只载入草稿，请到实际天赋面板核对保存。']='?\nOnly a draft is loaded. Review and save in the actual talent panel.',
 ['？\n仍通过原生接口逐点确认，不自动重置或收费。']='?\nUses the native talent interface. No automatic reset or charge.',
 ['当前方案已包含本级推荐，本次无需补点']='The current build already includes this level\'s recommendations. No additional points to add.',
 ['本级推荐已全部加入，当前 AE/TE 点数已用完']='All recommendations for this level are included; AE/TE budgets are fully spent.',
 ['本方案推荐节点已全部加入；仍有 AE ']='All recommended nodes are included. Remaining AE ',
 [' 未加点，可在实际天赋面板选择其他合法节点']=' unspent; choose other legal nodes in the actual talent panel.',
 ['当前AE和TE额度已用完，没有可补点数；已存点数保留']='AE and TE budgets are fully spent. Saved points are retained.',
 ['当前没有可补的推荐点数；']='No recommended points can be added now; ',
 ['。已存点数保留']='. Saved points are retained.',
 ['当前有未保存加点，请先在巫医面板保存或撤回']='Unsaved talent changes exist. Save or revert them in the Witch Doctor panel first.',
 ['角色等级与服务器快照不同，请等待同步或到原面板刷新；不会按旧点数载入']='Character level differs from the server snapshot. Wait for sync or refresh the actual panel; stale budgets will not be used.',
 ['请切回当前等级推荐；预览等级方案不能直接载入']='Select Current Level first; fixed-level previews cannot be applied directly.',
 ['请先在巫医面板刷新完整方案，等待服务器同步']='Refresh the complete build in the Witch Doctor panel and wait for server sync.',
 ['请先在巫医面板选择已解锁的当前激活方案']='Select the unlocked, active build in the Witch Doctor panel first.',
 ['当前已保存方案尚未同步']='The saved build has not synchronized yet.',
 ['方案状态已改变，请重新确认']='Build state changed. Confirm again.',
 ['仅可载入自己巫医角色的草稿']='Only your own Witch Doctor draft can be loaded.',
 ['脱战且存活时才可载入草稿']='You must be alive and out of combat to load a draft.',
 ['补点结果试图移除已存节点，已停止']='Stopped: the proposed draft would remove a saved node.',
 ['请启用配套巫医天赋插件，再重新登录']='Enable the matching Witch Doctor talent addon and log in again.',
 ['巫医节点版本不匹配，请使用WD161累计或更新的配套推荐包']='Witch Doctor node versions differ. Install the matching WD161 cumulative or newer recommendation addon.',
 ['巫医校验器不可用']='Witch Doctor validator unavailable',
 ['巫医校验器异常，已停止生成方案']='Witch Doctor validator error; build generation stopped.',
 ['推荐方案不存在']='Recommended build not found',
 ['当前已保存方案不符合规则：']='The saved build fails validation: ',
 ['推荐节点与本服版本不符：']='Recommended node differs from the server version: ',
 ['推荐生成超过安全步数']='Recommendation exceeded its safe iteration limit.',
 ['天赋说明']='Talent Details',['删除收藏']='Delete Favorite',
 ['当前方案已包含本级推荐']='The current build already includes this level\'s recommendations.',
 ['请先在原巫医面板激活并查看同专精的已解锁方案']='Activate and view an unlocked build with the same spec in the actual Witch Doctor panel.',
 ['实际巫医面板有未保存草稿，请先保存或撤回']='The actual Witch Doctor panel has an unsaved draft. Save or revert it first.',
 ['巫医方案尚未完整同步，或缺少原保存接口']='Waiting for a complete Witch Doctor snapshot or the original save interface.',
 ['衣柜正在处理装备，请稍后再应用']='The equipment vault is busy. Apply after it finishes.',
 ['请先在巫医面板绑定并查看本推荐专精；不会自动切换或付费重置']='Bind and view this recommended spec in the Witch Doctor panel first. No automatic spec switch or paid reset.',
 ['等待服务器方案']='Waiting for the server build',['等待同步（旧快照']='Waiting for sync (previous snapshot: ',['点数暂不可读']='Point totals are not available yet',
 ['当前天赋以已保存数据为准']='Showing saved talents',['收藏配点 ']='Favorite rank ',['当前已保存 ']='Saved rank ',['滚轮']='Scroll',
}
-- Replace longest phrases in one pass. Replacement text is never translated again.
local cache={};local cacheCount=0;local keys={};for k in pairs(dictionary)do if not k:match('^%d+级$')then keys[#keys+1]=k end end
table.sort(keys,function(a,b)return #a>#b end)
function L.Text(value)
 if not L.English()or type(value)~='string'then return value end
 if dictionary[value]then return dictionary[value]end
 if cache[value]then return cache[value]end
 if not value:find('[\228-\233][\128-\191][\128-\191]')then return value end
 local out={};local pos=1
 while pos<=#value do
  local match
  for _,k in ipairs(keys)do if value:sub(pos,pos+#k-1)==k then match=k;break end end
  if match then out[#out+1]=dictionary[match];pos=pos+#match else out[#out+1]=value:sub(pos,pos);pos=pos+1 end
 end
 local translated=table.concat(out)
 -- Keep dynamic messages bounded across long sessions.
 if cacheCount>=256 then cache={};cacheCount=0 end
 cache[value]=translated;cacheCount=cacheCount+1
 return translated
end
function L.Bind(widget,key)L.bindings[widget]=key;widget:SetText(L.Text(key));return widget end
function L.Refresh()for widget,key in pairs(L.bindings)do widget:SetText(L.Text(key))end end
function L.Set(language)
 if language~='enUS'and language~='zhCN'then return end
 RebornTGViewSettings=RebornTGViewSettings or{};RebornTGViewSettings.centerLanguage=language
 L.Refresh();local T=G.TalentCenter
 if T and T.frame then
  local details=T.details and T.details:IsShown()
  T.Refresh();if T.language then T.language:SetText(L.English()and'中文'or'EN')end
  if details and T.detailsButton then local click=T.detailsButton:GetScript('OnClick');if click then click(T.detailsButton)end end
 end
end
function L.Toggle()L.Set(L.English()and'zhCN'or'enUS')end
function L.Popup(key)
 local d=StaticPopupDialogs[key];if not d or not L.English()then return end
 -- Delete contains an arbitrary player-provided name: never translate its payload.
 if key~='REBORN_TG_CENTER_DELETE'then d.text=L.Text(d.text)end
 d.button1=L.Text(d.button1);d.button2='Cancel'
end
-- Private preset translations; originals remain the validation/navigation keys.
local preset={
 ['练级 · 暗影续航']={'Leveling - Shadow Sustain','Solo quests and individual enemies. Prioritize damage, Spirits and survival; abilities remain subject to actual level requirements.','Prioritize ranged weapons, hit and ranged AP; intellect/agility benefit Sen\'jin\'s Apprentice. Sustain comes first; this is not a gear ranking.','Choose Soul Hunting over Death Hex. Hexfire Serpents/Soul Striker and Snake Charmer/Viper Ward are exclusive choices.',{'Prepare healing/Mimic Ward. Use Malefic Wrath; use Soul Reclamation when short of Spirits.','Use Soul Glaive on the main target. A successfully completed Soul Volley grants a Spirit and reduces the current Glaive cooldown.','Use Mirage or Shadowstalking for danger and Vol\'jin\'s Watch for protection. Feign death does not guarantee an encounter reset.'}},
 ['单体 · 战刃联动']={'Single Target - Glaive Synergy','Bosses and single targets. Build around five Spirits, Soul Eclipse, Price and Soul Glaive.','Ranged AP, hit and agility/intellect. The Gift\'s 15% ranged haste requires your own living Mimic.','Choose Soul Striker over Hexfire Serpents. Dambala is consumed by Shadowflame after Eclipse; the unselected Bwonsamdi option strengthens splash by 40%, not the primary hit.',{'Start with your Mimic and Serpent Ward; build five Spirits.','Complete Soul Eclipse at five Spirits, then use normal Soul Glaive within the 8-second Price window for the critical strike and cooldown synergy.','A completed Soul Volley reduces an active Glaive cooldown by 3 seconds. Becoming ready alone does not reduce it.','After Price Glaive, consume Dambala with Shadowflame within 15 seconds; use Shadow Avatar and Vol\'jin\'s Blessing for Glaive recovery.'}},
 ['群体 · 巫毒扩散']={'Area Damage - Voodoo Spread','Clustered enemies and sustained area damage, using Malicious Hex, Strings, Hexfire and puppet synergies.','Follow current Voodoo spell-power coefficients; balance intellect, hit and mana recovery. Do not copy the ranged-AP Shadow build.','Choose This Is Voodoo over Ethereal Spirit. No Shadowhunting TE or Glaive/Volley rotation is mixed into this build.',{'Apply your own Puppeteer\'s Strings/Malicious Hex, then place the appropriate puppet and summons.','Use Hexfire on your own String target to release stored Voodoo Spirit damage and gain Spirits.','Use Hex spread, bursts and Shadowflame against groups; avoid breaking planned crowd control.','Use advanced summons and Other Side when unlocked. Check basic Ward, Mimic and Effigy limits separately.'}},
 ['支援 · 酿造治疗']={'Support - Brewing Healer','Group healing, ingredient buffs and dispels. NPCBots are not player targets for Spirit Link health balancing.','Prioritize spirit, healing power and mana sustain. Shared Potent Mixes uses the stronger family bonus, without duplicate healing or threat reduction.','Choose Jungle Doctor over Jungle Bloom; Earthroot/Peacebloom, Spirit Outside/Spirit Touch and Rage/Arcane Brew are exclusive choices.',{'Prepare Jungle Mushrooms. Bartender permits a second ingredient; a third replaces the oldest.','Use Potion Toss for urgent single-target healing, Splash for clustered allies, and Loa\'s Brew for direct healing and synergies.','Stand still for Mojo Beam. Branches cost extra mana; echoes do not create more branches or reduce potion cooldown.','Use Tiki Splash with a base available. Spirit Link balances player teammates only; NPCBots are excluded.'}},
}
local titles={['防护 · 副本承伤']='Protection - Dungeon Tank',['狂怒 · 双持输出']='Fury - Dual Wield',['武器 · 战场压制']='Arms - Battleground Pressure',['武器 · 副本输出']='Arms - Dungeon Damage',['狂怒 · 战场追击']='Fury - Battleground Pursuit',['防护 · 战场控场']='Protection - Battleground Control',['神圣 · 团队治疗']='Holy - Group Healing',['惩戒 · 副本输出']='Retribution - Dungeon Damage',['神圣 · 竞技治疗']='Holy - PvP Healing',['防护 · 战场护卫']='Protection - Battleground Escort',['惩戒 · 竞技压制']='Retribution - PvP Pressure'}
function L.Plan(p,field)
 if not p then return''end
 if not L.English()then if field=='rotation'then return p.rotation or{}end;return p[field]or''end
 if p[field..'EN']then return p[field..'EN']end
 local row=preset[p.title]
 if row then
  if field=='rotation'then return row[5]end
  local index=({title=1,purpose=2,stats=3,conflicts=4})[field];if index then return row[index]end
  if field=='reserveNote'then return p.spec==1 and'Level 80: 36 AE / 35 TE. Shared Potent Mixes uses the stronger bonus and does not stack; the final class point completes the legal allocation.'or'Level 80 adds damage, sustain and group dispel tools. Lower levels retain real prerequisites. Shadow TE still observes its 23-point gate.'end
 end
 if field=='title'then return titles[p.title]or L.Text(p.title)end
 if field=='body'then return L.nativeBodies[p.title]or''end
 if field=='rotation'then return{}end
 return L.Text(p[field]or'')
end
L.nativeBodies={
 ['防护 · 副本承伤']='Dungeon tank reference. Use a suitable one-handed weapon and shield, defensive gear and threat tools. Warrior and Paladin use different native trees. Server replacements must be checked in their actual spell tooltips. Talent allocation alone does not change a bot\'s role or strategy; configure that separately.',
 ['狂怒 · 双持输出']='Dual-wield dungeon damage reference: Precision, Flurry and Titan\'s Grip. Adjust hit talents to gear. Death Wish, Bloodthirst and Bloodsurge have server replacements; do not copy an unmodified retail rotation or assume historical server bugs exist here.',
 ['武器 · 战场压制']='Battleground/arena practice with a two-handed axe or polearm. Balance Mortal Strike, Hamstring, Second Wind and mobility. Adapt weapon specialization for swords/maces. Improved Mortal Strike has two ranks; the top talent is a server replacement. Arena performance is not guaranteed.',
 ['武器 · 副本输出']='Dungeon damage practice with a two-handed axe or polearm. Build around Rend, Taste for Blood, Deep Wounds and Mortal Strike, with less PvP utility. This is a server-specific 57/14/0 candidate, not the original guide\'s 55/8/8. Replacement spells require rotation testing.',
 ['狂怒 · 战场追击']='Dual-wield battleground pursuit with healer support. Emphasizes Piercing Howl, Blood Craze, Improved Intercept and Furious Attacks; reduces rage/Execute/Precision investment. Gear must supply the remaining hit. Fewer control tools than Arms; native server replacements still apply.',
 ['防护 · 战场控场']='Shield-based battleground control, escort and Shield Slam pressure. Adds Iron Will, Tactical Mastery, Improved Spell Reflection and Disarm at the expense of dungeon avoidance and damage. Not a universal main-tank build. Last Stand and Shockwave are server replacements.',
 ['神圣 · 团队治疗']='Level-80 healing practice: casting stability, critical-strike sustain and group protection. Core talents: Holy Shock, Infusion of Light and Beacon of Light. Learn spell ranks from the trainer and verify Beacon targets. This server-generated 51/20/0 candidate is not claimed identical to an external guide.',
 ['惩戒 · 副本输出']='Level-80 melee damage practice: Judgements of the Wise, The Art of War and Divine Storm, with group protection. Talent 1823 is Divine Steed and 1410 is Righteous Combatant on this server. Inspect actual spells and trained ranks before building a rotation; do not assume retail Crusader Strike.',
 ['神圣 · 竞技治疗']='Level-80 PvP healing candidate: Aura Mastery, Improved Concentration Aura, Holy Shock, Sacred Cleansing, Infusion of Light and Beacon, with Freedom and stuns. Watch enemy control/dispels and save protection for interrupt windows. Budget 51/20/0 (71); no automatic reset. Verify your own aura source in groups; arena validation remains pending.',
 ['防护 · 战场护卫']='Level-80 battleground survival, control and escort candidate. Core: Stoicism, Guardian\'s Favor, Improved Hammer of Justice, Divine Guardian, Avenger\'s Shield, Shield of the Templar and Hammer of the Righteous. Check your health before damage transfer. Budget 0/54/17 (71). PvE taunt threat is not PvP control; bot roles remain separate.',
 ['惩戒 · 竞技压制']='Level-80 PvP pressure candidate: Pursuit of Justice, Divine Purpose, Repentance, The Art of War, Judgements of the Wise and Divine Storm. Coordinate control and avoid breaking it with periodic damage. Talent 1823 is Divine Steed; 1410 is Righteous Combatant. Talent 1756 is excluded without prerequisite 1409. Budget 0/17/54 (71); conflicts require the original reset process. Arena validation remains pending.',
}
