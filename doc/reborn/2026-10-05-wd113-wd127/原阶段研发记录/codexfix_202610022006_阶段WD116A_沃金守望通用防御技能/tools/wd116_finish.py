from pathlib import Path
import json,shutil,hashlib,zipfile,subprocess
from wd19_common import dbc
from wd9a_storm import Archive
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');P=Path(Path('wd116_path.txt').read_text(encoding='utf8'));B=Path(Path('wd114_path.txt').read_text(encoding='utf8').strip());V=Path(Path('wd115_path.txt').read_text(encoding='utf8'));C=R/'beascendclient/newrebornWOWli20260929beAscend';S=R/'beascendserver/wowshub_playerbot_npcbot_newrace20260929Ascend'
def put(name,s):
 p=P/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(s,encoding='utf8')
results=json.loads((P/'checks/mysql_results.json').read_text());assert results['count']==342
duration=dbc((S/'Data/dbc/SpellDuration.dbc').read_bytes())[0];assert duration[1][1]==10000
a=Archive(C/'Data/patch-XA.MPQ');raw=a.read('DBFilesClient\\SpellDuration.dbc');a.close()
if raw:assert dbc(raw)[0][1][1]==10000
put('checks/duration.txt','Server DurationIndex1=10000 ms; client '+('Patch-XA DurationIndex1=10000 ms.' if raw else 'uses native DurationIndex1; no custom duration record written.')+'\n')
put('tools/check_syntax.lua','for i=1,#arg do assert(loadfile(arg[i])) end\nprint("All packaged Lua syntax passed")\n')
lua=R/'beascendBuild/modules/mod-ale/src/lualib/lua/RelWithDebInfo/lua52_interpreter.exe'
files=list((P/'02_覆盖到客户端根目录').rglob('*.lua'))
run=subprocess.run([str(lua),str(P/'tools/check_syntax.lua')]+[str(f) for f in files],capture_output=True,encoding='utf8',errors='replace');assert run.returncode==0,run.stderr;put('checks/syntax.txt',run.stdout)
inc=(P/'01_覆盖到源代码根目录/modules/mod-reborn-witchdoctor/src/RebornWitchDoctorAllocation.inc').read_text(encoding='utf8')
assert 'if(family==0) rank=std::max(rank,AERank(mask,67));' in inc
assert 'if(spec==3) return mask==0;' in inc
assert 'else if(!p->HasSpell(9003855)) p->learnSpell(9003855);' in inc
assert 'CastSpell(p,9003855' not in inc
# Capture targeted dependency and donor evidence, no live service changes.
put('本批依赖与验收台账.csv','能力,节点,来源Spell,本地Spell,分类,获得方式,依赖,本批状态\n沃金守望,6042,504465,9003855,巫毒书页/通用树,9基础AE后1AE,原生Aura87+Aura23+Effect136,候选待实机\n沃金恢复,隐藏,681004,9003856,不入技能书,父光环每秒触发,自身最大生命值与治疗修正,候选待实机\n灵魂行者,9347,504459/504636,待后续,通用树,预览,沃金守望和迅捷神像,本批不开放\n')
shutil.copy2(B/'server_SQL/01_CHARACTERS_WD114A_必须执行.sql',P/'rollback_WD115/01_CHARACTERS_WD114A_仅供旧节点状态回退.sql')
sha=json.loads((P/'research/head.json').read_text())['sha']
readme=f'''# WD116A 沃金守望累计测试包

新增通用主动技能“沃金守望 / Vol'jin's Vigil”（节点6042，技能9003855）。本包累计保留WD114功能、已安装的数值提示与技能书定位文件，以及WD115A假死图标、强效混合同源整合。WD115A仍待用户实测，不因打入累计包而登记通过。

## 安装顺序

先停服、退出客户端，备份源码、客户端MPQ、服务端DBC和Characters数据库。
1. 覆盖 `01_覆盖到源代码根目录` 全部文件，再自行编译。
2. 在 **Characters** 库执行 `server_SQL/01_CHARACTERS_WD116A_必须执行.sql`。这是新增节点保存所必需的累计SQL，不要再执行WD113/WD114旧版本。目录内其他World SQL为此前累计内容，已经安装WD114的环境无需因本技能重跑。
3. 覆盖 `02_覆盖到客户端根目录`。导入 `client_mpq输入_导入现有Patch-XA` 的DBFilesClient文件到现有Patch-XA同名内部路径；MPQ备份放Data目录外。
4. 覆盖 `03_覆盖到服务端根目录` 后启动。客户端与服务端Spell独立生成，不能互相复制替代。

不必先装WD115A再装本包。请保持整套文件版本一致，避免新源码配旧保存过程导致方案同步失败。本次未替你编译、部署或写生产库。

## 技能与学习

先投入9点基础通用AE，再花1 AE学习；同层高级节点不能互相凑前置。保存并激活后生效，三种专精都可使用。在巫毒技能书中找“沃金守望”；天赋节点和技能书使用同一官方手套图标。

瞬发、自身、无耗蓝，冷却120秒。10秒内受到的伤害降低25%；每秒触发一次恢复，基础量为自身最大生命值的2%。实际恢复走原生治疗加成/受疗修正，满血产生过量治疗，所以不能单凭血条总计判断是否恢复20%。不是免疫，也不保证抵消所有特殊脚本伤害。

新技能只在正式活动方案拥有；浏览和草稿不授予。切换到不含它的方案撤销技能和正在运行的光环，不改变购买方案或其他已存节点。隐藏治疗技能9003856不加入技能书。

## 测试重点

1. 保存后技能书出现且图标与节点一致；拖入动作条可以施放。
2. 受伤且无其他恢复/受疗增益时检查约每秒一次的2%最大生命恢复，共10秒；同一攻击来源对比开启前后的伤害。
3. 检查2分钟冷却、满血使用、结束后不继续恢复；测试前后保持装备及其他减伤相同。
4. 切换不含该技能的方案后光环停止；切回、重登恢复学习状态。检查原巫毒和酿造方案、购买资格仍在。
5. 同测WD115A：假死图标一致；强效混合只显示当前最高等级，不重复叠加。

## 来源、适配与验证范围

社区最新核对提交 `{sha}`。官方20260925 Spell504465为25%减伤/120秒CD；描述引用681004的2%最大生命治疗及503598的1000毫秒周期。上游Completion把第二效果转周期，Auras每秒施放VigilHeal。这里用WotLK原生Aura23触发Effect136实现同一恢复链，避免重复proc治疗。

技能图标沿当前项目节点Icon复用官方BLP。防御视觉暂复用现有原生树皮术视觉，未移植CoA专属动态视觉；这不改变技能名或施法形态。灵魂行者及迅捷神像增强留待后续，本批不开放空效果节点。

已通过：342项隔离MySQL检查、累计Lua方案/精确高位传输回归、新节点前置/点数/跨专精检查、20项双端数据检查、所有交付Lua语法、全Spell字符串偏移验证。旧Spell行及字符串前缀保持原值，新增9003855/56；未编译、未实机，伤害/治疗数值以实测为最终验收。

## 回滚

优先恢复安装前整套备份，并重新编译旧源码。rollback_WD115保存本次修改前文件供定位。若已经保存新节点6042，旧WD114 SQL会因未知节点主动拒绝；不要删节点、清空方案或强行绕过守卫。应恢复一致的安装前Characters备份，或保留新schema等待专项回退方案，不能只降级数据库过程。不要混用累计目录中的旧版SQL。
'''
put('README_覆盖与测试说明.md',readme)
put('memory.md',readme+'\n开发检查曾发现旧测试把bit77当越界，现按新上限78更新；首次隔离SQL测试缺历史schema夹具，补齐后342项通过。全程仅隔离端口33500，测试MySQL已关闭。\n')
put('tutor.md','''# 沃金守望移植步骤

1. 按节点6042找到Spell504465；顺着描述引用追681004与503598，而不是把dummy42误当完整周期机制。减伤BasePoints -26加DieSides1为-25；治疗BasePoints1加DieSides1为2。
2. 原生Aura87负责按学派掩码127减伤。第二效果改为周期触发Aura23、1000ms，触发隐藏9003856的Effect136，按被治疗者最大生命计算后应用原生治疗修正。目标均为施法者，隐藏治疗不再触发父技能，不会自递归。
3. 父技能和隐藏治疗分开；只给父技能SkillLineAbility。独立SpellIcon引用天赋节点已有图标，不覆盖公共图标。双端从各自累计基线追加行，原字符串前缀保留。
4. 方案索引68使用bit77；C++128位、Lua四limb十进制、SQL decimal上限同步到78位。保留前68个节点顺序。9基础AE前置排除新节点本身，所有既有同层前置也排除它，防止凑点漏洞。
5. 保存过程精确恢复新位并禁止免费减少已保存加点；重装SQL不改变原行。切方案移除技能时同时结束持续光环，不主动施放防御技能。
6. 本次使用plan-coa-class-migration、trace-and-port-coa-spell-resources、build-wotlk-three-build-projection永久Skill。新能力候选，不能把隔离测试替代用户实机验收。配套源码/DBC/SQL都在本包，可逐文件与rollback_WD115对比。
''')
put('phaseFixForNewChat.md','本批WD116A候选，WD115A未实机确认。先收集沃金守望基础减伤/逐秒恢复/冷却/保存反馈，再审计灵魂行者增强，不能先开放依赖未验收的全部分支。旧假死基本通过；耗蓝提示/洛阿强化已通过；其他阶段状态查总记忆。\n')
for n in ['wd116_build.py','wd116_research.py','wd116_tests.py','wd116_finish.py']:shutil.copy2(Path('D:/000rebornWOW')/n,P/'tools'/n)
manifest={f.relative_to(P).as_posix():hashlib.sha256(f.read_bytes()).hexdigest() for f in P.rglob('*') if f.is_file() and f.name!='SHA256.json'};put('SHA256.json',json.dumps(manifest,ensure_ascii=False,indent=2))
z=P.with_suffix('.zip');assert not z.exists()
with zipfile.ZipFile(z,'w',zipfile.ZIP_DEFLATED) as archive:
 for f in P.rglob('*'):
  if f.is_file():archive.write(f,f.relative_to(P))
