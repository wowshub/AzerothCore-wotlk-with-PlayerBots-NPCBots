---
name: port-coa-race-appearance-wxl
description: Bring CoA races into the WotLK creation page through wxl-extended-dbc additive tables and make their appearance options really work. Use when a new race shows white, green or wrong-model bodies, its colour/face/hair arrows or dice do nothing, it crashes on a customization arrow, or when choosing race ids, single-gender locks, backgrounds and icons.
---

# CoA 种族导入：外观选项真正生效

只管创建页外观。真正建角、出生、掩码看 [port-wotlk-custom-race-creation-flow](../port-wotlk-custom-race-creation-flow/SKILL.md)。本 Skill 全部结论来自创建页实测，未覆盖进入世界后的表现。先读项目 AGENTS、协作说明和相关交接。

## 1. 先看证据，不要先猜

| 现象 | 先看 |
|---|---|
| 白模 | 客户端根目录 `KvOutfit.log` 的 `fields rejected by ValidateExtended` |
| 崩溃、读文件失败 | `Errors\*.txt`：准确文件名、地址、寄存器 |
| 选项无效 | 模型贴图槽类型 + 该种族 CharSections 行 |

把"这一族有几行、模型槽类型、运行库内部编号"一次扫全，比一个个修快。不要先怀疑缓存：本案白模曾被误判为缓存和内存区问题，清缓存只是碰巧好转。

验收时确认用户说的"男/女"对应哪个模型。巫妖的巨魔造型在数据里是女性模型，造型不能代表性别，要看高亮按钮和模型路径。

## 2. 性别值

创建页只认 `SEX_MALE=2`、`SEX_FEMALE=3`。`SetSelectedSex`（Wow.exe 0x4E1A60）比对表 `(2,3,1)`：传 0 被忽略，性别沿用上一个状态，表现为时好时坏；传 1 设成无性别，表现为串模（女妖显示泰坦）。锁定单性别必须传常量。

单性别种族仍要备齐另一性别的行，见第 6 节。

## 3. 运行库 EsteriaAppearance.dll

现场 DLL 是 CoA 1.9.2，不认识 1.9.9 新增种族。它把 DBC 编号映射成内部编号（函数 0x100287C0，范围 21~112）：

- 83 豺狼人→63，97 沙伯龙→64，98 龙人→70，90 女妖→77，106 螳螂人→75，109 虚灵→76，112 赫猿→73。这些走 `Esteria<族>.bin`，贴图槽 11/12/13 由运行库绑定，用**原版 M2**，不要改槽。
- 校验（0x1002BF00）失败就放弃绑定，槽空即白。63/64/69/70 的女性必被拒。
- **新种族选编号要避开映射。** 66、69、70 曾分别被当成高山牛头人、土灵、哈拉尼尔逻辑处理；换到 114~117 后解决。基础表可能残留旧行（race 66 有 1408 行牛头人数据），也是换号的理由。
- 运行库的选项上限可能小于它自己的数据。沙伯龙表（文件偏移 0x54E54，每项 field/count/factor）脸 1、发型 1，而 `.bin` 用到 10 和 3；改这 2 个字节并恢复完整行后，选项全部生效。改前先比对 `.bin` 的选项最大值，并保留原 DLL。

## 4. 不被运行库接管的种族：选贴图通路

RACE14 那批曾把贴图写死成类型 0，所以箭头切到了下一行但看不出变化。按下表改模型贴图槽，并让 CharSections 第 0 类行提供贴图。

| 槽类型 | 取贴图 | 特点 |
|---|---|---|
| 8 直贴 | 第 0 类行 tex2 | 整张加载，保留透明和高清。**优先用** |
| 1 皮肤合成 | 第 0 类行 tex1 | 丢透明，只接受调色板格式、最大 512 宽，且覆盖脸和内衣区域 |
| 6 头发 | 第 3 类行 tex1（发型+发色） | 可让护甲层跟发色走（泰坦男） |

