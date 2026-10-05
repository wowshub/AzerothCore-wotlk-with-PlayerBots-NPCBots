from pathlib import Path
import shutil,subprocess,json,struct
from wd19_common import dbc
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');B=Path(Path('wd116_path.txt').read_text(encoding='utf8'));P=Path(Path('wd117_path.txt').read_text(encoding='utf8'));T=P/'tools';T.mkdir(exist_ok=True);(P/'checks').mkdir(exist_ok=True)
for f in (B/'research').glob('*.tsv'):shutil.copy2(f,P/'research'/f.name)
for f in (B/'tools').glob('*.lua'):
 s=f.read_text(encoding='utf8').replace('MaskSet(pair,78,1,1)','MaskSet(pair,80,1,1)').replace('MaskSet(all,78,1,1)','MaskSet(all,80,1,1)').replace('MaskSet(combined,78,1,1)','MaskSet(combined,80,1,1)').replace('302231454903657293676544','1208925819614629174706176')
 (T/f.name).write_text(s,encoding='utf8')
s=(T/'scenario116.lua').read_text(encoding='utf8')+'''
M.pending=nil;M.level=80;M.aeBudget=56;M.teBudget=55
local base=123+2*2^44
local one=M.MaskSet(base,78,2,1);local two=M.MaskSet(base,78,2,2)
assert(M.IsAENode(9347) and M.AERank(9347,one)==1 and M.AERank(9347,two)==2)
assert(M.AESpent(one)==10 and M.AESpent(two)==11)
assert(M.AEValid(one) and M.AEValid(two))
assert(not M.AEValid(M.MaskSet(base,78,2,3)))
assert(not M.AEValid(M.MaskSet(base-1,78,2,1)))
assert(not M.AEValid(M.MaskSet(two,80,1,1)))
for spec=0,2 do M.specs[2]=spec;assert(M.AEValid(two)) end
M.aeBudget=10;assert(not M.AEValid(two));M.aeBudget=56
assert(M.AETooltip({ID=9347,AECost=1,TECost=0}))
M.aeMasks[2]=base;M.draftAE=two;M.aeDirty=true;M.dirty=true;M.pending=nil
local sent;M.Request=function(s)sent=s end;M.Save();assert(sent and sent:match(' '..M.MaskDecimal(two)..'$'))
print('PASS WD117 two ranks, foundation, budget, cross spec, 80-bit exact save')
''';(T/'scenario117.lua').write_text(s,encoding='utf8')
lua=R/'beascendBuild/modules/mod-ale/src/lualib/lua/RelWithDebInfo/lua52_interpreter.exe';cl=P/'02_覆盖到客户端根目录/Interface/AddOns/RebornWitchDoctorTalents'
def run(name,args):
 r=subprocess.run([str(lua)]+list(map(str,args)),capture_output=True,encoding='utf8',errors='replace');(P/'checks'/name).write_text(r.stdout+r.stderr,encoding='utf8');print(r.stdout,r.stderr);assert r.returncode==0
