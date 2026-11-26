# GLUEFONT1A：角色创建界面中文乱码/错位

用户反馈(2026-11-26)："界面的乱码修复应该可以了 我没有注意有乱码了"。

- 状态：安装后用户没有再注意到乱码(基本确认)。问题本身是偶发的，乱码原因(字形缓存按字体字号共享被挤出)是推断，没有复现或证实。
- 读回：试装客户端 Patch-YB 里的 RebornCreatorTextFix.lua 与 GlueXML.toc 等于包内版本。
- 安装：把 `data/reborn-client/Interface/GlueXML/RebornCreatorTextFix.lua` 导入 Patch-YB 同路径，并在实装的 GlueXML.toc 里、`## This Always Runs Last` 之前加一行 `RebornCreatorTextFix.lua`(整个 toc 不入库)。
- 依赖建角界面脚本 RebornCreator.lua(另一成员维护，本次没有改)；以后重新导入 toc 要保留这一行。
- 实装 toc SHA256 `86f8a9832567dc83077805ef936c7b3bbc3c4b6344a8899fb5150dca7c0567dd`，脚本 SHA256 `03d4f2ca522d30bf71291b01144daec550caed738876377ce2fcc898cc67e1de`。
