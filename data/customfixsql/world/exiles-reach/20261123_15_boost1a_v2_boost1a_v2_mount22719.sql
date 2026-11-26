-- BOOST1A V2 (2026-11-24, Claude): taxi mount creature 9167010 uses display 22719 (stock "Flying Machine" mount gyrocopter, creature 24653) instead of 28830 (GnomeCopter, no rider seat).
-- The Booster NPC 167027 keeps the GnomeCopter look (28830). Safe to run twice.
DELETE FROM `creature_template_model` WHERE `CreatureID` = 9167010;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (9167010, 0, 22719, 1, 1, 0);
INSERT IGNORE INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`) VALUES (22719, 1, 1, 2, 0);
SELECT `CreatureID`, `CreatureDisplayID` FROM `creature_template_model` WHERE `CreatureID` IN (9167010, 167027);
