# SETHARMOR20261108: Sethrak body-armour overlay (Claude, 2026-11-08)

User confirmations (chat, 2026-11-08): male v8 "this time the painted armour is much more symmetric and good-looking" (screenshot of the character-select screen),
female v8 "the female one is also great" (screenshot of the character-select screen), then "passed, this design is great". Male v7 was also seen in game (equipment shown, running without flicker).

## What it is
A client-only change (Patch-YJ import, no server, SQL, DBC or DLL): the Sethrak male and female models get an extra opaque "armour overlay" layer so chest / legs / glove / boot textures draw on the body.
- extra character-skin (type 1) texture slot + lookup, replaceable-texture entry 1, UV2 laid out on the standard character texture rectangles, mirrored left/right (the standard texture is shared by both body halves);
- the race skin is baked into the 512x512 palettised composite base (same BLP layout as the original), the face/underwear bake textures (FL/FU/LU/TU) are replaced by the matching crops;
- only the always-on body mesh gets the overlay (the triangles of that section are reordered, body first and head last, and a body-only section is appended to every skin); the head and the built-in decor pieces are untouched;
- female: only body vertices get a new UV2 (UV2 is used by effect layers of other parts), the section / batch arrays are copied to the end of the skin file.
Method, pitfalls and the eight versions that led here: SKILL.md (this folder). Plain-language lesson: 大白话教学.md. Scripts: scripts/.

## Files (see the Release resource zip for hashes)
- male: Sethrak.m2 (result SHA256 1d60976f096f81e3cd3af6819789ad64f00b9e641bbe2e9803843f87bfa4893d), Sethrak00~03.skin, skin11_t0~5.blp, skin11_t0~5_FL/FU/LU/TU.blp (35 files)
- female: SethrakF.m2, SethrakF00~03.skin (new in Patch-YJ; the originals are in Patch-YB), snakeloa_1_body_blue_t0~5.blp and the 24 Bake textures (35 files)
- the offline check for people who edit the male model afterwards: seth_overlay_guard.py

## Dependency (must be read)
The male Sethrak.m2 was built on the male model that was on the tester's client (base SHA256 4606f633fe48eb44..., it includes Codex's RACECOMBO1B helper bones, which are partly accepted by the user
but are not released independently). Anyone whose male model differs must regenerate the overlay on their own model (scripts) and run the guard. Codex builds his back-shield changes on top of this male M2 (agreed with the user).
The female files do not depend on any other candidate. Codex's HELMKT1A (Kul Tiran male helmet attachment) is a separate change and is NOT part of this release.

## Verified offline
Vertices (position / weights / normals / UV1) unchanged; every original skin section draws exactly the same triangles; new sections contain no head triangles; overlay batches point to the new sections with the right material / layer / texture / UV index; BLP files have the original length and header; female non-body UV2 unchanged (0 vertices differ).

## Not verified / limits
Boots, cloak, robe and sleeves have no geometry and do not show. Female in-game animations, every equipment combination and long play were not tested. Without armour the body is the baked skin: softer than the original and mirrored left/right.
The merchant item-link patch (MERCHFIX1A) is a separate, untested candidate and is not included.
