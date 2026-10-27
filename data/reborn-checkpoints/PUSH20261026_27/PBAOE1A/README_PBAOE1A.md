# PBAOE1A：playerbot 群伤取证与 MultiBot 提示修复

状态：候选。低输出原因尚未定案，**本包不宣称已经提高 DPS**。按交接“现有日志不足先加最小诊断”执行；不改 NPCBot、清本、巫医数值、输出阈值和真人托管行为。

## 安装与开启

1. 基于当前累计源码：主仓 43eb71d68c8a856e4e28c2f465b14fc682aaa9cc，实际 Playerbots 子仓 b0f62dc67aebd5899e4eb44adb73449b0ffc9481，含本地累计修改，逐文件输入哈希见 checks/inputs.json。先备份，覆盖 01 的 modules 到源码根目录，随后编译（中间不要插其它编译）。Engine.h 有改动，重编所有依赖单元及 AiFactory.cpp；可用项目既有“编译前运行_更新已修改文件时间.bat”处理旧对象时间问题。实际完整编译/链接由用户执行，本轮未运行。
2. 覆盖 02 的 Interface 到客户端根目录，重载插件；只修 MultiBot zhCN 冰霜提示的一处文案。
3. 默认没有诊断输出。在运行 worldserver.conf 添加 `Reborn.PlayerbotAoeDiagnostic = 1`，重启服务器加载。未整份提供或覆盖运行配置。
4. 当前实际配置 Logger.playerbots 和 Appender.Playerbots 级别都是 5（ERROR）；诊断为 INFO，测试时两者级别均需改为 3。保留其它字段，例如当前两行改为：

```ini
Reborn.PlayerbotAoeDiagnostic = 1
Appender.Playerbots=2,3,0,Playerbots.log,w
Logger.playerbots=3,Console Playerbots
```

已有同名项请修改，勿重复添加。测试后把诊断改 0，并恢复原两项日志级别 5。INFO 会包含其它 playerbots 信息；短时取证即可。日志位于服务端 logs/Playerbots.log；当前 w 模式可能重启清空日志，请重启前保存上一轮记录。

没有 SQL、DBC、MPQ、03 数据、服务器 EXE；没有部署或推送。与 WDN6B 文件不重叠，可以在其后安装；这不是巫医最终总包。

## 交接第 4 节逐项结论

1. 暗影狩猎群伤：当前 spec==2 有五魂 Spirit Eclipse、Reclamation 攒魂（含真实 9004174 替代）、Spirit Glaive；群蛇是独立召唤分支。Shadowflare 的群伤选择只在 spec==0 调用的 RebornWD189::Damage 里，spec==2 没有这个入口。已确认覆盖缺口，尚未据此直接改循环。本服 Shadowflare 是直接范围伤害；额外诅咒扩散在 WD151::dark 中要求 9004092 天赋有效并命中至少 3 个目标，不是上游 SQL 注释里的两怪即无条件扩散。
2. 闲置：Choose 可因未载入真实方案、控制/读条、自保、紧急治疗、净化、缺参战目标、费用/CD、移动权限而不输出。召唤维护在普通暗影资源链之前，可能占用 GCD，但是否本局主要原因未证实。Prepared 单独查真实费用，不能把 CanCastSpell 探测成功当有蓝。此次不调阈值，诊断记录资源与实际选择。
3. 目标：CurrentEnemy 先看 current target，继而主人选中目标、自身 victim、攻击者；全部要求已有队伍战斗关系且非可破控目标。不会仅凭主人选中闲置怪便开火。不改变这一保护。
4. “缺席三分之一”：输出和受伤为零不能证明不在场，可能距离/控制/策略/未施法。本局缺位置及逐技能日志，根因未确定。现有 StrandedRecovery 的 Player + PlayerbotAI 判断和 60 秒无进展门槛不等于每个零输出角色必定传送；本批不改它。新日志只能补采之后的样本，不能复原旧场次。
5. 职责：本服真实提交方案 spec==1 为治疗、spec==2 为暗影狩猎输出、spec==0 为巫毒输出；不能套上游 specId=4。非治疗也可能因急救/净化临时辅助。日志输出实际 plan/spec/healer，未查询在线 Jorn 存档，不能宣称当前装备与方案已核实。
6. 法师：MultiBot frost aoe 按钮确实发送 co +/-frost aoe。MageAoeStrategy 根据实际天赋 tab 选择：冰霜/奥术 medium aoe 倾向烈焰风暴→暴风雪，地面烈焰已有时暴风雪优先；冰霜 light aoe 加冰锥；火焰另有龙息、冲击波、活体炸弹分支。light 为当前目标 8 码内至少 2 个有效 attackers，medium 为至少 3 个，并要求当前目标存在。整场有 12 怪不等于此时 8 码内满足条件。寒冰新星不能直接当这两个开关的输出动作。
7. 法师低输出：全 mod-playerbots 搜索未发现 CoaAoeNoIdlePull，不能归因于这项上游配置。原生可用性、走位、仇恨/控制等仍可能阻挡；250 左右 DPS 的具体原因待新日志。诊断列出实际策略、cluster8 和执行判定，不关闭防误拉保护。
8. 中文文案：确认为提示错误，按钮实际命令正确。仅将 frostAoe 提示中“禁用奥术范围攻击”改为“禁用冰霜范围攻击”。

