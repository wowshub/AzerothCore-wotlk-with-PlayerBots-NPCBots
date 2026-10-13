-- WD144: bind native-modifier lifecycle helpers without replacing prior Jinx scripts.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd144_world$$
CREATE PROCEDURE reborn_wd144_world()
BEGIN
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id IN(9003994,9003995) AND ScriptName<>'WD144::talent') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD144 passive script ownership conflict';END IF;
 INSERT IGNORE INTO spell_script_names(spell_id,ScriptName) VALUES(9003150,'WD144::jinx'),(9003994,'WD144::talent'),(9003995,'WD144::talent');
END$$
CALL reborn_wd144_world()$$
DROP PROCEDURE reborn_wd144_world$$
DELIMITER ;
