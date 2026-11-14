# -*- coding: utf-8 -*-
# SETHCAPE1A: add cape geometry (geoset 1502..1508) + type-2 texture slot to the Sethrak M2 models.
# usage: python sethcape.py female|male outdir
import sys, struct, os, hashlib, math, json
exec(open(r'D:\_zsdc\godi_check.py', encoding='utf-8').read().split('hits=[]')[0])

sex = sys.argv[1]; outdir = sys.argv[2]
rel = ('Character/RebornUIR3A/Sethrak/Female/SethrakF.m2' if sex == 'female' else 'Character/RebornUIR3A/Sethrak/Male/Sethrak.m2')
# CAPEFIX: the game loads sethrakf.m2 (YJ) for the female, NOT Sethrak.m2 (YB) - proven by Logs/CapeDiag.log 2026-11-14
TRUE_ORIG = r'D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261114/claudefix_20261114_阶段SETHCAPE1A_蛇人男女披风网格_候选_Claude/00_真原件备份_回滚用_' + ('女性' if sex == 'female' else '男性') + '/'
# always build from the true originals saved by SETHCAPE1A (the client now holds the 1A files, which already contain a cape)
if sex == 'female':
    F_ORIG = r'D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261114/claudefix_20261114_阶段SETHCAPE1D_蛇人女性披风_改对文件SethrakF_Patch-YJ_候选_Claude/00_回滚用原件_Patch-YJ_女性SethrakF/'
    m2_orig = open(F_ORIG + rel, 'rb').read(); m2_src = 'true-original(1D backup)'
    skins_orig = {}
    for k in range(4):
        skins_orig[k] = (open(F_ORIG + rel[:-3] + '0%d.skin' % k, 'rb').read(), 'true-original(1D backup)')
else:
    m2_orig = open(TRUE_ORIG + rel, 'rb').read(); m2_src = 'true-original'
    skins_orig = {}
    for k in range(4):
        skins_orig[k] = (open(TRUE_ORIG + rel[:-3] + '0%d.skin' % k, 'rb').read(), 'true-original')
print('base', sex, m2_src, len(m2_orig), [skins_orig[k][1] for k in range(4)])

m2 = bytearray(m2_orig)
assert m2[:4] == b'MD20' and struct.unpack_from('<I', m2, 4)[0] == 264


def hdr(off): return struct.unpack_from('<II', m2, off)


def align16():
    while len(m2) % 16: m2.append(0)


nV, oV = hdr(0x3C)
P = [struct.unpack_from('<3f', m2, oV + i * 48) for i in range(nV)]

# ---------------------------------------------------------------- donor sets (back-of-body vertices present in every LOD)
big = {}
S = {}
for k, (sk, src) in skins_orig.items():
    _, nI, oI, nT, oT, nP, oP, nS, oS, nU, oU, lod = struct.unpack_from('<4sIIIIIIIIIII', sk, 0)
    assert nP == nI
    secs = [struct.unpack_from('<10H', sk, oS + i * 48) for i in range(nS)]
    bi = max((i for i in range(nS) if secs[i][0] == 0), key=lambda i: secs[i][3])
    big[k] = bi
    idx = struct.unpack_from('<%dH' % nI, sk, oI)
    vs, vc = secs[bi][2], secs[bi][3]
    S[k] = {idx[j]: j for j in range(vs, vs + vc)}
common = set(S[0])
for k in (1, 2, 3): common &= set(S[k])
print('donor candidates per LOD', {k: len(S[k]) for k in S}, 'common', len(common))
back = [v for v in common if P[v][0] < -0.02 and 1.0 < P[v][2] < 1.95 and abs(P[v][1]) < 0.45]
print('back donor vertices', len(back))
assert len(back) > 50

