# -*- coding: utf-8 -*-
"""HARA3 V1: new Haranir quests 9190001-9190006, retail creature models, drops, rewards."""
import ctypes, struct, os, hashlib, shutil, io, sys, pickle, glob, re, sqlite3, math, csv, json, collections
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
B = chr(92)
J = os.path.join
WS = r'D:\000rebornWOW\000RebornWOWHighForkPRO'
DAY = J(WS, '000Ascendupdate', '000Ascendupdate20261126')
P = J(DAY, u'claudefix_20261126_阶段HARA3_V1_哈籁尼尔任务5到10_原版怪物模型掉落奖励_Claude')
assert not os.path.exists(P), P
CLIENT = r'C:\000ref\WarcraftXL试装_client'
SRVROOT = J(WS, 'beascendserver', 'wowshub_playerbot_npcbot_newrace20261122Ascend')
SRV = J(SRVROOT, 'Data', 'dbc')
H = r'D:\_zsdc\hara'
M = J(H, 'models3', 'd')
sha = lambda b: hashlib.sha256(b).hexdigest()
fb = lambda x: struct.unpack('<I', struct.pack('<f', x))[0]
exec(open(r'D:\_zsdc\cls\classq.py', encoding='utf-8').read().split("cls = {}")[0].replace("sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')", ''))
exec(open(r'D:\_zsdc\maps2\verify.py', encoding='utf-8').read().split('# retail creature positions')[0].replace("sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')\n", ''))
bsrc = open(r'D:\_zsdc\models4\build_model1a.py', encoding='utf-8').read()
exec(bsrc[bsrc.index('dll = ctypes.WinDLL'):bsrc.index('# id, folder, m2 file id')])      # client_table / parse / row_of / append
R = pickle.load(open(J(H, 'q510.pkl'), 'rb'))
BASEDIR = r'D:\000rebornWOW\000RebornWOWHighForkPRO\beascendcode\claude-release-20261126\data\sql\base\db_world'
u = lambda v: v.strip("'")
f = lambda v: float(u(v))


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


# ------------------------------------------------------------------ models and displays
# model data id -> (folder, template display for sounds); 710104 (lasher) already exists from HARA2
MODELDATA = {710111: ('HaraBud', 1092), 710112: ('HaraRotling', 1092), 710113: ('HaraLightbloom', 2261), 710114: ('HaraSwiftsting', 92)}
FOLDER = {710104: 'HaraLasher'}
FOLDER.update({k: v[0] for k, v in MODELDATA.items()})
# creature -> (model data id, retail displays, combat reach in yards, bounding radius in yards)
VIS = {237036: (710111, [118221, 118222, 118215, 118213], 1.2, 0.5),
       237623: (710112, [114561, 115184, 115185, 115186], 1.1, 0.5),
       240344: (710113, [127946], 1.6, 0.5),
       240656: (710113, [127944], 1.5, 0.4),
       240871: (710114, [108827, 108828, 108829, 108832], 1.0, 0.4),
       248493: (710104, [104472, 104473, 104476], 1.1, 0.5)}
G = r'D:\_zsdc\wago_item'
allret = {str(d) for v in VIS.values() for d in v[1]}
RCDI = {r['ID']: r for r in csv.DictReader(open(G + '/CreatureDisplayInfo.csv', encoding='utf-8-sig')) if r['ID'] in allret}
RGEO = collections.defaultdict(dict)
for r in csv.DictReader(open(r'D:\_zsdc\wago_geo\CreatureDisplayInfoGeosetData.csv', encoding='utf-8-sig')):
    if r['CreatureDisplayInfoID'] in allret:
        RGEO[r['CreatureDisplayInfoID']][int(r['GeosetIndex']) + 1] = int(r['GeosetValue'])
RSCALE = {(r['CreatureID'], r['CreatureDisplayID']): f(r['DisplayScale']) for r in R['creature_template_model']}


def parts_of(folder):
    m = open(J(M, 'retail_%s_%s.m2' % (folder, folder)), 'rb').read()
    sk = open(J(M, 'retail_%s_%s00.skin' % (folder, folder)), 'rb').read()
    nsub, osub = struct.unpack_from('<II', sk, 28)
    nbat, obat = struct.unpack_from('<II', sk, 36)
    lookup = struct.unpack_from('<I', m, 0x84)[0]
    texofs = struct.unpack_from('<I', m, 0x54)[0]
    ids = [struct.unpack_from('<H', sk, osub + 48 * s)[0] for s in range(nsub)]
    types = {}
    for b in range(nbat):
        q_ = obat + 24 * b
        sec = struct.unpack_from('<H', sk, q_ + 4)[0]
        cnt, combo = struct.unpack_from('<HH', sk, q_ + 14)
        for k in range(cnt):
            t = struct.unpack_from('<h', m, lookup + 2 * (combo + k))[0]
            types.setdefault(ids[sec], set()).add(struct.unpack_from('<I', m, texofs + 16 * t)[0])
    return ids, types


def box_of(folder):
    p = J(M, 'retail_%s_%s.m2' % (folder, folder))
    m = open(p, 'rb').read()
    nv, vo = struct.unpack_from('<II', m, 0x3c)
    vs = [struct.unpack_from('<3f', m, vo + 48 * i) for i in range(nv)]
    return [min(v[k] for v in vs) for k in range(3)] + [max(v[k] for v in vs) for k in range(3)]


