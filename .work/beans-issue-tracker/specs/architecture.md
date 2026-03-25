# Beans (bn) — Architecture

## Problem Statement

Beads (`bd`) is a daemon-backed, SQLite-cached issue tracker consuming 1,500-2,500 tokens of context per session while providing value primarily as an audit log. Its daemon/Dolt/SQLite layers are fragile, its 126-line global rule file loads for every project, and 20+ registered skills burn context on features never invoked (dependency graphs, ready queries). The harness already tracks task lifecycle in `.work/*/state.json`, making beads a parallel bookkeeping system that duplicates state.

Beans (`bn`) replaces beads with a minimal POSIX sh + jq script operating on `.beans/issues.jsonl`. No daemon, no database, no external runtime. Context injection drops from ~2,000 tokens to ~100.

## Goals

1. **Reduce context cost to <150 tokens** — eliminate global rule file, skills, and session-start hook injection
2. **Zero external runtime dependencies** — POSIX sh + jq only (both pre-installed on target system)
3. **Preserve audit trail** — every task gets an issue; closed issues remain searchable
4. **Git-native data** — `.beans/issues.jsonl` tracked in git, merge-safe via `merge=union` gitattribute
5. **Drop-in migration** — mechanical `bd` → `bn` swap across harness commands/hooks/rules
6. **Self-documenting CLI** — commands match what agents already know; minimal instruction needed
7. **Offline-first** — no network, no daemon, no background processes

### Non-Goals

- **Full project management** — no labels, milestones, sprints, or time tracking
- **Multi-user coordination** — designed for single-developer + AI agent workflows
- **Web UI or API** — CLI only
- **Comments on issues** — close reason serves as the final note; git history provides the timeline
- **Backward compatibility with beads** — clean break; migration script converts data once
- **Template/convoy system** — seeds has this; beans does not need it

## Design Decisions

### DD-1: Data Format and Schema

**Decision**: Single JSONL file at `.beans/issues.jsonl`, one JSON object per line, snake_case field names.

**Schema**:
```json
{
  "id": "work-harness-a1b2",
  "title": "[Feature] Add search command",
  "status": "open",
  "type": "task",
  "priority": 2,
  "description": "Optional longer description",
  "close_reason": null,
  "depends_on": [],
  "blocks": [],
  "created_at": "2026-03-25T14:00:00Z",
  "updated_at": "2026-03-25T14:00:00Z",
  "closed_at": null
}
```

**Rationale**:
- snake_case matches existing beads JSONL (minimizes migration friction)
- Single file keeps grep/jq operations simple — no directory-per-issue overhead
- `depends_on` + `blocks` are bidirectional arrays maintained by the dep commands
- No `assignee` field — single-developer workflow, assignment is implicit
- No `owner`/`created_by` — not needed in single-developer context
- ISO 8601 timestamps for consistency

**Fields**:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | yes | `{project}-{4hex}` |
| `title` | string | yes | Issue title |
| `status` | enum | yes | `open`, `in_progress`, `closed` |
| `type` | enum | yes | `task`, `bug`, `feature`, `epic` |
| `priority` | int 0-4 | yes | P0=critical ... P4=backlog |
| `description` | string | no | Longer description |
| `close_reason` | string | no | Why it was closed |
| `depends_on` | string[] | no | IDs this issue depends on |
| `blocks` | string[] | no | IDs this issue blocks |
| `created_at` | ISO 8601 | yes | Creation timestamp |
| `updated_at` | ISO 8601 | yes | Last update timestamp |
| `closed_at` | ISO 8601 | no | When closed |

### DD-2: ID Generation

**Decision**: `{project-prefix}-{4-random-hex}` (e.g., `work-harness-a1b2`).

**Rationale**:
- Matches beads' existing format — all references in state.json, commits, and handoff prompts remain recognizable
- 4 hex chars = 65,536 unique IDs per project — more than sufficient (current project has ~108 issues)
- Random generation via `od -An -tx1 -N2 /dev/urandom | tr -d ' '` (POSIX-portable)
- Collision check: generate, check if ID exists in JSONL, retry (up to 10 attempts, then fail)
- Project prefix read from `.beans/config` (plain text file, single line: project name)

