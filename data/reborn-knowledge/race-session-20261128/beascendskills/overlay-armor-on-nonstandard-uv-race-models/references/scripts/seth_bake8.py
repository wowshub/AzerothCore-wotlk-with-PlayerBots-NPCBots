# -*- coding: utf-8 -*-
"""v4: bake the Sethrak male skin atlas into the standard-layout composite base (skin11_tN.blp, 512x512 palettised BLP2)
using the UV1 -> UV2 correspondence of the patched model, so armour painted over it replaces the skin where it exists."""
import io, os, struct, sys, zipfile, json
from PIL import Image
sys.stdout.reconfigure(encoding='utf-8')
R = r'D:\000rebornWOW\000RebornWOWHighForkPRO'
W = r'D:\_zsdc\seth_work'
Z1D = R + r'\000Ascendupdate\000Ascendupdate20261108\codexfix_20261108_022900_阶段RACECLASS1D_蛇人独立肤色图集与面部装备隔离.zip'
OUT = W + r'\out8\01_导入Patch-YJ.mpq'
M2P = OUT + r'\Character\RebornUIR3A\Sethrak\Male\Sethrak.m2'
SK = OUT + r'\Character\RebornUIR3A\Sethrak\Male\Sethrak00.skin'
ORIG_T0 = W + r'\orig_true\01_导入Patch-YJ.mpq\Reborn\Sethrak\skin11_t0.blp'
S = 512

m2 = open(M2P, 'rb').read()
nV, oV = struct.unpack_from('<II', m2, 0x3C)
V = []
for i in range(nV):
    o = oV + i * 48
    u1, v1 = struct.unpack_from('<2f', m2, o + 32)
    u2, v2 = struct.unpack_from('<2f', m2, o + 40)
    V.append((u1, v1, u2, v2))
sk = open(SK, 'rb').read()
m, nI, oI, nT, oT, nP, oP, nS, oS, nU, oU, lod = struct.unpack_from('<4sIIIIIIIIIII', sk, 0)
idx = struct.unpack_from('<%dH' % nI, sk, oI)
tri = struct.unpack_from('<%dH' % nT, sk, oT)
body = [i for i in range(nS) if struct.unpack_from('<H', sk, oS + i * 48)[0] == 0 and struct.unpack_from('<H', sk, oS + i * 48 + 6)[0] > 250]
bsec = body[-1]            # v7: the last id-0 section is the new body-only one
_sid, _lvl, _vs, _vc, _ts, _tc = struct.unpack_from('<HHHHHH', sk, oS + bsec * 48)
print('body-only section', bsec, 'vertices', _vc, 'triangle indices', _tc)
tris = [(idx[tri[i]], idx[tri[i + 1]], idx[tri[i + 2]]) for i in range(_ts, _ts + _tc - _tc % 3, 3)]
print('triangles', len(tris))
# keep unique triangles only (the geoset variants repeat the same geometry)
seen = set(); uniq = []
for t in tris:
    k = tuple(sorted(t))
    if k in seen: continue
    seen.add(k); uniq.append(t)
print('unique triangles', len(uniq))

z = zipfile.ZipFile(Z1D)
report = {}


def bake(color):
    atlas = Image.open(io.BytesIO(z.read('01_导入Patch-YJ.mpq/Reborn/RaceClass1D/Sethrak/Male/color%d.blp' % color))).convert('RGB')
    atlas = atlas.resize((atlas.size[0] // 2, atlas.size[1] // 2), Image.LANCZOS)   # v5: prefilter, the composite is far smaller than the atlas
    aw, ah = atlas.size
    A = atlas.load()
    buf = bytearray(S * S * 3)
    cov = bytearray(S * S)
    skipped = 0
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
                u = l0 * p[0][0] + l1 * p[1][0] + l2 * p[2][0]
                v = l0 * p[0][1] + l1 * p[1][1] + l2 * p[2][1]
                ax = min(max(int(u * aw), 0), aw - 1); ay = min(max(int(v * ah), 0), ah - 1)
                r, g, bl = A[ax, ay]
                o = (py * S + px) * 3
                buf[o] = r; buf[o + 1] = g; buf[o + 2] = bl
                cov[py * S + px] = 1
    covered = sum(cov)
    # dilate into the empty pixels (a few passes) so bilinear filtering never pulls in black
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
                            o = (qy * S + qx) * 3
                            acc[0] += buf[o]; acc[1] += buf[o + 1]; acc[2] += buf[o + 2]; n += 1
                if n:
                    o = (py * S + px) * 3
                    nb[o] = acc[0] // n; nb[o + 1] = acc[1] // n; nb[o + 2] = acc[2] // n
                    ncov[py * S + px] = 1
        cov = ncov; buf = nb
    # fill what is still empty with the mean colour
    tot = [0, 0, 0]; n = 0
    for i in range(S * S):
        if cov[i]:
            tot[0] += buf[i * 3]; tot[1] += buf[i * 3 + 1]; tot[2] += buf[i * 3 + 2]; n += 1
    mean = tuple(t // max(n, 1) for t in tot)
    for i in range(S * S):
        if not cov[i]:
            buf[i * 3:i * 3 + 3] = bytes(mean)
    img = Image.frombytes('RGB', (S, S), bytes(buf))
    report[color] = {'covered_px': covered, 'fraction': round(covered / (S * S), 3), 'skipped_seam_triangles': skipped, 'atlas': [aw, ah]}
    return img


def write_blp(img, path):
    pal_img = img.quantize(256, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.FLOYDSTEINBERG)
    pal = pal_img.getpalette()[:768]
    pal = pal + [0] * (768 - len(pal))
    head = bytearray(open(ORIG_T0, 'rb').read()[:148])        # the original header: same size, same mip table
    palette = bytearray()
    for i in range(256):
        palette += bytes([pal[i * 3 + 2], pal[i * 3 + 1], pal[i * 3], 255])
    data = bytearray()
    w = h = S
    lvl = 0
    while True:
        im = img.resize((w, h), Image.LANCZOS) if (w, h) != (S, S) else img
        q = im.quantize(palette=pal_img, dither=Image.Dither.FLOYDSTEINBERG)
        data += q.tobytes()
        data += bytes([255]) * (w * h)                           # 8-bit alpha plane: fully opaque
        if w == 1 and h == 1: break
        w = max(1, w // 2); h = max(1, h // 2); lvl += 1
    out = bytes(head) + bytes(palette) + bytes(data)
    orig_len = os.path.getsize(ORIG_T0)
    assert len(out) == orig_len, (len(out), orig_len)
    open(path, 'wb').write(out)


os.makedirs(W + r'\bake8_png', exist_ok=True)
for c in range(6):
    img = bake(c)
    img.save(W + r'\bake8_png\composite_t%d.png' % c)
    write_blp(img, OUT + r'\Reborn\Sethrak\skin11_t%d.blp' % c)
    print('colour', c, report[c])
json.dump(report, open(W + r'\bake8_report.json', 'w'), indent=1)
