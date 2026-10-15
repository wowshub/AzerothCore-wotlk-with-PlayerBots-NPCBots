-- WD149 append bindings and guard manually scaled child.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd149_world$$
CREATE PROCEDURE reborn_wd149_world()
BEGIN
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE ABS(spell_id) BETWEEN 9004070 AND 9004073 AND ScriptName<>'WD149::explosion') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD149 ID conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_bonus_data WHERE entry=9004071 AND (comments IS NULL OR comments<>'WD149 manual Godslayer')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD149 coefficient conflict';END IF;
 INSERT INTO spell_script_names SELECT 9003574,'WD149::gain' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003574 AND ScriptName='WD149::gain');
 INSERT INTO spell_script_names SELECT 9004071,'WD149::explosion' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004071 AND ScriptName='WD149::explosion');
 INSERT INTO spell_script_names SELECT 9004030,'WD149::ending' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004030 AND ScriptName='WD149::ending');
 INSERT INTO spell_script_names SELECT 9004031,'WD149::ending' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004031 AND ScriptName='WD149::ending');
 INSERT INTO spell_script_names SELECT 9004032,'WD149::ending' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004032 AND ScriptName='WD149::ending');
 INSERT INTO spell_script_names SELECT 9004033,'WD149::ending' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004033 AND ScriptName='WD149::ending');
 INSERT INTO spell_script_names SELECT 9004034,'WD149::ending' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004034 AND ScriptName='WD149::ending');
 INSERT INTO spell_script_names SELECT 9004035,'WD149::ending' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004035 AND ScriptName='WD149::ending');
 INSERT INTO spell_script_names SELECT 9004036,'WD149::ending' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004036 AND ScriptName='WD149::ending');
 INSERT INTO spell_bonus_data(entry,direct_bonus,dot_bonus,ap_bonus,ap_dot_bonus,comments) VALUES(9004071,0,0,0,0,'WD149 manual Godslayer') ON DUPLICATE KEY UPDATE direct_bonus=0,dot_bonus=0,ap_bonus=0,ap_dot_bonus=0;
END$$
CALL reborn_wd149_world()$$
DROP PROCEDURE reborn_wd149_world$$
DELIMITER ;
