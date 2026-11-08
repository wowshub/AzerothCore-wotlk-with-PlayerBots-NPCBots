# 测试_codexwork_RACERELEASE1A_verify_frozen_archive.py：逐行讲解
实际验证代码；原样归档供学习。私有路径/环境必须先核对，不能运行到生产库或覆盖运行客户端。
来源：`D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261107\codexwork_RACERELEASE1A\verify_frozen_archive.py`。以下行号是所附原件的真实行号；空行/注释也保留。

## 原代码
```python
from pathlib import Path
import zipfile,json,hashlib,subprocess
W=Path(__file__).resolve().parent;C=json.loads((W/'context.json').read_text(encoding='utf-8'));P=Path(C['package']);G=Path(C['git']);CP=Path(C['checkpoint'])
sha=lambda b:hashlib.sha256(b).hexdigest()
z=zipfile.ZipFile(str(P)+'.zip');differences=[]
for n in z.namelist():
 if n.endswith('/'):continue
 f=P/n;b=z.read(n)
 if not f.is_file()or f.read_bytes()!=b:
  differences.append({'path':n,'frozen':sha(b),'unpacked':sha(f.read_bytes())if f.is_file()else None})
sql=next(n for n in z.namelist()if n.startswith('A_服务端_Codex/交付/data/customfixsql/')and n.endswith('.sql'))
b=z.read(sql);assert b'COALESCE(@RACENEXT1A_INTEGRATION_VERIFIED,0)'in b
dst=G/'data/customfixsql'/sql.split('/data/customfixsql/')[1];dst.write_bytes(b)
assert len(differences)==1 and differences[0]['path']==sql,differences
(CP/'frozen_archive_audit.json').write_text(json.dumps({'files':len([n for n in z.namelist()if not n.endswith('/')]),'unpacked_differences':differences,'action':'Published SQL restored from immutable original ZIP, default integration confirmation remains 0. Unpacked directory was not changed. No SQL executed.','archive_sha256':sha(Path(str(P)+'.zip').read_bytes())},ensure_ascii=False,indent=2),encoding='utf-8')
print('Frozen ZIP audited; one unpacked SQL guard difference. Restored original ZIP SQL only in publication tree.')
```

## 一行一行读
| 原件行号 | 代码 | 大白话解释 |
|---:|---|---|
| 1 | <code>from pathlib import Path</code> | 导入此行列出的Python库/对象，供路径、JSON、进程或二进制处理使用。 |
| 2 | <code>import zipfile,json,hashlib,subprocess</code> | 导入此行列出的Python库/对象，供路径、JSON、进程或二进制处理使用。 |
| 3 | <code>W=Path(__file__).resolve().parent;C=json.loads((W/'context.json').read_text(encoding='utf-8'));P=Path(C['package']);G=Path(C['git']);CP=Path(C['checkpoint'])</code> | 以指定编码读源码/报告，再做结构分析；读文本不是启动服务器。 只对指定发布工作树执行Git核对；正式发布白名单，不包含日常未知修改。 |
| 4 | <code>sha=lambda b:hashlib.sha256(b).hexdigest()</code> | 计算精确文件指纹；它证明字节相同，不证明玩法正确。 |
| 5 | <code>z=zipfile.ZipFile(str(P)+'.zip');differences=[]</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`z=zipfile.ZipFile(str(P)+'.zip');differences=[]`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 6 | <code>for n in z.namelist():</code> | 循环：for n in z.namelist()；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 7 | <code> if n.endswith('/'):continue</code> | 条件分支：只有`if n.endswith('/'):continue`成立才走随后分支；不满足进入else/跳过。 |
| 8 | <code> f=P/n;b=z.read(n)</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`f=P/n;b=z.read(n)`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 9 | <code> if not f.is_file()or f.read_bytes()!=b:</code> | 读取原始内容，哈希/归档按字节核对，避免换行归一掩盖变化。 |
| 10 | <code>  differences.append({'path':n,'frozen':sha(b),'unpacked':sha(f.read_bytes())if f.is_file()else None})</code> | 读取原始内容，哈希/归档按字节核对，避免换行归一掩盖变化。 |
| 11 | <code>sql=next(n for n in z.namelist()if n.startswith('A_服务端_Codex/交付/data/customfixsql/')and n.endswith('.sql'))</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`sql=next(n for n in z.namelist()if n.startswith('A_服务端_Codex/交付/data/customfixsql/')and n.endswith('.sql'))`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 12 | <code>b=z.read(sql);assert b'COALESCE(@RACENEXT1A_INTEGRATION_VERIFIED,0)'in b</code> | 确认变量未设置时取0；不等于1就SIGNAL拒绝，这是冻结ZIP的原始守卫。 |
| 13 | <code>dst=G/'data/customfixsql'/sql.split('/data/customfixsql/')[1];dst.write_bytes(b)</code> | 按原始字节存证据/原件；不偷偷改变BOM或换行来让哈希看似一致。 |
| 14 | <code>assert len(differences)==1 and differences[0]['path']==sql,differences</code> | 断言这行写出的条件必须成立：assert len(differences)==1 and differences[0]['path']==sql,differences；否则立刻停测，不能继续记通过。 |
| 15 | <code>(CP/'frozen_archive_audit.json').write_text(json.dumps({'files':len([n for n in z.namelist()if not n.endswith('/')]),'unpacked_differences':differences,'action':'Published SQL restored from immutable original ZIP, default integration confirmation remains 0. Unpacked directory was not changed. No SQL executed.','archive_sha256':sha(Path(str(P)+'.zip').read_bytes())},ensure_ascii=False,indent=2),encoding='utf-8')</code> | 将报告/夹具写入隔离工作目录，编码显式指定；不是覆盖运行客户端。 读取原始内容，哈希/归档按字节核对，避免换行归一掩盖变化。 |
| 16 | <code>print('Frozen ZIP audited; one unpacked SQL guard difference. Restored original ZIP SQL only in publication tree.')</code> | 把测试结果/计数输出为证据；前面的断言都没失败才能走到这里。 |
