# MBCRASH1B 验收
2026-10-14 用户确认：“现在 不崩溃了 可以把这次作为一个推送吧”。
范围：原机器人上线/下线/入组场景基本复测未再崩溃。不外推长期压力、全部跨图/竞态矩阵或消除所有悬空指针。
截图仍提示队员未接受副本邀请；LFG资格/邀请流程不属于本次已修复范围。

计算型Unit目标缓存改存GUID，每次Get/LazyGet/RefGet/Format重新解析当前地图对象；Reset清空缓存身份，保留计算间隔并处理毫秒回绕。
仅Value.h/Value.cpp，保留旧NPCB1A与其他Playerbots改动。CurrentTargetValue自带GUID路线；通用UnitManualSetValue未在本次改造。RefGet为借用返回，身份更新须用Set；地图线程契约仍由核心保证。
上游mod-playerbots/mod-playerbots @79bd428115c8f33b74b13de23b133d49c3f75c60，Issue2851开放建议参考，非已合入修复。
https://github.com/mod-playerbots/mod-playerbots/issues/2851

发布前两个现场文件SHA256均与用户验收包输出一致。5个真实C++翻译单元语法检查、30项独立模型/源码/哈希断言通过；模型不是引擎测试。
无客户端、DBC、SQL或资源附件需求；程序由用户自行编译。崩溃dump、日志、EXE/PDB仅保留本地，不入Git/Release。

原候选包SHA256：133143d14152c40b5e6488fdcd1a36f3df8fe37ecf7cca525624051b05a583b2
