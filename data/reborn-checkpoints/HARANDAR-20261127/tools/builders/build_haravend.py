# -*- coding: utf-8 -*-
"""HARAVEND1 V1: the three retail merchants of Har'mara (weapons/armour/repair, general goods, innkeeper)."""
import os, io, sys, hashlib, sqlite3, glob, re, math
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
B = chr(92)
J = os.path.join
WS = r'D:\000rebornWOW\000RebornWOWHighForkPRO'
DAY = J(WS, '000Ascendupdate', '000Ascendupdate20261126')
P = J(DAY, u'claudefix_20261126_阶段HARAVEND1_V1_哈籁尼尔出生地商人修理旅店_Claude')
assert not os.path.exists(P), P
sha = lambda b: hashlib.sha256(b).hexdigest()
exec(open(r'D:\_zsdc\cls\classq.py', encoding='utf-8').read().split("cls = {}")[0].replace("sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')", ''))
exec(open(r'D:\_zsdc\maps2\verify.py', encoding='utf-8').read().split('# retail creature positions')[0].replace("sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')\n", ''))
BASEDIR = r'D:\000rebornWOW\000RebornWOWHighForkPRO\beascendcode\claude-release-20261126\data\sql\base\db_world'


def rows(table):
    cols_, on = [], False
    for line in open(J(BASEDIR, table + '.sql'), encoding='utf-8', errors='replace'):
        if line.startswith('CREATE TABLE `%s`' % table):
            on = True
        elif on and line.startswith(')'):
            on = False
        elif on and line.strip().startswith('`'):
            cols_.append(line.strip().split('`')[1])
        elif line.startswith('('):
            for r_ in split_rows(line):
                yield dict(zip(cols_, r_))


q = lambda s: "'" + s.replace(chr(92), chr(92) * 2).replace("'", "''") + "'"
# entry: name, subtitle, npcflag, stand-in display, x, y, z (retail), orientation, donors, extra items
NPC = {
    252203: (u"Al'luun 奥露恩", u'Weapons, Armor & Repairs 武器护甲与修理', 4224, 1710, 1272.0, 964.0, 1332.5, 3.9, [3588, 3609, 3610, 3611, 3612, 3613], [2508, 2509]),
    252211: (u"Le'neia 勒奈亚", u'General Goods 杂货与弹药', 128, 1700, 1379.0, 923.0, 1346.2, 3.4, [3608, 3614, 3589], [2512, 2516]),
    258354: (u"Gnu'la 格努菈", u'Innkeeper 旅店老板', 65665, 4861, 1372.0, 916.0, 1346.4, 3.1, [6736], []),
}
IDL = ', '.join(map(str, sorted(NPC)))
assert not [r['entry'] for r in rows('creature_template') if int(r['entry']) in NPC]
vend = {}
for r in rows('npc_vendor'):
    vend.setdefault(int(r['entry']), []).append((int(r['item']), int(r['ExtendedCost'])))
items = {int(r['entry']): r['name'] for r in rows('item_template')}
displays = {int(r['CreatureDisplayID']) for r in rows('creature_template_model') if r['CreatureID'] in ('3613', '3608', '6091')}
assert {1710, 1700, 4861} == displays, displays
stock = {}
for e, v in NPC.items():
    got = set()
    for d in v[8]:
        assert vend.get(d), d
        assert all(c == 0 for _i, c in vend[d]), (d, 'donor sells for special currency')
        got |= {i for i, _c in vend[d]}
    got |= set(v[9])
    assert got <= set(items) and len(got) <= 150, (e, len(got), got - set(items))
    stock[e] = len(got)
print('items per merchant', stock)
# keep clear of the monsters of HARA2 / HARA3 and check the ground
mobs = []
for pat in (u'claudefix_*HARA2_V1_*', u'claudefix_*HARA3_V1_*'):
    sqlf = glob.glob(J(glob.glob(DAY + B + pat)[0], '04_*', '*.sql'))[0]
    mobs += [(int(e), float(x), float(y)) for e, x, y in re.findall(r"\(@g \+ \d+, (\d+), 12694, 1, 1, 0, ([\d.-]+), ([\d.-]+),", open(sqlf, encoding='utf-8').read())]
