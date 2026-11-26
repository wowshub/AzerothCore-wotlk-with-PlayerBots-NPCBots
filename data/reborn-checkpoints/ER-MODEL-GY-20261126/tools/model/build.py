# -*- coding: utf-8 -*-
"""MODEL2A V1: retail ogres, Gor'groth, Tunk and Kalecgos (displays 710010-710024), shared by both factions."""
import ctypes, struct, os, hashlib, shutil, io, sys
from PIL import Image
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
B = chr(92)
WS = r'D:\000rebornWOW\000RebornWOWHighForkPRO'
DAY = os.path.join(WS, '000Ascendupdate', '000Ascendupdate20261126')
NAME = 'claudefix_20261126_阶段MODEL2A_V1_食人魔与暗槌首领和卡雷苟斯换高版本原版模型_Claude'
P = os.path.join(DAY, NAME)
assert not os.path.exists(P)
CLIENT = r'C:\000ref\WarcraftXL试装_client'
SRV = WS + r'\beascendserver\wowshub_playerbot_npcbot_newrace20261122Ascend\Data\dbc'
W = r'D:\_zsdc\boss2'
sha = lambda b: hashlib.sha256(b).hexdigest()
fb = lambda x: struct.unpack('<I', struct.pack('<f', x))[0]
EXPECT = {'client CreatureModelData.dbc': '3f65e33ea7ec', 'client CreatureDisplayInfo.dbc': '746bed181e6e', 'csv': 'a1f5a466f216',
          'server CreatureModelData.dbc': 'fbacc3a5ce6c', 'server CreatureDisplayInfo.dbc': 'c7d95c13b6c2'}

src = open(r'D:\_zsdc\models4\build_model1a.py', encoding='utf-8').read()
exec(src[src.index('dll = ctypes.WinDLL'):src.index('# id, folder, m2 file id')])      # client_table / parse / row_of / append

# ---------------------------------------------------------------- models: display id used for the model row -> (folder, geobox, template display, keep sounds)
MODEL = {
    'RetailOgre': (710010, (-0.92, -1.26, -0.17, 0.79, 1.26, 3.21), 11567, True),
    'RetailGorgroth': (710018, (-0.87, -1.27, -0.04, 0.67, 1.26, 3.27), 11567, True),
    'RetailTunk': (710019, (-4.61, -6.44, -0.01, 4.09, 6.88, 15.1), 11567, True),
    'RetailKalec': (710023, (-0.33, -0.56, 0.0, 0.38, 0.55, 2.04), 15511, False),
    'RetailKalecDragon': (710024, (-19.91, -9.86, -0.55, 10.38, 9.66, 13.43), 26752, True),
}


def geo(*pairs):
    """retail (GeosetIndex, GeosetValue) pairs -> 3.3.5 CreatureGeosetData, one nibble per group"""
    v = 0
    for i, g in pairs:
        assert g < 16
        v |= g << (4 * i)
    return v


