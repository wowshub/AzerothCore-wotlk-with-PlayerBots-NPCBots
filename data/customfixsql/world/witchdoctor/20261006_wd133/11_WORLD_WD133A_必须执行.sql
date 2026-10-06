-- WORLD only; preserve old bindings. No production execution by builder.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd133_world$$
CREATE PROCEDURE reborn_wd133_world()
BEGIN
 IF EXISTS(SELECT 1 FROM spell_bonus_data WHERE entry=9003941 AND (comments IS NULL OR comments NOT LIKE 'WD133%')) THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD133 coefficient ownership conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE
 (spell_id=9003940 AND ScriptName<>'spell_reborn_wd131_mojo') OR
 (spell_id IN(9003942,9003944) AND ScriptName NOT IN('spell_reborn_wd133_base','aura_reborn_wd133_base')) OR
 (spell_id=9003943 AND ScriptName<>'aura_reborn_wd133_beast')) THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD133 script ownership conflict';END IF;
 DELETE FROM spell_script_names WHERE spell_id IN(9003940,9003942,9003943,9003944);
 INSERT INTO spell_script_names(spell_id,ScriptName) VALUES
 (9003940,'spell_reborn_wd131_mojo'),(9003942,'spell_reborn_wd133_base'),(9003942,'aura_reborn_wd133_base'),
 (9003944,'spell_reborn_wd133_base'),(9003944,'aura_reborn_wd133_base'),(9003943,'aura_reborn_wd133_beast');
 INSERT INTO spell_bonus_data(entry,direct_bonus,dot_bonus,ap_bonus,ap_dot_bonus,comments) VALUES(9003941,0,0,0,0,'WD133 Fish Bones percent health; no flat spell power')
 ON DUPLICATE KEY UPDATE direct_bonus=0,dot_bonus=0,ap_bonus=0,ap_dot_bonus=0,comments=VALUES(comments);
END$$
CALL reborn_wd133_world()$$
DROP PROCEDURE reborn_wd133_world$$
DELIMITER ;
