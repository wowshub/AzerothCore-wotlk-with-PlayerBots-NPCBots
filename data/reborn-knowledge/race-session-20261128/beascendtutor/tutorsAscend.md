# beAscend Tutor Catalog

## 2026-09-29 本窗口新教程

- [restore-coa-wmo-minimap-mappings](restore-coa-wmo-minimap-mappings/TUTOR.md)：用“房子地址与平面图索引”解释 WMO 改名后小地图黑圆。
- [seam-coa-northshire-adt-boundaries](seam-coa-northshire-adt-boundaries/TUTOR.md)：用“地砖与斜坡”解释 ADT 高度接缝及草地模型地址。
- [本窗口总教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260929/codexfix_202609290608_阶段交接_成功经验与源码推送/tutor.md)：串讲天赋真实归属、提示、小地图和地形四层。
- [trace-and-port-coa-spell-resources](trace-and-port-coa-spell-resources/TUTOR.md)：补充 WD85A/B 两项已测试巫毒天赋的命中归属、周期结算和 DBC 字符串修正教学。

Tutor 面向新人，用“生活类比 → 数据流 → 代码 → 测试矩阵”的顺序解释对应 Skill。目录必须与 `beascendskills` 一一对应。

## 课程目录

| Tutor | 新人能学会什么 |
|---|---|
| [repair-wotlk-spell-cast-posture](repair-wotlk-spell-cast-posture/TUTOR.md) | 区分施法起手与周期飞弹，并将姿势绑定到Aura生命周期 |
| [overlay-armor-on-nonstandard-uv-race-models](overlay-armor-on-nonstandard-uv-race-models/TUTOR.md) | 用"人偶和包装纸"理解为什么新种族穿不上胸甲，以及装备叠加层、镜像排布、烘焙底图怎么让它穿上 |
| [bridge-native-class-mechanics-into-spelldraft](bridge-native-class-mechanics-into-spelldraft/00-course-map.md) | 区分“学会法术”“拥有职业资格”“底层资源结构”，理解灵魂链接与泰坦之握桥接 |
| [build-spelldraft-talent-management-cards](build-spelldraft-talent-management-cards/00-course-map.md) | 理解已确认等级、Pending 和逐级退款 |
| [repair-spelldraft-native-passive-talents](repair-spelldraft-native-passive-talents/00-course-map.md) | 从 character_spell 到 Aura、属性、重登与退款闭环 |
| [build-spelldraft-mystic-enchant-system](build-spelldraft-mystic-enchant-system/00-course-map.md) | 区分装备词缀与角色19槽，学习定向石、双语图鉴、滚动总览、Frame父子关系、右侧停靠和Base Stats锚点恢复 |
| [stabilize-spelldraft-client-ui](stabilize-spelldraft-client-ui/00-course-map.md) | 父子层级、frame strata、拖动层和快照缓存 |
| [repair-multiclass-summon-lifecycle](repair-multiclass-summon-lifecycle/00-course-map.md) | 主宠、守护者、多召唤上限和稳定 Buff |
| [control-spelldraft-reward-drops](control-spelldraft-reward-drops/00-course-map.md) | 模式隔离、等级差软衰减和可配置掉率 |
| [repair-custom-client-dbc-crashes](repair-custom-client-dbc-crashes/00-course-map.md) | 用 Error #132 与 DBC 基线定位缺记录崩溃 |
| [repair-dungeon-map-coordinate-projection](repair-dungeon-map-coordinate-projection/00-course-map.md) | 地图素材、楼层记录、坐标投影和记录 ID 冲突 |
| [build-portable-service-vendors](build-portable-service-vendors/00-course-map.md) | 商人模板检查、服务入口、五分钟召唤和冷却 |
| [deliver-web-shop-items-transactionally](deliver-web-shop-items-transactionally/00-course-map.md) | 为什么扣款、库存、订单和邮件必须在同一事务中 |
| [build-complete-dungeon-quest-helper](build-complete-dungeon-quest-helper/00-course-map.md) | 从实时任务库生成全副本任务，并学会物品门槛、starter/ender分权与ElseGroup防绕过 |
| [build-account-glyph-collection-preview](build-account-glyph-collection-preview/00-course-map.md) | 角色收藏权威、永久刻录、金币装备/替换、AIO快照与生物缓存预热 |
| [map-custom-race-shapeshift-models](map-custom-race-shapeshift-models/00-course-map.md) | 形态选模优先级、RaceID边界、旧精确行冲突与可回滚SQL |
| [deliver-breaking-news-reliably](deliver-breaking-news-reliably/00-course-map.md) | 理解角色枚举、Warden初始化竞态、安全载荷编码与GlueXML父级 |
| [build-wotlk-monk-combat-visuals](build-wotlk-monk-combat-visuals/00-course-map.md) | 用演员与舞台类比理解武僧动作、特效、声音资源、运行时仲裁、Trampoline与x86 DLL编译 |
| [backport-wotlk-addon-api-compatibly](backport-wotlk-addon-api-compatibly/00-course-map.md) | 用口令翻译和插头转换器理解新版插件 API 的 3.3.5a 兼容层 |
| [integrate-playerbots-extension-module](integrate-playerbots-extension-module/00-course-map.md) | 用「老款车装新款自动驾驶套件」理解模块识别规则、真编译器预检、新旧依赖兼容和看记录排错；附插件中英切换与 /reload 不加载新文件；机器人战斗统计与职责口径；岩石大厅修复批次（躲技能高度差、事件不直线穿墙、灭团后恢复目标、坠落记录器）；DCMOV2A：机器人为何会走到地图下面（古达克实测通过）；DC20261012：首领连灭怎么找原因、随机副本队伍为何不能重置；连续清本：传送途中玩家暂不在世界中，不能当下线 |

