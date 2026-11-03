-- WORLD DATABASE (选中服务端实际连接的 world 库后执行). 只加一个字段,不用 PREPARE.
-- 提示 Duplicate column name 'scale' 表示已经有了,忽略即可。
ALTER TABLE `reborn_housing_object` ADD COLUMN `scale` FLOAT NOT NULL DEFAULT 1;
-- 检查: SHOW COLUMNS FROM `reborn_housing_object` LIKE 'scale';
-- 回滚: ALTER TABLE `reborn_housing_object` DROP COLUMN `scale`;
