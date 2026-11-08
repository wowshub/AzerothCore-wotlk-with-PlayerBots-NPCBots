# 测试_check_languages.py：逐行讲解
实际测试原件逐行；Python路径保持当时输入，不保证当前可直接执行。C++夹具是生产函数加API替身，不是完整游戏引擎。
来源：`D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261106\codexwork_RACEJOINT1A\check_languages.py`。以下行号是所附原件的真实行号；空行/注释也保留。

## 原代码
```python
from pathlib import Path
import json,struct,hashlib
W=Path(__file__).resolve().parent;R=W.parents[2];P=Path((W/'package_path.txt').read_text(encoding='utf-8'))
S=R/'beascendserver/wowshub_playerbot_npcbot_newrace20261107Ascend'
def rows(p):
 b=p.read_bytes();n,nf,rs,ss=struct.unpack_from('<4I',b,4);return [struct.unpack('<'+'I'*(rs//4),b[20+i*rs:20+(i+1)*rs]) for i in range(n)]
report=[]
for base in [S/'Data/dbc',S/'Data/dbc/zhCN',W/'client_inputs/Patch-XA.mpq/DBFilesClient']:
 skills=rows(base/'SkillRaceClassInfo.dbc');abilities=rows(base/'SkillLineAbility.dbc')
 def first(skill,race):
  mask=1<<((race-1)&31)
  return next((r for r in skills if r[1]==skill and (not r[3] or r[3]&1) and (not r[2] or (r[2]&mask and r[2]&(r[2]-1)))),None)
 for race,lang,spell in [(39,98,668),(49,109,669)]:
  r=first(lang,race);assert r is not None,(base,race,lang)
  ab=[a for a in abilities if a[2]==spell and a[1]==lang and (not a[4] or a[4]&1) and (not a[3] or a[3]&(a[3]-1) and a[3]&(1<<((race-1)&31)))];assert ab,(base,race,spell)
  report.append(dict(base=str(base),race=race,language_first_matching_row=list(r),spell_rows=[list(a) for a in ab]))
  for skill in [26,256,257,95,162,43 if race==39 else 44,413,414,415,433]:assert first(skill,race) is not None,(base,race,'basic',skill)
  # Single-bit Gnomish/Eredar grants cannot pass the actual core predicate.
  for a in abilities:
   if a[3] in [64,65536]:assert not (a[3]&(a[3]-1))
(P/'checks/language_eligibility.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
print('PASS server root, zhCN and client XA first-match languages and basic Warrior skills; no edits to these existing tables required')
```

