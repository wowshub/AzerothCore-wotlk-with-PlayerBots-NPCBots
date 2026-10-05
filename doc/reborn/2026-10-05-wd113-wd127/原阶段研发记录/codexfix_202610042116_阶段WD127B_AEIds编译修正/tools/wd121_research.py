# coding: utf-8
from pathlib import Path
import datetime,json,urllib.request,urllib.parse,shutil
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');B=Path(Path('wd120_path.txt').read_text())
stamp=datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=-7))).strftime('%Y%m%d%H%M')
f=Path('wd121_path.txt')
if not f.exists():f.write_text(str(R/f'000Ascendupdate/000Ascendupdate{stamp[:8]}/codexfix_{stamp}_阶段WD121A_酿造治疗双天赋'))
P=Path(f.read_text());(P/'research').mkdir(parents=True,exist_ok=True)
def get(url):return urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'WD121-audit'}),timeout=30).read()
api='https://api.github.com/repos/jealous-sound/azerothcore-wotlk-coa'
head=json.loads(get(api+'/commits/HEAD'));(P/'research/head.json').write_text(json.dumps(head));sha=head['sha'];print('HEAD',sha,flush=True)
for i,q in enumerate(['"Fresh Ingredients"','"Potion Boss"','705856 OR 707858 OR 561072','WitchDoctor']):
 data=get('https://api.github.com/search/issues?q='+urllib.parse.quote('repo:jealous-sound/azerothcore-wotlk-coa '+q));(P/f'research/search{i}.json').write_bytes(data);print([(x['number'],x['title'],x['state']) for x in json.loads(data).get('items',[])][:15],flush=True)
for name in ['AscensionWitchDoctorBrewing.cpp','AscensionWitchDoctorAbilities.cpp','AscensionWitchDoctorCompletion.cpp','AscensionWitchDoctorCoefficients.h']:
 (P/'research'/name).write_bytes(get('https://raw.githubusercontent.com/jealous-sound/azerothcore-wotlk-coa/'+sha+'/src/server/coa/'+name))
(P/'research/pull4753.json').write_bytes(get(api+'/pulls/4753'))
for name in ['preview_donor.json','node6498.txt','node29303.txt']:
 shutil.copy2(B/'research'/name,P/'research'/name)
print('research saved')
