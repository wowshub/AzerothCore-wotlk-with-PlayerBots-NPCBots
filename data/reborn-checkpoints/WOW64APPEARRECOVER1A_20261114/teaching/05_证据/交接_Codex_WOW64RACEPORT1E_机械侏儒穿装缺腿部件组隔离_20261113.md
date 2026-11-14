# WOW64RACEPORT1E 未实机候选

包：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261113\codexfix_20261113_阶段WOW64RACEPORT1E_机械侏儒穿装缺腿修正候选.zip
SHA256：bb3808ccbbb26451f3e770ac2f41c1c589022c0507358ef118bc5db9a66c86f1

# WOW64RACEPORT1E：机械侏儒男女穿装缺腿（候选，未实机）

在已经安装 D 的当前客户端上追加。本包保留 C 眼睛/眼镜和 D 四档手臂及腿脚补面，不换 M2，不需要编译或更换 EXE。

## 安装

完全退出游戏，先备份下面4个同名文件：
1. 将01里的 EsteriaAppearanceGeometry.bin 放到 WowClient64.exe 所在根目录覆盖。
2. 将02里的 Esteria 文件夹导入当前 Data/Patch-YB.mpq 根目录，覆盖 RebornNativeMechagnome.bin。
3. 将03里的 custom 文件夹导入当前 Data/Patch-YI.mpq 根目录，覆盖男女各一个00.skin。
4. 保存并关闭 MPQEditor，再启动游戏。

三部分必须配套。不要导入 backup 或 checks；不用重装 C/D，也不用动其它种族文件。

## 为什么穿装后腿消失

C把源机械腿3001/3002映射到普通靴子部件501/502。原生外观先选机械腿，随后标准装备处理遇到靴子/长袍会隐藏501～599，导致腿被关掉。D补齐了缺失三角面，但未解决穿装时这组冲突。实际当前根目录BIN及两SKIN与D完全匹配，非漏安装。

E把追加的机械腿恢复为独立组3001/3002，脚恢复3101/3102；配套选择目录由group5/10改为30/31。原始重叠默认全腿501改为未选择的3000，由同组选择规则关闭，避免默认腿和改装腿重叠。当前C原生ApplyCatalog支持0～51组，>=19直接选模型几何，所以不用改EXE。

仅8条选择记录和男女各5个SKIN部件编号变化；所有顶点、UV、权重、骨、批次、材质、三角面索引原字节保留，几何目录其余24行原字节保留。

## 验证边界

已完成字节范围检查、D原索引保留、两种腿各有非零面、选择数据一致性、源代码实际处理顺序审查、24个穿装/腿档的离线显示集合推演、ZIP读回。离线推演不是引擎渲染验证。

待游戏验证：男女T14是否完整有腿；T7/NO来回；两档腿及四档手臂；眼镜是否保留；换长袍/靴子、动作、重登是否正常。未实机，不承诺全部装备无穿模。

## 基线和回退

依赖当前C EXE（f9321d611474bbbef7eaa1289a98c37eb4f06e762e82e38cb95ecc8773bb1a94）及已装D资源。输入输出SHA256在checks/离线复现/validation.json；输入不匹配时停止整文件覆盖并重合并。
回退须退出游戏，将backup四文件成对还原到原位置，仅适用于未叠加后续更新；会恢复D穿装缺腿状态。无服务器/SQL/DBC/EXE/M2改动，未部署、未提交推送。


本轮已读项目AGENTS/rule/ref/skillsAscend、coordinate/audit-and-port/port-coa-race-appearance-wxl，C/D交接与协作表及共享台账。当前D根目录和两SKIN逐字节匹配；选择目录输入C已取证。未改运行端/共享源码/服务器。V2与旧中立预览种族清单仍待交付，不因插入此修复取消。

## 新验收记录
用户确认男女穿装腿部问题解决；实装4/4匹配E。已同步原Skill、同名Tutor、skillsAscend/tutorsAscend/tutorAscend；不修改冻结包。顶部“种族→种手”仍未解决，不扩大全矩阵、不推送。
