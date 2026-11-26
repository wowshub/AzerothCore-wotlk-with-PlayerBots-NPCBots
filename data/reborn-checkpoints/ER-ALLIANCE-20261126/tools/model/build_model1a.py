# -*- coding: utf-8 -*-
"""MODEL1A V1: retail models for the harpy, Bloodbeak, Jaina and Wrathion (displays 710004-710008)."""
import ctypes, struct, os, hashlib, glob
B = chr(92)
WS = r'D:\000rebornWOW\000RebornWOWHighForkPRO'
DAY = os.path.join(WS, '000Ascendupdate', '000Ascendupdate20261125')
NAME = 'claudefix_20261125_阶段MODEL1A_V1_鹰身人血喙吉安娜拉希奥换高版本原版模型_Claude'
P = os.path.join(DAY, NAME)
assert not os.path.exists(P)
CLIENT = r'C:\000ref\WarcraftXL试装_client'
SRV = WS + r'\beascendserver\wowshub_playerbot_npcbot_newrace20261122Ascend\Data\dbc'
OVERLAY_SRC = r'D:\_zsdc\models4\overlay\3055446.bin'
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
    return None


def append(d, new_rows, strings):
    n, nf, rs, rows, sb = parse(d)
    for r in new_rows:
        assert row_of(d, r[0]) is None, 'id %d already present' % r[0]
    out = b'WDBC' + struct.pack('<4I', n + len(new_rows), nf, rs, len(sb) + len(strings)) + rows + b''.join(struct.pack('<%dI' % nf, *r) for r in new_rows) + sb + strings
    m = parse(out)
    assert m[0] == n + len(new_rows) and m[3][:len(rows)] == rows and m[4][:len(sb)] == sb
    return out


# id, folder, m2 file id, template display (None = stock carrion bird), geobox, display scale, geoset, textures [(fdid, name)], keep sounds
V = lambda s: B.join(s.split('/'))
M = [
    (710004, 'RetailHarpy', 1120702, 1350, (-0.80, -0.52, 0.01, 0.42, 0.55, 2.18), 1.5, 0, [(1120828, 'HarpySkin')], True),
    (710005, 'RetailBloodbeak', 1242538, None, (-20.88, -7.34, -1.07, 6.57, 6.80, 11.83), 1.0, 0, [(1242539, 'BloodbeakSkinA'), (1242540, 'BloodbeakSkinB')], True),
    (710006, 'RetailJaina', 1717164, 30863, (-0.37, -0.38, 0.0, 0.36, 0.40, 1.91), 1.2, 0x11, [], True),
    (710007, 'RetailWrathion', 3055446, 15511, (-0.42, -0.52, 0.0, 0.35, 0.37, 2.11), 1.0, 0, [], False),
    (710008, 'RetailWrathionFinal', 3952870, 15511, (-0.42, -0.52, 0.0, 0.35, 0.37, 2.11), 1.0, 0, [(5386323, 'WrathionSkinA'), (5386322, 'WrathionSkinB')], False),
]


def build(read):
    md0, di0 = read('CreatureModelData.dbc'), read('CreatureDisplayInfo.dbc')
    msb = parse(md0)[4]
    # a stock carrion bird as the sound / blood template of Bloodbeak
    n, nf, rs, rows, _ = parse(md0)
    birds = set()
    for i in range(n):
        r = struct.unpack_from('<%dI' % nf, rows, i * rs)
        if b'carrionbird' in msb[r[2]:msb.index(0, r[2])].lower():
            birds.add(r[0])
    n, nf, rs, rows, _ = parse(di0)
    bird = next(struct.unpack_from('<I', rows, i * rs)[0] for i in range(n) if struct.unpack_from('<I', rows, i * rs + 4)[0] in birds)
    mrows, drows, mstr, dstr = [], [], b'', b''
    dbase = len(parse(di0)[4])
    for nid, folder, fdid, tdisp, box, scale, geo, tex, sounds in M:
        dr = row_of(di0, tdisp or bird)
        assert dr is not None, (tdisp, bird)
        mr = row_of(md0, dr[1])
        assert mr is not None and len(mr) == 28 and len(dr) == 16
        mr[0], mr[2] = nid, len(msb) + len(mstr)
        mstr += V('Creature/%s/%s.mdx' % (folder, folder)).encode() + b'\0'
        mr[4] = fb(1.0)
        if not sounds:
            mr[13] = 0
        mr[14], mr[15], mr[16] = fb(0.611), fb(2.031), 0
        for i, v in zip(range(17, 23), box):
            mr[i] = fb(v)
        dr[0], dr[1] = nid, nid
        dr[3] = 0
        dr[4], dr[5] = fb(scale), 255
        dr[6] = dr[7] = dr[8] = dr[9] = dr[13] = dr[15] = 0
        dr[14] = geo
        if not sounds:
            dr[2] = dr[12] = 0
        for k, (_, tname) in enumerate(tex):
            dr[6 + k] = dbase + len(dstr)
            dstr += tname.encode() + b'\0'
        mrows.append(mr)
        drows.append(dr)
    return {'CreatureModelData.dbc': (md0, append(md0, mrows, mstr)), 'CreatureDisplayInfo.dbc': (di0, append(di0, drows, dstr))}


