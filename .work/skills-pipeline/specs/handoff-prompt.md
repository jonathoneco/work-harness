# Spec Handoff: W4 Skills Pipeline

**Task**: skills-pipeline | **Tier**: 3 | **Epic**: work-harness-alc
**Spec completed**: 2026-03-24

## What This Step Produced

- **15 spec files**: 1 cross-cutting contracts + 14 component specs
- **Spec index**: `.work/skills-pipeline/specs/index.md`
- **Components specified**: All 14 from the architecture (C01-C14)
- **Phases covered**: 4 (Foundation, Content Packs, New Commands, Integration)

## Spec Summary Table

| Spec | Component | Title | Phase | New Files | Modified Files |
|------|-----------|-------|-------|-----------|----------------|
| 00 | — | Cross-cutting contracts | All | 0 | 0 |
| 01 | C13 | Skill metadata + update command | 1 | 2 | 33 |
| 02 | C04 | Pack discovery extension | 1 | 0 | 1 |
| 03 | C01 | Language packs (Python, TS, Rust) | 2 | 3 | 0 |
| 04 | C02 | Framework packs (React, Next.js) | 2 | 2 | 0 |
| 05 | C03 | Go pack refactoring | 2 | 0 | 1 |
| 06 | C05 | AMA skill enrichment | 1 | 0 | 1 |
| 07 | C06 | Codex-review skill enrichment | 1 | 0 | 1 |
| 08 | C07 | Context-docs skill enrichment | 1 | 0 | 1 |
| 09 | C08 | `/workflow-meta` command | 3 | 1 | 0 |
| 10 | C09 | `/dev-update` command + skill | 3 | 2 | 1 |
| 11 | C10 | `/work-dump` command | 3 | 1 | 0 |
| 12 | C11 | PR handling: state-driven | 3 | 0 | 1 |
| 13 | C12 | Agency-agents curation | 4 | 1 | 2 |
| 14 | C14 | install.sh updates | 4 | 0 | 2 |

**Totals**: 12 new files, 36 modified files (32 from metadata tagging + 4 substantive modifications)

## Key Design Decisions Resolved During Spec

1. **Skill count correction**: Architecture estimated "23 existing skills" — actual count is **32** (13 skills + 19 commands). All 32 need `meta` blocks. 6 of the 32 lack `---` frontmatter delimiters and need them added first.

2. **Single pack file per language**: V1 uses one `<language>-anti-patterns.md` file per language rather than splitting into separate files per category (anti-patterns, best-practices, idiomatic). Categories are H2 sections within the single file. Multi-file split deferred until a pack exceeds ~400 entries.

3. **Go pack overlap preserved**: The Go pack's first 5 rules overlap with `code-quality.md` universal rules. Decision: keep both — the Go pack versions add Go-specific code examples that the universal rules lack. Additive, not duplicative.

4. **`/workflow-meta` command loads existing skill**: The new command uses `skills: [workflow-meta]` frontmatter to load the existing skill. The command provides the interactive workflow; the skill provides static conventions. No content duplication.

5. **PR state machine priority order**: States are checked in priority order (NO_PR first, MERGED second, CI_FAIL third, etc.). First match wins. This prevents ambiguous states (e.g., a merged PR with failing CI — "merged" takes priority).

6. **code-quality.md gets version 2**: The discovery extension (C04) constitutes a significant content change, so `meta.version` bumps from 1 to 2. All other existing files start at version 1.

7. **harness-doctor grows from 7 to 8 checks**: Check 8 (agency-agents recommendations) is stack-aware — it reads the stack profile and checks for essential agents, not just whether any agents are installed.

## Items Deferred from Specs

1. **Additional framework packs**: Only React and Next.js are specified. Django, FastAPI, gin, htmx, etc. deferred until demand materializes.
2. **Multi-file pack split**: Single file per language for V1. Split when a pack exceeds ~400 entries.
3. **`/work-skill-update --fix` mode**: V1 is read-only (report only). A future `--fix` mode could auto-update `last_reviewed` or suggest content changes.
4. **`/work-dump --create` mode**: V1 is advisory only (DD-3). A future `--create` flag could auto-create issues after user confirmation.
5. **Configurable staleness threshold**: V1 hardcodes 90 days. Future: `harness.yaml` setting to override.

## Instructions for Decompose Step

The decompose step should create work items from these specs. Suggested decomposition:

### Phase 1 Work Items (Foundation — can be parallelized)
- **C13 metadata tagging**: Split into 2 parallel tracks:
  - Track A: Add frontmatter to 6 files lacking it + `meta` block to all 32 files (subagent-friendly batch task)
  - Track B: Create `skill-lifecycle.md` + `work-skill-update.md` (2 new files)
- **C04 discovery extension**: Small, 1 file modification
- **C05-C07 enrichment**: 3 independent file modifications, can be parallel

### Phase 2 Work Items (Content Packs — fully parallel)
- **C01 Python pack**: 1 new file, ~200-300 lines
- **C01 TypeScript pack**: 1 new file, ~200-300 lines
- **C01 Rust pack**: 1 new file, ~200-300 lines
- **C02 React pack**: 1 new file, ~150-250 lines
- **C02 Next.js pack**: 1 new file, ~150-250 lines
- **C03 Go refactor**: 1 file modification

### Phase 3 Work Items (New Commands — independent)
- **C08 `/workflow-meta`**: 1 new file
- **C09 `/dev-update`**: 2 new files + 1 modification
- **C10 `/work-dump`**: 1 new file
- **C11 PR state machine**: 1 file modification (significant rewrite of Steps 8-9)

### Phase 4 Work Items (Integration — depends on Phases 1-3)
- **C12 agency-curation**: 1 new file + 2 modifications
- **C14 install.sh verification**: 2 file modifications + verification run

### Parallelization Notes
- Phase 1 items are all independent and can run in parallel
- Phase 2 items are all independent and can run in parallel (6 parallel streams)
- Phase 3 items are all independent and can run in parallel (4 parallel streams)
- Phase 4 must wait for Phases 1-3 to complete
- Within each phase, subagents can be used for parallel execution
- C13 Track A (metadata tagging of 32 files) is ideal for a batch subagent
