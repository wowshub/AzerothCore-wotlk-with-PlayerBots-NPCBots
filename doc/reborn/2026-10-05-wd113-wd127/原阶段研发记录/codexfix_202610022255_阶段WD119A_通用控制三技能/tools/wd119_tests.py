from pathlib import Path
import shutil,subprocess,json,struct,re,hashlib
from wd19_common import dbc,Archive
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');B=Path(Path('wd118_path.txt').read_text(encoding='utf8'));P=Path(Path('wd119_path.txt').read_text(encoding='utf8'));T=P/'tools';T.mkdir(exist_ok=True);(P/'checks').mkdir(exist_ok=True)
for f in (B/'research').glob('*.tsv'):shutil.copy2(f,P/'research'/f.name)
for f in (B/'tools').glob('*.lua'):
 s=f.read_text(encoding='utf8');s=re.sub(r'MaskSet\((pair|all|combined|two|snake),81,1,1\)',r'MaskSet(\1,84,1,1)',s);s=s.replace('2417851639229258349412352','19342813113834066795298816');(T/f.name).write_text(s,encoding='utf8')
s=(T/'scenario118.lua').read_text(encoding='utf8')+'''
M.pending=nil;M.level=80;M.aeBudget=56;M.teBudget=55
local foundation=123+2*2^44
local frog=M.MaskSet(foundation,81,1,1);local gonk=M.MaskSet(frog,82,1,1);local krag=M.MaskSet(frog,83,1,1)
assert(M.AERank(6031,frog)==1 and M.AERank(6525,gonk)==1 and M.AERank(12525,krag)==1)
assert(M.AESpent(frog)==10 and M.AESpent(gonk)==11 and M.TESpent(krag)==0)
for spec=0,2 do M.specs[2]=spec;assert(M.AEValid(frog) and M.AEValid(gonk) and M.AEValid(krag)) end
assert(not M.AEValid(M.MaskSet(gonk,83,1,1)))
assert(not M.AEValid(M.MaskSet(foundation,82,1,1)));assert(not M.AEValid(M.MaskSet(foundation,83,1,1)))
assert(not M.AEValid(M.MaskSet(foundation-1,81,1,1)))
M.level=25;assert(not M.AEValid(frog));M.level=26;assert(M.AEValid(frog));M.level=80
assert(not M.AEValid(M.MaskSet(frog,84,1,1)))
local combined=M.MaskSet(M.MaskSet(krag,78,2,2),80,1,1)
assert(M.AEValid(combined) and M.AERank(9347,combined)==2 and M.AERank(29306,combined)==1 and M.AERank(12525,combined)==1)
M.aeBudget=10;assert(not M.AEValid(gonk));M.aeBudget=56
M.aeMasks[2]=foundation;M.draftAE=gonk;M.aeDirty=true;M.dirty=true;M.pending=nil
local sent;M.Request=function(s)sent=s end;M.Save();assert(sent and sent:match(' '..M.MaskDecimal(gonk)..'$'))
for _,id in ipairs({6031,6525,12525}) do assert(M.IsAENode(id));assert(M.AETooltip({ID=id,AECost=1,TECost=0})) end
print('PASS WD119 three nodes: exact84-bit, mutual choice, prerequisite, budgets, cross-spec and levels')
''';(T/'scenario119.lua').write_text(s,encoding='utf8')
lua=R/'beascendBuild/modules/mod-ale/src/lualib/lua/RelWithDebInfo/lua52_interpreter.exe';cl=P/'02_覆盖到客户端根目录/Interface/AddOns/RebornWitchDoctorTalents'
def run(n,args):
 r=subprocess.run([str(lua)]+list(map(str,args)),capture_output=True,encoding='utf8',errors='replace');(P/'checks'/n).write_text(r.stdout+r.stderr,encoding='utf8');print(r.stdout,r.stderr);assert r.returncode==0
