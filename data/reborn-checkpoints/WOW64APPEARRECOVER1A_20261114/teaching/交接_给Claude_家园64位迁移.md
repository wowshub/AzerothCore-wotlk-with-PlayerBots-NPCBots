# 交接给Claude：我方家园功能迁到WOW64（2026-11-14）

用户本轮明确：家园可以让Claude负责，给Claude交接，由用户亲自转交。本方没有直接发消息或改你的家园源码。请先按规范登记占用，再开展独立候选。此文不是要求把供体家园替换现有玩法。

## 目标
将32位客户端我方家园/WXL依赖的功能移到当前64位客户端，保留现有购地、收费、权限、摆件与玩家存档。先完成一个物件“列目录→预览→放置→移动旋转缩放→保存→重登读回→收回”的最小闭环，再分批扩功能。旧32位DLL不能直接加载到x64，不要照搬地址补丁。

## 已知基线与历史陷阱
- 客户端路径D:/000rebornWOW/000RebornWOWHighForkPRO/beascendclient/newrebornWOWli20261107beAscend。最初稳定EXIT1E SHA25660621732c92b7fecb0ac4c8349a00749f160b4bf2f1d7827dd57cdf05a247de7，最新本方读回已是你的CAPEDIAG1B 62965b1a506e2b2b5df9ffdcf5c0d21fc2705a485ae02fcb738e02c986ca4fce；继续开工需重核，不能认为此值永远最新。
- Codex累计客户端源码：D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261110/codexwork_WOW64BUILD1B/source。你的EXIT源码在20261113/claudework_WOW64EXIT1A/source；下次累计保留Client.cpp、SoundInterface2ZoneSounds.cpp、MinimapFrame.cpp三个已通过修复以及后续双方登记改动。
- 当前该build-x64/CMakeCache.txt明确WOWDECOMP_EXTENSION_HOUSING=OFF、WOWDECOMP_RETAIL_ASSETS=OFF。供体Extensions/Housing/src/Housing.cpp及HousingWire.h/README.md是Esteria的另一套协议，不能只把开关改ON。
- CRASH1A历史实际证据：供体家园客户端发0x537 HELLO、正文6字节、包头size10；当时我方服务器NUM_MSG_TYPES=0x51F，拒绝并断开。禁用该供体扩展是当时兼容措施，不是已把我方家园迁完。当前服务器范围需重核，不能沿用旧数值作无条件结论。
- 供体文档称私有0x537..0x53E及CVar housingEnabled；代码与文档可能时间不一致，必须读实际自动发包入口。不要通过放宽WorldSocket合法性校验“兼容所有未知包”。先能力协商，服务端未支持时不发送该私有包。
- 我方旧资源入口D:/000rebornWOW/000RebornWOWHighForkPRO/beascendmodules/大头冬家园系统/Extensions及Patch-Housing.MPQ目录。日常服务端在beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots；本方只按模块目录名过滤未发现独立housing模块，不能据此说家园源码不存在，你的现有整合可能在其他目录。请按函数/命令/已发布提交找真实归属。

## 逐项迁移清单
|阶段|检查与实现|通过门槛|
|---|---|---|
|HOME64-A|只读列旧32位WXL扩展、ImGui/Lua API、服务端.home命令/协议、表与收费/权限|每项都有文件和函数；明确已测/候选/未知；不触生产数据|
|HOME64-B|客户端原生桥与安全握手、关闭能力默认静默|未支持服务器不被踢；退出/切角色清队列；主线程不阻塞|
|HOME64-C|一个已知旧家具模型与DBC资产闭包|64位能预览并真实放置，无白绿模，不能只看静态图|
|HOME64-D|编辑/保存/重登/收回、版本号与拒绝/重试|服务端权威；重复点击不重复放；超时不扣两次；访客不可编辑|
|HOME64-E|购地升级/权限/库存价格/历史与恢复|保留旧库含义；隔离DB测试；用户执行生产SQL|
|HOME64-F|床椅、中文字体、拖拽/缩放/缩略图缓存、批量场景|断线/取消/重登/多玩家/大场景回归|

## 交叉开发边界
Codex继续种族外观/双形态，真实狼人16、龙希尔27、虚灵109，不按供体编号改存档。你改客户端公共文件前请登记具体函数，给独立差异/新包；不要把你的整树旧版本覆盖Codex累计。种族M2/skin/UV2与原生RebornNative目录不是家园迁移的附带清理项。你自己的披风候选按最新SETHCAPE登记，不由本方代宣布验收。

## 必须避免本次事故重演
根目录EsteriaOff.txt已由Codex改名停用，用户冷启动确认白模与机械臂“全部恢复了”。开工先读《开关文件清单_会改变行为的文件和设置.md》，确认它仍不存在。若要测试housingEnabled或音频/插件等开关，先登记作用、副作用与编号撤销步骤；当轮自己核对已恢复。禁止把关闭外观时的测试结论继续用于模型修改。

## 交付给用户
每天独立目录、源码覆盖包/资源增量/哈希/准确原基线/回滚条件；默认用户编译部署、SQL由用户执行。未实机写未实机；不在“可登录”名义下宣布家园全功能完成。验收后再按Skill更新/分项提交，发下一批前核对Codex最新源码。完整32→64清单与本次教学见同日总结教学11附表。
