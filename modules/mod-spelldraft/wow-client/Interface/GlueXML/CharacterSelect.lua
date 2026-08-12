
function CharSelect_Test()
	--CharSelectTestText:SetText(GetNumCharacters().."zzz");
end

CHARACTER_SELECT_ROTATION_START_X = nil;
CHARACTER_SELECT_INITIAL_FACING = nil;

CHARACTER_ROTATION_CONSTANT = 0.6;

MAX_CHARACTERS_DISPLAYED = 10;
MAX_CHARACTERS_PER_REALM = 50;

-- RebornWOW A.23.1R2: progression-mode badges for the character list.
-- The server preserves the three single paid-service flags and uses only
-- otherwise-unused multi-flag combinations for progression modes.
local REBORN_MODE_INFO = {
	classic = {
		icon = "Interface\\Icons\\INV_Misc_Book_09",
		iconSize = 15,
		zh = "经典职业模式",
		en = "Classic Class Mode",
		zhDesc = "保留原职业技能、训练师和原版天赋树。",
		enDesc = "Uses the original class, trainers, and talent trees.",
	},
	draft = {
		icon = "Interface\\Icons\\INV_Misc_Dice_02",
		iconSize = 19,
		zh = "随机抽卡模式",
		en = "Random Draft Mode",
		zhDesc = "升级时从随机技能卡片中选择技能。",
		enDesc = "Choose abilities from random spell cards while leveling.",
	},
	free = {
		icon = "Interface\\Icons\\Spell_Holy_MindVision",
		iconSize = 17,
		zh = "自由选择模式",
		en = "Free Pick Mode",
		zhDesc = "使用成长点数自由选择技能与天赋。",
		enDesc = "Spend progression points to choose spells and talents.",
	},
	pending = {
		icon = "Interface\\Icons\\INV_Misc_QuestionMark",
		iconSize = 15,
		zh = "尚未选择成长模式",
		en = "Progression Mode Not Selected",
		zhDesc = "进入游戏后必须先选择一种成长模式。",
		enDesc = "Choose a progression mode after entering the world.",
	},
};

local function Reborn_DecodeProgressionMode(PCC, PRC, PFC)
	if PCC and PFC and not PRC then return "classic"; end
	if PCC and PRC and not PFC then return "draft"; end
	if PRC and PFC and not PCC then return "free"; end
	if PCC and PRC and PFC then return "pending"; end
	return nil;
end

local function Reborn_SetModeBadge(slot, mode)
	local badge = _G["CharSelectCharacterButton"..slot.."ModeBadge"];
	if not badge then return; end
	badge.modeKey = mode;
	local info = mode and REBORN_MODE_INFO[mode];
	if not info then
		local hiddenIcon = badge.Icon or _G[badge:GetName().."Icon"];
		if hiddenIcon then hiddenIcon:SetTexture(nil); end
		badge:Hide();
		return;
	end
	local icon = badge.Icon or _G[badge:GetName().."Icon"];
	if icon then
		icon:SetTexture(info.icon);
		icon:SetWidth(info.iconSize or 16);
		icon:SetHeight(info.iconSize or 16);
		icon:SetTexCoord(0.07, 0.93, 0.07, 0.93);
	end
	badge:Show();
end

function CharacterSelectModeBadge_OnEnter(self)
	local info = self.modeKey and REBORN_MODE_INFO[self.modeKey];
	if not info then return; end
	GlueTooltip_SetOwner(self);
	-- GlueXML cannot read the in-world /sdlang preference reliably.  Display
	-- both languages here so the character list remains bilingual regardless
	-- of the executable locale selected by a custom client.
	GlueTooltip_SetText(info.zh.." / "..info.en.."\n|cffffffff"..info.zhDesc.."\n"..info.enDesc.."|r", nil, 1.0, 0.82, 0.12);
end

SelectBorroso = 1;

-- RebornWOW S.7.7.1 compatibility guard.
-- This 3.3.5 client does not export the optional Glue native used by
-- RealmList.lua.  The project has one compatible realm, so an absent native
-- must mean "not invalid" instead of raising a Lua error when Realm List opens.
if ( not IsInvalidLocale ) then
	function IsInvalidLocale()
		return false;
	end
end

-- Correct known malformed zone text returned to the character-list UI.
-- The client AreaTable entry and the installed Chinese font both contain
-- the correct glyph; this guard only changes the broken display value.
local CHARACTER_SELECT_ZONE_TEXT_FIXES = {
	["刀?山"] = "刀锋山",
	["刀？山"] = "刀锋山",
	["刀?山竞技场"] = "刀锋山竞技场",
	["刀？山竞技场"] = "刀锋山竞技场",
};

local function CharacterSelect_FixZoneText(zone)
	if ( not zone ) then
		return zone;
	end
	return CHARACTER_SELECT_ZONE_TEXT_FIXES[zone] or zone;
end

-- RebornWOW S.7.7: read-only account wallet on the character-select screen.
-- It reuses the authenticated S.7.5 quote bridge, so VP/DP come from the same
-- sahtout_site.user_currencies row used by the website and slot billing.
local RebornCharacterWallet = {
	frame = nil,
	pending = false,
	elapsed = 0,
	timeout = 0,
};

local RebornCharacterWallet_Request;

local function RebornCharacterWallet_GetAccountName()
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

local function RebornCharacterWallet_CreateText(parent, size, red, green, blue)
	local fontString = parent:CreateFontString(nil, "OVERLAY");
	fontString:SetFont("Fonts\\FRIZQT__.TTF", size, "OUTLINE");
	fontString:SetTextColor(red, green, blue);
	return fontString;
end

