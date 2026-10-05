from pathlib import Path
import json,hashlib,zipfile,shutil
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');P=Path(Path('wd117_path.txt').read_text(encoding='utf8'));B=Path(Path('wd116_path.txt').read_text(encoding='utf8'))
def put(n,s):
 f=P/n;f.parent.mkdir(parents=True,exist_ok=True);f.write_text(s,encoding='utf8')
assert json.loads((P/'checks/mysql_results.json').read_text())['count']==354
assert len(json.loads((P/'checks/data.json').read_text()))==25
sha=json.loads((P/'research/head.json').read_text())['sha']
shutil.copy2(B/'server_SQL/01_CHARACTERS_WD116A_必须执行.sql',P/'rollback_WD116/01_CHARACTERS_WD116A_仅供旧节点状态回退.sql')
readme=f'''# WD117A 灵魂行者双技能联动——累计候选包

包含WD115A假死图标与强效混合整合、WD116A沃金守望，以及本批灵魂行者。WD115A、WD116A、WD117A都仍待用户实机确认；不将此前耗蓝提示通过等同于这些新能力通过。

## 覆盖步骤

1. 备份当前源码、客户端、服务端DBC及Characters数据库。覆盖01目录全部文件，自行重新编译。
2. 在Characters库执行server_SQL/01_CHARACTERS_WD117A_必须执行.sql。只用这一份最新累计Characters SQL，勿再套WD113/114/116旧过程。
3. 覆盖02客户端文件；将client_mpq输入_导入现有Patch-XA内文件按内部同名路径导入现有Patch-XA。备份MPQ放在Data目录外。
4. 覆盖03服务端文件。双端Spell来自各自基线，不能相互复制。重启服务端并完全退出客户端后重进。

无需先装WD115/116。本技能不新增World SQL，目录内既有World SQL是历史累计内容；WD114已安装环境无需为本节点重跑。未替用户编译、部署或改生产库。

## 新增节点

灵魂行者：节点9347，2级，每级1 AE，先投入9点基础通用AE。同层高级节点不算基础点数；原始节点无强制技能前置。保存并激活生效，三种专精可用；只有已学习沃金守望或迅捷神像时才产生相应收益。技能书被动9003857/9003858使用与天赋节点一致的既有官方图标，仅保留当前等级。

|灵魂行者等级|两技能持续|沃金减伤|沃金基础每秒恢复|迅捷移速、定身/减速抵抗|
|---|---|---|---|---|
|未学习|10秒|25%|2%最大生命|25%|
|1级|11秒|27%|2.2%最大生命|27%|
|2级|12秒|30%|2.4%最大生命|30%|

原始增幅为10%/20%。核心百分比光环采用整数，所以25×1.1最终为27；提示按这个实际整数结果显示。逐秒治疗在实际治疗量上增强，避免先把2.2%截成2%；仍受其他治疗/受疗修正及取整影响，满血会过量治疗。迅捷移速仍遵循原生同类光环叠加规则。

沃金守望冷却仍为120秒，不改变两技能冷却、范围、其他神像或普通伤害技能。等级变化会结束旧沃金光环及当前迅捷神像，需重新施放；不会重置冷却。切方案及重登恢复当前正式方案被动，草稿不授予效果。

原始技能描述标注基础值，下方绿色“当前”行显示服务端同步后的持续时间和效果；保持此前耗蓝刷新与过期响应过滤。治疗行明确是基础恢复比例，最终治疗量看战斗记录。

## 建议实测顺序

1. 先不点灵魂行者，验证WD116沃金守望：10秒、25%减伤、约每秒2%基础恢复、120秒冷却。
2. 保存一级和二级，分别核对上表，确认节点和技能书图标一致、只保留一个等级；无其他增益时测数值。
3. 迅捷神像分别持续11/12秒，附近队友获得27%/30%光环；定身/减速抵抗为概率，不能以一次命中判定失败。
4. 技能提示在升级、切换方案、重登后更新；快速悬停不同技能不串值。检查原巫毒/酿造方案和购买资格保留。
5. 切至无灵魂行者方案，旧增强神像及沃金光环结束，重新施放回到基础值；其他神像不受本次清理影响。
6. 同测累计WD115：假死图标一致，强效混合只采用两个来源中的最高等级、不重复叠加。

## 来源与边界

本次在线检查jealous-sound/azerothcore-wotlk-coa最新提交 {sha}、相关Issues/PR搜索及Completion/Auras源码，证据在research。官方节点9347对应504459/504636；上游Completion明确将SpiritWalkerOne第二效果BasePoints修正为9，因此采用一级10%、二级20%，不照搬旧一级15%数据。

本地将沃金持续及首效果限定到9003855，恢复仅限定自施9003856，迅捷只增强9003432/9003433链；避免相同修正重复应用。正式加点使用新bit78–79，80位范围同时覆盖C++、Lua精确十进制、Characters SQL，旧位不变。

已通过354项隔离MySQL检查、累计Lua方案回归、25项双端数据/源码检查、全部交付Lua语法、中英文提示与旧响应过滤测试；构建时检查全Spell字符串偏移。隔离MySQL已关闭。没有C++编译或游戏实测，实际伤害、治疗和神像效果待验收。

## 回滚

优先恢复安装前整套备份并重新编译旧源码。rollback_WD116保留改动前文件与旧SQL用于定位。已经保存9347节点后，旧schema会因未知节点拒绝；不要删节点、清空方案或绕过检查，应恢复一致的安装前数据库备份，或保留新schema等待专项迁移。勿单独回退过程或混用源码/DBC/Lua版本。
'''
put('README_覆盖与测试说明.md',readme)
put('memory.md',readme)
put('本批依赖与验收台账.csv','节点,名称,原始Spell,本地Spell,依赖,状态\n9347,灵魂行者,504459/504636,9003857/9003858,沃金守望与迅捷神像,候选待实机\n6042,沃金守望,504465,9003855/9003856,WD116基础效果,累计待实机\n通用,迅捷神像,既有实现,9003432/9003433,现有召唤和光环,本批增强待实机\n')
put('tutor.md','''# 灵魂行者联动移植步骤

1. 用节点映射定位原始两级Spell，再核对最新Completion；说明与原始BP冲突时保留上游修复证据。
2. 为被动建立精确目标修正：Vigil原生Duration/Effect1，Swift只在对应召唤AI创建时取正式被动等级。三个增益分量统一快照，不影响其他神像。
3. 治疗不要先截断2.2%基础百分比；仅对自施隐藏恢复的实际治疗量作整数乘除。不要全局放大治疗。
4. 同步AE位宽、双级读取上限、预算、前置、SQL保存/读取和技能恢复。等级变化清理旧效果，保留冷却与方案购买记录。
5. 独立双端DBC只新增两行被动及书页映射；旧两个父技能只改基础值标识文本。复用节点官方BLP，新增私有SpellIcon记录。
6. 扩展现有服务端数值协议，兼容旧响应，沿用序号、方案修订和缓存失效检查；测试中英文和快速切换。
7. 运行隔离数据库与Lua回归后交累计候选；用户编译和实机前不能登记验收成功。

实际使用项目永久Skill：plan-coa-class-migration、trace-and-port-coa-spell-resources、build-wotlk-three-build-projection。
''')
put('phaseFixForNewChat.md','WD117A累计候选，354隔离SQL及Lua/数据检查通过，未编译未实机。先收集WD115假死图标/强效混合、WD116沃金、WD117灵魂行者两级联动反馈，再推进依赖技能。保留用户已通过的耗蓝提示和既有方案；不要把候选登记成功。\n')
for n in ['wd117_build.py','wd117_research.py','wd117_tests.py','wd117_tooltip_tests.py','wd117_finish.py']:
 shutil.copy2(Path('D:/000rebornWOW')/n,P/'tools'/n)
