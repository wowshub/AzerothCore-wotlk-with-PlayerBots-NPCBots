# 2026-10-15 Codex已验收客户端与服务器Data+SQL并集
范围：WD150B（含WD149A/C、WD150A/B、UI10C/E/F）、WD151A/B、WD152A/B最终版本。不能以最后一包替代今天并集；本包逐文件并集，最新双端Spell保留前批记录/说明，SpellIcon/SkillLineAbility累积，SpellRadius保留151，原生UI保留150最终。不是整个客户端或空服务器安装包；适用已安装WD148A及MBCRASH1B的现有完整环境。
已按各测试包安装通过者无需重复安装。新装Characters只执行最终01_node_reference.sql→02_save_rows.sql（WD152A累计含前批），不得再用150/151旧定义覆盖。World依次WD149→WD150→WD151→WD152B；文件分别01_WD149_world.sql、01_WD150_world.sql、01_WD151_world.sql、01_WD152B_world_必须执行.sql。152B完整替代152A世界SQL，无Auth更新，不递归执行其他旧SQL。
02客户端Lua；04服务端Data/dbc；技能资源导入现有PATCH-XA；原生UI两目录分别导入现有Data/Patch-X.mpq和Data/enUS/patch-enUS-5.mpq。双端表不同、不可互换；不能用小ZIP替换整MPQ，不写ZA。停服备份数据库/源码/DBC/MPQ，由用户编译标签最终源码、执行SQL和部署；退出客户端、关闭MPQEditor后安装并完整重启。
无EXE/PDB/账号/玩家数据库/配置/日志。上传GitHub附件不是已部署远程服务器或launcher。远程基线未知时先核对哈希/版本和其他成员改动。新增节点回滚须一致时点角色库及所有配套资源，不能只退程序。
