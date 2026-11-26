-- DARK1A V1 (2026-11-25, Claude) - candidate, NOT user-tested.
-- Exile's Reach Horde chain after 59949, the Darkmaul Citadel part: 59975 To Darkmaul Citadel -> 59978 Right Beneath Their Eyes ->
--   59979 Like Ogres to the Slaughter -> 59980 Catapult Destruction -> 59981 Controlling their Stones.
-- Data from LoreWalkerTDB (12.x) rebuilt for AC 3.3.5, map 12175, incl. quest_poi map markers.
-- Simplified vs retail (see README): no ogre disguise/phasing/teleport; 59978 has 4 objectives (AC limit) with area credits in Dark1A.lua;
--   the three ward stones (items) become kill credits of Jugnug/Wug/Grunk (no new items, so no client Item.dbc needed);
--   catapults/runes are click objects cloned from the verified totem row 9350803 (needs HARPY1C V4 applied first); boss fights are plain melee.
-- Safe to run twice. guids = live legal maximum + 1 (must stay below 16777215). Keep worldserver stopped, restart after.
SET @spawn_limit := 16777215;

DELETE FROM `creature` WHERE `map` = 12175 AND `Comment` LIKE 'DARK1A %';
DELETE FROM `gameobject` WHERE `map` = 12175 AND `Comment` LIKE 'DARK1A %';
DELETE FROM `creature_template` WHERE `entry` IN (167596, 167598, 167633, 167632, 167631, 167183, 153239, 153580, 154103, 153581, 153582, 153583);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (167596, 167598, 167633, 167632, 167631, 167183, 153239, 153580, 154103, 153581, 153582, 153583);
DELETE FROM `gameobject_template` WHERE `entry` IN (9326651, 9339865);
DELETE FROM `quest_template` WHERE `ID` IN (59975, 59978, 59979, 59980, 59981);
DELETE FROM `quest_template_addon` WHERE `ID` IN (59975, 59978, 59979, 59980, 59981);
DELETE FROM `quest_offer_reward` WHERE `ID` IN (59975, 59978, 59979, 59980, 59981);
DELETE FROM `quest_request_items` WHERE `ID` IN (59975, 59978, 59979, 59980, 59981);
DELETE FROM `creature_queststarter` WHERE `quest` IN (59975, 59978, 59979, 59980, 59981);
DELETE FROM `creature_questender` WHERE `quest` IN (59975, 59978, 59979, 59980, 59981);
DELETE FROM `quest_poi_points` WHERE `QuestID` IN (59975, 59978, 59979, 59980, 59981);
DELETE FROM `quest_poi` WHERE `QuestID` IN (59975, 59978, 59979, 59980, 59981);
SELECT COALESCE(MAX(`guid`), 0) INTO @g FROM `creature` WHERE `guid` < @spawn_limit;
SELECT COALESCE(MAX(`guid`), 0) INTO @o FROM `gameobject` WHERE `guid` < @spawn_limit;
SELECT IF(@g + 40 + 10000 < @spawn_limit AND @o + 10 + 10000 < @spawn_limit, 'guid base OK', 'ABORT: no guid room, do not continue') AS guid_check, @g AS creature_max, @o AS go_max;
SELECT COUNT(*) AS totem_row_9350803_must_be_1 FROM `gameobject_template` WHERE `entry` = 9350803;
SELECT COUNT(*) AS thrall_167212_must_be_1 FROM `creature_template` WHERE `entry` = 167212;

