# TG16A scoped acceptance


## 2026-10-19 TG16A 图鉴按等级推荐联动实测通过

用户原话：“这下这个图鉴 系统 按照等级推荐 的联动 可以了 测试通过 可以推送了 我明天继续测试”。验收限图鉴按等级推荐联动，以及本次使用中的保留已学补点流程基本通过；不扩大到全部职业、全部收藏/导入导出、互斥/收费/异常保存矩阵。后续测试仍待继续。

方法：推荐模板与实际已存方案分层。已存rank高于模板rank不等于互斥；从权威已存mask逐级补点，每次复用原规则校验。保留全部已存rank，受实际等级/AE/TE预算约束，真互斥节点跳过。接受确认只载入本地草稿，保存仍由用户在原面板执行。确认前后复核revision、slot、layout hash、savedMask、targetMask、预算；保留错专精、脏草稿、同步、战斗、等级预览保护。灰按钮展示实际阻止原因。

反例：TG15A原savedRank>idealRank判断误拦兼容选择；不能只因不在推荐清单就建议洗点。离线27级6/9 AE、1/9 TE兼容净化神像案例可复现，但不能冒称是用户真实节点。已学补点结果可能不同于标准树图，实际应查看确认框/草稿。

冻结TG16A包SHA256：28cd75e5a52fd4bf4c31c4a449794e304a122935855bae1f065ba5d300e04575。55/55现场文件匹配。技能、存档、服务器规则未改；无SQL/Data/MPQ更新，无需编译或重新覆盖已测试客户端。

Parent official commit: 27e66458dab470b3106b4e9c245257764103f606.

Client Lua/TOC mirrors include the cumulative dependency closure from TG1F through TG16A; archival of dependencies is not blanket acceptance of every feature. The full unchanged frozen ZIP is the installable resource, including BLP assets. Do not install Git mirrors alone. No server changes, SQL or Data needed. Previous unrelated 28 worktree mode changes and pycache are excluded. Playerbots gitlink remains the official parent value.

Resource: codexfix_20261019_074151_阶段TG16A_巫医保留已学推荐补点与禁用原因累计包.zip
SHA256: 28cd75e5a52fd4bf4c31c4a449794e304a122935855bae1f065ba5d300e04575
