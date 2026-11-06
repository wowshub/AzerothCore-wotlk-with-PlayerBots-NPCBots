-- WHTAL7A CHARACTERS one cumulative installer. Stop server; stop on errors.
SET NAMES utf8mb4;
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wht7_char_install$$
CREATE PROCEDURE reborn_wht7_char_install()
BEGIN
 IF (SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME IN('reborn_wh_t1_state','reborn_wh_t1_nodes','reborn_wh_t1_intents')) NOT IN(0,3)
 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WHTAL7A: incomplete old talent tables; do not recreate missing data';END IF;
CREATE TABLE IF NOT EXISTS reborn_wh_t1_state (
 guid INT UNSIGNED NOT NULL, account INT UNSIGNED NOT NULL,
 revision INT UNSIGNED NOT NULL DEFAULT 0, schema_version INT UNSIGNED NOT NULL DEFAULT 1,
 PRIMARY KEY(guid), CHECK(schema_version>=1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS reborn_wh_t1_nodes (
 guid INT UNSIGNED NOT NULL, node_id INT UNSIGNED NOT NULL, `rank` TINYINT UNSIGNED NOT NULL,
 PRIMARY KEY(guid,node_id), CHECK(node_id IN(34538,7451)), CHECK(`rank`=1)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE IF NOT EXISTS reborn_wh_t1_intents (
 op_key VARCHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
 guid INT UNSIGNED NOT NULL, account INT UNSIGNED NOT NULL, expected_revision INT UNSIGNED NOT NULL,
 old_mask TINYINT UNSIGNED NOT NULL, target_mask TINYINT UNSIGNED NOT NULL,
 kind TINYINT UNSIGNED NOT NULL, level_snapshot TINYINT UNSIGNED NOT NULL,
 cost INT UNSIGNED NOT NULL, money_before INT UNSIGNED NOT NULL,
 status TINYINT UNSIGNED NOT NULL DEFAULT 0, outcome TINYINT UNSIGNED NOT NULL DEFAULT 0,
 created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 PRIMARY KEY(op_key), KEY ix_wh_t1_pending(guid,status),
 CHECK(status IN(0,1,2)), CHECK(outcome IN(0,1)), CHECK(kind IN(0,1)),
 CHECK(old_mask<=3 AND target_mask<=3), CHECK(cost IN(0,100000))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

IF (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='reborn_wh_t1_state')<>4
 OR (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='reborn_wh_t1_nodes')<>3
 OR (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='reborn_wh_t1_intents')<>13
 OR (SELECT COUNT(*) FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME IN('reborn_wh_t1_state','reborn_wh_t1_nodes','reborn_wh_t1_intents') AND ENGINE='InnoDB')<>3
 OR EXISTS(SELECT 1 FROM reborn_wh_t1_state WHERE schema_version NOT IN(1,2,3,4,5,6,7) OR revision>=2000000000)
 OR EXISTS(SELECT 1 FROM reborn_wh_t1_intents WHERE status<2)
 OR EXISTS(SELECT 1 FROM reborn_wh_t1_nodes WHERE node_id NOT IN(34538,7451,6415,6457,7424,6413,29150,34592) OR (node_id IN(7451,6457,7424,6413,29150,34592) AND `rank`<>1) OR (node_id IN(34538,6415) AND `rank` NOT IN(1,2)))
 OR EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND CONSTRAINT_TYPE='CHECK' AND TABLE_NAME='reborn_wh_t1_nodes' AND CONSTRAINT_NAME NOT IN('reborn_wh_t1_nodes_chk_1','reborn_wh_t1_nodes_chk_2','wht2_node_ids','wht2_node_ranks','wht3_node_ids','wht3_node_ranks','wht4_node_ids','wht4_node_ranks','wht5_node_ids','wht5_node_ranks','wht6_node_ids','wht6_node_ranks','wht7_node_ids','wht7_node_ranks'))
 OR EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND CONSTRAINT_TYPE='CHECK' AND TABLE_NAME='reborn_wh_t1_intents' AND CONSTRAINT_NAME NOT IN('reborn_wh_t1_intents_chk_1','reborn_wh_t1_intents_chk_2','reborn_wh_t1_intents_chk_3','reborn_wh_t1_intents_chk_4','reborn_wh_t1_intents_chk_5','wht2_intent_masks','wht3_intent_masks','wht4_intent_masks','wht5_intent_masks','wht6_intent_masks','wht7_intent_masks'))
 OR (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='reborn_wh_t1_intents' AND COLUMN_NAME IN('old_mask','target_mask') AND DATA_TYPE IN('tinyint','smallint') AND COLUMN_TYPE LIKE '%unsigned%')<>2
 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WHTAL7A: unknown/future schema or unresolved receipt; stop and restore old service to recover';END IF;
 IF EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME='reborn_wh_t1_nodes' AND CONSTRAINT_NAME='reborn_wh_t1_nodes_chk_1')THEN ALTER TABLE reborn_wh_t1_nodes DROP CHECK reborn_wh_t1_nodes_chk_1;END IF;
IF EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME='reborn_wh_t1_nodes' AND CONSTRAINT_NAME='reborn_wh_t1_nodes_chk_2')THEN ALTER TABLE reborn_wh_t1_nodes DROP CHECK reborn_wh_t1_nodes_chk_2;END IF;
IF EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME='reborn_wh_t1_intents' AND CONSTRAINT_NAME='reborn_wh_t1_intents_chk_4')THEN ALTER TABLE reborn_wh_t1_intents DROP CHECK reborn_wh_t1_intents_chk_4;END IF;

 IF EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME='reborn_wh_t1_nodes' AND CONSTRAINT_NAME='wht2_node_ids') THEN ALTER TABLE reborn_wh_t1_nodes DROP CHECK wht2_node_ids;END IF;
 IF EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME='reborn_wh_t1_nodes' AND CONSTRAINT_NAME='wht2_node_ranks') THEN ALTER TABLE reborn_wh_t1_nodes DROP CHECK wht2_node_ranks;END IF;
 IF EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME='reborn_wh_t1_intents' AND CONSTRAINT_NAME='wht2_intent_masks') THEN ALTER TABLE reborn_wh_t1_intents DROP CHECK wht2_intent_masks;END IF;
 IF EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME='reborn_wh_t1_nodes' AND CONSTRAINT_NAME='wht3_node_ids') THEN ALTER TABLE reborn_wh_t1_nodes DROP CHECK wht3_node_ids;END IF;
 IF EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME='reborn_wh_t1_nodes' AND CONSTRAINT_NAME='wht3_node_ranks') THEN ALTER TABLE reborn_wh_t1_nodes DROP CHECK wht3_node_ranks;END IF;
 IF EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME='reborn_wh_t1_intents' AND CONSTRAINT_NAME='wht3_intent_masks') THEN ALTER TABLE reborn_wh_t1_intents DROP CHECK wht3_intent_masks;END IF; IF EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME='reborn_wh_t1_nodes' AND CONSTRAINT_NAME='wht4_node_ids') THEN ALTER TABLE reborn_wh_t1_nodes DROP CHECK wht4_node_ids;END IF;
 IF EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME='reborn_wh_t1_nodes' AND CONSTRAINT_NAME='wht4_node_ranks') THEN ALTER TABLE reborn_wh_t1_nodes DROP CHECK wht4_node_ranks;END IF;
 IF EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME='reborn_wh_t1_intents' AND CONSTRAINT_NAME='wht4_intent_masks') THEN ALTER TABLE reborn_wh_t1_intents DROP CHECK wht4_intent_masks;END IF;

 IF EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME='reborn_wh_t1_nodes' AND CONSTRAINT_NAME='wht5_node_ids') THEN ALTER TABLE reborn_wh_t1_nodes DROP CHECK wht5_node_ids;END IF;
 IF EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME='reborn_wh_t1_nodes' AND CONSTRAINT_NAME='wht5_node_ranks') THEN ALTER TABLE reborn_wh_t1_nodes DROP CHECK wht5_node_ranks;END IF;
 IF EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME='reborn_wh_t1_intents' AND CONSTRAINT_NAME='wht5_intent_masks') THEN ALTER TABLE reborn_wh_t1_intents DROP CHECK wht5_intent_masks;END IF;
 IF EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME='reborn_wh_t1_nodes' AND CONSTRAINT_NAME='wht6_node_ids') THEN ALTER TABLE reborn_wh_t1_nodes DROP CHECK wht6_node_ids;END IF;
 IF EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME='reborn_wh_t1_nodes' AND CONSTRAINT_NAME='wht6_node_ranks') THEN ALTER TABLE reborn_wh_t1_nodes DROP CHECK wht6_node_ranks;END IF;
 IF EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME='reborn_wh_t1_intents' AND CONSTRAINT_NAME='wht6_intent_masks') THEN ALTER TABLE reborn_wh_t1_intents DROP CHECK wht6_intent_masks;END IF;
 IF NOT EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME='reborn_wh_t1_nodes' AND CONSTRAINT_NAME='wht7_node_ids')THEN
 ALTER TABLE reborn_wh_t1_nodes ADD CONSTRAINT wht7_node_ids CHECK(node_id IN(34538,7451,6415,6457,7424,6413,29150,34592));END IF;
 IF NOT EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME='reborn_wh_t1_nodes' AND CONSTRAINT_NAME='wht7_node_ranks')THEN
 ALTER TABLE reborn_wh_t1_nodes ADD CONSTRAINT wht7_node_ranks CHECK((node_id IN(7451,6457,7424,6413,29150,34592) AND `rank`=1) OR (node_id IN(34538,6415) AND `rank` IN(1,2)));END IF;
 IF NOT EXISTS(SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME='reborn_wh_t1_intents' AND CONSTRAINT_NAME='wht7_intent_masks')THEN
 ALTER TABLE reborn_wh_t1_intents ADD CONSTRAINT wht7_intent_masks CHECK(old_mask<=1019 AND target_mask<=1019 AND (!(old_mask&64) OR old_mask&1) AND (!(target_mask&64) OR target_mask&1) AND ((old_mask>>2)&3)<=2 AND ((target_mask>>2)&3)<=2);END IF;
 ALTER TABLE reborn_wh_t1_intents MODIFY old_mask SMALLINT UNSIGNED NOT NULL, MODIFY target_mask SMALLINT UNSIGNED NOT NULL;
 ALTER TABLE reborn_wh_t1_state ALTER COLUMN schema_version SET DEFAULT 7;
 UPDATE reborn_wh_t1_state SET schema_version=7 WHERE schema_version IN(1,2,3,4,5,6);
