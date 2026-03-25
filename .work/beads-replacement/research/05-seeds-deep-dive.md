# Seeds (sd) Deep Dive Evaluation

## Summary

Seeds is a purpose-built beads replacement for AI agent workflows. It eliminates the three worst beads pain points (daemon, SQLite, Dolt) while preserving full feature parity on the operations that matter. However, it introduces new concerns: Bun runtime dependency, single-developer risk, ecosystem coupling, and a missing `search` command. The context window cost is **significantly lower** than beads but **not zero** — and the "sd prime" pattern still burns tokens on boilerplate the harness doesn't need.

**Verdict**: Viable as a beads replacement. Better than beads on every dimension except maturity and search. The main risk is bus factor and the Bun dependency. If adopting Seeds, the harness should NOT use `sd prime` or `sd onboard` — instead, keep the existing lean rules file pattern with `sd`/`bd` swapped.

---

## 1. Context Window Cost (MOST IMPORTANT)

### What Seeds injects

Seeds has three injection points:

| Mechanism | Lines | Chars | Est. Tokens | When |
|-----------|-------|-------|-------------|------|
| `sd prime` (full) | 83 | 3,007 | ~365-490 | Agent runs at session start |
| `sd prime --compact` | 16 | 570 | ~68-91 | Agent runs at session start |
| `sd onboard` (CLAUDE.md section) | 23 | 770 | ~92-123 | Persistent in CLAUDE.md |

### How it compares to beads

| Dimension | Beads | Seeds | Custom `wt` |
|-----------|-------|-------|-------------|
| Global rules file | 126 lines / ~800 tokens | 0 (no global rules) | 0 |
| Onboard injection | N/A | 23 lines / ~100 tokens | 0 |
| Per-session prime | N/A | 83 lines / ~400 tokens | 0 |
| Skills/hooks | 20+ skill entries (~1,500 tokens) | 0 skills | 0 |
| Command embedding | ~200 tokens across 14 files | Same pattern needed | Same |
| **Total pre-conversation** | **~1,500-2,500 tokens** | **~500-600 tokens** | **~100-200 tokens** |

### Key findings

1. **`sd prime` full output is 83 lines of workflow instructions** — it tells the agent to use Seeds for all tracking, provides a session close protocol with quality gates (`bun test && bun run lint && bun run typecheck`), and lists all commands including labels, sync, stats, and doctor. Much of this is irrelevant to the harness (the harness has its own session protocol, quality gates are project-specific, label management is unused).

2. **`sd prime --compact` is lean** — 16 lines, just a command cheat sheet. This is approximately what the harness actually needs.

3. **`sd onboard` writes a 23-line section into CLAUDE.md** — it tells the agent to run `sd prime` at session start, provides a quick reference, and adds a "Before You Finish" checklist. This is loaded for every conversation in the project, so it's a persistent context tax.

4. **Custom PRIME.md**: Seeds checks for `.seeds/PRIME.md` before falling back to defaults. This means the harness could override the prime output with a minimal version. Good escape hatch.

5. **No global rules file**: Unlike beads, Seeds does not require a global rules file (like `beads-workflow.md`). This is a significant win — beads adds ~800 tokens to EVERY project, even ones that don't use issue tracking.

6. **No skills or hooks**: Seeds does not inject Claude Code skills, hooks, or slash commands into the consuming project. It's a pure CLI tool. The only injection is `sd onboard` (opt-in) and `sd prime` (agent-invoked).

### Verdict on context cost

