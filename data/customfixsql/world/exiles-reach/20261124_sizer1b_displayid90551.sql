-- SIZER1B V1 (2026-11-24, Claude): the custom Re-Sizer 9178051 uses the normal icon (display 90551, same as the retail-style icon of ITEMICON1B).
UPDATE `item_template` SET `displayid` = 90551 WHERE `entry` = 9178051;
SELECT `entry`, `name`, `displayid`, `spellid_1` FROM `item_template` WHERE `entry` = 9178051;
