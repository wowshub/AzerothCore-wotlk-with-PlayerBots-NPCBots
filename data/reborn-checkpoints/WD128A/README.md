# WD128A 源码与资源归档（已知保存缺陷）

本归档仅保存 WD128A 调酒师、双香料及精确数值修正。用户明确要求 WD128B 保存入口修正留到下次提交，因此本次不合入。已知新节点保存会被 100 位入口拒绝；本归档不能作为已修复保存问题的可用新版本发布。WD127F 的基本验收不能替代本批验收。

## 安装与数据库

1. 将 01_覆盖到源代码根目录 合入源码工程，由用户编译服务端。
2. 客户端覆盖 02_覆盖到客户端根目录；将 client_mpq输入_导入现有Patch-XA 导入现有补丁 MPQ。必须保留 MPQ 中的图标，loose 插件不是完整替代。
3. 服务端使用 03_覆盖到服务端根目录 中的独立 Data/dbc。客户端和服务端 DBC 绝不可互换。
4. WD128A 对应 Characters 脚本为 server_SQL/01_CHARACTERS_WD128A_必须执行.sql；已经执行过则不因本归档重跑。World 脚本为历史依赖，已部署 WD127F 不要重复执行。新数据库不能把这份累计 SQL 当作空库初始化脚本，它依赖既有 WD67/WD93 等结构。
5. 本次仅归档，不建议为此重新安装 WD128A。保存入口修正留待后续独立提交。

原 WD128A/WD128B ZIP 保持不变。provenance 下是 WD128A 历史证据，旧说明仅供追溯；本批有已知保存问题。

## 验证边界

本次仅做归档与源码逐字节核对，不宣称完成服务端编译、生产数据库执行、实际部署或新技能实机验收。A 原验证见 provenance；其检查曾漏掉保存入口，历史测试结果不能描述为本次重新执行或整体功能通过。

## 源码与资源配对

仓库 data/reborn-checkpoints/WD128A/manifest.json 记录归档包及各安装文件 SHA256。C++ 位于正常源码目录，客户端 Lua/TOC 位于 data/reborn-client，SQL 位于 data/customfixsql/witchdoctor/20261005_wd128。
DBC、BLP 在本归档包中保存，不把大 ZIP 加入普通 Git 历史。本批存在已知保存缺陷，不发布为正常版本。后续修复并验证后，用配套源码 commit 创建版本 tag，将匹配的 ZIP 和 SHA256 作为 Release 附件。未上传前，其他人仅 clone 仓库不能取得这些二进制资源，必须取得本包。不要删除本地唯一副本。

本地附件：`D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261005\codexarchive_202610052158_WD128A_源码与资源版本归档.zip`

SHA256：`e172a65ca62a5e9a3712d447db1ea73cb9a9ddd36129e7a5ea6a6184e4f519b6`

清单 SHA256 对应交付原始字节；Git 可能规范化文本换行，各仓库映射另记 git_blob_oid 用于核对提交中的文本。
