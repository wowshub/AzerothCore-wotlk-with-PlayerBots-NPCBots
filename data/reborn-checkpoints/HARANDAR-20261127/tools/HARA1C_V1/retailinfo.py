# -*- coding: utf-8 -*-
"""Harandar: area ids used by the raw retail tiles, their names, world map art and loading screen from the retail tables."""
import struct, io, os, sys, csv, glob, collections, pickle
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
G = r'D:\_zsdc\wago69587'
J = os.path.join
rd = lambda n: list(csv.DictReader(open(J(G, n), encoding='utf-8-sig')))
tiles = [l.split() for l in open(r'D:\_zsdc\maps2\12694.tiles').read().split('\n') if l]
areas = collections.Counter()
missing = 0
for t in tiles:
    p = r'D:\_zsdc\hara\probe\adt\%s.adt' % t[2]
    if not os.path.exists(p):
        missing += 1
        continue
    d = open(p, 'rb').read()
    o = 0
    while o + 8 <= len(d):
        tag = d[o:o + 4][::-1]
        n = struct.unpack_from('<I', d, o + 4)[0]
        if tag == b'MCNK':
            areas[struct.unpack_from('<I', d, o + 8 + 0x34)[0]] += 1
        o += 8 + n
en = {r['ID']: r for r in rd('AreaTable.csv')}
zh = {r['ID']: r for r in rd('AreaTable_zh.csv')}
print('raw tiles missing', missing, '| area ids', len(areas))
for a, n in areas.most_common():
    e = en.get(str(a), {})
    print('  %6d chunks %6d parent %-6s bit %-5s map %-5s %s | %s' % (a, n, e.get('ParentAreaID'), e.get('AreaBit'), e.get('ContinentID'), e.get('AreaName_lang'), zh.get(str(a), {}).get('AreaName_lang')))
asg = [r for r in rd('UiMapAssignment.csv') if r.get('MapID') == '2694']
ui = {r['ID']: r for r in rd('UiMap.csv')}
print('UiMapAssignment rows for 2694:', len(asg))
for r in asg:
    u = ui.get(r['UiMapID'], {})
    if r.get('AreaID') in ('0', '15355') or u.get('Type') == '3':
        print('   uimap', r['UiMapID'], u.get('Name_lang'), 'type', u.get('Type'), 'area', r.get('AreaID'), 'region', [r.get('Region_%d' % i) for i in (0, 1, 3, 4)], 'ui', [r.get(k) for k in r if k.startswith('Ui') and ('Min' in k or 'Max' in k)])
x = [r for r in rd('UiMapXMapArt.csv') if r['UiMapID'] == '2413']
print('art ids for 2413:', [(r['UiMapArtID'], r.get('PhaseID')) for r in x])
if x:
    art = x[0]['UiMapArtID']
    tl = [r for r in rd('UiMapArtTile.csv') if r['UiMapArtID'] == art and r.get('LayerIndex') == '0']
    print('art tiles layer0', len(tl), 'rows', max(int(r['RowIndex']) for r in tl) + 1, 'cols', max(int(r['ColIndex']) for r in tl) + 1)
ls = rd('LoadingScreens.csv') if os.path.exists(J(G, 'LoadingScreens.csv')) else []
for r in ls:
    if r.get('ID') == '660':
        print('loading screen 660:', {k: v for k, v in r.items() if v not in ('0', '')})
pickle.dump(dict(areas=dict(areas)), open(r'D:\_zsdc\maps2\hara_areas.pkl', 'wb'))
