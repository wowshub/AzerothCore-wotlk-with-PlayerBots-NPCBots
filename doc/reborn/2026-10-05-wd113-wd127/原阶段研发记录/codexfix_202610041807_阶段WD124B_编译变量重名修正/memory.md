# WD124B 阶段记录

用户在编译 WD124A 时报告 `'wanted': redefinition; different subscripts` 和 `modules.lib` 找不到。检查 WD124A `RebornWitchDoctorAllocation.inc`，第 163 行新加的四项被动数组与第 393 行原有八项数组同名、位于 `AEApply` 同一作用域。前者改名 `supportWanted`，只改它的两处循环，后者不变。`modules.lib` 是前述编译失败的下游链接结果，不单独改库路径。此修正也合入 WD125A。未编译、未实机。
