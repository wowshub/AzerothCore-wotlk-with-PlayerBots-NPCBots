

## 2026-09-29 WD86A 两项用户实机通过

用户明确反馈：巫毒心智（按施放时灵魂层数调整暗影傀儡跳速和持续时间）、黑暗洛阿祝福（团队伤害提高3%，自身傀儡加速）测试通过。登记这两项基本效果通过；未提供每个层数逐跳日志、同类增伤全组合、多人归属、PvP/机器人、切方案/重登完整矩阵，不扩大结论。WD87A仍候选待测。

来源：[WD86A覆盖说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609291413_阶段WD86A_巫毒心智与黑暗洛阿祝福/README_覆盖与测试说明.md)、[完整教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609291413_阶段WD86A_巫毒心智与黑暗洛阿祝福/tutor.md)。本次不改历史交付源码/DBC/SQL及SHA256清单；新增验收附件与永久知识记录。

复用方法：周期间隔在Aura初始化读取本人灵魂快照，用基础间隔×100/(100+10×层数)；持续时间×(100+10×层数)/100。祝福本人时间项再乘80%，团队增伤用原生1056组规则3取强。HasSpell加HasAura避免队友光环接收者误获本人专属傀儡收益。施放后新增层数不追改已开始周期。C++、Lua、SQL与双端独立DBC成套交付，32位最高位保存使用BIGINT重建值；WD87扩容另行验收。

永久方法：[来源移植](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendskills/trace-and-port-coa-spell-resources/SKILL.md)、[三方案投影](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendskills/build-wotlk-three-build-projection/SKILL.md)。

# WD86A 新人教学

把天赋想成一张保存的配方。客户端点亮是写草稿，数据库保存是签字，服务器给角色被动才是按配方制作。三步少一步，就会出现“亮了但是没效果”。本批把6059、5332同时加入C++、Lua、characters检查约束和保存过程，技能书映射则在各端SkillLineAbility中独立添加。

## 1. 先问数据来自哪里

文件夹上写“最新”不保证内容最新。本次登记解包目录少三个WD85法术，实际MPQ却有；逐行比较证明旧解包所有行都是MPQ的前缀，于是只读提取实际MPQ。服务端继续独立取自己的表。这用到版本管理里的来源追踪和增量合并，不能图方便用一端整表覆盖另一端。

## 2. 为什么第32位会坏

掩码像32个灯开关。新心智用2^30=1073741824，祝福用2^31=2147483648。普通有符号32位整数最大2147483647，存祝福就可能溢出。C++原本是uint32，网络按十进制，Lua双精度在32位范围内可精确表示；旧SQL局部变量v_saved却是INT，所以单独改为BIGINT UNSIGNED。角色表仍保存node_id/node_rank，不搬迁角色数据。

保存操作先检查预算和专精，再检查请求revision，最后比较每个节点是否减少。服务器不能只信Lua，因为客户端请求可能被修改。SQL事务失败回滚，旧revision不能写入。这对应数据库事务与乐观并发控制。隔离测试特意连续保存两次带最高位的值，才能发现“第一次成功、第二次读取旧值溢出”的问题。

## 3. 两个时钟

暗影傀儡有一个总时长和一个每跳闹钟。巫毒心智有5层灵魂时，速度是基础的1.5倍，因此间隔750/1.5=500ms；总时长2250*1.5=3375ms。不是把间隔简单减50%。祝福则按官方DBC和上游用例把两个时间乘0.8；只有祝福时是600ms和1800ms，仍3跳。

代码用int64计算中间乘法，再转回int32，避免中间溢出。除法是整数除法，亚毫秒被截去。上限5层来自当前已有灵魂Aura；施放过程中新增的灵魂只影响下一次傀儡，这就是快照。没有写一个每帧追着灵魂改总时长的循环。

WD86A::Owns先判定巫医和已学技能，再检查Aura。只检查HasAura会把团队友方获得的祝福当成他自己点了天赋，从而错误加快队友傀儡。MindPercent读取本人施加的灵魂，Interval算间隔，Duration算总时长。周期函数注册到已有傀儡AuraScript，最大时长接已有AllSpellScript；均按9003680—89限定，不改其他职业或全局法术节奏。

## 4. 为什么团队增伤不手写一圈玩家

本地核心已经实现Effect65团队区域Aura和Aura79伤害百分比，交给它维护范围与团队身份。BasePoints是2，DieSides=1时实际3；如果从dummy模板复制出DieSides=0却仍写2，就会变成2%。本批离线核对时纠正了这一点。

