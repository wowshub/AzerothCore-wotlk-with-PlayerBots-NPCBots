# HOME8B–9A / SEAT1 / WEAPDECOR2B / WHLFG1A 验收记录（2026-11-05 提交）

用户 2026-11-05 确认下列范围测试通过并要求 commit+push；未外推未列出的内容。

## 本提交内容（服务端 + SQL）
- mod-reborn-housing 累计源码：配方表与获取方式(HOME8B)、家具中文名(HOME8C)、库存与稀有度(HOME9A/9B)、家具可坐(SEAT1A)、床可躺下(SEAT1B–1E，床高 Data6、重力处理)。
- SQL：data/customfixsql/world/housing/{HOME8B,HOME8C,HOME9A,SEAT1A,SEAT1E}，data/customfixsql/characters/housing/HOME9A。HOME9A 的 00_ 脚本须先于 01_ 导入。SQL 手动导入，本提交不执行。
- 注意：RebornHousing.cpp 是累计文件，同时含 WEAPDECOR2A 的 GM 命令 `.home recipe`（价格与材料编辑器）——**该项未收到测试结果，未验收**，随文件入库但不属于验收范围。

## 客户端（不在 Git 中的二进制/DLL源码，仅记录）
- WEAPDECOR2B 住宅面板"点世界选择"开关、HOME7D/8A 主面板与工具栏、HOME9A 库存/稀有度界面：用户测试通过。客户端 wxl-housing.dll 为累计构建，另含未验收的拾取点 GM 窗口，故不作为 Release 附件。
- WHLFG1A 猎巫者(class15)地城职责：DivxDecoder.dll 源码 ui57_install_monk_lfg_roles 增加 `g_ui57_roles[15] = 0x0B`（队长+坦克+输出，无治疗）。用户测试通过。
  输入源码 SHA256 0BDE59AA…88C2；输出源码 444c4650781ea1f485cae05622720bce610ca318cb5c32e002a45afed1e73109；输出 DLL 4971ae64c571540a6a910538c9fe221d56f37be2ed1d1ade6d575a51dc43c804。日志标记 `WHLFG1A class15 mask=11`。开放坦克职责不代表猎巫战斗体系完成。

## 未纳入
- DCLANG1A（DungeonClear 坐标窗口中英切换）在独立 addon 仓库，其工作树混有其它阶段未提交改动，未在本次推送。
- WEAPDECOR1A–1G、WPICK1A/1B/2（拾取点）、2A：未测试，未纳入；核心 GameObject 钩子与 mod-reborn-pickups 不在本提交。
