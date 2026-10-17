# WD158A完整移植检查表（Codex自审，候选）

独立累计目录codexwork_WD158A；源基线035ce516063ae81d250a0fa1f1a3db92213a5631＋157冻结ff38c380…37fba；共用范围先登记写后读回，包含追加SpellHandler/Unit两个精确私有分支。源输入/输出及正式基线备选哈希见checks/input-output.json；双端表增量见research/resource-report.json。未触碰日常源码/运行目录、Playerbots/NpcBots/DC。

本次实际读Skill：plan-coa-class-migration及stages，audit-and-port-upstream-features及CHECKLIST，trace-and-port-coa-spell-resources，coordinate-ai-team-parallel-development；用于依赖批次、完整契约/自审、双端闭包与跨线隔离。156D是已验收，157和158均待实机；不更新永久成功配方。

## 来源

社区jealous-sound/azerothcore-wotlk-coa/main固定f6e30667591521c9f4f199a294b7cc4b15573c71；源码与SHA在upstream/sources.json，包括Coefficients表501134的0.1RAP。官方依据为本机COALauncher/coawowClinet20260930OFFICIAL技能数据与MPQ，独立于社区源码。节点Data正式ID7103/4423/29977，原Spell681242/681199/807743，辅助501134/504588/807772。最初也核对了后续Spirit Volley，未在本批开放。

在线Issues包含Umbral1506/4275/5761/7789开放，学徒761关闭；PR7412宏语义、4260首跳/GCD、4253触发消费、6317避免概率相乘实际合并，merge分别7bcaec8a6d0dea7b45a1e957a3d04652a138dc8a、644588cb20ad716837d9f8f09ca8ce19a92fbeca、2dd46db6edb3e978abe5842bc43ebfcf49c0cfa2、99abf5dca0b713f4032da6f1d39ff45ae1a045df。完整补丁/评论/状态在upstream/details.json。Shock名称/原ID查询结果同文件。不把合并或关闭当实机证明；仍开放问题列为针对性回归，不伪称上游全好。

## 契约

三个节点暗影专精、max1、1TE、无互斥。UM30级＋4506；学徒40级＋UM；Shock31级＋8此前暗影TE＋4177/5303/11177任一。无新导师rank链；157槽173bits44hex，hash f221c187a25ed30f7da7b005794222480345c83dfa7405f81ac09518a5b973bd，旧154槽不移动。

UM被动10%＋GetRatingBonusValue(CR_CRIT_RANGED)百分点，只实际自身远程自动/远程技能伤害，排除无伤害、近战、周期、UM本身。核心Proc为320（64|256）/Damage1/HIT2/Chance100，脚本一次真实概率，不能再在Proc表填10%。Ready自有10秒，可取消/过期；成功一次消费，取消/失败不消费，代际计数保护施法中再次触发。

UM主动4164已点天赋才学一次；9%基础Mana，instant/offGCD，0独立CD，nativeRANGED/Shadow。最多3目标，次目标主目标10码内、存活、同图同相、敌对、LOS，按距离/GUID稳定选择；触发副本不收费/消费/递归。原生6秒Aura53吸血，1000ms周期，去初始额外跳；3＋0.3×(level−14)基础按官方成长，加10%RAP，在原生done倍率前一次结算；原生暴击取RANGED并取目标减暴，治疗按实际吸血伤害原生处理。Curse dispel2、法力/减免/韧性/吸收/驱散由核心负责；刷新原有Hex只自己的GUID。原生刷新periodicReset=false，不主动ResetTicks。

学徒永久自身原生Aura212/212/174，100%Intellect＋25%Agility为RAP、25%Agility为spell damage，stat indices3/1/1及school127；原生属性变动与退点重算，不手工重复加面板、不加治疗。无CD/费用/目标伤害/额外资源。

Shock自身主动、敌人30码（原Range4）、25%baseMana、instant/offGCD、28000ms；4秒silence Aura27(effectMechanic9)；另一个native68只NPC，4秒lockout。移除原137（WotLK是ENERGIZE_PCT，不能照搬）。SpellMechanic0、effect0 mechanic9/effect1 mechanic0，沉默免疫不直接挡整个interrupt效果；原生独立免疫及递减保留。不伤害、不产魂、不假造伤害数值。

## 联动逐条

