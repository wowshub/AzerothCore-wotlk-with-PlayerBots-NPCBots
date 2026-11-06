-- WORLD DATABASE. WPICK1A: clickable (type 10 goober) weapon pickup templates, entries 9300001+. Safe to run more than once.
-- The models are existing client display ids (GameObjectDisplayInfo.dbc), no client file is needed.
SET NAMES utf8mb4;

REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9300001,10,8213,'Reborn Pickup: Hammer PvP Alliance (Frostmourne altar)',1,0,0,0,0);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9300002,10,8214,'Reborn Pickup: Axe Northrend (Frostmourne altar)',1,0,0,0,0);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9300003,10,8215,'Reborn Pickup: Maul (Frostmourne altar)',1,0,0,0,0);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9300004,10,8493,'Reborn Pickup: Hammer PvP Horde',1,0,0,0,0);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9300005,10,8494,'Reborn Pickup: Orc Axe',1,0,0,0,0);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9300006,10,8490,'Reborn Pickup: Orc Spear',1,0,0,0,0);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9300007,10,8564,'Reborn Pickup: Long Sword',1,0,0,0,0);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9300008,10,8288,'Reborn Pickup: Vrykul Sword',1,0,0,0,0);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9300009,10,8220,'Reborn Pickup: Frost Giant Spear',1,0,0,0,0);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9300010,10,8102,'Reborn Pickup: Scythe of Antiok',1,0,0,0,0);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9300011,10,8101,'Reborn Pickup: Stone Club',1,0,0,0,0);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9300012,10,669,'Reborn Pickup: Human Sword 1',1,0,0,0,0);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9300013,10,670,'Reborn Pickup: Human Sword 2',1,0,0,0,0);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9300014,10,671,'Reborn Pickup: Human Mace',1,0,0,0,0);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9300015,10,908,'Reborn Pickup: Human Hammer 1',1,0,0,0,0);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9300016,10,1067,'Reborn Pickup: Human Hammer 2',1,0,0,0,0);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9300017,10,2455,'Reborn Pickup: Human Staff',1,0,0,0,0);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9300018,10,8496,'Reborn Pickup: Crossbow',1,0,0,0,0);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9300019,10,8416,'Reborn Pickup: Shield Alliance',1,0,0,0,0);
REPLACE INTO `gameobject_template` (`entry`,`type`,`displayId`,`name`,`size`,`Data0`,`Data1`,`Data2`,`Data3`) VALUES (9300020,10,8492,'Reborn Pickup: Shield Horde',1,0,0,0,0);

SELECT `entry`,`displayId`,`name` FROM `gameobject_template` WHERE `entry` BETWEEN 9300001 AND 9300099;
