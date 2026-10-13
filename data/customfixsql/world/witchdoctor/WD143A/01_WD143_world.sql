-- WD143A WORLD: preflight every owned row before writes; safe to repeat.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd143_world$$
CREATE PROCEDURE reborn_wd143_world()
BEGIN
 IF EXISTS(SELECT 1 FROM spell_bonus_data WHERE entry IN(9003969,9003970,9003971,9003972,9003973,9003974,9003975,9003976,9003977,9003978,9003980,9003981,9003982,9003983,9003984,9003985,9003986,9003987,9003988) AND (comments IS NULL OR comments NOT LIKE 'WD143%')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD143 coefficient ownership conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003970 AND ScriptName<>'WD143::arrow') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD143 script ownership conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003971 AND ScriptName<>'WD143::arrow') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD143 script ownership conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003972 AND ScriptName<>'WD143::arrow') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD143 script ownership conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003973 AND ScriptName<>'WD143::arrow') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD143 script ownership conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003974 AND ScriptName<>'WD143::arrow') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD143 script ownership conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003975 AND ScriptName<>'WD143::arrow') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD143 script ownership conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003976 AND ScriptName<>'WD143::arrow') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD143 script ownership conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003977 AND ScriptName<>'WD143::arrow') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD143 script ownership conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003978 AND ScriptName<>'WD143::arrow') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD143 script ownership conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003980 AND ScriptName<>'WD143::reclamation') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD143 script ownership conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003981 AND ScriptName<>'WD143::reclamation') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD143 script ownership conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003982 AND ScriptName<>'WD143::reclamation') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD143 script ownership conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003983 AND ScriptName<>'WD143::reclamation') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD143 script ownership conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003984 AND ScriptName<>'WD143::reclamation') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD143 script ownership conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003985 AND ScriptName<>'WD143::reclamation') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD143 script ownership conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003986 AND ScriptName<>'WD143::reclamation') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD143 script ownership conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003987 AND ScriptName<>'WD143::reclamation') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD143 script ownership conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003988 AND ScriptName<>'WD143::reclamation') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD143 script ownership conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003989 AND ScriptName<>'WD143::auto_shot') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD143 script ownership conflict';END IF;
 INSERT INTO spell_bonus_data(entry,direct_bonus,dot_bonus,ap_bonus,ap_dot_bonus,comments) VALUES(9003969,0,0,0,0,'WD143 explicit scaling'),(9003970,0,0,0,0,'WD143 explicit scaling'),(9003971,0,0,0,0,'WD143 explicit scaling'),(9003972,0,0,0,0,'WD143 explicit scaling'),(9003973,0,0,0,0,'WD143 explicit scaling'),(9003974,0,0,0,0,'WD143 explicit scaling'),(9003975,0,0,0,0,'WD143 explicit scaling'),(9003976,0,0,0,0,'WD143 explicit scaling'),(9003977,0,0,0,0,'WD143 explicit scaling'),(9003978,0,0,0,0,'WD143 explicit scaling'),(9003980,0,0,0,0,'WD143 explicit scaling'),(9003981,0,0,0,0,'WD143 explicit scaling'),(9003982,0,0,0,0,'WD143 explicit scaling'),(9003983,0,0,0,0,'WD143 explicit scaling'),(9003984,0,0,0,0,'WD143 explicit scaling'),(9003985,0,0,0,0,'WD143 explicit scaling'),(9003986,0,0,0,0,'WD143 explicit scaling'),(9003987,0,0,0,0,'WD143 explicit scaling'),(9003988,0,0,0,0,'WD143 explicit scaling') ON DUPLICATE KEY UPDATE direct_bonus=0,dot_bonus=0,ap_bonus=0,ap_dot_bonus=0;
 INSERT IGNORE INTO spell_script_names(spell_id,ScriptName) VALUES(9003970,'WD143::arrow'),(9003971,'WD143::arrow'),(9003972,'WD143::arrow'),(9003973,'WD143::arrow'),(9003974,'WD143::arrow'),(9003975,'WD143::arrow'),(9003976,'WD143::arrow'),(9003977,'WD143::arrow'),(9003978,'WD143::arrow'),(9003980,'WD143::reclamation'),(9003981,'WD143::reclamation'),(9003982,'WD143::reclamation'),(9003983,'WD143::reclamation'),(9003984,'WD143::reclamation'),(9003985,'WD143::reclamation'),(9003986,'WD143::reclamation'),(9003987,'WD143::reclamation'),(9003988,'WD143::reclamation'),(9003989,'WD143::auto_shot');
END$$
CALL reborn_wd143_world()$$
DROP PROCEDURE reborn_wd143_world$$
DELIMITER ;