local function RebornCharacterWallet_EnsureFrame()
	if ( RebornCharacterWallet.frame ) then
		return RebornCharacterWallet.frame;
	end

	local frame = CreateFrame("Frame", "RebornCharacterWalletFrame", CharacterSelectUI);
	frame:SetWidth(320);
	frame:SetHeight(38);
	frame:SetPoint("TOP", CharacterSelectUI, "TOP", 0, -8);
	frame:SetFrameStrata("HIGH");
	frame:EnableMouse(true);
	frame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 24,
		edgeSize = 20,
		insets = { left = 6, right = 6, top = 6, bottom = 6 },
	});
	frame:SetBackdropColor(0.02, 0.03, 0.05, 0.92);
	frame:SetBackdropBorderColor(0.65, 0.52, 0.18, 1.00);

	frame.title = RebornCharacterWallet_CreateText(frame, 9, 1.00, 0.82, 0.00);
	frame.title:SetPoint("LEFT", frame, "LEFT", 13, 0);
	frame.title:SetWidth(102);
	frame.title:SetJustifyH("LEFT");
	frame.title:SetText("钱包 / Wallet");

	frame.vpIcon = frame:CreateTexture(nil, "ARTWORK");
	frame.vpIcon:SetWidth(16);
	frame.vpIcon:SetHeight(16);
	frame.vpIcon:SetPoint("LEFT", frame, "LEFT", 116, 0);
	frame.vpIcon:SetTexture("Interface\\Icons\\INV_Misc_Coin_01");
	frame.vpIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93);

	frame.vpText = RebornCharacterWallet_CreateText(frame, 11, 1.00, 0.82, 0.00);
	frame.vpText:SetPoint("LEFT", frame.vpIcon, "RIGHT", 4, 0);
	frame.vpText:SetWidth(72);
	frame.vpText:SetJustifyH("LEFT");
	frame.vpText:SetText("VP …");

	frame.dpIcon = frame:CreateTexture(nil, "ARTWORK");
	frame.dpIcon:SetWidth(16);
	frame.dpIcon:SetHeight(16);
	frame.dpIcon:SetPoint("LEFT", frame, "LEFT", 212, 0);
	frame.dpIcon:SetTexture("Interface\\Icons\\INV_Misc_Gem_Diamond_02");
	frame.dpIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93);
	frame.dpIcon:SetVertexColor(0.20, 0.85, 1.00);

	frame.dpText = RebornCharacterWallet_CreateText(frame, 11, 0.00, 0.80, 1.00);
	frame.dpText:SetPoint("LEFT", frame.dpIcon, "RIGHT", 4, 0);
	frame.dpText:SetWidth(76);
	frame.dpText:SetJustifyH("LEFT");
	frame.dpText:SetText("DP …");

	frame:SetScript("OnMouseDown", function()
		if ( RebornCharacterWallet_Request ) then
			RebornCharacterWallet_Request();
		end
	end);

	frame:SetScript("OnUpdate", function(self, elapsed)
		if ( not RebornCharacterWallet.pending ) then
			return;
		end

		RebornCharacterWallet.elapsed = RebornCharacterWallet.elapsed + elapsed;
		RebornCharacterWallet.timeout = RebornCharacterWallet.timeout + elapsed;
		if ( RebornCharacterWallet.timeout >= 8 ) then
			RebornCharacterWallet.pending = false;
			self.title:SetText("|cffff4040钱包超时 / Timeout|r");
			return;
		end
		if ( RebornCharacterWallet.elapsed < 0.10 ) then
			return;
		end
		RebornCharacterWallet.elapsed = 0;

		if ( not RebornSpectator_GetOnlineJson ) then
			RebornCharacterWallet.pending = false;
			self.title:SetText("|cffff4040钱包离线 / Offline|r");
			return;
		end

		local state, dpBalance, price, slot, generation, affordable, freeSlots, billingEnabled, vpBalance = RebornSpectator_GetOnlineJson(-7402);
		if ( state == "ready" ) then
			RebornCharacterWallet.pending = false;
			dpBalance = tonumber(dpBalance) or 0;
			vpBalance = tonumber(vpBalance) or 0;
			self.title:SetText("钱包 / Wallet");
			self.vpText:SetText("VP "..vpBalance);
			self.dpText:SetText("DP "..dpBalance);
		elseif ( state == "error" ) then
			RebornCharacterWallet.pending = false;
			self.title:SetText("|cffff4040钱包错误 / Error|r");
		end
	end);

	frame:Hide();
	RebornCharacterWallet.frame = frame;
	return frame;
end

RebornCharacterWallet_Request = function()
	local frame = RebornCharacterWallet_EnsureFrame();
	local account = RebornCharacterWallet_GetAccountName();
	local requestedSlot = math.max(1, math.min(50, (GetNumCharacters() or 0) + 1));

	frame.title:SetText("刷新中 / Refresh");
	frame.vpText:SetText("VP …");
	frame.dpText:SetText("DP …");
	frame:Show();
	RebornCharacterWallet.pending = false;
	RebornCharacterWallet.elapsed = 0;
	RebornCharacterWallet.timeout = 0;

	if ( account == "" or not RebornSpectator_GetOnlineJson ) then
		frame.title:SetText("|cffff4040钱包不可用 / N/A|r");
		return;
	end

	RebornSpectator_GetOnlineJson(-7400);
	local index;
	for index = 1, string.len(account) do
		RebornSpectator_GetOnlineJson(-(10000 + string.byte(account, index)));
	end
	RebornSpectator_GetOnlineJson(-(11000 + requestedSlot));
	local submitState = RebornSpectator_GetOnlineJson(-7401);
	if ( submitState == "pending" ) then
		RebornCharacterWallet.pending = true;
	else
		frame.title:SetText("|cffff4040请求无效 / Invalid|r");
	end
end

function CharacterSelect_OnLoad(self) 
 REALM_SIRION = GetServerName();
