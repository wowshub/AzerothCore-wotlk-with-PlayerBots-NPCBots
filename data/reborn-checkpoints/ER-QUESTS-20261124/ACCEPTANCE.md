# ER-QUESTS-20261124：流放者之岛（Exile's Reach）部落线，2026-11-24 用户验收的三项（Claude）

## 用户验收（原话 / 范围：Markas，试装客户端，Horde，单人）
| 项目 | 原话 | 范围 | 文件 |
|---|---|---|---|
| 乘坐飞行侦察 59940（模型夹住玩家后背，飞过尸骸群落地才计数） | "这下对了" | 起飞→绕飞→完成 | Beach1C.lua；SQL boost1a / boost2a |
| 篝火点击提示 59932（发光手套光标、任务闪光） | "好棒这次可以了 满意" | 光标与闪光 | SQL camp1a_v3 |
| 急救包 59930 | "这次完美了" | 点伤员→站起→计数→连续使用 | Beach1A.lua；SQL firstaid1a |
| 缩放器 59941（自定义编号 9178051，使用法术 746，变大再变回） | "可以用了 图标也对了" / "几秒之后也变回之前的大小了" | 3 头野猪计数、图标、变回原大小 | Beach1C.lua；SQL sizer1a_v4 / sizer1b |

## 边界（未测 / 未查明）
- 零售编号 178051 的物品在客户端始终没有"使用："，原因**未查明**（客户端 Item.dbc 行与能用的急救包格式相同）；改自定义编号 9178051 后正常。
- 电光装饰法术 45935/28136 是否可见未确认；其他种族/体型、联盟线、BOOST1B(59942)、BEACH1D 未测。
- 本批依赖之前的岛任务基础包(BEACH1A/1C quest SQL、BOAR1A 野猪模型、船与过场动画等)，这些**不在本次提交**。

## 二进制资源（不入库，哈希供核对）
- Patch-ZC `Creature\GnomeCopter\GnomeCopter.m2`（追加骑手挂点 z=+0.15）sha256 2d6d043daad6d52ed816b336f07953840445972913a776ef813fb2589f2602e7（原版 b23f8dcf…）
- Patch-XA `DBFilesClient\Item.dbc`（+1 行 9178051，类别12，外观 90551，119480 行）sha256 a6ca7772252851e64786ee752fa7d9af07b53e3c22c797edeb12a2d474611ce8（基线 99019f83…）

## 部署顺序（用户自己执行）
SQL 按文件名日期顺序执行于 acore_world；Lua 覆盖 lua_scripts 后**重启 worldserver**（飞行坐骑外观、物品使用法术都是启动时读取）；客户端清 Cache\WDB。skills/ 与 tutor/ 是同日更新的永久 Skill/Tutor 副本。
