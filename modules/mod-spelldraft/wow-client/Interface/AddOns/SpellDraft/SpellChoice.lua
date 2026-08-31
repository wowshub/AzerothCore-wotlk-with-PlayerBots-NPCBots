SpellDraft = SpellDraft or {}
local L = SpellDraft.L
SpellDraft.CustomTalentProtocolVersion = "A31R4.15.11-B0.1"

-- Confirmed custom talents are server-authoritative, but addon messages are
-- asynchronous and the 3.3.5 client can reopen SpellCraft before the reply is
-- delivered.  Keep a per-character last-known snapshot so closing/reopening
-- or /reload never paints a false 0/5 tree.  Every valid server state replaces
-- this cache; it is not used to grant talents.
local talentStateV2Received = false
local acquiredStateV3Received = false

local function TalentStateCharacterKey()
  local name = UnitName("player")
  if not name or name == "" or name == UNKNOWNOBJECT then return nil end
  local realm = GetRealmName and GetRealmName() or ""
  return tostring(realm or "") .. ":" .. tostring(name)
end

local function CopyTalentIDs(source)
  local copy = {}
  if type(source) == "table" then
    for _, id in ipairs(source) do
      id = tonumber(id)
      if id and id > 0 then table.insert(copy, id) end
    end
  end
  return copy
end

local function CopyTalentRanks(source)
  local copy = {}
  if type(source) == "table" then
    for firstRankSpellId, rank in pairs(source) do
      firstRankSpellId, rank = tonumber(firstRankSpellId), tonumber(rank)
      if firstRankSpellId and firstRankSpellId > 0 and rank and rank > 0 then
        copy[firstRankSpellId] = rank
      end
    end
  end
  return copy
end

function SpellDraft.SaveTalentStateCache(ids)
  if not SpellDraftDB then return end
  local key = TalentStateCharacterKey()
  if not key then return end
  SpellDraftDB.confirmedTalentsByCharacter = SpellDraftDB.confirmedTalentsByCharacter or {}
  SpellDraftDB.confirmedTalentsByCharacter[key] = CopyTalentIDs(ids)
end

function SpellDraft.SaveTalentRankCache(ranks)
  if not SpellDraftDB then return end
  local key = TalentStateCharacterKey()
  if not key then return end
  SpellDraftDB.confirmedTalentRanksByCharacter = SpellDraftDB.confirmedTalentRanksByCharacter or {}
  SpellDraftDB.confirmedTalentRanksByCharacter[key] = CopyTalentRanks(ranks)
end

function SpellDraft.RestoreTalentStateCache(force)
  if not SpellDraftDB then return false end
  local key = TalentStateCharacterKey()
  local cached = key and SpellDraftDB.confirmedTalentsByCharacter
      and SpellDraftDB.confirmedTalentsByCharacter[key]
  local restored = false
  if type(cached) == "table" then
    if force or type(SpellDraft.DraftedTalents) ~= "table" or #SpellDraft.DraftedTalents == 0 then
      SpellDraft.DraftedTalents = CopyTalentIDs(cached)
    end
    restored = true
  end
  local rankCached = SpellDraftDB.confirmedTalentRanksByCharacter
      and SpellDraftDB.confirmedTalentRanksByCharacter[key]
  if type(rankCached) == "table" then
    if force or type(SpellDraft.ConfirmedTalentRanks) ~= "table" then
      SpellDraft.ConfirmedTalentRanks = CopyTalentRanks(rankCached)
    end
    restored = true
  end
  return restored
end

local function ApplyAuthoritativeTalentState(ids)
  SpellDraft.DraftedTalents = CopyTalentIDs(ids)
  SpellDraft.SaveTalentStateCache(SpellDraft.DraftedTalents)
  if SpellDraft.TryResolveTalentCommitFromSync then
    SpellDraft.TryResolveTalentCommitFromSync()
  end
  if SpellDraft.RefreshTalentsList then
    SpellDraft.RefreshTalentsList()
  end
  -- SCTState also owns the learned state of cross-class active/passive Tome
  -- abilities. Refresh the left catalog after every authoritative update so a
  -- learned Titan's Grip does not remain grey until the book is reopened.
  if SpellDraft.RefreshSpellBook then
    SpellDraft.RefreshSpellBook()
  end
end

local function ApplyAuthoritativeTalentRanks(ranks)
  SpellDraft.ConfirmedTalentRanks = CopyTalentRanks(ranks)
  SpellDraft.SaveTalentRankCache(SpellDraft.ConfirmedTalentRanks)
  -- User-verified B0.10.1 behavior: a saved DB rank consumes any local
  -- pending point that would exceed the talent's remaining capacity.
  if SpellDraft.ReconcileStagedTalentRanks then
    SpellDraft.ReconcileStagedTalentRanks(SpellDraft.ConfirmedTalentRanks)
  end
  if SpellDraft.TryResolveTalentCommitFromSync then
    SpellDraft.TryResolveTalentCommitFromSync()
  end
  if SpellDraft.RefreshTalentsList then
    SpellDraft.RefreshTalentsList()
  end
end

-- Expose the same atomic projector to the talent book.  A successful refund
-- acknowledgement carries the exact server-verified target rank, so the book
-- can update that one key immediately without inventing per-talent prefixes.
SpellDraft.ApplyAuthoritativeTalentRanks = ApplyAuthoritativeTalentRanks

-- B0.7 count-framed, tokenized rank stream.  Never expose a partially
-- received transaction: the previous confirmed table remains visible until
-- SCTREnd proves the complete set arrived.
local chunkedTalentRankToken
local chunkedTalentRankExpected = 0
local chunkedTalentRankReceived = 0

-- B0.9.15.11 acquired-spell transaction.  This is deliberately independent
-- from the adjustable talent-rank stream: Tome actives and playstyle passives
-- belong in the left learned catalog, not in the right refundable panel.
local chunkedAcquiredToken
local chunkedAcquiredExpected = 0
local chunkedAcquiredReceived = 0
local chunkedAcquiredIds = {}
local chunkedAcquiredSeen = {}
local chunkedTalentRanks = {}

local function ResetChunkedTalentRankFrame()
  chunkedTalentRankToken = nil
  chunkedTalentRankExpected = 0
  chunkedTalentRankReceived = 0
  chunkedTalentRanks = {}
end

-- Shared single timer frame implementation for Delay/After
local timerFrame = CreateFrame("Frame")
local timerQueue = {}

timerFrame:SetScript("OnUpdate", function(self, elapsed)
  local now = GetTime()
  local i = 1
  while i <= #timerQueue do
    local item = timerQueue[i]
    if now >= item.fireAt then
      table.remove(timerQueue, i)
      local success, err = pcall(item.fn)
      if not success then
        geterrorhandler()(err)
      end
    else
      i = i + 1
    end
  end
  if #timerQueue == 0 then
    self:Hide()
  end
end)
timerFrame:Hide()

function SpellDraft.After(seconds, func)
  table.insert(timerQueue, { fireAt = GetTime() + seconds, fn = func })
  timerFrame:Show()
end

local Delay = SpellDraft.After

-- The stock 3.3.5 client does not consistently place cross-class or talent
-- spells on an action bar. The server sends the exact final rank plus all IDs
-- in its rank chain through SCBar. Never identify a spell by localized name:
-- different abilities can share the same name (475/2782 are both Remove Curse).
local actionPlacementSerial = 0
local actionPlacementBySpell = {}
local pendingManualPlacements = {}
local pendingManualBySpell = {}
local manualPlacementButton
local manualPlacementCloseButton
local UpdateManualPlacementButton

local function SpellIDFromLink(link)
  return link and tonumber(string.match(link, "spell:(%d+)")) or nil
end

local function FindSpellBookEntryByID(wantedID)
  for tab = 1, GetNumSpellTabs() do
    local _, _, offset, numSpells = GetSpellTabInfo(tab)
    for index = offset + 1, offset + numSpells do
      local bookID = SpellIDFromLink(GetSpellLink(index, BOOKTYPE_SPELL))
      if bookID == wantedID then return index end
    end
  end
  return nil
end

local function ActionBarContainsSpellChain(chainIDs)
  for slot = 1, 144 do
    if HasAction(slot) then
      local linkedID = SpellIDFromLink(GetActionLink and GetActionLink(slot))
      if not linkedID and GetActionInfo then
        local actionType, actionID = GetActionInfo(slot)
        if actionType == "spell" then linkedID = tonumber(actionID) end
      end
      if linkedID and chainIDs[linkedID] then return true end
    end
  end
  return false
end

-- 3.3.5 action slots are not laid out on screen in numeric order. 1-12 is
-- only the base page; the extra visible bars normally use 61-72, 49-60 and
-- 25-48. Scan those first, then the remaining pages. This avoids reporting
-- "main bar full" while the player still has many visible empty slots.
local ACTION_SLOT_PRIORITY = {}
local function AddActionSlotRange(firstSlot, lastSlot)
  for slot = firstSlot, lastSlot do
    table.insert(ACTION_SLOT_PRIORITY, slot)
  end
end
AddActionSlotRange(1, 12)
AddActionSlotRange(61, 72)
AddActionSlotRange(49, 60)
AddActionSlotRange(25, 48)
AddActionSlotRange(13, 24)
AddActionSlotRange(73, 120)

local function ResolveVisibleButtonSlot(button)
  if not button then return nil end
  if ActionButton_GetPagedID then
    local ok, slot = pcall(ActionButton_GetPagedID, button)
    if ok and tonumber(slot) and tonumber(slot) > 0 then return tonumber(slot) end
  end
  if ActionButton_CalculateAction then
    local ok, slot = pcall(ActionButton_CalculateAction, button)
    if ok and tonumber(slot) and tonumber(slot) > 0 then return tonumber(slot) end
  end
  return tonumber(button.action or button:GetAttribute("action"))
end

local function FindPreferredEmptyActionSlot()
  local seen = {}
  local prefixes = {
    "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
    "MultiBarRightButton", "MultiBarLeftButton"
  }
  for _, prefix in ipairs(prefixes) do
    for index = 1, 12 do
      local button = _G[prefix .. index]
      if button and button:IsShown() then
        local slot = ResolveVisibleButtonSlot(button)
        if slot and not seen[slot] then
          seen[slot] = true
          if not HasAction(slot) then return slot end
        end
      end
    end
  end
  for _, slot in ipairs(ACTION_SLOT_PRIORITY) do
    if not seen[slot] and not HasAction(slot) then return slot end
  end
  return nil
end

local function QueueManualPlacement(spellID, chainIDs)
  if pendingManualBySpell[spellID] then return end
  pendingManualBySpell[spellID] = true
  table.insert(pendingManualPlacements, { spellID = spellID, chainIDs = chainIDs })
  if UpdateManualPlacementButton then UpdateManualPlacementButton() end
end

