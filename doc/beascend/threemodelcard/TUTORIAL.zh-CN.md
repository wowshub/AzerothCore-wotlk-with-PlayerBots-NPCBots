# 从“技能一闪消失”到三模式：完整大白话教学

这是一份给第一次接触魔兽私服、Lua、C++ 和数据库的新手看的教程。不要先背代码，先记住一句话：

> 一个画面上的功能，通常同时经过客户端显示、网络消息、服务器规则、数据库持久化四层。只修其中一层，往往只能让它“看起来好了一秒”。

---

## 一、先建立四层模型

把游戏想象成一家银行：

1. **客户端 Lua/XML** 是柜台屏幕，只负责让你看见和点击。
2. **AIO/网络消息** 是柜台递交的申请单。
3. **服务器 Lua/C++** 是银行审核员，决定能不能办。
4. **数据库** 是总账，决定重登后还在不在。

因此，“技能在技能书里闪一下又消失”不等于技能书坏了。客户端先收到“学会”，随后服务器又执行 `RemoveSpell`，画面当然会先出现再消失。

---

## 二、A.8：抽到的技能为什么一闪就消失

### 1. 旧逻辑的问题

旧反作弊监听学习技能事件。它发现抽卡模式角色突然学会一个技能，就延迟 250 毫秒删除：

```lua
p:RemoveSpell(spellId)
```

问题是合法抽卡本身也会触发同一个学习事件。抽卡处理器与反作弊处理器在抢时间：一个教技能，一个删技能。

### 2. 修后的关键代码

```lua
local drafted = CharDBQuery(
    "SELECT 1 FROM drafted_spells WHERE player_guid = " .. guid ..
    " AND spell_id = " .. spellId
)
if drafted then
    return
end

p:RemoveSpell(spellId)
```

逐行解释：

- `CharDBQuery(...)`：去角色数据库查账。
- `SELECT 1`：不需要取整行，只问“有没有这条记录”。
- `player_guid`：角色唯一编号，不能只用角色名。
- `spell_id`：法术唯一编号。
- `if drafted then return end`：如果数据库证明它是合法抽卡，立刻退出，不删除。
- `RemoveSpell`：只有查不到合法记录时才执行，训练师偷学仍会被拦。

### 3. 为什么必须“先记账，再发货”

修复后的顺序是：

```lua
CharDBExecute("INSERT IGNORE INTO drafted_spells ...")
player:LearnSpell(spellId)
```

这叫**先建立事实，再触发事件**。`LearnSpell` 会触发其他监听器；在触发之前，数据库必须已经能证明这次学习合法。

`INSERT IGNORE` 的意义是：同一技能重复登记时不报重复主键错误，操作具有“做一次和做两次结果相同”的性质，这叫**幂等性**。

### 4. 内存丢失后的恢复

三张候选卡原本只放在 `currentDraftChoices[guid]`。Lua 重载或时序变化会让内存表消失，因此校验失败时改为读取：

```sql
SELECT offered_spell_1, offered_spell_2, offered_spell_3
FROM prestige_stats
WHERE player_id = ?;
```

客户端点的技能必须仍属于数据库保存的三张卡，才能恢复内存并继续。这样既减少误报，也没有放松安全校验。

### 5. 测试方法

1. 新建尚未抽卡的角色。
2. 点击三张卡之一。
3. 等待至少 10 秒，确认技能没有消失。
4. 小退重登，确认技能仍在。
5. 尝试从训练师学一个不允许的技能，确认反作弊仍会删除。

这叫**正向测试 + 反向测试**：既证明合法路径能走，也证明非法路径没有被顺手放开。

---

## 三、A.9～A.19：客户端兼容与界面基础

### 模型框空值

自定义种族模型会让旧 3.3.5a UI 出现 `settings=nil`、`rotation=nil`。修复思想不是到处吞错误，而是在模型框初始化边界补默认值：设置、缩放、旋转必须在拖动或运算前存在。

### 界面拖动为什么会卡

拖动时不要每帧重建几十个按钮、重新查询所有法术或反复布局。正确做法是：

- `OnDragStart` 只执行 `StartMoving()`；
- `OnDragStop` 执行 `StopMovingOrSizing()` 并保存坐标；
- 数据刷新与位置移动分开。

### 双语为什么用词典，而不是复制两套界面

推荐结构：

```lua
local TEXT = {
    zhCN = { title = "选择角色成长模式" },
    enUS = { title = "Choose Character Progression" },
}
```

界面控件只有一套，切换语言时只替换文字。这避免中文界面修了按钮而英文界面漏修。

---

## 四、A.20：遗产技能为什么必须走“服务器权威”

