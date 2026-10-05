from pathlib import Path
import json,re,datetime,urllib.request,urllib.parse
from wd19_common import dbc,Archive
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO')
p=Path('wd119_path.txt')
if not p.exists():
 t=datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=-7)))
 P=R/('000Ascendupdate/000Ascendupdate'+t.strftime('%Y%m%d'))/('codexfix_'+t.strftime('%Y%m%d%H%M')+'_阶段WD119A_通用控制三技能')
 p.write_text(str(P),encoding='utf8')
P=Path(p.read_text(encoding='utf8'));(P/'research').mkdir(parents=True,exist_ok=True)
def online():
 def get(url):return urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'WD119-audit'}),timeout=30).read()
 base='https://api.github.com/repos/jealous-sound/azerothcore-wotlk-coa'
 h=json.loads(get(base+'/commits/HEAD'));(P/'research/head.json').write_text(json.dumps(h));print('HEAD',h['sha'],flush=True)
 for i,q in enumerate(['"Amphibimorph"','"Gonk" OR "Krag"','"Mirage" "Witch"','"500952" OR "806469" OR "807855"']):
  raw=get('https://api.github.com/search/issues?q='+urllib.parse.quote('repo:jealous-sound/azerothcore-wotlk-coa '+q));(P/f'research/search{i}.json').write_bytes(raw);print([(x['number'],x['title']) for x in json.loads(raw).get('items',[])],flush=True)
 for name in ['AscensionWitchDoctorCompletion.cpp','AscensionWitchDoctorAuras.cpp']:
  (P/'research'/name).write_bytes(get('https://raw.githubusercontent.com/jealous-sound/azerothcore-wotlk-coa/'+h['sha']+'/src/server/coa/'+name))
def local():
 a=Archive(Path('D:/game/ascend/coaWOW/coawowClinet20260925OFFICIAL/Data/patch-T.MPQ'));rows,pool=dbc(a.read('DBFilesClient\\Spell.dbc'));a.close()
 s=(R/'beascendclient/newrebornWOWli20260929beAscend/Interface/AddOns/RebornWitchDoctorTalents/Data.lua').read_text(encoding='utf-8-sig');out={}
 for n in s.split('{["ID"]=')[1:]:
  nid=int(n.split(',')[0])
  if nid not in [29747,6031,6525,12525,7154,11154]:continue
  (P/f'research/node{nid}.txt').write_text(n[:1500],encoding='utf8');print('NODE',n[:850])
  for sid in [int(x) for x in re.search(r'\["Spells"\]=\{(.*?)\}',n)[1].split(',')]:
   r=rows[sid];out[str(sid)]=dict(node=nid,row=r,name=pool[r[136]:].split(b'\0')[0].decode(),desc=pool[r[170]:].split(b'\0')[0].decode());print('SPELL',sid,out[str(sid)]['desc'],r[71:74],r[80:83],r[95:98],r[110:113])
 (P/'research/donor.json').write_text(json.dumps(out,ensure_ascii=False,indent=2),encoding='utf8')
if __name__=='__main__':
 import sys
 (online if 'online' in sys.argv else local)()
