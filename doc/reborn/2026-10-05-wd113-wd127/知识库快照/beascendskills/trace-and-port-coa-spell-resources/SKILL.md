---
name: trace-and-port-coa-spell-resources
description: Trace a local CoA class ability from progression records through spell mechanics and MPQ assets, then prepare an isolated WotLK port or a source-grounded line-by-line tutorial. Use for a bounded skill or class-mechanic migration, not wholesale class imports or unrelated UI errors.
---

# Trace and port CoA spell resources

## Establish the requested scope

Support an audit, a teaching request, or a bounded implementation as requested. A tutorial does not authorize regenerating old packages. An audit does not authorize installing the proposed class. In this project, deliver overwrite packages for the user to compile/install unless they explicitly change that arrangement.

Read the current project rule/refResource documents and state table; verify their paths exist. Treat dated reference paths as pointers to verify, not proof of the live baseline. Preserve existing class identities, approved race restrictions, character data, and independently validated fixes.

## Trace evidence before copying

1. Find the progression source: class/level/spell entries and, when relevant, CharacterAdvancementData.json. Keep advancement IDs, spell IDs, class IDs, and masks distinct. Inspect realm/version/required-node filters before counting playable skills.
2. Enumerate actual MPQs and inspect requested internal paths. Record every candidate, unreadable file, source archive and SHA256. A filename sort is a search heuristic, not proof of runtime precedence. Do not substitute an older unpack directory for a locked current archive.
3. Read the selected Spell row and follow time/range/icon/visual references. Expand all nonempty visual kits, attachments, missile trajectories, sounds, models and embedded textures. Trace gameplay triggers separately in server code.
4. Identify the exact implementation of coefficients, previous-target state, cooldowns, target eligibility and child spells. Do not infer these solely from tooltip wording.

For the proven local Witch Doctor example, read [references/wd3-case.md](references/wd3-case.md). For formats and teaching structure, read [references/method.md](references/method.md).

## Build only the bounded dependency closure

- Read client and server baselines separately; append guarded records to each side's own table and string block. Check reserved IDs across both sides and relevant database tables.
- Preserve unrelated rows and old string prefixes. Use independent asset paths and remap embedded texture filenames as well as DBC paths. Do not replace whole character models when existing skeletons supply the actions.
- Reject unsupported dependencies until understood. Record compatibility deviations explicitly rather than synthesizing missing donor records without evidence.
- Place custom mechanics at the matching server effect/hit hooks; compare coefficient placement as well as numeric factors. Avoid applying native and custom scaling twice.
- Keep per-player temporary state on the player, using GUID resolution and eligibility checks. Separate visible abilities from hidden triggered effects to prevent recursion.
- Make database changes conflict guarded and repeatable. Test actual storage-engine behavior; do not promise transaction rollback for MyISAM tables.

## Validate and teach

Separate old-data invariants, dependency checks, isolated database execution, behavior models, user compilation, and in-game results. Never promote static checks or a few confirmed effects into complete gameplay acceptance.

Preflight every generated client **and** server DBC against the actual core format: validate header/record/string-block sizes and every `s` field offset, including hidden child spells and empty localized description slots. WD85A's ID 9003732 carried a stale description offset and stopped worldserver during Data Stores initialization; [WD85B](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609290754_阶段WD85B_Spell字符串偏移修正/README_覆盖与测试说明.md) corrected it. The user later confirmed the two talents' basic gameplay, not every numeric and ownership edge.

For teaching, quote the actual delivered source with line numbers, explain each statement's input/output and role, and include source archive evidence. Explain discovered mistakes and compatibility differences. Keep the detailed beginner lesson in a linked tutorial; keep this skill concise.

Archive source hashes, ID mappings, exact rollback inputs, readable installation instructions and the accepted/pending status. Keep MPQ backups outside Data. Leave the user's MPQEditor and production processes alone. Historical builders are evidence, not automatically reusable migration tools.


## WD24A 节能巫祝：用户基本实测通过（2026-09-19）

用户明确反馈“节能巫祝 这个测试通过了”。仅确认本批基本使用通过，不推定全部资源类型、机器人边界或视觉完全一致；WD25A希里克诅咒仍在编译测试，WD26A法力诅咒待验收。
来源：[WD24A](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260918/codexfix_202609182337_阶段WD24A_节能巫祝与资源消耗适配/README_覆盖与测试说明.md)，[逐步教程](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260918/codexfix_202609182337_阶段WD24A_节能巫祝与资源消耗适配/tutor.md)。ZIP SHA256：`8cb71fa29d2c2bdf55805b17511e8cb0c2428c172e06a2c0a3d057b18cc61d4f`，历史交付文件未改写。
复用要点：原生Aura72按七学派费用倍率实现5%标准资源减耗；费用计算应核对最终扣除路径，不把自定义扣费、符文槽或全资源清空泛化为支持。清除本地不支持且上游为空实现的Effect168时同时清空对应参数。未确认的procedural8视觉参数组关闭仍是已知降级，用户基本通过不能抹去该限制。
永久流程：[Skill](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendskills/trace-and-port-coa-spell-resources/SKILL.md)；[同名Tutor](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendtutor/trace-and-port-coa-spell-resources/TUTOR.md)。


## WD25A / WD26A 用户基本实测通过（2026-09-19）

用户明确反馈“希里克诅咒 法力诅咒 测试通过”，两批登记基本成功；不推定野兽形态PvP完整递减、全部机器人及空蓝/满蓝等边界均已验收。缩小诅咒WD27A正在编译测试，仍为候选。

复用要点：恐惧持续上限必须在原生递减之前按准确私有ID限制；野兽目标限制不能扩大到全部玩家。周期吸取先确认触发施法者归属，原生Effect8按实际扣到的法力返还，不能按理论值凭空回蓝；自然回复抑制不等同禁止药水和主动补蓝。

来源：[WD25A覆盖说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260918/codexfix_202609182359_阶段WD25A_希里克诅咒与野兽恐惧/README_覆盖与测试说明.md)，[详细教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260918/codexfix_202609182359_阶段WD25A_希里克诅咒与野兽恐惧/tutor.md)。原ZIP SHA256 `364e38ee4143f222615bd3a5e2bd3a91a7e885037a9fd5bc060428cf88ec1d3b`，未改写旧包。

来源：[WD26A覆盖说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260919/codexfix_202609190014_阶段WD26A_法力诅咒周期吸取与回复抑制/README_覆盖与测试说明.md)，[详细教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260919/codexfix_202609190014_阶段WD26A_法力诅咒周期吸取与回复抑制/tutor.md)。原ZIP SHA256 `c3389f2032ba6f18be4cf99d755ea7e87a75be3428632e95e3f720c8cea386dc`，未改写旧包。

永久流程：[Skill](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendskills/trace-and-port-coa-spell-resources/SKILL.md)，[同名Tutor](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendtutor/trace-and-port-coa-spell-resources/TUTOR.md)。


## WD27A 缩小诅咒：用户基本实测通过（2026-09-19）

用户反馈“上一个包检测通过 我来测试破咒术”，承接WD27A缩小诅咒。登记基本使用成功，不外推所有跨施法者、下线或特殊物理法强边界。WD28A破咒术仍待实机验收。
来源：[WD27A](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260919/codexfix_202609190033_阶段WD27A_缩小诅咒六等级适配/README_覆盖与测试说明.md)，[逐步教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260919/codexfix_202609190033_阶段WD27A_缩小诅咒六等级适配/tutor.md)，原ZIP SHA256 `d27366846698374844d442d2935ae0d170e5f01871f7cff647200a1a4b57f82b`，未改写。
复用经验：CoA344同时影响近战/远程AP，345涉及伤害/治疗法强；WotLK三个效果槽可拆主/辅助并用原生type2关联管理生命周期。辅助隐藏、同持续时间、不进技能书，清除必须保留施法者GUID。魔法伤害掩码126避免改动白字伤害；物理技能吃法强仍是已知适配边界，不能因基本通过而抹去。
永久流程：[Skill](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendskills/trace-and-port-coa-spell-resources/SKILL.md)，[Tutor](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendtutor/trace-and-port-coa-spell-resources/TUTOR.md)。


## WD29A 万灵药：用户基本通过反馈（2026-09-19）

用户在WD29A交付后反馈“测试通过可以进行下一步的开发”，记录基本使用通过。现场审计发现模块源码仍为WD28A、服务端DBC已是WD29A；因此不能据此宣称此目录WD29A源码已编译或全部资格校验已验收。后续累计包补齐已知WD29A源码，保留该版本证据边界。
来源：[WD29A](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260919/codexfix_202609190159_阶段WD29A_万灵药净化与短时免疫/README_覆盖与测试说明.md)，[教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260919/codexfix_202609190159_阶段WD29A_万灵药净化与短时免疫/tutor.md)；原ZIP `fbec4b7cf961eea57b8b835c8c87a311e434b653acb7200100a0beca068ac472` 未改写。
复用经验：Aura41按Misc4/3/2提供类型免疫，AttributesEx0x8000清除旧效果，ApplyAllSpellImmunitiesTo在apply=false撤销免疫；这采用免疫净化移除语义，不等于Effect38的逐次驱散和AfterDispel。持续读Duration表，不能将BasePoints9+1误作10秒。
永久流程：[Skill](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendskills/trace-and-port-coa-spell-resources/SKILL.md)、[Tutor](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendtutor/trace-and-port-coa-spell-resources/TUTOR.md)。