run('lua.txt',[T/'scenario119.lua',cl/'WD8.lua',cl/'Allocation.lua',T/'scenario87_regression.lua',T/'scenario88.lua',T/'scenario91.lua'])
run('syntax.txt',[T/'check_syntax.lua']+list(cl.rglob('*.lua')))
s=(T/'wd118_numeric_test.lua').read_text(encoding='utf8')+'''
for i,vals in ipairs({{1000,120000},{1500,60000},{0,120000},{1000,120000}}) do
 M.invalidate();id=9003861;reset('351 Mana');now=80+i*2
 GameTooltipTextLeft3=font('1 sec cast');GameTooltipTextRight3=font('2 min cooldown')
 M.refresh(GameTooltip);M.receive('WD114|'..seq()..'|9003861|ok|351|'..vals[1]..'|'..vals[2]..'|10|1')
 assert(GameTooltipTextLeft3.text==(vals[1]==0 and 'Instant' or string.format('%.2f sec cast',vals[1]/1000)))
 assert(GameTooltipTextRight3.text==string.format('%g sec cooldown',vals[2]/1000))
 for repeatCount=1,5 do M.refresh(GameTooltip) end
 assert(GameTooltip:NumLines()==5)
end
-- Cursor moves before previous reply: never repaint another spell with frog timings.
M.invalidate();id=9003861;reset();now=92;M.refresh(GameTooltip);local previous=seq()
id=9003143;reset('330 Mana');M.refresh(GameTooltip)
M.receive('WD114|'..previous..'|9003861|ok|351|0|120000|10|1')
assert(GameTooltipTextLeft3.text=='瞬发法术' and GameTooltipTextLeft2.text~='351 Mana')
print('PASS WD119 authoritative cast/cooldown transitions and fast hover isolation')
''';(T/'wd119_numeric_test.lua').write_text(s,encoding='utf8');run('numeric_tooltip.txt',[T/'wd119_numeric_test.lua',cl/'NumericTooltip.lua'])
shutil.copytree(B/'rollback/server_SQL',P/'rollback/server_SQL',dirs_exist_ok=True)
s=(B/'tools/test_mysql.py').read_text(encoding='utf8').replace('_wd118_sql_scratch_','_wd119_sql_scratch_').replace('01_CHARACTERS_WD118A_必须执行.sql','01_CHARACTERS_WD119A_必须执行.sql').replace('2**81','2**84').replace('bit81','bit84')
marker=" rollback=(P/'rollback/server_SQL/01_CHARACTERS_WD105A.sql').read_text(encoding='utf8')"
block='''
 for g in range(160,166):
  q(f"INSERT INTO characters(guid,account,name,taximask,innTriggerId,race,class,money) VALUES({g},10,'new119{g}','',0,1,13,10000000); INSERT INTO reborn_wd5a_builds(guid) VALUES({g}); INSERT INTO reborn_wd67_members(guid,enabled) VALUES({g},1); INSERT INTO reborn_wd13_slots(guid,slot,paid_copper) VALUES({g},0,0),({g},1,10000000); INSERT INTO reborn_wd16_profiles VALUES({g},0,0),({g},1,1),({g},2,3);")
 frog,gonk,krag=2**81,2**82,2**83
 ck('frog cannot self-bootstrap',save(160,0,frog)=='0')
 ck('Gonk requires frog',save(160,0,classbase+gonk)=='0')
 ck('Krag requires frog',save(160,0,classbase+krag)=='0')
 ck('blessings exclusive',save(160,0,classbase+frog+gonk+krag)=='0')
 ck('frog level25 refused',save(160,0,classbase+frog,25)=='0')
 ck('frog level26 insufficient natural budget',save(160,0,classbase+frog,26)=='0')
 ck('frog explicit test points',grant(160,0)=='1')
 ck('frog level26 allowed with budget',save(160,1,classbase+frog,26)=='1')
 ck('Gonk added to saved frog',save(160,2,classbase+frog+gonk)=='1')
 ck('Gonk no free change to Krag',save(160,3,classbase+frog+krag)=='0')
 ck('frog no free removal',save(160,3,classbase+gonk)=='0')
 ck('frog cannot use same tier foundation',save(161,0,classbase-1+frog+gonk+snake)=='0')
 ck('Krag Brewing slot allowed',save(161,0,classbase+frog+krag,slot=1)=='1')
 ck('Krag exact high node',q('SELECT node_rank FROM reborn_wd67_nodes WHERE guid=161 AND slot=1 AND node_id=12525')=='1')
 ck('frog coexist Walker Slither',save(162,0,classbase+frog+krag+snake+2*walker)=='1')
 ck('all high nodes preserved',q('SELECT COUNT(*) FROM reborn_wd67_nodes WHERE guid=162 AND node_id IN(6031,12525,29306,9347)')=='4')
 ck('84bit boundary refused',save(163,0,classbase+2**84)=='0')
 ck('unknown node protected',q('INSERT INTO reborn_wd67_nodes VALUES(163,0,987654,1)',fail=True))
 ck('frog rank2 refused',q('INSERT INTO reborn_wd67_nodes VALUES(163,0,6031,2)',fail=True))
 ck('saved Gonk exact reconstruction',save(160,3,classbase+frog+gonk)=='1')
 before119=q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id;SELECT * FROM reborn_wd13_slots ORDER BY guid,slot;')
 q(install);ck('reinstall preserves nodes and paid slots',before119==q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id;SELECT * FROM reborn_wd13_slots ORDER BY guid,slot;'))
 before=q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id;')
'''
assert marker in s;s=s.replace(marker,block+marker).replace('31118,12264,6042,9347,29306);','31118,12264,6042,9347,29306,6031,6525,12525);');(T/'test_mysql.py').write_text(s,encoding='utf8')
checks=[]
def ck(n,c):assert c,n;checks.append(n)
for prefix in ['03_覆盖到服务端根目录/Data/dbc','client_mpq输入_导入现有Patch-XA/DBFilesClient']:
 for name in ['Spell.dbc','SkillLineAbility.dbc']:
  raw=(P/prefix/name).read_bytes();rows,pool=dbc(raw);old,op=dbc((B/prefix/name).read_bytes());ck(prefix+name+' old rows untouched',all(rows[k]==v for k,v in old.items()));ck(prefix+name+' string prefix preserved',pool.startswith(op))
  fields=len(next(iter(rows.values())));ck(prefix+name+' WDBC exact size',len(raw)==20+len(rows)*fields*4+len(pool))
  if name=='Spell.dbc':
   for r in rows.values():
    for st in [136,153,170,187]:assert all(o<len(pool) and pool.find(b'\0',o)>=0 for o in r[st:st+16])
   ck(prefix+' all spell string offsets valid',True)
   r=rows[9003861];g=rows[9003862];k=rows[9003863]
   ck(prefix+' frog shape silence slow',r[71:74]==[6,6,6] and r[95:98]==[56,60,33] and r[110]==13321 and r[82]==4294967270)
   ck(prefix+' ground AOE 8yd 30yd',r[86:89]==[16]*3 and r[92:95]==[14]*3 and r[46]==4 and r[16]==64)
   ck(prefix+' native duration cast cd power',r[40]==64 and r[28]==4 and r[29]==120000 and r[204]==18 and r[38:40]==[26,26])
   ck(prefix+' damage break DR mechanic',r[32]&2 and r[3]==17)
   ck(prefix+' native flat modifier',g[95:98]==[107,107,0] and g[110:112]==[11,10] and g[80:82]==[4294907295,499])
   ck(prefix+' native instant modifier',k[95]==108 and k[110]==10 and k[80]==4294967195)
   ck(prefix+' modifier exact hook no foreign mask',g[122:131]==k[122:131]==[0]*9 and g[208:212]==k[208:212]==[0]*4)
   ck(prefix+' original native Hex visual',r[131]==rows[51514][131])
  else:
   for sid in [9003861,9003862,9003863]:ck(prefix+str(sid)+' unique Voodoo book',sum(r[2]==sid and r[1]==9004 for r in rows.values())==1)
