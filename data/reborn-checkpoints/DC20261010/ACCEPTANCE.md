# DC20261010 验收记录：岩石大厅修复 + 坠落记录器 + 机器人测试面板

- 日期：2026-10-10；负责：Claude（mod-dungeon-clear、mod-playerbots 共享区域、mod-reborn-bot-telemetry、DungeonClear 插件）
- 用户原话：「前面的测试已经差不多了 功能都通过了 可以进行分功能commit 提交推送 release了」
- 前置基线：threemodelcardpro `72d28e5cbc1ca4f3734befd05bafa0f4dc8dc759`（DCAI1A）

## 提交（按功能）

| 功能 | 交付包 | 提交 |
|---|---|---|
| DCAI1B+DCAI1C 机器人躲技能不走下平台；岩石大厅暗物质 | DCAI1B、DCAI1C | 子模块 wowshub/mod-playerbots `reborn-dcai1a-20261009` → `c6b1939a6875c760f2046d887920e6a11945db66`；主仓库 gitlink `2999d7219dd5c319bf3084a7b0cad016b6237aaa` |
| DCRZ1A 只把已学会复活技能的队员当作复活者 | DCRZ1A | `09ab445150de2b99f6fd44b4a0deb984013de493` |
| DCOBJ1A-C + DCMOV1A-B 灭团/重进后按副本进度恢复目标；事件移动不再直线穿墙；法庭等跳过剧情后才算完成 | DCOBJ1A、1B、1C、DCMOV1A、1B | `6aca67e00630215f05e9bac4984ba2bf2cc0c070` |
| DCDIAG1A+DCDIAG1B 坠落记录器（fall / air） | DCDIAG1A、DCMOV1A（含 1B 遥测部分） | `95eda0166ddd75afadfedec80049086ace9e2e55` |
| DCTEST2A-4C 测试列表、机器人详情、面板调上限、`.dc spectate follow <名字>` 修复（服务端） | DCTEST2A、3A、4A、4C | `879c3b99ea6b729af84bebc7fef209557ebe40b1` |
| DCTEST1A-4D 插件 v3.6-reborn11（客户端） | DCTEST1A、1B、2A、2B、3A、4A、4B、4C、4D | wowshub/mod-dungeon-clear-addon `67cd2441cb714d78bbfed869c9296e792443b2f4`，tag `v3.6-reborn11`，Release 附件 `DungeonClear-3.6-reborn11.zip` SHA256 `03a3c776c7e1a0b60061cb8c38e080b258b08949b12cf88f555005dd018e1519` |

## 测试范围（用户在游戏内）
- 岩石大厅多次完整通关：不再走下克莱斯塔卢斯平台、不再直线穿墙掉坑；躲火、躲暗物质；法庭之后灭团或 `dc on` 不再回去做护送；法庭会等 Brann 跳过剧情的对话，然后开门；斯约尼尔击杀。坠落记录器只记录到技能位移，没有 "air" 记录。
- 圣骑士学会救赎（48950）后能复活队友；没学会时不再一直等待。
- 测试窗口与测试列表：4 组测试同时运行（rfc / wc / deadmines / sfk / maraudon / bfd 等）、观看中置顶、切换观看、右键菜单、本局统计、上限弹窗与 -/+、机器人详情、视角按钮、滚动条、选中副本保持可见。
- 未测：其他副本和团本里的具体战术效果；"护送途中灭团"这条路径（规则推演为不会标记护送完成）；DCTEST 在非 GM 账号下的提示。

## 不在本次范围
- LFGFIX1A（`src/server/game/DungeonFinding/LFGMgr.cpp`）：满员队伍重启后无法排随机本的问题**未解决**，不提交，等待证据。
- Codex 的巫医相关未提交改动、mod-ale / mod-starting-pet / mod-dungeon-scale 子模块改动、`.psd` 文件：与本线无关，保持原样。

## 来源核对
提交前用脚本逐文件比对：源码里 22 个改动文件与各自最后一个交付包逐字节一致（SHA256）。客户端安装目录 `newrebornWOWli20261008beAscend/Interface/Addons/DungeonClear` 与插件提交内容一致（忽略换行符）。

