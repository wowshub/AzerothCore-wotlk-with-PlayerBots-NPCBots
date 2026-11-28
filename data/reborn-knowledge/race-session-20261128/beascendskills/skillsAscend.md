# beAscend Skills Catalog

## 2026-09-29 本窗口新增可复用能力

- [restore-coa-wmo-minimap-mappings](restore-coa-wmo-minimap-mappings/SKILL.md)：用户确认北郡监狱、上山洞穴、新金矿地下城三处圆形小地图基本可用；来源 WMO2E，M 键地图和副本玩法未验收。
- [seam-coa-northshire-adt-boundaries](seam-coa-northshire-adt-boundaries/SKILL.md)：用户确认 WMO2B 草地棋盘块及 WMO2C 北郡外围地缝基本修复；暴风城室内闪烁、后山缺口未解决。
- 本窗口 WD78B、WD79B、WD80D、WMO1A 的成功方法沿用本索引中现有 Skill。用户随后确认 WD85A 两项天赋在 WD85B 启动修正后基本通过，已补入 [巫医技能移植 Skill](trace-and-port-coa-spell-resources/SKILL.md) 与同名 Tutor；WD84A 其余节点及 WMO2F–J 不继承验收。

阶段复盘：[成功经验与交接](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609290608_阶段交接_成功经验与源码推送/memory.md)。

这里仅收录已经由用户在真实客户端与服务端验收成功、以后可重复使用的工程能力。每日修复包保存当时证据；Skill 只提炼不随日期变化的方法、边界、验收和反例。

## 收录规则

1. 未经实机确认的候选方案不得写成成功 Skill。
2. Skill 与 Tutor 目录同名，统一使用小写 kebab-case。
3. 每个 Skill 必须记录来源包、已验证边界和仍未验证内容。
4. 失败修复只进入 anti-pattern，不得伪装为成功经验。
5. 新版本应更新原 Skill；只有责任模型明显不同才新建目录。

## 已验证 Skills

| Skill | 可复用能力 | 关键实机结论 |
|---|---|---|
| [bridge-native-class-mechanics-into-spelldraft](bridge-native-class-mechanics-into-spelldraft/SKILL.md) | 把原生职业机制安全桥接到无职业 SpellDraft | DK 符文止崩；灵魂链接 20% 分伤确认；泰坦之握双手双持与 10% 惩罚确认；经典模式保留 |
| [build-spelldraft-talent-management-cards](build-spelldraft-talent-management-cards/SKILL.md) | 天赋卡片、Pending、逐级回退、职业树定位 | 双列卡片、加减点、搜索和定位通过 |
| [repair-spelldraft-native-passive-talents](repair-spelldraft-native-passive-talents/SKILL.md) | 原生被动保存、Aura、属性、重登、退款闭环 | 纯属性七链、命中双链、双武器专精、精确瞄准、全副武装、精神敏锐等通过 |
| [build-spelldraft-mystic-enchant-system](build-spelldraft-mystic-enchant-system/SKILL.md) | 神秘附魔多槽、角色19槽、定向石、双语图鉴、滚动总览与跨插件停靠 | 多附魔Tooltip、空装备槽秘印、40石双语、双入口唯一总览、右侧停靠和Base Stats联动通过 |
| [stabilize-spelldraft-client-ui](stabilize-spelldraft-client-ui/SKILL.md) | UI 层级、拖动、快照缓存和重复打开稳定性 | 正常可视拖动、打开卡顿显著降低、连续打开错位修复通过 |
| [repair-multiclass-summon-lifecycle](repair-multiclass-summon-lifecycle/SKILL.md) | 跨职业多召唤、主宠边界、数量限制和 Aura 稳定策略 | 最多召唤 2 个已确认；GM 多技能书与召唤自愈链通过 |
| [control-spelldraft-reward-drops](control-spelldraft-reward-drops/SKILL.md) | 天赋之书/失落魔典的模式隔离、等级差保护和配置掉率 | 经典隔离与大号刷低级副本软衰减已落地 |
| [repair-custom-client-dbc-crashes](repair-custom-client-dbc-crashes/SKILL.md) | 定位并修复自定义客户端 DBC 缺记录导致的 Error #132 | 联盟恶魔猎人 255 级理发不再崩溃 |
| [repair-dungeon-map-coordinate-projection](repair-dungeon-map-coordinate-projection/SKILL.md) | 副本楼层图、记录冲突和玩家坐标投影修复 | 哀嚎洞穴与影牙城堡问题楼层修复，正常楼层保持不变 |
| [build-portable-service-vendors](build-portable-service-vendors/SKILL.md) | 安全随身商人、材料商、毒药商、兽栏与五分钟生命周期 | 崩溃入口修复；双阵营商人、材料与全等级毒药直开通过 |
| [deliver-web-shop-items-transactionally](deliver-web-shop-items-transactionally/SKILL.md) | 网站商城扣款、库存、订单与 SOAP 邮件事务一致性 | Clockwork Rocket Bot 邮件到账，DP 正确扣除，失败可回滚 |
| [build-complete-dungeon-quest-helper](build-complete-dungeon-quest-helper/SKILL.md) | 从实时数据库生成全副本任务宠物，并按物品触发、自动交付、剧情状态、跑腿与事件脚本分配starter/ender | 失落神庙与长者修复通过；55级新角色确认错误任务不再出现、正常任务不再立即可交 |
| [build-account-glyph-collection-preview](build-account-glyph-collection-preview/SKILL.md) | 角色独立雕纹收藏、永久刻录、金币装备/替换与模型预览 | 刻录、角色隔离、金币装备/替换、黑熊/山猫预览及中文鼠标提示均实机通过 |
| [map-custom-race-shapeshift-models](map-custom-race-shapeshift-models/SKILL.md) | 自定义种族德鲁伊形态独立映射与旧精确行冲突清理 | 赞达拉熊/巨熊/猎豹/旅行/水栖/普通飞行/迅捷飞行全部实机通过，其他种族边界保留 |
| [deliver-breaking-news-reliably](deliver-breaking-news-reliably/SKILL.md) | 角色选择页公告的Warden有界重试、安全编码与GlueXML重挂 | 真实角色页已显示标题、HTML正文、边框与滚动条 |
| [build-wotlk-monk-combat-visuals](build-wotlk-monk-combat-visuals/SKILL.md) | 3.3.5a 武僧动作、SpellVisual、声音、双 DBC、Patch-XA与运行时动作仲裁闭环 | 虎掌/直击动作分离、贯日击移动跳跃拳击、旭日东升踢221在站立/移动/横移/跳跃完整出腿、声音与干净Patch-XA加载均实机通过 |
| [integrate-playerbots-extension-module](integrate-playerbots-extension-module/SKILL.md) | 接入 playerbots 扩展模块：文件夹名/启动函数、API 漂移 requires 兼容、cl /Zs 用项目参数预检、测试记录排错 | mod-dungeon-clear 祖尔法拉克 .dc test 7/7 Boss 零死亡；DC0A+DC0B 提交 986452ab9，tag reborn-dc0b-20261008；DCUI1A 插件中英切换 v3.6-reborn1（d0d981110）；DCP1 战斗统计模块 2dc049c52；DCSB1 一键托管 95bb32e60；DCAI1A 战术按编号 72d28e5cb；DC20261010 岩石大厅修复+坠落记录器+测试面板 7051220dc；DCMOV2A 清本移动不再被换到地图下面（古达克实测）fa5a5f31e，tag reborn-dcmov2a-20261011；DC20261012 清本合并上游+一键重置+斯拉德兰打法+队伍名字（古达克实测）42c4b6783，tag reborn-dc-20261012；DCCB1A+TELE1A 294b4dc66，tag reborn-dccb1a-tele1a-20261012；DCQ1A+DCQ1B 连续清本（紫罗兰监狱→乌特加德之巅实测）a69ea457e，tag reborn-dcq1a-20261012 |
| [backport-wotlk-addon-api-compatibly](backport-wotlk-addon-api-compatibly/SKILL.md) | 将新版插件/WeakAuras 缺失 API 安全映射到 3.3.5a 等价能力 | M6H 聊天菜单 Toggle 兼容层已实机通过 |
| [repair-wotlk-spell-cast-posture](repair-wotlk-spell-cast-posture/SKILL.md) | 让周期飞弹/Aura持续期保持已验证的角色施法姿势 | WD70B 暗影傀儡动作获用户实机通过；不包含所有模型或飞弹挂点 |
| [overlay-armor-on-nonstandard-uv-race-models](overlay-armor-on-nonstandard-uv-race-models/SKILL.md) | 让非标准身体 UV 的自定义种族模型显示胸甲/腿甲/手套：类型 1 贴图槽 + UV2 左右镜像标准分区 + 烘焙底图 + 头与装饰件排除；脚本可重复生成 | 蛇人男、女 v8：用户 2026-11-08 创建页/选角确认装备盖住蛇皮、花纹对称、头原版、6 肤色正常；男 v7 进游戏装备显示；靴子/披风/长袍无几何体不显示、Codex 已以 v8 男性 M2 为底叠加背盾（合并办法见 Skill）；已提交推送并发布 reborn-sethrak-armor-20261108（提交 7612c6f9e5） |

## 尚未晋升为成功 Skill 的项目

- 神秘附魔36种正式Boss/宝箱掉落分配、装备提取、新治疗/DPS/坦克秘印扩展：设计方向明确，但尚未完成真实掉落与战斗闭环。
- 雕纹收藏金币清空槽位：永久刻录与金币装备/替换已通过，金币清空仍待开发验收。
- 灵魂碎片提示成功但未进入背包：仍需定位。
- 魅魔、地狱犬、恶魔卫士宠物技能条：仍需完整实测和修复。
- 恶魔学识 Buff 长时间无闪烁回归：数量限制已通过，但该项仍需最终确认。
- 右侧动作条 2 登录/切图自动显示：有修复包，缺最终验收。
- 永恒之火任务：有桥接包，缺真实副本最终验收。


2026-09-06：`build-wotlk-monk-combat-visuals`已补充M6L3切喉手222与M6L2 B水中218/221成功案例；来源`D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260906\codexfix_202609060405_阶段M6M1_怒雷破引导连击\checks\上一阶段成功基线`。

- 2026-09-06：[build-wotlk-conditional-damage-absorb](build-wotlk-conditional-damage-absorb/SKILL.md)，M6N1躯不坏基本使用用户确认；精确边界与组合矩阵保留待测。


- 壮胆酒百分比生命防御，M6Q1用户基本确认：[adapt-wotlk-percent-health-defensive](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendskills/adapt-wotlk-percent-health-defensive/SKILL.md)

- 2026-09-07 位置条件单体控制（基本实机通过）：[adapt-wotlk-positional-single-target-control](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendskills/adapt-wotlk-positional-single-target-control/SKILL.md)；来源M6S2。

- 新增职业职责/专业许可（UI57/UI62用户确认）：[integrate-wotlk-custom-class-ui-eligibility](integrate-wotlk-custom-class-ui-eligibility/SKILL.md)

- [repair-wotlk-item-texture-references](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendskills/repair-wotlk-item-texture-references/SKILL.md) — 三项实测成功归档，2026-09-08。

- [adapt-wotlk-native-single-target-taunt](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendskills/adapt-wotlk-native-single-target-taunt/SKILL.md) — 三项实测成功归档，2026-09-08。

- [repair-wotlk-action-icon-tint-conflicts](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendskills/repair-wotlk-action-icon-tint-conflicts/SKILL.md) — 三项实测成功归档，2026-09-08。

- M6AC1基本实机反馈：[extend-wotlk-monk-skill-batches](D:\000rebornWOW\000RebornWOWHighForkPRO\beascendskills\extend-wotlk-monk-skill-batches\SKILL.md)；完整矩阵待测。

- [创建角色职业数组越界（用户确认）](repair-client-random-class-stack-capacity/SKILL.md)


## 2026-09-14 武僧本轮已验证流程

- [SKILL.md](<D:/000rebornWOW/000RebornWOWHighForkPRO/beascendskills/build-wotlk-three-build-projection/SKILL.md>)
- [SKILL.md](<D:/000rebornWOW/000RebornWOWHighForkPRO/beascendskills/audit-wotlk-shadowing-mpq-backups/SKILL.md>)
- [SKILL.md](<D:/000rebornWOW/000RebornWOWHighForkPRO/beascendskills/restrict-wotlk-custom-class-creation/SKILL.md>)

## 开发入口补充（2026-09-16）
新职业接入先读 [职业兼容Skill](integrate-wotlk-custom-class-ui-eligibility/SKILL.md) 与 [检查表](integrate-wotlk-custom-class-ui-eligibility/references/custom-class-preflight.md)。WD10B仅为待验收反例，未晋升成功；项目AGENTS.md负责提醒读取本库。

2026-09-16：integrate-wotlk-custom-class-ui-eligibility补充WD10C Details职业图标与默认头像基本显示经验；WD10D专业仅候选。

2026-09-16：build-portable-service-vendors补充WD12B巫医导师训练列表打开的限定验收；购买/重登未验收。WD14仅候选。


## 2026-09-17 WD16 巫医绑定方案（用户基本测试通过）
来源：000Ascendupdate/000Ascendupdate20260916/codexfix_202609162250_阶段WD16_方案绑定与付费完整洗点。用户原话：“测试可以了 现在继续下一步开发”。这是整体基本流程反馈，不等于逐项确认断线、故障恢复或全部收费边界。
巫医为独立存档方案，不改MAX_TALENT_SPECS。每套初选一个专精；其他页只浏览；已保存点禁止免费退点；10金币固定全洗（config可改）清本套点数和专精；其他方案保留；切已解锁完整方案免费恢复动作条。第二套1000金一次性，第三套config。不能恢复WD14混点或WD15一套内三个免费专精快照。
记录必须区分：用户基本通过、51项离线检查、未逐项实机验证边界。未来装备仓库未包含在此验收。


## 2026-09-17 EV1G限定成功：装备包双龙UI
用户截图EV1G并说“这个和coawow很搭了 很棒”。确认的是整窗双龙美术、背景后退和文字/装备可读性的视觉结果。来源：000Ascendupdate/000Ascendupdate20260917/codexfix_202609170211_阶段EV1G_背景退后与装备可读性。
适用于独立RebornEquipmentVault预览窗：FULLSCREEN_DIALOG与完整构建；整窗BORDER背景，当前BLP2/DXT1 1024方画布、有效UV(0,1,170/1024,853/1024)，左右暗罩.35/.50、人物区域.16、槽暗底.55、空图标alpha .65。复用已确认文件字节优先，不将PNG/TGA直接放入旧客户端。
只记录视觉成功，不扩展成存取、购买、整套换装、天赋联动已验证。EV2A服务端资格校验候选位于D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260917\codexfix_202609170239_阶段EV2A_装备原件与穿戴资格服务端校验，仍待实机。


## 2026-09-17 WD18 两处圆环实机通过

用户明确反馈“好的 修复好了”。来源：000Ascendupdate/000Ascendupdate20260917/codexfix_202609170357_阶段WD18_双面板圆环淡黑方底修复。
WD17只裁头像，圆环本身ClassPortraitRing的方形UV区域仍含淡黑方底。WD18对天赋Panel.lua和衣柜Vault.lua的圆环也几何裁圆：72显示尺寸、UV .25-.75、144个半单位水平条带（142有效），边缘宽度按条带较远边的圆方程计算。仅初始化创建，旧客户端无需现代MaskTexture，无资源重编码。
复用时同时检查图标和圆环/阴影两层；不能把圆环当成下层头像遮罩。验收仅限此次两个圆环方底消除，不扩展到装备存取或数据库故障保证。


- 2026-09-17 EV2C 基本存入闭环用户确认：[原装备衣柜](store-wotlk-original-equipment-in-wardrobe/SKILL.md)；详细异常矩阵未逐项验收。

- 2026-09-17 [EV2D逐件取回基本确认](store-wotlk-original-equipment-in-wardrobe/SKILL.md)；大退显示EV2D1修复待验收。

- [EV2D1自动补图基本确认](stabilize-spelldraft-client-ui/SKILL.md)，红问号展示EV2D3待验收。

- [EV2D7 OneBag拖回基本实测确认](store-wotlk-original-equipment-in-wardrobe/SKILL.md)，精确落格/交换未实现。

## 2026-09-17 EV2E 拖回继续实机确认
用户“好棒现在可以拖回去了 开始下一阶段的开发吧”。确认EV2E客户端下OneBag拖回基本闭环；未单独确认搜索框、按钮闪烁与所有异常矩阵。来源：000Ascendupdate/000Ascendupdate20260917/codexfix_202609170825_阶段EV2E_拖回反馈与天赋底栏优化。保持先清视觉拖影再检测目标、按实际OneBag控件与真实ID判定、服务器确认才改变原件位置。下一阶段EV2F整套存入仅候选。

## 2026-09-17 EV2F 整套存入基本实测确认
用户“好棒 可以了 给我继续下一步的开发 继续完善”，确认EV2F整套存入基本流程。来源：000Ascendupdate/000Ascendupdate20260917/codexfix_202609171718_阶段EV2F_身上整套装备依次存入。未逐项确认19槽、原件字段、满包、数据库故障等矩阵。
复用：服务端EQUIPPED数量快照与原GUID核对；ev3putw kind=3；原生卸装资格检查；提交后再移除身上原物品；客户端冻结GUID、刷新核对、逐件确认、占用槽跳过与中途停止。是逐件部分完成，不是整套原子换装。后续EV2G一键穿戴仍为候选，不包含本次验收。

## 2026-09-17 EV2G 一键穿戴基本实机确认
用户“好棒 可以了 继续下一步的开发”，确认EV2G基本流程。来源：000Ascendupdate/000Ascendupdate20260917/codexfix_202609171804_阶段EV2G_衣柜一键依次穿戴。未扩大到全19槽、双手/副手/满包、绑定和数据库故障全部边界。
复用：原GUID与旧装备GUID核对、CanEquip/CanUnequip、旧装备预留不同背包空位；新位置/正常穿戴绑定同事务，提交后原生更新内存/效果。逐件回执推进，不是整套原子切换。EV2H分页/改名/购买为候选，不继承本次验收。

## 2026-09-17 EV2H/EV2H1 结构补齐与基本显示确认
用户截图确认slot主键guid,wardrobe,slot、op.wardrobe默认1、unlock字段存在；随后游戏EV2H显示首柜自定义名“初始装备”、原装备和“衣柜已同步”。确认这些结构/显示，不确认付费购买、跨柜原件操作、重启持久化或异常矩阵。原动态迁移完整导入未加slot/op列的根因未复现；直接ALTER补列生效。不得沿用原脚本已实机成功的说法。
来源：EV2H、EV2H1及EV2H2阶段memory。当前补满6个序号仅候选，灰色编号不代表已解锁。


## 2026-09-17 EV2H2/EV2H3 多柜购买与分页基本实测确认
用户“搞定 可以下一步的开发啦”，EV2H2截图确认7/8/9已购、10柜报价、11/12未解锁占位及第二页；确认购买/分页与配置开启基本闭环。未扩展到重启持久化、全槽或事务故障矩阵。来源：codexfix_202609172014_阶段EV2H2_衣柜序号补满当前页、codexfix_202609172023_阶段EV2H3_补齐服务端衣柜配置覆盖包；验收记录：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260917\codexfix_202609172049_阶段EV2I_衣柜关联巫医天赋方案\memory.md。
复用：每页6个序号，未来编号只展示不能访问；真实owned和next报价由服务端确认。新增配置随包交付实际.conf，不能只给.dist或口头说明。当前实际conf每柜100金币，后续保留现场设置。EV2I天赋关联仅候选，不继承此次验收。

## 2026-09-18 EV2K1 人物绶带与Equipence共存：用户实机确认
用户反馈“好帅啊”并提供EV2K1人物/衣柜同屏截图：人物装备小绶带与外侧附魔图标错开；衣柜保留大绶带与穿戴中标记。验收限此次截图所示布局，不能推导所有UI缩放、满宝石槽、异常换装和持久化已通过。
来源：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260918\codexfix_202609180337_阶段EV2K1_人物绶带避让附魔宝石
实测图片：codex-clipboard-c143d94d-ca38-49d9-aa93-1641004faf78.png。
复用方法：先核对Equipence内联图标增长方向与装等底部锚点；人物使用格内顶部外侧角标（22×32缩放0.70），衣柜保留原大绶带。缓存复用且不接收鼠标；不要用提高层级去覆盖其他插件。人物100以上以#显示，完整编号见悬停。
永久Skill：beascendskills/stabilize-spelldraft-client-ui/SKILL.md；同名Tutor：beascendtutor/stabilize-spelldraft-client-ui/TUTOR.md。
衣柜建议冻结新增功能进入最终验收；仍需确认A/B往返归柜、新装备确认替换、重登/重启保存、背包满与战斗限制等场景。不标整模块最终完成。


## 2026-09-18 WD19A待实机验收资料（不属于已验证能力）

[技能等级链草案](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260918/codexfix_202609181708_阶段WD19A_巫医攻疗成长与分族训练/candidate_skill/port-wotlk-class-skill-ranks/SKILL.md)与[同批教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260918/codexfix_202609181708_阶段WD19A_巫医攻疗成长与分族训练/tutor.md)。17个新增等级、分族购买恢复；312离线断言和80资源检查，C++编译/实机/完整职业待完成。


## WD20A 候选延伸（待实机，不属于已验证能力）

Spirit Wuju四等级、Lethargy Jinx、私有同组互斥；300离线断言及64资源闭包。复用trace-and-port-coa-spell-resources方法，等待用户编译/实测。来源与教程：[codexfix_202609181807_阶段WD20A_巫医灵魂增益与诅咒控制](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260918/codexfix_202609181807_阶段WD20A_巫医灵魂增益与诅咒控制/tutor.md)。


## WD21A 候选延伸（尚未实机验收）

蛇之守卫基础召唤、目标与生命周期；复用trace-and-port-coa-spell-resources及repair-multiclass-summon-lifecycle方法。212离线检查、25资源闭包；不继承旧宠物已验证结论。候选教程：[codexfix_202609181956_阶段WD21A_蛇之守卫召唤与攻击](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260918/codexfix_202609181956_阶段WD21A_蛇之守卫召唤与攻击/tutor.md)。


## 2026-09-18 EV2Q / WD21A 用户基本实测确认

用户原话：“这次可以了 衣柜这样的设计好多了 同时 蛇之守卫也很不错 继续开发下一阶段的技能吧”。确认衣柜此次交互设计/恢复流程和蛇之守卫基本使用得到正面实测反馈。未据此宣称数据库故障、跨地图全部边界或30级后伤害平衡已逐项验收。

- 衣柜来源：[EV2Q说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260918/codexfix_202609181850_阶段EV2Q_售出装备旧归属恢复与替换/README_覆盖与测试说明.md)。
- 守卫来源：[WD21A说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260918/codexfix_202609181956_阶段WD21A_蛇之守卫召唤与攻击/README_覆盖与测试说明.md)。现场累计源码和服务端DBC与WD21A交付逐项一致。
- 下一阶段WD22A候选不继承本次实测结论；历史ZIP保持原字节与哈希不变。


## WD22A 治疗守卫候选（待实机）

225项离线检查；支持组队Playerbot/NPCBot，未继承前批验收。教程：[codexfix_202609182136_阶段WD22A_治疗守卫与同类召唤互斥](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260918/codexfix_202609182136_阶段WD22A_治疗守卫与同类召唤互斥/tutor.md)。


## WD23A 力量巫祝候选（待实机）

六级成长及双巫祝互斥，288离线检查，不晋升已验证。教程：[codexfix_202609182256_阶段WD23A_力量巫祝六等级与增益互斥](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260918/codexfix_202609182256_阶段WD23A_力量巫祝六等级与增益互斥/tutor.md)。


## UIV1 用户实测通过：加载期语音API保护

用户反馈“继续开始下一步的技能修复 测试这个通过”，承接UIV1。确认组队reload报错修复基本通过，不扩展到全部语音场景或巫医技能验收。
来源：[codexfix_202609182326_阶段UIV1_队伍头像语音API缺失保护](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260918/codexfix_202609182326_阶段UIV1_队伍头像语音API缺失保护/README_覆盖与测试说明.md)。FrameXML早于插件，插件shim不能保护此前调用；应在调用点type检查并短路，保留真实函数。缺失状态用false，Lua中0为真。27项离线检查与用户实测分别记录，历史ZIP不变。


## WD24A 节能巫祝候选（待实机）

122离线检查，5%标准资源减耗、巫祝互斥，视觉procedural8降级已记。教程：[codexfix_202609182337_阶段WD24A_节能巫祝与资源消耗适配](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260918/codexfix_202609182337_阶段WD24A_节能巫祝与资源消耗适配/tutor.md)。


## WD25A 希里克诅咒候选（待实机）

163离线检查，私有PvP8秒上限及Jinx互斥，41资源闭包，未晋升已验证。教程：[codexfix_202609182359_阶段WD25A_希里克诅咒与野兽恐惧](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260918/codexfix_202609182359_阶段WD25A_希里克诅咒与野兽恐惧/tutor.md)。


## WD26A 法力诅咒候选（待实机）

166离线检查，原生周期吸取与回复抑制，先安装WD25A，待实机。教程：[codexfix_202609190014_阶段WD26A_法力诅咒周期吸取与回复抑制](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260919/codexfix_202609190014_阶段WD26A_法力诅咒周期吸取与回复抑制/tutor.md)。


## WD24A 节能巫祝：用户基本实测通过（2026-09-19）

用户明确反馈“节能巫祝 这个测试通过了”。仅确认本批基本使用通过，不推定全部资源类型、机器人边界或视觉完全一致；WD25A希里克诅咒仍在编译测试，WD26A法力诅咒待验收。
来源：[WD24A](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260918/codexfix_202609182337_阶段WD24A_节能巫祝与资源消耗适配/README_覆盖与测试说明.md)，[逐步教程](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260918/codexfix_202609182337_阶段WD24A_节能巫祝与资源消耗适配/tutor.md)。ZIP SHA256：`8cb71fa29d2c2bdf55805b17511e8cb0c2428c172e06a2c0a3d057b18cc61d4f`，历史交付文件未改写。
复用要点：原生Aura72按七学派费用倍率实现5%标准资源减耗；费用计算应核对最终扣除路径，不把自定义扣费、符文槽或全资源清空泛化为支持。清除本地不支持且上游为空实现的Effect168时同时清空对应参数。未确认的procedural8视觉参数组关闭仍是已知降级，用户基本通过不能抹去该限制。
永久流程：[Skill](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendskills/trace-and-port-coa-spell-resources/SKILL.md)；[同名Tutor](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendtutor/trace-and-port-coa-spell-resources/TUTOR.md)。


## WD27A 缩小诅咒候选（待实机）

366离线检查，原生效果拆分和type2生命周期，先25→26→27；未实机验收。教程：[codexfix_202609190033_阶段WD27A_缩小诅咒六等级适配](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260919/codexfix_202609190033_阶段WD27A_缩小诅咒六等级适配/tutor.md)。


## WD25A / WD26A 用户基本实测通过（2026-09-19）

用户明确反馈“希里克诅咒 法力诅咒 测试通过”，两批登记基本成功；不推定野兽形态PvP完整递减、全部机器人及空蓝/满蓝等边界均已验收。缩小诅咒WD27A正在编译测试，仍为候选。

复用要点：恐惧持续上限必须在原生递减之前按准确私有ID限制；野兽目标限制不能扩大到全部玩家。周期吸取先确认触发施法者归属，原生Effect8按实际扣到的法力返还，不能按理论值凭空回蓝；自然回复抑制不等同禁止药水和主动补蓝。

来源：[WD25A覆盖说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260918/codexfix_202609182359_阶段WD25A_希里克诅咒与野兽恐惧/README_覆盖与测试说明.md)，[详细教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260918/codexfix_202609182359_阶段WD25A_希里克诅咒与野兽恐惧/tutor.md)。原ZIP SHA256 `364e38ee4143f222615bd3a5e2bd3a91a7e885037a9fd5bc060428cf88ec1d3b`，未改写旧包。

来源：[WD26A覆盖说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260919/codexfix_202609190014_阶段WD26A_法力诅咒周期吸取与回复抑制/README_覆盖与测试说明.md)，[详细教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260919/codexfix_202609190014_阶段WD26A_法力诅咒周期吸取与回复抑制/tutor.md)。原ZIP SHA256 `c3389f2032ba6f18be4cf99d755ea7e87a75be3428632e95e3f720c8cea386dc`，未改写旧包。

永久流程：[Skill](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendskills/trace-and-port-coa-spell-resources/SKILL.md)，[同名Tutor](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendtutor/trace-and-port-coa-spell-resources/TUTOR.md)。


## WD28A 破咒术候选（待实机）

138离线检查，原生驱散及机器人目标规则，待实机。教程：[codexfix_202609190139_阶段WD28A_破咒术友方诅咒驱散](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260919/codexfix_202609190139_阶段WD28A_破咒术友方诅咒驱散/tutor.md)。


## WD27A 缩小诅咒：用户基本实测通过（2026-09-19）

用户反馈“上一个包检测通过 我来测试破咒术”，承接WD27A缩小诅咒。登记基本使用成功，不外推所有跨施法者、下线或特殊物理法强边界。WD28A破咒术仍待实机验收。
来源：[WD27A](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260919/codexfix_202609190033_阶段WD27A_缩小诅咒六等级适配/README_覆盖与测试说明.md)，[逐步教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260919/codexfix_202609190033_阶段WD27A_缩小诅咒六等级适配/tutor.md)，原ZIP SHA256 `d27366846698374844d442d2935ae0d170e5f01871f7cff647200a1a4b57f82b`，未改写。
复用经验：CoA344同时影响近战/远程AP，345涉及伤害/治疗法强；WotLK三个效果槽可拆主/辅助并用原生type2关联管理生命周期。辅助隐藏、同持续时间、不进技能书，清除必须保留施法者GUID。魔法伤害掩码126避免改动白字伤害；物理技能吃法强仍是已知适配边界，不能因基本通过而抹去。
永久流程：[Skill](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendskills/trace-and-port-coa-spell-resources/SKILL.md)，[Tutor](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendtutor/trace-and-port-coa-spell-resources/TUTOR.md)。


## WD29A 万灵药候选（待实机）

163离线检查，三类净化与短时免疫，待实机。教程：[codexfix_202609190159_阶段WD29A_万灵药净化与短时免疫](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260919/codexfix_202609190159_阶段WD29A_万灵药净化与短时免疫/tutor.md)。


## WD29A 万灵药：用户基本通过反馈（2026-09-19）

