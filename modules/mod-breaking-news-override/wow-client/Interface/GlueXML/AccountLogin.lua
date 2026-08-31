FADE_IN_TIME = 2;
DEFAULT_TOOLTIP_COLOR = {0.8, 0.8, 0.8, 0.09, 0.09, 0.09};
MAX_PIN_LENGTH = 10;

_clickable = {
	["ruRU"] = "Используемый сервер (Выберите):",
	["enUS"] = "点击选择服务器:",
	["enGB"] = "Server used (Select):",
	["frFR"] = "Serveur utilisé (sélectionner):",
	["deDE"] = "Verwendeter Server (Auswahl):",
	["esES"] = "Servidor utilizado (Seleccionar):",
	["esMX"] = "Servidor utilizado (Seleccionar):",
	["koKR"] = "사용된 서버(선택하려면 클릭):",
	["zhCN"] = "点击选择服务器",
	["enCN"] = "点击选择服务器",
	["zhTW"] = "點擊選擇服務器",
}

-- Some mixed GlueXML packages run the parent ModelFFX OnLoad before all named
-- child controls have been published as globals.  Do not assume those controls
-- already exist; finish their visual/form initialization shortly afterwards.
local ACCOUNT_LOGIN_DEFERRED_INIT_INTERVAL = 0.05;
local ACCOUNT_LOGIN_DEFERRED_INIT_LIMIT = 100;
local AccountLoginDeferredInitFrame;
local BreakingNewsLoginDragPosition;

local function BreakingNews_LoginPageEnabled()
	local mode = tonumber(BREAKING_NEWS_DISPLAY_MODE) or 3;
	return mode == 1 or mode == 3;
end

local function BreakingNews_SaveLoginPosition(self)
	self:StopMovingOrSizing();
	if ( not BREAKING_NEWS_LOGIN_REMEMBER_DRAGGED_POSITION or not AccountLogin ) then
		return;
	end

	local frameX, frameY = self:GetCenter();
	local parentX, parentY = AccountLogin:GetCenter();
	if ( frameX and frameY and parentX and parentY ) then
		BreakingNewsLoginDragPosition = {
			x = frameX - parentX,
			y = frameY - parentY,
		};
	end
end

local function BreakingNews_ConfigureLoginDragging(enabled)
	if ( not ServerAlertFrame ) then
		return;
	end
	if ( not enabled ) then
		ServerAlertFrame:StopMovingOrSizing();
	end

	ServerAlertFrame:SetScript("OnDragStart", nil);
	ServerAlertFrame:SetScript("OnDragStop", nil);
	ServerAlertFrame:SetMovable(enabled and true or false);
	ServerAlertFrame:EnableMouse(enabled and true or false);

	if ( enabled ) then
		ServerAlertFrame:RegisterForDrag("LeftButton");
		ServerAlertFrame:SetScript("OnDragStart", function(self)
			self:StartMoving();
		end);
		ServerAlertFrame:SetScript("OnDragStop", BreakingNews_SaveLoginPosition);
	end

	if ( ServerAlertFrame.SetClampedToScreen ) then
		ServerAlertFrame:SetClampedToScreen(true);
	end
end

local function BreakingNews_AnchorLoginPage()
	ServerAlertFrame:ClearAllPoints();
	if ( BREAKING_NEWS_LOGIN_MOVABLE and
		 BREAKING_NEWS_LOGIN_REMEMBER_DRAGGED_POSITION and
		 BreakingNewsLoginDragPosition ) then
		ServerAlertFrame:SetPoint(
			"CENTER", AccountLogin, "CENTER",
			BreakingNewsLoginDragPosition.x,
			BreakingNewsLoginDragPosition.y);
		return;
	end

	ServerAlertFrame:SetPoint(
		BREAKING_NEWS_LOGIN_POINT or "TOPLEFT",
		AccountLogin,
		BREAKING_NEWS_LOGIN_RELATIVE_POINT or "TOPLEFT",
		tonumber(BREAKING_NEWS_LOGIN_OFFSET_X) or 10,
		tonumber(BREAKING_NEWS_LOGIN_OFFSET_Y) or -130);
end

local function BreakingNews_ShowLoginPage(body)
	if ( not BreakingNews_LoginPageEnabled() or not ServerAlertFrame or
		 not ServerAlertText or not ServerAlertTitle or not AccountLogin ) then
		if ( ServerAlertFrame ) then
			ServerAlertFrame:Hide();
		end
		return;
	end

	ServerAlertFrame:SetParent(AccountLogin);
	BreakingNews_AnchorLoginPage();
	ServerAlertFrame:SetFrameStrata("DIALOG");
	BreakingNews_ConfigureLoginDragging(BREAKING_NEWS_LOGIN_MOVABLE == true);
	ServerAlertTitle:SetText(BREAKING_NEWS_LOGIN_TITLE or "服务器条款 / Server Terms");
	ServerAlertText:SetText(body or BREAKING_NEWS_LOGIN_HTML or "");
	if ( ServerAlertScrollFrame ) then
		ServerAlertScrollFrame:SetVerticalScroll(0);
	end
	ServerAlertFrame:Show();
end

local function AccountLogin_StyleEditBox(editBox)
	if ( not editBox ) then
		return;
	end

	local backdropColor = DEFAULT_TOOLTIP_COLOR;
	editBox:SetBackdropBorderColor(backdropColor[1], backdropColor[2], backdropColor[3]);
	editBox:SetBackdropColor(backdropColor[4], backdropColor[5], backdropColor[6]);
end

local function AccountLogin_ApplyEditBoxStyles()
	AccountLogin_StyleEditBox(AccountLoginAccountEdit);
	AccountLogin_StyleEditBox(AccountLoginPasswordEdit);
	AccountLogin_StyleEditBox(AccountLoginTokenEdit);
	AccountLogin_StyleEditBox(TokenEnterDialogBackgroundEdit);
