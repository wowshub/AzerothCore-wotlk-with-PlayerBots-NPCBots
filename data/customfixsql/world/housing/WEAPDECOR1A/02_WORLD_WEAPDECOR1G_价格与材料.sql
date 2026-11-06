-- WEAPDECOR1G: 三件武器摆件的价格与制作材料（按所在地图等级分档）
-- 需要先导入过 HOME9A 的 00_ 加列脚本（rarity / ways 两列）。
-- 价格单位：铜币。实际售价 = gold_copper x 稀有度倍率(Housing.Rarity.PriceMultiplier) x Housing.Acquire.GoldPercent / 100
-- 等级档（基础价）：低级(1-60) 20金；外域(60-70) 40金；诺森德(70-80) 80金；PvP 100金。
-- 稀有度 2 = 倍率200%，ways 3 = 可购买+可制作（4 = 掉落/拾取，另算）。
INSERT INTO `reborn_housing_recipe`
 (`catalog_id`,`gold_copper`,`m1_item`,`m1_count`,`m2_item`,`m2_count`,`m3_item`,`m3_count`,`source_zh`,`rarity`,`ways`) VALUES
 -- 10401 PvP 联盟战锤：PvP 档。荣誉材料用常见矿：钴矿锭 / 萨隆邦钢锭 / 霜纹布
 (10401, 1000000, 36913, 6, 33470, 10, 0, 0, 'PvP 武器摆件', 2, 3),
 -- 10402 诺森德战斧：诺森德档
 (10402,  800000, 36913, 4, 37663, 2, 0, 0, '诺森德武器摆件', 2, 3),
 -- 10403 大型战锤 B：外域档
 (10403,  400000, 23445, 4, 23426, 4, 0, 0, '外域武器摆件', 2, 3)
ON DUPLICATE KEY UPDATE
 `gold_copper`=VALUES(`gold_copper`),
 `m1_item`=VALUES(`m1_item`),`m1_count`=VALUES(`m1_count`),
 `m2_item`=VALUES(`m2_item`),`m2_count`=VALUES(`m2_count`),
 `m3_item`=VALUES(`m3_item`),`m3_count`=VALUES(`m3_count`),
 `source_zh`=VALUES(`source_zh`),`rarity`=VALUES(`rarity`),`ways`=VALUES(`ways`);
-- 材料物品ID：36913 萨隆邦钢锭，33470 霜纹布，37663 泰坦精钢锭，23445 魔化铁锭，23426 氪金锭（请在游戏里核对后再改）
SELECT `catalog_id`,`gold_copper`,`m1_item`,`m1_count`,`m2_item`,`m2_count`,`rarity`,`ways` FROM `reborn_housing_recipe` WHERE `catalog_id` IN (10401,10402,10403);
