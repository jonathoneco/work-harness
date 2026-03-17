# Review Methodology

How the adaptive work harness conducts code review — when it happens, who reviews, how findings are tracked, and how severity gates work.

## When Review Happens

| Tier | Trigger | Mechanism |
|------|---------|-----------|
| 1 (Fix) | Automatic after implementation | Stop hook (`review-gate.sh`) runs review on session end |
| 2-3 (Feature/Initiative) | Manual invocation | User runs `/work-review` |
| 3 (Initiative) | Mandatory pre-archive | Cannot archive without passing review gate |

## Review Agent Selection

The `/work-review` command selects agents based on the files changed in the current task:

| File Pattern | Agent(s) Selected |
|-------------|------------------|
| `*.go` (non-test) | go-reviewer |
| `*_test.go` | go-reviewer |
| `*.html`, `templates/**` | htmx-debugger |
| Any file | security-reviewer (always included) |
| `migrations/*.sql` | go-reviewer (schema awareness) |

**Stack-tracer** is selected when changes span 2+ application layers:

| Layer | File Pattern |
|-------|-------------|
| Handler | `internal/handlers/*.go` |
| Service | `internal/services/*.go` |
| Database | `internal/database/*.go`, `migrations/*.sql` |
| Template | `internal/views/templates/**/*.html` |
| Model | `internal/models/*.go` |

Stack-tracer triggers when ANY of:
- Changes touch files in 2+ layers
- Both `.go` and `.html` files are changed
- Migration files are changed alongside any `.go` file
- Handler files are changed (even without template changes)

## Finding Lifecycle

```
                    ┌─────────┐
     new finding ──►│  OPEN   │
                    └────┬────┘
                         │
              ┌──────────┼──────────┐
              ▼          ▼          ▼
         ┌────────┐ ┌────────┐ (no action
         │ FIXED  │ │PARTIAL │  = stays OPEN)
         └────────┘ └───┬────┘
                        │
                        ▼
                   ┌────────┐
                   │ FIXED  │  (after complete fix)
                   └────────┘

     re-review finds new issue ──► NEW
```

- **OPEN** — newly identified, not yet addressed
- **FIXED** — re-review confirmed the fix resolves the finding
- **PARTIAL** — fix attempted but incomplete (e.g., handler fixed, template not updated)
- **NEW** — appeared in re-review that wasn't in the original pass

## Severity Enforcement

| Severity | Gate Behavior | Auto-Issue |
|----------|--------------|------------|
| `critical` | Blocks session end (review-gate.sh exit 2) | Yes — creates beads issue automatically |
| `important` | Warns at session end (review-gate.sh stderr) | Yes — creates beads issue automatically |
| `suggestion` | No gate enforcement | No |

## Findings Format

Findings are stored in `.review/findings.jsonl` (append-only, one finding per line):

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | `f-YYYYMMDD-NNN` (assigned by review command) |
| `task_name` | string | Matches `.work/<name>/` |
| `issue_id` | string | Beads issue ID of the originating task |
| `severity` | string | `critical`, `important`, or `suggestion` |
| `category` | string | e.g., `error-handling`, `security`, `htmx`, `layer-cascade` |
| `title` | string | One-line summary |
| `description` | string | Detailed explanation with code context |
| `file` | string | File path relative to project root |
| `line` | number/null | Line number, null if file-level |
| `status` | string | `OPEN`, `FIXED`, `PARTIAL`, or `NEW` |
| `found_at` | string | ISO 8601 timestamp |
| `found_by` | string | Agent kebab-case name (e.g., `go-reviewer`) |
| `resolved_at` | string/null | ISO 8601 when status changed from OPEN |
| `resolution` | string/null | One-line description of the fix |
| `beads_issue_id` | string/null | Populated for critical/important findings |

**ID allocation**: The review command collects raw findings from all agents, then assigns sequential IDs. Agents do NOT write to findings.jsonl directly.

## Re-review Reconciliation

When `/work-review` runs a re-review pass:

1. Review command reads existing `OPEN` findings from findings.jsonl
2. Passes existing findings to each agent as context
3. Each agent returns:
   - `[FIXED]` marker for fixed findings
   - `[PARTIAL]` marker for partially fixed findings
   - Existing findings still present are omitted (remain OPEN by default)
   - New findings returned as normal `[CRITICAL]`/`[IMPORTANT]`/`[SUGGESTION]`
4. Review command reconciles agent output against existing findings and updates findings.jsonl

## Critical Rule for Subagents

Review agents do NOT write to findings.jsonl directly. They return structured findings to the orchestrating `/work-review` command, which handles ID assignment, status management, and file writes.
