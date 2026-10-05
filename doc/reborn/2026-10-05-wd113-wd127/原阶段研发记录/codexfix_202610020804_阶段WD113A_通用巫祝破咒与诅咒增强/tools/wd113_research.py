from pathlib import Path
import json,urllib.request,urllib.parse,hashlib
import wd19_common as c
B=Path(Path('wd112_path.txt').read_text(encoding='utf8'))
P=c.R/'000Ascendupdate/000Ascendupdate20261002/codexfix_202610020900_阶段WD113A_通用巫祝破咒与诅咒增强'
P.mkdir(parents=True,exist_ok=True);(P/'research').mkdir(exist_ok=True)
Path('wd113_path.txt').write_text(str(P),encoding='utf8')
def get(url):return urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'WD113-source-audit'}),timeout=25).read()
base='https://api.github.com/repos/jealous-sound/azerothcore-wotlk-coa'
try:
 h=json.loads(get(base+'/commits/HEAD'));(P/'research/head.json').write_text(json.dumps(h),encoding='utf8');print('HEAD',h['sha'],flush=True)
 for i,q in enumerate(['"Loa Empowerment"','"Blessing of Hir"','"Blatant Curse"']):
  d=json.loads(get('https://api.github.com/search/issues?q='+urllib.parse.quote('repo:jealous-sound/azerothcore-wotlk-coa '+q)))
  (P/f'research/search{i}.json').write_text(json.dumps(d),encoding='utf8')
  print(q,[(v['number'],v['title'])for v in d.get('items',[])],flush=True)
 for f in (B/'research').glob('AscensionWitchDoctor*'):
  data=get('https://raw.githubusercontent.com/jealous-sound/azerothcore-wotlk-coa/'+h['sha']+'/src/server/coa/'+f.name)
  (P/'research'/f.name).write_bytes(data)
except Exception as e:
 (P/'research/online_failure.txt').write_text(str(e),encoding='utf8');print(type(e).__name__,str(e),flush=True)
raw=Path('wd113_candidates.json').read_bytes();d=json.loads(raw)
(P/'research/donor.json').write_text(json.dumps([v for v in d if v['node'] in [6381,12048,11323]],ensure_ascii=False,indent=2),encoding='utf8')
print('research complete')
