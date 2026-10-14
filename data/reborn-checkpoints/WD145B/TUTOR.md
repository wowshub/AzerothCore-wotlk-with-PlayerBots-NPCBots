# WD145A 大白话教学

灵魂像一个最多存5格的计数器。灵魂回收负责加一格；灵魂蚀读取当前几格，发几次攻击，但不扣格。洛阿之灵是在你按下灵魂回收时先看旧格数，再掷一次概率；灵魂信徒在每次实际“获得”事件回复法力；村落智慧是被动修饰。四个职责分别实现，便于对照测试。

Lua负责选点草稿和界面，Characters SQL负责保存与拒绝非法点法，C++把当前保存方案变成技能/光环，World SQL负责告诉服务器“哪个Spell用哪个脚本”，DBC负责双端技能记录。任何一层缺失，都可能出现“能保存但技能不生效”。本批专门交叉检查注册名，不把编译通过等同绑定成功。

下面引用的是交付源码 `RebornWitchDoctorShadow145.inc` 的实际行，不是供覆盖游戏的讲解版：

## 第8行

```cpp
uint32 Count(Player* p) { Aura* a=p?p->GetAura(Spirit,p->GetGUID()):nullptr;return a?std::min<uint32>(5,a->GetStackAmount()):0; }
```

先按自己的GUID寻找灵魂光环，最多读5层；它不是背包物品。

## 第15行

```cpp
if(mod && check && mod->spellId==Wisdom && mod->op==SPELLMOD_DAMAGE) return !Reclaim(check->Id);
```

只认村落智慧自己的修饰，并只认灵魂回收九个私有等级；其余法术交还正常判断。

## 第25行

```cpp
if(Owns(p,Devotee) && GetHitUnit()==p && p->HasAura(Devotee,p->GetGUID()) && GetHitAura())
```

必须仍是活着的巫医、已保存对应被动、光环属于自己，且本次确实打到自身灵魂光环。

## 第47行

```cpp
remaining=Owns(p,GetId())?Count(p):0;
```

把施放时的灵魂数存下来，后续获得灵魂不会让这一次无限延长。

## 第51行

```cpp
damage=uint32(std::max(0,effect->GetAmount())+rap*.07f+sp*.15f);
```

按等级基础、远程攻击强度和暗影法强算基础值，转整数截去小数；之后原生战斗引擎还会算抗性等。

## 第53行

```cpp
splash=uint32(130*WD120A::Scaling(p->GetLevel())+rap*.15f+sp*.15f);
```

爆炸用单独公式，不能把主目标伤害直接复制给所有人。

## 第54行

```cpp
GetAura()->SetMaxDuration(remaining*250);GetAura()->SetDuration(remaining*250);
```

把光环时长设为层数乘250毫秒；1层250毫秒、5层1250毫秒。

## 第67行

```cpp
std::vector<ObjectGuid> selected;
```

先存副目标身份，不在触发施法跨回调期间依赖旧单位指针。

## 第77行

```cpp
if(Unit* other=ObjectAccessor::GetUnit(*p,guid))
```

轮到每个副目标时重新找单位；目标消失就跳过。

## 第90行

```cpp
new modifiers();RegisterSpellScript(WD145::spirit_gain);RegisterSpellScript(WD145::eclipse_cast);RegisterSpellScript(WD145::eclipse_aura);
```

宏会把参数字面字符串做注册名，因此这里必须和SQL中WD145::前缀一致。

## 用数字理解

施法前0、1、5层时，灵魂回收追加概率分别是0%、5%、25%；本次新产生的一层不会倒过来抬高本次概率。5层不代表每4次严格触发1次。最大法力10000时，灵魂信徒单次理论恢复300，但缺蓝只有100就最多实际恢复100；蓝条还叠加技能消耗和自然回蓝，所以用战斗日志判读。

村落智慧是+5个百分点命中，例如同条件80%→85%，不是命中等级+5；伤害20%只作用于灵魂回收。测试固定目标、装备和其他增益，对比多次非暴击结果，排除武器随机值和抗性。

SQL测试使用全新本地临时数据库并核验datadir，只测试虚拟角色。测试先故意传缺前置、错方案、旧hash、少点数，再确认拒绝且不丢原行。最后测试完整合法方案以及重复安装。测试脚本和结果是证据，不能直接改连接去生产环境执行。

本批没有游戏验收。失败教训和兼容差异见memory及来源文档；待用户确认后再把已验证部分写回永久成功案例。


# WD145B：等级与百分比怎么区分

命中等级好比装备给的原材料，等级越高，每1%所需的材料通常越多。天赋说“增加5个百分点命中”是直接增加百分比，并不是往原材料里塞5点。所以108保持108合理，但面板应解释额外加成。

服务端StatSystem真正采用“命中光环的百分比总和 + 命中等级换算值”。本包读取9004012的Effect1/2，分别对应物理和法术命中；返回的是服务器已经应用的光环值，不依赖你面板里未保存的草稿。查询不写数据库、不补发光环、更不会再加一次5%。

HitRating.lua通过hooksecurefunc在原生PaperDollFrame_SetRating完成后补充显示。记录原文本与本次渲染文本，下一次只在原文本上绘制，避免108(+5%)(+5%)不断叠加；原生换装备刷新时重新采集原值。响应序号必须等于待处理请求，旧回包、换方案和超过3秒的数据都不显示。

技能书分类是另一回事：Spell.dbc里有被动说明，不等于SkillLineAbility已映射到职业分支。新增行复用同职业暗影主动的skill/race/class字段，只替换SpellID与新行ID，禁用自动学技能标记。分类修复不要求遗忘重学。

checks/test_hit_rating.lua运行的正是交付Lua，不是另写一个假算法。当前只通过离线测试和C++语法，进游戏的栏宽、实时显示、分类结果仍待用户验收。


2026-10-13用户已确认基本通过，原文中的候选状态属于开发时历史，不扩大专项。