hostile = {245114}
for e, v in NPC.items():
    x, y, z = v[4], v[5], v[6]
    t = height(12694, x, y)
    near = sorted((round(math.hypot(a - x, b - y)), m) for m, a, b in mobs)[:3]
    print(e, 'z', z, 'ground', round(t, 1), 'nearest monsters (yards, entry)', near)
    assert -0.8 < z - t < 3.0, (e, z, t)
    assert not [m for d, m in near if m in hostile and d < 30]

SQL = [u'''-- HARAVEND1 V1 (2026-11-26, Claude) - candidate, NOT user-tested. Stop worldserver, WORLD database, restart. Safe to run twice.
SET NAMES utf8mb4;
SET @spawn_limit := 16777215;
SELECT COUNT(DISTINCT `entry`) AS stock_vendor_lists_must_be_10 FROM `npc_vendor` WHERE `entry` IN (%(donors)s);
DELETE FROM `creature` WHERE `map` = 12694 AND `Comment` LIKE 'HARAVEND %%';
DELETE FROM `creature_template` WHERE `entry` IN (%(ids)s);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (%(ids)s);
DELETE FROM `npc_vendor` WHERE `entry` IN (%(ids)s);
SELECT COALESCE(MAX(`guid`), 0) INTO @g FROM `creature` WHERE `guid` < @spawn_limit;
SELECT IF(@g + 10 + 10000 < @spawn_limit, 'guid base OK', 'ABORT: no guid room, do not continue') AS guid_check;''' % dict(ids=IDL, donors=', '.join(str(d) for v in NPC.values() for d in v[8]))]
for k, (e, (name, sub, flag, disp, x, y, z, o, donors, extra)) in enumerate(sorted(NPC.items()), 1):
    SQL.append(u'INSERT INTO `creature_template` (`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `unit_class`, `unit_flags`, `type`, `AIName`, `MovementType`, `HealthModifier`, `DamageModifier`, `ExperienceModifier`, `RegenHealth`, `flags_extra`, `ScriptName`) VALUES\n(%d, %s, %s, 10, 10, 35, %d, 1, 1.14286, 0, 1, 768, 7, \'\', 0, 3, 1, 0, 1, 2, \'\');' % (e, q(name), q(sub), flag))
    SQL.append('INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES (%d, 0, %d, 1, 1, 0);' % (e, disp))
    SQL.append('INSERT IGNORE INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`)\nSELECT %d, 0, `item`, `maxcount`, `incrtime`, `ExtendedCost`, 0 FROM `npc_vendor` WHERE `entry` IN (%s);' % (e, ', '.join(map(str, donors))))
    if extra:
        SQL.append('INSERT IGNORE INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `ExtendedCost`, `VerifiedBuild`) VALUES %s;' % ', '.join('(%d, 0, %d, 0, 0, 0, 0)' % (e, i) for i in extra))
    SQL.append("INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES\n(@g + %d, %d, 12694, 1, 1, 0, %.2f, %.2f, %.2f, %.2f, 60, 0, 0, 'HARAVEND %d');" % (k, e, x, y, z + 0.05, o, e))
SQL.append(u'''SELECT (SELECT COUNT(*) FROM `creature_template` WHERE `entry` IN (%(ids)s)) AS merchants_must_be_3,
       (SELECT COUNT(*) FROM `creature` WHERE `Comment` LIKE 'HARAVEND %%') AS spawns_must_be_3,
       (SELECT COUNT(*) FROM `npc_vendor` WHERE `entry` = 252203) AS weapons_armor_about_%(a)d,
       (SELECT COUNT(*) FROM `npc_vendor` WHERE `entry` = 252211) AS general_goods_about_%(g)d,
       (SELECT COUNT(*) FROM `npc_vendor` WHERE `entry` = 258354) AS innkeeper_about_%(i)d;''' % dict(ids=IDL, a=stock[252203], g=stock[252211], i=stock[258354]))
