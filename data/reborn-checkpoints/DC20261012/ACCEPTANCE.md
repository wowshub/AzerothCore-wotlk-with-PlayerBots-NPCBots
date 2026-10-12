# DC20261012 验收记录：清本上游合并、一键重置、斯拉德兰打法、队伍名字刷新、地图缩放

- 日期：2026-10-12；开发：Claude；验收：用户。
- 发布范围：DCUP1A、DCRST1A、DCGD1A、PBGRP1B、MAPRS1A/1B。日常源码中同时存在的 Codex WD139B/WD139C（巫医）**未验收，不在本次发布内**；本次提交只用各候选包的输出文件，在隔离发布目录组装。

## 各项

| 编号 | 内容 | 位置 | 用户验收 |
|---|---|---|---|
| DCUP1A | 合并 jrad7/mod-dungeon-clear `07f8e33c8676bfc821fdbbadd68be3a25db63ba3`（13 个提交：DPS 等仇恨、坦克接战、被动回收修复、自动补吃喝策略、旧目标状态清理、斯坦索姆/黑色沼泽修复、Pull Lab、playerbots 配置名兼容）。冲突 1 处（`DcTestRunManager.h` 引用，两边保留）；适配 1 处（`DcLabInject.cpp` 的 `MoveKnockbackFrom` 4/5 参数） | `modules/mod-dungeon-clear`（改 79、增 68） | 古达克整本顺利，4 首领 0 团灭 |
| DCRST1A | 清本面板「重置副本」：检查 → 随机副本队伍改为普通队伍 → 全队传出 → 全员出本后重置（世界线程） | `modules/mod-dungeon-clear/src/DcInstanceReset.h/.cpp`、`DungeonClearAddonHook.cpp`、`mod_dungeon_clear_loader.cpp`；插件见 mod-dungeon-clear-addon v3.6-reborn15 | **普通队伍路径通过**（日志 `DCRST1A: Jorn moving 5 member(s) out before reset` → `reset instances`）；**随机副本队伍改组路径未测** |
| DCGD1A | 斯拉德兰打法，移植 mod-playerbots `86d0f48265da6386c9279ab106023ae4cea18392`（#2733） | 子模块 `modules/mod-playerbots` → `fb5017f14258ced801eb9a9a11b1b7a9046815b5` | 之前 5 次团灭（含旧版程序对照，排除 DCUP1A）；装上后斯拉德兰 55 秒 0 死亡 |
| PBGRP1B | 机器人上线后主动推送队员名字 | 同上子模块（`d5db6eb4`） | 叫机器人上线后名字立即显示，不需 /reload |
| MAPRS1A/1B | 小窗口世界地图右下角拖动缩放（插件 RebornWorldMapResize 1.0.1） | `data/reborn-client/Interface/AddOns/RebornWorldMapResize` | 拖动可用，1B 拖动角清晰可见 |

## 候选包（原包保留不改）
- `000Ascendupdate/000Ascendupdate20261011/claudefix_20261011_204500_阶段DCUP1A_合并清本上游13提交`
- `000Ascendupdate/000Ascendupdate20261011/claudefix_20261011_224000_阶段DCRST1A_一键重置副本`
- `000Ascendupdate/000Ascendupdate20261012/claudefix_20261012_020000_阶段DCGD1A_斯拉德兰打法移植上游2733`
- `000Ascendupdate/000Ascendupdate20261011/claudefix_20261011_213000_阶段PBGRP1B_队伍框体名字随机器人上线刷新`
- `000Ascendupdate/000Ascendupdate20261012/claudefix_20261012_023000_阶段MAPRS1A_小地图窗口拖动缩放`、`…_030000_阶段MAPRS1B_拖动角更醒目`

## 核对
- 发布基线 `fa5a5f31`（DCMOV2A）。DCUP1A 147 个文件在基线中的哈希逐一等于包登记的输入；DCRST1A 两个修改文件的基线等于 DCUP1A 输出。
- 暂存清单与各包文件清单逐行一致（153 项），不含巫医文件。
- 子模块两项提交的原文件与 `11c8ee86` 逐一一致。
- 语法检查：清本模块全部 207 个源文件、DCRST1A 3 个文件、古达克 5 个源文件 + 3 个注册文件 MSVC `cl /Zs` 0 错误；插件 Lua 5.1 编译通过。完整编译由用户完成并实测。

## 部署
- 服务端：安装后**须重新运行 CMake 配置**（新增 `src/Lab`、`src/Util`、`DcInstanceReset.cpp`），再编译。
- 客户端：DungeonClear 插件 v3.6-reborn15、RebornWorldMapResize 1.0.1（见 Release 附件）。
- 无 SQL、无 DBC。

## 边界
- 只在古达克普通难度验证；斯坦索姆、黑色沼泽等上游修复的副本未专项测试。
- DCRST1A 随机副本队伍自动改组、队里有其他真人或 NpcBots 时的拒绝路径未实测。
- 打完副本"一直处于战斗中"（古达克掉水的达卡莱袭击者）本次未复现，仍待 DCCB1A。
