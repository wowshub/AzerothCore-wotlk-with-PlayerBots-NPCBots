-- =========================================================================
-- RebornWOW 野外寻宝宝箱系统 (TREAS1B)
-- 阶段: TREAS1B
-- 责任成员: Gemini (包前缀 geminifix_)
-- 文件: 20261013_01_treasure_schema.sql
-- 库: world
-- 作用: 创建野外寻宝核心表结构 (点位表、线索表、领取日志表)
-- 安全机制: 可重入 (IF NOT EXISTS)，不破坏任何现有表结构与数据
-- =========================================================================

-- 1. 寻宝点位与刷新状态表
CREATE TABLE IF NOT EXISTS `reborn_treasure_spawns` (
  `spawn_id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '点位唯一标识',
  `quality` tinyint(3) unsigned NOT NULL DEFAULT '1' COMMENT '品质: 1=普通, 2=稀有, 3=史诗',
  `entry` int(10) unsigned NOT NULL DEFAULT '990200' COMMENT 'GO entry: 990200, 990201, 990202',
  `map` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '地图ID',
  `zone_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '区域ID',
  `position_x` float NOT NULL DEFAULT '0' COMMENT '坐标X',
  `position_y` float NOT NULL DEFAULT '0' COMMENT '坐标Y',
  `position_z` float NOT NULL DEFAULT '0' COMMENT '坐标Z',
  `orientation` float NOT NULL DEFAULT '0' COMMENT '朝向Orientation',
  `respawn_time_min` int(10) unsigned NOT NULL DEFAULT '300' COMMENT '最小刷新时间(秒)',
  `respawn_time_max` int(10) unsigned NOT NULL DEFAULT '600' COMMENT '最大刷新时间(秒)',
  `last_claimed_time` bigint(20) unsigned NOT NULL DEFAULT '0' COMMENT '上次领取Unix时间戳',
  `next_respawn_time` bigint(20) unsigned NOT NULL DEFAULT '0' COMMENT '下次刷新Unix时间戳',
  `is_active` tinyint(3) unsigned NOT NULL DEFAULT '1' COMMENT '点位是否启用: 1=启用, 0=停用',
  `comment` varchar(255) NOT NULL DEFAULT '' COMMENT '点位描述',
  PRIMARY KEY (`spawn_id`),
  KEY `idx_map_active` (`map`,`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='野外寻宝点位与刷新状态表';

-- 2. 寻宝线索表 (支持每个点位独立配置专属线索谜题与触发距离)
CREATE TABLE IF NOT EXISTS `reborn_treasure_clues` (
  `clue_id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '线索唯一标识',
  `spawn_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '关联的点位ID',
  `clue_text` text NOT NULL COMMENT '线索文本/探索提示',
  `min_distance` float NOT NULL DEFAULT '5.0' COMMENT '触发提示最小距离(码)',
  `max_distance` float NOT NULL DEFAULT '45.0' COMMENT '触发提示最大距离(码)',
  `comment` varchar(255) NOT NULL DEFAULT '' COMMENT '备注说明',
  PRIMARY KEY (`clue_id`),
  KEY `idx_spawn_id` (`spawn_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='野外寻宝线索表';

-- 3. 寻宝领取审计日志表 (记录防刷、幂等与补领证据)
CREATE TABLE IF NOT EXISTS `reborn_treasure_claim_log` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '日志ID',
  `spawn_id` int(10) unsigned NOT NULL COMMENT '领取的点位ID',
  `player_guid` int(10) unsigned NOT NULL COMMENT '玩家GUID(Low)',
  `player_name` varchar(50) NOT NULL DEFAULT '' COMMENT '玩家角色名',
  `claim_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '领取时间',
  `reward_money` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '发放铜币总额',
  `reward_items` text NOT NULL COMMENT '发放物品明细',
  `delivery_method` varchar(20) NOT NULL DEFAULT 'DIRECT' COMMENT '发放途径: DIRECT(直接入包) 或 MAIL_BACKUP(背包满邮件安全补发)',
  PRIMARY KEY (`id`),
  KEY `idx_player` (`player_guid`),
  KEY `idx_spawn` (`spawn_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='野外寻宝领取审计日志表';

