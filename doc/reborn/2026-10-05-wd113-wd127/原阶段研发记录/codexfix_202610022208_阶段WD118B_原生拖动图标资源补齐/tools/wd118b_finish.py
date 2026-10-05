from pathlib import Path
import hashlib,json,struct,zipfile,shutil
from wd19_common import dbc
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');P=Path(Path('wd118b_path.txt').read_text(encoding='utf8'));B=Path(Path('wd118_path.txt').read_text(encoding='utf8'))
def put(n,s):
 f=P/n;f.parent.mkdir(parents=True,exist_ok=True);f.write_bytes(s if isinstance(s,bytes) else s.encode('utf8'))
rows,pool=dbc((B/'client_mpq输入_导入现有Patch-XA/DBFilesClient/SpellIcon.dbc').read_bytes());checks=[]
for i in range(910115,910120):
 path=pool[rows[i][1]:].split(b'\0')[0].decode();rel=path.replace('\\','/')+'.blp';raw=(B/'02_覆盖到客户端根目录'/rel).read_bytes()
 assert raw[:4] in [b'BLP1',b'BLP2'];w,h=struct.unpack_from('<II',raw,12);assert w==h and w in [32,64,128,256]
 put('client_mpq输入_导入现有Patch-XA/'+rel,raw);checks.append(dict(icon=i,path=rel,bytes=len(raw),width=w,height=h,sha256=hashlib.sha256(raw).hexdigest()))
scan=json.loads((P/'research/all_archive_scan.json').read_text(encoding='utf8'));assert not scan['errors'] and not scan['icon_hits']
put('checks.json',json.dumps(checks,ensure_ascii=False,indent=2))
readme='''# WD118B 原生鼠标拖动图标资源补齐

适用于WD115A、WD116A、WD117A及WD118A。它是图标资源小补丁，不是技能累计包，不要求先安装WD118A。

用户确认：假死技能书图标已变更，拖动能放进动作条，仅鼠标上的图标不可见。因此不改PickupSpell或技能授予机制。

## 安装（不编译、不执行SQL）

1. 完全退出游戏，备份当前Data/patch-XA.MPQ，备份放Data目录外。
2. 用MPQEditor打开当前patch-XA.MPQ，把包内 `client_mpq输入_导入现有Patch-XA` 的**内容**按路径导入，保留Interface开头的完整内部路径。
3. 不要把“client_mpq输入_导入现有Patch-XA”这个目录名本身导入MPQ，也不要只复制到磁盘插件目录。
4. 确认MPQ内包含 `Interface\\AddOns\\RebornWitchDoctorTalents\\Icons\\7e06e90aea7e069e.blp`，这是假死图标。完全重开客户端；仅/reload不足以验证原生资源加载。

本包仅新增5个BLP：假死、强效混合、沃金守望、灵魂行者、化蛇，保持原SpellIcon引用路径与原图片内容。WD115只引用其中两张，另外三张不会授予技能或改变天赋。没有Spell.dbc、SpellIcon.dbc、Lua、源码或SQL覆盖，不会把WD118的新数据退回WD115。之后安装WD116–118仍需保留这五个MPQ内部文件。

## 为什么这样修

此前图标仅随02插件目录交付。Lua界面能读取图标并显示，不能据此证明原生鼠标图标也从同一渠道加载。本次扫描当前客户端Data下全部MPQ：五个引用路径均缺失、无读取失败；而对应磁盘BLP存在。现有FrameXML拖动函数调用PickupSpell，用户又已确认能放入动作条，说明拾取链已工作。因此本补丁优先补齐原生归档资源，不伪造Lua鼠标图标。

这是资源缺口的定向修正，尚需实机确认鼠标显示恢复；不声称已经逆向验证客户端内部加载器。只核对本地已交付图标链，没有新增技能机制或宣称重新核对社区最新技能代码。

## 测试与回滚

重新进入后：从技能书拖动假死，看鼠标图标；放到空动作条，再从动作条拖动检查图标；取消拖动后正常施放，确认假死行为未改变。若仍透明，反馈是技能书和动作条两种来源都透明，还是只有一种。

离线已检查五个引用路径、BLP头和尺寸、SHA256、全MPQ缺项证据及ZIP完整性；未启动客户端测试。恢复安装前MPQ备份即可回滚本补丁，不需要数据库回退。
'''
put('README_安装与测试.md',readme);put('memory.md',readme)
put('tutor.md','''# 图标能显示但拖动透明，怎样排查

先把操作和绘图分开：技能能放入动作条，说明光标携带的技能数据正常；此时改拾取函数会扩大范围。下一步沿Spell9003853的IconID910115查SpellIcon字符串，得到7e06e90aea7e069e的完整资源路径。

磁盘插件目录和MPQ是两种资源入口。界面SetTexture能显示不等于原生鼠标路径必然可用。审计脚本读取归档而不改运行MPQ；扫描没有命中后，将原图按同一完整路径交给用户导入。不能只拖一张文件到MPQ根目录，因为原生引用含有Interface/AddOns/…目录。

构建代码用assert检查BLP标识和宽高，hashlib计算SHA256核对内容，zipfile检查交付压缩包。它没有重绘图片、改技能ID或替换DBC，因此兼容WD115至WD118，不会因图标修复回退游戏机制。五张图一并补齐，是修正同一交付缺口，不代表新增五项技能。

实机验收必须看技能书拖出、动作条拖出、放置、取消、重登。未收到用户确认前仅登记候选；成功后再将“原生图标需MPQ资源闭环”的适用范围补入永久技能资源追踪Skill与同名Tutor。
''')
put('phaseFixForNewChat.md','WD118B是仅5BLP的MPQ资源增量，不含DBC/Lua/C++/SQL。用户确认拖动能放动作条，只有光标图标不可见；原五图仅在插件磁盘目录，当前Data所有MPQ均缺这五条路径。补资源后待实机；WD115图标在书页可见已获确认，鼠标问题不能标通过。后续累计包必须同时携带02目录和MPQ图标资源。\n')
for name in ['wd118b_audit.py','wd118b_scan.py','wd118b_finish.py']:put('tools/'+name,Path(name).read_bytes())
manifest={f.relative_to(P).as_posix():hashlib.sha256(f.read_bytes()).hexdigest() for f in P.rglob('*') if f.is_file() and f.name!='SHA256.json'};put('SHA256.json',json.dumps(manifest,ensure_ascii=False,indent=2))
z=P.with_suffix('.zip');assert not z.exists()
with zipfile.ZipFile(z,'w',zipfile.ZIP_DEFLATED) as a:
 for name in list(manifest)+['SHA256.json']:a.write(P/name,name)
