from pathlib import Path
import datetime, hashlib, json, re, struct, zipfile, urllib.request, urllib.parse
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO')
stamp=datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=-7))).strftime('%Y%m%d%H%M')
P=R/f'000Ascendupdate/000Ascendupdate{stamp[:8]}/codexfix_{stamp}_阶段WD122B_范围目标枚举编译修正'
P.mkdir(parents=True,exist_ok=False)
Path('wd122b_path.txt').write_text(str(P),encoding='utf8')
def put(name,text):
 p=P/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text,encoding='utf8')
sha=lambda b:hashlib.sha256(b).hexdigest()
header=R/'beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots/src/server/shared/SharedDefines.h'
h=header.read_text(encoding='utf-8-sig')
assert re.search(r'TARGET_UNIT_CASTER_AREA_RAID\s*=\s*56\b',h)
old=b'TARGET_UNIT_SRC_AREA_RAID';new=b'TARGET_UNIT_CASTER_AREA_RAID'
rel=Path('modules/mod-reborn-witchdoctor/src/RebornWitchDoctorBrewingFoundation.inc')
checks={'header':str(header),'header_sha256':sha(header.read_bytes()),'enum_value':56,'variants':{}}
for v in ['122','123']:
 b=Path(Path(f'wd{v}_path.txt').read_text().strip());src=b/'01_覆盖到源代码根目录'/rel;raw=src.read_bytes()
 assert raw.count(old)==1
 fixed=raw.replace(old,new)
 for token in set(re.findall(rb'\bTARGET_[A-Z0-9_]+\b',fixed)):
  assert re.search(r'\b'+token.decode()+r'\s*=',h),token
 for prefix,data in [(f'WD{v}A/01_覆盖到源代码根目录',fixed),(f'rollback/WD{v}A',raw)]:
  dst=P/prefix/rel;dst.parent.mkdir(parents=True,exist_ok=True);dst.write_bytes(data)
 dbc_checks=[]
 for root in ['03_覆盖到服务端根目录','client_mpq输入_导入现有Patch-XA']:
  found=list((b/root).rglob('Spell.dbc'));assert len(found)==1,found
  data=found[0].read_bytes();magic,n,f,size,ss=struct.unpack_from('<4s4I',data);assert magic==b'WDBC'
  rows=[struct.unpack_from('<'+'I'*f,data,20+i*size) for i in range(n) if struct.unpack_from('<I',data,20+i*size)[0]==9003866]
  assert len(rows)==1 and rows[0][86]==56
  dbc_checks.append({'file':str(found[0]),'pulse':9003866,'targetA':56})
 checks['variants'][v]={'baseline':str(b),'before':sha(raw),'after':sha(fixed),'only_change':'TARGET_UNIT_SRC_AREA_RAID -> TARGET_UNIT_CASTER_AREA_RAID','dbc':dbc_checks}
put('checks/static.json',json.dumps(checks,ensure_ascii=False,indent=2))
research=[]
try:
 def get(url):return urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'WD122B-compatibility-audit'}),timeout=15).read()
 api='https://api.github.com/repos/jealous-sound/azerothcore-wotlk-coa'
 head=json.loads(get(api+'/commits/HEAD'));commit=head['sha'];put('research/head.json',json.dumps(head))
 upstream=get(f'https://raw.githubusercontent.com/jealous-sound/azerothcore-wotlk-coa/{commit}/src/server/shared/SharedDefines.h').decode()
 put('research/SharedDefines.h.txt',upstream)
 q='repo:jealous-sound/azerothcore-wotlk-coa TARGET_UNIT_SRC_AREA_RAID'
 result=get('https://api.github.com/search/issues?q='+urllib.parse.quote(q)).decode();put('research/issues_and_prs.json',result)
 research.append(f'在线 HEAD {commit}；相关枚举 Issues/PR 搜索结果 {json.loads(result).get("total_count")} 项。当前本地核心头文件为适配依据。')
except Exception as e:
 research.append(f'本次在线核对未完成：{type(e).__name__}: {e}。不宣称上游最新已核对；沿用历史来源只作背景。本修复依据当前本地 SharedDefines.h，不变更技能机制。')
