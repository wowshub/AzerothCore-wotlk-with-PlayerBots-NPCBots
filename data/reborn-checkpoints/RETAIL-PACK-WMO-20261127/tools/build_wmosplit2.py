# -*- coding: utf-8 -*-
"""WMOSPLIT2 V1: the accepted split-group treatment for all four ported buildings that have indoor split groups."""
import io, os, sys, struct, hashlib, shutil, subprocess, pickle, math

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
exec(open(r'D:\_zsdc\slim\collect.py', encoding='utf-8').read().split('def main():')[0].replace(
    "sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', line_buffering=True)", ''))
WS = r'D:\000rebornWOW\000RebornWOWHighForkPRO'
P = J(WS, '000Ascendupdate', '000Ascendupdate20261127', u'claudefix_20261127_阶段WMOSPLIT2_V1_高版本建筑拆分分块修复_四座建筑累计_Claude')
assert not os.path.exists(P)
ROOTS = [4235933, 4530996, 4320278, 6224922]
V1 = J(WS, '000Ascendupdate', '000Ascendupdate20261127', u'claudefix_20261127_阶段WMOSPLIT1_V1_禁忌离岛大洞_只给拆分分块加室外标记_测试_Claude',
       u'01_覆盖到客户端根目录', 'Data', 'Retail', 'TwoFormsTables')
CTF = J(CLIENT, 'Data', 'Retail', 'TwoFormsTables')
parts = lambda b: {t: d for t, d in chunks(b)}
mogp = lambda g: parts(raw(g))[b'PGOM']


def info(root):
    c = parts(raw(root))
    n = struct.unpack_from('<I', c[b'DHOM'], 4)[0]
    g = u32s(c[b'DIFG'])[:n]
    split = [i for i, f in enumerate(g) if struct.unpack_from('<I', mogp(f), 60)[0] & 0xC0 and struct.unpack_from('<I', mogp(f), 8)[0] & 0x2000]
    return n, g, split


def patch(b, split, is_root):
    b = bytearray(b)
    o, done = 0, 0
    while o + 8 <= len(b):
        n = struct.unpack_from('<I', b, o + 4)[0]
        if is_root and b[o:o + 4] == b'IGOM':
            for i in split:
                at = o + 8 + i * 32
                struct.pack_into('<I', b, at, struct.unpack_from('<I', b, at)[0] | 0x8)
                done += 1
        elif not is_root and b[o:o + 4] == b'PGOM':
            at = o + 16
            struct.pack_into('<I', b, at, struct.unpack_from('<I', b, at)[0] | 0x8)
            done += 1
        o += 8 + n
    assert done == (len(split) if is_root else 1)
    return bytes(b)


TFT = J(P, u'01_覆盖到客户端根目录', 'Data', 'Retail', 'TwoFormsTables')
os.makedirs(TFT)
od = J(W, 'wmosplit2', 'overlay')
os.makedirs(od, exist_ok=True)
allfiles, new, data_of = [], [], {}
for root in ROOTS:
    n, g, split = info(root)
    assert split, root
    for f in [root] + [g[i] for i in split]:
        data = patch(raw(f), split, f == root)
        old = J(V1, '%d.bin' % f)
        if os.path.exists(old):
            assert open(old, 'rb').read() == data
        have = J(CTF, '%d.bin' % f)
        if os.path.exists(have):
            assert open(have, 'rb').read() == data, 'client already has a different file %d' % f
        else:
            new.append(f)
        open(J(TFT, '%d.bin' % f), 'wb').write(data)
        open(J(od, '%d.bin' % f), 'wb').write(data)
        allfiles.append(f)
    print('building', root, 'groups', n, 'split', split)
print('files', len(allfiles), 'not yet in the client', len(new))
assert len(allfiles) == len(set(allfiles)) == 28

