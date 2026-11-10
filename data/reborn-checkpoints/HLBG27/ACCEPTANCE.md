# HLBG V27 acceptance record (2026-11-10)

Stage: Hinterland Battleground port (map 20411, BG type 20, queue 14), cumulative package V1-V27.

## What the user confirmed in game
- 2026-11-10: "这个也可以啦" for V27. Confirmed scope: bots leaving the Alliance start follow the six `.gps`
  waypoints (155.19,-4755.04) .. (-4.47,-4652.52) and no longer walk into the sea or get stuck at the start.
- Earlier user-confirmed items in the same line: HUD display, prep-phase icon, respawn at the pier, bots no longer
  in water, bot routes at the Alliance start.

## Not yet confirmed (do not read as accepted)
- Horde-side route through the Troll hotel/mall gap (waiting for the user's `.gps` points).
- Window picture layout, M map fit, HOUSEFIX1A tower collision, emblem removal (conf reward lines must be set to 0).
- NPC collision on the towers is unchanged.

## Contents of this commit
- New module `modules/mod-reborn-bg-hinterland` (battleground, conf.dist, manual SQL).
- `modules/mod-playerbots` gitlink -> 455139a3 (wowshub/mod-playerbots branch reborn-dcai1a-20261009):
  DCHinterlandTactics / Strategy / Routes (generated) plus wiring in ActionContext, StrategyContext, AiFactory,
  BattleGroundJoinAction.
- Binary resources (vmaps/mmaps/maps, DBC, BLP, addons) stay in the delivered V27 package, not in Git.

## Verification state
Server code: MSVC /Zs syntax check only, plus the user's own compile and in-game test of package V27.
Source: upstream DarkChaos-255 Hinterland BG, adapted; route tool scripts are in the V27 package (工具_路线生成).