readme='''# WD122B 范围目标枚举编译修正

修正 WD122A 使用不存在的 TARGET_UNIT_SRC_AREA_RAID 导致模块编译失败。当前核心正确枚举为 TARGET_UNIT_CASTER_AREA_RAID = 56，与双端蘑菇脉冲 9003866 的目标字段一致。

## 安装（两个版本只能选一个）

你当前覆盖的是 WD122A：将 `WD122A/01_覆盖到源代码根目录` 内的 modules 文件夹覆盖到你实际编译的源码根目录。

只有已经覆盖 WD123A 累计源码时，才选 `WD123A/01_覆盖到源代码根目录`。不要把两个分支依次覆盖；WD122A 版本不含 WD123A 泼洒逻辑。

保持原有 RelWithDebInfo 和平台配置，重新生成解决方案，先确保 modules 项目成功，再链接 worldserver。modules.lib 缺失很可能是前面模块编译失败的后果；不要下载库文件、改链接路径或手工创建空库。如果仍失败，从生成输出中的第一条编译错误继续查。

本包仅一处 C++ 枚举名称修正。无需新 SQL、DBC、Lua 或 MPQ；原累计包要求的安装步骤仍需完成。没有替你编译、生成 EXE 或部署。

## 验证与回滚

两种源码分别校验：只替换一个枚举标识符；目标符号在当前核心确实定义为56；客户端和服务端9003866目标均为56。ZIP完整性校验通过后交付。完整C++编译和游戏行为仍待你验证。

编译后继续测试丛林绽放5人/6秒、丛林医师8人/4秒，以及切换方案。WD123A用户另测泼洒药水。

rollback 内为两个原始版本的单文件备份，仅用于撤销本次改动，恢复会重新带回该编译错误；不要覆盖到另一版本。
'''
put('README_覆盖与测试说明.md',readme)
tutor='''# 教学：枚举名字和数值必须同时对上

本次旧代码：`SpellObjectAreaTargetSelectFn(spell_reborn_wd120_brewing::PulseTargets, EFFECT_0, TARGET_UNIT_SRC_AREA_RAID)`。

改为：`SpellObjectAreaTargetSelectFn(spell_reborn_wd120_brewing::PulseTargets, EFFECT_0, TARGET_UNIT_CASTER_AREA_RAID)`。

第一个参数指定筛选目标的函数；EFFECT_0指定第一个法术效果槽；最后的枚举指定这条回调匹配的目标类型。枚举是数字的有名常量，不是可随意拼写的描述。SharedDefines.h 定义正确名称值56；DBC里同一位置也为56，二者才能匹配。没有新增枚举、硬填数字或改变目标规则。

编译器先把源文件生成对象文件，再把模块打包成modules.lib，最后链接worldserver。第一步因名字不存在而失败，后续可能就找不到库。因此先修第一条错误。缺库不是技能SQL错误。

之前静态核对覆盖了目标数值，却漏查符号是否在目标核心声明，这是本次交付遗漏。数字模型和SQL测试不能证明C++能编译。以后新增枚举先查实际头文件定义；不使用被忽略文件的默认搜索结果判断符号不存在，可用rg --hidden。

tools中的Python先复制原文件作为回滚，断言错误名称只出现一次，再按字节替换；分别检查WD122和WD123，避免把后者新增功能覆盖掉。SHA256用于确认文件身份；checks记录双端DBC和头文件证据。没有运行编译器，仍需用户生成解决方案确认。
'''
put('tutor.md',tutor)
put('memory.md','WD122A 用户报告编译失败；WD123A继承同一错误。两批不得登记编译通过。本次使用项目 trace-and-port-coa-spell-resources Skill，只作源码兼容修复。历史ZIP和实际源码目录未改。\n\n'+'\n'.join(research)+'\n\n'+tutor)
put('handoff.md','当前用户基线WD122A，优先用WD122A分支。已确认本地枚举错误，交付修正候选；等待用户编译/实测。WD123A同修但未宣称安装或验收。保留WD121B冷却修正，未改SQL/DBC/Lua。\n')
put('tools/wd122b_fix.py',Path(__file__).read_text(encoding='utf8'))
manifest={str(p.relative_to(P)):sha(p.read_bytes()) for p in P.rglob('*') if p.is_file()}
put('SHA256.json',json.dumps(manifest,ensure_ascii=False,indent=2))
z=P.with_suffix('.zip')
with zipfile.ZipFile(z,'w',zipfile.ZIP_DEFLATED) as f:
 for p in P.rglob('*'):
  if p.is_file():f.write(p,str(p.relative_to(P)))
with zipfile.ZipFile(z) as f:assert f.testzip() is None
entry=f'\n\n## {stamp} WD122B 编译枚举修正（待用户编译）\nWD122A用户报告未声明目标枚举，WD123A亦继承。当前核心TARGET_UNIT_CASTER_AREA_RAID=56；两个隔离单文件版本仅替换错误符号，双端9003866目标56核对一致。modules.lib缺失很可能是连带错误。之前静态检查遗漏枚举声明，不能声称已编译通过；本次亦未编译/部署/实机。保留原ZIP和生产文件。\n[说明]({P.as_posix()}/README_覆盖与测试说明.md) · [教学]({P.as_posix()}/tutor.md)。ZIP SHA256 `{sha(z.read_bytes())}`。使用trace-and-port-coa-spell-resources，符号存在性检查纳入后续审计。\n'
for name in ['updateMemory.md','updateListAscend.md','tutorMemory.md','refResourceAscend.md','beascendskills/skillsAscend.md','beascendskills/trace-and-port-coa-spell-resources/SKILL.md','beascendtutor/tutorAscend.md','beascendtutor/trace-and-port-coa-spell-resources/TUTOR.md']:
 with (R/name).open('a',encoding='utf8') as f:f.write(entry)
(P.parent/'phaseFixForNewChat_WD122B.md').write_text(entry,encoding='utf8')
print(json.dumps({'package':str(z),'sha256':sha(z.read_bytes()),'checks':checks,'online':research},ensure_ascii=False,indent=2))