DISPLAY = []      # (new display id, creature, model data id, retail display, cdi scale, textures, geoset value, template display)
nid = 710121
report = []
for entry, (mdid, rets, reach, rad) in sorted(VIS.items()):
    folder = FOLDER[mdid]
    ids, types = parts_of(folder)
    groups = sorted({s // 100 for s in ids if s // 100})
    for ret in rets:
        rr = RCDI[str(ret)]
        assert rr['ExtendedDisplayInfoID'] == '0'
        tex = [int(rr['TextureVariationFileDataID_%d' % k]) for k in range(3)]
        tex = [t for t in tex if t]
        geo = 0
        for g in groups:
            val = RGEO[str(ret)].get(g, 0xF)
            assert 0 < val <= 15 and g <= 8, (ret, g, val)
            geo |= val << (4 * (g - 1))
        shown = sorted({s for s in ids if s // 100 == 0 or ((geo >> (4 * (s // 100 - 1))) & 0xF) == 0 or s % 100 == ((geo >> (4 * (s // 100 - 1))) & 0xF)})
        gs = [s // 100 for s in shown if s]
        assert len(gs) == len(set(gs)), (ret, shown)
        need = {t for s in shown for t in types[s] if t}
        have = {11 + k for k in range(len(tex))}
        assert need <= have, (ret, need, have)
        report.append((nid, entry, ret, hex(geo), shown))
        DISPLAY.append((nid, entry, mdid, ret, f(rr['CreatureModelScale']), tex, geo, 1092 if mdid == 710104 else MODELDATA[mdid][1]))
        nid += 1
for r_ in report:
    print('display %d creature %d retail %d geo %s parts %s' % r_)


def build(read):
    md0, di0 = read('CreatureModelData.dbc'), read('CreatureDisplayInfo.dbc')
    assert row_of(md0, 710104) is not None, 'HARA2 tables are not installed'
    msb, dbase = parse(md0)[4], len(parse(di0)[4])
    mrows, drows, mstr, dstr = [], [], b'', b''
    for mid, (folder, tdisp) in sorted(MODELDATA.items()):
        assert row_of(md0, mid) is None
        tdr = row_of(di0, tdisp)
        mr = row_of(md0, tdr[1])
        assert mr is not None and len(mr) == 28, (mid, tdisp)
        mr[0], mr[2] = mid, len(msb) + len(mstr)
        mstr += (B.join(['retail', folder, folder]) + '.mdx').encode() + b'\0'
        mr[4] = fb(1.0)
        mr[14], mr[15], mr[16] = fb(0.611), fb(2.031), 0
        for i, v in zip(range(17, 23), box_of(folder)):
            mr[i] = fb(v)
        mrows.append(mr)
    for did, entry, mdid, ret, cscale, tex, geo, tdisp in DISPLAY:
        assert row_of(di0, did) is None
        dr = list(row_of(di0, tdisp))
        assert len(dr) == 16
        dr[0], dr[1] = did, mdid
        dr[3] = 0
        dr[4], dr[5] = fb(cscale), 255
        dr[6] = dr[7] = dr[8] = dr[9] = dr[13] = dr[14] = dr[15] = 0
        dr[14] = geo
        for k, t in enumerate(tex):
            dr[6 + k] = dbase + len(dstr)
            dstr += ('%s%d' % (FOLDER[mdid], t)).encode() + b'\0'
        drows.append(dr)
    return {'CreatureModelData.dbc': (md0, append(md0, mrows, mstr)), 'CreatureDisplayInfo.dbc': (di0, append(di0, drows, dstr))}


client = build(client_table)
server = build(lambda n: open(J(SRV, n), 'rb').read())
csv_old = open(J(CLIENT, 'Data', 'Retail', 'aliases_maps.csv'), 'rb').read()
assert b'HaraLasher' in csv_old, 'HARA2 aliases are not installed'
have = {x.split(b';')[0]: x.split(b';', 1)[1].lower() for x in csv_old.split() if b';' in x}
add = []
for line in open(J(H, 'models3', 'aliases_maps.csv'), 'rb').read().split():
    fdid, path = line.split(b';', 1)
    if fdid in have:
        assert have[fdid] == path.lower(), (line, have[fdid])
    else:
        add.append(line)
csv_new = csv_old + (b'' if csv_old.endswith(b'\n') else b'\r\n') + b'\r\n'.join(add) + b'\r\n'
for did, entry, mdid, ret, cscale, tex, geo, tdisp in DISPLAY:
    folder = FOLDER[mdid]
    for t in tex:
        assert (B.join(['retail', folder, '%s%d.blp' % (folder, t)])).encode().lower() in csv_new.lower(), (folder, t)
        assert os.path.isfile(J(M, 'retail_%s_%s%d.blp' % (folder, folder, t))), (folder, t)
print('aliases added', len(add))

# ------------------------------------------------------------------ spawn layout
hara2 = glob.glob(DAY + B + u'claudefix_*HARA2_V1_*')[0]
old_sql = open(J(hara2, u'04_服务端_SQL', 'world_hara2.sql'), encoding='utf-8').read()
taken = [(float(a), float(b)) for a, b in re.findall(r"\(@g \+ \d+, \d+, 12694, 1, 1, 0, ([\d.-]+), ([\d.-]+),", old_sql)]
assert len(taken) > 50
NPCS = [(1149.0, 1167.0), (1349.0, 908.0), (1339.0, 905.0), (1263.0, 923.0), (1254.0, 930.0)]
clear = lambda x, y: all(math.hypot(x - a, y - b) >= 3.5 for a, b in taken) and all(math.hypot(x - a, y - b) >= 8 for a, b in NPCS)
h = lambda x, y: height(12694, x, y)


def near(x, y, z, radii):
    h0 = h(x, y)
    for rad in radii:
        for k in range(12):
            a = k * math.pi / 6 + rad
            nx, ny = x + rad * math.cos(a), y + rad * math.sin(a)
            h1 = h(nx, ny)
            if abs(h1 - h0) <= 1.2 and clear(nx, ny):
                return nx, ny, max(h1 + 0.1, z + (h1 - h0))
    return None


EXTRA = {237623: 3, 240871: 6, 248493: 5, 240656: 3}
WANDER = {237036: 0, 237623: 6, 240871: 6, 248493: 5, 240344: 3, 240656: 3}
place, moved = [], 0
for entry in sorted(VIS):
    ref = []
    for c in R['creature']:
        if int(c['id']) != entry:
            continue
        x, y, z, o = f(c['position_x']), f(c['position_y']), f(c['position_z']), f(c['orientation'])
        if math.hypot(x - 1263, y - 923) > 500:
            continue
        ref.append((x, y, z, o))
    for x, y, z, o in ref:
        if not clear(x, y):
            got = near(x, y, z, (4, 5, 6, 8, 10))
            assert got, (entry, x, y)
            x2, y2, z2 = got
            moved += 1
        else:
            x2, y2, z2 = x, y, z
        taken.append((x2, y2))
        place.append((entry, x2, y2, z2, o))
    added, k = 0, 0
    flat = [s for s in ref if abs(s[2] - h(s[0], s[1])) < 0.6] or ref
    while added < EXTRA.get(entry, 0):
        x, y, z, o = flat[k % len(flat)]
        got = near(x, y, z, (9 + k // len(flat) * 3, 12 + k // len(flat) * 3, 15 + k // len(flat) * 3))
        k += 1
        assert k < 80, entry
        if got:
            taken.append(got[:2])
            place.append((entry, got[0], got[1], got[2], o))
            added += 1
count = collections.Counter(p[0] for p in place)
print('spawns', len(place), dict(count), 'nudged', moved)

# ------------------------------------------------------------------ creatures
q = lambda s: "'" + s.replace(chr(92), chr(92) * 2).replace("'", "''") + "'"
loc = {r['entry']: u(r['Name']) for r in R['creature_template_locale'] if u(r.get('locale', '')) == 'zhCN'}
ret = {r['entry']: r for r in R['creature_template']}
# entry: level, unit class, hp, damage, loot junk source, gear band or None, money
STAT = {237036: (4, 1, 1.0, 0.7, 160394, None, (6, 20)),
        237623: (4, 1, 1.0, 0.8, 160394, None, (6, 20)),
        240871: (5, 1, 0.9, 0.8, 160394, 'B', (8, 28)),
        248493: (5, 1, 1.0, 0.8, 160394, 'B', (8, 28)),
        240344: (6, 1, 1.1, 0.9, 150238, 'B', (10, 35)),
        240656: (6, 8, 1.0, 0.8, 150238, 'B', (10, 35))}
NEW = sorted(STAT)
assert not [r['entry'] for r in rows('creature_template') if int(r['entry']) in NEW]
# gear pool of the accepted island loot, band B (required level 3-6)
gsrc = open(J(WS, 'beascendskills', 'port-retail-zone-end-to-end', 'references', 'build_loot2.py'), encoding='utf-8').read()
GEAR = {o['i']: o for o in json.load(open(r'D:\_zsdc\cls\gear.json', encoding='utf-8'))}
ns = {'G': GEAR, 'SLOTS': {5, 6, 7, 8, 9, 10, 14, 16, 20}}
exec(gsrc[gsrc.index('def family('):gsrc.index('# (armour %, weapon %) per kill')], ns)
ARM, WEP = ns['BAND']['B']

# ------------------------------------------------------------------ quests
DALNIR, ORWEYNA, HAGAR = 245102, 245879, 245097
QU = {
    9190001: dict(t=u"Lashroom Sprouts 菇房的幼苗", diff=6, money=350, prev=90960, start=HAGAR, end=DALNIR,
                  log=u"Cut back 8 Lashroom Buds on your way to Root Tender Dalnir. / 在回去找根须照料者戴尼尔的路上，清掉8株鞭笞菇幼芽。",
                  desc=u"Your story is painted, $N, and a painted haranir does not rest long. Lashroom buds are crowding the roots below Har'mara. Dalnir has asked for hands. Cut the buds back, then report to Dalnir.$B$B$N，你的故事已经画下，而画过故事的哈籁尼尔人不会闲太久。哈尔玛拉下方的根须被鞭笞菇幼芽挤满了，戴尼尔正缺人手。清掉一些，然后去向戴尼尔报到。",
                  done=u"Report to Dalnir in Har'mara. / 回哈尔玛拉向戴尼尔报到。",
                  offer=u"So Hagar sent you. Good. The roots south of us feel lighter already.$B$B是哈加尔让你来的吧。很好，南边的根须已经轻松多了。",
                  req=u"The buds are still spreading. / 幼芽还在蔓延。",
                  obj=[(237036, 8, u"Lashroom Bud slain 清除鞭笞菇幼芽")], choice=[4663, 4666, 15472], item=0),
    9190002: dict(t=u"Hungry Rot 饥饿的小腐菌", diff=6, money=400, prev=9190001, start=DALNIR, end=DALNIR,
                  log=u"Destroy 8 Hungry Rotlings. / 消灭8只饥饿的小腐菌。",
                  desc=u"Where lashrooms grow, rotlings wake. They eat what the roots need. Thin their numbers before they grow bold.$B$B鞭笞菇长到哪里，小腐菌就醒到哪里。它们啃食根须赖以生存的东西。趁它们还没胆大起来，减少它们的数量。",
                  done=u"Return to Dalnir. / 回去找戴尼尔。",
                  offer=u"Well done. Rot has its place, but not on a living root.$B$B干得好。腐烂自有它的位置，但不该在活着的根须上。",
                  req=u"The rotlings are still feeding. / 小腐菌还在啃食。",
                  obj=[(237623, 8, u"Hungry Rotling slain 消灭饥饿的小腐菌")], choice=[3642, 7277, 3214], item=0),
    9190003: dict(t=u"Stingers in the Grove 林间的毒刺", diff=6, money=450, prev=9190002, start=DALNIR, end=DALNIR,
                  log=u"Slay 6 Swiftstings south of the village. / 消灭村子南边的6只迅针。",
                  desc=u"The tenders who go south come back covered in stings. The swiftstings have nested near the low grove. Clear them out.$B$B去南边的照料者回来时满身蜇伤。迅针在低处的树丛附近筑了巢，把它们清掉。",
                  done=u"Return to Dalnir. / 回去找戴尼尔。",
                  offer=u"The tenders will thank you, and so will their ankles.$B$B照料者们会感谢你的，他们的脚踝也一样。",
                  req=u"I can still hear them buzzing. / 我还能听见它们嗡嗡叫。",
                  obj=[(240871, 6, u"Swiftsting slain 消灭迅针")], choice=[2958, 2962, 2966], item=0),
    9190004: dict(t=u"Creeping Lashers 蔓生的鞭藤", diff=7, money=500, prev=9190003, start=DALNIR, end=DALNIR,
                  log=u"Slay 8 lashers (withered ones count too). / 消灭8株鞭笞者(枯萎的也算)。",
                  desc=u"The lashers have crept further than I have ever seen. Something to the south is driving them toward us. Cut them down, then we will find out what.$B$B鞭笞者蔓延得比我见过的任何时候都远。南边有什么东西正把它们往我们这边赶。先砍掉它们，再查明原因。",
                  done=u"Return to Dalnir. / 回去找戴尼尔。",
                  offer=u"Take this cloak. Orweyna has news from the south, and you will want to be dressed for it.$B$B拿上这件斗篷。奥威娜带来了南边的消息，你得穿戴好再去。",
                  req=u"The lashers still creep. / 鞭笞者还在蔓延。",
                  obj=[(248493, 8, u"Lasher slain 消灭鞭笞者")], choice=[], item=4671),
    9190005: dict(t=u"Wardens of the Lightbloom 光绽林莽守卫", diff=7, money=600, prev=9190004, start=ORWEYNA, end=ORWEYNA,
                  log=u"Drive back 8 Lightbloom Grovewardens. / 击退8名光绽林莽守卫。",
                  desc=u"Now we know what drives the lashers. The Lightbloom has sent wardens into our grove, and they plant as they walk. Drive them back.$B$B现在知道是什么在驱赶鞭笞者了。光绽派守卫进了我们的树丛，他们走到哪里就种到哪里。把他们赶回去。",
                  done=u"Return to Orweyna. / 回去找奥威娜。",
                  offer=u"They will think twice before walking here again.$B$B他们下次再想走进这里，得掂量掂量了。",
                  req=u"Their blooms are still among our roots. / 他们的花还开在我们的根须间。",
                  obj=[(240344, 8, u"Lightbloom Grovewarden slain 击退光绽林莽守卫")], choice=[2572, 4861, 2965], item=0),
    9190006: dict(t=u"Sap Weavers 树脂编织者", diff=7, money=700, prev=9190005, start=ORWEYNA, end=ORWEYNA,
                  log=u"Slay 6 Lightbloom Sap Weavers. / 消灭6名光绽树脂编织者。",
                  desc=u"The wardens are only the hands. The sap weavers twist our own trees against us. Silence them, $N.$B$B守卫只是手脚。树脂编织者扭曲我们自己的树木来对付我们。让他们住手，$N。",
                  done=u"Return to Orweyna. / 回去找奥威娜。",
                  offer=u"The sap runs clean again. You have walked your story well. Choose your weapon, for harder days are close.$B$B树液又清澈了。你把自己的故事走得很好。挑一件武器吧，更艰难的日子快到了。",
                  req=u"The weaving continues. / 编织还在继续。",
                  obj=[(240656, 6, u"Lightbloom Sap Weaver slain 消灭树脂编织者")], choice=[1917, 2281, 3223, 2268, 2067, 4763], item=0),
}
assert not [r['ID'] for r in rows('quest_template') if int(r['ID']) in QU]
items = {int(r['entry']) for r in rows('item_template')}
for v in QU.values():
    assert all(i in items for i in v['choice'] + ([v['item']] if v['item'] else []))
assert all(i in items for i in ARM + WEP)
for k, v in QU.items():
    for e, n_, _t in v['obj']:
        spare = count[e] + (17 if e == 248493 else 0)
        assert spare >= n_ + 2, (k, e, spare, n_)

# ------------------------------------------------------------------ SQL
IDL = ', '.join(map(str, NEW))
QL = ', '.join(map(str, QU))
DL = '%d AND %d' % (DISPLAY[0][0], DISPLAY[-1][0])
sql = [u'''-- HARA3 V1 (2026-11-26, Claude) - candidate, NOT user-tested. Stop worldserver, run on the WORLD database, restart. Safe to run twice.
-- Needs HARA2 V1 + V2 and the accepted island loot (LOOT1A V2). Rerunning HARA2 V1 resets the lasher credit: run this file again afterwards.
SET NAMES utf8mb4;
SET @spawn_limit := 16777215;
SELECT (SELECT COUNT(*) FROM `quest_template` WHERE `ID` = 90960) AS hara2_quest_must_be_1,
       (SELECT COUNT(*) FROM `creature_template` WHERE `entry` IN (245097, 245102, 245879, 248669)) AS hara2_npcs_must_be_4;
DELETE FROM `creature` WHERE `map` = 12694 AND `Comment` LIKE 'HARA3 %%';
DELETE FROM `creature_template` WHERE `entry` IN (%(c)s);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (%(c)s);
DELETE FROM `creature_loot_template` WHERE `Comment` LIKE 'HARA3 %%';
DELETE FROM `smart_scripts` WHERE `source_type` = 0 AND `entryorguid` IN (%(c)s);
DELETE FROM `creature_model_info` WHERE `DisplayID` BETWEEN %(d)s;
DELETE FROM `quest_template` WHERE `ID` IN (%(q)s);
DELETE FROM `quest_template_addon` WHERE `ID` IN (%(q)s);
DELETE FROM `quest_offer_reward` WHERE `ID` IN (%(q)s);
DELETE FROM `quest_request_items` WHERE `ID` IN (%(q)s);
DELETE FROM `quest_poi` WHERE `QuestID` IN (%(q)s);
DELETE FROM `quest_poi_points` WHERE `QuestID` IN (%(q)s);
DELETE FROM `creature_queststarter` WHERE `quest` IN (%(q)s);
DELETE FROM `creature_questender` WHERE `quest` IN (%(q)s);
UPDATE `creature_template` SET `KillCredit1` = 0 WHERE `entry` = 248669;
SELECT COALESCE(MAX(`guid`), 0) INTO @g FROM `creature` WHERE `guid` < @spawn_limit;
SELECT IF(@g + 200 + 10000 < @spawn_limit, 'guid base OK', 'ABORT: no guid room, do not continue') AS guid_check, @g AS creature_max;''' % dict(c=IDL, d=DL, q=QL)]
cols = '`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `unit_class`, `unit_flags`, `type`, `AIName`, `MovementType`, `HealthModifier`, `DamageModifier`, `ExperienceModifier`, `RegenHealth`, `flags_extra`, `ScriptName`, `mingold`, `maxgold`'
vals, mods = [], []
for e in NEW:
    lv, ucls, hp, dmg, _src, _band, money = STAT[e]
    name = u'%s %s' % (u(ret[str(e)]['name']), loc[str(e)])
    vals.append(u"(%d, %s, NULL, %d, %d, 7, 0, 1, 1.14286, 0, %d, 0, %d, %s, %d, %s, %s, 2, 1, 0, '', %d, %d)" % (
        e, q(name), lv, lv, ucls, int(ret[str(e)]['type']), q('SmartAI' if e == 240656 else ''), 1 if WANDER[e] else 0, hp, dmg, money[0], money[1]))
    mine = [d for d in DISPLAY if d[1] == e]
    for k, d in enumerate(mine):
        mods.append('(%d, %d, %d, %s, 1, 0)' % (e, k, d[0], RSCALE[(str(e), str(d[3]))]))
sql.append(u'INSERT INTO `creature_template` (%s) VALUES\n%s;' % (cols, ',\n'.join(vals)))
sql.append('INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES\n%s;' % ',\n'.join(mods))
info = []
for did, e, mdid, rd, cscale, tex, geo, tdisp in DISPLAY:
    scale = RSCALE[(str(e), str(rd))]
    info.append('(%d, %.3f, %.3f, 2, 0)' % (did, VIS[e][3] / scale, VIS[e][2] / scale))
sql.append('INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`) VALUES\n%s;' % ',\n'.join(info))
sql.append(u'-- withered lashers (HARA2) also count for "Creeping Lashers"\nUPDATE `creature_template` SET `KillCredit1` = 248493 WHERE `entry` = 248669;')
sql.append(u'''-- the sap weaver casts Wrath (9739, damage scales down with the creature level) and closes in when out of mana
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `action_type`, `action_param1`, `action_param2`, `target_type`, `comment`)
VALUES (240656, 0, 0, 0, 0, 0, 100, 0, 0, 1000, 3500, 5000, 11, 9739, 64, 2, 'Lightbloom Sap Weaver - In Combat - Cast Wrath');''')
sql.append(u'-- drops: junk copied from accepted island rows (level 4 also their starter gear), level 5-6 get the next gear band')
head = 'INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)'
gear_total = 0
for e in NEW:
    lv, ucls, hp, dmg, src, band, money = STAT[e]
    cond = u" AND `Comment` NOT LIKE '%初始装备'" if band else u''
    sql.append(head + u"\nSELECT %d, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, 'HARA3 copy of %d' FROM `creature_loot_template` WHERE `Entry` = %d AND `Comment` LIKE 'LOOT1A %%' AND `QuestRequired` = 0%s;" % (e, src, src, cond))
    if band:
        g = []
        for group, pool, pct in ((8, ARM, 22), (9, WEP, 6)):
            g += ["(%d, %d, 0, %s, 0, 1, %d, 1, 1, 'HARA3 gear')" % (e, i, round(pct / len(pool), 4), group) for i in pool]
        gear_total += len(g)
        # an item already copied as junk keeps its junk row
        sql.append(head.replace('INSERT INTO', 'INSERT IGNORE INTO') + ' VALUES\n' + ',\n'.join(g) + ';')
    sql.append('UPDATE `creature_template` SET `lootid` = %d WHERE `entry` = %d AND EXISTS (SELECT 1 FROM `creature_loot_template` WHERE `Entry` = %d);' % (e, e, e))
cins = 'INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES'
sp = ["(@g + %d, %d, 12694, 1, 1, 0, %.2f, %.2f, %.2f, %.2f, 45, %d, %d, 'HARA3 %d')" % (i, e, x, y, z, o, WANDER[e], 1 if WANDER[e] else 0, e) for i, (e, x, y, z, o) in enumerate(place, 1)]
sql.append(cins + '\n' + ',\n'.join(sp) + ';')
for qid, v in sorted(QU.items()):
    obj = v['obj'] + [(0, 0, '')] * (4 - len(v['obj']))
    ch = v['choice'] + [0] * (6 - len(v['choice']))
    names = ['ID', 'QuestType', 'QuestLevel', 'MinLevel', 'AllowableRaces', 'RewardXPDifficulty', 'RewardMoney', 'Flags', 'LogTitle', 'LogDescription', 'QuestDescription', 'QuestCompletionLog', 'RewardItem1', 'RewardAmount1']
    data = [qid, 2, -1, 1, 0, v['diff'], v['money'], 0, q(v['t']), q(v['log']), q(v['desc']), q(v['done']), v['item'], 1 if v['item'] else 0]
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
pos = {}
for e, x, y, z, o in place:
    pos.setdefault(e, []).append((x, y))
npcpos = {DALNIR: (1349.0, 908.0), ORWEYNA: (1339.0, 905.0)}
poi, pts = [], []
for qid, v in sorted(QU.items()):
    marks = [(i, pos[o[0]]) for i, o in enumerate(v['obj'])] + [(-1, [npcpos[v['end']]])]
    for k, (obj_i, L) in enumerate(marks):
        cx = sum(a for a, b in L) / len(L)
        cy = sum(b for a, b in L) / len(L)
        r = max(8.0, min(60.0, max(math.hypot(a - cx, b - cy) for a, b in L)))
        poi.append('(%d, %d, %d, 12694, 20418, 0, 0, 1, 0)' % (qid, k, obj_i))
        for j, (dx, dy) in enumerate(((-r, -r), (r, -r), (r, r), (-r, r))):
            pts.append('(%d, %d, %d, %d, %d, 0)' % (qid, k, j, round(cx + dx), round(cy + dy)))
sql.append('INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`) VALUES\n%s;' % ',\n'.join(poi))
sql.append('INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES\n%s;' % ',\n'.join(pts))
sql.append(u'''SELECT (SELECT COUNT(*) FROM `quest_template` WHERE `ID` IN (%(q)s)) AS quests_must_be_6,
       (SELECT COUNT(*) FROM `creature_template` WHERE `entry` IN (%(c)s)) AS creature_templates_must_be_6,
       (SELECT COUNT(*) FROM `creature` WHERE `Comment` LIKE 'HARA3 %%') AS creature_spawns_must_be_%(ns)d,
       (SELECT COUNT(*) FROM `creature_model_info` WHERE `DisplayID` BETWEEN %(d)s) AS model_info_must_be_%(nd)d,
       (SELECT COUNT(DISTINCT `Entry`) FROM `creature_loot_template` WHERE `Comment` LIKE 'HARA3 %%') AS mobs_with_drops_must_be_6,
       (SELECT `KillCredit1` FROM `creature_template` WHERE `entry` = 248669) AS lasher_credit_must_be_248493,
       (SELECT COUNT(*) FROM `smart_scripts` WHERE `entryorguid` = 240656 AND `source_type` = 0) AS caster_script_must_be_1;''' % dict(q=QL, c=IDL, d=DL, ns=len(place), nd=len(DISPLAY)))
sql = '\n'.join(sql)
undo = sql.split('SELECT COALESCE(MAX(`guid`)')[0]
undo = undo[undo.index('DELETE FROM `creature` WHERE'):]
undo = u'-- HARA3 V1 undo (world database)\nSET NAMES utf8mb4;\n' + undo

# ------------------------------------------------------------------ level simulation with core formulas
qx = open(J(SRV, 'QuestXP.dbc'), 'rb').read()
_c, qn, qnf, qrs = struct.unpack('<4I', qx[:16])
X = {struct.unpack_from('<I', qx, 20 + i * qrs)[0]: struct.unpack_from('<%dI' % qnf, qx, 20 + i * qrs) for i in range(qn)}
NEED = {1: 400, 2: 900, 3: 1400, 4: 2100, 5: 2800, 6: 3600, 7: 4500, 8: 5400, 9: 6500}


def killxp(pl, ml):
    base = pl * 5 + 45
    if ml >= pl:
        return int(base * (1 + 0.05 * min(ml - pl, 4)))
    zd = 5 if pl < 8 else 6
    return int(base * (1 - (pl - ml) / zd)) if pl - ml < zd else 0


lv, xp = 1, 0
sim = []
CHAIN = [('90957', [(6, 1)], 5), ('90958', [(8, 2), (8, 2)], 6), ('90959', [(1, 3)], 6), ('90960', [], 6)] + [(str(k), [(v['obj'][0][1], STAT[v['obj'][0][0]][0])], v['diff']) for k, v in sorted(QU.items())]
for name, kills, diff in CHAIN:
    for n_, ml in kills:
        for _ in range(n_):
            xp += 2 * killxp(lv, ml)
            while lv in NEED and xp >= NEED[lv]:
                xp -= NEED[lv]
                lv += 1
    xp += X[lv][2 + min(diff + 1, 8) - 1]
    while lv in NEED and xp >= NEED[lv]:
        xp -= NEED[lv]
        lv += 1
    sim.append((name, lv, xp, NEED.get(lv, 0)))
for s_ in sim:
    print('after %s level %d (%d/%d)' % s_)

# ------------------------------------------------------------------ SQL simulation
db = sqlite3.connect(':memory:')
db.create_function('IF', 3, lambda a, b, c: b if a else c)


def mk(t):
    cs, on = [], False
    for line in open(J(BASEDIR, t + '.sql'), encoding='utf-8', errors='replace'):
        if line.startswith('CREATE TABLE `%s`' % t):
            on = True
        elif on and line.startswith(')'):
            break
        elif on and line.strip().startswith('`'):
            cs.append(line.strip().split('`')[1])
    db.execute('create table %s (%s)' % (t, ','.join('"%s"' % c for c in cs)))
    return cs


tables = ['creature', 'creature_template', 'creature_template_model', 'creature_loot_template', 'creature_model_info', 'smart_scripts', 'quest_template', 'quest_template_addon',
          'quest_offer_reward', 'quest_request_items', 'quest_poi', 'quest_poi_points', 'creature_queststarter', 'creature_questender']
schema = {t: mk(t) for t in tables}
for t, need_ in (('creature', ('Comment', 'id1', 'wander_distance')), ('smart_scripts', ('event_param1',)), ('creature_template', ('KillCredit1',))):
    for c_ in need_:
        if c_ not in schema[t]:
            db.execute('alter table %s add column "%s"' % (t, c_))
for t, used in re.findall(r'INSERT(?: IGNORE)? INTO `(\w+)` \(([^)]*)\)', sql):
    for c_ in re.findall(r'`(\w+)`', used):
        assert c_ in schema[t] or (t == 'creature' and c_ in ('Comment', 'id1', 'wander_distance')), ('column not in base schema', t, c_)
db.execute('create unique index loot_pk on creature_loot_template(Entry, Item)')
db.execute('insert into quest_template(ID) values (90960)')
for e in (245097, 245102, 245879, 248669):
    db.execute('insert into creature_template(entry, KillCredit1) values (?, 0)', (e,))
for s_ in (160394, 150238):
    for it, com in ((779, 'LOOT1A x'), (2589, 'LOOT1A x'), (ARM[0], u'LOOT1A x 初始装备'), (85, u'LOOT1A x 初始装备')):
        db.execute("insert or ignore into creature_loot_template(Entry, Item, Reference, Chance, QuestRequired, LootMode, GroupId, MinCount, MaxCount, Comment) values (?, ?, 0, 20, 0, 1, 0, 1, 1, ?)", (s_, it, com))


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
        s = re.sub(r'@(\w+)', lambda m_: str(var.get(m_[1], m_[0])), s).replace('INSERT IGNORE', 'INSERT OR IGNORE')
        c = db.execute(s)
        if into:
            var[into[1]] = c.fetchone()[0]
        elif s.startswith('SELECT') and show:
            n_ = [d[0] for d in c.description]
            for r in c.fetchall():
                print('  ', dict(zip(n_, r)))


seed = {t: db.execute('select count(*) from %s' % t).fetchone()[0] for t in tables}
run(sql, True)
snap = [db.execute('select count(*) from %s' % t).fetchone()[0] for t in tables]
run(sql, False)
assert snap == [db.execute('select count(*) from %s' % t).fetchone()[0] for t in tables]
run(undo, False)
assert seed == {t: db.execute('select count(*) from %s' % t).fetchone()[0] for t in tables}, 'undo leaves rows'
assert db.execute('select KillCredit1 from creature_template where entry = 248669').fetchone()[0] == 0
print('sql ran twice identically; undo restores the seeded state')

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
    wr(u'05_撤销/原Patch-YB/DBFilesClient/' + n, old)
    hashes.append((u'客户端 YB ' + n, sha(old), sha(new)))
wr(u'02_覆盖到客户端根目录/Data/Retail/aliases_maps.csv', csv_new)
wr(u'05_撤销/原客户端根目录/Data/Retail/aliases_maps.csv', csv_old)
hashes.append((u'客户端 aliases_maps.csv', sha(csv_old), sha(csv_new)))
for n, (old, new) in server.items():
    wr(u'03_服务端_Data_dbc/' + n, new)
    wr(u'05_撤销/原服务端dbc/' + n, old)
    hashes.append((u'服务端 ' + n, sha(old), sha(new)))
wr(u'04_服务端_SQL/world_hara3.sql', sql)
wr(u'05_撤销/undo_hara3.sql', undo)
table = '\n'.join(u'| %s | `%s` | `%s` |' % (h_[0], h_[1][:12], h_[2][:12]) for h_ in hashes)
wr(u'README_覆盖与测试说明.md', u'''
# HARA3 V1：哈籁尼尔任务 5–10(候选，实机未测)

前提：HARA2 V1 + V2 已装；流放者之岛掉落(LOOT1A V2)在库里。

## 内容(6 个任务是新设计的，零售没有这些任务；怪物、位置和模型用零售的)
| 任务 | 名称 | 接 → 交 | 目标 | 怪物 | 奖励 |
|---|---|---|---|---|---|
| 9190001 | 菇房的幼苗 | 洞穴深处哈加尔 → 戴尼尔 | 8 | 鞭笞菇幼芽 4 级(原地不动) | 腰带三选一 |
| 9190002 | 饥饿的小腐菌 | 戴尼尔 | 8 | 4 级 | 护腕三选一 |
| 9190003 | 林间的毒刺 | 戴尼尔 | 6 | 迅针 5 级 | 裤子三选一(绿) |
| 9190004 | 蔓生的鞭藤 | 戴尼尔 | 8 | 鞭笞者 5 级(枯萎的鞭笞者也算) | 斗篷 |
| 9190005 | 光绽林莽守卫 | 奥威娜 | 8 | 6 级 | 胸甲三选一(绿) |
| 9190006 | 树脂编织者 | 奥威娜 | 6 | 6 级，会放愤怒(远程) | 武器六选一 |

- 估算(单人，只打任务要求的数量)：%(sim)s
- **和零售/草案的不同**：这六种怪都是黄名(不主动攻击)，零售的两种光绽敌人是红名——它们和低级任务混在同一片地方，改红名会把 2–3 级角色打死。
- 零售数量不够的怪补了刷新点(小腐菌 +3、迅针 +6、鞭笞者 +5、编织者 +3)；和已有刷新点重叠的挪开了几码。
- 掉落：铜币、杂物、可穿的初始装备(5–6 级怪掉高一档)。

## 部署(关游戏、停服)
1. 备份 `Data\\Patch-YB.mpq`、`Data\\Retail\\aliases_maps.csv`、服务端两个生物 dbc。核对下表"输入"哈希，不相等先告诉我。
2. `01_导入Patch-YB.mpq` 的两个 dbc 导入 Patch-YB；`02_覆盖到客户端根目录` 覆盖到客户端根目录。
3. `03_服务端_Data_dbc` 覆盖服务端 `Data\\dbc`。
4. world 库执行 `04_服务端_SQL\\world_hara3.sql`。开头 `hara2_quest…`=1、`hara2_npcs…`=4、`guid base OK`；末尾按列名对读回值。
5. 启动服务端，删客户端 `Cache\\WDB`。

| 文件 | 输入 | 输出 |
|---|---|---|
%(t)s

## 测试
- 接着做：交掉 90960 后，洞穴深处的哈加尔给 9190001(`.tele Haranir` 后 `.go xyz 1149 1166 1310 12694`)。戴尼尔 `1349 908 1345`，奥威娜在旁边。
- 打怪区域在营地南边 `1230 800 1330` 一带。

| 重点看 | |
|---|---|
| 模型 | 6 种新怪有贴图、会动；**光绽守卫/编织者**模型很复杂，看有没有拉伸、碎片、部件重叠 |
| 大小和攻击距离 | 迅针很小，是否点得到、近战打得到 |
| 地面 | 补刷和挪过位置的怪有没有悬空、卡进地里或树根里 |
| 强度 | 单人能否打得过，编织者远程伤害 |
| 任务 | 接交顺序、计数、奖励能否选、地图标记 |
| 等级 | 做完 9190006 时几级 |

## 撤销
执行 `05_撤销\\undo_hara3.sql`，换回 `05_撤销` 里的 dbc、csv，重启。

## 未做与边界
- 全部未实机测试(SQL 只做过离线模拟，模型只做过离线姿势渲染，渲染不带贴图)。
- 除编织者外怪物没有技能；声音借用现成生物。
- 任务 11–15 和传送暴风城在下一批。
''' % dict(t=table, sim=u'做完 9190006 约 %d 级(%d/%d)' % sim[-1][1:]))
wr(u'memory.md', u'''
# HARA3 V1 记录(2026-11-26，Claude)
用户："好的 继续下一批的任务开发吧 前面的都很棒"。任务 9190001-9190006；怪 237036/237623/240344/240656/240871/248493(零售编号)；模型数据 710111-710114(710104 复用)，显示 710121 起。
脚本 D:\\_zsdc\\hara(ex3.py 提取、models3/conv.py、build_hara3.py)。状态：候选，未实测。''')
wr(u'tutor.md', u'''
# 大白话：新任务怎么接在老任务后面
零售没有这些任务，但零售把怪摆好了。我们只写"让你去打谁、打几只、给什么"。怪的模型、位置照搬；数量不够就在旁边补几只。''')
lines = []
for dp, _d, fn in os.walk(P):
    for fl in fn:
        p = J(dp, fl)
        lines.append('%s  %s' % (sha(open(p, 'rb').read()), os.path.relpath(p, P).replace(B, '/')))
wr('SHA256SUMS.txt', '\n'.join(sorted(lines, key=lambda s: s[66:])).encode('utf-8') + b'\n')


def app(path, text, key):
    t = open(path, 'rb').read()
    assert t.strip() and key.encode('utf-8') not in t, path
    e = '\r\n' if b'\r\n' in t else '\n'
    open(path, 'ab').write((('' if t.endswith(b'\n') else e) + e + text.replace('\n', e) + e).encode('utf-8'))
    after = open(path, 'rb').read()
    assert after.startswith(t) and key.encode('utf-8') in after


app(J(WS, u'协作说明_并行开发.md'), u'| 2026-11-26 | Claude | HARA3 V1：哈籁尼尔任务 9190001-9190006 | 候选(实机未测) | YB CreatureModelData +4(710111-710114)、CreatureDisplayInfo +%d(710121 起)、aliases_maps.csv；服务端同名 DBC；world 生物 237036/237623/240344/240656/240871/248493、任务 9190001-9190006、248669 KillCredit1 | 现场 YB 与服务端表为基底(见台账) | 000Ascendupdate20261126/claudefix_…HARA3_V1… | Codex 改 YB 两张生物表前请以本包装后版本为底 |' % len(DISPLAY), u'HARA3 V1：哈籁尼尔')
app(J(WS, u'台账_YB_XA共享文件哈希.md'), u'## 2026-11-26 HARA3 V1(Claude，待用户安装)\n|文件|输入|输出|\n|---|---|---|\n' + '\n'.join(u'|%s|%s|%s|' % h_ for h_ in hashes), u'HARA3 V1(Claude')
MEM = r'<user-profile>\.claude\projects\d--000rebornWOW-000RebornWOWHighForkPRO-beascendLauncher-wowlauncher2026-CataLauncher-rebornWOW\memory\haranir-start-port.md'
app(MEM, u'11-26: user said HARA2 results are great and asked for the next batch. HARA3 V1 delivered (quests 9190001-9190006), untested. Next HARA4 (quests 11-15 + teleport to Stormwind).', u'HARA3 V1 delivered')
print(P)
for h_ in hashes:
    print(h_[0], h_[1][:12], '->', h_[2][:12])
