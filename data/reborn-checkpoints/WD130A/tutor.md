# WD130A 开发教学

可以把光束想成浇水管：主目标接总管，每半秒已有水管各接一根支管。每个支管立即供水，下一轮开始要为它付维持费用。用“本轮开始的支管清单”循环，防止刚长出的支管在同一轮无限再生长。

1. 查官方Spell记录得到7等级、基础治疗、8秒、500毫秒和费用；再读最新社区实现得到未被官方文字量化的支管策略。DBC只是参数，不等于分支逻辑已经存在。
2. 为主技能分配9003922–28，临时修正3929，被动3930/31，隐藏治疗3932。ID是唯一键，节点ID与技能ID不可混用。
3. AuraScript保存GUID数组：GUID像对象的身份证，真正操作前查回对象并验证，避免保存失效地址。Apply建主分支；Tick先扣蓝后治疗并扩散；Removed清理临时状态。
4. 隐藏治疗将基础值加治疗强度×0.1073交给核心。SQL把额外系数设0，避免加两次。AfterHit看实际加血而非原始数值，满血不会减冷却。
5. 允许引导中施法要同时照顾客户端允许动作、服务端当前施法容器、读条和费用。共享头只识别本项目的光束与3类药水，其他技能不会获得权限。
6. 瓶外之灵把两个友方加到同一次Bottle施法里，相当于一张订单多两个收件人，而不是下三次订单。这样每次OnSpellCast仅加一次Spirit，也不会三次刷新森金。
7. 保存是一条端到端数据管道：C++节点表96项、mask108位、客户端四个32位limb、SQL DECIMAL和存档行、面板Data/Progress一并修改。105/106/107位是新节点，旧位完全不挪动。
8. 互斥与前置既要界面阻止，也要服务器和存储过程拒绝。客户端按钮不可点只是用户体验，SQL拒绝绕过请求才是持久化约束。
9. 测试先验证旧数据逐行不变，再跑真实Lua和隔离SQL，最后对5个实际C++单元做语法检查。只有你编译并在客户端测试，才能确认运行效果。语法正确并不证明网络、动画或多人生命周期正确。

## 本次排错记录

- Python3.9缺tzdata包，使用当前日期对应America/Los_Angeles的UTC-7生成目录时间；未安装环境依赖。
- Unit.cpp同一条件出现两次，初始唯一替换守卫拒绝修改；改为只匹配普通施法打断引导这一处，不修改自动射击路径。
- 6013不是普通独立节点，它带578295互斥组；初始生成守卫发现差异后补三端互斥校验。
- 第一次隔离SQL正向失败是测试夹具把药水增效放到bit90而非正确bit89；修正夹具后83检查通过，未靠放松前置使测试变绿。
- 初次Lua解释器沿用旧HighFork路径不存在；现场rg定位实际HighForkPRO路径后运行通过。
- 逐字段复核发现草稿属性0x20000会错误要求潜行，交付前改为官方原始属性并加入“不要求潜行”的回归断言；未交付该草稿。

## 关键源码逐行对照

下面是本次实际交付的新机制文件，每段保留注释。PrepareAuraScript/PrepareSpellScript宏注册当前类信息；Validate验证依赖ID；OnCheckCast是施放前检查；OnEffectPeriodic是每次周期回调；PreventDefaultAction避免再执行默认周期；AfterEffectRemove负责销毁状态。std::vector是可增长数组，std::find防重复，remove_if配合erase删除失效GUID。