manifest={f.relative_to(P).as_posix():hashlib.sha256(f.read_bytes()).hexdigest() for f in P.rglob('*') if f.is_file() and f.name!='SHA256.json'};put('SHA256.json',json.dumps(manifest,ensure_ascii=False,indent=2))
z=P.with_suffix('.zip');assert not z.exists()
with zipfile.ZipFile(z,'w',zipfile.ZIP_DEFLATED) as a:
 for f in P.rglob('*'):
  if f.is_file():a.write(f,f.relative_to(P))
with zipfile.ZipFile(z) as a:assert a.testzip() is None
digest=hashlib.sha256(z.read_bytes()).hexdigest()
note=f'''\n\n## 2026-10-02 WD117A 灵魂行者双技能联动（候选，未编译未实机）
在WD116累计基础新增9347双级9003857/58，10%/20%增强沃金及迅捷持续和效果，精确80位保存。一级整数光环27%、二级30%；恢复在实际治疗量上乘10%/20%，不提前截断2.2%。等级变化清旧增强效果不重置冷却。复用节点官方图标；服务端提示支持持续、减伤、基础逐秒恢复和迅捷增幅。
上游commit {sha}，Completion将SpiritWalkerOne第二效果修正9（10%）。354隔离SQL、累计Lua、25数据/源码及全部Lua语法、数值提示回归通过。WD115/116/117均仍候选，先验收再推进其他依赖。
使用plan-coa-class-migration、trace-and-port-coa-spell-resources、build-wotlk-three-build-projection。覆盖说明：[{P.name}]({P.as_posix()}/README_覆盖与测试说明.md)；教学：[{P.name}/tutor.md]({P.as_posix()}/tutor.md)。ZIP SHA256 `{digest}`。
'''
for rel in ['updateMemory.md','updateListAscend.md','refResourceAscend.md','beascendskills/skillsAscend.md','beascendtutor/tutorsAscend.md','beascendskills/plan-coa-class-migration/SKILL.md','beascendskills/trace-and-port-coa-spell-resources/SKILL.md','beascendskills/build-wotlk-three-build-projection/SKILL.md','beascendtutor/plan-coa-class-migration/TUTOR.md','beascendtutor/trace-and-port-coa-spell-resources/TUTOR.md','beascendtutor/build-wotlk-three-build-projection/TUTOR.md']:
 f=R/rel;assert f.exists()
 with f.open('a',encoding='utf8') as out:out.write(note)
print(z);print(digest);print(len(manifest),'files',z.stat().st_size,'bytes')
