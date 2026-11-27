# -*- coding: utf-8 -*-
"""HARA4 V1: outward batch - Nai'theren Grotto cooking chain (retail 91585-91589) plus a lead-in quest, models, props, graveyard."""
import ctypes, struct, os, hashlib, io, sys, pickle, glob, re, sqlite3, math, csv, json, collections
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
B = chr(92)
J = os.path.join
WS = r'D:\000rebornWOW\000RebornWOWHighForkPRO'
DAY = J(WS, '000Ascendupdate', '000Ascendupdate20261126')
P = J(DAY, u'claudefix_20261126_阶段HARA4_V1_哈籁尼尔南下奈瑟兰洞窟_村宴任务线六个任务_Claude')
assert not os.path.exists(P), P
CLIENT = r'C:\000ref\WarcraftXL试装_client'
SRVROOT = J(WS, 'beascendserver', 'wowshub_playerbot_npcbot_newrace20261122Ascend')
SRV = J(SRVROOT, 'Data', 'dbc')
H = r'D:\_zsdc\hara'
sha = lambda b: hashlib.sha256(b).hexdigest()
fb = lambda x: struct.unpack('<I', struct.pack('<f', x))[0]
exec(open(r'D:\_zsdc\cls\classq.py', encoding='utf-8').read().split("cls = {}")[0].replace("sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')", ''))
exec(open(r'D:\_zsdc\maps2\verify.py', encoding='utf-8').read().split('# retail creature positions')[0].replace("sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')\n", ''))
bsrc = open(r'D:\_zsdc\models4\build_model1a.py', encoding='utf-8').read()
exec(bsrc[bsrc.index('dll = ctypes.WinDLL'):bsrc.index('# id, folder, m2 file id')])      # client_table (Patch-YB) / parse / row_of / append
w_ = open(J(H, 'which.py'), encoding='utf-8').read()
xdll = {'ctypes': ctypes, 'struct': struct, 'os': os, 'CLIENT': CLIENT}
exec(w_[w_.index('dll = ctypes.WinDLL'):w_.index('names = sys.argv[1:]')], xdll)


def xa_table(n):
    d, T_ = xdll['dll'], xdll['H']
    h = T_()
    assert d.SFileOpenArchive(J(CLIENT, 'Data', 'Patch-XA.mpq'), 0, 0x100 | 0x10000 | 0x20000, ctypes.byref(h))
    f = T_()
    assert d.SFileOpenFileEx(h, ('DBFilesClient' + B + n).encode(), 0, ctypes.byref(f))
    size = d.SFileGetFileSize(f, None)
    buf = ctypes.create_string_buffer(size)
    got = ctypes.c_uint32()
    assert d.SFileReadFile(f, buf, size, ctypes.byref(got), None) and got.value == size
    d.SFileCloseArchive(h)
    return buf.raw[:size]


R = pickle.load(open(J(H, 'hubs.pkl'), 'rb'))
BASEDIR = r'D:\000rebornWOW\000RebornWOWHighForkPRO\beascendcode\claude-release-20261126\data\sql\base\db_world'
u = lambda v: v.strip("'")
f = lambda v: float(u(v))
h = lambda x, y: height(12694, x, y)
wsrc = open(J(H, 'water.py'), encoding='utf-8').read()
exec(wsrc[wsrc.index('S = 533.33333'):wsrc.index('X = pickle.load')].replace('SRV,', 'SRVROOT,'))
q = lambda s: "'" + s.replace(chr(92), chr(92) * 2).replace("'", "''") + "'"


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
DIRS = {'HaraDrifter': 'models', 'HaraSaptor': 'models', 'HaraSwiftsting': 'models3', 'HaraFrillfish': 'models4', 'HaraSporeglider': 'models4', 'HaraDarter': 'models4'}
FOLDER = {710101: 'HaraDrifter', 710105: 'HaraSaptor', 710114: 'HaraSwiftsting', 710115: 'HaraFrillfish', 710116: 'HaraSporeglider', 710117: 'HaraDarter'}
DONOR = {710101: 17751, 710105: 180, 710114: 92, 710115: 17751, 710116: 180, 710117: 92}   # sound donors
NEWMODEL = {710115: 0.2, 710116: 1.0, 710117: 1.0}                                          # retail CreatureModelData.ModelScale
# creature -> (model data id, retail displays, combat reach yards, bounding radius yards)
VIS = {240113: (710101, [131466, 131467, 131468], 1.2, 0.5),
       240120: (710115, [103966, 103968], 1.0, 0.4),
       248127: (710114, [110392, 110393], 0.8, 0.4),
       248598: (710116, [125989], 3.5, 1.0),
       249285: (710105, [122801, 122802, 122803], 1.5, 0.7),
       256195: (710117, [139459, 139513], 1.5, 0.5)}
allret = {str(d) for v in VIS.values() for d in v[1]}
RCDI = {r['ID']: r for r in csv.DictReader(open(r'D:\_zsdc\wago_item\CreatureDisplayInfo.csv', encoding='utf-8-sig')) if r['ID'] in allret}
RGEO = collections.defaultdict(dict)
for r in csv.DictReader(open(r'D:\_zsdc\wago_geo\CreatureDisplayInfoGeosetData.csv', encoding='utf-8-sig')):
    if r['CreatureDisplayInfoID'] in allret:
        RGEO[r['CreatureDisplayInfoID']][int(r['GeosetIndex']) + 1] = int(r['GeosetValue'])
RSCALE = {(r['CreatureID'], r['CreatureDisplayID']): f(r['DisplayScale']) for r in R['creature_template_model']}


def mfile(folder, tail):
    return J(H, DIRS[folder], 'd', 'retail_%s_%s%s' % (folder, folder, tail))


def parts_of(folder):
    m = open(mfile(folder, '.m2'), 'rb').read()
    sk = open(mfile(folder, '00.skin'), 'rb').read()
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
    m = open(mfile(folder, '.m2'), 'rb').read()
    nv, vo = struct.unpack_from('<II', m, 0x3c)
    vs = [struct.unpack_from('<3f', m, vo + 48 * i) for i in range(nv)]
    return [min(v[k] for v in vs) for k in range(3)] + [max(v[k] for v in vs) for k in range(3)]


