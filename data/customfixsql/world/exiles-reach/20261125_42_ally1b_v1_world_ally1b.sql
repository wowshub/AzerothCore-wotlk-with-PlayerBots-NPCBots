-- ALLY1B V1 (2026-11-25, Claude) - candidate, NOT user-tested. Needs the Horde beach/camp stages (BEACH1A, BEACH1B) applied.
-- Stop worldserver, run on the world database, restart. Safe to run twice.
-- 1) Alliance beach and camp NPCs and quests 55122, 54951, 54952, 55174, 59254 (rows cloned from the tested Horde rows).
-- 2) Phases on map 12175: Horde friendly NPCs stay in phase 1, Alliance NPCs are phase 2, monsters and objects become 3 (both).
--    Ally1B.lua puts Alliance players into phase 2 on the island.
SET @spawn_limit := 16777215;
SELECT (SELECT COUNT(*) FROM `quest_template` WHERE `ID` IN (59929, 59930, 59931, 59932, 59933)) AS horde_quests_must_be_5,
       (SELECT COUNT(*) FROM `creature_template` WHERE `entry` IN (166782, 166906, 166854, 166796, 166786, 166791, 164577)) AS horde_templates_must_be_7,
       (SELECT COUNT(*) FROM `gameobject` WHERE `id` = 9174074 AND `map` = 12175) AS horde_campfire_spawns_at_least_1;
DELETE FROM `creature` WHERE `map` = 12175 AND `Comment` LIKE 'ALLY1B %';
DELETE FROM `gameobject` WHERE `map` = 12175 AND `Comment` LIKE 'ALLY1B %';
DELETE FROM `creature_template` WHERE `entry` IN (156626, 156651, 156607, 156609, 156612, 156610, 9164577);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (156626, 156651, 156607, 156609, 156612, 156610, 9164577);
DELETE FROM `creature_template_addon` WHERE `entry` IN (156626, 156651, 156607, 156609, 156612, 156610, 9164577);
DELETE FROM `creature_template_movement` WHERE `CreatureId` IN (156626, 156651, 156607, 156609, 156612, 156610, 9164577);
DELETE FROM `gameobject_template` WHERE `entry` = 9174075;
DELETE FROM `quest_template` WHERE `ID` IN (55122, 54951, 54952, 55174, 59254);
DELETE FROM `quest_template_addon` WHERE `ID` IN (55122, 54951, 54952, 55174, 59254);
DELETE FROM `quest_offer_reward` WHERE `ID` IN (55122, 54951, 54952, 55174, 59254);
DELETE FROM `quest_request_items` WHERE `ID` IN (55122, 54951, 54952, 55174, 59254);
DELETE FROM `creature_queststarter` WHERE `quest` IN (55122, 54951, 54952, 55174, 59254);
DELETE FROM `creature_questender` WHERE `quest` IN (55122, 54951, 54952, 55174, 59254);
DELETE FROM `quest_poi_points` WHERE `QuestID` IN (55122, 54951, 54952, 55174, 59254);
DELETE FROM `quest_poi` WHERE `QuestID` IN (55122, 54951, 54952, 55174, 59254);

