from pathlib import Path
import datetime,json,urllib.request,urllib.parse,shutil,hashlib
from wd19_common import Archive,dbc
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');B=Path(Path('wd121_path.txt').read_text());O=Path(Path('wd120_path.txt').read_text())
f=Path('wd122_path.txt')
if not f.exists():
 t=datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=-7))).strftime('%Y%m%d%H%M');f.write_text(str(R/f'000Ascendupdate/000Ascendupdate{t[:8]}/codexfix_{t}_阶段WD122A_丛林蘑菇互斥双天赋'))
P=Path(f.read_text());(P/'research').mkdir(parents=True,exist_ok=True)
def local():
 a=Archive(Path('D:/game/ascend/coaWOW/coawowClinet20260925OFFICIAL/Data/patch-T.MPQ'));raw=a.read('DBFilesClient\\Spell.dbc');a.close();rows,pool=dbc(raw)
 out={}
 for sid in [705859,706545,801660,802703]:
  r=rows[sid];out[sid]={'row':r,'desc':pool[r[170]:].split(b'\0')[0].decode()};print(sid,'effects',r[71:74],'aura',r[95:98],'base',r[80:83],'misc',r[110:113],'amp',r[98:101],'max',r[211])
 (P/'research/official.json').write_text(json.dumps({'archive':'D:/game/ascend/coaWOW/coawowClinet20260925OFFICIAL/Data/patch-T.MPQ','sha256':hashlib.sha256(raw).hexdigest(),'spells':out},ensure_ascii=False,indent=2),encoding='utf8')
 for n in [6020,29737]:shutil.copy2(O/f'research/node{n}.txt',P/f'research/node{n}.txt')
def online():
 def get(url):return urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'WD122-audit'}),timeout=25).read()
 api='https://api.github.com/repos/jealous-sound/azerothcore-wotlk-coa';h=json.loads(get(api+'/commits/HEAD'));(P/'research/head.json').write_text(json.dumps(h));print('HEAD',h['sha'])
 for i,q in enumerate(['"Jungle Booms"','"Doctor of the Jungle"','705859 OR 706545']):
  d=get('https://api.github.com/search/issues?q='+urllib.parse.quote('repo:jealous-sound/azerothcore-wotlk-coa '+q));(P/f'research/search{i}.json').write_bytes(d);print([(x['number'],x['title'],x['state']) for x in json.loads(d).get('items',[])])
 for name in ['AscensionWitchDoctorBrewing.cpp','AscensionWitchDoctorCompletion.cpp','AscensionWitchDoctorAuras.cpp']:
  (P/'research'/name).write_bytes(get('https://raw.githubusercontent.com/jealous-sound/azerothcore-wotlk-coa/'+h['sha']+'/src/server/coa/'+name))
if __name__=='__main__':
 import sys
 (online if 'online' in sys.argv else local)()
