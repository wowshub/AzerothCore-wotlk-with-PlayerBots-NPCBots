# -*- coding: utf-8 -*-
"""Shared setup for the two new maps: tile tables from the retail WDTs, aliases and batch lists for the converter."""
import struct, subprocess, os, io, sys, shutil
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
W = r'D:\_zsdc\maps2'
PROBE = r'D:\_zsdc\home64f\w\build-x64\Release\RetailAssetProbe.exe'
J = os.path.join
B = chr(92)
MAPS = {12570: ('ForbiddenReach', 4637866), 12694: ('Harandar', 5413167)}


def chunks(d):
    o = 0
    while o + 8 <= len(d):
        t = d[o:o + 4][::-1]
        n = struct.unpack_from('<I', d, o + 4)[0]
        yield t, d[o + 8:o + 8 + n]
        o += 8 + n


def ini(path):
    open(path, 'w', newline='\n').write('mode=local\npath=D:/wow12/World of Warcraft69587\nproduct=wow\nregion=us\n'
                                        'build=c9fa1a64b0170829cc5c5c98c71025c3\nlocale=2\naliases=aliases_maps.csv\n')


if __name__ == '__main__':
    os.makedirs(W, exist_ok=True)
    ini(J(W, 'probe.ini'))
    aliases = ['%d;World%sMaps%s%s%s%s.wdt' % (fdid, B, B, d, B, d) for d, fdid in MAPS.values()]
    open(J(W, 'aliases_maps.csv'), 'wb').write(('\r\n'.join(aliases) + '\r\n').encode())
    lst = J(W, 'wdt.txt')
    open(lst, 'w', newline='\n').write(''.join('retail/%d.wdt\n' % f for _, f in MAPS.values()))
    os.makedirs(J(W, 'rawwdt'), exist_ok=True)
    subprocess.run([PROBE, J(W, 'probe.ini'), '--extract-batch', lst, J(W, 'rawwdt')], check=True, capture_output=True, cwd=W)
    for mid, (d, fdid) in MAPS.items():
        ch = dict(chunks(open(J(W, 'rawwdt', '%d.wdt' % fdid), 'rb').read()))
        a = ch[b'MAID']
        tiles = []
        for ty in range(64):
            for tx in range(64):
                e = struct.unpack_from('<8I', a, (ty * 64 + tx) * 32)
                if e[0]:
                    tiles.append((tx, ty, e))
        open(J(W, '%d.tiles' % mid), 'w').write('\n'.join('%d %d %s' % (x, y, ' '.join(map(str, e))) for x, y, e in tiles) + '\n')
        names = ['World/Maps/%s/%s.wdt' % (d, d)]
        for x, y, e in tiles:
            for idx, s in ((0, ''), (1, '_obj0'), (2, '_obj1'), (3, '_tex0')):
                if e[idx]:
                    aliases.append('%d;World%sMaps%s%s%s%s_%d_%d%s.adt' % (e[idx], B, B, d, B, d, x, y, s))
            names.append('World/Maps/%s/%s_%d_%d.adt' % (d, d, x, y))
        open(J(W, '%d.adtlist' % mid), 'w', newline='\n').write('\n'.join(names) + '\n')
        minimap = sum(1 for _, _, e in tiles if e[7])
        print(mid, d, 'tiles', len(tiles), 'with minimap art', minimap, 'x', min(t[0] for t in tiles), max(t[0] for t in tiles), 'y', min(t[1] for t in tiles), max(t[1] for t in tiles))
    open(J(W, 'aliases_maps.csv'), 'wb').write(('\r\n'.join(aliases) + '\r\n').encode())
    print('alias lines', len(aliases))