end

local function AccountLogin_InitializeLoginForm()
	-- These are the controls touched unconditionally by the original OnShow.
	-- Returning false schedules a bounded retry instead of aborting GlueXML.
	if ( not AccountLoginAccountEdit or not AccountLoginPasswordEdit or
		 not AccountLoginTokenEdit or not AccountLoginLoginButton or
		 not AccountLoginDropDown ) then
		return false;
	end

	AccountLogin_ApplyEditBoxStyles();

	local serverName = GetServerName();
	if ( serverName and AccountLoginRealmName and AccountServerListButton ) then
		AccountLoginRealmName:SetText(serverName);
		AccountServerListButton:SetText(GetCVar("realmlist"));
		AccountServerListButton:SetWidth(AccountServerListButton:GetTextWidth());
	end
	if ( serverName == "" and AccountLoginRealmName ) then
		AccountLoginRealmName:SetText(_clickable[GetLocale()]);
	end

	local accountName = GetSavedAccountName() or "";
	if ( AccountLoginAccountEdit:GetText() == "" ) then
		AccountLoginAccountEdit:SetText(accountName);
	end
	AccountLoginTokenEdit:SetText("");
	if ( accountName ~= "" and GetUsesToken() ) then
		AccountLoginTokenEdit:Show();
	else
		AccountLoginTokenEdit:Hide();
	end

	AccountLogin_SetupAccountListDDL();
	if ( accountName == "" ) then
		AccountLogin_FocusAccountName();
	else
		AccountLogin_FocusPassword();
	end

	if ( AccountLoginUpgradeAccountButton ) then
		if ( IsTrialAccount() ) then
			AccountLoginUpgradeAccountButton:Show();
		else
			AccountLoginUpgradeAccountButton:Hide();
		end
	end

	return true;
end

local function AccountLogin_StopDeferredInitialization()
	if ( AccountLoginDeferredInitFrame ) then
		AccountLoginDeferredInitFrame:Hide();
		AccountLoginDeferredInitFrame:SetScript("OnUpdate", nil);
	end
end

local function AccountLogin_StartDeferredInitialization()
	if ( not AccountLoginDeferredInitFrame ) then
		AccountLoginDeferredInitFrame = CreateFrame("Frame");
	end

	AccountLoginDeferredInitFrame.elapsed = 0;
	AccountLoginDeferredInitFrame.attempts = 0;
	AccountLoginDeferredInitFrame:SetScript("OnUpdate", function(self, elapsed)
		self.elapsed = self.elapsed + elapsed;
		if ( self.elapsed < ACCOUNT_LOGIN_DEFERRED_INIT_INTERVAL ) then
			return;
		end

		self.elapsed = 0;
		self.attempts = self.attempts + 1;
		if ( AccountLogin_InitializeLoginForm() or self.attempts >= ACCOUNT_LOGIN_DEFERRED_INIT_LIMIT ) then
			AccountLogin_StopDeferredInitialization();
		end
	end);
	AccountLoginDeferredInitFrame:Show();
end

function AccountLogin_OnLoad(self)
	if ( TOSFrame ) then
		TOSFrame.noticeType = "EULA";
	end

	self:RegisterEvent("SHOW_SERVER_ALERT");
	self:RegisterEvent("SHOW_SURVEY_NOTIFICATION");
	self:RegisterEvent("CLIENT_ACCOUNT_MISMATCH");
	self:RegisterEvent("CLIENT_TRIAL");
	self:RegisterEvent("SCANDLL_ERROR");
	self:RegisterEvent("SCANDLL_FINISHED");

	local versionType, buildType, version, internalVersion, date = GetBuildInfo();
	if ( AccountLoginVersion ) then
		AccountLoginVersion:SetFormattedText(VERSION_TEMPLATE, versionType, version, internalVersion, buildType, date);
	end

	-- Color edit box backdrops
	AccountLogin_ApplyEditBoxStyles();

	--[[self:SetCamera(0);
	self:SetSequence(0);

	if (IsStreamingTrial()) then
		AccountLoginCinematicsButton:Disable();
		AccountLogin:SetModel("Interface\\Glues\\Models\\UI_MainMenu\\UI_MainMenu.m2");
	else
		AccountLogin:SetModel("Interface\\Glues\\Models\\UI_MainMenu_Northrend\\UI_MainMenu_Northrend.m2");
	end]]
end

function AccountLogin_OnShow(self)

	ShowScene(self);
	PlaySceneMusic();
	ShowSceneLogo();

	self:SetSequence(0);
	--[[PlayGlueMusic(CurrentGlueMusic);
	PlayGlueAmbience(GlueAmbienceTracks["DARKPORTAL"], 4.0);]]

	-- Try to show the EULA or the TOS
	AccountLogin_ShowUserAgreements();
	BreakingNews_ShowLoginPage();

	if ( not AccountLogin_InitializeLoginForm() ) then
		AccountLogin_StartDeferredInitialization();
	end

	ACCOUNT_MSG_NUM_AVAILABLE = 0;
	ACCOUNT_MSG_PRIORITY = 0;
	ACCOUNT_MSG_HEADERS_LOADED = false;
	ACCOUNT_MSG_BODY_LOADED = false;
	ACCOUNT_MSG_CURRENT_INDEX = nil;
end

function AccountLogin_OnHide(self)
	AccountLogin_StopDeferredInitialization();
	if ( ServerAlertFrame ) then
		BreakingNews_ConfigureLoginDragging(false);
		ServerAlertFrame:Hide();
	end
	--Stop the sounds from the login screen (like the dragon roaring etc)
	StopAllSFX( 1.0 );
	if ( not (AccountLoginSaveAccountName and AccountLoginSaveAccountName:GetChecked()) ) then
		SetSavedAccountList("");
	end
