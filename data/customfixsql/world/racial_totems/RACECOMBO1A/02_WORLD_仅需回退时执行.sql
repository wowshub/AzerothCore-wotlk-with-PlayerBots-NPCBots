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
DROP PROCEDURE IF EXISTS codex_racecombo1a_rollback$$
CREATE PROCEDURE codex_racecombo1a_rollback()
BEGIN
 DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
 IF COALESCE(@RACECOMBO1A_READY,0)<>1 THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RACECOMBO1A: rollback also requires explicit same-session approval';
 END IF;
 IF (SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME IN('player_totem_model','creature_model_info') AND ENGINE='InnoDB')<>2 THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RACECOMBO1A: InnoDB required for atomic mapping rollback';
 END IF;
 IF (SELECT COUNT(*) FROM reborn_racecombo1a_totem_backup)<>16 OR
    (SELECT COUNT(*) FROM reborn_racecombo1a_totem_backup b JOIN racecombo1a_expected e USING(TotemID,RaceID))<>16 OR
    EXISTS(SELECT 1 FROM reborn_racecombo1a_totem_backup WHERE HadRow NOT IN(0,1) OR (HadRow=1 AND (ModelID IS NULL OR ModelID BETWEEN 61100 AND 61115))) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RACECOMBO1A: exact installation backup missing';
 END IF;
 IF EXISTS(SELECT 1 FROM player_totem_model t JOIN racecombo1a_expected e USING(TotemID,RaceID)
  JOIN reborn_racecombo1a_totem_backup b USING(TotemID,RaceID)
  WHERE t.ModelID<>e.ModelID AND NOT(b.HadRow=1 AND t.ModelID=b.ModelID)) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RACECOMBO1A: later mapping changes found; refuse rollback';
 END IF;
 IF EXISTS(SELECT 1 FROM creature_model_info t JOIN racecombo1a_modelinfo e USING(DisplayID) WHERE NOT(t.BoundingRadius <=> e.BoundingRadius AND t.CombatReach <=> e.CombatReach AND t.Gender <=> e.Gender AND t.DisplayID_Other_Gender <=> e.DisplayID_Other_Gender AND t.VerifiedBuild <=> e.VerifiedBuild)) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='RACECOMBO1A: later private model metadata changes; refuse rollback';
 END IF;
 START TRANSACTION;
 DELETE t FROM player_totem_model t JOIN racecombo1a_expected e USING(TotemID,RaceID);
 INSERT INTO player_totem_model(TotemID,RaceID,ModelID)
  SELECT TotemID,RaceID,ModelID FROM reborn_racecombo1a_totem_backup WHERE HadRow=1;
 DELETE t FROM creature_model_info t JOIN racecombo1a_modelinfo e USING(DisplayID);
 COMMIT;
 SELECT 'RACECOMBO1A: restored exact original racial totem rows; backup retained' AS result;
END$$
CALL codex_racecombo1a_rollback()$$
DROP PROCEDURE codex_racecombo1a_rollback$$
DELIMITER ;
