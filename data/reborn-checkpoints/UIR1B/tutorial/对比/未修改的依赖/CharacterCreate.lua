-- WD2: select by enumerated token/index; never assume list index equals class ID.
CLASS_INFO_WITCHDOCTOR0 = "- 资源：法力";
CLASS_INFO_WITCHDOCTOR1 = "- 巫毒施法职业；当前开放人类男女创建测试";
NEW_CLASS_INFO_WITCHDOCTOR = "法术伤害";
NEW_CLASS_WITCHDOCTOR = "以巫毒与灵魂法术战斗的巫医。";
NEW_CLASS_WITCHDOCTOR_FEMALE = NEW_CLASS_WITCHDOCTOR;
CLASS_WITCHDOCTOR = NEW_CLASS_WITCHDOCTOR;
CLASS_WITCHDOCTOR_FEMALE = NEW_CLASS_WITCHDOCTOR;
function CharacterCreate_WitchDoctorRaceIsOpen(index)
    return CharacterCreate.wdHumanRaces and CharacterCreate.wdHumanRaces[index] == true;
end
function CharacterCreate_WitchDoctorSelectionIsBlocked()
    local _, token, index = GetSelectedClass();
    return (token == "WITCHDOCTOR" or (CharacterCreate.witchDoctorClassIndex and index == CharacterCreate.witchDoctorClassIndex))
        and (PAID_SERVICE_TYPE or not CharacterCreate_WitchDoctorRaceIsOpen(GetSelectedRace()));
end
function CharacterCreate_SelectWitchDoctor(self)
    local index = CharacterCreate.witchDoctorClassIndex;
    if not index or not CharacterCreate_WitchDoctorRaceIsOpen(GetSelectedRace()) or PAID_SERVICE_TYPE then
        self:SetChecked(0); return;
    end
    if self:IsEnabled() ~= 1 and self:IsEnabled() ~= true then return; end
    CharacterClass_OnClick(self, index);
end

-- MONKRACE2: resolve eligibility from enumerated race names, never button/list IDs.
local monkPhaseOneNames = {
    ["人类"]=true, ["human"]=true, ["兽人"]=true, ["orc"]=true,
    ["矮人"]=true, ["dwarf"]=true, ["暗夜精灵"]=true, ["night elf"]=true,
    ["亡灵"]=true, ["undead"]=true, ["血精灵"]=true, ["blood elf"]=true,
    ["熊猫人"]=true, ["熊猫人（联盟）"]=true, ["pandaren"]=true,
    ["pandaren alliance"]=true, ["pandaren horde"]=true,
};
function CharacterCreate_MonkRaceIsOpen(raceIndex)
    return CharacterCreate.monkPhaseOneRaces and CharacterCreate.monkPhaseOneRaces[raceIndex] == true;
end
function CharacterCreate_MonkSelectionIsBlocked()
    local _, token, index = GetSelectedClass();
    if token == "MONK" or (CharacterCreate.monkClassIndex and index == CharacterCreate.monkClassIndex) then
        return not CharacterCreate_MonkRaceIsOpen(GetSelectedRace());
    end
    return false;
end

--CLASS_DISABLED = "You must choose a different race to be this class";
CLASS_DISABLED = "你必须选择一个其他种族才能创建该职业";
CUSTOMIZE = "自定义";
NEXT = "下一步";
FINISH = "完成"; 
CLASS_ALMACENADA = 1; 
OKGETCLASSULTIMATE = 0;

-- The customized race-info ScrollFrame can receive OnLoad before its named
-- $parentScrollBar child is published in _G. Retry only this initialization
-- for a bounded period instead of aborting the entire GlueXML load chain.
local CHAR_CREATE_RACE_SCROLL_RETRY_INTERVAL = 0.05;
local CHAR_CREATE_RACE_SCROLL_RETRY_LIMIT = 100;

-- RebornWOW S.7.4: read-only account-DP quote before creating slot 11+.
-- The quote is presentation only.  WorldServer S.7.3 locks the wallet and
-- rechecks the price when CMSG_CHAR_CREATE is received.
local REBORN_SLOT_FREE_FALLBACK = 10;
local RebornSlotQuote = {
	pending = false,
	elapsed = 0,
	timeout = 0,
	name = nil,
	slot = 0,
	frame = nil,
};

local function RebornSlotQuote_GetAccountName()
	local account = nil;
	if ( GetSavedAccountName ) then
		account = GetSavedAccountName();
	end
	if ( (not account or account == "") and AccountLoginAccountEdit and AccountLoginAccountEdit.GetText ) then
		account = AccountLoginAccountEdit:GetText();
	end
	if ( not account ) then
		return "";
	end
	return string.upper(account);
end

local function RebornSlotQuote_SetOkayEnabled(enabled)
	if ( not CharCreateOkayButton ) then
		return;
	end
	if ( enabled ) then
		CharCreateOkayButton:Enable();
	else
		CharCreateOkayButton:Disable();
	end
end

local function RebornSlotQuote_NativeCreate()
	local name = RebornSlotQuote.name or CharacterCreateNameEdit:GetText();
	RebornSlotQuote.pending = false;
	RebornSlotQuote.elapsed = 0;
	RebornSlotQuote.timeout = 0;
	RebornSlotQuote_SetOkayEnabled(true);
	if ( RebornSlotQuote.frame ) then
		RebornSlotQuote.frame:Hide();
	end
	if CharacterCreate_MonkSelectionIsBlocked() then
        message("该种族暂未开放武僧。 / Monk is not available for this race yet.");
        return;
    end
    if CharacterCreate_WitchDoctorSelectionIsBlocked() then
        message("巫医目前仅开放人类新建角色。"); return;
    end
    CreateCharacter(name);
end

local function RebornSlotQuote_CreateButton(name, parent, width, text)
	local button = CreateFrame("Button", name, parent, "GlueButtonSmallTemplate");
	button:SetWidth(width);
	button:SetHeight(28);
	button:SetText(text);
	return button;
end

-- GlueXML does not load the in-world FrameXML font templates such as
-- GameFontNormalLarge/GameFontHighlight.  Create plain FontStrings and assign
-- their font explicitly so the quote dialog works before entering the world.
local function RebornSlotQuote_CreateText(parent, size, red, green, blue)
	local fontString = parent:CreateFontString(nil, "OVERLAY");
	fontString:SetFont("Fonts\\FRIZQT__.TTF", size, "OUTLINE");
	fontString:SetTextColor(red, green, blue);
	return fontString;
end

local function RebornSlotQuote_EnsureFrame()
	if ( RebornSlotQuote.frame ) then
		return RebornSlotQuote.frame;
	end

	local frame = CreateFrame("Frame", "RebornCharacterSlotQuoteFrame", CharacterCreateFrame);
	frame:SetWidth(560);
	frame:SetHeight(390);
	frame:SetPoint("CENTER", CharacterCreateFrame, "CENTER", 0, 10);
	frame:SetFrameStrata("DIALOG");
	frame:SetToplevel(true);
	frame:EnableMouse(true);
	frame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = { left = 11, right = 12, top = 12, bottom = 11 },
	});

	frame.title = RebornSlotQuote_CreateText(frame, 22, 1.00, 0.82, 0.00);
	frame.title:SetPoint("TOP", frame, "TOP", 0, -34);
	frame.title:SetText("扩展角色槽位 / Extra Character Slot");

	frame.subtitle = RebornSlotQuote_CreateText(frame, 15, 1.00, 1.00, 1.00);
	frame.subtitle:SetWidth(500);
	frame.subtitle:SetPoint("TOP", frame.title, "BOTTOM", 0, -10);
	frame.subtitle:SetText("第 11 个角色起使用账号级 DP 购买\nAccount-level DP is required from character slot 11 onward");

	frame.slotLine = RebornSlotQuote_CreateText(frame, 15, 1.00, 0.82, 0.00);
	frame.slotLine:SetPoint("TOPLEFT", frame, "TOPLEFT", 48, -112);
	frame.slotLine:SetWidth(464);
	frame.slotLine:SetJustifyH("LEFT");

	frame.balanceLine = RebornSlotQuote_CreateText(frame, 15, 1.00, 1.00, 1.00);
	frame.balanceLine:SetPoint("TOPLEFT", frame.slotLine, "BOTTOMLEFT", 0, -18);
	frame.balanceLine:SetWidth(464);
	frame.balanceLine:SetJustifyH("LEFT");

	frame.priceLine = RebornSlotQuote_CreateText(frame, 15, 1.00, 1.00, 1.00);
	frame.priceLine:SetPoint("TOPLEFT", frame.balanceLine, "BOTTOMLEFT", 0, -12);
	frame.priceLine:SetWidth(464);
	frame.priceLine:SetJustifyH("LEFT");

	frame.afterLine = RebornSlotQuote_CreateText(frame, 15, 1.00, 1.00, 1.00);
	frame.afterLine:SetPoint("TOPLEFT", frame.priceLine, "BOTTOMLEFT", 0, -12);
	frame.afterLine:SetWidth(464);
	frame.afterLine:SetJustifyH("LEFT");

	frame.warning = RebornSlotQuote_CreateText(frame, 12, 0.75, 0.75, 0.75);
	frame.warning:SetPoint("TOPLEFT", frame.afterLine, "BOTTOMLEFT", 0, -18);
	frame.warning:SetWidth(464);
	frame.warning:SetJustifyH("LEFT");
	frame.warning:SetText("最终价格与余额由服务器再次核验；创建失败不会扣除 DP。\nFinal price and balance are rechecked by the server; failed creation is not charged.");

	frame.status = RebornSlotQuote_CreateText(frame, 15, 1.00, 0.82, 0.00);
	frame.status:SetPoint("BOTTOM", frame, "BOTTOM", 0, 80);
	frame.status:SetWidth(500);
	frame.status:SetText("正在查询 DP 报价… / Requesting DP quote...");

	frame.confirm = RebornSlotQuote_CreateButton("RebornCharacterSlotQuoteConfirm", frame, 145, "确认创建 / Confirm");
	frame.confirm:SetPoint("BOTTOM", frame, "BOTTOM", -165, 36);
	frame.confirm:SetScript("OnClick", function()
		if ( RebornSlotQuote.pending ) then
			return;
		end
		RebornSlotQuote_NativeCreate();
	end);

	frame.recharge = RebornSlotQuote_CreateButton("RebornCharacterSlotQuoteRecharge", frame, 145, "充值 DP / Recharge");
	frame.recharge:SetPoint("BOTTOM", frame, "BOTTOM", 0, 36);
	frame.recharge:SetScript("OnClick", function()
		if ( RebornSpectator_GetOnlineJson ) then
			RebornSpectator_GetOnlineJson(-7403);
		end
	end);

	frame.cancel = RebornSlotQuote_CreateButton("RebornCharacterSlotQuoteCancel", frame, 120, "取消 / Cancel");
	frame.cancel:SetPoint("BOTTOM", frame, "BOTTOM", 155, 36);
	frame.cancel:SetScript("OnClick", function()
		RebornSlotQuote.pending = false;
		RebornSlotQuote.elapsed = 0;
		RebornSlotQuote.timeout = 0;
		RebornSlotQuote_SetOkayEnabled(true);
		frame:Hide();
	end);

	frame:SetScript("OnUpdate", function(self, elapsed)
		if ( not RebornSlotQuote.pending ) then
			return;
		end
		RebornSlotQuote.elapsed = RebornSlotQuote.elapsed + elapsed;
		RebornSlotQuote.timeout = RebornSlotQuote.timeout + elapsed;
		if ( RebornSlotQuote.timeout >= 8 ) then
			RebornSlotQuote.pending = false;
			self.status:SetText("|cffff4040报价超时，请稍后重试 / Quote timed out; please retry|r");
			self.recharge:Enable();
			self.cancel:Enable();
			RebornSlotQuote_SetOkayEnabled(true);
			return;
		end
		if ( RebornSlotQuote.elapsed < 0.10 ) then
			return;
		end
		RebornSlotQuote.elapsed = 0;
		if ( not RebornSpectator_GetOnlineJson ) then
			RebornSlotQuote.pending = false;
			self.status:SetText("|cffff4040报价桥不可用 / DP quote bridge unavailable|r");
			self.recharge:Enable();
			self.cancel:Enable();
			RebornSlotQuote_SetOkayEnabled(true);
			return;
		end

		local state, balance, price, slot, generation, affordable, freeSlots, billingEnabled, vpBalance = RebornSpectator_GetOnlineJson(-7402);
		if ( state == "ready" ) then
			RebornSlotQuote.pending = false;
			balance = tonumber(balance) or 0;
			vpBalance = tonumber(vpBalance) or 0;
			price = tonumber(price) or 0;
			slot = tonumber(slot) or RebornSlotQuote.slot;
			affordable = tonumber(affordable) or 0;
			billingEnabled = tonumber(billingEnabled) or 0;
			self.slotLine:SetText("角色槽位 / Character slot: |cff00ccff"..slot.."|r");
			self.balanceLine:SetText("网站账户余额 / Website wallet: |cffffcc00"..vpBalance.." VP|r  |  |cff00ccff"..balance.." DP|r");
			self.priceLine:SetText("本次价格 / Required: |cffffff00"..price.." DP|r");
			self.afterLine:SetText("创建后余额 / Balance after: |cff00ccff"..math.max(0, balance - price).." DP|r");
			if ( billingEnabled == 0 or price == 0 ) then
				RebornSlotQuote_NativeCreate();
				return;
			end
			if ( affordable == 1 ) then
				self.status:SetText("|cff00ff00余额充足，请确认创建 / Balance sufficient; confirm creation|r");
				self.confirm:Enable();
			else
				self.status:SetText("|cffff4040DP 不足，请先充值 / Insufficient DP; please recharge|r");
				self.confirm:Disable();
			end
			self.recharge:Enable();
			self.cancel:Enable();
			RebornSlotQuote_SetOkayEnabled(true);
		elseif ( state == "error" ) then
			RebornSlotQuote.pending = false;
			self.status:SetText("|cffff4040报价失败，未创建角色 / Quote failed; character not created|r");
			self.recharge:Enable();
			self.cancel:Enable();
			RebornSlotQuote_SetOkayEnabled(true);
		end
	end);

	frame:Hide();
	RebornSlotQuote.frame = frame;
	return frame;
end

local function RebornSlotQuote_Request(characterName, requestedSlot)
	local frame = RebornSlotQuote_EnsureFrame();
	local account = RebornSlotQuote_GetAccountName();
	RebornSlotQuote.name = characterName;
	RebornSlotQuote.slot = requestedSlot;
	RebornSlotQuote.elapsed = 0;
	RebornSlotQuote.timeout = 0;
	RebornSlotQuote.pending = true;
	frame.slotLine:SetText("角色槽位 / Character slot: |cff00ccff"..requestedSlot.."|r");
	frame.balanceLine:SetText("网站账户余额 / Website wallet: … VP  |  … DP");
	frame.priceLine:SetText("本次价格 / Required: …");
	frame.afterLine:SetText("创建后余额 / Balance after: …");
	frame.status:SetText("正在查询 DP 报价… / Requesting DP quote...");
	frame.confirm:Disable();
	frame.recharge:Disable();
	frame.cancel:Enable();
	frame:Show();
	RebornSlotQuote_SetOkayEnabled(false);

	if ( account == "" or not RebornSpectator_GetOnlineJson ) then
		RebornSlotQuote.pending = false;
		frame.status:SetText("|cffff4040无法识别已认证账号或报价桥不可用\nAuthenticated account or quote bridge unavailable|r");
		frame.recharge:Enable();
		frame.cancel:Enable();
		RebornSlotQuote_SetOkayEnabled(true);
		return;
	end

	RebornSpectator_GetOnlineJson(-7400);
	local index;
	for index = 1, string.len(account) do
		RebornSpectator_GetOnlineJson(-(10000 + string.byte(account, index)));
	end
	RebornSpectator_GetOnlineJson(-(11000 + requestedSlot));
	local submitState = RebornSpectator_GetOnlineJson(-7401);
	if ( submitState ~= "pending" ) then
		RebornSlotQuote.pending = false;
		frame.status:SetText("|cffff4040报价请求无效 / Invalid quote request|r");
		frame.recharge:Enable();
		frame.cancel:Enable();
		RebornSlotQuote_SetOkayEnabled(true);
	end
end

function CharCreateRaceInfoScrollFrame_Initialize(self)
	if ( not self or not self.GetName ) then
		return false;
	end

	local frameName = self:GetName();
	local scrollBar = frameName and _G[frameName.."ScrollBar"];
	if ( not scrollBar ) then
		return false;
	end

	scrollBar:ClearAllPoints();
	scrollBar:SetPoint("TOPLEFT", self, "TOPRIGHT", 11, 10);
	scrollBar:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", 11, 12);
	if ( GlueScrollFrame_OnScrollRangeChanged ) then
		GlueScrollFrame_OnScrollRangeChanged(self);
	end
	return true;
end

function CharCreateRaceInfoScrollFrame_OnLoad(self)
	if ( CharCreateRaceInfoScrollFrame_Initialize(self) ) then
		return;
	end

	self.r27ScrollInitElapsed = 0;
	self.r27ScrollInitAttempts = 0;
	self:SetScript("OnUpdate", function(frame, elapsed)
		frame.r27ScrollInitElapsed = frame.r27ScrollInitElapsed + elapsed;
		if ( frame.r27ScrollInitElapsed < CHAR_CREATE_RACE_SCROLL_RETRY_INTERVAL ) then
			return;
		end

		frame.r27ScrollInitElapsed = 0;
		frame.r27ScrollInitAttempts = frame.r27ScrollInitAttempts + 1;
		if ( CharCreateRaceInfoScrollFrame_Initialize(frame) or
			 frame.r27ScrollInitAttempts >= CHAR_CREATE_RACE_SCROLL_RETRY_LIMIT ) then
			frame:SetScript("OnUpdate", nil);
		end
	end);
end

CHARACTER_FACING_INCREMENT = 2;
MAX_RACES = 40;
-- This client exposes ten class buttons. Keeping this aligned with the XML
-- prevents startup code from addressing a non-existent eleventh button.
-- The server/client DBC contract reserves class IDs below 24.  This is a UI
-- capacity, not permission to create a class: GetAvailableClasses and
-- IsRaceClassValid remain authoritative.
MAX_CLASSES_PER_RACE = 24;
NUM_CHAR_CUSTOMIZATIONS = 5;
MIN_CHAR_NAME_LENGTH = 2;
CHARACTER_CREATE_ROTATION_START_X = nil;
CHARACTER_CREATE_INITIAL_FACING = nil;
NUM_PREVIEW_FRAMES = 14;
WORGEN_RACE_ID = 6;
TUSKARR_RACE_ID = 6;
EXTRA_RACE_NAGA_INDEX = 25;
EXTRA_RACE_NAGA_NAME = "Naga";
EXTRA_RACE_DRACTHYR_INDEX = 35;
EXTRA_RACE_DRACTHYR_NAME = "龙希尔";
EXTRA_RACE_NAGA_KEY = "NAGA";
EXTRA_RACE_DRACTHYR_KEY = "DRACTHYR";
-- Stage I.6: keep the six custom races below the top edge and leave a
-- slightly wider faction-group gap between Dracthyr and Naga.
-- Keep these anchors independent from the gender controls so moving one row
-- can never drag the other row with it.
EXTRA_RACE_DRACTHYR_BUTTON_X = -45;
EXTRA_RACE_NAGA_BUTTON_X = 45;
EXTRA_RACE_TOP_BUTTON_Y = -26;
STAGE_I4_GENDER_BUTTON_X = 24;
STAGE_I4_GENDER_BUTTON_Y = 68;
-- Stage M3: the dedicated Monk selector sits on the center line above the
-- two gender buttons. It is only a visual alias for the real DBC enum row;
-- it never substitutes class ID 14 for the enum index expected by Glue API.
MONK_CLASS_FILE = "MONK";
MONK_CLASS_BUTTON_Y = 4;
MONK_CLASS_ICON = "Interface\\Glues\\CharacterCreate\\Reborn-Monk-Classes";
MONK_CLASS_ICON_LEFT = 0.125;
MONK_CLASS_ICON_RIGHT = 0.25;
MONK_CLASS_ICON_TOP = 0;
MONK_CLASS_ICON_BOTTOM = 0.125;
MONK_CLASS_PENDING_TOOLTIP = "|cff00ff96武僧 Monk|r|n|n当前客户端尚未从 ChrClasses.dbc 枚举到武僧。|n请部署 classID 14 的客户端/服务端 DBC 后再选择。";
MONK_PROOF_RACE_ID = 1;
-- Stage M4 deliberately opens only Human + Monk. These fallbacks keep the
-- proof self-contained without replacing the project's full GlueStrings.lua.
CLASS_INFO_MONK0 = CLASS_INFO_MONK0 or "- 职能：坦克、治疗、近战伤害";
CLASS_INFO_MONK1 = CLASS_INFO_MONK1 or "- 穿着皮甲，使用武艺与真气";
CLASS_INFO_MONK2 = CLASS_INFO_MONK2 or "- 本阶段仅用于人类武僧选择链实测";
NEW_CLASS_INFO_MONK = NEW_CLASS_INFO_MONK or "坦克、治疗、近战伤害";
NEW_CLASS_MONK = NEW_CLASS_MONK or "|cff00ff96武僧|r以武艺与真气应对战场上的各种挑战。";
NEW_CLASS_MONK_FEMALE = NEW_CLASS_MONK_FEMALE or NEW_CLASS_MONK;
CLASS_MONK = CLASS_MONK or NEW_CLASS_MONK;
CLASS_MONK_FEMALE = CLASS_MONK_FEMALE or NEW_CLASS_MONK_FEMALE;
-- Use the generic Horde scene for Naga instead of the Tauren scene.
EXTRA_RACE_NAGA_BACKGROUND_RACE = EXTRA_RACE_NAGA_INDEX;
EXTRA_RACE_DRACTHYR_BACKGROUND_RACE = 5;
EXTRA_RACE_DRACTHYR_BACKGROUND_MODEL = "Interface\\Glues\\Models\\ui_dracthyr\\ui_dracthyr.m2";
EXTRA_RACE_DRACTHYR_BACKGROUND_ZOOM_MALE = "Interface\\Glues\\Models\\ui_dracthyr\\ui_dracthyr_zoom_male.m2";
EXTRA_RACE_DRACTHYR_BACKGROUND_ZOOM_FEMALE = "Interface\\Glues\\Models\\ui_dracthyr\\ui_dracthyr_zoom_female.m2";
NORMAL_RACE_BUTTON_LIMIT = 21;
SAFE_DEFAULT_RACE_ID = 1;
-- Stage E.2.1 activates the existing XML-owned Alliance Pandaren and Dark Iron
-- buttons. Nightborne and Zandalari remain static placeholders.
STAGE_E_PANDAREN_LAYOUT_INDEX = 22;
STAGE_E_PANDAREN_RACE_ID = 22;
STAGE_E_PANDAREN_CLASS_LIST = {1,2,3,4,5,6,7,8,9,10};
-- Race22 shares the proven Pandaren scene/camera chain used by Horde Pandaren.
-- Using layout 1 (Human) makes the larger Pandaren body sit too high in close-up
-- and also selects the generic Alliance background on the default zoom level.
STAGE_E_PANDAREN_BACKGROUND_LAYOUT = 19;
STAGE_E_PANDAREN_BACKGROUND_MODEL = "Interface\\Glues\\Models\\UI_Pandaren\\UI_PandarenC.m2";
STAGE_C_DARK_IRON_LAYOUT_INDEX = 23;
STAGE_C_DARK_IRON_RACE_ID = 26;
STAGE_C_DARK_IRON_CLASS_LIST = {1,2,3,4,5,6,7,8,9,10};
STAGE_C_DARK_IRON_BACKGROUND_MODEL = "Interface\\Glues\\Models\\ui_darkirondwarf\\ui_darkirondwarf.m2";
STAGE_C_DARK_IRON_WHEEL_ZOOM_PREFIX = "Interface\\Glues\\Models\\ui_darkirondwarf\\ui_darkirondwarf_r4zdi";
STAGE_H_NIGHTBORNE_LAYOUT_INDEX = 24;
STAGE_H_NIGHTBORNE_RACE_ID = 23;
STAGE_H_NIGHTBORNE_CLASS_LIST = {1,2,3,4,5,6,7,8,9,10};
STAGE_H_NIGHTBORNE_BACKGROUND_LAYOUT = STAGE_H_NIGHTBORNE_LAYOUT_INDEX;
STAGE_H_NIGHTBORNE_BACKGROUND_MODEL = "Interface\\Glues\\Models\\ui_Nightborne\\ui_nightborne.m2";
STAGE_H_NIGHTBORNE_WHEEL_ZOOM_PREFIX = "Interface\\Glues\\Models\\ui_Nightborne\\ui_nightborne_r23znb";
STAGE_I_ZANDALARI_LAYOUT_INDEX = 25;
STAGE_I_ZANDALARI_RACE_ID = 18;
STAGE_I_ZANDALARI_CLASS_LIST = {1,2,3,4,5,6,7,8,9,10};
STAGE_I_ZANDALARI_BACKGROUND_LAYOUT = STAGE_I_ZANDALARI_LAYOUT_INDEX;
STAGE_I_ZANDALARI_BACKGROUND_MODEL = "Interface\\Glues\\Models\\ui_zandalari\\ui_zandalari.m2";
STAGE_I_ZANDALARI_WHEEL_ZOOM_PREFIX = "Interface\\Glues\\Models\\ui_zandalari\\ui_zandalari_r18zza";

-- Stage B.1: reuse the proven stage2 layout indices and offsets, but keep
-- these four XML-owned buttons outside the normal race/model selection list.
-- No RaceID, DBC or model is touched in this stage.
SIRUS_TOP_BUTTON_X_BY_LAYOUT = {
	[22] = -115, -- Alliance Pandaren
	[23] = -185, -- Dark Iron Dwarf
	[24] = 115,  -- Nightborne
	[25] = 185,  -- Zandalari Troll
};
local STAGE_B_STATIC_RACE_BUTTONS = {
	[22] = {
		displayName = "联盟熊猫人",
		faction = "ALLIANCE",
		maleTexture = "Interface\\Icons\\Reborn_PandarenMale_Round",
		femaleTexture = "Interface\\Icons\\Reborn_PandarenFemale_Round",
	},
	[23] = {
		displayName = "黑铁矮人",
		faction = "ALLIANCE",
		maleTexture = "Interface\\Icons\\Reborn_DarkIronDwarfMale_Round",
		femaleTexture = "Interface\\Icons\\Reborn_DarkIronDwarfFemale_Round",
	},
	[24] = {
		displayName = "夜之子",
		faction = "HORDE",
		maleTexture = "Interface\\Icons\\Reborn_NightborneMale_Round",
		femaleTexture = "Interface\\Icons\\Reborn_NightborneFemale_Round",
	},
	[25] = {
		displayName = "赞达拉巨魔",
		faction = "HORDE",
		maleTexture = "Interface\\Icons\\Reborn_ZandalariMale_Round",
		femaleTexture = "Interface\\Icons\\Reborn_ZandalariFemale_Round",
	},
};

function CharacterCreate_PositionStageI4GenderButtons()
	if ( not CharCreateMaleButton or not CharCreateFemaleButton or not CharCreateClassFrame ) then
		return;
	end

	-- Stage M4D: these are class/race-step controls. Parenting them to the
	-- authoritative class frame makes them disappear even if a late race/class
	-- refresh calls :Show() while the customization page is active.
	CharCreateMaleButton:SetParent(CharCreateClassFrame);
	CharCreateFemaleButton:SetParent(CharCreateClassFrame);
	CharCreateMaleButton:ClearAllPoints();
	CharCreateMaleButton:SetPoint(
		"BOTTOM",
		"CharCreateClassFrame",
		"TOP",
		-STAGE_I4_GENDER_BUTTON_X,
		STAGE_I4_GENDER_BUTTON_Y
	);
	CharCreateFemaleButton:ClearAllPoints();
	CharCreateFemaleButton:SetPoint(
		"BOTTOM",
		"CharCreateClassFrame",
		"TOP",
		STAGE_I4_GENDER_BUTTON_X,
		STAGE_I4_GENDER_BUTTON_Y
	);
	CharCreateMaleButton:SetFrameStrata("HIGH");
	CharCreateFemaleButton:SetFrameStrata("HIGH");
end

-- WD1: presentation only; this placeholder never submits a class selection.
-- Slot 0 is Monk. New classes occupy -1, +1, -2, +2 around it.
function CharacterCreate_AscendClassSlotX(order)
    if order == 0 then return 0; end
    local distance = math.floor((order + 1) / 2) * 62;
    if order % 2 == 1 then return -distance; end
    return distance;
end

-- WD1A: smaller icons on their own row, with a permanent neutral ring.
function CharacterCreate_StyleAscendClassButton(button)
    button:SetWidth(42);
    button:SetHeight(42);
    local pushed = button:GetPushedTexture();
    if pushed then pushed:SetWidth(42); pushed:SetHeight(42); end
    local checked = button:GetCheckedTexture();
    if checked then checked:SetWidth(52); checked:SetHeight(52); end
    local highlight = button:GetHighlightTexture();
    if highlight then highlight:SetWidth(52); highlight:SetHeight(52); end
    if not button.ascendNeutralRing then
        local ring = button:CreateTexture(nil, "OVERLAY");
        ring:SetTexture("Interface\\Glues\\CharacterCreate\\Reborn-Ascend-ClassRing");
        ring:SetTexCoord(0.25, 0.75, 0.25, 0.75);
        ring:SetWidth(48);
        ring:SetHeight(48);
        ring:SetPoint("CENTER", button, "CENTER", 0, 0);
        button.ascendNeutralRing = ring;
    end
end

function CharacterCreate_PositionWitchDoctorPreview()
    local button = CharCreateWitchDoctorPreviewButton;
    if not button or not CharCreateClassFrame then return; end
    button:SetParent(CharCreateClassFrame);
    CharacterCreate_StyleAscendClassButton(button);
    button:ClearAllPoints();
    button:SetPoint("BOTTOM", "CharCreateClassFrame", "TOP", CharacterCreate_AscendClassSlotX(1), MONK_CLASS_BUTTON_Y);
    button:SetFrameStrata("HIGH");
    button:SetFrameLevel(CharCreateClassFrame:GetFrameLevel() + 30);
    local index = CharacterCreate.witchDoctorClassIndex;
    local enabled = index and CharacterCreate.wdEnumeratedEnabled and CharacterCreate_WitchDoctorRaceIsOpen(CharacterCreate.selectedRace) and not PAID_SERVICE_TYPE;
    button:SetChecked(index and CharacterCreate.selectedClass == index and 1 or 0);
    if enabled then button:Enable(); else button:Disable(); end
    SetButtonDesaturated(button, not enabled);
    if button.nameFrame and button.nameFrame.text then
        button.nameFrame.text:SetText("巫医");
    end
    button.tooltip = enabled and "|cfff500ff巫医 / Witch Doctor|r|n|n法力 · 巫毒法术|n当前为创建登录测试阶段。"
        or "|cff999999巫医 / Witch Doctor|r|n|n当前仅开放人类男女；需安装匹配的职业数据与服务端。";
    if PAID_SERVICE_TYPE then button:Hide(); else button:Show(); end
end

