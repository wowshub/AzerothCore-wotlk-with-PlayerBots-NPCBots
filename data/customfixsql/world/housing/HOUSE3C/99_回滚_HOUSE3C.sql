-- ROLLBACK for HOUSE3C. Remove placed pieces first (.home remove <object_id>).
SET NAMES utf8mb4;
DELETE FROM `reborn_housing_recipe` WHERE `catalog_id` BETWEEN 10701 AND 10716;
DELETE FROM `reborn_housing_catalog` WHERE `catalog_id` BETWEEN 10701 AND 10716;
DELETE FROM `gameobject_template` WHERE `entry` BETWEEN 9200701 AND 9200716;
