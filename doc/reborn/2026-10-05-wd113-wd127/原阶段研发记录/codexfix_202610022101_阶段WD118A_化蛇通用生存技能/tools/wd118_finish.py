from pathlib import Path
import json,hashlib,zipfile,shutil
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');P=Path(Path('wd118_path.txt').read_text(encoding='utf8'));B=Path(Path('wd117_path.txt').read_text(encoding='utf8'))
def put(n,s):
 f=P/n;f.parent.mkdir(parents=True,exist_ok=True);f.write_text(s,encoding='utf8')
results=json.loads((P/'checks/mysql_results.json').read_text());assert results['count']>=367
assert len(json.loads((P/'checks/data.json').read_text()))==30
sha=json.loads((P/'research/head.json').read_text())['sha']
shutil.copy2(B/'server_SQL/01_CHARACTERS_WD117A_必须执行.sql',P/'rollback_WD117/01_CHARACTERS_WD117A_仅供安装前状态回退.sql')
put('rollback_WD117/02_WORLD_仅撤销本批绑定.sql',"DELETE FROM spell_script_names WHERE spell_id=9003859 AND ScriptName='aura_reborn_wd118_slither';\n")
readme=f'''# WD118A 化蛇通用生存技能——累计候选包

本包在WD117A累计基线上新增化蛇（Slither），包含WD115假死图标/强效混合整合、WD116沃金守望、WD117灵魂行者。WD115–118新变更仍待用户实机验收；既有用户确认的基本能力保留原验收范围。

## 安装

1. 备份当前源码、客户端、服务端DBC及Characters库。将01全部覆盖到源码根目录，自行重新编译。
2. **Characters库**执行 `server_SQL/01_CHARACTERS_WD118A_必须执行.sql`，替代旧累计保存过程。不要再执行WD113/114/117旧Characters SQL。
3. **World库**执行 `server_SQL/02_WORLD_WD118A_必须执行.sql`。这是本批光环生命周期脚本绑定，必须执行；不能只装DBC。其他历史World SQL是累计旧内容，已装WD114环境不必因本技能重跑。
4. 覆盖02客户端目录；把client_mpq输入_导入现有Patch-XA中的文件按内部路径导入现有Patch-XA。MPQ备份放Data目录外。
5. 覆盖03服务端目录，再重启服务端并完全退出客户端重进。双端DBC各自独立生成，不能互相复制。

无需先装WD117再装本包。默认交付覆盖包，未替用户编译、部署或修改生产数据库。World数据仅只读核对蛇模型；测试使用独立临时MySQL实例。

## 新技能

通用树节点29306，30级、先9点基础通用AE，再花1 AE。保存并激活后，在巫毒技能书中出现“化蛇 / Slither”（9003859），图标与天赋节点一致。三种专精可使用，书页类别不代表专精限制。

- 化为现有蛇模型，解除施放前已有的定身与减速。
- 移动速度提高80%，持续5秒；冷却60秒，1.5秒公共冷却。
- 期间不能攻击或施法，可以右键取消。
- 原始配套效果：远程攻击及法术对你的命中率降低100个百分点，游泳速度提高80%。这不是全伤害免疫：近战、已有持续伤害，以及忽略命中判定的特殊效果需分别测试。
- 只解除已有控制，不提供持续的定身/减速免疫。
- 原始费用为25法力加19%基础法力，走本核心正常费用计算；技能书/动作条的耗蓝通过现有服务端数值协议同步。

隐藏效果9003860不入技能书。到期、取消、死亡移除或切到不含化蛇的方案时，父形态与配套闪避效果一起清理，不直接强制覆盖其他形态的显示ID。

## 下午建议测试

1. 保存节点后看图标、书页、拖入动作条；切换、重登后学习状态仍正确。检查原巫毒/酿造方案、购买资格和已有加点仍在。
2. 地面无其他变形时施放：出现蛇形，移动变快，5秒后恢复，60秒冷却。水中检查游泳增速。
3. 被定身或减速时施放应解除已有影响；期间尝试攻击、普通施法均被阻止。等公共冷却结束后再测，避免把GCD误当沉默。
4. 右键取消后立即恢复正常施法/攻击；再检查自然到期、死亡、切方案，不残留速度、沉默或远程/法术闪避。
5. 分别用近战、普通远程攻击、需要命中判定的法术、预先挂上的持续伤害测试，不能只靠一次未命中宣称无敌。
6. 同测累计WD116基础沃金与WD117灵魂行者：无天赋10秒/25%/2%，一级11秒/27%/2.2%，二级12秒/30%/2.4%。回血为基础比例，受实际治疗修正。

## 来源与本地适配

官方客户端20260925：500947，配套806295；节点29306。社区仓库最新核对commit `{sha}`。PR6192已于2026-10-02合并，修正了删除禁止攻击/施法效果、但残留负面标记而无法取消的问题。本地保留Aura60并只清除两条私有法术的负面标记，避免影响其他法术。社区自述实测不等于本项目实测。

上游链接：[PR6192](https://github.com/jealous-sound/azerothcore-wotlk-coa/pull/6192)、[问题6019](https://github.com/jealous-sound/azerothcore-wotlk-coa/issues/6019)、[问题4092](https://github.com/jealous-sound/azerothcore-wotlk-coa/issues/4092)。完整搜索、PR差异及当前代码保存在research。

本地复用World中2914蛇模板和当前客户端已有模型1206/2957/2958/6303，未重写模板或导入其他种族模型。节点官方BLP已有，新增独立图标记录910119。没有移植CoA独有粒子链，父技能Visual为0，变形由原生Transform负责。

为避免未映射公共类别误伤其他法术，使用独立60秒技能冷却，不照搬CoA类别641。费用、持续、速度、变形、禁止攻击施法和配套命中修正依据官方行。化蛇节点30级取原始Spell等级。新bit80接在灵魂行者bit78–79之后，C++/Lua/SQL上限同步81位。

## 验证与回滚

通过{results['count']}项隔离SQL检查、累计Lua方案回归、30项双端数据/源码检查、全部交付Lua语法、耗蓝提示和已有数值同步回归。旧Spell/SkillLineAbility行及字符串池前缀保持原值，新技能追加。未编译、未实机；形态、攻击限制、实际速度及战斗命中仍待你验收。

安装前整套备份是首选回滚方案。rollback_WD117保留改动前文件；旧Characters过程遇到新增29306节点会拒绝，不要删节点、清空方案或绕过校验。若已保存新节点，恢复一致的安装前数据库备份，或保留新schema等待专项迁移；不要只降级SQL。
'''
put('README_覆盖与测试说明.md',readme)
put('memory.md',readme+'''\n开发排错：初次只读World查询使用旧modelid1字段失败，随后按当前creature_template_model读到2914四种模型。原始patch-T不含SpellDuration，5秒由上游PR契约和当前Duration28核对。两个尝试的上游文件名404，未把缺失文件当证据。初次SQL全量运行在旧20级节点用例失败；定向调用成功；新等级拒绝分支补显式ROLLBACK，再跑全量结果见checks。提示测试最初误把已加载enUS实例期望为中文格式，修正测试预期后通过。未修改已交付旧ZIP。\n''')
put('本批依赖与验收台账.csv','节点,技能,原始Spell,本地Spell,依赖,获得方式,状态\n29306,化蛇,500947,9003859,原生Aura31/56/60及蛇模板2914,30级9基础AE后1AE,候选待实机\n隐藏,化蛇闪避,806295,9003860,父光环生命周期/命中及游泳Aura,父光环触发,候选待实机\n')
put('tutor.md','''# 化蛇：从技能说明到完整生存技能

把技能想成一张短时通行证：主光环管外形、移速和行为限制，附属光环管远程命中与游泳；证件过期时，附属权限也必须撤销。

1. 先确认来源。节点29306指向500947，说明又引用806295。只复制主行会漏掉远程/法术闪避。原始BP79加DieSides1才是80%；负数以无符号32位存储，4294967195解释为-101，再加1为-100。不要把整数直接当百分比。
2. Python构建器从WD117副本开始，每次给新法术分配私有ID，先assert不存在。Spell字符串不是文本本身，而是池内偏移；新字符串追加到末尾，不能拿客户端偏移去覆盖服务端。pack按WDBC头、固定行、字符串池顺序写出；校验全部偏移在池内。
3. `r[95:98]=[31,56,60]`这三个光环类型分别是速度、变形、禁止攻击与施法。变形MiscValue2914是生物模板ID，不是模型ID。本项目当前模型通过creature_template_model映射得到，不能用旧版本modelid1列猜。
4. 上游旧代码删除第三效果会让蛇仍能攻击；又因负面标记留着不能取消。这里的`info->AttributesCu &= ~SPELL_ATTR0_CU_NEGATIVE`仅在两个私有ID上清标记，保留实际效果。位运算像开关板，只关掉负面标记，不拆掉沉默和缴械逻辑。
5. AuraScript Apply先调用`RemoveMovementImpairingAuras(true)`：true包含定身；然后AttackStop停止已有攻击，最后触发配套9003860。原生Aura60负责禁止后续攻击/施法，不用每秒循环强制打断。Remove按同一施法者GUID清附属光环，避免清理别人的效果。
6. World SQL把9003859关联到注册好的AuraScript，INSERT IGNORE使重跑不重复。只写C++而不执行绑定SQL，回调不会运行，所以它不是可选步骤。Characters SQL是另一职责：保存节点、校验等级/点数/专精，和World技能绑定不能混库。
7. 新节点index70必须放bit80，不能套旧index+9公式，否则撞上灵魂行者二级位。C++用128位容器，Lua用四个32位段，网络用十进制字符串，SQL用DECIMAL精确还原；测试专门同时保存灵魂行者二级与化蛇。
8. 事务像一次完整记账：检查失败必须ROLLBACK，成功才COMMIT。本次等级不足分支显式回滚。保存规则禁止免费减少已存加点；切方案只管理技能和光环，不改购买资格。
9. 数值提示调用服务端CalcPowerCost，不能由Lua拿基础法力再估算。沿用序号/版本校验避免快速移动鼠标把上个技能的费用贴到化蛇上。

工具：Python3.9负责独立文件增量、DBC解析、哈希与打包；项目Lua5.2解释器执行客户端逻辑桩；MySQL8临时端口33500验证保存过程，不连接生产库写入。Lua桩只证明状态算法，SQL只证明存档，均不能替代C++编译与游戏战斗测试。

实操：先无节点存一套方案，再点化蛇保存；测试等级29拒绝与30允许；给另一套方案保留原样；切换检查增益结束。游戏内用相同装备和攻击来源分别测近战、远程、法术，记录取消前后；正确结果既包括该有效果，也包括无关技能不受影响。

本批使用永久Skill：plan-coa-class-migration、trace-and-port-coa-spell-resources、build-wotlk-three-build-projection；尚未实机，不晋升已验证配方。
''')
put('phaseFixForNewChat.md','WD118A累计候选：化蛇29306/9003859，配套9003860，level30、9基础AE+1AE、bit80。最新社区PR6192保留Aura60并清负面标记；本包必须Characters WD118+World脚本绑定+双端DBC+Lua+重编译。未编译未实机；先收集WD115–118反馈。酿造配料/药剂投掷仍有依赖缺口，本批不开放对应空效果节点。\n')
for n in ['wd118_build.py','wd118_slither_research.py','wd118_extract.py','wd118_tests.py','wd118_finish.py']:shutil.copy2(Path('D:/000rebornWOW')/n,P/'tools'/n)
manifest={f.relative_to(P).as_posix():hashlib.sha256(f.read_bytes()).hexdigest() for f in P.rglob('*') if f.is_file() and f.name!='SHA256.json' and f.name!='test_mysql_debug.py'};put('SHA256.json',json.dumps(manifest,ensure_ascii=False,indent=2))
z=P.with_suffix('.zip');assert not z.exists()
with zipfile.ZipFile(z,'w',zipfile.ZIP_DEFLATED) as a:
 for name in list(manifest)+['SHA256.json']:a.write(P/name,name)
