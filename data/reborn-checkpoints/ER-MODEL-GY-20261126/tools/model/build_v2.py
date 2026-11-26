# -*- coding: utf-8 -*-
"""MODEL2A V2: ogre part groups that retail does not list must be hidden explicitly (a zero nibble leaves every variant visible)."""
import ctypes, struct, os, hashlib, io, sys, glob
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
B = chr(92)
WS = r'D:\000rebornWOW\000RebornWOWHighForkPRO'
DAY = os.path.join(WS, '000Ascendupdate', '000Ascendupdate20261126')
NAME = 'claudefix_20261126_阶段MODEL2A_V2_食人魔白模肩甲修复_Claude'
P = os.path.join(DAY, NAME)
assert not os.path.exists(P)
V1 = glob.glob(DAY + B + 'claudefix_*MODEL2A_V1_*')[0]
CLIENT = r'C:\000ref\WarcraftXL试装_client'
SRV = WS + r'\beascendserver\wowshub_playerbot_npcbot_newrace20261122Ascend\Data\dbc'
W = r'D:\_zsdc\boss2'
sha = lambda b: hashlib.sha256(b).hexdigest()
src = open(r'D:\_zsdc\models4\build_model1a.py', encoding='utf-8').read()
exec(src[src.index('dll = ctypes.WinDLL'):src.index('# id, folder, m2 file id')])

OGRES = [710010, 710011, 710012, 710013, 710014, 710015, 710016, 710017, 710020, 710021, 710022]
cl_old = client_table('CreatureDisplayInfo.dbc')
sv_old = open(SRV + B + 'CreatureDisplayInfo.dbc', 'rb').read()
assert cl_old == open(V1 + r'\01_导入Patch-YB.mpq\DBFilesClient\CreatureDisplayInfo.dbc', 'rb').read(), 'client table is not the V1 output'
assert sv_old == open(V1 + r'\03_服务端_Data_dbc\CreatureDisplayInfo.dbc', 'rb').read(), 'server table is not the V1 output'

# the ogre model's parts: geoset id -> texture slot types it needs
m = open(W + r'\d\retail_RetailOgre_RetailOgre.m2', 'rb').read()
sk = open(W + r'\d\retail_RetailOgre_RetailOgre00.skin', 'rb').read()
nsub, osub = struct.unpack_from('<II', sk, 28)
nbat, obat = struct.unpack_from('<II', sk, 36)
lookup = struct.unpack_from('<I', m, 0x84)[0]
texofs = struct.unpack_from('<I', m, 0x54)[0]
sub_ids = [struct.unpack_from('<H', sk, osub + 48 * s)[0] for s in range(nsub)]
types = {}
for b in range(nbat):
    q = obat + 24 * b
    section = struct.unpack_from('<H', sk, q + 4)[0]
    count, combo = struct.unpack_from('<HH', sk, q + 14)
    for k in range(count):
        t = struct.unpack_from('<h', m, lookup + 2 * (combo + k))[0]
        types.setdefault(sub_ids[section], set()).add(struct.unpack_from('<I', m, texofs + 16 * t)[0])
assert set(types) == set(sub_ids) and max(sub_ids) < 500 and not any(i % 100 >= 15 for i in sub_ids)


def visible(geo):
    """the client's rule (CCharacterComponent::ApplyMonsterGeosets): a non-zero nibble shows exactly that variant, zero leaves the group untouched"""
    out = []
    for sid in sub_ids:
        group = sid // 100
        v = (geo >> (4 * (group - 1))) & 0xF if group else 0
        if group == 0 or v == 0 or sid % 100 == v:
            out.append(sid)
    return sorted(set(out))


