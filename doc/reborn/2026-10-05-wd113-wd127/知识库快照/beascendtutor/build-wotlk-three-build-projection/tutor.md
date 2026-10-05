# 03 为什么直接ActivateSpec没有动作

以下摘自15施法创建关键行；最后的效果枚举已经按15A纠正。原15脚本中的旧标识符是已知错误。

```cpp
SpellInfo const* info = sSpellMgr->GetSpellInfo(63645);
if (!info || !info->CastTimeEntry || info->CastTimeEntry->CastTime <= 0 ||
    !info->HasEffect(SPELL_EFFECT_TALENT_SPEC_SELECT)) return false;
Spell* spell = new Spell(this, info, TRIGGERED_NONE);
m_monkSpecCast = spell;
m_monkCastTarget = spec;
m_monkCastSource = GetActiveSpec();
m_monkCastHit = false;
SendMonkSpecState();
SpellCastTargets targets;
targets.SetUnitTarget(this);
return spell->prepare(&targets) == SPELL_CAST_OK;
```

| 行 | 代码 | 大白话解释 |
|---|---|---|
| 1 | `SpellInfo const* info = sSpellMgr->GetSpellInfo(63645);` | 按ID找现有切天赋法术资料；本项目63645提供原生读条规则，不是任意客户端都可照抄。 |
| 2 | `if (!info &#124;&#124; !info->CastTimeEntry &#124;&#124; info->CastTimeEntry->CastTime <= 0 &#124;&#124;` | 缺资料、缺施法时间或时间不正数就拒绝。||是任一条件成立。 |
| 3 | `!info->HasEffect(SPELL_EFFECT_TALENT_SPEC_SELECT)) return false;` | 核对真实效果枚举；函数EffectActivateSpec不等于存在同名枚举。 |
| 4 | `Spell* spell = new Spell(this, info, TRIGGERED_NONE);` | 创建正常施法；TRIGGERED_NONE不是瞬发触发施法。 |
| 5 | `m_monkSpecCast = spell;` | 保存这次法术对象身份；对象由原生事件管理，不长期解引用悬空地址。 |
| 6 | `m_monkCastTarget = spec;` | 记录用户真正要切的0/1/2。 |
| 7 | `m_monkCastSource = GetActiveSpec();` | 记住出发时哪套，结束时防止状态已经变化。 |
| 8 | `m_monkCastHit = false;` | 先置未命中，不能一开始就宣布成功。 |
| 9 | `SendMonkSpecState();` | 通知UI当前开始忙，随后仍须处理取消。 |
| 10 | `SpellCastTargets targets;` | 创建目标描述。 |
| 11 | `targets.SetUnitTarget(this);` | 目标为自己，不取当前敌人。 |
| 12 | `return spell->prepare(&targets) == SPELL_CAST_OK;` | 交给原生prepare；返回是否受理，不等于已经施法完成。 |


完整入口还先拒绝战斗、死亡、载具、飞行、重复施法、动作条加载中等状态。MarkMonkSpecCastHit只接受同一对象且施法者为this；不会让其他原生法术消耗这次目标。
FinishMonkSpecCast检查ok、命中、对象身份、源方案未变、目标合法和角色状态，再清除锁，SaveToDB、设置动作条加载后保存标志、ActivateSpec。失败只清锁并保留原天赋。清锁顺序很重要，否则激活过程可能把自己的施法当成冲突再次打断。
READY=是否可操作，CAST=是否施法中，不能把READY0全解释成读条。数据库正在回包也可READY0。
测试：5秒完成一次；读条时移动/取消不切；连点不重复；死亡、进战斗拒绝；空动作条允许；换角色后旧回包丢弃；重登三套点数各自保留。
编译错误排查：SharedDefines.h效果162→SpellEffects.cpp第162处理项→调用处。先修未声明标识符，再重编game；不要从别处复制game.lib硬凑链接。


## 2026-09-17 WD16 巫医绑定方案（用户基本测试通过）
来源：000Ascendupdate/000Ascendupdate20260916/codexfix_202609162250_阶段WD16_方案绑定与付费完整洗点。用户原话：“测试可以了 现在继续下一步开发”。这是整体基本流程反馈，不等于逐项确认断线、故障恢复或全部收费边界。
巫医为独立存档方案，不改MAX_TALENT_SPECS。每套初选一个专精；其他页只浏览；已保存点禁止免费退点；10金币固定全洗（config可改）清本套点数和专精；其他方案保留；切已解锁完整方案免费恢复动作条。第二套1000金一次性，第三套config。不能恢复WD14混点或WD15一套内三个免费专精快照。
记录必须区分：用户基本通过、51项离线检查、未逐项实机验证边界。未来装备仓库未包含在此验收。


