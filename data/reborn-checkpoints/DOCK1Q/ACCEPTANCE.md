# DOCK1Q 收纳图标不再闪现 验收记录

- 日期：2026-10-16；开发：Claude；验收：用户。用户原话："不出现了……这个修复通过"。
- 现场插件 `RebornDock.lua`、`RebornDock.toc` 与候选包输出逐字节一致。
- 内容：快捷方式类收纳（SpellDraft 法术书按钮等）的原按钮被别的插件重新设成可见时，立即改回透明、不可点击；登录后前 10 秒每帧接管。
- 未单独验证：战斗中 SpellDraft 切换模式的情况。
- 私有仓库 wowshub/reborn-dock-addon `a6908bb8`。
- 候选包：`000Ascendupdate/000Ascendupdate20261016/claudefix_20261016_092321_阶段DOCK1Q_收纳图标不再闪现`。
