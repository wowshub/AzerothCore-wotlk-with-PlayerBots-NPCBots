# -*- coding: utf-8 -*-
"""HARA3 V2: the Lashroom Bud is no longer a critter."""
import os, io, sys, hashlib, sqlite3
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
B = chr(92)
J = os.path.join
WS = r'D:\000rebornWOW\000RebornWOWHighForkPRO'
DAY = J(WS, '000Ascendupdate', '000Ascendupdate20261126')
P = J(DAY, u'claudefix_20261126_阶段HARA3_V2_菇房幼苗会还手不再逃跑_Claude')
assert not os.path.exists(P), P
sha = lambda b: hashlib.sha256(b).hexdigest()
SQL = u'''-- HARA3 V2 (2026-11-26, Claude) - candidate, NOT user-tested. Stop worldserver, WORLD database, after world_hara3.sql (V1). Safe to run twice.
-- Cause: retail marks the Lashroom Bud as creature type 8 (critter). The core gives every critter the critter AI: it runs away when hit, never
-- fights back and gives no experience. Type 4 (like the other lashers) makes it a normal neutral monster.
SET NAMES utf8mb4;
UPDATE `creature_template` SET `type` = 4 WHERE `entry` = 237036;
SELECT `entry`, `type` AS must_be_4, `faction` AS must_be_7,
       (SELECT COUNT(*) FROM `creature_template` WHERE `entry` IN (237036, 237623, 240344, 240656, 240871, 248493) AND `type` = 8) AS critters_left_must_be_0
FROM `creature_template` WHERE `entry` = 237036;
'''
UNDO = u'''-- undo HARA3 V2
UPDATE `creature_template` SET `type` = 8 WHERE `entry` = 237036;
'''
db = sqlite3.connect(':memory:')
db.execute('create table creature_template(entry, type, faction)')
for e, t in ((237036, 8), (237623, 4), (240344, 7), (240656, 7), (240871, 1), (248493, 4), (721, 8)):
    db.execute('insert into creature_template values (?, ?, 7)', (e, t))


def run(text):
    out = []
    for s in '\n'.join(l for l in text.splitlines() if not l.startswith('--')).split(';'):
        if s.strip() and not s.strip().startswith('SET NAMES'):
            out += db.execute(s).fetchall()
    return out


r = run(SQL)
assert r == run(SQL) == [(237036, 4, 7, 0)], r
assert db.execute('select type from creature_template where entry = 721').fetchone() == (8,)
run(UNDO)
assert db.execute('select type from creature_template where entry = 237036').fetchone() == (8,)


def wr(rel, data):
    p = J(P, rel.replace('/', B))
    os.makedirs(os.path.dirname(p), exist_ok=True)
    assert not os.path.exists(p), p
    data = data.strip('\n').replace('\n', '\r\n').encode('utf-8-sig' if rel.endswith('.md') else 'utf-8') + b'\r\n'
    open(p, 'wb').write(data)


wr(u'01_服务端_SQL/world_hara3_v2.sql', SQL)
wr(u'02_撤销/undo_hara3_v2.sql', UNDO)
wr(u'README_覆盖与测试说明.md', u'''
# HARA3 V2：菇房幼苗会还手了(候选，实机未测)

在 HARA3 V1 之上的小修复。只有一条 SQL。

| 现象 | 原因 | 现在 |
|---|---|---|
| 鞭笞菇幼芽挨打就跑、不还手 | 零售数据标成"小动物"，服务端按小动物处理(也不给经验) | 改成普通中立怪：挨打会追上来打你，击杀给经验 |

## 部署(停服)
1. world 库执行 `01_服务端_SQL\\world_hara3_v2.sql`。读回：4、7、0。
2. 启动服务端，删客户端 `Cache\\WDB`(客户端缓存了怪的类型)。

以后重跑 V1 的 `world_hara3.sql`，要接着再跑一次本包 SQL。

## 测试
打一只幼芽：应站住或追过来还手，不逃跑；死后给经验，任务计数 +1。

## 撤销
执行 `02_撤销\\undo_hara3_v2.sql`。
''')
wr(u'memory.md', u'''
# HARA3 V2 记录(2026-11-26，Claude)
用户实机：任务 9190001 的怪被打就逃、不还手。原因：零售 type 8(小动物)→ CritterAI。改为 type 4。状态：候选，未实测。脚本 D:\\_zsdc\\hara\\build_hara3_v2.py。''')
wr(u'tutor.md', u'''
# 大白话
零售里有些"任务怪"在数据上其实是小动物。老服务端看到小动物就让它逃命，所以搬怪时要先看类型这一栏。''')
lines = []
for dp, _d, fn in os.walk(P):
    for fl in fn:
        p = J(dp, fl)
        lines.append('%s  %s' % (sha(open(p, 'rb').read()), os.path.relpath(p, P).replace(B, '/')))
open(J(P, 'SHA256SUMS.txt'), 'wb').write('\n'.join(sorted(lines, key=lambda s: s[66:])).encode('utf-8') + b'\n')


def app(path, text, key):
    t = open(path, 'rb').read()
    assert t.strip() and key.encode('utf-8') not in t, path
    e = '\r\n' if b'\r\n' in t else '\n'
    open(path, 'ab').write((('' if t.endswith(b'\n') else e) + e + text.replace('\n', e) + e).encode('utf-8'))
    assert open(path, 'rb').read().startswith(t)


app(J(WS, u'协作说明_并行开发.md'), u'| 2026-11-26 | Claude | HARA3 V2：菇房幼苗不再逃跑 | 候选(实机未测) | world creature_template 237036 type 8→4 | 离线模拟通过；原因见核心 CritterAI | 000Ascendupdate20261126/claudefix_…HARA3_V2… | 重跑 V1 SQL 后需再跑 V2 |', u'HARA3 V2：菇房')
SK = J(WS, 'beascendskills', 'port-retail-zone-end-to-end', 'SKILL.md')
s = open(SK, 'rb').read()
old = u'| 怪不掉东西 | 没给 lootid/金币 | 同批给齐 |'.encode('utf-8')
assert s.count(old) == 1
nl = b'\r\n' if b'\r\n' in s else b'\n'
new = old + nl + u'| 任务怪挨打就逃、不还手、没经验 | 零售生物类型 8(小动物)会用小动物 AI | 导入前检查 `type`，任务怪改普通类型 |'.encode('utf-8') + nl + u'| 点击物体能反复点、不消失 | goober 的 Data3(自动收起毫秒)=0，Data5 不生效 | Data5=1 且 Data3>0(如 1500) |'.encode('utf-8')
open(SK, 'wb').write(s.replace(old, new))
assert open(SK, 'rb').read().count(b'\n') == s.count(b'\n') + 2
MD = r'<user-profile>\.claude\projects\d--000rebornWOW-000RebornWOWHighForkPRO-beascendLauncher-wowlauncher2026-CataLauncher-rebornWOW\memory'
app(J(MD, 'haranir-start-port.md'), u'11-26: user found Lashroom Bud fleeing (retail creature type 8 = critter) -> HARA3 V2 delivered (type 4), untested. Always check creature type when porting.', u'HARA3 V2 delivered')
print(P)
