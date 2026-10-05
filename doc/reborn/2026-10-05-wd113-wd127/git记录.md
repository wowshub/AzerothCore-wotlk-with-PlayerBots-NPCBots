# 已提交并推送

远端： https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots.git
分支： threemodelcardpro

- 559fe78fdbeefba87d88c0d29bcbc4be5d6bd693：28项文件，累计巫医模块、核心依赖、最终测试资源归档。
- 8100818d20b1a7d1262627daeb3333ec65cef8c8：归档ZIP强制binary，恢复原字节。最终ZIP SHA256 e68282509364048d9b32009ac07b7c7f14dfa5fb46ae918560856201e4e90417。
- 首轮push实际输出f758d118b..8100818d2，随后独立ls-remote确认同一完整SHA。此前未推送的32095f2e5同时进入该分支历史。

排除并原样保留：ACSoap独立故障修改、shell执行位、PSD、子模块指针、种族Lua备份等非巫医改动。源码工作树因此不宣称完全干净。14份WD127F交付源码与提交前实际工程逐字节一致。只有已有Allocation.inc末尾额外空行的空白提示被单独记录；检查不忽略实质缩进／合并标记。

总结／Skills／Tutor随后作为第二轮文档提交推送；其最终SHA由Git日志和本窗口最终回复给出，避免提交文件自引用自身SHA。
