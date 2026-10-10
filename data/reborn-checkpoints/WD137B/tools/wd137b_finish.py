from pathlib import Path
import json,hashlib,zipfile,subprocess,base64
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');P=Path(Path('wd137b_path.txt').read_text().strip())
def put(n,s):
 f=P/n;f.parent.mkdir(parents=True,exist_ok=True);f.write_text(s,encoding='utf8')
head='bf9a292ba8a55a7315957434e1fed1ec1d3472d9'
for name in ['Completion','Brewing']:
 j=json.loads(subprocess.check_output(['gh','api',f'repos/jealous-sound/azerothcore-wotlk-coa/contents/src/server/coa/AscensionWitchDoctor{name}.cpp?ref={head}']))
 put('research/'+name+'.cpp',base64.b64decode(j['content']).decode())
readme='''# WD137B：瓶中之灵移动施法客户端修正（待复测）

这是已安装WD137A后的客户端增量包。前提：服务端已经编译并运行WD137A。

## 为什么上一包仍会打断
上一包添加了服务端调酒大师许可，却漏掉客户端瓶中之灵八个等级的移动取消标记。当前Patch-XA与patch-ZA的Spell.dbc完全相同，八个等级InterruptFlags都是15；服务器允许，并不能阻止客户端自行取消。这里属于有数据和历史WD96依据的诊断，尚未抓取实际取消包，最终以你的复测为准。

## 安装：下面两种选一种
先完全退出客户端，备份现用文件（备份放Data之外）。
1. 简单方法：把“02_覆盖到客户端根目录”内的Data/patch-ZA.mpq覆盖客户端同名文件。这个ZA保留当前包其余14份资源，只更新Spell.dbc。
2. 自己合并：把“client_mpq输入_导入现有Patch-XA”中的DBFilesClient/Spell.dbc导入你的Patch-XA。如果保留patch-ZA，也要在ZA内更新同一份Spell.dbc，避免旧ZA遮住新XA。不要为了此项删除含其他累计功能的ZA。

启动客户端重新测试；单独/reload不会重新加载DBC。本批不需要重新编译、不需要SQL、不改服务端Data。千万不要把这个客户端Spell.dbc复制到服务端！

## 请验证这几步
1. 无调酒大师状态：站着能读瓶中之灵；开始移动应中断；一直跑时不应成功施法。
2. 开启调酒大师（9003957）后，在10秒内边跑边读瓶中之灵；前后移动、横移均应完成。
3. 站着起读后再移动，也应完成；手动Esc/停止施法仍能取消。
4. 调酒大师快结束时读条并保持移动：状态结束后应重新中断；再次移动读条应失败。
5. 其他普通读条技能仍按原规则移动中断；瓶中之灵治疗、消耗仍正常。

没有状态时，客户端可能短暂出现读条后被服务端拒绝，这是本地3.3.5适配边界，不代表无条件移动施法。

## 校验和回滚
仅9003460—9003467八行的字段31由15变14；其他所有字段、记录、字符串池不变。15份MPQ资源已读回逐字节核对。现用Spell.cpp、SpellInfo.cpp、Brewing137.inc与WD137A候选一致；服务端八行仍为15。
这里只做数据与源码路径核对，没有启动游戏验证，未宣布通过，也未commit/tag/release。
回滚：恢复rollback/patch-ZA.mpq；如果手工合并过XA，也把rollback/Spell.dbc恢复到你修改过的客户端MPQ。
'''
put('README_覆盖与测试说明.md',readme)
put('tutor.md','''# 大白话：移动施法有两道门
客户端先判断是否允许继续读条，服务端再判断这次施法是否合法。WD137A只打开了服务端的条件门，客户端的门还关着。
InterruptFlags是多个开关加在一起的数字。15二进制是1111，最低位1代表移动打断。只清最低位，结果14（1110），其他打断规则保持。
本包只改客户端八个瓶中之灵等级。服务端仍保留15，在起读Spell::prepare和读条Spell::update两处，只有本人已学调酒大师且本人光环有效时才放行；光环过期就不再放行。
CheckCast另一处移动检测针对自动射击/坐姿限制，瓶中之灵不是自动射击且AuraInterruptFlags为0，不需要无差别改掉。它的ChannelInterruptFlags为0，也不是引导技能。本批不吞掉取消施法消息，Esc仍可正常使用。
这是之前WD96已使用的双端适配方式。WD137A的条件组合测试只证明许可函数，没有验证客户端数据，因而漏掉了这一层。新检查逐字段对比双端，并明确要求客户端重启和负向实机测试。
脚本用Python struct解析WDBC头和232字段记录（按实际头读取字段数），复制原字符串池，只改指定八行；用StormLib打包并逐字节读回，防止误带旧DBC。涉及位运算、客户端与服务器权威分工、最小差异和回归验证等知识。
''')
put('memory.md',f'''# WD137B诊断记录
上游复核2026-10-08固定提交{head}，读取Completion/Brewing；Issue2869 closed，PR4753已合并e17d84e40c219569f54f90945b99be6736255a57。源码存research，不把关闭状态当本地验收。
采用项目trace-and-port-coa-spell-resources Skill；重新读取WD96A/memory.md（原3.3.5客户端清movement位、服务端条件限制），本次修正遗漏客户端八rank标志。当前XA与ZA的Spell完全相同，使用当前ZA资源并集保留14份未改文件；服务端独立DBC不交付、不修改。
源码比对只读，不触及Claude/DC/playerbots工作树。WD137A用户报告移动施法失败；此前离线测试覆盖不足，不登记通过。本包等待新复测，发布仍待用户确认。
''')
put('phaseFixForNewChat.md','''# 交接
WD137A未验收：用户报告移动仍打断。WD137B仅客户端八rank InterruptFlags15→14，服务器已安装源码与137A一致，无新编译/SQL。客户端实际XA/ZA两份Spell一致，包含9003957。安装重启后等待用户测试才允许137 commit/push/tag/release。
风暴之眼地面首次进入异常、/reload恢复仍在排查，尚无可靠根因和修复结论。当前20261008目录没有启用名为d3d9.dll的文件，只有旧备份，不能直接归咎LIGHT渲染器。需确认发生问题的客户端与reload含义。后续技能按相关依赖组合批量交付，不单技能默认拆包。
''')
put('research/upstream.txt',f'commit {head}\nhttps://github.com/jealous-sound/azerothcore-wotlk-coa/issues/2869\nhttps://github.com/jealous-sound/azerothcore-wotlk-coa/pull/4753\n')
manifest={str(f.relative_to(P)):hashlib.sha256(f.read_bytes()).hexdigest() for f in P.rglob('*') if f.is_file() and 'mpq_payload' not in f.parts}
put('manifest.json',json.dumps(manifest,ensure_ascii=False,indent=2))
z=P.with_suffix('.zip');assert not z.exists()
with zipfile.ZipFile(z,'w',zipfile.ZIP_DEFLATED) as out:
 for f in P.rglob('*'):
  if f.is_file() and 'mpq_payload' not in f.parts:out.write(f,f.relative_to(P))
with zipfile.ZipFile(z) as out:assert out.testzip() is None
digest=hashlib.sha256(z.read_bytes()).hexdigest()
record=f'\n\n## 2026-10-08 WD137B 客户端移动取消修正（候选待测）\nWD137A用户反馈移动仍中断，未验收。当前客户端瓶中之灵八rank移动标志15漏改；本包仅客户端改14，服务端15及调酒大师条件许可保持。读取trace-and-port-coa-spell-resources和WD96A历史双端方法。八字段差异、其他行/字符串池不变、15MPQ资源读回通过；不代表实机通过。无需SQL或重新编译，需退出客户端再覆盖重启。未提交发布；风暴之眼异常仍待定位。\n包：{z}\nSHA256：{digest}\n'
for name in ['updateMemory.md','tutorMemory.md','refResourceAscend.md']:
 with (R/name).open('a',encoding='utf8') as f:f.write(record)
print(z);print(digest)
