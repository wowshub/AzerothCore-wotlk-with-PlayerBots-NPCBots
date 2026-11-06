---
name: port-wotlk-custom-race-creation-flow
description: Audit and port a WotLK custom race through creation, character selection and first login; diagnose enumeration/class-state leaks, missing Glue scenes, language, reputation and starter-item symptoms using current client/server baselines. Use for a new playable race or its creation/first-login failures, not class talents or standalone NPC model replacement.
---

# 自定义种族：创建到首次进入世界

本流程提炼自蛇人、双头食人魔的限定实测和失败案例；不是“任何新种族完整可玩”的认证。先读项目AGENTS/rule、协作登记与所有相关成员的交接；改共享文件前登记，用户自行导入、编译、执行SQL。实际输入哈希优先于旧目录名称。

## 1. 分清身份和容量

- 分别记录服务器raceID、Glue枚举索引、ChrRaces文件token、显示名称、阵营、性别、Display/ModelID。按钮第几个不是raceID，同名种族也可能不同阵营。
- 先查占用和实角色/NPC/掩码引用。36/37仅为本案已用编号，不能让下一种族继续照抄；22曾被误当空位，实际已有角色。
- `MAX_RACES`变大不代表所有原生数组和32位掩码已扩。ID>32不能直接`1 << (race-1)`，不能用移位溢出伪造低位资格。审批通过的模板兼容应局限语言/声望/通用装备等指定用途，不能替换真实种族身份或继承整套母族天赋。

## 2. 基线与资源完整性

扫描正式客户端Data及语言目录、松散文件、同路径MPQ和有效加载来源。服务端根DBC和locale分别核对，不能用客户端整表覆盖服务端。记录读不到的归档和影响；不要说“全扫描通过”。新种族私有资源按当前Y分区规则，共享创建脚本回归累计YB，YA历史地图保留。职业XA/XB及Claude DLL遵循各自归属。

模型按M2/SKIN/ANIM/BLP及Display→Model链闭合；只识别MD20版本不是资源完整。双头食人魔必须实查双头模型，不拿单头代替；文件夹名Female不等于模型外观一定为女款。创建可见、角色选择可见、世界可见是三个独立检查。

## 3. 创建资格和UI状态必须一致

客户端DBC列出组合、Glue职业白名单、原生实际选中职业、缓存、按钮和“下一步/提交”，以及服务端建角白名单必须一致。当前首测仅战士，不代表所有未来新种族必须仅战士。

每次选种族/切性别都按当前状态重算；测试“未开放种族→新种族→经典种族→新种族”，不能只在干净打开时看一次。Disabled、普通/按下图标去色、alpha、灰罩、选中圈和独立巫医/武僧/猎巫按钮是不同控件状态，不能只点亮黄圈。切回旧种族由它原有的职业资格计算，不把新种族限制泄漏过去，也不强行开放所有职业。

不要依赖“先点人类/兽人就正常”作为操作要求，这是状态残留的反例。避免每帧反复查询/重写原生种族模型；优先修事件收尾。最终CreateCharacter路径（包括XML和付费槽确认）仍需检查实际选择，不能靠画亮按钮绕过服务器资格。

**状态边界：** RACEUI1A的随机名/背景已用户通过，职业切换被用户否定；RACEUI1B已被用户否定：遗漏RebornRacePreview.Open真实入口，且误显示列表selection长框。RACEUI1C已在真实Open接桥、隐藏长框，2026-11-05用户确认正常，见文末限定验收。离线通过不等于游戏通过。不要把B写成已验证范式。事件末态复核是诊断/候选实现建议。

## 4. 角色选择黑屏与蓝白方块

当世界内模型正常、角色选择背景黑且有方块，先追Glue的`GetSelectBackgroundModel→SetBackgroundModel→SetCharSelectBackground`，检查token拼出的背景路径实际是否存在。若仅缺场景，可按批准阵营复用已有背景；只别名场景，不换种族ID、不换正常世界模型。保留SelectCharacter真实角色加载与其它种族路径。

本案在已读归档缺UI_REBORNSETHRAK/UI_REBORNOGRE，现有Human/Orc分支可读；用户确认修后无蓝白方块。原世界模型正常是重要定位证据，不要再次整套换M2/贴图。

## 5. 随机名字

