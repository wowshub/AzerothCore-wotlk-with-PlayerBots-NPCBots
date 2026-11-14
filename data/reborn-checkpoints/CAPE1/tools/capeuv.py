import sys, struct
exec(open(r'D:\_zsdc\godi_check.py', encoding='utf-8').read().split('hits=[]')[0])
for rel in sys.argv[1:]:
    p = rel.replace('/', BS); m, s = read(p)
    nV, oV = struct.unpack_from('<II', m, 0x3C)
    sk, ss = read(p[:-3] + '00.skin')
    _, nI, oI, nT, oT, nP, oP, nS, oS, nU, oU, bones = struct.unpack_from('<4sIIIIIIIIIII', sk, 0)
    idx = struct.unpack_from('<%dH' % nI, sk, oI); tri = struct.unpack_from('<%dH' % nT, sk, oT)
    secs = [struct.unpack_from('<HHHHHHHHHH', sk, oS + i*48) for i in range(nS)]
    print('==', rel)
    for sec in secs:
        if sec[0]//100 != 15: continue
        sid, lvl, vs, vc, is_, ic = sec[:6]
        vs_set = set(idx[tri[t]] for t in range(is_, is_+ic))
        us = [struct.unpack_from('<2f', m, oV+v*48+32) for v in vs_set]
        bs = set();
        for v in vs_set:
            b = struct.unpack_from('<4B', m, oV+v*48+12); w = struct.unpack_from('<4B', m, oV+v*48+16)
            for bb, ww in zip(b, w):
                if ww: bs.add(bb)
        print(' %d verts %d  u %.2f..%.2f v %.2f..%.2f  bones %s' % (sid, len(vs_set), min(u[0] for u in us), max(u[0] for u in us), min(u[1] for u in us), max(u[1] for u in us), sorted(bs)[:14]))