SQL = '\n'.join(SQL)
UNDO = u'''-- undo HARAVEND1
DELETE FROM `creature` WHERE `map` = 12694 AND `Comment` LIKE 'HARAVEND %%';
DELETE FROM `creature_template` WHERE `entry` IN (%(ids)s);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (%(ids)s);
DELETE FROM `npc_vendor` WHERE `entry` IN (%(ids)s);
''' % dict(ids=IDL)

# ---- simulate
db = sqlite3.connect(':memory:')
db.create_function('IF', 3, lambda a, b, c: b if a else c)
db.execute('create table creature(guid, id1, map, spawnMask, phaseMask, equipment_id, position_x, position_y, position_z, orientation, spawntimesecs, wander_distance, MovementType, Comment)')
db.execute('create table creature_template(entry primary key, name, subname, minlevel, maxlevel, faction, npcflag, speed_walk, speed_run, rank, unit_class, unit_flags, type, AIName, MovementType, HealthModifier, DamageModifier, ExperienceModifier, RegenHealth, flags_extra, ScriptName)')
db.execute('create table creature_template_model(CreatureID, Idx, CreatureDisplayID, DisplayScale, Probability, VerifiedBuild)')
db.execute('create table npc_vendor(entry, slot, item, maxcount, incrtime, ExtendedCost, VerifiedBuild, primary key(entry, item, ExtendedCost))')
for v in NPC.values():
    for d in v[8]:
        db.executemany('insert or ignore into npc_vendor values (?, 0, ?, 0, 0, ?, 0)', [(d, i, c) for i, c in vend[d]])


def run(text, show):
    var = {}
    t = '\n'.join(l for l in text.splitlines() if not l.startswith('--'))
    stm, cur = [], ''
    for part in t.split(';'):
        cur += part
        if cur.count("'") % 2 == 0:
            stm.append(cur)
            cur = ''
        else:
            cur += ';'
    for s in stm:
        s = s.strip()
        if not s or s.startswith('SET NAMES'):
            continue
        m = re.match(r'SET @(\w+) := (\d+)$', s)
        if m:
            var[m[1]] = m[2]
            continue
        into = re.search(r' INTO @(\w+)', s) if s.startswith('SELECT') else None
        if into:
            s = s.replace(into[0], '')
        s = re.sub(r'@(\w+)', lambda m: str(var.get(m[1], m[0])), s).replace('INSERT IGNORE', 'INSERT OR IGNORE')
        c = db.execute(s)
        if into:
            var[into[1]] = c.fetchone()[0]
        elif s.startswith('SELECT') and show:
            names = [d[0] for d in c.description]
            for r in c.fetchall():
                print('  ', dict(zip(names, r)))


count = lambda: [db.execute('select count(*) from %s' % t).fetchone()[0] for t in ('creature', 'creature_template', 'creature_template_model', 'npc_vendor')]
before = count()
run(SQL, True)
after = count()
run(SQL, False)
assert count() == after
for e in NPC:
    assert db.execute('select count(*) from npc_vendor where entry = ?', (e,)).fetchone()[0] == stock[e], e
run(UNDO, False)
assert count() == before
print('sql ran twice identically; undo restores the seeded state')


def wr(rel, data):
    p = J(P, rel.replace('/', B))
    os.makedirs(os.path.dirname(p), exist_ok=True)
    assert not os.path.exists(p), p
    data = data.strip('\n').replace('\n', '\r\n').encode('utf-8-sig' if rel.endswith('.md') else 'utf-8') + b'\r\n'
    open(p, 'wb').write(data)