## 2026-09-27 WD78B三个巫医天赋基本实测通过

用户明确“三个巫医天赋 可以了通过 继续下一批的移植吧”，登记荆棘谷风格、扎拉赞恩的恶意、妖火基本使用通过。不扩展为所有等级/数值、PvP和所有方案矩阵，也不把Voodoo Spirits704511未移植的妖火联动记为通过。

来源：[WD78B](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260926/codexfix_202609262111_阶段WD78B_巫毒三节点双池整合/README_覆盖与测试说明.md)，[教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260926/codexfix_202609262111_阶段WD78B_巫毒三节点双池整合/tutor.md)。复用：已有战斗实现接正式双池时同时扩C++/Lua/SQL白名单与mask；保留旧位、旧账本，不允许现代导师路径恢复已撤销技能；两个点数池不可互借。现代激活存档决定技能所有权，草稿不能授予。WD79A新候选不继承验收。

永久方法：beascendskills/trace-and-port-coa-spell-resources/SKILL.md与build-wotlk-three-build-projection/SKILL.md；对应同名Tutor。


## 2026-09-27 WD79B 黑暗魔法技能提示基本实测通过

用户明确“好棒啊 搞定了”，承接WD79B，确认黑暗魔法实际生效后技能书/动作条施法时间提示修正基本通过；不扩大为全部方案、等级、急速与其他技能完整矩阵。来源：[WD79B](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260927/codexfix_202609270144_阶段WD79B_黑暗魔法施法提示双池同步/README_覆盖与测试说明.md)，ZIP SHA256 ca3346832515aba7029fdf5c97ed665ccac5558ba8169a3a67b0dcea6ecdde8e。历史包保持不变。
复用：现代方案读aeMasks[active+1]并显式传AERank，不能用默认读取草稿的参数或旧builds；unknown/pending显示待同步。两套UI展示与服务器战斗效果分开排错。


## 2026-09-29 WD89A 反例更正：空掩码不是排除（代码已证实，修正包待实机）

本地SpellInfo::IsAffected在familyName=0时直接true；非0同家族的空mask也不排除。GlobalScript::OnIsAffectedBySpellModCheck返回false是强制匹配，返回true只是继续原生判断。此前“空DBC mask能保护无关技能”的解释不成立，不再作为可复用保证。

实际当心巫毒9003752/53和扎拉赞恩9003611均family0/空mask，可误延长暗影傀儡。用户反馈单次施放超过5秒仍发射，数据基础3秒/冷却18秒未互换。WD89A提供私有精确来源回退拒绝和实际时间诊断；候选未编译、未实机。既有用户基本验收保留，不能扩大为全负向范围验收。

[源码证据与适配](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609291613_阶段WD89A_天赋范围修正与拟态计时/research/来源与适配.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609291613_阶段WD89A_天赋范围修正与拟态计时/tutor.md)。后续测试必须同时包含合法目标有加成、无关目标无加成、其他职业原生效果不变。别只测“看到增加了”就认定边界正确。


## 2026-09-29 WD87–WD91前批技能用户基本实机确认

用户概括确认“前面的技能都测试 通过”。WD87三节点、WD88三节点与WD91黑暗雕像登记基本实机通过，采用WD89范围修正后的累计版本；未提供完整数值/多人/PvP/机器人/方案矩阵。WD93仍候选；WD90/92 UI不扩大验收。

[验收依据](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609291627_阶段WD91A_黑暗雕像三目标联动/验收补充_20260929_用户确认前批技能.md)。

[复用教学](WD87-WD91-acceptance.md)。


## 2026-09-30 WD100A 通用神像三节点（候选）

