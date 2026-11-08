# 新族客户端_GlueParent.lua：逐行讲解
只新增39/49识别、同阵营姓名池与选角场景别名，复用此前已验收的职业刷新。
来源：`B_客户端_整合候选/交付/02_MPQ导入目录/导入PATCH-YB/Interface/GlueXML/GlueParent.lua`。以下行号是所附原件的真实行号；空行/注释也保留。
## 函数和接口先读表
| 名称 | 在这份文件中的作用 |
|---|---|
| `SetBackgroundModel` | 选择Glue舞台背景；只对CharacterSelect做场景token别名 |

## 本次修改涉及的实际代码片段

原件第631–637行：
```lua
  local token=string.upper(name)
  if token=="REBORNSETHRAK" then name="Human"
  elseif token=="REBORNOGRE" then name="Orc"
  elseif token=="REBORNKULTIRAN" then name="Human"   -- RACENEXT3A
  elseif token=="MAGHAR" then name="Orc" end
 end

```

## 一行一行读
| 原件行号 | 代码 | 大白话解释 |
|---:|---|---|
| 631 | <code>  local token=string.upper(name)</code> | 定义局部变量：local token=string.upper(name)；值只在当前Lua范围使用，不自动改服务器已学或永久存档。 |
| 632 | <code>  if token=="REBORNSETHRAK" then name="Human"</code> | 条件分支：只有`if token=="REBORNSETHRAK"  name="Human"`成立才走随后分支；不满足进入else/跳过。 |
| 633 | <code>  elseif token=="REBORNOGRE" then name="Orc"</code> | 条件分支：只有`elseif token=="REBORNOGRE"  name="Orc"`成立才走随后分支；不满足进入else/跳过。 |
| 634 | <code>  elseif token=="REBORNKULTIRAN" then name="Human"   -- RACENEXT3A</code> | 条件分支：只有`elseif token=="REBORNKULTIRAN"  name="Human"   -- RACENEXT3A`成立才走随后分支；不满足进入else/跳过。 |
| 635 | <code>  elseif token=="MAGHAR" then name="Orc" end</code> | 条件分支：只有`elseif token=="MAGHAR"  name="Orc" end`成立才走随后分支；不满足进入else/跳过。 |
| 636 | <code> end</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 637 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
