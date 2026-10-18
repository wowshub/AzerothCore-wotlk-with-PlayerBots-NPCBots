# DCBATCH20261018 — 清本模块一批功能验收（Claude）

- 日期：2026-10-18。
- 用户原话："这几个都测试作为通过 推送和一个功能一个功能地推送吧"。
- 范围：待测清单（`000Ascendupdate/000Ascendupdate20261017/待测清单_Claude_20261017.md`）A–J 组全部候选包。
  - 用户实测过 A、B、C、D3（DCGM1G 重测）。
  - 其余由用户这句话确认为通过。
  - 都属于"基本通过"，不外推所有副本、所有职业、长时间压力或异常矩阵。
- 父提交：db6de62da（Codex WD161）。

## 服务端与客户端镜像：每个功能一个提交

| 功能 | 提交 | 候选包 |
|---|---|---|
| DCTEST7A 测试本局统计里的首领清单 | 2f753b86e0d00c3b0d73881795ca4e2acf54b5ca | 000Ascendupdate20261016/claudefix_20261016_080228_阶段DCTEST7A_测试首领清单 |
| DCGM1B 测试队作弊档（剧情 / 休闲 / 速通） | 010450e809bcb1d23b36f713a801327d1d9875de | 000Ascendupdate20261016/claudefix_20261016_092943_阶段DCGM1B_作弊档 |
| DCRZ2B 玩家队跑尸倒计时 | 44f57664cf8df2ad73a4bb0640bbbfac4c7d625a | 000Ascendupdate20261016/claudefix_20261016_093636_阶段DCRZ2B_玩家队跑尸 |
| DCGM1B2 测试列表选档、四档各一局、运行中切档 | b8aba58916c84ed9a3e702d21d1b7519a2407fb8 | 000Ascendupdate20261017/claudefix_20261017_191132_阶段DCGM1B2_测试列表选作弊档 |
| DCGM1B3 档位标签与记录分类（schema 17） | 2fdf2f8644b0cc6c9fdf1f5995b46941a0c47008 | 000Ascendupdate20261017/claudefix_20261017_192137_阶段DCGM1B3_作弊档标签与日志分类 |
| DCGM1D `.dc party` 我的队伍 GM 操作 | f802d092319a390589553be24be9dac629cecfa3 | 000Ascendupdate20261017/claudefix_20261017_201656_阶段DCGM1D_我的队伍GM死亡复活 |
| MBR1A MultiBot 列表同阵营、等级排序、常用组队（DC botinfo） | c59cf8c79cb2b25dc378164a4bb98ea2c31c4d15 | 000Ascendupdate20261017/claudefix_20261017_205305_阶段MBR1A_机器人列表同阵营等级排序与常用组队 |
| MBR1B 队伍机器人都显示、提示稳定、星标按钮 | fb471016034f355c59ff743160b7813c572d3b4b | 000Ascendupdate20261017/claudefix_20261017_220957_阶段MBR1B_队伍机器人都显示与提示修复 |
| DCGM1F 我的队伍作弊档补全（npcbot、离队取消、面板标签、日志 tier=） | 554f3aec5309d577d0664126e08ddf88e9d44c2d | 000Ascendupdate20261017/claudefix_20261017_223537_阶段DCGM1F_我的队伍作弊档补全与标签 |
| DOCK1R 收纳框每行个数上限 | e8b77d46d3613da5a8d7513318053580a9702b23 | 000Ascendupdate20261017/claudefix_20261017_200114_阶段DOCK1R_每行个数上限 |
| DCGM1G 死亡状态下 GM 菜单可用 | b35122ed45c37f8f675b3eafd34cb83ff844d81b | 000Ascendupdate20261018/claudefix_20261018_010458_阶段DCGM1G_死亡时GM菜单可用 |
| DCENC1A 首领战卡死自动脱战 | 2b8927112ae16913e25f3bc1eecdc3a9c1be1c80 | 000Ascendupdate20261018/claudefix_20261018_011406_阶段DCENC1A_首领战卡死自动脱战 |
| DCAST1A 坦克回援被打的队友 | 5944b2c186ff432088a88ac4c96a81e4c90cb744 | 000Ascendupdate20261018/claudefix_20261018_013507_阶段DCAST1A_坦克回援被打的队友 |
| DCSTR1A 拉回队员不传送托管的真人、不落空 | 2f77dd299e7afb99ea9975567f04aeaa85b2074b | 000Ascendupdate20261018/claudefix_20261018_013841_阶段DCSTR1A_拉回队员不传送真人且不落空 |
| DCHOL2A 闪电大厅比亚格里巡逻暂停拉怪、副本下方救回 | fd96b3c7c04d1f843d6c6a39504820ec36d60b45 | 000Ascendupdate20261018/claudefix_20261018_014919_阶段DCHOL2A_闪电大厅巡逻首领与副本下方救回 |
| DCHOL2B 比亚格里回拉到用户实测的北侧通道营地 | 96c2b8e041e28d2dea7a447079c7e533b51838a0 | 000Ascendupdate20261018/claudefix_20261018_022214_阶段DCHOL2B_比亚格里拉到北侧通道打 |

