from pathlib import Path
from datetime import datetime
from zoneinfo import ZoneInfo
import hashlib,json,shutil,subprocess,zipfile
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');W=Path('D:/000rebornWOW')
# Explicit client date for archive day; no dependency on host timezone.
stamp='20261002_'+datetime.now().strftime('%H%M%S')
P=R/'000Ascendupdate/000Ascendupdate20261002'/('codexfix_'+stamp+'_阶段WD114C_已学技能书条目补漏')
P.mkdir(exist_ok=False)
rel=Path('Interface/AddOns/RebornWitchDoctorSkillBook/RebornWitchDoctorSkillBook.lua')
base=R/'beascendclient/newrebornWOWli20260929beAscend'/rel
dst=P/'02_覆盖到客户端根目录'/rel;dst.parent.mkdir(parents=True)
dst.write_text(base.read_text(encoding='utf-8-sig')+'\n'+(W/'wd114c_book.lua').read_text(encoding='utf-8'),encoding='utf-8')
back=P/'rollback'/rel;back.parent.mkdir(parents=True);shutil.copy2(base,back)
for name in ['checks','tools','research']:(P/name).mkdir()
for name in ['wd114c_book.lua','wd114c_test.lua','wd114c_audit.py','wd114c_more.py','wd114c_scanui.py','wd114c_finish.py']:shutil.copy2(W/name,P/'tools'/name)
shutil.copy2(W/'wd114c_audit.json',P/'research/archive_skilllines.json')
shutil.copy2(W/'wd114c_ui/patch-enUS-5.mpq.lua',P/'research/SpellBookFrame_current.lua')
lua=R/'beascendBuild/modules/mod-ale/src/lualib/lua/RelWithDebInfo/lua52_interpreter.exe'
test=subprocess.run([str(lua),str(W/'wd114c_test.lua'),str(dst)],capture_output=True)
assert test.returncode==0,(test.stdout,test.stderr)
(P/'checks/lua.txt').write_bytes(test.stdout+test.stderr)
readme='''# WD114C 已学技能书条目补漏（候选，待游戏验收）

基于当前 WD114A + WD114B。用户确认9003852/9003853/9003854已学，但技能书缺图标。本包不授予技能，不改变扣蓝、治疗、威胁或任何天赋/角色存档。

## 安装

把 `02_覆盖到客户端根目录` 内的 Interface 文件夹覆盖到实际游戏客户端根目录，再 `/reload`。只更换已有 RebornWitchDoctorSkillBook 插件的一份 Lua；该插件须启用。无需重新编译、无需SQL、无需MPQ或DBC操作。保留WD114B。

打开法术书，选择巫毒分类并翻到最后一页：五个编号9003850—9003854中，已学且此前漏掉的条目会补在该分类末尾；已有条目保留原位置。假死药剂可拖到动作条，冷却和施法仍用真实技能。通用强效混合9003854应显示4%/15%；酿造强效调配9003621仍为8%/30%，本补丁不合并两个节点或决定其叠加规则。

## 测试

1. 在含假死、显性诅咒、强效混合的已保存激活方案打开巫毒书页，查三个图标和提示。
2. 拖假死到动作条，正常施放与检查冷却。被动不需要主动施放。
3. 切换到没有这些天赋的方案，确认补入条目消失；再切回、/reload及重登检查恢复。
4. 勾选/取消“显示所有法术等级”，检查不会重复出现同一ID。
5. 保留洛阿强化和指定诅咒费用实时显示的既有测试；本包没有触碰NumericTooltip。

若仍缺失：在打开巫毒技能书后输入 `/wdbook`，发送输出。诊断列出每项已学状态、原生技能槽和自定义列表是否存在，可区分原生列表缺失与UI层遗漏。没有找到真实巫毒分类时不会强行塞入综合页。战斗中不刷新安全按钮，脱战后再查看。

## 已查明与边界

实际Patch-XA中的Spell和SkillLineAbility已经包含这五个ID。当前自定义FrameXML默认遍历最高等级技能槽，只有IsSpellKnown为true并不能保证进入渲染列表。缺少游戏运行时原生槽快照，尚未证明具体是哪层漏项；本包是在渲染列表入口增加小范围、按真实已学状态的补漏，不宣称已经修好客户端原生最高等级算法。
独立Lua解释器回归通过，未启动游戏、未部署、未编译。恢复旧版时把rollback/Interface覆盖回客户端并/reload。
'''
(P/'README_覆盖与测试说明.md').write_text(readme,encoding='utf-8')
tutor='''# 排错过程与实现教学

IsSpellKnown是“角色已学会”；Spell.dbc提供技能信息；SkillLineAbility提供分类；本客户端的FrameXML又通过最高等级槽映射生成spellbookCustomRender。四层必须区分。本次读取项目AGENTS、ruleAscend、refResourceAscend、skillsAscend与integrate-wotlk-custom-class-ui-eligibility/SKILL.md及其新增职业检查表，仅处理技能书/已学显示项。其他职业准入和职责不在本次范围。

只读读取当前Patch-XA的五条Spell与SkillLineAbility，排除本地记录不存在。读取当前enUS/patch-enUS-5.mpq的SpellBookFrame.lua：UpdateSpellRender默认使用GetKnownSlotFromHighestRankSlot，随后由SpellButton_UpdateButton设置实际SpellID、技能槽和安全按钮；客户端隐藏名单没有9003850—54。未获得用户进程原生槽结果，因此不能把最高等级转换认定为唯一根因。

补丁追加到已有诊断插件：scan用原生完整槽GetSpellTabInfo的offset/count枚举真实技能索引；repair只对五个固定ID且IsSpellKnown真、GetSpellInfo存在、当前列表缺失时追加。已经存在的ID不重复；找不到原生槽时仍使用此UI原本支持的按ID条目，并不捏造槽编号。分类优先使用该技能原生槽所属页，否则使用真实巫毒页；找不到分类就退出。列表计数同步，分页更新，动作按钮沿用现有按ID调用。

hooksecurefunc在原UI重建完成后追加，不替换全局GetSpellTabInfo/GetSpellLink或IsSpellKnown。仅巫医、普通法术书、非战斗状态执行；PET和其他职业退出。自身生成条目在技能不再已学时删除，原UI其他记录不随意清理。/wdbook输出原生槽与最终列表，供下轮精确判断。

tools含Lua与测试，checks含结果。覆盖真实Lua执行、已学/未学、原生槽有无、重复刷新、遗忘、旧酿造同名技能保留、战斗、其他职业、宠物、无分类等边界。未进行游戏战斗/拖动验收。该项为本地UI兼容补漏，没有新增CoA战斗移植；沿用WD114A来源记录，不声称本次联网核对了最新上游。
'''
(P/'tutor.md').write_text(tutor,encoding='utf-8')
note=f'''\n\n## 2026-10-02 WD114C 已学技能书条目补漏（候选）
用户已确认三个IsSpellKnown为true。实读当前Patch-XA，五条Spell/分类存在；enUS自定义FrameXML由最高等级槽生成列表，无独立已学补漏。增量Lua按ID只补五条已学且列表遗漏的技能，保留真实槽、无槽时使用现有按ID条目；巫毒分类、分页同步、去重、脱战刷新；/wdbook输出定位信息。根因具体层级仍需实机诊断，不宣称原生算法已修复。Lua回归通过，未部署。洛阿强化/WD114B用户基本通过不受改动；显性费用实测、假死/强效、同名节点叠加仍待验收。
[安装]({P.as_posix()}/README_覆盖与测试说明.md) · [教学]({P.as_posix()}/tutor.md)
'''
(P/'memory.md').write_text(note,encoding='utf-8');(P/'phaseFixForNewChat.md').write_text(note,encoding='utf-8')
for name in ['updateMemory.md','refResourceAscend.md','beascendskills/skillsAscend.md','beascendtutor/tutorsAscend.md']:
 with (R/name).open('a',encoding='utf-8') as f:f.write(note)
hashes={str(f.relative_to(P)):hashlib.sha256(f.read_bytes()).hexdigest() for f in P.rglob('*') if f.is_file()}
(P/'checks/SHA256.json').write_text(json.dumps(hashes,ensure_ascii=False,indent=2),encoding='utf-8')
z=P.with_suffix('.zip')
with zipfile.ZipFile(z,'w',zipfile.ZIP_DEFLATED) as a:
 for f in P.rglob('*'):
  if f.is_file():a.write(f,str(f.relative_to(P)))
with zipfile.ZipFile(z) as a:assert a.testzip() is None
print(z)
