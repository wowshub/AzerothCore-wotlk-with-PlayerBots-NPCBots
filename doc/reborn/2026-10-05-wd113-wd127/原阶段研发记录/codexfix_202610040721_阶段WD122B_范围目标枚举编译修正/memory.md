WD122A 用户报告编译失败；WD123A继承同一错误。两批不得登记编译通过。本次使用项目 trace-and-port-coa-spell-resources Skill，只作源码兼容修复。历史ZIP和实际源码目录未改。

本次在线核对未完成：URLError: <urlopen error [WinError 10061] No connection could be made because the target machine actively refused it>。不宣称上游最新已核对；沿用历史来源只作背景。本修复依据当前本地 SharedDefines.h，不变更技能机制。

# 教学：枚举名字和数值必须同时对上

本次旧代码：`SpellObjectAreaTargetSelectFn(spell_reborn_wd120_brewing::PulseTargets, EFFECT_0, TARGET_UNIT_SRC_AREA_RAID)`。

改为：`SpellObjectAreaTargetSelectFn(spell_reborn_wd120_brewing::PulseTargets, EFFECT_0, TARGET_UNIT_CASTER_AREA_RAID)`。

第一个参数指定筛选目标的函数；EFFECT_0指定第一个法术效果槽；最后的枚举指定这条回调匹配的目标类型。枚举是数字的有名常量，不是可随意拼写的描述。SharedDefines.h 定义正确名称值56；DBC里同一位置也为56，二者才能匹配。没有新增枚举、硬填数字或改变目标规则。

编译器先把源文件生成对象文件，再把模块打包成modules.lib，最后链接worldserver。第一步因名字不存在而失败，后续可能就找不到库。因此先修第一条错误。缺库不是技能SQL错误。

之前静态核对覆盖了目标数值，却漏查符号是否在目标核心声明，这是本次交付遗漏。数字模型和SQL测试不能证明C++能编译。以后新增枚举先查实际头文件定义；不使用被忽略文件的默认搜索结果判断符号不存在，可用rg --hidden。

tools中的Python先复制原文件作为回滚，断言错误名称只出现一次，再按字节替换；分别检查WD122和WD123，避免把后者新增功能覆盖掉。SHA256用于确认文件身份；checks记录双端DBC和头文件证据。没有运行编译器，仍需用户生成解决方案确认。
