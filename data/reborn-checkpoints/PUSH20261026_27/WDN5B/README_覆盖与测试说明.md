# WDN5B NPCBot最终治疗日志（增量覆盖测试包）

游戏内验证：**未运行**。未完整链接worldserver；Unit.cpp /Zs语法检查通过，提取真实HealBySpell方法的API替身测试21项通过（另含200条并发记录）。不是实机测试通过，也没有发布Release。

## 做了什么
只改两个文件：
- src/server/game/Entities/Unit/Unit.cpp：NPCBot条件编译下增加bot_ai.h引用；仅在Unit::HealBySpell内DealHeal之前快照治疗前HP，在SetEffectiveHeal之后输出最终日志。不改治疗量、行为、公共钩子参数顺序或dc_fights.jsonl。
- modules/mod-reborn-bot-telemetry/conf/RebornBotTelemetry.conf.dist：追加两个默认配置项，原配置保留。
采用本次HealInfo，未使用跨钩子thread_local。独立于BotTelemetry.Enable。不包含被放弃的healBy包。
这是叠加WDN5A的日志增量包，不是新的技能总包；当前Unit.cpp与WDN5A累计内容一致，日志补丁保留它们。

## 安装与启用
1. 将01_覆盖到源代码根目录内文件覆盖到：
D:\000rebornWOW\000RebornWOWHighForkPRO\beascendcode\AzerothCore-wotlk-with-PlayerBots-NPCBots
2. 先覆盖，再运行项目根“编译前运行_更新已修改文件时间.bat”，再由你编译、部署并重启服务端。本包未生成或部署worldserver.exe。
3. .conf.dist只是模板，**覆盖源码模板不会修改你正在使用的配置**。在实际生效配置中追加或修改下面两项（不要重复定义同名键）：
D:\000rebornWOW\000RebornWOWHighForkPRO\beascendserver\wowshub_playerbot_npcbot_newrace20261013Ascend\configs\modules\RebornBotTelemetry.conf

```ini
RebornBotTelemetry.NpcBotHealLog = 1
RebornBotTelemetry.NpcBotHealLog.MinHeal = 1
```
交付模板默认NpcBotHealLog=0，必须主动设为1才输出。测试结束改回0。
新程序首次部署需重启。之后代码每笔治疗读取配置，没有静态缓存；源码已核对.reload config调用LoadConfigSettings(true)。可以尝试.reload config切换，**实际热重载未运行**；不确定是否生效时重启确认。
4. 无SQL、无DBC、无客户端资源更新。

## 日志在哪里
使用LOG_INFO("server",...)，固定前缀[NPCBOT-HEAL]。当前现场Logger.server=4,Console Server和Appender.Server=2,5,...允许INFO进入Server.log（只读核对，未修改配置）。其他部署如提高日志过滤级别，需要自行允许server的INFO；不要为了日志降低全服所有logger的级别。

```powershell
Select-String -LiteralPath 'D:\000rebornWOW\000RebornWOWHighForkPRO\beascendserver\wowshub_playerbot_npcbot_newrace20261013Ascend\logs\Server.log' -SimpleMatch '[NPCBOT-HEAL]'
```
也可在日志目录用：`findstr /C:"[NPCBOT-HEAL]" Server.log`，或 `grep -F '[NPCBOT-HEAL]' Server.log`。

示例（格式示意，**不是实机结果**）：
```text
[NPCBOT-HEAL] time=1793000000 serverMs=123456 bot=Witch Doctor WDN1A(900260) casterGuid=Creature-... class=21 role=124776 spell=9003101:Loa's Brew target=德德熊(tank) targetGuid=Player-... heal=1200 over=300 absorb=100 targetHpBefore=45 inCombat=1 mapId=599 instanceId=3
```
字段：time为Unix秒、serverMs为服务端单调毫秒（会回绕），GUID使用完整ToString；class是NPCBot职业ID（巫医21），不是玩家职业ID13。spellName采用SpellName[0]，缺失写unknown。targetHpBefore在这次DealHeal调用前取值；heal为最终有效治疗，over为吸收结算后的治疗量减有效量（防下溢），absorb单列。
MinHeal按heal+over判断（使用64位相加），默认1；两者均0不写。因此纯过量会写，全吸收且有效/过量都0不写。每笔符合条件的治疗一行，不做聚合。
坦克类型：同队的原生坦克识别，或正在受击的熊/巨熊；不改队伍职责。普通玩家和玩家型机器人统一标player，避免引入Playerbots模块依赖；不会把它们的施法误记为NPCBot。

## 第一阶段覆盖边界
只记录直接施法者是NPCBot、并经HealBySpell结算的治疗。不覆盖召唤物自己施放的治疗（治疗守卫、神像等），也不覆盖绕过HealBySpell直接调用DealHeal的治疗。不能拿这份日志当NPCBot全部治疗量；玩家型机器人Ereer仍走原统计。
没有治疗日志也不一定就是AI故障：先检查开关、logger、最低量、施法来源和上述覆盖边界，再与[WDN5A heal]决策日志对照。

## 实机测试步骤（全部未运行）
- 开启后，带治疗职责巫医NPCBot进入岩石大厅，打3–5波小怪和1个Boss，保留Server.log。
- 确认日志是NPCBot自己的名字/GUID，能看到治疗坦克及治疗前HP；同名角色不靠名字区分。
- 满血时合法治疗若产生纯过量，应该heal=0、over>0；有治疗吸收时不要把absorb算进over。
- 与坦克低血量时段、WDN5A决策日志对照，不把施法请求当最终有效治疗。
- 改回0并重载/重启，再制造合法治疗，应不再产生此前缀的新行。

## 校验、回滚和基线
checks/manifest.json记录两个文件输入/输出SHA256；SHA256SUMS.txt是包内清单。仅当现有文件等于输入或输出版本时覆盖；如果后续装过别的包且哈希不同，先合并。
回滚仅在两个源码文件仍是本包输出时恢复backup_原文件并重新编译；若已有后续修改，禁止整文件回退。也可以直接将业务日志开关设0停止输出。
远端基线efdd0178caae352342e71b81aaa3d256e9044f73，开发用实际日常源码独立副本，未改日常/运行目录，未commit/push/tag。
