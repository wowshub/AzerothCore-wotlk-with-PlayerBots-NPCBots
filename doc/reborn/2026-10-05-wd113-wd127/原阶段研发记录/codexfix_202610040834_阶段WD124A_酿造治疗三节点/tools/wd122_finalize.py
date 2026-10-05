from pathlib import Path
import json,hashlib,zipfile,shutil,datetime
from wd19_common import dbc
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');B=Path(Path('wd121_path.txt').read_text());P=Path(Path('wd122_path.txt').read_text());Q=Path(Path('wd121b_path.txt').read_text());C=R/'beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots'
def put(rel,s):
 f=P/rel;f.parent.mkdir(parents=True,exist_ok=True);f.write_text(s,encoding='utf8')
rows,_=dbc((P/'03_覆盖到服务端根目录/Data/dbc/Spell.dbc').read_bytes())
source=P/'01_覆盖到源代码根目录/modules/mod-reborn-witchdoctor/src'
hooks=(source/'RebornWitchDoctorBrewingFoundation.inc').read_text(encoding='utf8');alloc=(source/'RebornWitchDoctorAllocation.inc').read_text(encoding='utf8');mods=(source/'RebornWitchDoctor.cpp').read_text(encoding='utf8')
assert 'if(m_scriptSpellId==WD120A::Pulse)' in hooks
assert 'GetSpellInfo()' not in hooks[hooks.index('void Register()'):]
assert 'RandomResize(targets,WD120A::PulseTargets(GetCaster()))' in hooks
assert 'CalculatePeriodic(p)' in alloc and 'SetPeriodicTimer(effect->GetAmplitude())' in alloc
assert 'return check->Id!=9003866 || mod->op!=SPELLMOD_DAMAGE;' in mods
assert 'return check->Id!=9003865 || mod->op!=SPELLMOD_ACTIVATION_TIME;' in mods
native=(C/'src/server/game/Entities/Player/Player.cpp').read_text(encoding='utf8')
assert 'totalmul *= CalculatePct(1.0f, 100.0f + mod->value)' in native
# Independent arithmetic expectations for native multiplicative healing, target cap, and cadence.
cases=0
for fresh in [0,15,30]:
 for choice in ['none','booms','doctor']:
  for boss in [False,True]:
   for amount in [1000,2000,10000]:
    pulse=amount*(1+fresh/100)*(2 if choice=='booms' else 1)
    expected=amount*(100+fresh)*(2 if choice=='booms' else 1)//100
    assert round(pulse)==expected
    interval=6000+(-2000 if choice=='doctor' else 0)
    cap=5 if choice=='booms' else 8
    assert interval in (4000,6000) and cap in (5,8)
    for count in [0,1,5,6,8,12]:
     assert min(count,cap)<=cap
     cases+=1
    # New nodes leave the tossed direct/HoT route alone; Boss remains its only new multiplier.
    toss=amount*(120 if boss else 100)//100
    assert toss==amount*(1.2 if boss else 1)
    cases+=1