RIG = int(sys.argv[3]) if len(sys.argv) > 3 else None
RIGP = {}
if RIG is not None:
    nBL_, oBL_ = struct.unpack_from('<II', m2_orig, 0x78)
    BL_ = struct.unpack_from('<%dH' % nBL_, m2_orig, oBL_)
    for k, (sk_, src_) in skins_orig.items():
        _, nI_, oI_, nT_, oT_, nP_, oP_, nS_, oS_, nU_, oU_, lod_ = struct.unpack_from('<4sIIIIIIIIIII', sk_, 0)
        sec_ = struct.unpack_from('<10H', sk_, oS_ + big[k] * 48)
        window = list(BL_[sec_[7]:sec_[7] + sec_[6]])
        assert RIG in window, ('rigid bone not in the bone window of LOD', k, RIG)
        RIGP[k] = window.index(RIG)
    print('rigid bone', RIG, 'local index per LOD', RIGP)
LOW = int(sys.argv[4]) if len(sys.argv) > 4 else None
LOWP = {}
if LOW is not None:
    for k, (sk_, src_) in skins_orig.items():
        _, nI_, oI_, nT_, oT_, nP_, oP_, nS_, oS_, nU_, oU_, lod_ = struct.unpack_from('<4sIIIIIIIIIII', sk_, 0)
        sec_ = struct.unpack_from('<10H', sk_, oS_ + big[k] * 48)
        window = list(BL_[sec_[7]:sec_[7] + sec_[6]])
        # far LOD windows may lack the low bone: then both influences use the chest bone (rigid at that distance)
        LOWP[k] = window.index(LOW) if LOW in window else RIGP[k]
        if LOW not in window:
            print('  note: LOD', k, 'has no bone', LOW, '-> chest bone for both influences')
    print('low bone', LOW, 'local index per LOD', LOWP)

# ---------------------------------------------------------------- cape mesh (grid) placed behind the torso
STYLE = os.environ.get('STYLE', 'B')
Z_BOT = 1.04 if sex == 'male' else 1.16     # female tail starts higher (z<1.2), keep her shorter
if STYLE in ('A', 'A2', 'A3'):
    Z_TOP = 1.76; ROWS, COLS = 9, 8
else:
    Z_TOP = 1.84; ROWS, COLS = 14, 10
import math


def back_x(z):
    xs = [P[v][0] for v in back if abs(P[v][2] - z) < 0.06 and abs(P[v][1]) < 0.3]
    return min(xs) if xs else -0.15


X_TOP = min(back_x(Z_TOP + (Z_BOT - Z_TOP) * i / ROWS) for i in range(ROWS + 1)) - 0.03
print('cape style', STYLE, 'X_TOP', round(X_TOP, 3))
verts = []   # (x,y,z,u,v)
vfrac = []   # share of the low spine bone (0 at the shoulders, grows downwards)
prev_xc = None
for r in range(ROWS + 1):
    t = r / ROWS
    z = Z_TOP + (Z_BOT - Z_TOP) * t
    if STYLE in ('A', 'A2', 'A3'):
        # male-like: follows the back contour, but never moves forward again below a row (no fold at the waist indentation)
        xc = back_x(z) - 0.035 - 0.07 * t
        if prev_xc is not None: xc = min(xc, prev_xc - 0.004)
        hw = 0.22 + 0.08 * t                         # narrower than 1G
        wrap = 0.0
    else:
        xc = X_TOP - 0.02 * t - 0.055 * t * t        # hangs almost straight down, the hem only flares a little
        hw = 0.22 + 0.07 * t                         # narrower than 1G (was 0.27 + 0.09 t)
        wrap = 0.040 * (1 - t) ** 1.5 + 0.010        # less wrap around the shoulders than 1G
    prev_xc = xc
    for c in range(COLS + 1):
        s_ = c / COLS
        e = 2 * s_ - 1
        y = e * hw
        fold = (0.0 if STYLE in ('A', 'A2') else (0.017 * (0.6 + 0.4 * t) * (-math.cos(2 * math.pi * 1.5 * abs(e))) if STYLE == 'A3' else None)) if STYLE in ('A', 'A2', 'A3') else 0.022 * (0.45 + 0.55 * t) * math.sin(2 * math.pi * 1.5 * s_ + 0.5)   # folds also at the top
        x = xc + wrap * e * e + fold
        # cape texture is mirrored left/right: centre u=0.99, edges u=0.25 (same as the human and Kul Tiran capes)
        verts.append((x, y, z, 0.25 + 0.74 * (1 - abs(e)), 0.99 * t))
        vfrac.append(min(0.75, 0.75 * t ** 1.3))