end

-- Some customized clients occasionally reach GlueXML before the native
-- CheckButton frame type has been registered.  Use a regular Button in XML
-- and provide the small checked-state API expected by the original login
-- code so the remember-account control still works on those cold starts.
function AccountLoginSaveAccountName_SetChecked(self, checked)
	self.accountNameChecked = checked and 1 or nil;
	local checkTexture = _G[self:GetName().."Check"];
	if ( checkTexture ) then
		if ( self.accountNameChecked ) then
			checkTexture:Show();
		else
			checkTexture:Hide();
		end
	end
end

function AccountLoginSaveAccountName_GetChecked(self)
	return self.accountNameChecked;
end

function AccountLoginSaveAccountName_OnLoad(self)
	self.SetChecked = AccountLoginSaveAccountName_SetChecked;
	self.GetChecked = AccountLoginSaveAccountName_GetChecked;
	self:SetChecked(GetSavedAccountName() ~= "");
end

function AccountLoginSaveAccountName_OnClick(self)
	self:SetChecked(not self:GetChecked());
	if ( self:GetChecked() ) then
		PlaySound("igMainMenuOptionCheckBoxOn");
	else
		PlaySound("igMainMenuOptionCheckBoxOff");
	end
end

function AccountLogin_FocusPassword()
	if ( AccountLoginPasswordEdit ) then
		AccountLoginPasswordEdit:SetFocus();
	end
end

function AccountLogin_FocusAccountName()
	if ( AccountLoginAccountEdit ) then
		AccountLoginAccountEdit:SetFocus();
	end
end

function AccountLogin_OnKeyDown(key)
	if ( key == "ESCAPE" ) then
		if ( ConnectionHelpFrame:IsShown() ) then
			ConnectionHelpFrame:Hide();
			AccountLoginUI:Show();
		elseif ( SurveyNotificationFrame:IsShown() ) then
			-- do nothing
		else
			AccountLogin_Exit();
		end
	elseif ( key == "ENTER" ) then
		if ( not TOSAccepted() ) then
			return;
		elseif ( TOSFrame:IsShown() or ConnectionHelpFrame:IsShown() ) then
			return;
		elseif ( SurveyNotificationFrame:IsShown() ) then
			AccountLogin_SurveyNotificationDone(1);
		end
		AccountLogin_Login();
	elseif ( key == "PRINTSCREEN" ) then
		Screenshot();
	end
end

function AccountLogin_OnEvent(event, arg1, arg2, arg3)
	if ( event == "SHOW_SERVER_ALERT" ) then
		if ( BREAKING_NEWS_ACCEPT_NATIVE_SERVER_ALERT ) then
			BreakingNews_ShowLoginPage(arg1);
		end
	elseif ( event == "SHOW_SURVEY_NOTIFICATION" ) then
		AccountLogin_ShowSurveyNotification();
	elseif ( event == "CLIENT_ACCOUNT_MISMATCH" ) then
		local accountExpansionLevel = arg1;
		local installationExpansionLevel = arg2;
		if ( accountExpansionLevel == 1 ) then
			GlueDialog_Show("CLIENT_ACCOUNT_MISMATCH", CLIENT_ACCOUNT_MISMATCH_BC);
		else
			GlueDialog_Show("CLIENT_ACCOUNT_MISMATCH", CLIENT_ACCOUNT_MISMATCH_LK);
		end
	elseif ( event == "CLIENT_TRIAL" ) then
		GlueDialog_Show("CLIENT_TRIAL");
	elseif ( event == "SCANDLL_ERROR" ) then
		GlueDialog:Hide();
		ScanDLLContinueAnyway();
		AccountLoginUI:Show();
	elseif ( event == "SCANDLL_FINISHED" ) then
		if ( arg1 == "OK" ) then
			GlueDialog:Hide();
			AccountLoginUI:Show();
		else
			AccountLogin.hackURL = _G["SCANDLL_URL_"..arg1];
			AccountLogin.hackName = arg2;
			AccountLogin.hackType = arg1;
			local formatString = _G["SCANDLL_MESSAGE_"..arg1];
			if ( arg3 == 1 ) then
				formatString = _G["SCANDLL_MESSAGE_HACKNOCONTINUE"];
			end
			local msg = format(formatString, AccountLogin.hackName, AccountLogin.hackURL);
			if ( arg3 == 1 ) then
				GlueDialog_Show("SCANDLL_HACKFOUND_NOCONTINUE", msg);
			else
				GlueDialog_Show("SCANDLL_HACKFOUND", msg);
			end
			PlaySoundFile("Sound\\Creature\\MobileAlertBot\\MobileAlertBotIntruderAlert01.wav");
		end
	end
end

function AccountLogin_Login()
	-- GlueXML can invoke this handler before every named XML child has been
	-- published as a Lua global.  Let the bounded initializer finish instead of
	-- throwing a nil error and leaving the login state machine spinning.
	if ( not AccountLoginAccountEdit or not AccountLoginPasswordEdit ) then
		AccountLogin_StartDeferredInitialization();
		return;
	end

	-- AccountLoginLoginButton:Disable()
	--if not AccountLoginForceLogin:GetChecked() then PlaySound("gsLogin");end
	DefaultServerLogin(AccountLoginAccountEdit:GetText(), AccountLoginPasswordEdit:GetText());
	--AccountLoginPasswordEdit:SetText("");

	if ( AccountLoginSaveAccountName and AccountLoginSaveAccountName:GetChecked() ) then
		SetSavedAccountName(AccountLoginAccountEdit:GetText());
	else
		SetSavedAccountName("");
		SetUsesToken(false);
	end

	if ( AccountLoginForceLogin and AccountLoginForceLogin:GetChecked() ) then
		if not VX_SOUNDBG then
			VX_SOUNDBG = GetCVar("Sound_EnableSoundWhenGameIsInBG");
		end
		SetCVar("Sound_EnableSoundWhenGameIsInBG",0);
	end
