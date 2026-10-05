from pathlib import Path
import json,hashlib,zipfile,shutil,subprocess,difflib
import wd19_common as c
P=Path(Path('wd114_path.txt').read_text(encoding='utf8').strip());B=Path(Path('wd113_path.txt').read_text(encoding='utf8').strip())
def put(name,text):(P/name).write_text(text,encoding='utf8')
head=json.loads((P/'research/head.json').read_text())['sha']
put('README_覆盖与测试说明.md','''# WD114A：巫祝数值同步与通用双技能（累计候选包）

承接已通过的WD112和当前WD113。包含WD113三项天赋，以及此次数值显示修正和两个新增通用技能。未编译C++、未部署、未实机；由你编译安装后测试。

## 本次改动

| 项目 | 内容 |
|---|---|
| 洛阿强化 | 保留巫祝减耗50%、力量巫祝效果+20%的服务器原生计算；恢复已保存激活方案时补查被动光环；技能书/动作条提示向服务器读取当前整数耗蓝与力量巫祝实际效果 |
| 显性诅咒、充足药剂 | 同一提示链覆盖已移植Jinx、洛阿佳酿和破咒术，显示服务器实际计算费用；不额外增加减耗 |
| 希里克的祝福 | 破咒术提示增加当前驱散尝试次数；仍是原生驱散，不保证抵抗或不可驱散目标成功 |
| 假死药剂 / Death Draught | 新增通用主动，节点31118、技能9003853；最多假死5分钟，施放开始30秒冷却，10级、1 AE |
| 强效混合 / Potent Mixes | 新增通用被动，节点12264、技能9003854；治疗量+4%，法术威胁-15%；9点基础AE后花1 AE |

两个新节点属于通用树，可供巫毒/酿造/暗影狩猎绑定方案使用。假死药剂可计入基础AE，强效混合及同层节点不能凑自身前置。强效混合按当前官方节点MaxPoints=1移植；未开放旧记录中的8%/30%第二阶。假死不是无敌，副本内不保证脱战，玩家也不会真的把你当成死亡目标；沿用WotLK原生假死处理。

## 覆盖安装（这次要重新编译）

1. 先备份当前Characters数据库、源码、客户端Lua、服务端DBC和客户端patch-XA.MPQ。保留现有第一套巫毒及第二套酿造方案。
2. `01_覆盖到源代码根目录` 全部覆盖到当前累计源码根目录后编译。包含核心SpellInfo.cpp及WitchDoctorTalentPolicy.h，不能只覆盖模块。编译成功后替换服务端程序再启动。
3. 在 **Characters库** 执行 `server_SQL/01_CHARACTERS_WD114A_必须执行.sql`，确认成功。只执行这个最新Characters SQL，不再执行WD113或更旧过程覆盖回来。本包不删除方案、购买记录或动作条。
4. 将 `02_覆盖到客户端根目录` 覆盖到游戏客户端根目录。必须同时覆盖 `.toc` 和新增 `NumericTooltip.lua`；完整重开客户端，不能只/reload新增加载清单。
5. `03_覆盖到服务端根目录` 覆盖到服务端根目录；将 `client_mpq输入_导入现有Patch-XA` 内的文件按原内部路径导入当前patch-XA.MPQ。双端同名DBC分别使用，不要互换。MPQ备份放在Data目录之外。
6. 已完整安装WD112时，不需要再次执行World SQL。附带的 `02_WORLD_WD112A_必须执行.sql` 仅是历史累计依赖，不是WD114新增步骤。
7. 保留WD107、WD108等已有修复。本包不含PlayerbotAI.cpp/.h，与DRBOT1A机器人变龙包可叠加；此处没有将机器人测试登记为通过。

## 明早建议这样测试

1. 先不加新点：确认旧巫毒/酿造方案、购买状态、动作条均保留；切方案、/reload、小退、大退后激活页正确，空槽不阻塞读取。
2. **灵魂巫祝**：对比两个方案，一套有洛阿强化，一套没有。装备、等级、其他Buff相同，关闭GM免耗蓝。悬停技能稍候约1秒，提示应变成服务器当前费用；正常施放后比较蓝条数值，注意自然回蓝会污染“几秒后”的差值。无其他修正且基础330蓝时为165蓝；基础351时按原生整数步骤取整，不能要求所有带其他减耗的角色都固定165。
3. **力量巫祝**：移除旧增益，再施放。提示下方显示当前近战/远程攻击强度增益；例如本地最高基础232，洛阿强化后取整为278。分别检查普通和强效版，切到未点方案后重新施放恢复基础效果。旧Buff为快照，不因浏览另一页立即改变。
4. **显性诅咒**：倦怠、希里克、法力、缩小、恶毒诅咒提示及实际费用应按原生-25%计算；恶意妖术9003112不属于这项或巫祝减耗范围。连续悬停不应反复把数值减半。
5. **希里克祝福**：破咒术提示尝试次数由1变2；对带两个可驱散诅咒的目标实测。切出该天赋恢复1，与黑暗魔精互斥仍生效。
6. **假死药剂**：保存激活后技能书可用；拉一只普通怪施放，检查倒地/停止攻击/仇恨处理，移动或取消后站起，冷却30秒；最多持续5分钟。副本/PvP按原生规则，不要求一定脱战。切到没有该技能的方案后应不再拥有，切回恢复但不自动假死。
7. **强效混合**：同一治疗技能、同装备、同Buff比较多次非暴击治疗，治疗量约+4%（整数取整）；法术威胁系数减少15%，与已有威胁modifier按核心加法/乘法阶段组合。它不直接清空原有仇恨，也不降低普通白字近战威胁。保存、重登、切出切回后检查效果和拥有权。

提示最初短暂出现“同步中”是等待读取服务端。如果长时间不刷新，先确认新程序确实启动、Characters SQL成功及完整重开客户端；旧程序没有新只读接口。客户端连续3次无有效接口回应会暂停快速重试60秒，不会无限每帧发请求。

## 已做与未做的检查

- 333项独立MySQL检查通过：使用私有33500端口、验证临时datadir后运行、测试后关闭；没有写正式数据库。
- 累计Lua回归通过：旧节点/新77位存储、预算、等级、互斥、空槽、跨专精与精确十进制保存。
- 数值提示Lua测试通过：中英文、重复刷新、旧回包、切方案、草稿隔离、Aura刷新、费用/效果、错误重试退避。
- 30项数据/静态检查通过：双端旧Spell和SkillLineAbility逐行不变、原字符串池前缀不变、全本地化字符串偏移有效、原生API/字段及新节点清理路径核对。
- 未编译C++，未验证真人实时扣蓝/模型/战斗；上述检查不能代替你的实测。未从截图确定原来的实际扣蓝也失败，明确修复的是已查明的同步缺口，并补强被动恢复。

## 回退

`rollback_WD113` 是本次改动文件的旧版本（新NumericTooltip.lua可以保留为不加载文件，旧toc不引用它）。若已保存31118/12264，旧WD113不识别新节点，不可仅回退EXE：使用安装前整套数据库及文件备份，或在新版本正常重置相关方案并确认无新节点后再降级。不要清空所有方案。
`rollback/server_SQL/01_CHARACTERS_WD105A.sql` 仅是隔离回归测试的历史夹具，不是给当前正式服执行的回退步骤。
''')
put('SOURCE_来源与适配.md',f'''# WD114来源与适配

本地基线是WD113候选、WD112已实测通过；读取AGENTS、ruleAscend、refResource及项目永久Skill：trace-and-port-coa-spell-resources、build-wotlk-three-build-projection。

本轮成功在线固定commit `{head}`，8份AscensionWitchDoctor源码归档在research。Issues1122（洛阿强化）、2190（假死药剂）、1290（强效混合）均closed，内容是历史静态审计，不能把“没找到专用handler”直接当成没有原生实现。本次所读8个文件未定位这三个ID专用实现；采用本地原生处理。查看PR6077/6123的正文和变更文件，未见对应巫医文件修复可直接复用。首次受限网络失败，后续获准只读网络核对成功，失败记录保留。

- [固定代码](https://github.com/jealous-sound/azerothcore-wotlk-coa/tree/{head})
- [Loa Empowerment](https://github.com/jealous-sound/azerothcore-wotlk-coa/issues/1122)
- [Death Draught](https://github.com/jealous-sound/azerothcore-wotlk-coa/issues/2190)
- [Potent Mixes](https://github.com/jealous-sound/azerothcore-wotlk-coa/issues/1290)

官方数据：20260925OFFICIAL/Data/patch-T.MPQ的Spell.dbc、patch-S.MPQ的SpellDuration.dbc。602220为实际假死药剂，801695标为UNUSED，不伪造第二阶。503748为当前Data.lua节点12264唯一等级，4%治疗/15%法术威胁；504888旧8%/30%版本不自动开放。

假死：独立私有9003853复制本地原生5384的可用Aura66及中断/自施放/姿态/视觉处理，持续索引5=300000毫秒，30秒施放起冷却（清除原生猎人5384的cooldown-on-expiry位，对齐当前 donor）。未迁移未解释的donor Effect93/64和关联UNUSED路径，不声称视觉为完整官方药瓶动作；本批主要是原生倒地机制。图标复用已有巫祝图标，不引入外部贴图。

强效混合：原生Aura136实现4%治疗；本核心Aura103是一次性总仇恨处理，不直接照搬donor103，而用百分比SpellModifier的THREAT操作并在ThreatManager现有spell路径精确匹配，-15%。普通近战spell=null不走该分支；不会误改旧仇恨。

洛阿强化审计：9003143在WD19A::SpiritRanks中，按FamilyBase=9003140合法匹配；9003850的两个原生modifier是-50%费用、+20%效果，DBC DieSides=1/基点-51与19正确。Spell::prepare/CheckPower调用CalcPowerCost、TakePower扣m_powerCost。客户端原生AddSpellMod只按非零mask位发送SMSG_SET_*，私有空mask不会同步，尽管服务端GlobalScript可以匹配成功。因此同步接口直接调用同一个计算函数，不在Lua猜测或重复减半；GM免耗蓝返回0。

被动恢复补查只在已保存且激活的AEApply中发生；不会给草稿授予效果。实际旧服是否曾缺Aura无法从截图证明，不记为复现的根因。
''')
put('tutor.md','''# WD114逐步教学

## 1. 把“生效”和“显示”拆开核对
截图中的330只是客户端文字，不能证明服务器扣了330。先顺着Spell::prepare → SpellInfo::CalcPowerCost → Player::ApplySpellMod → Spell::TakePower追踪。此项目的自定义modifier由服务器按精确SpellID匹配，客户端没有同一规则；空mask导致原生费用更新包没有对应位可发送。

解决办法不是把文字330写成165，而是复用服务器计算入口。RebornWitchDoctorTalents.cpp中的SpellNumbers只读取当前角色已学的白名单技能：请求序号和SpellID进来，返回整数cost、力量巫祝效果或破咒次数，以及当前revision/active槽。它不调用Load、存储过程、learnSpell或施法。400毫秒读限流独立于保存限流。

NumericTooltip.lua最多每秒查询一次当前悬停技能。缓存两秒，UNIT_AURA等事件清缓存；序号、内部epoch、revision和active用于拒绝旧回包。它不读取draftAE，因此浏览别的天赋不会把未保存的点当成已生效。显示时保留原始费用行，防止165反复减半。只改费用行，不误改30码射程。力量巫祝的当前效果作为单独一行展示，原描述保留基础值。旧服务器或缺接口连续失败三次后等待60秒。

## 2. 被动与主动不能一起自动施放
AEApply先按当前激活存档决定拥有权。9003850—52已学习但缺少永久被动Aura时重新施放自身，恢复native modifier。新9003854同理；9003853是假死主动技能，只学习不自动施放。切出拥有它的方案时移除自身Aura及已学技能。被动恢复是防护措施，不能反称截图已证明旧Aura缺失。

## 3. 新技能为什么这样适配
假死药剂复用原生5384的Aura66；核心负责停攻击、仇恨、假死状态和恢复，不手工把角色杀死、不直接改成尸体模型。持续5分钟、30秒冷却来自官方602220，清除原生猎人冷却从Aura结束开始的标志。保留原生中断和站起逻辑；副本内核心只停攻击，不保证脱战。

强效混合的治疗用原生136百分比Aura。威胁不能照抄官方Aura103，本核心103含义不同：改用SpellMod操作2，即法术威胁。ThreatManager只有spell非空才调用它，所以普通白字近战不受影响。百分比-15写成BasePoints=-16且DieSides=1；治疗4写成3+1。两项都只在当前角色永久被动存在时参与原生计算。

## 4. 三层保存保持同一规则
C++ AEIds在旧66个末尾追加31118、12264，index66/67对应bit75/76。Lua四limb和SQL DECIMAL同步扩到77位，旧bit67仍禁用。旧节点位置完全不变，数据库仍存原node_id/node_rank行。假死是低层1AE，可计前置；强效混合是9AE门槛的新同层点，不能自己凑第九点。C++、Lua、SQL以及审计提示都要一致。

## 5. 如何避免把测试说大
SQL在临时数据库中执行保存/回读/互斥/重复导入；Lua使用真正解释器执行UI代码，模拟的只是游戏API；DBC检查全部字符串偏移和旧行不变。这些能拦住范围错误、字段错误和存档回归，但不证明游戏模型、实时扣蓝、治疗/威胁全组合正确。实机仍需用户编译后验收。

本次修复过程的反例：初查SpellDuration不在patch-T，改从实际包含它的patch-S读取；旧回归把现在开放的12264当成必须关闭节点，替换成仍未开放的6044作为负向样本；第一次隔离SQL运行缺历史schema TSV夹具，补齐后重跑333项成功。没有将测试失败隐藏成已通过。
''')
put('memory.md','''# WD114A候选记录
用户反馈WD113洛阿强化已点、灵魂巫祝提示351/330没有减半，随后授权：机制不一致就修复，提供新包并继续下一批，明早测试。
已确认私有空mask原生modifier无法自动同步客户端费用。服务端既有合法家族范围和数值静态核对正确，未从截图证明实际扣蓝错误。本批增加服务器权威数值提示，已保存激活方案的被动恢复，补假死药剂/强效混合两项正式拥有权与机制；新节点仍待实机。
基线承接WD113/112，保存77位、bit67禁用；旧方案/购买/动作条不删除。333隔离MySQL、累计Lua、数值提示测试、30数据/静态检查通过。未编译、未部署、未写正式库，未改原始资源；DRBOT1A仍未收到通过反馈。
失败过程：一次shell内引号导致临时只读查询SyntaxError；SpellDuration在patch-S而非T；首次Lua旧断言12264必须未开放需换负向样本；首次隔离SQL缺schema夹具，结束进程后补齐重跑。研究第一次网络拒绝、随后只读上游检查成功。全部失败发生在研究/测试副本，不在生产。
''')
put('phaseFixForNewChat.md',f'''# 接续交接
当前候选WD114A在 {P}。已验收仍只有WD112及以前基本机制，WD113三项不可标完整通过（用户反馈洛阿提示问题）。新包：费用/力量巫祝/破咒数值由服务器只读接口同步；9003850—52激活恢复补Aura；新31118→9003853假死，12264→9003854强效混合。77位，末尾bit75/76，bit67保留禁用。基于当前候选继续不能退回WD104/105。
服务端回包WD114序号/id/cost/a/b/revision/active；客户端NumericTooltip.lua由当前toc加载。首次hover约1秒同步，3次失败60秒退避。原生权威整数并非Lua硬除2。未实机确认旧实际扣蓝失败，只能确认旧显示缺口。
下一步先收本包实测，包括原两套购买状态保存、巫祝实际扣蓝、力量增幅、Jinx减耗、破咒次数、新两项、切出撤销。保持WD106空槽/WD107时间/WD108激活页/WD111双守卫。DRBOT1A尚未实测验收，不覆盖其两个PlayerbotAI文件。
酿造还有配料/药锅/投掷链依赖缺口，现有取药大锅不是完整官方Cauldron系统。先查依赖再开节点，不为了数量做空节点。目录中的tools为构建/验证证据，部分脚本依赖D:/000rebornWOW中的既有帮助文件和历史包，非用户安装入口。
''')
put('dependency_ledger.csv','node,private_spell,tree,gate,dependency,status\n6381,9003850,Class,9AE+1,Wuju families;server numeric tooltip,candidate fix\n12048,9003851,Class,9AE+1;exclusive6048,Hexbreak,candidate carryover\n11323,9003852,Class,9AE+1,Jinx families;server numeric tooltip,candidate carryover\n31118,9003853,Class,level10;1AE,native feign death66,candidate new\n12264,9003854,Class,9AE+1,native healing136;spell threat modifier,candidate new\n')
(P/'rollback/server_SQL/仅限测试夹具.md').write_text('此目录SQL仅供隔离回归测试旧过程，不能给当前正式Characters库执行。请按主README回退章节操作。\n',encoding='utf8')
for name in ['wd114_build.py','wd114_data.py','wd114_tests.py','wd114_research.py','wd114_pr_review.py','wd114_numeric.lua','wd114_numeric_test.lua','wd114_finish.py']:
 shutil.copy2(name,P/'tools'/name)
