-- ALLY1E-M V1: Ralia (156929) and her escape mount (9167012) use the retail stag, creature display 710009. Needs ALLY1E and the server dbc rows. Safe to run twice.
DELETE FROM `creature_model_info` WHERE `DisplayID` = 710009;
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`) VALUES (710009, 0.6, 1.5, 1, 0);
UPDATE `creature_template_model` SET `CreatureDisplayID` = 710009, `DisplayScale` = 1 WHERE `CreatureID` IN (156929, 9167012) AND `Idx` = 0;
SELECT `CreatureID`, `CreatureDisplayID`, `DisplayScale` FROM `creature_template_model` WHERE `CreatureID` IN (156929, 9167012);
