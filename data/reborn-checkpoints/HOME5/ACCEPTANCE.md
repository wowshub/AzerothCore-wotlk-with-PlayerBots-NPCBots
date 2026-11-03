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
