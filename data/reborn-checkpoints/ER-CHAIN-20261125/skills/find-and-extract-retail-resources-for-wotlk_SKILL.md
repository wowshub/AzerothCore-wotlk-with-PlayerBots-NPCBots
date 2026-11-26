---
name: find-and-extract-retail-resources-for-wotlk
description: 从零售(12.x)客户端/数据库、wago.tools 表、社区 listfile、其他服务器的补丁里查找并提取任务、NPC、物品图标、生物模型、地图、过场动画等资源，并导入 3.3.5 自定义客户端与服务端的方法：该去哪里找(数据来源清单)、怎么按 ID/名字搜索、怎么确认"客户端当前实际生效的 DBC"、模型/图标/地图的提取与转换步骤、服务端地面数据(.map)生成、验证与常见失败。需要某个零售资源但不知道从哪找、要导入新地图/模型/图标时先读。
---

# 搜索与提取零售及其他服务器资源(流放者之岛实战提炼)

## 证据状态(先读)
- **用户实测通过**：从零售数据库提取任务与NPC并在 3.3.5 里跑通；零售野猪模型(别名文件+CreatureModelData/DisplayInfo+服务端 creature_model_info)；零售图标转成 3.3.5 BLP 后背包里显示(ITEMICON1A V3)；流放岛地形/建筑在客户端能显示(MAP12 系列，见 port-retail-map-to-custom-client)；岛服务端地面数据 116 个 `.map` 让 NPC 不再下沉。
- **没实测**：缩放器图标(ITEMICON1B)；"其他私服/其他服务器的补丁"的提取——本技能第五节是**通用做法的推荐流程，我们没有在其他服务器资源上真的走通过**，按候选对待；vmaps/mmaps 生成没做；零售过场动画 895(联盟船失事)读不出。
- 本机固定位置(换机器要改)：零售客户端与数据 `D:\wow12`(含 `LoreWalkerTDB`、零售 69587 版本 CASC)；`D:\_zsdc\wow12x`、`D:\_zsdc\er_srv` 是我的工作目录；StormLib 在 `D:\soft\python3.9\Lib\site-packages\pympq\StormLib.dll`。

