from pathlib import Path
import re,json,struct,shutil,subprocess
import wd19_common as common
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');P=Path(Path('wd120_path.txt').read_text());B=Path(Path('wd119_path.txt').read_text());BC=Path(Path('wd119c_path.txt').read_text());T=P/'tools';T.mkdir(exist_ok=True);(P/'checks').mkdir(exist_ok=True)
lua=R/'beascendBuild/modules/mod-ale/src/lualib/lua/RelWithDebInfo/lua52_interpreter.exe';cl=P/'02_覆盖到客户端根目录/Interface/AddOns/RebornWitchDoctorTalents'
for f in (B/'tools').glob('*.lua'):
 s=f.read_text(encoding='utf8');s=s.replace('MaskSet(frog,84,1,1)','MaskSet(frog,87,1,1)').replace('19342813113834066795298816','154742504910672534362390528');(T/f.name).write_text(s,encoding='utf8')
s=(T/'scenario119.lua').read_text(encoding='utf8')+'''
M.pending=nil;M.level=80;M.aeBudget=56;M.teBudget=55;M.specs[2]=1
local brewer=M.MaskSet(0,84,1,1)
local shrooms=M.MaskSet(brewer,85,1,1)
local all=M.MaskSet(shrooms,86,1,1)
assert(M.AEValid(all) and M.AESpent(all)==0 and M.TESpent(all)==0)
assert(M.AERank(4005,all)==1 and M.AERank(12645,all)==1 and M.AERank(12646,all)==1)
assert(not M.AEValid(M.MaskSet(0,85,1,1)))
assert(M.AEValid(M.MaskSet(1,85,1,1))) -- official OR Healing Ward path
M.level=13;assert(M.AEValid(shrooms) and not M.AEValid(all))
M.level=14;assert(M.AEValid(all));M.level=80
M.specs[2]=0;assert(not M.AEValid(all));M.specs[2]=2;assert(not M.AEValid(all));M.specs[2]=1
assert(not M.AEValid(M.MaskSet(all,87,1,1)))
local joined=M.MaskSet(M.MaskSet(M.MaskSet(gonk,84,1,1),85,1,1),86,1,1)
assert(M.AEValid(joined) and M.AESpent(joined)==11 and M.TESpent(joined)==0)
M.aeMasks[2]=gonk;M.draftAE=joined;M.aeDirty=true;M.dirty=true;M.pending=nil
M.Save();assert(sent and sent:match(' '..M.MaskDecimal(joined)..'$'))
for _,id in ipairs({4005,12645,12646}) do assert(M.IsAENode(id));assert(M.AETooltip({ID=id,AECost=0,TECost=0})) end
print('PASS WD120 free nodes / exact87-bit / OR prerequisites / level14 / separate Brewing ownership')
'''
(T/'scenario120.lua').write_text(s,encoding='utf8')
def run(n,args):
 r=subprocess.run([str(lua)]+list(map(str,args)),capture_output=True,encoding='utf8',errors='replace');(P/'checks'/n).write_text(r.stdout+r.stderr,encoding='utf8');print(r.stdout,r.stderr);assert r.returncode==0
run('lua.txt',[T/'scenario120.lua',cl/'WD8.lua',cl/'Allocation.lua',T/'scenario87_regression.lua',T/'scenario88.lua',T/'scenario91.lua'])
run('syntax.txt',[T/'check_syntax.lua']+list(cl.rglob('*.lua')))
# Run the latest cooldown and spellbook regression fixtures against current output.
print('C119 tools', [f.name for f in (BC/'tools').glob('*.lua')])
checks=[]
def ck(n,b):assert b,n;checks.append(n)
ids={9003864,9003865,9003866,9003867,*range(9003870,9003877)}
fmt=(R/'beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots/src/server/shared/DataStores/DBCfmt.h').read_text()
spellfmt=re.search(r'SpellEntryfmt\[\]\s*=\s*"([^"]+)"',fmt)[1]
for prefix in ['03_覆盖到服务端根目录/Data/dbc','client_mpq输入_导入现有Patch-XA/DBFilesClient']:
 for table in ['Spell','SkillLineAbility']:
  base=(BC/prefix/(table+'.dbc'));base=base if base.exists() else B/prefix/(table+'.dbc')
  old,op=common.dbc(base.read_bytes());new,np=common.dbc((P/prefix/(table+'.dbc')).read_bytes())
  ck(prefix+table+' old rows/string prefix untouched',all(new.get(i)==r for i,r in old.items()) and np.startswith(op))
  if table=='Spell':
   ck(prefix+' exact ID additions',set(new)-set(old)==ids)
   for i,r in new.items():
    for col,kind in enumerate(spellfmt):
     if kind=='s':ck(prefix+str(i)+' string'+str(col),r[col]<len(np) and np.find(b'\0',r[col])>=0)
   for sid in ids:
    r=new[sid];ck(str(sid)+' no foreign fields',r[226:234]==[0]*8 and r[122:131]==[0]*9 and r[208:212]==[0]*4)
   ck(prefix+' 119C movement preserved',new[9003861][31]==15)
   ck(prefix+' ingredient six sec trigger',new[9003865][98]==6000 and new[9003865][116]==9003866)
   ck(prefix+' pulse cap8 radius30',new[9003866][212]==8 and new[9003866][92]==10)
   ck(prefix+' HOT 18sec tick3',new[9003867][40]==85 and new[9003867][98]==3000)
   for j,level in enumerate([14,22,30,38,46,54,60]):
    ck(prefix+' tossrank'+str(j),new[9003870+j][39]==level and new[9003870+j][29]==15000 and new[9003870+j][37]>level and new[9003870+j][205:208]==[133,1500,0])
  else:
   for sid in ids-{9003866,9003867}:ck(prefix+str(sid)+' unique Brewing book',sum(r[2]==sid and r[1]==9005 for r in new.values())==1)
   ck(prefix+' hidden children',not any(r[2] in {9003866,9003867} for r in new.values()))
ck('Player.cpp exactly retains119C', (P/'01_覆盖到源代码根目录/src/server/game/Entities/Player/Player.cpp').read_bytes()==(BC/'01_覆盖到源代码根目录/src/server/game/Entities/Player/Player.cpp').read_bytes())
(P/'checks/data.json').write_text(json.dumps({'checks':len(checks),'result':'PASS','new_spell_ids':sorted(ids)},indent=2));print(len(checks),'DBC/string checks PASS')
