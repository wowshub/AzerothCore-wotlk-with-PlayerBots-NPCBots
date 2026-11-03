# HOME 线 (HOME1A .. HOME5B9 / H3A / H3C) 验收记录 2026-11-02

范围：服务端模块 mod-reborn-housing（地块、家具、.home 命令、地块改名、scale 字段自动补齐）及其 WORLD SQL。
客户端对应提交：wowshub/wxl-reborn 739bdda（wxl-housing 扩展）。

## 用户在游戏里确认的（2026-11-02）
- 地块改名（含中文名）可用；服务端 .home plot rename 生效。
- 服务端家具 #4 编辑、更新；我的家园列表显示并自动刷新。
- 服务端启动正常（缺 scale 字段时自动补，不再 1054 崩溃）。

## 未测试 / 不外推
- 拖拽后缩放与朝向的多人同步细节(H3C)。
- 地块半径购买分档、家具上下翻转(未实现)、移除返还金币(未实现)。
- .home 命令对非 GM 的全部权限边界。

## SQL
data/customfixsql/world/housing/{HOME1A,HOME1B,HOME4A,H3A,H3C}。按顺序执行一次；H3C 目录里的 00_ 文件是不含 PREPARE 的补 scale 字段脚本。
本记录不运行生产 SQL。

## 2026-11-02 追加：HOME5C / HOME5C2 / HOME5C3（用户确认测试成功）
- 购买新地块窗口：名字（可空，默认角色名）、三档大小、圆形/方形、预览图、价格；买完新地块出现在列表并被选中。
- 形状：圆形、方形；方形不加价，圆形按 Housing.Plot.CirclePercent（默认 120）加价；档位在 Housing.Plot.Tiers（默认 15/30/50 码 = 100/500/2000 金）。
- 游戏内预览：.home plot preview <半径> [形状]，沿用 Housing.Show.* 的火盆。
- 修复：地块表里残留的 uk_owner（一人一块限制，HOME4A 的 PREPARE SQL 被导入工具跳过）会让第二块地被数据库拒绝而程序误报成功；
  现在服务端启动时用普通 ALTER 去掉它，购买时核对插入是否成功。
- SQL：data/customfixsql/world/housing/HOME5C（加 shape 列，服务端也会自补）。
- 未测试：非 GM 账号下的真实三档价格与扣费；GM 自定义半径；方形地块里摆家具的边界；多人同时购买。

## 2026-11-02 追加：HOME6A 三轴旋转（用户确认通过："多面旋转可以的 不错 通过"）
- 家具表 reborn_housing_object 新增 pitch、roll（弧度，启动时自动补列）；.home put/set 增加俯仰、侧倾参数；J 行带出两个角。
- 服务端用 Rz(朝向)·Ry(俯仰)·Rx(侧倾) 合成四元数；俯仰限制 ±89°。客户端三轴球环旋转，世界轴。
- 离线自测：4000 组角度往返误差约 1e-15。
- 未测试：局部轴旋转（未做）、编辑服务端家具时原物体仍显示（原有行为）、重启服务端后大批量倾斜家具的显示。
