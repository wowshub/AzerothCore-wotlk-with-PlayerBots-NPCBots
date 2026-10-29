-- MBWD3C: run ONLY in the character database, with worldserver stopped.
-- No WORLD/AUTH changes. Existing rows are retained on reinstall.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_mbwd3c_install_check$$
CREATE PROCEDURE reborn_mbwd3c_install_check()
BEGIN
  IF (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE()
      AND table_name IN ('characters','character_spell')) <> 2 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='MBWD3C: select the CHARACTERS database first; stopped';
  END IF;
  CREATE TABLE IF NOT EXISTS reborn_mbwd_preferences (
    guid INT UNSIGNED NOT NULL,
    revision INT UNSIGNED NOT NULL DEFAULT 0,
    mask TINYINT UNSIGNED NOT NULL DEFAULT 3,
    PRIMARY KEY (guid),
    CONSTRAINT mbwd3c_mask CHECK (mask <= 3),
    CONSTRAINT mbwd3c_revision CHECK (revision <= 2000000000)
  ) ENGINE=InnoDB;
  IF (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE()
      AND table_name='reborn_mbwd_preferences') <> 3
    OR (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE()
      AND table_name='reborn_mbwd_preferences' AND is_nullable='NO' AND
      ((column_name='guid' AND column_type='int unsigned') OR
       (column_name='revision' AND column_type='int unsigned') OR
       (column_name='mask' AND column_type='tinyint unsigned'))) <> 3
    OR (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema=DATABASE()
      AND table_name='reborn_mbwd_preferences' AND index_name='PRIMARY' AND column_name='guid') <> 1
    OR (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema=DATABASE()
      AND table_name='reborn_mbwd_preferences' AND index_name='PRIMARY') <> 1
    OR (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE()
      AND table_name='reborn_mbwd_preferences' AND engine='InnoDB') <> 1 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='MBWD3C: existing preference table has an incompatible schema; stopped';
  END IF;
  IF EXISTS (SELECT 1 FROM reborn_mbwd_preferences WHERE mask>3 OR revision>2000000000) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='MBWD3C: invalid existing preference values; stopped';
  END IF;
END$$
CALL reborn_mbwd3c_install_check()$$
DROP PROCEDURE reborn_mbwd3c_install_check$$

DROP PROCEDURE IF EXISTS reborn_mbwd3c_state$$
CREATE PROCEDURE reborn_mbwd3c_state(IN p_guid INT UNSIGNED)
BEGIN
  SELECT 'ok' AS result, COALESCE(p.revision,0) AS revision, COALESCE(p.mask,3) AS mask
  FROM (SELECT 1 AS singleton) AS s
  LEFT JOIN reborn_mbwd_preferences AS p ON p.guid=p_guid;
END$$

DROP PROCEDURE IF EXISTS reborn_mbwd3c_set$$
CREATE PROCEDURE reborn_mbwd3c_set(IN p_guid INT UNSIGNED, IN p_expected INT UNSIGNED, IN p_mask INT UNSIGNED)
proc: BEGIN
  DECLARE v_revision INT UNSIGNED;
  DECLARE v_mask INT UNSIGNED;
  DECLARE v_result VARCHAR(8) DEFAULT 'ok';
  DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
  IF p_guid IS NULL OR p_expected IS NULL OR p_mask IS NULL OR p_guid=0 OR p_mask>3 OR p_expected>2000000000 THEN
    SELECT 'invalid' AS result, COALESCE(p.revision,0) AS revision, COALESCE(p.mask,3) AS mask
    FROM (SELECT 1 AS singleton) AS s LEFT JOIN reborn_mbwd_preferences AS p ON p.guid=p_guid;
    LEAVE proc;
  END IF;
  START TRANSACTION;
  -- Take an exclusive duplicate-key lock immediately. INSERT IGNORE followed
  -- by FOR UPDATE can deadlock when competing readers upgrade shared locks.
  INSERT INTO reborn_mbwd_preferences(guid,revision,mask) VALUES(p_guid,0,3)
    ON DUPLICATE KEY UPDATE guid=guid;
  SELECT revision,mask INTO v_revision,v_mask FROM reborn_mbwd_preferences WHERE guid=p_guid FOR UPDATE;
  IF v_revision>=2000000000 THEN SET v_result='invalid';
  ELSEIF v_revision<>p_expected THEN SET v_result='stale';
  ELSEIF v_mask<>p_mask THEN
    SET v_revision=v_revision+1;
    SET v_mask=p_mask;
    UPDATE reborn_mbwd_preferences SET revision=v_revision,mask=v_mask WHERE guid=p_guid;
  END IF;
  COMMIT;
  SELECT v_result AS result,v_revision AS revision,v_mask AS mask;
END$$
DELIMITER ;
