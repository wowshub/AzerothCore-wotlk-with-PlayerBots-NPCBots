-- VEH3A V1: Horde vehicle 9167020 = retail giant boar (display 710001), seat of stock vehicle 29, stomp 51493. Same setup as the accepted Alliance ALLY1C V3. Safe to run twice.
SET NAMES utf8mb4;
SELECT COUNT(*) AS vehicle_template_must_be_1 FROM `creature_template` WHERE `entry` = 9167020;
UPDATE `creature_template` SET `name` = 'Scientifically Enhanced Boar 科学强化野猪', `VehicleId` = 29, `speed_run` = 1.71429 WHERE `entry` = 9167020;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 9167020;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (9167020, 0, 710001, 0.7, 1, 0);
DELETE FROM `creature_template_spell` WHERE `CreatureID` = 9167020;
INSERT INTO `creature_template_spell` (`CreatureID`, `Index`, `Spell`, `VerifiedBuild`) VALUES (9167020, 0, 51493, 0);
DELETE FROM `npc_spellclick_spells` WHERE `npc_entry` = 9167020;
INSERT INTO `npc_spellclick_spells` (`npc_entry`, `spell_id`, `cast_flags`, `user_type`) VALUES (9167020, 46598, 1, 0);
UPDATE `quest_template` SET `LogDescription` = 'Ride the giant boar and trample 6 Monstrous Cadavers, then slay Torgok. / 骑上巨型野猪踩死6个巨大的尸骸，再击杀托戈克。' WHERE `ID` = 59942;
UPDATE `quest_template` SET `QuestDescription` = REPLACE(`QuestDescription`, 'ride the Choppy Booster Mk. 5 and BLAST those walkin'' cadavers from the sky!', 'ride a scientifically enhanced boar and STOMP those walkin'' cadavers flat!') WHERE `ID` = 59942;
UPDATE `quest_template` SET `QuestDescription` = REPLACE(`QuestDescription`, 'Anyway, hop on the Choppy Booster Mk. 5 and I''ll pilot it.', 'Anyway, hop on the boar and hold on tight.') WHERE `ID` = 59942;
UPDATE `quest_template` SET `QuestDescription` = REPLACE(`QuestDescription`, 'we''ll blast our way to all the other survivors!', 'we''ll trample our way to all the other survivors!') WHERE `ID` = 59942;
UPDATE `quest_template` SET `QuestDescription` = REPLACE(`QuestDescription`, '你骑着斩切者助推器5型，从天上把那些行走的尸骸轰成渣！', '你骑上科学强化过的野猪，把那些行走的尸骸踩扁！') WHERE `ID` = 59942;
UPDATE `quest_template` SET `QuestDescription` = REPLACE(`QuestDescription`, '总之，跳上斩切者助推器5型，我来驾驶。', '总之，跳上野猪，抓稳了。') WHERE `ID` = 59942;
UPDATE `quest_template` SET `QuestDescription` = REPLACE(`QuestDescription`, '我们就一路轰开', '我们就一路踩过去') WHERE `ID` = 59942;
SELECT t.`VehicleId`, m.`CreatureDisplayID`, m.`DisplayScale`, s.`Spell`, c.`spell_id` AS click_spell,
       (SELECT COUNT(*) FROM `creature_model_info` WHERE `DisplayID` = 710001) AS model_info_must_be_1,
       (SELECT COUNT(*) FROM `creature` WHERE `id1` = 9167020) AS spawned_must_be_1
FROM `creature_template` t
JOIN `creature_template_model` m ON m.`CreatureID` = t.`entry`
JOIN `creature_template_spell` s ON s.`CreatureID` = t.`entry`
JOIN `npc_spellclick_spells` c ON c.`npc_entry` = t.`entry`
WHERE t.`entry` = 9167020;
