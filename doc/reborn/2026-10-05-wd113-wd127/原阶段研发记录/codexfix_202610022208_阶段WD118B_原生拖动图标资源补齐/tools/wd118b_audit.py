from pathlib import Path
import json,datetime
from wd19_common import dbc,Archive
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');C=R/'beascendclient/newrebornWOWli20260929beAscend';B=Path(Path('wd118_path.txt').read_text(encoding='utf8'))
stamp=(datetime.datetime.now(datetime.timezone.utc)-datetime.timedelta(hours=7)).strftime('%Y%m%d%H%M');P=R/f'000Ascendupdate/000Ascendupdate{stamp[:8]}'/f'codexfix_{stamp}_阶段WD118B_原生拖动图标资源补齐';P.mkdir(parents=True,exist_ok=True);(P/'research').mkdir(exist_ok=True);Path('wd118b_path.txt').write_text(str(P),encoding='utf8')
rows,pool=dbc((B/'client_mpq输入_导入现有Patch-XA/DBFilesClient/SpellIcon.dbc').read_bytes())
icons={i:pool[rows[i][1]:].split(b'\0')[0].decode() for i in range(910115,910120)}
print(icons)
a=Archive(C/'Data/patch-XA.MPQ');out={}
for i,path in icons.items():
 out[i]={'path':path,'loose_exists':(C/(path.replace('\\','/')+'.blp')).exists(),'mpq_exists':bool(a.read(path+'.blp'))}
for path in ['Interface/FrameXML/SpellBookFrame.lua','Interface/FrameXML/SpellBookFrame.xml']:
 raw=a.read(path.replace('/','\\'))
 if raw:(P/'research'/Path(path).name).write_bytes(raw);print('extracted',path)
a.close();(P/'research/icon_audit.json').write_text(json.dumps(out,ensure_ascii=False,indent=2),encoding='utf8');print(out)
