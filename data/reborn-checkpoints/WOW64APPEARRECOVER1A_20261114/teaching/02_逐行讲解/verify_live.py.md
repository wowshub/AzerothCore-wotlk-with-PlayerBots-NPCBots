# verify_live.py 逐行教学
此脚本只读；面向当前E归档或本机只读指纹，不替代游戏测试。

第1行：
```python
from pathlib import Path
```
导入标准库：文件路径、二进制读数、指纹或JSON。

第2行：
```python
import hashlib,json
```
导入标准库：文件路径、二进制读数、指纹或JSON。

第3行：
```python
r=Path(r'D:\000rebornWOW\000RebornWOWHighForkPRO')
```
建立当前步骤的值、资源或范围；脚本主课08解释整体目标。

第4行：
```python
c=r/'beascendclient/newrebornWOWli20261107beAscend'
```
建立当前步骤的值、资源或范围；脚本主课08解释整体目标。

第5行：
```python
a=r/'000Ascendupdate/000Ascendupdate20261111/codexwork_WOW64CREATORAUDIT1A/audit.py'
```
建立当前步骤的值、资源或范围；脚本主课08解释整体目标。

第6行：
```python
ns={'__file__':str(a)}
```
建立当前步骤的值、资源或范围；脚本主课08解释整体目标。

第7行：
```python
exec(a.read_text('utf8').split('clients=')[0],ns)
```
读取已有文件字节/MPQ条目，不执行覆盖操作。

第8行：
```python
report={'active_disable_flag':(c/'EsteriaOff.txt').exists(),'files':[]}
```
建立当前步骤的值、资源或范围；脚本主课08解释整体目标。

第9行：
```python
def add(name,b):report['files'].append({'file':name,'size':len(b),'sha256':hashlib.sha256(b).hexdigest()})
```
建立当前步骤的值、资源或范围；脚本主课08解释整体目标。

第10行：
```python
for name in ('WowClient64.exe','EsteriaAppearanceGeometry.bin'):add(name,(c/name).read_bytes())
```
循环覆盖声明范围；仅这些样本被检查。

第11行：
```python
for archive,entries in [('Patch-YB.mpq',[r'Esteria\RebornNativeMechagnome.bin',r'Interface\GlueXML\CharacterSelect.lua']),('Patch-YI.mpq',[r'custom\mechagnome\native\male\mechagnomemale00.skin',r'custom\mechagnome\native\female\mechagnomefemale00.skin'])]:
```
循环覆盖声明范围；仅这些样本被检查。

第12行：
```python
 m=ns['StormReader'](str(c/'Data'/archive))
```
建立当前步骤的值、资源或范围；脚本主课08解释整体目标。

第13行：
```python
 try:
```
建立当前步骤的值、资源或范围；脚本主课08解释整体目标。

第14行：
```python
  for entry in entries:
```
循环覆盖声明范围；仅这些样本被检查。

第15行：
```python
   b=m.read_file(entry);assert b is not None,entry;add(archive+':'+entry,b)
```
断言不变量；失败立即停止，不能用python -O跳过。

第16行：
```python
 finally:m.close()
```
建立当前步骤的值、资源或范围；脚本主课08解释整体目标。

第17行：
```python
print(json.dumps(report,ensure_ascii=False,indent=2))
```
输出报告/案例结果，不能把输出当画面渲染证明。
