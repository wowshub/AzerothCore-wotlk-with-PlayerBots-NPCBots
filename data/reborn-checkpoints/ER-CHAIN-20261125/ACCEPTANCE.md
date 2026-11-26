# ER-CHAIN-20261125：流放者之岛部落任务链(59926–59985)源码归档

用户原话(2026-11-25)："哇这次这个任务链就结束啦 先commit 并推送到远端吧"。

## 验收范围(按实际状态)

| 部分 | 状态 |
|---|---|
| 整条部落线走到 59985 并结束 | 用户总体确认"任务链结束" |
| 船上任务链、海滩、营地、飞行侦察、篝火光标、急救包、缩放器 | 此前逐项实测通过(11-23/11-24) |
| 59942 载具、59943–59947 鹰身人图腾 | 11-25 实测通过 |
| 暗槌外圈 59975–59981 | 11-25 用户确认测试通过 |
| 分支任务 56839、54933 | "这几个任务 好棒啊 都可以了 通过 测试" |
| 深坑 59948/59949、副本内部三头目(DARK3A/3D)、落石堵门(DARK3E)、59985 修复(DARK3F) | 已装；随整链结束，没有逐项单独确认 |
| 巨熊模型与地图图标(BEAR1A)、vmaps/mmaps(VMAP12175A) | 已装服务端/试装客户端；用户未单独确认效果 |
| 岛上复活点(GY1A) | 用户未反馈；本次未核对是否已执行 |
| 食人魔变身(DARK1B) | **发布时服务端实装的 Dark1A.lua 仍是 DARK1A V1**；DARK1B 版放在 lua_candidates_not_installed，按候选对待 |

不外推：联盟线、多人/组队、全部职业、异常中断与长期压力。发布时未重新编译、未执行生产 SQL、未做实机复测。

## world SQL 执行顺序

按序号执行；执行前停 worldserver，执行后重启。**不要在后面阶段之后重跑前面的阶段**(会覆盖后续改动)。DARK3C V1(列不存在)与续接包 DARKFIX1A 不收录。

| 序号 | 阶段 | 文件(data/customfixsql/world/exiles-reach/) | 备注 |
|---|---|---|---|
| 1 | SHIP2C_V1 | 20261123_01_ship2c_v1_ship2b_horde_ship_quests.sql |  |
| 2 | MAP12S_V3 | 20261123_02_map12s_v3_map12s_graveyard_spirit_healer.sql |  |
| 3 | BEACH1A_V3 | 20261123_03_beach1a_v3_beach1a_quests.sql |  |
| 4 | BEACH1B_V1 | 20261123_04_beach1b_v1_beach1b_quests.sql |  |
| 5 | BEACH1C_V2 | 20261123_05_beach1c_v2_beach1c_quests.sql |  |
| 6 | BOAR1A_V2 | 20261123_06_boar1a_v2_boar1a_wandering_boar_display.sql |  |
| 7 | ITEMICON1A_V3 | 20261123_07_itemicon1a_v3_itemicon1a_first_aid_kit.sql |  |
| 8 | ITEMICON1B_V1 | 20261123_08_itemicon1b_v1_itemicon1b_resizer.sql |  |
| 9 | QPOI1A_V1 | 20261123_09_qpoi1a_v1_qpoi1a_island_quests.sql |  |
| 10 | FIRSTAID1A_V1 | 20261123_firstaid1a_item_746.sql | 仓库已有(同内容) |
| 11 | CAMP1A_V1 | 20261123_11_camp1a_v1_camp1a_campfire.sql |  |
| 12 | CAMP1A_V2 | 20261123_12_camp1a_v2_camp1a_v2_campfire.sql |  |
| 13 | CAMP1A_V3 | 20261123_camp1a_v3_campfire_cast_cursor.sql | 仓库已有(同内容) |
| 14 | BOOST1A_V1 | 20261123_boost1a_mount_creature.sql | 仓库已有(同内容) |
| 15 | BOOST1A_V2 | 20261123_15_boost1a_v2_boost1a_v2_mount22719.sql |  |
| 16 | BOOST2A_V1 | 20261124_boost2a_mount_model28830.sql | 仓库已有(同内容) |
| 17 | SIZER1A_V4 | 20261124_sizer1a_v4_item9178051.sql | 仓库已有(同内容) |
| 18 | SIZER1B_V2 | 20261124_sizer1b_displayid90551.sql | 仓库已有(同内容) |
| 19 | VEH1A_V1 | 20261125_19_veh1a_v1_veh1a_v1_gunship.sql |  |
| 20 | HARPY1A_V1 | 20261125_20_harpy1a_v1_harpy1a_quests.sql |  |
| 21 | HARPY1B_V1 | 20261125_21_harpy1b_v1_harpy1b_poi.sql |  |
| 22 | HARPY1C_V1 | 20261125_22_harpy1c_v1_harpy1c_flames.sql |  |
| 23 | HARPY1C_V2 | 20261125_23_harpy1c_v2_harpy1c_v2.sql |  |
| 24 | HARPY1C_V3 | 20261125_24_harpy1c_v3_harpy1c_v3.sql |  |
| 25 | HARPY1C_V4 | 20261125_25_harpy1c_v4_harpy1c_v4.sql |  |
| 26 | PIT1A_V1 | 20261125_26_pit1a_v1_pit1a_quests.sql |  |
| 27 | PIT1B_V1 | 20261125_27_pit1b_v1_pit1b.sql |  |
| 28 | PIT1D_V1 | 20261125_28_pit1d_v1_pit1d.sql |  |
| 29 | GY1A_V1 | 20261125_29_gy1a_v1_gy1a_graveyards.sql |  |
| 30 | DARK1A_V1 | 20261125_30_dark1a_v1_dark1a.sql |  |
| 31 | BRANCH1A_V1 | 20261125_31_branch1a_v1_branch1a.sql |  |
| 32 | DARK2A_V1 | 20261125_32_dark2a_v1_dark2a.sql |  |
| 33 | DARK2B_V1 | 20261125_33_dark2b_v1_dark2b.sql |  |
| 34 | DARK3A_V1 | 20261125_34_dark3a_v1_dark3a.sql |  |
| 35 | DARK3C_V2 | 20261125_35_dark3c_v2_dark3c_v2.sql |  |
| 36 | BEAR1A_V1 | 20261125_36_bear1a_v1_bear1a.sql |  |
| 37 | VMAP12175A_V1 | 20261125_37_vmap12175a_v1_vmap12175a_restore_ground_movement.sql |  |
| 38 | DARK3D_V1 | 20261125_38_dark3d_v1_dark3d.sql |  |
| 39 | DARK3E_V1 | 20261125_39_dark3e_v1_dark3e.sql |  |
| 40 | DARK3F_V1 | 20261125_40_dark3f_v1_dark3f.sql |  |

