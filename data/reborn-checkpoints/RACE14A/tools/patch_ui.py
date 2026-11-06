import os, sys, hashlib
SP = os.path.dirname(os.path.abspath(__file__))
OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)

# (k, token, round icon dir, Chinese name, horde, extra fields)
RACES = [
    ('Titan', 'TITANALLIANCE', '泰坦', False, 'zmax=3'),
    ('Mogu', 'MOGUALLIANCE', '魔古族', False, 'zmax=3'),
    ('Sureki', 'SUREKIALLIANCE', '苏雷基', False, 'zmax=3'),
    ('Centaur', 'CENTAURALLIANCE', '半人马', False, 'sc=20, zmax=1'),
    ('Fungarian', 'FUNGARIANALLIANCE', '蘑菇人', False, 'sc=2, zmax=3'),
    ('LostOne', 'LOSTONEALLIANCE', '失落者', True, ''),
    ('Stormforged', 'STORMFORGEDALLIANCE', '风暴铸造者', False, 'zmax=3'),
    ('Qiraji', 'QIRAJIHORDE', '其拉人', True, 'zmax=3'),
    ('Nerubian', 'NERUBIANHORDE', '蛛魔', True, ''),
    ('Dreadlord', 'DREADLORDHORDE', '恐惧魔王', True, 'sc=15, zmax=3'),
    ('Wretched', 'WRETCHEDHORDE', '邪裔', True, ''),
    ('Moarg', 'MOARGHORDE', '莫阿格', True, 'sc=15, zmax=3, zmaxF=2'),
    ('Sporeling', 'SPORELINGALLIANCE', '孢子人', False, 'sc=4'),
    ('Lich', 'LICHHORDE', '巫妖', True, 'sc=18'),
]

def edit(path, fn):
    b = open(path, 'rb').read()
    nb = fn(b)
    assert nb != b
    return nb

# ---- XML
def xml(b):
    nl = b'\r\n' if b'\r\n' in b[-400:] else b'\n'
    end = b.rfind(b'</Ui>')
    assert end > 0
    add = b''
    for k, *_ in RACES:
        if (('name="Reborn%sPreviewButton"' % k).encode()) in b: continue
        add += ('\t<CheckButton name="Reborn%sPreviewButton" inherits="CharCreateRaceButtonTemplate" parent="CharacterCreate" hidden="true"/>' % k).encode() + nl
    return b[:end] + b'\t<!-- RACE14A: 14 CoA 1.9.9 races, preview only -->' + nl + add + b[end:]

# ---- Lua
def lua(b):
    nl = b'\r\n' if b'\r\n' in b else b'\n'
    marker = '    { k="Sylvari",     f="SYLVARIALLIANCE",     ic="R:Sylvari",     n="希尔瓦里", horde=true },'.encode() + nl
    i = b.find(marker)
    assert i > 0, 'marker'
    i += len(marker)
    add = ('    -- RACE14A: CoA 1.9.9 AllRaces v12, 7 Alliance + 7 Horde (preview only). Icons: Reborn\\Preview\\RACE14\\<k>\\icon-round.blp' ).encode() + nl
    for k, tok, n, horde, extra in RACES:
        fields = 'k="%s", f="%s", ic="S:%s", n="%s"' % (k, tok, k, n)
        if extra:
            fields = 'k="%s", %s, f="%s", ic="S:%s", n="%s"' % (k, extra, tok, k, n)
        if horde:
            fields += ', horde=true'
        add += ('    { %s },' % fields).encode('utf-8') + nl
    b = b[:i] + add + b[i:]
    oldn = b'local s = posStore[e.k]'
    assert oldn in b
    nl2 = nl
    start = b.index(b'function NudgeGet(e)')
    end_ = b.index(b'function NudgeUpdate(e, p)')
    newfn = nl2.join([
        b'function NudgeGet(e)',
        b'    local fem = type(GetSelectedSex) == "function" and SEX_FEMALE and GetSelectedSex() == SEX_FEMALE   -- RACE14A: separate camera for female',
        b'    local key = e.k .. (fem and "F" or "M")',
        b'    local s = posStore[key]',
        b'    if not s then',
        b'        local fp = (fem and e.posF) or e.pos',
        b'        local far = { fp and fp[1] or 0, fp and fp[2] or 0, fp and fp[3] or 0 }',
        b'        local fn = (fem and e.nearF) or e.near',
        b'        local near = fn and { fn[1], fn[2], fn[3] } or { far[1] + 24, far[2], far[3] }',
        b'        s = { far = far, near = near, mode = "far" }',
        b'        posStore[key] = s',
        b'    end',
        b'    return s[s.mode], s',
        b'end',
        b''])
    b = b[:start] + newfn + b[end_:]
    oldz = b'if a and a.zmax and level and level > a.zmax then level = a.zmax end'
    assert oldz in b, 'zmax line'
    newz = b'local zm = a and ((type(GetSelectedSex) == "function" and SEX_FEMALE and GetSelectedSex() == SEX_FEMALE and a.zmaxF) or a.zmax); if zm and level and level > zm then level = zm end   -- RACE14A zmaxF'
    b = b.replace(oldz, newz)
    old = b'local icon = kind == "R" and ("Reborn\\\\Preview\\\\UIR1B\\\\"..name.."\\\\icon-round.blp") or ("Interface\\\\Icons\\\\"..name)'
    assert old in b, 'icon line'
    new = b'local icon = kind == "R" and ("Reborn\\\\Preview\\\\UIR1B\\\\"..name.."\\\\icon-round.blp") or kind == "S" and ("Reborn\\\\Preview\\\\RACE14\\\\"..name.."\\\\icon-round.blp") or ("Interface\\\\Icons\\\\"..name)'
    return b.replace(old, new)

g = os.path.join(OUT, 'Interface', 'GlueXML')
os.makedirs(g, exist_ok=True)
for name, fn in (('CharacterCreate.xml', xml), ('RebornRacePreview.lua', lua)):
    src = os.path.join(SP, 'yb', name)
    nb = edit(src, fn)
    open(os.path.join(g, name), 'wb').write(nb)
    print(name, len(open(src, 'rb').read()), '->', len(nb), hashlib.sha256(nb).hexdigest())
