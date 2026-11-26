# -*- coding: utf-8 -*-
"""BRANCH1B V1: the Lightspawn (157114, quest 54933) uses its retail model (display 70162, M2 1348273) as display 710003."""
import ctypes, struct, os, hashlib, shutil
B = chr(92)
WS = r'D:\000rebornWOW\000RebornWOWHighForkPRO'
DAY = os.path.join(WS, '000Ascendupdate', '000Ascendupdate20261125')
NAME = 'claudefix_20261125_阶段BRANCH1B_V1_光明之灵换高版本原版模型_Claude'
P = os.path.join(DAY, NAME)
assert not os.path.exists(P)
CLIENT = r'C:\000ref\WarcraftXL试装_client'
SRV = WS + r'\beascendserver\wowshub_playerbot_npcbot_newrace20261122Ascend\Data\dbc'
NEW, OLD_DISPLAY, NPC, FDID = 710003, 5233, 157114, 1348273
MODEL = 'Creature\\RetailLightspawn\\RetailLightspawn.mdx'
ALIAS = '%d;Creature\\RetailLightspawn\\RetailLightspawn.m2' % FDID

dll = ctypes.WinDLL(r'D:\soft\python3.9\Lib\site-packages\pympq\StormLib.dll')
dll.SFileOpenArchive.argtypes = [ctypes.c_wchar_p, ctypes.c_uint32, ctypes.c_uint32, ctypes.POINTER(ctypes.c_void_p)]
dll.SFileOpenFileEx.argtypes = [ctypes.c_void_p, ctypes.c_char_p, ctypes.c_uint32, ctypes.POINTER(ctypes.c_void_p)]
dll.SFileGetFileSize.argtypes = [ctypes.c_void_p, ctypes.c_void_p]
dll.SFileGetFileSize.restype = ctypes.c_uint32
dll.SFileReadFile.argtypes = [ctypes.c_void_p, ctypes.c_void_p, ctypes.c_uint32, ctypes.POINTER(ctypes.c_uint32), ctypes.c_void_p]
dll.SFileCloseArchive.argtypes = [ctypes.c_void_p]
sha = lambda b: hashlib.sha256(b).hexdigest()


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


