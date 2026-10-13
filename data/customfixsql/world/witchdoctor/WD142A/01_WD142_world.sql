-- WORLD database: WD142 private scripts and zero automatic coefficients.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd142_world$$
CREATE PROCEDURE reborn_wd142_world()
BEGIN
 IF EXISTS(SELECT 1 FROM spell_bonus_data WHERE entry IN(9003963,9003966) AND (comments IS NULL OR comments NOT LIKE 'WD142%')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD142 coefficient ownership conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003962 AND ScriptName<>'WD142::aura_veil') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD142 script ownership conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003963 AND ScriptName<>'WD142::spell_pulse') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD142 script ownership conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003965 AND ScriptName<>'WD142::aura_devotion') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD142 script ownership conflict';END IF;
 INSERT INTO spell_bonus_data(entry,direct_bonus,dot_bonus,ap_bonus,ap_dot_bonus,comments) VALUES(9003963,0,0,0,0,'WD142 explicit coefficient'),(9003966,0,0,0,0,'WD142 copied damage healing') ON DUPLICATE KEY UPDATE direct_bonus=0,dot_bonus=0,ap_bonus=0,ap_dot_bonus=0;
 INSERT IGNORE INTO spell_script_names(spell_id,ScriptName) VALUES(9003962,'WD142::aura_veil');
 INSERT IGNORE INTO spell_script_names(spell_id,ScriptName) VALUES(9003963,'WD142::spell_pulse');
 INSERT IGNORE INTO spell_script_names(spell_id,ScriptName) VALUES(9003965,'WD142::aura_devotion');
END$$
CALL reborn_wd142_world()$$
DROP PROCEDURE reborn_wd142_world$$
DELIMITER ;
