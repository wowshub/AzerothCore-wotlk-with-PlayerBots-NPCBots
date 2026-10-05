from wd119_research import R,P
from wd19_common import dbc,Archive
import urllib.request,json,struct
def get(url):return urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'WD119-audit'}),timeout=30).read()
sha=json.loads((P/'research/head.json').read_text())['sha'];root='https://raw.githubusercontent.com/jealous-sound/azerothcore-wotlk-coa/'+sha+'/'
for path in ['src/server/coa/AscensionWitchDoctorAbilities.cpp','apps/coa-gameplay-test/scenarios/witchdoctor-amphibimorph-blessings.json','apps/coa-gameplay-test/scenarios/witchdoctor-fix-934-amphibimorph-pvp-clauses.json']:
 (P/'research'/path.split('/')[-1]).write_bytes(get(root+path))