```cpp
// WD130: local adaptation of CoA 04360619. Branch cap and ramp are documented policy.
namespace WD130Local
{
void Reduce(Player* p,uint32 first,uint32 last,int32 ms)
{
    for(uint32 id=first;id<=last;++id) if(p->GetSpellCooldownDelay(id)) p->ModifySpellCooldown(id,-ms);
}
}
class spell_reborn_wd130_beam : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd130_beam);
    SpellCastResult Check()
    {
        Player* p=GetCaster()->ToPlayer();
        if(!IsDoctor(p) || !p->IsAlive() || !p->HasSpell(GetSpellInfo()->Id) || p->GetLevel()<GetSpellInfo()->SpellLevel)
            return SPELL_FAILED_CASTER_AURASTATE;
        return WD130A::Friendly(p,GetExplTargetUnit())?SPELL_CAST_OK:SPELL_FAILED_BAD_TARGETS;
    }
    void Register() override { OnCheckCast += SpellCheckCastFn(spell_reborn_wd130_beam::Check); }
};
class spell_reborn_wd130_heal : public SpellScript
{
    PrepareSpellScript(spell_reborn_wd130_heal);
    void Hit()
    {
        Player* p=GetCaster()->ToPlayer();
        // Effective gain, not the raw heal or overheal, reduces each live rank's cooldown.
        if(IsDoctor(p) && GetHitHeal()>0 && p->HasAura(9003930))
        { WD130Local::Reduce(p,9003870,9003876,1000); WD130Local::Reduce(p,9003890,9003896,1000); }
    }
    void Register() override { AfterHit += SpellHitFn(spell_reborn_wd130_heal::Hit); }
};
class aura_reborn_wd130_beam : public AuraScript
{
    PrepareAuraScript(aura_reborn_wd130_beam);
    std::vector<ObjectGuid> branches;
    uint32 ticks=0;
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9003929,9003932}); }
    void Apply(AuraEffect const*,AuraEffectHandleModes)
    {
        if(Player* p=GetCaster()?GetCaster()->ToPlayer():nullptr)
        {
            branches.push_back(GetTarget()->GetGUID());
            p->CastSpell(p,9003929,true);
            if(Aura* a=p->GetAura(9003929,p->GetGUID())) { a->SetMaxDuration(GetDuration());a->SetDuration(GetDuration()); }
        }
    }
    void Heal(Player* p,ObjectGuid guid,int32 base)
    {
        if(!WD130A::Channel(p)) return;
        Unit* u=ObjectAccessor::GetUnit(*p,guid);
        if(!WD130A::Friendly(p,u)) return;
        int32 amount=std::max(0,base)+int32(float(std::max(0,p->SpellBaseHealingBonusDone(SPELL_SCHOOL_MASK_NATURE)))*0.1073f);
        // Hidden heal has zero SQL coefficients; native done/taken, crit and absorbs run once.
        p->CastCustomSpell(u,9003932,&amount,nullptr,nullptr,true);
    }
    void Tick(AuraEffect const* effect)
    {
        PreventDefaultAction();
        Player* p=GetCaster()?GetCaster()->ToPlayer():nullptr;
        if(!IsDoctor(p) || !WD130A::Channel(p)) { Remove();return; }
        branches.erase(std::remove_if(branches.begin(),branches.end(),[p](ObjectGuid g){return !WD130A::Friendly(p,ObjectAccessor::GetUnit(*p,g));}),branches.end());
        if(branches.empty()) { p->InterruptSpell(CURRENT_CHANNELED_SPELL);return; }
        static uint32 const mana[7]={101,139,186,231,316,429,470};
        ++ticks;
        uint32 cost=uint32(uint64(mana[GetId()-9003922])*branches.size()*(100+10*(ticks-1))/200);
        if(p->GetPower(POWER_MANA)<int32(cost)) { p->InterruptSpell(CURRENT_CHANNELED_SPELL);return; }
        p->ModifyPower(POWER_MANA,-int32(cost));
        // Only branches present at tick start sprout this round, so growth is bounded.
        auto previous=branches;
        for(ObjectGuid guid:previous)
        {
            if(!WD130A::Channel(p)) return;
            Heal(p,guid,effect->GetAmount());
            Unit* center=ObjectAccessor::GetUnit(*p,guid);
            if(!WD130A::Friendly(p,center) || branches.size()>=8) continue;
            ObjectGuid added;
            for(Unit* ally:WD130A::Allies(p,center))
                if(std::find(branches.begin(),branches.end(),ally->GetGUID())==branches.end())
                { added=ally->GetGUID();break; }
            if(!added.IsEmpty()) { branches.push_back(added);Heal(p,added,effect->GetAmount()); }
        }
    }
    void Removed(AuraEffect const*,AuraEffectHandleModes)
    {
        if(Unit* p=GetCaster()) p->RemoveAurasDueToSpell(9003929,p->GetGUID());
        branches.clear();
    }
    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_reborn_wd130_beam::Apply,EFFECT_0,SPELL_AURA_PERIODIC_DUMMY,AURA_EFFECT_HANDLE_REAL);
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_reborn_wd130_beam::Tick,EFFECT_0,SPELL_AURA_PERIODIC_DUMMY);
        AfterEffectRemove += AuraEffectRemoveFn(aura_reborn_wd130_beam::Removed,EFFECT_0,SPELL_AURA_PERIODIC_DUMMY,AURA_EFFECT_HANDLE_REAL);
    }
};
class wd130_events : public AllSpellScript
{
public:
    wd130_events():AllSpellScript("wd130_events",{ALLSPELLHOOK_ON_CAST}) { }
    void OnSpellCast(Spell* spell,Unit* caster,SpellInfo const* info,bool) override
    {
        Player* p=caster?caster->ToPlayer():nullptr;
        if(!spell || spell->IsTriggered() || !info || !IsDoctor(p) || !p->IsAlive()) return;
        if(WD19A::IsBrew(info->Id) && p->HasAura(9003930)) WD130Local::Reduce(p,9003922,9003928,2000);
        if(WD130A::Bottle(info->Id) && p->HasAura(9003931)) p->CastSpell(p,9003574,true);
    }
};

```

其他修改可对照rollback_WD129A：Allocation.inc负责位编码、预算、前置与正式授予；TalentNodes定义节点元数据；Talents.cpp负责服务器查询；WitchDoctorTalentPolicy拒绝导师绕过；Lua Allocation/WD8处理精确传输；Data/Progress保留布局并公开实现状态。SQL的ownership guard先检查外来绑定再写，SIGNAL表示拒绝覆盖未归属本批的数据。

## 工具和可重复实验

tools保存本次Python构建、验证和隔离MySQL脚本。构建脚本依赖本机已登记的包路径与wd19_common/Storm读取工具，供审计，不是用户安装步骤。脚本按原记录克隆、仅追加新行、保留字符串前缀；hashlib核对SHA256，struct按小端WDBC编码，zipfile检查最终归档。
checks/scenario130.lua调用真实Allocation校验，save_request.lua调用真实M.Save；test_mysql130.py新建私有数据库目录并核对端口和datadir才测试，不接生产库。MSVC响应文件/Zs日志只证明语法，不输出新的可运行服务器。
独立练习：在测试方案中尝试少1点基础TE、未满29级、同时选瓶外之灵与灵魂之触，应该被拒绝；恢复合法前置后保存并重登，应该保留。这验证的是边界约束，而不只是按钮变亮。
