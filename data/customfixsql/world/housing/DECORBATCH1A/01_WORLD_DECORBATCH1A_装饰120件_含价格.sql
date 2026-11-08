-- WORLD DATABASE. DECORBATCH1A: 120 modern (retail) M2 decor pieces as housing furniture (lighting/accents/nature/structure/functional/misc).
-- Needs GameObjectDisplayInfo.dbc with display ids 940001-940120 on the server AND in the client Patch-XA.
SET NAMES utf8mb4;

REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200801,5,940001,'Reborn DECORBATCH1A: 12ph_be_legacy_candelabra02',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10801,9200801,'家园烛台2','12ph_be_legacy_candelabra02','lighting',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200802,5,940002,'Reborn DECORBATCH1A: 12be_bloodelf_lighting_candelabra02',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10802,9200802,'血精灵烛台2','12be_bloodelf_lighting_candelabra02','lighting',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200803,5,940003,'Reborn DECORBATCH1A: 12fn_fungarian_lighting_brazier01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10803,9200803,'菌人火盆1A','12fn_fungarian_lighting_brazier01','lighting',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200804,5,940004,'Reborn DECORBATCH1A: 12pm_primitive_lighting_bonfire01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10804,9200804,'原始部落篝火1A','12pm_primitive_lighting_bonfire01','lighting',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200805,5,940005,'Reborn DECORBATCH1A: 12tr_amani_defense_territorymarker_withcandle01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10805,9200805,'阿曼尼巨魔蜡烛1A','12tr_amani_defense_territorymarker_withcandle01','lighting',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200806,5,940006,'Reborn DECORBATCH1A: 12tb_twilightsblade_decor_brazier03',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10806,9200806,'暮光之刃火盆3','12tb_twilightsblade_decor_brazier03','lighting',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200807,5,940007,'Reborn DECORBATCH1A: 12vd_void_lighting_brazier01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10807,9200807,'虚空火盆1','12vd_void_lighting_brazier01','lighting',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200808,5,940008,'Reborn DECORBATCH1A: 12ve_voidelf_lighting_brazier01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10808,9200808,'虚空精灵火盆1','12ve_voidelf_lighting_brazier01','lighting',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200809,5,940009,'Reborn DECORBATCH1A: 12we_wildelf_light01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10809,9200809,'野性精灵装饰1','12we_wildelf_light01','lighting',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200810,5,940010,'Reborn DECORBATCH1A: 12ph_bloodelf_decor_glasslamp01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10810,9200810,'家园玻璃灯1','12ph_bloodelf_decor_glasslamp01','lighting',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200811,5,940011,'Reborn DECORBATCH1A: 12be_bloodelf_lighting_candelabra03',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10811,9200811,'血精灵烛台3','12be_bloodelf_lighting_candelabra03','lighting',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200812,5,940012,'Reborn DECORBATCH1A: 12fn_fungarian_lighting_brazier01_unlit',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10812,9200812,'菌人火盆1B','12fn_fungarian_lighting_brazier01_unlit','lighting',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200813,5,940013,'Reborn DECORBATCH1A: 12pm_primitive_lighting_bonfire01_unlit',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10813,9200813,'原始部落篝火1B','12pm_primitive_lighting_bonfire01_unlit','lighting',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200814,5,940014,'Reborn DECORBATCH1A: 12tr_amani_lighting_candle01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10814,9200814,'阿曼尼巨魔蜡烛1B','12tr_amani_lighting_candle01','lighting',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200815,5,940015,'Reborn DECORBATCH1A: 12vd_void_lighting_smalllight01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10815,9200815,'虚空装饰1A','12vd_void_lighting_smalllight01','lighting',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200816,5,940016,'Reborn DECORBATCH1A: 12ve_voidelf_lighting_campfire01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10816,9200816,'虚空精灵装饰1A','12ve_voidelf_lighting_campfire01','lighting',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200817,5,940017,'Reborn DECORBATCH1A: 12ph_dr_legacy_lantern02',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10817,9200817,'家园灯笼2','12ph_dr_legacy_lantern02','lighting',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200818,5,940018,'Reborn DECORBATCH1A: 12be_bloodelf_lighting_candle02',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10818,9200818,'血精灵蜡烛2','12be_bloodelf_lighting_candle02','lighting',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200819,5,940019,'Reborn DECORBATCH1A: 12fn_fungarian_lighting_hanginglight01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10819,9200819,'菌人装饰1A','12fn_fungarian_lighting_hanginglight01','lighting',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200820,5,940020,'Reborn DECORBATCH1A: 12pm_primitive_lighting_brazier01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10820,9200820,'原始部落火盆1','12pm_primitive_lighting_brazier01','lighting',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200821,5,940021,'Reborn DECORBATCH1A: 12ph_bloodelf_decor_book04',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10821,9200821,'家园书4','12ph_bloodelf_decor_book04','accents',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200822,5,940022,'Reborn DECORBATCH1A: 12al_armyoflight_decor_banner01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10822,9200822,'光之军团旗帜1','12al_armyoflight_decor_banner01','accents',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200823,5,940023,'Reborn DECORBATCH1A: 12be_bloodelf_decor_painting01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10823,9200823,'血精灵画1','12be_bloodelf_decor_painting01','accents',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200824,5,940024,'Reborn DECORBATCH1A: 12fn_fungarian_decor_banner01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10824,9200824,'菌人旗帜1','12fn_fungarian_decor_banner01','accents',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200825,5,940025,'Reborn DECORBATCH1A: 12pm_primitive_defense_banner01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10825,9200825,'原始部落旗帜1','12pm_primitive_defense_banner01','accents',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200826,5,940026,'Reborn DECORBATCH1A: 12tr_amani_cooking_mug01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10826,9200826,'阿曼尼巨魔杯子1','12tr_amani_cooking_mug01','accents',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200827,5,940027,'Reborn DECORBATCH1A: 12vd_void_decor_banner01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10827,9200827,'虚空旗帜1','12vd_void_decor_banner01','accents',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200828,5,940028,'Reborn DECORBATCH1A: 12ve_voidelf_decor_banner01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10828,9200828,'虚空精灵旗帜1','12ve_voidelf_decor_banner01','accents',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200829,5,940029,'Reborn DECORBATCH1A: 12ph_bloodelf_food_cake01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10829,9200829,'家园蛋糕1','12ph_bloodelf_food_cake01','accents',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200830,5,940030,'Reborn DECORBATCH1A: 12al_armyoflight_decor_tatteredflag01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10830,9200830,'光之军团旗1','12al_armyoflight_decor_tatteredflag01','accents',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200831,5,940031,'Reborn DECORBATCH1A: 12be_bloodelf_decor_painting02',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10831,9200831,'血精灵画2','12be_bloodelf_decor_painting02','accents',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200832,5,940032,'Reborn DECORBATCH1A: 12fn_fungarian_decor_banner02',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10832,9200832,'菌人旗帜2','12fn_fungarian_decor_banner02','accents',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200833,5,940033,'Reborn DECORBATCH1A: 12pm_primitive_defense_banner02',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10833,9200833,'原始部落旗帜2','12pm_primitive_defense_banner02','accents',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200834,5,940034,'Reborn DECORBATCH1A: 12tr_amani_cooking_mug02',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10834,9200834,'阿曼尼巨魔杯子2','12tr_amani_cooking_mug02','accents',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200835,5,940035,'Reborn DECORBATCH1A: 12ve_voidelf_decor_floatingtome01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10835,9200835,'虚空精灵魔法书1','12ve_voidelf_decor_floatingtome01','accents',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200836,5,940036,'Reborn DECORBATCH1A: 12ph_demonhunter_banner04',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10836,9200836,'家园旗帜4','12ph_demonhunter_banner04','accents',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200837,5,940037,'Reborn DECORBATCH1A: 12be_bloodelf_decor_wallart04',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10837,9200837,'血精灵墙饰4','12be_bloodelf_decor_wallart04','accents',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200838,5,940038,'Reborn DECORBATCH1A: 12fn_fungarian_food_planter01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10838,9200838,'菌人食物1','12fn_fungarian_food_planter01','accents',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200839,5,940039,'Reborn DECORBATCH1A: 12tr_amani_decor_animaltrophy01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10839,9200839,'阿曼尼巨魔奖杯1','12tr_amani_decor_animaltrophy01','accents',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200840,5,940040,'Reborn DECORBATCH1A: 12ph_demonhunter_lorebook01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10840,9200840,'家园书1','12ph_demonhunter_lorebook01','accents',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200841,5,940041,'Reborn DECORBATCH1A: 12ph_durotar_decor_planter01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10841,9200841,'家园花盆1A','12ph_durotar_decor_planter01','nature',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200842,5,940042,'Reborn DECORBATCH1A: 12be_bloodelf_decor_planterfloating01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10842,9200842,'血精灵花盆1','12be_bloodelf_decor_planterfloating01','nature',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200843,5,940043,'Reborn DECORBATCH1A: 12dur_durotar_azshara_plant_blueberry_a01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10843,9200843,'杜隆塔尔植物1A','12dur_durotar_azshara_plant_blueberry_a01','nature',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200844,5,940044,'Reborn DECORBATCH1A: 12elw_elwynn_autumn_plant_flowerbush_b02',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10844,9200844,'艾尔文花2','12elw_elwynn_autumn_plant_flowerbush_b02','nature',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200845,5,940045,'Reborn DECORBATCH1A: 12esw_lightbloom_plant_lilypad_a02',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10845,9200845,'永歌森林植物2','12esw_lightbloom_plant_lilypad_a02','nature',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200846,5,940046,'Reborn DECORBATCH1A: 12rtl_bioluminescent_plant_pancakemushroom_c03',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10846,9200846,'根须之地蘑菇3','12rtl_bioluminescent_plant_pancakemushroom_c03','nature',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200847,5,940047,'Reborn DECORBATCH1A: 12zam_main_plant_ivy_c01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10847,9200847,'沼泽常春藤1','12zam_main_plant_ivy_c01','nature',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200848,5,940048,'Reborn DECORBATCH1A: 12vdl_arid_plant_glowshrub_a03',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10848,9200848,'虚空植物3','12vdl_arid_plant_glowshrub_a03','nature',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200849,5,940049,'Reborn DECORBATCH1A: 12ph_elwynn_decor_planter01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10849,9200849,'家园花盆1B','12ph_elwynn_decor_planter01','nature',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200850,5,940050,'Reborn DECORBATCH1A: 12be_bloodelf_decor_planterfloating03',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10850,9200850,'血精灵花盆3','12be_bloodelf_decor_planterfloating03','nature',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200851,5,940051,'Reborn DECORBATCH1A: 12dur_durotar_azshara_plant_blueberry_b01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10851,9200851,'杜隆塔尔植物1B','12dur_durotar_azshara_plant_blueberry_b01','nature',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200852,5,940052,'Reborn DECORBATCH1A: 12elw_elwynn_autumn_plant_flowerrose_d01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10852,9200852,'艾尔文花1','12elw_elwynn_autumn_plant_flowerrose_d01','nature',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200853,5,940053,'Reborn DECORBATCH1A: 12esw_main_tree_cypressred_a02',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10853,9200853,'永歌森林树2','12esw_main_tree_cypressred_a02','nature',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200854,5,940054,'Reborn DECORBATCH1A: 12zam_main_plant_shaggymushroom_b03',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10854,9200854,'沼泽蘑菇3','12zam_main_plant_shaggymushroom_b03','nature',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200855,5,940055,'Reborn DECORBATCH1A: 12vdl_arid_plant_voidfingers_b01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10855,9200855,'虚空植物1','12vdl_arid_plant_voidfingers_b01','nature',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200856,5,940056,'Reborn DECORBATCH1A: 12ph_elwynn_decor_planter02',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10856,9200856,'家园花盆2','12ph_elwynn_decor_planter02','nature',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200857,5,940057,'Reborn DECORBATCH1A: 12be_bloodelf_smalltree_17',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10857,9200857,'血精灵树17','12be_bloodelf_smalltree_17','nature',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200858,5,940058,'Reborn DECORBATCH1A: 12dur_durotar_azshara_plant_blueberry_c01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10858,9200858,'杜隆塔尔植物1C','12dur_durotar_azshara_plant_blueberry_c01','nature',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200859,5,940059,'Reborn DECORBATCH1A: 12elw_elwynn_autumn_plant_grass_b02',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10859,9200859,'艾尔文草2','12elw_elwynn_autumn_plant_grass_b02','nature',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200860,5,940060,'Reborn DECORBATCH1A: 12zam_swamp_plant_pineappleaccent_b02',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10860,9200860,'沼泽植物2','12zam_swamp_plant_pineappleaccent_b02','nature',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200861,5,940061,'Reborn DECORBATCH1A: 12ph_bloodelf_door01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10861,9200861,'家园门1','12ph_bloodelf_door01','structure',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200862,5,940062,'Reborn DECORBATCH1A: 12be_bloodelf_navigation_fence01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10862,9200862,'血精灵围栏1A','12be_bloodelf_navigation_fence01','structure',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200863,5,940063,'Reborn DECORBATCH1A: 12fn_fungarian_navigation_fence01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10863,9200863,'菌人围栏1','12fn_fungarian_navigation_fence01','structure',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200864,5,940064,'Reborn DECORBATCH1A: 12tr_amani_navigation_fence03',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10864,9200864,'阿曼尼巨魔围栏3','12tr_amani_navigation_fence03','structure',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200865,5,940065,'Reborn DECORBATCH1A: 12ph_bloodelf_ibe01_platform_beam',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10865,9200865,'家园横梁1','12ph_bloodelf_ibe01_platform_beam','structure',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200866,5,940066,'Reborn DECORBATCH1A: 12be_bloodelf_navigation_fencecapper01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10866,9200866,'血精灵围栏1B','12be_bloodelf_navigation_fencecapper01','structure',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200867,5,940067,'Reborn DECORBATCH1A: 12fn_fungarian_navigation_fence02',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10867,9200867,'菌人围栏2','12fn_fungarian_navigation_fence02','structure',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200868,5,940068,'Reborn DECORBATCH1A: 12tr_amani_navigation_fencepost01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10868,9200868,'阿曼尼巨魔围栏1','12tr_amani_navigation_fencepost01','structure',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200869,5,940069,'Reborn DECORBATCH1A: 12ph_charity_hfh_doghouse_roof01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10869,9200869,'家园屋顶1A','12ph_charity_hfh_doghouse_roof01','structure',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200870,5,940070,'Reborn DECORBATCH1A: 12be_bloodelf_navigation_secretdoor03',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10870,9200870,'血精灵门3','12be_bloodelf_navigation_secretdoor03','structure',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200871,5,940071,'Reborn DECORBATCH1A: 12fn_fungarian_structure_door01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10871,9200871,'菌人门1','12fn_fungarian_structure_door01','structure',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200872,5,940072,'Reborn DECORBATCH1A: 12tr_amani_navigation_signpost01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10872,9200872,'阿曼尼巨魔立柱1','12tr_amani_navigation_signpost01','structure',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200873,5,940073,'Reborn DECORBATCH1A: 12ph_charity_hfh_doghouse_roof02',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10873,9200873,'家园屋顶2','12ph_charity_hfh_doghouse_roof02','structure',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200874,5,940074,'Reborn DECORBATCH1A: 12fn_fungarian_structure_window01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10874,9200874,'菌人窗1','12fn_fungarian_structure_window01','structure',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200875,5,940075,'Reborn DECORBATCH1A: 12ph_durotar_crafting_roofshingle01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10875,9200875,'家园屋顶1B','12ph_durotar_crafting_roofshingle01','structure',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200876,5,940076,'Reborn DECORBATCH1A: 12ph_durotar_crafting_roofshinglepile01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10876,9200876,'家园屋顶1C','12ph_durotar_crafting_roofshinglepile01','structure',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200877,5,940077,'Reborn DECORBATCH1A: 12ph_earthen_decor_windowfacade02',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10877,9200877,'家园窗2','12ph_earthen_decor_windowfacade02','structure',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200878,5,940078,'Reborn DECORBATCH1A: 12ph_earthen_decor_windowfacade03',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10878,9200878,'家园窗3','12ph_earthen_decor_windowfacade03','structure',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200879,5,940079,'Reborn DECORBATCH1A: 12ph_elwynn_navigation_fencelong01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10879,9200879,'家园围栏1','12ph_elwynn_navigation_fencelong01','structure',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200880,5,940080,'Reborn DECORBATCH1A: 12ph_elwynn_navigation_fencelong02',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10880,9200880,'家园围栏2','12ph_elwynn_navigation_fencelong02','structure',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200881,5,940081,'Reborn DECORBATCH1A: 12ph_dragon_forge01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10881,9200881,'家园熔炉1','12ph_dragon_forge01','functional',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200882,5,940082,'Reborn DECORBATCH1A: 12be_bloodelf_crafting_anvil01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10882,9200882,'血精灵铁砧1','12be_bloodelf_crafting_anvil01','functional',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200883,5,940083,'Reborn DECORBATCH1A: 12fn_fungarian_crafting_anvil01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10883,9200883,'菌人铁砧1','12fn_fungarian_crafting_anvil01','functional',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200884,5,940084,'Reborn DECORBATCH1A: 12pm_primitive_cooking_bbqroaster01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10884,9200884,'原始部落烹饪1A','12pm_primitive_cooking_bbqroaster01','functional',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200885,5,940085,'Reborn DECORBATCH1A: 12tr_amani_cooking_cauldron01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10885,9200885,'阿曼尼巨魔大锅1','12tr_amani_cooking_cauldron01','functional',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200886,5,940086,'Reborn DECORBATCH1A: 12vd_void_crafting_channelingwardrobe01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10886,9200886,'虚空工艺1','12vd_void_crafting_channelingwardrobe01','functional',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200887,5,940087,'Reborn DECORBATCH1A: 12ve_voidelf_crafting_anvil01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10887,9200887,'虚空精灵铁砧1','12ve_voidelf_crafting_anvil01','functional',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200888,5,940088,'Reborn DECORBATCH1A: 12ph_durotar_crafting_bonetusk01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10888,9200888,'家园工艺1A','12ph_durotar_crafting_bonetusk01','functional',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200889,5,940089,'Reborn DECORBATCH1A: 12be_bloodelf_crafting_canvas01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10889,9200889,'血精灵工艺1','12be_bloodelf_crafting_canvas01','functional',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200890,5,940090,'Reborn DECORBATCH1A: 12fn_fungarian_crafting_forge01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10890,9200890,'菌人熔炉1','12fn_fungarian_crafting_forge01','functional',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200891,5,940091,'Reborn DECORBATCH1A: 12pm_primitive_cooking_bowl01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10891,9200891,'原始部落烹饪1B','12pm_primitive_cooking_bowl01','functional',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200892,5,940092,'Reborn DECORBATCH1A: 12tr_amani_cooking_cauldron02',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10892,9200892,'阿曼尼巨魔大锅2','12tr_amani_cooking_cauldron02','functional',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200893,5,940093,'Reborn DECORBATCH1A: 12vd_void_crafting_tool02',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10893,9200893,'虚空工艺2','12vd_void_crafting_tool02','functional',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200894,5,940094,'Reborn DECORBATCH1A: 12ve_voidelf_crafting_energyforge01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10894,9200894,'虚空精灵熔炉1','12ve_voidelf_crafting_energyforge01','functional',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200895,5,940095,'Reborn DECORBATCH1A: 12ph_durotar_crafting_chisel01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10895,9200895,'家园工艺1B','12ph_durotar_crafting_chisel01','functional',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200896,5,940096,'Reborn DECORBATCH1A: 12be_bloodelf_crafting_canvas02',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10896,9200896,'血精灵工艺2','12be_bloodelf_crafting_canvas02','functional',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200897,5,940097,'Reborn DECORBATCH1A: 12fn_fungarian_crafting_tool01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10897,9200897,'菌人工艺1','12fn_fungarian_crafting_tool01','functional',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200898,5,940098,'Reborn DECORBATCH1A: 12pm_primitive_cooking_cauldron01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10898,9200898,'原始部落大锅1','12pm_primitive_cooking_cauldron01','functional',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200899,5,940099,'Reborn DECORBATCH1A: 12tr_amani_cooking_pitcher01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10899,9200899,'阿曼尼巨魔烹饪1','12tr_amani_cooking_pitcher01','functional',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200900,5,940100,'Reborn DECORBATCH1A: 12ph_durotar_crafting_coiledrope01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10900,9200900,'家园工艺1C','12ph_durotar_crafting_coiledrope01','functional',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200901,5,940101,'Reborn DECORBATCH1A: 12ph_bloodelf_decor_cookware_pot01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10901,9200901,'家园锅1A','12ph_bloodelf_decor_cookware_pot01','misc',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200902,5,940102,'Reborn DECORBATCH1A: 12be_bloodelf_decor_armillarysphere01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10902,9200902,'血精灵装饰1','12be_bloodelf_decor_armillarysphere01','misc',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200903,5,940103,'Reborn DECORBATCH1A: 12fn_fungarian_decor_bowl01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10903,9200903,'菌人装饰1B','12fn_fungarian_decor_bowl01','misc',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200904,5,940104,'Reborn DECORBATCH1A: 12xp_general_furniture_magicaldresser01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10904,9200904,'通用家具1A','12xp_general_furniture_magicaldresser01','misc',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200905,5,940105,'Reborn DECORBATCH1A: 12pm_primitive_decor_hangingrope01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10905,9200905,'原始部落装饰1A','12pm_primitive_decor_hangingrope01','misc',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200906,5,940106,'Reborn DECORBATCH1A: 12ru_rutaani_decor_fountain01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10906,9200906,'鲁塔尼装饰1A','12ru_rutaani_decor_fountain01','misc',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200907,5,940107,'Reborn DECORBATCH1A: 12tr_amani_decor_hangingtrinket01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10907,9200907,'阿曼尼巨魔装饰1','12tr_amani_decor_hangingtrinket01','misc',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200908,5,940108,'Reborn DECORBATCH1A: 12tb_twilightsblade_decor_crystal02',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10908,9200908,'暮光之刃装饰2','12tb_twilightsblade_decor_crystal02','misc',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200909,5,940109,'Reborn DECORBATCH1A: 12vd_void_decor_knickknack01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10909,9200909,'虚空装饰1B','12vd_void_decor_knickknack01','misc',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200910,5,940110,'Reborn DECORBATCH1A: 12ve_voidelf_decor_knickknack01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10910,9200910,'虚空精灵装饰1B','12ve_voidelf_decor_knickknack01','misc',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200911,5,940111,'Reborn DECORBATCH1A: 12ph_bloodelf_decor_cookware_pot01_base',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10911,9200911,'家园锅1B','12ph_bloodelf_decor_cookware_pot01_base','misc',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200912,5,940112,'Reborn DECORBATCH1A: 12be_bloodelf_decor_drapery_11_blue',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10912,9200912,'血精灵装饰11','12be_bloodelf_decor_drapery_11_blue','misc',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200913,5,940113,'Reborn DECORBATCH1A: 12fn_fungarian_decor_bowl02',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10913,9200913,'菌人装饰2','12fn_fungarian_decor_bowl02','misc',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200914,5,940114,'Reborn DECORBATCH1A: 12xp_generic_furniture_canvas01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10914,9200914,'通用家具1B','12xp_generic_furniture_canvas01','misc',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200915,5,940115,'Reborn DECORBATCH1A: 12pm_primitive_decor_hangingrope01_noanim',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10915,9200915,'原始部落装饰1B','12pm_primitive_decor_hangingrope01_noanim','misc',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200916,5,940116,'Reborn DECORBATCH1A: 12ru_rutaani_decor_fountain01_lightbloom',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10916,9200916,'鲁塔尼装饰1B','12ru_rutaani_decor_fountain01_lightbloom','misc',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200917,5,940117,'Reborn DECORBATCH1A: 12tr_amani_decor_hangingtrinket02',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10917,9200917,'阿曼尼巨魔装饰2','12tr_amani_decor_hangingtrinket02','misc',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200918,5,940118,'Reborn DECORBATCH1A: 12tb_twilightsblade_storage_chest01',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10918,9200918,'暮光之刃箱子1','12tb_twilightsblade_storage_chest01','misc',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200919,5,940119,'Reborn DECORBATCH1A: 12vd_void_decor_knickknack02',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10919,9200919,'虚空装饰2','12vd_void_decor_knickknack02','misc',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200920,5,940120,'Reborn DECORBATCH1A: 12ve_voidelf_decor_knickknack02',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10920,9200920,'虚空精灵装饰2','12ve_voidelf_decor_knickknack02','misc',1);

