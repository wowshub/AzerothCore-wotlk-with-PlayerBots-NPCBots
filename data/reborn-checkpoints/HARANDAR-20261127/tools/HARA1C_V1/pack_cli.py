# -*- coding: utf-8 -*-
"""Client package HARA1C: Harandar map rows, world map, loading screen, minimaps of both maps."""
import struct, io, os, sys, glob, shutil, hashlib, pickle, csv
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', line_buffering=True)
W = r'D:\_zsdc\maps2'
J = os.path.join
B = chr(92)
WS = r'D:\000rebornWOW\000RebornWOWHighForkPRO'
CLIENT = r'C:\000ref\WarcraftXL试装_client'
DAY = J(WS, '000Ascendupdate', '000Ascendupdate20261126')
P = J(DAY, u'claudefix_20261126_阶段HARA1C_V1_哈籁尼尔地图客户端_世界地图加载图与两图小地图_Claude')
T = pickle.load(open(J(W, 'client_tables.pkl'), 'rb'))
sha = lambda b: hashlib.sha256(b).hexdigest()
G = r'D:\_zsdc\wago69587'
rd = lambda n: list(csv.DictReader(open(J(G, n), encoding='utf-8-sig')))


def load_order(name):
    """root patches in the client's order: common < patch < patch-2 .. patch-9 < patch-A .. patch-ZZ, locale patches by number."""
    n = name.lower().split(B)[-1][:-4]
    if name.lower().startswith('enus'):
        return (3, n) if n.startswith('patch-enus') else (0, n)
    if n.startswith('patch-'):
        s = n[6:]
        return (4 if not s.isdigit() else 2, len(s) if not s.isdigit() else 0, s) if False else ((2, s) if s.isdigit() else (4, s))
    return (1, n)


def loaded(name):
    n = name.lower().split(B)[-1]
    return ' ' not in n and 'diable' not in n and 'disable' not in n and (not n.startswith('patch-enus') or n[:-4].split('-')[-1] in ('2', '3', '4', '5'))


def winner(entries):
    live = [(f, d) for f, d in entries if loaded(f)]
    return sorted(live, key=lambda x: load_order(x[0]))[-1], [f for f, _ in sorted(live, key=lambda x: load_order(x[0]))]


