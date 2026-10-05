from pathlib import Path
import re,json,shutil,subprocess
from wd19_common import dbc
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');B=Path(Path('wd122_path.txt').read_text());P=Path(Path('wd123_path.txt').read_text());T=P/'tools';A=P/'02_覆盖到客户端根目录/Interface/AddOns';(P/'checks').mkdir(exist_ok=True)
lua=R/'beascendBuild/modules/mod-ale/src/lualib/lua/RelWithDebInfo/lua52_interpreter.exe'
for f in T.glob('scenario*.lua'):
 s=f.read_text(encoding='utf8')
 for name in ['all','frog','both','booms']:s=s.replace(f'MaskSet({name},92,1,1)',f'MaskSet({name},93,1,1)')
 s=s.replace('4951760157141521099596496896','9903520314283042199192993792');f.write_text(s,encoding='utf8')
s=(T/'scenario122.lua').read_text(encoding='utf8')+'''
M.level=17;M.teBudget=1;M.aeBudget=56;M.specs[2]=1;M.pending=nil
local splash=M.MaskSet(0,92,1,1)
assert(M.AEValid(splash) and M.AERank(7128,splash)==1 and M.TESpent(splash)==1 and M.AESpent(splash)==0)
M.level=16;assert(not M.AEValid(splash));M.level=17
M.teBudget=0;assert(not M.AEValid(splash));M.teBudget=1
M.specs[2]=0;assert(not M.AEValid(splash));M.specs[2]=1
assert(not M.AEValid(M.MaskSet(splash,93,1,1)))
M.aeMasks[2]=0;M.draftAE=splash;M.aeDirty=true;M.dirty=true;M.pending=nil
M.Save();assert(sent and sent:match(' '..M.MaskDecimal(splash)..'$'))
assert(M.IsAENode(7128) and M.AETooltip({ID=7128,AECost=0,TECost=1}))
M.level=80;M.teBudget=55
local foundation7=M.MaskSet(f8,55,2,1)
local withSplash=M.MaskSet(foundation7,92,1,1)
assert(M.BrewingFoundation(withSplash)==8 and M.AEValid(M.MaskSet(withSplash,90,1,1)))
print('PASS WD123 level17/TE1/no false foundation/spec/93bit/save')
'''
(T/'scenario123.lua').write_text(s,encoding='utf8')
s=(T/'wd122_numeric_test.lua').read_text(encoding='utf8')+'''
for _,spell in ipairs({9003890,9003896}) do
 id=spell;now=now+3;reset();M.invalidate();M.refresh(GameTooltip)
 M.receive('WD114|'..seq()..'|'..spell..'|ok|500|100|150|10|1|23|12000')
 local text=_G['GameTooltipTextLeft'..GameTooltip.n].text
 assert(text:find('100',1,true) and text:find('150',1,true) and text:find('23',1,true) and text:find('12',1,true))
 M.invalidate();now=now+3;M.refresh(GameTooltip)
 assert(not _G['GameTooltipTextLeft'..GameTooltip.n].text:find('150',1,true))
end
print('PASS WD123 direct plus HoT server values, ranks, stale invalidation')
'''
(T/'wd123_numeric_test.lua').write_text(s,encoding='utf8')
def run(name,args):
 r=subprocess.run([str(lua)]+[str(x) for x in args],capture_output=True,encoding='utf8',errors='replace');(P/'checks'/name).write_text(r.stdout+r.stderr,encoding='utf8');print(r.stdout,r.stderr);assert r.returncode==0,name
