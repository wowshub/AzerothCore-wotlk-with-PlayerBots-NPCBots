# WOW64RACEPORT1D 机械侏儒缺臂回归修正（候选，未实机）

用户截图：C机械男猎人、机械臂2/4无双臂，B有臂；眼镜已显示。C的320部件选择夹具只验证ID选择，未验证SKIN实际三角形，不能称完整可显示检查。本轮修正该漏检。

包：D:\000rebornWOW\000RebornWOWHighForkPRO\000Ascendupdate\000Ascendupdate20261113\codexfix_20261113_阶段WOW64RACEPORT1D_机械侏儒四档手臂与腿脚几何补齐候选.zip
SHA256：ad60873465172c88689148bb5de42c40d1d22e2f6d1752b8ddbea27f4cdffb44
安装详见包内README：C之后追加根目录1 BIN + YI男女2 SKIN；保留C EXE/M2/眼材质/眼镜目录和其它累计。无运行端写入、服务器SQL、提交推送。

实际根目录几何目录与YI SKIN均已只读核对。male/female 的302/303/304/502/1002均有顶点但indexCount=0；B强制301遮盖问题，C开放选项暴露空面。YI原装collections_mechagnome_mg_m/f完整有对应2902/2903/2904/3002/3102。按位置+法线+UV1映射三角面到现有native lookup，目标重复项权重/SKIN骨索引/UV2一致才接受。只追加索引并修正5section索引字段，M2/顶点/UV/骨/动作不变。完整起点超过65535，使用当前C原生已有M2WideIndexStart高16位机制；不适配32位。

原生M2Shared优先EsteriaSkinBlob，CatalogFile优先MPQ Esteria目录后根目录回退；全Data MPQ扫描无几何目录覆盖项。必须同步根目录EsteriaAppearanceGeometry.bin中的两行，保留其余24行，不能仅改MPQ SKIN。

通过：男女10部件39000/38112新增索引；原始可绘制section原字节/原索引不变；源目标三角面属性绕序相等；重复deformation/UV2无歧义；目标SKIN bone properties到模型骨调色板边界有效；26目录行及其余24字节保留；便携脚本重建相等；ZIP成员读回相等。未实机，不把这些写为游戏验收。

基线：C EXE f9321d611474bbbef7eaa1289a98c37eb4f06e762e82e38cb95ecc8773bb1a94。出包前EXE、根目录BIN、男女M2及SKIN仍匹配读入；协作尾表和最新交接无新增冲突。其它空cape/附件组未处理。

待用户：男女四档臂、两档腿脚与动作；保留眼镜/眼睛且切回无残留；T7/T14/NO、保存重登。出包和安装分开；未自动安装。回退须BIN+两SKIN成对，回到C缺臂，不是已通过版本。

实际读取：项目AGENTS、rule/ref/skillsAscend、并行规范与coordinate技能、audit-and-port技能、port-coa-race-appearance-wxl与overlay技能；本轮C/B/1A及Creator相关交接，协作表/共享台账，C/B冻结包与当前实际原件；来源与原生加载函数证据在codexwork_WOW64RACEPORT1D。永久Skill不把此候选晋升为成功；下次必须检查可选组有非零三角面、匹配批次/骨边界和有效内嵌覆盖输入。
