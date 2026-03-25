---
description: "Show active task status — progress, findings, and suggested next action"
user_invocable: true
meta:
  stack: ["all"]
  version: 1
  last_reviewed: 2026-03-24
---

# Work Status

Read-only status display for active tasks. Shows step progress, finding counts, and suggests the next action. Makes no state changes.

**Config injection**: If `.claude/harness.yaml` exists in the current project directory,
read it and include a "Project Stack Context" section (language, framework, database,
build commands) in all subagent prompts and handoff prompts you produce.

## Arguments

- `$ARGUMENTS` — optional task name. If omitted, show all active tasks.

## Process

### Step 1: Discover tasks

Follow the **task-discovery** skill (`claude/skills/work-harness/task-discovery.md`).

- If `$ARGUMENTS` specifies a task name: show `.work/<name>/state.json` (even if archived)
- If no arguments: show all tasks where `archived_at` is null
- If no active tasks: "No active tasks. Run /work to start one."

### Step 2: Display status for each task

For each task, read `state.json` and display:

```
## Active Tasks

### <name> (Tier <N>)
**Title:** <title>
**Issue:** <issue_id>
**Step:** <current_step> (<status>)
**Progress:** [====>    ] 3/5 steps

| Step | Status | Duration |
|------|--------|----------|
| assess | completed | 1m |
| plan | completed | 15m |
| implement | active | (in progress) |
| review | not_started | — |

**Findings:** <N> open (C critical, I important, S suggestion)
**Sessions:** <N> checkpoints

**Suggested next action:** Continue implementing. Run /work-feature to resume.
```

**Progress bar:** Count completed + skipped steps vs total steps in the `steps` array.

**Duration:** For completed steps, compute from `started_at` to `completed_at`. For active steps, show "(in progress)". For not_started, show "—".

### Step 3: Compute finding counts

If `.work/<name>/review/findings.jsonl` exists:

1. Read all lines, filter by `task_name` matching this task
2. For each finding ID, the last line with that ID is the current state
3. Count findings by severity and status (only count OPEN and NEW as "open")
4. Display: `<N> open (C critical, I important, S suggestion)`

If no findings file or no findings for this task: "No findings"

### Step 4: Suggest next action

Based on task state:

| Condition | Suggestion |
|-----------|------------|
| `current_step` is active | "Continue <step>. Run /work-<tier-command> to resume." |
| OPEN critical findings exist | "Fix <N> critical findings. Run /work-review after fixing." |
| All steps completed (Tier 2-3) | "Task complete. Run /work-archive when ready." |
| All steps completed (Tier 1) | "Task auto-archived." |

Tier-to-command mapping: Tier 1 = `/work-fix`, Tier 2 = `/work-feature`, Tier 3 = `/work-deep`.

## Key principles

- **Read-only.** This command never modifies state.json, findings, or any files.
- **Fast orientation.** The output should give a complete picture in under 10 seconds of reading.
- **Actionable.** Always end with a concrete next step the user can take.
