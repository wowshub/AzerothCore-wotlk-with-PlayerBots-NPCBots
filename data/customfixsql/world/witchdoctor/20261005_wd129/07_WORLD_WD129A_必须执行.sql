-- WORLD; WD129A bindings only. Do not rerun old world scripts for this upgrade.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd129_world$$
CREATE PROCEDURE reborn_wd129_world()
BEGIN
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003915 AND ScriptName<>'spell_reborn_wd120_brewing') OR
    EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id IN(9003917,9003918) AND ScriptName<>'aura_reborn_wd129_thistle') THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD129 spell script ownership conflict'; END IF;
 IF EXISTS(SELECT 1 FROM spell_bonus_data WHERE entry=9003919 AND COALESCE(comments,'') NOT LIKE 'WD129%') THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD129 heal coefficient ownership conflict'; END IF;
 DELETE FROM spell_script_names WHERE spell_id IN(9003915,9003917,9003918);
 INSERT INTO spell_script_names VALUES(9003915,'spell_reborn_wd120_brewing'),(9003917,'aura_reborn_wd129_thistle'),(9003918,'aura_reborn_wd129_thistle');
 DELETE FROM spell_bonus_data WHERE entry=9003919;
 INSERT INTO spell_bonus_data(entry,direct_bonus,dot_bonus,ap_bonus,ap_dot_bonus,comments) VALUES(9003919,0,0,0,0,'WD129 Bloodthistle: percent of actual damage, no added coefficients');
END$$
CALL reborn_wd129_world()$$
DROP PROCEDURE reborn_wd129_world$$
DELIMITER ;