## 日志如何读

- `[PBAOE1A engine]`：class 8/13 的每个 AI Engine 最多每 5 秒采一个实际 tick；包含名字/GUID、地图实例、战斗/存活、蓝量、移动/读条/失控、当前目标距离/LOS、attackers、cluster8、minimal、该 Engine 策略。不同状态 Engine 各有自己的限流。
- `[PBAOE1A action]`：采样 tick 最多 16 条实际引擎事件；USELESS、IMPOSSIBLE、PREREQ、FAILED、OK 或 multiplier 阻挡。不会为了日志额外调用 isUseful/isPossible/Execute；超出 16 条截断。OK 表示动作返回成功，不代表伤害命中；5 秒采样不用于统计施法次数。
- `[PBAOE1A wd]`：巫医可用性检查也记录空选择，包含真实方案、魂量、选中技能、选择理由和是否要求走位。空选择 reason=rotation 是默认值，不是具体根因。
- `[PBAOE1A wd-spell]`：Shadowflare/实际回收替代/月蚀/战刃的已学、冷却/GCD、原生费用和资源类型、Prepared、最大距离/LOS、扩散天赋、拟态存在。Prepared 不含所有原生施法条件；rangeOK 只表示最大范围，不代替最小射程/正面/弹药等完整检查。
- Engine 未被调度、离线或传送过程不能保证产生日志；没有采样也不能断言角色不存在。actor 与策略只观察，不修改职责。

## 上游核对与适配边界

2026-10-27 在线核对：
- Zyth45/mod-playerbots，默认 coa，9bf5cb3c1cbc594ad416293985bbc406544ca7db，GPL-2.0。实际读取 rotations.sql 及 CHANGELOG_COA.md。当前 SQL 仍为 light aoe Shadowflare / 三魂 Eclipse；变更日志提到缺失才补和五魂，两者不完全一致，不能只依变更标题移植。
- shiro2448/mod-playerbots-fork：默认分支实际为 coa；用户指定 wildcard 当前 7b61471cf618f69927f05392057eefcb0585bee9，GPL-2.0。该分支轮转 SQL blob 与 Zyth 完全相同：a893455356efad96546a251de82af8b1d975842a。这只能证明该文件相同，不能据此说整个仓库无独立实现。
- Corfirean/mod-coa-playerbots，master，6a289fc2230ce9425924ca86dee02d0bb8d3d344，AGPL-3.0。读取 ProfileWitchDoctor.cpp 作为结构参考；未复制其代码、评分或法术 ID。本批未逐项核实 CombatContext 的爆发判断，保留交接线索状态。
- jealous-sound/azerothcore-wotlk-coa，5dd9d5c861c340a0d990c4d49264baa297161a11；读取巫医文件目录、AscensionWitchDoctorAbilities.cpp 和最近 30 条 Issue/PR。关键词搜索返回 HTTP 422，相关历史 Issue/PR 全量核对仍有缺口；不是声称无相关修复。

来源只用于分析。本批完全沿用本地实际技能、法术脚本与已安装构筑规则，未移植上游 SQL、跨服 ID 或 AGPL 实现。

## 检查与回归

Engine.cpp、包含改后职业 Context 的真实 AiFactory.cpp 经 MSVC /Zs 通过；Lua 解析通过。自审，非另一位 AI 评审。诊断默认关闭、每实例限流、无跨线程静态 map，读取快照不写方案，不改变动作返回值、优先级和施法结果。
完整编译链接：未运行；游戏：未运行；DPS 对照：未运行。没有新增技能/减益/视觉，相关资源和数值联动本批不改。

用户测试（全部未运行）：先关闭诊断确认原行为；再开启诊断，以同一队伍分别打一段单怪和聚集多怪，记录开始结束时间。保存 Playerbots.log、dc_fights.jsonl、分技能伤害截图，并确认 Jorn 的暗影狩猎方案和 Etetee frost aoe 状态。最好有同条件多局对照；不要把本包当提高 DPS 的结果包。不开清本及纯玩家队伍也回归。取得样本后再决定 Shadowflare 入口、召唤占用和法师被阻挡的具体修复。

## 回滚

只在当前文件等于本包输出哈希时回盖 backup_原文件 对应源码/客户端，再重编；若已有后续修改须合并，不能整份覆盖。输入/输出都不匹配时先停覆盖并比较。恢复日志配置；无数据库回滚。

## 流程记录

使用项目 coordinate-ai-team-parallel-development、audit-and-port-upstream-features、port-coa-playerbot-class-ai 技能；共享函数提前登记，git fetch wowshub 已完成。来源核对、策略/资源/目标/召唤联动静态审查已做；运行数据不足明确待取证。未验证项未写为成功 Skill，未改原运行文件。
