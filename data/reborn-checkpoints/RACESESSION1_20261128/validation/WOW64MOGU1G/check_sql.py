from pathlib import Path
import re
import sqlite3

w=Path(__file__).resolve().parent
out=next(p for p in w.parent.glob('*WOW64MOGU1G*') if p.name.startswith('codexfix') and p.is_dir())
sql=(out/'04_WORLD/01_MOGU1G_WORLD.sql').read_text(encoding='utf8')
previous=w.parents[1]/'000Ascendupdate20261125/codexwork_WOW64MOGU1A/candidate/after/WORLD/01_MOGU1A_WORLD.sql'
base=w.parents[2]/'beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots/data/sql/base/db_world'
db=sqlite3.connect(':memory:')
db.executescript('''
CREATE TABLE playercreateinfo(race,class,map,zone,position_x,position_y,position_z,orientation,PRIMARY KEY(race,class));
CREATE TABLE player_race_stats(Race PRIMARY KEY,Strength,Agility,Stamina,Intellect,Spirit);
CREATE TABLE playercreateinfo_action(race,class,button,action,type,PRIMARY KEY(race,class,button));
CREATE TABLE playercreateinfo_item(race,class,itemid,amount,Note,PRIMARY KEY(race,class,itemid));
CREATE TABLE item_template(entry INTEGER PRIMARY KEY);
''')
for table in ('playercreateinfo','player_race_stats','playercreateinfo_action','playercreateinfo_item'):
    db.executescript(re.search(r'INSERT INTO .+?;', (base/f'{table}.sql').read_text(),re.S)[0])
pattern=r'INSERT INTO player\w+\(.+?;'
db.executescript('\n'.join(re.findall(pattern,previous.read_text(encoding='utf8'),re.S)))
ids=re.search(r"JSON_TABLE\('(\[[0-9, ]+\])'",sql)[1]
required_items=tuple(map(int,ids[1:-1].split(',')))
assert len(set(required_items))==16
db.executemany('INSERT INTO item_template VALUES (?)',[(x,) for x in required_items[:-1]])
missing_sql="""SELECT GROUP_CONCAT(entry) FROM
(SELECT j.value AS entry FROM json_each(?) j LEFT JOIN item_template item ON item.entry=j.value
 WHERE item.entry IS NULL ORDER BY j.value)"""
assert db.execute(missing_sql,(ids,)).fetchone()==(str(required_items[-1]),)
db.execute('INSERT INTO item_template VALUES (?)',(required_items[-1],))
assert db.execute(missing_sql,(ids,)).fetchone()==(None,)
assert all(item<900000 for item in required_items)
keep='WHERE race<>123 OR class NOT IN (3,7,11)'
before={t:db.execute(f'SELECT * FROM {t} {keep}').fetchall()
        for t in ('playercreateinfo','playercreateinfo_item','playercreateinfo_action')}
inserts='\n'.join(re.findall(pattern,sql,re.S)).replace('IN ((3,3),(11,7),(4,11))',
                    'IN (VALUES (3,3),(11,7),(4,11))')
db.executescript(inserts)
roster=db.execute('SELECT class,map FROM playercreateinfo WHERE race=123 ORDER BY class').fetchall()
assert roster==[(1,0),(2,0),(3,0),(4,0),(5,0),(6,609),(7,0),(8,0),(9,0),(11,0)]
assert all(db.execute(f'SELECT * FROM {t} {keep}').fetchall()==old for t,old in before.items())
print('PASS SQLite fixture: install with 16 stock items and zero custom items, exact missing-ID diagnostic, class and DK map unchanged')