新增Class灵魂守卫7033、迅捷神像6051、黑暗魔精6048，3 AE；55位方案用Lua双32位精确保留旧点。复用既有战斗效果，新增拥有权/等级/前置/清理。Lua回归、141隔离SQL、113数据源码通过；一次早期旧断言失败未复现留档，未编译部署实机。[覆盖与测试](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300016_阶段WD100A_通用神像三节点/README_覆盖与测试说明.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300016_阶段WD100A_通用神像三节点/tutor.md) · [来源](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300016_阶段WD100A_通用神像三节点/来源与适配说明.md)。
仅登记候选工具与验证边界，不标记实机成功。


## 2026-09-30 迅捷召唤实际冷却基本验收与文字候选修正

用户原话“虽然现在缩短时间是正确的”，确认迅捷召唤的实际冷却缩短基本通过。截图灵魂神像基础3分钟；180×75%=135秒即2分15秒，属于冷却不是存活时长。未扩大为其他Class技能、所有召唤、PvP/机器人矩阵通过。

文字修正随WD100A新增独立RebornWDCooldownTooltip插件，5提示入口与切方案、中英文离线Lua回归通过，画面仍待验证。可先仅复制新插件目录并完全重启客户端，无需编译、SQL、MPQ。

[覆盖与测试](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300016_阶段WD100A_通用神像三节点/README_覆盖与测试说明.md)


## 2026-09-30 巫毒分支与WD101用户基本验收

用户确认巫毒基本测试及此前三问题已解决。四节点保存、五分身显示、魔像绿色修正登记基本通过；不扩大PvP/机器人/数值全矩阵，WD102独立技能框未单独验收。[WD101验收](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300307_阶段WD101A_保存与召唤外观修正/验收补充_20260930_用户确认.md)。


## 2026-09-30 WD104A 酿造三被动正式方案（候选待测）

强效调配、魔精依赖、酿造大师：每项两阶1TE/阶，酿造绑定、最高阶拥有权、61位保存、旧导师补发阻断。184隔离SQL、累计Lua新增27组合、63数据源码检查通过；未编译部署实机。保留原巫毒及WD101/103，不宣布整酿造/普通技能完成。下一批需先处理仅剩3位的编码容量。

[覆盖与测试](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300653_阶段WD104A_酿造三被动正式方案/README_覆盖与测试说明.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300653_阶段WD104A_酿造三被动正式方案/tutor.md) · [交接](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300653_阶段WD104A_酿造三被动正式方案/phaseFixForNewChat.md)。
本段仅记录候选方法与证据，不晋升已验证Skill。


## 2026-09-30 WD105A 酿造治疗续航三节点（候选待测）

9311灵魂医者、5055洛阿之临、4715洛阿祝福正式方案：20级免费/1TE/30级免费，最高bit63、旧52节点兼容、现代导师补发阻断。Lua累计+8组合、40源码/数据、两轮各236隔离SQL通过；首次快照异常保留在memory，未编译/实机。8覆盖文件加CharactersSQL。下一批增加节点必须先扩展64位容量。

[覆盖与测试](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300717_阶段WD105A_酿造治疗续航三节点/README_覆盖与测试说明.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300717_阶段WD105A_酿造治疗续航三节点/tutor.md) · [交接](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300717_阶段WD105A_酿造治疗续航三节点/phaseFixForNewChat.md)。本条仅候选，不晋升已验证。


## 2026-09-30 WD106A 空方案读取回归（已定位，修复待实测）

用户反馈WD104A全部方案锁定。真实Jorn48旧节点及第二套1000金购买/酿造绑定仍在；AESpecValid错误拒绝spec3+mask0使全槽Load失败，WD105继承。独立双版本最小修正版允许空未绑定槽，保存仍禁未绑定；无生产DB写入。此前SQL/Lua回归未覆盖真实C++Load，不能视为加载验收。暂停WD104/105推广，用户编译重启后确认。[修复说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300744_阶段WD106A_空方案读取回归修复/README_覆盖与测试说明.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300744_阶段WD106A_空方案读取回归修复/tutor.md)。


## 2026-09-30 WD107A 酿造大师提示同步（显示候选）

用户确认酿造大师2阶实际施法2.5秒；仅登记这项机制反馈。客户端提示补10rank白名单、已保存激活29736读取、高位mask兼容、双语2位小数。76离线显示断言通过，无编译/SQL/DBC改动，画面待测。[说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300816_阶段WD107A_酿造大师施法提示同步/README_覆盖与测试说明.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300816_阶段WD107A_酿造大师施法提示同步/tutor.md)。不扩大WD104整包或WD106验收。


