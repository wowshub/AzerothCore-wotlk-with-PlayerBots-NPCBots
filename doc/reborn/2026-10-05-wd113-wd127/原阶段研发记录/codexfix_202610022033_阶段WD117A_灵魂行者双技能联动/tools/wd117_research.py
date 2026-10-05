from pathlib import Path
import json,urllib.request,urllib.parse,datetime
from wd19_common import dbc
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');B=Path(Path('wd116_path.txt').read_text(encoding='utf8'))
stamp=(datetime.datetime.now(datetime.timezone.utc)-datetime.timedelta(hours=7)).strftime('%Y%m%d%H%M');P=R/('000Ascendupdate/000Ascendupdate'+stamp[:8])/('codexfix_'+stamp+'_阶段WD117A_灵魂行者双技能联动')
P.mkdir(parents=True,exist_ok=True);(P/'research').mkdir(exist_ok=True);Path('wd117_path.txt').write_text(str(P),encoding='utf8')
def get(url):return urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'WD117-audit'}),timeout=25).read()
base='https://api.github.com/repos/jealous-sound/azerothcore-wotlk-coa'
h=json.loads(get(base+'/commits/HEAD'));(P/'research/head.json').write_text(json.dumps(h));print('HEAD',h['sha'],flush=True)
for i,q in enumerate(['"Spirit Walker"','is:pr "Spirit Walker"']):
 raw=get('https://api.github.com/search/issues?q='+urllib.parse.quote('repo:jealous-sound/azerothcore-wotlk-coa '+q));(P/f'research/search{i}.json').write_bytes(raw);print([(x['number'],x['title']) for x in json.loads(raw).get('items',[])],flush=True)
for name in ['AscensionWitchDoctorCompletion.cpp','AscensionWitchDoctorAuras.cpp']:(P/'research'/name).write_bytes(get('https://raw.githubusercontent.com/jealous-sound/azerothcore-wotlk-coa/'+h['sha']+'/src/server/coa/'+name))
d=json.loads(Path('wd113_candidates.json').read_text(encoding='utf8'));(P/'research/donor.json').write_text(json.dumps([x for x in d if x['node']==9347],ensure_ascii=False,indent=2),encoding='utf8')
rows,pool=dbc((B/'03_覆盖到服务端根目录/Data/dbc/Spell.dbc').read_bytes())
for id in [9003432,9003433,9003855,9003856]:
 r=rows[id];print(id,'duration',r[40],'effects',r[71:74],'bp',r[80:83],'auras',r[95:98],pool[r[170]:].split(b'\0')[0].decode('utf8'),flush=True)
