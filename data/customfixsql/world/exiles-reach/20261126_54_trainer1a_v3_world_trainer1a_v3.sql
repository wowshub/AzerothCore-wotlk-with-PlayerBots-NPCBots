-- TRAINER1A V3 (2026-11-26, Claude) - candidate, NOT user-tested. Stop worldserver, run on the WORLD database, restart. Safe over V1 / V2.
-- Plain stock trainer mechanics, no script: one trainer creature per class on the same spot in front of the giant boar,
-- and a visibility condition so that every player sees only the mentor of his or her own class.
-- DELETE lua_scripts/RebornClassMentor.lua (V1 / V2 script) before starting the server.
SET NAMES utf8mb4;
SET @spawn_limit := 16777215;
DELETE FROM `creature` WHERE `map` = 12175 AND `Comment` LIKE 'TRAINER1A %';
DELETE FROM `conditions` WHERE `SourceTypeOrReferenceId` = 30 AND `SourceGroup` = 0 AND `SourceEntry` IN (9180201, 9180202, 9180203, 9180204, 9180205, 9180206, 9180207, 9180208, 9180209, 9180211, 9180213, 9180214, 9180215);
DELETE FROM `creature_default_trainer` WHERE `CreatureId` IN (9180001, 9180101, 9180102, 9180103, 9180104, 9180105, 9180106, 9180107, 9180108, 9180109, 9180111, 9180113, 9180114, 9180115, 9180201, 9180202, 9180203, 9180204, 9180205, 9180206, 9180207, 9180208, 9180209, 9180211, 9180213, 9180214, 9180215);
DELETE FROM `trainer_spell` WHERE `TrainerId` IN (901801, 901802, 901803, 901804, 901805, 901806, 901807, 901808, 901809, 901811);
DELETE FROM `trainer` WHERE `Id` IN (901801, 901802, 901803, 901804, 901805, 901806, 901807, 901808, 901809, 901811);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (9180001, 9180101, 9180102, 9180103, 9180104, 9180105, 9180106, 9180107, 9180108, 9180109, 9180111, 9180113, 9180114, 9180115, 9180201, 9180202, 9180203, 9180204, 9180205, 9180206, 9180207, 9180208, 9180209, 9180211, 9180213, 9180214, 9180215);
DELETE FROM `creature_template` WHERE `entry` IN (9180001, 9180101, 9180102, 9180103, 9180104, 9180105, 9180106, 9180107, 9180108, 9180109, 9180111, 9180113, 9180114, 9180115, 9180201, 9180202, 9180203, 9180204, 9180205, 9180206, 9180207, 9180208, 9180209, 9180211, 9180213, 9180214, 9180215);
SELECT COALESCE(MAX(`guid`), 0) INTO @g FROM `creature` WHERE `guid` < @spawn_limit;
SELECT IF(@g + 20 + 10000 < @spawn_limit, 'guid base OK', 'ABORT: no guid room, do not continue') AS guid_check, @g AS creature_max;

INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `unit_class`, `unit_flags`, `type`, `AIName`, `HealthModifier`, `DamageModifier`, `RegenHealth`, `flags_extra`, `ScriptName`) VALUES
(9180201, 'Warrior Mentor 战士导师', 'Class Skills 学习本职业技能', 60, 60, 35, 48, 1, 1.14286, 0, 1, 512, 7, '', 1, 1, 1, 2, ''),
(9180202, 'Paladin Mentor 圣骑士导师', 'Class Skills 学习本职业技能', 60, 60, 35, 48, 1, 1.14286, 0, 1, 512, 7, '', 1, 1, 1, 2, ''),
(9180203, 'Hunter Mentor 猎人导师', 'Class Skills 学习本职业技能', 60, 60, 35, 48, 1, 1.14286, 0, 1, 512, 7, '', 1, 1, 1, 2, ''),
(9180204, 'Rogue Mentor 潜行者导师', 'Class Skills 学习本职业技能', 60, 60, 35, 48, 1, 1.14286, 0, 1, 512, 7, '', 1, 1, 1, 2, ''),
(9180205, 'Priest Mentor 牧师导师', 'Class Skills 学习本职业技能', 60, 60, 35, 48, 1, 1.14286, 0, 1, 512, 7, '', 1, 1, 1, 2, ''),
(9180206, 'Death Knight Mentor 死亡骑士导师', 'Class Skills 学习本职业技能', 60, 60, 35, 48, 1, 1.14286, 0, 1, 512, 7, '', 1, 1, 1, 2, ''),
(9180207, 'Shaman Mentor 萨满导师', 'Class Skills 学习本职业技能', 60, 60, 35, 48, 1, 1.14286, 0, 1, 512, 7, '', 1, 1, 1, 2, ''),
(9180208, 'Mage Mentor 法师导师', 'Class Skills 学习本职业技能', 60, 60, 35, 48, 1, 1.14286, 0, 1, 512, 7, '', 1, 1, 1, 2, ''),
(9180209, 'Warlock Mentor 术士导师', 'Class Skills 学习本职业技能', 60, 60, 35, 48, 1, 1.14286, 0, 1, 512, 7, '', 1, 1, 1, 2, ''),
(9180211, 'Druid Mentor 德鲁伊导师', 'Class Skills 学习本职业技能', 60, 60, 35, 48, 1, 1.14286, 0, 1, 512, 7, '', 1, 1, 1, 2, ''),
(9180213, 'Witch Doctor Mentor 巫医导师', 'Class Skills 学习本职业技能', 60, 60, 35, 48, 1, 1.14286, 0, 1, 512, 7, '', 1, 1, 1, 2, ''),
(9180214, 'Monk Mentor 武僧导师', 'Class Skills 学习本职业技能', 60, 60, 35, 48, 1, 1.14286, 0, 1, 512, 7, '', 1, 1, 1, 2, ''),
(9180215, 'Witch Hunter Mentor 猎魔人导师', 'Class Skills 学习本职业技能', 60, 60, 35, 48, 1, 1.14286, 0, 1, 512, 7, '', 1, 1, 1, 2, '');
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(9180201, 0, 18921, 1, 1, 0),
(9180202, 0, 18921, 1, 1, 0),
(9180203, 0, 18921, 1, 1, 0),
(9180204, 0, 18921, 1, 1, 0),
(9180205, 0, 18921, 1, 1, 0),
(9180206, 0, 18921, 1, 1, 0),
(9180207, 0, 18921, 1, 1, 0),
(9180208, 0, 18921, 1, 1, 0),
(9180209, 0, 18921, 1, 1, 0),
(9180211, 0, 18921, 1, 1, 0),
(9180213, 0, 18921, 1, 1, 0),
(9180214, 0, 18921, 1, 1, 0),
(9180215, 0, 18921, 1, 1, 0);
INSERT INTO `conditions` (`SourceTypeOrReferenceId`, `SourceGroup`, `SourceEntry`, `SourceId`, `ElseGroup`, `ConditionTypeOrReference`, `ConditionTarget`, `ConditionValue1`, `ConditionValue2`, `ConditionValue3`, `NegativeCondition`, `ErrorType`, `ErrorTextId`, `ScriptName`, `Comment`) VALUES
(30, 0, 9180201, 0, 0, 15, 0, 1, 0, 0, 0, 0, 0, '', 'TRAINER1A mentor visible to class 1 only'),
(30, 0, 9180202, 0, 0, 15, 0, 2, 0, 0, 0, 0, 0, '', 'TRAINER1A mentor visible to class 2 only'),
(30, 0, 9180203, 0, 0, 15, 0, 4, 0, 0, 0, 0, 0, '', 'TRAINER1A mentor visible to class 3 only'),
(30, 0, 9180204, 0, 0, 15, 0, 8, 0, 0, 0, 0, 0, '', 'TRAINER1A mentor visible to class 4 only'),
(30, 0, 9180205, 0, 0, 15, 0, 16, 0, 0, 0, 0, 0, '', 'TRAINER1A mentor visible to class 5 only'),
(30, 0, 9180206, 0, 0, 15, 0, 32, 0, 0, 0, 0, 0, '', 'TRAINER1A mentor visible to class 6 only'),
(30, 0, 9180207, 0, 0, 15, 0, 64, 0, 0, 0, 0, 0, '', 'TRAINER1A mentor visible to class 7 only'),
(30, 0, 9180208, 0, 0, 15, 0, 128, 0, 0, 0, 0, 0, '', 'TRAINER1A mentor visible to class 8 only'),
(30, 0, 9180209, 0, 0, 15, 0, 256, 0, 0, 0, 0, 0, '', 'TRAINER1A mentor visible to class 9 only'),
(30, 0, 9180211, 0, 0, 15, 0, 1024, 0, 0, 0, 0, 0, '', 'TRAINER1A mentor visible to class 11 only'),
(30, 0, 9180213, 0, 0, 15, 0, 4096, 0, 0, 0, 0, 0, '', 'TRAINER1A mentor visible to class 13 only'),
(30, 0, 9180214, 0, 0, 15, 0, 8192, 0, 0, 0, 0, 0, '', 'TRAINER1A mentor visible to class 14 only'),
(30, 0, 9180215, 0, 0, 15, 0, 16384, 0, 0, 0, 0, 0, '', 'TRAINER1A mentor visible to class 15 only');