## 2026-09-20 本窗口复盘入口
遇到本轮同类问题时读[按需复盘](references/session-20260920.md)。已验证方法复用；WD34/35/37/38不因整批交付而提升成功状态。


## WD38A 用户实测通过（2026-09-20 本次新任务反馈）
用户原话：“WD38A 测试通过，继续巫医下一批技能”。登记合包基本实测通过：黑暗/丛林神像、原图腾正式参数恢复、恶意妖术8技能等级周期暴击。没有逐项日志的新反馈不扩展为所有等级、双施法者、真人/两类机器人全矩阵已完成；120级历史异常未归因。
来源：[WD38A覆盖说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260920/codexfix_202609200757_阶段WD38A_神像同机制批量与恶意妖术合包/README_覆盖与测试说明.md)，原ZIP SHA256 `4c1cd57f31f5db2e024f03d2b3a861fab37ce8d55b4129ae3e177d02dffa3bfa`；旧包不改写。验收承接档：[WD39A](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260920/codexfix_202609201949_阶段WD39A_宁静神像抗施法打退/memory.md)。
可复用方法：同机制神像配置驱动，共用Idol槽而独立于Ward；刷新2.2秒短Aura，按ownerGUID撤销，原生Aura143处理抗性取强。Hex应用/刷新快照暴击率，核心逐跳掷骰与倍率；rank是技能等级，不是人物等级。
永久流程：beascendskills/trace-and-port-coa-spell-resources、repair-multiclass-summon-lifecycle及各自同名Tutor。本次下一批宁静神像仍是候选，不继承此次验收。


## WD39A 宁静神像基本实测通过（2026-09-21）
用户明确“宁静神像 测试可以的”，随后继续测并索要方法；登记基本使用通过，不扩大为读条/引导、低等级及两类机器人全部专项验收。复用Idol槽、2.2秒短Aura、按owner清理和原生Aura149。来源：D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260920/codexfix_202609201949_阶段WD39A_宁静神像抗施法打退；下一批WD40不继承验收。


## 2026-09-21 WD40A 哨戒守卫基本实测通过
用户明确“哨戒守卫 测试通过 可以看到他盗贼的隐身”。确认盗贼潜行揭露；其他类型隐形、范围/LOS、双施法者、两类机器人等未逐项确认。WD41A暗影雕像继续候选。
[验收记录](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260921/WD40A_哨戒守卫实测验收记录.md)；[来源包说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260921/codexfix_202609210144_阶段WD40A_哨戒守卫潜行隐形揭露/README_覆盖与测试说明.md)。


## 2026-09-21 WD41A 暗影雕像基本实测通过
用户明确“暗影雕像 雕像也测试通过了”，登记基本通过，不扩大为全部范围/免疫/双施法者与机器人矩阵。保留独立Effigy槽、单次召唤、单Aura双减速经验。
[来源](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260921/codexfix_202609210329_阶段WD41A_暗影雕像施法与移动减速/README_覆盖与测试说明.md)。WD42恢复合包，仍为候选。


## 2026-09-21 WD42A 墓刻通过、妖术机制通过及外观回归
用户确认墓刻雕像基本实测通过；妖术雕像敌方法师直接攻击主人会变青蛙，攻击雕像不触发符合既定规则。妖术模型名字和受击点明显过高，WD42A外观验收存在回归，不能记为完整成功。其他PvP递减、伤害解除、两类机器人、范围/LOS、替换全部边界未逐项验收。
已验证子集：墓刻指定控制加时基本使用；妖术显式敌方法术打主人触发一次，攻击雕像不触发。WD42B高度补丁仅为候选，不能晋升其模型烘焙方法为已验证。
来源：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260921\codexfix_202609210728_阶段WD42A_妖术与墓刻雕像合包\README_覆盖与测试说明.md
回归修正：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260921\codexfix_202609211610_阶段WD42B_妖术雕像高度与日志排查\README_覆盖与测试说明.md


## 2026-09-21 WD42B 妖术雕像高度修复用户实测通过
用户明确“测试这个妖术雕像 修复 通过”。承接WD42B，确认名字/受击点高度修正基本通过；此前墓刻及青蛙触发已基本通过。不能据此确认LOG42C两项红字、亡者大军缺失模板、root心跳或骸骨问题均已修复。
已验证方法：仅限本只静态建筑雕像，M2顶点/骨pivot/包围盒/碰撞与SKIN中心半径统一缩0.1，显示倍率恢复1，双端私有ModelData补高度；带动画或粒子模型不可直接套用。
来源：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260921\codexfix_202609211610_阶段WD42B_妖术雕像高度与日志排查\README_覆盖与测试说明.md
本批WD43A仍为候选。


## 2026-09-21 WD43A诅咒雕像与迅捷神像基本实测通过
用户反馈“测试通过”，随后请求诅咒雕像适度放大。登记两项基本使用通过，不扩大为全暴击路径、全部等级与机器人矩阵均已完成；外观放大为新候选。保留私有标记9003431、原生暴击最终判定与周期快照分离方法；迅捷采用原生移速/定身减速抵抗，25%不是免疫。
[来源](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260921/codexfix_202609211700_阶段WD43A_诅咒雕像与迅捷神像合包/README_覆盖与测试说明.md)，原ZIP SHA256 f9956e87660532f6a6d363a2773fe1b56296fe9cb6682bb597243943abb42dce。


## 2026-09-21 WD44A两项净化技能用户基本实测通过
用户原话：“继续下一批的技能开发吧 这两个通过”。确认净化神像、群体万灵药基本使用通过；不扩展为所有机器人/驱散抵抗/共享冷却边界全部验收，也不将这句话单独当作诅咒雕像1.6倍外观确认。
可复用方法：净化首跳3秒与间隔3秒，原生Effect38疾病/毒各1；群体版原生Aura41免疫净化3秒，ownerGUID召唤生命周期，已学群体版时共享万灵药冷却。本地独立导师入口与成长JSON编号冲突仍是适配边界。
[来源](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260921/codexfix_202609211832_阶段WD44A_净化同机制技能与诅咒雕像尺寸优化/README_覆盖与测试说明.md)，原ZIP SHA256 d149501fc4876f2d19244dc81465d1bf2e3139ec63258c1ad8f18a7ee4bbedb0。


## 2026-09-21 WD45A静滞守卫与穆厄扎拉之触基本实测通过
用户明确：“上面的技能测试通过 继续下一批的技能开发吧”。承接WD45A两项技能，登记基本使用通过；不扩大为所有等级、伤害系数、PvP递减、双施法者及机器人完整矩阵。此前登录提示后用户说明MPQEditor未关闭，不归因为已证实的技能代码缺陷。
可复用：单次2秒延迟爆发、先标记fired再施法、守卫销毁/替换取消；私有精确SpellID加时置于原生递减前，避免与原family Aura107重复。
[来源](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260921/codexfix_202609211948_阶段WD45A_静滞守卫延时爆发与昏迷/README_覆盖与测试说明.md)，原ZIP SHA256 d801be4a0fa7cafb12e148d3744ec48016f8adc865c6fc1773ca62bc7aa327cc。


## 2026-09-22 WD46A＋WD46B用户基本实测通过
用户明确：“继续开发下一批的技能 这两个技能通过”。确认瓶中之灵、灵魂之触基本使用通过，承接WD46B技能书显示修正；不扩大为8rank/所有机器人/范围/吸收完整矩阵。
复用：AfterHit读有效治疗；复制伤害排除二次法强和暴击；治疗目标作为范围/LOS中心；已学记录与客户端隐藏位分开审计。可学习被动保留0x40而清0x80，勿清整个Attributes。WD46A原隐藏位漏检为已纠正反例。
[WD46A](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260921/codexfix_202609212147_阶段WD46A_瓶中之灵与灵魂之触/README_覆盖与测试说明.md)，ZIP fbf6372f071b87b038930568508e54eb5491c9f369a183ac259572168f1e2e4c；[WD46B](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260922/codexfix_202609220100_阶段WD46B_灵魂之触技能书显示/README_安装说明.md)，ZIP d58326291f09bba809719cd88533db5afe8dfb8129b9840e62f123d82564b55b。


## 2026-09-22 WD47A两项用户基本实测通过
用户明确“好的 这2个技能通过了 继续下一批的技能修复移植吧”。洛阿祝福和丛林秘法按基本通过登记；另有截图9003482贝瑟克的凶猛剩余13秒，直接证明祝福触发与显示。未将一句通过扩展为所有机器人、80码边缘、多巫医及生命周期完整矩阵。
复用：从AfterHit有效回血触发；单独追加父法术脚本，不受旧前一目标提前return影响；隐藏复制治疗OnHit恢复固定值后仍原生吸收/过量，不能假定伤害忽略标志适用于治疗；原生Aura20秒属性还原；可学习被动清隐藏位。雕像GUID查现存对象和归属，Ward/Idol不误触发。
[来源包](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260922/codexfix_202609220121_阶段WD47A_洛阿祝福与丛林秘法/README_覆盖与测试说明.md)；[教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260922/codexfix_202609220121_阶段WD47A_洛阿祝福与丛林秘法/tutor.md)；ZIP SHA256 15afe7af51f019d13e598f94bfc5c7af45b35ff835c78dac1e4a72b4ea2e494a。新WD48不继承验收结论。


