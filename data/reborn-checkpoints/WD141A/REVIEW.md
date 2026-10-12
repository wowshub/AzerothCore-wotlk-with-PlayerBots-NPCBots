# 评审：WD141A 面板金币解锁第三方案（2026-10-12）

- 评审方：Claude；被评审：Codex 候选 `000Ascendupdate/000Ascendupdate20261012/codexfix_20261012_054431_阶段WD141A_面板金币解锁第三方案`。
- 按《规范_交叉并行开发.md》v2 第 12 节。只读评审，不改巫医任何文件。

## 范围和读过的材料
- `RebornWitchDoctorTalents.cpp` 改动前后对比（忽略换行符后只有 3 处：`State` 新增字段、`TrainerOptions` 互斥、新增 `PanelUnlockQuote`/`PanelUnlockBuy` 和两条命令），以及未改动的 `PurchasePolicy`、`TrainerOptions`、`TrainerPurchase` 全文。
- 客户端 `Unlock.lua`（新增，全文）、`Profiles.lua` 与 `RebornWitchDoctorTalents.toc` 的改动。
- `03` 服务端配置：只把 `RebornWD13.ThirdSlot.Enable` 从 0 改为 1。
- 自测：`Unlock.lua`、`Profiles.lua` 用 Lua 5.1 编译通过。用 `checks/file_manifest.json` 对日常源码和客户端做三态核对：源码 4 个文件可直接覆盖；**客户端 3 个文件用户已安装**；服务端配置未改。
- **未核对**：26 项 Lua、16 组模拟交易没有重跑；没有编译和进游戏。

## 总结论：同意（无阻断问题）

### 1. 单次报价消费 —— 成立
- `PanelUnlockBuy` 一进来就把 `panelQuoteValid` 置 false（失败也算用过），还要求 `token`、`revision`、`slot` 都和服务器保存的报价一致，并且在 60 秒内。
- 通过后把报价交给原有 `TrainerPurchase`：它先置 `quoteValid=false` 再判断，**同一报价不可能成交两次**。
- 客户端令牌来自服务器（`++panelQuoteToken`，跳过 0），客户端无法伪造有效报价。

### 2. NPC 与面板互斥报价 —— 成立
- 面板报价同时清掉 NPC 报价（`quoteValid=false`）；NPC `TrainerOptions` 同时清掉面板报价（`panelQuoteValid=false`）。所以"在一边报价、到另一边成交"两种顺序都会被拒。
- 两边共用 `quoteSlot/quoteGold/quoteLevel/quoteTime`，但因为互相作废，不会串用对方的报价。

### 3. 复用原 `TrainerPurchase` 事务 —— 安全
- 原事务逐字未改：重新取当前配置并与报价比对（管理员改价或关闭后旧报价失效）；`ProfileReady(p,true)` 重新读档并检查存活、脱战、非施法、非载具；再查当前已解锁数和等级；先改内存金币，再在**同一个数据库事务**里写购买记录和金币，提交失败则退回金币；提交后重新读档。
- 面板通过"购买后 `unlocked` 是否增加"判断成败，比依赖 `TrainerPurchase` 的返回值（它是 `void`）更可靠。
- 聊天命令和 NPC 对话都在世界线程处理，没有并发问题。

### 4. 插件超时与草稿 —— 合理
- 购买前要求：已读档、布局一致、**没有未保存草稿**、衣柜不忙、存活且脱战。
- 等待回包期间，包装了 `CanEdit/SelectSlot/SetSpec/Bind/Activate/Save/QuoteReset/ConfirmReset/Query`，阻止任何编辑或其他请求，所以购买回包不会覆盖正在改的草稿。
- 确认框 55 秒，比服务器的 60 秒短，余量合理；确认时再检查一次版本、槽位、等级和金币。
- 8 秒没回包：报价超时提示检查服务端版本；**购买超时提示"刷新或重登核对，不要直接重复购买"**。服务端以"已解锁数"为准，不会重复收费。
- 回包按序号对应，迟到的旧回包会被忽略。

## 建议（低优先级，不阻断）
| # | 内容 | 谁改 |
|---|---|---|
| 1 | `PanelUnlockBuy` 在 `TrainerPurchase` 已提交、但随后重新读档失败时回 `verify`。这时金币已扣、方案已解锁。客户端文案"交易结果需要核对，请刷新或重登；不要重复购买"是对的，验收记录里可以写明 `verify` 表示"很可能已成功" | Codex（文案/记录） |
| 2 | 走面板时，如果 `TrainerPurchase` 拒绝（比如金币刚好不够、250 毫秒内连点），聊天里会出现原 NPC 文案"请重新与导师对话"，面板同时显示"未完成购买"。功能没问题，只是提示指向 NPC；以后可以给面板路径换一句通用提示 | Codex（以后） |
| 3 | 两个面板命令都是 `SEC_PLAYER`，任何玩家都能发；入口已检查 `Doctor(p)`，非巫医直接返回，没有问题 | — |
| 4 | **部署顺序提醒**：用户客户端已装新插件，服务端还没换新程序。在此之前点锁定方案会得到"报价请求超时，请确认已安装 WD141 服务端"，属预期 | 用户 |

## 冲突核对
- 只改巫医模块、巫医插件和巫医配置，与 Claude 的 DCCB1A+TELE1A（清本 `DcCombatPurge.cpp`、统计模块）、LFG81A 无文件重叠，可以同一次编译。

## 需要用户决定的事项
无（价格沿用 40 级 1000 金，第 3 槽开启、4～10 预留，均为已定配置）。

## 修订记录
- 2026-10-12：Claude 初版。
