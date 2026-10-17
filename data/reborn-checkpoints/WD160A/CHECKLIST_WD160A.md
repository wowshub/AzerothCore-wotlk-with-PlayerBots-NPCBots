# WD160A完整移植审查

作者/审查者Codex，同一作者自审，没有独立AI评审。独立工作目录D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261016\codexwork_WD160A。项目协作说明登记160A及模型/DragonUI/Player范围；不改Claude组件和运行目录。

读取AGENTS/rule/refResource/协作规则及audit-and-port-upstream-features、coordinate-ai-team-parallel-development、plan-coa-class-migration、trace-and-port-coa-spell-resources、repair-multiclass-summon-lifecycle及evidence-lineage。实际输入/输出SHA见input-output及cumulative-source-inputs；双端表见resource-report，资源原MPQ与哈希见assets.json。

最新社区main在线固定f6e30667591521c9f4f199a294b7cc4b15573c71，2026-10-16。七份实际代码+来源hash见upstream/sources.json。5648合并0a8553e27664ec71cebb5c94c9c0d5b184f16c82，7048合并fb02600e85eebfb933be0f46a92712872d63c561；4101/4103/453已关闭，详细评论/补丁/场景见details.json。最新源码Fools分支仍只见Float伤害字段，未见SetBaseWeaponDamage/目标生命复制，不能仅凭PR合并认定已修；本地明确补齐并验证原生武器数组。

官方依据独立于社区：20260930客户端Spell707329/712373/712374/712415/681007。记录20秒、45秒/120秒、14%/17%法力、50%+ranged rating、216+.15RAP、无GCD、20码Fool。社区NPC SQL51105→Display411030→Model411030→ZulDrak蛇雕像M2，模型源MPQ实际读回；没有用普通蛇模型冒充。原CDF空格皮肤覆盖改为空串，由M2内嵌贴图提供外观。原712374带历史混合效果，未照搬未经证实的100%魔法免疫/旧触发链；本地存在提示为零数值Aura。

## 获取及联动契约

两节点各1TE、当前已保存激活暗影方案、23此前TE。Viper与Handler同组783222互斥；当前现代前置Eye4572，旧Berserking29978尚不在现代布局，不假装路线可保存。Fool前置Eye/Edge/Dambala任一。Viper主动仅在已有Call时授予；不反复proc学习，不动主宠物。162槽178bits45hex，hash fdd5ef377c3ef9ab57332b55dd791e7fbcdade00405f98662d8cc6174fad14c1，旧160槽逐项原位。

|来源|条件/GUID|受益|公式/单位|撤销/生命周期|实际入口|展示|证据|
|---|---|---|---|---|---|---|---|
|毒蛇天赋|当前方案自有marker+Call|Call按钮/技能书/DragonUI|4182替换4080，持久身份仍4080|洗点/换方案/失去Call|Bridge/Replacement/Player canonical|真实技能/安全守卫列表|Lua/真实方法/Zs；游戏待测|
|毒蛇召唤|合法地面，模板存在，冷却可用|自有NPC900255|1只20秒；ApplySpellMod3160持续一次；新召唤成功后清旧|死/到期/失Call/换图/退出/洗点|summon::Hit、Viper/CustomData|20秒真Timer存在Buff4184|源审/归属Timer摘取，游戏待测|
|毒蛇攻击|自己存活且有Call/Talent；敌人30码/同相位/LOS/非易断CC|原目标|1000ms基准，一次Update最多一击|条件撤销|viper::AI::UpdateAI，继承Enemy|3161原生攻击/头顶伤害|实际摘取计时/不补发|
|毒蛇冲击|每次实际发射，自己rating|原目标|50%+CR_CRIT_RANGED bonus，0..100%；216+.15RAP，Fire|瞬时无持续减益|Chance/blast::Damage；bonus表全0|独立命中视觉/战斗记录|实际抽取/系数/DBC/SQL|
|巫毒火/打击者|Viper自有GUID；原已保存火天赋|周围最多3敌人|原20/40%+Striker10百分点|原条件|WD150::Shot新增entry/ownership|既有火伤视觉|源码链/现有回归，真实组合待测|
|残余能量|自己3532实际生效；自己的Viper|守卫攻击进度|既有3533原生层数最多9%，timer按step放大一次|父天赋移除时撤销WardHaste|WD51 check/proc/remove+ViperAI|真实守卫急速Aura，读实际频率|摘取9%计时/原code连通；游戏待测|
|真神|自有True天赋，毒蛇召唤成功|本人Ready|一次召唤Gain一次，不按伤害递归|原消费|summon::Hit→WD149::Gain|原真实Ready|源链/Zs，游戏待测|
|Viper冷却|成功普通施放|Viper/Call|45000ms；Call用秒精度向上取整共享；已有Call计时阻止Viper|自然结束|native cooldown+SharedCooldown Check|原生计时/只读诊断|原生API已审；整机时间待测|
|愚者召唤|原敌合法/20码/LOS，自己的已学Fool|自有NPC900256|20秒；目标当前/最大HP、真实base武器范围、攻击时间|目标死/友好/离图/主人死/洗点/换图/退出|SetGUID/AI/CustomData/Clear|原生Clone247与目标外观、真实攻击|实际SetGUID+native武器arraygetter/setter、state边界|
|愚者复制|原目标普通施法；只原生伤害、无script；40码/LOS/同相位/owner状态有效|原施法者|分身triggered cast原SpellID，无资源/自定义连锁|不合法即不复制|AllSpellScriptOnCast→CanMirrorSpell→CastSpell|真实战斗法术与copy计数|filter实际执行；完整echo引擎未测|
|159前置|已保存的新节点|Gift/Price|三端OR路线统一，仍预算/互斥/前置限制|退款使用既有收费|Lua/C++/SQL|实际保存/提示1/1|545SQL及真实DB-C++-Lua|

