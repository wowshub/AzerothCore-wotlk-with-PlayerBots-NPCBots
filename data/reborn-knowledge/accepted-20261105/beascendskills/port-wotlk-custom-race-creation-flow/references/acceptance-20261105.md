# 2026-11-05 限定证据

- RACEALL1A：000Ascendupdate/000Ascendupdate20261103/codexfix_20261103_235039_阶段RACEALL1A_蛇人与双头食人魔今日累计测试总包.zip，SHA256 38cd15bbe2135a4d72a87aff542f7582876cdfe4701be4c9b16e1cb383552b85。用户确认两族男女能进入世界、模型正常；后续确认装备在包内、语言恢复，部分角色声望/技能正常。这不是所有出生/重登路径逐项通过。
- RACEUI1A_WHUI2A：000Ascendupdate/000Ascendupdate20261105/codexfix_20261105_阶段RACEUI1A_WHUI2A_创建状态与猎巫布局修复包.zip，SHA256 6b916e9f61fc09d8ad369297ade696113c0c43481f33fd62a01f834e0fc30378。用户原话“随机名字 测试通过”“现在界面也没有蓝白方块了”。仅这两项确认。
- A职业切换失败：用户“点到其他没有开发的新种族之后再点回蛇人，战士图标变成灰色”，需绕经旧种族才恢复；不能标A整包通过。
- RACEUI1B为当前新候选，事件末态和bool纹理同步，离线3200切换检查，游戏未测。未确认其为唯一根因。自动穿装也未修复。

正式客户端 D:/000rebornWOW/000RebornWOWHighForkPRO/beascendclient/newrebornWOWli20261031beAscend；版本路径随未来项目规则重新核对，不能永久当最新。案例race36/37与token REBORNSETHRAK/REBORNOGRE不代表可复制给下一个种族的空闲编号。

无本批新commit/tag/Release；旧包哈希不因新增验收记录改变。Patch9/Housing只读错误5未读取，背景资源缺失结论限已读归档。

## RACEUI1B用户否定 / C修正候选

用户：切新种族仍全亮，必须点性别才只亮战士；出现黄色长框。已查XML加载的RebornRacePreview.lua，实际Open绕过标准Race_OnClick，未刷新职业。B夹具未覆盖真实自绘入口，是入口覆盖失败，不能用3200次模拟掩盖。B误显示button.selection，XML为256×96列表高亮；不得在职业按钮上Show。独立职业环/文字也需同步禁用。
C配套2个Lua，在实际Open接桥，隐藏selection，已复现旧Open反例并跑1500真实Open路径替身检查，游戏未测。A名字/背景仍保留通过结论，B不晋升成功。

## 2026-11-05 RACEUI1C：真实自绘入口与职业状态已用户基本验收

用户原话：“现在 正常了 帮我把这次修复和之前的修复 一个一个 成功的修复做个commit 并推送吧 把这次 这个选择战士 其他职业灰色的 切换 成功修复写进skulls 为以后复用”。确认C修后的基本切换行为；不扩展为所有种族/付费服务/装备或种族技能专项通过。

可复用步骤：
1. 沿XML脚本加载、按钮SetScript追真实入口；本例上排自绘按钮走RebornRacePreview.lua的local Open，并不走CharacterRace_OnClick。不能只给标准入口做大量模拟。
2. Open切换种族/性别/模型后，显式调用同一职业刷新桥：按当前枚举重算职业→同步真实选中职业→同步UI。名单、原生选择、缓存、下一步、最终提交保持一致。旧种族沿原资格规则恢复；不强行全开，也不泄漏新种族“仅战士”限制。
3. 控件逐层同步：Enable/Disable、普通图与按下图去色、alpha、灰罩、文字、常驻职业环。巫医/武僧/猎巫是独立按钮，也要处理；返回旧种族先恢复样式，再由它原本的白名单计算资格。去色参数明确传bool，不靠遗漏参数保持/恢复旧状态。
4. 选中效果先查真实贴图用途。本例button.selection是XML中256×96的人物列表长条，不是职业圆环；隐藏它，保留现有CheckedTexture圆环。不要凭字段名Show一个未确认的图层。
5. 测试必须使用实际Open函数体，穿插旧种族其它职业→未开发种族→蛇人→旧种族→食人魔、男女与自定义返回。本例13组Lua5.1、1500次真实Open路径替身检查之后，又由用户确认C正常；这两种证据分开保存。

来源：D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261105/codexfix_20261105_阶段RACEUI1C_真实种族按钮刷新与长框修复.zip，SHA256 f8fe4e18d0929bad7ff09a47c37892b1de6620beba05f7c61f1a6001df722ad4。最终两Lua已与现场YB逐字节匹配。A随机名字/选角背景也已通过；A/B失败记录保留，不给失败中间包补写成功。Skill记录不等于已推送/Release，发布证据另列。
