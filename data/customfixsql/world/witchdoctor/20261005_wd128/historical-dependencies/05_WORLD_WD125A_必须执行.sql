-- WORLD database. Guard private spell IDs and preserve WD120/WD123 bindings.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd125_world$$
CREATE PROCEDURE reborn_wd125_world()
BEGIN
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id IN(9003901,9003905) AND ScriptName<>'spell_reborn_wd120_brewing') THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD125A spell script ID conflict'; END IF;
 INSERT IGNORE INTO spell_script_names(spell_id,ScriptName) VALUES
 (9003901,'spell_reborn_wd120_brewing'),(9003905,'spell_reborn_wd120_brewing');
END$$
CALL reborn_wd125_world()$$
DROP PROCEDURE reborn_wd125_world$$
DELIMITER ;