client = build(client_table)
server = build(lambda n: open(SRV + B + n, 'rb').read())
csv_old = open(CLIENT + r'\Data\Retail\aliases_maps.csv', 'rb').read()
nl = b'\r\n' if b'\r\n' in csv_old else b'\n'
add = []
for nid, folder, fdid, tdisp, box, scale, geo, tex, sounds in M:
    add.append('%d;%s' % (fdid, V('Creature/%s/%s.m2' % (folder, folder))))
    add += ['%d;%s' % (t, V('Creature/%s/%s.blp' % (folder, tn))) for t, tn in tex]
for line in add:
    assert (line.split(';')[0] + ';').encode() not in csv_old, line
csv_new = csv_old + (b'' if csv_old.endswith(b'\n') else nl) + nl.join(x.encode() for x in add) + nl
assert not os.path.exists(CLIENT + r'\Data\Retail\TwoFormsTables\3055446.bin')
assert b'overlay=TwoFormsTables' in open(CLIENT + r'\Data\Retail\RetailCasc.ini', 'rb').read()


def wr(rel, data):
    f = os.path.join(P, rel.replace('/', B))
    os.makedirs(os.path.dirname(f), exist_ok=True)
    open(f, 'wb').write(data.encode('utf-8') if isinstance(data, str) else data)


hashes = []
for n, (old, new) in client.items():
    wr('01_导入Patch-YB.mpq/DBFilesClient/' + n, new)
    wr('05_撤销/原Patch-YB/DBFilesClient/' + n, old)
    hashes.append(('客户端 YB ' + n, sha(old), sha(new)))
wr('02_覆盖到客户端根目录/Data/Retail/aliases_maps.csv', csv_new)
wr('05_撤销/原客户端根目录/Data/Retail/aliases_maps.csv', csv_old)
hashes.append(('客户端 aliases_maps.csv', sha(csv_old), sha(csv_new)))
over = open(OVERLAY_SRC, 'rb').read()
wr('02_覆盖到客户端根目录/Data/Retail/TwoFormsTables/3055446.bin', over)
for n, (old, new) in server.items():
    wr('03_服务端_Data_dbc/' + n, new)
    wr('05_撤销/原服务端dbc/' + n, old)
    hashes.append(('服务端 ' + n, sha(old), sha(new)))

INFO = [(710004, 0.5, 1.5, 1), (710005, 1.5, 5, 2), (710006, 0.383, 1.5, 1), (710007, 0.383, 1.5, 0), (710008, 0.383, 1.5, 0)]
SET = [  # display, scale, entries, previous display, previous scale
    (710004, 1, [152843], 1350, 1),
    (710005, 0.5, [153964], 10869, 1.2),
    (710006, 1, [156280, 156626, 156651, 156807, 9156280], 30863, 1),
    (710007, 1, [156859, 156887, 167290], 15511, 1),
    (710007, 1.25, [156799, 167128, 167631], 15511, 1),
    (710008, 1, [9167675], 15511, 1),
]
allids = [e for s in SET for e in s[2]]
IDS = ', '.join(map(str, allids))
sql = ['-- MODEL1A V1: retail models for harpy / Bloodbeak / Jaina / Wrathion. Needs the server dbc rows of this package. Safe to run twice.',
       'SELECT COUNT(*) AS model_rows_before_must_be_%d FROM `creature_template_model` WHERE `CreatureID` IN (%s) AND `Idx` = 0;' % (len(allids), IDS),
       'DELETE FROM `creature_model_info` WHERE `DisplayID` BETWEEN 710004 AND 710008;']
sql += ['INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`) VALUES (%d, %s, %s, %d, 0);' % r for r in INFO]
sql += ['UPDATE `creature_template_model` SET `CreatureDisplayID` = %d, `DisplayScale` = %s WHERE `CreatureID` IN (%s) AND `Idx` = 0;' % (d, s, ', '.join(map(str, e))) for d, s, e, _, _ in SET]
sql += ['SELECT `CreatureDisplayID`, COUNT(*) AS npcs FROM `creature_template_model` WHERE `CreatureID` IN (%s) AND `Idx` = 0 GROUP BY `CreatureDisplayID` ORDER BY `CreatureDisplayID`;' % IDS,
        'SELECT COUNT(*) AS model_info_must_be_5 FROM `creature_model_info` WHERE `DisplayID` BETWEEN 710004 AND 710008;']
