# coding: utf-8
from pathlib import Path
import subprocess,socket,time,json,datetime
P=Path(__file__).resolve().parents[1];R=P.parents[2];D=R/'000Ascendupdate/000Ascendupdate20260929';B=next(x for x in D.glob('*WD86A*')if x.is_dir());B88=next(x for x in D.glob('*WD88A*')if x.is_dir())
base=R/'beascendserver/wowshub_playerbot_npcbot_newrace20261007Ascend/mysql-8.0.31-winx64'
data=Path('D:/000rebornWOW')/('_wd136_sql_scratch_'+datetime.datetime.now().strftime('%Y%m%d%H%M%S'));data.mkdir();port=33536
s=socket.socket();s.bind(('127.0.0.1',port));s.close();(P/'checks').mkdir(exist_ok=True)
log=(P/'checks/mysql.log').open('w');args=[str(base/'bin/mysqld.exe'),'--no-defaults','--basedir='+str(base),'--datadir='+str(data)]
assert subprocess.run(args+['--initialize-insecure','--console'],stdout=log,stderr=log,creationflags=subprocess.CREATE_NO_WINDOW,timeout=300).returncode==0
cli=[str(base/'bin/mysql.exe'),'--no-defaults','--protocol=TCP','-h127.0.0.1','-P'+str(port),'-uroot','--default-character-set=utf8mb4','--batch','--skip-column-names']
checks=[];proc=None;verified=False
def q(sql,use=True,fail=False):
 p=subprocess.run(cli+(['wd100']if use else []),input=sql,encoding='utf8',capture_output=True,timeout=30)
 with (P/'checks/sql_trace.jsonl').open('a',encoding='utf8') as tr: tr.write(json.dumps({'sql':sql,'out':p.stdout,'err':p.stderr,'returncode':p.returncode},ensure_ascii=False)+'\n')
 if fail:return p.returncode!=0
 assert p.returncode==0,p.stderr
 return p.stdout.strip()
def ck(n,c):
 if not c: print("FAILED",n,q("SELECT * FROM reborn_wd67_nodes WHERE guid IN(9,16);"),q("SELECT guid,revision FROM reborn_wd5a_builds WHERE guid IN(9,16,160); SELECT * FROM reborn_wd95_test_points WHERE guid=160;"))
 assert c,n
 checks.append(n)
def schema(t):
 b=B88 if t=='spell_script_names' else B
 l=[s for s in (b/'research'/('schema_'+t+'.tsv')).read_text(encoding='utf8').splitlines() if s.strip()]
 return l[1].split('\t',1)[1].replace('\\n','\n').replace('\\t','\t')+';'