- 只有一层：走类型 8，第 0 类 tex2 = tex1，贴图保持原版。
- 两层（身体+护甲）：先核对UV是否兼容人形皮肤合成。仅兼容时才考虑镂空多的一层走8、另一层走1；蛇人等非人形UV不可照套，type1可能将装备画到脸上，须保留独立图集并另做装备适配。
- 一个模型每种类型只留一个槽。多个部位共用时改 texture lookup 指向同一槽。骷髅用两个类型 1 槽时出现亮绿色；全身改走类型 8 后解决，确切原因未查明。
- 高清 NPC 模型与其他模型共路径时，复制到新路径再改（.m2/.skin/.anim），不影响 NPC，并把 CreatureModelData 指向副本。自带贴图只有一张时可调色生成多种肤色。

## 5. 皮肤合成的覆盖层必须烘焙

合成时脸和内衣区域被整块覆盖，透明不起作用。行为空时贴上别族默认贴图（小腿、肚子上的兽人脸）；用未压缩透明图显示绿色；用调色板透明图显示杂色。生物模型贴图是整张展开的，这些区域可能对应任何部位。

**解法：把合成层贴图的这些区域裁下来，做成对应行的贴图**，贴回去就和原来相同（512 布局）：

| 用途 | 区域 x,y,w,h |
|---|---|
| 第 1 类 tex1 脸下 | 0,384,256,128 |
| 第 1 类 tex2 脸上 | 0,320,256,64 |
| 第 4 类 tex1 内衣下 | 256,192,256,128 |
| 第 4 类 tex2 内衣上 | 256,0,256,128 |

按行的颜色编号对应该颜色的合成层贴图，全部用不透明调色板格式。只走类型 8 的模型不需要烘焙。

## 6. 数据完整性

- **不要截断 CharSections。** 格鲁姆胡须和头发被截成 60 行，留下空洞：0x004EBFF7 读 0x1C 崩溃。
- 第 0 类有行、第 4 类没有：0x004EA77F 读 0x10 崩溃（骷髅女性）。第 0 类也没有则只白不崩。
- 选项在但没变化时，查 `CharHairGeosets`、`CharacterFacialHairStyles`。格鲁姆模型有部件 102~107 和发型部件，CoA 两张表却没有行；补行后才真正变化。对应顺序是自行排的，不是 CoA 设定。
- `CharacterFacialHairStyles` 行数变化必须同步 gt-index 的 `.wxlidx`（连续编号，注意不撞下一文件的起点）。
- 追加文件 `*.dbc1-<项目>` 按首字段合并，已验证蛇人可用同编号覆盖基础行，不用发整张基础表。
- 新 classID 对：缺 CharBaseInfo 会崩，照抄同类种族的 12 对。

## 7. 资源格式与路径

- 512 宽的未压缩 BGRA（BLP 编码 3）作皮肤贴图会读取失败或崩溃（Failed to read，0x008686C6）。全部改调色板（编码 1）。256x128 的未压缩小图没有读取失败，但进合成同样显示绿色。
- 不要发和基础客户端同路径的 M2/skin/anim，版本不一致会碎面并报内存错误；旧贴图盖住高清贴图同样会错位（骷髅）。
- 模型资源放 Patch-YJ 追加；读 MPQ 要排除 `Data\back` 里的旧副本。
- Bash heredoc 写中文会变编码，脚本用文件工具写。

## 8. 背景、图标、按钮

- `SetBackgroundModel` 联盟表只认 1~11，部落表只认 12~21，对不上退回默认。预览种族按背景编号选表，否则滚轮前后不一致。
- 赞达拉、夜之子、龙希尔有专用函数，用 `zanda`、`night`、`drac` 标记走专用背景。
- 预览按钮必须是 XML 里已有的 `Reborn<k>PreviewButton`，可复用闲置按钮。位置用 side/slot 固定，新增往外加。
- 图标要互不相同。没有现成图时可用模型和贴图渲染头像；战利品头像类图标不适合。

## 9. 验收与状态

用户在 2026-11-06 实测通过的范围与未覆盖项见 [验收边界](references/acceptance-20261106.md)。教学：[TUTOR.md](../../beascendtutor/port-coa-race-appearance-wxl/TUTOR.md)。

## 2026-11-08 蛇人变形退出反例

用户报告蛇人男女退出幽灵狼后脸部出现装备纹理。RACECLASS1B只重建动态替换索引，用户随后确认创建预览也直接异常，判定失败。旧索引不一致只是结构证据，不能据此认定恢复正确。对非人形UV的模型，type1会引入平面衣服合成，必须测试穿装和变形退出。实际高优先级模型位于YJ，不能用YB旧全显式版覆盖已验收的V53六肤色。RACECLASS1D独立图集/UV方案仍待实机，关闭蛇皮平面衣服合成的取舍须向用户说明。来源见20261108交接，不登记为成功配方。


