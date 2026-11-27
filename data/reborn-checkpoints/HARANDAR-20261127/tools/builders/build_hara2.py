# -*- coding: utf-8 -*-
"""HARA2 V1: the four retail Haranir starter quests, retail creature models, loot, rewards, mentors, click script."""
import ctypes, struct, os, hashlib, shutil, io, sys, pickle, glob, re, sqlite3, math
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
B = chr(92)
J = os.path.join
WS = r'D:\000rebornWOW\000RebornWOWHighForkPRO'
DAY = J(WS, '000Ascendupdate', '000Ascendupdate20261126')
P = J(DAY, u'claudefix_20261126_阶段HARA2_V1_哈籁尼尔出生任务1到4_原版怪物模型掉落奖励职业导师_Claude')
assert not os.path.exists(P), P
CLIENT = r'C:\000ref\WarcraftXL试装_client'
SRVROOT = J(WS, 'beascendserver', 'wowshub_playerbot_npcbot_newrace20261122Ascend')
SRV = J(SRVROOT, 'Data', 'dbc')
H = r'D:\_zsdc\hara'
M = J(H, 'models')
sha = lambda b: hashlib.sha256(b).hexdigest()
fb = lambda x: struct.unpack('<I', struct.pack('<f', x))[0]
exec(open(r'D:\_zsdc\cls\classq.py', encoding='utf-8').read().split("cls = {}")[0].replace("sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')", ''))
exec(open(r'D:\_zsdc\maps2\verify.py', encoding='utf-8').read().split('# retail creature positions')[0].replace("sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')\n", ''))
bsrc = open(r'D:\_zsdc\models4\build_model1a.py', encoding='utf-8').read()
exec(bsrc[bsrc.index('dll = ctypes.WinDLL'):bsrc.index('# id, folder, m2 file id')])      # client_table / parse / row_of / append
R = pickle.load(open(J(H, 'q14.pkl'), 'rb'))
BASEDIR = r'D:\000rebornWOW\000RebornWOWHighForkPRO\beascendcode\claude-release-20261126\data\sql\base\db_world'


def rows(table):
    """rows of a base world table (the helpers loaded above reuse the name B, so this one carries its own path)"""
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


# ------------------------------------------------------------------ models: id -> (folder, template display, cdi scale, texture fdids, radius, reach)
MODEL = {
    710101: ('HaraDrifter', 17751, 0.25, [7106044, 7106036, 7106040], 0.5, 1.2),
    710102: ('HaraSludger', 705, 1.0, [5140792], 0.5, 1.0),
    710103: ('HaraPlant', 1092, 1.0, [], 0.5, 1.0),
    710104: ('HaraLasher', 1092, 1.0, [1722697], 0.6, 1.2),
    710105: ('HaraSaptor', 180, 1.0, [6055706, 6055711], 0.7, 1.5),
    710106: ('HaraOrweyna', 2261, 1.0, [], 0.35, 1.5),
}


def box_of(folder):
    m = open(J(M, 'd', 'retail_%s_%s.m2' % (folder, folder)), 'rb').read()
    nv, vo = struct.unpack_from('<II', m, 0x3c)
    vs = [struct.unpack_from('<3f', m, vo + 48 * i) for i in range(nv)]
    return [min(v[k] for v in vs) for k in range(3)] + [max(v[k] for v in vs) for k in range(3)]


def build(read):
    md0, di0 = read('CreatureModelData.dbc'), read('CreatureDisplayInfo.dbc')
    msb, dbase = parse(md0)[4], len(parse(di0)[4])
    mrows, drows, mstr, dstr = [], [], b'', b''
    for nid, (folder, tdisp, cscale, tex, _r, _c) in sorted(MODEL.items()):
        tdr = row_of(di0, tdisp)
        mr = row_of(md0, tdr[1])
        assert mr is not None and len(mr) == 28, (nid, tdisp)
        mr[0], mr[2] = nid, len(msb) + len(mstr)
        mstr += (B.join(['retail', folder, folder]) + '.mdx').encode() + b'\0'
        mr[4] = fb(1.0)
        mr[14], mr[15], mr[16] = fb(0.611), fb(2.031), 0
        for i, v in zip(range(17, 23), box_of(folder)):
            mr[i] = fb(v)
        mrows.append(mr)
        dr = list(tdr)
        assert len(dr) == 16
        dr[0], dr[1] = nid, nid
        dr[3] = 0
        dr[4], dr[5] = fb(cscale), 255
        dr[6] = dr[7] = dr[8] = dr[9] = dr[13] = dr[14] = dr[15] = 0
        for k, t in enumerate(tex):
            s = '%s%d' % (folder, t)
            dr[6 + k] = dbase + len(dstr)
            dstr += s.encode() + b'\0'
        drows.append(dr)
    return {'CreatureModelData.dbc': (md0, append(md0, mrows, mstr)), 'CreatureDisplayInfo.dbc': (di0, append(di0, drows, dstr))}


client = build(client_table)
server = build(lambda n: open(J(SRV, n), 'rb').read())
csv_old = open(J(CLIENT, 'Data', 'Retail', 'aliases_maps.csv'), 'rb').read()
assert b'Harandar' in csv_old, 'the map client package is not installed'
add = open(J(M, 'aliases_maps.csv'), 'rb').read().split()
for line in add:
    fdid = line.split(b';')[0] + b';'
    assert not any(x.startswith(fdid) for x in csv_old.split()), line
