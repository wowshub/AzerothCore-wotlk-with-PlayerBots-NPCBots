---
name: repair-wow64-race-helmet-fitting
description: Repair WoW64 custom-race helmet missing-resource cubes, incorrect head attachments, and undersized helmets using verified model paths and per-sex skeleton profiles. Use for helmet fitting, not body texture or robe coverage faults.
---

# 自定义种族头盔适配

先固定当前累计客户端、MPQ 优先级与实际种族/性别/形态。遵守项目协作登记，保留对方最新累计改动。

## 分开诊断三个层次

1. 蓝白方块：查实际请求的头盔资源路径、种族/性别后缀及胜出的 MPQ。不要拿缩放掩盖缺资源，也不要以隐藏头盔作为修复。
2. 脖子、背后或双头中间挂载：核对人物模型 attachment 11、lookup、实际 head keybone 6、挂点所属骨骼及模型坐标系。对应性别供体的 head-to-crown 差值可参考；骨骼编号不能跨模型照搬。
3. 位置正确但嵌进头内：独立检查头盔实例比例。只调挂点坐标不会放大头盔；按真实种族、性别和骨骼指纹建立尺寸配置，禁止把人物整体放大来补偿。

## 实施约束

- M2 定点修复先校验整个输入 SHA256、记录范围与原值，只改确认的 attachment 坐标，保留其余字节。文件路径含 Female 不代表实际使用角色是女性。
- 运行时修复只操作 ATTACH_HELM 实例，在父模型加载且骨骼匹配时调用 SetAttachmentFrame；使用绝对尺寸，重复刷新不得累乘。不要改共享 mesh 或子模型世界矩阵。
- 头盔缩放和 crown 偏移要共同校准。无头盔、变形模型、未加载父模型、非目标族和肩甲应保持原行为。
- 双头模型需明确一个头盔挂在哪个头，单侧正确不等于实现两顶头盔。
- 供体路径修复、挂点修复、尺寸修复分别记录验收。选角、建角、装备窗口、幻化缩略图和世界人物是不同入口，不能凭一个入口宣称全部通过。

具体参数、失败经验与验收边界见 [HELM2B/C 记录](references/helm2bc-20261115.md)。配套教学位于项目 beascendtutor/repair-wow64-race-helmet-fitting/TUTOR.md。

2026-11-16 德拉金99男女所测头盔资源已显示，但尺寸仍被用户要求继续优化；只记录资源显示改善，见[限定反馈](references/drakkin-resource-20261116.md)。男2.0/女0.90不能收为通过的尺寸参数。

## 验证与累计编译

至少检查重复刷新、装卸、多款头盔、男女和转头动作。自动测试验证代码保护，不替代用户视觉验收。复制源码保留旧时间戳可能让增量编译跳过文件：核对日志里的实际编译项和最终 EXE 哈希。累计包中的家园等其他功能不继承头盔验收。

## 2026-11-16最终累计反馈

见[本轮方法与限定验收](references/final-fitting-20261116.md)。历史候选记录保留；本轮最终参数/生命周期覆盖此前候选，不把总体反馈扩成所有装备专项。


2026-11-17 NEUTRAL2A候选：20个有效性别按bone/vertex指纹测量头骨后代中央范围生成crown与绝对缩放，原attachment11缺失可先用已有合法socket接上头盔实例再SetAttachmentFrame，不能只在晚刷新对一个从未挂接的盔设坐标。无头盔、未加载、错指纹、重复刷新与武器不受影响有真实函数夹具；全款式/动作未实机。参数及资源缺口见当日codexwork_WOW64NEUTRAL2A/helmet-measurements.json和逐族表，不能继承旧族头盔已验收结论。


## 20261118 WOW64NEUTRAL3A 候选（未实机验收）
20指纹仍保留，本次按截图微调73/76/83/90/96/97/114/116的绝对crown与比例。所测角色只读存档均有头盔且playerFlags=0；另有首次AddHelm早于模型挂点就绪的缺盔路径，补真实附件缺失重试，不靠重穿。位置/尺寸/资源/时序分别诊断。夹具与Release通过；多款式/转头/跑跳贴合未实机，不能晋升验收。
来源：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261118\codexfix_20261118_001419_阶段WOW64NEUTRAL3A_新种族装备头盔加载与炉石学习完整修复；完整证据见checks与memory，实际出包日与工作目录日分开记录。


## 2026-11-18 NEUTRAL3A实机失败与NEUTRAL3B候选
# 3A失败复盘 / 3B候选

