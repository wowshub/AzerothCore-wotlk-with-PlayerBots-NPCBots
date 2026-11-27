# -*- coding: utf-8 -*-
"""Retail art from the local data: Harandar world map and loading screen, minimap tiles of both maps -> 3.3.5 BLP files."""
import struct, io, os, sys, csv, subprocess, hashlib, glob
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', line_buffering=True)
from PIL import Image
exec(open(r'D:\_zsdc\maps2\prep.py', encoding='utf-8').read().split("if __name__")[0].replace("sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')", ''))
sys.path.insert(0, r'D:\_zsdc\home64f\w\source\docs\housing\tools\ui')
sys.path.insert(1, r'D:\_zsdc\er_srv')
from make_worldmap import blp
from blp_dxt1 import dxt1_level
G = r'D:\_zsdc\wago69587'
RAW = J(W, 'blpraw')
OUT = J(W, 'art')
os.makedirs(RAW, exist_ok=True)
art = [r for r in csv.DictReader(open(J(G, 'UiMapArtTile.csv'), encoding='utf-8-sig')) if r['UiMapArtID'] == '1942' and r['LayerIndex'] == '0']
LOADFDID = 7385003
mini = {}
for mid in MAPS:
    mini[mid] = []
    for l in open(J(W, '%d.tiles' % mid)).read().split('\n'):
        if l:
            t = l.split()
            if int(t[9]):
                mini[mid].append((int(t[0]), int(t[1]), int(t[9])))
want = sorted({int(r['FileDataID']) for r in art} | {LOADFDID} | {f for v in mini.values() for _x, _y, f in v})
todo = [f for f in want if not os.path.exists(J(RAW, '%d.blp' % f))]
print('art files wanted', len(want), 'to extract', len(todo))
for i in range(0, len(todo), 200):
    lst = J(W, 'blp.lst')
    open(lst, 'w', newline='\n').write(''.join('retail/%d.blp\n' % f for f in todo[i:i + 200]))
    r = subprocess.run([PROBE, J(W, 'probe.ini'), '--extract-batch', lst, RAW], capture_output=True, text=True, errors='replace', cwd=W)
    bad = [l for l in (r.stdout + r.stderr).splitlines() if l and not l.startswith('ok ')]
    if bad:
        print('  problems', bad[:4])
print('extracted', len([f for f in want if os.path.exists(J(RAW, '%d.blp' % f))]), 'of', len(want))
img = lambda f: Image.open(J(RAW, '%d.blp' % f))

# world map of Harandar: 15 x 10 retail tiles -> 3.3.5 4 x 3 tiles
cols = 1 + max(int(r['ColIndex']) for r in art)
rows_ = 1 + max(int(r['RowIndex']) for r in art)
canvas_art = Image.new('RGB', (cols * 256, rows_ * 256))
for r in art:
    canvas_art.paste(img(int(r['FileDataID'])).convert('RGB'), (int(r['ColIndex']) * 256, int(r['RowIndex']) * 256))
shown, canvas = (4008, 2672), (4096, 3072)
c = Image.new('RGBA', canvas, (0, 0, 0, 0))
c.paste(canvas_art.resize(shown, Image.LANCZOS), (0, 0))
wd = J(OUT, 'Interface', 'WorldMap', 'Harandar')
os.makedirs(wd, exist_ok=True)
for i in range(12):
    x, y = (i % 4) * 1024, (i // 4) * 1024
    open(J(wd, 'Harandar%d.blp' % (i + 1)), 'wb').write(blp(c.crop((x, y, x + 1024, y + 1024))))
c.crop((0, 0, 4008, 2672)).resize((1002, 668), Image.LANCZOS).save(J(W, 'preview_worldmap.png'))
print('world map written')

# loading screen (4:3 and wide)
im = img(LOADFDID).convert('RGBA')
op = im.getchannel('A').point(lambda a: 255 if a > 128 else 0)
cov = Image.composite(im.convert('L'), Image.new('L', im.size, 0), op)
im = im.convert('RGB').crop(cov.point(lambda v: 255 if v > 12 else 0).getbbox())
ld = J(OUT, 'Interface', 'Glues', 'LoadingScreens')
os.makedirs(ld, exist_ok=True)
for suffix, (aspect, size) in {'': (4 / 3, (2048, 2048)), 'Wide': (16 / 10, (4096, 2048))}.items():
    w = min(im.width, round(im.height * aspect))
    h = min(im.height, round(w / aspect))
    left, top = (im.width - w) // 2, (im.height - h) // 2
    cut = im.crop((left, top, left + w, top + h)).resize(size, Image.LANCZOS)
    open(J(ld, 'LoadScreenHarandar%s.blp' % suffix), 'wb').write(blp(cut, opaque=True))
    if not suffix:
        cut.resize((1024, 768)).save(J(W, 'preview_loading.png'))
print('loading screen written, source', im.size)


# minimap tiles: 256 x 256 DXT1 with mips, stored under hashed names, listed in md5translate.trs
def blp1(image):
    out = bytearray(148 + 1024)
    out[0:4] = b'BLP2'
    struct.pack_into('<I', out, 4, 1)
    out[8:12] = bytes((2, 0, 0, 1))
    struct.pack_into('<II', out, 12, image.width, image.height)
    level = image
    for mip in range(16):
        data = dxt1_level(level)
        struct.pack_into('<I', out, 20 + mip * 4, len(out))
        struct.pack_into('<I', out, 84 + mip * 4, len(data))
        out += data
        if level.size == (1, 1):
            break
        level = level.resize((max(1, level.width // 2), max(1, level.height // 2)), Image.BOX)
    return bytes(out)


md = J(OUT, 'textures', 'Minimap')
os.makedirs(md, exist_ok=True)
lines = []
for mid, (d, _f) in MAPS.items():
    lines.append('dir: %s' % d)
    n, sizes = 0, set()
    for x, y, f in mini[mid]:
        src = img(f)
        sizes.add(src.size)
        data = blp1(src.convert('RGB').resize((256, 256), Image.LANCZOS))
        name = hashlib.md5(('%s/map%d_%d' % (d, x, y)).encode()).hexdigest() + '.blp'
        open(J(md, name), 'wb').write(data)
        lines.append('%s%smap%02d_%02d.blp\t%s' % (d, B, x, y, name))
        n += 1
    print(mid, 'minimap tiles', n, 'source sizes', sizes)
open(J(W, 'md5translate_add.trs'), 'wb').write(('\r\n'.join(lines) + '\r\n').encode())
print('done')
