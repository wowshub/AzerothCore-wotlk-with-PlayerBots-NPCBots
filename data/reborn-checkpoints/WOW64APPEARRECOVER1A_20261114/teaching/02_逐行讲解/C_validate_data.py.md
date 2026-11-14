# C_validate_data.py 逐行读法
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
m=R(str(c/'Data/Patch-YI.mpq'));paths=set();report=[]
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第5行**
```
for fn in ['RebornNativeMechagnome.bin','RebornNativeEarthenEyes.bin']:
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第6行**
```
 b=(w/'client_patch/Esteria'/fn).read_bytes();_,_,n=struct.unpack_from('<3I',b)
```
按指定小端格式读字段，不是字符串处理；H/I分别占2/4字节。 只读原始字节，适用于模型和二进制目录。

**第7行**
```
 for i in range(n):
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第8行**
```
  row=struct.unpack_from('<7I128s',b,12+i*156)
```
按指定小端格式读字段，不是字符串处理；H/I分别占2/4字节。

**第9行**
```
  if row[1]==1:paths.add(row[7].split(b'\0')[0].decode())
```
条件分支：只有满足当前条件才执行这一段，其他情形走后面的分支。

**第10行**
```
for p in sorted(paths):
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第11行**
```
 b=m.read_file(p);assert b and b[:4]==b'BLP2',p;wi,he=struct.unpack_from('<II',b,12);off=struct.unpack_from('<I',b,20)[0]
```
按指定小端格式读字段，不是字符串处理；H/I分别占2/4字节。 条件不成立立即中止，防止错误基线生成貌似正常的补丁。

**第12行**
```
 if b[8]==3:im=Image.frombytes('RGBA',(wi,he),b[off:off+wi*he*4],'raw','BGRA')
```
条件分支：只有满足当前条件才执行这一段，其他情形走后面的分支。

**第13行**
```
 else:im=Image.open(io.BytesIO(b));im.load()
```
条件分支：只有满足当前条件才执行这一段，其他情形走后面的分支。

**第14行**
```
 report.append({'path':p,'sha256':hashlib.sha256(b).hexdigest(),'dimensions':im.size})
```
计算字节指纹，以匹配输入输出，不代表游戏效果验收。

**第15行**
```
m.close();(w/'texture-validation.json').write_text(json.dumps(report,indent=2),'utf8')
```
保存本行右侧结果或设置对象状态；字段名与常量的具体含义结合本文件主课阅读，不能把赋值本身当验证。

**第16行**
```
# Current installed native variants match the original generator geoset vocabulary,
```
注释或编译/导入说明：阅读它确认这一段意图；注释本身不证明游戏行为。

**第17行**
```
# not the upstream's later full geometry/topology. Preserve current skin/animation.
```
注释或编译/导入说明：阅读它确认这一段意图；注释本身不证明游戏行为。

**第18行**
```
for p in (w/'model_patch').rglob('*.m2'):
```
遍历这里列出的每项；看右侧范围决定测试覆盖哪些组合，范围外不自动算通过。

**第19行**
```
 b=p.read_bytes();old=(w.parent/'codexwork_WOW64RACEPORT1B/backup_models'/p.relative_to(w/'model_patch')).read_bytes();assert b==old
```
条件不成立立即中止，防止错误基线生成貌似正常的补丁。 只读原始字节，适用于模型和二进制目录。

**第20行**
```
(w/'data-test.log').write_text('PASS %d material paths decoded; restored pre-B native M2 exactly; no SKIN/UV/bone/animation replacement\n'%len(paths),'utf8');print('PASS',len(paths),'eye atlas paths decode')
```
执行当前表达式或方法；它仍受所在循环/分支限制。对文件的影响以旁边的白名单和断言为边界。
