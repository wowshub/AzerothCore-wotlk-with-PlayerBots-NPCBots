---
name: synchronize-wotlk-spell-costs-and-cooldowns
description: Repair server-authoritative custom spell cost or cooldown values that disagree with WotLK 3.3.5 tooltip headers, descriptions, or action-bar timers; use when private server-only modifiers cannot be predicted from client DBC masks.
---

# Synchronize private spell costs and cooldowns

Read project rule/refResource and independently identify active client/server data. Scope to the affected exact SpellIDs and all ranks; keep cost, cast time, cooldown, GCD and Aura duration distinct.

## Trace the two flows

- Mechanics: active saved build → learned passive and actual Aura → native ApplySpellMod → stored cooldown / paid cost. Do not calculate from draft talent points or blindly subtract twice.
- Client: cooldown packet order relative to SMSG_SPELL_GO → predicted action timer; tooltip Left description **and Right heading** → authoritative query reply → current hovered SpellID.

## Repair where authority belongs

1. Verify DBC field semantics from this core's DBCStructure and CalcValue. EffectDieSides starts at74, BasePoints80, TargetA86. die0 does not add1. Confirm actual Aura amount before choosing a base-minus-one convention.
2. Keep the conditional passive native; do not globally lower the base DBC cooldown to the talented value. Resolve signed/unsigned min/max explicitly and cast before subtraction.
3. If SPELL_GO overwrites an earlier custom cooldown packet, follow the existing post-GO correction: read the already stored server delay, clear only the owner's client prediction, send that delay. Exclude passive/item/event-start/ignore-cooldown triggered casts. Do not clear/recalculate server storage.
4. Serialize every authoritative field: count top-level arguments against format placeholders and confirm the receiver gets the cooldown. Missing fields must show syncing/unavailable, not an invented current value.
5. Update only white-listed tooltip lines, including Right headings and locale variants. Preserve original text across paints and detect native row rebuilds. Use sequence, SpellID, epoch, revision and active-slot validation; invalidate on relevant character changes and avoid Show reentry.
6. Preserve unrelated HoT duration/GCD/range and ordinary spells; do not override global GetActionCooldown or GetSpellCooldown to hide a protocol failure.

## Verify and record

Run real delivered Lua with mocked API for all ranks, both locales, repeated paint, native rebuild, talent on/off/on, missing field and stale-hover responses. Check packet ordering against delivered C++, then independent compiler type/syntax probes when a full build is not authorized. Compare client/server DBC independently at byte/row/string levels. In game separately verify actual reuse, action timer, heading, body and remaining time; a correct green line alone is insufficient.

Verified source: [WD127F case](references/wd127f-case.md), user confirmed current skill tests passed on2026-10-05. Scope is Potion Toss and Splash basic synchronization;84 scenarios are offline, not84 in-game tests. Gonk after-GO precedent also has user basic confirmation. This does not certify every rank/PvP/bot/third-party UI combination or unrelated passive coefficients.

Anti-patterns: pre-GO-only packet; Left-only text replacement; a passed test built on wrong DBC indices; missing last format placeholder; 9.999 formatted to10 instead of repairing5001→5000; claiming modules.lib failure is an independent link configuration issue.
