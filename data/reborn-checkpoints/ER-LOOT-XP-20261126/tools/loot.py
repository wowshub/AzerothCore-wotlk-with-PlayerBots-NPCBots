# -*- coding: utf-8 -*-
"""Step 1 of LOOT1A: retail drop lists for the island creatures, filtered to items that exist in 3.3.5, plus stock gold and green-item data."""
import sys, io, os, json, statistics
sys.path.insert(0, r'D:\_zsdc\wow12x')
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
from er_lib import rows, cols
from sqlrows import split_rows
BASE = r'D:\000rebornWOW\000RebornWOWHighForkPRO\beascendcode\claude-release-20261126\data\sql\base\db_world'
MOBS = [150228, 150229, 150238, 151091, 152843, 153239, 153266, 153581, 153582, 153583, 153964, 156501, 156814, 156900, 157300, 160394, 160433,
        161130, 161131, 161133, 162817, 165150, 9159801, 9159802, 9159803]


def base_cols(table):
    on, c = False, []
    for line in open(os.path.join(BASE, table + '.sql'), encoding='utf-8', errors='replace'):
        if line.startswith('CREATE TABLE `%s`' % table):
            on = True
            continue
        if on:
            if line.startswith(')'):
                return c
            s = line.strip()
            if s.startswith('`'):
                c.append(s.split('`')[1])


def base_rows(table):
    c = base_cols(table)
    n = 0
    for line in open(os.path.join(BASE, table + '.sql'), encoding='utf-8', errors='replace'):
        if not line.startswith('('):          # the base dumps put one row on each line
            continue
        for r in split_rows(line):
            assert len(r) == len(c), (table, len(r), len(c))
            n += 1
            yield dict(zip(c, r))
    assert n > 1000, (table, n)


retail = {}
for r in rows('creature_loot_template'):
    e = int(r['Entry'])
    if e in MOBS:
        retail.setdefault(e, []).append(r)
print('retail loot columns', cols('creature_loot_template'))
want = {int(r['Item']) for v in retail.values() for r in v}
items, greens = {}, []
for r in base_rows('item_template'):
    i = int(r['entry'])
    q, cls, req, ilvl = int(r['Quality']), int(r['class']), int(r['RequiredLevel']), int(r['ItemLevel'])
    info = dict(name=r['name'].strip("'"), q=q, cls=cls, sub=int(r['subclass']), req=req, ilvl=ilvl, inv=int(r['InventoryType']), bond=int(r['bonding']),
                rnd=int(r['RandomProperty']) or int(r['RandomSuffix']), stats=int(r['stat_value1']), flags=int(r['Flags']), classmask=int(r['AllowableClass']), disp=int(r['displayid']))
    if i in want:
        items[i] = info
    if q == 2 and cls in (2, 4) and 6 <= req <= 10 and info['inv'] and i < 25000 and info['disp'] and info['classmask'] in (-1, 32767, 1535, 262143):
        greens.append((i, info))
gold = {}
for r in base_rows('creature_template'):
    lv = int(r['minlevel'])
    if lv <= 12 and int(r['maxlevel']) == lv and int(r['rank']) == 0 and int(r['type']) == 7 and int(r['mingold']) > 0:
        gold.setdefault(lv, []).append((int(r['mingold']), int(r['maxgold'])))
gold = {lv: (int(statistics.median(a for a, _ in v)), int(statistics.median(b for _, b in v))) for lv, v in gold.items()}
json.dump(dict(retail={e: v for e, v in retail.items()}, items=items, greens=greens, gold=gold), open(r'D:\_zsdc\cls\loot.json', 'w', encoding='utf-8'), ensure_ascii=False)
for e in MOBS:
    v = retail.get(e, [])
    ok = [r for r in v if int(r['Item']) in items and r.get('QuestRequired') in ('0', None)]
    print(e, 'retail rows', len(v), 'usable in 3.3.5', len(ok), [(int(r['Item']), items[int(r['Item'])]['name'][:18], r['Chance']) for r in ok][:4])
print('gold by level', sorted(gold.items()))
print('greens', len(greens))
for i, g in sorted(greens, key=lambda x: (x[1]['rnd'] != 0, x[1]['req']))[:60]:
    print(i, g['name'], 'cls', g['cls'], g['sub'], 'inv', g['inv'], 'req', g['req'], 'rnd', g['rnd'])