local function PlaceAcceptedSpellOnce(spellID, chainIDs, serial, attempt, hardwareClick)
  if actionPlacementBySpell[spellID] ~= serial then return end
  local bookIndex = FindSpellBookEntryByID(spellID)
  if not bookIndex then
    if attempt < 6 then
      Delay(0.5, function() PlaceAcceptedSpellOnce(spellID, chainIDs, serial, attempt + 1) end)
    end
    return
  end

  -- Passive talents belong in the spellbook only and cannot be dragged to a bar.
  if IsPassiveSpell(bookIndex, BOOKTYPE_SPELL) then return end
  if ActionBarContainsSpellChain(chainIDs) then return end

  -- Never mutate the protected action bar from the delayed server callback.
  -- Some 3.3.5 clients place the newly learned spell slightly later than the
  -- SCBar acknowledgement.  Doing our own PlaceAction here races that native
  -- placement and produces two identical buttons (ours first, native second).
  -- Wait for native placement; if it did not happen, preserve a one-click
  -- hardware-event fallback instead.
  if not hardwareClick then
    QueueManualPlacement(spellID, chainIDs)
    UIErrorsFrame:AddMessage(L("Spell learned; click the placement button to add it to an action bar."), 1, 0.65, 0, 1)
    return
  end

  local emptySlot = FindPreferredEmptyActionSlot()
  if not emptySlot then
    UIErrorsFrame:AddMessage(L("Spell learned; all action bars are full."), 1, 0.82, 0, 1)
    return
  end

  ClearCursor()
  -- Client forks differ here: some accept the exact spell ID, while others
  -- expose a spellbook-slot pickup API. Try each safe form and verify the
  -- cursor instead of assuming that a call succeeded.
  PickupSpell(spellID)
  if not GetCursorInfo() and PickupSpellBookItem then
    PickupSpellBookItem(bookIndex, BOOKTYPE_SPELL)
  end
  if not GetCursorInfo() then
    PickupSpell(bookIndex, BOOKTYPE_SPELL)
  end
  if not GetCursorInfo() then
    UIErrorsFrame:AddMessage(L("Spell learned; automatic action bar placement failed."), 1, 0.45, 0, 1)
    return
  end

  PlaceAction(emptySlot)
  ClearCursor()
end

local function QueueAcceptedSpellPlacement(spellID, chainIDs)
  actionPlacementSerial = actionPlacementSerial + 1
  local serial = actionPlacementSerial
  actionPlacementBySpell[spellID] = serial
  -- Native learned/superseded packets and their action placement may arrive
  -- after SCBar. Give them time to settle before offering the manual fallback.
  Delay(1.50, function() PlaceAcceptedSpellOnce(spellID, chainIDs, serial, 1) end)
end

-- Create a hidden tooltip for reading spell descriptions
local tooltip = CreateFrame("GameTooltip", "SpellDraftHiddenTooltip", UIParent, "GameTooltipTemplate")
local cacheTooltip = CreateFrame("GameTooltip", "SpellDraftCacheTooltip", UIParent, "GameTooltipTemplate")
cacheTooltip:SetOwner(UIParent, "ANCHOR_NONE")

local showHUD = true
local rarityTextures = {
  "COMM.tga",  -- Common
  "UNCO.tga",  -- Uncommon
  "RARE.tga",  -- Rare
  "EPIC.tga",  -- Epic
  "LEGE.tga",  -- Legendary
  "BROK.tga",  -- Broken (joke/trap cards?)
}

local lastSpellIDs = {}
local choiceMessageSerial = 0
local dismissToggled = false
local restoringFromDismiss = false
local isTalentDraftActive = false
local talentEssence = 0
local talentRerollCost = 0
local talentRerollsUsed = 0
local talentRerollLimit = 3
local bannedSpells = {}
local currentSpellRarities = {}
local pendingSubmittedSpellID = nil
local pendingSubmitSerial = 0
local pendingRequestToken = nil
local pendingChoiceButton
local ShowSpellChoices
tooltip:SetOwner(UIParent, "ANCHOR_NONE")
GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")
GameTooltip:SetFrameStrata("TOOLTIP")
GameTooltip:SetFrameLevel(100)
GameTooltip:SetClampedToScreen(true)

-- Determine primary faction language that is speakable and known
local function GetFactionLanguage()
  return nil
end

-- Filter out SC:* whispers from showing in chat (only for self-whispers)
local function SpellChoiceWhisperFilter(_, _, msg, sender)
  if sender == UnitName("player") then
    if msg:match("^SC:%d+$") or
       msg:match("^SC_BAN:%d+$") or
       msg:match("^SC_BUY_TALENT:%d+$") or
       msg:match("^SC_COMMIT_TALENTS:%-?%d+:.+$") or
       msg:match("^SC_REFUND_TALENT:%-?%d+:%d+$") or
       msg == "SC_CHECK" or
       msg == "SC_REROLL" or
       msg:match("^SC_REROLL:%-?%d+:%d+:%d+:%d+$") or
       msg == "SC_REPLACE_BANNED" then
      return true
    end
  end
end
local bansLeft = 0
local rerollsLeft = 0
local unlimitedReroll = false
local banMode = false
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", SpellChoiceWhisperFilter)         -- incoming
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", SpellChoiceWhisperFilter) -- outgoing

local unlocked = false -- ← Controlled by server response
local frame = SpellChoiceFrame
SpellChoiceFrame:EnableMouse(true)
SpellChoiceFrame:SetFrameStrata("TOOLTIP")
GameTooltip:SetClampedToScreen(true)
local buttons = {SpellChoiceButton1, SpellChoiceButton2, SpellChoiceButton3}
SpellChoiceRerollButton:SetText(L("Reroll"))
SpellChoiceDismissButton:SetText(L("Dismiss"))

local TalentEssenceText = SpellChoiceFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
TalentEssenceText:SetPoint("BOTTOM", SpellChoiceRerollButton, "TOP", 0, 7)
TalentEssenceText:SetText("")
TalentEssenceText:Hide()

-- A pending draft belongs to the character, not to the lifetime of the large
-- card frame.  Other panels (including the SpellDraft grimoire) may hide the
-- card frame, so keep a small independent recovery button on UIParent until a
-- choice is actually consumed by the server.
local function UpdatePendingChoiceButton()
  if not pendingChoiceButton then return end
  local hasPending = #lastSpellIDs > 0
  if hasPending and not SpellChoiceFrame:IsShown() then
    pendingChoiceButton:SetText(isTalentDraftActive and L("Pending Talent Draft") or L("Pending Spell Draft"))
    pendingChoiceButton:Show()
  else
    pendingChoiceButton:Hide()
  end
end

local function RestorePendingChoices()
  dismissToggled = false
  restoringFromDismiss = true
  if SpellDraftDB then SpellDraftDB.dismissToggled = false end
  if #lastSpellIDs > 0 then
    ShowSpellChoices(lastSpellIDs)
  else
    local target = UnitName("player")
    if target then SendChatMessage("SC_CHECK", "WHISPER", GetFactionLanguage(), target) end
  end
  restoringFromDismiss = false
  UpdatePendingChoiceButton()
end

pendingChoiceButton = CreateFrame("Button", "SpellDraftPendingChoiceButton", UIParent, "UIPanelButtonTemplate")
pendingChoiceButton:SetSize(142, 24)
pendingChoiceButton:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 118)
pendingChoiceButton:SetFrameStrata("FULLSCREEN_DIALOG")
pendingChoiceButton:SetClampedToScreen(true)
pendingChoiceButton:SetScript("OnClick", RestorePendingChoices)
pendingChoiceButton:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_TOP")
  GameTooltip:SetText(L("A draft choice is waiting"))
  GameTooltip:AddLine(L("Click to reopen the same three cards. No tome or draft is consumed."), 1, 1, 1, true)
  GameTooltip:Show()
end)
pendingChoiceButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
pendingChoiceButton:Hide()

UpdateManualPlacementButton = function()
  if not manualPlacementButton then return end
  while #pendingManualPlacements > 0
      and ActionBarContainsSpellChain(pendingManualPlacements[1].chainIDs) do
    local completed = table.remove(pendingManualPlacements, 1)
    pendingManualBySpell[completed.spellID] = nil
  end
  if #pendingManualPlacements == 0 then
    manualPlacementButton:Hide()
    if manualPlacementCloseButton then manualPlacementCloseButton:Hide() end
    return
  end
  local spellName = GetSpellInfo(pendingManualPlacements[1].spellID) or L("Unknown Spell")
  manualPlacementButton:SetText(L("Place on action bar: %s", spellName))
  manualPlacementButton:Show()
  if manualPlacementCloseButton then manualPlacementCloseButton:Show() end
end

-- Cursor/action-slot mutation is protected by this client when invoked from a
-- delayed server acknowledgement. A real mouse click supplies the hardware
-- event, so preserve every failed placement in this small one-click queue.
manualPlacementButton = CreateFrame("Button", "SpellDraftManualPlacementButton", UIParent, "UIPanelButtonTemplate")
manualPlacementButton:SetSize(230, 26)
local function ManualPlacementPositionKey()
  return (GetRealmName() or "") .. ":" .. (UnitName("player") or "")
end

local function RestoreManualPlacementPosition()
  local key = ManualPlacementPositionKey()
  local saved = SpellDraftDB and SpellDraftDB.manualPlacementPositions
      and SpellDraftDB.manualPlacementPositions[key]
  manualPlacementButton:ClearAllPoints()
  if saved and saved.point and saved.relativePoint and saved.x and saved.y then
    manualPlacementButton:SetPoint(saved.point, UIParent, saved.relativePoint, saved.x, saved.y)
  else
    manualPlacementButton:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 148)
  end
end

local function SaveManualPlacementPosition()
  local point, _, relativePoint, x, y = manualPlacementButton:GetPoint(1)
  if not point then return end
  SpellDraftDB = SpellDraftDB or {}
  SpellDraftDB.manualPlacementPositions = SpellDraftDB.manualPlacementPositions or {}
  SpellDraftDB.manualPlacementPositions[ManualPlacementPositionKey()] = {
    point = point,
    relativePoint = relativePoint,
    x = math.floor((x or 0) + 0.5),
    y = math.floor((y or 0) + 0.5),
  }
end

RestoreManualPlacementPosition()
manualPlacementButton:SetFrameStrata("FULLSCREEN_DIALOG")
manualPlacementButton:SetClampedToScreen(true)
manualPlacementButton:SetMovable(true)
manualPlacementButton:RegisterForDrag("LeftButton")
manualPlacementButton:SetScript("OnDragStart", function(self)
  self:StartMoving()
end)
manualPlacementButton:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  SaveManualPlacementPosition()
end)
manualPlacementButton:SetScript("OnClick", function()
  local request = pendingManualPlacements[1]
  if not request then return end
  local serial = actionPlacementBySpell[request.spellID]
  PlaceAcceptedSpellOnce(request.spellID, request.chainIDs, serial, 6, true)
  table.remove(pendingManualPlacements, 1)
  pendingManualBySpell[request.spellID] = nil
  UpdateManualPlacementButton()
end)
manualPlacementButton:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_TOP")
  GameTooltip:SetText(L("Action bar placement requires one click"))
  GameTooltip:AddLine(L("The spell is already learned. Click to place it in the first visible empty action slot."), 1, 1, 1, true)
  GameTooltip:AddLine(L("Drag this bar to move it. Its position is saved for this character."), 0.35, 0.85, 1, true)
  GameTooltip:Show()