# minimum clearance to the body surface (z-fighting made the folded side flicker)
CLEAR = 0.03
pushed = 0
body_pts = [q for q in P if -0.5 < q[0] < 0.0 and q[2] > 1.0]     # torso only: the snake tail (x down to -2.1) is not 'body' here
def body_limit(y, z):
    near = [q[0] for q in body_pts if abs(q[1] - y) < 0.07 and abs(q[2] - z) < 0.07]
    return min(near) - CLEAR if near else None
for i, (x, y, z, u, v) in enumerate(verts):
    a_l, b_l = body_limit(y, z), body_limit(-y, z)
    cands = [t for t in (a_l, b_l) if t is not None]
    if cands:
        limit = min(cands)              # same limit left and right -> symmetric result
        if x > limit:
            x = max(limit, x - 0.06)
            pushed += 1
    verts[i] = (x, y, z, u, v)
print('clearance: pushed back', pushed, 'of', len(verts), 'cape vertices')
tris = []
for r in range(ROWS):
    for c in range(COLS):
        a_ = r * (COLS + 1) + c; b_ = a_ + 1; d_ = a_ + (COLS + 1); e_ = d_ + 1
        tris += [(a_, d_, b_), (b_, d_, e_)]
# vertex normals from the triangles, facing backwards (-x)
nrm = [[0.0, 0.0, 0.0] for _ in verts]
for (i0, i1, i2) in tris:
    A, B, C = verts[i0], verts[i1], verts[i2]
    e1 = (B[0] - A[0], B[1] - A[1], B[2] - A[2]); e2 = (C[0] - A[0], C[1] - A[1], C[2] - A[2])
    n = (e1[1] * e2[2] - e1[2] * e2[1], e1[2] * e2[0] - e1[0] * e2[2], e1[0] * e2[1] - e1[1] * e2[0])
    for i in (i0, i1, i2):
        for k_ in range(3): nrm[i][k_] += n[k_]
for i, n in enumerate(nrm):
    L = math.sqrt(n[0] ** 2 + n[1] ** 2 + n[2] ** 2) or 1.0
    n = [n[0] / L, n[1] / L, n[2] / L]
    if n[0] > 0: n = [-n[0], -n[1], -n[2]]
    # blend with the plain backwards normal: no bright / dark spots at the pleats
    n = [0.45 * n[0] - 0.55, 0.45 * n[1], 0.45 * n[2]]
    L2 = math.sqrt(n[0] ** 2 + n[1] ** 2 + n[2] ** 2) or 1.0
    nrm[i] = [n[0] / L2, n[1] / L2, n[2] / L2]
NV = len(verts)
print('cape verts', NV, 'tris', len(tris))

# donor for each cape vertex: nearest back vertex in the (y, z) plane
donor = []
central = [q for q in back if abs(P[q][1]) < 0.15] or back
Z_CUT = 1.55
for (x, y, z, u, v) in verts:
    if STYLE == 'A3' or (STYLE == 'A2' and z < Z_CUT):
        # lower rows: the whole row uses the same central donor height (no arm / far-off bones, no skew)
        best = min(central, key=lambda q: abs(P[q][2] - z))
    else:
        best = min(back, key=lambda q: (P[q][1] - y) ** 2 + (P[q][2] - z) ** 2)
    donor.append(best)

