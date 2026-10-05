from pathlib import Path
import json,hashlib,zipfile,shutil,csv,io
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');P=Path(Path('wd119_path.txt').read_text(encoding='utf8'));B=Path(Path('wd118_path.txt').read_text(encoding='utf8'))
def put(n,s):
 f=P/n;f.parent.mkdir(parents=True,exist_ok=True);f.write_text(s,encoding='utf8')
results=json.loads((P/'checks/mysql_results.json').read_text());assert results['status']=='passed' and results['count']==388
data=json.loads((P/'checks/data.json').read_text());assert len(data)==53
sha=json.loads((P/'research/head.json').read_text())['sha']
shutil.copy2(B/'server_SQL/01_CHARACTERS_WD118A_必须执行.sql',P/'rollback_WD118/01_CHARACTERS_WD118A_仅供安装前状态回退.sql')
put('README_覆盖与测试说明.md',f'''# WD119A 蛙变术与双祝福——累计测试包

以WD118A累计源码/双端数据为基线，合并WD118B已通过的拖动图标资源补齐。本批3个新节点仍待用户编译与实机测试；拖动光标和沃金守望本次基本测试通过已另行登记，不扩大到灵魂行者、化蛇或本批控制效果。

## 本批3项

| 节点 | 技能 | 行为 |
|---|---|---|
|6031|蛙变术 / Amphibimorph，9003861|30码施放距离、落点8码范围，敌人变蛙、不能攻击施法、移速降低25%，临时视为野兽。普通目标40秒；玩家最多8秒并受控制递减；受到伤害解除。基础读条1秒、冷却120秒，18%基础法力。|
|6525|贡克祝福 / Gonk's Blessing，9003862|只修改蛙变术：冷却变为60秒，基础读条变为1.5秒。|
|12525|克拉格瓦祝福 / Krag'wa's Blessing，9003863|只修改蛙变术：变为瞬发，冷却仍为120秒。|

两祝福互斥，且需先学习蛙变术。三项都属于通用树、巫毒技能书分类，三种专精可使用。等级门槛26，先投入9点基础通用AE；每个节点再消耗1 AE。同层节点不能互相凑前置。正常点数成长下还需满足总点数预算；达到26级不代表已有足够10/11 AE。

提示使用服务端实际费用、施法时间和冷却计算，读条可继续受急速影响。1秒/1.5秒是无急速的基础值。选择祝福不会重置正在进行的冷却。被动与主动的图标分别与对应天赋节点一致；图标同时提供给插件目录和MPQ。

## 覆盖顺序

1. 备份当前源码、客户端、服务端DBC和Characters库。将`01_覆盖到源代码根目录`全部覆盖到项目源码根目录，然后自行重新编译。包括新交付的Unit.cpp、SpellMgr.cpp；它们在本地当前版本上只增加本技能精确判定。
2. **Characters库仅执行`server_SQL/01_CHARACTERS_WD119A_必须执行.sql`**，不要随后再执行WD113/114/118旧保存过程。WD119兼容旧节点，不清空旧方案、不重置已购买方案。SQL中的unknown-node守卫不得绕过。
3. World库：若此前未安装WD118，执行`02_WORLD_WD118A_必须执行.sql`以绑定累计化蛇脚本；可重复执行。WD112 World SQL是保留的历史累计依赖，已安装WD112环境无需重跑。本批蛙变与祝福采用原生效果和精确核心判定，没有新增World表写入。
4. 覆盖`02_覆盖到客户端根目录`。将`client_mpq输入_导入现有Patch-XA`下的**DBFilesClient和Interface全部按内部路径导入现有Patch-XA**。不要只导入DBC；否则原生拖动图标可能再次缺失。MPQ备份放Data之外。
5. 覆盖`03_覆盖到服务端根目录`后重启服务端，完全退出客户端再进入。客户端与服务端Spell、SkillLineAbility各自独立生成，不能互相替代。

无需先逐个覆盖WD115–118；本包已经累计。保留既有WD106空槽修复、WD107提示、WD108激活方案展示，以及WD109–118相关改动。本次未修改运行目录或生产数据库，未编译或生成EXE。

## 下午测试顺序

1. 保存一套仅有蛙变术的方案，另两套分别保存蛙变＋贡克、蛙变＋克拉格瓦；不要通过免费撤销已保存点数来尝试换祝福。确认双祝福同选被拒绝，其他已购买方案和旧节点仍在。
2. 无急速对照：基础1秒/120秒；贡克1.5秒/60秒；克拉格瓦瞬发/120秒。分别看天赋说明、书页、动作条提示与实际施放/冷却。切回基础方案应恢复，快速移鼠标不串值；有急速时以服务端实际提示为准。
3. 向敌人附近地面施放：圈内敌人变为现有原生青蛙、友方不变；不能攻击施法、可以缓慢移动。远离落点、超距及不合法目标不受影响。对普通可控怪观察40秒；造成一次有效伤害应解除，免疫目标沿用原生免疫。
4. 可用时测试PvP：首次最多8秒；连续施放共享原生变形/迷惑递减，不应每次固定8秒。蛙变期间针对野兽的目标校验应按野兽处理，结束后恢复原类型。
5. 检查三个节点各自图标在天赋、技能书一致；主动可拖动，鼠标上图标可见并可放动作条。被动不是可主动施放技能。
6. 切方案、/reload、退出重登，确认技能拥有权、被动效果、动作条及购买状态保留；无祝福方案不残留其加成。顺手回归沃金守望和假死拖动。

## 已查与限制

- 388项隔离MySQL检查通过；累计Lua加点/协议回归、全部交付Lua语法、服务端提示回包模拟通过；53项DBC/源码/图标等检查通过。
- 全部旧DBC记录与字符串前缀保持；新增ID不冲突，84位保存保留灵魂行者双位和化蛇位置；8张新增SpellIcon的BLP在磁盘/MPQ目录逐字节一致。
- 当前Patch-XA在审计时被其他程序占用（Windows错误32）。青蛙模型与原生Hex视觉的引用在登记解包参考中存在，World模板13321及四模型映射已只读确认；**未宣称当前锁定MPQ的实际资源或游戏渲染已经验证**。本包不覆盖CreatureDisplayInfo/CreatureModelData/SpellVisual等模型表，仅复用原生Hex外观。请将变蛙外观列入本次实测。
- 变蛙受伤解除采用最新上游的确定性伤害打断；不是保证承受若干次伤害。未移植CoA独有蛙变粒子，使用本项目已有Hex施法视觉。
- 未进行C++编译或实机；静态与模拟测试不能替代真实战斗、PvP及机器人测试。

## 回退

`rollback_WD118`保留本次修改前的源码、DBC和WD118 Characters过程；新增图标可以留在MPQ中。若已保存6031/6525/12525，先保留角色库备份，在当前版本通过正常重置撤销这些节点，或整体恢复安装前Characters备份，再回退对应源码/Lua/DBC与保存过程。旧过程遇到新节点会拒绝安装，不要删除守卫或只降SQL。客户端Lua可从原WD118包恢复，图标补齐保留WD118B。不要对角色数据手工删行来强行降级。

来源与差异见`来源与适配说明.md`，逐步教学见`tutor.md`，检查详情见`checks`。
''')
put('来源与适配说明.md',f'''# 来源、差异与边界

社区上游：jealous-sound/azerothcore-wotlk-coa，2026-10-02本批实时读取HEAD `{sha}`，不是飞升官方源码。保存的head.json、搜索结果、问题详情、PR文件列表和当前源码位于research。

- [PR4753](https://github.com/jealous-sound/azerothcore-wotlk-coa/pull/4753) 已合并，合并时间2026-09-22T23:10:46Z；相关[934](https://github.com/jealous-sound/azerothcore-wotlk-coa/issues/934)、[1179](https://github.com/jealous-sound/azerothcore-wotlk-coa/issues/1179)、[3693](https://github.com/jealous-sound/azerothcore-wotlk-coa/issues/3693)已关闭。不能据最初“搜索不到ID所以未实现”的报告照抄结论：原生Aura56/60/33和107/108已承担主要效果。
- 当前Completion.cpp仍对Amphibimorph添加TAKE_DAMAGE。上游回归场景分别覆盖8秒PvP限制与60秒/0.5秒/瞬发原生modifier。场景作为参考，不冒称本项目实际运行了上游测试。
- 官方客户端依据：`D:/game/ascend/coaWOW/coawowClinet20260925OFFICIAL/Data/patch-T.MPQ`中的Spell500952、806469、807855；本地已导出CoA树节点6031/6525/12525。保存donor.json和节点原文。官方说明、社区实现、本地适配分开。

| 项目 | 原始 | 本地适配及原因 |
|---|---|---|
|父技能|500952，三原生光环、40秒、1秒施法、120秒CD、18%基础蓝，8码半径、30码距离|9003861，保留目标与数值；category清零使用独立RecoveryTime，防止源分类号影响无关技能|
|图标|三个节点分别具有本地提取的官方图标|分配SpellIcon910120–122；同一BLP同时给插件和MPQ|
|变形模板|216377，本地World不存在|采用已存在的原生Hex青蛙13321，模型901/1924/6295/6297；不把模板ID误当模型ID，不创建缺资源模板|
|野兽语义|官方说明写变为Beast，原生transform不自动更改所有目标类型|Unit::GetCreatureType仅在9003861光环存在时返回Beast，消失自然恢复；不永久改生物模板、不改所有变形|
|玩家上限|8秒|SpellMgr按私有ID返回8000ms，交给原生递减；基础PvE仍40秒|
|伤害解除|说明可能打断，当前上游采用TAKE_DAMAGE|同一确定性打断，明确文档化；不自行编造概率|
|祝福范围|family19、bit0x80000000|私有ID精确白名单，GlobalScript只匹配蛙变，SpellInfo拒绝无关fallback，防family0空mask泛化|
|获得|9AE、1AE、互斥group807855，连接蛙变|三端保存/校验一致；祝福要求父技能；26级父Spell门槛，计入通用点数；三专精允许|
|保存|原无本地正式节点|旧71项后追加3项，bits81/82/83；不改变任何旧节点位、方案槽或购买记录|
|提示|客户端原生无法收到空mask精确modifier映射|调用相同CalcPowerCost、CalcCastTime、ApplySpellMod冷却路径返回只读值，沿用序号/revision/active过滤|

当前MPQ锁定的资源检查缺口见checks/resource_status.json；登记解包参考仅用于校验原生引用，不被用来覆盖新Spell等累计数据。双端分别从WD118A自己的一份Spell与SkillLineAbility追加，不相互复制。新增核心文件Unit.cpp/SpellMgr.cpp来自当前源码目录并做精确增量，备份位于rollback_WD118。

本批实际使用永久Skill：plan-coa-class-migration及references/stages.md，trace-and-port-coa-spell-resources，build-wotlk-three-build-projection。技能依赖表见research/ability-ledger.csv与dependency-edges.csv。
''')
put('research/ability-ledger.csv','node_id,source_spell,local_spell,book,tree,acquisition,level,dependency,status\n6031,500952,9003861,Voodoo,Class,9 foundation AE plus 1 AE,26,native control and frog model,candidate\n6525,806469,9003862,Voodoo,Class,9 foundation AE plus 1 AE,26,6031 exclusive12525,candidate\n12525,807855,9003863,Voodoo,Class,9 foundation AE plus 1 AE,26,6031 exclusive6525,candidate\n')
put('research/dependency-edges.csv','from,to,relation\n6525,6031,cooldown-60000ms cast+500ms\n12525,6031,cast-100percent\n6525,12525,mutually-exclusive\n6031,13321,transform-template\n6031,9003861,native-effect-and-type-lifetime\n')
put('checks/验证记录.md',f'''# WD119验证记录

隔离MySQL `{results['count']}` 项通过，schema安装重跑、84位存储、预算/等级/互斥、旧位和旧方案、购买状态、受保护回退均覆盖。实例端口33500，临时独立datadir，测试确认@@datadir后才操作；结束正常关闭。没有生产写入。

Lua累计回归、语法和数值提示模拟通过。模型引用检查明确区分当前被锁MPQ与登记参考。53项数据/静态检查通过，检查项在data.json。

实际遇到的问题：初次构建发现祝福节点group字段为807855，修正匹配保留原互斥组；首次SQL测试在“failed rollback retains rows”失败，原因是新测试复用了before变量并拼接购买表，后续旧断言仅比较节点表，属于测试夹具比较口径错误。分开before119并重取节点快照后全量388通过。资源审计打开当前Patch-XA失败错误32，两次均如实保留，改为显式记录参考存在而不宣称实际MPQ已核实。

未执行C++编译、真实施放、PvP递减或客户端渲染。当前结论为可交用户测试的候选包。
''')
put('memory.md','WD119A：3项关联Class节点6031/6525/12525，父9003861，祝福9003862/63。基于WD118A累计，合入WD118B已验收资源。保留旧节点位置，新增bits81–83，84位三端精确保存；26级、9基础AE、父依赖与互斥。原生控制/flat/pct modifier，精确范围保护，Unit野兽语义，SpellMgr先8秒再DR，伤害解除，原生Hex模型兼容。388隔离SQL、累计Lua及53静态检查通过。当前MPQ锁定，仅参考模型链查验；未编译未实机。用户本轮确认拖动图标和沃金守望基本通过，已同步永久库，其他未测内容不继承。\n')
put('tutor.md',f'''# 蛙变术三节点：从说明到一套可保存的技能

把它看成一台机器和两个互斥附件。蛙变术是机器；贡克附件让它冷却更快但启动慢半秒；克拉格瓦附件让它立即启动。附件不能互相替代机器，也不能两个同时装上。

## 1 先拆说明、追来源

先看官方500952的三个效果：Aura56变形、60禁止攻击施法、33减速。负BasePoints以无符号数保存，4294967270应按32位有符号解释为-26，再加DieSides1，才是-25%。40秒不是写在伤害列，而是DurationIndex64查时间表。8码来自Radius14；30码来自Range4。用错字段时，界面会有图标但实际完全不同。

然后看社区PR4753及最新commit `{sha}`。最早Issue“没有脚本所以没实现”是不充分证据：引擎的通用Aura处理器就是实现。我们复用原生机制，只修缺少的玩家上限、目标类型和本项目的精确匹配。

## 2 本地编号与资源

原始编号不是可直接占用本项目数据库的通行证。构建器先assert本地9003861–63不存在，再分别向客户端/服务端自己的Spell表追加；不拿服务端整表覆盖客户端。名字等文本追加到各自字符串池，全部`s`字段检查偏移有效，这是避免旧WD85字符串错误的必要步骤。

图标链是天赋Icon路径→SpellIcon→Spell→技能书/鼠标。原生拖动图标这次已由用户确认，经验是同时交付磁盘插件与MPQ内部路径中的同一BLP，不能只看书页能显示。新增三张使用已有官方节点资源，不需要生图。

原始变形模板216377在本地不存在。原生Hex引用13321，实际World表确认它有四个青蛙模型。我们复用这条现成链，不创建一个指向未知模型的空模板。当前MPQ被占用，因此登记解包参考中的模型和视觉只能算参考检查；不伪装成游戏内已经看过。

## 3 为什么要改两处核心

`if (HasAura(9003861)) return CREATURE_TYPE_BEAST;`放在Unit::GetCreatureType入口，只对正在蛙变的目标生效。生活类比是临时身份证：光环还在，系统按野兽校验；光环消失，继续走原来的种族/生物逻辑。无需另存原类型，也不会忘记恢复；其他变形和机器人代码保持原样。

SpellMgr中的`if (spellproto->Id == 9003861) return 8 * IN_MILLISECONDS;`位于控制持续上限层。原生引擎先用8秒封顶，再按递减变成4秒、2秒、免疫。若在施法结束后强制SetDuration(8000)，反而可能把已经递减成4秒的控制拉回8秒，这是应避免的做法。

## 4 增强为什么不会串到其他技能

贡克的Aura107分别以op11减少60000ms冷却、op10增加500ms读条；克拉格瓦的Aura108以op10减100%读条。C++ GlobalScript只允许check->Id为9003861且op符合对应祝福时匹配。此核心返回false代表强制匹配；返回true还会继续原生判断，所以SpellInfo又对9003862/63添加回退拒绝。两层缺一不可，不能把空family mask当作排除。

基础表仍是1000ms和120000ms；实际计算由原生ApplySpellMod完成，不在DBC里把父技能永久改成瞬发。切无祝福方案后才可正确恢复，也不会影响另一名没有该天赋的玩家。

## 5 保存是一份账，不是点亮图标

旧index69灵魂行者占bits78–79，index70化蛇占bit80。新index71–73占bits81–83；C++128位、Lua四32位分段、SQL DECIMAL必须一致，不能将完整数字转为Lua浮点。三层都校验：先9基础AE、等级26、每节点1AE；祝福必须有父技能，两祝福互斥。原来的位和行不动，就能保留之前的方案。

AEApply先删除不属于激活方案的祝福Aura和已学技能，再恢复应有的被动；蛙变主动只学习，不自动施放。草稿没有任何真实效果。保存后禁止免费减少已保存点数，测试双祝福应使用独立方案或正常重置。

## 6 数值提示和实际机制分开验证

服务端对9003861调用`CalcPowerCost`、`CalcCastTime`和`ApplySpellMod(...SPELLMOD_COOLDOWN...)`，客户端只显示回包，不自行猜“基础乘百分比”。回包要核对技能ID、请求序号、revision和active方案；否则鼠标从蛙变移到巫祝时，迟到的瞬发结果会串到别的技能。

数值测试用三组服务器回包模拟1秒/120秒、1.5秒/60秒、0秒/120秒，还测试切回基础、重复重绘和快速移鼠标。模拟只证明提示刷新逻辑，真正的施法和冷却仍要在客户端测试。

## 7 验证工具和独立练习

Python3.9负责读取WDBC、增量写入、精确位运算、文件哈希；Lua5.2解释器用于UI逻辑桩与语法；MySQL8独立端口33500用于真实存储过程、约束与事务测试。没有使用生产库写入或替用户编译。构建脚本是本机工作区复现工具，使用D:/000rebornWOW下阶段指针及既有来源，不是部署脚本。

练习：先预测两种附件的读条/冷却，再建立三套方案逐项验证；再用错误组合（无父技能、双祝福、少一点基础AE）确认拒绝。最后做负向对照：其他攻击/治疗技能不应被贡克加0.5秒，也不应因克拉格瓦变瞬发。正确实现必须同时满足该变化的变化、不该变化的不变。

本次离线结果：388项SQL、53项数据/静态和累计Lua通过；C++编译、游戏内外观/战斗/PvP待测。成功以后再把对应边界升级为已验证经验。
''')
put('phaseFixForNewChat.md','下一基线WD119A累计候选：WD118A+已验收WD118B图标；新增蛙变6031/9003861、贡克6525/9003862、克拉格瓦12525/9003863，bits81–83。388隔离SQL及53数据静态检查通过，未编译未实机。覆盖全部源码、02客户端、MPQ输入含Interface、03服务端；Characters WD119唯一最新，未装化蛇需World118绑定。当前Patch-XA锁定，参考模型链已查但实际资源待测。用户明确图标拖动、沃金守望通过，验收已同步永久库。灵魂行者/化蛇和新三项仍不能继承验收。下一批按依赖审计酿造基础药剂投掷/配料，不用图标数量推全职业完成。\n')
for n in ['wd119_build.py','wd119_tests.py','wd119_research.py','wd119_more.py','wd119_follow.py','wd119_native.py','wd119_resource_audit.py','wd119_finish.py','wd19_common.py','wd9a_storm.py']:shutil.copy2(Path('D:/000rebornWOW')/n,P/'tools'/n)
# Exact source-delta guards for newly delivered live-baseline files.
for rel,old,new in [
 ('src/server/game/Entities/Unit/Unit.cpp','uint32 Unit::GetCreatureType() const\n{','uint32 Unit::GetCreatureType() const\n{\n    // WD119: temporary frog category without changing templates or shapeshift state.\n    if (HasAura(9003861)) return CREATURE_TYPE_BEAST;'),
 ('src/server/game/Spells/SpellMgr.cpp','    // WD25A: official Hireek','    // WD119: clamp before native diminishing (8/4/2 seconds), not after it.\n    if (spellproto->Id == 9003861) return 8 * IN_MILLISECONDS;\n\n    // WD25A: official Hireek')]:
 previous=(P/'rollback_WD118/01_覆盖到源代码根目录'/rel).read_text(encoding='utf-8-sig');current=(P/'01_覆盖到源代码根目录'/rel).read_text(encoding='utf-8-sig');assert previous.replace(old,new)==current