wr('04_服务端_SQL/world_model1a.sql', '\r\n'.join(sql) + '\r\n')
undo = ['UPDATE `creature_template_model` SET `CreatureDisplayID` = %d, `DisplayScale` = %s WHERE `CreatureID` IN (%s) AND `Idx` = 0;' % (pd, ps, ', '.join(map(str, e))) for _, _, e, pd, ps in SET]
undo.append('DELETE FROM `creature_model_info` WHERE `DisplayID` BETWEEN 710004 AND 710008;')
wr('05_撤销/undo_model1a.sql', '\r\n'.join(undo) + '\r\n')

table = '\n'.join('| %s | %s | %s |' % h for h in hashes)
wr('README_覆盖与测试说明.md', '''# MODEL1A V1：鹰身人、血喙、吉安娜、拉希奥换高版本原版模型

状态：候选，实机未测。前提：BRANCH1B、ALLY1D 已装。

| 角色 | 零售外观 -> 新编号 | 涉及的 NPC |
|---|---|---|
| 鹰身人唤雷者 | 63605 -> 710004 | 152843 |
| 血喙(零售是一只巨鸟，不是鹰身人) | 64922 -> 710005，缩放 0.5(零售值) | 153964 |
| 吉安娜 | 88316 -> 710006 | 156280、156626、156651、156807、9156280 |
| 拉希奥 | 93216 -> 710007(部分 NPC 缩放 1.25，即零售 107146) | 156859、156887、167290、156799、167128、167631 |
| 拉希奥(最后一处) | 115495 -> 710008 | 9167675 |

模型和贴图运行时从本机零售数据读取。例外：拉希奥模型(3055446)有一条音效事件的时间顺序写反了，客户端转换器会拒绝整个模型，
所以附了一个只改 4 个字节的本地副本放进 `Data\\Retail\\TwoFormsTables`(客户端现成的覆盖目录)。这个文件含零售素材，只在本机用，不要提交或分发。

## 部署(关游戏、停服)
1. 备份 `Data\\Patch-YB.mpq`。核对 YB 两张生物表 SHA256 等于下表"输入"；不相等说明别人改过，不要导入，告诉我重出。
2. 把 `01_导入Patch-YB.mpq\\DBFilesClient` 两个 DBC 导入 `Patch-YB.mpq`，保存并关闭 MPQ 编辑器。
3. 把 `02_覆盖到客户端根目录` 覆盖到客户端根目录(aliases_maps.csv 和一个 3055446.bin)。
4. 核对服务端两个 DBC 等于"输入"后备份，用 `03_服务端_Data_dbc` 覆盖 `Data\\dbc`。
5. world 库执行 `04_服务端_SQL\\world_model1a.sql`。开头读回 14；末尾 710004=1、710005=1、710006=5、710007=6、710008=1，model_info 5。
6. 启动服务端；删客户端 `Cache\\WDB` 后进游戏。

以后重跑更早阶段的任务 SQL 会把外观改回替代品，之后要接着再跑本包 SQL。

## 测试(.gm off；联盟和部落的坐标相同)
| 看什么 | 坐标 |
|---|---|
| 营地吉安娜、拉希奥(联盟) | `.go xyz 186 -2289 82 12175` |
| 鹰身人 | `.go xyz 436 -2408 147 12175` |
| 血喙 | `.go xyz 500 -2338 162 12175` |
| 巢穴入口拉希奥 | `.go xyz 392 -2440 126 12175` |

1. 逐个看：有贴图、会动，不是白模、绿色、方块或看不见；吉安娜身上没有两套部件重叠。
2. 打鹰身人和血喙：攻击、受击、死亡动作正常。
3. 血喙的大小和高度合适吗(是否陷地或悬空)。
4. 吉安娜、拉希奥模型很大(各约 20MB)，第一次看到时可能卡一下；请确认客户端不崩。
看到异常时说是哪一个，并把客户端 `Logs\\Extensions.log` 里含 Retail 的行发我。

## 指纹(SHA256)
| 文件 | 输入 | 输出 |
|---|---|---|
''' + table + '\n| 客户端 TwoFormsTables/3055446.bin | (原来没有) | ' + sha(over) + ''' |

## 撤销
1. YB 两张表导回 `05_撤销\\原Patch-YB`。
2. 用 `05_撤销\\原客户端根目录` 覆盖回根目录，删除 `Data\\Retail\\TwoFormsTables\\3055446.bin`。
3. 服务端换回 `05_撤销\\原服务端dbc`，执行 `05_撤销\\undo_model1a.sql`，重启。
''')
wr('memory.md', '''# memory - MODEL1A V1 (2026-11-25, Claude, 候选未测)
- 用户确认光明之灵(BRANCH1B)通过，指着血喙说小头目也不是高版本模型，要求鹰身人/血喙/拉希奥/吉安娜都换。
- 710004..710008；吉安娜 CreatureGeosetData=0x11(零售 CreatureDisplayInfoGeosetData：101、201)。
- 3055446 原文件事件 11 序列 25 时间戳 [267,0] -> 转换器报 Invalid M2 animation track；覆盖目录放排序后的副本。
- 仍是替代外观：Mithdran Dawntracker(166791/166996)、Breka Grimaxe(167632) 用 15511；亨利/基拉/梅瑞迪是定制人形。
''')
wr('tutor.md', '''# tutor - 零售模型被转换器拒绝时 (MODEL1A V1, 未实测)
1. 先离线转换(RetailAssetProbe --batch)，报错就照转换器源码里的检查逐条定位到哪个轨道、哪个序列。
2. 只改出错的几个字节，放进 RetailCasc.ini 的 overlay 目录(文件名=文件编号.bin)，再离线转换一次确认。
3. 一个模型有多套部件时，查零售 CreatureDisplayInfoGeosetData，填 3.3.5 的 CreatureGeosetData(每 4 位一组，最低位是 1xx 组)。
''')
lines = []
for dp, dn, fn in os.walk(P):
    for f in sorted(fn):
        p = os.path.join(dp, f)
        lines.append('%s  %s' % (sha(open(p, 'rb').read()), os.path.relpath(p, P).replace(B, '/')))