# ---------------------------------------------------------------- M2 edits (append only)
# vertices
align16(); newV = len(m2)
old_vert_bytes = bytes(m2[oV:oV + nV * 48])
new_vert = bytearray()
for vi, ((x, y, z, u, v), dv) in enumerate(zip(verts, donor)):
    don = bytes(m2[oV + dv * 48:oV + dv * 48 + 48])
    w = don[12:16]; bi_ = don[16:20]
    if RIG is not None:
        wl = int(round(255 * vfrac[vi])) if LOW is not None else 0
        w = bytes([255 - wl, wl, 0, 0]); bi_ = bytes([RIGP[0], LOWP[0] if LOW is not None else 0, 0, 0])
    new_vert += struct.pack('<3f', x, y, z) + w + bi_ + struct.pack('<3f', *nrm[vi]) + struct.pack('<2f', u, v) + struct.pack('<2f', 0.0, 0.0)
m2 += old_vert_bytes + new_vert
struct.pack_into('<II', m2, 0x3C, nV + NV, newV)
CAPE_V0 = nV                                   # first new vertex id
# textures: append a type-2 (cloak) slot
nTex, oTex = hdr(0x50)
align16(); newTex = len(m2)
m2 += bytes(m2_orig[oTex:oTex + nTex * 16]) + struct.pack('<IIII', 2, 0, 0, 0)
struct.pack_into('<II', m2, 0x50, nTex + 1, newTex)
TEX_NEW = nTex
# texture lookup
nTL, oTL = hdr(0x80)
tl = list(struct.unpack_from('<%dH' % nTL, m2_orig, oTL)) + [TEX_NEW]
align16(); newTL = len(m2); m2 += struct.pack('<%dH' % len(tl), *tl)
struct.pack_into('<II', m2, 0x80, len(tl), newTL)
TL_NEW = len(tl) - 1
# replaceable texture table: type 2 -> the new texture (extend if needed)
nR, oR = hdr(0x68)
rep = list(struct.unpack_from('<%dH' % nR, m2_orig, oR))
while len(rep) < 3: rep.append(0xFFFF)
assert rep[2] == 0xFFFF, rep
rep[2] = TEX_NEW
align16(); newR = len(m2); m2 += struct.pack('<%dH' % len(rep), *rep)
struct.pack_into('<II', m2, 0x68, len(rep), newR)
# materials: append (flags 4 = two-sided, blend 0 = opaque)
nM, oM = hdr(0x70)
mats = bytes(m2_orig[oM:oM + nM * 4]) + struct.pack('<HH', 4, 0)
align16(); newM = len(m2); m2 += mats
struct.pack_into('<II', m2, 0x70, nM + 1, newM)
MAT_NEW = nM
# uv set 0 lookup index
nTU, oTU = hdr(0x88)
tu = list(struct.unpack_from('<%dH' % nTU, m2_orig, oTU))
TU0 = tu.index(0)

