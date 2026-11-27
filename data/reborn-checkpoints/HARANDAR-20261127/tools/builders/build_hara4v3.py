# -*- coding: utf-8 -*-
"""HARA4 V3: correct the direction wording of three HARA4 quests (WoW axes: +x north, +y west). Includes the V2 line."""
import io, os, sys, hashlib, sqlite3, glob, re
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
J = os.path.join
WS = r'D:\000rebornWOW\000RebornWOWHighForkPRO'
D = J(WS, '000Ascendupdate', '000Ascendupdate20261127')
P = J(D, u'claudefix_20261127_阶段HARA4_V3_任务方向文字改正_含药剂水下呼吸_Claude')
assert not os.path.exists(P)
V1 = glob.glob(J(WS, '000Ascendupdate', '*', u'claudefix_*HARA4_V1*', u'05_*', 'world_hara4.sql'))[0]
v1 = open(V1, encoding='utf-8').read()

# (quest, column, old fragment, new fragment) -- every old fragment must exist in the V1 SQL
REP = [
    (9190007, 'LogTitle', u'A Smell from the South 南边飘来的香味', u'A Smell from the East 东边飘来的香味'),
    (9190007, 'LogDescription', u"south of Har'mara", u"about 400 yards east of Har'mara"),
    (9190007, 'LogDescription', u'到哈尔玛拉南边的', u'到哈尔玛拉东边约400码的'),
    (9190007, 'QuestDescription', u'far to the south', u'far to the east'),
    (9190007, 'QuestDescription', u'在南边很远的', u'在东边很远的'),
    (91587, 'LogDescription', u'north of the grotto', u'about 150 yards west of the grotto'),
    (91587, 'LogDescription', u'消灭洞窟北边的', u'消灭洞窟西边约150码处的'),
    (91589, 'LogDescription', u"carry it north to Har'mara", u"carry it west to Har'mara"),
    (91589, 'LogDescription', u'带回北边的哈尔玛拉', u'向西带回哈尔玛拉'),
]
q = lambda s: "'" + s.replace("'", "''") + "'"
for _i, _c, old, _n in REP:
    assert old.replace("'", "''") in v1, old

# geography check against the delivered spawn and quest giver positions
YU, BOSS, ORW, DISH = (1357.4, 486.2), (1381.55, 626.64), (1339.0, 905.0), (1170.0, 806.5)
assert BOSS[1] - YU[1] > 4 * abs(BOSS[0] - YU[0])          # boss: west of the cook
assert ORW[1] - YU[1] > 4 * abs(YU[0] - ORW[0])            # cook: east of Orweyna
assert DISH[1] > YU[1] and DISH[0] < YU[0]                 # gathering place: west (and south) of the grotto

lines = [u'-- HARA4 V3: 改正三个任务的方向文字(游戏坐标 X+ 是北、Y+ 是西)，并包含 V2 的药剂水下呼吸。world 库执行。可重复执行。',
         u'SELECT COUNT(*) AS hara4_quests_must_be_3 FROM `quest_template` WHERE `ID` IN (9190007, 91587, 91589);',
         u'UPDATE `gameobject_template` SET `Data10` = 7178 WHERE `entry` = 564999 AND `Data1` = 91585;']
undo = [u'-- 撤销 HARA4 V3 的文字改动(不撤销 V2 的药剂；要撤药剂请用 V2 的撤销脚本)']
for i, c, old, new in REP:
    lines.append(u'UPDATE `quest_template` SET `%s` = REPLACE(`%s`, %s, %s) WHERE `ID` = %d;' % (c, c, q(old), q(new), i))
    undo.append(u'UPDATE `quest_template` SET `%s` = REPLACE(`%s`, %s, %s) WHERE `ID` = %d;' % (c, c, q(new), q(old), i))
lines.append(u'SELECT `ID`, `LogTitle`, `LogDescription` FROM `quest_template` WHERE `ID` IN (9190007, 91587, 91589) ORDER BY `ID`;')
lines.append(u'SELECT `Data10` AS spell_must_be_7178 FROM `gameobject_template` WHERE `entry` = 564999;')
SQL, UNDO = '\n'.join(lines) + '\n', '\n'.join(undo) + '\n'

