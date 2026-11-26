# -*- coding: utf-8 -*-
"""LOOT1A V2: V1 plus plain starter armour and weapons, in three level bands."""
import os, io, sys, json, hashlib
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
B = chr(92)
WS = r'D:\000rebornWOW\000RebornWOWHighForkPRO'
DAY = os.path.join(WS, '000Ascendupdate', '000Ascendupdate20261126')
NAME = 'claudefix_20261126_阶段LOOT1A_V2_怪物掉落增加初始装备_Claude'
P = os.path.join(DAY, NAME)
assert not os.path.exists(P)
v1 = open(r'D:\_zsdc\cls\build_loot.py', encoding='utf-8').read()
exec(v1[v1.index('D = json.load('):v1.index('keys = [(r[0], r[1]) for r in rows]')])      # same drop lists, gear pools and money as V1
G = {o['i']: o for o in json.load(open(r'D:\_zsdc\cls\gear.json', encoding='utf-8'))}
SLOTS = {5, 6, 7, 8, 9, 10, 14, 16, 20}


def family(prefixes, quality=(1,)):
    out = []
    for p in prefixes:
        mine = [i for i, o in G.items() if o['cls'] == 4 and o['inv'] in SLOTS and o['q'] in quality and o['name'].rsplit(' ', 1)[0] == p]
        assert len(mine) >= 4, p
        out += mine
    return sorted(out)


def weapons(lo, hi, per_kind=3):
    kinds = {}
    for i, o in sorted(G.items(), key=lambda x: (x[1]['req'], x[0])):
        if o['cls'] == 2 and o['q'] == 1 and lo <= o['req'] <= hi and o['dmg'] > 0 and o['sub'] in (0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 15, 19):
            kinds.setdefault(o['sub'], []).append(i)
    return sorted(i for v in kinds.values() for i in v[:per_kind])


BAND = {  # name: (armour pool, weapon pool)
    'A': (family(['Cracked Leather', 'Dirty Leather', 'Sun Cured', 'Thin Cloth', 'Tattered Cloth', 'Light Cloth', 'Rusted Chain', 'Tarnished Chain', 'Unadorned Chain'])
          + [1167, 2133, 17184], weapons(1, 3)),
    'B': (family(['Battered Leather', 'Rough Leather', 'Knitted', 'Woven', 'Light Chain', 'Light Mail']) + [17186], weapons(3, 6)),
    'C': (family(['Cadet', 'Gypsy', 'Brackwater', 'Veteran', 'Hunting', 'Spellbinder', 'Infantry', 'War Torn']), weapons(6, 10)),
}
for band, (a, w) in BAND.items():
    assert a and w, band
    for i in a + w:
        assert i in G, (band, i)
# (armour %, weapon %) per kill; 0 chance in the table = "exactly one of the pool, always"
RATE = {('A', 'n'): (30, 8), ('A', 'e'): (100, 50), ('B', 'n'): (22, 6), ('B', 'e'): (100, 50), ('C', 'n'): (14, 5), ('C', 'e'): (100, 40)}
gear_rows = 0
for e, (name, level, kind, donor, extra) in sorted(MOBS.items()):
    if kind == 'b':
        continue                                           # dungeon bosses already drop a green weapon and armour piece
    band = 'A' if level <= 4 else 'B' if level <= 7 else 'C'
    have = {r[1] for r in rows if r[0] == e}
    for group, pool, pct in ((8, BAND[band][0], RATE[(band, kind)][0]), (9, BAND[band][1], RATE[(band, kind)][1])):
        use = [i for i in pool if i not in have]
        have |= set(use)
        for i in use:
            rows.append((e, i, 0 if pct == 100 else round(pct / len(use), 4), group, 1, 1, 'LOOT1A %s 初始装备' % name))
            gear_rows += 1
assert max(r[3] for r in rows if r[3] not in (8, 9)) < 8
keys = [(r[0], r[1]) for r in rows]
assert len(keys) == len(set(keys))
for e in MOBS:
    for g in {r[3] for r in rows if r[0] == e and r[3]}:
        total = sum(r[2] for r in rows if r[0] == e and r[3] == g)
        assert total <= 100.5, (e, g, total)
