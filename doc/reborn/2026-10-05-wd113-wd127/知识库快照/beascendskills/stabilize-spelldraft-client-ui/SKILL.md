---
name: stabilize-spelldraft-client-ui
description: Diagnose and stabilize the beAscend SpellDraft 3.3.5 client UI, including frame strata, equipment-overlay leaks, visible dragging, repeated-open corruption, snapshot caching, dropdown compatibility, and action-bar visibility. Use when the SpellDraft book overlaps native panels, opens slowly, turns black while dragging, duplicates rows, or throws frame/template Lua errors.
---

# Stabilize SpellDraft Client UI

## Model

Separate four responsibilities: frame ownership, frame level/strata, data refresh, and drag feedback. A fix in one must not replace the others.

## Rules

- Reuse the established book frame and its Jiangnan-rain parchment layout; switch pages inside it instead of creating competing top-level books.
- Parent every equipment slot, average-item-level label, hide button, catalog card, and drag visual to the page that owns it.
- Restore the normal visible frame during drag. Do not display a full-screen black blocker as a movement surrogate.
- Debounce open/refresh messages and reuse the last authoritative snapshot. Build rows once, update fields in place, and hide unused rows.
- Make repeated open/close idempotent. A second click must not append unnamed frames below the book or resend an overlapping transaction.
- Never assume XML template fields exist. Guard optional regions and provide explicit dropdown width padding for this client.
- Test at rest and while moving/jumping, then with the character, spellbook, quest log, achievements, transmog, and mystic pages open.

Read [evidence-lineage.md](references/evidence-lineage.md) for verified packages and the black-drag, layer-leak, anonymous-dropdown, and double-open anti-patterns.


EV1G装备预览窗视觉验收与范围见 [equipment-vault-ev1g.md](references/equipment-vault-ev1g.md)。不代表真实仓库功能通过。

## 2026-09-17 WD18 两处圆环实机通过

用户明确反馈“好的 修复好了”。来源：000Ascendupdate/000Ascendupdate20260917/codexfix_202609170357_阶段WD18_双面板圆环淡黑方底修复。
WD17只裁头像，圆环本身ClassPortraitRing的方形UV区域仍含淡黑方底。WD18对天赋Panel.lua和衣柜Vault.lua的圆环也几何裁圆：72显示尺寸、UV .25-.75、144个半单位水平条带（142有效），边缘宽度按条带较远边的圆方程计算。仅初始化创建，旧客户端无需现代MaskTexture，无资源重编码。
复用时同时检查图标和圆环/阴影两层；不能把圆环当成下层头像遮罩。验收仅限此次两个圆环方底消除，不扩展到装备存取或数据库故障保证。

## EV2D1 自动补图基本确认（2026-09-17）
用户表示大退后“不一会就刷新成装备图标”，确认自动补图基本工作；红问号体验由EV2D3候选调整。来源000Ascendupdate/000Ascendupdate20260917/codexfix_202609170634_阶段EV2D1_大退后装备资料自动补刷。复用：原件快照与GetItemInfo元数据分离，有限隐藏Tooltip请求与本地自动重绘。不能将加载图片当成恢复原装备，低网速/异常矩阵仍未完整验收。

## 已发生反例：EV2D5 Bagnon枚举（2026-09-17）
枚举含隐藏原型/未绑定控件，直接调用GetPlayer触发frameSettings nil key。不得以方法存在就判定插件控件已初始化；拖影清理放在第三方目标检测前。EV2D6候选见 D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260917\codexfix_202609170801_阶段EV2D6_跳过背包原型与拖影异常清理，未实机验收，不是成功配方。

EV2D6实测拖出仍拒绝的证据：focus=OneBagFrameBag0Item3，当前实际背包是OneBag，不是先前按外观推测的Bagnon。先用事件日志识别真实控件再查对应源码；同时安装不代表实际使用。EV2D7仅候选，未实机成功。

