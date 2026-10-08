# DC0A+DC0B 用户验收 — 2026-10-08

功能：接入 mod-dungeon-clear（上游 https://github.com/jrad7/mod-dungeon-clear ，本地快照，提交号未知；AGPL v3），playerbot 坦克自动领队清副本，`.dc test` 自动测试并写 dc_testruns.jsonl。
用户原话：“还真不错 机器人 真的在打副本 现在P0阶段 我测试的还不错”。此前反馈：编译通过（含链接）；“之前手动可以的”（.dc on）。
登记为**基本实机通过**（P0）。

## 实测证据（测试服 wowshub_playerbot_npcbot_newrace20261008Ascend - botclear 的 dc_testruns.jsonl，14 条）
- 2026-10-07 23:06 祖尔法拉克 L46：success，7/7 Boss，0 死亡，1652 秒，防骑坦克。
- 死亡矿井 L24 三支防骑队伍各 2/7、0 死亡，均因 GM 下线中止（从游戏内发起时 GM 必须在线）。
- 其余：GM 下线 6 次、AccountInstancesPerHour=5 拦截 2 次（测试服 DC0D 调为 1000）、手动 stop 3 次、机器人准备超时 1 次、熊德坦克掉出副本 1 次。无模块自身错误、无团灭。

## 不扩大的范围
未覆盖：死亡矿井完整通关、团队副本（DC0B 的补 buff 回合在本 playerbots 上跳过）、英雄难度、随机本/战场自动补人（默认关闭未测）、NPCBot、巫医/武僧机器人（无战斗循环）、自定义副本内容。熊德坦克明显偏弱（低等级技能 IMPOSSIBLE、普攻 FAILED）。
DC0C（控制台驾驶员账号首次创建重试）与 DC0D（测试服配置）不在本提交：DC0C 未编译测试；DC0D 是运行配置。

## 来源与校验
- 本提交 modules/mod-dungeon-clear 共 482 文件，与 DC0A（文件夹名改为 mod-dungeon-clear）+ DC0B（4 文件）逐字节一致，即用户编译测试的版本。
- DC0A 包 claudefix_20261007_085721_阶段DC0A_机器人自动清副本模块接入.zip  SHA256 f940464e0c1afe116e53ac006260aefcab2c4ea3036784020e2cda4e6d529051
- DC0B 包 claudefix_20261007_191213_阶段DC0B_编译修复_旧版playerbots兼容.zip  SHA256 5fe67b225f4eb25fbcd946cbcaec6180ffc3419ad211899ebbb47b4b46d1a348
- 父提交 a986fc2e2005ebefc1907065933c634251c0fb7c；运行配置 configs/modules/mod_dungeon_clear.conf = 模块默认值（随 DC0A 包）。无 SQL。
