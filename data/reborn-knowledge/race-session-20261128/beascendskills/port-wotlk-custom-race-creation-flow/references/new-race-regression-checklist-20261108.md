# 新种族移植：基础漏项与回归清单（用户要求，2026-11-08）

用于新增种族、给既有新族开放职业、改ClientFileString/ClientPrefix、更换身体模型或发布其累计包。按本批实际开放的种族/性别/职业填写，不把一个角色通过外推全矩阵。不相关行标明原因，候选/静态/实机通过分别记。

| 检查项 | 必须核对的真实链 | 实机验收重点/失败教训 |
|---|---|---|
| 身份与出生 | 真实raceID/性别/职业、共享mask、创建前技能、语言双ID、声望模板 | 不继承共享位母族专长；出生物品能实际穿，不只在包里；重登只补缺，不重发装或降熟练度 |
| 猎人武器 | 弓45/264、枪46/266、弩226/5011、自动射击75，技能DBC与Spell资格 | 每一种实际装备、匹配箭/子弹、起射停止、重登；不能只复制供体出生武器 |
| 猎人弹药槽 | 普通Hunter3/HUNTER与13/14/15自定义职业分别接入原生slot0 | 原生Update可能再次Hide；保留native按钮/OnClick，检查穿脱、冷启动、缓存晚到和战斗队列。背包有箭、自动射击成功均不能替代面板槽验收。Zann曾延迟后显示，唯一事件根因未证明，不盲删WTF/缓存 |
| 萨满四元素 | 精确RaceID→四slot显示ID→客户端/服务器各自Display/Model→M2/SKIN/ANIM/BLP | 单放、组放、替换、回收、到期；防DisplayID0与资源缺失。已有原生安全回退保留，不能只改一种图腾或盲归咎BLP格式；大小、名字高度及name attachment18分别核对 |
| 变身与恢复 | 幽灵狼/恶魔变形/小德各形态等本批已开放技能 | 变前→变中→取消→重登，比较真实race、原生Display、皮肤/脸、装备；暗影等材质效果与换身体模型分开。一个形态正常不等于其它都正常 |
| 装备与模型 | 皮肤合成槽/UV、头盔变体、头肩/左右手/背盾挂点 | 胸腿手套、头盔是否秃头/偏位、盾牌拔出/收起、坐姿/NPC对话/舞蹈。非标准UV不能让衣服画到脸上；保留Claude已验收叠加层，helper骨轨道须检查主M2与外部.anim基址，不能只看数值范围 |
| 预览 | 创建/选角/属性/幻化/外观多处真实模型加载入口 | 角色动作、双臂闪烁、绿罩、加载后姿势各测；不逐帧seek并重置动作混合；静态网格图不能冒充游戏动态预览 |
| 首登 | 三模式→选经典→介绍→开始冒险→移动/跳跃 | 必须首次完整不小退；IsVisible/alpha/尺寸正常仍可能屏幕坐标nil，显式ClearAllPoints/CENTER/尺寸恢复后确认有效坐标再ACK，不以超时强解锁代替修复 |
| **死亡与遗骨** | **活体→刚死可复活尸体→释放灵魂→复活后原地bones** | **男女分别实测，复活后应见遗骨而非占位方块；现场与观察者、重复死亡至少按本批目标抽测。只测倒地尸体不充分** |

## 遗骨方块的定位与补齐

