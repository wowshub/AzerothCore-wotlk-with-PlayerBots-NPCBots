from pathlib import Path
import json,hashlib
from wd9a_storm import Archive
from wd19_common import dbc
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO')
C=R/'beascendclient/newrebornWOWli20260929beAscend'
result=[]
for p in (C/'Data').glob('*.MPQ'):
 if not p.name.lower().startswith('patch'):continue
 try:
  a=Archive(p)
  try:
   raw=a.read('DBFilesClient\\SkillLineAbility.dbc')
   if raw:
    rows,_=dbc(raw)
    item={'archive':str(p),'sha':hashlib.sha256(raw).hexdigest(),'rows':[r for r in rows.values() if r[2] in [9003850,9003851,9003852,9003853,9003854]]}
    result.append(item);print(json.dumps(item,ensure_ascii=False))
  finally:a.close()
 except Exception as e:print(p.name,str(e))
Path('D:/000rebornWOW/wd114c_audit.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