-- stat_1_custom:SetText(GetServerName());

	self:SetSequence(0);
	self:SetCamera(0);

	self.createIndex = 0;
	self.selectedIndex = 0;
	self.characterPage = 1;
	self.selectLast = 0;
	self.currentModel = nil;
	self:RegisterEvent("ADDON_LIST_UPDATE");
	self:RegisterEvent("CHARACTER_LIST_UPDATE");
	self:RegisterEvent("UPDATE_SELECTED_CHARACTER");
	self:RegisterEvent("SELECT_LAST_CHARACTER");
	self:RegisterEvent("SELECT_FIRST_CHARACTER");
	self:RegisterEvent("SUGGEST_REALM");
	self:RegisterEvent("FORCE_RENAME_CHARACTER");
	SetCharSelectModelFrame("CharacterSelect");

	-- Color edit box backdrops
	local backdropColor = DEFAULT_TOOLTIP_COLOR;
	CharacterSelectCharacterFrame:SetBackdropBorderColor(backdropColor[1], backdropColor[2], backdropColor[3]);
	CharacterSelectCharacterFrame:SetBackdropColor(backdropColor[4], backdropColor[5], backdropColor[6], 0.85);
	
end

function CharacterSelect_OnShow()
	--CharSelectTestButton:Show();
	-- request account data times from the server (so we know if we should refresh keybindings, etc...)
	ReadyForAccountDataTimes()
	RebornCharacterWallet_Request();
	
	local CurrentModel = CharacterSelect.currentModel;

	if ( CurrentModel ) then
		if CurrentModel ~= "MainMenu" then
		end
	end

	UpdateAddonButton();

	local serverName, isPVP, isRP = GetServerName();
	local connected = IsConnectedToServer();
	local serverType = "";
	if ( serverName ) then
		if( not connected ) then
			serverName = serverName.."\n("..SERVER_DOWN..")";
		end
		if ( isPVP ) then
			if ( isRP ) then
				serverType = RPPVP_PARENTHESES;
			else
				serverType = PVP_PARENTHESES;
			end
		elseif ( isRP ) then
			serverType = RP_PARENTHESES;
		end
		CharSelectCharacterName4:SetText(serverName.." "..serverType);
		CharSelectRealmName:SetText(serverName.." "..serverType);
		CharSelectRealmName:Show();
	else
		CharSelectCharacterName4:Hide();
		CharSelectRealmName:Hide();
	end

	if ( connected ) then
		GetCharacterListUpdate();
	else
		UpdateCharacterList();
	end

	-- Gameroom billing stuff (For Korea and China only)
	if ( SHOW_GAMEROOM_BILLING_FRAME ) then
		local paymentPlan, hasFallBackBillingMethod, isGameRoom = GetBillingPlan();
		if ( paymentPlan == 0 ) then
			-- No payment plan
			GameRoomBillingFrame:Hide();
			CharacterSelectRealmSplitButton:ClearAllPoints();
			CharacterSelectRealmSplitButton:SetPoint("TOP", CharacterSelectLogo, "BOTTOM", 0, -5);
		else
			local billingTimeLeft = GetBillingTimeRemaining();
			-- Set default text for the payment plan
			local billingText = _G["BILLING_TEXT"..paymentPlan];
			if ( paymentPlan == 1 ) then
				-- Recurring account
				billingTimeLeft = ceil(billingTimeLeft/(60 * 24));
				if ( billingTimeLeft == 1 ) then
					billingText = BILLING_TIME_LEFT_LAST_DAY;
				end
			elseif ( paymentPlan == 2 ) then
				-- Free account
				if ( billingTimeLeft < (24 * 60) ) then
					billingText = format(BILLING_FREE_TIME_EXPIRE, billingTimeLeft.." "..MINUTES_ABBR);
				end				
			elseif ( paymentPlan == 3 ) then
				-- Fixed but not recurring
				if ( isGameRoom == 1 ) then
					if ( billingTimeLeft <= 30 ) then
						billingText = BILLING_GAMEROOM_EXPIRE;
					else
						billingText = format(BILLING_FIXED_IGR, MinutesToTime(billingTimeLeft, 1));
					end
				else
					-- personal fixed plan
					if ( billingTimeLeft < (24 * 60) ) then
						billingText = BILLING_FIXED_LASTDAY;
					else
						billingText = format(billingText, MinutesToTime(billingTimeLeft));
					end	
				end
			elseif ( paymentPlan == 4 ) then
				-- Usage plan
				if ( isGameRoom == 1 ) then
					-- game room usage plan
					if ( billingTimeLeft <= 600 ) then
						billingText = BILLING_GAMEROOM_EXPIRE;
					else
						billingText = BILLING_IGR_USAGE;
					end
				else
					-- personal usage plan
					if ( billingTimeLeft <= 30 ) then
						billingText = BILLING_TIME_LEFT_30_MINS;
					else
						billingText = format(billingText, billingTimeLeft);
					end
				end
			end
			-- If fallback payment method add a note that says so
			if ( hasFallBackBillingMethod == 1 ) then
				billingText = billingText.."\n\n"..BILLING_HAS_FALLBACK_PAYMENT;
			end
			GameRoomBillingFrameText:SetText(billingText);
			GameRoomBillingFrame:SetHeight(GameRoomBillingFrameText:GetHeight() + 26);
			GlueFrameFadeIn(GameRoomBillingFrame, VX_FADE_REFRESH, GameRoomBillingFrame:Show());
			--GameRoomBillingFrame:Show();
			CharacterSelectRealmSplitButton:ClearAllPoints();
			CharacterSelectRealmSplitButton:SetPoint("TOP", GameRoomBillingFrame, "BOTTOM", 0, -10);
		end
	end

	if( IsTrialAccount() ) then
		CharacterSelectUpgradeAccountButton:Show();
	else
		CharacterSelectUpgradeAccountButton:Hide();
	end

	-- fadein the character select ui
	--GlueFrameFadeIn(CharacterSelectUI, CHARACTER_SELECT_FADE_IN)
	GlueFrameFadeIn(CharacterSelect, VX_FADE_LOAD); 

	RealmSplitCurrentChoice:Hide();
	RequestRealmSplitInfo();

	--Clear out the addons selected item
	GlueDropDownMenu_SetSelectedValue(AddonCharacterDropDown, ALL);
