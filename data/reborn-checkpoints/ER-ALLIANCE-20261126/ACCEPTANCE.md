# ER-ALLIANCE-20261126：流放者之岛联盟任务链归档(双阵营完成)

用户原话(2026-11-26)："好棒 现在的联盟和部落 流放岛 已经搞定了 可以先commit 并推送了吧"。
部落线上次归档见 ER-CHAIN-20261125。

## 验收范围(按实际状态)

| 部分 | 状态 |
|---|---|
| 联盟、部落两条主线在流放者之岛走通 | 用户总体确认"已经搞定了" |
| 联盟船与失事过场(ALLY1A V3) | 此前用户实测("好棒 搞定了") |
| 联盟 55173–55879(ALLY1C V1–V3)、分支任务 56839/54933、光明之灵原版模型 | 此前用户实测通过 |
| 吉安娜动作(MODEL1A–1C) | 用户实机确认("这下对了")；其余四个模型用户反馈没有问题 |
| 海滩营地(ALLY1B)、鹰身人区(ALLY1D)、深坑(ALLY1E)、雄鹿模型(ALLY1E-M)、部落野猪载具(VEH3A) | 已装；随总体确认，没有逐项单独反馈 |
| 暗槌外圈与副本终章(ALLY1F、ALLY1G) | 服务端脚本与插件读回等于包内版本；随总体确认，没有逐项单独反馈 |
| 部落食人魔变身(随 ALLY1F 的 Dark1A.lua 首次实装) | 没有单独反馈 |

不外推：职业任务(联盟、部落都未做)、组队与机器人、全部职业、断线重登等异常、长期压力。world SQL 是否逐个执行由用户操作，本次没有读数据库；发布时没有编译、没有执行 SQL、没有实机复测。
不包含：GLUEFONT1A(建角界面乱码修复，候选未测)。

## world SQL 执行顺序

接在 ER-CHAIN-20261125 的 1–40 之后。执行前停 worldserver，执行后重启。**不要在后面阶段之后重跑前面的阶段**(会覆盖相位和外观)。
SHIP2A 的天气 SQL 是上次归档漏掉的，放在最前(与任务序号无依赖)。

| 序号 | 阶段 | 文件(data/customfixsql/world/exiles-reach/) |
|---|---|---|
| 0 | SHIP2A_V2 | 20261121_00_ship2a_v2_world_ship2a_game_weather.sql |
| 41 | ALLY1A_V3 | 20261125_41_ally1a_v3_world_ally1a_ship.sql |
| 42 | ALLY1B_V1 | 20261125_42_ally1b_v1_world_ally1b.sql |
| 43 | ALLY1C_V1 | 20261125_43_ally1c_v1_world_ally1c.sql |
| 44 | ALLY1C_V2 | 20261125_44_ally1c_v2_world_ally1c_v2.sql |
| 45 | ALLY1C_V3 | 20261125_45_ally1c_v3_world_ally1c_v3.sql |
| 46 | BRANCH1B_V1 | 20261125_46_branch1b_v1_world_branch1b.sql |
| 47 | VEH3A_V1 | 20261125_47_veh3a_v1_world_veh3a.sql |
| 48 | ALLY1D_V1 | 20261125_48_ally1d_v1_world_ally1d.sql |
| 49 | MODEL1A_V1 | 20261125_49_model1a_v1_world_model1a.sql |
| 50 | ALLY1E_V1 | 20261125_50_ally1e_v1_world_ally1e.sql |
| 51 | ALLY1E_M_V1 | 20261125_51_ally1e_m_v1_world_ally1e_m.sql |
| 52 | ALLY1F_V1 | 20261126_52_ally1f_v1_world_ally1f.sql |
| 53 | ALLY1G_V1 | 20261126_53_ally1g_v1_world_ally1g.sql |

ALLY1A 三个版本中只收录最终版。BRANCH1B、ALLY1E-M、MODEL1A 的 SQL 依赖客户端和服务端的 CreatureModelData/CreatureDisplayInfo(710003–710009)，DBC 不入库。

## 服务端 Lua(与发布时实装一致；入库换行统一为 LF，SHA256 为实装文件原字节)

| 文件 | 来自 | SHA256 |
|---|---|---|
| Ally1A.lua | ALLY1A_V3 | 6949fb64f670cd40bc5ea58a13f47fb8fd0673dc87d35a48a85fcc7e8cd68e5a |
| Ally1B.lua | ALLY1B_V1 | 571a49340af7d25859f79c0bedcef5eb493c2d7db9e4ece5d79ab795670289e0 |
| Ally1C.lua | ALLY1C_V3 | 9415af16d7e0413a89fa5ead7d1aa79f062204f69cd631c3f9a77c5e0547e6eb |
| Ally1D.lua | ALLY1D_V1 | c2b416936d80bcbd117ef5505556e7e6c0bbde6584c6b7595778a34cc95d6e47 |
| Ally1E.lua | ALLY1E_V1 | 027494fc9c6a913ab497853d8a2958901299636ab727396c514d161a9d8ee12f |
| Veh1A.lua | VEH3A_V1 | 9e01d0188cc364d5eb75e2969ae378c3332b9fdab348d3bf7fcd8cca09d9f41b |
| Dark1A.lua | ALLY1F_V1 | 91dceeae4f229663ad088b3ab6b611dd1642b5e7ffc3d6f8e64e13e94a69fd2b |
| Dark2A.lua | ALLY1G_V1 | f2d55afb22a3a8b1cb688ea600e7726d30e62e49525b620285f47632e98899d0 |
| Branch1A.lua | BRANCH1A_V1 | e110ca93091a627735435e88eb340e4dab2d53151cb7b925138b717934af6b9b |
| Pit1A.lua | PIT1D_V1 | 2a4b0e003ca7e70b0d49300c81d04217742fc5a4691bf553901d55fcfa88bc2f |
| Harpy1C.lua | HARPY1C_V4 | 631f6c85d76fc3ffba7433ee9a74ec37da556f6531dc79dec1a00336dc0e83f0 |

船、海滩部分的其余脚本与 ER-CHAIN-20261125 归档内容相同。

## 客户端与资源

- 插件 `data/reborn-client/Interface/AddOns/RebornQuestPins` 更新到 1.2；RebornShipMovie、RebornQuestMap 与上次归档相同。
- 不入库：DBC、MPQ、过场影片、模型别名与覆盖目录里的零售素材(TwoFormsTables *.bin，禁止提交或分发)、渲染图。清单在 `manifests/`，原包在本机 `000Ascendupdate/`。
- 联盟船地图 12261 使用用户称已获作者授权的 UniWoW 测试资源，资源不入库。
- 仓库内容本身不是可独立部署的完整安装包。`tools/` 里的脚本含本机路径，使用前要改。
