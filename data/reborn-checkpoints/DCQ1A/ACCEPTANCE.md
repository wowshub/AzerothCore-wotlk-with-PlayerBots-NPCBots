# DCQ1A + DCQ1B 验收记录：连续清本

- 日期：2026-10-12；开发：Claude；验收：用户。
- 用户原话："我选了2个 他自动传送的 中间 打完一个 随机打第二个了 挺好"，随后说"推送吧"。

## 功能
在清本面板勾选多个副本，系统依次自动完成：传送进副本 → 坦克开始清本 → 清完后全队出本并重置（复用 DCRST1A）→ 进入下一个副本。
- 团灭：全队在入口复活重打；同一副本失败 2 次就跳过。
- 每进一个副本前检查：有人背包空位少于 5 格，或有已穿装备耐久低于 20%，就暂停。
- 手动停止清本会暂停队列，"继续"接着打当前副本。
- 英雄难度清完后不重置，直接进入下一个副本。

## 改动
| 批次 | 文件 |
|---|---|
| DCQ1A | 新增 `modules/mod-dungeon-clear/src/DcDungeonQueue.h/.cpp`；`DcActionShared.cpp`（`DisableDungeonClear` 通知队列）；`DungeonClearAddonHook.cpp`（`queue` 子命令）；`DcInstanceReset.h/.cpp`（`IsPending`）；`mod_dungeon_clear_loader.cpp`（注册）。插件 DungeonClear v3.6-reborn16（`DungeonClear.lua`、`Locale.lua`、`DungeonClear.toc`） |
| DCQ1B | `DcDungeonQueue.cpp`、`DcInstanceReset.cpp`：传送途中队长暂时不在世界中，不再当作下线而丢弃队列和重置 |

## 实测证据
**第一次（只装了 DCQ1A）：监狱**
- 清完后传出副本门外，队列停住了。
- 日志只到 `DCRST1A: Jorn moving 5 member(s) out before reset`，之后没有"重置完成"，也没有"重置取消"。
- 原因见上表 DCQ1B 一行，DCQ1B 修复了这个问题。

**第二次（装了 DCQ1A + DCQ1B）：紫罗兰监狱 + 乌特加德之巅**
- 日志完整走通：
  - `queue started with 2` → `entering The Violet Hold (1/2)` → `cleared` → `DCRST1A … moving 5` → `reset instances`；
  - → `entering Utgarde Pinnacle (2/2)` → `cleared` → `reset instances` → `queue finished (2 dungeons)`。
- 紫罗兰监狱：约 08:55～09:10，17 场战斗，0 死亡。
- 乌特加德之巅：约 09:10～09:31，18 场战斗，0 死亡，4 个首领都已入账。

## 未测（保持待测）
- 团灭后复活重打、同一副本连败 2 次跳过。
- 背包或耐久不足时暂停。
- 手动停止后"继续"。
- 英雄难度。
- 传送失败（等级或进本次数限制）时暂停。
- 随机副本队伍改组后的重置（DCRST1A 原有的未测项）。

## 哈希
用户实测源码等于候选包输出（SHA256 前 12 位）：

| 文件 | 来源包 | SHA256 前 12 位 |
|---|---|---|
| `DcDungeonQueue.h` | DCQ1A | 30dd26749bbc |
| `DcDungeonQueue.cpp` | DCQ1B | f327e0a72943 |
| `DcInstanceReset.h` | DCQ1A | 33f5542baf4b |
| `DcInstanceReset.cpp` | DCQ1B | 02c0e4601d0c |
| `DungeonClearAddonHook.cpp` | DCQ1A | 5ca83c067477 |
| `mod_dungeon_clear_loader.cpp` | DCQ1A | 3ba339a4bfe5 |
| `DcActionShared.cpp` | DCQ1A | bae68c7900c4 |

- 基线：`5708223a`，其中 5 个已有文件与 `294b4dc6` 相同，等于候选包输入。
- 候选包：
  - `000Ascendupdate/000Ascendupdate20261012/claudefix_20261012_080000_阶段DCQ1A_连续清本`
  - `000Ascendupdate/000Ascendupdate20261012/claudefix_20261012_084000_阶段DCQ1B_队长传送途中不丢队列`
- 不包含 DCST1A 草稿：未部署，3 个文件仍等于原版。

## 安装
- 新增 .cpp，需要重新运行 CMake 配置后编译 worldserver。无 SQL，无配置改动。
- 客户端：DungeonClear 插件 v3.6-reborn16（Release 附件）。
