---
name: integrate-playerbot-racial-form-lifecycle
description: Add or audit playerbot automatic racial forms while preserving the existing form spell lifecycle and player-controlled forms. Use for AI-triggered forms, not client model or general combat rotation repairs.
---

# Playerbot 种族形态生命周期

## 已验证范围
DRBOT1A 用户2026-10-08确认龙希尔机器人战斗自动变龙。仅基本进战触发通过；脱战、骑乘、颜色、死亡等专项不继承验收。

## 方法与边界
- 读取当前协作说明、TwoForms与PlayerbotAI；只在机器人会话、目标种族、真人主人同组条件接管。不能把真人或手动变形当AI拥有。
- 经已有种族法术320555施法，不直接SetDisplayId，保留TwoForms的光环同步、取消与装备恢复路径。
- AI更新每次最多触发一个动作；成功施放后跳过当次后续动作，失败有重试间隔。控制/骑乘/载具/潜行/其他变形或施法中暂缓。
- AI私有状态记录自己取得的形态；只移除自己开的光环。战斗取消后抑制重加，稳定脱战后再解锁，避免来回抖动。
- 修改共享playerbots前后核对公共API和DC依赖。发布子模块提交到可访问自有远端后，再更新主仓库gitlink；保留其他分支，不强推。
- 不能用“能变龙”证明完整生命周期。候选包留原记录，新验收按用户确切测试范围写入。

来源：[DRBOT1A](../../000Ascendupdate/000Ascendupdate20261001/codexfix_202610011018_阶段DRBOT1A_组队龙希尔战斗变形/README_覆盖与测试说明.md)。[教学](../../beascendtutor/integrate-playerbot-racial-form-lifecycle/TUTOR.md)。