## 核对

- 重放顺序与链条：
  - 10-17 及以后的包：每个包覆盖前，工作树里的对应文件都与该包的"原文件备份"一致（换行统一为 LF 后比较）。
  - 10-16 的三个包（DCTEST7A、DCGM1B、DCRZ2B）：它们由打包工具串联生成，备份存的是最初的原始文件，没有逐个核对链条，正确性由下面的最终比对保证。
- 最终比对：16 个提交之后，34 个文件（服务端 `modules/mod-dungeon-clear` 和 `data/reborn-client` 下的 MultiBot、RebornDock）与用户编译并实测的现场源码、现场客户端完全一致（换行统一为 LF 后比较）。
- 编译检查：DCGM1F 之后的各包都做过 `cl /Zs` 语法和类型检查（MSVC 14.44，modules.vcxproj RelWithDebInfo 参数），0 错误，并做了反向验证（故意写错能报出错误）。用户已自行编译并实测。
- 新增文件：`DcPartyTier.h/.cpp`（DCGM1F）、`DcUnderFloorRescue.h/.cpp`（DCHOL2A）。新装时需要 CMake Generate。
- 客户端 MultiBot：仓库里此前只有 MultiBot 的语言文件，这次第一次纳入 `Core/MultiBotInit.lua`、`Core/MultiBotHandler.lua`、`MultiBot.toc`、`Features/MultiBotRebornRoster.lua`，提交的是用户实测的完整文件。

## 客户端

- DungeonClear 插件在独立仓库 wowshub/mod-dungeon-clear-addon：v3.6-reborn38，提交 a77a9d15faf9cc410424a703277164e2d0a80c15，每个功能一个提交。附件 DungeonClear-3.6-reborn38.zip 的 SHA256 为 379577eedc10bd7f6c58a8ac409ee332b2dd93135686ab25283e91750c627357，与用户实测客户端逐字节一致。
- MultiBot 和 RebornDock 的变更文件，作为本仓库 Release 附件 reborn-dcbatch-20261018-client.zip 发布，SHA256 为 e83ff2f4242ebf771da9306af8d383924035490af4c426bbe9cc3642b59a8a07，文件取自用户实测客户端。

## 边界

- 没有 SQL、DBC、MPQ 改动，没有部署，没有生产 SQL，没有编译 EXE 上传，没有改 playerbots 子模块。
- 比亚格里营地坐标 (1445.72, 40.80, 58.77) 来自用户在游戏里实地站位 `.gps`；回拉的完整流程（拖怪、击退方向）在本批验收中属于"基本通过"。
- 待做（不在本批）：主面板三栏重绘（副本列表、主控制、组队列表）、DCTEST8A 测试窗口选人、DCGM1C 抱大腿模式、DCSB2A 真人队友托管弹窗。
