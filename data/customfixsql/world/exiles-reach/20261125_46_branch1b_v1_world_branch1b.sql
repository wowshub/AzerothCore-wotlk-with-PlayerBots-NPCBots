-- BRANCH1B V1: Lightspawn 157114 uses the retail model as creature display 710003. Needs the server dbc rows of this package. Safe to run twice.
DELETE FROM `creature_model_info` WHERE `DisplayID` = 710003;
INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`) VALUES (710003, 0.6, 1.5, 2, 0);
UPDATE `creature_template_model` SET `CreatureDisplayID` = 710003, `DisplayScale` = 1 WHERE `CreatureID` = 157114;
SELECT `CreatureID`, `CreatureDisplayID`, `DisplayScale`,
       (SELECT COUNT(*) FROM `creature_model_info` WHERE `DisplayID` = 710003) AS model_info_must_be_1
FROM `creature_template_model` WHERE `CreatureID` = 157114;