## 2026-09-22 WD49A用户基本实测通过
用户明确反馈“好的 可以了技能都动过了 任务书籍显示也正常”。登记侵蚀之夜、金度之怒及本合包修正基本通过；不外推全等级概率统计、所有三方案/动作条边界和所有机器人均已验证。
复用：原生Aura107/108配精确私有技能家族匹配；被动清隐藏位；同一donor先查旧天赋与完整模块，不只看Ranks.h；旧ID保留为等级链起点，购买账本不删，旧别名在动作条恢复时归一。物品23338与任务9373分别核对：物品2047是旧职业位集合，-1不限；任务0不限，不能混用，不能全库开放职业专属书。
来源：[覆盖包](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260922/codexfix_202609220521_阶段WD49A_侵蚀之夜与金度之怒合包/README_覆盖与测试说明.md)，[教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260922/codexfix_202609220521_阶段WD49A_侵蚀之夜与金度之怒合包/tutor.md)。ZIP cdf7113bbece94dc22be53a4f420a308fcc5cbfb9f6e36db73303102e8b686a0。


## 2026-09-22 WD50A 用户基本实测通过
用户明确反馈恶性蔓延、妖术迸发通过。登记9003520传播自己的恶意妖术与9003521触发6秒20%施法急速基本使用通过；不扩大为全部概率统计、双施法者、低等级/机器人/边界距离矩阵已完成。
复用：传播保留持续时间、下一跳计时、伤害数值、暴击概率快照；按owner过滤并排除重复挂同源Hex。原生伤害暴击proc产生Aura216，刷新而非叠层；施法急速不是直接把读条乘0.8。来源[WD50A说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260922/codexfix_202609220700_阶段WD50A_恶性蔓延与妖术迸发/README_覆盖与测试说明.md)、[教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260922/codexfix_202609220700_阶段WD50A_恶性蔓延与妖术迸发/tutor.md)。原ZIP SHA256 64185c8f2e9b1892487152000a01593146202d3c4bbd66d9224263e9be1800de，历史包不改写。
用户同时报告WDUI1A三槽不显示，UI故障不撤销两被动的基本验收。WDUI1B/C为另一个客户端UI修正，待实机。


## 2026-09-22 WD51A＋WD51B用户基本实测通过；WD52全量审计
用户反馈“测试已通过，继续下一阶段的技能开发”，确认恶意滋长9003530与毒蛇守卫狂暴9003532基本使用通过，承接WD51B IsHex编译修正。不扩大为概率统计、双施法者、重召/洗点完整矩阵。
来源：000Ascendupdate/000Ascendupdate20260922/codexfix_202609221910_阶段WD51A_恶意滋长与毒蛇守卫狂暴，ZIP SHA256 92713d790d11873860b9d767e532aad5695f0e6ed8a5b20ba9a23066fe40de86；WD51B包 codexfix_202609221955_阶段WD51B_恶意滋长IsHex编译修正，ZIP SHA256 cd80c2c282faec770b8d1c8868be1a587b77372f5c86fcb759dbb6b36e8f8a30。历史包不改写。
复用：按施法者归属隔离周期增伤；先结算本跳再叠层影响下一跳；毒蛇守卫按自己当前召唤GUID和entry过滤，使用时间进度实现急速，不能改动治疗守卫。IsHex反例：存在调用不等于声明存在，必须核对当前头文件API。
教学：恶意滋长像同一个人的下一次结账折算，不能算到旁人账上；守卫急速改变计时器走快的速度，换新守卫不能凭旧GUID继承状态。结合原包tutor.md和WD51B差异读真实代码；用户这次确认基本效果，不把离线测试当全场景实测。
WD52审计见 [审计结论](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260922/WD52_巫医全技能与天赋分类审计/审计结论与下一阶段.md)：48技能族，配套天赋目录159节点，16有本地效果/映射，143尚未匹配，2真实学习节点、157未接入；分类与完整天赋尚未部署。不能以旧JSON403条或上游175 SpellID直接减48。下一阶段转按树开发并接入学习规则。


## 2026-09-23 WD53A 用户基本实测通过
用户明确“继续下一期的技能开发 技能测试通过”，承接洛阿仪式9003540与灵魂回收9003541，记录两项基本使用通过；不外推全部返蓝概率/边界、断线消息时序、多角色/机器人测试已完成。
来源：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260923\codexfix_202609230218_阶段WD53A_洛阿仪式与灵魂回收；ZIP SHA256 173b1590e210a8e8ab4842508167b440f05e94e14864f7c14deacf36576029fb。历史包不改写。
复用：独立召唤槽用GUID与owner校验，成功召唤保存实际费用收据，先消费收据再清理；选择消息只同步本人已学类别，正式施法仍由安全按钮和服务器法术系统发起。两项主动技能同时接导师、书页分类、学习账本和重登，不只增加插件按钮。
教学：参见来源包tutor.md。把三类召唤物看成三张独立收据，回收只结算当前活着且归自己的对象；不能把萨满原生图腾数组当成自定义召唤槽。


## 2026-09-23 WD54A 天生炼金师自动补学基本验收
用户更新运行目录EXE并重启后明确回复“有了”。确认天生炼金师9003550已出现/成功补学，基本学习接入通过；不外推炼金术实际+15、遗忘/重学专业、全部新老角色与其他种族完整矩阵已测。
此前新老巫医没有技能且IsSpellKnown=false：当前源码及双端DBC已03:49更新，编译输出04:22，而运行目录EXE仍03:18、进程03:24启动。复制新编译EXE到运行目录并重启后用户确认出现。代码/DBC在磁盘存在不等于当前进程已加载；先比较编译输出、部署文件与进程启动时间，不反复覆盖客户端或强学技能掩盖版本差异。
来源包：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260923\codexfix_202609230330_阶段WD54A_酿造基础被动天生炼金师；原ZIP SHA256 c003a75a74c3d5466a3c0d4646b30ab62da6054f815caea6052f5342953bda12。历史包不改写。
排查教学：[运行版本核对](000Ascendupdate/000Ascendupdate20260923/WD54A_自动学习未生效排查.md)。永久方法：beascendskills/trace-and-port-coa-spell-resources/SKILL.md；同名教学：beascendtutor/trace-and-port-coa-spell-resources/TUTOR.md。源包tutor.md保留完整Aura98及学习接入教学。
WD55A暗影烈焰仍待单独安装/实测，不继承本次验收。


## 2026-09-23 WD55A 暗影烈焰基本实测通过
用户明确“暗影烈焰 测试通过”，记录该技能基本使用通过；不扩大为全部13等级、系数统计、灵魂所有叠层/回复/双施法者/死亡边界完整验收。WD56A大巫毒仍由用户测试，不能继承通过。
来源包：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260923\codexfix_202609230419_阶段WD55A_暗影烈焰与击杀灵魂；ZIP SHA256 5d8c153cd3ab8a05fb026c1b6f527e5820b8edd72eb3b99e4b8a75256e392bc5。原包不改写。
可复用方法：当前父技能说明与上游把旧触发式改为直接伤害的实现一起核对；旧子技能残留周期描述不优先。手工35%暗影SP+10%RAP与SQL默认系数归零成对，击杀收益在AfterHit；Spirit原生Aura24/8、叠层和生命周期。Spell字段37/38/39是MaxLevel/BaseLevel/SpellLevel，必须读当前结构定义。灵魂环绕球Issue270仍未解决，不因本次通过宣称修复。
教程：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260923\codexfix_202609230419_阶段WD55A_暗影烈焰与击杀灵魂\tutor.md。永久Skill/Tutor为trace-and-port-coa-spell-resources。下一批按酿造基础缺口及完整物品取用依赖推进，不把新增基础技能等同正式天赋节点开放。


## 2026-09-23 WD56A 大巫毒基本使用与外观实测通过
用户明确“大巫毒 好帅 测试通过”，确认基本玩法及召唤外观；不扩大为全部PvP、跨队伍、死亡/地图/断线和锁定边界验收。来源包：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260923\codexfix_202609230541_阶段WD56A_大巫毒防护领域；ZIP SHA256 fdcfcaaa3c9fbd888059f7127498f8a13e30fea178ca1b488ee2f588591e0787，历史包未改写。
可复用经验：独立召唤GUID不占三类槽；600ms防护租期配合250ms刷新、按施法者GUID清理；原生免疫期间施加衰退限制需NO_IMMUNITIES，不能取消限制绕过保护。克隆完整模型/贴图/皮肤链，并补全creature_template_model和creature_model_info。官方当前说明与旧版本数值冲突时固定来源，不能混用。教程：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260923\codexfix_202609230541_阶段WD56A_大巫毒防护领域\tutor.md。永久Skill和同名Tutor：trace-and-port-coa-spell-resources。下一批WD57A魔精大锅仍为开发候选，不继承本次通过。