tx = lambda *ids: ['%s%d' % ('Ogre', t) if t else None for t in ids]
# display id: (folder, retail display, geoset data, textures, bounding radius base, combat reach base)
DISPLAY = {
    710010: ('RetailOgre', 91775, geo((2, 3), (1, 1), (3, 3)), tx(937289, 960032, 937293), 0.5, 1.1),
    710011: ('RetailOgre', 91776, geo((3, 3), (2, 2), (1, 4)), tx(937286, 960032, 937292), 0.5, 1.1),
    710012: ('RetailOgre', 91777, geo((2, 2), (1, 1), (3, 3)), tx(937289, 960032, 937293), 0.5, 1.1),
    710013: ('RetailOgre', 91778, geo((3, 3), (2, 1), (1, 4)), tx(937286, 960032, 937292), 0.5, 1.1),
    710014: ('RetailOgre', 91779, geo((2, 3), (3, 4)), tx(937287, 960032, 937293), 0.5, 1.1),
    710015: ('RetailOgre', 91851, geo((2, 3), (0, 4), (3, 1)), tx(937287, 937283, 960033), 0.5, 1.1),
    710016: ('RetailOgre', 91853, geo((2, 6), (0, 2), (3, 1)), tx(937290, 937283, 960035), 0.5, 1.1),
    710017: ('RetailOgre', 91854, geo((2, 2), (0, 2), (3, 4), (1, 5)), tx(937289, 960034, 937292), 0.5, 1.1),
    710018: ('RetailGorgroth', 140024, 0, [], 0.45, 1.17),
    710019: ('RetailTunk', 97213, 0, ['Tunk985043'], 1.9, 5.0),
    710020: ('RetailOgre', 139988, geo((0, 7), (1, 7), (2, 1), (3, 2)), tx(937286, 960034, 960035), 0.5, 1.2),
    710021: ('RetailOgre', 139991, geo((0, 7), (1, 10), (2, 2), (3, 4)), tx(937286, 960032, 960033), 0.5, 1.2),
    710022: ('RetailOgre', 140023, geo((3, 1), (2, 3), (0, 6)), tx(937291, 937285, 0), 0.5, 1.2),
    710023: ('RetailKalec', 75614, 0, [], 0.3, 1.1),
    710024: ('RetailKalecDragon', 114576, geo((0, 2)), [], 1.35, 13.3),
}
# creature entry: ([display ids], scale, previous display, previous scale, label)
NPC = [
    (153239, [710010, 710011, 710012, 710013], 2.0, 11567, 1, '食人魔蛮兵(四种随机)'),
    (154103, [710014], 2.0, 11567, 1, '食人魔厨师'),
    (153581, [710015], 2.3, 11567, 1.25, '格伦克'),
    (153582, [710016], 2.3, 11567, 1.25, '沃格'),
    (153583, [710017], 2.3, 11567, 1.25, '朱格努格'),
    (153580, [710018], 3.0, 11567, 1.4, '戈尔格罗斯(外圈)'),
    (156814, [710018], 3.0, 25192, 1.75, '戈尔格罗斯(首领)'),
    (157300, [710019], 0.7, 18047, 1.25, '图克'),
    (9159801, [710020], 1.7, 11561, 0.62, '暗槌百夫长'),
    (9159802, [710021], 1.65, 14423, 0.68, '暗槌暗影召唤师'),
    (9159803, [710022], 1.65, 14423, 0.68, '暗槌导灵者'),
    (167663, [710023], 1.4, 26752, 0.3, '卡雷苟斯(友方，部落)'),
    (161350, [710023], 1.4, 26752, 0.3, '卡雷苟斯(友方，联盟)'),
    (156501, [710024], 0.9, 26752, 0.6, '卡雷苟斯(巨龙首领)'),
]
NEW_IDS = sorted(DISPLAY)
base = lambda f: B.join(['retail', f, f])


def build(read):
    md0, di0 = read('CreatureModelData.dbc'), read('CreatureDisplayInfo.dbc')
    msb, dbase = parse(md0)[4], len(parse(di0)[4])
    mrows, drows, mstr, dstr, strings = [], [], b'', b'', {}
    for folder, (mid, box, tdisp, sounds) in MODEL.items():
        mr = row_of(md0, row_of(di0, tdisp)[1])
        assert mr is not None and len(mr) == 28
        mr[0], mr[2] = mid, len(msb) + len(mstr)
        mstr += (base(folder) + '.mdx').encode() + b'\0'
        mr[4] = fb(1.0)
        if not sounds:
            mr[13] = 0
        mr[14], mr[15], mr[16] = fb(0.611), fb(2.031), 0
        for i, v in zip(range(17, 23), box):
            mr[i] = fb(v)
        mrows.append(mr)
    for nid, (folder, retail, g, tex, _, _) in sorted(DISPLAY.items()):
        mid, box, tdisp, sounds = MODEL[folder]
        dr = row_of(di0, tdisp)
        assert len(dr) == 16
        dr[0], dr[1] = nid, mid
        dr[3] = 0
        dr[4], dr[5] = fb(1.0), 255
        dr[6] = dr[7] = dr[8] = dr[9] = dr[13] = dr[15] = 0
        dr[14] = g
        if not sounds:
            dr[2] = dr[12] = 0
        for k, t in enumerate(tex):
            if t:
                if t not in strings:
                    strings[t] = dbase + len(dstr)
                    dstr += t.encode() + b'\0'
                dr[6 + k] = strings[t]
        drows.append(dr)
    return {'CreatureModelData.dbc': (md0, append(md0, mrows, mstr)), 'CreatureDisplayInfo.dbc': (di0, append(di0, drows, dstr))}


