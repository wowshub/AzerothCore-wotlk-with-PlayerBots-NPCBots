# WD161A审查（同作者自审，非独立AI评审）

读取AGENTS/ruleAscend/refResource/协作说明/交叉规范及永久skillsAscend；应用audit-and-port-upstream-features、plan-coa-class-migration、coordinate-ai-team-parallel-development、trace-and-port-coa-spell-resources。旧WD43 README与Skill限定实测、WD51已验收方法分别读取。

上游在线固定f6e30667591521c9f4f199a294b7cc4b15573c71，实际5文件及哈希见sources.json。Events::Check/Proc的Berserking只取有效周期伤害并WardBuff；Summons::WardBuff含Serpent/Mass/Viper。最新CursedField通过召唤的范围field；本地保留已验收WD43精确原生暴击判定，不把社区已关闭4109/5648当成本地全部专项通过。Issue7232仍开放，指Wildcard280915，不能扩大为本地706542已失败或已解决。旧222/247崩溃背景与7048友方Ward来源已检索，当前本地无新核心成员或ABI改动。

|来源→受益|条件与公式|撤销/展示|实现与证据|
|---|---|---|---|
|狂暴→四组蛇|自己的存活同图同相位召唤GUID；本人周期有效伤害，25%几率；3%*1..3=3/6/9%，15秒|真实3533层数；消失/移除天赋时按owner清|WD51 Proc/Remove→WD161::Wards/Haste；基本/群蛇/妖火GUID集合+Viper；fixture按entry/owner/map/phase去重；实际AI原有计时不再乘第二次|
|狂暴→蛇类前置|30级8此前TE，保存当前暗影1TE；可做Handler/Viper OR前置，并计入后续23TE|草稿不生效，取消不能免费退款|C++/SQL/Lua相同门槛；真实SQL和C++AEValid/SpecValid/Lua+替代路径通过|
|诅咒雕像→敌人|58级24此前AE、1AE；15码LOS15秒，16%基础法力60秒CD；伤害/治疗暴击仅原生路径|9003431玩家可见短减益，按施法者GUID；每秒刷新2200ms，离开/死亡/到期/驱散/召唤撤销清；父是否活着由AI判断|保留WD41/43实现与Unit/Spell/Aura精确白名单；现代Apply/ClearEffects清自己的Cursed槽而不清其他雕像；真实DB→C++→Lua展示通过；实际PvP/多人/弹道边界待测|
|新存档→旧购买|只modern&&loaded接管；旧162位置不变、bit67保持禁用，未注册现代的旧角色不改|不送点、不清账本、不能免费减少已存档等级|新164槽180bit45hex；自审修正Lua旧巫毒残差白名单及details.limit遗漏；累计真实Lua确认0/1中英文保存/草稿|

视觉：沿用WD43/44模型900201→1101130和Visual887961/887962；WD51狂暴原Icon273215，无新独立粒子承诺。基础来源WD43A资源依赖88项记录仍为历史证据，不能当成本批现场渲染。WD160双端10表/模型/声音/贴图累计字节不变，343当前不变量；安装依赖正式156D的旧资源，不交小XA整包替换。

生命周期：同owner才授予/撤销；重复恢复不重学不刷新已有Aura；撤销Cursed只清900201，不误清暗影/妖术/墓刻；取消狂暴清自己的四组蛇的3533。换方案和洗点沿现有AEApply，数据库失败ClearEffects对现代节点撤销；旧legacy不调用桥。死亡/换图/下线沿原召唤AI和logout/map清理，实际游戏仍待测。

实际验证：556隔离SQL（私有datadir/33562，finally停止）、累计Lua5.1、6个/Zs、actual161.cpp真实函数摘取与模拟对象、actual160.cpp累计生产函数+新门槛、roundtrip161.py真实数据库→实际生成C++→实际Lua。343资源和节点映射检查。最初本地TCP因沙箱10013失败，授权私有测试后通过；夹具资源前提/索引49/Tooltip15秒更正如实记录，不伪装成线上崩溃。

未测：真实引擎的召唤/概率/攻击频率/全等级/多人/PvP/DBM taint；未构建worldserver、未生产安装。所有候选依赖157—160仍未用户确认。本批只是全部当前展示节点已有现代映射，不是整职业机制验收完成。