用户在WD29A交付后反馈“测试通过可以进行下一步的开发”，记录基本使用通过。现场审计发现模块源码仍为WD28A、服务端DBC已是WD29A；因此不能据此宣称此目录WD29A源码已编译或全部资格校验已验收。后续累计包补齐已知WD29A源码，保留该版本证据边界。
来源：[WD29A](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260919/codexfix_202609190159_阶段WD29A_万灵药净化与短时免疫/README_覆盖与测试说明.md)，[教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260919/codexfix_202609190159_阶段WD29A_万灵药净化与短时免疫/tutor.md)；原ZIP `fbec4b7cf961eea57b8b835c8c87a311e434b653acb7200100a0beca068ac472` 未改写。
复用经验：Aura41按Misc4/3/2提供类型免疫，AttributesEx0x8000清除旧效果，ApplyAllSpellImmunitiesTo在apply=false撤销免疫；这采用免疫净化移除语义，不等于Effect38的逐次驱散和AfterDispel。持续读Duration表，不能将BasePoints9+1误作10秒。
永久流程：[Skill](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendskills/trace-and-port-coa-spell-resources/SKILL.md)、[Tutor](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendtutor/trace-and-port-coa-spell-resources/TUTOR.md)。


## WD30A 夺回灵魂候选（待实机）

400离线检查/21资源；原生复活与两类机器人适配，待编译和实机。教程：[codexfix_202609190319_阶段WD30A_夺回灵魂复活技能](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260919/codexfix_202609190319_阶段WD30A_夺回灵魂复活技能/tutor.md)。


## WD31A 暗影化身候选（待实机）

156离线检查/25资源；原生急速与暗影减伤，待编译实机。教程：[codexfix_202609190351_阶段WD31A_暗影化身急速与暗影减伤](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260919/codexfix_202609190351_阶段WD31A_暗影化身急速与暗影减伤/tutor.md)。


## NAGAF1 外观引用候选（待实机）

借用纹理引用核对方法，41行/7贴图，未晋升成功案例。[教程](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260919/codexfix_202609190427_阶段NAGAF1_娜迦NPC脸部资源修复/tutor.md)。


## WD32A 强效节能巫祝候选（待实机）

136离线检查/8资源；团队5%减耗和Wuju互斥，待实机。[教程](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260919/codexfix_202609190440_阶段WD32A_强效节能巫祝团队减耗/tutor.md)。


## WD33A 群体巫祝合并候选（待实机）

215离线检查，新灵魂/力量及已有节能互斥回归。未编译/实机；[教程](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260919/codexfix_202609190554_阶段WD33A_强效灵魂巫祝团队精神抗性/tutor.md)。


## WD33B 低等级受益候选

WD33A暴露25级队友无法收灵魂/力量；局部修复仍待编译实机。[教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260919/codexfix_202609190752_阶段WD33B_强效巫祝低等级队友切换修复/tutor.md)。

- 2026-09-20：repair-multiclass-summon-lifecycle补充WD36实测：27/80级Playerbot回蓝4%，27级回血+50；正式参数恢复与WD37B暴击仍待测。证据：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260920\codexfix_202609200724_阶段WD37B_图腾正式设置与恶意妖术周期暴击

- 2026-09-20本窗口复盘：store-wotlk-original-equipment-in-wardrobe；EV2Q基本恢复通过，O3弹窗失败反例，满包/原GUID/事务故障仍需分项验收。 [01_精品衣柜从原件到可靠队列.md](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260920/codex总结_202609201927_本窗口修复复盘教学与新任务交接/教学/01_精品衣柜从原件到可靠队列.md)

- 2026-09-20本窗口复盘：repair-multiclass-summon-lifecycle；27/80级Playerbot回蓝、27级治疗已有日志；WD38A抗性神像和正式恢复仍待实机。 [03_回血回蓝图腾的三只钟.md](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260920/codex总结_202609201927_本窗口修复复盘教学与新任务交接/教学/03_回血回蓝图腾的三只钟.md)

- 2026-09-20本窗口复盘：trace-and-port-coa-spell-resources；已验证方法复用；WD34/35/37/38不因整批交付而提升成功状态。 [02_巫医职业与技能等级链.md](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260920/codex总结_202609201927_本窗口修复复盘教学与新任务交接/教学/02_巫医职业与技能等级链.md)

候选未晋升：女武神配置 [SKILL.md](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260920/codex总结_202609201927_本窗口修复复盘教学与新任务交接/候选Skills/configure-ale-auto-resurrection/SKILL.md)；真实怪物击杀关/开测试待确认。


## WD38A 用户实测通过（2026-09-20 本次新任务反馈）
用户原话：“WD38A 测试通过，继续巫医下一批技能”。登记合包基本实测通过：黑暗/丛林神像、原图腾正式参数恢复、恶意妖术8技能等级周期暴击。没有逐项日志的新反馈不扩展为所有等级、双施法者、真人/两类机器人全矩阵已完成；120级历史异常未归因。
来源：[WD38A覆盖说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260920/codexfix_202609200757_阶段WD38A_神像同机制批量与恶意妖术合包/README_覆盖与测试说明.md)，原ZIP SHA256 `4c1cd57f31f5db2e024f03d2b3a861fab37ce8d55b4129ae3e177d02dffa3bfa`；旧包不改写。验收承接档：[WD39A](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260920/codexfix_202609201949_阶段WD39A_宁静神像抗施法打退/memory.md)。
可复用方法：同机制神像配置驱动，共用Idol槽而独立于Ward；刷新2.2秒短Aura，按ownerGUID撤销，原生Aura143处理抗性取强。Hex应用/刷新快照暴击率，核心逐跳掷骰与倍率；rank是技能等级，不是人物等级。
永久流程：beascendskills/trace-and-port-coa-spell-resources、repair-multiclass-summon-lifecycle及各自同名Tutor。本次下一批宁静神像仍是候选，不继承此次验收。


## WD39A 宁静神像基本实测通过（2026-09-21）
用户明确“宁静神像 测试可以的”，随后继续测并索要方法；登记基本使用通过，不扩大为读条/引导、低等级及两类机器人全部专项验收。复用Idol槽、2.2秒短Aura、按owner清理和原生Aura149。来源：D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260920/codexfix_202609201949_阶段WD39A_宁静神像抗施法打退；下一批WD40不继承验收。


## 2026-09-21 WD40A 哨戒守卫基本实测通过
用户明确“哨戒守卫 测试通过 可以看到他盗贼的隐身”。确认盗贼潜行揭露；其他类型隐形、范围/LOS、双施法者、两类机器人等未逐项确认。WD41A暗影雕像继续候选。
[验收记录](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260921/WD40A_哨戒守卫实测验收记录.md)；[来源包说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260921/codexfix_202609210144_阶段WD40A_哨戒守卫潜行隐形揭露/README_覆盖与测试说明.md)。


## 2026-09-21 WD41A 暗影雕像基本实测通过
用户明确“暗影雕像 雕像也测试通过了”，登记基本通过，不扩大为全部范围/免疫/双施法者与机器人矩阵。保留独立Effigy槽、单次召唤、单Aura双减速经验。
[来源](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260921/codexfix_202609210329_阶段WD41A_暗影雕像施法与移动减速/README_覆盖与测试说明.md)。WD42恢复合包，仍为候选。


## 2026-09-21 WD42A 墓刻通过、妖术机制通过及外观回归
用户确认墓刻雕像基本实测通过；妖术雕像敌方法师直接攻击主人会变青蛙，攻击雕像不触发符合既定规则。妖术模型名字和受击点明显过高，WD42A外观验收存在回归，不能记为完整成功。其他PvP递减、伤害解除、两类机器人、范围/LOS、替换全部边界未逐项验收。
已验证子集：墓刻指定控制加时基本使用；妖术显式敌方法术打主人触发一次，攻击雕像不触发。WD42B高度补丁仅为候选，不能晋升其模型烘焙方法为已验证。
来源：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260921\codexfix_202609210728_阶段WD42A_妖术与墓刻雕像合包\README_覆盖与测试说明.md
回归修正：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260921\codexfix_202609211610_阶段WD42B_妖术雕像高度与日志排查\README_覆盖与测试说明.md


## 2026-09-21 WD42B 妖术雕像高度修复用户实测通过
用户明确“测试这个妖术雕像 修复 通过”。承接WD42B，确认名字/受击点高度修正基本通过；此前墓刻及青蛙触发已基本通过。不能据此确认LOG42C两项红字、亡者大军缺失模板、root心跳或骸骨问题均已修复。
已验证方法：仅限本只静态建筑雕像，M2顶点/骨pivot/包围盒/碰撞与SKIN中心半径统一缩0.1，显示倍率恢复1，双端私有ModelData补高度；带动画或粒子模型不可直接套用。
来源：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260921\codexfix_202609211610_阶段WD42B_妖术雕像高度与日志排查\README_覆盖与测试说明.md
本批WD43A仍为候选。


## 2026-09-21 WD43A诅咒雕像与迅捷神像基本实测通过
用户反馈“测试通过”，随后请求诅咒雕像适度放大。登记两项基本使用通过，不扩大为全暴击路径、全部等级与机器人矩阵均已完成；外观放大为新候选。保留私有标记9003431、原生暴击最终判定与周期快照分离方法；迅捷采用原生移速/定身减速抵抗，25%不是免疫。
[来源](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260921/codexfix_202609211700_阶段WD43A_诅咒雕像与迅捷神像合包/README_覆盖与测试说明.md)，原ZIP SHA256 f9956e87660532f6a6d363a2773fe1b56296fe9cb6682bb597243943abb42dce。


## 2026-09-21 WD44A两项净化技能用户基本实测通过
用户原话：“继续下一批的技能开发吧 这两个通过”。确认净化神像、群体万灵药基本使用通过；不扩展为所有机器人/驱散抵抗/共享冷却边界全部验收，也不将这句话单独当作诅咒雕像1.6倍外观确认。
可复用方法：净化首跳3秒与间隔3秒，原生Effect38疾病/毒各1；群体版原生Aura41免疫净化3秒，ownerGUID召唤生命周期，已学群体版时共享万灵药冷却。本地独立导师入口与成长JSON编号冲突仍是适配边界。
[来源](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260921/codexfix_202609211832_阶段WD44A_净化同机制技能与诅咒雕像尺寸优化/README_覆盖与测试说明.md)，原ZIP SHA256 d149501fc4876f2d19244dc81465d1bf2e3139ec63258c1ad8f18a7ee4bbedb0。


## 2026-09-21 WD45A静滞守卫与穆厄扎拉之触基本实测通过
用户明确：“上面的技能测试通过 继续下一批的技能开发吧”。承接WD45A两项技能，登记基本使用通过；不扩大为所有等级、伤害系数、PvP递减、双施法者及机器人完整矩阵。此前登录提示后用户说明MPQEditor未关闭，不归因为已证实的技能代码缺陷。
可复用：单次2秒延迟爆发、先标记fired再施法、守卫销毁/替换取消；私有精确SpellID加时置于原生递减前，避免与原family Aura107重复。
[来源](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260921/codexfix_202609211948_阶段WD45A_静滞守卫延时爆发与昏迷/README_覆盖与测试说明.md)，原ZIP SHA256 d801be4a0fa7cafb12e148d3744ec48016f8adc865c6fc1773ca62bc7aa327cc。


## 2026-09-22 WD46A＋WD46B用户基本实测通过
用户明确：“继续开发下一批的技能 这两个技能通过”。确认瓶中之灵、灵魂之触基本使用通过，承接WD46B技能书显示修正；不扩大为8rank/所有机器人/范围/吸收完整矩阵。
复用：AfterHit读有效治疗；复制伤害排除二次法强和暴击；治疗目标作为范围/LOS中心；已学记录与客户端隐藏位分开审计。可学习被动保留0x40而清0x80，勿清整个Attributes。WD46A原隐藏位漏检为已纠正反例。
[WD46A](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260921/codexfix_202609212147_阶段WD46A_瓶中之灵与灵魂之触/README_覆盖与测试说明.md)，ZIP fbf6372f071b87b038930568508e54eb5491c9f369a183ac259572168f1e2e4c；[WD46B](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260922/codexfix_202609220100_阶段WD46B_灵魂之触技能书显示/README_安装说明.md)，ZIP d58326291f09bba809719cd88533db5afe8dfb8129b9840e62f123d82564b55b。


## 2026-09-22 WD47A两项用户基本实测通过
用户明确“好的 这2个技能通过了 继续下一批的技能修复移植吧”。洛阿祝福和丛林秘法按基本通过登记；另有截图9003482贝瑟克的凶猛剩余13秒，直接证明祝福触发与显示。未将一句通过扩展为所有机器人、80码边缘、多巫医及生命周期完整矩阵。
复用：从AfterHit有效回血触发；单独追加父法术脚本，不受旧前一目标提前return影响；隐藏复制治疗OnHit恢复固定值后仍原生吸收/过量，不能假定伤害忽略标志适用于治疗；原生Aura20秒属性还原；可学习被动清隐藏位。雕像GUID查现存对象和归属，Ward/Idol不误触发。
[来源包](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260922/codexfix_202609220121_阶段WD47A_洛阿祝福与丛林秘法/README_覆盖与测试说明.md)；[教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260922/codexfix_202609220121_阶段WD47A_洛阿祝福与丛林秘法/tutor.md)；ZIP SHA256 15afe7af51f019d13e598f94bfc5c7af45b35ff835c78dac1e4a72b4ea2e494a。新WD48不继承验收结论。


## 2026-09-22 WD49A用户基本实测通过
用户明确反馈“好的 可以了技能都动过了 任务书籍显示也正常”。登记侵蚀之夜、金度之怒及本合包修正基本通过；不外推全等级概率统计、所有三方案/动作条边界和所有机器人均已验证。
复用：原生Aura107/108配精确私有技能家族匹配；被动清隐藏位；同一donor先查旧天赋与完整模块，不只看Ranks.h；旧ID保留为等级链起点，购买账本不删，旧别名在动作条恢复时归一。物品23338与任务9373分别核对：物品2047是旧职业位集合，-1不限；任务0不限，不能混用，不能全库开放职业专属书。
来源：[覆盖包](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260922/codexfix_202609220521_阶段WD49A_侵蚀之夜与金度之怒合包/README_覆盖与测试说明.md)，[教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260922/codexfix_202609220521_阶段WD49A_侵蚀之夜与金度之怒合包/tutor.md)。ZIP cdf7113bbece94dc22be53a4f420a308fcc5cbfb9f6e36db73303102e8b686a0。


## 2026-09-22 WD50A 用户基本实测通过
用户明确反馈恶性蔓延、妖术迸发通过。登记9003520传播自己的恶意妖术与9003521触发6秒20%施法急速基本使用通过；不扩大为全部概率统计、双施法者、低等级/机器人/边界距离矩阵已完成。
复用：传播保留持续时间、下一跳计时、伤害数值、暴击概率快照；按owner过滤并排除重复挂同源Hex。原生伤害暴击proc产生Aura216，刷新而非叠层；施法急速不是直接把读条乘0.8。来源[WD50A说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260922/codexfix_202609220700_阶段WD50A_恶性蔓延与妖术迸发/README_覆盖与测试说明.md)、[教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260922/codexfix_202609220700_阶段WD50A_恶性蔓延与妖术迸发/tutor.md)。原ZIP SHA256 64185c8f2e9b1892487152000a01593146202d3c4bbd66d9224263e9be1800de，历史包不改写。
用户同时报告WDUI1A三槽不显示，UI故障不撤销两被动的基本验收。WDUI1B/C为另一个客户端UI修正，待实机。


## 2026-09-22 WD51A＋WD51B用户基本实测通过；WD52全量审计
用户反馈“测试已通过，继续下一阶段的技能开发”，确认恶意滋长9003530与毒蛇守卫狂暴9003532基本使用通过，承接WD51B IsHex编译修正。不扩大为概率统计、双施法者、重召/洗点完整矩阵。
来源：000Ascendupdate/000Ascendupdate20260922/codexfix_202609221910_阶段WD51A_恶意滋长与毒蛇守卫狂暴，ZIP SHA256 92713d790d11873860b9d767e532aad5695f0e6ed8a5b20ba9a23066fe40de86；WD51B包 codexfix_202609221955_阶段WD51B_恶意滋长IsHex编译修正，ZIP SHA256 cd80c2c282faec770b8d1c8868be1a587b77372f5c86fcb759dbb6b36e8f8a30。历史包不改写。
复用：按施法者归属隔离周期增伤；先结算本跳再叠层影响下一跳；毒蛇守卫按自己当前召唤GUID和entry过滤，使用时间进度实现急速，不能改动治疗守卫。IsHex反例：存在调用不等于声明存在，必须核对当前头文件API。
教学：恶意滋长像同一个人的下一次结账折算，不能算到旁人账上；守卫急速改变计时器走快的速度，换新守卫不能凭旧GUID继承状态。结合原包tutor.md和WD51B差异读真实代码；用户这次确认基本效果，不把离线测试当全场景实测。
WD52审计见 [审计结论](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260922/WD52_巫医全技能与天赋分类审计/审计结论与下一阶段.md)：48技能族，配套天赋目录159节点，16有本地效果/映射，143尚未匹配，2真实学习节点、157未接入；分类与完整天赋尚未部署。不能以旧JSON403条或上游175 SpellID直接减48。下一阶段转按树开发并接入学习规则。


## 2026-09-23 WD53A 用户基本实测通过
用户明确“继续下一期的技能开发 技能测试通过”，承接洛阿仪式9003540与灵魂回收9003541，记录两项基本使用通过；不外推全部返蓝概率/边界、断线消息时序、多角色/机器人测试已完成。
来源：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260923\codexfix_202609230218_阶段WD53A_洛阿仪式与灵魂回收；ZIP SHA256 173b1590e210a8e8ab4842508167b440f05e94e14864f7c14deacf36576029fb。历史包不改写。
复用：独立召唤槽用GUID与owner校验，成功召唤保存实际费用收据，先消费收据再清理；选择消息只同步本人已学类别，正式施法仍由安全按钮和服务器法术系统发起。两项主动技能同时接导师、书页分类、学习账本和重登，不只增加插件按钮。
教学：参见来源包tutor.md。把三类召唤物看成三张独立收据，回收只结算当前活着且归自己的对象；不能把萨满原生图腾数组当成自定义召唤槽。


## 2026-09-23 WD54A 天生炼金师自动补学基本验收
用户更新运行目录EXE并重启后明确回复“有了”。确认天生炼金师9003550已出现/成功补学，基本学习接入通过；不外推炼金术实际+15、遗忘/重学专业、全部新老角色与其他种族完整矩阵已测。
此前新老巫医没有技能且IsSpellKnown=false：当前源码及双端DBC已03:49更新，编译输出04:22，而运行目录EXE仍03:18、进程03:24启动。复制新编译EXE到运行目录并重启后用户确认出现。代码/DBC在磁盘存在不等于当前进程已加载；先比较编译输出、部署文件与进程启动时间，不反复覆盖客户端或强学技能掩盖版本差异。
来源包：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260923\codexfix_202609230330_阶段WD54A_酿造基础被动天生炼金师；原ZIP SHA256 c003a75a74c3d5466a3c0d4646b30ab62da6054f815caea6052f5342953bda12。历史包不改写。
排查教学：[运行版本核对](000Ascendupdate/000Ascendupdate20260923/WD54A_自动学习未生效排查.md)。永久方法：beascendskills/trace-and-port-coa-spell-resources/SKILL.md；同名教学：beascendtutor/trace-and-port-coa-spell-resources/TUTOR.md。源包tutor.md保留完整Aura98及学习接入教学。
WD55A暗影烈焰仍待单独安装/实测，不继承本次验收。


## 2026-09-23 WD55A 暗影烈焰基本实测通过
用户明确“暗影烈焰 测试通过”，记录该技能基本使用通过；不扩大为全部13等级、系数统计、灵魂所有叠层/回复/双施法者/死亡边界完整验收。WD56A大巫毒仍由用户测试，不能继承通过。
来源包：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260923\codexfix_202609230419_阶段WD55A_暗影烈焰与击杀灵魂；ZIP SHA256 5d8c153cd3ab8a05fb026c1b6f527e5820b8edd72eb3b99e4b8a75256e392bc5。原包不改写。
可复用方法：当前父技能说明与上游把旧触发式改为直接伤害的实现一起核对；旧子技能残留周期描述不优先。手工35%暗影SP+10%RAP与SQL默认系数归零成对，击杀收益在AfterHit；Spirit原生Aura24/8、叠层和生命周期。Spell字段37/38/39是MaxLevel/BaseLevel/SpellLevel，必须读当前结构定义。灵魂环绕球Issue270仍未解决，不因本次通过宣称修复。
教程：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260923\codexfix_202609230419_阶段WD55A_暗影烈焰与击杀灵魂\tutor.md。永久Skill/Tutor为trace-and-port-coa-spell-resources。下一批按酿造基础缺口及完整物品取用依赖推进，不把新增基础技能等同正式天赋节点开放。


## 2026-09-23 WD56A 大巫毒基本使用与外观实测通过
用户明确“大巫毒 好帅 测试通过”，确认基本玩法及召唤外观；不扩大为全部PvP、跨队伍、死亡/地图/断线和锁定边界验收。来源包：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260923\codexfix_202609230541_阶段WD56A_大巫毒防护领域；ZIP SHA256 fdcfcaaa3c9fbd888059f7127498f8a13e30fea178ca1b488ee2f588591e0787，历史包未改写。
可复用经验：独立召唤GUID不占三类槽；600ms防护租期配合250ms刷新、按施法者GUID清理；原生免疫期间施加衰退限制需NO_IMMUNITIES，不能取消限制绕过保护。克隆完整模型/贴图/皮肤链，并补全creature_template_model和creature_model_info。官方当前说明与旧版本数值冲突时固定来源，不能混用。教程：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260923\codexfix_202609230541_阶段WD56A_大巫毒防护领域\tutor.md。永久Skill和同名Tutor：trace-and-port-coa-spell-resources。下一批WD57A魔精大锅仍为开发候选，不继承本次通过。


## 2026-09-23 WD57A/B魔精大锅与WD58A空灵之魂基本实测通过
用户明确“2个技能包 都测试通过”，承接大锅（含WD57B编译修正）和空灵之魂。记录基本玩法成功，不推定25次并发、跨队伍、概率统计及全等级所有边界完成。历史ZIP保持不变。
来源：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260923\codexfix_202609230706_阶段WD57A_魔精大锅与团队取用；SHA256 5954af9861dc54098a93a6d369f2b03b424dbfc8f1f9e72d9af96519c94895c3；教学：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260923\codexfix_202609230706_阶段WD57A_魔精大锅与团队取用\tutor.md
来源：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260923\codexfix_202609230824_阶段WD57B_魔精大锅编译接口修正；SHA256 186e96c795b97fb0d8d37179311e03d9dcbf8fec2bc28656c1ace5d5b5a2e12d；教学：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260923\codexfix_202609230824_阶段WD57B_魔精大锅编译接口修正\tutor.md
来源：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260923\codexfix_202609231650_阶段WD58A_空灵之魂暴击易伤；SHA256 f2443c22092def4c1dc72698f3bc84194683c756c3acfda8812c95051ed81fe6；教学：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260923\codexfix_202609231650_阶段WD58A_空灵之魂暴击易伤\tutor.md
复用：原生Effect50保存大锅owner，type22按成功施法计次，额外拦25次和非READY窗口；读取当前GameObject.h确认getLootState大小写，不凭接口习惯猜。空灵之魂用伤害后钩子、真实伤害值和每个AOE目标分别判断，原生Aura197表达目标暴击易伤；临时导师入口不同于正式天赋加点。
用户要求提高效率：后续优先按共同依赖组成3—4项完整功能合包，不再默认一个技能一包；不可把同技能等级或隐藏触发子法术凑成多个技能。


## WD62A 用户基本实测通过（2026-09-24）

用户在WD62交付后明确“测试通过”，登记黑暗魔精、睿智、洛阿之力基本通过。不外推所有随机抵抗、全种族/机器人及PvP边界，不把此前1HP恢复当成源码根因修复。

复用要点：Aura178是符合Dispel1/2负面光环的抵抗路径，同类正值取强，不是所有魔法伤害减20%；Aura72费用字段与原生最大法力132、总属性137分别计算；学派40是自然+暗影，属性1是敏捷。保留双端独立母版与旧记录，剔除官方描述未说明的第三dummy时明确记录。书页9006是巫医暗影狩猎，9003是武僧织雾。

来源：[WD62说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260923/codexfix_202609232343_阶段WD62A_防护与属性三被动合包/README_覆盖与测试说明.md)；[教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260923/codexfix_202609232343_阶段WD62A_防护与属性三被动合包/tutor.md)。历史ZIP不改写，SHA256 b6a91e84d761bc13325108d6f46afdcec3e8f891753c1286370657493d8a41e4。WD63仍待测。


## NPCMOUNT1 已验收：M2动画表与扩展表头重叠
[Skill](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendskills/repair-wotlk-m2-sequence-header-overlap/SKILL.md)；用户反馈骑马正常。只适用已确认二进制重叠，不能泛用于所有滑行。


## 2026-09-24 WD63E 灵魂神像135秒客户端同步实测通过
用户截图GetSpellCooldown(9003370)输出134.999、133.917000000002：总时长约135秒，与180秒减少25%一致。结合此前WD63D的learned1/aura1/op11/type108/value-25/match1及服务器剩余132800ms，登记WD63E灵魂神像单放的客户端冷却同步基本实测通过。
本次不扩大为一键三放、14召唤族、所有职业、事件冷却或到期再次施放全矩阵已验证。Tooltip仍显示基础3分钟，未做动态说明修正。
复用经验：只对精确匹配服务器Hastened修饰的施法，在SpellGo后清客户端该技能计时，再发送服务器实际剩余毫秒；不删除服务器CD、不再次乘75%、不改GCD。此测试支持该校正有效，但未做客户端抓包，不能声称已直接观测到客户端内部覆盖顺序。

来源包：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260924\codexfix_202609240755_阶段WD63E_迅捷召唤客户端冷却后置同步.zip
SHA256：5f4ed3e7c425936875e10626e1bb00a949dbc35e080c8d743932cd0ba7096703
教学：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260924\codexfix_202609240755_阶段WD63E_迅捷召唤客户端冷却后置同步\tutor.md


## 2026-09-24 WD67C 悬停同步基本实测通过
用户明确“这下点击就同步了”。确认点击天赋后、鼠标不移开也实时更新Tooltip；不扩大为收费重置、全部技能收益/双语、关闭页/其他Tooltip矩阵已验收。来源D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260924\codexfix_202609242013_阶段WD67C_天赋悬停实时刷新与加点收益对比，ZIP SHA256 4d1de527e2dfd3c3034c428f95f78014943851ce97a6e0c2923a5848c2fb5531。
复用：M.changed末尾刷新当前可见且仍拥有GameTooltip的按钮，OnLeave/OnHide清理；草稿与服务器已保存分开展示，不把预览当作已生效。
永久方法：beascendskills/build-wotlk-three-build-projection/SKILL.md；同名Tutor/WD67C-hover.md。下一批WD68候选不继承验收。


## 2026-09-25 WD68 傀儡师之线基本保存效果用户确认
用户针对“但还不能据此确认保存后的技能效果”回复“现在测试可以的了”，只登记傀儡师之线保存后基本效果可用。不扩展为15%全部数值统计、双施法者/死亡/切方案生命周期，也不扩展为拟态守卫与暗影傀儡战斗通过。用户随后截图暗影傀儡1/1未保存，仅证明选择流程。
来源：000Ascendupdate20260924/codexfix_202609242135_阶段WD68A_巫毒分支前置与技能整合，ZIP SHA256 bff01b041a0fc947d21129059dabbc54526ce483ac168bbcc84e74e0df9db554；承接次日WD68B/C编译接口修正，不能用原WD68A源码覆盖当前累计源码。
可复用方法：免费专精身份节点仍按方案保存/激活授予；0费用不等于全角色常驻。区分点亮草稿、服务器保存、真实被动触发三层证据。阶段记录与教学见WD69A归档；完整实现教学留在WD68A的tutor.md。

证据：[WD69A记录](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260925/codexfix_202609250201_阶段WD69A_饮水职业资格与天赋前置提示/memory.md)。永久Skill/Tutor：trace-and-port-coa-spell-resources。

- [guard-wotlk-battleground-map-preview-markers](guard-wotlk-battleground-map-preview-markers/SKILL.md)：MAP74A 战场异地预览越界箭头，2026-09-25 用户反馈测试通过，范围限本批。

- bridge-native-class-mechanics-into-spelldraft：2026-09-25补WD71B部分验收，自动启动通过、持弓失败，WD71C候选待验收。

2026-09-26：UI76B弹药槽基本显示获用户测试通过，详见职业兼容Skill。UI76C腰带和创建预览候选未验收。

2026-09-26：UI76C腰带腹部恢复用户确认通过，见职业兼容Skill；同包创建预览失败，UI76D候选未实机。

2026-09-26 UI76D三模式按钮换装基本通过；随机外观保持未通过，UI76E候选，见职业兼容Skill。

- 2026-09-26：[repair-wotlk-model-index-buffer-capacity](repair-wotlk-model-index-buffer-capacity/SKILL.md)，CLIENTCRASH3B/UI77组合基本不崩溃用户确认；全模型及提速未完整验收。


## 2026-09-27 WD78B三个巫医天赋基本实测通过

用户明确“三个巫医天赋 可以了通过 继续下一批的移植吧”，登记荆棘谷风格、扎拉赞恩的恶意、妖火基本使用通过。不扩展为所有等级/数值、PvP和所有方案矩阵，也不把Voodoo Spirits704511未移植的妖火联动记为通过。

来源：[WD78B](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260926/codexfix_202609262111_阶段WD78B_巫毒三节点双池整合/README_覆盖与测试说明.md)，[教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260926/codexfix_202609262111_阶段WD78B_巫毒三节点双池整合/tutor.md)。复用：已有战斗实现接正式双池时同时扩C++/Lua/SQL白名单与mask；保留旧位、旧账本，不允许现代导师路径恢复已撤销技能；两个点数池不可互借。现代激活存档决定技能所有权，草稿不能授予。WD79A新候选不继承验收。

永久方法：beascendskills/trace-and-port-coa-spell-resources/SKILL.md与build-wotlk-three-build-projection/SKILL.md；对应同名Tutor。


## 2026-09-27 WMO1A外壳用户确认及Claude交接

用户截图与“搞定了”确认监狱WMO外壳基本显示；内部与副本入口均缺，随后门洞内草地截图支持继续排查地形遮挡，尚未证实。吊桥、塔楼和对应地形工作交给Claude，Codex继续巫医主线。

[交接](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260926/交接Claude_北郡监狱吊桥塔楼与副本提取.md)。永久外壳方法：beascendskills/merge-wotlk-adt-wmo-chunk-references/SKILL.md与同名beascendtutor/TUTOR.md；来源WMO1A。地下场景和可玩副本未通过。


## 2026-09-27 WD79B 黑暗魔法技能提示基本实测通过

用户明确“好棒啊 搞定了”，承接WD79B，确认黑暗魔法实际生效后技能书/动作条施法时间提示修正基本通过；不扩大为全部方案、等级、急速与其他技能完整矩阵。来源：[WD79B](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260927/codexfix_202609270144_阶段WD79B_黑暗魔法施法提示双池同步/README_覆盖与测试说明.md)，ZIP SHA256 ca3346832515aba7029fdf5c97ed665ccac5558ba8169a3a67b0dcea6ecdde8e。历史包保持不变。
复用：现代方案读aeMasks[active+1]并显式传AERank，不能用默认读取草稿的参数或旧builds；unknown/pending显示待同步。两套UI展示与服务器战斗效果分开排错。

