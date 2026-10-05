# WD3 case: Witch Doctor starter abilities

This is a dated example, not a current-runtime path declaration. Recheck all paths and free IDs for a new stage.

- Original class13 level-one entries: 807037 Malefic Wrath and 801670 Loa's Brew.
- Project IDs: 9003100 damage, 9003101 heal, 9003102 hidden echo; skill line9004. Real class13/human1; Monk remains14.
- Actual source tables: Spell from patch-T.MPQ; visual/kit/effect/icon/time/range from patch-S.MPQ; SoundEntries from patch-M.MPQ. Models came from patch-N.MPQ and common-2.MPQ. Sound table origin does not imply all sound files are in that archive.
- Example path: 801670 → visual989913 → effect622870 → SPELLS\PotionA_SpellObject.m2, read from common-2.MPQ.
- CoA source: AscensionCustomClassData.h, AscensionWitchDoctorAbilities.cpp, AscensionWitchDoctorCompletion.cpp, AscensionWitchDoctorCoefficients.h.
- Damage coefficient0.625; healing coefficient0.84. CoA adds power to effect base. The port uses an effect-launch hook and zero native SQL coefficients; normal low-rank coefficient penalties would otherwise differ.
- Echo references the previous successfully healed target and copies half of effective healing on a target change. Repeated same-target healing produces no echo. Target must be alive, same map/phase, friendly, self or party/raid, within40 yards. Temporary memory is per caster and cleared on logout.
- A missing donor SpellMissile1501 reference was explicitly normalized to0 straight-projectile compatibility. It was not claimed to be a faithful missing trajectory reconstruction.
- Generic reader's200MB limit rejected the209403302-byte source Spell table. A bounded dedicated read recovered it; this was a tooling limit, not corrupted game data.
- A developer field error was corrected before delivery: Spell column35 is ProcChance; DurationIndex is40.
-177 static/behavior-model checks and isolated SQL installation/retry/conflict/rollback checks passed. User later approved visuals, animations and damage. Do not infer all echo edges or continuous20-minute tests from that approval.
- Subsequent Details GetBarColor nil-unpack was a separate addon compatibility issue: missing class registration/default profile colors. Fix the demonstrated layer without changing spell data to silence an addon traceback.

Evidence archive: D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20260915/codexfix_202609150412_阶段WD3_巫医出生施法技能/checks

Beginner tutorial: [417-line annotated course](../../../beascendtutor/port-wotlk-witchdoctor-starter-spells/README.md)
