# -*- coding: utf-8 -*-
"""SETHARMOR1A: male Sethrak armour overlay experiment. Builds the patched M2 + skins + transparent base textures
from the RACECLASS1D male model (the active one) and writes them to a work folder with a verification report."""
import zipfile, struct, math, os, sys, json, hashlib, shutil
sys.stdout.reconfigure(encoding='utf-8')
exec(open(r'D:\_zsdc\seth_m2.py', encoding='utf-8').read().split("def analyse")[0])   # L, rd (StormLib helpers)

R = r'D:\000rebornWOW\000RebornWOWHighForkPRO'
Z1D = R + r'\000Ascendupdate\000Ascendupdate20261108\codexfix_20261108_022900_阶段RACECLASS1D_蛇人独立肤色图集与面部装备隔离.zip'
YJ = R + r'\beascendclient\newrebornWOWli20261107beAscend\Data\Patch-YJ.mpq'
WORK = r'D:\_zsdc\seth_work'
OUT = WORK + r'\out8'
BK = WORK + r'\backup'
M2P = 'Character/RebornUIR3A/Sethrak/Male/Sethrak.m2'
SKP = 'Character/RebornUIR3A/Sethrak/Male/Sethrak%s.skin'

# ------------------------------------------------------------------ inputs
z = zipfile.ZipFile(Z1D)
m2_zip = z.read('01_导入Patch-YJ.mpq/' + M2P)
skins_orig = {}
for n in ('00', '01', '02', '03'):
    # the TRUE originals saved before the first import (the client's YJ now holds the patched v1 files)
    b = open(WORK + r'\orig_true\01_导入Patch-YJ.mpq' + '\\' + (SKP % n).replace('/', '\\'), 'rb').read()
    skins_orig[n] = b
cur = open(WORK + r'\orig_true\01_导入Patch-YJ.mpq' + '\\' + M2P.replace('/', '\\'), 'rb').read()
print('true original M2 == 1D package M2:', cur == m2_zip, len(cur) if cur else None, len(m2_zip))
assert cur is not None
m2_orig = cur   # the model the client really uses now (1D plus Codex's later attachment changes)

# ------------------------------------------------------------------ geometry classes
X0 = 0.08
REG = {  # standard character texture layout on a 256 grid: x, y, w, h
    'ArmUpper': (0, 0, 128, 64), 'ArmLower': (0, 64, 128, 64), 'Hand': (0, 128, 128, 32), 'FaceLower': (0, 192, 128, 64), 'Head': (0, 160, 128, 96),
    'TorsoUpper': (128, 0, 128, 64), 'TorsoLower': (128, 64, 128, 32), 'LegUpper': (128, 96, 128, 64),
    'LegLower': (128, 160, 128, 64), 'Foot': (128, 224, 128, 32)}


def uv_in(region, u, v):
    x, y, w, h = REG[region]
    u = min(max(u, 0.04), 0.96); v = min(max(v, 0.04), 0.96)
    return ((x + u * w) / 256.0, (y + v * h) / 256.0)


def classify(x, y, z):
    ax = abs(y); side = 1.0 if y >= 0 else -1.0
    if z >= 1.95:
        return 'TorsoUpper', (abs(math.atan2(y, x - X0)) / math.pi, 0.0)   # v7: the head is not part of the overlay
    if x < -0.45 and z < 1.3:
        ang = (math.atan2(z - 0.8, abs(y)) + math.pi / 2) / math.pi
        return 'LegLower', (ang, (-x - 0.45) / 2.2)
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
        if z >= 1.4: return 'TorsoUpper', (ang, (1.95 - z) / 0.55)
        return 'TorsoLower', (ang, (1.4 - z) / 0.4)
    ang = (math.atan2((y - side * 0.17) * side, x - X0) + math.pi) / (2 * math.pi)
    if z >= 0.55: return 'LegUpper', (ang, (1.0 - z) / 0.45)
    if z >= 0.15: return 'LegLower', (ang, (0.55 - z) / 0.4)
    return 'Foot', (ang, (0.15 - z) / 0.15)


