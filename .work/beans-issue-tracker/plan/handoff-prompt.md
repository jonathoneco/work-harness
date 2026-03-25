# Handoff: plan → implement

## What This Step Produced

Architecture document at `.work/beans-issue-tracker/specs/architecture.md` with 10 design decisions and 11 components across 3 implementation phases.

## Architecture Summary

Beans (`bn`) is a single POSIX sh + jq script (`bin/bn`, ~300-500 lines) that replaces beads (`bd`). It operates on `.beans/issues.jsonl` — a git-tracked JSONL file with `merge=union` gitattribute for conflict-free merging. No daemon, no database, no external runtime.

10 commands: `init`, `create`, `list`, `show`, `update`, `close`, `search`, `dep add`, `dep rm`, `ready`. All list/show/search commands support `--json` for structured agent output.

Concurrent access via `flock` advisory locking + atomic temp-file rename. Dedup-on-read (last occurrence wins) handles union merge duplicates.

## Key Design Decisions

1. **Single JSONL file**, snake_case fields, schema: id, title, status, type, priority, description, close_reason, depends_on, blocks, timestamps
2. **IDs**: `{project}-{4hex}` matching beads format, random via `/dev/urandom`
3. **10 commands** covering actual harness usage (no daemon commands, no sync, no prime/onboard)
4. **merge=union gitattribute** + dedup-on-read (last wins) — no merge conflicts ever
5. **flock + atomic rename** for concurrent access
6. **grep + jq search** — case-insensitive, searches all string fields
7. **~25-line rule file** replacing 126-line beads-workflow.md — target <100 tokens context
8. **One-time migration** preserving original beads IDs (state.json refs stay valid)
9. **bin/bn in harness repo** — single file, no build step, added to PATH
10. **Direct bd→bn replacement** — no compatibility layer, clean break

## Implementation Instructions

### Phase 1: Build `bin/bn`
Create the script with this structure:
```
#!/bin/sh
# beans (bn) — minimal issue tracker
# Functions: bn_init, bn_create, bn_list, bn_show, bn_update, bn_close, bn_search, bn_dep, bn_ready, bn_migrate
# Bottom: case "$1" in dispatcher
```

Key implementation details:
- Read `.beans/config` for project prefix (one line: project name)
- All write operations go through a `bn_locked_write` helper using `flock`
- All read operations go through a `bn_read_issues` helper that dedup by ID (last wins)
- `--json` flag: output raw JSON lines instead of formatted text
- `create` prints the new ID to stdout (for capture: `id=$(bn create --title "...")`)
- `close` accepts multiple IDs: `bn close id1 id2 id3`
- `dep add` updates BOTH sides: adds to issue's `depends_on` AND to target's `blocks`

### Phase 2: Harness Migration
Files to update (see DD-10 in architecture for complete list):
- Replace `~/.claude/rules/beads-workflow.md` with `beans-workflow.md` (~25 lines)
- Update 14+ command files: `bd` → `bn` mechanical swap
- Rewrite `hooks/beads-check.sh` → `hooks/beans-check.sh`
- Update `hooks/artifact-gate.sh`
- Rename state.json field `beads_epic_id` → `epic_id` in command templates
- Delete all `beads:*` skill entries
- Run `bn migrate-from-beads` to convert existing data

### Phase 3: Validate
- `grep -r 'bd ' claude/commands/` should return zero hits
- `grep -r 'beads' claude/` should return zero hits (except migration notes)
- Test: `bn init && bn create --title "test" && bn list && bn search test && bn close <id>`
- Run full T1/T2 workflow to verify end-to-end

### Important Constraints
- POSIX sh only (no bashisms) — check with `shellcheck -s sh`
- All variables quoted (per shell scripting rules)
- Error paths must fail hard, not return empty/zero (code-quality rule 1, 2, 3)
- No backward compatibility layer (code-quality rule 8)
