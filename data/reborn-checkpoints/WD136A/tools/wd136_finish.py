# coding: utf-8
from wd136_init import *
import zipfile,subprocess,re
CK=P/'checks'
assert json.loads((CK/'mysql_results.json').read_text())['count']==201
assert json.loads((CK/'verification.json').read_text())['status']=='passed'
assert json.loads((CK/'mpq_readback.json').read_text())['all_bytes_match']
for n in ['RebornWitchDoctor','RebornWitchDoctorTalents','Spell','SpellEffects','SpellAuraEffects','Unit']:
 t=(CK/('msvc_'+n+'.log')).read_text(encoding='utf8',errors='replace');assert n+'.cpp' in t and 'error C' not in t,n
x=subprocess.run([str(CK/'runtime/test.exe')],capture_output=True,text=True);assert x.returncode==0;put('checks/runtime_result.log',x.stdout)
# Verify live sources, addon files and server inputs were not changed while packaging.
base=json.loads((P/'research/baseline_sources.json').read_text(encoding='utf8'))
for f in base['files']:assert hashlib.sha256(Path(f['path']).read_bytes()).hexdigest()==f['sha256'],f['path']
for n in ['Spell.dbc','SpellIcon.dbc','SkillLineAbility.dbc']:
 assert (D/n).read_bytes()==(P/'rollback_WD135UI/03_覆盖到服务端根目录/Data/dbc'/n).read_bytes()
