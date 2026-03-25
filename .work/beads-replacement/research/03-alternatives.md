# Alternatives to Beads for AI-Agent Issue Tracking

## Questions

- What are the viable replacements for beads in the work harness?
- Which alternatives minimize context window cost while preserving dependency tracking, search, and cross-session coordination?
- Are there newer tools purpose-built for AI agent task coordination?
- Could the workflow layer (state.json) absorb issue-tracking duties, eliminating a separate tool entirely?

---

## Findings

### 1. GitHub Issues + `gh` CLI

**What it is**: GitHub's native issue tracker, accessed via the `gh` CLI tool already installed on the system.

**Dependency support**: GitHub shipped issue dependencies (blocked-by/blocking) as a generally available feature in August 2025, with full API and webhook support. The `gh` CLI does not yet have native `--blocked-by`/`--blocking` flags (feature request: [cli/cli#11757](https://github.com/cli/cli/issues/11757)), but two community extensions fill the gap:
- [gh-issue-dependency](https://github.com/torynet/gh-issue-dependency) — add/remove/list blocking relationships
- [gh-issue-ext](https://github.com/jwilger/gh-issue-ext) — sub-issues, blocking deps, linked branches

**Search**: Full-text search via `gh issue list --search "keyword"`, label/milestone/assignee filtering. GitHub's search is powerful and well-indexed.

**Context window cost**: Zero prompt injection needed. The agent just calls `gh issue create`, `gh issue list`, etc. via Bash. No rules file, no skills, no daemon. The `gh` CLI is self-documenting and any model already knows it. Estimated context cost: **<100 tokens** (just a brief "use gh for issues" note in rules, or nothing at all).

**Git-native**: Issues live on GitHub, not in the repo. This is both a strength (no repo clutter) and a weakness (requires network access, external service dependency).

**Stability**: Extremely mature. `gh` CLI is maintained by GitHub, v2.x, actively developed.

| Dimension | Rating |
|-----------|--------|
| Context window cost | Excellent (near zero) |
| Dependency support | Good (via extensions or API) |
| Search | Excellent |
| Git-native | No (external service) |
| Stability | Excellent |
| Integration complexity | Low |
| AI agent usability | Excellent (models know `gh` natively) |

**Pros**:
- Zero new tooling to install (gh already present)
- Zero context injection (models know gh)
- Excellent search, filtering, and API
- Dependencies now supported natively
- Issues visible in GitHub web UI for human review
- Sub-issues supported via API

**Cons**:
- Requires network access (breaks offline-first)
- External service dependency (not git-native)
- Rate limiting on heavy agent usage (5,000 requests/hour for authenticated)
- Dependency queries require extensions or GraphQL API calls
- No `ready` command equivalent without scripting
- Issues not in the git history (can't grep closed issues from a detached checkout)

---

### 2. Seeds (`sd`)

**What it is**: A purpose-built replacement for beads, created explicitly for AI agent workflows. JSONL storage, zero external dependencies beyond chalk + commander. Part of the [os-eco](https://github.com/jayminwest/os-eco) AI agent tooling ecosystem.

**Repository**: [github.com/jayminwest/seeds](https://github.com/jayminwest/seeds) — 66 stars, 80 commits, v0.2.5 (March 2026). TypeScript/Bun runtime.

**Data format**: `.seeds/issues.jsonl` — one JSON object per line, diffable, uses `merge=union` gitattribute for automatic merge handling. Dedup-on-read (last occurrence wins).

**Dependency support**: Full. `sd dep add/remove/list`, `sd block/unblock`, `sd ready` (shows unblocked work). Direct feature parity with beads.

**Search**: `sd list` with `--status`, `--type`, `--assignee`, `--label` filters. No explicit full-text search command found, but JSONL is greppable.

**Context window cost**: Has `sd prime` (outputs AI context) and `sd onboard` (injects into CLAUDE.md). The context footprint is unclear — could be minimal or could repeat the beads pattern of heavy prompt injection. Need to inspect actual output. Risk of recreating the same bloat problem.

**Migration**: Built-in `sd migrate-from-beads` command imports `.beads/issues.jsonl` into `.seeds/`.

| Dimension | Rating |
|-----------|--------|
| Context window cost | Unknown (has prime/onboard — could be light or heavy) |
| Dependency support | Excellent (full parity with beads) |
| Search | Good (filter-based, JSONL is greppable) |
| Git-native | Excellent (JSONL in repo, merge=union) |
| Stability | Early (v0.2.5, 66 stars, 80 commits) |
| Integration complexity | Low (CLI drop-in for beads) |
| AI agent usability | Good (--json output, designed for agents) |

**Pros**:
- Direct beads replacement — nearly identical API surface
- JSONL-only storage (no SQLite, no daemon, no Dolt)
- Built-in migration from beads
- Advisory file locks for concurrent agent access
- merge=union gitattribute for branch merges
- Part of a broader AI agent ecosystem (Mulch, Canopy, Overstory)

**Cons**:
- Very young project (v0.2.5, March 2026)
- Requires Bun runtime (extra dependency)
- May repeat beads' context bloat pattern with `sd prime`/`sd onboard`
- 30+ commands — similar API surface area complexity to beads
- Single developer project — bus factor of 1
- Unclear if `sd prime` is minimal or heavy on context injection

---

### 3. Custom JSONL Tracker (Shell Script)

**What it is**: A minimal custom tracker built as a thin shell script (or small Go/Python CLI) wrapping `jq` operations on a `.issues/issues.jsonl` file. Implements only the 6 operations actually used: create, list, update, close, search, deps.

**Data format**: JSONL file(s) in `.issues/` directory. Same format as beads/seeds but with zero external tooling.

**Dependency support**: Implement as a `depends_on` JSON array field. `ready` = filter for status=open AND no open dependencies.

**Search**: `grep` or `jq` on JSONL. Fast, simple, zero-cost.

**Context window cost**: Minimal. The script is self-contained; the agent calls it like any other CLI. Rules file could be 20-30 lines. Estimated: **100-200 tokens**.

**Estimated implementation effort**: 200-400 lines of shell script (with jq), or ~500 lines of Go for a compiled binary with better error handling.

| Dimension | Rating |
|-----------|--------|
| Context window cost | Excellent (minimal rules needed) |
| Dependency support | Good (must implement, but straightforward) |
| Search | Good (grep/jq on JSONL) |
| Git-native | Excellent (JSONL in repo) |
| Stability | Depends on implementation quality |
| Integration complexity | Medium (must build + maintain) |
| AI agent usability | Good (simple CLI, --json output) |

**Pros**:
- Absolute minimum context window cost
- No external dependencies (POSIX sh + jq, or standalone Go binary)
- Tailored exactly to the harness's needs — no unused features
- Full control over data format and CLI surface
- Git-native by definition
- Can be incrementally built and tested
- Simple enough that any AI agent can understand the entire tool

**Cons**:
- Must build and maintain it (ongoing cost)
- Shell scripts can be fragile for concurrent access (need advisory locks)
- No community, no bug reports from other users
- Feature requests require implementation effort
- Risk of scope creep (rebuilding beads/seeds)

**Core API** (estimated):

```
wt create --title "..." [--type task] [--priority 2] [--depends-on ID]
wt list [--status open|closed|in_progress] [--ready]
wt show <id>
wt update <id> --status in_progress
wt close <id> [--reason "..."]
wt search <keyword>
```

---

### 4. Extend state.json (Absorb Into Workflow Layer)

**What it is**: Eliminate the separate issue-tracking tool entirely. Add issue-tracking fields directly into `.work/*/state.json` or a sibling file like `.work/*/issues.jsonl`.

**How it would work**:
- Each task's `.work/<name>/` directory already tracks the task lifecycle
- Add a `issues` array to state.json, or a separate `issues.jsonl` file per task
- Gate issues, sub-task issues, review findings — all in the task directory
- Cross-task queries via simple glob + jq across `.work/*/issues.jsonl`

**Context window cost**: Zero additional tools. The agent already reads/writes state.json. Issue operations become jq transformations on a known file. **Near zero marginal context cost**.

| Dimension | Rating |
|-----------|--------|
| Context window cost | Excellent (zero new tools) |
| Dependency support | Must implement (JSON field) |
| Search | Fair (glob + jq across .work/ directories) |
| Git-native | Excellent (already in repo) |
| Stability | Inherits workflow layer stability |
| Integration complexity | Low (extends existing infra) |
| AI agent usability | Excellent (agents already manage state.json) |

**Pros**:
- Zero new tools, zero new context injection
- Natural fit — issues are scoped to the task they belong to
- Already git-tracked
- Eliminates a tool dependency entirely
- Simplifies the mental model (one system, not three)

**Cons**:
- Cross-task queries are harder (must scan multiple directories)
- No centralized "all open issues" view without aggregation
- Archived tasks move their issues to archive too
- Doesn't naturally support standalone issues (not tied to a task)
- `bd search` for historical context becomes harder (must search archived tasks)
- Risk of state.json bloat for complex T3 tasks with many issues

---

### 5. git-bug

**What it is**: Distributed, offline-first bug tracker embedded in git. Stores issues as git objects (not files). 9.7k stars, v0.10.1 (May 2025), actively maintained.

**Repository**: [github.com/git-bug/git-bug](https://github.com/git-bug/git-bug)

**Dependency support**: Not mentioned in documentation. No evidence of blocked-by/blocking relationships.

**Search**: Built-in search, described as "millisecond-speed." Query language exists but details unclear.

**Context window cost**: Low — it's a standalone CLI (`git bug add`, `git bug ls`, etc.). Models could learn it from a brief rules section. Estimated: **200-400 tokens**.

**Data storage**: Git objects (not files). This is elegant for distribution but opaque — you can't grep the issue data directly, and it doesn't produce a diffable JSONL file.

| Dimension | Rating |
|-----------|--------|
| Context window cost | Good (standalone CLI) |
| Dependency support | None (dealbreaker for T3 workflows) |
| Search | Good (built-in, fast) |
| Git-native | Excellent (git objects) |
| Stability | Good (9.7k stars, active, v0.10.1) |
| Integration complexity | Medium (new tool to install + learn) |
| AI agent usability | Fair (non-standard CLI, no --json output documented) |

**Pros**:
- Most mature git-native option (9.7k stars)
- True offline-first, no external services
- Fast search
- Bridges to GitHub/GitLab for sync

**Cons**:
- No dependency tracking (dealbreaker)
- Data stored as git objects, not greppable files
- No `--json` output mode documented (agents need structured output)
- Would need significant wrapper scripting to match beads functionality
- Written in Go — if you need to extend it, non-trivial

---

### 6. Chainlink

**What it is**: A CLI issue tracker specifically designed for AI-assisted development. Written in Rust, SQLite storage. 281 stars, 117 commits.

**Repository**: [github.com/dollspace-gay/chainlink](https://github.com/dollspace-gay/chainlink)

**Dependency support**: Yes — `block`, `unblock`, `ready`, `blocked` commands. Also has `relate/unrelate`.

**Search**: Filter by status, label, priority. No full-text search.

**Session management**: Built-in session tracking with breadcrumbs, handoff notes. Claude Code hooks included.

**Context window cost**: Includes its own Claude Code hooks and `.chainlink/rules/` configuration. Designed to inject behavioral guardrails. Likely **moderate-to-high context cost** — it wants to control the agent's behavior.

**Data storage**: SQLite at `.chainlink/issues.db`. Not diffable, not greppable, not git-friendly.

| Dimension | Rating |
|-----------|--------|
| Context window cost | Poor (injects hooks, rules, guardrails) |
| Dependency support | Good |
| Search | Fair (filter-based only) |
| Git-native | Poor (SQLite database) |
| Stability | Moderate (281 stars, Rust) |
| Integration complexity | High (opinionated, wants to own the workflow) |
| AI agent usability | Good (designed for AI agents) |

**Pros**:
- Purpose-built for AI agent development
- Full dependency support with ready/blocked queries
- Session management with handoff notes
- Time tracking, milestones, sub-issues
- Written in Rust (fast, single binary)

**Cons**:
- SQLite storage — not diffable, not git-friendly
- Opinionated workflow — wants to control agent behavior via hooks/rules
- Would conflict with the existing work harness (competing control plane)
- High context injection (its own rules, hooks, guardrails)
- No JSONL/text export as primary format
- Adds complexity rather than removing it

---

### 7. Taskwarrior

**What it is**: Mature CLI task manager (v3.x). JSON data format, dependency support, extensive filtering.

**Dependency support**: Yes — `depends` field containing comma-separated UUIDs. `task ready` shows unblocked tasks.

**Data format**: JSON files in `~/.task/` (not in the repo). Can be synced to git via community scripts.

**Search**: Powerful filter expressions, report customization.

**Context window cost**: Models know Taskwarrior well. Brief rules section sufficient. Estimated: **200-300 tokens**.

| Dimension | Rating |
|-----------|--------|
| Context window cost | Good (well-known tool) |
| Dependency support | Excellent (native, with `task ready`) |
| Search | Excellent (powerful filters) |
| Git-native | Poor (data in ~/.task, not in repo) |
| Stability | Excellent (very mature, large community) |
| Integration complexity | Medium (data location mismatch) |
| AI agent usability | Good (models know it) |

**Pros**:
- Mature, well-tested, extensive feature set
- Native dependency tracking with `task ready`
- Models already know the command surface
- Powerful filtering and reporting

**Cons**:
- Data stored in `~/.task/`, not in the project repo (not git-native)
- Getting data into the repo requires sync scripts (fragile)
- Data format is JSON lines but with taskwarrior-specific semantics
- Heavy for the use case — many features we'd never use
- Multiple projects in one data store creates noise
- Per-project isolation requires config hacks

---

### 8. Claude Code Native Tasks

**What it is**: Claude Code's built-in task system, stored at `~/.claude/tasks/{task-list-id}/`. Supports dependencies, multi-session coordination, and is used natively by Agent Teams.

**Dependency support**: Yes — tasks can depend on other tasks; pending tasks with unresolved deps cannot be claimed.

**Multi-session coordination**: Tasks persist to disk and are shared across sessions via `CLAUDE_CODE_TASK_LIST_ID` environment variable. Updates are immediate (file-based).

**Context window cost**: Zero — it's built into Claude Code itself. The agent uses `TaskCreate`, `TaskUpdate`, `TaskList` internally. No CLI, no rules, no prompt injection needed.

| Dimension | Rating |
|-----------|--------|
| Context window cost | Perfect (built-in, zero injection) |
| Dependency support | Good (native) |
| Search | Poor (no search API, limited to list/get) |
| Git-native | No (stored in ~/.claude/, not in repo) |
| Stability | Experimental (marked as such in docs) |
| Integration complexity | Low (already available) |
| AI agent usability | Perfect (native primitives) |

**Pros**:
- Zero context cost — it's a native Claude Code capability
- Dependencies and blocking built-in
- Multi-session coordination works out of the box
- File locking for concurrent access
- No external tool to install or maintain

**Cons**:
- Data stored in `~/.claude/tasks/`, NOT in the repo (not git-tracked)
- Experimental feature, subject to breaking changes
- No search capability (can't query historical tasks)
- No close reason, no description field beyond task title
- Tasks are ephemeral (no persistent audit trail)
- Can't grep closed tasks for prior art (critical gap)
- Limited metadata (no type, priority, custom fields)
- Tight coupling to Claude Code (not portable to other agents)

---

### 9. todo.txt Format

**What it is**: A simple plaintext format for task management. One task per line, human-readable, extensible via `key:value` pairs.

**Dependency support**: Not in core spec. Some tools (topydo) add `id:` and `p:` (parent) extensions. Would need custom implementation.

**Context window cost**: Very low — the format is trivial. Estimated: **50-100 tokens**.

| Dimension | Rating |
|-----------|--------|
| Context window cost | Excellent |
| Dependency support | Poor (requires extensions) |
| Search | Good (grep-friendly) |
| Git-native | Excellent (plaintext file) |
| Stability | Excellent (format is frozen) |
| Integration complexity | Medium (need wrapper for deps) |
| AI agent usability | Good (simple format) |

**Pros**:
- Extremely simple format, human-readable
- Git-friendly (single text file, easy diffs)
- Frozen spec — will never break
- Many existing tools and editors

**Cons**:
- No native dependency support
- No structured metadata (IDs, types, close reasons)
- Extensions are non-standard across tools
- Would need significant wrapping to match beads functionality
- Not designed for programmatic use (no JSON output)

---

### 10. Dolt-Backed Approach (Fix Beads, Don't Replace)

**What it is**: Keep the Dolt-versioned database concept but strip away the daemon, SQLite cache, and complex sync mechanism. Use Dolt as a git-like versioned database directly.

**Reality check**: From the pain points analysis (02-pain-points.md), Dolt/VC is "not actually used" — it's dead weight. The JSONL file IS the source of truth in practice. The SQLite layer exists only for query performance, and the daemon exists only to manage SQLite. The entire Dolt layer could be removed without losing any actual functionality.

| Dimension | Rating |
|-----------|--------|
| Context window cost | Same as beads (still needs rules) |
| Dependency support | Same as beads |
| Search | Same as beads |
| Git-native | Partial (Dolt is git-like but not git) |
| Stability | Worse (must maintain a fork) |
| Integration complexity | High (must rewrite beads internals) |
| AI agent usability | Same as beads |

**Verdict**: Not recommended. The problem IS beads (complexity, context cost, daemon), not the storage backend. Fixing beads means rebuilding beads — better to start fresh with a simpler design.

---

### 11. git-issue

**What it is**: Minimalist decentralized issue management using git. Issues stored as text files in `.issues/` directories.

**Repository**: [github.com/dspinellis/git-issue](https://github.com/dspinellis/git-issue) — 865 stars, 514 commits.

**Dependency support**: None.

**Data format**: Filesystem directories — each issue gets a folder with text files for description, tags, etc.

| Dimension | Rating |
|-----------|--------|
| Context window cost | Good (simple CLI) |
| Dependency support | None (dealbreaker) |
| Search | Fair (file-based) |
| Git-native | Excellent |
| Stability | Moderate |
| Integration complexity | Medium |
| AI agent usability | Fair |

**Verdict**: No dependency support makes this unsuitable for T3 workflows.

---

### 12. driusan/bug (PoormanIssueTracker)

**What it is**: Filesystem-based issue tracker. Issues as directories in `issues/`, plaintext files.

**Status**: Last commit 2016. Unmaintained. 211 stars.

**Verdict**: Dead project, no dependencies. Not viable.

---

## Comparison Matrix

| Alternative | Context Cost | Dependencies | Search | Git-Native | Stability | Effort |
|------------|-------------|-------------|--------|-----------|-----------|--------|
| GitHub Issues + gh | Near zero | Yes (API) | Excellent | No | Excellent | Low |
| Seeds (sd) | Unknown | Excellent | Good | Excellent | Early | Low |
| Custom JSONL | Excellent | Must build | Good | Excellent | Self | Medium |
| Extend state.json | Near zero | Must build | Fair | Excellent | Inherits | Low-Med |
| git-bug | Good | None | Good | Excellent | Good | Medium |
| Chainlink | Poor | Good | Fair | Poor | Moderate | High |
| Taskwarrior | Good | Excellent | Excellent | Poor | Excellent | Medium |
| CC Native Tasks | Zero | Good | None | No | Experimental | Low |
| todo.txt | Excellent | None | Good | Excellent | Excellent | Medium |
| Dolt-backed | Same | Same | Same | Partial | Worse | High |

---

## Recommendations

### Rank 1: Custom JSONL Tracker

**Why**: This is the sweet spot for the work harness. The pain points analysis (02-pain-points.md) already concluded that "a thin shell script wrapping jq operations on a JSONL file could replace 90% of functionality." This approach:
- Minimizes context window cost to near zero (simple CLI, 6 commands)
- Eliminates all external dependencies (no daemon, no runtime, no binary)
- JSONL in git = diffable, searchable, mergeable
- Tailored exactly to the harness's 6 actual operations (create, list, update, close, search, deps)
- Can be prototyped in ~200 lines of shell script
- Agent knows exactly what the tool does because it's simple enough to explain in 20 lines of rules

**Implementation path**: Write a `wt` (work-tracker) shell script, 200-400 lines, using jq for JSON manipulation. Store data in `.issues/issues.jsonl`. Update 14 command files to use `wt` instead of `bd`. Rewrite the beads-workflow.md rules to ~30 lines.

**Risk**: Maintenance burden, concurrent access needs advisory locks, possible edge cases.

### Rank 2: GitHub Issues + `gh` CLI

**Why**: If the offline-first/git-native requirement can be relaxed, this is the winner. Zero context cost (models know `gh` natively), zero maintenance, excellent search, dependencies now supported. The only real costs are network dependency and the fact that issues aren't in the git history.

**Implementation path**: Replace `bd` calls with `gh issue` calls in all commands. Write a thin `ready` helper script that queries for unblocked issues. Rewrite beads-workflow.md to ~15 lines or eliminate it entirely.

**Risk**: Network dependency, rate limiting with heavy agent use, no offline access, dependency queries need GraphQL or extension.

### Rank 3: Hybrid — Extend state.json + Minimal JSONL

**Why**: The most radical simplification. Eliminate the separate issue tracker entirely for T1/T2 tasks (which are already fully tracked by state.json). Only use a lightweight JSONL tracker for T3 tasks that genuinely need dependency graphs and sub-task coordination. This cuts the context cost for 80% of sessions to zero.

**Implementation path**:
1. For T1/T2: state.json already has `issue_id`, status tracking, step management. Add a `close_reason` field. No separate tool needed.
2. For T3: Add a `.work/<name>/issues.jsonl` file for sub-task tracking. Implement a minimal `wt` script scoped to the task directory.
3. For cross-task search: A simple `wt search` that greps across all `.work/*/issues.jsonl` files.

**Risk**: T3 workflows become slightly different from T1/T2. Cross-task queries require scanning archived directories.

---

## Open Questions

1. **Seeds' actual context cost**: Need to install seeds and run `sd prime` and `sd onboard` to measure actual token injection. If it's <200 tokens, seeds jumps to Rank 1 as a drop-in replacement with community maintenance.

2. **gh issue dependency maturity**: The GitHub dependency API is new (August 2025). How reliable is it? Can `gh api` query blocked/unblocked status efficiently? Need to test the GraphQL query performance.

3. **Concurrent access in shell scripts**: If multiple agents modify `.issues/issues.jsonl` simultaneously, advisory file locks (flock) may not be sufficient. Seeds uses `O_CREAT | O_EXCL` atomic locks — is this needed for the harness, or is concurrent write rare enough to ignore?

4. **Cross-session context recovery**: The `bd search` for "check closed issues before exploring code" pattern is used in 7+ commands. Any replacement must support efficient text search across closed issues. How critical is this in practice vs. how often it's actually invoked?

5. **Claude Code Native Tasks evolution**: The task system is marked experimental. If Anthropic adds search, persistent storage, and richer metadata, it could eventually replace all custom tracking. Worth monitoring but not betting on today.

6. **Beads rule file elimination**: The 126-line `beads-workflow.md` is loaded for ALL projects, not just work-harness. Removing beads means removing this global tax. Any replacement should be project-scoped (loaded only when `.issues/` or `.work/` exists).

7. **Migration path**: With 108 existing issues and 14+ command files to update, what's the phased migration plan? Can we run old and new in parallel during transition?
