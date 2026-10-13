# MBUI1A–1D 验收记录：MultiBot 底栏的随从图标、缩放和金边

- 日期：2026-10-12；开发：Claude；验收：用户（"搞定"）。
- RebornCompanions 原是 Codex 的 NBC2 插件，这次由用户直接指定 Claude 修改，已登记在协作说明。

## 功能
| 批次 | 内容 | 实测 |
|---|---|---|
| MBUI1A | 原来压在底栏上方中间的红色"雇佣随从"按钮，改成底栏最右侧的机器人图标（`Art/RobotIcon.tga`，用 MultiBot 自己的按钮函数生成，样式与其他图标一致）。图标右下角的小三角拖动可缩放整条底栏（0.5～1.6 倍），双击恢复原大小，缩放比例按角色保存（`RebornCompanionsDB`）。MultiBot 下线时保存位置的算法被替换为考虑缩放的版本 | 图标出现，缩放可用 |
| MBUI1B | 修复点击图标后窗口打不开：MultiBot 的 PostClick 已经会切换窗口，多加的 OnClick 又切换一次 | 点击后窗口正常打开 |
| MBUI1C | 底栏一排图标外加 NetherBot 同款的金边和深色底 | **不显示** |
| MBUI1D | 边框创建时立即给出位置和大小，改由一个独立框体负责刷新，并每次重新对齐层级；新增 `/rcbar` 诊断命令 | 用户："搞定" |

MultiBot 插件本身的文件一个都没有改。

## 哈希（用户现场 = 候选包输出，SHA256 前 12 位）
| 文件 | 哈希 | 来源包 |
|---|---|---|
| `Main.lua` | 316233df30d7 | MBUI1D |
| `RebornCompanions.toc` | 50afb484bfff | MBUI1A |
| `Art/RobotIcon.tga` | 27e35753a2e8 | MBUI1A |

候选包都在 `000Ascendupdate/000Ascendupdate20261012/`：
- `claudefix_20261012_100000_阶段MBUI1A_随从图标与底栏缩放`
- `claudefix_20261012_103000_阶段MBUI1B_机器人图标点击打不开`
- `claudefix_20261012_110000_阶段MBUI1C_底栏金边`
- `claudefix_20261012_113000_阶段MBUI1D_底栏金边不显示`

## 未单独验证
- 缩放后小退/重登时位置是否保持。
- MultiBot 展开或收起按钮组时，边框是否跟着变化。
- 没有 MultiBot 时，原红色按钮是否作为后备出现。

## 安装
- 只有客户端改动：用 Release 附件（RebornCompanions 完整目录）覆盖。
- 因为新增了保存变量，首次安装需要重开游戏。
- 服务端不动。
