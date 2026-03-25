---
name: dev-update
description: "Conventions for generating structured developer status updates from workflow artifacts. Consumed by /dev-update command."
meta:
  stack: ["all"]
  version: 1
  last_reviewed: 2026-03-25
---

# Dev Update

Conventions for synthesizing developer status updates from the work harness's own artifacts. The update is a point-in-time snapshot of what was done, what's in progress, and what's blocked.

## When This Activates

- Running `/dev-update`
- Spawning agents that generate status summaries

## Artifact Reading Priority

Read artifacts in this order. Stop when you have enough for a complete update:

1. **Active task state** (`.work/*/state.json` where `archived_at` is null)
   - Task name, tier, current step, step statuses
   - How far through the workflow the task is

2. **Recent git log** (`git log --oneline --since="1 day ago"` or configurable window)
   - What was actually committed
   - Commit messages as evidence of completed work

3. **Checkpoint files** (`.work/*/checkpoints/*.md`)
   - Session progress notes
   - Resumption context from previous sessions

4. **Beans issues** (`bn list --status=in_progress` and recently closed)
   - Claimed work in progress
   - Recently completed issues

5. **Handoff prompts** (`.work/*/*/handoff-prompt.md`)
   - Step completion summaries
   - Key decisions made

## Update Structure

Every update follows this template:

```markdown
# Dev Update — YYYY-MM-DD

## Completed
- [item]: [1-sentence description of what was done]

## In Progress
- [task-name] (Tier N, step: [current_step]): [what's happening now]

## Blocked / Needs Input
- [item]: [what's blocking and what's needed]

## Next
- [planned next action]
```

### Rules

- **Completed**: Only list items with evidence (commits, closed issues, completed steps)
- **In Progress**: Active tasks with their current step
- **Blocked**: Items where progress cannot continue without external input
- **Next**: The most likely next action based on task state
- **Brevity**: Each item is 1 sentence. The entire update should be scannable in 30 seconds.
- **No speculation**: If there's no evidence of work, don't invent items

## Time Window

Default: last 24 hours. Can be overridden via `$ARGUMENTS` (e.g., `/dev-update --since 3d` or `/dev-update --week`).

| Argument | Window |
|----------|--------|
| (none) | 24 hours |
| `--today` | Since midnight local time |
| `--week` | 7 days |
| `--since Nd` | N days |