仅验证M2/SKIN几何和权重不能证明绘制安全。每个非零textureCount批次还要追colorIndex、materialIndex、textureCombo、coordCombo、weightCombo、transformCombo直到真正运行数组。纹理数量大于0不代表一定存在opacity track，65535不是所有字段通用的可直接解引用哨兵。新生常量轨道要有真实时间/关键帧，空track实例默认值0会造成不崩但全透明。

把真实Crash寄存器与反汇编、胜出MPQ及哈希并列：这次0+65535*12+8精确解释BFFFC，优先于继续猜网络/角色/模型加载速度。负例必须能拒绝旧错误和故意毒化的资源，旧校验器没有检查透明度链，3A通过不能继承。

头盔资源存在后再核父模型真实socket11。借一个socket然后只改m_attachmentId并不等于补了真实lookup，异步重载按ID重新解析会丢失。能定点补真实挂点时保留原骨和几何，只追加附件/lookup，独立备份和SHA守卫；不修改共享盔模型。

本次真实崩溃根因有指令级证据，修复资源/函数和编译已校验；尚未游戏实机，头盔精确适配、9族服装/动作仍待测。不把离线样例通过写成完整可玩。

来源：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261118\codexfix_20261118_024217_阶段WOW64NEUTRAL3B_多种族选角崩溃与邪兽人头盔累计修复；实际证据见checks/evidence，不能将旧3A离线通过作实机成功。


## 2026-11-18 NEUTRAL3C 稳定加载与外观候选（未实机）
# NEUTRAL3C 方法与反例（候选，未实机）

“打开建角/重新穿脱后有衣服”反证资源并非全部缺失。追选角Idle与world Prep两个真实入口：只给少数旧族每帧RenderPrep，会让新族首次异步衣物失败后缺少重试。必须驱动当前选中实例，保留非阻塞加载与实际就绪，不能固定sleep或清缓存掩盖。

缓存只记gear/fields不够：TextureCache元数据返回不等于mip可画。ItemsLoaded对已有info但缺mip可能不报整体加载失败；旧合成按mask跳过缺失层并缓存半套。当前登记的item层未就绪时保持pending，key含图层ID及ready位；等资源晚到重新合成。naked/纯几何无可画层是正常状态，不能无限pending。9私有层与102/110/101/108旧native路径要一起检查，不能只改新函数。

可用子模型也必须属于当前父模型、skin-parent仍在、贴图可绘制、目标几何可见。实际装备/字段变化要使绑定缓存失效。选角缓存alpha0必须与真实幽灵0.4分开；Centaur不在中立IsRace列表内，不能遗漏；Fenris是110萨特，Garuka是102女Centaur，依据真实身份而非截图腿数。

骷髅绿色袍摆是1302可选网格用固定type8，不只是色彩异常。增加对应装备层，再按实际geoset启闭；原裸骨与原父网格保持。龙人避尾只改披风顶点，先核全LOD及共享顶点，保留尾巴/骨/UV；不是物理布料，动作边界待测。

幻化不能继承NPC远景相机；小图按装备部位取景，头部需要实际helm attachment到达，不能用独立衣物子模型当作头盔就绪。动态人物从当前world model独立复制并重绑，强制人类/武器模型及非目标族保留原行为。反复应用用绝对取景，不能累乘。

新修头盔参数只限116男和90女，20有效槽的其他18不动；3B的opacity止崩和真attachment11保留。自动函数/资源校验与真实画面验收分别记录；本轮源码已编译，真实游戏仍待测。

来源：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261118\codexfix_20261118_062830_阶段WOW64NEUTRAL3C_衣物稳定加载与头盔披风幻化优化；证据见checks与源/资产哈希。用户仅证明衣物后来可显示、3B邪兽人帽子已出现，不能外推3B/C全验收。


## 2026-11-28 本窗口总体基本验收与新族总流程
用户确认之前修复“都测试差不多了”并授权commit/push，最终累计按基本通过记录，未扩写全职业/男女/动作矩阵。已失败的魔古早期脸图、STARTFIX1A漏inl及龙希尔1E保留失败。新族开工先用[端到端流程](../port-wow64-playable-race-end-to-end/SKILL.md)及其失败台账/检查表；保留本Skill专项方法和旧边界。正式提交/资源状态看RACESESSION1_20261128。


## 2026-11-28 Stormforged基本验收
用户确认联盟84本次移植完成；目录优先级、真实发型材质、服务端root/locale缺表、头盔及衣物披风指纹教训见[本次证据与验收边界](../port-wow64-playable-race-end-to-end/references/stormforged-20261128.md)。后续保留已安装BODY1A衣物层，未测试矩阵不扩大验收。