end

function AccountLogin_SetFrameShown(frame, shown)
	-- Some custom glue combinations can omit agreement controls.
	-- Treat those controls as optional so the login screen can continue loading.
	if ( not frame ) then
		return;
	end
	if ( shown ) then
		frame:Show();
	else
		frame:Hide();
	end
end

function AccountLogin_TOS()
	if ( not GlueDialog:IsShown() ) then
		PlaySound("gsLoginNewAccount");
		AccountLoginUI:Hide();
		TOSFrame:Show();
		TOSScrollFrameScrollBar:SetValue(0);
		AccountLogin_SetFrameShown(TOSScrollFrame, true);
		TOSFrameTitle:SetText(TOS_FRAME_TITLE);
		AccountLogin_SetFrameShown(TOSText, true);
	end
end

function AccountLogin_ManageAccount()
	PlaySound("gsLoginNewAccount");

	local vx_url = AUTH_NO_TIME_URL;
	if vx.ServerList then
		for i = 1, #vx.ServerList, 1 do
			if vx.ServerList[i].Host and vx.ServerList[i].Host == GetCVar("realmlist") and vx.ServerList[i].ManageAccount then
				vx_url = vx.ServerList[i].ManageAccount;
				break
			end
		end
	end

	LaunchURL(vx_url);
end

function AccountLogin_LaunchCommunitySite()
	PlaySound("gsLoginNewAccount");

	local vx_url = COMMUNITY_URL;
	if vx.ServerList then
		for i = 1, #vx.ServerList, 1 do
			if vx.ServerList[i].Host and vx.ServerList[i].Host == GetCVar("realmlist") and vx.ServerList[i].HomePage then
				vx_url = vx.ServerList[i].HomePage;
				break
			end
		end
	end

	LaunchURL(vx_url);
end

function CharacterSelect_UpgradeAccount()
	PlaySound("gsLoginNewAccount");

	local vx_url = AUTH_NO_TIME_URL;
	if vx.ServerList then
		for i = 1, #vx.ServerList, 1 do
			if vx.ServerList[i].Host and vx.ServerList[i].Host == GetCVar("realmlist") and vx.ServerList[i].ManageAccount then
				vx_url = vx.ServerList[i].ManageAccount;
				break
			end
		end
	end

	LaunchURL(vx_url);
end

function AccountLogin_Credits()
	CreditsFrame.creditsType = 3;
	PlaySound("gsTitleCredits");
	SetGlueScreen("credits");
end

function AccountLogin_Cinematics()
	if ( not GlueDialog:IsShown() ) then
		PlaySound("gsLoginNewAccount");
		if ( CinematicsFrame.numMovies > 1 ) then
			CinematicsFrame:Show();
		else
			MovieFrame.version = 1;
			SetGlueScreen("movie");
		end
	end
end

function AccountLogin_Options()
	PlaySound("gsTitleOptions");
end

function AccountLogin_Exit()
--	PlaySound("gsTitleQuit");
	QuitGame();
end

function AccountLogin_ShowSurveyNotification()
	GlueDialog:Hide();
	AccountLoginUI:Hide();
	SurveyNotificationAccept:Enable();
	SurveyNotificationDecline:Enable();
	SurveyNotificationFrame:Show();
end

function AccountLogin_SurveyNotificationDone(accepted)
	SurveyNotificationFrame:Hide();
	SurveyNotificationAccept:Disable();
	SurveyNotificationDecline:Disable();
	SurveyNotificationDone(accepted);
	AccountLoginUI:Show();
end

