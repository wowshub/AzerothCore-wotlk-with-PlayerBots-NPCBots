from wd119_research import *
import sys,subprocess,os
if 'online' in sys.argv:
 def get(url):return urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'WD119-audit'}),timeout=30).read()
 base='https://api.github.com/repos/jealous-sound/azerothcore-wotlk-coa';sha=json.loads((P/'research/head.json').read_text())['sha']
 for suf in ['pulls/4753','pulls/4753/files','issues/934','issues/1179','issues/3693']:
  data=get(base+'/'+suf);(P/'research'/(suf.replace('/','_')+'.json')).write_bytes(data)
  j=json.loads(data)
  if isinstance(j,dict):print(suf,j.get('merged_at'),j.get('state'),j.get('body','')[:2200])
  else:print('files',[(x['filename']) for x in j])
 for n in ['AscensionWitchDoctorCompletion.h','AscensionWitchDoctor.cpp']:
  try:(P/'research'/n).write_bytes(get('https://raw.githubusercontent.com/jealous-sound/azerothcore-wotlk-coa/'+sha+'/src/server/coa/'+n))
  except Exception as e:print(n,e)
else:
 S=R/'beascendserver/wowshub_playerbot_npcbot_newrace20260929Ascend'
 d=json.loads((P/'research/donor.json').read_text(encoding='utf8'));out={}
 for name,idx in [('SpellDuration',40),('SpellCastTimes',28),('SpellRange',46),('SpellRadius',92)]:
  rows,pool=dbc((S/f'Data/dbc/{name}.dbc').read_bytes());out[name]={sid:rows.get(x['row'][idx]) for sid,x in d.items()};print(name,out[name])
 for sid in ['500952','806469','807855']:
  r=d[sid]['row'];print(sid,[(i,x) for i,x in enumerate(r[:136]) if x],r[204:232])
 (P/'research/references.json').write_text(json.dumps(out,indent=2))
 cfg=(S/'configs/worldserver.conf').read_text(encoding='utf-8-sig');f=re.search(r'^WorldDatabaseInfo\s*=\s*(.+)',cfg,re.M)[1].strip().strip('"').split(';');env=os.environ.copy();env['MYSQL_PWD']=f[3]
 q="SELECT entry,name,type FROM creature_template WHERE entry IN(216377,16398,990031) OR name='Frog'; SELECT * FROM creature_template_model WHERE CreatureID IN(216377,16398,990031); SELECT spell_id,ScriptName FROM spell_script_names WHERE spell_id BETWEEN 9003861 AND 9003863;"
 result=subprocess.run([str(S/'mysql-8.0.31-winx64/bin/mysql.exe'),'--connect-timeout=5','-h',f[0],'-P',f[1],'-u',f[2],f[4],'-B'],input=q,env=env,capture_output=True,encoding='utf8');print(result.stdout,result.stderr);(P/'research/world_readonly.tsv').write_text(result.stdout or result.stderr,encoding='utf8')
