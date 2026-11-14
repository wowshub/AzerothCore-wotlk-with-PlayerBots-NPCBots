# E_build_fix.py 逐行读法
原件见03_代码原件；这里每行引用真实代码。空行只起分隔作用。下述是历史构建/测试代码，别直接向运行端执行。

**第1行**
```
from pathlib import Path
```
执行当前表达式或方法；它仍受所在循环/分支限制。对文件的影响以旁边的白名单和断言为边界。

**第2行**
```
import struct,json,hashlib
```
执行当前表达式或方法；它仍受所在循环/分支限制。对文件的影响以旁边的白名单和断言为边界。

**第3行**
```
w=Path(__file__).parent
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第4行**
```
b=(w/'selection-before.bin').read_bytes();out=bytearray(b);n=struct.unpack_from('<I',b,8)[0];changes=[]
```
按指定小端格式读字段，不是字符串处理；H/I分别占2/4字节。 只读原始字节，适用于模型和二进制目录。

**第5行**
```
for i in range(n):
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第6行**
```
 off=12+i*156;x=struct.unpack_from('<7I',b,off)
```
按指定小端格式读字段，不是字符串处理；H/I分别占2/4字节。

**第7行**
```
 if x[1]==0 and x[2] in [5,10]:
```
条件分支：只有满足当前条件才执行这一段，其他情形走后面的分支。

**第8行**
```
  assert (x[2],x[3]) in [(5,501),(5,502),(10,1001),(10,1002)]
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第9行**
```
  g=30 if x[2]==5 else 31;v=g*100+x[3]%100;struct.pack_into('<II',out,off+8,g,v);changes.append((i,x[0],x[2],x[3],g,v))
```
在指定字节位置写入有确定格式的值；不会自动懂M2语义，所以必须核对允许偏移。 原5/10组转30/31，选择记录必须和SKIN编号一起更新。

**第10行**
```
assert len(changes)==8
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第11行**
```
assert all(b[i]==out[i] or any(12+j[0]*156+8<=i<12+j[0]*156+16 for j in changes) for i in range(len(b)))
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第12行**
```
(w/'selection-after.bin').write_bytes(out);skins={};notes=[]
```
保留字节精确输出，避免文本换行转换破坏证据。

**第13行**
```
for sex in ['male','female']:
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第14行**
```
 k=(w/(sex+'-before.skin')).read_bytes();out=bytearray(k);n,o=struct.unpack_from('<II',k,28);allowed=[];seen=0;parts=[]
```
按指定小端格式读字段，不是字符串处理；H/I分别占2/4字节。 只读原始字节，适用于模型和二进制目录。

**第15行**
```
 assert all(struct.unpack_from('<H',k,o+i*48)[0]//100 not in [30,31] for i in range(n))
```
按指定小端格式读字段，不是字符串处理；H/I分别占2/4字节。 条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第16行**
```
 for i in range(n):
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第17行**
```
  off=o+i*48;g=struct.unpack_from('<H',k,off)[0];ng=g
```
按指定小端格式读字段，不是字符串处理；H/I分别占2/4字节。

**第18行**
```
  if g==501:
```
条件分支：只有满足当前条件才执行这一段，其他情形走后面的分支。

**第19行**
```
   ng=3000 if seen==0 else 3001;seen+=1
```
3000保留为不选中的重复腿；3001/3002才是两档机械腿。 原5/10组转30/31，选择记录必须和SKIN编号一起更新。

**第20行**
```
  elif g==502:ng=3002
```
原5/10组转30/31，选择记录必须和SKIN编号一起更新。

**第21行**
```
  elif g in [1001,1002]:ng=3100+g%100
```
31xx是独立机械脚组，避开普通装备隐藏组。

**第22行**
```
  if ng!=g:struct.pack_into('<H',out,off,ng);allowed.extend([off,off+1]);parts.append((i,g,ng))
```
在指定字节位置写入有确定格式的值；不会自动懂M2语义，所以必须核对允许偏移。

**第23行**
```
 assert seen==2 and len(parts)==5
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第24行**
```
 assert all(a==b or i in allowed for i,(a,b) in enumerate(zip(k,out)))
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第25行**
```
 # C runtime applies catalog >=19 directly; later ordinary equipment can only hide low-numbered groups.
