# D_build_fix.py 逐行读法
原件见03_代码原件；这里每行引用真实代码。空行只起分隔作用。下述是历史构建/测试代码，别直接向运行端执行。

**第1行**
```
from pathlib import Path
```
执行当前表达式或方法；它仍受所在循环/分支限制。对文件的影响以旁边的白名单和断言为边界。

**第2行**
```
import struct,hashlib,json,collections
```
执行当前表达式或方法；它仍受所在循环/分支限制。对文件的影响以旁边的白名单和断言为边界。

**第3行**
```
w=Path(__file__).parent
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第4行**
```
u16=lambda b,o:struct.unpack_from('<H',b,o)[0]
```
按指定小端格式读字段，不是字符串处理；H/I分别占2/4字节。

**第5行**
```
u32=lambda b,o:struct.unpack_from('<I',b,o)[0]
```
按指定小端格式读字段，不是字符串处理；H/I分别占2/4字节。

**第6行**
```
def arr(b,o,stride):
```
读取数量/起点，并以stride检查数组没有越过文件尾。

**第7行**
```
 n,p=struct.unpack_from('<II',b,o);assert p+n*stride<=len(b);return n,p
```
按指定小端格式读字段，不是字符串处理；H/I分别占2/4字节。 条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第8行**
```
def sections(k):
```
把每条48字节的SKIN部件解码，返回字节位置和字段。

**第9行**
```
 n,o=arr(k,28,48);return [(o+i*48,struct.unpack_from('<10H',k,o+i*48)) for i in range(n)]
```
按指定小端格式读字段，不是字符串处理；H/I分别占2/4字节。

**第10行**
```
def verts(b,k):
```
建立SKIN局部顶点与M2顶点的对应；几何特征与变形特征分开用于匹配和防歧义。

**第11行**
```
 n,o=arr(k,4,2);vn,vo=arr(b,60,48);pn,po=arr(k,20,4);assert pn==n
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第12行**
```
 out=[]
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第13行**
```
 for i in range(n):
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第14行**
```
  ix=u16(k,o+2*i);assert ix<vn;v=b[vo+ix*48:vo+(ix+1)*48]
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第15行**
```
  out.append((v[:12]+v[20:40],v[12:16]+k[po+i*4:po+i*4+4]+v[40:48]))
```
执行当前表达式或方法；它仍受所在循环/分支限制。对文件的影响以旁边的白名单和断言为边界。

**第16行**
```
 return out
```
返回当前计算结果/结束函数，调用方必须按返回值决定后续动作。

**第17行**
```
def indices(k):
```
解码整份16位面索引数组。

**第18行**
```
 n,o=arr(k,12,2);return list(struct.unpack_from('<%dH'%n,k,o))
```
按指定小端格式读字段，不是字符串处理；H/I分别占2/4字节。

**第19行**
```
def tri(k,row):
```
恢复部件面索引的高低位起点，再切出该部件的面。

**第20行**
```
 ix=indices(k);s=row[4]+(row[1]<<16);return ix[s:s+row[5]]
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第21行**
```
def validate(k):
```
独立复查输出的数组、部件和面索引边界。

**第22行**
```
 assert k[:4]==b'SKIN'
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第23行**
```
 for o,s in [(4,2),(12,2),(20,4),(28,48),(36,24)]:arr(k,o,s)
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第24行**
```
 nv,_=arr(k,4,2);ni,_=arr(k,12,2);ns,_=arr(k,28,48);assert 0<nv<=65535 and ni>0 and ns<=4096
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第25行**
```
 for p,x in sections(k):
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第26行**
```
  start=x[4]+(x[1]<<16);assert start<=ni and x[5]<=ni-start and x[2]+x[3]<=nv and x[6]<=75
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第27行**
```
  ts=tri(k,x);assert all(x[2]<=i<x[2]+x[3] for i in ts)
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第28行**
```
 return {'lookup_count':nv,'index_count':ni,'sections':ns}
```
返回当前计算结果/结束函数，调用方必须按返回值决定后续动作。

