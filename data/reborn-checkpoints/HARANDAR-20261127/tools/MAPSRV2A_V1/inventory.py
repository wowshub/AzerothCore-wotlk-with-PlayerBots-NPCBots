# -*- coding: utf-8 -*-
"""Area ids and liquid types used by the converted tiles and buildings, against the live server / test-client tables."""
import struct, io, os, sys, glob, collections, pickle
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
exec(open(r'D:\_zsdc\maps2\prep.py', encoding='utf-8').read().split("if __name__")[0].replace("sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')", ''))
SRV = r'D:\000rebornWOW\000RebornWOWHighForkPRO\beascendserver\wowshub_playerbot_npcbot_newrace20261122Ascend'
D = J(SRV, 'Data', 'dbc')


def dbc(path):
    d = open(path, 'rb').read()
    _, n, nf, rs, ss = struct.unpack_from('<4sIIII', d)
    return {struct.unpack_from('<I', d, 20 + i * rs)[0]: struct.unpack_from('<%dI' % (rs // 4), d, 20 + i * rs) for i in range(n)}, nf


liq, _ = dbc(J(D, 'LiquidType.dbc'))
at, _ = dbc(J(D, 'AreaTable.dbc'))
mp, _ = dbc(J(D, 'Map.dbc'))
print('server Map.dbc has 12175/12570/12694:', [k in mp for k in (12175, 12570, 12694)])
res = {}
for mid, (d, _f) in MAPS.items():
    areas, tl, wl = collections.Counter(), collections.Counter(), collections.Counter()
    wmo = set()
    for p in glob.glob(J(W, 'adt%d' % mid, d + '_*.adt')):
        data = open(p, 'rb').read()
        for t, b in chunks(data):
            if t == b'MCNK':
                areas[struct.unpack_from('<I', b, 0x34)[0]] += 1
            elif t == b'MH2O':
                for k in range(256):
                    off, count, _a = struct.unpack_from('<3I', b, k * 12)
                    for layer in range(count):
                        tl[struct.unpack_from('<H', b, off + layer * 24)[0]] += 1
            elif t == b'MWMO':
                wmo.update(x.decode('latin1').replace(B, '/').lower() for x in b.split(b'\0') if x)
    for n in wmo:
        base = n.split('/')[-1][:-4]
        for g in glob.glob(J(W, 'wmo', base + '_*.wmo')):
            top = dict(chunks(open(g, 'rb').read()))
            m = top.get(b'MOGP')
            if m:
                sub = dict(chunks(m[68:]))
                if b'MLIQ' in sub:
                    wl[struct.unpack_from('<I', m, 52)[0]] += 1
    res[mid] = dict(areas=dict(areas), terrain_liquid=dict(tl), wmo_liquid=dict(wl), wmo=sorted(wmo))
    print('=====', mid, d)
    print(' area ids (chunks):', areas.most_common(30), 'distinct', len(areas))
    print('   already in server AreaTable:', [a for a in areas if a in at])
    print(' terrain liquid types:', dict(tl))
    print('   not in server LiquidType:', sorted(k for k in tl if k not in liq))
    print(' building liquid types (MOGP value, groups with water):', dict(wl))
    print('   not in server LiquidType:', sorted(k for k in wl if k not in liq))
pickle.dump(res, open(J(W, 'inventory.pkl'), 'wb'))
