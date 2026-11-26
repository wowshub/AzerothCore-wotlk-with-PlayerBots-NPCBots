-- MODEL1A V1: retail models for harpy / Bloodbeak / Jaina / Wrathion. Needs the server dbc rows of this package. Safe to run twice.
SELECT COUNT(*) AS model_rows_before_must_be_14 FROM `creature_template_model` WHERE `CreatureID` IN (152843, 153964, 156280, 156626, 156651, 156807, 9156280, 156859, 156887, 167290, 156799, 167128, 167631, 9167675) AND `Idx` = 0;
DELETE FROM `creature_model_info` WHERE `DisplayID` BETWEEN 710004 AND 710008;
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`) VALUES (710004, 0.5, 1.5, 1, 0);
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`) VALUES (710005, 1.5, 5, 2, 0);
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`) VALUES (710006, 0.383, 1.5, 1, 0);
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`) VALUES (710007, 0.383, 1.5, 0, 0);
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`) VALUES (710008, 0.383, 1.5, 0, 0);
UPDATE `creature_template_model` SET `CreatureDisplayID` = 710004, `DisplayScale` = 1 WHERE `CreatureID` IN (152843) AND `Idx` = 0;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 710005, `DisplayScale` = 0.5 WHERE `CreatureID` IN (153964) AND `Idx` = 0;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 710006, `DisplayScale` = 1 WHERE `CreatureID` IN (156280, 156626, 156651, 156807, 9156280) AND `Idx` = 0;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 710007, `DisplayScale` = 1 WHERE `CreatureID` IN (156859, 156887, 167290) AND `Idx` = 0;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 710007, `DisplayScale` = 1.25 WHERE `CreatureID` IN (156799, 167128, 167631) AND `Idx` = 0;
UPDATE `creature_template_model` SET `CreatureDisplayID` = 710008, `DisplayScale` = 1 WHERE `CreatureID` IN (9167675) AND `Idx` = 0;
SELECT `CreatureDisplayID`, COUNT(*) AS npcs FROM `creature_template_model` WHERE `CreatureID` IN (152843, 153964, 156280, 156626, 156651, 156807, 9156280, 156859, 156887, 167290, 156799, 167128, 167631, 9167675) AND `Idx` = 0 GROUP BY `CreatureDisplayID` ORDER BY `CreatureDisplayID`;
SELECT COUNT(*) AS model_info_must_be_5 FROM `creature_model_info` WHERE `DisplayID` BETWEEN 710004 AND 710008;
