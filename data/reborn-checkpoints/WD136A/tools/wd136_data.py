# coding: utf-8
from wd136_init import *
import struct,sys
sys.path.insert(0,str(Path(Path('D:/000rebornWOW/wd128_path.txt').read_text().strip())/'tools'));from wd19_common import dbc
def pack(rows,pool):
 n=len(next(iter(rows.values())));return struct.pack('<4s4I',b'WDBC',len(rows),n,n*4,len(pool))+b''.join(struct.pack('<'+'I'*n,*r) for r in rows.values())+pool
icon='Interface/AddOns/RebornWitchDoctorTalents/Icons/adca7b653c1f090f.blp'
put(CF+icon,(C/icon).read_bytes());put('client_mpq输入_导入现有Patch-XA/'+icon,(C/icon).read_bytes())
for pre in ['client_mpq输入_导入现有Patch-XA/DBFilesClient','03_覆盖到服务端根目录/Data/dbc']:
 for n in ['Spell.dbc','SpellIcon.dbc','SkillLineAbility.dbc']:put('rollback_WD135UI/'+pre+'/'+n,(P/pre/n).read_bytes())
 ir,ip=dbc((P/pre/'SpellIcon.dbc').read_bytes());iid=max(ir)+1;ir[iid]=[iid,len(ip)];ip+=icon[:-4].replace('/','\\').encode()+b'\0';put(pre+'/SpellIcon.dbc',pack(ir,ip))
 r,pool=dbc((P/pre/'Spell.dbc').read_bytes())
 for n,base in [(9003954,9003950),(9003955,9003903),(9003956,9003952)]:
  assert n not in r
  v=r[base].copy();v[0]=n;v[133]=iid;v[34:37]=[0,0,0];v[37:40]=[0,57 if n==9003954 else 0,57 if n==9003954 else 0];v[29:34]=[0]*5;v[41:45]=[0]*4;v[204]=0;v[206:208]=[0,0];v[208:212]=[0]*4
  # Clear every effect's copied fields, including unsupported donor auras and masks.
  v[71:131]=[0]*60;v[71]=10 if n==9003956 else 6;v[74]=1;v[86]=1 if n==9003954 else 21;v[95]=0 if n==9003956 else 4
  v[80]=19 if n==9003954 else 4 if n==9003955 else 0
  v[40]=21 if n==9003954 else 8 if n==9003955 else 0;v[46]=1 if n==9003954 else 13
  if n==9003955:v[36]=3
  v[131:133]=[0,0]
  descriptions={9003954:'配料附效持续时间延长20%。丛林蘑菇给予15秒强化：接下来3次进攻技能按实际伤害的5%恢复自身生命。Ingredient effects last 20% longer. Jungle Shrooms grants 5% damage leech for the next 3 offensive casts within 15 sec.',9003955:'接下来3次进攻技能按实际伤害的5%恢复自身生命。一次施法的群攻和周期不额外消耗次数。Next 3 offensive casts heal you for 5% resolved damage; multiple targets and ticks share one cast.',9003956:'按已结算伤害回复，不再次计算法强或暴击。Resolved damage leech; no repeated scaling or crit.'}
  for start,text in [(136,'调制大师 / Master of Concoctions'),(153,'被动 / Passive' if n==9003954 else ''),(170,descriptions[n]),(187,descriptions[n] if n==9003955 else '')]:
   off=len(pool);pool+=text.encode('utf8')+b'\0';v[start:start+16]=[off]*16
  r[n]=v
 put(pre+'/Spell.dbc',pack(r,pool))
 sr,sp=dbc((P/pre/'SkillLineAbility.dbc').read_bytes());v=next(v.copy() for v in sr.values() if v[2]==9003950);v[0]=max(sr)+1;v[2]=9003954;sr[v[0]]=v;put(pre+'/SkillLineAbility.dbc',pack(sr,sp))
print('Three private spells, one talent book entry and independent icon tables generated.')
