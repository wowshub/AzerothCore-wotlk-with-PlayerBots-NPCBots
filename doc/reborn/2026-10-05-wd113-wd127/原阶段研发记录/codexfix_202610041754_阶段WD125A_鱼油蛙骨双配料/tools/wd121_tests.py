# coding: utf-8
from pathlib import Path
import re,json,shutil,subprocess,hashlib
import wd19_common as common
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');B=Path(Path('wd120_path.txt').read_text());P=Path(Path('wd121_path.txt').read_text());T=P/'tools';A=P/'02_覆盖到客户端根目录/Interface/AddOns';(P/'checks').mkdir(exist_ok=True)
lua=R/'beascendBuild/modules/mod-ale/src/lualib/lua/RelWithDebInfo/lua52_interpreter.exe'
for f in T.glob('scenario*.lua'):
 s=f.read_text(encoding='utf8');s=s.replace('MaskSet(all,87,1,1)','MaskSet(all,90,1,1)').replace('MaskSet(frog,87,1,1)','MaskSet(frog,90,1,1)').replace('154742504910672534362390528','1237940039285380274899124224');f.write_text(s,encoding='utf8')
s=(T/'scenario120.lua').read_text(encoding='utf8')+'''
M.level=80;M.teBudget=55;M.aeBudget=56;M.specs[2]=1;M.pending=nil
local f8=M.MaskSet(M.MaskSet(M.MaskSet(M.MaskSet(M.MaskSet(0,55,2,2),57,2,2),59,2,2),62,1,1),64,1,1)
local rank1=M.MaskSet(f8,87,2,1)
local rank2=M.MaskSet(f8,87,2,2)
local both=M.MaskSet(rank2,89,1,1)
assert(M.AEValid(rank1) and M.AEValid(rank2) and M.AEValid(both))
assert(M.AERank(6498,both)==2 and M.AERank(29303,both)==1)
assert(M.AESpent(both)==0 and M.TESpent(both)==11 and M.BrewingFoundation(both)==8)
assert(not M.AEValid(M.MaskSet(both,87,2,3)))
assert(not M.AEValid(M.MaskSet(both,90,1,1)))
local low=M.MaskSet(both,55,2,1)
assert(not M.AEValid(low)) -- same-tier points cannot supply missing eighth foundation
M.teBudget=10;assert(not M.AEValid(both));M.teBudget=11;assert(M.AEValid(both))
M.specs[2]=0;assert(not M.AEValid(both));M.specs[2]=2;assert(not M.AEValid(both));M.specs[2]=1
M.aeMasks[2]=rank1;M.draftAE=both;M.aeDirty=true;M.dirty=true;M.pending=nil
M.Save();assert(sent and sent:match(' '..M.MaskDecimal(both)..'$'))
for _,id in ipairs({6498,29303}) do assert(M.IsAENode(id));assert(M.AETooltip({ID=id,AECost=0,TECost=1})) end
print('PASS WD121 ranks / exact90-bit / foundation8 / no bootstrap / TE budget / spec / protocol')
'''
(T/'scenario121.lua').write_text(s,encoding='utf8')
def run(name,args):
 r=subprocess.run([str(lua)]+[str(x) for x in args],capture_output=True,encoding='utf8',errors='replace');(P/'checks'/name).write_text(r.stdout+r.stderr,encoding='utf8');print(r.stdout,r.stderr);assert r.returncode==0
run('lua.txt',[T/'scenario121.lua',A/'RebornWitchDoctorTalents/WD8.lua',A/'RebornWitchDoctorTalents/Allocation.lua',T/'scenario87_regression.lua',T/'scenario88.lua',T/'scenario91.lua'])
run('syntax.txt',[T/'check_syntax.lua']+list(A.rglob('*.lua')))
for name,script,addon in [('numeric','wd120_numeric_test.lua','RebornWitchDoctorTalents/NumericTooltip.lua'),('book','wd119b_book_test.lua','RebornWitchDoctorSkillBook/RebornWitchDoctorSkillBook.lua'),('cooldown','wd119b_cooldown_test.lua','RebornWDCooldownTooltip/Cooldown.lua')]:
 run('ui_'+name+'.txt',[T/script,A/addon])
checks=[]
def ck(n,b):assert b,n;checks.append(n)
fmt=(R/'beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots/src/server/shared/DataStores/DBCfmt.h').read_text();spellfmt=re.search(r'SpellEntryfmt\[\]\s*=\s*"([^"]+)"',fmt)[1]
for prefix in ['03_覆盖到服务端根目录/Data/dbc','client_mpq输入_导入现有Patch-XA/DBFilesClient']:
 for table in ['Spell','SkillLineAbility']:
  old,op=common.dbc((B/prefix/(table+'.dbc')).read_bytes());new,np=common.dbc((P/prefix/(table+'.dbc')).read_bytes())
  ck(prefix+table+' preserves every old row and string prefix',all(new.get(k)==v for k,v in old.items()) and np.startswith(op))
  if table=='Spell':
   ck(prefix+' exact3 additions',set(new)-set(old)=={9003877,9003878,9003879})
   for i,r in new.items():
    for col,kind in enumerate(spellfmt):
     if kind=='s':assert r[col]<len(np) and np.find(b'\0',r[col])>=0,(i,col)
   ck(prefix+' ALL core string fields validated',True)
   for sid,amt in [(9003877,15),(9003878,30),(9003879,20)]:
    r=new[sid];ck(str(sid)+' native damage modifier',r[71]==6 and r[95]==108 and r[110]==0 and r[80]+1==amt)
    ck(str(sid)+' no foreign references',r[122:131]==[0]*9 and r[226:234]==[0]*8 and r[131]==0 and r[4]==64)
   ck(prefix+' PotionBoss periodic modifier',new[9003879][96]==108 and new[9003879][111]==22 and new[9003879][81]==19)
  else:
   ck(prefix+' exact Brewing book entries',all(sum(r[2]==sid and r[1]==9005 for r in new.values())==1 for sid in range(9003877,9003880)))