## 服务端 Lua(与发布时实装内容一致；入库时换行统一为 LF，下表 SHA256 是实装文件原字节)

| 文件 | SHA256 |
|---|---|
| ShipCrash.lua | b5c0ee953378d178cd2665a56c24fe5f539463c2e8739637fb50f1a50da22540 |
| ShipQuests.lua | 988e65a7d9533143b1760161569c5bdcfec95ee91faf845acc3550270eb6e68b |
| ShipRespawn.lua | fd4005d725c919d12c181bcb1996e62705a85b93aa315f4b890e12d6982f00e9 |
| Beach1A.lua | 9036c6f2e365eee3fe2eaa22d4e1fdb9152c82d1da3fc8c9f756ce87a24b2b3d |
| Beach1B.lua | 860bf51cecf71154f36f839243c14a729a203b971d8f91d9753b7ecf1ae382b7 |
| Beach1C.lua | 49620cec7cc09f2313a78f4d1306634b1f68615d6c0b72870ea1ffa10a2a357e |
| RebornQuestMap.lua | 92763ea08ab79e00dc3dcfd007a62ca57f18a5ae1c37113c4b0b8c72e7b41def |
| Veh1A.lua | 9217c301440416f3f94975dc493f63d5c042123acae8b17563a7d4b46a7a6650 |
| Harpy1C.lua | 631f6c85d76fc3ffba7433ee9a74ec37da556f6531dc79dec1a00336dc0e83f0 |
| Pit1A.lua | 2a4b0e003ca7e70b0d49300c81d04217742fc5a4691bf553901d55fcfa88bc2f |
| Dark1A.lua | e20be9a5f2829b74ada1f0f8de0485efd18d4c2364b417a87db31c5bca1ed568 |
| Branch1A.lua | e110ca93091a627735435e88eb340e4dab2d53151cb7b925138b717934af6b9b |
| Dark2A.lua | 36cb7bd1da0772918e9f0bfd1a1226d88c884da4320cd2458fcc8dcc359d2585 |

## 客户端

插件源码在 `data/reborn-client/Interface/AddOns/`(RebornQuestMap、RebornQuestPins、RebornShipMovie)，与试装客户端实装一致。
DBC、地图、模型、图标、vmaps/mmaps 等二进制不入库：各包清单在 `manifests/`，原包在本机 `000Ascendupdate/` 对应日期目录。仓库内容本身不是可独立部署的完整安装包。
