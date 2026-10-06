# WD133A 实际代码教学

野兽之血像把一笔账分五期付款，不能把分期当打折；水晶之水像把真正收到账的治疗换成短时储备，过量治疗不能充入储备；鱼骨则是准备配方后给下一瓶药贴一次附加效果。先读README测试单与来源文件，再对照下列实际源码。

DeferredDamage::Store把实际吸收数分成商与余数，余数按前几格加1，不丢失小数尾数；Next先清当前格再返回，Drain先清全部账再返回，避免伤害触发死亡/光环移除时重复支付。它不决定免伤、学校或目标，仅负责整数守恒。
base施法检查只认可本角色正式拥有的技能与大锅；原生团队范围Aura控制进入/离开，Apply给野兽目标独立隐藏Aura并对齐剩余时间。Removed按施法者GUID清自己的隐藏Aura，触发还债；Crystal已产生盾不清，最多保留剩余5秒。
beast::Absorb只选直接物理伤害及一个来源，AfterAbsorb记录实际数值。Tick每秒取一期，Removed取所有余款；Pay使用已减免后的债务，不再通过护甲/护盾重复减免，独立日志ID标明这是偿还。若目标死亡或已不在世界，跳过后续伤害。
crystal::OnHeal在核心实际加血之后读gain，选择一个9003944来源，重新解析GUID并检查范围/团队/存活，按gain/5加剩余盾并封顶最大生命，再施放隐藏吸收盾。施放吸收盾不产生新的治疗，因此没有递归；魔精波动的直接HealInfo同样走DealHeal，所以无需破坏其不额外派发proc的旧保证。

## RebornWitchDoctorDeferredDamage.h

001: `#pragma once`

002: `#include <array>`

003: `#include <cstdint>`

004: `namespace WD133`

005: `{`

006: `struct DeferredDamage`

007: `{`

008: `    std::array<std::uint64_t,5> debt{};`

009: `    unsigned cursor=0;`

010: `    void Store(std::uint32_t amount)`

011: `    {`

012: `        for(unsigned i=0;i<5;++i) debt[(cursor+i)%5]+=amount/5+(i<amount%5);`

013: `    }`

014: `    std::uint64_t Next()`

015: `    {`

016: `        auto amount=debt[cursor];debt[cursor]=0;cursor=(cursor+1)%5;return amount;`

017: `    }`

018: `    std::uint64_t Drain()`

019: `    {`

020: `        std::uint64_t total=0;for(auto d:debt) total+=d;debt={};return total;`

021: `    }`

022: `};`

023: `}`


## RebornWitchDoctorBrewing133.inc

001: `// WD133: two Cauldron bases; native raid-area lifecycle; no global healing coefficient changes.`

002: `#include "RebornWitchDoctorDeferredDamage.h"`

003: `class spell_reborn_wd133_base : public SpellScript`

004: `{`

005: `    PrepareSpellScript(spell_reborn_wd133_base);`

006: `    SpellCastResult Check()`

007: `    {`

008: `        Player* p=GetCaster()->ToPlayer();`

009: `        return IsDoctor(p) && p->IsAlive() && p->HasSpell(GetSpellInfo()->Id) && p->HasSpell(9003864)`

010: `            ?SPELL_CAST_OK:SPELL_FAILED_CASTER_AURASTATE;`

011: `    }`

012: `    void Register() override { OnCheckCast += SpellCheckCastFn(spell_reborn_wd133_base::Check); }`

013: `};`

014: `class aura_reborn_wd133_base : public AuraScript`

015: `{`

016: `    PrepareAuraScript(aura_reborn_wd133_base);`

017: `    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9003942,9003943,9003944,9003945}); }`

018: `    void Apply(AuraEffect const*,AuraEffectHandleModes)`

019: `    {`

020: `        Unit* p=GetCaster();Unit* u=GetTarget();if(!p || !u) return;`

021: `        if(p==u) p->RemoveAurasDueToSpell(GetId()==9003942?9003944:9003942,p->GetGUID());`

022: `        if(GetId()==9003942)`

023: `        {`

024: `            p->CastSpell(u,9003943,true);`

025: `            if(Aura* a=u->GetAura(9003943,p->GetGUID())) { a->SetMaxDuration(GetDuration());a->SetDuration(GetDuration()); }`