class Dbc:
    def __init__(self, name):
        (self.src, d), self.all = winner(T['found'][name])
        _, n, nf, rs, ss = struct.unpack_from('<4sIIII', d)
        self.name, self.nf, self.rs = name, nf, rs
        self.raw = d
        self.recs = [list(struct.unpack_from('<%dI' % (rs // 4), d, 20 + i * rs)) for i in range(n)]
        self.strs = bytearray(d[20 + n * rs:])
        self.before = n

    def get(self, k):
        return next((r for r in self.recs if r[0] == k), None)

    def text(self, o):
        return self.strs[o:self.strs.index(0, o)].decode('utf-8', 'replace')

    def add(self, s):
        o = len(self.strs)
        self.strs += s.encode('utf-8') + b'\0'
        return o

    def blob(self):
        return struct.pack('<4sIIII', b'WDBC', len(self.recs), self.nf, self.rs, len(self.strs)) + b''.join(struct.pack('<%dI' % (self.rs // 4), *r) for r in self.recs) + bytes(self.strs)


fb = lambda v: struct.unpack('<I', struct.pack('<f', v))[0]
bf = lambda v: struct.unpack('<f', struct.pack('<I', v))[0]

if __name__ == '__main__':
    mp, at, wma, ls, lq, wmc = (Dbc(n) for n in ('Map.dbc', 'AreaTable.dbc', 'WorldMapArea.dbc', 'LoadingScreens.dbc', 'LiquidType.dbc', 'WorldMapContinent.dbc'))
    tables = (mp, at, wma, ls, lq, wmc)
    for t in tables:
        print('%-22s base %-22s rows %6d  (also in %s)' % (t.name, t.src, t.before, [f for f in t.all if f != t.src]))
    assert mp.get(12175) and mp.get(12570) and at.get(12175), 'the winning archive lacks the earlier maps'
    if '--inspect' in sys.argv:
        for t, k in ((mp, 12570), (mp, 12175)):
            r = t.get(k)
            print('Map', k, 'dir', t.text(r[1]), 'area', r[22], 'loading', r[57], 'exp', r[63])
        print('WMA rows of 12570/12175:', [(r[0], r[1], r[2], wma.text(r[3]), [round(bf(r[i]), 1) for i in (4, 5, 6, 7)], r[8:]) for r in wma.recs if r[1] in (12570, 12175)])
        print('continent rows:', [(r[0], r[1], r[2:6], [round(bf(v), 2) for v in r[6:13]], r[13:]) for r in wmc.recs])
        print('loading rows of those maps:', [(r[0], ls.text(r[1]), ls.text(r[2]), r[3:]) for r in ls.recs if r[0] in (mp.get(12570)[57], mp.get(12175)[57])])
        print('area rows sample:', [at.recs[i][:6] for i in range(len(at.recs) - 3, len(at.recs))])
        print('liquid has', {k: bool(lq.get(k)) for k in (941, 1177, 1055, 1132, 1222, 1255)})
        print('trs', [(f, len(d), loaded(f)) for f, d in T['trs']])
        raise SystemExit

    assert not os.path.exists(P), P
    NEW_MAP, ZONE, LS_ID, WMA_ZONE, WMA_CONT, CONT_ID = 12694, 15355, 9404, 20418, 20419, 19
    assert not mp.get(NEW_MAP) and not ls.get(LS_ID) and not wma.get(WMA_ZONE) and not wma.get(WMA_CONT) and not wmc.get(CONT_ID)
    r = list(mp.get(12570))
    r[0] = NEW_MAP
    r[1] = mp.add('Harandar')
    nm = mp.add(u'哈籁尼尔出生地')
    old_name = mp.get(12570)[5]
    for i in range(5, 21):
        if r[i] == old_name:
            r[i] = nm
    assert r[5] == nm
    r[22], r[57] = ZONE, LS_ID
    mp.recs.append(r)
    ls.recs.append([LS_ID, ls.add('Harandar'), ls.add('Interface' + B + 'Glues' + B + 'LoadingScreens' + B + 'LoadScreenHarandar.blp'), 1])
    # retail UiMapAssignment of 2694: x -2520.83..2527.08, y -3993.75..3579.17 (left/right are Y, top/bottom are X)
    bounds = [fb(3579.17), fb(-3993.75), fb(2527.08), fb(-2520.83)]
    name = wma.add('Harandar')
    wma.recs.append([WMA_ZONE, NEW_MAP, ZONE, name] + bounds + [0xFFFFFFFF, 0, WMA_CONT])
    wma.recs.append([WMA_CONT, NEW_MAP, 0, name] + bounds + [0xFFFFFFFF, 0, 0])
    c = list(next(x for x in wmc.recs if x[1] == 12570))
    c[0], c[1] = CONT_ID, NEW_MAP
    wmc.recs.append(c)
    used = {x[3] for x in at.recs}
    free = [b for b in range(4095, 0, -1) if b not in used]
    tpl = at.get(13769)
    en = {x['ID']: x for x in rd('AreaTable.csv')}
    zh = {x['ID']: x for x in rd('AreaTable_zh.csv')}
    tiles_areas = pickle.load(open(J(W, 'hara_areas.pkl'), 'rb'))['areas']
    want = [(ZONE, 0, NEW_MAP)] + [(a, ZONE, NEW_MAP) for a in sorted(tiles_areas) if a not in (0, ZONE)] + [(12694, 0, 12694), (12570, 0, 12570)]
    added = 0
    for aid, parent, cont in want:
        if at.get(aid):
            continue
        row = list(tpl)
        row[0], row[1], row[2], row[3] = aid, cont, parent, free.pop(0)
        text = {12694: u'哈籁尼尔出生地', 12570: u'禁忌离岛'}.get(aid) or zh.get(str(aid), {}).get('AreaName_lang') or en.get(str(aid), {}).get('AreaName_lang') or 'Harandar'
        off = at.add(text)
        old = tpl[11]
        for i in range(11, 27):
            if row[i] == old:
                row[i] = off
        at.recs.append(row)
        added += 1
    w13 = lq.get(13)
    for k in (1055, 1132, 1222, 1255):
        assert not lq.get(k)
        row = list(w13)
        row[0] = k
        lq.recs.append(row)
    d1 = J(P, u'01_导入Patch-X.mpq', 'DBFilesClient')
    und = J(P, u'04_撤销', u'原Patch-X', 'DBFilesClient')
    os.makedirs(d1)
    os.makedirs(und)
    hashes = []
    for t in tables:
        out = t.blob()
        open(J(d1, t.name), 'wb').write(out)
        open(J(und, t.name), 'wb').write(t.raw)
        hashes.append((t.name, sha(t.raw), sha(out), t.before, len(t.recs)))
    d2 = J(P, u'02_导入Patch-ZC.mpq')
    shutil.copytree(J(W, 'art'), d2)
    trs_old = dict(T['trs'])['Patch-ZC.mpq']
    add = open(J(W, 'md5translate_add.trs'), 'rb').read()
    assert b'dir: ForbiddenReach' not in trs_old and b'dir: Harandar' not in trs_old
    trs_new = trs_old + (b'' if trs_old.endswith(b'\n') else b'\r\n') + add
    open(J(d2, 'textures', 'Minimap', 'md5translate.trs'), 'wb').write(trs_new)
    os.makedirs(J(P, u'04_撤销', u'原Patch-ZC', 'textures', 'Minimap'))
    open(J(P, u'04_撤销', u'原Patch-ZC', 'textures', 'Minimap', 'md5translate.trs'), 'wb').write(trs_old)
    hashes.append(('md5translate.trs (Patch-ZC)', sha(trs_old), sha(trs_new), trs_old.count(b'.blp\t'), trs_new.count(b'.blp\t')))
    # every minimap line must point at a delivered file
    missing = [l for l in add.decode().split('\r\n') if '\t' in l and not os.path.exists(J(d2, 'textures', 'Minimap', l.split('\t')[1]))]
    assert not missing, missing[:3]
    live = open(J(CLIENT, 'Data', 'Retail', 'aliases_maps.csv'), 'rb').read()
    line = b'5413167;World' + B.encode() + b'Maps' + B.encode() + b'Harandar' + B.encode() + b'Harandar.wdt'
    assert b'Harandar' not in live
    new = live + (b'' if live.endswith(b'\n') else b'\r\n') + line + b'\r\n'
    for rel, data in ((u'03_覆盖到客户端根目录', new), (J(u'04_撤销', u'原客户端根目录'), live)):
        os.makedirs(J(P, rel, 'Data', 'Retail'))
        open(J(P, rel, 'Data', 'Retail', 'aliases_maps.csv'), 'wb').write(data)
    hashes.append(('aliases_maps.csv', sha(live), sha(new), live.count(b';'), new.count(b';')))
    pickle.dump(hashes, open(J(W, 'cli_hashes.pkl'), 'wb'))
    print('areas added', added, '| minimap files', len(glob.glob(J(d2, 'textures', 'Minimap', '*.blp'))))
    for h in hashes:
        print('  %-28s %s -> %s  rows %d -> %d' % (h[0], h[1][:12], h[2][:12], h[3], h[4]))
