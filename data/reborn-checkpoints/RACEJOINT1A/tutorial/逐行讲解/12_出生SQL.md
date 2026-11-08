# 出生SQL：逐行讲解
以原ZIP默认守卫0为准，不使用被改动解压目录的默认1。长INSERT逐列参数在第四课对应解释。
来源：`A_服务端_Codex/交付/data/customfixsql/world/coa_birth/RACEJOINT1A/01_WORLD_RACENEXT1A_战士出生.sql`。以下行号是所附原件的真实行号；空行/注释也保留。

## 原代码
```sql
SET NAMES utf8mb4;
-- STAGED ONLY: requires coordinated server/client race support. Not a standalone playable-race installer.
-- Stop worldserver; back up WORLD and CHARACTERS. MyISAM tables are not transactional.
-- No skill/spell racemask rows are added: bits 7/17 are shared with existing races.
-- All conflicts are checked before the first birth-table INSERT. Do not use mysql --force.
DROP TEMPORARY TABLE IF EXISTS rn1_expected_0;
CREATE TEMPORARY TABLE rn1_expected_0 LIKE `playercreateinfo`;
INSERT INTO rn1_expected_0(`race`,`class`,`map`,`zone`,`position_x`,`position_y`,`position_z`,`orientation`) VALUES ('39','1','0','12','-8949.95','-132.493','83.5312','0'),('49','1','1','14','-618.518','-4251.67','38.718','0');
DROP TEMPORARY TABLE IF EXISTS rn1_expected_1;
CREATE TEMPORARY TABLE rn1_expected_1 LIKE `playercreateinfo_action`;
INSERT INTO rn1_expected_1(`race`,`class`,`button`,`action`,`type`) VALUES ('39','1','0','6603','0'),('39','1','72','78','0'),('39','1','83','117','128'),('49','1','0','6603','0'),('49','1','72','78','0'),('49','1','83','117','128');
DROP TEMPORARY TABLE IF EXISTS rn1_expected_2;
CREATE TEMPORARY TABLE rn1_expected_2 LIKE `playercreateinfo_item`;
INSERT INTO rn1_expected_2(`race`,`class`,`itemid`,`amount`,`Note`) VALUES ('39','1','117','4','RACENEXT1A: Warrior first-test food'),('49','1','117','4','RACENEXT1A: Warrior first-test food');
DROP TEMPORARY TABLE IF EXISTS rn1_expected_3;
CREATE TEMPORARY TABLE rn1_expected_3 LIKE `player_race_stats`;
INSERT INTO rn1_expected_3(`Race`,`Strength`,`Agility`,`Stamina`,`Intellect`,`Spirit`) VALUES ('39','0','0','0','0','0'),('49','3','-3','1','-3','2');
DELIMITER $$
DROP PROCEDURE IF EXISTS codex_racenext1a_install$$
CREATE PROCEDURE codex_racenext1a_install()
BEGIN
IF COALESCE(@RACENEXT1A_INTEGRATION_VERIFIED,0)<>1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RACENEXT1A: core/client integration must be verified first'; END IF;
IF EXISTS(SELECT 1 FROM `playercreateinfo` t LEFT JOIN rn1_expected_0 e ON t.`race` <=> e.`race` AND t.`class` <=> e.`class` AND t.`map` <=> e.`map` AND t.`zone` <=> e.`zone` AND t.`position_x` <=> e.`position_x` AND t.`position_y` <=> e.`position_y` AND t.`position_z` <=> e.`position_z` AND t.`orientation` <=> e.`orientation` WHERE t.`race` IN(39,49) AND e.`race` IS NULL) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RACENEXT1A: conflicting playercreateinfo; no birth writes'; END IF;
IF EXISTS(SELECT 1 FROM `playercreateinfo_action` t LEFT JOIN rn1_expected_1 e ON t.`race` <=> e.`race` AND t.`class` <=> e.`class` AND t.`button` <=> e.`button` AND t.`action` <=> e.`action` AND t.`type` <=> e.`type` WHERE t.`race` IN(39,49) AND e.`race` IS NULL) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RACENEXT1A: conflicting playercreateinfo_action; no birth writes'; END IF;
IF EXISTS(SELECT 1 FROM `playercreateinfo_item` t LEFT JOIN rn1_expected_2 e ON t.`race` <=> e.`race` AND t.`class` <=> e.`class` AND t.`itemid` <=> e.`itemid` AND t.`amount` <=> e.`amount` AND t.`Note` <=> e.`Note` WHERE t.`race` IN(39,49) AND e.`race` IS NULL) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RACENEXT1A: conflicting playercreateinfo_item; no birth writes'; END IF;
IF EXISTS(SELECT 1 FROM `player_race_stats` t LEFT JOIN rn1_expected_3 e ON t.`Race` <=> e.`Race` AND t.`Strength` <=> e.`Strength` AND t.`Agility` <=> e.`Agility` AND t.`Stamina` <=> e.`Stamina` AND t.`Intellect` <=> e.`Intellect` AND t.`Spirit` <=> e.`Spirit` WHERE t.`Race` IN(39,49) AND e.`Race` IS NULL) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RACENEXT1A: conflicting player_race_stats; no birth writes'; END IF;
IF (SELECT COUNT(*) FROM item_template WHERE entry IN(38,117,6125,6948,12282,49778,899990,899991,899992,899993,899994,900025,900026,900027,900028,900029) AND AllowableRace=-1 AND (AllowableClass & 1)<>0)<>16 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RACENEXT1A: incompatible starter items'; END IF;
INSERT INTO `playercreateinfo`(`race`,`class`,`map`,`zone`,`position_x`,`position_y`,`position_z`,`orientation`) SELECT e.`race`,e.`class`,e.`map`,e.`zone`,e.`position_x`,e.`position_y`,e.`position_z`,e.`orientation` FROM rn1_expected_0 e WHERE NOT EXISTS(SELECT 1 FROM `playercreateinfo` t WHERE t.`race` <=> e.`race` AND t.`class` <=> e.`class` AND t.`map` <=> e.`map` AND t.`zone` <=> e.`zone` AND t.`position_x` <=> e.`position_x` AND t.`position_y` <=> e.`position_y` AND t.`position_z` <=> e.`position_z` AND t.`orientation` <=> e.`orientation`);
INSERT INTO `playercreateinfo_action`(`race`,`class`,`button`,`action`,`type`) SELECT e.`race`,e.`class`,e.`button`,e.`action`,e.`type` FROM rn1_expected_1 e WHERE NOT EXISTS(SELECT 1 FROM `playercreateinfo_action` t WHERE t.`race` <=> e.`race` AND t.`class` <=> e.`class` AND t.`button` <=> e.`button` AND t.`action` <=> e.`action` AND t.`type` <=> e.`type`);
INSERT INTO `playercreateinfo_item`(`race`,`class`,`itemid`,`amount`,`Note`) SELECT e.`race`,e.`class`,e.`itemid`,e.`amount`,e.`Note` FROM rn1_expected_2 e WHERE NOT EXISTS(SELECT 1 FROM `playercreateinfo_item` t WHERE t.`race` <=> e.`race` AND t.`class` <=> e.`class` AND t.`itemid` <=> e.`itemid` AND t.`amount` <=> e.`amount` AND t.`Note` <=> e.`Note`);
INSERT INTO `player_race_stats`(`Race`,`Strength`,`Agility`,`Stamina`,`Intellect`,`Spirit`) SELECT e.`Race`,e.`Strength`,e.`Agility`,e.`Stamina`,e.`Intellect`,e.`Spirit` FROM rn1_expected_3 e WHERE NOT EXISTS(SELECT 1 FROM `player_race_stats` t WHERE t.`Race` <=> e.`Race` AND t.`Strength` <=> e.`Strength` AND t.`Agility` <=> e.`Agility` AND t.`Stamina` <=> e.`Stamina` AND t.`Intellect` <=> e.`Intellect` AND t.`Spirit` <=> e.`Spirit`);
SELECT 'RACENEXT1A: birth rows prepared; no racial spells granted' AS result;
END$$
CALL codex_racenext1a_install()$$
DROP PROCEDURE codex_racenext1a_install$$
DELIMITER ;
```

