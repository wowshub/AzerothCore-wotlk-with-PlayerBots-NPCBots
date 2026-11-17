---
name: repair-wow64-model-preview-lifecycle
description: Repair WoW64 custom-race selection fragments, detached clothing and white DressUp previews by tracing asynchronous readiness, skin-parent lifetime and current-model duplication.
---

# 选角与装备预览的模型生命周期

先辨别入口：世界人物、选角、建角、DressUp主模型和缩略图可能创建不同实体。固定实际模型/纹理槽/异步状态，避免只按截图猜缺贴图。
首次加载碎片查整棵附件树的绘制时序与真实动作（HasSequence可能仅命中alias）；衣服静止漂浮查skin-parent关系是否在拆挂时被清除；只有预览白查是否从旧nativeDisplay重建了占位实体。
复用引擎独立DuplicateModel与collection重绑，保持源人物隔离；强制剪影/非目标族/变形不匹配保留旧路。拆挂仅清自己的关系，真正卸载再清后代。异步就绪和状态恢复需覆盖重新选择、关闭重开、缓存复用，不使用固定延时替代就绪判断。
选角参阅[首次加载与伪敬礼](references/selection-20261116.md)，虚灵幻化参阅[实体与材质复制](references/ethereal-20261116.md)，袖甲跟随参阅既有[身体装备Skill](../overlay-armor-on-nonstandard-uv-race-models/SKILL.md)。不把离线替身验证写成真实画面验收。