**第29行**
```
report=[];patched={}
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第30行**
```
for sex in ['male','female']:
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第31行**
```
 sb=(w/(sex+'-source.m2')).read_bytes();sk=(w/(sex+'-source.skin')).read_bytes()
```
只读原始字节，适用于模型和二进制目录。

**第32行**
```
 db=(w/(sex+'-target.m2')).read_bytes();dk=(w/(sex+'-target.skin')).read_bytes()
```
只读原始字节，适用于模型和二进制目录。

**第33行**
```
 assert dk==(w/(sex+'-catalog.skin')).read_bytes(), 'MPQ/catalog baseline differs'
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。 只读原始字节，适用于模型和二进制目录。

**第34行**
```
 sa,da=verts(sb,sk),verts(db,dk);old=indices(dk);new=list(old);out=bytearray(dk);changed=[];details=[]
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第35行**
```
 for sg,dg in [(2902,302),(2903,303),(2904,304),(3002,502),(3102,1002)]:
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第36行**
```
  sp,sx=next((p,x) for p,x in sections(sk) if x[0]==sg)
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第37行**
```
  dp,dx=next((p,x) for p,x in sections(dk) if x[0]==dg)
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第38行**
```
  assert dx[5]==0 and sx[5]>0 and sx[5]%3==0
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第39行**
```
  dest=collections.defaultdict(list)
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第40行**
```
  for i in range(dx[2],dx[2]+dx[3]):dest[da[i][0]].append(i)
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第41行**
```
  assert set(dest)=={sa[i][0] for i in range(sx[2],sx[2]+sx[3])}
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第42行**
```
  for ids in dest.values():assert len({da[i][1] for i in ids})==1,'ambiguous target deformation'
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第43行**
```
  source=tri(sk,sx);assert len(source)==sx[5] and all(sx[2]<=i<sx[2]+sx[3] for i in source)
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第44行**
```
  for key in {sa[i][0] for i in source}:
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第45行**
```
   assert len({sa[i][1] for i in range(sx[2],sx[2]+sx[3]) if sa[i][0]==key})==1,'ambiguous donor deformation'
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第46行**
```
  mapped=[dest[sa[i][0]][0] for i in source];start=len(new);new+=mapped
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第47行**
```
  struct.pack_into('<H',out,dp+2,start>>16);struct.pack_into('<HH',out,dp+8,start&65535,len(mapped))
```
在指定字节位置写入有确定格式的值；不会自动懂M2语义，所以必须核对允许偏移。

**第48行**
```
  changed.extend(range(dp+2,dp+4));changed.extend(range(dp+8,dp+12))
```
执行当前表达式或方法；它仍受所在循环/分支限制。对文件的影响以旁边的白名单和断言为边界。

**第49行**
```
  assert [sa[i][0] for i in source]==[da[i][0] for i in mapped], 'triangle positions/normals/UV/winding differ'
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第50行**
```
  def deg(attrs,ii):return sum(len({attrs[j][0][:12] for j in ii[t:t+3]})<3 for t in range(0,len(ii),3))