put('checks/mechanics_model.json',json.dumps({'status':'PASS source audit and offline arithmetic, not engine execution','cases':cases,'checks':['native percent healing multiplies Fresh and Booms: 1.30*2 = 2.60','Doctor native activation time 6000-2000 = 4000ms','exact pulse cap5 vs8; no PotionToss/HoT modifiers','changed cadence resets full interval without extra cast','registration uses m_scriptSpellId, no null Spell dereference']},ensure_ascii=False,indent=2))
result=json.loads((P/'checks/mysql_results.json').read_text());assert result['status']=='passed' and result['count']==425
assert json.loads((P/'checks/data.json').read_text())['status']=='PASS'
head=json.loads((P/'research/head.json').read_text())['sha']
put('README_覆盖与测试说明.md','''# WD122A 丛林蘑菇互斥双天赋累计测试包

基于已通过WD121A双天赋与WD121B蛙变冷却修正。新增两项待你实测，不能同时选择。

|天赋|本批效果|
|---|---|
|丛林绽放 / Jungle Booms|大锅蘑菇单次治疗提高100%；每跳目标上限8→5人，间隔仍6秒。|
|丛林医师 / Doctor of the Jungle|大锅蘑菇间隔6→4秒；单次治疗量和8人上限不变。|

两者共用官方选择组706545，酿造方案先投入8点基础TE，每项1 TE。同层节点不能凑前置。基础来自7131/30884/29736/5055/7129；无需额外学习链，但测试效果要准备丛林蘑菇。
它们不影响药水投掷直接治疗、其18秒蘑菇持续治疗、耗蓝或15秒冷却。新鲜配料仍生效：本地原生百分比相乘，二级30%与绽放100%合计为基础的2.6倍，不是2.3倍。药水增效仍只作用于投掷。

## 安装

1. 备份源码、Characters数据库、客户端MPQ及服务端DBC。将01_覆盖到源代码根目录全部覆盖，然后自行重新编译worldserver。本包包含WD121B的Spell.cpp，不要用旧包覆盖回去。
2. Characters库导入server_SQL/01_CHARACTERS_WD122A_必须执行.sql。它支持本轮及旧节点，重复导入保留方案与购买。不要再导入旧WD113–121 Characters脚本，也不要删除unknown-node保护来绕过版本冲突。
3. 已通过WD120的World SQL无需重导。本包仍带累计World依赖，首次补装按原对应说明；本次没有新增World脚本绑定。
4. 覆盖02_覆盖到客户端根目录。把client_mpq输入_导入现有Patch-XA中的DBFilesClient和Interface按原路径导入现有Patch-XA，两张图标不能漏；备份MPQ放Data目录外。
5. 停服覆盖03_覆盖到服务端根目录，使用新编译程序重启服务端；完全退出客户端再进入。双端Spell数据各用本包对应文件，不能互相代替。

## 测试

- 无新天赋：准备蘑菇，绿色同步行应为每6秒、最多8人。
- 选丛林绽放并保存激活：当前治疗应为相同装备和其他天赋下的2倍，绿色行每6秒、最多5人。人数验证需超过5名可治疗队友且均在30码内；沿用原范围随机选人，不承诺优先最低血。
- 另一方案选丛林医师：每4秒、最多8人，单次治疗不翻倍。服务端拒绝同方案两者同时保存。
- 已准备蘑菇时切到/切出医师：间隔自动重算为4/6秒，从新的完整间隔开始，不额外立即治疗。保存草稿前不改变效果。
- 切回旧方案/重登后检查新被动恢复与移除；回测新鲜配料、药水增效以及蛙变术贡克60秒、移动打断。

黄色说明标明基础值，绿色当前行由服务端返回治疗范围、间隔和人数。当前治疗是自身加成参考，不包含目标治疗增减益、暴击及过量治疗。

## 验证边界与回滚

425项隔离MySQL、累计Lua/旧技能书/提示刷新、双端DBC旧行及全字符串检查通过；另有378组离线数值组合和源码调用路径审计。未替用户编译、部署或实机测试。
rollback_WD121A_B保存本次改动前文件。数据库已有新节点记录后，不能只覆盖旧存储过程或删除节点行；使用升级前自己的数据库备份恢复，并将源码、Lua、双端DBC作为一套回退。原WD121A/WD121B ZIP保持不变。
''')
put('来源与适配说明.md',f'''# WD122A 来源与适配

本轮在线CoA HEAD `{head}`，原始JSON与三个源码文件保存在research。

- [Jungle Booms #2865](https://github.com/jealous-sound/azerothcore-wotlk-coa/issues/2865)、[Doctor #3070](https://github.com/jealous-sound/azerothcore-wotlk-coa/issues/3070)已关闭；关闭状态不等同本项目已验收。
- [当前Completion.cpp](https://github.com/jealous-sound/azerothcore-wotlk-coa/blob/{head}/src/server/coa/AscensionWitchDoctorCompletion.cpp)将JungleBooms第二效果op34适配为最大目标数Aura；本项目改为只对私有脉冲9003866限制目标，避免共享族掩码波及别的技能。保留既有核心随机筛选语义。
- 官方20260925 patch-T.MPQ只读Spell证据见research/official.json及SHA。705859第一效果+100%，第二效果-3目标；706545为原生激活间隔-2000ms。节点提取记录显示6020/29737同组706545、各1TE、基础8TE。

9003880/81是本项目私有被动ID，图标910128/129来自现有节点贴图，节点/技能书/鼠标采用同一路径。当前服务器相关World表只读查询无这两个ID占用；候选双端DBC与旧技能列表验证无冲突。没有生产SQL写入。
伤害/治疗百分比走原生op0；间隔走原生op19，仅匹配蘑菇准备Aura9003865。人数由同一PulseTargets函数供真实范围目标筛选及提示使用。方案变化时重算现有准备Aura周期，不给额外脉冲。无新召唤物或模型，不引入额外视觉资源链。

采用永久Skill trace-and-port-coa-spell-resources（已读），范围为两个既有酿造节点；未启动整职业规划或动画修复。继承已验收WD121B，新增能力仍待实机。
''')
put('memory.md','''# WD122A 阶段记忆

用户确认新鲜配料15/30、药水增效20%通过，继续下一批。此前WD120三技能及WD119C+WD121B三种蛙变行为亦已确认。此次按同机制、同互斥组选择6020和29737，不把尚未接入的多配料/泼洒功能混入。
81项AEIds、92位保存（新index79/80，对应bit90/91），C++/SQL/Lua同步。所有旧位及购买不动。选择组和基础8TE、酿造专精、1TE预算均在服务端和SQL独立拒绝非法输入。
DBC新增9003880/81；仅旧9003865描述标为基础，所有旧行为字段不变。图标两路径同步。WD121B的Spell.cpp/Player.cpp与原包字节一致。
检查中的两次失败均为新测试夹具错误：Lua拼接1000..缺括号；目标枚举误写20，核对现有脉冲为56后修正。另在源码审计发现注册阶段不能调用GetSpellInfo，已改m_scriptSpellId并加断言。不是用户运行故障，不把这些静态检查称为编译通过。
425隔离SQL、Lua、DBC及378数值组合通过，无新增实机结论。最终未编译、未部署，没有改原归档。老WD121A首次历史等级断言失败未根因的记录仍保留，本轮隔离全套通过不能抹除历史。
''')
put('handoff.md','''# WD122A 下一窗口交接

已验收：WD120大锅/蘑菇/投掷，WD119C移动打断/克拉格瓦瞬发与WD121B贡克动作条60秒，WD121A新鲜配料及药水增效。
新候选：WD122A丛林绽放6020→9003880（+100%、5人/6秒）；丛林医师29737→9003881（8人/4秒）。二选一，基础8TE+1TE，保存mask92位。等待用户分别验证及切方案恢复；不重复问已通过项目是否通过。
下一批可继续酿造泼洒/多配料，须重新核对上游和官方来源，再按依赖选择。当前仍只开放蘑菇配料。构建器仅用于候选，不能对已交付ZIP重跑覆盖；记录与检查在本目录。
''')
sections=['# WD122A 逐步教学\n\n先明确一项天赋作用在哪里：丛林绽放只改变大锅脉冲的治疗与人数，医师只改变准备Aura的周期。投掷与18秒持续治疗是不同ID，必须排除。\n']
for rel,needle,title in [('RebornWitchDoctor.cpp','if(mod->spellId==9003880)','1. 精确选择原生法术修正'),('RebornWitchDoctorBrewingFoundation.inc','void PulseTargets','2. 范围人数与注册生命周期'),('RebornWitchDoctorAllocation.inc','bool const cadenceChanged','3. 保存方案恢复与周期变化'),('RebornWitchDoctorTalents.cpp','int32 interval=info','4. 服务器提示与真实Aura共用值')]:
 lines=(source/rel).read_text(encoding='utf8').splitlines();i=next(i for i,x in enumerate(lines) if needle in x)
 sections.append(f'\n## {title}\n\n文件 `{rel}`，第{i+1}行起：\n\n```cpp\n'+ '\n'.join(f'{j+1}: {lines[j]}' for j in range(i,min(i+18,len(lines))))+'\n```\n')
