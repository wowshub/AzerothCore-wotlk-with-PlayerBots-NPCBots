# -*- coding: utf-8 -*-
"""HARA4 V4: weaker Bloomterror boss. Cumulative: includes the V3 SQL (direction wording + elixir)."""
import io, os, sys, hashlib, sqlite3, glob
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
J = os.path.join
WS = r'D:\000rebornWOW\000RebornWOWHighForkPRO'
D = J(WS, '000Ascendupdate', '000Ascendupdate20261127')
P = J(D, u'claudefix_20261127_阶段HARA4_V4_腐肉佳肴首领降低血量和伤害_含方向文字与药剂_Claude')
assert not os.path.exists(P)
V3 = glob.glob(J(D, u'claudefix_*HARA4_V3*', u'01_*', 'world_hara4_v3.sql'))[0]
v3 = open(V3, encoding='utf-8').read().replace('\r\n', '\n')
v3 = v3.split('\n', 1)[1]                                   # drop the V3 header comment
V1 = glob.glob(J(WS, '000Ascendupdate', '*', u'claudefix_*HARA4_V1*', u'05_*', 'world_hara4.sql'))[0]
v1 = open(V1, encoding='utf-8').read()
assert "'SmartAI', 0, 3.0, 1.1, 2," in v1 and '(248598, 0, 0, 0, 0, 0, 100, 0, 6000, 9000, 40000, 50000, 11, 744, 0, 2,' in v1

BOSS = u"""-- 首领 248598：血量系数 3.0 -> 2.0，伤害系数 1.1 -> 0.8，首次放毒 6-9 秒 -> 15-20 秒
SELECT `HealthModifier`, `DamageModifier` FROM `creature_template` WHERE `entry` = 248598;
UPDATE `creature_template` SET `HealthModifier` = 2.0, `DamageModifier` = 0.8 WHERE `entry` = 248598;
UPDATE `smart_scripts` SET `event_param1` = 15000, `event_param2` = 20000 WHERE `entryorguid` = 248598 AND `source_type` = 0 AND `id` = 0 AND `action_param1` = 744;
SELECT `HealthModifier` AS hp_must_be_2, `DamageModifier` AS damage_must_be_0_8 FROM `creature_template` WHERE `entry` = 248598;
SELECT `event_param1` AS poison_must_be_15000, `event_param2` AS poison_must_be_20000 FROM `smart_scripts` WHERE `entryorguid` = 248598 AND `source_type` = 0 AND `id` = 0;
"""
SQL = u'-- HARA4 V4: 首领削弱 + V3(方向文字、药剂水下呼吸)。world 库执行。可重复执行。\n' + v3 + BOSS
UNDO = u"""-- 撤销 HARA4 V4 的首领改动(文字撤销见 V3，药剂撤销见 V2)
UPDATE `creature_template` SET `HealthModifier` = 3.0, `DamageModifier` = 1.1 WHERE `entry` = 248598;
UPDATE `smart_scripts` SET `event_param1` = 6000, `event_param2` = 9000 WHERE `entryorguid` = 248598 AND `source_type` = 0 AND `id` = 0 AND `action_param1` = 744;
"""

db = sqlite3.connect(':memory:')
db.execute('CREATE TABLE quest_template (ID INTEGER, LogTitle TEXT, LogDescription TEXT, QuestDescription TEXT)')
db.execute('CREATE TABLE gameobject_template (entry INTEGER, Data1 INTEGER, Data10 INTEGER)')
db.execute('CREATE TABLE creature_template (entry INTEGER, HealthModifier REAL, DamageModifier REAL)')
db.execute('CREATE TABLE smart_scripts (entryorguid INTEGER, source_type INTEGER, id INTEGER, action_param1 INTEGER, event_param1 INTEGER, event_param2 INTEGER)')
db.execute('INSERT INTO creature_template VALUES (248598, 3.0, 1.1), (240120, 1.0, 0.8)')
db.execute('INSERT INTO smart_scripts VALUES (248598, 0, 0, 744, 6000, 9000)')
db.executescript(SQL)
db.executescript(SQL)
assert db.execute('SELECT * FROM creature_template ORDER BY entry').fetchall() == [(240120, 1.0, 0.8), (248598, 2.0, 0.8)]
assert db.execute('SELECT event_param1, event_param2 FROM smart_scripts').fetchall() == [(15000, 20000)]
db.executescript(UNDO)
assert db.execute('SELECT * FROM creature_template ORDER BY entry').fetchall() == [(240120, 1.0, 0.8), (248598, 3.0, 1.1)]
assert db.execute('SELECT event_param1, event_param2 FROM smart_scripts').fetchall() == [(6000, 9000)]