先看按钮真实OnClick和原生GetRandomName结果。新token缺NameGen记录时可以使用经说明的同阵营模板/同性别本地候选池；优先保留正常原生结果，只在空/重复时回退。相邻点击不重复不等于服务器名字可用，最终重名/合法性仍交给服务器。

## 6. 出生初始化：逐层验证，不盲补

| 症状 | 先检查 | 不要直接做 |
|---|---|---|
| 不能说话 | 阵营语言法术与技能、当前聊天语言、创建与登录恢复链 | 给所有语言/绕过聊天检查 |
| 声望空白 | 服务端实际Faction默认值/flags/模板掩码与存档、客户端筛选 | 重置已有声望或声称只换模型能修 |
| 裸体/没武器 | 检查背包、CharStartOutfit性别行、item_template、穿戴资格和初始化先后 | 重复发装备/解除全物品限制 |
| 技能缺失 | playercreateinfo_skills及加载时racemask、SkillRaceClassInfo、技能法术授予与注册 | 只加DBC行就认定服务器会授予 |
| 男女表现不一 | 对比真实性别键与操作顺序；重新登录/检查包内物品 | 直接认定女模型没做或给男角色数据整表覆盖 |

本案用户先报女性无装备/语言，后确认男女都有、物品在背包、旧角色恢复说话。不能把最初症状继续当最终事实，也不能反向声称自动穿装已修。旧角色修复应精确缺项、保留已有数值/装备，不反复登录发奖。

## 7. 最小验收记录

两族男女：冷启动直接选、从未开发种族切回、旧职业→新族战士、反复切性别、自定义返回、连续随机名、创建、角色选择、进入世界、语言、声望、技能、身上与包内装备、退出重登。再回归旧种族/旧职业。

裸模和首登通过不包含骑乘、游泳、跳跃、全部装备/头盔、施法/受击/死亡、任务声望、种族技能及PvP。分别记录“离线/用户基本通过/专项/已发布”，冻结旧包，不把未验收依赖夹进发布。

案例与哈希：[验收边界](references/acceptance-20261105.md)。教学：[TUTOR.md](../../beascendtutor/port-wotlk-custom-race-creation-flow/TUTOR.md)。

## 2026-11-05 RACEUI1C：真实自绘入口与职业状态已用户基本验收

用户原话：“现在 正常了 帮我把这次修复和之前的修复 一个一个 成功的修复做个commit 并推送吧 把这次 这个选择战士 其他职业灰色的 切换 成功修复写进skulls 为以后复用”。确认C修后的基本切换行为；不扩展为所有种族/付费服务/装备或种族技能专项通过。

可复用步骤：
1. 沿XML脚本加载、按钮SetScript追真实入口；本例上排自绘按钮走RebornRacePreview.lua的local Open，并不走CharacterRace_OnClick。不能只给标准入口做大量模拟。
2. Open切换种族/性别/模型后，显式调用同一职业刷新桥：按当前枚举重算职业→同步真实选中职业→同步UI。名单、原生选择、缓存、下一步、最终提交保持一致。旧种族沿原资格规则恢复；不强行全开，也不泄漏新种族“仅战士”限制。
3. 控件逐层同步：Enable/Disable、普通图与按下图去色、alpha、灰罩、文字、常驻职业环。巫医/武僧/猎巫是独立按钮，也要处理；返回旧种族先恢复样式，再由它原本的白名单计算资格。去色参数明确传bool，不靠遗漏参数保持/恢复旧状态。
4. 选中效果先查真实贴图用途。本例button.selection是XML中256×96的人物列表长条，不是职业圆环；隐藏它，保留现有CheckedTexture圆环。不要凭字段名Show一个未确认的图层。
5. 测试必须使用实际Open函数体，穿插旧种族其它职业→未开发种族→蛇人→旧种族→食人魔、男女与自定义返回。本例13组Lua5.1、1500次真实Open路径替身检查之后，又由用户确认C正常；这两种证据分开保存。

来源：D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261105/codexfix_20261105_阶段RACEUI1C_真实种族按钮刷新与长框修复.zip，SHA256 f8fe4e18d0929bad7ff09a47c37892b1de6620beba05f7c61f1a6001df722ad4。最终两Lua已与现场YB逐字节匹配。A随机名字/选角背景也已通过；A/B失败记录保留，不给失败中间包补写成功。Skill记录不等于已推送/Release，发布证据另列。