end)
manualPlacementButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
manualPlacementButton:Hide()

-- The client may already have placed a low-level spell while its protected
-- action-slot state is still stale to addon code. The close control dismisses
-- only this fallback request; it never touches the spell or draft state.
manualPlacementCloseButton = CreateFrame("Button", "SpellDraftManualPlacementCloseButton", UIParent, "UIPanelCloseButton")
manualPlacementCloseButton:SetSize(26, 26)
manualPlacementCloseButton:SetPoint("LEFT", manualPlacementButton, "RIGHT", 4, 0)
manualPlacementCloseButton:SetFrameStrata("FULLSCREEN_DIALOG")
manualPlacementCloseButton:SetClampedToScreen(true)
manualPlacementCloseButton:SetScript("OnClick", function()
  local request = table.remove(pendingManualPlacements, 1)
  if request then pendingManualBySpell[request.spellID] = nil end
  UpdateManualPlacementButton()
end)
manualPlacementCloseButton:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_TOP")
  GameTooltip:SetText(L("Dismiss this placement reminder"))
  GameTooltip:AddLine(L("The learned spell and draft progress are not affected."), 1, 1, 1, true)
  GameTooltip:Show()
end)
manualPlacementCloseButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
manualPlacementCloseButton:Hide()

local pendingChoiceWatcher = CreateFrame("Frame")
local pendingChoiceElapsed = 0
pendingChoiceWatcher:SetScript("OnUpdate", function(_, elapsed)
  pendingChoiceElapsed = pendingChoiceElapsed + elapsed
  if pendingChoiceElapsed >= 0.25 then
    pendingChoiceElapsed = 0
    UpdatePendingChoiceButton()
    if UpdateManualPlacementButton then UpdateManualPlacementButton() end
  end
end)

