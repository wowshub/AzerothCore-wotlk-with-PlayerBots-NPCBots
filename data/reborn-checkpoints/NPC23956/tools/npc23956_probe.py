from pathlib import Path
import json,struct
from wd9a_storm import Archive
from wd19_common import dbc
import wd19_common as common
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO')
C=R/'beascendclient/newrebornWOWli20261008beAscend'
common.S=R/'beascendserver/wowshub_playerbot_npcbot_newrace20261008Ascend'
try:print(common.query('WorldDatabaseInfo','SELECT * FROM creature_template_model WHERE CreatureID=23956; SELECT entry,name,AIName,ScriptName FROM creature_template WHERE entry=23956; SELECT * FROM creature_template_addon WHERE entry=23956;').decode('utf8','replace'))
except Exception as e:print('DB read:',type(e).__name__,str(e)[:200])
archives=[]
for p in C.joinpath('Data').rglob('*'):
 if p.suffix.lower()=='.mpq':
  try:archives.append((p,Archive(p)))
  except Exception as e:print('LOCK',p.name,str(e))
tables={}
for name in ['CreatureDisplayInfo','CreatureDisplayInfoExtra','CreatureModelData','ItemDisplayInfo']:
 tables[name]=[]
 for p,a in archives:
  b=a.read('DBFilesClient\\'+name+'.dbc')
  if b:
   rows,pool=dbc(b);tables[name].append((p,rows,pool))
def st(pool,off):return pool[off:].split(b'\0')[0].decode('utf8','replace')
extras=set();models=set();heads=set()
for p,r,s in tables['CreatureDisplayInfo']:
 for i in [22293,22294]:
  if i in r:
   print('DISPLAY',p.name,i,r[i]);extras.add(r[i][3]);models.add(r[i][1])
for p,r,s in tables['CreatureDisplayInfoExtra']:
 for i in sorted(extras):
  if i in r:print('EXTRA',p.name,i,r[i]);heads.add(r[i][8])
for p,r,s in tables['CreatureModelData']:
 for i in sorted(models):
  if i in r:print('MODEL',p.name,i,st(s,r[i][2]))
for p,r,s in tables['ItemDisplayInfo']:
 for i in sorted(heads):
  if i in r:print('HEAD',p.name,i,[st(s,o) for o in r[i][1:5]])
for p,a in archives:a.close()
