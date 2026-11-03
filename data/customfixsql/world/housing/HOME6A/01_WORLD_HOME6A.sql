-- HOME6A: 家具的俯仰(pitch)和侧倾(roll)，单位弧度。服务端启动时也会自动补这两列，导入与否都可以；列已存在时会报 Duplicate column，无害。
ALTER TABLE `reborn_housing_object` ADD COLUMN `pitch` FLOAT NOT NULL DEFAULT 0;
ALTER TABLE `reborn_housing_object` ADD COLUMN `roll` FLOAT NOT NULL DEFAULT 0;