csv_new = csv_old + (b'' if csv_old.endswith(b'\n') else b'\r\n') + b'\r\n'.join(add) + b'\r\n'
for nid, (folder, _t, _s, tex, _r, _c) in MODEL.items():
    for t in tex:
        assert (B.join(['retail', folder, '%s%d.blp' % (folder, t)])).encode() in csv_new
        assert os.path.isfile(J(M, 'd', 'retail_%s_%s%d.blp' % (folder, folder, t)))

# ------------------------------------------------------------------ creatures
f = lambda v: float(v.strip("'"))
spawn = {}
for c in R['creature']:
    spawn.setdefault(int(c['id']), []).append((f(c['position_x']), f(c['position_y']), f(c['position_z']), f(c['orientation']), c.get('PhaseId', '0').strip("'")))
q = lambda s: "'" + s.replace(chr(92), chr(92) * 2).replace("'", "''") + "'"
# entry: (name, sub, min, max, faction, npcflag, rank, unit_class, unit_flags, type, hp, dmg, display, scale, wander, label)
C = {
    245090: ("Hagar 哈加尔", 'Elder 长者', 10, 10, 35, 3, 0, 1, 512, 7, 3, 1, 1542, 1, 0),
    245102: ("Dalnir 戴尼尔", 'Root Tender 根须照料者', 10, 10, 35, 3, 0, 1, 512, 7, 3, 1, 2261, 1, 0),
    245879: ("Orweyna 奥威娜", '', 10, 10, 35, 3, 0, 1, 512, 7, 3, 1, 710106, 1, 0),
    245881: ("Orweyna 奥威娜", '', 10, 10, 35, 3, 0, 1, 512, 7, 3, 1, 710106, 1, 0),
    245096: ("Hagar 哈加尔", 'Elder 长者', 10, 10, 35, 3, 0, 1, 512, 7, 3, 1, 1542, 1, 0),
    245097: ("Hagar 哈加尔", 'Elder 长者', 10, 10, 35, 3, 0, 1, 512, 7, 3, 1, 1542, 1, 0),
    246705: ("Dalnir 戴尼尔", 'Root Tender 根须照料者', 10, 10, 35, 1, 0, 1, 512, 7, 3, 1, 2261, 1, 0),
    245104: ("Alton Parsons 奥尔顿·帕森斯", 'Outsider 外来者', 5, 5, 35, 1, 0, 1, 768, 7, 5, 1, 1943, 1, 0),
    245118: ("Invasive Drifter 入侵的漂流者", '', 1, 1, 7, 0, 0, 1, 0, 1, 1, 0.5, 710101, 1, 4),
    245117: ("Pesky Sludger 讨厌的跃泥鱼", '', 2, 2, 7, 0, 0, 1, 0, 1, 1, 0.5, 710102, 0.7, 5),
    246277: ("Withered Plant 枯萎的植物", 'Pull it 点击拔除', 1, 1, 35, 1, 0, 1, 768, 10, 1, 0, 710103, 1, 0),
    248669: ("Withered Lasher 枯萎的鞭笞者", '', 2, 3, 7, 0, 0, 1, 0, 4, 1, 0.5, 710104, 0.7, 5),
    245114: ("Vicious Saptor 凶狠的迅叶龙", '', 3, 3, 14, 0, 0, 1, 0, 1, 2.5, 0.7, 710105, 1.2, 3),
    247257: ("Outsider Found 找到外来者", '', 1, 1, 35, 0, 0, 1, 768, 10, 1, 1, 11686, 1, 0),
    246360: ("Outsider Directed to Safety 外来者脱险", '', 1, 1, 35, 0, 0, 1, 768, 10, 1, 1, 11686, 1, 0),
    253478: ("Dalnir Met 会见戴尼尔", '', 1, 1, 35, 0, 0, 1, 768, 10, 1, 1, 11686, 1, 0),
}
NEW = sorted(C)
used = [r['entry'] for r in rows('creature_template') if int(r['entry']) in C]
assert not used, used
GOLD = {245118: (2, 6), 245117: (2, 8), 248669: (3, 9), 245114: (15, 40)}
LOOTSRC = {245118: 150228, 245117: 150228, 248669: 160433, 245114: 151091}
place = []      # (entry, x, y, z, o, wander, label)


def one(entry, phase=None, idx=0):
    L = [s for s in spawn[entry] if phase is None or s[4] == phase]
    x, y, z, o, _p = L[idx]
    place.append((entry, x, y, z, o, 0))


one(245090, '45843')
one(245102)
one(245879, '45845')
one(245881, '45847')
one(245096, '45847')
one(245097, '45851')
one(246705, '0') if any(s[4] == '0' for s in spawn[246705]) else one(246705)
place[-1] = (246705,) + (1174.2, 1004.4, 1341.2, 4.0, 0)
one(245104, '45846')
for x, y, z, o, ph in spawn[245118]:
    t = height(12694, x, y)
    if ph == '45843' and z - t <= 9:
        place.append((245118, x, y, round(t + 2.0, 2), o, 4))
for e, w in ((245117, 5), (246277, 0), (248669, 5), (245114, 3)):
    for x, y, z, o, _ph in spawn[e]:
        place.append((e, x, y, z, o, w))
counts = {e: sum(1 for p in place if p[0] == e) for e in (245118, 245117, 246277, 248669, 245114)}
print('spawns', len(place), counts)
assert counts[245118] >= 8 and counts[245117] >= 8 and counts[246277] >= 6 and counts[248669] >= 8

