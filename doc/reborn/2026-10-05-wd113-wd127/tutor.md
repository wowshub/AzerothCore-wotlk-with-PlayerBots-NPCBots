# 从零读懂本窗口修复

先学“一个技能由谁负责”，再读代码。节点像课程报名，角色学会Spell像毕业证，Aura像正在佩戴的加成，DBC像基础说明书，C++是实际结算，Lua是窗口，SQL是永久存档。一个文件修好不等于这六层都同步。

## 基础语法与参数

| 写法 | 大白话意义 | 本窗口常见坑 |
|---|---|---|
| uint32 / int32 | 不能负／能负的32位整数 | 冷却基础uint32与修正int32混用导致min/max不能推导；无符号先减可能下溢 |
| float / double / f后缀 | 小数及精度、单精度字面量 | 先取整2.2%会丢小数；系数增15%是乘1.15，不是加15个百分点 |
| *、->、nullptr | 对象地址、访问对象、空地址 | GetTarget/ToPlayer后先判空 |
| & | 引用，同一实际变量 | ModifyHealReceived修改heal会改真实治疗，不只是局部副本 |
| const、constexpr | 不修改／编译期固定 | ID地址和治疗数值不是一回事 |
| &&、||、! | 同时、任一、否定 | 先检查两种药水完整范围，再要求被动Aura |
| ?: | 条件真取前值，否则后值 | 投掷与泼洒不同子效果、不同系数 |
| Lua local、table、ipairs | 局部变量、表、按顺序迭代 | 四limb保存位掩码，不能把100位压成Lua浮点 |
| : 与 . | 冒号隐含self／点号普通调用 | font:SetText更新当前控件，M.receive是模块函数 |
| assert | 条件不满足立刻停 | 断言表达式若字段理解错误，测试通过也是假放心 |

## DBC参数必须按本核心结构表读

以下为从0开始的列，不是人类数的“第1列”。每列4字节，WDBC头20字节。

| 列 | 名称 | 作用 |
|---|---|---|
| 28 | CastingTimeIndex | 引用施法时间表，数值不是毫秒本身 |
| 29／30 | RecoveryTime／CategoryRecoveryTime | 技能／类别基础冷却毫秒，15000=15秒 |
| 31 | InterruptFlags | 读条打断位；移动位1，14 OR 1=15；不能把DurationIndex错当31 |
| 40 | DurationIndex | 引用持续时间表，不是直接秒数 |
| 71—73 | Effect | 三个效果槽类型，例如6为应用光环 |
| 74—76 | EffectDieSides | die0不加1，die1才加1 |
| 80—82 | EffectBasePoints | 基础量，有符号32位编码；-5000是减5000毫秒 |
| 86—88 | EffectImplicitTargetA | 目标选择，不是骰子；旧WD124验证误读此列 |
| 95—97 | EffectApplyAuraName | 光环类型；必须查本核心定义，不能照搬CoA不同枚举 |
| 98—100 | EffectAmplitude | 周期毫秒，3000=每3秒；12秒／3秒通常四跳，仍看生命周期时点 |
| 110—112 | EffectMiscValue | 对应光环的操作类型／参数；107光环misc11为冷却修正 |
| 133 | SpellIconID | 指向SpellIcon中的资源路径，不能直接拿节点图片名当数值 |

时间要分三件：技能冷却10秒，HoT可持续12／18秒，GCD通常1.5秒。三者不同不代表不同步；标题／动作条／服务端可再次施放时间都应描述同一个CD才要求一致。

## 学习顺序

1. 按上表区分ID、效果与单位；用原阶段教程理解每个技能的来源。
2. 读下方1—8：拥有权、公式、快照和生命周期。
3. 读9—13：消息顺序、权威数字、异步与安全UI。
4. 读14与测试说明：知道离线能证明什么、游戏还须测什么。
5. 最后读失败备份，先定位一条完整数据链，再选3—4项依赖完整的新技能，不靠不断试包找原因。

每节引用的是实际交付／提交源码；逐行表讲运行目的。原阶段完整教学与原测试脚本另外保存在逐阶段教学、原阶段研发记录。它们的历史候选结论和旧字段误判不是最终事实。


## 1. 灵魂行者：等级、持续、效果要共用一套实际公式

输入是实际Unit；Bonus只认已学且已有Aura的正式等级，先检查二级再一级。Duration给持续毫秒，SwiftAmount给整数光环效果。冷却不在这两个函数中。对应WD117与WD119B提示修正。

实际来源：[RebornWitchDoctorSpiritWalker.h](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots/modules/mod-reborn-witchdoctor/src/RebornWitchDoctorSpiritWalker.h:1)。归档完整副本：[成功代码快照/RebornWitchDoctorSpiritWalker.h](成功代码快照/RebornWitchDoctorSpiritWalker.h)。

```cpp
#ifndef REBORN_WD117_SPIRIT_WALKER_H
#define REBORN_WD117_SPIRIT_WALKER_H
#include "Player.h"
namespace WD117
{
inline uint32 Bonus(Unit const* unit)
{
    Player const* p=unit?unit->ToPlayer():nullptr;
    if(!p) return 0;
    if(p->HasSpell(9003858) && p->HasAura(9003858)) return 20;
    return p->HasSpell(9003857) && p->HasAura(9003857)?10:0;
}
inline uint32 Duration(Unit const* unit) { return 10000*(100+Bonus(unit))/100; }
inline int32 SwiftAmount(Unit const* unit) { return int32(25*(100+Bonus(unit))/100); }
}
#endif
```

逐行读法（编号对应上述代码块；空行和块边界也说明）：

1. 头文件保护：避免同一个头在一次编译中被重复定义。
2. 头文件保护：避免同一个头在一次编译中被重复定义。
3. 引入本函数使用的类型／工具声明；缺头文件会使Player、SpellInfo或容器方法无法编译。
4. 把本批私有名字放进命名空间，避免别批相同常量名冲突。
5. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
6. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
7. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
8. 以明确类型保存本节输入或中间量；*为对象指针，const禁止通过此变量改值，数字类型决定取整和是否可为负。
9. 条件守卫：条件不满足时阻止本节无资格／不匹配的对象进入后续分支。&&需同时成立，||允许任一成立。
10. 检查角色真实学习状态；草稿选中了节点不是这个检查的替代。
11. 检查角色真实学习状态；草稿选中了节点不是这个检查的替代。
12. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
13. 10000毫秒乘(100＋10或20)/100，得到10/11/12秒；冷却不在这里改变。
14. 基础25乘增幅后用整数返回，一级27而非27.5，二级30，提示必须跟实际取整一致。
15. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
16. 头文件保护：避免同一个头在一次编译中被重复定义。

## 2. 强效混合：两个入口是最高等级，不是两份收益

以下AEApply片段负责真实拥有权。移除旧独立9003854，通用与酿造仅最高级9003620/21留下。1级4%／15%，2级8%／30%；保留双入口只为旧方案兼容。

实际来源：[RebornWitchDoctorAllocation.inc](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots/modules/mod-reborn-witchdoctor/src/RebornWitchDoctorAllocation.inc:289)。归档完整副本：[成功代码快照/RebornWitchDoctorAllocation.inc](成功代码快照/RebornWitchDoctorAllocation.inc)。

```cpp
    // WD115A: retire the duplicate Class spell before granting the shared highest rank.
    p->RemoveAurasDueToSpell(9003854,p->GetGUID());
    if(p->HasSpell(9003854)) p->removeSpell(9003854,3,false);
    // Saved Brewing ranks and the Class rank share one Potent Mixes family.
    // Remove highest first, without lower-rank relearning, before granting desired rank.
    for(uint32 family=0;family<3;++family)
    {
        uint32 rank=AERank(mask,49+family);
        // WD115A: both progression nodes reference the same upstream rank family.
        if(family==0) rank=std::max(rank,AERank(mask,67));
        for(int tier=2;tier>=1;--tier)
        {
            uint32 spell=9003620+2*family+uint32(tier-1);
            if(rank!=uint32(tier))
            {
                if(p->HasSpell(spell)) p->removeSpell(spell,3,false);
                p->RemoveAurasDueToSpell(spell,p->GetGUID());
            }
        }
        if(rank)
        {
            uint32 spell=9003620+2*family+rank-1;
            if(!p->HasSpell(spell)) p->learnSpell(spell);
            if(family==0 && !p->HasAura(spell)) p->CastSpell(p,spell,true);
        }
    }
    // WD105A: three single-rank Brewing passives; only saved active ownership applies.
    uint32 const sustain[3]={9003630,9003631,9003480};
    for(uint32 i=0;i<3;++i)
    {
        if(!AERank(mask,52+i))
        {
            if(p->HasSpell(sustain[i])) p->removeSpell(sustain[i],3,false);
            p->RemoveAurasDueToSpell(sustain[i],p->GetGUID());
        }
        else if(!p->HasSpell(sustain[i])) p->learnSpell(sustain[i]);
    }
```

逐行读法（编号对应上述代码块；空行和块边界也说明）：

1. 注释：记录WD115A: retire the duplicate Class spell before granting the shared highest rank.；注释本身不执行。
2. 撤销旧重复的通用强效混合技能／Aura，避免它与正规9003620/21重复生效。
3. 撤销旧重复的通用强效混合技能／Aura，避免它与正规9003620/21重复生效。
4. 注释：记录Saved Brewing ranks and the Class rank share one Potent Mixes family.；注释本身不执行。
5. 注释：记录Remove highest first, without lower-rank relearning, before granting desired rank.；注释本身不执行。
6. 只遍历本节列出的对象／索引，每次更新循环变量；范围不能误含其他职业ID。
7. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
8. 以明确类型保存本节输入或中间量；*为对象指针，const禁止通过此变量改值，数字类型决定取整和是否可为负。
9. 注释：记录WD115A: both progression nodes reference the same upstream rank family.；注释本身不执行。
10. 两个同源入口取最高等级；不相加。通用1＋酿造2最终仍为2级。
11. 从2级往1级检查；先撤高等级，不触发意外低等级保留。
12. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
13. 三个家族各占两个私有ID；基址加家族偏移和等级偏移找到实际技能。
14. 当前层级不是方案想要的层级就撤销；类型显式一致方便编译。
15. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
16. 撤销该方案不再拥有的技能；本工程参数3覆盖原生两投影组，false不限定只撤临时学习。
17. 移除这个技能且由指定GUID施加的Aura；不清空全部玩家增益。
18. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
19. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
20. 条件守卫：条件不满足时阻止本节无资格／不匹配的对象进入后续分支。&&需同时成立，||允许任一成立。
21. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
22. 三个家族各占两个私有ID；基址加家族偏移和等级偏移找到实际技能。
23. 学会方案正式拥有的技能；HasSpell保护让重复Apply不重复授予。
24. 只对强效混合家族使用通用入口和永久被动恢复，不把规则扩展到其他家族。
25. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
26. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
27. 注释：记录WD105A: three single-rank Brewing passives; only saved active ownership applies.；注释本身不执行。
28. 以明确类型保存本节输入或中间量；*为对象指针，const禁止通过此变量改值，数字类型决定取整和是否可为负。
29. 只遍历本节列出的对象／索引，每次更新循环变量；范围不能误含其他职业ID。
30. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
31. 条件守卫：条件不满足时阻止本节无资格／不匹配的对象进入后续分支。&&需同时成立，||允许任一成立。
32. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
33. 撤销该方案不再拥有的技能；本工程参数3覆盖原生两投影组，false不限定只撤临时学习。
34. 移除这个技能且由指定GUID施加的Aura；不清空全部玩家增益。
35. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
36. 学会方案正式拥有的技能；HasSpell保护让重复Apply不重复授予。
37. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。

