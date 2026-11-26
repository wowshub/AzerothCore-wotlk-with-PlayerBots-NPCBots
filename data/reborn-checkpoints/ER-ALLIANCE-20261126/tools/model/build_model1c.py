# -*- coding: utf-8 -*-
"""MODEL1C V1: give Jaina a model path starting with retail\\ so the client reads her skeletal .anim files correctly."""
import ctypes, struct, os, hashlib, shutil, subprocess
B = chr(92)
WS = r'D:\000rebornWOW\000RebornWOWHighForkPRO'
DAY = os.path.join(WS, '000Ascendupdate', '000Ascendupdate20261125')
NAME = 'claudefix_20261125_阶段MODEL1C_V1_吉安娜动作扭曲修复_模型路径改为retail开头_Claude'
P = os.path.join(DAY, NAME)
assert not os.path.exists(P)
CLIENT = r'C:\000ref\WarcraftXL试装_client'
OLD = 'Creature' + B + 'RetailJaina' + B + 'RetailJaina'
NEW = 'retail' + B + 'RetailJaina' + B + 'RetailJaina'
sha = lambda b: hashlib.sha256(b).hexdigest()

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


old = client_table('CreatureModelData.dbc')
a, b = (OLD + '.mdx').encode() + b'\0', (NEW + '.mdx').encode() + b'\0'
assert old.count(a) == 1 and len(b) <= len(a)
new = old.replace(a, b + b'\0' * (len(a) - len(b)))
n, nf, rs, ss = struct.unpack('<4I', new[4:20])
sb = new[20 + n * rs:]
rows = [struct.unpack_from('<%dI' % nf, new, 20 + i * rs) for i in range(n)]
jr = next(r for r in rows if r[0] == 710006)
assert sb[jr[2]:sb.index(0, jr[2])] == b[:-1] and len(new) == len(old) and new[:20 + n * rs] == old[:20 + n * rs]
csv_old = open(CLIENT + r'\Data\Retail\aliases_maps.csv', 'rb').read()
la, lb = ('1717164;' + OLD + '.m2').encode(), ('1717164;' + NEW + '.m2').encode()
assert csv_old.count(la) == 1
csv_new = csv_old.replace(la, lb)
for f in ('5838022.bin', '99000001.bin'):
    assert os.path.isfile(CLIENT + B + 'Data' + B + 'Retail' + B + 'TwoFormsTables' + B + f), 'MODEL1B not installed: ' + f

# offline: every file the client will ask for resolves and converts under the new path, with the client's overrides
V = r'D:\_zsdc\models4\verify5'
if not os.path.isdir(V):
    shutil.copytree(r'D:\_zsdc\models4\verify3', V, ignore=shutil.ignore_patterns('d', '*.txt'))
open(V + B + 'aliases_maps.csv', 'wb').write(csv_new)
m = open(r'D:\_zsdc\models4\verify3\d\Creature_RetailJaina_RetailJaina.m2', 'rb').read()
cnt, off = struct.unpack_from('<II', m, 28)
names = [NEW + '.m2', NEW + '00.skin']
for i in range(cnt):
    s, v = struct.unpack_from('<HH', m, off + 64 * i)
    if not struct.unpack_from('<I', m, off + 64 * i + 12)[0] & 0x60:
        names.append(NEW + '%04d-%02d.anim' % (s, v))
open(V + B + 'l.txt', 'w', newline='\r\n').write('\n'.join(names) + '\n')
os.makedirs(V + B + 'd', exist_ok=True)
r = subprocess.run([r'D:\_zsdc\fx\build\Release\RetailAssetProbe.exe', V + B + 'p.ini', '--batch', V + B + 'l.txt'], env=dict(os.environ, PROBE_DUMP=V + B + 'd'),
                   capture_output=True, text=True, cwd=V, timeout=500)
lines = (r.stdout + r.stderr).splitlines()
ok = sum(x.startswith('ok') for x in lines)
print('converted', ok, 'of', len(names), [x for x in lines if not x.startswith('ok')][:5])
assert ok == len(names)
assert open(V + B + 'd' + B + 'retail_RetailJaina_RetailJaina.m2', 'rb').read() == m, 'converted model differs under the new path'


def wr(rel, data):
    f = os.path.join(P, rel.replace('/', B))
    os.makedirs(os.path.dirname(f), exist_ok=True)
    open(f, 'wb').write(data.encode('utf-8') if isinstance(data, str) else data)


