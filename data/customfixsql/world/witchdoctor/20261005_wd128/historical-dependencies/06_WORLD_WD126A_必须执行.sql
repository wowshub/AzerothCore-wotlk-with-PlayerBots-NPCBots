-- WORLD database; keep prior WD125 SQL in order.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd126_world$$
CREATE PROCEDURE reborn_wd126_world()
BEGIN
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003910 AND ScriptName<>'spell_reborn_wd126_shrink_ally') THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD126A private spell script ID conflict'; END IF;
 INSERT IGNORE INTO spell_script_names(spell_id,ScriptName) VALUES(9003910,'spell_reborn_wd126_shrink_ally');
END$$
CALL reborn_wd126_world()$$
DROP PROCEDURE reborn_wd126_world$$
DELIMITER ;
