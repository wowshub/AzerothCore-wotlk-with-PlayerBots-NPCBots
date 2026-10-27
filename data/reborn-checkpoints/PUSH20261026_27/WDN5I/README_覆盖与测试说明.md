# WDN5I 两处服务器红字修复候选
仅覆盖两份源码，在已安装 TG24B＋WDN5H 上修补；不需要重装 TG31A 客户端，无 SQL/DBC。

1. 备份当前源码。checks/manifest.json 的 before 必须与覆盖前文件一致；如不一致先合并，不直接整文件覆盖。
2. 01_覆盖到源代码根目录 合并到日常源码根目录。先覆盖，再编译，中间不要插其他编译。可运行项目已有“编译前运行_更新已修改文件时间.bat”避免旧对象跳过重编。
3. 用户编译部署并重启服务端。本包没有 EXE，未替用户部署或修改运行配置。
4. 观察新的日志区段：不再新增 Missing property RebornBotTelemetry.NpcBotRezLog 和 _MeleeDamageUpdate(): NIY myclass 21!。旧日志不会被清除。

可选诊断：在 configs/modules/RebornBotTelemetry.conf 加 RebornBotTelemetry.NpcBotRezLog = 1，再重启，可观察 NPCBOT-REZ / NPCBOT-REZ-CAST；0 表示关闭，修复后缺省也关闭且不刷警告。保留已有治疗日志设置，不覆盖整份配置。

修复内容：三处 GetOption<bool>(key,false,false) 禁止可选项缺失警告；巫医职业21明确使用原默认分支的0/0近战属性系数。基础AP、装备AP与其他职业及未知职业报警保留。这不是把巫医伤害设为0，也没有修改复活触发条件。

验证：两份实际源码 MSVC /Zs 语法检查通过（bot_ai.cpp 仍有原有数值转换警告）；精确差异与原件哈希复查通过。完整编译、服务端运行、游戏测试：未运行。
坦克死亡后的清本联动、战斗阻挡复活、面板记录状态不一致，仍待当前副本测试；本包不宣称解决。

来源：Claude交接_20261027_TG24B_WDN5H与TG31A安装测试.md；当前Config.h/GetOption第三参数showLogs与Config.cpp实际实现。在线fetch wowshub成功，基线见manifest。CoA查询HEAD dcfa377561e586d45f6d751cc656e0128c91fba2，同路径NpcBots/bot_ai.cpp不存在（404），NpcBotRezLog相关Issue/PR搜索0条；这是本服NPCBot适配遗漏，未声称照搬上游修复。
回滚：只有当前文件仍等于manifest.after且没有后续修改，才可恢复backup_原文件并重新编译；否则先合并。