2026-09-27：WD80D共享节点悬停双选用户实机测试通过，已更新stabilize-spelldraft-client-ui Skill/Tutor；未包含空灵之魂效果移植。


## 2026-09-29 WD86A 两项用户实机通过

用户明确反馈：巫毒心智（按施放时灵魂层数调整暗影傀儡跳速和持续时间）、黑暗洛阿祝福（团队伤害提高3%，自身傀儡加速）测试通过。登记这两项基本效果通过；未提供每个层数逐跳日志、同类增伤全组合、多人归属、PvP/机器人、切方案/重登完整矩阵，不扩大结论。WD87A仍候选待测。

来源：[WD86A覆盖说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609291413_阶段WD86A_巫毒心智与黑暗洛阿祝福/README_覆盖与测试说明.md)、[完整教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609291413_阶段WD86A_巫毒心智与黑暗洛阿祝福/tutor.md)。本次不改历史交付源码/DBC/SQL及SHA256清单；新增验收附件与永久知识记录。

复用方法：周期间隔在Aura初始化读取本人灵魂快照，用基础间隔×100/(100+10×层数)；持续时间×(100+10×层数)/100。祝福本人时间项再乘80%，团队增伤用原生1056组规则3取强。HasSpell加HasAura避免队友光环接收者误获本人专属傀儡收益。施放后新增层数不追改已开始周期。C++、Lua、SQL与双端独立DBC成套交付，32位最高位保存使用BIGINT重建值；WD87扩容另行验收。

永久方法：[来源移植](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendskills/trace-and-port-coa-spell-resources/SKILL.md)、[三方案投影](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendskills/build-wotlk-three-build-projection/SKILL.md)。


## 2026-09-29 WD89A 反例更正：空掩码不是排除（代码已证实，修正包待实机）

本地SpellInfo::IsAffected在familyName=0时直接true；非0同家族的空mask也不排除。GlobalScript::OnIsAffectedBySpellModCheck返回false是强制匹配，返回true只是继续原生判断。此前“空DBC mask能保护无关技能”的解释不成立，不再作为可复用保证。

实际当心巫毒9003752/53和扎拉赞恩9003611均family0/空mask，可误延长暗影傀儡。用户反馈单次施放超过5秒仍发射，数据基础3秒/冷却18秒未互换。WD89A提供私有精确来源回退拒绝和实际时间诊断；候选未编译、未实机。既有用户基本验收保留，不能扩大为全负向范围验收。

[源码证据与适配](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609291613_阶段WD89A_天赋范围修正与拟态计时/research/来源与适配.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609291613_阶段WD89A_天赋范围修正与拟态计时/tutor.md)。后续测试必须同时包含合法目标有加成、无关目标无加成、其他职业原生效果不变。别只测“看到增加了”就认定边界正确。


## 2026-09-29 WD87–WD91前批技能用户基本实机确认

用户概括确认“前面的技能都测试 通过”。WD87三节点、WD88三节点与WD91黑暗雕像登记基本实机通过，采用WD89范围修正后的累计版本；未提供完整数值/多人/PvP/机器人/方案矩阵。WD93仍候选；WD90/92 UI不扩大验收。

[验收依据](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609291627_阶段WD91A_黑暗雕像三目标联动/验收补充_20260929_用户确认前批技能.md)。

已同步原来源移植/三方案Skill及同名Tutor，未新建重复能力目录。


## UIA1 用户实机确认（2026-09-29）

用户明确“成就修好了”，确认此前多项成就点击缺失AchievementProgressBarTemplate报错基本修复。仅验收反馈范围，不扩大为全部任务/成就追踪与所有界面组合。复用方法：扫描MPQ同路径版本，定位调用与模板定义断链；只补回旧版同客户端StatusBar模板块，保留当前WatchFrame其余字节及缓存逻辑。
来源：[UIA1覆盖与测试](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609291824_阶段UIA1_成就进度条模板修复/README_覆盖与测试说明.md)；输出XML SHA256 028ee6af0d4a35dc6ea1cf390298f41d876c1eeafa605b678bfd5132cf4b2409。


## 2026-09-29 WD93/WD96前批技能基本验收补充

用户原话“前面的技能测试通过 继续下一轮的修复 移植”，按最近交付范围登记WD93A配套WD93B的邦桑迪之声/力量的代价及WD96A傀儡师之握基本玩法通过。未提供逐跳数值、PvP/机器人、多角色归属、死亡/切方案全部矩阵，不自动扩大为全项通过。WD93B曾因CalcAmount阶段GetTarget为空导致崩溃，GetUnitOwner加空值保护的修正必须保留。此反馈不验收后续WD97B或STONE59B。

[验收补充](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609291750_阶段WD96A_傀儡师之握移动施法/验收补充_20260929_前批技能确认.md)

WD97B新增方案接入仍是候选，未继承本次验收。[批量接入教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609291940_阶段WD97B_通用三天赋方案接入/tutor.md)


## 2026-09-29 WD98A 巫毒末端三项（候选）

战争魔像、恶意魔像、灵魂提线：51位TE方案、智力快照护盾与魔像拦截、500ms减冷却、五分身20层强化爆炸。195数据/源码/模型检查、Lua回归、50隔离SQL通过；未编译部署/实机。巫毒仍剩妖火进阶11133。[覆盖与测试](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609292100_阶段WD98A_巫毒末端机制/README_覆盖与测试说明.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609292100_阶段WD98A_巫毒末端机制/tutor.md) · [来源](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609292100_阶段WD98A_巫毒末端机制/来源与适配说明.md)。
记录为候选方法与待测边界，不新增实机成功结论。


## 2026-09-29 WD99A 妖火进阶分支收尾（候选）

新增免费50级11133：8秒准备、临时替换怒火、最多3目标直伤与9秒可暴击诅咒、10秒独立蛇守卫；52位保存、动作条还原、拟态有界复制。Lua回归、59隔离SQL、104数据源码检查通过；未编译部署实机。Voodoo本地表37/37节点已候选接入，不能等同全部验收。[覆盖与测试](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609292230_阶段WD99A_妖火进阶分支收尾/README_覆盖与测试说明.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609292230_阶段WD99A_妖火进阶分支收尾/tutor.md) · [来源](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609292230_阶段WD99A_妖火进阶分支收尾/来源与适配说明.md)。
仅登记候选方法与待测试边界，不晋升实机成功。


## 2026-09-30 WD100A 通用神像三节点（候选）

新增Class灵魂守卫7033、迅捷神像6051、黑暗魔精6048，3 AE；55位方案用Lua双32位精确保留旧点。复用既有战斗效果，新增拥有权/等级/前置/清理。Lua回归、141隔离SQL、113数据源码通过；一次早期旧断言失败未复现留档，未编译部署实机。[覆盖与测试](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300016_阶段WD100A_通用神像三节点/README_覆盖与测试说明.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300016_阶段WD100A_通用神像三节点/tutor.md) · [来源](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300016_阶段WD100A_通用神像三节点/来源与适配说明.md)。
仅登记候选工具与验证边界，不标记实机成功。


## 2026-09-30 迅捷召唤实际冷却基本验收与文字候选修正

用户原话“虽然现在缩短时间是正确的”，确认迅捷召唤的实际冷却缩短基本通过。截图灵魂神像基础3分钟；180×75%=135秒即2分15秒，属于冷却不是存活时长。未扩大为其他Class技能、所有召唤、PvP/机器人矩阵通过。

文字修正随WD100A新增独立RebornWDCooldownTooltip插件，5提示入口与切方案、中英文离线Lua回归通过，画面仍待验证。可先仅复制新插件目录并完全重启客户端，无需编译、SQL、MPQ。

[覆盖与测试](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300016_阶段WD100A_通用神像三节点/README_覆盖与测试说明.md)


## 2026-09-30 WD99B 编译错误候选修正

用户报告const/最大值/缺game.lib；实际文件含WD99A，局部Unit const*误调用非const法强API。独立单文件改Unit*，WD100同步，未编译待用户确认。[覆盖说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300126_阶段WD99B_妖火系数const编译修正/README_覆盖与测试说明.md)。


WD101A候选反例补充：配套SQL版本审计、查询写入限流、私有纹理与镜像外观；详现有来源移植/三方案Skill和同名Tutor，未登记为成功。[codexfix_202609300307_阶段WD101A_保存与召唤外观修正](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300307_阶段WD101A_保存与召唤外观修正/README_覆盖与测试说明.md)。


## 2026-09-30 巫毒分支与WD101用户基本验收

用户确认巫毒基本测试及此前三问题已解决。四节点保存、五分身显示、魔像绿色修正登记基本通过；不扩大PvP/机器人/数值全矩阵，WD102独立技能框未单独验收。[WD101验收](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300307_阶段WD101A_保存与召唤外观修正/验收补充_20260930_用户确认.md)。


## 2026-09-30 WD104P 新职业移植规划流程

用户要求先建框架、步骤避免返工。新建plan-coa-class-migration Skill及同名Tutor，路由现有来源/界面/方案能力；先全量盘点、公共骨架、按依赖3–4项交付，再跨系回归和职业对账。流程本身尚未整职业验证。巫医三系46导师技能系列40组同名映射/6组未匹配，不等同普通技能已全部完成；详[WD104P流程与盘点](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300607_阶段WD104P_职业移植流程与酿造依赖审计/README_流程与当前结论.md)。


## 2026-09-30 WD103A 分类基本实机确认

用户原话“现在分类好了”，确认本批分类基本显示通过。客户端增量补100映射、修45分类，双端11傀儡归巫毒的候选包获得分类正向反馈；未逐项展开检查或提供全rank/全部导师资格矩阵，不扩大验收。D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300521_阶段WD103A_技能书与导师三系分类恢复/README_覆盖与测试说明.md


## 2026-09-30 WD104A 酿造三被动正式方案（候选待测）

强效调配、魔精依赖、酿造大师：每项两阶1TE/阶，酿造绑定、最高阶拥有权、61位保存、旧导师补发阻断。184隔离SQL、累计Lua新增27组合、63数据源码检查通过；未编译部署实机。保留原巫毒及WD101/103，不宣布整酿造/普通技能完成。下一批需先处理仅剩3位的编码容量。

[覆盖与测试](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300653_阶段WD104A_酿造三被动正式方案/README_覆盖与测试说明.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300653_阶段WD104A_酿造三被动正式方案/tutor.md) · [交接](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300653_阶段WD104A_酿造三被动正式方案/phaseFixForNewChat.md)。


## 2026-09-30 WD105A 酿造治疗续航三节点（候选待测）

9311灵魂医者、5055洛阿之临、4715洛阿祝福正式方案：20级免费/1TE/30级免费，最高bit63、旧52节点兼容、现代导师补发阻断。Lua累计+8组合、40源码/数据、两轮各236隔离SQL通过；首次快照异常保留在memory，未编译/实机。8覆盖文件加CharactersSQL。下一批增加节点必须先扩展64位容量。

[覆盖与测试](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300717_阶段WD105A_酿造治疗续航三节点/README_覆盖与测试说明.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300717_阶段WD105A_酿造治疗续航三节点/tutor.md) · [交接](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300717_阶段WD105A_酿造治疗续航三节点/phaseFixForNewChat.md)。本条仅候选，不晋升已验证。


## 2026-09-30 WD106A 空方案读取回归（已定位，修复待实测）

用户反馈WD104A全部方案锁定。真实Jorn48旧节点及第二套1000金购买/酿造绑定仍在；AESpecValid错误拒绝spec3+mask0使全槽Load失败，WD105继承。独立双版本最小修正版允许空未绑定槽，保存仍禁未绑定；无生产DB写入。此前SQL/Lua回归未覆盖真实C++Load，不能视为加载验收。暂停WD104/105推广，用户编译重启后确认。[修复说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300744_阶段WD106A_空方案读取回归修复/README_覆盖与测试说明.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300744_阶段WD106A_空方案读取回归修复/tutor.md)。


## 2026-09-30 WD107A 酿造大师提示同步（显示候选）

用户确认酿造大师2阶实际施法2.5秒；仅登记这项机制反馈。客户端提示补10rank白名单、已保存激活29736读取、高位mask兼容、双语2位小数。76离线显示断言通过，无编译/SQL/DBC改动，画面待测。[说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300816_阶段WD107A_酿造大师施法提示同步/README_覆盖与测试说明.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300816_阶段WD107A_酿造大师施法提示同步/tutor.md)。不扩大WD104整包或WD106验收。


## 2026-09-30 WD108A 默认激活方案与列表置顶（候选）

用户明确当前部署基线：WD105A全部源码＋WD106A的WD105A修复文件，已编译；WD105 CharactersSQL、客户端Lua、双端Spell已更新，保留WD107。后续开发必须在此累计层继续，不退回WD104。此次只改实际客户端Profiles.lua，首次成功回包默认active，后续保留手动浏览/草稿；列表改锚点不改slot。离线Lua初始/失败/重复同步、三槽排序及点击目标通过，画面待测。[说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300841_阶段WD108A_激活方案默认显示与置顶/README_覆盖与测试说明.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260930/codexfix_202609300841_阶段WD108A_激活方案默认显示与置顶/tutor.md)。

补记用户明确WD104三个技能测试通过：强效调配、魔精依赖、酿造大师基本效果；不扩大WD105三技能验收。

## 2026-09-30 WD104—WD108 用户基本实测通过及收工交接

用户原话：“前面的技能和修复都测试通过 明天继续吧晚安啦”。据本轮上下文登记：WD104强效调配、魔精依赖、酿造大师；WD105灵魂医者、洛阿之临、洛阿祝福；WD106空方案读取修复；WD107施法提示；WD108重登默认激活方案与列表置顶，基本使用通过。不扩大为全等级、多人/PvP、全部故障恢复与数值矩阵已验收。

当前已部署并测试的累计基线：WD105A全部源码＋WD106A包内WD105A对应修复；WD105 Characters SQL、客户端Lua、独立双端Spell；保留WD107提示、WD108 Profiles。下一轮必须保留上述累计修改，禁止以原WD104或未修WD105覆盖回退。历史包和ZIP保持不变，以本验收补充覆盖“候选待测”的历史状态；WD104/105原始读取缺陷仍保留为反例。

已验证方法（限定本批基本使用）：读取允许spec3且mask0的空未绑定槽，保存仍禁止未绑定；首次成功同步按active选择浏览槽，后续保留主动浏览和草稿；列表只改显示位置，slot身份不变；技能提示按激活且已保存方案计算，不读草稿，高位mask不转浮点。教学见对应包tutor.md，技能方法归入build-wotlk-three-build-projection。

明天接续：先核对实际文件与上述累计基线，处理现有64位投影容量已满的扩展，保留旧节点表/方案/动作条兼容，再按依赖选3—4项酿造及相关通用技能。分类成功不等于普通技能全部完成，依赖台账仍需逐项推进。今晚停止开发；未安排自动任务。


## 2026-10-01 WD109A 酿造扩容与联动三节点（候选待测）

当前WD105/106累计源码之上追加7129充足药剂、7948灵魂之触、31137丛林秘法；保留WD107/108。旧55节点顺序/存储行不变，扩容C++128位、Lua四limb、SQL decimal，当前开放67位。新品减耗仅佳酿/破咒；两高级节点需8基础酿造TE。Jungle按最新20260925官方Radius9从旧80码修正20码，双端说明同步。270隔离SQL、87数据/源码/旧UI、1984精确数值断言与累计Lua通过；未编译、未实机。正式DB只读连接失败，未生产写入。此条仅候选，不晋升已验证。

[覆盖与测试](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261001/codexfix_202610010819_阶段WD109A_酿造扩容与联动三节点/README_覆盖与测试说明.md) · [教程](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261001/codexfix_202610010819_阶段WD109A_酿造扩容与联动三节点/tutor.md) · [交接](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261001/codexfix_202610010819_阶段WD109A_酿造扩容与联动三节点/phaseFixForNewChat.md)。


## 2026-10-01 WD110–112 三轮累计（候选待测）

承接WD109，接入穆厄扎拉之触、天选之人双拟态守卫、怒气/奥术佳酿互斥选择，共4新节点。诅咒雕像24AE前置无法满足，保持旧拥有方式、不开放新节点；bit67保留禁用。保留WD106空槽、WD107提示、WD108方案显示。最新社区commit ad8df63b9003a003946831ef025677ceb6f6288e；295隔离SQL、59静态/数据/UI、1984整数断言及累计Lua通过；未编译、未实机，未生产写入。所有新技能与WD109仍待用户验收，非已验证案例。

[累计覆盖与测试](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261001/codexfix_20261001_阶段WD112A_三轮累计通用与酿造/README_覆盖与测试说明.md) · [逐步教程](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261001/codexfix_20261001_阶段WD112A_三轮累计通用与酿造/tutor.md) · [交接](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261001/codexfix_20261001_阶段WD112A_三轮累计通用与酿造/phaseFixForNewChat.md)。


## 2026-10-02 WD109A 与 WD110—WD112 用户实测通过

用户明确反馈 WD109A 测试通过，WD112A 累计包的三轮也已通过：WD110 穆厄扎拉之触接入方案保存；WD111 天选之人双拟态守卫；WD112 怒气佳酿、奥术佳酿互斥选择。WD109A 包括充足药剂、灵魂之触、丛林秘法及高位方案扩容。登记本批基本使用通过，不扩展为全等级、PvP、多人归属、断线故障恢复完整矩阵。

后续以 WD112A 累计交付为技能开发基线，保留 WD106 空槽读取、WD107 提示、WD108 激活方案显示，保留旧节点位置与存储行。诅咒雕像 5113 未在本批新开放，bit67 保留禁用；DRBOT1A 龙希尔机器人变形用户正在测试，不能继承这次验收。

已验证方法的基本使用：跨 64 位保存需 C++ 128 位、Lua 四 limb、SQL DECIMAL 同步，不能把完整掩码转 Lua 浮点；新增技能所有权由已保存且激活方案决定。双守卫用两个 GUID 分别检查目标和清理，不能修改全部图腾的通用数量；互斥节点在客户端、C++、SQL 三层一致约束。详细边界沿用原包说明。

[WD109A 教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261001/codexfix_202610010819_阶段WD109A_酿造扩容与联动三节点/tutor.md) · [WD112A 教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261001/codexfix_20261001_阶段WD112A_三轮累计通用与酿造/tutor.md)


## 2026-10-02 WD113A 通用巫祝、破咒与诅咒增强（候选）
WD109—112用户基本实测通过已另行登记；本批承接WD112追加6381/12048/11323，bit72—74，保留禁用bit67；原生精确modifier与AE9前置、黑暗魔精互斥。318隔离SQL、累计Lua、32静态/数据检查通过，未编译未实机。DRBOT1A仍待用户测试。
[覆盖与测试](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610020804_阶段WD113A_通用巫祝破咒与诅咒增强/README_覆盖与测试说明.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610020804_阶段WD113A_通用巫祝破咒与诅咒增强/tutor.md)


## 2026-10-02 WD114A 巫祝数值同步与通用双技能（候选）
用户反馈WD113洛阿强化提示不减半，未证明实际扣蓝失败。确认空mask原生modifier不会发送客户端费用更新；本批新增自角色白名单的服务器数值接口与Lua同步，恢复激活方案时补被动Aura。新增假死药剂31118/9003853、强效混合12264/9003854，77位，保留bit67及旧方案。333隔离MySQL、累计Lua/提示、30数据静态检查通过，未编译未部署未实机。DRBOT1A仍待验收。
[覆盖与测试](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610020855_阶段WD114A_巫祝数值同步与通用双技能/README_覆盖与测试说明.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610020855_阶段WD114A_巫祝数值同步与通用双技能/tutor.md) · [来源](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610020855_阶段WD114A_巫祝数值同步与通用双技能/SOURCE_来源与适配.md)


## 2026-10-02 WD114B 巫祝提示重绘优化（候选待测试）

用户澄清实际耗蓝很可能已减半，要求基于WD114A优化显示。保留WD114A原ZIP，仅交付NumericTooltip.lua增量：费用重绘、原生行重建识别、Show重入保护、异步回包当前技能核对；不修改实际费用或角色存档。旧提示回归与新增Lua回调测试通过，旧A触发新增布局断言预期失败。未编译未部署未实机；实际扣蓝仍未确认。下一批机制开发仍以WD114A累计源码与本B客户端为候选基线，不能登记WD114已验收。

[覆盖说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610021638_阶段WD114B_巫祝提示重绘优化/README_覆盖与测试说明.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610021638_阶段WD114B_巫祝提示重绘优化/tutor.md)


## 2026-10-02 WD114B 数值提示与洛阿强化用户确认通过；其他问题继续核对

用户明确“这个数值显示 测试通过”，随后明确“洛阿强化……这个测试通过”。登记WD114B费用提示刷新/旧数值修正及洛阿强化本次基本使用通过；不扩展为全等级、所有方案故障恢复或全部减耗机制验收。

仍待核对：用户称假死药剂点选后技能书找不到、显性诅咒无技能书图标、强效混合4%/15%与技能书8%/30%不一致。只读核对WD114A：31118 -> 9003853，11323 -> 9003852，12264 -> 9003854；三者SkillLineAbility均为9004巫毒分类。截图技能书选中酿造分类。酿造7131 -> 9003620/9003621，2级8%/30%；通用12264 -> 9003854，1级4%/15%。两节点当前独立拥有，不能把两编号误认成同一记录，也不能未核对上游重叠语义便宣称叠加合理。Allocation.lua酿造7131仍残留“通用树同名节点未开放”旧说明，已记录待统一。

显性诅咒支持的9003150、9003200、9003210、9003220—25、9003762已经同时列入服务端SpellNumbers和NumericTooltip费用同步白名单；不是需要再把其被动技能自身费用减25%。未确认这些技能实机费用。假死/显性技能是否已授予，需要查看巫毒书页或IsSpellKnown结果；没有据此修改生产存档或伪造已修复结论。

本次实际读取永久Skill：trace-and-port-coa-spell-resources/SKILL.md、build-wotlk-three-build-projection/SKILL.md。只读核对现有交付，不新增机制移植；WD114A既有上游证据保留，未声称重新核对最新上游。

来源：000Ascendupdate/000Ascendupdate20261002/codexfix_202610021638_阶段WD114B_巫祝提示重绘优化/README_覆盖与测试说明.md。WD113/114其他节点、DRBOT1A仍不能登记全部通过。


## 2026-10-02 WD114C 已学技能书条目补漏（候选）
用户已确认三个IsSpellKnown为true。实读当前Patch-XA，五条Spell/分类存在；enUS自定义FrameXML由最高等级槽生成列表，无独立已学补漏。增量Lua按ID只补五条已学且列表遗漏的技能，保留真实槽、无槽时使用现有按ID条目；巫毒分类、分页同步、去重、脱战刷新；/wdbook输出定位信息。根因具体层级仍需实机诊断，不宣称原生算法已修复。Lua回归通过，未部署。洛阿强化/WD114B用户基本通过不受改动；显性费用实测、假死/强效、同名节点叠加仍待验收。
[安装](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_20261002_184045_阶段WD114C_已学技能书条目补漏/README_覆盖与测试说明.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_20261002_184045_阶段WD114C_已学技能书条目补漏/tutor.md)


## 2026-10-02 WD114D 精确定位（候选）
用户截图五ID原生槽及列表均存在、插件已加载，WD114C漏项假说未命中；当前尚未定位实际不可见原因。新增/wdbook中文名或ID按实际渲染列表跳转页格并检查按钮data/可见性。Lua导航边界和累计语法通过，未部署未实机。不修改机制数据、不宣称图标问题已修复。
[说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_20261002_191509_阶段WD114D_技能书精确定位/README_覆盖与测试说明.md)


## 2026-10-02 WD115A 假死通过、图标和强效混合同源整合候选
用户明确假死药剂可以了通过；假死/显性图标已在最新截图显示，旧漏项假说不再作为根因。仅假死基本机制验收，不扩展显性25%费用和全部方案边界。
本批复用trace-and-port-coa-spell-resources及build-wotlk-three-build-projection。假死官方节点图标7e06e90aea7e069e现有可复用，Spell误用了巫祝图标，独立SpellIcon修正。强效通用12264和酿造7131引用同源503748/504888，保留方案位和投资，最高等级合并至9003620/21，撤销旧重复9003854，不叠加。中文名和图标统一，双入口提示重复投资无额外收益；不自动退款或改旧方案。
上游HEAD d7620151fa4267ab90c7e0554b32628017df241a，Issue1290/2190、最新场景和相关PR搜索已存档。Data/Content进阶JSON没有这些法术且同号ID跨版本复用，不能当当前服务器开放配置；双入口保留是本项目兼容策略。上游固定威胁与说明百分比差异未照搬。
双端限定记录/所有字符串偏移、Lua语法、72组状态模型通过；未编译、未部署、未实机；模型不是运行证据。WD114B数值提示保留，只有增量inc/Lua/DBC/图标，无SQL。方案/点数/购买记录均不改。技能总完成度不提升。
[WD115A说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022030_阶段WD115A_假死图标与强效混合来源审计/README_覆盖与测试说明.md) · [教程](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022030_阶段WD115A_假死图标与强效混合来源审计/tutor.md)。ZIP SHA256 `be987886df6c41099cbd345d3b0edba5a4ed062eb2524440908a971115003d27`。


## 2026-10-02 WD116A 沃金守望通用防御技能（候选）
新增节点6042->9003855，隐藏治疗9003856；先9基础AE后1AE，跨专精，bit77精确存储。原生25%减伤、1秒一次2%最大生命治疗、10秒持续、120秒冷却；受原生治疗修正。官方图标与天赋一致，视觉兼容复用原生树皮术，未宣称CoA独有特效。
累计WD114与WD115整合，保留数值提示、原方案和购买资格。WD115仍未用户实测。使用plan-coa-class-migration、trace-and-port-coa-spell-resources、build-wotlk-three-build-projection。来源commit d7620151fa4267ab90c7e0554b32628017df241a，官方504465/681004/503598，上游周期修正已查。灵魂行者未开放。
342隔离SQL、累计Lua、20数据检查及全部Lua语法通过；未编译未部署未实机。初次测试因缺schema夹具中止，补齐后通过；旧bit77越界测试更新为78。不能将候选登记成功。需要Characters WD116A SQL，旧版本unknown-node守卫禁止带新节点回退。
[覆盖说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022006_阶段WD116A_沃金守望通用防御技能/README_覆盖与测试说明.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022006_阶段WD116A_沃金守望通用防御技能/tutor.md)；ZIP SHA256 `7bb6b2411a0c0a556191b86ac40fa623d64993cee897b5098b40121a270f4b49`。


## 2026-10-02 WD117A 灵魂行者双技能联动（候选，未编译未实机）
在WD116累计基础新增9347双级9003857/58，10%/20%增强沃金及迅捷持续和效果，精确80位保存。一级整数光环27%、二级30%；恢复在实际治疗量上乘10%/20%，不提前截断2.2%。等级变化清旧增强效果不重置冷却。复用节点官方图标；服务端提示支持持续、减伤、基础逐秒恢复和迅捷增幅。
上游commit d7620151fa4267ab90c7e0554b32628017df241a，Completion将SpiritWalkerOne第二效果修正9（10%）。354隔离SQL、累计Lua、25数据/源码及全部Lua语法、数值提示回归通过。WD115/116/117均仍候选，先验收再推进其他依赖。
使用plan-coa-class-migration、trace-and-port-coa-spell-resources、build-wotlk-three-build-projection。覆盖说明：[codexfix_202610022033_阶段WD117A_灵魂行者双技能联动](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022033_阶段WD117A_灵魂行者双技能联动/README_覆盖与测试说明.md)；教学：[codexfix_202610022033_阶段WD117A_灵魂行者双技能联动/tutor.md](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022033_阶段WD117A_灵魂行者双技能联动/tutor.md)。ZIP SHA256 `ba2e743f813316cceb0daaf1c3f5abf5a7a2daaee52449b222ac90e155f17bc6`。


## 2026-10-02 WD118A 化蛇通用生存技能（候选）
基于WD117累计，节点29306->9003859、隐藏9003860，30级9基础AE后1AE、bit80。5秒化蛇、80%移速、已有定身/减速解除、60秒冷却；保留禁止攻击施法且可取消。配套原始远程/法术命中修正-100个百分点、80%游泳；非全伤害免疫。现有蛇模板2914及四模型客户端存在，节点图标一致，未移植CoA专属粒子链。
最新上游d7620151fa4267ab90c7e0554b32628017df241a，PR6192已合并；独立父/子生命周期与方案撤销。Characters WD118及World绑定SQL必须成套，旧节点和购买状态不清。367隔离SQL、累计Lua、30数据/源码及提示检查通过，未编译未实机；WD115–118仍待验收。
使用plan-coa-class-migration、trace-and-port-coa-spell-resources、build-wotlk-three-build-projection。首次全量旧level20用例失败，定向成功；新增等级分支补ROLLBACK后全量完成，证据见checks。完整说明与教学：[README](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022101_阶段WD118A_化蛇通用生存技能/README_覆盖与测试说明.md)、[tutor](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022101_阶段WD118A_化蛇通用生存技能/tutor.md)。ZIP SHA256 `302b7254571ee0b44ba30d95b9cc4a3c64fb5e410843e73c5e11560c8445550f`。


## 2026-10-02 WD118B 原生拖动图标资源补齐（候选）
用户确认WD115假死书页图标修改可见，拖动可放动作条但鼠标图标透明。五个新增SpellIcon路径的BLP此前只在02插件目录交付，当前全MPQ扫描未命中。补齐原路径5BLP到MPQ输入；不改DBC/Lua/源码/SQL，兼容WD115–118，待实机确认光标。无机制新增，仅本地资源链审计。以后累计交付同时包含磁盘与MPQ资源；不能因界面能显示而省略原生入口验证。
使用trace-and-port-coa-spell-resources。五BLP头/尺寸/引用/哈希、归档扫描及ZIP完整性已查。说明：[WD118B](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022208_阶段WD118B_原生拖动图标资源补齐/README_安装与测试.md)；教程：[tutor](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022208_阶段WD118B_原生拖动图标资源补齐/tutor.md)。ZIP SHA256 `fafcb38ceb02d34065360acfbbd5fec393d395cd44cd7b9d79065af3be3128ce`。


## 2026-10-02 拖动图标与沃金守望用户基本验收
用户原话：“这个图标拖动的时候可以看到了 沃金守望：测试通过”。确认WD118B补齐MPQ资源后，本次假死药剂拖动光标显示恢复；沃金守望基本使用通过。不扩大为全部五图标逐一确认、灵魂行者增强、化蛇、PvP或多人完整矩阵通过。
来源：[图标修复](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022208_阶段WD118B_原生拖动图标资源补齐/README_安装与测试.md)、[沃金守望](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022006_阶段WD116A_沃金守望通用防御技能/README_覆盖与测试说明.md)。原ZIP不改写。
复用：原生SpellIcon引用的新BLP同时交付插件目录与MPQ内部准确路径；书页可见不代表原生鼠标加载可见，分别测书页、拖动光标、落入动作条。沃金守望以独立主动/隐藏周期治疗分工，激活方案授予和撤销，不能因图标出现推定保存或机制通过。本条以用户明确的基本测试结论覆盖原候选状态，其他未测项保留。


