-- WD144C: display-only target debuffs, no extra combat modifiers.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd144c_world$$
CREATE PROCEDURE reborn_wd144c_world()
BEGIN
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE ABS(spell_id) IN(9003996,9003997) AND ScriptName<>'WD144::marker') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD144C marker ID ownership conflict';END IF;
 INSERT INTO spell_script_names(spell_id,ScriptName)
 SELECT 9003996,'WD144::marker' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003996 AND ScriptName='WD144::marker');
 INSERT INTO spell_script_names(spell_id,ScriptName)
 SELECT 9003997,'WD144::marker' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003997 AND ScriptName='WD144::marker');
END$$
CALL reborn_wd144c_world()$$
DROP PROCEDURE reborn_wd144c_world$$
DELIMITER ;
