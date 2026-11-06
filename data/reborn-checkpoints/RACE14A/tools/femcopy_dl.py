import os, shutil, struct, sys, glob
YJ = sys.argv[1]
B = chr(92)
jobs = [('Dreadlord', 'DreadlordPlayerFemale', {'DreadLordSkin.blp': 'DreadLordSkinGreen.blp'}),
]
for d, base, swap in jobs:
    dd = os.path.join(YJ, 'Creature', d)
    for f in sorted(os.listdir(dd)):
        if f.startswith(base) and not f.startswith(base + 'F') and f.lower().endswith(('.m2', '.skin', '.anim')):
            nf = base + 'F' + f[len(base):]
            shutil.copyfile(os.path.join(dd, f), os.path.join(dd, nf))
    p = os.path.join(dd, base + 'F.m2')
    data = bytearray(open(p, 'rb').read())
    n, o = struct.unpack('<II', data[0x50:0x58])
    tail = bytearray()
    for k in range(n):
        t, fl, ln, no = struct.unpack('<IIII', data[o + k * 16:o + k * 16 + 16])
        if ln:
            nm = data[no:no + ln - 1].decode('latin1')
            leaf = nm.split(B)[-1]
            if leaf in swap:
                newnm = nm[:len(nm) - len(leaf)] + swap[leaf]
                b = (newnm + '\0').encode('latin1')
                off = len(data) + len(tail)
                tail += b
                data[o + k * 16:o + k * 16 + 16] = struct.pack('<IIII', t, fl, len(b), off)
                print(d, 'female', leaf, '->', swap[leaf], 'exists', os.path.exists(os.path.join(dd, swap[leaf])))
    open(p, 'wb').write(bytes(data) + bytes(tail))