end

function CharacterSelect_OnHide()
	RebornCharacterWallet.pending = false;
	if ( RebornCharacterWallet.frame ) then
		RebornCharacterWallet.frame:Hide();
	end
	CharacterDeleteDialog:Hide();
	CharacterRenameDialog:Hide();
	if ( DeclensionFrame ) then
		DeclensionFrame:Hide();
	end
	SERVER_SPLIT_STATE_PENDING = -1;
end

function CharacterSelect_OnUpdate(elapsed)
	if ( SERVER_SPLIT_STATE_PENDING > 0 ) then
		CharacterSelectRealmSplitButton:Show();

		if ( SERVER_SPLIT_CLIENT_STATE > 0 ) then
			RealmSplit_SetChoiceText();
			RealmSplitPending:SetPoint("TOP", RealmSplitCurrentChoice, "BOTTOM", 0, -10);
		else
			RealmSplitPending:SetPoint("TOP", CharacterSelectRealmSplitButton, "BOTTOM", 0, 0);
			RealmSplitCurrentChoice:Hide();
		end

		if ( SERVER_SPLIT_STATE_PENDING > 1 ) then
			CharacterSelectRealmSplitButton:Disable();
			CharacterSelectRealmSplitButtonGlow:Hide();
			RealmSplitPending:SetText( SERVER_SPLIT_PENDING );
		else
			CharacterSelectRealmSplitButton:Enable();
			CharacterSelectRealmSplitButtonGlow:Show();
			local datetext = SERVER_SPLIT_CHOOSE_BY.."\n"..SERVER_SPLIT_DATE;
			RealmSplitPending:SetText( datetext );
		end

		if ( SERVER_SPLIT_SHOW_DIALOG and not GlueDialog:IsShown() ) then
			SERVER_SPLIT_SHOW_DIALOG = false;
			local dialogString = format(SERVER_SPLIT,SERVER_SPLIT_DATE);
			if ( SERVER_SPLIT_CLIENT_STATE > 0 ) then
				local serverChoice = RealmSplit_GetFormatedChoice(SERVER_SPLIT_REALM_CHOICE);
				local stringWithDate = format(SERVER_SPLIT,SERVER_SPLIT_DATE);
				dialogString = stringWithDate.."\n\n"..serverChoice;
				GlueDialog_Show("SERVER_SPLIT_WITH_CHOICE", dialogString);
			else
				GlueDialog_Show("SERVER_SPLIT", dialogString);
			end
		end
	else
		CharacterSelectRealmSplitButton:Hide();
	end

	-- Account Msg stuff
	if ( (ACCOUNT_MSG_NUM_AVAILABLE > 0) and not GlueDialog:IsShown() ) then
		if ( ACCOUNT_MSG_HEADERS_LOADED ) then
			if ( ACCOUNT_MSG_BODY_LOADED ) then
				local dialogString = AccountMsg_GetHeaderSubject( ACCOUNT_MSG_CURRENT_INDEX ).."\n\n"..AccountMsg_GetBody();
				GlueDialog_Show("ACCOUNT_MSG", dialogString);
			end
		end
	end
end

function CharacterSelect_OnKeyDown(self,key)
		--		CHANGE_RACE_CUSTOM_ENABLE = CharacterSelect.selectedRace;
	if ( key == "ESCAPE" ) then
		CharacterSelect_Exit();
	elseif ( key == "ENTER" ) then
		CharacterSelect_EnterWorld();
	elseif ( key == "PRINTSCREEN" ) then
		Screenshot();
	elseif ( key == "UP" or key == "LEFT" ) then
		local numChars = GetNumCharacters();
		if ( numChars > 1 ) then
			if ( self.selectedIndex > 1 ) then
				CharacterSelect_SelectCharacter(self.selectedIndex - 1);
				CharacterSelectUI.id = self.selectedIndex - 1;
				--GlueFrameFadeOut(CharacterSelect, VX_FADE_REFRESH, CharacterSelectButton_OnClick_Wait);

			else
				CharacterSelect_SelectCharacter(numChars);
				CharacterSelectUI.id = numChars;
				--GlueFrameFadeOut(CharacterSelect, VX_FADE_REFRESH, CharacterSelectButton_OnClick_Wait);
			end
		end
	elseif ( arg1 == "DOWN" or arg1 == "RIGHT" ) then
		local numChars = GetNumCharacters();
		if ( numChars > 1 ) then
			if ( self.selectedIndex < GetNumCharacters() ) then
				CharacterSelect_SelectCharacter(self.selectedIndex + 1);
				CharacterSelectUI.id = self.selectedIndex + 1;
				--GlueFrameFadeOut(CharacterSelect, VX_FADE_REFRESH, CharacterSelectButton_OnClick_Wait);
			else
				CharacterSelect_SelectCharacter(1);
				CharacterSelectUI.id = 1;
				--GlueFrameFadeOut(CharacterSelect, VX_FADE_REFRESH, CharacterSelectButton_OnClick_Wait);
			end
		end
	end
end