### DD-3: Command Surface Area

**Decision**: 10 commands matching actual harness usage patterns plus dependency management.

```
bn init                                    # Initialize .beans/ directory
bn create --title "..." [--type task] [--priority 2] [--description "..."]
bn list [--status open|in_progress|closed] [--type task|bug|feature|epic] [--ready] [--json]
bn show <id> [--json]                      # Show single issue details
bn update <id> [--status STATUS] [--priority N] [--title "..."]
bn close <id> [--reason "..."]             # Also: bn close <id1> <id2> ...
bn search <keyword> [--status STATUS] [--json]  # Full-text search across all fields
bn dep add <issue> <depends-on>            # Issue depends on depends-on
bn dep rm <issue> <depends-on>             # Remove dependency
bn ready [--json]                          # Alias for: bn list --ready
```

**Rationale**:
- `init` creates `.beans/`, `config`, `issues.jsonl`, and `.gitattributes` entry
- `create` returns the new issue ID on stdout (for capture in scripts: `id=$(bn create ...)`)
- `list` with `--ready` flag replaces the separate `bd ready` — one less command to learn
- `show` displays a single issue in human-readable format (or JSON with `--json`)
- `close` accepts multiple IDs for batch closing (used by work-archive)
- `search` does case-insensitive grep across all string fields — the feature seeds lacks
- `dep add` maintains bidirectional consistency (updates both `depends_on` and `blocks`)
- `ready` is a convenience alias, not a separate code path
- Every list/show/search command supports `--json` for structured agent consumption
- No `sync`, `export`, `import`, `compact`, `doctor`, `prime`, or `onboard` — unnecessary without a daemon

### DD-4: Merge Strategy

**Decision**: `merge=union` gitattribute on `.beans/issues.jsonl` + dedup-on-read (last occurrence wins).

**Implementation**:
1. `bn init` adds `.beans/issues.jsonl merge=union` to `.gitattributes`
2. Every read operation (`list`, `show`, `search`, `ready`, internal helpers) pipes through a dedup filter: `tac | jq -s 'group_by(.id) | map(.[0]) | sort_by(.created_at)' | ...`
3. After dedup, if the count changed, rewrite the file atomically (compact on read)

**Rationale**:
- `merge=union` means git merges append both sides' lines — no merge conflicts ever
- Dedup-on-read with last-occurrence-wins resolves union duplicates correctly (the latest update wins)
- Compact-on-read keeps the file from growing unbounded
- This is the same strategy seeds uses, proven effective

### DD-5: Concurrent Access

**Decision**: Advisory file locking via `flock` + atomic writes via temp-file-and-rename.

**Implementation**:
```sh
lockfile=".beans/.lock"
(
  flock -x 9
  # read, modify, write to temp
  tmpfile=$(mktemp .beans/.issues.XXXXXX)
  # ... jq operations ...
  mv "$tmpfile" .beans/issues.jsonl
) 9>"$lockfile"
```

**Rationale**:
- `flock` is available on all Linux systems and macOS (via util-linux or brew)
- Advisory locks prevent corruption from concurrent `bn` invocations (e.g., parallel agents in worktrees)
- Atomic rename ensures readers never see a partial write
- Lock scope is minimal — held only during the read-modify-write cycle
- No daemon needed for concurrency safety

### DD-6: Search Implementation

**Decision**: `grep -i` on JSONL for initial filtering, `jq` for field extraction and formatting.

**Implementation**:
```sh
bn_search() {
  keyword="$1"
  grep -i "$keyword" .beans/issues.jsonl | jq -r '
    select(true) |  # already filtered by grep
    "\(.id) [\(.status)] \(.title)" +
    if .close_reason then "\n  Reason: \(.close_reason)" else "" end
  '
}
```

