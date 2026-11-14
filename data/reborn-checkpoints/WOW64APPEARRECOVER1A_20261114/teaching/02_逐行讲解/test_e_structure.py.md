# test_e_structure.py 逐行教学
此脚本只读；面向当前E归档或本机只读指纹，不替代游戏测试。

第1行：
```python
from pathlib import Path
```
导入标准库：文件路径、二进制读数、指纹或JSON。

第2行：
```python
import struct
```
导入标准库：文件路径、二进制读数、指纹或JSON。

第3行：
```python
p=Path(__file__).resolve().parents[1]/'05_证据/E输出'
```
建立当前步骤的值、资源或范围；脚本主课08解释整体目标。

第4行：
```python
for sex in ('male','female'):
```
循环覆盖声明范围；仅这些样本被检查。

第5行：
```python
 b=(p/(sex+'-after.skin')).read_bytes()
```
读取已有文件字节/MPQ条目，不执行覆盖操作。

第6行：
```python
 assert b[:4]==b'SKIN'
```
断言不变量；失败立即停止，不能用python -O跳过。

第7行：
```python
 n,o=struct.unpack_from('<II',b,28)
```
读取固定格式字段：<为小端，I为4字节、H为2字节。

第8行：
```python
 assert o+n*48<=len(b)
```
断言不变量；失败立即停止，不能用python -O跳过。

第9行：
```python
 for group in (3001,3002,3101,3102):
```
循环覆盖声明范围；仅这些样本被检查。

第10行：
```python
  rows=[struct.unpack_from('<10H',b,o+i*48) for i in range(n) if struct.unpack_from('<H',b,o+i*48)[0]==group]
```
读取固定格式字段：<为小端，I为4字节、H为2字节。

第11行：
```python
  assert len(rows)==1 and rows[0][5]>0 and rows[0][5]%3==0,(sex,group)
```
断言不变量；失败立即停止，不能用python -O跳过。

第12行：
```python
 b=(p/'selection-after.bin').read_bytes();n=struct.unpack_from('<I',b,8)[0]
```
读取固定格式字段：<为小端，I为4字节、H为2字节。

第13行：
```python
 for group in (30,31):
```
循环覆盖声明范围；仅这些样本被检查。

第14行：
```python
  rows=[struct.unpack_from('<7I',b,12+i*156) for i in range(n) if struct.unpack_from('<I',b,12+i*156+8)[0]==group]
```
读取固定格式字段：<为小端，I为4字节、H为2字节。

第15行：
```python
  assert rows and all(row[3]//100==group for row in rows)
```
断言不变量；失败立即停止，不能用python -O跳过。

第16行：
```python
print('PASS: E archived geometry and independent groups; NOT an in-game render test')
```
输出报告/案例结果，不能把输出当画面渲染证明。