# ------------------------------------------------------------------ objects: click stones and fungi (clones of the verified click row 9350803)
GOS = {553763: (u'Invasive Fungi 入侵真菌', 6432, 90958, 1, 1.0),
       554679: (u'Legacy Stone of True Self 真我传承石', 235, 90960, 0, 2.0),
       546728: (u'Legacy Stone of True Calling 使命传承石', 235, 90960, 0, 2.0),
       554848: (u'Legacy Stone of the Goddess 女神指引传承石', 235, 90960, 0, 2.0),
       554966: (u'Paint Your Legacy Stone 绘制你的传承石', 235, 90960, 0, 1.6)}
assert not [r['entry'] for r in rows('gameobject_template') if int(r['entry']) in GOS]
gspawn = [(553763, f(g['position_x']), f(g['position_y']), f(g['position_z'])) for g in R['gameobject'] if g['id'] == '553763']
gspawn += [(554679, 1100.3, 1033.9, 1339.5), (546728, 1144.6, 1060.0, 1321.0), (554848, 1144.5, 1129.2, 1312.0), (554966, 1137.6, 1166.3, 1311.7)]
assert sum(1 for g in gspawn if g[0] == 553763) >= 6

# ------------------------------------------------------------------ quests
QU = {
    90957: dict(t=u"Initiation Day 入门之日", diff=5, money=60, prev=0, start=245090, end=245102,
                log=u"Kill 6 Invasive Drifters around the roots, then meet Root Tender Dalnir. / 在根须周围消灭6只入侵的漂流者，然后去找根须照料者戴尼尔。",
                desc=u"$N, today is when you find your proper place among the haranir. Root Tender Dalnir will guide you. By the end of the day you will make your mark in the Den of Remembrance.$B$BDalnir was clearing invasive drifters from the roots. Before you go to him, help by removing some of the pests yourself.$B$B$N，今天是你在哈籁尼尔族人中找到自己位置的日子。根须照料者戴尼尔会指引你，今天结束时你将在铭记之穴留下自己的印记。$B$B戴尼尔正在清理根须上的漂流者。去见他之前，先动手清掉一些。",
                done=u"Meet Dalnir in Har'mara. / 去哈尔玛拉找戴尼尔。",
                offer=u"Good. The roots breathe easier already.$B$B很好，根须已经舒展多了。",
                req=u"The drifters are still there. / 漂流者还没清干净。",
                obj=[(245118, 6, u"Invasive Drifter slain 消灭入侵的漂流者")], choice=[]),
    90958: dict(t=u"Roots Above All 根须至上", diff=6, money=100, prev=90957, start=245102, end=245102,
                log=u"Remove lashers, sludgers, withered plants and invasive fungi. / 清除鞭笞者、跃泥鱼、枯萎植物和入侵真菌。",
                desc=u"Some say the great trees grow and Harandar will remain even if we do not tend them. Our traditions say it does not matter. We remain here to protect, tend and serve.$B$BKeeping the ground around the roots free of pests reflects this duty. Return to me once you are done.$B$B有人说巨树自会生长，就算无人照料哈籁恩达尔也会长存。我们的传统说这并不重要：我们留在这里，就是为了守护、照料和服侍。$B$B让根须周围远离害虫，就是这份责任。办完回来找我。",
                done=u"Return to Dalnir. / 回去找戴尼尔。",
                offer=u"You represent our ways well, $N.$B$B$N，你很好地践行了我们的传统。",
                req=u"The roots still suffer. / 根须还在受害。",
                obj=[(248669, 8, u"Withered Lasher slain 消灭枯萎的鞭笞者"), (245117, 8, u"Pesky Sludger slain 消灭跃泥鱼"), (246277, 6, u"Withered Plant pulled 拔除枯萎植物"), (-553763, 6, u"Invasive Fungi removed 清除入侵真菌")],
                choice=[3274, 4906, 2691]),
    90959: dict(t=u"Traditional Duties 传统职责", diff=6, money=150, prev=90958, start=245879, end=245881,
                log=u"Search for the outsider in Har'mara, get them to safety, meet Dalnir at the Den. / 在哈尔玛拉寻找那位外来者，让他脱险，再到铭记之穴见戴尼尔。",
                desc=u"Dalnir has a point about the ceremony, but we should not focus too narrowly. Sometimes we must look beyond.$B$BAn outsider was seen to the south west. Find them before the saptors do.$B$B戴尼尔对仪式的看法有道理，但我们不能只盯着眼前，有时也要看向外面。$B$B有人在西南方看到一位外来者，赶在迅叶龙之前找到他。",
                done=u"Return to Orweyna outside the Den of Remembrance. / 回到铭记之穴外找奥威娜。",
                offer=u"You did more than tradition asked. Thank you.$B$B你做的超出了传统的要求，谢谢你。",
                req=u"Have you found the outsider? / 找到外来者了吗？",
                obj=[(247257, 1, u"Outsider found 找到外来者"), (245114, 1, u"Vicious Saptor slain 击杀凶狠的迅叶龙"), (246360, 1, u"Outsider directed to safety 外来者脱险"), (253478, 1, u"Dalnir met at the Den 在铭记之穴见戴尼尔")],
                choice=[12299, 24142, 24141]),
    90960: dict(t=u"My Story, My Legacy 我的故事，我的传承", diff=6, money=300, prev=90959, start=245096, end=245097,
                log=u"Commune with the three legacy stones, then paint your own story. / 与三座传承石交感，然后绘下你自己的故事。",
                desc=u"$N, the final part of the ceremony is ahead of you.$B$BThe first stone shows a vision of your true self. The second shows where you are needed. The third breaks the barrier between us and the Goddess herself. The ceremony ends with you painting your story in the Den.$B$B$N，仪式的最后一段在等着你。$B$B第一块石头让你看见真正的自我，第二块告诉你何处需要你，第三块打破我们与女神之间的隔阂。最后，你要在洞穴里绘下自己的故事。",
                done=u"Speak with Hagar deep in the Den. / 到洞穴深处找哈加尔。",
                offer=u"Your story is painted beside those who came before. Walk it well.$B$B你的故事已经画在先人们旁边了。好好走下去。",
                req=u"The stones are waiting. / 石头在等你。",
                obj=[(-554679, 1, u"True Self witnessed 见到真我"), (-546728, 1, u"True Calling witnessed 见到使命"), (-554848, 1, u"Goddess Guidance received 得到女神指引"), (-554966, 1, u"Legacy stone painted 绘制传承石")],
                choice=[20839, 20835, 20838, 20836, 20840, 5579]),
}
assert not [r['ID'] for r in rows('quest_template') if int(r['ID']) in QU]
items = {int(r['entry']) for r in rows('item_template')}
for v in QU.values():
    assert all(i in items for i in v['choice'])

