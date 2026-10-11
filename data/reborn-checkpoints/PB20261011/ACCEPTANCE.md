# PB20261011 验收记录：PBGRP1A、PBMOVE1A、PBBG1C（mod-playerbots）

- 日期：2026-10-11；负责：Claude（共享区域 `modules/mod-playerbots`，已在协作说明登记）
- 用户确认："PBGRP1A……应该是通过了"；"测试没有崩溃了，也都依次出了战场了"；古达克实测后："提交吧"
- 子模块：wowshub/mod-playerbots `reborn-dcai1a-20261009` `b0f62dc6` → **`11c8ee86120d69c8cff0e015be98eacb032d9c77`**（6 个文件，+218 / −0）
- 主仓库：基于 `f3bc093073fec5ab5f9b937e8563598c2d2a787e`，只更新 gitlink 和本验收记录。发布在单独的 worktree `beascendcode/claude-release-20261011` 完成，日常编译目录未改动。

## 验收范围

| 阶段 | 内容 | 文件 | 测试 |
|---|---|---|---|
| PBGRP1A | 小号机器人上线时你的客户端还在读取界面，队伍框体漏掉了在线更新，显示"未知目标 / OFFLINE"，要 `/reload`。改为最后一个机器人上线 3 秒后、你进入世界时，重发一次队伍列表 | `src/Bot/PlayerbotMgr.h/.cpp` | 用户：重启后组队框体正常，基本通过 |
| PBMOVE1A | 核心找不到导航路径时会改走直线，目的地在另一层时，远程机器人就直线穿过古达克的平台。改为高度差大于 6 码、又不是正常导航路径时，跳过这次移动，并写 `PBMOVE1A:` 日志 | `src/Ai/Base/Actions/MovementActions.h/.cpp` | 古达克 08:44–09:04 全通关、0 死亡、无坠入地图下方；迦尔达拉 173 秒（修复前 1014 秒）；拦截到 1 次 `dungeon clear follow tank` 给出的 z=0 目的地 |
| PBBG1C | 你离开战场后，小号机器人留在战场里。改为按原队伍里的真人判断（离开 5 秒，战斗中最多 15 秒），在 **世界线程** 排队执行 `LeaveBG`（PBBG1B 在战场地图线程直接执行导致崩溃） | `src/Bot/PlayerbotAI.h/.cpp` | 阿拉希盆地：4 个小号（含带宠物的猎人）依次离开，无崩溃；Dvd 在战斗中，15 秒后被强制脱战离开 |

未验证：竞技场；随机机器人的战场行为（只做了观察，未专门回归）；其他多层副本。

## 失败过程（保留）
- PBBG1A：依赖 `master` 判断，实测一直没有触发。
- PBBG1B：判断正确，但在战场地图线程直接 `LeaveBG`，猎人离开时服务器崩溃。`CMSG_LEAVE_BATTLEFIELD` 属于 PROCESS_THREADUNSAFE，必须在世界线程执行。

## 交付包（000Ascendupdate20261011，SHA256SUMS.txt 的 SHA256）
| 包 | 哈希 |
|---|---|
| claudefix_20261011_032849_阶段PBGRP1A_重登后队伍框体刷新 | `74cbf3c8962595816165208a210df1c6d5764a2c9714853f9587c3b2542e0a3c` |
| claudefix_20261011_062300_阶段PBMOVE1A_远程不再穿地板 | `d133c8ecf7ec8f49c008549ba5f3b2754c602bc2394544e1446710e7e280a755` |
| claudefix_20261011_063252_阶段PBGRP1A+PBMOVE1A+PBBG1A_整合包v2 | `f5e6fef661a1f252ae8aac1f3c0b91c048c5b81adec4dda2d4c6fbfeebcda507` |
| claudefix_20261011_075707_阶段PBBG1C_离开战场改在世界线程执行_修崩溃 | `063663bc09766e4947226df936441bd8e3c974fec5a73e8f9178148bf23aaa70` |

## 一致性核对
提交前确认：日常编译目录中 mod-playerbots 只改了这 6 个文件，并且与整合包 v2（PBGRP1A、PBMOVE1A）及 PBBG1C 包逐字节一致；远端分支提交前为 `b0f62dc6`。

## 后续
- DCMOV2A：从根源修复 `dungeon clear follow tank` 地面高度查询失败时给出 z=0 目的地的问题（mod-dungeon-clear）。
- 部署：只需编译 worldserver，无 SQL、无客户端改动。
