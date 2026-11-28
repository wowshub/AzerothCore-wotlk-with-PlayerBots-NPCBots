# -*- coding: utf-8 -*-
"""v4b: the face/underwear bake textures (FL/FU/LU/TU) are composited on top of the base in the face / torso / leg regions.
They were all-zero (black) and covered the baked head. Replace them by the matching crops of the baked composite."""
import os, sys
from PIL import Image
sys.stdout.reconfigure(encoding='utf-8')
W = r'D:\_zsdc\seth_work'
OT = W + r'\orig_true\01_导入Patch-YJ.mpq\Reborn\Bake'
OUT = W + r'\out8\01_导入Patch-YJ.mpq\Reborn\Bake'
CROP = {'FU': (0, 320, 256, 384), 'FL': (0, 384, 256, 512), 'TU': (256, 0, 512, 128), 'LU': (256, 192, 512, 320)}


def write_blp(img, orig_path, out_path):
    orig = open(orig_path, 'rb').read()
    w0, h0 = img.size
    pal_img = img.quantize(256, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.FLOYDSTEINBERG)
    pal = pal_img.getpalette()[:768]; pal = pal + [0] * (768 - len(pal))
    palette = bytearray()
    for i in range(256):
        palette += bytes([pal[i * 3 + 2], pal[i * 3 + 1], pal[i * 3], 255])
    data = bytearray()
    w, h = w0, h0
    while True:
        im = img.resize((w, h), Image.LANCZOS) if (w, h) != (w0, h0) else img
        q = im.quantize(palette=pal_img, dither=Image.Dither.FLOYDSTEINBERG)
        data += q.tobytes()
        data += bytes([255]) * (w * h)
        if w == 1 and h == 1: break
        w = max(1, w // 2); h = max(1, h // 2)
    out = orig[:148] + bytes(palette) + bytes(data)
    assert len(out) == len(orig), (os.path.basename(orig_path), len(out), len(orig))
    open(out_path, 'wb').write(out)


for c in range(6):
    comp = Image.open(W + r'\bake8_png\composite_t%d.png' % c).convert('RGB')
    for suf, box in CROP.items():
        name = 'skin11_t%d_%s.blp' % (c, suf)
        write_blp(comp.crop(box), OT + '\\' + name, OUT + '\\' + name)
print('wrote 24 crops')
