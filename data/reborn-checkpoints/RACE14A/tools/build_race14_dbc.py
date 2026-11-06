"""RACE14A: merge the 14 CoA 1.9.9 races (rows only) into the current Patch-YB shared client tables.
Rows of the existing tables are kept byte-for-byte; new rows and new strings are appended."""
import struct, zipfile, glob, os, json, sys, hashlib

SP = os.path.dirname(os.path.abspath(__file__))
ZIPS = sorted(glob.glob('D:/game/ascend/coa新种族/CoA-Races-Only-1.9.9/CoA-Races-Only-1.9.9-?.zip'))
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(SP, 'out_dbc')
os.makedirs(OUT, exist_ok=True)

def zread(name):
    for f in ZIPS:
        z = zipfile.ZipFile(f)
        if name in z.namelist():
            return z.read(name)
    raise KeyError(name)

class Tbl:
    def __init__(self, x):
        m, self.rc, self.fc, self.rs, self.ss = struct.unpack('<4sIIII', x[:20])
        assert m == b'WDBC'
        self.n = self.rs // 4
        self.rows = [list(struct.unpack('<%dI' % self.n, x[20 + i * self.rs:20 + (i + 1) * self.rs])) for i in range(self.rc)] if self.rs % 4 == 0 else None
        self.raw = x[20:20 + self.rc * self.rs]
        self.st = bytearray(x[20 + self.rc * self.rs:])
    def s(self, o):
        e = self.st.find(b'\0', o)
        return bytes(self.st[o:e])
    def intern(self, b):
        if not b:
            return 0
        k = bytes(b) + b'\0'
        i = self.st.find(k)
        while i > 0 and self.st[i - 1] != 0:   # must start at a string boundary
            i = self.st.find(k, i + 1)
        if i >= 0:
            return i
        o = len(self.st)
        self.st += k
        return o
    def dump(self):
        body = b''.join(struct.pack('<%dI' % self.n, *r) for r in self.rows) if self.rows is not None else self.raw
        rc = len(self.rows) if self.rows is not None else self.rc
        return b'WDBC' + struct.pack('<IIII', rc, self.fc, self.rs, len(self.st)) + body + bytes(self.st)

def load_yb(n):
    return Tbl(open(os.path.join(SP, 'ybdbc', n + '.dbc'), 'rb').read())

def load_th(n):
    return Tbl(zread('CoA-Races/server/dbc/' + n + '.dbc'))

# source id -> (target id, team 0=Alliance 1=Horde, short name)
RACES = {
    91: (91, 0, 'Titan'), 123: (123, 0, 'Mogu'), 86: (86, 0, 'Sureki'), 75: (75, 0, 'Centaur'),
    93: (93, 0, 'Fungarian'), 125: (73, 1, 'LostOne'), 114: (84, 0, 'Stormforged'),
    88: (88, 1, 'Qiraji'), 120: (120, 1, 'Nerubian'), 89: (89, 1, 'Dreadlord'), 92: (92, 1, 'Wretched'),
    119: (119, 1, 'Moarg'), 111: (76, 0, 'Sporeling'), 122: (113, 1, 'Lich'),
}
CHR_STR = [6, 11] + list(range(14, 30)) + list(range(31, 47)) + list(range(48, 64)) + [65, 66]
report = {}

# ---------------- ChrRaces
yb, th = load_yb('ChrRaces'), load_th('ChrRaces')
ybids = {r[0] for r in yb.rows}
throw = {r[0]: r for r in th.rows}
tmpl = {0: next(r for r in yb.rows if r[0] == 36), 1: next(r for r in yb.rows if r[0] == 37)}
tokens_taken = {yb.s(r[11]).upper() for r in yb.rows}
for src, (dst, team, nm) in RACES.items():
    assert dst not in ybids, ('target id taken', dst)
    r = list(throw[src])
    new = list(r)
    new[0] = dst
    for i in CHR_STR:
        new[i] = yb.intern(th.s(r[i])) if r[i] else 0
    new[2] = tmpl[team][2]          # faction template of the parent faction (Human 1 / Orc 2), as 36/37 do
    new[7] = tmpl[team][7]          # base language: Common / Orcish
    new[13] = team
    if src == 89:
        new[5] = 977640   # Dreadlord: male keeps the classic model 977641 (as in 1.9.9); female gets a recoloured copy (display 977640 reuses its slot)
    tok = yb.s(new[11]).upper()
    report.setdefault('tokens', {})[nm] = tok.decode()
    assert tok not in tokens_taken, ('token taken', nm, tok)
    tokens_taken.add(tok)
    yb.rows.append(new)
open(os.path.join(OUT, 'ChrRaces.dbc'), 'wb').write(yb.dump())

# ---------------- CreatureDisplayInfo / CreatureModelData (ids kept, no collisions)
disp_ids, model_ids = set(), set()
for src in RACES:
    r = throw[src]
    disp_ids |= {r[4], r[5]}
    if src == 89:
        disp_ids.add(977640)
