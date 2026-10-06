# 小技能测试、提交、tag与Release：从一次修复到可复现版本

把源码想成配方，客户端/服务端数据想成材料，实测记录是试做结果。commit给配方版本一个机器编号，tag给这个版本起名字，Release把名字、说明和材料包放到同一处。只有材料也对得上，别人才能复现。

## 一次完成顺序

1. 先测试并逐项记录。WD131两项魔精是在5秒内药水命中后才加状态，只点准备按钮看不到加成不代表代码错误。用户说“两项通过”记基本通过，不虚构30%减伤的完整日志。
2. 对包清单和现场源码作SHA256/逐字节比较。相同文件才可说该源码对应这个测试包。原ZIP保留不重压；客户端和服务端DBC独立生成。源码库保存文本和清单，大二进制放Release资源附件。
3. git status --short看全部变化，再只git add本次确定的路径。git diff --cached --stat看范围，git diff --cached --check检查空白问题，git diff --cached审阅真正内容。不要用git add .卷入别的窗口。
4. git commit -m写清本批行为；Git根据文件树、父提交、作者/时间和说明计算提交编号。git rev-parse HEAD取完整40位，git log --oneline显示短前缀。相同文件重新提交也可能因父提交或时间不同而产生不同编号。
5. git push wowshub threemodelcardpro上传分支；git ls-remote wowshub refs/heads/threemodelcardpro读回核对。同名origin可能是别人的上游，因此不要凭习惯推origin。
6. 最终提交确定后生成两条命令：git tag -a 标签 完整提交SHA -m 说明；git push wowshub refs/tags/标签。附注tag有自己的对象编号，解引用后应是目标commit。A→B时只给B打tag就包含A，不能把标签指到旧A却上传B资源。
7. GitHub新建Release选择刚推的tag，粘贴助手给的正文，上传原资源ZIP和SHA256文件。Markdown格式为[短编号（说明）](仓库/commit/完整SHA)，比较用仓库/compare/旧SHA...新SHA。粘贴时不要连外层三个反引号一起复制。
8. 发布后记录Release URL、tag解引用commit、附件名称和哈希。用户没反馈发布且未读回时，状态仍是“源码已推送，tag/Release待用户操作”。同名tag已有相同目标不重复创建；不同目标先查原因，不能强移。

## 本次实践

WD131A两项用户确认基本通过，母版d2a202bb8（WD130B）。源包codexfix_202610060350_阶段WD131A_双魔精与配料快照.zip，SHA256 31849cfa393f51a7382bb792ad47b33028afa663fdb03f486e473c99eef8a469。18个源码和91个安装文件核验；原106隔离SQL/69组检查与/Zs证据保留，不重新部署。本次提交/标签命令取提交后生成的发布目录文件，不能在尚未commit时猜SHA。

代码/SQL级实现教学见本批原tutor.md；本教程专讲验收与发布。工作流：[Skill](../../beascendskills/release-tested-reborn-features/SKILL.md)。原证据：[WD131验收](../../beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots/data/reborn-checkpoints/WD131A/ACCEPTANCE.md)。