src=P/'01_覆盖到源代码根目录';inc=(src/'modules/mod-reborn-witchdoctor/src/RebornWitchDoctorAllocation.inc').read_text(encoding='utf8');cpp=(src/'modules/mod-reborn-witchdoctor/src/RebornWitchDoctor.cpp').read_text(encoding='utf8')
ck('exact load index high bits','index>=70?index+10:' in inc and '(mask>>(index+10))&1u' in inc)
ck('C++ parents choices','if((AERank(mask,72) || AERank(mask,73)) && !AERank(mask,71)) return false;' in inc and 'if(AERank(mask,72) && AERank(mask,73)) return false;' in inc)
ck('native modifier positive and fallback guards','if(mod->spellId==9003862) return check->Id!=9003861' in cpp and 'case 9003862: case 9003863:' in (src/'src/server/game/Spells/SpellInfo.cpp').read_text(encoding='utf8'))
ck('PvP cap before native DR','if (spellproto->Id == 9003861) return 8 * IN_MILLISECONDS;' in (src/'src/server/game/Spells/SpellMgr.cpp').read_text(encoding='utf8'))
ck('temporary beast type exact aura','if (HasAura(9003861)) return CREATURE_TYPE_BEAST;' in (src/'src/server/game/Entities/Unit/Unit.cpp').read_text(encoding='utf8'))
icons,pool=dbc((P/'client_mpq输入_导入现有Patch-XA/DBFilesClient/SpellIcon.dbc').read_bytes())
for sid in range(910115,910123):
 o=icons[sid][1];path=pool[o:pool.find(b'\0',o)].decode().replace('\\','/')+'.blp';disk=P/'02_覆盖到客户端根目录'/path;mpq=P/'client_mpq输入_导入现有Patch-XA'/path
 ck(str(sid)+' disk/MPQ equal BLP',disk.read_bytes()==mpq.read_bytes() and disk.read_bytes()[:4] in [b'BLP1',b'BLP2'])
