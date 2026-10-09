"""
DCP1A: quick look at dc_fights.jsonl (written by mod-reborn-bot-telemetry).
Prints each fight and a per-class/spec summary (DPS, HPS, damage taken/s, deaths).

usage: python summarize_fights.py <path to dc_fights.jsonl> [--boss-only]
"""
import json
import sys
from collections import defaultdict

CLASS = {1: "战士", 2: "圣骑士", 3: "猎人", 4: "盗贼", 5: "牧师", 6: "死亡骑士", 7: "萨满",
         8: "法师", 9: "术士", 11: "德鲁伊", 13: "巫医", 14: "武僧"}

path = sys.argv[1]
boss_only = "--boss-only" in sys.argv
fights = []
for n, line in enumerate(open(path, encoding="utf-8"), 1):
    line = line.strip()
    if not line:
        continue
    try:
        fights.append(json.loads(line))
    except ValueError as e:
        print(f"第 {n} 行不是合法 JSON：{e}")
if boss_only:
    fights = [f for f in fights if f.get("bossEntry")]

agg = defaultdict(lambda: {"n": 0, "dmg": 0, "heal": 0, "taken": 0, "sec": 0.0, "deaths": 0, "ilvl": 0})
for f in fights:
    sec = f["durationMs"] / 1000.0
    tag = f["bossName"] or f"小怪x{f['enemies']}"
    print(f"\n地图 {f['mapId']}  {tag}  {sec:.0f}s  {'团灭' if f['wipe'] else '胜利'}")
    for m in f["members"]:
        cls = CLASS.get(m["class"], f"class{m['class']}")
        role = m["role"]
        # schema 2: role comes from the bot's strategies; note when talents disagree or it also heals
        if m.get("specRole") and m["specRole"] != role:
            role += f"(天赋:{m['specRole']})"
        if m.get("heal") and m["role"] != "heal":
            role += "+治疗"
        print(f"  {m['name']:<14}{cls}/天赋{m['specTab']} {role:<4} {'bot' if m['bot'] else '真人'} "
              f"ilvl{m['ilvl']:>4}  DPS {m['dmgDone'] / sec:>7.0f}  HPS {m['healDone'] / sec:>6.0f}  "
              f"承伤/s {m['dmgTaken'] / sec:>6.0f}  死亡 {m['deaths']}  <50%血 {m['lowHpMs'] / 1000:.0f}s")
        a = agg[(cls, m["specTab"], m["role"])]
        a["n"] += 1
        a["dmg"] += m["dmgDone"]
        a["heal"] += m["healDone"]
        a["taken"] += m["dmgTaken"]
        a["sec"] += sec
        a["deaths"] += m["deaths"]
        a["ilvl"] += m["ilvl"]

print(f"\n==== 汇总（{len(fights)} 场战斗{'，仅首领' if boss_only else ''}）====")
for (cls, spec, role), a in sorted(agg.items(), key=lambda kv: -kv[1]["dmg"] / max(kv[1]["sec"], 1)):
    print(f"{cls}/天赋{spec} {role:<4} 场次{a['n']:>4}  平均ilvl {a['ilvl'] / a['n']:.0f}  "
          f"DPS {a['dmg'] / a['sec']:>7.0f}  HPS {a['heal'] / a['sec']:>6.0f}  "
          f"承伤/s {a['taken'] / a['sec']:>6.0f}  死亡 {a['deaths']}")