E = ', '.join(map(str, sorted(MOBS)))
q = lambda s: "'" + s.replace("'", "''") + "'"
sql = ['-- LOOT1A V2 (2026-11-26, Claude): drops, money and starter equipment for the Exile\'s Reach creatures. Replaces LOOT1A V1 (works with or without it).',
       '-- Quest drops are not touched. Safe to run twice. Rerunning BEACH1A / BEACH1B removes these rows for those creatures: run this file again.',
       'SET NAMES utf8mb4;',
       'SELECT COUNT(*) AS creatures_found_%d FROM `creature_template` WHERE `entry` IN (%s);' % (len(MOBS), E),
       'SELECT `entry`, `lootid` AS other_loot_table_expected_none FROM `creature_template` WHERE `entry` IN (%s) AND `lootid` NOT IN (0, `entry`);' % E,
       "DELETE FROM `creature_loot_template` WHERE `Comment` LIKE 'LOOT1A %';"]
head = 'INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES'
for e in sorted(MOBS):
    mine = [r for r in rows if r[0] == e]
    sql.append(head + '\n' + ',\n'.join('(%d, %d, 0, %s, 0, 1, %d, %d, %d, %s)' % (r[0], r[1], r[2], r[3], r[4], r[5], q(r[6])) for r in mine) + ';')
    lo, hi = money(e, MOBS[e][1], MOBS[e][2])
    sql.append('UPDATE `creature_template` SET `lootid` = %d, `mingold` = %d, `maxgold` = %d WHERE `entry` = %d AND `lootid` IN (0, %d);' % (e, lo, hi, e, e))
sql += ["SELECT (SELECT COUNT(*) FROM `creature_loot_template` WHERE `Comment` LIKE 'LOOT1A %%') AS rows_%d," % len(rows),
        '       (SELECT COUNT(*) FROM `creature_template` WHERE `entry` IN (%s) AND `lootid` = `entry`) AS with_loot_%d,' % (E, len(MOBS)),
        "       (SELECT COUNT(*) FROM `creature_loot_template` l LEFT JOIN `item_template` i ON i.`entry` = l.`Item` WHERE l.`Comment` LIKE 'LOOT1A %' AND i.`entry` IS NULL) AS missing_items_0;"]
undo = ['-- undo LOOT1A (V1 or V2)',
        "DELETE FROM `creature_loot_template` WHERE `Comment` LIKE 'LOOT1A %';",
        'UPDATE `creature_template` SET `mingold` = 0, `maxgold` = 0 WHERE `entry` IN (%s);' % E,
        'UPDATE `creature_template` t SET t.`lootid` = 0 WHERE t.`entry` IN (%s) AND NOT EXISTS (SELECT 1 FROM `creature_loot_template` l WHERE l.`Entry` = t.`entry`);' % E]


def wr(rel, data, nl='\n'):
    f = os.path.join(P, rel.replace('/', B))
    os.makedirs(os.path.dirname(f), exist_ok=True)
    open(f, 'w', encoding='utf-8', newline=nl).write(data)


