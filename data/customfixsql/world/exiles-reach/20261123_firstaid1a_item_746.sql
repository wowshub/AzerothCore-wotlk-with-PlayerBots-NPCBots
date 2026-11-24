-- FIRSTAID1A V1 (2026-11-23, Claude): quest item 168410 "First Aid Kit" now casts spell 746 (Linen Bandage visual, friendly target) when used,
-- so the client shows the targeting cursor. Beach1A.lua (V4) reacts to the cast. Safe to run twice.
UPDATE `item_template` SET
  `spellid_1` = 746, `spelltrigger_1` = 0, `spellcharges_1` = -1, `spellcooldown_1` = -1, `spellcategory_1` = 0, `spellcategorycooldown_1` = -1
WHERE `entry` = 168410;
SELECT `entry`, `name`, `spellid_1`, `spelltrigger_1`, `spellcharges_1` FROM `item_template` WHERE `entry` = 168410;
