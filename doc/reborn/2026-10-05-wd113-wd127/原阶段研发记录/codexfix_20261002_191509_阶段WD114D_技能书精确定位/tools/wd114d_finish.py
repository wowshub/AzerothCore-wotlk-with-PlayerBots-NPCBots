from pathlib import Path
from datetime import datetime
import shutil,subprocess,json,hashlib,zipfile
W=Path('D:/000rebornWOW');R=W/'000RebornWOWHighForkPRO'
P=R/'000Ascendupdate/000Ascendupdate20261002'/('codexfix_20261002_'+datetime.now().strftime('%H%M%S')+'_阶段WD114D_技能书精确定位')
unfinished=[p for p in P.parent.glob('*_阶段WD114D_技能书精确定位') if not (p/'README_覆盖与测试说明.md').exists()]
if unfinished:P=sorted(unfinished)[-1]
P.mkdir(exist_ok=True)
rel=Path('Interface/AddOns/RebornWitchDoctorSkillBook/RebornWitchDoctorSkillBook.lua')
base=R/'beascendclient/newrebornWOWli20260929beAscend'/rel
text=base.read_text(encoding='utf-8-sig');assert 'WD114C' in text and 'WD114D' not in text
text=text.replace('return {repair=repair,scan=scan}','')+'\n'+(W/'wd114d_jump.lua').read_text(encoding='utf-8')
dst=P/'02_覆盖到客户端根目录'/rel;dst.parent.mkdir(parents=True,exist_ok=True);dst.write_text(text,encoding='utf-8')
back=P/'rollback'/rel;back.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(base,back)
for n in ['tools','checks']:(P/n).mkdir(exist_ok=True)
for n in ['wd114d_jump.lua','wd114d_test.lua','wd114d_finish.py']:shutil.copy2(W/n,P/'tools'/n)
lua=R/'beascendBuild/modules/mod-ale/src/lualib/lua/RelWithDebInfo/lua52_interpreter.exe'
r=subprocess.run([str(lua),str(W/'wd114d_test.lua'),str(W/'wd114d_jump.lua')],capture_output=True);assert r.returncode==0
(P/'checks/navigation.txt').write_bytes(r.stdout+r.stderr)
(P/'tools/syntax.lua').write_text('assert(loadfile(arg[1]))',encoding='utf-8')
r=subprocess.run([str(lua),str(P/'tools/syntax.lua'),str(dst)],capture_output=True)
# The standalone loadfile above must parse the cumulative client script.
assert r.returncode==0,(r.stdout,r.stderr)
doc='''# WD114D 技能书精确定位（待实机验证）

用户诊断已证明9003850—9003854均已学、原生槽存在、自定义列表存在，插件已加载。WD114C未解决用户看不到图标的问题，不能继续将其解释为列表遗漏。原生槽7/40/19不是渲染列表位置，不能直接据此断言第几页。

本包扩展已有/wdbook：按真实渲染列表中的SpellID确定分类、页码与格子，切换到该页，并用原有SpellButton更新路径刷新。保持原来的技能书与动作条机制，不建立替代技能面板、不改DBC/SQL、不授予技能或修改天赋。具体遮挡/翻页原因还没有实机证据，因此这是定位及刷新工具，不冒充已验证的底层显示修复。

## 安装使用

覆盖02_覆盖到客户端根目录中的Interface文件夹，游戏/reload。无需编译、无需SQL或MPQ操作；保留WD114A及已通过的WD114B。

先脱战并打开法术书，再分别执行：

```
/wdbook 假死
/wdbook 显性诅咒
/wdbook 强效混合
```

也可用9003853、9003852、9003854代替中文。一次定位一个技能。命令会输出实际分类/页/格及“按钮匹配”“可见”，并让目标保持高亮、其他技能变暗，沿用原UI搜索效果。清空搜索或正常浏览可恢复。若对应格子仍看不到，请截取命令结果与整个技能书，继续核查按钮纹理/父窗口遮挡。/wdbook不带参数仍输出完整诊断，并增加实际页码。

通用强效混合9003854与酿造强效调配9003621按不同ID定位，不合并，不修改两套数值或决定是否应叠加。假死、显性、强效的机制不因本包变更。

## 验证与回滚

Lua解释器测试覆盖跨页精确索引、中文别名、同名不同ID保留、战斗/未学/宠物页拦截；累计Lua语法检查通过。未进行游戏实机测试。
rollback/Interface覆盖回客户端并/reload可退回WD114C。
'''
(P/'README_覆盖与测试说明.md').write_text(doc,encoding='utf-8')
(P/'tutor.md').write_text('''# 技能书定位教学

本次沿用并读取项目integrate-wotlk-custom-class-ui-eligibility Skill，限定技能书显示项。当前FrameXML使用spellbookCustomRender数组，一页12项，所以页码为ceil(index/12)，格子为(index-1)%12+1。原生槽编号与排序后的数组位置不同，不能混用。

locate按SpellID查找，不按名称模糊匹配，避免同名等级混淆。命令确认巫医、已学、脱战、普通法术页后重建列表，再清除旧搜索，设置目标ID、页码并调用原分类切换与按钮更新。它不触碰施法授权和保存数据。随后核对目标SpellButton.data与IsShown，为后续遮挡/纹理检查提供证据。

之前最高等级列表遗漏是假说，新的用户输出没有支持此假说，已撤销其作为当前根因的判断。当前只完成定位刷新工具，未证明底层显示问题已解决。原本/W D114C防漏逻辑保留但现有项不重复补入。测试只验证可执行Lua和导航边界；需要实际游戏确认。
'''.replace('/W D114C','WD114C'),encoding='utf-8')
note=f'''\n\n## 2026-10-02 WD114D 精确定位（候选）
用户截图五ID原生槽及列表均存在、插件已加载，WD114C漏项假说未命中；当前尚未定位实际不可见原因。新增/wdbook中文名或ID按实际渲染列表跳转页格并检查按钮data/可见性。Lua导航边界和累计语法通过，未部署未实机。不修改机制数据、不宣称图标问题已修复。
[说明]({P.as_posix()}/README_覆盖与测试说明.md)
'''
for n in ['memory.md','phaseFixForNewChat.md']:(P/n).write_text(note,encoding='utf-8')
for n in ['updateMemory.md','refResourceAscend.md','beascendskills/skillsAscend.md','beascendtutor/tutorsAscend.md']:
 with (R/n).open('a',encoding='utf-8') as f:f.write(note)
(P/'checks/hashes.json').write_text(json.dumps({str(f.relative_to(P)):hashlib.sha256(f.read_bytes()).hexdigest() for f in P.rglob('*') if f.is_file()},ensure_ascii=False,indent=2),encoding='utf-8')
z=P.with_suffix('.zip')
with zipfile.ZipFile(z,'w',zipfile.ZIP_DEFLATED) as a:
 for f in P.rglob('*'):
  if f.is_file():a.write(f,str(f.relative_to(P)))
with zipfile.ZipFile(z) as a:assert a.testzip() is None
print(z)