S=R/'beascendserver/wowshub_playerbot_npcbot_newrace20260929Ascend';C=R/'beascendclient/newrebornWOWli20260929beAscend'
resourceStatus={}
try:
 a=Archive(C/'Data/patch-XA.MPQ');raw=a.read('DBFilesClient\\CreatureDisplayInfo.dbc');a.close();resourceStatus['current_archive']='read successfully'
except AssertionError as e:
 resourceStatus['current_archive']='unverified: '+str(e)
 ref=R/'beascendclient/patch20260929巫医开发技能北郡暴风城问题/patch-XA/DBFilesClient/CreatureDisplayInfo.dbc'
 raw=ref.read_bytes();resourceStatus['reference_only']=str(ref)
rows,_=dbc(raw);ck('reference frog models exist (see current archive status)',all(i in rows for i in [901,1924,6295,6297]));resourceStatus['reference_sha256']=hashlib.sha256(raw).hexdigest()
(P/'checks/resource_status.json').write_text(json.dumps(resourceStatus,ensure_ascii=False,indent=2),encoding='utf8')
# New native references are also present in each side's own baseline.
for name,index,value in [('SpellDuration',1,40000),('SpellCastTimes',1,1000),('SpellRadius',1,1090519040)]:
 rows,_=dbc((S/f'Data/dbc/{name}.dbc').read_bytes());rid={'SpellDuration':64,'SpellCastTimes':4,'SpellRadius':14}[name];ck(name+' native reference',rows[rid][index]==value)
(P/'checks/data.json').write_text(json.dumps(checks,indent=2),encoding='utf8');print(len(checks),'checks; SQL prepared')