END$$
CALL reborn_wht7_char_install()$$
DROP PROCEDURE reborn_wht7_char_install$$
DROP PROCEDURE IF EXISTS reborn_wht1_prepare$$
CREATE PROCEDURE reborn_wht1_prepare(IN p_key VARCHAR(64),IN p_guid INT UNSIGNED,IN p_account INT UNSIGNED,
 IN p_revision INT UNSIGNED,IN p_mask INT UNSIGNED,IN p_kind INT UNSIGNED,IN p_level INT UNSIGNED,IN p_money INT UNSIGNED)
BEGIN
 DECLARE v_account INT UNSIGNED DEFAULT 0; DECLARE v_class INT UNSIGNED DEFAULT 0;
 DECLARE v_revision INT UNSIGNED DEFAULT 0; DECLARE v_schema INT UNSIGNED DEFAULT 0;
 DECLARE v_mask INT UNSIGNED DEFAULT 0; DECLARE v_bad INT UNSIGNED DEFAULT 0; DECLARE v_count INT UNSIGNED DEFAULT 0;
 DECLARE v_budget INT UNSIGNED DEFAULT 0; DECLARE v_cost INT UNSIGNED DEFAULT 0;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_account=0;
 DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK;RESIGNAL;END;
 START TRANSACTION;
 SELECT account,class INTO v_account,v_class FROM characters WHERE guid=p_guid FOR UPDATE;
 IF v_account<>p_account OR v_account=0 OR v_class<>15 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WHTAL7A: actor mismatch'; END IF;
 INSERT IGNORE INTO reborn_wh_t1_state(guid,account) VALUES(p_guid,p_account);
 SELECT account,revision,schema_version INTO v_account,v_revision,v_schema FROM reborn_wh_t1_state WHERE guid=p_guid FOR UPDATE;
 IF v_account<>p_account OR v_schema<>7 OR v_revision<>p_revision OR v_revision>=1999999999
 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WHTAL7A: stale/future state'; END IF;
 SELECT COALESCE(SUM(IF(node_id=34538,IF(`rank`=2,65,1),IF(node_id=7451,2,IF(node_id=6415,`rank`*4,IF(node_id=6457,16,IF(node_id=7424,32,IF(node_id=6413,128,IF(node_id=29150,256,IF(node_id=34592,512,0))))))))),0),COUNT(*),COALESCE(SUM(node_id NOT IN(34538,7451,6415,6457,7424,6413,29150,34592) OR (node_id IN(7451,6457,7424,6413,29150,34592) AND `rank`<>1) OR (node_id IN(34538,6415) AND `rank` NOT IN(1,2))),0)
 INTO v_mask,v_count,v_bad FROM reborn_wh_t1_nodes WHERE guid=p_guid;
 IF v_bad OR v_count>8 OR v_mask>1019 OR (v_mask&64 AND !(v_mask&1)) OR (((v_mask>>2)&3)&3)>2 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WHTAL7A: unknown owned node'; END IF;
 SET v_budget=CASE LEAST(p_level,80) WHEN 1 THEN 0 WHEN 2 THEN 0 WHEN 3 THEN 0 WHEN 4 THEN 0 WHEN 5 THEN 0 WHEN 6 THEN 0 WHEN 7 THEN 0 WHEN 8 THEN 0 WHEN 9 THEN 0 WHEN 10 THEN 1 WHEN 11 THEN 1 WHEN 12 THEN 2 WHEN 13 THEN 2 WHEN 14 THEN 3 WHEN 15 THEN 3 WHEN 16 THEN 4 WHEN 17 THEN 4 WHEN 18 THEN 5 WHEN 19 THEN 5 WHEN 20 THEN 6 WHEN 21 THEN 6 WHEN 22 THEN 7 WHEN 23 THEN 7 WHEN 24 THEN 8 WHEN 25 THEN 8 WHEN 26 THEN 9 WHEN 27 THEN 9 WHEN 28 THEN 10 WHEN 29 THEN 10 WHEN 30 THEN 11 WHEN 31 THEN 11 WHEN 32 THEN 12 WHEN 33 THEN 12 WHEN 34 THEN 13 WHEN 35 THEN 13 WHEN 36 THEN 14 WHEN 37 THEN 14 WHEN 38 THEN 15 WHEN 39 THEN 15 WHEN 40 THEN 16 WHEN 41 THEN 16 WHEN 42 THEN 17 WHEN 43 THEN 17 WHEN 44 THEN 18 WHEN 45 THEN 18 WHEN 46 THEN 19 WHEN 47 THEN 19 WHEN 48 THEN 20 WHEN 49 THEN 20 WHEN 50 THEN 21 WHEN 51 THEN 21 WHEN 52 THEN 22 WHEN 53 THEN 22 WHEN 54 THEN 23 WHEN 55 THEN 23 WHEN 56 THEN 24 WHEN 57 THEN 24 WHEN 58 THEN 25 WHEN 59 THEN 25 WHEN 60 THEN 26 WHEN 61 THEN 26 WHEN 62 THEN 27 WHEN 63 THEN 27 WHEN 64 THEN 28 WHEN 65 THEN 28 WHEN 66 THEN 29 WHEN 67 THEN 29 WHEN 68 THEN 30 WHEN 69 THEN 30 WHEN 70 THEN 31 WHEN 71 THEN 31 WHEN 72 THEN 32 WHEN 73 THEN 32 WHEN 74 THEN 33 WHEN 75 THEN 33 WHEN 76 THEN 34 WHEN 77 THEN 34 WHEN 78 THEN 35 WHEN 79 THEN 35 WHEN 80 THEN 36 ELSE 0 END;
 IF p_mask>1019 OR (p_mask&64 AND !(p_mask&1)) OR (((p_mask>>2)&3)&3)>2 OR p_kind>1 OR p_level<1 OR p_level>255 OR p_money>2147483647 OR p_key NOT REGEXP '^[0-9]+-[0-9]+-[0-9]+$'
 OR (p_kind=0 AND (((p_mask & (v_mask&1011))<>(v_mask&1011) OR ((p_mask>>2)&3)<((v_mask>>2)&3)) OR ((p_mask&1)+((p_mask>>1)&1)+((p_mask>>2)&3)+((p_mask>>4)&1)+((p_mask>>5)&1)+((p_mask>>6)&1)+((p_mask>>7)&1)+((p_mask>>8)&1)+((p_mask>>9)&1))>v_budget OR (p_mask<>0 AND p_level<10)))
 OR (p_kind=1 AND (p_mask<>0 OR v_mask=0))
 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WHTAL7A: invalid mask/budget/operation'; END IF;
 SET v_cost=IF(p_kind=1,100000,0);
 IF p_money<v_cost THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WHTAL7A: insufficient gold'; END IF;
 IF EXISTS(SELECT 1 FROM reborn_wh_t1_intents WHERE guid=p_guid AND status<2)
 OR EXISTS(SELECT 1 FROM reborn_wh_t1_intents WHERE op_key=p_key)
 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WHTAL7A: unresolved/replayed operation'; END IF;
 -- Snapshot the owner's current native money value; this is not a fee.
 UPDATE characters SET money=p_money WHERE guid=p_guid;
 INSERT INTO reborn_wh_t1_intents(op_key,guid,account,expected_revision,old_mask,target_mask,kind,level_snapshot,cost,money_before)
 VALUES(p_key,p_guid,p_account,p_revision,v_mask,p_mask,p_kind,p_level,v_cost,p_money);
 COMMIT;
 SELECT 1 AS prepared;
