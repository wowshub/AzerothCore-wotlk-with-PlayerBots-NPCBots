# DCRUN20261024B — 熔渣炉终点、统一本局统计视图、NPCBot 巫医图标（Claude）

- 日期：2026-10-23（包与前序记录沿用 20261024 命名）。
- 用户原话：「这次统计效果 好漂亮 颜色和分类都很专业」「测试通过」「你看看这两个都可以通过了 很棒 有承伤 有治疗者的统计」，附闪电大厅测试截图（沃尔坎已击杀 7:22，当前目标艾欧纳尔）。
- 范围：**DCHOL3A**（K81，熔渣炉楼梯）、**DCSTAT1A**（K88，统一本局统计视图）、**DCNPC1A**（NPCBot 巫医邀请图标，无坦克提示）。
- **不在范围**：DCWD1A 法术账本（K87）。该局队内没有巫医，账本没有被真正测到，仍待测；截图里的承伤和治疗者节来自 DCSTAT1A 的现有数据，不是账本。

## 提交与 Release

| 功能 | 仓库 | 提交 | Release |
|---|---|---|---|
| DCHOL3A | 主仓 threemodelcardpro | 590a88f1efa0dd0eccabcc153a958a764272a90e（父 6483ebaa2，Codex 的 NPCBot 巫医提交） | reborn-dchol3a-20261024 |
| DCSTAT1A | 插件 mod-dungeon-clear-addon | a88667d64d10324cc2bfefcb095e9d30ae98c9ad | v3.6-reborn102 |
| DCNPC1A | 插件 | b5fe3378f57b0b2ba2522553e027b742d2d6a334 | v3.6-reborn103 |

远端分支与 tag 目标已用 ls-remote 读回一致，附件 uploaded、非草稿。

## 验证与边界

- DCHOL3A：只有这一段楼梯的实测（沃尔坎之后继续推进）。其他副本终点判定未改。仅服务端 C++，两个文件，无 SQL、无新文件；用户自行编译部署。
- DCSTAT1A：实测外观与折叠通过；清本一侧只有现有数据（成员、首领、死亡），装等/输出/承伤/死亡原因需要服务端记录（S2），未做。
- DCNPC1A：原因由代码核对（NPCBot 巫医内部职业号 21、清本命令只发给带 PlayerbotAI 的坦克），不是服务端日志证实。NPCBot 不能当带队坦克，未改。
- 链条核对：每个包覆盖前文件与其 backup_原文件一致；DCNPC1A 的备份目录漏了 DungeonClearStats.lua（与 DCSTAT1A 同内容，哈希一致），未改已交付包。
