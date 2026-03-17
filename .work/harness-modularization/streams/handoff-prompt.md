# Decompose Handoff → Implement

## What This Step Produced

13 work items across 5 streams, organized into 3 implementation phases. All beads issues created with dependency chains matching the spec dependency graph.

## Work Item Summary

| W# | Title | Beads ID | Stream | Phase | Spec |
|----|-------|----------|--------|-------|------|
| W-01 | Repo scaffold | rag-nq7ut | A | 1 | 01 |
| W-02 | Config reader (lib/config.sh) | rag-3rpm0 | A | 1 | 02 |
| W-03 | Settings merger (lib/merge.sh) | rag-u5br4 | A | 1 | 03 |
| W-04 | Work commands (10 commands) | rag-um0k7 | B | 2 | 04 |
| W-05 | Skills + language packs | rag-6plf9 | B | 2 | 05 |
| W-06 | Workflow agents (4 agents) | rag-fs6ap | B | 2 | 06 |
| W-07 | Rules (2 rules) | rag-7ypmv | B | 2 | 07 |
| W-08 | Hooks (7 hooks) | rag-cgew8 | C | 2 | 08 |
| W-09 | Schema migrator (lib/migrate.sh) | rag-wzlyt | C | 2 | 09 |
| W-10 | Install script (install.sh) | rag-d4xkc | E | 3 | 10 |
| W-11 | harness-init command | rag-i8h9z | D | 2 | 11 |
| W-12 | harness-update command | rag-wwpv6 | D | 2 | 12 |
| W-13 | harness-doctor command | rag-nrxsn | D | 2 | 13 |

## Streams

| Stream | Name | Phase | Work Items | Description |
|--------|------|-------|------------|-------------|
| A | Foundation | 1 | W-01, W-02, W-03 | Repo scaffold + foundation libraries (sequential) |
| B | Content | 2 | W-04, W-05, W-06, W-07 | Commands, skills, agents, rules (parallel) |
| C | Infrastructure | 2 | W-08, W-09 | Hooks + schema migrator (parallel) |
| D | Project Commands | 2 | W-11, W-12, W-13 | harness-init/update/doctor (parallel) |
| E | Install Script | 3 | W-10 | Integration point (depends on all Phase 2) |

## Phase Execution Plan

### Phase 1: Foundation (Stream A — sequential)

Single agent executes W-01 → W-02 → W-03 in order.

- **W-01**: Create repo directory structure, VERSION, README, LICENSE, .gitignore, install.sh stub
- **W-02**: Implement `lib/config.sh` — 5 public functions + 1 internal helper for yq-based config access
- **W-03**: Implement `lib/merge.sh` — 3 functions for jq-based settings.json hook merge/de-merge

**Completion gate**: All 3 items closed. Run `make test` equivalent (manual shell verification per spec 02/03 test strategies).

### Phase 2: Core (Streams B, C, D — parallel)

Three agents run simultaneously after Phase 1 completes.

**Stream B (Content)**: Copy and parameterize markdown content files from gaucho/.claude/ and dotfiles/home/.claude/. Remove hard-coded Go/HTMX references, add config injection directives. 4 items, all parallel within stream.

**Stream C (Infrastructure)**: Create 7 POSIX sh hook scripts and schema migrator library. Both depend on lib/config.sh from Phase 1. 2 items, parallel within stream.

**Stream D (Project Commands)**: Create 3 harness management commands (init, update, doctor). All are Claude Code commands (markdown) that use config reader functions. 3 items, parallel within stream.

**Completion gate**: All 9 items closed (W-04 through W-09, W-11 through W-13).

### Phase 3: Integration (Stream E — sequential)

Single agent implements the install script after all Phase 2 streams complete.

- **W-10**: Replace install.sh stub with full 3-mode script (install/update/uninstall). Sources all lib scripts, copies content, merges hooks, manages CLAUDE.md tags, writes manifest.