# ------------------------------------------------------------------ SQL
IDL = ', '.join(map(str, NEW))
GL = ', '.join(map(str, GOS))
QL = ', '.join(map(str, QU))
sql = [u'''-- HARA2 V1 (2026-11-26, Claude) - candidate, NOT user-tested. Stop worldserver, run on the WORLD database, restart. Safe to run twice.
-- Needs: MAPSRV2A (map 12694), the click row 9350803 (island packages) and, for mob drops, LOOT1A V2 rows.
SET NAMES utf8mb4;
SET @spawn_limit := 16777215;
SELECT COUNT(*) AS click_template_9350803_must_be_1 FROM `gameobject_template` WHERE `entry` = 9350803;
DELETE FROM `creature` WHERE `map` = 12694 AND (`Comment` LIKE 'HARA2 %%');
DELETE FROM `gameobject` WHERE `map` = 12694 AND (`Comment` LIKE 'HARA2 %%');
DELETE FROM `creature_template` WHERE `entry` IN (%(c)s);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (%(c)s);
DELETE FROM `creature_template_movement` WHERE `CreatureId` IN (%(c)s);
DELETE FROM `creature_loot_template` WHERE `Comment` LIKE 'HARA2 %%';
DELETE FROM `creature_model_info` WHERE `DisplayID` BETWEEN 710101 AND 710106;
DELETE FROM `gameobject_template` WHERE `entry` IN (%(g)s);
DELETE FROM `gameobject_template_addon` WHERE `entry` IN (%(g)s);
DELETE FROM `quest_template` WHERE `ID` IN (%(q)s);
DELETE FROM `quest_template_addon` WHERE `ID` IN (%(q)s);
DELETE FROM `quest_offer_reward` WHERE `ID` IN (%(q)s);
DELETE FROM `quest_request_items` WHERE `ID` IN (%(q)s);
DELETE FROM `quest_poi` WHERE `QuestID` IN (%(q)s);
DELETE FROM `quest_poi_points` WHERE `QuestID` IN (%(q)s);
DELETE FROM `creature_queststarter` WHERE `quest` IN (%(q)s);
DELETE FROM `creature_questender` WHERE `quest` IN (%(q)s);
SELECT COALESCE(MAX(`guid`), 0) INTO @g FROM `creature` WHERE `guid` < @spawn_limit;
SELECT COALESCE(MAX(`guid`), 0) INTO @o FROM `gameobject` WHERE `guid` < @spawn_limit;
SELECT IF(@g + 200 + 10000 < @spawn_limit AND @o + 40 + 10000 < @spawn_limit, 'guid base OK', 'ABORT: no guid room, do not continue') AS guid_check, @g AS creature_max, @o AS go_max;''' % dict(c=IDL, g=GL, q=QL)]
cols = '`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `unit_class`, `unit_flags`, `type`, `AIName`, `MovementType`, `HealthModifier`, `DamageModifier`, `ExperienceModifier`, `RegenHealth`, `flags_extra`, `ScriptName`, `mingold`, `maxgold`'
vals, mods = [], []
for e in NEW:
    name, sub, lo, hi, fac, npcf, rank, ucls, uf, typ, hp, dmg, disp, scale, wander = C[e]
    g = GOLD.get(e, (0, 0))
    vals.append(u"(%d, %s, %s, %d, %d, %d, %d, 1, 1.14286, %d, %d, %d, %d, '', %d, %s, %s, 2, 1, %d, '', %d, %d)" % (
        e, q(name), q(sub) if sub else 'NULL', lo, hi, fac, npcf, rank, ucls, uf, typ, 1 if wander else 0, hp, dmg, 0 if e in GOLD else 2, g[0], g[1]))
    mods.append('(%d, 0, %d, %s, 1, 0)' % (e, disp, scale))
sql.append(u'INSERT INTO `creature_template` (%s) VALUES\n%s;' % (cols, ',\n'.join(vals)))
sql.append('INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES\n%s;' % ',\n'.join(mods))
sql.append('INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`, `Chase`, `Random`, `InteractionPauseTimer`) VALUES (245118, 1, 0, 1, 0, 0, 0, 0), (246277, 1, 0, 0, 1, 0, 0, 0);')
sql += ['INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`) VALUES (%d, %s, %s, 2, 0);' % (i, MODEL[i][4], MODEL[i][5]) for i in sorted(MODEL)]
sql.append(u'\n-- drops: copies of the accepted island drop rows (money is set on the templates above)')
for e, s in sorted(LOOTSRC.items()):
    sql.append('''INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)
SELECT %d, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, 'HARA2 copy of %d' FROM `creature_loot_template` WHERE `Entry` = %d AND `Comment` LIKE 'LOOT1A %%' AND `QuestRequired` = 0;
UPDATE `creature_template` SET `lootid` = %d WHERE `entry` = %d AND EXISTS (SELECT 1 FROM `creature_loot_template` WHERE `Entry` = %d);''' % (e, s, s, e, e, e))
cins = 'INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES'
sp = []
for i, (e, x, y, z, o, w) in enumerate(place, 1):
    sp.append("(@g + %d, %d, 12694, 1, 1, 0, %.2f, %.2f, %.2f, %.2f, %d, %d, %d, 'HARA2 %d')" % (i, e, x, y, z, o, 40 if e in GOLD or e == 246277 else 120, w, 1 if w else 0, e))