## 3. 药师等四被动：数组、等级与Aura恢复

support列出四个私有技能，supportWanted按正式mask决定要哪几个。先移除错误等级，后学会并恢复缺失Aura。这解释wanted重名修正与一级／二级不重复的机制；DBC数值疑点仍另列，不因拥有权正确就证明百分比正确。

实际来源：[RebornWitchDoctorAllocation.inc](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots/modules/mod-reborn-witchdoctor/src/RebornWitchDoctorAllocation.inc:165)。归档完整副本：[成功代码快照/RebornWitchDoctorAllocation.inc](成功代码快照/RebornWitchDoctorAllocation.inc)。

```cpp
    // WD124: saved-build-only native passives. Rank 2 supersedes rank 1.
    uint32 const support[4]={9003897,9003898,9003899,9003900};
    bool const supportWanted[4]={AERank(mask,82)>0,AERank(mask,83)==1,AERank(mask,83)==2,AERank(mask,84)>0};
    for(uint32 id:support) if(!sSpellMgr->GetSpellInfo(id)) return;
    for(uint32 i=0;i<4;++i) if(!supportWanted[i])
    {
        p->RemoveAurasDueToSpell(support[i],p->GetGUID());
        if(p->HasSpell(support[i])) p->removeSpell(support[i],3,false);
    }
    for(uint32 i=0;i<4;++i) if(supportWanted[i])
    {
        if(!p->HasSpell(support[i])) p->learnSpell(support[i]);
        if(!p->HasAura(support[i])) p->CastSpell(p,support[i],true);
    }
```

逐行读法（编号对应上述代码块；空行和块边界也说明）：

1. 注释：记录WD124: saved-build-only native passives. Rank 2 supersedes rank 1.；注释本身不执行。
2. 以明确类型保存本节输入或中间量；*为对象指针，const禁止通过此变量改值，数字类型决定取整和是否可为负。
3. 四个bool逐一对应support中的投手、药师1、药师2、再生者。二级药师不能与一级同时授予；新名字避开旧wanted数组。
4. 只遍历本节列出的对象／索引，每次更新循环变量；范围不能误含其他职业ID。
5. 四个bool逐一对应support中的投手、药师1、药师2、再生者。二级药师不能与一级同时授予；新名字避开旧wanted数组。
6. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
7. 移除这个技能且由指定GUID施加的Aura；不清空全部玩家增益。
8. 撤销该方案不再拥有的技能；本工程参数3覆盖原生两投影组，false不限定只撤临时学习。
9. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
10. 四个bool逐一对应support中的投手、药师1、药师2、再生者。二级药师不能与一级同时授予；新名字避开旧wanted数组。
11. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
12. 学会方案正式拥有的技能；HasSpell保护让重复Apply不重复授予。
13. 检查对应光环当前是否存在；被动已学但Aura丢失时才触发恢复。
14. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。

## 4. 酿造公式：基础、治疗系数、精神与等级倍率

这些函数是运行时与提示共享的数值入口。IsToss/IsSplash覆盖完整七等级；PulseTargets把绽放人数切为5；SplashBonus用22.4494%自然治疗和8%精神，Toss用28%和10%，Pulse用20%和等级二次曲线。

实际来源：[RebornWitchDoctorBrewingNumbers.h](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots/modules/mod-reborn-witchdoctor/src/RebornWitchDoctorBrewingNumbers.h:1)。归档完整副本：[成功代码快照/RebornWitchDoctorBrewingNumbers.h](成功代码快照/RebornWitchDoctorBrewingNumbers.h)。

```cpp
#pragma once
#include <algorithm>
#include "Player.h"
#include "SpellInfo.h"
namespace WD120A
{
constexpr uint32 Brewer=9003864, Shrooms=9003865, Pulse=9003866, Hot=9003867;
// WD122: shared runtime / tooltip cap; private aura avoids donor family-mask leakage.
inline uint32 PulseTargets(Unit* caster) { return caster->HasAura(9003880)?5u:8u; }
inline bool IsToss(uint32 id) { return id>=9003870 && id<=9003876; }
constexpr uint32 SplashHot=9003889;
inline bool IsSplash(uint32 id) { return id>=9003890 && id<=9003896; }
inline float SplashBonus(Player* p)
{
    return float(std::max(0,p->SpellBaseHealingBonusDone(SPELL_SCHOOL_MASK_NATURE)))*0.224494f
        +std::max(0.0f,p->GetStat(STAT_SPIRIT))*0.08f;
}
inline double Scaling(uint32 level)
{
    return 0.0267291844060354+0.0048541098014737*level+0.0001859597762293*level*level;
}
inline float Bonus(Player* p,bool pulse)
{
    return float(std::max(0,p->SpellBaseHealingBonusDone(SPELL_SCHOOL_MASK_NATURE)))*(pulse?0.20f:0.28f)
        +(pulse?0.0f:std::max(0.0f,p->GetStat(STAT_SPIRIT))*0.10f);
}
}

// WD125: private ingredient spell IDs; never use the donor IDs in live spellbook.
namespace WD125A
{
constexpr uint32 FishPrep=9003901,FishField=9003902,FishPotion=9003903,FishSplash=9003904;
constexpr uint32 BonesPrep=9003905,BonesField=9003906,BonesPotion=9003907,BonesSplash=9003908;
inline bool IsPrep(uint32 id) { return id==FishPrep || id==BonesPrep || id==WD120A::Shrooms; }
}
```

逐行读法（编号对应上述代码块；空行和块边界也说明）：

1. 头文件保护：避免同一个头在一次编译中被重复定义。
2. 引入本函数使用的类型／工具声明；缺头文件会使Player、SpellInfo或容器方法无法编译。
3. 引入本函数使用的类型／工具声明；缺头文件会使Player、SpellInfo或容器方法无法编译。
4. 引入本函数使用的类型／工具声明；缺头文件会使Player、SpellInfo或容器方法无法编译。
5. 把本批私有名字放进命名空间，避免别批相同常量名冲突。
6. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
7. 编译期固定私有SpellID，准备技能与隐藏附效不同号；ID只是地址，不是治疗数值。
8. 注释：记录WD122: shared runtime / tooltip cap; private aura avoids donor family-mask leakage.；注释本身不执行。
9. 检查对应光环当前是否存在；被动已学但Aura丢失时才触发恢复。
10. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
11. 编译期固定私有SpellID，准备技能与隐藏附效不同号；ID只是地址，不是治疗数值。
12. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
13. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
14. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
15. 读取自然系治疗加成，非负夹取后乘该技能自己的系数。
16. 读取精神属性并乘指定比例；不是把精神百分比误当治疗乘区。
17. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
18. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
19. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
20. 上游固定二次等级公式：常数项＋一次项×level＋二次项×level²；不能拿描述变量ID猜倍率。
21. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
22. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
23. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
24. 读取自然系治疗加成，非负夹取后乘该技能自己的系数。
25. 读取精神属性并乘指定比例；不是把精神百分比误当治疗乘区。
26. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
27. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
28. 空行：把不同职责分开，运行时不做任何事。
29. 注释：记录WD125: private ingredient spell IDs; never use the donor IDs in live spellbook.；注释本身不执行。
30. 把本批私有名字放进命名空间，避免别批相同常量名冲突。
31. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
32. 编译期固定私有SpellID，准备技能与隐藏附效不同号；ID只是地址，不是治疗数值。
33. 编译期固定私有SpellID，准备技能与隐藏附效不同号；ID只是地址，不是治疗数值。
34. 判断本次施放是否为三个准备技能之一；目前只允许一种配料，尚未实现Mixologist。
35. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。

## 5. 大锅／蘑菇／两种药水／鱼油蛙骨：同一次施放闭包

Validate核对依赖；Check核对资格和已准备；PulseTargets裁名单；Snapshot发射时快照并保持单配料；HealBase在原生倍率之前加系数；IngredientEffect命中后附子效果；Register把上述函数挂到对应时点。这一整份78行对应WD120/122/123/125，不能把子效果另列成天赋。

实际来源：[RebornWitchDoctorBrewingFoundation.inc](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots/modules/mod-reborn-witchdoctor/src/RebornWitchDoctorBrewingFoundation.inc:1)。归档完整副本：[成功代码快照/RebornWitchDoctorBrewingFoundation.inc](成功代码快照/RebornWitchDoctorBrewingFoundation.inc)。

