# -*- coding: utf-8 -*-
"""SLIM1A V1 package: the verified decoded cache (hard-linked from the staging folder, same volume)."""
import io, os, sys, hashlib, pickle, shutil

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
J = os.path.join
W = r'D:\_zsdc\slim'
WS = r'D:\000rebornWOW\000RebornWOWHighForkPRO'
CLIENT = u'C:\\000ref\\WarcraftXL试装_client'
BUILD = 'c9fa1a64b0170829cc5c5c98c71025c3'
REL = J('Data', 'Retail', 'CdnCache', 'wow-' + BUILD)
P = J(WS, '000Ascendupdate', '000Ascendupdate20261127', u'claudefix_20261127_阶段SLIM1A_V1_高版本素材瘦身包_拷客户端不用wow12_Claude')
assert not os.path.exists(P)
SRC = J(W, 'stage', REL)
C = pickle.load(open(J(W, 'closure.pkl'), 'rb'))
assert not C['missing'] and pickle.load(open(J(W, 'verify_missing.pkl'), 'rb')) == {}
user = pickle.load(open(J(W, 'user_files.pkl'), 'rb'))

files, size = [], 0
for root, _, names in os.walk(SRC):
    for n in names:
        if n.endswith('.tmp'):
            continue
        s = J(root, n)
        rel = os.path.relpath(s, SRC)
        d = J(P, u'01_覆盖到客户端根目录', REL, rel)
        os.makedirs(os.path.dirname(d), exist_ok=True)
        os.link(s, d)
        files.append(rel)
        size += os.path.getsize(s)
new = sorted(set(files) - user)
have = {int(os.path.basename(f)[3:-4]) for f in files if f.replace('\\', '/').startswith('2/strict/id-')}
assert set(C['seen']) <= have
print('files', len(files), 'new', len(new), 'GB %.2f' % (size / 2 ** 30))

ini = open(J(CLIENT, 'Data', 'Retail', 'RetailCasc.ini'), 'rb').read()
old = b'path=D:/wow12/World of Warcraft69587'
assert ini.count(old) == 1
test = ini.replace(old, b'path=D:/slimtest_no_wow12')
assert not os.path.exists(r'D:\slimtest_no_wow12')
TD = J(P, u'02_模拟朋友电脑测试')
os.makedirs(TD)
open(J(TD, 'RetailCasc.slimtest.ini'), 'wb').write(test)
open(J(TD, u'RetailCasc.原版.ini'), 'wb').write(ini)

kinds = {}
for f, k in C['seen'].items():
    kinds[k] = kinds.get(k, 0) + 1
gb = size / 2 ** 30


def wr(rel, text):
    path = J(P, *rel.split('/'))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, 'wb').write(text.replace('\n', '\r\n').encode('utf-8'))


