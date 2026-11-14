# C_build_data.py 逐行读法
原件见03_代码原件；这里每行引用真实代码。空行只起分隔作用。下述是历史构建/测试代码，别直接向运行端执行。

**第1行**
```
exec((__import__('pathlib').Path(__file__).parent/'inspect_inputs.py').read_text('utf8').split("for n in ['Patch-YB.mpq'")[0])
```
执行当前表达式或方法；它仍受所在循环/分支限制。对文件的影响以旁边的白名单和断言为边界。

**第2行**
```
import shutil
```
执行当前表达式或方法；它仍受所在循环/分支限制。对文件的影响以旁边的白名单和断言为边界。

**第3行**
```
bwork=w.parent/'codexwork_WOW64RACEPORT1B'
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第4行**
```
j=json.loads((w/'preparation.json').read_text('utf8'));opt={};labels=j['labels'];offsets={0x28:0,0x2c:1,0x34:2,0x24:3,0x30:4}
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第5行**
```
fields=[0,1,2,3,1,2,2,4,3,0,0,4]
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第6行**
```
remap={**{2900+i:300+i for i in range(1,5)},**{3000+i:500+i for i in range(1,3)},**{3100+i:1000+i for i in range(1,3)},**{2400+i:1600+i for i in range(5)},1603:1803}
```
3000保留为不选中的重复腿；3001/3002才是两档机械腿。 31xx是独立机械脚组，避开普通装备隐藏组。

**第7行**
```
records=[];allgeos=[]
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第8行**
```
m=R(str(c/'Data/Patch-YI.mpq'))
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第9行**
```
for gender,sex in enumerate(['male','female']):
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第10行**
```
 p=j['sexes'][sex]['profile'];co={l:max(1,len(p['choices'][l])) for l in labels};factors=[1,1,1,1,co['Face'],co['Hair Style'],co['Hair Style']*co['Arm Upgrade'],1,co['Hair Color'],co['Skin Color'],co['Skin Color']*co['Paint'],co['Modification']];ops=list(zip(fields,[co[l] for l in labels],factors));opt[sex]=ops
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第11行**
```
 base='custom\\mechagnome\\native\\%s\\mechagnome%s'%(sex,sex);orig=m.read_file(base+'.m2');skin=m.read_file(base+'00.skin');n,o=struct.unpack_from('<II',skin,28);geos=set(struct.unpack_from('<H',skin,o+i*48)[0] for i in range(n));allgeos.append(sorted(geos))
```
按指定小端格式读字段，不是字符串处理；H/I分别占2/4字节。

**第12行**
```
 # Restore the correct shared type-5 material slots from the exact pre-B native model.
```
注释或编译/导入说明：阅读它确认这一段意图；注释本身不证明游戏行为。

**第13行**
```
 restored=(bwork/'backup_models'/Path(base.replace('\\','/')+'.m2')).read_bytes();assert len(restored)<=len(orig)
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。 只读原始字节，适用于模型和二进制目录。

**第14行**
```
 out=w/'model_patch'/Path(base.replace('\\','/')+'.m2');out.parent.mkdir(parents=True,exist_ok=True);out.write_bytes(restored)
```
保留字节精确输出，避免文本换行转换破坏证据。

**第15行**
```
 bak=w/'backup_models'/out.relative_to(w/'model_patch');bak.parent.mkdir(parents=True,exist_ok=True);bak.write_bytes(orig)
```
保留字节精确输出，避免文本换行转换破坏证据。