def patch(d):
    n, nf, rs, rows, sb = parse(d)
    out = bytearray(d)
    report = []
    for i in range(n):
        r = struct.unpack_from('<%dI' % nf, rows, i * rs)
        if r[0] not in OGRES:
            continue
        old = r[14]
        new = old
        for g in range(4):
            if not (old >> (4 * g)) & 0xF:
                new |= 0xF << (4 * g)
        struct.pack_into('<I', out, 20 + i * rs + 14 * 4, new)
        have = {11 + k for k in range(3) if r[6 + k]}
        for when, geo in (('old', old), ('new', new)):
            parts = visible(geo)
            missing = sorted({t for s in parts for t in types[s] if t and t not in have})
            groups = [s // 100 for s in parts]
            report.append((r[0], when, hex(geo), parts, missing))
            if when == 'new':
                assert not missing, (r[0], missing, parts)
                assert len(groups) == len(set(groups)), ('two variants of one group', r[0], parts)
                assert 3 in groups and 4 in groups, ('no head or body', r[0], parts)
    assert len(report) == 2 * len(OGRES)
    return bytes(out), report


cl_new, rep = patch(cl_old)
sv_new, _ = patch(sv_old)
for rid, when, geo, parts, missing in rep:
    print(rid, when, geo, 'parts', len(parts), parts if len(parts) < 8 else parts[:7] + ['...'], 'missing texture types', missing)


def wr(rel, data):
    f = os.path.join(P, rel.replace('/', B))
    os.makedirs(os.path.dirname(f), exist_ok=True)
    open(f, 'wb').write(data.encode('utf-8') if isinstance(data, str) else data)


wr('01_导入Patch-YB.mpq/DBFilesClient/CreatureDisplayInfo.dbc', cl_new)
wr('02_服务端_Data_dbc/CreatureDisplayInfo.dbc', sv_new)
wr('03_撤销/原Patch-YB/DBFilesClient/CreatureDisplayInfo.dbc', cl_old)
wr('03_撤销/原服务端dbc/CreatureDisplayInfo.dbc', sv_old)
hashes = [('客户端 YB CreatureDisplayInfo.dbc', sha(cl_old), sha(cl_new)), ('服务端 CreatureDisplayInfo.dbc', sha(sv_old), sha(sv_new))]
table = '\n'.join('| %s | %s | %s |' % h for h in hashes)
wr('README_覆盖与测试说明.md', '''# MODEL2A V2：食人魔白模肩甲修复

状态：候选，游戏里未测。叠在 MODEL2A V1 上，只换一张外观表。SQL 不用再跑。

## 原因
客户端规则：某个部件组填 0 时，该组所有款式一起显示(不是隐藏)。V1 里零售没有指定的组填了 0：
暗槌导灵者十几套肩甲叠在一起，其中一类贴图本来就没有，显示成白色；厨师、蛮兵等也有部件叠在一起。

## 改动
CreatureDisplayInfo 里 11 个食人魔外观中，零售没指定的部件组改填一个不存在的款式号(整组隐藏)。
离线按客户端规则核对：每个食人魔每组最多一个部件、有头有身体、显示出来的部件都有贴图。

## 安装(关客户端和服务端)
1. 备份 `Data\\Patch-YB.mpq`。核对 YB 里 CreatureDisplayInfo.dbc 的 SHA256 等于下表"输入"；不相等就别导入，告诉我。
2. 把 `01_导入Patch-YB.mpq\\DBFilesClient\\CreatureDisplayInfo.dbc` 导入 YB，保存并关闭 MPQ 编辑器。
3. `02_服务端_Data_dbc` 里的文件覆盖服务端 `Data\\dbc`。
4. 启动服务端；删客户端 `Cache\\WDB`。

## 测试
1. 导灵者(`.go xyz 858 -1617 220 12175` 首领旁)没有白色肩甲。
2. 食人魔蛮兵、厨师、三个副官、百夫长、召唤师：没有白色部件，没有两套部件穿插，没有缺头缺身体。
3. 还有哪个看着不对，截图告诉我。

## 指纹(SHA256)
| 文件 | 输入 | 输出 |
|---|---|---|
%s

## 撤销
YB 导回 `03_撤销\\原Patch-YB` 里的表，服务端换回 `03_撤销\\原服务端dbc`。
''' % table)
wr('memory.md', '''# memory - MODEL2A V2 (2026-11-26, Claude, 候选未测)
- 用户截图：暗槌导灵者白膜肩膀。
- ApplyMonsterGeosets(0x004E7790)：nibble 非 0 才隐藏整组并显示指定款；0 = 整组保持可见。零售未指定的组要填 0xF。
- 教训：离线渲染时按自己假设过滤部件，没有按客户端规则渲染，所以 V1 没发现。
''')
wr('tutor.md', '''# tutor - 生物部件组叠在一起或白模 (MODEL2A V2, 未实测)
1. 查客户端 ApplyMonsterGeosets 的规则：0 表示"不改"，不是"隐藏"。
2. 要隐藏一组就填一个模型里没有的款式号。
3. 检查脚本要按客户端规则算出可见部件，再核对每个部件需要的贴图槽都有贴图。
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
assert 'MODEL2A V2(' not in open(log, 'rb').read().decode('utf-8', 'replace')
append_text(log, ['| 2026-11-26 | Claude | MODEL2A V2(食人魔白模肩甲：未指定部件组改为隐藏) | 候选(未安装) | YB 与服务端 CreatureDisplayInfo.dbc 仅 710010-710022 的 CreatureGeosetData | 基线：MODEL2A V1 实装 | 包 000Ascendupdate20261126/%s | 占用 YB CreatureDisplayInfo |' % NAME])
append_text(os.path.join(WS, '台账_YB_XA共享文件哈希.md'), ['', '## 2026-11-26 MODEL2A V2（Claude，候选未安装）', '', '|文件|实际input|候选output|', '|---|---|---|'] + ['|%s|%s|%s|' % h for h in hashes])
for h in hashes:
    print(h[0], h[1][:12], '->', h[2][:12])
