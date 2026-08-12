SpellDraft = SpellDraft or {}
SpellDraftDB = SpellDraftDB or {}

-- English phrases are the stable keys.  English clients use the key itself;
-- Chinese clients read the matching value below.  Missing translations fall
-- back to English, so a new UI label can never break addon loading.
local zhCN = {
    ["Automatic"] = "自动",
    ["Chinese"] = "中文",
    ["English"] = "英文",
    ["Language"] = "语言",
    ["SpellDraft language: %s. Reloading UI..."] = "SpellDraft 语言：%s。正在重新载入界面……",
    ["Usage: /sdlang auto, /sdlang zh, or /sdlang en"] = "用法：/sdlang auto、/sdlang zh 或 /sdlang en",

    ["All"] = "全部", ["General"] = "通用",
    ["Warrior"] = "战士", ["Paladin"] = "圣骑士", ["Hunter"] = "猎人", ["Rogue"] = "盗贼",
    ["Priest"] = "牧师", ["Death Knight"] = "死亡骑士", ["Shaman"] = "萨满", ["Mage"] = "法师",
    ["Warlock"] = "术士", ["Druid"] = "德鲁伊",
    ["Arms"] = "武器", ["Fury"] = "狂怒", ["Protection"] = "防护",
    ["Holy"] = "神圣", ["Retribution"] = "惩戒",
    ["Beast Mastery"] = "野兽控制", ["Marksmanship"] = "射击", ["Survival"] = "生存",
    ["Assassination"] = "刺杀", ["Combat"] = "战斗", ["Subtlety"] = "敏锐",
    ["Discipline"] = "戒律", ["Shadow"] = "暗影",
    ["Blood"] = "鲜血", ["Frost"] = "冰霜", ["Unholy"] = "邪恶",
    ["Elemental"] = "元素", ["Enhancement"] = "增强", ["Restoration"] = "恢复",
    ["Arcane"] = "奥术", ["Fire"] = "火焰",
    ["Affliction"] = "痛苦", ["Demonology"] = "恶魔学识", ["Destruction"] = "毁灭",
    ["Balance"] = "平衡", ["Feral"] = "野性", ["Feral Combat"] = "野性战斗",
    ["Common"] = "普通", ["Uncommon"] = "优秀", ["Rare"] = "稀有",
    ["Epic"] = "史诗", ["Legendary"] = "传说", ["Broken"] = "损坏",
    ["Innate"] = "固有",
    ["Character Advancement · SpellDraft"] = "角色成长 · SpellDraft",
    ["Spells & Abilities"] = "技能与能力", ["Talent Trees"] = "天赋树",
    ["Moving Character Advancement..."] = "正在移动角色成长面板……",
    ["Search spells..."] = "搜索技能……",
    ["Page %d of %d"] = "第 %d / %d 页",
    ["Choose a class above"] = "请从上方选择一个职业",
    ["Its three talent trees will appear here"] = "选择后将在这里显示三系天赋",
    ["Locked talents can only be drafted from a Tome of Talents"] = "带锁天赋只能通过天赋之书抽取",
    ["Talk to Nibbs when you need to reset talents."] = "需要洗点时，请与小鬼 Nibbs 对话。",
    ["Prestige"] = "转生", ["None"] = "无", ["Rerolls"] = "重抽", ["Bans"] = "禁用", ["(+50% XP)"] = "（+50% 经验）",
    ["Talent Points: %d"] = "天赋点数：%d",
    ["Locked: Requires Tome of Talents"] = "已锁定：需要天赋之书",
    ["Requires level %d"] = "需要等级 %d",
    ["Requires %d points in %s."] = "需要投入 %d 点到%s。",
    ["prerequisite"] = "前置天赋",
    ["This talent is locked and can only be acquired from a Tome of Talents."] = "该天赋已锁定，只能通过天赋之书获得。",
    ["This talent requires level %d."] = "该天赋需要等级 %d。",
    ["You do not have any Talent Points."] = "你没有可用的天赋点数。",
    ["Prestige Shop"] = "转生商店",
    ["Click to open the Prestige Shop to spend your Prestige Tokens."] = "点击打开转生商店并消费转生代币。",
    ["Your Tokens: %d"] = "你的代币：%d",
    ["Button position reset."] = "按钮位置已重置。",
    ["SpellDraft Grimoire"] = "SpellDraft 法术书",
    ["Click to toggle spellbook."] = "点击打开或关闭法术书。",
    ["Drag with Left Click to reposition."] = "按住鼠标左键拖动可调整位置。",
    ["Grimoire not initialized yet."] = "法术书尚未初始化。",

    ["Reroll"] = "重抽", ["Reroll (%s)"] = "重抽（%s）", ["Dismiss"] = "暂时关闭", ["Ban"] = "禁用",
    ["Ban [ON] (%d)"] = "禁用模式[开启]（%d）", ["Ban (%d)"] = "禁用（%d）",
    ["Ban Mode Activated"] = "禁用模式已开启",
    ["No bans remaining."] = "没有剩余禁用次数。", ["You have no rerolls remaining."] = "没有剩余重抽次数。",
    ["Cannot reroll at this time."] = "当前不能重抽。",
    ["Spell #%d"] = "法术 #%d", ["Spell data not cached."] = "法术数据尚未缓存。",
    ["%d Drafts Remaining"] = "剩余 %d 次抽取", ["%d Draft(s) Left"] = "还剩 %d 次抽取",
    ["Talent Draft"] = "天赋抽取",
    ["Floating HUD enabled."] = "浮动资源栏已启用。", ["Floating HUD disabled."] = "浮动资源栏已禁用。",
    ["Mana"] = "法力", ["Rage"] = "怒气", ["Focus"] = "集中值", ["Energy"] = "能量", ["Runic Power"] = "符文能量",

    ["Are you sure you want to purchase %s for %d Prestige Tokens?"] = "确定购买%s吗？价格为 %d 枚转生代币。",
    ["Yes"] = "是", ["No"] = "否", ["Buy"] = "购买",
    ["Tokens: %d"] = "代币：%d", ["Cost: %d Prestige Token(s)"] = "价格：%d 枚转生代币",
    ["Select an item from the list above to view details."] = "请从上方列表选择物品以查看详情。",
    ["Drafts"] = "抽卡", ["Heirlooms"] = "传家宝", ["Mounts"] = "坐骑", ["Pets"] = "宠物", ["Cosmetic"] = "趣味物品",
    ["Scroll of Reroll"] = "重抽卷轴", ["Scroll of Ban"] = "禁用卷轴",
    ["Lost Grimoire"] = "失落魔典", ["Tome of Talents"] = "天赋之书",
    ["Consuming this scroll grants you +1 Draft Reroll."] = "使用后获得 1 次额外重抽。",
    ["Consuming this scroll grants you +1 Draft Ban."] = "使用后获得 1 次额外禁用。",
    ["Consuming this grimoire triggers an immediate bonus spell draft."] = "使用后立即获得一次额外技能抽取。",
    ["Consuming this grimoire triggers a passive class talent draft."] = "使用后立即进行一次职业被动天赋抽取。",
    ["Heirloom 2H Axe. Scales with level and increases experience gained."] = "双手斧传家宝，随等级成长并提高经验获取。",
    ["Heirloom 1H Sword. Scales with level and increases experience gained."] = "单手剑传家宝，随等级成长并提高经验获取。",
    ["Heirloom Bow. Scales with level and increases experience gained."] = "弓传家宝，随等级成长并提高经验获取。",
    ["Heirloom Dagger. Scales with level and increases experience gained."] = "匕首传家宝，随等级成长并提高经验获取。",
    ["Heirloom Staff. Scales with level and increases experience gained."] = "法杖传家宝，随等级成长并提高经验获取。",
    ["Heirloom Plate Shoulders. Scales with level and grants +10% XP bonus."] = "板甲肩部传家宝，随等级成长并提供 10% 经验加成。",
    ["Heirloom Plate Chest. Scales with level and grants +10% XP bonus."] = "板甲胸部传家宝，随等级成长并提供 10% 经验加成。",
    ["Heirloom Leather Shoulders. Scales with level and grants +10% XP bonus."] = "皮甲肩部传家宝，随等级成长并提供 10% 经验加成。",
    ["Heirloom Leather Chest. Scales with level and grants +10% XP bonus."] = "皮甲胸部传家宝，随等级成长并提供 10% 经验加成。",
    ["Heirloom Cloth Chest. Scales with level and grants +10% XP bonus."] = "布甲胸部传家宝，随等级成长并提供 10% 经验加成。",
    ["Heirloom Mail Shoulders. Scales with level and grants +10% XP bonus."] = "锁甲肩部传家宝，随等级成长并提供 10% 经验加成。",
    ["Heirloom Mail Chest. Scales with level and grants +10% XP bonus."] = "锁甲胸部传家宝，随等级成长并提供 10% 经验加成。",
    ["Heirloom Trinket. Scales with level and restores health upon defeating enemies."] = "饰品传家宝，随等级成长，击败敌人时恢复生命。",
    ["Heirloom Trinket. Scales with level and restores mana upon defeating enemies."] = "饰品传家宝，随等级成长，击败敌人时恢复法力。",
    ["Teaches you how to summon the rare Amani War Bear mount."] = "教你召唤稀有的阿曼尼战熊坐骑。",
    ["Teaches you how to summon the legendary Spectral Tiger mount."] = "教你召唤传说级幽灵虎坐骑。",
    ["Teaches you how to summon the flying Ashes of Al'ar mount."] = "教你召唤可飞行的奥的灰烬坐骑。",
    ["Teaches you how to summon the unique Mimiron's Head flying mount."] = "教你召唤独特的米米尔隆的头部飞行坐骑。",
    ["Teaches you how to summon the Lich King's personal mount, Invincible."] = "教你召唤巫妖王的专属坐骑无敌。",
    ["Teaches you how to summon the Swift Gladiator Nether Drake."] = "教你召唤迅捷角斗士虚空幼龙。",
    ["Teaches you how to summon the Deadly Gladiator's Frost Wyrm."] = "教你召唤致命角斗士的冰霜巨龙。",
    ["Summons a Mini Diablo companion vanity pet."] = "召唤迷你暗黑破坏神趣味宠物。",
    ["Summons a Zergling companion vanity pet."] = "召唤跳虫趣味宠物。",
    ["Summons a Panda Cub companion vanity pet."] = "召唤熊猫宝宝趣味宠物。",
    ["Summons Lurky the Netherwhelp companion vanity pet."] = "召唤虚空幼龙宝宝奔波尔霸。",
    ["Transform into a member of the opposite faction."] = "变形成敌对阵营的种族。",
    ["Transform into a Blood Elf for 5 minutes."] = "变形成血精灵，持续 5 分钟。",
    ["Surround yourself in a purple bubble and transform into a gorilla."] = "进入紫色气泡并变形成猩猩。",
    ["Transform into an Iron Dwarf."] = "变形成铁矮人。",
    ["Transform into a Murloc."] = "变形成鱼人。",
    ["Places an Ogre Pinata that can be beaten for bubblegum."] = "放置一个食人魔彩罐，击打后可获得泡泡糖。",
    ["Sets up a romantic picnic basket complete with a parasol."] = "摆放一套带遮阳伞的浪漫野餐篮。",

    ["Prestige Level: %d"] = "转生等级：%d", ["Prestige: %d"] = "转生：%d",
    ["Mystic Enchant"] = "神秘附魔",
    ["Nibbs' Mystic Enchants"] = "Nibbs 的神秘附魔",
    ["Reroll / Imbue"] = "重抽／灌注", ["Reroll (Epic+)"] = "重抽（史诗+）", ["Imbue"] = "灌注", ["%s (Epic+)"] = "%s（史诗+）",
    ["Drag a green-or-better weapon or armor piece here."] = "将优秀或更高品质的武器、护甲拖到这里。",
    ["Prestige Token: %d/%d"] = "转生代币：%d/%d",
    ["Transfer Enchant"] = "转移附魔", ["Source"] = "来源", ["Destination"] = "目标", ["Result"] = "结果", ["Transfer"] = "转移",
    ["Place the enchanted item on the left and the target item on the right."] = "左侧放已有附魔的物品，右侧放目标物品。",
    ["Appraising..."] = "正在鉴定……", ["Cannot service that item"] = "无法处理该物品",
    ["Current: %s"] = "当前：%s", ["No Mystic Enchant on this item."] = "该物品没有神秘附魔。",
    ["Transfer %s to %s"] = "将%s转移到%s", ["Warning: destination already has %s"] = "警告：目标物品已经拥有%s",
    ["Cannot transfer"] = "无法转移", ["Service failed"] = "服务失败",
    ["This will DESTROY %s on the destination item. Transfer anyway?"] = "这会摧毁目标物品上的%s。仍要转移吗？",
    ["for"] = "花费", ["it will be destroyed!"] = "它将被摧毁！",
}