run('lua.txt',[T/'scenario123.lua',A/'RebornWitchDoctorTalents/WD8.lua',A/'RebornWitchDoctorTalents/Allocation.lua',T/'scenario87_regression.lua',T/'scenario88.lua',T/'scenario91.lua'])
run('syntax.txt',[T/'check_syntax.lua']+list(A.rglob('*.lua')))
for name,script,addon in [('numeric','wd123_numeric_test.lua','RebornWitchDoctorTalents/NumericTooltip.lua'),('book','wd119b_book_test.lua','RebornWitchDoctorSkillBook/RebornWitchDoctorSkillBook.lua'),('cooldown','wd119b_cooldown_test.lua','RebornWDCooldownTooltip/Cooldown.lua')]:run('ui_'+name+'.txt',[T/script,A/addon])
checks=[]
def ck(n,b):assert b,n;checks.append(n)
fmt=(R/'beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots/src/server/shared/DataStores/DBCfmt.h').read_text();fmt=re.search(r'SpellEntryfmt\[\]\s*=\s*"([^"]+)"',fmt)[1]
donor=json.loads((P/'research/splash_closure.json').read_text(encoding='utf8'));mapping={802710:9003890,**{567731+i:9003891+i for i in range(6)}}
for prefix in ['03_覆盖到服务端根目录/Data/dbc','client_mpq输入_导入现有Patch-XA/DBFilesClient']:
 for table in ['Spell','SkillLineAbility']:
  old,op=dbc((B/prefix/(table+'.dbc')).read_bytes());new,np=dbc((P/prefix/(table+'.dbc')).read_bytes())
  def same(k,r):return (new[k][:170]==r[:170] and new[k][203:]==r[203:] and new[k][186]==r[186]) if table=='Spell' and k==9003879 else new.get(k)==r
  ck(prefix+table+' old mechanics unchanged; only Boss description extended',all(same(k,r) for k,r in old.items()) and np.startswith(op))
  if table=='Spell':
   ck('exact 7 active +1 hidden additions',set(new)-set(old)=={9003889,*range(9003890,9003897)})
   for i,r in new.items():
    for col,kind in enumerate(fmt):
     if kind=='s':assert r[col]<len(np) and np.find(b'\0',r[col])>=0,(i,col)
   ck('all string offsets valid',True)
   for src,sid in mapping.items():
    r=new[sid];d=donor[str(src)]['row'];ck('rank '+str(sid),r[37:40]==d[37:40] and r[74]==d[74] and r[77]==d[77] and r[80]==d[80])
    ck('ground/cap/radius/cooldown/cost '+str(sid),r[86:92]==[87,0,0,31,0,0] and r[212]==8 and r[92]==13 and r[29]==15000 and r[30]==0 and r[204]==20)
    ck('no foreign dummy triggers '+str(sid),r[71:74]==[10,0,0] and r[116:131]==[0]*15 and r[226:234]==[0]*8)
   r=new[9003889];d=donor['803698']['row'];ck('hidden correct healing, 12sec/3sec',r[95:98]==[8,0,0] and r[40]==29 and r[98]==3000 and r[77]==d[77] and r[80]==d[80])
  else:ck('book highest rank chain, hidden absent',all(sum(r[2]==sid and r[1]==9005 for r in new.values())==1 for sid in mapping.values()) and not any(r[2]==9003889 for r in new.values()))
