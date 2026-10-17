-- WD159 native SpellScript hooks: no probabilistic proc table, roll30 once after ordinary cast.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd159_world$$
CREATE PROCEDURE reborn_wd159_world()
BEGIN
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE ABS(spell_id) BETWEEN 9004170 AND 9004176 AND ScriptName NOT IN('WD159::ready','WD159::volley')) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD159 script conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_bonus_data WHERE entry=9004174 AND comments<>'WD159 Volley scripted RAP before native multipliers') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD159 bonus conflict';END IF;
 INSERT INTO spell_script_names SELECT 9004173,'WD159::ready' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004173 AND ScriptName='WD159::ready');
 INSERT INTO spell_script_names SELECT 9004174,'WD159::volley' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004174 AND ScriptName='WD159::volley');
 INSERT INTO spell_script_names SELECT 9003970,'WD159::generator' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003970 AND ScriptName='WD159::generator');
 INSERT INTO spell_script_names SELECT 9003971,'WD159::generator' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003971 AND ScriptName='WD159::generator');
 INSERT INTO spell_script_names SELECT 9003972,'WD159::generator' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003972 AND ScriptName='WD159::generator');
 INSERT INTO spell_script_names SELECT 9003973,'WD159::generator' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003973 AND ScriptName='WD159::generator');
 INSERT INTO spell_script_names SELECT 9003974,'WD159::generator' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003974 AND ScriptName='WD159::generator');
 INSERT INTO spell_script_names SELECT 9003975,'WD159::generator' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003975 AND ScriptName='WD159::generator');
 INSERT INTO spell_script_names SELECT 9003976,'WD159::generator' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003976 AND ScriptName='WD159::generator');
 INSERT INTO spell_script_names SELECT 9003977,'WD159::generator' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003977 AND ScriptName='WD159::generator');
 INSERT INTO spell_script_names SELECT 9003978,'WD159::generator' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003978 AND ScriptName='WD159::generator');
 INSERT INTO spell_script_names SELECT 9003980,'WD159::generator' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003980 AND ScriptName='WD159::generator');
 INSERT INTO spell_script_names SELECT 9003981,'WD159::generator' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003981 AND ScriptName='WD159::generator');
 INSERT INTO spell_script_names SELECT 9003982,'WD159::generator' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003982 AND ScriptName='WD159::generator');
 INSERT INTO spell_script_names SELECT 9003983,'WD159::generator' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003983 AND ScriptName='WD159::generator');
 INSERT INTO spell_script_names SELECT 9003984,'WD159::generator' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003984 AND ScriptName='WD159::generator');
 INSERT INTO spell_script_names SELECT 9003985,'WD159::generator' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003985 AND ScriptName='WD159::generator');
 INSERT INTO spell_script_names SELECT 9003986,'WD159::generator' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003986 AND ScriptName='WD159::generator');
 INSERT INTO spell_script_names SELECT 9003987,'WD159::generator' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003987 AND ScriptName='WD159::generator');
 INSERT INTO spell_script_names SELECT 9003988,'WD159::generator' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003988 AND ScriptName='WD159::generator');
 INSERT INTO spell_script_names SELECT 9004000,'WD159::eclipse' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004000 AND ScriptName='WD159::eclipse');
 INSERT INTO spell_script_names SELECT 9004001,'WD159::eclipse' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004001 AND ScriptName='WD159::eclipse');
 INSERT INTO spell_script_names SELECT 9004002,'WD159::eclipse' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004002 AND ScriptName='WD159::eclipse');
 INSERT INTO spell_script_names SELECT 9004003,'WD159::eclipse' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004003 AND ScriptName='WD159::eclipse');
 INSERT INTO spell_script_names SELECT 9004004,'WD159::eclipse' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004004 AND ScriptName='WD159::eclipse');
 INSERT INTO spell_script_names SELECT 9004005,'WD159::eclipse' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004005 AND ScriptName='WD159::eclipse');
 INSERT INTO spell_script_names SELECT 9004006,'WD159::eclipse' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004006 AND ScriptName='WD159::eclipse');
 INSERT INTO spell_script_names SELECT 9004030,'WD159::glaive' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004030 AND ScriptName='WD159::glaive');
 INSERT INTO spell_script_names SELECT 9004031,'WD159::glaive' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004031 AND ScriptName='WD159::glaive');
 INSERT INTO spell_script_names SELECT 9004032,'WD159::glaive' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004032 AND ScriptName='WD159::glaive');
 INSERT INTO spell_script_names SELECT 9004033,'WD159::glaive' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004033 AND ScriptName='WD159::glaive');
 INSERT INTO spell_script_names SELECT 9004034,'WD159::glaive' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004034 AND ScriptName='WD159::glaive');
 INSERT INTO spell_script_names SELECT 9004035,'WD159::glaive' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004035 AND ScriptName='WD159::glaive');
 INSERT INTO spell_script_names SELECT 9004036,'WD159::glaive' WHERE NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9004036 AND ScriptName='WD159::glaive');
 INSERT INTO spell_bonus_data(entry,direct_bonus,dot_bonus,ap_bonus,ap_dot_bonus,comments)VALUES(9004174,0,0,0,0,'WD159 Volley scripted RAP before native multipliers')ON DUPLICATE KEY UPDATE direct_bonus=0,dot_bonus=0,ap_bonus=0,ap_dot_bonus=0;
END$$
CALL reborn_wd159_world()$$
DROP PROCEDURE reborn_wd159_world$$
DELIMITER ;