## 2026-10-02 WD119A 蛙变术与双祝福（候选待测）
承接WD118A累计，合并用户已确认拖动可见的WD118B。新增Class6031蛙变术9003861、6525贡克祝福9003862、12525克拉格瓦祝福9003863，26级/9基础AE/每项1AE；两祝福互斥且要求父技能。40秒普通目标、玩家8秒后原生递减、伤害解除、临时野兽类型，1秒120秒/1.5秒60秒/瞬发120秒三种基础状态；服务端数值提示同步。保留旧方案和购买，bits81–83追加，84位三端一致。
最新社区commit d7620151fa4267ab90c7e0554b32628017df241a、已合并PR4753及934/1179/3693和当前场景已核对；官方20260925Spell500952/806469/807855单独记录。原模板216377本地缺失，复用原生Hex蛙13321；未导入CoA独有粒子。当前Patch-XA被锁错误32，登记解包引用存在不等同实际MPQ/渲染验收。
388隔离SQL、53数据/静态、累计Lua/语法/提示模拟通过；未编译未部署未实机。首次SQL旧回退断言失败为新增测试before变量含购买表导致口径不一致，修正夹具后全量通过。用户本轮沃金守望基本通过已另行登记，灵魂行者/化蛇和本批不继承。
使用plan-coa-class-migration、trace-and-port-coa-spell-resources、build-wotlk-three-build-projection。交付需Characters WD119；未装WD118需World118绑定。详情：[覆盖说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022255_阶段WD119A_通用控制三技能/README_覆盖与测试说明.md)、[教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022255_阶段WD119A_通用控制三技能/tutor.md)、[来源](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261002/codexfix_202610022255_阶段WD119A_通用控制三技能/来源与适配说明.md)。ZIP SHA256 `51c3063a16dcd0f24ca3c5d8a2e9c093f11b98ce84dbfbcf2b8b12690c386733`。


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


## 2026-10-03 WD119C 蛙变冷却与移动回归（候选待测）
WD119A用户发现贡克查询60秒但客户端实际倒计时120秒，以及移动不中断读条。Player.cpp精确补9003862→9003861的最终冷却包；双端9003861 InterruptFlags14→15补MOVEMENT位；提示识别秒施法时间。保留WD119B。累计Lua、逐字段数据差异与源码范围检查通过，未编译未实机；不宣称WD119A整体通过。需源码重编译+双端DBC+Lua，不需SQL。
[覆盖说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610030224_阶段WD119C_蛙变冷却同步与移动打断/README_覆盖与测试说明.md)；ZIP SHA256 2d464fbaa1401cacf87881fb8a51bd105bd6392466e1fa40a8fb5640ef04e170。


## 202610030327 WD120A 酿造基础三节点（候选待编译/实测）
已完成4005大锅酿造、12645丛林蘑菇、12646药水投掷的有界接入：免费酿造节点、配料6秒范围治疗、投掷7级+18秒HoT。保存扩87位，旧位与购买账本保留；World手动系数避免重复加成；节点/技能书/拖动图标一致。当前治疗参考范围读取服务端，不依赖草稿。基线WD119A累计+已验收WD119B+候选WD119C；WD119C和本批尚未实机通过。
上游在线固定d7620151fa4267ab90c7e0554b32628017df241a；字段232是描述变量ID，实际802703等级缩放来自ScalingBase实现。不能将早期字段误判继续复用。仅蘑菇一种配料，其他配料和泼洒仍未开放；外观复用既有洛阿佳酿887925，36项引用资源已只读找到，不宣称大锅模型或专属药瓶弹道完成。
403项临时MySQL与累计Lua/DBC检查通过；C++没有编译，没有修改运行目录或生产数据库。一次历史GM测试断言未复现，原路径未声称修复，详见memory。
[覆盖说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610030147_阶段WD120A_酿造下一批依赖开发/README_覆盖与测试说明.md)；[逐步教程](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610030147_阶段WD120A_酿造下一批依赖开发/tutor.md)；[交接](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610030147_阶段WD120A_酿造下一批依赖开发/handoff.md)。ZIP SHA256 `02ee4367bc97f2f9df779b800886cc20a5759539b88a3b62c26ab8e134fea71c`。旧ZIP不改写。


## 202610030403 WD121A 酿造治疗双天赋（候选，未编译/未实机）
基于WD120累计，新增6498新鲜配料两级9003877/78（大锅蘑菇15%/30%）和29303药水增效9003879（投掷及蘑菇HoT20%）。90位保存、79项映射，基础8酿造TE后每级1TE，同层不计前置；保留旧方案及购买。节点/书页/拖动图标一致，权威治疗提示走同一原生done healing路径。WD119C及WD120仍候选，不把继续开发请求当验收。
本批在线HEAD ccaf63902e3d244953d0bed991aae79fdc32055c；Issue1142关闭但PR4753仍needs-decision。官方20260925本地Fresh op0与社区场景op22/目标冲突，按大锅描述精确限定；PotionBoss由op8适配末端op0/op22使手动系数一并增强，差异明示，不声称官方服务器完全一致。
414隔离MySQL、累计Lua/旧UI、双端旧行/字符串、720数值负向模型通过。首次历史war等级拒绝断言失败未捕获原值，后续完整追踪复测及20次重复拒绝通过，未根因、不称修复。未生产写入、未编译、未实机；尚不晋升已验证Skill。
[覆盖测试](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610030339_阶段WD121A_酿造治疗双天赋/README_覆盖与测试说明.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610030339_阶段WD121A_酿造治疗双天赋/tutor.md) · [来源](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610030339_阶段WD121A_酿造治疗双天赋/来源与适配说明.md) · [交接](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610030339_阶段WD121A_酿造治疗双天赋/handoff.md)。ZIP SHA256 `61a121430c0696d33f4991142ad71cb7e4107e2cbeb1588c8615ad159d47b220`。


## 202610030712 WD121B 蛙变术施法后冷却同步（候选，未编译/实机）
用户继续反馈提示60秒、动作条2分钟。源码定位WD119C早期发送后仍有SPELL_GO预测路径；原WD63E施法后纠正仅处理Hastened。本包补Gonk9003862→frog9003861精准匹配，读取服务器剩余毫秒并只重置客户端计时，不二次扣减或删除服务器记录。Player.cpp保留WD121A字节基线。
32项静态/双端数据/消息模型检查通过，未抓包或实机，不晋升已验证修复。上游在线HEAD a670f706882fa8e4014bc8bb943663a48f616804。专项源码包需用户覆盖、编译并重启，无本次SQL/DBC/Lua变更；下一批开发不替代本项验收。
[覆盖说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610030705_阶段WD121B_蛙变冷却施法后同步/README_覆盖与测试说明.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610030705_阶段WD121B_蛙变冷却施法后同步/tutor.md) · [交接](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610030705_阶段WD121B_蛙变冷却施法后同步/handoff.md)。ZIP SHA256 `34acda358562d324b3c84027f90fba5dd4142214410b123b3f166246e3db2f63`，旧归档不改写。


## 2026-10-03 WD120A三技能及WD119C/WD121B蛙变三状态：用户实测通过
用户明确逐项确认六项通过：免费大锅入口、蘑菇每6秒范围治疗、7级投掷/15秒冷却/18秒蘑菇HoT；贡克动作条60秒、普通/贡克移动打断、克拉格瓦瞬发移动施放。仅登记列明行为，未外推完整PvP/等级/机器人/重登矩阵。冷却同步验收为WD121B补全后的组合，不抹去WD119C早期遗漏。
WD121A新增新鲜配料15%/30%与药水增效20%仍待用户明天测试。保留WD121B，旧归档不改写。
[六项验收与续测交接](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/WD120A_WD119C_WD121B_用户六项实测通过.md)。


## 2026-10-03 WD121A实测通过；WD122A蘑菇互斥双天赋候选
用户确认新鲜配料15/30%及药水增效20%测试通过，已[登记验收](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/WD121A_双天赋用户实测通过.md)；不外推完整场景矩阵。
新WD122A：6020→9003880丛林绽放+100%/5人/6秒，29737→9003881丛林医师8人/4秒，共组706545互斥。81节点映射、92位精确保存，8基础酿造TE+1TE，SQL/C++/Lua均校验。目标cap及周期实时提示；切方案重算现有准备Aura，保留WD121B字节基线。
425项隔离SQL、累计Lua/DBC检查及378数值组合通过；未编译/部署/实机。在线HEAD e7c0ccabb18456bb8aac2aaba55bc799381b9b26，官方-3目标、-2000ms独立核对。早期测试夹具语法/枚举错误及注册阶段空Spell风险已静态纠正，边界见memory。
[覆盖说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610031523_阶段WD122A_丛林蘑菇互斥双天赋/README_覆盖与测试说明.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610031523_阶段WD122A_丛林蘑菇互斥双天赋/tutor.md) · [交接](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610031523_阶段WD122A_丛林蘑菇互斥双天赋/handoff.md)。ZIP SHA256 `b1b494f939234f7a4ae443af1fd63915227e224336229274cfa89175d5d7899e`。新阶段待验收，旧ZIP不改写。


## 2026-10-03 WD123A 泼洒药水与蘑菇范围治疗（候选待实测）
新增7128→9003890–96七等级，17级/1TE/酿造，40码地点、10码8友方、独立15秒、20%基础法力。正确蘑菇803698→隐藏9003889，12秒/3秒，不误给803273鱼油。上游未关闭6294与常量颠倒证据记录，在线HEAD e7c0ccabb18456bb8aac2aaba55bc799381b9b26。
82项映射/93位保存；较早层级泼洒1TE计后续8基础。药水增效只增加新HoT20%，不增泼洒直接；旧投掷与大锅天赋保持。WD122A仍未获验收，WD121B字节保留。
441隔离SQL、累计Lua/DBC、384离线组合、36项既有视觉资源检查通过，未编译/部署/实机。只用覆盖包，不写生产数据库；旧ZIP不改写。
[覆盖说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610031548_阶段WD123A_泼洒药水与蘑菇范围治疗/README_覆盖与测试说明.md) · [来源](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610031548_阶段WD123A_泼洒药水与蘑菇范围治疗/来源与适配说明.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610031548_阶段WD123A_泼洒药水与蘑菇范围治疗/tutor.md) · [交接](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261003/codexfix_202610031548_阶段WD123A_泼洒药水与蘑菇范围治疗/handoff.md)。ZIP SHA256 `33a8ba7a096ce1848b861710d6af1e2145db91333bc440f5909674246a3b0d38`。


## 202610040721 WD122B 编译枚举修正（待用户编译）
WD122A用户报告未声明目标枚举，WD123A亦继承。当前核心TARGET_UNIT_CASTER_AREA_RAID=56；两个隔离单文件版本仅替换错误符号，双端9003866目标56核对一致。modules.lib缺失很可能是连带错误。之前静态检查遗漏枚举声明，不能声称已编译通过；本次亦未编译/部署/实机。保留原ZIP和生产文件。
[说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261004/codexfix_202610040721_阶段WD122B_范围目标枚举编译修正/README_覆盖与测试说明.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261004/codexfix_202610040721_阶段WD122B_范围目标枚举编译修正/tutor.md)。ZIP SHA256 `723474723e7ff16174015ec842890b70e8d16d1b6a2965b0380de06f1b311510`。使用trace-and-port-coa-spell-resources，符号存在性检查纳入后续审计。


## 2026-10-04 WD122A 用户本批测试通过
用户明确反馈“WD122A 累计测试包测试通过继续下一批技能的开发”。在WD122B编译修正交付后登记WD122本批基本测试通过；未获得逐项日志，不扩大成全部数值、多人、机器人、切方案矩阵均验证。下一累计版本必须合并TARGET_UNIT_CASTER_AREA_RAID=56的兼容修正，历史WD122A原ZIP仍有已知编译错误，不能重新直接使用。WD123泼洒药水仍候选待测。
来源：000Ascendupdate20261003/codexfix_202610031523_阶段WD122A_丛林蘑菇互斥双天赋；修正：000Ascendupdate20261004/codexfix_202610040721_阶段WD122B_范围目标枚举编译修正。
复用：互斥天赋的保存、激活被动、目标人数和周期提示一并接入；枚举须查目标核心声明。周期重新计时不能凭空增加治疗跳数。基本验收不能替代未测边界。


## 2026-10-04 WD123B 泼洒药水累计候选
承接用户WD122测试通过，将WD123A七级范围治疗与12秒/3秒蘑菇HoT合并WD122B正确枚举；累计Lua/DBC检查重跑通过，66个其余安装文件与WD123A字节一致。SQL历史441项隔离验证，本轮未重跑。未编译/部署/实机，上游刷新失败已明示。
[覆盖说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261004/codexfix_202610040753_阶段WD123B_泼洒药水累计与编译修正/README_覆盖与测试说明.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261004/codexfix_202610040753_阶段WD123B_泼洒药水累计与编译修正/tutor.md)。ZIP SHA256 `601d3b2d0ab69f45f94d76dbffc4613dd6477511688d99619e0b85bcd66531a1`。

## WD123B 泼洒药水基本实机通过（2026-10-04）
用户确认泼洒药水与蘑菇附加治疗测试通过。它们是一项可选主动技能与其隐藏HoT，不是两个独立天赋。复用经验：进技能书/动作栏的主法术和隐藏触发效果必须分离；官方资源中803273鱼油与803698蘑菇不可颠倒；治疗目标与持续跳数、双端DBC、SpellIcon及服务端治疗系数同步。WD123B来源：[覆盖说明](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261004/codexfix_202610040753_阶段WD123B_泼洒药水累计与编译修正/README_覆盖与测试说明.md)。只记基本验收；WD124A药水投手/药师/再生者仍候选，真实冷却/回蓝/治疗/属性需用户验收。


## 2026-10-05 WD113—WD127窗口收工

- [synchronize-wotlk-spell-costs-and-cooldowns](synchronize-wotlk-spell-costs-and-cooldowns/SKILL.md)：用户确认WD127F药水投掷／泼洒基本同步通过，固化后GO消息、Right标题、协议字段与实际DBC数值闭环。
- trace-and-port-coa-spell-resources、build-wotlk-three-build-projection、stabilize-spelldraft-client-ui更新窗口证据，未重复建立同类Skill。
- [成功、失败和待测总表](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261005/codexsummary_202610050358_阶段WD113至WD127_成功失败教学与交接/memory.md)，药师／再生者精确编码仍待核对，不作为正确数值案例。


## WD128 A+B 三节点用户基本通过（2026-10-05）

更新既有 trace-and-port-coa-spell-resources 与 build-wotlk-three-build-projection 的 Skill/同名Tutor，覆盖三节点与保存入口修复，不扩大PvP/机器人/精确数值验收。[发布教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261005/release_WD128_20261005_三个技能用户验收/tutor.md)。


## WD129A 用户验收通过 — 2026-10-06

血蓟和森金两技能按用户确认登记通过；保留1.94/2.380秒精确数值对照边界。[WD129A验收与证据](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots/data/reborn-checkpoints/WD129A/ACCEPTANCE.md)。原包不改写。

已同步 trace-and-port-coa-spell-resources 与 build-wotlk-three-build-projection 及同名Tutor。


## WD130 A+B 用户验收与推送 — 2026-10-06

WD130A + WD130B 用户基本测试通过。

[c0b09aee5（WD130A：魔精光束与双联动）](https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/commit/c0b09aee574636db090125085c6f99eff91352cf)
→ [d2a202bb8（WD130B：缩小盟友节点图标一致）](https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/commit/d2a202bb8d7e5e5d75f8df39c44055da8b75a046) ← tag ← Release及资源附件

- 魔精光束、泼洒他们、瓶外之灵：用户确认本批基本通过。
- 明确复测：洛阿药剂成功施放使魔精光束剩余冷却减少2秒，基础冷却说明仍是14秒。
- WD130B统一缩小盟友节点与技能书图标。
- 不扩大为所有等级、精确数值、PvP或机器人矩阵通过。


[发布教程](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261006/release_WD130_20261006_用户验收/tutor.md)。原包保留，未改写候选包历史记录；以本次验收为后续状态。


## WD131A 两项用户基本通过 — 2026-10-06

“可以了 这两个技能通过”。魔精：蛙骨蘑菇、魔精：丛林血蓟登记基本实机通过。
此前仅点击魔精时没有生命/体型改变，经说明需5秒内投掷/泼洒命中目标后，用户确认通过。没有新代码修正；同一WD131A包验收。
没有逐项战斗日志，不扩大为全部等级、精确减伤、PvP、机器人、多施法者或跨重登临时状态矩阵通过。
保留本地适配：对应配料拥有权、手动换料取消待用魔精、特殊双配料内存状态不跨重登永久保存。


[验收记录](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots/data/reborn-checkpoints/WD131A/ACCEPTANCE.md) · [发布工作流Skill](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendskills/release-tested-reborn-features/SKILL.md) · [同名教程](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendtutor/release-tested-reborn-features/TUTOR.md)

新增 [release-tested-reborn-features](release-tested-reborn-features/SKILL.md)：小功能验收、提交推送、tag/Release分工与源码资源关联。


## WD132A 用户验收 — 2026-10-06

魔精波动扩散治疗与团队恢复，用户明确“WD132A 测试通过”，记基本实机通过，不扩大为全部数值/PvP/机器人矩阵。本次授权代办commit/push/tag/Release，发布状态以读回结果为准。
[验收记录](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots/data/reborn-checkpoints/WD132A/ACCEPTANCE.md) · [实际代码教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261006/codexfix_202610060515_阶段WD132A_魔精波动扩散与回蓝/tutor.md)


## WD133A 用户验收 — 2026-10-06

鱼骨魔精、野兽之血与水晶之水，用户明确“WD133A 测试通过”，记基本实机通过，不扩大为全部数值/PvP/机器人矩阵。本次授权代办commit/push/tag/Release，发布状态以读回结果为准。
[验收记录](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots/data/reborn-checkpoints/WD133A/ACCEPTANCE.md) · [实际代码教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261006/codexfix_202610060712_阶段WD133A_酿造联动下一批/tutor.md)


## WD134A+B 用户验收 — 2026-10-07

两技能及射程提示基本实测通过，授权commit/push/tag/Release。归档包保持不变，发布状态以远端读回为准。
[验收](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots/data/reborn-checkpoints/WD134B/ACCEPTANCE.md)


# WD135A 用户基本验收 — 2026-10-07
用户明确“134 和135 这两个技能测试通过”，授权commit/push/tag/Release；随后明确下一批明天再做，今天止于发布。
灵魂链接雕像：节点13133、技能9003953，14秒/2秒/10码/3分钟/3%基础法力；共享Idol槽，团队玩家生命比例重分配且总生命守恒，不支持NPCBot。
登记基本使用通过，不外推全部多人/PvP/机器人、生命守恒极值和生命周期矩阵专项验收。
发布前24份现场源码与候选逐字一致；117安装文件与manifest哈希一致。历史188隔离SQL、29数据/Lua、C++单元/Zs及10000守恒案例为原包证据，发布未重跑生产SQL或重编译部署。
WD134原Release已存在且标签指向912959a6e79f0969dcdbf4408d21129988606ec2，不重复生成。

资源 ZIP SHA256：ec0d478f4db6e0cb7f9356bb46c639438d6d70dc3057bbb8fe775674cb186e18
原包：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261007\codexfix_20261007_032414_阶段WD135A_灵魂链接雕像
历史候选文档不改写；后续验收以此记录为准。

[验收](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots/data/reborn-checkpoints/WD135A/ACCEPTANCE.md)


# WD135UI1 用户基本验收 — 2026-10-07
用户明确“刚做的召唤栏与图标修复尚未收到测试确认 测试都通过了”。登记三项基本通过：灵魂链接雕像进入Idol栏；八类未学空槽显示简短用途且无未学技能详情；灵魂回收采用图腾回收图标3994，灵魂守卫不改。
Lua 5.2语法与8空槽/5已学辅助槽悬停测试通过；游戏用户确认不外推战斗锁定、所有专精与全部语言组合专项矩阵。
资源包以现场LIGHT8B patch-ZA为底版，Spell仅9003541字段133从3062改3994；保留WD135A技能9003953及LIGHT8B视觉模型。LIGHT8视觉不因本次UI确认升级为所有渲染专项通过。
本提交跟踪Lua、资源生成代码与校验清单；MPQ作为Release附件，不将DLL/INI或无关源码带入。

资源 ZIP SHA256：6ce7e6d2537054b0b1bc00490cf5c7803cd37799127d5ae1ec70387ede6eed3c
原包：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261007\codexfix_20261007_095525_WD135UI1_召唤栏空槽与回收图标
历史候选文档不改写；后续验收以此记录为准。

[验收](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots/data/reborn-checkpoints/WD135UI1/ACCEPTANCE.md)


