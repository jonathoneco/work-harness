# Spec Handoff → Decompose

## What This Step Produced

14 spec files (00 cross-cutting + 13 component specs) covering all components of the claude-work-harness project. All 6 deferred questions from planning were resolved.

## Spec Artifacts

### Spec Files
All in `.work/harness-modularization/specs/`:
- `00-cross-cutting-contracts.md` — shared schemas, naming, paths, harness.yaml/manifest schemas, hook format, config injection pattern, shell conventions
- `01-repo-scaffold.md` — C1: directory structure, VERSION, README, LICENSE
- `02-config-reader.md` — C10: `lib/config.sh` with yq helpers
- `03-settings-merger.md` — C8: `lib/merge.sh` with jq-based merge/de-merge
- `04-commands.md` — C2: 10 work commands with config injection
- `05-skills.md` — C3: 4 skills + language packs
- `06-agents.md` — C4: 4 workflow agents
- `07-rules.md` — C5: 2 rules
- `08-hooks.md` — C6: 7 hooks with per-hook event registration (DQ1)
- `09-schema-migrator.md` — C9: `lib/migrate.sh` with sequential migrations (DQ4)
- `10-install-script.md` — C7: install/update/uninstall with conflict detection (DQ2, DQ5)
- `11-harness-init.md` — C11: project scaffolding with interactive flow (DQ6)
- `12-harness-update.md` — C12: compatibility check command
- `13-harness-doctor.md` — C13: health check command

### Index
`specs/index.md` — tracks all specs with status, dependencies, DQ resolution map, and phase→spec mapping.

## Deferred Questions Resolved

| DQ# | Question | Resolution Summary |
|-----|----------|--------------------|
| DQ1 | Hook registration format | Spec 00§6 defines format. Spec 08§2 has per-hook event/matcher table: state-guard→PostToolUse(Write\|Edit), work-check/beads-check/review-gate/artifact-gate/review-verify→Stop, pr-gate→PreToolUse(Bash). |
| DQ2 | CLAUDE.md content | Spec 00§7 defines tag format. Spec 10§3 defines: brief pointer block with HTML comment tags (`<!-- harness:start/end -->`), replaced on update, removed on uninstall. |
| DQ3 | Config injection boilerplate | Spec 00§8: prompt-level directive in command text instructing Claude to read harness.yaml and inject "Project Stack Context" section into subagent/handoff prompts. Not shell template rendering. |
| DQ4 | Migration function signatures | Spec 09§3: `harness_migrate <harness_yaml_path>` reads schema_version, calls sequential `migrate_N_to_M` functions. Each function uses yq to transform YAML in-place, then bumps schema_version. |
| DQ5 | Conflict detection | Spec 10§4: if target file exists and is NOT in manifest → warn and skip. `--force` flag overrides. Never silently overwrite user files. |
| DQ6 | harness-init interactive flow | Spec 11§3: 6-prompt sequence (name→language→framework→database→build commands→review routing) with auto-detection (go.mod→go, package.json→typescript, etc.) and per-language defaults. |

## Dependency Graph for Decompose

```
Phase 1 (parallel):
  Spec 01 (scaffold)
  Spec 02 (config reader) → depends on 01
  Spec 03 (settings merger) → depends on 01

Phase 2 (parallel, after Phase 1):
  Content group (parallel):
    Spec 04 (commands)
    Spec 05 (skills)
    Spec 06 (agents)
    Spec 07 (rules)
  Infra group (parallel):
    Spec 08 (hooks) → depends on 02
    Spec 09 (migrator) → depends on 02

Phase 3 (after Phase 2):
  Spec 10 (install script) → depends on 02, 03, 08, 09

Phase 4 (after Phase 1, parallel with Phase 2+):
  Spec 11 (harness-init) → depends on 02
  Spec 12 (harness-update) → depends on 02
  Spec 13 (harness-doctor) → depends on 02
```

**Critical path:** 01 → 02 → 08 → 10

## Key Design Decisions Made During Spec

1. **Config injection is prompt-level**: Commands include a natural-language directive for Claude to read harness.yaml, not a shell template system.
2. **Hook pr-gate.sh fires PreToolUse(Bash)**: Intercepts git push commands, reads build config from harness.yaml, runs format/lint/build checks.
3. **Conflict detection is warn-and-skip**: Install never silently overwrites. --force required for overwrite.
4. **Migrations are yq-based in-place transforms**: Each migration function takes the harness.yaml path, transforms it with yq, bumps schema_version.
5. **harness-init auto-detects language**: Checks go.mod/package.json/Cargo.toml/requirements.txt before prompting.
6. **Exit code convention**: 0=success/skip, 1=warning, 2=blocked (hard error).
7. **Settings merger uses temp file + atomic mv**: Never writes partial JSON.

## Instructions for Decompose Step

1. Read this handoff prompt — primary input
2. Break specs into work items following the phase/dependency graph above
3. Group work items into streams (one per independent workstream)
4. Phase ordering: Phase 1 → Phase 2 → Phase 3 → Phase 4 (Phase 4 can overlap with Phase 2+)
5. Critical path is 01→02→08→10 — prioritize these
6. Each work item should reference its spec (e.g., "W-01: repo scaffold — spec 01")
7. Content specs (04-07) are independent and can be one stream
8. Infrastructure specs (02, 03, 08, 09, 10) form the critical chain
