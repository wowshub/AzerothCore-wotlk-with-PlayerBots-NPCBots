# mod-breaking-news-override

HighFork-compatible Breaking News delivery for the 3.3.5 login and character-selection screens.

- `src/`: worldserver delivery with bounded Warden initialization retries and hex-safe Lua transport.
- `conf/`: display mode, title, HTML path, cache, logging, and retry configuration.
- `data/breakingnews_character.html`: editable character-selection update sample.
- `wow-client/Interface/GlueXML/`: login terms, login-only/character-only/both display modes, and movable/fixed login panel configuration.

The account-login page runs before a worldserver session exists, so its terms and placement are configured in `BreakingNewsLoginConfig.lua`. Keep its `BREAKING_NEWS_DISPLAY_MODE` value synchronized with `BreakingNews.DisplayMode` in the server configuration.

The client files are complete overwrite files for the matching customized HighFork client baseline. Merge them into the client patch project and rebuild the MPQ instead of copying them into a running AddOns directory.
