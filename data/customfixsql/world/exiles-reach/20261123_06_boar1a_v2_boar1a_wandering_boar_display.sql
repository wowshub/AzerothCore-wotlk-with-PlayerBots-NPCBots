-- BOAR1A V2 (2026-11-23, Claude): Wandering Boar 156722 uses the retail giant boar model (creature display 710001).
-- V1 forgot creature_model_info: the server refused to load the creature ("No model data exist for CreatureDisplayID = 710001").
-- Safe to run twice.
DELETE FROM `creature_model_info` WHERE `DisplayID` = 710001;
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`, `VerifiedBuild`) VALUES (710001, 1.6, 3.0, 2, 0, 0);
UPDATE `creature_template_model` SET `CreatureDisplayID` = 710001, `DisplayScale` = 0.3 WHERE `CreatureID` = 156722;
SELECT `DisplayID`, `BoundingRadius`, `CombatReach` FROM `creature_model_info` WHERE `DisplayID` = 710001;
SELECT `CreatureID`, `CreatureDisplayID`, `DisplayScale` FROM `creature_template_model` WHERE `CreatureID` = 156722;
