from pathlib import Path
import json,hashlib,struct
from wd19_common import dbc,Archive
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');P=Path(Path('wd120_path.txt').read_text());S=R/'beascendserver/wowshub_playerbot_npcbot_newrace20260929Ascend/Data/dbc';C=R/'beascendclient/newrebornWOWli20260929beAscend';out={}
try:
 a=Archive(C/'Data/Patch-XA.mpq');raw=a.read('DBFilesClient\\SpellVisual.dbc');a.close();out['current_XA']='readable' if raw else 'no SpellVisual override'
except AssertionError as e:out['current_XA']='unverified: '+str(e);raw=None
spells,_=dbc((P/'client_mpq输入_导入现有Patch-XA/DBFilesClient/Spell.dbc').read_bytes())
visualIds={spells[i][131] for i in [9003866,9003867,9003870]};out['native_visual_ids']=sorted(visualIds)
# A server data copy proves record references, not the rendering order of a locked client MPQ.
visuals,vp=dbc((S/'SpellVisual.dbc').read_bytes());kits,kp=dbc((S/'SpellVisualKit.dbc').read_bytes());effects,ep=dbc((S/'SpellVisualEffectName.dbc').read_bytes())
out['reference_only_source']=str(S);out['reference_visual_rows']={i:visuals[i] for i in visualIds}
out['reference_table_hashes']={t:hashlib.sha256((S/(t+'.dbc')).read_bytes()).hexdigest() for t in ['SpellVisual','SpellVisualKit','SpellVisualEffectName']}
refs={}
for name,rid,col,value in [('SpellDuration',85,1,18000),('SpellDuration',21,1,0xffffffff),('SpellRadius',10,1,struct.unpack('<I',struct.pack('<f',30))[0]),('SpellCastTimes',1,1,0)]:
 rows,_=dbc((S/(name+'.dbc')).read_bytes());assert rows[rid][col]==value;refs[name+str(rid)]=rows[rid]
out['duration_radius_cast_verified']=refs
icons,pool=dbc((P/'client_mpq输入_导入现有Patch-XA/DBFilesClient/SpellIcon.dbc').read_bytes());out['icons']={}
for sid in range(910123,910126):
 o=icons[sid][1];path=pool[o:pool.find(b'\0',o)].decode().replace('\\','/')+'.blp';disk=(P/'02_覆盖到客户端根目录'/path).read_bytes();mpq=(P/'client_mpq输入_导入现有Patch-XA'/path).read_bytes();assert disk==mpq and disk[:4] in [b'BLP1',b'BLP2'];out['icons'][sid]={'path':path,'sha256':hashlib.sha256(disk).hexdigest()}
(P/'checks/resource_status.json').write_text(json.dumps(out,ensure_ascii=False,indent=2),encoding='utf8');print(json.dumps({k:v for k,v in out.items() if k in ['current_XA','native_visual_ids']},ensure_ascii=False))
