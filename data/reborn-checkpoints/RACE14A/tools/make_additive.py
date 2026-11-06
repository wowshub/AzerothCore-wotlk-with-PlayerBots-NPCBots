"""RACE14X1A: turn the merged 7 tables into rows-only continuation files for wxl-extended-dbc (name.dbc1-race14)."""
import struct, os, sys, json, hashlib

SP = os.path.dirname(os.path.abspath(__file__))
OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)
CHR_STR = [6, 11] + list(range(14, 30)) + list(range(31, 47)) + list(range(48, 64)) + [65, 66]
STRF = {'ChrRaces': CHR_STR, 'CreatureDisplayInfo': [6, 7, 8, 9], 'CreatureModelData': [2], 'CharSections': [4, 5, 6],
        'CharHairGeosets': [], 'CharacterFacialHairStyles': [], 'CharBaseInfo': []}

def load(p):
    x = open(p, 'rb').read()
    m, rc, fc, rs, ss = struct.unpack('<4sIIII', x[:20])
    return rc, fc, rs, x[20:20 + rc * rs], x[20 + rc * rs:]

report = {}
for name, strf in STRF.items():
    brc, bfc, brs, bbody, bst = load(os.path.join(SP, 'ybdbc', name + '.dbc'))
    nrc, nfc, nrs, nbody, nst = load(os.path.join(SP, 'out_dbc', name + '.dbc'))
    assert brs == nrs and bfc == nfc
    # our merge only appends rows, so the old rows are byte-identical and the new ones are the tail
    assert nbody[:brc * brs] == bbody, name
    tail = nbody[brc * brs:]
    n = len(tail) // brs
    st = bytearray(b'\0')
    cache = {0: 0}
    rows = []
    for i in range(n):
        r = bytearray(tail[i * brs:(i + 1) * brs])
        for f in strf:
            v = struct.unpack_from('<I', r, f * 4)[0]
            if v == 0:
                continue
            if v not in cache:
                e = nst.find(b'\0', v)
                cache[v] = len(st)
                st += nst[v:e + 1]
            struct.pack_into('<I', r, f * 4, cache[v])
        rows.append(bytes(r))
    body = b''.join(rows)
    data = b'WDBC' + struct.pack('<IIII', n, bfc, brs, len(st)) + body + bytes(st)
    fn = '%s.dbc1-race14' % name
    open(os.path.join(OUT, fn), 'wb').write(data)
    report[name] = (n, len(data), hashlib.sha256(data).hexdigest()[:12], brc)
    if name == 'CharacterFacialHairStyles':
        # sidecar: row ids continue the base order (the extension numbers base rows 1..N)
        ids = struct.pack('<%dI' % n, *range(brc + 1, brc + 1 + n))
        open(os.path.join(OUT, fn + '.wxlidx'), 'wb').write(ids)
for k, v in report.items():
    print(k, 'new rows', v[0], 'bytes', v[1], v[2], 'base rows', v[3])