## 2026-11-08 RACECOMBO1A有限改善与1B候选
用户后续明确：此前蛇人面部正常、当前幽灵狼恢复不再脸丑/装备贴脸。只将独立六色图集+关闭type1记为本次基本改善；不覆盖全性别肤色装备矩阵。非人形UV不能套“两层必有type1”，有两层也先检查人形合成区域是否对应脸部；普通胸甲裤子贴皮关闭是明确限制，完整装备显示需另适配UV。
1B选角私有经典场景、男盾/40543盔挂点、四LOD臂部重复绘制去重均候选。男臂装饰保留一款常驻、备用UV样式不切换，六肤色不改；不能声称只是纸娃娃变化或全装备适配。女结构不同不套男挂点。详见当日RACECOMBO1B交接与包，所有1B游戏项待测。



## 2026-11-08 RACECOMBO1B用户反馈收窄与1C候选
用户确认选角帽盔和持盾位置大体通过、绿色大面消失；随后补图游戏内收在背后的盾仍错位，因此背盾不能登记通过。脸部与幽灵狼恢复基本改善保留，普通人形装备平面合成仍关闭。1C只给男背盾新增专用helper索引158（第159根骨），parent15，Z+90，原158骨记录、头盔11/持盾0/背武器12与UV/skin保留。此为候选，不能从坐标计算声称游戏已贴合；女蛇不套男值。



## 2026-11-08 RACECOMBO1D：蛇人图腾基本通过，背盾对话放大修正候选
用户C蛇人图腾“不崩溃了 太帅了”，只记蛇人本次基本使用；另三族/全技能/PvP与模式介绍本轮未反馈。C背盾对NPC说话时巨大、结束恢复，失败。原因证据：C helper158使用global=-1的83主M2关键帧，Talk54/ID60 flags0x281无0x20，客户端按外部.anim基址解释；范围检查不能替代动画取文件检查。D仅helper158改为全局恒定T0/R原Z90/S1（复用已有global0），保留其它原字节/原骨/挂点/图腾97项；83路径与矩阵检查通过，游戏对话待测。不得清所有外部动画标志强塞M2，不要把外部槽强解主文件得出的垃圾数认作原骨损坏。原全局表历史布局保留，未全面修。工作codexwork_RACECOMBO1D，交付仍候选，原C包不改。



## 2026-11-08 RACECOMBO1E/F累计候选：C模式倒退确认
用户新库尔女Beatrix三模式首登也丢失，要多次小退才到介绍；双头食人魔能选经典但介绍仍丢。C真实缓存CRC3362226416且完整minified夹具通过，不是旧缓存/未装，必须把C模式记失败。E改普通RebornModeGate插件预载（RequiredDeps AIO_Client），动态脚本仅装载小桩，不改AIO库；本地禁用等待页、可见选择ACK、低频持续恢复、权威完成状态、迟到pending保护。45s延迟/完整按钮链离线通过，真实首登仍待测，不能据此声称修好。角色新SavedVariables诊断与/rebornmode可查状态，不强解锁/清模式记录。
用户库尔女40543光头：39 ClientPrefix仍Hu，而现成KT女盔范围更符合头部；F只39字段6改KT，927基础型号男女资源及skin现存，29个缺KT但有Hu的变体复制兼容，其余49原Hu也未找到列缺口，不宣称全头盔覆盖。四族玩家Wardrobe预览从每帧seek15/0改一次站立，保留旧族/武器预览；180帧/异步加载夹具通过，实际闪烁仍待测。D背盾固定轨道原输出累计，只有男helper变动。
C蛇人图腾基本不崩且外观满意保留，库尔游戏动态图与旧静态图不同因为未套待机骨变换/粒子；静态网格不能代替成品游戏形态。97图腾资源本包不改。Claude HOUSE20261108已发布，SETHRAK-ARMOR新路径UV试验独占，本包不带其内容。

## 装备显示（2026-11-08）

