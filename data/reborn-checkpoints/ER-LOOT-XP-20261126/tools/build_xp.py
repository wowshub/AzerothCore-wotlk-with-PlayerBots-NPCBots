# -*- coding: utf-8 -*-
"""XP1A V1: island quests scale with the player and pay more; island monsters give double kill experience."""
import os, io, sys, json, hashlib
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
exec(open(r'D:\_zsdc\cls\xpsim2.py', encoding='utf-8').read().replace("sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')\n", '').split("show('now (quest level 1)'")[0])
B = chr(92)
WS = r'D:\000rebornWOW\000RebornWOWHighForkPRO'
DAY = os.path.join(WS, '000Ascendupdate', '000Ascendupdate20261126')
NAME = 'claudefix_20261126_阶段XP1A_V1_流放者之岛任务和怪物经验提高到出岛约10级_Claude'
P = os.path.join(DAY, NAME)
assert not os.path.exists(P)
BONUS, MOD = 2, 2.0
# Alliance quests that were cloned from a Horde quest in SQL keep the source difficulty
CLONES = {55122: 59929, 54951: 59930, 54952: 59931, 55174: 59932, 59254: 59933, 55173: 59935, 55186: 59938, 55184: 59938, 55193: 59940, 56034: 59941, 55879: 59942}
diff = {q: v['diff'] for q, v in Q.items()}
for a, h in CLONES.items():
    assert a not in diff
    diff[a] = diff[h]
HOSTILE = [150228, 150229, 150238, 151091, 152843, 153239, 153266, 153581, 153582, 153583, 153964, 156501, 156814, 156900, 157300, 160394, 160433,
           161130, 161131, 161133, 162817, 165150, 9159801, 9159802, 9159803]
now, new = run(), run(-1, BONUS, MOD)
by = {}
for q, d in diff.items():
    by.setdefault(min(8, d + BONUS), []).append(q)
ids = ', '.join(map(str, sorted(diff)))
mobs = ', '.join(map(str, HOSTILE))
sql = ['-- XP1A V1 (2026-11-26, Claude): more experience on Exile\'s Reach. Safe to run twice (values are fixed, not added).',
       '-- Rerunning any island quest SQL puts those quests back to level 1: run this file again afterwards.',
       'SELECT (SELECT COUNT(*) FROM `quest_template` WHERE `ID` IN (%s)) AS quests_found_%d,' % (ids, len(diff)),
       '       (SELECT COUNT(*) FROM `creature_template` WHERE `entry` IN (%s)) AS monsters_found_%d;' % (mobs, len(HOSTILE))]
sql += ['UPDATE `quest_template` SET `QuestLevel` = -1, `RewardXPDifficulty` = %d WHERE `ID` IN (%s);' % (d, ', '.join(map(str, sorted(v)))) for d, v in sorted(by.items())]
sql += ['UPDATE `creature_template` SET `ExperienceModifier` = %s WHERE `entry` IN (%s);' % (MOD, mobs),
        'SELECT (SELECT COUNT(*) FROM `quest_template` WHERE `ID` IN (%s) AND `QuestLevel` = -1) AS quests_scaling_%d,' % (ids, len(diff)),
        '       (SELECT COUNT(*) FROM `creature_template` WHERE `entry` IN (%s) AND `ExperienceModifier` = %s) AS monsters_double_%d;' % (mobs, MOD, len(HOSTILE))]
old = {}
for q, d in diff.items():
    old.setdefault(d, []).append(q)
undo = ['-- undo XP1A V1'] + ['UPDATE `quest_template` SET `QuestLevel` = 1, `RewardXPDifficulty` = %d WHERE `ID` IN (%s);' % (d, ', '.join(map(str, sorted(v)))) for d, v in sorted(old.items())]
undo.append('UPDATE `creature_template` SET `ExperienceModifier` = 1 WHERE `entry` IN (%s);' % mobs)


def wr(rel, data, nl='\n'):
    f = os.path.join(P, rel.replace('/', B))
    os.makedirs(os.path.dirname(f), exist_ok=True)
    open(f, 'w', encoding='utf-8', newline=nl).write(data)