1. 沿服务器Map::ConvertCorpseToBones核对实际对象是可复活尸体还是CORPSE_BONES。服务器复制race/sex等字段、清装备；不通过删除尸体、关遗骨或修改复活规则掩盖缺资源。重启后消失可能只是临时bones被清理，不证明修复。
2. 从当前实际ChrRaces读取**ClientFileString字段11**，不要拿显示名称、race枚举、ClientPrefix字段6或文件夹猜路径。本次36=REBORNSETHRAK、37=REBORNOGRE、39=REBORNKULTIRAN、49=Maghar，不能让下一族硬抄这些值。
3. 当前Wow.exe模板为`World\Generic\PassiveDoodads\DeathSkeletons\%s%sDeathSkeleton.mdx`。资源通常为同stem `.m2`，配套`00.skin`等LOD及显式BLP/外部ANIM。检查男女两套，即使暂锁单性别也登记另一性别边界。模板需按当前EXE复核，读不到不宣称已证实。
4. 遍历有效MPQ/语言目录与松散文件，按路径直接查询，不能只靠listfile。记录同路径优先级、读不到的文件和影响。BONES2A有64个可读当前MPQ直接查询，Patch-9/Housing锁定未读；部分listfile加密不妨碍已知路径直接hash查询，不能写“全部归档完整扫描”。
5. 优先找对应CoA同版本资源；没有时用已验证兼容遗骨模型，**明确不是该族专属骨骼**。蛇人不自动等于蛇形遗骨，双头食人魔兼容兽人遗骨不等于双头骨。不得改通用种族前缀来修遗骨，否则可能破坏已通过的头盔、外观/场景等；共享前缀也不能靠同一文件分出多族造型。
6. 仅新增准确遗骨路径；贴图放本阶段私有目录并重定向M2中的长度/偏移，保持原顶点、骨、材质、动画和skin。检查完整记录图、LOD索引、BLP解码、外部动画、模型与skin越界负例；原生lookup可共用完全相同小数组，校验器应区分合法别名与部分越界重叠，不能为了通过而改坏原生模型。
7. 用户导入已有目标MPQ并完整冷启，不能用小MPQ替换完整累计包。新增路径包通常不需要服务端/SQL/DLL；只有确有其它根因才另立范围。回滚按本包路径与output哈希删除新增项；后来合入别的内容时不可整包倒退。

## 证据与当前状态

- 旧BONES1A来源：000Ascendupdate/000Ascendupdate20260922/codexfix_202609220850_阶段BONES1A_新种族复活遗骨资源修复。它是旧35条种族表上的候选，不代表已覆盖后来新前缀或本次四族；没有给它补写全族实机通过。
- 已通过/发布的武器、弹药槽、首登I、背盾G、预览、头盔、图腾K1C证据：000Ascendupdate/000Ascendupdate20261108/release_RACERELEASE1B_20261108/publication.json。十职业建角底座仍按用户指示暂不发布。
- BONES2A：本次8M2/8skin/4BLP兼容遗骨候选；当前四族8模型路径在可读MPQ中缺失，补齐后静态和损坏负例通过，**用户已基本实测通过**，但未逐项提供完整矩阵。截图方块未抓对象GUID，不扩写额外对象级证据。
- CoA上游实际仓库已转为Conquest-of-AzerothCore/azerothcore-wotlk-coa；本次核对main=00ba053a91b878b0c48e8796d0ab535a2d769953的Corpse/Map/ObjectAccessor。旧jealous-sound路径代码API可重定向，但Issues搜索repo限定会422；先查询full_name再搜。DeathSkeleton定向搜索无结果，不等于证明上游永无相关修复；本次不移植无关尸体法术PR。


## 2026-11-08 BONES2A用户基本验收
用户原话“测试通过 可以推送了”。四新族兼容遗骨修复按基本使用通过记录，当前YJ20/20匹配冻结原ZIP；全部男女/四族/观察者/真人与机器人/重复死亡矩阵未逐项确认，不扩写。无活体模型、DBC、服务端、SQL、DLL改动，十职业建角底座不发布。Release：https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-bones2a-20261108；原ZIP SHA256 b3f14f8d75838ab047f4d58eb6124b5539437d26228edd98225301640410ed4c。原包待测文字保留为历史，此新记录更新状态；已装通过无需重装。


## 2026-11-08 RACEBATCH2A：暗落者十职业候选
候选未实机，不继承旧族验收。新增38前检查：同阵营共享位32可入，40联盟/巨魔8部落别名冲突单列，不能盲开下一ID。38仅Orcish109/669，亡灵5声望/属性，不能让共享牛头人位带入种族特长。原生十职业与界面索引分开；Hunter武器资格早于发装、AmmoFix已覆盖原生Hunter但新族仍待冷启实测。

本次实际抓到**M2/SKIN跨分区错配**：通用查询得到patch.MPQ血精灵遗骨M2的499顶点，却得到Patch-T的1469/1479索引SKIN。文件都存在仍会错！选择common-2.MPQ中男女成套资源并逐LOD验证索引/子网格/材质范围；新建REBORNDARKFALLEN遗骨路径、贴图私有，不改全局查询顺序或原生文件。不要以后机械固定common-2，必须按实际版本配对再检。

