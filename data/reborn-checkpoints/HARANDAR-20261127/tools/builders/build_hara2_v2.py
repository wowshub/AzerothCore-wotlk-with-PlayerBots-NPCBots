# -*- coding: utf-8 -*-
"""HARA2 V2: click fungi are consumed by the core after one click; the pulled plant cannot be counted twice."""
import os, io, sys, hashlib, sqlite3
from lupa.lua51 import LuaRuntime
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
B = chr(92)
J = os.path.join
WS = r'D:\000rebornWOW\000RebornWOWHighForkPRO'
DAY = J(WS, '000Ascendupdate', '000Ascendupdate20261126')
P = J(DAY, u'claudefix_20261126_阶段HARA2_V2_真菌点一次就消失_30秒后刷新_Claude')
assert not os.path.exists(P), P
H = r'D:\_zsdc\hara'
sha = lambda b: hashlib.sha256(b).hexdigest()
V1 = open(J(H, 'Hara2.lua'), 'rb').read()
live = open(J(WS, 'beascendserver', 'wowshub_playerbot_npcbot_newrace20261122Ascend', 'lua_scripts', 'Hara2.lua'), 'rb').read()
assert live == V1, 'the installed Hara2.lua differs from V1'

s = V1.decode('utf-8').replace('\r\n', '\n')


def sub(old, new):
    global s
    assert s.count(old) == 1, old
    s = s.replace(old, new)


sub('-- Hara2.lua (HARA2 V1, 2026-11-26, Claude)', '-- Hara2.lua (HARA2 V2, 2026-11-26, Claude)')
sub('''RegisterCreatureGossipEvent(PLANT, 1, function(event, player, creature)
    player:GossipComplete()
    if need(player, Q_ROOTS, PLANT, 6) then
''', '''local pulledAt = {}                                     -- [plant guid low] = os.time() of the click that counted

RegisterCreatureGossipEvent(PLANT, 1, function(event, player, creature)
    player:GossipComplete()
    local id, now = creature:GetGUIDLow(), os.time()
    if pulledAt[id] and now - pulledAt[id] < 10 then return end    -- already pulled, it is about to vanish
    if need(player, Q_ROOTS, PLANT, 6) then
        pulledAt[id] = now
''')
sub('print("[Hara2] HARA2 V1 loaded', 'print("[Hara2] HARA2 V2 loaded')
lua = s.replace('\n', '\r\n').encode('utf-8')

SQL = u'''-- HARA2 V2 (2026-11-26, Claude) - candidate, NOT user-tested. WORLD database. Run after world_hara2.sql (V1). Safe to run twice.
-- Cause: a goober with Data3 (auto close, milliseconds) = 0 is never deactivated by the core, so Data5 (consumable) never acts.
-- Data3 = 1500: the first click counts, the object is locked, vanishes after 1.5 s and returns after its spawn time (30 s).
SET NAMES utf8mb4;
UPDATE `gameobject_template` SET `Data3` = 1500, `castBarCaption` = 'Clearing 清除中' WHERE `entry` = 553763;
UPDATE `gameobject_template` SET `castBarCaption` = 'Communing 交感中' WHERE `entry` IN (554679, 546728, 554848, 554966);
SELECT `entry`, `Data1` AS quest_must_be_90958, `Data3` AS must_be_1500, `Data5` AS must_be_1,
       (SELECT COUNT(*) FROM `gameobject` WHERE `id` = 553763 AND `spawntimesecs` = 30) AS spawns_expect_6_or_more
FROM `gameobject_template` WHERE `entry` = 553763;
'''
UNDO = u'''-- undo HARA2 V2 (back to V1 values)
SET NAMES utf8mb4;
UPDATE `gameobject_template` SET `Data3` = 0, `castBarCaption` = 'Burning 点燃中' WHERE `entry` IN (553763, 554679, 546728, 554848, 554966);
'''

README = u'''
# HARA2 V2：真菌点一次就消失(候选，实机未测)

在 HARA2 V1 之上的小修复，要先装好 V1。没有客户端文件。

## 改了什么
| 问题 | 原因 | 现在 |
|---|---|---|
| 入侵真菌能反复点，一株就能刷满 6/6 | 物体缺"自动收起时间"，服务端从不让它消失 | 点一次记 1 个，1.5 秒后消失，30 秒后刷新 |
| 枯萎植物在消失前连点可能记两次 | 脚本没有加锁 | 同一株只记一次 |
| 真菌和传承石的施法条文字是复制来的"点燃中" | 复制模板时漏改 | 改成清除中 / 交感中 |

## 部署(停服)
1. world 库执行 `01_服务端_SQL\\world_hara2_v2.sql`。读回：quest 90958、1500、1、刷新点至少 6。
2. `02_服务端_lua_scripts_覆盖\\Hara2.lua` 覆盖 `lua_scripts\\Hara2.lua`。
3. 启动服务端(控制台应有 `[Hara2] HARA2 V2 loaded`)。

以后如果重跑 V1 的 `world_hara2.sql`，要接着再跑一次本包 SQL。

## 测试
任务 90958：放弃后重接让计数归零。点一株真菌 → 计数 +1，约 1.5 秒后消失，30 秒后原地刷新；枯萎植物同样一株只加 1。

## 撤销
执行 `03_撤销\\undo_hara2_v2.sql`，把 `03_撤销\\Hara2.lua` 放回 `lua_scripts`，重启。
'''
MEMO = u'''
# HARA2 V2 记录(2026-11-26，Claude)
用户实机：任务 90958 的植物能一直点。原因：goober Data3=0 时核心不进入 GO_ACTIVATED，Data5 不生效。修复 Data3=1500；脚本给枯萎植物加锁。状态：候选，未实测。脚本 D:\\_zsdc\\hara\\build_hara2_v2.py。'''
TUTOR = u'''
# 大白话
"用完就消失"要两样一起设：多久收起(Data3)和收起后要不要消失(Data5)。只设后一样，物体永远等不到收起那一步。'''


