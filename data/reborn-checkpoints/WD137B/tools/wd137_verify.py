# coding: utf-8
exec(compile(Path('wd137_build.py').read_text(encoding='utf8').split('for pre,live in')[0],'helpers','exec')) if False else None
from pathlib import Path
import json,struct,subprocess,re,hashlib
from wd19_common import dbc
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');P=Path(Path('wd137_path.txt').read_text().strip());B=Path(Path('wd136_path.txt').read_text().strip());S=R/'beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots';CK=P/'checks';CK.mkdir(exist_ok=True)
checks=[]
def ck(n,v):assert v,n;checks.append(n)
fmt=re.search(r'SpellEntryfmt\[\]\s*=\s*"([^"]+)"',(S/'src/server/shared/DataStores/DBCfmt.h').read_text())[1]
for pre in ['client_mpq输入_导入现有Patch-XA/DBFilesClient','03_覆盖到服务端根目录/Data/dbc']:
 for name in ['Spell.dbc','SpellIcon.dbc','SkillLineAbility.dbc']:
  rows,pool=dbc((P/pre/name).read_bytes());old,op=dbc((P/'rollback'/pre/name).read_bytes())
  ck(pre+name+' old rows/strings',all(rows[k]==v for k,v in old.items()) and pool.startswith(op));ck(pre+name+' one appended record',len(rows)==len(old)+1)
 rows,pool=dbc((P/pre/'Spell.dbc').read_bytes())
 for v in rows.values():
  for i,t in enumerate(fmt):
   if t=='s':assert 0<=v[i]<len(pool) and pool.find(b'\0',v[i])>=0
 v=rows[9003957];ck(pre+' instant/120s/10s/native100percent',v[28]==1 and v[29]==120000 and v[40]==1 and v[80:83]==[99]*3 and v[110:113]==[0,22,8])
lua=R/'beascendBuild/modules/mod-ale/src/lualib/lua/RelWithDebInfo/lua52_interpreter.exe';addon=P/'02_覆盖到客户端根目录/Interface/AddOns/RebornWitchDoctorTalents'
def run(name,script,args):
 t=CK/name;t.write_text(script,encoding='utf8');r=subprocess.run([str(lua),str(t),*map(str,args)],capture_output=True,encoding='utf8');(CK/(name+'.log')).write_text(r.stdout+r.stderr,encoding='utf8');ck(name,r.returncode==0);return r.stdout
run('syntax.lua','for i=1,#arg do assert(loadfile(arg[i])) end print("syntax passed")',list((P/'02_覆盖到客户端根目录').rglob('*.lua')))
for name in ['previous_numeric_test.lua','potion_numeric_test.lua','scenario130.lua','scenario131.lua','scenario132.lua','scenario133.lua','actual_save132.lua','actual_save135.lua']:
 t=(B/'checks'/name).read_text(encoding='utf8').replace(',118,1,1)',',119,1,1)')
 run(name,t,[addon if name.startswith('actual_save') else addon/('NumericTooltip.lua' if 'numeric' in name else 'Allocation.lua')])
t=(B/'checks/scenario136.lua').read_text(encoding='utf8').replace(',118,1,1)',',119,1,1)')
t+='''
local master=M.MaskSet(good,118,1,1)
assert(M.AEValid(master));assert(M.AERank(29740,master)==1)
assert(M.TESpent(master)==M.TESpent(good)+1)
M.level=58;assert(not M.AEValid(master));M.level=59;assert(M.AEValid(master));M.level=80
assert(not M.AEValid(M.MaskSet(master,117,1,0)))
M.specs[1]=0;assert(not M.AEValid(master));M.specs[1]=1
M.teBudget=M.TESpent(master)-1;assert(not M.AEValid(master));M.teBudget=100
assert(not M.AEValid(M.MaskSet(master,119,1,1)))
M.draftAE=master;M.Save();assert(got=='.wd67save 1 0 '..M.MaskDecimal(master))
print('MASTER '..M.MaskDecimal(master));print('MASTER_TE '..M.TESpent(master));print('PASS WD137 119-bit exact save and requirements')
'''
out=run('scenario137.lua',t,[addon/'Allocation.lua']);masks=json.loads((B/'checks/masks.json').read_text());masks.update({k:int(v) for k,v in re.findall(r'^(CONCOCTIONS|LESS|CONCOCTIONS_TE|MASTER|MASTER_TE) (\d+)$',out,re.M)});(CK/'masks.json').write_text(json.dumps(masks,indent=2))
# Preserve rollback source from live source (a second staged edit must not overwrite original backup).
for f in (P/'rollback/01_覆盖到源代码根目录').rglob('*'):
 if f.is_file():f.write_bytes((S/f.relative_to(P/'rollback/01_覆盖到源代码根目录')).read_bytes())
