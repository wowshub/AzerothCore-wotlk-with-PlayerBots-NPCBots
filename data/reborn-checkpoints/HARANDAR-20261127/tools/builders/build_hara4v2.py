# -*- coding: utf-8 -*-
"""HARA4 V2: Yu'relen's elixir casts Water Breathing on the drinker (SQL only)."""
import io, os, sys, hashlib, sqlite3, struct
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
J = os.path.join
WS = r'D:\000rebornWOW\000RebornWOWHighForkPRO'
P = J(WS, '000Ascendupdate', '000Ascendupdate20261127', u'claudefix_20261127_阶段HARA4_V2_尤瑞伦药剂给水下呼吸_Claude')
assert not os.path.exists(P)

# the spell must be a self-targeted water breathing aura in the live Spell.dbc
b = open(J(WS, 'beascendserver', 'wowshub_playerbot_npcbot_newrace20261122Ascend', 'Data', 'dbc', 'Spell.dbc'), 'rb').read()
_, n, nf, rs, ss = struct.unpack_from('<4sIIII', b)
spell = [f for f in (struct.unpack_from('<%di' % nf, b, 20 + i * rs) for i in range(n)) if f[0] == 7178]
assert spell and spell[0][95] == 82 and spell[0][86] == 1 and spell[0][40] == 30

SQL = u"""-- HARA4 V2: 尤瑞伦的药剂(物体 564999)点击后给自己上水下呼吸(法术 7178，30 分钟)。world 库执行。可重复执行。
SELECT COUNT(*) AS hara4_elixir_must_be_1 FROM `gameobject_template` WHERE `entry` = 564999 AND `Data1` = 91585;
UPDATE `gameobject_template` SET `Data10` = 7178 WHERE `entry` = 564999 AND `Data1` = 91585;
SELECT `entry`, `Data1`, `Data10` AS spell_must_be_7178 FROM `gameobject_template` WHERE `entry` = 564999;
"""
UNDO = u"""-- 撤销 HARA4 V2
UPDATE `gameobject_template` SET `Data10` = 0 WHERE `entry` = 564999 AND `Data1` = 91585;
"""
db = sqlite3.connect(':memory:')
db.execute('CREATE TABLE gameobject_template (entry INTEGER, Data1 INTEGER, Data10 INTEGER)')
db.execute('INSERT INTO gameobject_template VALUES (564999, 91585, 0), (557572, 557572, 0)')
for _ in range(2):
    db.executescript(SQL)
assert db.execute('SELECT Data10 FROM gameobject_template ORDER BY entry').fetchall() == [(0,), (7178,)]
db.executescript(UNDO)
assert db.execute('SELECT SUM(Data10) FROM gameobject_template').fetchone() == (0,)

README = u"""# HARA4 V2：尤瑞伦的药剂给水下呼吸

状态：**候选，实机未测**。前提：已装 HARA4 V1。只改 world 库一行，客户端不用换文件。

## 原因
V1 只做了“点药剂 → 任务计数”，没有给药剂挂任何法术。

## 改动
点药剂时给自己上 **水下呼吸**(法术 7178，原版“水下呼吸药剂”效果，30 分钟)。

## 安装
1. 停服。
2. world 库执行 `01_服务端_SQL/world_hara4_v2.sql`。第一个结果必须是 1，最后一行 spell_must_be_7178 = 7178。
3. 启动服务端；关游戏后删客户端 `Cache\\WDB`。

## 测试
1. 身上有“园中鲜货”且目标还没全部完成时，点药剂(已经点过计数的也可以再点)。
2. 身上出现水下呼吸增益；下水后不出现呼吸条。
3. 死亡会清掉增益，任务目标没做完时可回去再喝。

任务目标全部完成或任务已交后，药剂按任务物体规则不能再点。这个角色已经做完的话，用 `.quest remove 91585` 后重接来测。

## 撤销
执行 `02_撤销/undo_hara4_v2.sql`，重启服务端。
"""
MEMORY = u"""# HARA4 V2 记录(2026-11-27，Claude)
- 状态：候选，未实机测试。
- 用户反馈：药剂点了计数，但没有水下呼吸增益。
- 原因：V1 的 goober 564999 Data10=0。零售物体数据里没有法术字段，效果在零售脚本侧，移植时漏补。
- 修复：Data10=7178。源码 GameObject::Use(goober) 在任务未完成时让使用者对自己施放 Data10。
- 同批问题：任务物品背包图标问号。查实为 Patch-XA.mpq 被 MPQ Editor 占用、游戏进程未持有它，非数据错误，无需新文件；用户重启客户端后确认。
- 已读：协作说明_并行开发.md 末尾(最新 Codex STARTFIX1B，不碰哈籁尼尔表)、交接_*.md 最新几份(2026-11-26 及以前)。
"""
TUTOR = u"""# 可点击任务物体怎么带增益效果
- 类型 10(goober)：Data1=任务ID(只有做该任务时能点)，Data10=法术ID(点击者对自己施放)。
- 零售库里同一物体的 Data10 常为 0，“喝药/泡泉/点火”这类效果要按任务含义自己补，打包前逐个物体问一句“点了之后玩家身上或场景应该发生什么”。
- 选法术：看 Spell.dbc 的光环类型(水下呼吸=82)、目标=自己、持续时间。
"""