assert (C/'Data/patch-ZA.mpq').read_bytes()==(P/('rollback_WD135UI/'+CF+'Data/patch-ZA.mpq')).read_bytes()
put('README_覆盖与测试说明.md',r'''# WD136A 调制大师：候选测试包

承接已验收 WD135A＋WD135UI1，新增酿造系“调制大师 / Master of Concoctions”，节点6026、被动9003954、三次强化9003955、回血日志9003956。包含当前累计源码及配套数据，不生成服务端EXE，不改运行目录，不执行生产SQL。尚未游戏实测，确认通过后再commit/push/tag/Release。

## 实现效果
- 药水投掷、泼洒附带的八种配料效果（蘑菇、鱼油、蛙骨、血蓟，各两种）持续时间增加20%；准备配料的常驻状态、其他HoT不扩大。
- 带蘑菇的投掷或泼洒命中后，友方获得15秒、3次强化：接下来成功释放的进攻技能按实际伤害的5%给自己回血。
- 一次群攻命中多个敌人只消耗一次，所有命中分别按伤害回血；同次施法的DoT/原生周期触发继承快照，不每跳扣次数。普通攻击、自动射击、治疗及无关触发不消耗。
- 施法取消/失败不扣；成功发出后未命中仍消耗一次。刷新药水可恢复3次；一次攻击不会把多个巫医的效果叠加相乘。
- 不算吸收和过量伤害，不重复乘法强、暴击；回血仍经过原生生命上限/治疗吸收处理。不会生成递归的治疗触发链。快照不写入角色数据库；巫医退出/死亡/失去该天赋等情况下不继续提供此回复。
- DoT在消耗第三次后继续按原施法快照生效；无强化时重新施放同一DoT会替换掉旧快照。特殊脚本自行产生、且不传递父Aura身份的衍生伤害不在本批保证范围。

## 正式学习
57级酿造方案，学会大锅酿造、丛林蘑菇、森金之仪；先投入23点前层酿造TE，再花1 TE点选6026并保存。高级层节点不能互相凑前置。
官方图上另一路6023尚未实现，本批保留预览，不虚假开放；目前使用已实现的森金之仪路径。
这不是后续“Master Mixologist / 705864”主动技能，后者仍待移植。

## 安装（已有WD135及召唤栏修复）
1. 备份当前源码、服务端Data/dbc、Characters数据库，以及客户端Data/patch-ZA.mpq和Interface。MPQ备份放Data之外。
2. 把`01_覆盖到源代码根目录`覆盖源码工程，由你编译并部署worldserver。新增两个核心头文件必须一起复制；本批改Spell/Aura布局，需要正常重新编译相关目标，不能只替换旧模块对象文件。
3. 停服，`03_覆盖到服务端根目录`覆盖服务端。里面四份DBC为服务端独立累计版，不能与客户端DBC互换。
4. **Characters库只执行`server_SQL/01_CHARACTERS_WD136A_必须执行.sql`**。本批不新增World/Auth SQL；已有WD135不用重复执行旧World脚本，更不要递归导入整个SQL文件夹。包内历史World脚本只供缺前批时按说明核对。
5. 完全退出游戏，把`02_覆盖到客户端根目录`的Data与Interface覆盖当前客户端。交付的`Data/patch-ZA.mpq`继承现场LIGHT8B、WD135UI并添加新数据；原有脚下光DLL/INI不改。不要再放旧patch-ZZ覆盖它。
6. 重启服务端、客户端，在酿造方案正式加点保存、测试。原语言修复、观察者模块未修改。

基线：refResourceAscend登记的newrebornWOWli20261007beAscend、wowshub_playerbot_npcbot_newrace20261007Ascend。若安装到blacknight或另一客户端，先确认与该基线的累计资源一致。
自己导入MPQ也可以：将`client_mpq输入_导入现有Patch-XA`内全部文件按原内部路径导入Patch-XA副本，并把旧patch-ZA/ZZ移出Data。两种安装方式选一种，勿让旧整张Spell表把新记录覆盖掉。

## 测试清单
1. 正式加点保存，检查酿造书页、图标、重登和切方案；56级、缺森金或23点前层投资时不能购买。已有WD134/135及召唤栏应保持正常。
2. 选蘑菇配料，先给自己投掷。查看15秒的调制大师强化，应有3次；找可造成伤害的目标，用单体进攻技能连续打3次。每次扣1，第四次不再回血。请先让角色缺血，满血看不出生命增长。
3. 伤害1000应约回血50；实际伤害800应约40，普通取整与治疗吸收另算。目标只剩100血时击杀，不应按1000的过量伤害回血。
4. 再给蘑菇强化，使用群攻命中多个敌人：只扣1次，按各目标实际伤害回血。释放DoT后观察数跳，次数不逐跳减少；无强化时重放DoT，旧回血资格应被替换。
5. 读条中取消、治疗自己、普通近战或自动射击，不应消费次数。成功施放但抵抗/未命中仍消费一次。蘑菇重上刷新3次，鱼油/蛙骨单独投掷不发蘑菇强化。
6. 对比未点/点天赋时的蘑菇、鱼油、蛙骨、血蓟附效时长（例如15秒→18秒，18秒→21.6秒，UI可能取整）；其他治疗法术持续时间不变。
7. 给队友强化后，由队友施放技能，回血应给队友本人；检查两位巫医、换图、下线、死亡、切掉天赋，不应跨人借用次数或无限残留回复。

## 已做检查及界限
201项独立MySQL检查；31组双端数据/实际Lua检查，含118位M.Save、前置、点数与旧药水数值回归；六个受影响C++单元MSVC /Zs语法检查；直接调用交付回血辅助代码的替身环境测试（群攻、三次、DoT快照、归属/失效及10000组整数上下界）；14个MPQ内容逐字读回。
未完整链接worldserver，未在客户端实测，不将上述检查记为游戏通过。替身测试不会证明真实战斗事件顺序；需按清单实测。

## 回退
`rollback_WD135UI`包含修改前源码、客户端补丁和服务端相关DBC；恢复对应文件并重新编译。若已保存6026，必须配合恢复测试前Characters数据库备份；旧117位保存过程不能读取118位新方案，不能仅回退源码或直接删已购节点。新加头文件留在目录但不被旧源引用无妨。
''')
put('来源与适配说明.md',r'''# WD136 来源与适配
核对日期2026-10-07。社区GitHub不是飞升官方服务器源码。
- 在线HEAD：413e03e986ad5d9a3e1d95f88af7effe39972b4f，实际源码留research/Abilities.cpp、Brewing.cpp、Completion.cpp、Auras.cpp。
- [上游源码](https://github.com/jealous-sound/azerothcore-wotlk-coa/blob/413e03e986ad5d9a3e1d95f88af7effe39972b4f/src/server/coa/AscensionWitchDoctorAbilities.cpp)：Spell/Aura快照、一次施法扣次数、DoT伤害回复提供实现参考。
- [PR4753](https://github.com/jealous-sound/azerothcore-wotlk-coa/pull/4753)已合并，merge e17d84e40c219569f54f90945b99be6736255a57；不能把PR全部案例继承为本地已通过。
- Concoctions和801690的开放/关闭Issue检索均保存原结果；未找到直接匹配报告。Mixologist检索的2869属于不同技能705864，没有把它当作6026修复证据。
- 官方目标说明读取登记本地CoA资源Spell.dbc：801690、570064、570185；原行和字符串见official136.json。节点6026由当前官方树映射Data.lua核对。效果20%、5%、3次和15秒均来自对应记录；570185旧提示写10%，采用父技能引用570064的实际5%而非过时隐藏提示。
- 原始Aura354本地不支持，改私有dummy＋精确事件；旧空family mask不能保护其他技能，配料延时用八个私有ID白名单。
- 本地缺上游通用ScriptValue/伤害事件API，以私有小结构附在Spell/Aura上，直接伤害取Unit::DealDamage结果、周期取原生DealDamage结果；不导入整个上游核心。
- 适配差异：成功发出时取得快照，比上游prepare时快照避免取消/过期借用；只消费一位巫医的效果；不存在原施法巫医时停止回复，不回退成受益者来源；原生吸收/过量扣除后精确5%，不额外治疗触发。
- 23点前层不含高级层自身/大锅/动荡/水晶之水；6023未实现，只开放已有森金连接路径，来源差异明确写在学习说明。
- 默认交用户覆盖编译包；没有完整编译、生产SQL、部署、用户实机或发布。
''')
put('tutor.md',r'''# 大白话教学：一次施法像一张订单

## 为什么上次没有直接开放
群攻一发打十个敌人，就像一张订单里有十件商品。“接下来三次技能”应数订单，不能数商品。DoT又像同一订单分六次送货，每次跳伤害仍属于原来的一次施法。
所以不能在每次伤害发生时扣次数，也不能只用技能ID存状态：同一个人连放两发火球，它们在空中是两个不同的对象。

## 本批各层做什么
1. Spell上的Snapshot保存`doctor`（巫医GUID）和`percent`（5）。成功发出时Launch只执行一次，把光环的一次额度交给这发法术。取消、失败停在前面，没有额度交接。
2. 法术施加DoT时把快照复制进Aura；每一跳从这个Aura读取。重新上无强化的同一个DoT，写入空快照，旧资格不会粘住。
3. 原生周期触发子技能只继承自己的父Aura，不再消耗；无关装备触发没有这个身份，自然不会借用。
4. 回血公式是`min(结算伤害, 命中前生命) × 5 / 100`。先使用64位乘法防溢出，再取整数，不把抵抗、吸收和过量部分当有效伤害。
5. 回血通过HealBySpell进入原生生命上限与治疗吸收；没有再走一遍法强和暴击，也不发新的治疗触发链。

## 关键代码逐句读
```cpp
struct Snapshot { uint64_t doctor=0; uint32_t percent=0; };
```
默认0表示没有强化，GUID是编号，不保存可能失效的角色指针。每次用ObjectAccessor按当前地图找角色，再检查还活着、同相位、还拥有天赋。

```cpp
result.doctor=chosen->GetCasterGUID().GetRawValue();
result.percent=5;
chosen->DropCharge();
```
先把来源复制出去再扣，第三次扣完可能删除光环；因此后面不能再访问chosen。副本仍在本次Spell里，第三次的群攻和周期不会因为光环消失而失去收益。

```cpp
if(!m_spellInfo->IsPositive()) m_spellAura->rebornConcoctions=rebornConcoctions;
```
这是覆盖而不是“非空才写”。非空才写会造成新一发没强化，却沿用旧DoT的回血资格。

持续时间只改八个配料附效，用整数`duration*120/100`，如18000毫秒变21600；不改常驻配料准备，不把所有治疗延长。

## 为什么还有Lua、SQL和DBC
三端都要认识新节点：C++决定真的学会/撤销，Lua决定按钮和请求，Characters保存过程核查点数并记账。新增index105使用bit117，总共118位。Lua用四段整数及十进制字符串传输，不能把整张大掩码转成浮点数。旧位不挪动，老方案原样保留。
DBC像游戏菜单与参数表：9003954是学到的被动；9003955是15秒3次的临时强化；9003956供回血日志使用。只有被动进技能书，隐藏效果不直接学习。
客户端和服务端的DBC分别在自己的原表追加，旧行与原字符串必须保留。同名文件不代表可互换。patch-ZA还带原来的LIGHT8B视觉，不能拿WD135早期Spell整表回盖。

## 如何自己验证
先测学习、保存、重登；再在缺血时测试三次单体技能；随后测试群攻和DoT；最后取消、第四发、切方案、另一位巫医以及其他配料做负向对照。
单看技能书出现图标只证明菜单存在，不证明战斗或保存正确。SQL在独立端口33536和独立临时目录运行，启动后先核对@@datadir，结束关闭；不是生产库。
这次先发现本地AuraEffect没有上游式GetSpellEffectInfo，改用本地GetSpellInfo/Effects/GetEffIndex。隔离语法检查又遇原目录头文件优先导致读旧Aura声明，最终显式预包含交付版本头文件解决，日志保留。六单元语法通过仍不等于完整服务端链接或实机成功。
''')
# Delivered excerpts with exact line numbers, avoiding stale pseudocode as implementation evidence.
annot=[]
for rel in ['src/server/game/Spells/RebornConcoctionsState.h','src/server/game/Spells/RebornWitchDoctorConcoctions.h']:
 annot.append('## '+rel+'\n```cpp\n'+'\n'.join(f'{i:3}: {line}' for i,line in enumerate((P/SF/rel).read_text().splitlines(),1))+'\n```')