客户端面板可以列出所有技能，但不能由客户端直接决定“我学会了”。否则玩家改一行 Lua 就能免费学习全部技能。

正确流程：

1. 客户端发送想学的 `spellId`。
2. 服务器检查它是否在 115 项白名单。
3. 检查类别额度，例如 `2/2/1/2`。
4. 检查钱或点数。
5. 先写合法学习记录。
6. 临时设置 `SpellDraft_SetSystemLearning(guid, true)`。
7. 调用 `LearnSpell`。
8. 成功后扣费并关闭临时放行。

这里的临时放行不是关闭反作弊，而是像给一次内部转账盖上“系统办理”印章。

---

## 五、A.21：阵营技能池和同阵营任务不是一回事

联盟抽到“传送奥格瑞玛”，说明技能池缺少阵营过滤。技能池应在随机前过滤，而不是抽到后再删除，否则会浪费一次候选位。

任务兼容与声望又是两套系统：

- 服务端任务使用 `AllowableRaces` 位掩码。
- 客户端声望面板使用 `Faction.dbc` 的 `BaseRepRaceMask`。

位掩码可以理解为一排开关。联盟总掩码 `RACEMASK_ALLIANCE` 是把所有联盟种族对应的位都打开。修复后的 C++ 兜底：

```cpp
case RACE_PANDAREN_ALLIANCE:
case RACE_DARK_IRON_DWARF:
case RACE_VOIDELF:
    compatibleRaceMask = RACEMASK_ALLIANCE;
    break;
```

它只放宽“种族位”，等级、职业、前置任务和声望条件仍继续检查。

---

## 六、A.22：三模式为什么不能只做三个按钮

模式编号：

- `0`：尚未选择；
- `1`：经典职业；
- `2`：随机抽卡；
- `3`：自由选择。

权威表 `spelldraft_character_mode` 按角色 GUID 保存。客户端点击只是请求，服务器负责：

- 模式是否开放；
- 角色是否已经锁定；
- DK 是否允许转一级；
- 保存是否成功。

### 旧系统的两个后门

旧 `spelldraft_core.lua` 和 `spell_choice.lua` 会在找不到档案时自动创建 `draft_state=1`。如果不封住它们，玩家明明选经典模式，后台仍可能把他拉回抽卡。

所以每个入口都要问：

```lua
if not SpellDraft_IsMode(player, "draft") then
    return
end
```

这叫**门禁前置**。不要执行到一半才发现模式不对。

### 为什么自由模式先显示但锁住

自由模式需要点数产生、可学技能列表、前置关系、扣点事务、洗点与反作弊闭环。只做一个能点的 UI 会制造永久坏号，所以服务器与按钮同时锁定，直到后端完整。

### Playerbot 为什么跳过

机器人没有人类鼠标，若被强制选择界面阻塞就无法登录。`IsBotPlayer` 在模式入口最前面返回，属于明确的系统边界，不需要再额外做一套机器人选卡 UI。

---

## 七、A.22.1～A.22.6：为什么 ESC、X 和选卡会连续出问题

WoW UI 存在层级、鼠标拦截和硬件事件限制：看得见的卡片不一定是最上层接收鼠标的 Frame。

修复顺序体现了排查方法：

1. 先调遮罩透明度，解决漆黑。
2. ESC 与 X 统一调用同一个收起函数，避免行为分叉。
3. 强制选择时只收成提示卡，不允许彻底绕过。
4. 给三张卡建立独立点击层，覆盖装饰纹理。
5. 在旧客户端受保护事件不稳定时，用硬件鼠标状态轮询确认点击。
6. 语言状态由一个来源同步到模式面板和 SpellDraft 面板。

原则是：**一个动作只有一个业务函数，多个按钮只是调用它。**

---

## 八、A.22.8：死亡骑士为什么要做两条路线

经典 DK 应保留 WotLK 的 55 级阿彻鲁斯剧情；抽卡 DK 才转成一级普通成长。不能全局把 DK 出生等级改成 1，否则经典模式也被破坏。

`ConvertDeathKnightToLevelOneDraft(player)` 主要做：

1. 校验角色刚创建、尚未正常成长。
2. 等级和经验归 1。
3. 清理英雄职业装备与天赋。
4. 发放低级可穿戴装备。
5. 按种族出生路线传送并绑定炉石。
6. 写转换状态，防止重复执行。

### 状态为什么不只用 true/false

使用类似：

- `0` 未处理；
- `1` 处理中；
- `2` 成功；
- `3` 失败。

这样服务器崩溃后能区分“从未开始”和“做到一半”，这叫**可恢复状态机**。

### DK 伤害缩放参数