## 2026-09-30 WD108A 默认激活方案与列表置顶（候选）

用户明确当前部署基线：WD105A全部源码＋WD106A的WD105A修复文件，已编译；WD105 CharactersSQL、客户端Lua、双端Spell已更新，保留WD107。后续开发必须在此累计层继续，不退回WD104。此次只改实际客户端Profiles.lua，首次成功回包默认active，后续保留手动浏览/草稿；列表改锚点不改slot。离线Lua初始/失败/重复同步、三槽排序及点击目标通过，画面待测。[说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300841_阶段WD108A_激活方案默认显示与置顶/README_覆盖与测试说明.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300841_阶段WD108A_激活方案默认显示与置顶/tutor.md)。

补记用户明确WD104三个技能测试通过：强效调配、魔精依赖、酿造大师基本效果；不扩大WD105三技能验收。

## 2026-09-30 WD104—WD108 用户基本实测通过及收工交接

用户原话：“前面的技能和修复都测试通过 明天继续吧晚安啦”。据本轮上下文登记：WD104强效调配、魔精依赖、酿造大师；WD105灵魂医者、洛阿之临、洛阿祝福；WD106空方案读取修复；WD107施法提示；WD108重登默认激活方案与列表置顶，基本使用通过。不扩大为全等级、多人/PvP、全部故障恢复与数值矩阵已验收。

当前已部署并测试的累计基线：WD105A全部源码＋WD106A包内WD105A对应修复；WD105 Characters SQL、客户端Lua、独立双端Spell；保留WD107提示、WD108 Profiles。下一轮必须保留上述累计修改，禁止以原WD104或未修WD105覆盖回退。历史包和ZIP保持不变，以本验收补充覆盖“候选待测”的历史状态；WD104/105原始读取缺陷仍保留为反例。

已验证方法（限定本批基本使用）：读取允许spec3且mask0的空未绑定槽，保存仍禁止未绑定；首次成功同步按active选择浏览槽，后续保留主动浏览和草稿；列表只改显示位置，slot身份不变；技能提示按激活且已保存方案计算，不读草稿，高位mask不转浮点。教学见对应包tutor.md，技能方法归入build-wotlk-three-build-projection。

明天接续：先核对实际文件与上述累计基线，处理现有64位投影容量已满的扩展，保留旧节点表/方案/动作条兼容，再按依赖选3—4项酿造及相关通用技能。分类成功不等于普通技能全部完成，依赖台账仍需逐项推进。今晚停止开发；未安排自动任务。


## 2026-10-01 WD109A 酿造扩容与联动三节点（候选待测）

当前WD105/106累计源码之上追加7129充足药剂、7948灵魂之触、31137丛林秘法；保留WD107/108。旧55节点顺序/存储行不变，扩容C++128位、Lua四limb、SQL decimal，当前开放67位。新品减耗仅佳酿/破咒；两高级节点需8基础酿造TE。Jungle按最新20260925官方Radius9从旧80码修正20码，双端说明同步。270隔离SQL、87数据/源码/旧UI、1984精确数值断言与累计Lua通过；未编译、未实机。正式DB只读连接失败，未生产写入。此条仅候选，不晋升已验证。

[覆盖与测试](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261001/codexfix_202610010819_阶段WD109A_酿造扩容与联动三节点/README_覆盖与测试说明.md) · [教程](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261001/codexfix_202610010819_阶段WD109A_酿造扩容与联动三节点/tutor.md) · [交接](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261001/codexfix_202610010819_阶段WD109A_酿造扩容与联动三节点/phaseFixForNewChat.md)。


## 2026-10-01 WD110–112 三轮累计（候选待测）

承接WD109，接入穆厄扎拉之触、天选之人双拟态守卫、怒气/奥术佳酿互斥选择，共4新节点。诅咒雕像24AE前置无法满足，保持旧拥有方式、不开放新节点；bit67保留禁用。保留WD106空槽、WD107提示、WD108方案显示。最新社区commit ad8df63b9003a003946831ef025677ceb6f6288e；295隔离SQL、59静态/数据/UI、1984整数断言及累计Lua通过；未编译、未实机，未生产写入。所有新技能与WD109仍待用户验收，非已验证案例。

