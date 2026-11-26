-- ALLY1C V2: Scout-o-Matic 156518 uses display 28830 (GnomeCopter), like the Horde booster 167027. Safe to run twice.
UPDATE `creature_template_model` SET `CreatureDisplayID` = 28830 WHERE `CreatureID` = 156518 AND `Idx` = 0;
INSERT IGNORE INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`) VALUES (28830, 1, 1, 2, 0);
SELECT `CreatureID`, `CreatureDisplayID` FROM `creature_template_model` WHERE `CreatureID` IN (156518, 167027);