- 一级默认约 `10%`；
- 55 级恢复 `100%`；
- 只缩放 DK SpellFamily 的直接伤害、周期伤害和治疗；
- 经典 DK 不进入缩放缓存。

不能粗暴缩放角色所有伤害，否则抽到的其他职业技能也会被重复削弱。

### 传送限制

原版 DK 未完成任务、未学会死亡之门时禁止离开黑锋要塞。一级抽卡 DK故意跳过该剧情，因此条件改成只限制 `GetLevel() > 1` 的经典路线。

---

## 九、A.23～A.24：角色徽章、平均装等和圆形图标

### 角色选择徽章的数据从哪里来

角色列表包长度固定，不宜随便增加字段。服务端在没有付费改名/换阵营/换种族请求时，复用原字段未使用的多位组合传输模式：

```cpp
if (progressionMode == 1)
    flags = CUSTOMIZE | FACTION;
else if (progressionMode == 2)
    flags = CUSTOMIZE | RACE;
else if (progressionMode == 3)
    flags = FACTION | RACE;
```

GlueXML 识别这些组合后显示书、骰子或自由模式图标。真实付费服务位优先，不能被徽章覆盖。

### 平均物品等级是什么

它不是所有物品等级的总和，而是参与统计装备槽的平均值。空槽如何处理必须统一：通常只平均已装备物品，或按产品设计将空槽视为 0，但不能一会儿用一种算法。

装备切换事件触发重新计算；切到称号或装备管理页时隐藏文本，避免文字漂浮在错误页面。

### 圆形图标为什么仍会看见方边

只套圆框不能把方形纹理变圆。需要：

- 使用自带透明通道的圆形素材；或
- 用圆形遮罩/裁剪坐标缩进方形边缘；
- 图标、圆环和点击区分别设置合适尺寸。

---

## 十、A.25：宠物明明在数据库，为什么兽栏还是空

这是典型的“三份状态不同步”：

1. `character_pet` 数据库有宠物。
2. 玩家身边有 `Pet` 实体。
3. `Player::PetStable` 内存缓存却为空。

兽栏窗口读取的是第 3 份，不是直接查询数据库。

### C++ 修复逐行理解

```cpp
PetStable* petStable = owner->GetPetStable();
```

取得当前角色的兽栏缓存；可能是空指针。

```cpp
if (mode == PET_SAVE_AS_CURRENT &&
    (!petStable || !petStable->CurrentPet ||
     petStable->CurrentPet->PetNumber != m_charmInfo->GetPetNumber()))
```

只有“保存为当前宠物”，并且缓存不存在、当前格为空或编号不一致时，才初始化。不会干扰正常的存入其他栏位流程。

```cpp
petStable = &owner->GetOrInitPetStable();
petStable->CurrentPet.emplace();
FillPetInfo(&petStable->CurrentPet.value());
```

- `GetOrInitPetStable()`：没有缓存就创建。
- `emplace()`：在 Optional 中原地建立一条 `PetInfo`。
- `FillPetInfo()`：把当前宠物编号、种类、模型、等级等写进缓存。

结果是新驯服宠物不必重登，兽栏立即能显示模型并存放。

### 旧角色为什么还要补一层

旧角色可能只有 `1515 驯服野兽`，没有 `883 召唤宠物`。跨职业模块原来只认 883，因此增加：

```cpp
if (player->HasSpell(883) || player->HasSpell(1515))
    return true;
```

并继续检查 `CurrentPet`、`StabledPets`、`UnslottedPets` 中是否存在真实 `HUNTER_PET`。术士恶魔、食尸鬼、水元素不是 `HUNTER_PET`，不会被误塞进猎人兽栏。

客户端 `PetStable.lua` 也不能再只依赖 `HasPetUI()` 的原职业判断。客户端负责显示兼容，服务器仍负责宠物合法性。

### 测试矩阵

至少测试：

- 新角色抽到 1515 后驯服、打开兽栏、存入、取出；
- 老角色已有宠物但无 883，打开兽栏；
- 术士恶魔尝试存入，必须失败；
- 小退重登后宠物仍在；
- 第一格和扩展栏位都测试。

---

## 十一、A.26：近战为什么提示“需要远程武器”

不是地图高度，也不是怪物点击盒。人族战士、娜迦 DK 都复现，说明共同原因在客户端战斗选择。

SpellDraft 会让角色学会：

- `75` 自动射击；
- `5019` 射击；
- `2764` 投掷。

客户端变量 `autoRangedCombat` 看到角色会远程自动攻击，右键时可能优先尝试远程；但第 18 槽没有远程武器，于是报错。

### 完整修复代码