```cpp
// WD120: CoA d7620151, isolated Brewing ingredient / Potion Toss closure.
#include "RebornWitchDoctorBrewingNumbers.h"
#include "Containers.h"
class spell_reborn_wd120_brewing : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd120_brewing);
    bool _shrooms=false,_fish=false,_bones=false;
    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({WD120A::Brewer,WD120A::Shrooms,WD120A::Pulse,WD120A::Hot,WD120A::SplashHot,WD125A::FishPrep,WD125A::FishField,WD125A::FishPotion,WD125A::FishSplash,WD125A::BonesPrep,WD125A::BonesField,WD125A::BonesPotion,WD125A::BonesSplash});
    }
    SpellCastResult Check()
    {
        if(GetSpellInfo()->Id==WD120A::Pulse) return SPELL_CAST_OK;
        Player* p=GetCaster()->ToPlayer();
        if(!IsDoctor(p) || !p->HasSpell(GetSpellInfo()->Id)) return SPELL_FAILED_CASTER_AURASTATE;
        if((WD120A::IsToss(GetSpellInfo()->Id) || WD120A::IsSplash(GetSpellInfo()->Id)) && !p->HasAura(WD120A::Shrooms) && !p->HasAura(WD125A::FishPrep) && !p->HasAura(WD125A::BonesPrep)) return SPELL_FAILED_CASTER_AURASTATE;
        return SPELL_CAST_OK;
    }
    void PulseTargets(std::list<WorldObject*>& targets)
    {
        if(GetSpellInfo()->Id==WD120A::Pulse)
            Acore::Containers::RandomResize(targets,WD120A::PulseTargets(GetCaster()));
    }
    void Snapshot()
    {
        // Per-cast state: a different preparation while the missile travels cannot change it.
        _shrooms=GetCaster()->HasAura(WD120A::Shrooms);
        _fish=GetCaster()->HasAura(WD125A::FishPrep);
        _bones=GetCaster()->HasAura(WD125A::BonesPrep);
        // Exactly one prepared ingredient until the Mixologist capacity node is implemented.
        uint32 id=GetSpellInfo()->Id;
        if(WD125A::IsPrep(id))
            for(uint32 other:{WD120A::Shrooms,WD125A::FishPrep,WD125A::BonesPrep})
                if(other!=id) GetCaster()->RemoveAurasDueToSpell(other,GetCaster()->GetGUID());
    }
    void HealBase(SpellEffIndex)
    {
        if(GetSpellInfo()->Id!=WD120A::Pulse && !WD120A::IsToss(GetSpellInfo()->Id) && !WD120A::IsSplash(GetSpellInfo()->Id)) return;
        Player* p=GetCaster()->ToPlayer();
        if(!IsDoctor(p)) return;
        bool pulse=GetSpellInfo()->Id==WD120A::Pulse;
        // The upstream scaling hook runs after level growth/dice, before done/taken modifiers.
        float base=float(GetEffectValue());
        if(pulse) base=float(int32(double(base)*WD120A::Scaling(p->GetLevel())));
        SetEffectValue(int32(base+(WD120A::IsSplash(GetSpellInfo()->Id)?WD120A::SplashBonus(p):WD120A::Bonus(p,pulse))));
    }
    void IngredientEffect()
    {
        Player* p=GetCaster()->ToPlayer();Unit* target=GetHitUnit();
        if(!IsDoctor(p) || (!WD120A::IsToss(GetSpellInfo()->Id) && !WD120A::IsSplash(GetSpellInfo()->Id)) || !target ||
           !target->IsAlive() || !p->IsFriendlyTo(target)) return;
        // Correct official 803698 healing route, not upstream 803273 Fish Oil.
        bool splash=WD120A::IsSplash(GetSpellInfo()->Id);
        if(_shrooms)
            p->CastSpell(target,splash?WD120A::SplashHot:WD120A::Hot,true);
        else if(_fish)
            p->CastSpell(target,splash?WD125A::FishSplash:WD125A::FishPotion,true);
        else if(_bones)
        {
            // Donor formula: base + 35% Spirit + 80% bonus healing.
            float amount=(splash?25.0f:100.0f)+std::max(0.0f,p->GetStat(STAT_SPIRIT))*0.35f
                +float(std::max(0,p->SpellBaseHealingBonusDone(SPELL_SCHOOL_MASK_NATURE)))*0.80f;
            int32 shield=std::max(1,int32(amount));
            p->CastCustomSpell(target,splash?WD125A::BonesSplash:WD125A::BonesPotion,&shield,nullptr,nullptr,true);
        }
    }
    void Register() override
    {
        // Pulse is a hidden triggered heal, not an independently learned player ability.
        if(m_scriptSpellId==WD120A::Pulse)
            OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_reborn_wd120_brewing::PulseTargets,EFFECT_0,TARGET_UNIT_CASTER_AREA_RAID);
        OnCheckCast += SpellCheckCastFn(spell_reborn_wd120_brewing::Check);
        OnCast += SpellCastFn(spell_reborn_wd120_brewing::Snapshot);
        OnEffectLaunchTarget += SpellEffectFn(spell_reborn_wd120_brewing::HealBase,EFFECT_0,SPELL_EFFECT_ANY);
        AfterHit += SpellHitFn(spell_reborn_wd120_brewing::IngredientEffect);
    }
};
```

逐行读法（编号对应上述代码块；空行和块边界也说明）：

1. 注释：记录WD120: CoA d7620151, isolated Brewing ingredient / Potion Toss closure.；注释本身不执行。
2. 引入本函数使用的类型／工具声明；缺头文件会使Player、SpellInfo或容器方法无法编译。
3. 引入本函数使用的类型／工具声明；缺头文件会使Player、SpellInfo或容器方法无法编译。
4. 定义本批脚本类型；基类决定是单次法术、持续Aura还是全局单位事件。
5. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
6. 核心宏给这个脚本声明注册需要的类型信息，不是给角色学习技能。
7. 记录本次发射时有无蘑菇；后续命中时读这个快照。
8. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
9. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
10. 启动时检查全部依赖私有法术是否存在；缺子法术不能假装主技能可用。
11. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
12. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
13. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
14. 条件守卫：条件不满足时阻止本节无资格／不匹配的对象进入后续分支。&&需同时成立，||允许任一成立。
15. 以明确类型保存本节输入或中间量；*为对象指针，const禁止通过此变量改值，数字类型决定取整和是否可为负。
16. 检查角色真实学习状态；草稿选中了节点不是这个检查的替代。
17. 检查对应光环当前是否存在；被动已学但Aura丢失时才触发恢复。
18. 返回当前函数计算出的值或错误码，当前函数在这里结束；外层流程根据返回结果继续或拒绝。
19. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
20. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
21. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
22. 条件守卫：条件不满足时阻止本节无资格／不匹配的对象进入后续分支。&&需同时成立，||允许任一成立。
23. 范围名单按目标上限随机截取；这段没有实现“最低血优先”，不能那样描述。
24. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
25. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
26. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
27. 注释：记录Per-cast state: a different preparation while the missile travels cannot change it.；注释本身不执行。
28. 检查对应光环当前是否存在；被动已学但Aura丢失时才触发恢复。
29. 检查对应光环当前是否存在；被动已学但Aura丢失时才触发恢复。
30. 检查对应光环当前是否存在；被动已学但Aura丢失时才触发恢复。
31. 注释：记录Exactly one prepared ingredient until the Mixologist capacity node is implemented.；注释本身不执行。
32. 以明确类型保存本节输入或中间量；*为对象指针，const禁止通过此变量改值，数字类型决定取整和是否可为负。
33. 判断本次施放是否为三个准备技能之一；目前只允许一种配料，尚未实现Mixologist。
34. 只遍历本节列出的对象／索引，每次更新循环变量；范围不能误含其他职业ID。
35. 移除这个技能且由指定GUID施加的Aura；不清空全部玩家增益。
36. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
37. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
38. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
39. 条件守卫：条件不满足时阻止本节无资格／不匹配的对象进入后续分支。&&需同时成立，||允许任一成立。
40. 以明确类型保存本节输入或中间量；*为对象指针，const禁止通过此变量改值，数字类型决定取整和是否可为负。
41. 限制实际巫医／资格；条件失败立即返回，不能让其他职业借脚本获得功能。
42. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
43. 注释：记录The upstream scaling hook runs after level growth/dice, before done/taken modifiers.；注释本身不执行。
44. 读取本次效果在核心已经处理等级／骰子后的基础量，不直接把DBC静态数字当最终治疗。
45. 范围蘑菇基础值按角色等级公式缩放，先处理基础，再走原生治疗加成。
46. 在effect launch阶段设置增补后的基础量，让后续原生治疗倍率、受疗和暴击正常处理。
47. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
48. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
49. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
50. 以明确类型保存本节输入或中间量；*为对象指针，const禁止通过此变量改值，数字类型决定取整和是否可为负。
51. 限制实际巫医／资格；条件失败立即返回，不能让其他职业借脚本获得功能。
52. 本节辅助赋值／调用，按右侧结果更新左侧状态。请结合紧邻代码和本节输入输出阅读；这是实际源码原句，不是建议另写的新实现。
53. 注释：记录Correct official 803698 healing route, not upstream 803273 Fish Oil.；注释本身不执行。
54. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
55. 条件守卫：条件不满足时阻止本节无资格／不匹配的对象进入后续分支。&&需同时成立，||允许任一成立。
56. 触发指定子技能／被动；最后true表示触发施放，避免把隐藏效果当一次新的玩家读条。
57. 进入前一个条件没有命中的备选分支，保留互斥顺序而不是同时执行两种附效。
58. 触发指定子技能／被动；最后true表示触发施放，避免把隐藏效果当一次新的玩家读条。
59. 进入前一个条件没有命中的备选分支，保留互斥顺序而不是同时执行两种附效。
60. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
61. 注释：记录Donor formula: base + 35% Spirit + 80% bonus healing.；注释本身不执行。
62. 读取精神属性并乘指定比例；不是把精神百分比误当治疗乘区。
63. 读取自然系治疗加成，非负夹取后乘该技能自己的系数。
64. 最终护盾量取整数且最低1；护盾和治疗不是同一种消费路径。
65. 把计算好的护盾amount传给目标触发子法术；不再把它当普通治疗量结算。
66. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
67. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
68. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
69. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
70. 注释：记录Pulse is a hidden triggered heal, not an independently learned player ability.；注释本身不执行。
71. 条件守卫：条件不满足时阻止本节无资格／不匹配的对象进入后续分支。&&需同时成立，||允许任一成立。
72. 在核心生成范围名单时接入截取函数；必须用本核心存在的CASTER_AREA_RAID枚举。
73. 把Check挂到施法资格检查时点，不等命中后才发现没配料。
74. 把Snapshot挂到实际施放时点，定义这瓶药水的配料快照。
75. 在对目标启动效果时调整治疗基础量，保证倍率处理顺序。
76. 命中完成后附加配料子效果，不把隐藏子法术再次当普通玩家药水递归。
77. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
78. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。

## 6. 化蛇：父Aura创建／清理隐藏辅助Aura

Apply在父光环应用时清旧移动控制、停攻击、添加9003860；Remove只撤同施法者辅助Aura。速度、变形、禁止攻击施法由原生效果负责。不能从此推导持续控制免疫或全伤害免疫。

实际来源：[RebornWitchDoctor.cpp](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots/modules/mod-reborn-witchdoctor/src/RebornWitchDoctor.cpp:3226)。归档完整副本：[成功代码快照/RebornWitchDoctor.cpp](成功代码快照/RebornWitchDoctor.cpp)。

```cpp
class aura_reborn_wd118_slither : public AuraScript
{
    PrepareAuraScript(aura_reborn_wd118_slither);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9003860}); }
    void Apply(AuraEffect const*,AuraEffectHandleModes)
    {
        Unit* unit=GetTarget();
        unit->RemoveMovementImpairingAuras(true);
        unit->AttackStop();
        unit->CastSpell(unit,9003860,true);
    }
    void Remove(AuraEffect const*,AuraEffectHandleModes)
    {
        GetTarget()->RemoveAurasDueToSpell(9003860,GetCasterGUID());
    }
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_reborn_wd118_slither::Apply,EFFECT_0,SPELL_AURA_MOD_INCREASE_SPEED,AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(aura_reborn_wd118_slither::Remove,EFFECT_0,SPELL_AURA_MOD_INCREASE_SPEED,AURA_EFFECT_HANDLE_REAL);
    }
};
```

