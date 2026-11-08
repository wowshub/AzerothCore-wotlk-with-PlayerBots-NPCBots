-- Undo of WMOHIDE1A: show the 8 WMO houses again.
UPDATE `reborn_housing_catalog` SET `enabled` = 1, `category` = 'buildings' WHERE `catalog_id` BETWEEN 10601 AND 10608;
