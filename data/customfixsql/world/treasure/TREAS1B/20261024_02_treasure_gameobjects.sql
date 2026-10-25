-- =========================================================================
-- RebornWOW 野外寻宝宝箱 (TREAS1B, 审核整合 Claude)
-- 库: world
-- 修正 TREAS1A 的 gameobject_template:
--   * 宝箱(type 3)的 Data0 是 lockId, Data1 才是 lootId。TREAS1A 把 990200 写进了 Data0,
--     等于指向一个不存在的锁; 这里两项都置 0 (无锁、无原生掉落), 奖励完全由模块发放。
--   * 去掉 TREAS1A 里不存在的 faction/flags 两列 (本核心的 gameobject_template 没有这两列, TREAS1A 的 SQL 会直接报 Unknown column)。
--   * 删除不被任何代码使用的 gameobject_loot_template 行, 避免与模块奖励重复或误导。
-- 可重复执行; 已导入过 TREAS1A 的库直接执行本文件即可覆盖旧值。
-- DisplayID 201 / 1581 / 3248 沿用 TREAS1A, 未在客户端核对过外观, 见 README。
-- =========================================================================

DELETE FROM `gameobject_template` WHERE `entry` IN (990200, 990201, 990202);
INSERT INTO `gameobject_template` (
  `entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`,
  `Data0`, `Data1`, `Data2`, `Data3`, `Data4`, `Data5`, `Data6`, `Data7`, `Data8`, `Data9`, `Data10`,
  `Data11`, `Data12`, `Data13`, `Data14`, `Data15`, `Data16`, `Data17`, `Data18`, `Data19`, `Data20`,
  `Data21`, `Data22`, `Data23`, `AIName`, `ScriptName`
) VALUES
(990200, 3, 201,  '野外寻宝宝箱 (普通)', 'Chest', '', '', 1.0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 'go_reborn_treasure_chest'),
(990201, 3, 1581, '野外寻宝宝箱 (稀有)', 'Chest', '', '', 1.2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 'go_reborn_treasure_chest'),
(990202, 3, 3248, '野外寻宝宝箱 (史诗)', 'Chest', '', '', 1.4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '', 'go_reborn_treasure_chest');

DELETE FROM `gameobject_loot_template` WHERE `Entry` IN (990200, 990201, 990202);