END$$

DROP PROCEDURE IF EXISTS reborn_wht1_apply$$
CREATE PROCEDURE reborn_wht1_apply(IN p_key VARCHAR(64),IN p_guid INT UNSIGNED,IN p_account INT UNSIGNED)
BEGIN
 DECLARE v_account INT UNSIGNED DEFAULT 0; DECLARE v_class INT UNSIGNED DEFAULT 0;
 DECLARE v_revision INT UNSIGNED DEFAULT 0; DECLARE v_expected INT UNSIGNED DEFAULT 0;
 DECLARE v_schema INT UNSIGNED DEFAULT 0; DECLARE v_mask INT UNSIGNED DEFAULT 0; DECLARE v_old INT UNSIGNED DEFAULT 0;
 DECLARE v_state INT UNSIGNED DEFAULT 99; DECLARE v_count INT UNSIGNED DEFAULT 0; DECLARE v_bad INT UNSIGNED DEFAULT 0;
 DECLARE v_current INT UNSIGNED DEFAULT 0;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_account=0;
 -- Joins the native transaction containing SaveGoldToDB. No nested START/COMMIT here.
 SELECT account,class INTO v_account,v_class FROM characters WHERE guid=p_guid FOR UPDATE;
 IF v_account<>p_account OR v_account=0 OR v_class<>15 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WHTAL7A: apply actor'; END IF;
 SELECT account,revision,schema_version INTO v_account,v_revision,v_schema FROM reborn_wh_t1_state WHERE guid=p_guid FOR UPDATE;
 IF v_account<>p_account OR v_schema<>7 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WHTAL7A: apply schema'; END IF;
 SELECT account,expected_revision,target_mask,old_mask,status INTO v_account,v_expected,v_mask,v_old,v_state
 FROM reborn_wh_t1_intents WHERE op_key=p_key AND guid=p_guid FOR UPDATE;
 IF v_account<>p_account OR v_state<>0 OR v_revision<>v_expected OR v_revision>=1999999999
 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WHTAL7A: apply stale/replay'; END IF;
 SELECT COALESCE(SUM(IF(node_id=34538,IF(`rank`=2,65,1),IF(node_id=7451,2,IF(node_id=6415,`rank`*4,IF(node_id=6457,16,IF(node_id=7424,32,IF(node_id=6413,128,IF(node_id=29150,256,IF(node_id=34592,512,0))))))))),0),COUNT(*),COALESCE(SUM(node_id NOT IN(34538,7451,6415,6457,7424,6413,29150,34592) OR (node_id IN(7451,6457,7424,6413,29150,34592) AND `rank`<>1) OR (node_id IN(34538,6415) AND `rank` NOT IN(1,2))),0)
 INTO v_current,v_count,v_bad FROM reborn_wh_t1_nodes WHERE guid=p_guid;
 IF v_current<>v_old OR v_bad OR v_count>8 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WHTAL7A: apply ownership changed'; END IF;
 DELETE FROM reborn_wh_t1_nodes WHERE guid=p_guid AND node_id IN(34538,7451,6415,6457,7424,6413,29150,34592);
 IF v_mask&1 THEN INSERT INTO reborn_wh_t1_nodes VALUES(p_guid,34538,1+((v_mask>>6)&1)); END IF;
 IF v_mask&2 THEN INSERT INTO reborn_wh_t1_nodes VALUES(p_guid,7451,1); END IF;
 IF (v_mask>>2)&3 THEN INSERT INTO reborn_wh_t1_nodes VALUES(p_guid,6415,(v_mask>>2)&3); END IF;
 IF v_mask&16 THEN INSERT INTO reborn_wh_t1_nodes VALUES(p_guid,6457,1); END IF;
 IF v_mask&32 THEN INSERT INTO reborn_wh_t1_nodes VALUES(p_guid,7424,1); END IF;
 IF v_mask&128 THEN INSERT INTO reborn_wh_t1_nodes VALUES(p_guid,6413,1); END IF;
 IF v_mask&256 THEN INSERT INTO reborn_wh_t1_nodes VALUES(p_guid,29150,1); END IF;
 IF v_mask&512 THEN INSERT INTO reborn_wh_t1_nodes VALUES(p_guid,34592,1); END IF;
 UPDATE reborn_wh_t1_state SET revision=revision+1 WHERE guid=p_guid;
 UPDATE reborn_wh_t1_intents SET status=1 WHERE op_key=p_key;
