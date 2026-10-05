# coding: utf-8
from pathlib import Path
import subprocess,socket,time,json,datetime
P=Path(__file__).resolve().parents[1];R=P.parents[2];D=R/'000Ascendupdate/000Ascendupdate20260929';B=next(x for x in D.glob('*WD86A*')if x.is_dir());B88=next(x for x in D.glob('*WD88A*')if x.is_dir())
base=R/'beascendserver/wowshub_playerbot_npcbot_newrace20260929Ascend/mysql-8.0.31-winx64'
data=Path('D:/000rebornWOW')/('_wd113_sql_scratch_'+datetime.datetime.now().strftime('%Y%m%d%H%M%S'));data.mkdir();port=33500
s=socket.socket();s.bind(('127.0.0.1',port));s.close();(P/'checks').mkdir(exist_ok=True)
log=(P/'checks/mysql.log').open('w');args=[str(base/'bin/mysqld.exe'),'--no-defaults','--basedir='+str(base),'--datadir='+str(data)]
assert subprocess.run(args+['--initialize-insecure','--console'],stdout=log,stderr=log,creationflags=subprocess.CREATE_NO_WINDOW,timeout=90).returncode==0
cli=[str(base/'bin/mysql.exe'),'--no-defaults','--protocol=TCP','-h127.0.0.1','-P'+str(port),'-uroot','--default-character-set=utf8mb4','--batch','--skip-column-names']
checks=[];proc=None;verified=False
def q(sql,use=True,fail=False):
 p=subprocess.run(cli+(['wd100']if use else []),input=sql,encoding='utf8',capture_output=True,timeout=30)
 if fail:return p.returncode!=0
 assert p.returncode==0,p.stderr
 return p.stdout.strip()