**第16行**
```
 for idx,label in enumerate(labels):
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第17行**
```
  choices=p['choices'][label];mapping=[]
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第18行**
```
  for choice in choices:mapping.append([remap.get(g,g) for g in p['geometry'].get(str(choice['ID']),[])])
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第19行**
```
  groups={g//100 for ls in mapping for g in ls if g!=0}
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第20行**
```
  for value,gs in enumerate(mapping):
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第21行**
```
   for group in groups:
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第22行**
```
    matches=[g for g in gs if g//100==group];assert len(matches)<=1
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。 统计满足条件的配方条数；应恰好1，0是缺配方，大于1是歧义。

**第23行**
```
    target=matches[0] if matches else group*100
```
统计满足条件的配方条数；应恰好1，0是缺配方，大于1是歧义。

**第24行**
```
    assert target%100==0 or target in geos,(sex,label,target)
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第25行**
```
    records.append(struct.pack('<7I128s',gender,0,group,target,(value<<16)|idx,0xffffffff,0xffffffff,b''))
```
执行当前表达式或方法；它仍受所在循环/分支限制。对文件的影响以旁边的白名单和断言为边界。

**第26行**
```
# Reuse actual installed material catalog, convert predicates to EHM1 selector indices.
```
注释或编译/导入说明：阅读它确认这一段意图；注释本身不证明游戏行为。

**第27行**
```
blob=(c/'EsteriaAppearanceMaterials.bin').read_bytes();magic,ver,count=struct.unpack_from('<3I',blob);assert magic==0x544d4145 and len(blob)==12+count*188
```
按指定小端格式读字段，不是字符串处理；H/I分别占2/4字节。 条件不成立立即中止，防止错误基线生成貌似正常的补丁。 只读原始字节，适用于模型和二进制目录。

**第28行**
```
for i in range(count):
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第29行**
```
 row=struct.unpack_from('<15I128s',blob,12+i*188)
```
按指定小端格式读字段，不是字符串处理；H/I分别占2/4字节。

**第30行**
```
 if row[0]!=47:continue
```
条件分支：只有满足当前条件才执行这一段，其他情形走后面的分支。

**第31行**
```
 sex=row[1];ops=opt[['male','female'][sex]];pred=[]
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第32行**
```
 for k in range(3):
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第33行**
```
  offset,factor,n,value=row[3+k*4:7+k*4];field=offsets[offset];idx=ops.index((field,n,factor));pred.append((value<<16)|idx)
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第34行**
```
 records.append(struct.pack('<7I128s',sex,1,row[2],0,*pred,row[15]))
```
执行当前表达式或方法；它仍受所在循环/分支限制。对文件的影响以旁边的白名单和断言为边界。

**第35行**
```
assert sum(struct.unpack_from('<I',v,4)[0]==1 for v in records)==792
```
按指定小端格式读字段，不是字符串处理；H/I分别占2/4字节。 条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第36行**
```
out=w/'client_patch/Esteria/RebornNativeMechagnome.bin';out.parent.mkdir(parents=True,exist_ok=True);out.write_bytes(struct.pack('<3I',0x314d4845,1,len(records))+b''.join(records))
```
保留字节精确输出，避免文本换行转换破坏证据。

**第37行**
```
# Earthen: install only eye/eyesight records, leave body/gear handling on its current native tables.
```
注释或编译/导入说明：阅读它确认这一段意图；注释本身不证明游戏行为。

**第38行**
```
blob=(c/'EsteriaEarthen.bin').read_bytes();count=struct.unpack_from('<I',blob,8)[0];er=[]
```
按指定小端格式读字段，不是字符串处理；H/I分别占2/4字节。 只读原始字节，适用于模型和二进制目录。

**第39行**
```
for i in range(count):
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第40行**
```
 row=list(struct.unpack_from('<7I128s',blob,12+i*156))
```
按指定小端格式读字段，不是字符串处理；H/I分别占2/4字节。

**第41行**
```
 if row[1]!=1 or row[2]!=5:continue
```
条件分支：只有满足当前条件才执行这一段，其他情形走后面的分支。

**第42行**
```
 for k in [4,5,6]:
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第43行**
```
  if row[k]==0xffffffff:continue
```
条件分支：只有满足当前条件才执行这一段，其他情形走后面的分支。

**第44行**
```
  idx=row[k]&65535;assert idx in [6,7];row[k]=(row[k]&0xffff0000)|(idx-1)
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第45行**
```
 er.append(struct.pack('<7I128s',*row))
```
执行当前表达式或方法；它仍受所在循环/分支限制。对文件的影响以旁边的白名单和断言为边界。

**第46行**
```
(w/'client_patch/Esteria/RebornNativeEarthenEyes.bin').write_bytes(struct.pack('<3I',0x314d4845,1,len(er))+b''.join(er))
```
保留字节精确输出，避免文本换行转换破坏证据。

**第47行**
```
m.close();(w/'options.json').write_text(json.dumps({'options':opt,'labels':labels,'earthen_options':[[0,14,1],[1,10,1],[2,11,1],[3,14,1],[4,11,1],[3,14,14],[1,4,10]],'earthen_labels':['Skin Color','Face','Hair Style','Hair Color','Beard Style','Eye Color','Eyesight'],'mecha_records':len(records),'earthen_records':len(er)},indent=2),'utf8');print('Catalogs',len(records),len(er),'restored native type5 slots; no geometry/model version replacement')
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。