with zipfile.ZipFile(z) as archive:assert archive.testzip() is None
digest=hashlib.sha256(z.read_bytes()).hexdigest()
note=f'''\n\n## 2026-10-02 WD116A 沃金守望通用防御技能（候选）
新增节点6042->9003855，隐藏治疗9003856；先9基础AE后1AE，跨专精，bit77精确存储。原生25%减伤、1秒一次2%最大生命治疗、10秒持续、120秒冷却；受原生治疗修正。官方图标与天赋一致，视觉兼容复用原生树皮术，未宣称CoA独有特效。
累计WD114与WD115整合，保留数值提示、原方案和购买资格。WD115仍未用户实测。使用plan-coa-class-migration、trace-and-port-coa-spell-resources、build-wotlk-three-build-projection。来源commit {sha}，官方504465/681004/503598，上游周期修正已查。灵魂行者未开放。
342隔离SQL、累计Lua、20数据检查及全部Lua语法通过；未编译未部署未实机。初次测试因缺schema夹具中止，补齐后通过；旧bit77越界测试更新为78。不能将候选登记成功。需要Characters WD116A SQL，旧版本unknown-node守卫禁止带新节点回退。
[覆盖说明]({P.as_posix()}/README_覆盖与测试说明.md) · [教学]({P.as_posix()}/tutor.md)；ZIP SHA256 `{digest}`。
'''
for rel in ['updateMemory.md','updateListAscend.md','refResourceAscend.md','beascendskills/skillsAscend.md','beascendtutor/tutorsAscend.md','beascendskills/plan-coa-class-migration/SKILL.md','beascendskills/trace-and-port-coa-spell-resources/SKILL.md','beascendskills/build-wotlk-three-build-projection/SKILL.md','beascendtutor/plan-coa-class-migration/TUTOR.md','beascendtutor/trace-and-port-coa-spell-resources/TUTOR.md','beascendtutor/build-wotlk-three-build-projection/TUTOR.md']:
 f=R/rel;assert f.exists()
 with f.open('a',encoding='utf8') as out:out.write(note)
print(z);print(digest);print('Files',len(manifest),'bytes',z.stat().st_size)
