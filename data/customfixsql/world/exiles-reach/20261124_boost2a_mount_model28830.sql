-- BOOST2A V1 (2026-11-24, Claude): taxi mount 9167010 goes back to display 28830 (the GnomeCopter look). The client model now has a rider attachment (id 0). Safe to run twice.
DELETE FROM `creature_template_model` WHERE `CreatureID` = 9167010;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (9167010, 0, 28830, 1, 1, 0);
SELECT `CreatureID`, `CreatureDisplayID` FROM `creature_template_model` WHERE `CreatureID` IN (9167010, 167027);
