-- SIZER1A V4 (2026-11-24, Claude): the Re-Sizer becomes a custom item 9178051 (retail id 178051 never showed the use-spell in the client).
-- Built as a copy of the working First Aid Kit row (168410) with the Re-Sizer's own name/description; quest 59941 now starts/gives 9178051.
-- Icon: displayid 16536 for now (the client Item.dbc has no row for 9178051, so a placeholder icon is possible; fix after the test works).
DELETE FROM `item_template` WHERE `entry` = 9178051;
CREATE TEMPORARY TABLE `tmp_resizer` AS SELECT * FROM `item_template` WHERE `entry` = 168410;
UPDATE `tmp_resizer` SET `entry` = 9178051, `name` = 'Re-Sizer 缩放器', `displayid` = 16536,
  `description` = 'Goblin-made gadget. Use it on a Wandering Boar. / 地精做的小玩意。对游荡野猪使用。',
  `spellid_1` = 746, `spelltrigger_1` = 0, `spellcharges_1` = 0, `stackable` = 1, `maxcount` = 1;
INSERT INTO `item_template` SELECT * FROM `tmp_resizer`;
DROP TEMPORARY TABLE `tmp_resizer`;
UPDATE `quest_template` SET `StartItem` = 9178051, `ItemDrop1` = 9178051 WHERE `ID` = 59941;
SELECT `entry`, `name`, `displayid`, `class`, `spellid_1`, `spelltrigger_1`, `spellcharges_1` FROM `item_template` WHERE `entry` IN (168410, 9178051);
SELECT `ID`, `StartItem`, `ItemDrop1` FROM `quest_template` WHERE `ID` = 59941;