wr('SHA256SUMS.txt', '\n'.join(lines) + '\n')


def append_text(path, lines_):
    t = open(path, 'rb').read()
    e = b'\r\n' if b'\r\n' in t else b'\n'
    open(path, 'ab').write((b'' if t.endswith(b'\n') else e) + b''.join(x.encode('utf-8') + e for x in lines_))


log = os.path.join(WS, '协作说明_并行开发.md')
assert 'MODEL1A V1' not in open(log, 'rb').read().decode('utf-8', 'replace')
append_text(log, ['| 2026-11-25 | Claude | 验收：BRANCH1B V1(光明之灵零售模型) | 用户实机通过(未提交/未发布) | 同该包登记 | 基线同上 | 000Ascendupdate20261125 | YB 占用解除 |',
                  '| 2026-11-25 | Claude | MODEL1A V1(鹰身人/血喙/吉安娜/拉希奥零售模型 710004-710008) | 候选(未安装) | YB CreatureModelData/CreatureDisplayInfo 各+5行、aliases_maps.csv +10行、TwoFormsTables/3055446.bin、服务端同名DBC各+5行、SQL | 基线：当前实装 YB(含 710001-710003) | 包 000Ascendupdate20261125/%s | 占用 YB 两张生物表；安装前核对输入哈希 |' % NAME])
led = os.path.join(WS, '台账_YB_XA共享文件哈希.md')
append_text(led, ['', '## 2026-11-25 MODEL1A V1（Claude，候选未安装）', 'BRANCH1B V1 已确认实装(读回等于其 output)。本包外观 710004-710008，覆盖前核对 input。', '', '|文件|实际input|候选output|', '|---|---|---|'] + ['|%s|%s|%s|' % h for h in hashes])
sw = os.path.join(WS, '开关文件清单_会改变行为的文件和设置.md')
append_text(sw, ['', '- MODEL1A V1(2026-11-25，Claude)：客户端 Data\\Retail\\TwoFormsTables 新增 3055446.bin(替换零售拉希奥模型读取的本地副本)，Data\\Retail\\aliases_maps.csv +10 行。撤销：1 关闭客户端；2 删除 Data\\Retail\\TwoFormsTables\\3055446.bin；3 用包内 05_撤销\\原客户端根目录 覆盖回 aliases_maps.csv；4 让助手 ls 核对后登记已撤销。状态：待用户测试。'])
print(len(add), 'alias lines;', len(lines), 'files')
for h in hashes:
    print(h[0].encode('ascii', 'replace').decode(), h[1][:12], '->', h[2][:12])
print(open(os.path.join(P, '04_服务端_SQL', 'world_model1a.sql'), encoding='utf-8').read().encode('ascii', 'replace').decode())
