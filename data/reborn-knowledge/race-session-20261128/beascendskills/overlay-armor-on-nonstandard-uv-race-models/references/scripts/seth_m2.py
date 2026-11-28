# -*- coding: utf-8 -*-
import sys, struct, ctypes, collections
sys.stdout.reconfigure(encoding='utf-8')
exec(open(r'D:\_zsdc\cls_check.py', encoding='utf-8').read().split("D = r'")[0])


def rd(mpq, name):
    h = ctypes.c_void_p()
    if not L.SFileOpenArchive(mpq, 0, 0x100, ctypes.byref(h)):
        return None
    f = ctypes.c_void_p()
    if not L.SFileOpenFileEx(h, name.encode(), 0, ctypes.byref(f)):
        L.SFileCloseArchive(h); return None
    sz = L.SFileGetFileSize(f, None)
    buf = ctypes.create_string_buffer(sz); n = ctypes.c_uint()
    L.SFileReadFile(f, buf, sz, ctypes.byref(n), None)
    L.SFileCloseFile(f); L.SFileCloseArchive(h)
    return buf.raw[:n.value]


def analyse(label, m2, skin):
    print('=====', label, 'm2', len(m2), 'skin', len(skin))
    magic, ver = struct.unpack_from('<4sI', m2, 0)
    nTex, ofsTex = struct.unpack_from('<II', m2, 0x50)
    nTexLookup, ofsTexLookup = struct.unpack_from('<II', m2, 0x80)
    print(magic, ver, 'textures', nTex)
    texs = []
    for i in range(nTex):
        t, fl, nl, no = struct.unpack_from('<IIII', m2, ofsTex + i * 16)
        nm = m2[no:no + nl].split(b'\0')[0].decode('latin1') if nl else ''
        texs.append((t, nm))
        print('  tex', i, 'type', t, nm)
    lookup = list(struct.unpack_from('<%dH' % nTexLookup, m2, ofsTexLookup))
    print('  texlookup', lookup)
    # skin
    m, nI, oI, nT, oT, nP, oP, nS, oS, nU, oU, bones = struct.unpack_from('<4sIIIIIIIIIII', skin, 0)
    subs = []
    for i in range(nS):
        sid = struct.unpack_from('<H', skin, oS + i * 48)[0]
        subs.append(sid)
    print('  submeshes', nS, sorted(subs))
    groups = collections.Counter(s // 100 for s in subs)
    print('  geoset groups', dict(sorted(groups.items())))
    combos = collections.Counter()
    for i in range(nU):
        fl, sh, si, si2, ci, rf, tun, mode, texid = struct.unpack_from('<BBHHhHHHH', skin, oU + i * 24)[:9]
        tx = lookup[texid] if texid < len(lookup) else -1
        ty = texs[tx][0] if 0 <= tx < len(texs) else None
        combos[(subs[si] // 100 if si < len(subs) else None, ty, texs[tx][1][-30:] if 0 <= tx < len(texs) else '')] += 1
    for k, v in sorted(combos.items(), key=lambda kv: str(kv[0])): print('  unit-combo (group, textype, name)', k, 'x', v)


D = r'D:\000rebornWOW\000RebornWOWHighForkPRO\beascendclient\newrebornWOWli20261107beAscend\Data\Patch-YB.mpq'
for sex, base in (('Male', 'Character\\RebornUIR3A\\Sethrak\\Male\\Sethrak'), ('Female', 'Character\\RebornUIR3A\\Sethrak\\Female\\Sethrak')):
    m2 = rd(D, base + '.m2')
    sk = rd(D, base + '00.skin') if sex == 'Male' else rd(D, 'Character\\RebornUIR3A\\Sethrak\\Female\\SethrakF00.skin')
    if m2 and sk:
        analyse('installed ' + sex, m2, sk)
    else:
        print('missing', sex, bool(m2), bool(sk))
P = r'D:\000rebornWOW\000RebornWOWResource\高清角色\德莱尼女性和男性塞斯拉克\Sethrak_for_Draenei_female_&_male+voice_attack,deatk_etc._v3\patch-D.mpq'
for sex, p in (('Male', 'character\\draenei\\male\\DraeneiMale'), ('Female', 'character\\draenei\\female\\draeneiFemale')):
    m2 = rd(P, p + '.m2'); sk = rd(P, p + '00.skin')
    if m2 and sk:
        analyse('pack ' + sex, m2, sk)
    else:
        print('missing pack', sex, bool(m2), bool(sk))
