from pathlib import Path
import struct,json,re,shutil
from wd19_common import dbc
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');P=Path(Path('wd120_path.txt').read_text());C=R/'beascendclient/newrebornWOWli20260929beAscend'
SF='01_覆盖到源代码根目录/';CF='02_覆盖到客户端根目录/';SRC='modules/mod-reborn-witchdoctor/src/'
def put(rel,s):
 f=P/rel;f.parent.mkdir(parents=True,exist_ok=True);f.write_bytes(s if isinstance(s,bytes) else s.encode('utf8'))
def pack(rows,pool):
 n=len(next(iter(rows.values())));return struct.pack('<4s4I',b'WDBC',len(rows),n,n*4,len(pool))+b''.join(struct.pack('<'+'I'*n,*r) for r in rows.values())+pool
put(SF+SRC+'RebornWitchDoctorBrewingFoundation.inc',Path('wd120_mechanics.inc').read_bytes())
f=P/SF/SRC/'RebornWitchDoctor.cpp';s=f.read_text(encoding='utf8');assert '#include "RebornWitchDoctorBrewingFoundation.inc"' not in s
s=s.replace('void AddRebornWitchDoctorScripts()', '#include "RebornWitchDoctorBrewingFoundation.inc"\n\nvoid AddRebornWitchDoctorScripts()').replace('    WD93A::Register();','    RegisterSpellScript(spell_reborn_wd120_brewing);\n    WD93A::Register();');f.write_text(s,encoding='utf8')
donor=json.loads((P/'research/donor.json').read_text(encoding='utf8'));ranks=json.loads((P/'research/rank_donor.json').read_text(encoding='utf8'))
icons=[]
for n in [4005,12645,12646]:
 node=(P/f'research/node{n}.txt').read_text(encoding='utf8');icon=re.search(r'\["Icon"\]="([^"]+)"',node)[1].replace('\\\\','\\');icons.append(icon);path=icon.replace('\\','/')+'.blp';data=(C/path).read_bytes();put(CF+path,data);put('client_mpq输入_导入现有Patch-XA/'+path,data)
mapping={92085:9003864,801660:9003865,802703:9003866,802973:9003867,801661:9003870,**{573430+i:9003871+i for i in range(6)}}
names={9003864:'大锅酿造 / Cauldron Brewer',9003865:'配料：丛林蘑菇 / Ingredient: Jungle Shrooms',9003866:'丛林蘑菇 / Jungle Shrooms',9003867:'丛林蘑菇 / Jungle Shrooms'}
desc={9003864:'可准备酿造配料。基础同时保留一种配料。本批开放丛林蘑菇。 / Prepare a brewing ingredient; one at a time. Jungle Shrooms is available in this batch.',9003865:'准备丛林蘑菇：每6秒治疗周围30码最多8名队友，基础值按角色等级缩放并增加20%治疗加成。药水投掷附加持续18秒、每3秒一次的治疗。取消配料或切出此方案后停止周期治疗。 / Prepare Jungle Shrooms: heal up to 8 raid allies within 30 yd every 6 sec, level-scaled base plus 20% bonus healing. Potion Toss adds a heal every 3 sec for 18 sec. Cancelling preparation or switching out stops the pulse.',9003866:'配料周期治疗。 / Ingredient periodic heal.',9003867:'每3秒恢复$s1生命值，持续18秒。 / Restores $s1 health every 3 sec for 18 sec.'}
for prefix in ['03_覆盖到服务端根目录/Data/dbc','client_mpq输入_导入现有Patch-XA/DBFilesClient']:
 raw=(P/prefix/'Spell.dbc').read_bytes();put('rollback_WD119C/'+prefix+'/Spell.dbc',raw);rows,pool=dbc(raw)
 for source,sid in mapping.items():
  assert sid not in rows,sid
  d=(donor.get(str(source)) or ranks[str(source)])['row'];r=d.copy();r[0]=sid
  r[1]=0;r[12:28]=[0]*16;r[28]=1;r[31]=12;r[32:37]=[0]*5;r[48:68]=[0]*20;r[68]=0xffffffff;r[69:71]=[0]*2
  r[122:131]=[0]*9;r[131:133]=[0]*2;r[134]=0;r[208:212]=[0]*4;r[217:225]=[0]*8;r[229:234]=[0]*5
  # Drop foreign extended attrs; retain native positive, passive and preparation flags explicitly.
  r[4:12]=[0,0,0,0,0,0,0,0];r[204:208]=[0,133,1500,0];r[225]=8;r[226:229]=[0]*3;r[224]=0xffffffff
  r[29]=15000 if sid>=9003870 else (500 if sid==9003865 else 0);r[30]=0
  r[133]=910123 if sid==9003864 else 910125 if sid>=9003870 else 910124
  if sid==9003864:
   r[4]=0x40;r[71:74]=[6,0,0];r[95:98]=[4,0,0];r[98:101]=[0]*3;r[116:119]=[0]*3;r[204:208]=[0]*4
  if sid==9003865:
   r[116]=9003866;r[204:208]=[0]*4
  if sid==9003866:
   r[204:208]=[0]*4;r[131]=rows[9003101][131]
  if sid==9003867:
   r[204:208]=[0]*4;r[131]=rows[9003101][131]
  if sid>=9003870:r[131]=rows[9003101][131]
  name=names.get(sid,'药水投掷 / Potion Toss');rank=('等级 %d / Rank %d'%(sid-9003869,sid-9003869)) if sid>=9003870 else ''
  description=desc.get(sid,'向友方投掷药水，基础治疗$s1，另加28%治疗加成和10%精神。需先准备配料；丛林蘑菇附加18秒持续治疗。冷却15秒。 / Toss a potion at an ally: base heal $s1 plus 28% bonus healing and 10% Spirit. Requires a prepared ingredient; Jungle Shrooms adds an 18 sec heal over time. 15 sec cooldown.')
  for start,text in [(136,name),(153,rank),(170,description),(187,description)]:
   off=len(pool);pool+=text.encode()+b'\0';r[start:start+16]=[off]*16
  rows[sid]=r
 put(prefix+'/Spell.dbc',pack(rows,pool))
 raw=(P/prefix/'SkillLineAbility.dbc').read_bytes();put('rollback_WD119C/'+prefix+'/SkillLineAbility.dbc',raw);rows,pool=dbc(raw)
 for sid in [9003864,9003865]+list(range(9003870,9003877)):
  assert not any(r[2]==sid for r in rows.values())
  r=next(r[:] for r in rows.values() if r[2]==9003621);r[0]=max(rows)+1;r[2]=sid;r[8]=sid+1 if 9003870<=sid<9003876 else 0;rows[r[0]]=r
 put(prefix+'/SkillLineAbility.dbc',pack(rows,pool))
prefix='client_mpq输入_导入现有Patch-XA/DBFilesClient';raw=(P/prefix/'SpellIcon.dbc').read_bytes();put('rollback_WD119C/'+prefix+'/SpellIcon.dbc',raw);rows,pool=dbc(raw)
for i,icon in enumerate(icons):
 assert 910123+i not in rows;rows[910123+i]=[910123+i,len(pool)];pool+=icon.encode()+b'\0'
put(prefix+'/SpellIcon.dbc',pack(rows,pool))
(P/'research/id_mapping.json').write_text(json.dumps(mapping,indent=2),encoding='utf8')
print('WD120 mechanics/data written')
