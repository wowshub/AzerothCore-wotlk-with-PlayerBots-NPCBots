from wd119_research import R,P
from wd19_common import dbc
import json,hashlib
D=R/'beascendclient/patch20260929巫医开发技能北郡暴风城问题/patch-XA/DBFilesClient'
out={'status':'registered extraction reference only; current Patch-XA locked during audit; no model/visual table overwritten','tables':{}}
for name in ['CreatureDisplayInfo','CreatureModelData','SpellVisual','SpellVisualKit','SpellVisualEffectName']:
 data=(D/(name+'.dbc')).read_bytes();rows,pool=dbc(data);out['tables'][name]={'sha256':hashlib.sha256(data).hexdigest()}
 if name=='CreatureDisplayInfo':
  out['displays']={str(i):rows[i] for i in [901,1924,6295,6297]};models={rows[i][1] for i in [901,1924,6295,6297]}
 elif name=='CreatureModelData':
  out['models']={str(i):{'row':rows[i],'path':pool[rows[i][2]:].split(b'\0')[0].decode()} for i in models}
 elif name=='SpellVisual':
  v=rows[12780];out['native_hex_visual']=v;kits={v[i] for i in [1,2,3,4,5,6,14,15,22,23,24,25] if v[i]}
 elif name=='SpellVisualKit':out['native_hex_kits']={str(i):rows[i] for i in kits}
(P/'research/native_resource_reference.json').write_text(json.dumps(out,ensure_ascii=False,indent=2),encoding='utf8');print('Reference chain recorded; current-archive gap retained')
