-- ROLLBACK for DECORBATCH1A. Remove placed pieces first (.home remove <object_id>).
SET NAMES utf8mb4;
DELETE FROM `reborn_housing_recipe` WHERE `catalog_id` BETWEEN 10801 AND 10920;
DELETE FROM `reborn_housing_catalog` WHERE `catalog_id` BETWEEN 10801 AND 10920;
DELETE FROM `gameobject_template` WHERE `entry` BETWEEN 9200801 AND 9200920;
