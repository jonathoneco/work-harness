# Spec C09: `/dev-update` Command + Skill

**Component**: C09 — `/dev-update` command + skill
**Phase**: 3 (New Commands)
**Status**: complete
**Dependencies**: Spec 00 (config injection, frontmatter schema)

---

## Overview and Scope

Creates a command and skill for generating structured developer status updates from workflow artifacts. The command reads active task state, recent git history, and checkpoint files to synthesize a markdown status update. Output is markdown to stdout (per DD-2: artifacts not side effects).

**What this does**:
- Creates `claude/commands/dev-update.md` command file
- Creates `claude/skills/work-harness/dev-update.md` skill file
- Reads workflow state, git log, and checkpoints to generate updates
- Outputs structured markdown to stdout

**What this does NOT do**:
- Send updates to Slack, email, or any external service (DD-2)
- Create or modify beads issues
- Require specific workflow state (works with or without active tasks)

---

## Implementation Steps

### Step 1: Create Dev-Update Skill

Create `claude/skills/work-harness/dev-update.md`:

```yaml
---
name: dev-update
description: "Conventions for generating structured developer status updates from workflow artifacts. Consumed by /dev-update command."
meta:
  stack: ["all"]
  version: 1
  last_reviewed: 2026-03-24
---
```

Content:

```markdown
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

4. **Beads issues** (`bd list --status=in_progress` and recently closed)
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
```

**Acceptance Criteria**:
- AC-C09-1.1: Skill file exists at `claude/skills/work-harness/dev-update.md`
- AC-C09-1.2: Artifact reading priority order is defined with 5 sources
- AC-C09-1.3: Update structure template with 4 sections (Completed, In Progress, Blocked, Next)
- AC-C09-1.4: Time window configuration documented

### Step 2: Create Dev-Update Command

Create `claude/commands/dev-update.md`:

```yaml
---
description: "Generate a structured developer status update from workflow artifacts"
user_invocable: true
skills: [dev-update, work-harness]
meta:
  stack: ["all"]
  version: 1
  last_reviewed: 2026-03-24
---
```

Command structure:

```markdown
# /dev-update $ARGUMENTS

Generate a structured status update from workflow artifacts. Output is markdown to stdout.

**Config injection**: If `.claude/harness.yaml` exists in the current project directory,
read it and include a "Project Stack Context" section (language, framework, database,
build commands) in all subagent prompts and handoff prompts you produce.

## Step 1: Determine Time Window

Parse `$ARGUMENTS` for time window flags:
- No arguments → 24 hours
- `--today` → since midnight
- `--week` → 7 days
- `--since Nd` → N days

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
```

**Acceptance Criteria**:
- AC-C09-2.1: Command file exists at `claude/commands/dev-update.md`
- AC-C09-2.2: Command accepts time window arguments
- AC-C09-2.3: Command reads from all 5 artifact sources
- AC-C09-2.4: Output follows the dev-update skill's template structure
- AC-C09-2.5: Command includes config injection directive
- AC-C09-2.6: Output is to stdout (no file creation by default)

### Step 3: Update `work-harness.md` References

Add to the References section:

```markdown
- **dev-update** — Status update generation conventions (path: `claude/skills/work-harness/dev-update.md`)
```

**Acceptance Criteria**:
- AC-C09-3.1: `work-harness.md` References section includes `dev-update`

---

## Interface Contracts

### Exposes

- **`/dev-update` command**: User-facing command for generating status updates
- **`dev-update` skill**: Reusable conventions for status update generation

### Consumes

- **Spec 00 Contract 2**: `meta` block in frontmatter
- **Spec 00 Contract 3**: Config injection directive
- **`work-harness` skill**: Loaded for task state knowledge
- **Active task state**: `.work/*/state.json`
- **Git log**: Recent commits
- **Beads**: Issue status

---

## Files to Create/Modify

| Action | File | Description |
|--------|------|-------------|
| Create | `claude/skills/work-harness/dev-update.md` | Status update conventions skill |
| Create | `claude/commands/dev-update.md` | Status update command |
| Modify | `claude/skills/work-harness.md` | Add dev-update reference |

**Total**: 2 new files, 1 modified file

---

## Testing Strategy

1. **Artifact gathering**: Run `/dev-update` in the current repo (which has active tasks). Verify it reads `.work/skills-pipeline/state.json` and recent git log.

2. **Output structure**: Verify the output contains all 4 sections (Completed, In Progress, Blocked, Next)

3. **Empty state**: Run in a repo with no `.work/` directory. Verify it gracefully reports "No active tasks" and still includes git log and beads data.

4. **Time window**: Run with `--week` and verify it captures a wider range of commits than the default 24 hours.
