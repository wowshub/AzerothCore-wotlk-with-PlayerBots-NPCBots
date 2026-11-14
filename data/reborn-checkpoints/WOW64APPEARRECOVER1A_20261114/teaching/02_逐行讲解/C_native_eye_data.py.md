# C_native_eye_data.py 逐行读法
原件见03_代码原件；这里每行引用真实代码。空行只起分隔作用。下述是历史构建/测试代码，别直接向运行端执行。

**第1行**
```
exec((__import__('pathlib').Path(__file__).parent/'inspect_inputs.py').read_text('utf8').split("for n in ['Patch-YB.mpq'")[0])
```
执行当前表达式或方法；它仍受所在循环/分支限制。对文件的影响以旁边的白名单和断言为边界。

**第2行**
```
from PIL import Image
```
执行当前表达式或方法；它仍受所在循环/分支限制。对文件的影响以旁边的白名单和断言为边界。

**第3行**
```
import io
```
执行当前表达式或方法；它仍受所在循环/分支限制。对文件的影响以旁边的白名单和断言为边界。

**第4行**
```
m=R(str(c/'Data/Patch-YI.mpq'));ls=m.read_file('(listfile)').decode('utf8','replace').splitlines();print('\n'.join(x for x in ls if 'mechagnome' in x.lower() and 'eye' in x.lower())[:6000])
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第5行**
```
for race in ['mechagnome','earthen']:
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第6行**
```
 for sex in ['male','female']:
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第7行**
```
  for k in [1,2,3]:
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第8行**
```
   p='custom\\%s\\native\\%s\\eyes0_%d.blp'%(race,sex,k)
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第9行**
```
   try:b=m.read_file(p)
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第10行**
```
   except Exception:continue
```
执行当前表达式或方法；它仍受所在循环/分支限制。对文件的影响以旁边的白名单和断言为边界。

**第11行**
```
   if not b:continue
```
条件分支：只有满足当前条件才执行这一段，其他情形走后面的分支。

**第12行**
```
   wi,he=struct.unpack_from('<II',b,12);print(p,wi,he,b[8]);off=struct.unpack_from('<I',b,20)[0];im=Image.frombytes('RGBA',(wi,he),b[off:off+wi*he*4],'raw','BGRA') if b[8]==3 else Image.open(io.BytesIO(b));im.save(w/(race+'-'+sex+str(k)+'.png'))
```
按指定小端格式读字段，不是字符串处理；H/I分别占2/4字节。

**第13行**
```
m.close()
```
执行当前表达式或方法；它仍受所在循环/分支限制。对文件的影响以旁边的白名单和断言为边界。

**第14行**
```
y=R(str(c/'Data/Patch-YB.mpq'));b=y.read_file('DBFilesClient\\CharSections.dbc');_,n,nf,rs,ss=struct.unpack_from('<4s4I',b);st=b[20+n*rs:];rows=[struct.unpack_from('<10I',b,20+i*rs) for i in range(n)];s=lambda x:st[x:].split(b'\0')[0].decode()
```
按指定小端格式读字段，不是字符串处理；H/I分别占2/4字节。

**第15行**
```
for race in [67,68]:
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第16行**
```
 for sex in [0,1]:
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第17行**
```
  for section in [0,1,2,3,4]:
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第18行**
```
   q=[x for x in rows if x[1:4]==(race,sex,section)];print(race,sex,section,'count',len(q), [(x[8:],[s(a) for a in x[4:7]]) for x in q[:1]])
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第19行**
```
y.close()
```
执行当前表达式或方法；它仍受所在循环/分支限制。对文件的影响以旁边的白名单和断言为边界。
