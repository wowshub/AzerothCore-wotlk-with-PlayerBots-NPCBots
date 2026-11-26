-- DARK3F V1 (2026-11-25, Claude) - candidate, NOT user-tested. Needs DARK1A and DARK2A applied. Stop worldserver, run on the world database, restart.
-- 1) The credit creatures 244389 (59985) and 9100210 (59978) were never created, so the core dropped those quest objectives
--    (Errors.log: "Quest 59985 has RequiredNpcOrGo1 = 244389 but creature with entry 244389 does not exist"). They are created here.
-- 2) DARK2B again (59985 text without Dragon Isles, Wrathion in Orgrimmar ends it); the DARK2A SQL had overwritten it.
-- 3) Map markers for 59985: Kalecgos on the island, Wrathion in Orgrimmar.
-- Safe to run twice.

DELETE FROM `creature_template` WHERE `entry` IN (244389, 9100210);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (244389, 9100210);
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `unit_class`, `unit_flags`, `type`, `AIName`, `HealthModifier`, `DamageModifier`, `RegenHealth`, `flags_extra`, `ScriptName`) VALUES
(244389, 'Credit: travel to Orgrimmar', NULL, 1, 1, 35, 0, 1, 1.14286, 0, 1, 33554432, 10, '', 1, 1, 1, 128, ''),
(9100210, 'Credit: citadel entrance', NULL, 1, 1, 35, 0, 1, 1.14286, 0, 1, 33554432, 10, '', 1, 1, 1, 128, '');
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(244389, 0, 11686, 1, 1, 0), (9100210, 0, 11686, 1, 1, 0);
UPDATE `quest_template` SET `RequiredNpcOrGo1` = 244389, `RequiredNpcOrGoCount1` = 1 WHERE `ID` = 59985;
UPDATE `quest_template` SET `RequiredNpcOrGo4` = 9100210, `RequiredNpcOrGoCount4` = 1 WHERE `ID` = 59978;

-- ===================== DARK2B (unchanged copy) =====================
-- DARK2B V1 (2026-11-25, Claude) - candidate, NOT user-tested. Builds on DARK2A V1 (must be applied first).
-- User: quest 59985 must not talk about the Dragon Isles; after Kalecgos sends you to Orgrimmar an NPC there should end the quest.
--   * 59985 text rewritten (no Dragon Isles); completion log now says to report to Wrathion in Orgrimmar.
--   * New turn-in NPC in Orgrimmar (Grommash Hold, map 1): Wrathion 9167675 (display 15511), replaces stock Thrall 4949 as the ender.
-- Safe to run twice. Keep worldserver stopped, restart after.
SET @spawn_limit := 16777215;

DELETE FROM `creature` WHERE `map` = 1 AND `Comment` LIKE 'DARK2B %';
DELETE FROM `creature_template` WHERE `entry` = 9167675;
DELETE FROM `creature_template_model` WHERE `CreatureID` = 9167675;
SELECT COALESCE(MAX(`guid`), 0) INTO @g FROM `creature` WHERE `guid` < @spawn_limit;
SELECT IF(@g + 5 + 10000 < @spawn_limit, 'guid base OK', 'ABORT: no guid room, do not continue') AS guid_check, @g AS creature_max;
SELECT COUNT(*) AS quest_59985_must_be_1 FROM `quest_template` WHERE `ID` = 59985;

INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `unit_class`, `unit_flags`, `type`, `AIName`, `HealthModifier`, `DamageModifier`, `RegenHealth`, `flags_extra`, `ScriptName`) VALUES
(9167675, 'Wrathion 瑞斯拉克', 'Black Dragonflight 黑龙军团', 80, 80, 35, 2, 1, 1.14286, 0, 1, 0, 7, '', 3, 1, 1, 0, '');
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (9167675, 0, 15511, 1, 1, 0);
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES
(@g + 1, 9167675, 1, 1, 1, 0, 1637.0, -4442.0, 15.8, 3.0, 120, 0, 0, 'DARK2B Wrathion in Orgrimmar');

