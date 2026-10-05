from pathlib import Path
import json,urllib.request,urllib.parse,datetime,re
from wd19_common import dbc,Archive
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');B=Path(Path('wd117_path.txt').read_text(encoding='utf8'));old=Path(Path('wd118_path.txt').read_text(encoding='utf8'))
P=old.with_name(old.name.replace('森金之临施法联动','化蛇通用生存技能'));P.mkdir(exist_ok=True);(P/'research').mkdir(exist_ok=True);Path('wd118_path.txt').write_text(str(P),encoding='utf8')
def get(url):return urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'WD118-audit'}),timeout=25).read()
base='https://api.github.com/repos/jealous-sound/azerothcore-wotlk-coa';h=json.loads(get(base+'/commits/HEAD'));(P/'research/head.json').write_text(json.dumps(h));print(h['sha'],flush=True)
for i,q in enumerate(['"Slither"','"500947" OR "806295"','is:pr "Slither"']):
 raw=get('https://api.github.com/search/issues?q='+urllib.parse.quote('repo:jealous-sound/azerothcore-wotlk-coa '+q));(P/f'research/search{i}.json').write_bytes(raw);print([(x['number'],x['title']) for x in json.loads(raw).get('items',[])],flush=True)
for suffix in ['pulls/6192','pulls/6192/files']:(P/'research'/('pr6192'+('_files' if suffix.endswith('files') else '')+'.json')).write_bytes(get(base+'/'+suffix))
for name in ['AscensionWitchDoctorCompletion.cpp','AscensionWitchDoctorAuras.cpp']:
 try:(P/'research'/name).write_bytes(get('https://raw.githubusercontent.com/jealous-sound/azerothcore-wotlk-coa/'+h['sha']+'/src/server/coa/'+name))
 except Exception as e:print(name,str(e))
a=Archive(Path('D:/game/ascend/coaWOW/coawowClinet20260925OFFICIAL/Data/patch-T.MPQ'));rows,pool=dbc(a.read('DBFilesClient\\Spell.dbc'));a.close()
# Patch-T omits the native duration table; compare the verified native local table and PR6192's 5s contract.
duration,dp=dbc((R/'beascendserver/wowshub_playerbot_npcbot_newrace20260929Ascend/Data/dbc/SpellDuration.dbc').read_bytes())
out={}
for sid in [500947,806295]:
 r=rows[sid];out[str(sid)]=dict(row=r,name=pool[r[136]:].split(b'\0')[0].decode('utf8'),desc=pool[r[170]:].split(b'\0')[0].decode('utf8'),duration=duration.get(r[40]));print(out[str(sid)],flush=True)
(P/'research/donor.json').write_text(json.dumps(out,ensure_ascii=False,indent=2),encoding='utf8')
s=(R/'beascendclient/newrebornWOWli20260929beAscend/Interface/AddOns/RebornWitchDoctorTalents/Data.lua').read_text(encoding='utf-8-sig');n=next(x for x in s.split('{["ID"]=')[1:] if x.startswith('29306,'));(P/'research/node.txt').write_text(n[:n.index('},',n.index('["Spells"]'))+2],encoding='utf8');print(n[:1500])
