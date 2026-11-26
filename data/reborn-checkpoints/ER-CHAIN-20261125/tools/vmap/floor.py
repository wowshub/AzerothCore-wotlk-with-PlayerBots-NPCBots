"""Floor heights under given world points, from the converted citadel collision triangles (same triangle filter as the vmap extractor)."""
import struct, glob, math, sys
C = 17066.666666


def chunks(d, o=0):
    while o + 8 <= len(d):
        t = d[o:o + 4][::-1]; n = struct.unpack_from('<I', d, o + 4)[0]
        yield t, d[o + 8:o + 8 + n]
        o += 8 + n


# placement of 3069822 in tile 34_30 (any tile carrying uid 25364592 gives the same values)
d = open(r'D:\_zsdc\er_srv\out2\ExilesReach_34_30.adt', 'rb').read()
ch = {}
for t, b in chunks(d):
    ch.setdefault(t, b)
mw = ch[b'MWMO']; off = {}; c = 0
for x in mw.split(b'\0'):
    if x:
        off[c] = x.decode()
    c += len(x) + 1
ids = struct.unpack('<%dI' % (len(ch[b'MWID']) // 4), ch[b'MWID'])
md = ch[b'MODF']
place = None
for k in range(len(md) // 64):
    nid, uid = struct.unpack_from('<2I', md, k * 64)
    if off[ids[nid]].endswith('3069822.wmo'):
        place = (struct.unpack_from('<3f', md, k * 64 + 8), struct.unpack_from('<3f', md, k * 64 + 20))
pos, rot = place
print('placement pos', [round(v, 2) for v in pos], 'rot', [round(v, 2) for v in rot])
tris = []
for p in sorted(glob.glob(r'D:\_zsdc\vm12175\wmo\3069822_*.wmo')):
    top = dict(chunks(open(p, 'rb').read()))
    sub = dict(chunks(top[b'MOGP'], 68))
    mopy, vi, vt = sub[b'MOPY'], sub[b'MOVI'], sub[b'MOVT']
    V = [struct.unpack_from('<3f', vt, i * 12) for i in range(len(vt) // 12)]
    for t in range(len(mopy) // 2):
        f = mopy[t * 2]
        if not ((f & 0x08) or ((f & 0x20) and not (f & 0x04))):
            continue
        i = struct.unpack_from('<3H', vi, t * 6)
        tris.append((V[i[0]], V[i[1]], V[i[2]]))
print('collision triangles', len(tris))


def transform(v, yaw):
    x, y, z = v
    a = math.radians(yaw)
    X = x * math.cos(a) - y * math.sin(a)
    Y = x * math.sin(a) + y * math.cos(a)
    return (C - pos[2] + X, C - pos[0] + Y, pos[1] + z)


def floors(T, px, py):
    out = []
    for a, b, c in T:
        den = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1])
        if abs(den) < 1e-9:
            continue
        l1 = ((b[1] - c[1]) * (px - c[0]) + (c[0] - b[0]) * (py - c[1])) / den
        l2 = ((c[1] - a[1]) * (px - c[0]) + (a[0] - c[0]) * (py - c[1])) / den
        l3 = 1 - l1 - l2
        if l1 >= -1e-6 and l2 >= -1e-6 and l3 >= -1e-6:
            out.append(l1 * a[2] + l2 * b[2] + l3 * c[2])
    return sorted(out)


PTS = {'entrance': (855.40, -1384.25, 176.63), 'p1 Tunk': (753.35, -1441.73, 176.63), 'p2 Gorgroth': (852.47, -1625.35, 219.04),
       'p3 dragon': (753.59, -1439.72, 272.74), 'cave833': (833.03, -1599.69, 219.05)}
best = []
for yaw in (rot[1], rot[1] + 180, rot[1] - 90, rot[1] + 90, -rot[1], 180 - rot[1], 270 - rot[1], 90 - rot[1]):
    T = [tuple(transform(v, yaw) for v in t) for t in tris]
    res, score = {}, 0.0
    for nm, (x, y, z) in PTS.items():
        f = floors(T, x, y)
        below = [h for h in f if h <= z + 1.5]
        res[nm] = (round(below[-1], 2) if below else None, [round(h, 1) for h in f][:12])
        score += min(abs(z - below[-1]), 30) if below else 30
    best.append((score, yaw, res))
best.sort(key=lambda r: r[0])
for score, yaw, res in best[:2]:
    print('yaw', round(yaw, 2), 'score', round(score, 1))
    for k, v in res.items():
        print('   ', k, 'floor below =', v[0], ' (point z', PTS[k][2], ') all surfaces', v[1])
