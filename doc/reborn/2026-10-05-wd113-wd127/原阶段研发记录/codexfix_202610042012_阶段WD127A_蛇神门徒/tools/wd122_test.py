from pathlib import Path
import re,json,shutil,subprocess
from wd19_common import dbc
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');B=Path(Path('wd121_path.txt').read_text());P=Path(Path('wd122_path.txt').read_text());Q=Path(Path('wd121b_path.txt').read_text());T=P/'tools';A=P/'02_覆盖到客户端根目录/Interface/AddOns';(P/'checks').mkdir(exist_ok=True)
lua=R/'beascendBuild/modules/mod-ale/src/lualib/lua/RelWithDebInfo/lua52_interpreter.exe'
# Boundary shifts in inherited regressions represent the next unknown bit, not old allocated bits.
for f in T.glob('scenario*.lua'):
 s=f.read_text(encoding='utf8').replace('MaskSet(all,90,1,1)','MaskSet(all,92,1,1)').replace('MaskSet(frog,90,1,1)','MaskSet(frog,92,1,1)').replace('MaskSet(both,90,1,1)','MaskSet(both,92,1,1)').replace('1237940039285380274899124224','4951760157141521099596496896');f.write_text(s,encoding='utf8')
s=(T/'scenario121.lua').read_text(encoding='utf8')+'''
M.level=80;M.teBudget=55;M.aeBudget=56;M.specs[2]=1;M.pending=nil
local booms=M.MaskSet(both,90,1,1)
local doctor=M.MaskSet(both,91,1,1)
assert(M.AEValid(booms) and M.AEValid(doctor))
assert(M.AERank(6020,booms)==1 and M.AERank(29737,doctor)==1)
assert(M.TESpent(booms)==12 and M.AESpent(booms)==0)
assert(not M.AEValid(M.MaskSet(booms,91,1,1)))
assert(not M.AEValid(M.MaskSet(booms,55,2,1)))
assert(not M.AEValid(M.MaskSet(booms,92,1,1)))
M.teBudget=11;assert(not M.AEValid(booms));M.teBudget=12
M.specs[2]=0;assert(not M.AEValid(doctor));M.specs[2]=1
M.aeMasks[2]=both;M.draftAE=booms;M.aeDirty=true;M.dirty=true;M.pending=nil
M.Save();assert(sent and sent:match(' '..M.MaskDecimal(booms)..'$'))
for _,id in ipairs({6020,29737}) do assert(M.IsAENode(id));assert(M.AETooltip({ID=id,AECost=0,TECost=1})) end
print('PASS WD122 choice/foundation/budget/spec/92bit/protocol')
'''
(T/'scenario122.lua').write_text(s,encoding='utf8')
s=(T/'wd120_numeric_test.lua').read_text(encoding='utf8')+'''
for _,v in ipairs({{6000,8},{6000,5},{4000,8}}) do
 id=9003865;now=now+3;reset();M.invalidate();M.refresh(GameTooltip)
 M.receive('WD114|'..seq()..'|9003865|ok|0|500|600|10|1|'..v[1]..'|'..v[2])
 local text=_G['GameTooltipTextLeft'..GameTooltip.n].text
 assert(text:find('每'..(v[1]/1000)..'秒',1,true) and text:find('最多'..v[2]..'人',1,true))
 assert(text:find('500',1,true) and text:find('600',1,true))
end
print('PASS WD122 authoritative interval/cap/amount refresh')
'''
(T/'wd122_numeric_test.lua').write_text(s,encoding='utf8')
def run(name,args):
 r=subprocess.run([str(lua)]+[str(x) for x in args],capture_output=True,encoding='utf8',errors='replace');(P/'checks'/name).write_text(r.stdout+r.stderr,encoding='utf8');print(r.stdout,r.stderr);assert r.returncode==0,name
run('lua.txt',[T/'scenario122.lua',A/'RebornWitchDoctorTalents/WD8.lua',A/'RebornWitchDoctorTalents/Allocation.lua',T/'scenario87_regression.lua',T/'scenario88.lua',T/'scenario91.lua'])
run('syntax.txt',[T/'check_syntax.lua']+list(A.rglob('*.lua')))
for name,script,addon in [('numeric','wd122_numeric_test.lua','RebornWitchDoctorTalents/NumericTooltip.lua'),('book','wd119b_book_test.lua','RebornWitchDoctorSkillBook/RebornWitchDoctorSkillBook.lua'),('cooldown','wd119b_cooldown_test.lua','RebornWDCooldownTooltip/Cooldown.lua')]:run('ui_'+name+'.txt',[T/script,A/addon])
checks=[]
def ck(n,b):assert b,n;checks.append(n)
fmt=(R/'beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots/src/server/shared/DataStores/DBCfmt.h').read_text();fmt=re.search(r'SpellEntryfmt\[\]\s*=\s*"([^"]+)"',fmt)[1]
for prefix in ['03_覆盖到服务端根目录/Data/dbc','client_mpq输入_导入现有Patch-XA/DBFilesClient']:
 for table in ['Spell','SkillLineAbility']:
  old,op=dbc((B/prefix/(table+'.dbc')).read_bytes());new,np=dbc((P/prefix/(table+'.dbc')).read_bytes())
  def preserved(k,v):
   if table=='Spell' and k==9003865:return new[k][:170]==v[:170] and new[k][203:]==v[203:] and new[k][186]==v[186]
   return new.get(k)==v
  ck(prefix+table+' old rows preserved except Shrooms base-description offsets',all(preserved(k,v) for k,v in old.items()) and np.startswith(op))
  if table=='Spell':
   ck('exact two additions',set(new)-set(old)=={9003880,9003881})
   for i,r in new.items():
    for col,kind in enumerate(fmt):
     if kind=='s':assert r[col]<len(np) and np.find(b'\0',r[col])>=0,(i,col)
   ck('all core strings valid',True)
   ck('Booms exact +100% native heal',new[9003880][95]==108 and new[9003880][80]==99 and new[9003880][110]==0)
   ck('Doctor exact -2000ms native amplitude',new[9003881][95]==107 and new[9003881][80]==((-2001)&0xffffffff) and new[9003881][110]==19)
   ck('Pulse area filter target hook matches',new[9003866][86]==56 and new[9003866][212]==8)
   ck('Shrooms base6000 and no periodic haste',new[9003865][98]==6000 and not new[9003865][9]&0x2000)
  else:ck('exact book Brewing ownership',all(sum(r[2]==sid and r[1]==9005 for r in new.values())==1 for sid in [9003880,9003881]))
