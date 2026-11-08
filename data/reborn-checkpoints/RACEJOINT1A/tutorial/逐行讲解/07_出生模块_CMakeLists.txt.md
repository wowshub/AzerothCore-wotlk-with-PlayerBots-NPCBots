# 出生模块_CMakeLists.txt：逐行讲解
新模块全文件逐行。Profile定义契约，Synchronize只补缺，CMake注册模块和配置；不是通过登录重复发装备。
来源：`A_服务端_Codex/交付/01_覆盖到源代码根目录/modules/mod-reborn-coa-birth/CMakeLists.txt`。以下行号是所附原件的真实行号；空行/注释也保留。

## 原代码
```text
AC_ADD_SCRIPT("${CMAKE_CURRENT_LIST_DIR}/src/RebornCoaBirth.cpp")
AC_ADD_SCRIPT_LOADER("RebornCoaBirth" "${CMAKE_CURRENT_LIST_DIR}/src/loader.h")
AC_ADD_CONFIG_FILE("${CMAKE_CURRENT_LIST_DIR}/conf/mod-reborn-coa-birth.conf.dist")
```

## 一行一行读
| 原件行号 | 代码 | 大白话解释 |
|---:|---|---|
| 1 | <code>AC_ADD_SCRIPT("${CMAKE_CURRENT_LIST_DIR}/src/RebornCoaBirth.cpp")</code> | 让AzerothCore模块构建收录RebornCoaBirth.cpp，否则仅有文件不会自动注册业务回调。 |
| 2 | <code>AC_ADD_SCRIPT_LOADER("RebornCoaBirth" "${CMAKE_CURRENT_LIST_DIR}/src/loader.h")</code> | 让AzerothCore模块构建收录RebornCoaBirth.cpp，否则仅有文件不会自动注册业务回调。 登记加载器声明和AddRebornCoaBirthScripts入口，生成模块统一加载调用。 |
| 3 | <code>AC_ADD_CONFIG_FILE("${CMAKE_CURRENT_LIST_DIR}/conf/mod-reborn-coa-birth.conf.dist")</code> | 把dist配置登记到模块配置加载清单，解决有conf文件但未被运行时读取的问题。 |
