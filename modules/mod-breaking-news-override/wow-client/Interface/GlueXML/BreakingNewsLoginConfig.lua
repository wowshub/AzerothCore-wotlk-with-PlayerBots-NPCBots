-- Breaking News login-page configuration.
-- Keep BREAKING_NEWS_DISPLAY_MODE synchronized with
-- configs/modules/breakingnews.conf on the server.
-- 0 = disabled, 1 = login only, 2 = character selection only, 3 = both.
BREAKING_NEWS_DISPLAY_MODE = 3;

-- Login-page window placement.
-- true: drag the panel with the left mouse button. The dragged position is
-- remembered until the client exits when REMEMBER is also true.
-- false: lock the panel to POINT/RELATIVE_POINT/OFFSET_X/OFFSET_Y below.
BREAKING_NEWS_LOGIN_MOVABLE = true;
BREAKING_NEWS_LOGIN_REMEMBER_DRAGGED_POSITION = true;
BREAKING_NEWS_LOGIN_POINT = "TOPLEFT";
BREAKING_NEWS_LOGIN_RELATIVE_POINT = "TOPLEFT";
BREAKING_NEWS_LOGIN_OFFSET_X = 10;
BREAKING_NEWS_LOGIN_OFFSET_Y = -130;

BREAKING_NEWS_LOGIN_TITLE = "服务器条款 / Server Terms";

-- false keeps this local terms page stable. Set true only when
-- SERVER_ALERT_URL is a trusted endpoint that returns compatible HTML.
BREAKING_NEWS_ACCEPT_NATIVE_SERVER_ALERT = false;

-- This is the login-page HTML body. The 3.3.5 GlueXML sandbox cannot read an
-- arbitrary local .html file before authentication, so the login body is kept
-- here. Character-selection content remains in server-side
-- breakingnews_character.html and can be changed independently.
BREAKING_NEWS_LOGIN_HTML = [[
<html>
<body>
<p>|cffFFD100欢迎来到 rebornWOW|r</p>
<br/>
<p>登录并使用本服务器即表示你同意遵守以下服务器条款：</p>
<p>1. 请尊重其他玩家，不骚扰、不冒充管理人员。</p>
<p>2. 不得利用漏洞、作弊程序或自动化工具破坏游戏公平。</p>
<p>3. 测试期间角色、物品和进度可能因维护或修复而调整。</p>
<p>4. 发现漏洞时请停止扩散并及时向管理团队报告。</p>
<br/>
<p>|cffFF6F51请在正式开放前按实际运营规则修改本页文字。|r</p>
</body>
</html>
]];
