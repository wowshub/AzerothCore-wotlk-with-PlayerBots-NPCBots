# -*- coding: utf-8 -*-
"""Collect every island quest from the archived SQL and simulate how far one character levels, with the core's own XP formulas."""
import re, glob, io, sys, json, os, struct
sys.path.insert(0, r'D:\_zsdc\wow12x')
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
from sqlrows import split_rows
REL = r'D:\000rebornWOW\000RebornWOWHighForkPRO\beascendcode\claude-release-20261126\data'
SRV = r'D:\000rebornWOW\000RebornWOWHighForkPRO\beascendserver\wowshub_playerbot_npcbot_newrace20261122Ascend\Data\dbc'
d = open(os.path.join(SRV, 'QuestXP.dbc'), 'rb').read()
n, nf, rs, ss = struct.unpack('<4I', d[4:20])
XP = {r[0]: r[1:] for r in (struct.unpack_from('<%dI' % nf, d, 20 + i * rs) for i in range(n))}
need = {}
for line in open(os.path.join(REL, 'sql', 'base', 'db_world', 'player_xp_for_level.sql'), encoding='utf-8'):
    if line.startswith('('):
        for r in split_rows(line):
            need[int(r[0])] = int(r[1])
quests, mobs = {}, {}
files = sorted(glob.glob(os.path.join(REL, 'customfixsql', 'world', 'exiles-reach', '*.sql')))
unq = lambda v: v.strip().strip("'").replace("''", "'")


def inserts(s, table):
    for m in re.finditer(r"INSERT INTO `%s` \(([^)]*)\) VALUES" % table, s):
        cols = [c.strip(' `\r\n') for c in m.group(1).split(',')]
        pos = m.end()
        # statement ends at the first ';' outside quotes
        inq, i = False, pos
        while i < len(s):
            ch = s[i]
            if ch == "'":
                inq = not inq
            elif ch == ';' and not inq:
                break
            i += 1
        for row in split_rows(s[pos:i]):
            if len(row) == len(cols):
                yield dict(zip(cols, (x.strip() for x in row)))


for f in files:
    s = open(f, encoding='utf-8').read()
    for r in inserts(s, 'quest_template'):
        q = int(r['ID'])
        quests.setdefault(q, {}).update(title=unq(r.get('LogTitle', '')), level=int(r['QuestLevel']), diff=int(r['RewardXPDifficulty']), file=os.path.basename(f))
        for k in range(1, 5):
            if r.get('RequiredNpcOrGo%d' % k, '0') not in ('0', None):
                quests[q].setdefault('npc', {})[k] = (int(r['RequiredNpcOrGo%d' % k]), int(r.get('RequiredNpcOrGoCount%d' % k, 1)))
        for k in range(1, 7):
            if r.get('RequiredItemId%d' % k, '0') not in ('0', None):
                quests[q].setdefault('item', {})[k] = (int(r['RequiredItemId%d' % k]), int(r.get('RequiredItemCount%d' % k, 1)))
    for r in inserts(s, 'quest_template_addon'):
        quests.setdefault(int(r['ID']), {})['prev'] = int(r.get('PrevQuestID', 0))
    for m in re.finditer(r"UPDATE `quest_template` SET (.*?) WHERE `ID` = (\d+);", s, re.S):
        q = int(m.group(2))
        sets = dict(re.findall(r"`(\w+)` = (-?\d+)", m.group(1)))
        for k in range(1, 5):
            if 'RequiredNpcOrGo%d' % k in sets:
                quests.setdefault(q, {}).setdefault('npc', {})[k] = (int(sets['RequiredNpcOrGo%d' % k]), int(sets.get('RequiredNpcOrGoCount%d' % k, 1)))
        for k in range(1, 7):
            if 'RequiredItemId%d' % k in sets:
                quests.setdefault(q, {}).setdefault('item', {})[k] = (int(sets['RequiredItemId%d' % k]), int(sets.get('RequiredItemCount%d' % k, 1)))
        for col, key in (('QuestLevel', 'level'), ('RewardXPDifficulty', 'diff')):
            if col in sets:
                quests.setdefault(q, {})[key] = int(sets[col])
    for r in inserts(s, 'creature_template'):
        mobs[int(r['entry'])] = dict(level=(int(r['minlevel']) + int(r['maxlevel'])) / 2, rank=int(r.get('rank', 0)), faction=int(r.get('faction', 35)), name=unq(r.get('name', '')))
quests = {q: v for q, v in quests.items() if 'level' in v}
print('quests', len(quests), 'levels', sorted({v['level'] for v in quests.values()}), 'difficulties', sorted({v['diff'] for v in quests.values()}))
json.dump(dict(quests=quests, mobs=mobs, need=need, xp=XP), open(r'D:\_zsdc\cls\xp.json', 'w'))
for q, v in sorted(quests.items()):
    print(q, v.get('prev'), v['diff'], v.get('npc', ''), v.get('item', ''), v['title'][:28])