-- ============================================================================
-- Custom SpellDraft Button Skinner
-- ============================================================================
local function SkinSpellDraftButton(btn, btnType)
  if not btn or btn.sdSkinned then return end
  btn.sdSkinned = true

  -- Clear standard Blizzard UIPanelButton textures
  if btn.SetNormalTexture then btn:SetNormalTexture("") end
  if btn.SetHighlightTexture then btn:SetHighlightTexture("") end
  if btn.SetPushedTexture then btn:SetPushedTexture("") end
  if btn.SetDisabledTexture then btn:SetDisabledTexture("") end

  -- Configure standard WoW 3.3.5a Backdrop
  btn:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
  })

  -- Dark void background
  btn:SetBackdropColor(0.04, 0.06, 0.12, 0.92)

  -- Theme color definitions
  local theme = {
    reroll = {
      border = { r = 0.61, g = 0.32, b = 1.0, a = 0.9 },        -- Mystical Purple (#9d52ff)
      hoverBorder = { r = 0.97, g = 0.45, b = 0.08, a = 1.0 },  -- Spellfire Orange (#f97316)
      font = "Fonts\\FRIZQT__.TTF",
      size = 11
    },
    ban = {
      border = { r = 0.95, g = 0.25, b = 0.37, a = 0.9 },       -- Crimson Red (#f43f5e)
      hoverBorder = { r = 1.0, g = 0.45, b = 0.45, a = 1.0 },
      font = "Fonts\\FRIZQT__.TTF",
      size = 11
    },
    dismiss = {
      border = { r = 0.83, g = 0.68, b = 0.21, a = 0.9 },       -- Antique Gold (#d4af37)
      hoverBorder = { r = 1.0, g = 0.88, b = 0.35, a = 1.0 },
      font = "Fonts\\FRIZQT__.TTF",
      size = 11
    }
  }

  local t = theme[btnType] or theme.dismiss
  btn.sdTheme = t
  btn:SetBackdropBorderColor(t.border.r, t.border.g, t.border.b, t.border.a)

  -- Custom Font Formatting
  local fs = btn:GetFontString()
  if fs then
    fs:SetFont(t.font, t.size, "OUTLINE")
    fs:SetShadowOffset(1, -1)
    fs:SetShadowColor(0, 0, 0, 1)
  end

  if not btn.sdHooked then
    btn.sdHooked = true
    btn:HookScript("OnEnter", function(self)
      if self:IsEnabled() then
        self:SetBackdropColor(0.12, 0.16, 0.28, 0.95)
        local h = self.sdTheme.hoverBorder
        self:SetBackdropBorderColor(h.r, h.g, h.b, h.a)
      end
    end)

    btn:HookScript("OnLeave", function(self)
      self:SetBackdropColor(0.04, 0.06, 0.12, 0.92)
      if self.sdBanActive then
        self:SetBackdropBorderColor(1.0, 0.25, 0.35, 1.0)
      else
        local b = self.sdTheme.border
        self:SetBackdropBorderColor(b.r, b.g, b.b, b.a)
      end
    end)
  end
end

-- Using shared timer frame for Delay
local function UpdateRerollButton()
  if not SpellChoiceRerollButton then return end
  SkinSpellDraftButton(SpellChoiceRerollButton, "reroll")

  local label
  if isTalentDraftActive then
    label = talentRerollCost > 0 and L("Reroll (%d Essence)", talentRerollCost) or L("Reroll limit reached")
    TalentEssenceText:SetText(L("Talent Essence: %d · Rerolls: %d / %d", talentEssence, talentRerollsUsed, talentRerollLimit))
    TalentEssenceText:Show()
  elseif unlimitedReroll then
    label = L("Reroll (%s)", "∞")
    TalentEssenceText:Hide()
  else
    label = L("Reroll (%s)", rerollsLeft)
    TalentEssenceText:Hide()
  end
  SpellChoiceRerollButton:SetText(label)

  local canTalentReroll = isTalentDraftActive and talentRerollCost > 0 and talentEssence >= talentRerollCost
  local canNormalReroll = not isTalentDraftActive and (rerollsLeft > 0 or unlimitedReroll)
  if (canTalentReroll or canNormalReroll) and not banMode then
    SpellChoiceRerollButton:Enable()
    SpellChoiceRerollButton:SetAlpha(1.0)
    SpellChoiceRerollButton:SetBackdropColor(0.04, 0.06, 0.12, 0.92)
    local b = SpellChoiceRerollButton.sdTheme.border
    SpellChoiceRerollButton:SetBackdropBorderColor(b.r, b.g, b.b, b.a)
  else
    SpellChoiceRerollButton:Disable()
    SpellChoiceRerollButton:SetAlpha(0.4)
    SpellChoiceRerollButton:SetBackdropColor(0.02, 0.03, 0.06, 0.8)
    SpellChoiceRerollButton:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.3)
  end
end
-- Debug helper
local function Debug(msg)
  --DEFAULT_CHAT_FRAME:AddMessage("|cff9999ff[DEBUG]|r " .. tostring(msg))
end

-- Request prestige status on login/reload
local function RequestPrestigeStatus()
  local target = UnitName("player")
  if target then
    SendChatMessage("SC_CHECK", "WHISPER", GetFactionLanguage(), UnitName("player"))
    --Debug("Sent SC_CHECK to server")
  else
    print("SpellChoice: Failed to send SC message — player name is nil.")
  end
end

-- [beascend] level-up style reward (sound + gold screen flash) on draft pick,
-- replaces the broken server-cast 24312 "Level Up" spell visual (rendered as a white pillar).
local function SpellDraft_LevelUpReward()
  PlaySoundFile("Sound\\Interface\\LevelUp.wav")
  if not SpellDraftLevelFlash then
    local f = CreateFrame("Frame", "SpellDraftLevelFlash", UIParent)
    f:SetAllPoints(UIParent)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:EnableMouse(false)
    local t = f:CreateTexture(nil, "OVERLAY")
    t:SetAllPoints(f)
    t:SetTexture("Interface\\FullScreenTextures\\LowHealth")
    t:SetBlendMode("ADD")
    t:SetVertexColor(1.0, 0.82, 0.25)
    f:Hide()
  end
  SpellDraftLevelFlash:SetAlpha(0)
  SpellDraftLevelFlash:Show()
  UIFrameFadeIn(SpellDraftLevelFlash, 0.12, 0, 0.55)
  Delay(0.14, function() UIFrameFadeOut(SpellDraftLevelFlash, 0.55, 0.55, 0) end)
  Delay(0.75, function() if SpellDraftLevelFlash then SpellDraftLevelFlash:Hide() end end)
end

local function HandleSpellClick(self)
  local spellID = self:GetID()
  if not spellID or spellID <= 0 then return end
  if pendingSubmittedSpellID then return end

  if bannedSpells[spellID] then
    Debug("[Ban] Blocked click on banned spell ID: " .. spellID)
    return
  end

  PlaySound("igMainMenuOptionCheckBoxOn")

  if banMode then
    local target = UnitName("player")
    if target then
      SendChatMessage("SC_BAN:" .. spellID, "WHISPER", GetFactionLanguage(), target)
      Debug("[Ban] Attempting to ban spell ID: " .. spellID)
    end
    return
  end

  -- Disable the visible set while waiting for the server. The reward flash is
  -- deliberately delayed until SpellChoiceAccepted confirms real learning.
  for _, otherBtn in ipairs(buttons) do
    otherBtn:EnableMouse(false)
    if otherBtn ~= self then
      UIFrameFadeOut(otherBtn, 0.5, 1, 0.1)
    else
      otherBtn:SetScale(1.1)
      UIFrameFadeOut(otherBtn, 0.5, 1, 1)
    end
  end

  local target = UnitName("player")
  if target then
    pendingSubmittedSpellID = spellID
    pendingSubmitSerial = pendingSubmitSerial + 1
    local submitSerial = pendingSubmitSerial
    pendingRequestToken = tostring(math.floor((GetTime() or 0) * 1000)) .. tostring(submitSerial)
    -- One click sends exactly one request. Repeating SC messages created a race
    -- where the first request committed while later retries rerolled/reopened it.
    SendChatMessage("SC:" .. spellID .. ":" .. pendingRequestToken, "WHISPER", GetFactionLanguage(), target)
    Delay(4.0, function()
      if pendingSubmittedSpellID == spellID and submitSerial == pendingSubmitSerial then
        pendingSubmittedSpellID = nil
        pendingRequestToken = nil
        UIErrorsFrame:AddMessage(L("No server confirmation. The same choice is still available."), 1.0, 0.25, 0.25, 1)
        RestorePendingChoices()
      end
    end)
  end
end



-- Show spell choices to the player
ShowSpellChoices = function(spellIDs)

  if UnitAffectingCombat("player") and UnitLevel("player") > 1 then
    dismissToggled = true
    if SpellDraftDB then
      SpellDraftDB.dismissToggled = true
    end
    if SpellChoiceDismissButton then
      local btnText = isTalentDraftActive and L("Talent Draft") or L("%d Draft(s) Left", SpellDraft.DraftsLeft or 0)
      SpellChoiceDismissButton:SetText(btnText)
      SpellChoiceDismissButton:SetParent(UIParent)
      SpellChoiceDismissButton:ClearAllPoints()
      SpellChoiceDismissButton:SetPoint("CENTER", UIParent, "CENTER", 0, -160)
      SpellChoiceDismissButton:SetFrameStrata("FULLSCREEN_DIALOG")
      SpellChoiceDismissButton:EnableMouse(true)
      SpellChoiceDismissButton:Show()
    end
  end

  if dismissToggled then
    -- Full suppression: disable everything interactable
    for _, btn in ipairs(buttons) do
      btn:Hide()
      btn:EnableMouse(false)
      btn:SetScript("OnEnter", nil)
      btn:SetScript("OnLeave", nil)
      btn:SetScript("OnClick", nil)
    end

    GameTooltip:Hide()
    GameTooltip:ClearAllPoints()
    GameTooltip:SetOwner(UIParent, "ANCHOR_NONE")

    SpellChoiceFrame:Hide()
    SpellChoiceFrame:EnableMouse(false)
    SpellChoiceFrame:SetAlpha(0)
    return
  end

  -- Restore clean UI state from minimized/dismissed state
  SpellChoiceFrame:SetAlpha(1)
  SpellChoiceFrame:EnableMouse(true)
  if SpellChoiceDismissButton then
    SpellChoiceDismissButton:SetParent(SpellChoiceFrame)
    SpellChoiceDismissButton:ClearAllPoints()
    SpellChoiceDismissButton:SetPoint("CENTER", SpellChoiceTitle, "TOP", 0, -290)
    SpellChoiceDismissButton:SetFrameStrata("FULLSCREEN_DIALOG")
    SpellChoiceDismissButton:SetText(L("Dismiss"))
    SpellChoiceDismissButton:SetAlpha(1)
    SpellChoiceDismissButton:Enable()
    SpellChoiceDismissButton:EnableMouse(true)
    SpellChoiceDismissButton:Show()
  end

  --print("SpellChoiceTitle is", SpellChoiceTitle and "found" or "MISSING")
  if not unlocked then
    --Debug("Blocked: Player is not prestiged.")
    return
  end

  -- if UnitLevel("player") == 1 then
  --   Debug("Blocked: Player is level 1. Spell choices disabled.")
  --   return
  -- end

  --Debug("Showing spell choices...")

local FALLBACK_SPELLS = {
  [75] = { name = "Auto Shot", icon = "Interface\\Icons\\Ability_Marksmanship", subName = "" },
  [5019] = { name = "Shoot", icon = "Interface\\Icons\\Ability_ShootWand", subName = "" },
  [2764] = { name = "Throw", icon = "Interface\\Icons\\Ability_Throw", subName = "" },
  [6603] = { name = "Attack", icon = "Interface\\Icons\\INV_Sword_04", subName = "" }
}

  for i = 1, #buttons do
    local spellID = tonumber(spellIDs[i])
    local btn = buttons[i]

    if spellID and btn then
      local name, subName, icon = GetSpellInfo(spellID)
      if (not name or not icon) and FALLBACK_SPELLS[spellID] then
        name = name or FALLBACK_SPELLS[spellID].name
        icon = icon or FALLBACK_SPELLS[spellID].icon
        subName = subName or FALLBACK_SPELLS[spellID].subName
      end

      btn.icon        = _G[btn:GetName() .. "Icon"]
      btn.name        = _G[btn:GetName() .. "Name"]
      --btn.mana        = _G[btn:GetName() .. "Mana"]
      --btn.castTime    = _G[btn:GetName() .. "CastTime"]
      --btn.description = _G[btn:GetName() .. "Description"]
      btn.levelReq    = _G[btn:GetName() .. "LevelReq"]

      if name and icon then
        if not btn.subNameText then
          local subNameText = btn:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
          subNameText:SetJustifyH("CENTER")
          btn.subNameText = subNameText
        end

        btn.icon:ClearAllPoints()
        btn.icon:SetPoint("TOP", btn, "TOP", 0, -90)

        btn.name:ClearAllPoints()
        btn.name:SetPoint("TOP", btn, "TOP", 0, -56)
        btn.name:SetText(name)

        btn.subNameText:ClearAllPoints()
        if subName and subName ~= "" then
          btn.subNameText:SetPoint("TOP", btn, "TOP", 0, -70)
          btn.subNameText:SetText("|cff808080" .. subName .. "|r")
          btn.subNameText:Show()
        else
          btn.subNameText:Hide()
        end

        Debug("Spell " .. i .. ": " .. name .. " (ID: " .. spellID .. ")")
        -- Force spell to load into cache
        cacheTooltip:SetOwner(UIParent, "ANCHOR_NONE")
        cacheTooltip:SetHyperlink("spell:" .. spellID)
        
      btn:SetID(spellID)
      -- GetSpellInfo already returns the complete icon path. Prefixing it again
      -- produces an invalid texture and the bright-green fallback square.
      btn:SetNormalTexture("")
      btn.icon:SetTexture(icon)

      if bannedSpells[spellID] then
        btn:SetAlpha(0.3)
        btn:Disable()
        btn:EnableMouse(false)
        Debug("[Ban] Auto-disabled banned spell ID: " .. spellID)
      else
        btn:SetAlpha(1)
        btn:Enable()
        btn:EnableMouse(true)
      end


        btn.icon:SetTexture(icon)
        local rarityFrame = _G[btn:GetName() .. "Rarity"]
        local rarityIndex = currentSpellRarities[i] or -1
        if rarityFrame and rarityIndex >= 0 then
          local rarityTex = rarityTextures[rarityIndex + 1]
          if rarityTex then
            rarityFrame:SetTexture("Interface\\AddOns\\SpellDraft\\Textures\\" .. rarityTex)
            rarityFrame:Show()
          else
            rarityFrame:Hide()
          end
        elseif rarityFrame then
          rarityFrame:Hide()
        end

        if not restoringFromDismiss then
        btn:SetScale(0.8)
        btn:SetAlpha(0)
        UIFrameFadeIn(btn, 0.6, 0, 1)

        -- Pulse animation
        local t = 0
        local pulseSpeed = 10
        local pulseDuration = (2 * math.pi) / pulseSpeed

        btn:SetScript("OnUpdate", function(self, elapsed)
          t = t + elapsed
          if t >= pulseDuration then
            self:SetScript("OnUpdate", nil)
            self:SetScale(1)
          else
            local scale = 1 + 0.05 * math.sin(t * pulseSpeed)
            self:SetScale(scale)
          end
        end)
      else
        btn:SetScale(1)
        btn:SetAlpha(1)
        btn:SetScript("OnUpdate", nil)
      end
        btn:EnableMouse(true)
        btn:Show()
      else
        Debug("Missing data for spell ID: " .. tostring(spellID))
        btn:SetID(spellID)
        btn.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        btn.name:SetText(L("Spell #%d", spellID))
        if btn.description then
          btn.description:SetText(L("Spell data not cached."))
        end
        if btn.levelReq then
          btn.levelReq:SetText("")
        end
        btn:EnableMouse(true)
        btn:Show()
        local rarityFrame = _G[btn:GetName() .. "Rarity"]
        if rarityFrame then
          rarityFrame:Hide()
        end
        tooltip:SetOwner(UIParent, "ANCHOR_NONE")
        tooltip:SetHyperlink("spell:" .. spellID)
      end
    else
      Debug("Invalid spell or button at index " .. tostring(i))
      if btn then btn:Hide() end
    end
  end

  if isTalentDraftActive then
    if SpellChoiceRerollButton then
      SpellChoiceRerollButton:Show()
      UpdateRerollButton()
    end
    if SpellChoiceBanButton then SpellChoiceBanButton:Hide() end
  else
    if SpellChoiceRerollButton then SpellChoiceRerollButton:Show() end
    if SpellChoiceBanButton then SpellChoiceBanButton:Show() end
  end

  frame:Show()
  UpdatePendingChoiceButton()
end


-- Event listening for addon messages
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

local enterTime = nil
local isWorldLoaded = false
local prestigeRetries = 0

local function TryRequestPrestige()
  if not enterTime then
    enterTime = GetTime()
  end

  local target = UnitName("player")
  if target and target ~= UNKNOWNOBJECT and target ~= "" then
    local elapsed = GetTime() - enterTime
    local minDelay = 0.5
    if UnitLevel("player") == 1 then
      minDelay = 5.0
    end

    if elapsed >= minDelay and isWorldLoaded then
      RequestPrestigeStatus()
    elseif prestigeRetries < 20 then
      prestigeRetries = prestigeRetries + 1
      Delay(0.5, TryRequestPrestige)
    end
  elseif prestigeRetries < 20 then
    prestigeRetries = prestigeRetries + 1
    Delay(0.5, TryRequestPrestige)
  end
end

eventFrame:SetScript("OnEvent", function(self, event, arg1, arg2, arg3, arg4)
  if event == "ADDON_LOADED" and arg1 == "SpellDraft" then
    SpellDraftDB = SpellDraftDB or {}
    SpellDraft.RestoreTalentStateCache(true)
    if SpellDraftDB.showHUD == nil then
      SpellDraftDB.showHUD = true
    end
    if SpellDraftDB.dismissToggled == nil then
      SpellDraftDB.dismissToggled = false
    end
    showHUD = SpellDraftDB.showHUD
    -- This SavedVariable is account-wide. Never restore another character's
    -- minimized Draft UI before this character is confirmed as Random Draft.
    dismissToggled = false
    SpellDraftDB.dismissToggled = false
    SpellChoiceFrame:Hide()
    if SpellChoiceDismissButton then SpellChoiceDismissButton:Hide() end

  elseif event == "PLAYER_ENTERING_WORLD" then
    SpellDraft.RestoreTalentStateCache(true)
    isWorldLoaded = true
    prestigeRetries = 0
    enterTime = nil
    TryRequestPrestige()

  elseif event == "CHAT_MSG_ADDON" then
    local prefix, message, channel, sender = arg1, arg2, arg3, arg4
    if prefix == "SpellChoiceStatus" then
      if message == "prestiged" then
        unlocked = true
        SpellDraft.Unlocked = true
        Debug("SpellChoice unlocked (prestiged).")
      else
        unlocked = false
        SpellDraft.Unlocked = false
        dismissToggled = false
        if SpellDraftDB then SpellDraftDB.dismissToggled = false end
        choiceMessageSerial = choiceMessageSerial + 1
        lastSpellIDs = {}
        SpellChoiceFrame:Hide()
        if SpellChoiceDismissButton then SpellChoiceDismissButton:Hide() end
        Debug("SpellChoice locked (not prestiged).")
      end
      if SpellDraft.UpdateHUD then SpellDraft.UpdateHUD() end

    elseif prefix == "SpellChoiceIsTalent" then
      isTalentDraftActive = (message == "1")
      UpdateRerollButton()

    elseif prefix == "SpellChoiceTalentEssence" then
      -- New protocol sends the uncapped balance only. Accept the old
      -- `current:cap` payload during rolling upgrades for compatibility.
      local current = string.match(message or "", "^(%d+)")
      talentEssence = tonumber(current) or 0
      SpellDraft.TalentEssence = talentEssence
      SpellDraft.TalentEssenceCap = nil
      UpdateRerollButton()
      if SpellDraft.UpdateStatsDisplay then
        SpellDraft.UpdateStatsDisplay()
      end

    elseif prefix == "SpellChoiceTalentReroll" then
      local cost, used, limit = string.match(message or "", "^(%d+):(%d+):(%d+)$")
      talentRerollCost = tonumber(cost) or 0
      talentRerollsUsed = tonumber(used) or 0
      talentRerollLimit = tonumber(limit) or 3
      UpdateRerollButton()

    elseif prefix == "SCTRefundCost" then
      SpellDraft.TalentRefundCost = math.max(0, tonumber(message) or 1)

    elseif prefix == "SpellChoiceBansLeft" then
      bansLeft = tonumber(message) or 0
      SpellDraft.BansLeft = bansLeft
      if SpellChoiceBanButton then
        SpellChoiceBanButton:SetText(banMode and L("Ban [ON] (%d)", bansLeft) or L("Ban (%d)", bansLeft))
      end
      if SpellDraft.UpdateStatsDisplay then
        SpellDraft.UpdateStatsDisplay()
      end
  elseif prefix == "SpellChoiceBans" then
    bannedSpells = {}
    local count = 0
    for id in string.gmatch(message, "%d+") do
      bannedSpells[tonumber(id)] = true
      count = count + 1
    end
    Debug("Loaded " .. count .. " banned spells from server.")   
  elseif prefix == "SpellChoiceBanAccepted" then
    local bannedID = tonumber(message)
    for _, btn in ipairs(buttons) do
      if btn:GetID() == bannedID then
        btn:SetAlpha(0.3)
        btn:Disable()
        Debug("[Ban] Server confirmed ban of spell ID " .. bannedID)
      end
    end

    -- Immediately refresh with new spell if needed
    local target = UnitName("player")
    if target then
      Delay(0.3, function()
        SendChatMessage("SC_REPLACE_BANNED", "WHISPER", GetFactionLanguage(), target)
      end)      
      Debug("[Ban] Immediately requested replacement for banned spell ID: " .. bannedID)
    end

  elseif prefix == "SpellChoiceBanDenied" then
      UIErrorsFrame:AddMessage(L("No bans remaining."), 1.0, 0.2, 0.2, 1)
      Debug("[Ban] Ban denied: no bans left")
    elseif prefix == "SpellChoice" then
      Debug("Received SpellChoice message: " .. message)

      local spellIDs = {}
      for id in string.gmatch(message, "%d+") do
        table.insert(spellIDs, tonumber(id))
      end

      -- Compare to last shown list
      local isDuplicate = #spellIDs == #lastSpellIDs
      if isDuplicate then
        for i = 1, #spellIDs do
          if spellIDs[i] ~= lastSpellIDs[i] then
            isDuplicate = false
            break
          end
        end
      end

      if isDuplicate and SpellChoiceFrame:IsShown() then
        Debug("Ignored duplicate spellID list (frame already shown).")
        return
      end

      -- If we got here, it's a new set
      lastSpellIDs = spellIDs
      choiceMessageSerial = choiceMessageSerial + 1
      local messageSerial = choiceMessageSerial
      dismissToggled = false
      if SpellDraftDB then
        SpellDraftDB.dismissToggled = false
      end
      Delay(0.5, function()
        -- Only the newest server set may win the delayed cache/display pass.
        if messageSerial == choiceMessageSerial then
          ShowSpellChoices(spellIDs)
        end
      end)
    elseif prefix == "SCBar" then
      local finalText, chainText = string.match(message or "", "^(%d+):?(.*)$")
      local finalID = tonumber(finalText)
      if finalID then
        local chainIDs = { [finalID] = true }
        for id in string.gmatch(chainText or "", "%d+") do
          chainIDs[tonumber(id)] = true
        end
        QueueAcceptedSpellPlacement(finalID, chainIDs)
      end

    elseif prefix == "SCResult" then
      local resultCode, resultSpell, resultToken = string.match(message or "", "^([^:]+):(%d+):?(.*)$")
      local resultID = tonumber(resultSpell)
      if resultID and pendingSubmittedSpellID == resultID
          and (not resultToken or resultToken == "" or resultToken == pendingRequestToken) then
        pendingSubmittedSpellID = nil
        pendingRequestToken = nil
        pendingSubmitSerial = pendingSubmitSerial + 1
        if resultCode == "OK" then
          SpellDraft_LevelUpReward()
        else
          UIErrorsFrame:AddMessage(L("The spell was not learned. Your draft was not consumed."), 1.0, 0.25, 0.25, 1)
          RestorePendingChoices()
        end
      end

    elseif prefix == "SpellChoiceAccepted" then
      local acceptedID = tonumber(message)
      if acceptedID and pendingSubmittedSpellID == acceptedID then
        pendingSubmittedSpellID = nil
        pendingRequestToken = nil
        pendingSubmitSerial = pendingSubmitSerial + 1
        SpellDraft_LevelUpReward()
      end

    elseif prefix == "SpellChoiceFailed" then
      local failedID = tonumber(message)
      if not failedID or pendingSubmittedSpellID == failedID then
        pendingSubmittedSpellID = nil
        pendingRequestToken = nil
        pendingSubmitSerial = pendingSubmitSerial + 1
        UIErrorsFrame:AddMessage(L("The spell was not learned. Your draft was not consumed."), 1.0, 0.25, 0.25, 1)
        RestorePendingChoices()
      end

    elseif prefix == "SpellChoiceClose" then
      -- Invalidate any delayed ShowSpellChoices callback that was queued before
      -- the server consumed the final entitlement and closed the draft.
      choiceMessageSerial = choiceMessageSerial + 1
      lastSpellIDs = {}
      isTalentDraftActive = false
      TalentEssenceText:Hide()
      frame:Hide()

    elseif prefix == "SCABegin" then
      local token, expectedText = string.match(message or "", "^([^|]+)|(%d+)$")
      local expected = tonumber(expectedText)
      if token and expected then
        chunkedAcquiredToken = token
        chunkedAcquiredExpected = expected
        chunkedAcquiredReceived = 0
        chunkedAcquiredIds = {}
        chunkedAcquiredSeen = {}
      end

    elseif prefix == "SCAPart" then
      local token, spellText = string.match(message or "", "^([^|]+)|(%d+)$")
      local spellId = tonumber(spellText)
      if token and token == chunkedAcquiredToken and spellId and spellId > 0
          and not chunkedAcquiredSeen[spellId] then
        chunkedAcquiredSeen[spellId] = true
        chunkedAcquiredReceived = chunkedAcquiredReceived + 1
        table.insert(chunkedAcquiredIds, spellId)
      end

    elseif prefix == "SCAEnd" then
      local token, declaredText = string.match(message or "", "^([^|]+)|(%d+)$")
      local declared = tonumber(declaredText)
      if token and token == chunkedAcquiredToken and declared
          and declared == chunkedAcquiredExpected
          and chunkedAcquiredReceived == declared then
        table.sort(chunkedAcquiredIds)
        acquiredStateV3Received = true
        talentStateV2Received = true
        ApplyAuthoritativeTalentState(chunkedAcquiredIds)
      end
      if token and token == chunkedAcquiredToken then
        chunkedAcquiredToken = nil
        chunkedAcquiredExpected = 0
        chunkedAcquiredReceived = 0
        chunkedAcquiredIds = {}
        chunkedAcquiredSeen = {}
      end

    elseif prefix == "SCTState" then
      local declaredText, payload = string.match(message or "", "^(%d+)|(.*)$")
      local declared = tonumber(declaredText)
      local ids = {}
      if declared then
        for id in string.gmatch(payload or "", "%d+") do
          table.insert(ids, tonumber(id))
        end
      end
      -- Only a complete count-framed packet may replace confirmed state.
      if not acquiredStateV3Received and declared and #ids == declared then
        talentStateV2Received = true
        ApplyAuthoritativeTalentState(ids)
      end

    elseif prefix == "SCDI" then
      local rank = math.max(0, math.min(5, tonumber(message) or 0))
      local ranks = CopyTalentRanks(SpellDraft.ConfirmedTalentRanks or {})
      if rank > 0 then
        ranks[20257] = rank
      else
        ranks[20257] = nil
      end
      ApplyAuthoritativeTalentRanks(ranks)

    elseif prefix == "SCAK" then
      -- User-verified B0.10.2 display-only channel for Ancestral Knowledge.
      -- It projects DB rank 0..5 into the UI and never mutates Aura/stats.
      local rank = math.max(0, math.min(5, tonumber(message) or 0))
      local ranks = CopyTalentRanks(SpellDraft.ConfirmedTalentRanks or {})
      if rank > 0 then
        ranks[17485] = rank
      else
        ranks[17485] = nil
      end
      ApplyAuthoritativeTalentRanks(ranks)

    elseif prefix == "SCDS" then
      -- B0.5.1 display-only DB projection for Divine Strength.  This packet is
      -- deliberately handled after/copying the current table so it replaces
      -- only 20262 and cannot erase unrelated confirmed talents.
      local rank = math.max(0, math.min(5, tonumber(message) or 0))
      local ranks = CopyTalentRanks(SpellDraft.ConfirmedTalentRanks or {})
      if rank > 0 then
        ranks[20262] = rank
      else
        ranks[20262] = nil
      end
      ApplyAuthoritativeTalentRanks(ranks)

    elseif prefix == "SCSOA" then
      -- DB-only projection for Strength of Arms, identical in responsibility
      -- to SCDI/SCAK/SCDS.  Native Aura owns Strength/Stamina/Expertise; this
      -- packet changes only the confirmed 46865 rank shown by both UI panels.
      local rank = math.max(0, math.min(2, tonumber(message) or 0))
      local ranks = CopyTalentRanks(SpellDraft.ConfirmedTalentRanks or {})
      if rank > 0 then
        ranks[46865] = rank
      else
        ranks[46865] = nil
      end
      ApplyAuthoritativeTalentRanks(ranks)

    elseif prefix == "SCTRBegin" then
      local tokenText, countText = string.match(message or "", "^(%d+)|(%d+)$")
      local token, count = tonumber(tokenText), tonumber(countText)
      if token and count and count >= 0 and count <= 512 then
        chunkedTalentRankToken = token
        chunkedTalentRankExpected = count
        chunkedTalentRankReceived = 0
        chunkedTalentRanks = {}
      else
        ResetChunkedTalentRankFrame()
      end

    elseif prefix == "SCTRPart" then
      local tokenText, firstText, rankText = string.match(message or "", "^(%d+)|(%d+)=(%d+)$")
      local token = tonumber(tokenText)
      local firstRankSpellId, rank = tonumber(firstText), tonumber(rankText)
      if token and token == chunkedTalentRankToken and firstRankSpellId and rank
          and rank > 0 and rank <= 9 and not chunkedTalentRanks[firstRankSpellId] then
        chunkedTalentRanks[firstRankSpellId] = rank
        chunkedTalentRankReceived = chunkedTalentRankReceived + 1
      end

    elseif prefix == "SCTREnd" then
      local tokenText, countText = string.match(message or "", "^(%d+)|(%d+)$")
      local token, count = tonumber(tokenText), tonumber(countText)
      if token and token == chunkedTalentRankToken and count == chunkedTalentRankExpected
          and chunkedTalentRankReceived == chunkedTalentRankExpected then
        ApplyAuthoritativeTalentRanks(chunkedTalentRanks)
      end
      ResetChunkedTalentRankFrame()

    elseif prefix == "SCTRank" or prefix == "SCTReg" then
      -- Shared authoritative delta/final registry projection for controlled
      -- spell-backed talents. Copy
      -- the current table and replace exactly one first-rank key; applying the
      -- result also reconciles an impossible local Pending point immediately.
      local firstText, rankText = string.match(message or "", "^(%d+)=(%d+)$")
      local firstRankSpellId, rank = tonumber(firstText), tonumber(rankText)
      local talent = firstRankSpellId and SpellDraftTalentDB and SpellDraftTalentDB[firstRankSpellId]
      local maxRank = talent and tonumber(talent.maxRank) or 9
      if firstRankSpellId and rank and rank >= 0 and rank <= maxRank then
        local ranks = CopyTalentRanks(SpellDraft.ConfirmedTalentRanks or {})
        if rank > 0 then ranks[firstRankSpellId] = rank
        else ranks[firstRankSpellId] = nil end
        ApplyAuthoritativeTalentRanks(ranks)
      end

    elseif prefix == "SCTRanks" then
      local declaredText, payload = string.match(message or "", "^(%d+)|(.*)$")
      local declared = tonumber(declaredText)
      local ranks, received = {}, 0
      if declared then
        for firstText, rankText in string.gmatch(payload or "", "(%d+)=(%d+)") do
          local firstRankSpellId, rank = tonumber(firstText), tonumber(rankText)
          if firstRankSpellId and rank and rank > 0 and not ranks[firstRankSpellId] then
            ranks[firstRankSpellId] = rank
            received = received + 1
          end
        end
      end
      if declared and received == declared then
        ApplyAuthoritativeTalentRanks(ranks)
      end

    elseif prefix == "SCTalents" or prefix == "SpellChoiceTalents" then
      -- Legacy compatibility. Once count-framed state has arrived, ignore
      -- later legacy packets. Also do not let an ambiguous empty legacy frame
      -- erase a non-empty per-character snapshot; SCTState will explicitly
      -- send 0| when the server really has no talents.
      if not talentStateV2Received then
        local ids = {}
        if message and message ~= "" then
          for id in string.gmatch(message, "%d+") do
            table.insert(ids, tonumber(id))
          end
        end
        if #ids > 0 then
          ApplyAuthoritativeTalentState(ids)
        else
          SpellDraft.RestoreTalentStateCache(false)
        end
      end

    elseif prefix == "SCTPoints" or prefix == "SpellChoiceTalentPoints" then
      local points = tonumber(message) or 0
      SpellDraft.TalentPoints = points
      if SpellDraft.UpdateStatsDisplay then
        SpellDraft.UpdateStatsDisplay()
      end

    elseif prefix == "SCTCommit" then
      local token, status, detail = string.match(message or "", "^([^:]+):([^:]+):?(.*)$")
      if SpellDraft.HandleTalentCommitResult then
        SpellDraft.HandleTalentCommitResult(status == "ok", detail, token)
      end

    elseif prefix == "SCTRefund" then
      local token, status, detail = string.match(message or "", "^([^:]+):([^:]+):?(.*)$")
      if SpellDraft.HandleTalentRefundResult then
        SpellDraft.HandleTalentRefundResult(status == "ok", detail, token)
      end

    elseif prefix == "SpellChoiceTalentCommit" then
      local ok, detail = string.match(message or "", "^(%a+):?(.*)$")
      if SpellDraft.HandleTalentCommitResult then
        SpellDraft.HandleTalentCommitResult(ok == "ok", detail)
      end

    elseif prefix == "SpellChoicePrestigeTokens" then
      local tokens = tonumber(message) or 0
      SpellDraft.PrestigeTokens = tokens
      if SpellDraft.UpdateStatsDisplay then
        SpellDraft.UpdateStatsDisplay()
      end
      if SpellDraft.UpdatePrestigeShopTokens then
        SpellDraft.UpdatePrestigeShopTokens()
      end

    elseif prefix == "SpellChoicePrestigeLevel" then
      local level = tonumber(message) or 0
      SpellDraft.PrestigeLevel = level
      if SpellDraft.UpdateStatsDisplay then
        SpellDraft.UpdateStatsDisplay()
      end

    elseif prefix == "SpellChoiceRerollDenied" then
      UIErrorsFrame:AddMessage(L("You have no rerolls remaining."), 1, 0, 0, 1)

    elseif prefix == "SpellChoiceRerolls" then
      rerollsLeft = tonumber(message) or 0
      SpellDraft.RerollsLeft = rerollsLeft
      UpdateRerollButton()
      if SpellDraft.UpdateStatsDisplay then
        SpellDraft.UpdateStatsDisplay()
      end

    elseif prefix == "SpellChoiceUnlimitedReroll" then
      unlimitedReroll = (message == "1")
      UpdateRerollButton()

    elseif prefix == "SpellChoiceDrafts" then
      local totalDrafts = tonumber(message) or 0
      SpellDraft.DraftsLeft = totalDrafts
      if SpellChoiceTitle then
        SpellChoiceTitle:SetText(L("%d Drafts Remaining", totalDrafts))
      end
      if dismissToggled and SpellChoiceDismissButton then
        SpellChoiceDismissButton:SetText(L("%d Draft(s) Left", totalDrafts))
      end
      if SpellDraft.UpdateStatsDisplay then
        SpellDraft.UpdateStatsDisplay()
      end
    elseif prefix == "SpellChoiceRarities" then
      currentSpellRarities = {}
      for r in string.gmatch(message, "-?%d+") do
        table.insert(currentSpellRarities, tonumber(r))
      end
      local rarities = {}
      for r in string.gmatch(message, "-?%d+") do
        table.insert(rarities, tonumber(r))
      end

      for i, rarity in ipairs(rarities) do
        local btn = buttons[i]
        if not btn then break end
        local rarityFrame = _G[btn:GetName() .. "Rarity"]

        if rarity and rarity >= 0 then
          local rarityTex = rarityTextures[rarity + 1]
          if rarityTex and rarityFrame then
            rarityFrame:SetTexture("Interface\\AddOns\\SpellDraft\\Textures\\" .. rarityTex)
            rarityFrame:Show()
          elseif rarityFrame then
            rarityFrame:Hide()
          end
        elseif rarityFrame then
          -- Rarity is -1 or invalid (NULL or missing)
          rarityFrame:Hide()
        end
      end
    end
  elseif event == "PLAYER_REGEN_DISABLED" then
    -- Auto-minimize choice frame on entering combat (only for level > 1)
    if UnitLevel("player") > 1 and not dismissToggled and SpellChoiceFrame:IsShown() then
      local dismissBtn = SpellChoiceDismissButton
      if dismissBtn then
        local onClick = dismissBtn:GetScript("OnClick")
        if onClick then
          onClick(dismissBtn)
        end
      end
    end
  end
end)

Debug("SpellChoice addon loaded.")

for _, btn in ipairs(buttons) do
  btn:SetScript("OnEnter", function(self)
    local spellID = self:GetID()
    if spellID and spellID > 0 then
      GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
      GameTooltip:SetHyperlink("spell:" .. spellID)
      GameTooltip:Show()
    end
  end)
  btn:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)
btn:SetScript("OnClick", HandleSpellClick)
end



local rerollCooldown = false
local rerollRequestSerial = 0

SpellChoiceRerollButton:SetScript("OnClick", function()
  PlaySound("igMainMenuOptionCheckBoxOn")
  local canTalentReroll = isTalentDraftActive and talentRerollCost > 0 and talentEssence >= talentRerollCost
  local canNormalReroll = not isTalentDraftActive and (rerollsLeft > 0 or unlimitedReroll)
  if rerollCooldown or not unlocked or (not canTalentReroll and not canNormalReroll) then
    UIErrorsFrame:AddMessage(L("Cannot reroll at this time."), 1, 0, 0, 1)
    return
  end

  rerollCooldown = true
  SpellChoiceRerollButton:Disable()

  Delay(0.5, function()
    rerollCooldown = false
    UpdateRerollButton() -- Re-enables if rerollsLeft > 0
  end)

  local target = UnitName("player")
  if target then
    -- Bind every click to one unique request and to the exact three cards the
    -- player is looking at.  The server can therefore reject a second event
    -- handler processing the same click instead of charging another reroll.
    rerollRequestSerial = rerollRequestSerial + 1
    -- WoW 3.3.5 string.format("%d") uses a signed 32-bit integer. An
    -- unbounded millisecond tick eventually becomes -2147483648, which no
    -- longer matches the server protocol and makes the reroll button inert.
    local safeTick = math.floor((GetTime() or 0) * 1000) % 10000000
    local requestToken = safeTick * 100 + (rerollRequestSerial % 100)
    if #lastSpellIDs == 3 then
      SendChatMessage(string.format("SC_REROLL:%d:%d:%d:%d",
        requestToken,
        tonumber(lastSpellIDs[1]) or 0,
        tonumber(lastSpellIDs[2]) or 0,
        tonumber(lastSpellIDs[3]) or 0),
        "WHISPER", GetFactionLanguage(), target)
    else
      -- Compatibility fallback for a draft restored before its cards finished
      -- loading. Normal visible three-card rerolls always use the guarded form.
      SendChatMessage("SC_REROLL", "WHISPER", GetFactionLanguage(), target)
    end
  else
    print("SpellChoice: Failed to send SC_REROLL — player name is nil.")
  end
end)
SpellChoiceBanButton = CreateFrame("Button", "SpellChoiceBanButton", SpellChoiceFrame, "UIPanelButtonTemplate")
SpellChoiceBanButton:SetSize(110, 26)
SpellChoiceBanButton:SetText(L("Ban"))
SpellChoiceBanButton:SetPoint("LEFT", SpellChoiceRerollButton, "RIGHT", 12, 0)

SkinSpellDraftButton(SpellChoiceRerollButton, "reroll")
SkinSpellDraftButton(SpellChoiceBanButton, "ban")
SkinSpellDraftButton(SpellChoiceDismissButton, "dismiss")

SpellChoiceBanButton:SetScript("OnClick", function(self)
  PlaySound("igMainMenuOptionCheckBoxOn")
  banMode = not banMode

  -- Toggle appearance
  if banMode then
    self:SetText(L("Ban [ON] (%d)", bansLeft))
    self.sdBanActive = true
    self:SetBackdropColor(0.25, 0.04, 0.08, 0.95)
    self:SetBackdropBorderColor(1.0, 0.25, 0.35, 1.0)
    SpellChoiceRerollButton:Disable()
    SpellChoiceRerollButton:SetAlpha(0.4)
    UIErrorsFrame:AddMessage(L("Ban Mode Activated"), 1.0, 0.5, 0.0, 1)
    Debug("[Ban] Mode activated")
  else
    self:SetText(L("Ban (%d)", bansLeft))
    self.sdBanActive = false
    self:SetBackdropColor(0.04, 0.06, 0.12, 0.92)
    local b = self.sdTheme.border
    self:SetBackdropBorderColor(b.r, b.g, b.b, b.a)
    UpdateRerollButton()
    Debug("[Ban] Mode deactivated")

    -- Check if any shown spell is banned
    local found = false
    for _, btn in ipairs(buttons) do
      local id = btn:GetID()
      if bannedSpells[id] then
        found = true
        Debug("[Ban] Detected banned spell in current draft: " .. id)
        break
      end
    end

    -- If so, request replacements for just banned ones
    if found then
      local target = UnitName("player")
      if target then
        SendChatMessage("SC_REPLACE_BANNED", "WHISPER", GetFactionLanguage(), target)
        Debug("[Ban] Requesting replacement for banned spells...")
        SendChatMessage("SC_CHECK", "WHISPER", GetFactionLanguage(), target)  -- Refresh bans too
        Debug("[Ban] Also re-requesting ban list to clear replaced spell")
      end
    end
  end
end)
SpellChoiceBanButton:Show()
SpellChoiceDismissButton:SetScript("OnClick", function(self)
    PlaySound("igMainMenuOptionCheckBoxOn")
    dismissToggled = not dismissToggled
    if SpellDraftDB then
        SpellDraftDB.dismissToggled = dismissToggled
    end

    if dismissToggled then
        local btnText
        if isTalentDraftActive then
            btnText = L("Talent Draft")
        else
            local label = SpellChoiceTitle:GetText() or ""
            local count = label:match("(%d+)") or "0"
            btnText = L("%d Draft(s) Left", tonumber(count) or 0)
        end
        self:SetText(btnText)

        for _, btn in ipairs(buttons) do
            btn:Hide()
            btn:EnableMouse(false)
            btn:SetScript("OnEnter", nil)
            btn:SetScript("OnLeave", nil)
            btn:SetScript("OnClick", nil)
        end

        SpellChoiceTitle:Hide()
        SpellChoiceRerollButton:Hide()
        SpellChoiceFrame:EnableMouse(false)
        SpellChoiceFrame:SetAlpha(0.01)

        self:SetParent(UIParent)
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "CENTER", 0, -160)
        self:SetFrameStrata("FULLSCREEN_DIALOG")
        self:EnableMouse(true)
        self:Show()

        -- Reset ban state when hidden
        banMode = false
        SpellChoiceBanButton:SetText(L("Ban"))
        UpdateRerollButton()
        Debug("[Ban] Ban mode reset due to dismissal")
    else
        self:SetText(L("Dismiss"))

        -- Reset ban mode just in case
        banMode = false
        SpellChoiceBanButton:SetText(L("Ban"))
        UpdateRerollButton()
        Debug("[Ban] Ban mode reset on re-toggle")

        -- Restore full UI state
        if lastSpellIDs and #lastSpellIDs > 0 then
        local target = UnitName("player")
        if target then
          SendChatMessage("SC_CHECK", "WHISPER", GetFactionLanguage(), target)
          Debug("[Ban] Re-requested banned spell list before restoring UI.")
        end

        restoringFromDismiss = true
        Delay(0.2, function()
          ShowSpellChoices(lastSpellIDs)
          restoringFromDismiss = false
        end)
      end

        SpellChoiceFrame:EnableMouse(true)
        SpellChoiceFrame:SetAlpha(1)
        SpellChoiceFrame:Show()

        for _, btn in ipairs(buttons) do
            btn:EnableMouse(true)
            btn:Show()

            btn:SetScript("OnEnter", function(self)
                local spellID = self:GetID()
                if spellID and spellID > 0 then
                    GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
                    GameTooltip:SetHyperlink("spell:" .. spellID)
                    GameTooltip:Show()
                end
            end)

            btn:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)

            btn:SetScript("OnClick", HandleSpellClick)
        end

        SpellChoiceTitle:Show()
        SpellChoiceRerollButton:Show()

        self:SetParent(SpellChoiceFrame)
        self:ClearAllPoints()
        self:SetPoint("BOTTOM", SpellChoiceTitle, "TOP", 0, -290)
    end
end)





