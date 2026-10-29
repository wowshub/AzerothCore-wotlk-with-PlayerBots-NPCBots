-- CHARACTERS only. Same MySQL instance as audited sahtout_site.user_currencies.
-- VP=points; DP=tokens. Never creates or seeds a wallet.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_bt1_install$$
CREATE PROCEDURE reborn_bt1_install()
BEGIN
 IF NOT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema=DATABASE() AND table_name='characters' AND engine='InnoDB') THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='MBTG1A: select CHARACTERS database';
 END IF;
 IF NOT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema='sahtout_site' AND table_name='user_currencies' AND engine='InnoDB') OR
 (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='sahtout_site' AND table_name='user_currencies' AND column_name IN('account_id','points','tokens') AND data_type IN('int','bigint','mediumint'))<>3 OR
 NOT EXISTS(SELECT 1 FROM information_schema.statistics WHERE table_schema='sahtout_site' AND table_name='user_currencies' AND index_name='PRIMARY' AND column_name='account_id') OR
 (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema='sahtout_site' AND table_name='user_currencies' AND index_name='PRIMARY')<>1 THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='MBTG1A: audited InnoDB account wallet unavailable';
 END IF;
 CREATE TABLE IF NOT EXISTS reborn_bt1_receipt(
 guid INT UNSIGNED NOT NULL,account_id INT UNSIGNED NOT NULL,class_id TINYINT UNSIGNED NOT NULL,
 slot TINYINT UNSIGNED NOT NULL,currency TINYINT UNSIGNED NOT NULL,amount INT UNSIGNED NOT NULL,
 purchased_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,PRIMARY KEY(guid,slot)
 )ENGINE=InnoDB;
 IF (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE()AND table_name='reborn_bt1_receipt'AND column_name IN('guid','account_id','class_id','slot','currency','amount')AND data_type IN('int','tinyint'))<>6 OR
 (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema=DATABASE()AND table_name='reborn_bt1_receipt'AND index_name='PRIMARY'AND column_name IN('guid','slot'))<>2 THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='MBTG1A: receipt schema mismatch; existing data preserved';
 END IF;
END$$
CALL reborn_bt1_install()$$
DROP PROCEDURE reborn_bt1_install$$
DROP PROCEDURE IF EXISTS reborn_bt1_buy$$
CREATE PROCEDURE reborn_bt1_buy(IN g INT UNSIGNED,IN a INT UNSIGNED,IN c INT UNSIGNED,IN s INT UNSIGNED,IN cur INT UNSIGNED,IN price INT UNSIGNED)
proc:BEGIN
 DECLARE acct,cls,seen,stored_account,stored_class,native_specs INT UNSIGNED DEFAULT 0;
 DECLARE balance BIGINT DEFAULT -1;
 DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK;SELECT 0 AS result;END;
 IF a=0 OR g=0 OR price=0 OR price>2000000000 OR cur NOT IN(1,2) OR (c<>13 AND c NOT IN(1,2,3,4,5,6,7,8,9,11)) OR s<1 OR s>2 OR(c<>13 AND s<>1)THEN SELECT 0 AS result;LEAVE proc;END IF;
 START TRANSACTION;
 SELECT account,class,specCount INTO acct,cls,native_specs FROM characters WHERE guid=g FOR UPDATE;
 IF acct<>a OR cls<>c THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 SELECT COUNT(*),COALESCE(MAX(account_id),0),COALESCE(MAX(class_id),0) INTO seen,stored_account,stored_class FROM reborn_bt1_receipt WHERE guid=g AND slot=s;
 IF seen>0 THEN
  IF stored_account<>a OR stored_class<>c THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
  COMMIT;SELECT 2 AS result;LEAVE proc;
 END IF;
 IF c<>13 AND native_specs>1 THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 IF c=13 AND EXISTS(SELECT 1 FROM reborn_wd13_slots WHERE guid=g AND slot=s)THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 IF cur=1 THEN SELECT tokens INTO balance FROM sahtout_site.user_currencies WHERE account_id=a FOR UPDATE;
 ELSE SELECT points INTO balance FROM sahtout_site.user_currencies WHERE account_id=a FOR UPDATE;END IF;
 IF balance<price THEN ROLLBACK;SELECT 3 AS result;LEAVE proc;END IF;
 IF cur=1 THEN UPDATE sahtout_site.user_currencies SET tokens=tokens-price WHERE account_id=a AND tokens>=price;
 ELSE UPDATE sahtout_site.user_currencies SET points=points-price WHERE account_id=a AND points>=price;END IF;
 IF ROW_COUNT()<>1 THEN ROLLBACK;SELECT 3 AS result;LEAVE proc;END IF;
 INSERT INTO reborn_bt1_receipt(guid,account_id,class_id,slot,currency,amount)VALUES(g,a,c,s,cur,price);
 IF c=13 THEN INSERT INTO reborn_wd13_slots(guid,slot,paid_copper)VALUES(g,s,0);END IF;
 COMMIT;SELECT 1 AS result;
END$$
DELIMITER ;