local function ResolveLanguage()
    local setting = SpellDraftDB.language or "auto"
    if setting == "zhCN" or setting == "enUS" then return setting end
    local locale = GetLocale and GetLocale() or "enUS"
    return (locale == "zhCN" or locale == "zhTW") and "zhCN" or "enUS"
end

function SpellDraft.GetLanguage()
    return ResolveLanguage()
end

function SpellDraft.GetLanguageSetting()
    return SpellDraftDB.language or "auto"
end

function SpellDraft.L(key, ...)
    local text = key
    if ResolveLanguage() == "zhCN" then text = zhCN[key] or key end
    if select("#", ...) > 0 then
        local ok, formatted = pcall(string.format, text, ...)
        if ok then return formatted end
    end
    return text
end

function SpellDraft.ClassName(token)
    if token == "ALL" then return SpellDraft.L("All") end
    if token == "GENERAL" then return SpellDraft.L("General") end
    local classKeys = {
        WARRIOR = "Warrior", PALADIN = "Paladin", HUNTER = "Hunter", ROGUE = "Rogue",
        PRIEST = "Priest", DEATHKNIGHT = "Death Knight", SHAMAN = "Shaman", MAGE = "Mage",
        WARLOCK = "Warlock", DRUID = "Druid",
    }
    return SpellDraft.L(classKeys[token] or token)