lua=c.R/'beascendBuild/modules/mod-ale/src/lualib/lua/RelWithDebInfo/lua52_interpreter.exe'
run=subprocess.run([str(lua),str(P/'tools/wd114_numeric_test.lua'),str(P/'02_覆盖到客户端根目录/Interface/AddOns/RebornWitchDoctorTalents/NumericTooltip.lua')],capture_output=True,encoding='utf8',errors='replace');assert run.returncode==0,run.stderr
put('checks/numeric_tooltip.txt',run.stdout+run.stderr)
sha=lambda f:hashlib.sha256(f.read_bytes()).hexdigest()
prefixes={'01_覆盖到源代码根目录':c.CODE,'02_覆盖到客户端根目录':c.R/'beascendclient/newrebornWOWli20260929beAscend','03_覆盖到服务端根目录':c.R/'beascendserver/wowshub_playerbot_npcbot_newrace20260929Ascend'}
manifest=[];diffs=[]
for sub,live in prefixes.items():
 for f in (P/sub).rglob('*'):
  if not f.is_file():continue
  rel=f.relative_to(P);base=B/rel;lf=live/f.relative_to(P/sub)
  manifest.append(dict(path=str(rel),sha256=sha(f),wd113=sha(base)if base.exists()else None,current_readonly=sha(lf)if lf.exists()else None))
  if f.suffix in ['.cpp','.h','.inc','.lua','.toc'] and (not base.exists() or sha(base)!=sha(f)):
   old=base.read_text(encoding='utf-8-sig').splitlines(True)if base.exists()else []
   diffs.extend(difflib.unified_diff(old,f.read_text(encoding='utf-8-sig').splitlines(True),fromfile='WD113/'+str(rel),tofile='WD114/'+str(rel)))
