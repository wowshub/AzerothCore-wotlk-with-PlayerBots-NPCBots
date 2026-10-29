-- LAB3C 掉落工坊时间点 (world 库). 可重复执行. 需要先有 LAB0 的 reborn_lootlab_baseline.
-- 一个时间点 = 某一刻"工坊改过的每张掉落表"的完整内容 (改过的表 = reborn_lootlab_baseline 里列出的表).
CREATE TABLE IF NOT EXISTS `reborn_lootlab_snapshot` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `name` VARCHAR(80) NOT NULL DEFAULT '',
  `snap_type` VARCHAR(12) NOT NULL DEFAULT 'manual',   -- manual 手动 / auto 自动 / before 回到某时间点之前自动保存
  `who` VARCHAR(32) NOT NULL DEFAULT '',
  `tables_n` INT UNSIGNED NOT NULL DEFAULT 0,
  `bytes` BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `hash` CHAR(32) NOT NULL DEFAULT '',                  -- 内容的 MD5: 和上一个一样就不重复保存
  PRIMARY KEY (`id`),
  KEY `idx_type` (`snap_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `reborn_lootlab_snapshot_row` (
  `snap_id` INT UNSIGNED NOT NULL,
  `kind` VARCHAR(32) NOT NULL,
  `loot_id` INT UNSIGNED NOT NULL,
  `rows_json` MEDIUMTEXT NOT NULL,
  PRIMARY KEY (`snap_id`, `kind`, `loot_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