-- trainer lists: union of the stock class trainers (Type 0, same class, Id below 900000)
INSERT INTO `trainer` (`Id`, `Type`, `Requirement`, `Greeting`, `VerifiedBuild`) VALUES (901801, 0, 1, 'What would you like to learn? 想学点什么？', 0);
INSERT INTO `trainer_spell` (`TrainerId`, `SpellId`, `MoneyCost`, `ReqSkillLine`, `ReqSkillRank`, `ReqAbility1`, `ReqAbility2`, `ReqAbility3`, `ReqLevel`, `VerifiedBuild`)
SELECT 901801, s.`SpellId`, MIN(s.`MoneyCost`), MIN(s.`ReqSkillLine`), MIN(s.`ReqSkillRank`), MIN(s.`ReqAbility1`), MIN(s.`ReqAbility2`), MIN(s.`ReqAbility3`), MIN(s.`ReqLevel`), 0
FROM `trainer_spell` s JOIN `trainer` t ON t.`Id` = s.`TrainerId` WHERE t.`Type` = 0 AND t.`Requirement` = 1 AND t.`Id` < 900000 GROUP BY s.`SpellId`;
INSERT INTO `creature_default_trainer` (`CreatureId`, `TrainerId`) VALUES (9180201, 901801);
INSERT INTO `trainer` (`Id`, `Type`, `Requirement`, `Greeting`, `VerifiedBuild`) VALUES (901802, 0, 2, 'What would you like to learn? 想学点什么？', 0);
INSERT INTO `trainer_spell` (`TrainerId`, `SpellId`, `MoneyCost`, `ReqSkillLine`, `ReqSkillRank`, `ReqAbility1`, `ReqAbility2`, `ReqAbility3`, `ReqLevel`, `VerifiedBuild`)
SELECT 901802, s.`SpellId`, MIN(s.`MoneyCost`), MIN(s.`ReqSkillLine`), MIN(s.`ReqSkillRank`), MIN(s.`ReqAbility1`), MIN(s.`ReqAbility2`), MIN(s.`ReqAbility3`), MIN(s.`ReqLevel`), 0
FROM `trainer_spell` s JOIN `trainer` t ON t.`Id` = s.`TrainerId` WHERE t.`Type` = 0 AND t.`Requirement` = 2 AND t.`Id` < 900000 GROUP BY s.`SpellId`;
INSERT INTO `creature_default_trainer` (`CreatureId`, `TrainerId`) VALUES (9180202, 901802);
INSERT INTO `trainer` (`Id`, `Type`, `Requirement`, `Greeting`, `VerifiedBuild`) VALUES (901803, 0, 3, 'What would you like to learn? 想学点什么？', 0);
INSERT INTO `trainer_spell` (`TrainerId`, `SpellId`, `MoneyCost`, `ReqSkillLine`, `ReqSkillRank`, `ReqAbility1`, `ReqAbility2`, `ReqAbility3`, `ReqLevel`, `VerifiedBuild`)
SELECT 901803, s.`SpellId`, MIN(s.`MoneyCost`), MIN(s.`ReqSkillLine`), MIN(s.`ReqSkillRank`), MIN(s.`ReqAbility1`), MIN(s.`ReqAbility2`), MIN(s.`ReqAbility3`), MIN(s.`ReqLevel`), 0
FROM `trainer_spell` s JOIN `trainer` t ON t.`Id` = s.`TrainerId` WHERE t.`Type` = 0 AND t.`Requirement` = 3 AND t.`Id` < 900000 GROUP BY s.`SpellId`;
INSERT INTO `creature_default_trainer` (`CreatureId`, `TrainerId`) VALUES (9180203, 901803);
INSERT INTO `trainer` (`Id`, `Type`, `Requirement`, `Greeting`, `VerifiedBuild`) VALUES (901804, 0, 4, 'What would you like to learn? 想学点什么？', 0);
INSERT INTO `trainer_spell` (`TrainerId`, `SpellId`, `MoneyCost`, `ReqSkillLine`, `ReqSkillRank`, `ReqAbility1`, `ReqAbility2`, `ReqAbility3`, `ReqLevel`, `VerifiedBuild`)
SELECT 901804, s.`SpellId`, MIN(s.`MoneyCost`), MIN(s.`ReqSkillLine`), MIN(s.`ReqSkillRank`), MIN(s.`ReqAbility1`), MIN(s.`ReqAbility2`), MIN(s.`ReqAbility3`), MIN(s.`ReqLevel`), 0
FROM `trainer_spell` s JOIN `trainer` t ON t.`Id` = s.`TrainerId` WHERE t.`Type` = 0 AND t.`Requirement` = 4 AND t.`Id` < 900000 GROUP BY s.`SpellId`;
INSERT INTO `creature_default_trainer` (`CreatureId`, `TrainerId`) VALUES (9180204, 901804);
INSERT INTO `trainer` (`Id`, `Type`, `Requirement`, `Greeting`, `VerifiedBuild`) VALUES (901805, 0, 5, 'What would you like to learn? 想学点什么？', 0);
INSERT INTO `trainer_spell` (`TrainerId`, `SpellId`, `MoneyCost`, `ReqSkillLine`, `ReqSkillRank`, `ReqAbility1`, `ReqAbility2`, `ReqAbility3`, `ReqLevel`, `VerifiedBuild`)
SELECT 901805, s.`SpellId`, MIN(s.`MoneyCost`), MIN(s.`ReqSkillLine`), MIN(s.`ReqSkillRank`), MIN(s.`ReqAbility1`), MIN(s.`ReqAbility2`), MIN(s.`ReqAbility3`), MIN(s.`ReqLevel`), 0
FROM `trainer_spell` s JOIN `trainer` t ON t.`Id` = s.`TrainerId` WHERE t.`Type` = 0 AND t.`Requirement` = 5 AND t.`Id` < 900000 GROUP BY s.`SpellId`;
INSERT INTO `creature_default_trainer` (`CreatureId`, `TrainerId`) VALUES (9180205, 901805);
INSERT INTO `trainer` (`Id`, `Type`, `Requirement`, `Greeting`, `VerifiedBuild`) VALUES (901806, 0, 6, 'What would you like to learn? 想学点什么？', 0);
INSERT INTO `trainer_spell` (`TrainerId`, `SpellId`, `MoneyCost`, `ReqSkillLine`, `ReqSkillRank`, `ReqAbility1`, `ReqAbility2`, `ReqAbility3`, `ReqLevel`, `VerifiedBuild`)
SELECT 901806, s.`SpellId`, MIN(s.`MoneyCost`), MIN(s.`ReqSkillLine`), MIN(s.`ReqSkillRank`), MIN(s.`ReqAbility1`), MIN(s.`ReqAbility2`), MIN(s.`ReqAbility3`), MIN(s.`ReqLevel`), 0
FROM `trainer_spell` s JOIN `trainer` t ON t.`Id` = s.`TrainerId` WHERE t.`Type` = 0 AND t.`Requirement` = 6 AND t.`Id` < 900000 GROUP BY s.`SpellId`;
INSERT INTO `creature_default_trainer` (`CreatureId`, `TrainerId`) VALUES (9180206, 901806);
INSERT INTO `trainer` (`Id`, `Type`, `Requirement`, `Greeting`, `VerifiedBuild`) VALUES (901807, 0, 7, 'What would you like to learn? 想学点什么？', 0);
INSERT INTO `trainer_spell` (`TrainerId`, `SpellId`, `MoneyCost`, `ReqSkillLine`, `ReqSkillRank`, `ReqAbility1`, `ReqAbility2`, `ReqAbility3`, `ReqLevel`, `VerifiedBuild`)
SELECT 901807, s.`SpellId`, MIN(s.`MoneyCost`), MIN(s.`ReqSkillLine`), MIN(s.`ReqSkillRank`), MIN(s.`ReqAbility1`), MIN(s.`ReqAbility2`), MIN(s.`ReqAbility3`), MIN(s.`ReqLevel`), 0
FROM `trainer_spell` s JOIN `trainer` t ON t.`Id` = s.`TrainerId` WHERE t.`Type` = 0 AND t.`Requirement` = 7 AND t.`Id` < 900000 GROUP BY s.`SpellId`;
INSERT INTO `creature_default_trainer` (`CreatureId`, `TrainerId`) VALUES (9180207, 901807);
INSERT INTO `trainer` (`Id`, `Type`, `Requirement`, `Greeting`, `VerifiedBuild`) VALUES (901808, 0, 8, 'What would you like to learn? 想学点什么？', 0);
INSERT INTO `trainer_spell` (`TrainerId`, `SpellId`, `MoneyCost`, `ReqSkillLine`, `ReqSkillRank`, `ReqAbility1`, `ReqAbility2`, `ReqAbility3`, `ReqLevel`, `VerifiedBuild`)
SELECT 901808, s.`SpellId`, MIN(s.`MoneyCost`), MIN(s.`ReqSkillLine`), MIN(s.`ReqSkillRank`), MIN(s.`ReqAbility1`), MIN(s.`ReqAbility2`), MIN(s.`ReqAbility3`), MIN(s.`ReqLevel`), 0
FROM `trainer_spell` s JOIN `trainer` t ON t.`Id` = s.`TrainerId` WHERE t.`Type` = 0 AND t.`Requirement` = 8 AND t.`Id` < 900000 GROUP BY s.`SpellId`;
INSERT INTO `creature_default_trainer` (`CreatureId`, `TrainerId`) VALUES (9180208, 901808);
INSERT INTO `trainer` (`Id`, `Type`, `Requirement`, `Greeting`, `VerifiedBuild`) VALUES (901809, 0, 9, 'What would you like to learn? 想学点什么？', 0);
INSERT INTO `trainer_spell` (`TrainerId`, `SpellId`, `MoneyCost`, `ReqSkillLine`, `ReqSkillRank`, `ReqAbility1`, `ReqAbility2`, `ReqAbility3`, `ReqLevel`, `VerifiedBuild`)
SELECT 901809, s.`SpellId`, MIN(s.`MoneyCost`), MIN(s.`ReqSkillLine`), MIN(s.`ReqSkillRank`), MIN(s.`ReqAbility1`), MIN(s.`ReqAbility2`), MIN(s.`ReqAbility3`), MIN(s.`ReqLevel`), 0
FROM `trainer_spell` s JOIN `trainer` t ON t.`Id` = s.`TrainerId` WHERE t.`Type` = 0 AND t.`Requirement` = 9 AND t.`Id` < 900000 GROUP BY s.`SpellId`;
INSERT INTO `creature_default_trainer` (`CreatureId`, `TrainerId`) VALUES (9180209, 901809);
INSERT INTO `trainer` (`Id`, `Type`, `Requirement`, `Greeting`, `VerifiedBuild`) VALUES (901811, 0, 11, 'What would you like to learn? 想学点什么？', 0);
INSERT INTO `trainer_spell` (`TrainerId`, `SpellId`, `MoneyCost`, `ReqSkillLine`, `ReqSkillRank`, `ReqAbility1`, `ReqAbility2`, `ReqAbility3`, `ReqLevel`, `VerifiedBuild`)
SELECT 901811, s.`SpellId`, MIN(s.`MoneyCost`), MIN(s.`ReqSkillLine`), MIN(s.`ReqSkillRank`), MIN(s.`ReqAbility1`), MIN(s.`ReqAbility2`), MIN(s.`ReqAbility3`), MIN(s.`ReqLevel`), 0
FROM `trainer_spell` s JOIN `trainer` t ON t.`Id` = s.`TrainerId` WHERE t.`Type` = 0 AND t.`Requirement` = 11 AND t.`Id` < 900000 GROUP BY s.`SpellId`;
INSERT INTO `creature_default_trainer` (`CreatureId`, `TrainerId`) VALUES (9180211, 901811);

