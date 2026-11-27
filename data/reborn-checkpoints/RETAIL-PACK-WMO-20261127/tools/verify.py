# -*- coding: utf-8 -*-
"""SLIM1A: open every collected map tile, building and model with the engine while the retail installation
is unreachable (path= points at a folder that does not exist). Whatever fails offline is run again with the
real installation; a name that works there and not offline means a file is missing from the pack."""
import io, os, pickle, re, shutil, subprocess, sys, time

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', line_buffering=True)
exec(open(r'D:\_zsdc\slim\collect.py', encoding='utf-8').read().split('def main():')[0].replace(
    "sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', line_buffering=True)", ''))

RET = J(STAGE, 'Data', 'Retail')
shutil.copyfile(J(CLIENT, 'Data', 'Retail', 'aliases_maps.csv'), J(RET, 'aliases_maps.csv'))
BASE = 'mode=local\npath=%s\nproduct=wow\nregion=us\nbuild=' + BUILD + '\nlocale=2\naliases=aliases_maps.csv\n'
OFF = J(RET, 'offline.ini')
ON = J(RET, 'online_check.ini')
assert not os.path.exists(r'D:\_zsdc\slim\no_such_folder')
open(OFF, 'w', newline='\n').write(BASE % 'D:/_zsdc/slim/no_such_folder')
open(ON, 'w', newline='\n').write(BASE % 'D:/wow12/World of Warcraft69587')

C = pickle.load(open(J(W, 'closure.pkl'), 'rb'))
groups = []                                 # lists of names that must share one process
for fid, p in C['alias']:
    if not p.lower().endswith('.wdt'):
        continue
    b = raw(fid)
    names = [p]
    for t, d in chunks(b):
        if t == b'DIAM':
            for i in range(len(d) // 32):
                if struct.unpack_from('<I', d, i * 32)[0]:
                    names.append('%s_%d_%d.adt' % (p[:-4], i % 64, i // 64))
    groups.append((os.path.basename(p.replace('\\', '/')), names))
wmo, m2 = [], []
for fid, k in sorted(C['seen'].items()):
    if k == 'wmo':
        b = raw(fid)
        if b is None:
            continue
        n = [len(d) // 4 for t, d in chunks(b) if t == b'DIFG']
        ids = [u32s(d) for t, d in chunks(b) if t == b'DIFG']
        wmo.append('retail/%d.wmo' % fid)
        wmo += ['retail/%d_%03d.wmo' % (fid, i) for i, g in enumerate(ids[0] if ids else ()) if g]
    elif k == 'm2':
        m2.append('retail/%d.m2' % fid)
m2 += [p for f, p in C['alias'] if p.lower().endswith('.m2')]
# keep a root and its groups in one batch
batch, cur = [], []
for name in wmo:
    if re.match(r'retail/\d+\.wmo$', name) and len(cur) > 2500:
        batch.append(cur)
        cur = []
    cur.append(name)
if cur:
    batch.append(cur)
groups += [('wmo%d' % i, b) for i, b in enumerate(batch)]
groups += [('m2_%d' % i, m2[i:i + 2000]) for i in range(0, len(m2), 2000)]


def run(ini, names, tag):
    lst = J(W, 'v_%s.txt' % tag)
    open(lst, 'w', newline='\n', encoding='utf-8').write(''.join(n + '\n' for n in names))
    r = subprocess.run([PROBE, ini, '--batch', lst], capture_output=True, cwd=W, timeout=3600)
    ok, bad = set(), {}
    for line in r.stdout.decode('utf-8', 'replace').splitlines():
        if line.startswith('ok '):
            ok.add(line[3:])
        elif line.startswith('fail '):
            n, _, e = line[5:].partition(': ')
            bad[n] = e
    done = ok | set(bad)
    for n in names:
        if n not in done:
            bad[n] = 'no answer (tool exit %s)' % r.returncode
    return ok, bad


report = {}
total_ok = total_bad = 0
for tag, names in groups:
    t = time.time()
    ok, bad = run(OFF, names, tag)
    total_ok += len(ok)
    total_bad += len(bad)
    print('%-22s offline ok %5d fail %4d  %ds' % (tag, len(ok), len(bad), time.time() - t))
    errs = {}
    for e in bad.values():
        errs[e] = errs.get(e, 0) + 1
    for e, c in sorted(errs.items(), key=lambda x: -x[1])[:5]:
        print('      %5d x %s' % (c, e[:150]))
    if bad:
        report[tag] = (names, bad)
pickle.dump(report, open(J(W, 'verify.pkl'), 'wb'))
print('TOTAL offline ok', total_ok, 'fail', total_bad)
# which of the failures are the pack's fault?
real = {}
for tag, (names, bad) in report.items():
    ok2, bad2 = run(ON, names if tag.startswith(('wmo', 'Harandar', 'ExilesReach', 'ForbiddenReach', 'test')) else list(bad), 'on_' + tag)
    diff = sorted(set(bad) & ok2)
    print('%-22s fails online too %4d, works only with the installation %4d' % (tag, len(set(bad) & set(bad2)), len(diff)))
    for n in diff[:6]:
        print('      ', n, '|', bad[n][:120])
    if diff:
        real[tag] = diff
pickle.dump(real, open(J(W, 'verify_missing.pkl'), 'wb'))
print('MISSING FROM PACK', sum(map(len, real.values())))
