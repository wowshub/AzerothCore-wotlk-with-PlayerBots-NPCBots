

## 2026-10-06 小技能/小功能验收、提交与版本发布规范

用户要求后续统一采用：逐项测试记录 → 用户确认范围 → 核对源码/资源哈希 → 更新每日记忆、技术Skill及同名Tutor/两个索引 → 按授权commit并推送 → 最终已验收提交关联tag与Release资源。
实施必读 [release-tested-reborn-features](beascendskills/release-tested-reborn-features/SKILL.md)，配套 [Tutor](beascendtutor/release-tested-reborn-features/TUTOR.md)。每项功能保留候选/基本通过/专项通过及提交/推送/tag/Release不同状态，不把一次总体通过扩大为所有数值或矩阵。相关小功能可同批提交，不强制每技能一个commit。
自有SQL用data/customfixsql按world/characters/auth及功能阶段分类，上游SQL留data/sql/updates；源码、客户端文本、清单与验收记录入Git，DBC/BLP/MPQ等资源ZIP作为Release附件并记录SHA256，原交付包不改写。
目标远端核对wowshub，不误推origin/lisancth；仅暂存本次白名单，不reset/clean无关修改。提交编号必须取实际Git输出。A+B最终标签指向已验收B，Release附件包含全部匹配资源。
当前分工沿用用户选择：助手按明确请求完成commit/push，并提供准确两条tag命令、可点击源码链和Release正文；用户自己打tag和发布Release。未来用户明确授权代发时可执行，不把本流程解释为反复索要确认或自动获得全部发布权限。未读回发布结果不记已发布。