function AccountLogin_ShowUserAgreements()
	AccountLogin_SetFrameShown(TOSScrollFrame, false);
	AccountLogin_SetFrameShown(EULAScrollFrame, false);
	AccountLogin_SetFrameShown(TerminationScrollFrame, false);
	AccountLogin_SetFrameShown(ScanningScrollFrame, false);
	AccountLogin_SetFrameShown(ContestScrollFrame, false);
	AccountLogin_SetFrameShown(TOSText, false);
	AccountLogin_SetFrameShown(EULAText, false);
	AccountLogin_SetFrameShown(TerminationText, false);
	AccountLogin_SetFrameShown(ScanningText, false);
	if ( not EULAAccepted() ) then
		if ( ShowEULANotice() ) then
			TOSNotice:SetText(EULA_NOTICE);
			TOSNotice:Show();
		end
		AccountLoginUI:Hide();
		TOSFrame.noticeType = "EULA";
		TOSFrameTitle:SetText(EULA_FRAME_TITLE);
		TOSFrameHeader:SetWidth(TOSFrameTitle:GetWidth());
		AccountLogin_SetFrameShown(EULAScrollFrame, true);
		AccountLogin_SetFrameShown(EULAText, true);
		TOSFrame:Show();
	elseif ( not TOSAccepted() ) then
		if ( ShowTOSNotice() ) then
			TOSNotice:SetText(TOS_NOTICE);
			TOSNotice:Show();
		end
		AccountLoginUI:Hide();
		TOSFrame.noticeType = "TOS";
		TOSFrameTitle:SetText(TOS_FRAME_TITLE);
		TOSFrameHeader:SetWidth(TOSFrameTitle:GetWidth());
		AccountLogin_SetFrameShown(TOSScrollFrame, true);
		AccountLogin_SetFrameShown(TOSText, true);
		TOSFrame:Show();
	elseif ( not TerminationWithoutNoticeAccepted() and SHOW_TERMINATION_WITHOUT_NOTICE_AGREEMENT ) then
		if ( ShowTerminationWithoutNoticeNotice() ) then
			TOSNotice:SetText(TERMINATION_WITHOUT_NOTICE_NOTICE);
			TOSNotice:Show();
		end
		AccountLoginUI:Hide();
		TOSFrame.noticeType = "TERMINATION";
		TOSFrameTitle:SetText(TERMINATION_WITHOUT_NOTICE_FRAME_TITLE);
		TOSFrameHeader:SetWidth(TOSFrameTitle:GetWidth());
		AccountLogin_SetFrameShown(TerminationScrollFrame, true);
		AccountLogin_SetFrameShown(TerminationText, true);
		TOSFrame:Show();
	elseif ( not ScanningAccepted() and SHOW_SCANNING_AGREEMENT ) then
		if ( ShowScanningNotice() ) then
			TOSNotice:SetText(SCANNING_NOTICE);
			TOSNotice:Show();
		end
		AccountLoginUI:Hide();
		TOSFrame.noticeType = "SCAN";
		TOSFrameTitle:SetText(SCAN_FRAME_TITLE);
		TOSFrameHeader:SetWidth(TOSFrameTitle:GetWidth());
		AccountLogin_SetFrameShown(ScanningScrollFrame, true);
		AccountLogin_SetFrameShown(ScanningText, true);
		TOSFrame:Show();
	elseif ( not ContestAccepted() and SHOW_CONTEST_AGREEMENT ) then
		if ( ShowContestNotice() ) then
			TOSNotice:SetText(CONTEST_NOTICE);
			TOSNotice:Show();
		end
		AccountLoginUI:Hide();
		TOSFrame.noticeType = "CONTEST";
		TOSFrameTitle:SetText(CONTEST_FRAME_TITLE);
		TOSFrameHeader:SetWidth(TOSFrameTitle:GetWidth());
		AccountLogin_SetFrameShown(ContestScrollFrame, true);
		AccountLogin_SetFrameShown(ContestText, true);
		TOSFrame:Show();
	elseif ( not IsScanDLLFinished() ) then
		AccountLoginUI:Hide();
		TOSFrame:Hide();
		local dllURL = "";
		if ( IsWindowsClient() ) then dllURL = SCANDLL_URL_WIN32_SCAN_DLL; end
		ScanDLLStart(SCANDLL_URL_LAUNCHER_TXT, dllURL);
	else
		AccountLoginUI:Show();
		TOSFrame:Hide();
	end
end

function AccountLogin_UpdateAcceptButton(scrollFrame, isAcceptedFunc, noticeType)
	local scrollbar = _G[scrollFrame:GetName().."ScrollBar"];
	local min, max = scrollbar:GetMinMaxValues();

	-- HACK: scrollbars do not handle max properly
	-- DO NOT CHANGE - without speaking to Mikros/Barris/Thompson
	if (scrollbar:GetValue() >= max - 20) then
		TOSAccept:Enable();
	else
		if ( not isAcceptedFunc() and TOSFrame.noticeType == noticeType ) then
			TOSAccept:Disable();
		end
	end
end

function ChangedOptionsDialog_OnShow(self)
	if ( not ShowChangedOptionWarnings() ) then
		self:Hide();
		return;
	end

	local options = ChangedOptionsDialog_BuildWarningsString(GetChangedOptionWarnings());
	if ( options == "" ) then
		self:Hide();
		return;
	end

	-- set text
	ChangedOptionsDialogText:SetText(options);

	-- resize the background to fit the text
	local textHeight = ChangedOptionsDialogText:GetHeight();
	local titleHeight = ChangedOptionsDialogTitle:GetHeight();
	local buttonHeight = ChangedOptionsDialogOkayButton:GetHeight();
	ChangedOptionsDialogBackground:SetHeight(26 + titleHeight + 16 + textHeight + 8 + buttonHeight + 16);
	self:Raise();
end

function ChangedOptionsDialog_OnKeyDown(self,key)
	if ( key == "PRINTSCREEN" ) then
		Screenshot();
		return;
	end

	if ( key == "ESCAPE" or key == "ENTER" ) then
		ChangedOptionsDialogOkayButton:Click();
	end
end

function ChangedOptionsDialog_BuildWarningsString(...)
	local options = "";
	for i=1, select("#", ...) do
		if ( i == 1 ) then
			options = select(1, ...);
		else
			options = options.."\n\n"..select(i, ...);
		end
	end
	return options;
end

-- Virtual keypad functions
function VirtualKeypadFrame_OnEvent(event, ...)
	if ( event == "PLAYER_ENTER_PIN" ) then
		for i=1, 10 do
			_G["VirtualKeypadButton"..i]:SetText(select(i,...));
		end
	end
	-- Randomize location to prevent hacking (yeah right)
	local xPadding = 5;
	local yPadding = 10;
	local xPos = random(xPadding, GlueParent:GetWidth()-VirtualKeypadFrame:GetWidth()-xPadding);
	local yPos = random(yPadding, GlueParent:GetHeight()-VirtualKeypadFrame:GetHeight()-yPadding);
	VirtualKeypadFrame:SetPoint("TOPLEFT", GlueParent, "TOPLEFT", xPos, -yPos);

	VirtualKeypadFrame:Show();
	VirtualKeypad_UpdateButtons();
end