DROP TEMPORARY TABLE IF EXISTS tmp_c;
CREATE TEMPORARY TABLE tmp_c AS SELECT * FROM `creature_template` WHERE `entry` = 166782;
UPDATE tmp_c SET `entry` = 156626, `name` = 'Lady Jaina Proudmoore 吉安娜·普罗德摩尔', `subname` = 'Lord Admiral 海军统帅', `ScriptName` = '';
INSERT INTO `creature_template` SELECT * FROM tmp_c;
DROP TEMPORARY TABLE tmp_c;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (156626, 0, 30863, 1, 1, 0);
DROP TEMPORARY TABLE IF EXISTS tmp_c;
CREATE TEMPORARY TABLE tmp_c AS SELECT * FROM `creature_template` WHERE `entry` = 166906;
UPDATE tmp_c SET `entry` = 156651, `name` = 'Lady Jaina Proudmoore 吉安娜·普罗德摩尔', `subname` = 'Lord Admiral 海军统帅', `ScriptName` = '';
INSERT INTO `creature_template` SELECT * FROM tmp_c;
DROP TEMPORARY TABLE tmp_c;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (156651, 0, 30863, 1, 1, 0);
DROP TEMPORARY TABLE IF EXISTS tmp_c;
CREATE TEMPORARY TABLE tmp_c AS SELECT * FROM `creature_template` WHERE `entry` = 166854;
UPDATE tmp_c SET `entry` = 156607, `name` = 'Alaria 阿拉莉亚', `subname` = NULL, `ScriptName` = '';
INSERT INTO `creature_template` SELECT * FROM tmp_c;
DROP TEMPORARY TABLE tmp_c;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (156607, 0, 3270, 1, 1, 0);
DROP TEMPORARY TABLE IF EXISTS tmp_c;
CREATE TEMPORARY TABLE tmp_c AS SELECT * FROM `creature_template` WHERE `entry` = 166796;
UPDATE tmp_c SET `entry` = 156609, `name` = 'Bjorn Stouthands 比约恩·壮手', `subname` = NULL, `ScriptName` = '';
INSERT INTO `creature_template` SELECT * FROM tmp_c;
DROP TEMPORARY TABLE tmp_c;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (156609, 0, 1628, 1, 1, 0);
DROP TEMPORARY TABLE IF EXISTS tmp_c;
CREATE TEMPORARY TABLE tmp_c AS SELECT * FROM `creature_template` WHERE `entry` = 166786;
UPDATE tmp_c SET `entry` = 156612, `name` = 'Kee-La 姬拉', `subname` = NULL, `ScriptName` = '';
INSERT INTO `creature_template` SELECT * FROM tmp_c;
DROP TEMPORARY TABLE tmp_c;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (156612, 0, 17022, 1, 1, 0);
DROP TEMPORARY TABLE IF EXISTS tmp_c;
CREATE TEMPORARY TABLE tmp_c AS SELECT * FROM `creature_template` WHERE `entry` = 166791;
UPDATE tmp_c SET `entry` = 156610, `name` = 'Austin Huxworth 奥斯汀·赫克斯沃斯', `subname` = NULL, `ScriptName` = '';
INSERT INTO `creature_template` SELECT * FROM tmp_c;
DROP TEMPORARY TABLE tmp_c;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (156610, 0, 2150, 1, 1, 0);
DROP TEMPORARY TABLE IF EXISTS tmp_c;
CREATE TEMPORARY TABLE tmp_c AS SELECT * FROM `creature_template` WHERE `entry` = 164577;
UPDATE tmp_c SET `entry` = 9164577, `name` = 'Captain Garrick 加里克船长', `subname` = NULL, `ScriptName` = '';
INSERT INTO `creature_template` SELECT * FROM tmp_c;
DROP TEMPORARY TABLE tmp_c;
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (9164577, 0, 3450, 1, 1, 0);
INSERT INTO `creature_template_addon` (`entry`, `path_id`, `mount`, `bytes1`, `bytes2`, `emote`, `visibilityDistanceType`, `auras`) VALUES
(156609, 0, 0, 3, 0, 0, 0, ''), (156612, 0, 0, 3, 0, 0, 0, ''), (156610, 0, 0, 3, 0, 0, 0, '');

SELECT COALESCE(MAX(`guid`), 0) INTO @g FROM `creature` WHERE `guid` < @spawn_limit;
SELECT COALESCE(MAX(`guid`), 0) INTO @go FROM `gameobject` WHERE `guid` < @spawn_limit;
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES
(@g + 1, 156626, 12175, 1, 2, 0, -435.153, -2610.99, 0.667893, 0.702199, 120, 0, 0, 'ALLY1B Jaina beach'),
(@g + 2, 156609, 12175, 1, 2, 0, -420.587, -2600.04, 0.551657, 3.63304, 120, 0, 0, 'ALLY1B wounded Bjorn'),
(@g + 3, 156612, 12175, 1, 2, 0, -448.918, -2606.02, 0.602431, 1.22242, 120, 0, 0, 'ALLY1B wounded Kee-La'),
(@g + 4, 156610, 12175, 1, 2, 0, -428.672, -2593.88, 0.152832, 1.43917, 120, 0, 0, 'ALLY1B wounded Austin'),
(@g + 5, 156607, 12175, 1, 2, 0, -249.388, -2489.95, 17.7668, 5.48748, 120, 0, 0, 'ALLY1B Alaria'),
(@g + 6, 156651, 12175, 1, 2, 0, -250.257, -2491.8, 17.7513, 0.313278, 120, 0, 0, 'ALLY1B Jaina camp'),
(@g + 7, 9164577, 12175, 1, 2, 0, -248.907, -2493.39, 18.2238, 1.16978, 120, 0, 0, 'ALLY1B Garrick');

