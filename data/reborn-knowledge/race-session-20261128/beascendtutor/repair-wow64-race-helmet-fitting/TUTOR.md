# 头盔为什么会方块、错位、过小

这三种现象对应不同环节：资源没加载、挂点不合适、头盔尺寸不匹配。先恢复资源，再校准头部挂点，最后看尺寸。只让头盔从方块变成真实模型还不算完成。

HELM2B 用对应骨骼供体的头部到头顶差值修正坐标。HELM2C 在此基础上为维库人、单头食人魔男女分别设置头盔实例比例。头盔跟着动画头骨移动，不改角色体型或肩甲。

实现逐步理解：先判断种族/性别和头盔是否存在；确认模型已加载；比对骨骼数量和 head 索引；计算 crown；只遍历 ATTACH_HELM；给每个头盔设置绝对 frame/scale。因此多次刷新不会越变越大，其他种族不会套错参数。

参数不是通用常量。角色身高、头骨 pivot、头部实际大小并不等价；换人物模型或供体头盔后必须重新测量和实机看效果。双头食人魔的单头盔挂点也不能当作双头盔功能。

测试时分别查看选角、装备窗口、幻化预览、游戏世界，并装卸和转头。用户已确认食人魔、维库人本次尺寸正常；格里恩新报尺寸问题和虚灵预览白模仍待修。完整参数和证据见 [永久 Skill](../../beascendskills/repair-wow64-race-helmet-fitting/SKILL.md)。

编译教训：复制来的源码可能带旧时间戳，增量编译会误以为无需重编。检查真实编译日志和输出哈希，不以 build 返回成功证明改动进入 EXE。不要回退已合并的 Claude 家园更新。

2026-11-16 德拉金男女的反馈说明“有头盔”和“头盔合身”是两次验收：Hu兼容资源消除了所测款式的方块，但用户仍指出大小及穿脸问题。不要把男2.0、女0.90作为成功尺寸复用；男女实际为不同骨架。后续分轴适配仍须实机。证据见[限定反馈](../../beascendskills/repair-wow64-race-helmet-fitting/references/drakkin-resource-20261116.md)。

## 2026-11-16：有帽子与合头型是两件事
先解决资源路径方块，再按男女骨架调挂点和宽深高。海象头宽、鱼人男女不同，不能全种族套一个scale；重复刷新要绝对赋值。最终参数和边界见[参考](../../beascendskills/repair-wow64-race-helmet-fitting/references/final-fitting-20261116.md)。


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
用户确认之前修复“都测试差不多了”并授权commit/push，最终累计按基本通过记录，未扩写全职业/男女/动作矩阵。已失败的魔古早期脸图、STARTFIX1A漏inl及龙希尔1E保留失败。新族开工先用[端到端流程](../../beascendskills/port-wow64-playable-race-end-to-end/SKILL.md)及其失败台账/检查表；保留本Skill专项方法和旧边界。正式提交/资源状态看RACESESSION1_20261128。