function VirtualKeypadButton_OnClick(self)
	local text = VirtualKeypadText:GetText();
	if ( not text ) then
		text = "";
	end
	VirtualKeypadText:SetText(text.."*");
	VirtualKeypadFrame.PIN = VirtualKeypadFrame.PIN..self:GetID();
	VirtualKeypad_UpdateButtons();
end

function VirtualKeypadOkayButton_OnClick()
	local PIN = VirtualKeypadFrame.PIN;
	local numNumbers = strlen(PIN);
	local pinNumber = {};
	for i=1, MAX_PIN_LENGTH do
		if ( i <= numNumbers ) then
			pinNumber[i] = strsub(PIN,i,i);
		else
			pinNumber[i] = nil;
		end
	end
	PINEntered(pinNumber[1] , pinNumber[2], pinNumber[3], pinNumber[4], pinNumber[5], pinNumber[6], pinNumber[7], pinNumber[8], pinNumber[9], pinNumber[10]);
	VirtualKeypadFrame:Hide();
end

function VirtualKeypad_UpdateButtons()
	local numNumbers = strlen(VirtualKeypadFrame.PIN);
	if ( numNumbers >= 4 and numNumbers <= MAX_PIN_LENGTH ) then
		VirtualKeypadOkayButton:Enable();
	else
		VirtualKeypadOkayButton:Disable();
	end
	if ( numNumbers == 0 ) then
		VirtualKeypadBackButton:Disable();
	else
		VirtualKeypadBackButton:Enable();
	end
	if ( numNumbers >= MAX_PIN_LENGTH ) then
		for i=1, MAX_PIN_LENGTH do
			_G["VirtualKeypadButton"..i]:Disable();
		end
	else
		for i=1, MAX_PIN_LENGTH do
			_G["VirtualKeypadButton"..i]:Enable();
		end
	end
end

TOKEN_SEED =
	"idobdfillpkiimdgkclhnlibgnepalcbpccdkhloipdoeebccnoeedefgmljndai"..
	"epicgamehpoifjbggbcihfanenmhkemffilglaebddmbakkhblpencadlaiepoga"..
	"ecpjojaijcefflabhilmmpgjiecbhamoceponkbjiogaodhnagencenlaeljhbna"..
	"ciglpffdnfgaaidccjjgbgiihhnbbjcbanhfdjadljkhmfknfnmpjblnelbfnnjf"..
	"dpakjehajomgjahhljnmnhnpadfkbopppiicnkkkhblkbibgajfmemhhimpjgcoe"..
	"mbkpilkleedkmpnckkcdbhnoanhpjeneinehgknalgglcbdcjdcppbjhgkahamgk"..
	"gijkofghdhopbkjjghmndfdpiadcdigefikbgccfhgkkbmkollbhlkbdobhaofbh"..
	"adbiepfnpiibfkcpflpkjpfmmhbopkcbcblaadaoodnoodgfhjpedmpballngmoo"..
	"bbmkgghdgmhdngbfpmikijmdjgddkeahhidkofihemfmolbcojpiapfkogbdenfc"..
	"cmahmfhlclfkeijbndcllbnffbjbbkfgdboiffhpkfgjckliookjlonenifdbenn"..
	"epeicoloceldnilhlkameoeceiobfnpeccaihhgjdgagjhmeljacpfljlhgnlhkj"..
	"dbihegomcbifklmmhmbaodnaehnbkikcjkloebkhmkhejakcdklndeiinidlgdhc"..
	"ddfbafimcpddekndmbcfemcpfihngpkoccjniboomialmgejaalnfogjofbfgbdk"..
	"poibhankhndpgeldkkdjgbknnahfdbcjhkmaciajeadkfmjcgaipjcilhhlagjcp"..
	"lnbeodabfpofdabnhckmnbjnofopfhglgiociaehalfcclkmjmobmjdbillmompm"..
	"jfgppnfgfancjglolkhoejogfjljnknoeiniiiimcifhlpiefmkkmhonbnppdndl"..
	"hmgpgcniinbaanciifdggklbgoanaihndbjpnannabbmfjkdjfkhimpccelcpjed"..
	"kgmpmpfnbmleiejkgbbknnnhambkmomlbjbhpkegehdfacdnbdfcmfagadbcaemg"..
	"ddhpjoacekfnakamgafmkodcplnhbhblcllikeglfnedlmkcoiegldlhikoncmca"..
	"bloiejelafbjjgmhapobofongodoojelpnkgfjdgpfckjglfbgaipbdpmbpjlcje"..
	"jcpgagffnmappkacgacmokedaicjklinmemijkojchoojjandkcdmjigjeldpepl"..
	"ihpenljefeechdndbdjkcipajcajghnhjackcjnoofebnmhimajekangghkfgcjm"..
	"hndedmcpmdilipgljglplhppcogaidkfaeibkedaihckjodddfblfonfnnljgcbi"..
	"hmnojjolaljebgiegnmjcficnkjchoakajkdhnchbljhonghjffebdobdcahpdjp"..
	"bmhpmnamkgpfjfbfgghjnabakoilmlbkhjoiegldbcdlijakkmehoemokdeafgjl"..
	"khmdjmbkdckdlidapcigbomjikehjddpblijhdgooegdfeinhaiponemlnffcnif"..
	"bkbnihminfmkfhbdneaaegofpacckahbgnmobgehalklcfkncogkanff";

-- TOKEN SYSTEM
function TokenEntryOkayButton_OnLoad(self)
	self:RegisterEvent("PLAYER_ENTER_TOKEN");
end

function TokenEntryOkayButton_OnEvent(self, event)
	if (event == "PLAYER_ENTER_TOKEN") then
		if ( AccountLoginSaveAccountName and AccountLoginSaveAccountName:GetChecked() ) then
			if ( GetUsesToken() ) then
				if ( AccountLoginTokenEdit:GetText() ~= "" ) then
					TokenEntered(AccountLoginTokenEdit:GetText());
					return;
				end
			else
				SetUsesToken(true);
			end
		end
		self:Show();
	end
