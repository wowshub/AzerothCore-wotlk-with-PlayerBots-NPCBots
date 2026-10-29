# UIR1D 已验收发布

## 2026-10-29 UIR1D 悬停分色用户基本验收
用户点名UIR1D包并表示“这个也测试成功”。确认蛇人与双头食人魔悬停白色名称、黄色简介、白色分条属性基本通过。发布前1/1安装Lua匹配冻结包；B到D包含C的十条属性文字，不能只摘分色函数漏掉文字依赖。
复用现有XML OnEnter/OnLeave与Tooltip高度计算；局部字符串色码分段开关，不改全局字体；身份键与显示名分开。模型黑影、属性机制、正式创建及所有分辨率矩阵不继承通过。

只改data/reborn-client/Interface/GlueXML/RebornRacePreview.lua。原交付包不改，资源附件保留SHA256；独立教学附件提供完整B/C/D原件及diff。无SQL/DBC/EXE或生产部署。
