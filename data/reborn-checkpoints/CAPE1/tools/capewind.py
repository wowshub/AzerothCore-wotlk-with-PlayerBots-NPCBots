import sys, struct
exec(open(r'D:\_zsdc\godi_check.py', encoding='utf-8').read().split('hits=[]')[0])
for rel in sys.argv[1:]:
    p = rel.replace('/', BS); m, s = read(p)
    nV, oV = struct.unpack_from('<II', m, 0x3C)
    nM, oM = struct.unpack_from('<II', m, 0x70)
    mats = [struct.unpack_from('<HH', m, oM+i*4) for i in range(nM)]
    sk, ss = read(p[:-3] + '00.skin')
    _, nI, oI, nT, oT, nP, oP, nS, oS, nU, oU, bones = struct.unpack_from('<4sIIIIIIIIIII', sk, 0)
    idx = struct.unpack_from('<%dH' % nI, sk, oI); tri = struct.unpack_from('<%dH' % nT, sk, oT)
    secs = [struct.unpack_from('<HHHHHHHHHH', sk, oS + i*48) for i in range(nS)]
    P = lambda v: struct.unpack_from('<3f', m, oV+v*48); N = lambda v: struct.unpack_from('<3f', m, oV+v*48+20)
    print('==', rel)
    flags = {}
    for i in range(nU):
        fl, sh, si, si2, ci, rf, tun, mode, tc = struct.unpack_from('<HHHHhHHHH', sk, oU + i*24)[:9]
        if secs[si][0]//100 == 15: flags.setdefault(secs[si][0], set()).add((rf, mats[rf][0], mats[rf][1]))
    for sec in secs:
        if sec[0]//100 != 15: continue
        sid, lvl, vs, vc, is_, ic = sec[:6]
        pos = neg = 0
        for t in range(is_, is_+ic, 3):
            a, b, c = [idx[tri[t+k]] for k in range(3)]
            A, B, C = P(a), P(b), P(c)
            e1 = [B[k]-A[k] for k in range(3)]; e2 = [C[k]-A[k] for k in range(3)]
            n = (e1[1]*e2[2]-e1[2]*e2[1], e1[2]*e2[0]-e1[0]*e2[2], e1[0]*e2[1]-e1[1]*e2[0])
            vn = [sum(N(v)[k] for v in (a,b,c)) for k in range(3)]
            d = sum(n[k]*vn[k] for k in range(3))
            if d >= 0: pos += 1
            else: neg += 1
        print(' %d tris agree-with-normal %d disagree %d  mat(render flags,blend) %s' % (sid, pos, neg, sorted(flags.get(sid, []))))
