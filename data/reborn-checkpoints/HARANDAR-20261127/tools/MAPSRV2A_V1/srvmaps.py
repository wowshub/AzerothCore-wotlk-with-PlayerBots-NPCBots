# -*- coding: utf-8 -*-
"""Server rows (Map / LiquidType / AreaTable) for both maps, fake client for map_extractor, and the .map files."""
import struct, io, os, sys, glob, shutil, ctypes, subprocess, pickle, time
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', line_buffering=True)
exec(open(r'D:\_zsdc\maps2\prep.py', encoding='utf-8').read().split("if __name__")[0].replace("sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')", ''))
SRV = r'D:\000rebornWOW\000RebornWOWHighForkPRO\beascendserver\wowshub_playerbot_npcbot_newrace20261122Ascend'
DBC = J(SRV, 'Data', 'dbc')
OUT = J(W, 'out_dbc')
NAMES = {12570: u'Forbidden Reach 禁忌离岛', 12694: u'Harandar 哈籁尼尔出生地', 12175: None}
NEW_LIQ = [941, 1177, 1055, 1132, 1222, 1255]


class Dbc:
    def __init__(self, path):
        d = open(path, 'rb').read()
        magic, n, nf, rs, ss = struct.unpack_from('<4sIIII', d)
        assert magic == b'WDBC' and rs == nf * 4
        self.nf, self.rs = nf, rs
        self.recs = [list(struct.unpack_from('<%dI' % nf, d, 20 + i * rs)) for i in range(n)]
        self.strs = bytearray(d[20 + n * rs:])
        self.src = path

    def get(self, key):
        return next((r for r in self.recs if r[0] == key), None)

    def text(self, off):
        return self.strs[off:self.strs.index(0, off)].decode('utf-8', 'replace')

    def add(self, text):
        off = len(self.strs)
        self.strs += text.encode('utf-8') + b'\0'
        return off

    def blob(self, recs=None):
        recs = self.recs if recs is None else recs
        return struct.pack('<4sIIII', b'WDBC', len(recs), self.nf, self.rs, len(self.strs)) + b''.join(struct.pack('<%dI' % self.nf, *r) for r in recs) + bytes(self.strs)


os.makedirs(OUT, exist_ok=True)
mp = Dbc(J(DBC, 'Map.dbc'))
tpl = mp.get(12570)
assert tpl and mp.text(tpl[1]) == 'ForbiddenReach' and mp.nf == 66
print('12570 row: dir', mp.text(tpl[1]), 'area field', tpl[22], 'expansion', tpl[63], 'string fields set', [i for i in range(5, 22) if tpl[i]])
if not mp.get(12694):
    r = list(tpl)
    r[0] = 12694
    r[1] = mp.add('Harandar')
    nm = mp.add(NAMES[12694])
    for i in range(5, 21):
        if tpl[i]:
            r[i] = nm
    r[22] = 12694
    mp.recs.append(r)
mp.get(12570)[22] = 12570
open(J(OUT, 'Map.dbc'), 'wb').write(mp.blob())

lq = Dbc(J(DBC, 'LiquidType.dbc'))
w13 = lq.get(13)
assert w13
added = []
for k in NEW_LIQ:
    if not lq.get(k):
        r = list(w13)
        r[0] = k
        lq.recs.append(r)
        added.append(k)
open(J(OUT, 'LiquidType.dbc'), 'wb').write(lq.blob())

at = Dbc(J(DBC, 'AreaTable.dbc'))
base = at.get(12175)
assert base and at.nf == 36
used = {r[3] for r in at.recs}
free = [b for b in range(4095, 0, -1) if b not in used]
print('island row 12175 explore bit before', base[3], '(must be below 4096)')
fixed = {}
if base[3] >= 4096:
    base[3] = free.pop(0)
    fixed[12175] = base[3]
for mid in (12570, 12694):
    assert not at.get(mid), 'area %d already there' % mid
    r = list(at.get(12175))
    r[0], r[1], r[2], r[3] = mid, mid, 0, free.pop(0)
    nm = at.add(NAMES[mid])
    for i in range(11, 27):
        if r[i]:
            r[i] = nm
    at.recs.append(r)
    fixed[mid] = r[3]