## LIGHT8B 基本视觉验收 — 2026-10-07
用户“下载测试了还可以”，确认本批烈焰风暴火苗/焦痕/余烬基本观感；不外推帧率、加载、所有地形或植物真实燃烧。
复用边界：克隆模型与视觉链，只改九个普通等级；继承现场最高覆盖DBC，核对WD135A 9003953，不能从旧底表覆盖新功能。M2共享数值轨道复制后重定向，保留网格/SKIN和材质路径，限制粒子峰值。完整生成10文件字节复现通过。
[已推送生成工具](https://github.com/wowshub/modern-wow-renderer/tree/aa4de93f133053dd92f93327cf99406cd27a14a7/tools/RebornFlamestrike)；原包codexfix_20261007_092024_LIGHT8B_WD135A兼容火苗焦痕余烬。LIGHT8A缺WD135A新增记录为反例，已由B替代。


## 2026-10-07 发布与当日同步
[release-tested-reborn-features](release-tested-reborn-features/SKILL.md) 已更新当前发布分工与 [当日Data/SQL合并步骤](release-tested-reborn-features/references/daily-sync.md)。新增对应Tutor的daily-sync.md。

## WD136A 2026-10-08 用户基本通过
已更新trace-and-port-coa-spell-resources及build-wotlk-three-build-projection与同名Tutor。


# DRBOT1A 战斗变龙基本验收（2026-10-08）
用户确认“龙希尔机器人 playerbot 战斗的时候可以变成龙人形态，测试通过”，授权提交。
当前两份文件与2026-10-01原包逐字一致。原记录仍为候选，过去未提交是因为没有收到本功能单独验收，不能拿巫医测试结论代替。
本次确认仅覆盖战斗自动变龙基本行为；稳定脱战恢复、不同性别颜色、取消光环、骑乘飞行、死亡与退组等矩阵仍待专项确认。
改动是PlayerbotAI私有函数及四个私有状态，UpdateAI在组队状态更新后调用；已有公开API、AiObjectContext/AiFactory未改。因此不触发协作说明中公共接口改动必须重跑DC编译的条件。本轮未重新完整编译DC或宣称DC全场景回归。
子模块现场祖先包含已存在831a25ee（自定义种族/API）与6a24cbd9（排除随机巫医）；主仓库旧gitlink仍为3fa1c1e4，更新引用会一并固定这两条现用前置，不是本轮新开发。
wowshub/newreborn与现场历史已分叉，采用独立分支reborn-drbot1a-20261008发布当前已测试谱系，不合并、不覆盖该远端分支。主仓库.gitmodules改为用户wowshub远端，使新gitlink可拉取。

永久方法：beascendskills/integrate-playerbot-racial-form-lifecycle/SKILL.md；同名Tutor。


## 2026-10-10 WD137B 移动施法基本验收
用户明确WD137B测试通过。保留WD137A漏客户端MOVEMENT的失败记录；双端分工：客户端八rank14，服务端15按9003957本人光环放行。基本通过不扩展所有数值/PvP/机器人专项。
D:\000rebornWOW\000RebornWOWHighForkPRO\beascendcode\AzerothCore-wotlk-with-PlayerBots-NPCBots\data\reborn-checkpoints\WD137B\ACCEPTANCE.md


## 2026-10-10 UI_AMMO1A 显示实测通过
# UI_AMMO1A 用户验收 2026-10-10
用户原话：“弩的弹药槽和 战士防护的显示正常了”。验收限显示；不扩大为全部职业、射击规则或机器人天赋加点验收。
基线57d3860f2fd8ff8bfc0a17ab855df858bc453c0d，fetch远端一致；两份运行客户端Lua与已交付包逐字节一致。
弩识别不再以拍卖行紧凑分类列表下标代替ItemSubClass ID；MultiBot Warrior3简中修正为防护。
仅覆盖Interface下两份Lua，非战斗/reload。无SQL、DBC、服务端Data或编译要求。与衣柜文件无重叠。
16项离线Lua检查已通过。完整回滚与教学见原包，原包不改写。
源ZIP SHA256: 6406c4c9310d73d263529ef352a1aed334997ee2f3848344dd5d75636d13cea9

来源：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261010\codexfix_20261010_020004_阶段UI_AMMO1A_弩弹药槽与战士天赋译名


## 2026-10-10 EV3T3 本批衣柜用户验收通过
用户：“好吧 这次衣柜先修复到这里 通过 给我commit并推送 release这一批的修复吧”。确认本批共享搭配、公共原件库、整套取回与条带显示修复的基本使用；不扩大到真实数据库故障、全职业/全缩放边界。最终源包与运行插件、当前衣柜源码逐文件一致；累计附件：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261010\release_EV3T3\EV3T3-tested-20261010.zip。验收记录：D:\000rebornWOW\000RebornWOWHighForkPRO\beascendcode\AzerothCore-wotlk-with-PlayerBots-NPCBots\data\reborn-checkpoints\EV3T3\ACCEPTANCE.md。发布状态待远端核验。
复用：引用与库存分离；按原GUID逐件回执；全入口限频；条带与Equipence右列联动留白。EV3T2单移锚点造成附魔重叠为已修正反例，旧包不改写。


## 2026-10-10 EV3T3 已发布
提交44f645592c99886098520eec3f66496aac49151e，tag reborn-ev3t3-20261010，wowshub/threemodelcardpro及标签目标已核验。Release https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-ev3t3-20261010 。附件EV3T3-tested-20261010.zip，300604字节，GitHub digest与本地SHA256 48038d83d698af0ad5e5d16ccf3bcf44dbbe1876d0b77f188c983bbd671c4ec7一致。未部署launcher/远程服。仅13文件提交，LFGMgr及所有无关修改保留。


## 2026-10-10 EV3U1 用户基本验收
# EV3U1 当前穿戴标记与刷新稳定：基本实测通过
2026-10-10 用户：“这个衣柜可以了 帮我继续天赋技能和雕纹推荐系统”。确认本次当前搭配标记、背包事件不再导致条带反复消失的基本使用；不扩展全部职业/缩放/数据库故障矩阵。
基线44f645592c99886098520eec3f66496aac49151e（reborn-ev3t3-20261010）。仅Shared.lua。衣柜按19槽原GUID判断完整匹配；红色当前标记与跨页摘要；相同搭配都标记，混搭不误标。普通背包事件合并查询，不清穿戴标记；后台只读保留显示，实际换装仍核对。
EV3U误将BAG_UPDATE当成穿戴变化造成闪烁为反例，由EV3U1修正。现场文件与最终候选SHA256完全一致。离线21项协议回归及100次背包事件合并、真实UI桩已通过。
安装：需现有EV3T3，退出游戏覆盖02中的Interface。已测试覆盖EV3U1者无需重复安装。无SQL、服务端Data/DBC、EXE或编译要求；未上传launcher或部署远程服务器。本包包含EV3U和EV3U1全部客户端改动。
回滚请用原候选包rollback/Interface恢复EV3U；如果需要恢复到EV3T3，使用EV3U包rollback。不会移动装备或修改数据库。
天赋推荐TG1A仍候选，未包含本发布。Claude未提交文件不包含。

来源：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261010\codexfix_20261010_083106_阶段EV3U1_当前标记与条带刷新稳定


## 2026-10-10 EV3U1 已发布
提交c63ff8fabc1ae1e55a86840681abc5d41065ad59，标签reborn-ev3u1-20261010。远端分支及标签目标读回一致，Release附件SHA256 1d3f4e563b04f5914d75a9acc8262c4753e2ced9d6a329cfb445d5e9c7471960一致。仅4文件，Claude改动与TG1A候选未纳入。Release：https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-ev3u1-20261010


## 2026-10-11 OB8A 用户基本验收
用户原话：“[下载 OB8A 配置优化包] 测试这个通过”。范围仅取消自动创建Rsp观察角色及隐藏已登记自动载体的配置；不删除角色、不推定副本/BG/竞技场旁观通过。后续OB8B仍候选。
可复用方法：ProvisionEnable控制未来创建，HideFromCharacterEnum控制旧自动绑定角色的选择页展示，必须分开设置，不能用批量删除玩家角色代替。
来源：[OB8A原包](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261010/codexfix_20261011_000006_阶段OB8A_取消自动观察角色.zip)。该原包保留不改写；用户当前要求本批候选测试后再提交，发布状态单独记录，未声称已发布。


## 2026-10-11 NBC2 用户基本验收
用户明确引用 NBC2 测试包并回复“测试通过”。确认该包随从多选、衣柜风格、停留/跟随功能整体基本通过；不外推未列出的全部战斗/断线矩阵，不代表OB8B或WD138B通过。来源：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261010\codexfix_20261010_231229_阶段NBC2_随从多选与衣柜风格.zip
ZIP SHA256：2c3bca6b038ab55def6b69b86b53070e567b0afa210d86ce970d1986878b550b
源码目前同时存在用户覆盖的未验收OB8B，后续提交须从NBC2原包精确隔离，不把当前botmgr.cpp整文件中的OB8B一起提交。原包不改写；本记录不代表已提交/发布。


## 2026-10-11 NBC2 用户基本验收
随从多选/收起召回基本通过；停留/跟随随包，不外推巡逻/游荡/刷怪功能。
来源：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261011\release_20261011_accepted\NBC2；资源SHA256 d5273b13704843a7bf2041a32639d8e762eab19900ea6b00d799665e60c7e70a。发布状态以同日release_20261011_accepted台账为准。


## 2026-10-11 WD138D 用户基本验收
提基泼洒基本使用通过，单级说明、固定主动入口和缺少基底提示；未全面验证数值和PVP矩阵。
来源：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261011\release_20261011_accepted\WD138D；资源SHA256 68aac4d793089b2024bbd7f7976be7602ba2fad3d295564db15708feb4e1fdaa。发布状态以同日release_20261011_accepted台账为准。


## 2026-10-11 OB8B 用户基本验收
取消自动观察角色通过；副本旁观通过，用户补充“战场也可以进”；竞技场及所有退出/断线异常矩阵未全面验证。
来源：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261011\release_20261011_accepted\OB8B；资源SHA256 fda495b993c18f0dff87067481b46c1cd52d404ff08960fb3322661f29b234ba。发布状态以同日release_20261011_accepted台账为准。


## 2026-10-11 TG1H 用户基本验收
自身当前专精推荐页序匹配通过；完整插件作为运行依赖归档，不表示所有职业/收藏/金币购买已完成。
来源：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261011\release_20261011_accepted\TG1H；资源SHA256 b249734b470e2709fd515e434f78e3c271e71789dbe457c666c4dc0563db0132。发布状态以同日release_20261011_accepted台账为准。


## 2026-10-11 UI8B 用户基本验收
动作条恢复基本使用通过；日志显示右栏位置从2512恢复到1927；偶发DBM技能书弹窗仍未解决。
来源：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261011\release_20261011_accepted\UI8B；资源SHA256 8783c403755f8c60929574282e512df1659074e0b92ec9ecf7f7fea0e1fb71c5。发布状态以同日release_20261011_accepted台账为准。

## 2026-10-11 流程规范类（v2 正式版，2026-10-11 用户确认）

流程类 Skill 不是实机验证的技术方法，单独列出，状态如实标注。

- [coordinate-ai-team-parallel-development](coordinate-ai-team-parallel-development/SKILL.md)：AI 团队（Claude、Codex，以后的 Gemini 等）交叉并行开发。包括开工检查清单、独占区和共享区的占用登记、日常编译目录和发布 worktree 的区分、交付包和整合包格式、阶段编号和日志前缀、交接和评审模板、新成员加入流程。完整规范：[规范_交叉并行开发.md](../规范_交叉并行开发.md)。状态：v2 正式版（Claude 起草、Codex 评审、Claude 修订，2026-10-11 用户确认），所有成员遵守。

## 2026-10-12 WD139C 累计验收发布完成

用户原话：“WD139c搞定了 通过”；本轮授权先发布再进入下一阶段。
提交 a2c79eb79e0d902bb0306235552dca34048f57d5，父提交 42c4b67839a96811dc4dd47721155e161ed89854；wowshub/threemodelcardpro 与附注标签 reborn-wd139c-20261012 的目标已读回一致。
Release：https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-wd139c-20261012
资源 reborn-wd139c-20261012-resources.zip，SHA256 7937db93888515adcf3682d024591975f99fe4843ce3a43f32ea2aceb8565437；GitHub 附件 uploaded、非草稿、远端 digest 与本地一致。

内容：WD139A/B 的256节点数组和新版通信、单一定义生成布局，累计C鱼骨前置修复。当前108槽107节点，不新增天赋。验收为用户基本通过，不外推全方案/PvP/故障注入专项。保留旧存档及旧入口；新旧保存命令均依赖新 reborn_wd139_save。
安装：新装先在角色库执行累计包3文件夹01再02，成功后启动新程序；已有B SQL只需最终02。不要用B旧02覆盖C。已装B+C且测试通过无需重复操作。本批无Data/DBC/MPQ更新；用户自行编译、部署与生产SQL执行。
发布从独立 codex-release-wd139-20261012 worktree 白名单提交24文件；未碰日常脏源码、LFG81A、playerbots或未来WD140。playerbots gitlink仍fb5017f14258ced801eb9a9a11b1b7a9046815b5。
源码Data.lua镜像采用已测试客户端版本保留提基24级设置；原A/B/C包不可改写。当前发布累计包和逐文件清单位于000Ascendupdate/000Ascendupdate20261012/release_WD139C。

复用经验：存储容量扩展不等于新增节点；迁移先冻结旧节点映射，再原子接收完整快照。协议哈希使用解析后规范行，避免BOM/空白引起布局误判。前置错误应在C++、Lua、SQL共同修正并分别验证，不能只改提示。鱼骨保留等级16、蛙骨/大锅和酿造投入要求，移除错误灵魂之触依赖；不能直接回退到B校验。

## 2026-10-12 WD140A 已验收发布
用户确认通过，Claude评审无阻断。提交af97b4a348a284907b8d0939dc08963cafed5244，基于a98a5278保留LFG81A，tag reborn-wd140a-20261012。
Release https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-wd140a-20261012 非草稿，附件uploaded，远端SHA256 a727ff21705f47cd1b0f2b84669a1272c690d8a772a53584ab7a445075eb31a3与原包一致。
12048是从实际旧映射9003661修为9003851；其他三重复键去重不改效果。无SQL/C++，不外推全职业验收。服务端旧展示元数据的说明列入下一批版本台账，不能重新按旧编号接入。


## 2026-10-12 WD141A 用户验收并发布

提交 5708223a9ca1b192be0bdbeebd4502dd33cbfd5c；父提交294b4dc66219502be754e088c972dc1b8a67a60d；tag reborn-wd141a-20261012。
[Release](https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-wd141a-20261012)，非草稿、两个附件uploaded，远端分支及标签目标已读回。资源SHA256 ca168d2fee073cb0aa9c2898ae419c6cad79d258876f13764da471f05071fccb，与冻结原包一致。
范围：面板金币购买第二/第三方案、第三槽开关；无新技能、无技能效果修改、无SQL/DBC/MPQ。用户购买第三方案、激活暗影、小退和reload保存通过；Claude评审同意。未外推全异常交易/NPC路径实机验收。
方法：服务端报价令牌单次消费、revision/槽位/有效期校验，复用NPC原金币与购买记录事务；客户端等待购买时锁编辑，超时提示核对结果而非断言失败。浏览方案与激活方案必须分离，购买不自动激活。4–10仍未开放。
8/8现场安装文件SHA256匹配；原26Lua/16模拟命令、MSVC语法检查是离线证据，不能当真实事务故障测试。发布13文件白名单，未碰日常目录与Claude DCQ1A。资源为现有完整客户端+WD139B/C+WD140A基础上的增量；Git客户端镜像不独立可安装。已测试用户无需重新覆盖。
证据：D:\000rebornWOW\000RebornWOWHighForkPRO\beascendcode\codex-release-wd139-20261012\data\reborn-checkpoints\WD141A\ACCEPTANCE.md。

## 2026-10-12 UI9C 用户基本验收并发布
图标纯秒数、小字号、Tooltip精确剩余；A/B失败过程保留。代码99a15cdcd40fad52ea0abe31447165138e386f96，tag reborn-ui9c-20261012。
https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-ui9c-20261012
教学：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261012\总结教学_巫医与UI9_20261012\00_阅读导航.md
交接：D:\000rebornWOW\000RebornWOWHighForkPRO\新对话交接_UI9C与巫医后续_20261012.md
资源SHA256 cac9f570557fc8159c14ccdf61ce7a223af3e441d44acdfd3cfec63da75a80d0；WD142A机制仍待测，无服务器部署。


## 2026-10-12 WD142A 三项通用天赋用户基本验收
用户针对黑暗帷幕、洛阿共鸣、邦桑迪的虔诚明确确认“测试 通过了 这个不都推到远端了吗”。30/30现场文件与冻结候选哈希一致；Claude评审同意。此前远端4cc4311只有UI9C及归档，WD142A此次补齐发布。未扩大全PvP/多人/数值矩阵。
复用：原生aura271处理本人法术易伤，白字钩子仅补遗漏路径；周期伤害显式系数且World自动系数清零；增强只限定周期。直接伤害自疗核对actor、周期与复制排除，按已结算伤害治疗自身。新节点追加不重排旧索引，旧十进制保存入口转交统一新版校验，拒绝删除无法表达的新节点。
教学思路：把易伤视作结算乘数、跳伤视作定时器、自疗视作结算后的监听器；分别测试才能避免翻倍/递归。布局容量与已用槽位分开；旧格式读进来后仍须用新规则检查再保存。
来源：[WD142A冻结包](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261012/codexfix_20261012_090601_阶段WD142A_黑暗帷幕与通用双天赋/README_安装与测试.md)；[逐行教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261012/codexfix_20261012_090601_阶段WD142A_黑暗帷幕与通用双天赋/tutor.md)；[本轮验收](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261012/release_WD142A/ACCEPTANCE.md)。原包不修改，已装测试通过无需重复部署。

- 2026-10-12 用户确认巫医MPQ归PATCH-XA、后续新职业PATCH-XB顺延；禁止继续将巫医包交给ZA。WD143B为归档纠错，尚非新游戏验收。[规则/来源](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261012/codexfix_20261012_224541_阶段WD143B_XA归档修复/README_先读_按顺序安装.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261012/codexfix_20261012_224541_阶段WD143B_XA归档修复/tutor.md)。

## 2026-10-13 WD143A三技能 + WD143B归档基本验收

用户原话：“测试成功 三个技能通过 给我推送吧”。暗影猎手4006、恶毒箭12086、灵魂回收4505基本实测通过，采用WD143A机制和WD143B PATCH-XA归档；不外推全等级/PvP/机器人/异常矩阵。DBM技能书受保护操作弹窗尚未定位，不记为修复。
复用要点：私有自动射击9003989需同步Spell/Unit/Player的精确原生例外；退出身份仅停止本人私有技能，保留外部75。灵魂回收在AfterCast增加旧灵魂池9003574，失败/取消不加。新增免费节点要同时校验C++、Lua、SQL的专精/等级/依赖，旧格式保存不能删除新节点。
所有巫医资源导入现有PATCH-XA；最新有效数据所在MPQ不等于交付目标。此次ZA仅配套清理6个原LIGHT8文件，先导入XA后清理ZA；不要用小包替换完整XA，旧包不改写。
本轮33现场文件+187个XA条目+ZA清理包相同，发布包逐文件读回；原275SQL/20000差分/Lua5.1/5单元语法是历史离线证据，本轮未重跑。
[验收和发布资料](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261013/release_WD143B/ACCEPTANCE.md)。已装实测用户无需重复覆盖。发布完成状态见同目录最终发布记录。

### WD143B 已发布（2026-10-13）

提交 `860a48e35bf0c793d8ac58314714b54acf213521`，tag `reborn-wd143b-20261013`，分支/标签/Release已读回；资源SHA256 `c1ebee9a4a7dc18cbf19ce75c67522fea5a76e33e600a5821fcaa1ba2a746752` 与GitHub digest一致。[Release](https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-wd143b-20261013)。用户具体授权附件后完成。详[最终发布记录](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261013/release_WD143B/最终发布记录.md)；已装测试通过无需重复覆盖；DBM弹窗未定位。


## 2026-10-13 WD144A 候选参考（不是已验证方法）

[本批来源/适配与离线边界](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261013/codexfix_20261013_011752_阶段WD144A_暗影强化与诅咒选择/memory.md) · [代码与测试教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261013/codexfix_20261013_011752_阶段WD144A_暗影强化与诅咒选择/tutor.md)。两个暗影双级强化与两个互斥通用诅咒附效；301隔离SQL/实际Lua/旧布局差分/修饰白名单/语法检查通过，未游戏实测。失败反例：只更新node_def而漏旧rank CHECK会导致一级可存、二级失败；只按非酿造TE识别巫毒会误拒新暗影点数。资源继续导入现有XA。待用户确认后才登记成功，不继承WD143验收。

## 2026-10-13 WD144A+B 用户基本验收
# WD144A+B 用户基本验收（2026-10-13）
用户原话：“这次这一批的技能通过 推送吧 继续下一批的开发”。
范围：强化恶毒箭1969、洛阿之力7779、腐朽诅咒12749、巨蛇意志29749，A机制与B最终冷却同步/诊断组合。用户后续要求独立目标debuff图标为新WD144C候选，不纳入本次发布。
截图明确证据：恶毒箭服务器calculated_ms=4000且二级光环amount=-4000、arrow_match=1；洛阿属性面板有变化；腐朽own_jinx=1/periodic_healing_pct=-30，巨蛇own_jinx=1/crit_bonus_points=10，互斥另一项为0。截图查询remaining_ms=0，并无即时冷却采样；总体通过按用户基本验收登记，不声称暴击统计、HoT精确数值、所有等级/PvP/机器人/跨图/死亡/多人专项已完成。
A遗漏post-GO冷却和动态提示为失败记录，B补齐。迟钝诅咒在实际技能书名为“迟缓诅咒 / Lethargy Jinx”，Spell9003150。两个附效在父诅咒内，当前没有独立图标。DBM受保护操作弹窗未修复。
保留WD139C存档前置、WD143B机制与XA归档。未新增方案4–10。本轮未部署、未运行生产SQL或编译EXE、未上传launcher。
发布准备基线437ff5e9e087cb4229ea5f359de4dac10ad6bcec；源码/客户端镜像逐文件与现场匹配，双端资源独立读回与A冻结件一致。
历史离线证据：A301SQL/20000布局差分/128128修饰范围及语法；B126实际Lua5.1/194postGO片段/两单元语法通过。本轮验收归档未重跑，不冒充游戏测试。

资源SHA256：d6bdbbca04cf0bdb5620c3de9ab9d730e153982aa79d61c57958c4d658f088c7

来源：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261013\release_WD144B\ACCEPTANCE.md
教学：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261013\codexfix_20261013_050718_阶段WD144B_恶毒箭冷却同步与诅咒诊断\tutor.md
方法：私有原生SpellMod须同时接通服务端计算、post-GO客户端计时和权威Tooltip；目标限定暴击不改全局面板，诊断须核对caster GUID；不要以单次暴击或光环挂载替代统计与治疗结算专项。

## 2026-10-13 WD144C：目标附效可视化已基本验收
用户确认“有了 测试通过 可以推送啦”。
来源：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261013\codexfix_20261013_061615_阶段WD144C_巨蛇与腐朽目标减益图标；冻结ZIP SHA256 288815cba794cd62e7716f3d62690caf890d5ed6c6e9060d1fae154c852f0caf。
验收：巨蛇/腐朽独立目标减益图标基本可见与使用通过；多人/PvP/所有生命周期专项未完整验收。
方法：父诅咒保留真实308/259数值，额外负面可见PERIODIC_DUMMY只展示；全部关联按父SpellID+施法者GUID，应用/刷新同步时长，移除父光环即清除；不能在显示光环重复数值。双端DBC分别新增并保留旧记录，world绑定守卫且幂等。反例：只改Tooltip不能让目标出现独立图标；只导客户端表不能代替配套服务端代码和绑定。
验收证据：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261013\release_WD144C\ACCEPTANCE.md；教学与实际代码：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261013\release_WD144C\TUTOR.md。


## 2026-10-13 WD145A 候选索引（未游戏验收）
灵魂蚀、暗影洛阿之灵、灵魂信徒、村落智慧；沿既有灵魂/灵魂回收依赖接入。仅离线验证，不晋升为成功案例。
[来源与适配](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261013/codexfix_20261013_085922_阶段WD145A_灵魂循环四节点/来源与适配说明.md) · [实际代码教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261013/codexfix_20261013_085922_阶段WD145A_灵魂循环四节点/tutor.md) · [测试交接](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261013/codexfix_20261013_085922_阶段WD145A_灵魂循环四节点/README_覆盖与测试说明.md)。


## 2026-10-13 WD145A+B 用户基本验收
灵魂蚀/暗影洛阿之灵/灵魂信徒/村落智慧，以及暗影分类/命中显示通过。灵魂数在施放前快照，追加施法必须排除递归；满层刷新仍是获得事件。百分比命中不同于命中等级，显示从服务器实际光环确认，不按草稿推断。被动也必须补SkillLineAbility分支映射。DBC字段以实际结构为准，注册宏完整名字与SQL逐字核对。
[验收](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261013/release_WD145B/ACCEPTANCE.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261013/release_WD145B/TUTOR.md)；资源SHA256 44dc667e48263b8913bf5520f752471e9d5c58c083673f91ec374de00a1050cc。发布状态以后续最终发布记录为准，未部署或生产SQL。

## 2026-10-14 用户确认的流程规范（不是实机成功声明）
- [audit-and-port-upstream-features](audit-and-port-upstream-features/SKILL.md)：所有技能/功能修复开发的上游核对、逐项联动、可见减益、特效与端到端检查；团队及新成员必读。


## 2026-10-14 WD146A–C / WD147A–B 用户基本通过
# WD146/147 已验证经验与边界
1. Aura CalcAmount时没有AuraApplication；通过GetUnitOwner并判空，不借用只能在Apply阶段访问的Target。
2. 新技能加入查询白名单不够，必须核查计算分支→协议→Lua。默认0不能解释成瞬发。
3. 拆开已学习、已保存、当前光环有效三种状态。沃金祝福依据暗影化身真实光环，基础CD与活动剩余时间分别解释。
4. 原版模型→材质→SKIN/ANIM及VisualKit附件完整迁移，专属路径避免冲突。资源装对不等于服务器产生显示Aura。
5. 短命辅助Aura在Unit更新前刷新会被同帧diff扣掉；Player更新后同步父寿命，每帧清理过期、死亡、减层。读数一次采样，避免不同时间截图混淆。
6. 新诊断.wd147check只读；orbs位掩码1/3/7/15/31对应1–5球；missing/failed帮助区分DBC缺失与创建失败。
7. 用户本轮确认基本通过；所有旁观、死亡驱散和高负载边界仍不得冒称专项通过。保留失败原包，后续验收另记。

[验收](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261014/release_WD147B/ACCEPTANCE.md)；发布结果以后续最终发布记录为准。


## 2026-10-14 WD148A 残余能量基本验收
# WD148 开发教学（候选经验，不是成功验收）
先区分父法术、周期触发槽和子法术。706544的周期槽数值不负责减冷却；706803自定义Effect192才是真正执行入口，所以不可只扫一行DBC。
本核心用周期Dummy适配子法术，单位是毫秒；原生魔法伤害百分比独立保留，不在脚本再次乘1.1。
AfterEffectRemove只绑定父效果0一次，移除原因限定EXPIRE。GetTargetApplication只能在有应用的回调使用，不能在CalcAmount照搬。
次级Buff进入技能书会误导玩家可主动施放；只对被动注册SkillLineAbility。诊断需区分avatar与lesser，不把完整化身的0当成次级化身无效。
视觉模型、贴图、skin和声音一起私有化；冲突版本来源全部保留，不能随机取最后找到的文件。
用户实测前不将此候选提升为成功Skill；预期与边界见完整移植检查表。

2026-10-14用户本轮确认基本通过；原文候选状态是历史，不扩大专项。

[验收](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261014/release_WD148A/ACCEPTANCE.md)；发布状态见后续最终发布记录。


## 2026-10-14 MBCRASH1B 机器人缓存寿命
[repair-playerbots-unit-cache-lifetime](repair-playerbots-unit-cache-lifetime/SKILL.md)：用户原场景复测不再崩溃；仅基本通过，未扩大全部竞态/长期压力。

## WD150B 已验收并发布（2026-10-15）
提交7a96329a605fc52cf99ba57c44a1c747c98930a9，父98a991f1e9141067ac8b281d18d8aa214df3be6e；wowshub/threemodelcardpro和tag reborn-wd150b-20261015解引用已读回一致。
Release https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-wd150b-20261015
非草稿，资源reborn-wd150b-20261015-resources.zip已uploaded，17,301,290字节，远端digest与本地SHA256 f4508ee14231ede5ddfc805843777315c7469e474184388a744343f0710c9e43一致。
33文件白名单，89份最终安装资源匹配。累计WD149A/C、WD150A/B、UI10C/E/F；UI及技能本轮基本通过，不扩大全部专项。Git首次归档原生FrameXML/SpellBook保留祖先空白；非空白差异检查通过。保留28项无关工作树变化，未部署/编译EXE/生产SQL/launcher上传。
已安装测试通过用户不必重装。安装及Chars/World/双端DBC/三个MPQ分工见release_WD150B/resources/README_先读.md。
下一批WD151A拟接暗影附魔两级、潜伏诅咒、黑暗洛阿咒语，按诅咒目标与驱散/AoE链复核，不能继承本批验收。当前节点表另有31项未正式接入；此数是天赋节点缺口，不是整职业全部功能结论。

## WD151B 四技能基本验收并发布（2026-10-15）
用户原话：“这个修复好 这4个技能就通过了 并推送吧”；Jinx诅咒时长延长另有明确确认。暗影附魔6011两级、黑暗洛阿6073、潜伏诅咒29743及苦难、洛阿之力29729基本通过；不扩大所有概率、AP互斥、全等级、多人、PvP专项。B仅说明字段改变，明确Jinx范围排除Hex。
提交e5197b186d7110cd7769e38e4c0899d43337cb55，父7a96329a605fc52cf99ba57c44a1c747c98930a9，分支/tag读回一致。
Release https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-wd151b-20261015
资源uploaded、非草稿，8,136,376字节；本地/远端SHA256 cfb33062e731585b0ae8f2e7b7d2ef208a745173216852cb43f06cbd620315e1一致。20文件白名单，16现场安装资源匹配A。B描述修正已授权发布，待客户端文字读回；无需重新编译/SQL。未动28无关工作树文件、日常原件、生产SQL、部署、EXE。
来源WD151A包52aff2e82740cec851ff269862a803f38bd653af0322236fa6403b1ddb380118；B包5591eb57a1bee1b2ed8beeec58fd0b4d9f8469696d9f1afdcac4c0e00836d45c。
经验：Hex与Jinx不可翻译成无范围的同一“妖术”；按精确mod集合列出受益技能。原生Aura108按精确白名单增加效果/时长，不能用技能书固定描述判断实际Aura。25/50两级悬停保存/草稿均回归；Mana抑制100%封顶。目标实际时长已由用户确认。

## WD152B候选反例：核心过滤先于脚本几率
来源 D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261015\codexfix_20261015_081829_阶段WD152B_灵魂触发与灵魂蚀条件提示
传统派spell_proc缺命中阶段导致真实核心过滤拒绝，SQL存在并非生效；B Damage1/Hit2修复，428隔离SQL与实际函数夹具通过，游戏待测。检查表必须含阶段/类型/命中/XP、已有行升级而非仅插入；不把64个进入过滤后的事件当成64次获魂。

## WD152B 用户基本验收并发布（2026-10-15）
用户原话：“这批技能通过 给我推送到远端 吧 我们明天就绪”。WD152A+B三节点7031暗矛传统派、11330邦桑迪之刃/29930丹巴拉的致命二选一，以及灵魂触发阶段、灵魂蚀缺魂提示基本通过；不扩大精确概率/全等级/多人/攻速互斥/PvP/全部生命周期专项。
提交2c3693e395b5d9ca3d20d6276314cb3632645629，父e5197b186d7110cd7769e38e4c0899d43337cb55；wowshub/threemodelcardpro与tag reborn-wd152b-20261015解引用读回一致。
Release https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-wd152b-20261015 ，非草稿、两个附件uploaded，digest与本地一致。
本批累计资源8,139,671字节，SHA256 267aaa50f7c18424926682674dda55beb098ae5e9d8f4785ce3e0ec2654666ae。
当日已验收客户端/服务端Data+SQL并集17,333,523字节，SHA256 db094585494cc37480815e1a5453c5faf5ced0f51b9edf4cda81c18249e354ae。含WD150B、WD151B、WD152B；98份最终运行资源匹配，双端独立，三个原生/技能MPQ分工保留。Characters只最终152A01→02；World149→150→151→152B（B替代152A世界SQL）。已安装测试通过无需重复操作。
24文件显式白名单提交，保留28无关mode与pycache，不改日常原件；未部署/生产SQL/launcher上传/编译worldserver。
技术复盘：Proc行存在不能证明入口生效，DONE_PERIODIC仍需HIT2，原phase0挡在30%抽取前。B更新已有行而非INSERT IGNORE；实际核心函数旧64/64拒绝、新64/64进入后续判定，428临时MySQL与函数/语法/双端不变量通过。Edge官方Mask对应范围9004021，原生+40%一次，不强化主目标、不重复脚本乘。Shadowflare整次快照一次，避免多目标只有首个享受丹巴拉。资源不足具体提示仅限真实缺魂分支。
旧A/B包及候选记录保留，以本条说明后续验收和发布状态。今天停止新技能开发，明天按剩余节点依赖台账继续。

## WD153A 三技能用户基本验收并发布（2026-10-16）
用户原话：“下载 WD153A 三技能联动测试包 测试通过 推送吧 我来继续测试154A”。6010魔精高涨、11164妖火群蛇、29981巨蛇诡计基本通过；不扩展所有概率、全等级、多施法者、PvP及生命周期专项。154A、155A、156A继续候选，不纳入本次发布。
提交932939c22202a1db5d5724bea6ec31d03fe7d7c4，父2c3693e395b5d9ca3d20d6276314cb3632645629；wowshub/threemodelcardpro与tag reborn-wd153a-20261016解引用读回一致。
Release https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-wd153a-20261016
非草稿，target=threemodelcardpro，资源reborn-wd153a-20261016-resources.zip uploaded，16,156,048字节，本地和远端digest一致：7ad4faf888750a24c06f6b8eccc7b6f7f6b6e972896cfeb7d103bed51cdf6ca0。
原测试ZIP3a1106537230dc29b492f25bbf27ca42589535e7409cff35088cf56e289705b9不改。29文件显式白名单提交，保留28无关mode和pycache。全部双端资源匹配153；日常7源码已经154，按冻结153发布，未替换日常文件或冒称EXE和tag完全核对。
本批141槽157bits40hex，额外拟态与天选之人叠加1/2/2/3且延长3秒；自己的Hex周期30%/3秒触发独立10秒蛇；恶毒箭实际伤害15%每秒4秒自然毒伤，刷新不叠。守卫GUID分组与旧普通/群蛇隔离，沿原巫毒火与真神链；派生毒伤排除灵魂/回声递归。实际Lua、443私有SQL、3Zs、核心方法与125资源检查为原离线证据，本条新增用户基本验收。
已按WD153A安装通过无需重装或重复SQL。新装适用完整WD152B：Characters最终15301→02，World153，双端8表分别安装、客户端导入现有XA；不混用，不写ZA。助手未编译worldserver/部署/生产SQL/launcher上传。
发布证据、运行时比对、资源与安装说明：000Ascendupdate/000Ascendupdate20261016/release_WD153A。初次推送审批因目的地归属未验证拒绝；只读核实登录wowshub/仓库owner及admin/push后补证重试获准，未绕过拒绝。

## WD154A 用户基本验收（2026-10-16，发布处理中）
用户点名原累计测试包并明确“测试通过 推送吧”。幻象29747及森金迅捷7154/智慧11154二选一基本通过；本次按冻结659b2cfc6a28926a68ba5bf60752cb02516b78340736e9fc54996487be13bf07发布，不外推多人/PvP、全生命周期、精确视觉专项。幻象成功AfterCast给5灵魂、原生隐身+独立50%移速+本人分身、当前威胁每秒-20%，Swift精准-60秒CD或Wisdom+20秒持续；两个天赋互斥。Family19第三段0x20000000隔离旧Jinx；镜像读取可见衣柜条目与三个虚拟武器，仅NPC900254+本人Clone4113，其他路径不动。速度Kit7/14关闭的兼容降级保持记录，不称完整原版视觉还原。155/156仍候选，未部署/生产SQL/编译worldserver；发布最终SHA和Release随后记录。

## WD154A 用户基本验收并发布（2026-10-16）
用户原话：“下载 WD154A 累计测试包 测试通过 推送吧”。幻象29747、森金迅捷7154/智慧11154二选一基本通过，不扩大所有等级、多人/PvP、生命周期和精确视觉专项。155A/156A继续候选，未纳入发布。
提交71e64def58aa0d0c33779a1cf6cb2ef8288dcbd0，父932939c22202a1db5d5724bea6ec31d03fe7d7c4；wowshub/threemodelcardpro与tag reborn-wd154a-20261016解引用读回一致。
Release https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-wd154a-20261016
非草稿，target=threemodelcardpro；附件reborn-wd154a-20261016-resources.zip uploaded，17,054,523字节，本地及远端digest相同：90945970a9e7d548837fdc566705ba1257d7148cd46cb6aad7dc6c338db5d553。
冻结原测试ZIP659b2cfc6a28926a68ba5bf60752cb02516b78340736e9fc54996487be13bf07不改。27文件显式白名单，保留28无关mode/pycache。现场76/90文件匹配154，其余7日常源码、4Lua、3服务端表已匹配155候选；只发布冻结154，不覆盖现场或冒称当前EXE已核对。
幻象基础20s/180sCD，成功AfterCast灵魂补到5层，50%移速/逃跑分身，当前威胁每秒-20%；直接非触发实际伤害/有效治疗破隐、已有周期不破隐。迅捷只减幻象60sCD，智慧只加20s持续，互斥。Family19第三段0x20000000独占幻象；本人NPC900254+Clone4113读取PLAYER_VISIBLE_ITEM/虚拟武器，其他镜像不变。速度Kit7/14未兼容组关闭的边界继续保留，不称完整原版视觉。
465隔离SQL、实际Lua、4Zs、真实核心/生产方法摘取及135资源检查为原离线证据；本条新增用户基本验收。144槽160bits40hex，旧141槽保持。源包和发布资源依赖闭包包含已验收153，不含155/156。
已安装154测试通过无需重复覆盖/编译/SQL。新装Chars只最终144槽01→02，World已装153只154；从152B则153→154；双端独立8表、客户端导入现有XA。已装155/156不能用此附件回退。未部署/生产SQL/编译worldserver/上传launcher。
证据与安装说明：000Ascendupdate/000Ascendupdate20261016/release_WD154A。

## WD155/156与B-D修复用户基本验收并发布（2026-10-16）
用户原话：“这几个bug都解决了 测试通过 帮我推送吧”；另要求推送前检查Claude Playerbot相关修改及共同开发文档。六节点6044魔精狂乱/6050独臂华尔兹/6049为了洛阿、4572金布尔之眼/6035驭蛇者/7355狂乱灵魂，以及155B布局崩溃修复、156B群体药AI图标与静滞4/5秒说明、156C拟态4140真实存在Buff与安全点击、156D Lua/XML加载配对修正基本通过。不外推全等级/概率/多人/PvP/长期压力或全部生命周期专项。原A崩溃/C缺函数反例保留，以最终D通过为当前状态。
提交 375b77f5b94363dce3045f13bc60b93c34ba6ceb，父ac66d6c6bbedc63e96ce14ac408791607e20a1d6；wowshub/threemodelcardpro与tag reborn-wd156d-20261016解引用读回一致。
Release https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-wd156d-20261016
非草稿，target=threemodelcardpro；资源reborn-wd156d-20261016-resources.zip为uploaded，17901156字节，本地及远端digest一致e9b9f42ea14f87135390f2523de1b96a5d454fcfa3038d9a7d1ba7267d7227d7。
48文件白名单，19源码/125实装资源全部匹配最终C+D冻结并集，原28无关mode及pycache保留，未改日常工作树。已读协作说明/规范、Claude交接、DCMOV3A README及远端验收；完整保留Claude DCGM1A/DCTEST6A/DCMOV3A祖先及Playerbots gitlink b0369e5137a4e3efa88882add4e44c0129d25fdc，不改子模块/清本、不带DCTEST7A候选。登录wowshub ID157596749、仓库owner/admin/push只读核实后正常推送，无强推。
资源是C+D逐路径并集，客户端松散与enUS5原生UI成对Lua/XML，技能数据仍现有XA，服务端独立8表，Characters仅最终150槽01→02、World已装155仅156，停154则155→156；已完整安装测试通过无需重装/重复SQL。无Auth迁移；无EXE/PDB/配置/玩家数据，不部署/生产SQL/上传launcher/编译worldserver。
复盘：新增Spell成员会导致增量混合ABI，修复恢复344/352布局外置加锁快照；仅语法不证明最终链接一致。技能书新XML必须配同入口Lua，loadstring不检查加载闭包；最终D原生安全OnClick保留、PostClick无新全局依赖，233rank主动分发及缺依赖复现检查。拟态显示依真实自有GUID/最长timer，用户确认基础约12秒非60秒CD；AddAura零数值不产战斗Proc。群体药独立910195私有图标不改假死/普通药；静滞条件说明不擅自全局提高基础控制。
证据：000Ascendupdate/000Ascendupdate20261016/release_WD156D。正式150槽166bits42hex，另12节点仍未映射，未自动开始下一批。


## 2026-10-16 WD159“代价”完整联动专项实测通过
用户原话：“我按照这个顺序 发现暴击可以了 冷却都对了 是我忘了按灵魂蚀”，随后“测试通过了”；又明确“目前只确认代价的联动通过”。范围9004172代价：持5层灵魂成功施放灵魂蚀，重置9004030—9004036灵魂战刃冷却并获得9004175的8秒就绪，下一次普通战刃必定暴击且9004150暗影追猎当前剩余冷却减15秒。不要求仅持5层直接战刃就触发，不能把前置步骤遗漏当作服务器缺陷。保持已测逻辑，不为假问题改玩法。灵魂齐射减3秒仍待核实；UI分类图标G候选和死亡妖术未保存截图反馈不继承通过。来源WD159A经WD162A—F累计；F冻结830375b107fedc35a70ae78db29692e8a905893d33a1d00ac970dd0748646182，Shadow159原SHA256 cfe1acef6ddd8bc83689d4215a9f6c00da27d5855624100ad8d3a5053e86d4c0。尚未提交/推送/发布；WD159整文件含其他待确认节点，不借专项反馈发布未测依赖。
可复用：按资源前置→触发主动技能→就绪Buff持续→受益技能→消耗/减秒逐段验收；先问施法顺序和查看Buff，伤害大小不能单独证明暴击；基础冷却/当前剩余/下次预存减秒必须区分。原失败证据保留。


## 2026-10-16 WD157死亡妖术：保存后目标减益显示通过
用户先提供Selected1/1未保存、Server-saved0/1截图；确认“刚才还没保存，我先保存再测试”，随后“有了 太棒了”“这个也通过了”。专项确认9004152保存激活后恶毒箭命中产生9004155目标可见减益；不因未保存预览改服务端，不把本次目视确认扩大成20%/40%实际治疗数值、多人归属和PvP全矩阵验收。源F冻结830375b107fedc35a70ae78db29692e8a905893d33a1d00ac970dd0748646182；Shadow157 SHA256 7d46d7d63229fc73e24da91168001bc765ff888547bd7ec81ff04b3283734cda。代码不改。
复用：先确认Selected与Server-saved一致且方案激活，再检验触发技能、伤害命中、目标减益；未保存的预览明确不生效。


## 2026-10-16 WD157A/WD158A分批发布读回
用户明确授权之前批次一个一个推送；按依赖先发布157/158。157提交4e49c4bf2765773058ab4e8590b4724af6493de2，tag reborn-wd157a-20261016；158提交11fc2f554ff3dfe36cc96f0407240d4bcf277e86，tag reborn-wd158a-20261016。远端threemodelcardpro=11fc2f554ff3dfe36cc96f0407240d4bcf277e86，两个tag peeled SHA均一致；两Release均非草稿，附件digest分别ff38c3800bc08bfdc6a1ddf29ea352aec361c45987c05c6881f8da033de37fba（36505968字节）、2b2e330d87d30fbd7355d49cf1a38a0094fe0fb830eb7f0a6a6a4e7a1b689ef2（38226095字节），与原冻结包一致。GitHub归档附件中文名称自动变为codexfix_20261016_104754_.WD157A_.zip与codexfix_20261016_120319_.WD158A_.zip，内容摘要正确。
Release：https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-wd157a-20261016 和 https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-wd158a-20261016 。基本玩法与发布授权，不扩展为全部PvP/概率/多人矩阵；死亡妖术额外保存后减益目视通过。输入原文件哈希与显式白名单核对、cached diff check通过，未暂存原29无关改动，未改Playerbots/DC。WD159灵魂齐射仍待定位，160/161依赖159暂不晋升发布；Price专项已通过不能借此发布159整文件。未构建worldserver、未部署、未生产SQL。

## 2026-10-17 WD159A—WD161A 用户基本验收并分批发布
用户原话：“所以我有一次看到他好像突然减了几秒 我感觉这个应该是通过了 发布这批次的技能吧”。灵魂齐射按用户判断记为基本玩法通过；最后诊断before=0/after=0只证明当时无剩余冷却可减，不作为精确3000ms计量证据。成功施放齐射才给1灵魂并减少已运行的战刃剩余冷却；仅获得6秒就绪不触发减秒。Price需5灵魂→成功灵魂蚀→8秒内普通战刃，用户已确认必暴击/追猎减15秒；死亡妖术保存激活后可见减益已确认。未外推完整数值、PvP、多人、全等级矩阵。
按依赖闭合分批发布：WD159A c26f301b6a95ab0b0dc1f89e1a2078c840b7bdc5；WD160A c6800ba0d5dabf87e8e060109d259248fdcba236；WD161A db6de62dabf02ae5cd56e2d2e807bc1f8e17fa75。对应tag reborn-wd159a-20261017、reborn-wd160a-20261017、reborn-wd161a-20261017，远端解引用逐项一致，正式分支=db6de62da。
Release（均非草稿，附件uploaded，远端digest与本地一致）：
- https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-wd159a-20261017 ：22996643字节，763dc5af212e294b4da3367e660dcf996d2b8cb8a55f5dc34a5652bb1a24a742。
- https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-wd160a-20261017 ：26453820字节，2be9fcfec80d7ad3161af9dc820535cf73913c748506e5da4f130287b7f20491。
- https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-wd161a-20261017 ：26480560字节，c1a95c264c8783c6e598dd8e62e62ca34aabebbdf955d988e3d5e831b51eecb1。
本条更新此前“159等待/160161依赖未发布”状态，旧冻结记录不改。累计资源保留已测G的wd159check诊断，Price/Eclipse/Glaive玩法代码核对不变；160/161带B的愚者把戏20秒存在Buff9004186及双端Spell.dbc，120秒技能冷却不改。所有附件排除FrameXML，C—H技能书UI仍独立待测，不借技能通过宣称UI通过。原ZIP不改，新ZIP逐条哈希/CRC读回通过。
发布工作树先快进保留Claude 003068e18聊天验收记录；27/25/23显式白名单提交，cached diff check通过，原28修改+pycache保留；Playerbots gitlink b0369e5137a4e3efa88882add4e44c0129d25fdc不变，不发布Claude候选，不改日常编译源/运行客户端。
已安装WD162累计并测试的用户无需重装/重复SQL。自156D新升级：World只尚未安装157→161增量；Characters仅最终阶段01_node_reference→02_save_rows；双端DBC独立，客户端导入现有PATCH-XA。无Auth、EXE、生产SQL或部署操作。最终164槽180bits45hex不等于全职业所有玩法矩阵验收。
适用Skill：release-tested-reborn-features（含daily-sync）、coordinate-ai-team-parallel-development、audit-and-port-upstream-features；本次是验收发布，没有新改玩法。可复用经验：先区分就绪与成功施放；减冷却验证必须先存在剩余冷却；不要用零剩余或正常自然倒数认定精确减秒；小阶段资源发布必须保留后续已测修正、排除未验收UI，不能机械上传最初候选包。
发布资料：000Ascendupdate/000Ascendupdate20261017/WD159A_accepted_package.json、WD160A_accepted_package.json、WD161A_accepted_package.json及各release_notes.md；Git各tag的data/reborn-checkpoints/WDxxxA/ACCEPTANCE_20261017.md和ACCEPTED_RESOURCE_MANIFEST.json。


## 2026-10-17 TG2A 巫医推荐候选参考（尚未实机验收）
来源：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261017\codexfix_20261017_104830_阶段TG2A_巫医四类天赋与雕文推荐.zip。四类推荐复用既有AE/TE校验与版本化hex，仅加载本地草稿，不直接存档或收费。284等级方案交叉生产C++通过，实际UI/原面板保存仍待测。雕文可信0：同时核对367文件属性+5条DB补充和触发系统开关，不因允许全职业或文件缺行误判。详情见000Ascendupdate20261017/codexwork_TG2A。本条仅候选流程与反例，不新增已验证能力。


2026-10-18：TG10A经典职业入口、三卡首页和单系树基本通过，已补入 stabilize-spelldraft-client-ui 同名Skill/Tutor；美术可读性TG11B候选待游戏测试，早期累计应用/雕文收益不继承验收。


## 2026-10-19 TG16A 图鉴按等级推荐联动实测通过

用户原话：“这下这个图鉴 系统 按照等级推荐 的联动 可以了 测试通过 可以推送了 我明天继续测试”。验收限图鉴按等级推荐联动，以及本次使用中的保留已学补点流程基本通过；不扩大到全部职业、全部收藏/导入导出、互斥/收费/异常保存矩阵。后续测试仍待继续。

方法：推荐模板与实际已存方案分层。已存rank高于模板rank不等于互斥；从权威已存mask逐级补点，每次复用原规则校验。保留全部已存rank，受实际等级/AE/TE预算约束，真互斥节点跳过。接受确认只载入本地草稿，保存仍由用户在原面板执行。确认前后复核revision、slot、layout hash、savedMask、targetMask、预算；保留错专精、脏草稿、同步、战斗、等级预览保护。灰按钮展示实际阻止原因。

反例：TG15A原savedRank>idealRank判断误拦兼容选择；不能只因不在推荐清单就建议洗点。离线27级6/9 AE、1/9 TE兼容净化神像案例可复现，但不能冒称是用户真实节点。已学补点结果可能不同于标准树图，实际应查看确认框/草稿。

冻结TG16A包SHA256：28cd75e5a52fd4bf4c31c4a449794e304a122935855bae1f065ba5d300e04575。55/55现场文件匹配。技能、存档、服务器规则未改；无SQL/Data/MPQ更新，无需编译或重新覆盖已测试客户端。


### TG16A 发布完成（2026-10-19）
提交606a607c877df8ca5bea0ad2006b78738f0b7bb8，父27e66458dab470b3106b4e9c245257764103f606；wowshub/threemodelcardpro及附注tag reborn-tg16a-20261019解引用已读回一致。
[Release](https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-tg16a-20261019)非草稿，附件reborn-tg16a-20261019-client.zip uploaded，19135369字节，远端digest与本地SHA256一致28cd75e5a52fd4bf4c31c4a449794e304a122935855bae1f065ba5d300e04575。
41白名单文件提交，累计Lua/TOC依赖归档及验收清单；18BLP在资源附件。现场55/55匹配。无关28mode变化及pycache保留未暂存；playerbots gitlink保持a09f38ed8a664e92539ab290d4f3ab9fe526bf95，不改Claude功能。标准diff检查仅发现原实测文件三处EOF空行，保留实测字节，仅豁免blank-at-eof后通过。无新逻辑改动。
用户验收为图鉴按等级推荐联动通过，不扩大到全部职业/收藏专项。已经测试通过无需重装；无服务端Data/SQL/DBC/MPQ及编译需求。未部署、生产SQL或launcher上传。明天由用户继续测试，不安排自动任务、不开始新功能。


## 2026-10-20 WD167A 已验收并发布
用户确认“WD167A：巫医召唤自动选敌安全修复。这个也测试通过”，随后要求推送后继续开发。Claude本轮已完成正式验收9e9b79668。独立重放WD167A三个生产函数，规范换行后与用户测试原包相同，32805夹具重过；不夹带WD166A或旧TG13A，不改Claude功能或Playerbots。
提交98b1bf6ef406411322f19f6d72569a26ce5405d9；wowshub/threemodelcardpro及tag reborn-wd167a-20261020解引用已读回。Release https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-wd167a-20261020 非草稿，附件uploaded，SHA256983966358126093e8a4d6e37f2c9e802675f70572240760d5fa016651c0327a0与远端digest一致。已测用户无需再次覆盖，正式源新用户自行编译；无SQL/Data/客户端/DBC/MPQ更新，不部署。
可复用：选中敌人不等于实际参战；自动召唤伤害按owner GUID、存活/世界、地图/相位、实际战斗关系、LOS与可破控过滤；收集候选后每次施法前重查，保留死亡中心对合法邻近目标溅射。只作用自动伤害，不改变手动技能、治疗、概率、范围和攻击周期。用户为功能基本通过，不扩展全PvP/控场/多人/全部召唤矩阵或完整巫医机器人AI。


## 2026-10-21 巫医Playerbot基础AI验收与复用
用户明确选择WD176A累计晨测总包允许发布，实测观察输出改善、六蛇技能使用；不外推精确DPS比例、三系所有主动、交易/生命周期或177–184新治疗。新增[port-coa-playerbot-class-ai](port-coa-playerbot-class-ai/SKILL.md)，对应Tutor同名，记录已存方案/真实已学、主循环+通用技能、正常资源、自动来源和安全副目标/召唤、固定副本测量。冻结176包43d6db520e3d86e37ac5d951f19894bb2e8d968244d9bc451a769e5807f9f6e1；正式提交状态见协作说明。原167验收保持。


## 2026-10-21 新反馈：弹药可用性漏判
WD170仅按武器属性评分，之后才找弹药，导致无子弹枪顶掉能用弓；用户已复现。装备自动选择不再作为完整验收能力，WD185候选按真实武器+携带可用弹药配对修复；尚未实机确认，不晋升成功方法。原输出/六蛇基本反馈保持。


## 2026-10-21 WD185A 用户基本验收并发布
用户原话：“现在自动换远程武器 机制是正确的了 这个测试通过”。确认本次武器与携带可用弹药配对选择基本通过；不外推全等级/所有装备、NPCBot、精确DPS或WD177–184治疗候选。
可复用：先过滤无可用弹药的弓/弩/枪，再沿用原属性评分及原生装备资格；成功换装同次选弹，防止高分无弹药枪反复顶回可用弓。保留脱战/站定检查、真实46699原生例外；不赠送购买、不读银行。正式176头与原包备份文本一致，仅发布185最小头，未混入治疗或Context标记。
主仓a5c8532d5b70329d6f9263a17b323f9a7bc1896a；Playerbots25a6feab74edf2e647f7ce44d062008176e37e77；tag reborn-wd185a-20261021。远端分支/标签读回，非草稿Release与附件uploaded/大小/SHA256核验。源码附件SHA256 d8ceed683a6048f68c8de45be953652ce5aa395ba1ca37df2541569e1ab7f4e4。
Release：https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-wd185a-20261021
已装WD185测试通过无需重复安装。无新客户端/Data/SQL/DBC/MPQ/配置EXE，未部署。原冻结候选包不改，验收与发布证据见000Ascendupdate/000Ascendupdate20261021/release_WD185A。


## 2026-10-21 WD186A 首次启用引导用户基本通过并已发布
用户原话：“首次启用引导测试包 测试包也已经测试成功”。验收限新角色首次启用引导基本体验，不外推所有语言/缩放、网络异常或存档费用专项。未启用/未知/已启用但低等级分开显示；确认框捕获revision，接受时复查状态；等待原服务器回包，不自动授予点数或绑定专精；原美术保留。14组Lua5.1真实文件加载与模型点击通过，用户现补基本实机；取消路径为代码审查，不冒称NO/Escape事件全回放。
主仓e7a6d90dd6a59fb83affbf8f02c0349e8bea5e4d；PB保持25a6feab74edf2e647f7ce44d062008176e37e77。tag reborn-wd186a-20261021；Release与附件uploaded/大小/digest核验，原ZIP SHA256 479ebc526b82c69e73f4378b784d3277aee47cb5c5dc6ed23071d1c08c6bcd64。
Release：https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-wd186a-20261021
正式此前无Panel镜像，首次归档已用基线及本次增量；仍需现有完整插件，单文件不是完整安装。无服务端/Data/SQL/DBC/MPQ/配置EXE，未部署。原冻结候选包不改。
本窗口完整总结教学与新对话交接：D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261021/总结教学_巫医AI与首次启用_20261021_完整归档/00_先读_学习路线与结论.md；四项待办（召唤位置/推荐入口/文字遮挡/余8AE）尚未实现，177–184仍候选。


## 2026-10-21 完整任务接续与已验证提效经验
[完整巫医待办](../巫医完整遗留开发与验收清单_20261021.md)；[已验证提效与反例](../beascendskills/port-coa-playerbot-class-ai/references/wd185-wd186-efficiency.md)。继续复用现有职业AI与UI Skill/Tutor；候选与已验收分开。


## 2026-10-22 WD177–WD204C / TG17–TG22 累计用户基本验收，逐批发布处理中
用户原话：“嗯嗯 前面的这几个包我测试 我觉得可以通过 并帮我一个一个进行推送远端”。按本对话最终交付WD204C累计包登记基本实测通过；用户未逐项报告每个治疗、全等级、PvP、精确DPS或完整生命周期矩阵，相关专项仍待，不扩大验收。WD204A/B是被C撤回的审查记录，自动幻象不纳入。
本轮从正式e7a6d90dd6a59fb83affbf8f02c0349e8bea5e4d/PB25a6feab74edf2e647f7ce44d062008176e37e77逐包重放29阶段；185弹药/186首次引导已有正式提交，185本轮仅补原累计日志标记，不重复发布旧标签。保留原WD165/166未验收根文件差异，最终仅该差异与测试包不同，其他源码匹配最终C（忽略CRLF）。原冻结包和candidate metadata不改写。
证据目录：D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261022/release_WD177_WD204C；最终提交/tag/附件以publication.json实际读回为准。仍不接入NPCBot，不生成游戏EXE、不部署、不执行生产SQL。
复用方法：累计包按相邻输入输出逐项重放，新增纳入既有文件查原backup，不把新纳入当全新文件覆盖；公共根文件三方合并保留未验收排除。战刃按原生自身锥形半径适配，不能把RangeEntry自身0码当攻击距离。蛙变免疫/短读条完成前取消、召唤来源和游戏专项边界沿原记录。
今晚目标是继续C09假死/化蛇/幻象停止与恢复闭环并交最终待测包，非承诺未经游戏验证即三系全部结束；明日先N00审计再安排NPCBot接入。其他G/T/S/N/R与固定副本矩阵继续保留。


## 2026-10-22 WD177–WD204C逐批正式发布完成
用户原话：“嗯嗯 前面的这几个包我测试 我觉得可以通过 并帮我一个一个进行推送远端”。按本对话最终WD204C累计范围登记基本实测通过，不扩大全等级/PvP/全部技能数值、精确DPS、三系固定副本和全部生命周期专项；旧候选历史与metadata不改写。204A/B撤回审查策略不发布，自动幻象仍待。
主仓最终48be5b0a8894227d0b51a770f7e867b8d82575b4；Playerbots最终d915f9dae06a6c4fb1e75a9c077e91a05e00f5e8。29主仓分项提交、22PB提交、29附注tag/非草稿Release已逐项正常推送并读回，未强推。185原弹药/186原引导发布保留，本轮185只有累计日志标记补归档。各阶段SHA/tag/URL见D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261022/release_WD177_WD204C/publication.json。
最终Release：https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-wd204c-20261022
附件reborn-wd204c-20261022-resources.zip，14467554字节，SHA256 d876d29d23c83500f5e290de2a10b5df5a0fa51f67e2f21f6d992480acf8511c；远端uploaded/大小/digest一致。48源码覆盖文件+完整客户端，原WD196B World绑定继承；无新增Data/DBC/MPQ/配置、Characters/Auth迁移。已装204C测试通过无需重装；生产SQL/编译/部署仍用户自行负责。
每阶段及最终Git实际存储文件与白名单输出逐项读回。最终相对原204C只有原正式保留的WD165/166根文件排除，该差异与176正式排除逐块相同。5个最终有效CPP（含导师Trainer）语法检查通过；538AI及各旧脚本/Lua矩阵标为继承证据，不假称本轮全部重跑。没有生成游戏EXE、部署、生产SQL或launcher上传，日常/运行/Claude文件未改。原28无关mode及pycache保留、暂存净。
失败复盘：白名单复制保留mtime、文件大小相同的纯阶段日志变更可被Git stat cache漏检；提交检查立即拒绝，未推送有遗漏内容。改为复制后os.utime并逐提交读取Git blob比对；29阶段全部读回通过后再推送。不是删断言或整树git add。既有文件新纳入累计包时必须查原backup并三方合并，不能按新增文件直接覆盖。
下一步：C09假死/化蛇/幻象的自动使用、停止攻击/移动、到期/撤销恢复；当前三个自动逃生闭环尚未完成。本轮只发布已验收内容，没有新增开发包。今晚最终待测汇总为目标，不承诺未经实机确认即全部结束；明日可先N00审计，不把NPCBot算已接入。G/T/S/N/R完整清单及未测矩阵继续保留。

2026-10-22 [TG23A双语基本验收](stabilize-spelldraft-client-ui/references/tg23a-bilingual-acceptance.md)；TG23B入口候选待测，PB205防御与NPCBot不继承。

2026-10-23 [WDN1A候选](plan-coa-class-migration/references/wdn1a-npcbot-candidate.md)：仅首轮离线通过，完整链接/游戏待测；非已验证职业。

2026-10-23 [WDN1A候选](plan-coa-class-migration/references/wdn1a-npcbot-candidate.md)：仅首轮离线通过，完整链接/游戏待测；非已验证职业。

2026-10-23 [TG23B入口验收](stabilize-spelldraft-client-ui/references/tg23b-toggle-accepted.md)；仅图标二次点击关闭基本通过，NPC/205仍待测。

2026-10-23 TG23B双语/图标与WD206V1大巫毒视觉基本通过并分项发布；详见原Skill与release_TG23B_WD206V1/publication.json，不含NPC候选。

## 2026-10-23 WDN1D1 NPCBot固定菜单双语基本通过并发布
用户：“双语通过 但是 还是不打”。只确认原生主菜单/职责菜单中文与英文同屏；375条固定来源文本不扩大为全部子菜单布局或15格式化动态提示均已测试。以原有en/zh/本批输出匹配后事务更新两表，保留自定义与其他语言，原生启动加载。SQL SHA256 7dd76176d6f2bf1db0633c989eede6e93bb1fb89d9a97306030cf529fd4819a5。
正式提交 6ba57ca1ba5653c4e15ce973b33d748c214420fb，tag reborn-wdn1d1-bilingual-20261023；Release https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-wdn1d1-bilingual-20261023，资源uploaded且digest/大小读回匹配 279c3b6e3296faf43b990daf393237b4782dd784f3bf4153ebdfc78e6d1ca8f5。不含NPC战斗AI；D2先报不打，随后用户确认灵魂战刃已释放，远程职责实际曾未勾选，roles36；Ereer为治疗来源，不得当作NPC自疗验收。自动射击/引怪稳定性D3仍候选，无治疗或坦克体系验收。
发布证据：000Ascendupdate/000Ascendupdate20261023/release_WDN1D1_bilingual/publication.json；原D1/D2冻结包不修改。

2026-10-23 WDN1D3私有NPC自动射击用户基本通过：见audit-and-port-upstream-features同名Skill/Tutor；非完整NPC/引怪验收。C1蛇卫候选不继承。

2026-10-23 WDN1C1 NPC基础蛇卫与持续射击用户基本通过，见audit-and-port-upstream-features Skill/Tutor；高级召唤和治疗未接入。

2026-10-23 WDN1C1已正式发布6483ebaa，见audit-and-port-upstream-features对应Skill/Tutor及release_WDN1C1/publication.json。

## 2026-10-25 WDN2S累计基本验收并发布
用户原话：“这个几个包测试通过 推送 把”。按最后交付WDN2S累计总包登记基本使用通过，不外推全部等级/PvP/长期专项。25个现场源码均与总包相同。
提交c0694d57771f2f76200b8851934bf75ef1021124；tag reborn-wdn2s-20261025。
https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-wdn2s-20261025
原附件SHA256 3560fda16db04c4ac5290e9c219a1018dc8c6b829eaf2950145b9b7015801d43。无新SQL/Data/部署，原包不改；保留隔离工作树无关修改。
复用经验：NPC角色号与玩家职业号分开；原生职责资格和持久化保留，攻击目标查询有开始攻击副作用；关闭输出须在治疗提前返回前清旧射击。单体治疗就绪不等于成功，失败可有界尝试合法群体后备。Aura Load/外部查询用合法owner上下文，不能默认GetTarget可用。
后续计划估计3批功能补齐+1批集中回归，非承诺固定结束时间；UI独立。来源/边界见000Ascendupdate/000Ascendupdate20261025/release_WDN2S/ACCEPTANCE.md。

## 2026-10-25 新增（已验证）
- [build-wotlk-addon-gm-panels](build-wotlk-addon-gm-panels/SKILL.md)：3.3.5 管理面板的菜单点别处关闭、弹窗层级、草稿+保存按钮、缩放不越栏、中英文切换、图标分类的检查表；来源 TREAS2B/2C/TREASFIX1/2，用户 2026-10-25 整体确认通过，Release reborn-treasfix2-20261025。

## 2026-10-25 WDN2Y累计基本验收
用户“这个应该都测试通过 推送并release 吧”。26现场源码与包逐字节匹配；T-Y治疗/配料/节蓝/回响基本通过，专项与后续生存/三系/回归仍待。包SHA256 58e6a75ce1bd8cfc41b295000bd442c8183a4dc468a4e86390d4e5f6d936bf4c；发布证据000Ascendupdate/000Ascendupdate20261025/release_WDN2Y。
方法：NPC治疗来源与主人玩家分开，配料单选与GUID清理，回响取核心实际gain且每NPC记GUID，Reset/死亡/换主地图位面/停用清理；API替身不替代游戏数值矩阵。原包保持冻结。

## 2026-10-25 WDN2Y发布完成
提交a3dd15fee12f8aba75c12a2cc28c1fd7672f7228；https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-wdn2y-20261025。远端分支/tag与非草稿Release附件uploaded、15882633字节及SHA256均核验一致。基本验收范围以release_WDN2Y/ACCEPTANCE.md为准。第二批生存脱险继续，未宣布整职业完成。

## 2026-10-25 WDN3A生存脱险候选
假死/化蛇/幻象独立NPC入口与暂停/恢复；核心假死精确900260+自施9003853并判空玩家接口。1355 AI契约、27回响、33队友药剂、57酿造及3语法通过；游戏待测，不宣称第二批整体验收或最终收尾。包：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261025\codexfix_20261025_092425_阶段WDN3A_NPC巫医生存脱险与前批累计测试包.zip；SHA256 d5a12d7c9c5db202147ed6fff050db2867fde3fe0c4642fdcb4afb912c6441e7。

## 2026-10-25 WDN3B减益与召唤调度候选
实际轮转先减益再非紧急召唤，成功SpellGo启动4秒调度间隔，Jinx有界后备；急救/回蓝/大巫毒不受间隔影响。1387提取契约和AI语法通过；游戏待测。累计3A仍未验收，不宣称三系完工。包：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261025\codexfix_20261025_183751_阶段WDN3B_NPC巫医减益与召唤调度累计测试包.zip；SHA256 ff9fdb3511a3f589257e3abe6d8305afb3c3919f9bf10b384cfd6219f295737b。

## 2026-10-25 WDN3C 脱险与攻击召唤联动候选
自身假死/化蛇/幻象时共用Safe暂停新攻击；攻击雕像暂停及清除待反击，友方治疗不受影响。1411契约和AI/技能模块语法通过，非实机验收；累计A/B待测。既有DOT/弹道不回收，不保证脱战。包：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261025\codexfix_20261025_185053_阶段WDN3C_NPC巫医脱险召唤联动累计测试总包.zip；SHA256 ec145e00aaed8a0bb6c9ec440c2e7440fd2a72d05ea7ab4ca6561d7262c9c133。

## 2026-10-25 WDN3D 实测反例修正版候选
用户确认残血不脱险、治疗连读条、PULL碎步；疑似假死未确认。解除额外队友参战门槛，危急有合法防御才中断读条，施法失败有界后备，持续掉血提前取消自动等待；修复PULL移动接管和非远程普通挥击入口，新增限频诊断。1428提取契约及两单元语法通过，游戏待测。包：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261025\codexfix_20261025_201339_阶段WDN3D_NPC巫医残血自保与PULL修正版累计测试包.zip；SHA256 c4baf0ac5a71631a8df988fe773fb63173f0203b2ff6cca2e1f0a399dd237c49。

## 2026-10-25 WDN3E 近战开怪和受伤应战候选
D纯DPS碎步反例：未勾远程却按箭射程停步；E仅远程停步，近战PULL到接触才施法。参考Hunter/Shaman补受伤和主人受攻击应战，4秒有效伤害辅助自保；普通蛇卫提前于拟态，补全限频日志。1447提取测试/两单元语法通过，游戏待测。幻象只确认出现，完整脱险未通过。包：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261025\codexfix_20261025_214257_阶段WDN3E_NPC巫医近战开怪与受伤应战累计测试包.zip；SHA256 b3ccf4d6ea214aaaccb9281e9734ae54a400d560c50ede21c3b29d592c34f4fd。

## 2026-10-25 WDN3E累计基本验收并发布
用户“这个测试 可以算通过 按照之前的阶段 再往下 一个阶段 开发”。按已交付E范围基本通过，不外推全部防御/三系/稳定性专项。commit 401623357379c341f57cbf3b5c1ce9a27fde1fdc，tag reborn-wdn3e-20261025；Release https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-wdn3e-20261025 。附件uploaded、非draft、15685443字节，SHA256 b3ccf4d6ea214aaaccb9281e9734ae54a400d560c50ede21c3b29d592c34f4fd与原包一致。后续WDN4A不在发布中。

## 2026-10-25 WDN4A 集中回归首轮候选
已验收E之上补AI相位/地图/换主清理，清理先于防御等待；取消DPS后停止已知攻击读条，保留治疗与防御；不重置原生冷却。1456提取测试及AI语法通过，实际换图/重登/稳定性待测，非最终完工包。包：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261025\codexfix_20261025_221923_阶段WDN4A_NPC巫医职责与地图相位回归累计测试包.zip；SHA256 612c440ee63d172bd8774ddc1aa66f89d6d3df1b4d84b8ceccc0b458f86ee85f。

## 2026-10-25 WDN4A 用户基本验收
用户原话：这个测试 可以算通过 按照之前的阶段 再往下 一个阶段 开发。对应WDN4A职责与地图相位回归累计包，SHA256 612c440ee63d172bd8774ddc1aa66f89d6d3df1b4d84b8ceccc0b458f86ee85f。登记基本通过，不扩大所有重登/实例/长期稳定性专项。发布状态以release_WDN4A证据为准。

## 2026-10-25 WDN4A发布完成
基本验收提交efdd0178caae352342e71b81aaa3d256e9044f73，tag reborn-wdn4a-20261025；https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-wdn4a-20261025。附件uploaded、非draft，SHA256 612c440ee63d172bd8774ddc1aa66f89d6d3df1b4d84b8ceccc0b458f86ee85f，远端分支/tag读回一致。后续4B不在发布范围。

## 2026-10-25 WDN4B 副本实例与复活调度回归候选
已验收A上补同地图不同实例清理，死亡/Reset/环境切换统一清理本地重试与保蓝状态，不动原生技能冷却和技能开关。1485项实际提取测试与AI语法通过；实际复活、换实例和长期稳定性待测。源码累计28份，仅AI变化；无新SQL/Data。包：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261025\codexfix_20261025_223553_阶段WDN4B_NPC巫医副本实例与复活恢复回归累计测试包.zip；SHA256 d48a89e7cf7b8cbcb10f9636a63bcf7c8d0cedd47d0dcd5b28c814d6c0e54b9b。教学见包内tutor.md。

## 2026-10-25 WDN4B 副本实例与复活调度回归候选
已验收A上补同地图不同实例清理，死亡/Reset/环境切换统一清理本地重试与保蓝状态，不动原生技能冷却和技能开关。1485项实际提取测试与AI语法通过；实际复活、换实例和长期稳定性待测。源码累计28份，仅AI变化；无新SQL/Data。包：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261025\codexfix_20261025_223720_阶段WDN4B_NPC巫医副本实例与复活恢复回归累计测试包.zip；SHA256 179d08cf16657fdac8fef3622096df89c91467846b80301dd83541aeef94b781。教学见包内tutor.md。

## 交付前现场版本核对补充
用户声明WDN4A测试通过已记录；但日常源码28项仅27项与A一致，唯一AI文件仍为WDN3E（SHA256 7236a3cbd91d2c94ed54e62b7b1eaf1c16451213dce3e377b132b280309fa167）。因此不能从该目录证明测试中的程序包含A；实际运行程序版本未独立核验。本B累计包含A+B，覆盖01后重新编译，在日志核对[WDN4B]，一起复测职责切换、地图/实例、复活恢复。A的用户反馈与文件核验是不同证据；A不能列作现场哈希闭环验证。

## 2026-10-25 WDN4B 副本实例与复活调度回归候选
已验收A上补同地图不同实例清理，死亡/Reset/环境切换统一清理本地重试与保蓝状态，不动原生技能冷却和技能开关。1485项实际提取测试与AI语法通过；实际复活、换实例和长期稳定性待测。源码累计28份，仅AI变化；无新SQL/Data。包：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261025\codexfix_20261025_223840_阶段WDN4B_NPC巫医副本实例与复活恢复回归累计测试包.zip；SHA256 3a60841beff02b38e5120ad1db2fb9070c9b4f4366e0d30ac5066d91140a2205。教学见包内tutor.md。

## 2026-10-25 WDN4B用户通过反馈／版本待确认
用户原话：这个测试 可以算通过 按照之前的阶段 再往下 一个阶段 开发。反馈对应B累计包3a60841beff02b38e5120ad1db2fb9070c9b4f4366e0d30ac5066d91140a2205；登记日常源码仍为E，已询问是否另有编译测试目录。在版本确认前不发布B为已核实版本。继续独立WDN4C技能管理完整性回归，不修改已交付包。

## 2026-10-25 WDN4C 技能管理完整性候选
普通蛇卫9003160补入伤害类技能开关；当前80级AI初始化32条均且仅出现在一张菜单，伤害12/治疗5/支援15。这是已接入条目完整性，不是全三系完成。1557实际提取测试及AI语法通过；B用户通过反馈保留但现场仍E，版本待确认，未发布B/C。包：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261025\codexfix_20261025_225149_阶段WDN4C_NPC巫医技能管理开关完整性回归累计测试包.zip；SHA256 1f24f28a84a736360de2e42ef9527685fc27d9dff5394dedc55fb9d176152264。

## 2026-10-25 WDN4C通过反馈与WDN4D集中收尾
用户反馈C测试可以通过，继续下一阶段。现场登记AI仍E，之前测试目录/版本问题待回复；记录反馈，不冒称运行版本闭环。D按原第四批做最终回归整合，无缺陷不改产品代码，不无限拆批。C包1f24f28a84a736360de2e42ef9527685fc27d9dff5394dedc55fb9d176152264。

## 2026-10-25 WDN4D 集中回归收尾整合
产品28源码与C完全一致，0项代码改动；5877实际提取/API替身检查及8编译单元语法通过。新增1–80级11rank族矩阵、各等级菜单入口对账。附FINAL_TESTS.md；不以离线通过代替运行版本/长期稳定性。C用户通过反馈保留，日常AI仍E，B/C/D发布待版本核实。包：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261025\codexfix_20261025_225856_阶段WDN4D_NPC巫医第四批集中回归收尾整合总包累计测试包.zip；SHA256 d37b883f9ccb7e9ef6497427667b5a793b556e481460b3c837a7f1aa83f2ae3c。已运行C无需再次覆盖编译，无新SQL/Data。

## 2026-10-26 WDN5A NPC巫医副本治疗候选（未实机验收）
交接确认运行C；日常28/28等于D，撤销此前版本不明判断但不因此发布B/C/D。修复零法力上限早退、60码选人28码接近、危急友方/坦克分诊、治疗与主人跟随站位竞争，危险目标暂停DPS。30累计源码，3旧文件修改+1新头；5895方法/API替身+4实际法力方法测试、8/Zs通过，真实波次未测。无新SQL/Data，用户只覆盖01编译。没有修改PB/Cgc/清本/遥测。包：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261026\codexfix_20261026_022151_阶段WDN5A_NPC巫医坦克优先治疗与追赶修复累计测试包.zip；SHA256 8bce01d1b731ab5d565a08be27bb45330d46a1320277ce2f7dd1ce43546ef373。本条为候选与反例记录，不晋升成功能力。

## 2026-10-26 WDN5B 最终NPCBot治疗日志（候选，游戏未运行）
按用户指定修订，仅Unit.cpp::HealBySpell诊断与配置模板追加；SetEffectiveHeal之后记录本体实际治疗/过量/吸收，DealHeal前HP快照，默认关闭。不改AI/jsonl/遥测CPP，不用thread_local配对。21提取方法检查与200并发记录、Unit.cpp/Zs通过；完整链接、游戏、热重载未运行。来源包：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261026\codexfix_20261026_065526_阶段WDN5B_NPCBot最终治疗日志覆盖测试包.zip；SHA256 106293d22cf8b20c7da127a95cbf502d4a20b79682dff69d244f6f5f55f6ae71。

- 2026-10-26 WDN5F复活诊断/清本联动候选，见port-coa-playerbot-class-ai；游戏未运行，包SHA256 44cf52f19c62f34332e858e9bd9263dffaa7903d41226bd0368b35f58e2a0b9e。

- WDN5G巫祝六入口与F联动累计候选；详port-coa-playerbot-class-ai，游戏未运行。包SHA256 71c897898eb0aadf58a33fdbb8fdb09c740d48f8118c57e3a38f2adf9b542a8b。

- 2026-10-26 WDN5H：port-coa-playerbot-class-ai补Jinx按真实资源/移动选择及原生吸蓝审查反例；候选游戏未运行，不晋升成功能力。


### TG24A 经典猎人接入候选，2026-10-26
当前服务端TalentID1361映射Spell80028独狼，不能按原版强击光环命名或直接导入宠物依赖配点。用稳定TalentID匹配原生页序/节点序；每点等待真实确认，超时停止不重发；收藏编辑/分享职业白名单与跨引擎互斥要一起接入。空筛选不能残留旧推荐应用按钮。2131条真实Lua+模拟API及旧UI回归通过，游戏未运行，不算成功经验。证据：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261026\codexfix_20261026_102233_阶段TG24A_猎人三系天赋中心与收藏累计客户端测试包\CHECKLIST_来源与验证.md

## 2026-10-26 TG24B 候选经验（未实机验收）
潜行者用本服83节点稳定TalentID/SpellID，不套原版rank或名称：2071实际为900033毁灭之刃，强化伏击上限2。方案逐级核对严格低层点数及依赖；猎人与潜行者加点任务必须互斥，失去确认时停止不重发。2171/2137实际Lua＋模拟API及31268数据断言通过，真实游戏/完整链接未运行。累计包按F→G→H逐段核对并留来源哈希；私有include需按工程公共include目录解析，不能只查相对路径。来源及安装边界见updateMemory本日TG24B+WDN5H条目；本记录不替代用户验收。

## 2026-10-26 TG25A：CoA风格职业大面板复用流程（候选）
已有TG10A战士/圣骑士三卡首页与独立树用户基本验收，不是没有历史设计Skill；入口/结构沿用该实现。TG25A接牧师并补猎人/潜行者美术，尚未游戏验收。具体流程见 references/coa-class-panel-art.md；教程见同名Tutor的TG25A记录。各职业风格矩阵、image_gen提示词与源PNG、144mip解码证据保存在TG25A包。生成图与浏览器预览不能替代实际客户端验收。


## 2026-10-27 MBWD2C/2D 实机基本确认
用户确认服务端启动崩溃与已报Lua错误已修复、巫医Playerbot天赋大面板能打开。原生 ChatCommandBuilder 的嵌套表持 reference_wrapper，子表必须用具名静态表，禁止用语句结束即析构的临时vector。旧版 UIPanelScrollFrameTemplate 需要父框名称查找 ScrollBar，不能用匿名框。模板初始化和原模板滚轮必须进入测试，而非只做空CreateFrame替身。
独立机器人GUID/nonce状态模型与本人天赋模型分离；策略图标只在服务器回读后亮起。颜色转义文本不能当超链接；UnitLevel前检查合法unit。这里只确认启动/报错/打开，不认定全部加点付费交易、所有底层滚动或技能专项通过。
来源：000Ascendupdate/000Ascendupdate20261027/release_MBWD2D/publication.json；最终提交 edb32897c572511faf9926554e403bc87904cf3c，标签 reborn-mbwd2d-20261027。累计资源SHA256 c1028abcb57e3a1b789f4c5bb0e315f0901e5c629b8f309e811b9f205ceb0ee7。已安装测试通过无需重复导入。


## 2026-10-28 MBWD3A–4C、MBTG1A/B 用户基本验收与本地提交
用户原话：“把昨天的这几个修复进行推送吧 测试通过了”。按本聊天近期8批记录总体基本使用通过，不外推全部职业、每币种异常交易、PvP和故障恢复专项。独立机器人模型/GUID/nonce、真实状态回读、草稿/保存/激活分离、报价单次消费和持久权益是本次复用方法；字体文案用当前语言的短句，不在窄确认窗堆叠双语。
正式基线上逐批提交，排除WD205未单独验收候选；没有照搬日常整份脏Context。原候选包保留原记录，最终发布资源与提交另列来源。3个实际CPP语法与87 Lua解析通过，正式适配后游戏重测未运行。仅基本验收，不认定所有底层交易细项已验证。
本地主仓3c22a6bebe69388bf57daa4d4118e80dfdb88a63，PB e85232a489d0f54efccc96a8ec33b063e0a4794b。自动审批因外发目的地未在本轮用户内容明确而拒绝push，已请求确认；当前未推送/未发布，后续以release_MB20261028/publication.json读回结果为准。
证据：000Ascendupdate/000Ascendupdate20261028/release_MB20261028。


## 2026-10-28 MBWD3A–4C / MBTG1A–B 发布完成
用户总体基本测试通过，并明确确认两个wowshub仓库及发布目的地；自动审批外发阻塞随后解除。8批逐项提交：主仓8个功能提交+验收清单提交，PB4个配套提交；发布期间远端先由Claude新增4个已发布提交，文件无重叠，正常合并保留，没有代交其候选。最后主仓9d060884c9c270a6733e977f8cbc80722270ad6f，PB e85232a489d0f54efccc96a8ec33b063e0a4794b；两个分支和最终附注标签reborn-mbtg1b-20261028-final读回一致。旧功能tag保留未移动。
Release：https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-mbtg1b-20261028-final
非草稿，源码/客户端与SQL两附件uploaded，大小与SHA256均核验一致。资源ce29aff03df9b5e714b2a476841a5b0018eb7932768d6d9f76142d0bbad3f269；SQL ea853fbf6efd9c57a724793add7107fe5d7ba4fd1268eccf183bc1721fed619e。
附件仅Codex管理的MBWD/MBTG范围，无Claude清本/LootLab/宝箱功能文件；既有正式共同祖先保留。排除WD205候选，三个真实CPP语法和87 Lua解析通过；正式适配后游戏引擎重测未运行，基本验收不外推全币种/所有职业/异常矩阵。用户自行编译部署，未执行生产SQL/上传launcher。已经安装且通过无需重装/重导。
证据：000Ascendupdate/000Ascendupdate20261028/release_MB20261028/publication.json。冻结释放发布写锁。


## 2026-10-29 UIR1B 圆形种族预览入口
蛇人/双头食人魔顶部图标、原生圆环与对称位置获用户截图确认。复用 [stabilize-spelldraft-client-ui](stabilize-spelldraft-client-ui/SKILL.md) 的头像/外环分层检查；模型黑影、正式创建未解决。详当日 codexdoc_UIR1B 逐行教学与 release_UIR1B 发布证据。


## 2026-10-29 UIR1B 已提交、推送并发布
提交 2af15d3e0ee52a1d0865b8d9efe3e51316501787；分支 wowshub/threemodelcardpro，标签 reborn-uir1b-20261029 解引用一致。
[Release](https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-uir1b-20261029) 非草稿，目标 threemodelcardpro，两个附件 uploaded，大小和 SHA256 读回全部一致。
仅蛇人/双头食人魔顶栏圆图、阵营环、蛇人选中与对称布局基本确认；模型黑影待修，正式创建未开放。4/4现场文件匹配冻结B；没有部署、编译、SQL或launcher改动。23文件白名单提交，既有无关工作树修改未暂存。
发布证据：000Ascendupdate/000Ascendupdate20261029/release_UIR1B/publication.json。MD及新旧完整文件在当日 codexdoc_UIR1B_蛇人与食人魔图标逐行教学，Release附教学ZIP。
资源SHA256 33360450d7006b0dacfd701cfa1d48ad524b374e4dcaeeff2707e57ced30d7a4；教学SHA256 8d7fedbff22a350f29f8cfc317897719712320c9a8df13c2712aa8362e5693ef。


## 2026-10-29 新职业武器学习强制检查
已在[integrate-wotlk-custom-class-ui-eligibility](integrate-wotlk-custom-class-ui-eligibility/SKILL.md)及其[武器矩阵](integrate-wotlk-custom-class-ui-eligibility/references/weapon-training-preflight.md)补充双端资格、NPC训练/价格/等级、具体装备和双持边界。巫医剑斧锤长柄/拳套数据候选已出包；不标实机成功。


## 2026-10-29 WDWP1B 用户基本验收
用户原话：“测试拳套和这些武器都可以npc学习了 帮我推送 这个包”。确认巫医拳套、单手/双手剑斧锤、长柄的NPC学习基本通过；未外推逐NPC、资金不足、全部等级边界、每件装备、双持、攻击动画或重登专项。
此前截图缺失项目时，客户端只装了拳套A、登记服务端仍旧表；永久反例：双端包必须覆盖实际服务端Data并重启，不以MPQ安装代替服务端生效。
冻结包SHA256 9093e7cb2c03659c5429efbc65846095744f707cc4dedbcb22e8a82bdce233b7。保留原候选说明，后续验收以本记录为准。


## 2026-10-29 WDWP1B 已发布
用户确认拳套及剑斧锤长柄NPC学习通过。提交 6ccdabf0e664099fe6dc8462984e10e8e5931b10；wowshub/threemodelcardpro与reborn-wdwp1b-20261029标签目标读回一致。Release https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-wdwp1b-20261029；附件uploaded、大小与SHA256 9093e7cb2c03659c5429efbc65846095744f707cc4dedbcb22e8a82bdce233b7核验一致。4/4现场安装文件匹配冻结包，12文件白名单提交；仅本包，不含UIR1C/D。未部署/生产SQL/launcher。已安装测试通过无需重装；不外推装备/双持/完整重登矩阵。证据：000Ascendupdate/000Ascendupdate20261029/release_WDWP1B/publication.json。


## 2026-10-29 UIR1D 悬停分色用户基本验收
用户点名UIR1D包并表示“这个也测试成功”。确认蛇人与双头食人魔悬停白色名称、黄色简介、白色分条属性基本通过。发布前1/1安装Lua匹配冻结包；B到D包含C的十条属性文字，不能只摘分色函数漏掉文字依赖。
复用现有XML OnEnter/OnLeave与Tooltip高度计算；局部字符串色码分段开关，不改全局字体；身份键与显示名分开。模型黑影、属性机制、正式创建及所有分辨率矩阵不继承通过。


## 2026-10-29 UIR1D 已提交推送发布
提交 ea2ec8a749909c61d61b51b1095fe22516ca4a3b；wowshub/threemodelcardpro和reborn-uir1d-20261029读回一致。Release https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-uir1d-20261029，两个附件uploaded，大小/SHA256均核验。用户确认白标题/黄简介/白属性基本通过，1/1现场Lua匹配。教学MD及B/C/D原件见当日codexdoc_UIR1D_种族悬停分色教学。仅介绍分色，不扩大为模型/机制/正式创建通过；未部署。证据release_UIR1D/publication.json。


## 2026-10-31 WHUI1A猎巫者图标基本显示通过；方法并入integrate-wotlk-custom-class-ui-eligibility，未开放创建。

## 2026-11-05 新种族首次进世界与猎巫十通用节点经验

- [新种族创建到首登流程](../beascendskills/port-wotlk-custom-race-creation-flow/SKILL.md)：身份/枚举/32位掩码、创建与选人场景分开、出生数据诊断；随机名和选人页背景用户已通过，战士切换及自动穿装仍待修/测。教学：[TUTOR](../beascendtutor/port-wotlk-custom-race-creation-flow/TUTOR.md)。
- 猎巫十通用节点（12AE）用户基本测试通过；加点/冷却/暴击联动基本反馈已写入trace-and-port-coa-spell-resources Skill及Tutor；四专精仍只浏览，不能扩大验收。本次记录没有新发布结论。

2026-11-05更正：RACEUI1B被用户否定（自绘Open漏刷新、误Show列表长框），不能标成功。RACEUI1C两脚本已接实际Open、去长框与独立职业禁用外观；13组/1500真实Open路径替身检查，游戏待测。详同名Skill案例。


## 2026-11-05 RACEUI1C 用户基本验收

最终C的实际自绘Open职业刷新、两新族仅战士/其它灰、旧种族往返与去长框用户确认正常。已更新port-wotlk-custom-race-creation-flow及restrict-wotlk-custom-class-creation Skill与Tutor；A/B失败历史保留，C最新通过覆盖此前“待测”的当前状态。不扩大为全种族/种族被动/自动穿装专项通过。

## 2026-11-05 已分项推送与发布（源码组件归档）

本轮16个分项commit已推送wowshub/threemodelcardpro，最终136d08aac84ff41058541f6b3150266cbc8369e5；tag reborn-accepted-fixes-20261105；Release https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-accepted-fixes-20261105。远端附件uploaded、454039字节，SHA256 87ac6c3e9a0e7437fa2e2f8e554f5751bec7df82e46116eaf7ec5063659edefd已与本地一致核验。

C职业切换/灰色规则/去长框、A名字与选角背景及猎巫十通用节点基本验收分别记录。Git保存可复核源码组件、差异和依赖；天赋C++为WHTALENT/source_snapshot，完整class15/新种族前置未整体入主模块，不能把自动源码ZIP当独立完整部署包。四专精、全种族被动/自动穿装专项不扩大验收。根项目发布证据：000Ascendupdate/000Ascendupdate20261105/release_ACCEPTED_20261105/publication.json。

## 2026-11-06 NEUTRAL1 中立栏与新种族外观

- [CoA 种族外观选项](../beascendskills/port-coa-race-appearance-wxl/SKILL.md)：wxl 追加表导入 CoA 种族；性别值 2/3、运行库映射与上限、直贴槽与皮肤合成的选择、覆盖层烘焙、数据空洞崩溃、背景选表。用户 2026-11-06 实测通过，仅限创建页预览，未覆盖进入世界。

## 预收藏参考（外部方法，**未经本项目实测**，不属于"已验证 Skills"）

这一区收录用户要求预先收藏的外部项目方法。按收录规则第 1 条，它们**不得写成成功经验**；没有同名 Tutor。某一项经用户实测通过后，再把那一项提炼进对应的已验证 Skill 并补 Tutor。

| Skill | 内容 | 状态 |
|---|---|---|
| [reference-retail-race-and-asset-import-methods](reference-retail-race-and-asset-import-methods/SKILL.md) | EsteriaWoW、Aetheria、Medviten 的 WHE-256-bit、wowdecomp、mod-playerhousing 里的：种族 ID 超过 31 与掩码的三种做法、种族生产十阶段流程、正式服风格捏脸、从正式服 CASC 取模型与坐骑导入、家园系统三种做法、验收与证据规则、来源与许可证 | 2026-11-07 预收藏；只读了 README 和 docs 文档，没读源码；没有实测；技能内列出了"对我们的检查项"和"未读清单" |

## 2026-11-07 39/49战士建角与出生流程

[port-wotlk-custom-race-creation-flow](../beascendskills/port-wotlk-custom-race-creation-flow/SKILL.md)已补39/49有限验收与前置技能顺序、共享位隔离/双端表、冻结SQL核验经验；[逐步教学](../000Ascendupdate/000Ascendupdate20261107/总结教学_20261107_新种族联合移植与天赋修复/00_从这里开始.md)。用户基本首测通过，专属种族特性和全矩阵仍待做；不把TGFIX全部经典职业专项或猎巫四专精写成完成。

## 2026-11-08 新种族猎人武器检查补充

port-wotlk-custom-race-creation-flow已补弓45/264、枪46/266、弩226/5011、自动射击75的出生前授予、旧角色补缺、弹药匹配及实际装备/射击矩阵。RACECLASS1C仍候选待实机，源于用户报告物品23347无法使用，不将旧职业验收继承到新种族。

### 2026-11-08 RACECOMBO1A候选与局部反馈
四族创建流程Skill补局部反馈边界；stabilize-spelldraft-client-ui补首登模式介绍丢失反例及握手/完成回执候选。不是已验证新配方。库尔女幽灵狼及兽人术士仅按用户实际范围登记；新图腾/蛇人/首登控制仍待测，详当日RACECOMBO1A交接。


## 2026-11-08 RACECOMBO1B候选与失败登记
port-coa-race-appearance-wxl已同步蛇人脸部/幽灵狼恢复基本改善、关闭平面装备合成限制；audit-and-port-upstream-features已同步16图腾透明度轨道生成器与校验同错的失败教训；创建流程Skill/Tutor已同步首选模式介绍转场分支。1B全部实际游戏待测，非成功验收。教学见当日RACECOMBO1B包01_小白教学.md。

## 2026-11-08 RACECOMBO1B 最新状态
用户明确大地之力图腾、抗火图腾、岗哨图腾均点击崩溃；其它未测，停止反复测试。16旧M2的0x58透明度数组被错误生成成2字节ushort，真实客户端要求20字节M2TrackHeader；旧验证复用同错因此漏检。现16个独立副本改完整固定不透明轨道+lookup0，保留其它原字节并追加；按本地M2Format/M2WalkLayout自动提取的独立检查拒绝16旧件、通过16新件。配套32skin/BLP现场匹配并累计交付。错误原件单列勿回退；另给原样1A精确回退SQL应急ZIP，正常安装不执行，助手未执行生产SQL。结构修复不等于游戏防崩已证实。
77项候选：4模式Lua、20选角路由/场景、男蛇M2+4skin、48图腾资源；无新DBC/C++/DLL/正常SQL。男臂装饰取舍一款常驻，女挂点未改，40543头盔/持盾/背盾实际位置待测。脸部+幽灵狼恢复用户基本通过，1A首选介绍与新图腾失败，不把整个A标成功。全部1B实际游戏待测，未提交发布。



## 2026-11-08 RACECOMBO1C候选
外观Skill/Tutor已同步B选角帽/持盾和无绿罩基本通过、游戏背盾仍失败的限定范围；资源审计同步B图腾持续卡死及C完整CoA成品模型替换/尾mip核验；模式UI及创建流程同步C本地准备页+可见回执恢复。C全部游戏项待测，不把离线夹具、成品来源或高清标签当验收。教学见当日C包01_小白教学.md，工作目录codexwork_RACECOMBO1C。



## 2026-11-08 RACECOMBO1D：蛇人图腾基本通过，背盾对话放大修正候选
用户C蛇人图腾“不崩溃了 太帅了”，只记蛇人本次基本使用；另三族/全技能/PvP与模式介绍本轮未反馈。C背盾对NPC说话时巨大、结束恢复，失败。原因证据：C helper158使用global=-1的83主M2关键帧，Talk54/ID60 flags0x281无0x20，客户端按外部.anim基址解释；范围检查不能替代动画取文件检查。D仅helper158改为全局恒定T0/R原Z90/S1（复用已有global0），保留其它原字节/原骨/挂点/图腾97项；83路径与矩阵检查通过，游戏对话待测。不得清所有外部动画标志强塞M2，不要把外部槽强解主文件得出的垃圾数认作原骨损坏。原全局表历史布局保留，未全面修。工作codexwork_RACECOMBO1D，交付仍候选，原C包不改。



## 2026-11-08 RACECOMBO1E/F累计候选：C模式倒退确认
用户新库尔女Beatrix三模式首登也丢失，要多次小退才到介绍；双头食人魔能选经典但介绍仍丢。C真实缓存CRC3362226416且完整minified夹具通过，不是旧缓存/未装，必须把C模式记失败。E改普通RebornModeGate插件预载（RequiredDeps AIO_Client），动态脚本仅装载小桩，不改AIO库；本地禁用等待页、可见选择ACK、低频持续恢复、权威完成状态、迟到pending保护。45s延迟/完整按钮链离线通过，真实首登仍待测，不能据此声称修好。角色新SavedVariables诊断与/rebornmode可查状态，不强解锁/清模式记录。
用户库尔女40543光头：39 ClientPrefix仍Hu，而现成KT女盔范围更符合头部；F只39字段6改KT，927基础型号男女资源及skin现存，29个缺KT但有Hu的变体复制兼容，其余49原Hu也未找到列缺口，不宣称全头盔覆盖。四族玩家Wardrobe预览从每帧seek15/0改一次站立，保留旧族/武器预览；180帧/异步加载夹具通过，实际闪烁仍待测。D背盾固定轨道原输出累计，只有男helper变动。
C蛇人图腾基本不崩且外观满意保留，库尔游戏动态图与旧静态图不同因为未套待机骨变换/粒子；静态网格不能代替成品游戏形态。97图腾资源本包不改。Claude HOUSE20261108已发布，SETHRAK-ARMOR新路径UV试验独占，本包不带其内容。



## 2026-11-08 RACECOMBO1G：Claude男女v8基线与背盾合并候选
用户确认Claude男女v8装备层已通过，指定Codex从现场v8模型起步。现场男性1d60976f096f81e3cd3af6819789ad64f00b9e641bbe2e9803843f87bfa4893d及70项Claude资源核对一致；G只改男性helper158固定全局TRS，60字节旧轨道头+末尾追加，所有贴图/查找/替换/顶点UV2和其它原字节不变。guard OVERLAY INTACT，UV2差异0、其它顶点差异0，损坏反例被拒绝；83动作取址/矩阵离线通过。累计E其它66项输出不变并重新核对当前客户端/服务端/源码；新整合的坐下起身+NPC对话/盾牌位置、模式、头盔、预览游戏待测，不继承v8验收。旧C/D/E男性M2不得再覆盖。没有男女skin/底图/女性资源、图腾/SQL/DLL/C++改动，不部署不发布。

交接：D:\000rebornWOW\000RebornWOWHighForkPRO\交接_Codex给Claude_RACECOMBO1G_v8叠加层完整与背盾累计候选_20261108.md

## 2026-11-08 RACECOMBO1H：G模式首登实测失败，世界事件回放候选
用户库尔女首次仍无三模式、小退后出现，截图确认Peggy；当前插件和双端源码/运行Lua为G/E输出。旧诊断只证明收到选择页后可见回执较晚，不足唯一根因。新增反例复现E在PEW前UI暂可见就发送PickerVisible；H普通插件2文件改为PEW且UI可见后回放权威页面，防旧pending覆盖介绍、完成老角色清待回放；等待页不破坏权威卡片。45s隐藏/先world后UI/旧E提前ACK反例及新H无提前ACK/选择完成夹具通过，原生WoW/AIO网络仍待测。协议Build E兼容已装服务端桩，UIBuild与TOC H；只冷启客户端，不编译/SQL/服务器改动；不碰G男蛇/Claude70项/DBC/图腾。H失败时取/rebornmode world/ui/modal等现场，不重复怪缓存或要求连续小退。
交接：D:\000rebornWOW\000RebornWOWHighForkPRO\交接_Codex_RACECOMBO1H_G首登失败与世界就绪回放候选_20261108.md

## 2026-11-08 RACETOTEMK1A：库尔德莱尼借用未通过，海潮祭柱候选
用户认可蛇人/双头/玛格汉三族图腾造型；只蛇人先前基本不崩有确认，不扩大另三族全技能稳定性。库尔截图仍是C高清draeneitotem，G/H没换，用户不认可专属性。K改用CoA patch-WC2的8du_seapriest_totem01，10原BLP保留；原场景物件补Unit动画lookup与Stand/Spawn/Death、固定元素乘色，原骨/顶点/UV/倍率不变。18资源仅39私有路径，无DBC/SQL/Lua/DLL，ID61108～61111不变；其它三族24M2/skin现场等于C。完整记录图/mip/内嵌取址及ZIP通过，实际外形尺寸/生命周期/防卡死仍待测；不将静态主体图当成品游戏截图。原源最大512，不说AI新绘制高清纹理或官方库尔原生图腾。
交接：D:\000rebornWOW\000RebornWOWHighForkPRO\交接_Codex_RACETOTEMK1A_库尔德莱尼借用替换海潮祭柱候选_20261108.md

## 2026-11-08 RACECOMBO1I：经典介绍页无坐标，手动锚点恢复已实测
用户库尔男萨满Dalar：H三模式出现，选经典后窗口消失。现场H诊断phase intro，服务器ready已收到；INTRO命令主/子IsVisible=1、子alpha1、1100x700；ROOT命令root alpha1、UIParent alpha1、TOOLTIP，但root与intro的GetLeft/GetBottom均nil。用户执行ClearAllPoints+显式CENTER到UIParent+显式宽高+Show后确认“介绍页立即出现了”。这是定位/临时恢复的实机证据，不等于I完整首登流程通过；是谁使初始锚点失效仍未查明。
I沿用H世界就绪回放，在根窗构建/进入介绍/重新Show/分辨率缩放变化时校正定位；心跳只在坐标失效或视口尺寸变化时补定位，不每帧反复布局；GateReady和介绍可见回执必须坐标已解析。27292顶点/Claude装备层、G背盾、模式DB与解锁协议均不动。2客户端插件文件，冷启动即可，无SQL/编译/服务器覆盖。旧H nil锚点状态夹具可复现；I切页/后续坐标丢失恢复及H生命周期/完整模式流程重新通过，I包冷启动全流程仍待用户测试。
交接：D:\000rebornWOW\000RebornWOWHighForkPRO\交接_Codex_RACECOMBO1I_经典介绍页无坐标与实测锚点恢复_20261108.md

## 2026-11-08 RACETOTEMK1B：海潮祭柱过大与悬高名字候选
用户K1A截图可同时看到四海潮祭柱，但模型过大、名字远高于主体。原场景M2渲染盒Z为-2.47～5.78、半径5.869，主体顶点Z仅-0.073～2.715；双端CreatureModelData仍为A旧水晶元数据，高度1.319。B候选将四私有显示ID61108～61111的CreatureDisplayInfo字段4比例1→0.60，主体约高1.67；ModelData字段14/15与17～22按实际未缩放主体数据校准（比例由DisplayInfo统一乘），各自独立客户端/服务器根/zhCN输入共6DBC，不互相替代整表。4私有M2只改0xA0起28字节渲染边界/半径为主体加余量，避免沿用原场景巨大盒；原顶点、骨、动画、粒子、皮肤贴图和其它字节不变。边界/元数据是高度疑点与修正候选，实际名字位置未测，不称唯一成因已证实。10项离线完整图/55轨道/四行字段白名单/其它行字符串不变通过；14原skin/贴图不重发。渲染视野边缘粒子及新比例/文字高度待测。无SQL/CPP/DLL/其它种族/Claude角色资源/模式改动。
交接：D:\000rebornWOW\000RebornWOWHighForkPRO\交接_Codex_RACETOTEMK1B_库尔祭柱比例与悬高名字候选_20261108.md

## 2026-11-08 HELMKT1A：库尔男40516头盔挂点基准候选
已读Claude头盔只读交接。实际现场39 ClientPrefix为KT（E/G改的是种族通用字段，男女共用），57061的ItemDisplayInfo为Helm_Robe_RaidShaman_C_01.mdx；原生KTM模型/skin在Patch-6，SHA d65fb06adaa8b5cb7aaa997d246e9ccb0f7720744f406ac688be40beb2c867af，并非男性仍用Hu或缺原生变体。锁定Housing/9未读，不能声称扫过全部档案。E的29个兼容变体是原Hu按字节复制，没有额外手调挂点。
当前库尔男模型80e7ae1f66e38b2e586b818d80ee01a2d1b302470250f54b4df34d75f33a133e，挂点11连骨175，pos(0.100,0,2.600470)相对骨pivot(-0.066322,0,2.390470)多出前0.166322/高0.210。候选仅将此挂点pos恢复为现有pivot，保留辅助骨原全局旋转/235动作/所有顶点UV/其它挂点。另原生KTM 40543绑定空间对照：修前盔顶2.8508、修后2.6493、男头顶2.6539；40516相同校正但有角冠造型，不能用角冠最高点判定贴合。此为静态对照，不冒称已观测原生客户端挂点乘法或用户实测。
只有1个YB男性M2，允许12字节坐标范围修改，其余原字节完全不变；负例破坏顶点被验证器拒绝，实际KT前缀/57061已核。无需改头盔变体、skin、DBC、女性、蛇人、SQL/DLL/源码或重启服务器。回归40516及其它KTM、旧兼容Hu副本需实机，不能宣布所有头盔一次验收。
交接：D:\000rebornWOW\000RebornWOWHighForkPRO\交接_Codex给Claude_HELMKT1A_库尔男头盔挂点候选与KT来源更正_20261108.md

## 2026-11-08 RACETOTEMK1C：K1B名字高度失败，补名字附件18候选
用户反馈“头盔测试通过”，另图腾文字仍高。K1B四M2+双端六DBC现场10/10匹配，不是漏装。海潮场景M2的attachments/lookup均0；原生德莱尼图腾有PlayerName18及空默认启用轨道，公开M2实现说明CGUnit GetNamePosition使用18，本地World.hpp也提供虚表slot8名字位置。C仅为4私有M2追加40字节附件18、19项lookup（18→0，其余-1），挂静态bone0，Z=主体顶点最高+.25；0.60比例后锚点约1.779、比主体顶+.15。不再改比例/渲染盒/双端表；旧M2只允许0xF0起16字节附件头变化，其余原字节、skin/BLP/粒子/动画不动。4完整图56轨道、静态root/原生默认启用/lookup负例和ZIP检查通过，实机名字高度待测。K1B边界校准不能当名字问题已解决的成功配方。

## HELMKT1A验收
用户原话“测试通过 头盔测试通过”，并提供Granis截图。已核现场YB男性M2输出6cb910b7f38b2e5769478483879252b312250797e711a48e523a1a99ddc32392，与冻结候选一致，限定本次库尔男性头盔基本验收；全部头盔/动作矩阵未逐项确认。包SHA256 04f593331844111c3a87369f3104cd8ca567e7253735d643e17d5367dd478282。未修改已冻结候选README，而以此新记录更新状态。
发布依赖审计待办：本修复建立在39 ClientPrefix=KT的E/G现场上，而该前缀与29个兼容盔资源尚未独立完成发布依赖闭包；不可把G/I/图腾等未通过候选一并发布。先审对应已测头盔的必需依赖，再按release-tested-reborn-features隔离发布；当前不称已提交/推送/Release。

交接：D:\000rebornWOW\000RebornWOWHighForkPRO\交接_Codex_RACETOTEMK1C_库尔图腾名字附件与头盔验收_20261108.md

## 2026-11-08 HUNTERAMMO1A：普通猎人弹药槽遗漏候选
用户Prudence库尔、Mandiss双头、Gaine玛格汉截图：弓/枪已装备但人物弹药按钮不显示。历史UI76B为13/14、UI_AMMO1A修弩子类、UI10B修三武器槽回弹，WHRESOURCE1A追加15。当前AmmoFix只custom13/14/15或UnitHasRelic才主动更新，普通Hunter3/HUNTER直接return；不是新种族又缺武器熟练度。本候选在现有累计文件加所有种族普通猎人路径，并在原生按钮Update可能隐藏后最终Show，保留武器类型判定、三武器行布局、反隐藏/脱战与缓存刷新。原生库存slot0和OnClick不改、不造弹药、不自动装备/改消耗。42种族/弓枪弩场景及旧失败反例、魔杖/投掷/空位不强显、缓存后到、nativeUpdate隐藏、13/14/15回归、战斗延后离线通过，原生游戏仍待测。仅一个AmmoFix.lua，无服务器/建角底座/SQL/DBC/编译。新增/ammocheck报版本、class、ranged、ammo、should，并请求同一UI队列。新种族验收清单必须同时查远程技能、弹药库存按钮、穿脱/缓存/战斗及实际射击，不只测自动射击。
交接：D:\000rebornWOW\000RebornWOWHighForkPRO\交接_Codex_HUNTERAMMO1A_普通猎人弹药槽与发布隔离_20261108.md


## 2026-11-08 RACERELEASE1B 七项已验收修复分项发布
头盔、首登I、幻化预览、原生Hunter弹药槽、蛇人背盾G、Hunter武器补缺、四族图腾最终K1C各自commit/tag/Release，详见000Ascendupdate/000Ascendupdate20261108/release_RACERELEASE1B_20261108/publication.json。原技术Skill/Tutor已更新验收、失败经验和Hunter弹药槽检查，不把冷启动延迟写成无延迟、不把CLASS1A建角底座写成已发布。当前用户无需重装。


## 2026-11-08 新种族基础回归/遗骨方块（用户要求固化）
ruleAscend已增加必查项；port-wotlk-custom-race-creation-flow的references/new-race-regression-checklist-20261108.md记录Hunter技能+弹药槽、四元素图腾、变身/装备/预览、首登与死亡复活遗骨全链检查。原Skill及同名Tutor、appearance入口已链接。BONES2A为8M2/8skin/4BLP兼容遗骨候选，离线通过，实机待测；不改变十职业建角底座暂不发布的范围。


## 2026-11-08 BONES2A用户基本验收
用户原话“测试通过 可以推送了”。四新族兼容遗骨修复按基本使用通过记录，当前YJ20/20匹配冻结原ZIP；全部男女/四族/观察者/真人与机器人/重复死亡矩阵未逐项确认，不扩写。无活体模型、DBC、服务端、SQL、DLL改动，十职业建角底座不发布。Release：https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-bones2a-20261108；原ZIP SHA256 b3f14f8d75838ab047f4d58eb6124b5539437d26228edd98225301640410ed4c。原包待测文字保留为历史，此新记录更新状态；已装通过无需重装。


## 2026-11-08 RACEBATCH2A：暗落者十职业候选
原port-wotlk-custom-race-creation-flow与port-coa-race-appearance-wxl Skill/同名Tutor补充：M2/SKIN跨MPQ配对索引、BLP3兼容转换、38/40阵营mask区别。候选未验收，证据见当日codexwork_RACEBATCH2A/delivery.json。


## 2026-11-09 RACEBATCH2B：入口和随机名漏项
原新族创建Skill/Tutor已补充可见按钮/真实token/职业资格闭环、预览族随机名独立于建角资格；B为客户端2Lua候选，未实机。证据codexwork_RACEBATCH2B/delivery.json。


## 2026-11-09 RACEPAIR3A：破碎者与失落者双族候选
40联盟破碎者+73部落失落者经典十职业候选；未实机/未发布。已补主表/扩展表资格、真实token与阵营核对、跨阵营位40的零mask身份路径、73持枪110别名回环、Display相对贴图随私有飞行目录迁移、单序列尸骨校验器不套活体未拥有/外置槽、猎人技能/弹药/真实物品校验及候选40组合待测。详细证据见原创建Skill基础回归参考新增本节；Tutor同步。ZIP哈希36bfddfa60542b24478c8e6fc557feef011bea9a91d70ccd5624c624fe48cb2b；旧38取消与四族底座不发布继续遵守。


## 2026-11-09 HUNTERSWAP1A：近战转远程的显示状态候选
新增猎人必须包含“先近战→宠物接怪→拉远→自动射击→回近战/停射”的实际武器切换，不只看出弹和动作。Bows与Rifle（枪/弩）分开，显示状态、真实装备、骨骼动作、BWR/BWP事件、owner/alias与MPQ有效覆盖层分别核对。旧HUNTERSHEATH只强发远程格不能证明主副手预测缓存已清；HUNTERSWAP1A补发仅36/73 Hunter，夹具和两CPP /Zs通过，真实客户端仍待测。RACEPAIR3A失落者M2被YJ同名旧版遮挡的漏项已记录，候选改到现有YJ。详见原创建Skill基础回归参考本节，勿继承旧包静态为实机成功。

## 2026-11-10 HUNTERSWAP1R1：实测失败与撤回模型候选
用户实测A+B失败：73失落者弓动作退步、从左手射弹；36蛇人仍拿近战武器发射枪弹。撤回HUNTERSWAP1A有效性预期，不把此前离线alias/事件/夹具检查作为实机成功。

当前两CPP、两个YJ失落者M2均精确等于失败候选output；实际运行Wow/worldserver路径正确，EXE存在HUNTERSWAP1A编译日志标记。不是“用户没装上”。只读指纹与运行路径见codexwork_HUNTERSWAP1R1/intake.json。

R1只交付两份改动前失落者M2（从冻结A原ZIP备份与解压备份双重逐字节核对）：男a234e3296ad942ee406800f5ee0966a004b6e36f7f55a76928c3b08ad9d6836c，女14195be5894910859cb08bc57844fd10e4aedcd142602c26fcf2dd05a51a10d2；导入现有YJ，同路径覆盖，先退出游戏。没有安装/部署，恢复弓的实际效果仍待测，枪弩不声称修复。保留A供取证，未改源码/蛇人叠加层/skin/BLP/DBC/SQL/DLL/PB。

用户已按临时root5射击再root2执行；当前Server.log等可读取且有正常新日志，但未检出HUNTERSWAP1A行。尚未取得现场sheath/virtual值，不能推断服务端值正确或客户端最终根因。命令返回成功也不证明记录分支运行，cs_server忽略SetLogLevel返回值。下一诊断先验证日志采集及实际命中分支，不重复发Force/alias盲改，不要求用户重证已经失败的现象。

包：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261110\codexfix_20261110_022023_阶段HUNTERSWAP1R1_仅恢复失落者改动前模型.zip
SHA256：bc2d7faece7223c844309f255acdc2a5208c33cf25b7b1c4f4d62559617809e4；8成员，2安装文件。ZIP成员全部读回相等。仅回退包未实机，不提交推送。原冻结包保持原字节。


## 2026-11-10 战场/竞技场退场生命周期检查（流程与失败案例，未修复验收）
[guard-wotlk-battleground-bot-exit-lifecycle](guard-wotlk-battleground-bot-exit-lifecycle/SKILL.md)：地图战场类型不保证owner BG引用存在；HLBGBOTEXIT1A空引用退场崩溃证据、验证矩阵与暂缓迁入原则。

## 2026-11-11 WOW64PORT1B候选与失败回归
理发/外观原Skill及同名Tutor已补64位缺49样式、捐赠方ID20/49/50/51身份冲突；尚未实机验收，不扩大旧x86成功范围。交接：交接_Codex_WOW64PORT1B_Online预览理发与外观身份候选_20261111.md。

- 2026-11-13：[机械侏儒肢体与装备冲突](port-coa-race-appearance-wxl/SKILL.md)：WOW64RACEPORT1E男女穿装缺腿用户基本通过，4/4实装匹配；D空面与E部件组冲突分层；全装备/动作未全验收，顶部错字未修。

- 2026-11-13：[repair-wow64-client-script-music-and-exit-hang](repair-wow64-client-script-music-and-exit-hang/SKILL.md)：64位客户端(STRHercules/Esteria)登录界面/PlayMusic无声（脚本音乐decodeBufferSize传0xFFFFFFFF，改0）与SoundWire虚拟声卡致退出“未响应”（3秒无进展看门狗）；EXIT1E用户实测：登录界面有声音、退出约3秒自动关闭。仅验证一台机器/一种虚拟声卡；Codex并入前不称最终EXE。含抓转储脚本。同名Tutor已建。

- 2026-11-13：[port-hinterland-battleground-with-navmesh-bot-routes](port-hinterland-battleground-with-navmesh-bot-routes/SKILL.md)：辛特兰战场(20411)移植、自建vmaps/mmaps、导航网格陆地路线表与联盟出生点路点；V27联盟出生点用户确认，部落侧路线等.gps，窗口图/M地图/塔碰撞未验收；同名Tutor已建。

- 2026-11-13：[repair-wotlk-addon-editbox-keyboard-capture](repair-wotlk-addon-editbox-keyboard-capture/SKILL.md)：插件输入框刷新时SetFocus抢键盘致W/A/S/D失效的修复(DCGPS1D)；用户实测通过，验收前先核对客户端实际文件；同名Tutor已建。

- 2026-11-13：[repair-wow64-client-minimap-group-blips](repair-wow64-client-minimap-group-blips/SKILL.md)：64位客户端自定义职业队友小地图黄色方块→PartyRaidBlips白色圆点；用户在DragonUI新旧皮肤下均确认；数字1 2 3来源未查清；同名Tutor已建。

- 2026-11-14：[repair-m2-cape-holes-backface-culling](repair-m2-cape-holes-backface-culling/SKILL.md)：自定义种族披风局部缺口=披风三角面朝向反+材质背面剔除，材质渲染标志0→4(KTCAPE1B)；用户实测库尔提拉斯女性修好；含读错文件/blend无效/EsteriaOff无效的排除记录与诊断脚本；蛇人披风不显示、32541崩溃未解决；同名Tutor已建。


### 2026-11-14 原种族外观流程补充
port-coa-race-appearance-wxl补入EsteriaOff诊断开关遗留/静态缓存冷启动/用户全部恢复证据；同名Tutor和当天逐行教学已同步。

- 2026-11-14：[add-cape-geometry-to-custom-race-m2](add-cape-geometry-to-custom-race-m2/SKILL.md)：给没有披风分组/贴图槽的自定义种族M2追加披风网格(蛇人男1C、女1J用户确认)；先从日志确认真实加载文件(女性是SethrakF.m2不是Sethrak.m2)、分段1501-1510、只追加、按行统一权重、对称褶堆、离身体3cm；非布料物理；同名Tutor已建。

- 2026-11-14：[reference-aetheria-and-wowdecomp-upstream-catalog](reference-aetheria-and-wowdecomp-upstream-catalog/SKILL.md)：外部项目与可用功能目录（Shotboom12 的 aetheria-physics 披风/头发/抖动物理、动作镜头、WxlHost、活的艾泽拉斯、Azeroth Remastered；T1ti/wowdecomp 的泄漏与 GUID 结论），本地副本在 000modal\000aetheria；只读目录，未实测，用户转述作者已同意使用，无书面证明。

- 2026-11-14 PETBODY1H：选角宝宝多余白盾基本实机通过；对应 port-wotlk-custom-race-creation-flow 的 Skill/Tutor 已补限定验收。BODY1I和七族登录不继承验收。

- [repair-wow64-race-helmet-fitting](repair-wow64-race-helmet-fitting/SKILL.md)：头盔资源、挂点与尺寸；HELM2B/C 用户基本通过，格里恩/虚灵新报告待修。
- 2026-11-16 repair-wow64-race-helmet-fitting：德拉金99男女所测款式从方块恢复实际头盔，尺寸/穿脸仍需优化；仅登记资源显示改善，HELM99B/JOY2A各项候选不继承验收。

2026-11-16 [JOY限定止卡死反馈及多族拒载反例](port-coa-race-appearance-wxl/references/wow64-alias-regression-20261116.md)：机械侏儒点击卡死反馈通过，CENTAUR2B全模型兼容候选未实机验收，尚未发布。

2026-11-16后续限定验收：[CENTAUR2B各族恢复、半马披风白块消除](port-coa-race-appearance-wxl/references/wow64-alias-regression-20261116.md)；选角碎片仍失败，CENTAUR3A待测，不扩展所有动作/款式。

- 2026-11-16：[repair-wow64-animation-alias-streaming](repair-wow64-animation-alias-streaming/SKILL.md)：本窗口最终方法、失败反例与限定验收已归档；同名Tutor已同步。

- 2026-11-16：[repair-wow64-model-preview-lifecycle](repair-wow64-model-preview-lifecycle/SKILL.md)：本窗口最终方法、失败反例与限定验收已归档；同名Tutor已同步。

- 2026-11-16：[repair-wow64-race-helmet-fitting](repair-wow64-race-helmet-fitting/SKILL.md)：本窗口最终方法、失败反例与限定验收已归档；同名Tutor已同步。

- 2026-11-16：[overlay-armor-on-nonstandard-uv-race-models](overlay-armor-on-nonstandard-uv-race-models/SKILL.md)：本窗口最终方法、失败反例与限定验收已归档；同名Tutor已同步。

- 2026-11-17：自定义种族创建流程补NEUTRAL1A/B失败复盘、64位原生主表全链与GetModelDataRec空指针；1C候选待实机，不能列为完整可玩验收。

- 2026-11-17：port-coa-race-appearance-wxl补NEUTRAL1D基本模型反馈/内部ID碰撞与1501身体反例；port-wotlk-custom-race-creation-flow补NEUTRAL2A永久阵营/出生事务与客户端语言声望回执候选，进入世界/装备未验收。

- 2026-11-17：创建流程补NEUTRAL2A随机机器人无origin→失败清理GetMap断言反例；NEUTRAL2B仅两CPP候选，未实机。

- 2026-11-17：创建流程补NEUTRAL2D单模型按钮禁用/颜色/悬停/随机/提交及ValidCreate与旧存档Valid分离；候选离线通过，未实机。

- 2026-11-17 NEUTRAL2E：原创建流程Skill/Tutor补真实RB外层桥漏接反例、12+12出生地与DK普通出生、RBF3两库就绪及旧存档兼容；离线通过，实际创建/首登待验收。

2026-11-17 NEUTRAL2F：创建后黑屏/蓝白方块沿原创建Skill第4节核对真实选角场景链，77主表场景全量审计与2E漏项反例已补原Skill/Tutor；是场景修复候选，不换身体/装备，未实机。


20261118 NEUTRAL3A：头盔/身体UV衣物/模型生命周期/创建首登/职业资格五个原Skill和同名Tutor已补候选方法、失败反例与未测边界；完整包D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261118\codexfix_20261118_001419_阶段WOW64NEUTRAL3A_新种族装备头盔加载与炉石学习完整修复.zip。未实机验收，不晋升已验证。

2026-11-18 NEUTRAL3B：原生命周期/UV衣物/头盔三个Skill及同名Tutor补3A实机失败、opacity双重索引BFFFC、真实socket11与负例校验。候选已编译未实机，不能继续推荐3A单独安装。

2026-11-18 NEUTRAL3C：四个原Skill/Tutor补选角漏刷新、mip晚到缓存半套、Centaur102与Satyr110身份、骷髅1302、龙人披风和女妖幻化取景；已编译候选未游戏验收。来源D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261118\codexfix_20261118_062830_阶段WOW64NEUTRAL3C_衣物稳定加载与头盔披风幻化优化。

2026-11-18 NEUTRAL3D：3C新增隐身已标实机失败；77族资源检查、成功项固定、身体可见与衣物重试解耦反例已补原生命周期/衣物/创建Skill及同名Tutor。候选已编译，未游戏验收。包：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261118\codexfix_20261118_083839_阶段WOW64NEUTRAL3D_全种族审计与隐身回归修复.zip


### 2026-11-19 WOW64NEUTRAL3E（候选，未实机）
身体装备独立来源/stock dirty隔离、半人马材质恢复、骷髅直接1302选择、私有层非零动作bounds/披风，以及选角普通1/真幽灵0.4目标。3D身体装备实机失败不晋升已验收；构建/实际函数夹具/资源负例通过。已补模型生命周期和非标准身体装备同名Skill/Tutor。包SHA256 911f08d97c9d12d3e61c19aa33535842428857a7fafb621e52ceb1b1c29bd9ef，详见交接_Codex_WOW64NEUTRAL3E_身体装备披风与透明回归_20261119.md。

## 3N 衣物缓存用户验收

2026-11-21 客户端 3N 实测通过装备缓存修复。用户确认此前多数缺失的身体装备已显示。七份私有衣物曾因同名 clothing.m2 共享错误骨架，使用已有完整路径缓存选项恢复。仍有猴子和骷髅装备覆盖不全、平直披风、孢子人人物面板错位和幻化缩略格空白的报告。这些项由 3P 候选继续处理。
3N 实装 EXE SHA256 FAF7DC32C5865FBD23193A51AF31AE7F8BF9EBBC18FBDA7450B23BFE33234A27。

## 2026-11-21 3N 与 3P 私有衣物挂载验收

衣物切换后缺失先核对缓存返回的完整路径。人物面板复制附件时重新绑定预览骨架，幻化护甲格走独立试穿入口，披风形状根据背部取样调整。用户确认本次修复通过。
[完整排查方法](overlay-armor-on-nonstandard-uv-race-models/references/private-clothing-20261121.md)
- 2026-11-22：[port-retail-map-to-custom-client](port-retail-map-to-custom-client/SKILL.md)：零售12.1.0新地图(流放者之岛12175、禁忌离岛12570、创始人要塞)导入3.3.5自定义64位客户端的完整流程与排错：新map行与资料片字段、WorldMapArea轴方向、AreaTable/LiquidType补行、RetailCasc.ini三种模式、崩溃RVA定位、大型WMO洞穴地面随视角消失=门户剔除(ini wmoindoor=both，MAP12J用户确认搞定)；透明墙/小地图/服务端地面数据未解决；同名Tutor已建，需Codex合并RetailWmo/CascSource。
- 2026-11-24：[port-retail-quest-chain-to-wotlk](port-retail-quest-chain-to-wotlk/SKILL.md)：把零售(12.x)任务链从 LoreWalkerTDB 提取并翻译成 3.3.5 的流程(台账、批量提取、目标翻译表、NPC/出生点编号规则、双语文本、交付验收)；用户实测通过的部分：船上任务链与失事动画、海滩 59929–59931、营地、零售野猪模型、急救包"使用→选最近未治疗伤员→连续使用"(FIRSTAID1C，用户"这次完美了")；BOOST1A 飞行、CAMP1A 篝火闪光、QMAP1A V2、SHIP2D V2/2E 仅为候选未测。
- 2026-11-24：[find-and-extract-retail-resources-for-wotlk](find-and-extract-retail-resources-for-wotlk/SKILL.md)：从零售数据库/wago.tools/listfile/本地零售 CASC 查找并提取任务、NPC、图标、模型、地图、过场动画，及"客户端当前生效的是哪份 DBC"的查法、服务端 .map 地面数据；其他服务器补丁的提取只是候选流程，未实测；vmaps/mmaps 未做。

## 2026-11-24 泰坦首登与部落鱼人

- 泰坦 91。用户确认“这次泰坦 这个进游戏通过了”。验收范围是 2B 建角、出生数据和累计 2F 客户端的进入世界。各出生任务、盔盾参数、脚步震动、披风与理发保留专项待验。
- 部落鱼人 121。截图显示已有角色进世界。建角灰图标应从实际生效的 YB 开始核对。只升级程序时，旧 Lua 和种族表仍会走灰色占位。实装 3B 男女头像分别匹配包内资源，3D Lua 也含男女两条路径。全肤色重登、男盔随动及各装备专项单独验收。
- 鱼人猎人 3G。用户确认“可以了 这下 动作可以了 动作一致了”。仅登记所测的射击动作通过。出生 23347 是劣质弩，走 48/49/106/110。3F 只接弓请求，实测无右手动作。3G 保留请求 ID，复用同模型的 108/107 关键帧，106 增加 BWP，49 增加 BWR，36 号出弹点跟右手。女模有原始序列但投掷查找项缺失时，应按序列 ID 查到真实记录。
- 3G 的弹药槽脚本已装但未单独确认。近战武器离手、法杖穿臂由后续截图报告，保留复查。射击动作、出弹位置、近远切换、弹药槽、收武器都需分别验收。
- 11-23 的种族头像错位与男女头像已有 1B 基本验收。阵营复用令牌时，以真实种族 ID、阵营和性别定位头像。沿用 11-23 验收时间。
- 2026-11-24 验收补充：[port-retail-quest-chain-to-wotlk](port-retail-quest-chain-to-wotlk/SKILL.md) 增加用户实测通过的乘坐飞行侦察(BOOST2A/2B)、篝火光标(CAMP1A V3)、缩放器自定义编号 9178051(SIZER1A/1B)及"零售编号 178051 不认使用效果"的坑。

## 2026-11-25 矮小鱼人死亡骑士符文熔铸

用户确认男女鱼人死亡骑士的符文熔铸功能通过。新种族法术书已显示 53428 但点击无面板时，沿 SkillLineAbility 追到技能线 776，核对双端 SkillRaceClassInfo 记录 936。用不限种族且仅死亡骑士的资格修复，并给已学法术但缺技能线的角色在登录时走原生补录。所测鱼人男女通过。逐条配方、任务交付及其他种族分别验收。详见 [1B 验收记录](../000Ascendupdate/000Ascendupdate20261125/验收_WOW64FISHCLASS1B_鱼人男女符文熔铸.md)。

## 2026-11-25 熊人符文灵魂之剑贴背

用户确认 1E 的熊人符文灵魂之剑收起效果。若斜背角度正确但剑仍离身，同时检查剑柄和剑尖到背部的间隙。用当前生效 M2 与 SKIN 的站立和动作采样校准位置及角度，保留原收剑骨骼并限定具体武器。其它武器和全动作矩阵分别验收。[1E 实测记录](../000Ascendupdate/000Ascendupdate20261125/验收_WOW64FISHCLASS1E_熊人符文剑贴背.md)

- 2026-11-25 部落线收尾：[port-retail-quest-chain-to-wotlk](port-retail-quest-chain-to-wotlk/SKILL.md) 增加计数生物缺失、ALE 对话返回值、SQL 重跑覆盖、任务地图标记、头目体型与封门做法；[find-and-extract-retail-resources-for-wotlk](find-and-extract-retail-resources-for-wotlk/SKILL.md) 增加零售地图 vmaps/mmaps 流程(已装服务端，实机效果未单独确认)。

- 2026-11-25：[port-retail-cinematic-to-wotlk](port-retail-cinematic-to-wotlk/SKILL.md)：高版本过场动画移植(多版本查找提取、DIVX 转码、MPQ 导入、插件按路径播放、服务端触发)；部落与联盟船失事影片用户实机通过，ESC 跳过未单独确认。含一键脚本。

- 2026-11-26 双阵营验收：[port-retail-quest-chain-to-wotlk](port-retail-quest-chain-to-wotlk/SKILL.md) 增加两阵营相位、物体分身、共用脚本；[find-and-extract-retail-resources-for-wotlk](find-and-extract-retail-resources-for-wotlk/SKILL.md) 增加零售人形模型 retail\ 路径与离线渲染。

- 2026-11-26：[port-retail-zone-end-to-end](port-retail-zone-end-to-end/SKILL.md)：高版本区域完整移植总流程与清单(地图、任务、双阵营、原版模型、数值、经验、金币掉落、穿戴限制、验收)；新地图移植先读它，再进各分项 Skill。

## 2026-11-26 男魔古 123 外观验收

WOW64MOGU1D 获用户确认男法师 NO 装备建角预览。CoA V2.03 Client-11/18 与 32 位 NEUTRAL1 V50 使用相同的 123 男性 CharacterFacialHairStyles 三条记录。64 位只有旧追加表时，主表缺记录会保留默认 101/201，连带出现帽兜和披风。按种族、性别、特征键将三行补入生效主表，用默认的 103/203 复核并回退旧改色；保留 1B 烘焙。核对当前生效主表、实际三套 SKIN、老版验收有限范围，不把单独截图扩大到装备或进世界。本日验收文件见 000Ascendupdate/000Ascendupdate20261126/验收_WOW64MOGU1D_男魔古建角.md。

- 2026-11-26：port-wotlk-custom-race-creation-flow 新增女魔古1I+1J面部限定通过；palette格式、type8图集和源码未编译反例。STARTFIX1A其他修正仍候选。

- 2026-11-27：port-wotlk-custom-race-creation-flow新增STARTFIX1A漏inl导致鱼人资格回退的反例；1B为候选待测，不能仅以CPP编译成功认定累计完整。

- 2026-11-27：新种族流程新增STARTFIX1C characters CHECK 3819反例及所有未来注册种族共用141要求；SQL17项隔离验证，游戏待测。

- 2026-11-27：STARTFIX1C 用户确认本批流放岛建角/进入与熊人坐下/对话落地通过；披风另案未验。见新种族流程Skill/Tutor的限定验收。

- 2026-11-28 [端到端新种族移植流程](port-wow64-playable-race-end-to-end/SKILL.md)：覆盖按钮→职业→男女模型/UV→装备/动作→出生/首登与累计编译；含本窗口失败台账与交付前检查表。总体基本通过不外推全矩阵。

- 2026-11-28：[Stormforged男女全身衣物/披风与root登录链验收](port-wow64-playable-race-end-to-end/references/stormforged-20261128.md)，目录遮挡、材质识别、复制UV层与新增顶点指纹。
