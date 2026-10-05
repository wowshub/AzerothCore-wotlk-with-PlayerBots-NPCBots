# WD124B：修复 WD124A 编译错误

WD124A 在 `AEApply` 同一个函数作用域先声明 `bool const wanted[4]`，后面又声明 `bool wanted[8]`，MSVC 报 `'wanted': redefinition; different subscripts`。本补丁仅把前一组 WD124 被动的数组改名为 `supportWanted`，其两处循环也同步改名；旧八项数组保留 `wanted`，逻辑和数据不变。

请在已覆盖 **WD124A 全部源码** 的基础上，把 `01_覆盖到源代码根目录` 覆盖到源码根目录，然后重新编译受影响的 modules/worldserver。`cannot open ... modules.lib` 是 modules 编译失败后链接阶段的连带报错；先看 `wanted` 的首个 C++ 错误是否消失。此包不需要重导 SQL、Lua 或 DBC，也不改已有存档。

本机没有替你编译。修复前后代码差异仅为局部变量名；用户编译通过前不能标为已验证。后续 WD125A 累计包已包含同一修正，使用 WD125A 时无需再叠加 WD124B。
