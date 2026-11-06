CurrentGlueMusic = "GS_LichKing"; --"GS_Retail";

GlueCreditsSoundKits = { };
GlueCreditsSoundKits[1] = "Menu-Credits01";
GlueCreditsSoundKits[2] = "Menu-Credits02";
GlueCreditsSoundKits[3] = "Menu-Credits03";

REALM_SIRION = "";

RAZA_GLOBAL_PAID_CHANGE = 0;
CLASE_GLOBAL_PAID_CHANGE = 0;

CHANGE_RACE_CUSTOM_ENABLE = 0;
MARCAR_FIRST_RACE_CUSTOM = 0;
CORREGIR_GLUESCREEN = 0;
CORREGIR_GLUESCREEN_TIME = 0;
GLOBAL_ZOOM_POS = 0;
GLOBAL_ZOOM_POS_22 = 1;
MOSTRAR_CREACIONES_NUEVAS = 0;
NEW_ELFOS_CROSSOVER = 0;
--[[vx = {
    ["ServerList"] = {
        {
            ["Host"] = "127.0.0.1",
            ["Portal"] = "eu",
            ["Description"] = " ",
        },
    }
};]]

--VX_LOGO_TEXTURE = "Interface\\Glues\\Common\\Glues-WoW-Logo";
VX_FADE_LOAD = 1.5; -- time in seconds
VX_FADE_UNLOAD = 1.0; -- time in seconds
VX_FADE_REFRESH = 0.25; -- time in seconds

--[[VX_SERVERLIST_SERVER_SELECTION = "Server Selection";
VX_SERVERLIST_SERVER_NAME = "Server Name";
VX_SERVERLIST_SERVER_DESCRIPTION = "Server Description";
VX_ACCOUNT_SEPARATOR = "---"]]


GlueScreenInfo = { };
GlueScreenInfo["login"]			= "AccountLogin";
GlueScreenInfo["charselect"]	= "CharacterSelect";
GlueScreenInfo["realmwizard"]	= "RealmWizard";
GlueScreenInfo["charcreate"]	= "CharacterCreate";
GlueScreenInfo["patchdownload"]	= "PatchDownload";
GlueScreenInfo["trialconvert"]	= "TrialConvert";
GlueScreenInfo["movie"]			= "MovieFrame";
GlueScreenInfo["credits"]		= "CreditsFrame";
GlueScreenInfo["options"]		= "OptionsFrame";

CharModelFogInfo = { };
CharModelFogInfo["HUMAN"] = { r=0.8, g=0.65, b=0.73, far=222 };
CharModelFogInfo["ORC"] = { r=0.5, g=0.5, b=0.5, far=270 };
CharModelFogInfo["DWARF"] = { r=0.85, g=0.88, b=1.0, far=500 };
CharModelFogInfo["NIGHTELF"] = { r=0.25, g=0.22, b=0.55, far=611 };
CharModelFogInfo["TAUREN"] = { r=1.0, g=0.61, b=0.42, far=153 };
CharModelFogInfo["SCOURGE"] = { r=0, g=0.22, b=0.22, far=26 };
CharModelFogInfo["CHARACTERSELECT"] = { r=0.8, g=0.65, b=0.73, far=222 };

CharModelGlowInfo = { };
CharModelGlowInfo["WORGEN"] = 0.0;
CharModelGlowInfo["GOBLIN"] = 0.0;
CharModelGlowInfo["HUMAN"] = 0.15;
CharModelGlowInfo["DWARF"] = 0.15;
CharModelGlowInfo["CHARACTERSELECT"] = 0.3;

GlueAmbienceTracks = { };
GlueAmbienceTracks["HUMAN"] = "GlueScreenHuman";
GlueAmbienceTracks["ORC"] = "GlueScreenOrc";
GlueAmbienceTracks["DWARF"] = "GlueScreenGnome";
GlueAmbienceTracks["GNOME"] = "GlueScreenGnome";
GlueAmbienceTracks["TAUREN"] = "GlueScreenTauren";
GlueAmbienceTracks["SCOURGE"] = "GlueScreenUndead";
GlueAmbienceTracks["NIGHTELF"] = "GlueScreenNightElf";
GlueAmbienceTracks["BROKEN"] = "GlueScreenBroken";
GlueAmbienceTracks["DRAENEI"] = "GlueScreenDraenei";
GlueAmbienceTracks["BLOODELF"] = "GlueScreenBloodElf";
GlueAmbienceTracks["FELORC"] = "GlueScreenBloodElf";
GlueAmbienceTracks["DARKPORTAL"] = "GlueScreenIntro";
GlueAmbienceTracks["DEATHKNIGHT"] = "GlueScreenIntro";
GlueAmbienceTracks["MONJE"] = "GlueScreenIntro";
GlueAmbienceTracks["CHARACTERSELECT"] = "GlueScreenIntro";
GlueAmbienceTracks["GOBLIN"] = "GlueScreenGoblin";
GlueAmbienceTracks["WORGEN"] = "GlueScreenWorgen";
GlueAmbienceTracks["NAGA"] = "GlueScreenNightElf";
GlueAmbienceTracks["SKELETON"] = "GlueScreenHuman";
GlueAmbienceTracks["TUSKARR"] = "GlueScreenBloodElf";
GlueAmbienceTracks["VRYKUL"] = "GlueScreenNightElf";

