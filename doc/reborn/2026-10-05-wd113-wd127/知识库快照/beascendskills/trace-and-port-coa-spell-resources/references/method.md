# Format and teaching notes

## DBC

Confirm the actual header and matching project schema before indexing. Ordinary WDBC has20-byte header; row/field/record/string sizes follow the4-byte signature. Not every table is an array of32-bit fields (CharStartOutfit is a counterexample).

Spell indices in this project: ID0, cast time28, proc chance35, levels37–39, duration40, power type41, fixed mana42, range46, speed47(float bits), effects71–73, base values80–82, targets86–91, radius92–94, triggers116–118, visuals131–132, icon133, localized names136–151, descriptions170–185, mana percentage204, GCD205–206, school225, coefficients229–231. Do not interpret float bits or string offsets as plain counts.

Visual kits carry more than CastKit: inspect precast, impact, state, state-done, channel, caster/target impact and area kits. Inspect model-attachment rows as a separate reverse reference. Resolve effect filenames and their actual archives rather than assuming all resources live beside the DBC.

M2 texture filenames, skin views and external animations require matching-format parsing. WD3 appended private texture-path strings and updated their pointers, preserving geometry. Do not treat those byte offsets as valid for other expansions.

## Progression audit

ClassSpells lists level-learning entries, not the complete set of unique combat abilities. CharacterAdvancementData can include Ability, Talent, TalentAbility, realm masks, retired entries, rank lists, RequiredIDs, ConnectedNodes and position fields. Count raw entries separately from filtered usable nodes and unique spell ranks. RequiredIDs can point to advancement-node IDs rather than Spell IDs.

## Beginner lesson sequence

1. Show verified paths and source hashes.
2. Trace one real ID from learning list to Spell, visual, kit and asset.
3. Explain what belongs to client visuals, server rules, SQL registration and offline Python.
4. Explain exact ID remapping, per-side string offsets and rollback.
5. Quote actual C++/SQL/core extraction code with each line explained; identify nonessential legacy imports honestly.
6. Demonstrate one numerical example and its rounding/overheal limits.
7. Explain actual validation and failed attempts, distinguishing tool failures from game defects.
8. Link the delivered artifact and preserve existing character data during rollback planning.