服务端1056组用规则3处理同类伤害增益取强，新增一条(1056,9003741)，不重写整个组。导入前检查组和规则确实存在；重复导入不会重复插入；发现私有ID已经分到别的组则报错。拒绝异常比悄悄覆盖未知记录更容易排错。

## 5. DBC字符串像书的页码

偏移是本张表字符串块内的位置。复制donor行时，数字即使看起来合理，也可能指向另一本书的页码。所有四组16种本地化字符串都应检查边界和终止符，而不仅是服务端加载的s字段。此次找出9003732第187列的7914011越界，精确置0表示空Aura描述；其他旧行保持。新名字、说明、等级文字和Aura文字都写入本端自己的字符串块。

## 6. 工具与验证的用途

- Python3.9的pathlib处理路径，struct按小端解析WDBC，hashlib记录SHA256，json保存证据；build_wd86.py只写本包。它依赖本工作区north_build.py的Archive读取器来只读访问MPQ，不能在陌生机器无依赖直接运行。
- test_wd86.py逐字节比较旧行、检查四组字符串、核对机制门槛，再通过lua52_interpreter.exe运行实际交付Lua；它不是C++编译，也不是WoW实机。
- test_mysql.py用当前只读捕获的表结构建立私有测试库；先创建父表再建有外键的子表。首次测试因nodes先于members创建失败，修正为父表在前后通过；这个失败是测试夹具顺序问题。
- mysql.exe执行安装/重复安装/保存/错误请求/回滚，mysqld.exe只绑定127.0.0.1:33486。每次创建独立scratch目录，核实@@datadir后才写入，最后关闭该测试进程。生产库没有执行本批写操作。

这些知识对应常见C++整数类型/RAII与事件回调、数据库事务/约束、二进制格式和边界检查；可对照《C++ Primer》的类型与类章节、《数据库系统概念》的事务及完整性约束章节学习。这里没有伪造书中页码或逐字引用。

## 7. 独立练习

先手算0/1/5层灵魂的两种时钟，再对照README。接着在测试角色上只点草稿，保存后观察技能书，然后重登、切方案和洗点。最后让另一位没有本天赋的巫医入队，确认获得3%增伤却没有傀儡加速。每次只改变一个条件，才知道哪一层出了问题。

下方摘录本次真实交付的新增函数，并附文件行号；全部源码与插件变更见research/源码与插件差异.md。逐行说明：常量行集中私有ID；Owns的return同时检查职业、技能所有权、Aura；MindPercent的早退给无天赋者100%；GetAura按施法者GUID选本人灵魂；min把异常层数限制到已有五层；Interval先除以速度倍率再乘祝福0.8；Duration先乘延长倍率再乘0.8；max保护正周期、min保护int32转换。事件注册行告诉核心“计算周期时调用Periodic”，最大时长分支同样只匹配本地傀儡等级链。

实际文件：`01_覆盖到源代码根目录/modules/mod-reborn-witchdoctor/src/RebornWitchDoctor.cpp`

```cpp
 185: namespace WD86A
 186: {
 187: constexpr uint32 Mind=9003740, Blessing=9003741, Spirit=9003574;
 188: bool Owns(Player* p,uint32 spell)
 189: {
 190:     // A raid recipient has the damage aura, but must not inherit the owner's talent.
 191:     return IsDoctor(p) && p->HasSpell(spell) && p->HasAura(spell);
 192: }
 193: uint32 MindPercent(Player* p)
 194: {
 195:     if (!Owns(p,Mind)) return 100;
 196:     Aura* spirit=p->GetAura(Spirit,p->GetGUID());
 197:     return 100+10*(spirit ? std::min<uint32>(5,spirit->GetStackAmount()) : 0);
 198: }
 199: int32 Interval(Player* p,int32 amplitude)
 200: {
 201:     int64 value=int64(amplitude)*100/MindPercent(p);
 202:     if (Owns(p,Blessing)) value=value*80/100;
 203:     return int32(std::max<int64>(1,value));
 204: }
 205: int32 Duration(Player* p,int32 duration)
 206: {
 207:     int64 value=int64(duration)*MindPercent(p)/100;
 208:     if (Owns(p,Blessing)) value=value*80/100;
 209:     return int32(std::min<int64>(2147483647,value));
 210: }
 211: }
```