def ck(n,c):
 if not c: print("FAILED",n,q("SELECT * FROM reborn_wd67_nodes WHERE guid IN(9,16);"),q("SELECT guid,revision FROM reborn_wd5a_builds WHERE guid IN(9,16);"))
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
 install=(P/'server_SQL/01_CHARACTERS_WD113A_必须执行.sql').read_text(encoding='utf8');q(install);q(install);ck('repeat install no automatic bonus',q('SELECT COUNT(*) FROM reborn_wd95_test_points')=='0')
 for g in range(1,23):q(f"INSERT INTO characters(guid,account,name,taximask,innTriggerId,race,class,money) VALUES({g},10,'wd96test{g}','',0,1,13,10000000); INSERT INTO reborn_wd5a_builds(guid) VALUES({g}); INSERT INTO reborn_wd67_members(guid,enabled) VALUES({g},1); INSERT INTO reborn_wd13_slots(guid,slot,paid_copper) VALUES({g},0,0),({g},1,0); INSERT INTO reborn_wd16_profiles VALUES({g},0,0),({g},1,1),({g},2,3);")
 def grant(g,rev,ae=20,te=20,account=10):return q(f'CALL reborn_wd95_testpoints({g},{account},{rev},{ae},{te});')
 def save(g,rev,mask,level=80,slot=0,account=10):return q(f'CALL reborn_wd67_save({g},{account},{rev},{slot},{mask},{level});')
 low8=65024;grasp=2**43
 ck('44-bit Grasp first save level27',save(1,0,low8+grasp,27)=='1')
 ck('44-bit repeat reconstruct',save(1,1,low8+grasp,27)=='1')
 ck('Grasp persists as node30596',q('SELECT node_rank FROM reborn_wd67_nodes WHERE guid=1 AND node_id=30596')=='1')
 ck('Grasp cannot drop without reset',save(1,2,low8,27)=='0')
 ck('stale revision refused',save(1,1,low8+grasp,27)=='2')
 ck('wrong account refused',save(1,2,low8+grasp,27,account=11)=='0')
 ck('level26 refused',save(2,0,low8+grasp,26)=='0')
 ck('seven foundation plus Grasp self-bootstrap refused',save(2,0,low8-2**9+grasp)=='0')
 ck('another tier cannot bootstrap Grasp',save(2,0,low8-2**9+2**19+grasp)=='0')
 ck('wrong spec refused',save(2,0,low8+grasp,slot=1)=='0')
 ck('locked slot refused',save(2,0,low8+grasp,slot=2)=='0')
 ck('mask above44-bit refused',save(2,0,2**55)=='0')
 low23=65024+2*2**32+2**17
 for i in range(17,28):low23+=2*2**23 if i==21 else 2**(i+3 if i>=22 else i+2)
 voice=2**41;price=2**42
 ck('Grasp counts toward later23-tier',save(2,0,low23-2**30+grasp+voice,57)=='1')
 ck('Grasp still consumes one TE',save(3,0,low23+grasp+voice,57)=='0')
 ck('same layout at59 budget25 accepted',save(3,0,low23+grasp+voice,59)=='1')
 ck('old43-bit Voice Price retained',save(4,0,low23+voice+price,59)=='1')
 ck('test bonus can cover TE budget',grant(5,0)=='1' and save(5,1,low23+grasp+voice+price,57)=='1')
 ck('test bonus cannot skip Grasp level27',grant(6,0)=='1' and save(6,1,low8+grasp,26)=='0')
 foundation_result=save(6,1,low8-512+grasp,85)
 assert foundation_result=='0',(foundation_result,q('SELECT * FROM reborn_wd5a_builds WHERE guid=6'),q('SELECT * FROM reborn_wd67_nodes WHERE guid=6'))
 ck('test bonus cannot skip Grasp foundation',True)
 for attempt in range(10):
  result=save(6,1,low8-512+grasp,85)
  assert result=='0',(attempt,result,q('SELECT revision FROM reborn_wd5a_builds WHERE guid=6'))
 ck('repeated invalid saves leave revision and nodes intact',q('SELECT revision FROM reborn_wd5a_builds WHERE guid=6')=='1' and q('SELECT COUNT(*) FROM reborn_wd67_nodes WHERE guid=6')=='0')
 ck('test bonus not additive',grant(5,2)=='1' and q('SELECT extra_te FROM reborn_wd95_test_points WHERE guid=5')=='20')
 ck('test bonus clear retains all nodes at maxlevel',grant(5,3,0,0)=='1')

 j,a,h=2**44,2**46,2**47
 class9=123+2*j
 ck('Class rank2 save, alternate spec',save(7,0,class9+a+h,80,slot=1)=='1')
 ck('Class exact 48-bit reconstruction',save(7,1,class9+a+h,80,slot=1)=='1')
 ck('new nodes all stored',q('SELECT COUNT(*) FROM reborn_wd67_nodes WHERE guid=7 AND node_id IN(7088,30147,4132)')=='3')
 ck('rank3 refused',save(8,0,3*j)=='0')
 ck('self-bootstrap refused',save(8,0,class9-j+a+h)=='0')
 ck('Alchemy level27 refused',save(8,0,class9+a,27)=='0')
 ck('9AE foundation but 9 total budget insufficient',save(8,0,class9+h,26)=='0')
 ck('Alchemy level28 10AE accepted',save(8,0,class9+a,28)=='1')
 ck('cannot refund new nodes without reset',save(7,2,class9,80,slot=1)=='0')
 ck('rank cannot decrease',save(8,1,class9-j+a,80)=='0')

 war,mal,soul=2**48,2**49,2**50
 ck('new three save at59 with allowance',grant(9,0)=='1' and save(9,1,low23+war+mal+soul,59)=='1')
 ck('51bit exact reconstruct',save(9,2,low23+war+mal+soul,59)=='1')
 ck('new three stored',q('SELECT COUNT(*) FROM reborn_wd67_nodes WHERE guid=9 AND node_id IN(31349,29929,6055)')=='3')
 ck('war level58 rejected',save(10,0,low8+war,58)=='0')
 ck('soul level58 rejected',save(10,0,low23+soul,58)=='0')
 ck('new tier cannot bootstrap',save(10,0,low23-2**30+mal+soul,80)=='0')
 ck('war contributes later tier',save(10,0,low23-2**30+war+mal+soul,80)=='1')
 ck('new Voodoo wrong spec rejected',save(11,0,low8+war,80,slot=1)=='0')
 ck('new no-drop',save(9,3,low23+war,80)=='0')
 ck('new budget enforced at59 without bonus',save(11,0,low23+war+mal+soul,59)=='0')

 adept=2**51
 ck('free node level50 zero AE/TE',save(12,0,adept,50)=='1')
 ck('52-bit repeat reconstruct',save(12,1,adept,50)=='1')
 ck('free node persisted',q('SELECT node_rank FROM reborn_wd67_nodes WHERE guid=12 AND node_id=11133')=='1')
 ck('level49 blocked',save(13,0,adept,49)=='0')
 ck('wrong spec blocked',save(13,0,adept,50,slot=1)=='0')
 ck('cannot refund free saved node',save(12,2,0,50)=='0')
 ck('cumulative52bit save',grant(14,0)=='1' and save(14,1,low23+war+mal+soul+adept,59)=='1')
 ck('cumulative52bit repeat',save(14,2,low23+war+mal+soul+adept,59)=='1')
 ck('free point cannot bootstrap23TE',grant(15,0)=='1' and save(15,1,low23-2**30+mal+soul+adept,59)=='0')

 w,speed,mojo=2**52,2**53,2**54
 allthree=class9+w+speed+mojo
 ck('55-bit Class odd mask accepted',save(16,0,allthree,85)=='1')
 ck('55-bit exact reconstruction',save(16,1,allthree,85)=='1')
 ck('three new records',q('SELECT COUNT(*) FROM reborn_wd67_nodes WHERE guid=16 AND node_id IN(7033,6051,6048)')=='3')
 ck('highbits cannot drop',save(16,2,class9+w+speed,85)=='0')
 ck('tier cannot bootstrap using same tier',save(17,0,class9-j+w+speed+mojo,85)=='0')
 ck('Swift level27 refused',save(17,0,class9+speed,27)=='0')
 ck('Swift level28 accepted',save(17,0,class9+speed,28)=='1')
 ck('Dark Mojo level31 refused',save(18,0,class9+mojo,31)=='0')
 ck('Dark Mojo level32 accepted',save(18,0,class9+mojo,32)=='1')
 ck('Spirit Warden costs tenth AE',save(19,0,class9+w,26)=='0')
 ck('Spirit Warden accepted with budget',save(19,0,class9+w,28)=='1')
 ck('Class allthree alternate spec',save(20,0,allthree,85,slot=1)=='1')
 ck('Class does not count as TE allowance',grant(20,1,0,0)=='1')
 ck('full old and new mask roundtrip',save(21,0,allthree+low23+war+mal+soul+adept,85)=='1' and save(21,1,allthree+low23+war+mal+soul+adept,85)=='1')
 q('INSERT INTO reborn_wd13_slots(guid,slot,paid_copper) VALUES(22,2,0);UPDATE reborn_wd16_profiles SET spec=2 WHERE guid=22 AND slot=2;')
 ck('third slot Class accepted',save(22,0,allthree,85,slot=2)=='1')
 # Stress repeat reconstruct and ensure all old+new rows remain, independent SELECT per save.
 expected=q('SELECT node_id,node_rank FROM reborn_wd67_nodes WHERE guid=21 ORDER BY node_id;')
 for revision in range(2,66):
  ck('stress cumulative save '+str(revision),save(21,revision,allthree+low23+war+mal+soul+adept,85)=='1')
  actual=q('SELECT node_id,node_rank FROM reborn_wd67_nodes WHERE guid=21 ORDER BY node_id;')
  assert actual==expected,(revision,expected,actual)
 ck('64 repeated saves preserve every row and rank',True)

 # Separate actors and two real saved slots. Keep prior Voodoo rows unchanged.
 before=q('SELECT guid,slot,node_id,node_rank FROM reborn_wd67_nodes ORDER BY guid,slot,node_id;')
 for g in range(30,35):
  q(f"INSERT INTO characters(guid,account,name,taximask,innTriggerId,race,class,money) VALUES({g},10,'brew{g}','',0,1,13,10000000); INSERT INTO reborn_wd5a_builds(guid) VALUES({g}); INSERT INTO reborn_wd67_members(guid,enabled) VALUES({g},1); INSERT INTO reborn_wd13_slots(guid,slot,paid_copper) VALUES({g},0,0),({g},1,0); INSERT INTO reborn_wd16_profiles VALUES({g},0,0),({g},1,1),({g},2,2);")
 a,b,c=2**55,2**57,2**59
 first=a+b+c;second=2*first
 ck('Brewing rank1 costs exactly3 TE',save(30,0,first,15,slot=1)=='1')
 ck('three Brewing nodes persisted rank1',q('SELECT COUNT(*) FROM reborn_wd67_nodes WHERE guid=30 AND slot=1 AND node_id IN(7131,30884,29736) AND node_rank=1')=='3')
 ck('rank1 repeated decimal reconstruction',save(30,1,first,15,slot=1)=='1')
 ck('rank2 budget5 rejects atomic upgrade',save(30,2,second,19,slot=1)=='0')
 ck('rank2 budget6 accepts upgrade',save(30,2,second,21,slot=1)=='1')
 ck('rank2 allthree persisted',q('SELECT COUNT(*) FROM reborn_wd67_nodes WHERE guid=30 AND slot=1 AND node_rank=2')=='3')
 ck('rank2 cannot free downgrade',save(30,3,first,80,slot=1)=='0')
 ck('rank3 rejected',save(31,0,3*a,80,slot=1)=='0')
 ck('unused bits rejected',save(31,0,2**72,80,slot=1)=='0')
 ck('wrong Voodoo spec rejected',save(31,0,first,80,slot=0)=='0')
 ck('locked third slot rejected',save(31,0,first,80,slot=2)=='0')
 ck('Voodoo plus Brewing mixed rejected',save(31,0,first+adept,80,slot=1)=='0')
 ck('level9 rejected despite bonus',grant(31,0)=='1' and save(31,1,a,9,slot=1)=='0')
 ck('rank1 level11 TE1 accepted',save(32,0,a,11,slot=1)=='1')
 ck('rank2 level11 TE1 rejected',save(32,1,2*a,11,slot=1)=='0')
 ck('rank2 level13 TE2 accepted',save(32,1,2*a,13,slot=1)=='1')
 ck('wrong account rejected',save(32,2,2*a,80,slot=1,account=11)=='0')
 ck('stale revision rejected',save(32,1,2*a,80,slot=1)=='2')
 combo=allthree+second
 ck('Class and Brewing exact odd mask',save(33,0,combo,80,slot=1)=='1')
 for rev in range(1,17):ck('61bit repeat '+str(rev),save(33,rev,combo,80,slot=1)=='1')
 ck('Class unchanged rank and AE cost',q('SELECT node_rank FROM reborn_wd67_nodes WHERE guid=33 AND node_id=7088')=='2')
 ck('Class plus Brewing clears unneeded GM bonus',grant(33,17,0,0)=='1')
 ck('invalid attempts retain empty actor',q('SELECT COUNT(*) FROM reborn_wd67_nodes WHERE guid=31')=='0')
 ck('prior Voodoo and Class characters unchanged',before==q('SELECT guid,slot,node_id,node_rank FROM reborn_wd67_nodes WHERE guid<30 ORDER BY guid,slot,node_id;'))
 ck('same character can save independent Voodoo slot',save(30,3,adept,80,slot=0)=='1')
 ck('Brewing slot survives Voodoo save',q('SELECT COUNT(*) FROM reborn_wd67_nodes WHERE guid=30 AND slot=1 AND node_rank=2')=='3')

 # Exercise the unchanged reset SQL plus the outer transaction assembled by C++.
 import re
 for table in ['reborn_wd16_reset_audit','reborn_wd9a_nodes','reborn_wd16_actions']:
  lines=[x for x in (P/('research/schema_'+table+'.tsv')).read_text(encoding='utf8').splitlines() if x.strip()]
  q(lines[1].split('\t',1)[1].replace('\\n','\n').replace('\\t','\t')+';')
 line=[x for x in (P/'research/live_reset.tsv').read_text(encoding='utf8').splitlines() if x.strip()][1]
 reset=line.split('\t')[2].replace('\\n','\n').replace('\\t','\t')
 reset=re.sub(r'CREATE DEFINER=`[^`]+`@`[^`]+` PROCEDURE','CREATE PROCEDURE',reset)
 q('DELIMITER $$\n'+reset+'$$\nDELIMITER ;')
 q('START TRANSACTION; CALL reborn_wd16_reset(30,10,4,1,100000); DELETE FROM reborn_wd67_nodes WHERE guid=30 AND slot=1; UPDATE characters SET money=money-100000 WHERE guid=30; COMMIT;')
 ck('reset removes all Brewing nodes in target slot',q('SELECT COUNT(*) FROM reborn_wd67_nodes WHERE guid=30 AND slot=1')=='0')
 ck('reset retains Voodoo slot on same actor',q('SELECT node_id FROM reborn_wd67_nodes WHERE guid=30 AND slot=0')=='11133')
 ck('reset releases target spec',q('SELECT spec FROM reborn_wd16_profiles WHERE guid=30 AND slot=1')=='3')
 ck('reset increments revision once and charges once',q('SELECT revision FROM reborn_wd5a_builds WHERE guid=30')=='5' and q('SELECT money FROM characters WHERE guid=30')=='9900000')
 ck('unbound reset slot cannot immediately save Brewing',save(30,5,first,80,slot=1)=='0')
 # Schema itself rejects invalid node/rank and guards rollback against allocated new nodes.
 ck('table rejects rank3',q('INSERT INTO reborn_wd67_nodes VALUES(34,1,7131,3);',fail=True))
 ck('table rejects unknown node',q('INSERT INTO reborn_wd67_nodes VALUES(34,1,999999,1);',fail=True))
 # WD105: highest-bit persistence and free-node budget behavior.
 for g in range(40,52):
  q(f"INSERT INTO characters(guid,account,name,taximask,innTriggerId,race,class,money) VALUES({g},10,'sustain{g}','',0,1,13,10000000); INSERT INTO reborn_wd5a_builds(guid) VALUES({g}); INSERT INTO reborn_wd67_members(guid,enabled) VALUES({g},1); INSERT INTO reborn_wd13_slots(guid,slot,paid_copper) VALUES({g},0,0),({g},1,0); INSERT INTO reborn_wd16_profiles VALUES({g},0,0),({g},1,1),({g},2,2);")
 healer,presence,blessing=2**61,2**62,2**63
 for j in range(8):
  mask=sum(2**(61+k)for k in range(3)if j&(1<<k))
  ck('64bit combination '+str(j),save(40+j,0,mask,80,slot=1)=='1')
  ck('64bit repeat '+str(j),save(40+j,1,mask,80,slot=1)=='1')
  ck('free nodes never consume bonus '+str(j),grant(40+j,2,0,0)=='1')
 ck('level19 healer rejected',save(48,0,healer,19,slot=1)=='0')
 ck('level20 healer accepted',save(48,0,healer,20,slot=1)=='1')
 ck('level29 blessing rejected',save(49,0,blessing,29,slot=1)=='0')
 ck('level30 blessing accepted',save(49,0,blessing,30,slot=1)=='1')
 ck('presence requires TE',save(50,0,presence,10,slot=1)=='0')
 ck('presence one TE at11',save(50,0,presence,11,slot=1)=='1')
 ck('free nodes wrong branch refused',save(51,0,healer+blessing,80,slot=0)=='0')
 ck('rank2 forbidden for single rank',q('INSERT INTO reborn_wd67_nodes VALUES(51,1,9311,2);',fail=True))
 highodd=allthree+second+healer+presence+blessing
 ck('64bit high plus odd Class bits',save(51,0,highodd,80,slot=1)=='1')
 for rev in range(1,17):ck('highest bit repeated '+str(rev),save(51,rev,highodd,80,slot=1)=='1')
 ck('highest bit cannot drop',save(51,17,highodd-blessing,80,slot=1)=='0')
 ck('full unsigned parsed then invalid rank rejected',save(51,17,2**64-1,80,slot=1)=='0')
 ck('new nodes persisted exactly',q('SELECT COUNT(*) FROM reborn_wd67_nodes WHERE guid=51 AND slot=1 AND node_id IN(9311,5055,4715) AND node_rank=1')=='3')
 # WD109: high limbs, old low64 reconstruction, prereqs and no-refund.
 for g in range(60,76):
  q(f"INSERT INTO characters(guid,account,name,taximask,innTriggerId,race,class,money) VALUES({g},10,'brew109{g}','',0,1,13,10000000); INSERT INTO reborn_wd5a_builds(guid) VALUES({g}); INSERT INTO reborn_wd67_members(guid,enabled) VALUES({g},1); INSERT INTO reborn_wd13_slots(guid,slot,paid_copper) VALUES({g},0,0),({g},1,10000000); INSERT INTO reborn_wd16_profiles VALUES({g},0,0),({g},1,1),({g},2,3);")
 pot,touch,jungle=2**64,2**65,2**66
 foundation=2*2**55+2*2**57+2*2**59+2**62+pot
 for bits in range(4):
  mask=foundation+((bits&1)*touch)+((bits>>1)*jungle)+1+2**61+2**63
  g=60+bits
  ck('67bit combination '+str(bits),save(g,0,mask,80,slot=1)=='1')
  ck('67bit reload/resave '+str(bits),save(g,1,mask,80,slot=1)=='1')
  ck('high limb no-drop '+str(bits),save(g,2,mask-pot,80,slot=1)=='0')
  ck('bonus audit counts new TE '+str(bits),grant(g,2,0,0)=='1')
 ck('first new bit low level11',save(64,0,pot,11,slot=1)=='1')
 ck('first new bit budget level10',save(65,0,pot,10,slot=1)=='0')
 ck('new bit wrong specialization',save(65,0,pot,80,slot=0)=='0')
 ck('Touch eight foundation and ninthTE',save(65,0,foundation+touch,27,slot=1)=='1')
 ck('Touch ninthTE insufficient at25',save(66,0,foundation+touch,25,slot=1)=='0')
 ck('Touch cannot bootstrap itself',save(66,0,foundation-pot+touch,80,slot=1)=='0')
 ck('two later nodes cannot bootstrap',save(66,0,foundation-pot+touch+jungle,80,slot=1)=='0')
 ck('Jungle level29 refused',save(66,0,foundation+jungle,29,slot=1)=='0')
 ck('Jungle level30 accepted',save(66,0,foundation+jungle,30,slot=1)=='1')
 ck('all three level30',save(67,0,foundation+touch+jungle,30,slot=1)=='1')
 ck('negative mask refused',save(68,0,-1,80,slot=1)=='0')
 ck('128 maximum rejected as unused bits',save(68,0,2**128-1,80,slot=1)=='0')
 ck('nonzero unbound slot refuses save',save(68,0,pot,80,slot=2)=='0')
 ck('missing rank rejects',q('INSERT INTO reborn_wd67_nodes VALUES(68,1,7129,2);',fail=True))
 ck('new free-drop denied even old mask valid',save(67,1,foundation,80,slot=1)=='0')
 ck('second slot purchase intact',q('SELECT paid_copper FROM reborn_wd13_slots WHERE guid=67 AND slot=1')=='10000000')
 ck('unused third slot preserved',q('SELECT spec FROM reborn_wd16_profiles WHERE guid=67 AND slot=2')=='3')
 before=q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id;')
 q(install);ck('repeat migration retains all existing node rows',before==q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id;'))
 # WD110-112 save/load and migration preservation tests.
 for g in range(80,95):
  q(f"INSERT INTO characters(guid,account,name,taximask,innTriggerId,race,class,money) VALUES({g},10,'new112{g}','',0,1,13,10000000); INSERT INTO reborn_wd5a_builds(guid) VALUES({g}); INSERT INTO reborn_wd67_members(guid,enabled) VALUES({g},1); INSERT INTO reborn_wd13_slots(guid,slot,paid_copper) VALUES({g},0,0),({g},1,10000000); INSERT INTO reborn_wd16_profiles VALUES({g},0,0),({g},1,1),({g},2,3);")
 classbase=1+2+2*4+16+32+64+2*2**44
 curse,touch,chosen,rage,arcane=[2**n for n in range(67,72)]
 for j,bit in enumerate([touch,chosen]):
  mask=classbase+bit
  ck('class high-bit save '+str(j),save(80+j,0,mask,80,slot=0)=='1')
  ck('class high-bit reload '+str(j),save(80+j,1,mask,80,slot=0)=='1')
  ck('class high-bit cannot refund '+str(j),save(80+j,2,classbase,80,slot=0)=='0')
  ck('class high-bit legal Brewing '+str(j),save(80+j,2,mask,80,slot=1)=='1')
 ck('Cursed reserved bit refused',save(83,0,classbase+curse,80)=='0')
 ck('Touch level30',save(84,0,classbase+touch,29)=='0' and save(84,0,classbase+touch,30)=='1')
 ck('Class nine foundation excludes new tier9',save(85,0,classbase-1+curse+touch)=='0')
 ck('Chosen adds foundation AE',save(85,0,classbase-1+chosen+touch)=='1')
 for j,bit in enumerate([rage,arcane]):
  ck('Brew level31 '+str(j),save(86+j,0,foundation+bit,30,slot=1)=='0' and save(86+j,0,foundation+bit,31,slot=1)=='1')
  ck('Brew repeat exact '+str(j),save(86+j,1,foundation+bit,31,slot=1)=='1')
  ck('Brew no free removal '+str(j),save(86+j,2,foundation,80,slot=1)=='0')
 ck('Brew choices exclusive',save(88,0,foundation+rage+arcane,80,slot=1)=='0')
 ck('Brew no bootstrap',save(88,0,foundation-pot+rage,80,slot=1)=='0')
 ck('Brew wrong spec',save(88,0,foundation+rage,80,slot=0)=='0')
 ck('72bit unused bit',save(88,0,2**72,80,slot=1)=='0')
 before=q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id;')
 q(install);ck('repeat upgrade preserves new and previous builds',before==q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id;'))
 world=(P/'server_SQL/02_WORLD_WD112A_必须执行.sql').read_text(encoding='utf8');q(world);q(world)
 ck('World repeat private binding',q('SELECT COUNT(*) FROM spell_script_names WHERE spell_id IN(9003841,9003843)')=='2')
 q("INSERT INTO spell_script_names VALUES(9003841,'conflict_fixture')")
 ck('World conflict refuses',q(world,fail=True))
 q("DELETE FROM spell_script_names WHERE ScriptName='conflict_fixture'")
 # WD113 exact 75-bit Class ownership, prerequisites, choices and persistence.
 for g in range(100,111):
  q(f"INSERT INTO characters(guid,account,name,taximask,innTriggerId,race,class,money) VALUES({g},10,'new113{g}','',0,1,13,10000000); INSERT INTO reborn_wd5a_builds(guid) VALUES({g}); INSERT INTO reborn_wd67_members(guid,enabled) VALUES({g},1); INSERT INTO reborn_wd13_slots(guid,slot,paid_copper) VALUES({g},0,0),({g},1,10000000); INSERT INTO reborn_wd16_profiles VALUES({g},0,0),({g},1,1),({g},2,3);")
 newbits=[2**72,2**73,2**74]
 for j,bit in enumerate(newbits):
  ck('WD113 foundation required '+str(j),save(100+j,0,bit)=='0')
  ck('WD113 node save '+str(j),save(100+j,0,classbase+bit)=='1')
  ck('WD113 repeat read '+str(j),save(100+j,1,classbase+bit)=='1')
  ck('WD113 no free refund '+str(j),save(100+j,2,classbase)=='0')
  ck('WD113 class cross spec '+str(j),save(100+j,2,classbase+bit,slot=1)=='1')
 ck('WD113 all three exact decimal',save(103,0,classbase+sum(newbits))=='1')
 ck('WD113 repeated upgrade keeps all nodes',q('SELECT COUNT(*) FROM reborn_wd67_nodes WHERE guid=103 AND node_id IN(6381,12048,11323)')=='3')
 ck('WD113 mutual exclusion DarkMojo',save(104,0,classbase+2**54+2**73)=='0')
 ck('WD113 same tier cannot bootstrap',save(104,0,classbase-1+sum(newbits))=='0')
 ck('WD113 budget enforced',save(104,0,classbase+sum(newbits),30)=='0')
 ck('WD113 high bit rejected',save(104,0,classbase+2**75)=='0')
 ck('WD113 original DarkMojo valid',save(104,0,classbase+2**54)=='1')
 before=q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id;')
 q(install);ck('WD113 reinstallation retains rows',before==q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id;'))
 rollback=(P/'rollback/server_SQL/01_CHARACTERS_WD105A.sql').read_text(encoding='utf8')
 ck('rollback refuses new saved node rows',q(rollback,fail=True))
 ck('failed rollback retains rows',before==q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id;'))
 # This is the isolated fixture only, never a production repair instruction.
 q('DELETE FROM reborn_wd67_nodes WHERE node_id IN(7129,7948,31137,5113,30891,6030,7132,29753,6381,12048,11323);');q(rollback)
 ck('old schema disallows new node',q('INSERT INTO reborn_wd67_nodes VALUES(68,1,7129,1);',fail=True))
 q(install);ck('reinstall restores support',save(68,0,pot,80,slot=1)=='1')
 (P/'checks/mysql_results.json').write_text(json.dumps(dict(status='passed',count=len(checks),checks=checks,scratch=str(data),production='No mutations; private port33500 only'),indent=2),encoding='utf8');print(len(checks),'isolated MySQL checks passed')
finally:
 if verified:subprocess.run([str(base/'bin/mysqladmin.exe'),'--no-defaults','--protocol=TCP','-h127.0.0.1','-P'+str(port),'-uroot','shutdown'],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,timeout=30)
 if proc:
  try:proc.wait(timeout=20)
  except subprocess.TimeoutExpired:proc.terminate();proc.wait(timeout=10)
 log.close()
