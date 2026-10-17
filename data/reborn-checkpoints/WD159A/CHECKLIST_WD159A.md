# WD159A完整移植审查表

作者/审查者：Codex，同一作者逐调用链自审，没有独立成员评审。独立目录D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261016\codexwork_WD159A；范围登记见项目协作说明WD159A三条事件。实际输入/输出SHA见checks/input-output.json及cumulative-source-inputs.json；整个包文件hash见SHA256SUMS。

读取Skill：audit-and-port-upstream-features、coordinate-ai-team-parallel-development、plan-coa-class-migration、trace-and-port-coa-spell-resources及项目AGENTS/rule/refResource/协作规范。适用范围：节点规划、上游来源、技能联动、独立资源和候选交付；不继承其他职业验收。

最新社区仓库jealous-sound/azerothcore-wotlk-coa/main，2026-10-16在线固定SHA f6e30667591521c9f4f199a294b7cc4b15573c71。七份实际代码及哈希、开放/关闭检索结果见upstream/sources.json；PR7164/7167/6409/5935/4253均已合并，具体差异/评论见details.json。7393双发争议仍开放；4091/5762/6972/6973/1517已关闭不等于本地已实机。没有把社区仓库称为官方服务器源码。

官方行为独立依据：20260930官方客户端MPQ及147阶段只读Spell/Visual表缓存；donor-contracts.json含503712/504582/505158/707650/705948/707326/712372字段。赠礼15%、每魂2%；代价8秒和15000毫秒，齐射30%/6秒/3000毫秒/28.5%RAP均逐字段核对。FreeVolley保持0TE。旧504583是历史赠礼脚本，不能误当当前707650天赋。旧707326描述写箭但当前AuraTip和最新实现针对战刃，本地文字明确战刃。

## 获取及保存契约

三项均只当前已保存激活暗影方案；免费齐射50级+4423，赠礼/代价1TE、23此前TE且满足连接；现有可用前置分别6035或29981、6035。自然点数路径两付费最早59，天赋基础门槛20。未来Viper/Fools路线未伪造开放。全1级，无新互斥；已有两选择组保留。160槽176bits44hex，旧槽/购买/其他方案不变，hash 1f8a95351ffadec92073df87bc86cadf91f8946c0d03eb1d0bb97488b1ff75e7。

|联动来源|条件/GUID|受益|公式/单位|撤销|实现入口|展示|证据/状态|
|---|---|---|---|---|---|---|---|
|箭/回收|自己普通成功施法，非触发|齐射Ready|每次30%，6秒，刷新generation|成功齐射/到期/死/切图/退出/洗点|WD159::generator/Proc/ready|4173真实Buff，最高回收替换|实际摘取/SQL绑定/Lua；游戏待测|
|齐射|受理施法时有Ready或自己赠礼拟态|自己Spirit/战刃|成功1层，上限5；剩余减3000ms|单次成功AfterCast|WD159::volley|4140/3574原生状态及wd159check|普通/触发/取消边界摘取通过|
|齐射伤害|合法敌人，30码/LOS；目标8码AOE|敌人|官方随等级基础＋.285RAP，RANGED命中/暴击；既有回收修饰一次|瞬时，无持续减益|Damage发射前系数，SpellBonusData全0|原生命中特效/伤害|实际本地链语法/公式；整机待测|
|齐射→拟态|自己存活拟态40码/LOS|守卫复制|原生triggered copy，owner归属|守卫到期/死/切图|WD68A::Mirror，WD159::Done|独立弹道/命中|调用链核对，真实复制待测|
|赠礼→急速/替换|自己的真实拟态GUID/剩余Timer，含extra/mojo|自己|原生140，15%，多守卫只一Aura|最后守卫消失或天赋撤销；每Update同步|Sync→PresenceRemaining→AddAura|4176原生Buff和替换按钮|实际Sync/原生Aura140/读条测试|
|赠礼→齐射伤害|自己有赠礼；命中时自己的Spirit|齐射主/范围/复制|每魂2%，0..10%，OnHit单次|不满足即无|WD159::volley::Hit|天赋说明/读诊断/战斗伤害|摘取数值；目标减免舍入实机待测|
|代价→重置|自己5魂成功普通灵魂蚀|全部已学战刃rank冷却|剩余归0，8秒就绪|单次成功施法；灵魂不消耗|eclipse CheckSnapshot/AfterCast|4175原生Buff/冷却|4/5/trigger/剩余边界摘取|
|代价→必暴/追猎|已受理普通战刃捕获自己的4175|本次战刃/自己追猎|原生命中后crit100%；追猎剩余−15000ms，0封底|成功施法消费，generation保护；取消析构清registry|glaive::Check/Done，Spell::HandleLaunchPhase|原生暴击/冷却/8秒Buff|native发射在AfterCast前；registry80000并发；实机待测|
|所有效果|登录激活/移除/死亡/切图/退出|自己|无虚构持续敌方DEBUFF|对应回调清Ready/Haste/替换，PriceMarker撤销清PriceReady|Bridge/lifecycle|真实Aura状态|实际方法正负条件；多人/PvP未测|

## 视觉独立链

齐射官方504582→Visual1717→全部kit/attach/effect/sound；本地888163、824620起kit、813620起effect、910203–205图标。assets.json列实际MPQ来源、逐文件SHA、M2/SKIN/ANIM/BLP/音效，resource-report两端各表独立增量，207检查全旧行/字符串前缀保留、全部引用闭合。持续/叠层/结束：齐射瞬时无持续敌方Aura；就绪/赠礼/代价原始Visual0，仅真实图标计时，不凭空造粒子。施法/弹道/命中/音效沿完整1717链；未游戏渲染，不称已还原视觉。

## 差异和自审发现

- 上游第三参数临时替换API本地没有：沿158私有ID方案保留原始宏和highestRank canonical；不反复learn/remove。
- 上游客户端流式DBC本地没有：客户端齐射CastTimeIndex31=2300、服务端23=1800+500；两端实际现有表读回。原生ranged haste路径同服务器读条，未改其他职业。
- 代价107若按Family0空mask会误加所有技能：SpellInfo白名单精准拒绝fallback，模块只认4030–36。
- 只用native临时Aura会在读条中到期后丢必暴：独立带锁Spell* registry在首次检查捕获、析构清理，不增加核心成员/vtable，头文件逐字去新增声明后等于正式基线；不重演155A布局崩溃。
- Gift计算位置需在命中时读实时灵魂，不能在发射前按旧层数算：本地OnHit仅一次乘，默认SP系数清零，原生暴击/减免继续处理；社区hit.damageBeforeTakenMods字段本地SpellScript未暴露，采用SetHitDamage修改实际结算值，该前置统计字段保持核心值，伤害/吸收与统计舍入待整机回归。
- 初始测试夹具缺int64类型定义、生成器漏O变量，仅测试脚本问题，已修；没有影响或修改生产数据。免费点数及两付费最早59均用实际Lua和隔离SQL核对。
- CalcAmount没有使用GetTarget，无新CalcAmount；OnHit/AfterCast对象先判空和owner，目标不跨回调保留原指针，持久状态只有自己的registry/GUID。

527私有SQL/实际Lua/6Zs/摘取真实方法+替身对象/原生读条与Aura140/真实SQL-C++-Lua/207资源不变量通过；全worldserver构建、真实引擎、多人PvP、随机样本及玩家实测未完成。当前结论：累计候选。安装与配套回滚见README。
