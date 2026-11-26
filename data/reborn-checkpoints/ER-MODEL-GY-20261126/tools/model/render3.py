# -*- coding: utf-8 -*-
"""Offline pose render of a converted (264) M2: python render.py out.png dir base seq[:variant] ...
variant 'raw' reads external keyframes relative to the file start, 'afm2' relative to the AFM2 chunk."""
import struct, sys, os, math
from PIL import Image, ImageDraw

out, root, base = sys.argv[1], sys.argv[2], sys.argv[3]
m = open(os.path.join(root, base + '.m2'), 'rb').read()
sk = open(os.path.join(root, base + '00.skin'), 'rb').read()
U = lambda b, p: struct.unpack_from('<I', b, p)[0]
H = lambda b, p: struct.unpack_from('<H', b, p)[0]
ns, so = U(m, 0x1c), U(m, 0x20)
nb, bo = U(m, 0x2c), U(m, 0x30)
nv, vo = U(m, 0x3c), U(m, 0x40)
ncombo, combo = U(m, 0x78), U(m, 0x7c)
verts = []
for i in range(nv):
    p = vo + 48 * i
    verts.append((struct.unpack_from('<3f', m, p), struct.unpack_from('<4B', m, p + 12), struct.unpack_from('<4B', m, p + 16)))
snv, sov, snt, sot, snp, sop, snsub, sosub = struct.unpack_from('<8I', sk, 4)
vmap = [H(sk, sov + 2 * i) for i in range(snv)]
tris = [H(sk, sot + 2 * i) for i in range(snt)]
subs = []
for s in range(snsub):
    q = sosub + 48 * s
    sid, level, vs, vc, ist, ic, bc, bci = struct.unpack_from('<8H', sk, q)
    subs.append((sid, level, vs, vc, ist + (level << 16), ic, bc, bci))


def mat_mul(a, b):
    return [[a[r][0] * b[0][c] + a[r][1] * b[1][c] + a[r][2] * b[2][c] + a[r][3] * b[3][c] for c in range(4)] for r in range(4)]


