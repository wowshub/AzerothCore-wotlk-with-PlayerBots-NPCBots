# -*- coding: utf-8 -*-
"""Walk the Horde chain with the core's XP formulas (1x rates): current data, then candidate settings."""
import json, io, sys
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
D = json.load(open(r'D:\_zsdc\cls\xp.json'))
XP = {int(k): v for k, v in D['xp'].items()}
need = {int(k): v for k, v in D['need'].items()}
Q = {int(k): v for k, v in D['quests'].items()}


def qxp(diff, qlevel, pl):
    ql = pl if qlevel == -1 else qlevel
    f = max(1, min(10, 2 * (ql - pl) + 20))
    x = f * XP[ql][diff] // 10
    step = 5 if x <= 100 else 10 if x <= 500 else 25 if x <= 1000 else 50
    return step * ((x + {5: 2, 10: 5, 25: 12, 50: 25}[step]) // step)


def kxp(pl, mob, elite, mod):
    base = pl * 5 + 45
    if mob >= pl:
        g = (base * (20 + min(4, mob - pl)) // 10 + 1) // 2
    else:
        gray = 0 if pl <= 5 else pl - 5 - pl // 10
        if mob <= gray:
            return 0
        zd = 5 if pl < 8 else 6 if pl < 10 else 7
        g = base * (zd + mob - pl) // zd
    return int(g * (2 if elite else 1) * mod)


# Horde chain in order: quest id, kills as (mob level, elite, count). Counts = objective kills plus the creatures met on the way.
CHAIN = [(59926, []), (59927, []), (59928, []), (59929, [(2, 0, 8)]), (59930, [(2, 0, 2)]), (59931, [(2, 0, 3)]), (59932, [(2, 0, 7)]), (59933, []), (59935, [(2, 0, 2)]),
         (59938, [(4, 0, 4), (3, 1, 1)]), (59940, []), (59941, [(3, 0, 2)]), (59942, [(2, 0, 6), (4, 1, 1)]), (59950, []), (59943, []), (59944, [(4, 0, 4), (5, 1, 1)]),
         (59945, [(4, 0, 10)]), (59946, [(4, 0, 4)]), (59947, []), (56839, [(9, 1, 1)]), (54933, [(4, 0, 2)]), (59948, []), (59949, [(4, 0, 8), (6, 1, 1)]), (59975, []),
         (59978, []), (59979, [(8, 0, 10)]), (59980, [(8, 0, 4)]), (59981, [(9, 1, 3), (8, 0, 4)]), (59984, [(9, 0, 7), (10, 1, 1), (11, 1, 1), (12, 1, 1)]), (59985, [])]


def run(qlevel=None, bonus=0, mod=1.0, quiet=True):
    pl, xp, qsum, ksum = 1, 0, 0, 0
    marks = {}

    def gain(v):
        nonlocal pl, xp
        xp += v
        while xp >= need[pl]:
            xp -= need[pl]
            pl += 1
    for q, kills in CHAIN:
        v = Q[q]
        for mob, elite, n in kills:
            for _ in range(n):
                k = kxp(pl, mob, elite, mod)
                ksum += k
                gain(k)
        r = qxp(min(8, v['diff'] + bonus), v['level'] if qlevel is None else qlevel, pl)
        qsum += r
        gain(r)
        marks[q] = pl
    return pl, xp, need[pl], qsum, ksum, marks


def show(tag, r):
    pl, xp, nx, qs, ks, m = r
    print('%-34s level %d (+%d/%d)  quest xp %d  kill xp %d | after beach %d, harpies %d, pit %d, before dungeon %d' % (tag, pl, xp, nx, qs, ks, m[59932], m[59946], m[59949], m[59981]))


show('now (quest level 1)', run())
for bonus in (0, 1, 2, 3):
    for mod in (1.0, 1.5, 2.0):
        show('quest -1, diff +%d, kill x%.1f' % (bonus, mod), run(-1, bonus, mod))
print('xp needed 1->10', sum(need[i] for i in range(1, 10)), [need[i] for i in range(1, 12)])
