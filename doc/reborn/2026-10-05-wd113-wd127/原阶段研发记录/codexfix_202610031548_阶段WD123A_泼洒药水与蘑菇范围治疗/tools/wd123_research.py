from pathlib import Path
import datetime,json,urllib.request,urllib.parse,shutil,hashlib
from wd19_common import Archive,dbc
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');B=Path(Path('wd122_path.txt').read_text());O=Path(Path('wd120_path.txt').read_text())
f=Path('wd123_path.txt')
if not f.exists():
 t=datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=-7))).strftime('%Y%m%d%H%M');f.write_text(str(R/f'000Ascendupdate/000Ascendupdate{t[:8]}/codexfix_{t}_阶段WD123A_泼洒药水与蘑菇范围治疗'))
P=Path(f.read_text());(P/'research').mkdir(parents=True,exist_ok=True)
def local():
 a=Archive(Path('D:/game/ascend/coaWOW/coawowClinet20260925OFFICIAL/Data/patch-T.MPQ'));raw=a.read('DBFilesClient\\Spell.dbc');a.close();rows,pool=dbc(raw)
 out={}
 for sid,r in rows.items():
  name=pool[r[136]:pool.find(b'\0',r[136])].decode()
  if name not in ['Splash Potion','Jungle Shrooms'] and sid!=561072:continue
  out[sid]={'row':r,'name':name,'desc':pool[r[170]:pool.find(b'\0',r[170])].decode()};print(sid,name,'level',r[26],'effects',r[71:74],'aura',r[95:98],'base',r[80:83],'amp',r[98:101],'max',r[212],'cd',r[29], 'radius',r[92:95],'range',r[40], 'desc',out[sid]['desc'])
 (P/'research/official.json').write_text(json.dumps({'archive':'D:/game/ascend/coaWOW/coawowClinet20260925OFFICIAL/Data/patch-T.MPQ','sha256':hashlib.sha256(raw).hexdigest(),'spells':out},ensure_ascii=False,indent=2),encoding='utf8')
 shutil.copy2(O/'research/node7128.txt',P/'research/node7128.txt')
def online():
 def get(url):return urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'WD123-audit'}),timeout=25).read()
 api='https://api.github.com/repos/jealous-sound/azerothcore-wotlk-coa';h=json.loads(get(api+'/commits/HEAD'));(P/'research/head.json').write_text(json.dumps(h));print('HEAD',h['sha'])
 for i,q in enumerate(['"Splash Potion"','802710','"Potion Boss"']):
  d=get('https://api.github.com/search/issues?q='+urllib.parse.quote('repo:jealous-sound/azerothcore-wotlk-coa '+q));(P/f'research/search{i}.json').write_bytes(d);print([(x['number'],x['title'],x['state']) for x in json.loads(d).get('items',[])][:12])
 for name in ['AscensionWitchDoctorBrewing.cpp','AscensionWitchDoctorCompletion.cpp','AscensionWitchDoctorAbilities.cpp','AscensionWitchDoctorCoefficients.h','AscensionWitchDoctorCompletion.h']:
  (P/'research'/name).write_bytes(get('https://raw.githubusercontent.com/jealous-sound/azerothcore-wotlk-coa/'+h['sha']+'/src/server/coa/'+name))
if __name__=='__main__':
 import sys
 (online if 'online' in sys.argv else local)()
