-- WORLD DATABASE. WEAPDECOR1A: three ground weapons as ordinary housing decor (type 5, existing client display ids). Safe to run more than once.
SET NAMES utf8mb4;

REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200401,10,8213,'Reborn H3A: wd_hammer_pvpalliance',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10401,9200401,'联盟角斗士战锤（地面）','Weapon hammer pvp alliance','weapons',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200402,10,8214,'Reborn H3A: wd_axe_northrend',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10402,9200402,'诺森德战斧（地面）','Weapon axe northrend','weapons',1);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9200403,10,8215,'Reborn H3A: wd_maul_b',1,0,0,0,0);
REPLACE INTO `reborn_housing_catalog` (`catalog_id`,`gobject_entry`,`name_zh`,`name_en`,`category`,`enabled`) VALUES (10403,9200403,'巨型重锤（地面）','Weapon maul b','weapons',1);

SELECT c.catalog_id,c.name_zh,t.displayId FROM reborn_housing_catalog c JOIN gameobject_template t ON t.entry=c.gobject_entry WHERE c.catalog_id BETWEEN 10401 AND 10499;