[累计覆盖与测试](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261001/codexfix_20261001_阶段WD112A_三轮累计通用与酿造/README_覆盖与测试说明.md) · [逐步教程](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261001/codexfix_20261001_阶段WD112A_三轮累计通用与酿造/tutor.md) · [交接](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261001/codexfix_20261001_阶段WD112A_三轮累计通用与酿造/phaseFixForNewChat.md)。


## 2026-10-02 WD109A 与 WD110—WD112 用户实测通过

用户明确反馈 WD109A 测试通过，WD112A 累计包的三轮也已通过：WD110 穆厄扎拉之触接入方案保存；WD111 天选之人双拟态守卫；WD112 怒气佳酿、奥术佳酿互斥选择。WD109A 包括充足药剂、灵魂之触、丛林秘法及高位方案扩容。登记本批基本使用通过，不扩展为全等级、PvP、多人归属、断线故障恢复完整矩阵。

后续以 WD112A 累计交付为技能开发基线，保留 WD106 空槽读取、WD107 提示、WD108 激活方案显示，保留旧节点位置与存储行。诅咒雕像 5113 未在本批新开放，bit67 保留禁用；DRBOT1A 龙希尔机器人变形用户正在测试，不能继承这次验收。

已验证方法的基本使用：跨 64 位保存需 C++ 128 位、Lua 四 limb、SQL DECIMAL 同步，不能把完整掩码转 Lua 浮点；新增技能所有权由已保存且激活方案决定。双守卫用两个 GUID 分别检查目标和清理，不能修改全部图腾的通用数量；互斥节点在客户端、C++、SQL 三层一致约束。详细边界沿用原包说明。

[WD109A 教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261001/codexfix_202610010819_阶段WD109A_酿造扩容与联动三节点/tutor.md) · [WD112A 教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261001/codexfix_20261001_阶段WD112A_三轮累计通用与酿造/tutor.md)


## WD114A 排错记录：原生modifier与提示同步是两条链（2026-10-02）
代码已核实：Player::AddSpellMod只按非零mask位发送客户端更新；服务器精确ID钩子可在空mask下匹配成功。这意味着“服务端可能生效”不证明客户端费用显示正确。用户截图未证明实际扣蓝失败，不能据此杜撰运行时根因。WD114A用只读服务器CalcPowerCost/固定效果值同步提示，拒绝旧revision/active/序号回包，并补激活被动恢复；该修正仍为候选，未实机验收。
[阶段教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610020855_阶段WD114A_巫祝数值同步与通用双技能/tutor.md)。下次出现同类问题，先分开核对已保存激活拥有权、Aura、计算入口、实际扣除、提示更新，避免只对显示数字硬乘百分比。


## 2026-10-02 WD114B 数值提示与洛阿强化用户确认通过；其他问题继续核对

用户明确“这个数值显示 测试通过”，随后明确“洛阿强化……这个测试通过”。登记WD114B费用提示刷新/旧数值修正及洛阿强化本次基本使用通过；不扩展为全等级、所有方案故障恢复或全部减耗机制验收。

仍待核对：用户称假死药剂点选后技能书找不到、显性诅咒无技能书图标、强效混合4%/15%与技能书8%/30%不一致。只读核对WD114A：31118 -> 9003853，11323 -> 9003852，12264 -> 9003854；三者SkillLineAbility均为9004巫毒分类。截图技能书选中酿造分类。酿造7131 -> 9003620/9003621，2级8%/30%；通用12264 -> 9003854，1级4%/15%。两节点当前独立拥有，不能把两编号误认成同一记录，也不能未核对上游重叠语义便宣称叠加合理。Allocation.lua酿造7131仍残留“通用树同名节点未开放”旧说明，已记录待统一。

显性诅咒支持的9003150、9003200、9003210、9003220—25、9003762已经同时列入服务端SpellNumbers和NumericTooltip费用同步白名单；不是需要再把其被动技能自身费用减25%。未确认这些技能实机费用。假死/显性技能是否已授予，需要查看巫毒书页或IsSpellKnown结果；没有据此修改生产存档或伪造已修复结论。

本次实际读取永久Skill：trace-and-port-coa-spell-resources/SKILL.md、build-wotlk-three-build-projection/SKILL.md。只读核对现有交付，不新增机制移植；WD114A既有上游证据保留，未声称重新核对最新上游。

来源：000Ascendupdate/000Ascendupdate20261002/codexfix_202610021638_阶段WD114B_巫祝提示重绘优化/README_覆盖与测试说明.md。WD113/114其他节点、DRBOT1A仍不能登记全部通过。


