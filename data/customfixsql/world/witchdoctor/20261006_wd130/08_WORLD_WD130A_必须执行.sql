-- WORLD only; WD130 script ownership guarded before mutation.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd130_world$$
CREATE PROCEDURE reborn_wd130_world()
BEGIN
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id BETWEEN 9003922 AND 9003928 AND ScriptName NOT IN ('spell_reborn_wd130_beam','aura_reborn_wd130_beam')) OR
 EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003932 AND ScriptName<>'spell_reborn_wd130_heal') OR
 EXISTS(SELECT 1 FROM spell_bonus_data WHERE entry=9003932 AND COALESCE(comments,'') NOT LIKE 'WD130%') THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD130 ownership conflict'; END IF;
 DELETE FROM spell_script_names WHERE spell_id BETWEEN 9003922 AND 9003928 OR spell_id=9003932;
 INSERT INTO spell_script_names VALUES
(9003922,'spell_reborn_wd130_beam'),
(9003922,'aura_reborn_wd130_beam'),
(9003923,'spell_reborn_wd130_beam'),
(9003923,'aura_reborn_wd130_beam'),
(9003924,'spell_reborn_wd130_beam'),
(9003924,'aura_reborn_wd130_beam'),
(9003925,'spell_reborn_wd130_beam'),
(9003925,'aura_reborn_wd130_beam'),
(9003926,'spell_reborn_wd130_beam'),
(9003926,'aura_reborn_wd130_beam'),
(9003927,'spell_reborn_wd130_beam'),
(9003927,'aura_reborn_wd130_beam'),
(9003928,'spell_reborn_wd130_beam'),
(9003928,'aura_reborn_wd130_beam'),
(9003932,'spell_reborn_wd130_heal');
 DELETE FROM spell_bonus_data WHERE entry=9003932;
 INSERT INTO spell_bonus_data(entry,direct_bonus,dot_bonus,ap_bonus,ap_dot_bonus,comments) VALUES(9003932,0,0,0,0,'WD130 Beam manual 0.1073 coefficient, native done/taken once');
END$$
CALL reborn_wd130_world()$$
DROP PROCEDURE reborn_wd130_world$$
DELIMITER ;
