# ER-MODEL-GY-20261126：食人魔与暗槌首领原版模型，岛上复活点

用户原话(2026-11-26)："首领和食人魔原版模型（MODEL2A）…内院灵魂医者（GY2A）：这两个都通过了"；三个首领外观此前原话"测试这三个BOSS都通过了"。

## 验收范围

| 项 | 内容 | 状态 |
|---|---|---|
| MODEL2A V1 + V2 | 食人魔、副官、守卫、戈尔格罗斯、图克、卡雷苟斯(人形与巨龙)换零售原版模型；V2 修复小食人魔白模肩甲 | 用户实测通过 |
| GY2A V1 | 暗槌内院复活点与灵魂医者(117510)，并重装岛上七处(117502–117508)，医者双阵营可见 | 用户实测通过(总体) |

不外推：双阵营逐点复活、副本内部死亡、长时间运行。发布时没有编译、没有执行 SQL、没有读数据库、没有部署。

## 安装
1. 客户端与服务端的 `CreatureModelData.dbc`、`CreatureDisplayInfo.dbc` 需含行 710010–710024；二进制与模型别名不入库，原包在本机 `000Ascendupdate/000Ascendupdate20261126/`。发布时服务端两表 SHA256：CreatureModelData `a07624cdff23f01d36d9598cc2880409d2b9adf93a8177fc82ac5954f149bbfe`，CreatureDisplayInfo `6a7525dd90b6d8cce94862e4dec529f4fdb7779566dc59a097a9de8a29e71be7`。这两张表是多人共用文件，覆盖前按哈希台账核对。
2. 停 worldserver，world 库按序执行：`data/customfixsql/world/exiles-reach/20261126_59_model2a_v1_world_model2a.sql`、`data/customfixsql/world/exiles-reach/20261126_60_gy2a_v1_world_gy2a_graveyard.sql`(60 内含原 GY1A，旧 GY1A 不要单独重跑)。
3. 启动，删客户端 `Cache/WDB`。

以后重跑部落 DARK 系列或 ALLY1G 的 SQL 会把外观改回去，之后要重跑 59。撤销见 `undo/` 与原包撤销目录。
