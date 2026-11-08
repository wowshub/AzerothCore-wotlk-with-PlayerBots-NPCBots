# 出生模块_loader.h：逐行讲解
新模块全文件逐行。Profile定义契约，Synchronize只补缺，CMake注册模块和配置；不是通过登录重复发装备。
来源：`A_服务端_Codex/交付/01_覆盖到源代码根目录/modules/mod-reborn-coa-birth/src/loader.h`。以下行号是所附原件的真实行号；空行/注释也保留。
## 函数和接口先读表
| 名称 | 在这份文件中的作用 |
|---|---|
| `AddRebornCoaBirthScripts` | 向模块加载器注册PlayerScript，同时报告配置开关 |

## 原代码
```cpp
void AddRebornCoaBirthScripts();
```

## 一行一行读
| 原件行号 | 代码 | 大白话解释 |
|---:|---|---|
| 1 | <code>void AddRebornCoaBirthScripts();</code> | 声明脚本注册函数的签名；具体实现位于cpp，生成的加载器据此调用。 |
