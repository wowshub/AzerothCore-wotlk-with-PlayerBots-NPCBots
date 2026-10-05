# WD127A 状态

- WD127A 是 WD124A–WD127A 的累计候选包；静态 DBC 校验通过，隔离 MySQL 结果见 `checks/mysql_results.json`。C++ 编译和游戏实测待用户完成。
- 新节点 35051，保存掩码第 99 位，私有被动 9003911。治疗额外加成相对提高 15%，破咒术多作用 8 码内一名友方，GCD 最低 1 秒。
- WD124A 药水投手 35065 位于酿造树顶部两个彩色方形节点正下方的灰色圆形节点；它是被动，不在技能书出现。截图可见但尚未加点。
- 根工程现有运行树未改动；交付覆盖包给用户编译部署。

## WD127B 编译修正

用户编译WD127A报 WD5A::AEIds different subscripts。定义88项但 RebornWitchDoctorTalents.cpp 仍声明86，且两个遍历停在86。WD127B集中以 AEIdCount=88 管理定义/声明/遍历，源文件仅改这两处；其他SQL/DBC/Lua均继承WD127A，未重新编译或实机验证。modules.lib 是上游模块构建失败的连带错误。

