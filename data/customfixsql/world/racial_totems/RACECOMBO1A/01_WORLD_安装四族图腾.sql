SET NAMES utf8mb4;
-- WORLD only. Default DENY. Verify source, BOTH client archives and server DBC first.
-- Then explicitly SET @RACECOMBO1A_READY=1 in this same connection before running.
DROP TEMPORARY TABLE IF EXISTS racecombo1a_expected;
CREATE TEMPORARY TABLE racecombo1a_expected(TotemID TINYINT UNSIGNED,RaceID TINYINT UNSIGNED,ModelID INT UNSIGNED,FallbackID INT UNSIGNED,PRIMARY KEY(TotemID,RaceID));
INSERT INTO racecombo1a_expected VALUES (1,36,61100,19074),(2,36,61101,19073),(3,36,61102,19075),(4,36,61103,19071),(1,37,61104,30758),(2,37,61105,30757),(3,37,61106,30759),(4,37,61107,30756),(1,39,61108,19074),(2,39,61109,19073),(3,39,61110,19075),(4,39,61111,19071),(1,49,61112,30758),(2,49,61113,30757),(3,49,61114,30759),(4,49,61115,30756);
DROP TEMPORARY TABLE IF EXISTS racecombo1a_modelinfo;
CREATE TEMPORARY TABLE racecombo1a_modelinfo LIKE creature_model_info;
INSERT INTO racecombo1a_modelinfo(DisplayID,BoundingRadius,CombatReach,Gender,DisplayID_Other_Gender,VerifiedBuild) VALUES (61100,1,1,2,0,0),(61101,1,1,2,0,0),(61102,1,1,2,0,0),(61103,1,1,2,0,0),(61104,0,0,2,0,0),(61105,0,0,2,0,0),(61106,0,0,2,0,0),(61107,0,0,2,0,0),(61108,1,1,2,0,0),(61109,1,1,2,0,0),(61110,1,1,2,0,0),(61111,1,1,2,0,0),(61112,0,0,2,0,0),(61113,0,0,2,0,0),(61114,0,0,2,0,0),(61115,0,0,2,0,0);
DELIMITER $$
DROP PROCEDURE IF EXISTS codex_racecombo1a_install$$
CREATE PROCEDURE codex_racecombo1a_install()
BEGIN
 DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
 IF COALESCE(@RACECOMBO1A_READY,0)<>1 THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RACECOMBO1A: default deny; verify core/client/server and backups';
 END IF;
 IF (SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME IN('player_totem_model','creature_model_info') AND ENGINE='InnoDB')<>2 THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RACECOMBO1A: InnoDB required for atomic mapping installation';
 END IF;
 IF EXISTS(SELECT 1 FROM player_totem_model t JOIN racecombo1a_expected e USING(TotemID,RaceID)
  WHERE t.ModelID NOT IN(e.ModelID,e.FallbackID)) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RACECOMBO1A: conflicting racial totem mapping; no mapping writes';
 END IF;
 IF EXISTS(SELECT 1 FROM creature_model_info t JOIN racecombo1a_modelinfo e USING(DisplayID) WHERE NOT(t.BoundingRadius <=> e.BoundingRadius AND t.CombatReach <=> e.CombatReach AND t.Gender <=> e.Gender AND t.DisplayID_Other_Gender <=> e.DisplayID_Other_Gender AND t.VerifiedBuild <=> e.VerifiedBuild)) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RACECOMBO1A: private creature model metadata conflict; no writes';
 END IF;
 IF EXISTS(SELECT 1 FROM player_totem_model t JOIN racecombo1a_expected e USING(TotemID,RaceID) WHERE t.ModelID=e.ModelID) THEN
  IF NOT EXISTS(SELECT 1 FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='reborn_racecombo1a_totem_backup') THEN
   SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RACECOMBO1A: installed mappings without original backup; refuse to fabricate rollback';
  END IF;
  IF (SELECT COUNT(*) FROM reborn_racecombo1a_totem_backup b JOIN racecombo1a_expected e USING(TotemID,RaceID))<>16 THEN
   SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RACECOMBO1A: incomplete original backup; no writes';
  END IF;
 END IF;
 CREATE TABLE IF NOT EXISTS reborn_racecombo1a_totem_backup(
  TotemID TINYINT UNSIGNED NOT NULL,RaceID TINYINT UNSIGNED NOT NULL,
  HadRow TINYINT UNSIGNED NOT NULL,ModelID INT UNSIGNED NULL,
  PRIMARY KEY(TotemID,RaceID)) ENGINE=InnoDB;
 -- Never replace the original backup on a repeated install.
 START TRANSACTION;
 INSERT IGNORE INTO reborn_racecombo1a_totem_backup(TotemID,RaceID,HadRow,ModelID)
  SELECT e.TotemID,e.RaceID,IF(t.ModelID IS NULL,0,1),t.ModelID
  FROM racecombo1a_expected e LEFT JOIN player_totem_model t USING(TotemID,RaceID);
 -- Preserve the native fallback totem's gameplay radius/reach; only art changes.
 INSERT IGNORE INTO creature_model_info(DisplayID,BoundingRadius,CombatReach,Gender,DisplayID_Other_Gender,VerifiedBuild)
  SELECT DisplayID,BoundingRadius,CombatReach,Gender,DisplayID_Other_Gender,VerifiedBuild FROM racecombo1a_modelinfo;
 INSERT INTO player_totem_model(TotemID,RaceID,ModelID)
  SELECT TotemID,RaceID,ModelID FROM racecombo1a_expected
  ON DUPLICATE KEY UPDATE ModelID=VALUES(ModelID);
 COMMIT;
 SELECT 'RACECOMBO1A: installed 16 racial totem mappings; full worldserver restart required' AS result;
END$$
CALL codex_racecombo1a_install()$$
DROP PROCEDURE codex_racecombo1a_install$$
DELIMITER ;
