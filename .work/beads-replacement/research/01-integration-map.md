# Beads Integration Map — Work Harness

## Questions
- How deeply is beads woven into the harness?
- What are all the touchpoints?

## Findings

### Enforcement Layer
- **Global rule**: `~/.claude/rules/beads-workflow.md` (126 lines) — "NEVER EDIT CODE WITHOUT A BEADS ISSUE"
- **beads-check.sh hook** (Stop event): blocks session end if code modified without claimed issue
- **artifact-gate.sh hook** (Stop event): enforces T3 completed steps have `gate_id`

### State Integration
- `state.json` fields: `issue_id` (T1-T3), `beads_epic_id` (T3), step-level `gate_id` + `gate_file`
- Every tier creates a beads issue at task start, closes at archive
- T3 creates an epic + per-step gate issues for transition auditing

### Command Surface (14+ commands, ~120 CLI invocations)
| Command | Beads Usage |
|---------|-------------|
| `/work` | Accept beads issue by ID, `bd show` |
| `/work-fix` | Create bug, claim, close |
| `/work-feature` | Create feature, claim, subtasks via `bd ready` |
| `/work-deep` | Create epic + issues, gates, dependency ordering |
| `/work-research` | Create research task, close on complete |
| `/work-archive` | Close all issues and epic |
| `/work-review` | Triage findings → `bd create` for deferred issues |
| `/work-dump` | `bd list --status=open`, generate create commands |
| `/handoff` | `bd list --status=in_progress` |
| `/ama` | `bd search`, `bd show` for context |
| `/harness-doctor` | Health check: `bd list --limit 1` |
| `/work-reground` | `bd show <issue_id>` for recovery |
| `/delegate` | Pass epic_id to subagent context |

### Core bd Commands Used
`bd create`, `bd update`, `bd close`, `bd list`, `bd ready`, `bd show`, `bd search`, `bd dep add`, `bd sync`

### System Prompt Injection
- Global rule file: ~126 lines loaded every session
- Session start hook: additional beads context block
- Beads skills: 20+ skill entries (beads:*)

## Implications
- Replacement requires: 14+ file rewrites, 3 hook rewrites, 1 global rule rewrite
- ~150 CLI invocation sites to update
- State.json field mapping (issue_id, beads_epic_id, gate_id)
- Dependency resolution semantics must be preserved for T3

## Open Questions
- Are gate issues purely audit trail or do they drive transitions?
- How critical is `bd search` for cross-session context recovery?
- Is dependency resolution (topological sort in `bd ready`) essential?
