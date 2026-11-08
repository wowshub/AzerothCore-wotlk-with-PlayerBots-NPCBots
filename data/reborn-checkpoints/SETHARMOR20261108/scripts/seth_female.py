# -*- coding: utf-8 -*-
"""SETHARMOR1B: female Sethrak armour overlay (same method as the male v7).
Stages: build (M2 + skins), bake (composite bases), faces (crops), verify.  usage: python seth_female.py build|bake|faces|verify"""
import io, os, sys, math, struct, json, shutil, collections
sys.stdout.reconfigure(encoding='utf-8')
WF = r'D:\_zsdc\seth_work_f'
OT = WF + r'\orig_true\01_导入Patch-YJ.mpq'
OUT = WF + r'\out\01_导入Patch-YJ.mpq'
BK = WF + r'\backup\01_导入Patch-YJ.mpq'
FD = 'Character/RebornUIR3A/Sethrak/Female/'
M2P = FD + 'SethrakF.m2'
SKP = FD + 'SethrakF%s.skin'
S = 512
HEAD_Z = 2.05          # female: longer neck, head from about 2.15
X0 = 0.08
REG = {'ArmUpper': (0, 0, 128, 64), 'ArmLower': (0, 64, 128, 64), 'Hand': (0, 128, 128, 32),
       'TorsoUpper': (128, 0, 128, 64), 'TorsoLower': (128, 64, 128, 32), 'LegUpper': (128, 96, 128, 64),
       'LegLower': (128, 160, 128, 64), 'Foot': (128, 224, 128, 32)}


def P_(p): return OT + '\\' + p.replace('/', '\\')
def rdf(p): return open(P_(p), 'rb').read()


def uv_in(region, u, v):
    x, y, w, h = REG[region]
    u = min(max(u, 0.04), 0.96); v = min(max(v, 0.04), 0.96)
    return ((x + u * w) / 256.0, (y + v * h) / 256.0)


def classify(x, y, z):
    ax = abs(y); side = 1.0 if y >= 0 else -1.0
    if z >= HEAD_Z:
        return 'TorsoUpper', (abs(math.atan2(y, x - X0)) / math.pi, 0.0)
    if x < -0.45 and z < 1.3:
        return 'LegLower', ((math.atan2(z - 0.8, abs(y)) + math.pi / 2) / math.pi, (-x - 0.45) / 2.2)
    A0, A1, B0, B1 = 0.42, 1.62, 1.0, 0.88
    dx, dz = B0 - A0, B1 - A1
    L2 = dx * dx + dz * dz
    t = ((ax - A0) * dx + (z - A1) * dz) / L2
    dist = abs((ax - A0) * dz - (z - A1) * dx) / math.sqrt(L2)
    if ax >= 0.28 and -0.1 <= t <= 1.25 and dist < 0.22:
        ang = (math.atan2(z - (A1 + t * dz), x - X0) + math.pi) / (2 * math.pi)
        if t < 0.45: return 'ArmUpper', (ang, max(t, 0) / 0.45)
        if t < 0.82: return 'ArmLower', (ang, (t - 0.45) / 0.37)
        return 'Hand', (ang, min((t - 0.82) / 0.43, 1.0))
    if z >= 1.0:
        ang = abs(math.atan2(y, x - X0)) / math.pi
        if z >= 1.4: return 'TorsoUpper', (ang, (HEAD_Z - z) / (HEAD_Z - 1.4))
        return 'TorsoLower', (ang, (1.4 - z) / 0.4)
    ang = (math.atan2((y - side * 0.17) * side, x - X0) + math.pi) / (2 * math.pi)
    if z >= 0.55: return 'LegUpper', (ang, (1.0 - z) / 0.45)
    if z >= 0.15: return 'LegLower', (ang, (0.55 - z) / 0.4)
    return 'Foot', (ang, (0.15 - z) / 0.15)


def sections(sk):
    m, nI, oI, nT, oT, nP, oP, nS, oS, nU, oU, lod = struct.unpack_from('<4sIIIIIIIIIII', sk, 0)
    return nI, oI, nT, oT, nS, oS, nU, oU


