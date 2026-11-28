SET NAMES utf8mb4;
DROP PROCEDURE IF EXISTS codex_mogu1e_install;
DROP PROCEDURE IF EXISTS codex_mogu1g_install;
DELIMITER $$
CREATE PROCEDURE codex_mogu1g_install()
BEGIN
    DECLARE missing_items TEXT;
    DECLARE error_detail VARCHAR(128);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
    START TRANSACTION;
    IF DATABASE() <> 'acore_world'
       OR (SELECT COUNT(*) FROM playercreateinfo WHERE race=123 AND class IN (1,2,4,5,6,8,9)) <> 7
       OR NOT EXISTS (SELECT 1 FROM playercreateinfo WHERE race=123 AND class=6 AND map=609)
       OR NOT EXISTS (SELECT 1 FROM player_race_stats WHERE Race=123)
       OR EXISTS (SELECT 1 FROM playercreateinfo WHERE race=123 AND class IN (3,7,11))
       OR EXISTS (SELECT 1 FROM playercreateinfo_action WHERE race=123 AND class IN (3,7,11))
       OR EXISTS (SELECT 1 FROM playercreateinfo_item WHERE race=123 AND class IN (3,7,11))
       OR (SELECT COUNT(*) FROM playercreateinfo WHERE (race,class) IN ((3,3),(11,7),(4,11))) <> 3
       OR (SELECT COUNT(DISTINCT class) FROM playercreateinfo_action WHERE (race,class) IN ((3,3),(11,7),(4,11))) <> 3
    THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='MOGU1G: missing Mogu 1A or donor data, or already installed';
    END IF;

    SELECT GROUP_CONCAT(required_items.entry ORDER BY required_items.entry)
      INTO missing_items
      FROM JSON_TABLE('[36, 129, 147, 148, 2102, 2362, 2508, 2516, 3661, 6123, 6124, 6948, 12282, 23344, 23345, 23348]', '$[*]' COLUMNS (entry INT PATH '$')) required_items
      LEFT JOIN item_template item ON item.entry = required_items.entry
      WHERE item.entry IS NULL;
    IF missing_items IS NOT NULL THEN
        SET error_detail = CONCAT('MOGU1G: missing stock item IDs: ', missing_items);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_detail;
    END IF;

    -- Keep the existing Mogu Alliance default starting location.
    INSERT INTO playercreateinfo(race,class,map,zone,position_x,position_y,position_z,orientation)
        SELECT 123, donor.class, home.map, home.zone, home.position_x, home.position_y, home.position_z, home.orientation
        FROM playercreateinfo home CROSS JOIN playercreateinfo donor
        WHERE home.race=123 AND home.class=1 AND (donor.race,donor.class) IN ((3,3),(11,7),(4,11));
    INSERT INTO playercreateinfo_action(race,class,button,action,type)
        SELECT 123,class,button,action,type FROM playercreateinfo_action
        WHERE (race,class) IN ((3,3),(11,7),(4,11)) AND NOT (type=0 AND action IN (20594,2481,58984,59547));
    INSERT INTO playercreateinfo_item(race,class,itemid,amount,Note)
        SELECT 123,class,itemid,amount,Note FROM playercreateinfo_item
        WHERE (race,class) IN ((3,3),(11,7),(4,11));
    COMMIT;
END$$
DELIMITER ;
CALL codex_mogu1g_install();
DROP PROCEDURE codex_mogu1g_install;
SELECT race,class,map,zone FROM playercreateinfo WHERE race=123 ORDER BY class;
