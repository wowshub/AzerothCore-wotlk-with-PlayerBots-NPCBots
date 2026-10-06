# WD129A 开发复盘与教学

先把调酒师理解为“两格材料架”：本次血蓟只是增加一种可放的材料，架子容量仍由调酒师决定。药瓶离手时把材料记下来，不能飞到一半再读取大锅，否则途中换料会改写已发出的药水。

森金像两张限时加速券：只有成功投掷或瓶中之灵发两张券；佳酿用一张，其他法术不能用；佳酿被中断时不能扣券。这里用核心已有消费机制，避免自己减一次、核心再减一次。

## 七个记录为什么只算两个技能

9003915是用户准备的血蓟；3916是区域增益；3917/3918是投掷/泼洒给友方的状态；3919是伤害后实际治疗。9003920是天赋授予的森金被动；3921是有两次次数的限时加速。隐藏记录不能当作额外已开发技能数量，也不应混进可学技能书。

## 保存的完整链

AEIds新增6021/6014，对应index91/92、bit103/104。C++数组常量93、AEValid右移105、AESave最大2^105-1、Lua四limb与WD8回包105、SQL Decimal最大值和节点写入同步。原bit0–102及购买修订号不动。只增数组却不改入口会重演WD128A“等待服务器确认”。

Characters过程仍先校验角色、账号、revision、方案、点数和旧购买，再保存；新节点需大锅及旧8基础TE，新点不能给自己凑门槛。隔离MySQL使用全新临时datadir和33529端口，脚本核对端口及datadir再执行，结束关闭；这与操作生产角色库完全分开。

## 新C++原文与解释

下面是本次新增inc的实际交付内容：

```cpp
// WD129: Bloodthistle proc and Sen'jin charge source. Included after BrewingFoundation.
namespace WD129A
{
struct LeechClock : DataMap::Base
{
    std::chrono::steady_clock::time_point next{};
};
}
class aura_reborn_wd129_thistle : public AuraScript
{
    PrepareAuraScript(aura_reborn_wd129_thistle);
    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9003917,9003918,9003919}); }
    bool Check(ProcEventInfo& event)
    {
        Unit* owner=GetTarget();Unit* enemy=event.GetActionTarget();
        if(!owner || !owner->IsAlive() || event.GetActor()!=owner || !enemy || enemy==owner ||
           owner->IsFriendlyTo(enemy) || !event.GetDamageInfo() || !event.GetDamageInfo()->GetDamage()) return false;
        if(event.GetSpellInfo() && event.GetSpellInfo()->Id==9003919) return false;
        // One recipient-wide 500ms clock covers Toss/Splash and multiple doctors.
        auto* state=owner->CustomData.GetDefault<WD129A::LeechClock>("Reborn.WD129.Leech");
        if(std::chrono::steady_clock::now()<state->next) return false;
        int32 amount=GetEffect(EFFECT_0)->GetAmount();
        for(AuraEffect const* effect:owner->GetAuraEffectsByType(SPELL_AURA_DUMMY))
            if((effect->GetId()==9003917 || effect->GetId()==9003918) && effect->GetAmount()>amount) return false;
        return amount>0;
    }
    void Proc(ProcEventInfo& event)
    {
        PreventDefaultAction();
        Unit* owner=GetTarget();
        auto* state=owner->CustomData.GetDefault<WD129A::LeechClock>("Reborn.WD129.Leech");
        auto const now=std::chrono::steady_clock::now();
        if(now<state->next) return;
        int32 heal=int32(std::min<uint64>(INT32_MAX,uint64(event.GetDamageInfo()->GetDamage())*uint32(std::max(0,GetEffect(EFFECT_0)->GetAmount()))/100));
        if(!heal) return;
        state->next=now+std::chrono::milliseconds(500); // reserve before nested heal/proc calls
        Unit* source=GetCaster();
        if(!source || !source->IsInMap(owner)) source=owner;
        source->CastCustomSpell(owner,9003919,&heal,nullptr,nullptr,true);
    }
    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_reborn_wd129_thistle::Check);
        OnProc += AuraProcFn(aura_reborn_wd129_thistle::Proc);
    }
};
class wd129_senjin_events : public AllSpellScript
{
public:
    wd129_senjin_events():AllSpellScript("wd129_senjin_events",{ALLSPELLHOOK_ON_CAST}) { }
    void OnSpellCast(Spell* spell,Unit* caster,SpellInfo const* info,bool) override
    {
        Player* p=caster?caster->ToPlayer():nullptr;
        if(!spell || spell->IsTriggered() || !info || !IsDoctor(p) || !p->IsAlive() ||
           !p->HasSpell(9003920) || !p->HasAura(9003920,p->GetGUID())) return;
        if(!WD120A::IsToss(info->Id) && !(info->Id>=9003460 && info->Id<=9003467)) return;
        // Successful cast only; native charged spellmod consumes once per Brew and restores on cancel.
        p->CastSpell(p,9003921,true);
        if(Aura* buff=p->GetAura(9003921,p->GetGUID())) buff->SetCharges(2);
    }
};
```

