# Reborn source checkpoint: Witch Doctor and equipment vault

This commit records the current source files, including custom Witch Doctor progression/talents and Wuju support through WD33B, equipment vault ownership and transaction handling, account character slots, and supporting core changes. The custom modules are explicitly tracked so fresh worktrees do not omit them.

The WD33B change permits lower-level teammates to receive private group Wujus 9003280/9003290/9003300, retaining caster learning gates and normal team/radius checks. It requires matching client and server Spell.dbc from the WD33B distribution. Static checks and source archival do not mean a new build or live acceptance.

## Installation boundary

This is a SOURCE checkpoint, not a complete playable distribution. Install the existing matching staged SQL and independently built client/server DBC/resources. No database dump, live credential file, MPQ, generated executable or full resource backup is included. Preserve the recorded per-stage installation order and rollback copies.

Own modules newly tracked: mod-reborn-witchdoctor, mod-reborn-equipment-vault, mod-reborn-character-slots. Existing monk and spectator modules remain unchanged. Playerbots/Eluna/starting-pet dependencies are separate git repositories pinned by the parent tree; their required commits must be published before the parent is pushed.

The local DungeonScale template has an unrelated loot exception edit; that third-party uncommitted configuration is not incorporated into this source checkpoint. Local executable-bit noise and three PSD changes are left untouched and uncommitted.

## Parallel development follow-up

Use distinct worktrees rooted at a complete baseline commit. Freeze resource baselines separately, allocate IDs centrally, and merge DBC changes by record/field rather than replacing whole tables. Only the integration task updates shared logs and creates the combined deployment package. This source checkpoint does not itself create worktrees, database backups or a frozen complete client/server baseline.