## 一行一行读
| 原件行号 | 代码 | 大白话解释 |
|---:|---|---|
| 1 | <code>SET NAMES utf8mb4;</code> | 将本SQL会话字符编码设utf8mb4，中文说明不乱码。 |
| 2 | <code>-- STAGED ONLY: requires coordinated server/client race support. Not a standalone playable-race installer.</code> | 说明注释：STAGED ONLY: requires coordinated server/client race support. Not a standalone playable-race installer.；它不执行，实际条件仍以相邻代码为准。 |
| 3 | <code>-- Stop worldserver; back up WORLD and CHARACTERS. MyISAM tables are not transactional.</code> | 说明注释：Stop worldserver; back up WORLD and CHARACTERS. MyISAM tables are not transactional.；它不执行，实际条件仍以相邻代码为准。 |
| 4 | <code>-- No skill/spell racemask rows are added: bits 7/17 are shared with existing races.</code> | 说明注释：No skill/spell racemask rows are added: bits 7/17 are shared with existing races.；它不执行，实际条件仍以相邻代码为准。 |
| 5 | <code>-- All conflicts are checked before the first birth-table INSERT. Do not use mysql --force.</code> | 说明注释：All conflicts are checked before the first birth-table INSERT. Do not use mysql --force.；它不执行，实际条件仍以相邻代码为准。 |
| 6 | <code>DROP TEMPORARY TABLE IF EXISTS rn1_expected_0;</code> | 清理同名本会话暂存，不删除正式角色/出生表。 |
| 7 | <code>CREATE TEMPORARY TABLE rn1_expected_0 LIKE `playercreateinfo`;</code> | 建立当前SQL会话临时的期望表，列结构复制现有目标表。 |
| 8 | <code>INSERT INTO rn1_expected_0(`race`,`class`,`map`,`zone`,`position_x`,`position_y`,`position_z`,`orientation`) VALUES ('39','1','0','12','-8949.95','-132.493','83.5312','0'),('49','1','1','14','-618.518','-4251.67','38.718','0');</code> | 填写本次期望行：INSERT INTO rn1_expected_0(`race`,`class`,`map`,`zone`,`position_x`,`position_y`,`position_z`,`orientation`) VALUES ('39','1','0','12','-8949.95','-132.493','83.5312','0'),('49','1','1','14','-618.518','-4251.67','38.718','0');；暂不写正式出生表。列含义按本课数据参数章节逐个对应。 |
| 9 | <code>DROP TEMPORARY TABLE IF EXISTS rn1_expected_1;</code> | 清理同名本会话暂存，不删除正式角色/出生表。 |
| 10 | <code>CREATE TEMPORARY TABLE rn1_expected_1 LIKE `playercreateinfo_action`;</code> | 建立当前SQL会话临时的期望表，列结构复制现有目标表。 |
| 11 | <code>INSERT INTO rn1_expected_1(`race`,`class`,`button`,`action`,`type`) VALUES ('39','1','0','6603','0'),('39','1','72','78','0'),('39','1','83','117','128'),('49','1','0','6603','0'),('49','1','72','78','0'),('49','1','83','117','128');</code> | 填写本次期望行：INSERT INTO rn1_expected_1(`race`,`class`,`button`,`action`,`type`) VALUES ('39','1','0','6603','0'),('39','1','72','78','0'),('39','1','83','117','128'),('49','1','0','6603','0'),('49','1','72','78','0'),('49','1','83','117','128');；暂不写正式出生表。列含义按本课数据参数章节逐个对应。 |
| 12 | <code>DROP TEMPORARY TABLE IF EXISTS rn1_expected_2;</code> | 清理同名本会话暂存，不删除正式角色/出生表。 |
| 13 | <code>CREATE TEMPORARY TABLE rn1_expected_2 LIKE `playercreateinfo_item`;</code> | 建立当前SQL会话临时的期望表，列结构复制现有目标表。 |
| 14 | <code>INSERT INTO rn1_expected_2(`race`,`class`,`itemid`,`amount`,`Note`) VALUES ('39','1','117','4','RACENEXT1A: Warrior first-test food'),('49','1','117','4','RACENEXT1A: Warrior first-test food');</code> | 填写本次期望行：INSERT INTO rn1_expected_2(`race`,`class`,`itemid`,`amount`,`Note`) VALUES ('39','1','117','4','RACENEXT1A: Warrior first-test food'),('49','1','117','4','RACENEXT1A: Warrior first-test food');；暂不写正式出生表。列含义按本课数据参数章节逐个对应。 |
| 15 | <code>DROP TEMPORARY TABLE IF EXISTS rn1_expected_3;</code> | 清理同名本会话暂存，不删除正式角色/出生表。 |
| 16 | <code>CREATE TEMPORARY TABLE rn1_expected_3 LIKE `player_race_stats`;</code> | 建立当前SQL会话临时的期望表，列结构复制现有目标表。 |
| 17 | <code>INSERT INTO rn1_expected_3(`Race`,`Strength`,`Agility`,`Stamina`,`Intellect`,`Spirit`) VALUES ('39','0','0','0','0','0'),('49','3','-3','1','-3','2');</code> | 填写本次期望行：INSERT INTO rn1_expected_3(`Race`,`Strength`,`Agility`,`Stamina`,`Intellect`,`Spirit`) VALUES ('39','0','0','0','0','0'),('49','3','-3','1','-3','2');；暂不写正式出生表。列含义按本课数据参数章节逐个对应。 |
| 18 | <code>DELIMITER $$</code> | 改变MySQL客户端语句结束标记，使存储过程内的分号不会提前截断过程。 |
| 19 | <code>DROP PROCEDURE IF EXISTS codex_racenext1a_install$$</code> | 移除本次临时安装过程定义，不删出生数据。 |
| 20 | <code>CREATE PROCEDURE codex_racenext1a_install()</code> | 把所有守卫和最终写入放同一次受控调用；并不让MyISAM自动变成事务表。 |
| 21 | <code>BEGIN</code> | 开始一个作用域/流程块，后面的局部变量和分支属于它。 |
| 22 | <code>IF COALESCE(@RACENEXT1A_INTEGRATION_VERIFIED,0)&lt;&gt;1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RACENEXT1A: core/client integration must be verified first'; END IF;</code> | 确认变量未设置时取0；不等于1就SIGNAL拒绝，这是冻结ZIP的原始守卫。 |
| 23 | <code>IF EXISTS(SELECT 1 FROM `playercreateinfo` t LEFT JOIN rn1_expected_0 e ON t.`race` &lt;=&gt; e.`race` AND t.`class` &lt;=&gt; e.`class` AND t.`map` &lt;=&gt; e.`map` AND t.`zone` &lt;=&gt; e.`zone` AND t.`position_x` &lt;=&gt; e.`position_x` AND t.`position_y` &lt;=&gt; e.`position_y` AND t.`position_z` &lt;=&gt; e.`position_z` AND t.`orientation` &lt;=&gt; e.`orientation` WHERE t.`race` IN(39,49) AND e.`race` IS NULL) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RACENEXT1A: conflicting playercreateinfo; no birth writes'; END IF;</code> | 逐列将已有39/49行和本次期望行比对；出现未识别行，出生表写入前报错。 |
| 24 | <code>IF EXISTS(SELECT 1 FROM `playercreateinfo_action` t LEFT JOIN rn1_expected_1 e ON t.`race` &lt;=&gt; e.`race` AND t.`class` &lt;=&gt; e.`class` AND t.`button` &lt;=&gt; e.`button` AND t.`action` &lt;=&gt; e.`action` AND t.`type` &lt;=&gt; e.`type` WHERE t.`race` IN(39,49) AND e.`race` IS NULL) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RACENEXT1A: conflicting playercreateinfo_action; no birth writes'; END IF;</code> | 逐列将已有39/49行和本次期望行比对；出现未识别行，出生表写入前报错。 |
| 25 | <code>IF EXISTS(SELECT 1 FROM `playercreateinfo_item` t LEFT JOIN rn1_expected_2 e ON t.`race` &lt;=&gt; e.`race` AND t.`class` &lt;=&gt; e.`class` AND t.`itemid` &lt;=&gt; e.`itemid` AND t.`amount` &lt;=&gt; e.`amount` AND t.`Note` &lt;=&gt; e.`Note` WHERE t.`race` IN(39,49) AND e.`race` IS NULL) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RACENEXT1A: conflicting playercreateinfo_item; no birth writes'; END IF;</code> | 逐列将已有39/49行和本次期望行比对；出现未识别行，出生表写入前报错。 |
| 26 | <code>IF EXISTS(SELECT 1 FROM `player_race_stats` t LEFT JOIN rn1_expected_3 e ON t.`Race` &lt;=&gt; e.`Race` AND t.`Strength` &lt;=&gt; e.`Strength` AND t.`Agility` &lt;=&gt; e.`Agility` AND t.`Stamina` &lt;=&gt; e.`Stamina` AND t.`Intellect` &lt;=&gt; e.`Intellect` AND t.`Spirit` &lt;=&gt; e.`Spirit` WHERE t.`Race` IN(39,49) AND e.`Race` IS NULL) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RACENEXT1A: conflicting player_race_stats; no birth writes'; END IF;</code> | 逐列将已有39/49行和本次期望行比对；出现未识别行，出生表写入前报错。 |
| 27 | <code>IF (SELECT COUNT(*) FROM item_template WHERE entry IN(38,117,6125,6948,12282,49778,899990,899991,899992,899993,899994,900025,900026,900027,900028,900029) AND AllowableRace=-1 AND (AllowableClass &amp; 1)&lt;&gt;0)&lt;&gt;16 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RACENEXT1A: incompatible starter items'; END IF;</code> | 必须16件起始物品全存在、无种族限制，且职业掩码包含战士位1，缺一件就拒绝。 |
| 28 | <code>INSERT INTO `playercreateinfo`(`race`,`class`,`map`,`zone`,`position_x`,`position_y`,`position_z`,`orientation`) SELECT e.`race`,e.`class`,e.`map`,e.`zone`,e.`position_x`,e.`position_y`,e.`position_z`,e.`orientation` FROM rn1_expected_0 e WHERE NOT EXISTS(SELECT 1 FROM `playercreateinfo` t WHERE t.`race` &lt;=&gt; e.`race` AND t.`class` &lt;=&gt; e.`class` AND t.`map` &lt;=&gt; e.`map` AND t.`zone` &lt;=&gt; e.`zone` AND t.`position_x` &lt;=&gt; e.`position_x` AND t.`position_y` &lt;=&gt; e.`position_y` AND t.`position_z` &lt;=&gt; e.`position_z` AND t.`orientation` &lt;=&gt; e.`orientation`);</code> | 只插入还不存在的完全相同行，重导不会重复发/写出生记录。 |
| 29 | <code>INSERT INTO `playercreateinfo_action`(`race`,`class`,`button`,`action`,`type`) SELECT e.`race`,e.`class`,e.`button`,e.`action`,e.`type` FROM rn1_expected_1 e WHERE NOT EXISTS(SELECT 1 FROM `playercreateinfo_action` t WHERE t.`race` &lt;=&gt; e.`race` AND t.`class` &lt;=&gt; e.`class` AND t.`button` &lt;=&gt; e.`button` AND t.`action` &lt;=&gt; e.`action` AND t.`type` &lt;=&gt; e.`type`);</code> | 只插入还不存在的完全相同行，重导不会重复发/写出生记录。 |
| 30 | <code>INSERT INTO `playercreateinfo_item`(`race`,`class`,`itemid`,`amount`,`Note`) SELECT e.`race`,e.`class`,e.`itemid`,e.`amount`,e.`Note` FROM rn1_expected_2 e WHERE NOT EXISTS(SELECT 1 FROM `playercreateinfo_item` t WHERE t.`race` &lt;=&gt; e.`race` AND t.`class` &lt;=&gt; e.`class` AND t.`itemid` &lt;=&gt; e.`itemid` AND t.`amount` &lt;=&gt; e.`amount` AND t.`Note` &lt;=&gt; e.`Note`);</code> | 只插入还不存在的完全相同行，重导不会重复发/写出生记录。 |
| 31 | <code>INSERT INTO `player_race_stats`(`Race`,`Strength`,`Agility`,`Stamina`,`Intellect`,`Spirit`) SELECT e.`Race`,e.`Strength`,e.`Agility`,e.`Stamina`,e.`Intellect`,e.`Spirit` FROM rn1_expected_3 e WHERE NOT EXISTS(SELECT 1 FROM `player_race_stats` t WHERE t.`Race` &lt;=&gt; e.`Race` AND t.`Strength` &lt;=&gt; e.`Strength` AND t.`Agility` &lt;=&gt; e.`Agility` AND t.`Stamina` &lt;=&gt; e.`Stamina` AND t.`Intellect` &lt;=&gt; e.`Intellect` AND t.`Spirit` &lt;=&gt; e.`Spirit`);</code> | 只插入还不存在的完全相同行，重导不会重复发/写出生记录。 |
| 32 | <code>SELECT 'RACENEXT1A: birth rows prepared; no racial spells granted' AS result;</code> | 此行属于“出生SQL”：`SELECT 'RACENEXT1A: birth rows prepared; no racial spells granted' AS result;`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 33 | <code>END$$</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 34 | <code>CALL codex_racenext1a_install()$$</code> | 在完整检查过程定义好后调用；失败须停止，不执行后续写入。 |
| 35 | <code>DROP PROCEDURE codex_racenext1a_install$$</code> | 移除本次临时安装过程定义，不删出生数据。 |
| 36 | <code>DELIMITER ;</code> | 改变MySQL客户端语句结束标记，使存储过程内的分号不会提前截断过程。 |
