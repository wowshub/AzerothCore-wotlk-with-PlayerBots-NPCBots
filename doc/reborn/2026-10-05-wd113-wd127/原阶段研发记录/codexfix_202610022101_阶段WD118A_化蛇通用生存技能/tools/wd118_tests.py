from pathlib import Path
import shutil,subprocess,json,struct
from wd19_common import dbc,Archive
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');B=Path(Path('wd117_path.txt').read_text(encoding='utf8'));P=Path(Path('wd118_path.txt').read_text(encoding='utf8'));T=P/'tools';T.mkdir(exist_ok=True);(P/'checks').mkdir(exist_ok=True)
for f in (B/'research').glob('*.tsv'):shutil.copy2(f,P/'research'/f.name)
for f in (B/'tools').glob('*.lua'):
 s=f.read_text(encoding='utf8').replace('MaskSet(pair,80,1,1)','MaskSet(pair,81,1,1)').replace('MaskSet(all,80,1,1)','MaskSet(all,81,1,1)').replace('MaskSet(combined,80,1,1)','MaskSet(combined,81,1,1)').replace('MaskSet(two,80,1,1)','MaskSet(two,81,1,1)').replace('1208925819614629174706176','2417851639229258349412352')
 (T/f.name).write_text(s,encoding='utf8')
s=(T/'scenario117.lua').read_text(encoding='utf8')+'''
M.pending=nil;M.level=80;M.aeBudget=56;M.teBudget=55
local base=123+2*2^44;local snake=M.MaskSet(base,80,1,1)
assert(M.IsAENode(29306) and M.AERank(29306,snake)==1 and M.AESpent(snake)==10)
assert(M.AEValid(snake));assert(not M.AEValid(M.MaskSet(base-1,80,1,1)))
for spec=0,2 do M.specs[2]=spec;assert(M.AEValid(snake)) end
M.level=29;assert(not M.AEValid(snake));M.level=30;assert(M.AEValid(snake));M.level=80
assert(not M.AEValid(M.MaskSet(snake,81,1,1)))
local together=M.MaskSet(snake,78,2,2);assert(M.AERank(9347,together)==2 and M.AERank(29306,together)==1 and M.AESpent(together)==12 and M.AEValid(together))
M.aeBudget=9;assert(not M.AEValid(snake));M.aeBudget=56
assert(M.AETooltip({ID=29306,AECost=1,TECost=0}))
M.aeMasks[2]=base;M.draftAE=together;M.aeDirty=true;M.dirty=true;M.pending=nil
local sent;M.Request=function(s)sent=s end;M.Save();assert(sent and sent:match(' '..M.MaskDecimal(together)..'$'))
print('PASS WD118 Slither level30, cross spec, foundation, budgets, 81-bit save, no Walker bit collision')
''';(T/'scenario118.lua').write_text(s,encoding='utf8')
lua=R/'beascendBuild/modules/mod-ale/src/lualib/lua/RelWithDebInfo/lua52_interpreter.exe';cl=P/'02_覆盖到客户端根目录/Interface/AddOns/RebornWitchDoctorTalents'
def run(n,args):
 r=subprocess.run([str(lua)]+list(map(str,args)),capture_output=True,encoding='utf8',errors='replace');(P/'checks'/n).write_text(r.stdout+r.stderr,encoding='utf8');print(r.stdout,r.stderr);assert r.returncode==0