INSERT INTO `reborn_housing_recipe` (`catalog_id`,`gold_copper`,`m1_item`,`m1_count`,`m2_item`,`m2_count`,`m3_item`,`m3_count`,`source_zh`,`rarity`,`ways`) VALUES
 (10801, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10802, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10803, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10804, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10805, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10806, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10807, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10808, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10809, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10810, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10811, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10812, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10813, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10814, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10815, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10816, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10817, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10818, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10819, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10820, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10821, 30000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10822, 30000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10823, 30000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10824, 30000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10825, 30000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10826, 30000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10827, 30000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10828, 30000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10829, 30000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10830, 30000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10831, 30000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10832, 30000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10833, 30000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10834, 30000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10835, 30000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10836, 30000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10837, 30000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10838, 30000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10839, 30000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10840, 30000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10841, 40000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10842, 40000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10843, 40000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10844, 40000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10845, 40000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10846, 40000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10847, 40000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10848, 40000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10849, 40000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10850, 40000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10851, 40000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10852, 40000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10853, 40000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10854, 40000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10855, 40000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10856, 40000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10857, 40000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10858, 40000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10859, 40000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10860, 40000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10861, 100000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10862, 100000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10863, 100000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10864, 100000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10865, 100000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10866, 100000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10867, 100000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10868, 100000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10869, 100000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10870, 100000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10871, 100000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10872, 100000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10873, 100000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10874, 100000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10875, 100000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10876, 100000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10877, 100000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10878, 100000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10879, 100000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10880, 100000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10881, 80000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10882, 80000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10883, 80000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10884, 80000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10885, 80000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10886, 80000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10887, 80000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10888, 80000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10889, 80000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10890, 80000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10891, 80000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10892, 80000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10893, 80000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10894, 80000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10895, 80000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10896, 80000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10897, 80000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10898, 80000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10899, 80000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10900, 80000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10901, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10902, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10903, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10904, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10905, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10906, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10907, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10908, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10909, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10910, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10911, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10912, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10913, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10914, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10915, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10916, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10917, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10918, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10919, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3),
 (10920, 50000, 2589, 4, 0, 0, 0, 0, '家园装饰', 1, 3);
