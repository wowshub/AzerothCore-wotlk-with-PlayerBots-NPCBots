-- WD138B manual WORLD migration. Abort on unrelated bindings; idempotent insert.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd138_bind$$
CREATE PROCEDURE reborn_wd138_bind()
BEGIN
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id IN (9003959,9003961) AND ScriptName NOT IN ('spell_reborn_wd138_tiki','aura_reborn_wd138_amount')) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD138 binding conflict';
 END IF;
 IF EXISTS(SELECT 1 FROM spell_bonus_data WHERE entry IN (9003959,9003961) AND (comments IS NULL OR comments NOT LIKE 'WD138 %')) THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD138 coefficient owner conflict';
 END IF;
 INSERT IGNORE INTO spell_script_names(spell_id,ScriptName) VALUES
 (9003959,'spell_reborn_wd138_tiki'),(9003959,'aura_reborn_wd138_amount'),(9003961,'aura_reborn_wd138_amount');
 DELETE FROM spell_bonus_data WHERE entry IN (9003959,9003961);
 INSERT INTO spell_bonus_data(entry,direct_bonus,dot_bonus,ap_bonus,ap_dot_bonus,comments) VALUES
 (9003959,0,0,0,0,'WD138 Tiki coefficient applied once in AuraScript'),
 (9003961,0,0,0,0,'WD138 Tiki shield coefficient applied once in AuraScript');
END$$
CALL reborn_wd138_bind()$$
DROP PROCEDURE reborn_wd138_bind$$
DELIMITER ;