三张眼部BLP为较新BGRA编码3，转换DXT5编码2、保留alpha/mips并独立解码对照；当前DLL能转码不等于原生兼容。先检查完整M2轨道/外部ANIM/skin，再归因贴图。实机卡死不可单凭格式推断。

31安装文件、4CPP /Zs、实际DBC的C++资格夹具、3Lua片段、隔离MySQL守卫/幂等/冲突、274依赖、8身体SKIN和2套遗骨通过静态；完整链接、十职业男女/猎人移动射击/图腾/变身/NPC盾盔/死亡/首登仍待用户。工作证据000Ascendupdate/000Ascendupdate20261108/codexwork_RACEBATCH2A；旧四族CLASS1A仍不发布。


## 2026-11-09 RACEBATCH2B：入口和随机名漏项
用户截图“失落者”是LOSTONEALLIANCE，不是38暗落者REBORNDARKFALLEN。A虽然已加十职业Lua/CharBase，漏了RebornRacePreview的E列表入口，现有XML暗落者按钮和专属头像从未Show。**只验证资格函数不等于入口可达**：下次从实际可见按钮→真实token匹配→运行时index→RefreshRaceClassState→职业资格→建角完整核对。按钮列表、XML存在、图标存在三者必须一起检查，不能只在GetAvailableRaces有数据就写已开放。B追加E队列末尾，不移动旧图标、不把失落者替换成38。

随机名不得绑定“已开放职业”的白名单。未知预览族的原生GetRandomName可能空/重复；从E登记表独立提供名字池fallback，男女分池，先使用正常原生返回；付费服务和其他原生族不套未知兜底；名字可生成不等于服务器允许建角或名字唯一。不修改RaceUIKind来绕过资格！至少测空/nil/重复/正常原生、男女、连续点击、不支持族、付费服务和重排运行时index。B实际Lua片段1000次两族男女+真实Open回调通过，未实机。

ZIP：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261109\codexfix_20261109_阶段RACEBATCH2B_暗落者入口与新族随机名字.zip
SHA256：c2a2d5ea6b23ec0c7c513c9d4c05b63517889b89277671b1e31489f9376907a7。2个YB Lua，覆盖当前A累计后冷启；无需编译/SQL，原A冻结包保留。截图失落者仍未开放十职业；暗落者需用新增按钮。未提交推送。


## 2026-11-09 RACEPAIR3A：破碎者与失落者双族候选
用户授权一次一联盟一部落、直接开放经典十职业。本批40=联盟破碎者/COABroken，73=部落失落者/LostOneAlliance；token字样不代表实际阵营。38旧暗落者已用户取消，C撤入口继续保留；没有删除其角色/存档/已有代码。**候选未实机，未提交推送；旧四族十职业底座仍不发布。**

1. 先以实际按钮→token→真实ID/阵营→枚举index确认对象；40在主ChrRaces，73在dbc1-race14扩展。客户端主/扩展CharBaseInfo要一起处理，不能只改主表留下旧职业组合。73原扩展第67列offset756越过353字节字符串块：客户端保持原字段；服务端此未使用列归零并记录，不把整扩展表回盖主表。
2. 40与巨魔8跨阵营，不能移除RaceMgr拒绝或改真实身份。本批40走零mask身份路径；73与当前地精9同部落，mask256且容量MAX_RACES=74。职业模板按职业选择，语言/声望分开，不能继承共享位母族特长。36/37零mask、39位64、49位65536及原RaceMgr防护保留；其它物品/任务/PvP共享位隔离未全面验收。
3. 失落者男女均缺110 HoldRifle，原生fallback是Stand；兼容别名复用自身48 ReadyRifle，owner↔alias完整回环，保留原TRS/顶点/UV/贴图表/SKIN。不能只新增lookup而遗漏owner回链，也不声称造出全套新高清射击动作。20选定动画与实际key-owner/ANIM范围核对通过，游戏中的移动/起停仍待测。
4. 同一身体/飞行模型的所有序列不能套用“单序列遗骨”的内嵌轨道校验假设；未拥有/外置槽的offset0可能合法。按真正owner验证，避免为了校验误报而破坏动画。独立遗骨指针/skin损坏负例与活体检查各自保留。
5. 破碎者迅捷飞行现有M2贴图路径末尾FF，本批私有副本仅修为NUL；新增Display/Model1101400、复制4个SKIN与相对贴图，只有40/form27引用。原生所有族全局模型不改。依赖检查必须包含Display替换贴图相对于新M2目录的路径，不能只复制M2显式贴图。
6. 猎人技能/弹药槽/出生远程+弹药继续逐项检查；旧供体136个物品ID中80个当前不存在，三端120套模板清480处无效项，其它原物品/槽位保持。两族普通Hunter3使用现有AmmoFix，首登沿用当前已验收I版，分别登记指纹，不把旧族验收外推新族。
7. 4男女身体依赖、4兼容遗骨、8四元素映射、两族变身链闭合；图腾本批是德莱尼/兽人兼容资源，不冒称专属新设计。两预览头像原BGRA3→DXT5，保留alpha/7mips，图案不变。入口脚本期间发生B反向变化，逐行审阅后按用户撤38要求合并，更新input/backup/台账，不盲覆盖。

