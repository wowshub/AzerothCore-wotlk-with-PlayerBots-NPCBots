from pathlib import Path
import shutil,subprocess,json,re,struct
import wd19_common as c
P=Path(Path('wd114_path.txt').read_text(encoding='utf8').strip());B=Path(Path('wd113_path.txt').read_text(encoding='utf8').strip());T=P/'tools'
for f in (B/'research').glob('*.tsv'):shutil.copy2(f,P/'research'/f.name)
for f in (B/'tools').glob('*.lua'):
 s=f.read_text(encoding='utf8').replace('37778931862957161709568','151115727451828646838272').replace('M.MaskSet(all,75,1,1)','M.MaskSet(all,77,1,1)').replace('not M.IsAENode(12264)','not M.IsAENode(6044)')
 (T/f.name).write_text(s,encoding='utf8')
shutil.copytree(B/'rollback/server_SQL',P/'rollback/server_SQL',dirs_exist_ok=True)
sql=(B/'tools/test_mysql.py').read_text(encoding='utf8').replace('_wd113_sql_scratch_','_wd114_sql_scratch_').replace('01_CHARACTERS_WD113A_必须执行.sql','01_CHARACTERS_WD114A_必须执行.sql').replace('classbase+2**75','classbase+2**77')
marker=" rollback=(P/'rollback/server_SQL/01_CHARACTERS_WD105A.sql').read_text(encoding='utf8')"
block=''' # WD114 cumulative exact high bits and unchanged previous layouts.
 for g in range(120,127):
  q(f"INSERT INTO characters(guid,account,name,taximask,innTriggerId,race,class,money) VALUES({g},10,'new114{g}','',0,1,13,10000000); INSERT INTO reborn_wd5a_builds(guid) VALUES({g}); INSERT INTO reborn_wd67_members(guid,enabled) VALUES({g},1); INSERT INTO reborn_wd13_slots(guid,slot,paid_copper) VALUES({g},0,0),({g},1,10000000); INSERT INTO reborn_wd16_profiles VALUES({g},0,0),({g},1,1),({g},2,3);")
 death,potent=2**75,2**76
 ck('WD114 Death level9 refused',save(120,0,death,9)=='0')
 ck('WD114 Death one AE at10',save(120,0,death,10)=='1')
 ck('WD114 Death same layout retained',save(120,1,death,10)=='1')
 ck('WD114 no free Death refund',save(120,2,0,10)=='0')
 ck('WD114 Potent needs foundation',save(121,0,potent)=='0')
 ck('WD114 Potent owns one AE',save(121,0,classbase+potent)=='1')
 ck('WD114 Potent cannot bootstrap itself',save(122,0,classbase-1+potent)=='0')
 ck('WD114 Death counts as foundation',save(122,0,classbase-1+death+potent)=='1')
 ck('WD114 new pair cross spec',save(122,1,classbase+death+potent,slot=1)=='1')
 ck('WD114 existing113 nodes remain',save(123,0,classbase+sum(newbits)+death+potent)=='1')
 ck('WD114 bit67 still forbidden',save(124,0,classbase+death+potent+2**67)=='0')
 ck('WD114 bit77 refused',save(124,0,classbase+2**77)=='0')
 ck('WD114 wrong account refused',save(124,0,death,account=11)=='0')
 ck('WD114 new pair budget checked',save(124,0,classbase+death+potent,20)=='0')
 before=q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id;')
 q(install);ck('WD114 reinstall leaves every old and new node intact',before==q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id;'))
'''
assert marker in sql;sql=sql.replace(marker,block+marker).replace('6381,12048,11323);','6381,12048,11323,31118,12264);')
(T/'test_mysql.py').write_text(sql,encoding='utf8')
scenario=(T/'scenario113.lua').read_text(encoding='utf8')+'''
M.pending=nil;M.level=80;M.slot=1;M.specs={0,1,3};M.aeBudget=56;M.teBudget=55
local foundation=123+2*2^44
local death=M.MaskSet(0,75,1,1);local potent=M.MaskSet(0,76,1,1)
assert(M.AERank(31118,death)==1 and M.AESpent(death)==1 and M.TESpent(death)==0)
M.level=9;assert(not M.AEValid(death));M.level=10;assert(M.AEValid(death));M.level=80
assert(not M.AEValid(potent))
local pair=M.MaskSet(M.MaskSet(foundation,75,1,1),76,1,1)
assert(M.AEValid(pair) and M.AESpent(pair)==11)
assert(M.AEValid(M.MaskSet(pair,0,1,0))) -- low tier Death can supply ninth foundation point
assert(not M.AEValid(M.MaskSet(M.MaskSet(pair,0,1,0),75,1,0)))
for spec=0,2 do M.specs[2]=spec;assert(M.AEValid(pair)) end
assert(not M.AEValid(M.MaskSet(pair,67,1,1)))
assert(not M.AEValid(M.MaskSet(pair,77,1,1)))
M.aeBudget=10;assert(not M.AEValid(pair));M.aeBudget=56
for _,id in ipairs({31118,12264}) do assert(M.AETooltip({ID=id,AECost=1,TECost=0})) end
M.aeMasks[2]=foundation;M.draftAE=pair;M.aeDirty=true;M.dirty=true;M.pending=nil
local sent;M.Request=function(s)sent=s end;M.Save();assert(sent and sent:match(' '..M.MaskDecimal(pair)..'$'))
print('PASS WD114 two nodes, old builds, cross spec, foundation, budget, level, 77-bit save')
'''
(T/'scenario114.lua').write_text(scenario,encoding='utf8')
lua=c.R/'beascendBuild/modules/mod-ale/src/lualib/lua/RelWithDebInfo/lua52_interpreter.exe';cl=P/'02_覆盖到客户端根目录/Interface/AddOns/RebornWitchDoctorTalents'
run=subprocess.run([str(lua),str(T/'scenario114.lua'),str(cl/'WD8.lua'),str(cl/'Allocation.lua'),str(T/'scenario87_regression.lua'),str(T/'scenario88.lua'),str(T/'scenario91.lua')],capture_output=True,encoding='utf8',errors='replace')
(P/'checks/lua_results.txt').write_text(run.stdout+run.stderr,encoding='utf8');print(run.stdout,run.stderr);assert run.returncode==0
checks=[]
def ck(name,test):assert test,name;checks.append(name)
fmt=re.search(r'SpellEntryfmt\[\] = "([^"]+)"',(c.CODE/'src/server/shared/DataStores/DBCfmt.h').read_text())[1]
for prefix in ['03_覆盖到服务端根目录/Data/dbc','client_mpq输入_导入现有Patch-XA/DBFilesClient']:
 for name in ['Spell.dbc','SkillLineAbility.dbc']:
  rows,pool=c.dbc((P/prefix/name).read_bytes());old,op=c.dbc((B/prefix/name).read_bytes())
  ck(prefix+name+' old rows unchanged',all(rows[k]==v for k,v in old.items()))
  ck(prefix+name+' original string pool preserved',pool.startswith(op))
  if name=='Spell.dbc':
   fields=set(i for i,x in enumerate(fmt)if x=='s')|set(j for i in [136,153,170,187]for j in range(i,i+16))
   ck(prefix+' all string offsets valid',all(r[j]<len(pool) and pool.find(b'\0',r[j])>=0 for r in rows.values()for j in fields))
   ck(prefix+' native Feign Death effect and interrupts',rows[9003853][71:74]==[6,0,0] and rows[9003853][95]==66 and rows[9003853][31:35]==rows[5384][31:35])
   ck(prefix+' five minutes thirty seconds from cast',rows[9003853][40]==5 and rows[9003853][29]==30000 and not rows[9003853][4]&0x02000000)
   ck(prefix+' Potent heals4 threat15',rows[9003854][95:97]==[136,108] and rows[9003854][80:82]==[3,2**32-16] and rows[9003854][111]==2)
   ck(prefix+' Wuju exact numeric modifier preserved',rows[9003850][80:82]==[2**32-51,19])
   ck(prefix+' all new self-only effects',rows[9003853][86]==1 and rows[9003854][86:88]==[1,1])
   # Fixed-range effects only for the read-only value preview; no random draw.
   ck(prefix+' numeric preview no dice randomness',all(rows[i][74:76]==[1,1] for i in [9003180,9003181,9003182,9003183,9003184,9003185,9003300]))