## 已纠正的旧结论

- 灵魂链接不再是“待测”：实机确认宠物分担 20% 伤害。
- 泰坦之握不再是“待测”：实机确认双手双持、`Penalty=-10`，Tooltip 显示 10%，经典战士路径保留。
- 多召唤只把“最多 2 个”列为已验收；宠物技能条、灵魂碎片和恶魔学识长期稳定仍保留待办。


2026-09-06：`build-wotlk-monk-combat-visuals`已补充M6L3切喉手222与M6L2 B水中218/221成功案例；来源`D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20260906\codexfix_202609060405_阶段M6M1_怒雷破引导连击\checks\上一阶段成功基线`。

- 2026-09-06：[build-wotlk-conditional-damage-absorb](build-wotlk-conditional-damage-absorb/00-course-map.md)，M6N1躯不坏基本使用用户确认；精确边界与组合矩阵保留待测。


- 壮胆酒百分比生命防御，M6Q1用户基本确认：[adapt-wotlk-percent-health-defensive](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendtutor/adapt-wotlk-percent-health-defensive/00-course-map.md)

- 2026-09-07 分筋错骨位置控制教学（基本实机通过）：[adapt-wotlk-positional-single-target-control](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendtutor/adapt-wotlk-positional-single-target-control/00-course-map.md)；来源M6S2。

- 新增职业职责/专业许可：[新人课程](integrate-wotlk-custom-class-ui-eligibility/00-course-map.md)

- [repair-wotlk-item-texture-references](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendtutor/repair-wotlk-item-texture-references/00-course-map.md) — 三项实测成功归档，2026-09-08。

- [adapt-wotlk-native-single-target-taunt](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendtutor/adapt-wotlk-native-single-target-taunt/00-course-map.md) — 三项实测成功归档，2026-09-08。

- [repair-wotlk-action-icon-tint-conflicts](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendtutor/repair-wotlk-action-icon-tint-conflicts/00-course-map.md) — 三项实测成功归档，2026-09-08。

- M6AC1累计武僧批次教学：D:\000rebornWOW\000RebornWOWHighForkPRO\beascendtutor\extend-wotlk-monk-skill-batches\tutor.md，仅基本实机反馈范围。

- [创建角色职业数组越界](创建角色职业数组越界.md)


## 2026-09-14 武僧本轮已验证流程

- [00-course-map.md](<D:/000rebornWOW/000RebornWOWHighForkPRO/beascendtutor/build-wotlk-three-build-projection/00-course-map.md>)
- [00-course-map.md](<D:/000rebornWOW/000RebornWOWHighForkPRO/beascendtutor/audit-wotlk-shadowing-mpq-backups/00-course-map.md>)
- [00-course-map.md](<D:/000rebornWOW/000RebornWOWHighForkPRO/beascendtutor/restrict-wotlk-custom-class-creation/00-course-map.md>)

