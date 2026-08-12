# beAscend three-mode SpellDraft integration

This branch collects the source-side integration developed during stages A.8–A.26:

- server-authoritative Classic / Random Draft / Free Pick mode framework;
- legal draft persistence and anti-cheat ordering fixes;
- level-one Random Draft Death Knight route;
- custom-race same-faction quest and reputation compatibility;
- character-select progression badges;
- cross-class hunter-pet and stable compatibility;
- adaptive right-click melee/ranged selection for classless modes;
- SpellDraft client addon and server Lua sources.

Free Pick remains intentionally server-locked until its point economy and validation pipeline are complete.

## Repository layout note

`mod-ale` and `mod-starting-pet` are Git submodules. Their local changes cannot be represented by the parent repository unless the child repositories are published first. Reproducible Git patches are therefore stored in `submodule-patches/` and can be applied inside each child repository with `git apply`.

The source release intentionally excludes build products, runtime caches, extracted MPQ files and DBC binary baselines.