-- campfire: Alliance copy at the same place (the Horde one stays in phase 1)
DROP TEMPORARY TABLE IF EXISTS tmp_g;
CREATE TEMPORARY TABLE tmp_g AS SELECT * FROM `gameobject_template` WHERE `entry` = 9174074;
UPDATE tmp_g SET `entry` = 9174075, `Data1` = 55174;
INSERT INTO `gameobject_template` SELECT * FROM tmp_g;
DROP TEMPORARY TABLE tmp_g;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `Comment`)
SELECT @go + 1, 9174075, `map`, `spawnMask`, 2, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, 'ALLY1B campfire'
FROM `gameobject` WHERE `id` = 9174074 AND `map` = 12175 ORDER BY `guid` LIMIT 1;

DROP TEMPORARY TABLE IF EXISTS tmp_q;
CREATE TEMPORARY TABLE tmp_q AS SELECT * FROM `quest_template` WHERE `ID` = 59929;
UPDATE tmp_q SET `ID` = 55122, `LogTitle` = 'Murloc Mania / 鱼人之乱', `LogDescription` = 'Recover 6 First Aid Kits from Murlocs. / 从鱼人身上取回6个急救包。', `QuestDescription` = 'I''m glad you made it out in one piece.$B$BJudging by the nearby shipwrecks, the missing expedition ran aground here, too.$B$BWe can''t move until we''ve got the remaining survivors back on their feet. Our remaining supplies have been stolen by murlocs! Recover enough first aid supplies for the wounded.$B$B很高兴你平安上岸。$B$B看附近的沉船，失踪的远征队也是在这里搁浅的。$B$B不让幸存者重新站起来，我们就没法出发。剩下的补给被鱼人偷走了！去为伤员找回足够的急救用品。', `QuestCompletionLog` = 'Return to Jaina. / 回到吉安娜那里。', `RewardNextQuest` = 0;
INSERT INTO `quest_template` SELECT * FROM tmp_q;
DROP TEMPORARY TABLE tmp_q;
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`, `NextQuestID`) VALUES (55122, 0, 54951);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `RewardText`, `VerifiedBuild`) VALUES (55122, 1, 'Excellent work. Let''s get the survivors back on their feet.$B$B干得好。我们让幸存者重新站起来吧。', 0);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`, `VerifiedBuild`) VALUES (55122, 'Did you recover the first aid kits? Don''t take the murlocs lightly.$B$B急救包找回来了吗？别小看鱼人。', 0);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (156626, 55122);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (156626, 55122);
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`)
SELECT 55122, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild` FROM `quest_poi` WHERE `QuestID` = 59929;
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`)
SELECT 55122, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild` FROM `quest_poi_points` WHERE `QuestID` = 59929;

DROP TEMPORARY TABLE IF EXISTS tmp_q;
CREATE TEMPORARY TABLE tmp_q AS SELECT * FROM `quest_template` WHERE `ID` = 59930;
UPDATE tmp_q SET `ID` = 54951, `LogTitle` = 'Emergency First Aid / 紧急急救', `LogDescription` = 'Use a First Aid Kit on Austin, Bjorn and Kee-La. / 对奥斯汀、比约恩和姬拉使用急救包。', `QuestDescription` = 'We have to patch everyone up before we can begin the search for the missing expedition.$B$BTake this first aid kit and tend to the wounded.$B$B开始搜寻失踪的远征队之前，得先给大家包扎好。$B$B拿上急救包，去照看伤员。', `QuestCompletionLog` = 'Return to Jaina. / 回到吉安娜那里。', `RewardNextQuest` = 0, `RequiredNpcOrGo1` = 156609, `RequiredNpcOrGo2` = 156612, `RequiredNpcOrGo3` = 156610, `RequiredNpcOrGo4` = 0, `RequiredNpcOrGoCount1` = 1, `RequiredNpcOrGoCount2` = 1, `RequiredNpcOrGoCount3` = 1, `RequiredNpcOrGoCount4` = 0, `ObjectiveText1` = 'First Aid Kit used on Bjorn / 已治疗比约恩', `ObjectiveText2` = 'First Aid Kit used on Kee-La / 已治疗姬拉', `ObjectiveText3` = 'First Aid Kit used on Austin / 已治疗奥斯汀', `ObjectiveText4` = '';
INSERT INTO `quest_template` SELECT * FROM tmp_q;
DROP TEMPORARY TABLE tmp_q;
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`, `NextQuestID`) VALUES (54951, 55122, 54952);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `RewardText`, `VerifiedBuild`) VALUES (54951, 1, 'We''re ready to move. Let''s find that missing expedition.$B$B可以出发了。去找那支失踪的远征队。', 0);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`, `VerifiedBuild`) VALUES (54951, 'Have you treated all of the survivors yet?$B$B你给所有幸存者治疗过了吗？', 0);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (156626, 54951);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (156626, 54951);
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`)
SELECT 54951, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild` FROM `quest_poi` WHERE `QuestID` = 59930;
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`)
SELECT 54951, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild` FROM `quest_poi_points` WHERE `QuestID` = 59930;

