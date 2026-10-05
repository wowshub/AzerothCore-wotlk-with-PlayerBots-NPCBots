from pathlib import Path
import shutil,subprocess,json,re,struct,hashlib
import wd19_common as c
P=Path(Path('wd113_path.txt').read_text(encoding='utf8'));B=Path(Path('wd112_path.txt').read_text(encoding='utf8'));T=P/'tools';T.mkdir(exist_ok=True);(P/'checks').mkdir(exist_ok=True)
for f in (B/'tools').glob('*.lua'):
 (T/f.name).write_text(f.read_text(encoding='utf8').replace('4722366482869645213696','37778931862957161709568'),encoding='utf8')
for f in (B/'research').glob('*.tsv'):shutil.copy2(f,P/'research'/f.name)
for f in (B/'rollback/server_SQL').glob('*'):
 d=P/'rollback/server_SQL'/f.name;d.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(f,d)
shutil.copy2(B/'server_SQL/02_WORLD_WD112A_必须执行.sql',P/'server_SQL/02_WORLD_WD112A_必须执行.sql')
for prefix in ['03_覆盖到服务端根目录/Data/dbc','client_mpq输入_导入现有Patch-XA/DBFilesClient']:
 for name in ['Spell.dbc','SkillLineAbility.dbc']:
  d=P/'rollback_WD112'/prefix/name;d.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(B/prefix/name,d)
