from pathlib import Path
import json,re,subprocess,os
from wd19_common import dbc,Archive
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');P=Path(Path('wd118_path.txt').read_text(encoding='utf8'));S=R/'beascendserver/wowshub_playerbot_npcbot_newrace20260929Ascend';C=R/'beascendclient/newrebornWOWli20260929beAscend'
a=Archive(Path('D:/game/ascend/coaWOW/coawowClinet20260925OFFICIAL/Data/patch-T.MPQ'));rows,pool=dbc(a.read('DBFilesClient\\Spell.dbc'));a.close()
duration,_=dbc((S/'Data/dbc/SpellDuration.dbc').read_bytes());out={}
for sid in [500947,806295]:
 r=rows[sid];out[str(sid)]=dict(row=r,name=pool[r[136]:].split(b'\0')[0].decode('utf8'),desc=pool[r[170]:].split(b'\0')[0].decode('utf8'));print(sid,out[str(sid)]['desc'],'dur',r[40],duration.get(r[40]),'effects',r[71:74],r[80:83],r[95:98],r[110:113])
(P/'research/donor.json').write_text(json.dumps(out,ensure_ascii=False,indent=2),encoding='utf8')
s=(C/'Interface/AddOns/RebornWitchDoctorTalents/Data.lua').read_text(encoding='utf-8-sig');n=next(x for x in s.split('{["ID"]=')[1:] if x.startswith('29306,'));(P/'research/node.txt').write_text(n[:1500],encoding='utf8');print(n[:1000])
cfg=(S/'configs/worldserver.conf').read_text(encoding='utf-8-sig');f=re.search(r'^WorldDatabaseInfo\s*=\s*(.+)',cfg,re.M)[1].strip().strip('"').split(';');env=os.environ.copy();env['MYSQL_PWD']=f[3]
q='SELECT entry,name FROM creature_template WHERE entry=2914; SELECT * FROM creature_template_model WHERE CreatureID=2914;'
r=subprocess.run([str(S/'mysql-8.0.31-winx64/bin/mysql.exe'),'--connect-timeout=5','-h',f[0],'-P',f[1],'-u',f[2],f[4],'-B'],input=q,env=env,capture_output=True,encoding='utf8');print(r.stdout,r.stderr);(P/'research/creature2914.tsv').write_text(r.stdout or r.stderr,encoding='utf8')

