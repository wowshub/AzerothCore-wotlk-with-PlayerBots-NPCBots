# WD127E 状态

2026-10-05用户报告WD127D编译std::min/max重载错误及modules.lib缺失。确认目标SpellInfo::RecoveryTime为uint32，而rec/cooldown为int32。仅修改Player.cpp与RebornWitchDoctorTalents.cpp各一行，显式int32模板参数并在减法前转为int32。WD127D代码首次交付漏检此编译类型错误。

MSVC独立/Zs旧表达式复现同样4个C2672错误；新表达式退出码0，10项静态断言通过。没有编译完整工程、生成EXE、部署生产文件或游戏实测。客户端两文件字节与WD127D一致。使用本会话已读的trace-and-port-coa-spell-resources Skill，范围为累计基线/覆盖包/证据边界。此次为本地编译适配，没有新技能或上游机制变更。
