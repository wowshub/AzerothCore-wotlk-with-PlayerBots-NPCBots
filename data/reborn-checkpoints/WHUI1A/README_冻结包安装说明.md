# WHUI1A 猎巫者创建页圆形图标（候选，未实机）

目标：武僧保持中间，巫医在左，猎巫者在右，三者同尺寸、同外环。猎巫者只显示原版CoA图标、名称与开发说明，不开放正式创建。

## 安装：只改客户端，不需要编译或SQL

1. 退出游戏，备份正式客户端Data里的Patch-YB.mpq；如果已有Patch-XB.mpq也先备份。交付目标只限beascendclient/newrebornWOWli20261031beAscend，不是旧客户端或Esteria试跑目录。
2. 按checks/input_output_manifest.json核对当前YB两文件输入SHA。等于输入可以导入；等于输出说明已装；两者都不等不要整文件覆盖，交回当前版本做增量合并。尤其不要在Claude更新累计包后再覆盖本包旧基线。
3. 将02_覆盖到客户端根目录/01_导入到Patch-YB.mpq里的Interface目录按原路径导入现有Patch-YB.mpq。两文件是CharacterCreate.lua、CharacterCreate.xml，它们在YB才能盖过旧XA创建页。
4. 本轮精确文件名扫描未发现Patch-XB.mpq。用MPQ工具新建Patch-XB.mpq，把02_覆盖到客户端根目录/02_导入到Patch-XB.mpq里的Interface目录按原路径导入。只有一个私有图集文件Reborn-WitchHunter-Classes.blp。若你安装前已经有XB，先核对用途归属，不能替换原包。
5. 保存并关闭MPQ编辑器，再启动客户端。要同时导入YB脚本与XB纹理，不能漏一边。无需清物品缓存：本批没改物品/DBC。

没有01游戏源码目录、03服务端目录、DBC、SQL、DLL或EXE，不交bat/ps1/patch，也不提供整份MPQ覆盖累计包。tools里的Python只是复盘工具，不是用户安装步骤。

## 实际变化

- YB Lua：新增CharacterCreate_PositionWitchHunterIcon；在现有PositionMonkButton中追加一次调用。沿用CharacterCreate_AscendClassSlotX(2)=+62，原巫医slot1=-62，武僧0不动；Y均为原MONK_CLASS_BUTTON_Y=4。
- YB XML：只增加一个CharCreateWitchHunterPreviewButton，继承原职业按钮模板；OnClick只SetChecked(0)，不触碰原来的选中职业；付费改种族/职业等服务页隐藏入口。
- 原CoA圆形图集来自官方20260930客户端patch-A.MPQ，逐字节复制到私有路径，不重新绘制、不替换现有共享职业图集。AtlasInfo原始class-round-witchhunter坐标为0.875/1/0.75/1，准确选取右下角猎巫者圆形格。
- 复用原42x42图标、48x48中性外环、52x52高亮；悬停名称与“移植开发中，暂未开放创建”。点击不会切换模型/职业，也不弹大预览框。

## 基线、来源与并行

基线是20261031正式客户端实际读取的YB文件，不是旧WDCRACE1包。输入Lua=653f854e…e056，XML=4c3759dc…f6dd，完整指纹见下。扫描同路径出现于X/XA/YB，最后已读版本YB。Patch-Housing.MPQ扫描时只读打开返回错误5，已记录；它排在已确认包含两文件的X/YB之前，不决定这两文件最终覆盖值。实际Glue页面加载仍须游戏测试，不将文件名扫描冒充引擎验证。

已fetch wowshub；此批不改游戏源码。社区CoA本轮HEAD=20689444fea23b1574b9500384f5624ffda7d82b，Issues/PR全部状态搜索“Witch Hunter icon”返回15条，未据此移植战斗逻辑；UI图集/坐标实际依据是本地官方20260930的AtlasInfo与BLP，不能称为社区最新UI实现。

Claude累计包1仍持有YB母包。本候选不修改母包或运行客户端，独立交精确增量/输入输出哈希；根目录交接_Claude_猎巫者WHUI1A_创建页共享文件注意.md已在开工和完成时登记。Claude后续重做包1必须从当前累计文件合入这两处Lua和一个XML节点，保留其全部新种族、巫医三族、头盔/家园累计变化。正式已交付的包不重写；组合改动有冲突须重新出包。

本批未分配本地classID、SpellID、物品ID。上游15只是下一阶段核对线索；图标按钮ID0不参加原生class枚举，不增加ChrClasses/CharBaseInfo，不调用GetAvailableClasses/GetAvailableRaces/SetSelectedClass包装。

## 测试结果与用户测试顺序

离线24项通过：实际Lua5.1语法、XML只新增一个节点、旧Lua移除新增段后等于基线、位置对称/尺寸/外环复用、付费页隐藏/返回恢复、实际OnClick/OnEnter/OnLeave脚本桩重放、图集透明圆角、BLP原件逐字节相同、运行YB仍未被改。首次XML比较失败来自缩进尾部空白差异，测试规范化空白后通过；生产XML改动的可逆字节核对在生成阶段已通过。

游戏显示、分辨率缩放、鼠标悬停与真实页面切换均未测；未部署、未执行生产SQL、未编译、未发布。离线脚本重放使用接口替身，不能证明WoW真实渲染已经成功。

用户验收：
1. 登录→创建角色。应看到“巫医—武僧—猎巫者”，三图标等间距、等大、同圆环，猎巫者无黑色方形底。
2. 悬停猎巫者应显示名称和开发说明；点击后当前选中职业、模型、种族和下一步资格不变，不触发创建。
3. 切换种族/性别/已有职业、返回再进入创建页，图标仍在武僧右侧；进入角色外观页后不额外残留图标。窗口/不同分辨率下与原两个图标同排。付费角色服务入口不显示此预览。
4. 巫医三族资格、武僧按钮、新种族入口及其模型、人类普通职业创建回归。无需新建一个“猎巫者”来验收本批。

## 回滚

当前YB两文件仍等于本包输出且无后续改动时，才把backup_原文件/导回Patch-YB.mpq两个原文件导回YB。若之后有Claude或其他功能更新，必须保留其改动、只撤本批增量，不能直接还原旧整表。

完成YB还原并进游戏正常后，再删除本批XB内唯一私有BLP；只有XB确认只含本批文件且无后续更新时才可移除整个XB。删除目录/包的操作由用户自己执行，不附删除脚本。不要先删XB而保留引用它的创建页脚本。

## 文件指纹

- Interface/GlueXML/CharacterCreate.lua：输入 653f854e00b2f91b83e91bb8df74424fe5b7596aeff66ed97fcee2f65616e056；输出 8b642d53bad071f0d43ca3d963028cae8c1aa592e7ac8929b51a2cd7c31fe211
- Interface/GlueXML/CharacterCreate.xml：输入 4c3759dc58b89c821acdeaa11385850da554d54c6e8fae7bf73241e36859f6dd；输出 2c93de6a700f9f444b2ae78e00f9ae7ae6321345ae924296c2b7a7ecaf8cc00d
- Interface/Glues/CharacterCreate/Reborn-WitchHunter-Classes.blp：输入 新增私有路径；输出 9c2620d39056b12e72078aee09361917bb35644ea2348e183d35856a18815a8e