## 2026-09-23 WD57A/B魔精大锅与WD58A空灵之魂基本实测通过
用户明确“2个技能包 都测试通过”，承接大锅（含WD57B编译修正）和空灵之魂。记录基本玩法成功，不推定25次并发、跨队伍、概率统计及全等级所有边界完成。历史ZIP保持不变。
来源：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260923\codexfix_202609230706_阶段WD57A_魔精大锅与团队取用；SHA256 5954af9861dc54098a93a6d369f2b03b424dbfc8f1f9e72d9af96519c94895c3；教学：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260923\codexfix_202609230706_阶段WD57A_魔精大锅与团队取用\tutor.md
来源：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260923\codexfix_202609230824_阶段WD57B_魔精大锅编译接口修正；SHA256 186e96c795b97fb0d8d37179311e03d9dcbf8fec2bc28656c1ace5d5b5a2e12d；教学：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260923\codexfix_202609230824_阶段WD57B_魔精大锅编译接口修正\tutor.md
来源：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260923\codexfix_202609231650_阶段WD58A_空灵之魂暴击易伤；SHA256 f2443c22092def4c1dc72698f3bc84194683c756c3acfda8812c95051ed81fe6；教学：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260923\codexfix_202609231650_阶段WD58A_空灵之魂暴击易伤\tutor.md
复用：原生Effect50保存大锅owner，type22按成功施法计次，额外拦25次和非READY窗口；读取当前GameObject.h确认getLootState大小写，不凭接口习惯猜。空灵之魂用伤害后钩子、真实伤害值和每个AOE目标分别判断，原生Aura197表达目标暴击易伤；临时导师入口不同于正式天赋加点。
用户要求提高效率：后续优先按共同依赖组成3—4项完整功能合包，不再默认一个技能一包；不可把同技能等级或隐藏触发子法术凑成多个技能。


## 2026-09-23 WD58教学字段索引更正（WD59审计）
按当前DBCStructure.h重新核对：Spell字段119—121是EffectPointsPerComboPoint；EffectSpellClassMask是122—130，每个效果连续三个字段。WD58文字中“第二效果掩码全0”的解释不准确：705917第二效果实际mask[1024,0,0]，只指向旧802704 Shadowflare子技能；当前801669和本地WD55直接伤害父技能使用bit4。WD58不移植旧子技能的15%系数修饰仍符合当前直接伤害路径，但理由应为旧触发子路径不再使用，不能记成全零掩码。没有改动已验收的WD58行为或历史ZIP；后续读取掩码一律按当前结构定义。


## WD62A 用户基本实测通过（2026-09-24）

用户在WD62交付后明确“测试通过”，登记黑暗魔精、睿智、洛阿之力基本通过。不外推所有随机抵抗、全种族/机器人及PvP边界，不把此前1HP恢复当成源码根因修复。

复用要点：Aura178是符合Dispel1/2负面光环的抵抗路径，同类正值取强，不是所有魔法伤害减20%；Aura72费用字段与原生最大法力132、总属性137分别计算；学派40是自然+暗影，属性1是敏捷。保留双端独立母版与旧记录，剔除官方描述未说明的第三dummy时明确记录。书页9006是巫医暗影狩猎，9003是武僧织雾。

来源：[WD62说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260923/codexfix_202609232343_阶段WD62A_防护与属性三被动合包/README_覆盖与测试说明.md)；[教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260923/codexfix_202609232343_阶段WD62A_防护与属性三被动合包/tutor.md)。历史ZIP不改写，SHA256 b6a91e84d761bc13325108d6f46afdcec3e8f891753c1286370657493d8a41e4。WD63仍待测。


## 2026-09-24 WD63E 灵魂神像135秒客户端同步实测通过
用户截图GetSpellCooldown(9003370)输出134.999、133.917000000002：总时长约135秒，与180秒减少25%一致。结合此前WD63D的learned1/aura1/op11/type108/value-25/match1及服务器剩余132800ms，登记WD63E灵魂神像单放的客户端冷却同步基本实测通过。
本次不扩大为一键三放、14召唤族、所有职业、事件冷却或到期再次施放全矩阵已验证。Tooltip仍显示基础3分钟，未做动态说明修正。
复用经验：只对精确匹配服务器Hastened修饰的施法，在SpellGo后清客户端该技能计时，再发送服务器实际剩余毫秒；不删除服务器CD、不再次乘75%、不改GCD。此测试支持该校正有效，但未做客户端抓包，不能声称已直接观测到客户端内部覆盖顺序。

来源包：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260924\codexfix_202609240755_阶段WD63E_迅捷召唤客户端冷却后置同步.zip
SHA256：5f4ed3e7c425936875e10626e1bb00a949dbc35e080c8d743932cd0ba7096703
教学：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260924\codexfix_202609240755_阶段WD63E_迅捷召唤客户端冷却后置同步\tutor.md


## 2026-09-25 WD68 傀儡师之线基本保存效果用户确认
用户针对“但还不能据此确认保存后的技能效果”回复“现在测试可以的了”，只登记傀儡师之线保存后基本效果可用。不扩展为15%全部数值统计、双施法者/死亡/切方案生命周期，也不扩展为拟态守卫与暗影傀儡战斗通过。用户随后截图暗影傀儡1/1未保存，仅证明选择流程。
来源：000Ascendupdate20260924/codexfix_202609242135_阶段WD68A_巫毒分支前置与技能整合，ZIP SHA256 bff01b041a0fc947d21129059dabbc54526ce483ac168bbcc84e74e0df9db554；承接次日WD68B/C编译接口修正，不能用原WD68A源码覆盖当前累计源码。
可复用方法：免费专精身份节点仍按方案保存/激活授予；0费用不等于全角色常驻。区分点亮草稿、服务器保存、真实被动触发三层证据。阶段记录与教学见WD69A归档；完整实现教学留在WD68A的tutor.md。

证据：[WD69A记录](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260925/codexfix_202609250201_阶段WD69A_饮水职业资格与天赋前置提示/memory.md)。永久Skill/Tutor：trace-and-port-coa-spell-resources。


## 2026-09-27 WD78B三个巫医天赋基本实测通过

用户明确“三个巫医天赋 可以了通过 继续下一批的移植吧”，登记荆棘谷风格、扎拉赞恩的恶意、妖火基本使用通过。不扩展为所有等级/数值、PvP和所有方案矩阵，也不把Voodoo Spirits704511未移植的妖火联动记为通过。

来源：[WD78B](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260926/codexfix_202609262111_阶段WD78B_巫毒三节点双池整合/README_覆盖与测试说明.md)，[教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260926/codexfix_202609262111_阶段WD78B_巫毒三节点双池整合/tutor.md)。复用：已有战斗实现接正式双池时同时扩C++/Lua/SQL白名单与mask；保留旧位、旧账本，不允许现代导师路径恢复已撤销技能；两个点数池不可互借。现代激活存档决定技能所有权，草稿不能授予。WD79A新候选不继承验收。

永久方法：beascendskills/trace-and-port-coa-spell-resources/SKILL.md与build-wotlk-three-build-projection/SKILL.md；对应同名Tutor。

## 2026-09-29 WD85A + WD85B 两节点基本实机通过

用户在 WD85B 启动修正后明确“这两个技能通过”，承接 **巫毒丝线**和**巫毒之魂**。当前服务端 Spell.dbc 与 WD85B 修正版 SHA256 一致。来源：[验收记录](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609290754_阶段WD85B_Spell字符串偏移修正/验收记录.md)、[WD85A 原包](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609291030_阶段WD85A_巫毒丝线与巫毒之魂/README_覆盖与测试说明.md)。

复用：两个正式天赋节点分别用现代活动方案授予私有被动；战斗效果只在**本人**触发法术实际命中**本人**丝线目标时结算。周期伤害作为隐藏子法术单独校验 Spell.dbc 全部字符串偏移；妖火结算先清存储伤害、再移除丝线，避免移除回调双重结算。C++、Lua、characters/world SQL 与双端 DBC 要按各自基线成组交付。未逐项确认 30% 数值、全吸收、双施法者、重登、五层上限及 PvP/机器人矩阵。


## 2026-09-29 WD86A 两项用户实机通过

用户明确反馈：巫毒心智（按施放时灵魂层数调整暗影傀儡跳速和持续时间）、黑暗洛阿祝福（团队伤害提高3%，自身傀儡加速）测试通过。登记这两项基本效果通过；未提供每个层数逐跳日志、同类增伤全组合、多人归属、PvP/机器人、切方案/重登完整矩阵，不扩大结论。WD87A仍候选待测。

来源：[WD86A覆盖说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609291413_阶段WD86A_巫毒心智与黑暗洛阿祝福/README_覆盖与测试说明.md)、[完整教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609291413_阶段WD86A_巫毒心智与黑暗洛阿祝福/tutor.md)。本次不改历史交付源码/DBC/SQL及SHA256清单；新增验收附件与永久知识记录。

复用方法：周期间隔在Aura初始化读取本人灵魂快照，用基础间隔×100/(100+10×层数)；持续时间×(100+10×层数)/100。祝福本人时间项再乘80%，团队增伤用原生1056组规则3取强。HasSpell加HasAura避免队友光环接收者误获本人专属傀儡收益。施放后新增层数不追改已开始周期。C++、Lua、SQL与双端独立DBC成套交付，32位最高位保存使用BIGINT重建值；WD87扩容另行验收。

永久方法：[来源移植](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendskills/trace-and-port-coa-spell-resources/SKILL.md)、[三方案投影](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendskills/build-wotlk-three-build-projection/SKILL.md)。


