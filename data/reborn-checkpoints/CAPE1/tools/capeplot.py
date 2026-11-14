import sys, struct
exec(open(r'D:\_zsdc\godi_check.py', encoding='utf-8').read().split('hits=[]')[0])

from PIL import Image, ImageDraw
rel = sys.argv[1]; out = sys.argv[2]
p = rel.replace('/', BS); m, s = read(p)
nV, oV = struct.unpack_from('<II', m, 0x3C)
V = [struct.unpack_from('<3f', m, oV+i*48) for i in range(nV)]
sk, ss = read(p[:-3] + '00.skin')
_, nI, oI, nT, oT, nP, oP, nS, oS, nU, oU, bones = struct.unpack_from('<4sIIIIIIIIIII', sk, 0)
idx = struct.unpack_from('<%dH' % nI, sk, oI); tri = struct.unpack_from('<%dH' % nT, sk, oT)
secs = [struct.unpack_from('<HHHHHHHHHH', sk, oS + i*48) for i in range(nS)]
cape = [x for x in secs if x[0]//100 == 15]
W = 260; H = 420
img = Image.new('RGB', (W*len(cape), H), 'white'); d = ImageDraw.Draw(img)
for n, sec in enumerate(cape):
    sid, lvl, vs, vc, is_, ic = sec[:6]
    polys = [[(V[idx[tri[t+k]]][1], V[idx[tri[t+k]]][2]) for k in range(3)] for t in range(is_, is_+ic, 3)]
    ys = [q[0] for pl in polys for q in pl]; zs = [q[1] for pl in polys for q in pl]
    y0, y1, z0, z1 = min(ys), max(ys), min(zs), max(zs)
    sc = min((W-20)/max(y1-y0,1e-3), (H-40)/max(z1-z0,1e-3))
    for pl in polys:
        pts = [(n*W+10+(q[0]-y0)*sc, H-20-(q[1]-z0)*sc) for q in pl]
        d.polygon(pts, fill=(255,200,120), outline=(0,0,0))
    d.text((n*W+5, 3), '%d tris=%d' % (sid, ic//3), fill='black')
    print(sid, 'tris', ic//3, 'y %.2f..%.2f z %.2f..%.2f' % (y0, y1, z0, z1))
img.save(out)