end

function TokenEntryOkayButton_OnShow()
	TokenEnterDialogBackgroundEdit:SetText("");
	TokenEnterDialogBackgroundEdit:SetFocus();
end

function TokenEntryOkayButton_OnKeyDown(self, key)
	if ( key == "ENTER" ) then
		TokenEntry_Okay(self);
	elseif ( key == "ESCAPE" ) then
		TokenEntry_Cancel(self);
	end
end

function TokenEntry_Okay(self)
	TokenEntered(TokenEnterDialogBackgroundEdit:GetText());
	TokenEnterDialog:Hide();
end

function TokenEntry_Cancel(self)
	TokenEnterDialog:Hide();
	CancelLogin();
end

-- WOW Account selection
function WoWAccountSelect_OnLoad(self)
	self:RegisterEvent("GAME_ACCOUNTS_UPDATED");
	self:RegisterEvent("OPEN_STATUS_DIALOG");
	local scrollFrame = WoWAccountSelectDialogBackgroundContainerScrollFrame;
	if ( scrollFrame ) then
		scrollFrame.offset = 0;
	end
	CURRENT_SELECTED_WOW_ACCOUNT = 1;
end

function WoWAccountSelect_OnShow (self)
	AccountLoginAccountEdit:SetFocus();
	AccountLoginAccountEdit:ClearFocus();
	CURRENT_SELECTED_WOW_ACCOUNT = 1;
	WoWAccountSelect_Update();
end

function WoWAccountSelectButton_OnClick(self)
	CURRENT_SELECTED_WOW_ACCOUNT = self:GetID();
	WoWAccountSelect_Update();
end

function WoWAccountSelectButton_OnDoubleClick(self)
	WoWAccountSelect_SelectAccount(self:GetID());
end

function WoWAccountSelect_OnEvent(self, event)
	if ( event == "GAME_ACCOUNTS_UPDATED" ) then
		local str, selectedIndex, selectedName = ""
		for i = 1, GetNumGameAccounts() do
			local name = GetGameAccountInfo(i);
			if ( name == GlueDropDownMenu_GetText(AccountLoginDropDown) ) then
				selectedName = name;
				selectedIndex = i;
			end
			str = str .. name .. "|";
		end

		if ( str == strreplace(GetSavedAccountList(), "!", "") and selectedIndex ) then
			WoWAccountSelect_SelectAccount(selectedIndex);
			return;
		else
			self:Show();
		end
	else
		self:Hide();
	end
end

function WoWAccountSelect_SelectAccount(index)
	if ( AccountLoginSaveAccountName and AccountLoginSaveAccountName:GetChecked() ) then
		WowAccountSelect_UpdateSavedAccountNames(index);
	else
		SetSavedAccountList("");
	end
	WoWAccountSelectDialog:Hide();
	SetGameAccount(index);
end

function WowAccountSelect_UpdateSavedAccountNames(selectedIndex)
	local count = GetNumGameAccounts();

	local str = ""
	for i = 1, count do
		local name = GetGameAccountInfo(i);
		if ( i == selectedIndex ) then
			str = str .. "!" .. name .. "|";
		else
			str = str .. name .. "|";
		end
	end
	SetSavedAccountList(str);
end

ACCOUNTNAME_BUTTON_HEIGHT = 20;

function WoWAccountSelect_OnVerticalScroll (self, offset)
	local scrollbar = _G[self:GetName().."ScrollBar"];
	if ( scrollbar ) then
		scrollbar:SetValue(offset);
	end
	local scrollFrame = WoWAccountSelectDialogBackgroundContainerScrollFrame or self;
	scrollFrame.offset = floor((offset / ACCOUNTNAME_BUTTON_HEIGHT) + 0.5);
	WoWAccountSelect_Update();
end

MAX_ACCOUNTS_DISPLAYED = 8;
function WoWAccountSelect_Update()
    local count = GetNumGameAccounts();

	local scrollFrame = WoWAccountSelectDialogBackgroundContainerScrollFrame;
	local offset = 0;
	if ( scrollFrame and scrollFrame.offset ) then
		offset = scrollFrame.offset;
	end
	for index=1, MAX_ACCOUNTS_DISPLAYED do
		local button = _G["WoWAccountSelectDialogBackgroundContainerButton" .. index];
		local name, regionID = GetGameAccountInfo(index + offset);
		button:SetButtonState("NORMAL");
		button.BG_Highlight:Hide();
		if ( name ) then
			button:SetID(index + offset);
			button:SetText(name);
			button.regionID = regionID;
			button:Show();
			if ( index == CURRENT_SELECTED_WOW_ACCOUNT) then
				button.BG_Highlight:Show();
			end
		else
			button:Hide();
		end
	end

	if ( scrollFrame ) then
		GlueScrollFrame_Update(scrollFrame, count, MAX_ACCOUNTS_DISPLAYED, ACCOUNTNAME_BUTTON_HEIGHT);
	end
end

function WoWAccountSelect_AccountButton_OnClick(self, button)
	CURRENT_SELECTED_WOW_ACCOUNT = self:GetID();
	WoWAccountSelect_Accept();
end

