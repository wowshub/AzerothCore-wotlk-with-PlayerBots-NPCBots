-- BEAR1A V1 (2026-11-25, Claude): Killclaw 153266 uses the retail Killclaw bear model (creature display 710002), drawn 1.8x = a giant bear.
-- Needs the client + SERVER dbc rows and the client aliases of this package. Recipe of the accepted BOAR1A V2. Safe to run twice. Needs BRANCH1A.
DELETE FROM `creature_model_info` WHERE `DisplayID` = 710002;
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`, `VerifiedBuild`) VALUES (710002, 1.6, 3.0, 2, 0, 0);
UPDATE `creature_template_model` SET `CreatureDisplayID` = 710002, `DisplayScale` = 1.8 WHERE `CreatureID` = 153266;
SELECT `DisplayID`, `BoundingRadius`, `CombatReach` FROM `creature_model_info` WHERE `DisplayID` = 710002;
SELECT `CreatureID`, `CreatureDisplayID`, `DisplayScale` FROM `creature_template_model` WHERE `CreatureID` = 153266;