逐行读法（编号对应上述代码块；空行和块边界也说明）：

1. 定义本批脚本类型；基类决定是单次法术、持续Aura还是全局单位事件。
2. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
3. 核心宏声明Aura脚本注册信息；真正生效要有对应World绑定和光环生命周期事件。
4. 启动时检查全部依赖私有法术是否存在；缺子法术不能假装主技能可用。
5. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
6. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
7. 以明确类型保存本节输入或中间量；*为对象指针，const禁止通过此变量改值，数字类型决定取整和是否可为负。
8. 清除施放前已有的定身／减速；不表示持续免疫新控制。
9. 停止当前攻击；配合原生禁止攻击／施法Aura，不是把玩家杀死。
10. 触发指定子技能／被动；最后true表示触发施放，避免把隐藏效果当一次新的玩家读条。
11. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
12. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
13. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
14. 移除这个技能且由指定GUID施加的Aura；不清空全部玩家增益。
15. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
16. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
17. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
18. 父Aura真实应用后调用Apply，不能只注册函数而不挂事件。
19. 父Aura移除时清配套子Aura，到期／取消／死亡时不残留辅助效果。
20. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
21. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
22. 空行：把不同职责分开，运行时不做任何事。

## 7. 沃金每秒回血：在实际生命量上增强

ModifyHealReceived输入施法者a、目标b、引用heal与SpellInfo；只放行9003856、自施自受。引用意味着直接改核心将结算的量；64位中间乘法避免溢出。

实际来源：[RebornWitchDoctor.cpp](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots/modules/mod-reborn-witchdoctor/src/RebornWitchDoctor.cpp:3248)。归档完整副本：[成功代码快照/RebornWitchDoctor.cpp](成功代码快照/RebornWitchDoctor.cpp)。

```cpp
class reborn_wd117_heal : public UnitScript
{
public:
    reborn_wd117_heal():UnitScript("reborn_wd117_heal") { }
    void ModifyHealReceived(Unit* a,Unit* b,uint32& heal,SpellInfo const* spell) override
    {
        if(!spell || spell->Id!=9003856 || !a || a!=b) return;
        heal=uint32(std::min<uint64>(std::numeric_limits<uint32>::max(),uint64(heal)*(100+WD117::Bonus(a))/100));
    }
};
```

逐行读法（编号对应上述代码块；空行和块边界也说明）：

1. 定义本批脚本类型；基类决定是单次法术、持续Aura还是全局单位事件。
2. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
3. 本节辅助赋值／调用，按右侧结果更新左侧状态。请结合紧邻代码和本节输入输出阅读；这是实际源码原句，不是建议另写的新实现。
4. 本节辅助赋值／调用，按右侧结果更新左侧状态。请结合紧邻代码和本节输入输出阅读；这是实际源码原句，不是建议另写的新实现。
5. 只在实际治疗量进入结算时调整恢复；不要先把DBC“2%”取整成整数后丢掉2.2%。
6. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
7. 仅处理自施自受的沃金隐藏治疗，别把任意外部治疗也增强。
8. 用64位中间结果计算百分比，再钳到uint32上限；防乘法溢出。
9. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
10. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。

## 8. 缩小盟友：原生光环与脚本资格分工

Check只做巫医、已学、存活友方校验。8秒、闪避、缩放、CD在DBC原生处理，脚本不再重复加一层属性。

实际来源：[RebornWitchDoctor.cpp](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots/modules/mod-reborn-witchdoctor/src/RebornWitchDoctor.cpp:3270)。归档完整副本：[成功代码快照/RebornWitchDoctor.cpp](成功代码快照/RebornWitchDoctor.cpp)。

```cpp
class spell_reborn_wd126_shrink_ally : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd126_shrink_ally);
    SpellCastResult Check()
    {
        Player* p=GetCaster()->ToPlayer();
        Unit* target=GetExplTargetUnit();
        return IsDoctor(p) && p->HasSpell(9003910) && target && target->IsAlive() &&
            p->IsValidAssistTarget(target) ? SPELL_CAST_OK : SPELL_FAILED_BAD_TARGETS;
    }
    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_reborn_wd126_shrink_ally::Check);
    }
};
```

逐行读法（编号对应上述代码块；空行和块边界也说明）：

1. 定义本批脚本类型；基类决定是单次法术、持续Aura还是全局单位事件。
2. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
3. 核心宏给这个脚本声明注册需要的类型信息，不是给角色学习技能。
4. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
5. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
6. 以明确类型保存本节输入或中间量；*为对象指针，const禁止通过此变量改值，数字类型决定取整和是否可为负。
7. 取得玩家明确选择的友方目标；没有目标、死亡或敌对都会被后续拒绝。
8. 检查角色真实学习状态；草稿选中了节点不是这个检查的替代。
9. 由核心判断目标能否接受友方施法，不只看名字颜色。
10. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
11. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
12. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
13. 把Check挂到施法资格检查时点，不等命中后才发现没配料。
14. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
15. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
16. 空行：把不同职责分开，运行时不做任何事。

## 9. 冷却根因：必须在SPELL_GO之后校正

这段是最终F真正解决动作条15秒的代码。按存储→GO→清客户端预测→发真实剩余顺序；只认私有药水被动／已知Hastened和贡克，条件排除物品和特殊触发。不要在Lua全局伪造GetActionCooldown。

实际来源：[Spell.cpp](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots/src/server/game/Spells/Spell.cpp:4069)。归档完整副本：[成功代码快照/Spell.cpp](成功代码快照/Spell.cpp)。

```cpp
    SendSpellGo();

    // WD63E: correct server-only Hastened prediction AFTER SMSG_SPELL_GO.
    // SPELL_GO can start the client's unmodified DBC cooldown. Replace only
    // that client's timer; never recalculate or erase the server cooldown.
    if (Player* player = m_caster->ToPlayer())
    {
        if (player->getClass() == 13 && !m_CastItem &&
            !m_spellInfo->IsPassive() && !m_spellInfo->IsCooldownStartedOnEvent() &&
            !HasTriggeredCastFlag(TRIGGERED_IGNORE_SPELL_AND_CATEGORY_CD) &&
            !HasTriggeredCastFlag(TRIGGERED_IGNORE_EFFECTS))
        {
            // WD121B: Gonk has the same server-only prediction issue as Hastened.
            // AddSpellAndCategoryCooldowns runs BEFORE SPELL_GO; its earlier packet
            // can be replaced by the client's base DBC timer when SPELL_GO arrives.
            // WD127F: both potion families need the same post-GO correction.
            // Use the cooldown already stored by Player; do not subtract twice.
            bool exactCooldown = ((m_spellInfo->Id >= 9003870 && m_spellInfo->Id <= 9003876) ||
                                  (m_spellInfo->Id >= 9003890 && m_spellInfo->Id <= 9003896)) &&
                                 player->HasAura(9003897);
            for (uint32 source : {9003653u, 9003862u})
            {
                if (source == 9003862 && m_spellInfo->Id != 9003861)
                    continue;
                AuraEffect* effect = player->GetAuraEffect(source, EFFECT_0);
                SpellModifier* modifier = effect ? effect->GetSpellModifier() : nullptr;
                if (modifier && modifier->op == SPELLMOD_COOLDOWN &&
                    player->IsAffectedBySpellmod(m_spellInfo, modifier, this))
                {
                    exactCooldown = true;
                    break;
                }
            }
            if (exactCooldown)
            {
                uint32 remaining = player->GetSpellCooldownDelay(m_spellInfo->Id);
                if (remaining)
                {
                    player->SendClearCooldown(m_spellInfo->Id, player);
                    WorldPacket cooldown;
                    player->BuildCooldownPacket(cooldown, SPELL_COOLDOWN_FLAG_NONE,
                        m_spellInfo->Id, remaining);
                    player->SendDirectMessage(&cooldown);
                }
            }
        }
    }
```

逐行读法（编号对应上述代码块；空行和块边界也说明）：

1. 先发施放完成消息；客户端可能在收到它后用基础DBC启动冷却。后续校正必须排在它后面。
2. 空行：把不同职责分开，运行时不做任何事。
3. 注释：记录WD63E: correct server-only Hastened prediction AFTER SMSG_SPELL_GO.；注释本身不执行。
4. 注释：记录SPELL_GO can start the client's unmodified DBC cooldown. Replace only；注释本身不执行。
5. 注释：记录that client's timer; never recalculate or erase the server cooldown.；注释本身不执行。
6. 条件守卫：条件不满足时阻止本节无资格／不匹配的对象进入后续分支。&&需同时成立，||允许任一成立。
7. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
8. 排除物品发起的法术，避免把本职业技能修正施加到物品冷却。
9. 排除冷却由结束事件启动的特殊法术；它们不能在普通施放完成点处理。
10. 排除显式忽略冷却／效果的触发施放，避免给隐藏子技能强加玩家冷却。
11. 排除显式忽略冷却／效果的触发施放，避免给隐藏子技能强加玩家冷却。
12. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
13. 注释：记录WD121B: Gonk has the same server-only prediction issue as Hastened.；注释本身不执行。
14. 注释：记录AddSpellAndCategoryCooldowns runs BEFORE SPELL_GO; its earlier packet；注释本身不执行。
15. 注释：记录can be replaced by the client's base DBC timer when SPELL_GO arrives.；注释本身不执行。
16. 注释：记录WD127F: both potion families need the same post-GO correction.；注释本身不执行。
17. 注释：记录Use the cooldown already stored by Player; do not subtract twice.；注释本身不执行。
18. 保存“是否需要在GO后校正客户端预测”的布尔值；药水两个完整等级区间和对应被动共同决定。
19. 本节辅助赋值／调用，按右侧结果更新左侧状态。请结合紧邻代码和本节输入输出阅读；这是实际源码原句，不是建议另写的新实现。
20. 检查对应光环当前是否存在；被动已学但Aura丢失时才触发恢复。
21. 只遍历本节列出的对象／索引，每次更新循环变量；范围不能误含其他职业ID。
22. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
23. 条件守卫：条件不满足时阻止本节无资格／不匹配的对象进入后续分支。&&需同时成立，||允许任一成立。
24. 跳过这一项但继续下一项，防把当前不适用的来源判成匹配。
25. 读取指定技能、效果槽和需要时指定施法者的光环效果，不凭是否学会代替是否正在生效。
26. 取出AuraEffect关联的原生SpellModifier；找不到时返回空指针，后续先判空。
27. 只匹配冷却操作，不能把读条时间或其他效果的modifier拿来修冷却。
28. 由服务端确认这个modifier是否作用于当前法术；不能把空家族mask当成所有法术通配。
29. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
30. 保存“是否需要在GO后校正客户端预测”的布尔值；药水两个完整等级区间和对应被动共同决定。
31. 已找到需要的匹配，结束当前循环，不再处理后续来源。
32. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
33. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
34. 保存“是否需要在GO后校正客户端预测”的布尔值；药水两个完整等级区间和对应被动共同决定。
35. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
36. 读取服务端已经保存的剩余毫秒，不能再减一次5000，也不重置服务器冷却。
37. 条件守卫：条件不满足时阻止本节无资格／不匹配的对象进入后续分支。&&需同时成立，||允许任一成立。
38. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
39. 只清拥有者客户端的预测计时；不删除服务器保存的冷却。
40. 本节辅助赋值／调用，按右侧结果更新左侧状态。请结合紧邻代码和本节输入输出阅读；这是实际源码原句，不是建议另写的新实现。
41. 构造一个指定SpellID／真实剩余毫秒的原生冷却消息。FLAG_NONE不表示免冷却。
42. 本节辅助赋值／调用，按右侧结果更新左侧状态。请结合紧邻代码和本节输入输出阅读；这是实际源码原句，不是建议另写的新实现。
43. 把刚构造的消息发给该玩家会话，动作条和原生剩余时间据此更新。
44. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
45. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
46. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
47. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
48. 空行：把不同职责分开，运行时不做任何事。