2026-09-16：[新增职业资格教学](integrate-wotlk-custom-class-ui-eligibility/00-course-map.md)补充武僧方法迁移到巫医、Skill入口漏检复盘；WD10B待实测。

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


- 2026-09-17 EV2C：[原装备衣柜教学](store-wotlk-original-equipment-in-wardrobe/TUTOR.md)，限定基本实机反馈，异常边界待验证。

- 2026-09-17 [EV2D逐件取回基本确认](store-wotlk-original-equipment-in-wardrobe/TUTOR.md)；大退显示EV2D1修复待验收。

- [EV2D1自动补图基本确认](stabilize-spelldraft-client-ui/TUTOR.md)，红问号展示EV2D3待验收。

- [EV2D7 OneBag拖回基本实测确认](store-wotlk-original-equipment-in-wardrobe/TUTOR.md)，精确落格/交换未实现。

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
[Tutor](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendtutor/repair-wotlk-m2-sequence-header-overlap/TUTOR.md)；用户反馈骑马正常。只适用已确认二进制重叠，不能泛用于所有滑行。


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

- [guard-wotlk-battleground-map-preview-markers](guard-wotlk-battleground-map-preview-markers/TUTOR.md)：战场预览地图与真实人物位置的区分；MAP74A 本批用户确认。

- bridge-native-class-mechanics-into-spelldraft：新增巫医自动循环与持弓显示分项验收案例，WD71C待测试。

2026-09-26 UI76B弹药槽基本显示用户确认通过，更新integrate-wotlk-custom-class-ui-eligibility/00-course-map.md；UI76C腰带与创建预览为候选。

2026-09-26：UI76C腰带用户通过、创建预览失败分别登记职业兼容教学；UI76D外层/内部DLL区分见当日tutor，未验收。

2026-09-26 UI76D基本换装确认，UI76E随机刷新候选，分项登记职业兼容教程。

- 2026-09-26：[repair-wotlk-model-index-buffer-capacity](repair-wotlk-model-index-buffer-capacity/TUTOR.md)，模型索引容量与同页VirtualProtect失败教学。


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


## 2026-10-05 WD113—WD127逐行课程

- [synchronize-wotlk-spell-costs-and-cooldowns](synchronize-wotlk-spell-costs-and-cooldowns/TUTOR.md)：服务端冷却与客户端预测、两侧文本、序号缓存、84项Lua测试。
- [全部成功／失败过程的总教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261005/codexsummary_202610050358_阶段WD113至WD127_成功失败教学与交接/tutor.md)与[逐阶段教程索引](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261005/codexsummary_202610050358_阶段WD113至WD127_成功失败教学与交接/逐阶段教学索引.md)。三份既有Skill对应Tutor同步更新。


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


## 2026-10-07 当日双端同步
[大白话教学](release-tested-reborn-features/daily-sync.md)：客户端patch、服务端Data、SQL的独立交付与按批并集合并，绑定已验收提交和Release。

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

## 2026-10-11 流程规范类教程（v2 正式版）

- [coordinate-ai-team-parallel-development](coordinate-ai-team-parallel-development/TUTOR.md)：用"几个师傅装修同一套房子"讲 AI 团队怎么协作：留言板登记、样板间和干净房间（发布 worktree）、一个修复从开工到发布的完整流程、出问题先分四类。


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


## 2026-10-13 WD145A+B 用户基本验收
灵魂蚀/暗影洛阿之灵/灵魂信徒/村落智慧，以及暗影分类/命中显示通过。灵魂数在施放前快照，追加施法必须排除递归；满层刷新仍是获得事件。百分比命中不同于命中等级，显示从服务器实际光环确认，不按草稿推断。被动也必须补SkillLineAbility分支映射。DBC字段以实际结构为准，注册宏完整名字与SQL逐字核对。
[验收](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261013/release_WD145B/ACCEPTANCE.md) · [教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261013/release_WD145B/TUTOR.md)；资源SHA256 44dc667e48263b8913bf5520f752471e9d5c58c083673f91ec374de00a1050cc。发布状态以后续最终发布记录为准，未部署或生产SQL。