function CharacterSelect_OnEventO()
local numChars = GetNumCharacters();
local index = 1;
local coords;
	if ( SelectBorroso == 0 ) then
		CharSelectCharacterName:SetAlpha(0);
		CharacterSelectCharacterFrame:SetAlpha(0);
		CharacterSelectCharacterFrame:SetPoint("TOPRIGHT", 5000, -8);
		CharSelectCharacterName2:SetPoint("CENTER", 330, 100);
		CharSelectCharacterName2:SetAlpha(1);
		CharSelectCharacterName2:SetFont("Fonts\\MORPHEUS.ttf", 43, "OUTLINE");
		CharSelectCharacterName2:Show();
		CharSelectCharacterName3:SetPoint("TOP", "CharSelectCharacterName2", 0, 120);
		CharSelectCharacterName3:SetFont("Fonts\\MORPHEUS.ttf", 83, "OUTLINE");
		CharSelectCharacterName3:Show();
		CharSelectCharacterName4:Show();
		CharacterSelectRotateLeft:SetAlpha(0);
		CharacterSelectRotateRight:SetAlpha(0);
		CharacterSelectAddonsButton:SetAlpha(0);
		CharSelectEnterWorldButton:SetAlpha(0);
		CharacterSelectBackButton:SetAlpha(0);
		CharacterSelectAddonsButton:Disable();
		CharacterSelectBackButton:Disable();
		OptionsButton2:Hide();
		OcultarName2:Show();
		DesenfoBoton:SetText("显示所有");
		
	elseif ( SelectBorroso == 1 ) then
		CharSelectCharacterName:SetAlpha(1);
		CharacterSelectCharacterFrame:SetAlpha(1);
		CharacterSelectCharacterFrame:SetPoint("TOPRIGHT", -5, -8);
		CharSelectCharacterName2:SetPoint("CENTER", 330, 100);
		CharSelectCharacterName2:SetFont("Fonts\\MORPHEUS.ttf", 43, "OUTLINE");
		CharSelectCharacterName2:SetAlpha(0);
		CharSelectCharacterName2:Hide();
		CharSelectCharacterName3:SetPoint("TOP", "CharSelectCharacterName2", 0, 120);
		CharSelectCharacterName3:SetFont("Fonts\\MORPHEUS.ttf", 83, "OUTLINE");
		CharSelectCharacterName3:Hide();
		CharSelectCharacterName4:Hide();
		CharacterSelectRotateLeft:SetAlpha(1);
		CharacterSelectRotateRight:SetAlpha(1);
		CharacterSelectAddonsButton:SetAlpha(1);
		CharSelectEnterWorldButton:SetAlpha(1);
		CharacterSelectBackButton:SetAlpha(1);
		OptionsButton2:Show();
		CharacterSelectAddonsButton:Enable();
		CharacterSelectBackButton:Enable();
		OcultarName2:Hide();
		DesenfoBoton:SetText("隐藏所有");
	end


end
function CharacterSelect_OnEvent(self, event, ...)
	if ( event == "ADDON_LIST_UPDATE" ) then
		UpdateAddonButton();
	elseif ( event == "CHARACTER_LIST_UPDATE" ) then
		UpdateCharacterList();
		CharSelectCharacterName:SetText(GetCharacterInfo(self.selectedIndex));
	elseif ( event == "UPDATE_SELECTED_CHARACTER" ) then
		local index = ...;
		if ( index == 0 ) then
			CharSelectCharacterName:SetText("");
			CharSelectCharacterName2:SetText("");
			CharSelectCharacterName3:SetText("");
		else
			local name, race, class, level, zone, sex, ghost, PCC, PRC, PFC = GetCharacterInfo(index);
			local raza, faccion = GetBGluSpecil(race, "faction");
			
			CharacterSelect_SetFaction(faccion, CharSelectEnterWorldButton);
			CharacterSelect_SetFaction(faccion, CharacterSelectAddonsButton);
			CharacterSelect_SetFaction(faccion, CharacterSelectBackButton);
			CharacterSelect_SetFaction(faccion, OptionsButton2);
			CharacterSelect_SetFaction(faccion, OcultarName2);
			CharacterSelect_SetFaction(faccion, DesenfoBoton);
			CharacterSelect_SetFaction(faccion, CharacterSelectRealmSplitButton);
			CharacterSelect_SetFaction(faccion, CharacterSelectDeleteButton);
			CharacterSelect_SetFaction(faccion, CharSelectChangeRealmButton);
			CharacterSelect_SetFaction(faccion, CharSelectCreateCharacterButton);
			CharacterSelect_SetFaction(faccion, CharSelectPreviousPageButton);
			CharacterSelect_SetFaction(faccion, CharSelectNextPageButton);
			CharSelectCreateCharacterButton:SetText("创建角色")
			CharacterSelectDeleteButton:SetText("删除角色")
	
			CharSelectCharacterName:SetText(GetCharacterInfo(index));
			CharSelectCharacterName3:SetText(GetCharacterInfo(index));
			self.selectedIndex = index;
			local selectedPage = math.floor((index - 1) / MAX_CHARACTERS_DISPLAYED) + 1;
			if ( selectedPage ~= self.characterPage ) then
				self.characterPage = selectedPage;
				UpdateCharacterList(true);
			end
			
			if class == nil then
			CharSelectCharacterName2:SetText("");
			else
			CharSelectCharacterName2:SetText("|n" .. class .."|n等级 " .. level);
			end
		end
		UpdateCharacterSelection(self);
	elseif ( event == "SELECT_LAST_CHARACTER" ) then
		self.selectLast = 1;
	elseif ( event == "SELECT_FIRST_CHARACTER" ) then
		CharacterSelect_SelectCharacter(1, 1);
	elseif ( event == "SUGGEST_REALM" ) then
		local category, id = ...;
		local name = GetRealmInfo(category, id);
		if ( name ) then
			SetGlueScreen("charselect");
			ChangeRealm(category, id);
		else
			if ( RealmList:IsShown() ) then
				RealmListUpdate();
			else
				GlueFrameFadeIn(RealmList, VX_FADE_REFRESH, RealmList:Show());
				--RealmList:Show();
			end
		end
	elseif ( event == "FORCE_RENAME_CHARACTER" ) then
		local message = ...;
		GlueFrameFadeIn(CharacterRenameDialog, VX_FADE_REFRESH, CharacterRenameDialog:Show());
		--CharacterRenameDialog:Show();
		CharacterRenameText1:SetText(_G[message]);
	end
