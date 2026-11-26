# ER-LOOT-XP-20261126：流放者之岛掉落金币与经验

用户原话(2026-11-26)："掉落和金币（LOOT1A V2） 通过 / 经验（XP1A）通过 / 护甲限制（ARMOR1A） 还是不行"。

## 验收范围

| 项 | 内容 | 状态 |
|---|---|---|
| LOOT1A V2 | 24 种生物的杂物、金币、按等级分档的白色初始装备、首领绿装；任务掉落不动 | 用户实测通过 |
| XP1A V1 | 59 个任务随玩家等级并提高经验档；25 种怪击杀经验 ×2 | 用户实测通过 |

用户没有报告出岛等级、双阵营、掉率数值是否逐项核过，不外推。护甲限制(ARMOR1A)未通过，本归档不包含。没有归档：BOSSEASY1A、ARMOR1A V2、GY2A、MODEL2A。
发布时没有编译、没有执行 SQL、没有读数据库、没有部署。

## 安装
接在流放者之岛已归档 SQL 之后，停 worldserver，world 库按序执行，然后启动；删客户端 `Cache/WDB`。
1. `data/customfixsql/world/exiles-reach/20261126_56_loot1a_v2_world_loot1a_v2.sql`
2. `data/customfixsql/world/exiles-reach/20261126_57_xp1a_v1_world_xp1a.sql`

以后重跑岛上任务或海滩 SQL，要接着重跑这两个文件。撤销见 `undo/`。无客户端补丁、无 DBC、无脚本。已装并测试通过无需重复执行。
`tools/` 为生成脚本，含本机路径，使用前要改；掉落基础数据来自本地 LoreWalkerTDB，按 3.3.5 现有物品过滤。
