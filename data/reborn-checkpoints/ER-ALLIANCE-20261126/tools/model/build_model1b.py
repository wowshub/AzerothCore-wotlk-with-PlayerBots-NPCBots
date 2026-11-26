# -*- coding: utf-8 -*-
"""MODEL1B V1: Jaina twisted when talking. Client only: two override files for her skeleton."""
import os, hashlib, shutil
B = chr(92)
WS = r'D:\000rebornWOW\000RebornWOWHighForkPRO'
DAY = os.path.join(WS, '000Ascendupdate', '000Ascendupdate20261125')
NAME = 'claudefix_20261125_阶段MODEL1B_V1_吉安娜说话时身体扭曲修复_Claude'
P = os.path.join(DAY, NAME)
assert not os.path.exists(P)
CLIENT = r'C:\000ref\WarcraftXL试装_client'
FILES = ['5838022.bin', '99000001.bin']
for f in FILES:
    assert not os.path.exists(CLIENT + B + 'Data' + B + 'Retail' + B + 'TwoFormsTables' + B + f), f
sha = lambda p: hashlib.sha256(open(p, 'rb').read()).hexdigest()


def wr(rel, text):
    f = os.path.join(P, rel.replace('/', B))
    os.makedirs(os.path.dirname(f), exist_ok=True)
    open(f, 'w', encoding='utf-8', newline='\n').write(text)


dst = os.path.join(P, '01_覆盖到客户端根目录', 'Data', 'Retail', 'TwoFormsTables')
os.makedirs(dst)
for f in FILES:
    src = r'D:\_zsdc\models4\skelfix' + B + f
    assert sha(src) == sha(r'D:\_zsdc\models4\verify3\TwoFormsTables' + B + f), 'packaged file differs from the verified one'
    shutil.copy(src, os.path.join(dst, f))
wr('README_覆盖与测试说明.md', '''# MODEL1B V1：吉安娜说话时身体扭曲

状态：候选，游戏里未测(离线已复现原问题并验证修好)。只改客户端，加两个文件。服务端、SQL、补丁 MPQ 都不动。
前提：MODEL1A V1 已装。

## 原因
吉安娜的模型借用一套共享骨架。客户端的模型转换器把共享骨架里的动作接到自己的动作后面时，没有同步更新动作之间的"别名编号"。
游戏要播放说话等需要临时加载的动作时，会把别的动作数据也按错误编号改写，身体就扭曲了。离线检查：吉安娜 74 个这类动作全部编号错误(说话、攻击、施法等)，
本批另外四个模型和光明之灵没有这个问题。

## 做法
不改客户端程序。给她单独放一份编号写对的骨架副本(新编号 99000001，别的模型用不到)，并让她自己的骨架指向这份副本。
离线用客户端实际读取的数据重新转换：74 个动作编号错误数为 0，动作数据逐个读取正常。

## 安装
1. 关闭客户端(现在开着的话要退出)。
2. 把 `01_覆盖到客户端根目录` 覆盖到客户端根目录。结果是 `Data\\Retail\\TwoFormsTables` 里多出 `5838022.bin`、`99000001.bin`。
3. 开游戏。

两个文件含零售素材，只在本机用，不要提交或分发。

## 测试
`.go xyz 186 -2289 82 12175`
1. 和吉安娜对话、接交任务多次，身体不再扭曲，能看到正常的说话动作。
2. 走开再回来、下线重登后再试一次。
3. 船上和营地其他几处吉安娜是同一个模型，顺路看一眼。

## 撤销
关闭客户端，删除 `Data\\Retail\\TwoFormsTables\\5838022.bin` 和 `99000001.bin`。

## 指纹(SHA256)
''' + '\n'.join('- %s %s' % (f, sha(os.path.join(dst, f))) for f in FILES) + '\n')
wr('memory.md', '''# memory - MODEL1B V1 (2026-11-25, Claude, 候选未测)
- 用户：MODEL1A 其他模型没问题，吉安娜(156807)对话时身体扭曲。
- 根因：RetailModel.cpp MergeSkeleton 只重映射 next(+60)，没重映射 alias(+62)；运行时 FinishLoadingLowPrioritySequence 顺 alias 链改写无关序列。
- 数据绕过：5838022(子骨架 SKPD -> 99000001)，99000001 = Patch-YK 里打包版 2137789 的修正副本(客户端读打包版，不是本地 CASC 版)。
- 正式修法(未做，需编译客户端程序)：合并后继承序列 alias = 自身新下标。
''')
wr('tutor.md', '''# tutor - 零售人形模型做动作时扭曲 (MODEL1B V1, 未实测)
1. 看模型是否有 SKID，骨架是否有 SKPD(继承父骨架)。
2. 离线转换后检查：每个外部动作(flags 不含 0x20/0x40)顺着 alias 链必须只经过别名动作并回到自己；不满足就会在加载 .anim 时写坏别的动作。
3. 核对客户端实际读哪份文件：RetailCasc.ini 有 packbuild 时，补丁里打包的 EsteriaRetail 文件优先于本地零售数据和覆盖目录。
4. 绕过办法：子骨架和父骨架副本放覆盖目录，父副本用一个没人用的新编号，别直接改共享骨架。
''')
lines = []
for dp, dn, fn in os.walk(P):
    for f in sorted(fn):
        p = os.path.join(dp, f)
        lines.append('%s  %s' % (sha(p), os.path.relpath(p, P).replace(B, '/')))
wr('SHA256SUMS.txt', '\n'.join(lines) + '\n')


def append_text(path, lines_):
    t = open(path, 'rb').read()
    e = b'\r\n' if b'\r\n' in t else b'\n'
    open(path, 'ab').write((b'' if t.endswith(b'\n') else e) + b''.join(x.encode('utf-8') + e for x in lines_))


log = os.path.join(WS, '协作说明_并行开发.md')
assert 'MODEL1B V1' not in open(log, 'rb').read().decode('utf-8', 'replace')
append_text(log, ['| 2026-11-25 | Claude | 反馈：MODEL1A V1 实机，其他模型无问题，吉安娜对话时扭曲 | 部分通过(未提交/未发布) | 同该包登记 | 基线同上 | 000Ascendupdate20261125 | YB 占用解除 |',
                  '| 2026-11-25 | Claude | MODEL1B V1(吉安娜扭曲：共享骨架别名编号) | 候选(未安装) | 客户端 Data/Retail/TwoFormsTables 新增 5838022.bin、99000001.bin | 基线：MODEL1A V1；父骨架取 Patch-YK 打包版 2137789(只读未改) | 包 000Ascendupdate20261125/%s | 同一转换器缺陷可能影响其他继承骨架的零售模型(含种族模型)，请 Codex 留意；未改客户端程序 |' % NAME])
sw = os.path.join(WS, '开关文件清单_会改变行为的文件和设置.md')
append_text(sw, ['', '- MODEL1B V1(2026-11-25，Claude)：客户端 Data\\Retail\\TwoFormsTables 新增 5838022.bin、99000001.bin(吉安娜骨架的修正副本)。撤销：1 关闭客户端；2 删除这两个文件；3 让助手 ls 核对后登记已撤销。状态：待用户测试。'])
print(len(lines), 'files')