end

function CharacterSelect_UpdateModel(self)
	UpdateSelectionCustomizationScene();
	self:AdvanceTime();
end

function CharacterSelect_GetPageCount()
	local numChars = GetNumCharacters();
	local pageCount = math.floor((numChars + MAX_CHARACTERS_DISPLAYED - 1) / MAX_CHARACTERS_DISPLAYED);
	if ( pageCount < 1 ) then
		pageCount = 1;
	end
	return pageCount;
end

function CharacterSelect_SetPage(page)
	local pageCount = CharacterSelect_GetPageCount();
	if ( page < 1 ) then
		page = 1;
	elseif ( page > pageCount ) then
		page = pageCount;
	end
	if ( page == CharacterSelect.characterPage ) then
		return;
	end
	CharacterSelect.characterPage = page;
	local firstCharacter = (page - 1) * MAX_CHARACTERS_DISPLAYED + 1;
	if ( firstCharacter <= GetNumCharacters() ) then
		CharacterSelect.selectedIndex = firstCharacter;
	end
	UpdateCharacterList();
end

function CharacterSelect_UpdatePageControls()
	local pageCount = CharacterSelect_GetPageCount();
	if ( CharacterSelect.characterPage < 1 ) then
		CharacterSelect.characterPage = 1;
	elseif ( CharacterSelect.characterPage > pageCount ) then
		CharacterSelect.characterPage = pageCount;
	end
	CharSelectPageText:SetFormattedText("%d / %d 页", CharacterSelect.characterPage, pageCount);
	if ( CharacterSelect.characterPage > 1 ) then
		CharSelectPreviousPageButton:Enable();
	else
		CharSelectPreviousPageButton:Disable();
	end
	if ( CharacterSelect.characterPage < pageCount ) then
		CharSelectNextPageButton:Enable();
	else
		CharSelectNextPageButton:Disable();
	end
end

function UpdateCharacterSelection(self)
	for slot=1, MAX_CHARACTERS_DISPLAYED, 1 do
		_G[_G["CharSelectCharacterButton"..slot]:GetName().."OnSelect"]:Hide();
	end

	local pageStart = (self.characterPage - 1) * MAX_CHARACTERS_DISPLAYED + 1;
	local visibleSlot = self.selectedIndex - pageStart + 1;
	if ( (visibleSlot > 0) and (visibleSlot <= MAX_CHARACTERS_DISPLAYED) ) then
		_G[_G["CharSelectCharacterButton"..visibleSlot]:GetName().."OnSelect"]:Show();
	end
end