## 2026-09-18 EV2K1 人物绶带与Equipence共存：用户实机确认
用户反馈“好帅啊”并提供EV2K1人物/衣柜同屏截图：人物装备小绶带与外侧附魔图标错开；衣柜保留大绶带与穿戴中标记。验收限此次截图所示布局，不能推导所有UI缩放、满宝石槽、异常换装和持久化已通过。
来源：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260918\codexfix_202609180337_阶段EV2K1_人物绶带避让附魔宝石
实测图片：codex-clipboard-c143d94d-ca38-49d9-aa93-1641004faf78.png。
复用方法：先核对Equipence内联图标增长方向与装等底部锚点；人物使用格内顶部外侧角标（22×32缩放0.70），衣柜保留原大绶带。缓存复用且不接收鼠标；不要用提高层级去覆盖其他插件。人物100以上以#显示，完整编号见悬停。
永久Skill：beascendskills/stabilize-spelldraft-client-ui/SKILL.md；同名Tutor：beascendtutor/stabilize-spelldraft-client-ui/TUTOR.md。
衣柜建议冻结新增功能进入最终验收；仍需确认A/B往返归柜、新装备确认替换、重登/重启保存、背包满与战斗限制等场景。不标整模块最终完成。


## UIV1 用户实测通过：加载期语音API保护

用户反馈“继续开始下一步的技能修复 测试这个通过”，承接UIV1。确认组队reload报错修复基本通过，不扩展到全部语音场景或巫医技能验收。
来源：[codexfix_202609182326_阶段UIV1_队伍头像语音API缺失保护](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260918/codexfix_202609182326_阶段UIV1_队伍头像语音API缺失保护/README_覆盖与测试说明.md)。FrameXML早于插件，插件shim不能保护此前调用；应在调用点type检查并短路，保留真实函数。缺失状态用false，Lua中0为真。27项离线检查与用户实测分别记录，历史ZIP不变。


## 2026-09-27 WD80D 共享节点悬停双选：用户测试通过

来源：000Ascendupdate/000Ascendupdate20260927/codexfix_202609270620_阶段WD80D_共享节点悬停双选。CoA实际CATalentChoiceBaseMixin对照：惰性SelectionFrame、父按钮后代、立即展开、0.15秒离开宽限、按PendingRank显示；适配现有Paint/Tooltip/SetNode/保存校验。用户明确“测试通过”，仅交互与已开放选项范围；空灵之魂尚未移植，不继承为效果通过。WD80C缺少绿色choice/circle atlas时同形灰色纹理着色回退一并保留。


## UIA1 用户实机确认（2026-09-29）

用户明确“成就修好了”，确认此前多项成就点击缺失AchievementProgressBarTemplate报错基本修复。仅验收反馈范围，不扩大为全部任务/成就追踪与所有界面组合。复用方法：扫描MPQ同路径版本，定位调用与模板定义断链；只补回旧版同客户端StatusBar模板块，保留当前WatchFrame其余字节及缓存逻辑。
来源：[UIA1覆盖与测试](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609291824_阶段UIA1_成就进度条模板修复/README_覆盖与测试说明.md)；输出XML SHA256 028ee6af0d4a35dc6ea1cf390298f41d876c1eeafa605b678bfd5132cf4b2409。


## 2026-10-03 WD119B 持续时间与技能书污染清理（候选待测）
仅客户端3文件增量：两技能正文读服务器当前10/11/12秒及效果，冷却单独标注；删除WD114C/D对原生列表、搜索、页码和刷新调用的写入，/wdbook只读定位并记录最近受保护操作。沿用WD119A提示协议，兼容WD117/118，不改源码SQLDBC和DBM。不把popup里的DBM-Core当作已证实根因；无taint栈，完整弹窗修复待实机验证。
累计数值模拟、12组真实描述、只读表/原生函数不变检查、5路冷却模拟、语法及ZIP校验通过。首次只读测试代理缺少Lua5.2的__ipairs导致夹具失败，修夹具后通过。未编译未部署未实机。使用stabilize-spelldraft-client-ui，仅候选经验。
来源：[覆盖说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610030124_阶段WD119B_持续时间显示与技能书污染清理/README_覆盖与测试说明.md)。ZIP SHA256 c7c7cf3ca7e025bef3781210913b574ea363a1b0948e80d80bd93a437cd99ce9。

