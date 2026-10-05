from pathlib import Path
import re, sys
from wd19_common import dbc

P = Path(__file__).resolve().parents[1]
B = Path(Path("D:/000rebornWOW/wd123b_path.txt").read_text().strip())
R = Path("D:/000rebornWOW/000RebornWOWHighForkPRO")
fmt_text = (R / "beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots/src/server/shared/DataStores/DBCfmt.h").read_text()
fmt = re.search(r'SpellEntryfmt\[\]\s*=\s*"([^"]+)"', fmt_text)[1]
expected = {
    9003897: [(6, 107, -5001, 11, 0)],
    9003898: [(6, 134, 49, 0, 0)],
    9003899: [(6, 136, 9, 127, 0), (6, 134, 49, 0, 0)],
    9003900: [(6, 220, 9, 1024, 4)],
}
for pref in ["03_覆盖到服务端根目录/Data/dbc", "client_mpq输入_导入现有Patch-XA/DBFilesClient"]:
    for name in ["Spell", "SkillLineAbility"]:
        old, old_pool = dbc((B / pref / (name + ".dbc")).read_bytes())
        new, new_pool = dbc((P / pref / (name + ".dbc")).read_bytes())
        assert set(new) - set(old) == (set(expected) if name == "Spell" else set(new) - set(old))
        assert all(new[k] == v for k, v in old.items()), (pref, name, "old row changed")
        assert new_pool.startswith(old_pool)
        if name == "Spell":
            for sid, effects in expected.items():
                row = new[sid]
                for i, (effect, aura, amount, misc, misc_b) in enumerate(effects):
                    assert row[71+i] == effect
                    assert row[95+i] == aura
                    assert row[80+i] == amount & 0xffffffff
                    assert row[86+i] == 1
                    assert row[110+i] == misc
                    assert row[113+i] == misc_b
                assert all(row[71+i] == 0 for i in range(len(effects), 3))
                assert row[29] == old[9003877][29] and row[30] == old[9003877][30]
            for sid, row in new.items():
                for i, kind in enumerate(fmt):
                    if kind == "s":
                        assert row[i] < len(new_pool) and new_pool.find(b"\0", row[i]) >= 0, (pref, sid, i)
        else:
            assert all(sum(row[2] == sid and row[1] == 9005 for row in new.values()) == 1 for sid in expected)
print("PASS WD124 old DBC rows, four passive spell rows, book rows and string offsets")
