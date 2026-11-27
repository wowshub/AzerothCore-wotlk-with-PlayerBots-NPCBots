-- HARA4 V4: 首领削弱 + V3(方向文字、药剂水下呼吸)。world 库执行。可重复执行。
SELECT COUNT(*) AS hara4_quests_must_be_3 FROM `quest_template` WHERE `ID` IN (9190007, 91587, 91589);
UPDATE `gameobject_template` SET `Data10` = 7178 WHERE `entry` = 564999 AND `Data1` = 91585;
UPDATE `quest_template` SET `LogTitle` = REPLACE(`LogTitle`, 'A Smell from the South 南边飘来的香味', 'A Smell from the East 东边飘来的香味') WHERE `ID` = 9190007;
UPDATE `quest_template` SET `LogDescription` = REPLACE(`LogDescription`, 'south of Har''mara', 'about 400 yards east of Har''mara') WHERE `ID` = 9190007;
UPDATE `quest_template` SET `LogDescription` = REPLACE(`LogDescription`, '到哈尔玛拉南边的', '到哈尔玛拉东边约400码的') WHERE `ID` = 9190007;
UPDATE `quest_template` SET `QuestDescription` = REPLACE(`QuestDescription`, 'far to the south', 'far to the east') WHERE `ID` = 9190007;
UPDATE `quest_template` SET `QuestDescription` = REPLACE(`QuestDescription`, '在南边很远的', '在东边很远的') WHERE `ID` = 9190007;
UPDATE `quest_template` SET `LogDescription` = REPLACE(`LogDescription`, 'north of the grotto', 'about 150 yards west of the grotto') WHERE `ID` = 91587;
UPDATE `quest_template` SET `LogDescription` = REPLACE(`LogDescription`, '消灭洞窟北边的', '消灭洞窟西边约150码处的') WHERE `ID` = 91587;
UPDATE `quest_template` SET `LogDescription` = REPLACE(`LogDescription`, 'carry it north to Har''mara', 'carry it west to Har''mara') WHERE `ID` = 91589;
UPDATE `quest_template` SET `LogDescription` = REPLACE(`LogDescription`, '带回北边的哈尔玛拉', '向西带回哈尔玛拉') WHERE `ID` = 91589;
SELECT `ID`, `LogTitle`, `LogDescription` FROM `quest_template` WHERE `ID` IN (9190007, 91587, 91589) ORDER BY `ID`;
SELECT `Data10` AS spell_must_be_7178 FROM `gameobject_template` WHERE `entry` = 564999;
-- 首领 248598：血量系数 3.0 -> 2.0，伤害系数 1.1 -> 0.8，首次放毒 6-9 秒 -> 15-20 秒
SELECT `HealthModifier`, `DamageModifier` FROM `creature_template` WHERE `entry` = 248598;
UPDATE `creature_template` SET `HealthModifier` = 2.0, `DamageModifier` = 0.8 WHERE `entry` = 248598;
UPDATE `smart_scripts` SET `event_param1` = 15000, `event_param2` = 20000 WHERE `entryorguid` = 248598 AND `source_type` = 0 AND `id` = 0 AND `action_param1` = 744;
SELECT `HealthModifier` AS hp_must_be_2, `DamageModifier` AS damage_must_be_0_8 FROM `creature_template` WHERE `entry` = 248598;
SELECT `event_param1` AS poison_must_be_15000, `event_param2` AS poison_must_be_20000 FROM `smart_scripts` WHERE `entryorguid` = 248598 AND `source_type` = 0 AND `id` = 0;
