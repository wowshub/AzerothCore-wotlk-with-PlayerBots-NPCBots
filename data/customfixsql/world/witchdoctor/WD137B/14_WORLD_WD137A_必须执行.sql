-- WD137A: run manually in WORLD after backing up. No other spell bindings removed.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd137_bind$$
CREATE PROCEDURE reborn_wd137_bind()
BEGIN
 IF EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003957 AND ScriptName<>'aura_reborn_wd137_master') THEN
  SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD137 spell binding conflict';
 END IF;
 IF NOT EXISTS(SELECT 1 FROM spell_script_names WHERE spell_id=9003957 AND ScriptName='aura_reborn_wd137_master') THEN
  INSERT INTO spell_script_names(spell_id,ScriptName) VALUES(9003957,'aura_reborn_wd137_master');
 END IF;
END$$
CALL reborn_wd137_bind()$$
DROP PROCEDURE reborn_wd137_bind$$
DELIMITER ;
