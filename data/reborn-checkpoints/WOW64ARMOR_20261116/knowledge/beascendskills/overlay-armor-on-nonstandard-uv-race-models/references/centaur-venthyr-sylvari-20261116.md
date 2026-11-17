# 身体装备、半人马披风与袖甲跟随

温西尔101的身体UV匹配76供体，但使用独立101-0/1.bin（1024x512）；希尔瓦里110匹配74，复制成110独立文件并保留fur透明。不能仅看名称就把76运行映射复用给所有族。四BIN共2097152采样点做范围检查。

半人马102原身体与clothing有208骨，按CRC、层级、pivot逐骨核对，使用独立M2+skin覆盖层、SetSkinParent；保持身体和衣服的顶点/权重。标准512盔甲图放大到2048x1024布局141左半，腰带type15独立alpha，脚部按实际分区映射，不把装备图画在马背或脸上。

背白不是任意贴图缺失：身体没有type2，旧AddCape替换被丢弃；clothing有type2，直接从ItemDisplayInfo解析披风BLP并绑定到clothing，保留异步就绪和缓存句柄生命周期。用户“背部白色也处理了”明确通过。

袖甲悬空先验了骨权重/调色板及rest距身体中位0.024，再定位ClearSkinParents在身体从背景拆挂时清掉后代clothing映射，导致衣服回到自有Stand/T姿势。最终ClearDetachedAttachment只删除拆下实例自己的skin-parent/frame/suppression，不清后代；真正卸载仍递归清理。102已装备却缺collection/绑定时Pending重新安排绑定；不能仅凭装备ID未变就跳过。

离线41600映射矩阵检查，含男女/多姿势、拆挂、重绑、缺collection、无关种族、卸载和换骨架。用户总体反馈仅剩白模，记基本通过；不外推所有世界动作和装备款式。

附件资源：00四个EquipmentFitting BIN覆盖客户端目录；02四个custom/rebornfit/centaur文件导入已有完整Patch-YB.mpq。不得拿增量目录另建同名小YB覆盖原完整档案。原身体、整表DBC和SQL不在此批。

## 来源与适用边界

最终冻结包：codexfix_20261116_185711_阶段WOW64ETHPREVIEW2A_虚灵幻化材质与主副预览_累计总包_附源码BAT.zip。
ZIP SHA256：11e46ec4d3241b7f981f606cb9585a3ca412e44c5fbc4654943946d9dfcb4c65。
EXE SHA256：de4e51ba9eb62bea82aa85ba2dd437e66a3220a872c5eec186568e46b873e5db。

这是已测试累计客户端的功能归档，不是可以单独编译或直接安装的完整客户端。client-source保留原工程相对路径，是上述冻结源码的逐字节副本；同一公共文件可能同时包含本次其他已验收客户端修复，不能当作仅该功能的最小差异或整文件回滚包。各批共用最终M2接口、装备合成与预览生命周期；需要在对应累计工程中审阅合并。原07完整源码与BAT保留在本地冻结包，不用服务端Git自动Source code包替代它。
附件只包含本批源码档案、知识、检查证据及明确列出的客户端增量资源。没有新EXE、整张DBC、SQL、服务端程序、现场dump、账号/角色数据或未验收家园源码。已安装且测试成功的用户无需重装、重导SQL或再次编译。未经核对后续改动，不整体回盖旧文件。
固定上游来源STRHercules/wowdecomp@601c8bbc3243920d92fa45cff3bc9472202fd0db；修复期间上游网络读取失败，不能称为最新上游核验。本轮发布前已成功fetch项目wowshub；功能依据现场与本地源码定位。
