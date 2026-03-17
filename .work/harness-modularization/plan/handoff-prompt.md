# Plan Handoff → Spec

## What This Step Produced
Architecture document at `.work/harness-modularization/specs/architecture.md` covering 13 components, 4 resolved questions, repo structure, data flows, dependency ordering, and implementation phasing.

## Architecture Document
`.work/harness-modularization/specs/architecture.md`

## Component List for Spec Writing

### Phase 1: Foundation
- **C1: Repo scaffold** — directory structure, VERSION, README, LICENSE
- **C10: Config reader** (`lib/config.sh`) — yq helpers for harness.yaml
- **C8: Settings merger** (`lib/merge.sh`) — jq-based merge/de-merge for settings.json

### Phase 2: Core Content + Hooks
- **C2: Commands** — 13 commands extracted and parameterized with config injection
- **C3: Skills** — 4 skills + language pack references
- **C4: Agents** — 4 workflow agents
- **C5: Rules** — 2 rules
- **C6: Hooks** — 7 hooks parameterized to read harness.yaml

### Phase 3: Install Infrastructure
- **C7: Install script** — install/update/uninstall with settings merge and manifest
- **C9: Schema migrator** — version-aware harness.yaml migrations

### Phase 4: Project Commands
- **C11: harness-init** — project scaffolding
- **C12: harness-update** — compatibility check
- **C13: harness-doctor** — health check

## Decisions Made During Planning
1. **Repo name**: `claude-work-harness`
2. **agency-agents**: Recommended companion, not auto-installed. Install script suggests if missing. `/harness-doctor` verifies referenced agents exist.
3. **Language packs**: Directive in `code-quality.md` reads `references/<language>-anti-patterns.md` where language comes from harness.yaml. All packs ship globally.
4. **pr-gate.sh**: Global hook, reads `.claude/harness.yaml` from current project dir. Exits 0 if no harness.yaml (graceful skip).
5. **`claude/` subdir**: Mirrors `~/.claude/` — install.sh copies contents. Makes it visually clear what ends up where.
6. **Hooks separate from `claude/`**: Stay in repo, referenced by absolute path. Updates via git pull without re-running install.
7. **All hooks graceful-skip**: Check for `.claude/harness.yaml` → exit 0 if absent. Works for all projects, harness-enabled or not.
8. **Manifest at `~/.claude/.harness-manifest.json`**: Tracks installed files, hook entries, harness dir path, schema version.

## Key Schemas
- **harness.yaml v1**: project, stack, build, review_routing, extensions, anti_patterns
- **Manifest**: harness_version, harness_dir, schema_version, files[], hooks_added[], claude_md_tag

## Questions Deferred to Spec
1. Exact hook registration format (events, matchers) per hook
2. CLAUDE.md appended content (how much context vs pointers)
3. Config injection boilerplate for commands
4. Migration function signatures
5. Conflict detection for existing non-harness files
6. harness-init interactive flow (prompt sequence, defaults per language)

## Instructions for Spec Step
1. Read this handoff prompt — primary input
2. Write cross-cutting contracts (spec 00) — shared naming, paths, harness.yaml schema, manifest schema
3. Write per-component specs following the phase ordering above
4. Each spec must include: acceptance criteria, files to create/modify, interface contracts
5. Pay special attention to C7 (install script) and C8 (settings merger) — these are the hardest components
6. Resolve the 6 deferred questions during spec writing