END$$

DROP PROCEDURE IF EXISTS reborn_wht1_recover$$
CREATE PROCEDURE reborn_wht1_recover(IN p_guid INT UNSIGNED,IN p_account INT UNSIGNED,IN p_key VARCHAR(64))
BEGIN
 DECLARE v_account INT UNSIGNED DEFAULT 0; DECLARE v_class INT UNSIGNED DEFAULT 0; DECLARE v_count INT UNSIGNED DEFAULT 0;
 DECLARE v_key VARCHAR(64) DEFAULT ''; DECLARE v_status INT UNSIGNED DEFAULT 0; DECLARE v_outcome INT UNSIGNED DEFAULT 0;
 DECLARE v_before INT UNSIGNED DEFAULT 0; DECLARE v_cost INT UNSIGNED DEFAULT 0; DECLARE v_money INT UNSIGNED DEFAULT 0;
 DECLARE v_repaired INT UNSIGNED DEFAULT 0;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_account=0;
 DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK;RESIGNAL;END;
 START TRANSACTION;
 -- All writer/reconciler paths lock this same pre-existing row first.
 SELECT account,class INTO v_account,v_class FROM characters WHERE guid=p_guid FOR UPDATE;
 IF v_account<>p_account OR v_account=0 OR v_class<>15 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WHTAL7A: recover actor'; END IF;
 IF p_key='' THEN
  SELECT COUNT(*) INTO v_count FROM reborn_wh_t1_intents WHERE guid=p_guid AND status<2;
  IF v_count>1 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WHTAL7A: multiple unresolved receipts'; END IF;
  IF v_count=1 THEN SELECT op_key INTO v_key FROM reborn_wh_t1_intents WHERE guid=p_guid AND status<2 LIMIT 1; END IF;
 ELSE SET v_key=p_key; END IF;
 IF v_key<>'' THEN
  SELECT COUNT(*) INTO v_count FROM reborn_wh_t1_intents WHERE op_key=v_key AND guid=p_guid;
  IF v_count=1 THEN
   SELECT account,status,outcome,money_before,cost INTO v_account,v_status,v_outcome,v_before,v_cost
   FROM reborn_wh_t1_intents WHERE op_key=v_key AND guid=p_guid FOR UPDATE;
   IF v_account<>p_account THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WHTAL7A: recover owner'; END IF;
   IF v_status<2 THEN
    SET v_outcome=IF(v_status=1,1,0); SET v_money=v_before-IF(v_outcome=1,v_cost,0);
    UPDATE characters SET money=v_money WHERE guid=p_guid;
    UPDATE reborn_wh_t1_intents SET status=2,outcome=v_outcome WHERE op_key=v_key;
    SET v_repaired=1;
   ELSE
    -- Already resolved receipts never rewrite later unrelated money changes.
    SET v_repaired=2;
   END IF;
  END IF;
 END IF;
 COMMIT;
 SELECT v_repaired AS repaired,v_outcome AS committed,v_money AS money;
END$$
DELIMITER ;
