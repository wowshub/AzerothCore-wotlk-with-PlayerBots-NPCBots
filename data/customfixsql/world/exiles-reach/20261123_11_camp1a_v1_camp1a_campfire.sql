-- CAMP1A V1 (2026-11-24, Claude): campfire 9174074 (quest 59932 Cooking Meat) gets a quest sparkle, a "grab" cursor and a clearer name. Safe to run twice.
-- Data1 = quest id: while the player has 59932 (incomplete) the core sends the "activatable + sparkle" flags for this object (GameObject::ActivateToQuest).
-- IconName = cursor shown over the object ('LootAll' = grabbing hand, used by stock goober "Captured Jormungar Spawn"). Other stock choices: 'Interact', 'Point', 'Inspect'.
UPDATE `gameobject_template` SET
  `name` = 'Campfire 篝火 (click to cook 点击烹饪)',
  `IconName` = 'LootAll',
  `castBarCaption` = 'Cook 烹饪',
  `Data1` = 59932
WHERE `entry` = 9174074;
SELECT `entry`, `type`, `name`, `IconName`, `castBarCaption`, `Data1` FROM `gameobject_template` WHERE `entry` = 9174074;
