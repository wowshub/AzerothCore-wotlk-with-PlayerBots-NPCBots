"""RACE14A: creature-style race models get direct texture files in the M2 (types 11/12/13 -> type 0 + path), because
this client does not apply CharSections skins to them without the Esteria runtime (same fix as Sethrak, RACEPREV1B)."""
import struct, os, sys, json, collections
SP = os.path.dirname(os.path.abspath(__file__))
B = chr(92)
YJ = sys.argv[1]
dryrun = len(sys.argv) > 2 and sys.argv[2] == 'dry'

def tbl(p):
    x = open(p, 'rb').read()
    m, rc, fc, rs, ss = struct.unpack('<4sIIII', x[:20])
    return x, rc, rs, x[20 + rc * rs:]

chr_x, chr_rc, chr_rs, chr_st = tbl(os.path.join(SP, 'out_dbc', 'ChrRaces.dbc'))
cdi_x, cdi_rc, cdi_rs, cdi_st = tbl(os.path.join(SP, 'out_dbc', 'CreatureDisplayInfo.dbc'))
cmd_x, cmd_rc, cmd_rs, cmd_st = tbl(os.path.join(SP, 'out_dbc', 'CreatureModelData.dbc'))
cs_x, cs_rc, cs_rs, cs_st = tbl(os.path.join(SP, 'out_dbc', 'CharSections.dbc'))
S = lambda st, o: st[o:st.find(b'\0', o)].decode('latin1') if o else ''
RACES = {91: 'Titan', 123: 'Mogu', 86: 'Sureki', 75: 'Centaur', 93: 'Fungarian', 61: 'LostOne', 84: 'Stormforged', 88: 'Qiraji', 120: 'Nerubian', 89: 'Dreadlord', 92: 'Wretched', 119: 'Moarg', 111: 'Sporeling', 113: 'Lich'}
disp = {}
for i in range(cdi_rc):
    f = struct.unpack('<16I', cdi_x[20 + i * 64:84 + i * 64]); disp[f[0]] = f
mod = {}
for i in range(cmd_rc):
    f = struct.unpack('<28I', cmd_x[20 + i * 112:132 + i * 112]); mod[f[0]] = f
secs = collections.defaultdict(list)   # (race,sex,type) -> [(var,color,t1,t2,t3)]
for i in range(cs_rc):
    f = struct.unpack('<10I', cs_x[20 + i * 40:60 + i * 40])
    if f[1] in RACES:
        secs[(f[1], f[2], f[3])].append((f[8], f[9], S(cs_st, f[4]), S(cs_st, f[5]), S(cs_st, f[6])))
report = []
for i in range(chr_rc):
    f = struct.unpack('<%dI' % (chr_rs // 4), chr_x[20 + i * chr_rs:20 + (i + 1) * chr_rs])
    if f[0] not in RACES or f[0] in (88, 75):   # 88 Qiraji is known to the Esteria runtime and already renders correctly
        continue
    rid = f[0]
    for sex, d in ((0, f[4]), (1, f[5])):
        mp = S(cmd_st, mod[disp[d][1]][2])
        if mp.lower().startswith('character'):
            report.append((RACES[rid], sex, mp, 'character-type model: CharSections path, no M2 patch'))
            continue
        p = os.path.join(YJ, mp.replace(B, '/').rsplit('.', 1)[0] + '.m2')
        base = sorted(secs[(rid, sex, 0)])
        hair = sorted(secs[(rid, sex, 3)])
        cand = {}
        if base:
            v, c, t1, t2, t3 = base[0]
            cand[11], cand[12], cand[13] = t1, t2, t3
        if hair and not cand.get(13):
            cand[13] = hair[0][2] or hair[0][3]
        d_ = bytearray(open(p, 'rb').read())
        n, o = struct.unpack('<II', d_[0x50:0x58])
        tail = bytearray()
        changed = []
        for k in range(n):
            t, fl, ln, no = struct.unpack('<IIII', d_[o + k * 16:o + k * 16 + 16])
            if t in (11, 12, 13) and cand.get(t):
                name = (cand[t] + '\0').encode('latin1')
                newoff = len(d_) + len(tail)
                tail += name
                d_[o + k * 16:o + k * 16 + 16] = struct.pack('<IIII', 0, fl, len(name), newoff)
                changed.append((k, t, cand[t]))
        report.append((RACES[rid], sex, mp, changed))
        if changed and not dryrun:
            open(p, 'wb').write(bytes(d_) + bytes(tail))
for r in report:
    print(r)
