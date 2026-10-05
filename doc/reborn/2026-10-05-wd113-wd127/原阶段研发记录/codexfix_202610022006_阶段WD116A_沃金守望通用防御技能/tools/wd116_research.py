from pathlib import Path
import json,urllib.request,urllib.parse,datetime
from wd9a_storm import Archive
from wd19_common import dbc
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO')
stamp=(datetime.datetime.now(datetime.timezone.utc)-datetime.timedelta(hours=7)).strftime('%Y%m%d%H%M')
P=R/('000Ascendupdate/000Ascendupdate'+stamp[:8])/('codexfix_'+stamp+'_阶段WD116A_沃金守望通用防御技能')
P.mkdir(parents=True,exist_ok=True);(P/'research').mkdir(exist_ok=True);Path('wd116_path.txt').write_text(str(P),encoding='utf8')
def get(url):return urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'WD116-audit'}),timeout=30).read()
base='https://api.github.com/repos/jealous-sound/azerothcore-wotlk-coa'
h=json.loads(get(base+'/commits/HEAD'));(P/'research/head.json').write_text(json.dumps(h));print('HEAD',h['sha'],flush=True)
for n,q in enumerate(['"Vol\'jin\'s Vigil"','is:pr "Vigil"']):
 d=get('https://api.github.com/search/issues?q='+urllib.parse.quote('repo:jealous-sound/azerothcore-wotlk-coa '+q));(P/f'research/search{n}.json').write_bytes(d);print([(x['number'],x['title']) for x in json.loads(d).get('items',[])],flush=True)
for name in ['AscensionWitchDoctorCompletion.cpp','AscensionWitchDoctorAuras.cpp','AscensionWitchDoctorCompletion.h']:
 (P/'research'/name).write_bytes(get('https://raw.githubusercontent.com/jealous-sound/azerothcore-wotlk-coa/'+h['sha']+'/src/server/coa/'+name))
a=Archive(Path('D:/game/ascend/coaWOW/coawowClinet20260925OFFICIAL/Data/patch-T.MPQ'));raw=a.read('DBFilesClient\\Spell.dbc');a.close();rows,pool=dbc(raw)
out={str(i):{'row':rows[i],'description':pool[rows[i][170]:].split(b'\0')[0].decode('utf8')} for i in [504465,681004,503598,802097]}
(P/'research/donor.json').write_text(json.dumps(out,ensure_ascii=False,indent=2),encoding='utf8')
for i,x in out.items():
 r=x['row'];print(i,x['description'],'dur',r[40],'cd',r[29:31],'effects',r[71:74],'bp',r[80:83],'aura',r[95:98],'amp',r[98:101],'trigger',r[116:119],flush=True)
