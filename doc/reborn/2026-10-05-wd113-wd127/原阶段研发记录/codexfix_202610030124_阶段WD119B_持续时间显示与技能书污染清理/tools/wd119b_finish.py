from pathlib import Path
import ast,subprocess,shutil,json,hashlib,zipfile
P=Path(Path('wd119b_path.txt').read_text().strip())
R=Path(r'D:\000rebornWOW\000RebornWOWHighForkPRO')
lua=R/'beascendBuild/modules/mod-ale/src/lualib/lua/RelWithDebInfo/lua52_interpreter.exe'
tree=ast.parse(Path('wd100_tooltip_test.py').read_text(encoding='utf-8-sig'))
h=next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='h' for t in n.targets))
h=h.replace('Hastened: 3 min','Cooldown (Hastened): 3 min')
h=h.replace('迅捷召唤：','冷却时间（迅捷召唤）：')
f=P/'tools/wd119b_cooldown_test.lua';f.write_text(h,encoding='utf8')
r=subprocess.run([str(lua),str(f),str(P/'02_覆盖到客户端根目录/Interface/AddOns/RebornWDCooldownTooltip/Cooldown.lua')],capture_output=True)
assert r.returncode==0,(r.stdout,r.stderr)
(P/'checks/cooldown.txt').write_bytes(r.stdout+r.stderr)
def put(n,s): (P/n).write_text(s,encoding='utf8')
readme='''# WD119B 持续时间显示与技能书污染清理（客户端候选）

这是 WD117/WD118/WD119 已安装环境的客户端增量修正，不是新的技能累计源码包。

## 安装
完全退出游戏。先备份你正在使用的以下三个 Lua 文件，再将 `02_覆盖到客户端根目录` 中的 Interface 合并到客户端根目录，覆盖三个同名文件，然后重新进入游戏。
- RebornWitchDoctorTalents/NumericTooltip.lua
- RebornWitchDoctorSkillBook/RebornWitchDoctorSkillBook.lua
- RebornWDCooldownTooltip/Cooldown.lua

无需重新编译，无需 SQL、DBC 或 MPQ 导入。保留现有图标和原累计技能包。若随后覆盖 WD119A，最后重新覆盖本包三个文件。包内 NumericTooltip 承接 WD119A 协议；旧 WD117/118 服务端依然兼容，不会自动授予 WD119 技能。

## 显示修正
灵魂行者没有缩短冷却。满级后，沃金守望和迅捷神像的持续时间从10秒到12秒；迅捷召唤另外将迅捷神像冷却从60秒降至45秒。原图中的绿色12秒与45秒没有矛盾，但正文仍写基础10秒容易误解。
两项技能正文现在用服务器返回的当前持续时间和效果替换基础数值说明。无有效回复时显示同步中，不冒用上次增强值。冷却说明明确标注“冷却时间 / Cooldown”，保持独立。

## 点击弹窗修正范围
WD114C/D曾从插件插入原生技能列表、写翻页/搜索字段、直接调用原生按钮刷新。原生按钮把这些字段用于受保护施法，构成不安全的插件写入路径。本包删除这些写入和钩子；/wdbook 改为只读打印分类、页码和格子，不再自动翻页。原生点击、拖动、宠物、其他职业处理函数保持原样。
弹窗只点名 DBM-Core，没有提供受阻函数/污染栈；本机没有taint.log，因此不能断言全部根因已经证实，也没有禁用或修改DBM。该项需要保留DBM复测。

## 测试
1. 灵魂行者0/1/2级：正文持续10/11/12秒，满级沃金守望减伤30%、基础每秒2.40%生命；迅捷神像移速与抵抗30%。
2. 迅捷召唤开启时迅捷神像冷却45秒，关闭时60秒；灵魂行者不改变这个冷却。沃金守望仍2分钟冷却。
3. 保留DBM，打开技能书并手动翻到迅捷神像，直接点击施放；换页、拖到动作条、动作条施放后再回书页点击，确认不弹窗。被动节点无需施放。
4. 切换已保存方案、快速悬停两个技能、reload/重登，确认正文不残留另一个技能或旧等级数值。
5. 若仍弹窗，点击忽略后输入 `/wdbook`，末行会记录最近受保护操作的插件名和函数名。将这一行反馈即可继续准确定位；无需先禁用DBM。

## 验证与回退
累计WD114耗蓝、WD117效果、WD118化蛇、WD119蛙变提示模拟，12组真实描述组合（2语言×2技能×3等级），只读技能书隔离检查及5路冷却提示模拟通过。首次只读夹具因Lua5.2代理表缺少__ipairs失败，补齐测试代理后通过；产品文件无需因该失败修改。Lua语法通过。
模拟不能验证真实客户端污染传播；尚未实机确认弹窗已消失。
回退优先恢复安装前自己的三个文件。`rollback_安装前客户端` 是制作包时此机器客户端快照（NumericTooltip未含WD119蛙变）；如果你已安装WD119A，不要用该旧快照覆盖NumericTooltip，应恢复你自己的备份或WD119A同名文件。
'''
put('README_覆盖与测试说明.md',readme)
put('memory.md','''# WD119B 候选记录
读取项目AGENTS、ruleAscend、refResourceAscend、skillsAscend及stabilize-spelldraft-client-ui/SKILL.md与evidence-lineage.md。本阶段仅现有客户端显示/插件写入清理，没有新增CoA机制或修改C++/DBC/SQL，未宣称上游机制重新审计。
实际输入：当前客户端SkillBook/Cooldown；WD119A累计NumericTooltip；WD118B研究中的patch-enUS-5 SpellBookFrame.lua及当前loose SpellBookFrame.xml只读用于调用链对照，没有发布修改的FrameXML。
可证实路径：WD114D调用UpdateSpellRender/SkillLineTab_OnClick/UpdateButton并写searchSpellID及SPELLBOOK_PAGENUMBERS；WD114C插入spellbookCustomRender并调用UpdateButton；原生UpdateButton向spell/index属性写数据，OnClick读取属性后CastSpellByID。删除不必要的跨安全边界写入。历史用户诊断已显示目标技能在原生列表中，并非需要补入的缺失技能。
不能证实：DBM-Core是最初污染源；没有现场taint栈，删除上述路径是候选修正，不能把离线Lua通过当作受保护调用验证。
数字已核对现有WD117代码：duration10000/11000/12000ms；整数25/27/30，治疗200/220/240百分之一；原黄色正文包含“基础（未计灵魂行者）”，据此精确替换。协议/缓存/序号/方案校验原样保留。未改冷却公式。
''')
put('tutor.md','''# 为什么12秒和45秒可以同时正确
持续时间是效果维持多久，冷却是下一次何时可以再次施放。灵魂行者增强前者，迅捷召唤缩短后者。显示层应读取服务端当前效果，明确区分两种时间，不把基础段落和当前段落同时作为有效值展示。
技能图标正常并不表示受保护点击链正常。普通插件从安全钩子的回调里修改原生列表，仍然是不安全写入；hooksecurefunc不等于回调获得安全权限。已有技能应由原生技能列表管理。定位命令只读输出位置，让用户正常点击原生分类与翻页按钮。
受保护操作弹窗里的插件名只是诊断线索，需要现场函数名或taint栈才能确定完整传播链。此包保留原生点击及DBM，并提供只读受阻事件记录供剩余问题定位。
此为候选经验，等待用户确认，不升级为已实测成功配方。
''')
put('phaseFixForNewChat.md','WD119B仅客户端3文件增量；NumericTooltip基于WD119A，兼容WD117/118。正文实时显示Walker数值，冷却明确标注；移除WD114C/D列表及导航写入，/wdbook只读定位+最近受阻操作。未改FrameXML或DBM，未实机确认弹窗消失。下一步以用户保留DBM直接点击/翻页/重登结果为准，若仍异常读取/wdbook末行并抓现场taint栈；不要宣称根因已完全定位。旧累计源码/SQL/DBC不变。\n')
for n in ['wd119b_build.py','wd119b_test.py','wd119b_finish.py']:shutil.copy2(n,P/'tools'/n)
manifest={f.relative_to(P).as_posix():hashlib.sha256(f.read_bytes()).hexdigest() for f in P.rglob('*') if f.is_file()}
put('SHA256.json',json.dumps(manifest,ensure_ascii=False,indent=2))
z=P.with_suffix('.zip');assert not z.exists()
with zipfile.ZipFile(z,'w',zipfile.ZIP_DEFLATED) as a:
 for f in P.rglob('*'):
  if f.is_file():a.write(f,f.relative_to(P).as_posix())
