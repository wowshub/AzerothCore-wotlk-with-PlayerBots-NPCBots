# -*- coding: utf-8 -*-
"""Read the built tables back, write README / records / checksums of HARA1C and register the work."""
import io, sys, os, hashlib, pickle, shutil, glob
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', line_buffering=True)
exec(open(r'D:\_zsdc\maps2\pack_cli.py', encoding='utf-8').read().split("if __name__")[0].replace("sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', line_buffering=True)", ''))
d1 = J(P, u'01_导入Patch-X.mpq', 'DBFilesClient')


def load(n):
    T['found'][n] = [('Patch-X.mpq', open(J(d1, n), 'rb').read())]
    return Dbc(n)


mp, at, wma, ls = load('Map.dbc'), load('AreaTable.dbc'), load('WorldMapArea.dbc'), load('LoadingScreens.dbc')
r = mp.get(12694)
print('map', mp.text(r[1]), mp.text(r[5]), 'area', r[22], 'loading', r[57], 'exp', r[63])
for k in (15355, 16584, 15928, 12694, 12570):
    a = at.get(k)
    print('area', k, 'map', a[1], 'parent', a[2], 'bit', a[3], at.text(a[11]))
for x in wma.recs:
    if x[1] == 12694:
        z = [bf(v) for v in x[4:8]]
        print('wma', x[0], x[2], wma.text(x[3]), [round(v, 1) for v in z], 'spawn on map at %.2f %.2f' % ((z[0] - 922.8) / (z[0] - z[1]), (z[2] - 1263.35) / (z[2] - z[3])))
print('loading', [ls.text(i) for i in ls.get(9404)[1:3]], 'file there', os.path.exists(J(P, u'02_导入Patch-ZC.mpq', 'Interface', 'Glues', 'LoadingScreens', 'LoadScreenHarandar.blp')))
H = pickle.load(open(J(W, 'cli_hashes.pkl'), 'rb'))
rows_ = '\n'.join(u'| %s | `%s` | `%s` |' % (h[0], h[1][:12], h[2][:12]) for h in H)


def put(rel, text):
    open(J(P, rel), 'w', encoding='utf-8-sig', newline='\r\n').write(text.strip('\n') + '\n')


put('README_覆盖与测试说明.md', u'''
# HARA1C V1：哈籁尼尔地图客户端 + 两张图的小地图（候选，实机未测）

配合服务端包 MAPSRV2A V1。适用试装客户端 `C:\\000ref\\WarcraftXL试装_client`。

## 内容
- 新地图 12694「哈籁尼尔出生地」：地图记录、34 个区域名(零售中文名)、世界地图(零售原图)、加载图(零售原图)、大陆下拉项。
- 4 种新水体编号补行(防止靠近建筑里的水时崩溃)。
- 小地图：禁忌离岛 131 块、哈籁尼尔 323 块(零售原版小地图缩到 256 像素)。
- `aliases_maps.csv` 加一行，让客户端从本机零售数据读哈籁尼尔地形。禁忌离岛的客户端部分此前 MAP12G 已装过。

## 安装(你操作，先关游戏和 MPQ 编辑器)
1. 备份 `Data\\Patch-X.mpq`、`Data\\Patch-ZC.mpq`、`Data\\Retail\\aliases_maps.csv`。
2. 核对 Patch-X 里这 6 个 dbc 和 ZC 里的 md5translate.trs 的 SHA256 开头等于下表"输入"；不相等说明之后有人改过，不要导入，告诉我。
3. 把 `01_导入Patch-X.mpq` 里的 `DBFilesClient` 导入 Patch-X(替换 6 个同名文件)。
4. 把 `02_导入Patch-ZC.mpq` 里的 `Interface` 和 `textures` 两个文件夹导入 Patch-ZC(保持目录结构)。其中 textures\\Minimap 有 454 个新图和 1 个替换的 md5translate.trs；MPQ 编辑器如提示文件数量上限，先在编辑器里扩大上限再导入。
5. 用 `03_覆盖到客户端根目录` 覆盖客户端根目录(只有 aliases_maps.csv)。
6. 保存并完全关闭编辑器；删客户端 `Cache` 里的 `WDB`；冷启动。

| 文件 | 输入 | 输出 |
|---|---|---|
%(rows)s

## 怎么测
先装好服务端包。GM 先开 `.cheat god`。
| 步骤 | 应看到 |
|---|---|
| `.tele Haranir` | 哈籁尼尔加载图 → 进图，地面、蘑菇树、建筑可见；左上角有地名 |
| 右上小地图 | 有地形图像，不是黑的；走动时跟着变 |
| 按 M | 哈籁恩达尔世界地图，箭头大约在左上部(横 35%%、纵 25%%) |
| 走到水边、建筑里的水边 | 不崩溃 |
| 洞穴和大建筑里转视角 | 地面不时有时无 |
| `.tele Dracthyr` | 禁忌离岛小地图也有图像 |

重点告诉我：能不能进图、小地图对不对位置、世界地图箭头准不准、哪里崩溃或看不见。

## 撤销
关游戏，把 `04_撤销` 里的原件按原位置放回(Patch-X 的 6 个 dbc、ZC 的 md5translate.trs、aliases_maps.csv)，保存关闭编辑器。ZC 里新增的图片留着不影响。

## 未做与边界
- 全部未实机测试。
- 天空和光照、音乐没有移植；天空可能是默认的。
- 天气、迷雾探索效果没有做；子区域没有单独的世界地图。
- 流放者之岛的小地图不在本包(需要的话可照同样方法做)。
- 本包 dbc 是整表(以现在生效的 Patch-X 为底只加行)。其他成员之后改这些表要以装好后的版本为底。
''' % dict(rows=rows_))
put('memory.md', u'''# HARA1C V1 记录(2026-11-26，Claude)
基底 Patch-X(6 表)与 Patch-ZC md5translate.trs(现场生效版)。地图 12694/区域 15355 等/WMA 20418-20419/大陆行 19/加载图 9404/液体 1055,1132,1222,1255。
经验：StormLib 调用必须声明 restype=c_bool，否则失败也返回真值、扫描极慢且读到空数据；打开 MPQ 加 NO_LISTFILE|NO_ATTRIBUTES，整套扫描不到 1 秒。UiMapAssignment 2694 的 Region 0/3 是世界 X(用地图宽高比 3:2 判定)。
状态：候选，未实测。脚本 D:\\_zsdc\\maps2。''')
put('tutor.md', u'''# 大白话：客户端要的是"户口"和"画"
地图记录和区域名是户口，世界地图、小地图、加载图是画。地形本身客户端直接从本机的零售数据读，只要在清单里写上它叫什么。''')
os.makedirs(J(P, 'scripts'))
for f in ('clientdbc.py', 'retailinfo.py', 'art.py', 'pack_cli.py', 'cli_readme.py'):
    shutil.copy2(J(W, f), J(P, 'scripts', f))