run('lua.txt',[T/'scenario117.lua',cl/'WD8.lua',cl/'Allocation.lua',T/'scenario87_regression.lua',T/'scenario88.lua',T/'scenario91.lua'])
(T/'check_syntax.lua').write_text('for i=1,#arg do assert(loadfile(arg[i])) end print("All packaged Lua syntax passed")',encoding='utf8')
run('syntax.txt',[T/'check_syntax.lua']+list(cl.rglob('*.lua')))
shutil.copytree(B/'rollback/server_SQL',P/'rollback/server_SQL',dirs_exist_ok=True)
s=(B/'tools/test_mysql.py').read_text(encoding='utf8').replace('_wd116_sql_scratch_','_wd117_sql_scratch_').replace('01_CHARACTERS_WD116A_必须执行.sql','01_CHARACTERS_WD117A_必须执行.sql').replace('2**78','2**80').replace('bit78 refused','bit80 refused')
marker=" rollback=(P/'rollback/server_SQL/01_CHARACTERS_WD105A.sql').read_text(encoding='utf8')"
block='''
 for g in range(140,144):
  q(f"INSERT INTO characters(guid,account,name,taximask,innTriggerId,race,class,money) VALUES({g},10,'new117{g}','',0,1,13,10000000); INSERT INTO reborn_wd5a_builds(guid) VALUES({g}); INSERT INTO reborn_wd67_members(guid,enabled) VALUES({g},1); INSERT INTO reborn_wd13_slots(guid,slot,paid_copper) VALUES({g},0,0),({g},1,10000000); INSERT INTO reborn_wd16_profiles VALUES({g},0,0),({g},1,1),({g},2,3);")
 walker=2**78
 ck('Walker cannot self-bootstrap',save(140,0,walker)=='0')
 ck('Walker rank1 saved',save(140,0,classbase+walker)=='1')
 ck('Walker rank1 row',q('SELECT node_rank FROM reborn_wd67_nodes WHERE guid=140 AND slot=0 AND node_id=9347')=='1')
 ck('Walker rank2 upgrade',save(140,1,classbase+2*walker)=='1')
 ck('Walker rank2 row',q('SELECT node_rank FROM reborn_wd67_nodes WHERE guid=140 AND slot=0 AND node_id=9347')=='2')
 ck('Walker no free downgrade',save(140,2,classbase+walker)=='0')
 ck('Walker rank3 invalid',save(141,0,classbase+3*walker)=='0')
 ck('Walker ninth foundation forbidden',save(141,0,classbase-1+walker)=='0')
 ck('Walker same-tier foundation forbidden',save(141,0,classbase-1+walker+vigil)=='0')
 ck('Walker Brewing profile',save(141,0,classbase+2*walker,slot=1)=='1')
 ck('Walker bit80 invalid',save(142,0,classbase+2**80)=='0')
 before=q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id;')
 q(install);ck('Walker schema reinstall preserves rows',before==q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id;'))
'''
assert marker in s;s=s.replace(marker,block+marker).replace('31118,12264,6042);','31118,12264,6042,9347);');(T/'test_mysql.py').write_text(s,encoding='utf8')
checks=[]
def ck(n,b):assert b,n;checks.append(n)
for prefix in ['03_覆盖到服务端根目录/Data/dbc','client_mpq输入_导入现有Patch-XA/DBFilesClient']:
 for name in ['Spell.dbc','SkillLineAbility.dbc']:
  rows,pool=dbc((P/prefix/name).read_bytes());old,op=dbc((B/prefix/name).read_bytes())
  for k,v in old.items():
   if name=='Spell.dbc' and k in [9003855,9003432]:ck(prefix+str(k)+' only text changed',rows[k][:170]==v[:170] and rows[k][186:]==v[186:])
   else:assert rows[k]==v,(prefix,name,k)
  ck(prefix+name+' prior mechanics preserved',True);ck(prefix+name+' pool prefix',pool.startswith(op))
  if name=='Spell.dbc':
   for sid,bp in [(9003857,9),(9003858,19)]:
    r=rows[sid];ck(prefix+str(sid)+' modifier ranks',r[95:98]==[108,108,0] and r[80:83]==[bp,bp,0] and r[110:113]==[1,3,0]);ck(prefix+str(sid)+' icon',r[133]==910118)
  else:ck(prefix+' each rank book mapping',all(sum(r[2]==sid for r in rows.values())==1 for sid in [9003857,9003858]))
src=P/'01_覆盖到源代码根目录/modules/mod-reborn-witchdoctor/src'
inc=(src/'RebornWitchDoctorAllocation.inc').read_text(encoding='utf8')
ck('rank2 load cap', 'index==69 || index==2' in inc)
ck('rank3 rejected','AERank(mask,69)>2' in inc)
ck('two-rank bit decode','(mask>>78)&3u' in inc)
(P/'checks/data.json').write_text(json.dumps(checks,indent=2),encoding='utf8');print(len(checks),'data checks passed; SQL ready')
