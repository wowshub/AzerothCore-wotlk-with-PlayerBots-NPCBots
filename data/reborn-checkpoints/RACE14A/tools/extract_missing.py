import json, glob, os, struct, sys, mpyq
SP = os.path.dirname(os.path.abspath(__file__))
B = chr(92)
OUT = sys.argv[1]
rep = json.load(open(os.path.join(SP, 'race14_report.json')))
inv = json.load(open(os.path.join(SP, 'inv.json')))
done = json.load(open(os.path.join(SP, 'assets_done.json')))
pkg = set()
for v in inv.values():
    for f in v.get('files', []):
        pkg.add(f.lower())

want = {}
# 1) CharSections textures not in the 1.9.9 package, and package textures not yet extracted
for t in rep['textures']:
    if not t:
        continue
    k = t.lower()
    if k not in pkg or k not in done:
        want[k] = t
# 2) textures named inside the M2 files
for f in glob.glob(os.path.join(SP, 'm2', '*.m2')):
    d = open(f, 'rb').read()
    n, o = struct.unpack('<II', d[0x50:0x58])
    for i in range(n):
        t, fl, ln, no = struct.unpack('<IIII', d[o + i * 16:o + i * 16 + 16])
        if ln:
            nm = d[no:no + ln].split(b'\0')[0].decode('latin1')
            if nm and nm.lower() not in done:
                want[nm.lower()] = nm
print('wanted', len(want))

# from the package first
D = 'D:/000rebornWOW/000RebornWOWHighForkPRO/beascendclient/newrebornWOWli20261031beAscend/Data'
roots = [('coa', 'D:/game/ascend/coaWOW/coawowClinet20260925OFFICIAL/Data')]
found = {}
for tag, root in roots:
    fs = sorted(set(glob.glob(root + '/**/*.mpq', recursive=True) + glob.glob(root + '/**/*.MPQ', recursive=True)), key=str.lower)
    for f in fs:
        try:
            m = mpyq.MPQArchive(f, listfile=False)
        except Exception:
            continue
        for k, nm in want.items():
            try:
                d = m.read_file(nm)
            except Exception:
                d = None
            if d:
                found[k] = (nm, d, os.path.basename(f))   # later archive wins
        m.file.close()
print('found in full CoA client', len(found))
tot = 0
for k, (nm, d, a) in found.items():
    p = os.path.join(OUT, nm.replace(B, '/'))
    os.makedirs(os.path.dirname(p), exist_ok=True)
    open(p, 'wb').write(d)
    tot += len(d)
print('written', len(found), 'MB', round(tot / 1048576, 1))
miss = [nm for k, nm in want.items() if k not in found]
print('still missing', len(miss), miss[:30])
json.dump({k: [v[0], v[2], len(v[1])] for k, v in found.items()}, open(os.path.join(SP, 'extra_found.json'), 'w'))
