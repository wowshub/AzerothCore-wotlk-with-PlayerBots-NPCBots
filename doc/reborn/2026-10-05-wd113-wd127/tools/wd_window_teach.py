# -*- coding: utf-8 -*-
from pathlib import Path
import re,shutil
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');C=R/'beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots'
P=Path(Path('D:/000rebornWOW/wd_summary_path.txt').read_text(encoding='utf-8'))
F=R/'000Ascendupdate/000Ascendupdate20261005/codexfix_202610050306_阶段WD127F_投掷泼洒冷却完整同步'
cpp=C/'modules/mod-reborn-witchdoctor/src'
lua=F/'02_覆盖到客户端根目录/Interface/AddOns/RebornWitchDoctorTalents'
def read(p):return p.read_text(encoding='utf-8-sig')
def between(p,start,end):
 s=read(p);i=s.index(start);j=s.index(end,i+len(start));return s[i:j],s[:i].count('\n')+1
def explain(line,context):
 s=line.strip()
 if not s:return '空行：把不同职责分开，运行时不做任何事。'
 if s.startswith(('//','--')):return '注释：记录'+s.lstrip('/- ').replace('|','／')+'；注释本身不执行。'
 if s in ['{','}','};','end']:return '开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。'
 rules=[
 ('SendSpellGo','先发施放完成消息；客户端可能在收到它后用基础DBC启动冷却。后续校正必须排在它后面。'),
 ('GetSpellCooldownDelay','读取服务端已经保存的剩余毫秒，不能再减一次5000，也不重置服务器冷却。'),
 ('SendClearCooldown','只清拥有者客户端的预测计时；不删除服务器保存的冷却。'),
 ('BuildCooldownPacket','构造一个指定SpellID／真实剩余毫秒的原生冷却消息。FLAG_NONE不表示免冷却。'),
 ('SendDirectMessage','把刚构造的消息发给该玩家会话，动作条和原生剩余时间据此更新。'),
 ('exactCooldown','保存“是否需要在GO后校正客户端预测”的布尔值；药水两个完整等级区间和对应被动共同决定。'),
 ('TRIGGERED_IGNORE','排除显式忽略冷却／效果的触发施放，避免给隐藏子技能强加玩家冷却。'),
 ('IsCooldownStartedOnEvent','排除冷却由结束事件启动的特殊法术；它们不能在普通施放完成点处理。'),
 ('IsAffectedBySpellmod','由服务端确认这个modifier是否作用于当前法术；不能把空家族mask当成所有法术通配。'),
 ('GetSpellModifier','取出AuraEffect关联的原生SpellModifier；找不到时返回空指针，后续先判空。'),
 ('GetAuraEffect','读取指定技能、效果槽和需要时指定施法者的光环效果，不凭是否学会代替是否正在生效。'),
 ('SPELLMOD_COOLDOWN','只匹配冷却操作，不能把读条时间或其他效果的modifier拿来修冷却。'),
 ('m_CastItem','排除物品发起的法术，避免把本职业技能修正施加到物品冷却。'),
 ('CalcPowerCost','用本核心实际费用计算入口生成数字，而不是用客户端旧数字乘一个自猜百分比。'),
 ('supportWanted','四个bool逐一对应support中的投手、药师1、药师2、再生者。二级药师不能与一级同时授予；新名字避开旧wanted数组。'),
 ('std::min<int32>','明确比较值都是有符号32位整数；取较小值以保留已经存在的更强修正，不能再次减5秒。'),
 ('std::max<int32>','先把无符号基础毫秒转成int32再减5000，随后与0取较大值，避免负冷却或无符号下溢。'),
 ('std::max(rank','两个同源入口取最高等级；不相加。通用1＋酿造2最终仍为2级。'),
 ('9003854','撤销旧重复的通用强效混合技能／Aura，避免它与正规9003620/21重复生效。'),
 ('tier>=1','从2级往1级检查；先撤高等级，不触发意外低等级保留。'),
 ('rank!=uint32(tier)','当前层级不是方案想要的层级就撤销；类型显式一致方便编译。'),
 ('9003620+2*family','三个家族各占两个私有ID；基址加家族偏移和等级偏移找到实际技能。'),
 ('family==0','只对强效混合家族使用通用入口和永久被动恢复，不把规则扩展到其他家族。'),
 ('RemoveAurasDueToSpell','移除这个技能且由指定GUID施加的Aura；不清空全部玩家增益。'),
 ('removeSpell','撤销该方案不再拥有的技能；本工程参数3覆盖原生两投影组，false不限定只撤临时学习。'),
 ('learnSpell','学会方案正式拥有的技能；HasSpell保护让重复Apply不重复授予。'),
 ('HasSpell','检查角色真实学习状态；草稿选中了节点不是这个检查的替代。'),
 ('HasAura','检查对应光环当前是否存在；被动已学但Aura丢失时才触发恢复。'),
 ('CastCustomSpell','把计算好的护盾amount传给目标触发子法术；不再把它当普通治疗量结算。'),
 ('CastSpell','触发指定子技能／被动；最后true表示触发施放，避免把隐藏效果当一次新的玩家读条。'),
 ('ValidateSpellInfo','启动时检查全部依赖私有法术是否存在；缺子法术不能假装主技能可用。'),
 ('PrepareSpellScript','核心宏给这个脚本声明注册需要的类型信息，不是给角色学习技能。'),
 ('PrepareAuraScript','核心宏声明Aura脚本注册信息；真正生效要有对应World绑定和光环生命周期事件。'),
 ('IsDoctor','限制实际巫医／资格；条件失败立即返回，不能让其他职业借脚本获得功能。'),
 ('GetExplTargetUnit','取得玩家明确选择的友方目标；没有目标、死亡或敌对都会被后续拒绝。'),
 ('IsValidAssistTarget','由核心判断目标能否接受友方施法，不只看名字颜色。'),
 ('SPELL_FAILED_BAD_TARGETS','合法巫医、已学、存活可帮助目标同时满足才成功；否则返回明确的目标错误。'),
 ('SPELL_FAILED_CASTER_AURASTATE','药水投掷／泼洒要求有准备配料，未准备返回状态错误，不消耗后续施放流程。'),
 ('RandomResize','范围名单按目标上限随机截取；这段没有实现“最低血优先”，不能那样描述。'),
 ('_shrooms=','记录本次发射时有无蘑菇；后续命中时读这个快照。'),
 ('_fish=','记录本次发射时有无鱼油，飞行中换配料不能改变这瓶已发出的药水。'),
 ('_bones=','记录本次发射时有无蛙骨。三个bool属于一次SpellScript实例，不是全服务器共享变量。'),
 ('other!=id','只清除上一种不同配料，不移除刚准备的本次配料。'),
 ('IsPrep','判断本次施放是否为三个准备技能之一；目前只允许一种配料，尚未实现Mixologist。'),
 ('Scaling(p->GetLevel','范围蘑菇基础值按角色等级公式缩放，先处理基础，再走原生治疗加成。'),
 ('SetEffectValue','在effect launch阶段设置增补后的基础量，让后续原生治疗倍率、受疗和暴击正常处理。'),
 ('GetEffectValue','读取本次效果在核心已经处理等级／骰子后的基础量，不直接把DBC静态数字当最终治疗。'),
 ('SpellBaseHealingBonusDone','读取自然系治疗加成，非负夹取后乘该技能自己的系数。'),
 ('STAT_SPIRIT','读取精神属性并乘指定比例；不是把精神百分比误当治疗乘区。'),
 ('0.80f','蛙骨护盾使用80%自然治疗加成，float避免先整数截断；再配35%精神和基础值。'),
 ('shield=','最终护盾量取整数且最低1；护盾和治疗不是同一种消费路径。'),
 ('SplashHot:WD120A::Hot','泼洒走12秒HoT，投掷走18秒HoT；两者都为隐藏附效，不能加入可加点节点。'),
 ('FishSplash:WD125A::FishPotion','鱼油在泼洒和投掷使用不同附效，避免拿蘑菇效果误触鱼油。'),
 ('BonesSplash:WD125A::BonesPotion','蛙骨泼洒和投掷各走自己的护盾子ID。'),
 ('OnObjectAreaTargetSelect','在核心生成范围名单时接入截取函数；必须用本核心存在的CASTER_AREA_RAID枚举。'),
 ('OnCheckCast','把Check挂到施法资格检查时点，不等命中后才发现没配料。'),
 ('OnCast','把Snapshot挂到实际施放时点，定义这瓶药水的配料快照。'),
 ('OnEffectLaunchTarget','在对目标启动效果时调整治疗基础量，保证倍率处理顺序。'),
 ('AfterHit','命中完成后附加配料子效果，不把隐藏子法术再次当普通玩家药水递归。'),
 ('AfterEffectApply','父Aura真实应用后调用Apply，不能只注册函数而不挂事件。'),
 ('AfterEffectRemove','父Aura移除时清配套子Aura，到期／取消／死亡时不残留辅助效果。'),
 ('RemoveMovementImpairingAuras','清除施放前已有的定身／减速；不表示持续免疫新控制。'),
 ('AttackStop','停止当前攻击；配合原生禁止攻击／施法Aura，不是把玩家杀死。'),
 ('ModifyHealReceived','只在实际治疗量进入结算时调整恢复；不要先把DBC“2%”取整成整数后丢掉2.2%。'),
 ('uint64(heal)','用64位中间结果计算百分比，再钳到uint32上限；防乘法溢出。'),
 ('a!=b','仅处理自施自受的沃金隐藏治疗，别把任意外部治疗也增强。'),
 ('Duration(Unit','10000毫秒乘(100＋10或20)/100，得到10/11/12秒；冷却不在这里改变。'),
 ('SwiftAmount(Unit','基础25乘增幅后用整数返回，一级27而非27.5，二级30，提示必须跟实际取整一致。'),
 ('0.026729','上游固定二次等级公式：常数项＋一次项×level＋二次项×level²；不能拿描述变量ID猜倍率。'),
 ('0.224494','泼洒直接治疗的自然治疗系数22.4494%，与投掷28%分开。'),
 ('pulse?0.20f:0.28f','范围蘑菇与投掷使用20%／28%不同治疗加成系数，布尔pulse决定哪一种。'),
 ('pulse?0.0f','范围蘑菇没有这段精神加成，投掷有10%；不要给所有治疗都附加精神。'),
 ('60000','贡克减去60000毫秒，即60秒，不是60分钟。'),
 ('PSendSysMessage','按WD114协议发送服务端只读数值；{}个数必须与顶层实参一一对应，Toss遗漏字段就是在这里。'),
 ('rest:match','按完整协议字段解析cost、a、b、revision、active、c、d、e；老格式回退不能假造新字段。'),
 ('pending.epoch','用请求的缓存代数过滤切方案／清缓存之前的回包。'),
 ('n~=pending.seq','序号和SpellID均须匹配当前等待请求，防快速悬停串值。'),
 ('state.pending','保存未确认时不显示草稿效果；已知revision和active还要与回包吻合。'),
 ('font and font:GetText','UI部件可能缺失；先判空再读取FontString文字。'),
 ('record and text==record.rendered','若屏幕仍是上次输出就找回原始文案；若原生控件重建了行则重新以新原文为基线。'),
 ('side=="Left"','旧条件限制左列会漏掉右侧冷却标题；最终药水分支已取消这个限制。'),
 ('clean:gsub','仅替换白名单法术的基础冷却文本，保留射程、HoT持续和其他描述；三种中英格式都处理。'),
 ('value.e/1000','把服务端毫秒换成界面秒；10000显示10，不靠格式四舍五入遮掩数据错误。'),
 ('wd114Lines[key]','记录这条FontString的原文和本次输出；切方案可恢复15，不能反复在10上再减5。'),
 ('wd114Drawing','Show或其他提示钩子会重入；绘制锁避免同步递归。'),
 ('nextSend=now+1','把查询节流到最多每秒一次，不在每帧反复查服务器／数据库。'),
 ('SendChatMessage','发只读数字查询，包含本次序号和准确SpellID；不是保存或施法命令。'),
 ('cache[id]','按SpellID存权威数字并记录revision、active、更新时间；不是按当前鼠标位置随便共享值。'),
 ('self.wd114EffectLine','复用当前效果行，重复刷新不增加无限行数。'),
 ('self.wd114Spell~=id','换到别的技能时清上个技能的原文和效果行身份，防串值。'),
 ('now-value.time>2','缓存两秒过期，装备／光环变化还会主动清缓存；过期数值不继续冒充当前结果。'),
 ('GetNumSpellTabs','只读枚举书页分类，不限制专精也不自动授予技能。'),
 ('GetSpellTabInfo','读取分类名称、原生偏移与槽数，用于解释SkillLine与书页位置。'),
 ('ADDON_ACTION','记录受保护操作事件，提供诊断；没有taint源栈时不能断言DBM是最初污染源。'),
 ('lastBlocked','保存最后一次被阻止操作的信息，打印即可，不调用原生按钮刷新来修它。'),
 ('locate(sid)','从真实列表算分类／页／格，只读输出让用户手动翻页。'),
 ('loadfile','加载真正交付的Lua文件；只模拟游戏API，不把重新抄的一份实现拿来测自己。'),
 ('font(s)','构造有GetText/SetText的最小字体对象，测试界面文字更新。'),
 ('CreateFrame','模拟Frame事件注册与回调保存，允许测试主动调用事件清缓存。'),
 ('GetLocale','测试固定zhCN或enUS，使同一真实代码走两条语言分支。'),
 ('GetTime','测试可控时间，确保节流、过期、超时不依赖真实等待。'),
 ('UnitClass','夹具返回巫医class13，避免测试提前在资格检查处退出。'),
 ('for _,lang','外层两种语言；不能只测中文说明而漏英文标题。'),
 ('for _,first','遍历投掷9003870和泼洒9003890两个七级系列。'),
 ('for rank=0,6','检查七个等级：基址加0到6；只测最高级不能证明低级分支没漏。'),
 ('for _,cooldown','依次10→15→10，模拟激活、切出、再切回被动，检验可恢复而非只减一次。'),
 ('M.invalidate','清权威缓存与待处理请求；随后模拟时间推进，让新查询通过节流。'),
 ('GameTooltipTextRight3','构造／核对真正右侧标题，旧版只改Left在这里会失败。'),
 ('GameTooltipTextLeft4','构造同时包含12秒HoT与15秒CD的说明，验证只改CD不误改HoT。'),
 ('M.receive','注入一个带序号、ID、revision、active和冷却字段的真实格式回包，执行真实解析／绘制。'),
 ('M.refresh','调用真实刷新入口；可用于重复绘制与原生行重建后的回归。'),
 ('NumLines()==5','原始4行加当前值1行，刷新5次也必须仍5行，防重复追加。'),
 ('cooldown syncing','没有e字段时绿色文字必须明确等待，不能默认15冒充权威值。'),
 ('local late=seq','保存旧请求号，换到另一个SpellID再投递旧响应，检验不串值。'),
 ('cases=cases+1','计数2语言×2系列×7等级×3变化＝84，不把额外负向用例混成84个实机测试。'),
 ('assert','断言条件不成立立即终止测试并报告行；本节检查对象是'+context+'，通过只证明这个离线边界。'),
 ('struct.unpack','按WDBC头、字段数与32位格式读取记录，不能把字段位置猜成另一版本。'),
 ('pack_into','只在复制出的数据指定记录第80列写入-5000，不重建整表或跨端互换。'),
 ('path.write','把候选写到归档目录；运行目录和原始MPQ不在这里替换。'),
 ('AEIdCount','声明、定义、循环共享88的一个常量；避免更新数组忘改循环而把已保存新节点误当未知。'),
 ]
 for pattern,note in rules:
  if pattern in s:return note
 if s.startswith('#include'):return '引入本函数使用的类型／工具声明；缺头文件会使Player、SpellInfo或容器方法无法编译。'
 if s.startswith(('#ifndef','#define','#endif','#pragma')):return '头文件保护：避免同一个头在一次编译中被重复定义。'
 if s.startswith('namespace'):return '把本批私有名字放进命名空间，避免别批相同常量名冲突。'
 if s.startswith('class '):return '定义本批脚本类型；基类决定是单次法术、持续Aura还是全局单位事件。'
 if re.match(r'(inline |void |bool |SpellCastResult |local function |function )',s):return '声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。'
 if s.startswith('constexpr'):return '编译期固定私有SpellID，准备技能与隐藏附效不同号；ID只是地址，不是治疗数值。'
 if s.startswith('return'):return '返回当前函数计算出的值或错误码，当前函数在这里结束；外层流程根据返回结果继续或拒绝。'
 if s.startswith('if'):return '条件守卫：条件不满足时阻止本节无资格／不匹配的对象进入后续分支。&&需同时成立，||允许任一成立。'
 if s.startswith('else'):return '进入前一个条件没有命中的备选分支，保留互斥顺序而不是同时执行两种附效。'
 if s.startswith('for'):return '只遍历本节列出的对象／索引，每次更新循环变量；范围不能误含其他职业ID。'
 if s.startswith('break'):return '已找到需要的匹配，结束当前循环，不再处理后续来源。'
 if s.startswith('continue'):return '跳过这一项但继续下一项，防把当前不适用的来源判成匹配。'
 if s.startswith('local '):return '声明Lua局部状态，只在当前作用域使用；本节后续调用读取该变量，不修改全局角色存档。'
 if s.startswith(('Player','Unit','AuraEffect','SpellModifier','uint32','int32','bool','float')):return '以明确类型保存本节输入或中间量；*为对象指针，const禁止通过此变量改值，数字类型决定取整和是否可为负。'
 if s.startswith('print'):return '输出检查／诊断结果，不能把这行文字当作游戏实机通过。'
 if s.startswith('GameTooltip'):return '最小Tooltip夹具的方法／对象，模拟行数、事件钩子或显示状态；没有启动真实客户端。'
 return '本节辅助赋值／调用，按右侧结果更新左侧状态。请结合紧邻代码和本节输入输出阅读；这是实际源码原句，不是建议另写的新实现。'
