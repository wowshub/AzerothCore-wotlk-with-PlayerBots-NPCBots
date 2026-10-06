-- WORLD database only. WD112 private script ownership, repeatable and conflict guarded.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd112_world$$
CREATE PROCEDURE reborn_wd112_world()
BEGIN
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id IN(9003841,9003843) AND ScriptName<>'spell_reborn_wd112_brew') THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD112 private spell binding conflict; no changes applied'; END IF;
 INSERT INTO spell_script_names(spell_id,ScriptName) SELECT 9003841,'spell_reborn_wd112_brew' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003841 AND ScriptName='spell_reborn_wd112_brew');
 INSERT INTO spell_script_names(spell_id,ScriptName) SELECT 9003843,'spell_reborn_wd112_brew' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003843 AND ScriptName='spell_reborn_wd112_brew');
END$$
CALL reborn_wd112_world()$$
DROP PROCEDURE reborn_wd112_world$$
DELIMITER ;
