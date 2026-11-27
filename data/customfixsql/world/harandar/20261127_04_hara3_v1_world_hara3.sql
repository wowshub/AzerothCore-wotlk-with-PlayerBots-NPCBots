-- HARA3 V1 (2026-11-26, Claude) - candidate, NOT user-tested. Stop worldserver, run on the WORLD database, restart. Safe to run twice.
-- Needs HARA2 V1 + V2 and the accepted island loot (LOOT1A V2). Rerunning HARA2 V1 resets the lasher credit: run this file again afterwards.
SET NAMES utf8mb4;
SET @spawn_limit := 16777215;
SELECT (SELECT COUNT(*) FROM `quest_template` WHERE `ID` = 90960) AS hara2_quest_must_be_1,
       (SELECT COUNT(*) FROM `creature_template` WHERE `entry` IN (245097, 245102, 245879, 248669)) AS hara2_npcs_must_be_4;
DELETE FROM `creature` WHERE `map` = 12694 AND `Comment` LIKE 'HARA3 %';
DELETE FROM `creature_template` WHERE `entry` IN (237036, 237623, 240344, 240656, 240871, 248493);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (237036, 237623, 240344, 240656, 240871, 248493);
DELETE FROM `creature_loot_template` WHERE `Comment` LIKE 'HARA3 %';
DELETE FROM `smart_scripts` WHERE `source_type` = 0 AND `entryorguid` IN (237036, 237623, 240344, 240656, 240871, 248493);
DELETE FROM `creature_model_info` WHERE `DisplayID` BETWEEN 710121 AND 710137;
DELETE FROM `quest_template` WHERE `ID` IN (9190001, 9190002, 9190003, 9190004, 9190005, 9190006);
DELETE FROM `quest_template_addon` WHERE `ID` IN (9190001, 9190002, 9190003, 9190004, 9190005, 9190006);
DELETE FROM `quest_offer_reward` WHERE `ID` IN (9190001, 9190002, 9190003, 9190004, 9190005, 9190006);
DELETE FROM `quest_request_items` WHERE `ID` IN (9190001, 9190002, 9190003, 9190004, 9190005, 9190006);
DELETE FROM `quest_poi` WHERE `QuestID` IN (9190001, 9190002, 9190003, 9190004, 9190005, 9190006);
DELETE FROM `quest_poi_points` WHERE `QuestID` IN (9190001, 9190002, 9190003, 9190004, 9190005, 9190006);
DELETE FROM `creature_queststarter` WHERE `quest` IN (9190001, 9190002, 9190003, 9190004, 9190005, 9190006);
DELETE FROM `creature_questender` WHERE `quest` IN (9190001, 9190002, 9190003, 9190004, 9190005, 9190006);
UPDATE `creature_template` SET `KillCredit1` = 0 WHERE `entry` = 248669;
SELECT COALESCE(MAX(`guid`), 0) INTO @g FROM `creature` WHERE `guid` < @spawn_limit;
SELECT IF(@g + 200 + 10000 < @spawn_limit, 'guid base OK', 'ABORT: no guid room, do not continue') AS guid_check, @g AS creature_max;
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `unit_class`, `unit_flags`, `type`, `AIName`, `MovementType`, `HealthModifier`, `DamageModifier`, `ExperienceModifier`, `RegenHealth`, `flags_extra`, `ScriptName`, `mingold`, `maxgold`) VALUES
(237036, 'Lashroom Bud 鞭笞菇幼芽', NULL, 4, 4, 7, 0, 1, 1.14286, 0, 1, 0, 8, '', 0, 1.0, 0.7, 2, 1, 0, '', 6, 20),
(237623, 'Hungry Rotling 饥饿的小腐菌', NULL, 4, 4, 7, 0, 1, 1.14286, 0, 1, 0, 4, '', 1, 1.0, 0.8, 2, 1, 0, '', 6, 20),
(240344, 'Lightbloom Grovewarden 光绽林莽守卫', NULL, 6, 6, 7, 0, 1, 1.14286, 0, 1, 0, 7, '', 1, 1.1, 0.9, 2, 1, 0, '', 10, 35),
(240656, 'Lightbloom Sap Weaver 光绽树脂编织者', NULL, 6, 6, 7, 0, 1, 1.14286, 0, 8, 0, 7, 'SmartAI', 1, 1.0, 0.8, 2, 1, 0, '', 10, 35),
(240871, 'Swiftsting 迅针', NULL, 5, 5, 7, 0, 1, 1.14286, 0, 1, 0, 1, '', 1, 0.9, 0.8, 2, 1, 0, '', 8, 28),
(248493, 'Lasher 鞭笞者', NULL, 5, 5, 7, 0, 1, 1.14286, 0, 1, 0, 4, '', 1, 1.0, 0.8, 2, 1, 0, '', 8, 28);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(237036, 0, 710121, 1.0, 1, 0),
(237036, 1, 710122, 1.0, 1, 0),
(237036, 2, 710123, 1.0, 1, 0),
(237036, 3, 710124, 1.0, 1, 0),
(237623, 0, 710125, 1.0, 1, 0),
(237623, 1, 710126, 1.0, 1, 0),
(237623, 2, 710127, 1.0, 1, 0),
(237623, 3, 710128, 1.0, 1, 0),
(240344, 0, 710129, 1.0, 1, 0),
(240656, 0, 710130, 1.0, 1, 0),
(240871, 0, 710131, 2.0, 1, 0),
(240871, 1, 710132, 2.0, 1, 0),
(240871, 2, 710133, 2.0, 1, 0),
(240871, 3, 710134, 2.0, 1, 0),
(248493, 0, 710135, 0.4, 1, 0),
(248493, 1, 710136, 0.4, 1, 0),
(248493, 2, 710137, 0.4, 1, 0);
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`) VALUES
(710121, 0.500, 1.200, 2, 0),
(710122, 0.500, 1.200, 2, 0),
(710123, 0.500, 1.200, 2, 0),
(710124, 0.500, 1.200, 2, 0),
(710125, 0.500, 1.100, 2, 0),
(710126, 0.500, 1.100, 2, 0),
(710127, 0.500, 1.100, 2, 0),
(710128, 0.500, 1.100, 2, 0),
(710129, 0.500, 1.600, 2, 0),
(710130, 0.400, 1.500, 2, 0),
(710131, 0.200, 0.500, 2, 0),
(710132, 0.200, 0.500, 2, 0),
(710133, 0.200, 0.500, 2, 0),
(710134, 0.200, 0.500, 2, 0),
(710135, 1.250, 2.750, 2, 0),
(710136, 1.250, 2.750, 2, 0),
(710137, 1.250, 2.750, 2, 0);
-- withered lashers (HARA2) also count for "Creeping Lashers"
UPDATE `creature_template` SET `KillCredit1` = 248493 WHERE `entry` = 248669;
-- the sap weaver casts Wrath (9739, damage scales down with the creature level) and closes in when out of mana
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `action_type`, `action_param1`, `action_param2`, `target_type`, `comment`)
VALUES (240656, 0, 0, 0, 0, 0, 100, 0, 0, 1000, 3500, 5000, 11, 9739, 64, 2, 'Lightbloom Sap Weaver - In Combat - Cast Wrath');
-- drops: junk copied from accepted island rows (level 4 also their starter gear), level 5-6 get the next gear band
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT 237036, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, 'HARA3 copy of 160394' FROM `creature_loot_template` WHERE `Entry` = 160394 AND `Comment` LIKE 'LOOT1A %' AND `QuestRequired` = 0;
UPDATE `creature_template` SET `lootid` = 237036 WHERE `entry` = 237036 AND EXISTS (SELECT 1 FROM `creature_loot_template` WHERE `Entry` = 237036);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT 237623, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, 'HARA3 copy of 160394' FROM `creature_loot_template` WHERE `Entry` = 160394 AND `Comment` LIKE 'LOOT1A %' AND `QuestRequired` = 0;
UPDATE `creature_template` SET `lootid` = 237623 WHERE `entry` = 237623 AND EXISTS (SELECT 1 FROM `creature_loot_template` WHERE `Entry` = 237623);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT 240344, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, 'HARA3 copy of 150238' FROM `creature_loot_template` WHERE `Entry` = 150238 AND `Comment` LIKE 'LOOT1A %' AND `QuestRequired` = 0 AND `Comment` NOT LIKE '%初始装备';
INSERT IGNORE INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(240344, 792, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240344, 793, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240344, 794, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240344, 795, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240344, 796, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240344, 797, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240344, 798, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240344, 799, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240344, 1839, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240344, 1840, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240344, 2364, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240344, 2366, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240344, 2367, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240344, 2369, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240344, 2370, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240344, 2371, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240344, 2372, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240344, 2373, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240344, 2374, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240344, 2375, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240344, 2392, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240344, 2393, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240344, 2394, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240344, 2395, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240344, 2396, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240344, 2397, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240344, 2398, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240344, 2399, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240344, 2400, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240344, 2401, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240344, 2402, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240344, 2403, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240344, 3602, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240344, 3603, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240344, 3606, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240344, 3607, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240344, 17186, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240344, 767, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240344, 768, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240344, 781, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240344, 2065, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240344, 2066, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240344, 2258, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240344, 2259, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240344, 2488, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240344, 2491, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240344, 2493, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240344, 2494, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240344, 2495, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240344, 2497, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240344, 2498, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240344, 2499, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240344, 2501, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240344, 2503, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240344, 2506, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240344, 2509, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240344, 2844, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240344, 3189, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240344, 3190, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240344, 3225, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240344, 4302, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240344, 7955, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240344, 8181, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear');
UPDATE `creature_template` SET `lootid` = 240344 WHERE `entry` = 240344 AND EXISTS (SELECT 1 FROM `creature_loot_template` WHERE `Entry` = 240344);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT 240656, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, 'HARA3 copy of 150238' FROM `creature_loot_template` WHERE `Entry` = 150238 AND `Comment` LIKE 'LOOT1A %' AND `QuestRequired` = 0 AND `Comment` NOT LIKE '%初始装备';
INSERT IGNORE INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(240656, 792, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240656, 793, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240656, 794, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240656, 795, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240656, 796, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240656, 797, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240656, 798, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240656, 799, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240656, 1839, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240656, 1840, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240656, 2364, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240656, 2366, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240656, 2367, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240656, 2369, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240656, 2370, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240656, 2371, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240656, 2372, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240656, 2373, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240656, 2374, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240656, 2375, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240656, 2392, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240656, 2393, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240656, 2394, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240656, 2395, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240656, 2396, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240656, 2397, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240656, 2398, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240656, 2399, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240656, 2400, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240656, 2401, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240656, 2402, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240656, 2403, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240656, 3602, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240656, 3603, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240656, 3606, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240656, 3607, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240656, 17186, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240656, 767, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240656, 768, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240656, 781, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240656, 2065, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240656, 2066, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240656, 2258, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240656, 2259, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240656, 2488, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240656, 2491, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240656, 2493, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240656, 2494, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240656, 2495, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240656, 2497, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240656, 2498, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240656, 2499, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240656, 2501, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240656, 2503, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240656, 2506, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240656, 2509, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240656, 2844, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240656, 3189, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240656, 3190, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240656, 3225, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240656, 4302, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240656, 7955, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240656, 8181, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear');
UPDATE `creature_template` SET `lootid` = 240656 WHERE `entry` = 240656 AND EXISTS (SELECT 1 FROM `creature_loot_template` WHERE `Entry` = 240656);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT 240871, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, 'HARA3 copy of 160394' FROM `creature_loot_template` WHERE `Entry` = 160394 AND `Comment` LIKE 'LOOT1A %' AND `QuestRequired` = 0 AND `Comment` NOT LIKE '%初始装备';
INSERT IGNORE INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(240871, 792, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240871, 793, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240871, 794, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240871, 795, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240871, 796, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240871, 797, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240871, 798, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240871, 799, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240871, 1839, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240871, 1840, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240871, 2364, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240871, 2366, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240871, 2367, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240871, 2369, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240871, 2370, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240871, 2371, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240871, 2372, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240871, 2373, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240871, 2374, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240871, 2375, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240871, 2392, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240871, 2393, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240871, 2394, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240871, 2395, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240871, 2396, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240871, 2397, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240871, 2398, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240871, 2399, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240871, 2400, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240871, 2401, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240871, 2402, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240871, 2403, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240871, 3602, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240871, 3603, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240871, 3606, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240871, 3607, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240871, 17186, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(240871, 767, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240871, 768, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240871, 781, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240871, 2065, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240871, 2066, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240871, 2258, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240871, 2259, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240871, 2488, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240871, 2491, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240871, 2493, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240871, 2494, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240871, 2495, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240871, 2497, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240871, 2498, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240871, 2499, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240871, 2501, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240871, 2503, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240871, 2506, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240871, 2509, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240871, 2844, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240871, 3189, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240871, 3190, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240871, 3225, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240871, 4302, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240871, 7955, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(240871, 8181, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear');
UPDATE `creature_template` SET `lootid` = 240871 WHERE `entry` = 240871 AND EXISTS (SELECT 1 FROM `creature_loot_template` WHERE `Entry` = 240871);
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT 248493, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, 'HARA3 copy of 160394' FROM `creature_loot_template` WHERE `Entry` = 160394 AND `Comment` LIKE 'LOOT1A %' AND `QuestRequired` = 0 AND `Comment` NOT LIKE '%初始装备';
INSERT IGNORE INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES
(248493, 792, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(248493, 793, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(248493, 794, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(248493, 795, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(248493, 796, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(248493, 797, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(248493, 798, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(248493, 799, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(248493, 1839, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(248493, 1840, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(248493, 2364, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(248493, 2366, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(248493, 2367, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(248493, 2369, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(248493, 2370, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(248493, 2371, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(248493, 2372, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(248493, 2373, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(248493, 2374, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(248493, 2375, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(248493, 2392, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(248493, 2393, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(248493, 2394, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(248493, 2395, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(248493, 2396, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(248493, 2397, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(248493, 2398, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(248493, 2399, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(248493, 2400, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(248493, 2401, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(248493, 2402, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(248493, 2403, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(248493, 3602, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(248493, 3603, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(248493, 3606, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(248493, 3607, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(248493, 17186, 0, 0.5946, 0, 1, 8, 1, 1, 'HARA3 gear'),
(248493, 767, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(248493, 768, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(248493, 781, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(248493, 2065, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(248493, 2066, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(248493, 2258, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(248493, 2259, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(248493, 2488, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(248493, 2491, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(248493, 2493, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(248493, 2494, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(248493, 2495, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(248493, 2497, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(248493, 2498, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(248493, 2499, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(248493, 2501, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(248493, 2503, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(248493, 2506, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(248493, 2509, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(248493, 2844, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(248493, 3189, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(248493, 3190, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(248493, 3225, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(248493, 4302, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(248493, 7955, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear'),
(248493, 8181, 0, 0.2308, 0, 1, 9, 1, 1, 'HARA3 gear');
UPDATE `creature_template` SET `lootid` = 248493 WHERE `entry` = 248493 AND EXISTS (SELECT 1 FROM `creature_loot_template` WHERE `Entry` = 248493);
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES
(@g + 1, 237036, 12694, 1, 1, 0, 1343.26, 895.33, 1345.38, 4.02, 45, 0, 0, 'HARA3 237036'),
(@g + 2, 237036, 12694, 1, 1, 0, 1333.16, 895.33, 1346.37, 4.02, 45, 0, 0, 'HARA3 237036'),
(@g + 3, 237036, 12694, 1, 1, 0, 1265.10, 837.77, 1332.69, 4.02, 45, 0, 0, 'HARA3 237036'),
(@g + 4, 237036, 12694, 1, 1, 0, 1224.72, 762.04, 1329.98, 4.02, 45, 0, 0, 'HARA3 237036'),
(@g + 5, 237036, 12694, 1, 1, 0, 1255.01, 731.75, 1331.23, 4.02, 45, 0, 0, 'HARA3 237036'),
(@g + 6, 237036, 12694, 1, 1, 0, 1270.55, 756.59, 1331.64, 1.92, 45, 0, 0, 'HARA3 237036'),
(@g + 7, 237036, 12694, 1, 1, 0, 1309.36, 796.24, 1333.23, 1.40, 45, 0, 0, 'HARA3 237036'),
(@g + 8, 237036, 12694, 1, 1, 0, 1293.72, 849.12, 1330.96, 0.77, 45, 0, 0, 'HARA3 237036'),
(@g + 9, 237036, 12694, 1, 1, 0, 1204.94, 862.66, 1330.91, 2.59, 45, 0, 0, 'HARA3 237036'),
(@g + 10, 237036, 12694, 1, 1, 0, 1201.17, 875.21, 1331.97, 2.59, 45, 0, 0, 'HARA3 237036'),
(@g + 11, 237036, 12694, 1, 1, 0, 1195.53, 901.01, 1332.60, 1.96, 45, 0, 0, 'HARA3 237036'),
(@g + 12, 237036, 12694, 1, 1, 0, 1195.45, 806.25, 1332.55, 3.76, 45, 0, 0, 'HARA3 237036'),
(@g + 13, 237623, 12694, 1, 1, 0, 1204.53, 989.23, 1328.27, 4.02, 45, 6, 1, 'HARA3 237623'),
(@g + 14, 237623, 12694, 1, 1, 0, 1137.26, 962.88, 1345.64, 3.08, 45, 6, 1, 'HARA3 237623'),
(@g + 15, 237623, 12694, 1, 1, 0, 1209.43, 906.65, 1329.17, 3.89, 45, 6, 1, 'HARA3 237623'),
(@g + 16, 237623, 12694, 1, 1, 0, 1355.97, 898.35, 1345.71, 4.02, 45, 6, 1, 'HARA3 237623'),
(@g + 17, 237623, 12694, 1, 1, 0, 1268.13, 850.30, 1329.50, 4.02, 45, 6, 1, 'HARA3 237623'),
(@g + 18, 237623, 12694, 1, 1, 0, 1295.39, 822.62, 1332.57, 4.02, 45, 6, 1, 'HARA3 237623'),
(@g + 19, 237623, 12694, 1, 1, 0, 1174.24, 792.33, 1334.13, 4.02, 45, 6, 1, 'HARA3 237623'),
(@g + 20, 237623, 12694, 1, 1, 0, 1214.62, 746.90, 1331.51, 4.02, 45, 6, 1, 'HARA3 237623'),
(@g + 21, 237623, 12694, 1, 1, 0, 1234.82, 701.46, 1337.81, 4.02, 45, 6, 1, 'HARA3 237623'),
(@g + 22, 237623, 12694, 1, 1, 0, 1129.06, 966.58, 1345.80, 3.08, 45, 6, 1, 'HARA3 237623'),
(@g + 23, 237623, 12694, 1, 1, 0, 1348.66, 893.11, 1345.41, 4.02, 45, 6, 1, 'HARA3 237623'),
(@g + 24, 237623, 12694, 1, 1, 0, 1256.90, 856.63, 1328.71, 4.02, 45, 6, 1, 'HARA3 237623'),
(@g + 25, 240344, 12694, 1, 1, 0, 1353.36, 895.33, 1345.78, 4.02, 45, 3, 1, 'HARA3 240344'),
(@g + 26, 240344, 12694, 1, 1, 0, 1337.08, 894.58, 1346.16, 4.02, 45, 3, 1, 'HARA3 240344'),
(@g + 27, 240344, 12694, 1, 1, 0, 1197.46, 895.74, 1332.45, 4.02, 45, 3, 1, 'HARA3 240344'),
(@g + 28, 240344, 12694, 1, 1, 0, 1233.20, 838.83, 1328.67, 1.20, 45, 3, 1, 'HARA3 240344'),
(@g + 29, 240344, 12694, 1, 1, 0, 1200.94, 811.33, 1331.56, 3.33, 45, 3, 1, 'HARA3 240344'),
(@g + 30, 240344, 12694, 1, 1, 0, 1237.51, 802.36, 1328.57, 2.73, 45, 3, 1, 'HARA3 240344'),
(@g + 31, 240344, 12694, 1, 1, 0, 1236.01, 798.94, 1328.62, 2.73, 45, 3, 1, 'HARA3 240344'),
(@g + 32, 240344, 12694, 1, 1, 0, 1325.68, 731.75, 1336.32, 4.02, 45, 3, 1, 'HARA3 240344'),
(@g + 33, 240344, 12694, 1, 1, 0, 1214.62, 701.46, 1336.85, 4.02, 45, 3, 1, 'HARA3 240344'),
(@g + 34, 240344, 12694, 1, 1, 0, 1234.26, 858.79, 1328.55, 0.21, 45, 3, 1, 'HARA3 240344'),
(@g + 35, 240656, 12694, 1, 1, 0, 1194.43, 1004.38, 1335.01, 4.02, 45, 3, 1, 'HARA3 240656'),
(@g + 36, 240656, 12694, 1, 1, 0, 1164.15, 837.77, 1335.35, 4.02, 45, 3, 1, 'HARA3 240656'),
(@g + 37, 240656, 12694, 1, 1, 0, 1279.80, 812.30, 1330.95, 6.04, 45, 3, 1, 'HARA3 240656'),
(@g + 38, 240656, 12694, 1, 1, 0, 1214.62, 777.19, 1330.42, 4.02, 45, 3, 1, 'HARA3 240656'),
(@g + 39, 240656, 12694, 1, 1, 0, 1274.45, 758.11, 1331.89, 4.02, 45, 3, 1, 'HARA3 240656'),
(@g + 40, 240656, 12694, 1, 1, 0, 1234.82, 716.60, 1333.93, 4.02, 45, 3, 1, 'HARA3 240656'),
(@g + 41, 240656, 12694, 1, 1, 0, 1190.72, 996.18, 1334.40, 4.02, 45, 3, 1, 'HARA3 240656'),
(@g + 42, 240656, 12694, 1, 1, 0, 1156.84, 832.52, 1336.33, 4.02, 45, 3, 1, 'HARA3 240656'),
(@g + 43, 240656, 12694, 1, 1, 0, 1271.60, 816.01, 1331.24, 6.04, 45, 3, 1, 'HARA3 240656'),
(@g + 44, 240871, 12694, 1, 1, 0, 1275.20, 822.62, 1331.82, 4.02, 45, 6, 1, 'HARA3 240871'),
(@g + 45, 240871, 12694, 1, 1, 0, 1265.10, 807.48, 1330.96, 4.02, 45, 6, 1, 'HARA3 240871'),
(@g + 46, 240871, 12694, 1, 1, 0, 1224.72, 777.19, 1329.79, 4.02, 45, 6, 1, 'HARA3 240871'),
(@g + 47, 240871, 12694, 1, 1, 0, 1267.00, 826.33, 1332.69, 4.02, 45, 6, 1, 'HARA3 240871'),
(@g + 48, 240871, 12694, 1, 1, 0, 1256.90, 811.19, 1331.15, 4.02, 45, 6, 1, 'HARA3 240871'),
(@g + 49, 240871, 12694, 1, 1, 0, 1217.41, 771.94, 1329.56, 4.02, 45, 6, 1, 'HARA3 240871'),
(@g + 50, 240871, 12694, 1, 1, 0, 1287.19, 822.11, 1331.91, 4.02, 45, 6, 1, 'HARA3 240871'),
(@g + 51, 240871, 12694, 1, 1, 0, 1275.23, 801.04, 1330.68, 4.02, 45, 6, 1, 'HARA3 240871'),
(@g + 52, 240871, 12694, 1, 1, 0, 1234.85, 770.75, 1331.05, 4.02, 45, 6, 1, 'HARA3 240871'),
(@g + 53, 248493, 12694, 1, 1, 0, 1214.62, 883.21, 1331.33, 4.02, 45, 5, 1, 'HARA3 248493'),
(@g + 54, 248493, 12694, 1, 1, 0, 1315.58, 792.33, 1333.12, 4.02, 45, 5, 1, 'HARA3 248493'),
(@g + 55, 248493, 12694, 1, 1, 0, 1204.53, 777.19, 1330.02, 4.02, 45, 5, 1, 'HARA3 248493'),
(@g + 56, 248493, 12694, 1, 1, 0, 1206.42, 886.92, 1332.15, 4.02, 45, 5, 1, 'HARA3 248493'),
(@g + 57, 248493, 12694, 1, 1, 0, 1306.62, 791.45, 1333.25, 4.02, 45, 5, 1, 'HARA3 248493'),
(@g + 58, 248493, 12694, 1, 1, 0, 1196.33, 780.90, 1329.68, 4.02, 45, 5, 1, 'HARA3 248493'),
(@g + 59, 248493, 12694, 1, 1, 0, 1209.07, 893.85, 1330.52, 4.02, 45, 5, 1, 'HARA3 248493'),
(@g + 60, 248493, 12694, 1, 1, 0, 1305.45, 798.77, 1333.91, 4.02, 45, 5, 1, 'HARA3 248493');
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `AllowableRaces`, `RewardXPDifficulty`, `RewardMoney`, `Flags`, `LogTitle`, `LogDescription`, `QuestDescription`, `QuestCompletionLog`, `RewardItem1`, `RewardAmount1`, `RequiredNpcOrGo1`, `RequiredNpcOrGoCount1`, `ObjectiveText1`, `RequiredNpcOrGo2`, `RequiredNpcOrGoCount2`, `ObjectiveText2`, `RequiredNpcOrGo3`, `RequiredNpcOrGoCount3`, `ObjectiveText3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount4`, `ObjectiveText4`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`) VALUES
(9190001, 2, -1, 1, 0, 6, 350, 0, 'Lashroom Sprouts 菇房的幼苗', 'Cut back 8 Lashroom Buds on your way to Root Tender Dalnir. / 在回去找根须照料者戴尼尔的路上，清掉8株鞭笞菇幼芽。', 'Your story is painted, $N, and a painted haranir does not rest long. Lashroom buds are crowding the roots below Har''mara. Dalnir has asked for hands. Cut the buds back, then report to Dalnir.$B$B$N，你的故事已经画下，而画过故事的哈籁尼尔人不会闲太久。哈尔玛拉下方的根须被鞭笞菇幼芽挤满了，戴尼尔正缺人手。清掉一些，然后去向戴尼尔报到。', 'Report to Dalnir in Har''mara. / 回哈尔玛拉向戴尼尔报到。', 0, 0, 237036, 8, 'Lashroom Bud slain 清除鞭笞菇幼芽', 0, 0, '', 0, 0, '', 0, 0, '', 4663, 1, 4666, 1, 15472, 1, 0, 0, 0, 0, 0, 0);
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`) VALUES (9190001, 90960);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `RewardText`, `VerifiedBuild`) VALUES (9190001, 1, 'So Hagar sent you. Good. The roots south of us feel lighter already.$B$B是哈加尔让你来的吧。很好，南边的根须已经轻松多了。', 0);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`, `VerifiedBuild`) VALUES (9190001, 'The buds are still spreading. / 幼芽还在蔓延。', 0);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (245097, 9190001);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (245102, 9190001);
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `AllowableRaces`, `RewardXPDifficulty`, `RewardMoney`, `Flags`, `LogTitle`, `LogDescription`, `QuestDescription`, `QuestCompletionLog`, `RewardItem1`, `RewardAmount1`, `RequiredNpcOrGo1`, `RequiredNpcOrGoCount1`, `ObjectiveText1`, `RequiredNpcOrGo2`, `RequiredNpcOrGoCount2`, `ObjectiveText2`, `RequiredNpcOrGo3`, `RequiredNpcOrGoCount3`, `ObjectiveText3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount4`, `ObjectiveText4`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`) VALUES
(9190002, 2, -1, 1, 0, 6, 400, 0, 'Hungry Rot 饥饿的小腐菌', 'Destroy 8 Hungry Rotlings. / 消灭8只饥饿的小腐菌。', 'Where lashrooms grow, rotlings wake. They eat what the roots need. Thin their numbers before they grow bold.$B$B鞭笞菇长到哪里，小腐菌就醒到哪里。它们啃食根须赖以生存的东西。趁它们还没胆大起来，减少它们的数量。', 'Return to Dalnir. / 回去找戴尼尔。', 0, 0, 237623, 8, 'Hungry Rotling slain 消灭饥饿的小腐菌', 0, 0, '', 0, 0, '', 0, 0, '', 3642, 1, 7277, 1, 3214, 1, 0, 0, 0, 0, 0, 0);
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`) VALUES (9190002, 9190001);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `RewardText`, `VerifiedBuild`) VALUES (9190002, 1, 'Well done. Rot has its place, but not on a living root.$B$B干得好。腐烂自有它的位置，但不该在活着的根须上。', 0);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`, `VerifiedBuild`) VALUES (9190002, 'The rotlings are still feeding. / 小腐菌还在啃食。', 0);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (245102, 9190002);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (245102, 9190002);
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `AllowableRaces`, `RewardXPDifficulty`, `RewardMoney`, `Flags`, `LogTitle`, `LogDescription`, `QuestDescription`, `QuestCompletionLog`, `RewardItem1`, `RewardAmount1`, `RequiredNpcOrGo1`, `RequiredNpcOrGoCount1`, `ObjectiveText1`, `RequiredNpcOrGo2`, `RequiredNpcOrGoCount2`, `ObjectiveText2`, `RequiredNpcOrGo3`, `RequiredNpcOrGoCount3`, `ObjectiveText3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount4`, `ObjectiveText4`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`) VALUES
(9190003, 2, -1, 1, 0, 6, 450, 0, 'Stingers in the Grove 林间的毒刺', 'Slay 6 Swiftstings south of the village. / 消灭村子南边的6只迅针。', 'The tenders who go south come back covered in stings. The swiftstings have nested near the low grove. Clear them out.$B$B去南边的照料者回来时满身蜇伤。迅针在低处的树丛附近筑了巢，把它们清掉。', 'Return to Dalnir. / 回去找戴尼尔。', 0, 0, 240871, 6, 'Swiftsting slain 消灭迅针', 0, 0, '', 0, 0, '', 0, 0, '', 2958, 1, 2962, 1, 2966, 1, 0, 0, 0, 0, 0, 0);
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`) VALUES (9190003, 9190002);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `RewardText`, `VerifiedBuild`) VALUES (9190003, 1, 'The tenders will thank you, and so will their ankles.$B$B照料者们会感谢你的，他们的脚踝也一样。', 0);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`, `VerifiedBuild`) VALUES (9190003, 'I can still hear them buzzing. / 我还能听见它们嗡嗡叫。', 0);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (245102, 9190003);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (245102, 9190003);
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `AllowableRaces`, `RewardXPDifficulty`, `RewardMoney`, `Flags`, `LogTitle`, `LogDescription`, `QuestDescription`, `QuestCompletionLog`, `RewardItem1`, `RewardAmount1`, `RequiredNpcOrGo1`, `RequiredNpcOrGoCount1`, `ObjectiveText1`, `RequiredNpcOrGo2`, `RequiredNpcOrGoCount2`, `ObjectiveText2`, `RequiredNpcOrGo3`, `RequiredNpcOrGoCount3`, `ObjectiveText3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount4`, `ObjectiveText4`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`) VALUES
(9190004, 2, -1, 1, 0, 7, 500, 0, 'Creeping Lashers 蔓生的鞭藤', 'Slay 8 lashers (withered ones count too). / 消灭8株鞭笞者(枯萎的也算)。', 'The lashers have crept further than I have ever seen. Something to the south is driving them toward us. Cut them down, then we will find out what.$B$B鞭笞者蔓延得比我见过的任何时候都远。南边有什么东西正把它们往我们这边赶。先砍掉它们，再查明原因。', 'Return to Dalnir. / 回去找戴尼尔。', 4671, 1, 248493, 8, 'Lasher slain 消灭鞭笞者', 0, 0, '', 0, 0, '', 0, 0, '', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`) VALUES (9190004, 9190003);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `RewardText`, `VerifiedBuild`) VALUES (9190004, 1, 'Take this cloak. Orweyna has news from the south, and you will want to be dressed for it.$B$B拿上这件斗篷。奥威娜带来了南边的消息，你得穿戴好再去。', 0);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`, `VerifiedBuild`) VALUES (9190004, 'The lashers still creep. / 鞭笞者还在蔓延。', 0);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (245102, 9190004);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (245102, 9190004);
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `AllowableRaces`, `RewardXPDifficulty`, `RewardMoney`, `Flags`, `LogTitle`, `LogDescription`, `QuestDescription`, `QuestCompletionLog`, `RewardItem1`, `RewardAmount1`, `RequiredNpcOrGo1`, `RequiredNpcOrGoCount1`, `ObjectiveText1`, `RequiredNpcOrGo2`, `RequiredNpcOrGoCount2`, `ObjectiveText2`, `RequiredNpcOrGo3`, `RequiredNpcOrGoCount3`, `ObjectiveText3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount4`, `ObjectiveText4`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`) VALUES
(9190005, 2, -1, 1, 0, 7, 600, 0, 'Wardens of the Lightbloom 光绽林莽守卫', 'Drive back 8 Lightbloom Grovewardens. / 击退8名光绽林莽守卫。', 'Now we know what drives the lashers. The Lightbloom has sent wardens into our grove, and they plant as they walk. Drive them back.$B$B现在知道是什么在驱赶鞭笞者了。光绽派守卫进了我们的树丛，他们走到哪里就种到哪里。把他们赶回去。', 'Return to Orweyna. / 回去找奥威娜。', 0, 0, 240344, 8, 'Lightbloom Grovewarden slain 击退光绽林莽守卫', 0, 0, '', 0, 0, '', 0, 0, '', 2572, 1, 4861, 1, 2965, 1, 0, 0, 0, 0, 0, 0);
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`) VALUES (9190005, 9190004);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `RewardText`, `VerifiedBuild`) VALUES (9190005, 1, 'They will think twice before walking here again.$B$B他们下次再想走进这里，得掂量掂量了。', 0);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`, `VerifiedBuild`) VALUES (9190005, 'Their blooms are still among our roots. / 他们的花还开在我们的根须间。', 0);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (245879, 9190005);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (245879, 9190005);
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `AllowableRaces`, `RewardXPDifficulty`, `RewardMoney`, `Flags`, `LogTitle`, `LogDescription`, `QuestDescription`, `QuestCompletionLog`, `RewardItem1`, `RewardAmount1`, `RequiredNpcOrGo1`, `RequiredNpcOrGoCount1`, `ObjectiveText1`, `RequiredNpcOrGo2`, `RequiredNpcOrGoCount2`, `ObjectiveText2`, `RequiredNpcOrGo3`, `RequiredNpcOrGoCount3`, `ObjectiveText3`, `RequiredNpcOrGo4`, `RequiredNpcOrGoCount4`, `ObjectiveText4`, `RewardChoiceItemID1`, `RewardChoiceItemQuantity1`, `RewardChoiceItemID2`, `RewardChoiceItemQuantity2`, `RewardChoiceItemID3`, `RewardChoiceItemQuantity3`, `RewardChoiceItemID4`, `RewardChoiceItemQuantity4`, `RewardChoiceItemID5`, `RewardChoiceItemQuantity5`, `RewardChoiceItemID6`, `RewardChoiceItemQuantity6`) VALUES
(9190006, 2, -1, 1, 0, 7, 700, 0, 'Sap Weavers 树脂编织者', 'Slay 6 Lightbloom Sap Weavers. / 消灭6名光绽树脂编织者。', 'The wardens are only the hands. The sap weavers twist our own trees against us. Silence them, $N.$B$B守卫只是手脚。树脂编织者扭曲我们自己的树木来对付我们。让他们住手，$N。', 'Return to Orweyna. / 回去找奥威娜。', 0, 0, 240656, 6, 'Lightbloom Sap Weaver slain 消灭树脂编织者', 0, 0, '', 0, 0, '', 0, 0, '', 1917, 1, 2281, 1, 3223, 1, 2268, 1, 2067, 1, 4763, 1);
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`) VALUES (9190006, 9190005);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `RewardText`, `VerifiedBuild`) VALUES (9190006, 1, 'The sap runs clean again. You have walked your story well. Choose your weapon, for harder days are close.$B$B树液又清澈了。你把自己的故事走得很好。挑一件武器吧，更艰难的日子快到了。', 0);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`, `VerifiedBuild`) VALUES (9190006, 'The weaving continues. / 编织还在继续。', 0);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (245879, 9190006);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (245879, 9190006);
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`) VALUES
(9190001, 0, 0, 12694, 20418, 0, 0, 1, 0),
(9190001, 1, -1, 12694, 20418, 0, 0, 1, 0),
(9190002, 0, 0, 12694, 20418, 0, 0, 1, 0),
(9190002, 1, -1, 12694, 20418, 0, 0, 1, 0),
(9190003, 0, 0, 12694, 20418, 0, 0, 1, 0),
(9190003, 1, -1, 12694, 20418, 0, 0, 1, 0),
(9190004, 0, 0, 12694, 20418, 0, 0, 1, 0),
(9190004, 1, -1, 12694, 20418, 0, 0, 1, 0),
(9190005, 0, 0, 12694, 20418, 0, 0, 1, 0),
(9190005, 1, -1, 12694, 20418, 0, 0, 1, 0),
(9190006, 0, 0, 12694, 20418, 0, 0, 1, 0),
(9190006, 1, -1, 12694, 20418, 0, 0, 1, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES
(9190001, 0, 0, 1198, 771, 0),
(9190001, 0, 1, 1318, 771, 0),
(9190001, 0, 2, 1318, 891, 0),
(9190001, 0, 3, 1198, 891, 0),
(9190001, 1, 0, 1341, 900, 0),
(9190001, 1, 1, 1357, 900, 0),
(9190001, 1, 2, 1357, 916, 0),
(9190001, 1, 3, 1341, 916, 0),
(9190002, 0, 0, 1176, 806, 0),
(9190002, 0, 1, 1296, 806, 0),
(9190002, 0, 2, 1296, 926, 0),
(9190002, 0, 3, 1176, 926, 0),
(9190002, 1, 0, 1341, 900, 0),
(9190002, 1, 1, 1357, 900, 0),
(9190002, 1, 2, 1357, 916, 0),
(9190002, 1, 3, 1341, 916, 0),
(9190003, 0, 0, 1208, 753, 0),
(9190003, 0, 1, 1304, 753, 0),
(9190003, 0, 2, 1304, 850, 0),
(9190003, 0, 3, 1208, 850, 0),
(9190003, 1, 0, 1341, 900, 0),
(9190003, 1, 1, 1357, 900, 0),
(9190003, 1, 2, 1357, 916, 0),
(9190003, 1, 3, 1341, 916, 0),
(9190004, 0, 0, 1185, 766, 0),
(9190004, 0, 1, 1305, 766, 0),
(9190004, 0, 2, 1305, 886, 0),
(9190004, 0, 3, 1185, 886, 0),
(9190004, 1, 0, 1341, 900, 0),
(9190004, 1, 1, 1357, 900, 0),
(9190004, 1, 2, 1357, 916, 0),
(9190004, 1, 3, 1341, 916, 0),
(9190005, 0, 0, 1197, 763, 0),
(9190005, 0, 1, 1317, 763, 0),
(9190005, 0, 2, 1317, 883, 0),
(9190005, 0, 3, 1197, 883, 0),
(9190005, 1, 0, 1331, 897, 0),
(9190005, 1, 1, 1347, 897, 0),
(9190005, 1, 2, 1347, 913, 0),
(9190005, 1, 3, 1331, 913, 0),
(9190006, 0, 0, 1160, 779, 0),
(9190006, 0, 1, 1280, 779, 0),
(9190006, 0, 2, 1280, 899, 0),
(9190006, 0, 3, 1160, 899, 0),
(9190006, 1, 0, 1331, 897, 0),
(9190006, 1, 1, 1347, 897, 0),
(9190006, 1, 2, 1347, 913, 0),
(9190006, 1, 3, 1331, 913, 0);
SELECT (SELECT COUNT(*) FROM `quest_template` WHERE `ID` IN (9190001, 9190002, 9190003, 9190004, 9190005, 9190006)) AS quests_must_be_6,
       (SELECT COUNT(*) FROM `creature_template` WHERE `entry` IN (237036, 237623, 240344, 240656, 240871, 248493)) AS creature_templates_must_be_6,
       (SELECT COUNT(*) FROM `creature` WHERE `Comment` LIKE 'HARA3 %') AS creature_spawns_must_be_60,
       (SELECT COUNT(*) FROM `creature_model_info` WHERE `DisplayID` BETWEEN 710121 AND 710137) AS model_info_must_be_17,
       (SELECT COUNT(DISTINCT `Entry`) FROM `creature_loot_template` WHERE `Comment` LIKE 'HARA3 %') AS mobs_with_drops_must_be_6,
       (SELECT `KillCredit1` FROM `creature_template` WHERE `entry` = 248669) AS lasher_credit_must_be_248493,
       (SELECT COUNT(*) FROM `smart_scripts` WHERE `entryorguid` = 240656 AND `source_type` = 0) AS caster_script_must_be_1;