## 10. 消耗与数值协议：服务端权威值、不是草稿

这段接续命令白名单／已学习校验。estimate根据等级和随机上下界确定自身治疗参考，最后走SpellHealingBonusDone。发送cost,a,b,revision,active,c,d,e，Toss末尾原少一个{}，F补全。绿色治疗不含目标受疗、暴击和过量。

实际来源：[RebornWitchDoctorTalents.cpp](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots/modules/mod-reborn-witchdoctor/src/RebornWitchDoctorTalents.cpp:555)。归档完整副本：[成功代码快照/RebornWitchDoctorTalents.cpp](成功代码快照/RebornWitchDoctorTalents.cpp)。

```cpp
    int32 const cost=p->GetCommandStatus(CHEAT_POWER)?0:info->CalcPowerCost(p,info->GetSchoolMask());
    if(id==WD120A::Shrooms || WD120A::IsToss(id) || WD120A::IsSplash(id))
    {
        bool pulse=id==WD120A::Shrooms;
        SpellInfo const* heal=pulse?sSpellMgr->GetSpellInfo(WD120A::Pulse):info;
        if(!heal) { h->PSendSysMessage("WD114|{}|{}|unavailable",sequence,id);return true; }
        auto const& effect=heal->Effects[EFFECT_0];
        int32 level=int32(p->GetLevel());
        if(heal->MaxLevel && level>int32(heal->MaxLevel)) level=int32(heal->MaxLevel);
        level=std::max(level,int32(heal->BaseLevel))-int32(std::max(heal->BaseLevel,heal->SpellLevel));
        int32 base=effect.BasePoints+int32(level*effect.RealPointsPerLevel);
        auto estimate=[&](int32 dice)
        {
            float amount=p->ApplyEffectModifiers(heal,EFFECT_0,float(base+dice));
            if(pulse) amount=float(int32(double(amount)*WD120A::Scaling(p->GetLevel())));
            uint32 result=uint32(std::max(0,int32(amount+(WD120A::IsSplash(id)?WD120A::SplashBonus(p):WD120A::Bonus(p,pulse)))));
            return p->SpellHealingBonusDone(p,heal,result,HEAL,EFFECT_0);
        };
        uint32 lo=estimate(effect.DieSides==0?0:1),hi=estimate(effect.DieSides);
        int32 cooldown=info->RecoveryTime;
        p->ApplySpellMod(id,SPELLMOD_COOLDOWN,cooldown);
        if(p->HasAura(9003897) && (WD120A::IsToss(id) || WD120A::IsSplash(id)))
            cooldown=std::min<int32>(cooldown,std::max<int32>(0,int32(info->RecoveryTime)-5000));
        if(pulse)
        {
            int32 interval=info->Effects[EFFECT_0].Amplitude;
            p->ApplySpellMod(id,SPELLMOD_ACTIVATION_TIME,interval);
            if(AuraEffect* effect=p->GetAuraEffect(id,EFFECT_0,p->GetGUID())) interval=effect->GetAmplitude();
            h->PSendSysMessage("WD114|{}|{}|ok|{}|{}|{}|{}|{}|{}|{}",sequence,id,cost,lo,hi,s->revision,s->active,interval,WD120A::PulseTargets(p));
        }
        else if(WD120A::IsSplash(id))
        {
            SpellInfo const* hot=sSpellMgr->GetSpellInfo(WD120A::SplashHot);
            if(!hot) { h->PSendSysMessage("WD114|{}|{}|unavailable",sequence,id);return true; }
            uint32 tick=p->SpellHealingBonusDone(p,hot,uint32(std::max(0,hot->Effects[EFFECT_0].CalcValue(p))),DOT,EFFECT_0);
            h->PSendSysMessage("WD114|{}|{}|ok|{}|{}|{}|{}|{}|{}|{}|{}",sequence,id,cost,lo,hi,s->revision,s->active,tick,12000,std::max(0,cooldown));
        }
        else h->PSendSysMessage("WD114|{}|{}|ok|{}|{}|{}|{}|{}|{}|{}|{}",sequence,id,cost,lo,hi,s->revision,s->active,0,0,std::max(0,cooldown));
        return true;
    }
```

逐行读法（编号对应上述代码块；空行和块边界也说明）：

1. 用本核心实际费用计算入口生成数字，而不是用客户端旧数字乘一个自猜百分比。
2. 条件守卫：条件不满足时阻止本节无资格／不匹配的对象进入后续分支。&&需同时成立，||允许任一成立。
3. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
4. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
5. 本节辅助赋值／调用，按右侧结果更新左侧状态。请结合紧邻代码和本节输入输出阅读；这是实际源码原句，不是建议另写的新实现。
6. 按WD114协议发送服务端只读数值；{}个数必须与顶层实参一一对应，Toss遗漏字段就是在这里。
7. 本节辅助赋值／调用，按右侧结果更新左侧状态。请结合紧邻代码和本节输入输出阅读；这是实际源码原句，不是建议另写的新实现。
8. 以明确类型保存本节输入或中间量；*为对象指针，const禁止通过此变量改值，数字类型决定取整和是否可为负。
9. 条件守卫：条件不满足时阻止本节无资格／不匹配的对象进入后续分支。&&需同时成立，||允许任一成立。
10. 本节辅助赋值／调用，按右侧结果更新左侧状态。请结合紧邻代码和本节输入输出阅读；这是实际源码原句，不是建议另写的新实现。
11. 以明确类型保存本节输入或中间量；*为对象指针，const禁止通过此变量改值，数字类型决定取整和是否可为负。
12. 本节辅助赋值／调用，按右侧结果更新左侧状态。请结合紧邻代码和本节输入输出阅读；这是实际源码原句，不是建议另写的新实现。
13. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
14. 以明确类型保存本节输入或中间量；*为对象指针，const禁止通过此变量改值，数字类型决定取整和是否可为负。
15. 范围蘑菇基础值按角色等级公式缩放，先处理基础，再走原生治疗加成。
16. 以明确类型保存本节输入或中间量；*为对象指针，const禁止通过此变量改值，数字类型决定取整和是否可为负。
17. 返回当前函数计算出的值或错误码，当前函数在这里结束；外层流程根据返回结果继续或拒绝。
18. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
19. 以明确类型保存本节输入或中间量；*为对象指针，const禁止通过此变量改值，数字类型决定取整和是否可为负。
20. 以明确类型保存本节输入或中间量；*为对象指针，const禁止通过此变量改值，数字类型决定取整和是否可为负。
21. 只匹配冷却操作，不能把读条时间或其他效果的modifier拿来修冷却。
22. 检查对应光环当前是否存在；被动已学但Aura丢失时才触发恢复。
23. 明确比较值都是有符号32位整数；取较小值以保留已经存在的更强修正，不能再次减5秒。
24. 条件守卫：条件不满足时阻止本节无资格／不匹配的对象进入后续分支。&&需同时成立，||允许任一成立。
25. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
26. 以明确类型保存本节输入或中间量；*为对象指针，const禁止通过此变量改值，数字类型决定取整和是否可为负。
27. 本节辅助赋值／调用，按右侧结果更新左侧状态。请结合紧邻代码和本节输入输出阅读；这是实际源码原句，不是建议另写的新实现。
28. 读取指定技能、效果槽和需要时指定施法者的光环效果，不凭是否学会代替是否正在生效。
29. 按WD114协议发送服务端只读数值；{}个数必须与顶层实参一一对应，Toss遗漏字段就是在这里。
30. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
31. 进入前一个条件没有命中的备选分支，保留互斥顺序而不是同时执行两种附效。
32. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
33. 本节辅助赋值／调用，按右侧结果更新左侧状态。请结合紧邻代码和本节输入输出阅读；这是实际源码原句，不是建议另写的新实现。
34. 按WD114协议发送服务端只读数值；{}个数必须与顶层实参一一对应，Toss遗漏字段就是在这里。
35. 以明确类型保存本节输入或中间量；*为对象指针，const禁止通过此变量改值，数字类型决定取整和是否可为负。
36. 按WD114协议发送服务端只读数值；{}个数必须与顶层实参一一对应，Toss遗漏字段就是在这里。
37. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
38. 按WD114协议发送服务端只读数值；{}个数必须与顶层实参一一对应，Toss遗漏字段就是在这里。
39. 返回当前函数计算出的值或错误码，当前函数在这里结束；外层流程根据返回结果继续或拒绝。
40. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。

## 11. 药水提示：左说明和右标题都处理

id只匹配两个七级系列。查找15秒／15 sec cooldown／Cooldown基础文案；从服务端e毫秒换秒，缺值显示同步中。self.wd114Lines保留原始文本，所以10→15→10可正确来回。

实际来源：[NumericTooltip.lua](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261005/codexfix_202610050306_阶段WD127F_投掷泼洒冷却完整同步/02_覆盖到客户端根目录/Interface/AddOns/RebornWitchDoctorTalents/NumericTooltip.lua:74)。归档完整副本：[成功代码快照/NumericTooltip.lua](成功代码快照/NumericTooltip.lua)。

```lua
    elseif (id>=9003870 and id<=9003876 or id>=9003890 and id<=9003896) and (clean:find("15秒冷却",1,true) or clean:find("15 sec cooldown",1,true) or clean:find("15 sec Cooldown",1,true)) then
     -- WD127F: native cooldown headings are Right FontStrings; descriptions are Left.
     -- Always rebuild from original text, including when a saved build is changed.
     local seconds=value and value.e and value.e/1000
     local rendered=seconds and clean:gsub("15秒冷却",string.format("%g秒冷却",seconds)):gsub("15 sec cooldown",string.format("%g sec cooldown",seconds)):gsub("15 sec Cooldown",string.format("%g sec Cooldown",seconds)) or (original..(en and " (syncing)" or "（同步中）"))
     self.wd114Lines[key]={original=original,rendered=rendered};if text~=rendered then font:SetText(rendered);changed=true end
```

