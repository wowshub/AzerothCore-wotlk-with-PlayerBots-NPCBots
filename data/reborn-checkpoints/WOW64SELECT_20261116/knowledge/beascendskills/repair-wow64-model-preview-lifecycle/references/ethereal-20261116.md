# 虚灵幻化白模：先复制实体，再复制外观状态

虚灵109在世界正常、ezCollections左主预览和右套装缩略图全白，肩甲仍有颜色。PREVIEW1A复制了RetailRace状态、形态、眼睛和偏好，但漏了实体创建入口，单纯补状态仍白。

CGCharacterModelBase从当前unit.worldModel做DuplicateModel并RetailRaceDuplicateCollections重绑衣服。DressUp覆写却按nativeDisplay→CreatureModelData重新CreateModel，拿到兼容占位实体，丢掉当前动态身体和已绑定材质。

最终仅非强制人类剪影、race109、RetailRaceActive且component.model==unit.worldModel时委托基类；其余族、无组件、未接管或变形实体不匹配保留旧路径。副本独立，不把世界模型转挂到预览。外观状态深复制与collection重绑配套，不能只复制贴图指针或重建旧占位身体。

真实Blizzard_Wardrobe.lua主预览SetUnit(player)，缩略图SetUnit(player,false)，均走此C++入口；不是Snapshot持久图片缓存，未清Cache/WTF、未改Lua/插件设置。原虚灵四clothing文件从供体逐字节补齐，288/285骨匹配，只含14/2纹理替换槽；机械另一形态不承诺同样衣服覆盖。

17个替身调用/状态隔离场景涵盖男女、三个body ID、强制人类、非目标种族、变形不匹配和复制不改源。这是代码路线验证，不等于真实GPU渲染。用户最终“搞定啦”确认所报主副预览白模解决；不能扩大所有形态/全装备组合。

附件四个custom/ethereal文件导入现有完整Patch-YB.mpq；已装者无需重导。最终白模修复本身仅DressUpModelFrame.cpp，无新增M2/BLP/DBC/SQL。

## 来源与适用边界

最终冻结包：codexfix_20261116_185711_阶段WOW64ETHPREVIEW2A_虚灵幻化材质与主副预览_累计总包_附源码BAT.zip。
ZIP SHA256：11e46ec4d3241b7f981f606cb9585a3ca412e44c5fbc4654943946d9dfcb4c65。
EXE SHA256：de4e51ba9eb62bea82aa85ba2dd437e66a3220a872c5eec186568e46b873e5db。

这是已测试累计客户端的功能归档，不是可以单独编译或直接安装的完整客户端。client-source保留原工程相对路径，是上述冻结源码的逐字节副本；同一公共文件可能同时包含本次其他已验收客户端修复，不能当作仅该功能的最小差异或整文件回滚包。各批共用最终M2接口、装备合成与预览生命周期；需要在对应累计工程中审阅合并。原07完整源码与BAT保留在本地冻结包，不用服务端Git自动Source code包替代它。
附件只包含本批源码档案、知识、检查证据及明确列出的客户端增量资源。没有新EXE、整张DBC、SQL、服务端程序、现场dump、账号/角色数据或未验收家园源码。已安装且测试成功的用户无需重装、重导SQL或再次编译。未经核对后续改动，不整体回盖旧文件。
固定上游来源STRHercules/wowdecomp@601c8bbc3243920d92fa45cff3bc9472202fd0db；修复期间上游网络读取失败，不能称为最新上游核验。本轮发布前已成功fetch项目wowshub；功能依据现场与本地源码定位。
