-- HOME5C: 地块形状 0=圆形 1=方形。服务端启动时也会自动补这一列，导入与否都可以。
ALTER TABLE `reborn_housing_plot` ADD COLUMN `shape` TINYINT UNSIGNED NOT NULL DEFAULT 0;