```lua
local function HasUsableRangedWeaponEquipped()
    if type(GetInventoryItemLink) ~= "function" or type(GetItemInfo) ~= "function" then
        return false
    end

    local itemLink = GetInventoryItemLink("player", 18)
    if not itemLink then return false end

    local equipLoc = select(9, GetItemInfo(itemLink))
    return equipLoc == "INVTYPE_RANGED"
        or equipLoc == "INVTYPE_RANGEDRIGHT"
        or equipLoc == "INVTYPE_THROWN"
end
```

逐行解释：

- `type(...)`：兼容旧客户端 API，函数不存在就安全返回。
- `18`：远程/圣物装备槽编号。
- `GetInventoryItemLink`：读取该槽物品链接。
- `select(9, GetItemInfo(...))`：取第 9 个返回值 `equipLoc`。
- 三种 `INVTYPE_*`：弓枪弩、魔杖类远程槽、投掷武器。
- 没包含 `INVTYPE_RELIC`，所以圣契、神像、图腾、魔印不会被误认为远程武器。

```lua
local function ApplyCombatModeCVar(modeName)
    _G.SpellDraftDB = _G.SpellDraftDB or {}
    local db = _G.SpellDraftDB
    local classlessMode = modeName == "draft" or modeName == "free"

    if classlessMode then
        if db.autoRangedCombatBeforeDraft == nil then
            db.autoRangedCombatBeforeDraft = tostring(GetCVar("autoRangedCombat") or "0")
        end
        SetCVar("autoRangedCombat", HasUsableRangedWeaponEquipped() and "1" or "0")
    elseif modeName == "classic" and db.autoRangedCombatBeforeDraft ~= nil then
        SetCVar("autoRangedCombat", db.autoRangedCombatBeforeDraft)
        db.autoRangedCombatBeforeDraft = nil
    end
end
```

- 抽卡/自由模式：有真实远程武器才自动远程，否则右键稳定近战。
- 经典模式：恢复进入抽卡逻辑前玩家自己的设置。
- 没有删除远程技能，猎人仍可装备弓枪后右键远程，也可从动作条手动使用技能。

事件监听：

```lua
combatModeCVarFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
combatModeCVarFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
```

- 登录/重载时校正一次。
- 装备变化时校正。
- 回调只处理 `slot == 18`，换帽子不会无意义重算。

### 测试矩阵

1. 抽卡战士无远程武器，右键狼，应进入近战。
2. 抽卡猎人装备弓，右键远处怪，应自动射击。
3. 猎人卸下弓，右键近身怪，应近战且不报远程武器。
4. 圣骑士装备圣契，仍应按无远程武器处理。
5. 切回经典模式，确认玩家原 `autoRangedCombat` 设置恢复。

---

## 十二、如何读懂这批测试代码

### 静态检查

```powershell
git diff --check
```

检查尾随空格、冲突标记和补丁格式问题。它不能证明业务一定正确，但能挡住一批低级提交错误。

```powershell
rg -n "SpellDraft_IsMode|HUNTER_PET|autoRangedCombat" modules src
```

用关键词追踪入口和所有调用点。修跨系统问题时，不要只看报错那一行。

### 数据库测试思路

```sql
SELECT spell_id
FROM drafted_spells
WHERE player_guid = ?;
```

验证合法技能是否先记账。

```sql
SELECT id, entry, slot, PetType
FROM character_pet
WHERE owner = ?;
```

验证宠物是 `HUNTER_PET`，并观察当前格与兽栏格变化。

### 为什么仍要实机测试

编译通过只证明语法和类型大体正确；Lua 解析通过也不代表 Frame 层级、鼠标硬件事件和客户端缓存一定正确。最终必须在真实客户端验证交互时序。

---

## 十三、这批修复用到的核心知识

- **状态机**：模式选择和 DK 转换不是一个布尔值。
- **服务器权威**：客户端只能请求，不能决定学习和扣费。
- **幂等性**：重复执行不制造重复技能或重复转换。
- **事务顺序**：先记合法记录，再触发学习事件。
- **缓存一致性**：数据库、运行实体、玩家缓存必须同步。
- **位掩码**：阵营、种族和角色选择传输都在用位组合。
- **事件驱动 UI**：登录、装备变化、分页切换时刷新，不每帧重算。
- **兼容层**：跨职业玩法不能继续信任原版“职业等于猎人”的前提。
- **回归测试矩阵**：每次不仅测修好的角色，还测经典模式、旧角色和不应被放开的对象。

如果只记住一个调试方法，请记住：先找“谁最终拥有决定权”，再沿着数据从客户端一路追到数据库，不要被第一张错误截图绑住。

