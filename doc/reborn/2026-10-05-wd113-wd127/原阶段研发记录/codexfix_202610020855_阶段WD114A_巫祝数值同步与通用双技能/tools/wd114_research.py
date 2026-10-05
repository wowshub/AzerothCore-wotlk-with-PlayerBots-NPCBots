from pathlib import Path
import json,re,urllib.request,urllib.parse,shutil
import wd19_common as c
B=Path(Path('wd113_path.txt').read_text(encoding='utf8').strip())
P=c.R/'000Ascendupdate/000Ascendupdate20261002/codexfix_202610020855_阶段WD114A_巫祝数值同步与通用双技能'
P.mkdir(parents=True,exist_ok=True)
Path('wd114_path.txt').write_text(str(P),encoding='utf8')
for sub in ['research','checks','tools']: (P/sub).mkdir(exist_ok=True)
for sub in ['01_覆盖到源代码根目录','02_覆盖到客户端根目录','03_覆盖到服务端根目录','client_mpq输入_导入现有Patch-XA','server_SQL']:
 shutil.copytree(B/sub,P/sub,dirs_exist_ok=True)
s=(c.R/'beascendclient/newrebornWOWli20260929beAscend/Interface/AddOns/RebornWitchDoctorTalents/Data.lua').read_text(encoding='utf-8-sig')
for part in s.split('{["ID"]=')[1:]:
 if part.startswith(('31118,','12264,','6044,')):print(part[:650])
a=c.Archive(Path('D:/game/ascend/coaWOW/coawowClinet20260925OFFICIAL/Data/patch-T.MPQ'))
rows,pool=c.dbc(a.read('DBFilesClient\\Spell.dbc'))
raw=a.read('DBFilesClient\\SpellDuration.dbc');a.close()
if not raw:
 for mpq in Path('D:/game/ascend/coaWOW/coawowClinet20260925OFFICIAL/Data').glob('*.MPQ'):
  a=c.Archive(mpq);raw=a.read('DBFilesClient\\SpellDuration.dbc');a.close()
  if raw: print('Duration source',mpq);break
dur=c.dbc(raw)[0] if raw else {}
d=json.loads(Path('wd113_candidates.json').read_text(encoding='utf8'))
out=[v for v in d if v['node'] in [31118,12264,6381,12048,11323]]
for v in out:
 r=v['row'];v['duration']=dur.get(r[40]);print(v['node'],v['name'],'duration',v['duration'],'cost/cd',r[28:31],r[41:47],'attrs',r[4:12], 'effects',r[71:74],r[95:98],r[110:113])
(P/'research/donor.json').write_text(json.dumps(out,ensure_ascii=False,indent=2),encoding='utf8')
def get(url):return urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'WD114-source-audit'}),timeout=20).read()
try:
 h=json.loads(get('https://api.github.com/repos/jealous-sound/azerothcore-wotlk-coa/commits/HEAD'))
 (P/'research/head.json').write_text(json.dumps(h),encoding='utf8');print('HEAD',h['sha'],flush=True)
 for i,term in enumerate(['"Loa Empowerment"','"Death Draught"','"Potent Mixes"','is:pr Witch Doctor']):
  q='repo:jealous-sound/azerothcore-wotlk-coa '+term
  data=get('https://api.github.com/search/issues?q='+urllib.parse.quote(q)+'&sort=updated&per_page=8')
  (P/f'research/search{i}.json').write_bytes(data)
  print(term,[(v['number'],v['title']) for v in json.loads(data)['items']],flush=True)
 for f in (B/'research').glob('AscensionWitchDoctor*'):
  (P/'research'/f.name).write_bytes(get('https://raw.githubusercontent.com/jealous-sound/azerothcore-wotlk-coa/'+h['sha']+'/src/server/coa/'+f.name))
except Exception as e:
 (P/'research/online_failure.txt').write_text(str(e),encoding='utf8');print('ONLINE FAILURE',e)
