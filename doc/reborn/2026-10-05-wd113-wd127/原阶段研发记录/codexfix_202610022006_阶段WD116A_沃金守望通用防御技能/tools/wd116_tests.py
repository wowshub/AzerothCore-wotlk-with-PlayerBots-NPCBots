from pathlib import Path
import shutil,subprocess,json,re,struct
from wd19_common import dbc
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');P=Path(Path('wd116_path.txt').read_text(encoding='utf8'));B=Path(Path('wd114_path.txt').read_text(encoding='utf8').strip());V=Path(Path('wd115_path.txt').read_text(encoding='utf8'))
T=P/'tools';T.mkdir(exist_ok=True);(P/'checks').mkdir(exist_ok=True)
for file in (B/'research').glob('*.tsv'):shutil.copy2(file,P/'research'/file.name)
for file in (B/'tools').glob('*.lua'):
 s=file.read_text(encoding='utf8').replace('MaskSet(pair,77,1,1)','MaskSet(pair,78,1,1)').replace('MaskSet(all,77,1,1)','MaskSet(all,78,1,1)').replace('151115727451828646838272','302231454903657293676544')
 (T/file.name).write_text(s,encoding='utf8')
lua=R/'beascendBuild/modules/mod-ale/src/lualib/lua/RelWithDebInfo/lua52_interpreter.exe';cl=P/'02_覆盖到客户端根目录/Interface/AddOns/RebornWitchDoctorTalents'
s=(T/'scenario114.lua').read_text(encoding='utf8')+'''
M.pending=nil;M.level=80;M.aeBudget=56;M.teBudget=55;M.slot=1
local foundation=123+2*2^44
local vigil=M.MaskSet(0,77,1,1)
local combined=M.MaskSet(foundation,77,1,1)
assert(M.IsAENode(6042) and M.AERank(6042,vigil)==1)
assert(M.AESpent(vigil)==1 and M.TESpent(vigil)==0)
assert(not M.AEValid(vigil))
assert(M.AEValid(combined))
assert(not M.AEValid(M.MaskSet(combined,0,1,0)))
for spec=0,2 do M.specs[2]=spec;assert(M.AEValid(combined)) end
M.aeBudget=9;assert(not M.AEValid(combined));M.aeBudget=56
assert(not M.AEValid(M.MaskSet(combined,78,1,1)))
assert(M.AETooltip({ID=6042,AECost=1,TECost=0}))
M.aeMasks[2]=foundation;M.draftAE=combined;M.aeDirty=true;M.dirty=true;M.pending=nil
local sent;M.Request=function(s)sent=s end;M.Save();assert(sent and sent:match(' '..M.MaskDecimal(combined)..'$'))
print('PASS WD116 Vigil 78-bit ownership, exact save, cross spec, 9-AE foundation, no circular bootstrap, budget and tooltip')
''';(T/'scenario116.lua').write_text(s,encoding='utf8')
run=subprocess.run([str(lua),str(T/'scenario116.lua'),str(cl/'WD8.lua'),str(cl/'Allocation.lua'),str(T/'scenario87_regression.lua'),str(T/'scenario88.lua'),str(T/'scenario91.lua')],capture_output=True,encoding='utf8',errors='replace');(P/'checks/lua.txt').write_text(run.stdout+run.stderr,encoding='utf8');print(run.stdout,run.stderr);assert run.returncode==0
shutil.copytree(B/'rollback/server_SQL',P/'rollback/server_SQL',dirs_exist_ok=True)
s=(B/'tools/test_mysql.py').read_text(encoding='utf8').replace('_wd114_sql_scratch_','_wd116_sql_scratch_').replace('01_CHARACTERS_WD114A_必须执行.sql','01_CHARACTERS_WD116A_必须执行.sql').replace('2**77','2**78').replace('bit77 refused','bit78 refused')
marker=" rollback=(P/'rollback/server_SQL/01_CHARACTERS_WD105A.sql').read_text(encoding='utf8')"
block=''' # WD116 uses a single new high bit, leaving all saved node IDs unchanged.
 for g in range(130,134):
  q(f"INSERT INTO characters(guid,account,name,taximask,innTriggerId,race,class,money) VALUES({g},10,'new116{g}','',0,1,13,10000000); INSERT INTO reborn_wd5a_builds(guid) VALUES({g}); INSERT INTO reborn_wd67_members(guid,enabled) VALUES({g},1); INSERT INTO reborn_wd13_slots(guid,slot,paid_copper) VALUES({g},0,0),({g},1,10000000); INSERT INTO reborn_wd16_profiles VALUES({g},0,0),({g},1,1),({g},2,3);")
 vigil=2**77
 ck('Vigil cannot self-bootstrap foundation',save(130,0,vigil)=='0')
 ck('Vigil one AE saved exactly',save(130,0,classbase+vigil)=='1')
 ck('Vigil exact persisted node',q('SELECT node_rank FROM reborn_wd67_nodes WHERE guid=130 AND slot=0 AND node_id=6042')=='1')
 ck('Vigil no free removal',save(130,1,classbase)=='0')
 ck('Vigil not ninth foundation',save(131,0,classbase-1+vigil)=='0')
 ck('Vigil same-tier not foundation',save(131,0,classbase-1+vigil+potent)=='0')
 ck('Vigil works in Brewing slot',save(131,0,classbase+vigil,slot=1)=='1')
 ck('Vigil unknown next bit rejected',save(132,0,classbase+2**78)=='0')
 before=q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id;')
 q(install);ck('Vigil reinstall preserves old/new saves',before==q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id;'))
'''
assert marker in s;s=s.replace(marker,block+marker).replace('31118,12264);','31118,12264,6042);');(T/'test_mysql.py').write_text(s,encoding='utf8')
checks=[]
def ck(n,b):assert b,n;checks.append(n)
for prefix in ['03_覆盖到服务端根目录/Data/dbc','client_mpq输入_导入现有Patch-XA/DBFilesClient']:
 for name in ['Spell.dbc','SkillLineAbility.dbc']:
  rows,pool=dbc((P/prefix/name).read_bytes());base=V if (V/prefix/name).exists() else B;old,op=dbc((base/prefix/name).read_bytes())
  ck(prefix+name+' all prior rows untouched',all(rows[k]==v for k,v in old.items()));ck(prefix+name+' pool prefix preserved',pool.startswith(op))
  if name=='Spell.dbc':
   r=rows[9003855];h=rows[9003856]
   print(prefix,'dice',r[74:77],h[74:77],'duration',r[40],'cd',r[29],'GCD',r[205:207])
   ck(prefix+' native reduction 25',r[95]==87 and struct.unpack('<i',struct.pack('<I',r[80]))[0]+r[74]==-25 and r[110]==127)
   ck(prefix+' heal exactly2 percent',h[71]==136 and h[80]+h[74]==2)
   ck(prefix+' self only',r[86:88]==[1,1] and h[86]==1)
   ck(prefix+' timed native trigger',r[96]==23 and r[99]==1000 and r[117]==9003856 and r[29]==120000 and r[40]==1)
   ck(prefix+' no recursive helper',h[116:119]==[0,0,0] and h[95:98]==[0,0,0])
  else:ck(prefix+' hidden helper not taught',not any(r[2]==9003856 for r in rows.values()))
(P/'checks/data.json').write_text(json.dumps(checks,indent=2),encoding='utf8');print(len(checks),'data checks passed; isolated SQL ready')
