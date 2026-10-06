# 巫医 WD128 SQL（手动执行）

characters/ 是本批 Characters 更新；world-history/ 保存累计包的历史 World 依赖，不是本次新增迁移。从已部署 WD127F 升级只执行 characters/ 中的脚本；已执行 WD128A 的无需为 WD128B 重跑。新空库不适用。

这些文件与交付原 SQL 逐字节一致，未在本次执行数据库。不要放进 db_world，也不要同时复制到自动更新目录导致两条执行途径。自动更新器读取数据库 updates_include 配置；若以后改为自动迁移，需要另行适配正确数据库、命名、依赖和执行方式，并验证 DELIMITER/存储过程兼容性。