sql.append(cins + '\n' + ',\n'.join(sp) + ';')
mentors = [(c, 9180200 + c) for c in (1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 13, 14, 15)]
mz = round(height(12694, 1254.0, 930.0) + 0.1, 2)
sql.append(u'-- class mentors (TRAINER1A V3 templates): every player sees only the mentor of his own class')
for i, (c, e) in enumerate(mentors, len(place) + 1):
    sql.append("%s\n" % cins.replace(' VALUES', '') + "SELECT @g + %d, %d, 12694, 1, 3, 0, 1254.0, 930.0, %.2f, 5.6, 120, 0, 0, 'HARA2 mentor %d' FROM `creature_default_trainer` WHERE `CreatureId` = %d;" % (i, e, mz, c, e))
for k, (e, (name, disp, quest, consumable, size)) in enumerate(sorted(GOS.items())):
    sql.append(u'''DROP TEMPORARY TABLE IF EXISTS tmp_go;
CREATE TEMPORARY TABLE tmp_go AS SELECT * FROM `gameobject_template` WHERE `entry` = 9350803;
UPDATE tmp_go SET `entry` = %d, `name` = %s, `displayId` = %d, `size` = %s, `Data1` = %d, `Data5` = %d;
INSERT INTO `gameobject_template` SELECT * FROM tmp_go;
DROP TEMPORARY TABLE tmp_go;''' % (e, q(name), disp, size, quest, consumable))
sql.append('INSERT INTO `gameobject_template_addon` (`entry`, `faction`, `flags`) VALUES %s;' % ', '.join('(%d, 0, 0)' % e for e in sorted(GOS)))
gins = 'INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `Comment`) VALUES'
sql.append(gins + '\n' + ',\n'.join("(@o + %d, %d, 12694, 1, 1, %.2f, %.2f, %.2f, 0, 0, 0, 0, 1, 30, 100, 1, 'HARA2 %d')" % (i, e, x, y, z, e) for i, (e, x, y, z) in enumerate(gspawn, 1)) + ';')
for qid, v in sorted(QU.items()):
    obj = v['obj'] + [(0, 0, '')] * (4 - len(v['obj']))
    ch = v['choice'] + [0] * (6 - len(v['choice']))
    names = ['ID', 'QuestType', 'QuestLevel', 'MinLevel', 'AllowableRaces', 'RewardXPDifficulty', 'RewardMoney', 'Flags', 'LogTitle', 'LogDescription', 'QuestDescription', 'QuestCompletionLog']
    data = [qid, 2, -1, 1, 0, v['diff'], v['money'], 0, q(v['t']), q(v['log']), q(v['desc']), q(v['done'])]
    for i in range(4):
        names += ['RequiredNpcOrGo%d' % (i + 1), 'RequiredNpcOrGoCount%d' % (i + 1), 'ObjectiveText%d' % (i + 1)]
        data += [obj[i][0], obj[i][1], q(obj[i][2])]
    for i in range(6):
        names += ['RewardChoiceItemID%d' % (i + 1), 'RewardChoiceItemQuantity%d' % (i + 1)]
        data += [ch[i], 1 if ch[i] else 0]
    sql.append(u'INSERT INTO `quest_template` (%s) VALUES\n(%s);' % (', '.join('`%s`' % n for n in names), ', '.join(map(str, data))))
    sql.append('INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`) VALUES (%d, %d);' % (qid, v['prev']))
    sql.append(u'INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `RewardText`, `VerifiedBuild`) VALUES (%d, 1, %s, 0);' % (qid, q(v['offer'])))
    sql.append(u'INSERT INTO `quest_request_items` (`ID`, `CompletionText`, `VerifiedBuild`) VALUES (%d, %s, 0);' % (qid, q(v['req'])))
    sql.append('INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (%d, %d);\nINSERT INTO `creature_questender` (`id`, `quest`) VALUES (%d, %d);' % (v['start'], qid, v['end'], qid))
# map markers: one area per objective from the first matching spawn, plus the turn-in
pos = {}
for e, x, y, z, o, w in place:
    pos.setdefault(e, []).append((x, y))
for e, x, y, z in gspawn:
    pos.setdefault(-e, []).append((x, y))
for e, alias in ((247257, 245104), (246360, 245104), (253478, 246705)):
    pos[e] = pos[alias]
poi, pts = [], []
for qid, v in sorted(QU.items()):
    marks = [(i, pos[o[0]]) for i, o in enumerate(v['obj'])] + [(-1, pos[v['end']])]
    for k, (obj_i, L) in enumerate(marks):
        cx = sum(a for a, b in L) / len(L)
        cy = sum(b for a, b in L) / len(L)
        r = max(8.0, min(60.0, max(math.hypot(a - cx, b - cy) for a, b in L)))
        poi.append('(%d, %d, %d, 12694, 20418, 0, 0, %d, 0)' % (qid, k, obj_i, 1))
        for j, (dx, dy) in enumerate(((-r, -r), (r, -r), (r, r), (-r, r))):
            pts.append('(%d, %d, %d, %d, %d, 0)' % (qid, k, j, round(cx + dx), round(cy + dy)))
