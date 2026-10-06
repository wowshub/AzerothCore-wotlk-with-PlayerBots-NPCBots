# WD132A 实际代码教学

先读README与来源说明。下列是本包实际源码，行号对应交付文件；可配合checks/candidate.diff阅读全部改动。

## 新附效实现

Enabled要求正式已学习且自身拥有被动Aura，草稿不能授权；Nearby用核心网格搜索，再筛自身/团队、存活、范围、视线。Echo以GetHitHeal返回的实际生命增量为源，剔除主目标与满血，按血量百分比/GUID排序，仅保存两个GUID，逐个重新取对象防对象失效。半量取整后只算接收目标修正，经过吸收、实际加血、日志和治疗威胁。Restore只在成功光束施法回调执行，优先缺蓝比例、上限10，触发原生持续Aura而不是自己定时加蓝。
001: `// WD132: effective Beam healing -> two lowest-health allies; no recursive Beam casts.`

002: `#include "ThreatManager.h"`

003: `namespace WD132A`

004: `{`

005: `constexpr uint32 Wave=9003937, Heal=9003938, Replenishment=9003939;`

006: `bool Enabled(Player* p) { return IsDoctor(p) && p->IsAlive() && p->HasSpell(Wave) && p->HasAura(Wave,p->GetGUID()); }`

007: `std::list<Unit*> Nearby(Player* p,Unit* center,float radius)`

008: `{`

009: `    std::list<Unit*> units;`

010: `    if(!center) return units;`

011: `    Acore::AnyUnitInObjectRangeCheck check(center,radius);`

012: `    Acore::UnitListSearcher<Acore::AnyUnitInObjectRangeCheck> search(center,units,check);`

013: `    Cell::VisitObjects(center,search,radius);`

014: `    units.remove_if([p,center,radius](Unit* u){return !WD130A::Friendly(p,u) || (u!=p && !p->IsInRaidWith(u)) ||`

015: `        !center->IsWithinDistInMap(u,radius) || !center->IsWithinLOSInMap(u);});`

016: `    return units;`

017: `}`

018: `void Echo(Player* p,Unit* primary,uint32 effective)`

019: `{`

020: `    if(!Enabled(p) || !primary || effective<2) return;`

021: `    SpellInfo const* info=sSpellMgr->GetSpellInfo(Heal);if(!info) return;`

022: `    auto units=Nearby(p,primary,20.0f); // official Radius9=20; community uses 15.`

023: `    units.remove_if([primary](Unit* u){return u==primary || u->IsFullHealth();});`

024: `    units.sort([](Unit* a,Unit* b){return a->GetHealthPct()==b->GetHealthPct()?a->GetGUID()<b->GetGUID():a->GetHealthPct()<b->GetHealthPct();});`

025: `    std::vector<ObjectGuid> targets;`

026: `    for(Unit* u:units) { targets.push_back(u->GetGUID());if(targets.size()==2) break; }`

027: `    ObjectGuid center=primary->GetGUID();`

028: `    for(ObjectGuid guid:targets)`

029: `    {`

030: `        Unit* u=ObjectAccessor::GetUnit(*p,guid);Unit* origin=ObjectAccessor::GetUnit(*p,center);`

031: `        if(!Enabled(p) || !origin || !WD130A::Friendly(p,u) || (u!=p && !p->IsInRaidWith(u)) ||`

032: `           !origin->IsWithinDistInMap(u,20.0f) || !origin->IsWithinLOSInMap(u)) continue;`

033: `        // Source effective heal already includes caster bonuses and crit. Apply recipient modifiers once.`

034: `        uint32 amount=u->SpellHealingBonusTaken(p,info,effective/2,HEAL);`

035: `        HealInfo heal(p,u,amount,info,info->GetSchoolMask());`

036: `        Unit::CalcHealAbsorb(heal);p->HealBySpell(heal,false);`

037: `        // No extra proc dispatch: this copied heal cannot recursively grow branches or reduce potion CDs.`

038: `        u->GetThreatMgr().ForwardThreatForAssistingMe(p,float(heal.GetEffectiveHeal())*0.5f,info);`

039: `    }`

040: `}`

041: `void Restore(Player* p)`

042: `{`

043: `    if(!Enabled(p)) return;`

044: `    auto units=Nearby(p,p,40.0f);`

045: `    units.remove_if([](Unit* u){return u->getPowerType()!=POWER_MANA || !u->GetMaxPower(POWER_MANA);});`

046: `    units.sort([](Unit* a,Unit* b){`

047: `        uint64 left=uint64(a->GetPower(POWER_MANA))*b->GetMaxPower(POWER_MANA),right=uint64(b->GetPower(POWER_MANA))*a->GetMaxPower(POWER_MANA);`

048: `        return left==right?a->GetGUID()<b->GetGUID():left<right;`

049: `    });`

050: `    std::vector<ObjectGuid> targets;`

051: `    for(Unit* u:units) { targets.push_back(u->GetGUID());if(targets.size()==10) break; }`

052: `    for(ObjectGuid guid:targets)`

053: `        if(Unit* u=ObjectAccessor::GetUnit(*p,guid))`

054: `            if(WD130A::Friendly(p,u) && (u==p || p->IsInRaidWith(u)) && u->getPowerType()==POWER_MANA)`

055: `                p->CastSpell(u,Replenishment,true);`

056: `}`

057: `}`

## 事件顺序与保存

RebornWitchDoctor.cpp先include132再include130，让130调用132命名空间。130的AfterHit先给Echo传有效治疗，再继续原有泼洒他们减CD；Echo的9003938不是9003932，不绑定130治疗脚本。AllSpellScript排除triggered和非巫医，Beam成功cast才Restore，药水/瓶中之灵不触发本次回蓝。
Allocation.inc末尾扩容AEIds并使用111位边界，索引98经已有Shift映射110；等级40、父节点索引54、专精1在C++/Lua/SQL三处一致。免费节点不加入TESpent；方案应用学习或撤销9003937并核自身Aura。Characters过程增加r98与DECIMAL的2^110，旧记录重装不删除，不能免费退点。真实M.Save输出1298074214633716130504660937080832，等于2^110+洛阿祝福2^63。

## DBC与SQL

wd132_data.py分别从服务端与客户端各自WD131A核对当前运行字节，再追加三行，保留旧行和字符串池。74列die均0；9003939第80列5，第95列21，第98列5000，第40列8。三个新法术共用4733图标，仅被动进SkillLineAbility。两端Icon表各追加自己的索引，不交换DBC。
10_WORLD脚本在任何插入前检查组占用和stack_rule/description所有权，重复执行幂等，碰到外来数据停止。test_mysql132.py使用独立33532端口和新datadir，先核@@datadir，结束关闭该实例；124项含老功能、新111位保存、冲突前不写入。不得改指生产地址。

## 检查与复现

tools/wd132_verify.py加载真实Lua、查DBC旧行保留及字段、跑旧数值场景；wd132_extra.py查官方/本地半径和持续时间并调用真实M.Save。MSVC先vcvars64再/Zs检查两个完整实际翻译单元，日志与rsp留checks。它不输出可部署EXE。
开发时发现patch-T未单独包含SpellRadius/SpellDuration，改为扫描官方数据归档记录其来源并比较相关行，避免凭旧经验推定半径；此过程没有改写旧包或现场文件。脚本依赖本机已有前批工具路径，拷到另一台机器须先配置路径，不能当一键生产升级脚本执行。
验收应记录原有效治疗、扩散ID、目标血量、回蓝日志、施法者和范围；离线检查不能代替实机测试。用户确认后才按永久release-tested-reborn-features流程提交与制作tag/Release资料。
