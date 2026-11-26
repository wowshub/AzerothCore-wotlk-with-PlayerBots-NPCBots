# -*- coding: utf-8 -*-
"""ALLY1E-M V1: Ralia and her escape mount use the retail stag (display 70xxxx), stacked on MODEL1C."""
import ctypes, struct, os, hashlib, glob, shutil
B = chr(92)
WS = r'D:\000rebornWOW\000RebornWOWHighForkPRO'
DAY = os.path.join(WS, '000Ascendupdate', '000Ascendupdate20261125')
NAME = 'claudefix_20261125_阶段ALLY1E_M_V1_拉莉亚换高版本原版雄鹿模型_可选_Claude'
P = os.path.join(DAY, NAME)
assert not os.path.exists(P)
C1 = glob.glob(DAY + B + '*MODEL1C_V1*')[0]
CLIENT = r'C:\000ref\WarcraftXL试装_client'
SRV = WS + r'\beascendserver\wowshub_playerbot_npcbot_newrace20261122Ascend\Data\dbc'
NEW, FDID, TEMPLATE_DISPLAY = 710009, 652455, 1992
BASE = B.join(['retail', 'RetailRalia', 'RetailRalia'])
sha = lambda b: hashlib.sha256(b).hexdigest()
fb = lambda x: struct.unpack('<I', struct.pack('<f', x))[0]

dll = ctypes.WinDLL(r'D:\soft\python3.9\Lib\site-packages\pympq\StormLib.dll')
dll.SFileOpenArchive.argtypes = [ctypes.c_wchar_p, ctypes.c_uint32, ctypes.c_uint32, ctypes.POINTER(ctypes.c_void_p)]
dll.SFileOpenFileEx.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_uint32, ctypes.POINTER(ctypes.c_void_p)]
dll.SFileGetFileSize.argtypes = [ctypes.c_void_p, ctypes.c_void_p]
dll.SFileGetFileSize.restype = ctypes.c_uint32
dll.SFileReadFile.argtypes = [ctypes.c_void_p, ctypes.c_void_p, ctypes.c_uint32, ctypes.POINTER(ctypes.c_uint32), ctypes.c_void_p]
dll.SFileCloseArchive.argtypes = [ctypes.c_void_p]


def client_table(n):
    h = ctypes.c_void_p()
    assert dll.SFileOpenArchive(CLIENT + r'\Data\Patch-YB.mpq', 0, 0x100, ctypes.byref(h)), 'cannot open Patch-YB'
    f = ctypes.c_void_p()
    assert dll.SFileOpenFileEx(h, ('DBFilesClient' + B + n).encode(), 0, ctypes.byref(f)) and f.value
    size = dll.SFileGetFileSize(f, None)
    buf = ctypes.create_string_buffer(size)
    got = ctypes.c_uint32()
    assert dll.SFileReadFile(f, buf, size, ctypes.byref(got), None) and got.value == size
    dll.SFileCloseArchive(h)
    return buf.raw[:size]


def parse(d):
    n, nf, rs, ss = struct.unpack('<4I', d[4:20])
    assert d[:4] == b'WDBC' and len(d) == 20 + n * rs + ss
    return n, nf, rs, d[20:20 + n * rs], d[20 + n * rs:]


def row_of(d, key):
    n, nf, rs, rows, sb = parse(d)
    for i in range(n):
        if struct.unpack_from('<I', rows, i * rs)[0] == key:
            return list(struct.unpack_from('<%dI' % nf, rows, i * rs))


def append(d, row, strings):
    n, nf, rs, rows, sb = parse(d)
    assert row_of(d, row[0]) is None
    out = b'WDBC' + struct.pack('<4I', n + 1, nf, rs, len(sb) + len(strings)) + rows + struct.pack('<%dI' % nf, *row) + sb + strings
    m = parse(out)
    assert m[0] == n + 1 and m[3][:len(rows)] == rows and m[4][:len(sb)] == sb
    return out


def build(md, di):
    dr = row_of(di, TEMPLATE_DISPLAY)
    mr = row_of(md, dr[1])
    mr[0], mr[2], mr[4] = NEW, len(parse(md)[4]), fb(1.0)
    mr[14], mr[15], mr[16] = fb(0.611), fb(2.031), 0
    for i, v in zip(range(17, 23), (-1.28, -1.16, -0.01, 2.28, 1.15, 3.86)):
        mr[i] = fb(v)
    base = len(parse(di)[4])
    dr[0], dr[1], dr[3], dr[4], dr[5] = NEW, NEW, 0, fb(1.0), 255
    for i in (7, 8, 9, 13, 14, 15):
        dr[i] = 0
    dr[6] = 0                                   # the stag's textures are fixed inside the model
    return append(md, mr, (BASE + '.mdx').encode() + b'\0'), append(di, dr, b'')