-- RaceLights[] duplicates the 3.2.2 color values in the models. Henceforth, the models no longer contain directional lights
RaceLights = {
    ForestTroll =  {
        {1,     0,  -0.82249,       -0.54912,       -0.14822,   1.0,    0.00000,    0.00000,    0.00000,    2.0,    0.581175,   0.50588,    0.42588},
        {1,     0,  0.00000,        -0.00000,       -1.00000,   1.0,    0.60392,    0.61490,    0.70000,    1.0,    0.00000,    0.00000,    0.00000},
        {1,     0,  0.02575,        0.86518,        -0.50081,   1.0,    0.00000,    0.00000,    0.00000,    1.0,    0.59137,    0.51745,    0.63471},
    },
    ForestTroll =  {
        {1,     0,  -0.82249,       -0.54912,       -0.14822,   1.0,    0.00000,    0.00000,    0.00000,    2.0,    0.581175,   0.50588,    0.42588},
        {1,     0,  0.00000,        -0.00000,       -1.00000,   1.0,    0.60392,    0.61490,    0.70000,    1.0,    0.00000,    0.00000,    0.00000},
        {1,     0,  0.02575,        0.86518,        -0.50081,   1.0,    0.00000,    0.00000,    0.00000,    1.0,    0.59137,    0.51745,    0.63471},
    },
    HUMAN =  {
        {1,     0,  0.000000,       0.000000,       -1.000000,   1.0,   0.27,       0.27,       .27,        1.0,    0,          0,          0},
        {1,     0,  -0.45756075,    -0.58900136,    -0.66611975, 1.0,   0.000000,   0.000000,   0.000000,   1.0,    0.19882353, 0.34921569, 0.43588236 },
        {1,     0,  -0.64623469,    0.57582057,     -0.50081086, 1.0,   0.000000,   0.000000,   0.000000,   2.0,    0.52196085, 0.44,       0.29764709 },
    },
    TROLL =  {
        {1,     0,  -0.82249,       -0.54912,       -0.14822,   1.0,    0.00000,    0.00000,    0.00000,    2.0,    0.581175,   0.50588,    0.42588},
        {1,     0,  0.00000,        -0.00000,       -1.00000,   1.0,    0.60392,    0.61490,    0.70000,    1.0,    0.00000,    0.00000,    0.00000},
        {1,     0,  0.02575,        0.86518,        -0.50081,   1.0,    0.00000,    0.00000,    0.00000,    1.0,    0.59137,    0.51745,    0.63471},
    },
    WORGEN =  {
        {1,     0,  -0.82249,       -0.54912,       -0.14822,   1.0,    0.00000,    0.00000,    0.00000,    2.0,    0.581175,   0.50588,    0.42588},
        {1,     0,  0.00000,        -0.00000,       -1.00000,   1.0,    0.60392,    0.61490,    0.70000,    1.0,    0.00000,    0.00000,    0.00000},
        {1,     0,  0.02575,        0.86518,        -0.50081,   1.0,    0.00000,    0.00000,    0.00000,    1.0,    0.59137,    0.51745,    0.63471},
    },
    Naga_ =  {
        {1,     0,  -0.82249,       -0.54912,       -0.14822,   1.0,    0.00000,    0.00000,    0.00000,    2.0,    0.581175,   0.50588,    0.42588},
        {1,     0,  0.00000,        -0.00000,       -1.00000,   1.0,    0.60392,    0.61490,    0.70000,    1.0,    0.00000,    0.00000,    0.00000},
        {1,     0,  0.02575,        0.86518,        -0.50081,   1.0,    0.00000,    0.00000,    0.00000,    1.0,    0.59137,    0.51745,    0.63471},
    },
    NAGA_ =  {
        {1,     0,  -0.82249,       -0.54912,       -0.14822,   1.0,    0.00000,    0.00000,    0.00000,    2.0,    0.581175,   0.50588,    0.42588},
        {1,     0,  0.00000,        -0.00000,       -1.00000,   1.0,    0.60392,    0.61490,    0.70000,    1.0,    0.00000,    0.00000,    0.00000},
        {1,     0,  0.02575,        0.86518,        -0.50081,   1.0,    0.00000,    0.00000,    0.00000,    1.0,    0.59137,    0.51745,    0.63471},
    },
    ORC = {
        {1,     0,  0.000000,       0.000000,       -1.000000,   1.0,   0.27,       0.27,       .27,        1.0,    0,          0,          0},
        {1,     0,  -0.74919,       0.35208,        -0.56103,   1.0,    0.00000,    0.00000,    0.00000,    1.0,    0.44706,    0.54510,    0.73725},
        {1,     0,  0.53162,        -0.84340,       0.07780,    1.0,    0.00000,    0.00000,    0.00000,    2.0,    0.55,       0.338625,   0.148825},
    },
    TUSKARR = {
        {1,     0,  -0.82249,       -0.54912,       -0.14822,   1.0,    0.00000,    0.00000,    0.00000,    2.0,    0.581175,   0.50588,    0.42588},
        {1,     0,  0.00000,        -0.00000,       -1.00000,   1.0,    0.60392,    0.61490,    0.70000,    1.0,    0.00000,    0.00000,    0.00000},
        {1,     0,  0.02575,        0.86518,        -0.50081,   1.0,    0.00000,    0.00000,    0.00000,    1.0,    0.59137,    0.51745,    0.63471},
    },
    SKELETON = {
        {1,     0,  -0.82249,       -0.54912,       -0.14822,   1.0,    0.00000,    0.00000,    0.00000,    2.0,    0.581175,   0.50588,    0.42588},
        {1,     0,  0.00000,        -0.00000,       -1.00000,   1.0,    0.60392,    0.61490,    0.70000,    1.0,    0.00000,    0.00000,    0.00000},
        {1,     0,  0.02575,        0.86518,        -0.50081,   1.0,    0.00000,    0.00000,    0.00000,    1.0,    0.59137,    0.51745,    0.63471},
    },
    DWARF = {
        {1,     0,  -0.00000,       -0.00000,       -1.00000,   1.0,    0.30000,    0.30000,    0.30000,    0.0,    0.00000,    0.00000,    0.00000},
        {1,     0,  -0.88314,       0.42916,        -0.18945,   1.0,    0.00000,    0.00000,    0.00000,    2.0,    0.44706,    0.67451,    0.760785},
    },
    GNOME = {
        {1,     0,  -0.00000,       -0.00000,       -1.00000,   1.0,    0.30000,    0.30000,    0.30000,    0.0,    0.00000,    0.00000,    0.00000},
        {1,     0,  -0.88314,       0.42916,        -0.18945,   1.0,    0.00000,    0.00000,    0.00000,    2.0,    0.44706,    0.67451,    0.760785},
    },
    TAUREN = {
        {1,     0,  0.000000,       0.000000,       -1.000000,   1.0,   0.27,       0.27,       .27,        1.0,    0,          0,          0},
        {1,     0,  -0.45756075,    -0.58900136,    -0.66611975, 1.0,   0.000000,   0.000000,   0.000000,   1.0,    0.19882353, 0.34921569, 0.43588236 },
        {1,     0,  -0.64623469,    0.57582057,     -0.50081086, 1.0,   0.000000,   0.000000,   0.000000,   2.0,    0.52196085, 0.44,       0.29764709 },
    },
    BROKEN = {
        {1,     0,  0.000000,       0.000000,       -1.000000,   1.0,   0.27,       0.27,       .27,        1.0,    0,          0,          0},
        {1,     0,  -0.45756075,    -0.58900136,    -0.66611975, 1.0,   0.000000,   0.000000,   0.000000,   1.0,    0.19882353, 0.34921569, 0.43588236 },
        {1,     0,  -0.64623469,    0.57582057,     -0.50081086, 1.0,   0.000000,   0.000000,   0.000000,   2.0,    0.52196085, 0.44,       0.29764709 },
    },
    SCOURGE = {
        {1,     0,  0.00000,        0.00000,        -1.00000,   1.0,    0.20000,    0.20000,    0.20000,    1.0,    0.00000,    0.00000,    0.00000},
    },
    NIGHTELF = {
        {1,     0,  -0.00000,       -0.00000,       -1.00000,   1.0,    0.09020,    0.09020,    0.17020,    1.0,    0.00000,    0.00000,    0.00000},
    },
    DRAENEI = {
        {1,     0,  0.000000,       0.000000,       -1.000000,   1.0,   0.27,       0.27,       .27,        1.0,    0,          0,          0},
        {1,     0,  -0.45756075,    -0.58900136,    -0.66611975, 1.0,   0.000000,   0.000000,   0.000000,   1.0,    0.19882353, 0.34921569, 0.43588236 },
        {1,     0,  -0.64623469,    0.57582057,     -0.50081086, 1.0,   0.000000,   0.000000,   0.000000,   2.0,    0.52196085, 0.44,       0.29764709 },
    },
    BLOODELF = {
        {1,     0,  -0.82249,       -0.54912,       -0.14822,   1.0,    0.00000,    0.00000,    0.00000,    2.0,    0.581175,   0.50588,    0.42588},
        {1,     0,  0.00000,        -0.00000,       -1.00000,   1.0,    0.60392,    0.61490,    0.70000,    1.0,    0.00000,    0.00000,    0.00000},
        {1,     0,  0.02575,        0.86518,        -0.50081,   1.0,    0.00000,    0.00000,    0.00000,    1.0,    0.59137,    0.51745,    0.63471},
    },
    FELORC = {
        {1,     0,  -0.82249,       -0.54912,       -0.14822,   1.0,    0.00000,    0.00000,    0.00000,    2.0,    0.581175,   0.50588,    0.42588},
        {1,     0,  0.00000,        -0.00000,       -1.00000,   1.0,    0.60392,    0.61490,    0.70000,    1.0,    0.00000,    0.00000,    0.00000},
        {1,     0,  0.02575,        0.86518,        -0.50081,   1.0,    0.00000,    0.00000,    0.00000,    1.0,    0.59137,    0.51745,    0.63471},
    },
    DEATHKNIGHT = {
        {1,     0,  -0.82249,       -0.54912,       -0.14822,   1.0,    0.00000,    0.00000,    0.00000,    2.0,    0.581175,   0.50588,    0.42588},
        {1,     0,  0.00000,        -0.00000,       -1.00000,   1.0,    0.60392,    0.61490,    0.70000,    1.0,    0.00000,    0.00000,    0.00000},
        {1,     0,  0.02575,        0.86518,        -0.50081,   1.0,    0.00000,    0.00000,    0.00000,    1.0,    0.59137,    0.51745,    0.63471},
    },
    MONJE = {
        {1,     0,  0.00000,        0.00000,        -1.00000,   1.0,    0.38824,    0.66353,    0.76941,    1.0,    0.00000,    0.00000,    0.00000},
    },
    CHARACTERSELECT =  {
        {1,     0,  -0.82249,       -0.54912,       -0.14822,   1.0,    0.00000,    0.00000,    0.00000,    2.0,    0.581175,   0.50588,    0.42588},
        {1,     0,  0.00000,        -0.00000,       -1.00000,   1.0,    0.60392,    0.61490,    0.70000,    1.0,    0.00000,    0.00000,    0.00000},
        {1,     0,  0.02575,        0.86518,        -0.50081,   1.0,    0.00000,    0.00000,    0.00000,    1.0,    0.59137,    0.51745,    0.63471},
    },
}