ybc, thc = load_yb('CreatureDisplayInfo'), load_th('CreatureDisplayInfo')
have = {r[0] for r in ybc.rows}
thcmap = {r[0]: r for r in thc.rows}
for d in sorted(disp_ids):
    if d in have:
        model_ids.add(thcmap[d][1]); continue
    r = list(thcmap[d])
    for i in (6, 7, 8, 9):
        r[i] = ybc.intern(thc.s(r[i])) if r[i] else 0
    model_ids.add(r[1])
    ybc.rows.append(r)
open(os.path.join(OUT, 'CreatureDisplayInfo.dbc'), 'wb').write(ybc.dump())
ybm, thm = load_yb('CreatureModelData'), load_th('CreatureModelData')
have = {r[0] for r in ybm.rows}
thmmap = {r[0]: r for r in thm.rows}
mpaths = []
for m in sorted(model_ids):
    if m in have:
        continue
    r = list(thmmap[m])
    mpaths.append(thm.s(r[2]).decode())
    r[2] = ybm.intern(thm.s(r[2]))
    ybm.rows.append(r)
FEMALE_COPY = {901404: 'Creature\Dreadlord\DreadlordPlayerFemaleF.mdx', 901415: 'Creature\Fungarian\FungarianPlayerF.mdx', 901411: 'Creature\Sporeling\SporelingPlayerF.mdx', 901413: 'Creature\LostOne\LostOnePlayerF.mdx'}
for row in ybm.rows:
    if row[0] in FEMALE_COPY:
        row[2] = ybm.intern(FEMALE_COPY[row[0]].encode('latin1'))
open(os.path.join(OUT, 'CreatureModelData.dbc'), 'wb').write(ybm.dump())
report['model_paths'] = mpaths
report['display_ids'] = sorted(disp_ids)

# ---------------- CharSections (re-id), CharHairGeosets (re-id), FacialHair, CharBaseInfo
ybs, ths = load_yb('CharSections'), load_th('CharSections')
nid = max(r[0] for r in ybs.rows) + 1
tex = set()
cnt = {}
for r in ths.rows:
    if r[1] in RACES:
        n = list(r)
        n[0] = nid
        nid += 1
        n[1] = RACES[r[1]][0]
        # 3.3.5 CharSections: ID, Race, Sex, BaseSection, Texture1..3 (strings, fields 4-6), Flags, Variation, Color
        for i in (4, 5, 6):
            if r[i]:
                tex.add(ths.s(r[i]).decode('latin1'))
            n[i] = ybs.intern(ths.s(r[i])) if r[i] else 0
        ybs.rows.append(n)
        cnt[RACES[r[1]][2]] = cnt.get(RACES[r[1]][2], 0) + 1
open(os.path.join(OUT, 'CharSections.dbc'), 'wb').write(ybs.dump())
report['charsections'] = cnt
report['textures'] = sorted(tex)

ybh, thh = load_yb('CharHairGeosets'), load_th('CharHairGeosets')
nid = max(r[0] for r in ybh.rows) + 1
for r in thh.rows:
    if r[1] in RACES:
        n = list(r); n[0] = nid; nid += 1; n[1] = RACES[r[1]][0]
        ybh.rows.append(n)
open(os.path.join(OUT, 'CharHairGeosets.dbc'), 'wb').write(ybh.dump())

ybf, thf = load_yb('CharacterFacialHairStyles'), load_th('CharacterFacialHairStyles')
for r in thf.rows:
    if r[0] in RACES:
        n = list(r); n[0] = RACES[r[0]][0]
        ybf.rows.append(n)
open(os.path.join(OUT, 'CharacterFacialHairStyles.dbc'), 'wb').write(ybf.dump())

ybb = load_yb('CharBaseInfo')
have = {ybb.raw[i * 2:i * 2 + 2] for i in range(ybb.rc)}
add = b''
# same 12 class combinations the other preview races (e.g. Drakkin 99) have in this client: the 10 stock classes incl. Death Knight(6) + Witch Doctor(13) + Monk(14).
# The 1.9.9 rows lack class 6 and carry CoA classes 12,16-32 that do not exist here; a missing (race,class) pair makes the client pick a random race and crash (0x004E0F84).
for dst_race in sorted({v[0] for v in RACES.values()}):
    for cls in (1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 13, 14):
        rec = bytes([dst_race, cls])
        if rec not in have:
            add += rec
            have.add(rec)
ybb.raw = ybb.raw + add
ybb.rc += len(add) // 2
open(os.path.join(OUT, 'CharBaseInfo.dbc'), 'wb').write(b'WDBC' + struct.pack('<IIII', ybb.rc, ybb.fc, ybb.rs, len(ybb.st)) + ybb.raw + bytes(ybb.st))

json.dump(report, open(os.path.join(SP, 'race14_report.json'), 'w'), indent=1, ensure_ascii=False)
for f in sorted(os.listdir(OUT)):
    p = os.path.join(OUT, f)
    print(f, os.path.getsize(p), hashlib.sha256(open(p, 'rb').read()).hexdigest()[:16])
print('tokens', report['tokens'])
print('charsections', cnt, 'textures', len(tex), 'models', len(mpaths))