## 2026-09-29 WD89A 反例更正：空掩码不是排除（代码已证实，修正包待实机）

本地SpellInfo::IsAffected在familyName=0时直接true；非0同家族的空mask也不排除。GlobalScript::OnIsAffectedBySpellModCheck返回false是强制匹配，返回true只是继续原生判断。此前“空DBC mask能保护无关技能”的解释不成立，不再作为可复用保证。

实际当心巫毒9003752/53和扎拉赞恩9003611均family0/空mask，可误延长暗影傀儡。用户反馈单次施放超过5秒仍发射，数据基础3秒/冷却18秒未互换。WD89A提供私有精确来源回退拒绝和实际时间诊断；候选未编译、未实机。既有用户基本验收保留，不能扩大为全负向范围验收。

[源码证据与适配](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609291613_阶段WD89A_天赋范围修正与拟态计时/research/来源与适配.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609291613_阶段WD89A_天赋范围修正与拟态计时/tutor.md)。后续测试必须同时包含合法目标有加成、无关目标无加成、其他职业原生效果不变。别只测“看到增加了”就认定边界正确。


## 2026-09-29 WD87–WD91前批技能用户基本实机确认

用户原话“前面的技能都测试 通过”，[验收补充](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609291627_阶段WD91A_黑暗雕像三目标联动/验收补充_20260929_用户确认前批技能.md)。确认范围是此前累计技能基本使用：WD87洛阿之灵/当心巫毒/巫毒灵魂，WD88涌动巫毒/恶毒诅咒/彼界，WD91黑暗雕像，配套WD89精确范围修正。不继承到WD93，也不替代完整边界测试或UI专项验收。

可复用流程：新增节点保留旧位，C++/Lua/SQL同时扩白名单、预算和mask；同一高阶门槛的节点从前置点数里一起排除，避免相互自举。高于32位用uint64/BIGINT与Lua精确十进制，保存/激活仍走既有角色、方案和revision校验。必须一起交付双端各自DBC、客户端Lua、源码及SQL。

战斗限定先核对“当前已学+本人Aura+GUID”，草稿不授予收益。灵魂与守卫时长用精确私有法术范围；family0/空mask在本核心不是负向排除，WD89对已知私有modifier来源增加原生回退拒绝，不能仅靠GlobalScript返回true保护无关技能。黑暗雕像使用触发子法术适配缺少多目标接口的核心，硬限制额外两目标、触发施法不再扩散，暗影耀斑只认本人的Threads。

源包与教学保留在WD87A、WD88A、WD89A、WD91A；旧WD85A错误DBC不在可用基线，沿用WD85B及后续累计修正。真实计时用服务器TempSummon剩余寿命；这一方法的计时数据与图标是否遮挡施法条要分层验证。


## WD93A CalcAmount回调误用GetTarget：已证实反例

2026-09-29用户实机点击Voice导致服务端C0000005，崩溃栈Amount第23行。DoEffectCalcAmount阶段尚无AuraApplication，本地AuraScript::GetTarget返回nullptr；不能在此阶段调用GetTarget()->ToPlayer。应使用已初始化的GetUnitOwner并检查空值。此结论来自源码与实际崩溃栈，WD93B修正包仍待实测，不能记为已成功。旧74项数据/模型检查遗漏生命周期限制，新增回调API审计。

[证据及教程](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609291753_阶段WD93B_邦桑迪之声施放崩溃修正/tutor.md)。


## 2026-09-29 WD93/WD96前批技能基本验收补充

用户原话“前面的技能测试通过 继续下一轮的修复 移植”，按最近交付范围登记WD93A配套WD93B的邦桑迪之声/力量的代价及WD96A傀儡师之握基本玩法通过。未提供逐跳数值、PvP/机器人、多角色归属、死亡/切方案全部矩阵，不自动扩大为全项通过。WD93B曾因CalcAmount阶段GetTarget为空导致崩溃，GetUnitOwner加空值保护的修正必须保留。此反馈不验收后续WD97B或STONE59B。

[验收补充](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609291750_阶段WD96A_傀儡师之握移动施法/验收补充_20260929_前批技能确认.md)

WD97B新增方案接入仍是候选，未继承本次验收。[批量接入教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609291940_阶段WD97B_通用三天赋方案接入/tutor.md)


## 2026-09-29 WD98A 巫毒末端三项（候选）

战争魔像、恶意魔像、灵魂提线：51位TE方案、智力快照护盾与魔像拦截、500ms减冷却、五分身20层强化爆炸。195数据/源码/模型检查、Lua回归、50隔离SQL通过；未编译部署/实机。巫毒仍剩妖火进阶11133。[覆盖与测试](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609292100_阶段WD98A_巫毒末端机制/README_覆盖与测试说明.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609292100_阶段WD98A_巫毒末端机制/tutor.md) · [来源](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609292100_阶段WD98A_巫毒末端机制/来源与适配说明.md)。
记录为候选方法与待测边界，不新增实机成功结论。


## 2026-09-29 WD99A 妖火进阶分支收尾（候选）

新增免费50级11133：8秒准备、临时替换怒火、最多3目标直伤与9秒可暴击诅咒、10秒独立蛇守卫；52位保存、动作条还原、拟态有界复制。Lua回归、59隔离SQL、104数据源码检查通过；未编译部署实机。Voodoo本地表37/37节点已候选接入，不能等同全部验收。[覆盖与测试](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609292230_阶段WD99A_妖火进阶分支收尾/README_覆盖与测试说明.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609292230_阶段WD99A_妖火进阶分支收尾/tutor.md) · [来源](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609292230_阶段WD99A_妖火进阶分支收尾/来源与适配说明.md)。
仅登记候选方法与待测试边界，不晋升实机成功。


## 2026-09-30 WD99B 编译错误候选修正

用户报告const/最大值/缺game.lib；实际文件含WD99A，局部Unit const*误调用非const法强API。独立单文件改Unit*，WD100同步，未编译待用户确认。[覆盖说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300126_阶段WD99B_妖火系数const编译修正/README_覆盖与测试说明.md)。


## 2026-09-30 WD101A 反例与候选修正边界

只读查明双端DBC/源码同版本不代表Characters存储过程同版本。WD100三项高位在52位旧过程被整单拒绝；同单免费妖火也不保存。用SHOW CREATE与隔离旧/新过程相同参数对照可确定该原因。只查文件哈希不足以宣布部署成套。读查询与写请求不应相互消耗同一限流配额。

显示记录整路径用于M2可替换纹理可能无法正确解析；本次仅私有魔像M2改为直接纹理绑定，不能只查贴图存在就写成渲染通过。分身初始化改为Aura247并保留真实caster，底座不再不可见；根因未运行时抓取，待实机。候选不是新增已成功能力。用户仅确认其余基本机制，视觉失败及四项保存失败明确保留。

[WD101A说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300307_阶段WD101A_保存与召唤外观修正/README_覆盖与测试说明.md) · [验证边界](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300307_阶段WD101A_保存与召唤外观修正/checks/验证记录.md)。


## 2026-09-30 巫毒分支与WD101用户基本验收

用户确认巫毒基本测试及此前三问题已解决。四节点保存、五分身显示、魔像绿色修正登记基本通过；不扩大PvP/机器人/数值全矩阵，WD102独立技能框未单独验收。[WD101验收](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300307_阶段WD101A_保存与召唤外观修正/验收补充_20260930_用户确认.md)。


## 2026-09-30 WD103A 分类基本实机确认

用户原话“现在分类好了”，确认本批分类基本显示通过。客户端增量补100映射、修45分类，双端11傀儡归巫毒的候选包获得分类正向反馈；未逐项展开检查或提供全rank/全部导师资格矩阵，不扩大验收。D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300521_阶段WD103A_技能书与导师三系分类恢复/README_覆盖与测试说明.md

整职业/新分支规划先用[职业移植规划Skill](../plan-coa-class-migration/SKILL.md)核对台账与依赖；单技能修复不重复全量审计。


## 2026-10-01 WD109A 酿造扩容与联动三节点（候选待测）

当前WD105/106累计源码之上追加7129充足药剂、7948灵魂之触、31137丛林秘法；保留WD107/108。旧55节点顺序/存储行不变，扩容C++128位、Lua四limb、SQL decimal，当前开放67位。新品减耗仅佳酿/破咒；两高级节点需8基础酿造TE。Jungle按最新20260925官方Radius9从旧80码修正20码，双端说明同步。270隔离SQL、87数据/源码/旧UI、1984精确数值断言与累计Lua通过；未编译、未实机。正式DB只读连接失败，未生产写入。此条仅候选，不晋升已验证。

[覆盖与测试](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261001/codexfix_202610010819_阶段WD109A_酿造扩容与联动三节点/README_覆盖与测试说明.md) · [教程](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261001/codexfix_202610010819_阶段WD109A_酿造扩容与联动三节点/tutor.md) · [交接](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261001/codexfix_202610010819_阶段WD109A_酿造扩容与联动三节点/phaseFixForNewChat.md)。


## 2026-10-01 WD110–112 三轮累计（候选待测）

