# 2026-11-08 七项已验收修复分项发布

用户要求“把这几次的修复一个一个推送吧”，确认首登I、NPC对话背盾、猎人武器/自动射击、幻化预览都通过，图腾“完美 测试通过”、头盔通过；弹药槽“修复通过可以推送了”。用户另明确“四族十职业建角底座暂不发布”。自动审批曾要求再次确认公开目的地，用户已明确同意上述wowshub仓库/分支和公开Release，随后发布完成。

| 功能 | 完整提交 | Release | 资源附件SHA256 |
|---|---|---|---|
| 库尔男性头盔与KT依赖 | `27ade201d4f7afe64a85039e8d07fb483cca3ace` | [reborn-helmkt1a-20261108](https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-helmkt1a-20261108) | `02cf4ec0065a7e37c6d86ca06717a5e0a3c760609098df0659b55bdb643106dd` |
| 首登三模式/介绍页定位 | `9f0833f7b4d48c7d940ca2f74a572a859632cdf8` | [reborn-modegate1i-20261108](https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-modegate1i-20261108) | `5e085e4ee56480ea2b65836bca5de15b3e145a19c2834e741461b530a3da9f7a` |
| 幻化外观预览闪烁 | `235ca8631cbda99b5b52eb338dc745ef5af88d75` | [reborn-preview1f-20261108](https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-preview1f-20261108) | `09ed385c507bb029c57997555080fc33cecb1c931115f2d666b8aafd2fff0ff7` |
| 普通猎人原生弹药槽 | `556095cc33a2dcaa98ca549790dda7da1bb8d6aa` | [reborn-hunterammo1a-20261108](https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-hunterammo1a-20261108) | `87c5dd0f135056d83776940a07963f4bff0efb76233c9e2506713fbb68a8a019` |
| 保留Claude叠加层的蛇人背盾 | `2d02b70cc30e61c5d112f3c00582f263142240fe` | [reborn-sethrak-shield-g-20261108](https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-sethrak-shield-g-20261108) | `460643ee497261d01b1337bad4b0104932b65d98eabcd9c575d48cac6e0a1148` |
| 四族猎人弓枪弩/自动射击补缺 | `e84ef372f4390444d1e18277bafc127f98064659` | [reborn-hunter-ranged1c-20261108](https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-hunter-ranged1c-20261108) | `1df2bcc81e6dc323d29d189af16d48ce0de8f64d9611abae5ace9c9975dd84df` |
| 四族图腾最终造型/名字高度 | `b847488239a57324ae19295f0a27bd8c961a6fe4` | [reborn-racetotem1c-20261108](https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots/releases/tag/reborn-racetotem1c-20261108) | `0dcfc01a5580c67271230b0c21f213d7811ef7b2fa10060fe82dbd715c9554e0` |

## 成功与验证

每项独立commit、附注tag和非草稿Release；七个附件uploaded，大小和远端SHA256 digest逐项匹配，ZIP逐文件读回。保留Claude家园和男女装备层7612c6f祖先；PB gitlink保持e85232a489d0f54efccc96a8ec33b063e0a4794b。未改日常编译树、当前运行客户端或服务端，未执行生产SQL，未生成新EXE。

核心猎人补缺从已测RACECLASS1C提取：四真实ID判断替代未发布helper，循环相同，保留正式建角资格；两个CPP MSVC /Zs和补缺幂等夹具通过。图腾ObjectMgr只增加四族缺映射时回退，整CPP /Zs通过。没有重新正式整树完整链接或另做游戏验收。

图腾96资源=16M2+16skin+64BLP全部与已测YJ一致。六DBC仅从各自正式旧基线追加16私有记录，保持原行/字符串，排除CLASS1A飞行候选；重新整合表只做记录级验证，没有额外实机复测。本包02/03不能用来回盖当前用户已安装的CLASS1A累计表；当前通过者无需重装/重编译/重复SQL。各Release均有安装条件和回滚说明。

蛇人男G模型830671ad...保留Claude v8全部叠加数据，OVERLAY INTACT，UV2差异0、其它顶点差异0。当前YJ后来安装了Claude SETHANIM1A候选9e37a39b...，相对G只有5项动画lookup修改；本次不夹带该候选，也不回盖当前现场。单男M2附件不包含Claude skin/BLP/女性任何文件，前置仍为已安装的独立肤色图集和Claude男女v8。

## 失败、修正与待测边界

历史模式A/B/C/G/H首登或转场失败记录保留，不再称它们成功；最终I对显式坐标恢复进行自动化，用户不小退完整流程通过。可见/alpha/尺寸正常不代表具有屏幕坐标，隐藏等待页不得伪造可见ACK。旧背盾per-sequence键被Talk外部.anim基址解释，改全局恒定TRS后用户确认；不能用静态范围检查替代实际关键帧所属文件核对。

图腾旧生成器轨道/结构失败不能归咎为“不是BLP”；最终使用兼容原M2/skin和原BLP资源，完整引用闭包与Unit动画轨道核验。K1A过大、K1B名字仍高，最终K1C补name attachment18通过，不再反复盲调主体尺寸。归档发现解压目录的安装SQL守卫被改为1，最终附件从冻结原ZIP取回默认0，原解压目录不改。

弹药槽旧逻辑只接入自定义职业13/14/15和圣物，遗漏原生Hunter3/HUNTER。最终修复保留原生slot0/OnClick，nativeUpdate之后Show，保留穿脱/缓存/战斗队列。Zann库尔男初看未显示，用户随后截图并说“一会显示了”；按基本显示通过登记，冷启动仍观察到延迟，具体属于物品资料、事件还是面板初始化尚未唯一证明。不要据此删除WTF/全缓存，更不能把自动射击通过当弹药槽通过。今后每个新种族Hunter须同时核武器技能、技能法术、实际装备、匹配弹药/原生槽、穿脱/重登/冷启动和实际射击。

未逐项测试：全部职业/男女/装备与动画组合、全等级图腾/全部生命周期、PvP/机器人；冷启动弹药槽无延迟也未证明。四族十职业建角底座CLASS1A不发布；种族专属特性RACIALNEXT1A仍未实现，不与本次混淆。

## 小白理解与下一步

服务器决定角色能学什么/召唤哪个显示ID；客户端DBC把ID指向模型，M2再引用skin/BLP并提供名字挂点；人物面板弹药按钮由Lua显示。技能已能用、背包里有箭，并不能证明弹药按钮被初始化。发布拆开，是为了能明确知道每次改动和依赖，而不是用旧完整文件反盖新累计文件。

已验收且已经安装的现场继续用，无需重新安装这批归档。后续Claude射击动画候选独立测试并保留G与装备层；未来若发布CLASS1A需另获用户指示和独立验收，不自动带入。本轮正式发布源不等于用户全部累计源码；任何后续回盖先比较各自input/output哈希。