-- ===== creature templates =====
-- displays (all stock, exist in the client): Thrall 4527, Wrathion 15511, Breka 15511 (x0.95), Mulgrin = Cairne 4307, Herbert 10256, ogres 11567
INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `unit_class`, `unit_flags`, `type`, `AIName`, `HealthModifier`, `DamageModifier`, `RegenHealth`, `flags_extra`, `ScriptName`) VALUES
(167596, 'Thrall 萨尔', NULL, 1, 1, 35, 2, 1, 1.14286, 0, 1, 0, 7, '', 3, 1, 1, 0, ''),
(167633, 'Thrall 萨尔', NULL, 1, 1, 35, 2, 1, 1.14286, 0, 1, 0, 7, '', 3, 1, 1, 0, ''),
(167598, 'Herbert Gloomburst 赫伯特·暗爆', NULL, 1, 1, 35, 1, 1, 1.14286, 0, 1, 0, 7, '', 3, 1, 1, 0, ''),
(167632, 'Breka Grimaxe 布蕾卡·格里姆斧', NULL, 1, 1, 35, 2, 1, 1.14286, 0, 1, 0, 7, '', 3, 1, 1, 0, ''),
(167631, 'Wrathion 瑞斯拉克', NULL, 1, 1, 35, 2, 1, 1.14286, 0, 1, 0, 7, '', 3, 1, 1, 0, ''),
(167183, 'Warlord Mulgrin Thunderwalker 督军穆格林·雷行者', NULL, 1, 1, 35, 2, 1, 1.14286, 0, 1, 0, 7, '', 3, 1, 1, 0, ''),
(153239, 'Ogre Brute 食人魔蛮兵', NULL, 8, 8, 14, 0, 1, 1.14286, 0, 1, 0, 7, '', 2, 0.5, 1, 0, ''),
(153580, 'Gor''groth 戈尔格罗斯', NULL, 8, 8, 35, 1, 1, 1.14286, 0, 1, 0, 7, '', 3, 1, 1, 0, ''),
(154103, 'Ogre Chef 食人魔厨师', NULL, 8, 8, 35, 0, 1, 1.14286, 0, 1, 0, 7, '', 2, 0.5, 1, 0, ''),
(153581, 'Grunk 格伦克', NULL, 9, 9, 14, 0, 1, 1.14286, 1, 1, 0, 7, '', 4, 0.8, 1, 0, ''),
(153582, 'Wug 沃格', NULL, 9, 9, 14, 0, 1, 1.14286, 1, 1, 0, 7, '', 4, 0.8, 1, 0, ''),
(153583, 'Jugnug 朱格努格', NULL, 9, 9, 14, 0, 1, 1.14286, 1, 1, 0, 7, '', 4, 0.8, 1, 0, '');
INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES
(167596, 0, 4527, 1, 1, 0),
(167633, 0, 4527, 1, 1, 0),
(167598, 0, 10256, 1, 1, 0),
(167632, 0, 15511, 0.95, 1, 0),
(167631, 0, 15511, 1, 1, 0),
(167183, 0, 4307, 1.1, 1, 0),
(153239, 0, 11567, 1, 1, 0),
(153580, 0, 11567, 1.4, 1, 0),
(154103, 0, 11567, 1, 1, 0),
(153581, 0, 11567, 1.25, 1, 0),
(153582, 0, 11567, 1.25, 1, 0),
(153583, 0, 11567, 1.25, 1, 0);

-- ===== click objects: exact clones of the verified totem row 9350803 (cursor 'Cast', consumable, quest sparkle) =====
-- catapult: stock ballista model 8002 (retail model 14627 is not in the client); rune: stock blue rune 7658 (retail 59825 is not in the client)
DROP TEMPORARY TABLE IF EXISTS tmp_dk;
CREATE TEMPORARY TABLE tmp_dk AS SELECT * FROM `gameobject_template` WHERE `entry` = 9350803;
UPDATE tmp_dk SET `entry` = 9326651, `displayId` = 8002, `name` = 'Ogre Catapult 食人魔投石机', `castBarCaption` = 'Detonating 引爆中', `size` = 1, `Data1` = 59980;
INSERT INTO `gameobject_template` SELECT * FROM tmp_dk;
UPDATE tmp_dk SET `entry` = 9339865, `displayId` = 7658, `name` = 'Ogre Runestone 食人魔符文石', `castBarCaption` = 'Disabling 解除中', `size` = 1.5, `Data1` = 59981;
INSERT INTO `gameobject_template` SELECT * FROM tmp_dk;
DROP TEMPORARY TABLE tmp_dk;