## 2026-10-02 WD115A 假死通过、图标和强效混合同源整合候选
用户明确假死药剂可以了通过；假死/显性图标已在最新截图显示，旧漏项假说不再作为根因。仅假死基本机制验收，不扩展显性25%费用和全部方案边界。
本批复用trace-and-port-coa-spell-resources及build-wotlk-three-build-projection。假死官方节点图标7e06e90aea7e069e现有可复用，Spell误用了巫祝图标，独立SpellIcon修正。强效通用12264和酿造7131引用同源503748/504888，保留方案位和投资，最高等级合并至9003620/21，撤销旧重复9003854，不叠加。中文名和图标统一，双入口提示重复投资无额外收益；不自动退款或改旧方案。
上游HEAD d7620151fa4267ab90c7e0554b32628017df241a，Issue1290/2190、最新场景和相关PR搜索已存档。Data/Content进阶JSON没有这些法术且同号ID跨版本复用，不能当当前服务器开放配置；双入口保留是本项目兼容策略。上游固定威胁与说明百分比差异未照搬。
双端限定记录/所有字符串偏移、Lua语法、72组状态模型通过；未编译、未部署、未实机；模型不是运行证据。WD114B数值提示保留，只有增量inc/Lua/DBC/图标，无SQL。方案/点数/购买记录均不改。技能总完成度不提升。
[WD115A说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022030_阶段WD115A_假死图标与强效混合来源审计/README_覆盖与测试说明.md) · [教程](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022030_阶段WD115A_假死图标与强效混合来源审计/tutor.md)。ZIP SHA256 `be987886df6c41099cbd345d3b0edba5a4ed062eb2524440908a971115003d27`。


## 2026-10-02 WD116A 沃金守望通用防御技能（候选）
新增节点6042->9003855，隐藏治疗9003856；先9基础AE后1AE，跨专精，bit77精确存储。原生25%减伤、1秒一次2%最大生命治疗、10秒持续、120秒冷却；受原生治疗修正。官方图标与天赋一致，视觉兼容复用原生树皮术，未宣称CoA独有特效。
累计WD114与WD115整合，保留数值提示、原方案和购买资格。WD115仍未用户实测。使用plan-coa-class-migration、trace-and-port-coa-spell-resources、build-wotlk-three-build-projection。来源commit d7620151fa4267ab90c7e0554b32628017df241a，官方504465/681004/503598，上游周期修正已查。灵魂行者未开放。
342隔离SQL、累计Lua、20数据检查及全部Lua语法通过；未编译未部署未实机。初次测试因缺schema夹具中止，补齐后通过；旧bit77越界测试更新为78。不能将候选登记成功。需要Characters WD116A SQL，旧版本unknown-node守卫禁止带新节点回退。
[覆盖说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022006_阶段WD116A_沃金守望通用防御技能/README_覆盖与测试说明.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022006_阶段WD116A_沃金守望通用防御技能/tutor.md)；ZIP SHA256 `7bb6b2411a0c0a556191b86ac40fa623d64993cee897b5098b40121a270f4b49`。


## 2026-10-02 WD117A 灵魂行者双技能联动（候选，未编译未实机）
在WD116累计基础新增9347双级9003857/58，10%/20%增强沃金及迅捷持续和效果，精确80位保存。一级整数光环27%、二级30%；恢复在实际治疗量上乘10%/20%，不提前截断2.2%。等级变化清旧增强效果不重置冷却。复用节点官方图标；服务端提示支持持续、减伤、基础逐秒恢复和迅捷增幅。
上游commit d7620151fa4267ab90c7e0554b32628017df241a，Completion将SpiritWalkerOne第二效果修正9（10%）。354隔离SQL、累计Lua、25数据/源码及全部Lua语法、数值提示回归通过。WD115/116/117均仍候选，先验收再推进其他依赖。
使用plan-coa-class-migration、trace-and-port-coa-spell-resources、build-wotlk-three-build-projection。覆盖说明：[codexfix_202610022033_阶段WD117A_灵魂行者双技能联动](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022033_阶段WD117A_灵魂行者双技能联动/README_覆盖与测试说明.md)；教学：[codexfix_202610022033_阶段WD117A_灵魂行者双技能联动/tutor.md](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022033_阶段WD117A_灵魂行者双技能联动/tutor.md)。ZIP SHA256 `ba2e743f813316cceb0daaf1c3f5abf5a7a2daaee52449b222ac90e155f17bc6`。


