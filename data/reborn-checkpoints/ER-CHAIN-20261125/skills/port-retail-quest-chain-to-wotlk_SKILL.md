---
name: port-retail-quest-chain-to-wotlk
description: 把零售(12.x)的一整条任务链(任务文本、目标、前后置、发放/交付NPC、怪物与出生点、掉落、任务物品)从 LoreWalkerTDB 提取出来，按 3.3.5 AzerothCore 重做并交付：建任务台账、批量提取 json、把零售 quest_objectives 翻译成 RequiredNpcOrGo/RequiredItemId/ItemDrop、对话/使用物品/飞行/过场动画等零售机制的简化做法、NPC 外观替代与出生点编号规则、中英双语文本、玩家可见的任务图标。移植流放者之岛(Exile's Reach)或任何零售新手区/任务线、给新种族接任务链时先读。
---

# 零售任务链移植到 3.3.5(流放者之岛部落线实战提炼)

## 证据状态(先读)
- 来源：`000Ascendupdate/000Ascendupdate20261123/` 下 SHIP2B V3–V5、SHIP2C、BEACH1A V1–V3、BEACH1B、BEACH1C V1–V2、BOAR1A V1–V2、ITEMICON1A V3、QPOI1A、QMAP1A V1–V2、SHIP2D/2E、FIRSTAID1A–1C、BOOST1A、MAP12S 系列。Claude 开发，用户在试装客户端实测。
- **用户实测通过(可当成功经验)**：船上任务链(59926–59928)与失事过场动画；海滩 59929–59931 的杀怪/拿物品/躺地伤员；营地 59932/59933；零售野猪模型导入；背包物品图标(急救包)；急救包"使用→治疗→计数→连续使用→自动选最近未治疗的伤员"(FIRSTAID1C，用户原话"这次完美了")；岛上服务端地面数据+灵魂医者。
- **仅候选，没实测，不能当成功经验**：BOOST1A(乘坐飞行侦察)；QMAP1A V2(大地图图标)；SHIP2D V2(ESC 跳过失事动画直接去岛)；SHIP2E(船上死亡原地复活)；BEACH1C V2 整条主线 59935–59950；ITEMICON1B；vmaps/mmaps；联盟线(船 12261)。
- 流放者之岛**部落**线 59926–59950 已提取并分批做完；联盟线只做了数据核对，没有做完。其他零售区域没做过，别把结论直接套用。

## 一、先做台账(不要一上来就写 SQL)
1. 用 `references/scripts/ledger.py` 在任务 ID 区间里列出：标题、前置/后置、发放NPC、交付NPC、种族/职业限制。流放者之岛部落线 ID 在 59926–60100 附近。
2. 台账里每个任务写清：目标类型、要的 NPC/物品、是否有载具/过场/阶段(phase)、本批怎么简化。放在 `台账_流放者之岛部落任务链.md` 这种文件里，改完就更新。
3. 先挑**一批**(3–6 个相邻任务)做；每批用户测通过再下一批。不要一次导入整条链。

## 二、批量提取
- 数据源：本地 `D:\wow12\LoreWalkerTDB\world.sql` 和 `hotfixes.sql`(12.x 的 TrinityCore 风格 dump，表名与 3.3.5 类似但列不同)。
- 工具：`references/scripts/er_lib.py`(读 dump，`rows('表名')` 逐行返回字典)、`sqlrows.py`(解析 INSERT)、`exbatch.py`。
- 用法：`python exbatch.py out.json 59929,59930,59931 额外NPC编号`，输出 json：`quests`(文本/奖励/前后置/发放交付NPC/objectives)、`npcs`(模板、模型、出生点、掉落)、`items`。
- 注意：**脚本里路径(W、H)是我机器上的位置，换机器先改。** 运行 python 时当前目录不要放会遮蔽标准库的同名文件(曾因 `dis.py` 出错)。
- 提取的出生点按坐标去重(零售同一个怪常有多条阶段重复行)。

## 三、把零售机制翻成 3.3.5 能跑的(核心表)
| 零售目标 | 3.3.5 做法 | 状态 |
|---|---|---|
| 杀怪 N 个 | quest_template.RequiredNpcOrGo1/Count1 | 用户测过 |
| 收集物品 | RequiredItemId + 怪物 creature_loot_template(QuestRequired=1) | 用户测过(59929) |
| 对话计数 | 发放/任务NPC 的 gossip hello + `player:KilledMonsterCredit(entry)` | 用户测过 |
| 对NPC使用物品 | item_template 挂使用法术(客户端自带的 746 绷带，spelltrigger 0，spellcharges -1，免改 DBC)；服务端 `RegisterPlayerEvent(5)` 取 spell:GetTarget()，目标是玩家自己(自动自我施法)时改用附近最近且未处理的目标；施法后移除绷带的 60 秒状态 11196 | 用户测过(FIRSTAID1C) |
| 到达某地 | 在目的地放一个营地NPC，交任务代替；或用 Lua 判距离 | 部分(BEACH1C 用交任务，V2 仍待测) |
| 载具/飞行 | `AddTaxiPath` 建路径 + `player:StartTaxi`，坐骑生物外观用客户端自带模型；飞完给计数 | **候选(BOOST1A，未测)** |
| 过场动画 | 客户端小插件 `RebornShipMovie` 用 MovieFrame 播；服务端靠 addon 私聊(WHISPER 给自己)通知跳过 | 动画通过；ESC 跳过为候选 |
| 任务物体(篝火等)的提示 | gameobject_template 的 Data1(GOOBER)=任务ID → 核心对该任务未完成的玩家发闪光；IconName 选光标(Point=钢铁手套的手、Cast=发光手套、Pickup=钱袋、LootAll=多个钱袋、Interact=齿轮；没有“抓取的手”；LootAll 不是手，CAMP1A V1 曾误用)；名字写双语操作提示 | **候选(CAMP1A，未测)** |
| 阶段(phase) | 一律 phaseMask=1 | 用户测过 |
| 变大/变小(缩放器) | 客户端不改，服务端改 DisplayScale 的 Lua 效果 | BEACH1C V2，待测 |

## 四、NPC / 怪物 / 出生点规则
1. **creature guid 必须 < 16,777,215**，用 `SELECT COALESCE(MAX(guid),0) INTO @g FROM creature WHERE guid < @spawn_limit;` 然后 `@g + n`。曾因 88200001 溢出导致 worldserver 启动后自动 Halting(WORLD-SHIP2B-GUID 事故)。
2. 每个用到的 display id 在服务端都要有 `creature_model_info`；没有就看不见(野猪事件)。零售模型没有对应 3.3.5 外观时，先用客户端自带外观做替身(`lookup.py` 按名字找)，要原样外观就走"零售模型导入"(见 find-and-extract 技能和 BOAR1A)。
3. 没有服务端地面数据时 NPC 会下沉掉进海里：给岛生成 `.map`(见 find-and-extract 技能)；临时可设 Flight/Rooted。
4. 躺在地上的伤员：`creature_template_addon.bytes1 = 3`；Lua `SetStandState(0)` 站起，`RegisterEvent` 20 秒后 `SetStandState(3)` 躺回。NPC 外观是全体玩家共用的，任务计数用 Lua 内存表按玩家记录。
5. 假人/靶子：RegenHealth=0，血量倍数 1，否则打不死或回血(V5)。
6. 自己的 creature_template 用 9167xxx 一类自定义编号；零售生物保留零售编号。

## 五、文本与图标
1. 任务/NPC/物品名称一律**中英双语**(`English 中文`)，对话气泡也双语。
2. 数据库列以用户**实际库**为准：曾因 `scale` 列被用户删掉而报错。写 SQL 前对照实际 `quest_template`、`item_template` 列，别照抄零售列。
3. 背包图标由**客户端 Item.dbc → ItemDisplayInfo**决定，不是服务端缓存；新增物品要补 Item.dbc 行(类别/外观)，图标 BLP 必须 DXT1+mips(`blp_dxt1.py`)。
4. 任务 NPC 头上的 !/? 与小地图点：QPOI1A(quest_poi)+QMAP1A 插件；大地图 V2 候选未测。

## 六、交付与验收
- 每批一个 `claudefix_日期_阶段X_V1_...` 文件夹：README(步骤+撤销+未测)、memory.md、tutor.md、SHA256SUMS、SQL/Lua/DBC。改动一律新建 V<N>，不改已交付包。
- 先登记协作说明与共享 DBC 哈希台账(见 coordinate-ai-team-parallel-development)；Item/ItemDisplayInfo、Creature* 与 Codex 共用，先读实装版再加行。
- 验收清单：能接 → 目标计数 → 交付奖励 → 后置任务自动出现 → 重登后状态 → 死亡/复活 → 重启服务端后 NPC 与 Lua 仍生效。用户没测的写"未测"，不继承。

## 已知坑(摘要)
- 服务端先于 Lua 拷贝启动 → Lua 不生效，要 `.reload ale` 或重启。
- 用户的 MPQ 编辑器开着会锁补丁文件，导致"没生效"，实测前先关。
- addon 私聊：LANG_ADDON 只允许队伍/团队/公会/战场/私聊，SAY 会被丢弃。
- 客户端缓存 `Cache\WDB` 不清，物品/NPC 外观改了也看不到。
- 友方法术没选目标会落在自己身上；任何依赖目标的逻辑要处理"目标是玩家自己"。
- 解析 SQL 的 dump 很大，逐行流式读，别整个读进内存(`sqlrows.py` 已是流式)。

## 复用脚本与参考
- `references/scripts/`：`er_lib.py`、`sqlrows.py`、`exbatch.py`、`ledger.py`。
- 相关技能：find-and-extract-retail-resources-for-wotlk(找资源/地图)、port-retail-map-to-custom-client(客户端地图)、audit-and-port-upstream-features(来源与端到端核对)、release-tested-reborn-features(验收后发布)。

## 补充(2026-11-24，SIZER1A/1B，用户确认"可以用了，图标也对了")
- **用户实测通过**：对任务物品挂 746 使用法术，对野猪使用→野猪变大→任务计数；物品用**自定义编号 9178051**，Item.dbc 追加一行(类别12、外观 90551)。
- **踩坑**：同样字段下，零售编号 178051 的物品在客户端始终没有"使用："、点了没反应(客户端 Item.dbc 行与能用的急救包格式完全相同，原因未查明)；换成 9 开头自定义编号立刻正常。**新增任务物品优先用自定义编号**，不要沿用零售编号。
- 用对应的"能用"物品先验证服务端逻辑(急救包 746 点野猪就变大)，可以把问题分成"服务端逻辑/物品记录"两层。
- 野猪变回原大小：不要写死 1.4，变大前先读 `GetScale()` 记住原值再恢复(SIZER1B V2，恢复大小待用户确认)。

## 2026-11-24 用户验收补充(飞行/篝火/缩放器，用户原话："这下对了""好棒这次可以了""可以用了，图标也对了""几秒之后也变回之前的大小了")
- **用户实测通过**：
  - 乘坐飞行侦察(BOOST2A/2B)：GnomeCopter.m2 追加骑手挂点(attachment id 0)，玩家被爪子夹住后背；飞过尸骸群半径(SCOUT_R=70)落地才计数。飞行路线(AddTaxiPath)**没有降落箭头**，不要把它写进验收项。
  - 篝火点击提示(CAMP1A V3)：gameobject_template Data1=任务ID、IconName=Cast(发光手套光标)。
  - 缩放器(SIZER1A V4 / SIZER1B V2)：自定义编号 9178051，使用法术 746，对野猪使用→电光视觉→变大→几秒后变回；变大前用 `GetScale()` 记住原值，恢复该值，不要写死。
- **flight 坑**：改了 creature_template_model 后必须**重启 worldserver**，飞行坐骑外观来自启动时缓存。
- **未测/未查明**：零售编号 178051 为什么没有使用效果(同字段改成 9178051 立刻正常)；电光装饰法术 45935/28136 是否真的可见；BOOST1B(59942)、BEACH1D 后续任务。

## 2026-11-25 部落线收尾(用户原话："这次这个任务链就结束啦"；此前对分支任务："这几个任务 好棒啊 都可以了 通过 测试")
- **整链走完**：59926 起到 59985(奥格瑞玛交任务)。明确确认过：59942 载具、59943–59947 图腾、暗槌外圈、两个分支任务(56839/54933)。深坑 59948/59949、副本内部、落石堵门、巨熊模型、墓地、vmaps 没有逐项单独确认。食人魔变身脚本(DARK1B)在发布时服务端并未实装。
- **计数生物必须真的建出来**：`KilledMonsterCredit(X)` 对应的 `RequiredNpcOrGo` 要有 creature_template + 模型行；否则核心丢掉该目标，任务一接就“完成”。启动后查 Errors.log 里 `does not exist, quest can't be done`。
- **ALE 对话返回值**：hello/select 处理完什么都不返回；`return false` 会让核心继续打开默认问候窗口，盖掉自定义菜单。
- **重跑早期阶段 SQL 会覆盖后续改动**(续接包曾让 59985 回到旧文本)；续接包要么含全部后续改动，要么只做诊断。
- 地图标记：quest_poi 除目标行外要有交任务行(ObjectiveIndex=-1，交任务 NPC 所在地图和 WorldMapArea)；小地图任务物体靠插件。
- AC 3.3.5 没有 `creature_template.InhabitType`，移动方式在 `creature_template_movement`。零售建筑内部没有服务端碰撞时怪会掉到地形上，根治是做 vmaps/mmaps(见 find-and-extract 技能)。
- 头目体型：优先换客户端现有的盔甲高清外观再放大(creature_template_model)，换前确认 creature_model_info 的 combat_reach 非 0。
- 堵出口：先量整个门洞(宽和高)，读 M2 画面与碰撞三角形投影核对覆盖率，落石用 type 0、关闭状态、flags 18。
