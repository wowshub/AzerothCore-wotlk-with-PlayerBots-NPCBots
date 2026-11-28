# -*- coding: utf-8 -*-
import struct, sys, collections
sys.stdout.reconfigure(encoding='utf-8')
W = r'D:\_zsdc\seth_work'
O = W + r'\orig_true\01_导入Patch-YJ.mpq\Character\RebornUIR3A\Sethrak\Male' + '\\'
N = W + r'\out8\01_导入Patch-YJ.mpq\Character\RebornUIR3A\Sethrak\Male' + '\\'
ok = True
def chk(c, msg):
    global ok
    print(('PASS ' if c else 'FAIL ') + msg); ok = ok and c
m2 = open(N + 'Sethrak.m2', 'rb').read()
nV, oV = struct.unpack_from('<II', m2, 0x3C)
vz = [struct.unpack_from('<f', m2, oV + i * 48 + 8)[0] for i in range(nV)]
for sn in ('00', '01', '02', '03'):
    a = open(O + 'Sethrak%s.skin' % sn, 'rb').read(); b = open(N + 'Sethrak%s.skin' % sn, 'rb').read()
    ha = struct.unpack_from('<4sIIIIIIIIIII', a, 0); hb = struct.unpack_from('<4sIIIIIIIIIII', b, 0)
    _, nI, oI, nT, oT, nP, oP, nS, oS, nU, oU, _ = ha
    _, nI2, oI2, nT2, oT2, nP2, oP2, nS2, oS2, nU2, oU2, _ = hb
    chk(nI == nI2 and oI == oI2 and nT == nT2 and oT == oT2 and nP == nP2 and oP == oP2, 'skin%s indices/triangles/properties arrays keep place and size' % sn)
    chk(a[oI:oI + nI * 2] == b[oI:oI + nI * 2], 'skin%s vertex index list unchanged' % sn)
    chk(oS2 + nS2 * 48 <= oU2 and oU2 + nU2 * 24 == len(b), 'skin%s sections and batches arrays inside the file, batches at the end' % sn)
    # triangle multiset per original section unchanged
    idx = struct.unpack_from('<%dH' % nI, b, oI)
    same = True
    for i in range(nS):
        sid, lvl, vs, vc, ts, tc = struct.unpack_from('<HHHHHH', a, oS + i * 48)
        ta = collections.Counter(struct.unpack_from('<3H', a, oT + (ts + k) * 2) for k in range(0, tc, 3))
        tb = collections.Counter(struct.unpack_from('<3H', b, oT2 + (ts + k) * 2) for k in range(0, tc, 3))
        if ta != tb: same = False
    chk(same, 'skin%s every original section still draws exactly the same triangles' % sn)
    # original sections untouched, new ones valid
    chk(a[oS:oS + nS * 48] == b[oS2:oS2 + nS * 48], 'skin%s original sections untouched' % sn)
    for j in range(nS, nS2):
        sid, lvl, vs, vc, ts, tc = struct.unpack_from('<HHHHHH', b, oS2 + j * 48)
        zs = [vz[idx[struct.unpack_from('<H', b, oT2 + (ts + k) * 2)[0]]] for k in range(0, tc)]
        chk(ts + tc <= nT and tc % 3 == 0 and max(zs) < 2.6 and all(True for _ in zs), 'skin%s new section %d: triangles %d..%d inside the array' % (sn, j, ts, ts + tc))
        hz = sum(1 for k in range(0, tc, 3) if (vz[idx[struct.unpack_from('<H', b, oT2 + (ts + k) * 2)[0]]] + vz[idx[struct.unpack_from('<H', b, oT2 + (ts + k + 1) * 2)[0]]] + vz[idx[struct.unpack_from('<H', b, oT2 + (ts + k + 2) * 2)[0]]]) / 3 >= 1.95)
        chk(hz == 0, 'skin%s new section %d has no head triangles' % (sn, j))
    added = [struct.unpack_from('<BbHHHHHHHHHHH', b, oU2 + i * 24) for i in range(nU, nU2)]
    chk(all(x[3] >= nS and x[3] < nS2 and x[6] == 0 and x[7] == 2 and x[8] == 1 and x[9] == 4 and x[10] == 2 for x in added),
        'skin%s %d overlay batches use the new body-only sections' % (sn, len(added)))
print('ALL PASS' if ok else 'SOME FAILED')
