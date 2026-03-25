---
description: "Generate a structured developer status update from workflow artifacts"
user_invocable: true
skills: [dev-update, work-harness]
meta:
  stack: ["all"]
  version: 1
  last_reviewed: 2026-03-25
---

# /dev-update $ARGUMENTS

Generate a structured status update from workflow artifacts. Output is markdown to stdout.

**Config injection**: If `.claude/harness.yaml` exists in the current project directory,
read it and include a "Project Stack Context" section (language, framework, database,
build commands) in all subagent prompts and handoff prompts you produce.

## Step 1: Determine Time Window

Parse `$ARGUMENTS` for time window flags:
- No arguments -> 24 hours
- `--today` -> since midnight
- `--week` -> 7 days
- `--since Nd` -> N days

Set `$SINCE` to the appropriate `git log --since` value.

## Step 2: Gather Artifacts

Read all artifact sources per the dev-update skill's priority order:

1. Find active tasks:
   ```bash
   find .work -name state.json -exec grep -l '"archived_at": null' {} \;
   ```
   For each, read current_step and step statuses.

2. Get recent commits:
   ```bash
   git log --oneline --since="$SINCE"
   ```

3. Find recent checkpoints:
   ```bash
   find .work -name '*.md' -path '*/checkpoints/*' -newer <cutoff>
   ```

4. Get beads status:
   ```bash
   bd list --status=in_progress
   bd list --status=closed --limit 10
   ```

5. Find handoff prompts for completed steps (optional, for richer context).

## Step 3: Synthesize Update

Using the dev-update skill's update structure template, generate the status update:

1. **Completed**: Map closed beads issues and completed step transitions within the time window
2. **In Progress**: Map active tasks with their current step and progress
3. **Blocked**: Identify tasks where the current step has been active for longer than expected, or where checkpoint notes mention blockers
4. **Next**: Infer from task state — the next step in the workflow, or the next `bd ready` item

## Step 4: Output

Print the update to stdout in markdown format. The user can redirect to a file if desired:

```bash
# User can pipe or redirect
/dev-update > status-update.md
```