# Prepare inherited actual compiler argument sets, with all candidate include paths first.
for name in ['RebornWitchDoctor','RebornWitchDoctorTalents','Spell','SpellInfo']:
 source='Spell' if name=='SpellInfo' else name
 text=(B/'checks'/(source+'.rsp')).read_text(encoding='utf16').replace(str(B),str(P)).replace(B.as_posix(),P.as_posix())
 if name=='SpellInfo':text=text.replace('Spell.cpp','SpellInfo.cpp')
 (CK/(name+'.rsp')).write_text(text,encoding='utf16')
cmd='@echo off\nchcp 65001 >nul\ncall "D:\\soft\\vs2022\\enterprise\\VC\\Auxiliary\\Build\\vcvars64.bat" >nul\n'
for name in ['RebornWitchDoctor','RebornWitchDoctorTalents','Spell','SpellInfo']:
 cmd+='cl.exe @"'+str(CK/(name+'.rsp'))+'" > "'+str(CK/('msvc_'+name+'.log'))+'" 2>&1\nif errorlevel 1 exit /b 1\n'
(P/'tools').mkdir(exist_ok=True);(P/'tools/syntax.cmd').write_text(cmd,encoding='utf8')
# Isolated SQL test, never production port/database.
t=(B/'tools/test_mysql136.py').read_text(encoding='utf8').replace('20261007Ascend/mysql','20261008Ascend/mysql').replace('33536','33537').replace('_wd136_sql_scratch_','_wd137_sql_scratch_').replace('01_CHARACTERS_WD136A','01_CHARACTERS_WD137A').replace('2**118','2**119')
marker=" (P/'checks/mysql_results.json').write_text"
assert marker in t
extra=''' master=int(masks['MASTER']);masterte=int(masks['MASTER_TE'])
 ck('137 rejects level58',save(34,0,master,level=58,slot=1)=='0')
 ck('137 requires Concoctions',save(34,0,master-2**117,level=80,slot=1)=='0')
 ck('137 rejects unknown bit119',save(34,0,master+2**119,level=80,slot=1)=='0')
 ck('137 stores master at119bits',save(34,0,master,level=80,slot=1)=='1')
 ck('137 stored node rank',q('SELECT node_rank FROM reborn_wd67_nodes WHERE guid=34 AND slot=1 AND node_id=29740')=='1')
 world137=(P/'server_SQL/14_WORLD_WD137A_必须执行.sql').read_text(encoding='utf8');q(world137);q(world137)
 ck('137 world idempotent',q('SELECT COUNT(*) FROM spell_script_names WHERE spell_id=9003957')=='1')
 q("INSERT INTO spell_script_names VALUES(9003957,'unrelated_conflict')")
 ck('137 world conflict guard',q(world137,fail=True))
 q("DELETE FROM spell_script_names WHERE ScriptName='unrelated_conflict'")
'''
t=t.replace(marker,extra+marker)
(P/'tools/test_mysql137.py').write_text(t,encoding='utf8')
(CK/'verification.json').write_text(json.dumps(checks,ensure_ascii=False,indent=2),encoding='utf8');print('PASS',len(checks));print(P/'tools/syntax.cmd')
