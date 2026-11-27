# -*- coding: utf-8 -*-
"""Convert every tile of both maps to 3.3.5 bytes, then every building (root + groups in one process) and model they use."""
import struct, subprocess, os, io, sys, glob, time, collections
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', line_buffering=True)
exec(open(r'D:\_zsdc\maps2\prep.py', encoding='utf-8').read().split("if __name__")[0].replace("sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')", ''))
t0 = time.time()
STEP = sys.argv[1]


def batch(names, outdir, tag, header=(), size=100):
    os.makedirs(outdir, exist_ok=True)
    bad = []
    for i in range(0, len(names), size):
        part = list(header) + names[i:i + size]
        lst = J(W, tag + '.lst')
        open(lst, 'w', newline='\n').write('\n'.join(part) + '\n')
        r = subprocess.run([PROBE, J(W, 'probe.ini'), '--batch', lst], env=dict(os.environ, PROBE_OUT=outdir), capture_output=True, text=True, errors='replace', cwd=W)
        lines = (r.stdout + r.stderr).splitlines()
        bad += [l for l in lines if l and not l.startswith('ok ')]
        done = sum(1 for l in lines if l.startswith(('ok ', 'fail ')))
        if done < len(part):
            bad.append('batch stopped: %d of %d, rc %d, next %s' % (done, len(part), r.returncode, part[done]))
        if (i // size) % 5 == 0:
            print('[%4ds] %s %d/%d problems %d' % (time.time() - t0, tag, i + len(names[i:i + size]), len(names), len(bad)))
    return bad


if STEP == 'adt':
    for mid, (d, fdid) in MAPS.items():
        names = open(J(W, '%d.adtlist' % mid)).read().split()
        wdt, tiles = names[0], names[1:]
        out = J(W, 'adt%d' % mid)
        todo = [n for n in tiles if not os.path.exists(J(out, n.split('/')[-1]))]
        bad = batch(todo, out, 'adt%d' % mid, header=[wdt], size=60)
        got = len(glob.glob(J(out, '%s_*.adt' % d)))
        print(mid, 'converted tiles', got, 'of', len(tiles), 'problems', len(bad))
        for l in bad[:8]:
            print('   ', l[:180])
elif STEP == 'assets':
    wmo, m2 = set(), set()
    for mid, (d, _) in MAPS.items():
        for p in glob.glob(J(W, 'adt%d' % mid, '*.adt')):
            ch = {}
            for t, b in chunks(open(p, 'rb').read()):
                ch.setdefault(t, b)
            for key, dest in ((b'MWMO', wmo), (b'MMDX', m2)):
                dest.update(x.decode('latin1').replace(B, '/').lower() for x in ch.get(key, b'').split(b'\0') if x)
    wmo = sorted(wmo)
    print('wmo roots', len(wmo), 'tile models', len(m2), 'sample', wmo[:2], sorted(m2)[:2])
    wdir = J(W, 'wmo')
    bad = batch(wmo, wdir, 'wmo_roots')
    print('root problems', len(bad), bad[:5])
    names, missing = [], []
    for n in wmo:
        f = J(wdir, n.split('/')[-1])
        if not os.path.exists(f):
            missing.append(n)
            continue
        ch = dict(chunks(open(f, 'rb').read()))
        ng = struct.unpack_from('<I', ch[b'MOHD'], 4)[0]
        m2.update(x.decode('latin1').replace(B, '/').lower() for x in ch.get(b'MODN', b'').split(b'\0') if x)
        names.append((n, ['%s_%03d.wmo' % (n[:-4], g) for g in range(ng)]))
    print('roots missing', len(missing), missing[:5], '| groups', sum(len(g) for _, g in names))
    # a root and its groups must go through one process, otherwise groups >= 002 come back as the root file
    pack, count, packs = [], 0, []
    for root, groups in names:
        if count + len(groups) + 1 > 150 and pack:
            packs.append(pack)
            pack, count = [], 0
        pack += [root] + groups
        count += len(groups) + 1
    if pack:
        packs.append(pack)
    bad = []
    for k, p in enumerate(packs):
        bad += batch(p, wdir, 'wmo_all', size=len(p))
    wrong = [g for _, gs in names for g in gs if not os.path.exists(J(wdir, g.split('/')[-1])) or b'MOGP' not in dict(chunks(open(J(wdir, g.split('/')[-1]), 'rb').read()))]
    print('group problems', len(bad), bad[:5], '| groups missing or not a group', len(wrong), wrong[:5])
    m2n = sorted({x[:-4] + '.m2' if x.endswith(('.mdx', '.mdl')) else x for x in m2})
    print('m2 to convert', len(m2n))
    mdir = J(W, 'm2')
    bad = batch([n for n in m2n if not os.path.exists(J(mdir, n.split('/')[-1]))], mdir, 'm2', size=150)
    print('m2 files', len(glob.glob(J(mdir, '*.m2'))), 'of', len(m2n), 'problems', len(bad))
    kinds = collections.Counter(l.split(':', 1)[-1].strip()[:90] for l in bad)
    print(kinds.most_common(8))
    for l in bad[:6]:
        print('   ', l[:180])
print('done in %ds' % (time.time() - t0))