out = []
for dp, _d, fn in os.walk(P):
    for f in fn:
        if f != 'SHA256SUMS.txt':
            out.append('%s  %s' % (hashlib.sha256(open(J(dp, f), 'rb').read()).hexdigest(), os.path.relpath(J(dp, f), P).replace(os.sep, '/')))
open(J(P, 'SHA256SUMS.txt'), 'w', encoding='utf-8', newline='\n').write('\n'.join(sorted(out, key=lambda s: s[66:])) + '\n')
print('files', len(out) + 1, 'MB', round(sum(os.path.getsize(J(dp, f)) for dp, _d, fn in os.walk(P) for f in fn) / 1048576))


def app(path, text, key):
    t = open(path, 'rb').read()
    assert t.strip() and key.encode('utf-8') not in t, path
    e = '\r\n' if b'\r\n' in t else '\n'
    open(path, 'ab').write((('' if t.endswith(b'\n') else e) + e + text.replace('\n', e) + e).encode('utf-8'))


app(J(WS, u'协作说明_并行开发.md'), u'| 2026-11-26 | Claude | HARA1C V1：哈籁尼尔地图客户端与两图小地图 | 候选(实机未测) | 试装客户端 Patch-X 的 Map/AreaTable/WorldMapArea/LoadingScreens/LiquidType/WorldMapContinent；Patch-ZC 的 textures/Minimap(含 md5translate.trs)、Interface；aliases_maps.csv | 现场生效版只加行 | 000Ascendupdate20261126/claudefix_…HARA1C… | 用户安装后他人改这些表请以新版为底 |', 'HARA1C V1：')
app(J(WS, u'台账_YB_XA共享文件哈希.md'), u'## 2026-11-26 HARA1C V1(Claude，待用户安装) 试装客户端 Patch-X / Patch-ZC\n| 文件 | 输入 | 输出 |\n|---|---|---|\n' + '\n'.join(u'|%s|%s|%s|' % (h[0], h[1], h[2]) for h in H), 'HARA1C V1(Claude')
M = r'<user-profile>\.claude\projects\d--000rebornWOW-000RebornWOWHighForkPRO-beascendLauncher-wowlauncher2026-CataLauncher-rebornWOW\memory\haranir-start-port.md'
s = open(M, encoding='utf-8').read()
assert s.strip()
open(M, 'w', encoding='utf-8').write(s + u'\n11-26 08:xx: HARA1C V1 client package delivered (untested) together with MAPSRV2A. Next: user tests both; then quests (design draft awaiting confirmation). StormLib ctypes needs restype=c_bool and flags 0x30100 (scan <1s).\n')
print('records ok')