wr(u'01_服务端_SQL/world_haravend1.sql', SQL)
wr(u'02_撤销/undo_haravend1.sql', UNDO)
wr(u'README_覆盖与测试说明.md', u'''
# HARAVEND1 V1：哈籁尼尔出生地商人(候选，实机未测)

零售在出生点附近本来就有这三位，用零售的名字和位置。他们是定制人形外观，暂用现成暗夜精灵代替。

| NPC | 位置(.go xyz … 12694) | 功能 | 商品 |
|---|---|---|---|
| 奥露恩 Al'luun | 出生点北边约 40 码 `1272 964 1333` | 武器、护甲、**修理** | 约 %(a)d 种：1–5 级布甲/皮甲/锁甲、盾、近战武器、弓和火枪、箭袋 |
| 勒奈亚 Le'neia | 戴尼尔东边 `1379 923 1346` | 杂货 | 约 %(g)d 种：背包、箭和子弹、投掷武器、专业工具和材料、钓鱼竿 |
| 格努菈 Gnu'la | 勒奈亚旁 `1372 916 1346` | 旅店(绑定炉石)、食物饮料 | 约 %(i)d 种 |

零售里勒奈亚卖的是铭文材料，这里改成杂货。商品清单照抄原版泰达希尔(暗夜精灵新手区)商人。

## 部署(停服)
world 库执行 `01_服务端_SQL\\world_haravend1.sql`。开头 `stock_vendor_lists`=10、`guid base OK`；末尾 3、3 和三个商品数。启动服务端，删客户端 `Cache\\WDB`。没有客户端文件。

## 测试
右键能打开购买界面；能卖东西；奥露恩能修理；格努菈能把这里设为炉石点并能用炉石传回；NPC 不悬空、不陷地。

## 撤销
执行 `02_撤销\\undo_haravend1.sql`。
''' % dict(a=stock[252203], g=stock[252211], i=stock[258354]))
wr(u'memory.md', u'''
# HARAVEND1 V1 记录(2026-11-26，Claude)
用户："给这个出生点 加点买卖东西的NPC"。零售 252203/252211/258354 的位置和名字，替身外观 1710/1700/4861，商品复制泰达希尔商人。状态：候选，未实测。脚本 D:\\_zsdc\\hara\\build_haravend.py。''')
wr(u'tutor.md', u'''
# 大白话
先看零售原地有没有商人，有就照搬位置和名字；卖什么直接抄老版本同类新手区商人的货单，价格和等级自然合适。''')
lines = []
for dp, _d, fn in os.walk(P):
    for fl in fn:
        p = J(dp, fl)
        lines.append('%s  %s' % (sha(open(p, 'rb').read()), os.path.relpath(p, P).replace(B, '/')))
open(J(P, 'SHA256SUMS.txt'), 'wb').write('\n'.join(sorted(lines, key=lambda s: s[66:])).encode('utf-8') + b'\n')


def app(path, text, key):
    t = open(path, 'rb').read()
    assert t.strip() and key.encode('utf-8') not in t, path
    e = '\r\n' if b'\r\n' in t else '\n'
    open(path, 'ab').write((('' if t.endswith(b'\n') else e) + e + text.replace('\n', e) + e).encode('utf-8'))
    assert open(path, 'rb').read().startswith(t)


app(J(WS, u'协作说明_并行开发.md'), u'| 2026-11-26 | Claude | HARAVEND1 V1：哈籁尼尔三位商人 | 候选(实机未测) | world 生物 252203/252211/258354、npc_vendor、3 个刷新点 | 离线模拟通过 | 000Ascendupdate20261126/claudefix_…HARAVEND1… | 无客户端文件 |', u'HARAVEND1 V1：哈籁尼尔三位')
MD = r'<user-profile>\.claude\projects\d--000rebornWOW-000RebornWOWHighForkPRO-beascendLauncher-wowlauncher2026-CataLauncher-rebornWOW\memory'
app(J(MD, 'haranir-start-port.md'), u'11-26: user asked for merchants at the start -> HARAVEND1 V1 delivered (retail vendors 252203/252211/258354), untested. User also reported the fleeing mob healing to full = same critter bug, fixed by HARA3 V2.', u'HARAVEND1 V1 delivered')
print(P)