DISPLAY, nid = [], 710138
for entry, (mdid, rets, reach, rad) in sorted(VIS.items()):
    folder = FOLDER[mdid]
    ids, types = parts_of(folder)
    groups = sorted({s // 100 for s in ids if s // 100})
    for ret in rets:
        rr = RCDI[str(ret)]
        assert rr['ExtendedDisplayInfoID'] == '0' and (str(entry), str(ret)) in RSCALE, (entry, ret)
        tex = [t for t in (int(rr['TextureVariationFileDataID_%d' % k]) for k in range(3)) if t]
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
        print('display %d creature %d retail %d geo %s parts %s' % (nid, entry, ret, hex(geo), shown))
        DISPLAY.append((nid, entry, mdid, ret, f(rr['CreatureModelScale']), tex, geo))
        nid += 1


def build(read):
    md0, di0 = read('CreatureModelData.dbc'), read('CreatureDisplayInfo.dbc')
    for mid in (710101, 710105, 710114):
        assert row_of(md0, mid) is not None, 'earlier Haranir tables are not installed'
    msb, dbase = parse(md0)[4], len(parse(di0)[4])
    mrows, drows, mstr, dstr = [], [], b'', b''
    for mid, mscale in sorted(NEWMODEL.items()):
        folder = FOLDER[mid]
        assert row_of(md0, mid) is None
        mr = row_of(md0, row_of(di0, DONOR[mid])[1])
        assert mr is not None and len(mr) == 28, mid
        mr[0], mr[2] = mid, len(msb) + len(mstr)
        mstr += (B.join(['retail', folder, folder]) + '.mdx').encode() + b'\0'
        mr[4] = fb(mscale)
        mr[14], mr[15], mr[16] = fb(0.611), fb(2.031), 0
        for i, v in zip(range(17, 23), box_of(folder)):
            mr[i] = fb(v)
        mrows.append(mr)
    for did, entry, mdid, ret, cscale, tex, geo in DISPLAY:
        assert row_of(di0, did) is None
        dr = list(row_of(di0, DONOR[mdid]))
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
# quest items: client Item.dbc (Patch-XA)
ITEMS = {9246923: (u'Frillfish Fillet 褶鱼肉片', 50869, 20), 9246924: (u'Root Drift Jelly 根漂胶质', 53565, 20), 9246926: (u'Nutrient-Rich Soil 肥沃土壤', 2480, 20),
         9246942: (u'Bloomterror Rind 盛放恐魔的外皮', 8942, 1), 9246950: (u'Village Meal Hamper 村宴食盒', 12333, 1)}
item0 = xa_table('Item.dbc')
ref = row_of(item0, 9178051)
assert ref is not None and len(ref) == 8 and ref[1] == 12, ref
item1 = append(item0, [[i, 12, 0, ref[3], 0xFFFFFFFF, d_, 0, 0] for i, (_n, d_, _s) in sorted(ITEMS.items())], b'')
print('Item.dbc rows', parse(item0)[0], '->', parse(item1)[0], 'reference row', ref)

csv_old = open(J(CLIENT, 'Data', 'Retail', 'aliases_maps.csv'), 'rb').read()
assert b'HaraBud' in csv_old, 'HARA3 aliases are not installed'
have = {x.split(b';')[0]: x.split(b';', 1)[1].lower() for x in csv_old.split() if b';' in x}
add = []
for line in open(J(H, 'models4', 'aliases_maps.csv'), 'rb').read().split():
    fdid, path = line.split(b';', 1)
    if fdid in have:
        assert have[fdid] == path.lower(), (line, have[fdid])
    elif line not in add:
        add.append(line)
csv_new = csv_old + (b'' if csv_old.endswith(b'\n') else b'\r\n') + b'\r\n'.join(add) + b'\r\n'
for did, entry, mdid, ret, cscale, tex, geo in DISPLAY:
    folder = FOLDER[mdid]
    for t in tex:
        assert (B.join(['retail', folder, '%s%d.blp' % (folder, t)])).encode().lower() in csv_new.lower(), (folder, t)
        assert any(os.path.isfile(J(H, d_, 'd', 'retail_%s_%s%d.blp' % (folder, folder, t))) for d_ in ('models', 'models3', 'models4')), (folder, t)
print('aliases added', len(add))

# ------------------------------------------------------------------ spawns
YUREL, YUREL2, HEALER = 247936, 9247936, 6491
ORWEYNA = 245879
GROTTO = (1357.0, 486.0)
VILLAGE_YU = (1175.0, 800.0)
GRAVE = (1296.0, 440.0)
taken = []
for tag, col in (('HARA2_V1', None), ('HARA3_V1', None), ('HARAVEND1_V1', None)):
    d_ = glob.glob(DAY + B + u'claudefix_*%s_*' % tag)[0]
    for p_ in glob.glob(d_ + B + u'*服务端_SQL' + B + '*.sql'):
        taken += [(float(a), float(b)) for a, b in re.findall(r"\(@g \+ \d+, \d+, 12694, 1, \d+, 0, ([\d.-]+), ([\d.-]+),", open(p_, encoding='utf-8').read())]
assert len(taken) > 100, len(taken)
fixed = [GROTTO, VILLAGE_YU, GRAVE, (1359.8, 487.3)]
# entry: (height above ground or water, None = retail height (swimmers), minimum spacing, wander)
PLACE = {240113: (2.0, 5.0, 4), 240120: (None, 5.0, 4), 248127: (0.1, 4.0, 4), 248598: (1.0, 0.0, 0), 249285: (0.1, 8.0, 5), 256195: (2.5, 9.0, 6)}
FLY = (240113, 256195, 248598)
SWIM = (240120,)
place = []
for entry, (lift, gap, wander) in sorted(PLACE.items()):
    for c in R['creature']:
        if int(c['id']) != entry:
            continue
        x, y, z, o = f(c['position_x']), f(c['position_y']), f(c['position_z']), f(c['orientation'])
        if math.hypot(x - GROTTO[0], y - GROTTO[1]) > 330:
            continue
        if entry != 248598:
            if any(math.hypot(x - a, y - b) < gap for e_, a, b, *_r in place if e_ == entry) or any(math.hypot(x - a, y - b) < 3.5 for a, b in taken):
                continue
            if any(math.hypot(x - a, y - b) < (25 if entry == 249285 else 8) for a, b in fixed):
                continue
        ground = h(x, y)
        pool = water(x, y)
        if pool is None or pool <= ground:
            pool = ground
        if lift is None:
            zz = z
            assert ground - 0.5 < z <= pool + 0.5, ('swimmer outside the pool', entry, x, y, z, ground, pool)
        elif entry in FLY:
            zz = round(pool + lift, 2)
        else:
            if pool - ground > 1.0:
                continue                                        # a walking creature would stand under water
            zz = round(ground + lift, 2)
        place.append((entry, x, y, zz, o, wander))
        taken.append((x, y))
count = collections.Counter(p[0] for p in place)
print('creature spawns', len(place), dict(count))
assert count[240120] >= 8 and count[240113] >= 8 and count[248598] == 1, count

# ------------------------------------------------------------------ objects
# entry: (type, display, size, quest, caption, name)
GO = {564999: (10, 8448, 1.6, 91585, u'饮用中', u"Yu'relen's Elixir 尤瑞伦的药剂"),
      557572: (3, 20, 1.0, 91586, u'挖掘中', u'Nutrient-Rich Dirt 肥沃的泥土'),
      558066: (10, 7871, 2.5, 91588, u'剔骨中', u'Fillet Knife 剔鱼刀（点击处理鱼肉）'),
      558065: (10, 5112, 1.0, 91588, u'清洗中', u'Wash Bed 洗菜盆（点击清洗蔬菜）'),
      558059: (10, 192, 0.8, 91588, u'烹煮中', u'Campfire 营火（点击烹煮食物）'),
      565800: (3, 31, 0.9, 91589, u'装箱中', u'Root Dash Delivery Crate 村宴货箱'),
      558126: (10, 381, 1.0, 91589, u'摆放中', u'Salad 凉拌菜（点击摆放）'),
      558129: (10, 6797, 1.0, 91589, u'摆放中', u'Fish Plate 烤鱼盘（点击摆放）'),
      558135: (10, 2951, 0.8, 91589, u'摆放中', u'Ribs 肋排（点击摆放）'),
      558146: (10, 20, 0.6, 91589, u'摆放中', u'Nutrient-Rich Dirt 沃土碗（点击摆放）')}
CHEST_ITEM = {557572: 9246926, 565800: 9246950}
gdb = open(J(SRV, 'GameObjectDisplayInfo.dbc'), 'rb').read()
_, gn, gnf, grs, gss = struct.unpack_from('<4sIIII', gdb)
gids = {struct.unpack_from('<I', gdb, 20 + i * grs)[0] for i in range(gn)}
assert all(v[1] in gids for v in GO.values()), [v[1] for v in GO.values() if v[1] not in gids]
gplace = []
for e in (564999, 557572, 558066, 558065, 558059, 565800):
    got = []
    for g in R['gameobject']:
        if int(g['id']) != e or math.hypot(f(g['position_x']) - GROTTO[0], f(g['position_y']) - GROTTO[1]) > 330:
            continue
        x, y, z, o = f(g['position_x']), f(g['position_y']), f(g['position_z']), f(g['orientation'])
        if any(math.hypot(x - a, y - b) < 3 for _e, a, b, *_r in got):
            continue
        got.append((e, x, y, z, o))
    assert got, e
    gplace += got
for e, (x, y) in zip((558126, 558129, 558135, 558146), ((1170.0, 803.0), (1170.0, 806.5), (1170.0, 810.0), (1170.0, 813.5))):
    gplace.append((e, x, y, round(h(x, y) + 0.05, 2), 0.0))
gcount = collections.Counter(p[0] for p in gplace)
print('object spawns', len(gplace), dict(gcount))
assert gcount[557572] >= 8, gcount

# ------------------------------------------------------------------ creatures
loc = {r['entry']: u(r['Name']) for r in R['creature_template_locale'] if u(r.get('locale', '')) == 'zhCN'}
ret = {r['entry']: r for r in R['creature_template']}
ZH = {240113: u'可口的根系漂流者', 240120: u'吐沫的褶鱼', 248127: u'急躁的甲虫', 248598: u'盛放的孢子滑翔者恐魔', 249285: u'流涎的迅叶龙', 256195: u'洞窟迅虫', 247936: u'尤瑞伦'}
# entry: level, hp, damage, faction, junk source, money
STAT = {240113: (7, 1.0, 0.8, 7, 150238, (12, 40)),
        240120: (7, 1.0, 0.8, 7, 150238, (12, 40)),
        248127: (7, 0.8, 0.7, 7, 150238, (10, 30)),
        248598: (9, 3.0, 1.1, 14, 150238, (80, 180)),
        249285: (8, 1.0, 0.9, 14, 150238, (14, 45)),
        256195: (8, 0.9, 0.8, 7, 150238, (14, 45))}
NEW = sorted(STAT)
NPCS = [YUREL, YUREL2]
assert not [r['entry'] for r in rows('creature_template') if int(r['entry']) in NEW + NPCS]
assert not [r['entry'] for r in rows('gameobject_template') if int(r['entry']) in GO]
base_items = {int(r['entry']) for r in rows('item_template')}
assert not base_items & set(ITEMS)
gsrc = open(J(WS, 'beascendskills', 'port-retail-zone-end-to-end', 'references', 'build_loot2.py'), encoding='utf-8').read()
GEAR = {o['i']: o for o in json.load(open(r'D:\_zsdc\cls\gear.json', encoding='utf-8'))}
ns = {'G': GEAR, 'SLOTS': {5, 6, 7, 8, 9, 10, 14, 16, 20}}
exec(gsrc[gsrc.index('def family('):gsrc.index('# (armour %, weapon %) per kill')], ns)
ARM, WEP = ns['BAND']['C']
BOSSGREEN = [28153, 24340, 24439, 24440, 4947, 4939]

# ------------------------------------------------------------------ quests
QU = {
    9190007: dict(t=u"A Smell from the South 南边飘来的香味", diff=5, money=200, prev=9190006, start=ORWEYNA, end=YUREL,
                  log=u"Find Yu'relen at Nai'theren Grotto, south of Har'mara. / 到哈尔玛拉南边的奈瑟兰洞窟找尤瑞伦。",
                  desc=u"The Lightbloom is quiet for now. Old Yu'relen cooks the village meal down at Nai'theren Grotto, far to the south, and he has not sent word. Go and see him, $N. Watch for saptors on the way.$B$B光绽派暂时消停了。老尤瑞伦在南边很远的奈瑟兰洞窟张罗村里的聚餐，到现在还没捎话回来。去看看他吧，$N。路上当心迅叶龙。",
                  done=u"Speak with Yu'relen. / 与尤瑞伦交谈。",
                  offer=u"Orweyna sent you? Good timing. My back has chosen today to give up on me.$B$B奥威娜让你来的？来得正好。我这把老腰偏偏今天罢工了。",
                  req=u"", go=[], item=[], choice=[], give=[]),
    91585: dict(t=u"Fresh from the Garden 园中鲜货", diff=7, money=600, prev=9190007, start=YUREL, end=YUREL,
                log=u"Drink Yu'relen's Elixir, then collect 6 Frillfish Fillets and 4 Root Drift Jellies. / 喝下尤瑞伦的药剂，收集6份褶鱼肉片和4份根漂胶质。",
                desc=u"Age has caught up with me this morning and I have pulled something.$B$B<Yu'relen clutches his back.>$B$BStill, our village meal must be prepared. Otherwise, it will mean the loss of much more than just an empty stomach. Take a sip of my elixir for the road, and gather some ingredients.$B$B今早岁数找上门来了，我扭到了腰。$B$B<尤瑞伦扶着后腰。>$B$B可村里的聚餐还是得备好，否则丢掉的可不只是一顿饱饭。喝口我的药剂提提神，帮我采些食材来。",
                done=u"Return to Yu'relen. / 回去找尤瑞伦。",
                offer=u"Excellent. Even an old cook can work wonders with good hands beside him.$B$B好极了。身边有双好帮手，老厨子也能变出花样。",
                req=u"I hope you brought back a good harvest. / 希望你满载而归。",
                go=[(564999, 1, u"Yu'relen's Elixir drunk 喝下尤瑞伦的药剂")], item=[(9246923, 6), (9246924, 4)], choice=[28146, 28147, 28148], give=[]),
    91586: dict(t=u"Soil-Based Alternatives 土里长出的替代品", diff=6, money=500, prev=91585, start=YUREL, end=YUREL,
                log=u"Dig up 6 bags of Nutrient-Rich Soil. / 挖取6袋肥沃土壤。",
                desc=u"This meal is more than tradition--it is a promise.$B$BThe haranir, rutaani, and fungarians share no love, but in Har'mara they share this table. To honor that pact, each must be fed in their own way.$B$BThe rutaani draw sustenance through their roots. A few bags of nutrient-rich soil should do.$B$B这顿饭不只是传统，更是一个承诺。$B$B哈籁尼尔人、芦塔尼和真菌人彼此并不亲近，但在哈尔玛拉，大家同坐一张桌子。要守住约定，就得按各自的吃法招待。$B$B芦塔尼靠根须吸收养分，几袋肥沃的土壤就行。",
                done=u"Return to Yu'relen. / 回去找尤瑞伦。",
                offer=u"Good. The rutaani will accept this without complaint. Peace rests on gestures such as these.$B$B很好，芦塔尼挑不出毛病了。和睦靠的就是这样的心意。",
                req=u"I hope you bring news of good soil. / 希望你找到了好土。",
                go=[], item=[(9246926, 6)], choice=[26006, 26020, 26032], give=[]),
    91587: dict(t=u"Carcass Cuisine 腐肉佳肴", diff=8, money=900, prev=91586, start=YUREL, end=YUREL,
                log=u"Slay the Sporeglider Bloomterror north of the grotto and bring back its rind. / 消灭洞窟北边的盛放的孢子滑翔者恐魔，带回它的外皮。",
                desc=u"The fungarians are caretakers of decay, transforming death into life's renewal.$B$BThey require a sporeglider carcass to sustain their vast community. There is one--larger than most--that has taken to warding off the root drifters we need.$B$BIts end will feed many, and ease our burden. It hits hard, $N. Do not rush it.$B$B真菌人照料腐朽，把死亡化作新生。$B$B他们人口众多，需要一具孢子滑翔者的尸体。有一只个头特别大的，正把我们要用的根系漂流者赶得到处跑。$B$B解决它，能喂饱许多人，也能省我们的事。它下手很重，$N，别莽撞。",
                done=u"Return to Yu'relen. / 回去找尤瑞伦。",
                offer=u"This carcass breathes new sustenance into the fungarians and the peace we uphold. Take a weapon, you have earned it.$B$B这份食材能养活真菌人，也能养住我们守着的和睦。挑件武器吧，这是你应得的。",
                req=u"Did you bring the rind? / 外皮带回来了吗？",
                go=[(248598, 1, u"Sporeglider Bloomterror slain 消灭孢子滑翔者恐魔")], item=[(9246942, 1)], choice=[6215, 2218, 5587, 26053, 5459, 22969], give=[]),
    91588: dict(t=u"Harandar's Kitchen 哈籁恩达尔的厨房", diff=6, money=500, prev=91587, start=YUREL, end=YUREL,
                log=u"Fillet the fish, wash the greens and cook over the campfire. / 用剔鱼刀处理鱼肉，在洗菜盆清洗蔬菜，在营火上烹煮。",
                desc=u"Now comes the true work: preparing what's been gathered.$B$BThe vegetables must be washed, the bones removed, and the fish roasted. A shared meal is only worthy if made with care. Only then may the meal carry the weight of peace.$B$B真正的活儿现在才开始：收拾采回来的东西。$B$B菜要洗净，骨要剔掉，鱼要烤熟。大家分享的饭菜，只有用心做才配得上桌，也才担得起和睦二字。",
                done=u"Return to Yu'relen. / 回去找尤瑞伦。",
                offer=u"All is ready. Let those who share in this meal remember that unity is not ease--it is effort.$B$B都备齐了。愿同席的人记得：团结从来不是轻松得来的，要靠用心。$B$B路上吃的，给你带上。",
                req=u"How is the preparation coming along? / 准备得怎么样了？",
                go=[(558066, 1, u"Fish filleted 处理鱼肉"), (558065, 1, u"Salad washed 清洗蔬菜"), (558059, 1, u"Food cooked 营火烹煮")], item=[], choice=[], give=[(2287, 10), (1179, 10)]),
    91589: dict(t=u"Root Dash Delivery 送餐回村", diff=7, money=900, prev=91588, start=YUREL, end=YUREL2,
                log=u"Take the meal hamper, carry it north to Har'mara and set out the four dishes. / 领取村宴食盒，带回北边的哈尔玛拉，摆好四道菜。",
                desc=u"It's simple fare, but made with care and meaning. Please, take the hamper by my side to the gathering place in the south of the village. I am sure the villagers will show up when the food comes.$B$BI will take the slow path and meet you there.$B$B粗茶淡饭，但样样用心。请把我身边的食盒带到村子南边的聚会地。饭菜一到，村里人准会来。$B$B我腿脚慢，走小路过去，在那儿等你。",
                done=u"Speak with Yu'relen at the gathering place in Har'mara. / 到哈尔玛拉的聚会地与尤瑞伦交谈。",
                offer=u"You have done more than fill bowls--you have upheld something fragile and vital. For the peace of Har'mara, we thank you.$B$B你做的不只是盛满几只碗，你守住了一样脆弱又要紧的东西。为了哈尔玛拉的和睦，我们谢谢你。",
                req=u"Once the meal is set, our job will be done for today. / 菜摆好了，今天的活就算干完了。",
                go=[(558126, 1, u"Salad served 摆好凉拌菜"), (558129, 1, u"Fish served 摆好烤鱼"), (558135, 1, u"Ribs served 摆好肋排"), (558146, 1, u"Soil served 摆好沃土")],
                item=[(9246950, 1)], choice=[26004, 26018, 26031], give=[]),
}
assert not [r['ID'] for r in rows('quest_template') if int(r['ID']) in QU]
for v in QU.values():
    assert all(i in base_items for i in v['choice'] + [i for i, _n in v['give']]), v['t']
    assert len(v['go']) <= 4 and len(v['item']) <= 6
assert all(i in base_items for i in ARM + WEP + BOSSGREEN)

# ------------------------------------------------------------------ SQL
IDL = ', '.join(map(str, NEW + NPCS))
GL = ', '.join(map(str, sorted(GO)))
IL = ', '.join(map(str, sorted(ITEMS)))
QL = ', '.join(map(str, sorted(QU)))
DL = '%d AND %d' % (DISPLAY[0][0], DISPLAY[-1][0])
sql = [u'''-- HARA4 V1 (2026-11-26, Claude) - candidate, NOT user-tested. Stop worldserver, run on the WORLD database, restart. Safe to run twice.
-- Needs HARA3 V1 + V2, HARAFOG1 and the accepted island loot (LOOT1A V2).
SET NAMES utf8mb4;
SET @spawn_limit := 16777215;
SELECT (SELECT COUNT(*) FROM `quest_template` WHERE `ID` = 9190006) AS hara3_quest_must_be_1,
       (SELECT COUNT(*) FROM `creature_template` WHERE `entry` = 245879) AS orweyna_must_be_1,
       (SELECT COUNT(*) FROM `creature_template` WHERE `entry` = 6491) AS spirit_healer_must_be_1;
DELETE FROM `creature` WHERE `map` = 12694 AND `Comment` LIKE 'HARA4 %%';
DELETE FROM `gameobject` WHERE `map` = 12694 AND `Comment` LIKE 'HARA4 %%';
DELETE FROM `creature_template` WHERE `entry` IN (%(c)s);
DELETE FROM `creature_template_model` WHERE `CreatureID` IN (%(c)s);
DELETE FROM `creature_template_movement` WHERE `CreatureId` IN (%(c)s);
DELETE FROM `creature_loot_template` WHERE `Comment` LIKE 'HARA4 %%';
DELETE FROM `smart_scripts` WHERE `source_type` = 0 AND `entryorguid` IN (%(c)s);
DELETE FROM `creature_model_info` WHERE `DisplayID` BETWEEN %(d)s;
DELETE FROM `gameobject_template` WHERE `entry` IN (%(g)s);
DELETE FROM `gameobject_template_addon` WHERE `entry` IN (%(g)s);
DELETE FROM `gameobject_loot_template` WHERE `Comment` LIKE 'HARA4 %%';
DELETE FROM `item_template` WHERE `entry` IN (%(i)s);
DELETE FROM `quest_template` WHERE `ID` IN (%(q)s);
DELETE FROM `quest_template_addon` WHERE `ID` IN (%(q)s);
DELETE FROM `quest_offer_reward` WHERE `ID` IN (%(q)s);
DELETE FROM `quest_request_items` WHERE `ID` IN (%(q)s);
DELETE FROM `quest_poi` WHERE `QuestID` IN (%(q)s);
DELETE FROM `quest_poi_points` WHERE `QuestID` IN (%(q)s);
DELETE FROM `creature_queststarter` WHERE `quest` IN (%(q)s);
DELETE FROM `creature_questender` WHERE `quest` IN (%(q)s);
DELETE FROM `graveyard_zone` WHERE `ID` = 126942;
DELETE FROM `game_graveyard` WHERE `ID` = 126942;
SELECT COALESCE(MAX(`guid`), 0) INTO @g FROM `creature` WHERE `guid` < @spawn_limit;
SELECT COALESCE(MAX(`guid`), 0) INTO @o FROM `gameobject` WHERE `guid` < @spawn_limit;
SELECT IF(@g + 400 + 10000 < @spawn_limit AND @o + 100 + 10000 < @spawn_limit, 'guid base OK', 'ABORT: no guid room, do not continue') AS guid_check, @g AS creature_max, @o AS object_max;''' % dict(c=IDL, d=DL, g=GL, i=IL, q=QL)]
cols = '`entry`, `name`, `subname`, `minlevel`, `maxlevel`, `faction`, `npcflag`, `speed_walk`, `speed_run`, `rank`, `unit_class`, `unit_flags`, `type`, `AIName`, `MovementType`, `HealthModifier`, `DamageModifier`, `ExperienceModifier`, `RegenHealth`, `flags_extra`, `ScriptName`, `mingold`, `maxgold`'
vals, mods = [], []
for e in NEW:
    lv, hp, dmg, fac, _src, money = STAT[e]
    ctype = int(ret[str(e)]['type'])
    assert ctype != 8, e
    vals.append(u"(%d, %s, NULL, %d, %d, %d, 0, 1, 1.14286, 0, 1, 0, %d, %s, %d, %s, %s, 2, 1, 0, '', %d, %d)" % (
        e, q(u'%s %s' % (u(ret[str(e)]['name']).replace("\\'", "'"), ZH[e])), lv, lv, fac, ctype, q('SmartAI' if e == 248598 else ''), 1 if PLACE[e][2] else 0, hp, dmg, money[0], money[1]))
    for k, d_ in enumerate([d_ for d_ in DISPLAY if d_[1] == e]):
        mods.append('(%d, %d, %d, %s, 1, 0)' % (e, k, d_[0], RSCALE[(str(e), str(d_[3]))]))
for e, sub in ((YUREL, u'村宴厨师'), (YUREL2, u'村宴厨师')):
    vals.append(u"(%d, %s, %s, 12, 12, 35, 2, 1, 1.14286, 0, 1, 768, 7, '', 0, 2, 1, 1, 1, 2, '', 0, 0)" % (e, q(u"Yu'relen 尤瑞伦"), q(sub)))
    mods.append('(%d, 0, 1732, 1, 1, 0)' % e)
sql.append(u'INSERT INTO `creature_template` (%s) VALUES\n%s;' % (cols, ',\n'.join(vals)))
sql.append('INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES\n%s;' % ',\n'.join(mods))
sql.append('INSERT INTO `creature_template_movement` (`CreatureId`, `Ground`, `Swim`, `Flight`, `Rooted`, `Chase`, `Random`, `InteractionPauseTimer`) VALUES\n%s;' % ', '.join(['(%d, 1, 0, 1, 0, 0, 0, 0)' % e for e in FLY] + ['(%d, 1, 1, 0, 0, 0, 0, 0)' % e for e in SWIM]))
info = []
for did, e, mdid, rd, cscale, tex, geo in DISPLAY:
    scale = RSCALE[(str(e), str(rd))]
    info.append('(%d, %.3f, %.3f, 2, 0)' % (did, VIS[e][3] / scale, VIS[e][2] / scale))
sql.append('INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`) VALUES\n%s;' % ',\n'.join(info))
sql.append(u'''-- the Bloomterror boss poisons its target now and then
INSERT INTO `smart_scripts` (`entryorguid`, `source_type`, `id`, `link`, `event_type`, `event_phase_mask`, `event_chance`, `event_flags`, `event_param1`, `event_param2`, `event_param3`, `event_param4`, `action_type`, `action_param1`, `action_param2`, `target_type`, `comment`)
VALUES (248598, 0, 0, 0, 0, 0, 100, 0, 6000, 9000, 40000, 50000, 11, 744, 0, 2, 'Sporeglider Bloomterror - In Combat - Cast Poison');''')
head = 'INSERT INTO `creature_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`)'
for e in NEW:
    junk = STAT[e][4]
    sql.append(head + u"\nSELECT %d, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, 'HARA4 copy of %d' FROM `creature_loot_template` WHERE `Entry` = %d AND `Comment` LIKE 'LOOT1A %%' AND `QuestRequired` = 0 AND `Comment` NOT LIKE '%%初始装备';" % (e, junk, junk))
    g = []
    for group, pool, pct in ((8, ARM, 14), (9, WEP, 5)):
        g += ["(%d, %d, 0, %s, 0, 1, %d, 1, 1, 'HARA4 gear')" % (e, i, round(pct / len(pool), 4), group) for i in pool]
    if e == 248598:
        g += ["(%d, %d, 0, 0, 0, 1, 10, 1, 1, 'HARA4 boss green')" % (e, i) for i in BOSSGREEN if i not in ARM + WEP]
    sql.append(head.replace('INSERT INTO', 'INSERT IGNORE INTO') + ' VALUES\n' + ',\n'.join(g) + ';')
    sql.append('UPDATE `creature_template` SET `lootid` = %d WHERE `entry` = %d;' % (e, e))
sql.append(head + u"\nVALUES (240120, 9246923, 0, 80, 1, 1, 0, 1, 1, 'HARA4 quest'), (240113, 9246924, 0, 80, 1, 1, 0, 1, 1, 'HARA4 quest'), (248598, 9246942, 0, 100, 1, 1, 0, 1, 1, 'HARA4 quest');")
# items
icol = '`entry`, `class`, `subclass`, `SoundOverrideSubclass`, `name`, `displayid`, `Quality`, `Flags`, `BuyCount`, `maxcount`, `stackable`, `bonding`, `description`, `Material`, `AllowableClass`, `AllowableRace`, `ItemLevel`'
sql.append(u'INSERT INTO `item_template` (%s) VALUES\n%s;' % (icol, ',\n'.join(u"(%d, 12, 0, -1, %s, %d, 1, 0, 1, 0, %d, 4, '', -1, -1, -1, 1)" % (i, q(n), d_, s) for i, (n, d_, s) in sorted(ITEMS.items()))))
# objects
tv, loot = [], []
for e, (typ, disp, size, quest, cap, name) in sorted(GO.items()):
    data = [0] * 24
    if typ == 3:
        data[0], data[1], data[3] = 43, e, 1
        loot.append("(%d, %d, 0, 100, 1, 1, 0, 1, 1, 'HARA4 quest')" % (e, CHEST_ITEM[e]))
    else:
        data[1], data[3] = quest, 2000
    tv.append(u"(%d, %d, %d, %s, '', %s, '', %s, %s, '', '', 0)" % (e, typ, disp, q(name), q(cap), size, ', '.join(map(str, data))))
sql.append(u'INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `IconName`, `castBarCaption`, `unk1`, `size`, %s, `AIName`, `ScriptName`, `VerifiedBuild`) VALUES\n%s;' % (', '.join('`Data%d`' % i for i in range(24)), ',\n'.join(tv)))
sql.append('INSERT INTO `gameobject_template_addon` (`entry`, `faction`, `flags`) VALUES %s;' % ', '.join('(%d, 0, 0)' % e for e in sorted(GO)))
sql.append('INSERT INTO `gameobject_loot_template` (`Entry`, `Item`, `Reference`, `Chance`, `QuestRequired`, `LootMode`, `GroupId`, `MinCount`, `MaxCount`, `Comment`) VALUES\n%s;' % ',\n'.join(loot))
# spawns
gins = 'INSERT INTO `gameobject` (`guid`, `id`, `map`, `spawnMask`, `phaseMask`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecs`, `animprogress`, `state`, `Comment`) VALUES'
gs = ["(@o + %d, %d, 12694, 1, 1, %.2f, %.2f, %.2f, %.2f, 0, 0, %.4f, %.4f, %d, 100, 1, 'HARA4 %d')" % (i, e, x, y, z, o, math.sin(o / 2), math.cos(o / 2), 30, e) for i, (e, x, y, z, o) in enumerate(gplace, 1)]
sql.append(gins + '\n' + ',\n'.join(gs) + ';')
cins = 'INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES'
sp = ["(@g + %d, %d, 12694, 1, 1, 0, %.2f, %.2f, %.2f, %.2f, %d, %d, %d, 'HARA4 %d')" % (i, e, x, y, z, o, 180 if e == 248598 else 45, w, 1 if w else 0, e) for i, (e, x, y, z, o, w) in enumerate(place, 1)]
yz = next(f(c['position_z']) for c in R['creature'] if c['id'] == str(YUREL))
n_ = len(place)
healer_z = round(h(*GRAVE) + 0.2, 2)
npc_spawns = [(YUREL, 1357.43, 486.21, yz, 2.55, 'HARA4 %d' % YUREL), (YUREL2, VILLAGE_YU[0], VILLAGE_YU[1], round(h(*VILLAGE_YU) + 0.1, 2), 2.6, 'HARA4 %d' % YUREL2),
              (HEALER, GRAVE[0] + 4, GRAVE[1] + 2, round(h(GRAVE[0] + 4, GRAVE[1] + 2) + 0.2, 2), 3.6, 'HARA4 spirit healer')]
for k, (e, x, y, z, o, com) in enumerate(npc_spawns, 1):
    sp.append("(@g + %d, %d, 12694, 1, %d, 0, %.2f, %.2f, %.2f, %.2f, 120, 0, 0, '%s')" % (n_ + k, e, 3 if e == HEALER else 1, x, y, z, o, com))
sql.append(cins + '\n' + ',\n'.join(sp) + ';')
sql.append(u"""-- graveyard at the grotto (the core picks the nearest graveyard linked to zone 15355 on the same map)
INSERT INTO `game_graveyard` (`ID`, `Map`, `x`, `y`, `z`, `Comment`) VALUES (126942, 12694, %.1f, %.1f, %.2f, 'Nai''theren Grotto (HARA4)');
INSERT INTO `graveyard_zone` (`ID`, `GhostZone`, `Faction`, `Comment`) VALUES (126942, 15355, 0, 'Nai''theren Grotto, both factions (HARA4)');""" % (GRAVE[0], GRAVE[1], healer_z))
for qid, v in sorted(QU.items()):
    names = ['ID', 'QuestType', 'QuestLevel', 'MinLevel', 'AllowableRaces', 'RewardXPDifficulty', 'RewardMoney', 'Flags', 'LogTitle', 'LogDescription', 'QuestDescription', 'QuestCompletionLog']
    data = [qid, 2, -1, 1, 0, v['diff'], v['money'], 0, q(v['t']), q(v['log']), q(v['desc']), q(v['done'])]
    go = [((-e if e in GO else e), n, t) for e, n, t in v['go']]
    go += [(0, 0, '')] * (4 - len(go))
    for i in range(4):
        names += ['RequiredNpcOrGo%d' % (i + 1), 'RequiredNpcOrGoCount%d' % (i + 1), 'ObjectiveText%d' % (i + 1)]
        data += [go[i][0], go[i][1], q(go[i][2])]
    it = v['item'] + [(0, 0)] * (6 - len(v['item']))
    for i in range(6):
        names += ['RequiredItemId%d' % (i + 1), 'RequiredItemCount%d' % (i + 1)]
        data += [it[i][0], it[i][1]]
    gv = v['give'] + [(0, 0)] * (4 - len(v['give']))
    for i in range(4):
        names += ['RewardItem%d' % (i + 1), 'RewardAmount%d' % (i + 1)]
        data += [gv[i][0], gv[i][1]]
    ch = v['choice'] + [0] * (6 - len(v['choice']))
    for i in range(6):
        names += ['RewardChoiceItemID%d' % (i + 1), 'RewardChoiceItemQuantity%d' % (i + 1)]
        data += [ch[i], 1 if ch[i] else 0]
    sql.append(u'INSERT INTO `quest_template` (%s) VALUES\n(%s);' % (', '.join('`%s`' % n for n in names), ', '.join(map(str, data))))
    sql.append('INSERT INTO `quest_template_addon` (`ID`, `PrevQuestID`) VALUES (%d, %d);' % (qid, v['prev']))
    sql.append(u'INSERT INTO `quest_offer_reward` (`ID`, `Emote1`, `RewardText`, `VerifiedBuild`) VALUES (%d, 1, %s, 0);' % (qid, q(v['offer'])))
    if v['req']:
        sql.append(u'INSERT INTO `quest_request_items` (`ID`, `CompletionText`, `VerifiedBuild`) VALUES (%d, %s, 0);' % (qid, q(v['req'])))
    sql.append('INSERT INTO `creature_queststarter` (`id`, `quest`) VALUES (%d, %d);\nINSERT INTO `creature_questender` (`id`, `quest`) VALUES (%d, %d);' % (v['start'], qid, v['end'], qid))
# map markers: area covered by the targets; items point at their source
pos = collections.defaultdict(list)
for e, x, y, *_r in place:
    pos[e].append((x, y))
for e, x, y, *_r in gplace:
    pos[e].append((x, y))
pos[ORWEYNA] = [(1339.0, 905.0)]
pos[YUREL] = [(1357.4, 486.2)]
pos[YUREL2] = [VILLAGE_YU]
SOURCE = {9246923: 240120, 9246924: 240113, 9246926: 557572, 9246942: 248598, 9246950: 565800}
poi, pts = [], []
for qid, v in sorted(QU.items()):
    marks = [(i, pos[o[0]]) for i, o in enumerate(v['go'])] + [(4 + i, pos[SOURCE[o[0]]]) for i, o in enumerate(v['item'])] + [(-1, pos[v['end']])]
    for k, (obj_i, L) in enumerate(marks):
        cx = sum(a for a, b in L) / len(L)
        cy = sum(b for a, b in L) / len(L)
        r = max(8.0, min(70.0, max(math.hypot(a - cx, b - cy) for a, b in L)))
        poi.append('(%d, %d, %d, 12694, 20418, 0, 0, 1, 0)' % (qid, k, obj_i))
        for j, (dx, dy) in enumerate(((-r, -r), (r, -r), (r, r), (-r, r))):
            pts.append('(%d, %d, %d, %d, %d, 0)' % (qid, k, j, round(cx + dx), round(cy + dy)))
sql.append('INSERT INTO `quest_poi` (`QuestID`, `id`, `ObjectiveIndex`, `MapID`, `WorldMapAreaId`, `Floor`, `Priority`, `Flags`, `VerifiedBuild`) VALUES\n%s;' % ',\n'.join(poi))
sql.append('INSERT INTO `quest_poi_points` (`QuestID`, `Idx1`, `Idx2`, `X`, `Y`, `VerifiedBuild`) VALUES\n%s;' % ',\n'.join(pts))
EXPECT = dict(quests=len(QU), creature_templates=len(NEW + NPCS), creature_spawns=len(sp), object_templates=len(GO), object_spawns=len(gplace), items=len(ITEMS), model_info=len(DISPLAY), quest_drop_rows=5, graveyard=2)
sql.append(u'''SELECT (SELECT COUNT(*) FROM `quest_template` WHERE `ID` IN (%(q)s)) AS quests_must_be_%(quests)d,
       (SELECT COUNT(*) FROM `creature_template` WHERE `entry` IN (%(c)s)) AS creature_templates_must_be_%(creature_templates)d,
       (SELECT COUNT(*) FROM `creature` WHERE `Comment` LIKE 'HARA4 %%') AS creature_spawns_must_be_%(creature_spawns)d,
       (SELECT COUNT(*) FROM `gameobject_template` WHERE `entry` IN (%(g)s)) AS object_templates_must_be_%(object_templates)d,
       (SELECT COUNT(*) FROM `gameobject` WHERE `Comment` LIKE 'HARA4 %%') AS object_spawns_must_be_%(object_spawns)d,
       (SELECT COUNT(*) FROM `item_template` WHERE `entry` IN (%(i)s)) AS items_must_be_%(items)d,
       (SELECT COUNT(*) FROM `creature_model_info` WHERE `DisplayID` BETWEEN %(d)s) AS model_info_must_be_%(model_info)d,
       (SELECT COUNT(*) FROM `creature_loot_template` WHERE `Comment` = 'HARA4 quest') + (SELECT COUNT(*) FROM `gameobject_loot_template` WHERE `Comment` = 'HARA4 quest') AS quest_drop_rows_must_be_%(quest_drop_rows)d,
       (SELECT COUNT(*) FROM `game_graveyard` WHERE `ID` = 126942) + (SELECT COUNT(*) FROM `graveyard_zone` WHERE `ID` = 126942) AS graveyard_rows_must_be_%(graveyard)d;''' % dict(EXPECT, q=QL, c=IDL, g=GL, i=IL, d=DL))
sql = '\n'.join(sql)
undo = sql.split('SELECT COALESCE(MAX(`guid`)')[0]
undo = u'-- HARA4 V1 undo (world database)\nSET NAMES utf8mb4;\n' + undo[undo.index('DELETE FROM `creature` WHERE'):]

# ------------------------------------------------------------------ level simulation with core formulas
qx = open(J(SRV, 'QuestXP.dbc'), 'rb').read()
_c, qn, qnf, qrs = struct.unpack('<4I', qx[:16])
X = {struct.unpack_from('<I', qx, 20 + i * qrs)[0]: struct.unpack_from('<%dI' % qnf, qx, 20 + i * qrs) for i in range(qn)}
NEED = {1: 400, 2: 900, 3: 1400, 4: 2100, 5: 2800, 6: 3600, 7: 4500, 8: 5400, 9: 6500, 10: 7600, 11: 8800}


def killxp(pl, ml):
    base = pl * 5 + 45
    if ml >= pl:
        return int(base * (1 + 0.05 * min(ml - pl, 4)))
    zd = 5 if pl < 8 else 6
    return int(base * (1 - (pl - ml) / zd)) if pl - ml < zd else 0


lv, xp, sim = 1, 0, []
CHAIN = [('90957', [(6, 1)], 5), ('90958', [(8, 2), (8, 2)], 6), ('90959', [(1, 3)], 6), ('90960', [], 6),
         ('9190001', [(8, 4)], 6), ('9190002', [(8, 4)], 6), ('9190003', [(6, 5)], 6), ('9190004', [(8, 5)], 7), ('9190005', [(8, 6)], 7), ('9190006', [(6, 6)], 7),
         ('9190007', [], 5), ('91585', [(8, 7), (5, 7)], 7), ('91586', [], 6), ('91587', [(1, 9)], 8), ('91588', [], 6), ('91589', [], 7)]
for name, kills, diff in CHAIN:
    for n2, ml in kills:
        for _ in range(n2):
            xp += 2 * killxp(lv, ml)
            while lv in NEED and xp >= NEED[lv]:
                xp -= NEED[lv]
                lv += 1
    xp += X[lv][2 + min(diff + 1, 8) - 1]
    while lv in NEED and xp >= NEED[lv]:
        xp -= NEED[lv]
        lv += 1
    sim.append((name, lv, xp, NEED.get(lv, 0)))
for s_ in sim[9:]:
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


tables = ['creature', 'gameobject', 'creature_template', 'creature_template_model', 'creature_template_movement', 'creature_loot_template', 'creature_model_info', 'smart_scripts',
          'gameobject_template', 'gameobject_template_addon', 'gameobject_loot_template', 'item_template', 'quest_template', 'quest_template_addon', 'quest_offer_reward', 'quest_request_items',
          'quest_poi', 'quest_poi_points', 'creature_queststarter', 'creature_questender', 'game_graveyard', 'graveyard_zone']
schema = {t: mk(t) for t in tables}
for t in ('creature', 'gameobject'):
    if 'Comment' not in schema[t]:
        db.execute('alter table %s add column "Comment"' % t)
        schema[t].append('Comment')
for t, c_ in (('creature', 'id1'), ('creature', 'wander_distance'), ('smart_scripts', 'event_param1')):
    if c_ not in schema[t]:
        db.execute('alter table %s add column "%s"' % (t, c_))
        schema[t].append(c_)
for t, used in re.findall(r'INSERT(?: IGNORE)? INTO `(\w+)` \(([^)]*)\)', sql):
    for c_ in re.findall(r'`(\w+)`', used):
        assert c_ in schema[t], ('column not in base schema', t, c_)
db.execute('create unique index loot_pk on creature_loot_template(Entry, Item)')
db.execute('insert into quest_template(ID) values (9190006)')
db.execute('insert into creature_template(entry) values (245879)')
db.execute('insert into creature_template(entry) values (6491)')
for it_, com in ((779, 'LOOT1A x'), (2589, 'LOOT1A x'), (ARM[0], u'LOOT1A x 初始装备')):
    db.execute("insert into creature_loot_template(Entry, Item, Reference, Chance, QuestRequired, LootMode, GroupId, MinCount, MaxCount, Comment) values (150238, ?, 0, 20, 0, 1, 0, 1, 1, ?)", (it_, com))


def run(text, show):
    var = {}
    t = '\n'.join(l for l in text.splitlines() if not l.lstrip().startswith('--'))
    stm, cur = [], ''
    for part in t.split(';'):
        cur += part
        if cur.replace("\\\\", '').count("'") % 2 == 0:
            stm.append(cur)
            cur = ''
        else:
            cur += ';'
    assert not cur.strip()
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
            nm_ = [d[0] for d in c.description]
            for r in c.fetchall():
                row = dict(zip(nm_, r))
                print('  ', row)
                for k_, v_ in row.items():
                    m2 = re.search(r'_must_be_(\d+)$', k_)
                    assert not m2 or v_ == int(m2.group(1)), (k_, v_)


seed = {t: db.execute('select count(*) from %s' % t).fetchone()[0] for t in tables}
run(sql, True)
snap = [db.execute('select count(*) from %s' % t).fetchone()[0] for t in tables]
run(sql, False)
assert snap == [db.execute('select count(*) from %s' % t).fetchone()[0] for t in tables]
bad = db.execute('select l.Item from creature_loot_template l where l.Comment like "HARA4 %" and l.Item >= 9000000 and l.Item not in (select entry from item_template)').fetchall()
assert not bad
run(undo, False)
assert seed == {t: db.execute('select count(*) from %s' % t).fetchone()[0] for t in tables}, 'undo leaves rows'
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
    wr(u'06_撤销/原Patch-YB/DBFilesClient/' + n, old)
    hashes.append((u'客户端 YB ' + n, sha(old), sha(new)))
wr(u'02_导入Patch-XA.mpq/DBFilesClient/Item.dbc', item1)
wr(u'06_撤销/原Patch-XA/DBFilesClient/Item.dbc', item0)
hashes.append((u'客户端 XA Item.dbc', sha(item0), sha(item1)))
wr(u'03_覆盖到客户端根目录/Data/Retail/aliases_maps.csv', csv_new)
wr(u'06_撤销/原客户端根目录/Data/Retail/aliases_maps.csv', csv_old)
hashes.append((u'客户端 aliases_maps.csv', sha(csv_old), sha(csv_new)))
for n, (old, new) in server.items():
    wr(u'04_服务端_Data_dbc/' + n, new)
    wr(u'06_撤销/原服务端dbc/' + n, old)
    hashes.append((u'服务端 ' + n, sha(old), sha(new)))
wr(u'05_服务端_SQL/world_hara4.sql', sql)
wr(u'06_撤销/undo_hara4.sql', undo)
readback = u'、'.join(str(v) for v in EXPECT.values())
table = '\n'.join(u'| %s | `%s` | `%s` |' % (h_[0], h_[1][:12], h_[2][:12]) for h_ in hashes)
wr(u'README_覆盖与测试说明.md', u'''
# HARA4 V1：南下奈瑟兰洞窟——村宴任务线(候选，实机未测)

前提：HARA3 V1 + V2、HARAFOG1、流放者之岛掉落(LOOT1A V2)已装。

## 内容
打怪只占一部分：赶路、采食材、挖土、打首领、做饭、送餐回村。

| 任务 | 名称 | 做什么 | 奖励 | 来源 |
|---|---|---|---|---|
| 9190007 | 南边飘来的香味 | 奥威娜 → 南边 450 码洞窟找尤瑞伦 | 经验、铜币 | 新设计(引路) |
| 91585 | 园中鲜货 | 喝药剂；褶鱼肉片 6、根漂胶质 4 | 护腕三选一(绿) | 零售 |
| 91586 | 土里长出的替代品 | 点土堆挖 6 袋土 | 裤子三选一(绿) | 零售 |
| 91587 | 腐肉佳肴 | 首领：孢子滑翔者恐魔(9 级，约三倍血，会上毒) | 武器六选一(绿)，首领另必掉一件绿装 | 零售 |
| 91588 | 哈籁恩达尔的厨房 | 点剔鱼刀、洗菜盆、营火 | 食物和饮料各 10 | 零售 |
| 91589 | 送餐回村 | 拿食盒，回村南聚会地摆 4 道菜，向那里的尤瑞伦交任务 | 胸甲三选一(绿) | 零售 |

- 估算(单人，只打任务需要的数量)：%(sim)s
- 洞窟一带另有零售原位置的野怪：洞窟迅虫(黄名)、急躁的甲虫(黄名)、**流涎的迅叶龙(红名，会主动攻击)**。
- 洞窟前是一片水潭，**褶鱼照零售放在水下**，要下水打。
- 洞窟新增复活点和灵魂医者。
- 和零售不同：怪物等级按 7–9 级重定；零售送餐任务原有 5 个步骤，老版本任务最多 4 个交互目标，食盒改成背包物品；道具外观用老版本自带模型；尤瑞伦用暗夜精灵代替；对话为中英双语。

## 部署(关游戏、停服)
1. 备份 `Data\\Patch-YB.mpq`、`Data\\Patch-XA.mpq`、`Data\\Retail\\aliases_maps.csv`、服务端两个生物 dbc。核对下表"输入"哈希，不相等先告诉我。
2. `01_导入Patch-YB.mpq` 的两个 dbc 导入 **Patch-YB**。
3. `02_导入Patch-XA.mpq` 的 `Item.dbc` 导入 **Patch-XA**(任务物品图标)。
4. `03_覆盖到客户端根目录` 覆盖到客户端根目录。
5. `04_服务端_Data_dbc` 覆盖服务端 `Data\\dbc`。
6. world 库执行 `05_服务端_SQL\\world_hara4.sql`。开头三项都是 1、`guid base OK`；末尾依次 %(rb)s。
7. 启动服务端，删客户端 `Cache\\WDB`。

| 文件 | 输入 | 输出 |
|---|---|---|
%(t)s

## 测试
接着做：交掉 9190006 后，奥威娜给 9190007。直接去洞窟：`.go xyz 1352 478 1336 12694`；村南聚会地：`.go xyz 1174 800 1336 12694`。

| 重点看 | |
|---|---|
| 新模型 | 褶鱼、首领(大型飞行生物)、洞窟迅虫：贴图、动作、有没有方形色块；大小是否合适 |
| 水里的褶鱼 | 洞窟前水潭里游动(需下水打，注意换气)；是否正常游、追击、掉鱼肉 |
| 够不够得着 | 漂流者、迅虫悬空约 2–3 码，近战能否打到；首领点选和近战距离 |
| 物品 | 背包里 5 种任务物品有图标和名字 |
| 点击物体 | 土堆能挖且会刷新；药剂、刀、盆、营火、四道菜能点、进度增加；位置是否悬空或埋地(洗菜盆在高处) |
| 首领强度 | 单人能否打过 |
| 复活 | 洞窟附近死亡应在洞窟复活点 |
| 地图标记 | 6 个任务在世界地图上的位置 |

## 撤销
执行 `06_撤销\\undo_hara4.sql`，换回 `06_撤销` 里的 dbc、csv，重启。

## 未做与边界
- 全部未实机测试(SQL 只做过离线模拟；新模型只做过不带贴图的姿势渲染，图中翅膀处的方片推测是光效面片，需进游戏确认)。
- 尤瑞伦在村南聚会地一直站着(零售是任务进行时才出现)。
- 下一批：年纪神龛(再往西南，哈加尔的 5 个原版任务)和传送暴风城。
''' % dict(t=table, rb=readback, sim=u'做完 91589 约 %d 级(%d/%d)' % sim[-1][1:]))
wr(u'memory.md', u'''
# HARA4 V1 记录(2026-11-26，Claude)
用户："测试都通过了 继续下一批的任务的制作 往外面的地图 延伸下 感觉 就在这一片杀怪 太无聊了"(通过项：HARA3 V2、HARAFOG1、HARAVEND1)。
任务 9190007 + 零售 91585-91589(奈瑟兰洞窟)；任务物品 9246923/4/6/42/50；模型数据 710115-710117，显示 710138 起；坟场 126942。
已读：port-retail-zone-end-to-end、port-retail-quest-chain-to-wotlk、当日协作说明。脚本 D:\\_zsdc\\hara(out_survey.py、hubs_detail.py、models4/、build_hara4.py)。状态：候选，未实测。''')
wr(u'tutor.md', u'''
# 大白话：让任务线不无聊
零售地图往南本来就有一个做饭的任务点。照搬它：先赶路，再采集、挖土、打一个首领、点炊具做饭、把饭送回村。打怪只是其中一步。''')
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


app(J(WS, u'协作说明_并行开发.md'), u'| 2026-11-26 | Claude | HARA4 V1：哈籁尼尔洞窟任务线 9190007、91585-91589 | 候选(实机未测) | YB CreatureModelData +3(710115-710117)、CreatureDisplayInfo +%d(710138 起)；**XA Item.dbc +5(9246923/4/6/42/50)**；aliases_maps.csv；服务端两张生物 DBC；world 生物/物体/物品/任务、坟场 126942 | 现场生效版为基底(见台账) | 000Ascendupdate20261126/claudefix_…HARA4_V1… | Codex 改 YB 生物表或 XA Item.dbc 请以本包装后版本为底 |' % len(DISPLAY), u'HARA4 V1：哈籁尼尔')
app(J(WS, u'台账_YB_XA共享文件哈希.md'), u'## 2026-11-26 HARA4 V1(Claude，待用户安装)\n|文件|输入|输出|\n|---|---|---|\n' + '\n'.join(u'|%s|%s|%s|' % h_ for h_ in hashes), u'HARA4 V1(Claude')
MEM = r'<user-profile>\.claude\projects\d--000rebornWOW-000RebornWOWHighForkPRO-beascendLauncher-wowlauncher2026-CataLauncher-rebornWOW\memory\haranir-start-port.md'
app(MEM, u'11-26: user confirmed HARA3 V2, HARAFOG1, HARAVEND1 pass ("测试都通过了"), asked quests to extend outward (killing in one area is boring) -> HARA4 V1 delivered (grotto cooking chain 9190007 + retail 91585-91589), untested. Next HARA5: Shrine of Ages retail 91872-91876 + teleport to Stormwind.', u'HARA4 V1 delivered')
print(P)
for h_ in hashes:
    print(h_[0], h_[1][:12], '->', h_[2][:12])