with zipfile.ZipFile(z) as a:assert a.testzip() is None
digest=hashlib.sha256(z.read_bytes()).hexdigest()
note=f'''\n\n## 2026-10-02 WD118A 化蛇通用生存技能（候选）
基于WD117累计，节点29306->9003859、隐藏9003860，30级9基础AE后1AE、bit80。5秒化蛇、80%移速、已有定身/减速解除、60秒冷却；保留禁止攻击施法且可取消。配套原始远程/法术命中修正-100个百分点、80%游泳；非全伤害免疫。现有蛇模板2914及四模型客户端存在，节点图标一致，未移植CoA专属粒子链。
最新上游{sha}，PR6192已合并；独立父/子生命周期与方案撤销。Characters WD118及World绑定SQL必须成套，旧节点和购买状态不清。{results['count']}隔离SQL、累计Lua、30数据/源码及提示检查通过，未编译未实机；WD115–118仍待验收。
使用plan-coa-class-migration、trace-and-port-coa-spell-resources、build-wotlk-three-build-projection。首次全量旧level20用例失败，定向成功；新增等级分支补ROLLBACK后全量完成，证据见checks。完整说明与教学：[README]({P.as_posix()}/README_覆盖与测试说明.md)、[tutor]({P.as_posix()}/tutor.md)。ZIP SHA256 `{digest}`。
'''
for rel in ['updateMemory.md','updateListAscend.md','tutorMemory.md','refResourceAscend.md','beascendskills/skillsAscend.md','beascendtutor/tutorsAscend.md','beascendskills/plan-coa-class-migration/SKILL.md','beascendskills/trace-and-port-coa-spell-resources/SKILL.md','beascendskills/build-wotlk-three-build-projection/SKILL.md','beascendtutor/plan-coa-class-migration/TUTOR.md','beascendtutor/trace-and-port-coa-spell-resources/TUTOR.md','beascendtutor/build-wotlk-three-build-projection/TUTOR.md']:
 f=R/rel;assert f.exists()
 with f.open('a',encoding='utf8') as out:out.write(note)
print(z);print(digest);print(len(manifest),'files',z.stat().st_size,'bytes')
