# WD137B诊断记录
上游复核2026-10-08固定提交bf9a292ba8a55a7315957434e1fed1ec1d3472d9，读取Completion/Brewing；Issue2869 closed，PR4753已合并e17d84e40c219569f54f90945b99be6736255a57。源码存research，不把关闭状态当本地验收。
采用项目trace-and-port-coa-spell-resources Skill；重新读取WD96A/memory.md（原3.3.5客户端清movement位、服务端条件限制），本次修正遗漏客户端八rank标志。当前XA与ZA的Spell完全相同，使用当前ZA资源并集保留14份未改文件；服务端独立DBC不交付、不修改。
源码比对只读，不触及Claude/DC/playerbots工作树。WD137A用户报告移动施法失败；此前离线测试覆盖不足，不登记通过。本包等待新复测，发布仍待用户确认。
