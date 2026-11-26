-- ALLY1C V3: vehicle 9167021 = retail giant boar (display 710001), seat of stock vehicle 29 (rider on the M2 mount point), stomp 51493. Safe to run twice.
SELECT COUNT(*) AS vehicle_template_must_be_1 FROM `creature_template` WHERE `entry` = 9167021;
UPDATE `creature_template` SET `VehicleId` = 29, `speed_run` = 1.71429 WHERE `entry` = 9167021;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 9167021;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (9167021, 0, 710001, 0.7, 1, 0);
DELETE FROM `creature_template_spell` WHERE `CreatureID` = 9167021;
INSERT INTO `creature_template_spell` (`CreatureID`, `Index`, `Spell`, `VerifiedBuild`) VALUES (9167021, 0, 51493, 0);
DELETE FROM `npc_spellclick_spells` WHERE `npc_entry` = 9167021;
INSERT INTO `npc_spellclick_spells` (`npc_entry`, `spell_id`, `cast_flags`, `user_type`) VALUES (9167021, 46598, 1, 0);
SELECT t.`VehicleId`, m.`CreatureDisplayID`, m.`DisplayScale`, s.`Spell`, c.`spell_id` AS click_spell,
       (SELECT COUNT(*) FROM `creature_model_info` WHERE `DisplayID` = m.`CreatureDisplayID`) AS model_info_must_be_1,
       (SELECT COUNT(*) FROM `creature` WHERE `id1` = 9167021) AS spawned_must_be_1
FROM `creature_template` t
JOIN `creature_template_model` m ON m.`CreatureID` = t.`entry`
JOIN `creature_template_spell` s ON s.`CreatureID` = t.`entry`
JOIN `npc_spellclick_spells` c ON c.`npc_entry` = t.`entry`
WHERE t.`entry` = 9167021;