for root in ROOTS:
    n, g, split = info(root)
    names = ['retail/%d.wmo' % root] + ['retail/%d_%03d.wmo' % (root, i) for i in range(n) if g[i]]
    res = {}
    for tag in ('orig', 'split'):
        ini = J(STAGE, 'Data', 'Retail', 'wmosplit2_%s.ini' % tag)
        text = 'mode=local\npath=D:/_zsdc/slim/no_such_folder\nproduct=wow\nregion=us\nbuild=%s\nlocale=2\n' % BUILD
        if tag == 'split':
            text += 'overlay=%s\n' % od.replace('\\', '/')
        open(ini, 'w', newline='\n').write(text)
        d = J(W, 'wmosplit2', '%d_%s' % (root, tag))
        os.makedirs(d, exist_ok=True)
        lst = J(W, 'wmosplit2', 'list.txt')
        open(lst, 'w', newline='\n').write(''.join(x + '\n' for x in names))
        r = subprocess.run([PROBE, ini, '--batch', lst], capture_output=True, cwd=W, env=dict(os.environ, PROBE_DUMP=d), timeout=500)
        out = r.stdout.decode('utf-8', 'replace')
        assert sum(l.startswith('ok ') for l in out.splitlines()) == len(names), out
        res[tag] = [open(J(d, x.replace('/', '_')), 'rb').read() for x in names]
    a, c = parts(res['orig'][0]), parts(res['split'][0])
    assert all(a[k] == c[k] for k in a if k != b'IGOM')
    for k, i in enumerate([i for i in range(n) if g[i]]):
        x, y = parts(res['orig'][k + 1])[b'PGOM'], parts(res['split'][k + 1])[b'PGOM']
        fx, fy = struct.unpack_from('<I', x, 8)[0], struct.unpack_from('<I', y, 8)[0]
        assert fy == (fx | 8 if i in split else fx) and x[:8] == y[:8] and x[12:] == y[12:]
        assert struct.unpack_from('<I', c[b'IGOM'], i * 32)[0] == struct.unpack_from('<I', a[b'IGOM'], i * 32)[0] | (8 if i in split else 0)
    print('building', root, 'client-ready data differs only in the split-group bits')

# where do the buildings stand? a floor point inside a split group, in world coordinates
MAPS = {}
for line in open(J(CLIENT, 'Data', 'Retail', 'aliases_maps.csv'), encoding='utf-8-sig'):
    if '.wdt' in line.lower():
        f, p = line.strip().split(';', 1)
        MAPS[int(f)] = p
