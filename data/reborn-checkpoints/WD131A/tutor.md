# WD131A：双魔精从源码到验证

把配料想成药水台上正在使用的两只瓶子，魔精是临时配方卡。施放魔精先换瓶子，再把配方卡放到台上；药水出手时把这张卡复制到本次药水并收走台上的卡。这样泼洒每个目标都按同一张卡处理，之后换瓶子也不能改掉已经飞出去的药水。

1. 先核对官方文字与真实数据。两个旧Effect164的触发ID与说明冲突，因此采用说明和最新社区Mix代码配对；所有新SpellID与实际双端表做不存在断言。看懂duration索引再写5秒/10秒，而不是把索引数字当秒数。
2. Ingredients增加mojoPair和mixing。前者记固定双配料来自哪项技能，后者只在原子切换期间暂时阻止普通FIFO逻辑，否则准备第一个配料时就可能把第二个挤掉。它属于每个Player的CustomData，不是全服共用变量。
3. Normalize先处理手动换料，再清不存在/重复的配料，最后按容量移除最旧项。魔精维持固定双配料；普通状态仍按调酒师决定1或2。HasSpell核验来源撤销后不能继续享受特殊容量。
4. 新Script的Check检查本职业、主动技能和两个配料所有权。Mix在AfterCast成功路径执行：清旧配料，施放两种合法准备，写顺序，退出mixing，再调用统一整理。逐一清两条7级药水冷却，调用原生RemoveSpellCooldown发送客户端通知；不把DBC基础冷却改为0。
5. 药水OnCast读取一次性待用Aura到成员_mojo，并撤销待用Aura。成员变量属于这一次SpellScript，AfterHit每个友方都使用同一值。普通施法失败未进入OnCast不会消耗；已经出手后目标失效仍消耗，不能借失败命中复制配方卡。
6. 原生Aura133负责最大生命百分比，61负责体型，229负责范围伤害承受；直接写die0/base10、15、-30。最大生命改变不是额外治疗，负30是减伤不是30%概率闪避；单体伤害不能受益。
7. 新节点追加在旧96个之后，位108/109。C++的AEIdCount、AEValid、保存十进制上限、拥有权同步，Lua index/maximum/MaskFits/预算，SQL过程与schema白名单都必须同改。不能只改显示，重演WD128A保存入口仍100位的错误。
8. Characters SQL先拒绝未知旧记录，再升级允许节点；实际save过程仍核验账号、revision、槽、预算、前置和不可免费退点。World SQL先检查脚本拥有权，再写两个绑定，避免覆盖别的模块。

## 实际新增脚本逐行读

以下行号来自交付的RebornWitchDoctorBrewing131.inc。Validate保证依赖记录存在；Check返回明确施法资格错误；Mix在成功施放后改状态；Register只挂两个明确钩子。

01: `// WD131: official 705851 / 500472 descriptions override stale donor ingredient trigger IDs.`

02: `class spell_reborn_wd131_mojo : public SpellScript`

03: `{`

04: `    PrepareSpellScript(spell_reborn_wd131_mojo);`

05: `    bool Validate(SpellInfo const*) override { return ValidateSpellInfo({9003933,9003934,9003935,9003936,9003865,9003905,9003915}); }`

06: `    SpellCastResult Check()`

07: `    {`

08: `        Player* p=GetCaster()->ToPlayer();`

09: `        uint32 partner=GetSpellInfo()->Id==9003933?9003905:9003915;`

10: `        return IsDoctor(p) && p->HasSpell(GetSpellInfo()->Id) && p->HasSpell(9003865) && p->HasSpell(partner)`

11: `            ?SPELL_CAST_OK:SPELL_FAILED_CASTER_AURASTATE;`

12: `    }`

13: `    void Mix()`

14: `    {`

15: `        Player* p=GetCaster()->ToPlayer(); if(!IsDoctor(p)) return;`

16: `        uint32 id=GetSpellInfo()->Id,partner=id==9003933?9003905:9003915;`

17: `        auto* state=p->CustomData.GetDefault<WD128A::Ingredients>("Reborn.WD128.Ingredients");`

18: `        state->mixing=true;state->mojoPair=id;`

19: `        p->RemoveAurasDueToSpell(id==9003933?9003934:9003933);`

20: `        for(uint32 prep:{9003865u,9003901u,9003905u,9003915u}) p->RemoveAurasDueToSpell(prep,p->GetGUID());`

21: `        p->CastSpell(p,9003865,true);p->CastSpell(p,partner,true);`

22: `        state->order={9003865,partner};state->mixing=false;`

23: `        WD128A::Normalize(p);`

24: `        for(uint32 first:{9003870u,9003890u})`

25: `            for(uint32 rank=0;rank<7;++rank) if(p->GetSpellCooldownDelay(first+rank)) p->RemoveSpellCooldown(first+rank,true);`

26: `    }`

27: `    void Register() override`

28: `    {`

29: `        OnCheckCast += SpellCheckCastFn(spell_reborn_wd131_mojo::Check);`

30: `        AfterCast += SpellCastFn(spell_reborn_wd131_mojo::Mix);`

31: `    }`

32: `};`

## 修改位置与测试代码

RebornWitchDoctorBrewingNumbers.h的WD128A::Normalize保存旧FIFO实现，只增临时配方状态；RebornWitchDoctorBrewingFoundation.inc的Snapshot和IngredientEffect分别负责发射快照和目标应用。Allocation.inc和TalentPolicy保证保存技能才可拥有；Data.lua保留WD130B图标修正。

checks/scenario131.lua真实加载交付Allocation.lua，构造合法8基础TE，加对应配料和位108/109，然后反向去掉配料/大锅、改变专精/等级/预算，必须被拒绝；逐个旧位追加移除新位确认旧值不变。checks/actual_save.log使用真实M.Save并捕获Request验证十进制请求：324677068011919168600110427799552与659178370147143201920052986118144，避免Lua浮点高位丢失。

tools/test_mysql131.py启动独立mysql目录和端口33531，先读@@datadir确认为本次目录，再装历史schema与新过程，测试保存/重复/拒绝/升级保留/脚本冲突，finally关闭该独立实例。不能把这个脚本改成生产地址。tools/wd131_verify.py逐行核对DBC旧记录、字符串偏移、图标内部路径及Lua语法/真实预算逻辑。

首次SQL生成匹配字符串过短导致断言阻止输出，改为精确匹配r93<MOD。首次直接调用cl未加载VS环境，缺cinttypes；通过vcvars64初始化后两个实际单元/Zs完成。它们是构建过程问题，不是用户要安装的失败版本。

实操：先读覆盖说明完成编译部署，再按“建议实机测试”记录技能名、目标、配料图标、待用Aura、命中Aura、时间与对照伤害。静态或模拟通过不代表两技能实机通过；用户明确验收后才更新永久Skill/同名Tutor并commit/tag/Release。