md_c1 = open(C1 + r'\01_导入Patch-YB.mpq\DBFilesClient\CreatureModelData.dbc', 'rb').read()
md_c1_in = open(C1 + r'\03_撤销\原Patch-YB\DBFilesClient\CreatureModelData.dbc', 'rb').read()
md_now = client_table('CreatureModelData.dbc')
assert md_now in (md_c1, md_c1_in), 'YB CreatureModelData changed by someone else'
di_now = client_table('CreatureDisplayInfo.dbc')
csv_c1 = open(C1 + r'\02_覆盖到客户端根目录\Data\Retail\aliases_maps.csv', 'rb').read()
csv_now = open(CLIENT + r'\Data\Retail\aliases_maps.csv', 'rb').read()
assert csv_now in (csv_c1, open(C1 + r'\03_撤销\原客户端根目录\Data\Retail\aliases_maps.csv', 'rb').read())
assert str(FDID).encode() + b';' not in csv_c1
nl = b'\r\n' if b'\r\n' in csv_c1 else b'\n'
csv_new = csv_c1 + (b'' if csv_c1.endswith(b'\n') else nl) + ('%d;%s.m2' % (FDID, BASE)).encode() + nl
md_s = open(SRV + B + 'CreatureModelData.dbc', 'rb').read()
di_s = open(SRV + B + 'CreatureDisplayInfo.dbc', 'rb').read()
md_new, di_new = build(md_c1, di_now)
md_s_new, di_s_new = build(md_s, di_s)


def wr(rel, data):
    f = os.path.join(P, rel.replace('/', B))
    os.makedirs(os.path.dirname(f), exist_ok=True)
    open(f, 'wb').write(data.encode('utf-8') if isinstance(data, str) else data)


wr('01_导入Patch-YB.mpq/DBFilesClient/CreatureModelData.dbc', md_new)
wr('01_导入Patch-YB.mpq/DBFilesClient/CreatureDisplayInfo.dbc', di_new)
wr('02_覆盖到客户端根目录/Data/Retail/aliases_maps.csv', csv_new)
wr('03_服务端_Data_dbc/CreatureModelData.dbc', md_s_new)
wr('03_服务端_Data_dbc/CreatureDisplayInfo.dbc', di_s_new)
wr('05_撤销/原Patch-YB/DBFilesClient/CreatureModelData.dbc', md_c1)
wr('05_撤销/原Patch-YB/DBFilesClient/CreatureDisplayInfo.dbc', di_now)
wr('05_撤销/原客户端根目录/Data/Retail/aliases_maps.csv', csv_c1)
wr('05_撤销/原服务端dbc/CreatureModelData.dbc', md_s)
wr('05_撤销/原服务端dbc/CreatureDisplayInfo.dbc', di_s)
hashes = [('客户端 YB CreatureModelData.dbc', sha(md_c1), sha(md_new)), ('客户端 YB CreatureDisplayInfo.dbc', sha(di_now), sha(di_new)),
          ('客户端 aliases_maps.csv', sha(csv_c1), sha(csv_new)), ('服务端 CreatureModelData.dbc', sha(md_s), sha(md_s_new)),
          ('服务端 CreatureDisplayInfo.dbc', sha(di_s), sha(di_s_new))]
wr('04_服务端_SQL/world_ally1e_m.sql', '\r\n'.join([
    '-- ALLY1E-M V1: Ralia (156929) and her escape mount (9167012) use the retail stag, creature display %d. Needs ALLY1E and the server dbc rows. Safe to run twice.' % NEW,
    'DELETE FROM `creature_model_info` WHERE `DisplayID` = %d;' % NEW,
    'INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`) VALUES (%d, 0.6, 1.5, 1, 0);' % NEW,
    'UPDATE `creature_template_model` SET `CreatureDisplayID` = %d, `DisplayScale` = 1 WHERE `CreatureID` IN (156929, 9167012) AND `Idx` = 0;' % NEW,
    'SELECT `CreatureID`, `CreatureDisplayID`, `DisplayScale` FROM `creature_template_model` WHERE `CreatureID` IN (156929, 9167012);', '']))
wr('05_撤销/undo_ally1e_m.sql', '\r\n'.join([
    'UPDATE `creature_template_model` SET `CreatureDisplayID` = 1992, `DisplayScale` = 1 WHERE `CreatureID` = 156929 AND `Idx` = 0;',
    'UPDATE `creature_template_model` SET `CreatureDisplayID` = 1992, `DisplayScale` = 1.2 WHERE `CreatureID` = 9167012 AND `Idx` = 0;',
    'DELETE FROM `creature_model_info` WHERE `DisplayID` = %d;' % NEW, '']))
