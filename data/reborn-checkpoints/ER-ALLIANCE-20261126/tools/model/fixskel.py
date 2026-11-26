# -*- coding: utf-8 -*-
"""Work around the converter's inherited-skeleton bug for Jaina only (no client code change).

The converter appends the parent skeleton's animations after the child's but keeps their parent-relative alias index, so
loading an external .anim also relocates unrelated sequences into that file. Here a private copy of the parent skeleton
(new id, so no other model sees it) carries merged-relative self aliases, and the child skeleton points at that copy."""
import struct, hashlib, os
CHILD_ID, PARENT_ID, PRIVATE_ID = 5838022, 2137789, 99000001
D = r'D:\_zsdc\models4'
OUT = os.path.join(D, 'skelfix')
os.makedirs(OUT, exist_ok=True)


def chunks(path):
    d = open(path, 'rb').read()
    o, out = 0, []
    while o < len(d):
        n = struct.unpack_from('<I', d, o + 4)[0]
        out.append([d[o:o + 4], bytearray(d[o + 8:o + 8 + n])])
        o += 8 + n
    assert o == len(d)
    return out


def get(c, tag):
    return next(x for x in c if x[0] == tag)[1]


child = chunks(os.path.join(D, 'skel', '%d.skel' % CHILD_ID))
parent = chunks(os.path.join(D, 'skel', 'packed_%d.bin' % PARENT_ID))  # the client reads this version (Patch-YK)
u32 = lambda b, p: struct.unpack_from('<I', b, p)[0]
u16 = lambda b, p: struct.unpack_from('<H', b, p)[0]


def records(c):
    s = get(c, b'SKS1')
    n, o = u32(s, 8), u32(s, 12)
    return s, [bytes(s[o + 64 * i:o + 64 * i + 64]) for i in range(n)], o


_, crec, _ = records(child)
ps, prec, poff = records(parent)
ident = lambda r: (u16(r, 0), u16(r, 2))
child_ids = {ident(r) for r in crec}
merged = {}
next_index = len(crec)
for i, r in enumerate(prec):
    if ident(r) not in child_ids:
        merged[i] = next_index
        next_index += 1
assert not any(u32(r, 12) & 0x40 for r in crec)

afid = get(parent, b'AFID')
files = {(u16(afid, p), u16(afid, p + 2)): u32(afid, p + 4) for p in range(0, len(afid), 8)}
new_records = list(prec)
copies = []     # (alias sequence, owner sequence)
for i, m in merged.items():
    r = prec[i]
    owner, depth = i, 0
    while u32(prec[owner], 12) & 0x40:
        owner = u16(prec[owner], 62)
        depth += 1
        assert depth < len(prec)
    rec = bytearray(prec[owner])
    rec[0:4] = r[0:4]               # own animation id / variation
    rec[60:62] = r[60:62]           # own variation link (the converter remaps it)
    struct.pack_into('<H', rec, 62, m)
    new_records[i] = bytes(rec)
    if owner != i:
        copies.append((i, owner))
        key, okey = ident(r), ident(prec[owner])
        if not u32(rec, 12) & 0x20:
            assert files.get(okey), ('no file for owner', okey)
            files[key] = files[okey]
        else:
            files.pop(key, None)
for i, rec in enumerate(new_records):
    ps[poff + 64 * i:poff + 64 * i + 64] = rec


def copy_tracks(tag, stride, offsets):
    b = get(parent, tag)
    n, o = u32(b, 0), u32(b, 4)
    done = 0
    for k in range(n):
        for t in offsets:
            p = o + stride * k + t
            if u16(b, p + 2) != 0xffff:
                continue
            for arr in (p + 4, p + 12):
                cnt, off = u32(b, arr), u32(b, arr + 4)
                if tag == b'SKA1' or arr == p + 4 or cnt:
                    for alias, owner in copies:
                        if alias < cnt and owner < cnt:
                            b[off + 8 * alias:off + 8 * alias + 8] = b[off + 8 * owner:off + 8 * owner + 8]
                            done += 1
    return done


nb = copy_tracks(b'SKB1', 88, (16, 36, 56))
na = copy_tracks(b'SKA1', 40, (20,))
for x in parent:
    if x[0] == b'AFID':
        x[1] = bytearray(b''.join(struct.pack('<HHI', k[0], k[1], v) for k, v in files.items()))
skpd = get(child, b'SKPD')
assert u32(skpd, 8) == PARENT_ID
struct.pack_into('<I', skpd, 8, PRIVATE_ID)
for name, c in (('%d.bin' % CHILD_ID, child), ('%d.bin' % PRIVATE_ID, parent)):
    data = b''.join(t + struct.pack('<I', len(p)) + bytes(p) for t, p in c)
    open(os.path.join(OUT, name), 'wb').write(data)
    print(name, len(data), hashlib.sha256(data).hexdigest()[:12])
print('child sequences', len(crec), 'inherited', len(merged), 'alias sequences made real', len(copies), 'track entries copied', nb, na)