sha = lambda p: hashlib.sha256(open(p, 'rb').read()).hexdigest()
wr('01_服务端_SQL/world_loot1a_v2.sql', '\n'.join(sql) + '\n', '\r\n')
wr('02_撤销/undo_loot1a.sql', '\n'.join(undo) + '\n', '\r\n')
wr('README_覆盖与测试说明.md', '''# LOOT1A V2：怪物掉落增加初始装备

状态：候选，游戏里未测。只改服务端数据库。**取代 LOOT1A V1**(装没装过 V1 都直接跑本包)。

## 改动
V1 的杂物、金币、绿装保持不变，另外加两类白色初始装备(胸甲、裤子、鞋、手套、腰带、护腕、披风、盾和各类武器)：

| 怪物等级 | 装备档次 | 普通怪：护甲 / 武器 | 稀有怪和头目 |
|---|---|---|---|
| 1–4 级(鱼人、野兽、蜘蛛、野猪人、鹰身人) | 1 级可穿 | %d%% / %d%% | 必掉一件护甲，%d%% 掉武器 |
| 5–7 级 | 3–6 级可穿 | %d%% / %d%% | 必掉一件护甲，%d%% 掉武器 |
| 8–10 级(食人魔、守卫、副官) | 6–10 级可穿 | %d%% / %d%% | 必掉一件护甲，%d%% 掉武器 |

- 野兽(山羊、豪猪、蜘蛛等)也会掉装备，方便开荒。
- 装备从整个档次里随机，可能掉到本职业穿不了的，可以卖掉。
- 副本首领不变(必掉一件绿色武器和一件绿色护甲)。

## 部署
1. 停 worldserver。
2. world 库执行 `01_服务端_SQL/world_loot1a_v2.sql`。
   开头读回 creatures_found %d；第二条查询应当没有任何行。
   末尾读回 rows %d、with_loot %d、missing_items 0。
3. 启动 worldserver。打新刷出来的怪。

以后重跑海滩任务 SQL(BEACH1A/1B)会删掉那几个怪的掉落，要接着再跑本包。

## 测试
新号在海滩杀 10 只怪左右，应该能拿到几件白色装备和铜币；任务物品照常掉。嫌多嫌少告诉我，改一个百分比就行。

## 撤销
执行 `02_撤销/undo_loot1a.sql`，重启。
''' % (RATE[('A', 'n')] + (RATE[('A', 'e')][1],) + RATE[('B', 'n')] + (RATE[('B', 'e')][1],) + RATE[('C', 'n')] + (RATE[('C', 'e')][1],) + (len(MOBS), len(rows), len(MOBS))))
wr('memory.md', '''# memory - LOOT1A V2 (2026-11-26, Claude, 候选未测)
- 用户截图(2 级角色只穿内衣)："这些怪物掉的东西基本出生的装备都没有 需要稍微优化下"。
- V1 低级怪只掉灰色杂物。V2 加三档白色装备池(组 8 护甲、组 9 武器)。脚本 D:\\_zsdc\\cls\\(gearq.py、build_loot2.py)。
''')
wr('tutor.md', '''# tutor - 新手区掉落要能穿 (LOOT1A V2, 未实测)
零售清单过滤到旧版本后往往只剩杂物；按等级分档补一组固定属性白装，用掉落组控制每次最多一件。
''')
lines = []
for dp, dn, fn in os.walk(P):
    for f in sorted(fn):
        p = os.path.join(dp, f)
        lines.append('%s  %s' % (sha(p), os.path.relpath(p, P).replace(B, '/')))
wr('SHA256SUMS.txt', '\n'.join(lines) + '\n')
log = os.path.join(WS, '协作说明_并行开发.md')
t = open(log, 'rb').read()
assert 'LOOT1A V2(' not in t.decode('utf-8', 'replace')
e_ = b'\r\n' if b'\r\n' in t else b'\n'
row = '| 2026-11-26 | Claude | LOOT1A V2(流放者之岛怪物掉落增加初始装备，取代 V1) | 候选(实机未测) | 仅服务端 world SQL(creature_loot_template、lootid/金币) | 基线：ER-ALLIANCE-20261126 | 包 000Ascendupdate20261126/%s | 无共享客户端文件 |' % NAME
open(log, 'ab').write((b'' if t.endswith(b'\n') else e_) + row.encode('utf-8') + e_)
M = r'C:\Users\beyourself\.claude\projects\d--000rebornWOW-000RebornWOWHighForkPRO-beascendLauncher-wowlauncher2026-CataLauncher-rebornWOW\memory\er-both-factions-pushed-20261126.md'
assert open(M, encoding='utf-8').read().strip()
open(M, 'a', encoding='utf-8').write(u"\n2026-11-26: user testing level run: drops lacked wearable starter gear -> LOOT1A V2 (replaces V1; band pools of white gear), untested.\n")
print(len(MOBS), 'creatures', len(rows), 'rows,', gear_rows, 'gear rows')
for band, (a, w) in BAND.items():
    print(band, 'armour', len(a), 'weapons', len(w), 'types', sorted({G[i]['sub'] for i in w}))
    print('  sample', [G[i]['name'] for i in a[:4]], [G[i]['name'] for i in w[:6]])