client = build(client_table)
server = build(lambda n: open(SRV + B + n, 'rb').read())
for who, tabs in (('client', client), ('server', server)):
    for n, (old, new) in tabs.items():
        assert sha(old).startswith(EXPECT[who + ' ' + n]), ('someone changed', who, n, sha(old)[:12])
csv_old = open(CLIENT + r'\Data\Retail\aliases_maps.csv', 'rb').read()
assert sha(csv_old).startswith(EXPECT['csv'])
nl = b'\r\n' if b'\r\n' in csv_old else b'\n'
add = open(W + B + 'aliases_maps.csv', 'rb').read().split()
for line in add:
    fdid = line.split(b';')[0] + b';'
    assert not any(x.startswith(fdid) for x in csv_old.split()), line
csv_new = csv_old + (b'' if csv_old.endswith(b'\n') else nl) + nl.join(add) + nl
# every texture a display names must have an alias in the model's folder
for nid, (folder, _, _, tex, _, _) in DISPLAY.items():
    for t in tex:
        if t:
            assert (B.join(['retail', folder, t + '.blp'])).encode() in csv_new, (nid, t)
            assert os.path.isfile(W + r'\d' + B + 'retail_%s_%s.blp' % (folder, t)), t

# the new rows read back
for tabs in (client, server):
    di_new = tabs['CreatureDisplayInfo.dbc'][1]
    sb = parse(di_new)[4]
    for nid, (folder, _, g, tex, _, _) in DISPLAY.items():
        r = row_of(di_new, nid)
        assert r[1] == MODEL[folder][0] and r[14] == g
        assert [sb[r[6 + k]:sb.index(0, r[6 + k])].decode() for k in range(len(tex)) if tex[k]] == [t for t in tex if t]


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

entries = [e for e, *_ in NPC]
EL = ', '.join(map(str, entries))
n_rows = sum(len(d) for _, d, *_ in NPC)
HEAD = 'INSERT INTO `creature_template_model` (`CreatureID`, `Idx`, `CreatureDisplayID`, `DisplayScale`, `Probability`, `VerifiedBuild`) VALUES'
sql = ['-- MODEL2A V1: retail ogres, Darkmaul bosses and Kalecgos. Needs ALLY1F, ALLY1G and the server dbc rows of this package. Safe to run twice.',
       'SELECT COUNT(*) AS creatures_found_must_be_%d FROM `creature_template` WHERE `entry` IN (%s);' % (len(entries), EL),
       'DELETE FROM `creature_model_info` WHERE `DisplayID` BETWEEN %d AND %d;' % (NEW_IDS[0], NEW_IDS[-1])]
sql += ['INSERT INTO `creature_model_info` (`DisplayID`, `BoundingRadius`, `CombatReach`, `Gender`, `DisplayID_Other_Gender`) VALUES (%d, %s, %s, 0, 0);' % (i, DISPLAY[i][4], DISPLAY[i][5]) for i in NEW_IDS]
sql.append('DELETE FROM `creature_template_model` WHERE `CreatureID` IN (%s);' % EL)
for e, disp, scale, _, _, _ in NPC:
    sql.append(HEAD + ' ' + ', '.join('(%d, %d, %d, %s, 1, 0)' % (e, i, d, scale) for i, d in enumerate(disp)) + ';')