-- custom classes: the server's own largest trainer list of that class, if there is one
INSERT INTO `creature_default_trainer` (`CreatureId`, `TrainerId`)
SELECT 9180213, t.`Id` FROM `trainer` t JOIN `trainer_spell` s ON s.`TrainerId` = t.`Id` WHERE t.`Type` = 0 AND t.`Requirement` = 13 GROUP BY t.`Id` ORDER BY COUNT(*) DESC, t.`Id` LIMIT 1;
INSERT INTO `creature_default_trainer` (`CreatureId`, `TrainerId`)
SELECT 9180214, t.`Id` FROM `trainer` t JOIN `trainer_spell` s ON s.`TrainerId` = t.`Id` WHERE t.`Type` = 0 AND t.`Requirement` = 14 GROUP BY t.`Id` ORDER BY COUNT(*) DESC, t.`Id` LIMIT 1;
INSERT INTO `creature_default_trainer` (`CreatureId`, `TrainerId`)
SELECT 9180215, t.`Id` FROM `trainer` t JOIN `trainer_spell` s ON s.`TrainerId` = t.`Id` WHERE t.`Type` = 0 AND t.`Requirement` = 15 GROUP BY t.`Id` ORDER BY COUNT(*) DESC, t.`Id` LIMIT 1;

