import sys,json
sys.path.insert(0,'stormforged-intake');sys.argv=['','C:/000ref/WarcraftXL\u8bd5\u88c5_client']
from probe import *
server=r/'beascendserver/wowshub_playerbot_npcbot_newrace20261122Ascend/Data/dbc'
report={}
for lang in ('','zhCN'):
 p=server/lang
 tables={name:(p/(name+'.dbc')).read_bytes() for name in ('ChrRaces','CreatureDisplayInfo','CreatureModelData')}
 disp={u('<I',v)[0]:u('<I',v,4)[0] for v in rows(tables['CreatureDisplayInfo'])[1]}
 model={u('<I',v)[0] for v in rows(tables['CreatureModelData'])[1]}
 missing=[]
 for v in rows(tables['ChrRaces'])[1]:
  race=u('<I',v)[0]
  for sex,id in enumerate(u('<2I',v,16)):
   if race==84:print(lang or 'root','Stormforged',sex,id,'model',disp.get(id),'exists',id in disp and disp[id] in model)
   if id and (id not in disp or disp[id] not in model):missing.append([race,sex,id,disp.get(id)])
 print(lang or 'root','missing race display/model links:',missing)
 report[lang or 'root']={'missing':missing,'hashes':{name:sha256(data).hexdigest() for name,data in tables.items()}}
(w/'server-display-audit.json').write_text(json.dumps(report,indent=2))
