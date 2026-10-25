-- =========================================================================
-- RebornWOW 野外寻宝宝箱系统 (TREAS1B)
-- 阶段: TREAS1B
-- 责任成员: Gemini (包前缀 geminifix_)
-- 文件: 20261013_03_treasure_initial_spawns.sql
-- 库: world
-- 作用: 插入初始验证点位 (艾尔文森林 2 处野外点位) 及配套线索
-- 安全机制: 小范围受控配置，不自动批量刷满全地图；可重入安全执行
-- =========================================================================

-- 1. 清理并写入初始测试点位 (Spawn ID 1 与 2)
DELETE FROM `reborn_treasure_spawns` WHERE `spawn_id` IN (1, 2);
INSERT INTO `reborn_treasure_spawns` (
  `spawn_id`, `quality`, `entry`, `map`, `zone_id`,
  `position_x`, `position_y`, `position_z`, `orientation`,
  `respawn_time_min`, `respawn_time_max`, `last_claimed_time`, `next_respawn_time`, `is_active`, `comment`
) VALUES
-- 点位 1: 艾尔文森林 水晶之湖湖畔 (普通品质, Entry 990200, 刷新 300–600 秒)
(1, 1, 990200, 0, 12, -9472.5, -156.4, 58.2, 1.2, 300, 600, 0, UNIX_TIMESTAMP(), 1, '艾尔文森林-水晶之湖湖畔芦苇丛 (普通)'),

-- 点位 2: 艾尔文森林 斯通菲尔德农场果树后方 (稀有品质, Entry 990201, 刷新 600–1200 秒)
(2, 2, 990201, 0, 12, -9728.8, 664.1, 31.8, 3.4, 600, 1200, 0, UNIX_TIMESTAMP(), 1, '艾尔文森林-斯通菲尔德农场果树 (稀有)');

-- 2. 清理并写入初始线索数据
DELETE FROM `reborn_treasure_clues` WHERE `spawn_id` IN (1, 2);
INSERT INTO `reborn_treasure_clues` (`clue_id`, `spawn_id`, `clue_text`, `min_distance`, `max_distance`, `comment`) VALUES
(1, 1, '水晶之湖清澈的水波拍打着岸边，在南侧浅滩的芦苇倒影深处，隐约闪烁着旅行者留下的宝箱微光...', 5.0, 45.0, '水晶之湖湖畔线索'),
(2, 2, '农场老宅后的果树下，泥土混杂着陈旧的木香，仔细观察树根的阴影，似乎埋藏着秘密...', 5.0, 45.0, '斯通菲尔德农场果树线索');

