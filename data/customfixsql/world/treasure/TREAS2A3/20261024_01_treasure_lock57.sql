-- TREAS2A3: 在 world 库执行。宝箱模板的锁编号 Data0 设为 57（原生“破损的箱子”同款，任何人可开）
UPDATE gameobject_template SET Data0 = 57 WHERE entry BETWEEN 990200 AND 990299;
SELECT entry, name, Data0 AS lockId, Data1 AS lootId FROM gameobject_template WHERE entry BETWEEN 990200 AND 990202;