逐行读法（编号对应上述代码块；空行和块边界也说明）：

1. 进入前一个条件没有命中的备选分支，保留互斥顺序而不是同时执行两种附效。
2. 注释：记录WD127F: native cooldown headings are Right FontStrings; descriptions are Left.；注释本身不执行。
3. 注释：记录Always rebuild from original text, including when a saved build is changed.；注释本身不执行。
4. 把服务端毫秒换成界面秒；10000显示10，不靠格式四舍五入遮掩数据错误。
5. 仅替换白名单法术的基础冷却文本，保留射程、HoT持续和其他描述；三种中英格式都处理。
6. 记录这条FontString的原文和本次输出；切方案可恢复15，不能反复在10上再减5。

## 12. Lua重入保护与异步响应核对

refresh绘制锁处理Show同步重入；receive校验序号、ID、epoch、状态、revision和活动方案，解析八项数字并缓存。旧响应不得写入当前别的技能。

实际来源：[NumericTooltip.lua](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261005/codexfix_202610050306_阶段WD127F_投掷泼洒冷却完整同步/02_覆盖到客户端根目录/Interface/AddOns/RebornWitchDoctorTalents/NumericTooltip.lua:114)。归档完整副本：[成功代码快照/NumericTooltip.lua](成功代码快照/NumericTooltip.lua)。

```lua
local function refresh(self,forced)
 -- Show() and other tooltip hooks may synchronously request another refresh.
 if self.wd114Drawing then return end
 self.wd114Drawing=true
 draw(self,forced)
 self.wd114Drawing=nil
end
local function receive(message)
 local n,id,status,rest=message:match("^WD114|(%d+)|(%d+)|([^|]+)|?(.*)$")
 n,id=tonumber(n),tonumber(id)
 if not n or not pending or n~=pending.seq or id~=pending.id or pending.epoch~=epoch then return end
 pending=nil
 if status~="ok" then failed();return end
 local cost,a,b,rev,active,c,d,e=rest:match("^(%d+)|([%-]?%d+)|([%-]?%d+)|(%d+)|(%d+)|(%d+)|(%d+)|(%d+)$")
 if not cost then cost,a,b,rev,active,c,d=rest:match("^(%d+)|([%-]?%d+)|([%-]?%d+)|(%d+)|(%d+)|(%d+)|(%d+)$") end
 if not cost then cost,a,b,rev,active,c=rest:match("^(%d+)|([%-]?%d+)|([%-]?%d+)|(%d+)|(%d+)|(%d+)$") end
 if not cost then cost,a,b,rev,active=rest:match("^(%d+)|([%-]?%d+)|([%-]?%d+)|(%d+)|(%d+)$") end
 if not cost then return end
 local state=RebornWD8
 if state and state.loaded and (state.pending or tonumber(rev)~=state.revision or tonumber(active)~=state.active) then return end
 failures=0
 cache[id]={e=tonumber(e),d=tonumber(d),c=tonumber(c),cost=tonumber(cost),a=tonumber(a),b=tonumber(b),rev=tonumber(rev),active=tonumber(active),time=GetTime()}
 if tip:IsShown() and tip.wd114Spell==id then refresh(tip) end
end
```

逐行读法（编号对应上述代码块；空行和块边界也说明）：

1. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
2. 注释：记录Show() and other tooltip hooks may synchronously request another refresh.；注释本身不执行。
3. Show或其他提示钩子会重入；绘制锁避免同步递归。
4. Show或其他提示钩子会重入；绘制锁避免同步递归。
5. 本节辅助赋值／调用，按右侧结果更新左侧状态。请结合紧邻代码和本节输入输出阅读；这是实际源码原句，不是建议另写的新实现。
6. Show或其他提示钩子会重入；绘制锁避免同步递归。
7. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
8. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
9. 声明Lua局部状态，只在当前作用域使用；本节后续调用读取该变量，不修改全局角色存档。
10. 本节辅助赋值／调用，按右侧结果更新左侧状态。请结合紧邻代码和本节输入输出阅读；这是实际源码原句，不是建议另写的新实现。
11. 用请求的缓存代数过滤切方案／清缓存之前的回包。
12. 本节辅助赋值／调用，按右侧结果更新左侧状态。请结合紧邻代码和本节输入输出阅读；这是实际源码原句，不是建议另写的新实现。
13. 条件守卫：条件不满足时阻止本节无资格／不匹配的对象进入后续分支。&&需同时成立，||允许任一成立。
14. 按完整协议字段解析cost、a、b、revision、active、c、d、e；老格式回退不能假造新字段。
15. 按完整协议字段解析cost、a、b、revision、active、c、d、e；老格式回退不能假造新字段。
16. 按完整协议字段解析cost、a、b、revision、active、c、d、e；老格式回退不能假造新字段。
17. 按完整协议字段解析cost、a、b、revision、active、c、d、e；老格式回退不能假造新字段。
18. 条件守卫：条件不满足时阻止本节无资格／不匹配的对象进入后续分支。&&需同时成立，||允许任一成立。
19. 声明Lua局部状态，只在当前作用域使用；本节后续调用读取该变量，不修改全局角色存档。
20. 保存未确认时不显示草稿效果；已知revision和active还要与回包吻合。
21. 本节辅助赋值／调用，按右侧结果更新左侧状态。请结合紧邻代码和本节输入输出阅读；这是实际源码原句，不是建议另写的新实现。
22. 按SpellID存权威数字并记录revision、active、更新时间；不是按当前鼠标位置随便共享值。
23. 条件守卫：条件不满足时阻止本节无资格／不匹配的对象进入后续分支。&&需同时成立，||允许任一成立。
24. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。

## 13. 技能书只读诊断：不再写原生安全按钮

scan只读分类与原生槽；locate只读渲染列表算页格；命令打印已学、槽、分类、页和格。监测ADDON_ACTION事件只存日志。当前诊断名单仍含退役9003854，看到它false并不代表正规9003620/21没学，后续可定向更新诊断名单。

实际来源：[RebornWitchDoctorSkillBook.lua](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261005/codexfix_202610050306_阶段WD127F_投掷泼洒冷却完整同步/02_覆盖到客户端根目录/Interface/AddOns/RebornWitchDoctorSkillBook/RebornWitchDoctorSkillBook.lua:1)。归档完整副本：[成功代码快照/RebornWitchDoctorSkillBook.lua](成功代码快照/RebornWitchDoctorSkillBook.lua)。

```lua
-- WD52A: follow MONKM1B's read-only native spellbook diagnostics.
SLASH_REBORNWDBOOK1 = "/wdbook"
SlashCmdList.REBORNWDBOOK = function()
    local _, class, id = UnitClass("player")
    if class ~= "WITCHDOCTOR" and id ~= 13 then
        print("[WD52A] 当前角色不是巫医。")
        return
    end
    print("[WD52A] 技能书分类不限制专精，也不会自动学习技能。")
    for i = 1, GetNumSpellTabs() do
        local name, _, offset, count = GetSpellTabInfo(i)
        print(string.format("%d: %s / %d spells / offset %d", i, name or "?", count or 0, offset or 0))
    end
end


-- WD119B: read-only diagnostics. Never refresh, navigate or mutate native spellbook state.
local ids={9003850,9003851,9003852,9003853,9003854,9003855,9003432,9003857,9003858}
local function isDoctor()
 local _,token,id=UnitClass("player");return token=="WITCHDOCTOR" or id==13
end
local function scan()
 local native,tab={},nil
 for i=1,GetNumSpellTabs() do
  local name,_,offset,count=GetSpellTabInfo(i)
  if name and (name:find("巫毒",1,true) or name:lower():find("voodoo",1,true)) then tab=i end
  for slot=(offset or 0)+1,(offset or 0)+(count or 0) do
   local link=GetSpellLink(slot,BOOKTYPE_SPELL or "spell")
   local id=link and tonumber(link:match("spell:(%d+)"))
   if id then
    native[id]={tab=i,slot=slot}
    if not tab and (id==9003143 or id==9003150 or id==9003640) then tab=i end
   end
  end
 end
 return native,tab
end
local function locate(id)
 for tab,list in pairs(spellbookCustomRender or {}) do
  for index,entry in ipairs(list) do
   if entry.spellID==id then return tab,math.ceil(index/12),(index-1)%12+1 end
  end
 end
end

local names={['假死']=9003853,['假死药剂']=9003853,['显性诅咒']=9003852,['強效混合']=9003854,['强效混合']=9003854,['沃金守望']=9003855,['迅捷神像']=9003432}
local previous=SlashCmdList.REBORNWDBOOK
local lastBlocked
local monitor=CreateFrame('Frame')
monitor:RegisterEvent('ADDON_ACTION_BLOCKED')
monitor:RegisterEvent('ADDON_ACTION_FORBIDDEN')
monitor:SetScript('OnEvent',function(_,event,addon,operation)
 if isDoctor() then lastBlocked={event,tostring(addon),tostring(operation)} end
end)
SlashCmdList.REBORNWDBOOK=function(arg)
 if not isDoctor() then return end
 local text=(arg or ''):match('^%s*(.-)%s*$')
 local id=tonumber(text) or names[text]
 if not id then previous() end
 local native=scan()
 for _,sid in ipairs(id and {id} or ids) do
  local tab,page,slot=locate(sid)
  print(string.format('[WD119B] %d %s 已学=%s 原生槽=%s 分类=%s 页=%s 格=%s',sid,GetSpellInfo(sid) or '?',tostring(IsSpellKnown(sid)),tostring(native[sid] and native[sid].slot),tostring(tab),tostring(page),tostring(slot)))
 end
 print('[WD119B] 只读定位：请手动点击对应分类和页码；左右列交替计格。')
 if lastBlocked then print('[WD119B] 最近受保护操作：'..table.concat(lastBlocked,' / ')) end
end
return {locate=locate,scan=scan}
```

逐行读法（编号对应上述代码块；空行和块边界也说明）：