```
统计三角形是否有重合点，用来比较供体与映射后退化面数量。

**第51行**
```
  assert deg(sa,source)==deg(da,mapped)
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第52行**
```
  bn,bo=arr(dk,36,24);assert any(u16(dk,bo+i*24+4)==(dp-arr(dk,28,48)[1])//48 for i in range(bn)), 'no batch'
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第53行**
```
  details.append({'source':sg,'target':dg,'triangles':len(mapped)//3,'start':start,'high_word':start>>16,'same_triangle_attributes':True,'duplicate_deformation_ambiguity':0})
```
执行当前表达式或方法；它仍受所在循环/分支限制。对文件的影响以旁边的白名单和断言为边界。

**第54行**
```
 while len(out)%4:out.append(0)
```
执行当前表达式或方法；它仍受所在循环/分支限制。对文件的影响以旁边的白名单和断言为边界。

**第55行**
```
 offset=len(out);out.extend(struct.pack('<%dH'%len(new),*new));struct.pack_into('<II',out,12,len(new),offset);changed+=list(range(12,20))
```
在指定字节位置写入有确定格式的值；不会自动懂M2语义，所以必须核对允许偏移。

**第56行**
```
 assert all(a==b or i in changed for i,(a,b) in enumerate(zip(dk,out))), 'unrelated original bytes changed'
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第57行**
```
 assert indices(out)[:len(old)]==old
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第58行**
```
 for (_,x),(_,y) in zip(sections(dk),sections(out)):
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第59行**
```
  if x[5]:assert x==y and tri(dk,x)==tri(out,y)
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第60行**
```
  elif y[0] not in [302,303,304,502,1002]:assert x==y
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第61行**
```
 stats=validate(out);patched[sex]=bytes(out);(w/(sex+'-fixed.skin')).write_bytes(out)
```
保留字节精确输出，避免文本换行转换破坏证据。

**第62行**
```
 report.append({'sex':sex,'before_sha256':hashlib.sha256(dk).hexdigest(),'after_sha256':hashlib.sha256(out).hexdigest(),'details':details,'validation':stats,'original_drawable_sections_unchanged':True,'M2_unchanged':True})
```
计算字节指纹，以匹配输入输出，不代表游戏效果验收。

**第63行**
```
root=w.parents[2];client=root/'beascendclient/newrebornWOWli20261107beAscend';before=(w/'catalog-before.bin').read_bytes()
```
只读原始字节，适用于模型和二进制目录。

**第64行**
```
assert struct.unpack_from('<3I',before)==(0x4d474145,1,26)
```
按指定小端格式读字段，不是字符串处理；H/I分别占2/4字节。 条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第65行**
```
at=12;out=bytearray(before[:12]);replaced=[]
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第66行**
```
for i in range(26):
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第67行**
```
 header=before[at:at+128];path=header.split(b'\0')[0].decode();size=u32(before,at+128);blob=before[at+132:at+132+size];at+=132+size
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第68行**
```
 sex=next((s for s in ['female','male'] if path.lower().replace('\\','/').endswith('/'+s+'/mechagnome'+s+'.m2')),None)
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第69行**
```
 if sex:
```
条件分支：只有满足当前条件才执行这一段，其他情形走后面的分支。

**第70行**
```
  assert blob==(w/(sex+'-target.skin')).read_bytes();blob=patched[sex];replaced.append(path)
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。 只读原始字节，适用于模型和二进制目录。

**第71行**
```
 out.extend(header);out.extend(struct.pack('<I',len(blob)));out.extend(blob)
```
执行当前表达式或方法；它仍受所在循环/分支限制。对文件的影响以旁边的白名单和断言为边界。

**第72行**
```
assert at==len(before) and len(replaced)==2
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第73行**
```
(w/'EsteriaAppearanceGeometry.fixed.bin').write_bytes(out)
```
保留字节精确输出，避免文本换行转换破坏证据。

**第74行**
```
(w/'validation.json').write_text(json.dumps({'skins':report,'catalog':{'rows':26,'replaced':replaced,'other_24_rows_byte_identical':True,'before_sha256':hashlib.sha256(before).hexdigest(),'after_sha256':hashlib.sha256(out).hexdigest()}},indent=2),'utf8')
```
计算字节指纹，以匹配输入输出，不代表游戏效果验收。

**第75行**
```
print(json.dumps(report,indent=2));print('PASS: triangles restored; original vertices, deformation, UVs, batches and other catalog rows preserved')
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第76行**
```

```
空行：分隔逻辑段，没有执行动作。