--------------------------------------------------------------------------------
-- Multi-Resource HUD programmatically generated below
--------------------------------------------------------------------------------

local hudFrame = CreateFrame("Frame", "SpellDraftHUD", UIParent)
hudFrame:SetWidth(119)
hudFrame:SetHeight(45)

local function PositionHUD()
    hudFrame:ClearAllPoints()
    hudFrame:SetPoint("BOTTOMLEFT", PlayerFrameHealthBar, "TOPLEFT", 5, 3)
end

local blizzardFramesDirty = false
local function RepositionBlizzardFrames()
    if InCombatLockdown() then
        blizzardFramesDirty = true
        return
    end

    blizzardFramesDirty = false

    -- 1. Druid Mana Bar
    if PlayerFrameDruidManaBar then
        local maxMana = UnitPowerMax("player", 0)
        if showHUD and maxMana and maxMana > 0 then
            if not PlayerFrameDruidManaBar:IsShown() then
                PlayerFrameDruidManaBar:Show()
            end
            local _, class = UnitClass("player")
            if class == "WARRIOR" then
                PlayerFrameDruidManaBar:ClearAllPoints()
                PlayerFrameDruidManaBar:SetPoint("TOPLEFT", PlayerFrameManaBar, "BOTTOMLEFT", 0, -1)
                PlayerFrameDruidManaBar:SetWidth(119)
                PlayerFrameDruidManaBar:SetHeight(10)
                
                -- Force standard textures, colors, and values
                PlayerFrameDruidManaBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
                PlayerFrameDruidManaBar:SetStatusBarColor(0, 0.4, 1)
                
                -- Style background
                local bg = _G["PlayerFrameDruidManaBarBG"] or PlayerFrameDruidManaBar.bg
                if bg then
                    bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
                    bg:SetVertexColor(0, 0.08, 0.2, 0.6)
                end
            end
        else
            if PlayerFrameDruidManaBar:IsShown() then
                PlayerFrameDruidManaBar:Hide()
            end
        end
    end

    -- 2. Pet Frame
    if PetFrame and PetFrame:IsShown() then
        PetFrame:ClearAllPoints()
        local maxMana = PlayerFrameDruidManaBar and UnitPowerMax("player", 0) or 0
        if showHUD and maxMana > 0 then
            PetFrame:SetPoint("TOPLEFT", PlayerFrame, "BOTTOMLEFT", 80, -14)
        else
            PetFrame:SetPoint("TOPLEFT", PlayerFrame, "BOTTOMLEFT", 80, -4)
        end
    end

    -- 3. Rune Frame
    if RuneFrame and RuneFrame:IsShown() then
        RuneFrame:ClearAllPoints()
        RuneFrame:SetPoint("TOP", PlayerFrameManaBar, "BOTTOM", 0, -16)
    end

    -- 4. Force Pet Action Bar Update
    if PetHasActionBar and PetHasActionBar() then
        if PetActionBarFrame and not PetActionBarFrame:IsShown() then
            PetActionBarFrame:Show()
        end
        if PetActionBar_Update then
            PetActionBar_Update()
        end
    end