wr('01_导入Patch-YB.mpq/DBFilesClient/CreatureModelData.dbc', new)
wr('02_覆盖到客户端根目录/Data/Retail/aliases_maps.csv', csv_new)
wr('03_撤销/原Patch-YB/DBFilesClient/CreatureModelData.dbc', old)
wr('03_撤销/原客户端根目录/Data/Retail/aliases_maps.csv', csv_old)
shutil.copy(r'D:\_zsdc\models4\r1.png', os.path.join(P, '离线渲染_上待机_中正确读法_下游戏现在的读法.png'))
hashes = [('客户端 YB CreatureModelData.dbc', sha(old), sha(new)), ('客户端 aliases_maps.csv', sha(csv_old), sha(csv_new))]
wr('README_覆盖与测试说明.md', '''# MODEL1C V1：吉安娜说话/接交任务时身体横过来

状态：候选，游戏里未测(离线渲染已复现游戏里的姿势，并确认正确读法下动作正常)。只改客户端。服务端、SQL 不动。
前提：MODEL1A V1、MODEL1B V1 已装(B 的两个文件要保留)。

## 原因
吉安娜的说话、攻击等动作是游戏临时从单独的动作文件读的，这类文件带一层分段头。客户端只对路径以 `retail\\` 开头的模型识别这层分段头；
MODEL1A 给她起的路径以 `Creature\\` 开头，于是动作数据整体读错位，身体横过来、手乱挥。包里的图下面一排就是按错误读法渲染的结果，和你的截图一致。
鹰身人、血喙、拉希奥、光明之灵的动作文件没有这层分段头，所以没事。MODEL1B 修的编号错误是另一个问题，仍然需要。

## 改动
YB 的 CreatureModelData 里 710006 的模型路径、aliases_maps.csv 对应的一行，从 `Creature\\RetailJaina\\...` 改成 `retail\\RetailJaina\\...`。表里其他内容一个字节没动。

## 安装(关闭客户端)
1. 备份 `Data\\Patch-YB.mpq`，核对 YB 里 CreatureModelData.dbc 的 SHA256 等于下表"输入"；不相等就别导入，告诉我。
2. 把 `01_导入Patch-YB.mpq\\DBFilesClient\\CreatureModelData.dbc` 导入 YB，保存并关闭 MPQ 编辑器。
3. 把 `02_覆盖到客户端根目录` 覆盖到客户端根目录。
4. 删客户端 `Cache\\WDB`，开游戏。

## 测试
`.go xyz 186 -2289 82 12175`
1. 和吉安娜反复对话、接交任务：站着做说话手势，身体不横过来。
2. 模型本身仍然正常(贴图、待机)。如果她整个看不见或变方块，告诉我，并发 `Logs\\Extensions.log` 里含 RetailJaina 的行。

## 指纹(SHA256)
| 文件 | 输入 | 输出 |
|---|---|---|
''' + '\n'.join('| %s | %s | %s |' % h for h in hashes) + '''

## 撤销
YB 导回 `03_撤销\\原Patch-YB` 里的表，用 `03_撤销\\原客户端根目录` 覆盖回根目录。
''')
wr('memory.md', '''# memory - MODEL1C V1 (2026-11-25, Claude, 候选未测)
- MODEL1B 装上后用户仍见扭曲(身体水平、招手)。
- 真因：M2Shared.cpp FinishLoadingLowPrioritySequence 只在 IsCdnPath(路径以 retail/ 或 forever/ 开头)时解析 AFM2/AFSB/AFSA；Creature\\ 别名路径下 AFSB 当裸数据读，错位 8 字节。
- 规则：带 SKID(外部骨架)的零售模型，别名虚拟路径必须以 retail\\ 开头。
- 离线渲染脚本 D:\\_zsdc\\models4\\render.py：用它先看姿势再交付。
''')
wr('tutor.md', '''# tutor - 导入带独立骨架的零售模型 (MODEL1C V1, 未实测)
1. 看 M2 有没有 SKID。有的话虚拟路径用 `retail\\名字\\名字.m2`，DBC 的 ModelName 同步。
2. 交付前离线渲染待机和几个外部动作(说话 60、64、65)看姿势，只核对文件能转换是不够的。
3. 同时检查继承骨架的别名编号(见 MODEL1B)。
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
assert 'MODEL1C V1' not in open(log, 'rb').read().decode('utf-8', 'replace')
append_text(log, ['| 2026-11-25 | Claude | 反馈：MODEL1B V1 装上后吉安娜仍扭曲 | 未解决 | 同该包登记 | 基线同上 | 000Ascendupdate20261125 | MODEL1B 文件保留 |',
                  '| 2026-11-25 | Claude | MODEL1C V1(吉安娜模型路径改 retail 开头，AFSB 动作正确读取) | 候选(未安装) | YB CreatureModelData.dbc 仅 710006 路径字符串、aliases_maps.csv 一行 | 基线：MODEL1A V1 实装版 + MODEL1B | 包 000Ascendupdate20261125/%s | 占用 YB CreatureModelData；带外部骨架的别名模型路径须以 retail 开头(Codex 请留意) |' % NAME])
led = os.path.join(WS, '台账_YB_XA共享文件哈希.md')
append_text(led, ['', '## 2026-11-25 MODEL1C V1（Claude，候选未安装）', '只改 710006 模型路径。', '', '|文件|实际input|候选output|', '|---|---|---|'] + ['|%s|%s|%s|' % h for h in hashes])
for h in hashes:
    print(h[0].encode('ascii', 'replace').decode(), h[1][:12], '->', h[2][:12])
