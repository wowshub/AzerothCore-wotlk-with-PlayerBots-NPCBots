from pathlib import Path
from wd9a_storm import Archive
import struct,json,hashlib
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');C=R/'beascendclient/newrebornWOWli20261008beAscend'
keys=['Item\\ObjectComponents\\Head\\Helm_Mail_Vrykul_01_'+s+e for s in ['VrM','NiM','HuM','WoM','NsM'] for e in ['.m2','00.skin']]+['Item\\ObjectComponents\\Head\\Helm_Mail_Vrykul_01Blue.blp','Character\\Vrykul\\Male\\VrykulMale.m2']
results=[]
for p in (C/'Data').rglob('*.mpq'):
 a=Archive(p)
 for k in keys:
  b=a.read(k)
  if b:
   r={'archive':str(p),'key':k,'size':len(b),'sha256':hashlib.sha256(b).hexdigest(),'magic':str(b[:4])}
   if k.endswith('.m2'):
    r['vertices']=struct.unpack_from('<I',b,60)[0];r['views']=struct.unpack_from('<I',b,68)[0]
   results.append(r);print(r,flush=True)
 a.close()
Path('npc23956_assets.json').write_text(json.dumps(results,indent=2))