-- quest text without the Dragon Isles
UPDATE `quest_template` SET
  `LogDescription` = 'Speak with Kalecgos to leave the citadel, then report to Wrathion in Orgrimmar. / 和卡雷苟斯说话离开要塞，再到奥格瑞玛向瑞斯拉克复命。',
  `QuestDescription` = 'You''ve done well here, $n. Kalecgos is going to see Wrathion and the Horde leaders in Orgrimmar.$B$BI must return there too. This shadow magic is concerning... and requires that I look into it more.$B$BTalk with Kalecgos. He will take you to Orgrimmar.$B$B你在这里干得很好，$n。卡雷苟斯要去奥格瑞玛见瑞斯拉克和部落的领袖们。$B$B我也必须回那里去。这种暗影魔法令人担忧……需要进一步调查。$B$B去和卡雷苟斯谈谈，他会带你去奥格瑞玛。',
  `QuestCompletionLog` = 'Report to Wrathion in Orgrimmar. / 到奥格瑞玛向瑞斯拉克复命。',
  `ObjectiveText1` = 'Speak to Kalecgos to travel to Orgrimmar / 和卡雷苟斯说话前往奥格瑞玛'
WHERE `ID` = 59985;
UPDATE `quest_offer_reward` SET `RewardText` = 'Wrathion: So you are the one who stopped Gor''groth. Welcome to Orgrimmar, $n. Your journey has only begun.$B$B瑞斯拉克：原来阻止戈尔格罗斯的就是你。欢迎来到奥格瑞玛，$n。你的旅程才刚刚开始。' WHERE `ID` = 59985;
UPDATE `quest_request_items` SET `CompletionText` = 'Welcome to Orgrimmar.$B$B欢迎来到奥格瑞玛。' WHERE `ID` = 59985;
DELETE FROM `creature_questender` WHERE `quest` = 59985;
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (9167675, 59985);

SELECT (SELECT COUNT(*) FROM `creature` WHERE `Comment` LIKE 'DARK2B %') AS wrathion_spawn_must_be_1,
       (SELECT `id` FROM `creature_questender` WHERE `quest` = 59985) AS ender_must_be_9167675,
       (SELECT LEFT(`QuestCompletionLog`, 30) FROM `quest_template` WHERE `ID` = 59985) AS completion_log;

-- ===================== map markers of 59985 =====================
DELETE FROM `quest_poi_points` WHERE `QuestID` = 59985;
DELETE FROM `quest_poi` WHERE `QuestID` = 59985;
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`) VALUES
(59985, 0, -1, 1, 321, 0, 0, 1, 0),
(59985, 1, 0, 12175, 20414, 0, 0, 1, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES
(59985, 0, 0, 1628, -4451, 0), (59985, 0, 1, 1646, -4451, 0), (59985, 0, 2, 1646, -4433, 0), (59985, 0, 3, 1628, -4433, 0),
(59985, 1, 0, 700, -1893, 0), (59985, 1, 1, 718, -1893, 0), (59985, 1, 2, 718, -1875, 0), (59985, 1, 3, 700, -1875, 0);

SELECT (SELECT COUNT(*) FROM `creature_template` WHERE `entry` IN (244389, 9100210)) AS credit_creatures_must_be_2,
       (SELECT `RequiredNpcOrGo1` FROM `quest_template` WHERE `ID` = 59985) AS objective_must_be_244389,
       (SELECT `id` FROM `creature_questender` WHERE `quest` = 59985) AS ender_must_be_9167675,
       (SELECT COUNT(*) FROM `creature` WHERE `Comment` LIKE 'DARK2B %') AS wrathion_spawn_must_be_1,
       (SELECT COUNT(*) FROM `quest_poi` WHERE `QuestID` = 59985) AS poi_must_be_2;