-- indicies for adding lights ModelFFX:Add*Light
LIGHT_LIVE  = 0;
LIGHT_GHOST = 1;

-- Alpha animation stuff
FADEFRAMES = {};
CURRENT_GLUE_SCREEN = nil;
PENDING_GLUE_SCREEN = nil;
-- Time in seconds to fade
LOGIN_FADE_IN = 0;
LOGIN_FADE_OUT = 0;
CHARACTER_SELECT_FADE_IN = 0;
RACE_SELECT_INFO_FADE_IN = .5;
RACE_SELECT_INFO_FADE_OUT = .5;

-- Realm Split info
SERVER_SPLIT_SHOW_DIALOG = false;
SERVER_SPLIT_CLIENT_STATE = -1;	--	-1 uninitialized; 0 - no choice; 1 - realm 1; 2 - realm 2
SERVER_SPLIT_STATE_PENDING = -1;	--	-1 uninitialized; 0 - no server split; 1 - server split (choice mode); 2 - server split (no choice mode)
SERVER_SPLIT_DATE = nil;

-- Account Messaging info
ACCOUNT_MSG_NUM_AVAILABLE = 0;
ACCOUNT_MSG_PRIORITY = 0;
ACCOUNT_MSG_HEADERS_LOADED = false;
ACCOUNT_MSG_BODY_LOADED = false;
ACCOUNT_MSG_CURRENT_INDEX = nil;

-- Gender Constants
SEX_NONE = 1;
SEX_MALE = 2;
SEX_FEMALE = 3;

function SetGlueScreen(name)
    local newFrame;
    for index, value in pairs(GlueScreenInfo) do
        local frame = _G[value];
        if ( frame ) then
            frame:Hide();
            if ( index == name ) then
                newFrame = frame;
            end
        end
    end

    if ( newFrame ) then
        newFrame:Show();
        SetCurrentScreen(name);
        SetCurrentGlueScreenName(name);
        if ( name == "credits" ) then
        --	StopLoginMusic();
            PlayCreditsMusic( GlueCreditsSoundKits[CreditsFrame.creditsType] );
            StopGlueAmbience();
        elseif ( name ~= "movie" ) then
            --StopGlueMusic();
            --StopLoginMusic();
            --PlayLoginMusic();
            --PlayGlueMusic(CurrentGlueMusic);
            if (name == "login") then
                --ShowScene(AccountLogin);
                --PlayGlueAmbience(GlueAmbienceTracks["DARKPORTAL"], 4.0);
            end
        end
    end
end

function SetCurrentGlueScreenName(name)
    CURRENT_GLUE_SCREEN = name;
end

function GetCurrentGlueScreenName()
    return CURRENT_GLUE_SCREEN;
end

function SetPendingGlueScreenName(name)
    PENDING_GLUE_SCREEN = name;
end

function GetPendingGlueScreenName()
    return PENDING_GLUE_SCREEN;
end
function Hab_textur_subRax()
    if ( CharCreateRacesButton1:IsShown() ) then
        Texture_paid_boton(CharCreateRacesButton1, 1);
    end
    if ( CharCreateRacesButton2:IsShown() ) then
        Texture_paid_boton(CharCreateRacesButton2, 2);
    end
    if ( CharCreateRacesButton3:IsShown() ) then
        Texture_paid_boton(CharCreateRacesButton3, 3);
    end
    if ( CharCreateRacesButton4:IsShown() ) then
        Texture_paid_boton(CharCreateRacesButton4, 4);
    end
    if ( CharCreateRacesButton5:IsShown() ) then
        Texture_paid_boton(CharCreateRacesButton5, 5);
    end
    if ( CharCreateRacesButton6:IsShown() ) then
        Texture_paid_boton(CharCreateRacesButton6, 6);
    end
    if ( CharCreateRacesButton7:IsShown() ) then
        Texture_paid_boton(CharCreateRacesButton7, 7);
    end
    if ( CharCreateRacesButton8:IsShown() ) then
        Texture_paid_boton(CharCreateRacesButton8, 8);
    end
    if ( CharCreateRacesButton9:IsShown() ) then
        Texture_paid_boton(CharCreateRacesButton9, 9);
    end
    if ( CharCreateRacesButton10:IsShown() ) then
        Texture_paid_boton(CharCreateRacesButton10, 10);
    end
    if ( CharCreateRacesButton11:IsShown() ) then
        Texture_paid_boton(CharCreateRacesButton11, 11);
    end
    if ( CharCreateRacesButton12:IsShown() ) then
        Texture_paid_boton(CharCreateRacesButton12, 12);
    end
    if ( CharCreateRacesButton13:IsShown() ) then
        Texture_paid_boton(CharCreateRacesButton13, 13);
    end
    if ( CharCreateRacesButton14:IsShown() ) then
        Texture_paid_boton(CharCreateRacesButton14, 14);
    end
    if ( CharCreateRacesButton15:IsShown() ) then
        Texture_paid_boton(CharCreateRacesButton15, 15);
    end
    if ( CharCreateRacesButton16:IsShown() ) then
        Texture_paid_boton(CharCreateRacesButton16, 16);
    end
    if ( CharCreateRacesButton17:IsShown() ) then
        Texture_paid_boton(CharCreateRacesButton17, 17);
    end
    if ( CharCreateRacesButton18:IsShown() ) then
        Texture_paid_boton(CharCreateRacesButton18, 18);
    end
