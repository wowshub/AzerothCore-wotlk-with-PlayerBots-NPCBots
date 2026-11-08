# -*- coding: utf-8 -*-
import struct, sys, math, collections
from PIL import Image, ImageDraw
sys.stdout.reconfigure(encoding='utf-8')


def load(path):
    m2 = open(path, 'rb').read()
    nV, oV = struct.unpack_from('<II', m2, 0x3C)
    V = []
    for i in range(nV):
        o = oV + i * 48
        V.append((struct.unpack_from('<3f', m2, o), struct.unpack_from('<3f', m2, o + 20), struct.unpack_from('<2f', m2, o + 32)))
    return V


for name in ('DraeneiMale', 'HumanMale'):
    V = load(r'D:\_zsdc\dr\%s.m2' % name)
    zs = [v[0][2] for v in V]; xs = [v[0][0] for v in V]; ys = [v[0][1] for v in V]
    print(name, 'verts', len(V), 'x %.2f..%.2f y %.2f..%.2f z %.2f..%.2f' % (min(xs), max(xs), min(ys), max(ys), min(zs), max(zs)))
    us = [v[2][0] for v in V]; vs = [v[2][1] for v in V]
    print('  uv range', min(us), max(us), min(vs), max(vs))
# torso analysis on the draenei male: front (normal x > 0.5), back (normal x < -0.5), sides
V = load(r'D:\_zsdc\dr\DraeneiMale.m2')
cx = sum(v[0][0] for v in V) / len(V)
print('draenei mean x', cx)
def stats(sel, label):
    if not sel: print(label, 'none'); return
    us = [v[2][0] for v in sel]; vs = [v[2][1] for v in sel]
    print('%-28s n=%5d  u %.2f..%.2f  v %.2f..%.2f' % (label, len(sel), min(us), max(us), min(vs), max(vs)))
# torso band by height: pick z 1.1..1.8 (draenei scale?)
zmax = max(v[0][2] for v in V)
print('draenei zmax', zmax)
for lo, hi, lab in ((0.50, 0.62, 'torso upper'), (0.38, 0.5, 'torso lower')):
    pass
# generic: print uv bbox per direction for vertices in the middle height band, normalised by zmax
for lo, hi in ((0.60, 0.75), (0.45, 0.60)):
    band = [v for v in V if lo * zmax <= v[0][2] < hi * zmax and abs(v[0][1]) < 0.35]
    stats([v for v in band if v[1][0] > 0.6], 'z %.2f-%.2f front (nx>0.6)' % (lo, hi))
    stats([v for v in band if v[1][0] < -0.6], 'z %.2f-%.2f back  (nx<-0.6)' % (lo, hi))
    stats([v for v in band if v[1][1] > 0.6], 'z %.2f-%.2f side+y' % (lo, hi))
    stats([v for v in band if v[1][1] < -0.6], 'z %.2f-%.2f side-y' % (lo, hi))
# draw the UV usage of the whole body + colour by direction
S = 512
img = Image.new('RGB', (S * 2 + 20, S), (16, 16, 20)); d = ImageDraw.Draw(img)
for p, n, uv in V:
    u, vv = uv
    if n[0] > 0.6: c = (80, 200, 255)       # front = cyan
    elif n[0] < -0.6: c = (255, 120, 80)    # back = orange
    elif n[1] > 0.6: c = (120, 255, 120)    # +y side = green
    elif n[1] < -0.6: c = (255, 255, 90)    # -y side = yellow
    else: c = (140, 140, 140)
    d.point((u * S, vv * S), fill=c)
# the same vertices seen from the side, to check the orientation
for p, n, uv in V:
    d.point((S + 20 + 250 + p[0] * 120, S - 20 - p[2] / zmax * 460), fill=(200, 200, 200))
img.save(r'D:\_zsdc\dr_uv_layout.png')
print('saved')
