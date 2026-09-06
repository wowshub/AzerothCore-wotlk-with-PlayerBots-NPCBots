# RebornWOW Monk combat checkpoint — 2026-09-05

This checkpoint records the custom class-14 Monk gameplay source accumulated
after the class-capacity foundation commit `84eddec7f`.

## Server gameplay included

- `9001502` Tiger Palm: preserves the verified CustomSpell08 presentation while moving.
- `9001504` Expel Harm: heals first and deals retaliation damage based on effective healing.
- `9001505` Roll: native DBC leap/collision chain with grounded/rooted/mounted guards and CustomSpell07 presentation.
- `9001507` Blackout Kick: requires two emulated Chi stacks; a landed rear hit applies the damage-over-time branch, otherwise it heals the caster; failed attacks do not consume Chi.
- `9001510` Jab: landed damage grants one harmless visible Chi stack, capped at four; failed attacks grant none.
- `9001513` Rising Sun Kick: requires two Chi, consumes them only on landed damage, and applies `9001514` Mortal Wounds.
- `9001514` Mortal Wounds: 25% healing-received reduction for ten seconds through the native 3.3.5 aura type.
- `9001515` Rising Sun Vulnerability: a landed Rising Sun Kick marks enemies within eight yards for fifteen seconds. A per-caster server bridge increases only the applying Monk's whitelisted ability damage by 15%, including Blackout Kick periodic damage.
- Class-14 out-of-combat health regeneration uses the native Rogue coefficient row while preserving the character's real Monk class everywhere else.
- The starter Lua teaches the verified staged kit at its configured levels and removes the temporary development aura on login.

## World database bindings

`28_monk_combat_scripts.sql` installs the six SpellScript bindings for Tiger
Palm, Expel Harm, Roll, Blackout Kick, Jab and Rising Sun Kick. The Rising Sun
15% damage bridge is a registered `UnitScript`, so it intentionally has no
`spell_script_names` row.

## Live verification status

- Passed: Tiger Palm, Expel Harm, Roll, Blackout Kick, Jab/four Chi, Rising Sun Kick two-Chi gate, 300% weapon damage, eight-second cooldown, sounds, Mortal Wounds display, and standing/moving/strafing/jumping kick animations.
- Passed for M6K9: the `9001515` debuff is applied to multiple nearby targets and displays its fifteen-second countdown.
- Still recommended: controlled A/B measurement of the M6K9 15% damage value and strict eight-yard boundary.

## Runtime assets kept outside this source commit

The project-specific Spell/SkillLine/SpellVisual/SpellVisualKit/Sound DBC rows,
OGG files, client action-button compatibility AddOn, MPQ payloads and the
user-built animation-arbitration DLL are versioned by the dated runtime-package
workflow, not by this core-source repository. A clean clone therefore still
requires the matching M6K runtime package.

Codex did not compile or deploy binaries for this checkpoint.