sql += ['SELECT (SELECT COUNT(*) FROM `creature_template_model` WHERE `CreatureID` IN (%s) AND `CreatureDisplayID` BETWEEN %d AND %d) AS model_rows_must_be_%d,' % (EL, NEW_IDS[0], NEW_IDS[-1], n_rows),
        '       (SELECT COUNT(*) FROM `creature_model_info` WHERE `DisplayID` BETWEEN %d AND %d) AS model_info_must_be_%d;' % (NEW_IDS[0], NEW_IDS[-1], len(NEW_IDS))]
wr('04_服务端_SQL/world_model2a.sql', '\r\n'.join(sql) + '\r\n')
undo = ['DELETE FROM `creature_template_model` WHERE `CreatureID` IN (%s);' % EL]
undo += [HEAD + ' (%d, 0, %d, %s, 1, 0);' % (e, pd, ps) for e, _, _, pd, ps, _ in NPC]
undo.append('DELETE FROM `creature_model_info` WHERE `DisplayID` BETWEEN %d AND %d;' % (NEW_IDS[0], NEW_IDS[-1]))
wr('05_撤销/undo_model2a.sql', '\r\n'.join(undo) + '\r\n')

# offline preview: the standing row of each model
tiles = []
for f in MODEL:
    im = Image.open(W + B + f + '.png').crop((0, 0, 1300, 320))
    tiles.append(im)
sheet = Image.new('RGB', (1300, 324 * len(tiles)), (200, 120, 0))
for i, t in enumerate(tiles):
    sheet.paste(t, (0, 324 * i))
sheet.resize((975, 243 * len(tiles))).save(os.path.join(P, '离线渲染_食人魔_戈尔格罗斯_图克_卡雷苟斯人形_巨龙.png'))