# ------------------------------------------------------------------ M2
m2 = bytearray(m2_orig)
nV, oV = struct.unpack_from('<II', m2, 0x3C)
assert m2[:4] == b'MD20' and struct.unpack_from('<I', m2, 4)[0] == 264
regcount = {}
uv2pts = []
for i in range(nV):
    o = oV + i * 48
    x, y, zz = struct.unpack_from('<3f', m2, o)
    reg, (u, v) = classify(x, y, zz)
    uu, vv = uv_in(reg, u, v)
    struct.pack_into('<2f', m2, o + 40, uu, vv)
    regcount[reg] = regcount.get(reg, 0) + 1
    uv2pts.append((reg, uu, vv, x, y, zz))
print('vertices per region', regcount)


def align16():
    while len(m2) % 16: m2.append(0)


def hdr(off): return struct.unpack_from('<II', m2, off)


# textures: append one type-1 (character skin composite) entry
nTex, oTex = hdr(0x50)
tex = bytes(m2[oTex:oTex + nTex * 16]) + struct.pack('<IIII', 1, 0, 0, 0)
align16(); newTex = len(m2); m2 += tex
struct.pack_into('<II', m2, 0x50, nTex + 1, newTex)
TEX_NEW = nTex                       # index of the new texture
# texture lookup
nTL, oTL = hdr(0x80)
tl = list(struct.unpack_from('<%dH' % nTL, m2, oTL)) + [TEX_NEW]
align16(); newTL = len(m2); m2 += struct.pack('<%dH' % len(tl), *tl)
struct.pack_into('<II', m2, 0x80, len(tl), newTL)
TL_NEW = len(tl) - 1
# texture unit lookup (uv set): append value 1 = second UV set
nTU, oTU = hdr(0x88)
tu = list(struct.unpack_from('<%dH' % nTU, m2, oTU)) + [1]
align16(); newTU = len(m2); m2 += struct.pack('<%dH' % len(tu), *tu)
struct.pack_into('<II', m2, 0x88, len(tu), newTU)
TU_NEW = len(tu) - 1
MAT_NEW = 0   # v4: opaque overlay, existing material 0 = (0, 0)
# replaceable texture table: type 1 -> the new texture
nR, oR = hdr(0x68)
before = struct.unpack_from('<%dH' % nR, m2, oR)
assert nR > 1 and before[1] == 0xFFFF, before
struct.pack_into('<H', m2, oR + 2, TEX_NEW)
print('texReplace before', before, 'after', struct.unpack_from('<%dH' % nR, m2, oR))
print('new texture index', TEX_NEW, 'texLookup idx', TL_NEW, 'texUnitLookup idx', TU_NEW)

# ------------------------------------------------------------------ skins
skins_new = {}
report = {'m2': {}, 'skins': {}}
vz = [struct.unpack_from('<f', m2, oV + i * 48 + 8)[0] for i in range(nV)]
HEAD_Z = 1.95
for n, sk in skins_orig.items():
    sk = bytearray(sk)
    m, nI, oI, nT, oT, nP, oP, nS, oS, nU, oU, lod = struct.unpack_from('<4sIIIIIIIIIII', sk, 0)
    assert oU + nU * 24 == len(sk), 'texture units are not at the end of the file'
    idx = struct.unpack_from('<%dH' % nI, sk, oI)
    body = sorted(i for i in range(nS)
                  if struct.unpack_from('<H', sk, oS + i * 48)[0] == 0 and struct.unpack_from('<H', sk, oS + i * 48 + 6)[0] > 250)
    print('skin', n, 'body sections', body)
    assert body, 'no body section found'
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
        struct.pack_into('<H', raw, 10, len(keep) * 3)          # new section = the body part only
        remap[bsec] = nS + j
        new_sections += raw
        stats.append((bsec, len(keep), len(head)))
    print('  triangles (section, body, head):', stats)
    newS = len(sk)
    sk += bytes(sk[oS:oS + nS * 48]) + bytes(new_sections)
    tu_old = bytes(sk[oU:oU + nU * 24])
    new = bytearray(); cnt = 0
    for i in range(nU):
        raw = bytes(tu_old[i * 24:(i + 1) * 24])
        f = list(struct.unpack('<BbHHHHHHHHHHH', raw))
        # f: flags, prio, shader, section, geoset, color, material, layer, texCount, texCombo, coordCombo, weight, transform
        if f[8] == 1 and f[7] == 1 and f[3] in remap:
            f[3] = remap[f[3]]
            f[6] = MAT_NEW
            f[7] = 2
            f[8] = 1
            f[9] = TL_NEW
            f[10] = TU_NEW
            new += struct.pack('<BbHHHHHHHHHHH', *f)
            cnt += 1
    newU = len(sk)
    sk += tu_old + bytes(new)
    struct.pack_into('<I', sk, 28, nS + len(body))
    struct.pack_into('<I', sk, 32, newS)
    struct.pack_into('<I', sk, 36, nU + cnt)
    struct.pack_into('<I', sk, 40, newU)
    skins_new[n] = bytes(sk)
    report['skins'][n] = {'old_batches': nU, 'added': cnt, 'size': len(sk), 'body_sections': body, 'tris': stats}
