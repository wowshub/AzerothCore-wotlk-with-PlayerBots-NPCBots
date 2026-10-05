# coding: utf-8
from pathlib import Path
import json,shutil,datetime,hashlib
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');P=Path(Path('wd120_path.txt').read_text());B=Path(Path('wd119_path.txt').read_text());BC=Path(Path('wd119c_path.txt').read_text());stamp=datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=-7))).isoformat(timespec='minutes')
def put(n,s):
 f=P/n;f.parent.mkdir(parents=True,exist_ok=True);f.write_bytes(s if isinstance(s,bytes) else s.encode('utf8'))
for rel,root in [('01_覆盖到源代码根目录/modules/mod-reborn-witchdoctor/src/RebornWitchDoctor.cpp',B),('02_覆盖到客户端根目录/Interface/AddOns/RebornWitchDoctorTalents/NumericTooltip.lua',BC),('server_SQL/01_CHARACTERS_WD119A_必须执行.sql',B)]:put('rollback_WD119C/'+rel,(root/rel).read_bytes())
readme='''# WD120A 酿造基础三节点累计测试包

状态：源码、数据与离线检查完成，待用户编译和游戏实测。以WD119A累计包为主体，合并WD119B技能书清理和WD119C蛙变冷却/移动打断。WD119C尚未得到用户实测通过反馈，不能当作已验收。

## 本批内容

|节点|获得条件|效果与使用|
|---|---|---|
|4005 大锅酿造|酿造方案，10级，免费|酿造专精被动；建立配料入口。本批只开放丛林蘑菇，基础一种配料。|
|12645 配料：丛林蘑菇|酿造方案，10级，免费；大锅酿造或治疗守卫|保存激活后，在酿造技能书主动施放准备。每6秒治疗30码内最多8名团队友方；基础数值随角色等级缩放，加20%治疗加成。|
|12646 药水投掷|酿造方案，14级，免费；大锅酿造或治疗守卫|需先准备配料，瞬发治疗友方，15秒冷却；增加28%治疗加成和10%精神。丛林蘑菇附加每3秒一次、持续18秒的治疗。14/22/30/38/46/54/60级共7个技能等级。|

三个节点均不消费AE/TE，也不能给其他节点凑前置点数。已保存技能只在激活方案中授予；切出方案撤销配料技能和自身准备光环。已经落在友方身上的18秒治疗按原持续时间结束。换回方案后可重新准备配料。大锅酿造是被动，不是旧版“魔精大锅”消耗品供应物件。

技能书中的丛林蘑菇与药水投掷增加服务端当前治疗范围提示，随等级、装备、属性和方案更新；范围包含自身治疗加成，尚未计目标增减益、暴击和过量治疗。节点图标、技能书图标和拖动资源使用同一套官方节点BLP。

## 覆盖与执行

1. 备份源码、客户端、服务端DBC和Characters数据库。将`01_覆盖到源代码根目录`全部覆盖到项目源码根目录，自行重新编译。必须包含Player.cpp以及新BrewingFoundation.inc、BrewingNumbers.h。
2. Characters库执行`server_SQL/01_CHARACTERS_WD120A_必须执行.sql`。此后不要再运行WD113–119的旧Characters保存过程。守卫发现未知节点时应停下核对版本，不要删守卫或清空方案表。
3. World库执行`server_SQL/03_WORLD_WD120A_必须执行.sql`。已装WD112/118时不用重跑包内两份旧World依赖；未装时按各自编号先补上。新World脚本可重复执行，注册配料/投掷逻辑、7级技能链，并关闭直接治疗的默认法强系数，避免重复加成。
4. 覆盖`02_覆盖到客户端根目录`。把`client_mpq输入_导入现有Patch-XA`中的DBFilesClient和Interface按内部路径全部导入现有Patch-XA；不要漏掉图标。备份MPQ放在Data之外。
5. 停服覆盖`03_覆盖到服务端根目录`，重启服务端；完全退出客户端后重新进入。双端DBC分别基于各自数据生成，不能互相替代。

不需要先逐个覆盖WD115–119。本包没有新EXE，没有改写运行源码、客户端或生产数据库。

## 建议实测顺序

- 先回归WD119C：贡克方案新施放蛙变术，实际倒计时约60秒；读条中移动应打断。克拉格瓦仍应瞬发。安装前的旧冷却不会自动清除，等它自然结束后再测。
- 在酿造方案保存这三个免费节点；确认旧方案、第二套已购买方案和其他技能不变，三个新图标出现在酿造栏目，拖动图标可见。
- 没准备蘑菇时投掷应拒绝；准备后约每6秒出现范围治疗。受伤队友30码内有效，超过范围不应被治疗。
- 投掷友方后检查直接治疗、15秒真实冷却、随后18秒内约6次治疗；切换目标与快速悬停不应遗留上个技能的数字。
- 切到巫毒方案：准备光环和三项酿造技能归属应撤销；切回、重登、升级后仍能正确恢复已保存节点和适合人物等级的投掷等级。14级前不能学习投掷。

## 检查与边界

累计加点/协议Lua回归、Lua语法、数值提示与快速切换、WD119B只读技能书、WD119C冷却提示回归通过；403项独立临时MySQL检查通过（包含购买记录、旧/新节点、重复安装、版本守卫、技能链与系数冲突）。双端旧DBC行和字符串前缀保持不变；新增技能的字符串偏移按当前核心格式检查通过。

图标使用官方20260925节点资源。治疗特效复用本项目现有洛阿佳酿视觉887925；当前客户端MPQ已读，36项模型/纹理/skin/动画/声音依赖可找到，记录在checks/native_visual_closure.json。**未移植独立大锅模型和CoA药瓶弹道；资源存在检查不等同游戏渲染实测。**其他配料、泼洒药水、双配料等后续节点仍未开放。没有编译C++或实机施法验证。

## 回退

保留安装前完整备份。`rollback_WD119C`提供本批修改前的对应文件和WD119A Characters过程（WD119C不改变该过程）。若已保存4005/12645/12646，先在本版本通过正常方案重置移除新节点，或整体恢复安装前Characters备份，再回退源码/Lua/DBC/Characters过程。旧SQL遇到新节点会拒绝执行；不要手工删方案行硬降级。新增World绑定应与对应源码一起管理，优先恢复安装前World备份；不能保留新绑定却移除其脚本。`rollback`目录中的WD105 SQL仅供累计隔离测试，不是本次生产回退步骤。
'''
put('README_覆盖与测试说明.md',readme)
memory='''# WD120A 研发与证据

基线：WD119A累计源码/独立双端DBC + WD119B三个Lua + WD119C Player.cpp、Spell中断标志和数值提示。保留用户之前已通过项目，WD119A/C控制回归与WD120A均仍待实测。

读取项目AGENTS、ruleAscend、refResource、永久skills目录，应用plan-coa-class-migration、trace-and-port-coa-spell-resources、build-wotlk-three-build-projection、stabilize-spelldraft-client-ui。未启动代理、未编译、未安装。

上游：https://github.com/jealous-sound/azerothcore-wotlk-coa ，实际在线commit d7620151fa4267ab90c7e0554b32628017df241a。本批已下载Brewing、Abilities、Completion、Coefficients、ScalingBase及等级缩放数据、相关Issues/PR和World SQL。节点取本地官方20260925来源Data，Spell取只读patch-T.MPQ。Issue6294提示蘑菇投掷/泼洒子效果混用；本批精确映射PotionShrooms802973，不使用SplashShrooms803273。

研究纠正：早期检查点把Spell第232字段182误称Scaling字段。核对上游DBCStructure后确认它是SpellDescriptionVariableID；该表不在patch-T中。实际等级倍率来源是最新AscensionScalingBase.cpp/Data.h中的802703条目与二次公式。没有凭182去臆造缩放表。

实现：新增9003864/65/66/67及9003870–76；仅3864/65与投掷7级进入酿造SkillLine9005。84–86三个高位对应4005/12645/12646，最大mask扩87位。C++/Lua/SQL保存、重建、不得免费撤销、预算与分支规则同步，旧位保持不变。RequiredIDs保留4005或29744的替代路径；三个免费节点都从AE/TE预算及GM预算回收检查中排除。

配料使用原生周期触发Aura，施法者自身保留准备状态；当前仅一种配料，无需提前引入全套多配料状态机。投掷在OnCast快照配料、命中后按此快照施加HoT，防止弹道飞行中读到新的配料状态。生命治疗在OnEffectLaunchTarget增补来源系数；Pulse先按角色等级缩放。World禁用对应8项原生法强加成；HoT保留其原生等级成长/原生系数路径，与上游未覆盖该子法术的做法一致。

兼容差异：清理CoA扩展属性、族掩码、外部ID；15秒类别冷却变为当前等级技能的15秒原生冷却。本批只有投掷一种药水，后续泼洒共冷却需按来源再接入。使用已有洛阿佳酿视觉作为兼容外观，没有声明新大锅模型已经移植。通用治疗候选模型restoration_impact_base_blue缺少01.skin，因此没有选用；保留拒绝记录，未修改这个既有模型。

失败及处理：最初扫描对每个字符串复制整段大池导致耗时，改为按NUL结束位置取值；SQL中rank是MySQL8保留字，实际执行失败后补反引号。首次扩大SQL白名单时发现免费节点被GM预算检查计入AE，已修正，未交付旧版本。新数值测试最初用了错误方案revision和行数，服务器回包被正确拒绝，已修正测试夹具。一次累计GM配点夹具断言返回非预期，后续全新临时库复测通过，未定位原因，不声称已修复该历史路径。Register阶段不得调用GetSpellInfo（验证阶段没有Spell实例），改为无条件注册、运行时精确ID分流。

验证证据在checks；SQL操作只针对验证过@@datadir的临时实例33500。生产World只读检查私有ID与表结构。未运行游戏/用户编译；候选状态不能升级为验收。
'''
put('memory.md',memory)
tutor='''# WD120A：从配料到治疗的移植步骤

1. 先确定节点而不是只看技能名称：4005是免费酿造入口；12645、12646也是免费，RequiredIDs对应“4005或29744”。药水投掷同名旧版本很多，这里按官方801661与573430–573435的7级数据、相同说明和当前上游系数范围适配，不能混用另一个14级技能族。
2. 阅读Spell的触发链：801660效果0是周期触发Aura23，6000ms触发802703；802703是范围治疗，30码、最多8目标；投掷命中后由上游脚本选择802973，后者是18秒、3000ms间隔的原生HoT。三个步骤不是同一段治疗。
3. 新模块RebornWitchDoctorBrewingFoundation.inc的Check只允许已学习技能，投掷还要求准备光环。Snapshot保存本次配料布尔值；IngredientEffect用本次快照，不重新读取命中时配料。此批只开蘑菇；以后增加配料时改成位掩码，仍维持逐次施法快照。
4. HealBase中的GetEffectValue已含基础等级成长和随机范围。Pulse乘上来源二次倍率，随后增加0.20×治疗加成；投掷增加0.28×治疗加成+0.10×精神。SetEffectValue把结果交回核心，再经过正常治疗增益、目标修正与暴击。不要在AfterHit再加一次基础治疗。
5. World的spell_bonus_data将手动加系数的8个ID置零，避免核心默认法强系数再叠一次。新增HoT未出现在上游手动系数覆盖里，保留其自身原生路径。
6. 保存新增三个位（84、85、86），不移动旧的0–83位。AEIds扩77项只是节点索引；存储87位包含早期多级节点占位。Lua用四个32位分段，SQL用DECIMAL，不能把大mask转成浮点数。免费节点不能进入AE/TE求和，也不能被GM预算回收逻辑收费。
7. AEApply只依据激活且已保存的mask学习技能。被动可自动恢复，配料是主动准备；切出时撤销技能及准备Aura。投掷按人物等级选择适合等级，World spell_ranks与双端SkillLineAbility保持一致。
8. 数值查询沿用WD114序号、方案revision、active和过期检查；新技能只加白名单与数值内容。回包显示含自身加成的范围，不把目标抗治疗/暴击/过量治疗混称为确定治疗量。技能书仅用原生分类，不写原生列表、不改DBM。
9. DBC按客户端、服务端各自旧表追加，不共享字符串偏移。每个新名字、说明、光环说明的16个语言偏移都重写；隐藏子法术也检查。GCD在205/206，SchoolMask在225，RuneCost在226，字段不能凭记忆写错。
10. 对比旧表逐行与字符串前缀，跑累计Lua与临时MySQL，再由用户编译和实测。离线通过不能证明真实治疗、弹道、可见图标和玩家组队边界已经通过。

关键文件：01_覆盖到源代码根目录/modules/mod-reborn-witchdoctor/src/RebornWitchDoctorBrewingFoundation.inc、RebornWitchDoctorBrewingNumbers.h、RebornWitchDoctorAllocation.inc，以及server_SQL/01_CHARACTERS_WD120A_必须执行.sql和03_WORLD_WD120A_必须执行.sql。具体源码为本包实际交付内容。
'''
put('tutor.md',tutor)
put('handoff.md','''# 后续交接

WD120A已生成酿造三节点候选；从本包继续，不能回到只有WD119A的客户端基线。保留WD119B/C。用户尚未确认WD119C及本批实测。下一步优先处理用户编译/游戏反馈，再延伸泼洒药水与其他配料；必须读取最新上游与官方描述，特别注意Issue6294的投掷/泼洒子效果区分。

安装、边界、历史失败和回退见README、memory及tutor。不要重新跑旧Characters SQL、不要手工删存档节点绕过unknown-node守卫，不要声明独立大锅模型已完成。本阶段没有改写运行项目和生产数据。
''')
put('研发检查点_尚无安装包.md','''# 历史研究检查点（已由WD120A候选包接续）

本目录最初只有研究材料，现在已有可覆盖的WD120A候选，安装入口见README_覆盖与测试说明.md。研究时对字段232的误判已纠正在memory.md；本文件保留入口，不再把早期误判当作实现依据。
''')
put('implementation_ledger.json',json.dumps({'built_at':stamp,'status':'candidate_pending_compile_and_game_test','baseline':['WD119A','WD119B','WD119C'],'nodes':[4005,12645,12646],'new_spells':[9003864,9003865,9003866,9003867,*range(9003870,9003877)],'upstream_commit':'d7620151fa4267ab90c7e0554b32628017df241a','scope_limits':['one ingredient only','existing Loa Brew visual fallback','no new cauldron model or dedicated bottle missile','no C++ compilation or in-game test']},ensure_ascii=False,indent=2))
for f in ['wd120_build.py','wd120_data.py','wd120_finish_impl.py','wd120_validate.py','wd120_ui_check.py','wd120_sql_prepare.py','wd120_resource_check.py','wd120_native_visual_audit.py','wd120_mechanics.inc','wd120_docs.py','wd120_rank_audit.py','wd120_audit.py','wd120_fetch_scale2.py','wd120_fetch_ranks.py','wd19_common.py','wd9a_storm.py']:
 put('tools/'+f,Path(f).read_bytes())
print('WD120 documentation written',stamp)
