# LFG81A 验收记录：超过 80 级可以排随机本和指定本（含 LFGFIX1A）

- 日期：2026-10-12；开发：Claude；验收：用户。
- 用户原话："我测试随机本80级以上也可以排了 指定本也可以"。

## 问题
本服 `MaxPlayerLevel = 255`。81 级角色在地下城查找器中，巫妖王之怒普通本提示"级别太高"，随机本也排不了；走进副本、排战场都正常。

## 改动
1. **`src/server/game/DungeonFinding/LFGMgr.cpp` `GetRandomAndSeasonalDungeons`（LFG81A）**：开关 `DungeonAccessRequirements.LFGLevelDBCOverride` 打开时，DBC 等级上限达到 `DEFAULT_MAX_LEVEL`（80）的随机入口对更高等级开放；上限 60/70 的经典、燃烧的远征随机入口不变。
2. **同文件 `JoinLfg` 开头（LFGFIX1A，2026-10-09 候选）**：满员随机本队伍已无人留在原副本时，按"已完成"处理，可以重新排队，不必解散重组。它从 10-09 起存在于用户编译的每一版程序中，本次随 LFG81A **组合测试**（用户今天全队排随机本正常）。
3. **运行配置**（不在仓库内，用户服务器 `configs/worldserver.conf`）：`DungeonAccessRequirements.LFGLevelDBCOverride = 1`。打开后指定副本的等级判断读取 `dungeon_access_template`；已核对诺森德全部 5 人本 `max_level = 0`（不限）。`worldserver.conf.dist` 默认值保持 0。

## 哈希
- 输出 `40b56f1f88f52cbfe5b859f504b30c4b68ae95d3322279f1ada27081621b73cb`（= 候选包输出 = 用户实测源码）。
- 发布基线 `a2c79eb79e0d902bb0306235552dca34048f57d5` 中该文件为 `ae8cade7…`；差异只有上述两处。
- 候选包：`000Ascendupdate/000Ascendupdate20261012/claudefix_20261012_040000_阶段LFG81A_超80级可排随机本与指定本`。

## 检查
- MSVC `cl /Zs` 语法检查 0 错误；用户完整编译并实测。

## 边界
- 只解决"能否排队/进入"。高于 80 级进 80 级副本，怪物不缩放；按等级缩放属于"弹性副本"设计（未开发）。
- 未专项测试：英雄随机本的装等要求、经典/燃烧的远征副本的指定排队、多名 81+ 成员混编。
