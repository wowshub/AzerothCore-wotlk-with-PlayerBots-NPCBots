from pathlib import Path
import json,hashlib,zipfile,shutil,struct
from wd19_common import dbc
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');B=Path(Path('wd122_path.txt').read_text());P=Path(Path('wd123_path.txt').read_text());C=R/'beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots';S=R/'beascendserver/wowshub_playerbot_npcbot_newrace20260929Ascend/Data/dbc'
def put(rel,s):
 f=P/rel;f.parent.mkdir(parents=True,exist_ok=True);f.write_text(s,encoding='utf8')
rows,_=dbc((P/'03_覆盖到服务端根目录/Data/dbc/Spell.dbc').read_bytes())
source=P/'01_覆盖到源代码根目录/modules/mod-reborn-witchdoctor/src';mechanics=(source/'RebornWitchDoctorBrewingFoundation.inc').read_text(encoding='utf8');mods=(source/'RebornWitchDoctor.cpp').read_text(encoding='utf8');alloc=(source/'RebornWitchDoctorAllocation.inc').read_text(encoding='utf8')
assert 'GetSpellInfo()' not in mechanics[mechanics.index('void Register()'):]
assert 'WD120A::IsSplash(GetSpellInfo()->Id)?WD120A::SplashHot:WD120A::Hot' in mechanics
assert 'check->Id==9003867 || check->Id==9003889' in mods
assert 'check->Id>=9003870 && check->Id<=9003876 && mod->op==SPELLMOD_DAMAGE' in mods
assert 'uint32 const splashLevels[7]={17,22,28,36,44,50,58}' in alloc
ref={}
for table,id,col,value in [('SpellDuration',29,1,12000),('SpellRadius',13,1,struct.unpack('<I',struct.pack('<f',10))[0]),('SpellRange',5,3,struct.unpack('<I',struct.pack('<f',40))[0]),('SpellCastTimes',1,1,0)]:
 raw=(S/(table+'.dbc')).read_bytes();r,pool=dbc(raw);assert r[id][col]==value;ref[table]={'id':id,'row':r[id],'sha256':hashlib.sha256(raw).hexdigest(),'source':str(S/(table+'.dbc'))}
for id in [9003889,*range(9003890,9003897)]:assert rows[id][131]==887925 and rows[id][213]==1
levels=[17,22,28,36,44,50,58];cases=[]
def fl(i):return struct.unpack('<f',struct.pack('<I',i))[0]
for level in range(10,81):
 rank=max([i+1 for i,l in enumerate(levels) if level>=l] or [0]);assert 0<=rank<=7
 if not rank:continue
 r=rows[9003889+rank];used=min(level,r[37]) if r[37] else level;delta=max(used,r[39])-max(r[39],r[38]);base=r[80]+int(delta*fl(r[77]))
 for bh,spirit in [(0,0),(1000,200),(3000,600)]:
  for boss in [False,True]:
   direct=int(base+1+bh*.224494+spirit*.08)
   # Original family-mask has no Splash direct bit; only ingredient HoT matches Boss.
   assert direct>=0
   hotrow=rows[9003889];hl=min(level,hotrow[37]) if hotrow[37] else level;hdelta=max(hl,hotrow[39])-max(hotrow[39],hotrow[38]);hotbase=hotrow[80]+1+int(hdelta*fl(hotrow[77]));hot=int(hotbase*(1.2 if boss else 1))
   assert hot>=hotbase and 12000//3000==4
   cases.append([level,rank,bh,spirit,boss,direct,hot])
