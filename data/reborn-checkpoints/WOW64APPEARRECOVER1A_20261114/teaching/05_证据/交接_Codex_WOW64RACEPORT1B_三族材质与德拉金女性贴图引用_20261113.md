# WOW64RACEPORT1B 候选交接（未实机）

包：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261113\codexfix_20261113_阶段WOW64RACEPORT1B_三族材质与德拉金女性清晰度候选.zip
SHA256：f3aff026931b11325ea770a47d00c70d4ba7573240620cfde8ba037195c7a059
EXE：b71bf56fef279cd3888323430074f4b109c05cf3a398ff9b101ebe51ca0d6cec
README：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261113\codexfix_20261113_阶段WOW64RACEPORT1B_三族材质与德拉金女性清晰度候选\README.md

用户原任务：机械侏儒67缺臂/白眼、德拉金99男性白膜、蛇人36绿白膜；追加99女性皮肤低清。本批全部纳入候选，不能把前批1A装上等同用户已验收。
基于当前已安装1A EXE 45a4837a…；保留25累计源，本批仅EsteriaAppearance.cpp与RebornCatalogAppearance.h有新改动，两个源码输入与A发布清单一致。没有部署或写运行端、生产SQL、提交推送。

实际结论：
- 本地历史Skill早已明确type8取CharSections第0类tex2，type1合成与高清完整图不是同一个通路。36主表只有10条旧行，type8引用空；YB的CharSections.dbc1-race14有36条有效覆盖/新增行，新x64尚未加载通用WXL追加。此包在当前主表合入这36条（6覆盖30新增），不声称通用WXL加载已完成。Claude男女蛇人M2哈希未变，skin、UV2、骨、Bake无写入；不发蛇人模型，因此无需模型变更guard。
- 99女性当前模型确为custom/kobold/koboldfemale；body-N 512x512是合成底图，extra-N 1024x512包含头耳细节。16条base行tex2从body改为extra。未换造型、未把扩大像素冒充高清，原图PNG取证在工作目录。实际效果待测。
- 99男性真实token DrakkinAlliance，与Donor66不同。精确私有目录加49条type12身体绑定，女性不接此目录；245种组合生产头校验通过。保留原TarasekM2。
- 67 token Mechagnome，Donor原生67却是Drakkin，已绕开错误规则。原M2存在完整手臂组301（离线顶点范围核对），修复原生选择；眼动态槽改为项目既有显式眼贴图，原有顶点、骨、动作、UV均逐字节不变。高级部件/所有眼色没有因此移完。

离线：完整Release x64编译链接通过；165引用实际读取解码通过（编码3用BGRA），245组合适配头检查（/UNDEBUG），ZIP每项读回一致。机械模型更改严格限制材质定义和type5替换索引，其他原字节一致；其他种族主表原行保持。候选主表输入dca9e622713c71aa72ac1bc3a34eaed4c9193a4f02bedebcd2ad13c1c5449c1d，输出246f699c7740a4f57eb666919e157d81414f82910978653e5e2ddc46ba81ff03；协作变动后不能旧表覆盖，先重合并。

注意原始审计脚本曾有16MB读取上限，机械侏儒18/20MB被误跳过，现已放宽128MB并从YI取全，不能把早期null称为缺模型。ChrRaces ClientFileString是列11，列14为本地名，最终token已独立读回。BLP编码3不能用Pillow默认解码失败来认定客户端不兼容。
上游本轮fetch固定857364328d90877b508db1eadc20fe7cfc175c99，无新引用，无整分支合并。V2只扫描上一阶段已校验Client6抽取档案，未声称全V2搜完，不需要新模型来修这条已确定的女性贴图错引。

已读项目AGENTS/rule/ref/skillsAscend；audit-and-port、coordinate、port-coa-race-appearance-wxl、overlay-armor-on-nonstandard-uv-race-models；协作/共享台账；F/G/A交接、Claude蛇人v8交接、RACECLASS1B历史失败记录。出包前复查根交接与协作尾表无新冲突。完整说明与回退见包README，脚本/哈希在checks。

请测试三族男女：冷启动创建、肤色切换、T7/T14/NO、选角、进世界、变形退出，保留Claude蛇人衣服效果。当前未游戏实测，不更新为成功Skill；枪弩/理发/全动作/退出卡死仍不自动通过。