sql.append('INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`) VALUES\n%s;' % ',\n'.join(poi))
sql.append('INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES\n%s;' % ',\n'.join(pts))
sql.append(u'''SELECT (SELECT COUNT(*) FROM `quest_template` WHERE `ID` IN (%(q)s)) AS quests_must_be_4,
       (SELECT COUNT(*) FROM `creature_template` WHERE `entry` IN (%(c)s)) AS creature_templates_must_be_%(nc)d,
       (SELECT COUNT(*) FROM `creature` WHERE `Comment` LIKE 'HARA2 %%' AND `Comment` NOT LIKE 'HARA2 mentor%%') AS creature_spawns_must_be_%(ns)d,
       (SELECT COUNT(*) FROM `creature` WHERE `Comment` LIKE 'HARA2 mentor%%') AS mentor_spawns_expect_10_or_more,
       (SELECT COUNT(*) FROM `gameobject_template` WHERE `entry` IN (%(g)s)) AS object_templates_must_be_5,
       (SELECT COUNT(*) FROM `gameobject` WHERE `Comment` LIKE 'HARA2 %%') AS object_spawns_must_be_%(ng)d,
       (SELECT COUNT(*) FROM `creature_model_info` WHERE `DisplayID` BETWEEN 710101 AND 710106) AS model_info_must_be_6,
       (SELECT COUNT(DISTINCT `Entry`) FROM `creature_loot_template` WHERE `Comment` LIKE 'HARA2 %%') AS mobs_with_drops_expect_4;''' % dict(q=QL, c=IDL, g=GL, nc=len(NEW), ns=len(place), ng=len(gspawn)))
sql = '\n'.join(sql)
undo = '\n'.join(sql.split('SELECT COALESCE(MAX(`guid`)')[0].splitlines()[2:]).replace("SELECT COUNT(*) AS click_template_9350803_must_be_1 FROM `gameobject_template` WHERE `entry` = 9350803;\n", '')
undo = '-- HARA2 V1 undo (world database). Remove lua_scripts/Hara2.lua too.\n' + undo.replace('SET @spawn_limit := 16777215;\n', '')

# ------------------------------------------------------------------ package


def wr(rel, data):
    p = J(P, rel.replace('/', B))
    os.makedirs(os.path.dirname(p), exist_ok=True)
    assert not os.path.exists(p), p
    if isinstance(data, str):
        data = data.strip('\n').replace('\n', '\r\n').encode('utf-8-sig' if rel.endswith('.md') else 'utf-8') + b'\r\n'
    assert data.strip()
    open(p, 'wb').write(data)


hashes = []
for n, (old, new) in client.items():
    wr(u'01_导入Patch-YB.mpq/DBFilesClient/' + n, new)
    wr(u'06_撤销/原Patch-YB/DBFilesClient/' + n, old)
    hashes.append((u'客户端 YB ' + n, sha(old), sha(new)))
wr(u'02_覆盖到客户端根目录/Data/Retail/aliases_maps.csv', csv_new)
wr(u'06_撤销/原客户端根目录/Data/Retail/aliases_maps.csv', csv_old)
hashes.append((u'客户端 aliases_maps.csv', sha(csv_old), sha(csv_new)))
for n, (old, new) in server.items():
    wr(u'03_服务端_Data_dbc/' + n, new)
    wr(u'06_撤销/原服务端dbc/' + n, old)
    hashes.append((u'服务端 ' + n, sha(old), sha(new)))