put('checks/mechanics_model.json',json.dumps({'status':'PASS arithmetic + source-route audit only, not engine execution','cases':len(cases),'limits':'HoT model verifies base growth and Boss multiplier, not all core default bonus-healing coefficients or target modifiers','checks':['all 7 level thresholds','direct manual coefficient 0.224494 + Spirit0.08','Boss excludes direct Splash, includes SplashHot','correct 803698 healing route, never803273 speed aura','only hidden child has 12sec periodic heal; no separate spellbook entry','saved active spec owns highest rank; no new global hooks'], 'samples':cases[:6]},ensure_ascii=False,indent=2))
put('checks/native_table_refs.json',json.dumps(ref,ensure_ascii=False,indent=2))
result=json.loads((P/'checks/mysql_results.json').read_text());assert result['status']=='passed' and result['count']==441
assert json.loads((P/'checks/data.json').read_text())['status']=='PASS'
assert json.loads((P/'checks/native_visual_closure.json').read_text())['status']=='all referenced native assets found'
head=json.loads((P/'research/head.json').read_text())['sha']
put('README_覆盖与测试说明.md','''# WD123A 泼洒药水与蘑菇范围治疗累计测试包

基于WD122A，保留已通过的WD121A治疗双天赋、WD121B蛙变冷却，以及待验收WD122A蘑菇二选一。
本批完整接入一个主动技能的7个等级及其独立蘑菇附加治疗。

## 新技能

**泼洒药水 / Splash Potion**：酿造专精，17级，花1 TE。向40码内地点施放，治疗落点10码内最多8名友方，瞬发，独立15秒冷却。技能等级门槛17／22／28／36／44／50／58级，只学习当前最高等级。
消耗20%基础法力值，最终消耗继续经过原生减耗计算，以实时提示为准。必须先准备丛林蘑菇；未准备时服务端拒绝使用。

**泼洒蘑菇附加治疗**：对本次实际选中的治疗目标施加12秒持续治疗，每3秒一次。它是隐藏触发效果，技能书只增加泼洒药水主动图标。单体药水投掷原来的18秒持续治疗保持不变。

**天赋范围**：药水增效提高泼洒附带蘑菇持续治疗20%，不提高泼洒直接治疗；这一范围依据官方法术掩码。新鲜配料、丛林绽放、丛林医师继续只影响大锅脉冲，不改变泼洒的8人上限与12秒持续治疗。泼洒药水属于较早层级，它的1 TE可以计入后续8点基础酿造TE门槛。

## 安装

1. 备份源码、Characters和World数据库、客户端MPQ及服务端DBC。覆盖01_覆盖到源代码根目录中的全部文件，自行重新编译worldserver。保留包内WD121B的Spell.cpp。
2. Characters库执行server_SQL/01_CHARACTERS_WD123A_必须执行.sql，不再执行旧Characters脚本。
3. World库执行server_SQL/04_WORLD_WD123A_必须执行.sql，安装七等级脚本绑定、等级链和直接治疗系数保护。已有WD120 World无需重导；其余累计依赖仍在包内。
4. 覆盖02_覆盖到客户端根目录；将client_mpq输入_导入现有Patch-XA内的DBFilesClient和Interface按原路径导入现有Patch-XA。图标需要一并导入。
5. 停服覆盖03_覆盖到服务端根目录对应数据，使用新编译程序重启；完全退出客户端再进入。双端DBC各用各自文件，MPQ备份放Data目录外。

## 建议测试

1. 酿造方案学习、保存并激活泼洒药水，技能书应显示当前等级；拖到动作条应保留相同图标。
2. 未准备蘑菇时不能施放；准备后可出现地面选点，确认40码距离及落点10码范围、最多8名友方。
3. 每个实际治疗目标应获得12秒治疗光环、每3秒跳一次，不能误获得游泳/移动加速。空地不凭空选远处队友。
4. 重复施放刷新同一技能效果；不同施法者、与单体投掷的共存边界请单独检查。成功后约15秒可再施放，切方案不能清掉已启动冷却。
5. 同装备切换药水增效：泼洒直接治疗不增加，附加持续治疗提高20%；重施后再比较。回测单体投掷18秒、WD122A二选一及贡克60秒。
6. 绿色当前提示分别列直接治疗范围和蘑菇每跳参考治疗，包含自身加成，不包含目标增减益、暴击或过量治疗；快速切换技能不能残留旧数值。

## 验证边界和回滚

441项隔离MySQL检查、累计Lua/技能书/提示回归、双端DBC与字符串检查通过。复用既有治疗视觉，36项引用资源找到；本批不声称新增专属药瓶弹道。未编译、未部署、未实机，WD122A和WD123A均待用户验收。
rollback_WD122A保存本次修改前文件。新节点已保存后回退旧数据库过程会遇到unknown-node保护，使用升级前自己的数据库备份，源码、Lua、双端DBC与数据库配套恢复，不删除角色方案绕过守卫。历史ZIP未改写。
''')
put('来源与适配说明.md',f'''# WD123A 来源审计

在线固定上游HEAD `{head}`。来源原文保存在research。

- [未关闭问题 #6294](https://github.com/jealous-sound/azerothcore-wotlk-coa/issues/6294)：报告蘑菇泼洒误给移动/游泳加速。
- [当前Completion.h](https://github.com/jealous-sound/azerothcore-wotlk-coa/blob/{head}/src/server/coa/AscensionWitchDoctorCompletion.h)定义SplashShrooms=803273、SplashFish=803698；官方20260925Spell数据恰好显示803273为Fish Oil（aura192/31/216），803698为Jungle Shrooms（aura8、3000ms、Duration29=12000ms）。因此不能原样复制上游常量。
- 本地官方patch-T.MPQ只读记录、Spell SHA和完整行见official.json及splash_closure.json。正确蘑菇私有映射803698→9003889；泼洒七级802710、567731–567736→9003890–9003896，保留等级增长、骰子和数值。
- 上游[系数表](https://github.com/jealous-sound/azerothcore-wotlk-coa/blob/{head}/src/server/coa/AscensionWitchDoctorCoefficients.h)与官方说明一致：直接治疗22.4494%治疗加成+8%精神。World将直接治疗原生默认系数置0，C++手动增加一次，随后走正常done/taken。
- 官方原始冷却分类90、15秒；单体投掷为91，二者独立。本项目继续采用私有Spell15秒冷却，避免复用外部分类波及别的技能。成本20%基础法力保留，实际查询读取CalcPowerCost。
- PotionBoss原mask第二字2048匹配单体投掷，第三字4096匹配配料；泼洒主技能第三字536870912不匹配，因此只拓展附加HoT的精准匹配，不扩大到泼洒直接治疗。

技能图标来自节点7128现有BLP，新增SpellIcon910130，两路径完全一致。当前World相关表只读检查新ID无记录；不写生产库。旧字段只更新PotionBoss说明，其他旧Spell机制、WD121B源码原样保留。
采用项目trace-and-port-coa-spell-resources永久Skill，范围是一个主动技能及其附加治疗链，没有整职业导入。临时MySQL为隔离合成数据，编译和实机仍由用户完成。
''')
put('memory.md','''# WD123A 阶段记忆

用户要求继续下一批，没有确认WD122A通过；基线为WD122A累计。选取酿造泼洒药水及正确蘑菇范围附加治疗。
查到上游未关闭6294，与实际常量反向映射吻合。采用官方803698的治疗，而非803273鱼油加速；不声称已修复上游仓库，本次仅适配本项目。
新增节点7128、index81、bit92，82项映射及93位精确保存。酿造17级1TE，不要求8点前置；作为较早层级本身计入后续8点基础。最高等级按17/22/28/36/44/50/58恢复，隐藏HoT不进书。
新增9003889隐藏HoT+9003890–96七级；图标910130。借用既有治疗视觉887925，无专属瓶弹道。地面目标87+31、10码、8友方；World七绑定及七系数0、七等级链，冲突保护先于写入。
441隔离SQL、Lua/DBC/36资源及离线数字审计通过。源码未编译，游戏未运行。WD122A仍待实测。初次官方扫描因字符串池切片低效中止并改成定长读取；没有修改资源原件。
只产出候选覆盖目录与ZIP，原累计档不改写；没有部署或生产SQL写入。
''')
put('handoff.md','''# WD123A 交接

已验收WD121A新鲜配料/药水增效，WD120三技能及WD119C/WD121B蛙变行为。WD122A蘑菇互斥双天赋、WD123A泼洒与附加治疗均待反馈，不因继续开发请求晋升通过。
本轮82节点、mask93位；7128→9003890–96、隐藏9003889。正确官方治疗803698、上游当前SplashShrooms常量803273是错误鱼油，需要保留这条差异。
安装需Characters WD123及新World WD123；旧World120已装可跳过。最高等级、地面选点、8人目标、12秒HoT、Boss只增HoT、切方案/重登是待测重点。
后续可接Mixologist+Fish Oil或其他酿造依赖，重新在线核对版本；不能沿用颠倒的SplashShrooms/Fish常量，也不能把本次候选视为实测基线。不要对交付ZIP重跑构建器。
''')
sections=['# WD123A 逐步教学\n\n这次从“技能名”继续追到实际效果ID，发现上游把鱼油和蘑菇附加效果颠倒。先核对官方Aura类型，再接本项目，避免只把错误效果换一个中文名称。\n']
for rel,key,title in [('RebornWitchDoctorBrewingNumbers.h','constexpr uint32 SplashHot','1. 私有ID与唯一系数函数'),('RebornWitchDoctorBrewingFoundation.inc','void HealBase','2. 每个落点目标计算直接治疗'),('RebornWitchDoctorBrewingFoundation.inc','void IngredientEffect','3. 正确的蘑菇持续治疗'),('RebornWitchDoctorAllocation.inc','// WD123:','4. 保存方案与技能等级'),('RebornWitchDoctorTalents.cpp','else if(WD120A::IsSplash(id))','5. 服务端实时数值')]:
 lines=(source/rel).read_text(encoding='utf8').splitlines();i=next(i for i,x in enumerate(lines) if key in x);sections.append(f'\n## {title}\n\n`{rel}` 第{i+1}行起：\n\n```cpp\n'+'\n'.join(f'{j+1}: {lines[j]}' for j in range(i,min(i+16,len(lines))))+'\n```\n')
