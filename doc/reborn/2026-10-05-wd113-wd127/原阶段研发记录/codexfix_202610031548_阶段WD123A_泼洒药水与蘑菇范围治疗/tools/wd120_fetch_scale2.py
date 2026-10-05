from wd120_audit import *
sha=json.loads((P/'research/head.json').read_text())['sha']
for rel in ['src/server/coa/AscensionScalingBase.cpp','src/server/coa/AscensionScalingBaseData.h','docs/coa/level-scaling.md']:
 data=urllib.request.urlopen(urllib.request.Request('https://raw.githubusercontent.com/jealous-sound/azerothcore-wotlk-coa/'+sha+'/'+rel,headers={'User-Agent':'WD120'}),timeout=25).read()
 (P/'research'/Path(rel).name).write_bytes(data)
 print(rel,len(data))