function UpdateCharacterList(skipSelection)
	local numChars = GetNumCharacters();
	local pageCount = CharacterSelect_GetPageCount();
	if ( CharacterSelect.characterPage < 1 ) then
		CharacterSelect.characterPage = 1;
	elseif ( CharacterSelect.characterPage > pageCount ) then
		CharacterSelect.characterPage = pageCount;
	end

	local pageStart = (CharacterSelect.characterPage - 1) * MAX_CHARACTERS_DISPLAYED + 1;
	local pageEnd = pageStart + MAX_CHARACTERS_DISPLAYED - 1;
	if ( pageEnd > numChars ) then
		pageEnd = numChars;
	end
	local visibleCount = pageEnd - pageStart + 1;
	if ( visibleCount < 0 ) then
		visibleCount = 0;
	end
	if ( numChars >= MAX_CHARACTERS_DISPLAYED ) then
		_G["CharacterSelectCharacterFrame"]:SetHeight(647);
	else
		_G["CharacterSelectCharacterFrame"]:SetHeight(647 - (9 - numChars) * 57);
	end

	local slot = 1;
	for characterIndex=pageStart, pageEnd, 1 do
		local name, race, class, level, zone, sex, ghost, PCC, PRC, PFC = GetCharacterInfo(characterIndex);
		local progressionMode = Reborn_DecodeProgressionMode(PCC, PRC, PFC);
		local clase, color = IgnorarSexoClase(class, race)
		local raza, faccion = GetBGluSpecil(race, "faction")
		
	--	CharSelectCharacterName2:SetText("|n" .. clase .."|nDe nivel " .. level);
		if name == "Debug" then
			DisconnectFromServer();
		else
			local button = _G["CharSelectCharacterButton"..slot];
			button:SetID(characterIndex);
			
				button.alianza:SetDesaturated(true);
				button.horde:SetDesaturated(true);
				button.alianza:Hide();
				button.horde:Hide(); 
				button.alianza:SetAlpha(0.6);
				
			if ( not name ) then
				button:SetText("ERROR - Tell Jeremy");
			else
				if(faccion == "Alliance")then 
					button.alianza:Show();
				else
					button.horde:Show();
				end
				
				if ( not zone ) then
					if(race == "Pandaren")then 
						zone = "La Isla Errante";
					else 
						zone = "";
					end
					
				end
				_G["CharSelectCharacterButton"..slot.."ButtonTextName"]:SetText(name);
				
				if( ghost ) then
					_G["CharSelectCharacterButton"..slot.."ButtonTextInfo"]:SetFormattedText(CHARACTER_SELECT_INFO_GHOST, level, class);
				else
						_G["CharSelectCharacterButton"..slot.."ButtonTextInfo"]:SetText("|cffffffffLevel "..level.."|r "..color..class.."|r");
				--		_G["CharSelectCharacterButton"..index.."ButtonTextInfo"]:SetFormattedText(CHARACTER_SELECT_INFO_ALL, race, level);
				end
				_G["CharSelectCharacterButton"..slot.."ButtonTextLocation"]:SetText(CharacterSelect_FixZoneText(zone));
			end
			button:Show();

			-- setup paid service buttons
			_G["CharSelectCharacterCustomize"..slot]:SetID(characterIndex);
			_G["CharSelectRaceChange"..slot]:SetID(characterIndex);
			_G["CharSelectFactionChange"..slot]:SetID(characterIndex);
			_G["CharSelectCharacterCustomize"..slot]:Hide();
			_G["CharSelectRaceChange"..slot]:Hide();
			_G["CharSelectFactionChange"..slot]:Hide();
			Reborn_SetModeBadge(slot, progressionMode);
			if ( progressionMode ) then
				-- Combined markers belong to progression mode, not paid services.
			elseif ( PFC ) then
				_G["CharSelectFactionChange"..slot]:Show();
			elseif ( PRC ) then
				_G["CharSelectRaceChange"..slot]:Show();
			elseif ( PCC ) then
				_G["CharSelectCharacterCustomize"..slot]:Show();
			end

			slot = slot + 1;
		end
	end

	if ( numChars == 0 ) then
		CharacterSelectDeleteButton:Disable();
		CharSelectEnterWorldButton:Disable();
		CharacterSelectRotateLeft:Hide();
		CharacterSelectRotateRight:Hide();
	else
		CharacterSelectDeleteButton:Enable();
		CharSelectEnterWorldButton:Enable();
		CharacterSelectRotateLeft:Show();
		CharacterSelectRotateRight:Show();
	end

	CharacterSelect.createIndex = numChars + 1;
	CharSelectCreateCharacterButton:Hide();	
	
	local connected = IsConnectedToServer();
	for hiddenSlot=slot, MAX_CHARACTERS_DISPLAYED, 1 do
		local button = _G["CharSelectCharacterButton"..hiddenSlot];
		_G["CharSelectCharacterCustomize"..hiddenSlot]:Hide();
		_G["CharSelectFactionChange"..hiddenSlot]:Hide();
		_G["CharSelectRaceChange"..hiddenSlot]:Hide();
		Reborn_SetModeBadge(hiddenSlot, nil);
		button:Hide();
	end
	if ( connected and numChars < MAX_CHARACTERS_PER_REALM ) then
		CharSelectCreateCharacterButton:SetID(CharacterSelect.createIndex);
		CharSelectCreateCharacterButton:Show();
	end
	CharacterSelect_UpdatePageControls();

	if ( numChars == 0 ) then
		CharacterSelect.selectedIndex = 0;
		CharacterSelect_SelectCharacter(CharacterSelect.selectedIndex, 1);
		return;
	end

	if ( CharacterSelect.selectLast == 1 ) then
		CharacterSelect.selectLast = 0;
		CharacterSelect.selectedIndex = numChars;
		CharacterSelect.characterPage = math.floor((numChars - 1) / MAX_CHARACTERS_DISPLAYED) + 1;
		UpdateCharacterList(true);
		CharacterSelect_SelectCharacter(numChars, 1);
		return;
	end

	if ( (CharacterSelect.selectedIndex == 0) or (CharacterSelect.selectedIndex > numChars) ) then
		CharacterSelect.selectedIndex = 1;
	end
	if ( not skipSelection ) then
		local selectedPage = math.floor((CharacterSelect.selectedIndex - 1) / MAX_CHARACTERS_DISPLAYED) + 1;
		if ( selectedPage ~= CharacterSelect.characterPage ) then
			CharacterSelect.characterPage = selectedPage;
			UpdateCharacterList(true);
		end
		CharacterSelect_SelectCharacter(CharacterSelect.selectedIndex, 1);
	else
		UpdateCharacterSelection(CharacterSelect);
	end
end

function CharacterSelectButton_OnClick(self)
	local id = self:GetID();
	if ( id ~= CharacterSelect.selectedIndex ) then
		CharacterSelectUI.id = id;
		GlueFrameFadeOut(CharacterSelect, VX_FADE_REFRESH, CharacterSelectButton_OnClick_Wait);
		--CharacterSelect_SelectCharacter(id);
	end
end

function CharacterSelectButton_OnClick_Wait()
	CharacterSelect_SelectCharacter(CharacterSelectUI.id);
	CharacterSelectUI.id = nil;
	GlueFrameFadeIn(CharacterSelect, VX_FADE_REFRESH);
end

function CharacterSelectButton_OnDoubleClick(self)
	local id = self:GetID();
	if ( id ~= CharacterSelect.selectedIndex ) then
		CharacterSelect_SelectCharacter(id);
	end
	CharacterSelect_EnterWorld();
end

function CharacterSelect_TabResize(self)
	local buttonMiddle = _G[self:GetName().."Middle"];
	local buttonMiddleDisabled = _G[self:GetName().."MiddleDisabled"];
	local width = self:GetTextWidth() - 8;
	local leftWidth = _G[self:GetName().."Left"]:GetWidth();
	buttonMiddle:SetWidth(width);
	buttonMiddleDisabled:SetWidth(width);
	self:SetWidth(width + (2 * leftWidth));
end

function CharacterSelect_SelectCharacter(id, noCreate)
	if ( id == CharacterSelect.createIndex ) then
		if ( not noCreate ) then
			PlaySound("gsCharacterSelectionCreateNew");
			SetGlueScreen("charcreate");
		end
	else
		CharacterSelect.currentModel = GetSelectBackgroundModel(id);
		SetBackgroundModel(CharacterSelect,CharacterSelect.currentModel);

		SelectCharacter(id);
	end
end

function CharacterDeleteDialog_OnShow()
	local name, race, class, level = GetCharacterInfo(CharacterSelect.selectedIndex);
	if name == "You" or name == "Found" or name == "Asecret" or name == "Area" then
		DisconnectFromServer();
	else
		CharacterDeleteText1:SetFormattedText(CONFIRM_CHAR_DELETE, name, level, class);
		CharacterDeleteBackground:SetHeight(16 + CharacterDeleteText1:GetHeight() + CharacterDeleteText2:GetHeight() + 23 + CharacterDeleteEditBox:GetHeight() + 8 + CharacterDeleteButton1:GetHeight() + 16);
		CharacterDeleteButton1:Disable();
	end
