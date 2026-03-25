# Beads Replacement — Research Deliverable

## Executive Summary

Beads is a daemon-backed, SQLite-cached issue tracker consuming **1,500-2,500 tokens of context per session** while providing value primarily as an audit log — not as the task tracker it was designed to be. Its "designed" features (dependency graphs, ready queries, multi-issue coordination) are documented in templates but **never actually invoked** in command logic. Meanwhile, the harness already tracks the complete task lifecycle in `.work/*/state.json`, making beads a parallel bookkeeping system that duplicates state, adds complexity, and burns context.

The recommendation is to replace beads with a **custom minimal tracker** (`wt`) — a ~200-400 line shell script wrapping `jq` on JSONL — that implements only the 6 operations actually used, eliminates the daemon/SQLite/Dolt layers, and reduces context injection from ~2,000 tokens to ~100.

---

## Findings

### 1. Integration Depth

Beads is deeply woven into the harness:

| Surface | Scope |
|---------|-------|
| Global rule file | 126 lines, loaded for ALL projects |
| Commands | 14+ files, ~120 `bd` CLI invocations |
| Hooks | 3 (beads-check.sh, artifact-gate.sh, state-guard.sh) |
| Skills | 20+ `beads:*` entries registered |
| State.json fields | `issue_id`, `beads_epic_id`, `gate_id` per step |
| Session start injection | Beads context block + rules |

A replacement requires touching ~20 files. This is significant but tractable — most changes are mechanical (swap `bd X` for `wt X`).

### 2. Context Window Cost

The single biggest problem. Before the user types a word:

| Source | Estimated Tokens |
|--------|-----------------|
| `beads-workflow.md` (global rule) | 600-800 |
| Session start hook injection | 200-400 |
| `beads:*` skills (20+ entries) | 400-600 |
| Command-embedded `bd` instructions | 300-700 |
| **Total per session** | **1,500-2,500** |

This is a tax on every session in every project, regardless of whether beads is needed.

### 3. Actual vs. Designed Usage

| Feature | Designed For | Actually Used? |
|---------|-------------|----------------|
| Issue CRUD (create/update/close) | Task tracking | YES — as audit log |
| `bd ready` (unblocked work) | Task coordination | NO — 3 template refs, 0 command invocations |
| `bd dep add` (dependencies) | Gating | NO — 2 example-syntax refs, never called |
| `bd search` (context recovery) | Cross-session context | WEAKLY — 4 refs, aspirational pattern |
| `bd show` (issue details) | Issue review | WEAKLY — 4 refs, mostly in reground |
| `bd list` (discovery) | Finding work | YES — in hooks and commands |
| Gate issues | Transition audit | YES — created and closed within seconds |
| Epic tracking | T3 coordination | YES — stores epic ID, but decompose specs do the real work |

**The key insight**: Beads is being used as an **audit log** (documenting what happened) and a **session gate** (enforcing issue-before-code), not as a task tracker or coordination system. Its designed coordination features (deps, ready, claiming) are unused.

### 4. The Daemon Problem

Beads runs a daemon (`bd.sock`) managing SQLite with auto-import/export from JSONL:
- 3.6 MB disk footprint (db + WAL + SHM + JSONL)
- 476+ KB daemon log in 8 days
- Constant import/export cycles create sync warnings
- Dolt/VC layer configured but never used

All of this complexity serves 108 JSONL lines of issue data.

### 5. State Duplication

The harness maintains parallel task state:

| Data | In state.json | In beads |
|------|--------------|----------|
| Task title | `title` | issue title |
| Task status | `current_step` + step statuses | issue status |
| Task creation | `created_at` | `created_at` |
| Task closure | `archived_at` | `closed_at` |
| Gate transitions | step `gate_id` + gate files | gate issues |
| Subtasks | decompose specs | epic + child issues |

Everything in beads is already tracked (or easily trackable) in the workflow layer.

---

## Alternatives Evaluated

12 alternatives were evaluated across 7 dimensions. Summary:

| Alternative | Context Cost | Deps | Search | Git-Native | Verdict |
|------------|-------------|------|--------|-----------|---------|
| Custom JSONL (`wt`) | Near zero | Build | jq/grep | Yes | **Recommended** |
| GitHub Issues + `gh` | Near zero | Yes (API) | Excellent | No | **Runner-up** |
| Hybrid state.json | Zero | Build | Fair | Yes | **Radical option** |
| Seeds (`sd`) | Unknown | Yes | Good | Yes | Risk of repeating bloat |
| git-bug | Good | None | Good | Yes | No deps = dealbreaker |
| Chainlink | Poor | Yes | Fair | No (SQLite) | Competing control plane |
| Taskwarrior | Good | Yes | Excellent | No (~/.task) | Wrong data location |
| CC Native Tasks | Zero | Yes | None | No | Experimental, no search |
| todo.txt | Excellent | None | Good | Yes | Too simple |
| Dolt-backed fix | Same | Same | Same | Partial | Rebuilding beads |
| git-issue | Good | None | Fair | Yes | No deps |
| driusan/bug | N/A | None | N/A | Yes | Dead project |

