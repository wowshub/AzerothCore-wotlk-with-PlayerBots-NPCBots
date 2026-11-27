# -*- coding: utf-8 -*-
"""Check the new .map files against the converted tiles, and what floor exists under the retail start points."""
import struct, io, os, sys, glob, math, pickle, collections
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
exec(open(r'D:\_zsdc\maps2\prep.py', encoding='utf-8').read().split("if __name__")[0].replace("sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')", ''))
src = open(r'D:\000rebornWOW\000RebornWOWHighForkPRO\beascendskills\find-and-extract-retail-resources-for-wotlk\references\hz.py', encoding='utf-8').read().split("for name, X, Y, ref in")[0]
S = 533.3333333


def height(mid, X, Y):
    tx = int(math.floor(32 - Y / S))
    ty = int(math.floor(32 - X / S))
    s = src.replace("r'D:\\_zsdc\\er_srv\\ext\\maps\\12175%02d%02d.map' % (ty, tx)", "r'D:\\_zsdc\\maps2\\ext\\maps' + chr(92) + '%d%02d%02d.map' % (MID, ty, tx)")
    ns = {'MID': mid}
    exec(s, ns)
    return ns['height'](X, Y)


# retail creature positions give a ground-truth height sample for Harandar
d = pickle.load(open(r'D:\_zsdc\hara\survey.pkl', 'rb'))
f = lambda v: float(v.strip("'"))
start = (1263.35, 922.787, 1332.45)
print('Haranir spawn: retail z', start[2], '| terrain under it', round(height(12694, *start[:2]), 2))
near = [c for c in d['creature'] if (f(c['position_x']) - start[0]) ** 2 + (f(c['position_y']) - start[1]) ** 2 < 150 ** 2]
diff = []
for c in near:
    x, y, z = (f(c[k]) for k in ('position_x', 'position_y', 'position_z'))
    try:
        diff.append(z - height(12694, x, y))
    except Exception:
        pass
b = collections.Counter('on terrain (within 2 yd)' if abs(v) < 2 else 'above terrain (on a building or flying)' if v > 0 else 'below terrain' for v in diff)
print('retail spawns within 150 yd of start:', len(diff), dict(b))
print('creature height minus terrain, median %.2f' % sorted(diff)[len(diff) // 2])
for n, (X, Y) in {'Dracthyr parade ground': (6517, -3317), 'Dracthyr cave': (6020.53, -3207.81)}.items():
    print(n, 'terrain', round(height(12570, X, Y), 2))
pickle.dump(dict(near=near), open(os.path.join(W, 'near.pkl'), 'wb'))
