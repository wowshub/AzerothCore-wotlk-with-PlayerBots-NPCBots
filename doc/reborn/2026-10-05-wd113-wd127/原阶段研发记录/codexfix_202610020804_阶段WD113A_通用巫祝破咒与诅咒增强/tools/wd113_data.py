from pathlib import Path
import struct,json
import wd19_common as c
P=Path(Path('wd113_path.txt').read_text(encoding='utf8'));B=Path(Path('wd112_path.txt').read_text(encoding='utf8'))
def pack(rows,pool):
 f=len(next(iter(rows.values())));return struct.pack('<4s4I',b'WDBC',len(rows),f,f*4,len(pool))+b''.join(struct.pack('<'+'I'*f,*r)for r in rows.values())+pool
desc=[('洛阿强化 / Loa Empowerment','巫祝技能耗蓝降低50%，力量巫祝效果提高20%；包含对应强效巫祝。现有增益需重新施放。 / Wuju mana cost -50%; Power Wuju effects +20%, including supported Greater Wujus. Recast existing buffs.'),('希里克的祝福 / Blessing of Hir\'eek','破咒术额外尝试移除一个诅咒。与黑暗魔精互斥。 / Hexbreak attempts to remove one additional curse. Exclusive with Dark Mojo.'),('显性诅咒 / Blatant Curse','倦怠、希里克、法力、缩小及恶毒诅咒耗蓝降低25%。 / Lethargy, Hir\'eek, Mana, Shrinking and Malignant Jinx mana cost reduced by 25%.')]
for prefix in ['03_覆盖到服务端根目录/Data/dbc/','client_mpq输入_导入现有Patch-XA/DBFilesClient/']:
 rows,pool=c.dbc((B/prefix/'Spell.dbc').read_bytes())
 for i,(name,text) in enumerate(desc):
  sid=9003850+i;assert sid not in rows
  r=rows[9003830].copy();r[0]=sid;r[38]=r[39]=10;r[133]=rows[[9003180,9003240,9003150][i]][133]
  for start in [71,74,77,80,83,86,89,92,95,98,101,104,107,110,113,116,119]:
   r[start:start+3]=[0]*3
  r[71]=6;r[74]=1;r[86]=1;r[95]=108;r[110]=14;r[80]=(-51 if i==0 else -26)&0xffffffff
  if i==0:r[72]=6;r[75]=1;r[87]=1;r[96]=108;r[111]=8;r[81]=19
  if i==1:r[95]=107;r[110]=3;r[80]=0
  for start,value in [(136,name),(153,''),(170,text),(187,'')]:
   offset=len(pool);pool+=value.encode()+b'\0'
   r[start:start+16]=[offset]*16
  rows[sid]=r
 path=P/prefix/'Spell.dbc';path.write_bytes(pack(rows,pool))
 rows,pool=c.dbc((B/prefix/'SkillLineAbility.dbc').read_bytes())
 for sid in range(9003850,9003853):
  assert not any(r[2]==sid for r in rows.values())
  r=next(r for r in rows.values()if r[2]==9003640).copy();r[0]=max(rows)+1;r[2]=sid;rows[r[0]]=r
 (P/prefix/'SkillLineAbility.dbc').write_bytes(pack(rows,pool))
print('Three native scoped modifiers added independently to client/server DBC')
