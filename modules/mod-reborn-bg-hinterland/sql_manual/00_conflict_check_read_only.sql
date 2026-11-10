-- HLBG1A: read-only conflict check. Run it on the world database BEFORE importing 01..04. Every query must return 0 rows
-- (or only rows you know are yours). Nothing here changes data.
SELECT 'battleground_template 20' AS what, ID FROM battleground_template WHERE ID = 20;
SELECT 'game_graveyard 1721/1722' AS what, ID, Map FROM game_graveyard WHERE ID IN (1721, 1722);
SELECT 'battlemaster_entry 900001' AS what, entry FROM battlemaster_entry WHERE entry = 900001;
SELECT 'creature_template' AS what, entry, name FROM creature_template
 WHERE entry = 900001 OR entry BETWEEN 600004 AND 600011 OR entry BETWEEN 810000 AND 810023;
SELECT 'creature guids' AS what, COUNT(*) FROM creature WHERE guid BETWEEN 16000000 AND 16000155;
SELECT 'gameobject guids' AS what, COUNT(*) FROM gameobject WHERE guid BETWEEN 16200000 AND 16200421;
SELECT 'waypoint_data ids' AS what, COUNT(*) FROM waypoint_data WHERE id BETWEEN 895000000 AND 895000009;
SELECT 'rows already on map 20411' AS what, (SELECT COUNT(*) FROM creature WHERE map = 20411) AS creatures,
       (SELECT COUNT(*) FROM gameobject WHERE map = 20411) AS gameobjects;
SELECT 'smart_scripts for the npc entries' AS what, COUNT(*) FROM smart_scripts WHERE entryorguid BETWEEN 810000 AND 810023 AND source_type = 0;
