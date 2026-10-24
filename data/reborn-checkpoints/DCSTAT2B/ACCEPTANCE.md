# DCSTAT2B 批次验收：清本记录补充、准备度和统计里的 NPCBot、魔枢首领数（Claude）

- 日期：2026-10-24。
- 用户原话：「出来了 好棒」（准备度里 NPCBot 巫医卡片）；「名字长度测试都通过」（准备度长名字）；「清本 统计显示 图标了 首领数量也对了 4个 通过」（清本统计）；「都帮我推送吧」。
- 范围：
  - **DCSTAT2A**：清本记录里每位成员的开局装等、职责。实测装等显示。**死因、承伤、治疗量用户没有死过一次验证，未验收。**
  - **DCPREP2A + DCPREP2B**：准备度面板读队伍里每个真人雇的 NPCBot（装等、属性、身上合剂/食物）。2B 修正了 2A 把自己（带真人 AI）排除掉的错误。实测 NPCBot 巫医卡片出现。
  - **DCSTAT2B**：清本统计里 NPCBot 读装等/职责、NPCBot 巫医职业图标（职业号 21）、首领总数只数真首领（魔枢 4/4，不再 4/7）。实测图标和 4/4 通过。
  - **DCPREP2C**：准备度卡片长名字按完整字符截断，悬停显示全名。实测通过。
- **不在范围**：NPCBot 的死因/承伤/治疗量（采集按玩家做，未做）；治疗量数值口径；除魔枢外其他有路点任务的副本（同一修正适用，但未逐个实测）；Details 的 NPCBot 统计插件、野外宝箱（TREAS1B）、幻象崩溃修复（WDCRASH1B）仍待测，没有包含在本次提交里。

## 提交与链条

| 层 | 内容 | 提交 |
|---|---|---|
| 主仓 threemodelcardpro | 5 个服务端文件：DcPlayerRuns.cpp、DcPrepSnapshot.h/.cpp、DungeonClearAddonHook.cpp、DungeonClearChatActions.cpp | 见 Release |
| 插件 mod-dungeon-clear-addon | reborn104 / 105 / 106 / 107 各一次提交 | 见 Release |

链条核对：每个包覆盖前的文件与其 backup_原文件 的哈希（CRLF 归一）一致，依次为 DCSTAT2A → DCPREP2A → DCPREP2B → DCSTAT2B → DCPREP2C；DCSTAT2A 随包带的 DungeonClearStats.lua 与仓库一致（无备份）。

## 边界
- 仅服务端 C++ 和客户端 Lua/TOC，无 SQL、无新文件；用户自行编译部署，MSVC `cl /Zs` 0 错误（含一个旧警告 C4099，非本批）。
- 修正 DCPREP2A 的错误属于同批：已装 2A 而未装 2B 的服务端读不到自己雇的 NPCBot，部署以最终文件为准。
