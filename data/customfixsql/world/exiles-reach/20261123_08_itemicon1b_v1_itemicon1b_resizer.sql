-- ITEMICON1B V1 (2026-11-23, Claude): Re-Sizer 178051 uses item display 90551 (retail gadget icon). Safe to run twice.
UPDATE `item_template` SET `displayid` = 90551 WHERE `entry` = 178051;
SELECT `entry`, `name`, `displayid` FROM `item_template` WHERE `entry` = 178051;