**Completion gate**: W-10 closed. Full end-to-end test: install → verify → update → verify → uninstall → verify clean.

## Dependency Graph (DAG)

```
Phase 1:
  W-01 ─┬─→ W-02 ─┬─→ W-08 ──┐
         │          ├─→ W-09 ──┤
         │          ├─→ W-11   │
         │          ├─→ W-12   │    Phase 3:
         │          └─→ W-13   ├──→ W-10
         │                     │
         ├─→ W-03 ─────────────┤
         │                     │
         ├─→ W-04              │
         ├─→ W-05              │
         ├─→ W-06              │
         └─→ W-07              │
                               │
  Phase 2 ─────────────────────┘
```

**Critical path**: W-01 → W-02 → W-08 → W-10

**Phase collapse note**: The spec handoff defined 4 phases (Phase 4 for project commands, overlapping with Phase 2+). Since W-11/W-12/W-13 depend only on W-02 (completed in Phase 1), they are folded into Phase 2 as Stream D. This reduces 4 spec phases to 3 decompose phases without changing execution semantics.

## File Conflict Analysis

No file appears in more than one stream within the same phase:

| Stream | Directories | Overlap Check |
|--------|------------|---------------|
| A | `lib/`, `VERSION`, etc. | Phase 1 only, no parallel |
| B | `claude/commands/work-*.md`, `claude/skills/`, `claude/agents/`, `claude/rules/` | No overlap with C or D |
| C | `hooks/`, `lib/migrate.sh` | No overlap with B or D |
| D | `claude/commands/harness-*.md`, `templates/` | No overlap with B or C |
| E | `install.sh` | Phase 3 only, no parallel |

Streams B and D both write to `claude/commands/` but different files (`work-*.md` vs `harness-*.md`).

## Key Specs to Read Per Stream

| Stream | Must Read |
|--------|-----------|
| A | spec 00, spec 01, spec 02, spec 03 |
| B | spec 00 §8 (config injection), spec 04, spec 05, spec 06, spec 07 |
| C | spec 00 §6 (hook format), spec 00 §9 (shell conventions), spec 02, spec 08, spec 09 |
| D | spec 00 §4 (harness.yaml schema), spec 02, spec 11, spec 12, spec 13 |
| E | spec 00 (all), spec 02, spec 03, spec 08, spec 09, spec 10 |

## Source Material for Content Streams

Agents implementing content (Stream B) need the current harness files as source:
- `gaucho/.claude/commands/` — current work commands
- `gaucho/.claude/skills/` — current skills
- `gaucho/.claude/agents/` — current agents
- `gaucho/.claude/rules/` — current rules
- `dotfiles/home/.claude/` — dotfiles copies (may differ)

The agent should diff gaucho vs dotfiles copies and use the most complete version as the source, then parameterize.

## Implementation Context

- **Target repo**: This implementation creates files for the `claude-work-harness` standalone repo. The files are written to `.work/harness-modularization/implement/` during implementation, then moved to the actual repo location in a later step.
- **Alternative**: If a separate repo is already created, agents write directly to it. Coordinate with user on target location.
- **POSIX sh**: All shell scripts use `#!/bin/sh`, `set -eu`, no bashisms (except `$(( ))` arithmetic). See spec 00 §9.
- **Exit codes**: 0 = success/skip, 1 = general error, 2 = blocked. See spec 00 §3.

## Instructions for Implement Step

1. Read this handoff prompt — primary input
2. For Phase 1: launch one agent with Stream A doc, execute W-01 → W-02 → W-03 sequentially
3. Run Phase 1 gate review (Phase A artifact + Phase B quality)
4. For Phase 2: launch 3 agents in parallel (Streams B, C, D) after Phase 1 gate passes
5. Run Phase 2 gate review
6. For Phase 3: launch one agent with Stream E doc after Phase 2 gate passes
7. Run Phase 3 gate review
8. Final verification: end-to-end install/update/uninstall cycle
9. Auto-advance to review step