承接WD109，接入穆厄扎拉之触、天选之人双拟态守卫、怒气/奥术佳酿互斥选择，共4新节点。诅咒雕像24AE前置无法满足，保持旧拥有方式、不开放新节点；bit67保留禁用。保留WD106空槽、WD107提示、WD108方案显示。最新社区commit ad8df63b9003a003946831ef025677ceb6f6288e；295隔离SQL、59静态/数据/UI、1984整数断言及累计Lua通过；未编译、未实机，未生产写入。所有新技能与WD109仍待用户验收，非已验证案例。

[累计覆盖与测试](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261001/codexfix_20261001_阶段WD112A_三轮累计通用与酿造/README_覆盖与测试说明.md) · [逐步教程](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261001/codexfix_20261001_阶段WD112A_三轮累计通用与酿造/tutor.md) · [交接](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261001/codexfix_20261001_阶段WD112A_三轮累计通用与酿造/phaseFixForNewChat.md)。


## 2026-10-02 WD109A 与 WD110—WD112 用户实测通过

用户明确反馈 WD109A 测试通过，WD112A 累计包的三轮也已通过：WD110 穆厄扎拉之触接入方案保存；WD111 天选之人双拟态守卫；WD112 怒气佳酿、奥术佳酿互斥选择。WD109A 包括充足药剂、灵魂之触、丛林秘法及高位方案扩容。登记本批基本使用通过，不扩展为全等级、PvP、多人归属、断线故障恢复完整矩阵。

后续以 WD112A 累计交付为技能开发基线，保留 WD106 空槽读取、WD107 提示、WD108 激活方案显示，保留旧节点位置与存储行。诅咒雕像 5113 未在本批新开放，bit67 保留禁用；DRBOT1A 龙希尔机器人变形用户正在测试，不能继承这次验收。

已验证方法的基本使用：跨 64 位保存需 C++ 128 位、Lua 四 limb、SQL DECIMAL 同步，不能把完整掩码转 Lua 浮点；新增技能所有权由已保存且激活方案决定。双守卫用两个 GUID 分别检查目标和清理，不能修改全部图腾的通用数量；互斥节点在客户端、C++、SQL 三层一致约束。详细边界沿用原包说明。

[WD109A 教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261001/codexfix_202610010819_阶段WD109A_酿造扩容与联动三节点/tutor.md) · [WD112A 教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261001/codexfix_20261001_阶段WD112A_三轮累计通用与酿造/tutor.md)


## WD114A 排错记录：原生modifier与提示同步是两条链（2026-10-02）
代码已核实：Player::AddSpellMod只按非零mask位发送客户端更新；服务器精确ID钩子可在空mask下匹配成功。这意味着“服务端可能生效”不证明客户端费用显示正确。用户截图未证明实际扣蓝失败，不能据此杜撰运行时根因。WD114A用只读服务器CalcPowerCost/固定效果值同步提示，拒绝旧revision/active/序号回包，并补激活被动恢复；该修正仍为候选，未实机验收。
[阶段教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610020855_阶段WD114A_巫祝数值同步与通用双技能/tutor.md)。下次出现同类问题，先分开核对已保存激活拥有权、Aura、计算入口、实际扣除、提示更新，避免只对显示数字硬乘百分比。


## 2026-10-02 WD114B 数值提示与洛阿强化用户确认通过；其他问题继续核对

用户明确“这个数值显示 测试通过”，随后明确“洛阿强化……这个测试通过”。登记WD114B费用提示刷新/旧数值修正及洛阿强化本次基本使用通过；不扩展为全等级、所有方案故障恢复或全部减耗机制验收。

仍待核对：用户称假死药剂点选后技能书找不到、显性诅咒无技能书图标、强效混合4%/15%与技能书8%/30%不一致。只读核对WD114A：31118 -> 9003853，11323 -> 9003852，12264 -> 9003854；三者SkillLineAbility均为9004巫毒分类。截图技能书选中酿造分类。酿造7131 -> 9003620/9003621，2级8%/30%；通用12264 -> 9003854，1级4%/15%。两节点当前独立拥有，不能把两编号误认成同一记录，也不能未核对上游重叠语义便宣称叠加合理。Allocation.lua酿造7131仍残留“通用树同名节点未开放”旧说明，已记录待统一。

显性诅咒支持的9003150、9003200、9003210、9003220—25、9003762已经同时列入服务端SpellNumbers和NumericTooltip费用同步白名单；不是需要再把其被动技能自身费用减25%。未确认这些技能实机费用。假死/显性技能是否已授予，需要查看巫毒书页或IsSpellKnown结果；没有据此修改生产存档或伪造已修复结论。

本次实际读取永久Skill：trace-and-port-coa-spell-resources/SKILL.md、build-wotlk-three-build-projection/SKILL.md。只读核对现有交付，不新增机制移植；WD114A既有上游证据保留，未声称重新核对最新上游。

来源：000Ascendupdate/000Ascendupdate20261002/codexfix_202610021638_阶段WD114B_巫祝提示重绘优化/README_覆盖与测试说明.md。WD113/114其他节点、DRBOT1A仍不能登记全部通过。


## 2026-10-02 WD115A 假死通过、图标和强效混合同源整合候选
用户明确假死药剂可以了通过；假死/显性图标已在最新截图显示，旧漏项假说不再作为根因。仅假死基本机制验收，不扩展显性25%费用和全部方案边界。
本批复用trace-and-port-coa-spell-resources及build-wotlk-three-build-projection。假死官方节点图标7e06e90aea7e069e现有可复用，Spell误用了巫祝图标，独立SpellIcon修正。强效通用12264和酿造7131引用同源503748/504888，保留方案位和投资，最高等级合并至9003620/21，撤销旧重复9003854，不叠加。中文名和图标统一，双入口提示重复投资无额外收益；不自动退款或改旧方案。
上游HEAD d7620151fa4267ab90c7e0554b32628017df241a，Issue1290/2190、最新场景和相关PR搜索已存档。Data/Content进阶JSON没有这些法术且同号ID跨版本复用，不能当当前服务器开放配置；双入口保留是本项目兼容策略。上游固定威胁与说明百分比差异未照搬。
双端限定记录/所有字符串偏移、Lua语法、72组状态模型通过；未编译、未部署、未实机；模型不是运行证据。WD114B数值提示保留，只有增量inc/Lua/DBC/图标，无SQL。方案/点数/购买记录均不改。技能总完成度不提升。
[WD115A说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022030_阶段WD115A_假死图标与强效混合来源审计/README_覆盖与测试说明.md) · [教程](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022030_阶段WD115A_假死图标与强效混合来源审计/tutor.md)。ZIP SHA256 `be987886df6c41099cbd345d3b0edba5a4ed062eb2524440908a971115003d27`。


## 2026-10-02 WD116A 沃金守望通用防御技能（候选）
新增节点6042->9003855，隐藏治疗9003856；先9基础AE后1AE，跨专精，bit77精确存储。原生25%减伤、1秒一次2%最大生命治疗、10秒持续、120秒冷却；受原生治疗修正。官方图标与天赋一致，视觉兼容复用原生树皮术，未宣称CoA独有特效。
累计WD114与WD115整合，保留数值提示、原方案和购买资格。WD115仍未用户实测。使用plan-coa-class-migration、trace-and-port-coa-spell-resources、build-wotlk-three-build-projection。来源commit d7620151fa4267ab90c7e0554b32628017df241a，官方504465/681004/503598，上游周期修正已查。灵魂行者未开放。
342隔离SQL、累计Lua、20数据检查及全部Lua语法通过；未编译未部署未实机。初次测试因缺schema夹具中止，补齐后通过；旧bit77越界测试更新为78。不能将候选登记成功。需要Characters WD116A SQL，旧版本unknown-node守卫禁止带新节点回退。
[覆盖说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022006_阶段WD116A_沃金守望通用防御技能/README_覆盖与测试说明.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022006_阶段WD116A_沃金守望通用防御技能/tutor.md)；ZIP SHA256 `7bb6b2411a0c0a556191b86ac40fa623d64993cee897b5098b40121a270f4b49`。


## 2026-10-02 WD117A 灵魂行者双技能联动（候选，未编译未实机）
在WD116累计基础新增9347双级9003857/58，10%/20%增强沃金及迅捷持续和效果，精确80位保存。一级整数光环27%、二级30%；恢复在实际治疗量上乘10%/20%，不提前截断2.2%。等级变化清旧增强效果不重置冷却。复用节点官方图标；服务端提示支持持续、减伤、基础逐秒恢复和迅捷增幅。
上游commit d7620151fa4267ab90c7e0554b32628017df241a，Completion将SpiritWalkerOne第二效果修正9（10%）。354隔离SQL、累计Lua、25数据/源码及全部Lua语法、数值提示回归通过。WD115/116/117均仍候选，先验收再推进其他依赖。
使用plan-coa-class-migration、trace-and-port-coa-spell-resources、build-wotlk-three-build-projection。覆盖说明：[codexfix_202610022033_阶段WD117A_灵魂行者双技能联动](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022033_阶段WD117A_灵魂行者双技能联动/README_覆盖与测试说明.md)；教学：[codexfix_202610022033_阶段WD117A_灵魂行者双技能联动/tutor.md](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022033_阶段WD117A_灵魂行者双技能联动/tutor.md)。ZIP SHA256 `ba2e743f813316cceb0daaf1c3f5abf5a7a2daaee52449b222ac90e155f17bc6`。