## 2026-10-02 WD118A 化蛇通用生存技能（候选）
基于WD117累计，节点29306->9003859、隐藏9003860，30级9基础AE后1AE、bit80。5秒化蛇、80%移速、已有定身/减速解除、60秒冷却；保留禁止攻击施法且可取消。配套原始远程/法术命中修正-100个百分点、80%游泳；非全伤害免疫。现有蛇模板2914及四模型客户端存在，节点图标一致，未移植CoA专属粒子链。
最新上游d7620151fa4267ab90c7e0554b32628017df241a，PR6192已合并；独立父/子生命周期与方案撤销。Characters WD118及World绑定SQL必须成套，旧节点和购买状态不清。367隔离SQL、累计Lua、30数据/源码及提示检查通过，未编译未实机；WD115–118仍待验收。
使用plan-coa-class-migration、trace-and-port-coa-spell-resources、build-wotlk-three-build-projection。首次全量旧level20用例失败，定向成功；新增等级分支补ROLLBACK后全量完成，证据见checks。完整说明与教学：[README](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022101_阶段WD118A_化蛇通用生存技能/README_覆盖与测试说明.md)、[tutor](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022101_阶段WD118A_化蛇通用生存技能/tutor.md)。ZIP SHA256 `302b7254571ee0b44ba30d95b9cc4a3c64fb5e410843e73c5e11560c8445550f`。


## 2026-10-02 拖动图标与沃金守望用户基本验收
用户原话：“这个图标拖动的时候可以看到了 沃金守望：测试通过”。确认WD118B补齐MPQ资源后，本次假死药剂拖动光标显示恢复；沃金守望基本使用通过。不扩大为全部五图标逐一确认、灵魂行者增强、化蛇、PvP或多人完整矩阵通过。
来源：[图标修复](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022208_阶段WD118B_原生拖动图标资源补齐/README_安装与测试.md)、[沃金守望](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022006_阶段WD116A_沃金守望通用防御技能/README_覆盖与测试说明.md)。原ZIP不改写。
复用：原生SpellIcon引用的新BLP同时交付插件目录与MPQ内部准确路径；书页可见不代表原生鼠标加载可见，分别测书页、拖动光标、落入动作条。沃金守望以独立主动/隐藏周期治疗分工，激活方案授予和撤销，不能因图标出现推定保存或机制通过。本条以用户明确的基本测试结论覆盖原候选状态，其他未测项保留。


## 2026-10-02 WD119A 蛙变术与双祝福（候选待测）
承接WD118A累计，合并用户已确认拖动可见的WD118B。新增Class6031蛙变术9003861、6525贡克祝福9003862、12525克拉格瓦祝福9003863，26级/9基础AE/每项1AE；两祝福互斥且要求父技能。40秒普通目标、玩家8秒后原生递减、伤害解除、临时野兽类型，1秒120秒/1.5秒60秒/瞬发120秒三种基础状态；服务端数值提示同步。保留旧方案和购买，bits81–83追加，84位三端一致。
最新社区commit d7620151fa4267ab90c7e0554b32628017df241a、已合并PR4753及934/1179/3693和当前场景已核对；官方20260925Spell500952/806469/807855单独记录。原模板216377本地缺失，复用原生Hex蛙13321；未导入CoA独有粒子。当前Patch-XA被锁错误32，登记解包引用存在不等同实际MPQ/渲染验收。
388隔离SQL、53数据/静态、累计Lua/语法/提示模拟通过；未编译未部署未实机。首次SQL旧回退断言失败为新增测试before变量含购买表导致口径不一致，修正夹具后全量通过。用户本轮沃金守望基本通过已另行登记，灵魂行者/化蛇和本批不继承。
使用plan-coa-class-migration、trace-and-port-coa-spell-resources、build-wotlk-three-build-projection。交付需Characters WD119；未装WD118需World118绑定。详情：[覆盖说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022255_阶段WD119A_通用控制三技能/README_覆盖与测试说明.md)、[教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022255_阶段WD119A_通用控制三技能/tutor.md)、[来源](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022255_阶段WD119A_通用控制三技能/来源与适配说明.md)。ZIP SHA256 `51c3063a16dcd0f24ca3c5d8a2e9c093f11b98ce84dbfbcf2b8b12690c386733`。