def row_of(rows, rs, key):
    for i in range(len(rows) // rs):
        if struct.unpack_from('<I', rows, i * rs)[0] == key:
            return list(struct.unpack_from('<%dI' % (rs // 4), rows, i * rs))
    return None


fb = lambda x: struct.unpack('<I', struct.pack('<f', x))[0]


def add(d, values, strings=b''):
    n, nf, rs, rows, sb = parse(d)
    assert row_of(rows, rs, NEW) is None, 'id %d already present' % NEW
    out = b'WDBC' + struct.pack('<4I', n + 1, nf, rs, len(sb) + len(strings)) + rows + struct.pack('<%dI' % nf, *values) + sb + strings
    m = parse(out)
    assert m[0] == n + 1 and m[3][:len(rows)] == rows and m[4][:len(sb)] == sb
    return out


def model_table(d, template_model):
    n, nf, rs, rows, sb = parse(d)
    assert nf == 28
    f = row_of(rows, rs, template_model)
    f[0], f[2] = NEW, len(sb)
    f[4] = fb(1.0)
    f[13] = 0                                  # no model sound set
    f[14], f[15] = fb(0.611), fb(2.031)        # retail model 8928
    f[16] = 0
    for i, v in zip(range(17, 23), (-0.943, -1.841, 0.082, 1.086, 1.841, 3.446)):
        f[i] = fb(v)
    return add(d, f, MODEL.encode() + b'\0')


def display_table(d, template_display):
    n, nf, rs, rows, sb = parse(d)
    assert nf == 16
    f = row_of(rows, rs, template_display)
    f[0], f[1] = NEW, NEW
    f[2] = f[3] = 0
    f[4], f[5] = fb(1.0), 255
    for i in (6, 7, 8, 9, 12, 13, 14, 15):
        f[i] = 0
    return add(d, f)


def build(read):
    dis = read('CreatureDisplayInfo.dbc')
    md = read('CreatureModelData.dbc')
    old = row_of(parse(dis)[3], parse(dis)[2], OLD_DISPLAY)
    assert old is not None
    return {'CreatureModelData.dbc': (md, model_table(md, old[1])), 'CreatureDisplayInfo.dbc': (dis, display_table(dis, OLD_DISPLAY))}


client = build(client_table)
server = build(lambda n: open(SRV + B + n, 'rb').read())
csv_old = open(CLIENT + r'\Data\Retail\aliases_maps.csv', 'rb').read()
assert str(FDID).encode() not in csv_old
nl = b'\r\n' if b'\r\n' in csv_old else b'\n'
csv_new = csv_old + (b'' if csv_old.endswith(b'\n') else nl) + ALIAS.encode() + nl


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
for n, (old, new) in server.items():
    wr('03_服务端_Data_dbc/' + n, new)
    wr('05_撤销/原服务端dbc/' + n, old)
    hashes.append(('服务端 ' + n, sha(old), sha(new)))

wr('04_服务端_SQL/world_branch1b.sql', '\r\n'.join([
    '-- BRANCH1B V1: Lightspawn %d uses the retail model as creature display %d. Needs the server dbc rows of this package. Safe to run twice.' % (NPC, NEW),
    'DELETE FROM `creature_model_info` WHERE `DisplayID` = %d;' % NEW,
    'INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`) VALUES (%d, 0.6, 1.5, 2, 0);' % NEW,
    'UPDATE `creature_template_model` SET `CreatureDisplayID` = %d, `DisplayScale` = 1 WHERE `CreatureID` = %d;' % (NEW, NPC),
    'SELECT `CreatureID`, `CreatureDisplayID`, `DisplayScale`,',
    '       (SELECT COUNT(*) FROM `creature_model_info` WHERE `DisplayID` = %d) AS model_info_must_be_1' % NEW,
    'FROM `creature_template_model` WHERE `CreatureID` = %d;' % NPC, '']))
wr('05_撤销/undo_branch1b.sql', '\r\n'.join([
    'UPDATE `creature_template_model` SET `CreatureDisplayID` = %d, `DisplayScale` = 1.3 WHERE `CreatureID` = %d;' % (OLD_DISPLAY, NPC),
    'DELETE FROM `creature_model_info` WHERE `DisplayID` = %d;' % NEW, '']))

table = '\n'.join('| %s | %s | %s |' % h for h in hashes)
wr('README_覆盖与测试说明.md', '''# BRANCH1B V1：光明之灵换成高版本原版模型

状态：候选，实机未测。前提：BRANCH1A(任务 54933)已装。

## 做了什么
BRANCH1A 里光明之灵借用的是灵魂医者外观。本包换成零售的原版模型(零售外观 70162，模型文件 1348273，缩放 1)，新外观编号 710003。
模型和贴图不复制进补丁，客户端运行时从本机零售数据读取(和野猪、杀爪熊同一办法)。

## 部署(关游戏、停服)
先关掉打开着的 MPQ 编辑器。
1. 备份 `Data\\Patch-YB.mpq`。核对 YB 里 CreatureModelData、CreatureDisplayInfo 两张表的 SHA256 是否等于下表"输入"；
   不相等说明打包之后有人改过 YB，不要导入，告诉我重出。
2. 把 `01_导入Patch-YB.mpq\\DBFilesClient` 的两个 DBC 导入 `Patch-YB.mpq`。
3. 把 `02_覆盖到客户端根目录` 覆盖到客户端根目录(只有 aliases_maps.csv，末尾多一行)。
4. 备份后用 `03_服务端_Data_dbc` 两个文件覆盖服务端 `Data\\dbc`。
5. world 库执行 `04_服务端_SQL\\world_branch1b.sql`，读回：157114 / 710003 / 1 / model_info 1。
6. 启动服务端；删客户端 `Cache\\WDB` 后进游戏。

## 测试
`.go xyz 301.4 -2486.3 116 12175`
1. 光明之灵显示为发光的灵体新模型，有贴图和光效，会动；不是白模、方块或看不见。
2. 大小合适吗(零售原尺寸，大约是玩家的一个半高)。
3. 54933 能接、能交。
4. 在它附近停一会儿，客户端不崩溃(模型带粒子特效，这是本包最需要确认的一点)。

## 没做的
零售的发光光环(法术 319104)3.3.5 没有，没加。基座、告示牌、宝箱仍是原版替代物体。

## 指纹(SHA256)
| 文件 | 输入 | 输出 |
|---|---|---|
''' + table + '''

## 撤销
客户端：把 `05_撤销\\原Patch-YB` 两个表导回 YB，`05_撤销\\原客户端根目录` 覆盖回根目录。
服务端：换回 `05_撤销\\原服务端dbc`，执行 `05_撤销\\undo_branch1b.sql`，重启。
''')
wr('memory.md', '''# memory - BRANCH1B V1 (2026-11-25, Claude, 候选未测)
- 用户测 BRANCH1A 通过，指出支线 NPC 不像高版本：157114 光明之灵当时用 5233(灵魂医者)。
- 零售 70162 -> 模型 8928 -> M2 1348273 (ManaFiend_Holy)，贴图全部写死在模型里(TXID)，不需要贴图别名和 TextureVariation。
- 新外观/模型编号 710003；RetailAssetProbe --batch 离线转换通过(264 版)，实机未测。
''')
wr('tutor.md', '''# tutor - 导入贴图写死在模型里的零售生物 (BRANCH1B V1, 未实测)
和野猪不同：CreatureDisplayInfo 的 TextureVariation 全部留空，aliases 只加模型一行；贴图由客户端按模型内的文件编号读取。
先用 `RetailAssetProbe <ini> --extract-batch <列表> <输出目录>` 取原文件(参数少一个会静默返回 2)，再用 --batch 离线跑一遍转换确认能读。
''')
lines = []
for dp, dn, fn in os.walk(P):
    for f in sorted(fn):
        p = os.path.join(dp, f)
        lines.append('%s  %s' % (sha(open(p, 'rb').read()), os.path.relpath(p, P).replace(B, '/')))
wr('SHA256SUMS.txt', '\n'.join(lines) + '\n')

log = os.path.join(WS, '协作说明_并行开发.md')
t = open(log, 'rb').read()
assert 'BRANCH1B V1'.encode() not in t
e = b'\r\n' if b'\r\n' in t else b'\n'
rows = ['| 2026-11-25 | Claude | 验收：ALLY1C V3(联盟野猪坐骑)、BRANCH1A(分支任务 56839/54933) | 用户实机通过(未提交/未发布) | 同各自登记 | 基线同上 | 000Ascendupdate20261125 | 无共享客户端文件 |',
        '| 2026-11-25 | Claude | BRANCH1B V1(光明之灵 157114 换零售模型 710003) | 候选(未安装) | YB CreatureModelData/CreatureDisplayInfo 各+1行(710003)、aliases_maps.csv +1行、服务端同名DBC各+1行、SQL | 基线：当前实装 YB(含 710001/710002 与 MOGU 改动) | 包 000Ascendupdate20261125/%s | 占用 YB 两张生物表；安装前核对输入哈希 |' % NAME]
open(log, 'ab').write((b'' if t.endswith(b'\n') else e) + b''.join(r.encode('utf-8') + e for r in rows))
led = os.path.join(WS, '台账_YB_XA共享文件哈希.md')
t = open(led, 'rb').read()
e = b'\r\n' if b'\r\n' in t else b'\n'
block = ['', '## 2026-11-25 BRANCH1B V1（Claude，候选未安装）', '光明之灵外观 710003。覆盖前核对 input，不一致先合并。', '', '|文件|实际input|候选output|', '|---|---|---|'] + ['|%s|%s|%s|' % h for h in hashes]
open(led, 'ab').write((b'' if t.endswith(b'\n') else e) + e.join(x.encode('utf-8') for x in block) + e)
for h in hashes:
    print(h[0].encode('ascii', 'replace').decode(), h[1][:12], '->', h[2][:12])
