# 用服务器的账本同步客户端的钟

先区分CD、GCD、读条和buff；再按保存真实值→发送GO→校正客户端计时的顺序理解。

[本窗口完整逐行教学](D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261005/codexsummary_202610050358_阶段WD113至WD127_成功失败教学与交接/tutor.md)的9—14节是本Skill课程，1—8与15—19提供基础和反例。

[验收证据](D:/000rebornWOW/000RebornWOWHighForkPRO/beascendskills/synchronize-wotlk-spell-costs-and-cooldowns/references/wd127f-case.md)。

离线程序通过不等于游戏所有组合通过；原生计时和鼠标数字都要测，不能只看到绿色行变10就收工。
