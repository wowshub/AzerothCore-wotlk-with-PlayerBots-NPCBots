-- WD145: exact additive bindings and explicit zero native coefficients.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd145_world$$
CREATE PROCEDURE reborn_wd145_world()
BEGIN
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE ABS(spell_id) BETWEEN 9004000 AND 9004006 AND ScriptName NOT IN('WD145::eclipse_cast','WD145::eclipse_aura')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD145 Eclipse ID ownership conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_bonus_data WHERE entry IN(9004020,9004021) AND (comments IS NULL OR comments<>'WD145 manually calculated Spirit Eclipse')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD145 damage coefficient ownership conflict';END IF;
 INSERT INTO spell_script_names SELECT 9003574,'WD145::spirit_gain' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003574 AND ScriptName='WD145::spirit_gain');
 INSERT INTO spell_script_names SELECT 9004000,'WD145::eclipse_cast' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004000 AND ScriptName='WD145::eclipse_cast');
 INSERT INTO spell_script_names SELECT 9004000,'WD145::eclipse_aura' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004000 AND ScriptName='WD145::eclipse_aura');
 INSERT INTO spell_script_names SELECT 9004001,'WD145::eclipse_cast' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004001 AND ScriptName='WD145::eclipse_cast');
 INSERT INTO spell_script_names SELECT 9004001,'WD145::eclipse_aura' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004001 AND ScriptName='WD145::eclipse_aura');
 INSERT INTO spell_script_names SELECT 9004002,'WD145::eclipse_cast' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004002 AND ScriptName='WD145::eclipse_cast');
 INSERT INTO spell_script_names SELECT 9004002,'WD145::eclipse_aura' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004002 AND ScriptName='WD145::eclipse_aura');
 INSERT INTO spell_script_names SELECT 9004003,'WD145::eclipse_cast' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004003 AND ScriptName='WD145::eclipse_cast');
 INSERT INTO spell_script_names SELECT 9004003,'WD145::eclipse_aura' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004003 AND ScriptName='WD145::eclipse_aura');
 INSERT INTO spell_script_names SELECT 9004004,'WD145::eclipse_cast' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004004 AND ScriptName='WD145::eclipse_cast');
 INSERT INTO spell_script_names SELECT 9004004,'WD145::eclipse_aura' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004004 AND ScriptName='WD145::eclipse_aura');
 INSERT INTO spell_script_names SELECT 9004005,'WD145::eclipse_cast' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004005 AND ScriptName='WD145::eclipse_cast');
 INSERT INTO spell_script_names SELECT 9004005,'WD145::eclipse_aura' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004005 AND ScriptName='WD145::eclipse_aura');
 INSERT INTO spell_script_names SELECT 9004006,'WD145::eclipse_cast' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004006 AND ScriptName='WD145::eclipse_cast');
 INSERT INTO spell_script_names SELECT 9004006,'WD145::eclipse_aura' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004006 AND ScriptName='WD145::eclipse_aura');
 INSERT INTO spell_bonus_data(entry,direct_bonus,dot_bonus,ap_bonus,ap_dot_bonus,comments) VALUES(9004020,0,0,0,0,'WD145 manually calculated Spirit Eclipse'),(9004021,0,0,0,0,'WD145 manually calculated Spirit Eclipse') ON DUPLICATE KEY UPDATE direct_bonus=0,dot_bonus=0,ap_bonus=0,ap_dot_bonus=0;
END$$
CALL reborn_wd145_world()$$
DROP PROCEDURE reborn_wd145_world$$
DELIMITER ;
