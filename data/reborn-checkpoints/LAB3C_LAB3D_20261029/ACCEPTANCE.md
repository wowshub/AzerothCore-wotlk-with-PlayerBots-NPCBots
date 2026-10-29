# LAB3C + LAB3D 验收记录（掉落工坊：时间点）

日期：2026-10-29。验收人：用户（实测），原话"现在测试都通过了"。整理：Claude。基线：wowshub/threemodelcardpro `c3f7dc2600`。

范围：
- LAB3C：时间点（手动 / 自动 / 回退前）、保存当前、查看差异、回到此时间点、删除；配置 `RebornLootLab.Snapshot.AutoMinutes/AutoKeep/AutoKeepDays`；世界线程自动保存；world 库两张表 `reborn_lootlab_snapshot`、`reborn_lootlab_snapshot_row`。
- LAB3D：分页签（我的时间点 / 自动与回退前）、官方原始（编号 0，只读，可查看差异和回到、不可删）、每行差异摘要、"当前状态"行、差异措辞改为"回到后会加入/移除/改为"。
- 客户端 RebornLootLab 2.5.0；服务端 LootLab.cpp；SQL `data/customfixsql/world/lootlab/LAB3C/LAB3C_snapshot_tables.sql`（可重复执行）。

验收环境说明：第一次测试时服务端还是旧版本（窗口停在"读取中…"，聊天框出现"未知的来源类型"），重新编译并重启 worldserver 后通过。

未测/未做：
- 时间点只覆盖"工坊改过的表"，不是整库备份；工坊之外手改的 loot 不在里面。
- 摘要只算最新 40 个点和官方原始，更早的点显示 `?`。
- 大量时间点（上百个）和很大的表（上千行）下的保存/回到耗时未专项测。
- 自动点在长时间运行下的行为（AutoKeep / AutoKeepDays 清理）只测了短时间。

来源包：`claudefix_20261028_270000_阶段LAB3C_掉落工坊时间点`、`claudefix_20261028_280000_阶段LAB3D_时间点分页签与官方原始`。发布目录与 LAB3C backup 统一换行后比对一致（4/4），发布文件取自 LAB3D 包与 LAB3C conf。