sections=[]
def unit(title,path,start=None,end=None,intro='',code=None,line=1):
 if code is None:
  if start is None:code=read(path);line=1
  else:code,line=between(path,start,end)
 snapshot=P/'成功代码快照'/path.name
 snapshot.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(path,snapshot)
 language='lua' if path.suffix=='.lua' else 'cpp' if path.suffix in ['.cpp','.h','.inc'] else 'python'
 rows=[f'## {title}\n',intro,f'\n实际来源：[{path.name}]({path.as_posix()}:{line})。归档完整副本：[成功代码快照/{path.name}](成功代码快照/{path.name})。\n',f'```{language}\n{code.rstrip()}\n```\n','逐行读法（编号对应上述代码块；空行和块边界也说明）：\n']
 for i,text in enumerate(code.splitlines(),1):rows.append(f'{i}. {explain(text,title)}')
 sections.append('\n'.join(rows))
unit('1. 灵魂行者：等级、持续、效果要共用一套实际公式',cpp/'RebornWitchDoctorSpiritWalker.h',intro='输入是实际Unit；Bonus只认已学且已有Aura的正式等级，先检查二级再一级。Duration给持续毫秒，SwiftAmount给整数光环效果。冷却不在这两个函数中。对应WD117与WD119B提示修正。')
unit('2. 强效混合：两个入口是最高等级，不是两份收益',cpp/'RebornWitchDoctorAllocation.inc',start='    // WD115A: retire',end='    // WD109',intro='以下AEApply片段负责真实拥有权。移除旧独立9003854，通用与酿造仅最高级9003620/21留下。1级4%／15%，2级8%／30%；保留双入口只为旧方案兼容。')
unit('3. 药师等四被动：数组、等级与Aura恢复',cpp/'RebornWitchDoctorAllocation.inc',start='    // WD124: saved',end='    // WD122: update',intro='support列出四个私有技能，supportWanted按正式mask决定要哪几个。先移除错误等级，后学会并恢复缺失Aura。这解释wanted重名修正与一级／二级不重复的机制；DBC数值疑点仍另列，不因拥有权正确就证明百分比正确。')
unit('4. 酿造公式：基础、治疗系数、精神与等级倍率',cpp/'RebornWitchDoctorBrewingNumbers.h',intro='这些函数是运行时与提示共享的数值入口。IsToss/IsSplash覆盖完整七等级；PulseTargets把绽放人数切为5；SplashBonus用22.4494%自然治疗和8%精神，Toss用28%和10%，Pulse用20%和等级二次曲线。')
unit('5. 大锅／蘑菇／两种药水／鱼油蛙骨：同一次施放闭包',cpp/'RebornWitchDoctorBrewingFoundation.inc',intro='Validate核对依赖；Check核对资格和已准备；PulseTargets裁名单；Snapshot发射时快照并保持单配料；HealBase在原生倍率之前加系数；IngredientEffect命中后附子效果；Register把上述函数挂到对应时点。这一整份78行对应WD120/122/123/125，不能把子效果另列成天赋。')
unit('6. 化蛇：父Aura创建／清理隐藏辅助Aura',cpp/'RebornWitchDoctor.cpp',start='class aura_reborn_wd118_slither',end='class reborn_wd117_heal',intro='Apply在父光环应用时清旧移动控制、停攻击、添加9003860；Remove只撤同施法者辅助Aura。速度、变形、禁止攻击施法由原生效果负责。不能从此推导持续控制免疫或全伤害免疫。')
unit('7. 沃金每秒回血：在实际生命量上增强',cpp/'RebornWitchDoctor.cpp',start='class reborn_wd117_heal',end='namespace WD5A',intro='ModifyHealReceived输入施法者a、目标b、引用heal与SpellInfo；只放行9003856、自施自受。引用意味着直接改核心将结算的量；64位中间乘法避免溢出。')
unit('8. 缩小盟友：原生光环与脚本资格分工',cpp/'RebornWitchDoctor.cpp',start='class spell_reborn_wd126_shrink_ally',end='void AddRebornWitchDoctorScripts()',intro='Check只做巫医、已学、存活友方校验。8秒、闪避、缩放、CD在DBC原生处理，脚本不再重复加一层属性。')
unit('9. 冷却根因：必须在SPELL_GO之后校正',C/'src/server/game/Spells/Spell.cpp',start='    SendSpellGo();\n\n    // WD63E',end='    bool resetAttackTimers',intro='这段是最终F真正解决动作条15秒的代码。按存储→GO→清客户端预测→发真实剩余顺序；只认私有药水被动／已知Hastened和贡克，条件排除物品和特殊触发。不要在Lua全局伪造GetActionCooldown。')
unit('10. 消耗与数值协议：服务端权威值、不是草稿',cpp/'RebornWitchDoctorTalents.cpp',start='    int32 const cost=p->GetCommandStatus',end='    if(id==9003861)',intro='这段接续命令白名单／已学习校验。estimate根据等级和随机上下界确定自身治疗参考，最后走SpellHealingBonusDone。发送cost,a,b,revision,active,c,d,e，Toss末尾原少一个{}，F补全。绿色治疗不含目标受疗、暴击和过量。')
unit('11. 药水提示：左说明和右标题都处理',lua/'NumericTooltip.lua',start='    elseif (id>=9003870',end='    elseif id==9003861 and (clean:match("秒冷却时间',intro='id只匹配两个七级系列。查找15秒／15 sec cooldown／Cooldown基础文案；从服务端e毫秒换秒，缺值显示同步中。self.wd114Lines保留原始文本，所以10→15→10可正确来回。')
unit('12. Lua重入保护与异步响应核对',lua/'NumericTooltip.lua',start='local function refresh',end='for _,event in ipairs',intro='refresh绘制锁处理Show同步重入；receive校验序号、ID、epoch、状态、revision和活动方案，解析八项数字并缓存。旧响应不得写入当前别的技能。')
book=F/'02_覆盖到客户端根目录/Interface/AddOns/RebornWitchDoctorSkillBook/RebornWitchDoctorSkillBook.lua'
unit('13. 技能书只读诊断：不再写原生安全按钮',book,intro='scan只读分类与原生槽；locate只读渲染列表算页格；命令打印已学、槽、分类、页和格。监测ADDON_ACTION事件只存日志。当前诊断名单仍含退役9003854，看到它false并不代表正规9003620/21没学，后续可定向更新诊断名单。')
unit('14. 真实Lua测试逐行：84场景如何组成',F/'checks/potion_numeric_test.lua',intro='完整测试加载交付NumericTooltip，模拟最小Frame/FontString和时间，不复制实现。84＝2语言×2药水系列×7级×3种CD变化。另测缺字段与迟到响应。测试说明行写12秒仅用于验证HoT不误改，不宣称投掷的真实HoT为12；实际投掷仍18秒。')
intro='''# 从零读懂本窗口修复

先学“一个技能由谁负责”，再读代码。节点像课程报名，角色学会Spell像毕业证，Aura像正在佩戴的加成，DBC像基础说明书，C++是实际结算，Lua是窗口，SQL是永久存档。一个文件修好不等于这六层都同步。

## 基础语法与参数

| 写法 | 大白话意义 | 本窗口常见坑 |
|---|---|---|
| uint32 / int32 | 不能负／能负的32位整数 | 冷却基础uint32与修正int32混用导致min/max不能推导；无符号先减可能下溢 |
| float / double / f后缀 | 小数及精度、单精度字面量 | 先取整2.2%会丢小数；系数增15%是乘1.15，不是加15个百分点 |
| *、->、nullptr | 对象地址、访问对象、空地址 | GetTarget/ToPlayer后先判空 |
| & | 引用，同一实际变量 | ModifyHealReceived修改heal会改真实治疗，不只是局部副本 |
| const、constexpr | 不修改／编译期固定 | ID地址和治疗数值不是一回事 |
| &&、||、! | 同时、任一、否定 | 先检查两种药水完整范围，再要求被动Aura |
| ?: | 条件真取前值，否则后值 | 投掷与泼洒不同子效果、不同系数 |
| Lua local、table、ipairs | 局部变量、表、按顺序迭代 | 四limb保存位掩码，不能把100位压成Lua浮点 |
| : 与 . | 冒号隐含self／点号普通调用 | font:SetText更新当前控件，M.receive是模块函数 |
| assert | 条件不满足立刻停 | 断言表达式若字段理解错误，测试通过也是假放心 |

## DBC参数必须按本核心结构表读

以下为从0开始的列，不是人类数的“第1列”。每列4字节，WDBC头20字节。

| 列 | 名称 | 作用 |
|---|---|---|
| 28 | CastingTimeIndex | 引用施法时间表，数值不是毫秒本身 |
| 29／30 | RecoveryTime／CategoryRecoveryTime | 技能／类别基础冷却毫秒，15000=15秒 |
| 31 | InterruptFlags | 读条打断位；移动位1，14 OR 1=15；不能把DurationIndex错当31 |
| 40 | DurationIndex | 引用持续时间表，不是直接秒数 |
| 71—73 | Effect | 三个效果槽类型，例如6为应用光环 |
| 74—76 | EffectDieSides | die0不加1，die1才加1 |
| 80—82 | EffectBasePoints | 基础量，有符号32位编码；-5000是减5000毫秒 |
| 86—88 | EffectImplicitTargetA | 目标选择，不是骰子；旧WD124验证误读此列 |
| 95—97 | EffectApplyAuraName | 光环类型；必须查本核心定义，不能照搬CoA不同枚举 |
| 98—100 | EffectAmplitude | 周期毫秒，3000=每3秒；12秒／3秒通常四跳，仍看生命周期时点 |
| 110—112 | EffectMiscValue | 对应光环的操作类型／参数；107光环misc11为冷却修正 |
| 133 | SpellIconID | 指向SpellIcon中的资源路径，不能直接拿节点图片名当数值 |

时间要分三件：技能冷却10秒，HoT可持续12／18秒，GCD通常1.5秒。三者不同不代表不同步；标题／动作条／服务端可再次施放时间都应描述同一个CD才要求一致。

## 学习顺序

1. 按上表区分ID、效果与单位；用原阶段教程理解每个技能的来源。
2. 读下方1—8：拥有权、公式、快照和生命周期。
3. 读9—13：消息顺序、权威数字、异步与安全UI。
4. 读14与测试说明：知道离线能证明什么、游戏还须测什么。
5. 最后读失败备份，先定位一条完整数据链，再选3—4项依赖完整的新技能，不靠不断试包找原因。

每节引用的是实际交付／提交源码；逐行表讲运行目的。原阶段完整教学与原测试脚本另外保存在逐阶段教学、原阶段研发记录。它们的历史候选结论和旧字段误判不是最终事实。
'''
tail='''
## 15. 三个编译错误怎样从第一条报错追起

**TARGET_UNIT_SRC_AREA_RAID不存在**：查本工程SpellInfo/SharedDefines真实枚举，使用TARGET_UNIT_CASTER_AREA_RAID。两个名字语义接近不代表同核心支持。后面的modules.lib只是模块没有成功生成，先修第一条C++错误，不改链接路径。

**wanted重定义**：一个AEApply函数作用域里已有八项wanted，新四项也叫wanted。改新数组为supportWanted并改两处引用，不把旧数组删掉。数组长度不同只是编译器提示，不是把两组强行改相同长度。

**AEIds 86/88不一致**：定义、extern和遍历统一AEIdCount=88。节点数量88与mask宽100是不同概念：两级节点占两位，旧保留位也占位，不能把“88节点”当成“88位”。C++宽整数、Lua四limb、SQL精确十进制都保留同一位分配。

**min/max**：实际最终表达式为：

```cpp
rec = std::min<int32>(rec, std::max<int32>(0, int32(spellInfo->RecoveryTime) - 5000));
```

从内向外读：把基础unsigned毫秒转signed；减5000；与0取较大值；与已经原生修正的rec取较小值。已有10000保持10000，基础15000兜底10000，已有8000保留8000。不是再从10000减5000，也不靠把界面文字改10解决。

## 16. 保存与高位：为什么旧SQL会报unknown node

Characters存slot/node_id/node_rank，传输mask只是一种紧凑编码。新增ID后旧schema函数不认识记录，会用SIGNAL抛1644；这是拒绝不兼容数据，防新节点被静默丢掉。正确修复是使用当前累计Characters过程并检查实际SHOW CREATE，不是删守卫或删除角色节点。World SQL负责脚本绑定／等级链／系数，不能把它误导入Characters。

测试在临时MySQL33500执行，先核对@@datadir不是生产，再验证重复导入、旧节点保留、预算、互斥、rank上限、未购买槽、拒绝免费撤销。各原测试脚本已原样归档。每一次“返回被拒绝”都必须检查期望是成功还是拒绝，不能只有没报Python错就算SQL通过。

## 17. 图标链与安全面板

节点图标路径、SpellIconID→SpellIcon路径、BLP是否在原生MPQ三个地址要一致。Loosely stored addon BLP能在Lua窗口显示，不代表原生鼠标拾取通道也能读到。WD118B补五个相同资源进MPQ，PickupSpell不改，完全重启。没有专属图标时才需生图，本次用了现存官方资源，没有生成新图片。

已学true不等于当前页已经看见。先查槽、SkillLine、真实渲染列表、分页。WD114C误判缺列表，又D定位写安全按钮，后来119B撤这些写入。弹窗提DBM只是被阻止时涉及的插件，不能没有taint栈就断言它是源头。

WD127C六节点真正缺的是Panel绘图源Data.lua，不是Allocation/Progress逻辑。Data记录同时含id、cap、label和row/col/icon；检查源头再补，不能让用户反复找不存在的灰图标。35065图标改为Spell_Nature_Regeneration_02，与技能书同一SpellIcon2020。位置是旧树空槽，不冒称官方新树布局。

## 18. 测试代码和工具分工

- Python3.9 struct：从WDBC头得记录数／字段数／字节尺寸，验证20+n*size+stringsize等于文件长；每个`s`偏移在池内且能找到NUL。双端各自比较前后，仅目标记录变动，非目标行和原字符串前缀保留。F的比较精确到仅9003897第80列4字节变化；再按真实die0消费公式验证15000-5000=10000。
- MSVC2022 `/Zs /std:c++17 /W4 /WX`：语法检查，不生成EXE。旧混型表达式复现四个C2672，新表达式静态断言；F编译实际后置代码块的独立夹具。夹具模拟Player/Spell接口，所以不能替代整工程的头文件／链接／运行验收。
- Lua5.2解释器：实际执行交付Lua，模拟3.3.5使用的API接口，采用旧客户端可用语法；它不是3.3.5的实际运行器。先测Right标题、Left正文、当前值，再测重绘、切方案、旧回包、缺字段。此前只测左说明是本窗口反例。
- PowerShell／rg：定位文件和真实符号，不运行生产替换。MPQEditor由用户导入，官方JSON与归档只读取来源；没有随意重写旧客户端FrameXML。
- Git：按明确路径暂存相关模块／核心，排除已存在的无关改动；推送用户指定wowshub分支。对ZIP用binary属性防换行转换；`git show`取回blob与原始ZIP SHA相同并CRC通过，才算资源也推送正确。

先执行上述离线测试，失败时修实现或修错误夹具并重新跑对应场景；最后用户游戏内核对两个技能每项显示与实际时间。用户现在确认F通过，是离线加实机的基本闭环；不是所有已归档脚本都在本次重新执行了。

## 19. 新手可以怎样继续

从交接清单挑依赖已有的3—4节点，先对官方说明、上游固定commit、实际本地代码建台账。编号、获得方式、面板、等级链、保存、Aura、效果、数字、图标分别核对。新增技能要看到它能保存、能学习、能看见、能拖动、能正确施放、切方案能撤销，再交累计包。每个批次附来源、回滚、测试边界；失败包进反例，不进成功Skill。

本教程使用类型系统、协议序列化、客户端预测校正、事件生命周期、纯读UI、快照和精确整数编码这些知识。没有读取的书不虚构引用；本核心源码结构和原阶段来源才是这里参数的证据。
'''
(P/'tutor.md').write_text(intro+'\n\n'+'\n\n'.join(sections)+tail,encoding='utf-8')
print('Tutorial sections',len(sections),'bytes',(P/'tutor.md').stat().st_size)