wr(u'04_服务端_SQL/world_hara2.sql', sql)
wr(u'05_服务端脚本_覆盖到lua_scripts/Hara2.lua', open(J(H, 'Hara2.lua'), 'rb').read())
wr(u'06_撤销/undo_hara2.sql', undo)
table = '\n'.join(u'| %s | `%s` | `%s` |' % (h[0], h[1][:12], h[2][:12]) for h in hashes)
wr(u'README_覆盖与测试说明.md', u'''
# HARA2 V1：哈籁尼尔出生任务 1–4（候选，实机未测）

前提：MAPSRV2A、HARA1C 已装(地图已确认可以)；流放者之岛的点击物体模板 9350803 和掉落(LOOT1A V2)在库里。

## 内容
| 任务 | 接 → 交 | 目标 | 奖励 |
|---|---|---|---|
| 90957 入门之日 | 哈加尔 → 戴尼尔 | 漂流者 6 | 铜币、经验 |
| 90958 根须至上 | 戴尼尔 → 戴尼尔 | 鞭笞者 8、跃泥鱼 8、拔枯萎植物 6、清真菌 6 | 靴子三选一(布/皮/锁) |
| 90959 传统职责 | 奥威娜 → 奥威娜 | 找到外来者、杀迅叶龙、让他脱险、见戴尼尔 | 手套三选一 |
| 90960 我的故事，我的传承 | 哈加尔 → 洞穴深处哈加尔 | 三块传承石 + 绘制 | 武器六选一 |

- 怪物 1–3 级，漂流者、跃泥鱼、鞭笞者是黄名(不主动打你)，迅叶龙红名。
- **原版模型**：漂流者、跃泥鱼、枯萎植物、鞭笞者、迅叶龙、奥威娜。
- **替身外观**：哈加尔、戴尼尔(零售是定制人形，用现成暗夜精灵)、奥尔顿(用现成人类)；传承石和真菌用现成物体外观。
- 怪物掉铜币、杂物和初始装备(复制流放者之岛已通过的掉落)。
- 出生点旁放了职业导师(和流放者之岛同一套，每人只看到自己职业的)。
- 任务文本中英双语：前两句描述按零售改写，交任务对白是我补的(零售数据里没有)。

## 部署(关游戏、停服)
1. 备份 `Data\\Patch-YB.mpq`、`Data\\Retail\\aliases_maps.csv`、服务端两个生物 dbc。核对下表"输入"哈希，不相等说明有人改过，先告诉我。
2. `01_导入Patch-YB.mpq` 的两个 dbc 导入 Patch-YB；`02_覆盖到客户端根目录` 覆盖到客户端根目录。
3. `03_服务端_Data_dbc` 覆盖服务端 `Data\\dbc`。
4. world 库执行 `04_服务端_SQL\\world_hara2.sql`。开头 `guid base OK`、`click_template…`=1；末尾按列名对读回值(`mobs_with_drops` 应是 4，`mentor_spawns` 至少 10)。
5. `05_服务端脚本_覆盖到lua_scripts\\Hara2.lua` 放进 `lua_scripts`。启动后控制台应有 `[Hara2] HARA2 V1 loaded`。
6. 删客户端 `Cache\\WDB`。

| 文件 | 输入 | 输出 |
|---|---|---|
%(t)s

## 测试路线(建一个新的联盟 1 级角色，建议哈籁尼尔)
1. `.tele Haranir`(建角时直接出生在这里由 Codex 做，暂时用传送)。`.gm off`。
2. 旁边应有哈加尔(头上叹号)和你的职业导师。接 90957，向南打漂流者，向东找戴尼尔交。
3. 90958：营地南侧打怪、点枯萎植物和真菌，回戴尼尔。接 90959(戴尼尔旁的奥威娜)。
4. 90959：往西南找奥尔顿，对话 → 杀迅叶龙 → 再对话 → 回铭记之穴外和戴尼尔对话 → 交奥威娜。
5. 90960(哈加尔，奥威娜旁)：往西北进洞穴，依次点三块传承石、绘制石，向洞穴深处的哈加尔交。

| 重点看 | |
|---|---|
| 怪物模型 | 有贴图、会动，不是白模/绿色/看不见；漂流者飞得高度打得到 |
| 地面 | NPC、怪、石头没有悬空或陷进地里，**洞穴里**尤其注意 |
| 任务计数 | 四个任务每个目标都能涨满 |
| 经验和强度 | 做完大约几级；1 级打不打得过 |
| 地图标记 | 按 M 能否看到任务区域 |

坐标备用(`.go xyz … 12694`)：出生 `1263 923 1332`，戴尼尔 `1349 908 1345`，奥尔顿 `1115 883 1346`，洞穴口一带 `1100 1034 1340`，洞穴深处 `1149 1166 1310`。

## 撤销
执行 `06_撤销\\undo_hara2.sql`，删 `Hara2.lua`，换回 `06_撤销` 里的 dbc、csv，重启。

## 未做与边界
- 全部未实机测试(SQL、脚本只做过离线模拟，模型只做过离线姿势渲染)。
- 开场演出、传承石的幻象画面没有做，用点击代替。
- 任务 5–15 和最后传送暴风城在下一批。
- 怪物没有特殊技能；声音借用现成生物。
''' % dict(t=table))
wr(u'memory.md', u'''
# HARA2 V1 记录(2026-11-26，Claude)
用户："地图可以了 开始帮我按照你设计的任务系统 开始吧"。零售任务 90957-90960，生物保留零售编号；模型 710101-710106(漂流者5884375、跃泥鱼5140780、植物5334283、鞭笞者1722688、迅叶龙5884349、奥威娜5633401)。
脚本 D:\\_zsdc\\hara(ex.py 提取、models/conv.py、build_hara2.py)。状态：候选，未实测。''')
wr(u'tutor.md', u'''
# 大白话：先搬原版四课
任务、人、怪、石头四样一起搬。能照原样搬的模型照原样搬，定制的人形先找替身并写清楚。零售的演出画面搬不过来，就换成"点一下"。''')
lines = []
for dp, _d, fn in os.walk(P):
    for fl in fn:
        p = J(dp, fl)
        lines.append('%s  %s' % (sha(open(p, 'rb').read()), os.path.relpath(p, P).replace(B, '/')))
wr('SHA256SUMS.txt', '\n'.join(sorted(lines, key=lambda s: s[66:])).encode('utf-8') + b'\n')

# ------------------------------------------------------------------ simulate the SQL
db = sqlite3.connect(':memory:')
db.create_function('IF', 3, lambda a, b, c: b if a else c)


def mk(t):
    cs = []
    on = False
    for line in open(J(r'D:\000rebornWOW\000RebornWOWHighForkPRO\beascendcode\claude-release-20261126\data\sql\base\db_world', t + '.sql'), encoding='utf-8', errors='replace'):
        if line.startswith('CREATE TABLE `%s`' % t):
            on = True
        elif on and line.startswith(')'):
            break
        elif on and line.strip().startswith('`'):
            cs.append(line.strip().split('`')[1])
    db.execute('create table %s (%s)' % (t, ','.join('"%s"' % c for c in cs)))
    return cs


tables = ['creature', 'gameobject', 'creature_template', 'creature_template_model', 'creature_template_movement', 'creature_loot_template', 'creature_model_info', 'gameobject_template', 'gameobject_template_addon',
          'quest_template', 'quest_template_addon', 'quest_offer_reward', 'quest_request_items', 'quest_poi', 'quest_poi_points', 'creature_queststarter', 'creature_questender', 'creature_default_trainer']
