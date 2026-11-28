SET NAMES utf8mb4;
START TRANSACTION;
INSERT INTO spelldraft_starting_zone
    (team,slot,route_key,name_en,name_zh,map_id,position_x,position_y,position_z,orientation,image_path,enabled,source_npc)
VALUES
    (0,13,'alliance_exiles_reach','Exile''s Reach','流放者之岛',12261,-1067.39,-1067.02,13.45,0.9,
        'Interface\\Buttons\\Exiles_Reach',1,0),
    (1,13,'horde_exiles_reach','Exile''s Reach','流放者之岛',12369,-1070.0,-1058.0,9.6,1.5,
        'Interface\\Buttons\\Exiles_Reach',1,0);
COMMIT;
SELECT team,slot,route_key,map_id,enabled FROM spelldraft_starting_zone WHERE slot=13 ORDER BY team;