end
function Habilitador_races_paid_custom()

        CharCreateRacesButton1:Enable();
        CharCreateRacesButton2:Enable();
        CharCreateRacesButton3:Enable();
        CharCreateRacesButton4:Enable();
        CharCreateRacesButton5:Enable();
        CharCreateRacesButton6:Enable();
        CharCreateRacesButton7:Enable();
        CharCreateRacesButton8:Enable();
        CharCreateRacesButton11:Enable();
        CharCreateRacesButton12:Enable();
        CharCreateRacesButton13:Enable();
        CharCreateRacesButton14:Enable();
        CharCreateRacesButton15:Enable();
        CharCreateRacesButton16:Enable();

        SetButtonDesaturated(CharCreateRacesButton1, false)
        SetButtonDesaturated(CharCreateRacesButton2, false)
        SetButtonDesaturated(CharCreateRacesButton3, false)
        SetButtonDesaturated(CharCreateRacesButton4, false)
        SetButtonDesaturated(CharCreateRacesButton5, false)
        SetButtonDesaturated(CharCreateRacesButton6, false)
        SetButtonDesaturated(CharCreateRacesButton7, false)
        SetButtonDesaturated(CharCreateRacesButton8, false)
        SetButtonDesaturated(CharCreateRacesButton11, false)
        SetButtonDesaturated(CharCreateRacesButton12, false)
        SetButtonDesaturated(CharCreateRacesButton13, false)
        SetButtonDesaturated(CharCreateRacesButton14, false)
        SetButtonDesaturated(CharCreateRacesButton15, false)
        SetButtonDesaturated(CharCreateRacesButton16, false)

        CharCreateRacesButton1:SetAlpha(1);
        CharCreateRacesButton2:SetAlpha(1);
        CharCreateRacesButton3:SetAlpha(1);
        CharCreateRacesButton4:SetAlpha(1);
        CharCreateRacesButton5:SetAlpha(1);
        CharCreateRacesButton6:SetAlpha(1);
        CharCreateRacesButton7:SetAlpha(1);
        CharCreateRacesButton8:SetAlpha(1);
        CharCreateRacesButton11:SetAlpha(1);
        CharCreateRacesButton12:SetAlpha(1);
        CharCreateRacesButton13:SetAlpha(1);
        CharCreateRacesButton14:SetAlpha(1);
        CharCreateRacesButton15:SetAlpha(1);
        CharCreateRacesButton16:SetAlpha(1);

    --	no_todas_clases();

end

function GlueParent_OnLoad(self)
--MOSTRAR_CREACIONES_NUEVAS = GetRacesOkFresh();
--NEW_ELFOS_CROSSOVER = GetElfOkFresh();
    local width = GetScreenWidth();
    local height = GetScreenHeight();

    if ( width / height > 16 / 9) then
        local maxWidth = height * 16 / 9;
        local barWidth = ( width - maxWidth ) / 2;
        self:ClearAllPoints();
        self:SetPoint("TOPLEFT", barWidth, 0);
        self:SetPoint("BOTTOMRIGHT", -barWidth, 0);
    end

    self:RegisterEvent("FRAMES_LOADED");
    self:RegisterEvent("SET_GLUE_SCREEN");
    self:RegisterEvent("START_GLUE_MUSIC");
    self:RegisterEvent("DISCONNECTED_FROM_SERVER");
    self:RegisterEvent("GET_PREFERRED_REALM_INFO");
    self:RegisterEvent("SERVER_SPLIT_NOTICE");
    self:RegisterEvent("ACCOUNT_MESSAGES_AVAILABLE");
    self:RegisterEvent("ACCOUNT_MESSAGES_HEADERS_LOADED");
    self:RegisterEvent("ACCOUNT_MESSAGES_BODY_LOADED");
end

function GlueParent_OnEvent(event, arg1, arg2, arg3)
    if ( event == "FRAMES_LOADED" ) then
        LocalizeFrames();
    elseif ( event == "SET_GLUE_SCREEN" ) then
        GlueScreenExit(GetCurrentGlueScreenName(), arg1);
    elseif ( event == "START_GLUE_MUSIC" ) then
        PlayLoginMusic();
        --PlayGlueMusic(CurrentGlueMusic);
        --PlayGlueAmbience(GlueAmbienceTracks["DARKPORTAL"], 4.0);
    elseif ( event == "DISCONNECTED_FROM_SERVER" ) then
        TokenEntry_Cancel(TokenEnterDialog);
        SetGlueScreen("login");
        if ( arg1 == 4 ) then
            GlueDialog_Show("PARENTAL_CONTROL");
        else
            GlueDialog_Show("DISCONNECTED");
        end
        AddonList:Hide();
    elseif ( event == "GET_PREFERRED_REALM_INFO" ) then
        if( arg1 == 1) then
            SetPreferredInfo(1);
        else
            SetGlueScreen("realmwizard");
            PlayGlueAmbience(GlueAmbienceTracks["DARKPORTAL"], 4.0);
        end
    elseif ( event == "SERVER_SPLIT_NOTICE" ) then
        CharacterSelectRealmSplitButton:Show();
        if ( SERVER_SPLIT_STATE_PENDING == -1 and arg1 == 0 and arg2 == 1 ) then
            SERVER_SPLIT_SHOW_DIALOG = true;
        end
        SERVER_SPLIT_CLIENT_STATE = arg1;
        SERVER_SPLIT_STATE_PENDING = arg2;
        SERVER_SPLIT_DATE = arg3;
    elseif ( event == "ACCOUNT_MESSAGES_AVAILABLE" ) then
--		ACCOUNT_MSG_NUM_AVAILABLE = arg1;
        ACCOUNT_MSG_HEADERS_LOADED = false;
        ACCOUNT_MSG_BODY_LOADED = false;
        ACCOUNT_MSG_CURRENT_INDEX = nil;
        AccountMsg_LoadHeaders();
    elseif ( event == "ACCOUNT_MESSAGES_HEADERS_LOADED" ) then
        ACCOUNT_MSG_HEADERS_LOADED = true;
        ACCOUNT_MSG_NUM_AVAILABLE = AccountMsg_GetNumUnreadMsgs();
        ACCOUNT_MSG_CURRENT_INDEX = AccountMsg_GetIndexNextUnreadMsg();
        if ( ACCOUNT_MSG_NUM_AVAILABLE > 0 ) then
            AccountMsg_LoadBody( ACCOUNT_MSG_CURRENT_INDEX );
        end
    elseif ( event == "ACCOUNT_MESSAGES_BODY_LOADED" ) then
        ACCOUNT_MSG_BODY_LOADED = true;
    end
end

-- Glue screen animation handling
function GlueScreenExit(currentFrame, pendingFrame)
    if ( currentFrame == "login" and pendingFrame == "charselect" ) then
        -- Authentication already succeeded. Enter character selection directly;
        -- the old full-screen fade made the ready page look stalled.
        AccountLoginUI:SetAlpha(1);
        SetGlueScreen(pendingFrame);
    else
        SetGlueScreen(pendingFrame);
    end
end

function GoToPendingGlueScreen()
    SetGlueScreen(GetPendingGlueScreenName());
end

-- Generic fade function
function GlueFrameFade(frame, timeToFade, mode, finishedFunction)
    if ( frame ) then
        frame.fadeTimer = 0;
        frame.timeToFade = timeToFade;
        frame.mode = mode;

        -- finishedFunction is an optional function that is called when the animation is complete
        if ( finishedFunction ) then
            frame.finishedFunction = finishedFunction;
        else
            frame.finishedFunction = nil;
        end
        tinsert(FADEFRAMES, frame);
    end
end

-- Fade in function
function GlueFrameFadeIn(frame, timeToFade, finishedFunction)
    GlueFrameFade(frame, timeToFade, "IN", finishedFunction);
end

-- Fade out function
function GlueFrameFadeOut(frame, timeToFade, finishedFunction)
    GlueFrameFade(frame, timeToFade, "OUT", finishedFunction);
end

