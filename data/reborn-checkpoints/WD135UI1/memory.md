# WD135UI1 记录
基线为blacknight现场Lua、已装patch-ZA(LIGHT8B)、Patch-XA中的SpellIcon。不是从旧WD包整表覆盖。
读取项目规则与资源目录，并应用stabilize-spelldraft-client-ui原位更新原则；图标核查沿用trace-and-port-coa-spell-resources。未使用图标染色冲突Skill的修复方法，因为本次不是染色争抢。
Tooltip先核查真实IsSpellKnown，未学习提前返回，不读取spell超链接。Paint同步隐藏所有未学会图标，不修改安全施法属性/协议/冷却逻辑。补充Idol列表9003953；现场C++ Slot已接受该ID。
client Spell仅9003541字段133从3062改3994；复用现有SpellIcon与贴图。保留全部LIGHT8B文件。没有修改服务器DBC和原客户端，也没有提交推送。
图标是原客户端Totemic Recall美术的复用，并非官方灵魂回收独有图案或新生成美术。整体待用户游戏验证。