-- spawns on one spot, phase 3 = both factions
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES
(@g + 1, 9180201, 12175, 1, 3, 0, 117.9, -2406.65, 89.4, 3.74, 120, 0, 0, 'TRAINER1A mentor class 1'),
(@g + 2, 9180202, 12175, 1, 3, 0, 117.9, -2406.65, 89.4, 3.74, 120, 0, 0, 'TRAINER1A mentor class 2'),
(@g + 3, 9180203, 12175, 1, 3, 0, 117.9, -2406.65, 89.4, 3.74, 120, 0, 0, 'TRAINER1A mentor class 3'),
(@g + 4, 9180204, 12175, 1, 3, 0, 117.9, -2406.65, 89.4, 3.74, 120, 0, 0, 'TRAINER1A mentor class 4'),
(@g + 5, 9180205, 12175, 1, 3, 0, 117.9, -2406.65, 89.4, 3.74, 120, 0, 0, 'TRAINER1A mentor class 5'),
(@g + 6, 9180206, 12175, 1, 3, 0, 117.9, -2406.65, 89.4, 3.74, 120, 0, 0, 'TRAINER1A mentor class 6'),
(@g + 7, 9180207, 12175, 1, 3, 0, 117.9, -2406.65, 89.4, 3.74, 120, 0, 0, 'TRAINER1A mentor class 7'),
(@g + 8, 9180208, 12175, 1, 3, 0, 117.9, -2406.65, 89.4, 3.74, 120, 0, 0, 'TRAINER1A mentor class 8'),
(@g + 9, 9180209, 12175, 1, 3, 0, 117.9, -2406.65, 89.4, 3.74, 120, 0, 0, 'TRAINER1A mentor class 9'),
(@g + 10, 9180211, 12175, 1, 3, 0, 117.9, -2406.65, 89.4, 3.74, 120, 0, 0, 'TRAINER1A mentor class 11');
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`)
SELECT @g + 11, 9180213, 12175, 1, 3, 0, 117.9, -2406.65, 89.4, 3.74, 120, 0, 0, 'TRAINER1A mentor class 13' FROM `creature_default_trainer` WHERE `CreatureId` = 9180213;
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`)
SELECT @g + 12, 9180214, 12175, 1, 3, 0, 117.9, -2406.65, 89.4, 3.74, 120, 0, 0, 'TRAINER1A mentor class 14' FROM `creature_default_trainer` WHERE `CreatureId` = 9180214;
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`)
SELECT @g + 13, 9180215, 12175, 1, 3, 0, 117.9, -2406.65, 89.4, 3.74, 120, 0, 0, 'TRAINER1A mentor class 15' FROM `creature_default_trainer` WHERE `CreatureId` = 9180215;

SELECT (SELECT COUNT(*) FROM `creature_template` WHERE `entry` IN (9180201, 9180202, 9180203, 9180204, 9180205, 9180206, 9180207, 9180208, 9180209, 9180211, 9180213, 9180214, 9180215)) AS templates_must_be_13,
       (SELECT COUNT(*) FROM `conditions` WHERE `SourceTypeOrReferenceId` = 30 AND `SourceGroup` = 0 AND `SourceEntry` IN (9180201, 9180202, 9180203, 9180204, 9180205, 9180206, 9180207, 9180208, 9180209, 9180211, 9180213, 9180214, 9180215)) AS visibility_conditions_must_be_13,
       (SELECT COUNT(*) FROM `creature` WHERE `Comment` LIKE 'TRAINER1A %' AND `id1` BETWEEN 9180201 AND 9180211) AS classic_spawns_must_be_10,
       (SELECT COUNT(*) FROM `creature` WHERE `Comment` LIKE 'TRAINER1A %' AND `id1` BETWEEN 9180213 AND 9180215) AS custom_class_spawns_info_only,
       (SELECT COUNT(*) FROM `creature_template` WHERE `entry` IN (9180001, 9180101, 9180102, 9180103, 9180104, 9180105, 9180106, 9180107, 9180108, 9180109, 9180111, 9180113, 9180114, 9180115)) AS old_templates_must_be_0;
SELECT d.`CreatureId` - 9180200 AS class_id, d.`TrainerId`, COUNT(s.`SpellId`) AS spells, SUM(s.`ReqLevel` BETWEEN 1 AND 10) AS learnable_up_to_level_10
FROM `creature_default_trainer` d JOIN `trainer_spell` s ON s.`TrainerId` = d.`TrainerId`
WHERE d.`CreatureId` IN (9180201, 9180202, 9180203, 9180204, 9180205, 9180206, 9180207, 9180208, 9180209, 9180211, 9180213, 9180214, 9180215) GROUP BY d.`CreatureId`, d.`TrainerId` ORDER BY d.`CreatureId`;