## 视觉/数据闭合

Viper summon1920、historicalProc2241、Blast2242、Fool1956逐Kit/Attach/EffectName/M2/SKIN/ANIM/BLP/Sound；私有888164–167/824650起/813650起/910206–207。Viper独立Display/Model891160，实际模型Spells/RebornWD160/ViperWard.m2。Spell→CDF/MD及完整模型依赖分别验证；295资源检查、双端各10表旧行和旧字符串前缀不变。2241核对留存但不把其Ward粒子误绑玩家存在Buff；Fool主体动态复制目标既有模型，不全量替换人物模型。施法/弹道/命中/声音保留官方链，真实渲染未测；瞬时火伤不伪造敌方持续DEBUFF。

## 自审/测试/缺口

- source Call内部trigger572899与学习channel681222不同，本地只替换学习对应9004080，沿5648修复点。
- API GetExplTargetDest返回WorldLocation，本地按当前头文件适配，不照搬其他版本SpellDestination。
- 上游Viper/Fool为NoSlot，本地各自GUID组不挤普通Ward/Idol/Effigy/Mimic；DragonUI RitualWard排除两个独立召唤并隐藏被替换Call。
- 当前上游712374混合效果未证明免疫，不编造免疫收益；ViperProc只用于50%和外观审计。
- 7048 PlayerControlled/faction/PvP随主人同步；友方/跨阵营实际IsValidAttackTarget整机未测，不继承社区场景验收。
- new spawn成功后才Clear旧组；无持久裸指针，跨触发使用GUID重新查找；CalcAmount无新增，没有AuraApplication空指针路径。
- 初始资源Attach中存在合法Effect0，明确保留0并跳过闭包解引用；不造无效Effect行。测试夹具缺基础常量/类型问题已修，生产未触碰。
- 545隔离MySQL，实际Lua5.1保存/双语/互斥/预算/路径，六文件/Zs，生产方法摘取与mock对象执行，真实SQL→Build.Hex→实际Lua已保存提示5235，295资源检查通过；未worldserver构建/完整引擎/真实玩法。
- 存档和程序需178bits/45hex/hash配套；SharedCooldown本地秒精度最多约1秒上取整。Fool复制过滤有意比“所有法术”窄，不称完全复刻复杂脚本；实际伤害/命中/免疫和多人生命周期待测。
- 现代显示节点仍有旧路径29978Berserking和5113CursedEffigy，research/unmapped-display-nodes.json明确留存；需单独盘点，不标全职业完成。

结论：WD157—160累计候选，待用户编译部署及实机。无push/生产SQL/运行目录改动。安装/配套回滚见README。