end

function CharacterSelect_EnterWorld()
	PlaySound("gsCharacterSelectionEnterWorld");
	StopGlueAmbience();
	--GlueFrameFadeOut(CharacterSelect, VX_FADE_UNLOAD, CharacterSelect_EnterWorld_Wait);
	EnterWorld();
end

function CharacterSelect_EnterWorld_Wait()
	if VX_SOUNDBG then
		SetCVar("Sound_EnableSoundWhenGameIsInBG", VX_SOUNDBG);
		VX_SOUNDBG = nil;
	end
	EnterWorld();
end

function CharacterSelect_Exit()
	PlaySound("gsCharacterSelectionExit");
	DisconnectFromServer();
	--GlueFrameFadeOut(CharacterSelect, VX_FADE_UNLOAD, CharacterSelect_Exit_Wait);
	SetGlueScreen("login");
end

function CharacterSelect_Exit_Wait()
	SetGlueScreen("login");
end

function CharacterSelect_AccountOptions()
	PlaySound("gsCharacterSelectionAcctOptions");
end

function CharacterSelect_TechSupport()
	PlaySound("gsCharacterSelectionAcctOptions");
	LaunchURL("http://localhost/");
end

function CharacterSelect_Delete()
	PlaySound("gsCharacterSelectionDelCharacter");
	if ( CharacterSelect.selectedIndex > 0 ) then
		GlueFrameFadeIn(CharacterDeleteDialog, VX_FADE_REFRESH, CharacterDeleteDialog:Show());
		--CharacterDeleteDialog:Show();
	end
end

function CharacterSelect_ChangeRealm()
	PlaySound("gsCharacterSelectionDelCharacter");
	RequestRealmList(1);
	GlueFrameFadeIn(RealmList, VX_FADE_REFRESH, RealmList:Show());
end

function CharacterSelectFrame_OnMouseDown(button)
	if ( button == "LeftButton" ) then
		CHARACTER_SELECT_ROTATION_START_X = GetCursorPosition();
		CHARACTER_SELECT_INITIAL_FACING = GetCharacterSelectFacing();
	end
end

function CharacterSelectFrame_OnMouseUp(button)
	if ( button == "LeftButton" ) then
		CHARACTER_SELECT_ROTATION_START_X = nil
	end
end

function CharacterSelectFrame_OnUpdate()
	if ( CHARACTER_SELECT_ROTATION_START_X ) then
		local x = GetCursorPosition();
		local diff = (x - CHARACTER_SELECT_ROTATION_START_X) * CHARACTER_ROTATION_CONSTANT;
		CHARACTER_SELECT_ROTATION_START_X = GetCursorPosition();
		SetCharacterSelectFacing(GetCharacterSelectFacing() + diff);
	end
end

function CharacterSelectRotateRight_OnUpdate(self)
	if ( self:GetButtonState() == "PUSHED" ) then
		SetCharacterSelectFacing(GetCharacterSelectFacing() + CHARACTER_FACING_INCREMENT);
	end
end

function CharacterSelectRotateLeft_OnUpdate(self)
	if ( self:GetButtonState() == "PUSHED" ) then
		SetCharacterSelectFacing(GetCharacterSelectFacing() - CHARACTER_FACING_INCREMENT);
	end
end

function CharacterSelect_ManageAccount()
	PlaySound("gsCharacterSelectionAcctOptions");
	LaunchURL(AUTH_NO_TIME_URL);
end

function RealmSplit_GetFormatedChoice(formatText)
	if ( SERVER_SPLIT_CLIENT_STATE == 1 ) then
		realmChoice = SERVER_SPLIT_SERVER_ONE;
	else
		realmChoice = SERVER_SPLIT_SERVER_TWO;
	end
	return format(formatText, realmChoice);
end

function RealmSplit_SetChoiceText()
	RealmSplitCurrentChoice:SetText( RealmSplit_GetFormatedChoice(SERVER_SPLIT_CURRENT_CHOICE) );
	RealmSplitCurrentChoice:Show();
end

function CharacterSelect_PaidServiceOnClick(self, button, down, service)
	PAID_SERVICE_CHARACTER_ID = self:GetID();
	PAID_SERVICE_TYPE = service;
	PlaySound("gsCharacterSelectionCreateNew");
	GlueFrameFadeOut(CharacterSelect, VX_FADE_UNLOAD, CharacterSelect_CharacterCreate_Wait);
	--SetGlueScreen("charcreate");
end

function CharacterSelect_CharacterCreate_Wait()
	SetGlueScreen("charcreate");
end


function CharacterSelect_DeathKnightSwap(self)
	--if ( CharacterSelect.currentModel == "DEATHKNIGHT" ) then
	--	if (self.currentModel ~= "DEATHKNIGHT") then
	--		self.currentModel = "DEATHKNIGHT";
	--		self:SetNormalTexture("Interface\\Glues\\Common\\Glue-Panel-Button-Up-Blue");
	--		self:SetPushedTexture("Interface\\Glues\\Common\\Glue-Panel-Button-Down-Blue");
	--		self:SetHighlightTexture("Interface\\Glues\\Common\\Glue-Panel-Button-Highlight-Blue");
	--	end
	--else
	--	if (self.currentModel == "DEATHKNIGHT") then
	--		self.currentModel = nil;
	--		self:SetNormalTexture("Interface\\Glues\\Common\\Glue-Panel-Button-Up");
	--		self:SetPushedTexture("Interface\\Glues\\Common\\Glue-Panel-Button-Down");
	--		self:SetHighlightTexture("Interface\\Glues\\Common\\Glue-Panel-Button-Highlight");
	--	end
	--end
end
