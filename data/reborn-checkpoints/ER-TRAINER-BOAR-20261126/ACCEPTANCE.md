# ER-TRAINER-BOAR-20261126：流放者之岛职业导师与任务野猪限制

用户原话(2026-11-26)："测试这两个修复都通过了 给我推送吧"。按对话上下文，对应最近交付的两项：TRAINER1A V3、VEH4A V1。

## 验收范围

| 项 | 内容 | 状态 |
|---|---|---|
| TRAINER1A V3 | 巨型野猪前各职业原版训练师同点刷新，按职业只看见自己的一位，右键开训练窗口 | 用户实测通过(总体确认) |
| VEH4A V1 | 只有接了任务且尸骸目标未满的角色能骑野猪；野猪只伤害尸骸 | 用户实测通过(总体确认) |

用户没有逐项报告 SQL 读回值、测过哪些职业或阵营。不外推：全部职业与自定义职业导师、抽卡模式(现在可打开训练窗口)、两阵营各自的野猪限制、中途重登、组队、长期运行。
失败记录：TRAINER1A V1(隐形列表 NPC)、V2(脚本 SendTrainerList)用户实测没有训练窗口，根因未查明，均作废、未归档为可用版本。
不包含(仍为候选或未单独确认)：GY2A、LOOT1A V2、XP1A、ARMOR1A、MODEL2A(首领模型此前确认通过，尚未归档)。发布时没有编译、没有执行 SQL、没有读数据库、没有部署。

## 安装(接在流放者之岛已归档 SQL 之后)
停 worldserver，按序在 world 库执行，然后重启。
1. `data/customfixsql/world/exiles-reach/20261126_54_trainer1a_v3_world_trainer1a_v3.sql`
2. `data/customfixsql/world/exiles-reach/20261126_55_veh4a_v1_world_veh4a.sql`(依赖已归档的 VEH3A、ALLY1C 两头野猪)
3. `lua_scripts/RebornBoarRule.lua` 放进服务端 `lua_scripts`；SHA256(实装原字节) `07e4cba64994a39aea665a05a58a0e5831590d1e7b554791cc35c13d7ae593f9`。
4. 删除 V1/V2 留下的 `lua_scripts/RebornClassMentor.lua`(如装过)。

撤销：`undo/` 内对应 SQL，并删除 RebornBoarRule.lua。无客户端文件、无 DBC、无需编译。已安装并测试通过的服务器无需重装。