README = u"""# SLIM1A V1：高版本素材瘦身包

状态：**候选**。离线验证通过，游戏客户端实机未测。

装上以后，客户端文件夹自己带着已移植内容需要的高版本素材，朋友的电脑不用装 12.x，也不用拷 `D:\\wow12`。

## 内容
- 缓存文件 %(files)d 个，约 %(gb).1f GB。其中你客户端里原来没有的 %(new)d 个。
- 范围：4 张高版本地图(测试地图/创始人要塞、流放者离岛、禁忌离岛、哈籁尼尔)的全部地块、%(wmo)d 个建筑、%(m2)d 个模型及它们引用的贴图和动作，以及 `aliases_maps.csv` 里登记的全部模型和贴图；另含你客户端原有缓存。

## 安装
1. 关闭游戏。
2. 把 `01_覆盖到客户端根目录` 里的 `Data` 复制到客户端根目录(`C:\\000ref\\WarcraftXL试装_client`)，同名文件选覆盖。只往 `Data\\Retail\\CdnCache` 里加文件，不改其他任何东西。

## 模拟朋友电脑测试(发给朋友前建议做)
做法：临时让客户端找不到 `D:\\wow12`。
1. 关闭游戏。
2. 把客户端 `Data\\Retail\\RetailCasc.ini` 改名为 `RetailCasc.ini.before_SLIM1A`。
3. 把本包 `02_模拟朋友电脑测试\\RetailCasc.slimtest.ini` 复制到 `Data\\Retail\\`，改名为 `RetailCasc.ini`。
4. 把客户端 `Logs\\RetailAssets.log` 删掉或改名，方便只看这次的记录。
5. 开游戏测试：
   - 建角界面翻看新种族；龙希尔两种形态都进一次游戏。
   - 哈籁尼尔、流放者离岛、禁忌离岛各走几处，看地面、建筑、树木、水、怪物、小地图。
   - 换装、坐骑、改过外观的首领和 NPC。
6. 关闭游戏。**撤销**：删除第 3 步放进去的 `RetailCasc.ini`，把 `RetailCasc.ini.before_SLIM1A` 改回 `RetailCasc.ini`。
7. 告诉我测试结果，并说一声已撤销(我会检查文件)。有缺东西的地方，`Logs\\RetailAssets.log` 里带 `Cannot open CASC storage` 的行就是缺的文件，我据此补。

## 发给朋友
1. 按“安装”装好本包后，复制整个客户端文件夹。`WTF`(含账号名和个人设置)、`Cache`、`Logs`、`Errors` 不用带；`Data` 要完整带上。
2. `RetailCasc.ini` 保持原样即可，朋友电脑上没有那个路径也没关系。
3. 来你的服务器玩：改 `Data\\enUS\\realmlist.wtf` 为你的服务器地址；auth 库 `realmlist.address` 要填他能访问到的地址；不同局域网需要公网 IP 或虚拟组网。

## 离线验证
让引擎在 `path=` 指向不存在目录的条件下打开全部内容：地块 1866 个、建筑及分组、模型共 9789 项成功，2 个模型失败(装着 `D:\\wow12` 时同样失败，报动作轨道无效，与缺文件无关)，缺文件 0。

## 没验证到的
- 游戏客户端本身的读取：引擎里按功能现查的数据表(种族外观、天空光照、水面等)，离线打开地图和模型不一定都碰到。你本机用过的部分已在缓存里。
- 打包进 MPQ 的新种族素材和 `TwoFormsTables` 不在本包范围，它们本来就在客户端里。
- 没在另一台电脑上运行过。

## 以后更新
再移植新地图、新模型后，缓存不会自动补齐朋友那份，需要重新收集出下一版(V2)。

## 撤销
缓存文件装着 `D:\\wow12` 时不改变显示效果。要删除本包新增的部分，按 `04_撤销\\新增文件清单.txt`(相对 `Data\\Retail\\CdnCache\\wow-%(build)s\\`)删除。

本包内含游戏原版素材，只用于拷贝自己的客户端，不提交仓库、不放进 Release。
""" % {'files': len(files), 'gb': gb, 'new': len(new), 'wmo': kinds.get('wmo', 0), 'm2': kinds.get('m2', 0), 'build': BUILD}
MEMORY = u"""# SLIM1A V1 记录(2026-11-27，Claude)
- 状态：候选。离线验证通过(9789 成功 / 2 失败且装着零售数据时同样失败 / 缺文件 0)；客户端实机未测。
- 用户："当然要做个瘦身包"。目标：朋友拷客户端即可，不需要 D:\\wow12。
- 收集：别名表 132 项出发，WDT/ADT/WMO/M2/SKEL 引用闭包 %d 个文件；缓存格式 WDC1+长度+FNV64。
- 脚本：scripts/collect.py、verify.py(原位置 D:\\_zsdc\\slim)。
- 已读：协作说明_并行开发.md 末尾、开关文件清单末尾、CascSource.cpp / DecodedCache.cpp / probe.cpp(D:\\_zsdc\\fx)。
""" % len(C['seen'])
TUTOR = u"""# 给别人一份能跑的高版本内容客户端
- local 模式读取顺序：MPQ 打包素材 -> overlay -> 解码缓存 -> 本地零售数据。缓存命中就不需要零售数据。
- 缓存只含读到过的文件。按 WDT -> ADT(obj0/tex0) -> 建筑/模型 -> 贴图/皮肤/动作 求引用闭包，一次收齐。
- 验证方法：把暂存目录里的 ini 指向不存在的路径，让引擎打开全部内容；失败项再用真实路径复跑，区分缺文件和引擎本身读不了。
"""
wr('README_覆盖与测试说明.md', README)
wr('memory.md', MEMORY)
wr('tutor.md', TUTOR)
wr(u'04_撤销/新增文件清单.txt', ''.join(f + '\n' for f in new))
os.makedirs(J(P, 'scripts'))
for n in ('collect.py', 'verify.py', 'build_slim1a.py', 'collect.log', 'verify.log'):
    shutil.copyfile(J(W, n), J(P, 'scripts', n))
