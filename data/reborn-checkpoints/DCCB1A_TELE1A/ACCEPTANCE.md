# DCCB1A + TELE1A 验收记录：清本结束后卡战斗看护、战斗统计补记

- 日期：2026-10-12；开发：Claude；验收：用户（古达克整本实测，06:07～06:20）。
- 用户同意按下述范围发布（TELE1A 实测通过；DCCB1A 已部署、未误触发，实际清除场景未出现）。

## 问题
- 古达克打完最后一个首领后全队一直"战斗中"，不能复活、不能吃喝；同一次迦尔达拉没进 `dc_fights.jsonl`。
- 原因：达卡莱掠夺者（29982）被犀牛甩进水里，够不着人也撤不回，一直挂着全队战斗。清本自带的卡死清除只在清本运行中生效；统计模块要全队脱战才结束一场，于是后面所有战斗并成一场，关服时也不补写。

## 改动
- **DCCB1A** `modules/mod-dungeon-clear/src/Ai/Dungeon/DungeonClear/Util/DcCombatPurge.cpp`：清本结束（打完自动关闭或手动停止）后继续看护 10 分钟；队里有人在战斗中、但没有怪攻击任何队员，持续 15 秒，就调用原有清除（只清登记表允许的怪）。日志 `DCCB1A:`。
- **TELE1A** `modules/mod-reborn-bot-telemetry/src/RebornBotTelemetry.cpp`、`conf/RebornBotTelemetry.conf.dist`：
  - 15 秒无伤害/治疗时每 30 秒记录 `TELE1A:` 持有者行（谁、和哪只怪、距离、血量、高度、是否回位）；
  - 30 秒无伤害/治疗即结束本场（`"endedBy":"idle"`），之后有新伤害/治疗才开新场；
  - 关服补写（控制台关服完整写入；直接关窗口写简化记录，队员行 `"absent":true`）；
  - 每条记录新增 `endedBy`（combat / idle / vanished / shutdown）；
  - 新配置 `BotTelemetry.IdleEndMs = 30000`、`BotTelemetry.HolderLogAfterMs = 15000`（有默认值）。

## 实测证据（古达克，服务器 05:48 启动的程序含两项）
- 17 场战斗、0 死亡、0 团灭；斯拉德兰 104 秒、达卡莱巨像 71 秒、莫拉比 45 秒、迦尔达拉 246 秒（已正常入账）。
- TELE1A 持有者行命中实际原因：`达卡莱掠夺者(29982) … 100% z108` 同时挂住恶魔猎人、Light、Dvd、搞撒（水面以下）。
- 17 条记录 `endedBy` 均为 `combat`。
- 清本运行中的原有清除处理了一条够不着的斯拉德兰毒蛇（29680）。
- DCCB1A：本次清本结束时全队已正常脱战，未触发、无误触发。

## 哈希
- 输出：`DcCombatPurge.cpp` 0811fc345fda61e2…、`RebornBotTelemetry.cpp` 1e8b4387bdefbbcb…、`RebornBotTelemetry.conf.dist` def906d0d21c849c…（= 候选包输出 = 用户实测源码）。
- 基线 `af97b4a348a284907b8d0939dc08963cafed5244` 中三文件等于候选包输入。
- 候选包：`000Ascendupdate/000Ascendupdate20261012/claudefix_20261012_050000_阶段DCCB1A+TELE1A_打完卡战斗与统计补记`。

## 边界
- DCCB1A 的实际清除（清本结束后仍被卡住）尚未遇到，待下次发生时验证；不在登记表里的持有者不会被清除，只会被 TELE1A 记录。
- `idle` 结束与关服补写未实测。
