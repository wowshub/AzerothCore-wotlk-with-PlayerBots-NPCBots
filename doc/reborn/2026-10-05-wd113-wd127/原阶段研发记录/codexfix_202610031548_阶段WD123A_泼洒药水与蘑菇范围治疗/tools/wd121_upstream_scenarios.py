from pathlib import Path
import urllib.request,json
P=Path(Path('wd121_path.txt').read_text());sha=json.loads((P/'research/head.json').read_text())['sha']
for name in ['witchdoctor-cauldron-effectiveness-spellmods.json','witchdoctor-percent-effectiveness-passives.json']:
 url='https://raw.githubusercontent.com/jealous-sound/azerothcore-wotlk-coa/'+sha+'/apps/coa-gameplay-test/scenarios/'+name
 data=urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'WD121'}),timeout=25).read();(P/'research'/name).write_bytes(data);print(name,data.decode()[:12000])
