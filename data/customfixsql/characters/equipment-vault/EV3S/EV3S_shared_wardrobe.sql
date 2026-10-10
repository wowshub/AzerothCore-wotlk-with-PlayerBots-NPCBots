-- EV3S Characters database ONLY. Stop worldserver; back up the Characters DB first.
-- DDL is not transactional. Run this complete file, not selected fragments.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_ev3s_install$$
CREATE PROCEDURE reborn_ev3s_install()
main: BEGIN
 DECLARE n INT DEFAULT 0;
 DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
 SELECT COUNT(*) INTO n FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='reborn_ev_shared_meta';
 IF n>0 THEN
  SELECT COUNT(*) INTO n FROM reborn_ev_shared_meta WHERE id=1 AND version=1;
  IF n=1 THEN
   -- Recover a disconnect between migration COMMIT and legacy-table quarantine.
   SELECT COUNT(*) INTO n FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='reborn_ev_slot';
   IF n=1 THEN RENAME TABLE reborn_ev_slot TO reborn_ev_slot_ev2r_backup, reborn_ev_home TO reborn_ev_home_ev2r_backup; END IF;
   SELECT 'EV3S already migrated; references were not overwritten' AS result; LEAVE main;
  END IF;
 END IF;
 SELECT COUNT(*) INTO n FROM information_schema.tables WHERE table_schema=DATABASE() AND engine='InnoDB' AND table_name IN ('reborn_ev_slot','reborn_ev_home','reborn_ev_head','reborn_ev_op','reborn_ev_unlock','characters','character_inventory','item_instance','character_gifts');
 IF n<>9 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='EV3S requires the existing EV2R Characters schema'; END IF;
 SELECT COUNT(*) INTO n FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name IN ('reborn_ev_slot_ev2r_backup','reborn_ev_home_ev2r_backup');
 IF n<>0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Unexpected legacy backup tables; inspect before migration'; END IF;
 SELECT COUNT(*) INTO n FROM reborn_ev_slot v LEFT JOIN item_instance i ON i.guid=v.item AND i.owner_guid=v.guid LEFT JOIN character_inventory c ON c.item=v.item LEFT JOIN reborn_ev_home h ON h.guid=v.guid AND h.wardrobe=v.wardrobe AND h.slot=v.slot AND h.item=v.item WHERE i.guid IS NULL OR c.item IS NOT NULL OR h.item IS NULL;
 IF n<>0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Stored original is missing, carried, or has mismatched membership'; END IF;
 SELECT COUNT(*) INTO n FROM reborn_ev_home h LEFT JOIN reborn_ev_unlock u ON u.guid=h.guid AND u.wardrobe=h.wardrobe WHERE u.guid IS NULL OR h.slot NOT BETWEEN 1 AND 19;
 IF n<>0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Invalid wardrobe reference; inspect before migration'; END IF;
 SELECT COUNT(*) INTO n FROM (SELECT guid FROM reborn_ev_unlock GROUP BY guid HAVING MAX(wardrobe)>1000 UNION SELECT guid FROM reborn_ev_slot GROUP BY guid HAVING COUNT(*)>2000) limits_check;
 IF n<>0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Existing wardrobe exceeds EV3S snapshot limits; keep EV2R and request paged migration'; END IF;
 CREATE TABLE IF NOT EXISTS reborn_ev_pool (guid INT UNSIGNED NOT NULL,item INT UNSIGNED NOT NULL,PRIMARY KEY(item),KEY owner(guid)) ENGINE=InnoDB;
 CREATE TABLE IF NOT EXISTS reborn_ev_outfit (guid INT UNSIGNED NOT NULL,wardrobe INT UNSIGNED NOT NULL,slot TINYINT UNSIGNED NOT NULL,item INT UNSIGNED NOT NULL,PRIMARY KEY(guid,wardrobe,slot),UNIQUE KEY same_outfit(guid,wardrobe,item),KEY original(item)) ENGINE=InnoDB;
 CREATE TABLE IF NOT EXISTS reborn_ev_shared_meta (id TINYINT UNSIGNED NOT NULL,version INT UNSIGNED NOT NULL,PRIMARY KEY(id)) ENGINE=InnoDB;
 SELECT (SELECT COUNT(*) FROM reborn_ev_pool)+(SELECT COUNT(*) FROM reborn_ev_outfit) INTO n;
 IF n<>0 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='Unmarked shared tables are nonempty; do not overwrite'; END IF;
 START TRANSACTION;
 INSERT INTO reborn_ev_pool (guid,item) SELECT guid,item FROM reborn_ev_slot;
 INSERT INTO reborn_ev_outfit (guid,wardrobe,slot,item) SELECT guid,wardrobe,slot,item FROM reborn_ev_home;
 INSERT INTO reborn_ev_shared_meta(id,version) VALUES(1,1);
 COMMIT;
 -- Old binaries fail their schema check instead of operating on stale storage.
 RENAME TABLE reborn_ev_slot TO reborn_ev_slot_ev2r_backup, reborn_ev_home TO reborn_ev_home_ev2r_backup;
 SELECT 'EV3S migrated; original item_instance and inventory rows untouched' AS result;
END$$
CALL reborn_ev3s_install()$$
DROP PROCEDURE reborn_ev3s_install$$
DELIMITER ;
