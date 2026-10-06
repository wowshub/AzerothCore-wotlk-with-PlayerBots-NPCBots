-- ============================================================
-- 科赞地精 前置剧情对白(进游戏后NPC说,纯服务器端)
-- 剧情:地精从科赞地下监狱越狱,被海水冲到岸边,萨斯发现并收编
-- 配合任务1「打理生意」quest=90011
-- ============================================================

-- ---------- 1. 重写任务1的剧情文本(萨斯对话框讲背景故事) ----------
UPDATE `quest_template` SET
`LogTitle` = '打理生意',
`QuestDescription` =
'$N!醒醒!你还活着?$B$B'
'我是萨斯,锈水财阀的人。你这副狼狈样……是从财阀那座地下监狱逃出来的吧?'
'就你一个?那场风暴把半个码头都掀翻了,牢门一开,囚犯全跳进海里逃命。'
'能被海浪冲上岸还有口气的,你算走运。$B$B'
'听着,小子——欠债的事我可以帮你"抹平",但天下没有免费的午餐。'
'财阀缺人手,你现在就归我管了。去海滩那头找工头丹普威克<class>报到,他会安排你干活。$B$B'
'干得好,债一笔勾销;干不好……嘿嘿,大海随时欢迎你回去。',
`LogDescription` = '去海滩另一头找锈水财阀的工头丹普威克报到。',
`QuestCompletionLog` = '你找到了工头丹普威克。'
WHERE `ID` = 90011;

-- ---------- 2. 萨斯设为SmartAI(才能触发喊话) ----------
UPDATE `creature_template` SET `AIName`='SmartAI' WHERE `entry`=900110;

-- ---------- 3. 萨斯的剧情喊话(creature_text) ----------
-- GroupID 0 = 一组喊话(玩家靠近时随机/按序播放)
DELETE FROM `creature_text` WHERE `CreatureID`=900110;
INSERT INTO `creature_text`
(`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`BroadcastTextId`,`TextRange`,`comment`)
VALUES
-- GroupID 0:玩家靠近时(发现落难者)
(900110,0,0,'喂——!海边那个!你还有气没有?别躺那儿喂螃蟹了!',12,0,100,5,0,0,0,0,'萨斯-发现玩家'),
(900110,0,1,'又一个从监狱逃出来的倒霉蛋……被海水冲上来的,啧啧。',12,0,100,1,0,0,0,0,'萨斯-发现玩家2'),
-- GroupID 1:玩家接任务后(指路)
(900110,1,0,'别愣着了,去找丹普威克!他在海滩那头,看到那台破钻机就是。',12,0,100,25,0,0,0,0,'萨斯-指路');

-- ---------- 4. 萨斯SmartAI脚本 ----------
-- event 10 OOC_LOS参数: HostilityMode(0任意),MaxRange(15码),CooldownMin,CooldownMax,PlayerOnly(1)
-- event 19 ACCEPTED_QUEST参数: QuestID, CooldownMin, CooldownMax
-- action 1 TALK参数: GroupID
DELETE FROM `smart_scripts` WHERE `entryorguid`=900110 AND `source_type`=0;
INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,
 `event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`event_param6`,
 `action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,
 `target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES
-- 玩家靠近15码喊话(GroupID 0),冷却15-25秒,仅对玩家
(900110,0,0,0, 10,0,100,0, 0,15,15000,25000,1,0, 1,0,0,0,0,0,0, 7,0,0,0,0,0,0,0,0,'萨斯-玩家靠近喊话'),
-- 接任务90011时喊话(GroupID 1 指路)
(900110,0,1,0, 19,0,100,0, 90011,0,0,0,0,0, 1,1,0,0,0,0,0, 7,0,0,0,0,0,0,0,0,'萨斯-接任务指路');

-- ---------- 5. 丹普威克设为SmartAI + 交任务喊话 ----------
UPDATE `creature_template` SET `AIName`='SmartAI' WHERE `entry`=900111;

DELETE FROM `creature_text` WHERE `CreatureID`=900111;
INSERT INTO `creature_text`
(`CreatureID`,`GroupID`,`ID`,`Text`,`Type`,`Language`,`Probability`,`Emote`,`Duration`,`Sound`,`BroadcastTextId`,`TextRange`,`comment`)
VALUES
-- GroupID 0:玩家靠近
(900111,0,0,'萨斯又给我送来个"新鲜货"?行吧,反正监狱里跑出来的也得有人管。',12,0,100,1,0,0,0,0,'丹普威克-发现玩家'),
-- GroupID 1:交任务后(正式收编)
(900111,1,0,'报到了?很好。欢迎加入锈水财阀,新人——从今天起,你的"前途"是财阀的了!科赞的钱可不会自己长出来,活儿多得是!',12,0,100,5,0,0,0,0,'丹普威克-收编');

-- 丹普威克SmartAI: 靠近喊话 + 交任务喊话
DELETE FROM `smart_scripts` WHERE `entryorguid`=900111 AND `source_type`=0;
INSERT INTO `smart_scripts`
(`entryorguid`,`source_type`,`id`,`link`,`event_type`,`event_phase_mask`,`event_chance`,`event_flags`,
 `event_param1`,`event_param2`,`event_param3`,`event_param4`,`event_param5`,`event_param6`,
 `action_type`,`action_param1`,`action_param2`,`action_param3`,`action_param4`,`action_param5`,`action_param6`,
 `target_type`,`target_param1`,`target_param2`,`target_param3`,`target_param4`,`target_x`,`target_y`,`target_z`,`target_o`,`comment`)
VALUES
-- 玩家靠近15码喊话(GroupID 0),冷却15-25秒,仅对玩家
(900111,0,0,0, 10,0,100,0, 0,15,15000,25000,1,0, 1,0,0,0,0,0,0, 7,0,0,0,0,0,0,0,0,'丹普威克-玩家靠近喊话'),
-- 交任务90011时喊话(GroupID 1 收编)
(900111,0,1,0, 20,0,100,0, 90011,0,0,0,0,0, 1,1,0,0,0,0,0, 7,0,0,0,0,0,0,0,0,'丹普威克-交任务收编');