size_rows = '\n'.join('| %s | %d | %s | %s |' % (label, e, '/'.join(map(str, d)), s) for e, d, s, _, _, label in NPC)
table = '\n'.join('| %s | %s | %s |' % h for h in hashes)
wr('README_覆盖与测试说明.md', '''# MODEL2A V1：食人魔、暗槌首领和卡雷苟斯换高版本原版模型

状态：候选，游戏里未测。离线转换和站立/移动/攻击/说话姿势渲染正常(渲染是灰模，**贴图和部件搭配要进游戏看**)。
前提：ALLY1F、ALLY1G 已装。联盟和部落共用这些生物，两边一起换。

## 换了什么
| 角色 | NPC | 新外观 | 缩放 |
|---|---|---|---|
%s

缩放基本按零售值。例外：三种首领守卫比零售小一些(零售接近首领大小)，巨龙卡雷苟斯约按原来的体型(零售还要大近一倍)。觉得不合适告诉我，只改一个数。
模型和贴图运行时从本机零售数据读取。

## 部署(关游戏、停服)
1. 备份 `Data\\Patch-YB.mpq`。核对 YB 两张生物表 SHA256 等于下表"输入"；不相等说明别人改过，不要导入，告诉我。
2. 把 `01_导入Patch-YB.mpq\\DBFilesClient` 两个 DBC 导入 `Patch-YB.mpq`，保存并关闭 MPQ 编辑器。
3. 把 `02_覆盖到客户端根目录` 覆盖到客户端根目录(只有 aliases_maps.csv)。
4. 核对服务端两个 DBC 等于"输入"后备份，用 `03_服务端_Data_dbc` 覆盖 `Data\\dbc`。
5. world 库执行 `04_服务端_SQL\\world_model2a.sql`。开头读回 %d；末尾 model_rows %d、model_info %d。
6. 启动服务端；删客户端 `Cache\\WDB`。

以后重跑部落 DARK 系列或联盟 ALLY1G 的任务 SQL 会把外观改回去，之后要接着再跑本包 SQL。

## 测试(.gm off，坐标 `.go xyz … 12175`)
| 看什么 | 坐标 |
|---|---|
| 食人魔、投石机一带 | `481 -2113 133` |
| 厨师、外圈戈尔格罗斯 | `595 -2063 160` |
| 三个副官 | `663 -2128 162`、`592 -2011 176`、`510 -1965 145` |
| 副本：图克和守卫 | `765 -1450 177` |
| 副本：戈尔格罗斯 | `860 -1615 219` |
| 副本：巨龙卡雷苟斯(前两个打完才出现) | `770 -1430 273` |
| 友方卡雷苟斯(人形) | `712 -1878 187` |

1. 每个都有贴图、会动，不是白模、绿色、方块或看不见；食人魔没有缺头、缺身体或两套部件重叠。
2. 打一场：攻击、受击、死亡动作正常，近战够得着(尤其巨龙)。
3. 大小合适吗：有没有卡进墙或天花板、浮空、陷地。
4. 第一次看到时模型较大，可能卡一下；请确认客户端不崩。
异常时说是哪一个，并发客户端 `Logs\\Extensions.log` 里含 Retail 的行。

## 指纹(SHA256)
| 文件 | 输入 | 输出 |
|---|---|---|
%s

## 撤销
1. YB 两张表导回 `05_撤销\\原Patch-YB`。
2. 用 `05_撤销\\原客户端根目录` 覆盖回根目录。
3. 服务端换回 `05_撤销\\原服务端dbc`，执行 `05_撤销\\undo_model2a.sql`，重启。
''' % (size_rows, len(entries), n_rows, len(NEW_IDS), table))
wr('memory.md', '''# memory - MODEL2A V1 (2026-11-26, Claude, 候选未测)
- 用户："换吧"。710010..710024；食人魔共用模型 930099(部件组=CreatureGeosetData 每组 4 位)；戈尔格罗斯 3545238；图克 984967；卡雷苟斯 4238520 / 4496906。
- 五个模型都没有外部骨架；别名路径统一用 retail\\ 开头。
- 脚本 D:\\_zsdc\\boss2\\(conv.py、render3.py、build.py)。
''')
wr('tutor.md', '''# tutor - 一个零售模型做出多种兵种 (MODEL2A V1, 未实测)
1. 同一个模型靠部件组和贴图区分兵种：零售 CreatureDisplayInfoGeosetData 的 (组序号, 值) 按每组 4 位写进 3.3.5 CreatureGeosetData。
2. 转换时模型要和它的 skin、anim 放在同一次进程里，否则读不到。
3. 缩放写在 creature_template_model，combat_reach 的基数要除以缩放，近战距离才合理。
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
assert 'MODEL2A V1' not in open(log, 'rb').read().decode('utf-8', 'replace')
append_text(log, ['| 2026-11-26 | Claude | MODEL2A V1(食人魔/暗槌首领/卡雷苟斯零售模型 710010-710024) | 候选(未安装) | YB CreatureModelData +5行、CreatureDisplayInfo +15行、aliases_maps.csv +%d行、服务端同名DBC、SQL | 基线：ALLY1E-M 输出(当前实装 YB) | 包 000Ascendupdate20261126/%s | 占用 YB 两张生物表；Codex 改这两张表前请先告知 |' % (len(add), NAME)])
led = os.path.join(WS, '台账_YB_XA共享文件哈希.md')
append_text(led, ['', '## 2026-11-26 MODEL2A V1（Claude，候选未安装）', '外观 710010-710024，覆盖前核对 input。', '', '|文件|实际input|候选output|', '|---|---|---|'] + ['|%s|%s|%s|' % h for h in hashes])
print(len(add), 'alias lines;', len(lines), 'files; rows', n_rows)
for h in hashes:
    print(h[0], h[1][:12], '->', h[2][:12])
print(open(os.path.join(P, '04_服务端_SQL', 'world_model2a.sql'), encoding='utf-8').read()[-1500:])