-- Function that actually performs the alpha change
function GlueFrameFadeUpdate(elapsed)
    local index = 1;
    while FADEFRAMES[index] do
        local frame = FADEFRAMES[index];
        frame.fadeTimer = frame.fadeTimer + elapsed;
        if ( frame.fadeTimer < frame.timeToFade ) then
            if ( frame.mode == "IN" ) then
                frame:SetAlpha(frame.fadeTimer / frame.timeToFade);
            elseif ( frame.mode == "OUT" ) then
                frame:SetAlpha((frame.timeToFade - frame.fadeTimer) / frame.timeToFade);
            end
        else
            if ( frame.mode == "IN" ) then
                frame:SetAlpha(1.0);
            elseif ( frame.mode == "OUT" ) then
                frame:SetAlpha(0);
            end
            GlueFrameFadeRemoveFrame(frame);
            if ( frame.finishedFunction ) then
                if ( frame.finishedFunction == "HIDE" ) then
                    frame:Hide();
                    frame.finishedFunction = nil;
                else
                    frame.finishedFunction();
                    frame.finishedFunction = nil;
                end
            end
        end
        index = index + 1;
    end
end

function GlueFrameRemoveFrame(frame, list)
    local index = 1;
    while list[index] do
        if ( frame == list[index] ) then
            tremove(list, index);
        end
        index = index + 1;
    end
end

function GlueFrameFadeRemoveFrame(frame)
    GlueFrameRemoveFrame(frame, FADEFRAMES);
end

function SetLighting(model, race)
    model:SetSequence(0);
    model:SetCamera(0);
    local fogInfo = CharModelFogInfo[race];
    if ( fogInfo ) then
        model:SetFogColor(fogInfo.r, fogInfo.g, fogInfo.b);
        model:SetFogNear(0);
        model:SetFogFar(fogInfo.far);
    else
        model:ClearFog();
    end

    local glowInfo = CharModelGlowInfo[race];
    if ( glowInfo ) then
        model:SetGlow(glowInfo);
    else
        model:SetGlow(0.3);
    end

    model:ResetLights();
    --[[
    ResetLights() sets all 6 light sets to default for the background. The six sets are:

        background - live
        background - ghost
        character - live
        character - ghost
        pet - live
        pet - ghost

    If you add a light to any one of these, NONE of the default lights are used for that set (most backgrounds have 3).

    You can add up to four lights per light set in the current version. They are merged in the engine.

    The current version only supports setting directional lights, and pulls the default point lights from the models.
    ]]
    local LightValues = RaceLights[race];
    if(LightValues) then
        for index, Array in pairs (LightValues) do
            if (Array[1]==1) then	-- is this light enabled?
                for j, f in pairs ({model.AddCharacterLight, model.AddLight, model.AddPetLight }) do
                    f(model, LIGHT_LIVE, unpack(Array));
                end
            end
        end
    end
end

function chekbtone(vxsd)

        CharCreateCustomizationButton1:SetButtonState("NORMAL");
        CharCreateCustomizationButton2:SetButtonState("NORMAL");
        CharCreateCustomizationButton3:SetButtonState("NORMAL");
        CharCreateCustomizationButton4:SetButtonState("NORMAL");
        CharCreateCustomizationButton5:SetButtonState("NORMAL");
        CharCreateCustomizationButton1:SetChecked(nil);
        CharCreateCustomizationButton2:SetChecked(nil);
        CharCreateCustomizationButton3:SetChecked(nil);
        CharCreateCustomizationButton4:SetChecked(nil);
        CharCreateCustomizationButton5:SetChecked(nil);
end
function defOpCib5()
--	SetSelectedRace(CharacterCreate.selectedRace);
--	SetCharacterRace(CharacterCreate.selectedRace);
-- 	SetBackgroundModel(CharacterCreate, CharacterCreate.selectedRace);
end

-- Function to set the background model for character select and create screens
function SetBackgroundModelNewZoom(num)
    if(num == 1)then
        SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_ALLIANCE\\UI_Alliance.m2")
    else
        SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\male\\UI_AllianceZoomMale1.m2");
    end
end

