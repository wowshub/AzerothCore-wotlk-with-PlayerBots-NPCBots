-- WD157 exact bindings; Arrow retains its existing WD143 binding.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd157_world$$
CREATE PROCEDURE reborn_wd157_world()
BEGIN
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE ABS(spell_id) BETWEEN 9004150 AND 9004157 AND ScriptName NOT IN('WD157::stalker','WD157::stealth','WD157::hunger')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD157 script conflict';END IF;
 INSERT INTO spell_script_names SELECT 9004150,'WD157::stalker' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004150 AND ScriptName='WD157::stalker');
 INSERT INTO spell_script_names SELECT 9004150,'WD157::stealth' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004150 AND ScriptName='WD157::stealth');
 INSERT INTO spell_script_names SELECT 9004151,'WD157::hunger' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004151 AND ScriptName='WD157::hunger');
END$$
CALL reborn_wd157_world()$$
DROP PROCEDURE reborn_wd157_world$$
DELIMITER ;
