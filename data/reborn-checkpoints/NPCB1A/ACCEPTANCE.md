# NPCB1A 验收记录：playerbot 小号带 NPCBot 下线崩溃

- 日期：2026-10-08；负责：Claude（用户指定，核心共享区域，已登记 协作说明_并行开发.md）
- 基线：`cd20023bc`
- 用户原话：「我测试了 没有再崩溃」
- 测试范围：用插件让雇有 NPCBot（含带宠物的猎人 NPCBot、圣骑士 NPCBot）的 playerbot 小号反复上线/下线，服务器不再崩溃；同期带 NPCBot 打通达克萨隆要塞，未见异常。未做专项回归：PvP、NPCBot 载具、其他召唤物职业。

## 问题
05:47 崩溃（ACCESS_VIOLATION，`ReputationMgr::GetForcedRankIfAny`）：小号下线时 NPCBot 宠物 UnSummon 只进入 remove list，宠物的 `m_creator`（原始 Player*）在主人被删除后悬空；同队 NPCBot 圣骑士刷新队伍光环 → `AnyGroupedUnitInObjectRangeCheck` → `Unit::GetReactionTo` → `pet->GetAffectingPlayer()` 读到已删除的 Player。

## 修改
- `src/server/game/AI/NpcBots/bot_ai.cpp`：`bot_ai::UnsummonCreature` 在 UnSummon 前 `SetCreator(nullptr)`。
- `src/server/game/Entities/Unit/Unit.cpp`：新增 `GetNpcBotCreatorSafe`（NPCBot 宠物经 owner GUID 找到所属 bot，再取 bot 的 creator），`GetAffectingPlayer` 与 `GetCharmerOrOwnerPlayerOrPlayerItself` 使用它。

## 来源
- 交付包：`000Ascendupdate20261008/claudefix_20261008_060228_阶段NPCB1A_NPCBot宠物悬空主人崩溃修复.zip`，SHA256 `2eeac93012cb7f5448993d0fec0e584723b9cc1702926f95b11e029145e187e4`
- 提交前核对：用户源码中两个文件与包内 `01_覆盖到源代码根目录` 逐字节一致。
- 无 SQL、配置、DBC、客户端改动。
