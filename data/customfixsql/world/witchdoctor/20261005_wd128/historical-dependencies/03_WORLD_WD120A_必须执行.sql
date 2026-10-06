-- WORLD database. WD120A adds only private IDs; replay-safe, conflicts rejected before writes.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd120_world$$
CREATE PROCEDURE reborn_wd120_world()
BEGIN
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id IN(9003864,9003865,9003866,9003867,9003870,9003871,9003872,9003873,9003874,9003875,9003876) AND ScriptName<>'spell_reborn_wd120_brewing') THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD120A script ID conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_bonus_data WHERE entry IN(9003866,9003870,9003871,9003872,9003873,9003874,9003875,9003876) AND (direct_bonus<>0 OR dot_bonus<>0 OR ap_bonus<>0 OR ap_dot_bonus<>0)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD120A coefficient ID conflict';END IF;
 IF EXISTS(SELECT 1 FROM spell_ranks WHERE (first_spell_id=9003870 OR spell_id BETWEEN 9003870 AND 9003876) AND (first_spell_id<>9003870 OR spell_id NOT BETWEEN 9003870 AND 9003876 OR `rank`<>spell_id-9003869)) THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD120A rank ID conflict';END IF;
 INSERT IGNORE INTO spell_script_names(spell_id,ScriptName) VALUES (9003865,'spell_reborn_wd120_brewing'),(9003866,'spell_reborn_wd120_brewing'),(9003870,'spell_reborn_wd120_brewing'),(9003871,'spell_reborn_wd120_brewing'),(9003872,'spell_reborn_wd120_brewing'),(9003873,'spell_reborn_wd120_brewing'),(9003874,'spell_reborn_wd120_brewing'),(9003875,'spell_reborn_wd120_brewing'),(9003876,'spell_reborn_wd120_brewing');
 INSERT INTO spell_bonus_data(entry,direct_bonus,dot_bonus,ap_bonus,ap_dot_bonus,comments) VALUES (9003866,0,0,0,0,'WD120A manual CoA coefficient before native done/taken'),(9003870,0,0,0,0,'WD120A manual CoA coefficient before native done/taken'),(9003871,0,0,0,0,'WD120A manual CoA coefficient before native done/taken'),(9003872,0,0,0,0,'WD120A manual CoA coefficient before native done/taken'),(9003873,0,0,0,0,'WD120A manual CoA coefficient before native done/taken'),(9003874,0,0,0,0,'WD120A manual CoA coefficient before native done/taken'),(9003875,0,0,0,0,'WD120A manual CoA coefficient before native done/taken'),(9003876,0,0,0,0,'WD120A manual CoA coefficient before native done/taken') ON DUPLICATE KEY UPDATE comments=VALUES(comments);
 INSERT IGNORE INTO spell_ranks(first_spell_id,spell_id,`rank`) VALUES (9003870,9003870,1),(9003870,9003871,2),(9003870,9003872,3),(9003870,9003873,4),(9003870,9003874,5),(9003870,9003875,6),(9003870,9003876,7);
END$$
CALL reborn_wd120_world()$$
DROP PROCEDURE reborn_wd120_world$$
DELIMITER ;