```
注释或编译/导入说明：阅读它确认这一段意图；注释本身不证明游戏行为。

**第26行**
```
 for leg in [1,2]:
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第27行**
```
  for gear in ['NO','boots','pants','robe','T7','T14']:
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第28行**
```
   visible={3000,3001,3002,3101,3102}
```
3000保留为不选中的重复腿；3001/3002才是两档机械腿。

**第29行**
```
   visible-={3000,3001,3002};visible.add(3000+leg)
```
3000保留为不选中的重复腿；3001/3002才是两档机械腿。

**第30行**
```
   visible-={3100,3101,3102};visible.add(3100+leg)
```
31xx是独立机械脚组，避开普通装备隐藏组。

**第31行**
```
   if gear!='NO':visible={g for g in visible if not 501<=g<=599}
```
条件分支：只有满足当前条件才执行这一段，其他情形走后面的分支。

**第32行**
```
   assert (3000+leg) in visible and (3100+leg) in visible and 3000 not in visible
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。 3000保留为不选中的重复腿；3001/3002才是两档机械腿。 31xx是独立机械脚组，避开普通装备隐藏组。

**第33行**
```
   for group in [3000+leg,3100+leg]:
```
3000保留为不选中的重复腿；3001/3002才是两档机械腿。 31xx是独立机械脚组，避开普通装备隐藏组。

**第34行**
```
    rows=[struct.unpack_from('<10H',out,o+i*48) for i in range(n) if struct.unpack_from('<H',out,o+i*48)[0]==group]
```
按指定小端格式读字段，不是字符串处理；H/I分别占2/4字节。

**第35行**
```
    assert len(rows)==1 and rows[0][5]>0
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第36行**
```
 skins[sex]=bytes(out);(w/(sex+'-after.skin')).write_bytes(out);notes.append({'sex':sex,'section_id_only_changes':parts,'indices_vertices_bones_UV_unchanged':True})
```
保留字节精确输出，避免文本换行转换破坏证据。

**第37行**
```
b=(w/'geometry-before.bin').read_bytes();at=12;out=bytearray(b[:12]);count=struct.unpack_from('<I',b,8)[0];replaced=[]
```
按指定小端格式读字段，不是字符串处理；H/I分别占2/4字节。 只读原始字节，适用于模型和二进制目录。

**第38行**
```
for i in range(count):
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第39行**
```
 h=b[at:at+128];path=h.split(b'\0')[0].decode().lower().replace('\\','/');size=struct.unpack_from('<I',b,at+128)[0];blob=b[at+132:at+132+size];at+=132+size
```
按指定小端格式读字段，不是字符串处理；H/I分别占2/4字节。

**第40行**
```
 sex=next((s for s in ['female','male'] if path.endswith('/'+s+'/mechagnome'+s+'.m2')),None)
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第41行**
```
 if sex:
```
条件分支：只有满足当前条件才执行这一段，其他情形走后面的分支。

**第42行**
```
  assert blob==(w/(sex+'-before.skin')).read_bytes();blob=skins[sex];replaced.append(path)
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。 只读原始字节，适用于模型和二进制目录。

**第43行**
```
 out+=h+struct.pack('<I',len(blob))+blob
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第44行**
```
assert len(replaced)==2 and at==len(b) and len(out)==len(b)
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第45行**
```
(w/'geometry-after.bin').write_bytes(out)
```
保留字节精确输出，避免文本换行转换破坏证据。

**第46行**
```
report={'selection_records_changed':changes,'skins':notes,'catalog_rows':count,'other_24_unchanged':True,'offline_equipment_state_cases':24,'status':'未实机','files':{name:hashlib.sha256((w/name).read_bytes()).hexdigest() for name in ['selection-before.bin','selection-after.bin','geometry-before.bin','geometry-after.bin','male-before.skin','male-after.skin','female-before.skin','female-after.skin']}}
```
计算字节指纹，以匹配输入输出，不代表游戏效果验收。 只读原始字节，适用于模型和二进制目录。

**第47行**
```
(w/'validation.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),'utf8');print('PASS 8 selector records and 10 SKIN section IDs only; D triangles preserved; 24 offline gear/leg cases')
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。
