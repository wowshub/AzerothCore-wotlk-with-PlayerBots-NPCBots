# TREAS2A4 批次验收：野外寻宝宝箱（种类、原生拾取窗口、拾空消失）+ DCCRASH1A + DETNPC1A（Claude）

- 日期：2026-10-24。
- 用户原话：「早就测试过啦 通过了」（TREAS1D 外观/手形、TREAS1E 屏幕提示、DCCRASH1A）；「现在可以拾取到东西了」「都拾取了」（TREAS2A3 拾取窗口，稀有宝箱 990201）；「TREAS2A4 测试通过」；「发」。
- 范围：
  - **TREAS1B/1C**（模块 mod-reborn-treasure）：点位表刷宝箱、线索提示、野外计时刷新、副本每局一次；GM 命令 `.treasure add/list/respawn/remove/reload`。
  - **TREAS1D**：宝箱模型 259、IconName 置空（手形光标）。world SQL。
  - **TREAS1E**：客户端插件 RebornTreasure 1.1.0，屏幕中间提示 + 探险日志。
  - **TREAS1F**：GameObject.cpp 让 990200–990202 像任务物品一样闪光（核心共享区域，一处判断）。
  - **TREAS2A**：宝箱种类表 reborn_treasure_types、模板 990200–990299、掉落走 gameobject_loot_template、金币走 gameobject_template_addon、GM 数据通道 `.treasure ui …`。
  - **TREAS2A2**（诊断，含在后续文件里）：开箱时给 GM 打一行灰色 `[寻宝调试]`，普通玩家看不到。
  - **TREAS2A3**：锁编号 57（与原生“破损的箱子”一致），客户端才显示拾取窗口。world SQL。
  - **TREAS2A4**：拾空后宝箱删除，按开箱时写好的计时重刷；登记到删除之间的点击被忽略。
  - **DCCRASH1A**：清本开始时雇佣的 NPCBot 不在地图不再断言崩溃。
  - **DETNPC1A**：客户端插件 DetailsNpcBots（Details 统计 NPCBot）。
- **不在范围 / 未测边界**：普通(990200)、史诗(990202)宝箱未单独实测；TREAS2A 的 GM 数据通道 `.treasure ui` 只有服务端，面板（TREAS2B–2D）未开发；副本里宝箱金币被 mod-dungeon-scale 按人数缩放（单人魔枢 1/5），是否豁免待用户决定；MOPFIX1A（zzzMoPItemTooltips 对比提示框崩溃规避）无复现证据，不发布。

## 提交与链条

| 提交 | 内容 |
|---|---|
| 6b9b0ce58202865b58a8fe1e1dc78009c627232b | DCCRASH1A：DcPlayerRuns.cpp |
| 5d3a37d1a1943faee37a5a96bc8091ecf18abb19 | TREAS1B–2A4：模块、GameObject.cpp、world SQL、RebornTreasure 插件 |
| 70608b59a18a05b0fed4714ccaacb63bf8094cca | DETNPC1A：DetailsNpcBots 插件 |

链条核对：每个包覆盖前文件与 backup_原文件 哈希（CRLF 归一）一致，依次 TREAS1B(新建) → 1C → 1F → 2A → 2A2 → 2A3 → 2A4；客户端 RebornTreasure 1B(新建) → 1E。最终 5 个服务端文件与用户日常源码树（实测编译用）逐一哈希一致。

## 部署顺序（用户执行）
1. world 库依次：TREAS1B 三个 SQL → TREAS1D → TREAS2A → TREAS2A3（`data/customfixsql/world/treasure/`）。
2. 源码覆盖后 CMake Generate（新模块），编译；`mod_reborn_treasure.conf.dist` 复制为 conf。
3. 客户端：`data/reborn-client/Interface/AddOns/RebornTreasure`、`DetailsNpcBots`。