## 2026-10-02 WD118A 化蛇通用生存技能（候选）
基于WD117累计，节点29306->9003859、隐藏9003860，30级9基础AE后1AE、bit80。5秒化蛇、80%移速、已有定身/减速解除、60秒冷却；保留禁止攻击施法且可取消。配套原始远程/法术命中修正-100个百分点、80%游泳；非全伤害免疫。现有蛇模板2914及四模型客户端存在，节点图标一致，未移植CoA专属粒子链。
最新上游d7620151fa4267ab90c7e0554b32628017df241a，PR6192已合并；独立父/子生命周期与方案撤销。Characters WD118及World绑定SQL必须成套，旧节点和购买状态不清。367隔离SQL、累计Lua、30数据/源码及提示检查通过，未编译未实机；WD115–118仍待验收。
使用plan-coa-class-migration、trace-and-port-coa-spell-resources、build-wotlk-three-build-projection。首次全量旧level20用例失败，定向成功；新增等级分支补ROLLBACK后全量完成，证据见checks。完整说明与教学：[README](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022101_阶段WD118A_化蛇通用生存技能/README_覆盖与测试说明.md)、[tutor](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022101_阶段WD118A_化蛇通用生存技能/tutor.md)。ZIP SHA256 `302b7254571ee0b44ba30d95b9cc4a3c64fb5e410843e73c5e11560c8445550f`。


## 2026-10-02 WD118B 原生拖动图标资源补齐（候选）
用户确认WD115假死书页图标修改可见，拖动可放动作条但鼠标图标透明。五个新增SpellIcon路径的BLP此前只在02插件目录交付，当前全MPQ扫描未命中。补齐原路径5BLP到MPQ输入；不改DBC/Lua/源码/SQL，兼容WD115–118，待实机确认光标。无机制新增，仅本地资源链审计。以后累计交付同时包含磁盘与MPQ资源；不能因界面能显示而省略原生入口验证。
使用trace-and-port-coa-spell-resources。五BLP头/尺寸/引用/哈希、归档扫描及ZIP完整性已查。说明：[WD118B](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022208_阶段WD118B_原生拖动图标资源补齐/README_安装与测试.md)；教程：[tutor](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022208_阶段WD118B_原生拖动图标资源补齐/tutor.md)。ZIP SHA256 `fafcb38ceb02d34065360acfbbd5fec393d395cd44cd7b9d79065af3be3128ce`。


## 2026-10-02 拖动图标与沃金守望用户基本验收
用户原话：“这个图标拖动的时候可以看到了 沃金守望：测试通过”。确认WD118B补齐MPQ资源后，本次假死药剂拖动光标显示恢复；沃金守望基本使用通过。不扩大为全部五图标逐一确认、灵魂行者增强、化蛇、PvP或多人完整矩阵通过。
来源：[图标修复](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022208_阶段WD118B_原生拖动图标资源补齐/README_安装与测试.md)、[沃金守望](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022006_阶段WD116A_沃金守望通用防御技能/README_覆盖与测试说明.md)。原ZIP不改写。
复用：原生SpellIcon引用的新BLP同时交付插件目录与MPQ内部准确路径；书页可见不代表原生鼠标加载可见，分别测书页、拖动光标、落入动作条。沃金守望以独立主动/隐藏周期治疗分工，激活方案授予和撤销，不能因图标出现推定保存或机制通过。本条以用户明确的基本测试结论覆盖原候选状态，其他未测项保留。


## 2026-10-02 WD119A 蛙变术与双祝福（候选待测）
承接WD118A累计，合并用户已确认拖动可见的WD118B。新增Class6031蛙变术9003861、6525贡克祝福9003862、12525克拉格瓦祝福9003863，26级/9基础AE/每项1AE；两祝福互斥且要求父技能。40秒普通目标、玩家8秒后原生递减、伤害解除、临时野兽类型，1秒120秒/1.5秒60秒/瞬发120秒三种基础状态；服务端数值提示同步。保留旧方案和购买，bits81–83追加，84位三端一致。
最新社区commit d7620151fa4267ab90c7e0554b32628017df241a、已合并PR4753及934/1179/3693和当前场景已核对；官方20260925Spell500952/806469/807855单独记录。原模板216377本地缺失，复用原生Hex蛙13321；未导入CoA独有粒子。当前Patch-XA被锁错误32，登记解包引用存在不等同实际MPQ/渲染验收。
388隔离SQL、53数据/静态、累计Lua/语法/提示模拟通过；未编译未部署未实机。首次SQL旧回退断言失败为新增测试before变量含购买表导致口径不一致，修正夹具后全量通过。用户本轮沃金守望基本通过已另行登记，灵魂行者/化蛇和本批不继承。
使用plan-coa-class-migration、trace-and-port-coa-spell-resources、build-wotlk-three-build-projection。交付需Characters WD119；未装WD118需World118绑定。详情：[覆盖说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022255_阶段WD119A_通用控制三技能/README_覆盖与测试说明.md)、[教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022255_阶段WD119A_通用控制三技能/tutor.md)、[来源](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022255_阶段WD119A_通用控制三技能/来源与适配说明.md)。ZIP SHA256 `51c3063a16dcd0f24ca3c5d8a2e9c093f11b98ce84dbfbcf2b8b12690c386733`。


## 2026-10-03 前批基本验收与WD119A状态澄清
用户先说“前面测试都已经都通过，继续下一批”，随即明确“我来测试 WD119A”。因此前批WD117灵魂行者、WD118化蛇及WD119B面板/提示按用户总体反馈登记基本测试通过；WD119A蛙变术、贡克祝福、克拉格瓦祝福保留待测，不将总体反馈扩大到随后明确正在测试的包，也不扩大成全PvP/多人/全部数值专项通过。既有WD118B拖动与沃金守望验收保留。
下一批来源审计目录：000Ascendupdate/000Ascendupdate20261003/codexfix_202610030147_阶段WD120A_酿造下一批依赖开发。该目录仅研发证据，无可安装新包；未改运行源码、客户端或生产数据库。


## 2026-10-03 WD119C 蛙变冷却与移动回归（候选待测）
WD119A用户发现贡克查询60秒但客户端实际倒计时120秒，以及移动不中断读条。Player.cpp精确补9003862→9003861的最终冷却包；双端9003861 InterruptFlags14→15补MOVEMENT位；提示识别秒施法时间。保留WD119B。累计Lua、逐字段数据差异与源码范围检查通过，未编译未实机；不宣称WD119A整体通过。需源码重编译+双端DBC+Lua，不需SQL。
[覆盖说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610030224_阶段WD119C_蛙变冷却同步与移动打断/README_覆盖与测试说明.md)；ZIP SHA256 2d464fbaa1401cacf87881fb8a51bd105bd6392466e1fa40a8fb5640ef04e170。


## 202610030327 WD120A 酿造基础三节点（候选待编译/实测）
已完成4005大锅酿造、12645丛林蘑菇、12646药水投掷的有界接入：免费酿造节点、配料6秒范围治疗、投掷7级+18秒HoT。保存扩87位，旧位与购买账本保留；World手动系数避免重复加成；节点/技能书/拖动图标一致。当前治疗参考范围读取服务端，不依赖草稿。基线WD119A累计+已验收WD119B+候选WD119C；WD119C和本批尚未实机通过。
上游在线固定d7620151fa4267ab90c7e0554b32628017df241a；字段232是描述变量ID，实际802703等级缩放来自ScalingBase实现。不能将早期字段误判继续复用。仅蘑菇一种配料，其他配料和泼洒仍未开放；外观复用既有洛阿佳酿887925，36项引用资源已只读找到，不宣称大锅模型或专属药瓶弹道完成。
403项临时MySQL与累计Lua/DBC检查通过；C++没有编译，没有修改运行目录或生产数据库。一次历史GM测试断言未复现，原路径未声称修复，详见memory。
[覆盖说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610030147_阶段WD120A_酿造下一批依赖开发/README_覆盖与测试说明.md)；[逐步教程](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610030147_阶段WD120A_酿造下一批依赖开发/tutor.md)；[交接](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610030147_阶段WD120A_酿造下一批依赖开发/handoff.md)。ZIP SHA256 `02ee4367bc97f2f9df779b800886cc20a5759539b88a3b62c26ab8e134fea71c`。旧ZIP不改写。


## 202610030403 WD121A 酿造治疗双天赋（候选，未编译/未实机）
基于WD120累计，新增6498新鲜配料两级9003877/78（大锅蘑菇15%/30%）和29303药水增效9003879（投掷及蘑菇HoT20%）。90位保存、79项映射，基础8酿造TE后每级1TE，同层不计前置；保留旧方案及购买。节点/书页/拖动图标一致，权威治疗提示走同一原生done healing路径。WD119C及WD120仍候选，不把继续开发请求当验收。
本批在线HEAD ccaf63902e3d244953d0bed991aae79fdc32055c；Issue1142关闭但PR4753仍needs-decision。官方20260925本地Fresh op0与社区场景op22/目标冲突，按大锅描述精确限定；PotionBoss由op8适配末端op0/op22使手动系数一并增强，差异明示，不声称官方服务器完全一致。
414隔离MySQL、累计Lua/旧UI、双端旧行/字符串、720数值负向模型通过。首次历史war等级拒绝断言失败未捕获原值，后续完整追踪复测及20次重复拒绝通过，未根因、不称修复。未生产写入、未编译、未实机；尚不晋升已验证Skill。
[覆盖测试](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610030339_阶段WD121A_酿造治疗双天赋/README_覆盖与测试说明.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610030339_阶段WD121A_酿造治疗双天赋/tutor.md) · [来源](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610030339_阶段WD121A_酿造治疗双天赋/来源与适配说明.md) · [交接](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610030339_阶段WD121A_酿造治疗双天赋/handoff.md)。ZIP SHA256 `61a121430c0696d33f4991142ad71cb7e4107e2cbeb1588c8615ad159d47b220`。


