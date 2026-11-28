---
name: port-wow64-playable-race-end-to-end
description: Port a playable race into this RebornWOW64 project from identity and creation icons through male/female appearance, equipment, classic classes, first login and shared starting zones. Use before adding a new race or auditing a cumulative race port; routes to existing model, UV, cloak and creation skills and requires evidence before delivery.
---

# 新种族从按钮到进入世界的一次移植流程

目标是把可提前发现的缺项在交付前解决，减少让用户反复查漏。此流程不承诺未运行客户端也能证明零bug；离线、真实引擎、用户基本验收分别记证据。2026-11-28用户总体基本通过本窗口最终修复，全部肤色/装备/职业/动作未逐项确认。

## 先做输入契约

1. 读项目AGENTS/rule/ref、协作说明和相关交接。登记真实server raceID、客户端枚举/Glue token、阵营、男女Display/Model、模型路径及全部同路径覆盖来源。对每个输入存SHA256。
2. 确认授权的职业集合、出生路线、DK两种模式、是否双形态、哪些部位原生装饰不可被装备贴图替代。用户给的截图是视觉目标，不据此猜骨骼编号。
3. 核对最新远端与源供体。32位旧移植成功时先查当年资源/贴图类型/geoset，不拿旧DLL地址直接套64位。男女分开，不把女性正常推导成男性正常。
4. 本项目新种族/新职业归Codex；Claude的地图、缓存、建筑overlay及RetailCasc.ini按登记保留。未测交叉内容不混入发布。

## 按依赖完成八道检查

| 阶段 | 交付前应得到的证据 | 对应专项 |
|---|---|---|
| 身份与入口 | ID未占用，图标路径/男女头像可读，客户端职业UI、原生选择、双端DBC及服务端白名单一致；旧族切回不泄漏状态 | port-wotlk-custom-race-creation-flow |
| 模型闭包 | 胜出M2/SKIN/ANIM/BLP、Display替换贴图、LOD/索引/材质/alpha有效；NO装备的脸与原装饰正确 | port-coa-race-appearance-wxl |
| 衣物UV | NO/T7/T14，头/脸/腿/脚与衣物区域独立；实际引擎BLP格式正确；原贴图和UV守卫通过 | overlay-armor-on-nonstandard-uv-race-models |
| 装备挂载 | 男女分别查盔11、肩甲、手持/背负/腰间；按武器类别与真实socket适配；重复刷新无累积，预览和世界均考虑 | repair-wow64-race-helmet-fitting |
| 披风与动作 | 穿/脱/隐藏；实际1501..1510网格与type2/透明轨道闭合；坐下/过渡/对话/起身/行走地面高度 | add-cape-geometry-to-custom-race-m2 |
| 出生与职业 | 物品确实在目标WORLD、可穿可用；语言、技能、声望、各本阵营职业任务、猎人弹药/图腾/DK技能线 | 创建Skill基础回归表 |
| 完整首登 | 建角→选角→首次进世界→模式介绍→开始冒险；背景路径/相机空数组；出生点/炉石/开场镜头/持久化事务 | 本文出生检查 |
| 累计与回归 | 当前EXE与源码/本地inl依赖对应、MPQ胜出输出匹配、双端DBC独立、负例/旧族不变、包内编译成品与回退 | 本文交付检查 |

每步写“预期/实际/证据/未覆盖”。有确定失败不先扩展新功能。先用脚本批量发现资格、文件和矩阵问题，再给用户一张集中最终检查表；不要把单个桩测试通过称作游戏成功。

## 出生路线与职业初始化

- WORLD路线、网络尾包和两张CHARACTERS出生持久化表分别审计。流放岛slot13/zone141；当前联盟map12261、部落12369属于本项目配置，应从目标表确认，不固定照搬下一项目。
- WORLD两行存在且worldserver已重编不等于建角事务能保存。看真正ERROR appender，检查CHECK/枚举/字段类型；CREATE TABLE IF NOT EXISTS不会更新已有约束。
- 新注册种族复用141，不为每族再增出生数据库枚举；真实race/class/sex资格仍由创建服务端验证。保留旧DK zone0与两模式分流、旧角色记录。
- 53428符文熔铸有法术但打不开面板：沿SkillLineAbility→776→SkillRaceClassInfo936与已学技能恢复检查；配方/任务不是同一验收。
- 出生装按目标item_template逐项检查Class/SubClass/Allowable/RequiredLevel/Skill，不能直接复制供体900xxx定制物品。SQL按实际schema使用字段；InhabitType不存在时先看当前结构，不能盲发同一UPDATE。
- 所有新种族应纳入本阵营原版职业任务资格审计；此前交接列出的未实现缺口仍需单列，不因总体通过就声称全部职业任务已完成。

## 空间与动画：交付前先证明方向

骨骼局部Z不是人物竖直Z。M2挂点Translate先经过骨骼旋转；应测完整socket→bone→actor→view→weapon-local链。需要固定身体向下时，在当帧骨骼变换后加actor空间位移，保留原角度/尺寸；其它调用默认零偏移。STARTFIX1F的-0.55仅是龙希尔本次参数，不是所有种族通用常量。

剑/斧/双手锤/杖按类别检查，不能只修某一把符文剑；单手腰间策略可保留。对握柄和末端同时测到背部间隙，避免“角度正确但悬空”或穿肩。预览复制附着frame时保留修正，拔武器/换父/变形/销毁时失效清理。

坐姿正确不保证对话正确。按lookup追真实sequence/alias owner和外部ANIM，采样完整过渡与根骨最低点；按该动作校正根平移和包围盒，不抬高整个人物破坏站走跑。

## 累计编译和交付

- 把引号include的同目录inl也纳入依赖闭包，记录实际include来源；曾漏EsteriaNativeEquipment.inl/RebornNeutralClothing.inl导致121配置静默回退，仍能编译成功。
- 修改CPP/头文件后确认真正重编译对象与链接库；EXE哈希、源文件、资源输出建立一张映射。只交源码不满足用户要编译包的指令；服务端编译/部署仍按当次授权。
- 禁止旧快照整表/整MPQ回盖；包只提供路径级导入文件，客户端与服务端DBC独立保留其它记录。发布保留所有依赖来源，最后包不等于完整并集。
- 自动验证至少有无效输入/不符合条件/旧族/反复触发反例；空间修改用真实矩阵库或引擎链验证，不只断言局部坐标减了多少。附可见成品预览时明确静态图不代表游戏动态。
- 最终用户集中检查：冷启动建角/选角/首登、男女NO/T7/T14、各武器类别持握与收起、披风、X坐/对话、职业技能与任务、变形恢复、死亡复活与遗骨。根据实际开放范围裁剪，未测保持未测。

具体失败与最终来源：[本窗口失败台账](references/session-20261125-28.md)。新族开工复制[交付前检查表](references/preflight.md)，填完再出包。教学见同名beascendtutor目录。这个Skill是总流程，专项参数仍由现有Skill维护。


## 2026-11-28 Stormforged基本验收
用户确认联盟84本次移植完成；目录优先级、真实发型材质、服务端root/locale缺表、头盔及衣物披风指纹教训见[本次证据与验收边界](references/stormforged-20261128.md)。后续保留已安装BODY1A衣物层，未测试矩阵不扩大验收。