function SetBackgroundModel(model, name, raza, zoom, gender)
 -- RACEUI1A: scene alias only. SelectCharacter still loads the real race model.
 if model==CharacterSelect and type(name)=="string" then
  local token=string.upper(name)
  if token=="REBORNSETHRAK" then name="Human"
  elseif token=="REBORNOGRE" then name="Orc" end
 end


    local nameupper = strupper(name);
    local ligthning = "BLOODELF"
    if(name == "NightElf" or name == "Scourge")then
        ligthning = "NIGHTELF"
    end
    local path = "Interface\\Glues\\Models\\UI_"..name.."\\UI_"..name..".m2";
    if ( model == CharacterCreate ) then
        if(raza == 900 or raza == 2000 )then
            if(GetSelectedSex() == SEX_MALE)then
                SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\custom\\UI_AllianceDoopel.m2")
            else
                if (nameupper == "HUMAN") then
                    SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_ALLIANCE\\UI_Alliance.m2")
                else
                    SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_HORDE\\UI_HORDE.m2")
                end
            end
        else
            if (nameupper == "ORC") then
                if(zoom == 1)then
                    CharacterCreateZoom2:SetNormalTexture("Interface\\Glues\\CharacterCreate\\ZoomButtom1")
                    CharacterCreateZoom1:SetNormalTexture("Interface\\Glues\\CharacterCreate\\ZoomButtom2p")

                    if(raza == 20)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\ui_demonhunter\\ui_demonhunter.m2");
                    elseif(raza == 12)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\orc\\normal\\z_orc_n.m2");
                    elseif(raza == 13)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\scourge\\normal\\z_scourge_n.m2");
                    elseif(raza == 14)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\tauren\\normal\\z_tauren_n.m2");
                    elseif(raza == 15)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\troll\\normal\\z_troll_n.m2");
                    elseif(raza == 16)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\goblin\\normal\\z_goblin_n.m2");
                    elseif(raza == 17)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\bloodelf\\normal\\z_bloodelf_n.m2");
                    elseif(raza == 21)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\ui_demonhunter\\ui_demonhunter.m2");
                    elseif(raza == 18)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\vulpera\\normal\\z_vulpera_n.m2");
                    elseif(raza == 19)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Pandaren\\UI_PandarenC.m2");
                    else
                        SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_HORDE\\UI_HORDE.m2")
                    end

                else
                    CharacterCreateZoom1:SetNormalTexture("Interface\\Glues\\CharacterCreate\\ZoomButtom2")
                    CharacterCreateZoom2:SetNormalTexture("Interface\\Glues\\CharacterCreate\\ZoomButtom1p")

                    if(CharacterCreateFrame.state == "CUSTOMIZATION")then
                        if(raza == 12)then
                            if(GetSelectedSex() == SEX_MALE )then
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\orc\\zoom\\z_orc_z.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Horde_Zoom\\male\\UI_HordeZoomMale1.m2");
                            else
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\orc\\zoom\\z_orc_z_female.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Horde_Zoom\\female\\UI_HordeZoomFemale1.m2");
                            end
                        elseif(raza == 14)then
                            if(GetSelectedSex() == SEX_MALE )then
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\tauren\\zoom\\z_tauren_z.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Horde_Zoom\\male\\UI_HordeZoomMale3.m2");
                            else
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\tauren\\zoom\\z_tauren_z_female.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Horde_Zoom\\female\\UI_HordeZoomFemale3.m2");
                            end
                        elseif(raza == 13)then
                            if(GetSelectedSex() == SEX_MALE )then
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\scourge\\zoom\\z_scourge_z.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Horde_Zoom\\male\\UI_HordeZoomMale2.m2");
                            else
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\scourge\\zoom\\z_scourge_z_female.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Horde_Zoom\\female\\UI_HordeZoomFemale2.m2");
                            end
                        elseif(raza == 15)then
                            if(GetSelectedSex() == SEX_MALE )then
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\troll\\zoom\\z_troll_z.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Horde_Zoom\\male\\UI_HordeZoomMale4.m2");
                            else
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\troll\\zoom\\z_troll_z_female.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Horde_Zoom\\female\\UI_HordeZoomFemale4.m2");
                            end
                        elseif(raza == 19)then
                            if(GetSelectedSex() == SEX_MALE )then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Pandaren\\UI_Pandaren_zoom1.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Horde_Zoom\\male\\UI_HordeZoomMale4.m2");
                            else
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Pandaren\\UI_Pandaren_zoom2.m2");
                        --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Horde_Zoom\\custom\\female\\UI_HordeZoomFemale6.m2");
                            end
                        elseif(raza == 16)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\goblin\\zoom\\z_goblin_z.m2");
                        elseif(raza == 21)then
                            if(GetSelectedSex() == SEX_MALE )then
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\ui_BloodElf_Dh_zoom\\ui_BloodElf_Dh_zoom.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Horde_Zoom\\male\\UI_HordeZoomMale5.m2");
                            else
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\ui_BloodElf_Dh_zoom\\ui_BloodElf_Dh_zoom.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Horde_Zoom\\female\\UI_HordeZoomFemale5.m2");
                            end
                        elseif(raza == 17)then
                            if(GetSelectedSex() == SEX_MALE )then
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\bloodelf\\zoom\\z_bloodelf_z.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Horde_Zoom\\male\\UI_HordeZoomMale5.m2");
                            else
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\bloodelf\\zoom\\z_bloodelf_z_female.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Horde_Zoom\\female\\UI_HordeZoomFemale5.m2");
                            end
                        elseif(raza == 18)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\vulpera\\zoom\\z_vulpera_z.m2")
                        elseif(raza == 20)then
                            if(GetSelectedSex() == SEX_MALE )then
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\ui_BloodElf_Dh_zoom\\ui_BloodElf_Dh_zoom.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Horde_Zoom\\male\\UI_HordeZoomMale5.m2");
                            else
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\ui_BloodElf_Dh_zoom\\ui_BloodElf_Dh_zoom.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Horde_Zoom\\female\\UI_HordeZoomFemale5.m2");
                            end
                        else
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_ALLIANCE\\UI_Alliance.m2")
                        end
                    else
                        SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_ALLIANCE\\UI_Alliance.m2")
                    end

                end
            elseif (nameupper == "HUMAN") then
                if(zoom == 1)then
                    CharacterCreateZoom2:SetNormalTexture("Interface\\Glues\\CharacterCreate\\ZoomButtom1")
                    CharacterCreateZoom1:SetNormalTexture("Interface\\Glues\\CharacterCreate\\ZoomButtom2p")

                    if(raza == 8)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\Worgen\\normal\\z_Worgen_n.m2");
                    elseif(raza == 4)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\gnome\\normal\\z_gnome_n.m2");
                    elseif(raza == 1)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\human\\normal\\z_human_n.m2");
                    elseif(raza == 2)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\enano\\normal\\z_dwarf_n.m2");
                    elseif(raza == 11)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\ui_demonhunter\\ui_demonhunter.m2");
                    elseif(raza == 3)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\nightelf\\normal\\z_nightelf_n.m2");
                    elseif(raza == 5)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\draenei\\normal\\z_draenei_n.m2");
                    elseif(raza == 6)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\Elfo_del_vacio\\normal\\z_Elfo_del_vacio_n.m2");
                    elseif(raza == 7)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\human\\normal\\z_human_n.m2");
                    elseif(raza == 10)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\lightforgeddraenei\\normal\\z_lightforgeddraenei_n.m2");
                    else
                        SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_ALLIANCE\\UI_Alliance.m2")
                    end

                else
                    CharacterCreateZoom1:SetNormalTexture("Interface\\Glues\\CharacterCreate\\ZoomButtom2")
                    CharacterCreateZoom2:SetNormalTexture("Interface\\Glues\\CharacterCreate\\ZoomButtom1p")

                    if(CharacterCreateFrame.state == "CUSTOMIZATION")then
                        if(raza == 1)then
                            if(GetSelectedSex() == SEX_MALE )then
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\human\\zoom\\z_human_z.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\male\\UI_AllianceZoomMale1.m2");
                            else
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\human\\zoom\\z_human_z_female.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\female\\UI_AllianceZoomFemale1.m2");
                            end
                        end
                        if(raza == 2)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\enano\\zoom\\z_dwarf_z.m2");
                        --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\male\\UI_AllianceZoomMale2.m2");
                        end
                        if(raza == 11)then
                            if(GetSelectedSex() == SEX_MALE )then
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\ui_NightElf_Dh_zoom\\ui_NightElf_Dh_zoom.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\male\\UI_AllianceZoomMale3.m2");
                            else
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\ui_NightElf_Dh_zoom\\ui_NightElf_Dh_zoom.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\female\\UI_AllianceZoomFemale2.m2");
                            end
                        end
                        if(raza == 3)then
                            if(GetSelectedSex() == SEX_MALE )then
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\nightelf\\zoom\\z_nightelf_z.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\male\\UI_AllianceZoomMale3.m2");
                            else
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\nightelf\\zoom\\z_nightelf_z_female.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\female\\UI_AllianceZoomFemale2.m2");
                            end
                        end
                        if(raza == 4)then
                            SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\gnome\\zoom\\z_gnome_z.m2");
                        --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\male\\UI_AllianceZoomMale4.m2");
                        end
                        if(raza == 5)then
                            if(GetSelectedSex() == SEX_MALE )then
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\draenei\\zoom\\z_draenei_z.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\male\\UI_AllianceZoomMale3.m2");
                            else
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\draenei\\zoom\\z_draenei_z_female.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\female\\UI_AllianceZoomFemale2.m2");
                            end
                        end
                        if(raza == 7)then
                            if(GetSelectedSex() == SEX_MALE )then
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\human\\zoom\\z_human_z.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\male\\UI_AllianceZoomMale1.m2");
                            else
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\human\\zoom\\z_human_z_female.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\female\\UI_AllianceZoomFemale1.m2");
                            end
                        end
                        if(raza == 10)then
                            if(GetSelectedSex() == SEX_MALE )then
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\lightforgeddraenei\\zoom\\z_lightforgeddraenei_z.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\male\\UI_AllianceZoomMale1.m2");
                            else
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\lightforgeddraenei\\zoom\\z_lightforgeddraenei_z_female.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\female\\UI_AllianceZoomFemale1.m2");
                            end
                        end
                        if(raza == 6)then
                            if(GetSelectedSex() == SEX_MALE )then
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\Elfo_del_vacio\\zoom\\z_Elfo_del_vacio_z.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\male\\UI_AllianceZoomMale1.m2");
                            else
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\Elfo_del_vacio\\zoom\\z_Elfo_del_vacio_z_female.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\female\\UI_AllianceZoomFemale1.m2");
                            end
                        end
                        if(raza == 8)then
                            if(GetSelectedSex() == SEX_MALE )then
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\Worgen\\zoom\\z_Worgen_z.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\Custom\\male\\UI_AllianceZoomMale6.m2");
                            else
                                SetCharCustomizeBackground("Interface\\Glues\\Models\\zoom\\Worgen\\zoom\\z_Worgen_z_female.m2");
                            --	SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_Alliance_Zoom\\Custom\\female\\UI_AllianceZoomFemale4.m2");
                            end
                        end
                    else
                        SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_ALLIANCE\\UI_Alliance.m2")
                    end
                end
            else
                SetCharCustomizeBackground(path);
            end
        end
    else
        GLOBAL_RACE_CHANGE = 0;
        if(name == "Skeleton" or name == "Tuskarr")then
            SetCharSelectBackground("Interface\\Glues\\Models\\ui_demonhunter\\ui_demonhunter.m2")
        elseif(name == "FelOrc")then
            SetCharSelectBackground("Interface\\Glues\\Models\\UI_Elfo_del_vacio\\UI_Elfo_del_vacio.m2")
        elseif(name == "Broken")then
            SetCharSelectBackground("Interface\\Glues\\Models\\ui_human\\UI_Human.m2")
        elseif(name == "Naga_")then
            SetCharSelectBackground("Interface\\Glues\\Models\\ui_vulpera\\ui_vulpera.m2")
        elseif(name == "Gnome")then
            SetCharSelectBackground("Interface\\Glues\\Models\\UI_Gnome\\ui_gnome.m2")
        elseif(name == "Troll")then
            SetCharSelectBackground("Interface\\Glues\\Models\\UI_Troll\\UI_Troll.m2")
        elseif(name == "ForestTroll")then
            SetCharSelectBackground("Interface\\Glues\\Models\\UI_Pandaren\\UI_Pandaren.m2")
        elseif(name == "Taunka")then
            SetCharSelectBackground("Interface\\Glues\\Models\\ui_lightforgeddraenei\\ui_lightforgeddraenei.m2")
        elseif(name == "NorthrendSkeleton" or name == "IceTroll")then
            SetCharSelectBackground("Interface\\Glues\\Models\\ui_demonhunter\\ui_demonhunter.m2")
        elseif(name == "Human")then
            SetCharSelectBackground("Interface\\Glues\\Models\\ui_kultiran\\ui_kultiran.m2")
        elseif(name == "Tauren")then
            SetCharSelectBackground("Interface\\Glues\\Models\\ui_highmountaintauren\\ui_highmountaintauren.m2")
        elseif(name == "Orc")then
            SetCharSelectBackground("Interface\\Glues\\Models\\UI_Troll\\UI_Troll.m2")

        else
            SetCharSelectBackground(path);
        end
    end
    --PlayGlueAmbience(GlueAmbienceTracks[nameupper], 4.0);
    SetLighting(model, ligthning)