新种族身体装备（胸甲/腿甲/手套）画不上去、或打开衣服合成盖脸时，用 [overlay-armor-on-nonstandard-uv-race-models](../overlay-armor-on-nonstandard-uv-race-models/SKILL.md)：类型 1 叠加层 + 第二套 UV 左右镜像 + 烘焙底图，蛇人男女 v8 用户已确认。


## 2026-11-08 RACECOMBO1G：Claude男女v8基线与背盾合并候选
用户确认Claude男女v8装备层已通过，指定Codex从现场v8模型起步。现场男性1d60976f096f81e3cd3af6819789ad64f00b9e641bbe2e9803843f87bfa4893d及70项Claude资源核对一致；G只改男性helper158固定全局TRS，60字节旧轨道头+末尾追加，所有贴图/查找/替换/顶点UV2和其它原字节不变。guard OVERLAY INTACT，UV2差异0、其它顶点差异0，损坏反例被拒绝；83动作取址/矩阵离线通过。累计E其它66项输出不变并重新核对当前客户端/服务端/源码；新整合的坐下起身+NPC对话/盾牌位置、模式、头盔、预览游戏待测，不继承v8验收。旧C/D/E男性M2不得再覆盖。没有男女skin/底图/女性资源、图腾/SQL/DLL/C++改动，不部署不发布。

交接：D:\000rebornWOW\000RebornWOWHighForkPRO\交接_Codex给Claude_RACECOMBO1G_v8叠加层完整与背盾累计候选_20261108.md

## 2026-11-08 RACETOTEMK1A：库尔德莱尼借用未通过，海潮祭柱候选
用户认可蛇人/双头/玛格汉三族图腾造型；只蛇人先前基本不崩有确认，不扩大另三族全技能稳定性。库尔截图仍是C高清draeneitotem，G/H没换，用户不认可专属性。K改用CoA patch-WC2的8du_seapriest_totem01，10原BLP保留；原场景物件补Unit动画lookup与Stand/Spawn/Death、固定元素乘色，原骨/顶点/UV/倍率不变。18资源仅39私有路径，无DBC/SQL/Lua/DLL，ID61108～61111不变；其它三族24M2/skin现场等于C。完整记录图/mip/内嵌取址及ZIP通过，实际外形尺寸/生命周期/防卡死仍待测；不将静态主体图当成品游戏截图。原源最大512，不说AI新绘制高清纹理或官方库尔原生图腾。
交接：D:\000rebornWOW\000RebornWOWHighForkPRO\交接_Codex_RACETOTEMK1A_库尔德莱尼借用替换海潮祭柱候选_20261108.md

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


## 2026-11-08 RACERELEASE1B：外观组件分项验收发布
用户确认背盾NPC对话不再放大、预览不再双臂闪烁，头盔与最终四族图腾通过。G以Claude v8为底，helper158恒定global0 TRS避免Talk外部.anim错误基址；OVERLAY INTACT、UV2和其它顶点差异均0。只带男性一M2，不带Claude skin/底图/女性。当前后续SETHANIM1A仅5项动画lookup候选，不随本次发布；不可用G反盖后续候选。
图腾16M2/16skin/64BLP闭包匹配当前YJ；库尔用海潮祭柱原资源，scale0.60，最终name attachment18解决悬字。K1B边界改动单独没有解决名字；原始静态概念/网格图不代表游戏动态结果。六表各自正式基线仅追加16图腾记录，不带暂缓的CLASS1A飞行记录。已测当前累计表不可整表反盖。
HELMKT1A=27ade201d4f7afe64a85039e8d07fb483cca3ace；PREVIEW1F=235ca8631cbda99b5b52eb338dc745ef5af88d75；SETHSHIELD1G=2d02b70cc30e61c5d112f3c00582f263142240fe；RACETOTEM1C=b847488239a57324ae19295f0a27bd8c961a6fe4。对应tag/附件全哈希见当日release_RACERELEASE1B_20261108/publication.json。未逐项全装备/动画/男女/PvP，不扩大验收。


## 复活后遗骨占位方块（2026-11-08）
活体/装备正常不等于bones资源完整。死亡遗骨按ClientFileString与性别构造DeathSkeleton路径，不能改活体模型或ClientPrefix来绕过。参见[新种族回归与遗骨专节](../port-wotlk-custom-race-creation-flow/references/new-race-regression-checklist-20261108.md)。BONES2A补36/37/39/49共8套兼容遗骨及依赖，实机待测，已过Claude装备层/射击动作和Codex头盔/背盾不改。


