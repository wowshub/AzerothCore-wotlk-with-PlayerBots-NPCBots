from pathlib import Path
import sys,re,json
B=Path(Path('wd124_path.txt').read_text().strip())
P=Path(Path('wd125_path.txt').read_text().strip())
sys.path.insert(0,str(P/'tools'))
from wd19_common import dbc
ids=set(range(9003901,9003909))
for pref in ['03_覆盖到服务端根目录/Data/dbc','client_mpq输入_导入现有Patch-XA/DBFilesClient']:
 for name in ['Spell','SkillLineAbility']:
  before,pool0=dbc((B/pref/(name+'.dbc')).read_bytes())
  after,pool=dbc((P/pref/(name+'.dbc')).read_bytes())
  assert pool.startswith(pool0)
  assert all(after[i]==v for i,v in before.items())
  if name=='Spell':
   assert set(after)-set(before)==ids
   assert after[9003901][116]==9003902 and after[9003905][116]==9003906
   assert after[9003902][95:97]==[31,58]
   assert after[9003906][95]==87 and after[9003906][80]==(2**32-4)
   assert after[9003903][95:98]==[49,31,216]
   assert after[9003904][95:98]==[192,31,216]
   assert after[9003907][95]==69 and after[9003908][95]==69
   for sid in ids:
    r=after[sid]
    for col in list(range(136,169))+list(range(170,203)):
     if col%17==16:continue
     assert r[col]<len(pool) and pool.find(b'\0',r[col])>=0,(pref,sid,col)
  else:
   for sid in (9003901,9003905):assert sum(row[2]==sid for row in after.values())==1
   for sid in ids-{9003901,9003905}:assert not any(row[2]==sid for row in after.values())
sql=(P/'server_SQL/01_CHARACTERS_WD125A_必须执行.sql').read_text(encoding='utf8')
assert '29738' in sql and str(2**98-1) in sql and 'r85' in sql
cpp=(P/'01_覆盖到源代码根目录/modules/mod-reborn-witchdoctor/src/RebornWitchDoctorAllocation.inc').read_text(encoding='utf8')
assert 'AEIds[86]' in cpp and '(mask>>98)!=0' in cpp
assert 'AEMask const maximum=(AEMask(1)<<98)-1;' in cpp
assert 'bool const supportWanted[4]' in cpp and 'bool wanted[8]' in cpp
print('PASS WD125 old DBC rows, 8 private spells, spellbook visibility, SQL mask and C++ allocation')
