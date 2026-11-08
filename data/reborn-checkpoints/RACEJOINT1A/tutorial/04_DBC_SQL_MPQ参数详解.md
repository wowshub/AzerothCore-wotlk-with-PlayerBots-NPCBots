# 第四课：二进制表和数据库不是一回事

DBC是客户端/服务端读入内存的结构化文件；SQL是操作MySQL表的指令。Lua不是DBC编辑器，SQL也不会自动修改MPQ。新种族贯穿几层，必须配齐。

## 这次究竟改了哪些数据

| 位置 | 表 | 精确范围 |
|---|---|---|
| 服务端根dbc与zhCN | ChrRaces、CharBaseInfo、CharSections、CreatureDisplayInfo、CreatureModelData、CharStartOutfit | 各自独立输入追加39/49资料，共12文件；不拿客户端整表覆盖 |
| YB | ChrRaces | 39/49的flags从12变8，仅清不可玩位4 |
| YB | CharBaseInfo | 只留39/49的战士组合，移除22个其它职业组合；其余不变 |
| XA | CharStartOutfit | 新增934–937四个性别行；保持XA作为该表唯一累计归属 |
| WORLD | playercreateinfo / action / item / player_race_stats | 2出生点+6动作+2食物+2属性=12行 |

flags是开关集合：12=8+4；清位4得到8，保留原位8，不能直接写0把其它标志一并丢掉。最终含义依据当前版本结构，不靠十进制数字猜。

CharBaseInfo回答“哪个种族可以哪个职业”。CharStartOutfit回答“哪个种族+职业+性别穿哪些条目”。男/女DBC键是0/1；Glue原生GetSelectedSex返回2/3，要减2或按已有映射转换。名字键SETHRAK0/1不是说GetSelectedSex直接就是0/1。这个差1/差2特别容易造成“男可以女不行”。

装备行934/935=39男/女，936/937=49男/女。行ID只是这张表的记录号，不是raceID。39使用38、899991、899994、899992、49778、899993、899990、6948；49使用6125、900028、900025、6948、12282、900027、900026、900029。这是当前人类/兽人战士出生模板，不是宣称CoA专属套装。

## WORLD参数逐个读

`playercreateinfo(race,class,map,zone,position_x,position_y,position_z,orientation)`：真实种族、职业、地图、区域、世界坐标XYZ、朝向弧度。39在地图0区域12，(-8949.95,-132.493,83.5312)，49在地图1区域14，(-618.518,-4251.67,38.718)，两者朝向0。它决定出生地点，和创建页背景无关。

`playercreateinfo_action(race,class,button,action,type)`：动作条槽位从0计数；type0是法术动作，128是物品。action6603=攻击、78=英勇打击、117=食物；button72/83是既有模板槽位，不是第72个技能。不要把物品117当spell117施法。

`playercreateinfo_item`给117食物4份，Note用于本批说明；衣服武器主要由CharStartOutfit给，不能在这里再发一套。

`player_race_stats`是种族基础修正，不是60级成品属性。39五项0；49力量+3、敏捷-3、耐力+1、智力-3、精神+2。最终人物属性还叠加职业、等级、装备等，不能只看这行就推断完整角色属性。

## SQL守卫逐层解释

1. 先建临时expected表，装入“本次期望的12行”。临时表只在本次连接有效，不是新建永久玩家存档表。
2. 安装过程先读`COALESCE(@RACENEXT1A_INTEGRATION_VERIFIED,0)`。变量没设置是NULL，COALESCE给默认0；只有用户同会话明确设1才能继续。0表示尚未确认核心/双端资源整合，**不是错误要删掉**。
3. `<=>`是MySQL的可处理NULL相等比较；逐列比期望值，出现未知已有39/49行就SIGNAL拒绝。它不会悄悄把已有数据改成本次样子。
4. 16个必需物品都要存在、AllowableRace=-1、职业掩码含战士位1；少一件或不兼容都停止。
5. 最后才写出生表，NOT EXISTS避免相同导入重复。默认拒绝和冲突检查必须在这些INSERT前完成。

MyISAM不是事务表，不能用“最后ROLLBACK就安全”来兜底；所以先完整检查。这里只读查询角色库占用，写入SQL只给WORLD；没有AUTH或CHARACTERS写入迁移。仅复制SQL文件到服务器不会执行它。

## 安装与回滚

已经测试通过不用重装。新安装遵循原README：备份→同一份源码的A/C覆盖并重新生成/完整编译→部署新程序→根/zhCN各自表和conf→YB/XA按归属增量导入→用户核对并手动运行守卫SQL→测试。

两个包不同路径并不自动避免冲突：YB和XA里同路径表仍会互相遮盖。共享母版先查根目录《台账_YB_XA共享文件哈希.md》并与Claude登记。三个DLL、Wow.exe、家园表不在本批。

创建39/49角色以后，不能随便把核心、DBC和出生记录删回旧版。文件回滚前先确认当前仍是本包输出；有新角色时优先向前修复，或用成对WORLD+CHARACTERS备份恢复。模块关闭不会撤回已学语言；恢复备份也不能覆盖别人后续同文件更新。
