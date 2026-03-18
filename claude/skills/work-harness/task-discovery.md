---
name: task-discovery
description: "Active task finding, state reading, tier-command mapping. Used by all work commands at startup to detect and route to the active task."
---

# Task Discovery

Shared algorithm for finding the active task, reading its state, and mapping it to the correct tier command. Every work command runs this at startup before applying tier-specific behavior.

## When This Activates

- Any work command startup (`/work-fix`, `/work-feature`, `/work-deep`, `/work-checkpoint`, `/work-archive`, `/work-redirect`, `/work-review`, `/work-status`, `/work-reground`)
- Any status query or context recovery operation

## Discovery Algorithm

Follow this 6-step process to find the active task. See `claude/skills/work-harness/references/state-conventions.md` for the full state.json schema.

### 1. Scan

Scan the `.work/` directory for subdirectories containing `state.json`.

If `.work/` does not exist: report "No active tasks" and let the calling command decide how to proceed (some commands stop, others proceed to create a new task).

### 2. Read

Read `state.json` from each subdirectory found in step 1.

If a `state.json` is unparseable (invalid JSON): log a warning and skip that entry. Do not fail the entire discovery.

### 3. Filter

Filter to active tasks only: those where `archived_at` is `null`.

### 4. Multiple Active Tasks

If more than one active task is found: list all active tasks with their name, tier, title, and current step. Ask the user to specify which one to work on.

### 5. One Active Task

If exactly one active task is found: use it. Extract the following fields:

- `name` -- task slug (directory name)
- `tier` -- 1, 2, or 3
- `title` -- human-readable description
- `current_step` -- which step is active
- `issue_id` -- beads issue ID
- `steps` -- ordered step array with status per step

### 6. No Active Tasks

If no active tasks remain after filtering: report "No active tasks" and let the calling command decide how to proceed.

## Tier-Command Mapping

| Tier | Command | Label |
|------|---------|-------|
| 1 | `/work-fix` | Fix |
| 2 | `/work-feature` | Feature |
| 3 | `/work-deep` | Initiative |

Use this mapping when suggesting next actions (e.g., "Run `/work-feature` to resume") or when detecting tier mismatches (the user invoked a command for a different tier than the active task).

## State Reading

After discovery identifies the active task, extract state for the calling command:

- **Step routing**: Use `current_step` to jump to the correct section in the command
- **Progress**: Compute completed/total from the `steps` array
- **Duration**: For completed steps, compute from `started_at` to `completed_at`
- **Findings**: If `.work/<name>/review/findings.jsonl` exists, count OPEN findings by severity

See `claude/skills/work-harness/references/state-conventions.md` for the full step status object schema including `gate_id`, `gate_file`, `handoff_prompt`, and other fields.

## Beads Issue Detection

When `$ARGUMENTS` is provided to a work command:

1. Check if the argument matches a beads issue ID pattern (e.g., `work-harness-abc`, `rag-1234`)
2. If it matches: run `bd show <issue_id>` to load issue details (title, description, status, dependencies)
3. Use the issue details to enrich the task context for assessment or resumption

## Error Cases

| Condition | Behavior |
|-----------|----------|
| `.work/` directory missing | Report "No active tasks". Not an error for commands that create tasks. |
| `state.json` unparseable | Log warning, skip entry. Continue with remaining tasks. |
| Multiple active tasks | List all, ask user to specify. Do not guess. |
| Active task of wrong tier | Report the mismatch. Let the calling command decide (ask user to continue or archive). |
| `$ARGUMENTS` looks like an issue ID but `bd show` fails | Log warning, proceed without issue context. |

## References

- **state-conventions** -- Full state.json schema, step lifecycle, step status object (path: `claude/skills/work-harness/references/state-conventions.md`)