DROP TEMPORARY TABLE IF EXISTS tmp_q;
CREATE TEMPORARY TABLE tmp_q AS SELECT * FROM `quest_template` WHERE `ID` = 59931;
UPDATE tmp_q SET `ID` = 54952, `LogTitle` = 'Finding the Lost Expedition / 寻找失踪的远征队', `LogDescription` = 'Search the nearby camp for expedition survivors. / 到附近营地寻找远征队幸存者。', `QuestDescription` = 'Captain Garrick went ahead to find survivors. It looks like she lit a fire.$B$BMeet her up ahead to see what she found. I''ll look further within the island for survivors... and the source of the magic that attacked us.$B$B加里克船长先去寻找幸存者了，看样子她点起了篝火。$B$B到前面和她会合，看看她发现了什么。我去岛屿深处找幸存者……还有袭击我们的魔法源头。', `QuestCompletionLog` = 'Speak with Alaria at the Abandoned Camp. / 到废弃营地和阿拉莉亚交谈。', `RewardNextQuest` = 0, `RequiredNpcOrGo1` = 0, `RequiredNpcOrGoCount1` = 0, `RequiredNpcOrGo2` = 0, `RequiredNpcOrGoCount2` = 0, `RequiredNpcOrGo3` = 0, `RequiredNpcOrGoCount3` = 0, `RequiredNpcOrGo4` = 0, `RequiredNpcOrGoCount4` = 0, `ObjectiveText1` = '', `ObjectiveText2` = '', `ObjectiveText3` = '', `ObjectiveText4` = '';
INSERT INTO `quest_template` SELECT * FROM tmp_q;
DROP TEMPORARY TABLE tmp_q;
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`, `NextQuestID`) VALUES (54952, 54951, 55174);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `RewardText`, `VerifiedBuild`) VALUES (54952, 1, 'The others... taken...$B$BNeed... food...$B$B其他人……被抓走了……$B$B需要……食物……', 0);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (156626, 54952);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (156607, 54952);
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`)
SELECT 54952, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild` FROM `quest_poi` WHERE `QuestID` = 59931;
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`)
SELECT 54952, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild` FROM `quest_poi_points` WHERE `QuestID` = 59931;

DROP TEMPORARY TABLE IF EXISTS tmp_q;
CREATE TEMPORARY TABLE tmp_q AS SELECT * FROM `quest_template` WHERE `ID` = 59932;
UPDATE tmp_q SET `ID` = 55174, `LogTitle` = 'Cooking Meat / 烹饪肉', `LogDescription` = 'Get 5 Raw Meat from wildlife around the camp and cook it on the campfire. / 从营地周围的野兽身上取5份生肉，在篝火上烤熟。', `QuestDescription` = 'Alaria is nearly starved to death. We need to get her something to eat!$B$BSlay some of the nearby wildlife for their meat. Bring whatever you find here to cook.$B$B阿拉莉亚快饿死了，我们得给她弄点吃的！$B$B去猎些附近的野兽取肉，带回这里烤。', `QuestCompletionLog` = 'Give Jaina the cooked meat. / 把烤熟的肉交给吉安娜。', `RewardNextQuest` = 0;
INSERT INTO `quest_template` SELECT * FROM tmp_q;
DROP TEMPORARY TABLE tmp_q;
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`, `NextQuestID`) VALUES (55174, 54952, 59254);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `RewardText`, `VerifiedBuild`) VALUES (55174, 1, '<Alaria quickly eats the meat that you cooked.>$B$BBy the Light... I feel so much better.$B$BYou need to keep moving... quilboar have kidnapped the expedition!$B$B<阿拉莉亚很快吃掉了你烤的肉。>$B$B圣光啊……我好多了。$B$B你们得赶紧走……野猪人绑走了远征队！', 0);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`, `VerifiedBuild`) VALUES (55174, 'Please... I need... some food...$B$B求你……我需要……一点食物……', 0);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (156651, 55174);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (156651, 55174);
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`)
SELECT 55174, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild` FROM `quest_poi` WHERE `QuestID` = 59932;
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`)
SELECT 55174, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild` FROM `quest_poi_points` WHERE `QuestID` = 59932;

DROP TEMPORARY TABLE IF EXISTS tmp_q;
CREATE TEMPORARY TABLE tmp_q AS SELECT * FROM `quest_template` WHERE `ID` = 59933;
UPDATE tmp_q SET `ID` = 59254, `LogTitle` = 'Enhanced Combat Tactics / 强化战斗战术', `LogDescription` = 'Spar with Captain Garrick. / 与加里克船长切磋。', `QuestDescription` = 'Chances are we''ll have to brave the quilboar''s den. That''s no small feat. They are far more aggressive and intelligent than the murlocs you faced earlier.$B$BI need to make sure I''m not sending you to your death. We''re going to have one last sparring session.$B$B我们恐怕得闯野猪人的巢穴。这可不是小事，它们比你之前对付的鱼人凶得多，也聪明得多。$B$B我得确认不是让你去送死。再切磋一次。', `QuestCompletionLog` = 'Return to Jaina. / 回到吉安娜那里。', `RewardNextQuest` = 0, `RequiredNpcOrGo1` = 164577, `RequiredNpcOrGoCount1` = 1, `ObjectiveText1` = 'Spar with Captain Garrick / 与加里克船长切磋';
INSERT INTO `quest_template` SELECT * FROM tmp_q;
DROP TEMPORARY TABLE tmp_q;
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`, `NextQuestID`) VALUES (59254, 55174, 0);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `RewardText`, `VerifiedBuild`) VALUES (59254, 1, 'Fine work, $n. Let''s hunt down those quilboar.$B$B干得漂亮，$n。去收拾那些野猪人吧。', 0);
INSERT INTO `quest_request_items` (`ID`, `CompletionText`, `VerifiedBuild`) VALUES (59254, 'Spar with Captain Garrick.$B$B去和加里克船长切磋。', 0);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (156651, 59254);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (156651, 59254);
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`)
SELECT 59254, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild` FROM `quest_poi` WHERE `QuestID` = 59933;
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`)
SELECT 59254, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild` FROM `quest_poi_points` WHERE `QuestID` = 59933;