## 2026-11-08 BONES2A用户基本验收
用户原话“测试通过 可以推送了”。四新族兼容遗骨修复按基本使用通过记录，当前YJ20/20匹配冻结原ZIP；全部男女/四族/观察者/真人与机器人/重复死亡矩阵未逐项确认，不扩写。无活体模型、DBC、服务端、SQL、DLL改动，十职业建角底座不发布。Release：https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-bones2a-20261108；原ZIP SHA256 b3f14f8d75838ab047f4d58eb6124b5539437d26228edd98225301640410ed4c。原包待测文字保留为历史，此新记录更新状态；已装通过无需重装。


## 2026-11-08 RACEBATCH2A：暗落者十职业候选
新增族先填../port-wotlk-custom-race-creation-flow/references/new-race-regression-checklist-20261108.md；本次补充了遗骨M2与SKIN跨MPQ错配（499/1469索引）及较新眼部BLP编码3转DXT5的实际例子。文件存在不代表成套，逐LOD索引与轨道验证；本批38十职业尚未实机，40阵营共享位冲突待另批；详见该参考及当日codexwork_RACEBATCH2A/delivery.json。旧四族底座不发布。


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


## 2026-11-11 WOW64PORT1B：64位捐赠ID冲突候选（未实机）
当前20=NorthrendSkeleton/Ni联盟DH，却被Vulpera20接管合成；49=Maghar被Earthen节索引重写；50/51与Haranir也不同身份。不能仅按数字进入Donor外观处理，需核对真实ChrRaces token/模型。候选保护这4个已确认身份，保留其真实ID与CharSections路径，不替换稳定模型/贴图；其它冲突ID仍需逐项审计。当前predicate/编译通过、脸部画面未实机，不写为成功方法。DK透明已由用户反馈恢复，未证明MPQEditor是唯一原因。
来源：[WOW64PORT1B交接](../../交接_Codex_WOW64PORT1B_Online预览理发与外观身份候选_20261111.md)。


## 2026-11-13 机械侏儒穿装缺腿：E基本实机通过
用户确认男女穿装腿部问题解决，四文件实装读回匹配E；仅本次基本使用通过。先查可选SKIN有实际三角面，再查目录选择之后的装备隐藏，不能把机械腿映入普通靴子501组。当前修复恢复30/31独立组并同步内嵌几何目录；保留C眼镜和D补面。详细方法、失败边界和原包见[机械肢体与装备反例](references/mechagnome-geometry-equipment-20261113.md)。顶部错字仍未修，全装备/动作/重登矩阵未扩大验收。


## 2026-11-14：多族同时白模先查诊断开关
本次EsteriaOff.txt遗留关闭原生外观，机械E四文件未变；仅停用开关并冷启动，用户确认全部恢复。按[开关事故与恢复证据](references/diagnostic-off-flag-20261114.md)和项目开关清单排查，不能先清缓存或整包回盖。静态缓存开关需完全退出重启；测试后本轮核对撤销。

## 2026-11-15 头盔专项
头盔方块、挂点或尺寸异常参见 [专用 Skill](../repair-wow64-race-helmet-fitting/SKILL.md)，不要把本次维库/食人魔验收推广到所有种族。

2026-11-16 WoW64 JOY止卡死获得限定反馈，但严格alias校验产生多族拒载回归；必须先扫全部当前男女模型。CENTAUR2B尚待实机，不作为成功配方：[限定反馈与反例](references/wow64-alias-regression-20261116.md)。

2026-11-16后续：CENTAUR2B各族显示恢复及半马披风白块获用户限定通过；入场碎片仍未通过。服装网格type2需从装备披风记录直接加载，不能从没有type2槽的身体复制。详见上述alias-regression参考的后续反馈。

## 2026-11-16已验收累计的分层入口

动画卡死/多族拒载使用[动画别名Skill](../repair-wow64-animation-alias-streaming/SKILL.md)；选角碎片/预览白模使用[模型生命周期Skill](../repair-wow64-model-preview-lifecycle/SKILL.md)；头盔与身体装备仍更新各自原Skill。JOY严格拒载失败版本不可复用。最终用户确认白模解决；全款式/全动作矩阵不继承。
