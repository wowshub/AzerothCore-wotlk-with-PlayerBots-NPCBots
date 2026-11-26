# ER-BOSS-ARMOR-20261126：暗槌三个首领降为普通怪，经典模式护甲限制

用户原话(2026-11-26)："可以杀死那三个boss 了 我到暴风城 9级大半了" / "装备问题也搞定了" / "新账号 有限制了"。

## 验收范围

| 项 | 内容 | 状态 |
|---|---|---|
| BOSSEASY1A V1 | 图克、戈尔格罗斯、首领卡雷苟斯改为 9 级普通怪(血量倍率 2、伤害倍率 0.5、经验倍率 4)，脚本去掉三个首领的技能 | 用户实测通过：三个首领可以击杀 |
| ARMOR1A V2 | 经典模式下，规则启用后新建的角色与 playerbots 按职业限制护甲；聊天提示原因 | 用户实测通过：新账号角色受限 |

观察记录：联盟号走完到暴风城时 9 级过半(XP1A 的部落单人估算为 10 级)。
不外推：部落首领战、抽卡模式放行、机器人受限、各职业逐一、40 级换甲、旧角色。可选的角色库起始时间 SQL 没有验收，不归档。
发布时没有编译、没有执行 SQL、没有读数据库、没有部署。

## 安装
接在此前归档内容之后。
1. 停 worldserver，world 库执行 `data/customfixsql/world/exiles-reach/20261126_58_bosseasy1a_v1_world_bosseasy1a.sql`。
2. `lua_scripts/Dark2A.lua` 覆盖服务端同名文件(SHA256 `2a782b5baf0a68ec1bb5bfd28a048a87e19add7db527de07cf5b0fedcabfd17b`)。
3. `lua_scripts/ClassArmorRule.lua` 放入 `lua_scripts`(SHA256 `0d67595cc8b48cf269205279213ea80a5aa15e56ad9edc10629e82278e93eabc`)。首次运行时脚本在 characters 库建表 `reborn_armor_rule` 记录启用时间，只限制此后新建的角色；playerbots 一律限制，身上不合规的护甲在登录时邮寄退回。
4. 启动。无客户端文件、无 DBC、无需编译。

不要在之后重跑 DARK2A / DARKFIX1A(首领变回精英)；重跑 XP1A 会把三个首领经验倍率改回 2。
撤销：执行 `undo/undo_58_bosseasy1a.sql`，Dark2A.lua 换回 ER-ALLIANCE-20261126 里的版本；删除 ClassArmorRule.lua。