with zipfile.ZipFile(z) as a:assert a.testzip() is None
sha=hashlib.sha256(z.read_bytes()).hexdigest()
note=f'''\n\n## 2026-10-02 WD118B 原生拖动图标资源补齐（候选）
用户确认WD115假死书页图标修改可见，拖动可放动作条但鼠标图标透明。五个新增SpellIcon路径的BLP此前只在02插件目录交付，当前全MPQ扫描未命中。补齐原路径5BLP到MPQ输入；不改DBC/Lua/源码/SQL，兼容WD115–118，待实机确认光标。无机制新增，仅本地资源链审计。以后累计交付同时包含磁盘与MPQ资源；不能因界面能显示而省略原生入口验证。
使用trace-and-port-coa-spell-resources。五BLP头/尺寸/引用/哈希、归档扫描及ZIP完整性已查。说明：[WD118B]({P.as_posix()}/README_安装与测试.md)；教程：[tutor]({P.as_posix()}/tutor.md)。ZIP SHA256 `{sha}`。
'''
for rel in ['updateMemory.md','updateListAscend.md','tutorMemory.md','refResourceAscend.md','beascendskills/skillsAscend.md','beascendtutor/tutorsAscend.md','beascendskills/trace-and-port-coa-spell-resources/SKILL.md','beascendtutor/trace-and-port-coa-spell-resources/TUTOR.md']:
 with (R/rel).open('a',encoding='utf8') as f:f.write(note)
print(z);print(sha)
