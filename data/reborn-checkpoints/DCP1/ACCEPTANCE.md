# DCP1（DCP1A + DCP1B）验收记录：机器人战斗统计模块

- 日期：2026-10-08；负责：Claude（DC 线 P1，新增独立模块，对 playerbots 只读）
- 基线：`10d6b316c`（NPCB1A）；模块在 `cd20023bc` 上开发，期间父节点只多了 NPCB1A，无同名文件
- 用户原话（DCP1B 后）：「我跑了python 命令 看到现在按照治疗 TANK统计了 你再看看 如果可以这次修复是可以的」

## 测试范围
- DCP1A：达克萨隆要塞普通 27 场（schema 1）：首领识别（托尔戈/召唤者诺沃斯/暴龙之王爵德）、死亡、装等随换装变化、真人/机器人区分正确。
- DCP1B：岩石大厅普通 26 场（schema 2）：Light（狂暴天赋战士）role=tank、specRole=dps；搞撒开启治疗策略后 role 由 dps 变 heal、HPS 出现；团灭（克莱斯塔卢斯首次、远古法庭事件两次）wipe=true、死亡计数正确。
- 未测：PvP（不统计）、NPCBot 进副本的归属（本次副本无 NPCBot）、`.dc test` 自动测试下的数据、团本。

## 已知边界
- 远古法庭这类事件型首领（打的是小怪波次）记为「小怪xN」，bossName 为空。
- NPCBot 若进副本，其伤害按核心规则算到雇主名下（未单独列出）。
- 治疗为有效治疗，不含吸收盾。

## 来源
- DCP1A：`000Ascendupdate20261008/claudefix_20261008_032725_阶段DCP1A_机器人战斗统计模块.zip` SHA256 `21194de66d934e7fd699f39eda79dafd741ba122f1034ea00ade43742861fcd0`
- DCP1B：`000Ascendupdate20261008/claudefix_20261008_072451_阶段DCP1B_统计按实际策略记职责.zip` SHA256 `cbeaa97e7ad37e5802adda0b7d4a9315daea207297195251188825a797f5355d`
- 提交前核对：源码 `modules/mod-reborn-bot-telemetry` 四个文件与 DCP1B 包逐字节一致；`tools/summarize_fights.py` 取 DCP1B 包版本。
- 运行配置：`configs/modules/RebornBotTelemetry.conf`（默认值即可）；无 SQL、DBC、客户端改动。