old,op=dbc((B/'client_mpq输入_导入现有Patch-XA/DBFilesClient/SpellIcon.dbc').read_bytes());new,np=dbc((P/'client_mpq输入_导入现有Patch-XA/DBFilesClient/SpellIcon.dbc').read_bytes());ck('icons old preserved',all(new[k]==v for k,v in old.items()) and np.startswith(op));path=np[new[910130][1]:].split(b'\0')[0].decode().replace('\\','/')+'.blp';raw=(P/'02_覆盖到客户端根目录'/path).read_bytes();ck('icon dual path',raw==(P/'client_mpq输入_导入现有Patch-XA'/path).read_bytes() and raw[:4] in (b'BLP1',b'BLP2'))
for rel in ['src/server/game/Spells/Spell.cpp','src/server/game/Entities/Player/Player.cpp']:ck('WD121B retained '+rel,(P/'01_覆盖到源代码根目录'/rel).read_bytes()==(B/'01_覆盖到源代码根目录'/rel).read_bytes())
(P/'checks/data.json').write_text(json.dumps({'status':'PASS','checks':checks},ensure_ascii=False,indent=2),encoding='utf8')
for f in (B/'research').glob('*.tsv'):shutil.copy2(f,P/'research'/f.name)
s=(B/'tools/test_mysql.py').read_text(encoding='utf8').replace('_wd122_sql_scratch_','_wd123_sql_scratch_').replace('01_CHARACTERS_WD122A_必须执行.sql','01_CHARACTERS_WD123A_必须执行.sql').replace('classbase+2**92','classbase+2**93').replace('f8+2**92,80','f8+2**93,80')
s=s.replace('6020,29737);\');q(rollback)','6020,29737,7128);\');q(rollback)')
anchor=" before=q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id;')\n rollback="
block=''' for g in range(200,205):
  q(f"INSERT INTO characters(guid,account,name,taximask,innTriggerId,race,class,money) VALUES({g},10,'wd123test{g}','',0,1,13,10000000); INSERT INTO reborn_wd5a_builds(guid) VALUES({g}); INSERT INTO reborn_wd67_members(guid,enabled) VALUES({g},1); INSERT INTO reborn_wd13_slots(guid,slot,paid_copper) VALUES({g},0,0),({g},1,10000000); INSERT INTO reborn_wd16_profiles VALUES({g},0,0),({g},1,1),({g},2,3);")
 splash=2**92
 ck('123 first rank17 accepted without false foundation',save(200,0,splash,17,slot=1)=='1')
 ck('123 level16 denied',save(201,0,splash,16,slot=1)=='0')
 ck('123 wrong spec',save(201,0,splash,80,slot=0)=='0')
 ck('123 bit93 denied',save(201,0,2**93,80,slot=1)=='0')
 ck('123 reloaded mask',save(200,1,splash,17,slot=1)=='1')
 ck('123 no free unlearn',save(200,2,0,17,slot=1)=='0')
 ck('123 old passives plus new spell',save(202,0,f8+2*fresh+boss+booms+splash,80,slot=1)=='1')
 ck('123 earlier Splash counts in foundation8',save(203,0,f8-2**55+splash+booms,80,slot=1)=='1')
 before123=q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id; SELECT * FROM reborn_wd13_slots ORDER BY guid,slot;')
 q(install);q(install);ck('123 reimport preserves',before123==q('SELECT * FROM reborn_wd67_nodes ORDER BY guid,slot,node_id; SELECT * FROM reborn_wd13_slots ORDER BY guid,slot;'))
 w123=(P/'server_SQL/04_WORLD_WD123A_必须执行.sql').read_text(encoding='utf8')
 q(w123);q(w123)
 ck('123 seven scripts',q("SELECT COUNT(*) FROM spell_script_names WHERE spell_id BETWEEN 9003890 AND 9003896 AND ScriptName='spell_reborn_wd120_brewing'")=='7')
 ck('123 seven zero manual coefficients',q('SELECT COUNT(*) FROM spell_bonus_data WHERE entry BETWEEN 9003890 AND 9003896 AND direct_bonus=0 AND dot_bonus=0')=='7')
 ck('123 ordered rank chain',q('SELECT COUNT(*) FROM spell_ranks WHERE first_spell_id=9003890 AND `rank`=spell_id-9003889')=='7')
 ck('123 hidden heal native, no script',q('SELECT COUNT(*) FROM spell_script_names WHERE spell_id=9003889')=='0')
 q("UPDATE spell_script_names SET ScriptName='conflict123' WHERE spell_id=9003891")
 ck('123 script conflict rejected',q(w123,fail=True));q("UPDATE spell_script_names SET ScriptName='spell_reborn_wd120_brewing' WHERE spell_id=9003891")
 q('UPDATE spell_bonus_data SET direct_bonus=1 WHERE entry=9003892')
 ck('123 coefficient conflict rejected',q(w123,fail=True));q('UPDATE spell_bonus_data SET direct_bonus=0 WHERE entry=9003892')
 q('UPDATE spell_ranks SET `rank`=9 WHERE spell_id=9003893')
 ck('123 rank conflict rejected',q(w123,fail=True));q('UPDATE spell_ranks SET `rank`=4 WHERE spell_id=9003893')
 q(w123)
'''
assert s.count(anchor)==1;s=s.replace(anchor,block+anchor);(T/'test_mysql.py').write_text(s,encoding='utf8')
print('PASS data/UI; isolated SQL suite ready')
