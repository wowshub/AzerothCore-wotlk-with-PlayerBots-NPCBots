# 评审：WD142A 三项通用天赋（2026-10-12）

- 评审方：Claude。被评审：Codex 候选 `000Ascendupdate/000Ascendupdate20261012/codexfix_20261012_090601_阶段WD142A_黑暗帷幕与通用双天赋`。
- 按《规范_交叉并行开发.md》v2 第 12 节，只读评审，没有改候选文件和巫医文件。

## 读过的材料
- `RebornWitchDoctorCommon142.inc`（新增，全文）。
- `RebornWitchDoctor.cpp`、`RebornWitchDoctorTalents.cpp` 的改动。
- `RebornWitchDoctorAllocation.inc` 的授予/撤销段。
- `WitchDoctorTalentPolicy.h` 的白名单。
- 角色库 `02_save_rows.sql`：新版保存过程的入参、节点、依赖、预算、删除保护，以及旧入口转译。
- World 库 `01_WD142_world.sql`。
- 服务端 `Spell.dbc` 中 9003962–9003966 五行：属性、触发标志、效果、光环类型。
- 核心对照（只读）：
  - `Unit::CalculateMeleeDamage` 中 `ModifyMeleeDamage` 钩子的位置；
  - `SpellDamageBonusTaken` / `MeleeDamageBonusTaken` 中 aura 271 的判定；
  - `AuraEffect::IsAffectedOnSpell` / `SpellInfo::IsAffected`。
- 三态核对：`01` 内 15 个源码文件，日常源码全部等于包内输入，可直接覆盖。
- **未核对**：
  - 没有重跑 297 项 SQL 和 2 万组差分；
  - 没有编译、链接或进游戏；
  - 没有核对用户客户端 patch-ZA 的输入哈希。

## 总结论：同意，无阻断问题

### 1. 旧入口与删除保护：成立
- `reborn_wd67_save` 只做十进制解码，然后调用 `reborn_wd139_save`。事务、行锁、revision、预算和依赖校验都只有一份，不存在第二套旧校验。
- 删除保护在新版过程末尾：已保存节点在新入参里缺失、或等级降低，就整体回滚。所以旧入口表达不了新节点，也删不掉新节点。免费退点同样被拦截。
- 布局哈希从 `6d8c…`（WD139C）换成 `39c8…`，SQL 和 C++ 两边一致。旧插件会被拒绝，提示更新，而不是误存。
- 依赖：
  - 三项都要求 ≥56 级，且 r0…r73 的通用 AE 合计 ≥24；
  - 洛阿共鸣另要求 ≥58 级并已有黑暗帷幕；
  - `Talents.cpp` 的显示判定（`AESpent` 减去这三项自身）与 SQL 一致。

### 2. 帷幕的 15%：没有重复计算，也没有漏算
- 法术伤害（直接、持续伤害、Pulse 自身）：aura 271 family 0。`IsAffected` 对 family 0 直接返回 true，lambda 要求施法者 GUID 一致，所以只有施放者本人吃到 15%，别的玩家不受益。
- 特殊近战攻击（带 `spellProto`）：走 `MeleeDamageBonusTaken` 的 aura 271 分支。
- 白字攻击（主手、副手）：核心不走上面两条，只有 `CalculateMeleeDamage` 里的 `ModifyMeleeDamage` 钩子补 15%。这个钩子只在白字路径调用，所以和法术那条不会叠加。
- 钩子在 BonusTaken 之后、护甲减伤之前，顺序与 aura 271 对法术的作用一致。

### 3. 周期伤害、共鸣、虔诚：成立
- **Pulse**：
  - 在 `OnEffectHitTarget` 设置效果值，用的是 DBC 基础值 + 10% 暗影法强 + 4.5% 攻强。`spell_bonus_data` 设为 0，法强不会再加一次。
  - 施法者的百分比增伤和暴击照常生效，与 README "经过实际增益结算"的说法一致。
- **洛阿共鸣**：只把 Pulse 翻倍，不影响 15%。
  - 9003964 是被动（attr0 0x40）+ 光环 4，`learnSpell` 会自动挂上，`HasAura` 判定可靠。
- **邦桑迪的虔诚**：
  - 9003965 是被动 + 光环 4。procFlags 0x11154 = 本人白字近战/远程 + 近战、远程、无类别、魔法类的直接伤害，**没有周期伤害位**。脚本里又排除了周期、宠物（`actor != p`）、自伤、Pulse/Heal 和三个已知复制法术。
  - 递归防护用 `executing`；治疗经过 `SpellHealingBonusTaken` 和吸收，不暴击，也不再加法强。

### 4. 撤销与清理：足够
- 撤销帷幕时先 `WD142Bridge::Clear`：只移除本人施放、仍在目标列表里的帷幕，不动别人的。然后撤销技能。
- 共鸣和虔诚撤销时，移除光环和技能。
- Tick 中如果施法者下线、死亡、失去技能、不在同一地图，就移除帷幕。目标死亡时光环自然移除，`Removed` 会清掉列表。
- 共享核心头 `WitchDoctorTalentPolicy.h` 只被 `Trainer.cpp` 和巫医两个 cpp 引用，重编译范围很小。

## 建议（低优先级，不阻断）
| # | 内容 | 谁改 |
|---|---|---|
| 1 | **施法者死亡会移除整个帷幕**（`!p->IsAlive()` → `Remove()`），连同 15% 易伤。如果官方行为是"死后不再跳伤，但减益留到结束"，可以把死亡改成只跳过本次跳伤。请对照官方说明决定，并在验收时写明 | Codex（核对） |
| 2 | 旧入口第 67 位解码成节点 0。节点 0 不在定义表里，这一位置 1 会整次保存失败，这是原有的空位，属预期。建议在旧入口注释里写明 | Codex（注释） |
| 3 | 15% 钩子作用于白字的每个伤害分量，例如武器附带的元素伤害，与 aura 271 对多系法术的效果一致，无需改。验收时可顺带看一把带元素伤害的武器 | 用户测试时 |
| 4 | 虔诚对 AoE 的每个命中目标各触发一次（每次 10%）。与"直接伤害的 10%"字面一致，但群体技能的回血会明显偏高；可在验收记录写明这是有意的 | Codex（记录） |
| 5 | 客户端 `patch-ZA.mpq` 和服务端 DBC 都是累计文件。安装前请核对用户现场文件等于包内输入哈希，本评审没有核对这部分 | 用户/Codex |

## 冲突核对
- 与 Claude 的 DCQ1A/DCQ1B（清本模块）、LFG81A、mod-playerbots 没有文件重叠，可以同一次编译。
- 唯一的共享核心文件 `WitchDoctorTalentPolicy.h` 只是在白名单里加了 3 个 ID。
- DCQ1A 新增了 `.cpp`。如果编译 WD142A 的那棵源码还没为 DCQ1A 重新运行过 CMake，这次需要运行一次；WD142A 本身不需要。

## 需要用户决定的事项
无。第 1 条以官方说明为准。

## 修订记录
- 2026-10-12：Claude 初版。