# ---------------------------------------------------------------- skins
GEOSETS = list(range(1501, 1511))   # 1501 = default (display group 0); client DBC cloak groups are 0..9 -> 1501..1510
skins_new = {}
for k, (sk0, src) in skins_orig.items():
    sk = bytearray(sk0)
    _, nI, oI, nT, oT, nP, oP, nS, oS, nU, oU, lod = struct.unpack_from('<4sIIIIIIIIIII', sk, 0)
    idx = list(struct.unpack_from('<%dH' % nI, sk, oI))
    props = bytes(sk[oP:oP + nP * 4])
    donor_sec = bytearray(sk[oS + big[k] * 48:oS + (big[k] + 1) * 48])
    # new vertex entries / props / triangles
    new_idx = [CAPE_V0 + i for i in range(NV)]
    new_props = b''.join(bytes(sk[oP + S[k][dv] * 4:oP + S[k][dv] * 4 + 4]) for dv in donor)
    if RIG is not None:
        new_props = b''.join(bytes([RIGP[k], LOWP[k] if LOW is not None else 0, 0, 0]) for _ in range(NV))
    new_tris = [(nI + a, nI + b, nI + c) for (a, b, c) in tris]
    assert nI + NV < 65536 and nT + len(new_tris) * 3 < 65536
    while len(sk) % 4: sk.append(0)
    newI = len(sk); sk += struct.pack('<%dH' % (nI + NV), *(idx + new_idx))
    while len(sk) % 4: sk.append(0)
    newT = len(sk); sk += bytes(sk0[oT:oT + nT * 2]) + b''.join(struct.pack('<3H', *t) for t in new_tris)
    while len(sk) % 4: sk.append(0)
    newP = len(sk); sk += props + new_props
    # sections
    cx = sum(v[0] for v in verts) / NV; cy = 0.0; cz = sum(v[2] for v in verts) / NV
    rad = max(math.dist((v[0], v[1], v[2]), (cx, cy, cz)) for v in verts)
    new_secs = bytearray()
    for gid in GEOSETS:
        raw = bytearray(donor_sec)
        struct.pack_into('<HHHHHH', raw, 0, gid, 0, nI, NV, nT, len(new_tris) * 3)
        struct.pack_into('<3f', raw, 20, cx, cy, cz)
        struct.pack_into('<3f', raw, 32, cx, cy, cz)
        struct.pack_into('<f', raw, 44, rad)
        new_secs += raw
    while len(sk) % 4: sk.append(0)
    newS = len(sk); sk += bytes(sk0[oS:oS + nS * 48]) + bytes(new_secs)
    # texture units
    sample = struct.unpack_from('<BbHHHHHHHHHHH', sk0, oU)
    new_units = bytearray()
    for j, gid in enumerate(GEOSETS):
        f = list(sample)
        f[3] = nS + j       # section index
        f[4] = 0
        f[5] = 0xFFFF       # no color track
        f[6] = MAT_NEW      # material
        f[7] = 0            # layer
        f[8] = 1            # texture count
        f[9] = TL_NEW
        f[10] = TU0
        f[11] = 0; f[12] = 0
        new_units += struct.pack('<BbHHHHHHHHHHH', *f)
    while len(sk) % 4: sk.append(0)
    newU = len(sk); sk += bytes(sk0[oU:oU + nU * 24]) + bytes(new_units)
    struct.pack_into('<II', sk, 4, nI + NV, newI)
    struct.pack_into('<II', sk, 12, nT + len(new_tris) * 3, newT)
    struct.pack_into('<II', sk, 20, nP + NV, newP)
    struct.pack_into('<II', sk, 28, nS + len(GEOSETS), newS)
    struct.pack_into('<II', sk, 36, nU + len(GEOSETS), newU)
    skins_new[k] = bytes(sk)
    print('skin', k, 'size', len(sk0), '->', len(sk), 'donor section', big[k])

# ---------------------------------------------------------------- write
def put(root, relp, data):
    d = os.path.join(root, *relp.split('/')[:-1]); os.makedirs(d, exist_ok=True)
    open(os.path.join(d, relp.split('/')[-1]), 'wb').write(data)


patch_name = 'Patch-YJ'
sex_cn = '女性' if sex == 'female' else '男性'
# folder names carry the target patch so the user never has to open the README to know where to import
new_root = os.path.join(outdir, '01_导入%s_%s_5个文件' % (patch_name, sex_cn))
old_root = os.path.join(outdir, '00_回滚用原件_%s_%s' % (patch_name, sex_cn))
put(new_root, rel, bytes(m2)); put(old_root, rel, bytes(m2_orig))
for k in range(4):
    r = rel[:-3] + '0%d.skin' % k
    put(new_root, r, skins_new[k]); put(old_root, r, skins_orig[k][0])
json.dump({'sex': sex, 'cape_verts': NV, 'cape_tris': len(tris), 'geosets': GEOSETS, 'texture_index': TEX_NEW,
           'material_index': MAT_NEW, 'donors': len(set(donor)), 'src': [m2_src] + [skins_orig[k][1] for k in range(4)]},
          open(os.path.join(outdir, 'build_%s.json' % sex), 'w'), ensure_ascii=False, indent=1)
print('written', new_root)
# preview: side view of the body back + cape
