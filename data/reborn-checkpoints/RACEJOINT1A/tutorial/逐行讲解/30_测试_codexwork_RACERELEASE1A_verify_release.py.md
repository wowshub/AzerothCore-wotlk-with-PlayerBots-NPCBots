# 测试_codexwork_RACERELEASE1A_verify_release.py：逐行讲解
实际验证代码；原样归档供学习。私有路径/环境必须先核对，不能运行到生产库或覆盖运行客户端。
来源：`D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261107\codexwork_RACERELEASE1A\verify_release.py`。以下行号是所附原件的真实行号；空行/注释也保留。
## 函数和接口先读表
| 名称 | 在这份文件中的作用 |
|---|---|
| `LoadRaces` | 从当前DBC装入种族，核共享位同阵营并打印启动容量信息 |
| `LearnDefaultSkills` | 学基础技能；这一步位于出生物品之前，决定装备能否直接穿上 |
| `check` | 断言结果必须成立，并累积一条检查；失败立即停止 |
| `decode` | 读取WDBC头和行区；检查文件长度以免写出损坏表 |
| `block` | 按花括号深度截取实际函数/代码块，用于比较或实际夹具执行 |
| `run` | 在专用测试库执行SQL并检查预期成功/失败，绝不是生产执行器 |

## 原代码
```python
from pathlib import Path
import json,hashlib,subprocess,re
W=Path(__file__).resolve().parent;C=json.loads((W/'context.json').read_text(encoding='utf-8'));R=Path(C['project']);G=Path(C['git']);P=Path(C['package']);CP=Path(C['checkpoint'])
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
checks=[]
def check(v,s):
 assert v,s
 checks.append(s)
def norm(p):return p.read_text(encoding='utf-8-sig')
def block(s,key):
 a=s.index(key);b=s.index('{',a);depth=1;e=b+1
 while depth:
  if s[e]=='{':depth+=1
  if s[e]=='}':depth-=1
  e+=1
 return s[a:e]
core=P/'C_核心前置_联合增量/交付/01_覆盖到源代码根目录'
for rel,key in [('src/server/shared/SharedDefines.h',n)for n in ['inline constexpr bool IsRaceMaskAlias','inline constexpr bool IsRaceMaskable','inline constexpr uint32 GetRaceMaskForRace','inline constexpr uint8 GetRaceAliasTemplateRace','inline constexpr bool IsWarriorOnlyNewRace','inline constexpr bool IsFirstCoaPostCreationRace','inline constexpr uint32 GetFirstCoaParentMask','inline constexpr bool IsFirstCoaLanguageSkill','inline constexpr bool IsFirstCoaSkillMaskAllowed','inline constexpr uint32 GetReputationRaceMaskForRace']]+[
 ('src/server/game/Entities/Player/Player.cpp','bool IsSkillLineAbilityRaceAllowedForPlayer'),
 ('src/server/game/Entities/Player/Player.cpp','void Player::LearnDefaultSkills()'),
 ('src/server/game/DataStores/DBCStores.cpp','SkillRaceClassInfoEntry const* GetSkillRaceClassInfo'),
 ('src/server/game/Entities/Player/RaceMgr.cpp','void RaceMgr::LoadRaces()')]:
 check(block(norm(G/rel),key)==block(norm(core/rel),key),'tested function identical: '+key)
diff=subprocess.check_output(['git','-C',str(G),'diff','--','src/server'],stderr=subprocess.DEVNULL).decode('utf-8')
check(not any(x in '\n'.join(l for l in diff.splitlines()if l.startswith('+')and not l.startswith('+++'))for x in ['CLASS_WITCH_HUNTER','WHBASE1','WDCRACE1']),'no unrelated class changes in core delta')
for x in C['core']:
 check(sha(G/x['path'])==x['release_output'],'prepared source hash '+x['path'])
installed=[]
live=R/'beascendserver/wowshub_playerbot_npcbot_newrace20261107Ascend'
for m in json.loads((P/'checks/input_output_manifest.json').read_text(encoding='utf-8')):
 if m['component']=='A_服务端_Codex' and m['relative'].startswith('03_覆盖到服务端根目录/Data/'):
  f=live/Path(m['relative']).relative_to('03_覆盖到服务端根目录')
  installed.append({'path':str(f),'present':f.exists(),'matches_tested':f.exists()and sha(f)==m['output'],'actual':sha(f)if f.exists()else None,'expected':m['output']})
for f in core.rglob('*'):
 if f.is_file():
  livef=R/'beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots'/f.relative_to(core)
  installed.append({'path':str(livef),'present':livef.exists(),'matches_tested':livef.exists()and norm(livef)==norm(f),'actual':sha(livef)if livef.exists()else None,'expected':sha(f)})
(CP/'release_verification.json').write_text(json.dumps({'checks':checks,'count':len(checks),'installed_snapshot':installed,'scope':'Function equivalence and scoped delta checks. Prior frozen candidate full-build evidence is separate; formal merged tree full link not rerun.'},ensure_ascii=False,indent=2),encoding='utf-8')
# Syntax check only: G core/deps headers, existing PB headers as a supplemental include.
daily=R/'beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots'
rsp=(R/'000Ascendupdate/000Ascendupdate20261103/codexwork_RACEFLOW1A/core2.rsp').read_text(encoding='utf-16').replace(str(daily),str(G))
lines=[]
for l in rsp.splitlines():
 if l.startswith('/I"'):
  path=Path(l[3:-1])
  if not path.exists():l=l.replace(str(G),str(daily))
 lines.append(l)
(W/'release_core.rsp').write_text('\n'.join(lines),encoding='utf-8')
cmd=['@echo off','call D:\\soft\\vs2022\\enterprise\\VC\\Auxiliary\\Build\\vcvars64.bat >nul','cd /d '+str(W)]
for x in C['core']:
 if x['path'].endswith('.cpp'):
  cmd+=['cl @release_core.rsp "'+str(G/x['path'])+'"','if errorlevel 1 exit /b 1']
cmd+=['exit /b 0'];(W/'verify_syntax.cmd').write_bytes(('\r\n'.join(cmd)+'\r\n').encode('ascii'))
q=subprocess.run(['cmd.exe','/d','/c',str(W/'verify_syntax.cmd')],capture_output=True);(W/'release_syntax.log').write_bytes(q.stdout+q.stderr)
(CP/'release_syntax_result.json').write_text(json.dumps({'exit_code':q.returncode,'command':str(W/'verify_syntax.cmd'),'scope':'Five scoped core cpp MSVC /Zs syntax only; not full build or engine test.'},indent=2),encoding='utf-8')
print('Semantic checks',len(checks),'installed',sum(x['matches_tested']for x in installed),'/',len(installed),'syntax exit',q.returncode)
if q.returncode:print((q.stdout+q.stderr).decode('utf-8',errors='replace')[-5000:])
assert q.returncode==0
```