- [audit-and-port-upstream-features](audit-and-port-upstream-features/TUTOR.md)：用户2026-10-14要求的完整移植教学与避坑流程；非技能实机验收。


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
[repair-playerbots-unit-cache-lifetime](repair-playerbots-unit-cache-lifetime/TUTOR.md)：用户原场景复测不再崩溃；仅基本通过，未扩大全部竞态/长期压力。

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


## 2026-10-21 巫医Playerbot基础AI验收与复用
用户明确选择WD176A累计晨测总包允许发布，实测观察输出改善、六蛇技能使用；不外推精确DPS比例、三系所有主动、交易/生命周期或177–184新治疗。新增[port-coa-playerbot-class-ai](port-coa-playerbot-class-ai/TUTOR.md)，对应Tutor同名，记录已存方案/真实已学、主循环+通用技能、正常资源、自动来源和安全副目标/召唤、固定副本测量。冻结176包43d6db520e3d86e37ac5d951f19894bb2e8d968244d9bc451a769e5807f9f6e1；正式提交状态见协作说明。原167验收保持。


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


## 2026-10-22 WD177–WD204C逐批正式发布完成
用户原话：“嗯嗯 前面的这几个包我测试 我觉得可以通过 并帮我一个一个进行推送远端”。按本对话最终WD204C累计范围登记基本实测通过，不扩大全等级/PvP/全部技能数值、精确DPS、三系固定副本和全部生命周期专项；旧候选历史与metadata不改写。204A/B撤回审查策略不发布，自动幻象仍待。
主仓最终48be5b0a8894227d0b51a770f7e867b8d82575b4；Playerbots最终d915f9dae06a6c4fb1e75a9c077e91a05e00f5e8。29主仓分项提交、22PB提交、29附注tag/非草稿Release已逐项正常推送并读回，未强推。185原弹药/186原引导发布保留，本轮185只有累计日志标记补归档。各阶段SHA/tag/URL见D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261022/release_WD177_WD204C/publication.json。
最终Release：https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-wd204c-20261022
附件reborn-wd204c-20261022-resources.zip，14467554字节，SHA256 d876d29d23c83500f5e290de2a10b5df5a0fa51f67e2f21f6d992480acf8511c；远端uploaded/大小/digest一致。48源码覆盖文件+完整客户端，原WD196B World绑定继承；无新增Data/DBC/MPQ/配置、Characters/Auth迁移。已装204C测试通过无需重装；生产SQL/编译/部署仍用户自行负责。
每阶段及最终Git实际存储文件与白名单输出逐项读回。最终相对原204C只有原正式保留的WD165/166根文件排除，该差异与176正式排除逐块相同。5个最终有效CPP（含导师Trainer）语法检查通过；538AI及各旧脚本/Lua矩阵标为继承证据，不假称本轮全部重跑。没有生成游戏EXE、部署、生产SQL或launcher上传，日常/运行/Claude文件未改。原28无关mode及pycache保留、暂存净。
失败复盘：白名单复制保留mtime、文件大小相同的纯阶段日志变更可被Git stat cache漏检；提交检查立即拒绝，未推送有遗漏内容。改为复制后os.utime并逐提交读取Git blob比对；29阶段全部读回通过后再推送。不是删断言或整树git add。既有文件新纳入累计包时必须查原backup并三方合并，不能按新增文件直接覆盖。
下一步：C09假死/化蛇/幻象的自动使用、停止攻击/移动、到期/撤销恢复；当前三个自动逃生闭环尚未完成。本轮只发布已验收内容，没有新增开发包。今晚最终待测汇总为目标，不承诺未经实机确认即全部结束；明日可先N00审计，不把NPCBot算已接入。G/T/S/N/R完整清单及未测矩阵继续保留。

2026-10-22 [TG23A双语教学](stabilize-spelldraft-client-ui/TG23A-bilingual-accepted.md)；TG23B入口候选待测，PB205防御与NPCBot不继承。

2026-10-23 [WDN1A候选教学](plan-coa-class-migration/WDN1A-npcbot-candidate.md)，未实机验收。