end

function SpellDraft.GetLanguageLabel(setting)
    setting = setting or SpellDraft.GetLanguageSetting()
    if setting == "zhCN" then return SpellDraft.L("Chinese") end
    if setting == "enUS" then return SpellDraft.L("English") end
    return SpellDraft.L("Automatic")
end

function SpellDraft.SetLanguage(setting)
    if setting ~= "auto" and setting ~= "zhCN" and setting ~= "enUS" then return false end
    SpellDraftDB.language = setting
    local label = SpellDraft.GetLanguageLabel(setting)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[SpellDraft]|r " .. SpellDraft.L("SpellDraft language: %s. Reloading UI...", label))
    ReloadUI()
    return true
end

SLASH_SPELLDRAFTLANG1 = "/sdlang"
SLASH_SPELLDRAFTLANG2 = "/spelldraftlang"
SlashCmdList["SPELLDRAFTLANG"] = function(msg)
    msg = string.lower((msg or ""):match("^%s*(.-)%s*$"))
    local setting, label
    if msg == "auto" or msg == "" then setting, label = "auto", SpellDraft.L("Automatic")
    elseif msg == "zh" or msg == "cn" or msg == "zhcn" then setting, label = "zhCN", SpellDraft.L("Chinese")
    elseif msg == "en" or msg == "enus" then setting, label = "enUS", SpellDraft.L("English")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[SpellDraft]|r " .. SpellDraft.L("Usage: /sdlang auto, /sdlang zh, or /sdlang en"))
        return
    end
    SpellDraft.SetLanguage(setting)
end
