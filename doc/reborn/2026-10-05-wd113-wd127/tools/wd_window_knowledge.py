# -*- coding: utf-8 -*-
from pathlib import Path
import shutil,json,re,hashlib
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');C=R/'beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots'
P=Path(Path('D:/000rebornWOW/wd_summary_path.txt').read_text(encoding='utf-8'))
F=R/'000Ascendupdate/000Ascendupdate20261005/codexfix_202610050306_阶段WD127F_投掷泼洒冷却完整同步'
def save(p,s):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(s,encoding='utf-8')
def add(p,s):
 p.parent.mkdir(parents=True,exist_ok=True)
 with p.open('a',encoding='utf-8') as f:f.write(s)
name='synchronize-wotlk-spell-costs-and-cooldowns'
skill=R/'beascendskills'/name
tutor=R/'beascendtutor'/name
save(skill/'SKILL.md','''---
name: synchronize-wotlk-spell-costs-and-cooldowns
description: Repair server-authoritative custom spell cost or cooldown values that disagree with WotLK 3.3.5 tooltip headers, descriptions, or action-bar timers; use when private server-only modifiers cannot be predicted from client DBC masks.
---

# Synchronize private spell costs and cooldowns

Read project rule/refResource and independently identify active client/server data. Scope to the affected exact SpellIDs and all ranks; keep cost, cast time, cooldown, GCD and Aura duration distinct.

## Trace the two flows

- Mechanics: active saved build → learned passive and actual Aura → native ApplySpellMod → stored cooldown / paid cost. Do not calculate from draft talent points or blindly subtract twice.
- Client: cooldown packet order relative to SMSG_SPELL_GO → predicted action timer; tooltip Left description **and Right heading** → authoritative query reply → current hovered SpellID.

## Repair where authority belongs

1. Verify DBC field semantics from this core's DBCStructure and CalcValue. EffectDieSides starts at74, BasePoints80, TargetA86. die0 does not add1. Confirm actual Aura amount before choosing a base-minus-one convention.
2. Keep the conditional passive native; do not globally lower the base DBC cooldown to the talented value. Resolve signed/unsigned min/max explicitly and cast before subtraction.
3. If SPELL_GO overwrites an earlier custom cooldown packet, follow the existing post-GO correction: read the already stored server delay, clear only the owner's client prediction, send that delay. Exclude passive/item/event-start/ignore-cooldown triggered casts. Do not clear/recalculate server storage.
4. Serialize every authoritative field: count top-level arguments against format placeholders and confirm the receiver gets the cooldown. Missing fields must show syncing/unavailable, not an invented current value.
5. Update only white-listed tooltip lines, including Right headings and locale variants. Preserve original text across paints and detect native row rebuilds. Use sequence, SpellID, epoch, revision and active-slot validation; invalidate on relevant character changes and avoid Show reentry.
6. Preserve unrelated HoT duration/GCD/range and ordinary spells; do not override global GetActionCooldown or GetSpellCooldown to hide a protocol failure.

## Verify and record

Run real delivered Lua with mocked API for all ranks, both locales, repeated paint, native rebuild, talent on/off/on, missing field and stale-hover responses. Check packet ordering against delivered C++, then independent compiler type/syntax probes when a full build is not authorized. Compare client/server DBC independently at byte/row/string levels. In game separately verify actual reuse, action timer, heading, body and remaining time; a correct green line alone is insufficient.

Verified source: [WD127F case](references/wd127f-case.md), user confirmed current skill tests passed on2026-10-05. Scope is Potion Toss and Splash basic synchronization;84 scenarios are offline, not84 in-game tests. Gonk after-GO precedent also has user basic confirmation. This does not certify every rank/PvP/bot/third-party UI combination or unrelated passive coefficients.

Anti-patterns: pre-GO-only packet; Left-only text replacement; a passed test built on wrong DBC indices; missing last format placeholder; 9.999 formatted to10 instead of repairing5001→5000; claiming modules.lib failure is an independent link configuration issue.
''')
case='''# WD127F accepted case

User2026-10-05: “现在这次的技能测试都通过了”。Basic in-game acceptance for final potion repair, after screenshots had shown description9.999, heading15 and action timer15.

Potion Toss9003870–76 / Splash9003890–96, private passive9003897. Base15000ms; passive finalBasePoints-5000 withactualDieSides0. Post-GO client correction reads stored delay. Toss protocol gains missing tenth placeholder; Lua handles Right heading and Left body. Mushroom HoT remains18s/12s respectively.

Final package: '''+F.as_posix()+'''.zip
SHA256:e68282509364048d9b32009ac07b7c7f14dfa5fb46ae918560856201e4e90417.
Source checkpoint559fe78fd; Git resource binary correction8100818d2, pushed wowshub/threemodelcardpro.

84 actual-Lua mock scenarios, historicalWD114–123 regressions, deliveredLua syntax, MSVCisolated/Zs block and signed-expression checks, bothDBCfull-string/single-field-byte checks. Agent did not compile the whole project or deploy. User's acceptance does not extend to all numeric matrices. WD124 Medicine Man/Regenerator49/9 encoded withdie0 are separate pending precision checks.

Full window review: '''+P.as_posix()+'''/memory.md
Full line-by-line lesson: '''+P.as_posix()+'''/tutor.md
Failed stages, originalZIP hashes and diagnostics remain in that summary's failure archive.
'''
save(skill/'references/wd127f-case.md',case)
save(tutor/'TUTOR.md','# 用服务器的账本同步客户端的钟\n\n先区分CD、GCD、读条和buff；再按保存真实值→发送GO→校正客户端计时的顺序理解。\n\n[本窗口完整逐行教学]('+P.as_posix()+'/tutor.md)的9—14节是本Skill课程，1—8与15—19提供基础和反例。\n\n[验收证据]('+str(skill/'references/wd127f-case.md').replace('\\','/')+')。\n\n离线程序通过不等于游戏所有组合通过；原生计时和鼠标数字都要测，不能只看到绿色行变10就收工。\n')
scope=(P/'memory.md').read_text(encoding='utf-8')
for key,heading,note in [
 ('trace-and-port-coa-spell-resources','WD113—WD127技能闭包与图标验收','保存完整获得方式、主/子ID、效果、方案撤销与数字通路。WD118B五BLP补MPQ使原生拾取可见；技能书可见不证明鼠标资源可加载。WD115同源强效混合用最高级、不重复授予。WD120—123治疗与隐藏子效果不是两份天赋。药师／再生者编码疑点不晋升数值成功。'),
 ('build-wotlk-three-build-projection','WD113—WD127累计节点和保存','88个节点映射、100位传输与旧node_id/node_rank存储分别管理；三端前置/互斥/预算/位索引同步；面板Data.lua也必须存在。新节点未知记录守卫不能删除。已学被动缺Aura可恢复，主动不自动施放。用户基本确认不等于所有预算与断线故障已实测。'),
 ('stabilize-spelldraft-client-ui','WD119B技能书污染与WD127C面板源','诊断按已学→原生槽→渲染列表→分类页格只读定位；不得为定位写受保护原生按钮/渲染表。DBM弹窗不是污染源证明。Panel按Data.lua绘图，逻辑层有节点不保证面板有节点；旧树布局和新版官方树不同，应单独迁移而非按ID覆盖。'),
]:
 s=R/'beascendskills'/key/'SKILL.md';t=R/'beascendtutor'/key
 ref=s.parent/'references/wd113-wd127-window.md';save(ref,'# '+heading+'\n\n'+note+'\n\n'+scope)
 add(s,'\n\n## 2026-10-05 '+heading+'\n\n'+note+'\n\n来源及限定验收：[本窗口证据](references/wd113-wd127-window.md)。最终药水同步使用[synchronize-wotlk-spell-costs-and-cooldowns](../'+name+'/SKILL.md)。旧失败包不作为成功基线。\n')
 save(t/'WD113-WD127.md','# '+heading+'教学\n\n'+note+'\n\n[本窗口逐行总教学]('+P.as_posix()+'/tutor.md)\n\n[逐阶段原教学索引]('+P.as_posix()+'/逐阶段教学索引.md)\n')
 index=t/'TUTOR.md' if (t/'TUTOR.md').exists() else t/'00-course-map.md'
 add(index,'\n\n## 2026-10-05 WD113—WD127\n\n[本窗口对应教学](WD113-WD127.md)：实际代码、每行作用、参数与测试，成功／失败边界分别记录。\n')
