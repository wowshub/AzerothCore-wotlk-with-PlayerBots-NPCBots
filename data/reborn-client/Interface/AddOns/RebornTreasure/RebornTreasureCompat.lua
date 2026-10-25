-- RebornTreasure compat (TREAS2D)
-- This 3.3.5 client has no colour for item quality 7 (heirloom): ITEM_QUALITY_COLORS[7] is nil (checked in game on
-- 2026-10-25: /run for i=0,8 ... gives 0-6 present, 7 and 8 missing). Blizzard's LootFrame.lua line 111 reads
-- ITEM_QUALITY_COLORS[quality].r for every line of a loot window, so one heirloom in a chest gave
-- "attempt to index local 'color' (a nil value)" and that line was not drawn. Define the missing colour
-- (the heirloom gold of later clients) before any loot window is opened.
if ITEM_QUALITY_COLORS and not ITEM_QUALITY_COLORS[7] then
    ITEM_QUALITY_COLORS[7] = { r = 0.9, g = 0.8, b = 0.5, hex = "|cffe6cc80" }
end
