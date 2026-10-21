---
name: port-coa-playerbot-class-ai
description: Port a CoA custom class into this project's existing Playerbots engine using learned spells and committed builds, safe automatic target propagation, team-aware summons, native resources, and measured dungeon validation. Use for class AI adapters and their native spell hooks, not standalone spell visuals or a claim that the entire class is complete.
---

# CoA职业Playerbot接入与实测收敛

## 已验证边界

2026-10-21用户选择WD176A累计晨测包作为本轮可提交版本，实际观察输出改善、普通蛇卫之外已使用六蛇技能。它证明基础AI/召唤链有实机改善；没有固定对照数值，不证明所有专精/技能/学习交易/生命周期矩阵全通过。WD177–184治疗等仍为候选。正式提交状态以根协作说明和发布记录为准，不能只按包名猜。

来源：`000Ascendupdate/000Ascendupdate20261020/WD176A_package.json`；冻结ZIP SHA256 `43d6db520e3d86e37ac5d951f19894bb2e8d968244d9bc451a769e5807f9f6e1`。前置WD167A自动选敌基本验收已发布。没有把输出观感改写成精确DPS增幅。

## 接入顺序和容易漏掉的层

1. 先按项目AGENTS、职业规划和上游审查规范固定版本。把官方技能/资源、社区CoA技能代码、社区Playerbots轮转分开对账；上游classID/SpellID不能直接当本服值。
2. 列出每族技能的首级获得、导师后续等级、实际当前保存槽/专精、互斥和资源。天赋书页是展示分类，不能据此禁止跨系已学通用技能。
3. 先做只读状态桥接：`WD168::ReadPlan/Capture`读取已提交状态，不为了AI观察调用Load/Ready或新建角色状态。草稿/推荐模板不能冒充实际激活构筑。
4. 接已有引擎的私有Context/Strategy/Action与工厂、职责路由，避免另造全局AI循环。新class回落到AiObjectContext不等于有职业策略；`bySpec`职责和实际Strategy职责要分别核对。
5. 选择真实HasSpell且满足等级的rank或原生就绪替换。单独核对实际费用：本项目PB CanCastSpell探测可能忽略power cost，不能把探测通过当法力足够；执行仍走普通原生CastSpell/prepare，不免费触发、不直接加减血蓝。
6. `isUseful`的选择不是最终授权。Execute重新分诊、检查当前目标/方案/资源/范围/LOS/移动权限；已有强制躲避和stay优先。缺弓/弹药不应冻结合法其它技能。

## 自动来源、召唤与副目标

- 手动技能与自动策略分层：自动施法按本次精确spell记录来源，不给角色永久贴“自动”标记；原生延迟/周期/派生技能要传递这次来源，重新施放不能沿用前次bool。
- 有选中敌人不代表已参战。直接目标、传播、复制、拟态/雕像、召唤攻击各层都要检查owner实际战斗关系、合法攻击、地图/相位/LOS与可破控；收集名单后每次真正施法前重查，跨帧保存GUID。
- 守卫按现有槽和真实存在GUID选择，不用“缺一个普通蛇”概括所有召唤。观察实际参战怪数、血蓝及队友真实覆盖；萨满在队不等于已经放了治疗图腾。
- 玩家GroupReference不包含全部NPCBot，混编成员要用真实GetBotGroup等关系核对。WD183枝外NPC急救扫描只是离线候选，不因本条成为已实测能力。
- 生命周期清理跟随原生拥有权。自动选敌保护不能顺手改原伤害、费用、触发概率、召唤cap或真人手动范围。

## 如何证明改进与控制收尾

清本对接记录run_id、AI版本、实际build槽/revision、装备/队伍/路线、GM辅助；按真实主动成功、派生技能、守卫/宠物主人分别归因。5秒选择日志不是施法次数，周期治疗不是又主动施法一次。相同条件至少3局再比较伤害、有效治疗、过量、死亡、耗蓝及呆站。

每批分开写：未实现、已实现未实测、基本实测通过、专项通过、已发布。先修基础闭环的缺陷再叠新技能；最终以明确功能台账和阻塞缺陷清零收尾，而不是无限出包。候选治疗阈值和最优构筑不作为下一职业的通用常数。

发布时复用现有发布Skill：对冻结候选取逐阶段差异，三方合并到最新正式基线；不整文件覆盖含Claude修复的公共PB文件。子模块先提交推送，再主仓gitlink；不能把当前日常全量脏树当已测来源。检查实际子模块.git，避免在空目录读到父仓库HEAD。

配套教学：[TUTOR.md](../../beascendtutor/port-coa-playerbot-class-ai/TUTOR.md)。本次收尾计划：[计划](../../计划_巫医1.0收尾与下一职业准入_20261021.md)。后续实测继续更新本Skill，不复制一套每包重复的Skill。