README = u"""# HARA4 V4：腐肉佳肴首领削弱

状态：**候选，实机未测**。前提：已装 HARA4 V1。只改 world 库，客户端不用换文件。
包含 V3(任务方向文字)和 V2(药剂水下呼吸)，只执行本包即可。

## 改动(盛放的孢子滑翔者恐魔 248598)
|项目|原来|现在|
|---|---|---|
|血量|528|约 352|
|近战伤害|3-16|约 2-12(系数 1.1 -> 0.8)|
|毒(每 3 秒 12 点，持续 30 秒)首次释放|开战 6-9 秒|开战 15-20 秒|

毒的伤害本身没改，之后仍是每 40-50 秒一次。经验、金钱、掉落不变。

## 安装
1. 停服。
2. world 库执行 `01_服务端_SQL/world_hara4_v4.sql`。末尾依次为 2、0.8、15000/20000。
3. 启动服务端；删客户端 `Cache\\WDB`(V3 的任务文字需要)。

## 测试
`.go xyz 1382 627 1350 12694`。看首领血量约 352、单人打起来是否合适。

## 撤销
`02_撤销/undo_hara4_v4.sql`(只撤首领)。
"""
MEMORY = u"""# HARA4 V4 记录(2026-11-27，Claude)
- 状态：候选，未实机测试。
- 用户要求：首领攻击稍微调低、血量调低。用户截图：9 级，528 血，伤害 3-16。
- 改动：HealthModifier 3.0->2.0，DamageModifier 1.1->0.8，首次放毒 15-20 秒。
- 同期用户确认：药剂水下呼吸通过。
- 已读：协作说明_并行开发.md 末尾。
"""
TUTOR = u"""# 单人练级线的首领强度
- 低级首领先用血量系数 2.0、伤害系数 0.8 左右起步。
- 持续伤害技能要单独算总量(每跳 × 跳数)再和玩家血量比，近战系数压不到它。
"""


def wr(rel, text):
    path = J(P, *rel.split('/'))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, 'wb').write(text.replace('\n', '\r\n').encode('utf-8'))


files = {u'01_服务端_SQL/world_hara4_v4.sql': SQL, u'02_撤销/undo_hara4_v4.sql': UNDO, u'README_覆盖与测试说明.md': README, 'memory.md': MEMORY, 'tutor.md': TUTOR}
for k, v in files.items():
    wr(k, v)
sums = ''.join('%s  %s\n' % (hashlib.sha256(open(J(P, *k.split('/')), 'rb').read()).hexdigest(), k) for k in sorted(files))
open(J(P, 'SHA256SUMS.txt'), 'wb').write(sums.encode('utf-8'))

LOG = J(WS, u'协作说明_并行开发.md')
row = u'| 2026-11-27 | Claude | HARA4 V4：首领 248598 降血量伤害(含 V3/V2) | 候选(实机未测)；药剂水下呼吸用户已测通过 | 仅 world creature_template/smart_scripts 248598 及 V3 内容；无客户端文件、无共享表 | HARA4 V1 | 000Ascendupdate20261127/claudefix_…HARA4_V4… | 用户要求削弱 |'
old = open(LOG, 'rb').read()
nl = b'\r\n' if b'\r\n' in old else b'\n'
open(LOG, 'ab').write((b'' if old.endswith(b'\n') else nl) + nl + row.encode('utf-8') + nl)
now = open(LOG, 'rb').read()
assert now.startswith(old) and row.encode('utf-8') in now[len(old):]
MD = r'<user-profile>\.claude\projects\d--000rebornWOW-000RebornWOWHighForkPRO-beascendLauncher-wowlauncher2026-CataLauncher-rebornWOW\memory'
h = open(J(MD, 'haranir-start-port.md'), 'ab')
h.write(u'11-27: HARA4 V4 delivered (boss 248598 HP x2.0, damage x0.8, first poison 15-20s; includes V3/V2), untested.\n'.encode('utf-8'))
h.close()
print(P)
