# -*- coding: utf-8 -*-
"""Server package: ground heights, building collision, pathfinding, map rows, graveyards and .tele names for both maps."""
import struct, io, os, sys, glob, shutil, hashlib, math
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', line_buffering=True)
exec(open(r'D:\_zsdc\maps2\verify.py', encoding='utf-8').read().split('# retail creature positions')[0].replace("sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')\n", ''))
WS = r'D:\000rebornWOW\000RebornWOWHighForkPRO'
SRV = J(WS, 'beascendserver', 'wowshub_playerbot_npcbot_newrace20261122Ascend', 'Data')
DAY = J(WS, '000Ascendupdate', '000Ascendupdate20261126')
P = J(DAY, u'claudefix_20261126_阶段MAPSRV2A_V1_禁忌离岛与哈籁尼尔服务端地图高度建筑碰撞寻路_Claude')
assert not os.path.exists(P), P
sha = lambda p: hashlib.sha256(open(p, 'rb').read()).hexdigest()
base = dict(l.split() for l in open(J(W, 'base_hashes.txt')).read().split('\n') if l)
for n, h in base.items():
    assert sha(J(SRV, 'dbc', n)) == h, 'server %s changed since the build' % n
root = J(P, u'01_覆盖到服务端根目录', 'Data')
counts = {}
for sub, sdir in (('maps', J(W, 'ext', 'maps')), ('vmaps', r'D:\_vm\n2\run\vmaps'), ('mmaps', r'D:\_vm\n2\mm\mmaps')):
    os.makedirs(J(root, sub))
    have = set(os.listdir(J(SRV, sub)))
    n = 0
    for f in os.listdir(sdir):
        if f not in have:                       # existing files (shared models, GameObjectModels.dtree) stay as they are
            shutil.copy2(J(sdir, f), J(root, sub, f))
            n += 1
        else:
            assert f == 'GameObjectModels.dtree' or open(J(sdir, f), 'rb').read() == open(J(SRV, sub, f), 'rb').read(), f
    counts[sub] = n
assert not os.path.exists(J(root, 'vmaps', 'GameObjectModels.dtree'))
os.makedirs(J(root, 'dbc'))
os.makedirs(J(P, u'03_撤销', u'原服务端dbc'))
for n in base:
    shutil.copy2(J(W, 'out_dbc', n), J(root, 'dbc', n))
    shutil.copy2(J(SRV, 'dbc', n), J(P, u'03_撤销', u'原服务端dbc', n))

spots = {12570: (u'Forbidden Reach 禁忌离岛', 6517.0, -3317.0, 'Dracthyr'), 12694: (u'Harandar 哈籁尼尔出生地', 1252.0, 908.0, 'Haranir')}
gy = {12570: 125701, 12694: 126941}
sql = [u'''-- MAPSRV2A V1 (2026-11-26, Claude) - candidate, NOT user-tested. Stop worldserver, run on the WORLD database, restart. Safe to run twice.
-- One graveyard + Spirit Healer (both factions) near the start of each new map, and the .tele names Dracthyr / Haranir.
SET NAMES utf8mb4;
SET @spawn_limit := 16777215;
DELETE FROM `creature` WHERE `Comment` LIKE 'MAPSRV2A %';
DELETE FROM `graveyard_zone` WHERE `ID` IN (125701, 126941);
DELETE FROM `game_graveyard` WHERE `ID` IN (125701, 126941);
DELETE FROM `game_tele` WHERE `name` IN ('Dracthyr', 'Haranir');
SELECT COALESCE(MAX(`guid`), 0) INTO @g FROM `creature` WHERE `guid` < @spawn_limit;
SELECT IF(@g + 5 + 10000 < @spawn_limit, 'guid base OK', 'ABORT: no guid room, do not continue') AS guid_check, @g AS creature_max;
SELECT COALESCE(MAX(`id`), 0) INTO @t FROM `game_tele`;''']
tele = {}
for k, (mid, (name, X, Y, tn)) in enumerate(sorted(spots.items()), 1):
    z = round(height(mid, X, Y) + 0.3, 2)
    hx, hy = X + 4.0, Y + 2.0
    hz = round(height(mid, hx, hy) + 0.3, 2)
    if mid == 12694:
        tele[mid] = (1263.35, 922.787, 1332.45, 1.356)
    else:
        tele[mid] = (X, Y, round(height(mid, X, Y) + 3, 2), 0.0)
    sql.append(u'''-- %(name)s
INSERT INTO `game_graveyard` (`ID`, `Map`, `x`, `y`, `z`, `Comment`) VALUES (%(g)d, %(m)d, %(x)s, %(y)s, %(z)s, '%(c)s start (MAPSRV2A)');
INSERT INTO `graveyard_zone` (`ID`, `GhostZone`, `Faction`, `Comment`) VALUES (%(g)d, %(m)d, 0, '%(c)s start, both factions (MAPSRV2A)');
INSERT INTO `creature` (`guid`, `id1`, `map`, `spawnMask`, `phaseMask`, `equipment_id`, `position_x`, `position_y`, `position_z`, `orientation`, `spawntimesecs`, `wander_distance`, `MovementType`, `Comment`) VALUES
(@g + %(k)d, 6491, %(m)d, 1, 3, 0, %(hx)s, %(hy)s, %(hz)s, 3.6, 300, 0, 0, 'MAPSRV2A spirit healer %(tn)s');
INSERT INTO `game_tele` (`id`, `position_x`, `position_y`, `position_z`, `orientation`, `map`, `name`) VALUES (@t + %(k)d, %(tx)s, %(ty)s, %(tz)s, %(to)s, %(m)d, '%(tn)s');''' % dict(
        name=name, g=gy[mid], m=mid, x=X, y=Y, z=z, c=tn, k=k, hx=hx, hy=hy, hz=hz, tn=tn, tx=tele[mid][0], ty=tele[mid][1], tz=tele[mid][2], to=tele[mid][3]))
    print(name, 'graveyard', (X, Y, z), 'healer', (hx, hy, hz), 'tele', tele[mid])