## 2026-10-03 WD119B 技能书面板恢复：用户实测确认
用户在测试WD118A化蛇时反馈法术书、专业页、召唤预览重叠；随后明确“我用下载 WD119B 修复包 正常了”。确认WD119B覆盖后本次技能书面板恢复正常。此次反馈没有逐项确认化蛇变形/5秒持续/80%移速、灵魂行者数值，也没有明确单独重测DBM受保护点击弹窗，不扩大验收范围。
方法：保留原生技能书管理，移除WD114C/D对列表、页码、搜索及按钮刷新的插件写入；/wdbook仅只读定位。此用户结果支持采用WD119B客户端基线，但不等于已经凭taint栈证明完整故障传播链。后续累计包应合并WD119B三个Lua文件，不用旧累计客户端文件将它们回退。
来源：000Ascendupdate/000Ascendupdate20261003/codexfix_202610030124_阶段WD119B_持续时间显示与技能书污染清理。原ZIP不改写；新增独立验收记录。


## 2026-10-03 前批基本验收与WD119A状态澄清
用户先说“前面测试都已经都通过，继续下一批”，随即明确“我来测试 WD119A”。因此前批WD117灵魂行者、WD118化蛇及WD119B面板/提示按用户总体反馈登记基本测试通过；WD119A蛙变术、贡克祝福、克拉格瓦祝福保留待测，不将总体反馈扩大到随后明确正在测试的包，也不扩大成全PvP/多人/全部数值专项通过。既有WD118B拖动与沃金守望验收保留。
下一批来源审计目录：000Ascendupdate/000Ascendupdate20261003/codexfix_202610030147_阶段WD120A_酿造下一批依赖开发。该目录仅研发证据，无可安装新包；未改运行源码、客户端或生产数据库。


## 202610030327 WD120A 酿造基础三节点（候选待编译/实测）
已完成4005大锅酿造、12645丛林蘑菇、12646药水投掷的有界接入：免费酿造节点、配料6秒范围治疗、投掷7级+18秒HoT。保存扩87位，旧位与购买账本保留；World手动系数避免重复加成；节点/技能书/拖动图标一致。当前治疗参考范围读取服务端，不依赖草稿。基线WD119A累计+已验收WD119B+候选WD119C；WD119C和本批尚未实机通过。
上游在线固定d7620151fa4267ab90c7e0554b32628017df241a；字段232是描述变量ID，实际802703等级缩放来自ScalingBase实现。不能将早期字段误判继续复用。仅蘑菇一种配料，其他配料和泼洒仍未开放；外观复用既有洛阿佳酿887925，36项引用资源已只读找到，不宣称大锅模型或专属药瓶弹道完成。
403项临时MySQL与累计Lua/DBC检查通过；C++没有编译，没有修改运行目录或生产数据库。一次历史GM测试断言未复现，原路径未声称修复，详见memory。
[覆盖说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610030147_阶段WD120A_酿造下一批依赖开发/README_覆盖与测试说明.md)；[逐步教程](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610030147_阶段WD120A_酿造下一批依赖开发/tutor.md)；[交接](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610030147_阶段WD120A_酿造下一批依赖开发/handoff.md)。ZIP SHA256 `02ee4367bc97f2f9df779b800886cc20a5759539b88a3b62c26ab8e134fea71c`。旧ZIP不改写。


## 2026-10-05 WD119B技能书污染与WD127C面板源

诊断按已学→原生槽→渲染列表→分类页格只读定位；不得为定位写受保护原生按钮/渲染表。DBM弹窗不是污染源证明。Panel按Data.lua绘图，逻辑层有节点不保证面板有节点；旧树布局和新版官方树不同，应单独迁移而非按ID覆盖。

来源及限定验收：[本窗口证据](references/wd113-wd127-window.md)。最终药水同步使用[synchronize-wotlk-spell-costs-and-cooldowns](../synchronize-wotlk-spell-costs-and-cooldowns/SKILL.md)。旧失败包不作为成功基线。