## 202610030712 WD121B 蛙变术施法后冷却同步（候选，未编译/实机）
用户继续反馈提示60秒、动作条2分钟。源码定位WD119C早期发送后仍有SPELL_GO预测路径；原WD63E施法后纠正仅处理Hastened。本包补Gonk9003862→frog9003861精准匹配，读取服务器剩余毫秒并只重置客户端计时，不二次扣减或删除服务器记录。Player.cpp保留WD121A字节基线。
32项静态/双端数据/消息模型检查通过，未抓包或实机，不晋升已验证修复。上游在线HEAD a670f706882fa8e4014bc8bb943663a48f616804。专项源码包需用户覆盖、编译并重启，无本次SQL/DBC/Lua变更；下一批开发不替代本项验收。
[覆盖说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610030705_阶段WD121B_蛙变冷却施法后同步/README_覆盖与测试说明.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610030705_阶段WD121B_蛙变冷却施法后同步/tutor.md) · [交接](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610030705_阶段WD121B_蛙变冷却施法后同步/handoff.md)。ZIP SHA256 `34acda358562d324b3c84027f90fba5dd4142214410b123b3f166246e3db2f63`，旧归档不改写。


## 2026-10-03 WD120A三技能及WD119C/WD121B蛙变三状态：用户实测通过
用户明确逐项确认六项通过：免费大锅入口、蘑菇每6秒范围治疗、7级投掷/15秒冷却/18秒蘑菇HoT；贡克动作条60秒、普通/贡克移动打断、克拉格瓦瞬发移动施放。仅登记列明行为，未外推完整PvP/等级/机器人/重登矩阵。冷却同步验收为WD121B补全后的组合，不抹去WD119C早期遗漏。
WD121A新增新鲜配料15%/30%与药水增效20%仍待用户明天测试。保留WD121B，旧归档不改写。
[六项验收与续测交接](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/WD120A_WD119C_WD121B_用户六项实测通过.md)。


## 2026-10-03 WD121A实测通过；WD122A蘑菇互斥双天赋候选
用户确认新鲜配料15/30%及药水增效20%测试通过，已[登记验收](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/WD121A_双天赋用户实测通过.md)；不外推完整场景矩阵。
新WD122A：6020→9003880丛林绽放+100%/5人/6秒，29737→9003881丛林医师8人/4秒，共组706545互斥。81节点映射、92位精确保存，8基础酿造TE+1TE，SQL/C++/Lua均校验。目标cap及周期实时提示；切方案重算现有准备Aura，保留WD121B字节基线。
425项隔离SQL、累计Lua/DBC检查及378数值组合通过；未编译/部署/实机。在线HEAD e7c0ccabb18456bb8aac2aaba55bc799381b9b26，官方-3目标、-2000ms独立核对。早期测试夹具语法/枚举错误及注册阶段空Spell风险已静态纠正，边界见memory。
[覆盖说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610031523_阶段WD122A_丛林蘑菇互斥双天赋/README_覆盖与测试说明.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610031523_阶段WD122A_丛林蘑菇互斥双天赋/tutor.md) · [交接](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610031523_阶段WD122A_丛林蘑菇互斥双天赋/handoff.md)。ZIP SHA256 `b1b494f939234f7a4ae443af1fd63915227e224336229274cfa89175d5d7899e`。新阶段待验收，旧ZIP不改写。


## 2026-10-03 WD123A 泼洒药水与蘑菇范围治疗（候选待实测）
新增7128→9003890–96七等级，17级/1TE/酿造，40码地点、10码8友方、独立15秒、20%基础法力。正确蘑菇803698→隐藏9003889，12秒/3秒，不误给803273鱼油。上游未关闭6294与常量颠倒证据记录，在线HEAD e7c0ccabb18456bb8aac2aaba55bc799381b9b26。
82项映射/93位保存；较早层级泼洒1TE计后续8基础。药水增效只增加新HoT20%，不增泼洒直接；旧投掷与大锅天赋保持。WD122A仍未获验收，WD121B字节保留。
441隔离SQL、累计Lua/DBC、384离线组合、36项既有视觉资源检查通过，未编译/部署/实机。只用覆盖包，不写生产数据库；旧ZIP不改写。
[覆盖说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610031548_阶段WD123A_泼洒药水与蘑菇范围治疗/README_覆盖与测试说明.md) · [来源](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610031548_阶段WD123A_泼洒药水与蘑菇范围治疗/来源与适配说明.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610031548_阶段WD123A_泼洒药水与蘑菇范围治疗/tutor.md) · [交接](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610031548_阶段WD123A_泼洒药水与蘑菇范围治疗/handoff.md)。ZIP SHA256 `33a8ba7a096ce1848b861710d6af1e2145db91333bc440f5909674246a3b0d38`。


## 202610040721 WD122B 编译枚举修正（待用户编译）
WD122A用户报告未声明目标枚举，WD123A亦继承。当前核心TARGET_UNIT_CASTER_AREA_RAID=56；两个隔离单文件版本仅替换错误符号，双端9003866目标56核对一致。modules.lib缺失很可能是连带错误。之前静态检查遗漏枚举声明，不能声称已编译通过；本次亦未编译/部署/实机。保留原ZIP和生产文件。
[说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261004/codexfix_202610040721_阶段WD122B_范围目标枚举编译修正/README_覆盖与测试说明.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261004/codexfix_202610040721_阶段WD122B_范围目标枚举编译修正/tutor.md)。ZIP SHA256 `723474723e7ff16174015ec842890b70e8d16d1b6a2965b0380de06f1b311510`。使用trace-and-port-coa-spell-resources，符号存在性检查纳入后续审计。


## 2026-10-04 WD122A 用户本批测试通过
用户明确反馈“WD122A 累计测试包测试通过继续下一批技能的开发”。在WD122B编译修正交付后登记WD122本批基本测试通过；未获得逐项日志，不扩大成全部数值、多人、机器人、切方案矩阵均验证。下一累计版本必须合并TARGET_UNIT_CASTER_AREA_RAID=56的兼容修正，历史WD122A原ZIP仍有已知编译错误，不能重新直接使用。WD123泼洒药水仍候选待测。
来源：000Ascendupdate20261003/codexfix_202610031523_阶段WD122A_丛林蘑菇互斥双天赋；修正：000Ascendupdate20261004/codexfix_202610040721_阶段WD122B_范围目标枚举编译修正。
复用：互斥天赋的保存、激活被动、目标人数和周期提示一并接入；枚举须查目标核心声明。周期重新计时不能凭空增加治疗跳数。基本验收不能替代未测边界。


## 2026-10-04 WD123B 泼洒药水累计候选
承接用户WD122测试通过，将WD123A七级范围治疗与12秒/3秒蘑菇HoT合并WD122B正确枚举；累计Lua/DBC检查重跑通过，66个其余安装文件与WD123A字节一致。SQL历史441项隔离验证，本轮未重跑。未编译/部署/实机，上游刷新失败已明示。
[覆盖说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261004/codexfix_202610040753_阶段WD123B_泼洒药水累计与编译修正/README_覆盖与测试说明.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261004/codexfix_202610040753_阶段WD123B_泼洒药水累计与编译修正/tutor.md)。ZIP SHA256 `601d3b2d0ab69f45f94d76dbffc4613dd6477511688d99619e0b85bcd66531a1`。

## WD123B 泼洒药水基本实机通过（2026-10-04）
用户确认泼洒药水与蘑菇附加治疗测试通过。它们是一项可选主动技能与其隐藏HoT，不是两个独立天赋。复用经验：进技能书/动作栏的主法术和隐藏触发效果必须分离；官方资源中803273鱼油与803698蘑菇不可颠倒；治疗目标与持续跳数、双端DBC、SpellIcon及服务端治疗系数同步。WD123B来源：[覆盖说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261004/codexfix_202610040753_阶段WD123B_泼洒药水累计与编译修正/README_覆盖与测试说明.md)。只记基本验收；WD124A药水投手/药师/再生者仍候选，真实冷却/回蓝/治疗/属性需用户验收。


## 2026-10-05 WD113—WD127技能闭包与图标验收

保存完整获得方式、主/子ID、效果、方案撤销与数字通路。WD118B五BLP补MPQ使原生拾取可见；技能书可见不证明鼠标资源可加载。WD115同源强效混合用最高级、不重复授予。WD120—123治疗与隐藏子效果不是两份天赋。药师／再生者编码疑点不晋升数值成功。

来源及限定验收：[本窗口证据](references/wd113-wd127-window.md)。最终药水同步使用[synchronize-wotlk-spell-costs-and-cooldowns](../synchronize-wotlk-spell-costs-and-cooldowns/SKILL.md)。旧失败包不作为成功基线。