put('实际交付代码索引.md','\n\n'.join(annot))
record='''# WD136A 调制大师候选记录 — 2026-10-07
读取项目AGENTS/rule/refResource/永久技能索引，应用plan-coa-class-migration、trace-and-port-coa-spell-resources（含method/wd3参考）、build-wotlk-three-build-projection。范围为复杂施法身份依赖的一项完整被动，未凑无关技能。
基线源码a986fc2e2005ebefc1907065933c634251c0fb7c；当前客户端/服务端按refResource路径，Spell以当前patch-ZA累计保留LIGHT8B/WD135UI，其他表独立核对。旧源/运行文件不改。
ID6026 -> 9003954/55/56；index105 bit117、118位。配料八附效+20%，蘑菇3次/15秒/5%。Spell/Aura对象快照，直接/周期结算伤害回收；高级酿造前置不自举。
201隔离SQL、31数据/Lua、6实际单元/Zs、实际辅助头文件替身测试及10000整数案例、14MPQ读回通过。未完整编译/部署/实机/commit/tag/Release，候选不晋升成功Skill。
过程问题：Python脚本加显式utf8编码；验证复用scenario134路径修正；本地AuraEffect API差异修正；隔离头文件覆盖顺序修正；默认沙箱Path.resolve拒绝，由受限端口/目录校验的独立SQL测试获准执行。保留失败日志，不声称解决其他运行问题。
'''
put('memory.md',record);put('phaseFixForNewChat.md',record+'\n下一步先让用户按README实测本批；通过后按release-tested-reborn-features发布。Master Mixologist29740与TikiSplash7133保持预览，之后按依赖逐批推进。当前官方6023另一连接尚未实现。\n')
put('能力与依赖台账.csv','node,original_spell,private_spell,status,dependencies\n6026,801690,9003954,candidate-tested-offline,"4005;12645;6014;prior23BrewingTE"\n6026,570064,9003955,hidden-buff,"real-cast-and-aura-snapshot"\n6026,570185,9003956,hidden-heal,"resolved-damage"\n29740,705864,,preview,"6026;cauldron-effect-scaling"\n7133,500053,,preview,"29754;button-replacement"\n')
for name in ['wd136_init.py','wd136_combat.py','wd136_ownership.py','wd136_data.py','wd136_verify.py','wd136_runtime_test.py','wd136_finish.py']:
 put('tools/'+name,Path('D:/000rebornWOW',name).read_bytes())