1. 注释：记录WD52A: follow MONKM1B's read-only native spellbook diagnostics.；注释本身不执行。
2. 本节辅助赋值／调用，按右侧结果更新左侧状态。请结合紧邻代码和本节输入输出阅读；这是实际源码原句，不是建议另写的新实现。
3. 本节辅助赋值／调用，按右侧结果更新左侧状态。请结合紧邻代码和本节输入输出阅读；这是实际源码原句，不是建议另写的新实现。
4. 夹具返回巫医class13，避免测试提前在资格检查处退出。
5. 条件守卫：条件不满足时阻止本节无资格／不匹配的对象进入后续分支。&&需同时成立，||允许任一成立。
6. 输出检查／诊断结果，不能把这行文字当作游戏实机通过。
7. 返回当前函数计算出的值或错误码，当前函数在这里结束；外层流程根据返回结果继续或拒绝。
8. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
9. 输出检查／诊断结果，不能把这行文字当作游戏实机通过。
10. 只读枚举书页分类，不限制专精也不自动授予技能。
11. 读取分类名称、原生偏移与槽数，用于解释SkillLine与书页位置。
12. 输出检查／诊断结果，不能把这行文字当作游戏实机通过。
13. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
14. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
15. 空行：把不同职责分开，运行时不做任何事。
16. 空行：把不同职责分开，运行时不做任何事。
17. 注释：记录WD119B: read-only diagnostics. Never refresh, navigate or mutate native spellbook state.；注释本身不执行。
18. 撤销旧重复的通用强效混合技能／Aura，避免它与正规9003620/21重复生效。
19. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
20. 夹具返回巫医class13，避免测试提前在资格检查处退出。
21. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
22. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
23. 声明Lua局部状态，只在当前作用域使用；本节后续调用读取该变量，不修改全局角色存档。
24. 只读枚举书页分类，不限制专精也不自动授予技能。
25. 读取分类名称、原生偏移与槽数，用于解释SkillLine与书页位置。
26. 条件守卫：条件不满足时阻止本节无资格／不匹配的对象进入后续分支。&&需同时成立，||允许任一成立。
27. 只遍历本节列出的对象／索引，每次更新循环变量；范围不能误含其他职业ID。
28. 声明Lua局部状态，只在当前作用域使用；本节后续调用读取该变量，不修改全局角色存档。
29. 声明Lua局部状态，只在当前作用域使用；本节后续调用读取该变量，不修改全局角色存档。
30. 条件守卫：条件不满足时阻止本节无资格／不匹配的对象进入后续分支。&&需同时成立，||允许任一成立。
31. 本节辅助赋值／调用，按右侧结果更新左侧状态。请结合紧邻代码和本节输入输出阅读；这是实际源码原句，不是建议另写的新实现。
32. 条件守卫：条件不满足时阻止本节无资格／不匹配的对象进入后续分支。&&需同时成立，||允许任一成立。
33. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
34. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
35. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
36. 返回当前函数计算出的值或错误码，当前函数在这里结束；外层流程根据返回结果继续或拒绝。
37. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
38. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
39. 只遍历本节列出的对象／索引，每次更新循环变量；范围不能误含其他职业ID。
40. 只遍历本节列出的对象／索引，每次更新循环变量；范围不能误含其他职业ID。
41. 条件守卫：条件不满足时阻止本节无资格／不匹配的对象进入后续分支。&&需同时成立，||允许任一成立。
42. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
43. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
44. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
45. 空行：把不同职责分开，运行时不做任何事。
46. 撤销旧重复的通用强效混合技能／Aura，避免它与正规9003620/21重复生效。
47. 声明Lua局部状态，只在当前作用域使用；本节后续调用读取该变量，不修改全局角色存档。
48. 保存最后一次被阻止操作的信息，打印即可，不调用原生按钮刷新来修它。
49. 模拟Frame事件注册与回调保存，允许测试主动调用事件清缓存。
50. 记录受保护操作事件，提供诊断；没有taint源栈时不能断言DBM是最初污染源。
51. 记录受保护操作事件，提供诊断；没有taint源栈时不能断言DBM是最初污染源。
52. 本节辅助赋值／调用，按右侧结果更新左侧状态。请结合紧邻代码和本节输入输出阅读；这是实际源码原句，不是建议另写的新实现。
53. 保存最后一次被阻止操作的信息，打印即可，不调用原生按钮刷新来修它。
54. 本节辅助赋值／调用，按右侧结果更新左侧状态。请结合紧邻代码和本节输入输出阅读；这是实际源码原句，不是建议另写的新实现。
55. 本节辅助赋值／调用，按右侧结果更新左侧状态。请结合紧邻代码和本节输入输出阅读；这是实际源码原句，不是建议另写的新实现。
56. 条件守卫：条件不满足时阻止本节无资格／不匹配的对象进入后续分支。&&需同时成立，||允许任一成立。
57. 声明Lua局部状态，只在当前作用域使用；本节后续调用读取该变量，不修改全局角色存档。
58. 声明Lua局部状态，只在当前作用域使用；本节后续调用读取该变量，不修改全局角色存档。
59. 条件守卫：条件不满足时阻止本节无资格／不匹配的对象进入后续分支。&&需同时成立，||允许任一成立。
60. 声明Lua局部状态，只在当前作用域使用；本节后续调用读取该变量，不修改全局角色存档。
61. 只遍历本节列出的对象／索引，每次更新循环变量；范围不能误含其他职业ID。
62. 从真实列表算分类／页／格，只读输出让用户手动翻页。
63. 输出检查／诊断结果，不能把这行文字当作游戏实机通过。
64. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
65. 输出检查／诊断结果，不能把这行文字当作游戏实机通过。
66. 保存最后一次被阻止操作的信息，打印即可，不调用原生按钮刷新来修它。
67. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
68. 返回当前函数计算出的值或错误码，当前函数在这里结束；外层流程根据返回结果继续或拒绝。

## 14. 真实Lua测试逐行：84场景如何组成

完整测试加载交付NumericTooltip，模拟最小Frame/FontString和时间，不复制实现。84＝2语言×2药水系列×7级×3种CD变化。另测缺字段与迟到响应。测试说明行写12秒仅用于验证HoT不误改，不宣称投掷的真实HoT为12；实际投掷仍18秒。

实际来源：[potion_numeric_test.lua](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261005/codexfix_202610050306_阶段WD127F_投掷泼洒冷却完整同步/checks/potion_numeric_test.lua:1)。归档完整副本：[成功代码快照/potion_numeric_test.lua](成功代码快照/potion_numeric_test.lua)。

```lua
local file=arg[1]
local now=0;local locale='zhCN';local sent={};local frames={};local id=9003143
function GetLocale() return locale end
function GetTime() return now end
function UnitClass() return '巫医','WITCHDOCTOR',13 end
function SendChatMessage(s) sent[#sent+1]=s end
function hooksecurefunc() end
function ChatFrame_AddMessageEventFilter(_,fn) _G.filter114=fn end
function CreateFrame()
 local f={};function f:RegisterEvent()end;function f:SetScript(k,v)self[k]=v end;frames[#frames+1]=f;return f
end
local function font(s) return {text=s,GetText=function(self)return self.text end,SetText=function(self,s)self.text=s end} end
GameTooltip={hooks={},n=4}
function GameTooltip:HookScript(k,v) self.hooks[k]=v end
function GameTooltip:GetSpell()return 'Skill','Rank 4',id end
function GameTooltip:GetName()return 'GameTooltip'end
function GameTooltip:NumLines()return self.n end
function GameTooltip:IsShown()return true end
function GameTooltip:AddLine(s)self.n=self.n+1;_G['GameTooltipTextLeft'..self.n]=font(s)end
function GameTooltip:SetHyperlink()end
function GameTooltip:SetSpellByID()end
function GameTooltip:SetSpellBookItem()end
function GameTooltip:SetAction()end
function GetSpellBookItemInfo()return 'SPELL',id end
function GetActionInfo()return 'spell',id end
RebornWD8={loaded=true,pending=false,revision=10,active=1,draftAE='99999999999999999999'}
local M=assert(loadfile(file))()
local function reset(s)
 GameTooltip.hooks.OnTooltipCleared(GameTooltip);GameTooltip.n=4
 GameTooltipTextLeft2=font(s or '330法力值');GameTooltipTextRight2=font('30码射程');GameTooltipTextLeft3=font('瞬发法术');GameTooltipTextLeft4=font('说明')
end
local function seq()return tonumber(sent[#sent]:match('numbers (%d+)'))end

local cases=0
for _,lang in ipairs({'zhCN','enUS'}) do
 locale=lang;now=0;frames={};sent={};M=assert(loadfile(file))()
 for _,first in ipairs({9003870,9003890}) do
  for rank=0,6 do
   id=first+rank
   for _,cooldown in ipairs({10000,15000,10000}) do
    M.invalidate();now=now+3;reset('826 Mana')
    GameTooltipTextRight3=font(lang=='zhCN' and '15秒冷却时间' or '15 sec Cooldown')
    GameTooltipTextLeft4=font(lang=='zhCN' and '蘑菇持续12秒，每3秒；15秒冷却。' or 'Shrooms 12 sec every 3 sec. 15 sec cooldown.')
    M.refresh(GameTooltip)
    assert(GameTooltipTextRight3.text:find('syncing',1,true) or GameTooltipTextRight3.text:find('同步中',1,true))
    M.receive('WD114|'..seq()..'|'..id..'|ok|826|293|319|10|1|160|12000|'..cooldown)
    local sec=tostring(cooldown/1000):gsub('%.0$','')
    assert(GameTooltipTextRight3.text==(lang=='zhCN' and sec..'秒冷却时间' or sec..' sec Cooldown'),GameTooltipTextRight3.text)
    assert(GameTooltipTextLeft4.text:find(lang=='zhCN' and sec..'秒冷却' or sec..' sec cooldown',1,true))
    assert(GameTooltipTextLeft4.text:find(lang=='zhCN' and '持续12秒' or '12 sec',1,true))
    assert(GameTooltipTextLeft5.text:find('cooldown '..sec..' sec',1,true))
    for rep=1,5 do M.refresh(GameTooltip) end
    assert(GameTooltip:NumLines()==5)
    -- Native action/book setter can rebuild the original Right heading in place.
    GameTooltipTextRight3:SetText(lang=='zhCN' and '15秒冷却时间' or '15 sec Cooldown')
    M.refresh(GameTooltip)
    assert(GameTooltipTextRight3.text==(lang=='zhCN' and sec..'秒冷却时间' or sec..' sec Cooldown'))
    cases=cases+1
   end
  end
 end
 -- No authoritative cooldown field: never invent a green 15-second result.
 id=9003876;M.invalidate();now=now+3;reset()
 GameTooltipTextRight3=font('15 sec Cooldown');M.refresh(GameTooltip)
 M.receive('WD114|'..seq()..'|'..id..'|ok|0|100|200|10|1|0|0')
 assert(GameTooltipTextLeft5.text:find('cooldown syncing',1,true))
 -- Late response for Toss must not repaint Splash.
 M.invalidate();now=now+3;id=9003876;reset();M.refresh(GameTooltip);local late=seq()
 id=9003896;reset();GameTooltipTextRight3=font('15 sec Cooldown');M.refresh(GameTooltip)
 M.receive('WD114|'..late..'|9003876|ok|0|100|200|10|1|0|0|10000')
 assert(GameTooltipTextRight3.text~='10 sec Cooldown')
end
print('PASS WD127F: '..cases..' potion rank/locale/build cases, Right header, Left description, green values, rebuild, stale replies, missing field and independent HoT duration')
```