open(J(OUT, 'AreaTable.dbc'), 'wb').write(at.blob())
other_bad = [(r[0], r[3]) for r in at.recs if r[3] != 0xFFFFFFFF and r[3] >= 4096]
print('liquid rows added', added, '| explore bits', fixed, '| other rows still over 4095:', len(other_bad), other_bad[:6])
open(J(W, 'base_hashes.txt'), 'w').write(''.join('%s %s\n' % (n, __import__('hashlib').sha256(open(J(DBC, n), 'rb').read()).hexdigest()) for n in ('Map.dbc', 'LiquidType.dbc', 'AreaTable.dbc')))

# ---- tiles with the map's own area id, then a fake client holding only these two maps
stage = J(W, 'stage')
shutil.rmtree(stage, ignore_errors=True)
files = []
for mid, (d, _f) in MAPS.items():
    od = J(stage, 'World', 'Maps', d)
    os.makedirs(od)
    shutil.copy2(J(W, 'adt%d' % mid, d + '.wdt'), J(od, d + '.wdt'))
    chunksn = 0
    for p in glob.glob(J(W, 'adt%d' % mid, d + '_*.adt')):
        b = bytearray(open(p, 'rb').read())
        o = 0
        while o + 8 <= len(b):
            tag = bytes(b[o:o + 4])[::-1]
            sz = struct.unpack_from('<I', b, o + 4)[0]
            if tag == b'MCNK':
                struct.pack_into('<I', b, o + 8 + 0x34, mid)
                chunksn += 1
            o += 8 + sz
        open(J(od, os.path.basename(p)), 'wb').write(bytes(b))
    print(mid, 'tiles staged', len(glob.glob(J(od, '*.adt'))), 'chunks set to area', mid, ':', chunksn)
sel = [mp.get(12570), mp.get(12694)]
os.makedirs(J(stage, 'DBFilesClient'))
open(J(stage, 'DBFilesClient', 'Map.dbc'), 'wb').write(mp.blob(sel))
open(J(stage, 'DBFilesClient', 'LiquidType.dbc'), 'wb').write(lq.blob())

L = ctypes.WinDLL(r'D:\soft\python3.9\Lib\site-packages\pympq\StormLib.dll')
L.SFileCreateArchive.argtypes = [ctypes.c_wchar_p, ctypes.c_uint32, ctypes.c_uint32, ctypes.POINTER(ctypes.c_void_p)]
L.SFileAddFileEx.argtypes = [ctypes.c_void_p, ctypes.c_wchar_p, ctypes.c_char_p, ctypes.c_uint32, ctypes.c_uint32, ctypes.c_uint32]
L.SFileCloseArchive.argtypes = [ctypes.c_void_p]
fake = J(W, 'fakeclient')
shutil.rmtree(fake, ignore_errors=True)
os.makedirs(J(fake, 'Data', 'enUS'))
h = ctypes.c_void_p()
mpq = J(fake, 'Data', 'enUS', 'locale-enUS.MPQ')
assert L.SFileCreateArchive(mpq, 0x00300000, 4096, ctypes.byref(h))
open(J(W, 'component.txt'), 'w').write('<Component version="12340" />\n')
files.append((J(W, 'component.txt'), 'component.wow-enUS.txt'))
for dp, _dn, fn in os.walk(stage):
    files += [(J(dp, f), os.path.relpath(J(dp, f), stage)) for f in fn]
for src, name in files:
    assert L.SFileAddFileEx(h, src, name.encode(), 0x80000200, 0x02, 0x02), name
L.SFileCloseArchive(h)
print('fake client archive', os.path.getsize(mpq) // 1048576, 'MB', len(files), 'files')

ext = J(W, 'ext')
shutil.rmtree(ext, ignore_errors=True)
os.makedirs(ext)
exe = J(ext, 'map_extractor.exe')
shutil.copy2(J(SRV, 'map_extractor.exe'), exe)
t0 = time.time()
with open(J(W, 'map_extractor.log'), 'wb') as lf:
    rc = subprocess.run([exe, '-i', fake, '-o', ext, '-e', '1'], cwd=ext, stdout=lf, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL, timeout=500).returncode
made = glob.glob(J(ext, 'maps', '*.map'))
print('map_extractor rc', rc, 'files', len(made), 'in %ds' % (time.time() - t0))
for mid in (12570, 12694):
    n = [p for p in made if os.path.basename(p).startswith(str(mid))]
    print(mid, 'map files', len(n), 'sample', [os.path.basename(p) for p in n[:3]])
print(open(J(W, 'map_extractor.log'), 'rb').read().decode('utf-8', 'replace')[-900:])