-- ===== phases: monsters, objects, spirit healers, the Lightspawn and the wandering boar are seen by both factions =====
UPDATE `creature` c JOIN `creature_template` t ON t.`entry` = c.`id1` SET c.`phaseMask` = 3
WHERE c.`map` = 12175 AND c.`phaseMask` = 1 AND (t.`faction` <> 35 OR c.`id1` IN (6491, 157114, 156722));
UPDATE `gameobject` SET `phaseMask` = 3 WHERE `map` = 12175 AND `phaseMask` = 1 AND `id` <> 9174074;

SELECT (SELECT COUNT(*) FROM `creature` WHERE `Comment` LIKE 'ALLY1B %') AS alliance_npcs_must_be_7,
       (SELECT COUNT(*) FROM `gameobject` WHERE `Comment` = 'ALLY1B campfire') AS alliance_campfire_must_be_1,
       (SELECT COUNT(*) FROM `quest_template` WHERE `ID` IN (55122, 54951, 54952, 55174, 59254)) AS quests_must_be_5,
       (SELECT COUNT(*) FROM `creature_template` WHERE `entry` IN (156626, 156651, 156607, 156609, 156612, 156610, 9164577)) AS templates_must_be_7,
       (SELECT COUNT(*) FROM `creature` WHERE `map` = 12175 AND `phaseMask` = 3) AS shared_creatures_more_than_0,
       (SELECT COUNT(*) FROM `creature` WHERE `map` = 12175 AND `phaseMask` = 3 AND `id1` IN (166782, 166906, 166854)) AS horde_npcs_shared_must_be_0;
