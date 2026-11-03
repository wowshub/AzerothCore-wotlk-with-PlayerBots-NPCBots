-- WORLD DATABASE. HOME1B: plot markers (flag in the middle, posts along the edge). Safe to run more than once. No --force.
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS `reborn_housing_marker` (
  `marker_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `plot_id`   INT UNSIGNED NOT NULL,
  `kind`      TINYINT UNSIGNED NOT NULL COMMENT '1 flag, 2 edge post',
  `spawn_id`  INT UNSIGNED NOT NULL COMMENT 'guid of the row in the core gameobject table',
  `map_id`    SMALLINT UNSIGNED NOT NULL,
  `x` FLOAT NOT NULL, `y` FLOAT NOT NULL, `z` FLOAT NOT NULL,
  `created`   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`marker_id`),
  KEY `idx_plot` (`plot_id`),
  KEY `idx_spawn` (`spawn_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Rollback: DROP TABLE `reborn_housing_marker`; (remove placed markers first with .home plot delete <id>)