49安装文件；4CPP /Zs、实际DBC驱动C++资格夹具、Lua5.1语法/真实Open回调片段、40组合资格和120套装备对照、私有MySQL43379默认拒绝/幂等/部分重试/冲突与缺物品拒绝、28显示ID/401依赖/1307身体纹理引用、4遗骨和body/flight选定轨道离线通过。完整worldserver链接、40组合实机、四图腾组放/变身取消、射击/弹药槽、盾盔/服装与预览/坐姿NPC、复活遗骨仍待用户。本包没有执行生产SQL、运行端覆盖或改DLL/PB/Claude蛇人模型。

ZIP：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261109\codexfix_20261109_035405_阶段RACEPAIR3A_破碎者与失落者经典十职业联合候选.zip
SHA256：36bfddfa60542b24478c8e6fc557feef011bea9a91d70ccd5624c624fe48cb2b；5176509 bytes；137 ZIP成员。
安装、教学、40行测试表、逐文件原件/差异、守卫SQL、哈希见包内00入口与07教学。证据：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261109\codexwork_RACEPAIR3A。上游固定bc1204a4290e8fe9ebbc9ca619ecdeee5776d9c0，实际3CPP与定向查询见checks/upstream.json；上游直接移位不能替换当前身份/阵营仲裁。


## 2026-11-09 HUNTERSWAP1A：近战转远程的显示状态候选
用户新反例：36蛇人弓正常，枪/弩仍拿近战武器射弹；73失落者枪同样失败，弓/弩未测。37双头食人魔、兽人、40破碎者被反馈正常，但未提供全部性别/武器矩阵。不把RACEPAIR3A静态通过写成射击实机通过。

读取Claude SETHANIM2A-F、HUNTERSHEATH1A、SETHROLLBACK1A说明与协作事件：2D补Sheath、2E改序列头、2F补Bullet36均已实测无效，不重发这些实验；蛇人当前YJ是已接受2B（男f76a8144da…、女ff7ab9512a…），保持原字节/皮肤叠加层。

确定漏项：RACEPAIR3A两个失落者持枪M2已在YB，但YJ同名旧文件优先，当前读取仍为a234e329/14195be5，110依旧缺失。上批出包的基线校验只复核input，漏了“output实际能否胜出”的跨分区验证。以后不仅核源分区里的新文件，还要按有效优先级重查同路径。当前候选把这两个模型导入**已有YJ**；不新造更高分区，不删其它累计。

本次源码层新证据：旧HUNTERSHEATH1A只Force持武字节和远程虚拟格2，未Force主/副手0/1清空；当前Object::SetUInt32Value相等值不设更新位。提取实际Object、Player::SetSheath、旧/新Shot块和真实CombatHandler夹具，构造服务端0/0/枪与客户端预测剑/副手/0的分歧，旧代码留下近战显示，新代码强发两格0后模拟接收正确。**这证明代码层缺口，不证明真实客户端现场唯一根因。** 新增仅Hunter3+race36/73，原伤害/距离/弹药/冷却/仇恨/停射和回近战路径保留。两CPP /Zs通过，未完整worldserver链接。