---

## Recommendations

### Primary: Custom JSONL Tracker (`wt`)

Build a minimal shell script (~200-400 lines) wrapping `jq` on `.issues/issues.jsonl`:

```
wt create --title "..." [--type task] [--priority 2] [--depends-on ID]
wt list [--status open|closed|in_progress] [--ready]
wt show <id>
wt update <id> --status in_progress
wt close <id> [--reason "..."]
wt search <keyword>
```

**Why this wins**:
- **Context cost**: ~100 tokens (6 commands, self-explanatory CLI)
- **Dependencies**: Zero (POSIX sh + jq, both already installed)
- **Maintenance**: Simple enough that Claude can fix bugs in the script itself
- **Tailored**: Implements exactly the 6 operations actually used, nothing more
- **Git-native**: JSONL file tracked in git, greppable, diffable
- **Migration**: Mechanical — swap `bd X` for `wt X` across 14 files

**What it preserves**: Audit trail, session enforcement, finding triage, cross-session search.
**What it drops**: Daemon, SQLite, Dolt, 20+ skills, 126-line global rule, dependency graphs (unused).

**Implementation estimate**: 1-2 sessions for the script + migration.

### Secondary: GitHub Issues (if offline-first isn't hard)

If network dependency is acceptable, GitHub Issues via `gh` CLI is even simpler:
- Zero context cost (models know `gh` natively)
- Zero maintenance
- Excellent search and filtering
- Dependencies now supported (August 2025 GA)
- Issues visible in GitHub web UI for human review

**Trade-off**: No offline access, issues not in git history, rate limiting possible.

### Tertiary: Hybrid Simplification

The most radical option — eliminate separate issue tracking for T1/T2 entirely:
- T1/T2 (80% of sessions): state.json already tracks everything. Add `close_reason`. Done.
- T3 only: Per-task `.work/<name>/issues.jsonl` for subtask coordination.
- Cross-task search: `grep` across `.work/*/issues.jsonl` and archived tasks.

**Trade-off**: Different patterns for T1/T2 vs T3. Cross-task queries require directory scanning.

---

## Migration Plan (for Custom JSONL Tracker)

### Phase 1: Build `wt` script
- Implement 6 commands in ~200-400 lines of shell
- Data format: JSONL in `.issues/issues.jsonl`
- ID generation: `<project-prefix>-<short-hash>`
- Advisory file locking via `flock` for concurrent access

### Phase 2: Update harness
- Rewrite `beads-workflow.md` → `issue-workflow.md` (~30 lines)
- Update 14+ command files (mechanical: `bd X` → `wt X`)
- Rewrite 2 hooks (beads-check.sh → issue-check.sh, artifact-gate.sh)
- Update state.json field names (`issue_id` stays, `beads_epic_id` → `epic_id`)

### Phase 3: Remove beads
- Delete `.beads/` directory
- Remove beads:* skills
- Remove beads global rule file
- Uninstall `bd` CLI
- Optional: migrate 108 existing issues via `jq` transformation

### Phase 4: Validate
- Run harness-doctor
- Test all tiers (T1, T2, T3)
- Verify context cost reduction

---

## Open Questions

1. **Is offline-first a hard requirement?** Decides between custom tracker (Path A) and GitHub Issues (Path B). If you sometimes work disconnected, Path A is necessary.

2. **Is the beads audit trail ever consulted?** Do you run `bd list --status=closed` or `bd search` to review historical decisions? If the answer is "rarely" or "never," the audit trail can be simplified to git commit messages.

3. **How critical is `bd search` for context recovery?** The pattern "search closed issues before exploring code" is documented in 7+ commands but may be aspirational. If handoff prompts are the real context bridge, search can be simpler.

4. **Should the replacement be in-house or external?** A custom `wt` script gives full control but requires maintenance. Seeds (`sd`) is a community option but may repeat beads' bloat. GitHub Issues requires no maintenance but needs network.

5. **Can we run old and new in parallel during migration?** This would de-risk the transition but adds temporary complexity.

---

## Sources

### Files Examined
- `.beads/issues.jsonl` (108 issues, data format analysis)
- `.beads/config.yaml` (beads configuration)
- `hooks/beads-check.sh`, `hooks/artifact-gate.sh`, `hooks/state-guard.sh`
- `claude/rules/workflow.md`, `~/.claude/rules/beads-workflow.md`
- `claude/commands/work-*.md` (all work commands)
- `claude/skills/work-harness.md` and sub-skills
- `.work/*/state.json` (multiple task state files)

### External Research
- GitHub Issues dependency API (GA August 2025)
- git-bug (github.com/git-bug/git-bug, 9.7k stars)
- Seeds (github.com/jayminwest/seeds, 66 stars)
- Chainlink (github.com/dollspace-gay/chainlink, 281 stars)
- Taskwarrior, todo.txt, git-issue, driusan/bug
- Claude Code native task system documentation