IDS = {'test': 13, 'ExilesReach': 12175, 'ForbiddenReach': 12570, 'Harandar': 12694}
HALF = 32 * 1600.0 / 3
places = {}
for wdt, p in MAPS.items():
    mapid = IDS[p.replace('\\', '/').split('/')[-1][:-4]]
    maid = parts(raw(wdt))[b'DIAM']
    for t in range(4096):
        obj = struct.unpack_from('<I', maid, t * 32 + 4)[0]
        if not obj or raw(obj) is None:
            continue
        for tag, d in chunks(raw(obj)):
            if tag == b'FDOM':
                for i in range(len(d) // 64):
                    fid = struct.unpack_from('<I', d, i * 64)[0]
                    if fid in ROOTS:
                        uid = struct.unpack_from('<I', d, i * 64 + 4)[0]
                        pos = struct.unpack_from('<3f', d, i * 64 + 8)
                        rot = struct.unpack_from('<3f', d, i * 64 + 20)
                        places[(fid, uid)] = (mapid, (HALF - pos[2], HALF - pos[0], pos[1]), rot[1])
coords = {}
for (fid, uid), (mapid, wpos, yaw) in sorted(places.items()):
    n, g, split = info(fid)
    best = None
    for i in split:
        m = mogp(g[i])
        sub = {}
        for t, d in chunks(m, 68):
            sub.setdefault(t[::-1].decode(), d)
        V = [struct.unpack_from('<3f', sub['MOVT'], k * 12) for k in range(len(sub['MOVT']) // 12)]
        I = struct.unpack('<%dH' % (len(sub['MOVI']) // 2), sub['MOVI'])
        ba = sub['MOBA']
        floors = []
        for b in range(len(ba) // 24):
            s = struct.unpack_from('<I', ba, b * 24 + 12)[0]
            cnt = struct.unpack_from('<H', ba, b * 24 + 16)[0]
            for t in range(s, s + cnt, 3):
                a_, b_, c_ = V[I[t]], V[I[t + 1]], V[I[t + 2]]
                u = [b_[k] - a_[k] for k in range(3)]
                v = [c_[k] - a_[k] for k in range(3)]
                nz = u[0] * v[1] - u[1] * v[0]
                L = math.sqrt((u[1] * v[2] - u[2] * v[1]) ** 2 + (u[2] * v[0] - u[0] * v[2]) ** 2 + nz * nz)
                if L > 6 and nz / L > 0.97:
                    floors.append((L, [(a_[k] + b_[k] + c_[k]) / 3 for k in range(3)]))
        if floors and (best is None or len(floors) > best[0]):
            mid = [sorted(f[1][k] for f in floors)[len(floors) // 2] for k in range(3)]
            pt = min(floors, key=lambda f: sum((f[1][k] - mid[k]) ** 2 for k in range(3)))[1]
            best = (len(floors), i, pt)
    if best:
        a = math.radians(yaw + 180)
        x, y, z = best[2]
        wx = wpos[0] + math.cos(a) * x - math.sin(a) * y
        wy = wpos[1] + math.sin(a) * x + math.cos(a) * y
        coords.setdefault(fid, []).append((mapid, round(wx), round(wy), round(wpos[2] + z + 2), best[1]))
for f in ROOTS:
    print('building', f, 'placed', len(coords.get(f, [])), coords.get(f, [])[:4])
pickle.dump(coords, open(J(W, 'wmosplit2', 'coords.pkl'), 'wb'))

rows = []
names_ = {13: u'测试地图', 12175: u'流放者离岛', 12570: u'禁忌离岛', 12694: u'哈籁尼尔'}
for f in ROOTS[1:]:
    for m, x, y, z, i in coords.get(f, [])[:3]:
        rows.append(u'|%d|%s|`.go xyz %d %d %d %d`|' % (f, names_[m], x, y, z, m))
table = u'\n'.join(rows) if rows else u'|(未在地图摆放数据里找到)|||'


def wr(rel, text):
    path = J(P, *rel.split('/'))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, 'wb').write(text.replace('\n', '\r\n').encode('utf-8'))


wr('README_覆盖与测试说明.md', u"""# WMOSPLIT2 V1：高版本建筑拆分分块修复(四座累计)

状态：大洞 4235933 部分与已通过的 WMOSPLIT1 逐字节相同(用户实测：都正常)；另外 3 座**候选，实机未测**。

## 内容
`Data\\Retail\\TwoFormsTables` 下 %(n)d 个文件(其中客户端里还没有的 %(new)d 个)。只给“拆分分块”加室外标记，其余数据不动。已移植的 525 座建筑里只有这 4 座需要。

## 安装
1. 关闭游戏。
2. 把 `01_覆盖到客户端根目录` 里的 `Data` 复制到客户端根目录。
3. `Data\\Retail\\RetailCasc.ini` 保持 `;wmoindoor=both`(带分号)。
4. 启动游戏。

## 测试(新增的 3 座)
先 `.gm fly on`。传送点是按建筑数据算出的分块地面，没实机走过。

|建筑|地图|传送|
|---|---|---|
%(table)s

看地面、墙是否完整，进出时远处有没有看穿或闪烁。

## 拷给朋友
整个客户端拷过去就带着这些文件和配置。

## 撤销
1. 关闭游戏。
2. 删除 `04_撤销\\文件清单.txt` 里列出的文件(连同 WMOSPLIT1 的大洞部分)。
3. 用 `Data\\Retail\\RetailCasc.原版.ini` 覆盖 `RetailCasc.ini`。

本包含游戏原版素材，不提交仓库。
""" % {'n': len(allfiles), 'new': len(new), 'table': table})
wr(u'04_撤销/文件清单.txt', ''.join('%d.bin\n' % f for f in allfiles))
wr(u'memory.md', u"""# WMOSPLIT2 V1 记录(2026-11-27，Claude)
- 大洞部分用户实测通过("都正常的了")；另 3 座(4530996/4320278/6224922)未实测。
- 规则：MOGP flags2 0x40/0x80 且室内(0x2000)的分块置 0x8；ini 不写 wmoindoor。
- 离线核对：客户端数据只差这些标志位。
""")
wr(u'tutor.md', u"""# 零售建筑远处看穿 / 室内空缺
- 现象对应：整座标室外 -> 地下洞穴远处物件和分块消失；原始方式 -> 分裂分块缺失。
- 处理：只给分裂分块加室外位，用 overlay 单文件交付，不必重编程序。
- 新移植地图后扫描建筑是否有室内分裂分块(split_scan)，有就一起生成 overlay。
""")
os.makedirs(J(P, 'scripts'))
shutil.copyfile(J(W, 'build_wmosplit2.py'), J(P, 'scripts', 'build_wmosplit2.py'))
shutil.copyfile(J(W, 'split_scan.py'), J(P, 'scripts', 'split_scan.py'))
sums = []
for rt, _, nm in os.walk(P):
    for x in nm:
        s = J(rt, x)
        sums.append('%s  %s\n' % (hashlib.sha256(open(s, 'rb').read()).hexdigest(), os.path.relpath(s, P).replace('\\', '/')))
open(J(P, 'SHA256SUMS.txt'), 'wb').write(''.join(sorted(sums, key=lambda t: t[66:])).encode('utf-8'))


def append(path, text):
    old = open(path, 'rb').read()
    nl = b'\r\n' if b'\r\n' in old else b'\n'
    add = (b'' if old.endswith(b'\n') else nl) + nl + text.encode('utf-8') + nl
    open(path, 'ab').write(add)
    assert open(path, 'rb').read() == old + add


append(J(WS, u'开关文件清单_会改变行为的文件和设置.md'), u'- WMOSPLIT1 状态更新(2026-11-27)：用户确认“都正常的了”，13 个 overlay 与 `;wmoindoor=both` 长期保留。\n- WMOSPLIT2 V1(2026-11-27，Claude，登记于用户操作前)：客户端 Data\\Retail\\TwoFormsTables 再增 %d 个 .bin(%s)；RetailCasc.ini 保持 wmoindoor 注释。撤销：1 关闭客户端；2 删除包内 04_撤销\\文件清单.txt 所列 28 个文件；3 用 RetailCasc.原版.ini 覆盖 RetailCasc.ini；4 让助手 ls 核对。状态：待用户安装。' % (len(new), u' '.join(u'%d.bin' % f for f in new)))
append(J(WS, u'协作说明_并行开发.md'), u'| 2026-11-27 | Claude | WMOSPLIT2 V1：四座高版本建筑拆分分块 overlay | 候选(大洞部分用户已测通过；另 3 座未测) | 客户端 TwoFormsTables 累计 28 个 overlay(与龙希尔表同目录，文件名不重叠)；RetailCasc.ini 不用 wmoindoor | WMOSPLIT1 V1(用户确认) | 000Ascendupdate20261127/claudefix_…WMOSPLIT2_V1… | Codex 改 RetailCasc.ini 时请保持 wmoindoor 注释；含原版素材不提交 |')
SK = J(WS, 'beascendskills', 'port-retail-zone-end-to-end', 'SKILL.md')
s = open(SK, 'rb').read()
mark = u'| 做完整条线才几级 |'.encode('utf-8')
assert s.count(mark) == 1
snl = b'\r\n' if b'\r\n' in s else b'\n'
add = u'| 洞穴/建筑远处看穿、坠饰碎石走近才出现；或室内大片空缺 | wmoindoor=both/outdoor 让地下建筑按野外处理；原始方式又画不出拆分分块 | 不写 wmoindoor，只给室内拆分分块(MOGP flags2 0x40/0x80)加 0x8，用 overlay 交付(已移植建筑中 4 座，大洞用户实测通过) |'.encode('utf-8') + snl
open(SK, 'wb').write(s.replace(mark, add + mark))
MD = u'<user-profile>/.claude/projects/d--000rebornWOW-000RebornWOWHighForkPRO-beascendLauncher-wowlauncher2026-CataLauncher-rebornWOW/memory/'
with open(MD + u'map12j-wmo-portal-cull-fixed.md', 'ab') as f:
    f.write(u'\n2026-11-27: user confirmed all normal for the cave; this SUPERSEDES wmoindoor=both (keep it commented). WMOSPLIT2 V1 delivered for all four buildings (other three untested). Re-run split_scan.py after porting new maps.\n'.encode('utf-8'))
print(P)
