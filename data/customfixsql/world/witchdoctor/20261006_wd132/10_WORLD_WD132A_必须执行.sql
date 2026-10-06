-- WORLD only. Private group: last applied ordinary Replenishment wins; no stacking.
DELIMITER $$
DROP PROCEDURE IF EXISTS reborn_wd132_world$$
CREATE PROCEDURE reborn_wd132_world()
BEGIN
 IF EXISTS(SELECT 1 FROM spell_group WHERE id=900132 AND spell_id NOT IN(57669,9003939)) OR EXISTS(SELECT 1 FROM spell_group_stack_rules WHERE group_id=900132 AND (stack_rule<>1 OR description NOT LIKE 'WD132%')) THEN
 SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='WD132 spell group ownership conflict';END IF;
 INSERT IGNORE INTO spell_group(id,spell_id) VALUES(900132,57669),(900132,9003939);
 INSERT INTO spell_group_stack_rules(group_id,stack_rule,description) VALUES(900132,1,'WD132 ordinary Replenishment exclusive') ON DUPLICATE KEY UPDATE description=VALUES(description);
END$$
CALL reborn_wd132_world()$$
DROP PROCEDURE reborn_wd132_world$$
DELIMITER ;
