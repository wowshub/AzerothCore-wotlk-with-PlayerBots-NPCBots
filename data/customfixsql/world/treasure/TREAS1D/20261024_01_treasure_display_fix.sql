-- TREAS1D  库: world  可重复执行
-- 原来的外观编号 201 是篝火, 1581/3248 不是任何现成宝箱模型, 所以宝箱不显示。
-- 改用游戏里最常见的宝箱外观 259 (Battered/Solid/Mithril Bound Chest 都用它), 用 size 区分大小。
UPDATE `gameobject_template` SET `displayId` = 259, `size` = 1.0 WHERE `entry` = 990200;
UPDATE `gameobject_template` SET `displayId` = 259, `size` = 1.3 WHERE `entry` = 990201;
UPDATE `gameobject_template` SET `displayId` = 259, `size` = 1.6 WHERE `entry` = 990202;

-- 鼠标手形: 普通宝箱的 IconName 都是空, 客户端按“宝箱”自动显示拾取手形; 原来填的 'Chest' 客户端不认, 鼠标就没变化。
UPDATE `gameobject_template` SET `IconName` = '' WHERE `entry` IN (990200, 990201, 990202);
