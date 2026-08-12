-- A.22.7: NPC 750002 and future level-one Death Knights share one route table.
CREATE TABLE IF NOT EXISTS `spelldraft_starting_zone` (
  `team` TINYINT UNSIGNED NOT NULL COMMENT '0=Alliance,1=Horde',
  `slot` TINYINT UNSIGNED NOT NULL COMMENT 'UI order within faction',
  `route_key` VARCHAR(40) NOT NULL,
  `name_en` VARCHAR(80) NOT NULL,
  `name_zh` VARCHAR(80) NOT NULL,
  `map_id` SMALLINT UNSIGNED NOT NULL,
  `position_x` FLOAT NOT NULL,
  `position_y` FLOAT NOT NULL,
  `position_z` FLOAT NOT NULL,
  `orientation` FLOAT NOT NULL DEFAULT 0,
  `image_path` VARCHAR(160) NOT NULL,
  `enabled` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `source_npc` INT UNSIGNED NOT NULL DEFAULT 750002,
  PRIMARY KEY (`team`, `slot`),
  UNIQUE KEY `uq_spelldraft_start_route` (`route_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Validated starting zones shared with NPC 750002';

INSERT INTO `spelldraft_starting_zone`
(`team`,`slot`,`route_key`,`name_en`,`name_zh`,`map_id`,`position_x`,`position_y`,`position_z`,`orientation`,`image_path`,`enabled`) VALUES
(0,1,'alliance_human','Human','人类',0,-8949.95,-132.493,83.5312,0,'Interface\\Buttons\\Northshire_Valley',1),
(0,2,'alliance_dwarf_gnome','Dwarf Gnome','矮人／侏儒',0,-6240.32,331.033,382.758,6.1,'Interface\\Buttons\\Coldridge_Valley',1),
(0,3,'alliance_night_elf','Night Elf','暗夜精灵',1,10311.3,832.463,1326.41,5.6,'Interface\\Buttons\\Shadowglen',1),
(0,4,'alliance_draenei','Draenei','德莱尼',530,-3961.64,-13931.2,100.615,2,'Interface\\Buttons\\Ammen_Vale',1),
(0,5,'alliance_worgen','Worgen','狼人',0,-1447.13,1407.73,35.556,0,'Interface\\Buttons\\Worgen_Gilneas',1),
(0,6,'alliance_void_elf','Void Elf','虚空精灵',10010,3652.77,1021.45338,13.3724165,0,'Interface\\Buttons\\Void_Elf',1),
(0,7,'alliance_high_elf','High Elf','高等精灵',10010,5098.649,-603.823,18.6165885,0,'Interface\\Buttons\\High_Elf',1),
(0,8,'alliance_lightforged','Lightforged Draenei','光铸德莱尼',10010,4376.8174,124.05848,0.70686644,0,'Interface\\Buttons\\Lightforged_Draenei',1),
(0,9,'alliance_demon_hunter','Demon Hunter Alliance','联盟恶魔猎手',0,-8881.176,1059.9805,105.70616,0,'Interface\\Buttons\\Demon_Hunter_Alliance',1),
(0,10,'alliance_pandaren','Pandaren Alliance','联盟熊猫人',10002,292.83646,-936.40204,102.698044,0,'Interface\\Buttons\\Pandaren_Alliance',1),
(0,11,'alliance_dark_iron','Dark Iron Dwarf','黑铁矮人',0,-7402.4277,291.20493,286.2949,0,'Interface\\Buttons\\Dark_Iron_Dwarf',1),
(0,12,'alliance_dracthyr','Dracthyr','龙希尔',3,-282.8949,-30.559977,450.49158,0,'Interface\\Buttons\\Dracthyr',1),
(1,1,'horde_orc_troll','Orc Troll','兽人／巨魔',1,-618.518,-4251.67,38.718,0,'Interface\\Buttons\\Valley_of_Trials',1),
(1,2,'horde_undead','Undead','亡灵',0,1676.71,1678.31,121.67,2.70526,'Interface\\Buttons\\Deathknell',1),
(1,3,'horde_tauren','Tauren','牛头人',1,-2917.58,-257.98,52.9968,0,'Interface\\Buttons\\Red_Cloud_Mesa',1),
(1,4,'horde_blood_elf','Blood Elf','血精灵',530,10349.6,-6357.29,33.4026,5.31605,'Interface\\Buttons\\Sunstrider_Isle',1),
(1,5,'horde_goblin','Goblin','地精',10000,590.5265,4807.36,3.53213,0,'Interface\\Buttons\\Goblin',1),
(1,6,'horde_vulpera','Vulpera','狐人',10012,-2151.8108,-454.82339,112.88782,0,'Interface\\Buttons\\Vulpera',1),
(1,7,'horde_pandaren','Pandaren Horde','部落熊猫人',10002,-826.33221,724.07113,20.017347,0,'Interface\\Buttons\\Pandaren_Horde',1),
(1,8,'horde_eredar','Eredar','艾瑞达',10000,1422.1322,3219.6353,25.355162,0,'Interface\\Buttons\\Eredar',1),
(1,9,'horde_zandalari','Zandalari Troll','赞达拉巨魔',10012,-8.498111,-944.57214,78.487915,0,'Interface\\Buttons\\Zandalari_Troll',1),
(1,10,'horde_demon_hunter','Demon Hunter Horde','部落恶魔猎手',0,4332.541,-2881.9714,0.90824634,0,'Interface\\Buttons\\Demon_Hunter_Horde',1),
(1,11,'horde_nightborne','Nightborne','夜之子',10000,1724.2849,4818.5576,6.791372,0,'Interface\\Buttons\\Nightborne',1),
(1,12,'horde_naga','Naga','娜迦',10001,-50.659386,-396.765338,-61.372284,0,'Interface\\Buttons\\Naga',1)
ON DUPLICATE KEY UPDATE
  `route_key`=VALUES(`route_key`), `name_en`=VALUES(`name_en`), `name_zh`=VALUES(`name_zh`),
  `map_id`=VALUES(`map_id`), `position_x`=VALUES(`position_x`), `position_y`=VALUES(`position_y`),
  `position_z`=VALUES(`position_z`), `orientation`=VALUES(`orientation`),
  `image_path`=VALUES(`image_path`), `enabled`=VALUES(`enabled`), `source_npc`=750002;

-- Only new races need an explicit override. The original ten races continue
-- to use their native playercreateinfo level-one position.
CREATE TABLE IF NOT EXISTS `spelldraft_race_start_route` (
  `race_id` TINYINT UNSIGNED NOT NULL,
  `team` TINYINT UNSIGNED NOT NULL COMMENT '0=Alliance,1=Horde',
  `slot` TINYINT UNSIGNED NOT NULL COMMENT 'Matching NPC 750002 button',
  `enabled` TINYINT UNSIGNED NOT NULL DEFAULT 1,
  `note` VARCHAR(80) NOT NULL,
  PRIMARY KEY (`race_id`),
  KEY `idx_spelldraft_race_route` (`team`,`slot`),
  CONSTRAINT `fk_spelldraft_race_route_zone`
    FOREIGN KEY (`team`,`slot`) REFERENCES `spelldraft_starting_zone` (`team`,`slot`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT INTO `spelldraft_race_start_route` (`race_id`,`team`,`slot`,`enabled`,`note`) VALUES
(9,1,5,1,'Goblin'),
(12,0,6,1,'Void Elf'),
(13,1,6,1,'Vulpera'),
(14,0,7,1,'High Elf'),
(15,1,7,1,'Pandaren Horde'),
(16,0,5,1,'Worgen'),
(17,1,8,1,'Eredar'),
(18,1,9,1,'Zandalari Troll'),
(19,0,8,1,'Lightforged Draenei'),
(20,0,9,1,'Demon Hunter Alliance'),
(21,1,10,1,'Demon Hunter Horde'),
(22,0,10,1,'Pandaren Alliance'),
(23,1,11,1,'Nightborne'),
(25,1,12,1,'Naga'),
(26,0,11,1,'Dark Iron Dwarf'),
(27,0,12,1,'Dracthyr')
ON DUPLICATE KEY UPDATE
  `team`=VALUES(`team`), `slot`=VALUES(`slot`), `enabled`=VALUES(`enabled`), `note`=VALUES(`note`);
