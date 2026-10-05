from wd119_research import R,P
from wd19_common import dbc,Archive
import re,os,subprocess,json
S=R/'beascendserver/wowshub_playerbot_npcbot_newrace20260929Ascend';B=Path('x') if False else None
rows,pool=dbc((S/'Data/dbc/Spell.dbc').read_bytes())
for sid in [51514,28271,28272]:
 r=rows[sid];print(sid,'misc',r[110:113],'visual',r[131:133],'attrs',r[4:12],'school',r[225])
cfg=(S/'configs/worldserver.conf').read_text(encoding='utf-8-sig');f=re.search(r'^WorldDatabaseInfo\s*=\s*(.+)',cfg,re.M)[1].strip().strip('"').split(';');env=os.environ.copy();env['MYSQL_PWD']=f[3]
ids=','.join(str(rows[s][110]) for s in [51514,28271,28272]);q=f'SELECT entry,name,type FROM creature_template WHERE entry IN({ids}); SELECT * FROM creature_template_model WHERE CreatureID IN({ids});'
r=subprocess.run([str(S/'mysql-8.0.31-winx64/bin/mysql.exe'),'--connect-timeout=5','-h',f[0],'-P',f[1],'-u',f[2],f[4],'-B'],input=q,env=env,capture_output=True,encoding='utf8');print(r.stdout,r.stderr);(P/'research/native_models.tsv').write_text(r.stdout or r.stderr,encoding='utf8')
