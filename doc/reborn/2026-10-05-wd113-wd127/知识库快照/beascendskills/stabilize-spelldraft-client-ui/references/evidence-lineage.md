# Evidence lineage

- Source day: `000Ascendupdate20260820`.
- Verified packages: B0.9.17.4 through B0.9.17.7 (layer/drag work), B0.9.20.3/20.4.2 (book UI controls), B0.9.21.4 through 21.4.2 (open-time snapshot cache and visible dragging), B0.9.22.0 (double-open corruption recovery).
- Accepted outcome: normal visible dragging restored; opening while jumping no longer had the original severe pause; repeated opening no longer produced rows below the book or server crash.

## Anti-patterns

- Raising CharacterFrame children to TOOLTIP strata: equipment slots leak over every native panel.
- Hiding the real book and showing a black drag surface: movement looks broken.
- Rebuilding every card on every authoritative fragment: causes frame churn, stalls, and duplicate children.
- Anonymous dropdowns on this client: template globals/padding may be nil.

Right Action Bar 2 restoration (B0.9.22.2) has a package but no final explicit user acceptance; keep it in regression testing, not the verified core.