sections.append('''
## 代码为什么这样写

IsAffectedBySpellmod让原生计算使用私有精准ID，而SpellInfo里的排除分支防止走共享mask兜底。百分比由核心相乘，100%是乘2；与30%新鲜配料并存为乘2.6。目标筛选在核心加目标之前，将列表最多裁成5，随后原8人限制不会扩大列表。
注册时Spell实例可能还不存在，必须读框架初始化的m_scriptSpellId；运行回调才读GetSpellInfo。两个时间点不能混为一谈。这是对象生命周期检查，不靠Lua绕过。
原生CalculatePeriodic先从DBC6000ms读取，再应用op19的-2000ms。切方案只有医师状态改变才重算，避免每次同步都延后治疗。SetPeriodicTimer从新的完整周期起步，不额外触发一次治疗。
Lua只展示服务端返回的a/b治疗范围、c间隔、d人数。新增8字段解析先尝试，再兼容旧7/6字段。序号、方案修订和缓存失效守卫保留，防止快速移动鼠标把旧技能数值写到新技能。

## 保存和文件工具

C++用81项映射，Lua四个32位整数承载精确92位mask，SQL用DECIMAL整数拆bit90/91，避免Lua浮点丢高位。SQL重复导入只升级定义，不清空角色；独立拒绝双选和基础不足。
wd122_build.py在独立目录复制累计文件、只增加两个Spell行，并分别维护客户端/服务端字符串池；每个字符串offset必须落在池内且以零结尾。两个图标复用本地已有BLP，分别送入松散文件与MPQ输入。
wd122_test.py运行真实Lua解释器和DBC验证，并生成隔离MySQL夹具。test_mysql.py先验证临时@@datadir才写合成角色，finally停止实例，禁止指向生产。mechanics_model是独立算术模型，不是C++引擎测试。
学习重点是法术修正与周期调度、对象生命周期、位域序列化、协议兼容、版本化数据库升级。这些解释依据本包实际源代码，不虚构书籍出处。
''')
put('tutor.md','\n'.join(sections))
# Rollback source/data snapshots, not destructive SQL. Full database restore requires user's backup.
shutil.copy2(B/'server_SQL/01_CHARACTERS_WD121A_必须执行.sql',P/'rollback_WD121A_B/WD121A_原Characters定义_勿直接回退有新节点的库.sql')
for name in ['wd122_research.py','wd122_build.py','wd122_test.py','wd122_finalize.py','wd19_common.py','wd9a_storm.py']:shutil.copy2(name,P/'tools'/name)
put('checks/source_audit.json',json.dumps({'status':'PASS','reserved_live_world_rows':0,'script_registration_safe':True,'native_spellmods_multiply':True,'in_game':False,'compiled':False},indent=2))
changes=[]
for folder in ['01_覆盖到源代码根目录','02_覆盖到客户端根目录','03_覆盖到服务端根目录','client_mpq输入_导入现有Patch-XA','server_SQL']:
 for f in (P/folder).rglob('*'):
  if f.is_file():
   rel=f.relative_to(P);old=Q/rel if (Q/rel).exists() else B/rel
   if not old.exists() or old.read_bytes()!=f.read_bytes():changes.append(str(rel).replace('\\','/'))
