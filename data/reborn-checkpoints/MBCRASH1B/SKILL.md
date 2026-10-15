---
name: repair-playerbots-unit-cache-lifetime
description: Diagnose Playerbots crashes involving cached Unit targets during logout or map changes, preserve matching dumps and symbols, and adapt GUID-based cache resolution. Do not use as a blanket fix for unrelated NPCBot owner-pointer crashes.
---

# Playerbots目标缓存寿命

MBCRASH1B：2026-10-14用户原场景基本复测未再崩溃。不是全压力/所有竞态验收。

## 证据与边界
- 先保存TXT/DMP、当时EXE/PDB和日志；程序已更新时从构建目录寻找匹配版本，以PE时间戳、CodeView GUID/age核验，不只看文件名。记录SHA256，转储和程序默认只作本地证据。
- 本例GetAura遍历无效Aura容器，调用方是大地之盾的主坦克目标。小dump未证明具体被释放角色；不能按职业或名字归因。
- NPCB1A曾修复NPCBot宠物悬空主人，属于不同调用链，不能当作本问题已经解决。

## 实施
1. 固定并阅读当前上游；本例来源mod-playerbots/mod-playerbots 79bd428115c8f33b74b13de23b133d49c3f75c60、[Issue2851](https://github.com/mod-playerbots/mod-playerbots/issues/2851)。建议不等于合入，后续先重查状态。
2. 审查Calculate、Get、LazyGet、RefGet、Set、Reset、Format和所有派生类。旧指针非空和IsInWorld不能证明未释放。
3. 在新鲜目标仍有效时保存GUID；读取时用ObjectAccessor按机器人当前地图查找，不从缓存裸指针取GUID。保留计算间隔，明确返回对象仅借用、非跨线程锁。
4. RefGet引用不能跨帧保存或绕过Set写身份；先审查实际调用方。CurrentTargetValue已有独立GUID实现，勿盲目替换。
5. 独立覆盖包、输入输出哈希、共享区登记；不覆盖日常源码或别人脏文件。公共头需重新构建依赖。

## 验证与反例
- 覆盖删除/离线/移除中/跨地图/同GUID新对象/重置/计时回绕；检验正常大地之盾、主坦克仇恨和其他目标选择。
- 编译检查及模型不等于游戏；记录用户真实复测范围。单纯给Aura加nullptr判断、关闭某职业或删除角色数据不能替代缓存寿命修复。
- 上游同样提到UnitManualSetValue；MBCRASH1B只修计算型缓存，未宣称全库裸指针已消除。

来源：[验收档案](ACCEPTANCE.md)；[教学](TUTOR.md)。
