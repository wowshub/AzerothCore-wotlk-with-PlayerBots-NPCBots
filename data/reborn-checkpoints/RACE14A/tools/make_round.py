import os, sys, struct
from PIL import Image, ImageDraw

SP = os.path.dirname(os.path.abspath(__file__))
OUT = sys.argv[1]
SRC = os.path.join(SP, 'icons')
names = ['Titan', 'Mogu', 'Sureki', 'Centaur', 'Fungarian', 'LostOne', 'Stormforged', 'Qiraji', 'Nerubian', 'Dreadlord', 'Wretched', 'Moarg', 'Sporeling', 'Lich']

def blp2(im):
    """BLP2, type 1, encoding 3 (uncompressed BGRA), alpha 8, full mip chain - same layout as the existing icon-round.blp files."""
    w, h = im.size
    mips = []
    cur = im
    while True:
        mips.append(cur)
        if cur.size == (1, 1):
            break
        cur = cur.resize((max(1, cur.size[0] // 2), max(1, cur.size[1] // 2)), Image.BOX)
    data = []
    for m in mips:
        r, g, b, a = m.split()
        data.append(Image.merge('RGBA', (b, g, r, a)).tobytes())
    head = struct.pack('<4sIBBBBII', b'BLP2', 1, 3, 8, 8, 1, w, h)
    off = 20 + 64 + 64 + 1024
    offs, sizes = [], []
    for d in data:
        offs.append(off)
        sizes.append(len(d))
        off += len(d)
    offs += [0] * (16 - len(offs))
    sizes += [0] * (16 - len(sizes))
    return head + struct.pack('<16I', *offs) + struct.pack('<16I', *sizes) + b'\0' * 1024 + b''.join(data)

S = 4
for n in names:
    p0 = os.path.join(SRC, 'CoA_Race_%s.blp' % n)
    try:
        src0 = Image.open(p0).convert('RGBA')
    except Exception:
        raw = open(p0, 'rb').read()
        mg, ty, enc, ad, ae, mip, w, h = struct.unpack('<4sIBBBBII', raw[:20])
        assert enc == 3, enc
        off0 = struct.unpack('<I', raw[20:24])[0]
        px = raw[off0:off0 + w * h * 4]
        src0 = Image.frombytes('RGBA', (w, h), px, 'raw', 'BGRA')
    src = src0.resize((64, 64), Image.LANCZOS)
    big = src.resize((64 * S, 64 * S), Image.LANCZOS)
    mask = Image.new('L', (64 * S, 64 * S), 0)
    ImageDraw.Draw(mask).ellipse((2 * S, 2 * S, 62 * S - 1, 62 * S - 1), fill=255)
    mask = mask.resize((64, 64), Image.LANCZOS)
    out = src.copy()
    out.putalpha(mask)
    d = os.path.join(OUT, 'Reborn', 'Preview', 'RACE14', n)
    os.makedirs(d, exist_ok=True)
    open(os.path.join(d, 'icon-round.blp'), 'wb').write(blp2(out))
    # self check: read back with Pillow
    chk = Image.open(os.path.join(d, 'icon-round.blp'))
    assert chk.size == (64, 64), chk.size
print('ok', len(names))