sections.append('''
## 调用顺序与边界

OnCheckCast检查真实已学技能及已准备蘑菇，草稿不能施法；OnCast保存这次施法的配料状态；OnEffectLaunchTarget为每个实际目标计算一次直接治疗，AfterHit仅对存活友方施加正确HoT。范围搜索、最多8目标、距离和消耗由核心处理。新药水不借用大锅随机5人逻辑，因为该回调注册时只匹配Pulse。
Direct系数由C++共享函数返回，World原生直接系数归零避免加两遍；HoT保留原生周期治疗和其正常默认系数。查询使用相同SpellHealingBonusDone，给出参考值，不能把参考值等同包含目标增减益的实际回血。
药水增效原生私有匹配只添加9003889+SPELLMOD_DOT，不增加9003890–96+SPELLMOD_DAMAGE。因此新药水直接治疗不被误增强，旧单体投掷20%不回退。

## 地面选点和数据

目标A87确定地点，目标B31搜索地点附近友方，半径表13=10码，距离表5=40码，MaxAffectedTargets8。去掉原CoA不支持的64触发路由，由明确的AfterHit替代，避免原始错误脚本再次给鱼油。公开主动7级加进技能书，触发HoT没有SkillLineAbility条目。
客户端与服务端Spell分别从各自WD122副本增量写入，新增字符串追加到各自池，旧机制行保持不动。只改药水增效中文/英文说明以覆盖新HoT范围。不能让两个同名DBC互相替换。

## 保存与验证工具

C++/Lua/SQL共同新增bit92及82项映射；Lua仍用四个32位分段运算，不把高位mask转成双精度整数。重复安装SQL保留节点、方案和购买；服务端和存储过程独立校验等级/预算/专精，客户端仅提供预览。
wd123_research.py固定在线HEAD及官方行，wd123_build.py只生成独立副本，wd123_test.py使用真实Lua解释器和字段逐项断言，test_mysql.py验证临时@@datadir后仅写合成数据库并停止临时进程。资源审计逐级追SpellVisual/Kit/EffectName及M2纹理，复用资源不会宣称新专属视觉。
离线数值模型不运行C++引擎，也没有替代实际治疗目标、暴击或默认HoT系数的验收。本包未编译，用户仍需实际测试。
''')
put('tutor.md','\n'.join(sections))
for name in ['wd123_research.py','wd123_build.py','wd123_test.py','wd123_finalize.py','wd123_visual_audit.py','wd19_common.py','wd9a_storm.py']:shutil.copy2(name,P/'tools'/name)
shutil.copy2(B/'server_SQL/01_CHARACTERS_WD122A_必须执行.sql',P/'rollback_WD122A/WD122A_原Characters定义_勿直接回退有新节点的库.sql')
put('checks/source_audit.json',json.dumps({'status':'PASS','world_reserved_rows':0,'native_healing_route':803698,'wrong_speed_route_rejected':803273,'compiled':False,'in_game':False},indent=2))
changed=[]
for folder in ['01_覆盖到源代码根目录','02_覆盖到客户端根目录','03_覆盖到服务端根目录','client_mpq输入_导入现有Patch-XA','server_SQL']:
 for f in (P/folder).rglob('*'):
  if f.is_file():
   rel=f.relative_to(P)
   if not (B/rel).exists() or f.read_bytes()!=(B/rel).read_bytes():changed.append(str(rel).replace('\\','/'))