with zipfile.ZipFile(z) as a:
 assert a.testzip() is None
 for n,h in manifest.items():assert hashlib.sha256(a.read(n)).hexdigest()==h
note=f'''\n\n## 2026-10-03 WD119B 持续时间与技能书污染清理（候选待测）
仅客户端3文件增量：两技能正文读服务器当前10/11/12秒及效果，冷却单独标注；删除WD114C/D对原生列表、搜索、页码和刷新调用的写入，/wdbook只读定位并记录最近受保护操作。沿用WD119A提示协议，兼容WD117/118，不改源码SQLDBC和DBM。不把popup里的DBM-Core当作已证实根因；无taint栈，完整弹窗修复待实机验证。
累计数值模拟、12组真实描述、只读表/原生函数不变检查、5路冷却模拟、语法及ZIP校验通过。首次只读测试代理缺少Lua5.2的__ipairs导致夹具失败，修夹具后通过。未编译未部署未实机。使用stabilize-spelldraft-client-ui，仅候选经验。
来源：[覆盖说明]({P.as_posix()}/README_覆盖与测试说明.md)。ZIP SHA256 {hashlib.sha256(z.read_bytes()).hexdigest()}。
'''
for rel in ['updateMemory.md','updateListAscend.md','tutorMemory.md','refResourceAscend.md','beascendskills/skillsAscend.md','beascendtutor/tutorsAscend.md','beascendskills/stabilize-spelldraft-client-ui/SKILL.md','beascendtutor/stabilize-spelldraft-client-ui/TUTOR.md']:
 f=R/rel;assert f.exists()
 with f.open('a',encoding='utf8') as out:out.write(note)
print(z);print('ZIP verified; bytes',z.stat().st_size)