**Rationale**:
- `grep` is fast for initial filtering across the full JSONL file (handles hundreds of issues instantly)
- `jq` formats the output for human readability
- Case-insensitive by default (`-i`) — most useful for keyword searches
- `--status` flag optionally pre-filters to avoid noise from closed issues
- `--json` flag returns raw JSON lines for agent consumption
- No index, no database — the JSONL file IS the index

### DD-7: Session Start Hook / Context Injection

**Decision**: Replace the 126-line `beads-workflow.md` with a ~25-line `beans-workflow.md` containing only the command cheat sheet and the "no code without issue" enforcement rule.

**Injected context** (target: <100 tokens):
```
## Issue Tracking (beans)
Before editing code, claim an issue: `bn update <id> --status in_progress`
If none exists: `bn create --title "..." --type task --priority 2`

Commands: bn list, bn show, bn create, bn update, bn close, bn search, bn ready, bn dep add/rm
All commands support --json for structured output.
```

**Rationale**:
- The "no code without issue" rule is the only behavioral enforcement that matters
- The command cheat sheet is 8 lines — agents already know how CLI tools work
- No need for: deprecated approaches table (beans has no history), complex dep examples (rarely used), Dolt/sync instructions (no daemon), or session discipline checklists (harness owns these)
- Eliminates 20+ beads skills (zero skills for beans)
- Session start hook reduced to: `bn list --status=in_progress` (show active issues, ~1 line of output)

### DD-8: Migration Path from Beads

**Decision**: One-time migration script (`bn migrate-from-beads`) built into `bn`.

**Steps**:
1. Read `.beads/issues.jsonl`
2. Transform each line with `jq`:
   - `issue_type` → `type`
   - `owner` / `created_by` → dropped (not in beans schema)
   - `close_reason` stays (already snake_case in beads)
   - `in-progress` → `in_progress` (normalize status)
   - `done`/`complete` → `closed`
   - Preserve original IDs (so state.json references remain valid)
   - Add empty `depends_on`/`blocks` if missing
3. Write to `.beans/issues.jsonl`
4. Harness migration: mechanical `bd` → `bn` replacement in ~14 command files, 3 hooks, 1 rule file
5. State.json field renames: `beads_epic_id` → `epic_id`

**Rationale**:
- Preserving IDs is critical — state.json, handoff prompts, and commit messages reference beads issue IDs
- The data transformation is simple jq — no intermediate format needed
- Harness command migration is mechanical find-replace with minor syntax adjustments

### DD-9: Where bn Script Lives

**Decision**: `bin/bn` in the work-harness repo, installed to user PATH via harness setup.

**Rationale**:
- `bn` is a harness component — it exists to serve the harness workflow
- Living in the harness repo means it's versioned alongside the commands/hooks that call it
- Single file (~300-500 lines of sh) — no build step, no package manager
- User adds `~/src/work-harness/bin` to PATH (or harness setup symlinks `bn` to `~/.local/bin/`)
- Alternative considered: separate repo — rejected because `bn` has no value outside the harness
- Alternative considered: npm/bun package — rejected because that adds runtime dependencies

### DD-10: Harness Command/Hook/Rule References

**Decision**: Direct replacement of `bd` with `bn` across all harness files. No compatibility layer.

**Files requiring changes**:

| Category | Files | Change Type |
|----------|-------|-------------|
| Global rule | `~/.claude/rules/beads-workflow.md` → `beans-workflow.md` | Rewrite (126 → ~25 lines) |
| Commands | 14+ `claude/commands/work-*.md` | Mechanical `bd` → `bn` swap |
| Hooks | `beads-check.sh` → `beans-check.sh` | Rewrite (simpler logic) |
| Hooks | `artifact-gate.sh` | Update `bd` → `bn` calls |
| State fields | `state.json` references | `beads_epic_id` → `epic_id` |
| Skills | `beads:*` entries | Delete entirely (zero beans skills) |