end

local function CreateHUDBar(colorR, colorG, colorB, name)
    local bar = CreateFrame("StatusBar", "SpellDraftHUD_" .. name, hudFrame)
    
    if name == "Energy" then
        bar:SetWidth(113)
        bar:SetHeight(12)
        bar:SetStatusBarTexture("Interface\\AddOns\\SpellDraft\\Textures\\energy_fill.tga")
        bar:SetStatusBarColor(1, 1, 1) -- White so texture's native yellow shows through
        
        -- Custom border overlay with rounded corners
        local border = bar:CreateTexture(nil, "OVERLAY")
        border:SetTexture("Interface\\AddOns\\SpellDraft\\Textures\\energy_border.tga")
        border:SetAllPoints(bar)
        
        -- Solid black base (rounded via the bg texture on top)
        local bgSolid = bar:CreateTexture(nil, "BACKGROUND")
        bgSolid:SetAllPoints(bar)
        bgSolid:SetTexture("Interface\\AddOns\\SpellDraft\\Textures\\energy_bg.tga")
        bgSolid:SetVertexColor(0, 0, 0, 1)
        
        -- Tinted background layer with rounded texture
        local bg = bar:CreateTexture(nil, "BACKGROUND", nil, 1)
        bg:SetTexture("Interface\\AddOns\\SpellDraft\\Textures\\energy_bg.tga")
        bg:SetAllPoints(bar)
        bg:SetVertexColor(0.3, 0.3, 0, 1)
    else
        bar:SetWidth(119)
        bar:SetHeight(12)
        bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        bar:SetStatusBarColor(colorR, colorG, colorB)
        
        -- Black 1-pixel outer border to match default nameplate/player frame style
        local border = bar:CreateTexture(nil, "BACKGROUND")
        border:SetPoint("TOPLEFT", bar, "TOPLEFT", -1, 1)
        border:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 1, -1)
        border:SetTexture("Interface\\Buttons\\WHITE8x8")
        border:SetVertexColor(0, 0, 0, 0.9)
        
        local bg = bar:CreateTexture(nil, "BACKGROUND", nil, 1)
        bg:SetAllPoints(bar)
        bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
        bg:SetVertexColor(colorR * 0.2, colorG * 0.2, colorB * 0.2, 0.6)
    end

    local text = bar:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
    text:SetPoint("CENTER", bar, "CENTER", 0, 0)
    text:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
    
    -- Mouseover tooltip showing resource name (like native Mana/Health/Rage)
    bar:EnableMouse(true)
    bar:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(name, colorR, colorG, colorB)
        GameTooltip:Show()
    end)
    bar:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    bar.text = text
    bar:Hide()
    return bar