# simulate on the original strings
orig = {}
for i, c, old, _n in REP:
    row = [l for l in v1.split('\n') if l.startswith('(%d, 2,' % i)][0]
    strs = [m.replace("''", "'") for m in re.findall(r"'((?:[^']|'')*)'", row)]
    orig.setdefault(i, strs[:3])                            # title, log description, description
db = sqlite3.connect(':memory:')
db.execute('CREATE TABLE quest_template (ID INTEGER, LogTitle TEXT, LogDescription TEXT, QuestDescription TEXT)')
db.execute('CREATE TABLE gameobject_template (entry INTEGER, Data1 INTEGER, Data10 INTEGER)')
db.execute('INSERT INTO gameobject_template VALUES (564999, 91585, 7178)')
db.executemany('INSERT INTO quest_template VALUES (?,?,?,?)', [[i] + v for i, v in sorted(orig.items())])
before = db.execute('SELECT * FROM quest_template ORDER BY ID').fetchall()
db.executescript(SQL)
after = db.execute('SELECT * FROM quest_template ORDER BY ID').fetchall()
db.executescript(SQL)
assert db.execute('SELECT * FROM quest_template ORDER BY ID').fetchall() == after
for i, c, old, new in REP:
    val = db.execute('SELECT %s FROM quest_template WHERE ID=?' % c, (i,)).fetchone()[0]
    assert new in val and old not in val, (i, c, val)
for r in after:
    print(r[0], '|', r[1], '|', r[2])
db.executescript(UNDO)
assert db.execute('SELECT * FROM quest_template ORDER BY ID').fetchall() == before

README = u"""# HARA4 V3：改正任务里写反的方向

状态：**候选，实机未测**。前提：已装 HARA4 V1。只改 world 库，客户端不用换文件。
包含 V2 的药剂水下呼吸：跑过 V2 也能直接执行；没跑过 V2 只执行本包即可。

## 原因
移植时把游戏坐标轴看错了(实际 X+ 是北、Y+ 是西)，我自己写的方向都不对：

|任务|原文字|实际位置|
|---|---|---|
|南边飘来的香味(改名为“东边飘来的香味”)|洞窟在南边|奥威娜 **东边** 约 420 码|
|腐肉佳肴|首领在洞窟北边|尤瑞伦 **西边** 约 145 码(略偏北)|
|送餐回村|向北带回村子|从洞窟 **向西**(偏南)约 360 码|

地图标记数据本身指在首领出生点，没有改。这张世界地图横向约 7500 码，首领和尤瑞伦只隔约 2%，两个标记会几乎叠在一起。

## 安装
1. 停服。
2. world 库执行 `01_服务端_SQL/world_hara4_v3.sql`。第一个结果为 3，最后一个结果为 7178。
3. 启动服务端；关游戏后删客户端 `Cache\\WDB`(任务文字有缓存，必须删)。

## 测试
- 任务日志里三个任务的方向文字已更新。
- 首领位置：尤瑞伦往西约 145 码，飞在空中。直接传送：`.go xyz 1382 627 1350 12694`；打死后 3 分钟刷新。

## 撤销
执行 `02_撤销/undo_hara4_v3.sql`。
"""
MEMORY = u"""# HARA4 V3 记录(2026-11-27，Claude)
- 状态：候选，未实机测试。
- 用户反馈：腐肉佳肴找不到首领，地图标记看着在给任务的人身上。
- 核对：quest_poi 目标序号 0/4 与原版规则一致，点位在首领出生点；quest_template 目标正确。WorldMapArea 20418 宽 7573 码，两标记仅差 1.8%(推断为看似重叠，未见用户地图画面)。
- 真正的错误：任务文字方向按错误坐标轴写的(北/西混淆)。HARA2/HARA3 的方向句核对后大致成立，未改。
- 已读：协作说明_并行开发.md 末尾、交接_*.md 最新几份。
"""
TUTOR = u"""# 任务文字里的方向怎么写
- 游戏世界坐标：**X 增大 = 北，Y 增大 = 西**。
- 写“某某边”之前算 dx、dy：|dy| > |dx| 时主方向是东西，不是南北。
- 世界地图很大时(几千码)，一两百码内的目标和交任务人标记会重叠，任务描述里写方向和大致码数。
"""


