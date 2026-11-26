# -*- coding: utf-8 -*-
"""Convert the five dungeon models with the client's converter and check every file the client will ask for."""
import os, struct, subprocess, io, sys
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
B = chr(92)
W = r'D:\_zsdc\boss2'
PROBE = r'D:\_zsdc\fx\build\Release\RetailAssetProbe.exe'
OGRE_TEX = [937289, 960032, 937293, 937286, 937292, 937287, 937283, 960033, 937290, 960035, 960034, 937291, 937285]
MODELS = {  # folder: (m2 file id, [(texture file id, name)])
    'RetailOgre': (930099, [(t, 'Ogre%d' % t) for t in OGRE_TEX]),
    'RetailGorgroth': (3545238, []),
    'RetailTunk': (984967, [(985043, 'Tunk985043')]),
    'RetailKalec': (4238520, []),
    'RetailKalecDragon': (4496906, []),
}
base = lambda f: B.join(['retail', f, f])
alias = []
for f, (fdid, tex) in MODELS.items():
    alias.append('%d;%s.m2' % (fdid, base(f)))
    alias += ['%d;%s' % (t, B.join(['retail', f, n + '.blp'])) for t, n in tex]
open(W + B + 'aliases_maps.csv', 'w', newline='\r\n').write('\n'.join(alias) + '\n')
D = W + B + 'd'
os.makedirs(D, exist_ok=True)


def run(names, tag):
    open(W + B + tag + '.txt', 'w', newline='\r\n').write('\n'.join(names) + '\n')
    r = subprocess.run([PROBE, W + B + 'probe.ini', '--batch', W + B + tag + '.txt'], env=dict(os.environ, PROBE_DUMP=D), capture_output=True, cwd=W, timeout=580)
    lines = (r.stdout + r.stderr).decode('utf-8', 'replace').splitlines()
    ok = sum(x.startswith('ok ') for x in lines)
    print(tag, ok, '/', len(names), [x for x in lines if not x.startswith('ok ')][:12])
    return lines


flat = lambda name: D + B + name.replace(B, '_')
names = []
for f, (fdid, tex) in MODELS.items():
    names.append(base(f) + '.m2')
    names += [B.join(['retail', f, n + '.blp']) for t, n in tex]
run(names, 'first')
names = []
for f in MODELS:
    m = open(flat(base(f) + '.m2'), 'rb').read()
    cnt, off = struct.unpack_from('<II', m, 0x1c)
    views = struct.unpack_from('<I', m, 0x44)[0]
    ext = [struct.unpack_from('<HH', m, off + 64 * i) for i in range(cnt) if not struct.unpack_from('<I', m, off + 64 * i + 12)[0] & 0x60]
    print(f, 'size', len(m), 'views', views, 'seqs', cnt, 'external', len(ext))
    names.append(base(f) + '.m2')          # the converter learns the skin/anim file ids from the model in the same run
    names += [base(f) + '%02d.skin' % i for i in range(views)]
    names += [base(f) + '%04d-%02d.anim' % sv for sv in ext]
run(names, 'second')
