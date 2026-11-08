-- WMOHIDE1A: take the 8 HOUSE3B WMO houses (catalog 10601-10608) off the catalog. They show as blue/white cubes on the server.
-- Nothing is deleted: enabled = 0 hides them, category = 'wmo_houses' parks them in their own category for later.
-- Remove placed ones first: .home remove <object_id>  (or from the plot list). Placed pieces stay in the world until removed.
UPDATE `reborn_housing_catalog` SET `enabled` = 0, `category` = 'wmo_houses' WHERE `catalog_id` BETWEEN 10601 AND 10608;
SELECT catalog_id, name_zh, category, enabled FROM `reborn_housing_catalog` WHERE `catalog_id` BETWEEN 10601 AND 10608;