-- ===== quests =====
INSERT INTO `quest_template` (`ID`, `QuestType`, `QuestLevel`, `MinLevel`, `RewardXPDifficulty`, `Flags`, `LogTitle`, `LogDescription`, `QuestDescription`, `QuestCompletionLog`, `AreaDescription`) VALUES
(59975, 2, 1, 1, 3, 0, 'To Darkmaul Citadel / 前往暗槌要塞', 'Meet Thrall outside of Darkmaul Citadel. / 在暗槌要塞外与萨尔会合。',
 'The last remaining survivor is being held within the ogre''s citadel.$B$BCrenna and Herbert have a plan to get us inside.$B$BA small group of us will gather up north. You''re coming with us.$B$BIf we fail here, the ogres will gain control of Kalecgos and his powerful blue dragon magic.$B$B最后一名幸存者被关在食人魔的要塞里。$B$B克蕾娜和赫伯特有办法带我们混进去。$B$B我们一小队人会在北面集合，你跟我们一起去。$B$B如果我们在这里失败，食人魔就会控制卡雷苟斯和他强大的蓝龙魔法。',
 'Meet Thrall outside of Darkmaul Citadel. / 在暗槌要塞外与萨尔会合。', ''),
(59978, 2, 1, 1, 5, 0, 'Right Beneath Their Eyes / 就在他们眼皮底下', 'Have Herbert Gloomburst transform you into an ogre, then scout the nearby ogre citadel. / 请赫伯特把你变成食人魔，再去侦察附近的食人魔要塞。',
 'We need to get into Darkmaul Citadel, rescue the last survivor, and stop Gor''groth.$B$BHerbert and Crenna are going to cast a spell to make you look an ogre... and then you''re going to take us in as your "prisoners."$B$BSpeak with Herbert when you''re ready.$B$B我们得进入暗槌要塞，救出最后一名幸存者，阻止戈尔格罗斯。$B$B赫伯特和克蕾娜会施法让你看起来像食人魔……然后你把我们当作你的“俘虏”带进去。$B$B准备好了就和赫伯特说话。',
 'Report back to Thrall. / 向萨尔复命。', ''),
(59979, 2, 1, 1, 5, 0, 'Like Ogres to the Slaughter / 如同食人魔去屠宰', 'Slay 8 ogres within Darkmaul Citadel. / 在暗槌要塞内击杀8个食人魔。',
 'This is worse than I thought. The ogres were counting on us to stage a rescue attempt.$B$BIt seems that they plan to attack our camp while they near completion of the ritual.$B$BWe can''t let that happen. Crush the ogres! Show them the strength of the Horde!$B$B情况比我想的更糟。食人魔早就料到我们会来营救。$B$B看来他们打算在仪式接近完成时攻击我们的营地。$B$B绝不能让这种事发生。碾碎食人魔！让他们见识部落的力量！',
 'Report back to Breka Grimaxe. / 向布蕾卡·格里姆斧复命。', ''),
(59980, 2, 1, 1, 5, 0, 'Catapult Destruction / 摧毁投石机', 'Blow up 4 catapults within Darkmaul Citadel. / 炸毁暗槌要塞内的4架投石机。',
 'As we snuck in here I noticed the ogres erecting catapults to destroy our camp.$B$BCork must have anticipated this and gave me several explosives to use, "just in case".$B$BTake these explosives and blow up those catapults!$B$BAlso don''t shake them too hard.$B$B我们潜进来时，我注意到食人魔在架设投石机，要砸毁我们的营地。$B$B软木肯定早料到了，给了我几包炸药，说是“以防万一”。$B$B用这些炸药把投石机炸掉！$B$B还有，别晃得太用力。',
 'Report back to Wrathion. / 向瑞斯拉克复命。', ''),
(59981, 2, 1, 1, 5, 0, 'Controlling their Stones / 夺取他们的石头', 'Defeat Jugnug, Wug and Grunk to recover the ward stones, then use the runes to free Warlord Thunderwalker. / 击败朱格努格、沃格和格伦克夺回结界石，再用符文石解放雷行者督军。',
 'Warlord Thunderwalker won''t last much longer. Soon, his life essence will be completely drained.$B$BGor''groth mentioned that they are keeping him captive through the use of ward stones.$B$BI want you to recover these ward stones and bring them here so we can release Thunderwalker.$B$B雷行者督军撑不了多久了，他的生命精华很快就会被抽干。$B$B戈尔格罗斯提过，他们靠结界石把他囚禁起来。$B$B我要你夺回这些结界石带到这里，我们好放了雷行者。',
 'Report back to Warlord Mulgrin Thunderwalker. / 向督军穆格林·雷行者复命。', '');
