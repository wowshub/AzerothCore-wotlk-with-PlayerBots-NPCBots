# RebornWOW source update summary — 2026-07-19

This commit series collects the reproducible core-source changes completed after the
previous `wowshub/longandnaga` push (`bff2ff8fb`).

The changes are intentionally split into separate commits for the 99-slot
stable, Naga passives, earlier pending Dracthyr flight safeguards, and earlier
pending custom-race/reputation integration.

## 99-slot hunter pet stable

- Raise `MAX_PET_STABLES` from 4 to 99 while keeping slot value 100 reserved
  for `PET_SAVE_NOT_IN_SLOT`.
- Continue using `StableSlotPrices.dbc` as the authoritative purchase-price
  table and reject missing rows safely instead of dereferencing a null entry.
- Runtime deployment also requires the matching 1..99 client/server DBC and
  the separately archived stable99 client executable; those binary assets are
  not stored in this source repository.

Files:

- `src/server/game/Entities/Pet/PetDefines.h`
- `src/server/game/Handlers/NPCHandler.cpp`

## Custom-race definitions and integration

- Add explicit race constants for Alliance Pandaren, Nightborne, and Dark Iron
  Dwarf while retaining the Forest Troll compatibility alias for Zandalari.
- Extend playable/alliance race masks.
- Map Naga reputation checks to the Orc parent race and Dracthyr reputation
  checks to the Human parent race without changing their real character race.
- Apply the same reputation mapping to online initialization, visibility, and
  offline/base-reputation queries.
- Add custom-race totem fallbacks and NPCBot display mappings.

Files:

- `src/server/shared/SharedDefines.h`
- `src/server/game/Globals/ObjectMgr.cpp`
- `src/server/game/Reputation/ReputationMgr.cpp`
- `src/server/game/AI/NpcBots/botcommands.cpp`

## Naga racial behavior

- Disable the breath mirror timer for Race 25 so Naga can breathe underwater
  indefinitely.
- Enforce a +150% swim-speed baseline.
- Teach the custom passive spellbook entries 100301 and 100302 on login and
  refresh swim speed immediately.

Files:

- `src/server/game/Entities/Player/Player.cpp`
- `src/server/game/Entities/Unit/Unit.cpp`
- `src/server/scripts/Custom/TwoForms/TwoForms.cpp`

## Dracthyr flight safety

- Make movement interrupt the Skyburst/flight cast (spell 100210).
- Reject flight activation indoors and on instanceable maps.
- Revoke active flight when entering an indoor or instanceable area.

Files:

- `src/server/game/Spells/SpellInfoCorrections.cpp`
- `src/server/scripts/Custom/TwoForms/TwoForms.cpp`

## Scope intentionally excluded

- Windows-only executable-bit changes on shell scripts are not source edits
  and are intentionally left out.
- PSD binary changes are not part of the server-source update.
- `modules/mod-dungeon-scale` and `modules/mod-playerbots` currently point at
  locally checked-out revisions; `mod-playerbots` also has an uncommitted
  nested-repository change. Their parent gitlinks are excluded so this commit
  never references a nested commit that is unavailable from its own remote.
- `StableSlotPrices.dbc`, `PetStable.lua`, and `PetStable.xml` are client/server
  runtime resources maintained by the MPQ/resource-package workflow, not this
  AzerothCore source repository.
- `RebornCustomMapRightClickFix.lua` is a client loose addon file maintained by
  the client resource workflow. Its guarded `GetScript` lookup is therefore in
  the cumulative runtime package rather than this Git commit series.

## Runtime archive

The matching client/server DBC, stable99 executable, stable client DLL, source
rebuild inputs, and compiled server binaries are preserved outside Git in the
local Stage 30 cumulative package documented by the project maintenance log.
