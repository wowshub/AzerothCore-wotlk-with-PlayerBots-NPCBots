# -*- coding: utf-8 -*-
import struct, sys, math, collections, colorsys
from PIL import Image, ImageDraw
sys.stdout.reconfigure(encoding='utf-8')
m2 = open(r'D:\_zsdc\dr\DraeneiMale.m2', 'rb').read()
nV, oV = struct.unpack_from('<II', m2, 0x3C)
V = []
for i in range(nV):
    o = oV + i * 48
    V.append((struct.unpack_from('<3f', m2, o), struct.unpack_from('<3f', m2, o + 20), struct.unpack_from('<2f', m2, o + 32)))
cx = 0.0
# the standard torso (upper) lives in u 0.5..1, v 0..0.375 of the 256 layout (rect 128,0,128,64 / 128,64,128,32 / 128,96,128,64 ...)
sel = [v for v in V if 0.5 <= v[2][0] <= 1.0 and 0.0 <= v[2][1] <= 0.375 and 1.3 <= v[0][2] <= 2.2]
print('torso-ish vertices', len(sel))
S = 512
img = Image.new('RGB', (S + 520, S), (16, 16, 20)); d = ImageDraw.Draw(img)
rows = collections.defaultdict(list)
for p, n, uv in sel:
    th = math.atan2(p[1], p[0] - cx)            # azimuth: 0 = front(+x), +pi/2 = +y side, pi = back
    h = (th + math.pi) / (2 * math.pi)
    r, g, b = colorsys.hsv_to_rgb(h, 1, 1)
    d.ellipse((uv[0] * S - 2, uv[1] * S - 2, uv[0] * S + 2, uv[1] * S + 2), fill=(int(r * 255), int(g * 255), int(b * 255)))
    rows[int(((th + math.pi) / (2 * math.pi)) * 12)].append(uv)
print('azimuth bin (0=back-left?... bin = (theta+pi)/2pi*12; theta 0=front)  -> mean u  mean v  n')
for k in sorted(rows):
    us = [u for u, v in rows[k]]; vs = [v for u, v in rows[k]]
    print(' bin %2d theta %+5.0f deg  mean u %.2f  v %.2f  n %d' % (k, (k + 0.5) / 12 * 360 - 180, sum(us) / len(us), sum(vs) / len(vs), len(us)))
# side view colour legend
for i in range(60):
    r, g, b = colorsys.hsv_to_rgb(i / 60, 1, 1)
    d.rectangle([S + 20 + i * 6, 20, S + 26 + i * 6, 40], fill=(int(r * 255), int(g * 255), int(b * 255)))
d.text((S + 20, 44), 'hue = azimuth: 0 left(-pi) ... 0.5 front(theta 0) ... 1 right(+pi)', fill=(255, 255, 255))
img.save(r'D:\_zsdc\dr_torso_uv.png')