end
function SetBackgroundModelRespaldo(model, name)
    local nameupper = strupper(name);
    local path = "Interface\\Glues\\Models\\UI_"..name.."\\UI_"..name..".m2";
    if ( model == CharacterCreate ) then
        if (nameupper == "ORC") then
            SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_HORDE\\UI_HORDE.m2")
        elseif (nameupper == "HUMAN") then
            SetCharCustomizeBackground("Interface\\Glues\\Models\\UI_ALLIANCE\\UI_Alliance.m2")
        else
            SetCharCustomizeBackground(path);
        end
    else
        SetCharSelectBackground(path);
    end
    --PlayGlueAmbience(GlueAmbienceTracks[nameupper], 4.0);
    SetLighting(model, nameupper)
end

-- function SetBackgroundCreateModel(model, race)
-- 	local path="";
-- 	local character;
-- 	local _, classFilename = GetSelectedClass();
--
-- -- DeathKnight

-- 	end
--
--   local path = "Interface\\Glues\\Models\\UI_"..race.."\\UI_"..race..".m2";
--
--   if ( model == CharacterCreate ) then
--      SetCharCustomizeBackground(path);
--   else
--      SetCharSelectBackground(path);
--   end
--
--   SetLighting(model, nameupper)
-- end

function SecondsToTime(seconds, noSeconds)
    local time = "";
    local count = 0;
    local tempTime;
    seconds = floor(seconds);
    if ( seconds >= 86400  ) then
        tempTime = floor(seconds / 86400);
        time = tempTime.." "..DAYS_ABBR.." ";
        seconds = mod(seconds, 86400);
        count = count + 1;
    end
    if ( seconds >= 3600  ) then
        tempTime = floor(seconds / 3600);
        time = time..tempTime.." "..HOURS_ABBR.." ";
        seconds = mod(seconds, 3600);
        count = count + 1;
    end
    if ( count < 2 and seconds >= 60  ) then
        tempTime = floor(seconds / 60);
        time = time..tempTime.." "..MINUTES_ABBR.." ";
        seconds = mod(seconds, 60);
        count = count + 1;
    end
    if ( count < 2 and seconds > 0 and not noSeconds ) then
        seconds = format("%d", seconds);
        time = time..seconds.." "..SECONDS_ABBR.." ";
    end
    return time;
end

function MinutesToTime(mins, hideDays)
    local time = "";
    local count = 0;
    local tempTime;
    -- only show days if hideDays is false
    if ( mins > 1440 and not hideDays ) then
        tempTime = floor(mins / 1440);
        time = tempTime.." "..DAYS_ABBR.." ";
        mins = mod(mins, 1440);
        count = count + 1;
    end
    if ( mins > 60  ) then
        tempTime = floor(mins / 60);
        time = time..tempTime.." "..HOURS_ABBR.." ";
        mins = mod(mins, 60);
        count = count + 1;
    end
    if ( count < 2 ) then
        tempTime = mins;
        time = time..tempTime.." "..MINUTES_ABBR.." ";
        count = count + 1;
    end
    return time;
end

function TriStateCheckbox_SetState(checked, checkButton)
    local checkedTexture = _G[checkButton:GetName().."CheckedTexture"];
    if ( not checkedTexture ) then
        message("Can't find checked texture");
    end
    if ( not checked or checked == 0 ) then
        -- nil or 0 means not checked
        checkButton:SetChecked(nil);
        checkButton.state = 0;
    elseif ( checked == 2 ) then
        -- 2 is a normal
        checkButton:SetChecked(1);
        checkedTexture:SetVertexColor(1, 1, 1);
        checkedTexture:SetDesaturated(0);
        checkButton.state = 2;
    else
        -- 1 is a gray check
        checkButton:SetChecked(1);
        local shaderSupported = checkedTexture:SetDesaturated(1);
        if ( not shaderSupported ) then
            checkedTexture:SetVertexColor(0.5, 0.5, 0.5);
        end
        checkButton.state = 1;
    end
end

function SetStateRequestInfo( choice )
    if ( SERVER_SPLIT_CLIENT_STATE ~= choice ) then
        SERVER_SPLIT_CLIENT_STATE = choice;
        SetRealmSplitState(choice);
        RealmSplit_SetChoiceText();
--		RequestRealmSplitInfo();
    end
end

function UpgradeAccount()
    PlaySound("gsLoginNewAccount");
    LaunchURL(AUTH_NO_TIME_URL);
end


function CharacterSelect_SetFaction(self, button)
     if ( self == "Alliance") then
            button:SetNormalTexture("Interface\\Glues\\Common\\Glue-Panel-Button-Up-Blue");
            button:SetPushedTexture("Interface\\Glues\\Common\\Glue-Panel-Button-Down-Blue");
            button:SetHighlightTexture("Interface\\Glues\\Common\\Glue-Panel-Button-Highlight-Blue");
     elseif ( self == "Horde") then
            button:SetNormalTexture("Interface\\Glues\\Common\\Glue-Panel-Button-Up");
            button:SetPushedTexture("Interface\\Glues\\Common\\Glue-Panel-Button-Down");
            button:SetHighlightTexture("Interface\\Glues\\Common\\Glue-Panel-Button-Highlight");
     else
            button:SetNormalTexture("Interface\\Glues\\Common\\Glue-Panel-Button-Up-Green");
            button:SetPushedTexture("Interface\\Glues\\Common\\Glue-Panel-Button-Down-Green");
            button:SetHighlightTexture("Interface\\Glues\\Common\\Glue-Panel-Button-Highlight-Green");

     end