2026-10-23 [WDN1A候选教学](plan-coa-class-migration/WDN1A-npcbot-candidate.md)，未实机验收。

2026-10-23 [TG23B教学](stabilize-spelldraft-client-ui/TG23B-toggle-accepted.md)；仅图标二次点击关闭基本通过，NPC/205仍待测。

## 2026-10-23 WDN1D1 NPCBot固定菜单双语基本通过并发布
用户：“双语通过 但是 还是不打”。只确认原生主菜单/职责菜单中文与英文同屏；375条固定来源文本不扩大为全部子菜单布局或15格式化动态提示均已测试。以原有en/zh/本批输出匹配后事务更新两表，保留自定义与其他语言，原生启动加载。SQL SHA256 7dd76176d6f2bf1db0633c989eede6e93bb1fb89d9a97306030cf529fd4819a5。
正式提交 6ba57ca1ba5653c4e15ce973b33d748c214420fb，tag reborn-wdn1d1-bilingual-20261023；Release https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-wdn1d1-bilingual-20261023，资源uploaded且digest/大小读回匹配 279c3b6e3296faf43b990daf393237b4782dd784f3bf4153ebdfc78e6d1ca8f5。不含NPC战斗AI；D2先报不打，随后用户确认灵魂战刃已释放，远程职责实际曾未勾选，roles36；Ereer为治疗来源，不得当作NPC自疗验收。自动射击/引怪稳定性D3仍候选，无治疗或坦克体系验收。
发布证据：000Ascendupdate/000Ascendupdate20261023/release_WDN1D1_bilingual/publication.json；原D1/D2冻结包不修改。

2026-10-23 WDN1D3私有NPC自动射击用户基本通过：见audit-and-port-upstream-features同名Skill/Tutor；非完整NPC/引怪验收。C1蛇卫候选不继承。

2026-10-23 WDN1C1 NPC基础蛇卫与持续射击用户基本通过，见audit-and-port-upstream-features Skill/Tutor；高级召唤和治疗未接入。

2026-10-23 WDN1C1已正式发布6483ebaa，见audit-and-port-upstream-features对应Skill/Tutor及release_WDN1C1/publication.json。

- WDN5G巫祝六入口与F联动累计候选；详port-coa-playerbot-class-ai，游戏未运行。包SHA256 71c897898eb0aadf58a33fdbb8fdb09c740d48f8118c57e3a38f2adf9b542a8b。

- 2026-10-26 WDN5H：port-coa-playerbot-class-ai补Jinx按真实资源/移动选择及原生吸蓝审查反例；候选游戏未运行，不晋升成功能力。


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
蛇人/双头食人魔顶部图标、原生圆环与对称位置获用户截图确认。复用 [stabilize-spelldraft-client-ui](stabilize-spelldraft-client-ui/TUTOR.md) 的头像/外环分层检查；模型黑影、正式创建未解决。详当日 codexdoc_UIR1B 逐行教学与 release_UIR1B 发布证据。


## 2026-10-29 UIR1B 已提交、推送并发布
提交 2af15d3e0ee52a1d0865b8d9efe3e51316501787；分支 wowshub/threemodelcardpro，标签 reborn-uir1b-20261029 解引用一致。
[Release](https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-uir1b-20261029) 非草稿，目标 threemodelcardpro，两个附件 uploaded，大小和 SHA256 读回全部一致。
仅蛇人/双头食人魔顶栏圆图、阵营环、蛇人选中与对称布局基本确认；模型黑影待修，正式创建未开放。4/4现场文件匹配冻结B；没有部署、编译、SQL或launcher改动。23文件白名单提交，既有无关工作树修改未暂存。
发布证据：000Ascendupdate/000Ascendupdate20261029/release_UIR1B/publication.json。MD及新旧完整文件在当日 codexdoc_UIR1B_蛇人与食人魔图标逐行教学，Release附教学ZIP。
资源SHA256 33360450d7006b0dacfd701cfa1d48ad524b374e4dcaeeff2707e57ced30d7a4；教学SHA256 8d7fedbff22a350f29f8cfc317897719712320c9a8df13c2712aa8362e5693ef。


