-- WD150 manual child coefficients; append bindings.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd150_world$$
CREATE PROCEDURE reborn_wd150_world()
BEGIN
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE ABS(spell_id) BETWEEN 9004080 AND 9004084 AND ScriptName NOT IN('WD150::call','WD150::fire')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD150 ownership conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_bonus_data WHERE entry=9004083 AND (comments IS NULL OR comments<>'WD150 manual VoodooFire')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD150 coefficient conflict';END IF;
 INSERT INTO spell_script_names SELECT 9004080,'WD150::call' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004080 AND ScriptName='WD150::call');
 INSERT INTO spell_script_names SELECT 9004083,'WD150::fire' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004083 AND ScriptName='WD150::fire');
 INSERT INTO spell_bonus_data(entry,direct_bonus,dot_bonus,ap_bonus,ap_dot_bonus,comments)VALUES(9004083,0,0,0,0,'WD150 manual VoodooFire') ON DUPLICATE KEY UPDATE direct_bonus=0,dot_bonus=0,ap_bonus=0,ap_dot_bonus=0;
END$$
CALL reborn_wd150_world()$$
DROP PROCEDURE reborn_wd150_world$$
DELIMITER ;
