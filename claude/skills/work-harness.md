---
name: work-harness
description: "Adaptive work harness conventions — state model, triage, review gates, escalation. Activates when .work/ directory exists with active tasks (state.json where archived_at is null). Propagate to implementation and review subagents via skills: [work-harness] frontmatter."
---

# Work Harness

This skill provides knowledge about the adaptive work harness — the unified
system for managing tasks from one-line fixes to multi-week initiatives.
It exists as a skill so that subagents (implementation agents, review agents,
research agents) inherit harness conventions.

## When This Activates

- `.work/` directory exists with at least one active task
- Running work commands (`/work`, `/work-fix`, `/work-feature`, `/work-deep`)
- Running state commands (`/work-status`, `/work-checkpoint`, etc.)

## References

- **triage-criteria** — 3-factor depth assessment formula and scoring rubric
- **review-methodology** — Review gate process, finding lifecycle, severity enforcement
- **state-conventions** — State model schema, step lifecycle, task discovery (path: `claude/skills/work-harness/references/state-conventions.md`)
- **depth-escalation** — When and how to escalate from one tier to another
- **gate-protocol** — Gate file SOP: directory layout, naming, structure, iteration, rollback (path: `claude/skills/work-harness/references/gate-protocol.md`)
- **task-discovery** — Active task finding, state reading, tier-command mapping (path: `claude/skills/work-harness/task-discovery.md`)
- **step-transition** — Approval ceremony, gate creation, state update, context compaction (path: `claude/skills/work-harness/step-transition.md`)
- **phase-review** — Phase A artifact validation + Phase B quality review with verdict handling (path: `claude/skills/work-harness/phase-review.md`)
- **context-seeding** — Context seeding protocol for step agent prompts: standard preamble, per-step context table, handoff contract, anti-patterns (path: `claude/skills/work-harness/context-seeding.md`)
- **step-agents** — Complete prompt templates for plan, spec, and decompose step agents (path: `claude/skills/work-harness/step-agents.md`)
- **teams-protocol** — Agent Teams usage protocol: naming, task schema, teammate prompts, completion detection, failure handling (path: `claude/skills/work-harness/teams-protocol.md`)

## Path Convention

All generated artifacts (checkpoints, handoff prompts, research notes, findings, specs) MUST use **project-relative paths** — never absolute paths or home directory references.

- **Correct**: `internal/handlers/auth.go`, `.work/task-name/research/notes.md`
- **Wrong**: `/home/user/src/project/internal/handlers/auth.go`, `~/docs/spec.md`

This applies to file listings, findings, spec references, and any path written to `.work/` or `docs/`.

## Key Concepts

- **3 tiers**: Fix (T1), Feature (T2), Initiative (T3)
- **Steps are data**: The `steps` array in state.json defines available phases
- **Auto-detect**: Commands read `current_step` and present the right interface
- **Every task has a beads issue**: Created during the assess step
- **State committed to git**: `.work/` directory is tracked, not gitignored

## Tier System

| Tier | Label | Steps | Sessions |
|------|-------|-------|----------|
| 1 | Fix | assess, implement, review | Single session |
| 2 | Feature | assess, plan, implement, review | 1-2 sessions |
| 3 | Initiative | assess, research, plan, spec, decompose, implement, review | Multi-session |

## State Management

Each task's state lives at `.work/<name>/state.json`:
- `name`: kebab-case task slug (max 40 chars)
- `tier`: 1, 2, or 3
- `current_step`: must be a value in the steps array
- `steps`: ordered array of step objects (`[{name, status, started_at, completed_at, gate_id, gate_file}, ...]`)
- `assessment`: triage scoring (null until assess step completes)
- `base_commit`: git commit hash at task creation time
- `archived_at`: null while active, ISO 8601 when archived

## Step Lifecycle

```
not_started --> active --> completed
     |
     +--> skipped
```

Only one step can be `active` at a time. `current_step` must match the active step. No re-opening completed steps.

## Step Transitions

Every step transition runs a two-phase review:
- **Phase A**: Artifact validation (structural completeness)
- **Phase B**: Quality review (substance evaluation)
- **Verdicts**: PASS, ADVISORY (log but don't block), BLOCKING (must fix)

After review completes, present results to user and wait for explicit approval before advancing state.

## Gate Files

Step transitions produce gate files at `.work/<name>/gates/`. These are the primary review artifact -- the user reviews them in their editor rather than scrolling terminal output. See the gate-protocol reference (`claude/skills/work-harness/references/gate-protocol.md`) for naming conventions, file structure, and rollback semantics. Gate files are Tier 3 only.

## Handoff Prompts

Handoff prompts bridge sessions. The current session has full context; the next session has none. The handoff prompt is the only bridge. Never re-read raw research notes when a handoff prompt exists.

## Finding Lifecycle

Findings are stored in `.work/<name>/review/findings.jsonl` (append-only):
- Statuses: OPEN, FIXED, PARTIAL, NEW
- Severities: critical, important, suggestion
- IDs: `f-YYYYMMDD-NNN` (assigned by review command, not agents)
- Agents return findings to the orchestrating command; they do NOT write to findings.jsonl directly

## Beads Integration

- Every task has a beads issue (created during assess step)
- Tier 3 tasks have an epic with sub-issues
- Critical/important review findings get automatic beads issues
- `bd ready` shows unblocked work; `bd close` marks completion

## Escalation

When implementation reveals complexity exceeding the current tier:
1. Update tier field
2. Insert new steps before implement in canonical order
3. Reset implement and review to not_started
4. Set current_step to first new step
5. Preserve original assessment scoring

## Context Compaction Protocol

Step transitions are natural compaction boundaries. After user acknowledges a transition:
1. Confirm handoff prompt is written and state.json updated
2. Tell user to run `/compact` then the tier command
3. Stop — do not continue inline

## Checkpoint Pattern

Checkpoints save session progress for continuity:
- Resumption prompt is the most important section
- Present for user review before writing
- Git commit after writing