shutil.copy(r'D:\_zsdc\ally1e\m\r.png', os.path.join(P, '离线渲染_待机_奔跑_行走_趴下.png'))
wr('README_覆盖与测试说明.md', '''# ALLY1E-M V1(可选)：拉莉亚和出坑坐骑换高版本原版雄鹿

状态：候选，游戏里未测；离线渲染待机、奔跑、行走、趴下姿势正常。
**安装顺序：先装 MODEL1C 并确认吉安娜正常，再装 ALLY1E，最后装本包。** 本包的客户端表是在 MODEL1C 的结果上追加的，
没装 MODEL1C 就导入本包，吉安娜的路径会改了但清单文件对不上。

## 内容
零售外观 73350(模型文件 652455，贴图写在模型里) -> 710009，用于 156929 和坐骑 9167012。模型自带坐骑挂点，不改模型。

## 部署(关游戏、停服)
1. 备份 `Data\\Patch-YB.mpq` 和服务端两个 DBC；核对它们等于下表"输入"。
2. 把 `01_导入Patch-YB.mpq` 两个表导入 YB，保存并关闭 MPQ 编辑器。
3. 把 `02_覆盖到客户端根目录` 覆盖到客户端根目录。
4. `03_服务端_Data_dbc` 覆盖服务端 `Data\\dbc`。
5. world 库执行 `04_服务端_SQL\\world_ally1e_m.sql`，读回两行 710009、1。
6. 启动服务端；删客户端 `Cache\\WDB`。

## 测试
`.go xyz 73 -2127 -29 12175`(坑底)
1. 拉莉亚是高版本雄鹿，有贴图、会动。
2. 骑乘出坑：人坐在鹿背上，没有陷进身体或悬空；鹿奔跑动作正常。
3. 大小合适吗(零售原尺寸，鹿角很高)。

## 指纹(SHA256)
| 文件 | 输入 | 输出 |
|---|---|---|
''' + '\n'.join('| %s | %s | %s |' % h for h in hashes) + '''

## 撤销
YB 导回 `05_撤销\\原Patch-YB`，`05_撤销\\原客户端根目录` 覆盖回根目录，服务端换回原 DBC，执行 `05_撤销\\undo_ally1e_m.sql`。
''')
wr('memory.md', '''# memory - ALLY1E-M V1 (2026-11-25, Claude, 候选未测)
- 710009 = 零售 73350 / 652455 雄鹿，有坐骑挂点 id 0；叠在 MODEL1C 之上。
''')
wr('tutor.md', '''# tutor - 零售坐骑类生物当飞行坐骑 (ALLY1E-M V1, 未实测)
看 M2 挂点表有没有 id 0；有就能直接当载人模型。交付前离线渲染待机和奔跑。
''')
lines_ = []
for dp, dn, fn in os.walk(P):
    for f in sorted(fn):
        p = os.path.join(dp, f)
        lines_.append('%s  %s' % (sha(open(p, 'rb').read()), os.path.relpath(p, P).replace(B, '/')))
wr('SHA256SUMS.txt', '\n'.join(lines_) + '\n')


def append_text(path, rows_):
    t = open(path, 'rb').read()
    e = b'\r\n' if b'\r\n' in t else b'\n'
    open(path, 'ab').write((b'' if t.endswith(b'\n') else e) + b''.join(x.encode('utf-8') + e for x in rows_))


log = os.path.join(WS, '协作说明_并行开发.md')
assert 'ALLY1E-M V1' not in open(log, 'rb').read().decode('utf-8', 'replace')
append_text(log, ['| 2026-11-25 | Claude | ALLY1E-M V1(拉莉亚/出坑坐骑换零售雄鹿 710009，可选) | 候选(未安装) | YB CreatureModelData/CreatureDisplayInfo 各+1行、aliases_maps.csv +1行、服务端同名DBC各+1行、SQL | 基线：MODEL1C V1 的输出(须先装) | 包 000Ascendupdate20261125/%s | 占用 YB 两张生物表；Codex 改这两张表前请先告知 |' % NAME])
led = os.path.join(WS, '台账_YB_XA共享文件哈希.md')
append_text(led, ['', '## 2026-11-25 ALLY1E-M V1（Claude，候选未安装，叠在 MODEL1C 上）', '', '|文件|实际input|候选output|', '|---|---|---|'] + ['|%s|%s|%s|' % h for h in hashes])
for h in hashes:
    print(h[0].encode('ascii', 'replace').decode(), h[1][:12], '->', h[2][:12])
