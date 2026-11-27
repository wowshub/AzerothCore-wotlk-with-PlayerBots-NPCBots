-- HARA2 V1 (2026-11-26, Claude) - candidate, NOT user-tested. Stop worldserver, run on the WORLD database, restart. Safe to run twice.
-- Needs: MAPSRV2A (map 12694), the click row 9350803 (island packages) and, for mob drops, LOOT1A V2 rows.
SET NAMES utf8mb4;
SET @spawn_limit := 16777215;
SELECT COUNT(*) AS click_template_9350803_must_be_1 FROM `gameobject_template` WHERE `entry` = 9350803;
DELETE FROM `creature` WHERE `map` = 12694 AND (`Comment` LIKE 'HARA2 %');
DELETE FROM `gameobject` WHERE `map` = 12694 AND (`Comment` LIKE 'HARA2 %');
DELETE FROM `creature_template` WHERE `entry` IN (245090, 245096, 245097, 245102, 245104, 245114, 245117, 245118, 245879, 245881, 246277, 246360, 246705, 247257, 248669, 253478);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (245090, 245096, 245097, 245102, 245104, 245114, 245117, 245118, 245879, 245881, 246277, 246360, 246705, 247257, 248669, 253478);
DELETE FROM `creature_template_movement` WHERE `CreatureId` IN (245090, 245096, 245097, 245102, 245104, 245114, 245117, 245118, 245879, 245881, 246277, 246360, 246705, 247257, 248669, 253478);
DELETE FROM `creature_loot_template` WHERE `Comment` LIKE 'HARA2 %';
DELETE FROM `creature_model_info` WHERE `DisplayID` BETWEEN 710101 AND 710106;
DELETE FROM `gameobject_template` WHERE `entry` IN (553763, 554679, 546728, 554848, 554966);
DELETE FROM `gameobject_template_addon` WHERE `entry` IN (553763, 554679, 546728, 554848, 554966);
DELETE FROM `quest_template` WHERE `ID` IN (90957, 90958, 90959, 90960);
DELETE FROM `quest_template_addon` WHERE `ID` IN (90957, 90958, 90959, 90960);
DELETE FROM `quest_offer_reward` WHERE `ID` IN (90957, 90958, 90959, 90960);
DELETE FROM `quest_request_items` WHERE `ID` IN (90957, 90958, 90959, 90960);
DELETE FROM `quest_poi` WHERE `QuestID` IN (90957, 90958, 90959, 90960);
DELETE FROM `quest_poi_points` WHERE `QuestID` IN (90957, 90958, 90959, 90960);
DELETE FROM `creature_queststarter` WHERE `quest` IN (90957, 90958, 90959, 90960);
DELETE FROM `creature_questender` WHERE `quest` IN (90957, 90958, 90959, 90960);
SELECT COALESCE(MAX(`guid`), 0) INTO @g FROM `creature` WHERE `guid` < @spawn_limit;
SELECT COALESCE(MAX(`guid`), 0) INTO @o FROM `gameobject` WHERE `guid` < @spawn_limit;
SELECT IF(@g + 200 + 10000 < @spawn_limit AND @o + 40 + 10000 < @spawn_limit, 'guid base OK', 'ABORT: no guid room, do not continue') AS guid_check, @g AS creature_max, @o AS go_max;
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `unit_class`, `unit_flags`, `type`, `AIName`, `MovementType`, `HealthModifier`, `DamageModifier`, `ExperienceModifier`, `RegenHealth`, `flags_extra`, `ScriptName`, `mingold`, `maxgold`) VALUES
(245090, 'Hagar 哈加尔', 'Elder 长者', 10, 10, 35, 3, 1, 1.14286, 0, 1, 512, 7, '', 0, 3, 1, 2, 1, 2, '', 0, 0),
(245096, 'Hagar 哈加尔', 'Elder 长者', 10, 10, 35, 3, 1, 1.14286, 0, 1, 512, 7, '', 0, 3, 1, 2, 1, 2, '', 0, 0),
(245097, 'Hagar 哈加尔', 'Elder 长者', 10, 10, 35, 3, 1, 1.14286, 0, 1, 512, 7, '', 0, 3, 1, 2, 1, 2, '', 0, 0),
(245102, 'Dalnir 戴尼尔', 'Root Tender 根须照料者', 10, 10, 35, 3, 1, 1.14286, 0, 1, 512, 7, '', 0, 3, 1, 2, 1, 2, '', 0, 0),
(245104, 'Alton Parsons 奥尔顿·帕森斯', 'Outsider 外来者', 5, 5, 35, 1, 1, 1.14286, 0, 1, 768, 7, '', 0, 5, 1, 2, 1, 2, '', 0, 0),
(245114, 'Vicious Saptor 凶狠的迅叶龙', NULL, 3, 3, 14, 0, 1, 1.14286, 0, 1, 0, 1, '', 1, 2.5, 0.7, 2, 1, 0, '', 15, 40),
(245117, 'Pesky Sludger 讨厌的跃泥鱼', NULL, 2, 2, 7, 0, 1, 1.14286, 0, 1, 0, 1, '', 1, 1, 0.5, 2, 1, 0, '', 2, 8),
(245118, 'Invasive Drifter 入侵的漂流者', NULL, 1, 1, 7, 0, 1, 1.14286, 0, 1, 0, 1, '', 1, 1, 0.5, 2, 1, 0, '', 2, 6),
(245879, 'Orweyna 奥威娜', NULL, 10, 10, 35, 3, 1, 1.14286, 0, 1, 512, 7, '', 0, 3, 1, 2, 1, 2, '', 0, 0),
(245881, 'Orweyna 奥威娜', NULL, 10, 10, 35, 3, 1, 1.14286, 0, 1, 512, 7, '', 0, 3, 1, 2, 1, 2, '', 0, 0),
(246277, 'Withered Plant 枯萎的植物', 'Pull it 点击拔除', 1, 1, 35, 1, 1, 1.14286, 0, 1, 768, 10, '', 0, 1, 0, 2, 1, 2, '', 0, 0),
(246360, 'Outsider Directed to Safety 外来者脱险', NULL, 1, 1, 35, 0, 1, 1.14286, 0, 1, 768, 10, '', 0, 1, 1, 2, 1, 2, '', 0, 0),
(246705, 'Dalnir 戴尼尔', 'Root Tender 根须照料者', 10, 10, 35, 1, 1, 1.14286, 0, 1, 512, 7, '', 0, 3, 1, 2, 1, 2, '', 0, 0),
(247257, 'Outsider Found 找到外来者', NULL, 1, 1, 35, 0, 1, 1.14286, 0, 1, 768, 10, '', 0, 1, 1, 2, 1, 2, '', 0, 0),
(248669, 'Withered Lasher 枯萎的鞭笞者', NULL, 2, 3, 7, 0, 1, 1.14286, 0, 1, 0, 4, '', 1, 1, 0.5, 2, 1, 0, '', 3, 9),
(253478, 'Dalnir Met 会见戴尼尔', NULL, 1, 1, 35, 0, 1, 1.14286, 0, 1, 768, 10, '', 0, 1, 1, 2, 1, 2, '', 0, 0);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(245090, 0, 1542, 1, 1, 0),
(245096, 0, 1542, 1, 1, 0),
(245097, 0, 1542, 1, 1, 0),
(245102, 0, 2261, 1, 1, 0),
(245104, 0, 1943, 1, 1, 0),
(245114, 0, 710105, 1.2, 1, 0),
(245117, 0, 710102, 0.7, 1, 0),
(245118, 0, 710101, 1, 1, 0),
(245879, 0, 710106, 1, 1, 0),
(245881, 0, 710106, 1, 1, 0),
(246277, 0, 710103, 1, 1, 0),
(246360, 0, 11686, 1, 1, 0),
(246705, 0, 2261, 1, 1, 0),
(247257, 0, 11686, 1, 1, 0),
(248669, 0, 710104, 0.7, 1, 0),
(253478, 0, 11686, 1, 1, 0);
INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`, `Chase`, `Random`, `InteractionPauseTimer`) VALUES (245118, 1, 0, 1, 0, 0, 0, 0), (246277, 1, 0, 0, 1, 0, 0, 0);
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`) VALUES (710101, 0.5, 1.2, 2, 0);
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`) VALUES (710102, 0.5, 1.0, 2, 0);
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`) VALUES (710103, 0.5, 1.0, 2, 0);
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`) VALUES (710104, 0.6, 1.2, 2, 0);
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`) VALUES (710105, 0.7, 1.5, 2, 0);
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`) VALUES (710106, 0.35, 1.5, 2, 0);

-- drops: copies of the accepted island drop rows (money is set on the templates above)
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT 245114, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, 'HARA2 copy of 151091' FROM `creature_loot_template` WHERE `Entry` = 151091 AND `Comment` LIKE 'LOOT1A %' AND `QuestRequired` = 0;
UPDATE `creature_template` SET `lootid` = 245114 WHERE `entry` = 245114 AND EXISTS (SELECT 1 FROM `creature_loot_template` WHERE `Entry` = 245114);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT 245117, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, 'HARA2 copy of 150228' FROM `creature_loot_template` WHERE `Entry` = 150228 AND `Comment` LIKE 'LOOT1A %' AND `QuestRequired` = 0;
UPDATE `creature_template` SET `lootid` = 245117 WHERE `entry` = 245117 AND EXISTS (SELECT 1 FROM `creature_loot_template` WHERE `Entry` = 245117);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT 245118, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, 'HARA2 copy of 150228' FROM `creature_loot_template` WHERE `Entry` = 150228 AND `Comment` LIKE 'LOOT1A %' AND `QuestRequired` = 0;
UPDATE `creature_template` SET `lootid` = 245118 WHERE `entry` = 245118 AND EXISTS (SELECT 1 FROM `creature_loot_template` WHERE `Entry` = 245118);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT 248669, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, 'HARA2 copy of 160433' FROM `creature_loot_template` WHERE `Entry` = 160433 AND `Comment` LIKE 'LOOT1A %' AND `QuestRequired` = 0;
UPDATE `creature_template` SET `lootid` = 248669 WHERE `entry` = 248669 AND EXISTS (SELECT 1 FROM `creature_loot_template` WHERE `Entry` = 248669);
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES
(@g + 1, 245090, 12694, 1, 1, 0, 1268.21, 943.81, 1332.59, 4.48, 120, 0, 0, 'HARA2 245090'),
(@g + 2, 245102, 12694, 1, 1, 0, 1349.04, 908.11, 1345.26, 3.82, 120, 0, 0, 'HARA2 245102'),
(@g + 3, 245879, 12694, 1, 1, 0, 1339.53, 905.60, 1345.42, 5.78, 120, 0, 0, 'HARA2 245879'),
(@g + 4, 245881, 12694, 1, 1, 0, 1164.92, 1002.47, 1341.36, 5.37, 120, 0, 0, 'HARA2 245881'),
(@g + 5, 245096, 12694, 1, 1, 0, 1167.67, 1002.90, 1341.55, 4.78, 120, 0, 0, 'HARA2 245096'),
(@g + 6, 245097, 12694, 1, 1, 0, 1148.61, 1166.34, 1310.16, 5.32, 120, 0, 0, 'HARA2 245097'),
(@g + 7, 246705, 12694, 1, 1, 0, 1174.20, 1004.40, 1341.20, 4.00, 120, 0, 0, 'HARA2 246705'),
(@g + 8, 245104, 12694, 1, 1, 0, 1115.41, 882.90, 1345.77, 6.01, 120, 0, 0, 'HARA2 245104'),
(@g + 9, 245118, 12694, 1, 1, 0, 1268.27, 860.10, 1330.11, 3.14, 40, 4, 1, 'HARA2 245118'),
(@g + 10, 245118, 12694, 1, 1, 0, 1225.47, 889.20, 1327.68, 1.49, 40, 4, 1, 'HARA2 245118'),
(@g + 11, 245118, 12694, 1, 1, 0, 1227.46, 827.47, 1330.78, 5.22, 40, 4, 1, 'HARA2 245118'),
(@g + 12, 245118, 12694, 1, 1, 0, 1211.01, 784.05, 1330.73, 4.11, 40, 4, 1, 'HARA2 245118'),
(@g + 13, 245118, 12694, 1, 1, 0, 1224.42, 746.16, 1332.83, 5.39, 40, 4, 1, 'HARA2 245118'),
(@g + 14, 245118, 12694, 1, 1, 0, 1255.28, 718.06, 1334.04, 6.10, 40, 4, 1, 'HARA2 245118'),
(@g + 15, 245118, 12694, 1, 1, 0, 1286.25, 754.35, 1332.06, 1.02, 40, 4, 1, 'HARA2 245118'),
(@g + 16, 245118, 12694, 1, 1, 0, 1313.18, 757.58, 1334.76, 1.91, 40, 4, 1, 'HARA2 245118'),
(@g + 17, 245118, 12694, 1, 1, 0, 1279.00, 781.86, 1332.59, 2.08, 40, 4, 1, 'HARA2 245118'),
(@g + 18, 245118, 12694, 1, 1, 0, 1300.52, 805.32, 1336.17, 1.37, 40, 4, 1, 'HARA2 245118'),
(@g + 19, 245118, 12694, 1, 1, 0, 1270.52, 811.31, 1332.96, 2.38, 40, 4, 1, 'HARA2 245118'),
(@g + 20, 245118, 12694, 1, 1, 0, 1281.09, 854.27, 1331.08, 1.57, 40, 4, 1, 'HARA2 245118'),
(@g + 21, 245118, 12694, 1, 1, 0, 1301.97, 887.33, 1329.01, 1.57, 40, 4, 1, 'HARA2 245118'),
(@g + 22, 245118, 12694, 1, 1, 0, 1330.12, 902.78, 1348.03, 0.09, 40, 4, 1, 'HARA2 245118'),
(@g + 23, 245118, 12694, 1, 1, 0, 1348.62, 886.27, 1347.70, 5.25, 40, 4, 1, 'HARA2 245118'),
(@g + 24, 245118, 12694, 1, 1, 0, 1185.22, 1001.22, 1338.53, 2.97, 40, 4, 1, 'HARA2 245118'),
(@g + 25, 245118, 12694, 1, 1, 0, 1184.12, 882.57, 1334.44, 3.66, 40, 4, 1, 'HARA2 245118'),
(@g + 26, 245118, 12694, 1, 1, 0, 1185.47, 744.30, 1341.40, 1.13, 40, 4, 1, 'HARA2 245118'),
(@g + 27, 245117, 12694, 1, 1, 0, 1265.10, 1004.38, 1327.41, 4.02, 40, 5, 1, 'HARA2 245117'),
(@g + 28, 245117, 12694, 1, 1, 0, 1234.82, 989.23, 1327.41, 4.02, 40, 5, 1, 'HARA2 245117'),
(@g + 29, 245117, 12694, 1, 1, 0, 1224.72, 928.65, 1327.81, 4.02, 40, 5, 1, 'HARA2 245117'),
(@g + 30, 245117, 12694, 1, 1, 0, 1396.35, 898.35, 1347.33, 4.02, 40, 5, 1, 'HARA2 245117'),
(@g + 31, 245117, 12694, 1, 1, 0, 1376.16, 898.35, 1346.19, 4.02, 40, 5, 1, 'HARA2 245117'),
(@g + 32, 245117, 12694, 1, 1, 0, 1244.91, 898.35, 1327.45, 4.02, 40, 5, 1, 'HARA2 245117'),
(@g + 33, 245117, 12694, 1, 1, 0, 1396.35, 883.21, 1346.47, 4.02, 40, 5, 1, 'HARA2 245117'),
(@g + 34, 245117, 12694, 1, 1, 0, 1376.16, 883.21, 1345.17, 4.02, 40, 5, 1, 'HARA2 245117'),
(@g + 35, 245117, 12694, 1, 1, 0, 1335.77, 883.21, 1344.69, 4.02, 40, 5, 1, 'HARA2 245117'),
(@g + 36, 245117, 12694, 1, 1, 0, 1285.30, 868.06, 1327.41, 4.02, 40, 5, 1, 'HARA2 245117'),
(@g + 37, 246277, 12694, 1, 1, 0, 1224.72, 974.08, 1327.41, 4.02, 40, 0, 0, 'HARA2 246277'),
(@g + 38, 246277, 12694, 1, 1, 0, 1396.35, 898.35, 1347.33, 4.02, 40, 0, 0, 'HARA2 246277'),
(@g + 39, 246277, 12694, 1, 1, 0, 1366.06, 898.35, 1346.80, 4.02, 40, 0, 0, 'HARA2 246277'),
(@g + 40, 246277, 12694, 1, 1, 0, 1204.53, 898.35, 1331.53, 4.02, 40, 0, 0, 'HARA2 246277'),
(@g + 41, 246277, 12694, 1, 1, 0, 1174.24, 883.21, 1333.45, 4.02, 40, 0, 0, 'HARA2 246277'),
(@g + 42, 246277, 12694, 1, 1, 0, 1361.86, 866.68, 1345.55, 0.48, 40, 0, 0, 'HARA2 246277'),
(@g + 43, 246277, 12694, 1, 1, 0, 1305.49, 852.92, 1331.03, 4.02, 40, 0, 0, 'HARA2 246277'),
(@g + 44, 246277, 12694, 1, 1, 0, 1265.10, 852.92, 1329.36, 4.02, 40, 0, 0, 'HARA2 246277'),
(@g + 45, 246277, 12694, 1, 1, 0, 1204.53, 837.77, 1328.71, 4.02, 40, 0, 0, 'HARA2 246277'),
(@g + 46, 246277, 12694, 1, 1, 0, 1305.49, 807.48, 1334.32, 4.02, 40, 0, 0, 'HARA2 246277'),
(@g + 47, 246277, 12694, 1, 1, 0, 1174.24, 807.48, 1335.02, 4.02, 40, 0, 0, 'HARA2 246277'),
(@g + 48, 246277, 12694, 1, 1, 0, 1285.30, 792.33, 1330.85, 4.02, 40, 0, 0, 'HARA2 246277'),
(@g + 49, 248669, 12694, 1, 1, 0, 1366.06, 1004.38, 1333.86, 4.02, 40, 5, 1, 'HARA2 248669'),
(@g + 50, 248669, 12694, 1, 1, 0, 1396.35, 898.35, 1347.33, 4.02, 40, 5, 1, 'HARA2 248669'),
(@g + 51, 248669, 12694, 1, 1, 0, 1345.87, 898.35, 1345.23, 4.02, 40, 5, 1, 'HARA2 248669'),
(@g + 52, 248669, 12694, 1, 1, 0, 1193.31, 896.06, 1333.04, 1.03, 40, 5, 1, 'HARA2 248669'),
(@g + 53, 248669, 12694, 1, 1, 0, 1345.87, 868.06, 1344.90, 4.02, 40, 5, 1, 'HARA2 248669'),
(@g + 54, 248669, 12694, 1, 1, 0, 1297.77, 852.40, 1330.96, 6.06, 40, 5, 1, 'HARA2 248669'),
(@g + 55, 248669, 12694, 1, 1, 0, 1205.84, 877.33, 1331.72, 2.46, 40, 5, 1, 'HARA2 248669'),
(@g + 56, 248669, 12694, 1, 1, 0, 1204.53, 852.92, 1328.96, 4.02, 40, 5, 1, 'HARA2 248669'),
(@g + 57, 248669, 12694, 1, 1, 0, 1196.94, 814.38, 1331.59, 6.22, 40, 5, 1, 'HARA2 248669'),
(@g + 58, 248669, 12694, 1, 1, 0, 1301.93, 789.95, 1332.18, 0.19, 40, 5, 1, 'HARA2 248669'),
(@g + 59, 248669, 12694, 1, 1, 0, 1275.20, 762.04, 1331.31, 4.02, 40, 5, 1, 'HARA2 248669'),
(@g + 60, 248669, 12694, 1, 1, 0, 1225.16, 765.98, 1329.95, 1.07, 40, 5, 1, 'HARA2 248669'),
(@g + 61, 248669, 12694, 1, 1, 0, 1224.01, 853.03, 1328.74, 5.52, 40, 5, 1, 'HARA2 248669'),
(@g + 62, 248669, 12694, 1, 1, 0, 1224.60, 805.97, 1328.87, 4.59, 40, 5, 1, 'HARA2 248669'),
(@g + 63, 248669, 12694, 1, 1, 0, 1285.41, 814.01, 1331.56, 0.48, 40, 5, 1, 'HARA2 248669'),
(@g + 64, 248669, 12694, 1, 1, 0, 1357.86, 889.16, 1345.97, 2.47, 40, 5, 1, 'HARA2 248669'),
(@g + 65, 248669, 12694, 1, 1, 0, 1336.65, 911.76, 1344.21, 2.31, 40, 5, 1, 'HARA2 248669'),
(@g + 66, 245114, 12694, 1, 1, 0, 1150.80, 892.17, 1337.85, 3.66, 40, 3, 1, 'HARA2 245114'),
(@g + 67, 245114, 12694, 1, 1, 0, 1120.86, 881.20, 1343.81, 2.71, 40, 3, 1, 'HARA2 245114');
-- class mentors (TRAINER1A V3 templates): every player sees only the mentor of his own class
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`)
SELECT @g + 68, 9180201, 12694, 1, 3, 0, 1254.0, 930.0, 1331.08, 5.6, 120, 0, 0, 'HARA2 mentor 1' FROM `creature_default_trainer` WHERE `CreatureId` = 9180201;
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`)
SELECT @g + 69, 9180202, 12694, 1, 3, 0, 1254.0, 930.0, 1331.08, 5.6, 120, 0, 0, 'HARA2 mentor 2' FROM `creature_default_trainer` WHERE `CreatureId` = 9180202;
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`)
SELECT @g + 70, 9180203, 12694, 1, 3, 0, 1254.0, 930.0, 1331.08, 5.6, 120, 0, 0, 'HARA2 mentor 3' FROM `creature_default_trainer` WHERE `CreatureId` = 9180203;
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`)
SELECT @g + 71, 9180204, 12694, 1, 3, 0, 1254.0, 930.0, 1331.08, 5.6, 120, 0, 0, 'HARA2 mentor 4' FROM `creature_default_trainer` WHERE `CreatureId` = 9180204;
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`)
SELECT @g + 72, 9180205, 12694, 1, 3, 0, 1254.0, 930.0, 1331.08, 5.6, 120, 0, 0, 'HARA2 mentor 5' FROM `creature_default_trainer` WHERE `CreatureId` = 9180205;
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`)
SELECT @g + 73, 9180206, 12694, 1, 3, 0, 1254.0, 930.0, 1331.08, 5.6, 120, 0, 0, 'HARA2 mentor 6' FROM `creature_default_trainer` WHERE `CreatureId` = 9180206;
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`)
SELECT @g + 74, 9180207, 12694, 1, 3, 0, 1254.0, 930.0, 1331.08, 5.6, 120, 0, 0, 'HARA2 mentor 7' FROM `creature_default_trainer` WHERE `CreatureId` = 9180207;
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`)
SELECT @g + 75, 9180208, 12694, 1, 3, 0, 1254.0, 930.0, 1331.08, 5.6, 120, 0, 0, 'HARA2 mentor 8' FROM `creature_default_trainer` WHERE `CreatureId` = 9180208;
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`)
SELECT @g + 76, 9180209, 12694, 1, 3, 0, 1254.0, 930.0, 1331.08, 5.6, 120, 0, 0, 'HARA2 mentor 9' FROM `creature_default_trainer` WHERE `CreatureId` = 9180209;
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`)
SELECT @g + 77, 9180211, 12694, 1, 3, 0, 1254.0, 930.0, 1331.08, 5.6, 120, 0, 0, 'HARA2 mentor 11' FROM `creature_default_trainer` WHERE `CreatureId` = 9180211;
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`)
SELECT @g + 78, 9180213, 12694, 1, 3, 0, 1254.0, 930.0, 1331.08, 5.6, 120, 0, 0, 'HARA2 mentor 13' FROM `creature_default_trainer` WHERE `CreatureId` = 9180213;
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`)
SELECT @g + 79, 9180214, 12694, 1, 3, 0, 1254.0, 930.0, 1331.08, 5.6, 120, 0, 0, 'HARA2 mentor 14' FROM `creature_default_trainer` WHERE `CreatureId` = 9180214;
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`)
SELECT @g + 80, 9180215, 12694, 1, 3, 0, 1254.0, 930.0, 1331.08, 5.6, 120, 0, 0, 'HARA2 mentor 15' FROM `creature_default_trainer` WHERE `CreatureId` = 9180215;
DROP TEMPORARY TABLE IF EXISTS tmp_go;
CREATE TEMPORARY TABLE tmp_go AS SELECT * FROM `gameobject_template` WHERE `entry` = 9350803;
UPDATE tmp_go SET `entry` = 546728, `name` = 'Legacy Stone of True Calling 使命传承石', `displayId` = 235, `size` = 2.0, `Data1` = 90960, `Data5` = 0;
INSERT INTO `gameobject_template` SELECT * FROM tmp_go;
DROP TEMPORARY TABLE tmp_go;
DROP TEMPORARY TABLE IF EXISTS tmp_go;
CREATE TEMPORARY TABLE tmp_go AS SELECT * FROM `gameobject_template` WHERE `entry` = 9350803;
UPDATE tmp_go SET `entry` = 553763, `name` = 'Invasive Fungi 入侵真菌', `displayId` = 6432, `size` = 1.0, `Data1` = 90958, `Data5` = 1;
INSERT INTO `gameobject_template` SELECT * FROM tmp_go;
DROP TEMPORARY TABLE tmp_go;
DROP TEMPORARY TABLE IF EXISTS tmp_go;
CREATE TEMPORARY TABLE tmp_go AS SELECT * FROM `gameobject_template` WHERE `entry` = 9350803;
UPDATE tmp_go SET `entry` = 554679, `name` = 'Legacy Stone of True Self 真我传承石', `displayId` = 235, `size` = 2.0, `Data1` = 90960, `Data5` = 0;
INSERT INTO `gameobject_template` SELECT * FROM tmp_go;
DROP TEMPORARY TABLE tmp_go;
DROP TEMPORARY TABLE IF EXISTS tmp_go;
CREATE TEMPORARY TABLE tmp_go AS SELECT * FROM `gameobject_template` WHERE `entry` = 9350803;
UPDATE tmp_go SET `entry` = 554848, `name` = 'Legacy Stone of the Goddess 女神指引传承石', `displayId` = 235, `size` = 2.0, `Data1` = 90960, `Data5` = 0;
INSERT INTO `gameobject_template` SELECT * FROM tmp_go;
DROP TEMPORARY TABLE tmp_go;
DROP TEMPORARY TABLE IF EXISTS tmp_go;
CREATE TEMPORARY TABLE tmp_go AS SELECT * FROM `gameobject_template` WHERE `entry` = 9350803;
UPDATE tmp_go SET `entry` = 554966, `name` = 'Paint Your Legacy Stone 绘制你的传承石', `displayId` = 235, `size` = 1.6, `Data1` = 90960, `Data5` = 0;
INSERT INTO `gameobject_template` SELECT * FROM tmp_go;
DROP TEMPORARY TABLE tmp_go;
INSERT INTO `gameobject_template_addon` (`entry`, `faction`, `flags`) VALUES (546728, 0, 0), (553763, 0, 0), (554679, 0, 0), (554848, 0, 0), (554966, 0, 0);
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `Comment`) VALUES
(@o + 1, 553763, 12694, 1, 1, 1330.73, 898.35, 1346.04, 0, 0, 0, 0, 1, 30, 100, 1, 'HARA2 553763'),
(@o + 2, 553763, 12694, 1, 1, 1330.73, 883.21, 1344.76, 0, 0, 0, 0, 1, 30, 100, 1, 'HARA2 553763'),
(@o + 3, 553763, 12694, 1, 1, 1270.15, 883.21, 1328.32, 0, 0, 0, 0, 1, 30, 100, 1, 'HARA2 553763'),
(@o + 4, 553763, 12694, 1, 1, 1205.18, 806.03, 1331.73, 0, 0, 0, 0, 1, 30, 100, 1, 'HARA2 553763'),
(@o + 5, 553763, 12694, 1, 1, 1270.71, 821.78, 1331.79, 0, 0, 0, 0, 1, 30, 100, 1, 'HARA2 553763'),
(@o + 6, 553763, 12694, 1, 1, 1294.23, 781.25, 1331.70, 0, 0, 0, 0, 1, 30, 100, 1, 'HARA2 553763'),
(@o + 7, 553763, 12694, 1, 1, 1199.32, 872.77, 1332.14, 0, 0, 0, 0, 1, 30, 100, 1, 'HARA2 553763'),
(@o + 8, 553763, 12694, 1, 1, 1166.51, 914.97, 1340.16, 0, 0, 0, 0, 1, 30, 100, 1, 'HARA2 553763'),
(@o + 9, 554679, 12694, 1, 1, 1100.30, 1033.90, 1339.50, 0, 0, 0, 0, 1, 30, 100, 1, 'HARA2 554679'),
(@o + 10, 546728, 12694, 1, 1, 1144.60, 1060.00, 1321.00, 0, 0, 0, 0, 1, 30, 100, 1, 'HARA2 546728'),
(@o + 11, 554848, 12694, 1, 1, 1144.50, 1129.20, 1312.00, 0, 0, 0, 0, 1, 30, 100, 1, 'HARA2 554848'),
(@o + 12, 554966, 12694, 1, 1, 1137.60, 1166.30, 1311.70, 0, 0, 0, 0, 1, 30, 100, 1, 'HARA2 554966');
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `AllowableRaces`, `RewardXPDifficulty`, `RewardMoney`, `Flags`, `LogTitle`, `LogDescription`, `QuestDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGoCount1`, `ObjectiveText1`, `RequiredNpcOrGo2`, `RequiredNpcOrGoCount2`, `ObjectiveText2`, `RequiredNpcOrGo3`, `RequiredNpcOrGoCount3`, `ObjectiveText3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount4`, `ObjectiveText4`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`) VALUES
(90957, 2, -1, 1, 0, 5, 60, 0, 'Initiation Day 入门之日', 'Kill 6 Invasive Drifters around the roots, then meet Root Tender Dalnir. / 在根须周围消灭6只入侵的漂流者，然后去找根须照料者戴尼尔。', '$N, today is when you find your proper place among the haranir. Root Tender Dalnir will guide you. By the end of the day you will make your mark in the Den of Remembrance.$B$BDalnir was clearing invasive drifters from the roots. Before you go to him, help by removing some of the pests yourself.$B$B$N，今天是你在哈籁尼尔族人中找到自己位置的日子。根须照料者戴尼尔会指引你，今天结束时你将在铭记之穴留下自己的印记。$B$B戴尼尔正在清理根须上的漂流者。去见他之前，先动手清掉一些。', 'Meet Dalnir in Har''mara. / 去哈尔玛拉找戴尼尔。', 245118, 6, 'Invasive Drifter slain 消灭入侵的漂流者', 0, 0, '', 0, 0, '', 0, 0, '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`) VALUES (90957, 0);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `RewardText`, `VerifiedBuild`) VALUES (90957, 1, 'Good. The roots breathe easier already.$B$B很好，根须已经舒展多了。', 0);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`, `VerifiedBuild`) VALUES (90957, 'The drifters are still there. / 漂流者还没清干净。', 0);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (245090, 90957);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (245102, 90957);
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `AllowableRaces`, `RewardXPDifficulty`, `RewardMoney`, `Flags`, `LogTitle`, `LogDescription`, `QuestDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGoCount1`, `ObjectiveText1`, `RequiredNpcOrGo2`, `RequiredNpcOrGoCount2`, `ObjectiveText2`, `RequiredNpcOrGo3`, `RequiredNpcOrGoCount3`, `ObjectiveText3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount4`, `ObjectiveText4`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`) VALUES
(90958, 2, -1, 1, 0, 6, 100, 0, 'Roots Above All 根须至上', 'Remove lashers, sludgers, withered plants and invasive fungi. / 清除鞭笞者、跃泥鱼、枯萎植物和入侵真菌。', 'Some say the great trees grow and Harandar will remain even if we do not tend them. Our traditions say it does not matter. We remain here to protect, tend and serve.$B$BKeeping the ground around the roots free of pests reflects this duty. Return to me once you are done.$B$B有人说巨树自会生长，就算无人照料哈籁恩达尔也会长存。我们的传统说这并不重要：我们留在这里，就是为了守护、照料和服侍。$B$B让根须周围远离害虫，就是这份责任。办完回来找我。', 'Return to Dalnir. / 回去找戴尼尔。', 248669, 8, 'Withered Lasher slain 消灭枯萎的鞭笞者', 245117, 8, 'Pesky Sludger slain 消灭跃泥鱼', 246277, 6, 'Withered Plant pulled 拔除枯萎植物', -553763, 6, 'Invasive Fungi removed 清除入侵真菌', 3274, 1, 4906, 1, 2691, 1, 0, 0, 0, 0, 0, 0);
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`) VALUES (90958, 90957);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `RewardText`, `VerifiedBuild`) VALUES (90958, 1, 'You represent our ways well, $N.$B$B$N，你很好地践行了我们的传统。', 0);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`, `VerifiedBuild`) VALUES (90958, 'The roots still suffer. / 根须还在受害。', 0);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (245102, 90958);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (245102, 90958);
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `AllowableRaces`, `RewardXPDifficulty`, `RewardMoney`, `Flags`, `LogTitle`, `LogDescription`, `QuestDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGoCount1`, `ObjectiveText1`, `RequiredNpcOrGo2`, `RequiredNpcOrGoCount2`, `ObjectiveText2`, `RequiredNpcOrGo3`, `RequiredNpcOrGoCount3`, `ObjectiveText3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount4`, `ObjectiveText4`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`) VALUES
(90959, 2, -1, 1, 0, 6, 150, 0, 'Traditional Duties 传统职责', 'Search for the outsider in Har''mara, get them to safety, meet Dalnir at the Den. / 在哈尔玛拉寻找那位外来者，让他脱险，再到铭记之穴见戴尼尔。', 'Dalnir has a point about the ceremony, but we should not focus too narrowly. Sometimes we must look beyond.$B$BAn outsider was seen to the south west. Find them before the saptors do.$B$B戴尼尔对仪式的看法有道理，但我们不能只盯着眼前，有时也要看向外面。$B$B有人在西南方看到一位外来者，赶在迅叶龙之前找到他。', 'Return to Orweyna outside the Den of Remembrance. / 回到铭记之穴外找奥威娜。', 247257, 1, 'Outsider found 找到外来者', 245114, 1, 'Vicious Saptor slain 击杀凶狠的迅叶龙', 246360, 1, 'Outsider directed to safety 外来者脱险', 253478, 1, 'Dalnir met at the Den 在铭记之穴见戴尼尔', 12299, 1, 24142, 1, 24141, 1, 0, 0, 0, 0, 0, 0);
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`) VALUES (90959, 90958);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `RewardText`, `VerifiedBuild`) VALUES (90959, 1, 'You did more than tradition asked. Thank you.$B$B你做的超出了传统的要求，谢谢你。', 0);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`, `VerifiedBuild`) VALUES (90959, 'Have you found the outsider? / 找到外来者了吗？', 0);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (245879, 90959);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (245881, 90959);
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `AllowableRaces`, `RewardXPDifficulty`, `RewardMoney`, `Flags`, `LogTitle`, `LogDescription`, `QuestDescription`, `QuestCompletionLog`, `RequiredNpcOrGo1`, `RequiredNpcOrGoCount1`, `ObjectiveText1`, `RequiredNpcOrGo2`, `RequiredNpcOrGoCount2`, `ObjectiveText2`, `RequiredNpcOrGo3`, `RequiredNpcOrGoCount3`, `ObjectiveText3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount4`, `ObjectiveText4`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`) VALUES
(90960, 2, -1, 1, 0, 6, 300, 0, 'My Story, My Legacy 我的故事，我的传承', 'Commune with the three legacy stones, then paint your own story. / 与三座传承石交感，然后绘下你自己的故事。', '$N, the final part of the ceremony is ahead of you.$B$BThe first stone shows a vision of your true self. The second shows where you are needed. The third breaks the barrier between us and the Goddess herself. The ceremony ends with you painting your story in the Den.$B$B$N，仪式的最后一段在等着你。$B$B第一块石头让你看见真正的自我，第二块告诉你何处需要你，第三块打破我们与女神之间的隔阂。最后，你要在洞穴里绘下自己的故事。', 'Speak with Hagar deep in the Den. / 到洞穴深处找哈加尔。', -554679, 1, 'True Self witnessed 见到真我', -546728, 1, 'True Calling witnessed 见到使命', -554848, 1, 'Goddess Guidance received 得到女神指引', -554966, 1, 'Legacy stone painted 绘制传承石', 20839, 1, 20835, 1, 20838, 1, 20836, 1, 20840, 1, 5579, 1);
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`) VALUES (90960, 90959);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `RewardText`, `VerifiedBuild`) VALUES (90960, 1, 'Your story is painted beside those who came before. Walk it well.$B$B你的故事已经画在先人们旁边了。好好走下去。', 0);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`, `VerifiedBuild`) VALUES (90960, 'The stones are waiting. / 石头在等你。', 0);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (245096, 90960);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (245097, 90960);
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`) VALUES
(90957, 0, 0, 12694, 20418, 0, 0, 1, 0),
(90957, 1, -1, 12694, 20418, 0, 0, 1, 0),
(90958, 0, 0, 12694, 20418, 0, 0, 1, 0),
(90958, 1, 1, 12694, 20418, 0, 0, 1, 0),
(90958, 2, 2, 12694, 20418, 0, 0, 1, 0),
(90958, 3, 3, 12694, 20418, 0, 0, 1, 0),
(90958, 4, -1, 12694, 20418, 0, 0, 1, 0),
(90959, 0, 0, 12694, 20418, 0, 0, 1, 0),
(90959, 1, 1, 12694, 20418, 0, 0, 1, 0),
(90959, 2, 2, 12694, 20418, 0, 0, 1, 0),
(90959, 3, 3, 12694, 20418, 0, 0, 1, 0),
(90959, 4, -1, 12694, 20418, 0, 0, 1, 0),
(90960, 0, 0, 12694, 20418, 0, 0, 1, 0),
(90960, 1, 1, 12694, 20418, 0, 0, 1, 0),
(90960, 2, 2, 12694, 20418, 0, 0, 1, 0),
(90960, 3, 3, 12694, 20418, 0, 0, 1, 0),
(90960, 4, -1, 12694, 20418, 0, 0, 1, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES
(90957, 0, 0, 1200, 767, 0),
(90957, 0, 1, 1320, 767, 0),
(90957, 0, 2, 1320, 887, 0),
(90957, 0, 3, 1200, 887, 0),
(90957, 1, 0, 1341, 900, 0),
(90957, 1, 1, 1357, 900, 0),
(90957, 1, 2, 1357, 916, 0),
(90957, 1, 3, 1341, 916, 0),
(90958, 0, 0, 1221, 796, 0),
(90958, 0, 1, 1341, 796, 0),
(90958, 0, 2, 1341, 916, 0),
(90958, 0, 3, 1221, 916, 0),
(90958, 1, 0, 1254, 854, 0),
(90958, 1, 1, 1374, 854, 0),
(90958, 1, 2, 1374, 974, 0),
(90958, 1, 3, 1254, 974, 0),
(90958, 2, 0, 1212, 804, 0),
(90958, 2, 1, 1332, 804, 0),
(90958, 2, 2, 1332, 924, 0),
(90958, 2, 3, 1212, 924, 0),
(90958, 3, 0, 1198, 798, 0),
(90958, 3, 1, 1318, 798, 0),
(90958, 3, 2, 1318, 918, 0),
(90958, 3, 3, 1198, 918, 0),
(90958, 4, 0, 1341, 900, 0),
(90958, 4, 1, 1357, 900, 0),
(90958, 4, 2, 1357, 916, 0),
(90958, 4, 3, 1341, 916, 0),
(90959, 0, 0, 1107, 875, 0),
(90959, 0, 1, 1123, 875, 0),
(90959, 0, 2, 1123, 891, 0),
(90959, 0, 3, 1107, 891, 0),
(90959, 1, 0, 1120, 871, 0),
(90959, 1, 1, 1152, 871, 0),
(90959, 1, 2, 1152, 903, 0),
(90959, 1, 3, 1120, 903, 0),
(90959, 2, 0, 1107, 875, 0),
(90959, 2, 1, 1123, 875, 0),
(90959, 2, 2, 1123, 891, 0),
(90959, 2, 3, 1107, 891, 0),
(90959, 3, 0, 1166, 996, 0),
(90959, 3, 1, 1182, 996, 0),
(90959, 3, 2, 1182, 1012, 0),
(90959, 3, 3, 1166, 1012, 0),
(90959, 4, 0, 1157, 994, 0),
(90959, 4, 1, 1173, 994, 0),
(90959, 4, 2, 1173, 1010, 0),
(90959, 4, 3, 1157, 1010, 0),
(90960, 0, 0, 1092, 1026, 0),
(90960, 0, 1, 1108, 1026, 0),
(90960, 0, 2, 1108, 1042, 0),
(90960, 0, 3, 1092, 1042, 0),
(90960, 1, 0, 1137, 1052, 0),
(90960, 1, 1, 1153, 1052, 0),
(90960, 1, 2, 1153, 1068, 0),
(90960, 1, 3, 1137, 1068, 0),
(90960, 2, 0, 1136, 1121, 0),
(90960, 2, 1, 1152, 1121, 0),
(90960, 2, 2, 1152, 1137, 0),
(90960, 2, 3, 1136, 1137, 0),
(90960, 3, 0, 1130, 1158, 0),
(90960, 3, 1, 1146, 1158, 0),
(90960, 3, 2, 1146, 1174, 0),
(90960, 3, 3, 1130, 1174, 0),
(90960, 4, 0, 1141, 1158, 0),
(90960, 4, 1, 1157, 1158, 0),
(90960, 4, 2, 1157, 1174, 0),
(90960, 4, 3, 1141, 1174, 0);
SELECT (SELECT COUNT(*) FROM `quest_template` WHERE `ID` IN (90957, 90958, 90959, 90960)) AS quests_must_be_4,
       (SELECT COUNT(*) FROM `creature_template` WHERE `entry` IN (245090, 245096, 245097, 245102, 245104, 245114, 245117, 245118, 245879, 245881, 246277, 246360, 246705, 247257, 248669, 253478)) AS creature_templates_must_be_16,
       (SELECT COUNT(*) FROM `creature` WHERE `Comment` LIKE 'HARA2 %' AND `Comment` NOT LIKE 'HARA2 mentor%') AS creature_spawns_must_be_67,
       (SELECT COUNT(*) FROM `creature` WHERE `Comment` LIKE 'HARA2 mentor%') AS mentor_spawns_expect_10_or_more,
       (SELECT COUNT(*) FROM `gameobject_template` WHERE `entry` IN (553763, 554679, 546728, 554848, 554966)) AS object_templates_must_be_5,
       (SELECT COUNT(*) FROM `gameobject` WHERE `Comment` LIKE 'HARA2 %') AS object_spawns_must_be_12,
       (SELECT COUNT(*) FROM `creature_model_info` WHERE `DisplayID` BETWEEN 710101 AND 710106) AS model_info_must_be_6,
       (SELECT COUNT(DISTINCT `Entry`) FROM `creature_loot_template` WHERE `Comment` LIKE 'HARA2 %') AS mobs_with_drops_expect_4;
