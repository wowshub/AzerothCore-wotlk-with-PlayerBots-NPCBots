"""Re-convert every WMO group in the same probe process as its root (otherwise groups >= 002 come back as the root file)."""
import struct, glob, os, subprocess, re
W = r'D:\_zsdc\vm12175'
PROBE = r'D:\_zsdc\home64f\w\build-x64\Release\RetailAssetProbe.exe'
D = os.path.join(W, 'wmo')


def chunks(d):
    o = 0
    while o + 8 <= len(d):
        t = d[o:o + 4][::-1]; n = struct.unpack_from('<I', d, o + 4)[0]
        yield t, d[o + 8:o + 8 + n]
        o += 8 + n


roots = sorted(os.path.basename(p) for p in glob.glob(D + r'\*.wmo') if not re.search(r'_\d{3}\.wmo$', p))
names, expect = [], []
for r in roots:
    ng = struct.unpack_from('<I', dict(chunks(open(os.path.join(D, r), 'rb').read()))[b'MOHD'], 4)[0]
    names.append('retail/' + r)
    for g in range(ng):
        n = '%s_%03d.wmo' % (r[:-4], g)
        names.append('retail/' + n); expect.append(n)
for n in expect:
    p = os.path.join(D, n)
    if os.path.exists(p):
        os.remove(p)
lst = os.path.join(W, 'all_wmo.txt')
open(lst, 'w', newline='\n').write('\n'.join(names) + '\n')
r = subprocess.run([PROBE, os.path.join(W, 'probe.ini'), '--batch', lst], env=dict(os.environ, PROBE_OUT=D), capture_output=True, text=True, errors='replace')
bad = [l for l in (r.stdout + r.stderr).splitlines() if l and not l.startswith('ok ')]
print('roots', len(roots), 'groups', len(expect), 'rc', r.returncode, 'not-ok', bad[:5])
wrong, missing = [], []
for n in expect:
    p = os.path.join(D, n)
    if not os.path.exists(p):
        missing.append(n); continue
    if b'MOGP' not in dict(chunks(open(p, 'rb').read())):
        wrong.append(n)
print('missing', len(missing), 'without MOGP', len(wrong), (missing + wrong)[:12])
