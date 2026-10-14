-- WD146: append exact scripts; preserve all previous Spirit bindings.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd146_world$$
CREATE PROCEDURE reborn_wd146_world()
BEGIN
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE ABS(spell_id) IN(9004030,9004031,9004032,9004033,9004034,9004035,9004036,9004040,9004041) AND ScriptName NOT IN('WD146::glaive','WD146::resistance','WD146::feeder','WD146::blessing')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD146 ID ownership conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_bonus_data WHERE entry BETWEEN 9004030 AND 9004036 AND (comments IS NULL OR comments<>'WD146 manually calculated Spirit Glaive')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD146 coefficient ownership conflict';END IF;
 INSERT INTO spell_script_names SELECT 9003574,'WD146::spirit_sync' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003574 AND ScriptName='WD146::spirit_sync');
 INSERT INTO spell_script_names SELECT 9004040,'WD146::feeder' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004040 AND ScriptName='WD146::feeder');
 INSERT INTO spell_script_names SELECT 9004041,'WD146::blessing' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004041 AND ScriptName='WD146::blessing');
 INSERT INTO spell_script_names SELECT 9004030,'WD146::glaive' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004030 AND ScriptName='WD146::glaive');
 INSERT INTO spell_script_names SELECT 9004030,'WD146::resistance' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004030 AND ScriptName='WD146::resistance');
 INSERT INTO spell_script_names SELECT 9004031,'WD146::glaive' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004031 AND ScriptName='WD146::glaive');
 INSERT INTO spell_script_names SELECT 9004031,'WD146::resistance' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004031 AND ScriptName='WD146::resistance');
 INSERT INTO spell_script_names SELECT 9004032,'WD146::glaive' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004032 AND ScriptName='WD146::glaive');
 INSERT INTO spell_script_names SELECT 9004032,'WD146::resistance' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004032 AND ScriptName='WD146::resistance');
 INSERT INTO spell_script_names SELECT 9004033,'WD146::glaive' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004033 AND ScriptName='WD146::glaive');
 INSERT INTO spell_script_names SELECT 9004033,'WD146::resistance' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004033 AND ScriptName='WD146::resistance');
 INSERT INTO spell_script_names SELECT 9004034,'WD146::glaive' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004034 AND ScriptName='WD146::glaive');
 INSERT INTO spell_script_names SELECT 9004034,'WD146::resistance' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004034 AND ScriptName='WD146::resistance');
 INSERT INTO spell_script_names SELECT 9004035,'WD146::glaive' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004035 AND ScriptName='WD146::glaive');
 INSERT INTO spell_script_names SELECT 9004035,'WD146::resistance' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004035 AND ScriptName='WD146::resistance');
 INSERT INTO spell_script_names SELECT 9004036,'WD146::glaive' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004036 AND ScriptName='WD146::glaive');
 INSERT INTO spell_script_names SELECT 9004036,'WD146::resistance' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004036 AND ScriptName='WD146::resistance');
 INSERT INTO spell_bonus_data(entry,direct_bonus,dot_bonus,ap_bonus,ap_dot_bonus,comments) VALUES (9004030,0,0,0,0,'WD146 manually calculated Spirit Glaive'),(9004031,0,0,0,0,'WD146 manually calculated Spirit Glaive'),(9004032,0,0,0,0,'WD146 manually calculated Spirit Glaive'),(9004033,0,0,0,0,'WD146 manually calculated Spirit Glaive'),(9004034,0,0,0,0,'WD146 manually calculated Spirit Glaive'),(9004035,0,0,0,0,'WD146 manually calculated Spirit Glaive'),(9004036,0,0,0,0,'WD146 manually calculated Spirit Glaive') ON DUPLICATE KEY UPDATE direct_bonus=0,dot_bonus=0,ap_bonus=0,ap_dot_bonus=0;
END$$
CALL reborn_wd146_world()$$
DROP PROCEDURE reborn_wd146_world$$
DELIMITER ;