| 交付包（000Ascendupdate…） | 校验对象 | SHA256 |
|---|---|---|
| 20261009/claudefix_20261009_020535_阶段DCRZ1A_清本复活者需已学复活技能 | zip | `6d60d9d393168f511a34f22e8e2c76f2e5f5263ca26a9b3812214fb9284e9010` |
| 20261009/claudefix_20261009_024846_阶段DCOBJ1A_重新开始时补记已完成目标 | zip | `4b96d2fcfd194e8c38763d9e49179aa29f2aabfa9d5b238369dba81b7bf48741` |
| 20261009/claudefix_20261009_030606_阶段DCOBJ1B_面板与重新开始都按已击杀首领补记目标 | zip | `41a3d97a6e8eaaca10322b2f9f5cf3e906f8db8b869f48502d7f92538ff8cb25` |
| 20261009/claudefix_20261009_031339_阶段DCOBJ1C_通关后条件事件也显示完成 | zip | `6a1b7d2944e71eb83bcc23f979de4cb2373c9ef2f6b0bf83bd2e1d7643750fc0` |
| 20261009/claudefix_20261009_050855_阶段DCAI1B_躲火修正与岩石大厅暗物质 | zip | `9b60be4d52fcf9468dc384ec0c91748a168a2a2580c0116c84977a084c35b35c` |
| 20261009/claudefix_20261009_054123_阶段DCAI1C_机器人躲避不再走下平台 | zip | `1a755acdcb775912509a774f56e0459839ad2b94e24127f7b6a9e385d24983c0` |
| 20261009/claudefix_20261009_055133_阶段DCDIAG1A_坠落记录器 | SHA256SUMS.txt | `c5d8acedcfaceab2f414a60313798e6b32a219669f6bf923621c89984992e474` |
| 20261009/claudefix_20261009_081048_阶段DCMOV1A_事件不穿墙与灭团后目标恢复 | SHA256SUMS.txt | `623bf61e3613b6a12b23074b697d7cd6b7cca3ac390f84fcb188d6b87b8ea962` |
| 20261010/claudefix_20261009_183705_阶段DCMOV1B_法庭不提前算完成 | SHA256SUMS.txt | `cd1310ce098e0fa8c38b10ca3552af4cbb16e56a3705872cb160508853511051` |
| 20261010/claudefix_20261009_181811_阶段DCTEST1A_插件测试窗口 | SHA256SUMS.txt | `5d175382916ff3c7ba014b79a9819b0e2e3c104db5701b79a4cfc95bf13cda6b` |
| 20261010/claudefix_20261009_185512_阶段DCTEST1B_测试窗口副本名汉化 | SHA256SUMS.txt | `2e332c6fd1c0ffbf292e1f8f231724dadea590542b3004f85792ab57d38595dc` |
| 20261010/claudefix_20261009_190413_阶段DCTEST2A_测试列表与机器人详情 | SHA256SUMS.txt | `447c85df8306e96a10c4811ffa294bc15b9e334f40b91d0ff0f3be93265945c0` |
| 20261010/claudefix_20261009_195016_阶段DCTEST2B_测试列表放左边可拖动 | SHA256SUMS.txt | `02e1c9add0709211c9f9e0b60b33631d88d43765b4f073cb37079429b9c503e1` |
| 20261010/claudefix_20261009_195630_阶段DCTEST3A_测试右键菜单与上限弹窗 | SHA256SUMS.txt | `98bd07da9197766d94521d3daf8dd6c6d23d868466385646c32be0dfb5ac8b89` |
| 20261010/claudefix_20261009_200455_阶段DCTEST4A_机器人详情面板 | SHA256SUMS.txt | `007d3e86981f852e39b069281e2789a1d0b44cbf2b414e0217f92dce521a5f81` |
| 20261010/claudefix_20261009_215053_阶段DCTEST4B_选中副本保持可见 | SHA256SUMS.txt | `e5fe7c9d47a22b0fd99b54612379bee00971f9be7a68a359074bbf774242904d` |
| 20261010/claudefix_20261009_215855_阶段DCTEST4C_观战视角按钮与跟随修复 | SHA256SUMS.txt | `26d8d839a6aa75b1ecb85239afed1d6d73202be09aed6c93dddc6c30db86ec46` |
| 20261010/claudefix_20261009_220240_阶段DCTEST4D_副本列表滚动条 | SHA256SUMS.txt | `0d9006139dbb7c7c1ac9c46e9158b9f06be0a13b5cf530ab5dcb04de5b72d1f5` |

## 部署
- 服务端：无 SQL、无 DBC 改动；无新增文件，不需要重跑 CMake。`RebornBotTelemetry.conf.dist` 新增 3 个可选项（默认值即可）。
- 客户端：安装 DungeonClear v3.6-reborn11（Release 附件），`/reload` 即可。
