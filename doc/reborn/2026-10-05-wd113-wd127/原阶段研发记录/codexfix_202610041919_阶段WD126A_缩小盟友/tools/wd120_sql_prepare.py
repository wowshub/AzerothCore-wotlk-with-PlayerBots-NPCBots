from pathlib import Path
import shutil
import wd19_common as common
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');P=Path(Path('wd120_path.txt').read_text());B=Path(Path('wd119_path.txt').read_text());T=P/'tools'
common.S=R/'beascendserver/wowshub_playerbot_npcbot_newrace20260929Ascend'
for f in (B/'research').glob('*.tsv'):shutil.copy2(f,P/'research'/f.name)
for table in ['spell_bonus_data','spell_ranks']:
 raw=common.query('WorldDatabaseInfo','SHOW CREATE TABLE '+table+';')
 (P/'research'/('schema_'+table+'.tsv')).write_bytes(raw)
ids='9003864,9003865,9003866,9003867,9003870,9003871,9003872,9003873,9003874,9003875,9003876'
raw=common.query('WorldDatabaseInfo',f'SELECT spell_id,ScriptName FROM spell_script_names WHERE spell_id IN({ids}); SELECT entry,comments FROM spell_bonus_data WHERE entry IN({ids}); SELECT * FROM spell_ranks WHERE first_spell_id IN({ids}) OR spell_id IN({ids});')
(P/'research/reserved_ids_readonly.tsv').write_bytes(raw);print(raw.decode())
shutil.copytree(B/'rollback',P/'rollback',dirs_exist_ok=True)
s=(B/'tools/test_mysql.py').read_text(encoding='utf8').replace('_wd119_sql_scratch_','_wd120_sql_scratch_').replace('01_CHARACTERS_WD119A_必须执行.sql','01_CHARACTERS_WD120A_必须执行.sql').replace('84bit boundary refused','87bit boundary refused').replace('classbase+2**84','classbase+2**87')
s=s.replace('6525,12525);\');q(rollback)','6525,12525,4005,12645,12646);\');q(rollback)')
anchor=" before=q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id;')\n rollback="
block=''' for g in range(170,175):
  q(f"INSERT INTO characters(guid,account,name,taximask,innTriggerId,race,class,money) VALUES({g},10,'wd120test{g}','',0,1,13,10000000); INSERT INTO reborn_wd5a_builds(guid) VALUES({g}); INSERT INTO reborn_wd67_members(guid,enabled) VALUES({g},1); INSERT INTO reborn_wd13_slots(guid,slot,paid_copper) VALUES({g},0,0),({g},1,10000000); INSERT INTO reborn_wd16_profiles VALUES({g},0,0),({g},1,1),({g},2,3);")
 brewer=2**84;shrooms=2**85;toss=2**86;full=brewer+shrooms+toss
 ck('Brewing free nodes level14 no testpoints',save(170,0,full,14,slot=1)=='1')
 ck('All3 decoded exact',q('SELECT COUNT(*) FROM reborn_wd67_nodes WHERE guid=170 AND slot=1 AND node_id IN(4005,12645,12646)')=='3')
 ck('newbits not lost on saved repeat',save(170,1,full,14,slot=1)=='1')
 ck('no free removal of new nodes',save(170,2,brewer+shrooms,14,slot=1)=='0')
 ck('no cross spec free nodes',save(171,0,full,80,slot=0)=='0')
 ck('requires one parent',save(171,0,shrooms+toss,80,slot=1)=='0')
 ck('HealingWard OR parent accepted',save(171,0,1+shrooms+toss,14,slot=1)=='1')
 ck('Toss level13 rejected',save(172,0,full,13,slot=1)=='0')
 ck('Ingredient level10 accepted',save(172,0,brewer+shrooms,10,slot=1)=='1')
 ck('Toss later addition level14',save(172,1,full,14,slot=1)=='1')
 before120=q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id;SELECT * FROM reborn_wd13_slots ORDER BY guid,slot;')
 q(install);q(install);ck('new install repeat all nodes / purchases unchanged',before120==q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id;SELECT * FROM reborn_wd13_slots ORDER BY guid,slot;'))
 for table in ['spell_bonus_data','spell_ranks']:
  lines=(P/'research'/('schema_'+table+'.tsv')).read_text(encoding='utf8').splitlines();q(lines[1].split('\\t',1)[1].replace('\\\\n','\\n').replace('\\\\t','\\t'))
 newworld=(P/'server_SQL/03_WORLD_WD120A_必须执行.sql').read_text(encoding='utf8');q(newworld);q(newworld)
 ck('new World rank family 7',q('SELECT COUNT(*) FROM spell_ranks WHERE first_spell_id=9003870')=='7')
 ck('new World coefficient zero for exactly8 heals',q('SELECT COUNT(*) FROM spell_bonus_data WHERE entry IN(9003866,9003870,9003871,9003872,9003873,9003874,9003875,9003876) AND direct_bonus=0 AND dot_bonus=0')=='8')
 q("INSERT INTO spell_script_names VALUES(9003864,'unrelated_conflict')")
 ck('private id conflict refuses new World install',q(newworld,fail=True))
 q("DELETE FROM spell_script_names WHERE spell_id=9003864 AND ScriptName='unrelated_conflict'")
 q('UPDATE spell_bonus_data SET direct_bonus=1 WHERE entry=9003866')
 ck('coefficient conflict rejected',q(newworld,fail=True))
 q('UPDATE spell_bonus_data SET direct_bonus=0 WHERE entry=9003866')
'''
assert s.count(anchor)==1;s=s.replace(anchor,block+anchor)
(T/'test_mysql.py').write_text(s,encoding='utf8');print('isolated SQL fixture prepared')