## 一、先判断要找什么，去哪里找
| 要找的东西 | 去哪里找 | 怎么用 |
|---|---|---|
| 任务文本/目标/NPC/出生点/掉落/SmartAI | `D:\wow12\LoreWalkerTDB\world.sql`、`hotfixes.sql` | `port-retail-quest-chain-to-wotlk/references/scripts/er_lib.py` 的 `rows('表')` |
| 物品、生物外观(DisplayInfo)、模型数据、物品外观 | wago.tools 导出的 CSV(Item、CreatureDisplayInfo、CreatureModelData、ItemModifiedAppearance、Map、Movie 等)，存 `D:\_zsdc\wago_item`、`wow12x\map_wago.csv`、`movie_wago.csv` | 先按 ID 搜行，拿到 FileDataID(FDID) |
| 文件编号→路径 | 社区 `listfile.csv`(`wow12x\listfile.csv`、`listfile2.csv`) | 搜文件名关键字得到 FDID，或反过来 |
| 零售文件本体(M2/BLP/ADT/WMO/电影) | 本地零售 CASC(`D:\wow12`)，用 `RetailAssetProbe.exe`(`D:\_zsdc\fx\build\Release\`)：`--batch` 探测存在，`--extract-batch` 提取 | 输出到 `PROBE_OUT` 目录；FDID 一行一个 |
| 3.3.5 原版资源(别人家的模型、技能、DBC) | 试装客户端各个 MPQ(用 StormLib)；服务端 `data/dbc`、`data/sql/base/db_world` | 找"客户端已经有的东西"，免导入 |
| 参考实现/源码 | GitHub：`wowshub/wowshubDragonEluna`、`KamiliaBlow/RoleplayCore`(`D:\wow12\url.txt`)、流放者之岛脚本 `repo_er`(`zone_exiles_reach.cpp`) | 只看做法，注意许可证(见 reference-retail-race-and-asset-import-methods) |
| 快速人工核对 | wowhead / wowpedia 页面 | 只用来对照名称与任务描述，不当数据源 |

## 二、"客户端当前实际生效的是哪一份 DBC"(最容易出错)
1. DBC 被多个 MPQ 覆盖，**最后加载的那份生效**。先用 StormLib 逐个打开试装客户端 `Data\*.mpq`，按**客户端实际加载顺序**找最后一个含该文件的 MPQ(`getitemdbc.py` 一类脚本)。**不能**简单按文件名字母序；也别只看 `patch-enUS.MPQ`(扫描会很慢，每个包只开一次)。
2. 本项目已实测的"赢层"：Item.dbc / ItemDisplayInfo.dbc → Patch-XA；CreatureModelData / CreatureDisplayInfo → Patch-YB；Map/AreaTable → Patch-X。**每次改前重新核对，别信这行**。
3. 改完把输入/输出 SHA256 登记到 `台账_YB_XA共享文件哈希.md`，Codex 等成员同时在改同一张表时，按主键加行，不要整张覆盖。
4. 服务端的 `data/dbc`(以及 `zhCN` 子目录)是另一份基线，客户端改了服务端也要同步，否则出现"没有 creature_model_info/AreaTable 行"的静默失败。

## 三、各类资源的提取与导入
**图标(物品)**：零售 FDID → `RetailAssetProbe --extract-batch` 得 BLP/PNG → 用 `blp_dxt1.py` 转 **DXT1 + 完整 mip**(Pillow 的调色板 BLP 在本客户端显示成绿色)，文件大小对齐原版 → 放 `Interface\Icons\xxx.blp`(Patch-ZC) → ItemDisplayInfo +1 行(图标名字段) → Item.dbc 把物品行的 DisplayInfoID 改成新行 → 服务端 `item_template.displayid`。背包图标认客户端 Item.dbc，不认服务端。
**生物模型(例：野猪 710001)**：零售 CreatureDisplayInfo → ModelID → CreatureModelData → 文件 FDID；`Data\Retail\aliases_maps.csv` 加一行 `FDID;虚拟路径`(RetailCasc.ini mode=local 读本地零售)；客户端 CreatureModelData、CreatureDisplayInfo(YB)各 +1 行；服务端同名 DBC +1 行、`creature_model_info` +1 行、`creature_template_model`。新 ID 先查是否占用(曾撞过 700001，改用 710001)。**模型的体型和碰撞要核对**(BOAR_BASE 0.3 之类缩放在 Lua 里调)。
**地图**：客户端部分见 `port-retail-map-to-custom-client`(Map.dbc 新行、WorldMapArea、AreaTable、LiquidType、RetailCasc.ini)。服务端地面数据：零售 → 转成 3.3.5 地形(ADT) → 服务端自带 `map_extractor.exe` 生成 `data/maps/<地图ID><y><x>.map`(高度、水、区域)，每块 533.333 码，tile=floor(32−坐标/533.333)。`hz.py` 能直接从 `.map` 读某坐标的地面高度，布置 NPC/飞行路线时用。只含出生点附近一圈即可(流放岛 116 块约 11MB)。**vmaps/mmaps 没做**，所以建筑碰撞和怪物寻路缺失。
**过场动画**：FDID → 视频/MOVIE 记录(`movie_wago.csv`)；客户端 Movie.dbc 加行或直接用插件 `MovieFrame` 播放；本客户端已用的做法是插件触发，见 SHIP2C。
**区域/墓地**：新地图的区域号要同时加到服务端与客户端 `AreaTable`，否则 `graveyard_zone` 记录被丢。
**别人家的补丁(其他服务器)**——**候选流程，未实测**：
1. 把对方补丁 MPQ 放到**独立的新目录**(别放进客户端 Data)，用 StormLib 列出文件，搜关键字(`creature\xxx`、`spells\xxx`、`world\maps\xxx`)。
2. 找到后在独立副本里提取，核对格式是否为 3.3.5(M2 版本 264、BLP DXT/mip、ADT 版本)；零售格式的要先转换。
3. 查许可证与来源，只导入允许使用的；登记来源。
4. 缺什么补什么：模型要有 CreatureModelData/DisplayInfo 与服务端 creature_model_info。

## 四、搜索技巧(大白话版见 Tutor)
- 先按 **ID** 搜，再按**名字**搜；名字在 3.3.5 里常叫法不同(用 `lookup.py` / `disp.py` 在服务端基础库里按名字找现成外观)。
- 数据 dump 很大，用流式读取，别整个读进内存。
- 同一个零售生物有多个阶段行，按坐标去重。
- 零售有、3.3.5 没有的东西(技能、光环)先想"能不能用现成的代替"(如绷带法术 746、侏儒直升机外观 28830)，再考虑新增 DBC。
- 找不到就记录"检索了哪些位置、没找到"，不要编造来源。

## 五、验收清单
文件进了正确的 MPQ → 清客户端缓存 `Cache\WDB` → 关掉 MPQ 编辑器 → 进游戏看 → 重启服务端再看。写明哪些是用户实测、哪些是候选。

## 参考
- `references/lookup.py`(按名字查 3.3.5 基础库里的外观)、`disp.py`(批量查)、`hz.py`(读 `.map` 地面高度)。
- 相关技能：port-retail-quest-chain-to-wotlk、port-retail-map-to-custom-client、reference-retail-race-and-asset-import-methods、repair-wotlk-item-texture-references。

## 2026-11-25 补充：零售地图的服务端 vmaps/mmaps(VMAP12175A)
取代上文“vmaps/mmaps 没做”。状态：已生成并装到服务端，离线用碰撞三角形核对 5 个坐标地面高度一致；实机寻路/视线效果用户未单独确认。
流程(脚本在 `references/vmap/`，路径需改)：`conv.py` 用 RetailAssetProbe `--batch` 把地图块引用的 WMO/M2 转成 3.3.5 格式 → `fixgroups.py`(**WMO 分组必须和根文件在同一次进程里转换**，否则 002 之后的分组静默返回根文件内容) → `run.py prepare`(私有假客户端：原版 MPQ 硬链接 + 只含本地图行的 Map.dbc) → `run.py vmap`(提取+组装，私有副本把组装器的 VMAP047 魔数改为 048) → `run.py mmap`。`floor.py` 校验地面高度。不要发布生成目录里的 GameObjectModels.dtree。