失落者M2候选同时给49/106/110建立本体兼容链：49复用46、106复用105、110复用48，真实ID/owner双向回环及BWR/BWP事件同步。保留原几何/权重/法线/UV/贴图/挂点/SKIN，两模型11选定轨道、skin索引、alias死环与事件越界负例通过。未跨骨架搬数据，也不称新录制枪姿势。

按A/B两步游戏测试：先只装两CPP并由用户编译部署，测蛇人枪/弩、弓回归；再导B两个失落者M2到YJ冷启，测失落者枪并补弓/弩。把“手中武器是否换对”与“姿势是否自然”分别记录；站定/后退、近战→宠物接怪→拉远→自动射击→回近战/停射、男女和旁观者/重登均在表中待测。不要用原版不存在的GetSheathState宏；本批有DEBUG服务端值日志，但日志不等于最终渲染证据。

上游固定888aa871307628f8ae2c94df38863b8406faa38e；实际读PlayerStorage/Object两源码、#10629/#4884与PR10013/8428正文。后两Issue为猎巫15切换问题，不能据此盲套所有普通猎人或说上游有本批现成修复。正式远端fetch读回2b34eebadb8780b7e6d0554f5841093d4722a522；包以当前日常累计两CPP为input，不能直接整文件盖正式旧分支。

ZIP：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261109\codexfix_20261109_185602_阶段HUNTERSWAP1A_蛇人与失落者猎人枪弩切换候选.zip
SHA256：f49edc705e2a37ecabdad9e98a63af25fe89bacc20e7cad8308391ab8bd6dcfd；894158 bytes；37成员/4安装文件。
入口：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261109\codexfix_20261109_185602_阶段HUNTERSWAP1A_蛇人与失落者猎人枪弩切换候选\00_先看这里_分两步测试.md
工作证据：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261109\codexwork_HUNTERSWAP1A；逐文件input/output及原件见manifest/backup，包内教学、测试代码/日志、12行种族×性别×武器待测表齐全。

**候选未游戏实测，未完整链接/部署/生产SQL/推送。** 未改蛇人模型/skin/贴图、DBC、DLL、NPCBot/PB/家园/战场；不发布旧四族十职业底座。冻结包不修改；有新结果再出下一版。

## 2026-11-10 HUNTERSWAP1R1：实测失败与撤回模型候选
用户实测A+B失败：73失落者弓动作退步、从左手射弹；36蛇人仍拿近战武器发射枪弹。撤回HUNTERSWAP1A有效性预期，不把此前离线alias/事件/夹具检查作为实机成功。

当前两CPP、两个YJ失落者M2均精确等于失败候选output；实际运行Wow/worldserver路径正确，EXE存在HUNTERSWAP1A编译日志标记。不是“用户没装上”。只读指纹与运行路径见codexwork_HUNTERSWAP1R1/intake.json。

R1只交付两份改动前失落者M2（从冻结A原ZIP备份与解压备份双重逐字节核对）：男a234e3296ad942ee406800f5ee0966a004b6e36f7f55a76928c3b08ad9d6836c，女14195be5894910859cb08bc57844fd10e4aedcd142602c26fcf2dd05a51a10d2；导入现有YJ，同路径覆盖，先退出游戏。没有安装/部署，恢复弓的实际效果仍待测，枪弩不声称修复。保留A供取证，未改源码/蛇人叠加层/skin/BLP/DBC/SQL/DLL/PB。

用户已按临时root5射击再root2执行；当前Server.log等可读取且有正常新日志，但未检出HUNTERSWAP1A行。尚未取得现场sheath/virtual值，不能推断服务端值正确或客户端最终根因。命令返回成功也不证明记录分支运行，cs_server忽略SetLogLevel返回值。下一诊断先验证日志采集及实际命中分支，不重复发Force/alias盲改，不要求用户重证已经失败的现象。

包：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261110\codexfix_20261110_022023_阶段HUNTERSWAP1R1_仅恢复失落者改动前模型.zip
SHA256：bc2d7faece7223c844309f255acdc2a5208c33cf25b7b1c4f4d62559617809e4；8成员，2安装文件。ZIP成员全部读回相等。仅回退包未实机，不提交推送。原冻结包保持原字节。

