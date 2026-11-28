# 给新对话框：新种族移植窗口收尾交接（2026-11-28）

## 从这里继续

工作区 D:/000rebornWOW/000RebornWOWHighForkPRO。先读AGENTS.md、ruleAscend.md、协作说明_并行开发.md、开关文件清单_会改变行为的文件和设置.md，再读新Skill：beascendskills/port-wow64-playable-race-end-to-end/SKILL.md。它带本窗口失败台账及可复制的preflight检查表，同名Tutor也已建立。

用户现授权：“之前的所有修复都测试差不多了，commit并推送，结束窗口，整理Skill和新窗口交接”。本次只收尾，不新增种族。最终总体基本通过，不补造所有职业/性别/动作矩阵专项。女鱼人头盔按“先这样”接受现状；旧失败包保留原字节，不得重新装成最终版。

## 最终现场与来源

- 当前真实启动客户端 C:/000ref/WarcraftXL试装_client/WowClient64.exe。2026-11-28只读核对SHA256=16f87cc54afd24eef7b824143b96c30d21816890bbc41684ca4ce07b190f4a0d，等于STARTFIX1F最终成品。没有重新替换或部署。
- 客户端累计源码：20261126/codexwork_STARTFIX1B/src 为前置，加20261127/codexwork_STARTFIX1F/src的M2Model.cpp/h和RetailRace.cpp。新发布checkpoint/client-source/src已按文件并集归档。必须保留EsteriaNativeEquipment.inl、RebornNeutralClothing.inl同目录实际版本，不可再回落Titan旧include。
- 熊人50男女共用YI Character/Furbolg/FurbolgRace.m2与FurbolgRace00.skin；最后用STARTFIX1D，含1C坐姿/地面表情修正及追加披风。不要用1B/1C旧单M2覆盖披风。
- 魔古123：男最终1D恢复V2.03；女1I模型/私有图集配1J格式修正（12张palette BLP字节10=8）。1A/B/C/F/H早期错误脸图不能替代最终组合。十个经典职业以1G实际WORLD物品兼容版为准，1E缺物品SQL已淘汰。
- 鱼人121男女DK符文熔铸53428/776/SkillRaceClassInfo936已明确通过；原登录补技能与类资格在服务端覆盖源码快照。泰坦91DK开放在累计源/资格档案中，总体通过不代表所有配方/任务完成。
- 流放岛slot13/zone141：WORLD联盟map12261、部落12369两路用户已核，旧characters CHECK只到140才是最终建角失败根因。STARTFIX1C同时迁移character_reborn_birth_route与character_reborn_neutral_origin，保留旧DK0/旧存档，未来已正常注册种族复用141。用户明确已建角进入成功。错误看Errors.log3819，不再让用户反复编译同一核心。
- 熊人坐姿和NPC对话：已明确不陷地。按实际lookup/owner对根平移与动作包围盒做局部修正，站走跑原轨道保留。
- 龙希尔27→retail52/70：1E减骨骼局部Z失败；1F在当帧骨变换后加actor空间(0,0,-.55)，仅FormDragon已收Staff/Stave，保持角度比例/局部矩阵；旧API默认零，复制frame保留offset，换父/销毁失效。真实Tempest20×100矩阵及筛选夹具通过，现按总体基本通过登记，不扩大所有武器动作。

## 仓库与发布方式

正式目标wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots，分支threemodelcardpro；收尾基线5aabe8f3a068d81d01b6a2a044a172c26bec2e17，保留Claude HARANDAR/建筑发布祖先。新窗口仍先fetch，不能从旧主工作区43eb71d直接推送。

依照已有WOW64RACES_20261124正式惯例，本次提交精确的已测客户端/服务端覆盖源码快照、必要自有SQL、检查脚本、清单和知识；公共核心没有被旧完整CPP反盖。主线仍有先前中立/双形态/体型依赖未完整移植，checkpoint源快照不是在任意新核心上一键覆盖可编译的承诺。需要做正式主线整合时，独立按依赖提取差异并验证，不把本次源码归档说成整套核心已合并编译。

已测用户无需重装或重跑SQL。此次未部署客户端、未替换worldserver、未执行生产SQL、未改启动器。

## 旧失败和下次必须提前规避

1. 贴图槽/UV/原生装饰先核NO，再核T7/T14；先真实引擎BLP编码，不只通用解码。
2. 实际include闭包与累积对象要固定；新目录缺inl会静默回退旧种族配置，编译仍成功。
3. 头盔位置/尺寸/资源变体分开；武器按剑斧双手锤杖长柄类别，不逐把补item。
4. 挂点方向过真实骨/人物/视角矩阵，用倒置骨反例，不把局部z减小当人物向下。
5. 披风要真实网格/type2/opacity/材质/所有LOD；不能只改geoset。根动作要测过渡与对话，不只坐稳。
6. WORLD有出生路线≠CHARACTERS事务能存；检查协议/路线/Map/数据库约束与日志appender。
7. 出生物品检查目标WORLD与可穿资格；SQL字段依实际schema；已有安装不可盲重跑。
8. 首次相机与异步加载需要空数组/索引负例，第二次正常不能当解决。

## 待开发或未完整验收

本阵营原版职业任务是以后所有新种族必须覆盖的范围。仍需沿交接_Claude给Codex_新种族职业任务开放_20261126.md逐族审计，不能因本次总体通过就抹掉既有缺口。全装备/肤色/动作、观察者/机器人/PvP、DK配方/任务、死亡遗骨等沿新Skill检查表按新工作范围验证。不要先要求用户复测已明确通过的同一现象，应先做批量静态/矩阵/数据库与资源完整性检查，再集中交付最终实机验收。

Claude已验收的28个建筑overlay与RetailCasc.ini中wmoindoor注释保留，不再恢复早期对照配置；含零售缓存的SLIM等不属于本次发布。不开新任务、不发消息给其他AI。

## 本次文件

阶段目录：D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261128/release_RACESESSION1。
正式Git归档路径：data/reborn-checkpoints/RACESESSION1_20261128 与 data/reborn-knowledge/race-session-20261128。
最终提交/远端/标签/Release与附件digest以该阶段publication.json为准；未成功前不写已发布。

本窗口文件并集资源：reborn-race-session-20261128-resources.zip；SHA256 2b9f699958ae64ba1c96d07252d7dfa54a07bcb0e7482185971df083aed1df57，31767970 bytes。它是有20261124底座环境的恢复档案，不是空服一键安装。

## 收尾结果

源码/SQL/检查脚本/Skill/Tutor/交接归档提交：48297f1533972121d3c88bfb63e0b31831d6c4ab。
目标wowshub/threemodelcardpro，push后ls-remote已确认同SHA。保留Claude5aabe8f3a0祖先。此次没有运行生产SQL或部署程序。

用户明确请求的commit/push已完成。额外附注tag与包含约32MB资源的公开GitHub Release，被自动审批以“当前请求未授权公开此具体资源包”拒绝；命令未执行，未重试或绕过。没有tag、Release或资源上传，不能把本批写成GitHub Release已发布。如以后要公开上传，须先获得用户对此具体资源包及目标的明确授权。

资源包保留本机：000Ascendupdate/000Ascendupdate20261128/release_RACESESSION1/reborn-race-session-20261128-resources.zip；SHA256=2b9f699958ae64ba1c96d07252d7dfa54a07bcb0e7482185971df083aed1df57。当前已测用户无需重装。源码快照归档不等于公共核心全部依赖已直接合并；下一窗口按NEXT-CHAT继续。