## 2026-10-29 新职业武器大师学习教学
更新[integrate-wotlk-custom-class-ui-eligibility/TUTOR](integrate-wotlk-custom-class-ui-eligibility/TUTOR.md)和课程目录：职业能学、NPC有课、物品能装备三层检查，附武器支持/NPC/费用/等级矩阵。WDWP1A/B游戏待测。


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


## 2026-10-31 WHUI1A图标入口/圆环/锚点/共享YB与私有XB，教学并入integrate-wotlk-custom-class-ui-eligibility；详细逐行教学见WHUI1A测试包。

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

## 2026-11-07 39/49战士建角与出生流程

[port-wotlk-custom-race-creation-flow](../beascendskills/port-wotlk-custom-race-creation-flow/SKILL.md)已补39/49有限验收与前置技能顺序、共享位隔离/双端表、冻结SQL核验经验；[逐步教学](../000Ascendupdate/000Ascendupdate20261107/总结教学_20261107_新种族联合移植与天赋修复/00_从这里开始.md)。用户基本首测通过，专属种族特性和全矩阵仍待做；不把TGFIX全部经典职业专项或猎巫四专精写成完成。

## 2026-11-08 新种族猎人武器检查补充

port-wotlk-custom-race-creation-flow已补弓45/264、枪46/266、弩226/5011、自动射击75的出生前授予、旧角色补缺、弹药匹配及实际装备/射击矩阵。RACECLASS1C仍候选待实机，源于用户报告物品23347无法使用，不将旧职业验收继承到新种族。

### 2026-11-08 RACECOMBO1A教学索引
原创建流程Tutor与UI稳定Tutor追加首登“服务器锁住但窗口未到”的排查及验收边界。完整建模、UV、握手/回执与SQL回退教学在当日RACECOMBO1A包01_小白教学.md；候选未实机，不晋升成功配方。


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
[guard-wotlk-battleground-bot-exit-lifecycle](guard-wotlk-battleground-bot-exit-lifecycle/TUTOR.md)：地图战场类型不保证owner BG引用存在；HLBGBOTEXIT1A空引用退场崩溃证据、验证矩阵与暂缓迁入原则。

## 2026-11-11 WOW64PORT1B候选与失败回归
理发/外观原Skill及同名Tutor已补64位缺49样式、捐赠方ID20/49/50/51身份冲突；尚未实机验收，不扩大旧x86成功范围。交接：交接_Codex_WOW64PORT1B_Online预览理发与外观身份候选_20261111.md。

- 2026-11-13：[机械侏儒肢体与装备冲突](port-coa-race-appearance-wxl/TUTOR.md)：WOW64RACEPORT1E男女穿装缺腿用户基本通过，4/4实装匹配；D空面与E部件组冲突分层；全装备/动作未全验收，顶部错字未修。


### 2026-11-14 原种族外观流程补充
port-coa-race-appearance-wxl补入EsteriaOff诊断开关遗留/静态缓存冷启动/用户全部恢复证据；同名Tutor和当天逐行教学已同步。

- [头盔资源、挂点与尺寸](repair-wow64-race-helmet-fitting/TUTOR.md)：HELM2B/C 教学与验收边界。
- 2026-11-16 repair-wow64-race-helmet-fitting：新增德拉金男女资源已显示、大小仍待修的限定反馈；强调有资源与合身分开验收，旧2.0/0.90不是成功参数。

2026-11-16 [动画坏链与整人物拒载复盘](../beascendskills/port-coa-race-appearance-wxl/references/wow64-alias-regression-20261116.md)：限定JOY反馈、15条目回归、120条目离线检查；新包待实机。

2026-11-16 [CENTAUR2B限定反馈与半马披风贴图链](../beascendskills/port-coa-race-appearance-wxl/references/wow64-alias-regression-20261116.md)：各族恢复、背白消除；伪敬礼入场修正仍待测。

- 2026-11-16：[repair-wow64-animation-alias-streaming](repair-wow64-animation-alias-streaming/TUTOR.md)：本窗口修复教学与最终验收边界。

- 2026-11-16：[repair-wow64-model-preview-lifecycle](repair-wow64-model-preview-lifecycle/TUTOR.md)：本窗口修复教学与最终验收边界。