sha = lambda p: hashlib.sha256(open(p, 'rb').read()).hexdigest()
wr('01_服务端_SQL/world_xp1a.sql', '\n'.join(sql) + '\n', '\r\n')
wr('02_撤销/undo_xp1a.sql', '\n'.join(undo) + '\n', '\r\n')
m = new[5]
wr('README_覆盖与测试说明.md', '''# XP1A V1：流放者之岛经验提高，做完约 10 级

状态：候选，游戏里未测。只改服务端数据库。可以和 LOOT1A 一起装，顺序不限。

## 原因
移植时岛上任务的等级全部写成 1 级，角色一高于 1 级，任务经验就按比例打折，到后面几乎没有。打怪经验本身是正常的。

## 改动
- %d 个岛上任务改为"随玩家等级"(QuestLevel -1)，经验档位提高 2 档(最高 8)。
- 岛上 %d 种怪的击杀经验 ×%s(头目原本就按精英翻倍)。

## 估算(按核心公式、1 倍经验率、单人模拟部落线)
| 进度 | 改之前 | 改之后 |
|---|---|---|
| 海滩营地做完 | %d 级 | %d 级 |
| 鹰身人区做完 | %d 级 | %d 级 |
| 深坑做完 | %d 级 | %d 级 |
| 进副本前 | %d 级 | %d 级 |
| 全部做完 | %d 级 | %d 级(再升到下一级进度 %d/%d) |

只算了任务目标和沿途少量怪；多打怪会更高，带队友(机器人/NPCBot)分经验会更低。服务器如果设了经验倍率(配置或 Custom_XP.lua)，结果按倍率变化。联盟线结构相同，没有单独模拟。

## 部署
1. 停 worldserver。
2. world 库执行 `01_服务端_SQL/world_xp1a.sql`。开头读回 quests %d、monsters %d；末尾读回 quests_scaling %d、monsters_double %d。
3. 启动 worldserver，删客户端 `Cache/WDB`(任务等级有缓存)。

以后重跑任何岛上任务 SQL，要接着再跑本包。

## 测试
新建 1 级角色从船上开始做，看交任务的经验、打怪经验，出岛时几级。偏高或偏低告诉我，只需要改两个数。

## 撤销
执行 `02_撤销/undo_xp1a.sql`，重启。
''' % (len(diff), len(HOSTILE), MOD, now[5][59932], m[59932], now[5][59946], m[59946], now[5][59949], m[59949], now[5][59981], m[59981], now[0], new[0], new[1], new[2],
       len(diff), len(HOSTILE), len(diff), len(HOSTILE)))
wr('memory.md', '''# memory - XP1A V1 (2026-11-26, Claude, 候选未测)
- 用户：怪物除了金币装备还要给经验；希望出岛约 10 级去暴风城/奥格接职业任务。
- 任务 QuestLevel=1 导致经验打折。改 -1、档位 +2、怪 ExperienceModifier 2。脚本 D:\\_zsdc\\cls\\(xpsim.py、xpsim2.py、build_xp.py)。
''')
wr('tutor.md', '''# tutor - 移植任务的经验 (XP1A V1, 未实测)
QuestLevel 决定经验打折：写死 1 级会让后面的任务几乎没经验。新移植任务线用 -1 或按进度给等级，并用核心公式先算一遍出口等级。
''')
lines = []
for dp, dn, fn in os.walk(P):
    for f in sorted(fn):
        p = os.path.join(dp, f)
        lines.append('%s  %s' % (sha(p), os.path.relpath(p, P).replace(B, '/')))
wr('SHA256SUMS.txt', '\n'.join(lines) + '\n')
log = os.path.join(WS, '协作说明_并行开发.md')
t = open(log, 'rb').read()
assert 'XP1A V1(' not in t.decode('utf-8', 'replace')
e = b'\r\n' if b'\r\n' in t else b'\n'
row = '| 2026-11-26 | Claude | XP1A V1(流放者之岛任务经验与击杀经验) | 候选(实机未测) | 仅服务端 world SQL(quest_template 等级/经验档、creature_template ExperienceModifier) | 基线：ER-ALLIANCE-20261126 | 包 000Ascendupdate20261126/%s | 无共享客户端文件 |' % NAME
open(log, 'ab').write((b'' if t.endswith(b'\n') else e) + row.encode('utf-8') + e)
M = r'C:\Users\beyourself\.claude\projects\d--000rebornWOW-000RebornWOWHighForkPRO-beascendLauncher-wowlauncher2026-CataLauncher-rebornWOW\memory\er-both-factions-pushed-20261126.md'
assert open(M, encoding='utf-8').read().strip()
open(M, 'a', encoding='utf-8').write(u"\n2026-11-26 (later): user proposes class quests at ~10 in Stormwind/Orgrimmar instead of porting island ones. Built XP1A V1 (quest level -1, +2 XP difficulty, kill x2; sim 6 -> 10), untested. Stock base DB: city class quests exist for warlock/warrior(A)/rogue/mage, paladin 12 (human/dwarf), hunter/druid/most shaman lead elsewhere, priest none; AllowableRaces 1101/690 exclude custom races (offer SQL). Script D:\\_zsdc\\cls\\classq.py.\n")
print(len(diff), 'quests', len(HOSTILE), 'monsters; end level', now[0], '->', new[0])
