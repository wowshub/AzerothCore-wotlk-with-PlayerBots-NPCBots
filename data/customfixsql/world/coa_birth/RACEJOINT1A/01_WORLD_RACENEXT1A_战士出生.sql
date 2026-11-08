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
IF COALESCE(@RACENEXT1A_INTEGRATION_VERIFIED,1)<>1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RACENEXT1A: core/client integration must be verified first'; END IF;
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