## 一行一行读
| 原件行号 | 代码 | 大白话解释 |
|---:|---|---|
| 1 | <code>from pathlib import Path</code> | 导入此行列出的Python库/对象，供路径、JSON、进程或二进制处理使用。 |
| 2 | <code>import json,hashlib,subprocess,re</code> | 导入此行列出的Python库/对象，供路径、JSON、进程或二进制处理使用。 |
| 3 | <code>W=Path(__file__).resolve().parent;C=json.loads((W/'context.json').read_text(encoding='utf-8'));R=Path(C['project']);G=Path(C['git']);P=Path(C['package']);CP=Path(C['checkpoint'])</code> | 以指定编码读源码/报告，再做结构分析；读文本不是启动服务器。 只对指定发布工作树执行Git核对；正式发布白名单，不包含日常未知修改。 |
| 4 | <code>sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()</code> | 计算精确文件指纹；它证明字节相同，不证明玩法正确。 读取原始内容，哈希/归档按字节核对，避免换行归一掩盖变化。 |
| 5 | <code>checks=[]</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`checks=[]`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 6 | <code>def check(v,s):</code> | 定义/进入函数：断言结果必须成立，并累积一条检查；失败立即停止。 |
| 7 | <code> assert v,s</code> | 断言这行写出的条件必须成立：assert v,s；否则立刻停测，不能继续记通过。 |
| 8 | <code> checks.append(s)</code> | 此行属于“def check(v,s):”：`checks.append(s)`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 9 | <code>def norm(p):return p.read_text(encoding='utf-8-sig')</code> | 以指定编码读源码/报告，再做结构分析；读文本不是启动服务器。 |
| 10 | <code>def block(s,key):</code> | 定义/进入函数：按花括号深度截取实际函数/代码块，用于比较或实际夹具执行。 |
| 11 | <code> a=s.index(key);b=s.index('{',a);depth=1;e=b+1</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`a=s.index(key);b=s.index('{',a);depth=1;e=b+1`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 12 | <code> while depth:</code> | 循环：while depth；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 13 | <code>  if s[e]=='{':depth+=1</code> | 条件分支：只有`if s[e]=='`成立才走随后分支；不满足进入else/跳过。 |
| 14 | <code>  if s[e]=='}':depth-=1</code> | 条件分支：只有`if s[e]=='}':depth-=1`成立才走随后分支；不满足进入else/跳过。 |
| 15 | <code>  e+=1</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`e+=1`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 16 | <code> return s[a:e]</code> | 返回表达式`s[a:e]`的计算结果给调用者；此处不再执行函数后面的语句。 |
| 17 | <code>core=P/'C_核心前置_联合增量/交付/01_覆盖到源代码根目录'</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`core=P/'C_核心前置_联合增量/交付/01_覆盖到源代码根目录'`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 18 | <code>for rel,key in [('src/server/shared/SharedDefines.h',n)for n in ['inline constexpr bool IsRaceMaskAlias','inline constexpr bool IsRaceMaskable','inline constexpr uint32 GetRaceMaskForRace','inline constexpr uint8 GetRaceAliasTemplateRace','inline constexpr bool IsWarriorOnlyNewRace','inline constexpr bool IsFirstCoaPostCreationRace','inline constexpr uint32 GetFirstCoaParentMask','inline constexpr bool IsFirstCoaLanguageSkill','inline constexpr bool IsFirstCoaSkillMaskAllowed','inline constexpr uint32 GetReputationRaceMaskForRace']]+[</code> | 循环：for rel,key in [('src/server/shared/SharedDefines.h',n)for n in ['inline constexpr bool IsRaceMaskAlias','inline constexpr bool IsRaceMaskable','inline constexpr uint32 GetRaceMaskForRace','inline constexpr uint8 GetRaceAliasTemplateRace','inline constexpr bool IsWarriorOnlyNewRace','inline constexpr bool IsFirstCoaPostCreationRace','inline constexpr uint32 GetFirstCoaParentMask','inline constexpr bool IsFirstCoaLanguageSkill','inline constexpr bool IsFirstCoaSkillMaskAllowed','inline constexpr uint32 GetReputationRaceMaskForRace']]+[；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 19 | <code> ('src/server/game/Entities/Player/Player.cpp','bool IsSkillLineAbilityRaceAllowedForPlayer'),</code> | 此行属于“def block(s,key):”：`('src/server/game/Entities/Player/Player.cpp','bool IsSkillLineAbilityRaceAllowedForPlayer'),`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 20 | <code> ('src/server/game/Entities/Player/Player.cpp','void Player::LearnDefaultSkills()'),</code> | 调用LearnDefaultSkills（学基础技能；这一步位于出生物品之前，决定装备能否直接穿上）；此行参数来自当前上下文。 |
| 21 | <code> ('src/server/game/DataStores/DBCStores.cpp','SkillRaceClassInfoEntry const* GetSkillRaceClassInfo'),</code> | 此行属于“def block(s,key):”：`('src/server/game/DataStores/DBCStores.cpp','SkillRaceClassInfoEntry const* GetSkillRaceClassInfo'),`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 22 | <code> ('src/server/game/Entities/Player/RaceMgr.cpp','void RaceMgr::LoadRaces()')]:</code> | 调用LoadRaces（从当前DBC装入种族，核共享位同阵营并打印启动容量信息）；此行参数来自当前上下文。 |
| 23 | <code> check(block(norm(G/rel),key)==block(norm(core/rel),key),'tested function identical: '+key)</code> | 调用check（断言结果必须成立，并累积一条检查；失败立即停止）、block（按花括号深度截取实际函数/代码块，用于比较或实际夹具执行）；此行参数来自当前上下文。 |
| 24 | <code>diff=subprocess.check_output(['git','-C',str(G),'diff','--','src/server'],stderr=subprocess.DEVNULL).decode('utf-8')</code> | 只对指定发布工作树执行Git核对；正式发布白名单，不包含日常未知修改。 |
| 25 | <code>check(not any(x in '\n'.join(l for l in diff.splitlines()if l.startswith('+')and not l.startswith('+++'))for x in ['CLASS_WITCH_HUNTER','WHBASE1','WDCRACE1']),'no unrelated class changes in core delta')</code> | 调用check（断言结果必须成立，并累积一条检查；失败立即停止）；此行参数来自当前上下文。 |
| 26 | <code>for x in C['core']:</code> | 循环：for x in C['core']；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 27 | <code> check(sha(G/x['path'])==x['release_output'],'prepared source hash '+x['path'])</code> | 调用check（断言结果必须成立，并累积一条检查；失败立即停止）；此行参数来自当前上下文。 |
| 28 | <code>installed=[]</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`installed=[]`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 29 | <code>live=R/'beascendserver/wowshub_playerbot_npcbot_newrace20261107Ascend'</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`live=R/'beascendserver/wowshub_playerbot_npcbot_newrace20261107Ascend'`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 30 | <code>for m in json.loads((P/'checks/input_output_manifest.json').read_text(encoding='utf-8')):</code> | 以指定编码读源码/报告，再做结构分析；读文本不是启动服务器。 |
| 31 | <code> if m['component']=='A_服务端_Codex' and m['relative'].startswith('03_覆盖到服务端根目录/Data/'):</code> | 条件分支：只有`if m['component']=='A_服务端_Codex' and m['relative'].startswith('03_覆盖到服务端根目录/Data/'):`成立才走随后分支；不满足进入else/跳过。 |
| 32 | <code>  f=live/Path(m['relative']).relative_to('03_覆盖到服务端根目录')</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`f=live/Path(m['relative']).relative_to('03_覆盖到服务端根目录')`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 33 | <code>  installed.append({'path':str(f),'present':f.exists(),'matches_tested':f.exists()and sha(f)==m['output'],'actual':sha(f)if f.exists()else None,'expected':m['output']})</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`installed.append({'path':str(f),'present':f.exists(),'matches_tested':f.exists()and sha(f)==m['output'],'actual':sha(f)if f.exists()else None,'expected':m['output']})`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 34 | <code>for f in core.rglob('*'):</code> | 循环：for f in core.rglob('*')；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 35 | <code> if f.is_file():</code> | 条件分支：只有`if f.is_file():`成立才走随后分支；不满足进入else/跳过。 |
| 36 | <code>  livef=R/'beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots'/f.relative_to(core)</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`livef=R/'beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots'/f.relative_to(core)`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 37 | <code>  installed.append({'path':str(livef),'present':livef.exists(),'matches_tested':livef.exists()and norm(livef)==norm(f),'actual':sha(livef)if livef.exists()else None,'expected':sha(f)})</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`installed.append({'path':str(livef),'present':livef.exists(),'matches_tested':livef.exists()and norm(livef)==norm(f),'actual':sha(livef)if livef.exists()else None,'expected':sha(f)})`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 38 | <code>(CP/'release_verification.json').write_text(json.dumps({'checks':checks,'count':len(checks),'installed_snapshot':installed,'scope':'Function equivalence and scoped delta checks. Prior frozen candidate full-build evidence is separate; formal merged tree full link not rerun.'},ensure_ascii=False,indent=2),encoding='utf-8')</code> | 将报告/夹具写入隔离工作目录，编码显式指定；不是覆盖运行客户端。 |
| 39 | <code># Syntax check only: G core/deps headers, existing PB headers as a supplemental include.</code> | 说明注释：Syntax check only: G core/deps headers, existing PB headers as a supplemental include.；它不执行，实际条件仍以相邻代码为准。 |
| 40 | <code>daily=R/'beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots'</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`daily=R/'beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots'`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 41 | <code>rsp=(R/'000Ascendupdate/000Ascendupdate20261103/codexwork_RACEFLOW1A/core2.rsp').read_text(encoding='utf-16').replace(str(daily),str(G))</code> | 以指定编码读源码/报告，再做结构分析；读文本不是启动服务器。 |
| 42 | <code>lines=[]</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`lines=[]`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 43 | <code>for l in rsp.splitlines():</code> | 循环：for l in rsp.splitlines()；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 44 | <code> if l.startswith('/I"'):</code> | 条件分支：只有`if l.startswith('/I"'):`成立才走随后分支；不满足进入else/跳过。 |
| 45 | <code>  path=Path(l[3:-1])</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`path=Path(l[3:-1])`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 46 | <code>  if not path.exists():l=l.replace(str(G),str(daily))</code> | 条件分支：只有`if not path.exists():l=l.replace(str(G),str(daily))`成立才走随后分支；不满足进入else/跳过。 |
| 47 | <code> lines.append(l)</code> | 此行属于“def block(s,key):”：`lines.append(l)`。按相邻作用域顺序执行；运算符、类型和API含义见前面的函数阅读表，原样保留便于逐行与原件核对。 |
| 48 | <code>(W/'release_core.rsp').write_text('\n'.join(lines),encoding='utf-8')</code> | 将报告/夹具写入隔离工作目录，编码显式指定；不是覆盖运行客户端。 |
| 49 | <code>cmd=['@echo off','call D:\\soft\\vs2022\\enterprise\\VC\\Auxiliary\\Build\\vcvars64.bat &gt;nul','cd /d '+str(W)]</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`cmd=['@echo off','call D:\\soft\\vs2022\\enterprise\\VC\\Auxiliary\\Build\\vcvars64.bat >nul','cd /d '+str(W)]`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 50 | <code>for x in C['core']:</code> | 循环：for x in C['core']；逐项/反复核对，退出条件和continue用于限制处理范围。 |
| 51 | <code> if x['path'].endswith('.cpp'):</code> | 条件分支：只有`if x['path'].endswith('.cpp'):`成立才走随后分支；不满足进入else/跳过。 |
| 52 | <code>  cmd+=['cl @release_core.rsp "'+str(G/x['path'])+'"','if errorlevel 1 exit /b 1']</code> | 赋值或初始化：左侧保存右侧表达式的结果。此行是`cmd+=['cl @release_core.rsp "'+str(G/x['path'])+'"','if errorlevel 1 exit /b 1']`；字段/标志的具体含义见本文件函数说明和参数章节，测试替身值不等于真实游戏数据。 |
| 53 | <code>cmd+=['exit /b 0'];(W/'verify_syntax.cmd').write_bytes(('\r\n'.join(cmd)+'\r\n').encode('ascii'))</code> | 按原始字节存证据/原件；不偷偷改变BOM或换行来让哈希看似一致。 |
| 54 | <code>q=subprocess.run(['cmd.exe','/d','/c',str(W/'verify_syntax.cmd')],capture_output=True);(W/'release_syntax.log').write_bytes(q.stdout+q.stderr)</code> | 收集命令标准输出和错误到证据，不靠屏幕一闪而过判断成功。 按原始字节存证据/原件；不偷偷改变BOM或换行来让哈希看似一致。 |
| 55 | <code>(CP/'release_syntax_result.json').write_text(json.dumps({'exit_code':q.returncode,'command':str(W/'verify_syntax.cmd'),'scope':'Five scoped core cpp MSVC /Zs syntax only; not full build or engine test.'},indent=2),encoding='utf-8')</code> | 检查子进程真实退出码；0为成功，非0须读日志，不能只看是否生成过旧EXE。 将报告/夹具写入隔离工作目录，编码显式指定；不是覆盖运行客户端。 |
| 56 | <code>print('Semantic checks',len(checks),'installed',sum(x['matches_tested']for x in installed),'/',len(installed),'syntax exit',q.returncode)</code> | 检查子进程真实退出码；0为成功，非0须读日志，不能只看是否生成过旧EXE。 |
| 57 | <code>if q.returncode:print((q.stdout+q.stderr).decode('utf-8',errors='replace')[-5000:])</code> | 检查子进程真实退出码；0为成功，非0须读日志，不能只看是否生成过旧EXE。 |
| 58 | <code>assert q.returncode==0</code> | 检查子进程真实退出码；0为成功，非0须读日志，不能只看是否生成过旧EXE。 |
