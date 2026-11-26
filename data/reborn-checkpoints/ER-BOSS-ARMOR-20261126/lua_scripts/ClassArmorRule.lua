-- ClassArmorRule.lua (ARMOR1A V2, 2026-11-26, Claude) - candidate. V2 = same rule, plus a chat line that says why a piece was
-- allowed or refused, so that a test shows which case applies.
-- Armour worn by class, for characters in Classic mode:
--   * real players: only characters created after this script ran for the first time (older characters are left as they are);
--   * playerbots: always (BOTS_TOO);
--   * Random Draft / Free Pick characters: no limit at all.
-- Why a script: a Classic priest was seen wearing mail. Where that proficiency comes from is not known, so the limit is enforced where
-- the item is put on, whatever skills the character has. NPCBots are not players and keep their own rules.
local BOTS_TOO = true
local MODE_RANDOM_DRAFT, MODE_FREE_PICK = 2, 3
local EVENT_CAN_USE_ITEM = 31
local NO_PROFICIENCY = 8                    -- EQUIP_ERR_NO_REQUIRED_PROFICIENCY
local ITEM_CLASS_ARMOR, HEIRLOOM = 4, 7
local CLOTH, LEATHER, MAIL, PLATE, SHIELD = 1, 2, 3, 4, 6

-- lowest level at which a class may wear that kind of armour (missing = never). Custom classes (12 and above) are not listed: no limit.
local RULE = {
    [1]  = {[CLOTH] = 1, [LEATHER] = 1, [MAIL] = 1, [PLATE] = 40, [SHIELD] = 1},      -- Warrior
    [2]  = {[CLOTH] = 1, [LEATHER] = 1, [MAIL] = 1, [PLATE] = 40, [SHIELD] = 1},      -- Paladin
    [3]  = {[CLOTH] = 1, [LEATHER] = 1, [MAIL] = 40},                                 -- Hunter
    [4]  = {[CLOTH] = 1, [LEATHER] = 1},                                              -- Rogue
    [5]  = {[CLOTH] = 1},                                                             -- Priest
    [6]  = {[CLOTH] = 1, [LEATHER] = 1, [MAIL] = 1, [PLATE] = 1},                     -- Death Knight
    [7]  = {[CLOTH] = 1, [LEATHER] = 1, [MAIL] = 40, [SHIELD] = 1},                   -- Shaman
    [8]  = {[CLOTH] = 1},                                                             -- Mage
    [9]  = {[CLOTH] = 1},                                                             -- Warlock
    [11] = {[CLOTH] = 1, [LEATHER] = 1},                                              -- Druid
}
local LIMITED = {[CLOTH] = true, [LEATHER] = true, [MAIL] = true, [PLATE] = true, [SHIELD] = true}

-- when the rule started (kept in the characters database, written once)
CharDBQuery("CREATE TABLE IF NOT EXISTS `reborn_armor_rule` (`id` TINYINT UNSIGNED NOT NULL PRIMARY KEY, `started_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP)")
CharDBQuery("INSERT IGNORE INTO `reborn_armor_rule` (`id`) VALUES (1)")
local ready = false
do
    local q = CharDBQuery("SELECT (SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = DATABASE() AND table_name = 'characters' AND column_name = 'creation_date'), (SELECT COUNT(*) FROM `reborn_armor_rule` WHERE `id` = 1)")
    ready = q ~= nil and q:GetUInt32(0) == 1 and q:GetUInt32(1) == 1
end

local isNew = {}            -- [guid low] = true / false once the character row has been seen

local function createdAfterRule(player)
    local guid = player:GetGUIDLow()
    if isNew[guid] ~= nil then return isNew[guid] end
    local q = CharDBQuery("SELECT IF(c.`creation_date` >= r.`started_at`, 1, 0) FROM `characters` c JOIN `reborn_armor_rule` r ON r.`id` = 1 WHERE c.`guid` = " .. guid)
    if not q then return true end        -- no row yet: the character is being created right now (do not remember this answer)
    isNew[guid] = q:GetUInt32(0) == 1
    return isNew[guid]
end

local function limited(player)
    if player.IsBot and player:IsBot() then return BOTS_TOO end
    if not ready then return false end   -- cannot tell old from new characters: leave real players alone
    if type(SpellDraft_GetCharacterModeId) == "function" then
        local mode = SpellDraft_GetCharacterModeId(player)
        if mode == MODE_RANDOM_DRAFT or mode == MODE_FREE_PICK then return false end
    end
    return createdAfterRule(player)
end

local told = {}             -- [guid low .. item] = true: one chat line per item and session

local function tell(player, itemEntry, text)
    if player.IsBot and player:IsBot() then return end
    local key = player:GetGUIDLow() .. ":" .. itemEntry
    if told[key] then return end
    told[key] = true
    player:SendBroadcastMessage("|cffffd100[护甲限制 Armor rule]|r " .. text .. " (item " .. itemEntry .. ")")
end

local function exemptReason(player)
    if not ready then return "无法判断新旧角色，不限制。 Cannot tell old from new characters: not limited." end
    if type(SpellDraft_GetCharacterModeId) == "function" then
        local mode = SpellDraft_GetCharacterModeId(player)
        if mode == MODE_RANDOM_DRAFT or mode == MODE_FREE_PICK then return "抽卡模式角色，不限制。 Draft character: not limited." end
    end
    return "本角色在护甲规则启用前创建，属于旧角色，不限制。 Created before the rule started: not limited."
end

local reported = false
RegisterPlayerEvent(EVENT_CAN_USE_ITEM, function(event, player, itemEntry)
    local ok, result = pcall(function()
        local rule = RULE[player:GetClass()]
        if not rule then return nil end
        local item = GetItemTemplate(itemEntry)
        if not item or item:GetClass() ~= ITEM_CLASS_ARMOR then return nil end
        local kind = item:GetSubClass()
        if not LIMITED[kind] or item:GetQuality() == HEIRLOOM then return nil end      -- heirlooms keep the core's own scaling rule
        local from = rule[kind]
        if from and player:GetLevel() >= from then return nil end
        if not limited(player) then
            tell(player, itemEntry, exemptReason(player))
            return nil
        end
        tell(player, itemEntry, "你的职业现在不能穿这类护甲。 Your class cannot wear this armour yet.")
        return NO_PROFICIENCY
    end)
    if not ok then
        if not reported then reported = true; print("[ClassArmorRule] ERROR (items allowed): " .. tostring(result)) end
        return
    end
    if result then return result end
end)

print("[ClassArmorRule] ARMOR1A V2 loaded: " .. (ready and "new Classic characters" or "characters table has no creation_date, real players NOT limited")
    .. (BOTS_TOO and " and all playerbots" or ""))