print(json.dumps(report['skins']))

# ------------------------------------------------------------------ transparent BLP2 (DXT5, all zero = alpha 0)
def blp_transparent(w, h):
    mips = []
    ww, hh = w, h
    while True:
        mips.append(max(1, (ww + 3) // 4) * max(1, (hh + 3) // 4) * 16)
        if ww == 1 and hh == 1: break
        ww = max(1, ww // 2); hh = max(1, hh // 2)
    off = 148 + 1024
    offs, sizes = [], []
    for s in mips:
        offs.append(off); sizes.append(s); off += s
    head = b'BLP2' + struct.pack('<I', 1) + bytes([2, 8, 7, 1]) + struct.pack('<II', w, h)
    head += struct.pack('<16I', *(offs + [0] * (16 - len(offs)))) + struct.pack('<16I', *(sizes + [0] * (16 - len(sizes))))
    head += bytes(1024)
    return head + bytes(sum(sizes))


blp_specs = []
for t in range(6):
    blp_specs.append(('Reborn/Sethrak/skin11_t%d.blp' % t, 512, 512))
    for suf, (w, h) in (('FL', (256, 128)), ('FU', (256, 64)), ('LU', (256, 128)), ('TU', (256, 128))):
        blp_specs.append(('Reborn/Bake/skin11_t%d_%s.blp' % (t, suf), w, h))

# ------------------------------------------------------------------ write
for d in (OUT, BK):
    if os.path.exists(d): shutil.rmtree(d)
base = OUT + r'\01_导入Patch-YJ.mpq'
bbase = BK + r'\01_导入Patch-YJ.mpq'
def put(root, rel, data):
    p = root + '\\' + rel.replace('/', '\\')
    os.makedirs(os.path.dirname(p), exist_ok=True)
    open(p, 'wb').write(data)
put(base, M2P, bytes(m2)); put(bbase, M2P, m2_orig)
for n in skins_orig:
    put(base, SKP % n, skins_new[n]); put(bbase, SKP % n, skins_orig[n])
orig_missing = []
for rel, w, h in blp_specs:
    op = WORK + r'\orig_true\01_导入Patch-YJ.mpq' + '\\' + rel.replace('/', '\\')
    if not os.path.exists(op):
        orig_missing.append(rel)
        put(base, rel, blp_transparent(w, h))
    else:
        o = open(op, 'rb').read()
        # v2: same layout as the original (BLP2, palettised, 8-bit alpha, same mips): keep the 148-byte header, zero the palette and all pixels
        put(base, rel, o[:148] + bytes(len(o) - 148))
        put(bbase, rel, o)
print('base textures not found in YJ (nothing to back up):', orig_missing)
json.dump({'verts': regcount, 'tex_new': TEX_NEW, 'tl_new': TL_NEW, 'tu_new': TU_NEW, 'skins': report['skins'], 'blp': [s[0] for s in blp_specs]},
          open(WORK + r'\build_report.json', 'w'), indent=1)
json.dump(uv2pts, open(WORK + r'\uv2pts.json', 'w'))
print('M2', len(m2_orig), '->', len(m2))