sql.append(u'''SELECT (SELECT COUNT(*) FROM `game_graveyard` WHERE `ID` IN (125701, 126941)) AS graveyards_must_be_2,
       (SELECT COUNT(*) FROM `graveyard_zone` WHERE `ID` IN (125701, 126941)) AS zone_rows_must_be_2,
       (SELECT COUNT(*) FROM `creature` WHERE `Comment` LIKE 'MAPSRV2A %') AS healers_must_be_2,
       (SELECT COUNT(*) FROM `game_tele` WHERE `name` IN ('Dracthyr', 'Haranir')) AS tele_names_must_be_2;''')
undo = '''-- MAPSRV2A V1 undo (world database).
DELETE FROM `creature` WHERE `Comment` LIKE 'MAPSRV2A %';
DELETE FROM `graveyard_zone` WHERE `ID` IN (125701, 126941);
DELETE FROM `game_graveyard` WHERE `ID` IN (125701, 126941);
DELETE FROM `game_tele` WHERE `name` IN ('Dracthyr', 'Haranir');'''


def put(rel, text, enc='utf-8'):
    p = J(P, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    open(p, 'w', encoding=enc, newline='\r\n').write(text.strip('\n') + '\n')


put(J(u'02_服务端_SQL', 'world_mapsrv2a.sql'), '\n'.join(sql))
put(J(u'03_撤销', 'undo.sql'), undo)
rows_ = '\n'.join('| %s | `%s` | `%s` |' % (n, base[n][:12], sha(J(root, 'dbc', n))[:12]) for n in base)
put('README_覆盖与测试说明.md', u'''
# MAPSRV2A V1：禁忌离岛(12570)与哈籁尼尔出生地(12694)的服务端地图数据（候选，实机未测）

两张图的全部地块都做了：地面高度、建筑碰撞(vmaps)、寻路(mmaps)，另加地图记录、复活点和传送名。

| 地图 | 地块 / 高度文件 | vmaps 地图文件 | mmaps 文件 |
|---|---|---|---|
| 禁忌离岛 12570 | 131 / 131 | 45 | 53 |
| 哈籁尼尔 12694 | 323 / 323 | 307 | 225 |

建筑 330 栋(418 个分组)、模型 2458 个从本机零售数据转换，转换失败 0。寻路文件比地块少是因为没有可走地面的地块(水面、空地)不生成。

本包新增文件：maps %(m)d、vmaps %(v)d、mmaps %(mm)d。和现有文件重名的一律没放进来(共享模型内容相同；`GameObjectModels.dtree` 不能覆盖)。

## 离线核对（不是游戏实测）
- 哈籁尼尔零售出生高度 1332.45，生成的地面在它下面 1.47 码。
- 出生点 150 码内 264 个零售生物点：186 个与地面相差 2 码内，其余在建筑上或空中。
- 禁忌离岛阅兵场地面 162.96，与之前客户端地形读数 163 一致。

## 部署（你操作）
1. **停服**。
2. 备份服务端 `Data\\dbc` 里的 Map.dbc、LiquidType.dbc、AreaTable.dbc(包内 `03_撤销` 也有一份原件)。核对三个文件的 SHA256 开头等于下表"输入"；不相等说明之后被改过，先告诉我。
3. 把 `01_覆盖到服务端根目录\\Data` 合并复制到服务端 `Data`(新增文件 + 覆盖 3 个 dbc)。`dbc\\zhCN` 子目录不用动。
4. world 库执行 `02_服务端_SQL\\world_mapsrv2a.sql`，读回四个值都是 2。
5. 启动。

| 文件 | 输入 | 输出 |
|---|---|---|
%(rows)s

AreaTable 顺带把流放者之岛 12175 行的探索编号改到合法范围：之前服务端日志里反复出现的 `Wrong area flag … must be < 128` 应当消失。

## 测试
GM 先开 `.cheat god`。
| 命令 | 应看到 |
|---|---|
| `.tele Haranir` | 哈籁尼尔出生点(客户端地图要装 HARA1C 之后才看得见) |
| `.tele Dracthyr` | 禁忌离岛阅兵场(客户端已装过 MAP12G，现在就能看) |
| `.gps` | 地面高度有数值，不是 -200000 |
| `.npc add 4949` 后 `.npc delete` | NPC 站在地面上不下沉 |
| 对着远处怪或 NPC `.mmap path` | 有路径 |
| `.die` 后释放灵魂 | 出现在出生点旁的灵魂医者处 |
| 走几步看服务端日志 | 不刷 area flag 报错 |

禁忌离岛现在不用 `.gm fly on` 也应能站住。

## 撤销
停服；把 `03_撤销\\原服务端dbc` 三个文件放回 `Data\\dbc`；删除 `Data` 下 maps、vmaps、mmaps 里文件名以 12570 或 12694 开头的文件；world 库执行 `03_撤销\\undo.sql`；启动。

## 未测与边界
- 全部未实机测试。个别建筑碰撞或寻路可能有洞或卡点，遇到请给 `.gps`。
- 新水体编号 941、1177、1055、1132、1222、1255 按普通水处理，哪处应当是别的水体需要实地看。
- 区域只用地图编号一个区域名；没有天气、没有 NPC、没有任务。
''' % dict(m=counts['maps'], v=counts['vmaps'], mm=counts['mmaps'], rows=rows_), 'utf-8-sig')
put('memory.md', u'''# MAPSRV2A V1 记录(2026-11-26，Claude)
用户："按照提取流放岛的地图和生成mmap vmap maps的skills来 把龙希尔的地图和现在再移植的地图一起把这些地图先整完整"。
流程与脚本在 D:\\_zsdc\\maps2(prep/convert/inventory/srvmaps/vm/verify/pack_srv)；经验：RetailAssetProbe 批量名用正斜杠才写出文件，地块批次第一行放 WDT；转换出的地块区域号为 0，需写入自定区域号；服务端 AreaBit 必须 < 4096。
状态：候选，未实测。''', 'utf-8-sig')
put('tutor.md', u'''# 大白话：给两座新岛打地基
客户端看得见地图不等于服务器知道哪里是地。高度图告诉它地面在哪，建筑碰撞告诉它墙和楼板在哪，寻路图告诉怪物怎么走。三样缺一，怪就沉、穿墙或呆住。''', 'utf-8-sig')
os.makedirs(J(P, 'scripts'))
for f in ('prep.py', 'convert.py', 'inventory.py', 'srvmaps.py', 'vm.py', 'verify.py', 'pack_srv.py'):
    shutil.copy2(J(W, f), J(P, 'scripts', f))
out = []
for dp, _d, fn in os.walk(P):
    for f in fn:
        if f != 'SHA256SUMS.txt':
            out.append('%s  %s' % (sha(J(dp, f)), os.path.relpath(J(dp, f), P).replace(os.sep, '/')))
open(J(P, 'SHA256SUMS.txt'), 'w', encoding='utf-8', newline='\n').write('\n'.join(sorted(out, key=lambda s: s[66:])) + '\n')
print('package files', len(out) + 1, counts, 'MB', round(sum(os.path.getsize(J(dp, f)) for dp, _d, fn in os.walk(P) for f in fn) / 1048576))
print(P)