Seeds is **3-5x cheaper** than beads on context. But the harness could achieve **near-zero** by:
- NOT using `sd onboard` (don't inject into CLAUDE.md)
- NOT using `sd prime` (don't invoke at session start)
- Instead, keeping a lean ~30-line rules section that just maps `bd` → `sd` commands

This is exactly the same approach as the custom `wt` option, just using Seeds as the underlying CLI instead of a shell script.

---

## 2. CLI Surface Area

### All `sd` subcommands (22 total)

**Issue commands (12):**
```
init, create, show, list, ready, update, close, dep, block, unblock, blocked, label
```

**Template commands (1 with subcommands):**
```
tpl (create, step add, list, show, pour, status)
```

**Project health (3):**
```
stats, sync, doctor
```

**Agent integration (2):**
```
prime, onboard
```

**Utility (2):**
```
upgrade, completions
```

**Migration (1):**
```
migrate-from-beads
```

### Comparison to harness needs

| Harness operation | Beads command | Seeds command | Match? |
|-------------------|---------------|---------------|--------|
| Create issue | `bd create` | `sd create` | Exact |
| List open | `bd list --status=open` | `sd list --status=open` | Exact |
| Find unblocked | `bd ready` | `sd ready` | Exact |
| Show details | `bd show <id>` | `sd show <id>` | Exact |
| Update status | `bd update <id> --status=...` | `sd update <id> --status=...` | Exact |
| Close issue | `bd close <id> --reason=...` | `sd close <id> --reason=...` | Exact |
| Search text | `bd search '<keyword>'` | **NO EQUIVALENT** | **MISSING** |
| Add dependency | `bd dep add <a> <b>` | `sd dep add <a> <b>` | Exact |
| Commit data | `bd vc commit -m "..."` | `sd sync` | Simpler |

### Critical gap: No search command

Seeds has **no `sd search` command**. The `sd list` command filters by status, type, assignee, and label — but there is no full-text search across issue titles, descriptions, or close reasons.

**Impact**: The harness uses `bd search` in 4 places for cross-session context recovery ("Search closed beads issues for context about <topic>"). Without search, agents would need to:
- Run `sd list --all --json` and pipe through `jq` for text matching
- Or `grep` the JSONL file directly

Both work (JSONL is grep-friendly), but it's an extra step the harness commands would need to handle. This is **not a dealbreaker** — JSONL grep is arguably faster and more flexible than `bd search` — but it means the harness needs a `grep_issues()` helper function or a thin wrapper.

**Note**: GitHub issue [#3](https://github.com/jayminwest/seeds/issues/3) requests comments, and [#4](https://github.com/jayminwest/seeds/issues/4) requests enhanced migration. No search feature request exists yet. This would be easy to contribute upstream.

### Is the API bloated?

No. Seeds has **22 commands** vs. beads' nominal 9 core commands, but:
- Seeds' extra commands are useful additions (block/unblock, labels, doctor, stats)
- Seeds has **no daemon**, no `vc commit`, no `export`/`import`, no `compact` — the commands that caused beads pain
- Every command supports `--json` for structured output
- Commands that aren't needed (tpl, labels, stats) don't add context cost — they're just unused CLI paths

The API surface is **right-sized**: lean where it counts, with useful extras that don't impose cost.

---

## 3. Data Format

### Schema

```typescript
interface Issue {
  id: string;              // "{project}-{4hex}" e.g. "seeds-a1b2"
  title: string;
  status: "open" | "in_progress" | "closed";
  type: "task" | "bug" | "feature" | "epic";
  priority: number;        // 0=critical, 1=high, 2=medium, 3=low, 4=backlog
  assignee?: string;
  description?: string;
  closeReason?: string;
  blocks?: string[];       // IDs this issue blocks
  blockedBy?: string[];    // IDs blocking this issue
  labels?: string[];
  convoy?: string;         // Template instance ID
  createdAt: string;       // ISO 8601
  updatedAt: string;
  closedAt?: string;
}
```

### Sample JSONL line (from Seeds' own `.seeds/issues.jsonl`)

```json
{"id":"seeds-0tk","title":"Build infra files","status":"closed","type":"task","priority":1,"createdAt":"2026-02-23T07:23:51.70417-08:00","updatedAt":"2026-02-23T07:28:04.077946-08:00","assignee":"jayminwest@gmail.com","description":"Create version-bump script...","closeReason":"Infrastructure files created...","closedAt":"2026-02-23T07:28:04.077946-08:00"}
```

### Merge strategy

- `.gitattributes`: `merge=union` on JSONL files (set by `sd init`)
- On read: dedup by ID, last occurrence wins
- This means parallel branch merges produce duplicates, which are cleaned on next read/write cycle
- **No merge conflicts ever** — union merge + dedup is bulletproof for append-heavy workloads

### ID generation

- Format: `{project-name}-{4-hex-chars}` (e.g., `myapp-a1b2`)
- Uses `crypto.randomBytes()` — not sequential
- Falls back to 8-hex-chars after 100 collisions at 4-hex length
- Project name comes from `.seeds/config.yaml`

### Compatibility with grep/jq

Excellent. One JSON object per line, no binary encoding, no headers. Standard grep, jq, and ripgrep all work perfectly:

```bash
# Search closed issues for keyword
grep -i "retry" .seeds/issues.jsonl | jq -r '.title'

# Find all open issues
jq -r 'select(.status == "open") | .id + " " + .title' .seeds/issues.jsonl

# Count by status
jq -r '.status' .seeds/issues.jsonl | sort | uniq -c
```

### Comparison to beads JSONL

The format is nearly identical to beads' `issues.jsonl`. Key differences:
- Seeds uses camelCase (`closeReason`, `createdAt`); beads uses both snake_case and camelCase
- Seeds adds `labels`, `convoy` fields
- Seeds omits beads' `owner` field (uses `assignee` instead)
- Both use ISO 8601 timestamps
- Both store dependencies as ID arrays

---

## 4. Dependency Support

### Commands

```bash
sd dep add <issue> <depends-on>      # issue depends on depends-on
sd dep remove <issue> <depends-on>   # remove dependency
sd dep list <issue>                  # show deps for an issue
sd block <id> --by <blocker-id>      # mark issue as blocked
sd unblock <id> --from <blocker-id>  # remove specific blocker
sd unblock <id> --all                # clear all resolved (closed) blockers
sd blocked                           # show all currently blocked issues
sd ready                             # open issues with no unresolved blockers
```

### How `sd ready` works

From `ready.ts`:
1. Load all issues
2. Collect IDs of all closed issues into a Set
3. Filter to status=open issues where ALL blockedBy IDs are in the closed set
4. Return the filtered list

This means:
- `sd ready` correctly handles transitive unblocking (if A depends on B and B is closed, A becomes ready)
- It does NOT auto-clear stale blockers from the `blockedBy` array — use `sd unblock --all` for that
- Both `dep add` and `block --by` maintain bidirectional consistency (updating both `blocks` and `blockedBy` arrays)

### Comparison to beads

Feature parity. Seeds has all the dependency operations beads has, plus:
- `sd unblock` (beads requires manual JSONL editing to remove blockers)
- `sd block` (beads supports this at create time only)
- `sd blocked` (dedicated blocked-issues view)

**Seeds is strictly better than beads on dependency management.**

---

## 5. Migration from Beads

### `sd migrate-from-beads`

From `migrate.ts`:

1. Reads `.beads/issues.jsonl` from the project root
2. Parses each line as JSON (skips malformed)
3. Maps beads fields to seeds fields:
   - `status`: maps `in-progress` → `in_progress`, `done`/`complete` → `closed`
   - `type`: maps `issue_type` or `type` → seeds types
   - `owner` → `assignee`
   - `close_reason`/`closeReason` → `closeReason`
   - `blocked_by`/`blockedBy` → `blockedBy`
   - Handles both snake_case and camelCase field names
4. **Preserves original IDs** — beads IDs are kept as-is
5. Skips issues that already exist in `.seeds/issues.jsonl` (by ID)
6. Appends new issues under advisory lock with atomic write

### What it migrates

| Data | Migrated? |
|------|-----------|
| Issue ID | Yes (preserved) |
| Title | Yes |
| Status | Yes (with mapping) |
| Type | Yes (with mapping) |
| Priority | Yes |
| Assignee/Owner | Yes |
| Description | Yes |
| Close reason | Yes |
| Dependencies (blocks/blockedBy) | Yes |
| Timestamps | Yes |
| Labels | No (beads doesn't have labels) |
| Config | No (must run `sd init` separately) |

### What it does NOT migrate

- Beads `beads.db` (SQLite) — only reads from `issues.jsonl`
- Dolt version history
- Beads configuration (project name, etc.)
- Any daemon state

### Verdict

Migration is straightforward and well-implemented. The preserved-ID approach means all existing references in `.work/` state files, handoff prompts, and commit messages remain valid. **No manual intervention needed.**

---

## 6. Runtime & Dependencies

### Requirements

| Component | Details |
|-----------|---------|
| Runtime | **Bun** (>=1.0.0) — required, not optional |
| Runtime deps | chalk (5.6.2), commander (14.0.3) |
| Dev deps | @biomejs/biome, @types/bun, typescript |
| Install | `bun install -g @os-eco/seeds-cli` |
| Binary | `sd` (TypeScript executed directly by Bun) |
| Daemon | **None** |
| Background process | **None** |
| Database | **None** — JSONL files only |

### Bun dependency

This is the biggest practical concern. The harness runs on Arch Linux with tool versioning via `mise`. Bun is available via mise (`mise use bun`), but it's an additional runtime to manage alongside Go, Node, and Python.

**Mitigation**: Seeds can be run via `npx @os-eco/seeds-cli` without global install, but this is slow (downloads on each invocation). For development, `bun link` in a local clone works.

**Alternative**: Could potentially run under Node.js (the TypeScript uses Bun-specific APIs like `Bun.file` and `Bun.write`, so this would require source changes or a compatibility shim). Not practical without forking.

### No daemon

This is a major improvement over beads. Seeds:
- No socket file
- No background process to manage
- No PID file
- No daemon logs
- No auto-import/export cycles
- No state management complexity

Every `sd` command reads JSONL, does work, writes JSONL, exits. Stateless. Clean.

---

## 7. Maturity & Risk

### Project health

| Metric | Value | Assessment |
|--------|-------|------------|
| Stars | 66 | Early adoption |
| Forks | 14 | Some interest |
| Contributors | **1** (jayminwest) | **Bus factor = 1** |
| Commits | 80 | Moderate velocity |
| Open issues | 2 (comments feature, Dolt migration) | Low backlog |
| Closed issues | 3 | Light issue history |
| First commit | 2026-02-23 | ~4 weeks old |
| Last commit | 2026-03-23 | Active (2 days ago) |
| Latest version | v0.2.5 | Pre-1.0, expect breaking changes |
| License | MIT | Permissive, forkable |
| Test count | 211 | Good coverage |
| CI | GitHub Actions (lint + typecheck + test) | Proper CI |

### Ecosystem coupling

Seeds is part of the "os-eco" ecosystem with:
- **Overstory**: Agent orchestration (multi-agent coordination, worktrees)
- **Mulch**: Knowledge/expertise management (learning persistence)
- **Canopy**: Prompt management

Seeds' CLAUDE.md includes sections for all three via marker comments. However, **Seeds itself has no runtime dependency on any of these**. The CLI works standalone — the ecosystem integration is purely in the CLAUDE.md instructions that `sd onboard` generates.

**Risk**: If the ecosystem evolves in a direction incompatible with the harness's patterns (e.g., overstory starts conflicting with harness orchestration), Seeds might be pulled along.

**Mitigation**: Seeds is MIT-licensed and self-contained. Forking is trivial.

### Known limitations

1. **No search command** — must grep JSONL directly
2. **No comments on issues** — feature requested in [#3](https://github.com/jayminwest/seeds/issues/3)
3. **Bun-only** — cannot run under Node.js without modification
4. **No `--search` or `--grep` flag on `sd list`**
5. **IDs are random hex** — no human-readable sequential numbering
6. **Single developer** — all 80 commits are from jayminwest

---

## 8. Head-to-Head Comparison

| Dimension | Beads (bd) | Seeds (sd) | Custom wt |
|-----------|-----------|-----------|-----------|
| **Context cost** | Poor (~2,000+ tokens) | Good (~500 tokens, reducible to ~100) | Excellent (~100 tokens) |
| **CLI complexity** | Medium (9 core + extras) | Right-sized (22 commands, all useful) | Minimal (6 commands) |
| **Data format** | JSONL + SQLite + Dolt | JSONL only | JSONL only |
| **Dependency support** | Good | Excellent (better than beads) | Must build |
| **Search** | Built-in (`bd search`) | **Missing** (grep JSONL) | Must build (grep) |
| **Merge handling** | Complex (SQLite conflicts) | Clean (union + dedup) | Must build (union + dedup) |
| **Concurrent access** | SQLite locks (fragile) | Advisory locks + atomic writes | Must build (flock) |
| **Daemon required** | Yes (pain point) | No | No |
| **Runtime** | Go binary + Dolt | Bun (TypeScript) | POSIX sh + jq / Go binary |
| **Installation** | Complex (Dolt, daemon) | `bun install -g` | Copy script |
| **Migration** | N/A (incumbent) | Built-in, preserves IDs | Must build |
| **Stability** | Mature but complex | Early (v0.2.5, 4 weeks) | Depends on implementation |
| **Bus factor** | Low (small team) | **1** (sole developer) | Self (full control) |
| **Maintenance burden** | High (daemon, sync, Dolt) | Low (community) | Medium (self-maintained) |
| **--json output** | Partial | Universal (every command) | Must build |
| **Offline-first** | Yes (with daemon overhead) | Yes (just files) | Yes |
| **Git-native** | Partial (SQLite not diffable) | Excellent (JSONL + merge=union) | Excellent |

### Ratings (1-5, 5 = best for harness)

| Dimension | Beads | Seeds | Custom wt |
|-----------|-------|-------|-----------|
| Context cost | 1 | 4 | 5 |
| CLI fit | 3 | 4 | 5 |
| Data format | 2 | 5 | 5 |
| Dependencies support | 4 | 5 | 3 |
| Search | 4 | 2 | 3 |
| Stability | 3 | 2 | 3 |
| Maintenance burden | 1 | 4 | 2 |
| Installation ease | 1 | 3 | 5 |
| **Total** | **19/40** | **29/40** | **31/40** |

---

## 9. Deal-Breakers Assessment

### Does it try to own the workflow?

**No.** Unlike Chainlink (which injects hooks, rules, and behavioral guardrails), Seeds is a pure CLI tool. The `sd prime` and `sd onboard` are opt-in context injection — the harness can choose not to use them. Seeds does not:
- Install Claude Code hooks
- Register slash commands in the consuming project
- Create rules files
- Override the agent's behavior

The overstory/mulch/canopy ecosystem references in Seeds' CLAUDE.md are specific to the seeds *development project*, not injected into consuming projects.

### Does it inject heavy context?

**Not by default.** The only automatic injection is `sd onboard` (23 lines into CLAUDE.md) — and that's opt-in. The `sd prime` output is invoked by the agent at session start, and the harness can override it with a custom `.seeds/PRIME.md` file or simply not use it.

### Is it abandoned?

**No.** Last commit was 2026-03-23 (2 days before this evaluation). Active development with v0.2.5 shipped March 4. However, the sole-developer pattern is a risk for long-term maintenance.

### Does it require a daemon?

**No.** This is Seeds' biggest advantage over beads. Zero background processes.

### Is the data format incompatible with grep?

**No.** JSONL is the most grep-friendly structured format possible. One record per line, plain text, no binary encoding.

### Actual deal-breakers found

1. **Bun runtime dependency** — not a hard deal-breaker (Bun is available via mise) but adds a runtime to the stack. If Bun is not already in use, this is friction.

2. **No search command** — the harness uses `bd search` for cross-session context recovery. Without it, the harness must provide a grep wrapper or contribute search upstream. Not a deal-breaker (JSONL grep works) but requires harness-side work.

3. **Bus factor of 1** — if jayminwest stops maintaining Seeds, the harness would need to fork or migrate again. MIT license makes forking viable, and the codebase is small (~1,200 LOC TypeScript) so maintaining a fork is practical.

---

## 10. Recommendations for the Harness

### If adopting Seeds

1. **Do NOT use `sd onboard`** — don't inject the seeds section into CLAUDE.md. The harness has its own context injection via rules files and skills.

2. **Do NOT use `sd prime` at session start** — the full prime output is 83 lines of workflow instructions that duplicate/conflict with the harness's own session protocols.

3. **DO create a custom `.seeds/PRIME.md`** — if prime must be used, override with a 10-line command cheat sheet (similar to `--compact` but without the "Before finishing" line).

4. **Replace `bd` with `sd` in rules** — the beads-workflow.md rules file can be adapted with a simple find-replace plus:
   - Change `bd vc commit` → `sd sync`
   - Change `bd search` → `grep -i '<keyword>' .seeds/issues.jsonl | jq .`
   - Remove daemon-related instructions

5. **Add a `search` wrapper** — since Seeds lacks search, add a thin function to the harness:
   ```bash
   sd-search() { grep -i "$1" .seeds/issues.jsonl | jq -r '.id + " " + .title'; }
   ```

6. **Pin Seeds version** — use `bun install -g @os-eco/seeds-cli@0.2.5` to avoid surprise breaking changes in pre-1.0.

7. **Run migration**: `sd init && sd migrate-from-beads` preserves all existing issue IDs and data.

### Seeds vs. Custom `wt` — which to build?

Seeds scores 29/40 vs. custom wt at 31/40. The gap is narrow and comes down to:

- **Seeds wins on**: zero implementation effort, community maintenance (if maintained), built-in migration, better dependency management, tested concurrent access
- **Custom wt wins on**: zero runtime dependency, zero context cost, exact API surface match, full control, no bus-factor risk

**Recommendation**: If the Bun dependency is acceptable, Seeds is the pragmatic choice — it's already built, tested, and covers 95% of the harness's needs. The 2-point gap (search + installation) is closable by contributing a search command upstream and using mise for Bun management.

If Bun is unacceptable, build the custom `wt` — but budget 2-4 hours for implementation and testing.