B93=next(x for x in D.glob('*WD93A*')if x.is_dir())
try:
 proc=subprocess.Popen(args+['--port='+str(port),'--bind-address=127.0.0.1','--mysqlx=OFF','--innodb-buffer-pool-size=32M','--console'],stdout=log,stderr=log,creationflags=subprocess.CREATE_NO_WINDOW)
 for _ in range(100):
  try:assert Path(q('SELECT @@datadir;',False)).resolve()==data.resolve();verified=True;break
  except (AssertionError,subprocess.TimeoutExpired):time.sleep(.2)
 assert verified
 q('CREATE DATABASE wd100;',False)
 for t in ['characters','reborn_wd5a_builds','reborn_wd67_members','reborn_wd67_nodes','reborn_wd67_budget','reborn_wd13_slots','reborn_wd16_profiles','spell_script_names']:q(schema(t))
 budget=[l.split()for l in (B/'research/budget.tsv').read_text().splitlines()if l.strip()][1:]
 q('INSERT INTO reborn_wd67_budget(level,ae,te) VALUES '+','.join('('+','.join(r)+')'for r in budget)+';')
 q((B93/'server_SQL/01_CHARACTERS_WD93A.sql').read_text(encoding='utf8'))
 install=(P/'server_SQL/01_CHARACTERS_WD136A_必须执行.sql').read_text(encoding='utf8');q(install);q(install);ck('repeat install no automatic bonus',q('SELECT COUNT(*) FROM reborn_wd95_test_points')=='0')
 world=(P/'server_SQL/05_WORLD_WD125A_必须执行.sql').read_text(encoding='utf8')
 q(world);q(world)
 ck('125 World bindings idempotent',q("SELECT COUNT(*) FROM spell_script_names WHERE spell_id IN(9003901,9003905) AND ScriptName='spell_reborn_wd120_brewing'")=='2')
 for g in range(1,35):q(f"INSERT INTO characters(guid,account,name,taximask,innTriggerId,race,class,money) VALUES({g},10,'wd96test{g}','',0,1,13,10000000); INSERT INTO reborn_wd5a_builds(guid) VALUES({g}); INSERT INTO reborn_wd67_members(guid,enabled) VALUES({g},1); INSERT INTO reborn_wd13_slots(guid,slot,paid_copper) VALUES({g},0,0),({g},1,0); INSERT INTO reborn_wd16_profiles VALUES({g},0,0),({g},1,1),({g},2,3);")
 def grant(g,rev,ae=20,te=20,account=10):return q(f'CALL reborn_wd95_testpoints({g},{account},{rev},{ae},{te});')
 def save(g,rev,mask,level=80,slot=0,account=10):return q(f'CALL reborn_wd67_save({g},{account},{rev},{slot},{mask},{level});')

 brewer=2**84;mix=2**100;peace=2**101;earth=2**102
 foundation=2*2**55+2*2**57+2*2**59+2**62+2**64
 ck('Mixologist saves bit100',save(1,0,brewer+mix,11,slot=1)=='1')
 ck('Mixologist repeat',save(1,1,brewer+mix,11,slot=1)=='1')
 ck('No free new-point refund',save(1,2,brewer,11,slot=1)=='0')
 ck('Stale revision rejected',save(1,1,brewer+mix,11,slot=1)=='2')
 ck('Wrong account rejected',save(1,2,brewer+mix,11,slot=1,account=11)=='0')
 ck('Missing brewer rejected',save(2,0,mix,80,slot=1)=='0')
 ck('Wrong spec rejected',save(2,0,brewer+mix,80,slot=0)=='0')
 ck('Unknown bit117 rejected',save(2,0,2**117,80,slot=1)=='0')
 ck('Level9 rejected',save(2,0,brewer+mix,9,slot=1)=='0')
 for g,spice,nid in [(3,peace,4112),(4,earth,7130)]:
  m=brewer+foundation+mix+spice
  ck('Spice exact save '+str(nid),save(g,0,m,80,slot=1)=='1')
  ck('Spice repeat '+str(nid),save(g,1,m,80,slot=1)=='1')
  ck('Spice row '+str(nid),q(f'SELECT node_rank FROM reborn_wd67_nodes WHERE guid={g} AND node_id={nid}')=='1')
  ck('Spice refund rejected '+str(nid),save(g,2,m-spice,80,slot=1)=='0')
  ck('Spice foundation rejected '+str(nid),save(5,0,brewer+spice,80,slot=1)=='0')
  ck('Mix cannot bootstrap old foundation '+str(nid),save(5,0,m-2**62,80,slot=1)=='0')
  ck('Choice cannot replace paid choice '+str(nid),save(g,2,m-spice+(earth if spice==peace else peace),80,slot=1)=='0')
 ck('Both choices rejected',save(5,0,brewer+foundation+peace+earth,80,slot=1)=='0')
 before=q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id');q(install)
 ck('Repeated upgrade preserves rows',before==q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id'))
 ck('Old tier99 saves',save(6,0,brewer+foundation+2**99,80,slot=1)=='1')
 ck('Old and new points save',save(6,1,brewer+foundation+2**99+earth,80,slot=1)=='1')
 ck('Old paid point cannot refund',save(6,2,brewer+foundation+earth,80,slot=1)=='0')
 q('DELETE FROM reborn_wd67_nodes WHERE guid=3;')
 ck('Opposite choice after isolated reset',save(3,2,brewer+foundation+earth,80,slot=1)=='1')

 # New nodes: real stored-procedure round-trip, no free refunds, preserved legacy masks.
 for g,bit,node in [(7,103,6021),(8,104,6014)]:
  m=brewer+foundation+2**bit
  ck('WD129 saves node '+str(node),save(g,0,m,80,slot=1)=='1')
  ck('WD129 row '+str(node),q(f'SELECT node_rank FROM reborn_wd67_nodes WHERE guid={g} AND node_id={node}')=='1')
  ck('WD129 repeat '+str(node),save(g,1,m,80,slot=1)=='1')
  ck('WD129 refund denied '+str(node),save(g,2,brewer+foundation,80,slot=1)=='0')
  ck('WD129 wrong spec '+str(node),save(9,0,m,80,slot=0)=='0')
  ck('WD129 prerequisite '+str(node),save(9,0,foundation+2**bit,80,slot=1)=='0')
  ck('WD129 missing brewer '+str(node),save(9,0,m-brewer,80,slot=1)=='0')
  ck('WD129 foundation '+str(node),save(9,0,brewer+2**bit,80,slot=1)=='0')
  ck('WD129 cannot bootstrap '+str(node),save(9,0,m-2**62,80,slot=1)=='0')
  ck('WD129 level gate '+str(node),save(9,0,m,9,slot=1)=='0')
 both=brewer+foundation+mix+earth+2**103+2**104
 ck('WD128 plus both WD129 nodes',save(10,0,both,80,slot=1)=='1')
 ck('WD129 persisted both nodes',q('SELECT COUNT(*) FROM reborn_wd67_nodes WHERE guid=10 AND node_id IN(6021,6014)')=='2')
 before=q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id');q(install)
 ck('WD129 repeated install preserves all saved points',before==q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id'))
 q('CREATE TABLE spell_bonus_data(entry MEDIUMINT UNSIGNED NOT NULL PRIMARY KEY,direct_bonus FLOAT NOT NULL DEFAULT 0,dot_bonus FLOAT NOT NULL DEFAULT 0,ap_bonus FLOAT NOT NULL DEFAULT 0,ap_dot_bonus FLOAT NOT NULL DEFAULT 0,comments VARCHAR(255));')
 newworld=(P/'server_SQL/07_WORLD_WD129A_必须执行.sql').read_text(encoding='utf8');q(newworld);q(newworld)
 ck('WD129 world three bindings',q('SELECT COUNT(*) FROM spell_script_names WHERE spell_id IN(9003915,9003917,9003918)')=='3')
 ck('WD129 leech coefficients zero',q('SELECT direct_bonus+dot_bonus+ap_bonus+ap_dot_bonus FROM spell_bonus_data WHERE entry=9003919')=='0')
 before=q('SELECT * FROM spell_script_names ORDER BY spell_id,ScriptName')
 q("UPDATE spell_bonus_data SET comments='foreign' WHERE entry=9003919")
 ck('WD129 foreign coefficient rejected',q(newworld,fail=True))
 ck('WD129 conflict fails before binding writes',before==q('SELECT * FROM spell_script_names ORDER BY spell_id,ScriptName'))
 q('UPDATE spell_bonus_data SET comments=NULL WHERE entry=9003919')
 ck('WD129 NULL coefficient owner rejected',q(newworld,fail=True))
 q("UPDATE spell_bonus_data SET comments='WD129 test' WHERE entry=9003919;INSERT INTO spell_script_names VALUES(9003915,'foreign_script')")
 ck('WD129 foreign binding rejected',q(newworld,fail=True))
 # WD130: exact SQL persistence and prerequisites, with fresh identities.
 parent=brewer+foundation+2**89
 for g,bit,node in [(17,105,30823),(18,107,6013)]:
  m=parent+2**bit
  ck('WD130 save '+str(node),save(g,0,m,80,slot=1)=='1')
  ck('WD130 row '+str(node),q(f'SELECT node_rank FROM reborn_wd67_nodes WHERE guid={g} AND node_id={node}')=='1')
  ck('WD130 repeat '+str(node),save(g,1,m,80,slot=1)=='1')
  ck('WD130 refund '+str(node),save(g,2,parent,80,slot=1)=='0')
  ck('WD130 wrong spec '+str(node),save(19,0,m,80,slot=0)=='0')
  ck('WD130 missing parent '+str(node),save(19,0,m-2**89,80,slot=1)=='0')
 ck('WD130 Beam below29',save(19,0,parent+2**105,28,slot=1)=='0')
 ck('WD130 Bottle choice',save(19,0,parent+2**107+2**65,80,slot=1)=='0')
 splash=brewer+foundation+2**92+2**106
 ck('WD130 splash node save',save(19,0,splash,80,slot=1)=='1')
 ck('WD130 missing Splash rejected',save(20,0,splash-2**92,80,slot=1)=='0')
 full=parent+2**92+2**105+2**106+2**107
 ck('WD130 three-node save',save(20,0,full,80,slot=1)=='1')
 ck('WD130 three rows',q('SELECT COUNT(*) FROM reborn_wd67_nodes WHERE guid=20 AND node_id IN(30823,6022,6013)')=='3')
 before=q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id');q(install)
 ck('WD130 reinstall preserves all rows',before==q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id'))
 world130=(P/'server_SQL/08_WORLD_WD130A_必须执行.sql').read_text(encoding='utf8');q(world130);q(world130)
 ck('WD130 15 World bindings',q('SELECT COUNT(*) FROM spell_script_names WHERE spell_id BETWEEN 9003922 AND 9003932')=='15')
 ck('WD130 coefficient zero',q('SELECT direct_bonus+dot_bonus+ap_bonus+ap_dot_bonus FROM spell_bonus_data WHERE entry=9003932')=='0')
 before=q('SELECT * FROM spell_script_names ORDER BY spell_id,ScriptName')
 q("UPDATE spell_bonus_data SET comments=NULL WHERE entry=9003932")
 ck('WD130 foreign null coefficient rejected',q(world130,fail=True));ck('WD130 guard precedes writes',before==q('SELECT * FROM spell_script_names ORDER BY spell_id,ScriptName'))

 for g,bit,node,partner in [(21,108,6016,97),(22,109,6009,103)]:
  m=brewer+foundation+2**85+2**partner+2**bit
  ck('WD131 exact save '+str(node),save(g,0,m,80,slot=1)=='1')
  ck('WD131 repeat '+str(node),save(g,1,m,80,slot=1)=='1')
  ck('WD131 stored '+str(node),q(f'SELECT node_rank FROM reborn_wd67_nodes WHERE guid={g} AND node_id={node}')=='1')
  ck('WD131 no refund '+str(node),save(g,2,m-2**bit,80,slot=1)=='0')
  ck('WD131 missing partner '+str(node),save(16,0,m-2**partner,80,slot=1)=='0')
  ck('WD131 missing shrooms '+str(node),save(16,0,m-2**85,80,slot=1)=='0')
  ck('WD131 wrong spec '+str(node),save(16,0,m,80,slot=0)=='0')
  ck('WD131 no bootstrap '+str(node),save(16,0,m-2**62,80,slot=1)=='0')
  ck('WD131 level9 '+str(node),save(16,0,m,9,slot=1)=='0')
 full=brewer+foundation+2**85+2**97+2**103+2**108+2**109
 ck('WD131 both Mojos',save(16,0,full,80,slot=1)=='1')
 before=q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id');q(install)
 ck('WD131 all old/new rows preserved',before==q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id'))
 w131=(P/'server_SQL/09_WORLD_WD131A_必须执行.sql').read_text(encoding='utf8');q(w131);q(w131)
 ck('WD131 exact World bindings',q('SELECT COUNT(*) FROM spell_script_names WHERE spell_id IN(9003933,9003934)')=='2')
 q("INSERT INTO spell_script_names VALUES(9003933,'foreign131')")
 before=q('SELECT * FROM spell_script_names ORDER BY spell_id,ScriptName')
 ck('WD131 foreign owner rejected',q(w131,fail=True))
 ck('WD131 conflict before mutations',before==q('SELECT * FROM spell_script_names ORDER BY spell_id,ScriptName'))

 wave=2**63+2**110
 ck('WD132 free save level40',save(23,0,wave,40,slot=1)=='1')
 ck('WD132 exact row',q('SELECT node_rank FROM reborn_wd67_nodes WHERE guid=23 AND node_id=4733')=='1')
 ck('WD132 repeat',save(23,1,wave,40,slot=1)=='1')
 ck('WD132 no free removal',save(23,2,2**63,40,slot=1)=='0')
 ck('WD132 level39 rejected',save(24,0,wave,39,slot=1)=='0')
 ck('WD132 missing parent',save(24,0,2**110,80,slot=1)=='0')
 ck('WD132 wrong spec',save(24,0,wave,80,slot=0)=='0')
 ck('WD132 full cumulative save',save(24,0,full+wave,80,slot=1)=='1')
 before=q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id');q(install)
 ck('WD132 reinstall preserves rows',before==q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id'))
 for name in ['spell_group','spell_group_stack_rules']:
  import re
  ddl=(R/'beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots/data/sql/base/db_world'/(name+'.sql')).read_text(encoding='utf-8')
  q(re.search(r'CREATE TABLE.*?;',ddl,re.S)[0])
 w132=(P/'server_SQL/10_WORLD_WD132A_必须执行.sql').read_text(encoding='utf-8');q(w132);q(w132)
 ck('WD132 group exactly two',q('SELECT GROUP_CONCAT(spell_id ORDER BY spell_id) FROM spell_group WHERE id=900132')=='57669,9003939')
 ck('WD132 exclusive',q('SELECT stack_rule FROM spell_group_stack_rules WHERE group_id=900132')=='1')
 q("INSERT INTO spell_group VALUES(900133,123);INSERT INTO spell_group_stack_rules VALUES(900133,2,'foreign')")
 for change,restore in [("INSERT INTO spell_group VALUES(900132,123)","DELETE FROM spell_group WHERE id=900132 AND spell_id=123"),("UPDATE spell_group_stack_rules SET stack_rule=2 WHERE group_id=900132","UPDATE spell_group_stack_rules SET stack_rule=1 WHERE group_id=900132"),("UPDATE spell_group_stack_rules SET description='foreign' WHERE group_id=900132","UPDATE spell_group_stack_rules SET description='WD132 restored' WHERE group_id=900132")]:
  q(change);before=q('SELECT * FROM spell_group ORDER BY id,spell_id')+q('SELECT * FROM spell_group_stack_rules ORDER BY group_id')
  ck('WD132 conflict rejected '+change,q(w132,fail=True));ck('WD132 failure before writes '+change,before==q('SELECT * FROM spell_group ORDER BY id,spell_id')+q('SELECT * FROM spell_group_stack_rules ORDER BY group_id'));q(restore)
 q(w132);ck('WD132 unrelated group untouched',q('SELECT description FROM spell_group_stack_rules WHERE group_id=900133')=='foreign')

 masks=json.loads((P/'checks/masks.json').read_text())
 for guid,key,node,bit in [(25,'FISH',6015,111),(26,'BEAST',29310,112),(27,'CRYSTAL',29754,113)]:
  mask=masks[key]
  ck('WD133 save '+key,save(guid,0,mask,80,slot=1)=='1')
  ck('WD133 repeat '+key,save(guid,1,mask,80,slot=1)=='1')
  ck('WD133 exact row '+key,q(f'SELECT node_rank FROM reborn_wd67_nodes WHERE guid={guid} AND node_id={node}')=='1')
  ck('WD133 no refund '+key,save(guid,2,mask-2**bit,80,slot=1)=='0')
  ck('WD133 wrong spec '+key,save(28,0,mask,80,slot=0)=='0')
 ck('WD133 Fish below16',save(28,0,masks['FISH'],15,slot=1)=='0')
 ck('WD133 Fish missing oil',save(28,0,masks['FISH']-2**65,80,slot=1)=='0')
 ck('WD133 Fish missing bones',save(28,0,masks['FISH']-2**97,80,slot=1)=='0')
 ck('WD133 Beast missing parent',save(28,0,masks['BEAST']-2**70,80,slot=1)=='0')
 ck('WD133 Crystal missing Beast',save(28,0,masks['CRYSTAL']-2**112,80,slot=1)=='0')
 ck('WD133 Crystal insufficient prior TE',save(28,0,masks['BEAST']+2**113,80,slot=1)=='0')
 oldte=q('SELECT te FROM reborn_wd67_budget WHERE level=80');q('UPDATE reborn_wd67_budget SET te='+str(masks['TE']-1)+' WHERE level=80')
 ck('WD133 all new nodes consume TE',save(28,0,masks['CRYSTAL'],80,slot=1)=='0');q('UPDATE reborn_wd67_budget SET te='+oldte+' WHERE level=80')
 before=q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id');q(install)
 ck('WD133 reinstall preserves all rows',before==q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id'))
 w133=(P/'server_SQL/11_WORLD_WD133A_必须执行.sql').read_text(encoding='utf-8');q(w133);q(w133)
 ck('WD133 exact six bindings',q('SELECT COUNT(*) FROM spell_script_names WHERE spell_id IN(9003940,9003942,9003943,9003944)')=='6')
 ck('WD133 percent heal no flat coefficients',q('SELECT direct_bonus+dot_bonus+ap_bonus+ap_dot_bonus FROM spell_bonus_data WHERE entry=9003941')=='0')
 q('UPDATE spell_bonus_data SET comments=NULL WHERE entry=9003941');before=q('SELECT * FROM spell_script_names ORDER BY spell_id,ScriptName')
 ck('WD133 coefficient ownership guarded',q(w133,fail=True));ck('WD133 coefficient guard before writes',before==q('SELECT * FROM spell_script_names ORDER BY spell_id,ScriptName'))
 q("UPDATE spell_bonus_data SET comments='WD133 restored' WHERE entry=9003941")
 q("INSERT INTO spell_script_names VALUES(9003943,'foreign133')");before=q('SELECT * FROM spell_script_names ORDER BY spell_id,ScriptName')
 ck('WD133 ownership conflict',q(w133,fail=True));ck('WD133 fails before writes',before==q('SELECT * FROM spell_script_names ORDER BY spell_id,ScriptName'))

 S=R/'beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots'
 import re
 for table in ['creature_template','creature_template_model','creature_model_info']:
  ddl=(S/'data/sql/base/db_world'/(table+'.sql')).read_text(encoding='utf-8')
  ddl=re.search(r'CREATE TABLE `'+table+r'` \([\s\S]+?;',ddl)[0];q(ddl)
 w134=(P/'server_SQL/12_WORLD_WD134A_必须执行.sql').read_text(encoding='utf-8');q(w134);q(w134)
 ck('WD134 exact28 script bindings',q("SELECT COUNT(*) FROM spell_script_names WHERE ScriptName LIKE '%wd134%'")=='28')
 ck('WD134 two zero coefficients',q('SELECT SUM(direct_bonus+dot_bonus+ap_bonus+ap_dot_bonus) FROM spell_bonus_data WHERE entry IN(9003949,9003952)')=='0')
 ck('WD134 model',q('SELECT CreatureDisplayID FROM creature_template_model WHERE CreatureID=900231')=='900231')
 for g,key in [(29,'CAULDRON'),(30,'BOTH')]:
  ck('WD134 saves '+key,save(g,0,masks[key],80,slot=1)=='1')
  ck('WD134 repeats '+key,save(g,1,masks[key],80,slot=1)=='1')
  ck('WD134 no free refund '+key,save(g,2,masks[key]-2**114,80,slot=1)=='0')
 ck('WD134 exact two new nodes',q('SELECT COUNT(*) FROM reborn_wd67_nodes WHERE guid=30 AND node_id IN(30333,6027)')=='2')
 ck('WD134 level56 rejected',save(31,0,masks['CAULDRON'],56,slot=1)=='0')
 ck('WD134 level57 accepted',save(31,0,masks['CAULDRON'],57,slot=1)=='1')
 ck('WD134 wrong spec',save(32,0,masks['BOTH'],80,slot=0)=='0')
 ck('WD134 missing Cauldron',save(32,0,masks['BOTH']-2**114,80,slot=1)=='0')
 ck('WD134 missing connected prerequisites',save(32,0,masks['NOPARENT'],80,slot=1)=='0')
 ck('WD134 unknown116',save(32,0,masks['BOTH']+2**116,80,slot=1)=='0')
 budget=q('SELECT te FROM reborn_wd67_budget WHERE level=80');q('UPDATE reborn_wd67_budget SET te='+str(masks['NEWTE']-1)+' WHERE level=80')
 ck('WD134 new nodes consume TE',save(32,0,masks['BOTH'],80,slot=1)=='0');q('UPDATE reborn_wd67_budget SET te='+budget+' WHERE level=80')
 before=q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id');q(install);ck('WD134 reinstall preserves all nodes',before==q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id'))
 for change,restore,label in [("UPDATE creature_template SET ScriptName='foreign' WHERE entry=900231","UPDATE creature_template SET ScriptName='npc_reborn_wd134_cauldron' WHERE entry=900231",'creature'),('UPDATE creature_model_info SET VerifiedBuild=0 WHERE DisplayID=900231','UPDATE creature_model_info SET VerifiedBuild=134 WHERE DisplayID=900231','model'),("UPDATE spell_bonus_data SET comments='foreign' WHERE entry=9003952","UPDATE spell_bonus_data SET comments='WD134 restored' WHERE entry=9003952",'coefficient')]:
  q(change);before=q('SELECT * FROM spell_script_names ORDER BY spell_id,ScriptName');ck('WD134 conflict '+label,q(w134,fail=True));ck('WD134 guards before write '+label,before==q('SELECT * FROM spell_script_names ORDER BY spell_id,ScriptName'));q(restore)
 link=2**63+2**110+2**116
 ck('WD135 level49 rejected',save(32,0,link,49,slot=1)=='0')
 ck('WD135 missing parent rejected',save(32,0,2**63+2**116,50,slot=1)=='0')
 ck('WD135 wrong spec rejected',save(32,0,link,50,slot=0)=='0')
 ck('WD135 free level50 save',save(32,0,link,50,slot=1)=='1')
 ck('WD135 exact node',q('SELECT node_rank FROM reborn_wd67_nodes WHERE guid=32 AND node_id=13133')=='1')
 ck('WD135 repeat save',save(32,1,link,50,slot=1)=='1')
 ck('WD135 no free refund',save(32,2,link-2**116,50,slot=1)=='0')
 q("INSERT INTO creature_template(entry,name,ScriptName) VALUES(900192,'Spirit Idol','npc_reborn_wd36a_idol');INSERT INTO creature_template_model(CreatureID,Idx,CreatureDisplayID,DisplayScale,Probability) VALUES(900192,0,4588,1,1)")
 w135=(P/'server_SQL/13_WORLD_WD135A_必须执行.sql').read_text(encoding='utf-8');q(w135);q(w135)
 ck('WD135 template',q("SELECT ScriptName FROM creature_template WHERE entry=900232")=='npc_reborn_wd135_link')
 ck('WD135 model inherited',q('SELECT CreatureDisplayID FROM creature_template_model WHERE CreatureID=900232')=='4588')
 ck('WD135 single binding',q('SELECT COUNT(*) FROM spell_script_names WHERE spell_id=9003953')=='1')
 q("UPDATE creature_template SET ScriptName='foreign' WHERE entry=900232")
 ck('WD135 foreign owner refused',q(w135,fail=True))
 # WD136 new-node persistence and exact prior-tier investment.
 m=masks['CONCOCTIONS']
 ck('WD136 saves exact high bit',save(33,0,m,57,slot=1)=='1')
 ck('WD136 saved node',q('SELECT node_rank FROM reborn_wd67_nodes WHERE guid=33 AND node_id=6026')=='1')
 ck('WD136 repeat idempotent',save(33,1,m,57,slot=1)=='1')
 ck('WD136 no free refund',save(33,2,m-2**117,57,slot=1)=='0')
 ck('WD136 level56 denied',save(34,0,m,56,slot=1)=='0')
 ck('WD136 missing shrooms denied',save(34,0,m-2**85,80,slot=1)=='0')
 ck('WD136 missing Senjin denied',save(34,0,m-2**104,80,slot=1)=='0')
 ck('WD136 missing brewer denied',save(34,0,m-2**84,80,slot=1)=='0')
 ck('WD136 wrong spec denied',save(34,0,m,80,slot=0)=='0')
 ck('WD136 cannot self-bootstrap23',save(34,0,masks['LESS'],80,slot=1)=='0')
 ck('WD136 unknown bit118 denied',save(34,0,m+2**118,80,slot=1)=='0')
 oldte=q('SELECT te FROM reborn_wd67_budget WHERE level=80');q('UPDATE reborn_wd67_budget SET te='+str(masks['CONCOCTIONS_TE']-1)+' WHERE level=80')
 ck('WD136 costs one TE',save(34,0,m,80,slot=1)=='0');q('UPDATE reborn_wd67_budget SET te='+oldte+' WHERE level=80')
 before=q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id');q(install)
 ck('WD136 upgrade keeps old and new nodes',before==q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id'))
 (P/'checks/mysql_results.json').write_text(json.dumps(dict(status='passed',count=len(checks),checks=checks,scratch=str(data),production='No production access; private port33536 only'),indent=2),encoding='utf8');print(len(checks),'isolated MySQL checks passed')
finally:
 if verified:subprocess.run([str(base/'bin/mysqladmin.exe'),'--no-defaults','--protocol=TCP','-h127.0.0.1','-P'+str(port),'-uroot','shutdown'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,timeout=30)
 if proc:
  try:proc.wait(timeout=20)
  except subprocess.TimeoutExpired:proc.terminate();proc.wait(timeout=10)
 log.close()
