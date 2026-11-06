# RACE14A + RACE14X1A 验收记录（2026-11-05，Claude）

用户原话："RACE 14A 测试已经可以了"、"没有问题 测试挺好的"（X1A）。验收范围仅为**创建页预览**：14 个 CoA 1.9.9 新种族的图标、点击预览、男女模型、默认皮肤、镜头与背景。**不含**创建开放、服务端数据、出生/语言/声望/特长、身体装备合成（只有武器/盾/肩/头盔/披风等挂载件能显示）、丰富的外观选项（依赖新版 EsteriaAppearance.dll）。

## 编号与阵营（取余32开关规则：同一开关的种族阵营必须相同）
联盟7：Titan 91、Mogu 123、Sureki 86、Centaur(联盟) 75、Fungarian 93、Stormforged 84、Sporeling 76。
部落7：Qiraji 88、Nerubian 120、Dreadlord 89、Wretched 92、Mo'arg 119、Lich 113、Lost One 73。
改号：Stormforged 114→84、Lich 122→113、Lost One 125→73（125 被 HighmountainHD 预览种族占用）、Sporeling 111→76。已删除 Elune's Chosen。

## 包与哈希
客户端包（不入 Git，作 Release 附件）：RACE14A（整表替换方式）与 RACE14X1A（wxl-extended-dbc 追加文件方式，扩展源码见 wxl-reborn 仓库 extensions/wxl-extended-dbc）。逐文件 SHA256 见 manifest_sha256.json。
本提交镜像的客户端脚本（验收版）：CharacterCreate.lua 0df4e7e1c57be07688f5549509e43909f8feb4afb17a7ccc36141a047c49271b（在原版基础上仅第 4342 行加滚动条 nil 保护）、CharacterCreate.xml e3b3643810d3abe999cc9a2b57b8c4329fcffe7058f034b4a7bf2c40fbd215dc、RebornRacePreview.lua 667a4102f7ac43da0667bb3dff8c77406679e17e6ccdb76ff1adf31987a34d44。

## 本次学到的经验（必读）
1. CharSections.dbc 字符串列是第 4–6 列，旗标/变体/颜色在第 7–9 列；把 6–8 列当字符串会把变体写成几百万，造成创建页崩溃与白/绿模。
2. 客户端选种族时会查 (种族,当前选中职业) 是否在 CharBaseInfo 里；缺行就判不可选并随机选种族，随机选择代码遇到种族表的空编号会读空指针崩溃（0x004E0F84 读 0x2C）。新种族必须配与现有预览种族相同的 12 个职业组合（含死亡骑士 6、13、14）。
3. 生物类模型（Creature\...）在本客户端不会用 CharSections 贴图；贴图要么由 Esteria 运行时按种族提供，要么像蛇人那样把 M2 的 11/12/13 号贴图槽改成直接文件路径。我们的 EsteriaAppearance.dll(10-30) 只认 1.9.2 年代名单，故 13 个新种族用直接贴图，其拉人（名单内）保持原样。
4. M2 的"贴图单元查找表"（头部 0x88）为空会在渲染时崩溃（魔古族）；补 256 项零表即可。
5. 肩甲骨头自带的固定旋转不对称会让肩甲朝向反（风暴铸造者女性）；清成单位旋转修复。
6. 预览镜头：CharacterCreate:SetPosition 在本客户端无效；只有借用场景号 sc（场景号=种族按钮序号=ChrRaces 行号）和滚轮上限 zmax/zmaxF 有效。
7. wxl-extended-dbc 可在不改七张 YB 表的前提下追加种族行：`表名.dbc1-项目名` + wxl-dbc.manifest（真 MPQ 必须带清单）+ CharacterFacialHairStyles 需要磁盘上的 `.wxlidx` 旁路文件；客户端测试通过。

## 未验证
服务端（取余32在核心的实现、出生数据、语言、声望）；创建开放；新版 Esteria 运行时；身体装备合成；Dreadlord 男性仍用经典模型（暗影界版靠几何集，创建页默认不显示身体）。

## 工具
tools/ 为本次生成数据的脚本（路径为本机开发路径，仅作复现参考）。
