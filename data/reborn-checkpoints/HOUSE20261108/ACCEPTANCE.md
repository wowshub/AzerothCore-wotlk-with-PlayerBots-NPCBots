# HOUSE20261108: housing release (Claude, 2026-11-08)

User confirmations (in chat, 2026-11-08): the world-pieces window, history/restore, right-click local edit + sync and the
server-pieces-first ordering "all pass"; then "push first, develop afterwards". In the scope question the user ticked plot upgrade
(PLOTUP1A), the 120-piece decor batch (DECORBATCH1A), the WMO take-down (WMOHIDE1A) and the all-plots list (OTHERSEL1A) as tested and passed.
Per-piece results of the 120 decor pieces and of the 16 HOUSE3C buildings were not itemized; they are not extended here.

## Server (module mod-reborn-housing, RebornHousing.cpp sha256 d042e0d495ee682f...)
- WORLDPUT1A: a GM can place outside every plot; such pieces are "world pieces" (plot_id 0), GM only, no per-plot cap.
- PLOTUP1A: `.home plot resize` (pay the price difference, enlarge only, circle/square, refused without any change when it would touch another plot).
- WORLDLIST1A: `.home ui world`, `.home world tp/remove/removeall`; reborn_housing_object gets placed_by / placed_at (added automatically on start).
- WORLDHIST1A: table reborn_housing_world_log (created automatically), `.home ui worldlog`, `.home world tplog/restore`; restore re-creates one piece in the state of a history row.
- OTHERSEL1A: `.home ui all` includes the caller's own plots first and carries the owner's character name.
- Checked offline: MSVC cl /Zs syntax check on the module file (a planted error is reported, so the check works). Not compiled into a worldserver by the assistant.

## SQL (data/customfixsql/world/housing/)
- HOUSE3C: 16 modern M2 buildings (catalog 10701-10716). DECORBATCH1A: 120 modern M2 decor pieces (catalog 10801-10920, display ids 940001-940120).
- WMOHIDE1A: sets catalog 10601-10608 (the 8 HOUSE3B WMO houses) to enabled = 0, category wmo_houses. Reason: server-spawned WMO objects show as blue/white cubes on this client (tested 2026-11-07); the WMO line stays open as its own category.
- Run by the user on the world DB; not run by the assistant.

## Client
- wxl-reborn commit 1212e56 (wowshub/wxl-reborn main): plot upgrade menu, GM "World plot" window with History tab, all-plots list with furniture window, S-first catalog sort, Chinese entries.
- Resource zip (Release attachment): wxl-housing.dll 6b3cd077f556ebed, server_catalog.tsv (552 rows), hide/show_wmo_houses.bat, GameObjectDisplayInfo.dbc 5e56d6d587cc7f5e (same file for server Data/dbc and client Patch-XA; base was 99fe23daf84f45d8).

## Not verified / limits
- WMO houses still do not render on the server; they are only hidden. No fix claimed.
- History keeps every row (shows the newest 300); only world pieces are logged, not pieces inside plots.
- A restored (taken-back) piece gets a new object id.
- No compile of the worldserver by the assistant; no production SQL, no deploy, no launcher upload.