026: `        }`

027: `    }`

028: `    void Removed(AuraEffect const*,AuraEffectHandleModes)`

029: `    {`

030: `        if(GetId()==9003942) GetTarget()->RemoveAurasDueToSpell(9003943,GetCasterGUID());`

031: `        // Earned Crystal shields last their remaining 5 seconds after leaving the field.`

032: `    }`

033: `    void Register() override`

034: `    {`

035: `        AfterEffectApply += AuraEffectApplyFn(aura_reborn_wd133_base::Apply,EFFECT_0,SPELL_AURA_DUMMY,AURA_EFFECT_HANDLE_REAL);`

036: `        AfterEffectRemove += AuraEffectRemoveFn(aura_reborn_wd133_base::Removed,EFFECT_0,SPELL_AURA_DUMMY,AURA_EFFECT_HANDLE_REAL);`

037: `    }`

038: `};`

039: `class aura_reborn_wd133_beast : public AuraScript`

040: `{`

041: `    PrepareAuraScript(aura_reborn_wd133_beast);`

042: `    WD133::DeferredDamage payments;bool paying=false;`

043: `    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9003946}); }`

044: `    void Amount(AuraEffect const*,int32& amount,bool& recalc) { amount=-1;recalc=false; }`

045: `    void Absorb(AuraEffect*,DamageInfo& damage,uint32& absorb)`

046: `    {`

047: `        absorb=0;`

048: `        if(paying || damage.GetDamageType()==DOT || !(damage.GetSchoolMask()&SPELL_SCHOOL_MASK_NORMAL)) return;`

049: `        // Multiple doctors must not multiply the deferred fraction. Lowest GUID wins while overlapping.`

050: `        for(AuraEffect const* a:GetTarget()->GetAuraEffectsByType(SPELL_AURA_SCHOOL_ABSORB))`

051: `            if(a->GetId()==9003943 && a->GetCasterGUID()<GetCasterGUID()) return;`

052: `        absorb=uint64(damage.GetDamage())*15/100;`

053: `    }`

054: `    void Stored(AuraEffect*,DamageInfo&,uint32& absorb)`

055: `    {`

056: `        payments.Store(absorb);`

057: `    }`

058: `    void Pay(uint64 amount)`

059: `    {`

060: `        Unit* u=GetTarget();if(!amount || !u->IsInWorld() || !u->IsAlive()) return;`

061: `        paying=true;`

062: `        uint32 hit=uint32(std::min<uint64>(amount,UINT32_MAX));`

063: `        SpellNonMeleeDamage log(u,u,sSpellMgr->GetSpellInfo(9003946),SPELL_SCHOOL_MASK_NORMAL);log.damage=hit;`

064: `        u->SendSpellNonMeleeDamageLog(&log);`

065: `        Unit::DealDamage(u,u,hit,nullptr,DOT,SPELL_SCHOOL_MASK_NORMAL,sSpellMgr->GetSpellInfo(9003946),false);`

066: `        paying=false;`

067: `    }`

068: `    void Tick(AuraEffect const*)`

069: `    {`

070: `        PreventDefaultAction();Pay(payments.Next());`

071: `    }`

072: `    void Removed(AuraEffect const*,AuraEffectHandleModes)`

073: `    {`

074: `        Pay(payments.Drain());`

075: `    }`

076: `    void Register() override`

077: `    {`

078: `        DoEffectCalcAmount += AuraEffectCalcAmountFn(aura_reborn_wd133_beast::Amount,EFFECT_0,SPELL_AURA_SCHOOL_ABSORB);`

079: `        OnEffectAbsorb += AuraEffectAbsorbFn(aura_reborn_wd133_beast::Absorb,EFFECT_0);`

080: `        AfterEffectAbsorb += AuraEffectAbsorbFn(aura_reborn_wd133_beast::Stored,EFFECT_0);`

081: `        OnEffectPeriodic += AuraEffectPeriodicFn(aura_reborn_wd133_beast::Tick,EFFECT_1,SPELL_AURA_PERIODIC_DUMMY);`

