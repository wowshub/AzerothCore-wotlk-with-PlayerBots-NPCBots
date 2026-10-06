-- WORLD only. Exact private spell binding; no production execution by builder.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd131_world$$
CREATE PROCEDURE reborn_wd131_world()
BEGIN
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id IN(9003933,9003934) AND ScriptName<>'spell_reborn_wd131_mojo') THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD131 ownership conflict';END IF;
 DELETE FROM spell_script_names WHERE spell_id IN(9003933,9003934);
 INSERT INTO spell_script_names VALUES (9003933,'spell_reborn_wd131_mojo'),(9003934,'spell_reborn_wd131_mojo');
END$$
CALL reborn_wd131_world()$$
DROP PROCEDURE reborn_wd131_world$$
DELIMITER ;
