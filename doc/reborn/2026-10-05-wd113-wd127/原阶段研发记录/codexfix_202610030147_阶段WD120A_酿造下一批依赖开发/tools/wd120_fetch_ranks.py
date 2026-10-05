from wd120_audit import *
sha=json.loads((P/'research/head.json').read_text())['sha']
for rel in ['data/sql/base/db_world/spell_ranks.sql','data/sql/updates/pending_db_world/rev_20260909_00_witch_doctor_completion.sql']:
 data=urllib.request.urlopen(urllib.request.Request('https://raw.githubusercontent.com/jealous-sound/azerothcore-wotlk-coa/'+sha+'/'+rel,headers={'User-Agent':'WD120'}),timeout=25).read()
 (P/'research'/('upstream_'+Path(rel).name)).write_bytes(data)
 print(rel,len(data))