end

-- Create horizontal bars (Mana, Rage, Energy)
local manaBar = CreateHUDBar(0, 0.4, 1, "Mana")
local rageBar = CreateHUDBar(1, 0, 0, "Rage")
local energyBar = CreateHUDBar(1, 1, 0, "Energy")

-- Create vertical Runic Power bar (anchored to right side of player frame)
local runicFrame = CreateFrame("Frame", "SpellDraftRunicFrame", UIParent)
runicFrame:SetWidth(8)
runicFrame:SetHeight(42)

local runicBar = CreateFrame("StatusBar", "SpellDraftHUD_RunicPower", runicFrame)
runicBar:SetWidth(6)
runicBar:SetHeight(38)
runicBar:SetOrientation("VERTICAL")
runicBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
runicBar:SetStatusBarColor(0, 0.82, 1)
runicBar:SetPoint("CENTER", runicFrame, "CENTER", 0, 0)

-- Rounded dark border for the vertical bar
local runicBorder = runicFrame:CreateTexture(nil, "BACKGROUND")
runicBorder:SetPoint("TOPLEFT", runicFrame, "TOPLEFT", 0, 0)
runicBorder:SetPoint("BOTTOMRIGHT", runicFrame, "BOTTOMRIGHT", 0, 0)
runicBorder:SetTexture("Interface\\Buttons\\WHITE8x8")
runicBorder:SetVertexColor(0.38, 0.38, 0.42, 1)

