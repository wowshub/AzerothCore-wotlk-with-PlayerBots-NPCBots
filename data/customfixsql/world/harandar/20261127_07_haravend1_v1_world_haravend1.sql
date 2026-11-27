-- HARAVEND1 V1 (2026-11-26, Claude) - candidate, NOT user-tested. Stop worldserver, WORLD database, restart. Safe to run twice.
SET NAMES utf8mb4;
SET @spawn_limit := 16777215;
SELECT COUNT(DISTINCT `entry`) AS stock_vendor_lists_must_be_10 FROM `npc_vendor` WHERE `entry` IN (3588, 3609, 3610, 3611, 3612, 3613, 3608, 3614, 3589, 6736);
DELETE FROM `creature` WHERE `map` = 12694 AND `Comment` LIKE 'HARAVEND %';
DELETE FROM `creature_template` WHERE `entry` IN (252203, 252211, 258354);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (252203, 252211, 258354);
DELETE FROM `npc_vendor` WHERE `entry` IN (252203, 252211, 258354);
SELECT COALESCE(MAX(`guid`), 0) INTO @g FROM `creature` WHERE `guid` < @spawn_limit;
SELECT IF(@g + 10 + 10000 < @spawn_limit, 'guid base OK', 'ABORT: no guid room, do not continue') AS guid_check;
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `unit_class`, `unit_flags`, `type`, `AIName`, `MovementType`, `HealthModifier`, `DamageModifier`, `ExperienceModifier`, `RegenHealth`, `flags_extra`, `ScriptName`) VALUES
(252203, 'Al''luun 奥露恩', 'Weapons, Armor & Repairs 武器护甲与修理', 10, 10, 35, 4224, 1, 1.14286, 0, 1, 768, 7, '', 0, 3, 1, 0, 1, 2, '');
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (252203, 0, 1710, 1, 1, 0);
INSERT IGNORE INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`)
SELECT 252203, 0, `item`, `maxcount`, `incrtime`, `ExtendedCost`, 0 FROM `npc_vendor` WHERE `entry` IN (3588, 3609, 3610, 3611, 3612, 3613);
INSERT IGNORE INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`) VALUES (252203, 0, 2508, 0, 0, 0, 0), (252203, 0, 2509, 0, 0, 0, 0);
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES
(@g + 1, 252203, 12694, 1, 1, 0, 1272.00, 964.00, 1332.55, 3.90, 60, 0, 0, 'HARAVEND 252203');
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `unit_class`, `unit_flags`, `type`, `AIName`, `MovementType`, `HealthModifier`, `DamageModifier`, `ExperienceModifier`, `RegenHealth`, `flags_extra`, `ScriptName`) VALUES
(252211, 'Le''neia 勒奈亚', 'General Goods 杂货与弹药', 10, 10, 35, 128, 1, 1.14286, 0, 1, 768, 7, '', 0, 3, 1, 0, 1, 2, '');
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (252211, 0, 1700, 1, 1, 0);
INSERT IGNORE INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`)
SELECT 252211, 0, `item`, `maxcount`, `incrtime`, `ExtendedCost`, 0 FROM `npc_vendor` WHERE `entry` IN (3608, 3614, 3589);
INSERT IGNORE INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`) VALUES (252211, 0, 2512, 0, 0, 0, 0), (252211, 0, 2516, 0, 0, 0, 0);
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES
(@g + 2, 252211, 12694, 1, 1, 0, 1379.00, 923.00, 1346.25, 3.40, 60, 0, 0, 'HARAVEND 252211');
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `unit_class`, `unit_flags`, `type`, `AIName`, `MovementType`, `HealthModifier`, `DamageModifier`, `ExperienceModifier`, `RegenHealth`, `flags_extra`, `ScriptName`) VALUES
(258354, 'Gnu''la 格努菈', 'Innkeeper 旅店老板', 10, 10, 35, 65665, 1, 1.14286, 0, 1, 768, 7, '', 0, 3, 1, 0, 1, 2, '');
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (258354, 0, 4861, 1, 1, 0);
INSERT IGNORE INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`)
SELECT 258354, 0, `item`, `maxcount`, `incrtime`, `ExtendedCost`, 0 FROM `npc_vendor` WHERE `entry` IN (6736);
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES
(@g + 3, 258354, 12694, 1, 1, 0, 1372.00, 916.00, 1346.45, 3.10, 60, 0, 0, 'HARAVEND 258354');
SELECT (SELECT COUNT(*) FROM `creature_template` WHERE `entry` IN (252203, 252211, 258354)) AS merchants_must_be_3,
       (SELECT COUNT(*) FROM `creature` WHERE `Comment` LIKE 'HARAVEND %') AS spawns_must_be_3,
       (SELECT COUNT(*) FROM `npc_vendor` WHERE `entry` = 252203) AS weapons_armor_about_44,
       (SELECT COUNT(*) FROM `npc_vendor` WHERE `entry` = 252211) AS general_goods_about_33,
       (SELECT COUNT(*) FROM `npc_vendor` WHERE `entry` = 258354) AS innkeeper_about_12;