put('checks/changed_files.json',json.dumps(changes,ensure_ascii=False,indent=2))
manifest={str(f.relative_to(P)).replace('\\','/'):hashlib.sha256(f.read_bytes()).hexdigest() for f in sorted(P.rglob('*')) if f.is_file() and f.name!='SHA256.json'}
put('SHA256.json',json.dumps(manifest,ensure_ascii=False,indent=2))
z=P.with_suffix('.zip');assert not z.exists(),'Do not overwrite archived ZIP'
with zipfile.ZipFile(z,'w',zipfile.ZIP_DEFLATED) as a:
 for f in sorted(P.rglob('*')):
  if f.is_file():a.write(f,f.relative_to(P))
with zipfile.ZipFile(z) as a:
 assert a.testzip() is None
 for rel,h in manifest.items():assert hashlib.sha256(a.read(rel)).hexdigest()==h
 assert not any(Path(x).suffix.lower() in ('.exe','.bat','.ps1','.patch') for x in a.namelist())
h=hashlib.sha256(z.read_bytes()).hexdigest();z.with_suffix('.zip.sha256.txt').write_text(h+'  '+z.name+'\n',encoding='utf8')
accept=R/'000Ascendupdate/000Ascendupdate20261003/WD121A_双天赋用户实测通过.md'
accept.write_text('''# WD121A 用户实测通过（2026-10-03）

用户明确：新鲜配料两级，大锅蘑菇治疗提高15%/30%；药水增效，投掷直接治疗及附带蘑菇持续治疗提高20%，测试通过，继续下一批。记录这两项数值行为通过，不扩展为所有装备/等级/PvP/机器人矩阵。此前WD120与蛙变六项已验收；后续WD122不继承通过状态。
''',encoding='utf8')
note=f'''\n\n## 2026-10-03 WD121A实测通过；WD122A蘑菇互斥双天赋候选
用户确认新鲜配料15/30%及药水增效20%测试通过，已[登记验收]({accept.as_posix()})；不外推完整场景矩阵。
新WD122A：6020→9003880丛林绽放+100%/5人/6秒，29737→9003881丛林医师8人/4秒，共组706545互斥。81节点映射、92位精确保存，8基础酿造TE+1TE，SQL/C++/Lua均校验。目标cap及周期实时提示；切方案重算现有准备Aura，保留WD121B字节基线。
425项隔离SQL、累计Lua/DBC检查及378数值组合通过；未编译/部署/实机。在线HEAD {head}，官方-3目标、-2000ms独立核对。早期测试夹具语法/枚举错误及注册阶段空Spell风险已静态纠正，边界见memory。
[覆盖说明]({P.as_posix()}/README_覆盖与测试说明.md) · [教学]({P.as_posix()}/tutor.md) · [交接]({P.as_posix()}/handoff.md)。ZIP SHA256 `{h}`。新阶段待验收，旧ZIP不改写。
'''
for rel in ['updateMemory.md','updateListAscend.md','tutorMemory.md','refResourceAscend.md','beascendskills/skillsAscend.md','beascendtutor/tutorAscend.md','beascendskills/trace-and-port-coa-spell-resources/SKILL.md','beascendtutor/trace-and-port-coa-spell-resources/TUTOR.md']:
 with (R/rel).open('a',encoding='utf8') as f:f.write(note)
print('ZIP verified',z,'SHA256',h,'cases',cases)
