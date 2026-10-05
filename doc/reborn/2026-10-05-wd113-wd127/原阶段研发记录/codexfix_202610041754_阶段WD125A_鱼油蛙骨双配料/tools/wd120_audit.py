from pathlib import Path
import re,json,datetime,urllib.request,urllib.parse
from wd19_common import dbc,Archive
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');B=Path(Path('wd119_path.txt').read_text())
C=R/'beascendclient/newrebornWOWli20260929beAscend'
if not Path('wd120_path.txt').exists():
 stamp=datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=-7))).strftime('%Y%m%d%H%M')
 Path('wd120_path.txt').write_text(str(R/f'000Ascendupdate/000Ascendupdate{stamp[:8]}/codexfix_{stamp}_阶段WD120A_酿造下一批依赖开发'))
P=Path(Path('wd120_path.txt').read_text());(P/'research').mkdir(parents=True,exist_ok=True)
def local():
 s=(C/'Interface/AddOns/RebornWitchDoctorTalents/Data.lua').read_text(encoding='utf-8-sig')
 a=Archive(Path('D:/game/ascend/coaWOW/coawowClinet20260925OFFICIAL/Data/patch-T.MPQ'));rows,pool=dbc(a.read('DBFilesClient\\Spell.dbc'));a.close()
 todo={int(x) for x in re.findall(r'\{(\d+),1,.*?false,',(B/'01_覆盖到源代码根目录/modules/mod-reborn-witchdoctor/src/RebornWitchDoctorTalentNodes.h').read_text(encoding='utf8'))}
 todo.update({6044,12749,29749,29743,30203,29757,6050,6052,6049})
 result={}
 for n in s.split('{["ID"]=')[1:]:
  nid=int(n.split(',')[0])
  if nid not in todo:continue
  name=re.search(r'\["Name"\]="([^"]+)',n)[1]
  desc=[]
  for sid in map(int,re.search(r'\["Spells"\]=\{(.*?)\}',n)[1].split(',')):
   if sid not in rows:continue
   d=pool[rows[sid][170]:].split(b'\0')[0].decode();desc.append((sid,d));result[str(sid)]={'node':nid,'name':name,'row':rows[sid],'desc':d}
  (P/f'research/node{nid}.txt').write_text(n[:1600],encoding='utf8')
  print(nid,name,desc)
 (P/'research/preview_donor.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf8')
def online():
 def get(url):return urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'WD120-audit'}),timeout=25).read()
 api='https://api.github.com/repos/jealous-sound/azerothcore-wotlk-coa'
 head=json.loads(get(api+'/commits/HEAD'));(P/'research/head.json').write_text(json.dumps(head));print('HEAD',head['sha'],flush=True)
 for i,q in enumerate(['Cauldron','"Potion Toss"','"Jungle Shrooms"']):
  data=get('https://api.github.com/search/issues?q='+urllib.parse.quote('repo:jealous-sound/azerothcore-wotlk-coa '+q));(P/f'research/search{i}.json').write_bytes(data);print([(x['number'],x['title']) for x in json.loads(data).get('items',[])],flush=True)
 for name in ['AscensionWitchDoctorCompletion.cpp','AscensionWitchDoctorAuras.cpp','AscensionWitchDoctorAbilities.cpp','AscensionWitchDoctorCompletion.h']:
  (P/'research'/name).write_bytes(get('https://raw.githubusercontent.com/jealous-sound/azerothcore-wotlk-coa/'+head['sha']+'/src/server/coa/'+name))
if __name__=='__main__':
 import sys
 (online if 'online' in sys.argv else local)()