def body_vertex_set(m2):
    """M2 vertex ids of the largest id-0 section of skin 00 (the always-on body mesh incl. head)."""
    sk = rdf(SKP % '00')
    nI, oI, nT, oT, nS, oS, nU, oU = sections(sk)
    idx = struct.unpack_from('<%dH' % nI, sk, oI)
    best = None
    for i in range(nS):
        sid, lvl, vs, vc, ts, tc = struct.unpack_from('<HHHHHH', sk, oS + i * 48)
        if sid == 0 and (best is None or vc > best[1]): best = (i, vc, vs)
    i, vc, vs = best
    return set(idx[vs + k] for k in range(vc)), best


def build():
    m2 = bytearray(rdf(M2P))
    assert m2[:4] == b'MD20' and struct.unpack_from('<I', m2, 4)[0] == 264
    nV, oV = struct.unpack_from('<II', m2, 0x3C)
    bodyv, best = body_vertex_set(m2)
    print('body vertex set from skin00 section', best[0], 'size', len(bodyv))
    regcount = collections.Counter(); uv2pts = []
    for i in range(nV):
        if i not in bodyv: continue            # female: UV2 is used by effect layers of other parts, leave those alone
        o = oV + i * 48
        x, y, z = struct.unpack_from('<3f', m2, o)
        reg, (u, v) = classify(x, y, z)
        uu, vv = uv_in(reg, u, v)
        struct.pack_into('<2f', m2, o + 40, uu, vv)
        regcount[reg] += 1; uv2pts.append((reg, uu, vv, x, y, z))
    print('body vertices per region', dict(regcount))

    def align16():
        while len(m2) % 16: m2.append(0)
    def hdr(off): return struct.unpack_from('<II', m2, off)
    nTex, oTex = hdr(0x50)
    tex = bytes(m2[oTex:oTex + nTex * 16]) + struct.pack('<IIII', 1, 0, 0, 0)
    align16(); newTex = len(m2); m2 += tex
    struct.pack_into('<II', m2, 0x50, nTex + 1, newTex); TEX_NEW = nTex
    nTL, oTL = hdr(0x80)
    tl = list(struct.unpack_from('<%dH' % nTL, m2, oTL)) + [TEX_NEW]
    align16(); newTL = len(m2); m2 += struct.pack('<%dH' % len(tl), *tl)
    struct.pack_into('<II', m2, 0x80, len(tl), newTL); TL_NEW = len(tl) - 1
    nTU, oTU = hdr(0x88)
    tu = struct.unpack_from('<%dH' % nTU, m2, oTU)
    assert tu[3] == 1, tu                       # the existing entry 3 = second UV set
    TU_NEW = 3
    nR, oR = hdr(0x68)
    before = struct.unpack_from('<%dH' % nR, m2, oR)
    assert nR > 1 and before[1] == 0xFFFF, before
    struct.pack_into('<H', m2, oR + 2, TEX_NEW)
    nM, oM = hdr(0x70)
    mats = struct.unpack_from('<%dH' % (nM * 2), m2, oM)
    assert (mats[0], mats[1]) == (0, 0), mats[:2]
    MAT_NEW = 0
    print('new texture', TEX_NEW, 'texLookup', TL_NEW, 'texUnit idx', TU_NEW, 'material', MAT_NEW)
    vz = [struct.unpack_from('<f', m2, oV + i * 48 + 8)[0] for i in range(nV)]
    report = {'skins': {}}
    skins_new = {}
    for n in ('00', '01', '02', '03'):
        sk = bytearray(rdf(SKP % n))
        nI, oI, nT, oT, nS, oS, nU, oU = sections(sk)
        idx = struct.unpack_from('<%dH' % nI, sk, oI)
        body = []
        for i in range(nS):
            sid, lvl, vs, vc, ts, tc = struct.unpack_from('<HHHHHH', sk, oS + i * 48)
            if sid != 0 or vc < 50: continue
            frac = sum(1 for k in range(vc) if idx[vs + k] in bodyv) / vc
            if frac >= 0.9: body.append(i)
            elif frac > 0.1: print('  WARNING section', i, 'shares %.0f%% of its vertices with the body' % (100 * frac))
        print('skin', n, 'body sections', body)
        assert body
        new_sections = bytearray(); remap = {}; stats = []
        for j, bsec in enumerate(body):
            raw = bytearray(sk[oS + bsec * 48:oS + (bsec + 1) * 48])
            sid, lvl, vs, vc, ts, tc = struct.unpack_from('<HHHHHH', raw, 0)
            assert tc % 3 == 0
            tris = [struct.unpack_from('<3H', sk, oT + (ts + k) * 2) for k in range(0, tc, 3)]
            keep, head = [], []
            for t3 in tris:
                zz = (vz[idx[t3[0]]] + vz[idx[t3[1]]] + vz[idx[t3[2]]]) / 3.0
                (head if zz >= HEAD_Z else keep).append(t3)
            for k, t3 in enumerate(keep + head):
                struct.pack_into('<3H', sk, oT + (ts + 3 * k) * 2, *t3)
            struct.pack_into('<H', raw, 10, len(keep) * 3)
            remap[bsec] = nS + j; new_sections += raw; stats.append((bsec, len(keep), len(head)))
        print('  triangles (section, body, head):', stats)
        while len(sk) % 4: sk.append(0)
        newS = len(sk)
        sk += bytes(sk[oS:oS + nS * 48]) + bytes(new_sections)
        tu_old = bytes(sk[oU:oU + nU * 24])
        new = bytearray(); cnt = 0
        for i in range(nU):
            f = list(struct.unpack('<BbHHHHHHHHHHH', tu_old[i * 24:(i + 1) * 24]))
            # flags, prio, shader, section, geoset, color, material, layer, texCount, texCombo, coordCombo, weight, transform
            if f[8] == 1 and f[7] == 1 and f[3] in remap:
                f[3] = remap[f[3]]; f[6] = MAT_NEW; f[7] = 2; f[8] = 1; f[9] = TL_NEW; f[10] = TU_NEW
                f[11] = 0; f[12] = 0
                new += struct.pack('<BbHHHHHHHHHHH', *f); cnt += 1
        newU = len(sk)
        sk += tu_old + bytes(new)
        struct.pack_into('<I', sk, 28, nS + len(body)); struct.pack_into('<I', sk, 32, newS)
        struct.pack_into('<I', sk, 36, nU + cnt); struct.pack_into('<I', sk, 40, newU)
        skins_new[n] = bytes(sk)
        report['skins'][n] = {'old_batches': nU, 'added': cnt, 'body_sections': body, 'tris': stats}
        assert cnt > 0, 'no overlay batch was added'
    print(json.dumps(report['skins']))
    for d in (os.path.dirname(OUT), os.path.dirname(BK)):
        if os.path.exists(d): shutil.rmtree(d)
    def put(root, rel, data):
        p = root + '\\' + rel.replace('/', '\\')
        os.makedirs(os.path.dirname(p), exist_ok=True); open(p, 'wb').write(data)
    put(OUT, M2P, bytes(m2)); put(BK, M2P, rdf(M2P))
    for n in skins_new:
        put(OUT, SKP % n, skins_new[n]); put(BK, SKP % n, rdf(SKP % n))
    for c in range(6):
        for rel in ['Reborn/Sethrak/snakeloa_1_body_blue_t%d.blp' % c] + ['Reborn/Bake/snakeloa_1_body_blue_t%d_%s.blp' % (c, s) for s in ('FL', 'FU', 'LU', 'TU')]:
            o = rdf(rel)
            put(BK, rel, o)
            put(OUT, rel, o[:148] + bytes(len(o) - 148))       # transparent placeholders, the bake/faces stages overwrite them
    json.dump({'regions': dict(regcount), 'skins': report['skins']}, open(WF + r'\build_report.json', 'w'), indent=1)
    json.dump(uv2pts, open(WF + r'\uv2pts.json', 'w'))
    json.dump(sorted(bodyv), open(WF + r'\bodyv.json', 'w'))
    print('M2', len(rdf(M2P)), '->', len(m2))


