-- TREAS2B: 在 world 库执行。TREAS2A 的 SQL 写入宝箱图标时反斜杠被转义吃掉了（InterfaceIconsINV_Box_01），这里补回
-- 面板也会自动补，这条只是让库里的数据干净；可重复执行
UPDATE reborn_treasure_types
SET icon = CONCAT('Interface\\Icons\\', SUBSTRING(icon, 15))
WHERE icon LIKE 'InterfaceIcons%';

SELECT entry, name, icon FROM reborn_treasure_types ORDER BY entry;