sums = []
for root, _, names in os.walk(P):
    for n in names:
        s = J(root, n)
        h = hashlib.sha256()
        with open(s, 'rb') as f:
            for part in iter(lambda: f.read(1 << 20), b''):
                h.update(part)
        sums.append('%s  %s\n' % (h.hexdigest(), os.path.relpath(s, P).replace('\\', '/')))
open(J(P, 'SHA256SUMS.txt'), 'wb').write(''.join(sorted(sums, key=lambda x: x[66:])).encode('utf-8'))


def append(path, text):
    old = open(path, 'rb').read()
    nl = b'\r\n' if b'\r\n' in old else b'\n'
    add = (b'' if old.endswith(b'\n') else nl) + nl + text.encode('utf-8') + nl
    open(path, 'ab').write(add)
    assert open(path, 'rb').read() == old + add


append(J(WS, u'协作说明_并行开发.md'), u'| 2026-11-27 | Claude | SLIM1A V1：高版本素材瘦身包 | 已释放(候选：离线验证通过，实机未测) | 只新增客户端 Data\\Retail\\CdnCache 缓存文件；不改 MPQ/DBC/SQL/EXE | 现客户端 aliases_maps.csv 与缓存 | 000Ascendupdate20261127/claudefix_…SLIM1A_V1… | 新增别名或高版本地图/模型后要重新收集；含原版素材，不提交仓库 |')
append(J(WS, u'开关文件清单_会改变行为的文件和设置.md'), u'- SLIM1A V1(2026-11-27，Claude)：(1)往客户端 Data\\Retail\\CdnCache 添加缓存文件(不改行为，清单在包内 04_撤销)；(2)可选测试：把 Data\\Retail\\RetailCasc.ini 改名为 RetailCasc.ini.before_SLIM1A，换上包内 RetailCasc.slimtest.ini(path 指向不存在的 D:/slimtest_no_wow12)，并删除或改名 Logs\\RetailAssets.log。撤销：1 关闭客户端；2 删除换上去的 Data\\Retail\\RetailCasc.ini；3 把 RetailCasc.ini.before_SLIM1A 改回 RetailCasc.ini；4 让助手 ls 核对后登记已撤销。状态：待用户测试。')
SK = J(WS, 'beascendskills', 'port-retail-zone-end-to-end', 'SKILL.md')
s = open(SK, 'rb').read()
mark = u'| 做完整条线才几级 |'.encode('utf-8')
assert s.count(mark) == 1
snl = b'\r\n' if b'\r\n' in s else b'\n'
add = u'| 客户端拷给别人后新地图缺地形或模型 | local 模式靠本机零售数据，缓存只含读到过的文件 | 按引用闭包重收瘦身包(SLIM1A 脚本)，用不存在的 path 离线验证；每次新增高版本内容后重收 |'.encode('utf-8') + snl
open(SK, 'wb').write(s.replace(mark, add + mark))
MD = r'<user-profile>\.claude\projects\d--000rebornWOW-000RebornWOWHighForkPRO-beascendLauncher-wowlauncher2026-CataLauncher-rebornWOW\memory'
open(J(MD, 'slim1a-retail-cache-pack.md'), 'wb').write((u"""---
name: slim1a-retail-cache-pack
description: "SLIM1A V1 (2026-11-27, candidate) - decoded-cache pack so a copied client works without the local retail data; re-collect after any new retail map or model"
metadata:
  type: project
---

2026-11-27 the user asked for a slim pack so a friend can run a copy of the client without the 137 GB retail data. Delivered `000Ascendupdate20261127/claudefix_..._SLIM1A_V1_...` (about GBVALUE GB). Offline engine verification passed; not tested in the game client. Scripts: D:\\_zsdc\\slim\\collect.py and verify.py.

**Why:** local mode reads retail files at runtime from D:\\wow12; the cache only holds what was already visited.

**How to apply:** after adding a retail alias, map or model, rerun collect.py (delete user_files.pkl to resync the client cache) and verify.py, then ship V2. Pending: user's friend-simulation test with the swapped RetailCasc.ini, registered in the switch-file list; check it is restored. Never commit these assets. See [[retailcasc-ini-modes-dracthyr]].
""".replace('GBVALUE', '%.1f' % gb)).encode('utf-8'))
open(J(MD, 'MEMORY.md'), 'ab').write(u'- [SLIM1A retail cache pack](slim1a-retail-cache-pack.md) — copy-the-client pack without D:\\wow12; re-collect after new retail content; restore the test ini\n'.encode('utf-8'))
print(P)
print('SUMS', len(sums))
