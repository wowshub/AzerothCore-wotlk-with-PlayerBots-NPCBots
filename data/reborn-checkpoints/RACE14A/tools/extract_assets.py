import zipfile, glob, os, json, mpyq, sys, hashlib, collections
SP = os.path.dirname(os.path.abspath(__file__))
B = chr(92)
OUT = sys.argv[1]
TMP = os.path.join(SP, 'mpq_tmp4')
os.makedirs(TMP, exist_ok=True)
inv = json.load(open(os.path.join(SP, 'inv.json')))
rep = json.load(open(os.path.join(SP, 'race14_report.json')))

skip_dirs = {'character' + B + 'nightborne' + B + 'male', 'character' + B + 'nightborne' + B + 'female'}
dirs = set()
for p in rep['model_paths']:
    d = p.rsplit(B, 1)[0].lower()
    if d not in skip_dirs:
        dirs.add(d)
dirs.add('character' + B + 'nightborne' + B + 'elune')

need = {}
for mp, v in inv.items():
    for f in v.get('files', []):
        lf = f.lower()
        d = lf.rsplit(B, 1)[0] if B in lf else ''
        if d in dirs or any(lf.startswith(x + B) for x in dirs):
            need[lf] = f   # original-case name

print('needed', len(need), 'dirs', len(dirs), flush=True)
done = {}
order = sorted(inv.keys(), key=lambda s: s.lower())
zips = sorted(glob.glob('D:/game/ascend/coa新种族/CoA-Races-Only-1.9.9/CoA-Races-Only-1.9.9-?.zip'))
loc = {}
for f in zips:
    z = zipfile.ZipFile(f)
    for i in z.infolist():
        if i.filename.lower().endswith('.mpq'):
            loc[os.path.basename(i.filename)] = (f, i.filename)
total = 0
for mp in order:
    files = [f for f in inv[mp].get('files', []) if f.lower() in need]
    if not files or mp not in loc:
        continue
    zf, zn = loc[mp]
    dst = os.path.join(TMP, mp)
    with zipfile.ZipFile(zf).open(zn) as s, open(dst, 'wb') as o:
        while True:
            b = s.read(1 << 22)
            if not b:
                break
            o.write(b)
    m = mpyq.MPQArchive(dst, listfile=False)
    n = 0
    for f in files:
        try:
            d = m.read_file(f)
        except Exception as e:
            d = None
        if d is None:
            continue
        p = os.path.join(OUT, f.replace(B, '/'))
        os.makedirs(os.path.dirname(p), exist_ok=True)
        open(p, 'wb').write(d)
        done[f.lower()] = (mp, len(d))
        n += 1
        total += len(d)
    m.file.close()
    os.remove(dst)
    print(mp, 'files', len(files), 'read', n, 'total MB', round(total / 1048576), flush=True)
missing = [need[k] for k in need if k not in done]
print('DONE', len(done), 'missing', len(missing), missing[:10])
json.dump({k: list(v) for k, v in done.items()}, open(os.path.join(SP, 'assets_done.json'), 'w'))
