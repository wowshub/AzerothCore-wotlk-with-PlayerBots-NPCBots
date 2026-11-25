-- BOOST1A V1 (2026-11-23, Claude): taxi mount creature 9167010 (gnome copter, stock display 28830) for the scouting flight of quest 59940;
-- the Booster NPC 167027 also uses the copter model. Safe to run twice.
DELETE FROM `creature_template` WHERE `entry` = 9167010;
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `unit_class`, `unit_flags`, `type`, `AIName`, `HealthModifier`, `DamageModifier`, `RegenHealth`, `flags_extra`, `ScriptName`)
VALUES (9167010, 'Choppy Booster Mk. 5 (flight) 斩切者助推器5型(飞行)', NULL, 1, 1, 35, 0, 1, 1.14286, 0, 1, 0, 9, '', 1, 1, 1, 0, '');
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (9167010, 167027);
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(9167010, 0, 28830, 1, 1, 0),
(167027, 0, 28830, 1, 1, 0);
INSERT IGNORE INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`) VALUES (28830, 1, 1, 2, 0);
SELECT `entry`, `name` FROM `creature_template` WHERE `entry` IN (9167010, 167027);
SELECT * FROM `creature_template_model` WHERE `CreatureID` IN (9167010, 167027);