end

function OnUpdateStats()
                -- SetLighting(CharacterCreate, "HUMAN")
 if ( GLOBAL_ZOOM_POS == 0) then -- COLOR DE PIEL
        CharCreateCustomizationButton1:SetChecked(1);
        CharCreateCustomizationButton1:SetButtonState("PUSHED", 1);
        GLOBAL_ZOOM_POS_22 = 0;
 end

 if ( GLOBAL_ZOOM_POS == 1) then -- ROSTRO
    if ( CharacterCreateFrame.state == "CUSTOMIZATION" ) then
        SetFondoZoom();
    else
        GLOBAL_ZOOM_POS_22 = 0;
    end
        CharCreateCustomizationButton2:SetChecked(1);
        CharCreateCustomizationButton2:SetButtonState("PUSHED", 1);
 end
 if ( GLOBAL_ZOOM_POS == 2) then -- PEINADO
    if ( CharacterCreateFrame.state == "CUSTOMIZATION" ) then
        SetFondoZoom();
    else
        GLOBAL_ZOOM_POS_22 = 0;
    end
        CharCreateCustomizationButton3:SetChecked(1);
        CharCreateCustomizationButton3:SetButtonState("PUSHED", 1);
 end
 if ( GLOBAL_ZOOM_POS == 3) then -- COLOR DE PELO
    if ( CharacterCreateFrame.state == "CUSTOMIZATION" ) then
        SetFondoZoom();
    else
        GLOBAL_ZOOM_POS_22 = 0;
    end
        CharCreateCustomizationButton4:SetChecked(1);
        CharCreateCustomizationButton4:SetButtonState("PUSHED", 1);
 end
 if ( GLOBAL_ZOOM_POS == 4) then -- CARACTERISTICAS
    if ( CharacterCreateFrame.state == "CUSTOMIZATION" ) then
        SetFondoZoom();
    else
        GLOBAL_ZOOM_POS_22 = 0;
    end
        CharCreateCustomizationButton5:SetChecked(1);
        CharCreateCustomizationButton5:SetButtonState("PUSHED", 1);
 end

end

function SetFondoZoom()

    if ( CharacterCreate.selectedRace == GetBGluSpecil("Draenei templeluz",1) and GetSelectedSex() == SEX_MALE ) then
        GLOBAL_ZOOM_POS_22 = 1;
    end
    if ( CharacterCreate.selectedRace == GetBGluSpecil("Draenei templeluz",1) and GetSelectedSex() == SEX_FEMALE ) then
        GLOBAL_ZOOM_POS_22 = 2;
    end
    if ( CharacterCreate.selectedRace == GetBGluSpecil("Draenei Forjaluz",1) and GetSelectedSex() == SEX_MALE ) then
        GLOBAL_ZOOM_POS_22 = 1;
    end
    if ( CharacterCreate.selectedRace == GetBGluSpecil("Draenei Forjaluz",1) and GetSelectedSex() == SEX_FEMALE ) then
        GLOBAL_ZOOM_POS_22 = 2;
    end
    if ( CharacterCreate.selectedRace == GetBGluSpecil("Draenei",1) and GetSelectedSex() == SEX_MALE ) then
        GLOBAL_ZOOM_POS_22 = 1;
    end
    if ( CharacterCreate.selectedRace == GetBGluSpecil("Draenei",1) and GetSelectedSex() == SEX_FEMALE ) then
        GLOBAL_ZOOM_POS_22 = 2;
    end
    if ( CharacterCreate.selectedRace == GetBGluSpecil("Enano",1) ) then
        GLOBAL_ZOOM_POS_22 = 1;
    end
    if ( CharacterCreate.selectedRace == GetBGluSpecil("Elfo de la noche",1) or CharacterCreate.selectedRace == GetBGluSpecil("Huargen",1) ) then
        GLOBAL_ZOOM_POS_22 = 1;
    end
    if ( CharacterCreate.selectedRace == GetBGluSpecil("Gnomo",1) ) then
        GLOBAL_ZOOM_POS_22 = 1;
    end
    if ( CharacterCreate.selectedRace == GetBGluSpecil("Humano",1) or CharacterCreate.selectedRace == GetBGluSpecil("Elfo del vacio",1)) then
        GLOBAL_ZOOM_POS_22 = 1;
    end
    if ( CharacterCreate.selectedRace == GetBGluSpecil("No muerto",1) ) then
        GLOBAL_ZOOM_POS_22 = 1;
    end
    if ( CharacterCreate.selectedRace == GetBGluSpecil("Elfo de sangre",1) ) then
        GLOBAL_ZOOM_POS_22 = 1;
    end
    if ( CharacterCreate.selectedRace == GetBGluSpecil("Orco",1) and GetSelectedSex() == SEX_FEMALE ) then
        GLOBAL_ZOOM_POS_22 = 2;
    end
    if ( CharacterCreate.selectedRace == GetBGluSpecil("Tauren",1) and GetSelectedSex() == SEX_MALE ) then
        GLOBAL_ZOOM_POS_22 = 1;
    end
    if ( CharacterCreate.selectedRace == GetBGluSpecil("Orco",1) and GetSelectedSex() == SEX_MALE ) then
        GLOBAL_ZOOM_POS_22 = 1;
    end
    if ( CharacterCreate.selectedRace == GetBGluSpecil("Tauren",1) and GetSelectedSex() == SEX_FEMALE ) then
        GLOBAL_ZOOM_POS_22 = 2;
    end
    if ( CharacterCreate.selectedRace == GetBGluSpecil("Troll",1)) then
        GLOBAL_ZOOM_POS_22 = 1;
    end
    if ( CharacterCreate.selectedRace == GetBGluSpecil("Natonocturno",1) and GetSelectedSex() == SEX_MALE ) then
        GLOBAL_ZOOM_POS_22 = 1;
    end
    if ( CharacterCreate.selectedRace == GetBGluSpecil("Natonocturno",1) and GetSelectedSex() == SEX_FEMALE ) then
        GLOBAL_ZOOM_POS_22 = 2;
    end
    if ( CharacterCreate.selectedRace == GetBGluSpecil("Nocheterna",1) and GetSelectedSex() == SEX_MALE ) then
        GLOBAL_ZOOM_POS_22 = 1;
    end
    if ( CharacterCreate.selectedRace == GetBGluSpecil("Nocheterna",1) and GetSelectedSex() == SEX_FEMALE ) then
        GLOBAL_ZOOM_POS_22 = 2;
    end
    if ( CharacterCreate.selectedRace == GetBGluSpecil("Goblin",1) ) then
        GLOBAL_ZOOM_POS_22 = 1;
    end
    if ( CharacterCreate.selectedRace == GetBGluSpecil("Vulpera",1) ) then
        GLOBAL_ZOOM_POS_22 = 1;
    end
    if ( CharacterCreate.selectedRace == GetBGluSpecil("Panda Horda",1)) then
        GLOBAL_ZOOM_POS_22 = 1;
    end
    if ( CharacterCreate.selectedRace == GetBGluSpecil("Panda Alianza",1) ) then
        GLOBAL_ZOOM_POS_22 = 1;
    end
    if ( CharacterCreate.selectedRace == GetBGluSpecil("Doppel Alianza",1)) then
        GLOBAL_ZOOM_POS_22 = 1;
    end
    if ( CharacterCreate.selectedRace == GetBGluSpecil("Doppel Horda",1)) then
        GLOBAL_ZOOM_POS_22 = 1;
    end
end
