---
name: repair-wow64-race-helmet-fitting
description: Repair WoW64 custom-race helmet missing-resource cubes, incorrect head attachments, and undersized helmets using verified model paths and per-sex skeleton profiles. Use for helmet fitting, not body texture or robe coverage faults.
---

# 自定义种族头盔适配

先固定当前累计客户端、MPQ 优先级与实际种族/性别/形态。遵守项目协作登记，保留对方最新累计改动。

## 分开诊断三个层次

1. 蓝白方块：查实际请求的头盔资源路径、种族/性别后缀及胜出的 MPQ。不要拿缩放掩盖缺资源，也不要以隐藏头盔作为修复。
2. 脖子、背后或双头中间挂载：核对人物模型 attachment 11、lookup、实际 head keybone 6、挂点所属骨骼及模型坐标系。对应性别供体的 head-to-crown 差值可参考；骨骼编号不能跨模型照搬。
3. 位置正确但嵌进头内：独立检查头盔实例比例。只调挂点坐标不会放大头盔；按真实种族、性别和骨骼指纹建立尺寸配置，禁止把人物整体放大来补偿。

## 实施约束

- M2 定点修复先校验整个输入 SHA256、记录范围与原值，只改确认的 attachment 坐标，保留其余字节。文件路径含 Female 不代表实际使用角色是女性。
- 运行时修复只操作 ATTACH_HELM 实例，在父模型加载且骨骼匹配时调用 SetAttachmentFrame；使用绝对尺寸，重复刷新不得累乘。不要改共享 mesh 或子模型世界矩阵。
- 头盔缩放和 crown 偏移要共同校准。无头盔、变形模型、未加载父模型、非目标族和肩甲应保持原行为。
- 双头模型需明确一个头盔挂在哪个头，单侧正确不等于实现两顶头盔。
- 供体路径修复、挂点修复、尺寸修复分别记录验收。选角、建角、装备窗口、幻化缩略图和世界人物是不同入口，不能凭一个入口宣称全部通过。

具体参数、失败经验与验收边界见 [HELM2B/C 记录](references/helm2bc-20261115.md)。配套教学位于项目 beascendtutor/repair-wow64-race-helmet-fitting/TUTOR.md。

2026-11-16 德拉金99男女所测头盔资源已显示，但尺寸仍被用户要求继续优化；只记录资源显示改善，见[限定反馈](references/drakkin-resource-20261116.md)。男2.0/女0.90不能收为通过的尺寸参数。

## 验证与累计编译

至少检查重复刷新、装卸、多款头盔、男女和转头动作。自动测试验证代码保护，不替代用户视觉验收。复制源码保留旧时间戳可能让增量编译跳过文件：核对日志里的实际编译项和最终 EXE 哈希。累计包中的家园等其他功能不继承头盔验收。

## 2026-11-16最终累计反馈

见[本轮方法与限定验收](references/final-fitting-20261116.md)。历史候选记录保留；本轮最终参数/生命周期覆盖此前候选，不把总体反馈扩成所有装备专项。
