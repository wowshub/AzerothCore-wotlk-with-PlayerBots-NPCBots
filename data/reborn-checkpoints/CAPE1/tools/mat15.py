import sys, struct
exec(open(r'D:\_zsdc\godi_check.py', encoding='utf-8').read().split('hits=[]')[0])
for n in sys.argv[1:]:
    p = n.replace('/', BS); m, s = read(p)
    nM, oM = struct.unpack_from('<II', m, 0x70)
    mats = [struct.unpack_from('<HH', m, oM+i*4) for i in range(nM)]
    sk, ss = read(p[:-3] + '00.skin')
    _, nI, oI, nT, oT, nP, oP, nS, oS, nU, oU, bones = struct.unpack_from('<4sIIIIIIIIIII', sk, 0)
    secs = [struct.unpack_from('<HHHHHHHHHH', sk, oS + i*48) for i in range(nS)]
    print('==', n, s, 'materials', mats, 'ofsMat', hex(oM))
    use = {}
    for i in range(nU):
        fl, sh, si, si2, ci, rf, tun, mode, tc = struct.unpack_from('<HHHHhHHHH', sk, oU + i*24)[:9]
        use.setdefault(rf, []).append((secs[si][0], tc))
    for rf in sorted(use):
        g15 = [x[0] for x in use[rf] if x[0]//100==15]
        other = sorted(set(x[0]//100 for x in use[rf] if x[0]//100!=15))
        print('  material', rf, 'blend', mats[rf][1], 'flags', mats[rf][0], 'cape sections', g15, 'other groups', other)
