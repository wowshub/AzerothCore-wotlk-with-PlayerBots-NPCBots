# coding: utf-8
from wd136_init import *
import subprocess,sys,struct,re
sys.path.insert(0,str(Path(Path('D:/000rebornWOW/wd128_path.txt').read_text().strip())/'tools'));from wd19_common import dbc
checks=[];CK=P/'checks';CK.mkdir(exist_ok=True)
def ck(n,v):assert v,n;checks.append(n)
fmt=re.search(r'SpellEntryfmt\[\]\s*=\s*"([^"]+)"',(S/'src/server/shared/DataStores/DBCfmt.h').read_text())[1]
for pre in ['client_mpq输入_导入现有Patch-XA/DBFilesClient','03_覆盖到服务端根目录/Data/dbc']:
 for name,added in [('Spell.dbc',3),('SpellIcon.dbc',1),('SkillLineAbility.dbc',1)]:
  r,p=dbc((P/pre/name).read_bytes());old,op=dbc((P/'rollback_WD135UI'/pre/name).read_bytes());ck(pre+name+' old records and strings preserved',all(r[k]==v for k,v in old.items()) and p.startswith(op));ck(pre+name+' exact appends',len(r)==len(old)+added)
 r,p=dbc((P/pre/'Spell.dbc').read_bytes())
 for row in r.values():
  for i,t in enumerate(fmt):
   if t=='s':assert 0<=row[i]<len(p) and p.find(b'\0',row[i])>=0
 ck(pre+' all localized strings valid',True)
 ck(pre+' buff three charges, 15s, no native proc',r[9003955][36]==3 and r[9003955][40]==8 and r[9003955][34]==0)
 ck(pre+' passive explicit 20 percent only dummy',r[9003954][80]==19 and r[9003954][95]==4 and r[9003954][72]==0)
 ck(pre+' previous two range fixes preserved',r[9003947][46]==1 and r[9003950][46]==1)
ck('accepted Recall icon preserved',dbc((P/'client_mpq输入_导入现有Patch-XA/DBFilesClient/Spell.dbc').read_bytes())[0][9003541][133]==3994)
lua=R/'beascendBuild/modules/mod-ale/src/lualib/lua/RelWithDebInfo/lua52_interpreter.exe';addon=P/CF/ADD
def run(n,script,arg):
 x=subprocess.run([str(lua),str(script),str(arg)],capture_output=True,encoding='utf8');put('checks/'+n+'.log',x.stdout+x.stderr);ck(n,x.returncode==0);return x.stdout
put('checks/syntax.lua','for i=1,#arg do assert(loadfile(arg[i])) end print("syntax passed")')
x=subprocess.run([str(lua),str(CK/'syntax.lua'),*map(str,(P/CF).rglob('*.lua'))],capture_output=True,encoding='utf8');put('checks/lua_syntax.log',x.stdout+x.stderr);ck('Lua syntax',x.returncode==0)
for name in ['previous_numeric_test.lua','potion_numeric_test.lua','scenario130.lua','scenario131.lua','scenario132.lua','scenario133.lua','actual_save132.lua','actual_save135.lua']:
 t=(B/'checks'/name).read_text(encoding='utf8').replace('MaskSet(crystal,117,1,1)','MaskSet(crystal,118,1,1)').replace('MaskSet(good,117,1,1)','MaskSet(good,118,1,1)');put('checks/'+name,t)
 run(name,CK/name,addon if name.startswith('actual_save') else addon/('NumericTooltip.lua' if 'numeric' in name else 'Allocation.lua'))
old=(Path(Path('D:/000rebornWOW/wd134b_path.txt').read_text().strip())/'checks/scenario134.lua').read_text(encoding='utf8')
head=old[:old.index('local base=')].replace('[6027]=103}','[6027]=103,[13133]=104,[6026]=105}')
body=r'''
local base="20604371637084532008189945406554112"
base=add(add(base,6014),12645)
for _,id in ipairs({30333,6027,29754,6026}) do base=add(base,id,0) end
assert(M.AEValid(base))
for pass=1,6 do for i=100,49,-1 do for id,k in pairs(index) do
 if k==i and id~=6014 and id~=12645 and M.BrewingSpent(base)>23 and M.AERank(id,base)>0 then
  local width=(id==6498 or id==35064 or id==7131 or id==30884 or id==29736) and 2 or 1
  local next=M.MaskSet(base,Shift(i),width,M.AERank(id,base)-1)
  if M.AEValid(next) then base=next end
 end
end end end
assert(M.BrewingSpent(base)==23)
local good=add(base,6026)
assert(M.AEValid(good));assert(M.TESpent(good)==M.TESpent(base)+1)
M.level=56;assert(not M.AEValid(good));M.level=57;assert(M.AEValid(good));M.level=80
assert(not M.AEValid(add(good,12645,0)));assert(not M.AEValid(add(good,6014,0)));assert(not M.AEValid(add(good,4005,0)))
M.specs[1]=0;assert(not M.AEValid(good));M.specs[1]=1
M.teBudget=M.TESpent(good)-1;assert(not M.AEValid(good));M.teBudget=100
assert(not M.AEValid(M.MaskSet(good,118,1,1)))
local less=base
for id,k in pairs(index) do if id~=6014 and id~=12645 and M.AERank(id,base)>0 then
 local width=(id==6498 or id==35064 or id==7131 or id==30884 or id==29736) and 2 or 1
 local m=M.MaskSet(base,Shift(k),width,M.AERank(id,base)-1)
 if M.AEValid(m) and M.BrewingSpent(m)==22 then less=m;break end
end end
assert(M.BrewingSpent(less)==22);assert(not M.AEValid(add(less,6026)))
M.CanEdit=function() return true end;M.aeDirty=true;M.draftAE=good;local got
M.Request=function(cmd,kind) got=cmd;assert(kind=='save') end;M.Save();assert(got=='.wd67save 1 0 '..M.MaskDecimal(good))
print('CONCOCTIONS '..M.MaskDecimal(good));print('LESS '..M.MaskDecimal(add(less,6026)));print('CONCOCTIONS_TE '..M.TESpent(good));print('PASS WD136 exact 118-bit save and prerequisite boundaries')
'''
put('checks/scenario136.lua',head+body);out=run('WD136 save scenario',CK/'scenario136.lua',addon/'Allocation.lua')
masks=json.loads((B/'checks/masks.json').read_text());masks.update({k:int(v) for k,v in re.findall(r'^(CONCOCTIONS|LESS|CONCOCTIONS_TE) (\d+)$',out,re.M)});put('checks/masks.json',json.dumps(masks,indent=2))
put('checks/verification.json',json.dumps({'status':'passed','checks':checks,'count':len(checks)},ensure_ascii=False,indent=2));print(len(checks),'data and actual Lua checks passed')