schema = {t: mk(t) for t in tables}
if 'Comment' not in schema['creature']:
    db.execute('alter table creature add column "Comment"')
if 'Comment' not in schema['gameobject']:
    db.execute('alter table gameobject add column "Comment"')
db.execute('insert into gameobject_template(entry, type) values (9350803, 10)')
for c in (1, 2, 3, 4, 5, 6, 7, 8, 9, 11):
    db.execute('insert into creature_default_trainer(CreatureId, TrainerId) values (?, ?)', (9180200 + c, 901800 + c))
for s in sorted(set(LOOTSRC.values())):
    db.execute("insert into creature_loot_template(Entry, Item, Reference, Chance, QuestRequired, LootMode, GroupId, MinCount, MaxCount, Comment) values (?, 779, 0, 20, 0, 1, 0, 1, 1, 'LOOT1A x')", (s,))


def run(text, show):
    var = {}
    t = '\n'.join(l for l in text.splitlines() if not l.lstrip().startswith('--'))
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
        m_ = re.match(r'SET @(\w+) := (\d+)$', s)
        if m_:
            var[m_[1]] = m_[2]
            continue
        into = re.search(r' INTO @(\w+)', s) if s.startswith('SELECT') else None
        if into:
            s = s.replace(into[0], '')
        s = re.sub(r'@(\w+)', lambda m_: str(var.get(m_[1], m_[0])), s)
        s = s.replace('DROP TEMPORARY TABLE', 'DROP TABLE')
        c = db.execute(s)
        if into:
            var[into[1]] = c.fetchone()[0]
        elif s.startswith('SELECT') and show:
            n_ = [d[0] for d in c.description]
            for r in c.fetchall():
                print('  ', dict(zip(n_, r)))


run(sql, True)
snap = [db.execute('select count(*) from %s' % t).fetchone()[0] for t in tables]
run(sql, False)
assert snap == [db.execute('select count(*) from %s' % t).fetchone()[0] for t in tables]
run(undo, False)
left = {t: db.execute('select count(*) from %s' % t).fetchone()[0] for t in tables}
print('after undo', {k: v for k, v in left.items() if v})

# ------------------------------------------------------------------ the script with stand-ins
from lupa.lua51 import LuaRuntime
L = LuaRuntime(unpack_returned_tuples=True)
L.execute('''H={} LOG={} CNT={}
function RegisterCreatureGossipEvent(e,ev,f) H[e]=f end
function P(has) return {GossipComplete=function() end,HasQuest=function(s,q) return has[q]==true end,GetReqKillOrCastCurrentCount=function(s,q,e) return CNT[e] or 0 end,
 KilledMonsterCredit=function(s,e) CNT[e]=(CNT[e] or 0)+1 LOG[#LOG+1]=e end,SendBroadcastMessage=function() end} end
C={DespawnOrUnsummon=function() end,SendUnitSay=function() end}''')
L.execute(open(J(H, 'Hara2.lua'), encoding='utf-8').read())
print(L.execute('''local p=P({[90958]=true,[90959]=true})
for i=1,9 do local r={H[246277](1,p,C)} assert(#r==0) end
H[245104](1,p,C) H[245104](1,p,C) H[246705](1,p,C) CNT[245114]=1 H[245104](1,p,C) H[245104](1,p,C) H[246705](1,p,C)
H[245104](1,P({}),C) H[246277](1,P({}),C)
return string.format("plant %d found %d safe %d met %d credits %d", CNT[246277], CNT[247257], CNT[246360], CNT[253478], #LOG)'''))


def app(path, text, key):
    t = open(path, 'rb').read()
    assert t.strip() and key.encode('utf-8') not in t, path
    e = '\r\n' if b'\r\n' in t else '\n'
    open(path, 'ab').write((('' if t.endswith(b'\n') else e) + e + text.replace('\n', e) + e).encode('utf-8'))


app(J(WS, u'协作说明_并行开发.md'), u'| 2026-11-26 | Claude | HARA2 V1：哈籁尼尔出生任务 90957-90960 | 候选(实机未测) | YB CreatureModelData/CreatureDisplayInfo +6(710101-710106)、aliases_maps.csv；服务端同名 DBC；world 生物 2451xx 等、物体 553763/554679/546728/554848/554966、任务 90957-90960；lua_scripts/Hara2.lua | 现场 YB 与服务端表为基底 | 000Ascendupdate20261126/claudefix_…HARA2… | Codex 改 YB 两张生物表前请以本包装后版本为底 |', u'HARA2 V1：哈籁尼尔')
app(J(WS, u'台账_YB_XA共享文件哈希.md'), u'## 2026-11-26 HARA2 V1(Claude，待用户安装)\n|文件|输入|输出|\n|---|---|---|\n' + '\n'.join(u'|%s|%s|%s|' % h for h in hashes), u'HARA2 V1(Claude')
MEM = r'<user-profile>\.claude\projects\d--000rebornWOW-000RebornWOWHighForkPRO-beascendLauncher-wowlauncher2026-CataLauncher-rebornWOW\memory\haranir-start-port.md'
s = open(MEM, encoding='utf-8').read()
assert s.strip()
open(MEM, 'w', encoding='utf-8').write(s + u'\n11-26: user confirmed maps OK ("地图看了 地图可以了") and asked to start quests. HARA2 V1 delivered (quests 90957-90960, retail models 710101-106), untested. MAPSRV2A + HARA1C accepted but not yet archived/released. Next batch HARA3 (new quests 5-10).\n')
print(P)
for h in hashes:
    print(h[0], h[1][:12], '->', h[2][:12])