function CharacterCreate_PositionMonkButton()
	local button = CharCreateMonkButton;
	if ( not button or not CharCreateClassFrame ) then
		return;
	end

	-- The dedicated Monk selector is a visual alias for the class list, so its
	-- visibility must follow CharCreateClassFrame on every creation sub-page.
	button:SetParent(CharCreateClassFrame);
	button:ClearAllPoints();
	button:SetPoint("BOTTOM", "CharCreateClassFrame", "TOP", 0, MONK_CLASS_BUTTON_Y);
    -- WD1B: restore the dedicated selector label after reset/enumeration.
    if button.nameFrame and button.nameFrame.text then
        button.nameFrame.text:SetText("武僧");
        button.nameFrame.text:SetAlpha(1);
        button.nameFrame.text:Show();
    end
    CharacterCreate_StyleAscendClassButton(button);
	CharacterCreate_PositionWitchDoctorPreview();
	button:SetFrameStrata("HIGH");
	if ( button.SetFrameLevel and CharCreateClassFrame.GetFrameLevel ) then
		button:SetFrameLevel(CharCreateClassFrame:GetFrameLevel() + 30);
	end
	button:Show();
end

function CharacterCreate_ResetMonkButton()
	local button = CharCreateMonkButton;
	if ( not button ) then
		return;
	end

	CharacterCreate.monkClassIndex = nil;
	button.monkClassIndex = nil;
	button.tooltip = MONK_CLASS_PENDING_TOOLTIP;
	button.tooltip2 = "";
	button:SetChecked(0);
	button:Disable();
	SetButtonDesaturated(button, 1);
	if ( CharCreateMonkButtonNormalTexture ) then
		CharCreateMonkButtonNormalTexture:SetTexture(MONK_CLASS_ICON);
		CharCreateMonkButtonNormalTexture:SetTexCoord(
			MONK_CLASS_ICON_LEFT,
			MONK_CLASS_ICON_RIGHT,
			MONK_CLASS_ICON_TOP,
			MONK_CLASS_ICON_BOTTOM
		);
		CharCreateMonkButtonNormalTexture:SetAlpha(0.45);
	end
	if ( CharCreateMonkButtonPushedTexture ) then
		CharCreateMonkButtonPushedTexture:SetTexture(MONK_CLASS_ICON);
		CharCreateMonkButtonPushedTexture:SetTexCoord(
			MONK_CLASS_ICON_LEFT,
			MONK_CLASS_ICON_RIGHT,
			MONK_CLASS_ICON_TOP,
			MONK_CLASS_ICON_BOTTOM
		);
	end
	if ( CharCreateMonkButtonDisableTexture ) then
		CharCreateMonkButtonDisableTexture:Show();
	end
	if ( button.nameFrame and button.nameFrame.text ) then
		button.nameFrame.text:SetText("");
	end
	CharacterCreate_PositionMonkButton();
end

function CharacterCreate_ConfigureMonkButton(classIndex, displayName, enabled, tooltip, tooltip2)
	local button = CharCreateMonkButton;
	if ( not button or not classIndex ) then
		return;
	end

	CharacterCreate.monkClassIndex = classIndex;
	button.monkClassIndex = classIndex;
	button.tooltip = tooltip or ("|cff00ff96"..(displayName or "武僧 Monk").."|r");
	button.tooltip2 = tooltip2 or "";
    if not CharacterCreate_MonkRaceIsOpen(CharacterCreate.selectedRace) then
        enabled = false;
        button.tooltip = "|cff999999武僧 / Monk|r";
        button.tooltip2 = "该种族暂未开放武僧。 / Monk is not available for this race yet.";
    end
	if ( enabled ) then
		button:Enable();
		SetButtonDesaturated(button, false);
		if ( CharCreateMonkButtonNormalTexture ) then
			CharCreateMonkButtonNormalTexture:SetAlpha(1);
		end
		if ( CharCreateMonkButtonDisableTexture ) then
			CharCreateMonkButtonDisableTexture:Hide();
		end
	else
		button:Disable();
		SetButtonDesaturated(button, 1);
		if ( CharCreateMonkButtonNormalTexture ) then
			CharCreateMonkButtonNormalTexture:SetAlpha(0.45);
		end
		if ( CharCreateMonkButtonDisableTexture ) then
			CharCreateMonkButtonDisableTexture:Show();
		end
	end
	CharacterCreate_PositionMonkButton();
end

function CharacterCreate_SelectMonk(self)
	local classIndex = self and self.monkClassIndex;
	if ( not self or not classIndex or not self:IsEnabled() ) then
		if ( self ) then
			self:SetChecked(0);
		end
		return;
	end
	CharacterClass_OnClick(self, classIndex);
end

function CharacterCreate_PositionSirusTopRaceButton(button, layoutIndex)
	local xOffset = SIRUS_TOP_BUTTON_X_BY_LAYOUT[layoutIndex];
	if ( not button or not xOffset or not CharacterCreate ) then
		return;
	end
	button:ClearAllPoints();
	button:SetPoint("TOP", "CharacterCreate", "TOP", xOffset, EXTRA_RACE_TOP_BUTTON_Y);
	button:SetScale(0.78);
	button:SetFrameStrata("HIGH");
	if ( CharCreateRaceButtonsFrame and button.SetFrameLevel ) then
		button:SetFrameLevel(CharCreateRaceButtonsFrame:GetFrameLevel() + 20);
	end
	if ( button.SetHitRectInsets ) then
		button:SetHitRectInsets(10, 10, 8, 8);
	end
end

function CharacterCreate_StageCIsDarkIronSelected()
	if ( not CharacterCreate or not CharacterCreate.stageCDarkIronListIndex ) then
		return false;
	end
	return CharacterCreate.selectedRace == CharacterCreate.stageCDarkIronListIndex
		or GetSelectedRace() == CharacterCreate.stageCDarkIronListIndex;
end

function CharacterCreate_StageEIsPandarenSelected()
	if ( not CharacterCreate or not CharacterCreate.stageEPandarenListIndex ) then
		return false;
	end
	return CharacterCreate.selectedRace == CharacterCreate.stageEPandarenListIndex
		or GetSelectedRace() == CharacterCreate.stageEPandarenListIndex;
end

function CharacterCreate_StageHIsNightborneSelected()
	if ( not CharacterCreate or not CharacterCreate.stageHNightborneListIndex ) then
		return false;
	end
	return CharacterCreate.selectedRace == CharacterCreate.stageHNightborneListIndex
		or GetSelectedRace() == CharacterCreate.stageHNightborneListIndex;
end

function CharacterCreate_StageBUpdateStaticRaceButtons()
	for layoutIndex=22, 25 do
		local button = _G["CharCreateRaceButton"..layoutIndex];
		local raceInfo = STAGE_B_STATIC_RACE_BUTTONS[layoutIndex];
		if ( button and raceInfo ) then
			if ( PAID_SERVICE_TYPE ) then
				button:Hide();
			else
				CharacterCreate_PositionSirusTopRaceButton(button, layoutIndex);

				local texture = raceInfo.maleTexture;
				local genderText = "男性";
				if ( type(GetSelectedSex) == "function" and GetSelectedSex() == SEX_FEMALE ) then
					texture = raceInfo.femaleTexture;
					genderText = "女性";
				end

				local normalTexture = _G[button:GetName().."NormalTexture"];
				local pushedTexture = _G[button:GetName().."PushedTexture"];
				if ( normalTexture ) then
					normalTexture:SetTexture(texture);
					normalTexture:SetTexCoord(0, 1, 0, 1);
				end
				if ( pushedTexture ) then
					pushedTexture:SetTexture(texture);
					pushedTexture:SetTexCoord(0, 1, 0, 1);
				end

				if ( button.borderfaction ) then
					if ( raceInfo.faction == "ALLIANCE" ) then
						button.borderfaction:SetTexture("Interface\\Glues\\CharacterCreate\\AlliRoundRaceOk");
					else
						button.borderfaction:SetTexture("Interface\\Glues\\CharacterCreate\\HordeRoundRaceOk");
					end
					button.borderfaction:SetAlpha(1);
					button.borderfaction:Show();
				end
				if ( button.nameFrame and button.nameFrame.text ) then
					button.nameFrame.text:SetText(raceInfo.displayName);
					button.nameFrame.text:SetAlpha(1);
				end

				button.stageBLayoutIndex = layoutIndex;
				if ( layoutIndex == STAGE_E_PANDAREN_LAYOUT_INDEX
					and CharacterCreate and CharacterCreate.stageEPandarenListIndex ) then
					button:SetID(CharacterCreate.stageEPandarenListIndex);
					button.stageCActiveRace = true;
					button.tooltip = "|cffFFFFFF联盟熊猫人|r\n\n"
						.."熊猫人源自被迷雾笼罩的潘达利亚大陆。数千年前，"
						.."他们的族人饱受古老魔古帝国残酷的奴役。但凭借超凡的"
						.."坚韧、高超的外交手段与独特的武道，熊猫人团结起"
						.."潘达利亚各族人民，终结了魔古的暴政，为故土带来和平。\n\n"
						.."少数游历四方的熊猫人，为追寻智慧或是冒险离开了家乡。"
						.."他们远离联盟与部落的纷争，但愿意向真正身处危难之人"
						.."伸出援手。如今，其中一些选择与联盟并肩作战。\n\n"
						.."种族特色：精通美食与烹饪；身手轻盈，休息时能积蓄"
						.."更多经验；可施展震山掌使敌人短暂瘫痪。";
					button:SetChecked(CharacterCreate_StageEIsPandarenSelected() and 1 or 0);
				elseif ( layoutIndex == STAGE_H_NIGHTBORNE_LAYOUT_INDEX
					and CharacterCreate and CharacterCreate.stageHNightborneListIndex ) then
					button:SetID(CharacterCreate.stageHNightborneListIndex);
					button.stageCActiveRace = true;
					button.tooltip = "|cffFFFFFF夜之子|r\n\n"
						.."夜之子曾是苏拉玛古老文明的子民。万年以来，夜井的奥术能量塑造了他们的身体与文化，也令他们与外界隔绝。\n\n"
						.."在摆脱燃烧军团的统治后，夜之子重新踏入艾泽拉斯，并选择与部落并肩作战。\n\n"
						.."种族特色：精通奥术魔法，能够召唤魔典，并可暂时减缓附近敌人的行动。";
					button:SetChecked(CharacterCreate_StageHIsNightborneSelected() and 1 or 0);
				elseif ( layoutIndex == STAGE_I_ZANDALARI_LAYOUT_INDEX
					and CharacterCreate and CharacterCreate.stageIZandalariListIndex ) then
					button:SetID(CharacterCreate.stageIZandalariListIndex);
					button.stageCActiveRace = true;
					button.tooltip = "|cffFFFFFF赞达拉巨魔|r\n\n"
						.."赞达拉巨魔来自古老强盛的赞达拉帝国。他们世代守护神圣的洛阿传统，并以强健体魄、卓越战技与深厚信仰闻名。\n\n"
						.."当新的威胁席卷艾泽拉斯时，赞达拉选择与部落并肩作战，为帝国的荣耀与未来而战。\n\n"
						.."种族特色：能够借助洛阿之力强化自身，并拥有出色的恢复能力与野外生存本领。";
					button:SetChecked(CharacterCreate_StageIIsZandalariSelected() and 1 or 0);
				elseif ( layoutIndex == STAGE_C_DARK_IRON_LAYOUT_INDEX
					and CharacterCreate and CharacterCreate.stageCDarkIronListIndex ) then
					button:SetID(CharacterCreate.stageCDarkIronListIndex);
					button.stageCActiveRace = true;
					button.tooltip = "|cffFFFFFF黑铁矮人|r\n\n"
						.."黑铁矮人以暴躁的性情与不屈的顽固闻名。三百年前，"
						.."他们挑起了三锤之战；战后，许多黑铁矮人转而侍奉"
						.."炎魔拉格纳罗斯。如今他们的主宰已被逐出艾泽拉斯，"
						.."不少黑铁矮人选择效忠女王茉艾拉·铜须，期望重新赢得"
						.."其他矮人部族的信任。\n\n"
						.."种族特色：能够化为石像抵御伤害；擅长枪械与锤类武器；"
						.."拥有冰霜抗性与寻找财宝的天赋。";
					button:SetChecked(CharacterCreate_StageCIsDarkIronSelected() and 1 or 0);
				else
					button:SetID(layoutIndex);
					button.stageCActiveRace = nil;
					button.tooltip = "|cffFFFFFF"..raceInfo.displayName.."|r\n\n"
						.."阶段B.1静态图标（"..genderText.."）\n"
						.."仅用于布局与点击测试，尚未激活种族和模型。";
					button:SetChecked(0);
				end
				button:Enable();
				button:Show();
			end
		end
	end
end

function CharacterCreate_StageBStaticRaceButton_OnClick(button)
	if ( not button ) then
		return;
	end
	local layoutIndex = button.stageBLayoutIndex or button:GetID();
	if ( layoutIndex == STAGE_E_PANDAREN_LAYOUT_INDEX
		and CharacterCreate and CharacterCreate.stageEPandarenListIndex ) then
		button:SetID(CharacterCreate.stageEPandarenListIndex);
		CharacterRace_OnClick(button, CharacterCreate.stageEPandarenListIndex, true);
		return;
	end
	if ( layoutIndex == STAGE_H_NIGHTBORNE_LAYOUT_INDEX
		and CharacterCreate and CharacterCreate.stageHNightborneListIndex ) then
		button:SetID(CharacterCreate.stageHNightborneListIndex);
		CharacterRace_OnClick(button, CharacterCreate.stageHNightborneListIndex, true);
		return;
	end
	if ( layoutIndex == STAGE_I_ZANDALARI_LAYOUT_INDEX
		and CharacterCreate and CharacterCreate.stageIZandalariListIndex ) then
		button:SetID(CharacterCreate.stageIZandalariListIndex);
		CharacterRace_OnClick(button, CharacterCreate.stageIZandalariListIndex, true);
		return;
	end
	if ( layoutIndex == STAGE_C_DARK_IRON_LAYOUT_INDEX
		and CharacterCreate and CharacterCreate.stageCDarkIronListIndex ) then
		button:SetID(CharacterCreate.stageCDarkIronListIndex);
		CharacterRace_OnClick(button, CharacterCreate.stageCDarkIronListIndex, true);
		return;
	end

	button:SetChecked(0);
	local raceInfo = STAGE_B_STATIC_RACE_BUTTONS[layoutIndex];
	if ( not raceInfo ) then
		return;
	end
	local genderText = "男性";
	if ( type(GetSelectedSex) == "function" and GetSelectedSex() == SEX_FEMALE ) then
		genderText = "女性";
	end
	local debugText = "[RebornWOW 阶段C] 点击未激活静态图标："
		..raceInfo.displayName.." / "..genderText
		.."；未切换RaceID，未读取模型。";
	if ( CharacterCreate ) then
		CharacterCreate.stageBLastDebug = debugText;
	end
	if ( type(print) == "function" ) then
		print(debugText);
	end
end

local featureIndex = 1
local FeatureType = 1

PAID_CHARACTER_CUSTOMIZATION = 1;
PAID_RACE_CHANGE = 3;
PAID_FACTION_CHANGE = 2;
PAID_SERVICE_CHARACTER_ID = nil;
PAID_SERVICE_TYPE = nil;

PREVIEW_FRAME_HEIGHT = 130;
PREVIEW_FRAME_X_OFFSET = 19;
PREVIEW_FRAME_Y_OFFSET = -7;

GLOBAL_ZOOM_POS_22 = 1;

FACTION_BACKDROP_COLOR_TABLE = {
	["Alliance"] = {0.5, 0.5, 0.5, 0.09, 0.09, 0.19, 0, 0, 0.2, 0.29, 0.33, 0.91},
	["Horde"] = {0.5, 0.2, 0.2, 0.19, 0.05, 0.05, 0.2, 0, 0, 0.90, 0.05, 0.07},
	["Player"] = {0.2, 0.5, 0.2, 0.05, 0.2, 0.05, 0.05, 0.2, 0.05, 1, 1, 1},
};
FRAMES_TO_BACKDROP_COLOR = {
	"CharacterCreateCharacterRace",
	"CharacterCreateCharacterClass",
--	"CharacterCreateCharacterFaction",
	"CharacterCreateNameEdit",
};
RACE_ICON_TCOORDS = {
	["HUMAN_MALE"]		= {0, 0.125, 0, 0.25},
	["DWARF_MALE"]		= {0.125, 0.25, 0, 0.25},
	["GNOME_MALE"]		= {0.25, 0.375, 0, 0.25},
	["NIGHTELF_MALE"]	= {0.375, 0.5, 0, 0.25},

	["TAUREN_MALE"]		= {0, 0.125, 0.25, 0.5},
	["SCOURGE_MALE"]	= {0.125, 0.25, 0.25, 0.5},
	["TROLL_MALE"]		= {0.25, 0.375, 0.25, 0.5},
	["ORC_MALE"]		= {0.375, 0.5, 0.25, 0.5},

	["HUMAN_FEMALE"]	= {0, 0.125, 0.5, 0.75},
	["DWARF_FEMALE"]	= {0.125, 0.25, 0.5, 0.75},
	["GNOME_FEMALE"]	= {0.25, 0.375, 0.5, 0.75},
	["NIGHTELF_FEMALE"]	= {0.375, 0.5, 0.5, 0.75},

	["TAUREN_FEMALE"]	= {0, 0.125, 0.75, 1.0},
	["SCOURGE_FEMALE"]	= {0.125, 0.25, 0.75, 1.0},
	["TROLL_FEMALE"]	= {0.25, 0.375, 0.75, 1.0},
	["ORC_FEMALE"]		= {0.375, 0.5, 0.75, 1.0},

	["BLOODELF_MALE"]	= {0.5, 0.625, 0.25, 0.5},
	["BLOODELF_FEMALE"]	= {0.5, 0.625, 0.75, 1.0},

	["DRAENEI_MALE"]	= {0.5, 0.625, 0, 0.25},
	["DRAENEI_FEMALE"]	= {0.5, 0.625, 0.5, 0.75},

	-- ["WORGEN_MALE"]		= {0.625, 0.75, 0, 0.25},
	-- ["WORGEN_FEMALE"]	= {0.625, 0.75, 0.5, 0.75},
	--
	  ["GOBLIN_MALE"]		= {0.625, 0.75, 0.125, 0.25},
	  ["GOBLIN_FEMALE"]	= {0.625, 0.75, 0.375, 0.5},
};

RACE_ICON_TCOORDS = {
	["HUMAN_MALE"]		= {0, 0.125, 0, 0.125},
	["HUMAN_FEMALE"]	= {0, 0.125, 0.125, 0.25},
	
	["DWARF_MALE"]		= {0.25, 0.375, 0.5, 0.625},
	["DWARF_FEMALE"]	= {0.25, 0.375, 0.625, 0.75},
	
	["NIGHTELF_MALE"]	= {0.125, 0.25, 0.25, 0.375},
	["NIGHTELF_FEMALE"]	= {0.125, 0.25, 0.375, 0.5},
	
	["GNOME_MALE"]		= {0.5, 0.625, 0.5, 0.625},
	["GNOME_FEMALE"]	= {0.5, 0.625, 0.625, 0.75},
	
	["TAUREN_MALE"]		= {0.25, 0.375,0.25, 0.375},
	["TAUREN_FEMALE"]	= {0.25, 0.375, 0.375, 0.5},

	["SCOURGE_MALE"]	= {0.625, 0.75, 0, 0.125},
	["SCOURGE_FEMALE"]	= {0.625, 0.75, 0.125, 0.25},
	
	["TROLL_MALE"]		= {0, 0.125, 0.5, 0.625},
	["TROLL_FEMALE"]	= {0, 0.125, 0.625, 0.75},
	
	["ORC_MALE"]		= {0.875, 1.0, 0, 0.125},
	["ORC_FEMALE"]		= {0.875, 1.0, 0.125, 0.25},

	["BLOODELF_MALE"]	= {0.25, 0.375, 0, 0.125},
	["BLOODELF_FEMALE"]	= {0.25, 0.375, 0.125, 0.25},

	["DRAENEI_MALE"]	= {0.75, 0.875, 0.25, 0.375},
	["DRAENEI_FEMALE"]	= {0.75, 0.875, 0.375, 0.5},
	-- Goblin
	["GOBLIN_MALE"]		= {0.75, 0.875, 0, 0.125},
	["GOBLIN_FEMALE"]	= {0.75, 0.875, 0.125, 0.25},
	-- Worgen
	["WORGEN_MALE"]	    = {0.375, 0.5, 0, 0.125},
	["WORGEN_FEMALE"]	= {0.375, 0.5, 0.125, 0.25}, 
	-- Pandaren Horde (Eredar)
	["SKELETON_MALE"]	= {0.125, 0.25 , 0.75, 0.875},
	["SKELETON_FEMALE"]	= {0.125, 0.25 , 0.875, 1.0},
	-- Pandaren Alliance 
    ["TUSKARR_MALE"]	= {0.375, 0.5, 0.25, 0.375},
	["TUSKARR_FEMALE"]	= {0.375, 0.5, 0.375, 0.5},
	-- Void Elf
	["FELORC_MALE"]	= {0.125, 0.25 , 0, 0.125},
	["FELORC_FEMALE"]	= {0.125, 0.25 , 0.125, 0.25},
	-- Nightborne(High Elf)
	["BROKEN_MALE"]	    = {0.875, 1.0 , 0.5, 0.625},
	["BROKEN_FEMALE"]	= {0.875, 1.0 , 0.625, 0.75},
	-- Pandaren
	["FORESTTROLL_MALE"]	= {0.75, 0.875, 0.5, 0.625},
	["FORESTTROLL_FEMALE"]	= {0.75, 0.875, 0.625, 0.75},
	-- Lightforged
	["TAUNKA_MALE"]	= {0.375, 0.5, 0.5, 0.625},
	["TAUNKA_FEMALE"]	= {0.375, 0.5, 0.625, 0.75}, 
	-- Demon Hunter Blood Elf
	["ICETROLL_MALE"]	= {0.5, 0.625, 0.25, 0.375},
	["ICETROLL_FEMALE"]	= {0.5, 0.625, 0.375, 0.5},
	-- Vulpera
	["NAGA__MALE"]	= {0, 0.125, 0.25, 0.375},
	["NAGA__FEMALE"]	= {0, 0.125, 0.375, 0.5},
	-- Demon Hunter Night Elf	
	["NORTHRENDSKELETON_MALE"]	= {0.375, 0.5, 0.25, 0.375},
	["NORTHRENDSKELETON_FEMALE"]	= {0.375, 0.5, 0.375, 0.5},
	-- Eredar
	["EREDAR_MALE"]	    = {0.125, 0.25 , 0.75, 0.875},
	["EREDAR_FEMALE"]	= {0.125, 0.25 , 0.875, 1.0},
	-- Zandalari Troll (OLD)
	["ZANDALARITROLL_MALE"]	    = {0.75, 0.875, 0.5, 0.625},
	["ZANDALARITROLL_FEMALE"]	= {0.75, 0.875, 0.625, 0.75},
};

CLASS_ICON_TCOORDS = {
	["WARRIOR"]	= {0, 0.25, 0, 0.25},
	["MAGE"]	= {0.25, 0.49609375, 0, 0.25},
	["ROGUE"]	= {0.49609375, 0.7421875, 0, 0.25},
	["DRUID"]	= {0.7421875, 0.98828125, 0, 0.25},
	["HUNTER"]	= {0, 0.25, 0.25, 0.5},
	["SHAMAN"]	= {0.25, 0.49609375, 0.25, 0.5},
	["PRIEST"]	= {0.49609375, 0.7421875, 0.25, 0.5},
	["WARLOCK"]	= {0.7421875, 0.98828125, 0.25, 0.5},
	["PALADIN"]	= {0, 0.25, 0.5, 0.75},
	["DEATHKNIGHT"]	= {0.25, 0.49609375, 0.5, 0.75},
	["ENGINEER"] = {0.25, 0.49609375, 0.5, 0.75}
};

BANNER_DEFAULT_TEXTURE_COORDS = {0.109375, 0.890625, 0.201171875, 0.80078125};
BANNER_DEFAULT_SIZE = {200, 308};

