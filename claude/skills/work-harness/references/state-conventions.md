# State Conventions

How the adaptive work harness stores and manages task state. This is the most critical reference for subagents — understanding state.json is required to participate correctly in any task.

## State Location

Each task's state lives at `.work/<name>/state.json`.

## Name Derivation Algorithm

Task names are derived from the title:

```
name = lowercase(title)
name = replace(/[^a-z0-9-]/g, '-', name)    # non-alphanumeric → hyphen
name = replace(/-+/g, '-', name)              # collapse consecutive hyphens
name = trim('-', name)                        # remove leading/trailing hyphens
name = truncate(40, name)                     # max 40 characters
if .work/<name>/ exists: name = name + "-2"   # increment until unique
```

## State.json Schema

```json
{
  "name":           "string  — kebab-case task slug",
  "tier":           "number|string  — 1, 2, 3, or \"R\"",
  "title":          "string  — human-readable task description",
  "created_at":     "string  — ISO 8601 timestamp",
  "updated_at":     "string  — ISO 8601 timestamp, updated on every state change",
  "issue_id":       "string  — beans issue ID (e.g., 'rag-1234')",
  "current_step":   "string  — must be a value in the steps array",
  "steps":          "object[] — ordered array of step objects [{name, status, ...}] for this tier",
  "step_status":    "object|null — DEPRECATED, use steps[].status instead. Legacy field, ignored by hooks.",
  "assessment":     "object|null — triage scoring, null until assess step completes",
  "docs_path":      "string|null — relative path to docs/feature/<name>, null for Tier 1",
  "epic_id":        "string|null — beans epic ID, only for Tier 3",
  "sessions":       "array   — session checkpoint records",
  "base_commit":    "string  — git commit hash at task creation time",
  "findings_file":  "string  — always '.review/findings.jsonl'",
  "archived_at":    "string|null — ISO 8601 when archived, null while active"
}
```

## Step Names by Tier

| Tier | Steps (in order) |
|------|-----------------|
| 1 (Fix) | `assess`, `implement`, `review` |
| 2 (Feature) | `assess`, `plan`, `implement`, `review` |
| 3 (Initiative) | `assess`, `research`, `plan`, `spec`, `decompose`, `implement`, `review` |
| R (Research) | `assess`, `research`, `synthesize` |

Tier R is created by the `work-research` command for research-only investigations that do not proceed to implementation.

## Step Lifecycle State Machine

```
not_started ──► active ──► completed
     │
     └──► skipped
```

No other transitions are valid:
- Cannot go from `completed` back to `active` (no re-opening)
- Cannot go from `skipped` to `active` (skip is permanent)
- Cannot go from `active` to `not_started` (no rollback)

### Step Status Object

```json
{
  "status":         "string  — 'not_started' | 'active' | 'completed' | 'skipped'",
  "started_at":     "string|null — set when status becomes 'active'",
  "completed_at":   "string|null — set when status becomes 'completed'",
  "skipped_reason": "string|null — one-line reason when status is 'skipped'",
  "handoff_prompt": "string|null — Tier 3 only, path relative to .work/<name>/",
  "gate_id":        "string|null — beans issue ID for gate review, Tier 3 only",
  "gate_file":      "string|null — relative path from .work/<name>/ to the gate review file, Tier 3 only"
}
```

## Step Advancement Rules

- Only one step can be `active` at a time
- `current_step` must match the active step
- When a step completes: set `completed_at`, advance `current_step` to next in `steps` array
- `updated_at` is set on every write
- Tier 1 last-step completion triggers auto-archive (`archived_at` set)
- Tier 2-3 remain active until explicit `/work-archive`

## Task Discovery

To find the active task:

1. Scan `.work/` directory for subdirectories
2. Read `state.json` in each subdirectory
3. Filter by `archived_at == null` (active tasks only)
4. Multiple active → ask user which one
5. One active → use it
6. None → suggest `/work` to create a new task

## Concurrency Model

- Single-session per task
- Parallel streams (Tier 3) use separate beans issues, not separate tasks
- No locking mechanism — assumed single-user, single-session at a time

## Verdict Types

Step transitions produce verdicts from phase review agents:

- **PASS**: No issues found. Transition proceeds.
- **ASK**: Specific questions that must be answered before the transition proceeds. Responses recorded in the gate file.
- **BLOCKING**: Substantive issues that must be fixed before the transition can proceed.

## Gate File Format

Step transition gate files are stored at `.work/<name>/gates/<from>-to-<to>.md`. The file includes:

1. Verdict summary (Phase A and Phase B results)
2. `## Resolved Asks` section (when ASK verdicts occurred)
3. Approval record

### Resolved Asks Section

Present only when ASK verdicts occurred during the transition. Omitted entirely for pure PASS transitions. Placed after the verdict summary, before the approval record.

```markdown
## Resolved Asks

### Phase A Asks

_(none)_

### Phase B Asks

**Q1**: [Original question text]
**A1**: [User's response — verbatim or summarized]

**Q2**: [Original question text]
**A2**: [User's response]
```

If no ASK items exist for a phase, that subsection shows `_(none)_`. If neither phase has ASKs, the entire section is omitted.

## Ceremony Configuration

The `workflow.ceremony` setting in `.claude/harness.yaml` controls approval ceremony behavior:

```yaml
workflow:
  ceremony: auto  # Options: "auto" (default), "always"
```

- **`auto`** (default): Ceremony behavior is risk-based. Low-risk PASS transitions auto-advance; medium/high-risk transitions require a hard stop approval ceremony.
- **`always`**: All transitions require a hard stop approval ceremony, regardless of risk level. ASK and BLOCKING behavior is unchanged (already hard stops).

See the risk classification table for per-transition risk levels:

| Transition              | Base Risk | Ceremony on PASS |
|-------------------------|-----------|------------------|
| research → plan         | high      | hard stop        |
| plan → spec             | high      | hard stop        |
| spec → decompose        | medium    | hard stop        |
| decompose → implement   | medium    | hard stop        |
| implement phase N → N+1 | low       | auto-advance     |
| implement → review      | low       | auto-advance     |

## Critical Rule for Subagents

**Subagents do NOT modify state.json directly.** Report results back to the orchestrating command. Only commands (`/work`, `/work-review`, `/work-checkpoint`, etc.) write state. This is the most important convention for subagents to follow.