逐行读法（编号对应上述代码块；空行和块边界也说明）：

1. 声明Lua局部状态，只在当前作用域使用；本节后续调用读取该变量，不修改全局角色存档。
2. 声明Lua局部状态，只在当前作用域使用；本节后续调用读取该变量，不修改全局角色存档。
3. 测试固定zhCN或enUS，使同一真实代码走两条语言分支。
4. 测试可控时间，确保节流、过期、超时不依赖真实等待。
5. 夹具返回巫医class13，避免测试提前在资格检查处退出。
6. 发只读数字查询，包含本次序号和准确SpellID；不是保存或施法命令。
7. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
8. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
9. 模拟Frame事件注册与回调保存，允许测试主动调用事件清缓存。
10. 声明Lua局部状态，只在当前作用域使用；本节后续调用读取该变量，不修改全局角色存档。
11. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
12. 构造有GetText/SetText的最小字体对象，测试界面文字更新。
13. 最小Tooltip夹具的方法／对象，模拟行数、事件钩子或显示状态；没有启动真实客户端。
14. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
15. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
16. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
17. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
18. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
19. 构造有GetText/SetText的最小字体对象，测试界面文字更新。
20. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
21. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
22. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
23. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
24. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
25. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
26. 本节辅助赋值／调用，按右侧结果更新左侧状态。请结合紧邻代码和本节输入输出阅读；这是实际源码原句，不是建议另写的新实现。
27. 加载真正交付的Lua文件；只模拟游戏API，不把重新抄的一份实现拿来测自己。
28. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
29. 最小Tooltip夹具的方法／对象，模拟行数、事件钩子或显示状态；没有启动真实客户端。
30. 构造同时包含12秒HoT与15秒CD的说明，验证只改CD不误改HoT。
31. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
32. 声明／定义这一小函数；本节前文给出它的输入、输出和被核心调用的时点。函数体不是写完就自动执行，仍需注册／调用。
33. 空行：把不同职责分开，运行时不做任何事。
34. 声明Lua局部状态，只在当前作用域使用；本节后续调用读取该变量，不修改全局角色存档。
35. 外层两种语言；不能只测中文说明而漏英文标题。
36. 加载真正交付的Lua文件；只模拟游戏API，不把重新抄的一份实现拿来测自己。
37. 遍历投掷9003870和泼洒9003890两个七级系列。
38. 检查七个等级：基址加0到6；只测最高级不能证明低级分支没漏。
39. 本节辅助赋值／调用，按右侧结果更新左侧状态。请结合紧邻代码和本节输入输出阅读；这是实际源码原句，不是建议另写的新实现。
40. 依次10→15→10，模拟激活、切出、再切回被动，检验可恢复而非只减一次。
41. 清权威缓存与待处理请求；随后模拟时间推进，让新查询通过节流。
42. 构造／核对真正右侧标题，旧版只改Left在这里会失败。
43. 构造同时包含12秒HoT与15秒CD的说明，验证只改CD不误改HoT。
44. 调用真实刷新入口；可用于重复绘制与原生行重建后的回归。
45. 构造／核对真正右侧标题，旧版只改Left在这里会失败。
46. 注入一个带序号、ID、revision、active和冷却字段的真实格式回包，执行真实解析／绘制。
47. 声明Lua局部状态，只在当前作用域使用；本节后续调用读取该变量，不修改全局角色存档。
48. 构造／核对真正右侧标题，旧版只改Left在这里会失败。
49. 构造同时包含12秒HoT与15秒CD的说明，验证只改CD不误改HoT。
50. 构造同时包含12秒HoT与15秒CD的说明，验证只改CD不误改HoT。
51. 断言条件不成立立即终止测试并报告行；本节检查对象是14. 真实Lua测试逐行：84场景如何组成，通过只证明这个离线边界。
52. 调用真实刷新入口；可用于重复绘制与原生行重建后的回归。
53. 原始4行加当前值1行，刷新5次也必须仍5行，防重复追加。
54. 注释：记录Native action/book setter can rebuild the original Right heading in place.；注释本身不执行。
55. 构造／核对真正右侧标题，旧版只改Left在这里会失败。
56. 调用真实刷新入口；可用于重复绘制与原生行重建后的回归。
57. 构造／核对真正右侧标题，旧版只改Left在这里会失败。
58. 计数2语言×2系列×7等级×3变化＝84，不把额外负向用例混成84个实机测试。
59. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
60. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
61. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
62. 注释：记录No authoritative cooldown field: never invent a green 15-second result.；注释本身不执行。
63. 清权威缓存与待处理请求；随后模拟时间推进，让新查询通过节流。
64. 构造／核对真正右侧标题，旧版只改Left在这里会失败。
65. 注入一个带序号、ID、revision、active和冷却字段的真实格式回包，执行真实解析／绘制。
66. 没有e字段时绿色文字必须明确等待，不能默认15冒充权威值。
67. 注释：记录Late response for Toss must not repaint Splash.；注释本身不执行。
68. 清权威缓存与待处理请求；随后模拟时间推进，让新查询通过节流。
69. 构造／核对真正右侧标题，旧版只改Left在这里会失败。
70. 注入一个带序号、ID、revision、active和冷却字段的真实格式回包，执行真实解析／绘制。
71. 构造／核对真正右侧标题，旧版只改Left在这里会失败。
72. 开始／结束这个代码块；变量的可见范围和分支归属由这里决定，括号不配对会直接编译失败。
73. 输出检查／诊断结果，不能把这行文字当作游戏实机通过。
## 15. 三个编译错误怎样从第一条报错追起

**TARGET_UNIT_SRC_AREA_RAID不存在**：查本工程SpellInfo/SharedDefines真实枚举，使用TARGET_UNIT_CASTER_AREA_RAID。两个名字语义接近不代表同核心支持。后面的modules.lib只是模块没有成功生成，先修第一条C++错误，不改链接路径。

**wanted重定义**：一个AEApply函数作用域里已有八项wanted，新四项也叫wanted。改新数组为supportWanted并改两处引用，不把旧数组删掉。数组长度不同只是编译器提示，不是把两组强行改相同长度。

**AEIds 86/88不一致**：定义、extern和遍历统一AEIdCount=88。节点数量88与mask宽100是不同概念：两级节点占两位，旧保留位也占位，不能把“88节点”当成“88位”。C++宽整数、Lua四limb、SQL精确十进制都保留同一位分配。

**min/max**：实际最终表达式为：

```cpp
rec = std::min<int32>(rec, std::max<int32>(0, int32(spellInfo->RecoveryTime) - 5000));
```

从内向外读：把基础unsigned毫秒转signed；减5000；与0取较大值；与已经原生修正的rec取较小值。已有10000保持10000，基础15000兜底10000，已有8000保留8000。不是再从10000减5000，也不靠把界面文字改10解决。

## 16. 保存与高位：为什么旧SQL会报unknown node

Characters存slot/node_id/node_rank，传输mask只是一种紧凑编码。新增ID后旧schema函数不认识记录，会用SIGNAL抛1644；这是拒绝不兼容数据，防新节点被静默丢掉。正确修复是使用当前累计Characters过程并检查实际SHOW CREATE，不是删守卫或删除角色节点。World SQL负责脚本绑定／等级链／系数，不能把它误导入Characters。

测试在临时MySQL33500执行，先核对@@datadir不是生产，再验证重复导入、旧节点保留、预算、互斥、rank上限、未购买槽、拒绝免费撤销。各原测试脚本已原样归档。每一次“返回被拒绝”都必须检查期望是成功还是拒绝，不能只有没报Python错就算SQL通过。

## 17. 图标链与安全面板

节点图标路径、SpellIconID→SpellIcon路径、BLP是否在原生MPQ三个地址要一致。Loosely stored addon BLP能在Lua窗口显示，不代表原生鼠标拾取通道也能读到。WD118B补五个相同资源进MPQ，PickupSpell不改，完全重启。没有专属图标时才需生图，本次用了现存官方资源，没有生成新图片。

已学true不等于当前页已经看见。先查槽、SkillLine、真实渲染列表、分页。WD114C误判缺列表，又D定位写安全按钮，后来119B撤这些写入。弹窗提DBM只是被阻止时涉及的插件，不能没有taint栈就断言它是源头。

WD127C六节点真正缺的是Panel绘图源Data.lua，不是Allocation/Progress逻辑。Data记录同时含id、cap、label和row/col/icon；检查源头再补，不能让用户反复找不存在的灰图标。35065图标改为Spell_Nature_Regeneration_02，与技能书同一SpellIcon2020。位置是旧树空槽，不冒称官方新树布局。

## 18. 测试代码和工具分工

- Python3.9 struct：从WDBC头得记录数／字段数／字节尺寸，验证20+n*size+stringsize等于文件长；每个`s`偏移在池内且能找到NUL。双端各自比较前后，仅目标记录变动，非目标行和原字符串前缀保留。F的比较精确到仅9003897第80列4字节变化；再按真实die0消费公式验证15000-5000=10000。
- MSVC2022 `/Zs /std:c++17 /W4 /WX`：语法检查，不生成EXE。旧混型表达式复现四个C2672，新表达式静态断言；F编译实际后置代码块的独立夹具。夹具模拟Player/Spell接口，所以不能替代整工程的头文件／链接／运行验收。
- Lua5.2解释器：实际执行交付Lua，模拟3.3.5使用的API接口，采用旧客户端可用语法；它不是3.3.5的实际运行器。先测Right标题、Left正文、当前值，再测重绘、切方案、旧回包、缺字段。此前只测左说明是本窗口反例。
- PowerShell／rg：定位文件和真实符号，不运行生产替换。MPQEditor由用户导入，官方JSON与归档只读取来源；没有随意重写旧客户端FrameXML。
- Git：按明确路径暂存相关模块／核心，排除已存在的无关改动；推送用户指定wowshub分支。对ZIP用binary属性防换行转换；`git show`取回blob与原始ZIP SHA相同并CRC通过，才算资源也推送正确。

先执行上述离线测试，失败时修实现或修错误夹具并重新跑对应场景；最后用户游戏内核对两个技能每项显示与实际时间。用户现在确认F通过，是离线加实机的基本闭环；不是所有已归档脚本都在本次重新执行了。

## 19. 新手可以怎样继续

从交接清单挑依赖已有的3—4节点，先对官方说明、上游固定commit、实际本地代码建台账。编号、获得方式、面板、等级链、保存、Aura、效果、数字、图标分别核对。新增技能要看到它能保存、能学习、能看见、能拖动、能正确施放、切方案能撤销，再交累计包。每个批次附来源、回滚、测试边界；失败包进反例，不进成功Skill。

本教程使用类型系统、协议序列化、客户端预测校正、事件生命周期、纯读UI、快照和精确整数编码这些知识。没有读取的书不虚构引用；本核心源码结构和原阶段来源才是这里参数的证据。