src=(P/'01_覆盖到源代码根目录/modules/mod-reborn-witchdoctor/src/RebornWitchDoctorTalents.cpp').read_text(encoding='utf8')
fn=src.split('bool SpellNumbers(')[1].split('class Commands')[0]
ck('read endpoint no SQL/load/mutation calls',not any(x in fn for x in ['CharacterDatabase','learnSpell','removeSpell','CastSpell','Ready(','Load(']))
ck('read endpoint calls actual server calculators','info->CalcPowerCost(p,info->GetSchoolMask())'in fn and 'CalculateSpellDamage(p,info,EFFECT_0)'in fn)
ck('self and whitelist only','!p->HasSpell(id)'in fn and '!allowed'in fn and 'Doctor(p)'in fn)
inc=(P/'01_覆盖到源代码根目录/modules/mod-reborn-witchdoctor/src/RebornWitchDoctorAllocation.inc').read_text(encoding='utf8')
ck('empty unbound slot fix preserved','if(spec==3) return mask==0;'in inc)
ck('reserved bit67 stays forbidden','if(AERank(mask,58) ||'in inc)
ck('native passive recovery present','if(!p->HasAura(class113[i])) p->CastSpell(p,class113[i],true);'in inc)
ck('active cannot auto cast Death','if(i==1 && !p->HasAura(id))'in inc)
ck('remove talent removes aura and ability','p->RemoveAurasDueToSpell(id,p->GetGUID());'in inc)
(P/'checks/static_data.json').write_text(json.dumps(checks,ensure_ascii=False,indent=2),encoding='utf8');print(len(checks),'static/data checks passed')