def wr(rel, data):
    p = J(P, rel.replace('/', B))
    os.makedirs(os.path.dirname(p), exist_ok=True)
    assert not os.path.exists(p), p
    if isinstance(data, str):
        data = data.strip('\n').replace('\n', '\r\n').encode('utf-8-sig' if rel.endswith('.md') else 'utf-8') + b'\r\n'
    assert data.strip()
    open(p, 'wb').write(data)


# ---- checks before anything is written
db = sqlite3.connect(':memory:')
db.execute('create table gameobject_template(entry, Data1, Data3, Data5, castBarCaption)')
db.execute('create table gameobject(id, spawntimesecs)')
for e in (553763, 554679, 546728, 554848, 554966):
    db.execute("insert into gameobject_template values (?, ?, 0, ?, 'Burning 点燃中')", (e, 90958 if e == 553763 else 90960, int(e == 553763)))
for _ in range(8):
    db.execute('insert into gameobject values (553763, 30)')


def run(t):
    out = []
    body = '\n'.join(l for l in t.splitlines() if not l.startswith('--'))
    for q in body.split(';'):
        q = q.strip()
        if q and not q.startswith('SET NAMES'):
            out += db.execute(q).fetchall()
    return out


before = db.execute('select * from gameobject_template order by entry').fetchall()
r = run(SQL)
assert r == run(SQL) and r == [(553763, 90958, 1500, 1, 8)], r
run(UNDO)
assert db.execute('select * from gameobject_template order by entry').fetchall() == before
L = LuaRuntime(unpack_returned_tuples=True)
L.execute('''H={} CNT={} GONE=0
function RegisterCreatureGossipEvent(e,ev,f) H[e]=f end
function P() return {GossipComplete=function() end,HasQuest=function() return true end,GetReqKillOrCastCurrentCount=function(s,q,e) return CNT[e] or 0 end,
 KilledMonsterCredit=function(s,e) CNT[e]=(CNT[e] or 0)+1 end,SendBroadcastMessage=function() end} end
function C(id) return {GetGUIDLow=function() return id end,DespawnOrUnsummon=function() GONE=GONE+1 end,SendUnitSay=function() end} end''')
L.execute(lua.decode('utf-8'))
res = L.execute('''local p=P()
for i=1,5 do H[246277](1,p,C(1)) end
local same=CNT[246277]
for id=2,9 do H[246277](1,p,C(id)) H[246277](1,p,C(id)) end
H[245104](1,p,C(50))
return string.format("same plant %d, nine plants %d, vanished %d, outsider %d", same, CNT[246277], GONE, CNT[247257])''')
print(res)
assert res == 'same plant 1, nine plants 6, vanished 6, outsider 1', res

wr(u'01_服务端_SQL/world_hara2_v2.sql', SQL)
wr(u'02_服务端_lua_scripts_覆盖/Hara2.lua', lua)
wr(u'03_撤销/undo_hara2_v2.sql', UNDO)
wr(u'03_撤销/Hara2.lua', V1)
wr(u'README_覆盖与测试说明.md', README)
wr(u'memory.md', MEMO)
wr(u'tutor.md', TUTOR)
lines = []
for dp, _d, fn in os.walk(P):
    for fl in fn:
        p = J(dp, fl)
        lines.append('%s  %s' % (sha(open(p, 'rb').read()), os.path.relpath(p, P).replace(B, '/')))
wr('SHA256SUMS.txt', '\n'.join(sorted(lines, key=lambda x: x[66:])).encode('utf-8') + b'\n')


def app(path, text, key):
    t = open(path, 'rb').read()
    assert t.strip() and key.encode('utf-8') not in t, path
    e = '\r\n' if b'\r\n' in t else '\n'
    open(path, 'ab').write((('' if t.endswith(b'\n') else e) + e + text.replace('\n', e) + e).encode('utf-8'))
    assert open(path, 'rb').read().startswith(t) and key.encode('utf-8') in open(path, 'rb').read()


app(J(WS, u'协作说明_并行开发.md'), u'| 2026-11-26 | Claude | HARA2 V2：真菌点一次就消失 | 候选(实机未测) | world gameobject_template 553763(Data3、文字)与 554679/546728/554848/554966(文字)；lua_scripts/Hara2.lua | SQL 与脚本离线模拟通过；现场脚本与 V1 一致 | 000Ascendupdate20261126/claudefix_…HARA2_V2… | 重跑 V1 SQL 后需再跑 V2 |', u'HARA2 V2：真菌')
MD = r'<user-profile>\.claude\projects\d--000rebornWOW-000RebornWOWHighForkPRO-beascendLauncher-wowlauncher2026-CataLauncher-rebornWOW\memory'
for name, text in (('haranir-start-port.md', u'11-26 test: user found the 90958 fungi clickable forever -> HARA2 V2 (Data3=1500) delivered, untested.'),
                   ('harpy-batch-accepted-20261125.md', u'**Correction 2026-11-26:** the core never despawns a goober whose Data3 (auto close, ms) is 0, whatever Data5 says (GameObject::Use only enters GO_ACTIVATED when auto close > 0). For click-once objects set Data5=1 AND Data3>0 (e.g. 1500); no Lua needed. HARA2 V1 hit this (V2 fixes it).')):
    app(J(MD, name), text, text[:40])
print(P)