put('tools/README.md','这些文件记录本次生成与验证过程，使用本机路径及wd136_path指针，不是安装程序。安装只按根README覆盖，勿在生产目录运行生成器。\n')
manifest=[]
for folder in [SF,CF,'03_覆盖到服务端根目录','server_SQL','client_mpq输入_导入现有Patch-XA']:
 for f in sorted((P/folder).rglob('*')):
  if f.is_file():manifest.append({'path':f.relative_to(P).as_posix(),'bytes':f.stat().st_size,'sha256':hashlib.sha256(f.read_bytes()).hexdigest()})
put('installation_manifest.json',json.dumps(manifest,ensure_ascii=False,indent=2))
z=P.with_suffix('.zip');assert not z.exists()
with zipfile.ZipFile(z,'w',zipfile.ZIP_DEFLATED,6) as archive:
 for f in sorted(P.rglob('*')):
  if f.is_file() and f.suffix.lower() not in ['.exe','.obj','.pdb','.pyc'] and '__pycache__' not in f.parts:archive.write(f,P.name+'/'+f.relative_to(P).as_posix())
with zipfile.ZipFile(z) as archive:
 assert archive.testzip() is None
 for f in manifest:assert hashlib.sha256(archive.read(P.name+'/'+f['path'])).hexdigest()==f['sha256']
digest=hashlib.sha256(z.read_bytes()).hexdigest();z.with_suffix('.zip.sha256').write_text(digest+'  '+z.name+'\n',encoding='utf8')
entry='\n\n## 2026-10-07 WD136A 调制大师候选\n'+str(P)+'\n新增6026/9003954–56，118位；配料附效20%与3次15秒5%回复，真实施法/Aura归属。201隔离SQL、31数据/Lua、6单元语法及辅助代码替身/10000整数测试、14MPQ读回通过；未完整编译、部署、实机或发布。不晋升成功Skill。服务端本批仅Characters136 SQL，保留旧World依赖；详细安装/回滚见包内README。ZIP SHA256 '+digest+'。\n'
for name in ['updateMemory.md','refResourceAscend.md']:
 with (R/name).open('a',encoding='utf8') as f:f.write(entry)
with (R/'tutorMemory.md').open('a',encoding='utf8') as f:f.write(entry+'教学：'+str(P/'tutor.md')+'；核心是一次施法订单与多命中/多跳身份分离，数据双端独立。\n')
print(json.dumps({'zip':str(z),'sha256':digest,'installation_files':len(manifest),'bytes':z.stat().st_size},ensure_ascii=False))
