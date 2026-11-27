# -*- coding: utf-8 -*-
"""Which test-client archives hold the map tables and what rows already exist."""
import ctypes, os, io, sys, struct, hashlib, pickle, time
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', line_buffering=True)
B = chr(92)
ROOT = r'C:\000ref\WarcraftXL试装_client\Data' + B
L = ctypes.WinDLL(r'D:\soft\python3.9\Lib\site-packages\pympq\StormLib.dll')
P = ctypes.c_void_p
L.SFileOpenArchive.argtypes = [ctypes.c_wchar_p, ctypes.c_uint32, ctypes.c_uint32, ctypes.POINTER(P)]
L.SFileOpenArchive.restype = ctypes.c_bool
L.SFileOpenFileEx.argtypes = [P, ctypes.c_char_p, ctypes.c_uint32, ctypes.POINTER(P)]
L.SFileOpenFileEx.restype = ctypes.c_bool
L.SFileGetFileSize.argtypes = [P, ctypes.POINTER(ctypes.c_uint32)]
L.SFileGetFileSize.restype = ctypes.c_uint32
L.SFileReadFile.argtypes = [P, ctypes.c_void_p, ctypes.c_uint32, ctypes.POINTER(ctypes.c_uint32), ctypes.c_void_p]
L.SFileReadFile.restype = ctypes.c_bool
L.SFileCloseFile.argtypes = [P]
L.SFileCloseArchive.argtypes = [P]
NAMES = ['Map.dbc', 'AreaTable.dbc', 'WorldMapArea.dbc', 'LoadingScreens.dbc', 'LiquidType.dbc', 'WorldMapContinent.dbc', 'textures/Minimap/md5translate.trs']
OUT = r'D:\_zsdc\maps2\client_tables.pkl'


def loaded(name):
    n = name.lower().split(B)[-1]
    if ' ' in n or 'diable' in n or 'disable' in n or 'backup' in n or 'speech' in n:
        return False
    if name.lower().startswith('enus'):
        return n in ('locale-enus.mpq', 'expansion-locale-enus.mpq', 'lichking-locale-enus.mpq', 'patch-enus.mpq') or n[:-4] in ('patch-enus-2', 'patch-enus-3', 'patch-enus-4', 'patch-enus-5')
    return True


files = [f for f in os.listdir(ROOT) if f.lower().endswith('.mpq') and os.path.isfile(ROOT + f)]
files += ['enUS' + B + f for f in os.listdir(ROOT + 'enUS') if f.lower().endswith('.mpq') and os.path.isfile(ROOT + 'enUS' + B + f)]
files = [f for f in files if loaded(f)]
# resume support: archives already scanned are kept
state = pickle.load(open(OUT, 'rb')) if os.path.exists(OUT) else dict(found={n: [] for n in NAMES}, done=[])
found = state['found']
priority = ['patch-x', 'patch-zc', 'enus\\patch-enus', 'patch-y', 'patch-z', 'patch']
files.sort(key=lambda f: next((i for i, p in enumerate(priority) if f.lower().startswith(p)), 99))
t0 = time.time()
for f in files:
    if f in state['done']:
        continue
    if time.time() - t0 > 540:
        print('PAUSED, %d archives left' % len([x for x in files if x not in state['done']]))
        break
    h = P()
    if not L.SFileOpenArchive(ROOT + f, 0, 0x100 | 0x10000 | 0x20000, ctypes.byref(h)):
        print('cannot open', f)
        state['done'].append(f)
        continue
    got_here = []
    for n in NAMES:
        name = (n if '/' in n else 'DBFilesClient/' + n).replace('/', B)
        fh = P()
        if not L.SFileOpenFileEx(h, name.encode(), 0, ctypes.byref(fh)):
            continue
        sz = L.SFileGetFileSize(fh, None)
        if 0 < sz < 80000000:
            buf = ctypes.create_string_buffer(sz)
            got = ctypes.c_uint32()
            L.SFileReadFile(fh, buf, sz, ctypes.byref(got), None)
            if got.value == sz:
                found[n].append((f, buf.raw[:sz]))
                got_here.append(n.split('/')[-1])
        L.SFileCloseFile(fh)
    L.SFileCloseArchive(h)
    state['done'].append(f)
    state['trs'] = found[NAMES[-1]]
    pickle.dump(state, open(OUT, 'wb'))
    print('%5ds %-28s %s' % (time.time() - t0, f, got_here or ''))
else:
    print('SCAN COMPLETE')
for n in NAMES:
    print(n)
    for f, d in found[n]:
        extra = ''
        if d[:4] == b'WDBC':
            _, c, nf, rs, ss = struct.unpack_from('<4sIIII', d)
            ids = {struct.unpack_from('<I', d, 20 + i * rs)[0] for i in range(c)}
            extra = 'rows %d' % c
            if n == 'Map.dbc':
                extra += ' has %s' % [k for k in (13, 12175, 12261, 12369, 12570, 12694) if k in ids]
            if n == 'LiquidType.dbc':
                extra += ' has %s' % [k for k in (941, 1177, 1055, 1132, 1222, 1255) if k in ids]
        print('   %-28s %9d bytes sha %s %s' % (f, len(d), hashlib.sha256(d).hexdigest()[:12], extra))