UPDATE `quest_template` SET
  `RequiredNpcOrGo1` = 167598, `RequiredNpcOrGoCount1` = 1, `ObjectiveText1` = 'Ask Herbert to perform the ogre transformation spell / 请赫伯特施展食人魔变身术',
  `RequiredNpcOrGo2` = 154103, `RequiredNpcOrGoCount2` = 1, `ObjectiveText2` = 'Find the ogre cooking area / 找到食人魔的厨房区',
  `RequiredNpcOrGo3` = 153580, `RequiredNpcOrGoCount3` = 1, `ObjectiveText3` = 'Greet Gor''groth (talk to him) / 向戈尔格罗斯致意（和他说话）',
  `RequiredNpcOrGo4` = 9100210, `RequiredNpcOrGoCount4` = 1, `ObjectiveText4` = 'Reach the citadel entrance / 抵达要塞入口'
WHERE `ID` = 59978;
UPDATE `quest_template` SET `RequiredNpcOrGo1` = 153239, `RequiredNpcOrGoCount1` = 8, `ObjectiveText1` = 'Ogres slain / 已击杀的食人魔' WHERE `ID` = 59979;
UPDATE `quest_template` SET `RequiredNpcOrGo1` = -9326651, `RequiredNpcOrGoCount1` = 4, `ObjectiveText1` = 'Catapults destroyed / 已炸毁的投石机' WHERE `ID` = 59980;
UPDATE `quest_template` SET
  `RequiredNpcOrGo1` = 153583, `RequiredNpcOrGoCount1` = 1, `ObjectiveText1` = 'Jugnug''s ward stone recovered (defeat Jugnug) / 夺回朱格努格的结界石（击败朱格努格）',
  `RequiredNpcOrGo2` = 153582, `RequiredNpcOrGoCount2` = 1, `ObjectiveText2` = 'Wug''s ward stone recovered (defeat Wug) / 夺回沃格的结界石（击败沃格）',
  `RequiredNpcOrGo3` = 153581, `RequiredNpcOrGoCount3` = 1, `ObjectiveText3` = 'Grunk''s ward stone recovered (defeat Grunk) / 夺回格伦克的结界石（击败格伦克）',
  `RequiredNpcOrGo4` = -9339865, `RequiredNpcOrGoCount4` = 3, `ObjectiveText4` = 'Disable the runes holding Warlord Thunderwalker / 解除囚禁雷行者督军的符文'
