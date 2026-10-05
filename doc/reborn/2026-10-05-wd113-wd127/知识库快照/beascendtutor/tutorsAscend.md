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