old,op=dbc((B/'client_mpq输入_导入现有Patch-XA/DBFilesClient/SpellIcon.dbc').read_bytes());new,np=dbc((P/'client_mpq输入_导入现有Patch-XA/DBFilesClient/SpellIcon.dbc').read_bytes())
ck('old icons preserved',all(new[k]==v for k,v in old.items()) and np.startswith(op))
for sid in [910128,910129]:
 path=np[new[sid][1]:].split(b'\0')[0].decode().replace('\\','/')+'.blp';raw=(P/'02_覆盖到客户端根目录'/path).read_bytes();ck('matching icon '+str(sid),raw==(P/'client_mpq输入_导入现有Patch-XA'/path).read_bytes() and raw[:4] in (b'BLP1',b'BLP2'))
for rel in ['src/server/game/Spells/Spell.cpp','src/server/game/Entities/Player/Player.cpp']:ck('WD121B preserved '+rel,(P/'01_覆盖到源代码根目录'/rel).read_bytes()==(Q/'01_覆盖到源代码根目录'/rel).read_bytes())
(P/'checks/data.json').write_text(json.dumps({'status':'PASS','checks':checks},ensure_ascii=False,indent=2),encoding='utf8')
# Full historical isolated SQL suite plus this batch's persistence and choice guards.
for f in (B/'research').glob('*.tsv'):shutil.copy2(f,P/'research'/f.name)
s=(B/'tools/test_mysql.py').read_text(encoding='utf8').replace('_wd121_sql_scratch_','_wd122_sql_scratch_').replace('01_CHARACTERS_WD121A_必须执行.sql','01_CHARACTERS_WD122A_必须执行.sql').replace('classbase+2**90','classbase+2**92').replace('f8+2**90,80','f8+2**92,80')
s=s.replace("(P/'rollback/server_SQL/01_CHARACTERS_WD105A.sql')",repr(B/'rollback/server_SQL/01_CHARACTERS_WD105A.sql').replace('WindowsPath(', 'Path('))
s=s.replace('6498,29303);\');q(rollback)','6498,29303,6020,29737);\');q(rollback)')
anchor=" before=q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id;')\n rollback="
block=''' for g in range(190,196):
  q(f"INSERT INTO characters(guid,account,name,taximask,innTriggerId,race,class,money) VALUES({g},10,'wd122test{g}','',0,1,13,10000000); INSERT INTO reborn_wd5a_builds(guid) VALUES({g}); INSERT INTO reborn_wd67_members(guid,enabled) VALUES({g},1); INSERT INTO reborn_wd13_slots(guid,slot,paid_copper) VALUES({g},0,0),({g},1,10000000); INSERT INTO reborn_wd16_profiles VALUES({g},0,0),({g},1,1),({g},2,3);")
 booms=2**90;doctor=2**91
 ck('122 Booms save',save(190,0,f8+booms,80,slot=1)=='1')
 ck('122 Doctor save',save(191,0,f8+doctor,80,slot=1)=='1')
 ck('122 exact rows',q('SELECT node_id FROM reborn_wd67_nodes WHERE guid=190 AND node_id=6020')=='6020' and q('SELECT node_id FROM reborn_wd67_nodes WHERE guid=191 AND node_id=29737')=='29737')
 ck('122 reload reconstruction',save(190,1,f8+booms,80,slot=1)=='1')
 ck('122 choice exclusive',save(192,0,f8+booms+doctor,80,slot=1)=='0')
 ck('122 no same tier bootstrap',save(192,0,f8-2**55+booms+boss,80,slot=1)=='0')
 ck('122 wrong spec',save(192,0,f8+doctor,80,slot=0)=='0')
 ck('122 next bit rejected',save(192,0,f8+2**92,80,slot=1)=='0')
 ck('122 fresh and boss coexist',save(193,0,f8+2*fresh+boss+booms,80,slot=1)=='1')
 ck('122 cannot free switch chosen node',save(190,2,f8+doctor,80,slot=1)=='0')
 before122=q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id; SELECT * FROM reborn_wd13_slots ORDER BY guid,slot;')
 q(install);q(install);ck('122 reimport preserves all plans/purchases',before122==q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id; SELECT * FROM reborn_wd13_slots ORDER BY guid,slot;'))
'''
assert s.count(anchor)==1;s=s.replace(anchor,block+anchor);(T/'test_mysql.py').write_text(s,encoding='utf8')
print('PASS data/UI; SQL suite prepared')
