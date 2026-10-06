-- WORLD. Conflict checks precede all writes; only WD123 private spell IDs.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd123_world$$
CREATE PROCEDURE reborn_wd123_world()
BEGIN
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id IN(9003890,9003891,9003892,9003893,9003894,9003895,9003896) AND ScriptName<>'spell_reborn_wd120_brewing') OR EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003889) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD123A script ID conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_bonus_data WHERE entry IN(9003890,9003891,9003892,9003893,9003894,9003895,9003896) AND (direct_bonus<>0 OR dot_bonus<>0 OR ap_bonus<>0 OR ap_dot_bonus<>0)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD123A coefficient conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_ranks WHERE (first_spell_id=9003890 OR spell_id BETWEEN 9003890 AND 9003896) AND (first_spell_id<>9003890 OR spell_id NOT BETWEEN 9003890 AND 9003896 OR `rank`<>spell_id-9003889)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD123A rank conflict';END IF;
 INSERT IGNORE INTO spell_script_names(spell_id,ScriptName) VALUES (9003890,'spell_reborn_wd120_brewing'),(9003891,'spell_reborn_wd120_brewing'),(9003892,'spell_reborn_wd120_brewing'),(9003893,'spell_reborn_wd120_brewing'),(9003894,'spell_reborn_wd120_brewing'),(9003895,'spell_reborn_wd120_brewing'),(9003896,'spell_reborn_wd120_brewing');
 INSERT INTO spell_bonus_data(entry,direct_bonus,dot_bonus,ap_bonus,ap_dot_bonus,comments) VALUES (9003890,0,0,0,0,'WD123A manual Splash coefficient'),(9003891,0,0,0,0,'WD123A manual Splash coefficient'),(9003892,0,0,0,0,'WD123A manual Splash coefficient'),(9003893,0,0,0,0,'WD123A manual Splash coefficient'),(9003894,0,0,0,0,'WD123A manual Splash coefficient'),(9003895,0,0,0,0,'WD123A manual Splash coefficient'),(9003896,0,0,0,0,'WD123A manual Splash coefficient') ON DUPLICATE KEY UPDATE comments=VALUES(comments);
 INSERT IGNORE INTO spell_ranks(first_spell_id,spell_id,`rank`) VALUES (9003890,9003890,1),(9003890,9003891,2),(9003890,9003892,3),(9003890,9003893,4),(9003890,9003894,5),(9003890,9003895,6),(9003890,9003896,7);
END$$
CALL reborn_wd123_world()$$
DROP PROCEDURE reborn_wd123_world$$
DELIMITER ;