def wr(rel, text):
    path = J(P, *rel.split('/'))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, 'wb').write(text.replace('\n', '\r\n').encode('utf-8'))


files = {u'01_服务端_SQL/world_hara4_v2.sql': SQL, u'02_撤销/undo_hara4_v2.sql': UNDO, u'README_覆盖与测试说明.md': README, 'memory.md': MEMORY, 'tutor.md': TUTOR}
for k, v in files.items():
    wr(k, v)
sums = ''.join('%s  %s\n' % (hashlib.sha256(open(J(P, *k.split('/')), 'rb').read()).hexdigest(), k) for k in sorted(files))
open(J(P, 'SHA256SUMS.txt'), 'wb').write(sums.encode('utf-8'))

LOG = J(WS, u'协作说明_并行开发.md')
row = u'| 2026-11-27 | Claude | HARA4 V2：尤瑞伦药剂给水下呼吸 | 候选(实机未测) | 仅 world gameobject_template 564999 Data10=7178(一条 SQL，带撤销)；无客户端文件、无共享表 | HARA4 V1 | 000Ascendupdate20261127/claudefix_…HARA4_V2… | 同批查明：任务物品背包问号是 Patch-XA 被 MPQ Editor 占用、客户端未加载；导入 MPQ 后请先关编辑器再启动游戏 |'
old = open(LOG, 'rb').read()
nl = b'\r\n' if b'\r\n' in old else b'\n'
open(LOG, 'ab').write((b'' if old.endswith(b'\n') else nl) + nl + row.encode('utf-8') + nl)
assert open(LOG, 'rb').read().startswith(old) and row.encode('utf-8') in open(LOG, 'rb').read()[len(old):]

SK = J(WS, 'beascendskills', 'port-retail-zone-end-to-end', 'SKILL.md')
s = open(SK, 'rb').read()
mark = u'| 做完整条线才几级 |'.encode('utf-8')
assert s.count(mark) == 1 and u'MPQ Editor'.encode('utf-8') not in s
snl = b'\r\n' if b'\r\n' in s else b'\n'
add = (u'| 点任务物体只计数、没有应有的效果(喝药没增益) | 零售物体数据不带法术 | goober 的 Data10 填法术ID；逐个物体确认“点了应该发生什么” |',
       u'| 新物品掉落窗口图标对、背包里全是问号，Item.dbc 里行也在 | 导入后 MPQ Editor 还开着该补丁，游戏启动时打不开它 | 查谁占用 MPQ(游戏进程应持有每个已加载补丁)；关掉编辑器再启动游戏 |')
open(SK, 'wb').write(s.replace(mark, b''.join(a.encode('utf-8') + snl for a in add) + mark))
assert open(SK, 'rb').read().count(b'\n') == s.count(b'\n') + 2
print(P)