put('checks/changed_files.json',json.dumps(changed,ensure_ascii=False,indent=2))
manifest={str(f.relative_to(P)).replace('\\','/'):hashlib.sha256(f.read_bytes()).hexdigest() for f in sorted(P.rglob('*')) if f.is_file() and f.name!='SHA256.json'}
put('SHA256.json',json.dumps(manifest,ensure_ascii=False,indent=2));z=P.with_suffix('.zip');assert not z.exists(),'Do not overwrite ZIP'
with zipfile.ZipFile(z,'w',zipfile.ZIP_DEFLATED) as a:
 for f in sorted(P.rglob('*')):
  if f.is_file():a.write(f,f.relative_to(P))
with zipfile.ZipFile(z) as a:
 assert a.testzip() is None
 for rel,h in manifest.items():assert hashlib.sha256(a.read(rel)).hexdigest()==h
 assert not any(Path(x).suffix.lower() in ('.exe','.bat','.ps1','.patch') for x in a.namelist())
h=hashlib.sha256(z.read_bytes()).hexdigest();z.with_suffix('.zip.sha256.txt').write_text(h+'  '+z.name+'\n',encoding='utf8')
note=f'''\n\n## 2026-10-03 WD123A 泼洒药水与蘑菇范围治疗（候选待实测）
新增7128→9003890–96七等级，17级/1TE/酿造，40码地点、10码8友方、独立15秒、20%基础法力。正确蘑菇803698→隐藏9003889，12秒/3秒，不误给803273鱼油。上游未关闭6294与常量颠倒证据记录，在线HEAD {head}。
82项映射/93位保存；较早层级泼洒1TE计后续8基础。药水增效只增加新HoT20%，不增泼洒直接；旧投掷与大锅天赋保持。WD122A仍未获验收，WD121B字节保留。
441隔离SQL、累计Lua/DBC、{len(cases)}离线组合、36项既有视觉资源检查通过，未编译/部署/实机。只用覆盖包，不写生产数据库；旧ZIP不改写。
[覆盖说明]({P.as_posix()}/README_覆盖与测试说明.md) · [来源]({P.as_posix()}/来源与适配说明.md) · [教学]({P.as_posix()}/tutor.md) · [交接]({P.as_posix()}/handoff.md)。ZIP SHA256 `{h}`。
'''
for rel in ['updateMemory.md','updateListAscend.md','tutorMemory.md','refResourceAscend.md','beascendskills/skillsAscend.md','beascendtutor/tutorAscend.md','beascendskills/trace-and-port-coa-spell-resources/SKILL.md','beascendtutor/trace-and-port-coa-spell-resources/TUTOR.md']:
 with (R/rel).open('a',encoding='utf8') as f:f.write(note)
print('Verified ZIP',z,'SHA256',h,'numeric cases',len(cases))