old,op=common.dbc((B/'client_mpq输入_导入现有Patch-XA/DBFilesClient/SpellIcon.dbc').read_bytes());new,np=common.dbc((P/'client_mpq输入_导入现有Patch-XA/DBFilesClient/SpellIcon.dbc').read_bytes())
ck('icons old rows/pool preserved',all(new[k]==v for k,v in old.items()) and np.startswith(op))
for sid in [910126,910127]:
 o=new[sid][1];path=np[o:np.find(b'\0',o)].decode().replace('\\','/')+'.blp';x=(P/'02_覆盖到客户端根目录'/path).read_bytes();ck(path,x==(P/'client_mpq输入_导入现有Patch-XA'/path).read_bytes() and x[:4] in [b'BLP1',b'BLP2'])
for rel in ['src/server/game/Entities/Player/Player.cpp', 'modules/mod-reborn-witchdoctor/src/RebornWitchDoctorBrewingNumbers.h']:
 ck('cumulative unchanged '+rel,(B/'01_覆盖到源代码根目录'/rel).read_bytes()==(P/'01_覆盖到源代码根目录'/rel).read_bytes())
(P/'checks/data.json').write_text(json.dumps({'checks':checks,'result':'PASS'},ensure_ascii=False,indent=2),encoding='utf8')
# Copy the full independent database suite; add new persistence, boundary and rank cases.
for f in (B/'research').glob('*.tsv'):shutil.copy2(f,P/'research'/f.name)
s=(B/'tools/test_mysql.py').read_text(encoding='utf8').replace('_wd120_sql_scratch_','_wd121_sql_scratch_').replace('01_CHARACTERS_WD120A_必须执行.sql','01_CHARACTERS_WD121A_必须执行.sql').replace('classbase+2**87','classbase+2**90').replace('87bit boundary refused','90bit boundary refused')
s=s.replace('6525,12525,4005,12645,12646);\');q(rollback)','6525,12525,4005,12645,12646,6498,29303);\');q(rollback)')
anchor=" before=q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id;')\n rollback="
block=''' for g in range(180,185):
  q(f"INSERT INTO characters(guid,account,name,taximask,innTriggerId,race,class,money) VALUES({g},10,'wd121test{g}','',0,1,13,10000000); INSERT INTO reborn_wd5a_builds(guid) VALUES({g}); INSERT INTO reborn_wd67_members(guid,enabled) VALUES({g},1); INSERT INTO reborn_wd13_slots(guid,slot,paid_copper) VALUES({g},0,0),({g},1,10000000); INSERT INTO reborn_wd16_profiles VALUES({g},0,0),({g},1,1),({g},2,3);")
 f8=2*2**55+2*2**57+2*2**59+2**62+2**64
 fresh=2**87;boss=2**89
 ck('121 rank1 accepted Brewing foundation8',save(180,0,f8+fresh,80,slot=1)=='1')
 ck('121 upgrade rank2 with boss',save(180,1,f8+2*fresh+boss,80,slot=1)=='1')
 ck('121 exact new rows',q('SELECT node_rank FROM reborn_wd67_nodes WHERE guid=180 AND node_id=6498')=='2' and q('SELECT node_rank FROM reborn_wd67_nodes WHERE guid=180 AND node_id=29303')=='1')
 ck('121 repeat mask reconstruction',save(180,2,f8+2*fresh+boss,80,slot=1)=='1')
 ck('121 no free rank downgrade',save(180,3,f8+fresh+boss,80,slot=1)=='0')
 ck('121 invalid rank3',save(181,0,f8+3*fresh,80,slot=1)=='0')
 ck('121 same tier cannot bootstrap',save(181,0,f8-2**55+2*fresh+boss,80,slot=1)=='0')
 ck('121 wrong spec',save(181,0,f8+fresh,80,slot=0)=='0')
 ck('121 bit90 rejected',save(181,0,f8+2**90,80,slot=1)=='0')
 before121=q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id; SELECT * FROM reborn_wd13_slots ORDER BY guid,slot;')
 q(install);q(install);ck('121 reinstall preserves all plans/purchases',before121==q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id; SELECT * FROM reborn_wd13_slots ORDER BY guid,slot;'))
'''
assert s.count(anchor)==1;s=s.replace(anchor,block+anchor);(T/'test_mysql.py').write_text(s,encoding='utf8')
print('All Lua/DBC checks PASS; MySQL suite prepared')