WHERE `ID` = 59981;
INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`, `NextQuestID`) VALUES
(59975, 59949, 0), (59978, 59975, 0), (59979, 59978, 0), (59980, 59979, 0), (59981, 59980, 0);
INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `Emote2`, `EmoteDelay1`, `EmoteDelay2`, `RewardText`, `VerifiedBuild`) VALUES
(59975, 1, 0, 0, 0, 'Thrall: Good, you made it. The citadel is just ahead. Herbert has a plan.$B$B萨尔：很好，你到了。要塞就在前面。赫伯特有个办法。', 0),
(59978, 1, 0, 0, 0, 'Thrall: Gor''groth himself did not suspect a thing. Ogres are not famous for their eyes. Now we fight from the inside.$B$B萨尔：戈尔格罗斯本人都没起疑。食人魔可不以眼力著称。现在我们从里面动手。', 0),
(59979, 1, 0, 0, 0, 'Breka: That will make them think twice before marching on our camp.$B$B布蕾卡：这样他们就得好好想想再去进攻我们的营地了。', 0),
(59980, 1, 0, 0, 0, 'Wrathion: Splendid. Nothing ruins a siege like a lack of siege weapons.$B$B瑞斯拉克：太好了。没有攻城器械，再好的围攻也泡汤。', 0),
(59981, 1, 0, 0, 0, 'Mulgrin: These were the ward stones used to bind me? Perhaps even the ogres have heard tale of my strength!$B$B穆格林：这就是用来束缚我的结界石？也许连食人魔都听说过我的威名！', 0);
INSERT INTO `quest_request_items` (`ID`, `EmoteOnComplete`, `EmoteOnIncomplete`, `CompletionText`, `VerifiedBuild`) VALUES
(59975, 0, 0, 'Over here.$B$B这边。', 0),
(59978, 0, 0, 'Have you scouted the citadel yet?$B$B你侦察过要塞了吗？', 0),
(59979, 0, 0, 'Keep killing ogres.$B$B继续杀食人魔。', 0),
(59980, 0, 0, 'The catapults must burn.$B$B投石机必须炸掉。', 0),
(59981, 0, 0, 'Bring me what the ogres took.$B$B把食人魔抢走的东西带来。', 0);
INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (167212, 59975), (167596, 59978), (167632, 59979), (167631, 59980), (167633, 59981);
INSERT INTO `creature_questender` (`id`, `quest`) VALUES (167596, 59975), (167633, 59978), (167632, 59979), (167631, 59980), (167183, 59981);

-- ===== spawns (retail positions; no phasing) =====
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES
(@g + 1, 167596, 12175, 1, 1, 0, 318.91, -2175.66, 105.94, 4.2645, 120, 0, 0, 'DARK1A Thrall outside citadel'),
(@g + 2, 167598, 12175, 1, 1, 0, 316.211, -2177.6, 105.476, 6.06396, 120, 0, 0, 'DARK1A Herbert'),
(@g + 3, 167633, 12175, 1, 1, 0, 712.062, -1878.94, 186.882, 1.64922, 120, 0, 0, 'DARK1A Thrall inside'),
(@g + 4, 167632, 12175, 1, 1, 0, 715.951, -1881.64, 186.508, 2.02857, 120, 0, 0, 'DARK1A Breka'),
(@g + 5, 167631, 12175, 1, 1, 0, 713.435, -1881.59, 186.508, 1.64922, 120, 0, 0, 'DARK1A Wrathion'),
(@g + 6, 167183, 12175, 1, 1, 0, 707.889, -1868.97, 189.325, 4.23171, 120, 0, 0, 'DARK1A Mulgrin'),
(@g + 7, 153580, 12175, 1, 1, 0, 587.685, -2063.17, 159.533, 3.33749, 120, 0, 0, 'DARK1A Gor''groth'),
(@g + 8, 154103, 12175, 1, 1, 0, 609.267, -2062.14, 159.592, 0.848848, 120, 0, 0, 'DARK1A chef'),
(@g + 9, 154103, 12175, 1, 1, 0, 604.814, -2067.2, 159.617, 5.96308, 120, 0, 0, 'DARK1A chef'),
(@g + 10, 153583, 12175, 1, 1, 0, 663.193, -2127.89, 161.384, 5.68607, 120, 0, 0, 'DARK1A Jugnug'),
(@g + 11, 153582, 12175, 1, 1, 0, 591.783, -2010.63, 175.676, 0.113099, 120, 0, 0, 'DARK1A Wug'),
(@g + 12, 153581, 12175, 1, 1, 0, 509.788, -1965.49, 144.521, 1.03183, 120, 0, 0, 'DARK1A Grunk'),
(@g + 13, 153239, 12175, 1, 1, 0, 451.958, -2114.27, 130.55, 2.72133, 120, 0, 0, 'DARK1A ogre'),
(@g + 14, 153239, 12175, 1, 1, 0, 456.92, -2046.08, 143.086, 3.6624, 120, 0, 0, 'DARK1A ogre'),
(@g + 15, 153239, 12175, 1, 1, 0, 524.132, -2006.11, 142.99, 0.0277943, 120, 0, 0, 'DARK1A ogre'),
(@g + 16, 153239, 12175, 1, 1, 0, 732.875, -2071.09, 120.149, 5.22481, 120, 0, 0, 'DARK1A ogre'),
(@g + 17, 153239, 12175, 1, 1, 0, 736.76, -2076.14, 120.123, 2.60965, 120, 0, 0, 'DARK1A ogre'),
(@g + 18, 153239, 12175, 1, 1, 0, 603.231, -2121.42, 158.924, 3.0342, 120, 0, 0, 'DARK1A ogre'),
(@g + 19, 153239, 12175, 1, 1, 0, 479.986, -2113.83, 132.548, 4.65749, 120, 0, 0, 'DARK1A ogre'),
(@g + 20, 153239, 12175, 1, 1, 0, 454.729, -2102.09, 130.526, 3.06899, 120, 0, 0, 'DARK1A ogre'),
(@g + 21, 153239, 12175, 1, 1, 0, 533.014, -2079.67, 158.342, 5.33907, 120, 0, 0, 'DARK1A ogre'),
(@g + 22, 153239, 12175, 1, 1, 0, 431.082, -2025.23, 132.453, 3.69202, 120, 0, 0, 'DARK1A ogre'),
(@g + 23, 153239, 12175, 1, 1, 0, 481.309, -1975.16, 143.104, 4.4183, 120, 0, 0, 'DARK1A ogre');
INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `Comment`) VALUES
(@o + 1, 9326651, 12175, 1, 1, 612.005, -2119.42, 158.902, 4.56228, 0, 0, 0, 1, 60, 255, 1, 'DARK1A catapult'),
(@o + 2, 9326651, 12175, 1, 1, 535.903, -2086, 158.324, 4.10596, 0, 0, 0, 1, 60, 255, 1, 'DARK1A catapult'),
(@o + 3, 9326651, 12175, 1, 1, 487.993, -2053.3, 143.95, 4.20806, 0, 0, 0, 1, 60, 255, 1, 'DARK1A catapult'),
(@o + 4, 9326651, 12175, 1, 1, 467.639, -1994.9, 143.769, 3.17447, 0, 0, 0, 1, 60, 255, 1, 'DARK1A catapult'),
(@o + 5, 9339865, 12175, 1, 1, 701.126, -1868.98, 186.882, 0.0116846, 0, 0, 0, 1, 60, 255, 1, 'DARK1A rune'),
(@o + 6, 9339865, 12175, 1, 1, 713.529, -1865.08, 186.882, 2.34432, 0, 0, 0, 1, 60, 255, 1, 'DARK1A rune'),
(@o + 7, 9339865, 12175, 1, 1, 707.785, -1875.74, 186.882, 1.69165, 0, 0, 0, 1, 60, 255, 1, 'DARK1A rune');

-- ===== quest map markers (retail quest_poi_points, X/Y only; ObjectiveIndex 0-based, -1 = turn-in) =====
INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`) VALUES
(59975, 0, -1, 12175, 20414, 0, 0, 1, 0),
(59978, 0, -1, 12175, 20414, 0, 0, 1, 0),
(59978, 1, 0, 12175, 20414, 0, 0, 1, 0),
(59978, 2, 1, 12175, 20414, 0, 0, 1, 0),
(59978, 3, 2, 12175, 20414, 0, 0, 1, 0),
(59978, 4, 3, 12175, 20414, 0, 0, 1, 0),
(59979, 0, -1, 12175, 20414, 0, 0, 1, 0),
(59979, 1, 0, 12175, 20414, 0, 0, 1, 0),
(59980, 0, -1, 12175, 20414, 0, 0, 1, 0),
(59980, 1, 0, 12175, 20414, 0, 0, 1, 0),
(59981, 0, -1, 12175, 20414, 0, 0, 1, 0),
(59981, 1, 0, 12175, 20414, 0, 0, 1, 0),
(59981, 2, 1, 12175, 20414, 0, 0, 1, 0),
(59981, 3, 2, 12175, 20414, 0, 0, 1, 0),
(59981, 4, 3, 12175, 20414, 0, 0, 1, 0);
INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES
(59975, 0, 0, 308, -2181, 0), (59975, 0, 1, 326, -2181, 0), (59975, 0, 2, 326, -2163, 0), (59975, 0, 3, 308, -2163, 0),
(59978, 0, 0, 692, -1889, 0), (59978, 0, 1, 710, -1889, 0), (59978, 0, 2, 710, -1871, 0), (59978, 0, 3, 692, -1871, 0),
(59978, 1, 0, 308, -2182, 0), (59978, 1, 1, 326, -2182, 0), (59978, 1, 2, 326, -2164, 0), (59978, 1, 3, 308, -2164, 0),
(59978, 2, 0, 589, -2091, 0), (59978, 2, 1, 610, -2083, 0), (59978, 2, 2, 619, -2061, 0), (59978, 2, 3, 610, -2040, 0),
(59978, 2, 4, 589, -2031, 0), (59978, 2, 5, 568, -2040, 0), (59978, 2, 6, 559, -2061, 0), (59978, 2, 7, 568, -2083, 0),
(59978, 3, 0, 583, -2064, 0), (59978, 3, 1, 601, -2064, 0), (59978, 3, 2, 601, -2046, 0), (59978, 3, 3, 583, -2046, 0),
(59978, 4, 0, 686, -1906, 0), (59978, 4, 1, 704, -1906, 0), (59978, 4, 2, 704, -1888, 0), (59978, 4, 3, 686, -1888, 0),
(59979, 0, 0, 701, -1886, 0), (59979, 0, 1, 719, -1886, 0), (59979, 0, 2, 719, -1868, 0), (59979, 0, 3, 701, -1868, 0),
(59979, 1, 0, 603, -2121, 0), (59979, 1, 1, 739, -2091, 0), (59979, 1, 2, 736, -2076, 0), (59979, 1, 3, 732, -2071, 0),
(59979, 1, 4, 691, -2032, 0), (59979, 1, 5, 582, -1975, 0), (59979, 1, 6, 481, -1975, 0), (59979, 1, 7, 431, -2025, 0), (59979, 1, 8, 452, -2114, 0),
(59980, 0, 0, 696, -1886, 0), (59980, 0, 1, 714, -1886, 0), (59980, 0, 2, 714, -1868, 0), (59980, 0, 3, 696, -1868, 0),
(59980, 1, 0, 609, -2118, 0), (59980, 1, 1, 462, -1997, 0), (59980, 1, 2, 488, -2052, 0), (59980, 1, 3, 534, -2086, 0),
(59981, 0, 0, 694, -1885, 0), (59981, 0, 1, 712, -1885, 0), (59981, 0, 2, 712, -1867, 0), (59981, 0, 3, 694, -1867, 0),
(59981, 1, 0, 652, -2137, 0), (59981, 1, 1, 670, -2137, 0), (59981, 1, 2, 670, -2119, 0), (59981, 1, 3, 652, -2119, 0),
(59981, 2, 0, 582, -2012, 0), (59981, 2, 1, 600, -2012, 0), (59981, 2, 2, 600, -1994, 0), (59981, 2, 3, 582, -1994, 0),
(59981, 3, 0, 499, -1973, 0), (59981, 3, 1, 517, -1973, 0), (59981, 3, 2, 517, -1955, 0), (59981, 3, 3, 499, -1955, 0),
(59981, 4, 0, 712, -1873, 0), (59981, 4, 1, 710, -1861, 0), (59981, 4, 2, 701, -1869, 0);

-- read-back
SELECT (SELECT COUNT(*) FROM `quest_template` WHERE `ID` IN (59975, 59978, 59979, 59980, 59981)) AS quests_must_be_5,
       (SELECT COUNT(*) FROM `creature` WHERE `Comment` LIKE 'DARK1A %') AS creatures_must_be_23,
       (SELECT COUNT(*) FROM `gameobject` WHERE `Comment` LIKE 'DARK1A %') AS objects_must_be_7,
       (SELECT COUNT(*) FROM `creature_template` WHERE `entry` IN (167596, 167598, 167633, 167632, 167631, 167183, 153239, 153580, 154103, 153581, 153582, 153583)) AS templates_must_be_12,
       (SELECT CONCAT(`IconName`, '/', `Data5`) FROM `gameobject_template` WHERE `entry` = 9326651) AS catapult_must_be_Cast_slash_1,
       (SELECT CONCAT(`IconName`, '/', `Data5`) FROM `gameobject_template` WHERE `entry` = 9339865) AS rune_must_be_Cast_slash_1,
       (SELECT COUNT(*) FROM `quest_poi` WHERE `QuestID` IN (59975, 59978, 59979, 59980, 59981)) AS poi_must_be_15;
