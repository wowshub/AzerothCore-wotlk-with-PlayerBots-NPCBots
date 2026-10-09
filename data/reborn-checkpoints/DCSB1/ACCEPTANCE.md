# DCSB1（DCSB1A + DCSB1B + DCSB1C）验收记录：清本面板一键托管自己

- 日期：2026-10-09；负责：Claude（mod-dungeon-clear 与 DungeonClear 插件；对 playerbots 只读调用公开接口）
- 基线：`2dc049c52`
- 用户原话：「其他的几个你的修复都测试通过了 DCSB1A + DCSB1B 一键托管……」「DCSB1C 现在也跟随 全程自己托管成机器人操作了 全程自己跟随TANK通副本打怪了 这个已经测试通过」
- 测试范围：巫医（无职业 AI）在乌特加德城堡用托管全程跟随坦克、持续攻击、通关，0 死亡；托管/手动切换；面板按钮与中英文。未测：传统职业的坦克/治疗职责切换、普通玩家权限（SelfBotLevel=2）、团本。

## 内容
- DCSB1A：`Util/DcSelfBot.*` + `DungeonClearAddonHook.cpp` 插件指令 `selfbot tank|heal|dps|off|state`，复用 playerbots `self` 命令（SelfBotLevel 权限不变），按 AiFactory 策略名切职责；插件 v3.6-reborn2「托管：坦克/治疗/输出/手动」。
- DCSB1B：`Strategy/DcSelfBotStrategy.h` 新增 `dc selfbot regroup` / `dc selfbot basic`，三个 Context 注册表登记。
- DCSB1C：basic 继承 CombatStrategy（目标死亡即放下目标、走进射程）；regroup 在坦克脱战而自己仍持目标时触发并切回非战斗引擎。

## 来源（提交前核对：源码 7 个文件与各包逐字节一致）
- DCSB1A：`000Ascendupdate20261008/claudefix_20261008_201701_阶段DCSB1A_插件一键托管自己.zip` SHA256 `d6b70ad29e9803465ecb02cc4defedcf4883d8c71f840b7bc862d49eb55eac46`
- DCSB1B：`000Ascendupdate20261008/claudefix_20261008_225541_阶段DCSB1B_托管巫医持续攻击与战后回队.zip` SHA256 `7eb5ec808a3ab1c4377dcec2b481d411b34738c3b57df5c1714f2b159bb0b11f`
- DCSB1C：`000Ascendupdate20261008/claudefix_20261009_005906_阶段DCSB1C_托管巫医怪死后切回跟随.zip` SHA256 `57e9c6e5dc06f5ff60f7e5620f44207b64fa12642956a290ad8d485b5d946e56`
- 客户端插件：wowshub/mod-dungeon-clear-addon v3.6-reborn2。无 SQL、DBC、配置改动。
