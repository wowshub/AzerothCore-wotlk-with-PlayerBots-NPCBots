-- ITEMICON1A V2 (2026-11-23, Claude): first aid kits 168410 / 170549 -> item display 90549; also restores the plain name
-- (the test name "... V90549" is removed). Safe to run twice.
UPDATE `item_template` SET `displayid` = 90549, `name` = 'First Aid Kit 急救包' WHERE `entry` IN (168410, 170549);
SELECT `entry`, `name`, `displayid` FROM `item_template` WHERE `entry` IN (168410, 170549);
