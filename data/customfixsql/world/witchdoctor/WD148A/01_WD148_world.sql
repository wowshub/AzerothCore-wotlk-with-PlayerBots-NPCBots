-- WD148: preserve existing Avatar bindings, bind the native expiration lifecycle.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd148_world$$
CREATE PROCEDURE reborn_wd148_world()
BEGIN
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE ABS(spell_id) IN(9004060,9004061) AND ScriptName NOT IN('WD148::lesser')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD148 ID ownership conflict';END IF;
 INSERT INTO spell_script_names SELECT 9003270,'WD148::avatar_end' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003270 AND ScriptName='WD148::avatar_end');
 INSERT INTO spell_script_names SELECT 9004061,'WD148::lesser' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004061 AND ScriptName='WD148::lesser');
END$$
CALL reborn_wd148_world()$$
DROP PROCEDURE reborn_wd148_world$$
DELIMITER ;