082: `        AfterEffectRemove += AuraEffectRemoveFn(aura_reborn_wd133_beast::Removed,EFFECT_0,SPELL_AURA_SCHOOL_ABSORB,AURA_EFFECT_HANDLE_REAL);`

083: `    }`

084: `};`

085: `class wd133_crystal_heal : public UnitScript`

086: `{`

087: `public:`

088: `    wd133_crystal_heal():UnitScript("wd133_crystal_heal",true,{UNITHOOK_ON_HEAL}) { }`

089: `    void OnHeal(Unit*,Unit* u,uint32& gain) override`

090: `    {`

091: `        if(!u || !u->IsAlive() || !u->IsInWorld() || gain<5) return;`

092: `        ObjectGuid selected;`

093: `        for(AuraEffect const* a:u->GetAuraEffectsByType(SPELL_AURA_DUMMY))`

094: `            if(a->GetId()==9003944 && (selected.IsEmpty() || a->GetCasterGUID()<selected)) selected=a->GetCasterGUID();`

095: `        if(selected.IsEmpty()) return;`

096: `        Unit* p=ObjectAccessor::GetUnit(*u,selected);`

097: `        if(!IsDoctor(p?p->ToPlayer():nullptr) || !p->IsAlive() || !p->HasAura(9003944,p->GetGUID()) ||`

098: `           !p->IsWithinDistInMap(u,40.0f) || !p->IsFriendlyTo(u) || (p!=u && !p->IsInRaidWith(u))) return;`

099: `        uint64 value=gain/5;`

100: `        if(AuraEffect* a=u->GetAuraEffect(9003945,EFFECT_0,selected)) value+=uint32(std::max(0,a->GetAmount()));`

101: `        int32 amount=int32(std::min<uint64>(std::min<uint64>(value,u->GetMaxHealth()),INT32_MAX));`

102: `        p->CastCustomSpell(u,9003945,&amount,nullptr,nullptr,true);`

103: `    }`

104: `};`

## 配方、数据与保存

Brewing131按新9003940选择first=鱼油、partner=蛙骨，并清其他待用魔精；BrewingFoundation在发射时捕获9003941，移除待用Aura，命中时每个友方获得相同快照。Normalize手动准备时同时取消第三种待用效果；旧3933/3934路径保持。
Allocation新增索引99/100/101，原Shift映射bit111/112/113；C++/Lua/SQL最大114位，AEIdCount102。TESpent三项均加1；水晶前置23不计自身。服务器节点查询返回实际已花TE而不是固定写8/23，客户端草稿与服务器已保存仍分离。
两侧DBC单独核对现场WD132A字节再追加7条。新行74列die0；鱼骨效果38+136，base1/10；两基底effect65/raid、radius23、duration1、manaPercent30；野兽隐藏69+226、每秒tick；水晶隐藏69、duration28。图标各自追加，3个主动进书页，隐藏不进书页。SQL所有权守卫先于写入，百分比治疗零固定法强系数。

## 测试代码与实际排错

scenario133.lua真实加载Allocation，验证鱼骨前置和16级、野兽OR前置、水晶23点/不能自举、TE预算、错专精、114位上界、四limb往返与真实M.Save。test_mysql133.py在33533独立实例读回@@datadir后才装测试schema，153项覆盖累计节点、预算、保存/重装/不免费退点及World冲突前不写。结束关闭隔离实例，不读写生产库。
deferred_damage_test.cpp直接包含本包实际头文件，10000组检查每格商余数、五格总数，另测连续写入与跨周期付款、Drain不可重复、大数累计。测试程序仅离线检查，不是worldserver，交付ZIP不带它的EXE/OBJ。
首次生成在宽泛if(AERank(mask,98)匹配到两处时断言阻断，改为精确等级校验位置；首次/Zs发现SpellNonMeleeDamage构造参数需要SpellInfo指针，按本核心API修正。复核发现节点查询te值应为实际投入、SQL预算需追加新三点、百分比治疗需避免固定法强默认系数，均在本候选交付前修正并重新验证。没有给用户安装过这些中间输出。
原始已验收ZIP及现场文件未改。完整源码变更见checks/candidate.diff；验证日志与manifest记录最终候选，离线通过不能冒充实机。确认成功后才按release-tested-reborn-features流程commit/tag/Release。
