# Runtime repair checkpoint — 2026-09-15

This commit records the installed source changes accumulated after 958e054b7.
It is a source checkpoint, not a claim that every change has passed full runtime validation.

## Included

- Monk combat scripts, starter skills and stagger-pool implementation.
- Independent third talent build storage, two-group client projection, preview versus activation, native cancellable activation cast and asynchronous action-bar guards.
- Third-build enrollment module, configuration, GM/gold/VP handling; this previously ignored module is now tracked.
- Monk armor restrictions and first-phase race creation whitelist.
- Glyph collection and native aura diagnostic source files previously hidden by the module ignore rule.
- Breaking News deferred delivery changes and retirement of the locally removed bundled client examples.
- Ninja/Visual Studio configuration macro compatibility.
- ALE, Playerbots and starting-pet dependency changes are identified by their submodule commits when available remotely.

## Validation boundaries

The user confirmed basic three-build switching and persistence, and allowed-race creation / disabled disallowed-race buttons. This commit does not establish complete combat, payment, client stability, or all race/gender regression coverage. No C++ build or live database migration was run as part of committing this checkpoint.

Client DLL/MPQ changes live outside this source repository and are not included. Existing deployment packages remain authoritative for their separate assets and database migrations. Do not assume cloning this source repository installs those assets or migrates existing characters.

Windows executable-bit-only changes and unrelated PSD differences were deliberately left uncommitted. Existing source line endings were preserved rather than mixing broad normalization into the checkpoint.

The DungeonScale configuration copy in this directory preserves the local addition of item 25462 to `DungeonScale.RewardScaling.Loot.ExceptionItemIDs`. Its external upstream submodule was not changed or pushed; apply this configuration delta deliberately if restoring that local setting.