-- Dark tinted background inside the bar
local runicBg = runicBar:CreateTexture(nil, "BACKGROUND")
runicBg:SetAllPoints(runicBar)
runicBg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
runicBg:SetVertexColor(0, 0.12, 0.18, 1)

-- Top rounded cap
local runicCapTop = runicFrame:CreateTexture(nil, "OVERLAY")
runicCapTop:SetTexture("Interface\\Buttons\\WHITE8x8")
runicCapTop:SetVertexColor(0.38, 0.38, 0.42, 1)
runicCapTop:SetWidth(8)
runicCapTop:SetHeight(1)
runicCapTop:SetPoint("TOP", runicFrame, "TOP", 0, 1)

-- Bottom rounded cap
local runicCapBot = runicFrame:CreateTexture(nil, "OVERLAY")
runicCapBot:SetTexture("Interface\\Buttons\\WHITE8x8")
runicCapBot:SetVertexColor(0.38, 0.38, 0.42, 1)
runicCapBot:SetWidth(8)
runicCapBot:SetHeight(1)
runicCapBot:SetPoint("BOTTOM", runicFrame, "BOTTOM", 0, -1)

-- Mouseover tooltip for runic bar
runicFrame:EnableMouse(true)
runicFrame:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(L("Runic Power"), 0, 0.82, 1)
    local cur = UnitPower("player", 6)
    local max = UnitPowerMax("player", 6)
    GameTooltip:AddLine(cur .. " / " .. max, 1, 1, 1)
    GameTooltip:Show()
end)
runicFrame:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

runicBar:Hide()
runicFrame:Hide()

-- Hook native secondary mana bar's Hide function to block the client from hiding it for Warriors
if PlayerFrameDruidManaBar then
    hooksecurefunc(PlayerFrameDruidManaBar, "Hide", function(self)
        if showHUD and not InCombatLockdown() then
            local maxMana = UnitPowerMax("player", 0)
            if maxMana and maxMana > 0 then
                self:Show()
                RepositionBlizzardFrames()
            end
        end
    end)
end

showHUD = true -- Enabled by default

function SpellDraft.UpdateHUD()
    if not showHUD then
        manaBar:Hide()
        rageBar:Hide()
        energyBar:Hide()
        runicBar:Hide()
        runicFrame:Hide()
        hudFrame:Hide()
        return
    end

    hudFrame:Show()
    PositionHUD()

    local nativePower = UnitPowerType("player")
    local _, playerClass = UnitClass("player")

    -- The "druid style" third mana bar is drawn by the client engine, which
    -- only triggers it for non-rage power types (energy/runic), so it never
    -- appears for Warriors (rage). For Warriors ONLY, show our own custom mana
    -- bar under the native power bar to mimic that third-bar layout. Every other
    -- class keeps using the engine's native secondary mana bar.
    if playerClass == "WARRIOR" then
        local maxMana = UnitPowerMax("player", 0)
        if maxMana and maxMana > 0 then
            local curMana = UnitPower("player", 0)
            manaBar:SetMinMaxValues(0, maxMana)
            manaBar:SetValue(curMana)
            manaBar.text:SetText(curMana .. " / " .. maxMana)
            manaBar:ClearAllPoints()
            -- Anchor directly beneath the native power bar (the rage bar for Warriors)
            manaBar:SetPoint("TOPLEFT", PlayerFrameManaBar, "BOTTOMLEFT", 0, -2)
            manaBar:Show()
        else
            manaBar:Hide()
        end
    else
        manaBar:Hide()
    end
    
    local hasRage = false
    local hasEnergy = false
    
    -- Update Rage bar
    if nativePower ~= 1 then
        local maxRage = UnitPowerMax("player", 1)
        if maxRage > 0 then
            local currentRage = UnitPower("player", 1)
            rageBar:SetMinMaxValues(0, maxRage)
            rageBar:SetValue(currentRage)
            rageBar.text:SetText(currentRage .. " / " .. maxRage)
            hasRage = true
        else
            rageBar:Hide()
        end
    else
        rageBar:Hide()
    end
    
    -- Update Energy bar
    if nativePower ~= 3 then
        local maxEnergy = UnitPowerMax("player", 3)
        if maxEnergy > 0 then
            local currentEnergy = UnitPower("player", 3)
            energyBar:SetMinMaxValues(0, maxEnergy)
            energyBar:SetValue(currentEnergy)
            energyBar.text:SetText(currentEnergy .. " / " .. maxEnergy)
            hasEnergy = true
        else
            energyBar:Hide()
        end
    else
        energyBar:Hide()
    end

    -- Update Runic Power bar (vertical, right side of nameplate)
    if nativePower ~= 6 then
        local maxRunic = UnitPowerMax("player", 6)
        if maxRunic > 0 then
            local currentRunic = UnitPower("player", 6)
            runicBar:SetMinMaxValues(0, maxRunic)
            runicBar:SetValue(currentRunic)
            runicFrame:ClearAllPoints()
            runicFrame:SetPoint("RIGHT", PlayerFrameHealthBar, "RIGHT", 14, 2)
            runicBar:Show()
            runicFrame:Show()
        else
            runicBar:Hide()
            runicFrame:Hide()
        end
    else
        runicBar:Hide()
        runicFrame:Hide()
    end

    -- Stack horizontal bars vertically upwards
    local lastBar = nil
    if hasEnergy then
        energyBar:ClearAllPoints()
        energyBar:SetPoint("BOTTOMLEFT", hudFrame, "BOTTOMLEFT", 0, 0)
        energyBar:Show()
        lastBar = energyBar
    end
    if hasRage then
        rageBar:ClearAllPoints()
        if lastBar then
            rageBar:SetPoint("BOTTOMLEFT", lastBar, "TOPLEFT", 0, 2)
        else
            rageBar:SetPoint("BOTTOMLEFT", hudFrame, "BOTTOMLEFT", 0, 0)
        end
        rageBar:Show()
        lastBar = rageBar
    end

    -- Show/Hide the native secondary mana bar safely (only outside combat)
    if PlayerFrameDruidManaBar and not InCombatLockdown() then
        local maxMana = UnitPowerMax("player", 0)
        if maxMana > 0 then
            if not PlayerFrameDruidManaBar:IsShown() then
                PlayerFrameDruidManaBar:Show()
                blizzardFramesDirty = true
            end
        else
            if PlayerFrameDruidManaBar:IsShown() then
                PlayerFrameDruidManaBar:Hide()
                blizzardFramesDirty = true
            end
        end
    end

    -- Update Druid Mana Bar values (safe, doesn't modify frame points/dimensions)
    if PlayerFrameDruidManaBar then
        local maxMana = UnitPowerMax("player", 0)
        if maxMana > 0 then
            local _, class = UnitClass("player")
            if class == "WARRIOR" then
                local cur = UnitPower("player", 0)
                local max = UnitPowerMax("player", 0)
                PlayerFrameDruidManaBar:SetMinMaxValues(0, max)
                PlayerFrameDruidManaBar:SetValue(cur)
            end
        end
    end

    -- Safe periodic reposition retry outside combat
    if blizzardFramesDirty or not InCombatLockdown() then
        RepositionBlizzardFrames()
    end
end

hudFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
hudFrame:RegisterEvent("PLAYER_LEVEL_UP")
hudFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
hudFrame:RegisterEvent("PET_UI_UPDATE")
hudFrame:RegisterEvent("UNIT_PET")
hudFrame:RegisterEvent("PLAYER_PET_CHANGED")
hudFrame:RegisterEvent("UNIT_MAXPOWER")
hudFrame:RegisterEvent("UNIT_POWER")

hudFrame:SetScript("OnEvent", function(self, event, unit)
    if event == "PLAYER_REGEN_ENABLED" then
        if blizzardFramesDirty then
            RepositionBlizzardFrames()
        end
    elseif event == "UNIT_POWER" or event == "UNIT_MAXPOWER" then
        if unit == "player" then
            RepositionBlizzardFrames()
            SpellDraft.UpdateHUD()
        end
    elseif event == "PET_UI_UPDATE" or event == "UNIT_PET" or event == "PLAYER_PET_CHANGED" then
        RepositionBlizzardFrames()
    elseif event == "PLAYER_ENTERING_WORLD" then
        RepositionBlizzardFrames()
        SpellDraft.UpdateHUD()
    else
        SpellDraft.UpdateHUD()
    end
end)

local lastHUDUpdate = 0
hudFrame:SetScript("OnUpdate", function(self, elapsed)
    lastHUDUpdate = lastHUDUpdate + elapsed
    if lastHUDUpdate >= 0.2 then
        lastHUDUpdate = 0
        SpellDraft.UpdateHUD()
    end
end)

SLASH_SDHUD1 = "/sdhud"
SlashCmdList["SDHUD"] = function()
    showHUD = not showHUD
    if SpellDraftDB then
        SpellDraftDB.showHUD = showHUD
    end
    if not InCombatLockdown() then
        RepositionBlizzardFrames()
    else
        blizzardFramesDirty = true
    end
    SpellDraft.UpdateHUD()
    if showHUD then
        print("|cff00ccff[SpellDraft]|r " .. L("Floating HUD enabled."))
    else
        print("|cff00ccff[SpellDraft]|r " .. L("Floating HUD disabled."))
    end
end
