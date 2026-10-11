# DCGPS1A–1C 验收记录：`.gps` 坐标一键复制

- 日期：2026-10-10；负责：Claude（服务端 `cs_misc.cpp` 的 `.gps`、DungeonClear 插件）
- 用户原话：“前面的gps修复也完美了”（同时确认登录器修改可以推送）
- 基线：`threemodelcardpro` @ `0d5fcfc40cdc361494c71dfd2bb038d253b669b8`。提交前执行了 `git fetch wowshub`，远端没有前进。

## 验收范围

| 阶段 | 内容 | 位置 | 状态 |
|---|---|---|---|
| DCGPS1A | `.gps` 末尾加一行机器可读的 `[gps] X .. Y .. Z .. O .. map .. zone .. area .. instance .. phase .. type .. entry .. spawn .. name ..`。原有输出不变；选中生物时带 entry 和 spawn（creature.guid） | `src/server/scripts/Commands/cs_misc.cpp`（本提交） | 用户游戏内测试通过 |
| DCGPS1A 插件 | 坐标复制窗口：5 种格式、预先选中文字的输入框、历史记录 | 插件 v3.6-reborn12（没有单独发布，已包含在 reborn14 里） | 用户测试通过 |
| DCGPS1B | 标题栏【坐标】按钮；【记录位置】替你发送 `.gps` | 插件 v3.6-reborn13（已包含在 reborn14 里） | 用户测试通过 |
| DCGPS1C | 【复制】按钮（AwesomeWotlk 的 `CopyToClipboard`，没有时退回 Ctrl+C）；记录地点名称；最多 200 个，每页 10 个；鼠标悬停详情；右键菜单（复制 / 复制为 / 传送到这里 / 备注 / 收藏 / 发到聊天 / 删除）；只看收藏；修正格式按钮宽度 | 插件 v3.6-reborn14 | 用户测试通过（复制到剪贴板实测可用） |

插件：wowshub/mod-dungeon-clear-addon `cd80dcb9836c0fa3b88d2e604ac1959b4ebf84d5`，tag `v3.6-reborn14`。Release 附件 `DungeonClear-3.6-reborn14.zip`，SHA256 `c2f29a55d792f277a129bd1724d7ad7f6f67e07cad3658c3a266b3c6666e10ba`（已下载回来核对过）。

## 一致性核对
- 源码 `cs_misc.cpp` 与 DCGPS1A 包内文件逐字节一致，SHA256 `7a4ff2648aba797d9b7de9d412ec94b647b4db3b20b07e257af6bf4808e659f3`。
- 客户端 `newrebornWOWli20261011beAscend/Interface/AddOns/DungeonClear`、DCGPS1C 包、插件提交，三者 5 个文件一致（忽略换行符）。

## 交付包（000Ascendupdate20261010）

| 包 | SHA256SUMS.txt 的 SHA256 |
|---|---|
| claudefix_20261010_203506_阶段DCGPS1A_坐标一键复制 | `2773deadd33ef7d881af7ea41ea6dacc92f9bbec6cba658188b1c4db95a31483` |
| claudefix_20261010_213604_阶段DCGPS1B_面板坐标按钮 | `470935e7e5e99b00d83d7cb78ec55cadff49d09d6479c8e5ea530cf0b5314703` |
| claudefix_20261010_215344_阶段DCGPS1C_坐标复制按钮与列表 | `e3ed5971853a482eb8507860dcad08a7be63c8a419ec5bbcd3e206e53ac719d8` |

## 部署
- 服务端：编译 worldserver（只改了 scripts/Commands 里的一个文件）。不需要 SQL、DBC。
- 客户端：安装 DungeonClear v3.6-reborn14（Release 附件），然后 `/reload`。
- 没有测试：非 GM 账号（`.gps` 本来就是 GM 命令，非 GM 点按钮时服务端拒绝，插件不会出错）。