for f in (P/'client_mpq输入_导入现有Patch-XA').rglob('*'):
 if f.is_file():manifest.append(dict(path=str(f.relative_to(P)),sha256=sha(f),wd113=sha(B/f.relative_to(P))))
put('manifest.json',json.dumps(manifest,ensure_ascii=False,indent=2))
put('checks/source_changes.txt',''.join(diffs))
put('checks/验证记录.md','333隔离MySQL、累计Lua（见lua_results.txt）、数值提示Lua（见numeric_tooltip.txt）和30项静态/数据（static_data.json）通过。没有C++编译或真人实机，生产未写入。源码改动对比见source_changes.txt，仅审阅文本，不作为安装补丁。\n')
note=f'''\n\n## 2026-10-02 WD114A 巫祝数值同步与通用双技能（候选）
用户反馈WD113洛阿强化提示不减半，未证明实际扣蓝失败。确认空mask原生modifier不会发送客户端费用更新；本批新增自角色白名单的服务器数值接口与Lua同步，恢复激活方案时补被动Aura。新增假死药剂31118/9003853、强效混合12264/9003854，77位，保留bit67及旧方案。333隔离MySQL、累计Lua/提示、30数据静态检查通过，未编译未部署未实机。DRBOT1A仍待验收。
[覆盖与测试]({P.as_posix()}/README_覆盖与测试说明.md) · [教学]({P.as_posix()}/tutor.md) · [来源]({P.as_posix()}/SOURCE_来源与适配.md)
'''
for rel in ['updateMemory.md','refResourceAscend.md','beascendskills/skillsAscend.md','beascendtutor/tutorsAscend.md']:
 f=c.R/rel
 if '## 2026-10-02 WD114A ' not in f.read_text(encoding='utf-8-sig'):
  with f.open('a',encoding='utf8')as out:out.write(note)