sql=(B/'tools/test_mysql.py').read_text(encoding='utf8').replace('_wd112_sql_scratch_','_wd113_sql_scratch_').replace('01_CHARACTERS_WD112A_必须执行.sql','01_CHARACTERS_WD113A_必须执行.sql')
marker=" rollback=(P/'rollback/server_SQL/01_CHARACTERS_WD105A.sql').read_text(encoding='utf8')"
block=''' # WD113 exact 75-bit Class ownership, prerequisites, choices and persistence.
 for g in range(100,111):
  q(f"INSERT INTO characters(guid,account,name,taximask,innTriggerId,race,class,money) VALUES({g},10,'new113{g}','',0,1,13,10000000); INSERT INTO reborn_wd5a_builds(guid) VALUES({g}); INSERT INTO reborn_wd67_members(guid,enabled) VALUES({g},1); INSERT INTO reborn_wd13_slots(guid,slot,paid_copper) VALUES({g},0,0),({g},1,10000000); INSERT INTO reborn_wd16_profiles VALUES({g},0,0),({g},1,1),({g},2,3);")
 newbits=[2**72,2**73,2**74]
 for j,bit in enumerate(newbits):
  ck('WD113 foundation required '+str(j),save(100+j,0,bit)=='0')
  ck('WD113 node save '+str(j),save(100+j,0,classbase+bit)=='1')
  ck('WD113 repeat read '+str(j),save(100+j,1,classbase+bit)=='1')
  ck('WD113 no free refund '+str(j),save(100+j,2,classbase)=='0')
  ck('WD113 class cross spec '+str(j),save(100+j,2,classbase+bit,slot=1)=='1')
 ck('WD113 all three exact decimal',save(103,0,classbase+sum(newbits))=='1')
 ck('WD113 repeated upgrade keeps all nodes',q('SELECT COUNT(*) FROM reborn_wd67_nodes WHERE guid=103 AND node_id IN(6381,12048,11323)')=='3')
 ck('WD113 mutual exclusion DarkMojo',save(104,0,classbase+2**54+2**73)=='0')
 ck('WD113 same tier cannot bootstrap',save(104,0,classbase-1+sum(newbits))=='0')
 ck('WD113 budget enforced',save(104,0,classbase+sum(newbits),30)=='0')
 ck('WD113 high bit rejected',save(104,0,classbase+2**75)=='0')
 ck('WD113 original DarkMojo valid',save(104,0,classbase+2**54)=='1')
 before=q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id;')
 q(install);ck('WD113 reinstallation retains rows',before==q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id;'))
'''
assert marker in sql;sql=sql.replace(marker,block+marker)
sql=sql.replace('5113,30891,6030,7132,29753);','5113,30891,6030,7132,29753,6381,12048,11323);')
(T/'test_mysql.py').write_text(sql,encoding='utf8')
scenario=(T/'scenario112.lua').read_text(encoding='utf8')+'''
M.level=80;M.slot=1;M.specs={0,1,3};M.aeBudget=56;M.teBudget=55
local base=123+2*2^44
local all=base
for j,id in ipairs({6381,12048,11323}) do
 local mask=M.MaskSet(base,71+j,1,1)
 assert(M.AERank(id,mask)==1 and M.AEValid(mask) and M.AESpent(mask)==10 and M.TESpent(mask)==0)
 assert(not M.AEValid(M.MaskSet(0,71+j,1,1)))
 for spec=0,2 do M.specs[2]=spec;assert(M.AEValid(mask)) end
 all=M.MaskSet(all,71+j,1,1)
 assert(M.AETooltip({ID=id,AECost=1,TECost=0}))
end
assert(M.AEValid(all) and M.AESpent(all)==12)
assert(not M.AEValid(M.MaskSet(all,0,1,0)))
assert(not M.AEValid(M.MaskSet(all,54,1,1)))
assert(not M.AEValid(M.MaskSet(all,75,1,1)))
M.aeBudget=11;assert(not M.AEValid(all));M.aeBudget=12;assert(M.AEValid(all))
M.aeMasks[2]=base;M.draftAE=all;M.aeDirty=true;M.dirty=true;M.pending=nil
local payload;M.Request=function(s)payload=s end;M.Save();assert(payload and payload:match(' '..M.MaskDecimal(all)..'$'))
print('PASS WD113 three high Class bits, ownership, cross-spec, foundation, mutually exclusive Dark Mojo, budget, exact save, tooltip')
'''
(T/'scenario113.lua').write_text(scenario,encoding='utf8')
lua=c.R/'beascendBuild/modules/mod-ale/src/lualib/lua/RelWithDebInfo/lua52_interpreter.exe';cl=P/'02_覆盖到客户端根目录/Interface/AddOns/RebornWitchDoctorTalents'
run=subprocess.run([str(lua),str(T/'scenario113.lua'),str(cl/'WD8.lua'),str(cl/'Allocation.lua'),str(T/'scenario87_regression.lua'),str(T/'scenario88.lua'),str(T/'scenario91.lua')],capture_output=True,encoding='utf8',errors='replace')
(P/'checks/lua_results.txt').write_text(run.stdout+run.stderr,encoding='utf8');print(run.stdout,run.stderr);assert run.returncode==0
checks=[]
def ck(name,test):assert test,name;checks.append(name)
fmt=re.search(r'SpellEntryfmt\[\] = "([^"]+)"',(c.CODE/'src/server/shared/DataStores/DBCfmt.h').read_text())[1]
for prefix in ['03_覆盖到服务端根目录/Data/dbc','client_mpq输入_导入现有Patch-XA/DBFilesClient']:
 for name in ['Spell.dbc','SkillLineAbility.dbc']:
  rows,pool=c.dbc((P/prefix/name).read_bytes());old,op=c.dbc((B/prefix/name).read_bytes())
  ck(prefix+'/'+name+' old rows unchanged',all(rows[k]==v for k,v in old.items()))
  ck(prefix+'/'+name+' string prefix preserved',pool.startswith(op))
  if name=='Spell.dbc':
   fields=set(i for i,x in enumerate(fmt)if x=='s')|set(j for i in [136,153,170,187]for j in range(i,i+16))
   ck(prefix+' all strings valid',all(r[j]<len(pool) and pool.find(b'\0',r[j])>=0 for r in rows.values()for j in fields))
   for id in [9003850,9003851,9003852]:
    r=rows[id];ck(prefix+str(id)+' permanent self passive',r[4]&64 and r[40]==rows[9003830][40] and r[86]==1)
    ck(prefix+str(id)+' no broad family',r[208:212]==[0]*4)
   def val(id,col):return struct.unpack('<i',struct.pack('<I',rows[id][col]))[0]+1
   ck(prefix+' Wuju -50/+20',val(9003850,80)==-50 and val(9003850,81)==20 and rows[9003850][74:76]==[1,1])
   ck(prefix+' Hexbreak +1 flat',val(9003851,80)==1 and rows[9003851][95]==107 and rows[9003851][110]==3)
   ck(prefix+' Jinx -25',val(9003852,80)==-25 and rows[9003852][95]==108 and rows[9003852][110]==14)
inc=(P/'01_覆盖到源代码根目录/modules/mod-reborn-witchdoctor/src/RebornWitchDoctorAllocation.inc').read_text(encoding='utf8')
ck('reserved67 blocked','if(AERank(mask,58) ||' in inc)
ck('empty unbound spec allowed','if(spec==3) return mask==0;'in inc)
ck('same-tier exclusion','-AERank(mask,63)-AERank(mask,64)-AERank(mask,65)<9' in inc)
ck('passive cleanup explicit','p->RemoveAurasDueToSpell(class113[i],p->GetGUID())'in inc)
(P/'checks/static_data.json').write_text(json.dumps(checks,ensure_ascii=False,indent=2),encoding='utf8');print(len(checks),'static/data checks passed')