**Rationale**:
- No shim or compatibility layer (per code-quality rule 8: no backward compatibility wrappers)
- Clean break is simpler than maintaining dual paths
- Migration is done in one session, not incrementally

## Component Map

| # | Component | File | Description | Lines (est.) |
|---|-----------|------|-------------|-------------|
| C1 | Core script | `bin/bn` | Main entry point, argument parsing, all commands | 300-500 |
| C2 | Init command | (in C1) | Creates `.beans/`, config, JSONL, gitattributes | 20-30 |
| C3 | CRUD commands | (in C1) | create, show, update, close, list | 120-180 |
| C4 | Search command | (in C1) | grep + jq full-text search | 20-30 |
| C5 | Dependency commands | (in C1) | dep add, dep rm, ready filter | 40-60 |
| C6 | Merge/dedup | (in C1) | Dedup-on-read, compact-on-read | 20-30 |
| C7 | Locking | (in C1) | flock wrapper for concurrent access | 15-20 |
| C8 | Migration | (in C1) | migrate-from-beads jq transformer | 30-50 |
| C9 | Beans workflow rule | `~/.claude/rules/beans-workflow.md` | Minimal context injection (~25 lines) | 25 |
| C10 | Beans check hook | `hooks/beans-check.sh` | Enforces issue-before-code | 20-30 |
| C11 | Harness command updates | `claude/commands/work-*.md` (14+) | bd → bn mechanical swap | Δ ~150 lines |
| C12 | Legacy migration prompt | `claude/commands/migrate-to-beans.md` | Claude Code command to migrate workflow content in other projects | 30-50 |

**Note**: C1-C8 are all in a single file (`bin/bn`). The script is organized as functions called from a `case` dispatcher at the bottom.

**Note**: C12 is a Claude Code slash command (`/migrate-to-beans`) for use in other projects that still have beads references. It instructs the agent to: run `bn migrate-from-beads` for data, then rewrite `.work/*/state.json` fields (`beads_epic_id` → `epic_id`), update handoff prompts containing `bd` references, and update any project-local rules/hooks. This is LLM work (context-aware rewriting), not mechanical jq — hence a prompt, not a script.

## Phased Implementation

### Phase 1: Core Script (bn)
Build `bin/bn` with all commands:
- Init, create, list, show, update, close
- Search
- Dep add, dep rm, ready
- Migrate-from-beads
- Locking, dedup, atomic writes
- `--json` flag on all output commands

**Deliverable**: Working `bn` script that passes manual smoke tests.

### Phase 2: Harness Migration
- Write `beans-workflow.md` (replace beads-workflow.md)
- Update all command files (bd → bn)
- Rewrite hooks (beads-check → beans-check, update artifact-gate)
- Update state.json field references
- Remove beads skills
- Run `bn migrate-from-beads` on existing data
- Create `/migrate-to-beans` command for migrating other projects

**Deliverable**: Harness fully references `bn`, zero `bd` references remain. Legacy migration prompt available for other projects.

### Phase 3: Validation and Cleanup
- Run harness-doctor
- Test T1/T2/T3 workflows end-to-end
- Verify context cost reduction (measure tokens before/after)
- Delete `.beads/` directory from tracked files
- Archive beads-replacement research task

**Deliverable**: Clean harness with beans as sole issue tracker.

## Scope Exclusions

- **No daemon or background process** — every command is stateless read-modify-write
- **No SQLite, Dolt, or any database** — JSONL is the only data store
- **No skills registration** — beans commands are self-documenting; no `beans:*` skills
- **No `bn prime` or `bn onboard`** — context injection is handled by the harness rule file
- **No labels or tags** — issue title prefixes (`[Feature]`, `[Bug]`) serve this purpose
- **No comments system** — close_reason + git history provide the audit trail
- **No version control subcommands** — `git add/commit` handles JSONL versioning directly
- **No template/convoy system** — harness decompose specs serve this purpose for T3
- **No stats or doctor command** — issue count is visible via `bn list | wc -l`; data integrity is trivially verifiable on JSONL
