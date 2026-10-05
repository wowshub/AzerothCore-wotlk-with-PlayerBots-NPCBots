# 新窗口交接：从WD127F继续

## 直接给新窗口的开场指令

请先读取项目AGENTS、最新ruleAscend/refResourceAscend、beascendskills/skillsAscend及本交接；不要仅依赖自动技能列表。接续已经由用户基本测试通过的WD127F累计母版，保留之前所有方案、购买、技能书、图标、读条中断和提示修复。先复核药师／再生者的DBCdie0/base49/9数值矛盾，再按依赖选3—4个下一批技能，不重复让用户安装旧失败包。默认只交可覆盖源码／客户端／服务端数据与SQL，由用户编译部署。

## 当前母版与远端

- 最终包：D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261005/codexfix_202610050306_阶段WD127F_投掷泼洒冷却完整同步.zip，SHA256 e68282509364048d9b32009ac07b7c7f14dfa5fb46ae918560856201e4e90417。
- 用户2026-10-05确认当前技能测试通过；前批明确成功见成功与待测清单。不要把基本通过扩大为全数值／PvP／机器人矩阵。
- 源码：D:/000rebornWOW/000RebornWOWHighForkPRO/beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots，分支threemodelcardpro；目标远端wowshub=https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots.git，**不是origin/lisancth**。
- 首轮推送559fe78fd＋8100818d2；前一未推送32095f2e5也在历史。Git保存累计源文件及data/reborn-checkpoints/WD127F的完整资源ZIP，ZIP必须取包含8100818d2的版本。
- 14个F源码文件与提交前实际工程逐字节一致。其余Core的早期巫医依赖也提交。ACSoap、shell位、PSD、子模块变化等非本窗口修改保留在工作树；不要reset/clean或顺手提交它们。
- 客户端及服务端实际运行路径仍以refResource登记和现场文件核对，不凭本归档推断部署。两侧Spell.dbc独立生成，绝不能互换。

## 已成功的方法不能回退

1. 数字从服务器读取，白名单、序号、epoch、revision和active核验；草稿不授权也不决定当前数值。
2. PotionToss9003870–76及Splash9003890–96都有CD字段。药水投手9003897精确减5000；无被动基础15秒，激活10秒。原生CD在GO后校正，文字Left/Right都刷新。HoT投掷18秒、泼洒12秒，独立于CD。
3. 贡克60秒后置同步；普通／贡克移动打断；克拉格瓦瞬发可移动。Spell.dbc第31列MOVEMENT位1已补，不能再拿未修旧数据覆盖。
4. WD119B只读技能书诊断，C/D写原生按钮和渲染表的旧路径不要恢复；五个BLP在MPQ而非只在loose插件。
5. 强效混合两入口最高级，不重复叠加9003854。节点图标、书页SpellIcon路径一致，但没有统一改官方整树布局。
6. 范围蘑菇与两种药水的隐藏附效、系数顺序和发射时配料快照保留；只有一种准备配料，Mixologist未做。
7. AEIdCount=88，mask宽100；C++、Lua四limb、SQL精确存取、Data.lua显示都同步。Characters累计SQL用127A过程，不能执行WD113旧schema清新记录。

## 接下来优先做什么

P0：检查9003898/99/3900实际Aura Amount消费。当前最终数据die0分别base49、9/49、9，与50%／10%／10%说明矛盾。它们只在拥有权／基本使用层面有总反馈；不能把49猜成50。若确证修数据，只改对应双端记录并校验旧行，更新数值显示和原验证脚本第74列；不要把所有法术的base统一+1。

P1：依赖台账选下一批3—4项。优先检查Mixologist／未完成酿造节点，但先核对最新官方和上游Issues/PR与实际commit，不承诺已开发。整树布局／官方ID跨版本复用另立专项，保留旧存档映射。

P2细测：鱼油16级自动学习边界、蛙骨护盾系数／换料快照、缩小盟友目标与属性、蛇神门徒第二驱散／GCD；不重复基本通过流程。诊断/wdbook旧名单含退役9003854，后续可改为正规9003620/21，false本身不是学习故障。

DRBOT1A及其它窗口地图／机器人事项不继承本次技能验收。

## 工具与证据

- 项目永久Skills：新synchronize-wotlk-spell-costs-and-cooldowns；现有trace-and-port-coa-spell-resources、build-wotlk-three-build-projection、stabilize-spelldraft-client-ui均已同步。
- 本窗口教程tutor.md含14段实际源码逐行讲解，逐阶段教学索引含各原教程；失败修复备份有原ZIP和SHA。
- Python3.9不支持Path.write_text的newline参数；用显式UTF-8。DBC字段74=die、80=base、86=TargetA，31=InterruptFlags、40=DurationIndex。
- Lua解释器：D:/000rebornWOW/000RebornWOWHighFork/beascendBuild/modules/mod-ale/src/lualib/lua/RelWithDebInfo/lua52_interpreter.exe。模拟测试不等于客户端3.3.5实机。
- MSVC：D:/soft/vs2022/enterprise。仅独立/Zs检查已经做过，不声称代理完整编译或生成EXE。只有用户明确要求才代编译／部署。
- F的checks含84场景、旧数字回归、全Lua语法、双端字段比较、实际后GO块MSVC检查；原隔离MySQL结果保留，不写生产数据库。
- 上游F在线获取失败，没固定最新commit；下一批新移植必须重新查。旧research的commit不能称今天最新。

## 不要再用的中间版

WD114C/D缺项与写原生UI假设、WD115仅loose图标、WD119C仅前置发送、WD122A坏枚举、WD124A wanted重名、WD127A数组尺寸、WD127B缺Data、WD127D混型min/max、WD127E局部冷却。最终包名0306，0305是构建中断目录；森金/022207草稿不是已发布的新技能。

本交接不要求用户再次确认已授权的归档／推送；未来新增技能仍按当前用户具体范围完成。