run('lua.txt',[T/'scenario118.lua',cl/'WD8.lua',cl/'Allocation.lua',T/'scenario87_regression.lua',T/'scenario88.lua',T/'scenario91.lua'])
run('syntax.txt',[T/'check_syntax.lua']+list(cl.rglob('*.lua')))
s=(T/'wd117_numeric_test.lua').read_text(encoding='utf8')+'''
M.invalidate();id=9003859;reset('351法力值');now=76;M.refresh(GameTooltip)
M.receive('WD114|'..seq()..'|9003859|ok|219|0|0|10|1')
assert(GameTooltipTextLeft2.text=='219 Mana')
print('PASS WD118 Slither cost uses authoritative reply')
''';(T/'wd118_numeric_test.lua').write_text(s,encoding='utf8');run('numeric_tooltip.txt',[T/'wd118_numeric_test.lua',cl/'NumericTooltip.lua'])
shutil.copytree(B/'rollback/server_SQL',P/'rollback/server_SQL',dirs_exist_ok=True)
s=(B/'tools/test_mysql.py').read_text(encoding='utf8').replace('_wd117_sql_scratch_','_wd118_sql_scratch_').replace('01_CHARACTERS_WD117A_必须执行.sql','01_CHARACTERS_WD118A_必须执行.sql').replace('2**80','2**81').replace('bit80','bit81').replace('timeout=90','timeout=300')
marker=" rollback=(P/'rollback/server_SQL/01_CHARACTERS_WD105A.sql').read_text(encoding='utf8')"
block='''
 for g in range(150,154):
  q(f"INSERT INTO characters(guid,account,name,taximask,innTriggerId,race,class,money) VALUES({g},10,'new118{g}','',0,1,13,10000000); INSERT INTO reborn_wd5a_builds(guid) VALUES({g}); INSERT INTO reborn_wd67_members(guid,enabled) VALUES({g},1); INSERT INTO reborn_wd13_slots(guid,slot,paid_copper) VALUES({g},0,0),({g},1,10000000); INSERT INTO reborn_wd16_profiles VALUES({g},0,0),({g},1,1),({g},2,3);")
 snake=2**80
 ck('Slither cannot self-bootstrap',save(150,0,snake)=='0')
 ck('Slither level29 refused',save(150,0,classbase+snake,29)=='0')
 ck('Slither level30 saved',save(150,0,classbase+snake,30)=='1')
 ck('Slither exact node',q('SELECT node_rank FROM reborn_wd67_nodes WHERE guid=150 AND slot=0 AND node_id=29306')=='1')
 ck('Slither no free removal',save(150,1,classbase)=='0')
 ck('Slither foundation not circular',save(151,0,classbase-1+snake)=='0')
 ck('Slither same-tier not foundation',save(151,0,classbase-1+snake+walker)=='0')
 ck('Slither Brewing slot',save(151,0,classbase+snake,slot=1)=='1')
 ck('Slither plus Walker rank2',save(152,0,classbase+snake+2*walker)=='1')
 ck('Slither and Walker exact rows',q('SELECT COUNT(*) FROM reborn_wd67_nodes WHERE guid=152 AND ((node_id=9347 AND node_rank=2) OR (node_id=29306 AND node_rank=1))')=='2')
 ck('Slither bit81 refused',save(153,0,classbase+2**81)=='0')
 before=q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id;')
 q(install);ck('Slither reinstall preserves all rows',before==q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id;'))
 world=(P/'server_SQL/02_WORLD_WD118A_必须执行.sql').read_text(encoding='utf8');q(world);q(world)
 ck('Slither World registration idempotent',q("SELECT COUNT(*) FROM spell_script_names WHERE spell_id=9003859 AND ScriptName='aura_reborn_wd118_slither'")=='1')
'''
assert marker in s;s=s.replace(marker,block+marker).replace('31118,12264,6042,9347);','31118,12264,6042,9347,29306);');(T/'test_mysql.py').write_text(s,encoding='utf8')
checks=[]
def ck(n,b):assert b,n;checks.append(n)
for prefix in ['03_覆盖到服务端根目录/Data/dbc','client_mpq输入_导入现有Patch-XA/DBFilesClient']:
 for name in ['Spell.dbc','SkillLineAbility.dbc']:
  rows,pool=dbc((P/prefix/name).read_bytes());old,op=dbc((B/prefix/name).read_bytes());ck(prefix+name+' old rows untouched',all(rows[k]==v for k,v in old.items()));ck(prefix+name+' pool preserved',pool.startswith(op))
  if name=='Spell.dbc':
   r=rows[9003859];h=rows[9003860]
   ck(prefix+' native shape speed pacify',r[71:74]==[6,6,6] and r[95:98]==[31,56,60] and r[111]==2914 and r[80]+r[74]==80)
   ck(prefix+' self duration cd level',r[86:89]==[1,1,1] and r[40]==28 and r[29]==60000 and r[38:40]==[30,30])
   ck(prefix+' avoidance native hit/swim',h[95:98]==[186,185,58] and h[110:113]==[126,1,0] and h[80]==4294967195 and h[82]==79)
   ck(prefix+' helper no cost cooldown',h[29]==0 and h[42]==0 and h[204]==0 and h[205:207]==[0,0])
   ck(prefix+' same icon',r[133]==h[133]==910119)
  else:ck(prefix+' only parent book entry',sum(r[2]==9003859 for r in rows.values())==1 and not any(r[2]==9003860 for r in rows.values()))
src=P/'01_覆盖到源代码根目录/modules/mod-reborn-witchdoctor/src';inc=(src/'RebornWitchDoctorAllocation.inc').read_text(encoding='utf8');cpp=(src/'RebornWitchDoctor.cpp').read_text(encoding='utf8')
ck('load bit80 no overlap','<<(index==70?80:index>=52?' in inc);ck('decode bit80','(mask>>80)&1u' in inc);ck('server level30','AERank(mask,70) && level<30' in inc)
ck('custom attr keeps aura60','info->AttributesCu &= ~SPELL_ATTR0_CU_NEGATIVE' in cpp)
ck('script registered','RegisterSpellScript(aura_reborn_wd118_slither);' in cpp)
ck('remove both on ownership end','p->RemoveAurasDueToSpell(9003859,p->GetGUID());' in inc and 'p->RemoveAurasDueToSpell(9003860,p->GetGUID());' in inc)
ck('cleanse roots plus snares','unit->RemoveMovementImpairingAuras(true);' in cpp)
ck('parent lifetime helper','GetTarget()->RemoveAurasDueToSpell(9003860,GetCasterGUID());' in cpp)
S=R/'beascendserver/wowshub_playerbot_npcbot_newrace20260929Ascend';duration,_=dbc((S/'Data/dbc/SpellDuration.dbc').read_bytes());ck('server5seconds',duration[28][1]==5000)
C=R/'beascendclient/newrebornWOWli20260929beAscend';a=Archive(C/'Data/patch-XA.MPQ');raw=a.read('DBFilesClient\\CreatureDisplayInfo.dbc');a.close();assert raw
rows,pool=dbc(raw);ck('all current snake models available in client',all(i in rows for i in [1206,2957,2958,6303]))
(P/'checks/data.json').write_text(json.dumps(checks,indent=2),encoding='utf8');print(len(checks),'checks; SQL ready')