- `LeechClock` 放在每个单位的 CustomData 中：不同玩家互不干扰，同一单位来自多种药水的吸血共用500ms；steady_clock不会因系统时钟校正倒退。
- `Validate` 要求依赖法术存在，缺数据时不能加载出半截效果。`Check` 首先只认光环受益者本人造成的真实非零伤害，排除友方、自伤、治疗事件及吸血治疗。
- 遍历该单位的Dummy光环，是为了较弱血蓟不抢先触发。相同强度由共享时钟防止重复；不是把两名巫医的5%叠成10%。
- `Proc` 先屏蔽默认动作，再用实际伤害×百分比算基础治疗；用uint64防乘法溢出，限制INT32_MAX后传给自定义治疗。产生至少1点基础治疗才占用时钟。
- 先占用时钟再施放隐藏治疗，是为了嵌套事件不能重复进入。优先使用原施法者，找不到或不在同地图时以受益者为治疗来源；该归属退化只用于光环尚在但原施法者不可用的场景，需要实机观察。
- `OnProc` 与 `DoCheckProc` 各注册一次；World绑定决定哪些私有光环走这段逻辑。没有World绑定就只有DBC状态而没有吸血治疗。
- `wd129_senjin_events` 监听本地核心成功施放的末尾事件。`IsTriggered` 排除隐藏触发；HasSpell与HasAura同时要求正式激活拥有权；白名单仅投掷七级或瓶中之灵八级。
- `CastSpell(...true)` 发限时券，`SetCharges(2)` 刷新为两张，不叠加到四张。原生modifier仅op10、无procflags；Player::RemoveSpellMods在成功finish只DropCharge一次，失败finish调用RestoreSpellMods。因此这里不手动再扣券。

## 精确白名单与DBC

地根草增加血蓟3916/3917/3918的op8匹配；3915准备本身及3919治疗不匹配，避免百分比重复乘。森金3921只匹配WD19A::IsBrew且op10；SpellInfo保留不匹配就拒绝的路径，空family mask不能变成全职业加速。

新DBC用本地受支持模板，die=0直接写8、5和-20，不再盲目加减1。官方Aura354换为本地Dummy；隐藏治疗额外系数为0，但治疗百分比与目标承受治疗仍按核心规则处理。SpellIcon两个端的行号可能不同，字符串指向同一私有图标，不能交换表。

## 测试如何避免只看到绿灯

173组DBC/Lua/入口检查分别证明旧记录未动、字符串偏移有效、书页/图标引用存在、旧UI回归、105位边界；真实Lua Save确实发出含bit103/104的十进制字符串，再对照源码入口。60项隔离MySQL证明实际存储过程保存、重复执行和冲突拒绝。/Zs检查三个实际编译单元，只能说明语法/符号通过，不能代替链接或服务启动。

独立FIFO模型49,152步验证四种材料在1/2容量下的序列约束；不等于真实角色Aura生命周期通过。真正测试仍需按README做两次佳酿、中断、血蓟吸血频率、重登和切方案。候选结果不能提前晋升永久Skill。

## 本次发现并处理的检查问题

最初解包目录DBC不匹配，改为读取实际运行MPQ而不是回退用户数据；森金共享图标像素冲突，改用节点私有路径；两端SpellIcon最大行号不同，验证按各自表检查；MSVC响应文件原为UTF16，先修正工具的编码和调用引号后才得到实际/Zs结果。World系数归属检查增加NULL分支并在首次写入前拒绝，新增隔离用例后重跑通过。