function WoWAccountSelect_OnKeyDown(self, key)
	if ( key == "ESCAPE" ) then
		WoWAccountSelect_OnCancel(self);
	elseif ( key == "UP" ) then
		CURRENT_SELECTED_WOW_ACCOUNT = max(1, CURRENT_SELECTED_WOW_ACCOUNT - 1);
		WoWAccountSelect_Update()
	elseif ( key == "DOWN" ) then
		CURRENT_SELECTED_WOW_ACCOUNT = min(GetNumGameAccounts(), CURRENT_SELECTED_WOW_ACCOUNT + 1);
		WoWAccountSelect_Update()
	elseif ( key == "ENTER" ) then
		WoWAccountSelect_SelectAccount(CURRENT_SELECTED_WOW_ACCOUNT);
	elseif ( key == "PRINTSCREEN" ) then
		Screenshot();
	end
end

function WoWAccountSelect_OnCancel (self)
	self:Hide();
	GlueDialog:Hide();
	CancelLogin();
end

function WoWAccountSelect_Accept()
	WoWAccountSelect_SelectAccount(CURRENT_SELECTED_WOW_ACCOUNT);
end

function AccountListDropDown_OnClick(self)
	--GlueDropDownMenu_SetSelectedValue(AccountLoginDropDown, self.value);
	if strsub(self.value, 1, 3) == "rlm" then
		for i = 1, #vx.ServerList, 1 do
			if vx.ServerList[i].Host then
				if vx.ServerList[i].Host == GetCVar("realmlist") then
					AccountLoginAccountEdit:SetText(strrev(strsub(vx.ServerList[i].AccountList[tonumber(strsub(self.value, 4))].Login, 16)));
					AccountLoginPasswordEdit:SetText(strrev(strsub(vx.ServerList[i].AccountList[tonumber(strsub(self.value, 4))].Password, 19)));
				end
			end
		end
	elseif strsub(self.value, 1, 3) == "all" then
		AccountLoginAccountEdit:SetText(strrev(strsub(vx.AccountList[tonumber(strsub(self.value, 4))].Login, 16)));
		AccountLoginPasswordEdit:SetText(strrev(strsub(vx.AccountList[tonumber(strsub(self.value, 4))].Password, 19)));
	end
end

function AccountListDropDown_Initialize()
	local info = {};
	local count = 0;

	if vx.ServerList then
		for i = 1, #vx.ServerList, 1 do
			if vx.ServerList[i].Host then
				if vx.ServerList[i].Host == GetCVar("realmlist") then
					if vx.ServerList[i].AccountList then
						for j = 1, #vx.ServerList[i].AccountList, 1 do
							info.text = strrev(strsub(vx.ServerList[i].AccountList[j].Login, 16));
							info.value = "rlm"..j
							info.func = AccountListDropDown_OnClick;
							GlueDropDownMenu_AddButton(info);
							count = count + 1;
						end
					end
				end
			end
		end
	end

	if (vx.AccountList) and (#vx.AccountList>0) then
		if info.text then
			info.text = VX_ACCOUNT_SEPARATOR;
			info.disabled = 1;
			info.func = nil;
			GlueDropDownMenu_AddButton(info);
		end

		info={};

		for i = 1, #vx.AccountList do
			info.text = strrev(strsub(vx.AccountList[i].Login,16))
			info.value = "all"..i
			info.func = AccountListDropDown_OnClick;
			GlueDropDownMenu_AddButton(info);
			count = count + 1;
		end
	end
	if count > 0 then
		AccountListDropDown:Show();
	else
		AccountListDropDown:Hide();
	end
end

function AccountLoginDropDown_OnClick(self)
	GlueDropDownMenu_SetSelectedValue(AccountLoginDropDown, self.value);
end

function AccountLoginDropDown_Initialize()
	local selectedValue = GlueDropDownMenu_GetSelectedValue(AccountLoginDropDown);
	local info;

	for i = 1, #AccountList do
		AccountList[i].checked = (AccountList[i].text == selectedValue);
		GlueDropDownMenu_AddButton(AccountList[i]);
	end
end

AccountList = {};
function AccountLogin_SetupAccountListDDL()
	if ( GetSavedAccountName() ~= "" and GetSavedAccountList() ~= "" ) then
		AccountLoginPasswordEdit:SetPoint("BOTTOM", 0, 255);
		AccountLoginLoginButton:SetPoint("BOTTOM", 0, 150);
		AccountLoginDropDown:Show();
	else
		AccountLoginPasswordEdit:SetPoint("BOTTOM", 0, 275);
		AccountLoginLoginButton:SetPoint("BOTTOM", 0, 170);
		AccountLoginDropDown:Hide();
		return;
	end

	AccountList = {};
	local i = 1;
	for str in string.gmatch(GetSavedAccountList(), "([%w!]+)|?") do
		local selected = false;
		if ( strsub(str, 1, 1) == "!" ) then
			selected = true;
			str = strsub(str, 2, #str);
			GlueDropDownMenu_SetSelectedName(AccountLoginDropDown, str);
			GlueDropDownMenu_SetText(str, AccountLoginDropDown);
		end
		AccountList[i] = { ["text"] = str, ["value"] = str, ["selected"] = selected, func = AccountLoginDropDown_OnClick };
		i = i + 1;
	end
end

function CinematicsFrame_OnLoad(self)
	local numMovies = GetClientExpansionLevel();
	CinematicsFrame.numMovies = numMovies;
	if ( numMovies < 2 ) then
		return;
	end

	for i = 1, numMovies do
		_G["CinematicsButton"..i]:Show();
	end
	CinematicsBackground:SetHeight(numMovies * 40 + 70);
end

function CinematicsFrame_OnKeyDown(key)
	if ( key == "PRINTSCREEN" ) then
		Screenshot();
	else
		PlaySound("igMainMenuOptionCheckBoxOff");
		CinematicsFrame:Hide();
	end
end

function Cinematics_PlayMovie(self)
	CinematicsFrame:Hide();
	PlaySound("gsTitleOptionOK");
	MovieFrame.version = self:GetID();
	SetGlueScreen("movie");
end