add(R/'beascendskills/skillsAscend.md','\n\n## 2026-10-05 WD113—WD127窗口收工\n\n- ['+name+']('+name+'/SKILL.md)：用户确认WD127F药水投掷／泼洒基本同步通过，固化后GO消息、Right标题、协议字段与实际DBC数值闭环。\n- trace-and-port-coa-spell-resources、build-wotlk-three-build-projection、stabilize-spelldraft-client-ui更新窗口证据，未重复建立同类Skill。\n- [成功、失败和待测总表]('+P.as_posix()+'/memory.md)，药师／再生者精确编码仍待核对，不作为正确数值案例。\n')
add(R/'beascendtutor/tutorsAscend.md','\n\n## 2026-10-05 WD113—WD127逐行课程\n\n- ['+name+']('+name+'/TUTOR.md)：服务端冷却与客户端预测、两侧文本、序号缓存、84项Lua测试。\n- [全部成功／失败过程的总教学]('+P.as_posix()+'/tutor.md)与[逐阶段教程索引]('+P.as_posix()+'/逐阶段教学索引.md)。三份既有Skill对应Tutor同步更新。\n')
handoff='''# 新窗口交接：从WD127F继续

## 直接给新窗口的开场指令

请先读取项目AGENTS、最新ruleAscend/refResourceAscend、beascendskills/skillsAscend及本交接；不要仅依赖自动技能列表。接续已经由用户基本测试通过的WD127F累计母版，保留之前所有方案、购买、技能书、图标、读条中断和提示修复。先复核药师／再生者的DBCdie0/base49/9数值矛盾，再按依赖选3—4个下一批技能，不重复让用户安装旧失败包。默认只交可覆盖源码／客户端／服务端数据与SQL，由用户编译部署。

## 当前母版与远端

- 最终包：'''+F.as_posix()+'''.zip，SHA256 e68282509364048d9b32009ac07b7c7f14dfa5fb46ae918560856201e4e90417。
- 用户2026-10-05确认当前技能测试通过；前批明确成功见成功与待测清单。不要把基本通过扩大为全数值／PvP／机器人矩阵。
- 源码：'''+C.as_posix()+'''，分支threemodelcardpro；目标远端wowshub=https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots.git，**不是origin/lisancth**。
- 首轮推送559fe78fd＋8100818d2；前一未推送32095f2e5也在历史。Git保存累计源文件及data/reborn-checkpoints/WD127F的完整资源ZIP，ZIP必须取包含8100818d2的版本。
- 14个F源码文件与提交前实际工程逐字节一致。其余Core的早期巫医依赖也提交。ACSoap、shell位、PSD、子模块变化等非本窗口修改保留在工作树；不要reset/clean或顺手提交它们。
- 客户端及服务端实际运行路径仍以refResource登记和现场文件核对，不凭本归档推断部署。两侧Spell.dbc独立生成，绝不能互换。

## 已成功的方法不能回退

1. 数字从服务器读取，白名单、序号、epoch、revision和active核验；草稿不授权也不决定当前数值。
2. PotionToss9003870–76及Splash9003890–96都有CD字段。药水投手9003897精确减5000；无被动基础15秒，激活10秒。原生CD在GO后校正，文字Left/Right都刷新。HoT投掷18秒、泼洒12秒，独立于CD。
3. 贡克60秒后置同步；普通／贡克移动打断；克拉格瓦瞬发可移动。Spell.dbc第31列MOVEMENT位1已补，不能再拿未修旧数据覆盖。
4. WD119B只读技能书诊断，C/D写原生按钮和渲染表的旧路径不要恢复；五个BLP在MPQ而非只在loose插件。
5. 强效混合两入口最高级，不重复叠加9003854。节点图标、书页SpellIcon路径一致，但没有统一改官方整树布局。
6. 范围蘑菇与两种药水的隐藏附效、系数顺序和发射时配料快照保留；只有一种准备配料，Mixologist未做。
7. AEIdCount=88，mask宽100；C++、Lua四limb、SQL精确存取、Data.lua显示都同步。Characters累计SQL用127A过程，不能执行WD113旧schema清新记录。

## 接下来优先做什么

P0：检查9003898/99/3900实际Aura Amount消费。当前最终数据die0分别base49、9/49、9，与50%／10%／10%说明矛盾。它们只在拥有权／基本使用层面有总反馈；不能把49猜成50。若确证修数据，只改对应双端记录并校验旧行，更新数值显示和原验证脚本第74列；不要把所有法术的base统一+1。

P1：依赖台账选下一批3—4项。优先检查Mixologist／未完成酿造节点，但先核对最新官方和上游Issues/PR与实际commit，不承诺已开发。整树布局／官方ID跨版本复用另立专项，保留旧存档映射。

P2细测：鱼油16级自动学习边界、蛙骨护盾系数／换料快照、缩小盟友目标与属性、蛇神门徒第二驱散／GCD；不重复基本通过流程。诊断/wdbook旧名单含退役9003854，后续可改为正规9003620/21，false本身不是学习故障。

DRBOT1A及其它窗口地图／机器人事项不继承本次技能验收。

## 工具与证据

- 项目永久Skills：新synchronize-wotlk-spell-costs-and-cooldowns；现有trace-and-port-coa-spell-resources、build-wotlk-three-build-projection、stabilize-spelldraft-client-ui均已同步。
- 本窗口教程tutor.md含14段实际源码逐行讲解，逐阶段教学索引含各原教程；失败修复备份有原ZIP和SHA。
- Python3.9不支持Path.write_text的newline参数；用显式UTF-8。DBC字段74=die、80=base、86=TargetA，31=InterruptFlags、40=DurationIndex。
- Lua解释器：D:/000rebornWOW/000RebornWOWHighFork/beascendBuild/modules/mod-ale/src/lualib/lua/RelWithDebInfo/lua52_interpreter.exe。模拟测试不等于客户端3.3.5实机。
- MSVC：D:/soft/vs2022/enterprise。仅独立/Zs检查已经做过，不声称代理完整编译或生成EXE。只有用户明确要求才代编译／部署。
- F的checks含84场景、旧数字回归、全Lua语法、双端字段比较、实际后GO块MSVC检查；原隔离MySQL结果保留，不写生产数据库。
- 上游F在线获取失败，没固定最新commit；下一批新移植必须重新查。旧research的commit不能称今天最新。

## 不要再用的中间版

WD114C/D缺项与写原生UI假设、WD115仅loose图标、WD119C仅前置发送、WD122A坏枚举、WD124A wanted重名、WD127A数组尺寸、WD127B缺Data、WD127D混型min/max、WD127E局部冷却。最终包名0306，0305是构建中断目录；森金/022207草稿不是已发布的新技能。

本交接不要求用户再次确认已授权的归档／推送；未来新增技能仍按当前用户具体范围完成。
'''
save(P/'交接文档.md',handoff)
save(P/'phaseFixForNewChat.md',handoff)
save(P/'README_阅读顺序.md','# 本窗口归档阅读顺序\n\n1. [成功、失败与待测清单](memory.md)\n2. [大白话逐行总教学](tutor.md)及[逐阶段原教程](逐阶段教学索引.md)\n3. [失败备份目录](失败修复备份/README.md)，仅排错、不要安装\n4. [新窗口交接](交接文档.md)\n5. [Git提交与推送记录](git记录.md)\n\n这是复盘归档，不是新的游戏覆盖包。原始修复ZIP没有改写。\n')
tag='\n\n## 2026-10-05 WD113—WD127窗口完整收工\n\n'
add(R/'updateMemory.md',tag+'先commit并推送wowshub/threemodelcardpro，559fe78fd累计源码与测试资源，8100818d2保证ZIPbinary完整；远端SHA复核一致。用户确认WD127F基本通过。复盘全部WD113—127成功与失败、逐行教学、失败ZIP备份、永久Skill/Tutor与新窗口交接已同步。药师/再生者die0/base49/9仍有编码矛盾，列续批P0不伪称数值成功。\n\n[本窗口归档]('+P.as_posix()+'/README_阅读顺序.md)。\n')
add(R/'updateListAscend.md',tag+'明确基本通过：洛阿／耗蓝提示、假死和拖影、沃金、119B面板、蛙变两祝福与移动打断、大锅蘑菇投掷、鲜配料药水增效、蘑菇互斥双天赋、泼洒与隐藏HoT、最终两药水10秒同步。其他最终累计内容依用户总反馈登记整体基本使用，不扩全参数；药师／再生者编码疑点和高级组合细测独立保留。\n\n[逐项清单]('+P.as_posix()+'/成功与待测清单.md)。\n')
add(R/'tutorMemory.md',tag+'[从基础语法到14段实际源码逐行与测试代码教学]('+P.as_posix()+'/tutor.md)；[每次原教程索引]('+P.as_posix()+'/逐阶段教学索引.md)。新Skill与3份既有Skill同名Tutor、两个总目录同步。\n')
add(R/'refResourceAscend.md',tag+'用户2026-10-05确认最终WD127F当前技能测试通过；母版必须用202610050306包，SHA256 e68282509364048d9b32009ac07b7c7f14dfa5fb46ae918560856201e4e90417。服务端/客户端DBC独立，不因归档推断已部署现场hash。源码与资源首轮已推送wowshub/threemodelcardpro到8100818d2。编码P0药师/再生者待精准核验；[交接]('+P.as_posix()+'/交接文档.md)。\n')
add(R/'phaseFixForNewChat.md',tag+handoff)
# Snapshot knowledge files into the archive and Git documentation, excluding large failed ZIP duplication.
for key in [name,'trace-and-port-coa-spell-resources','build-wotlk-three-build-projection','stabilize-spelldraft-client-ui']:
 for base in ['beascendskills','beascendtutor']:
  shutil.copytree(R/base/key,P/'知识库快照'/base/key,dirs_exist_ok=True)
for base,file in [('beascendskills','skillsAscend.md'),('beascendtutor','tutorsAscend.md')]:
 shutil.copy2(R/base/file,P/'知识库快照'/base/file)
for f in ['updateMemory.md','updateListAscend.md','tutorMemory.md','refResourceAscend.md','phaseFixForNewChat.md']:
 dest=P/'总记录快照'/f;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(R/f,dest)
g=C/'doc/reborn/2026-10-05-wd113-wd127'
shutil.copytree(P,g,dirs_exist_ok=True,ignore=shutil.ignore_patterns('backup_zips','总记录快照'))
print(P)