CHAR_CUSTOMIZE_HAIR_COLOR = 4;
 
 
-- Stage16 Race27 Dracthyr creation preview buttons
-- Stage41 rollback: restore CharacterCreate.xml to ModelFFX after DressUpModel root freeze.
-- Stage44: probe which CreateFrame frame types are registered in the Glue character creation environment.
-- Stage48: fix Stage47 DUM register status typo and add direct DressUpModel method probe.
-- Stage56: restore the DUM method probe entry and guard button callbacks against missing Lua functions.
-- Stage57: auto-request native DressUpModel registration before DUM/NO probes and summarize live model methods.
-- Stage88: Stage80 immediate restore and three-button UI on the stable Stage79 command chain.
-- Stage47 result kept: native PlayerModel/DressUpModel/TabardModel registration is still provided by the proxy DLL.
-- Goal: expose T7 / NO / T14 preview modes and keep the selected mode after customization.
DRACTHYR_CREATION_PREVIEW_RACES = { [1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [6] = true, [7] = true, [8] = true, [9] = true, [10] = true, [11] = true, [12] = true, [13] = true, [14] = true, [15] = true, [16] = true, [17] = true, [18] = true, [19] = true, [20] = true, [21] = true, [25] = true, [27] = true, [35] = true, [900] = true, [2000] = true };
DRACTHYR_CREATION_PREVIEW_MODES = {
	{ key = "default", label = "T7装备" },
	{ key = "t14", label = "T14装备" },
	{ key = "none", label = "NO装备" },
};
DRACTHYR_CREATION_FRAME_TYPE_CANDIDATES = {
	"Frame",
	"Button",
	"CheckButton",
	"Model",
	"PlayerModel",
	"DressUpModel",
	"ModelFFX",
	"TabardModel",
	"CinematicModel",
};
DRACTHYR_CREATION_FRAME_TYPE_SHORT_NAMES = {
	["Frame"] = "F",
	["Button"] = "B",
	["CheckButton"] = "CB",
	["Model"] = "M",
	["PlayerModel"] = "PM",
	["DressUpModel"] = "DUM",
	["ModelFFX"] = "MFX",
	["TabardModel"] = "TM",
	["CinematicModel"] = "CM",
};
DRACTHYR_CREATION_DYNAMIC_MODEL_TYPES = {
	{ frameType = "Model", shortName = "M" },
	{ frameType = "PlayerModel", shortName = "PM" },
	{ frameType = "DressUpModel", shortName = "DUM" },
	{ frameType = "ModelFFX", shortName = "MFX" },
	{ frameType = "TabardModel", shortName = "TM" },
	{ frameType = "CinematicModel", shortName = "CM" },
};
DRACTHYR_CREATION_PREVIEW_T14_ITEMS = {
	[0] = {
		[1] = { 38, 39, 40, 49778, 6948, 77268, 77120, 78888, 77171, 77166 },
		[2] = { 45, 43, 44, 6948, 2361, 85344, 90423, 90454, 85345, 90445, 87404 },
		[3] = { 127, 6126, 6127, 12282, 6948, 2101, 23347, 158630, 87941, 90421, 90453, 89830, 90444, 87938 },
		[4] = { 49, 47, 48, 28979, 2092, 50055, 6948, 89836, 90420, 90451, 90518, 90442, 89842 },
		[5] = { 6098, 52, 53, 51, 35, 6948, 89924, 89949, 87178, 87121, 151827, 87119 },
		[6] = { 34652, 34655, 34659, 34650, 34653, 34649, 34651, 34656, 34648, 34657, 34658, 38145, 38147, 41751, 88503, 88505, 90455, 88502, 90521, 89843 },
		[7] = { 154, 153, 6948, 36, 2362, 85349, 90529, 90738 },
		[8] = { 56, 1395, 55, 35, 6096, 6948, 89947, 87027, 87179, 87174, 86959, 89931 },
		[9] = { 57, 6097, 1396, 35, 59, 6948, 85373, 85372, 90449, 86229, 86330, 85369 },
		[11] = { 3661, 6123, 6124, 6948, 87957, 86972, 87951, 89948, 90514, 91094 },
	},
	[1] = {
		[1] = { 38, 39, 40, 49778, 6948, 77268, 77120, 78888, 77171, 77166 },
		[2] = { 45, 43, 44, 6948, 2361, 85344, 90423, 90454, 85345, 90445, 87404 },
		[3] = { 127, 6126, 6127, 12282, 6948, 2101, 23347, 158630, 87941, 90421, 90453, 89830, 90444, 87938 },
		[4] = { 49, 47, 48, 28979, 2092, 50055, 6948, 89836, 90420, 90451, 90518, 90442, 89842 },
		[5] = { 6098, 52, 53, 51, 35, 6948, 89924, 89949, 87178, 87121, 151827, 87119 },
		[6] = { 34652, 34655, 34659, 34650, 34653, 34649, 34651, 34656, 34648, 34657, 34658, 38145, 38147, 41751, 88503, 88505, 90455, 88502, 90521, 89843 },
		[7] = { 154, 153, 6948, 36, 2362, 85349, 90529, 90738 },
		[8] = { 56, 1395, 55, 35, 6096, 6948, 89947, 87027, 87179, 87174, 86959, 89931 },
		[9] = { 57, 6097, 1396, 35, 59, 6948, 85373, 85372, 90449, 86229, 86330, 85369 },
		[11] = { 3661, 6123, 6124, 6948, 87957, 86972, 87951, 89948, 90514, 91094 },
	},
};

function CharacterCreate_IsDracthyrCreationPreviewRace()
	local race = nil;
	if ( CharacterCreate ) then
		race = CharacterCreate.selectedRace or CharacterCreate.customSelectedRace;
	end
	if ( not race and EXTRA_RACE_DRACTHYR_INDEX ) then
		race = EXTRA_RACE_DRACTHYR_INDEX;
	end
	return race and DRACTHYR_CREATION_PREVIEW_RACES[race];
end

function CharacterCreate_GetDracthyrCreationPreviewClass()
	if ( CLASS_ALMACENADA and CLASS_ALMACENADA > 0 ) then
		return CLASS_ALMACENADA;
	end
	if ( CharacterCreate and CharacterCreate.selectedClass and CharacterCreate.selectedClass > 0 ) then
		return CharacterCreate.selectedClass;
	end
	return 1;
end

function CharacterCreate_GetDracthyrCreationPreviewGender()
	if ( type(GetSelectedSex) == "function" and SEX_FEMALE and GetSelectedSex() == SEX_FEMALE ) then
		return 1;
	end
	return 0;
end

-- Stage55: keep the full probe status internally, but only show a short
-- two-line summary on the character creation screen so it cannot overlap
-- the Finish button or the probe buttons.
function CharacterCreate_FormatDracthyrCreationPreviewStatusForUi(text)
	local value = tostring(text or "");
	if ( type(gsub) == "function" ) then
		value = gsub(value, "\r", "");
	end

	local firstLine = value;
	local secondLine = nil;
	local marker = strfind(value, "|n");
	if ( marker ) then
		firstLine = strsub(value, 1, marker - 1);
		secondLine = strsub(value, marker + 2);
		local secondMarker = strfind(secondLine, "|n");
		if ( secondMarker ) then
			secondLine = strsub(secondLine, 1, secondMarker - 1).." ...";
		end
	end

	if ( strlen(firstLine) > 34 ) then
		firstLine = strsub(firstLine, 1, 34).."...";
	end
	if ( secondLine and strlen(secondLine) > 34 ) then
		secondLine = strsub(secondLine, 1, 34).."...";
	end
	if ( secondLine and secondLine ~= "" ) then
		return firstLine.."|n"..secondLine;
	end
	return firstLine;
end

function CharacterCreate_SetDracthyrCreationPreviewStatus(text)
	CharacterCreate.dracthyrCreationPreviewStatusText = text or "";
	if ( DracthyrCreationPreviewFrame and DracthyrCreationPreviewFrame.status ) then
		DracthyrCreationPreviewFrame.status:SetText(CharacterCreate_FormatDracthyrCreationPreviewStatusForUi(CharacterCreate.dracthyrCreationPreviewStatusText));
	end
end

-- Stage25: Glue Lua -> DivxDecoder command bridge probe.
-- This does not change equipment by itself. It checks whether the character
-- creation Lua layer can talk to the Stage24 native DLL command bridge.
function CharacterCreate_AppendDracthyrCreationPreviewStatus(text)
	if ( not text or text == "" ) then
		return;
	end
	local current = CharacterCreate.dracthyrCreationPreviewStatusText or "";
	if ( current ~= "" ) then
		CharacterCreate_SetDracthyrCreationPreviewStatus(current.."|n"..text);
	else
		CharacterCreate_SetDracthyrCreationPreviewStatus(text);
	end
end

function CharacterCreate_GetStage25BridgeSeq()
	local base = 1;
	if ( type(GetTime) == "function" and math and math.floor ) then
		base = math.floor(GetTime() * 1000);
	end
	if ( not CharacterCreate.stage25BridgeSeq or CharacterCreate.stage25BridgeSeq >= base ) then
		CharacterCreate.stage25BridgeSeq = (CharacterCreate.stage25BridgeSeq or 0) + 1;
	else
		CharacterCreate.stage25BridgeSeq = base;
	end
	return CharacterCreate.stage25BridgeSeq;
end

function CharacterCreate_WriteStage25CommandFile(seq, command, arg)
	if ( not io or type(io.open) ~= "function" ) then
		return false, "io.open缺失";
	end
	local paths = {
		"Race27ClientExtCommand.ini",
		"D:\\game\\newrebornWOWli20260515 - Copy\\Race27ClientExtCommand.ini",
	};
	local lastErr = nil;
	local okCount = 0;
	local lastPath = nil;
	for _, path in ipairs(paths) do
		local file, err = io.open(path, "w");
		if ( file ) then
			file:write("[Command]\n");
			file:write("seq="..tostring(seq).."\n");
			file:write("name="..tostring(command or "").."\n");
			file:write("arg="..tostring(arg or "").."\n");
			file:close();
			okCount = okCount + 1;
			lastPath = path;
		else
			lastErr = tostring(path)..":"..tostring(err);
		end
	end
	if ( okCount > 0 ) then
		return true, "io.open OK seq="..tostring(seq).." count="..tostring(okCount).." path="..tostring(lastPath);
	end
	return false, "io.open失败:"..tostring(lastErr);
end

function CharacterCreate_GetStage65BridgeRepeatCount(command)
	return 1;
end

-- The class buttons use the client's compact UI ordering.  The native T14
-- bridge uses the real class IDs instead, where Druid is 11 rather than 10.
T14_PREVIEW_NATIVE_CLASS_IDS = {
	["WARRIOR"] = 1,
	["PALADIN"] = 2,
	["HUNTER"] = 3,
	["ROGUE"] = 4,
	["PRIEST"] = 5,
	["DEATHKNIGHT"] = 6,
	["SHAMAN"] = 7,
	["MAGE"] = 8,
	["WARLOCK"] = 9,
	["DRUID"] = 11,
	-- WD2B: costume profile only; character identity remains WITCHDOCTOR/class 13.
	-- The installed native preview bridge has legacy profiles, not a class 13 profile.
	["WITCHDOCTOR"] = 7,
	-- Costume only: legacy bridge has no Monk profile; use leather Rogue preview.
	["MONK"] = 4,
};

function CharacterCreate_GetT14PreviewNativeClassId()
	local _, classFileName = GetSelectedClass();
	local nativeClassId = T14_PREVIEW_NATIVE_CLASS_IDS[strupper(classFileName or "")];
	if ( nativeClassId ) then
		return nativeClassId;
	end

	local uiClassId = CharacterCreate_GetDracthyrCreationPreviewClass() or 1;
	if ( uiClassId == 10 ) then
		return 11;
	end
	return uiClassId;
end

function CharacterCreate_SendStage25BridgeCommand(command, arg)
	local seq = CharacterCreate_GetStage25BridgeSeq();
	local candidates = {};
	local isT14ClassCommand = type(command) == "string" and string.match(command, "^T14_EQUIPMENT_PREVIEW_TEST_C%d%d$") ~= nil;
	local isPreviewCommand = ( command == "DEFAULT_EQUIPMENT_PREVIEW_TEST" or command == "NO_EQUIPMENT_PREVIEW_TEST" or command == "T14_EQUIPMENT_PREVIEW_TEST" or isT14ClassCommand );
	local commandFileInfo = nil;
	local commandFileWritten = false;
	if ( isPreviewCommand ) then
		local directBridge = _G["R27_NoEquipmentCommand"];
		if ( type(directBridge) == "function" ) then
			local repeatCount = CharacterCreate_GetStage65BridgeRepeatCount(command);
			local okCount = 0;
			local lastErr = nil;
			for i = 1, repeatCount do
				local bridgeOk, bridgeErr = pcall(directBridge, command, arg or "", seq);
				if ( bridgeOk and bridgeErr ~= false ) then
					okCount = okCount + 1;
				else
					lastErr = bridgeErr;
					break;
				end
			end
			if ( okCount == repeatCount ) then
				return true, "R27_NoEquipmentCommand OK seq="..tostring(seq).." repeat="..tostring(repeatCount);
			end
			commandFileInfo = "内存桥失败:"..strsub(tostring(lastErr), 1, 50);
		end
		local fileCallOk, fileOk, fileDetail = pcall(CharacterCreate_WriteStage25CommandFile, seq, command, arg);
		if ( fileCallOk and fileOk ) then
			commandFileInfo = fileDetail;
			commandFileWritten = true;
		elseif ( fileCallOk ) then
			commandFileInfo = "命令文件失败:"..tostring(fileDetail);
		else
			commandFileInfo = "命令文件异常:"..strsub(tostring(fileOk), 1, 50);
		end
	end
	table.insert(candidates, "R27_SendClientCommand");
	table.insert(candidates, "Race27_SendClientCommand");
	table.insert(candidates, "ClientExt_SendCommand");
	table.insert(candidates, "SendClientExtCommand");
	table.insert(candidates, "SendRace27ClientCommand");
	for _, name in ipairs(candidates) do
		local fn = _G[name];
		if ( type(fn) == "function" ) then
			local ok, err = pcall(fn, command, arg or "", seq);
			if ( ok and err ~= false ) then
				if ( commandFileInfo ) then
					return true, name.." OK seq="..tostring(seq).." "..commandFileInfo;
				end
				return true, name.." OK seq="..tostring(seq);
			end
			return false, name.." ERR "..strsub(tostring(err), 1, 50);
		end
	end

	if ( commandFileInfo ) then
		return commandFileWritten, commandFileInfo;
	end
	local ok, fileOk, fileDetail = pcall(CharacterCreate_WriteStage25CommandFile, seq, command, arg);
	if ( ok and fileOk ) then
		return true, fileDetail;
	end
	if ( ok ) then
		return false, fileDetail;
	end
	return false, "写文件异常:"..strsub(tostring(fileOk), 1, 50);
end

function CharacterCreate_SendStage25PreviewBridgeForMode(key, silent)
	local command = nil;
	local uiClassId = CharacterCreate_GetDracthyrCreationPreviewClass() or 1;
	local nativeClassId = CharacterCreate_GetT14PreviewNativeClassId() or uiClassId;
	local nativeClassText = tostring(nativeClassId);
	if ( nativeClassId < 10 ) then
		nativeClassText = "0"..nativeClassText;
	end
	local arg = "stage104_"..tostring(key or "unknown").."_ui_"..tostring(uiClassId).."_native_"..nativeClassText;
	if ( key == "default" ) then
		command = "DEFAULT_EQUIPMENT_PREVIEW_TEST";
	elseif ( key == "none" ) then
		command = "NO_EQUIPMENT_PREVIEW_TEST";
	elseif ( key == "t14" ) then
		command = "T14_EQUIPMENT_PREVIEW_TEST_C"..nativeClassText;
	elseif ( key == "modelapi" ) then
		command = "PING";
	end
	if ( not command ) then
		return;
	end

	local ok, detail = CharacterCreate_SendStage25BridgeCommand(command, arg);
	if ( ok and not silent ) then
		CharacterCreate_AppendDracthyrCreationPreviewStatus("桥OK: "..detail);
	elseif ( not ok and not silent ) then
		CharacterCreate_AppendDracthyrCreationPreviewStatus("桥失败: "..tostring(detail));
	end
	return ok, detail;
end

function CharacterCreate_Stage80SendPreviewBridge(modeKey, silent)
	if ( CharacterCreate and CharacterCreate.stage80PreviewBridgeBusy ) then
		return false;
	end
	if ( CharacterCreate ) then
		CharacterCreate.stage80PreviewBridgeBusy = true;
	end
	local ok, dispatched, detail = pcall(CharacterCreate_SendStage25PreviewBridgeForMode, modeKey, silent);
	if ( CharacterCreate ) then
		CharacterCreate.stage80PreviewBridgeBusy = nil;
	end
	if ( not ok ) then
		CharacterCreate_AppendDracthyrCreationPreviewStatus("桥异常: "..strsub(tostring(dispatched), 1, 60));
		return false;
	end
	return dispatched == true, detail;
end

function CharacterCreate_GetDracthyrCreationPreviewModels()
	local models = {};
	local seen = {};
	local function add(model)
		if ( model and not seen[model] ) then
			seen[model] = true;
			table.insert(models, model);
		end
	end
	add(CharacterCreate);
	add(_G["CharacterCreate"]);
	add(_G["CharacterCreateModel"]);
	add(_G["CharCreateModel"]);
	add(_G["CharCreatePreviewModel"]);
	add(_G["R27DynamicProbeDressUpModel"]);
	add(_G["R27DynamicProbePlayerModel"]);
	add(_G["R27DynamicProbeModel"]);
	add(_G["R27DynamicProbeModelFFX"]);
	if ( CharacterCreateFrame ) then
		add(CharacterCreateFrame.Model);
		add(CharacterCreateFrame.model);
		if ( type(CharacterCreateFrame.GetChildren) == "function" ) then
			local ok, children = pcall(function() return { CharacterCreateFrame:GetChildren() }; end);
			if ( ok and children ) then
				for _, child in ipairs(children) do
					add(child);
				end
			end
		end
	end
	return models;
end

function CharacterCreate_CallDracthyrModelMethod(methodName, ...)
	local called = 0;
	local lastError = nil;
	for _, model in ipairs(CharacterCreate_GetDracthyrCreationPreviewModels()) do
		local method = model and model[methodName];
		if ( type(method) == "function" ) then
			local ok, err = pcall(method, model, ...);
			if ( ok ) then
				called = called + 1;
			else
				lastError = err;
			end
		end
	end
	return called, lastError;
end

function CharacterCreate_RefreshDracthyrCreationPreviewFromDefault()
	local race = CharacterCreate and (CharacterCreate.selectedRace or CharacterCreate.customSelectedRace);
	local classId = CharacterCreate_GetDracthyrCreationPreviewClass();
	if ( race and type(SetSelectedRace) == "function" ) then
		pcall(SetSelectedRace, race);
	end
	if ( classId and type(SetSelectedClass) == "function" ) then
		pcall(SetSelectedClass, classId);
	end
	if ( classId and type(SetCharacterClass) == "function" ) then
		pcall(SetCharacterClass, classId);
	end
	if ( type(UpdateCustomizationScene) == "function" ) then
		pcall(UpdateCustomizationScene);
	end
	if ( CharacterCreate and type(CharacterCreate.AdvanceTime) == "function" ) then
		pcall(CharacterCreate.AdvanceTime, CharacterCreate);
	end
end

function CharacterCreate_Stage66Call(label, fn, ...)
	if ( type(fn) ~= "function" ) then
		return false, tostring(label).."缺失";
	end
	local ok, err = pcall(fn, ...);
	if ( ok ) then
		return true, tostring(label);
	end
	return false, tostring(label)..":"..strsub(tostring(err), 1, 36);
end

function CharacterCreate_Stage66PulseCustomization()
	local featureType = nil;
	if ( CharacterCreateFrame ) then
		featureType = CharacterCreateFrame.customizationType;
	end
	featureType = featureType or FeatureType;
	if ( type(CycleCharCustomization) ~= "function" or not featureType ) then
		return false, "Cycle缺失";
	end
	local okForward = pcall(CycleCharCustomization, featureType, 1);
	local okBack = pcall(CycleCharCustomization, featureType, -1);
	return okForward and okBack, "Cycle+/-";
end

function CharacterCreate_Stage66RefreshPreviewNow(modeKey, stepIndex)
	local calls = {};
	local race = CharacterCreate and (CharacterCreate.customSelectedRace or CharacterCreate.selectedRace);
	race = CharacterCreate_GetSafeRaceId(race or GetSelectedRace());
	local classId = CharacterCreate_GetDracthyrCreationPreviewClass();
	local sex = CharacterCreate_GetDracthyrCreationPreviewGender();
	local ok, label;

	local function remember(callOk, callLabel)
		if ( callOk ) then
			table.insert(calls, callLabel);
		end
	end

	if ( race ) then
		ok, label = CharacterCreate_Stage66Call("SetSelectedRace", SetSelectedRace, race);
		remember(ok, label);
	end
	if ( sex ) then
		ok, label = CharacterCreate_Stage66Call("SetSelectedSex", SetSelectedSex, sex);
		remember(ok, label);
	end
	if ( classId ) then
		ok, label = CharacterCreate_Stage66Call("SetSelectedClass", SetSelectedClass, classId);
		remember(ok, label);
	end
	if ( race ) then
		ok, label = CharacterCreate_Stage66Call("SetCharacterRace", SetCharacterRace, race);
		remember(ok, label);
	end
	if ( classId ) then
		ok, label = CharacterCreate_Stage66Call("SetCharacterClass", SetCharacterClass, classId);
		remember(ok, label);
	end
	ok, label = CharacterCreate_Stage66Call("UpdateCustomizationScene", UpdateCustomizationScene);
	remember(ok, label);
	ok, label = CharacterCreate_Stage66Call("UpdateModel", CharacterCreate_UpdateModel, CharacterCreate);
	remember(ok, label);
	ok, label = CharacterCreate_Stage66Call("PrepPreview", CharCreate_PrepPreviewModels, true);
	remember(ok, label);
	if ( CharCreatePreviewFrame and CharCreatePreviewFrame:IsShown() ) then
		ok, label = CharacterCreate_Stage66Call("DisplayPreview", CharCreate_DisplayPreviewModels);
		remember(ok, label);
	end
	if ( type(GetCharacterCreateFacing) == "function" and type(SetCharacterCreateFacing) == "function" ) then
		ok, label = CharacterCreate_Stage66Call("Facing", SetCharacterCreateFacing, GetCharacterCreateFacing());
		remember(ok, label);
	end
	if ( stepIndex and stepIndex >= 2 ) then
		ok, label = CharacterCreate_Stage66PulseCustomization();
		remember(ok, label);
	end
	CharacterCreate.stage66LastRefreshDetail = "step="..tostring(stepIndex).." mode="..tostring(modeKey).." "..CharacterCreate_JoinProbeList(calls, "无调用", 58);
	return table.getn(calls) > 0;
end

function CharacterCreate_RequestStage66PreviewRefresh(modeKey)
	if ( not CharacterCreate ) then
		return;
	end
	CharacterCreate.stage66RefreshMode = modeKey or "unknown";
	CharacterCreate.stage66RefreshElapsed = 0;
	CharacterCreate.stage66RefreshIndex = 1;
	CharacterCreate.stage66RefreshDelays = { 0.15, 0.70, 1.50 };
	CharacterCreate_AppendDracthyrCreationPreviewStatus("Stage80刷新: 仅T7安排0.15/0.7/1.5秒");
end

function CharacterCreate_ProcessStage66PreviewRefresh(elapsed)
	if ( not CharacterCreate or not CharacterCreate.stage66RefreshIndex ) then
		return;
	end
	local delays = CharacterCreate.stage66RefreshDelays;
	local index = CharacterCreate.stage66RefreshIndex;
	if ( not delays or not delays[index] ) then
		CharacterCreate.stage66RefreshIndex = nil;
		return;
	end
	CharacterCreate.stage66RefreshElapsed = (CharacterCreate.stage66RefreshElapsed or 0) + (elapsed or 0);
	while ( delays[index] and CharacterCreate.stage66RefreshElapsed >= delays[index] ) do
		pcall(CharacterCreate_Stage66RefreshPreviewNow, CharacterCreate.stage66RefreshMode, index);
		index = index + 1;
	end
	if ( delays[index] ) then
		CharacterCreate.stage66RefreshIndex = index;
	else
		local detail = CharacterCreate.stage66LastRefreshDetail or "完成";
		CharacterCreate.stage66RefreshIndex = nil;
	CharacterCreate_AppendDracthyrCreationPreviewStatus("Stage80刷新完成: "..strsub(detail, 1, 62));
	end
end

function CharacterCreate_TryDracthyrPreviewGearType(gearType)
	local candidates = {
		"SetSelectedPreviewGearType",
		"SetPreviewGearType",
		"SetCharacterCreatePreviewGearType",
	};
	for _, name in ipairs(candidates) do
		local fn = _G[name];
		if ( type(fn) == "function" ) then
			local ok, err = pcall(fn, gearType);
			if ( ok ) then
				return true, name;
			end
			return false, name..":"..tostring(err);
		end
	end
	return false, "PreviewGear API缺失";
end

-- Stage18 API probe: inspect CharacterCreate ModelFFX and nearby global glue APIs.
DRACTHYR_CREATION_MODEL_METHOD_CANDIDATES = {
	"GetObjectType", "GetName", "Show", "Hide", "SetPoint", "SetWidth", "SetHeight",
	"TryOn", "Undress", "Dress", "SetAutoDress", "SetItem", "EquipItem",
	"SetEquipment", "SetPreviewItem", "SetItemByID", "UndressSlot",
	"SetUnit", "SetCreature", "SetDisplayInfo", "SetModel", "ClearModel",
	"SetCamera", "SetSequence", "AdvanceTime", "SetLight", "SetFacing",
	"SetRotation", "SetPosition", "SetPortraitZoom", "RefreshCamera",
	"RefreshUnit", "SetCustomRace",
};

DRACTHYR_CREATION_GLOBAL_API_CANDIDATES = {
	"SetSelectedPreviewGearType", "SetPreviewGearType", "SetCharacterCreatePreviewGearType",
	"SetCharacterCreatePreviewEquipment", "SetCharacterCreateEquipmentPreview",
	"SetCharCustomizeFrame", "SetSelectedRace", "SetSelectedClass", "SetCharacterClass",
	"SetSelectedSex", "SetCharacterGender", "UpdateCustomizationScene",
	"CharCreate_PrepPreviewModels", "ResetCharCustomize", "CycleCharCustomization",
};

function CharacterCreate_JoinProbeList(values, emptyText, maxLen)
	if ( not values or #values == 0 ) then
		return emptyText;
	end
	local text = table.concat(values, ",");
	if ( maxLen and strlen(text) > maxLen ) then
		text = strsub(text, 1, maxLen).."...";
	end
	return text;
end

function CharacterCreate_GetProbeModelNames()
	local names = {};
	if ( CharacterCreate ) then
		table.insert(names, "CharacterCreate");
	end
	if ( _G["CharacterCreateModel"] ) then
		table.insert(names, "CharacterCreateModel");
	end
	if ( CharacterCreateFrame and CharacterCreateFrame.Model ) then
		table.insert(names, "Frame.Model");
	end
	if ( CharacterCreateFrame and CharacterCreateFrame.model ) then
		table.insert(names, "Frame.model");
	end
	return names;
end

function CharacterCreate_ProbeMetatableMethods(model)
	local found = {};
	local ok, mt = pcall(getmetatable, model);
	if ( ok and mt and type(mt.__index) == "table" ) then
		for name, value in pairs(mt.__index) do
			if ( type(value) == "function" ) then
				table.insert(found, name);
				if ( #found >= 10 ) then
					break;
				end
			end
		end
	end
	return found;
end

function CharacterCreate_ProbeDracthyrCreationPreviewAPI()
	local modelFound = {};
	local globalFound = {};
	local metaFound = {};
	local models = CharacterCreate_GetDracthyrCreationPreviewModels();

	for _, methodName in ipairs(DRACTHYR_CREATION_MODEL_METHOD_CANDIDATES) do
		for _, model in ipairs(models) do
			if ( model and type(model[methodName]) == "function" ) then
				table.insert(modelFound, methodName);
				break;
			end
		end
	end

	for _, apiName in ipairs(DRACTHYR_CREATION_GLOBAL_API_CANDIDATES) do
		if ( type(_G[apiName]) == "function" ) then
			table.insert(globalFound, apiName);
		end
	end

	for _, model in ipairs(models) do
		local names = CharacterCreate_ProbeMetatableMethods(model);
		for _, name in ipairs(names) do
			table.insert(metaFound, name);
		end
		if ( #metaFound >= 10 ) then
			break;
		end
	end

	local status =
		"模型:"..CharacterCreate_JoinProbeList(modelFound, "无", 58).."|n"..
		"全局:"..CharacterCreate_JoinProbeList(globalFound, "无", 58).."|n"..
		"MT:"..CharacterCreate_JoinProbeList(metaFound, "无/不可读", 58);
	CharacterCreate_SetDracthyrCreationPreviewStatus(status);
	CharacterCreate.dracthyrCreationPreviewLastProbe = status;
	return status;
end

-- Stage19 paged API probe: split API output into short visible pages.
function CharacterCreate_SetProbeStatusLines(title, values, emptyText)
	local line1 = title..":";
	local line2 = CharacterCreate_JoinProbeList(values, emptyText or "无", 74);
	CharacterCreate_SetDracthyrCreationPreviewStatus(line1.."|n"..line2);
end

function CharacterCreate_CollectModelAPIs()
	local modelFound = {};
	local models = CharacterCreate_GetDracthyrCreationPreviewModels();
	for _, methodName in ipairs(DRACTHYR_CREATION_MODEL_METHOD_CANDIDATES) do
		for _, model in ipairs(models) do
			if ( model and type(model[methodName]) == "function" ) then
				table.insert(modelFound, methodName);
				break;
			end
		end
	end
	return modelFound;
end

function CharacterCreate_CollectGlobalAPIs()
	local globalFound = {};
	for _, apiName in ipairs(DRACTHYR_CREATION_GLOBAL_API_CANDIDATES) do
		if ( type(_G[apiName]) == "function" ) then
			table.insert(globalFound, apiName);
		end
	end
	return globalFound;
end

function CharacterCreate_CollectMetatableAPIs()
	local metaFound = {};
	local models = CharacterCreate_GetDracthyrCreationPreviewModels();
	for _, model in ipairs(models) do
		local names = CharacterCreate_ProbeMetatableMethods(model);
		for _, name in ipairs(names) do
			table.insert(metaFound, name);
		end
		if ( #metaFound >= 18 ) then
			break;
		end
	end
	return metaFound;
end

function CharacterCreate_ShowModelAPIProbe()
	local values = CharacterCreate_CollectModelAPIs();
	CharacterCreate_SetProbeStatusLines("模型API", values, "无");
end

function CharacterCreate_GetShortFrameTypeName(frameType)
	return DRACTHYR_CREATION_FRAME_TYPE_SHORT_NAMES[frameType] or frameType;
end

function CharacterCreate_ShortenFrameTypeList(values, emptyText)
	if ( not values or #values == 0 ) then
		return emptyText or "无";
	end
	local shortValues = {};
	for _, frameType in ipairs(values) do
		table.insert(shortValues, CharacterCreate_GetShortFrameTypeName(frameType));
	end
	return CharacterCreate_JoinProbeList(shortValues, emptyText or "无", 70);
end

function CharacterCreate_FormatTypeProbeList(values, emptyText)
	return CharacterCreate_ShortenFrameTypeList(values, emptyText);
end

function CharacterCreate_IsNativeDressupFrameType(frameType)
	return frameType == "DressUpModel" or frameType == "PlayerModel" or frameType == "TabardModel";
end

function CharacterCreate_TryAutoRegisterDressupTypes(silent)
	local fn = _G["R27_NoEquipmentCommand"] or _G["R27_RegisterDressupTypes"];
	if ( type(fn) ~= "function" ) then
		if ( not silent ) then
			CharacterCreate_SetDracthyrCreationPreviewStatus("注册DUM失败: 桥函数缺失");
		end
		return false, "桥函数缺失";
	end
	local ok, err = pcall(fn, "REGISTER_DRESSUP_TYPES", "stage57_auto");
	if ( ok ) then
		if ( CharacterCreate ) then
			CharacterCreate.r27DressupTypesRegisterRequested = true;
		end
		return true, "注册已请求";
	end
	if ( not silent ) then
		CharacterCreate_SetDracthyrCreationPreviewStatus("注册DUM失败|n"..strsub(tostring(err), 1, 74));
	end
	return false, strsub(tostring(err), 1, 74);
end

function CharacterCreate_ProbeGlueCreateFrameTypes()
	local okTypes = {};
	local failTypes = {};
	if ( type(CreateFrame) ~= "function" ) then
		table.insert(failTypes, "CreateFrame缺失");
		return okTypes, failTypes;
	end
	local candidates = DRACTHYR_CREATION_FRAME_TYPE_CANDIDATES or {};
	local parent = CharacterCreateFrame or GlueParent or CharacterCreate;
	for _, frameType in ipairs(candidates) do
		local probeName = "R27GlueFrameTypeProbe"..frameType;
		local frame = _G[probeName];
		if ( frame ) then
			table.insert(okTypes, frameType);
			if ( type(frame.Hide) == "function" ) then
				pcall(frame.Hide, frame);
			end
		else
			local ok, frameOrError = pcall(CreateFrame, frameType, probeName, parent);
			if ( ok and frameOrError ) then
				table.insert(okTypes, frameType);
				if ( type(frameOrError.SetWidth) == "function" ) then
					pcall(frameOrError.SetWidth, frameOrError, 4);
				end
				if ( type(frameOrError.SetHeight) == "function" ) then
					pcall(frameOrError.SetHeight, frameOrError, 4);
				end
				if ( type(frameOrError.SetPoint) == "function" ) then
					pcall(frameOrError.SetPoint, frameOrError, "CENTER", parent or GlueParent, "CENTER", 0, 0);
				end
				if ( type(frameOrError.Hide) == "function" ) then
					pcall(frameOrError.Hide, frameOrError);
				end
			else
				table.insert(failTypes, frameType);
			end
		end
	end
	return okTypes, failTypes;
end

function CharacterCreate_SafeProbeGlueCreateFrameTypes()
	if ( type(CharacterCreate_ProbeGlueCreateFrameTypes) ~= "function" ) then
		return {}, { "类型探针缺失" };
	end
	local ok, okTypes, failTypes = pcall(CharacterCreate_ProbeGlueCreateFrameTypes);
	if ( ok ) then
		return okTypes or {}, failTypes or {};
	end
	return {}, { "类型探针异常" };
end

function CharacterCreate_GetOrCreateDynamicProbeModel(frameType)
	if ( type(CreateFrame) ~= "function" ) then
		return nil, "CreateFrame缺失";
	end
	local name = "R27DynamicProbe"..frameType;
	if ( _G[name] ) then
		return _G[name], nil;
	end
	local parent = CharacterCreateFrame or GlueParent or CharacterCreate;
	local ok, model = pcall(CreateFrame, frameType, name, parent);
	if ( not ok or not model ) then
		if ( CharacterCreate_IsNativeDressupFrameType(frameType) and ( not CharacterCreate or not CharacterCreate.r27DynamicProbeAutoRegisterRetrying ) ) then
			if ( CharacterCreate ) then
				CharacterCreate.r27DynamicProbeAutoRegisterRetrying = true;
			end
			local regOk, regInfo = CharacterCreate_TryAutoRegisterDressupTypes(true);
			ok, model = pcall(CreateFrame, frameType, name, parent);
			if ( CharacterCreate ) then
				CharacterCreate.r27DynamicProbeAutoRegisterRetrying = nil;
			end
			if ( ok and model ) then
				if ( type(model.SetWidth) == "function" ) then
					pcall(model.SetWidth, model, 8);
				end
				if ( type(model.SetHeight) == "function" ) then
					pcall(model.SetHeight, model, 8);
				end
				if ( type(model.SetPoint) == "function" ) then
					pcall(model.SetPoint, model, "CENTER", parent or GlueParent, "CENTER", 0, 0);
				end
				if ( type(model.Hide) == "function" ) then
					pcall(model.Hide, model);
				end
				return model, nil;
			end
			return nil, strsub("autoReg="..tostring(regOk).." "..tostring(regInfo).." "..tostring(model), 1, 74);
		end
		return nil, strsub(tostring(model), 1, 58);
	end
	if ( type(model.SetWidth) == "function" ) then
		pcall(model.SetWidth, model, 8);
	end
	if ( type(model.SetHeight) == "function" ) then
		pcall(model.SetHeight, model, 8);
	end
	if ( type(model.SetPoint) == "function" ) then
		pcall(model.SetPoint, model, "CENTER", parent or GlueParent, "CENTER", 0, 0);
	end
	if ( type(model.Hide) == "function" ) then
		pcall(model.Hide, model);
	end
	return model, nil;
end

function CharacterCreate_GetSafeObjectType(frame)
	if ( frame and type(frame.GetObjectType) == "function" ) then
		local ok, objectType = pcall(frame.GetObjectType, frame);
		if ( ok and objectType ) then
			return tostring(objectType);
		end
	end
	return "?";
end

function CharacterCreate_CollectMethodsFromObject(frame)
	local found = {};
	if ( not frame ) then
		return found;
	end
	for _, methodName in ipairs(DRACTHYR_CREATION_MODEL_METHOD_CANDIDATES) do
		local ok, value = pcall(function()
			return frame[methodName];
		end);
		if ( ok and type(value) == "function" ) then
			table.insert(found, methodName);
		end
	end
	return found;
end

function CharacterCreate_CollectPreviewModelMethodSummary()
	local values = {};
	for index, model in ipairs(CharacterCreate_GetDracthyrCreationPreviewModels()) do
		local objectType = CharacterCreate_GetSafeObjectType(model);
		local hasUndress = "N";
		local hasTryOn = "N";
		local hasSlot = "N";
		if ( model and type(model.Undress) == "function" ) then
			hasUndress = "Y";
		end
		if ( model and type(model.TryOn) == "function" ) then
			hasTryOn = "Y";
		end
		if ( model and type(model.UndressSlot) == "function" ) then
			hasSlot = "Y";
		end
		table.insert(values, tostring(index)..":"..tostring(objectType).." U"..hasUndress.." T"..hasTryOn.." S"..hasSlot);
	end
	return CharacterCreate_JoinProbeList(values, "无模型", 74);
end


function CharacterCreate_RegisterNativeDressupTypesProbe()
	local regOk, regInfo = CharacterCreate_TryAutoRegisterDressupTypes(true);
	if ( not regOk ) then
		CharacterCreate_SetDracthyrCreationPreviewStatus("注册DUM失败|n"..tostring(regInfo));
		return;
	end
	local okTypes, failTypes = CharacterCreate_SafeProbeGlueCreateFrameTypes();
	CharacterCreate_SetDracthyrCreationPreviewStatus("注册DUM已请求|n类型OK: "..CharacterCreate_FormatTypeProbeList(okTypes, "无").."|n类型NO: "..CharacterCreate_FormatTypeProbeList(failTypes, "无"));
end
function CharacterCreate_ShowDynamicModelMethodProbe()
	if ( not CharacterCreate ) then
		CharacterCreate_SetDracthyrCreationPreviewStatus("动态M失败: CharacterCreate缺失");
		return;
	end
	local page = (CharacterCreate.r27DynamicModelProbePage or 0) + 1;
	if ( page > #DRACTHYR_CREATION_DYNAMIC_MODEL_TYPES ) then
		page = 1;
	end
	CharacterCreate.r27DynamicModelProbePage = page;
	local info = DRACTHYR_CREATION_DYNAMIC_MODEL_TYPES[page];
	local model, err = CharacterCreate_GetOrCreateDynamicProbeModel(info.frameType);
	if ( not model ) then
		CharacterCreate_SetDracthyrCreationPreviewStatus("动态M["..page.."] "..info.shortName.."失败|n"..tostring(err));
		return;
	end
	local objectType = CharacterCreate_GetSafeObjectType(model);
	local methods = CharacterCreate_CollectMethodsFromObject(model);
	CharacterCreate_SetDracthyrCreationPreviewStatus("动态M["..page.."] "..info.shortName.." OK type="..objectType.."|n方法:"..CharacterCreate_JoinProbeList(methods, "无", 72));
end

function CharacterCreate_ShowDressUpModelMethodProbe()
	if ( type(CharacterCreate_GetOrCreateDynamicProbeModel) ~= "function" ) then
		CharacterCreate_SetDracthyrCreationPreviewStatus("DUM失败: 动态M入口缺失");
		return false;
	end
	local regOk, regInfo = CharacterCreate_TryAutoRegisterDressupTypes(true);
	local model, err = CharacterCreate_GetOrCreateDynamicProbeModel("DressUpModel");
	if ( not model ) then
		local okTypes, failTypes = CharacterCreate_SafeProbeGlueCreateFrameTypes();
		CharacterCreate_SetDracthyrCreationPreviewStatus("DUM失败 autoReg="..tostring(regOk).."|n"..tostring(err).." OK:"..CharacterCreate_FormatTypeProbeList(okTypes, "无").." NO:"..CharacterCreate_FormatTypeProbeList(failTypes, "无"));
		return false;
	end
	local objectType = CharacterCreate_GetSafeObjectType(model);
	local keyNames = { "Undress", "Dress", "TryOn", "SetUnit", "SetCreature", "RefreshUnit", "SetModel", "ClearModel" };
	local keyMethods = {};
	for _, methodName in ipairs(keyNames) do
		local ok, value = pcall(function() return model[methodName]; end);
		if ( ok and type(value) == "function" ) then
			table.insert(keyMethods, methodName.."=Y");
		else
			table.insert(keyMethods, methodName.."=N");
		end
	end
	local methods = CharacterCreate_CollectMethodsFromObject(model);
	CharacterCreate_SetDracthyrCreationPreviewStatus("DUM type="..objectType.." autoReg="..tostring(regOk).."|n关键:"..CharacterCreate_JoinProbeList(keyMethods, "无", 72).."|n方法:"..CharacterCreate_JoinProbeList(methods, "无", 72));
	return true;
end

function CharacterCreate_Stage54AddProbeCandidate(list, seen, objectValue, objectName)
	if ( objectValue and not seen[objectValue] ) then
		seen[objectValue] = true;
		table.insert(list, { object = objectValue, name = objectName or tostring(objectValue) });
	end
end

function CharacterCreate_Stage54RankProbeCandidate(entry)
	local objectValue = entry and entry.object;
	if ( not objectValue ) then
		return -1, "?";
	end
	local objectType = CharacterCreate_GetSafeObjectType(objectValue);
	local rank = 0;
	if ( objectType and strfind(objectType, "Model") ) then
		rank = rank + 50;
	end
	if ( type(objectValue.Undress) == "function" ) then
		rank = rank + 30;
	end
	if ( type(objectValue.Dress) == "function" ) then
		rank = rank + 20;
	end
	if ( type(objectValue.TryOn) == "function" ) then
		rank = rank + 10;
	end
	if ( entry.name and strfind(entry.name, "DressUp") ) then
		rank = rank + 5;
	end
	return rank, objectType or "?";
end

function CharacterCreate_Stage54FindNativeProbeModel()
	local list = {};
	local seen = {};
	CharacterCreate_Stage54AddProbeCandidate(list, seen, CharacterCreate, "CharacterCreate");
	CharacterCreate_Stage54AddProbeCandidate(list, seen, _G["CharacterCreate"], "_G.CharacterCreate");
	CharacterCreate_Stage54AddProbeCandidate(list, seen, _G["CharacterCreateModel"], "CharacterCreateModel");
	CharacterCreate_Stage54AddProbeCandidate(list, seen, _G["CharCreateModel"], "CharCreateModel");
	CharacterCreate_Stage54AddProbeCandidate(list, seen, _G["CharCreatePreviewModel"], "CharCreatePreviewModel");
	CharacterCreate_Stage54AddProbeCandidate(list, seen, _G["R27DynamicProbeDressUpModel"], "R27DynamicProbeDressUpModel");
	CharacterCreate_Stage54AddProbeCandidate(list, seen, _G["R27DynamicProbePlayerModel"], "R27DynamicProbePlayerModel");
	CharacterCreate_Stage54AddProbeCandidate(list, seen, _G["R27DynamicProbeModel"], "R27DynamicProbeModel");
	if ( CharacterCreateFrame ) then
		CharacterCreate_Stage54AddProbeCandidate(list, seen, CharacterCreateFrame.Model, "CharacterCreateFrame.Model");
		CharacterCreate_Stage54AddProbeCandidate(list, seen, CharacterCreateFrame.model, "CharacterCreateFrame.model");
		if ( type(CharacterCreateFrame.GetChildren) == "function" ) then
			local ok, children = pcall(function() return { CharacterCreateFrame:GetChildren() }; end);
			if ( ok and children ) then
				for i, child in ipairs(children) do
					CharacterCreate_Stage54AddProbeCandidate(list, seen, child, "CharacterCreateFrame.child"..i);
				end
			end
		end
	end
	if ( type(CreateFrame) == "function" ) then
		local parent = CharacterCreateFrame or GlueParent or CharacterCreate;
		local createTypes = { "DressUpModel", "PlayerModel", "Model", "ModelFFX" };
		for _, frameType in ipairs(createTypes) do
			local probeName = "R27Stage54ArgProbe"..frameType;
			local existing = _G[probeName];
			if ( existing ) then
				CharacterCreate_Stage54AddProbeCandidate(list, seen, existing, probeName);
			else
				local ok, created = pcall(CreateFrame, frameType, probeName, parent);
				if ( ok and created ) then
					if ( type(created.SetWidth) == "function" ) then pcall(created.SetWidth, created, 8); end
					if ( type(created.SetHeight) == "function" ) then pcall(created.SetHeight, created, 8); end
					if ( type(created.Hide) == "function" ) then pcall(created.Hide, created); end
					CharacterCreate_Stage54AddProbeCandidate(list, seen, created, probeName);
				end
			end
		end
	end
	local bestEntry = nil;
	local bestRank = -1;
	local bestType = "?";
	for _, entry in ipairs(list) do
		local rank, objectType = CharacterCreate_Stage54RankProbeCandidate(entry);
		if ( rank > bestRank ) then
			bestEntry = entry;
			bestRank = rank;
			bestType = objectType;
		end
	end
	if ( bestEntry ) then
		return bestEntry.object, bestEntry.name, bestType, bestRank;
	end
	return nil, "none", "?", 0;
end

function CharacterCreate_ShowNativeMethodAddressProbe()
	local fn = _G["R27_NativeMethodAddressProbe"];
	if ( type(fn) ~= "function" ) then
		CharacterCreate_SetDracthyrCreationPreviewStatus("对象栈探针失败: R27_NativeMethodAddressProbe缺失");
		return false;
	end
	local objectValue, objectName, objectType, objectRank = CharacterCreate_Stage54FindNativeProbeModel();
	local objectText = tostring(objectValue);
	local ok, err = pcall(fn, "STAGE54_OBJECT_LAYOUT_PROBE", objectName or "none", objectValue, objectType or "?", objectText, CharacterCreate, tostring(CharacterCreate));
	if ( ok ) then
		CharacterCreate_SetDracthyrCreationPreviewStatus("原生地址已请求|nStage54对象栈: "..tostring(objectName).." type="..tostring(objectType).." rank="..tostring(objectRank));
		return true;
	end
	CharacterCreate_SetDracthyrCreationPreviewStatus("原生地址失败: "..tostring(err));
	return false;
end
function CharacterCreate_ShowGlueCreateFrameTypeProbe()
	local okTypes, failTypes = CharacterCreate_SafeProbeGlueCreateFrameTypes();
	local okText = CharacterCreate_ShortenFrameTypeList(okTypes, "无");
	local failText = CharacterCreate_ShortenFrameTypeList(failTypes, "无");
	CharacterCreate_SetDracthyrCreationPreviewStatus("类型OK: "..okText.."|n类型NO: "..failText);
end

function CharacterCreate_ShowGlobalAPIProbe()
	local values = CharacterCreate_CollectGlobalAPIs();
	CharacterCreate_SetProbeStatusLines("全局API", values, "无");
end

function CharacterCreate_ShowMetatableAPIProbe()
	local values = CharacterCreate_CollectMetatableAPIs();
	CharacterCreate_SetProbeStatusLines("元表API", values, "无/不可读");
end

function CharacterCreate_CancelStage66PreviewRefresh()
	if ( not CharacterCreate ) then
		return;
	end
	CharacterCreate.stage66RefreshIndex = nil;
	CharacterCreate.stage66RefreshDelays = nil;
	CharacterCreate.stage66RefreshElapsed = nil;
end

function CharacterCreate_ReapplyStage80ModeNow(reason)
	if ( not CharacterCreate ) then
		return false;
	end
	local mode = CharacterCreate.dracthyrCreationPreviewMode;
	if ( mode ~= "none" and mode ~= "t14" ) then
		return false;
	end
	if ( CharacterCreate.stage80ImmediateReapplyBusy ) then
		return false;
	end
	CharacterCreate.stage80ImmediateReapplyBusy = true;
	local ok = CharacterCreate_Stage80SendPreviewBridge(mode, true);
	CharacterCreate.stage80ImmediateReapplyBusy = nil;
	return ok;
end

function CharacterCreate_ApplyDracthyrCreationDefaultPreview()
	local dispatched = CharacterCreate_Stage80SendPreviewBridge("default", true);
	CharacterCreate_SetDracthyrCreationPreviewStatus("当前：T7装备");
	if ( not dispatched ) then
		CharacterCreate_SetDracthyrCreationPreviewStatus("当前：T7装备|n预览桥未发送成功，请重试");
	end
	return dispatched;
end

function CharacterCreate_ApplyDracthyrCreationNoGearPreview()
	CharacterCreate_CancelStage66PreviewRefresh();
	CharacterCreate_SetDracthyrCreationPreviewStatus("当前：NO装备");
	local dispatched = CharacterCreate_Stage80SendPreviewBridge("none", true);
	if ( not dispatched ) then
		CharacterCreate_SetDracthyrCreationPreviewStatus("当前：NO装备|n预览桥未发送成功，请重试");
	end
	return dispatched;
end

function CharacterCreate_ApplyDracthyrCreationT14Preview()
	CharacterCreate_CancelStage66PreviewRefresh();
	CharacterCreate_SetDracthyrCreationPreviewStatus("当前：T14装备");
	local dispatched = CharacterCreate_Stage80SendPreviewBridge("t14", true);
	if ( not dispatched ) then
		CharacterCreate_SetDracthyrCreationPreviewStatus("当前：T14装备|n预览桥未发送成功，请重试");
	end
	return dispatched;
end

function CharacterCreate_CallDracthyrCreationPreviewHandler(label, functionName, fallbackFunctionName)
	local fn = _G[functionName];
	local usedFunctionName = functionName;
	if ( type(fn) ~= "function" and fallbackFunctionName ) then
		fn = _G[fallbackFunctionName];
		usedFunctionName = fallbackFunctionName;
	end
	if ( type(fn) ~= "function" ) then
		CharacterCreate_SetDracthyrCreationPreviewStatus(tostring(label or "按钮").."入口缺失|n"..tostring(functionName));
		return false;
	end
	local ok, result = pcall(fn);
	if ( not ok ) then
		CharacterCreate_SetDracthyrCreationPreviewStatus(tostring(label or "按钮").."执行失败|n"..strsub(tostring(result), 1, 74));
		return false;
	end
	if ( usedFunctionName ~= functionName ) then
		CharacterCreate_AppendDracthyrCreationPreviewStatus(tostring(label or "按钮").."入口缺失，已改用等价探针");
	end
	return result;
end

function CharacterCreate_SetDracthyrCreationPreviewMode(key, playSound)
	local classId = CharacterCreate_GetDracthyrCreationPreviewClass() or 1;
	-- Explicit clicks must retry after race/sex/model changes.

	if ( playSound ) then
		PlaySound("igMainMenuOptionCheckBoxOn");
	end
	CharacterCreate.dracthyrCreationPreviewMode = key;
	local applied = false;
	if ( key == "default" ) then
		applied = CharacterCreate_CallDracthyrCreationPreviewHandler("T7装备", "CharacterCreate_ApplyDracthyrCreationDefaultPreview");
	elseif ( key == "t14" ) then
		applied = CharacterCreate_CallDracthyrCreationPreviewHandler("T14装备", "CharacterCreate_ApplyDracthyrCreationT14Preview");
	elseif ( key == "none" ) then
		applied = CharacterCreate_CallDracthyrCreationPreviewHandler("NO装备", "CharacterCreate_ApplyDracthyrCreationNoGearPreview");
	end
	if ( applied ) then
		CharacterCreate.stage89AppliedPreviewMode = key;
		CharacterCreate.stage89AppliedPreviewClass = classId;
	end
	CharacterCreate_UpdateDracthyrCreationPreviewButtons();
	return applied;
end

function CharacterCreate_ResetDracthyrCreationPreviewMode()
	CharacterCreate.dracthyrCreationPreviewMode = "default";
	CharacterCreate.dracthyrCreationPreviewStatusText = "当前：T7装备";
	CharacterCreate.stage89AppliedPreviewMode = nil;
	CharacterCreate.stage89AppliedPreviewClass = nil;
end

function CharacterCreate_EnsureDracthyrCreationPreviewButtons()
	if ( DracthyrCreationPreviewFrame ) then
		return;
	end
	if ( not CharCreateCustomizationFrame or not CharCreateCustomizationButton5 ) then
		return;
	end

	local frame = CreateFrame("Frame", "DracthyrCreationPreviewFrame", CharCreateCustomizationFrame);
	frame:SetWidth(286);
	frame:SetHeight(96);
	frame:SetPoint("TOP", CharCreateCustomizationButton5, "BOTTOM", 0, -6);
	frame.buttons = {};

	frame.label = frame:CreateFontString(nil, "OVERLAY", "GlueFontNormalSmall");
	frame.label:SetPoint("TOP", frame, "TOP", 0, 2);
	frame.label:SetWidth(286);
	frame.label:SetJustifyH("CENTER");
	frame.label:SetText("创建装备预览");

	local columns = 2;
	local buttonWidth = 118;
	local buttonHeight = 22;
	local rowGap = 3;
	local leftX = -62;
	local rightX = 62;
	local firstButtonY = -17;

	for index, mode in ipairs(DRACTHYR_CREATION_PREVIEW_MODES) do
		local button = CreateFrame("Button", "DracthyrCreationPreviewButton"..index, frame, "GlueButtonSmallTemplate");
		local row = math.floor((index - 1) / columns);
		local column = index - (row * columns) - 1;
		local xOffset = leftX;
		if ( column == 1 ) then
			xOffset = rightX;
		end
		local yOffset = firstButtonY - (row * (buttonHeight + rowGap));
		button:SetWidth(buttonWidth);
		button:SetHeight(buttonHeight);
		button:SetPoint("TOP", frame, "TOP", xOffset, yOffset);
		button.codexPreviewKey = mode.key;
		button.codexPreviewLabel = mode.label;
		button:SetScript("OnClick", function(self)
			CharacterCreate_SetDracthyrCreationPreviewMode(self.codexPreviewKey, true);
		end);
		frame.buttons[index] = button;
	end

	frame.status = frame:CreateFontString(nil, "OVERLAY", "GlueFontNormalSmall");
	frame.status:SetPoint("TOP", frame, "TOP", 0, -69);
	frame.status:SetWidth(286);
	frame.status:SetJustifyH("CENTER");
	if ( type(frame.status.SetTextColor) == "function" ) then
		frame.status:SetTextColor(1.0, 0.82, 0.0);
	end
	frame.status:SetText("");
	frame:Hide();
end

function CharacterCreate_HideDracthyrCreationPreviewButtons()
	if ( DracthyrCreationPreviewFrame ) then
		DracthyrCreationPreviewFrame:Hide();
	end
end

function CharacterCreate_UpdateDracthyrCreationPreviewButtons()
	CharacterCreate_EnsureDracthyrCreationPreviewButtons();
	if ( not DracthyrCreationPreviewFrame ) then
		return;
	end
	if ( CharacterCreateFrame and CharacterCreateFrame.state == "CUSTOMIZATION" ) then
		DracthyrCreationPreviewFrame:Show();
	else
		DracthyrCreationPreviewFrame:Hide();
	end
	for index, mode in ipairs(DRACTHYR_CREATION_PREVIEW_MODES) do
		local button = DracthyrCreationPreviewFrame.buttons[index];
		if ( button ) then
			if ( CharacterCreate and CharacterCreate.dracthyrCreationPreviewMode == mode.key ) then
				button:SetText("> "..mode.label);
			else
				button:SetText("  "..mode.label);
			end
		end
	end
	CharacterCreate_SetDracthyrCreationPreviewStatus(CharacterCreate.dracthyrCreationPreviewStatusText);
end


function CharacterCreateFrame_OnMouseWheel(delta)
	if ( not delta or delta == 0 ) then
		return;
	end

	if ( type(CharacterCreate_SetWheelZoomLevel) ~= "function" ) then
		return;
	end

	local level = CharacterCreate.r27WheelZoomLevel or 1;
	if ( delta > 0 ) then
		level = math.min(4, level + 1);
	else
		level = math.max(1, level - 1);
	end
	CharacterCreate_SetWheelZoomLevel(level);
end

function CharacterCreate_OnLoad(self)
	self:RegisterEvent("RANDOM_CHARACTER_NAME_RESULT");
	self:RegisterEvent("GLUE_UPDATE_EXPANSION_LEVEL");

	self:SetSequence(0);
	self:SetCamera(0);
	CharacterCreate_PositionStageI4GenderButtons();
	if ( CharacterCreateFrame and CharacterCreateFrame.EnableMouseWheel and CharacterCreateFrame.SetScript ) then
		CharacterCreateFrame:EnableMouseWheel(true);
		CharacterCreateFrame:SetScript("OnMouseWheel", function(_, delta)
			CharacterCreateFrame_OnMouseWheel(delta);
		end);
	end

	CharacterCreate.numRaces = 0;
	CharacterCreate.selectedRace = 0;
	CharacterCreate.numClasses = 0;
	CharacterCreate.selectedClass = 0;
	CharacterCreate.selectedGender = 0;

	SetCharCustomizeFrame("CharacterCreate");

	for i=1, NUM_CHAR_CUSTOMIZATIONS, 1 do
		local button = _G["CharCreateCustomizationButton"..i];
		if ( button and button.text ) then
			button.text:SetText(_G["CHAR_CUSTOMIZATION"..i.."_DESC"]);
		end
	end

	-- Color edit box backdrop
	local backdropColor = FACTION_BACKDROP_COLOR_TABLE["Alliance"];
	-- The name field may be registered one frame after its parent.  Its styling
	-- is optional; never abort the rest of character-create initialization.
	if ( CharacterCreateNameEdit and backdropColor ) then
		CharacterCreateNameEdit:SetBackdropBorderColor(backdropColor[1], backdropColor[2], backdropColor[3]);
		CharacterCreateNameEdit:SetBackdropColor(backdropColor[4], backdropColor[5], backdropColor[6]);
	end
	--[[CharacterCreateNameEdit:SetParent(CharacterCreateFrame)
	CharacterCreateNameEdit:SetPoint("TOPLEFT", CharacterCreateFrame, 635, -30)]]--
	if ( CharCreateCustomizationFrame ) then
		CharCreateCustomizationFrame:SetPoint("RIGHT", CharacterCreateFrame, -50, -10)
	end

	CharacterCreateFrame.state = "CLASSRACE";

	CharCreatePreviewFrame.previews = { };
	CharacterCreate_ResetDracthyrCreationPreviewMode();
	CharacterCreate_EnsureDracthyrCreationPreviewButtons();
	CharacterCreate_UpdateDracthyrCreationPreviewButtons();

	CustomizationBG = CharacterCreateFrame:CreateTexture("CustomizationBG", "BACKGROUND")
	CustomizationBG:SetSize(-5, GlueParent:GetHeight())
    CustomizationBG:SetTexture("Interface\\Glues\\CharacterCreate\\Shadowv")
    CustomizationBG:SetPoint("RIGHT")
    CustomizationBG:Hide()

	CustomizationBG2 = CharacterCreateFrame:CreateTexture("CustomizationBG2", "BACKGROUND")
	CustomizationBG2:SetSize(-5, GlueParent:GetHeight())
    CustomizationBG2:SetTexture("Interface\\Glues\\CharacterCreate\\MainShadow")
    CustomizationBG2:SetPoint("CENTER")
    CustomizationBG2:SetAlpha(1)

	CustomizationLogoAlliance = CharacterCreateFrame:CreateTexture("CustomizationLogoAlliance", "ARTWORK")
	CustomizationLogoAlliance:SetSize(100, 100)
    CustomizationLogoAlliance:SetTexture("Interface\\Glues\\CharacterCreate\\AllianceLogo")
    CustomizationLogoAlliance:SetPoint("TOPLEFT", -16, 16)

	CustomizationTextAlliance = CharacterCreateFrame:CreateFontString("CustomizationTextAlliance", "OVERLAY")
    CustomizationTextAlliance:SetFontObject(GlueFontNormal)
    CustomizationTextAlliance:SetFont("Fonts\\FRIZQT__.TTF", 16)
    CustomizationTextAlliance:SetText(string.upper(ALLIANCE))
    CustomizationTextAlliance:SetPoint("LEFT", CustomizationLogoAlliance, "RIGHT", -24, 0)

	CustomizationLogoHorde = CharacterCreateFrame:CreateTexture("CustomizationLogoHorde", "ARTWORK")
	CustomizationLogoHorde:SetSize(100, 100)
    CustomizationLogoHorde:SetTexture("Interface\\Glues\\CharacterCreate\\HordeLogo")
    CustomizationLogoHorde:SetPoint("TOPRIGHT", 16, 16)

	CustomizationTextHorde = CharacterCreateFrame:CreateFontString("CustomizationTextHorde", "OVERLAY")
    CustomizationTextHorde:SetFontObject(GlueFontNormal)
    CustomizationTextHorde:SetFont("Fonts\\FRIZQT__.TTF", 16)
    CustomizationTextHorde:SetText(string.upper(HORDE))
    CustomizationTextHorde:SetPoint("RIGHT", CustomizationLogoHorde, "LEFT", 24, 0)


end

function CharCustomizeButtonClick(id, button)
	if (button == 'LeftButton') then
		CharacterCustomization_Left(id)
	elseif (button == 'RightButton') then
		CharacterCustomization_Right(id)
	end
	-- CycleCharCustomization(id, 1);
	--[[FeatureType = id
	for i=1,5 do
		_G["CharCreateCustomizationButton"..i]:SetChecked(0);
	end
	_G["CharCreateCustomizationButton"..id]:SetChecked(1);]]

end


function CharacterCreate_UpdateExtraRaceIndices(...)
	local nagaIndex = nil;
	local nagaName = nil;
	local dracthyrIndex = nil;
	local dracthyrName = nil;
	for i=1, select("#", ...), 3 do
		local listIndex = (i + 2) / 3;
		local name = select(i, ...);
		local fileName = select(i + 1, ...);
		local upperFileName = fileName and strupper(fileName) or "";
		if ( upperFileName == "NAGA_" or upperFileName == "NAGA" ) then
			nagaIndex = listIndex;
			nagaName = name;
		elseif ( upperFileName == "DRACTHYR_" or upperFileName == "DRACTHYR" or string.find(upperFileName, "DRACTHYR") or name == "龙希尔" or name == "Dracthyr" ) then
			dracthyrIndex = listIndex;
			dracthyrName = name;
		end
	end
	if ( nagaIndex ) then
		EXTRA_RACE_NAGA_INDEX = nagaIndex;
		EXTRA_RACE_NAGA_NAME = nagaName or "Naga";
	end
	if ( dracthyrIndex ) then
		EXTRA_RACE_DRACTHYR_INDEX = dracthyrIndex;
		EXTRA_RACE_DRACTHYR_NAME = dracthyrName or EXTRA_RACE_DRACTHYR_NAME or "Dracthyr";
	end
end

function CharacterCreate_BuildNagaTooltip()
	local name = EXTRA_RACE_NAGA_NAME or "Naga";
	local text = GetFlavorText("RACE_INFO_NAGA_CUSTOM", GetSelectedSex());
	if ( not text ) then
		text = _G["RACE_INFO_NAGA_CUSTOM"] or "";
	end

	local abilityIndex = 1;
	local tempText = _G["ABILITY_INFO_NAGA_CUSTOM"..abilityIndex];
	local abilityText = "";
	while ( tempText ) do
		abilityText = abilityText..tempText.."\n\n";
		abilityIndex = abilityIndex + 1;
		tempText = _G["ABILITY_INFO_NAGA_CUSTOM"..abilityIndex];
	end

	local tooltip = "|cffFFFFFF" .. name .. "|r";
	if ( text and text ~= "" ) then
		tooltip = tooltip .. "\n\n|r" .. text;
	end
	if ( abilityText and abilityText ~= "" ) then
		tooltip = tooltip .. "\n\n|cffFFFFFF" .. abilityText;
	end
	return tooltip;
end

function CharacterCreate_BuildDracthyrTooltip()
	local name = EXTRA_RACE_DRACTHYR_NAME or "Dracthyr";
	local text = GetFlavorText("RACE_INFO_DRACTHYR_CUSTOM", GetSelectedSex());
	if ( not text ) then
		text = _G["RACE_INFO_DRACTHYR_CUSTOM"] or "";
	end

	local abilityIndex = 1;
	local tempText = _G["ABILITY_INFO_DRACTHYR_CUSTOM"..abilityIndex];
	local abilityText = "";
	while ( tempText ) do
		abilityText = abilityText..tempText.."\n\n";
		abilityIndex = abilityIndex + 1;
		tempText = _G["ABILITY_INFO_DRACTHYR_CUSTOM"..abilityIndex];
	end

	local tooltip = "|cffFFFFFF" .. name .. "|r";
	if ( text and text ~= "" ) then
		tooltip = tooltip .. "\n\n|r" .. text;
	end
	if ( abilityText and abilityText ~= "" ) then
		tooltip = tooltip .. "\n\n|cffFFFFFF" .. abilityText;
	end
	return tooltip;
end

function CharacterCreate_GetNagaPortraitTexCoords()
	if ( GetSelectedSex() == SEX_MALE ) then
		return 0.375, 0.5, 0.75, 0.875;
	end
	return 0.5, 0.625, 0.75, 0.875;
end

function CharacterCreate_SetNagaPortrait(button)
	local texture = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Races2";
	local left, right, top, bottom = CharacterCreate_GetNagaPortraitTexCoords();
	local normalTexture = _G[button:GetName().."NormalTexture"];
	local pushedTexture = _G[button:GetName().."PushedTexture"];

	if ( normalTexture ) then
		normalTexture:SetTexture(texture);
		normalTexture:SetTexCoord(left, right, top, bottom);
	end
	if ( pushedTexture ) then
		pushedTexture:SetTexture(texture);
		pushedTexture:SetTexCoord(left, right, top, bottom);
	end
end

function CharacterCreate_EnsureCustomRaceButton(index)
	local buttonName = "CustomCharCreateRaceButton"..index;
	local button = _G[buttonName];
	-- Custom buttons are also XML-owned on this client.  Returning nil is
	-- safer than asking stable99 to dynamically create an unsupported type.
	return button;
end

function CharacterCreate_GetDracthyrPortraitTexture()
	if ( GetSelectedSex() == SEX_MALE ) then
		return "Interface\\Icons\\INV_DracthyrHead02_Round";
	end
	return "Interface\\Icons\\INV_DracthyrHead01_Round";
end

function CharacterCreate_SetDracthyrPortrait(button)
	local texture = CharacterCreate_GetDracthyrPortraitTexture();
	local normalTexture = _G[button:GetName().."NormalTexture"];
	local pushedTexture = _G[button:GetName().."PushedTexture"];

	if ( normalTexture ) then
		normalTexture:SetTexture(texture);
		normalTexture:SetBlendMode("BLEND");
		normalTexture:SetTexCoord(0, 1, 0, 1);
	end
	if ( pushedTexture ) then
		pushedTexture:SetTexture(texture);
		pushedTexture:SetBlendMode("BLEND");
		pushedTexture:SetTexCoord(0, 1, 0, 1);
	end
end

function CharacterCreate_IsExtraRaceId(raceId)
	return raceId == EXTRA_RACE_NAGA_INDEX or raceId == EXTRA_RACE_DRACTHYR_INDEX;
end

function CharacterCreate_GetExtraRaceKeyForRaceId(raceId)
	if ( raceId == EXTRA_RACE_NAGA_INDEX ) then
		return EXTRA_RACE_NAGA_KEY;
	elseif ( raceId == EXTRA_RACE_DRACTHYR_INDEX ) then
		return EXTRA_RACE_DRACTHYR_KEY;
	end
	return nil;
end

function CharacterCreate_GetActiveRaceForButtons()
	if ( CharacterCreate.extraRaceButtonSelection ) then
		return CharacterCreate.extraRaceButtonSelection;
	end
	local customKey = CharacterCreate_GetExtraRaceKeyForRaceId(CharacterCreate.customSelectedRace);
	if ( customKey ) then
		return customKey;
	end
	local selectedKey = CharacterCreate_GetExtraRaceKeyForRaceId(CharacterCreate.selectedRace);
	if ( selectedKey ) then
		return selectedKey;
	end
	local currentKey = CharacterCreate_GetExtraRaceKeyForRaceId(GetSelectedRace());
	if ( currentKey ) then
		return currentKey;
	end
	return nil;
end

function CharacterCreate_EnsureExtraRaceSelectedRing(button)
	if ( not button ) then
		return nil;
	end
	if ( not button.codexSelectedRing ) then
		button.codexSelectedRing = button:CreateTexture(nil, "OVERLAY");
		button.codexSelectedRing:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreatePatchwerk_nuevo");
		button.codexSelectedRing:SetBlendMode("ADD");
		button.codexSelectedRing:SetWidth(82);
		button.codexSelectedRing:SetHeight(82);
		button.codexSelectedRing:SetPoint("CENTER", button, "CENTER", 1, -1);
		button.codexSelectedRing:SetTexCoord(0.79296875, 0.95312500, 0.00097656, 0.08105469);
		button.codexSelectedRing:Hide();
	end
	return button.codexSelectedRing;
end

function CharacterCreate_SetExtraRaceButtonChecked(button, checked)
	if ( not button ) then
		return;
	end
	local selectedRing = CharacterCreate_EnsureExtraRaceSelectedRing(button);
	if ( checked ) then
		button:SetChecked(1);
		if ( selectedRing ) then
			selectedRing:Show();
		end
		if ( button.borderfaction ) then
			button.borderfaction:SetAlpha(1);
			if ( button.borderfaction.SetDesaturated ) then
				button.borderfaction:SetDesaturated(false);
			end
		end
	else
		button:SetChecked(0);
		if ( selectedRing ) then
			selectedRing:Hide();
		end
		if ( button.borderfaction ) then
			button.borderfaction:SetAlpha(0.45);
			if ( button.borderfaction.SetDesaturated ) then
				button.borderfaction:SetDesaturated(true);
			end
		end
	end
end

function CharacterCreate_UpdateExtraRaceChecks(selectedRace)
	local raceKey = nil;
	if ( selectedRace == EXTRA_RACE_NAGA_KEY or selectedRace == EXTRA_RACE_DRACTHYR_KEY ) then
		raceKey = selectedRace;
	else
		raceKey = CharacterCreate_GetExtraRaceKeyForRaceId(selectedRace) or CharacterCreate_GetActiveRaceForButtons();
	end
	for i=1, 4 do
		local button = _G["CustomCharCreateRaceButton"..i];
		CharacterCreate_SetExtraRaceButtonChecked(button, false);
	end
	if ( raceKey == EXTRA_RACE_DRACTHYR_KEY and CustomCharCreateRaceButton2 ) then
		CharacterCreate_SetExtraRaceButtonChecked(CustomCharCreateRaceButton2, true);
	elseif ( raceKey == EXTRA_RACE_NAGA_KEY and CustomCharCreateRaceButton1 ) then
		CharacterCreate_SetExtraRaceButtonChecked(CustomCharCreateRaceButton1, true);
	end
end

function CharacterCreate_SetupExtraRaceButtonFrame(button, raceIndex, raceKey, label, tooltip, factionTexture, xOffset)
	button:ClearAllPoints();
	button:SetPoint("TOP", "CharacterCreate", "TOP", xOffset, EXTRA_RACE_TOP_BUTTON_Y);
	button:SetScale(0.78);
	button:SetID(raceIndex);
	CharacterCreate_RegisterSafeRaceId(raceIndex, false);
	button:SetFrameStrata("HIGH");
	if ( CharCreateRaceButtonsFrame and button.SetFrameLevel ) then
		local frameLevel = CharCreateRaceButtonsFrame:GetFrameLevel() + 20;
		if ( raceIndex == EXTRA_RACE_DRACTHYR_INDEX ) then
			frameLevel = frameLevel + 10;
		end
		button:SetFrameLevel(frameLevel);
	end
	if ( button.SetHitRectInsets ) then
		button:SetHitRectInsets(10, 10, 8, 8);
	end
	if ( button.nameFrame and button.nameFrame.text ) then
		button.nameFrame.text:SetText(label);
		button.nameFrame.text:SetAlpha(1);
	end
	button.codexExtraRaceKey = raceKey;
	button.codexExtraRaceIndex = raceIndex;
	button.tooltip = tooltip;
	button:Enable();
	SetButtonDesaturated(button);
	if ( button.borderfaction ) then
		button.borderfaction:SetTexture(factionTexture);
		button.borderfaction:Show();
	end
	CharacterCreate_EnsureExtraRaceSelectedRing(button);
	CharacterCreate_SetExtraRaceButtonChecked(button, CharacterCreate_GetActiveRaceForButtons() == raceKey);
	button:SetScript("OnClick", function(self) CharacterCreate_SelectExtraRace(self, raceIndex, raceKey); end);
	button:SetScript("OnEnter", function(self)
		if ( self.tooltip ) then
			CharacterCreateTooltip:SetOwner(self, "TOPLEFT", "BOTTOMRIGHT", -8, 0);
			CharacterCreateTooltip:SetText(self.tooltip);
		end
	end);
	button:SetScript("OnLeave", function(self) CharacterCreateTooltip:Hide(); end);
	button:Show();
end

function CharacterCreate_SelectExtraRace(self, raceIndex, raceKey)
	if ( not self:IsEnabled() ) then
		self:SetChecked(0);
		return;
	end
	raceKey = raceKey or CharacterCreate_GetExtraRaceKeyForRaceId(raceIndex);
	PlaySound("gsCharacterCreationClass");
	SetSelectedRace(raceIndex);
	CharacterCreate.selectedRace = raceIndex;
	CharacterCreate.customSelectedRace = raceIndex;
	CharacterCreate.extraRaceButtonSelection = raceKey;
	CharacterCreate_UpdateExtraRaceChecks(raceKey);
	SetCharacterRace(raceIndex);
	SetCharacterCreateFacing(-15);
	CharacterCreateEnumerateClasses(GetAvailableClasses());
	local _,_,classIndex = GetSelectedClass();
	if ( PAID_SERVICE_TYPE ) then
		classIndex = PaidChange_GetCurrentClassIndex();
		SetSelectedClass(classIndex);
	end
	SetCharacterClass(classIndex);
	CharacterCreate_UpdateHairCustomization();
	CharacterChangeFixup();
	CharacterCreate.selectedRace = raceIndex;
	CharacterCreate.customSelectedRace = raceIndex;
	CharacterCreate.extraRaceButtonSelection = raceKey;
	CharacterCreate_SetupExtraRaceButtons();
	CharacterCreate_UpdateExtraRaceChecks(raceKey);
end

function CharacterCreate_SetupExtraRaceButtons()
	local nagaButton = CharacterCreate_EnsureCustomRaceButton(1);
	local dracthyrButton = CharacterCreate_EnsureCustomRaceButton(2);
	if ( not CharacterCreate.backgroundRaceByListId ) then
		CharacterCreate.backgroundRaceByListId = {};
	end

	if ( not nagaButton ) then
		return;
	end

	if ( dracthyrButton ) then
		CharacterCreate_SetupExtraRaceButtonFrame(
			dracthyrButton,
			EXTRA_RACE_DRACTHYR_INDEX,
			EXTRA_RACE_DRACTHYR_KEY,
			EXTRA_RACE_DRACTHYR_NAME or "Dracthyr",
			CharacterCreate_BuildDracthyrTooltip(),
			"Interface\\Glues\\CharacterCreate\\AlliRoundRaceOk",
			EXTRA_RACE_DRACTHYR_BUTTON_X
		);
		CharacterCreate.backgroundRaceByListId[EXTRA_RACE_DRACTHYR_INDEX] = EXTRA_RACE_DRACTHYR_BACKGROUND_RACE;
		CharacterCreate_SetDracthyrPortrait(dracthyrButton);
	end

	CharacterCreate_SetupExtraRaceButtonFrame(
		nagaButton,
		EXTRA_RACE_NAGA_INDEX,
		EXTRA_RACE_NAGA_KEY,
		EXTRA_RACE_NAGA_NAME or "Naga",
		CharacterCreate_BuildNagaTooltip(),
		"Interface\\Glues\\CharacterCreate\\HordeRoundRaceOk",
		EXTRA_RACE_NAGA_BUTTON_X
	);
	CharacterCreate.backgroundRaceByListId[EXTRA_RACE_NAGA_INDEX] = EXTRA_RACE_NAGA_BACKGROUND_RACE;
	CharacterCreate_SetNagaPortrait(nagaButton);

	if ( CustomCharCreateRaceButton2 ) then
		if ( CustomCharCreateRaceButton2 ~= dracthyrButton ) then
			CustomCharCreateRaceButton2:Hide();
		end
	end
	if ( CustomCharCreateRaceButton3 ) then
		CustomCharCreateRaceButton3:Hide();
	end
	if ( CustomCharCreateRaceButton4 ) then
		CustomCharCreateRaceButton4:Hide();
	end
	CharacterCreate_UpdateExtraRaceChecks();
end

-- The old standalone Hero selector bypasses the DBC enumeration path.  Keep it
-- unavailable, but allow numbered class buttons to follow GetAvailableClasses.
function CharacterCreate_HideLegacyHeroClassButton()
	local heroButton = CharCreateClassButtoHero;
	if ( heroButton ) then
		heroButton:SetChecked(0);
		heroButton:Disable();
		heroButton:Hide();
		if ( heroButton.selection ) then
			heroButton.selection:Hide();
		end
	end
end

-- Lay out the enumerated classes in a centered two-row grid.  Button numbers
-- are enumeration indexes; the real class ID continues to come from the DBC.
function CharacterCreate_PositionClassButtons()
	local count = math.min(CharacterCreate.numClasses or 0, MAX_CLASSES_PER_RACE);
	local columns = 12;
	local spacingX = 76;
	local spacingY = 72;
	local visibleButtons = {};

	for i=1, count do
		local button = _G["CharCreateClassButton"..i];
		if ( button and not button.codexIsMonkClass and not button.codexIsWitchDoctorClass ) then
			table.insert(visibleButtons, button);
		end
	end

	for i=1, MAX_CLASSES_PER_RACE do
		local button = _G["CharCreateClassButton"..i];
		if ( button ) then
			button:ClearAllPoints();
		end
	end

	for visibleIndex, button in ipairs(visibleButtons) do
		local row = math.floor((visibleIndex - 1) / columns);
		local first = row * columns + 1;
		local rowCount = math.min(columns, #visibleButtons - first + 1);
		local column = visibleIndex - first;
		local startX = -((rowCount - 1) * spacingX) / 2;
		button:SetPoint("BOTTOM", CharacterCreateFrame, "BOTTOM", startX + column * spacingX, 17 + row * spacingY);
	end
end

function CharacterCreate_OnShow()
	CharacterCreate_PositionStageI4GenderButtons();
	CharacterCreate.witchDoctorClassIndex = nil;
	CharacterCreate.wdEnumeratedEnabled = nil;
	CharacterCreate_ResetMonkButton();
	for i=1, MAX_CLASSES_PER_RACE, 1 do
		local button = _G["CharCreateClassButton"..i];
		if ( button ) then
			button:Enable();
			--button:SetScale(0.8)
			SetButtonDesaturated(button, false)
		end
	end

	for i=1, MAX_RACES, 1 do
		-- The stable99 client can report CheckButton as an unknown dynamic
		-- CreateFrame type on the glue screen.  Race buttons are declared by
		-- CharacterCreate.xml, so never manufacture a missing one here.
		local button = _G["CharCreateRaceButton"..i];
		if ( button ) then
			button:Enable();
			--button:SetScale(0.8)
			SetButtonDesaturated(button, false)
		end
	end

	if ( PAID_SERVICE_TYPE ) then
		CustomizeExistingCharacter( PAID_SERVICE_CHARACTER_ID );
		CharacterCreateNameEdit:SetText( PaidChange_GetName() );
	else
		--randomly selects a combination
		ResetCharCustomize();
		CharacterCreateNameEdit:SetText("");
		CharCreateRandomizeButton:Show();
	end

	CharacterCreateEnumerateRaces(GetAvailableRaces());
	SetCharacterRace(CharacterCreate_EnsureSafeSelectedRace());

	CharacterCreateEnumerateClasses(GetAvailableClasses());
	local_,_,index = GetSelectedClass();
	SetCharacterClass(index);
 
	SetCharacterGender(GetSelectedSex()); 
	CharacterCreate_SetupZoomButtonScripts();
	
	-- Hair customization stuff
	CharacterCreate_UpdateHairCustomization();

	SetCharacterCreateFacing(-15);
	
	if ( ALLOW_RANDOM_NAME_BUTTON ) then
		CharacterCreateRandomName:Hide();
	end
	
	-- setup customization
	CharacterChangeFixup();

	--SetFaceCustomizeCamera(false);
	if(BLIZLIKESERVER == true)then 
		for i=1, MAX_RACES - 1 do 
		local index = i
			if(index == 7 or index == 8 or index == 9 or index == 10 or index == 6 or index == 15 or index == 19 or index == 20 or index == 17 or index == 18)then 
			_G["CharCreateRaceButton"..index]:Hide(); 
			CustomCharCreateRaceButton1:Hide(); 
			CustomCharCreateRaceButton2:Hide(); 
			CustomCharCreateRaceButton3:Hide(); 
			CustomCharCreateRaceButton4:Hide(); 
			end
		end 
		CharCreateClassButton1:SetPoint("BOTTOM", -340, 17);
		CharCreateClassButton2:SetPoint("BOTTOM","CharCreateClassButton1","BOTTOMLEFT", 100, 0);
		CharCreateClassButton3:SetPoint("BOTTOM","CharCreateClassButton2","BOTTOMLEFT", 100, 0);
		CharCreateClassButton4:SetPoint("BOTTOM","CharCreateClassButton3","BOTTOMLEFT", 100, 0);
		CharCreateClassButton5:SetPoint("BOTTOM","CharCreateClassButton4","BOTTOMLEFT", 100, 0);
		CharCreateClassButton7:SetPoint("BOTTOM","CharCreateClassButton5","BOTTOMLEFT", 100, 0);
		CharCreateClassButton8:SetPoint("BOTTOM","CharCreateClassButton7","BOTTOMLEFT", 100, 0);
		CharCreateClassButton9:SetPoint("BOTTOM","CharCreateClassButton8","BOTTOMLEFT", 100, 0);
		CharCreateClassButton10:SetPoint("BOTTOM","CharCreateClassButton9","BOTTOMLEFT", 100, 0);
		CharCreateClassButton11:SetPoint("BOTTOM","CharCreateClassButton6","BOTTOMLEFT", 100, 0);
		CharCreateClassButton6:SetPoint("BOTTOM","CharCreateClassButton10","BOTTOMLEFT", 100, 0);
		
		CharacterCreate_HideLegacyHeroClassButton();
	else 
		CharCreateClassButton1:SetPoint("BOTTOM", -385, 17);
		CharCreateClassButton2:SetPoint("BOTTOM","CharCreateClassButton1","BOTTOMLEFT", 100, 0);
		CharCreateClassButton3:SetPoint("BOTTOM","CharCreateClassButton2","BOTTOMLEFT", 100, 0);
		CharCreateClassButton4:SetPoint("BOTTOM","CharCreateClassButton3","BOTTOMLEFT", 100, 0);
		CharCreateClassButton5:SetPoint("BOTTOM","CharCreateClassButton4","BOTTOMLEFT", 100, 0);
		CharCreateClassButton7:SetPoint("BOTTOM","CharCreateClassButton5","BOTTOMLEFT", 180, 0);
		CharCreateClassButton8:SetPoint("BOTTOM","CharCreateClassButton7","BOTTOMLEFT", 100, 0);
		CharCreateClassButton9:SetPoint("BOTTOM","CharCreateClassButton8","BOTTOMLEFT", 100, 0);
		CharCreateClassButton10:SetPoint("BOTTOM","CharCreateClassButton9","BOTTOMLEFT", 100, 0);
		CharCreateClassButton11:SetPoint("BOTTOM","CharCreateClassButton6","BOTTOMLEFT", 100, 0);
		CharCreateClassButton6:SetPoint("BOTTOM","CharCreateClassButton10","BOTTOMLEFT", 100, 0);
		
		if(ADD_CUSTOM_CLASS_EXTRA == false)then
			CharCreateClassButton1:SetPoint("BOTTOM", -340, 17);
			CharCreateClassButton2:SetPoint("BOTTOM","CharCreateClassButton1","BOTTOMLEFT", 100, 0);
			CharCreateClassButton3:SetPoint("BOTTOM","CharCreateClassButton2","BOTTOMLEFT", 100, 0);
			CharCreateClassButton4:SetPoint("BOTTOM","CharCreateClassButton3","BOTTOMLEFT", 100, 0);
			CharCreateClassButton5:SetPoint("BOTTOM","CharCreateClassButton4","BOTTOMLEFT", 100, 0);
			CharCreateClassButton7:SetPoint("BOTTOM","CharCreateClassButton5","BOTTOMLEFT", 100, 0);
			CharCreateClassButton8:SetPoint("BOTTOM","CharCreateClassButton7","BOTTOMLEFT", 100, 0);
			CharCreateClassButton9:SetPoint("BOTTOM","CharCreateClassButton8","BOTTOMLEFT", 100, 0);
			CharCreateClassButton10:SetPoint("BOTTOM","CharCreateClassButton9","BOTTOMLEFT", 100, 0);
			CharCreateClassButton11:SetPoint("BOTTOM","CharCreateClassButton6","BOTTOMLEFT", 100, 0);
			CharCreateClassButton6:SetPoint("BOTTOM","CharCreateClassButton10","BOTTOMLEFT", 100, 0);
			
			CharacterCreate_HideLegacyHeroClassButton();
		end
		if(CLANDESTINOSERVER == true)then
		 	CharCreateRaceButton8:SetPoint("TOPLEFT","CharCreateRaceButton1","BOTTOMLEFT", 86, 37);
		 	CharCreateRaceButton10:SetPoint("TOPLEFT","CharCreateRaceButton8","BOTTOMLEFT", 0, -20);
		 	CharCreateRaceButton6:SetPoint("TOPLEFT","CharCreateRaceButton10","BOTTOMLEFT", 0, -20);
		 	CharCreateRaceButton7:SetPoint("TOPLEFT","CharCreateRaceButton6","BOTTOMLEFT", 0, -20);
			
		 	CharCreateRaceButton12:SetPoint("TOPRIGHT","CharacterCreateFrame", -32, -75);
		 	CharCreateRaceButton13:SetPoint("TOPLEFT","CharCreateRaceButton12","BOTTOMLEFT", 0, -20);
		 	CharCreateRaceButton14:SetPoint("TOPLEFT","CharCreateRaceButton13","BOTTOMLEFT", 0, -20);
		 	CharCreateRaceButton15:SetPoint("TOPLEFT","CharCreateRaceButton14","BOTTOMLEFT", 0, -20);
		 	CharCreateRaceButton17:SetPoint("TOPLEFT","CharCreateRaceButton15","BOTTOMLEFT", 0, -20);
			
		 	CharCreateRaceButton20:SetPoint("TOPLEFT","CharCreateRaceButton12","BOTTOMLEFT", -86, 37);
		 	CharCreateRaceButton18:SetPoint("TOPLEFT","CharCreateRaceButton20","BOTTOMLEFT", 0, -20);
		 	CharCreateRaceButton19:SetPoint("TOPLEFT","CharCreateRaceButton18","BOTTOMLEFT", 0, -20);
		 	CharCreateRaceButton16:SetPoint("TOPLEFT","CharCreateRaceButton19","BOTTOMLEFT", 0, -20);
			
		 	CharCreateRaceButton11:SetPoint("TOPLEFT","CharCreateRaceButton10","BOTTOMLEFT", 83, 22);
		 	CharCreateRaceButton21:SetPoint("TOPLEFT","CharCreateRaceButton18","BOTTOMLEFT", -83, 22);
		-- 	CharCreateRaceButton9:SetPoint("TOPLEFT","CharCreateRaceButton9","BOTTOMLEFT", -83, 22);
			
			CharCreateRaceButton9:Hide(); 
			CustomCharCreateRaceButton1:Hide(); 
			CustomCharCreateRaceButton2:Hide(); 
			CustomCharCreateRaceButton3:Hide(); 
			CustomCharCreateRaceButton4:Hide(); 
		end
	end
	-- Apply the data-driven grid after legacy layout branches have finished.
	CharacterCreate_PositionClassButtons();
	CharacterCreate_SetupExtraRaceButtons();
	CharacterCreate_StageBUpdateStaticRaceButtons();
	CharacterCreate_HideLegacyHeroClassButton();
end

function CharacterCreate_OnHide()
	PAID_SERVICE_CHARACTER_ID = nil;
	PAID_SERVICE_TYPE = nil;
	if ( CharacterCreateFrame.state == "CUSTOMIZATION" ) then
		CharacterCreate_Back();
	end
	-- character previews will need to be redone if coming back to character create. One reason is all the memory used for
	-- tracking the frames (on the c side) will get released if the user returns to the login screen
	CharCreatePreviewFrame.rebuildPreviews = true;
end

function CharacterCreate_OnEvent(event, arg1, arg2, arg3)
	if ( event == "RANDOM_CHARACTER_NAME_RESULT" ) then
		if ( arg1 == 0 ) then
			-- Failed.  Generate a random name locally.
			CharacterCreateNameEdit:SetText(GenerateRandomName());
		else
			-- Succeeded.  Use what the server sent.
			CharacterCreateNameEdit:SetText(arg2);
		end
		CharacterCreateRandomName:Enable();
		CharCreateOkayButton:Enable();
		PlaySound("gsCharacterCreationLook");
	elseif ( event == "GLUE_UPDATE_EXPANSION_LEVEL" ) then
		-- Expansion level changed while online, so enable buttons as needed
		if ( CharacterCreateFrame:IsShown() ) then
			CharacterCreateEnumerateRaces(GetAvailableRaces());
			CharacterCreateEnumerateClasses(GetAvailableClasses());
		end
	end
end

function CharacterCreateFrame_OnMouseDown(button)
	if ( button == "LeftButton" ) then
		CHARACTER_CREATE_ROTATION_START_X = GetCursorPosition();
		CHARACTER_CREATE_INITIAL_FACING = GetCharacterCreateFacing();
	end
end

function CharacterCreateFrame_OnMouseUp(button)
	if ( button == "LeftButton" ) then
		CHARACTER_CREATE_ROTATION_START_X = nil
	end
end

function CharacterCreateFrame_OnUpdate(self, elapsed)
	if ( type(CharacterCreate_ProcessStage66PreviewRefresh) == "function" ) then
		CharacterCreate_ProcessStage66PreviewRefresh(elapsed);
	end
	if ( CHARACTER_CREATE_ROTATION_START_X ) then
		local x = GetCursorPosition();
		local diff = (x - CHARACTER_CREATE_ROTATION_START_X) * CHARACTER_ROTATION_CONSTANT;
		CHARACTER_CREATE_ROTATION_START_X = GetCursorPosition();
		SetCharacterCreateFacing(GetCharacterCreateFacing() + diff);
		CharCreate_RotatePreviews();
	end
	CharacterCreateWhileMouseDown_Update(elapsed);
end

function CharacterCreate_StripRaceColor(name)
	if ( not name ) then
		return "";
	end
	local cleanName = string.gsub(name, "|c%x%x%x%x%x%x%x%x", "");
	cleanName = string.gsub(cleanName, "|r", "");
	return cleanName;
end

function CharacterCreate_RaceNameMatches(entryName, targetName)
	if ( not entryName or not targetName ) then
		return false;
	end
	if ( entryName == targetName ) then
		return true;
	end
	if ( string.find(targetName, "|", 1, true) ) then
		return false;
	end
	return CharacterCreate_StripRaceColor(entryName) == targetName;
end

function CharacterCreate_FindRaceEntryByNameOnly(raceEntries, ...)
	for nameIndex=1, select("#", ...), 1 do
		local targetName = select(nameIndex, ...);
		for _, entry in ipairs(raceEntries) do
			if ( CharacterCreate_RaceNameMatches(entry.name, targetName) ) then
				return entry;
			end
		end
	end
	return nil;
end

function CharacterCreate_FindRaceEntryByNameOnlyByFaction(raceEntries, expectedFaction, ...)
	for nameIndex=1, select("#", ...), 1 do
		local targetName = select(nameIndex, ...);
		for _, entry in ipairs(raceEntries) do
			if ( CharacterCreate_RaceNameMatches(entry.name, targetName) ) then
				local _, entryFaction = GetFactionForRace(entry.listIndex);
				if ( entryFaction == expectedFaction ) then
					return entry;
				end
			end
		end
	end
	return CharacterCreate_FindRaceEntryByNameOnly(raceEntries, ...);
end

function CharacterCreate_FindRaceEntry(raceEntries, fileName, ...)
	for nameIndex=1, select("#", ...), 1 do
		local targetName = select(nameIndex, ...);
		for _, entry in ipairs(raceEntries) do
			if ( CharacterCreate_RaceNameMatches(entry.name, targetName) ) then
				return entry;
			end
		end
	end

	if ( fileName ) then
		local wantedFileName = strupper(fileName);
		for _, entry in ipairs(raceEntries) do
			if ( strupper(entry.fileName or "") == wantedFileName ) then
				return entry;
			end
		end
	end
	return nil;
end
function CharacterCreate_RaceEntryMatches(entry, fileName, ...)
	if ( not entry ) then
		return false;
	end
	if ( fileName and strupper(entry.fileName or "") == strupper(fileName) ) then
		return true;
	end
	for nameIndex=1, select("#", ...), 1 do
		if ( CharacterCreate_RaceNameMatches(entry.name, select(nameIndex, ...)) ) then
			return true;
		end
	end
	return false;
end

function CharacterCreate_FindRaceEntryByFaction(raceEntries, expectedFaction, fileName, ...)
	for _, entry in ipairs(raceEntries) do
		if ( CharacterCreate_RaceEntryMatches(entry, fileName, ...) ) then
			local _, entryFaction = GetFactionForRace(entry.listIndex);
			if ( entryFaction == expectedFaction ) then
				return entry;
			end
		end
	end
	return CharacterCreate_FindRaceEntry(raceEntries, fileName, ...);
end

function CharacterCreate_HideSirusExtraRaceButtons(layout)
	-- Keep empty/unsupported slots hidden. Naga is shown by CustomCharCreateRaceButton1.
	local hiddenButtons = {9};
	for _, buttonIndex in ipairs(hiddenButtons) do
		layout[buttonIndex] = nil;
	end
end

function CharacterCreate_ResetSafeRaceMap()
	CharacterCreate.safeRaceIds = {};
	CharacterCreate.safeDefaultRaceId = nil;
	CharacterCreate.safeAllianceRaceId = nil;
	CharacterCreate.safeHordeRaceId = nil;
	CharacterCreate.backgroundRaceByListId = {};
end

function CharacterCreate_GetBackgroundRaceId(raceId)
	if ( not raceId ) then
		return raceId;
	end
	if ( CharacterCreate.backgroundRaceByListId and CharacterCreate.backgroundRaceByListId[raceId] ) then
		return CharacterCreate.backgroundRaceByListId[raceId];
	end
	return raceId;
end

function CharacterCreate_RegisterSafeRaceId(raceId, preferAsDefault)
	if ( not raceId ) then
		return;
	end
	if ( not CharacterCreate.safeRaceIds ) then
		CharacterCreate.safeRaceIds = {};
	end
	CharacterCreate.safeRaceIds[raceId] = true;
	if ( preferAsDefault and not CharacterCreate.safeDefaultRaceId ) then
		CharacterCreate.safeDefaultRaceId = raceId;
	end
	if ( not CharacterCreate.safeAllianceRaceId or not CharacterCreate.safeHordeRaceId ) then
		local _, faction = GetFactionForRace(raceId);
		if ( faction == "Alliance" and not CharacterCreate.safeAllianceRaceId ) then
			CharacterCreate.safeAllianceRaceId = raceId;
		elseif ( faction == "Horde" and not CharacterCreate.safeHordeRaceId ) then
			CharacterCreate.safeHordeRaceId = raceId;
		end
	end
end

function CharacterCreate_RegisterSafeRaceEntry(entry)
	if ( not entry ) then
		return;
	end
	CharacterCreate_RegisterSafeRaceId(entry.listIndex, true);
end

function CharacterCreate_GetSafeRaceId(raceId)
	if ( not raceId ) then
		return CharacterCreate.safeDefaultRaceId or SAFE_DEFAULT_RACE_ID;
	end
	if ( not CharacterCreate.safeRaceIds ) then
		return SAFE_DEFAULT_RACE_ID;
	end
	if ( CharacterCreate.safeRaceIds[raceId] ) then
		return raceId;
	end

	local _, faction = GetFactionForRace(raceId);
	if ( faction == "Horde" and CharacterCreate.safeHordeRaceId ) then
		return CharacterCreate.safeHordeRaceId;
	elseif ( faction == "Alliance" and CharacterCreate.safeAllianceRaceId ) then
		return CharacterCreate.safeAllianceRaceId;
	end
	return CharacterCreate.safeDefaultRaceId or SAFE_DEFAULT_RACE_ID;
end

function CharacterCreate_EnsureSafeSelectedRace()
	local currentRace = GetSelectedRace();
	local safeRace = CharacterCreate_GetSafeRaceId(currentRace);
	if ( safeRace and currentRace ~= safeRace ) then
		SetSelectedRace(safeRace);
	end
	return safeRace;
end

function CharacterCreate_EnsureCreateSelection()
	local raceId = CharacterCreate.selectedRace or GetSelectedRace();
	local activeExtraRace = CharacterCreate_GetActiveRaceForButtons();
	if ( activeExtraRace == EXTRA_RACE_NAGA_KEY ) then
		raceId = EXTRA_RACE_NAGA_INDEX;
	elseif ( activeExtraRace == EXTRA_RACE_DRACTHYR_KEY ) then
		raceId = EXTRA_RACE_DRACTHYR_INDEX;
	end
	raceId = CharacterCreate_GetSafeRaceId(raceId);
	if ( raceId ) then
		CharacterCreate.selectedRace = raceId;
		CharacterCreate.customSelectedRace = CharacterCreate_IsExtraRaceId(raceId) and raceId or nil;
		CharacterCreate.extraRaceButtonSelection = CharacterCreate_GetExtraRaceKeyForRaceId(raceId);
		if ( GetSelectedRace() ~= raceId ) then
			SetSelectedRace(raceId);
		end
		SetCharacterRace(raceId);
	end

	local classId = CharacterCreate.selectedClass or CLASS_ALMACENADA or 1;
	if ( CLASS_ALMACENADA and CLASS_ALMACENADA > 0 ) then
		classId = CLASS_ALMACENADA;
	end
	if ( classId ) then
		CharacterCreate.selectedClass = classId;
		SetSelectedClass(classId);
		SetCharacterClass(classId);
	end
	SetCharacterGender(GetSelectedSex());
end

function CharacterCreate_SetDracthyrBackground(zoom)
	if ( type(SetCharCustomizeBackground) ~= "function" ) then
		return false;
	end
	local backgroundModel = EXTRA_RACE_DRACTHYR_BACKGROUND_MODEL;
	if ( zoom ~= 1 ) then
		if ( GetSelectedSex() == SEX_FEMALE ) then
			backgroundModel = EXTRA_RACE_DRACTHYR_BACKGROUND_ZOOM_FEMALE;
		else
			backgroundModel = EXTRA_RACE_DRACTHYR_BACKGROUND_ZOOM_MALE;
		end
	end
	local ok = pcall(SetCharCustomizeBackground, backgroundModel);
	if ( not ok ) then
		return false;
	end

	if ( zoom == 1 ) then
		if ( CharacterCreateZoom1 ) then
			CharacterCreateZoom1:SetNormalTexture("Interface\\Glues\\CharacterCreate\\ZoomButtom2p");
		end
		if ( CharacterCreateZoom2 ) then
			CharacterCreateZoom2:SetNormalTexture("Interface\\Glues\\CharacterCreate\\ZoomButtom1");
		end
	else
		if ( CharacterCreateZoom1 ) then
			CharacterCreateZoom1:SetNormalTexture("Interface\\Glues\\CharacterCreate\\ZoomButtom2");
		end
		if ( CharacterCreateZoom2 ) then
			CharacterCreateZoom2:SetNormalTexture("Interface\\Glues\\CharacterCreate\\ZoomButtom1p");
		end
	end

	if ( type(SetLighting) == "function" ) then
		pcall(SetLighting, CharacterCreate, "BLOODELF");
	end
	return true;
end

function CharacterCreate_IsStageCDarkIronRace(raceId)
	return CharacterCreate
		and CharacterCreate.stageCDarkIronListIndex
		and raceId == CharacterCreate.stageCDarkIronListIndex;
end

function CharacterCreate_IsStageEPandarenRace(raceId)
	return CharacterCreate
		and CharacterCreate.stageEPandarenListIndex
		and raceId == CharacterCreate.stageEPandarenListIndex;
end

function CharacterCreate_SetStageEPandarenBackground()
	if ( type(SetCharCustomizeBackground) ~= "function" ) then
		return false;
	end
	if ( not pcall(SetCharCustomizeBackground, STAGE_E_PANDAREN_BACKGROUND_MODEL) ) then
		return false;
	end
	if ( type(SetLighting) == "function" ) then
		pcall(SetLighting, CharacterCreate, "BLOODELF");
	end
	if ( type(CharacterCreate_UpdateWheelZoomButtons) == "function" ) then
		CharacterCreate_UpdateWheelZoomButtons(1);
	end
	return true;
end

function CharacterCreate_IsStageHNightborneRace(raceId)
	return CharacterCreate and CharacterCreate.stageHNightborneListIndex
		and raceId == CharacterCreate.stageHNightborneListIndex;
end

function CharacterCreate_SetStageHNightborneBackground()
	if ( type(SetCharCustomizeBackground) ~= "function" ) then return false; end
	if ( not pcall(SetCharCustomizeBackground, STAGE_H_NIGHTBORNE_BACKGROUND_MODEL) ) then return false; end
	if ( type(SetLighting) == "function" ) then pcall(SetLighting, CharacterCreate, "BLOODELF"); end
	if ( type(CharacterCreate_UpdateWheelZoomButtons) == "function" ) then CharacterCreate_UpdateWheelZoomButtons(1); end
	return true;
end

function CharacterCreate_StageIIsZandalariSelected()
	if ( not CharacterCreate or not CharacterCreate.stageIZandalariListIndex ) then
		return false;
	end
	local selectedRace = CharacterCreate.selectedRace;
	if ( not selectedRace or selectedRace == 0 ) then
		selectedRace = GetSelectedRace();
	end
	return selectedRace == CharacterCreate.stageIZandalariListIndex;
end

-- Stage I.2: only the outer race/class page defaults Zandalari to T14.
-- Customization-page T14/T7/NO buttons remain fully user-controlled.
function CharacterCreate_ApplyStageI2ZandalariDefaultT14()
	if ( not CharacterCreate_StageIIsZandalariSelected() ) then
		CharacterCreate.stageI2ZandalariDefaultT14Signature = nil;
		return false;
	end
	if ( CharCreatePreviewFrame and CharCreatePreviewFrame:IsShown() ) then
		return false;
	end

	local classId = CharacterCreate_GetDracthyrCreationPreviewClass()
		or CharacterCreate.selectedClass
		or 1;
	local sex = 0;
	if ( type(GetSelectedSex) == "function" ) then
		sex = GetSelectedSex() or 0;
	end
	local signature = tostring(classId)..":"..tostring(sex);
	if ( CharacterCreate.stageI2ZandalariDefaultT14Signature == signature
			and CharacterCreate.dracthyrCreationPreviewMode == "t14"
			and CharacterCreate.stage89AppliedPreviewMode == "t14"
			and CharacterCreate.stage89AppliedPreviewClass == classId ) then
		CharacterCreate_UpdateDracthyrCreationPreviewButtons();
		return true;
	end

	if ( CharacterCreate.selectedClass and CharacterCreate.selectedClass > 0 ) then
		CLASS_ALMACENADA = CharacterCreate.selectedClass;
	end
	CharacterCreate.dracthyrCreationPreviewMode = "t14";
	CharacterCreate.stage89AppliedPreviewMode = nil;
	CharacterCreate.stage89AppliedPreviewClass = nil;
	local applied = CharacterCreate_SetDracthyrCreationPreviewMode("t14", false);
	if ( applied ) then
		CharacterCreate.stageI2ZandalariDefaultT14Signature = signature;
	else
		CharacterCreate.stageI2ZandalariDefaultT14Signature = nil;
	end
	return applied;
end

function CharacterCreate_IsStageIZandalariRace(raceId)
	return CharacterCreate and CharacterCreate.stageIZandalariListIndex
		and raceId == CharacterCreate.stageIZandalariListIndex;
end

function CharacterCreate_SetStageIZandalariBackground()
	if ( type(SetCharCustomizeBackground) ~= "function" ) then return false; end
	if ( not pcall(SetCharCustomizeBackground, STAGE_I_ZANDALARI_BACKGROUND_MODEL) ) then return false; end
	if ( type(SetLighting) == "function" ) then pcall(SetLighting, CharacterCreate, "BLOODELF"); end
	if ( type(CharacterCreate_UpdateWheelZoomButtons) == "function" ) then CharacterCreate_UpdateWheelZoomButtons(1); end
	return true;
end

function CharacterCreate_SetStageCDarkIronBackground()
	if ( type(SetCharCustomizeBackground) ~= "function" ) then
		return false;
	end
	if ( not pcall(SetCharCustomizeBackground, STAGE_C_DARK_IRON_BACKGROUND_MODEL) ) then
		return false;
	end
	if ( type(SetLighting) == "function" ) then
		pcall(SetLighting, CharacterCreate, "DRAENEI");
	end
	if ( type(CharacterCreate_UpdateWheelZoomButtons) == "function" ) then
		CharacterCreate_UpdateWheelZoomButtons(1);
	end
	return true;
end

function CharacterCreate_SetCurrentBackground(zoom)
	local raceId = CharacterCreate_GetSafeRaceId(CharacterCreate.selectedRace or GetSelectedRace());
	if ( raceId == EXTRA_RACE_DRACTHYR_INDEX and CharacterCreate_SetDracthyrBackground(zoom) ) then
		CharacterCreate.r27WheelZoomLevel = (zoom == 1) and 1 or 4;
		return;
	end
	if ( CharacterCreate_IsStageEPandarenRace(raceId) and CharacterCreate_SetStageEPandarenBackground() ) then
		CharacterCreate.r27WheelZoomLevel = 1;
		return;
	end
	if ( CharacterCreate_IsStageHNightborneRace(raceId) and CharacterCreate_SetStageHNightborneBackground() ) then
		CharacterCreate.r27WheelZoomLevel = 1;
		return;
	end
	if ( CharacterCreate_IsStageIZandalariRace(raceId) and CharacterCreate_SetStageIZandalariBackground() ) then
		CharacterCreate.r27WheelZoomLevel = 1;
		return;
	end
	if ( CharacterCreate_IsStageCDarkIronRace(raceId) and CharacterCreate_SetStageCDarkIronBackground() ) then
		CharacterCreate.r27WheelZoomLevel = 1;
		return;
	end
	local backgroundRaceId = CharacterCreate_GetBackgroundRaceId(raceId);
	local _, faction = GetFactionForRace(raceId);

	if ( raceId == EXTRA_RACE_NAGA_INDEX ) then
		faction = "Horde";
	elseif ( raceId == EXTRA_RACE_DRACTHYR_INDEX ) then
		faction = "Alliance";
	end

	if ( faction == "Alliance" ) then
		SetBackgroundModel(CharacterCreate, "HUMAN", backgroundRaceId, zoom);
	else
		SetBackgroundModel(CharacterCreate, "ORC", backgroundRaceId, zoom);
	end
	CharacterCreate.r27WheelZoomLevel = (zoom == 1) and 1 or 4;
end

-- Levels 2-4 use copies of the normal race scene with progressively moved
-- character attachments. This avoids the client state's old two-mode camera.
CHARACTER_CREATE_WHEEL_ZOOM_PREFIX_BY_BACKGROUND = {
	[1] = "Interface\\Glues\\Models\\zoom\\human\\normal\\z_human_n_r27zh",
	[2] = "Interface\\Glues\\Models\\zoom\\enano\\normal\\z_dwarf_n_r27zd",
	[3] = "Interface\\Glues\\Models\\zoom\\nightelf\\normal\\z_nightelf_n_r27zne",
	[4] = "Interface\\Glues\\Models\\zoom\\gnome\\normal\\z_gnome_n_r27zg",
	[5] = "Interface\\Glues\\Models\\zoom\\draenei\\normal\\z_draenei_n_r27zdr",
	[6] = "Interface\\Glues\\Models\\zoom\\Elfo_del_vacio\\normal\\z_Elfo_del_vacio_n_r27zve",
	[7] = "Interface\\Glues\\Models\\zoom\\highelf\\normal\\z_highelf_n_r27zhe",
	[8] = "Interface\\Glues\\Models\\zoom\\Worgen\\normal\\z_Worgen_n_r27zwo",
	[10] = "Interface\\Glues\\Models\\zoom\\lightforgeddraenei\\normal\\z_lightforgeddraenei_n_r27zlf",
	[11] = "Interface\\Glues\\Models\\ui_demonhunter\\ui_demonhunter_r27zadh",
	[12] = "Interface\\Glues\\Models\\zoom\\orc\\normal\\z_orc_n_r27zo",
	[13] = "Interface\\Glues\\Models\\zoom\\scourge\\normal\\z_scourge_n_r27zs",
	[14] = "Interface\\Glues\\Models\\zoom\\tauren\\normal\\z_tauren_n_r27zta",
	[15] = "Interface\\Glues\\Models\\zoom\\troll\\normal\\z_troll_n_r27ztr",
	[16] = "Interface\\Glues\\Models\\zoom\\goblin\\normal\\z_goblin_n_r27zgo",
	[17] = "Interface\\Glues\\Models\\zoom\\bloodelf\\normal\\z_bloodelf_n_r27zbe",
	[18] = "Interface\\Glues\\Models\\zoom\\vulpera\\normal\\z_vulpera_n_r27zvu",
	[19] = "Interface\\Glues\\Models\\UI_Pandaren\\UI_PandarenC_r27zpa",
	[20] = "Interface\\Glues\\Models\\ui_eredar\\ui_eredar_r27zer",
	[21] = "Interface\\Glues\\Models\\ui_demonhunter\\ui_demonhunter_r27zhdh",
	[STAGE_C_DARK_IRON_LAYOUT_INDEX] = STAGE_C_DARK_IRON_WHEEL_ZOOM_PREFIX,
	[STAGE_H_NIGHTBORNE_LAYOUT_INDEX] = STAGE_H_NIGHTBORNE_WHEEL_ZOOM_PREFIX,
	[STAGE_I_ZANDALARI_LAYOUT_INDEX] = STAGE_I_ZANDALARI_WHEEL_ZOOM_PREFIX,
	[EXTRA_RACE_NAGA_KEY] = "Interface\\Glues\\Models\\UI_Horde\\UI_Horde_r27zna",
	[EXTRA_RACE_DRACTHYR_KEY] = "Interface\\Glues\\Models\\ui_dracthyr\\ui_dracthyr_r27zdy",
};

CHARACTER_CREATE_WHEEL_ZOOM_UNISEX = {
	[EXTRA_RACE_NAGA_KEY] = true,
};

function CharacterCreate_GetWheelZoomModel(level)
	local raceId = CharacterCreate_GetSafeRaceId(CharacterCreate.selectedRace or GetSelectedRace());
	local activeExtraRace = CharacterCreate_GetActiveRaceForButtons();
	local backgroundRaceId = nil;
	if ( activeExtraRace == EXTRA_RACE_NAGA_KEY or activeExtraRace == EXTRA_RACE_DRACTHYR_KEY ) then
		-- The client can reorder extra races between starts. Their named button
		-- keys remain stable, unlike their transient list indexes.
		backgroundRaceId = activeExtraRace;
	else
		backgroundRaceId = raceId;
		backgroundRaceId = CharacterCreate_GetBackgroundRaceId(raceId);
	end

	local prefix = CHARACTER_CREATE_WHEEL_ZOOM_PREFIX_BY_BACKGROUND[backgroundRaceId];
	if ( not prefix ) then
		return nil, backgroundRaceId;
	end

	local suffix = "m";
	if ( CHARACTER_CREATE_WHEEL_ZOOM_UNISEX[backgroundRaceId] ) then
		suffix = "u";
	elseif ( GetSelectedSex() == SEX_FEMALE ) then
		suffix = "f";
	end
	return prefix..level..suffix..".m2", backgroundRaceId;
end

function CharacterCreate_UpdateWheelZoomButtons(level)
	if ( CharacterCreateZoom1 ) then
		CharacterCreateZoom1:SetNormalTexture((level == 1) and "Interface\\Glues\\CharacterCreate\\ZoomButtom2p" or "Interface\\Glues\\CharacterCreate\\ZoomButtom2");
	end
	if ( CharacterCreateZoom2 ) then
		CharacterCreateZoom2:SetNormalTexture((level == 1) and "Interface\\Glues\\CharacterCreate\\ZoomButtom1" or "Interface\\Glues\\CharacterCreate\\ZoomButtom1p");
	end
end

function CharacterCreate_SetWheelZoomLevel(level)
	level = math.max(1, math.min(4, level or 1));
	if ( level == (CharacterCreate.r27WheelZoomLevel or 1) ) then
		return;
	end
	if ( level == 1 ) then
		CharacterCreate_SetCurrentBackground(1);
		return;
	end

	local modelPath, backgroundRaceId = CharacterCreate_GetWheelZoomModel(level);
	if ( not modelPath or type(SetCharCustomizeBackground) ~= "function" ) then
		return;
	end
	if ( not pcall(SetCharCustomizeBackground, modelPath) ) then
		return;
	end

	CharacterCreate_UpdateWheelZoomButtons(level);
	if ( type(SetLighting) == "function" ) then
		local lighting = (backgroundRaceId == STAGE_C_DARK_IRON_LAYOUT_INDEX) and "DRAENEI"
			or ((backgroundRaceId == 3 or backgroundRaceId == 13) and "NIGHTELF" or "BLOODELF");
		pcall(SetLighting, CharacterCreate, lighting);
	end
	CharacterCreate.r27WheelZoomLevel = level;
end

function CharacterCreate_SetupZoomButtonScripts()
	if ( CharacterCreateZoom1 ) then
		CharacterCreateZoom1:SetScript("OnClick", function()
			-- Keep the two legacy buttons on the same four-level background path
			-- used by the mouse wheel.  The old nil zoom path can select the wrong
			-- scene for extra races such as Naga.
			CharacterCreate_SetWheelZoomLevel(1);
		end);
	end
	if ( CharacterCreateZoom2 ) then
		CharacterCreateZoom2:SetScript("OnClick", function()
			CharacterCreate_SetWheelZoomLevel(4);
		end);
	end
end

function CharacterCreate_SetRaceButtonFromEntry(button, entry, gender)
	if ( not button or not entry ) then
		return;
	end

	local unlocalizedname = strupper(entry.fileName or "DEFAULT");
	local coords = RACE_ICON_TCOORDS[unlocalizedname.."_"..gender];
	if ( coords == nil ) then
		coords = RACE_ICON_TCOORDS["HUMAN_"..gender];
	end

	button:SetID(entry.listIndex);
	button:Show();
	if ( _G[button:GetName().."NormalTexture"] ) then
		_G[button:GetName().."NormalTexture"]:SetTexCoord(coords[1], coords[2], coords[3], coords[4]);
		_G[button:GetName().."PushedTexture"]:SetTexCoord(coords[1], coords[2], coords[3], coords[4]);
	end

	local faction = coords[5];
	if ( faction ) then
		if ( faction == "ALLIANCE" ) then
			button.borderfaction:SetTexture("Interface\\Glues\\CharacterCreate\\AlliRoundRaceOk");
		else
			button.borderfaction:SetTexture("Interface\\Glues\\CharacterCreate\\HordeRoundRaceOk");
		end
	end
	button.borderfaction:Hide();

	local textito = string.gsub(button:GetName(), "CharCreateRaceButton", "");
	if ( LIKENUMBERRACES == true ) then
		button.nameFrame.text:SetText(textito);
	else
		button.nameFrame.text:SetText(entry.name);
	end

	if ( entry.enabled == 1 ) then
		button.enable = true;
		button:Enable();
		SetButtonDesaturated(button);
		button.name = entry.name;
		button.tooltip = entry.name;
	else
		button:Disable();
		SetButtonDesaturated(button, 1);
		button.name = entry.name;
		local disabledReason = _G[unlocalizedname.."_DISABLED"];
		if ( disabledReason ) then
			button.tooltip = entry.name.."|n"..disabledReason;
		else
			button.tooltip = nil;
		end
	end

	local abilityIndex = 1;
	local tempText = _G["ABILITY_INFO_"..unlocalizedname..abilityIndex];
	local abilityText = "";
	while ( tempText ) do
		abilityText = abilityText..tempText.."\n\n";
		abilityIndex = abilityIndex + 1;
		tempText = _G["ABILITY_INFO_"..unlocalizedname..abilityIndex];
	end

	local text = GetFlavorText("RACE_INFO_"..unlocalizedname, gender);
	if ( text ) then
		button.tooltip = "|cffFFFFFF" .. button.nameFrame.text:GetText() .. "|r\n\n|r" .. text .. "\n\n|cffFFFFFF" .. abilityText;
	end
end

function CharacterCreateEnumerateRaces(...)
    CharacterCreate.wdHumanRaces = {};
	CharacterCreate.monkPhaseOneRaces = {};
	CharacterCreate_UpdateExtraRaceIndices(...);
	local availableRaceCount = select("#", ...)/3;
	CharacterCreate.numRaces = math.min(availableRaceCount, NORMAL_RACE_BUTTON_LIMIT);
	if ( CharacterCreate.numRaces > MAX_RACES ) then
		message("Too many races!  Update MAX_RACES");
		return;
	end

	local gender;
	local selectedSex = GetSelectedSex();
	if ( selectedSex == SEX_MALE ) then
		gender = "MALE";
	else
		gender = "FEMALE";
	end

	local raceEntries = {};
	for i=1, select("#", ...), 3 do
		local entry = {};
		entry.listIndex = (i + 2) / 3;
		entry.name = select(i, ...);
		entry.fileName = select(i + 1, ...);
		entry.enabled = select(i + 2, ...);
        local policyName = string.lower((entry.name or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""));
        CharacterCreate.monkPhaseOneRaces[entry.listIndex] = monkPhaseOneNames[policyName] == true;
        CharacterCreate.wdHumanRaces[entry.listIndex] = policyName == "人类" or policyName == "human";
		table.insert(raceEntries, entry);
	end

	local layout = {};
	layout[1] = CharacterCreate_FindRaceEntry(raceEntries, "HUMAN", "人类", "Human");
	layout[2] = CharacterCreate_FindRaceEntry(raceEntries, "DWARF", "矮人", "Dwarf");
	layout[3] = CharacterCreate_FindRaceEntry(raceEntries, "NIGHTELF", "暗夜精灵", "Night Elf");
	layout[4] = CharacterCreate_FindRaceEntry(raceEntries, "GNOME", "侏儒", "Gnome");
	layout[5] = CharacterCreate_FindRaceEntry(raceEntries, "DRAENEI", "德莱尼", "Draenei");
	layout[6] = CharacterCreate_FindRaceEntryByNameOnlyByFaction(raceEntries, "Alliance", "虚空精灵", "Void Elf", "Elfo del vacio");
	layout[7] = CharacterCreate_FindRaceEntryByNameOnlyByFaction(raceEntries, "Alliance", "高等精灵", "High Elf");
	layout[8] = CharacterCreate_FindRaceEntryByNameOnlyByFaction(raceEntries, "Alliance", "狼人", "Worgen", "Huargen");
	layout[9] = nil;
	layout[10] = CharacterCreate_FindRaceEntryByNameOnlyByFaction(raceEntries, "Alliance", "光铸德莱尼", "Lightforged");
	layout[11] = CharacterCreate_FindRaceEntryByNameOnlyByFaction(raceEntries, "Alliance", "恶魔猎手|cff0070de|r", "恶魔猎手", "Demon Hunter|cff0070de|r", "Demon Hunter");

	layout[12] = CharacterCreate_FindRaceEntryByFaction(raceEntries, "Horde", "ORC", "兽人", "Orc");
	layout[13] = CharacterCreate_FindRaceEntry(raceEntries, "SCOURGE", "亡灵", "Undead");
	layout[14] = CharacterCreate_FindRaceEntry(raceEntries, "TAUREN", "牛头人", "Tauren");
	layout[15] = CharacterCreate_FindRaceEntry(raceEntries, "TROLL", "巨魔", "Troll");
	layout[16] = CharacterCreate_FindRaceEntryByFaction(raceEntries, "Horde", "GOBLIN", "地精", "Goblin");
	layout[17] = CharacterCreate_FindRaceEntry(raceEntries, "BLOODELF", "血精灵", "Blood Elf");
	layout[18] = CharacterCreate_FindRaceEntryByNameOnlyByFaction(raceEntries, "Horde", "狐人", "Vulpera");
	layout[19] = CharacterCreate_FindRaceEntryByNameOnlyByFaction(raceEntries, "Horde", "熊猫人|cffc41f3b|r", "熊猫人", "Panda Horda", "Pandaren|cffc41f3b|r", "Pandaren");
	layout[20] = CharacterCreate_FindRaceEntryByNameOnlyByFaction(raceEntries, "Horde", "曼阿里·艾瑞达", "Man'ari Eredar", "Eredar");
	layout[21] = CharacterCreate_FindRaceEntryByNameOnlyByFaction(raceEntries, "Horde", "恶魔猎手|cffc41f3b|r", "恶魔猎手", "Demon Hunter|cffc41f3b|r", "Demon Hunter");
	local pandarenEntry = CharacterCreate_FindRaceEntry(raceEntries, "PANDAREN", "熊猫人|cff0070de|r", "联盟熊猫人", "Pandaren|cff0070de|r", "Pandaren");
	local darkIronEntry = CharacterCreate_FindRaceEntry(raceEntries, "DARKIRONDWARF", "黑铁矮人", "Dark Iron Dwarf", "DarkIronDwarf");
	local nightborneEntry = CharacterCreate_FindRaceEntry(raceEntries, "NIGHTBORNE", "夜之子", "Nightborne");
	local zandalariEntry = CharacterCreate_FindRaceEntry(raceEntries, "ZANDALARITROLL", "赞达拉巨魔", "Zandalari Troll", "ZandalariTroll");
	CharacterCreate_HideSirusExtraRaceButtons(layout);
	CharacterCreate_ResetSafeRaceMap();
	CharacterCreate.stageEPandarenListIndex = nil;
	CharacterCreate.stageCDarkIronListIndex = nil;
	CharacterCreate.stageHNightborneListIndex = nil;
	CharacterCreate.stageIZandalariListIndex = nil;
	if ( pandarenEntry ) then
		CharacterCreate.stageEPandarenListIndex = pandarenEntry.listIndex;
		-- Reuse the Horde Pandaren background and all four Pandaren camera levels.
		-- Race22 remains Alliance; only its visual scene carrier is shared.
		CharacterCreate.backgroundRaceByListId[pandarenEntry.listIndex] = STAGE_E_PANDAREN_BACKGROUND_LAYOUT;
	end
	if ( nightborneEntry ) then
		CharacterCreate.stageHNightborneListIndex = nightborneEntry.listIndex;
		CharacterCreate.backgroundRaceByListId[nightborneEntry.listIndex] = STAGE_H_NIGHTBORNE_BACKGROUND_LAYOUT;
	end
	if ( zandalariEntry ) then
		CharacterCreate.stageIZandalariListIndex = zandalariEntry.listIndex;
		CharacterCreate.backgroundRaceByListId[zandalariEntry.listIndex] = STAGE_I_ZANDALARI_BACKGROUND_LAYOUT;
	end
	if ( darkIronEntry ) then
		CharacterCreate.stageCDarkIronListIndex = darkIronEntry.listIndex;
		CharacterCreate.backgroundRaceByListId[darkIronEntry.listIndex] = STAGE_C_DARK_IRON_LAYOUT_INDEX;
	end

	for buttonIndex=1, NORMAL_RACE_BUTTON_LIMIT, 1 do
		-- All 21 normal race buttons are declared by CharacterCreate.xml.
		-- stable99 cannot safely manufacture a missing CheckButton at runtime.
		local button = _G["CharCreateRaceButton"..buttonIndex];
		local entry = layout[buttonIndex];
		if ( button ) then
			if ( entry ) then
				CharacterCreate_RegisterSafeRaceEntry(entry);
				CharacterCreate.backgroundRaceByListId[entry.listIndex] = buttonIndex;
				CharacterCreate_SetRaceButtonFromEntry(button, entry, gender);
			else
				button:Hide();
			end
		end
	end

	-- Register activated custom races only after native buttons so Human remains
	-- the safe default and normal Alliance fallback.
	if ( pandarenEntry ) then
		CharacterCreate_RegisterSafeRaceId(pandarenEntry.listIndex, false);
	end
	if ( nightborneEntry ) then
		CharacterCreate_RegisterSafeRaceId(nightborneEntry.listIndex, false);
	end
	if ( zandalariEntry ) then
		CharacterCreate_RegisterSafeRaceId(zandalariEntry.listIndex, false);
	end
	if ( darkIronEntry ) then
		CharacterCreate_RegisterSafeRaceId(darkIronEntry.listIndex, false);
	end

	for i=NORMAL_RACE_BUTTON_LIMIT + 1, MAX_RACES, 1 do
		if ( _G["CharCreateRaceButton"..i] ) then
			_G["CharCreateRaceButton"..i]:Hide();
		end
	end
	CharacterCreate_SetupExtraRaceButtons();
	CharacterCreate_StageBUpdateStaticRaceButtons();
end
function CharacterCreate_GetAllowedClassList()
	local selectedRace = CharacterCreate and CharacterCreate.selectedRace or GetSelectedRace();
	if ( CharacterCreate and CharacterCreate.stageEPandarenListIndex
		and selectedRace == CharacterCreate.stageEPandarenListIndex ) then
		return STAGE_E_PANDAREN_CLASS_LIST;
	end
	if ( CharacterCreate and CharacterCreate.stageHNightborneListIndex
		and selectedRace == CharacterCreate.stageHNightborneListIndex ) then
		return STAGE_H_NIGHTBORNE_CLASS_LIST;
	end
	if ( CharacterCreate and CharacterCreate.stageIZandalariListIndex
		and selectedRace == CharacterCreate.stageIZandalariListIndex ) then
		return STAGE_I_ZANDALARI_CLASS_LIST;
	end
	if ( CharacterCreate and CharacterCreate.stageCDarkIronListIndex
		and selectedRace == CharacterCreate.stageCDarkIronListIndex ) then
		return STAGE_C_DARK_IRON_CLASS_LIST;
	end
	local raceName = GetNameForRace();
	local classList = nil;
	if ( raceName ) then
		classList = GetBGluSpecil(raceName, "Classes");
	end
	if ( not classList ) then
		classList = GetBGluSpecil(selectedRace, "Classes");
	end
	return classList;
end
function CharacterCreate_IsClassAllowedByGlue(classIndex)
    if CharacterCreate.witchDoctorClassIndex == classIndex then return CharacterCreate_WitchDoctorRaceIsOpen(CharacterCreate.selectedRace) and not PAID_SERVICE_TYPE; end
	if ( CharacterCreate.monkClassIndex == classIndex ) then
		return CharacterCreate_MonkRaceIsOpen(CharacterCreate.selectedRace);
	end
	local classList = CharacterCreate_GetAllowedClassList();
	if ( not classList ) then
		return false;
	end
	for _, classId in pairs(classList) do
		if ( classId == classIndex ) then
			return true;
		end
	end
	return false;
end
function CharacterCreate_IsRaceClassValidSafe(raceIndex, classIndex)
    if CharacterCreate.witchDoctorClassIndex == classIndex then return CharacterCreate_WitchDoctorRaceIsOpen(raceIndex) and not PAID_SERVICE_TYPE; end
	if CharacterCreate.monkClassIndex == classIndex then return CharacterCreate_MonkRaceIsOpen(raceIndex); end
	if ( type(IsRaceClassValid) == "function" ) then
		return IsRaceClassValid(raceIndex, classIndex);
	end
	return CharacterCreate_IsClassAllowedByGlue(classIndex);
end
function CharacterCreateEnumerateClasses(...)
	CharacterCreate.numClasses = select("#", ...)/3;
	if ( CharacterCreate.numClasses > MAX_CLASSES_PER_RACE ) then
		message("Too many classes!  Update MAX_CLASSES_PER_RACE");
		return;
	end
	local coords;
	local index = 1;
	local button;
	CharacterCreate.witchDoctorClassIndex = nil;
	CharacterCreate.wdEnumeratedEnabled = nil;
	CharacterCreate_ResetMonkButton();
	for classButtonIndex=1, MAX_CLASSES_PER_RACE do
		local classButton = _G["CharCreateClassButton"..classButtonIndex];
		if ( classButton ) then
			classButton.codexIsMonkClass = false;
            classButton.codexIsWitchDoctorClass = false;
		end
	end
	for i=1, select("#", ...), 3 do
		local classToken = select(i+1, ...);
		local unlocalizedname = type(classToken) == "string" and strupper(classToken) or "";
		if ( unlocalizedname == MONK_CLASS_FILE ) then
			CharacterCreate.monkClassIndex = index;
		end
        if unlocalizedname == "WITCHDOCTOR" then CharacterCreate.witchDoctorClassIndex = index; end

		-- A rejected character-create request can make some modified 3.3.5 cores
		-- briefly enumerate an unknown class token while rebuilding this screen.
		-- Keep the original class/button index and use a harmless placeholder icon;
		-- skipping the entry would shift class IDs and could create the wrong class.
		coords = CLASS_ICON_TCOORDS[unlocalizedname] or CLASS_ICON_TCOORDS["WARRIOR"];
		_G["CharCreateClassButton"..index.."NormalTexture"]:SetTexCoord(coords[1], coords[2], coords[3], coords[4]);
		_G["CharCreateClassButton"..index.."PushedTexture"]:SetTexCoord(coords[1], coords[2], coords[3], coords[4]);
		button = _G["CharCreateClassButton"..index];
		button:Show();
		button.nameFrame.text:SetText(select(i, ...));
		button.tooltip = ""
		button.tooltip2 = ""
		button.tooltip = button.nameFrame.text:GetText()
		
		local abilityIndex = 0;
		local tempText = _G["CLASS_INFO_"..unlocalizedname..abilityIndex];
		local tempText2 = _G["NEW_CLASS_INFO_"..unlocalizedname];
		abilityText = "";
		abilityText2 = "";
		while ( tempText ) do
			abilityText = abilityText..tempText.."\n\n";
			button.tooltip2 = abilityText 	
			abilityText2 = tempText2 .. "";
			abilityIndex = abilityIndex + 1;
			tempText = _G["CLASS_INFO_"..unlocalizedname..abilityIndex];
		end
		if(button.nameFrame.text:GetText() == "Caballero de la Muerte")then 
			button.nameFrame.text:SetText("|n|nCaballero|nde la Muerte");
			button.nameFrame.text:SetPoint("TOP", 2, -40);
		end 
		
		CharCreateClassButtoHeroNormalTexture:SetTexCoord(0.49609370, 0.7421870, 0.5, 0.75);
		CharCreateClassButtoHeroPushedTexture:SetTexCoord(0.49609370, 0.7421870, 0.5, 0.75);
	--	message(CharacterCreate.selectedRace)
		if(CharacterCreate.selectedRace == 900 or CharacterCreate.selectedRace == 2000)then 
			CharCreateClassButtoHero:Enable();
			SetButtonDesaturated(CharCreateClassButtoHero);
			CharCreateClassButtoHeroNormalTexture:SetAlpha(1);
		else
			CharCreateClassButtoHero:Disable();
			SetButtonDesaturated(CharCreateClassButtoHero, 1);
			CharCreateClassButtoHeroNormalTexture:SetAlpha(0.4);
		end
			CharCreateClassButtoHero.nameFrame.text:SetSize(100,0)
			CharCreateClassButtoHero.nameFrame.text:SetText("|n|nLuchador|nErrante");
			CharCreateClassButtoHero.nameFrame.text:SetPoint("TOP", 2, -40);
		
		if ( select(i+2, ...) == 1 ) then
			if (CharacterCreate_IsRaceClassValidSafe(CharacterCreate.selectedRace, index) or CharacterCreate_IsClassAllowedByGlue(index)) then
			
				local race, _ = GetNameForRace();
				local itsOK = CharacterCreate_IsClassAllowedByGlue(index);
				
				if(CharacterCreate.selectedRace == 900 or CharacterCreate.selectedRace == 2000)then
					CharCreateClassButtoHeroNormalTexture:SetAlpha(1);
					CharCreateClassButtoHero.nameFrame.text:SetText("|CFFDAA520" .. CharCreateClassButtoHero.nameFrame.text:GetText() .. "|r")
					CharCreateClassButtoHero:Enable();
					SetButtonDesaturated(CharCreateClassButtoHero);
					text = NEW_CLASS_HERO .. "|n|n" 
					CharCreateClassButtoHero.tooltip = "|r"..text
					CharCreateClassButtoHero.tooltip = CharCreateClassButtoHero.tooltip.."职能: |cffFFFFFF"..NEW_CLASS_HAB.."|r"
				else
					CharCreateClassButtoHeroNormalTexture:SetAlpha(0.4);
					CharCreateClassButtoHero.nameFrame.text:SetText("|CFF696969" .. CharCreateClassButtoHero.nameFrame.text:GetText() .. "|r")
					CharCreateClassButtoHero:Disable();
					SetButtonDesaturated(CharCreateClassButtoHero, 1);
					CharCreateClassButtoHero.tooltip = "|cffFF0000" .. CLASS_DISABLED .."|r";
					text = NEW_CLASS_HERO .. "|n|n" 
					CharCreateClassButtoHero.tooltip = text .. "|cffFFFFFF"..CharCreateClassButtoHero.tooltip.."|r"
					_G["CharCreateClassButton"..index.."DisableTexture"]:Show();
				end
				
				if(itsOK == true)then
						_G["CharCreateClassButton"..index.."NormalTexture"]:SetAlpha(1);
						button.nameFrame.text:SetText("|CFFDAA520" .. button.nameFrame.text:GetText() .. "|r")
						button:Enable();
						SetButtonDesaturated(button);
						text = GetFlavorText("NEW_CLASS_"..strupper(unlocalizedname), "MALE").."|n|n" 
						button.tooltip = "|r"..text
						button.tooltip = button.tooltip.."职能: |cffFFFFFF"..abilityText2.."|r"
						
				else
					_G["CharCreateClassButton"..index.."NormalTexture"]:SetAlpha(0.4);
					button.nameFrame.text:SetText("|CFF696969" .. button.nameFrame.text:GetText() .. "|r")
					button:Disable();
					SetButtonDesaturated(button, 1);
					button.tooltip = "|cffFF0000" .. CLASS_DISABLED .."|r";
					text = GetFlavorText("NEW_CLASS_"..strupper(unlocalizedname), "MALE").."|n|n" 
					button.tooltip = text .. "|cffFFFFFF"..button.tooltip.."|r"
					_G["CharCreateClassButton"..index.."DisableTexture"]:Show();
				end  
			else
				_G["CharCreateClassButton"..index.."NormalTexture"]:SetAlpha(0.4);
				button.nameFrame.text:SetText("|CFF696969" .. button.nameFrame.text:GetText() .. "|r")
				button:Disable();
				SetButtonDesaturated(button, 1);
				button.tooltip = "|cff8B0000" .. CLASS_DISABLED .."|r";
				text = GetFlavorText("NEW_CLASS_"..strupper(unlocalizedname), "MALE").."|n|n" 
				button.tooltip = text .. "|cffFFFFFF"..button.tooltip.."|r"
				_G["CharCreateClassButton"..index.."DisableTexture"]:Show();
			end
		else
			button:Disable();
			SetButtonDesaturated(button, 1);
			_G["CharCreateClassButton"..index.."DisableTexture"]:Show();
		end
				
		if ( unlocalizedname == MONK_CLASS_FILE ) then
			button.codexIsMonkClass = true;
			CharacterCreate_ConfigureMonkButton(
				index,
				select(i, ...),
				button:IsEnabled(),
				button.tooltip,
				button.tooltip2
			);
			button:Hide();
		end

        if unlocalizedname == "WITCHDOCTOR" then
            button.codexIsWitchDoctorClass = true;
            CharacterCreate.wdEnumeratedEnabled = select(i+2, ...) == 1 or select(i+2, ...) == true;
            CharacterCreate_PositionWitchDoctorPreview();
            button:Hide();
        end

		index = index + 1; 
	end
	for i=CharacterCreate.numClasses + 1, MAX_CLASSES_PER_RACE, 1 do
		local button = _G["CharCreateClassButton"..i];
		if ( button ) then
			button:Hide();
		end
	end
	CharacterCreate_HideLegacyHeroClassButton();
	CharacterCreate_PositionClassButtons();
end

function SetCharacterRace(id)
	id = CharacterCreate_GetSafeRaceId(id);
	if ( not id ) then
		return;
	end
	local isExtraRace = CharacterCreate_IsExtraRaceId(id);
	local extraRaceKey = CharacterCreate_GetExtraRaceKeyForRaceId(id);
	if ( isExtraRace ) then
		CharacterCreate.customSelectedRace = id;
		CharacterCreate.extraRaceButtonSelection = extraRaceKey;
	else
		CharacterCreate.customSelectedRace = nil;
		CharacterCreate.extraRaceButtonSelection = nil;
	end
	if ( GetSelectedRace() ~= id ) then
		SetSelectedRace(id);
	end

	for i=1, 4  do
		local button2 = _G["CustomCharCreateRaceButton"..i];
		if ( button2 ) then
			CharacterCreate_SetExtraRaceButtonChecked(button2, false);
		end
	end 
	CharacterCreate.selectedRace = id;
	CharacterCreate_UpdateExtraRaceChecks(extraRaceKey or id);
	local selectedButton;
	for i=1, NORMAL_RACE_BUTTON_LIMIT, 1 do
		local button = _G["CharCreateRaceButton"..i];
		if ( button ) then
			if ( not isExtraRace and button:GetID() == id ) then
				button:SetChecked(1);
			else
				button:SetChecked(0);
			end
		end
	end
	local pandarenButton = _G["CharCreateRaceButton"..STAGE_E_PANDAREN_LAYOUT_INDEX];
	if ( pandarenButton ) then
		pandarenButton:SetChecked(
			CharacterCreate.stageEPandarenListIndex
			and id == CharacterCreate.stageEPandarenListIndex
			and 1 or 0
		);
	end
	local nightborneButton = _G["CharCreateRaceButton"..STAGE_H_NIGHTBORNE_LAYOUT_INDEX];
	if ( nightborneButton ) then
		nightborneButton:SetChecked(CharacterCreate.stageHNightborneListIndex and id == CharacterCreate.stageHNightborneListIndex and 1 or 0);
	end
	local zandalariButton = _G["CharCreateRaceButton"..STAGE_I_ZANDALARI_LAYOUT_INDEX];
	if ( zandalariButton ) then
		zandalariButton:SetChecked(CharacterCreate.stageIZandalariListIndex and id == CharacterCreate.stageIZandalariListIndex and 1 or 0);
	end
	local darkIronButton = _G["CharCreateRaceButton"..STAGE_C_DARK_IRON_LAYOUT_INDEX];
	if ( darkIronButton ) then
		darkIronButton:SetChecked(
			CharacterCreate.stageCDarkIronListIndex
			and id == CharacterCreate.stageCDarkIronListIndex
			and 1 or 0
		);
	end

	-- Set Faction
	local name, faction = GetFactionForRace(CharacterCreate.selectedRace);

	if faction == nil then
		faction = "Alliance";
	end 
	local canProceed = true; 
	CharCreate_EnableNextButton(canProceed);

	-- Convert the runtime race ID to the background layout ID before choosing a scene.
	-- Horde scene assets use layout IDs 12-21 rather than the raw race-list IDs.
	CharacterCreate_SetCurrentBackground(1);

	-- Character list refresh can reach this function before the XML gender
	-- buttons have been instantiated.  Do not index the missing globals.
	if ( CharCreateMaleButton and CharCreateFemaleButton ) then
		if(CharacterCreate.selectedRace == 900 or CharacterCreate.selectedRace == 2000 )then  
			CharCreateMaleButton:Hide()
			CharCreateFemaleButton:Hide()
		else 
			CharCreateMaleButton:Show()
			CharCreateFemaleButton:Show()
		end
	end
	-- Set backdrop colors based on faction
	local backdropColor = FACTION_BACKDROP_COLOR_TABLE[faction];
 	CharCreateCustomizationFrameBanner:SetVertexColor(backdropColor[10], backdropColor[11], backdropColor[12]);
	CharacterCreateNameEdit:SetBackdropColor(backdropColor[4], backdropColor[5], backdropColor[6]);
 
	-- race info
	local frame = CharCreateRaceInfoFrame;
	local race, fileString = GetNameForRace();
	frame.title:SetText(race);
	fileString = strupper(fileString);
	if ( CharacterCreate.selectedRace == EXTRA_RACE_NAGA_INDEX ) then
		frame.title:SetText(EXTRA_RACE_NAGA_NAME or "Naga");
		fileString = "NAGA_CUSTOM";
	elseif ( CharacterCreate.selectedRace == EXTRA_RACE_DRACTHYR_INDEX ) then
		frame.title:SetText(EXTRA_RACE_DRACTHYR_NAME or "Dracthyr");
		fileString = "DRACTHYR_CUSTOM";
	end
	local gender;
	if ( GetSelectedSex() == SEX_MALE ) then
		gender = "MALE";
	else
		gender = "FEMALE";
	end
	local raceText = _G["RACE_INFO_"..fileString];
	local abilityIndex = 1;
	local tempText = _G["ABILITY_INFO_"..fileString..abilityIndex];
	abilityText = "";
	while ( tempText ) do
		abilityText = abilityText..tempText.."\n\n";
		abilityIndex = abilityIndex + 1;
		tempText = _G["ABILITY_INFO_"..fileString..abilityIndex];
	end
	CharCreateRaceInfoFrameScrollFrameScrollBar:SetValue(0);
	local text
	text = GetFlavorText("RACE_INFO_"..strupper(fileString), GetSelectedSex())
	if not text then
		text = "Not in GlueXML."
	end
	CharCreateRaceInfoFrame.scrollFrame.scrollChild.infoText:SetText(text.."|n|n");
	if ( abilityText and abilityText ~= "" ) then
		CharCreateRaceInfoFrame.scrollFrame.scrollChild.bulletText:SetText(abilityText);
	else
		CharCreateRaceInfoFrame.scrollFrame.scrollChild.bulletText:SetText("");
	end
 
end

function SetCharacterClass(id)
	CharacterCreate.selectedRace = CharacterCreate_GetSafeRaceId(CharacterCreate.selectedRace or GetSelectedRace());
	if ( CharacterCreate.selectedRace and GetSelectedRace() ~= CharacterCreate.selectedRace ) then
		SetSelectedRace(CharacterCreate.selectedRace);
	end

	CharacterCreate.selectedClass = id;
	for i=1, CharacterCreate.numClasses, 1 do
		local button = _G["CharCreateClassButton"..i];
		if ( i == id ) then
			button:SetChecked(1);
		else
			button:SetChecked(0);
			button.selection:Hide();
		end
	end
	if ( CharCreateMonkButton ) then
		CharCreateMonkButton:SetChecked(CharacterCreate.monkClassIndex == id and 1 or 0);
	end

	if(CharacterCreate.selectedRace == 900 and id == 10 or CharacterCreate.selectedRace == 2000 and id == 10)then
		CharCreateClassButtoHero:SetChecked(1);
		CharCreateClassButton10:SetChecked(0);
	else
		CharCreateClassButtoHero:SetChecked(0);
	end
	local name, faction = GetFactionForRace(CharacterCreate.selectedRace);

	if faction == nil then
		faction = "Alliance";
	end 
	local canProceed = not (CharacterCreate.monkClassIndex == id and not CharacterCreate_MonkRaceIsOpen(CharacterCreate.selectedRace)); 
    if CharacterCreate.witchDoctorClassIndex == id and not CharacterCreate_WitchDoctorRaceIsOpen(CharacterCreate.selectedRace) then canProceed = false; end
    CharacterCreate_PositionWitchDoctorPreview();
	CharCreate_EnableNextButton(canProceed);

	-- Use the same mapped background path as race selection.
	CharacterCreate_SetCurrentBackground(1);

	-- class info
	local frame = CharCreateClassInfoFrame;
	local className, classFileName, _, tank, healer, damage = GetSelectedClass();
	local namenewclasglobal1 = "";
	local namenewclasglobal2 = "";
	
	--if(CLASS_ALMACENADA)then 
	--	namenewclasglobal1 = _G["CharCreateClassButton"..CLASS_ALMACENADA].nameFrame.text:GetText(); 
	--	namenewclasglobal2 = _G["CharCreateClassButton"..CLASS_ALMACENADA].tooltip2; 
	--end

	if(CharacterCreate.selectedRace == 900 or CharacterCreate.selectedRace == 2000 )
		and CharCreateMaleButton and CharCreateFemaleButton then  
		CharCreateMaleButton:Hide();
		CharCreateFemaleButton:Hide();
		
		--if(CLASS_ALMACENADA == 10)then
		--	namenewclasglobal1 = "Luchador Errante";
		--	namenewclasglobal2 = NEW_CLASS_HAB .. "|r|n|n" .. NEW_CLASS_HAB1 .. "|n|n" .. NEW_CLASS_HAB2 .. "|n|n" .. NEW_CLASS_HAB3 .. "|n|n" .. NEW_CLASS_HAB4;  
		--end
	end

    NewHabilidadesText:SetFont("Fonts\\MORPHEUS.TTF", 32, "OUTLINE")
	NewHabilidadesText:SetText(namenewclasglobal1)
	NewHabilidadesText2:SetText("|CFFFFFFFF" .. namenewclasglobal2 .. "|r")
	
	local abilityIndex = 0;
	local abilityIndex2 = 0;
	if not classFileName then
		classFileName = "WARRIOR"
	end
	local tempText = _G["CLASS_INFO_"..classFileName..abilityIndex];
	abilityText = "";
	while ( tempText ) do
		abilityText = abilityText..tempText.."\n\n";
		abilityIndex = abilityIndex + 1;
		tempText = _G["CLASS_INFO_"..classFileName..abilityIndex];
	end 
	CharCreateClassInfoFrame.title:SetText(className);
	CharCreateClassInfoFrame.scrollFrame.scrollChild.bulletText:SetText(abilityText);
	CharCreateClassInfoFrame.scrollFrame.scrollChild.infoText:SetText(GetFlavorText("CLASS_"..strupper(classFileName), GetSelectedSex()).."|n|n");
	CharCreateClassInfoFrameScrollFrameScrollBar:SetValue(0);
	
	if ( CharacterCreateFrame.state == "CLASSRACE" ) then
		local race, _ = GetNameForRace();
		local DeleteClass = CharacterCreate_GetAllowedClassList(); 
		
			if(#DeleteClass > 0)then 
				local r = math.random(1,#DeleteClass)
				local RandomClass = DeleteClass[r]
				local itsOK = false;
				for k, v in pairs(DeleteClass) do 
					if(v == id)then
						itsOK = true;
						break
					end
				end 
			end
		if(itsOK == false)then 
			SetSelectedClass(RandomClass)
			id = RandomClass;
		end 
		NewHabilidadesText:Hide()
		NewHabilidadesText2:Hide()
	else 
		NewHabilidadesText:Show()
		NewHabilidadesText2:Show()
	end
end

function CharacterCreate_OnChar()
end

function CharacterCreate_OnKeyDown(key)
	if ( key == "ESCAPE" ) then
		CharacterCreate_Back();
	elseif ( key == "ENTER" ) then
		CharacterCreate_Forward();
	elseif ( key == "PRINTSCREEN" ) then
		Screenshot();
	end
end

function CharacterCreate_UpdateModel(self)
	UpdateCustomizationScene();
	self:AdvanceTime();
end

function CharacterCreate_Finish()
	PlaySound("gsCharacterCreationCreateChar");

	-- If something disabled this button, ignore this message.
	-- This can happen if you press enter while it's disabled, for example.
	if ( not CharCreateOkayButton:IsEnabled() ) then
		return;
	end

	if ( PAID_SERVICE_TYPE ) then
		GlueDialog_Show("CONFIRM_PAID_SERVICE");
	else
		-- if using templates, pandaren must pick a faction
		local _, faction = GetFactionForRace(CharacterCreate.selectedRace);
		--if ( IsUsingCharacterTemplate() and ( faction ~= "Alliance" and faction ~= "Horde" ) ) then
		--	CharacterTemplateConfirmDialog:Show();
		--else  
 		CharacterCreate_EnsureCreateSelection();

		local characterName = CharacterCreateNameEdit:GetText();
		local characterCount = 0;
		if ( GetNumCharacters ) then
			characterCount = tonumber(GetNumCharacters()) or 0;
		end
		local requestedSlot = characterCount + 1;
		if ( requestedSlot > REBORN_SLOT_FREE_FALLBACK ) then
			RebornSlotQuote_Request(characterName, requestedSlot);
		else
			if CharacterCreate_MonkSelectionIsBlocked() then
        message("该种族暂未开放武僧。 / Monk is not available for this race yet.");
        return;
    end
    if CharacterCreate_WitchDoctorSelectionIsBlocked() then
        message("巫医目前仅开放人类新建角色。"); return;
    end
    CreateCharacter(characterName);
		end
		--end
	end
end

function CharacterCreate_Back()
	if ( CharacterCreateFrame.state == "CUSTOMIZATION" ) then
		PlaySound("gsCharacterCreationCancel");
		CharacterCreateFrame.state = "CLASSRACE"
		CharCreateClassFrame:Show();
		CharCreateRaceFrame:Show();
		if ( CharCreateMaleButton and CharCreateFemaleButton ) then
			CharCreateMaleButton:Show()
			CharCreateFemaleButton:Show()
		end
		-- CharCreateMoreInfoButton:Show();
		CharCreateCustomizationFrame:Hide();
		CharCreatePreviewFrame:Hide();
		CharacterCreate_HideDracthyrCreationPreviewButtons();
		CharCreateOkayButton:SetText(NEXT);
		CharacterCreateNameEdit:Hide();
		CharacterCreateRandomName:Hide();
		CustomizationBG:Hide()
		CharCreateRandomizeButton:Hide()
		CustomizationLogoAlliance:Show()
		CustomizationTextAlliance:Show()
		CustomizationLogoHorde:Show()
		CustomizationTextHorde:Show()

		--back to awesome gear
		--SetSelectedPreviewGearType(1);

		-- back to normal camera
		--SetFaceCustomizeCamera(false);
--		GLOBAL_ZOOM_POS_22 = 0;
		if(CLASS_ALMACENADA > 0 )then 
			SetSelectedClass(CLASS_ALMACENADA); 	
			SetCharacterClass(CLASS_ALMACENADA); 	
		else 
			CLASS_ALMACENADA = 1;
			SetSelectedClass(CLASS_ALMACENADA); 	
			SetCharacterClass(CLASS_ALMACENADA); 
		end
--	local _, faction = GetFactionForRace(CharacterCreate.selectedRace);
--	if (faction == "Alliance") then
--		SetBackgroundModel(CharacterCreate, "HUMAN");
--	else
--		SetBackgroundModel(CharacterCreate, "ORC");
--	end

		return;
	end

	PlaySound("gsCharacterCreationCancel");
	CHARACTER_SELECT_BACK_FROM_CREATE = true;
	SetGlueScreen("charselect"); 
	 
end

function CharacterCreate_UpdateFacialHairCustomization()
	if ( GetFacialHairCustomization() == "NONE" ) then
		CharacterCustomizationButtonFrame5:Hide();
		--CharCreateRandomizeButton:SetPoint("TOP", "CharacterCustomizationButtonFrame5", "BOTTOM", 0, -5);
	else
		CharacterCustomizationButtonFrame5Text:SetText(_G["FACIAL_HAIR_"..GetFacialHairCustomization()]);
		CharacterCustomizationButtonFrame5:Show();
		--CharCreateRandomizeButton:SetPoint("TOP", "CharacterCustomizationButtonFrame5", "BOTTOM", 0, -5);
	end
end

function CharacterCreate_UpdateHairCustomization() 
	CharCreateCustomizationButton1:SetAlpha(1)
	CharCreateCustomizationButton2:SetAlpha(1)
	CharCreateCustomizationButton3:SetAlpha(1)
	CharCreateCustomizationButton4:SetAlpha(1)
	CharCreateCustomizationButton5:SetAlpha(1)
	if not _G["HAIR_"..GetHairCustomization().."_STYLE"] or _G["HAIR_"..GetHairCustomization().."_STYLE"] == "" then
		CharCreateCustomizationButton3:Hide()
		CharCreateCustomizationButton4:SetPoint("TOP", CharCreateCustomizationButton2, "BOTTOM", 0, -20)
	else
		CharCreateCustomizationButton3:Show()
		CharCreateCustomizationButton3.text:SetText(_G["HAIR_"..GetHairCustomization().."_STYLE"])
		--CharCreateCustomizationButton4:SetPoint("TOP", CharCreateCustomizationButton3, "BOTTOM", 0, -20)
	end

	if not _G["HAIR_"..GetHairCustomization().."_COLOR"] or _G["HAIR_"..GetHairCustomization().."_COLOR"] == "" then
		CharCreateCustomizationButton4:Hide()
		if CharCreateCustomizationButton3:IsShown() then
			CharCreateCustomizationButton5:SetPoint("TOP", CharCreateCustomizationButton4, "BOTTOM", 0, 0)
		else
			CharCreateCustomizationButton5:SetPoint("TOP", CharCreateCustomizationButton3, "BOTTOM", 0, 0)
		end
	else
		CharCreateCustomizationButton4:Show()
		CharCreateCustomizationButton4.text:SetText(_G["HAIR_"..GetHairCustomization().."_COLOR"])
		CharCreateCustomizationButton5:SetPoint("TOP", CharCreateCustomizationButton4, "BOTTOM", 0, 0)
	end

	if not _G["FACIAL_HAIR_"..GetFacialHairCustomization()] or _G["FACIAL_HAIR_"..GetFacialHairCustomization()] == "" then
		CharCreateCustomizationButton5:Hide()
	else
		CharCreateCustomizationButton5:Show()
		CharCreateCustomizationButton5.text:SetText(_G["FACIAL_HAIR_"..GetFacialHairCustomization()])
	end
	
	
	if(CharacterCreate.selectedRace == 17)then
		if ( GetSelectedSex() == SEX_FEMALE ) then
			CharCreateCustomizationButton5.text:SetText("耳环") --CharCreateCustomizationButton5.text:SetText("Earrings")
		end
		CharCreateCustomizationButton3.text:SetText("发型") -- CharCreateCustomizationButton3.text:SetText("Hair Style")
		CharCreateCustomizationButton5:SetPoint("TOP", CharCreateCustomizationButton4, "BOTTOM", 0, 0)
		CharCreateCustomizationButton4:Show()
		CharCreateCustomizationButton4.text:SetText("发色") -- CharCreateCustomizationButton4.text:SetText("Hair Color")
	end
	
	if(CharacterCreate.selectedRace == 19)then 
		if ( GetSelectedSex() == SEX_MALE ) then
			CharCreateCustomizationButton5:SetPoint("TOP", CharCreateCustomizationButton3, "BOTTOM", 0, 0)
			CharCreateCustomizationButton4:Hide()
		end
	end
	
	--if(CharacterCreate.selectedRace == 15)then 
		--CharCreateCustomizationButton5.text:SetText("Features")
	--end
	
	if(CharacterCreate.selectedRace == 18)then 
		CharCreateCustomizationButton5.text:SetText("Features")
	end
	
	if(CharacterCreate.selectedRace == 11)then 
		CharCreateCustomizationButton5.text:SetText("Features")
	end
	
	if(CharacterCreate.selectedRace == 21)then 
		CharCreateCustomizationButton5.text:SetText("Features")
	end

	if(CharacterCreate.selectedRace == 25)then
		CharCreateCustomizationButton2.text:SetText("脸型")
		CharCreateCustomizationButton3:Show()
		CharCreateCustomizationButton3.text:SetText("发型")
		CharCreateCustomizationButton4:Show()
		CharCreateCustomizationButton4.text:SetText("发色")
		CharCreateCustomizationButton5:Show()
		CharCreateCustomizationButton5.text:SetText("特色形状")
		CharCreateCustomizationButton5:SetPoint("TOP", CharCreateCustomizationButton4, "BOTTOM", 0, 0)
	end

	if(CharacterCreate.selectedRace == EXTRA_RACE_DRACTHYR_INDEX)then
		CharCreateCustomizationButton2.text:SetText("脸型")
		CharCreateCustomizationButton3:Show()
		CharCreateCustomizationButton3.text:SetText("发型")
		CharCreateCustomizationButton4:Show()
		CharCreateCustomizationButton4.text:SetText("发色")
		CharCreateCustomizationButton5:Show()
		if ( GetSelectedSex() == SEX_FEMALE ) then
			CharCreateCustomizationButton5.text:SetText("特征")
		else
			CharCreateCustomizationButton5.text:SetText("胡须")
		end
		CharCreateCustomizationButton5:SetPoint("TOP", CharCreateCustomizationButton4, "BOTTOM", 0, 0)
	end
	
	if(CharacterCreate.selectedRace == 6)then 
		CharCreateCustomizationButton5:Hide()
	end
	
	if(CharacterCreate.selectedRace == 7)then  
		if ( GetSelectedSex() == SEX_FEMALE ) then
			CharCreateCustomizationButton5.text:SetText("耳环") -- CharCreateCustomizationButton5.text:SetText("Earrings") 
		end
		CharCreateCustomizationButton3.text:SetText("发型") -- CharCreateCustomizationButton3.text:SetText("Hair Style")
		CharCreateCustomizationButton5:SetPoint("TOP", CharCreateCustomizationButton4, "BOTTOM", 0, 0)
		CharCreateCustomizationButton4:Show()
		CharCreateCustomizationButton4.text:SetText("发色") -- CharCreateCustomizationButton4.text:SetText("Hair Color")
	end
	
	if(CharacterCreate.selectedRace == 8)then  
		if ( GetSelectedSex() == SEX_FEMALE ) then
			CharCreateCustomizationButton5.text:SetText("Features")
		end
		CharCreateCustomizationButton5:SetPoint("TOP", CharCreateCustomizationButton3, "BOTTOM", 0, 0)
		CharCreateCustomizationButton4:Hide()
	end
	
	if(CharacterCreate.selectedRace == 900 or CharacterCreate.selectedRace == 2000)then   
		CharCreateCustomizationButton1:SetAlpha(0)
		CharCreateCustomizationButton2:SetAlpha(0)
		CharCreateCustomizationButton3:SetAlpha(0)
		CharCreateCustomizationButton4:SetAlpha(0)
		CharCreateCustomizationButton5:SetAlpha(0)
	end
	
	

end

function CharacterCreate_Forward()
	 
	if ( CharacterCreateFrame.state == "CLASSRACE" ) then
	
		CLASS_ALMACENADA = CharacterCreate.selectedClass;
		
		CharacterCreateFrame.state = "CUSTOMIZATION"
		PlaySound("gsCharacterSelectionCreateNew");
		CharCreateClassFrame:Hide();
		CharCreateRaceFrame:Hide(); 
		CharCreateCustomizationFrame:Show();
		CharacterCreate_UpdateHairCustomization() 
		CharacterTemplateConfirmDialog:Hide();

		CharCreate_PrepPreviewModels();
		CharacterCreate_ResetDracthyrCreationPreviewMode();
		CharacterCreate_UpdateDracthyrCreationPreviewButtons();
		
		if ( CharacterCreateFrame.customizationType ) then
			CharCreate_ResetFeaturesDisplay();
		else
			CharCreateSelectCustomizationType(1);
		end
		
		CharCreateOkayButton:SetText(FINISH);
		CharacterCreateNameEdit:Show();
		if ( ALLOW_RANDOM_NAME_BUTTON ) then
			CharacterCreateRandomName:Show();
		end

		if ( CharCreateMaleButton and CharCreateFemaleButton ) then
			CharCreateMaleButton:Hide()
			CharCreateFemaleButton:Hide()
		end
		CustomizationBG:Show()
		CharCreateRandomizeButton:Show()
		CustomizationLogoAlliance:Hide()
		CustomizationTextAlliance:Hide()
		CustomizationLogoHorde:Hide()
		CustomizationTextHorde:Hide()

 	local race, _ = GetNameForRace();
 	if(CLASS_ALMACENADA ~= 6)then 
		SetSelectedClass(CLASS_ALMACENADA);
 		SetCharacterClass(CLASS_ALMACENADA);
		
	--	SetSelectedClass(GetBGluSpecil(race,"NoClass"));
 	--	SetCharacterClass(GetBGluSpecil(race,"NoClass"));
	else
	
		--local namenewclasglobal1 = _G["CharCreateClassButton"..CLASS_ALMACENADA].nameFrame.text:GetText(); 
		--local namenewclasglobal2 = _G["CharCreateClassButton"..CLASS_ALMACENADA].tooltip2; 
		-- 
		--NewHabilidadesText:SetFont("Fonts\\MORPHEUS.TTF", 32, "OUTLINE")
		--NewHabilidadesText:SetText("Caballero de la muerte")
		--NewHabilidadesText2:SetText("|CFFFFFFFF" .. namenewclasglobal2 .. "|r")
		--
		--NewHabilidadesText:Show();
		--NewHabilidadesText2:Show();
	
 	end 
--	local backgroundFilenamS = GetBGluSpecil(race, "name");
--	OnUpdateStats();
--	SetBackgroundModel2(CharacterCreate, backgroundFilenamS);  

	else
		CharacterCreate_Finish();
	end

--				SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_zoom_humano\\UI_Alliance_zoom_humanob.m2");	
end

function CharCreateCustomizationFrame_OnShow ()
	-- reset size/tex coord to default to facilitate switching between genders for Pandaren
	CharCreateCustomizationFrameBanner:SetSize(BANNER_DEFAULT_SIZE[1], BANNER_DEFAULT_SIZE[2]);
	CharCreateCustomizationFrameBanner:SetTexCoord(BANNER_DEFAULT_TEXTURE_COORDS[1], BANNER_DEFAULT_TEXTURE_COORDS[2], BANNER_DEFAULT_TEXTURE_COORDS[3], BANNER_DEFAULT_TEXTURE_COORDS[4]);

	-- check each button and hide it if there are no values select
	local resize = 0;
	local lastGood = 0;
	local isSkinVariantHair = false --GetSkinVariationIsHairColor(CharacterCreate.selectedRace);
	local isDefaultSet = 0;
	local checkedButton = 1;

	-- check if this was set, if not, default to 1
	if ( CharacterCreateFrame.customizationType == 0 or CharacterCreateFrame.customizationType == nil ) then
		CharacterCreateFrame.customizationType = 1;
	end
	for i=1, NUM_CHAR_CUSTOMIZATIONS, 1 do
		if ( ( --[[GetNumFeatureVariationsForType(i)]]5 <= 1 ) or ( isSkinVariantHair and i == CHAR_CUSTOMIZE_HAIR_COLOR ) ) then
			resize = resize + 1;
			_G["CharCreateCustomizationButton"..i]:Hide();
		else
			_G["CharCreateCustomizationButton"..i]:Show();
			--_G["CharCreateCustomizationButton"..i]:SetChecked(0); -- we will handle default selection
			-- this must be done since a selected button can 'disappear' when swapping genders
			if ( isDefaultSet == 0 and CharacterCreateFrame.customizationType == i) then
				isDefaultSet = 1;
				checkedButton = i;
			end
			-- set your anchor to be the last good, this currently means button 1 HAS to be shown
			if (i > 1) then
				_G["CharCreateCustomizationButton"..i]:SetPoint( "TOP",_G["CharCreateCustomizationButton"..lastGood]:GetName() , "BOTTOM");
			end
			lastGood = i;
		end
	end

	if (isDefaultSet == 0) then
		CharacterCreateFrame.customizationType = lastGood;
		checkedButton = lastGood;
	end
	--_G["CharCreateCustomizationButton"..checkedButton]:SetChecked(1);

	if (resize > 0) then
	-- we need to resize and remap the banner texture
		local buttonx, buttony = CharCreateCustomizationButton1:GetSize()
		local screenamount = resize*buttony;
		print(screenamount);
		local frameX, frameY = CharCreateCustomizationFrameBanner:GetSize();
		local pctShrink = .2*resize;
		local uvXDefaultSize = BANNER_DEFAULT_TEXTURE_COORDS[2] - BANNER_DEFAULT_TEXTURE_COORDS[1];
		local uvYDefaultSize = BANNER_DEFAULT_TEXTURE_COORDS[4] - BANNER_DEFAULT_TEXTURE_COORDS[3];
		local newYUV = pctShrink*uvYDefaultSize + BANNER_DEFAULT_TEXTURE_COORDS[3];
		-- end coord stay the same
		CharCreateCustomizationFrameBanner:SetTexCoord(BANNER_DEFAULT_TEXTURE_COORDS[1], BANNER_DEFAULT_TEXTURE_COORDS[2], newYUV, BANNER_DEFAULT_TEXTURE_COORDS[4]);
		print(pctShrink);
		CharCreateCustomizationFrameBanner:SetSize(frameX, frameY - screenamount);
		print(CharCreateCustomizationFrameBanner:GetTexCoord());
	end

	--CharCreateRandomizeButton:SetPoint("TOP", _G["CharCreateCustomizationButton"..lastGood]:GetName(), "BOTTOM", 0, 0);
end

function CharacterClass_OnClick(self, id)
	if( self:IsEnabled() ) then
		PlaySound("gsCharacterCreationClass");
		local _,_,currClass = GetSelectedClass();
		if ( currClass ~= id ) then
			SetSelectedClass(id);
			SetCharacterClass(id);
			SetCharacterRace(CharacterCreate_EnsureSafeSelectedRace());
			CharacterChangeFixup();
		else
			self:SetChecked(1); 
		end
				if(CharacterCreate.selectedRace == 900 and id == 10 or CharacterCreate.selectedRace == 2000 and id == 10)then
				  	CharCreateClassButtoHero:SetChecked(1);
					CharCreateClassButton10:SetChecked(0);
				else
					CharCreateClassButtoHero:SetChecked(0);
				end
				
	else
		self:SetChecked(0);
	end
	CharacterCreate_ApplyStageI2ZandalariDefaultT14();
	CharacterCreate_HideLegacyHeroClassButton();
end

function CharacterRace_OnClick(self, id, forceSelect)
	if( self:IsEnabled() ) then
		id = CharacterCreate_GetSafeRaceId(id);
		if ( not id ) then
			self:SetChecked(0);
			return;
		end
		if ( not CharacterCreate_IsExtraRaceId(id) ) then
			CharacterCreate.customSelectedRace = nil;
			CharacterCreate.extraRaceButtonSelection = nil;
		end
		PlaySound("gsCharacterCreationClass");
		if ( GetSelectedRace() ~= id or forceSelect ) then
			SetSelectedRace(id);
			SetCharacterRace(id);
			--[[if ( id == TUSKARR_RACE_ID ) then
				SetCharacterGender(SEX_MALE);
			else]]
				SetCharacterGender(GetSelectedSex());
			--end
			SetCharacterCreateFacing(-15);
			CharacterCreateEnumerateClasses(GetAvailableClasses());
			local _,_,classIndex = GetSelectedClass();
			if ( PAID_SERVICE_TYPE ) then
				classIndex = PaidChange_GetCurrentClassIndex();
				SetSelectedClass(classIndex);	-- selecting a race would have changed class to default
			end
			SetCharacterClass(classIndex);

			-- Hair customization stuff
			CharacterCreate_UpdateHairCustomization();

			CharacterChangeFixup();
		else
			self:SetChecked(1);
		end
	else
		self:SetChecked(0);
	end
	CharacterCreate_ApplyStageI2ZandalariDefaultT14();
end

function SetCharacterGender(sex)
	local gender;
	local activeExtraKey = CharacterCreate_GetActiveRaceForButtons();
	local preservedExtraRace = CharacterCreate.selectedRace;
	if ( activeExtraKey == EXTRA_RACE_NAGA_KEY ) then
		preservedExtraRace = EXTRA_RACE_NAGA_INDEX;
	elseif ( activeExtraKey == EXTRA_RACE_DRACTHYR_KEY ) then
		preservedExtraRace = EXTRA_RACE_DRACTHYR_INDEX;
	end
	local preserveCustomRace = CharacterCreate_IsExtraRaceId(preservedExtraRace);

	if ( CharCreateMaleButton and CharCreateFemaleButton ) then
		if ( sex == SEX_MALE ) then
			CharCreateMaleButton:SetChecked(1);
			CharCreateFemaleButton:SetChecked(0);
		else
			CharCreateMaleButton:SetChecked(0);
			CharCreateFemaleButton:SetChecked(1);
		end
	end
	SetSelectedSex(sex);
	if ( CharacterCreateTooltip2 ) then
		CharacterCreateTooltip2:Hide();
	end

	-- Update race images to reflect gender
	if ( preserveCustomRace ) then
		SetSelectedRace(preservedExtraRace);
	end
	CharacterCreateEnumerateRaces(GetAvailableRaces());
	if ( preserveCustomRace ) then
		SetSelectedRace(preservedExtraRace);
		CharacterCreate.selectedRace = preservedExtraRace;
		CharacterCreate.customSelectedRace = preservedExtraRace;
		CharacterCreate.extraRaceButtonSelection = CharacterCreate_GetExtraRaceKeyForRaceId(preservedExtraRace);
	end
	CharacterCreateEnumerateClasses(GetAvailableClasses());
	if ( preserveCustomRace ) then
		SetCharacterRace(preservedExtraRace);
	else
		SetCharacterRace(CharacterCreate_EnsureSafeSelectedRace());
	end

	local _,_,classIndex = GetSelectedClass();
	if ( PAID_SERVICE_TYPE ) then
		classIndex = PaidChange_GetCurrentClassIndex();
		-- PandarenFactionButtons_SetTextures();
	end
	SetCharacterClass(classIndex);

	CharacterCreate_UpdateHairCustomization();
	CharacterChangeFixup();
	CharacterCreate_SetupExtraRaceButtons();
	CharacterCreate_StageBUpdateStaticRaceButtons();
	if ( preserveCustomRace ) then
		CharacterCreate_UpdateExtraRaceChecks(preservedExtraRace);
	end
	CharacterCreate_SetCurrentBackground(1);

	-- Update preview models if on customization step
	if ( CharCreatePreviewFrame:IsShown() ) then
		CharCreateCustomizationFrame_OnShow(); -- buttons may need to reset for dirty Pandarens
		CharCreate_PrepPreviewModels();
		CharCreate_ResetFeaturesDisplay();
	end
end

function CharacterCustomization_Left(id)
	PlaySound("gsCharacterCreationLook");
	CycleCharCustomization(id, -1);
	CharacterCreate_ReapplyStage80ModeNow("custom_left");
end

function CharacterCustomization_Right(id)
	PlaySound("gsCharacterCreationLook");
	CycleCharCustomization(id, 1);
	CharacterCreate_ReapplyStage80ModeNow("custom_right");
end

function CharacterCreate_GenerateRandomName(button)
	CharacterCreateNameEdit:SetText(GetRandomName());
end

function CharacterCreate_Randomize()
	PlaySound("gsCharacterCreationLook");
	RandomizeCharCustomization();
	CharCreate_ResetFeaturesDisplay();
	-- UI76G: native randomize preserves preview slots; no delayed gear writes.
end

function CharacterCreateRotateRight_OnUpdate(self)
	if ( self:GetButtonState() == "PUSHED" ) then
		SetCharacterCreateFacing(GetCharacterCreateFacing() + CHARACTER_FACING_INCREMENT);
		CharCreate_RotatePreviews();
	end
end

function CharacterCreateRotateLeft_OnUpdate(self)
	if ( self:GetButtonState() == "PUSHED" ) then
		SetCharacterCreateFacing(GetCharacterCreateFacing() - CHARACTER_FACING_INCREMENT);
		CharCreate_RotatePreviews();
	end
end

function SetButtonDesaturated(button, desaturated)
	if ( not button ) then
		return;
	end
	local icon = button:GetNormalTexture();
	if ( not icon ) then
		return;
	end

	icon:SetDesaturated(desaturated);
end

function GetFlavorText(tagname, sex)
	local primary, secondary;
	if ( sex == SEX_MALE ) then
		primary = "";
		secondary = "_FEMALE";
	else
		primary = "_FEMALE";
		secondary = "";
	end
	local text = _G[tagname..primary];
	if ( (text == nil) or (text == "") ) then
		text = _G[tagname..secondary];
	end
	return text;
end

function CharacterChangeFixup()
	if ( PAID_SERVICE_TYPE ) then
		-- no class changing as a paid service
		if(CLANDESTINOSERVER == false)then 
			CustomCharCreateRaceButton1:Disable(); -- Drusera Alianza
			SetButtonDesaturated(CustomCharCreateRaceButton1, 1); -- Drusera Alianza
			CustomCharCreateRaceButton1.nameFrame.text:SetAlpha(0.3); -- Drusera Alianza
			CustomCharCreateRaceButton2:Disable(); -- Drusera Horda
			SetButtonDesaturated(CustomCharCreateRaceButton2, 1); -- Drusera Horda
			CustomCharCreateRaceButton2.nameFrame.text:SetAlpha(0.3); -- Drusera Horda
			CustomCharCreateRaceButton3:Disable(); -- Doopel Alianza
			SetButtonDesaturated(CustomCharCreateRaceButton3, 1); -- Drusera Alianza
			CustomCharCreateRaceButton3.nameFrame.text:SetAlpha(0.3); -- Drusera Alianza
			CustomCharCreateRaceButton4:Disable(); -- Doopel Horda
			SetButtonDesaturated(CustomCharCreateRaceButton4, 1); -- Drusera Horda
			CustomCharCreateRaceButton4.nameFrame.text:SetAlpha(0.3); -- Drusera Horda 
			
			CustomCharCreateRaceButton1.tooltip = "|cffFF0000不兼容|r\n\n|cffFFFFFF你不能选择这个种族";
			CustomCharCreateRaceButton2.tooltip = "|cffFF0000不兼容|r\n\n|cffFFFFFF你不能选择这个种族";
			CustomCharCreateRaceButton3.tooltip = "|cffFF0000不兼容|r\n\n|cffFFFFFF你不能选择这个种族";
			CustomCharCreateRaceButton4.tooltip = "|cffFF0000不兼容|r\n\n|cffFFFFFF你不能选择这个种族";
			
		end
		for i=1, MAX_CLASSES_PER_RACE, 1 do
			if (CharacterCreate.selectedClass ~= i) then 
				local button = _G["CharCreateClassButton"..i];  
				_G["CharCreateClassButton"..i.."NormalTexture"]:SetAlpha(0.4);
				if(i == 1)then button.nameFrame.text:SetText("|CFF696969Guerrero|r")
				elseif(i == 2)then button.nameFrame.text:SetText("|CFF696969Paladín|r")
				elseif(i == 3)then button.nameFrame.text:SetText("|CFF696969Cazador|r")
				elseif(i == 4)then button.nameFrame.text:SetText("|CFF696969Pícaro|r")
				elseif(i == 5)then button.nameFrame.text:SetText("|CFF696969Sacerdote|r")
				elseif(i == 6)then button.nameFrame.text:SetText("|CFF696969|n|nCaballero|nde la Muerte|r")
				elseif(i == 7)then button.nameFrame.text:SetText("|CFF696969Chamán|r")
				elseif(i == 8)then button.nameFrame.text:SetText("|CFF696969Mago|r")
				elseif(i == 9)then button.nameFrame.text:SetText("|CFF696969Brujo|r")
				elseif(i == 10)then button.nameFrame.text:SetText("|CFF696969Druida|r")
				end
				button:Disable();
				SetButtonDesaturated(button, 1); 
				_G["CharCreateClassButton"..index.."DisableTexture"]:Show();  
			end
		end

			local fact = CharacterCreate.selectedRace;
			if(GLOBAL_RACE_CHANGE == 0)then 
				GLOBAL_RACE_CHANGE = CharacterCreate.selectedRace;  
			end 
			
			if ( PAID_SERVICE_TYPE == PAID_FACTION_CHANGE ) then
				local factionGlobalX = GetBGluSpecil(GLOBAL_RACE_CHANGE,"faction2");
				
				for i=1,NORMAL_RACE_BUTTON_LIMIT do
					local buttonrace = _G["CharCreateRaceButton"..i];
					if (GLOBAL_RACE_CHANGE ~= i) then 
						buttonrace.nameFrame.text:SetAlpha(0.3);
						buttonrace:Disable(); 
						buttonrace.tooltip = "|cffFF0000Incompatible|r\n\n|cffFFFFFFNo puedes escoger esta raza";
						SetButtonDesaturated(buttonrace, 1); 
						local clases = GetBGluSpecil(i,"Classes"); 
						local facto = GetBGluSpecil(i,"faction2"); 
							for k, v in pairs(clases) do
								if(v == CharacterCreate.selectedClass)then  
									if(factionGlobalX ~= facto)then
										buttonrace.nameFrame.text:SetAlpha(1);
										buttonrace:Enable(); 
										SetButtonDesaturated(buttonrace);
										buttonrace.tooltip = "|cffFFFFFFRaza compatible:|n|nPuedes cambiar a esta raza";
										
										if(CLANDESTINOSERVER == false)then 
											if(i == 900)then 
												CustomCharCreateRaceButton1:Enable(); 
												SetButtonDesaturated(CustomCharCreateRaceButton1);
												CustomCharCreateRaceButton1.nameFrame.text:SetAlpha(1); 
												CustomCharCreateRaceButton3:Enable(); 
												SetButtonDesaturated(CustomCharCreateRaceButton3); 
												CustomCharCreateRaceButton3.nameFrame.text:SetAlpha(1); 
												CustomCharCreateRaceButton1.tooltip = "|cffFFFFFFRaza compatible:|n|nPuedes cambiar a esta raza";
												CustomCharCreateRaceButton3.tooltip = "|cffFFFFFFRaza compatible:|n|nPuedes cambiar a esta raza";
											end
											if(i == 2000)then 
												CustomCharCreateRaceButton2:Enable(); 
												SetButtonDesaturated(CustomCharCreateRaceButton2);
												CustomCharCreateRaceButton2.nameFrame.text:SetAlpha(1); 
												CustomCharCreateRaceButton4:Enable(); 
												SetButtonDesaturated(CustomCharCreateRaceButton4);
												CustomCharCreateRaceButton4.nameFrame.text:SetAlpha(1); 
												CustomCharCreateRaceButton2.tooltip = "|cffFFFFFFRaza compatible:|n|nPuedes cambiar a esta raza";
												CustomCharCreateRaceButton4.tooltip = "|cffFFFFFFRaza compatible:|n|nPuedes cambiar a esta raza";
											end
										end
									end 
								end
							end 
					else
						buttonrace.nameFrame.text:SetAlpha(1);
					end
				end 
			
			elseif ( PAID_SERVICE_TYPE == PAID_RACE_CHANGE ) then
				
				local factionGlobalX = GetBGluSpecil(GLOBAL_RACE_CHANGE,"faction2");
				
				for i=1,NORMAL_RACE_BUTTON_LIMIT do
					local buttonrace = _G["CharCreateRaceButton"..i];
					if (GLOBAL_RACE_CHANGE ~= i) then 
						buttonrace.nameFrame.text:SetAlpha(0.3);
						buttonrace:Disable();
						buttonrace.tooltip = "|cffFF0000Incompatible|r\n\n|cffFFFFFFNo puedes escoger esta raza";
						SetButtonDesaturated(buttonrace, 1);
						local clases = GetBGluSpecil(i,"Classes"); 
						local facto = GetBGluSpecil(i,"faction2"); 
							for k, v in pairs(clases) do
								if(v == CharacterCreate.selectedClass)then  
									if(factionGlobalX == facto)then
										buttonrace.nameFrame.text:SetAlpha(1);
										buttonrace:Enable(); 
										SetButtonDesaturated(buttonrace);
										buttonrace.tooltip = "|cffFFFFFFRaza compatible:|n|nPuedes cambiar a esta raza";
										
										if(CLANDESTINOSERVER == false)then 
											if(i == 900)then 
												CustomCharCreateRaceButton1:Enable(); 
												SetButtonDesaturated(CustomCharCreateRaceButton1);
												CustomCharCreateRaceButton1.nameFrame.text:SetAlpha(1); 
												CustomCharCreateRaceButton3:Enable(); 
												SetButtonDesaturated(CustomCharCreateRaceButton3); 
												CustomCharCreateRaceButton3.nameFrame.text:SetAlpha(1); 
												CustomCharCreateRaceButton1.tooltip = "|cffFFFFFFRaza compatible:|n|nPuedes cambiar a esta raza";
												CustomCharCreateRaceButton3.tooltip = "|cffFFFFFFRaza compatible:|n|nPuedes cambiar a esta raza";
											end
											if(i == 2000)then 
												CustomCharCreateRaceButton2:Enable(); 
												SetButtonDesaturated(CustomCharCreateRaceButton2);
												CustomCharCreateRaceButton2.nameFrame.text:SetAlpha(1); 
												CustomCharCreateRaceButton4:Enable(); 
												SetButtonDesaturated(CustomCharCreateRaceButton4);
												CustomCharCreateRaceButton4.nameFrame.text:SetAlpha(1); 
												CustomCharCreateRaceButton2.tooltip = "|cffFFFFFFRaza compatible:|n|nPuedes cambiar a esta raza";
												CustomCharCreateRaceButton4.tooltip = "|cffFFFFFFRaza compatible:|n|nPuedes cambiar a esta raza";
											end
										end
									end 
								end
							end 
					else 
						buttonrace.nameFrame.text:SetAlpha(1);
					end
				end 
			
			
			elseif ( PAID_SERVICE_TYPE == PAID_CHARACTER_CUSTOMIZATION ) then
			
				for i=1,NORMAL_RACE_BUTTON_LIMIT do
					local buttonrace = _G["CharCreateRaceButton"..i];
					if (GLOBAL_RACE_CHANGE ~= i) then 
						buttonrace.tooltip = "|cffFF0000No permitido|r\n\n|cffFFFFFFSolo puedes editar a tu raza actual";
						buttonrace:Disable();
						SetButtonDesaturated(buttonrace, 1); 
						buttonrace.nameFrame.text:SetAlpha(0.2);
					else 
						buttonrace.nameFrame.text:SetAlpha(1);
					end 
				end 
			
			end
			CharacterCreateTooltip:Hide();
	else
		SetButtonDesaturated(CustomCharCreateRaceButton1);
		SetButtonDesaturated(CustomCharCreateRaceButton2);
		SetButtonDesaturated(CustomCharCreateRaceButton3);
		SetButtonDesaturated(CustomCharCreateRaceButton4);
		 
		CustomCharCreateRaceButton1.nameFrame.text:SetAlpha(1);  
		CustomCharCreateRaceButton3.nameFrame.text:SetAlpha(1);  
		CustomCharCreateRaceButton2.nameFrame.text:SetAlpha(1);  
		CustomCharCreateRaceButton4.nameFrame.text:SetAlpha(1); 
			
		for i=1,NORMAL_RACE_BUTTON_LIMIT do 
			local buttonrace = _G["CharCreateRaceButton"..i];
			if ( buttonrace ) then
				buttonrace.nameFrame.text:SetAlpha(1);
				buttonrace:Enable(); 
				SetButtonDesaturated(buttonrace);
			end
		end 
		
		CharCreateRaceButtonsFrame:SetAlpha(1);
		CharCreateClassFrame:SetAlpha(1);
	end
end

function CharCreateSelectCustomizationType(newType)
	-- deselect previous type selection
	if ( CharacterCreateFrame.customizationType and CharacterCreateFrame.customizationType ~= newType ) then
		--_G["CharCreateCustomizationButton"..CharacterCreateFrame.customizationType]:SetChecked(0);
	end
	--_G["CharCreateCustomizationButton"..newType]:SetChecked(1);
	CharacterCreateFrame.customizationType = newType;
	CharCreate_ResetFeaturesDisplay();

	--[[if (newType > 1) then
		SetFaceCustomizeCamera(true);
	else
		SetFaceCustomizeCamera(false);
	end]]
end

function CharCreate_ResetFeaturesDisplay()
	--SetPreviewFramesFeature(CharacterCreateFrame.customizationType);
	-- set the previews scrollframe container height
	-- since the first and the last previews need to be in the center position when scrolled all the way
	-- to the top or to the bottom, there will be gaps of height equal to 2 previews on each side
	local numTotalButtons = 4--GetNumFeatureVariations() + 4;
	CharCreatePreviewFrame.scrollFrame.container:SetHeight(numTotalButtons * PREVIEW_FRAME_HEIGHT - PREVIEW_FRAME_Y_OFFSET);

	for _, previewFrame in pairs(CharCreatePreviewFrame.previews) do
		previewFrame.featureType = 0;
	end

	CharCreate_DisplayPreviewModels();
end

function CharCreate_PrepPreviewModels(reloadModels)
	local displayFrame = CharCreatePreviewFrame;

	-- clear models if rebuildPreviews got flagged
	local rebuildPreviews = displayFrame.rebuildPreviews;
	displayFrame.rebuildPreviews = nil;

	-- need to reload models class was swapped to or from DK
	local classSwap = false;
	local _, class = GetSelectedClass();
	--[[if ( class == "DEATHKNIGHT" or displayFrame.lastClass == "DEATHKNIGHT" ) and ( class ~= displayFrame.lastClass ) then
		classSwap = true;
	end]]

	-- always clear the featureType
	for index, previewFrame in pairs(displayFrame.previews) do
		previewFrame.featureType = 0;
		-- force model reload if class changed
		if ( classSwap ) then
			previewFrame.race = nil;
			previewFrame.gender = nil;
		end
		if ( rebuildPreviews ) then
			--SetPreviewFrame(previewFrame.model:GetName(), index);
		end
	end
end

function CharCreate_DisplayPreviewModels(selectionIndex)
	if ( not selectionIndex ) then
		selectionIndex = featureIndex--GetSelectedFeatureVariation();
	end

	local displayFrame = CharCreatePreviewFrame;
	local previews = displayFrame.previews;
	local numVariations = 8--GetNumFeatureVariations();
	local currentFeatureType = CharacterCreateFrame.customizationType;

	local race = CharacterCreate_GetSafeRaceId(GetSelectedRace());
	local gender = GetSelectedSex();

	-- selection index is the center preview
	-- there are 2 previews above and 2 below, and will pad it out to 1 more on each side, for a total of 7 previews to set up
	for index = selectionIndex - 3, selectionIndex + 3 do
		-- there is empty space both at the beginning and at end of the list, each gap the height of 2 previews
		if ( index > 0 and index <= numVariations ) then
			local previewFrame = previews[index];
			-- create button if we don't have it yet
			if ( not previewFrame ) then
				previewFrame = CreateFrame("BUTTON", "PreviewFrame"..index, displayFrame.scrollFrame.container, "CharCreatePreviewFrameTemplate");
				-- index + 1 because of 2 gaps at the top and -1 for the current preview
				previewFrame:SetPoint("TOPLEFT", PREVIEW_FRAME_X_OFFSET, (index + 1) * -PREVIEW_FRAME_HEIGHT + PREVIEW_FRAME_Y_OFFSET);
				previewFrame.button.index = index;
				previews[index] = previewFrame;
				--SetPreviewFrame(previewFrame.model:GetName(), index);
				-- no texture as of yet
				--previewFrame:SetNormalTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
			end
			-- load model if needed, may have been cleared by different race/gender selection
			if ( previewFrame.race ~= race or previewFrame.gender ~= gender ) then
				--SetPreviewFrameModel(index);
				previewFrame.race = race;
				previewFrame.gender = gender;
				-- apply settings
				local model = previewFrame.model;
				--model:SetCustomCamera(cameraID);
				local scale = 1--model:GetWorldScale();
				--model:SetCameraTarget(config.tx * scale, config.ty * scale, config.tz * scale);
				--model:SetCameraDistance(config.distance * scale);
				-- Some customized clients intentionally disable SetPreviewFrameModel,
				-- so the template can exist without a child model.  Do not abort the
				-- whole customization OnShow chain in that valid state: otherwise the
				-- name edit box and both randomize buttons never get shown.
				local cx, cy, cz;
				if ( model and type(model.GetPosition) == "function" ) then
					pcall(function()
						cx, cy, cz = model:GetPosition();
					end);
				end
				-- model:SetPosition(cx-15, cy, cz)
				--model:SetCameraPosition(cx, cy, config.cz * scale);
				if ( model and type(model.SetLight) == "function" ) then
					pcall(model.SetLight, model, 1, 0, 0, 0, 0, 1, 1.0, 1.0, 1.0);
				end
			end
			-- need to reset the model if it was last used to preview a different feature
			if ( previewFrame.featureType ~= currentFeatureType ) then
				--ResetPreviewFrameModel(index);
				--ShowPreviewFrameVariation(index);
				previewFrame.featureType = currentFeatureType;
			end
			previewFrame:Show();
		else
			-- need to hide tail previews when going to features with fewer styles
			if ( previews[index] ) then
				previews[index]:Hide();
			end
		end
	end
	displayFrame.border.number:SetText("选项 "..selectionIndex.."                     "); -- displayFrame.border.number:SetText("Option "..selectionIndex.."                     ");
	displayFrame.selectionIndex = selectionIndex;
	CharCreate_RotatePreviews();
	CharCreatePreviewFrame_UpdateStyleButtons();
	-- scroll to center the selection
	if ( not displayFrame.animating ) then
		displayFrame.scrollFrame:SetVerticalScroll((selectionIndex - 1) * PREVIEW_FRAME_HEIGHT);
	end
end


function CharCreate_RotatePreviews()
	if ( CharCreatePreviewFrame:IsShown() ) then
		local facing = ((GetCharacterCreateFacing())/ -180) * math.pi;
		local previews = CharCreatePreviewFrame.previews;
		--CharCreatePreviewFrame.selectionIndex = 0;
		for index = CharCreatePreviewFrame.selectionIndex - 3, CharCreatePreviewFrame.selectionIndex + 3 do
			local previewFrame = previews[index];
			if ( previewFrame ) then -- and previewFrame.model:HasCustomCamera()
				--previewFrame.model:SetCameraFacing(facing);
			end
		end
	end
end

function CharCreate_ChangeFeatureVariation(delta)
	local numVariations = 8--GetNumFeatureVariations();
	local startIndex = featureIndex--GetSelectedFeatureVariation();
	local endIndex = startIndex + delta;
	if ( endIndex < 1 or endIndex > numVariations ) then
		return;
	end
	PlaySound("gsCharacterCreationClass");
	featureIndex = endIndex
	CharCreatePreviewFrame_SelectFeatureVariation(endIndex);
end

function CharCreatePreviewFrameButton_OnClick(self)
	PlaySound("gsCharacterCreationClass");
	CharCreatePreviewFrame_SelectFeatureVariation(self.index);
end

function CharCreatePreviewFrame_SelectFeatureVariation(endIndex)
	local self = CharCreatePreviewFrame;
	if ( self.animating ) then
		if ( not self.queuedIndex ) then
			self.queuedIndex = endIndex;
		end
	else
		local startIndex = featureIndex--GetSelectedFeatureVariation();
		--SelectFeatureVariation(endIndex);
		for i=1,endIndex do
			CycleCharCustomization(FeatureType, 1);
		end
		CharCreatePreviewFrame_UpdateStyleButtons();
		featureIndex = endIndex
		CharCreatePreviewFrame_StartAnimating(startIndex, endIndex);
	end
end

function CharCreatePreviewFrame_StartAnimating(startIndex, endIndex)
	local self = CharCreatePreviewFrame;
	if ( self.animating ) then
		return;
	else
		self.startIndex = startIndex;
		self.currentIndex = startIndex;
		self.endIndex = endIndex;
		self.queuedIndex = nil;
		self.direction = 1;
		if ( self.startIndex > self.endIndex ) then
			self.direction = -1;
		end
		self.movedTotal = 0;
		self.moveUntilUpdate = PREVIEW_FRAME_HEIGHT;
		self.animating = true;
	end
end

function CharCreatePreviewFrame_StopAnimating()
	local self = CharCreatePreviewFrame;
	if ( self.animating ) then
		self.animating = false;
	end
end

local ANIMATION_SPEED = 5;
function CharCreatePreviewFrame_OnUpdate(self, elapsed)
	if ( self.animating ) then
		local moveIncrement = PREVIEW_FRAME_HEIGHT * elapsed * ANIMATION_SPEED;
		self.movedTotal = self.movedTotal + moveIncrement;
		self.scrollFrame:SetVerticalScroll((self.startIndex - 1) * PREVIEW_FRAME_HEIGHT + self.movedTotal * self.direction);
		self.moveUntilUpdate = self.moveUntilUpdate - moveIncrement;
		if ( self.moveUntilUpdate <= 0 ) then
			self.currentIndex = self.currentIndex + self.direction;
			self.moveUntilUpdate = PREVIEW_FRAME_HEIGHT;
			-- reset movedTotal to account for rounding errors
			self.movedTotal = abs(self.startIndex - self.currentIndex) * PREVIEW_FRAME_HEIGHT;
			CharCreate_DisplayPreviewModels(self.currentIndex);
		end
		if ( self.currentIndex == self.endIndex ) then
			self.animating = false;
			CharCreate_DisplayPreviewModels();
			if ( self.queuedIndex ) then
				local newIndex = self.queuedIndex;
				self.queuedIndex = nil;
				--SelectFeatureVariation(newIndex);
				featureIndex = newIndex
				CycleCharCustomization(FeatureType, featureIndex);
				CharCreatePreviewFrame_UpdateStyleButtons();
				CharCreatePreviewFrame_StartAnimating(self.endIndex, newIndex);
			end
		end
	end
end

function CharCreatePreviewFrame_UpdateStyleButtons()
	local selectionIndex = math.random(1,5)--GetSelectedFeatureVariation();
	local numVariations = 8--GetNumFeatureVariations();
	if ( selectionIndex == 1 ) then
		CharCreateStyleUpButton:Enable();
		CharCreateStyleUpButton.arrow:SetDesaturated(true);
	else
		CharCreateStyleUpButton:Enable();
		CharCreateStyleUpButton.arrow:SetDesaturated(false);
	end
	if ( selectionIndex == numVariations ) then
		CharCreateStyleDownButton:Disable();
		CharCreateStyleDownButton.arrow:SetDesaturated(true);
	else
		CharCreateStyleDownButton:Disable(true);
		CharCreateStyleDownButton.arrow:SetDesaturated(false);
	end
end

local TotalTime = 0;
local KeepScrolling = nil;
local TIME_TO_SCROLL = 0.5;
function CharacterCreateWhileMouseDown_OnMouseDown(direction)
	TIME_TO_SCROLL = 0.5;
	TotalTime = 0;
	KeepScrolling = direction;
end
function CharacterCreateWhileMouseDown_OnMouseUp()
	KeepScrolling = nil;
end
function CharacterCreateWhileMouseDown_Update(elapsed)
	if ( KeepScrolling ) then
		TotalTime = TotalTime + elapsed;
		if ( TotalTime >= TIME_TO_SCROLL ) then
			CharCreate_ChangeFeatureVariation(KeepScrolling);
			TIME_TO_SCROLL = 0.25;
			TotalTime = 0;
		end
	end
end

-- pandaren stuff related to faction change
function CharCreate_EnableNextButton(enabled)
	local button = CharCreateOkayButton;
	if enabled then
		button:Enable();
	else
		button:Disable();
	end
	button.Arrow:SetDesaturated(not enabled);
	if enabled then
		button.TopGlow:Hide();
		button.BottomGlow:Hide();
	else
		button.TopGlow:Show();
		button.BottomGlow:Show();
	end
end
 