manifest={f.relative_to(P).as_posix():hashlib.sha256(f.read_bytes()).hexdigest() for f in P.rglob('*') if f.is_file() and f.name!='SHA256.json'};put('SHA256.json',json.dumps(manifest,ensure_ascii=False,indent=2))
z=P.with_suffix('.zip');assert not z.exists()
with zipfile.ZipFile(z,'w',zipfile.ZIP_DEFLATED) as a:
 for n in list(manifest)+['SHA256.json']:a.write(P/n,n)
with zipfile.ZipFile(z) as a:
 assert a.testzip() is None
 for n,h in manifest.items():assert hashlib.sha256(a.read(n)).hexdigest()==h
digest=hashlib.sha256(z.read_bytes()).hexdigest()
note=f'''\n\n## 2026-10-02 WD119A 蛙变术与双祝福（候选待测）
承接WD118A累计，合并用户已确认拖动可见的WD118B。新增Class6031蛙变术9003861、6525贡克祝福9003862、12525克拉格瓦祝福9003863，26级/9基础AE/每项1AE；两祝福互斥且要求父技能。40秒普通目标、玩家8秒后原生递减、伤害解除、临时野兽类型，1秒120秒/1.5秒60秒/瞬发120秒三种基础状态；服务端数值提示同步。保留旧方案和购买，bits81–83追加，84位三端一致。
最新社区commit {sha}、已合并PR4753及934/1179/3693和当前场景已核对；官方20260925Spell500952/806469/807855单独记录。原模板216377本地缺失，复用原生Hex蛙13321；未导入CoA独有粒子。当前Patch-XA被锁错误32，登记解包引用存在不等同实际MPQ/渲染验收。
388隔离SQL、53数据/静态、累计Lua/语法/提示模拟通过；未编译未部署未实机。首次SQL旧回退断言失败为新增测试before变量含购买表导致口径不一致，修正夹具后全量通过。用户本轮沃金守望基本通过已另行登记，灵魂行者/化蛇和本批不继承。
使用plan-coa-class-migration、trace-and-port-coa-spell-resources、build-wotlk-three-build-projection。交付需Characters WD119；未装WD118需World118绑定。详情：[覆盖说明]({P.as_posix()}/README_覆盖与测试说明.md)、[教学]({P.as_posix()}/tutor.md)、[来源]({P.as_posix()}/来源与适配说明.md)。ZIP SHA256 `{digest}`。
'''
for rel in ['updateMemory.md','updateListAscend.md','tutorMemory.md','refResourceAscend.md','beascendskills/skillsAscend.md','beascendtutor/tutorsAscend.md','beascendskills/plan-coa-class-migration/SKILL.md','beascendskills/trace-and-port-coa-spell-resources/SKILL.md','beascendskills/build-wotlk-three-build-projection/SKILL.md','beascendtutor/plan-coa-class-migration/TUTOR.md','beascendtutor/trace-and-port-coa-spell-resources/TUTOR.md','beascendtutor/build-wotlk-three-build-projection/TUTOR.md']:
 f=R/rel;assert f.exists()
 with f.open('a',encoding='utf8') as out:out.write(note)
print(z);print(digest);print(len(manifest),'files',z.stat().st_size,'bytes')
