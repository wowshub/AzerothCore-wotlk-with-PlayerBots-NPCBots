# WD120A 研发与证据

基线：WD119A累计源码/独立双端DBC + WD119B三个Lua + WD119C Player.cpp、Spell中断标志和数值提示。保留用户之前已通过项目，WD119A/C控制回归与WD120A均仍待实测。

读取项目AGENTS、ruleAscend、refResource、永久skills目录，应用plan-coa-class-migration、trace-and-port-coa-spell-resources、build-wotlk-three-build-projection、stabilize-spelldraft-client-ui。未启动代理、未编译、未安装。

上游：https://github.com/jealous-sound/azerothcore-wotlk-coa ，实际在线commit d7620151fa4267ab90c7e0554b32628017df241a。本批已下载Brewing、Abilities、Completion、Coefficients、ScalingBase及等级缩放数据、相关Issues/PR和World SQL。节点取本地官方20260925来源Data，Spell取只读patch-T.MPQ。Issue6294提示蘑菇投掷/泼洒子效果混用；本批精确映射PotionShrooms802973，不使用SplashShrooms803273。

研究纠正：早期检查点把Spell第232字段182误称Scaling字段。核对上游DBCStructure后确认它是SpellDescriptionVariableID；该表不在patch-T中。实际等级倍率来源是最新AscensionScalingBase.cpp/Data.h中的802703条目与二次公式。没有凭182去臆造缩放表。

实现：新增9003864/65/66/67及9003870–76；仅3864/65与投掷7级进入酿造SkillLine9005。84–86三个高位对应4005/12645/12646，最大mask扩87位。C++/Lua/SQL保存、重建、不得免费撤销、预算与分支规则同步，旧位保持不变。RequiredIDs保留4005或29744的替代路径；三个免费节点都从AE/TE预算及GM预算回收检查中排除。

配料使用原生周期触发Aura，施法者自身保留准备状态；当前仅一种配料，无需提前引入全套多配料状态机。投掷在OnCast快照配料、命中后按此快照施加HoT，防止弹道飞行中读到新的配料状态。生命治疗在OnEffectLaunchTarget增补来源系数；Pulse先按角色等级缩放。World禁用对应8项原生法强加成；HoT保留其原生等级成长/原生系数路径，与上游未覆盖该子法术的做法一致。

兼容差异：清理CoA扩展属性、族掩码、外部ID；15秒类别冷却变为当前等级技能的15秒原生冷却。本批只有投掷一种药水，后续泼洒共冷却需按来源再接入。使用已有洛阿佳酿视觉作为兼容外观，没有声明新大锅模型已经移植。通用治疗候选模型restoration_impact_base_blue缺少01.skin，因此没有选用；保留拒绝记录，未修改这个既有模型。

失败及处理：最初扫描对每个字符串复制整段大池导致耗时，改为按NUL结束位置取值；SQL中rank是MySQL8保留字，实际执行失败后补反引号。首次扩大SQL白名单时发现免费节点被GM预算检查计入AE，已修正，未交付旧版本。新数值测试最初用了错误方案revision和行数，服务器回包被正确拒绝，已修正测试夹具。一次累计GM配点夹具断言返回非预期，后续全新临时库复测通过，未定位原因，不声称已修复该历史路径。Register阶段不得调用GetSpellInfo（验证阶段没有Spell实例），改为无条件注册、运行时精确ID分流。

验证证据在checks；SQL操作只针对验证过@@datadir的临时实例33500。生产World只读检查私有ID与表结构。未运行游戏/用户编译；候选状态不能升级为验收。