- 2026-11-16：[repair-wow64-race-helmet-fitting](repair-wow64-race-helmet-fitting/TUTOR.md)：本窗口修复教学与最终验收边界。

- 2026-11-16：[overlay-armor-on-nonstandard-uv-race-models](overlay-armor-on-nonstandard-uv-race-models/TUTOR.md)：本窗口修复教学与最终验收边界。

- 2026-11-17：自定义种族创建流程补NEUTRAL1A/B失败复盘、64位原生主表全链与GetModelDataRec空指针；1C候选待实机，不能列为完整可玩验收。

- 2026-11-17：port-coa-race-appearance-wxl补NEUTRAL1D基本模型反馈/内部ID碰撞与1501身体反例；port-wotlk-custom-race-creation-flow补NEUTRAL2A永久阵营/出生事务与客户端语言声望回执候选，进入世界/装备未验收。

- 2026-11-17：创建流程补NEUTRAL2A随机机器人无origin→失败清理GetMap断言反例；NEUTRAL2B仅两CPP候选，未实机。

- 2026-11-17：创建流程补NEUTRAL2D单模型按钮禁用/颜色/悬停/随机/提交及ValidCreate与旧存档Valid分离；候选离线通过，未实机。

## 2026-11-24 新增教程

- [port-retail-quest-chain-to-wotlk](port-retail-quest-chain-to-wotlk/TUTOR.md)：用"翻译"的思路讲怎么把零售任务链搬到 3.3.5：列清单、分批、提取、目标翻译、NPC 编号、双语、交付、常见坑。
- [find-and-extract-retail-resources-for-wotlk](find-and-extract-retail-resources-for-wotlk/TUTOR.md)：用"仓库、目录、对照表"的比方讲怎么找和取零售资源，先查客户端已有，再零售，再改装、查赢的那份、三关检查；其他服务器资源为候选流程。

## 2026-11-24 鱼人远程动作复用

先确认远程物品子类。23347 是弩，走枪弩 48/49/106/110，弓走 29/46/47/105/109。缺失动作可用同一 M2 的 108 准备投掷与 107 投掷攻击替代。增加可直接查询的原生请求 ID，保留已有序列和数据。以实际客户端事件回调为准核对 BWP/BWR，弓用 35、枪弩用 36；保持右手链随动作变化。实际射击和收武器要在进世界后验证，近远切换与面板弹药槽是独立问题。

- 2026-11-25 补充：任务链收尾三个坑(一接就完成、对话选项不见、文字变回旧版)与“怪掉进深渊”的原因，见两个同名 Tutor 末尾。

- [port-retail-cinematic-to-wotlk](port-retail-cinematic-to-wotlk/TUTOR.md)：用“片子、放映员、导演”讲怎么给任务加高版本过场动画，以及没画面时按什么顺序排查。

- 2026-11-26：任务链与零售资源两篇 Tutor 增加"两阵营共用一座岛""人物动作扭曲"两节大白话。

- 2026-11-26：[port-retail-zone-end-to-end](port-retail-zone-end-to-end/TUTOR.md)：用"开一家新店"讲一张高版本地图怎样一次搬完整。

- 2026-11-26：port-wotlk-custom-race-creation-flow 新增女魔古1I+1J面部限定通过；palette格式、type8图集和源码未编译反例。STARTFIX1A其他修正仍候选。

- 2026-11-27：port-wotlk-custom-race-creation-flow新增STARTFIX1A漏inl导致鱼人资格回退的反例；1B为候选待测，不能仅以CPP编译成功认定累计完整。

- 2026-11-27：新种族流程新增STARTFIX1C characters CHECK 3819反例及所有未来注册种族共用141要求；SQL17项隔离验证，游戏待测。

- 2026-11-27：STARTFIX1C 用户确认本批流放岛建角/进入与熊人坐下/对话落地通过；披风另案未验。见新种族流程Skill/Tutor的限定验收。

- 2026-11-28 [新种族移植教学与失败复盘](port-wow64-playable-race-end-to-end/TUTOR.md)：覆盖按钮→职业→男女模型/UV→装备/动作→出生/首登与累计编译；含本窗口失败台账与交付前检查表。总体基本通过不外推全矩阵。
