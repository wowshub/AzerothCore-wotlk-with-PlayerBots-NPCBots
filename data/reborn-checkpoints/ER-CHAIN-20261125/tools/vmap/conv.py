"""Convert every building (WMO root+groups) and model (M2) used by the Exile's Reach tiles into 3.3.5 bytes (RetailAssetProbe --batch, PROBE_OUT)."""
import struct, glob, os, subprocess, sys
W = r'D:\_zsdc\vm12175'
PROBE = r'D:\_zsdc\home64f\w\build-x64\Release\RetailAssetProbe.exe'


def chunks(d):
    o = 0
    while o + 8 <= len(d):
        t = d[o:o + 4][::-1]; n = struct.unpack_from('<I', d, o + 4)[0]
        yield t, d[o + 8:o + 8 + n]
        o += 8 + n


def strings(b):
    return [x.decode('latin1') for x in b.split(b'\0') if x]


def run(tag, names, outdir):
    os.makedirs(outdir, exist_ok=True)
    todo = [n for n in names if not os.path.exists(os.path.join(outdir, n.split('/')[-1]))]
    print(tag, 'wanted', len(names), 'to convert', len(todo), flush=True)
    for i in range(0, len(todo), 100):
        part = todo[i:i + 100]
        lst = os.path.join(W, tag + '.txt')
        open(lst, 'w', newline='\n').write('\n'.join(part) + '\n')
        env = dict(os.environ, PROBE_OUT=outdir)
        r = subprocess.run([PROBE, os.path.join(W, 'probe.ini'), '--batch', lst], env=env, capture_output=True, text=True, errors='replace')
        bad = [l for l in (r.stdout + r.stderr).splitlines() if l and not l.startswith('ok ')]
        for l in bad[:5]:
            print('  ', l, flush=True)
        print(tag, i + len(part), '/', len(todo), 'rc', r.returncode, 'not-ok lines', len(bad), flush=True)


wmo, m2 = set(), set()
for p in glob.glob(r'D:\_zsdc\er_srv\out2\ExilesReach_*.adt'):
    ch = {}
    for t, b in chunks(open(p, 'rb').read()):
        ch.setdefault(t, b)
    wmo.update(n.replace('\\', '/').lower() for n in strings(ch.get(b'MWMO', b'')))
    m2.update(n.replace('\\', '/').lower() for n in strings(ch.get(b'MMDX', b'')))
wmo = sorted(wmo)
wdir = os.path.join(W, 'wmo')
run('wmo_roots', wmo, wdir)
groups = []
missing = []
for n in wmo:
    f = os.path.join(wdir, n.split('/')[-1])
    if not os.path.exists(f):
        missing.append(n); continue
    ch = dict(chunks(open(f, 'rb').read()))
    ng = struct.unpack_from('<I', ch[b'MOHD'], 4)[0]
    groups += ['%s_%03d.wmo' % (n[:-4], g) for g in range(ng)]
    m2.update(x.replace('\\', '/').lower() for x in strings(ch.get(b'MODN', b'')))
print('wmo roots', len(wmo), 'missing', missing, 'groups', len(groups), flush=True)
run('wmo_groups', groups, wdir)
m2n = sorted(x[:-4] + '.m2' if x.endswith(('.mdx', '.mdl')) else x for x in m2)
print('m2 names', len(m2n), m2n[:3], flush=True)
run('m2', sorted(set(m2n)), os.path.join(W, 'm2'))
print('DONE', flush=True)
