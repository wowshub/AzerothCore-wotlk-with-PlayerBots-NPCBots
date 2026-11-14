import sys, struct
exec(open(r'D:\_zsdc\godi_check.py', encoding='utf-8').read().split('hits=[]')[0])
for n in sys.argv[1:]:
    p = n.replace('/', BS); m, s = read(p)
    nTex, oTex = struct.unpack_from('<II', m, 0x50); nTL, oTL = struct.unpack_from('<II', m, 0x80)
    nM, oM = struct.unpack_from('<II', m, 0x70)
    types = [struct.unpack_from('<I', m, oTex+i*16)[0] for i in range(nTex)]
    tl = list(struct.unpack_from('<%dH'%nTL, m, oTL))
    mats = [struct.unpack_from('<HH', m, oM+i*4) for i in range(nM)]
    sk, ss = read(p[:-3] + '00.skin')
    _, nI, oI, nT, oT, nP, oP, nS, oS, nU, oU, bones = struct.unpack_from('<4sIIIIIIIIIII', sk, 0)
    secs = [struct.unpack_from('<HHHHHHHHHH', sk, oS + i*48) for i in range(nS)]
    print('==', n, 'types', types, 'lookup', tl, 'materials(flags,blend)', mats)
    from collections import Counter
    c = Counter()
    for i in range(nU):
        fl, sh, si, si2, ci, rf, tun, mode, tc = struct.unpack_from('<HHHHhHHHH', sk, oU + i*24)[:9]
        t = types[tl[tc]] if tc < len(tl) else None
        c[(secs[si][0]//100, t, mats[rf][1] if rf < len(mats) else None)] += 1
    for k in sorted(c, key=lambda x:(x[0], str(x[1]))): print('  group', k[0], 'textype', k[1], 'blend', k[2], 'x', c[k])
