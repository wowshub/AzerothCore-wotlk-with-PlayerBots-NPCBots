-- ----------------------------------------------------------------------------
-- TUNING CONFIGURATION - CONSUMABLE DROP RATES
-- To adjust the drop chance of the module's custom items, change the 'Chance'
-- values in the INSERT statements at the bottom of this file (Lines 88-144).
--
-- Current Default Drop Rates:
-- 1. Scroll of Reroll (17731 / 4427):
--    - Normal / Elite NPCs: 0.6%  (Line 89)
--    - Boss NPCs:         10.0%  (Line 96)
-- 2. Scroll of Ban (30811 / 1078):
--    - Normal / Elite NPCs: 0.6%  (Line 104)
--    - Boss NPCs:         10.0%  (Line 111)
-- 3. Lost Grimoire (13149):
--    - Normal / Elite NPCs: 0.1%  (Line 119)
--    - Boss NPCs:          5.0%  (Line 126)
-- 4. Tome of Talents (25462):
--    - Normal / Elite NPCs: 1.0%  (Line 134)
--    - Boss NPCs:         15.0%  (Line 141)
-- ----------------------------------------------------------------------------

-- 1. Clean up stale custom entries (99001, 99002, 99003)
DELETE FROM `item_template` WHERE `entry` IN (99001, 99002, 99003);

-- 2. Override existing unused retail templates to match our custom design
UPDATE `item_template` SET
  `class` = 0,
  `subclass` = 4,
  `name` = 'Scroll of Reroll',
  `Quality` = 2,
  `Flags` = 0,
  `BuyPrice` = 1000,
  `SellPrice` = 250,
  `InventoryType` = 0,
  `RequiredLevel` = 1,
  `stackable` = 20,
  `maxcount` = 0,
  `spellid_1` = 24312,
  `spelltrigger_1` = 0,
  `spellcharges_1` = -1,
  `Material` = 4,
  `Description` = 'Consuming this scroll grants you +1 Draft Reroll.'
WHERE `entry` = 17731;

UPDATE `item_template` SET
  `class` = 0,
  `subclass` = 4,
  `name` = 'Scroll of Ban',
  `Quality` = 2,
  `Flags` = 0,
  `BuyPrice` = 1000,
  `SellPrice` = 250,
  `InventoryType` = 0,
  `RequiredLevel` = 1,
  `stackable` = 20,
  `maxcount` = 0,
  `spellid_1` = 24312,
  `spelltrigger_1` = 0,
  `spellcharges_1` = -1,
  `Material` = 4,
  `Description` = 'Consuming this scroll grants you +1 Draft Ban.'
WHERE `entry` = 30811;

UPDATE `item_template` SET
  `class` = 0,
  `subclass` = 0,
  `name` = 'Lost Grimoire',
  `Quality` = 3,
  `Flags` = 0,
  `BuyPrice` = 5000,
  `SellPrice` = 1250,
  `InventoryType` = 0,
  `RequiredLevel` = 1,
  `stackable` = 5,
  `maxcount` = 0,
  `spellid_1` = 24312,
  `spelltrigger_1` = 0,
  `spellcharges_1` = -1,
  `Material` = -1,
  `Description` = 'Consuming this grimoire triggers an immediate bonus spell draft.'
WHERE `entry` = 13149;

UPDATE `item_template` SET
  `class` = 12,
  `subclass` = 0,
  `name` = 'Tome of Talents',
  `Quality` = 3,
  `Flags` = 0,
  `BuyPrice` = 5000,
  `SellPrice` = 1250,
  `InventoryType` = 0,
  `RequiredLevel` = 1,
  `stackable` = 5,
  `maxcount` = 0,
  `spellid_1` = 24312,
  `spelltrigger_1` = 0,
  `spellcharges_1` = -1,
  `Material` = -1,
  `Description` = 'Usable at level 10. Draft one rare special talent from three choices. The tome is not consumed if your level is too low.'
WHERE `entry` = 25462;

-- Chinese client text for the repurposed item.  The English base row above
-- remains the fallback for enUS clients and for any locale without a custom
-- translation.
DELETE FROM `item_template_locale`
WHERE `ID` = 25462 AND `locale` IN ('zhCN', 'zhTW');

INSERT INTO `item_template_locale`
  (`ID`, `locale`, `Name`, `Description`, `VerifiedBuild`)
VALUES
  (25462, 'zhCN', '天赋之书', '10级后可使用。从三项珍贵特殊天赋中选择一项；等级不足时不会消耗天赋之书。', NULL),
  (25462, 'zhTW', '天賦之書', '10級後可使用。從三項珍貴特殊天賦中選擇一項；等級不足時不會消耗天賦之書。', NULL);

-- 3. Clean up reference loot templates and direct loot entries
DELETE FROM `reference_loot_template` WHERE `Entry` = 99000;
DELETE FROM `creature_loot_template` WHERE `Reference` = 99000;
DELETE FROM `creature_loot_template` WHERE `Item` IN (17731, 30811, 13149, 25462);

-- 4. Inject Scroll of Reroll (17731) directly
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `GroupId`, `MinCount`, `MaxCount`)
SELECT cl.Entry, 17731, 0,
       CASE WHEN MAX(ct.`rank`) = 3 THEN 10.0 ELSE 0.6 END,
       0, 1, 1
FROM `creature_loot_template` cl
JOIN `creature_template` ct ON cl.Entry = ct.lootid
GROUP BY cl.Entry;

-- 5. Inject Scroll of Ban (30811) directly
INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `GroupId`, `MinCount`, `MaxCount`)
SELECT cl.Entry, 30811, 0,
       CASE WHEN MAX(ct.`rank`) = 3 THEN 10.0 ELSE 0.6 END,
       0, 1, 1
FROM `creature_loot_template` cl
JOIN `creature_template` ct ON cl.Entry = ct.lootid
GROUP BY cl.Entry;

-- 6. Lost Grimoire (13149) and Tome of Talents (25462) are intentionally
-- not injected into the global creature loot table. Their personal-drop
-- controllers enforce SpellDraft mode isolation and level-difference guards.