|来源|条件/GUID|受益/公式|撤销|实际入口|可见/证据|
|---|---|---|---|---|---|
|远程攻击→UM|自己marker、实际伤害、flags64/256|一次10+rating百分点判定，10秒Ready|消费/过期/取消/死亡/换方案/图/登出|158talent.Check/Proc|真实Ready图标时间；实际Proc gate与单次roll测试|
|UMReady→Hex按钮|自己Ready、最高activeHex、已学UM|只最高Hex临时替换；原始宏保持Hex|Ready消失/退点/死亡等恢复最高，升级中恢复正确|158Replacement；Player临时替换/Canonical；SpellHandler私有4164不重定向原始宏|原生SUPERCEDED包；实际方法包序/重入/升级恢复测试；游戏安全UI待测|
|UM→AoE/吸血/Hex刷新|合法敌人最多主＋2，ownerGUID|6秒×1秒，0.1RAP每跳，自己已有Hex刷新|原生到期/驱散/死亡；施法者退出/退点清理|158umbral/leech；原生53|真实目标DEBUFF/战斗日志；实际安全CalcAmount/边界测试，游戏未测|
|UM→既有Hex模组|FamilyBase映射Hex、同本地Hex mask|扎拉赞DOT/威胁一次；已有自己Growth受益，不产生Growth|marker/目标Growth撤销即撤销|WD59FamilyBase；Unit.cpp精确4164受益|actualamount/native倍率方法及源审查；具体联动数值游戏待测|
|UM→Mimic|已验证自有守卫，只成功普通主施法|复制主目标，原始casterGUID归属p，不复制2个次目标/不消费/递归|守卫/父marker清理|WD68Mirror私有4164同3822归属；158Triggered分支|原生UM；核心语法/来源审查，真实多个守卫待测|
|学徒→RAP/SP→伤害|自己active方案、当前Int/Agi|100%Int＋25%Agi RAP；25%Agi SP，参与既有系数|退点/属性变动原生重算|原生212/174及StatSystem/Unit计算|属性面板/诊断原始贡献；抽取实际原生属性循环执行，游戏待测|
|Shock→玩家/NPC|合法目标，玩家排除68，NPC需可打断当前法术|玩家4s沉默；NPC额外4s学派lockout|原生时间/免疫/驱散/递减，非持续伪附效|158shock.OnEffectLaunchTarget；原生EffectInterruptCast|真实4s沉默图标；实际native launch/普通/引导/不可打断/死目标/玩家过滤执行|

## 视觉闭包

UM501134→Visual1916→全部非空Kit/ModelAttach/EffectName/M2/SKIN/ANIM/BLP/Sound，私有888161；Shock807743→90080同链，私有888162。原节点/Ready/学徒Visual0不凭空加模型，UM/学徒/Shock节点图标910200—202。39路径来源及哈希在assets.json，完整表依赖192检查。M2为MD20/264；本批无7/14新降级，累计157疾行兼容边界保留。

Sound12979在官方不同包只有字符串偏移和29/30字段差异，规范化为实际字符串＋尾0后等价，采用30字段兼容行；不按文件名猜不同声音。对比证据sound-conflict.json，最终声音资产哈希见assets。施法/弹道/命中/持续/结束及音效逐Kit追踪；叠层UM非叠加DoT，无虚构堆叠模型；学徒纯属性无命中视觉。全部外观真实游戏待测。

## 审查、测试与发现的问题

CalcAmount用GetUnitOwner（合法目标owner）与GetOldAmount重建RAP＋单次done倍率，不在无AuraApplication回调用GetTarget。施法检查判空，经WD68Caster处理真实拟态归属；ownerGUID贯穿Hex刷新/UM清理。辅助Ready不进技能书，UM只随Talent学习/撤销；三个学习节点、五条绑定及5条DBC一致。

独立自审发现：硬编码272漏远程自动攻击64，改320并提取实际CanSpellTriggerProcOnEvent复现旧拒绝/新通过；OnEffectHitTarget过滤NPC打断太迟，改OnEffectLaunchTarget，在真实原生方法launch阶段验证玩家不被打断；普通CalcAmount +=RAP会让该部分漏原生倍率，改以UnitOwner安全重建一次；只按一般映射遍历可能恢复低rank，明确最高Hex规范化且升级中恢复最高。声音偏移/字段差异经语义对比确认非不同音效。均作为本批候选处理，不称游戏问题已闭环。

结果：514隔离SQL（修正320后复测）及累计保存/版本/冲突/幂等；累计Lua、0/1保存/草稿中英Tooltip；6实际translation units /Zs（改Shock回调后模块再查）；实际方法/原生Proc/原生打断/原生属性循环；真实SQL行→C++生成Hex→实际Lua原子监听→已保存Tooltip；192双端旧行/字符串/视觉声音/时长/来源/ABI保留检查。离线桩不等于真实战斗。没有worldserver构建或生产执行。

所有旧表记录与字符串前缀保留，157冻结ZIP哈希保持；双端分别合并，不互换。源W/日常/运行目录未改；Player/Spell类无新增成员。Claude已发布代码留在基线，未带入其候选。

未测：真实游戏加载、安全UI、全部等级/职业机器人、精确概率、反射/驱散/免疫/DR、多玩家/多守卫、所有生命周期和压力。SourceIssues仍开放，实机回归按README逐项。结论：WD157＋WD158组合候选，等待用户；未commit/push/Release/部署。回滚须一致时点全套备份，不把旧布局覆盖已保存新节点。
