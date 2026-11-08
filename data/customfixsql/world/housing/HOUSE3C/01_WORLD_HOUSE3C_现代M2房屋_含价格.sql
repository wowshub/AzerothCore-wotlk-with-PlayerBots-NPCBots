-- WORLD DATABASE. HOUSE3C: 16 modern (retail) M2 buildings as housing furniture. gameobject_template type 5 + catalog row + price/materials.
-- Needs the matching GameObjectDisplayInfo.dbc (display ids 930001-930016) on the server AND in the client Patch-XA. Check ids are free first.
SET NAMES utf8mb4;

REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200701,5,930001,'Reborn HOUSE3C: 12ph_folk_tent01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10701,9200701,'家园民居帐篷一','Housing folk tent 1','buildings',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200702,5,930002,'Reborn HOUSE3C: 12ph_folk_tent02',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10702,9200702,'家园民居帐篷二','Housing folk tent 2','buildings',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200703,5,930003,'Reborn HOUSE3C: 10ne_nightelf_tent03',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10703,9200703,'暗夜精灵大帐篷','Night elf large tent','buildings',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200704,5,930004,'Reborn HOUSE3C: 6dr_draenei_shed_01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10704,9200704,'德莱尼棚屋','Draenei shed','buildings',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200705,5,930005,'Reborn HOUSE3C: 6dr_draenei_shed_greenhouse_01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10705,9200705,'德莱尼温室棚屋','Draenei greenhouse shed','buildings',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200706,5,930006,'Reborn HOUSE3C: 6dr_draenei_tent',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10706,9200706,'德莱尼帐篷','Draenei tent','buildings',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200707,5,930007,'Reborn HOUSE3C: 7dh_demonhunter_tentmedium01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10707,9200707,'恶魔猎手中型帐篷','Demon hunter medium tent','buildings',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200708,5,930008,'Reborn HOUSE3C: 6hu_jewelcrafting_tent',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10708,9200708,'珠宝匠帐篷','Jewelcrafting tent','buildings',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200709,5,930009,'Reborn HOUSE3C: sherpa_tent_01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10709,9200709,'雪地向导帐篷','Sherpa tent','buildings',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200710,5,930010,'Reborn HOUSE3C: 12ph_light_gazebo01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10710,9200710,'圣光凉亭','Light gazebo','buildings',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200711,5,930011,'Reborn HOUSE3C: 12ph_void_gazebo01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10711,9200711,'虚空凉亭','Void gazebo','buildings',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200712,5,930012,'Reborn HOUSE3C: 12ph_shop_spring_cherryblossom_gazebo01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10712,9200712,'樱花凉亭','Cherry blossom gazebo','buildings',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200713,5,930013,'Reborn HOUSE3C: 10ts_tuskarr_tent01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10713,9200713,'海象人帐篷','Tuskarr tent','buildings',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200714,5,930014,'Reborn HOUSE3C: 12pm_primitive_structure_largetent01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10714,9200714,'原始部落大帐篷','Primitive large tent','buildings',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200715,5,930015,'Reborn HOUSE3C: 12fn_fungarian_structure_tent01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10715,9200715,'菌人帐篷','Fungarian tent','buildings',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200716,5,930016,'Reborn HOUSE3C: 12ve_voidelf_structure_tent02',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10716,9200716,'虚空精灵帐篷','Void elf tent','buildings',1);

INSERT INTO `reborn_housing_recipe` (`catalog_id`,`gold_copper`,`m1_item`,`m1_count`,`m2_item`,`m2_count`,`m3_item`,`m3_count`,`source_zh`,`rarity`,`ways`) VALUES
 (10701, 250000, 2589, 10, 2592, 5, 0, 0, '房屋建筑', 2, 3),
 (10702, 250000, 2589, 10, 2592, 5, 0, 0, '房屋建筑', 2, 3),
 (10703, 400000, 2589, 10, 2592, 5, 0, 0, '房屋建筑', 2, 3),
 (10704, 400000, 2835, 20, 2840, 10, 0, 0, '房屋建筑', 2, 3),
 (10705, 450000, 2835, 20, 2840, 10, 0, 0, '房屋建筑', 2, 3),
 (10706, 250000, 2589, 10, 2592, 5, 0, 0, '房屋建筑', 2, 3),
 (10707, 250000, 2589, 10, 2592, 5, 0, 0, '房屋建筑', 2, 3),
 (10708, 200000, 2589, 10, 2592, 5, 0, 0, '房屋建筑', 2, 3),
 (10709, 200000, 2589, 10, 2592, 5, 0, 0, '房屋建筑', 2, 3),
 (10710, 500000, 2835, 20, 2840, 10, 0, 0, '房屋建筑', 2, 3),
 (10711, 600000, 2835, 20, 2840, 10, 0, 0, '房屋建筑', 2, 3),
 (10712, 500000, 2835, 20, 2840, 10, 0, 0, '房屋建筑', 2, 3),
 (10713, 250000, 2589, 10, 2592, 5, 0, 0, '房屋建筑', 2, 3),
 (10714, 300000, 2589, 10, 2592, 5, 0, 0, '房屋建筑', 2, 3),
 (10715, 300000, 2589, 10, 2592, 5, 0, 0, '房屋建筑', 2, 3),
 (10716, 350000, 2589, 10, 2592, 5, 0, 0, '房屋建筑', 2, 3)
ON DUPLICATE KEY UPDATE `gold_copper`=VALUES(`gold_copper`),`m1_item`=VALUES(`m1_item`),`m1_count`=VALUES(`m1_count`),`m2_item`=VALUES(`m2_item`),`m2_count`=VALUES(`m2_count`),`source_zh`=VALUES(`source_zh`),`rarity`=VALUES(`rarity`),`ways`=VALUES(`ways`);