## 2026-10-03 前批基本验收与WD119A状态澄清
用户先说“前面测试都已经都通过，继续下一批”，随即明确“我来测试 WD119A”。因此前批WD117灵魂行者、WD118化蛇及WD119B面板/提示按用户总体反馈登记基本测试通过；WD119A蛙变术、贡克祝福、克拉格瓦祝福保留待测，不将总体反馈扩大到随后明确正在测试的包，也不扩大成全PvP/多人/全部数值专项通过。既有WD118B拖动与沃金守望验收保留。
下一批来源审计目录：000Ascendupdate/000Ascendupdate20261003/codexfix_202610030147_阶段WD120A_酿造下一批依赖开发。该目录仅研发证据，无可安装新包；未改运行源码、客户端或生产数据库。


## 202610030327 WD120A 酿造基础三节点（候选待编译/实测）
已完成4005大锅酿造、12645丛林蘑菇、12646药水投掷的有界接入：免费酿造节点、配料6秒范围治疗、投掷7级+18秒HoT。保存扩87位，旧位与购买账本保留；World手动系数避免重复加成；节点/技能书/拖动图标一致。当前治疗参考范围读取服务端，不依赖草稿。基线WD119A累计+已验收WD119B+候选WD119C；WD119C和本批尚未实机通过。
上游在线固定d7620151fa4267ab90c7e0554b32628017df241a；字段232是描述变量ID，实际802703等级缩放来自ScalingBase实现。不能将早期字段误判继续复用。仅蘑菇一种配料，其他配料和泼洒仍未开放；外观复用既有洛阿佳酿887925，36项引用资源已只读找到，不宣称大锅模型或专属药瓶弹道完成。
403项临时MySQL与累计Lua/DBC检查通过；C++没有编译，没有修改运行目录或生产数据库。一次历史GM测试断言未复现，原路径未声称修复，详见memory。
[覆盖说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610030147_阶段WD120A_酿造下一批依赖开发/README_覆盖与测试说明.md)；[逐步教程](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610030147_阶段WD120A_酿造下一批依赖开发/tutor.md)；[交接](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610030147_阶段WD120A_酿造下一批依赖开发/handoff.md)。ZIP SHA256 `02ee4367bc97f2f9df779b800886cc20a5759539b88a3b62c26ab8e134fea71c`。旧ZIP不改写。


## 202610030403 WD121A 酿造治疗双天赋（候选，未编译/未实机）
基于WD120累计，新增6498新鲜配料两级9003877/78（大锅蘑菇15%/30%）和29303药水增效9003879（投掷及蘑菇HoT20%）。90位保存、79项映射，基础8酿造TE后每级1TE，同层不计前置；保留旧方案及购买。节点/书页/拖动图标一致，权威治疗提示走同一原生done healing路径。WD119C及WD120仍候选，不把继续开发请求当验收。
本批在线HEAD ccaf63902e3d244953d0bed991aae79fdc32055c；Issue1142关闭但PR4753仍needs-decision。官方20260925本地Fresh op0与社区场景op22/目标冲突，按大锅描述精确限定；PotionBoss由op8适配末端op0/op22使手动系数一并增强，差异明示，不声称官方服务器完全一致。
414隔离MySQL、累计Lua/旧UI、双端旧行/字符串、720数值负向模型通过。首次历史war等级拒绝断言失败未捕获原值，后续完整追踪复测及20次重复拒绝通过，未根因、不称修复。未生产写入、未编译、未实机；尚不晋升已验证Skill。
[覆盖测试](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610030339_阶段WD121A_酿造治疗双天赋/README_覆盖与测试说明.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610030339_阶段WD121A_酿造治疗双天赋/tutor.md) · [来源](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610030339_阶段WD121A_酿造治疗双天赋/来源与适配说明.md) · [交接](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610030339_阶段WD121A_酿造治疗双天赋/handoff.md)。ZIP SHA256 `61a121430c0696d33f4991142ad71cb7e4107e2cbeb1588c8615ad159d47b220`。


## 2026-10-05 WD113—WD127

[本窗口对应教学](WD113-WD127.md)：实际代码、每行作用、参数与测试，成功／失败边界分别记录。