def wr(rel, text):
    path = J(P, *rel.split('/'))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, 'wb').write(text.replace('\n', '\r\n').encode('utf-8'))


files = {u'01_服务端_SQL/world_hara4_v3.sql': SQL, u'02_撤销/undo_hara4_v3.sql': UNDO, u'README_覆盖与测试说明.md': README, 'memory.md': MEMORY, 'tutor.md': TUTOR}
for k, v in files.items():
    wr(k, v)
sums = ''.join('%s  %s\n' % (hashlib.sha256(open(J(P, *k.split('/')), 'rb').read()).hexdigest(), k) for k in sorted(files))
open(J(P, 'SHA256SUMS.txt'), 'wb').write(sums.encode('utf-8'))

LOG = J(WS, u'协作说明_并行开发.md')
row = u'| 2026-11-27 | Claude | HARA4 V3：任务方向文字改正(含 V2 药剂) | 候选(实机未测) | 仅 world quest_template 9190007/91587/91589 文字、gameobject_template 564999 Data10；无客户端文件、无共享表 | HARA4 V1 | 000Ascendupdate20261127/claudefix_…HARA4_V3… | 坐标轴提醒：X+ 北、Y+ 西 |'
old = open(LOG, 'rb').read()
nl = b'\r\n' if b'\r\n' in old else b'\n'
open(LOG, 'ab').write((b'' if old.endswith(b'\n') else nl) + nl + row.encode('utf-8') + nl)
now = open(LOG, 'rb').read()
assert now.startswith(old) and row.encode('utf-8') in now[len(old):]

SK = J(WS, 'beascendskills', 'port-retail-zone-end-to-end', 'SKILL.md')
s = open(SK, 'rb').read()
mark = u'| 做完整条线才几级 |'.encode('utf-8')
assert s.count(mark) == 1 and u'Y+ 是西'.encode('utf-8') not in s
snl = b'\r\n' if b'\r\n' in s else b'\n'
add = u'| 任务文字说在北边，实际在西边；地图标记和交任务人叠在一起看不出 | 坐标轴看反；大地图上百来码几乎重合 | X+ 是北、Y+ 是西，按 dx/dy 写方向；任务描述写明方向和大致码数 |'.encode('utf-8') + snl
open(SK, 'wb').write(s.replace(mark, add + mark))
assert open(SK, 'rb').read().count(b'\n') == s.count(b'\n') + 1

MD = r'<user-profile>\.claude\projects\d--000rebornWOW-000RebornWOWHighForkPRO-beascendLauncher-wowlauncher2026-CataLauncher-rebornWOW\memory'
open(J(MD, 'wow-axes-quest-directions.md'), 'wb').write(u"""---
name: wow-axes-quest-directions
description: "WoW world axes are +X north, +Y west; check dx/dy before writing any direction into quest text or telling the user where something is"
metadata:
  type: feedback
---

World coordinates: X grows to the north, Y grows to the west. On 2026-11-27 the user could not find the 91587 boss because my quest text said north (it is west), and 9190007 / 91589 and my own reports had the same mistake (the grotto is east of Har'mara, the Shrine of Ages is south of the grotto, not southwest).

**Why:** the player navigates by the quest text, since on a 7500-yard world map targets 150 yards apart draw on top of each other.

**How to apply:** compute dx/dy for every direction claim, and put direction plus rough yards into the quest description. See [[haranir-start-port]].
""".encode('utf-8'))
open(J(MD, 'MEMORY.md'), 'ab').write(u'- [WoW axes for quest text](wow-axes-quest-directions.md) — +X north, +Y west; check dx/dy before writing directions\n'.encode('utf-8'))
h = open(J(MD, 'haranir-start-port.md'), 'ab')
h.write(u'\n11-27: HARA4 V1 under test; V2 (elixir water breathing) and V3 (direction wording, includes V2) delivered, untested. Quest item bag question marks traced to Patch-XA held by MPQ Editor.\n'.encode('utf-8'))
h.close()
print(P)