lesson=f'''\n\n## WD114A 排错记录：原生modifier与提示同步是两条链（2026-10-02）
代码已核实：Player::AddSpellMod只按非零mask位发送客户端更新；服务器精确ID钩子可在空mask下匹配成功。这意味着“服务端可能生效”不证明客户端费用显示正确。用户截图未证明实际扣蓝失败，不能据此杜撰运行时根因。WD114A用只读服务器CalcPowerCost/固定效果值同步提示，拒绝旧revision/active/序号回包，并补激活被动恢复；该修正仍为候选，未实机验收。
[阶段教学]({P.as_posix()}/tutor.md)。下次出现同类问题，先分开核对已保存激活拥有权、Aura、计算入口、实际扣除、提示更新，避免只对显示数字硬乘百分比。
'''
for rel in ['beascendskills/trace-and-port-coa-spell-resources/SKILL.md','beascendskills/build-wotlk-three-build-projection/SKILL.md','beascendtutor/trace-and-port-coa-spell-resources/TUTOR.md','beascendtutor/build-wotlk-three-build-projection/TUTOR.md']:
 f=c.R/rel
 if '## WD114A 排错记录'not in f.read_text(encoding='utf-8-sig'):
  with f.open('a',encoding='utf8')as out:out.write(lesson)
hashes={str(f.relative_to(P)):sha(f) for f in P.rglob('*')if f.is_file() and f.name!='SHA256SUMS.json'}
put('SHA256SUMS.json',json.dumps(hashes,ensure_ascii=False,indent=2))
z=P.with_suffix('.zip')
with zipfile.ZipFile(z,'w',zipfile.ZIP_DEFLATED,6)as out:
 for f in P.rglob('*'):
  if f.is_file():out.write(f,str(f.relative_to(P)))
with zipfile.ZipFile(z)as inp:
 assert inp.testzip()is None
 for rel,digest in hashes.items():assert hashlib.sha256(inp.read(rel.replace('\\','/'))).hexdigest()==digest,rel
print('PACKAGE',z,'files',len(hashes)+1,'bytes',z.stat().st_size,'sha256',sha(z))
