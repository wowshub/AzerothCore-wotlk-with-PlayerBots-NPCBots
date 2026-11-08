# 种族核心_DBCStores.cpp：逐行讲解
这是从Claude已核验核心输出到联合包的实际对照；SharedDefines等可能包含已由Claude完成的前置。正式发布种族增量另见release_scope.json，不夹带独立职业变化。
来源：`C_核心前置_联合增量/交付/01_覆盖到源代码根目录/src/server/game/DataStores/DBCStores.cpp`。以下行号是所附原件的真实行号；空行/注释也保留。
## 函数和接口先读表
| 名称 | 在这份文件中的作用 |
|---|---|
| `IsRaceMaskAlias` | 判断是不是本项目批准的高ID掩码别名范围；它不表示种族身份相同 |
| `GetRaceMaskForRace` | 将真实race映射为旧接口资格位；36/37仍返回0 |
| `IsFirstCoaPostCreationRace` | 识别先前蛇人36/食人魔37，保持既有显式兼容路径 |
| `IsFirstCoaSkillMaskAllowed` | 允许指定阵营语言或含模板位的共享行，排除其它单族特长 |
| `GetSkillRaceClassInfo` | 按技能、真实种族、职业筛首条资格行；单族行对别名族不继承 |

## 本次修改涉及的实际代码片段

原件第1000–1008行：
```cpp
                if (!(itr->second->RaceMask & raceMask))
                    continue;

                // RACENEXT3A: an alias race shares a mask bit with another race but not its racial rows;
                // only multi-race rows (languages, class skills) match.
                if (IsRaceMaskAlias(race) && !HasMultipleRaceBits(itr->second->RaceMask))
                    continue;
            }
            else
```

## 一行一行读
| 原件行号 | 代码 | 大白话解释 |
|---:|---|---|
| 1000 | <code>                if (!(itr-&gt;second-&gt;RaceMask &amp; raceMask))</code> | 条件分支：只有`if (!(itr->second->RaceMask & raceMask))`成立才走随后分支；不满足进入else/跳过。 |
| 1001 | <code>                    continue;</code> | 跳过当前不合格记录，进入下一条；不授予这条技能/种族。 |
| 1002 | （空行） | 空行，隔开逻辑段；没有运行行为。 |
| 1003 | <code>                // RACENEXT3A: an alias race shares a mask bit with another race but not its racial rows;</code> | 说明注释：RACENEXT3A: an alias race shares a mask bit with another race but not its racial rows;；它不执行，实际条件仍以相邻代码为准。 |
| 1004 | <code>                // only multi-race rows (languages, class skills) match.</code> | 说明注释：only multi-race rows (languages, class skills) match.；它不执行，实际条件仍以相邻代码为准。 |
| 1005 | <code>                if (IsRaceMaskAlias(race) &amp;&amp; !HasMultipleRaceBits(itr-&gt;second-&gt;RaceMask))</code> | 别名族过滤单种族位技能行，保留满足资格的共享行。 |
| 1006 | <code>                    continue;</code> | 跳过当前不合格记录，进入下一条；不授予这条技能/种族。 |
| 1007 | <code>            }</code> | 结束最近一个函数/结构/分支/循环作用域；按缩进与前方开头配对。 |
| 1008 | <code>            else</code> | 处理前一条件未成立的另一条路径，不会两条分支都执行。 |