## 一行一行读
| 原件行号 | 代码 | 大白话解释 |
|---:|---|---|
| 1 | <code>from pathlib import Path</code> | 导入此行列出的Python库/对象，供路径、JSON、进程或二进制处理使用。 |
| 2 | <code>import json,struct,hashlib</code> | 导入此行列出的Python库/对象，供路径、JSON、进程或二进制处理使用。 |
| 3 | <code>W=Path(__file__).resolve().parent;R=W.parents[2];P=Path((W/'package_path.txt').read_text(encoding='utf-8'))</code> | 以指定编码读源码/报告，再做结构分析；读文本不是启动服务器。 |
| 4 | <code>S=R/'beascendserver/wowshub_playerbot_npcbot_newrace20261107Ascend'</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`S=R/'beascendserver/wowshub_playerbot_npcbot_newrace20261107Ascend'`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 5 | <code>def rows(p):</code> | 此行属于“def rows(p):”：`def rows(p):`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 6 | <code> b=p.read_bytes();n,nf,rs,ss=struct.unpack_from('&lt;4I',b,4);return [struct.unpack('&lt;'+'I'*(rs//4),b[20+i*rs:20+(i+1)*rs]) for i in range(n)]</code> | 按明确二进制结构解WDBC头/行，防止字符串区或行宽错位。 读取原始内容，哈希/归档按字节核对，避免换行归一掩盖变化。 |
| 7 | <code>report=[]</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`report=[]`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 8 | <code>for base in [S/'Data/dbc',S/'Data/dbc/zhCN',W/'client_inputs/Patch-XA.mpq/DBFilesClient']:</code> | 循环：for base in [S/'Data/dbc',S/'Data/dbc/zhCN',W/'client_inputs/Patch-XA.mpq/DBFilesClient']；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 9 | <code> skills=rows(base/'SkillRaceClassInfo.dbc');abilities=rows(base/'SkillLineAbility.dbc')</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`skills=rows(base/'SkillRaceClassInfo.dbc');abilities=rows(base/'SkillLineAbility.dbc')`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 10 | <code> def first(skill,race):</code> | 此行属于“def first(skill,race):”：`def first(skill,race):`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 11 | <code>  mask=1&lt;&lt;((race-1)&amp;31)</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`mask=1<<((race-1)&31)`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 12 | <code>  return next((r for r in skills if r[1]==skill and (not r[3] or r[3]&amp;1) and (not r[2] or (r[2]&amp;mask and r[2]&amp;(r[2]-1)))),None)</code> | 返回表达式`next((r for r in skills if r[1]==skill and (not r[3] or r[3]&1) and (not r[2] or (r[2]&mask and r[2]&(r[2]-1)))),None)`的计算结果给调用者；此处不再执行函数后面的语句。 |
| 13 | <code> for race,lang,spell in [(39,98,668),(49,109,669)]:</code> | 循环：for race,lang,spell in [(39,98,668),(49,109,669)]；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 14 | <code>  r=first(lang,race);assert r is not None,(base,race,lang)</code> | 断言这行写出的条件必须成立：r=first(lang,race);assert r is not None,(base,race,lang)；否则立刻停测，不能继续记通过。 |
| 15 | <code>  ab=[a for a in abilities if a[2]==spell and a[1]==lang and (not a[4] or a[4]&amp;1) and (not a[3] or a[3]&amp;(a[3]-1) and a[3]&amp;(1&lt;&lt;((race-1)&amp;31)))];assert ab,(base,race,spell)</code> | 断言这行写出的条件必须成立：ab=[a for a in abilities if a[2]==spell and a[1]==lang and (not a[4] or a[4]&1) and (not a[3] or a[3]&(a[3]-1) and a[3]&(1<<((race-1)&31)))];assert ab,(base,race,spell)；否则立刻停测，不能继续记通过。 |
| 16 | <code>  report.append(dict(base=str(base),race=race,language_first_matching_row=list(r),spell_rows=[list(a) for a in ab]))</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`report.append(dict(base=str(base),race=race,language_first_matching_row=list(r),spell_rows=[list(a) for a in ab]))`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 17 | <code>  for skill in [26,256,257,95,162,43 if race==39 else 44,413,414,415,433]:assert first(skill,race) is not None,(base,race,'basic',skill)</code> | 循环：for skill in [26,256,257,95,162,43 if race==39 else 44,413,414,415,433]:assert first(skill,race) is not None,(base,race,'basic',skill)；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 18 | <code>  # Single-bit Gnomish/Eredar grants cannot pass the actual core predicate.</code> | 说明注释：Single-bit Gnomish/Eredar grants cannot pass the actual core predicate.；它不执行，实际条件仍以相邻代码为准。 |
| 19 | <code>  for a in abilities:</code> | 循环：for a in abilities；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 20 | <code>   if a[3] in [64,65536]:assert not (a[3]&amp;(a[3]-1))</code> | 条件分支：只有`if a[3] in [64,65536]:assert not (a[3]&(a[3]-1))`成立才走随后分支；不满足进入else/跳过。 |
| 21 | <code>(P/'checks/language_eligibility.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')</code> | 将报告/夹具写入隔离工作目录，编码显式指定；不是覆盖运行客户端。 |
| 22 | <code>print('PASS server root, zhCN and client XA first-match languages and basic Warrior skills; no edits to these existing tables required')</code> | 把测试结果/计数输出为证据；前面的断言都没失败才能走到这里。 |