def bake():
    from PIL import Image
    m2 = open(OUT + '\\' + M2P.replace('/', '\\'), 'rb').read()
    nV, oV = struct.unpack_from('<II', m2, 0x3C)
    V = []
    for i in range(nV):
        o = oV + i * 48
        u1, v1 = struct.unpack_from('<2f', m2, o + 32); u2, v2 = struct.unpack_from('<2f', m2, o + 40)
        V.append((u1, v1, u2, v2))
    sk = open(OUT + '\\' + (SKP % '00').replace('/', '\\'), 'rb').read()
    nI, oI, nT, oT, nS, oS, nU, oU = sections(sk)
    idx = struct.unpack_from('<%dH' % nI, sk, oI); tri = struct.unpack_from('<%dH' % nT, sk, oT)
    bodyv = set(json.load(open(WF + r'\bodyv.json')))
    body = [i for i in range(nS) if struct.unpack_from('<H', sk, oS + i * 48)[0] == 0
            and sum(1 for k in range(struct.unpack_from('<H', sk, oS + i * 48 + 6)[0]) if idx[struct.unpack_from('<H', sk, oS + i * 48 + 4)[0] + k] in bodyv) >= 0.9 * struct.unpack_from('<H', sk, oS + i * 48 + 6)[0]]
    bsec = body[-1]
    _s, _l, _vs, _vc, _ts, _tc = struct.unpack_from('<HHHHHH', sk, oS + bsec * 48)
    print('body-only section', bsec, 'vertices', _vc, 'triangle indices', _tc)
    tris = [(idx[tri[i]], idx[tri[i + 1]], idx[tri[i + 2]]) for i in range(_ts, _ts + _tc - _tc % 3, 3)]
    seen = set(); uniq = []
    for t in tris:
        k = tuple(sorted(t))
        if k in seen: continue
        seen.add(k); uniq.append(t)
    import zipfile
    os.makedirs(WF + r'\bake_png', exist_ok=True)
    report = {}
    BL = P_('Reborn/Sethrak/snakeloa_1_body_blue_t0.blp')
    for color in range(6):
        atlas = Image.open(P_('Reborn/RaceClass1D/Sethrak/Female/color%d.blp' % color)).convert('RGB')
        atlas = atlas.resize((atlas.size[0] // 2, atlas.size[1] // 2), Image.LANCZOS)
        aw, ah = atlas.size; A = atlas.load()
        buf = bytearray(S * S * 3); cov = bytearray(S * S); skipped = 0
        for (a, b, c) in uniq:
            p = [V[a], V[b], V[c]]
            xs = [q[2] * S for q in p]; ys = [q[3] * S for q in p]
            if max(xs) - min(xs) > 0.4 * S or max(ys) - min(ys) > 0.4 * S:
                skipped += 1; continue
            minx = max(int(min(xs)), 0); maxx = min(int(max(xs)) + 1, S - 1)
            miny = max(int(min(ys)), 0); maxy = min(int(max(ys)) + 1, S - 1)
            x0, y0, x1, y1, x2, y2 = xs[0], ys[0], xs[1], ys[1], xs[2], ys[2]
            den = (y1 - y2) * (x0 - x2) + (x2 - x1) * (y0 - y2)
            if abs(den) < 1e-9: continue
            for py in range(miny, maxy + 1):
                for px in range(minx, maxx + 1):
                    cx = px + 0.5; cy = py + 0.5
                    l0 = ((y1 - y2) * (cx - x2) + (x2 - x1) * (cy - y2)) / den
                    l1 = ((y2 - y0) * (cx - x2) + (x0 - x2) * (cy - y2)) / den
                    l2 = 1 - l0 - l1
                    if l0 < -0.02 or l1 < -0.02 or l2 < -0.02: continue
                    u = l0 * p[0][0] + l1 * p[1][0] + l2 * p[2][0]; v = l0 * p[0][1] + l1 * p[1][1] + l2 * p[2][1]
                    r, g, bl = A[min(max(int(u * aw), 0), aw - 1), min(max(int(v * ah), 0), ah - 1)]
                    o = (py * S + px) * 3
                    buf[o] = r; buf[o + 1] = g; buf[o + 2] = bl; cov[py * S + px] = 1
        covered = sum(cov)
        for _ in range(8):
            ncov = bytearray(cov); nb = bytearray(buf)
            for py in range(S):
                for px in range(S):
                    if cov[py * S + px]: continue
                    acc = [0, 0, 0]; n = 0
                    for dy in (-1, 0, 1):
                        for dx in (-1, 0, 1):
                            qx = px + dx; qy = py + dy
                            if 0 <= qx < S and 0 <= qy < S and cov[qy * S + qx]:
                                o = (qy * S + qx) * 3; acc[0] += buf[o]; acc[1] += buf[o + 1]; acc[2] += buf[o + 2]; n += 1
                    if n:
                        o = (py * S + px) * 3; nb[o] = acc[0] // n; nb[o + 1] = acc[1] // n; nb[o + 2] = acc[2] // n; ncov[py * S + px] = 1
            cov = ncov; buf = nb
        tot = [0, 0, 0]; n = 0
        for i in range(S * S):
            if cov[i]: tot[0] += buf[i * 3]; tot[1] += buf[i * 3 + 1]; tot[2] += buf[i * 3 + 2]; n += 1
        mean = bytes(t // max(n, 1) for t in tot)
        for i in range(S * S):
            if not cov[i]: buf[i * 3:i * 3 + 3] = mean
        img = Image.frombytes('RGB', (S, S), bytes(buf))
        img.save(WF + r'\bake_png\composite_t%d.png' % color)
        write_blp(img, P_('Reborn/Sethrak/snakeloa_1_body_blue_t%d.blp' % color), OUT + r'\Reborn\Sethrak\snakeloa_1_body_blue_t%d.blp' % color)
        report[color] = {'covered_px': covered, 'fraction': round(covered / (S * S), 3), 'skipped_seam_triangles': skipped, 'atlas': [aw * 2, ah * 2]}
        print('colour', color, report[color])
    json.dump(report, open(WF + r'\bake_report.json', 'w'), indent=1)


def write_blp(img, orig_path, out_path):
    from PIL import Image
    orig = open(orig_path, 'rb').read()
    w0, h0 = img.size
    pal_img = img.quantize(256, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.FLOYDSTEINBERG)
    pal = pal_img.getpalette()[:768]; pal = pal + [0] * (768 - len(pal))
    palette = bytearray()
    for i in range(256): palette += bytes([pal[i * 3 + 2], pal[i * 3 + 1], pal[i * 3], 255])
    data = bytearray(); w, h = w0, h0
    while True:
        im = img.resize((w, h), Image.LANCZOS) if (w, h) != (w0, h0) else img
        q = im.quantize(palette=pal_img, dither=Image.Dither.FLOYDSTEINBERG)
        data += q.tobytes(); data += bytes([255]) * (w * h)
        if w == 1 and h == 1: break
        w = max(1, w // 2); h = max(1, h // 2)
    out = orig[:148] + bytes(palette) + bytes(data)
    assert len(out) == len(orig), (os.path.basename(orig_path), len(out), len(orig))
    open(out_path, 'wb').write(out)


def faces():
    from PIL import Image
    CROP = {'FU': (0, 320, 256, 384), 'FL': (0, 384, 256, 512), 'TU': (256, 0, 512, 128), 'LU': (256, 192, 512, 320)}
    for c in range(6):
        comp = Image.open(WF + r'\bake_png\composite_t%d.png' % c).convert('RGB')
        for suf, box in CROP.items():
            name = 'snakeloa_1_body_blue_t%d_%s.blp' % (c, suf)
            write_blp(comp.crop(box), P_('Reborn/Bake/' + name), OUT + r'\Reborn\Bake' + '\\' + name)
    print('wrote 24 crops')


def verify():
    ok = True
    def chk(c, msg):
        nonlocal ok
        print(('PASS ' if c else 'FAIL ') + msg); ok = ok and c
    a2 = rdf(M2P); b2 = open(OUT + '\\' + M2P.replace('/', '\\'), 'rb').read()
    same = [off for off in range(0, 0xA0, 4) if a2[off:off + 4] != b2[off:off + 4]]
    chk(set(same) <= {0x50, 0x54, 0x80, 0x84}, 'M2 header words changed: %s (only texture + texture lookup arrays)' % [hex(s) for s in same])
    nV, oV = struct.unpack_from('<II', b2, 0x3C)
    bodyv = set(json.load(open(WF + r'\bodyv.json')))
    diff = 0; uvdiff_nonbody = 0
    for i in range(nV):
        oa = a2[oV + i * 48:oV + i * 48 + 48]; ob = b2[oV + i * 48:oV + i * 48 + 48]
        if oa[:40] != ob[:40]: diff += 1
        if i not in bodyv and oa[40:] != ob[40:]: uvdiff_nonbody += 1
    chk(diff == 0, 'positions/weights/normals/UV1 unchanged (%d differ)' % diff)
    chk(uvdiff_nonbody == 0, 'UV2 of non-body vertices (effect layers) unchanged (%d differ)' % uvdiff_nonbody)
    nTex, oTex = struct.unpack_from('<II', b2, 0x50)
    types = [struct.unpack_from('<I', b2, oTex + i * 16)[0] for i in range(nTex)]
    chk(types == [8, 0, 0, 0, 0, 0, 1], 'texture types %s' % types)
    nTL, oTL = struct.unpack_from('<II', b2, 0x80); tl = struct.unpack_from('<%dH' % nTL, b2, oTL)
    chk(tl[-1] == 6 and tl[:9] == (0, 1, 0, 1, 3, 5, 5, 4, 4), 'texLookup %s' % (tl,))
    nR, oR = struct.unpack_from('<II', b2, 0x68); rp = struct.unpack_from('<%dH' % nR, b2, oR)
    chk(rp[1] == 6 and rp[8] == 0, 'texReplace %s' % (rp,))
    vz = [struct.unpack_from('<f', b2, oV + i * 48 + 8)[0] for i in range(nV)]
    for sn in ('00', '01', '02', '03'):
        a = rdf(SKP % sn); b = open(OUT + '\\' + (SKP % sn).replace('/', '\\'), 'rb').read()
        nI, oI, nT, oT, nS, oS, nU, oU = sections(a); nI2, oI2, nT2, oT2, nS2, oS2, nU2, oU2 = sections(b)
        chk((nI, oI, nT, oT) == (nI2, oI2, nT2, oT2) and a[oI:oI + nI * 2] == b[oI2:oI2 + nI * 2], 'skin%s index list / triangle array keep place and size' % sn)
        chk(oS2 + nS2 * 48 <= len(b) and oU2 + nU2 * 24 == len(b), 'skin%s sections + batches arrays inside the file' % sn)
        idx = struct.unpack_from('<%dH' % nI, b, oI)
        sameT = True
        for i in range(nS):
            sid, lvl, vs, vc, ts, tc = struct.unpack_from('<HHHHHH', a, oS + i * 48)
            ta = collections.Counter(struct.unpack_from('<3H', a, oT + (ts + k) * 2) for k in range(0, tc, 3))
            tb = collections.Counter(struct.unpack_from('<3H', b, oT2 + (ts + k) * 2) for k in range(0, tc, 3))
            if ta != tb: sameT = False
        chk(sameT, 'skin%s every original section draws exactly the same triangles' % sn)
        chk(a[oS:oS + nS * 48] == b[oS2:oS2 + nS * 48], 'skin%s original sections untouched' % sn)
        okn = True
        for j in range(nS, nS2):
            sid, lvl, vs, vc, ts, tc = struct.unpack_from('<HHHHHH', b, oS2 + j * 48)
            if not (ts + tc <= nT and tc % 3 == 0): okn = False
            for k in range(0, tc, 3):
                zz = sum(vz[idx[struct.unpack_from('<H', b, oT2 + (ts + k + q) * 2)[0]]] for q in range(3)) / 3
                if zz >= HEAD_Z: okn = False
        chk(okn, 'skin%s new body-only sections valid and without head triangles' % sn)
        added = [struct.unpack_from('<BbHHHHHHHHHHH', b, oU2 + i * 24) for i in range(nU, nU2)]
        chk(all(nS <= x[3] < nS2 and x[6] == 0 and x[7] == 2 and x[8] == 1 and x[9] == 9 and x[10] == 3 for x in added) and len(added) > 0,
            'skin%s %d overlay batches: new sections, material 0, layer 2, texLookup 9, uv set idx 3' % (sn, len(added)))
    print('ALL PASS' if ok else 'SOME FAILED')


if __name__ == '__main__':
    {'build': build, 'bake': bake, 'faces': faces, 'verify': verify}[sys.argv[1]]()