def trs(t, q, s, pivot):
    x, y, z, w = q
    n = math.sqrt(x * x + y * y + z * z + w * w) or 1
    x, y, z, w = x / n, y / n, z / n, w / n
    R = [[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
         [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
         [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]]
    M = [[R[r][c] * s[c] for c in range(3)] + [0] for r in range(3)] + [[0, 0, 0, 1]]
    for r in range(3):
        M[r][3] = pivot[r] + t[r] - sum(M[r][c] * pivot[c] for c in range(3))
    return M


def load_seq(seq, variant):
    sid, var = struct.unpack_from('<HH', m, so + 64 * seq)
    flags = U(m, so + 64 * seq + 12)
    j = seq
    while U(m, so + 64 * j + 12) & 0x40:
        j = H(m, so + 64 * j + 62)
    if j != seq:
        return load_seq(j, variant)
    if flags & 0x20:
        return m, sid, var, flags
    raw = open(os.path.join(root, base + '%04d-%02d.anim' % (sid, var)), 'rb').read()
    o, ch = 0, {}
    while o + 8 <= len(raw) and raw[o:o + 3] == b'AFS' or o + 8 <= len(raw) and raw[o:o + 3] == b'AFM':
        t = raw[o:o + 4]
        z = U(raw, o + 4)
        ch[t] = raw[o + 8:o + 8 + z]
        o += 8 + z
    if variant == 'raw':
        buf = raw
    elif variant == 'afm2':
        buf = ch.get(b'AFM2', raw)
    else:
        buf = ch.get(b'AFSB', raw)
    return buf, sid, var, flags


def sample(p, seq, t, buf, kind, default):
    gs = H(m, p + 2)
    nt, to, nk, ko = struct.unpack_from('<4I', m, p + 4)
    i = 0 if gs != 0xffff else seq
    if i >= nt:
        return default
    src = m if gs != 0xffff else buf
    tc, tp = struct.unpack_from('<II', m, to + 8 * i)
    kc, kp = struct.unpack_from('<II', m, ko + 8 * i)
    if not kc:
        return default
    times = [U(src, tp + 4 * k) for k in range(tc)] if tp + 4 * tc <= len(src) else [0]
    a = 0
    while a + 1 < len(times) and times[a + 1] <= t:
        a += 1
    b = min(a + 1, kc - 1)
    a = min(a, kc - 1)
    f = 0 if b == a or times[b] == times[a] else max(0, min(1, (t - times[a]) / (times[b] - times[a])))

    def key(k):
        if kind == 'q':
            if kp + 8 * k + 8 > len(src):
                return default
            return [(v + 32768 if v < 0 else v - 32767) / 32767 for v in struct.unpack_from('<4h', src, kp + 8 * k)]
        if kp + 12 * k + 12 > len(src):
            return default
        return list(struct.unpack_from('<3f', src, kp + 12 * k))
    x, y = key(a), key(b)
    if kind == 'q' and sum(i * j for i, j in zip(x, y)) < 0:
        y = [-v for v in y]
    return [i + (j - i) * f for i, j in zip(x, y)]


def pose(seq, t, variant):
    buf = load_seq(seq, variant)[0]
    j = seq
    while U(m, so + 64 * j + 12) & 0x40:
        j = H(m, so + 64 * j + 62)
    world = []
    for b in range(nb):
        q = bo + 88 * b
        parent = struct.unpack_from('<h', m, q + 8)[0]
        pivot = struct.unpack_from('<3f', m, q + 76)
        M = trs(sample(q + 16, j, t, buf, 'v', [0, 0, 0]), sample(q + 36, j, t, buf, 'q', [0, 0, 0, 1]), sample(q + 56, j, t, buf, 'v', [1, 1, 1]), pivot)
        world.append(M if parent < 0 else mat_mul(world[parent], M))
    pts = [None] * snv
    for sid, level, vs, vc, ist, ic, bc, bci in subs:
        for i in range(vs, vs + vc):
            pos, w, idx = verts[vmap[i]]
            loc = struct.unpack_from('<4B', sk, sop + 4 * i)
            r = [0, 0, 0]
            for k in range(4):
                if not w[k]:
                    continue
                g = H(m, combo + 2 * (bci + loc[k]))
                M = world[g]
                for a in range(3):
                    r[a] += (w[k] / 255) * (M[a][0] * pos[0] + M[a][1] * pos[1] + M[a][2] * pos[2] + M[a][3])
            pts[i] = r
    return pts


W, HH = 260, 320
GEO = {int(x) for x in os.environ.get('GEO', '').split(',') if x}
SC = float(os.environ.get('SCALE', '90'))
rows = []
for spec in sys.argv[4:]:
    parts = spec.split(':')
    seq = int(parts[0])
    variant = parts[1] if len(parts) > 1 else 'afsb'
    sid = H(m, so + 64 * seq)
    dur = U(m, so + 64 * seq + 4)
    row = Image.new('RGB', (W * 5, HH), (30, 30, 30))
    for col, (frac, view) in enumerate([(0.0, 'side'), (0.3, 'side'), (0.6, 'side'), (0.3, 'front'), (0.6, 'front')]):
        pts = pose(seq, dur * frac, variant)
        draw = ImageDraw.Draw(row)
        order = []
        for sid_, level, vs, vc, ist, ic, bc, bci in subs:
            if GEO and sid_ != 0 and sid_ not in GEO:
                continue
            for k in range(ist, ist + ic, 3):
                a, b, c = pts[tris[k]], pts[tris[k + 1]], pts[tris[k + 2]]
                if view == 'side':
                    depth = -(a[1] + b[1] + c[1])
                    xy = [(col * W + W / 2 + p[0] * SC, HH - 40 - p[2] * SC) for p in (a, b, c)]
                else:
                    depth = a[0] + b[0] + c[0]
                    xy = [(col * W + W / 2 + p[1] * SC, HH - 40 - p[2] * SC) for p in (a, b, c)]
                u = [b[i] - a[i] for i in range(3)]
                v = [c[i] - a[i] for i in range(3)]
                n = [u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0]]
                ln = math.sqrt(sum(x * x for x in n)) or 1
                shade = int(60 + 180 * abs(n[0 if view == 'front' else 1] * 0.8 + n[2] * 0.4) / ln)
                shade = max(0, min(255, shade))
                order.append((depth, xy, shade))
        order.sort(key=lambda x: x[0])
        for _, xy, sh in order:
            draw.polygon(xy, fill=(sh, sh, sh))
        draw.line([(col * W, HH - 40), (col * W + W, HH - 40)], fill=(90, 60, 60))
    ImageDraw.Draw(row).text((5, 5), 'seq %d anim %d %s' % (seq, sid, variant), fill=(255, 220, 80))
    rows.append(row)
img = Image.new('RGB', (W * 5, HH * len(rows) + 4 * len(rows)), (200, 120, 0))
for i, r in enumerate(rows):
    img.paste(r, (0, i * (HH + 4)))
img.save(out)
print('saved', out)
