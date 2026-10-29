-- LAB0 掉落工坊: 改动日志 + 官方原始爆率还原点 (world 库). 可重复执行.
CREATE TABLE IF NOT EXISTS `reborn_lootlab_log` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `who` VARCHAR(32) NOT NULL DEFAULT '',
  `kind` VARCHAR(32) NOT NULL,
  `loot_id` INT UNSIGNED NOT NULL,
  `action` VARCHAR(255) NOT NULL DEFAULT '',
  `old_rows` MEDIUMTEXT NULL,
  `new_rows` MEDIUMTEXT NULL,
  `reverted` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_target` (`kind`, `loot_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 首次改某张掉落表之前, 自动把它的官方原样存一份 (只存一次, 之后永不覆盖). "还原到官方" 读这里.
CREATE TABLE IF NOT EXISTS `reborn_lootlab_baseline` (
  `kind` VARCHAR(32) NOT NULL,
  `loot_id` INT UNSIGNED NOT NULL,
  `saved_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `rows_json` MEDIUMTEXT NOT NULL,
  `conds_json` MEDIUMTEXT NULL,
  PRIMARY KEY (`kind`, `loot_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
