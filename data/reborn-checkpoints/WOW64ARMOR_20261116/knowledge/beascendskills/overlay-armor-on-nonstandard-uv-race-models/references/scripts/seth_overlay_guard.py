# -*- coding: utf-8 -*-
"""Guard check for the male Sethrak armour overlay (SETHARMOR1A v8).
Run it on a Sethrak.m2 that somebody edited on top of the overlay M2: it confirms the overlay is still intact.
usage: python seth_overlay_guard.py <Sethrak.m2> [reference overlay Sethrak.m2]
Exit code 0 = overlay intact, 1 = overlay damaged."""
import struct, sys, hashlib


def arr(m, off): return struct.unpack_from('<II', m, off)


def main():
    path = sys.argv[1]
    m = open(path, 'rb').read()
    ref = open(sys.argv[2], 'rb').read() if len(sys.argv) > 2 else None
    ok = True

    def chk(c, msg):
        nonlocal ok
        print(('PASS ' if c else 'FAIL ') + msg); ok = ok and c
    chk(m[:4] == b'MD20' and struct.unpack_from('<I', m, 4)[0] == 264, 'MD20 version 264')
    nTex, oTex = arr(m, 0x50)
    types = [struct.unpack_from('<I', m, oTex + i * 16)[0] for i in range(nTex)] if oTex + nTex * 16 <= len(m) else []
    chk(types == [8, 0, 0, 1], 'textures are [8,0,0,1] (the 4th is the character-skin overlay slot): %s' % types)
    nTL, oTL = arr(m, 0x80)
    tl = struct.unpack_from('<%dH' % nTL, m, oTL) if oTL + nTL * 2 <= len(m) else ()
    chk(len(tl) >= 5 and tl[4] == 3, 'texture lookup entry 4 -> texture 3 (the skins use lookup index 4): %s' % (tl,))
    nTU, oTU = arr(m, 0x88)
    tu = struct.unpack_from('<%dH' % nTU, m, oTU) if oTU + nTU * 2 <= len(m) else ()
    chk(len(tu) >= 3 and tu[2] == 1, 'UV-set lookup entry 2 = second UV set (skins use coordinate index 2): %s' % (tu,))
    nR, oR = arr(m, 0x68)
    rp = struct.unpack_from('<%dH' % nR, m, oR) if oR + nR * 2 <= len(m) else ()
    chk(len(rp) > 1 and rp[1] == 3, 'replaceable texture 1 -> texture 3: %s' % (rp,))
    nV, oV = arr(m, 0x3C)
    chk(nV == 27292, 'vertex count %d (27292 expected: the overlay only changes UV2, never the vertex count)' % nV)
    if ref is not None:
        nVr, oVr = arr(ref, 0x3C)
        diff = 0
        if nV == nVr:
            for i in range(nV):
                if m[oV + i * 48 + 40:oV + i * 48 + 48] != ref[oVr + i * 48 + 40:oVr + i * 48 + 48]: diff += 1
        chk(nV == nVr and diff == 0, 'UV2 of every vertex equals the reference overlay M2 (%d differ)' % diff)
        pos_diff = sum(1 for i in range(min(nV, nVr)) if m[oV + i * 48:oV + i * 48 + 40] != ref[oVr + i * 48:oVr + i * 48 + 40])
        print('INFO vertices whose position/weights/normals/UV1 differ from the reference: %d (a bone/attachment edit should leave this at 0)' % pos_diff)
    print('OVERLAY INTACT' if ok else 'OVERLAY DAMAGED')
    print('sha256 prefix', hashlib.sha256(m).hexdigest()[:16])
    return 0 if ok else 1


if __name__ == '__main__':
    sys.exit(main())
